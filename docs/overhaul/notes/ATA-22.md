# ATA 22 Autopilot Flight Director System（AFDS）・ヨーダンパー・自動スタビライザートリム — 実装ノート

GAP ID の接頭辞：`AFDS`。2026-10-23 作成。コードは `overhaul` ブランチ（041c9ffa）時点。行番号は同ブランチのもの。

## 1. 概要

- 対象：MCP の操作子、A/P の engage/disengage とインターロック、3 チャンネル（L/C/R）と LAND 3/LAND 2、F/D、ロール・ピッチの全モードの arm/engage/遷移（TO/GA、LNAV・VNAV の AFDS 側、HDG SEL/HOLD、ATT、FLCH、V/S、ALT、LOC、G/S、FLARE、ROLLOUT）、モードの自動反転、FMA、A/P 切断警報、autoland 状態表示、ヨーダンパー（22-21）、自動スタビライザートリム（22-22。手動トリムとの関係を含む）。
- 対象外：autothrottle と推力管理（別担当。A/T と AFDS の取り合いだけ書く）、FMC の水平・垂直経路計算（別担当。AFDS が受け取る量と、LNAV/VNAV の arm・engage・反転だけ書く）、ILS/RA/IRS の受信機（ATA 34）、舵面・ratio changer・stab の機構（ATA 27）、bus isolation の電源側（ATA 24、ELEC-18）。
- 使った資料（PDF ページ）：
  - ATA22：22-00 p.4–44（A/P サーボ・CLCP・油圧割当て）、22-21 p.49–96（図 p.85・87）、22-22 p.101–170（図 p.149・159）、22-10 p.175–298（図 p.191・295）、22-11 p.301–324（図 p.319）、22-12 p.327–362（図 p.335・337・339・341・343・345・347・351・353・355・357）、22-14 p.365–404（図 p.371・383・385）。
  - FCOM 4.10 p.639–657、4.20 p.659–675、4.30 p.677、SP.4 p.171–175、10.30 p.1081–1107（FMA の典型表示）。関連：L.10 p.79–80、9.10/9.20/9.30 p.927–931・944–950・958、10.10 p.966・978–980・999–1000・1043、Bulletin TB1-4 p.47。
  - FCTM p.43・48・63–66・112・117–118・124・159・162・165–166・207・209。
- 型式差（FCOM の機体番号。109・405 が P&W、570 が GE。ATA-29 ノート参照）。RR は `資料に記載なし`。
  - ATT：109/405 にあり、570 には無い（F/D ON・A/P engage の既定ロールが HDG HOLD だけ）（FCOM p.640、p.663）。
  - G/S 捕捉：109/570 は LOC より先でも可、405 は LOC 捕捉まで抑止（FCOM p.651、p.669–670）。
  - AUTOPILOT DISC の音：109/405 は wailer（最低 1 秒）、570 は siren（FCOM p.655、p.677）。
  - F/D モード故障：109/405 は該当する bar だけ、570 は両 bar が消える（FCOM p.660）。
- 資料の食い違いと採用：
  - ROLLOUT の起動：FCOM 約 5 ft RA（p.664、p.671）、ATA 2 ft（p.296、p.360）。FMA の切替は FCOM の約 5 ft を採る。翼水平指令（ROLL DOWN）は ATA の 5 ft gear altitude（p.348）。
  - AUTOPILOT DISC の音：ATA は two-tone siren（p.366）。FCOM の型式別を採る。
  - stab trim の EICAS：ATA は STAB AUTO TRIM・STAB SPEED TRIM・STAB TRIM・STAB TRIM UNSCHD・STAB AUTO CUTOUT（p.170）、FCOM は >STAB GREENBAND・>STAB TRIM 2, 3・STAB TRIM UNSCHD（p.958）。乗員表示は FCOM を採る。ATA の残りは STATUS／整備レベルと `推定`。
  - FLARE の高さ：FCOM は 60–40 ft（p.665）・約 50 ft（p.671）、ATA は沈下率で 40/50/60 ft（p.342、図 p.295）。両立するので ATA の表を採る。
  - 単一チャンネルの flare：FCOM は「単一 A/P・F/D だけでは使わない」（p.670）、制限で 100 ft AGL までに解除（p.80）。ATA は単一 A/P でも flare まで可（p.288）で、そのとき AUTOPILOT caution（p.382）。挙動は ATA、運用は FCOM。
  - GA の目標速度：FCOM は MCP と現速度の大きい方、5 秒超過で現速度に更新（上限 MCP+25）（p.664、p.673）。ATA は片発時の上限を MCP+10 とする（p.298）。片発だけ ATA を採る。

## 2. 構成

### 2.1 FCC・MCP・サーボ

- FCC 3 台（L/C/R）。モード管理、制御則、故障検知、構成管理（engage と表示）、冗長管理、整備（ATA22 p.181）。プロセッサはピッチ用とロール/ヨー用の 2 個。制御則は 25 ms ごと、BITE は 1.5 s ごと（p.233）。
- 電源（ATA22 p.191 図）：

| 機器 | AC（本体） | DC（servo・engage） | 備考 |
|---|---|---|---|
| L FCC | 115V AC bus 3 | 28V DC bus 3 | |
| C FCC | 115V AC bus 1 | 28V DC bus 1 | |
| R FCC | 115V AC bus 2 | 28V DC bus 2 | |
| 警報（全 FCC の AFDS WARN） | — | 28V DC STBY bus（AUTO FLT WARN） | 本文は battery bus と書く（p.190） |
| MCP ch A / ch B | — | 28V DC bus 3（MCP L）/ bus 2（MCP R） | 照明は 0–5V AC |

- MCP：A/B の 2 チャンネル。A は L・C FCC、B は R・C FCC から入力し、片方が壊れると他方が両側に出す（p.209）。電源投入時の表示は IAS 200、HDG 000、V/S 空白、ALT 10000（p.236、FCOM p.643・647・649）。
- サーボ（ATA22 p.10–12、p.32–44、p.222、p.242–248）：

| チャンネル | 油圧 | aileron | elevator | rudder |
|---|---|---|---|---|
| L | 3 | L CLCP | L elevator A/P servo | L rollout PCP |
| C | 1 | lateral A/P servo | C elevator A/P servo | C rollout PCP |
| R | 2 | R CLCP | R elevator A/P servo | R rollout PCP |

  - 巡航は aileron・elevator 各 1 個。autoland で 2・3 個目が加わる。rudder（rollout PCP）は dual/triple のときだけ engage（p.222）。
  - サーボの状態は disengaged／armed（LVDT で舵面位置に同期）／engaged（EHSV で駆動）／camout（servo と surface の LVDT 不一致）（p.242–244）。
  - 複数チャンネルは機械的な力の投票。3 系は中間値、2 系は小さい方。大きく食い違うと、3 系は外れた FCC が、2 系は両方が外れる（p.32）。
- A/P は aileron と elevator を動かす。rudder は multi-A/P approach のときだけ、rollout では NWS も（FCOM p.659）。

### 2.2 入力

- IRU×3、ADC×3、RA×3、ILS×3、master FMC（ATA22 p.200–212）。Capt 選択の ADC が L・C FCC、F/O 選択の ADC が R FCC へ（p.204）。
- 信号選択：起動時は自系だけ。2 個以上有効で A/P engage か F/D ON のとき中間値選択。LOC/GS は捕捉から、RA は LOC+GS 捕捉かつ 1500 ft 未満から中間値（p.200）。
- ADC の使い分け：R A/P が first engaged、または F/O の F/D だけ ON のとき全 FCC が F/O 側 ADC を使い、ほかは Capt 側。無効なら反対側へ自動切替し、A/P と F/D が OFF になるまで保持（p.202）。FMC も同じ考え方（p.202）。
- FMC → FCC：horizontal steering、target airspeed/Mach/altitude、vertical steering と rate、min/max speed（p.206）。
- 機体構成：flap（内側 TE の RVDT、FCU 経由）、stab 位置（FCU）、speedbrake handle（RVDT×3）。HYDIM の「油圧有効」は診断専用、air/ground は ground test 専用（p.218）。
- 離散入力：disengage switch、GA switch（thrust lever 2・3 に各 3 接点）、HDG REF switch（magnetic/true）、F/D source select（p.220、p.240、FCOM p.1043）。

### 2.3 出力

- EIU 経由で PFD（FMA、AFDS 状態、FD 指令、選択値）と EICAS（p.226、p.366）。master warning と aural は MAWEA（A/P WARN 1/2 を normal と battery の 2 系統で出す）、master caution は EIU（p.226、p.380）。
- SRM へ autotrim の arm・engage・指令（§4.8）。
- ILS TUNE INHIBIT（A/P 時は LOC/GS 捕捉後、F/D だけなら 500 ft RA 未満、地上で滑走路方位 45° 以内・40 kt 以上・LOC/APP 未選択のとき）と RA TEST INHIBIT（p.212）。LOC アンテナは地上か LOC/APP 選択で前方へ、GS アンテナは脚下げで nose gear door へ。切替の 1 系故障で NO LAND 3、2 系以上で NO AUTOLAND（p.214–216）。
- APP arm 中に BCU 1 へ bus isolation 要求。4 秒以内に分離し、BCU 2 が BUS ISOLATED を返す（LAND 3 の必要条件）（p.192–196、ATA-24 の ELEC-18）。

### 2.4 ヨーダンパー

- YDM 2 台（upper → upper rudder、lower → lower rudder）。各 YDM に control と monitor の 2 プロセッサ（p.52、p.74）。
- 入力：IRU（横加速度、roll rate、yaw rate、GS、roll angle）、ADC（impact pressure、AOA、TAS、overspeed）、modal accelerometer×4、air/ground（3 本）、油圧（HYDIM と pressure switch。正常時は相反）（p.64–70）。
- 出力：RPCM 内の Y/D actuator（engage solenoid → EHSV、LVDT 帰還）。油圧は upper が 3、lower が 2（p.64、p.78、FCOM p.949）。pedal は動かない（FCOM p.949）。
- 電源：upper は FCEPSM-1L（故障で 2L）の 26V AC（両 L FCEPSM は AC standby bus から）と 28V DC battery bus、engage relay は FCE DC CB 1・2。lower は FCEPSM-1R（AC bus 1）と DC bus 1・2（p.60–62）。

### 2.5 自動スタビライザートリム（ASTS）

- SRM 2 台（L/R、それぞれ arm 用と control 用のプロセッサ）、STCM 2 台（油圧 2・3。solenoid valve 5 個と MOV）（p.125、p.131、p.160）。SRM の機能：manual trim、FCC autotrim、speed trim、rate control、自動 shutdown（rudder ratio と aileron lockout は ATA 27）（p.125）。
- 電源：L SRM は L FCE PSM（AC standby、battery bus）、shutoff・rate・control は 28V DC bus 3、manual trim も DC bus 3、alternate trim は battery bus。R SRM は 2R PSM（AC bus 2・DC bus 2）、shutoff・rate・control は DC bus 2（p.116–118）。
- FCC との対応：L FCC → L SRM、R → R、C → 両方。SRM の autotrim valid は L SRM → L・C FCC、R SRM → R・C FCC。engage interlock にも使う（p.144、p.224）。
- 他の入力：ADC の CAS（L SRM は Capt ADC が主）、air/ground、gear down（PSEU）、stab・flap 位置（FCU）、各 STCM の brake release（p.120）。

## 3. 操作と表示

### 3.1 MCP・グレアシールド・操縦輪・スラストレバー

| 操作子 | 実機の挙動（要点） | 典拠 |
|---|---|---|
| F/D L/R | ON：自側 PFD に FD。地上・A/P なし・両 OFF から最初の ON で TO/GA（roll・pitch）。飛行中・A/P なし・両 OFF から最初の ON で V/S＋HDG HOLD（bank > 5° なら ATT。570 は HDG HOLD だけ）。A/P engage 中に最初の ON で A/P のモードを表示。OFF：FD を出さない。ただし >80 kt・flap UP 以外で TO/GA を押すと出る（F/D を ON→OFF で消える） | FCOM p.639–640、p.660–661 |
| A/P ENGAGE（CMD L/C/R） | どれか押すと engage。F/D ON ならその F/D のモード、両 OFF なら V/S＋HDG HOLD/ATT。巡航では 2 台目が engage しない（MCP の要求による engage は他チャンネルの servo が engaged でないことが条件。multi は APP からだけ） | FCOM p.640、ATA22 p.266、p.314、図 p.319 |
| DISENGAGE bar | 下げ：全 A/P 解除、engage 禁止、amber stripe。上げ：engage 可 | FCOM p.640 |
| A/P disengage switch（操縦輪） | 1 回目：全 A/P 解除、master warning、>AUTOPILOT DISC、音。自動解除後なら警報のリセット。2 回目：リセット | FCOM p.655 |
| IAS/MACH 窓 | 電源投入 200 kt。100–399 kt、.400–.950。上昇で約 .840 で Mach、降下で約 310 kt で IAS に自動切替。FMC 速度のとき空白。FLCH SPD・V/S・TO/GA・ALT・G/S では開く | FCOM p.642–643 |
| SEL | IAS⇔Mach（Mach 0.4 以上で IAS→Mach）。窓が空白なら無効 | FCOM p.643 |
| IAS/MACH selector 押し | VNAV 中に窓を開閉（speed intervention）。VNAV PTH で降下中に開くと VNAV SPD、制約を捕捉すると PTH。approach 中は PTH のまま A/T が速度 | FCOM p.643 |
| LNAV | arm/select/disarm。50 ft 以上で、active leg から 2.5 NM 以内なら即 engage、外なら intercept heading 上で接近時に engage。intercept heading でなければ CDU に NOT ON INTERCEPT HEADING。最終点・discontinuity・offset の終点などでは現 heading を保持。HDG HOLD/SEL、LOC 捕捉、FMC 二重故障で解除。armed 中の 2 回目で disarm | FCOM p.644–645、p.663 |
| VNAV | arm/select/disarm。400 ft 未満は白で arm、400 ft で engage。データ不足は PERF/VNAV NOT AVAILABLE。TO/GA・FLCH・V/S・ALT・G/S と FMC 二重故障で解除。armed 中の 2 回目で disarm | FCOM p.645、p.664–665 |
| FLCH | FLCH SPD。窓が空白なら FMC 目標速度（無効なら現速度）で開く。TO/GA→FLCH は現速度と選択速度の大きい方。選択高度で ALT。A/T は THR、降下では続いて HOLD | FCOM p.646 |
| HDG 窓・selector | 電源投入 000。LOC 捕捉で ILS front course に変わる | FCOM p.646–647 |
| HDG SEL | HDG SEL（bank limit が効く）。先に方位を選んで押すと近い側へ旋回、押してから回すと回した向きへ旋回 | FCOM p.647、ATA22 p.274 |
| BANK LIMIT | AUTO：TAS・flap・V2 で 15–25°。5/10/15/20/25：その値が上限。FCTM は LNAV にも効き、離陸 flap で V2+10 未満は 15° とする | FCOM p.647、FCTM p.118 |
| HDG HOLD | 翼水平にしてから、その時の heading を保持 | FCOM p.647、p.663 |
| V/S | V/S 以外では窓は空白。押すと現 V/S を表示して V/S。100 fpm 刻み、−8000〜+6000 fpm。選択高度で ALT。A/T は armed なら SPD | FCOM p.648 |
| ALT 窓・selector | 0–50000 ft、100 ft 刻み、電源投入 10000。押し：制約を 1 個削除、上昇中に CRZ ALT を窓の値へ、巡航中は CRZ ALT 変更と VNAV PTH/ALT からの上昇・降下開始、T/D 50 NM 以内で reduced rate descent | FCOM p.649 |
| ALT HOLD | 押した時の高度を保持 | FCOM p.650 |
| LOC | arm/disarm/capture。進入角 120° 以内で捕捉。捕捉前は 2 回目か他のロールモードで disarm、捕捉後は LNAV 以外のロールモード、TO/GA、A/P 解除＋両 F/D OFF で解除 | FCOM p.650–651 |
| APP | LOC と G/S を arm、他の A/P を arm（CMD 灯点灯）し、LOC・G/S 捕捉かつ RA < 1500 ft で engage。G/S は 80° 以内で捕捉。捕捉前は 2 回目、LOC/LNAV/VNAV 選択で disarm。LOC 捕捉・G/S arm 中は LNAV 以外のロールモードで解除（LOC を押すと LOC approach）。G/S 捕捉・LOC arm 中（109/570）は VNAV 以外のピッチモードで解除。捕捉後は TO/GA か A/P 解除＋両 F/D OFF | FCOM p.651–652 |
| TO/GA switch | 地上 50 kt 未満・flap UP 以外：A/T THR REF（A/T 担当）。離陸後（TO 推力のまま）：50–400 ft は TO/GA roll、400 ft 以上は roll と pitch。approach（flap UP 以外か G/S 捕捉）：TO/GA roll・pitch、A/T THR（2000 fpm）、2 回目で THR REF。A/P も F/D も無いときは FD・THR・TO/GA・TO/GA を表示 | FCOM p.656–657 |

- 選択値（速度・Mach・方位・高度）は A/P/F/D の engage 前に設定できる。V/S だけは不可（FCOM p.660）。
- 全モードは A/P 解除＋両 F/D OFF で消える。LOC・G/S 捕捉後は、それか TO/GA でしか解除できない（FCOM p.660）。

### 3.2 FMA と AFDS 状態（PFD）

- 並び：A/T｜roll｜pitch。active は上段に大きい緑、armed は下段に小さい白（TO/GA armed は表示しない）（FCOM p.662–663、ATA22 p.376–378）。
- active roll：TO/GA、HDG HOLD、HDG SEL、LNAV、LOC、ROLLOUT、ATT（109/405）。armed roll：LNAV、LOC、ROLLOUT（FCOM p.654）。
- active pitch：TO/GA、ALT、V/S、VNAV PTH、VNAV SPD、VNAV ALT、G/S、FLARE、FLCH SPD。armed pitch：VNAV、G/S、FLARE（FCOM p.654）。
- AFDS 状態（attitude の上）：FD（F/D ON・A/P なし。ON の側だけ）、CMD（A/P engaged。両側）、LAND 3、LAND 2（緑に白三角）、NO AUTOLAND（amber）、TEST（FCOM p.654、p.662、ATA22 p.250、p.384）。1500 ft RA 未満の multi-channel では autoland 状態が engage 状態に代わる（ATA22 p.250、p.370）。
- モードが変わると 10 秒間緑の枠。NO AUTOLAND への劣化は 10 秒間 amber の枠。故障したモードには amber の横線（FCOM p.653、ATA22 p.369）。
- FD の故障：選択 FCC のデータが無効なら FD 故障旗、bar は視野外へ（ATA22 p.252、p.369、FCOM p.999–1000）。
- 表示の出どころ（EIU）：A/P engaged/armed なら engaged の FCC（Capt 側は L, C, R、F/O 側は R, C, L の順）。F/D だけなら F/D source 切替の FCC。autoland 状態はどれかの FCC が立てれば表示し、NO AUTOLAND > LAND 2 > LAND 3 の優先（ATA22 p.369–370）。
- 典型表示（FCOM p.1082–1107）：離陸前 HOLD｜TO/GA｜TO/GA、armed LNAV・VNAV、FD。上昇 THR REF｜LNAV｜VNAV SPD、CMD。巡航 SPD｜LNAV｜VNAV PTH。降下 HOLD｜LNAV｜VNAV PTH。進入 SPD｜LOC｜G/S、armed ROLLOUT・FLARE、LAND 3。接地後 ROLLOUT、LAND 3。

### 3.3 ヨーダンパー・stab trim の操作と表示

- YAW DAMPER UPPER/LOWER：ON で給電。INOP 灯はスイッチ OFF か YD 不作動（FCOM p.931、p.950、ATA22 p.72）。
- stab trim：操縦輪の 2 連スイッチ（両方を同方向）、ALTN 2 連スイッチ、STAB TRIM cutout（ON/AUTO/CUTOUT。ガードで AUTO）、指示器（unit 表示、greenband、OFF 旗）（FCOM p.927–929、p.944–946）。機構と greenband は ATA 27 担当と重なる。

### 3.4 EICAS メッセージ

| メッセージ | レベル | 条件 | 典拠 |
|---|---|---|---|
| >AUTOPILOT DISC | Warning（109/405 wailer、570 siren） | 全 A/P が解除（手動・自動） | FCOM p.655、p.677 |
| >AUTOPILOT | Caution（beeper） | A/P が degraded mode。engaged のモードが故障 | FCOM p.660、p.677、ATA22 p.382 |
| >AUTOTHROT DISC | Caution | A/T 解除（逆推力による解除では出ない）。A/T 担当 | FCOM p.677 |
| >NO AUTOLAND | LAND 3/2 表示後なら Caution、前なら Advisory | autoland 不可 | FCOM p.677、ATA22 p.373–374 |
| >NO LAND 3 | 同上 | 3 チャンネル autoland の冗長なし | FCOM p.677、ATA22 p.373–374 |
| >STAB TRIM 2, 3 | Advisory | 自動 cutout、CUTOUT 位置、または指令したのに actuator が動かない | FCOM p.958 |
| STAB TRIM UNSCHD | Caution（beeper） | 非指令の stab 動きで自動 cutout しない、または A/P engaged で ALTN trim 使用 | FCOM p.958 |
| >STAB GREENBAND | Advisory | nose gear 圧と greenband の不一致（ATA 27 担当と重なる） | FCOM p.958 |
| >YAW DAMPER LWR, UPR | Advisory | module/actuator 故障、IRU OFF/align、スイッチ OFF、module 電源断 | FCOM p.958、ATA22 p.96 |

- 両 SRM の故障では NO AUTOLAND（advisory、地上はエンジン始動まで抑止）が出て A/P を engage できない（FCOM p.47 TB1-4）。
- 200 ft RA 未満では LAND 3 → LAND 2 を表示しない。NO AUTOLAND への劣化だけ変わる。急がない故障は接地後に表示する（FCOM p.662、ATA22 p.386）。

## 4. 内部ロジック

### 4.1 engage と disengage（ATA22 p.302–324、図 p.319）

- engage の前提：115V AC と 28V DC、28V DC STBY bus（engage 後に失っても外れない）、FCC・MCP・aileron/elevator サーボが有効、inner loop センサ有効。multi-channel は autoland センサも有効（p.302–304）。
- arm の開始：他チャンネルが armed/engaged でなければ MCP の CMD 要求で arm。A/P engaged 中に APP を選ぶと他チャンネルが multi-arm（p.314）。
- arm 禁止：電源監視の故障、arm/engage solenoid が arm 前に通電（hot short）、MCP 無効（p.314）。
- arm 解除：engaged だった他チャンネルが外れたとき、単一チャンネル arm 中に wheel が 25° を超えたとき（p.314）。arm 解除の故障：program pin parity、servo loop、LVDT の断線・短絡、hot short、servo と surface の同期外れ、inner loop センサの二重故障、自己試験、multi-arm 中の autoland センサの二重故障。単一チャンネル arm では aileron 指令 25° wheel 超過の監視を事前試験（p.316）。
- engage の開始（図 p.319）：単一は CMD 要求（1/2 s）で、他チャンネルの servo が engaged でないこと。multi は multi-arm、LOC 捕捉、G/S 捕捉、RA < 1500 ft、track が adjusted runway heading の 2° 以内、がそろって 5 秒後（adjusted runway heading は ILS の滑走路方位と実際の差を最大 5° まで補正）（p.318、p.288、p.294）。
- engage の解除条件（図 p.319）：multi の条件が無くなり他の servo も engaged、autotrim valid 1・2 の両方喪失または flare 中の接地（RA < 5 ft）（単一チャンネル）、GA から巡航モードへの遷移で first-in-command でないチャンネル（p.318）。
- engage 解除の故障：multi では program pin 不一致、rudder servo/servo loop 故障、同種 autoland センサ 2 個故障。単一では aileron 指令 25° 超過、高度の捕捉・保持ができない故障（p.320）。
- detent/camout：detent が失われると multi では解除（2 系は両方、3 系は該当だけ）、単一では AUTOPILOT caution（p.322）。2 系で同種の inner loop/autoland センサ 2 個故障はハードウェア解除（p.322）。
- first-in-command：GA → 巡航モードで残るチャンネル。外れたら L→R→C→L の順に移る（p.324）。
- 解除の警報：全チャンネルの servo が外れると master warning、level A の音、>AUTOPILOT DISC。再 engage か disengage switch で消す（p.380、FCOM p.655）。

### 4.2 モード遷移表（ATA22 p.335・351。○＝可、×＝不可、⊕＝同じモード）

ピッチ（行が遷移元）：

| 元＼先 | T/O | V/S | ALT HOLD | ALT CAPT | FLCH | VNAV | G/A | G/S | FLARE |
|---|---|---|---|---|---|---|---|---|---|
| T/O | ⊕ | ○ | ○ | ③ | ○ | ○ | × | × | × |
| V/S | × | ⊕ | ○ | ○ | ○ | ○ | ○ | ○ | × |
| ALT HOLD | × | ○ | ⊕ | ⊕ | ○ | ○ | ○ | ○ | × |
| ALT CAPT | × | ○ | ⊕ | ⊕ | ○ | ○ | ○ | ○ | × |
| FLCH | × | ○ | ○ | ○ | ⊕ | ○ | ○ | ○ | × |
| VNAV | × | ○ | ○ | ○ | ○ | ⊕ | ○ | ○ | × |
| G/A | × | ① | ① | ③ | ① | ○ | ⊕ | × | × |
| G/S | × | ② | ② | × | ② | × | ○ | ⊕ | ○ |
| FLARE | × | × | × | × | × | × | ○ | × | ⊕ |

①＝400 ft RA 以上で可、②＝LOC active になる前は可、③＝800 ft RA 以上で可。

ロール：

| 元＼先 | T/O | HDG HOLD | HDG SEL | LNAV | LOC | G/A | ROLLOUT |
|---|---|---|---|---|---|---|---|
| T/O | ⊕ | ○ | ○ | ○ | × | × | × |
| HDG HOLD | × | ⊕ | ○ | ○ | ○ | ○ | × |
| HDG SEL | × | ○ | ⊕ | ○ | ○ | ○ | × |
| LNAV | × | ○ | ○ | ⊕ | ○ | ○ | × |
| LOC | × | ① | ① | × | ⊕ | ○ | ○ |
| G/A | × | ② | ② | ② | × | ⊕ | × |
| ROLLOUT | × | × | × | × | × | × | ⊕ |

①＝G/S active の前は可、②＝400 ft RA 以上で可。

- 各モードは「要求 AND TRANS ENABLE → latch（新モード engage で reset）」「latch AND モード有効 → engage」の形（図 p.337–357）。armed はそれぞれの latch を表示する。

### 4.3 モードごとの論理

- T/O（図 p.337）：(Capt または F/O の F/D が OFF→ON のパルス) AND 地上 AND どの A/P も CMD でない → latch。reset は (地上 AND A/P CMD)、A/T SPD、新モード。roll は同じ立ち上がりで T/O roll（図 p.353）。地上は FD 専用。pitch は 8°、roll は翼水平。離陸で roll は対地 track 保持（ATA22 p.264、FCOM p.666）。
- 離陸ピッチ（ATA22 p.264、p.344、FCOM p.664、p.667）：V/S < 600 fpm は姿勢、600–1200 fpm は姿勢と速度の混合、> 1200 fpm は速度。目標は max(V2+10, 回転時速度+10)。5 秒超過で現速度へ（上限 V2+25）。MCP を高くするとその値。片発：故障時速度を V2〜V2+10 に制限（V2 未満なら V2、V2〜V2+10 はその速度、V2+10 超は V2+10）、混合帯は 0–600 fpm。PLI 未満に制限。windshear・片発検出時に保護。
- 離陸の流れ（FCOM p.667–668、FCTM p.112）：65 kt で A/T HOLD（A/T 担当）、100 kt で FMC が気圧高度を記録（LNAV/VNAV の engage 基準）。50 ft で LNAV、400 ft で VNAV（現速度を指令）。T/O は他のピッチ・ロールモードか LNAV/VNAV の engage で終わる。
- G/A（図 p.337）：GA switch AND TRANS ENABLE AND 空中 AND (flap UP 以外 OR G/S engaged) → latch。roll は同時に G/A roll（図 p.355）。APP は解除。pitch 則は離陸と同じ混合（全時間 windshear 保護）。目標は max(MCP, 開始時速度)、5 秒超過で現速度（上限 MCP+25、開始時に MCP+25 超ならその速度）、片発は 0–600 fpm 混合で上限 MCP+10。roll は開始時の track を保持。A/P の engage 状態は維持（multi のまま）。400 ft RA 以上で巡航モードを選ぶと pitch・roll は独立に変わり、multi は first-in-command だけ残る。選択高度に達すると ALT、first-in-command 以外は解除、roll は TO/GA のまま。400 ft 未満は A/P 解除＋両 F/D OFF でしか終わらない。TO/GA switch は、着陸で RA 5 ft を下回ってから 2 秒後に無効になり、RA 5 ft を上回ってから 3 秒後に再び有効になる。windshear：15° か PLI のわずか下の低い方まで pitch up、上昇率 600→1200 fpm（片発 0→600）で速度制御へ移る。F/D OFF でも >80 kt で FD を自動表示（ATA22 p.298、FCOM p.672–675、FCTM p.207、p.209）。
- A/P engage（ATA22 p.266）：F/D ON なら現モード。ただし F/D が地上 T/O なら HDG HOLD と V/S、LOC 捕捉中なら LOC arm・HDG HOLD、G/S 捕捉中なら G/S arm・V/S で再捕捉。F/D OFF なら V/S と、bank ≤ 5° は HDG HOLD、> 5° は ATT（どちらも HDG HOLD 灯）。
- 技法（FCTM）：A/P は機体がトリムされ FD 指令を満たした状態で engage する（p.63、p.112）。MCP のモードが効かないときは A/P 解除＋両 F/D OFF で全モードを消し、再 engage か F/D ON の既定モードから選び直す（p.65）。T/O・G/A からの ALT 捕捉は 800 ft RA 以上（§4.2 の ③）で、低高度の level off では行き過ぎうる（p.124）。
- HDG HOLD（図 p.353）：要求か既定で latch。engage は roll < 3° が 2 秒続いてから、その時の heading を保持（ROLL DOWN で翼水平）（p.272、p.348）。既定：空中で F/D ON・A/P なし・bank < 5°、F/D OFF で A/P engage・bank < 5°、F/D が T/O（地上）・G/A・LOC 捕捉中に A/P engage、HDG SEL 中の HDG REF 切替（p.352）。
- ATT（109/405）：F/D ON（A/P なし）か A/P engage（F/D OFF）で bank > 5°。5–30° はその bank を保持、5° 未満は翼水平へ（HDG HOLD）、30° 超は 30° へ（FCOM p.663、ATA22 p.352）。
- HDG SEL：要求 AND TRANS ENABLE AND 有効。LOC・G/S 捕捉後と GA の 400 ft 未満は禁止。AUTO bank limit は速度で変わる（p.274、p.352）。
- LNAV（図 p.355）：要求 AND TRANS ENABLE で arm（LOC engaged 中は不可）。2 回目、LOC/APP 要求、engage で arm 解除。engage は FMC data valid（飛行計画が入力・activate・execute 済み、50 ft AGL 以上、計算データ有効、捕捉条件）（p.270、p.354）。
- LOC（図 p.357）：LOC/APP 要求 AND TRANS ENABLE で arm。engage は LOC 有効 AND course error < 120° AND 捕捉。G/S 未 engage なら 2 回目（LOC/APP）、LNAV arm、（APP では）VNAV arm で arm 解除。G/S engaged なら新しいピッチモードで解除。捕捉点は GS、進入角、LOC 偏差の関数。捕捉で HDG 窓が滑走路方位になる（p.290–292、p.356）。
- G/S（図 p.343）：APP 要求 AND TRANS ENABLE で arm。LOC armed 中は APP 2 回目・LOC 要求・VNAV/LNAV arm、LOC engaged 中は新ロールモードで arm 解除。engage は捕捉検出（ビーム中心からの距離と偏差変化率）。FLARE engage か新モードで解除（p.292、p.342）。
- V/S（図 p.339）：要求か既定。既定は空中で F/D ON（A/P なし）、F/D OFF で A/P engage、F/D が T/O（地上）・G/S 捕捉中に A/P engage、speed-through-elevator 中に A/T が SPD になったとき（p.338）。engage 時に現 V/S に同期。前が ALT か、TO/GA で降下中なら 000（p.282）。V/S 000 を選ぶと内部は ALT HOLD、表示は V/S のまま（p.282、p.338）。
- ALT：要求、V/S の 0 選択、ALT CAPT、既定で ALT HOLD。既定は FLCH で MCP 高度への捕捉経路から 8000 ft 離れたとき、VNAV で FMC 目標高度が MCP 高度から離れる向きに変わったとき・MCP 高度を越えさせるとき、MCP 高度で master FMC が故障したとき（p.338）。捕捉は 0.05 g まで、表示は ALT（p.286）。
- FLCH（図 p.341）：要求 AND TRANS ENABLE。目標高度が必要。速度は前が VNAV なら FMC 目標、そうでなければ MCP と現速度の大きい方（p.284、p.344）。
- VNAV（図 p.341）：要求 AND TRANS ENABLE で arm（G/S 中は不可）。FMC data valid まで ARM 表示、valid で engage。2 回目と APP 要求で arm 解除、新モードで engage 解除（p.279、p.340）。VNAV SPD：上昇、降下（選択時）、PTH で速度限界に近づいたとき。VNAV PTH：FMC 高度の捕捉・保持、降下。T/D 以降は PTH のまま A/T IDLE、進入高度近くで A/T SPD。VNAV ALT：MCP 高度を FMC 高度より先に捕捉、または FMC 目標が MCP 高度を越えさせるとき（p.279–280、FCOM p.645、p.664–665）。
- FLARE（図 p.343、p.295）：multi-channel engage で arm 表示。engage 高さは沈下率で決まる：8.4 ft/s 以下 40 ft、8.4–12.4 で 40→50 ft、12.4–14.6 で 50 ft、14.6–18.1 で 50→60 ft、18.1 以上 60 ft。G/S を置き換え、接地で消えて nose を下ろす（p.294、p.342、FCOM p.665、p.671）。
- ROLLOUT：multi-channel で arm 表示、約 5 ft（FCOM）で engage、LOC を置き換える。multi でなければ FD だけの rollout で表示は LOC（FCOM p.664、ATA22 p.360）。

### 4.4 制御則（ATA22 p.330–362）

- outer loop（V/S・heading などから姿勢指令）と inner loop（姿勢誤差と姿勢率から舵面指令）。巡航の outer loop は 1 センサで可。outer loop を失うとモード故障で姿勢保持へ反転（p.330）。servo loop は指令と servo 位置を比べ、監視にも使う（p.330）。
- ピッチ（図 p.345・347）：PITCH ATT INTEG は A/P 非 engage 時に姿勢へ同期。ELEV TRIM INTEG は arm 中に servo を舵面へ同期し、engage 後は elevator と SRM（stab trim）に指令。versine で旋回時のピッチ補償。NOSE LETDOWN は接地後かつ 2° 未満で pitch down。モードが無効なら FD 指令は NCD（p.332）。
- V/S：選択値と IRU の inertial V/S の差（p.344）。
- speed-through-elevator（T/O・G/A・FLCH）：ADC 速度との差。最小速度は FMC から、FMC 故障時は FCC が AOA・flap・stab・speedbrake から計算。最大は FMC から、故障時は max operating schedule か flap から（p.344、FCOM p.675）。
- 高度保持：開始時の気圧高度との差＋inertial V/S で減衰。捕捉：捕捉時の MCP 高度との差＋inertial V/S（G/S 以外の全モードで捕捉あり）（p.346）。
- G/S：RA から送信所までの距離を推定（3° 想定）して偏差を直線距離に換算し、その値と変化率で指令。inertial path control を含み、信号を失っても経路を保持（p.346）。
- flare：gear altitude（RA、pitch、アンテナと脚の距離）を使い、1.5 ft/s で GS 送信所の 450 ft 先に接地。25 ft で FMC へ retard 指令（p.294、p.346）。
- ロール（図 p.349）：ROLL ATT INTEG は非 engage 時に roll へ同期。ROLL DOWN は HDG HOLD 開始時と autoland の 5 ft で翼水平。AIL TRIM INTEG は servo 同期と指令（p.348）。
- HDG 系は基準/選択 heading と機首方位の差。T/O・G/A は track（p.358）。LNAV は FMC の steering（希望 track からの偏差）を FD と ROLL ATT INTEG へ（p.358）。
- LOC：捕捉は横方向速度、LOC 偏差、track と滑走路方位の差。追従は RA から距離を推定（3° GS、10,000 ft 滑走路を想定）した直線偏差と変化率。inertial path control で信号喪失・異常時も経路を保持（p.358）。
- runway align（multi-channel のみ）：engage 時から片発対策（aileron と rudder で翼水平か小さく風上側翼下げ）。crab > 10° は 500 ft で 5° の forward slip、5–10° は 500 ft で 5° まで減らし 200 ft で残り、< 5° は 200 ft で全部除く。表示なし。rollout と GA で解除。片発が進入前なら 1300 ft で sideslip（翼水平）、進入中なら検出時。故障エンジン反対側からの強い横風では翼水平 sideslip をしない（p.296、p.360–362、FCOM p.670）。
- rollout：LOC 偏差の距離と変化率で rudder と NWS（multi-channel）。A/P 解除まで続く（p.362、FCOM p.671）。
- FCC の YD 指令：multi-channel approach で両 YDM が無効のときだけ（p.362）。
- A/P が非対称推力を補償している状態で単一チャンネルに戻るか解除すると、rudder はトリム位置へ戻る（FCOM p.670、p.673）。

### 4.5 autoland と状態表示

- LAND 3：電源・engaged FCC・autoland センサが 3 重（fail operational）。LAND 2：FCC とセンサが少なくとも 2 重（fail passive）。NO AUTOLAND：それ以下（ATA22 p.250、p.256、FCOM p.662）。
- NO LAND 3 の原因：IRU（inner/outer）・ILS 受信機・RA の 1 個故障、flap/stab control unit の 1 個故障、LOC/GS アンテナ切替の 1 個故障、FCC・サーボ・servo loop の 1 個故障、ILS/RA が tune/test inhibit に応じない、bus が分離しない、MCP wrap-around 試験故障。同種 2 個で NO AUTOLAND。autoland と無関係な FCC 検出故障も、地上・A/P 解除中は NO LAND 3（level C）で出す（ATA22 p.384）。
- EICAS：multi-channel engaged 中の劣化は level B（beeper）、そうでなければ level C。200 ft 未満では NO AUTOLAND への劣化だけ（p.373–374、p.386）。PFD の NO AUTOLAND は、multi-channel 中に単一へ劣化したとき（10 秒 amber 枠）と、multi-channel approach なのに 600 ft AGL までに LAND 3/2 が出ないとき。後者は flare・rollout を arm しない（FCOM p.653）。
- 乗員の確認：500 ft で autoland 状態を呼称、alert height（200 ft 以上）より上の劣化は高い最低気象条件に移る、AH 以下は NO AUTOLAND 以外は続行（FCTM p.48、p.159、p.165–166）。
- 制限：A/P は離陸後 250 ft 未満で engage しない。MDA から 50 ft 以上下では解除（ILS 結合か GA を除く）。単一チャンネル ILS は 100 ft AGL 未満までに解除。autoland の風は向かい風 25 kt、追い風 10 kt（405・570）／15 kt（109）、横風 25 kt、G/S 最大 3.25°。A/P 中の aileron trim 禁止（FCOM p.79–80）。

### 4.6 警報と注意の分類（ATA22 p.380–383）

- 警報：A/P WARN 1（EICAS メッセージ）と 2（MAWEA の音と灯）を normal と battery の両方で出す（p.380）。
- AUTOPILOT caution は 3 種類。①caution の後に解除：FCC の I/O buffer・MCP wrap-around 故障、MCP の data path/計算故障、IRU 垂直加速度の 2 個目故障、ADC の高度・速度・impact pressure の 2 個目故障。②caution とモード故障（amber 線）：LNAV/VNAV 中の master FMC 故障、multi GA 中の選択 ADC 故障、LOC/GS 捕捉中の LOC/GS 2 個目故障、LOC+GS 捕捉・1500 ft 未満で RA 2 個目故障、IRU outer loop の 2 個目故障、捕捉後の ILS 周波数変更、ILS 2・3 個の NCD。③caution のみ：ground test、単一チャンネルの flare、stab trim 故障、FLCH/VNAV から要求なしに V/S へ遷移、program pin parity、V/S で 1.3 Vs かつ 100 fpm 超の上昇、単一チャンネルでの pilot override（detent trip）（p.382–383）。
- caution は A/P 解除か、条件の無いモードを選ぶと消える（p.254）。FCOM は「影響がモードだけなら A/P は姿勢安定化モードで engaged のまま、amber 線、AUTOPILOT」（p.660）。ILS 干渉監視は短時間なら表示なし、続けば表示（FCTM p.162）。

### 4.7 ヨーダンパー（ATA22 p.83–96、図 p.85・87）

- 動作モード：電源投入 → 地上なら power-up test（最大 5 s、INOP 点灯）→ 合格で ground op（engaged だが指令ゼロ）。空中になると fade-in 5 s → flight mode。着陸で fade-out 5 s → ground op。空中で電源投入なら試験なしで fade-in。故障で fault INOP（解除・INOP）。抜けるのはスイッチの入れ直しか autorecovery（どれかの IRU が NAV に入る、5 s 未満の一時故障）（p.83–84）。
- 指令：dutch roll（横加速度、impact pressure、AOA、yaw rate、roll rate、roll angle、TAS、GS）＋turn coordination（roll angle）＋modal suppression（modal 加速度、最大 1°、ADC overspeed で停止）の和を authority limit で制限。各 YDM は rudder 4° まで（modal 1° を含む）（p.86–87）。

| 有効 IRU | 有効 ADC | authority |
|---|---|---|
| 3 または 2 | 2・1・0 | ±4.0° |
| 1 | 2 | 可変（`資料に記載なし`） |
| 1 | 1 または 0 | ±1.0° |
| 0 | — | INOP（IRU OFF/align で YAW DAMPER メッセージ） |

- 入力が一部無効なら指令を減らす（例：ADC）（p.86）。control と monitor の出力比較、LVDT・servo loop・engage relay の監視で不 engage か解除（p.88）。解除時は solenoid が切れて actuator はばねで中立（p.90）。

### 4.8 自動スタビライザートリム（ATA22 p.105–166）

- 単位：1 unit ≒ 1°（0 unit = +3.0°、15 unit = −12.0°）（p.132）。限界（SRM のソフトウェアで arm 信号を切る）：

| モード | ND 限界 | NU 限界 |
|---|---|---|
| speed trim | 0.8 | 11.6 |
| manual・単一 rate autotrim、脚上げ・flap UP | 1.8 | 11.6 |
| manual・単一 rate autotrim、脚下げか flap 出 | 0.8 | 11.6 |
| full rate autotrim（LAND 2） | `資料に記載なし` | 13.5 |
| alternate | 0.25 | 14.75 |

- 速度（CAS、加速時 230 kt・減速時 220 kt で切替）（p.165–166）：

| | < 220 kt | > 230 kt |
|---|---|---|
| 2 チャンネル（manual、alternate、LAND 2 の full rate） | 0.5°/s | 0.2°/s（manual、alternate） |
| 1 チャンネル（manual、alternate、autotrim） | 0.25°/s | 0.1°/s |

- モード（p.139–140）：電源投入で、地上・A/P なしは disengaged、空中・A/P なしは speed trim、A/P CMD は autotrim。autotrim は A/P CMD で開始。単一 A/P で manual trim を使うと A/P が外れて manual。multi-channel では manual trim を使っても autotrim のまま（FCOM は「操縦輪のスイッチは無効」p.945）。A/P 解除で空中なら speed trim、地上なら disengaged。離陸後 20 s で speed trim。alternate は他と独立。
- manual：arm と control の両信号が同方向で作動（両 STCM、full rate）。column を逆向きに 4.5° 以上動かすと control 信号を切る（alternate は切らない）。manual trim を検出すると autotrim valid を 0 にし、単一 A/P は外れる（p.122、p.142、FCOM p.945）。
- FCC autotrim（図 p.149）：elevator servo 指令が 0.4°（G/S 捕捉中 0.6°）を超えると trim 指令、0.25° で止める。rollout 中は禁止。SRM は 3.5 s 遅らせる。trim の経路は最初に engage したチャンネルで決まり（L→L SRM など）、dead trim で 1 回だけ別経路へ autosequence（A/P 全解除でリセット）。LAND 2 だけ、両 SRM 有効なら 120 ft 未満で full rate（遅れなし、両 SRM）、trim bias（解除時に pitch up）を両 SRM 有効で 120 ft、片方で 190 ft から加え、GA で取り消す。trim fault monitor は非指令・逆向きの動き（unscheduled）と、指令しても動かない（dead trim）を見て A/P caution・解除・NO LAND 3/NO AUTOLAND に使う（p.144–152）。
- speed trim（図 p.159）：速度増で nose up、減で nose down。engage は air data 有効（両 ADC の差 10 kt で無効）、stab 位置と air/ground 有効、空中 20 s、manual・alternate・autotrim でない。engage 時の stab 位置と速度に同期し、120 kt で 0、220 kt で 2.55° NU（最大）となる速度の関数の変化分を指令（図から読み取り）。1 度に 1 台の SRM（電源投入時にランダムで選ぶ）（p.155–158）。
- shutdown（p.162）：unscheduled trim 監視は全モードで有効。どちらかの SRM が unscheduled を検出し、その STCM の brake release があると、その STCM の MOV に 10 s の閉指令（alternate trim 中と cutout switch ON では出さない）。cutout switch を CUTOUT/ON から AUTO にした 5 s 後と、AUTO での電源投入時に 10 s の開指令。FCOM：自動 cutout 後は ON にするまで閉のまま。片方の actuator が動かないと trim は半速（FCOM p.945）。

## 5. 他系統とのつながり

| 方向 | 相手 | 内容 | 典拠 |
|---|---|---|---|
| 入力 | 電源（ATA 24） | FCC L/C/R：AC 3/1/2、DC 3/1/2。警報：DC STBY。MCP：DC 3/2。YD：AC standby・AC 1・DC 1/2・battery。SRM：AC standby・AC 2・DC 2/3・battery | ATA22 p.60–62、p.116–118、p.191 |
| 出力 | 電源（ATA 24） | APP arm で bus isolation 要求、BUS ISOLATED を LAND 3 の条件に | ATA22 p.192–196 |
| 入力 | 油圧（ATA 29） | A/P サーボ L/C/R＝系統 3/1/2、YD upper/lower＝3/2、STCM＝2・3。HYDIM の圧有効は FCC では診断用 | ATA22 p.10–12、p.64、p.218 |
| 入力 | 航法（ATA 34） | IRU×3、ADC×3、RA×3、ILS×3。FCC から ILS TUNE INHIBIT、RA TEST INHIBIT、アンテナ切替 | ATA22 p.200–216 |
| 入出力 | FMC（ATA 34-61） | FMC→FCC：steering、目標速度・高度、vertical steering、min/max 速度。MCP→FMC：モード、選択高度、ALT selector 押し。FMC master switch で全 FCC が同じ FMC | ATA22 p.206–210、FCOM p.649 |
| 入出力 | A/T | ピッチモードが A/T モードを決める（THR/THR REF/IDLE/HOLD/SPD）。SPD switch は VNAV/FLCH/TO/GA 中は無効。V/S 既定：speed-through-elevator 中に A/T が SPD。T/O latch は A/T SPD で reset。flare 25 ft で retard | FCOM p.641–642、ATA22 p.294、p.337–338 |
| 出力 | 舵面（ATA 27） | aileron/elevator/rudder サーボ、NWS（rollout）、stab trim（SRM 経由）、YD actuator | ATA22 p.222、p.224、FCOM p.659 |
| 入力 | 舵面（ATA 27） | flap・stab・speedbrake 位置、column 位置（column cutout） | ATA22 p.120、p.218 |
| 出力 | 表示・警報（ATA 31） | EIU（FMA、状態、FD、選択値、EICAS）、MAWEA（warning）、master caution | ATA22 p.226、p.366 |
| 入力 | 脚・air/ground（ATA 32） | YD・SRM の air/ground、gear down（PSEU）。FCC の air/ground は試験専用で、接地判定は RA | ATA22 p.69、p.120、p.218 |
| 出力 | ステアリング（ATA 32） | rollout で NWS | FCOM p.659、p.671 |

## 6. 実装上の注意

### 6.1 現コードの構造と X-Plane への依存

- AFDS のコードは 3 プラグイン・8 ファイルに散っている：`B747.70.xt.autopilot.lua`（3564 行：MCP、モード、FMA、状態）、`…monitor.lua`（VNAV/LNAV/LOC/GS の実行、A/T 監視）、`…vnav.lua`・`…vnavspd.lua`（VNAV の目標）、`B747.autoland.lua`（flare/rollout）、`B747.19.xt.hydraulics_override.lua`（FD 指令・A/P サーボ PID・autotrim・YD）、`B747.01.xt.manipulators.lua`（F/D switch）、`B747.40.xt.engines.lua`（TO/GA switch）、`B747.60.xt.fltInst02.lua`（TO/GA ピッチ目標）、`B747.45.xt.fltCtrls.lua`（YD の ON 判定、手動 trim）。モード状態は dataref を介して共有し、`B747DR_ap_lastCommand` の 0.1〜0.5 s の待ちで切替の順序を調整している。hydraulics 側のピッチ FD は autopilot 側の FMA 更新より先に走る（OLD_FORK_NOTES §13 と同じ）。
- 何を X-Plane が計算し、何をプラグインが計算するか：

| 機能 | 計算する側 | X-Plane 側で使うもの |
|---|---|---|
| HDG SEL / HDG HOLD | X-Plane の AP（heading select／heading hold）が FD roll を計算。プラグインは 10 個の移動平均を取り aileron の PID へ | `sim/autopilot/heading`、`sim/autopilot/heading_hold`、`sim/cockpit/autopilot/heading_mag`、`sim/cockpit2/autopilot/heading_status`・`heading_hold_status`・`flight_director_roll_deg`・`bank_angle_mode` |
| LNAV | プラグインが目標 heading（現 leg の点への方位＋風補正）を作り、X-Plane の HDG SEL に渡す | 同上 |
| LOC | プラグインが目標 heading（course＋dots×4＋方位差×2＋風補正）を作り、X-Plane の HDG SEL に渡す | 同上と `nav1/2_hdef_dots_pilot`・`nav1/2_display_horizontal` |
| TO/GA roll | X-Plane の FD roll（X-Plane に lateral mode が無い状態） | `flight_director_roll_deg` |
| ATT、ROLLOUT | プラグイン（固定 bank、rudder trim） | `sim/flightmodel2/controls/rudder_trim` |
| 全ピッチモード、flare | プラグイン（`ap_director_pitch` → elevator PID） | X-Plane のピッチモードは使わない（`sim/autopilot/level_change`・`vertical_speed` を replace、X-Plane の高度 dial は 150000 にして捕捉させない） |
| 目標値の置き場 | — | `airspeed_dial_kts(_mach)`、`airspeed_is_mach`、`vvi_dial_fpm`、`TOGA_pitch_deg` |
| A/P サーボ | プラグイン（独自の `laminar/B747/autopilot/servos_on`、`override_control_surfaces`=1） | X-Plane の servo は使わない |
| A/T | X-Plane の A/T は 0.5 s ごとに OFF に戻す（monitor.lua:567-582） | — |
| YD | プラグイン（X-Plane の YD は常に OFF：fltCtrls.lua:740-743） | — |
| stab trim | 手動は X-Plane の pitch trim コマンド、A/P 中はプラグインが `elevator_trim` を直接書く | `sim/flight_controls/pitch_trim_up/down`、`sim/flightmodel2/controls/elevator_trim` |

- ピッチモードの状態は独自 dataref（`laminar/B747/autopilot/vvi_status`・`speed_status`・`altitude_hold_status`・`altitude_hold_ft`・`altitude_dial_ft`）、LOC/GS は `actual_nav_status`・`actual_glideslope_status`（ほかに表示用の `nav_status`・`glideslope_status`）。前者 5 個は ND プラグインの init（`xtlua_nd/init/scripts/B747.61.nd/B747.61.nd.lua:27-31`）で作られている。

### 6.2 ACF_DIFF §3.3 との関係

- コードが実際に依存するのは、X-Plane が計算するロール FD に効く値：`_ott_psi_deg_off_for_full_def`（純正 15 / カスタム 20）、`_ott_psi_sec_into_future`（0.75 / 1.0）、`_ott_psi_sec_to_tune`（0.3 / 5.0）、`_ott_phi_deg_off_for_full_def`（20 / 10）、`_ott_phi_sec_into_future`（1.0 / 1.3）、`_ott_phi_sec_to_tune`（2 / 3）、`_ott_roll_rate`（6 / 4）、`_auto_roll_axis_defaults_free`（0 / 1）。HDG SEL/HOLD・LNAV・LOC・TO/GA の bank の取り方が acf で変わる（`推定`：X-Plane の AP 調整項目の意味からの推定）。
- 依存しないもの：`_fdir_needed_to_engage_servo`（X-Plane の servo を使わない）、`_alt_always_armed`・`_load_alt_presel_on_alt_hit`（X-Plane の高度 dial は 150000）、`_load_presel_on_asi_hit`・`_load_presel_on_vvi_hit`・`_vvi_but_adjusts_pitch`・`_auto_ptch_axis_defaults_free`・`_ott_the_*`（X-Plane のピッチモード不使用）、`_integrated_approach_navigation`・`_ott_gls_*`・`_ott_flare_*`（X-Plane の APR/autoland 不使用）、`_ott_asi_*`・`_ott_atr_*`（X-Plane の A/T は OFF）。
- 作り直しでロール指令をプラグインで計算すれば、§3.3 の差は AFDS に効かなくなる。

### 6.3 作り直すときの注意

- 名前と数値の約束（INTERFACES.tsv）：FMA の数値（armed roll 1–4、active roll 1–7、armed pitch 1–4、active pitch 1–9、A/T 1–5、AFDS 状態 1–5。`init/scripts/B747.70.autopilot/B747.70.autopilot.lua:128-203`）はパネルの `SHOW_EQUAL` が使うので変えない。amber 線・FD 故障旗・TEST は今の数値に入らず、表示には custom acf のパネル変更（承認が要る）か、既存の数値の範囲での工夫が要る。
- コマンド：MCP・CMD・disengage・F/D・HDG REF・APP は `laminar/B747/…` を残す。X-Plane 標準の `sim/autopilot/*`（airspeed/heading/altitude/vertical_speed/bank_limit の up/down、knots_mach_toggle、heading_hold、take_off_go_around）と `sim/engines/TOGA_power` は利用者の操縦桿・キー割当てが使うので、今と同じく replace/wrap して受ける。
- XTLua：`after_physics` は別スレッドで、dataref の書き込みは非同期（ARCHITECTURE.md §1）。モードの latch・遷移表・制御則・表示を 1 つのモジュールで、決まった順に毎フレーム回す（FCC は 25 ms 周期：ATA22 p.233）。0.1〜0.5 s の待ち（`lastCommand`）でつなぐ今の作りはやめる。積分器は A/P 非 engage 時に同期させ（ATA22 p.332、p.348）、ワインドアップを防ぐ（OLD_FORK_NOTES §13 の 2 s の積分巻き上がりは参考）。
- 3 チャンネルは「FCC 3 個の論理を 1 つの関数で 3 回」回し、engage・センサ有効・電源・油圧をチャンネルごとに持つと LAND 3/2・first-in-command・NO LAND 3 を素直に書ける。舵面への出力は今の `sim_pitch_ratio`・`sim_roll_ratio`（controlOverrides）を残してよい。rudder（rollout PCP）と NWS の出口は新しく要る（ATA 27/32 担当と調整）。
- 簡略化してよいもの：機械的な力の投票（チャンネルの指令は 1 つにまとめ、故障したら外すだけ）、LVDT/hot short/program pin の監視、ground test と CMC、MCP の内部チャンネル切替。簡略化してはいけないもの：遷移表と TRANS ENABLE、既定モードと自動反転、multi-channel の engage 条件と LAND 3/2/NO AUTOLAND の決め方、TO/GA の速度則、flare/rollout、警報の分類とリセット。
- 故障モデルが無い現状でも、電源・油圧・IRU・ADC・RA・ILS の有効性は他モジュールから取れる範囲で入れる（NO LAND 3/NO AUTOLAND、ATT 反転、AUTOPILOT caution の土台になる）。

## 7. 現状実装との比較（GAP 候補）

パスは一意なのでファイル名だけ書く（`autopilot.lua`＝`B747.70.xt.autopilot.lua`、`monitor.lua`・`autoland.lua` も同じフォルダ、`hydraulics_override.lua`・`hydraulicsmodel.lua`＝`B747.19.xt.*`）。

| ID | 種別 | 重要度 | 規模 | 内容 | 根拠 | 該当コード |
|---|---|---|---|---|---|---|
| AFDS-01 | 挙動の誤り | 高 | L | ロール指令を X-Plane の AP に頼っている。HDG SEL/HOLD は X-Plane の FD roll、LNAV と LOC は目標 heading を X-Plane の HDG SEL に渡す近似、TO/GA roll は X-Plane に lateral mode が無いまま（track 保持なし）。FD roll は 10 サンプルの移動平均で遅れる。ATT は 30° 制限・5° 未満での HDG HOLD 移行が無い。bank limit AUTO は X-Plane の `bank_angle_mode`=4（20° 固定） | ATA22 p.348、p.352、p.358；FCOM p.647、p.663；FCTM p.118 | `hydraulics_override.lua:408-425`、`:805-834`；`autopilot.lua:2633-2640`、`:1362-1382`、`:3454`；`monitor.lua:741-863` |
| AFDS-02 | 挙動の誤り | 高 | M | LOC/APP：両受信機に信号があるだけで LOC 捕捉（遠方・full scale でも捕捉し LNAV を解除）。追従は dots と方位差からの heading。いったん乗った後に両受信機の dots の和が 4 を超えると捕捉を解除し、信号断でも armed に戻る（inertial path なし）。G/S は LOC 捕捉後・1.5 dots 以内（405 の挙動だけ）、arm は 3500 ft RA 未満。APP 押下で即 HDG を course に（実機は LOC 捕捉時）。ILS 自動同調が無いと LOC/APP を arm せず RW/ILS CRS ERROR。LOC の 2 回目で disarm しない | FCOM p.646–647、p.650–652；ATA22 p.290–292、p.342–343、p.356–358 | `monitor.lua:731-776`；`autopilot.lua:2397`、`:2419`、`:2430-2444`、`:2519-2537` |
| AFDS-03 | 挙動の誤り | 高 | M | TO/GA：ピッチ目標が速度に比例する姿勢（Vs で 2°、V2+10 で 12°）で、V2+10〜V2+25／MCP+25 の速度保持、600–1200 fpm の混合、片発目標、windshear 15° が無い。pitch と roll を 1 つのフラグ（TOGA_status）で持つので、ALT 捕捉・FLCH で roll の TO/GA も消え、HDG SEL/HOLD を選んでも FMA は TO/GA のまま。ALT 捕捉の窓に入ると高度に関係なく TO/GA を消す（実機は T/O・G/A からの捕捉は 800 ft RA 以上）。飛行中の TO/GA switch は arm 条件（flap UP 以外か G/S 捕捉）を見ない。離陸後 50–400 ft の roll だけ、接地後 2 s の無効化、F/D 自動表示（>80 kt）が無い | FCOM p.656–657、p.661、p.663–668、p.672–675；ATA22 p.264、p.298、p.336–337、p.344 | `B747.60.xt.fltInst02.lua:3083-3117`；`hydraulics_override.lua:754-763`、`:612-619`；`autopilot.lua:2623`；`B747.40.xt.engines.lua:542-575` |
| AFDS-04 | バグ | 高 | L | autoland：flare/rollout は engaged 3 チャンネルのときだけ動き、LAND 2 では flare せず G/S のまま接地。flare は 50 ft 固定、目標ピッチは事前平均ピッチ＋1–2.5°（1.5 ft/s・GS 送信所 450 ft 先の接地則ではない）。IDLE 表示 40 ft（FCOM 25 ft）、ROLLOUT は 4.5 ft＋pitch。rollout は HSI OBS との heading 差で rudder trim を動かす（LOC 偏差・NWS なし）。runway align・decrab・片発補償が無い。接地後 65 kt で A/P を自動解除し、AUTOPILOT DISC も出さない | FCOM p.670–672；ATA22 p.294–296、p.342、p.346、p.360–362、図 p.295 | `autoland.lua:21`、`:63-84`、`:101-104`、`:148-160`、`:219-221`、`:287-297`、`:354-359` |
| AFDS-05 | 欠落 | 中 | L | multi-channel：APP 押下（1500 ft 超、A/P engaged）で 3 チャンネルの CMD を即 1、1500 ft 未満の LOC+GS 捕捉で即 engage（5 s 遅れ・2° 条件なし）。LAND 3/2 は engaged の数だけで決め、bus isolation・センサ冗長・200 ft 以下の抑止なし。PFD の NO AUTOLAND は 200–1000 ft で LOC も GS も未捕捉のとき（実機は 600 ft までに LAND 3/2 が出ないとき）。first-in-command、GA 後の巡航モード選択・ALT 捕捉での単一化が無い | FCOM p.651、p.653、p.662、p.673；ATA22 p.192–196、p.250、p.288、p.294、p.318–324、p.384–386 | `autopilot.lua:2406-2412`、`:2475-2489`、`:2959-2991` |
| AFDS-06 | 欠落 | 高 | S | A/P engage の既定モード：F/D OFF で CMD を押しても V/S＋HDG HOLD/ATT にならない。モードが何も選ばれていなければ FMA は空白のまま、A/P サーボは何もしない。F/D が地上 TO/GA・LOC/GS 捕捉中の engage の扱いも無い。F/D 側の ATT は 30° 制限と 570 型の区別が無い | FCOM p.639–640、p.663；ATA22 p.266、p.338、p.352 | `autopilot.lua:830-895`；`hydraulics_override.lua:986`、`:1026`；`B747.01.xt.manipulators.lua:1256-1270` |
| AFDS-07 | 挙動の誤り | 高 | S | V/S の同期：V/S 押下で目標を 0 fpm にする。F/D ON の既定 V/S も前回の dial 値。実機は現 V/S（前が ALT か TO/GA で降下中なら 000） | FCOM p.648、p.665；ATA22 p.282、p.344 | `autopilot.lua:786-792`；`B747.01.xt.manipulators.lua:217-223`、`:1261` |
| AFDS-08 | 挙動の誤り | 高 | M | LNAV/VNAV/SPD：LNAV は arm 後 RA 50 ft 超で無条件 engage（2.5 NM・intercept 判定、NOT ON INTERCEPT HEADING なし）。active の LNAV/VNAV を押すと解除する（実機は armed のときだけ disarm）。SPD switch が VNAV を解除する（実機は VNAV/FLCH/TO/GA 中は無効）。TO/GA が VNAV を解除しない（`vnav_state` が残り、VNAV の処理が内部のピッチフラグと目標高度を書き続けるので、ALT 則に落ちて TO/GA が消えうる）。VNAV のサブモード表示は内部フラグからの推定（−500 fpm を VNAV SPD とみなす等）で、speed intervention 中の PTH→SPD 表示が無い | FCOM p.642–645、p.663–665；ATA22 p.270、p.279–280、p.340–341、p.354–355 | `autopilot.lua:2877-2881`、`:1029-1037`、`:1064-1066`、`:582`、`:2761-2787`；`monitor.lua:469-530`；`hydraulics_override.lua:603-619`；`B747.40.xt.engines.lua:542-575` |
| AFDS-09 | 挙動の誤り | 中 | M | 遷移規則と相互 disarm：FLCH・V/S・ALT が G/S 捕捉後も内部フラグを変える（FMA は G/S を優先表示）。LOC 捕捉後・G/S 前に HDG SEL/HOLD へ戻せない。GA の 400 ft 未満でも HDG SEL などを選べる。LOC/APP で LNAV arm が消えない、LNAV/VNAV で APP が消えない、APP で VNAV arm が消えない。A/P を使わず両 F/D を OFF にするとモードが残る | ATA22 p.335、p.343、p.351、p.354–357；FCOM p.651、p.660 | `autopilot.lua:732-827`、`:2596`、`:2700`、`:2724`；`monitor.lua:741-776` |
| AFDS-10 | 挙動の誤り | 中 | L | ピッチ制御則：全モードを「ピッチ目標を少しずつ増減する」則で作り、10 サンプル平均とモード変化後 0.7 s の固定がある。ALT 捕捉は V/S に比例する窓（200–1000 ft）と「誤差×2 fpm」で 0.05 g の捕捉則ではない。ピッチ制限は V/S 系 −3.5〜10°、FLCH −3.5〜15°。G/S は dots を fpm に換算（RA による直線偏差・inertial path なし）。integrator・versine・inner/outer loop の構造が無い | ATA22 p.286、p.330–332、p.344–346 | `hydraulics_override.lua:436-456`、`:463-483`、`:504-803`、`:901-923`；`autopilot.lua:2348` |
| AFDS-11 | 欠落 | 中 | M | 速度保護と自動反転：min/max は Vmc+10 と flap 別の固定値で、全モードの速度目標を切る。FMC の min/max（5 kt 余裕）、FMC 無効時の FCC 計算、保護が VNAV SPD/FLCH/TO/GA だけ、が無い。V/S 既定（speed-through-elevator 中に A/T が SPD）、ALT HOLD 既定（FLCH の 8000 ft 逆行、VNAV の条件）、V/S での 1.3 Vs caution が無い | FCOM p.675；ATA22 p.338、p.344、p.382 | `autopilot.lua:1942-1997` |
| AFDS-12 | バグ | 中 | S | AUTOPILOT caution が出ない：`simDR_autopilot_fail` を定義していない。mode fail の amber 線、FD 故障旗、TEST を出す dataref も無い（表示には custom acf のパネル変更が要る） | FCOM p.653、p.660、p.677；ATA22 p.252、p.369、p.376–383 | `autopilot.lua:3386-3390` |
| AFDS-13 | 欠落 | 中 | M | NO LAND 3／NO AUTOLAND の EICAS：caution [49]・[50] と advisory [248] を誰も立てない。advisory [246] を PFD の NO AUTOLAND 条件で出している。表示前後でのレベル切替、地上の level C、接地後表示が無い | FCOM p.662、p.677；ATA22 p.373–374、p.384–386 | `autopilot.lua:2992-2996`；`B747.87.xt.warning.lua:157-158`、`:432-434` |
| AFDS-14 | 挙動の誤り | 低 | S | AUTOPILOT DISC：型式によらず wailer（570 は siren）、wailer の最低 1 秒なし。disengage bar を上げると warning が消える（実機は disengage switch か再 engage） | FCOM p.640、p.655、p.677；ATA22 p.254、p.380 | `B747.87.xt.warning.lua:806-808`；`autopilot.lua:919-921` |
| AFDS-15 | 欠落 | 中 | M | engage インターロック：CMD は RA > 400 ft と他チャンネル無しだけを見る（実機は地上でも engage でき、250 ft は運用制限）。MCP 有効、DC STBY、センサ有効、SRM の autotrim valid、25° wheel 超過、detent/camout（単一は caution、複数は解除）が無い。pilot の入力は A/P 出力に足されるだけ | ATA22 p.302–322；FCOM p.79–80、p.47 | `autopilot.lua:837`、`:863`、`:884`；`hydraulicsmodel.lua:577-578`、`:600-601` |
| AFDS-16 | 欠落 | 中 | S | AFDS の電源：FCC L/C/R（AC 3/1/2・DC 3/1/2）、MCP（DC 3/2）、警報（DC STBY）を見ない。油圧だけ 1000 psi で見る | ATA22 p.191、p.304 | `autopilot.lua:2480-2499` |
| AFDS-17 | 挙動の誤り | 中 | M | YD の則：bank < 5° は 0.9 s の heading 平均との差、> 5° は sideslip を PID で戻す（5° で則が切り替わる）。地上でも動く（ground op、5 s fade-in/out なし）。出力 ±3.5 を rudder ratio changer で縮める。dutch roll 減衰・turn coordination・modal suppression・±4° と IRU/ADC 数による縮小・overspeed で modal 停止が無い | ATA22 p.50–52、p.83–90、図 p.85・87；FCOM p.949 | `hydraulics_override.lua:426-432`、`:836-899`、`:1048-1103`；`hydraulicsmodel.lua:566-567` |
| AFDS-18 | 挙動の誤り | 低 | S | YD の有効条件：battery switch と IRS 切替位置 NAV（align 中も有効）だけで INOP を決める。電源（FCEPSM/AC standby、AC 1、DC 1/2、battery）、油圧 3/2、power-up test（地上で最大 5 s INOP）、fault と autorecovery、FCC の YD 指令（両 YDM 無効の multi approach）が無い | ATA22 p.60–64、p.83–84、p.88、p.96、p.362；FCOM p.931、p.958 | `B747.45.xt.fltCtrls.lua:714-744`、`:1170-1184`；`B747.90.xt.lighting.lua:1329-1330` |
| AFDS-19 | 挙動の誤り | 中 | M | A/P 中の autotrim：pitch ratio（pilot 入力込み）が窓を越えると `elevator_trim` を 1 フレームだけ動かして 1.2 s 待つ。速度は 220/230 kt で 30/60 s フルレンジ（≈0.5/0.25 unit/s）。RA 500 ft 未満は trim しない。実機は elevator サーボ指令 0.4°（G/S 0.6°）〜0.25°、SRM で 3.5 s 遅れ、単一チャンネル 0.25°/s・0.1°/s、LAND 2 の full rate と trim bias、rollout で禁止、unscheduled/dead trim 監視と autosequence | ATA22 p.144–152、p.165–166、図 p.149 | `hydraulics_override.lua:925-957` |
| AFDS-20 | 欠落 | 中 | M | stab trim（ASTS 側）：手動 trim は X-Plane の pitch_trim を 1 スイッチで直接動かし、速さは acf の `_elev_trim_time`（25 s、`推定`）で速度に依らない。2 スイッチ同時、速度別レート、油圧 2/3（片方で半速）、モード別の限界、column cutout、単一 A/P での trim による解除・multi での無効、cutout switch・ALTN trim、unscheduled trim の自動 shutdown、STAB TRIM 2/3・UNSCHD・GREENBAND、speed trim が無い。ATA 27 担当と重なる | FCOM p.927–929、p.944–946、p.958；ATA22 p.131–166、図 p.159 | `B747.45.xt.fltCtrls.lua:233-289` |
| AFDS-21 | 挙動の誤り | 低 | S | MCP の細部：IAS の初期値 100 kt（実機 200）。MCP 高度の変更を 3 s 後に反映し、その間は古い高度で捕捉する。HDG REF（TRUE）を AFDS が使わない。F/D source 切替が効かない。ALT selector 押しの制約削除・reduced rate descent が無い（FMC 担当と重なる）。TO/GA→FLCH で現速度と選択速度の大きい方にしない | FCOM p.643、p.646、p.649、p.1043；ATA22 p.220、p.236、p.344 | `autopilot.lua:3434`、`:1426-1479`、`:660-716`；`B747.01.xt.manipulators.lua:1479-1481` |
| AFDS-22 | 挙動の誤り | 中 | S | acf 依存（ACF_DIFF §3.3）：ロール FD を X-Plane が計算するため、`_ott_psi_*`・`_ott_phi_*`・`_ott_roll_rate`・`_auto_roll_axis_defaults_free` の違いで HDG SEL/HOLD・LNAV・LOC・TO/GA の bank の取り方が 2 つの acf で変わる（`推定`）。ほかの §3.3 の項目はコードが使っていない（§6.2）。AFDS-01 で解消する | ACF_DIFF §3.3 | `hydraulicsmodel.lua:181`（`flight_director_roll_deg` の読み込み）；`hydraulics_override.lua:422-423` |
| AFDS-23 | 欠落 | 低 | S | ILS/RA の inhibit：LOC/GS 捕捉後も ILS 自動同調が 2 s ごとに周波数とコースを書く。ILS TUNE INHIBIT、RA TEST INHIBIT、アンテナ切替の監視が無い（ATA 34 担当との境界） | ATA22 p.212–216 | `autopilot.lua:1621-1800` |
| AFDS-24 | 挙動の誤り | 低 | S | VNAV 上昇中に遷移高度で自動的に両高度計を STD にする。資料に無い機能（FMC・EFIS 担当と重なる可能性） | FCOM p.645、p.664–665（VNAV の機能に記載なし） | `B747.70.xt.autopilot.vnavspd.lua:426-433` |

- 正しく実装されている点：A/P サーボの油圧 L/C/R＝3/1/2 による解除（`autopilot.lua:2491-2499`）。CMD は他チャンネルが無いときだけ engage（`:837`、`:863`、`:884`）。disengage switch の 1 回目／2 回目と自動解除後のリセット（`:925-967`）。FMA の 10 秒枠と NO AUTOLAND の amber 枠（`:3022-3125`）。IAS/MACH の .84・310 kt 自動切替と SEL の Mach 0.4（`:1239-1260`、`:1910-1934`）。V/S の範囲と刻み（`:1384-1424`）。MCP 灯の大半（`B747.90.xt.lighting.lua:1655-1667`。APP 後に 3 個の CMD 灯が点くのも実機どおり）。F/D ON の地上 TO/GA と空中既定（`B747.01.xt.manipulators.lua:1245-1270`、ただし AFDS-06・07）。

## 8. 作り直しか部分修正か

**推奨：AFDS（モード論理・制御則・表示・autoland）は作り直す。ヨーダンパーと ASTS も新しいモジュールとして作る。作り直しの前に、S 規模の誤りだけ先に直してよい。**

- 理由：
  - 骨格が X-Plane の AP に乗っている。ロールは X-Plane の HDG 系を流用し、LNAV と LOC はそれに目標 heading を渡す近似、ピッチは独自の「少しずつ足す」則、autoland は別ファイルの別の則で、どれも実機の FCC の構造（outer/inner loop、integrator の同期、TRANS ENABLE と latch、既定と反転）と違う。部分修正を重ねても、遷移表・既定モード・multi-channel・TO/GA の独立性は入れにくい。
  - 状態が 8 ファイル・3 プラグインに散り、0.1〜0.5 s の待ち（`lastCommand`）と実行順で整合を取っている。旧フォークは 369 コミットで同じ構造を調整し続け、ピッチ・ロール・autoland に未解決を残した（OLD_FORK_NOTES §1・§2・§7・§12・§13。参照のみ）。
  - acf の X-Plane AP 調整値にロールの挙動が左右される（AFDS-22）。
- 作り方の案（L 規模、数週間）：
  1. FCC の状態機械（§4.2 の遷移表、§4.3 の latch・既定・反転、§4.1 の engage・3 チャンネル・first-in-command）と FMA/状態表示を 1 モジュールに置く。FMA の数値と INTERFACES.tsv の名前は残す。
  2. ロールの指令（HDG/TRK、LNAV は FMC の steering 量、LOC の捕捉・追従、ATT、TO/GA track、runway align、rollout）をプラグインで計算し、X-Plane の HDG モードと FD を使わない。
  3. ピッチの指令（V/S、ALT と 0.05 g の捕捉、speed-through-elevator と保護、VNAV、G/S、flare）を同じモジュールで、FCC と同じ周期で計算する。舵面への出口（`sim_pitch_ratio`・`sim_roll_ratio`）は今のものを使う。
  4. autoland（multi-channel の engage、LAND 3/2/NO AUTOLAND、flare、rollout の rudder と NWS、片発・decrab）。電源（ATA 24 の bus isolation）・油圧・センサ有効を入れる。
  5. YD（モード、則、authority、INOP）と ASTS（autotrim、speed trim、rate、限界、shutdown、手動・ALTN との関係）。ASTS は ATA 27 担当と分担を決める。
- 先に直してよいもの（S）：AFDS-06（既定モード）、AFDS-07（V/S 同期）、AFDS-12（AUTOPILOT caution の未定義変数）、AFDS-04 のうち LAND 2 でも flare させる条件、AFDS-08 のうち LNAV/VNAV の 2 回目と SPD switch、AFDS-21 の IAS 初期値。
- FMC 担当との取り合いは、FMC が「希望 track・track 角誤差・cross track」「vertical steering（目標 V/S・経路偏差）」「目標速度・min/max 速度」「VNAV のサブモード要求」を出し、AFDS がそれを受けて arm・engage・反転を決める形にする（ATA22 p.206、p.346、p.358）。

## 9. 未確認事項

1. パネルの `SHOW_GREATER 1 laminar/B747/autopilot/FMA/active_pitch_mode`（FD pitch bar）と `…active_roll_mode`（FD roll bar）が「> 1」なら、TO/GA（=1）では FD bar が出ない（`747-400.acf:85146-85180`、`:88735-88770`、`:92342`、`:95910`）。X-Plane で TO/GA の FD bar が見えるか確かめる。見えないならパネル変更（custom acf、承認が要る）が要る。ATA-28 ノートも同じ問い（以上か超か）を挙げている。
2. disengage bar で `sim/autopilot/servos_fdir_off` を出す（`autopilot.lua:913-916`）と X-Plane の FD と HDG モードが切れ、F/D ON のまま HDG SEL/HOLD の roll 指令と FMA が消えるか（X-Plane で確認）。
3. X-Plane の `heading_hold` が「翼水平にしてから保持」か「押した時の heading へ戻る」か。TO/GA 中（X-Plane に lateral mode が無い）の `flight_director_roll_deg` が `_auto_roll_axis_defaults_free`（純正 0／カスタム 1）でどう変わるか。
4. YD の authority「可変」（IRU 1・ADC 2）の中身と、TAS による authority の変化は `資料に記載なし`。ratio changer で YD を縮める今の作りの根拠も無い。
5. LNAV・LOC・GA の bank 上限、FCC のピッチ指令の上下限、LOC 捕捉点と G/S 捕捉検出の数式、ALT 捕捉の開始条件（0.05 g 以外）は `資料に記載なし`。
6. A/P サーボの「油圧あり」の閾値（コードは 1000 psi）。FCC は HYDIM の圧有効を診断にしか使わない（ATA22 p.218）ので、実機では servo loop の故障として外れる（`推定`）。
7. 3D コクピットに STAB TRIM cutout switch と ALTN trim switch の操作子があるか（コマンドは Lua に無い）。F/D source selector・HDG REF の操作子は INTERFACES.tsv にある。
8. RR 型の AUTOPILOT DISC の音、ATT・G/S 捕捉順の型式（FCOM の 109/405/570）をリバリー（エンジン型式）にどう対応させるか。
9. speed trim を X-Plane の機体モデルの上でどこまで入れるか（手動操縦の速度安定に効く。trim 指示器が自動で動くのは乗員に見える）。
10. full rate autotrim（LAND 2）の ND 限界は `資料に記載なし`。
