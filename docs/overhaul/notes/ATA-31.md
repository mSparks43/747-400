# ATA 31 表示系（IDS：PFD・ND・EICAS 表示、表示切替、時計）— 調査ノート

対象コード：`overhaul` ブランチ（feedd8a9。plugins と acf は本家 041c9ffa のまま）。2026-10-23 調査。GAP の ID 接頭辞は `DSP`。

## 1. 概要

- 範囲：PFD（速度テープと各種バグ・限界帯、姿勢、FD、FMA の枠、高度・V/S、最低高度、気圧、ILS、故障フラグ）、ND（APP/VOR/MAP/PLN、CTR、レンジ、WXR/STA/WPT/ARPT/DATA/POS/TFC、シンボル）、EICAS の表示形式（上下、DSP、synoptic の枠組み、STAT、compact）、ソース選択（EIU・IRS・ADC・FD・NAV、CDU 代替操作）、表示器の電源・故障・輝度、時計。FDR・ACMS・W&B は概観のみ。
- 範囲外：EICAS メッセージの発生ロジック（別担当。ここでは表示系に属するメッセージの有無だけ扱う）、各 synoptic の中身、FMC のデータそのもの、FMA の中身（AFDS 担当）、スタンバイ計器（ATA 34 担当）。
- 型式の基準：他のノートと同じく **109（旅客型 PW）**。405/570 との違いは必要な所だけ書く。パネルは 109 寄り（DH/MDA、10〜640 NM、MAP は track up）だが、TERR スイッチ（405/570 のみ）、ND の TAS 表示（405/570 のみ）、2 位置の AIR DATA 選択器（570 型。3D の `Cockpit_Panel.obj:31894`）が混ざる。
- 資料：
  - FCOM 10.10（p.963-1068）全頁、10.20（p.1069-1079）、10.30（p.1081-1107、図）、10.40（p.1109-1111、p.1140-1158）、10.50（p.1197-1199）、7.10-7.12（p.829-857）、7.20 のうち表示形式（p.872-875）、15.10 の EICAS・DSP・STAT（p.1527-1530、p.1545）、15.20 の EICAS 表示・ND 自動表示・速度警報（p.1547-1549、p.1556-1557、p.1582-1585）、6.20 の負荷表（p.800、p.804）、PI.10.3（p.229）。
  - ATA31：31-62 EFIS（p.3-58。図 p.5, 15-17, 55, 57 を画像で確認）、31-25 時計（p.59-82）、31-31 FDR（p.279, 292）、31-35 ACMS（p.338）、31-41 W&B（p.412-426）。補助に ATA27 p.698-702（SWMC）、ATA34_1 p.142（ADC の VMO 曲線）。FCOM p.1072-1073 の切替図を画像で確認。
- 資料どうしの関係：ATA31 の EFIS 章は NCD/invalid の表以外ほぼ図で、内部ロジック（EIU の内部、表示器の BITE）は載っていない。乗員から見える挙動は FCOM に従う。時計の CHR 表示は ATA31 p.68 が「分:秒」、FCOM p.1058 が「分（秒は秒針）」→ FCOM を採り、上限 99 分は ATA31 から取る。

## 2. 構成

### 2.1 構成品

| 構成品 | 内容 | 根拠 |
|---|---|---|
| 表示器（DU）6 台 | 左右 outboard（PFD）、左右 inboard（ND）、upper（primary EICAS）、lower（secondary EICAS）。WXR は inboard と lower にだけ入る | FCOM p.1069-1071 (10.20.1-3) |
| EIU 3 台（L/C/R） | 全系統のデータを受けて表示を作る。EICAS は 3 台のうち 1 台が全面を制御 | FCOM p.1069, p.1547 (15.20.1) |
| EFIS control panel 2 台 | 左は左 PFD/ND、右は右 PFD/ND。故障時は同じ側の CDU で代替 | FCOM p.1035 (10.10.73) |
| Display select panel（DSP） | ENG/STAT/ELEC/FUEL/ECS/HYD/DRS/GEAR、CANC、RCL | FCOM p.1046-1047 |
| 計器ソース選択パネル ×2 | FLT DIR（L/C/R）、NAV（FMC L/FMC R/CDU L(R)/CDU C）、EIU（L/AUTO/C/R）、IRS（L/C/R）、AIR DATA（109 は L/C/R） | FCOM p.1043-1044 (10.10.81-82) |
| 中央パネル EIU 選択器 | EICAS 用の EIU（L/AUTO/C/R） | FCOM p.1529 (15.10.3) |
| INBD/LWR 表示選択器 ×2、HDG REF スイッチ | 表示の割り当て、方位基準 | FCOM p.1045-1046 |
| 輝度つまみ | outboard、inboard（外：表示、内：WXR）、upper、lower（外：表示、内：WXR）。周囲光センサーで自動補正 | FCOM p.1047-1048, p.1071 |
| SWMC（ATA 27-32） | 最小速度（stick shaker 速度）、Vmo、PLI のパラメーターを EIU 経由で供給 | ATA27 p.698, p.701-702 (27-32) |
| 時計 ×2 | UTC/日付、ET、CHR。グレアシールドの CHR スイッチと並列 | ATA31 p.60, p.66-70 (31-25) |

### 2.2 電源（109）

| 負荷 | バス | 根拠 |
|---|---|---|
| 左 PFD・左 ND（と左 FMC） | APU standby bus（通常は captain transfer bus。AC1・AC3 が無いと APU standby inverter） | FCOM p.800 (6.20.6), p.804 (6.20.10) |
| 右 PFD・右 ND、lower EICAS、右 EIU、右 EFIS CP、右 ADC、右 FMC/CDU | F/O transfer bus（AC2、無ければ AC1） | FCOM p.800 |
| upper（primary）EICAS、左 EIU、左 CDU、左 ADC、左 EFIS CP | main standby bus（AC3、無ければ main standby inverter） | FCOM p.804 |
| 中央 EIU、中央 ADC | captain transfer bus | FCOM p.800 |
| 時計 | main hot battery bus が時刻基準と電源 A/B。APU battery bus の電圧で表示（電源 B）を許可 | ATA31 p.64, p.74 (31-25) |
| DSP、輝度つまみ | 資料に記載なし | — |

- standby 電源で左 EIU が故障すると全表示器が消える（FCOM p.1529）。全 6 面が消えたら EIU L・C の CB を入れ直す（FCOM p.55、Operations Manual Bulletin）。

### 2.3 PFD のデータ源

姿勢＝IRS、ILS＝ILS と DME、速度テープ＝ADC・FMC・stall warning computer、FMA＝FCC と FMC、電波高度＝RA と EFIS CP、高度＝ADC、V/S＝IRS と ADC、方位＝FMC と IRS、選択方位＝FCC、滑走路方位＝ILS、マーカー、windshear＝GPWS（ATA31 p.6 (31-62)）。

## 3. 操作と表示

### 3.1 EFIS control panel（109）

| 操作 | 機能 | 根拠 |
|---|---|---|
| DH/MDA 選択（外）・設定つまみ（中）・RST（内） | DH＝電波高度、MDA＝気圧高度を設定。RST は点滅する amber DH を消す（値は変えない） | FCOM p.1036 (10.10.74) |
| MTRS / FPV（押しボタン） | PFD にメートル高度 / flight path vector を出す | FCOM p.1036-1037 |
| BARO：IN/HPA（外）、つまみ（中）、STD（内） | STD で 29.92/1013。STD 中は回すと preselect、もう一度 STD で preselect、preselect が無ければ STD 前の値 | FCOM p.1037 (10.10.75) |
| ND モード（外）・CTR（内） | APP/VOR/MAP/PLN。CTR は APP/VOR/MAP で拡大↔中心を交互に | FCOM p.1039 |
| レンジ（外）・TFC（内） | 109 は 10〜640 NM。TFC は VOR/APP/MAP/MAP CTR で TCAS 表示、TCAS FAIL を消す | FCOM p.1041-1042 |
| VOR/ADF L・R | VOR：針・識別符号/周波数・DME、ADF：針・識別符号/周波数（PLN 以外）、OFF で消す | FCOM p.1040; ATA31 p.24 |
| WXR/STA/WPT/ARPT/DATA/POS | 3.4 の表を参照。2 回押しで消える。多すぎると EXCESS DATA | FCOM p.1040 |

### 3.2 その他の操作

| 操作 | 機能 | 根拠 |
|---|---|---|
| ISS：EIU | L/C/R：その EIU。AUTO：機長は L→C→R、副操縦士は R→C→L の順に使える物を選ぶ。ILS 受信機もこれで決まる | FCOM p.1044 |
| ISS：IRS | 選んだ IRU の姿勢と V/S。方位・風・横滑り・航跡・偏流・GS は FMC/IRU の状態と NAV・IRS 選択器で決まる | FCOM p.1044 |
| ISS：AIR DATA / FLT DIR / NAV | ADC、FCC、FMC（CDU 位置は alternate navigation で ND の地図源） | FCOM p.1043-1044 |
| 中央 EIU SEL | AUTO：L→C→R。手動位置でその EIU が壊れると自動切替しない | FCOM p.1529 |
| INBD | EICAS：inboard に secondary（または primary）EICAS。NORM：ND（outboard 故障なら PFD）。PFD：inboard に PFD | FCOM p.1045 (10.10.83) |
| LWR | EICAS PRI：lower に primary EICAS。NORM：DSP の選択（upper 故障なら primary EICAS）。ND：lower に ND | FCOM p.1045 |
| HDG REF | NORM：磁方位（高緯度域では自動で真方位、AFDS は LNAV 以外不可）。TRUE：真方位。HDG SEL 中に切り替えると HDG HOLD | FCOM p.1046 |
| DSP | 押すと lower に表示、同じものをもう一度押すと消える。STAT は次ページ、最終ページで消える。CANC/RCL は 3.5 | FCOM p.1047, p.1530 |

### 3.3 PFD（要点）

| 要素 | 内容・条件 | 根拠 |
|---|---|---|
| 現在速度 | ADC 速度。計算値なしは 30 kt。最小機動速度未満で枠が amber。M.40 以上で Mach | FCOM p.968 (10.10.6) |
| 速度トレンド | 10 秒後の予測 | FCOM p.968 |
| 指令速度バグ・表示 | MCP の IAS/MACH、窓が空なら FMC 速度。範囲外は上下端に半分 | FCOM p.968-969 |
| 最大速度（red/black） | Vmo/Mmo、脚・フラップ placard の最小 | FCOM p.969 |
| 最大機動速度（amber） | 1.3 g で高速バフェット。高高度・高重量で出ることがある | FCOM p.969 |
| 最小機動速度（amber） | フラップ下げ：shaker まで 1.3 g。フラップ上げ 20,200 ft 未満：shaker まで 1.3 g と VREF+80 の小さい方。20,200 ft 以上：低速バフェットまで 1.3 g。離陸後最初のフラップ上げで表示開始 | FCOM p.973 (10.10.11) |
| 最小速度（red/black） | stick shaker（または低速バフェット）速度 | FCOM p.973 |
| V1・VR | CDU で選択したとき。VR が V1 から 4 kt 以内なら「R」。V1 が範囲外なら上端に数字。浮揚で消える。未選択は NO V SPD | FCOM p.972 |
| フラップ機動速度 | 現在の設定と 1 段小さい設定。約 20,000 ft 以上では出さない。値は UP=VREF30+80、1=+60、5=+40、10=+20、20=+10、25=VREF25、30=VREF30 | FCOM p.972; p.229 (PI.10.3) |
| VREF | CDU 選択値。範囲外なら下端に数字 | FCOM p.973 |
| 姿勢 | ピッチ目盛 2.5°、バンク目盛 0/10/20/30/45°。LCD はバンク 35° 以上で amber。PLI は 109 でフラップが上がっていないとき。左右の差で PITCH/ROLL フラグ | FCOM p.975 (10.10.13) |
| FD・FPV | FD バー。FPV は EFIS CP で選択 | FCOM p.980 |
| 電波高度・DH（109） | 2,500 ft 未満で表示。DH 以下で大きな点滅 amber DH。着地、DH+75 ft の復行、RST で解除。DH が 0 未満なら非表示 | FCOM p.981-982 |
| ILS | 識別符号/周波数、DME、コース（受信機間の不一致は amber の横線）。ポインターは 2⅓ dot 以内で塗りつぶし。目盛は同調後に表示。低高度で AP/FD 使用中に偏位過大なら目盛 amber・ポインター点滅（LNAV 中で LOC 未捕捉も）。expanded LOC は 1 枠 ½ dot。rising runway は 2,500 ft 未満、200 ft 未満で近づく。マーカー点滅（OM 青/MM amber/IM 白） | FCOM p.986-989 |
| 高度 | 選択高度（範囲外は端に半分）、メートル併記。到達前 900〜300 ft で枠を白強調、逸脱 300〜900 ft で amber。10,000 ft 未満は万の桁が斜線 | FCOM p.991-992 |
| MDA・TDZ（109） | MDA ポインターと数字（-100 ft 未満で非表示）。TDZ 斜線は FMC の着陸高度（出発地は 400 NM か半分の距離まで） | FCOM p.993 (10.10.31) |
| 気圧 | 設定値、STD、preselect、IN/HPA。遷移高度の上下 300 ft で設定の誤りがあれば枠付き amber | FCOM p.995 |
| V/S | ポインター、V/S モード中の選択 V/S、400 fpm 超で数字 | FCOM p.996 |
| 方位 | 方位ポインター（IRS 方位）、航跡、選択方位、MAG/TRU（TRU は枠） | FCOM p.997-998 |
| 故障フラグ | FPV、SEL SPD、SPD LIM、NO V SPD、SPD（NO V SPD・SEL SPD・SPD LIM・MACH を抑制）、ATT、FD、LOC、HDG、MACH、DH、RA、G/S、VERT、ALT、NO TDZ | FCOM p.999 (10.10.37) |

### 3.4 ND（要点）

| 要素 | 内容・条件 | 根拠 |
|---|---|---|
| モードと向き | MAP は 109 で track up、VOR・APP は heading up、PLN は真北 up で動かない（LEGS の STEP で送る）。APP CTR・VOR CTR・PLN では WXR・TCAS を出さない | FCOM p.1039, p.1109-1110 |
| 方位基準 | 磁/真。TRU で 2,000 ft を 800 fpm 超で降下すると基準の枠が amber で 10 秒点滅、2,000 ft を 500 fpm 超で上昇すると白に戻る。TRU→MAG で MAG を 10 秒枠囲み | FCOM p.1110, p.1142 |
| 選択方位 | PLN 以外。MAP で LNAV/LOC/ROLLOUT 中は、つまみを動かしてから 10 秒で破線だけ消す | FCOM p.1142 |
| 航跡線・レンジ | MAP・MAP CTR。VOR/APP では WXR か TFC がオンのとき | FCOM p.1143 |
| STA / WPT / ARPT | STA：10〜40 NM で高・低高度の施設、80 NM 以上は高高度だけ。同調中の VHF 施設はスイッチによらず緑。WPT：10〜40 NM。ARPT：全レンジ。出発・到着空港は常時 | FCOM p.1040, p.1145, p.1149 |
| DATA / POS | DATA：PLN・MAP・MAP CTR で ETA・高度・高度制限。POS：MAP・MAP CTR で IRU・GPS 位置、NAV RAD の VOR への radial（DME があれば距離に印） | FCOM p.1040 |
| 経路と諸点 | 経路（有効 magenta、変更 白破線、非有効 青長破線）、トレンドベクトル（30 秒ごと、レンジで 1〜3 区間）、高度到達弧、T/C・S/C・T/D・E/D、VNAV パスポインター（降下中のみ、±400 ft、超えたら数字）、空港・滑走路（80 NM 以上で空港、40 NM 以下で滑走路と 14.2 NM の中心線）、待機・PT、エネルギー円、FIX の基準点 | FCOM p.1147-1150 |
| 位置更新状態 | IRS(3)・DD・VD・LOC・GPS など。IRS(3) から変わると 10 秒緑枠 | FCOM p.1150 |
| GS・TAS・風 | GS は 30 kt 未満で大きい字。TAS は 405/570 のみ（100 kt 超） | FCOM p.1141-1142 |
| TCAS | RA 赤、TA amber、近接（1,200 ft・6 NM 以内）白塗り、他 白。相対高度、500 fpm 以上で矢印。OFFSCALE、TRAFFIC、no bearing 表示、TFC/TCAS TEST/TA ONLY（青）、TCAS FAIL/TCAS OFF（amber） | FCOM p.1031-1032, p.1152-1154 |
| メッセージ・フラグ | EXCESS DATA、WXR 系、RSTR INOP、MAP/WXR RANGE DISAGREE。HDG/TRK、MAP、VOR/LOC、VOR/ADF L・R、DME、VTK、G/S のフラグ。CDU が地図源なら CDU L/C/R | FCOM p.1030-1034, p.1151 |

### 3.5 EICAS の表示

- primary：EPR・N1・EGT（PW）、TAT、推力基準、メッセージ（警告→注意→勧告→メモ、1 ページ 11 行）、ページ番号、STATUS 差（cyan、新しいステータス。エンジン始動から離陸後 30 分は抑止）、二次エンジン逸脱差（cyan、STATUS 差より優先）、RECALL（離して 1 秒）（FCOM p.1527-1529, p.830）。
- secondary：二次エンジン（N2・FF・OIL P/T/Q・VIB）。電源投入時と、空中で燃料制御スイッチを CUTOFF にしたときに自動表示（FCOM p.843 (7.11.3), p.872 (7.20.2)）。109 は STAT ページに舵面位置（FCOM p.938 (9.10.12)）。
- 部分表示：二次エンジン非選択中に逸脱すると該当項目だけ出る。他の synoptic を選ぶと primary に compact で出る。表示器が 1 台なら primary に compact（FCOM p.874-875 (7.20.4-5), p.856-857）。
- STAT：ステータスメッセージ 11 行とページ番号（FCOM p.1545）。
- CANC：次ページ、最終ページで caution・advisory を消す（warning・memo は残る）、超過の赤枠を白に。RCL：1 ページ目へ全部再表示、赤枠を戻す（FCOM p.1530, p.1548-1549）。

### 3.6 CDU 代替操作（CDU-152）

MENU の EFIS CP / EICAS CP（パネル故障時に SELECT）→ EFIS CONTROL（BARO SET、DH SET、DH RESET、MDA SET、RANGE INCR/DECR、MODE、CTR、OPTIONS）、EFIS OPTIONS（WXR/POS/MTRS/FPV/WPT/STA/ARPT/DATA、VOR/ADF。TCAS は不可）、EICAS MODES/SYNOPTICS。各 CDU は自分の側の EFIS を操作する（FCOM p.1060-1068）。

### 3.7 時計

CHR（3 回で開始・停止・リセット、グレアシールドの CLOCK と同格）、秒針、ET（RUN/HLD/RESET。RESET は HLD に戻るばね）、DATE（日・月と年を 1 秒ごとに交互、もう一度で時刻）、SET（RUN/HLD Y/MS M/HS D）（FCOM p.1058-1059; ATA31 p.66-70）。

### 3.8 EICAS メッセージ（表示系）

| メッセージ | 種別 | 条件 | 根拠 | 現状 |
|---|---|---|---|---|
| >SNGL SOURCE RA | 勧告 | 両席が同じ RA | FCOM p.1197 (10.50.1) | 未実装（warning.lua:452） |
| >SOURCE SEL ADC/EIU/F/D/IRS/NAV | 勧告 | 両席が同じ ADC/EIU/FCC/IRU/FMC | FCOM p.1197 | 未実装（:453-457） |
| ALT DISAGREE | 注意・beeper | 未補正高度の差 200 ft 超が 5 秒超 | FCOM p.1197 | 未実装（:109） |
| >ATTITUDE | 注意・beeper | 選択 IRS の姿勢差 3° 以上 | FCOM p.1197 | 未実装（:111） |
| >BARO DISAGREE | 勧告 | 気圧設定の不一致が 1 分超 | FCOM p.1198 | 実装（fltInst02.lua:3184-3195） |
| >HEADING | 勧告 | 表示方位の差 4° 以上 | FCOM p.1198 | 未実装（:371） |
| IAS DISAGREE | 注意・beeper | 差 5 kt 以上が 5 秒超 | FCOM p.1198 | 未実装（:152） |
| >TRACK | 勧告 | 航跡の差 6° 以上 | FCOM p.1198 | 未実装（:477） |
| >AOA RIGHT | 勧告 | 右 AOA 故障 | FCOM p.1198 | 実装（X-Plane の rel_AOA、fltInst02.lua:3176-3182） |
| >EFIS CONTROL L, R / >EFIS/EICAS C/P | 勧告 | EFIS CP 故障 / 両 CP と DSP 故障 | FCOM p.1198-1199 | 未実装（:274-276） |
| >EIU LEFT | 勧告 | 左 EIU 故障。空中は抑止 | FCOM p.1199 | 未実装（:277） |
| >SNGL SOURCE ILS | 注意・beeper | 両席が同じ LOC/GS 受信機 | FCOM p.1430 (11.60.2) | 未実装（:165） |
| >AIRSPEED LOW | 注意・beeper | 最小機動速度未満 | FCOM p.1556, p.1605 | 実装（代用値、fltInst02.lua:3166-3174） |
| >OVERSPEED | 警告・siren | Vmo/Mmo 超過（placard は含まない） | FCOM p.1557, p.1605 | 実装だが placard でも出る（:3156-3164） |

## 4. 内部ロジック

### 4.1 表示器の割り当てと切替

- 通常：outboard＝PFD、inboard＝ND、upper＝primary EICAS、lower＝secondary EICAS（FCOM p.1071）。
- 自動切替：outboard が壊れると PFD は inboard へ（INBD NORM のとき）。upper が壊れると primary EICAS は lower へ（LWR NORM のとき）（FCOM p.1045, p.1072）。
- 手動：INBD EICAS で inboard に secondary EICAS（図では upper 故障で primary は lower）、LWR ND で lower に ND（FCOM p.1073 の図）。故障が無いときに表示が消える面がどうなるかは資料に記載なし。
- 表示器 1 台だけが EICAS に使えるとき：primary を常に出し、二次エンジンは compact（FCOM p.874）。
- 実装の考え方：表示器ごとに「電源・故障」の状態を持ち、選択器と故障から各表示器の内容を決める。結果はいまの `laminar/B747/flt_inst/display/*_pos` と `electrical/display_has_power[0..5]`（内容ごとの電源）に出す（パネルの約束）。

### 4.2 ソース選択と比較

- 通常位置（NP）：機長は FD L・NAV FMC L・EIU AUTO・IRS L・AIR DATA L、副操縦士は FD R・NAV FMC R・EIU AUTO・IRS R・AIR DATA R（FCOM p.111, p.115 (NP.21)）。
- EIU：席ごとに有効な EIU を AUTO の優先順で決める。その EIU が ILS 受信機を決める（FCOM p.1044）。EICAS は中央 EIU SEL の EIU（FCOM p.1529）。
- IRS：姿勢と V/S は選択 IRU。方位・航跡・風・GS は FMC 正常時は FMC 経由（ND の track は FMC、alternate navigation では IRU）（FCOM p.1044, p.1110）。IRS 選択は SWMC の入力も切り替える（ATA27 p.698）。
- AIR DATA：速度・高度・Mach・TAT。中央 ADC を選ぶと V/S が遅れることがある（FCOM p.1079 (10.20.11)）。
- 同じソースを両席で使うと SOURCE SEL、比較の閾値は 3.8 の表。RA は 3 台で、RA フラグは 3 台とも無効のとき（ATA31 p.16）。
- NCD と invalid（ATA31 p.15-17, p.55, p.57）：invalid はシンボルを消して黄色（amber）のフラグ、NCD はフラグなしで消す（または `---`）。例：姿勢 invalid→ATT、NCD→消去のみ。G/S・LOC invalid→目盛ごと消してフラグ、NCD→ポインターだけ消す。速度 invalid→SPD。MACH invalid→MACH、NCD か CAS invalid→消すだけ。HDG invalid→HDG、NCD→数字だけ消す。V/S invalid→VERT。DH は EFIS CP の値が invalid/NCD で DH。RA は 3 台とも invalid で RA。最大速度は SWC の Vmax と ADC の最大速度予定がともに invalid で SPD LIM、最小速度は SWC の Vmin invalid で SPD LIM。FMA invalid は文字に黄色の線。V 速度 invalid→NO V SPD。地図 invalid→MAP。

### 4.3 速度テープの値

| 値 | 求め方 | 根拠 |
|---|---|---|
| Vmo/Mmo | ADC のソフトに入った曲線（gear down dispatch で別曲線）。数値は資料に記載なし | ATA34_1 p.142 (34-12) |
| 最大速度 | Vmo/Mmo、脚 placard、フラップ placard の最小。SWMC と ADC から | FCOM p.969; ATA31 p.17 |
| 最大機動速度 | 1.3 g で高速バフェットに達する速度。高高度・高重量でだけ帯が現れる | FCOM p.969 |
| 最小機動速度 | 3.3 の 3 区分（20,200 ft 境界）。離陸後最初のフラップ上げから表示 | FCOM p.973 |
| 最小速度 | SWMC が AOA・フラップ・スポイラー・Mach から出す shaker 速度 | ATA27 p.698, p.701-702 |
| フラップ機動速度 | 3.3 の VREF30 基準。FCU が全部壊れると出ない | FCOM p.229; FCOM p.53 (bulletin) |

- 1.3 g の境界と shaker 速度の数値表は資料に記載なし。重量・高度・Mach・フラップから求める近似が要る（推定：PI の失速速度表と buffet boundary を使う）。

### 4.4 最低高度・気圧・高度・ILS

- DH（109）：電波高度 ≤ DH で amber DH 点滅。点滅時間は資料に記載なし。解除は着地、DH+75 ft までの上昇、同じ側の RST（FCOM p.981-982）。各 PFD は自分の側の DH と RA で判定する（推定：DH は EFIS CP ごとに設定し、両席が同じ RA を使うと SNGL SOURCE RA が出るため）。
- 気圧 STD の状態機械：通常→STD 押し＝STD（29.92/1013、preselect 無し）。STD 中に回す＝preselect を表示。STD 押し＝preselect があればそれ、無ければ STD 前の値（FCOM p.1037）。遷移高度の警告：気圧設定のまま MCP が遷移高度より上で、遷移高度+300 ft を越えると枠付き amber。STD のまま MCP が遷移高度より下で、遷移レベル−300 ft を下回ると同じ（FCOM p.995）。遷移高度・遷移レベルは FMC の値（推定）。
- 高度枠：選択高度の 900〜300 ft 手前で白強調、捕捉後 300〜900 ft 逸脱で amber（FCOM p.991-992）。ALTITUDE ALERT 本体は警報担当。
- ILS：スケールは同調で表示（FCOM p.987）。偏位過大の amber 化は「低い電波高度で AP/FD 使用中」としか書かれておらず、高度と dot の閾値は資料に記載なし。

### 4.5 ND

- 向き：MAP＝航跡（FMC、無効なら IRU）、VOR/APP＝方位、PLN＝真北。向きの基準は MAG/TRU に従う（FCOM p.1110）。
- レンジ表示は選択レンジの半分の弧に数字を出す（推定：FCOM p.1001 の図で 40 が 80 NM 相当の位置）。
- 自動表示（FCOM p.1583-1585 (15.20.37-39)）：immediate windshear 中は新しい TCAS（109）を自動表示しない。新しい TA/RA で、片方の ND に TFC が出ていればその ND は維持し、もう片方は抑止（後で TFC を押すと表示）。どちらにも出ていなければ両 ND で自動選択。MAP/MAP CTR/VOR/APP 以外の ND は「待機」し、そのモードになると自動選択。TA/RA が終わっても自動では消さない。TERR（405/570）・PWS→WXR も同様（WXR/TERR を先に選べば解除）。
- EXCESS DATA：表示できる量を超えたらメッセージ。上限は資料に記載なし。

### 4.6 EICAS の形式とページ

- secondary の状態：OFF / 全表示 / 部分表示。ENG 押し：OFF↔全表示、部分表示中は全表示↔部分表示。他の synoptic 選択中の逸脱は primary に compact の部分表示。逸脱が戻るまで部分表示と差は消えない。差が出ていて部分表示が無いとき STAT を押すと primary に compact（FCOM p.874-875）。
- メッセージのページ：警告が 1 ページを超えたらページ番号を出さない。新しい注意・勧告は見ているページの警告の直下に入る。RCL は 1 ページ目に戻す（FCOM p.1548-1549）。
- STAT：新しいメッセージが上。STAT の押し方は CANC/RCL と同様のページ送り（FCOM p.1549）。

### 4.7 時計

- 電源：main hot battery bus が無いと全機能停止（電源復帰後は 00:00 と秒針 60 で、SET の HLD Y で 1 桁進めるまで NCD）。APU battery bus が無いと表示だけ消え、内部は動く（ATA31 p.66, p.74, p.78, p.80; FCOM p.1075）。
- 機長時計が FMC L、副操縦士時計が FMC R へ UTC/日付。FMC は機長時計を主、故障で副へ。GPS があれば GPS が時刻源（ATA31 p.77; FCOM p.1075）。
- SET：MS は 1 分/秒、HS は 1 時間/秒で進む。HLD で停止、RUN で開始（ATA31 p.67）。ET は 99:59 まで、CHR は 99 分 59 秒まで（ATA31 p.67-68）。

### 4.8 FDR・ACMS・W&B（概観）

- FDR：空中、またはエンジン 1 発以上作動で記録。最新 25 時間。EIU からデータ、故障は EIU へ。DFDAC は standby bus と F/O transfer bus、DFDR は AC3（ATA31 p.279, p.292 (31-31)）。乗員の操作は無い。
- ACMS：DMU と QAR。報告を中央 CDU・プリンター・ACARS へ（ATA31 p.338 (31-35)）。
- W&B（オプション）：脚の荷重から GW・CG。ground service bus 給電。FMC（PERF INIT の GR WT ADV、TAKEOFF の CG）と EIU へ（ATA31 p.414, p.422, p.426 (31-41); FCOM の FMC 章）。FMC 担当。

## 5. 他系統とのつながり

| 相手 | 内容 | 根拠・現状 |
|---|---|---|
| 電源（ATA 24） | 2.2 のバス。表示・EIU・時計の通電判定 | 現状は `capt_display_power`・`fo_display_power` の 2 値（electrical.lua:546-548）。ATA-24 ノートの ELEC-01/02 が前提 |
| IRS（ATA 34） | 姿勢・方位・航跡・GS・風、整列状態（TIME TO ALIGN） | `laminar/B747/pfd/{capt,fo}/irs` は irs_system.lua:209-210 が「位置入力済み かつ 選択 IRU 整列」で 1 にする |
| ADC・RA・ILS/VOR/ADF/DME（ATA 34） | 速度・高度・Mach・TAT、RA、偏位・識別符号 | パネルは X-Plane の pilot/copilot 計器 dataref を直接読む。VOR L/R は nav 番号 2/3、ILS は 0/1（B744.fms.pages.lua:2562-2565） |
| SWMC（ATA 27） | 最小速度、Vmo、PLI | 現状は fltInst02 が表で代用し、stick shaker（`sim/flightmodel/failures/stallwarning`）と `sim/cockpit2/autopilot/TOGA_pitch_deg` まで書いている（fltInst02.lua:3083-3123） |
| AFDS（ATA 22） | FMA、FD バー、指令速度、選択方位・高度、`ils_dots` | `ils_dots` は autopilot.lua:1635-1638, 1792-1797 |
| FMC（ATA 34-61） | 経路・地図、V 速度選択、VREF、着陸高度（TDZ）、遷移高度、ND の文字列（GS/TAS/風、次 WPT） | V1/VR/V2 は fltInst02 が表から自動計算（選択操作なし）。ND 文字列は B747.68.xt.fms.lua:930-1042 |
| TCAS・GPWS・WXR | ND の交通・地形・気象、PFD の PULL UP/WINDSHEAR | 気象・地形は X-Plane の EFIS map と外部 Terrain Radar |
| EICAS メッセージ（別担当） | 表示系メッセージ（3.8）、CAS ページ、STATUS | warning.lua:895-1000 がページを作る（最大 10 ページ） |
| エンジン（ATA 77） | 一次・二次表示の値と色 | 別担当。形式（compact/部分）はここ |
| 燃料 | 燃料制御スイッチで ENG 表示 | fuel.lua:568-594 が `dsp/synoptic_display` を書く |
| 照明 | 表示器の輝度 | lighting.lua:893-918 |

## 6. 実装上の注意

- **パネルの制約**：描画は acf 末尾の generic instrument。純正 acf は変えない。カスタム acf の変更は承認が要る。各 GAP に【Lua のみ】【パネル変更要】を付けた。パネルは表示内容ごとに `display_has_power[i]` と `*_pos` で位置と電源を切り替える作り（内容 0=機長 PFD、1=副 PFD、2=副 ND、3=機長 ND、4=upper、5=lower、6〜8=CDU）。この意味は変えない。
- パネルの読み先：速度テープは Lua の `laminar/B747/gauges/indicators/airspeed_kts_*`（fltInst02.lua:3223-3234）なので Lua でソースを変えられる。高度・姿勢・方位・V/S・RA・ILS は X-Plane の `sim/cockpit2/gauges/indicators/*_pilot/_copilot` を直接読む。X-Plane 12 には ADC・AHRS を席の間で切り替える dataref が無い（`Resources/plugins/DataRefs.txt` で確認。あるのは `alternate_static_air_ratio` と HSI/RMI の航法源だけ）ので、ソース切替にはパネル変更（Lua が作る席別の値を読ませる）が要る。
- SHOW 条件の意味：`SHOW_GREATER 1 .../pfd_pos`（値は 0/1）や、存在しない `display/fo/eicas_pos` に `SHOW_GREATER 0` で EICAS が出ていることから、SHOW_GREATER/LESS は「以上/以下」と推定（ATA-28 ノートと同じ結論）。複数条件が AND か OR かは未確認（`GROUP <= DH`、747-400.acf:86915 は AND なら決して表示されない）。
- 型式の混在（1 章）：109 を基準にし、TERR と ND の TAS は設定でどちらにもできるようにするのが無難。PFD の LCD/CRT は `laminar/B747/pfd/style`（simconfig）で、現パネルの差は NO V SPD の絵だけ。
- 他系統のロジックが fltInst02 に同居している（stick shaker、TO/GA ピッチ目標、BAT DISCH MAIN・BATTERY OFF、OVERSPEED/AIRSPEED LOW）。作り直しでは所管の系統へ移し、表示系は「表示用の値を読むだけ」にする。`dsp/synoptic_display` は燃料モジュールも書く（XTLua では複数モジュールからの書き込みが非同期に競合する）。
- ND の地図記号は 1 側 60 個の文字アイコン（`nd/{capt,fo}/text/*`）と X-Plane の EFIS map（WXR・地形・経路）の重ね合わせ。アイコン位置の更新は毎フレーム、航法データの JSON 解読は 2 秒ごと、`earth_fix.dat` は前回の走査完了から 10 秒後に少しずつ走査（nd.lua:552-607, 690-768）。アイコンの作り直しは 0.2 秒ごとのつもりだが判定を誤っていて実質ほぼ毎フレーム（DSP-21）。仕組み自体は残してよい。
- 簡略化してよい：EIU の内部、表示器の BITE、色故障、周囲光センサー、ACMS、W&B、FDR（開発用ログのままでよい）。簡略化してはいけない：ソース選択が表示内容と SOURCE SEL/DISAGREE に効くこと、最低高度の警報と解除、速度テープの限界値、表示器喪失時の切替と compact EICAS、CANC/RCL/STAT のページ操作、OVERSPEED の条件。

## 7. 現状実装との比較（GAP 候補）

| ID | 種別 | 重要度 | 規模 | 内容 | 根拠 | 該当コード |
|---|---|---|---|---|---|---|
| DSP-01 | 挙動の誤り | 高 | S | PFD の方位目盛が `laminar/B747/nd/up/*` で回る。ND が MAP なら航跡、PLN なら 0（真北）が上になり、PFD の方位ポインターが IRS 方位を示さない。ND 側は同じ dataref が必要なので Lua だけでは直せない【パネル変更要：PFD を方位の dataref に】 | FCOM p.997 (10.10.35) | nd.lua:698-721; 747-400.acf:88024, 88078, 91613, 91667, 95171, 95225, 98739, 98793 |
| DSP-02 | 欠落 | 高 | L | ソース選択が無い。FLT DIR・NAV・EIU・AIR DATA の選択器と中央 EIU SEL は位置を変えるだけ。IRS 選択器は姿勢の有効判定にだけ効く。PFD/ND は常に X-Plane の pilot/copilot 側、RA は両 PFD とも機長側（`efis/radio_altitude`）。比較監視（SOURCE SEL、SNGL SOURCE）も無い【一部パネル変更要：速度テープは Lua のみ】 | FCOM p.1043-1044, p.1197; ATA31 p.16 | fltInst02.lua:520-657, 2366-2379; irs_system.lua:209-210 |
| DSP-03 | 挙動の誤り | 高 | M | パネルが NAV ソース選択器（FMC L/FMC R/CDU）を ND の基準受信機の選択に流用。機長 ND は NAV=0 で ILS L、1 で ILS R、2 で VOR L、3 で VOR R（副は 2=ILS L、3=ILS R、0/1=VOR で、要素によって 0 と 1 が入れ違い）。通常位置 FMC L では VOR モードにコース・偏位・受信機表示が出ない。PFD の ILS コースと DME は FMC master 選択器で nav1/nav2 を切り替える【パネル変更要：基準受信機用の dataref を新設】 | FCOM p.1043-1044, p.1144 | 747-400.acf:108772, 108834, 108900（機長 ND）、86769, 87735（PFD）; fltInst02.lua:3453-3454 |
| DSP-04 | 欠落 | 中 | L | PFD の故障フラグは ATT・HDG・VERT（どれも IRS 未整列で一斉）と NO V SPD だけ。SPD・ALT・MACH・FD・G/S・LOC・RA・DH・FPV・SEL SPD・SPD LIM・NO TDZ・PITCH/ROLL が無い（PITCH/ROLL は画像だけある）。NCD と invalid の区別も無い【パネル変更要】 | FCOM p.999; ATA31 p.15-17 | 747-400.acf:87107, 88117 |
| DSP-05 | 挙動の誤り | 高 | M | 速度テープの帯が違う。最大機動速度は常に Vmax−10（高高度・高重量でだけ出るはず）。最小機動速度は重量とフラップの独自式（20,200 ft の区分、1.3 g、VREF+80 が無い）。表示開始は推力基準が TO 以外になったとき（最初のフラップ上げではない）【Lua のみ】 | FCOM p.969, p.973 | fltInst02.lua:2858-2876, 2986 |
| DSP-06 | 挙動の誤り | 高 | S | OVERSPEED を Vmax（フラップ・脚 placard 込み）で出している。FCOM では Vmo/Mmo のみ【Lua のみ】 | FCOM p.1557 (15.20.11) | fltInst02.lua:3156-3164 |
| DSP-07 | バグ | 中 | S | 最小速度（Vs）の高度区分で 0 ft 以上は常に 0〜2,000 ft 帯（elseif が届かない）。2,000 ft 超の値が 2,000 ft で頭打ち【Lua のみ】 | — | fltInst02.lua:3018-3032 |
| DSP-08 | バグ | 中 | S | 表の誤記：VsData F20 10,000 ft 200 t＝133.60、F20 0 ft 360 t＝156.66、VR F10 D 領域 320〜420 t＝93〜111、VR F20 D 220 t＝97、V2 F20 E 380 t＝149（V 速度は FMC 担当と調整）【Lua のみ】 | — | fltInst.lua:116, 137, 193, 274, 277 |
| DSP-09 | バグ | 高 | S | DH RST を押すと、両席の DH を 350 ft（MDA 選択中は MDA を 1,000 ft）に書き換える。RST は点滅を消すだけ。副の RST は機長側のスイッチ位置も 1 にして離しても戻さないので、機長が RST を押し直すまで DH 警報が毎フレーム即解除される（3D のボタンも押されたまま）【Lua のみ】 | FCOM p.1036 | fltInst02.lua:778-792, 949-963 |
| DSP-10 | 挙動の誤り | 中 | M | DH 警報は機長の DH・RA だけで計算し、両 PFD が同じ `dec_height/display_status` を読む（副の PFD も機長の DH で表示が変わる）。点滅は 5 秒で止まり点灯のまま（時間は資料に記載なし）。RA の amber グループの条件が矛盾（`<= DH`）【パネル変更要：席ごとの dataref】 | FCOM p.981-982 | fltInst02.lua:2248-2311; 747-400.acf:86841, 86915 |
| DSP-11 | 挙動の誤り | 中 | S | STD を押すと preselect を 29.92 にするので、戻すと「STD 前の値」でなく 29.92 になる。遷移高度の amber 枠が無い（パネル）。CDU の BARO 入力・STD が両席に効く【一部パネル変更要】 | FCOM p.995, p.1037, p.1064 | fltInst02.lua:859-871, 1030-1042; B744.fms.pages.lua:957-984 |
| DSP-12 | 欠落 | 中 | L | PFD の記号が無い：FPV（スイッチもラッチしない）、PLI、TDZ、選択高度枠の白強調と amber、LCD のバンク 35° amber、範囲外の V1・VREF の数字、VR の「R」、ILS 偏位過大の amber・点滅、ILS 周波数・コース不一致の線【パネル変更要】 | FCOM p.972-993 | fltInst02.lua:875-881 |
| DSP-13 | 挙動の誤り | 低 | S | フラップ機動速度バグをレバー位置（flap_ratio）の重なった範囲で出す。フラップ 30 で 20 のバグが残る。25 の値が VREF30+5（FCOM は VREF25）【Lua のみで近似可】 | FCOM p.972, p.229 | fltInst02.lua:2882-2902; 747-400.acf:85859 |
| DSP-14 | 挙動の誤り | 中 | S | PFD の ILS 表示（`ils_dots`）が「目的地から 50 NM 以内」を条件にしている。FCOM は同調で目盛表示（現状では離陸時に同調しても LOC が出ない）【Lua のみ】 | FCOM p.987 | autopilot.lua:1635-1638, 1792-1797 |
| DSP-15 | バグ | 中 | S | パネルの参照誤り：機長 ND の TRK/HDG 表示が副の ND モード選択器、中心表示の方位ポインターが副の方位、拡大 APP の G/S が副の偏位、ILS R の周波数が nav3、ILS/VOR の識別符号フラグの取り違え、空の dataref 名の条件 182 か所、EICAS の表示条件が存在しない `display/fo/(pri_)eicas_pos`【パネル変更要】 | INTERFACES.tsv | 747-400.acf:109432, 109475, 109516, 108994, 110018-110045, 116618, 116632, 116915, 99470, 117804, 125278 |
| DSP-16 | 欠落 | 中 | M | DATA・POS が機能しない（スイッチが状態を持たず、CDU でもコメントアウト）。WPT の ETA・高度、IRU/GPS 位置、VOR radial が無い【一部パネル変更要】 | FCOM p.1040 | fltInst02.lua:1196-1210, 1357-1371; B744.fms.pages.lua:855, 890 |
| DSP-17 | 欠落 | 低 | M | STA に高・低高度の区別が無く、同調施設も STA オフでは出ない。出発・到着空港と滑走路を常時出さない。60 個で黙って打ち切り（EXCESS DATA なし）。MAP フラグは IRS 未整列のときだけ。109 では出ない TAS を出す【一部パネル変更要】 | FCOM p.1040, p.1111, p.1149 | nd.lua:254, 256-316; B747.68.xt.fms.lua:1032-1034 |
| DSP-18 | 欠落 | 中 | M | TCAS：TA/RA での TFC 自動選択（4.5）が無い。記号は白の菱形 1 種（相対高度 2,000 ft 以内を全部）。アイコン画像 `nd_icons-1.png` には RA 赤・TA amber・白の菱形と上下矢印があるのに使っていない。近接（白塗り）の絵と amber の相対高度文字は無い。TCAS OFF を TFC 未選択でも出す、TA ONLY が無い。X-Plane の地図の TCAS 表示は `EFIS_tcas_on_copilot` を使わず、どちらかの TFC で機長側の 1 本を立てる【一部パネル変更要（色分けと矢印は Lua のみ）】 | FCOM p.1032, p.1152-1154, p.1584 | fltInst02.lua:2566-2603; nd.lua:274-279, 496-509 |
| DSP-19 | 欠落 | 低 | M | TERR は外部 Terrain Radar 頼みで、この X-Plane には入っていない。カスタム acf には `*.terrain_radar_descr` も無い。地形・PWS 警報での自動表示も無い【Lua のみ（外部依存を除く）】 | FCOM p.1585 | fltInst02.lua:1212-1219; nd.lua:705-714 |
| DSP-20 | 欠落 | 中 | M | HDG REF スイッチが 3D の位置しか動かさない。TRU 表示、高緯度の自動 TRU、amber 点滅枠、HDG SEL→HDG HOLD が無い【パネル変更要（TRU 表示）】 | FCOM p.1046, p.1110 | manipulators.lua:1479-1481 |
| DSP-21 | バグ | 低 | S | 航跡線の判定に CTR の押しボタン位置（押している間だけ 1）を使い、副の判定に機長の WXR 状態を使う。ND のアイコン作り直しの 0.2 秒判定が `diff2` でなく `diff`（2 秒周期の基準）を見ており、ほぼ毎フレーム全アイコンを作り直す【Lua のみ】 | FCOM p.1143 | fltInst02.lua:2610-2630; nd.lua:748-752 |
| DSP-22 | 挙動の誤り | 低 | S | MAP で LNAV/LOC/ROLLOUT 中、選択方位の破線だけでなくバグごと消す（バグと破線が同じグループ）【パネル変更要】 | FCOM p.1142 | fltInst02.lua:3588-3625; 747-400.acf:109809 |
| DSP-23 | 欠落 | 低 | M | トレンドベクトル、S/C・E/D・減速点、待機・PT、エネルギー円、FIX 基準点が無い【パネル変更要】 | FCOM p.1147-1150 | nd.lua:466-495 |
| DSP-24 | 欠落 | 中 | L | EICAS の compact・部分表示・二次エンジン逸脱差が無い。ENG の自動表示を地上・RUN 方向でも出す（空中の CUTOFF のみのはず）。電源投入時の自動表示は flight start のときだけで、停電からの復帰では出さない【パネル変更要（自動表示の条件は Lua のみ）】 | FCOM p.843, p.872-875 | fuel.lua:568-594; fltInst02.lua:1386-1393, 3441 |
| DSP-25 | 欠落 | 中 | M | STAT ページにステータスメッセージの行が無い（Lua のページ送りだけある）。STATUS 差も無い【パネル変更要】 | FCOM p.1528, p.1545 | fltInst02.lua:1395-1411; 747-400.acf:129368 |
| DSP-26 | 欠落 | 低 | S | CAS の表示はパネルが 2 ページ分だけ。警報モジュールは最大 10 ページ作る【パネル変更要】 | FCOM p.1548-1549 | 747-400.acf:118045; warning.lua:898-902 |
| DSP-27 | 欠落 | 中 | L | 表示器と EIU の故障が無く、自動切替（PFD→inboard、PRI EICAS→lower）、EIU の AUTO 切替、「standby 電源で左 EIU 故障なら全消灯」が無い【Lua のみ（compact を除く）】 | FCOM p.1045, p.1072, p.1529 | fltInst02.lua:3236-3404 |
| DSP-28 | バグ | 中 | S | 選択器の組み合わせ 81 通りのうち 11 通りしか処理せず、他は直前の配置のまま。INBD EICAS で ND を lower へ、INBD PFD で secondary EICAS を outboard へ移すなど資料に無い入れ替えをする【Lua のみ】 | FCOM p.1045, p.1073 | fltInst02.lua:3239-3403 |
| DSP-29 | 挙動の誤り | 中 | M | 表示の電源が粗い：副表示の AC1 代替を STBY POWER 選択器に依存させ、upper EICAS を機長表示と同じ扱い、EIU は無い。APU 始動中に機長表示を消す処理は資料に記載なし（ATA-24 の ELEC-01/02 が前提）【Lua のみ】 | FCOM p.800, p.804 | electrical.lua:546-548, 624-626; fltInst02.lua:3245-3250 |
| DSP-30 | 欠落 | 低 | S | 輝度が表示器でなく内容に付く（PFD を inboard に移しても outboard のつまみ）。3D のつまみが操作する `instrument_brightness_ratio[1]`・`[4]`・`[11]`（WXR の内側つまみと推定）を使う計器が無い。周囲光の自動補正なし【一部パネル変更要（WXR）】 | FCOM p.1047-1048, p.1071 | lighting.lua:893-918 |
| DSP-31 | 挙動の誤り | 中 | S | CDU の EFIS 操作：RANGE が両席に効く、WXR は常に機長側、MODE が X-Plane の map_mode を更新しない、POS/DATA 不可、SELECT が常時出る（パネル故障の概念なし）【Lua のみ】 | FCOM p.1060-1068 | B744.fms.pages.lua:849-993, 45-90 |
| DSP-32 | 欠落 | 中 | M | 表示系メッセージの大半（3.8 の「未実装」）が無い。文言は表にあるが立てる処理が無い【Lua のみ（DSP-02 に依存）】 | FCOM p.1197-1199, p.1430 | warning.lua:109-111, 152, 165, 274-277, 371, 452-457, 477 |
| DSP-33 | バグ | 低 | S | 時計：CHR が 60 分で 59:99 に止まる（99:59 まで）。CHR 表示中は ET の開始・リセットが効かない。SET 選択器が何もしない。UTC・日付・ET の表示に電源条件が無く、年は OS の日付。表示消灯は `clock_utc_display=2` などパネルの値で可能【Lua のみ】 | ATA31 p.67-68, p.74; FCOM p.1075 | fltInst03.lua:127-149, 190-204, 216-225, 260-262, 318-346（fltInst04 も同じ） |
| DSP-34 | 挙動の誤り | 中 | M | 計器モジュールが他系統の出力を書く：stick shaker を「速度 < 表の Vs」で出し、`TOGA_pitch_deg` を書き、BAT DISCH MAIN・BATTERY OFF を立てる（ATA 27・22・24 へ移す）【Lua のみ】 | ATA27 p.701 | fltInst02.lua:3083-3123, 3197-3216 |
| DSP-35 | バグ | 低 | S | ACF_DIFF §2 の「ADF 方位針 2 個」は実は機長 ND 中心表示の VOR L/R 針。コードは VOR L/R を nav 番号 2/3 に同調するので純正の `[2]`・`[3]` が正しく、カスタムの `[3]`・`[4]` は誤り（VOR L 針が VOR R を指す）。ADF 針の `adf1/2_relative_bearing_deg[10]`（スカラーに添字）も要確認【パネル変更要（カスタム acf）】 | ACF_DIFF.md §2 | 747-400.acf:109044, 109062; 747-400_custom.acf:98755, 98773; 747-400.acf:99631 |

- 重要度の内訳：高 6、中 19、低 10（計 35）。

## 8. 作り直しか部分修正か

- **表示ロジック（fltInst02 のうち表示・選択器・速度テープ・最低高度・気圧・DSP・表示切替）は作り直しを勧める。** 理由：(1) 3,700 行に計器・選択器・V 速度表・他系統（stick shaker、TO/GA ピッチ、電池メッセージ）が混在し、席ごとの状態が対になっていない（DH・RST・BARO・CDU）。(2) ソース選択・表示器故障・EIU という骨格がそもそも無く、継ぎ足しでは DSP-02/27/28/32 を整合させにくい。(3) 選択器の配置は 4 つの位置の符号化 81 通りを手書きの表で持っており、規則で解く形に変えた方が安全。分け方の案：`efis_control`（EFIS CP・CDU 代替・席ごとの状態）、`source_select`（EIU/IRS/ADC/FD/NAV と比較監視の出力）、`display_manager`（表示器の電源・故障・選択器→`*_pos`・`display_has_power`）、`speed_tape`（限界値。SWMC 相当は ATA 27 担当と共有）、`minimums_baro`。INTERFACES.tsv の `laminar/B747/flt_inst/*`・`efis/*`・`nd/*`・`dsp/*`・`pfd/*`・`airspeed/*`・`dec_height`・`radio_alt`・`vsi/fpm`・`STAT/*` とコマンドは名前と値の意味を保つ。
- **ND の地図エンジン（xtlua_nd）は部分修正。** アイコン配置・更新周期は動いており性能も調整済み。DSP-16〜19・21・23 は機能追加で済む。
- **時計（fltInst03/04）は部分修正**（DSP-33）。2 ファイルは機長/副の複製なので 1 本にまとめるとよい。
- **FDR プラグインは現状維持**（実機 DFDR の模擬ではなく開発用ログ。乗員から見えない）。
- **パネル**：パネル変更が要るもの（DSP-01・03・04・10・12・15・20・22〜26・35。一部が要るのは 02・11・16〜18・30）は、カスタム acf への変更案として一覧にまとめ、利用者の承認を得てから行う。優先は DSP-01（方位）と DSP-03（基準受信機）。Lua だけで直るもの（DSP-05・06・07・09・14・27・28・31〜33 など）は先に進められる。

## 9. 未確認事項

1. パネルの SHOW 条件が複数あるときに AND か OR か、境界を含むか（`GROUP <= DH`、747-400.acf:86915 の RA amber が出るか）。
2. `adf1_relative_bearing_deg[10]` のようなスカラーへの添字を X-Plane がどう扱うか（ADF 針が動くか）。
3. X-Plane の EFIS map（`EFIS_map_t_HM` 等）が MAP で track up になっているか、プラグインの文字アイコンと向きが合うか。TCAS 記号を X-Plane 側でも描いて二重になっていないか。
4. X-Plane の pilot/copilot 計器の故障（`sim/operation/failures/*`）を、どの範囲で実機の ADC/IRU/RA の故障の代わりに使うか（パネルは X-Plane の席別の値を直接読むので、故障はそのまま表示に出る）。
5. `radio_altimeter_height_ft_pilot` が 2,500 ft を超えても値を返すか（T/D アイコンが RA>5,000 ft を条件にしている。nd.lua:470）。
6. 故障の無いときに INBD EICAS・INBD PFD を選ぶと、空いた表示器（lower・outboard）に何が出るか（資料に記載なし）。
7. DH の点滅時間と、109 で RA の数字が DH 以下で色を変えるか（資料に記載なし）。
8. 副操縦士側の NAV 選択器の位置番号と 3D の目盛の対応（パネルは副で 2=ILS L、3=ILS R、0/1=VOR を混用）。
9. 速度テープの 1.3 g 境界、shaker 速度、Vmo/Mmo の数値の出所（FCOM・ATA に表が無い。PI の失速速度表から作るか）。
10. 最小機動速度帯と最小速度帯を離陸滑走中・浮揚直後にどう出すか（「最初のフラップ上げで表示」は最小機動速度だけの記述）。
11. Terrain Radar プラグインを使う前提を残すか（カスタム acf 用の descriptor を作るか）。
12. APU 始動中に機長表示を消す処理（fltInst02.lua:3247-3250）が実機の挙動か。
