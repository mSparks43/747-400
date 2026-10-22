# ATA 24 Electrical Power（電源）— 調査ノート

対象コード：`overhaul` ブランチ（feedd8a9。plugins と acf は本家 041c9ffa のまま）。2026-10-23 調査。GAP の ID 接頭辞は `ELEC`。

## 1. 概要

- 範囲：AC 発電（IDG・APU 発電機・外部電源）、GCB/BTB/SSB/APB/XPC と電源切替、transfer bus、standby、ground handling / ground service bus、DC（TRU・DCIR・バッテリー母線）、充電器、IDG drive と disconnect、utility/galley の負荷管理、autoland 時のバス分離、ELEC synoptic と EICAS メッセージ。APU 本体・点火セレクター・照明・表示切替は他章だが、現コードでは電源モジュールに同居しているので比較には含めた。
- 資料と範囲：
  - LH24 全頁（p.3-249。p.250-256 は目次）。Lufthansa の PW 機（747-430、旅客）。GCU/BCU/AGCU の内部ロジックはこれしかない。図は p.7, 9, 21, 27, 31, 61, 73, 103, 105, 121, 123, 127, 151, 155, 159, 163, 183, 215, 217, 219, 225, 229, 237, 247, 249 を画像で確認した。
  - FCOM 6.10（p.779-794）、6.20（p.795-820）、6.30（p.821-824）、SP.6（p.179-182）、NP.21 の電源の手順（p.103-104, p.150-151）、7.14（p.867）、7.30（p.895-897）。FCOM の 6.20.26 にあるはずの系統図（foldout）は PDF に無い。
  - 消費側を補うため FCOM 全体をバス名で検索し、他章の記述（p.444, p.504, p.955, p.1074-1075, p.1217）も 5 章の表に入れた。
- FCOM の型式番号（FCOM p.5 (0.1.1)）：405 = Boeing Converted Freighter（PW）、109 = Passenger（PW）、570 = Freighter（GE）。
  - 本機は旅客型なので **109 を基準**にする。109 と 570 は standby が main standby bus と APU standby bus の 2 本で共通。405 だけ standby bus 1 本＋APU alternate power＋ALTN EFIS selector。
  - simconfig で FREIGHTER を選んだときは 570 を当てるのが自然（推定）。違いは main deck cargo handling bus があり galley bus が無い点。
- 資料どうしの食い違い（どちらを採ったか）：
  - GHB の優先順位：FCOM p.799 は「両方 available なら EXT」、LH24 p.6 は「先に来た方」→ FCOM を採る。
  - IDG disconnect の電源：FCOM p.819 は main battery bus、LH24 p.61（図 33）は 28V DC hot bat bus の CB → 乗員から見えないので FCOM の記載で表に入れ、両方を書いておく。
  - IDG 油温の advisory 閾値：LH24 p.72-73 の論理図は oil out >185 °C、p.116 の保守ページの説明は 142 °C advisory / 185 °C caution → 論理図（185 °C）を採る。
  - synoptic の正常時の DRIVE 枠：FCOM p.792 は「blank (green)」、LH24 p.30 は「white」→ FCOM。

## 2. 構成

### 2.1 電源

| 電源 | 主な値 | つながり | 根拠 |
|---|---|---|---|
| IDG 1-4 | 3 相 400 Hz 115 V、90 kVA。CSD で発電機を 12,000 rpm に保つ | GCB → AC bus n。BTB → 同期バス | LH24 p.50 (24-10), p.92, p.96 (24-20) |
| APU GEN 1/2 | 90 kVA、380-420 Hz。地上専用 | APB 1 → 同期バス左、APB 2 → 右 | LH24 p.124, p.134 (24-20); FCOM p.895 (7.30.1) |
| EXT PWR 1/2 | 3 相 400 Hz 115 V、レセプタクル各 250 A。1 = 後方（BCU 1）、2 = 前方（BCU 2） | XPC 1 → 同期バス左、XPC 2 → 右 | LH24 p.34, p.36 (24-00) |
| main / APU battery | 24 V 40 Ah NiCd | 各 hot battery bus に直結 | LH24 p.190 (24-30); FCOM p.820 (6.20.26) |
| main / APU battery charger | GSB から 3 相給電。充電：38 A 定電流 → 27.75 V 定電圧。TR mode：27.75 V・最大 64 A | 各 hot battery bus | LH24 p.192-196 (24-30) |
| TRU 1-4 | 75 A、28 V DC（出力電圧は無調整） | AC n → DC n | LH24 p.116 (24-20), p.162, p.174 (24-30) |
| main / APU static inverter | 1 kVA、単相 115 V 400 Hz、入力 18-36 V DC | main standby bus / APU standby bus | LH24 p.154, p.158 (24-20) |
| GH TRU A/B | 20 A | GHB → DC GHB（2 本） | LH24 p.212 (24-30) |
| LH のオプション | towing static inverter、APU TRU | 109 の FCOM には無い（570 は APU start TR あり：FCOM p.895） | LH24 p.160, p.206-210 |

### 2.2 母線（バス）

| バス | 通常の電源 | 切替先と条件 | 根拠 |
|---|---|---|---|
| AC 1-4 | IDG n（GCB） | 同期バスから BTB 経由 | LH24 p.6 (24-00); FCOM p.798 (6.20.4) |
| 同期バス | 左：BTB1・BTB2・XPC1・APB1／右：BTB3・BTB4・XPC2・APB2 | 左右は SSB でつながる | LH24 p.7, p.9 (24-00) |
| CAPT XFR | AC 3 | AC 1（IBVSU、条件は 4.6） | LH24 p.228 (24-50); FCOM p.799-800 |
| F/O XFR | AC 2 | AC 1 | 同上 |
| main standby（AC STBY） | AC 3（STBY PWR AUTO のとき） | main static inverter | LH24 p.150 (24-20); FCOM p.804 (6.20.10) |
| APU standby | CAPT XFR | APU static inverter | LH24 p.158-159 (24-20); FCOM p.804 |
| GSB、GS utility bus | AC 1（GS utility は L UTILITY ON かつ U-ELCU 1 経由） | 地上で ground service switch を押すと EXT1 か APU GEN1（EXT 優先） | LH24 p.38, p.40 (24-00), p.216 (24-40); FCOM p.799 |
| GHB（2 区分）、DC GHB | EXT1 か APU GEN1（地上で自動。EXT 優先） | 空中・air mode では非通電 | LH24 p.6, p.214 (24-40); FCOM p.799 |
| utility 1-4 / galley 1-4（109） | AC n から ELCU 経由 | L UTILITY：1・2、R UTILITY：3・4 | FCOM p.781, p.800-801 |
| DC 1-4 | TRU n | DCIR を介して DC tie bus で相互に給電 | LH24 p.20, p.166 (24-30); FCOM p.819 |
| main / APU battery bus | DC 3（battery transfer relay R7224） | 各 hot battery bus（main battery relay R7223。BATTERY ON が必要） | LH24 p.182 (24-30); FCOM p.819-820 |
| main / APU hot battery bus | 充電器（GSB 給電時） | 各バッテリーに常時直結 | FCOM p.820 |
| main deck cargo handling bus（405, 570 のみ） | EXT2 か APU GEN2（地上。EXT 優先。主母線とは排他） | — | FCOM p.802 |

### 2.3 制御装置

- GCU×4：BTB・GCB・GCR、auto paralleling、auto bus isolation、冷却弁、anticycling。保護：underspeed、OV/UV、OF/UF、差動、open phase、ダイオード、difference current、過/不足励磁、shorted PMG、reverse power、CPU 故障（LH24 p.98）。
- AGCU×2：APU 発電機の電圧調整、APB、power ready（LH24 p.112, p.140, p.144）。
- BCU×2：XPC・APB・SSB（SSB は BCU 2 が駆動）、no-break power transfer（NBPT）、GH/GS バス、負荷管理、autoland 時の分離、EIU と CMC への出力。EIU は BCU 1 の情報を使い、BCU 1 が故障したら BCU 2 を使う（LH24 p.112, p.114, p.140）。
- IBVSU×2（transfer bus）、ELCU×8（galley 4、utility 4）（LH24 p.228, p.232）。

## 3. 操作と表示

### 3.1 P5 electrical panel（括弧内は現コードの `laminar/B747/button_switch/position` の添字 / `laminar/B747/annunciator/brightness_ratio` の添字）

| 操作部 | 機能 | 表示灯 | 根拠 |
|---|---|---|---|
| STANDBY POWER（OFF/AUTO/BAT。OFF へは押して回す。`standby_power/sel_dial_pos` 0/1/2） | OFF：main と APU の standby bus を全電源から切る。AUTO：使える電源から給電。BAT：BATTERY ON なら main/APU battery bus を hot battery bus から、両 standby bus をインバーターから給電し、両充電器を止める。地上整備用 | — | FCOM p.780-781 (6.10.2-3); LH24 p.158 |
| BATTERY（カバー付き alternate action、[13] / 灯[10]） | ON：両バッテリーを battery bus と standby bus のバックアップにする。OFF：battery bus から切り離す | OFF（amber）＝スイッチ OFF。DC 母線に電源があるときに点く | FCOM p.781; LH24 p.164 (24-30) |
| L / R UTILITY（[11]/[12]、灯[8]/[9]） | ON：ELCU に給電（109：utility 2 個＋galley 2 個）。OFF：給電を切り、故障ロジックをリセット | OFF（amber）：故障で ELCU が開、スイッチ OFF、galley 非常スイッチ OFF（109）。負荷制限（load shed）中は点かない | FCOM p.781-782 (6.10.3-4) |
| EXT PWR 1/2（momentary、[14]/[15]、灯[11]-[14]） | AVAIL 点灯中に押すと接続、ON 点灯中に押すと切離し | AVAIL（white）：プラグ接続かつ品質良、ON が点くと消える。ON（white）：接続中 | FCOM p.784 (6.10.6) |
| APU GEN 1/2（[16]/[17]、灯[15]-[18]） | 同上 | AVAIL：APU 発電機の品質良。ON：接続中。どちらも空中では消灯 | FCOM p.783 (6.10.5); LH24 p.146, p.148 |
| BUS TIE 1-4（[18]-[21]、灯[19]-[22]） | AUTO：自動 bus tie を有効にし DCIR を閉じる。OFF：BTB と DCIR を開き、故障ロジックをリセット | ISLN（amber）：BTB 開（autoland 中は消灯） | FCOM p.785 (6.10.7); LH24 p.104-105 |
| GEN CONT 1-4（[22]-[25]、灯[23]-[26]） | ON：品質が良ければ GCB を閉じてよい。OFF：界磁と GCB を開き、故障ロジックをリセット | OFF（amber）：GCB 開 | FCOM p.786 (6.10.8) |
| DRIVE DISC 1-4（カバー付き momentary、[26]-[29]、灯[27]-[30]） | idle 以上なら IDG をエンジンから切り離し、GCB を開く。再接続は地上整備のみ | DRIVE（amber）：IDG 油圧低・油温高（570 と SB 適用後の 109 は、周波数故障で GCB が開いたときも） | FCOM p.785-786 |

- overhead maintenance panel：GEN FIELD MAN RESET 1-4・APU 1/2（カバー付き spring toggle。GEN CONT／APU GEN が OFF のときだけ界磁を開閉）と FIELD OFF 灯（white）、SPLIT SYSTEM BREAKER スイッチ（地上のみ）と OPEN 灯（white）（FCOM p.788 (6.10.10); LH24 p.28）。3D コクピットには無い。
- ground service switch：door 2L の客室乗務員パネル。押すと点灯（LH24 p.40-41）。

### 3.2 ELEC synoptic と STAT のバッテリー表示

- 表示（FCOM p.789-792 (6.10.11-14)、LH24 p.30）：
  - SSB：閉／開
  - BUS TIE：電力の流れの帯（BTB 閉）／ISLN（amber、BTB 開）
  - UTILITY・GALLEY（109）：green（通電）／amber（非通電）
  - BUS 1-4：green／amber
  - GEN CONT：帯（GCB 閉）／OFF（amber、GCB 開）
  - DRIVE：空白／DRIVE TEMP/PRESS（amber）
- 表示は遮断器と接触器の状態から作る（実際の電流ではない）。DC の流れは描かない。元データが無効なら低輝度の白。autoland で BTB 1・2・3 が開いている間は「ELECTRICAL SYNOPTIC INHIBITED FOR AUTOLAND」（FCOM p.789）。
- STAT ページ：MAIN BATT と APU BATT の V-DC、A-DC、CHG/DIS（電流 0 なら空白）（FCOM p.793 (6.10.15)）。
- 現在の acf の部品（`747-400.acf` 130166-131150 行）：ext1/ext2/apu1/apu2 ← `electrical/ext_pwr1_on` など、topbus1-4 ← `bus1hot`…`bus4hot`、isln1-4 ← **スイッチ位置** `button_switch/position[18-21]`、topleftbus/topright ← `topleftbus`/`toprightbus`、SSB の指針 ← `ssb`（0-1）、バス ← `laminar/B747/rel_esys`・`rel_esys2-4`（1 で amber）、utility ← `utilityleft1/2`・`utilityright1/2`、GEN CONT ← X-Plane の `sim/cockpit2/annunciators/generator_off[0-3]`、DRIVE ← エンジン滑油圧の `laminar/B747/engines/EICAS2_oil_press_status[0-3]`。
- galley 専用の部品と autoland の文言は無い。STAT のバッテリー表示（129889-129966 行）に CHG/DIS は無い。

### 3.3 EICAS メッセージ

| メッセージ | レベル | 条件 | 抑止 | 根拠 | 現コード |
|---|---|---|---|---|---|
| >BAT DISCH APU | advisory | APU バッテリーが放電中（BCU 2 が ≥2 A を検知。EIU の遅延あり） | APU 始動中 | FCOM p.821 (6.30.1); LH24 p.200 | adv[19]：STBY PWR=BAT の 10 秒後に強制 |
| >BAT DISCH MAIN | advisory | main バッテリーが放電中（≥2 A。表示まで最大約 3 分） | — | FCOM p.821, p.181 (SP.6.3); LH24 p.200 | adv[20]：X-Plane の Wh 減少で判定 |
| >BATTERY OFF | advisory | BATTERY スイッチ OFF | — | FCOM p.821 | adv[21]（fltInst02） |
| >DRIVE DISC 1-4 | advisory | DRIVE DISC を押し、IDG が切り離された | — | FCOM p.821 | adv[83-86] |
| ELEC AC BUS 1-4 | caution（beeper） | AC bus 非通電。関連機器のメッセージも出る | — | FCOM p.821 | caution[15-18] |
| ELEC BUS ISLN 1-4 | advisory | BTB 開 | ELEC AC BUS 表示中、autoland 中 | FCOM p.821, p.802 | adv[92-95] 未使用 |
| ELEC DRIVE 1-4 | advisory | IDG 油圧低（<140 psi）か油温高（oil out >185 °C）（570 と SB 適用後は周波数故障での GCB 開も）。エンジン運転中かつ IDG 接続中に限る | DRIVE DISC を押した後 | FCOM p.821; LH24 p.72-73 | adv[96-99] 未使用 |
| ELEC GEN OFF 1-4 | advisory（109, 570）／caution＋beeper（405） | GCB 開 | ELEC AC BUS 表示中（同番号を抑止：推定） | FCOM p.822 (6.30.2) | caution[71-74]。adv[100-103] は未使用 |
| >ELEC SSB OPEN | advisory | close 指令中なのに SSB が開 | — | FCOM p.822 | adv[104] 未使用 |
| ELEC UTIL BUS L/R | advisory | 109：galley か utility bus の一つ以上が非通電（故障、スイッチ OFF、galley 非常スイッチ OFF）。405・570：utility bus が非通電 | load shed 中 | FCOM p.822 | adv[105-106] |
| >STBY BUS APU / >STBY BUS MAIN | advisory（109, 570） | APU standby bus / main standby bus 非通電 | — | FCOM p.823 (6.30.3) | adv[276-277] 未使用 |
| >STBY POWER OFF | advisory（405） | standby bus 非通電 | — | FCOM p.823 | adv[278] 未使用 |

- status（整備用、補助）：
  - DRIVE DISC n：周波数が 100 Hz 未満になると EIU に記憶。IDG を再接続しても CMC で消すまで残る（LH24 p.64）。
  - ELEC DRIVE n：oil out が 155-260 °C の状態が 10 分続く、または油圧 <140 psi。エンジン運転中かつ IDG 接続中（LH24 p.72-73）。
  - DRIVE n TEMP SNS（LH24 p.72）、ELEC IDG VALVE（LH24 p.82）。
  - ELEC TR UNIT（LH24 p.186）。
  - BAT CHARGER MAIN / APU：GSB 給電中、STBY PWR が BAT 以外。EIU の遅延あり（LH24 p.198）。
- 電源モジュールが出している他章のメッセージ：APU（adv 13）、APU DOOR（adv 14）、memo APU RUNNING（memo 1）、STBY IGNITION ON（memo 34）。

## 4. 内部ロジック

### 4.1 電源が「使える」条件

- IDG n（good power）：
  - 入力回転 ≥4525 rpm（underspeed でない）。この回転は PW 54.3 % N2、GE 55.3 % N2、RR 50.0 % N3（LH24 p.66 (24-10)）。underspeed 中は GCB をトリップし、UV/UF のトリップは抑止する。
  - 電圧 104.5-131 V・周波数 370-425 Hz（LH24 p.102）。
  - drive が接続されている。
  - GCR が閉。GCR は GEN CONT ON で閉じる。開く要因：故障（SPMG、OV/UV、差動、OF/UF、ダイオード、open phase、GCU 内部）、engine fire switch、DRIVE DISC、GEN CONT OFF。故障後のリセットは GEN CONT を OFF→ON。FIELD MAN RESET は GEN CONT OFF のときだけ効く（LH24 p.108）。
- APU GEN n（power ready）：APU 回転 >95 %、104-130 V、GCR トリップ無し（LH24 p.146）。GCR を開く要因：APU fire switch、OV、UV（underspeed 起因を除く）、軸受故障（5 分遅れ）、FIELD スイッチ（LH24 p.144）。地上のみ（FCOM p.895）。
- EXT n（available）：3 相平均で 104.5-125 V、370-430 Hz、相順 ABC、E/F ピン接続、インターロックに異常電圧なし（LH24 p.214, p.218）。

### 4.2 XPC / APB と電源切替（NBPT）

- XPC：available、EXT スイッチの close 指令、air mode でない、trip logic 無し、の全部で close 指令を出し、NBPT ロジックを経て閉じる。trip/close ロジックは前の指令が終わるか 4.5 秒経つまで新しい指令を受け付けない。AVAIL 灯＝available かつ XPC 開。ON 灯＝XPC 閉（LH24 p.218-219）。
- APB：XPC と同じ構造。AGCU が「並列できる」か「バスが死んでいる」と判断したときに閉じる。トリップ要因：
  - AGCU 側：underspeed、GCR トリップ
  - BCU 側：同期バス故障、SUSP、切替完了・last source on・軸受故障、power ready の喪失
  （LH24 p.148）
- 電源切替は原則 no-break：同期を取り、一瞬並列してから古い方を切る。断が出るのは、無電源機に EXT 2 本か APU 2 本を順に入れたとき。このときは 2 本目の XPC/APB を閉じる前に SSB を開く（LH24 p.126, p.224）。
- 3.5 秒以内に同期できなければ break power transfer（先に古い方を切る）（LH24 p.102, p.123）。
- SUSP（異種電源の並列が 120 ms 超）：IDG を含まなければ両方の電源を、含めば該当 BTB をトリップ（LH24 p.102, p.123）。
- 切替表（LH24 p.123 図 64。左側の電源が新たに入る場合。右側は左右対称。SSB 閉の同期バスにいた電源 → 落ちる遮断器）：

| 新たに入る電源 | EXT1 | APU1 | IDG1/2 | IDG1/2 と 3/4 | IDG3/4 | APU2 | EXT2 |
|---|---|---|---|---|---|---|---|
| EXT1（EXT2 は unavailable） | — | APB | GCB | 全 GCB | GCB | APB | — |
| EXT1（EXT2 も available） | — | APB | GCB | SSB→GCB1/2 | SSB | SSB | SSB（断） |
| APU1（APU2 は unavailable） | XPC | — | GCB | 全 GCB | GCB | — | XPC |
| APU1（APU2 も available） | XPC | — | GCB | SSB→GCB1/2 | SSB | SSB（断） | SSB |
| IDG1/2 | XPC | APB | — | — | — | APB | XPC |

- 乗員から見た動き（FCOM p.796-797 (6.20.2-3)）：
  - 無電源機で 1 つ目を選ぶ → SSB が閉じて全体に給電。同種の 2 つ目を反対側で選ぶ → SSB が開いて左右別々に給電。片方が切れたり故障したりすると SSB が閉じて残りが全体に給電。
  - IDG 運転中に EXT/APU が available なら、1 つ選ぶと同じ側の IDG が外れて SSB が開く。反対側にもう 1 つ選ぶと残りの IDG も外れ、SSB は開いたまま。
  - 左右に別の EXT/APU が入った状態でエンジンを始動すると、その IDG が自分の側を引き継ぐ。反対側の IDG も入ると SSB が閉じる。EXT/APU が 1 つで全体を賄っている状態でエンジンを始動すると、IDG が全体を引き継ぎ、SSB は閉じたまま。
  - 地上では EXT/APU を選べば IDG を母線から外せる。
  - EXT と APU を同じ側に同時に接続することはできない。

### 4.3 GCB（LH24 p.102、図 54 p.103）

- close：次のすべて → 300 ms のワンショットで閉じる。
  - GEN CONT ON
  - GCR 閉
  - underspeed でない（遅延あり）
  - load bus が死んでいるか、同期バスと auto parallel 成立
  - 下記の許可ラッチがセット
  - last source on によるトリップが無い
  - good power（閉じた後は自己保持）
- 許可ラッチ：
  - リセット（＝GCB トリップ）：BTB 閉の状態で XPC/APB が閉じた瞬間。EXT/APU を選ぶと IDG が外れるのはこれ。反対側の XPC/APB でも SSB 経由で効くと推定（切替表の「全 GCB」から）。
  - セット：(dead bus または auto parallel) かつ XPC/APB が閉じていない、GEN CONT の OFF→ON、underspeed、BTB 開、のどれか。
- trip：GEN CONT OFF、GCR トリップ、underspeed、上記ラッチのリセット、last source on（BTB を閉じたとき古い側を落とす）。
- GCB と BTB が閉になったら BCU に通知し、隣の同期バスにいる XPC/APB を落とさせる（IDG への切替の完了）。
- break power transfer：EXT/APU が同期バスに給電中で、GEN CONT ON・GCR 閉・underspeed でない・BTB 閉が 3.5 秒続いたら、XPC/APB を先に落として IDG を入れる。別の IDG が給電中で周波数が合わなければ GCB は閉じない。

### 4.4 BTB（LH24 p.104、図 55 p.105）

- close（ワンショット）：次のすべて。
  - BUS TIE が AUTO
  - 故障ラッチ①・②が立っていない
  - autoland 要求が無い
  - 隣の同期バスが死んでいる、auto parallel 成立、GCB 開、のどれか
- close の条件が崩れると BTB は開く。
- 故障ラッチ①：load bus 差動故障、同期バス故障、GCB 閉中の SUSP でセット。BUS TIE の OFF→AUTO でのみリセット。
- 故障ラッチ②（generator power faults）：過/不足励磁、difference current（平均から 35-40 A）、reverse power（8±1 kW）、open phase、OF/UF（<370 / >430 Hz）でセット。
  - auto reclose でリセット：GCB が開いた瞬間かつ GEN CONT ON かつ BTB 開。発電機側の故障なら GCB も落ちて BTB が閉じ直し、AC bus は同期バスから給電される（FCOM p.798 と同じ動き）。
  - BUS TIE を OFF→AUTO にしてもリセット。
- ISLN 灯 = BTB 開 かつ autoland でない。
- 自動の BTB 分離では DCIR は開かない。DCIR が開くのは BUS TIE OFF のとき（FCOM p.819 (6.20.25)）と autoland のとき（LH24 p.166）。

### 4.5 SSB（LH24 p.120、図 63 p.121。BCU 2 が駆動）

- 閉じる条件（どれか）：
  - 同期バスに最初の電源が乗った
  - BCU 1 からの close 指令
  - 両側とも IDG で、auto parallel が完了
  - 両側に電源があった後に片側が死んだ（ただし同期バス故障、BPT、手動 trip による場合を除く）
  - 手動 close（air mode でなく、両側に別々の EXT/APU/異種電源が無いとき）
- 開く条件（どれか）：
  - 手動 trip（air mode でないとき）
  - NBPT ロジック
  - 両側に別々の EXT/APU/異種電源がある
  - 反対側の BCU に電源が無い
  - 同期バス故障のラッチ。リセットは、IDG 両側かつ auto parallel、SSB スイッチの操作（地上）、最初の電源投入、のどれか
- IDG が両側にあるとき、手動で開いても auto parallel が終われば自動で閉じ直す（LH24 p.120）。
- >ELEC SSB OPEN（advisory）は close を指令しているのに開いているとき（FCOM p.822）。

### 4.6 transfer bus（IBVSU）

- 主電源が 97 V 未満の状態が 180 ms 続いたら AC 1 に切り替える。主電源が 106 V 以上の状態が 1.2 秒続いたら戻す。
- 制御電源は DC 1。DC 1 が 20 ms 以上切れると主電源側に留まる（主電源側に戻る）（LH24 p.228 (24-50)）。
- CAPT IBVSU の接点は、AC 3 が 97 V 未満で battery transfer relay の制御回路も切る（4.8）（LH24 p.155 図 81）。

### 4.7 GHB / GSB

- GHB：
  - 地上で air mode でなく、GHR が故障していなければ自動で給電。EXT1 が available ならそれ、無ければ APU GEN1（FCOM p.799、LH24 p.214）。
  - GHR 故障のリセットは EXT1 のコードを抜くこと（LH24 p.214）。
  - DC GHB は GH TRU A・B から各 1 本（LH24 p.212）。
- GSB：
  - AC 1 に電源があれば AC 1 から（GSTR 消勢）。
  - AC 1 が無いとき、地上（air mode でない）で ground service switch を押すと GSTR が付勢され、EXT1（GSSR）か APU GEN1 から給電。EXT 優先。
  - リレー故障のリセットは switch の再操作。
  - 主電源を落とした後は、もう一度押す必要がある（LH24 p.38, p.130, p.216; FCOM p.799）。
  - ground service utility bus も同じ。AC 1 から給電するときは L UTILITY ON（U-ELCU 1）が必要（LH24 p.38, p.216）。

### 4.8 DC と battery bus

- TRU n → DC n → DCIR n → DC tie bus（LH24 p.166）。
  - DCIR は BUS TIE AUTO で閉じる。autoland で IDG が 3 台以上あるときは GCU が開く。
  - DC の電圧表示はバス電圧で、TRU 単体の電圧ではない（LH24 p.180）。
- TRU 故障：DCIR が開なら「バス電圧 <18 V かつ TRU 電流 <2.5 A」、閉なら「電流 <2.5 A」。どちらも AC bus に電源があることが前提。故障なら ELEC TR UNIT（status）（LH24 p.186）。
- single TRU operation：動いている TRU が 1 台だけになったら R7225 を付勢する（LH24 p.184）。
- battery transfer relay R7224（付勢なら battery bus は DC 3 から）。付勢の条件はすべて：
  - DC 3 に電源（R7228 DC voltage sense）
  - STBY PWR が BAT でない
  - AC 3 が 97 V 以上（CAPT IBVSU の接点）
  - R7225 が消勢
  （LH24 p.155, p.182）
- R7224 が消勢で BATTERY ON なら main battery relay R7223 が付勢し、main/APU battery bus は各 hot battery bus から給電される。BATTERY OFF なら battery bus は非通電（LH24 p.182; FCOM p.819-820）。
- APU 始動中は R7687 で main hot battery bus を APU battery bus につなぐ。無電源機で R7223 が付勢しているときの話で、starter による電圧低下から APU の制御回路を守るため（LH24 p.162, p.182）。

### 4.9 standby 電源（109, 570）

- main standby bus：
  - STBY PWR OFF：非通電（AC 電源が全部あっても）。
  - AUTO：AC 3 に電源があれば standby power transfer relay R7227 が付勢して AC 3 から。インバーターは remote control 線が接地されて停止。AC 3 が無くなれば R7227 が消勢し、インバーターが起動して給電。
  - BAT：R7227 消勢、インバーター起動。
  - インバーターの入力：R7224 付勢なら DC 3、消勢なら main hot battery bus（R7223）。
  - AC 3 を失うと 4.8 の条件で入力は main hot battery bus に移る。その hot bus は、AC 1→GSB→充電器が生きていれば充電器から、生きていなければバッテリーから給電（FCOM p.804）。R7223 は BATTERY ON が条件なので、BATTERY OFF なら inverter は動かない（FCOM p.804 も「Battery switch ON」を条件にしている）。
  （LH24 p.150-155; FCOM p.780-781, p.804）
- APU standby bus：
  - CAPT XFR に電源があれば relay が付勢して CAPT XFR から。
  - CAPT XFR が無くなるか BAT なら、APU static inverter から。入力は APU hot battery bus（APU inverter transfer relay、BATTERY ON）。
  - OFF：非通電。
  - APU 始動中は APU start relay（65 秒）がインバーターを止める（LH24 p.158-159; FCOM p.804）。
- どちらのバッテリーも standby bus を最低 30 分維持する（FCOM p.804, p.806）。
- BAT 位置では両充電器が止まり、BAT DISCH MAIN と BAT DISCH APU が出る（SP.6 の試験手順：最大 3 分で表示。AUTO に戻すと消える）（FCOM p.806, p.181）。

### 4.10 充電器とバッテリーの表示

- 充電：38 A の定電流 → 約 31 V の inflection に達したら、その時間の 12 % だけ追加充電 → 27.75 V の定電圧（main 38 A、APU 35 A の電流制限）。バッテリー電圧が 23 V 未満になると定電流に戻る（LH24 p.192-196）。
- TR mode（27.75 V、≤64 A）になる条件（LH24 p.194, p.196）：
  - main：main battery relay 付勢時、または冷却ファン停止時
  - APU：battery transfer relay 消勢時、または lav/galley vent 停止時
- 充電器が止まる条件（LH24 p.192, p.194, p.196）：
  - バッテリー connector／インターロック外れ、過電流
  - バッテリー過温（68 °C の thermoswitch）
  - 入力喪失、入力 <94 V か >134 V
  - STBY PWR=BAT（R7208/R7218）
  - APU 始動中（APU 側のみ）
  - 電源投入時にバッテリー電圧が 4 V 以下だと起動しない
- 電圧の表示は hot battery bus の電圧（充電器が動いていれば充電器の電圧）。電流の表示は DCCS から、CHG/DIS 付き。APU 側は始動中は電流表示を止め、電圧は starter 側を示す（LH24 p.202, p.204）。

### 4.11 IDG drive と disconnect

- DRIVE 灯＝油圧 <140 psi、oil out >185 °C、OF/UF 故障のどれか。エンジンが止まっていれば油圧低で点灯する（NP の preflight で「DRIVE lights illuminated」を確認する：FCOM p.104 (NP.21.10)）。ELEC DRIVE はこれにエンジン運転中かつ IDG 接続中を加えたもの（LH24 p.72-73、図 39）。
- DRIVE DISC：
  - 押すと disconnect solenoid が働き、同じ信号で GCR と GCB をトリップする。>DRIVE DISC を表示。
  - 完全に切れるのは idle 以上のとき。保持は 3 秒以内、次の操作まで 60 秒あける（整備上の注意）。
  - 再接続は地上でエンジン停止後に reset ring で（LH24 p.60, p.92; FCOM p.785）。
- thermal disconnect（109, 570）：油温 213 °C（415 °F）で自動的に切れる → GCB 開で ELEC GEN OFF。その後 DRIVE DISC を押すと ELEC DRIVE が DRIVE DISC に置き換わる（FCOM p.797; LH24 p.62）。

### 4.12 utility / galley の負荷管理（109）

- ELCU は G1-4 と U1-4。L UTILITY が G1・G2・U1・U2、R が G3・G4・U3・U4（FCOM p.800; LH24 p.230, p.238）。
- ELCU の保護：差動 ≥30 A、過電流（10-60 kVA に設定）で開く。リセットは UTILITY の OFF→ON（LH24 p.234）。
- 負荷制限（load shed）：
  - 需要が容量を超えたら、1 秒ごとに 1 個ずつ開く。順番は G1→G4→G2→G3、続いて U1→U4→U2→U3（LH24 p.236）。
  - 容量（1 台あたり）：
    - 4 台・3 台：305 A を 5 秒、243 A を 4 分
    - 2 台：203 A を 5 秒
    - 0-1 台で air mode：外部電源が無ければ即座に全部を落とす
    - 0-1 台で ground mode：305 A / 243 A
    - EXT/APU：1 系統あたり 290 A（+30 A）。遅延は超過量に反比例
    （LH24 p.240, p.242）
  - 復帰は逆順。0-1 台：何も戻さない。2 台：utility 全部と G ELCU 3。3-4 台：全部（LH24 p.238）。
  - load shed 中は UTIL OFF 灯と ELEC UTIL BUS を出さない。代わりに FUEL PUMP 3 FWD、FUEL OVRD 2 FWD、FUEL OVRD 3 FWD、FUEL OVD CTR L、FUEL PUMP 2 FWD がこの順に出ることがある（FCOM p.795 (6.20.1)）。
- 405・570 は utility だけ（galley 無し）（FCOM p.795, p.801）。

### 4.13 autoland 時のバス分離、air mode

- autoland（FCOM p.802; LH24 p.244-249）：
  - 3 チャンネルで approach すると FCC が BCU 1 に要求し、BCU 1 が構成を決める。
    - 発電機 4 台と TRU 4 台がそろっていれば config A：BTB1-3 と DCIR1-3 を開き、AC 4 が同期バスを維持する。
    - 1 チャンネル（発電機または TRU）が欠けていれば B/C/D/E。TRU の故障は発電機の故障と同じ扱いだが GCB はトリップしない。
    - 2 チャンネル以上欠けていれば要求を無視する。
  - 実行中に 2 チャンネル以上欠けた場合：200 ft より上なら元の構成に戻す。200 ft 以下なら DCIR だけ閉じ、BTB は要求が消えるまでそのまま。
  - 解除：AP がすべて切れた、TO/GA かつ RA 100 ft 超、APP の解除、構成を維持できない。
  - 実行中は ISLN 1-3 を消灯、ELEC BUS ISLN を出さない、synoptic を抑止。
- air mode（BCU）：空中、または IDG 4 台のうち 3 台以上が 6100 rpm 以上（PW 73.3 % N2、GE 74.6 % N2、RR 67.4 % N3）（LH24 p.66）。
  - air mode 中は、XPC/APB/SSB の手動操作と GHB・GSB の切替を受け付けない。APU GEN の AVAIL/ON 灯は空中では消える。
  - 負荷制限の 0-1 台の規則が変わる（LH24 p.28, p.146-148, p.214, p.218, p.240）。

## 5. 他系統とのつながり

### 5.1 バスごとの負荷（資料の記載。他系統の作り直しで使う）

| バス | 負荷 | 根拠 |
|---|---|---|
| AC 1-4 | TRU、航法無線と FCC、操縦室照明、pitot・window heat。AC1 → GSB と両 XFR の backup。AC2 → F/O XFR。AC3 → CAPT XFR と main standby。各 AC → utility（109 は galley も） | FCOM p.798-799 (6.20.4-5) |
| CAPT XFR | center EIU、left HF、center ADC（109, 405）、APU standby bus（109, 570） | FCOM p.800 (6.20.6) |
| F/O XFR | autothrottle servo、lower EICAS display、right ADC、right EFIS control、right EIU、right FMC、right CDU、right HF、right ND、right PFD | FCOM p.800 |
| main standby | left EIU、left CDU、left ILS、left VOR、各種 flight control 部品、全エンジンの standby ignition、primary EICAS display、standby instrument lights、left ADC、left transponder、left EFIS control panel | FCOM p.804 (6.20.10) |
| APU standby | left FMC、left ND、left PFD | FCOM p.804 |
| standby だけが生きている場合 | 左翼の後縁フラップ位置センサーが非通電（EICAS に amber X） | FCOM p.955 |
| GSB | main/APU battery charger、APU 始動用の燃料ポンプ、upper deck emergency doors（109, 405）、操縦室の flood・navigation・service lights、service outlets、horizontal stabilizer fuel pump（defuel 用、109） | FCOM p.799 (6.20.5); LH24 p.192 |
| GHB | 下部貨物室の荷役装置と照明、給油系統、auxiliary hydraulic pump 4、flight deck access lights（スイッチを押したとき） | FCOM p.799, p.444 |
| utility 1-4 | forward main fuel pumps 2・3、forward override/jettison pumps 2・3、center override/jettison pump、recirculating fans（109）／galley 機器（405, 570）。どのポンプがどのバスかは資料に記載なし | FCOM p.801 (6.20.7) |
| galley 1-4（109） | 客室の galley | FCOM p.801 |
| DC 1-4 | 与圧・燃料投棄・pack 温度の各コントローラー、主翼防氷の制御、EDP とデマンドポンプの制御、燃料移送と投棄弁の制御、nacelle 防氷の制御。DC1 は IBVSU の制御電源。DC4 は非常灯バッテリーを充電 | FCOM p.819, p.504 (1.40.6); LH24 p.228 |
| main battery bus | APU controller（alternate）、全エンジンの fuel valves、全 crossfeed valves、dome・storm・一部の表示灯、IDG disconnect（全）、手動与圧制御、後縁フラップ制御、captain interphone、left RTP、left VHF。ISFD（570）、standby attitude indicator（109, 405、「main battery」）、BCU の電源の一つ | FCOM p.819-820, p.1074, p.1075 (10.20.7); LH24 p.218 |
| APU battery bus | APU DC fuel pump、engine start air control、cargo/F-O/service interphone、PA、APU とエンジンの fire/overheat detection loops A・B、APU fire warning horn、時計の表示 | FCOM p.820 (6.20.26), p.1075 |
| main hot battery bus | APU fuel shutoff valve、全 spar valves、APU と下部貨物室の消火器、全エンジンの消火器と fire switch unlock、時計の内部機能。main static inverter の入力（4.9）、GCU と BCU 2 の電源（BATTERY ON 時） | FCOM p.820, p.1075; LH24 p.108, p.150, p.218 |
| APU hot battery bus | IRU（L/C/R）の DC 電源（IRS ON BAT）、左右 outflow valves、APU inlet door、APU controller（primary）、APU static inverter、APU starter（109 はバッテリー始動）、BCU 1 の電源（BATTERY ON 時） | FCOM p.820, p.1217 (11.10.11), p.896 (7.30.2); LH24 p.158, p.218 |
| main deck cargo handling（405, 570） | 主甲板の荷役装置と照明、nose/side cargo door（570）、side cargo door（405） | FCOM p.802 |

### 5.2 入出力

- 入力：
  - エンジン：N2（RR は N3）→ IDG の underspeed と air mode。エンジン運転状態 → ELEC DRIVE。engine fire switch → GCR トリップ（LH24 p.66, p.108）。
  - APU：N1 >95 %。APU fire switch → AGCU の GCR トリップ。APU 始動 → APU start relay（65 秒）、R7687、APU 充電器の停止、BAT DISCH APU の抑止（LH24 p.144, p.159, p.182, p.196, p.200）。
  - 空地判定（air mode）。
  - FCC の autoland 要求。BCU 2 から FCC へ分離完了の確認（LH24 p.244）。
- 出力：
  - 各バスの通電状態（他系統すべて）。
  - EICAS メッセージ・synoptic・status。
  - 負荷制限に伴う燃料ポンプのメッセージ（FCOM p.795）。
  - APU 始動電源：109 は main と APU の両バッテリーを使う。starter は APU battery、始動中のそれ以外は main battery（FCOM p.896）。

### 5.3 現コードで他モジュールが「電源あり」を判定している方法

| 使う側 | 判定 | 場所 |
|---|---|---|
| 燃料ポンプ・弁 | `bus_volts[0] > 0` | B747.25.xt.fuel.lua:704, :1221 |
| 抽気弁、装備冷却 | `bus_volts[0] > 0` | B747.55.xt.air.lua:468, :794 |
| IRS 更新・NAV RAD | `bus_volts[0] > 22` | B747.68.xt.fms.lua:1236 |
| EICAS メッセージの計算 | `bus_volts[0] < 5` か `rel_esys2 == 6` なら停止し、4 秒後に再開 | B747.87.xt.warning.lua:1140-1155 |
| 表示器（PFD/ND/EICAS） | `display_has_power[0-5]` を capt/fo の値から（APU 始動中は機長側を消す） | B747.60.xt.fltInst02.lua:3236-3272 |
| CDU | `display_has_power[6-8]` | B747.03.xt.electrical.lua:624-626 |
| 時計 | `bus_volts[0]` の 0-5 V を 0-1 に | B747.60.xt.fltInst03.lua:269, :320、fltInst04.lua:269, :319 |
| 表示灯の輝度 | `max(bus_volts[0], bus_volts[2]) / 28` | B747.90.xt.lighting.lua:1691-1694 |
| ELEC パネルの灯 | lighting が独自に計算（3.1 の添字） | B747.90.xt.lighting.lua:1076-1119, :1737-1771 |
| 客室灯 | gen/gpu/apu と `cross_tie` | B747.90.xt.lighting.lua:920-934 |
| yaw damper | `battery_array_on[0]` | B747.45.xt.fltCtrls.lua:722, :734 |
| quick start（AI） | `cross_tie`、`generator_on`、`APU_generator_on`、`battery_on` | B747.95.xt.AI.lua:628-834 |
| 3D の LIT テクスチャ | `sim/cockpit/electrical/avionics_on`（= BATTERY スイッチ） | Avionics.lua:83-90、obj 15 か所 |
| FMOD | `bus_volts[0]`（`==28`、`!=28`、`>24`、`<24`。155 か所）、`battery_on[0]`（85 か所）、`ext/apu_pwr*_on`、STBY PWR の位置 | fmod/747-400.snd |

- 油圧・エンジン・防氷・通信・AFDS の各モジュールは電源を見ていない。

## 6. 実装上の注意

- **電源の判定は Lua の電源モデルが持つ**。X-Plane の電気系統は「X-Plane 内部の機器と音のための代理」として残す。
  - X-Plane の autopilot サーボ・航法無線・FMS や、BUS_SRC 2/3/4 のパネル計器は X-Plane のバス電力が要る。実機の AC バス単位で X-Plane のバスを落とすと AFDS などが止まる。
  - `cross_tie=1` は維持する。X-Plane の battery_on は BATTERY スイッチに合わせる（FMOD の `battery_on[0]` の意味を守る）。
  - X-Plane の GPU on ＝ XPC のどれかが閉、X-Plane の APU 発電機 on ＝ APB のどれかが閉、X-Plane の `generator_on[i]` ＝ GCB i が閉、にする。こうすると `generator_off[i]`（synoptic の GEN CONT 枠と GEN OFF 灯）が GCB と一致する。X-Plane の発電機がどの回転から発電するかは要確認。
  - AC 電源があるときは `bus_volts[0]` がちょうど 28 V になるようにする。FMOD が `==28` で判定しているため。
- **他系統向けの公開 dataref を新設する**。各バスの通電を 0/1 で出し、名前と添字は文書化する。
  - 対象：AC1-4、同期バス左右、SSB、CAPT/F/O XFR、main/APU standby、GSB、GS utility、GHB、DC GHB、utility1-4、galley1-4、DC1-4、DC tie、main/APU battery bus、main/APU hot battery bus。表示器（DU）単位の通電もここで出す。
  - XTLua は plugin をまたぐと dataref でしか受け渡せない。init の `B747.03.electrical.lua` で作る。
  - 使う側（keysystems の fuel、air、fms、fltInst、lighting など）は 1 フレーム遅れて読む。読み始めの 0 も考慮する（OLD_FORK_NOTES §14）。
- **残す名前**（INTERFACES.tsv）：
  - コマンド：`button_switch/elec_*`（battery、ext_pwr_1/2、apu_gen_1/2、bus_tie_1-4、gen_ctrl_1-4、drive_disc_1-4、util_L/R）、`electrical/standby_power/*`、`electrical/apu/*`、`electrical/stby_ignit/*`、`electrical/auto_ignit/*`、`electrical/connect_power`（AutoATC）。
  - dataref：`electrical/ext_pwr1_on/2_on`、`apu_pwr1_on/2_on`、`apu_volts`、`ssb`、`apu_inlet_door`、`button_switch/position`、`annunciator/brightness_ratio`、`gear/chocked`。
- **INTERFACES.tsv に載っていないが、パネルの SHOW_* 条件で使われていて名前と意味を守る必要があるもの**：
  - `electrical/bus1hot-bus4hot`：BTB の流れの帯
  - `topleftbus`・`toprightbus`：同期バスの左右
  - `utilityleft1/2`・`utilityright1/2`
  - `display_has_power[0-8]`：0 機長 PFD、1 F/O PFD、2 F/O ND、3 機長 ND、4 upper EICAS、5 lower EICAS、6 FMS L、7 FMS R、8 FMS C（acf 84615-140101 行）
  - `laminar/B747/rel_esys`・`rel_esys2-4`：1 で bus amber
  - `engines/EICAS2_oil_press_status`、`dsp/synoptic_display`
  - パネルの SHOW_* で使われ INTERFACES.tsv に無い laminar 名は、全体で 175 個あった。INTERFACES.tsv は作り直しが要る。
- Lua の間だけで使う名前：`*_avail`、`elec_ext_pwr_1/switch_mode` などの switch_mode 4 個、`capt_display_power`・`fo_display_power`（0＝通電、6＝非通電）、`generator/drive_disc_status`、`elec/init_CD`。使う側を全部直すなら変えてよい。
- **純正 acf を変えられないことによる表示の制約**（直すにはカスタム acf の変更と承認が要る）：
  - synoptic の ISLN 枠がスイッチ位置に直結していて、自動の BTB トリップを出せない。
  - DRIVE 枠がエンジン滑油圧に直結している。
  - galley 単独の色と autoland の抑止文言を出せない。
  - STAT の CHG/DIS が無い。APU BATT の A-DC が APU 発電機の電流になっている。
- **簡略化してよいもの**：
  - 電圧・周波数・相、同期の過程（瞬時に同期したとみなす）、equalizing loop、BCU/GCU の冗長、保守ページ、BITE。
  - 保護トリップは故障注入のときだけでよい。
  - 負荷制限は電流を計算せず、発電機の台数と air mode の規則（4.12）で決める。
  - 断のある切替の断の長さは資料に記載なし（数百 ms で十分と推定）。
- **簡略化してはいけないもの**：
  - 各バスの通電（standby 2 本と hot battery bus を含む）
  - 電源の優先と切替表（4.2）
  - GCB・BTB・SSB の、乗員から見える動き
  - STBY PWR の OFF/AUTO/BAT、transfer bus の backup
  - UTILITY と load shed の見え方
  - EICAS のレベルと抑止
  - air mode で APU/EXT が使えないこと
  - IDG の型式別の閾値
- **型式**：IDG の閾値は PW・GE・RR とも LH24 p.66 にある（RR は資料が無いが、この値は使える）。109（PW 旅客）を基準にする。GE を選んだときに 570 の改良 GCU（DRIVE の周波数条件）を当てるかは要判断。
- **現在の電源モジュールに同居している他章の処理**：APU の選択・始動・停止・inlet door（ATA 49）、点火セレクター（ATA 74）、ストロボの点滅（init スクリプトの after_physics：init `B747.03.electrical.lua:130-161`）。作り直しで移すか残すかを、各章の担当と合わせる。

## 7. 現状実装との比較（GAP 候補）

### 7.1 現在の動き（要約）

- `B747_bus_tie()` は毎フレーム `sim/cockpit2/electrical/cross_tie=1` を書く（B747.03.xt.electrical.lua:500）。
  - ヘッダの「4 つの bus tie が全部閉じたときだけ X-Plane の 4 バスがつながる」は現状と違う。そのコードはコメントアウトされている（:501-515）。
  - X-Plane の 5 本のバスは、バッテリー（スイッチ連動）、GPU、APU 発電機、発電機 4 台のどれかがあれば全部同じ電圧になる。
- バスごとの「通電」は表示用のフラグだけ。
  - `bus1hot`…：bus tie スイッチ AUTO かつ（自 IDG か同期バス）
  - `topleftbus`…、`ssb`、`rel_esys`…、`utility*`
  - 一部は前フレームの値を参照して循環している（:540-592）。
- 外部電源：輪止めがあり、XP12 では X-Plane の GPU 電圧が 24 V 以上なら available（:456-476）。EXT 1/2 は常に同時。
- APU 発電機は X-Plane の APU 発電機 1 台で、GEN1/2 はスイッチのフラグにすぎない（:703-725）。
- パネルの灯は lighting モジュールが計算する（B747.90.xt.lighting.lua:1076-1119）。

### 7.2 GAP

| ID | 種別 | 重要度 | 規模 | 内容 | 根拠 | 該当コード |
|---|---|---|---|---|---|---|
| ELEC-01 | 欠落 | 高 | L | 実機のバス構成を表す電源モデルが無い：AC1-4、同期バス左右、SSB、XFR、standby 2 本、GS/GH、DC1-4、DC tie、バッテリー系 4 本、utility/galley。X-Plane は cross_tie 固定で全バスが一体。バス単位の状態は表示フラグだけで、GCB/BTB/SSB/APB/XPC が遮断器として存在しない | LH24 p.7, p.9; FCOM p.796-820 | B747.03.xt.electrical.lua:500, :540-592 |
| ELEC-02 | 欠落 | 高 | L | 他系統がバス単位の通電を問い合わせる手段が無い。各モジュールは `bus_volts[0]`（バッテリーだけでも真）で判定する。燃料ポンプ（AC/utility）、抽気弁（DC）、IRS、EICAS などが実機と違う電源条件で動く。公開 dataref を作り、各モジュールを移す必要がある | FCOM p.798-801, p.819-820 | fuel.lua:704, :1221; air.lua:468, :794; fms.lua:1236; warning.lua:1140; fltInst03.lua:269; lighting.lua:1691; fltCtrls.lua:722 |
| ELEC-03 | 挙動の誤り | 高 | M | 電源切替が違う。(a) IDG が入ると同じ側の EXT/APU しか落とさない。実機はどちら側でも落とす。(b) 同じ側の IDG が発電中は、EXT/APU を押しても毎フレーム switch_mode が 0 に戻り、選べない。実機は GCB を落として引き継ぐ（同種のもう一方が available かで、全 GCB か SSB＋GCB1/2 かが変わる）。(c) EXT1 と IDG3/4 が並列のまま続く（SUSP 無し） | LH24 p.102, p.123; FCOM p.796-797 | electrical.lua:573-583, :627-634; manipulators.lua:624-680 |
| ELEC-04 | 挙動の誤り | 中 | M | GCB/BTB の自動制御が無い。GCB は GEN CONT と X-Plane の発電状態だけ、BTB はスイッチだけで決まる。無いもの：故障トリップ、auto reclose、3.5 秒の break power transfer、last source on、「BTB の自動分離では DCIR を開かない」。IDG が入る回転（PW 54.3 % N2 ほか）は X-Plane 任せ | LH24 p.66, p.102-108; FCOM p.798, p.819 | electrical.lua:589-592, :760-833 |
| ELEC-05 | 挙動の誤り | 中 | S | SSB：異種電源（EXT1＋APU2 など）では常に分割する。実機は、同種のもう一方が available かで、分割か片方トリップかが決まる。>ELEC SSB OPEN（adv 104）、手動 SSB スイッチ、OPEN 灯が無い | LH24 p.120-123; FCOM p.788, p.822 | electrical.lua:566-583; warning.lua:290 |
| ELEC-06 | 欠落 | 高 | M | standby 電源が無い（main/APU standby bus、両インバーター、R7224/R7223、CAPT IBVSU）。表示の通電式で近似している。STBY PWR OFF では AC 電源があっても両 standby bus が落ちるはずだが、そうならない。F/O XFR の AC1 backup が STBY PWR の位置に依存している（誤り）。>STBY BUS MAIN/APU（adv 276-277）が無い | LH24 p.150-159, p.182; FCOM p.780-781, p.803-806, p.823 | electrical.lua:546-548; fltInst02.lua:3245-3272; warning.lua:462-463 |
| ELEC-07 | 挙動の誤り | 中 | S | 表示器と CDU の電源の割当が違う。現状：CDU L/R は F/O 側、CDU C は機長側、upper EICAS は機長側（APU standby 相当）。実機：CDU L と primary EICAS は main standby、CDU R と lower EICAS は F/O XFR、機長 PFD/ND と FMC L は APU standby。バッテリーだけの状態で CDU L が消え、CDU C が点く | FCOM p.800, p.804 | electrical.lua:624-626; fltInst02.lua:3267-3272 |
| ELEC-08 | 挙動の誤り | 高 | S | ELEC GEN OFF を caution（71-74）で出し、GEN CONT を操作したときしか更新しない。エンジン停止、drive disc、故障で GCB が開いても出ない。109 では advisory で、条件は「GCB 開」。ELEC AC BUS 表示中は抑止する | FCOM p.822 | electrical.lua:766-831; warning.lua:179-182, :286-289 |
| ELEC-09 | 挙動の誤り | 中 | S | ELEC AC BUS n の条件に BUS TIE AUTO が入っている。BUS TIE OFF にすると、自分の IDG が給電していても caution が出る | FCOM p.798, p.821 | electrical.lua:589-613 |
| ELEC-10 | 欠落 | 中 | S | ELEC BUS ISLN 1-4（adv 92-95）が無い。ISLN 灯はスイッチ OFF（と、常に 1 の cross_tie が 0 のとき）だけで、BTB の自動トリップと autoland 中の消灯が無い | FCOM p.785, p.802, p.821 | lighting.lua:1104-1107; warning.lua:278-281 |
| ELEC-11 | 挙動の誤り | 中 | S | DRIVE 灯が「X-Plane の発電機故障か generator_off」で点く。GEN CONT OFF でも点き、IDG の油圧・油温とは無関係。ELEC DRIVE 1-4（adv 96-99）が無い。synoptic の DRIVE 枠はエンジン滑油圧で代用（acf のため直せない） | LH24 p.72-73; FCOM p.786, p.792, p.821 | lighting.lua:1116-1119; 747-400.acf:131062-131132 |
| ELEC-12 | 挙動の誤り | 低 | S | DRIVE DISC が回転や電源に関係なく即座に切れる。実機は idle 以上で切れ（停止中は不完全）、電源は main battery bus（FCOM）／hot battery bus（LH24 の図） | FCOM p.785, p.819; LH24 p.60-61 | manipulators.lua:714-748; electrical.lua:763-765 |
| ELEC-13 | 欠落 | 中 | M | GHB/GSB（GHR・GSSR・GSTR、ground service switch、DC GHB）が無い。aux hydraulic pump 4、給油、充電器の電源を判定できない | LH24 p.36-40, p.214-217; FCOM p.799 | なし |
| ELEC-14 | 欠落 | 中 | M | ELCU と load shed が無い。utility の通電は「スイッチ AND（bus hot か gen on）」だけ。ELEC UTIL BUS と UTIL OFF 灯はスイッチ OFF だけで、load shed 中の抑止と galley（109）が無い | LH24 p.230-242; FCOM p.781-782, p.795, p.800-801, p.822 | electrical.lua:584-587, :904-918; lighting.lua:1077-1078 |
| ELEC-15 | 欠落 | 中 | M | DC 系（TRU、DCIR、DC tie、ELEC TR UNIT、single TRU）とバッテリー母線（main/APU battery bus、hot battery bus）が無い。BATTERY OFF で X-Plane のバッテリーごと切れて `bus_volts[0]` が 0 になる。実機では BATTERY OFF でも hot battery bus（消火器、IRU の DC backup、時計、APU inlet door など）は生きている。逆に消火器などは今は電源を見ていない | LH24 p.20, p.162-186; FCOM p.819-820 | electrical.lua:414-432 |
| ELEC-16 | 挙動の誤り | 中 | S | バッテリーの表示と BAT DISCH。APU バッテリーをモデル化しておらず、`apu_volts` は 28 固定、A-DC は APU 発電機の電流。>BAT DISCH APU は STBY PWR=BAT の 10 秒後に MAIN と一緒に強制、MAIN は X-Plane の Wh 減少で判定。実機：放電 ≥2 A と EIU の遅延（最大約 3 分）、BAT で充電器が止まる | LH24 p.192-204; FCOM p.793, p.181 | electrical.lua:429-431, :837-851; fltInst02.lua:3197-3207; 747-400.acf:129930-129957 |
| ELEC-17 | 挙動の誤り | 低 | S | 外部電源の available。XP12 では X-Plane の GPU 電圧次第で、`connect_power`（FMC の GRND POWER、AutoATC）だけでは翌フレームに 0 に戻るように読める（要確認）。EXT1/2 は常に同時。輪止めが条件。C&D で EXT2/APU2 の switch_mode を戻していない | LH24 p.214, p.218 | electrical.lua:338-346, :456-476; manipulators.lua:2056-2057 |
| ELEC-18 | 欠落 | 低 | M | autoland のバス分離（config A-E、DCIR、ISLN 消灯、synoptic 抑止）が無い。AFDS の LAND 3 との連携が要る | LH24 p.244-249; FCOM p.789, p.802 | なし |
| ELEC-19 | 欠落 | 低 | S | air mode（IDG 3/4 台 ≥6100 rpm、または空中）が無い。XPC/APB/SSB 操作の抑止、GHB の遮断、APU GEN AVAIL の抑止は一部だけ | LH24 p.66, p.146-148, p.214 | electrical.lua:703-725 |
| ELEC-20 | バグ | 低 | S | 未定義の global（failCapt、failFO）を参照し、毎フレーム X-Plane の故障 dataref `rel_esys2`・`rel_esys3` に 0 を書く。ユーザーがかけたバス故障を消してしまう | — | electrical.lua:549-555 |
| ELEC-21 | バグ | 低 | S | Avionics.lua:70 の `puOn` は `gpuOn` の誤記（XP12 では gpuOn が常に false）。出力の Ext_Power_Av・Eng_Gen_on はどこからも使われていない。X-Plane の avionics_on（LIT テクスチャ）は BATTERY スイッチ連動で、バスの通電とは無関係 | — | Avionics.lua:66-90 |
| ELEC-22 | 欠落 | 低 | S | GEN FIELD MAN RESET、SSB スイッチ、FIELD OFF/OPEN 灯（overhead maintenance panel）が無い。3D にも操作部が無い | FCOM p.788; LH24 p.28 | なし |
| ELEC-23 | 欠落 | 低 | S | EICAS status（DRIVE DISC n、ELEC DRIVE n、BAT CHARGER MAIN/APU、ELEC TR UNIT、ELEC IDG VALVE）が無い | LH24 p.64, p.72, p.82, p.186, p.198 | なし |
| ELEC-24 | バグ | 低 | S | `laminar/B747/electrical/oil` をどこでも作っていない（find しているだけで、使っていない） | — | electrical.lua:104 |

- 集計：高 5（01, 02, 03, 06, 08）、中 10、低 9。
- ACF_DIFF の項目：§2 のとおり、電気系統の acf 項目は純正とカスタムで全部同じ。差分による GAP は無い。コードが依存している acf の値は次のとおり。
  - バッテリーと発電機 4 台が bus 5 にある（`_bus_bat_is_on/0 4`、`_bus_gen_is_on/0-3 4`）。
  - `_selective_ties 31`（5 本とも cross tie に入る）。コードは cross_tie=1 に依存している。
  - `_bus_apu_is_on 0`（APU 発電機は bus 1：推定）。
  - 負荷の割当（`_esys_bus_bit_add`）はほぼ bus 1。cross_tie=1 なので、電源の有無ではなく電流（バッテリーの消費、amps の表示）にだけ効く。
  - `_num_batteries 1`、`_battery_watt_hr_max 1272`：実機は 24 V 40 Ah が 2 個。

## 8. 作り直しか部分修正か

- **電源ロジック（`B747.03.xt.electrical.lua`）は作り直しを勧める。** 規模は L。
  - (1) 根本の前提（X-Plane の 5 本＋cross_tie）ではバス単位の通電を表せない。いまの bus*hot 群は表示用の近似で、前フレームの値を使って循環しており、直す足場にならない。
  - (2) 1065 行のうち、残すべきロジックは少ない。APU の手順、点火セレクター、quick start の状態設定くらい。コメントアウトされた古いロジックが多い。
  - (3) 他系統が依存するのは「どのバスに電源があるか」という API だけなので、新しいモデルが最初に出すべきもの。
- 進め方の案：
  1. init に公開 dataref（6 章）を足す。
  2. 純関数に近い電源モデルを書く。入力：スイッチ、N2/N3、APU、外部電源、空地、故障。状態：遮断器のラッチとタイマー。出力：バス、灯、CAS、synoptic、X-Plane の代理。4 章の論理表をそのまま実装する。
  3. 既存の表示用 dataref（bus1hot、rel_esys、display_has_power、ext/apu_pwr*_on など）をモデルから埋める。ELEC パネルの灯の計算を lighting から電源側に移すか、電源側の新しい dataref を読む形にする。
  4. 使う側（fuel、air、fms、warning、fltInst02/03/04、lighting、fltCtrls、AI）を新しい dataref に移す。
- INTERFACES.tsv の名前と意味（6 章の SHOW_* の漏れ分も含めて）を守れば、3D・パネル・音は変更不要。パネルで直せない表示（6 章）はカスタム acf の課題として別に扱う。
- APU と点火を同じモジュールに残すかは ATA 49/74 の担当と決める。

## 9. 未確認事項

- パネル計器の `BUS_SRC 2/3/4` が X-Plane のどのバスを指すのか（0 始まりの添字か）。そのバスの電圧で計器が消えるか暗くなるか。cross_tie=1 をやめる場合に効く。
- X-Plane の発電機が発電を始める回転と、`generator_off[i]` が書けるかどうか。GCB 状態と synoptic の GEN CONT 枠を一致させられるか。
- XP12 の GPU（`GPU_generator_volts`、地上サービスの GPU 車）と `connect_power` の実際の動き。FMC の GRND POWER だけで外部電源が available になるか。
- 実機で、バッテリーだけで電源を入れたとき ELEC AC BUS 1-4 が出るか。エンジン停止中に ELEC GEN OFF 1-4 が出るか（FCOM の論理からは出ると読める）。資料に記載なし。
- エンジン停止中の synoptic の DRIVE 枠（DRIVE 灯は点灯：FCOM p.104）。資料に記載なし。
- 109 の改良 GCU の SB を適用済みとみなすか（DRIVE と ELEC DRIVE の周波数条件）。GE を選んだときに 570 の仕様を当てるか。FREIGHTER のときに 570 の cargo handling bus を作るか。
- EXT/APU を切り離すとき IDG への戻りが no-break か break か（資料に記載なし）。断のある切替の断の長さ（資料に記載なし）。
- CDU C の電源（担当範囲の資料に記載なし）。utility bus と燃料ポンプの対応（資料に記載なし）。
- IDG disconnect の電源（FCOM：main battery bus、LH24 の図：hot battery bus）。
- バッテリーの放電電流（standby 時）は資料に記載なし。「最低 30 分」（FCOM p.804）を満たす値を推定で置く必要がある。X-Plane のバッテリーは 1 個（1272 Wh）なので、APU バッテリーは Lua 側で持つ必要がある。
- INTERFACES.tsv が、パネルの SHOW_* 条件にだけ出る laminar 名（175 個。電源関係は bus1hot など 15 個）を拾っていない。再生成が必要。
