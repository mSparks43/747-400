# ATA 34 Navigation（FMC を除く）調査メモ

2026-10-23 調査。対象コードは `overhaul`（041c9ffa）。出典の書き方は REFERENCE_INDEX.md に従う。GAP の ID は NAV-xx。

## 1. 概要

- 対象
  - エアデータ：pitot-static、ADC L/C/R、AOA・TAT、Vmo/Mmo と OVERSPEED、altitude alert
  - 計器ソース切替：instrument source select（FLT DIR、NAV、EIU、IRS、AIR DATA）、中央パネルの EIU と FMC master
  - スタンバイ計器：standby ASI・altimeter・attitude、磁気コンパス、RMI
  - IRS L/C/R（MSU、アライン、位置入力、ATT、電源と ON BAT）、GPS L/R
  - 無線航法受信機（VOR/MKR、ADF、ILS、DME）と同調（手動、FMC autotune、代替同調）
  - 電波高度計（RA）L/C/R、GPWS（mode 1–7、look-ahead、TCF）、windshear
  - ATC トランスポンダ、TCAS、気象レーダー（WXR）
  - 上記の EICAS メッセージ
- 対象外（境界は §5）：FMC の航法計算と CDU ページ一覧（ATA 34-61）、表示器の書式全般（ATA 31）、警報の共通の仕組み（aural 発生器、master caution/warning の共通部）、ACP の構成（ATA 23）、probe heat の加熱制御（ATA 30）、AFDS（ATA 22）。
- 使った資料（PDF ページ）
  - ATA34_1：p.3–32（20-11。ARINC 429 の SSM と EIU だけ）、p.33–70（34-11）、p.71–82（34-13）、p.83–168（34-12）、p.169–200（34-16）、p.201–274（34-43）、p.275–322（34-57）、p.323–386（34-51）、p.387–422（34-32）、p.423–512（34-31）、p.513–572（34-55）、p.573–646（34-53）。図は `_ref/text/img/ATA34_1/` の p.99・103・111・113・143・283・435・525 を見た。
  - ATA34_2：p.3–68（34-45）、p.69–110（34-33）、p.111–240（34-46）、p.241–256（34-24）、p.257–262（34-22）、p.263–374（34-21）、p.375–426（34-58）。図は `_ref/text/img/ATA34_2/` の p.39・89・99・117・129・145・153・155・163・169・175・181・185・187・195・199・201・207・239・273・275・281・287・295・363 を見た。
  - FCOM：10.10 p.981–1000・1013–1018・1030–1044・1052–1057・1060、10.20 p.1071–1079、10.40 p.1110・1144–1155、10.50 p.1197–1199、11.10 p.1210・1215–1224、11.20 p.1225–1232、11.31 p.1240–1244、11.40 p.1285–1287・1303–1307、11.50 p.1422・1427–1428、11.60 p.1429–1435、15.10 p.1527–1545、15.20 p.1547–1602（GPWS・windshear・TCAS の部分）、15.30 p.1603–1605。ほかに NP（p.95–152 の該当箇所）、SP.11 p.194、L.10 p.77、3.30 p.635、4.20 p.666、6.20 p.800・803、0.1 p.5。
  - FCOM 5.10（p.683–712）にはトランスポンダの記述が無い。トランスポンダと WXR のパネルは 11.10.12–18（p.1218–1224）にある。
- effectivity：FCOM の 109（PW 旅客機）を基準にする（ATA-36.md と同じ扱い。FCOM p.5 (0.1.1)）。ただし 3D コクピットは次の点で別の型に近い。どちらに合わせるかは利用者の判断（§9）。
  - WXR パネルは 570 型（747-400_cockpit.obj:22986-23028）。
  - GND PROX パネルの TERR OVRD、EFIS の TERR スイッチと RADIO/BARO の MINS は 405/570（look-ahead 付き EGPWS）の構成。
  - RMI は 405 だけの装備（FCOM p.1074 (10.20.6)）だが 3D にある。
  - TCAS は 109 に Ver 6.04A と 7.0 がある（FCOM p.1553–1554）。FMOD の warnings.bank の音声素材は 7.0 の文言なので 7.0 とする（推定）。
- 資料が食い違うときは本文に両方を書き、乗員に見える挙動は FCOM に従った。
- 現状の要約：ATA 34 の大半は、X-Plane のセンサーをパネルが直接読んで成り立っている（§2.3）。プラグインのロジックがあるのは、IRS のアライン（簡略）、NAV RADIO ページと VOR/ILS の autotune（簡略）、トランスポンダのノブ（対応が誤り）、ソース選択器のノブ（ほぼ飾り）、OVERSPEED（条件が誤り）、DH alert、一部の EICAS メッセージだけ。GPWS と TCAS の判定ロジックは無い。
- ACF_DIFF §2 の「ADF 方位針」は、実は ND の VOR L/R 方位針だった。純正 acf の `[2]/[3]` が正しい（NAV-41）。

## 2. 構成

### 2.1 機器と電源

| 系統 | 機器 | 電源 | 主な出力先 | 根拠 |
|---|---|---|---|---|
| エアデータ | ADC L / C / R。C は L か R の代替 | L：115V AC standby bus、C：Capt transfer bus、R：F/O transfer bus | EIU、FCC、YDM、SRM、FCU、CPC、EEC、FMC、IRU、ATC、GPWC、MAWEA | ATA34_1 p.84・p.103・p.111・p.113 (34-12)、FCOM p.800・p.803 (6.20) |
| | ADC source select relay（Capt 用・F/O 用。ラッチ式） | 28V DC bus 3 | ADC 出力バスと C の構成の切替 | ATA34_1 p.99–100・p.114 (34-12) |
| | pitot-static probe 4 本（CAPT、F/O、AUX 1、AUX 2）、flush static port 4 個（前方 = alternate、後方 = dedicated）、C 用の pitot/static source select valve | valve は電気駆動 | §2.2 | ATA34_1 p.36–58 (34-11) |
| | AOA vane L/R（各 2 出力）、TAT probe（L は L と C の ADC 用の 2 素子、R は 1 素子） | AOA は ADC の 26V AC。TAT heater は 115V AC（空中のみ） | ADC | ATA34_1 p.94・p.102・p.120 (34-12)、FCOM p.1079 (10.20.11) |
| | EIU L / C / R（3 ADC を直接受け、選択は discrete） | L：standby bus、C：Capt transfer、R：F/O transfer | PFD、ND、EICAS | ATA34_1 p.113、FCOM p.800・p.803 |
| | crew alerting card（MAWEA 内。altitude alert） | PSU A（資料の表記は「standby bus No. 3」）/ PSU B（F/O instrument transfer bus） | EIU、aural | ATA34_1 p.170・p.188 (34-16) |
| スタンバイ | standby ASI（AUX 1 pitot + alternate static、60–450 kt、故障旗なし） | 照明 5V AC だけ | — | ATA34_1 p.76・p.80 (34-13)、FCOM p.1055 (10.10.93) |
| | standby altimeter（alternate static、BARO 22.00–31.99 inHg / 745–1084 hPa、故障旗なし） | vibrator 28V DC（無いと固着） | — | ATA34_1 p.78、FCOM p.1055–1056 |
| | standby attitude（独立の垂直ジャイロ。APP で左 ILS を表示） | main battery bus 28V DC → inverter 20V AC 400 Hz | — | ATA34_2 p.244・p.252 (34-24)、FCOM p.1075 (10.20.7) |
| | 磁気コンパス | 照明 5V AC | — | ATA34_2 p.258 (34-22) |
| IRS | IRU L / C / R（RLG。ARINC 429 出力 3 本） | AC：L = AC bus 3、R = AC bus 2、C = AC bus 1。backup は APU hot battery bus（C は条件付きで 5 分後に切断、§4.5） | EIU、FCC、FMC、CDU、YDM、WXR、GPWC、DMU。ブレーキと失速警報へは source select relay 経由 | ATA34_2 p.266・p.273–275・p.281 (34-21) |
| | MSU（IRU ごとに OFF-ALIGN-NAV-ATT。NAV はデテント）、IRS ON BAT 灯（頭上整備パネル P461、白） | ON BAT 回路は APU hot bat bus | — | ATA34_2 p.286・p.294–295、FCOM p.1216–1217 (11.10.10–11) |
| GPS | GPS/MMR L / R（12 ch。MMR は ILS 受信機と一体） | L：AC STBY bus、R：AC bus 2 | FMC、DMU（405/570 は GPWS も） | ATA34_2 p.384・p.386・p.388 (34-58)、FCOM p.1225 (11.20.1) |
| 無線航法 | VOR/MKR L / R（108.00–117.95 MHz。MKR は L の分だけ有効） | L：AC STBY bus、R：AC bus 2 | EIU、FMC、AMU | ATA34_1 p.330・p.343 (34-51)、p.388・p.394 (34-32) |
| | ADF L / R（190–1749.5 kHz） | L：AC bus 3、R：AC bus 2 | EIU（ND）、AMU | ATA34_1 p.276・p.283・p.288 (34-57) |
| | ILS L / C / R（LOC 108.10–111.95、GS 329.15–335.00 MHz） | L：AC STBY bus、C：AC bus 1、R：AC bus 2 | 自側 FCC、EIU、FMC（ID）、GPWC（L）、AMU | ATA34_1 p.435・p.446・p.448 (34-31) |
| | DME L / R（5 ch、252 ch を走査、320 NM まで） | L：AC bus 3、R：AC bus 2 | EIU、FMC、AMU | ATA34_1 p.524・p.525・p.539 (34-55) |
| RA・GPWS | RA L / C / R（4,300 MHz FM/CW、−20〜2,500 ft、AID 57 ft、暖機 1 分） | L：AC bus 3、C：AC bus 1、R：AC bus 2 | EIU、FCC、MAWEA（L/R）、GPWC、TCAS | ATA34_2 p.70・p.76・p.78・p.82・p.84 (34-33) |
| | GPWC（EGPWS：mode 1–7、look-ahead、TCF。地形 DB と 3,500 ft 以上の滑走路 DB） | AC bus 3 | EIU、MAWEA、TCAS（inhibit）、WXR、terrain select relay → ND | ATA34_2 p.114・p.129・p.135 (34-46) |
| | GND PROX パネル（F/O 計器盤） | — | GPWC、MAWEA（CONFIG GR OVRD） | ATA34_2 p.139・p.207、FCOM p.1537–1539 |
| 監視 | ATC トランスポンダ L / R（Mode S）、ATC/TCAS パネル | L：AC standby bus、R：AC bus 2。アンテナスイッチは DC bus 2 | TCAS、EIU（故障） | ATA34_1 p.584・p.590 (34-53) |
| | TCAS コンピュータ、上下の指向性アンテナ | AC bus 3 | PFD、ND、DMU、MAWEA（音声） | ATA34_2 p.17・p.21–22・p.30 (34-45) |
| | WXR R/T L / R、アンテナ 1 基（導波管スイッチ。無励磁で L） | 115V AC（バス名は資料に記載なし） | ND（ARINC 453） | ATA34_1 p.208・p.210・p.212・p.253 (34-43) |

### 2.2 pitot-static の配管（ATA34_1 p.44・p.47–48・p.76・p.104、FCOM p.1077 (10.20.9)）

| 受け手 | pitot | static |
|---|---|---|
| ADC L | CAPT | CAPT（左上 S1 + 右下 S2） |
| ADC R | F/O | F/O（右上 S1 + 左下 S2） |
| ADC C（通常 = L の代替） | AUX 2 | AUX 1（左上 S2 + 右下 S1） |
| ADC C（F/O が C を選択 = R の代替） | F/O | AUX 2（右上 S2 + 左下 S1） |
| standby ASI / standby altimeter | AUX 1 / なし | alternate（前方の flush port 左右） |
| elevator feel computer | AUX 1・AUX 2 | dedicated（後方の flush port） |

### 2.3 シムでの現状の実体

| 実機 | 現状 | 根拠コード |
|---|---|---|
| ADC L/C/R、EIU | 無い。表示と全利用者が X-Plane の pilot（Capt）/ copilot（F/O）系を直接読む | B747.60.xt.fltInst02.lua:3223-3234、B747.42.xt.EEC.lua:53・194・213-215、B747.45.xt.fltCtrls.lua:131 |
| IRU L/C/R | `irs/irs_system.lua` のアライン状態だけ。姿勢・方位はパネルが X-Plane の AHARS 1（Capt）/ 2（F/O）を直接読む | irs_system.lua、747-400.acf の PFD/ND |
| GPS L/R | シムの真位置そのもの | irs_system.lua:78-83 |
| VOR L/R | X-Plane の NAV3/NAV4（配列 index 2/3） | B744.fms.pages.lua:2562-2565、irs/rnav_system.lua:76-85、B747.60.xt.fltInst02.lua:103-104 |
| ILS L/R（C は無い） | NAV1/NAV2（index 0/1）。コースは `nav_obs_deg_mag_pilot[0]/[1]` | B744.fms.pages.lua:401-404、B747.70.xt.autopilot.lua:1752-1786 |
| ADF L/R | ADF1/ADF2 | B744.fms.pages.lua:2566-2567 |
| DME | X-Plane の受信機ごとの DME（`nav_dme_distance_nm[N]`。NAV 周波数に自動で対） | パネル定義 |
| MKR | X-Plane の marker 受信機 1 台 | パネル定義 |
| RA | X-Plane の pilot 側 RA を −8 ft して 1 系統 | B747.60.xt.fltInst02.lua:2366-2378 |
| GPWS・windshear | PFD は X-Plane の annunciator、音声は FMOD .snd の条件式 | 747-400.acf:87129-87154、fmod/747-400.snd:5942-6103 |
| TCAS | X-Plane の traffic 位置を ND に白い 1 種類のアイコンで描くだけ | B747.61.xt.nd.lua:496-509 |
| WXR | X-Plane のレーダーそのまま | — |
| トランスポンダ | X-Plane の `transponder_mode` に 1 か 2 だけを書く | B747.30.xt.fltMgmt.lua:216-229 |
| standby 計器 | obj が Capt の速度・高度・気圧と X-Plane の AHARS を読む | Cockpit_Panel.obj:32047-32401 |

## 3. 操作と表示

### 3.1 計器ソース切替

左右の instrument source select パネル（FCOM p.1042–1044 (10.10.80–82)。通常位置は FCOM p.110 (NP.21.16)・p.115 (NP.21.21)）

| 選択器 | 位置 | 働き | 通常位置（Capt / F/O） |
|---|---|---|---|
| FLT DIR | L / C / R | PFD の FD を出す FCC | L / R |
| NAV | FMC L、FMC R、CDU L（Capt）、CDU C、CDU R（F/O） | FMC L/R が PFD と ND に航法情報を出す。CDU は alternate navigation で ND へ | FMC L / FMC R |
| EIU | L / AUTO / C / R | PFD・ND へ出す EIU。AUTO は Capt が L→C→R、F/O が R→C→L の順に作動中のものを選ぶ。各側の LOC/GS 受信機もこれで決まる | AUTO / AUTO |
| IRS | L / C / R | PFD の姿勢と V/S。heading・track・風・GS は FMC と IRU の状態と NAV/IRS 選択で決まる。Capt 側で選んだ IRU が autobrake の基準 | L / R |
| AIR DATA | L / C / R（109・405。570 は L / R） | PFD と ND に出す ADC | L / R |

- AFDS 作動中の heading 表示は、NAV で作動中の FMC を選んでいれば IRS 選択によらず NAV モードの IRU から出る（FCOM p.1228 (11.20.4)）。
- 中央パネルの EIU selector（EICAS 用）：L / AUTO / C / R。AUTO は L→C→R の順に作動中の EIU を選ぶ。手動選択では自動切替をしない。standby 電源で L を選んでいて左 EIU が故障すると全 CRT が消える（FCOM p.1529 (15.10.3)）。
- FMC master selector：L / R。誘導指令を出す FMC を選ぶ。A/T 作動中に切り替えると A/T が切れる（再作動は可）（FCOM p.1215 (11.10.9)、p.666 (4.20)）。飛行中に選択外の FMC が故障すると SINGLE FMC OPERATION、選択中の FMC が故障すると全 CDU に TIMEOUT - RESELECT が出て、NAV でその FMC を選んでいる側の ND は消える（FCOM p.1275 (11.32)）。

### 3.2 ADC の表示と BARO

- PFD 速度テープは ADC の CAS。30 kt 未満と NCD は 30 を表示し、故障でテープを消して SPD 旗（ATA34_1 p.126 (34-12)）。Mach は .40 未満と NCD で空白、故障で MACH 旗（ATA34_1 p.128、FCOM p.999 (10.10.37)）。高度は選択 ADC の気圧高度で、故障でテープと窓を消して ALT 旗（ATA34_1 p.130、FCOM p.992 (10.10.30)）。V/S は ADC V/S を IRS で減衰したもの（FCOM p.996 (10.10.34)）。
- TAT は EICAS に常時、CAS/Mach/高度/SAT は AUX EICAS の PERF、TAS/SAT は CDU PROGRESS 2/2、TAS は ND（100 kt 超）。故障で各表示を消す（ATA34_1 p.132）。C ADC 選択時は V/S 表示が遅れることがある（FCOM p.1079 (10.20.11)）。
- EFIS control panel の BARO：外側 IN/HPA、中間ノブで設定、内側 STD 押しボタン（ATA34_1 p.124、FCOM p.1037 (10.10.75)）。STD は 29.92 in / 1013 hPa。STD 表示中にノブを回すと 2 行目に preselect を出し、次の STD 押しでその値に戻る。preselect が無ければ STD を押す直前の値に戻る（FCOM p.1037、ATA34_1 p.135–136）。電源投入時は電源断時の値（ATA34_1 p.135）。
- PFD の気圧表示は、気圧設定のまま転移高度 + 300 ft を超えて上昇、または STD のまま転移レベル − 300 ft を下回ると枠付きの琥珀（FCOM p.995 (10.10.33)）。

### 3.3 Altitude alert（FCOM p.992・p.1559、ATA34_1 p.178–184）

- 接近：選択高度の 900 ft 手前から 300 ft まで、PFD の選択高度表示と現在高度の枠を白で強調。
- 逸脱：300 ft 以上 900 ft 以内に離れると、EICAS >ALTITUDE ALERT（琥珀）、master caution、level B aural、高度窓の枠が琥珀（2 重線）。

### 3.4 スタンバイ計器と RMI（FCOM p.1052–1056、ATA34_2 p.244–258）

- standby attitude：bank 目盛 0/10/20/30/45°、GYRO 旗、G/P 旗、LAT 旗、caging（引くと水平に戻す）、APP 選択（OFF / APP = 左 ILS / B/CRS）。表示範囲は上 107°・下 63°・ロール 360°。
- standby ASI は未補正の IAS、standby altimeter は未補正の気圧高度で自前の BARO ノブ。RVSM の精度要件を満たさない（FCOM p.77 (L.10)）。
- RMI（405 だけ）：細い指針 = 左 VOR/ADF、太い指針 = 右。heading は F/O の IRS 選択が R なら右 IRU、C か L なら中央 IRU。NORM で極域なら HDG 旗、TRUE で VOR を選ぶと VOR 旗（FCOM p.1056–1057 (10.10.94–95)、p.1075）。

### 3.5 IRS・GPS

- MSU（FCOM p.1216 (11.10.10)）：OFF でアラインを失う。ALIGN は駐機中に選ぶとアライン開始、NAV から選ぶとセンサー誤差を除く。NAV はアライン完了で NAV モードへ入る通常位置。ATT は姿勢モードで、位置と速度は地上で再アラインするまで失い、CDU から磁方位の入力が要る。NAV はデテントで、引かないと NAV から動かせない（ATA34_2 p.294–295）。
- IRS ON BAT 灯：IRS がバックアップ電源（APU hot battery bus）で動作中（FCOM p.1217 (11.10.11)）。点灯条件は §4.5。
- CDU POS INIT 1/3（FCOM p.1285–1287 (11.40.9–11)）：LAST POS、REF AIRPORT、GATE、UTC（GPS / MAN）、GPS POS。SET IRS POS は、いずれかの IRU が align 中で位置が未入力ならボックス、align 中でなければ空白。SET HDG は、いずれかの IRU が ATT のときダッシュ。0–360 を受け付け、ATT の全 IRU の磁方位を更新し、2 秒後にダッシュへ戻る。
- POS REF 2/3：FMC POS（括弧内に更新源）、IRS(3) の位置と GS、RNP/ACTUAL、`<PURGE`、GPS NAV INHIBIT/ENABLE。POS REF 3/3：IRS L/C/R と GPS L/R の位置・GS（ATA34_2 p.396–400 (34-58)、FCOM p.1244 (11.31.10)）。地上で NAV の IRU の GS はドリフト率、IRS MONITOR（地上のみ）は IRU ごとの平均ドリフト率（ATA34_2 p.356–358 (34-21)）。
- PFD・ND：姿勢・方位・V/S は IRS から（FCOM p.966–967・p.997）。源の故障か計算値が無いとき ATT・HDG・VERT 旗（FCOM p.999）。ATA は NCD（消すだけ）と invalid（旗）を分ける（ATA34_2 p.310–328）。乗員表示なので FCOM に従い、アライン中も旗を出す。ND の track・GS・風は通常 FMC から、FMC 故障で選択 IRU から（ATA34_2 p.314）。
- ND MAP 左下の更新状態：IRS (3)/(L)/(C)/(R)、GPS / LOCGPS、DD / VD / LOC など。IRS (3) から変わると 10 秒間緑の枠。POS スイッチで IRU 位置と GPS 位置を FMC 位置に対して表示（FCOM p.1150 (10.40.42)、p.1225 (11.20.1)）。

### 3.6 無線航法

- CDU NAV RADIO ページ（FCOM p.1303–1307 (11.40.27–31)）
  - VOR L/R：周波数と状態。P = procedure、R = route（直前の VOR か 250 NM 以内の先の VOR）、A = 位置決めに最適な局、M = 手動。手動が優先し、DELETE で autotune へ戻る。入力は識別符号か周波数（XXX.X / XXX.XX）、または識別符号か周波数とコース。対の DME も同調する。
  - CRS は autotune 中は空白。VOR 進入では IAF/FAF の通過で FMC が procedure 同調し、inbound コースも入れる。RADIAL は局から機体への radial。
  - ADF L/R：手動だけ。末尾 A で ANT（方位を出さず音声優先）、B で BFO。
  - ILS：周波数/フロントコース、またはコースだけ（/YYY）。状態は PARK、「XXX.XX/YYY PARK」、A、M。PARK は電源投入時、T/D まで 200 NM 超、または目的地まで半分未満。周波数/コース PARK は、ILS・LOC・BC か ILS/LOC のある滑走路への進入を選び、T/D まで 200 NM 未満か半分を過ぎたとき。A は同じ進入選択で T/D まで 50 NM 未満、滑走路端まで 150 NM 未満、または FMC が descent のとき。E&M p.540 (34-55) も同じ規則だが、p.460 (34-31) は「200 NM か半分で autotune」で食い違う。FCOM に従う。
- ALTN NAV RADIO（両 FMC 故障。FCOM p.1422 (11.50.2)、p.1427–1428）：autotune 無し。左 CDU が VOR L・DME L・ADF L・ILS L、右 CDU が右側、中央 CDU が ILS C だけを同調。ILS は故障時に autotune 中だった値を写し、無ければ PARK。
- EFIS control panel の VOR/ADF スイッチ（左右）：VOR で VOR 指針・周波数か ID・DME（PLN 以外）、ADF で ADF 指針と周波数か ID、OFF で消去（FCOM p.1038–1040 (10.10.76–78)）。ND の APP は基準 ILS 受信機・コース・DME・LOC/GS 偏位、VOR は基準 VOR・コース・DME・TO/FROM・偏位を出す。VOR は緑、ADF は cyan（FCOM p.1228・p.1230）。ID 解読前は周波数。同調中の VHF 局は STA スイッチに関係なく緑で地図に出る。手動同調の VOR は選択コースと逆方向も出す（FCOM p.1145 (10.40.37)）。
- 無効表示（E&M）：ADF NCD は指針を消し周波数は残す、invalid は ADF 旗、ANT で指針を消す（ATA34_1 p.304–308 (34-57)）。VOR 方位 NCD は偏位・TO/FROM を消し、invalid は VOR 旗。autotune 中は VOR 偏位・コース指針・選択コース・TO/FROM を消す（p.358–368 (34-51)）。DME は 99.95 NM 未満 0.1 NM 刻み、以上 1 NM 刻み、NCD はダッシュ、invalid は PFD で空白・ND で旗。左 ND は左 DME、右 ND は右 DME（p.546–552 (34-55)）。
- PFD（FCOM p.986–989 (10.10.24–27)、ATA34_1 p.466–470 (34-31)）
  - approach reference：ILS の ID か周波数、ILS DME、コース。同調中の ILS 同士で周波数（コース）が違うと琥珀の横線。周波数・ID は、周波数が有効で、roll が 53° 未満で、選択 ILS が PARK でないときに出す（E&M p.466）。
  - MB：OM 青、MM 琥珀（E&M は yellow）、IM 白。局の符号に合わせて点滅。VOR L 故障時は出ない（FCOM p.987）。
  - LOC/GS：受信で指針、中心から 2 1/3 dot 以内で塗りつぶし（ND は 2 1/2 dot：FCOM p.1144）。scale は周波数同調後に出る。過大偏位警告は §4.7。expanded localizer は 1 目盛 1/2 dot。rising runway は RA 2,500 ft 未満で出て、200 ft 未満で近づく。

### 3.7 電波高度計と minimums

- RA 表示：−20〜2,500 ft のデジタル。2,500 ft 超は空白。刻みは 100 ft 未満 2 ft、500 ft 未満 10 ft、以上 20 ft（ATA34_2 p.95 (34-33)、FCOM p.981）。RA 故障で RA 旗、NCD で空白（ATA34_2 p.96）。
- minimums：EFIS CP の MINS（RADIO/BARO）、設定ノブ、MINS RST。RA が設定以下で、109 は大きな琥珀 DH が点滅、405/570 は「RADIO」と値が琥珀で点滅。リセットは接地、設定 + 75 ft への上昇、RST。RST は点滅のリセットだけ（FCOM p.981–982、p.1036 (10.10.74)）。E&M は「最初の 3 s 点滅、DH + 75 ft の上昇で arm」（ATA34_2 p.95）。EFIS CP 故障時は CDU の EFIS CONTROL で DH −20〜999 ft と DH RESET（ATA34_2 p.92、FCOM p.1060）。GPWS の minimums voice は機長側の設定を使う（FCOM p.1540）。

### 3.8 GND PROX パネル、PFD・ND の GPWS 表示、aural

| 操作子・灯 | 動作 | 根拠 |
|---|---|---|
| GND PROX G/S INHB（押しボタン） | 1,000 ft RA 未満で押すと GLIDE SLOPE を禁止（鳴る前なら禁止、鳴っていれば取消）。再押しでは戻らず、30 ft 未満への降下か 1,000 ft 超への上昇で mode 5 が再 arm | FCOM p.1537 (15.10.11)、ATA34_2 p.139・p.174 (34-46) |
| GND PROX 灯（琥珀） | GLIDE SLOPE、SINK RATE、TERRAIN、TOO LOW FLAPS/GEAR/TERRAIN、look-ahead caution・TCF の間。inhibit/override した警報では点かない | FCOM p.1538、p.1573 |
| FLAP OVRD（ガード付き alternate、OVRD 灯） | flaps 25 以上を模擬し TOO LOW FLAPS を禁止。押したまま IAS > 250 kt が 60 s 超で GND PROX SYS | FCOM p.1538、ATA34_2 p.139・p.205 |
| CONFIG GR OVRD（同） | gear down を模擬し TOO LOW GEAR と EICAS の CONFIG GEAR を禁止（MAWEA にも配線）。IAS > 290 kt が 60 s 超で GND PROX SYS | FCOM p.1538、ATA34_2 p.207 |
| TERR OVRD（405/570） | look-ahead 警報と terrain 表示（TCF も）を禁止。mode 1–7 は影響なし。>TERR OVRD | FCOM p.1538、ATA34_2 p.128・p.140 |

- 109 の GND PROX パネルは G/S INHIBIT スイッチと白の G/S INHIBIT 灯、GND PROX 灯、FLAP OVRD、CONFIG GR OVRD で、TERR OVRD は無い（FCOM p.1538–1539）。
- PFD の赤 PULL UP は mode 1・2 の warning と look-ahead warning、赤 WINDSHEAR は immediate windshear。表示中は他の GPWS 警報を禁止（FCOM p.1531 (15.10.5)、ATA34_2 p.142）。PULL UP・WINDSHEAR の間は master WARNING 灯（FCOM p.1532、p.1555）。
- ND の terrain（405/570）：TERR スイッチで MAP/MAP CTR/VOR/APP に表示し WXR を解除。2,000 ft 境界の緑の濃淡、点の緑・琥珀・赤・マゼンタ、警報中は塗りの琥珀/赤。TERRAIN/OBSTACLE、TERR、TERR OVRD、TERR FAIL、TERR POS、TERR TEST、TERR RANGE DISAGREE（FCOM p.1540–1543）。

| voice（405/570） | 条件 | 灯 |
|---|---|---|
| SINK RATE → PULL UP | mode 1 | GND PROX → PFD PULL UP + master WARNING |
| TERRAIN → PULL UP | mode 2（landing config では TERRAIN だけ） | 同上 |
| DON'T SINK | mode 3 | GND PROX |
| TOO LOW, GEAR / TOO LOW, FLAPS / TOO LOW, TERRAIN | mode 4（TERRAIN は高速時）、TCF | GND PROX |
| GLIDE SLOPE | mode 5（音量と反復は偏位で増加） | GND PROX |
| 2500, 1000, 500, 100, 50, 40, 30, 20, 10 | mode 6（405。109 は 100/50/30/10、570 は 500 が条件付きで 100〜10） | なし |
| APPROACHING MINIMUMS（設定 + 80 ft）、MINIMUMS | 405（570 は MINIMUMS だけ） | なし |
| BANK ANGLE | 35°・40°・45°。低高度では 10° から（405） | なし |
| CAUTION TERRAIN / CAUTION OBSTACLE | look-ahead caution（40–60 s 前） | GND PROX、ND 琥珀 |
| TERRAIN, TERRAIN, PULL UP / OBSTACLE…PULL UP | look-ahead warning（20–30 s 前） | PFD PULL UP、ND 赤、master WARNING |
| siren + WINDSHEAR ×3 | immediate windshear | PFD WINDSHEAR、master WARNING |

- 根拠：FCOM p.1573・p.1576–1578・p.1581。E&M は mode 3 を SINK RATE/TERRAIN、mode 4 を TERRAIN と書く（ATA34_2 p.161・p.168）。FCOM に従う。

### 3.9 トランスポンダ（109、FCOM p.1219–1220 (11.10.13–14)、p.1533–1534）

- モードセレクタ：TEST（試験）、STBY（無効）、ALT OFF（高度報告なし）、ALT ON（空中で高度報告）、TA（トランスポンダと TCAS の TA。RA になるはずの機体は TA として扱う）、TA/RA。
- ATC スイッチ 1 / 2 で L / R を選ぶ。選ばない側には standby discrete（ATA34_1 p.584）。表示はコード、ATC 1 / ATC 2、R（応答）。ATC FAIL 灯（琥珀）は選択中のトランスポンダの故障。IDENT は SPI を 18 秒送る（ATA34_1 p.620・p.633）。
- Mode S は STBY 以外なら常に動く。空中では ALT ON・TA・TA/RA で高度を報告する（FCOM p.1231 (11.20.7)）。
- E&M の ATC/TCAS パネルには ABOVE/N/BELOW スイッチ（ABV +9,900/−2,700 ft、N ±2,700 ft、BLW +2,700/−9,900 ft）がある（ATA34_2 p.26）が、FCOM の 109 パネルには無い。FCOM に従い ±2,700 ft の窓だけにする。
- 手順：離陸滑走路に入るとき TA/RA（FCOM p.128 (NP.21.34)）。停止時 STBY（FCOM p.152 (NP.21.58)）。
- 3D のモードノブは 5 位置（0–4）で TEST が無い（Cockpit_Pedestal1.obj:40246-40252）。コードからみて 0 STBY、1 ALT OFF、2 ALT ON、3 TA、4 TA/RA（推定）。

### 3.10 TCAS の表示と音声

- ND のシンボル（FCOM p.1534 (15.10.8)、p.1152 (10.40.44)、ATA34_2 p.42–44 (34-45)）：RA は赤の塗り四角、TA は琥珀の塗り丸、proximate（6 nm 以内かつ ±1,200 ft 以内）は白の塗り菱形、other は白の中抜き菱形。相対高度は 100 ft 単位の 2 桁で上なら +、下なら −。±500 fpm 以上で上下矢印。no-bearing は右上に最大 2 件。
- 表示できる ND モードは MAP、MAP CTR、VOR、APP（FCOM p.1560 (15.20.14)、p.1039 (10.10.77)）。160 nm 未満で直径 3 nm のリング（ATA34_2 p.42）。

| ND メッセージ | 色 | 条件（FCOM p.1032 (10.10.70)、p.1153–1154、p.1535、p.1562–1563） |
|---|---|---|
| TFC | cyan | traffic 表示が有効。TCAS FAIL / OFF / TEST の表示中は出さない |
| TRAFFIC | 琥珀 / 赤 | TA / RA 発生中。全モード・全レンジ、TFC の有無によらない |
| OFFSCALE | 琥珀 / 赤 | TA / RA が ND レンジ外 |
| TA ONLY | cyan | TA モード（RA を出せない）。全モード |
| TCAS TEST | cyan | 試験中 |
| TCAS FAIL | 琥珀 | 故障、または ND に出せない。TFC 選択時 |
| TCAS OFF | 琥珀 | モードが TA・TA/RA 以外。TFC 選択時 |

- TFC スイッチは traffic 表示の入切。TCAS FAIL 表示中に押すとその表示を消す（FCOM p.1042）。TA/RA 発生時、どちらの ND にも TFC が出ていなければ、該当モードの ND を自動で TFC にする（片側が既に TFC ならもう片側はしない）。該当モードでない ND は armed になり、そのモードにした時点で TFC。自動で入った TFC は TFC スイッチを押すまで残る（FCOM p.1534、p.1584 (15.20.38)）。
- PFD（109）：RA pitch region（赤枠）。1 つの RA に 1 つ、複数 RA で 2 つ（FCOM p.1537、p.1562）。570 は赤の VS 帯も出す。E&M は赤のピッチ記号と VS 帯（ATA34_2 p.46）。FCOM の 109 に従う。
- 音声（109、Ver 7.0。FCOM p.1553 (15.20.7)、p.1563–1568）：TA は TRAFFIC, TRAFFIC（1 回）。RA は CLIMB, CLIMB / DESCEND, DESCEND、CLIMB, CROSSING CLIMB / DESCEND, CROSSING DESCEND、INCREASE CLIMB / INCREASE DESCENT、CLIMB, CLIMB NOW / DESCEND, DESCEND NOW、MAINTAIN VERTICAL SPEED, MAINTAIN（CROSSING 付きも）、MONITOR VERTICAL SPEED、ADJUST VERTICAL SPEED, ADJUST。終了は CLEAR OF CONFLICT。Ver 6.04A は ADJUST の代わりに REDUCE CLIMB / REDUCE DESCENT（FCOM p.1554、p.1568–1569）。試験は TCAS TEST OK / TCAS TEST FAIL（ATA34_2 p.50）。目安の上昇降下率は 1,500 fpm、INCREASE で 2,500 fpm（ATA34_2 p.49–50）。

### 3.11 気象レーダー

- 109 のパネル（FCOM p.1221–1222 (11.10.15–16)）：GAIN（CAL = 較正値）、SYS L/R、MODE（TEST、WX、WX+T、MAP）、TILT ±15°、GND CLTR SPRS。WX+T の乱気流は 40 nm 以下。TEST は送信せずに試験し、WXR 選択中の ND に試験パターンを出す。
- 570 のパネル（3D の型。FCOM p.1223–1224 (11.10.17–18)）：左右別の TILT と MAP GAIN（MAP だけに効く）、LR/T・RR/T（R/T 選択）、左右別のモードスイッチ TFR（反対側の表示を選ぶ。両側同時で TEST）、WX と WX+T（ゲイン自動）、MAP、GCS。WX+T でレンジを 40 nm より大きくすると WX に変わる。TEST は地上で 12 秒の PWS 試験（PWS は 405/570 だけ）。
- EFIS の WXR スイッチは選択中の R/T を入れ、MAP/MAP CTR/VOR/APP に表示する。WXR FAIL 表示中に押すと消す（FCOM p.1040）。640 nm 選択時 R/T は 320 nm で動く（ATA34_1 p.238）。TCAS と WXR は同時表示できる（FCOM p.1583 (15.20.37)）。
- ND：エコーは緑・琥珀・赤・マゼンタ（乱気流）。注記はモード、ゲイン、チルト。故障は WXR FAIL と原因（RT、ANT、CONT、ATT、WEAK）、WXR RANGE DISAGREE、MAP/WXR RANGE DISAGREE、RSTR INOP（FCOM p.1031 (10.10.69)、p.1151・p.1155、ATA34_1 p.244–250）。

### 3.12 EICAS メッセージ

「現状」：○ = 条件どおり出る、△ = 出るが条件が違う、× = 警報モジュールの表に定義だけ、− = 表にも無い。

| メッセージ | レベル | 条件 | 根拠 | 現状 |
|---|---|---|---|---|
| >OVERSPEED | Warning（siren） | Vmo/Mmo 超過。下回るまで表示 | FCOM p.1605 (15.30.3)、p.1557 (15.20.11) | △ NAV-02 |
| >ALTITUDE ALERT | Caution（beeper） | MCP 選択高度から 300 ft を超えて逸脱 | FCOM p.1605、p.1559 | × |
| ALT DISAGREE | Caution（beeper） | 両席の未補正高度の差 > 200 ft。5 s 継続まで抑制 | FCOM p.1197 (10.50.1) | × |
| IAS DISAGREE | Caution（beeper） | 両席の速度差 ≥ 5 kt。5 s 継続まで抑制 | FCOM p.1198 (10.50.2) | × |
| >BARO DISAGREE | Advisory | 両席の気圧設定の不一致が 1 分超 | FCOM p.1198 | ○（B747.60.xt.fltInst02.lua:3141-3195） |
| >SOURCE SEL ADC / EIU / F/D / IRS / NAV | Advisory | 両席の表示が同じ ADC / EIU / FCC / IRU / FMC を参照 | FCOM p.1197 | × |
| >SNGL SOURCE RA | Advisory | 両席が同じ RA を参照 | FCOM p.1197 | × |
| >ATTITUDE | Caution（beeper） | 両席が選んだ IRS の姿勢差 ≥ 3° | FCOM p.1197 | × |
| >HEADING / >TRACK | Advisory | 表示 heading の差 ≥ 4° / 選択 track の差 ≥ 6° | FCOM p.1198 | × |
| >AOA RIGHT | Advisory | 右 AOA 故障（109・405） | FCOM p.1198 | △ NAV-07 |
| >EIU LEFT | Advisory | 左 EIU 故障。飛行中は抑制 | FCOM p.1199 (10.50.3) | × |
| HEAT P/S CAPT, F/O, L AUX, R AUX | Advisory | probe heater の電流なし（ATA 30 と共有） | FCOM p.635 (3.30.1) | CAPT/F/O ○、AUX × |
| VMO GEAR DOWN / VMO SPARE ENGINE | Memo | 電子機器室で dispatch 設定 | FCOM p.1557 | × |
| IRS CENTER, LEFT, RIGHT | Advisory | IRU 故障 | FCOM p.1429 (11.60.1) | ×（表は CENTRE） |
| >IRS AC / >IRS DC CENTER, LEFT, RIGHT | Advisory | IRU の AC 電源喪失 / backup DC 喪失 | FCOM p.1429 | × |
| IRS MOTION | Advisory | アライン中の過大な動き | FCOM p.1430 (11.60.2) | △ NAV-22 |
| IRS ALIGN MODE C, L, R | Memo | IRU が align モード。全 IRU が NAV で消える。電源投入の 12 秒後に出る | FCOM p.1430、ATA34_2 p.338 | △ NAV-16 |
| >GPS / >GPS LEFT, RIGHT | Advisory | GPS 2 台故障 / センサー故障 | FCOM p.1429 | × |
| ILS ANTENNA | Caution（beeper） | GS か LOC のアンテナが切り替わらない | FCOM p.1429 | × |
| >SNGL SOURCE ILS | Caution（beeper） | 両席が同じ LOC/GS 受信機を参照 | FCOM p.1430 | × |
| >ALT CALLOUTS | Advisory | 進入中の高度 voice（405/570 は minimums も）が出ない | FCOM p.1604 (15.30.2) | × |
| GND PROX SYS | Advisory | GPWS 警報が出ない可能性（GPWC 故障、または override + 速度条件） | FCOM p.1604、p.1538 | × |
| >TERR OVRD / TERR POS | Advisory | TERR OVRD が OVRD / GPS 故障で look-ahead 不能（405/570） | FCOM p.1604–1605 | × |
| WINDSHEAR SYS | Advisory | windshear 警報が出ない可能性 | FCOM p.1605 | ×（表は >WINDSHEAR SYS） |
| >TRANSPONDER L, R | Advisory | トランスポンダ故障 | FCOM p.1430 | × |
| >TCAS OFF | Advisory | モードが TA・TA/RA 以外。離陸は地上〜400 ft RA、進入は 400 ft RA 以下〜復行 400 ft で抑止 | FCOM p.1605、p.1593、p.1601 | △ NAV-76 |
| >TCAS RA CAPTAIN, F/O | Advisory | その側の PFD に RA ガイダンスを出せない | FCOM p.1605、p.1570 | ×（表は RA CAPT。設定はコメントアウト） |
| >TCAS SYSTEM | Advisory | TCAS 故障（両 ND に TCAS FAIL、音声なし） | FCOM p.1605、p.1570 | × |

- STATUS（整備向け。乗員操作には不要）：P/S XFR VLV、ALT ALERT SYS（ATA34_1 p.58・p.194）、ILS L/C/R・G/S ANTENNA・LOC ANTENNA（ATA34_1 p.478）、IRS AC/DC/IRS（ATA34_2 p.332）、RADIO ALT L/C/R、GND PROX SYS・WINDSHEAR REAC・TERR SYS（ATA34_2 p.98–99・p.221・p.238–239）、ATC L/R（ATA34_1 p.644）、TCAS SYSTEM（ATA34_2 p.66）。表にあるのは ALT ALERT SYS（advisory 扱い）だけ。DME 故障の status 名は資料に記載なし（ATA34_1 p.568）。E&M はトランスポンダ故障を >ATC L/R と書く（ATA34_1 p.644）が、FCOM の名前に従う。
- 関係する FMC（scratchpad）メッセージ：ENTER IRS POSITION、CYCLE IRS OFF-NAV、IRS POS/ORIGIN DISAGREE、SET CLOCK TO UTC TIME（GPS UTC と時計の差 12 秒超）（FCOM p.1431–1434）、ILS TUNE INHIBITED - MCP、NAV INVALID-TUNE AAA、RW/ILS FREQ ERROR・CRS ERROR（FCOM p.1432–1434）。

## 4. 内部ロジック

### 4.1 ADC

- 計算（ATA34_1 p.138–152 (34-12)）：Pt と Ps から CAS・Mach、Ps に AOA を使う SSEC。高度変化率は気圧高度の変化率。TAT は probe 値と Mach、SAT は TAT と Mach、TAS は Mach と SAT から。AOA は AOA 1 を使い、故障時 AOA 2。C の AOA は通常左 vane の出力 2、F/O が C を選ぶと右 vane の出力 2（p.102）。
- baro 補正高度は 4 系統：ADC L（と L として働く C）は 1・3・4 番が baro 1（Capt）、2 番が baro 2。ADC R は 2・3・4 番が baro 2、1 番が baro 1（p.146）。baro は左 EFIS CP → 左 CDU → 全 ADC（baro 1）、右 → 右 CDU（baro 2）。EFIS CP が無効なら CDU の値（p.92・p.144）。
- probe heat が切れると ADC は discrete で知らせるだけで、出力値は変えない（p.60・p.106・p.148）。故障は SSM の fail で出し、表示側が旗にする（ATA34_1 p.24 (20-11)、p.155）。
- Vmo/Mmo（ATA34_1 p.140–143、FCOM p.1557）：Vmo 365 kt、高高度側は Mmo 0.92。gear down dispatch は 270 kt / M0.73。図の折れ点は 27,490 ft と 30,841.5 ft（365 kt と M0.92 の交点は標準大気で約 28,670 ft と推定）。OVERSPEED は ADC が判定して 3 EIU（R ADC は MAWEA にも）へ出し、EICAS と level A warning（p.108）。フラップ・脚の placard 速度は OVERSPEED の条件に入らない（FCOM p.1557 の条件は Vmo/Mmo だけ）。
- source select relay（ATA34_1 p.98–114、図 p.99）
  - Capt の AIR DATA スイッチの discrete は左 ATC・左 IRU・左 FMC・3 EIU・MAWEA へ、F/O は右側の同じ系統へ（p.98）。
  - Capt が C：Capt relay が Capt 側の 4 バスを C ADC にする。F/O が C：F/O relay が C ADC を R の代替に組み替える（program pin、SDI、baro の割り当て、AOA と HEAT ON の入力、pitot/static valve を F/O pitot・AUX 2 static へ）（p.100・p.104・p.106・p.151）。
  - 片方の relay の電源はもう片方の非 C 接点を通るので、両席同時に C にはできない。先に選んだ側がラッチする（p.98・p.100）。valve は 2 コイルのラッチ式で、位置を EIU へ出し、スイッチと不一致なら P/S XFR VLV（p.58）。
  - 出力の配分（p.111・p.113 の表）：EIU は 3 ADC を直接受ける。Capt relay（L か C）は FCC L・C、YDM、SRM、FCU、CPC、MAWEA、FMC、IRU、EEC 1–4、ATC、GPWC へ。F/O relay（R か C）は FCC R など右側へ。つまり FCC L・C は Capt 側 ADC、FCC R は F/O 側 ADC を使う。

### 4.2 Altitude alert（crew alerting card、ATA34_1 p.183–196 (34-16)）

- 入力：左バス（L か C ADC）と右バス（R か C ADC）の baro 補正高度、Capt の AIR DATA discrete、MCP の選択高度と valid、FCC in command、G/S capture、脚 down & locked（PSEU）、landing flaps（FCU）、parking brake。
- バス選択：L か C の FCC が in command なら左、R なら右。in command が無いか複数なら、Capt スイッチが L/C で左、R で右（p.186・p.190）。
- 判定：300 ≤ |偏差| ≤ 900 ft で advise（接近の白枠）。|偏差| < 300 で capture し alert を arm。arm 後に 300 ≤ |偏差| ≤ 900 で alert。900 ft を超えて離れるか選択高度が変わるとリセット。300 ft 以内に戻ると alert 解除（p.183–184・p.190–191）。
- inhibit：G/S capture、脚 down & locked かつ landing flaps、選択高度の変更中（rate detector）。地上で parking brake set なら inhibit を無効にする（試験用）（p.184・p.191–192、FCOM p.1559）。
- 出力：advise/alert を 3 EIU と aural へ。aural は level B（0.8 s に 4 回のビープ）（p.194）。master caution は両席のスイッチで消える（p.180）。

### 4.3 disagree とソースメッセージ

- 閾値と遅延は §3.12（FCOM p.1197–1198）。ALT DISAGREE は未補正高度の比較なので、気圧設定の違いでは出ない（文言からの解釈）。
- relay の interlock で両席 C はできないので、>SOURCE SEL ADC が出るのは実際には Capt が R か F/O が L を選んだとき（推定）。

### 4.4 スタンバイ計器（ATA34_2 p.244–252、ATA34_1 p.78・p.80）

- standby attitude：電源投入で自動 erect（3°/分）。30 s 回してから cage ノブを数秒引くと 0° に戻る。ロータ 18,000 rpm、停止まで約 9 分。ジャイロ電源の異常で GYRO 旗。
- standby ASI・altimeter は空圧の機械式。altimeter は vibrator（28V DC）が無いと固着して誤指示。

### 4.5 IRS

- モード（ATA34_2 p.335–338 (34-21)、FCOM p.1227 (11.20.3)）
  - OFF→ALIGN か NAV でアライン開始（局所鉛直と真北、姿勢・速度・高度（ADC から）・位置（FMC から）の初期化）。NAV 位置なら完了で自動的に NAV へ、ALIGN 位置なら NAV を選ぶまで align のまま。
  - 所要約 10 分。緯度による差は資料に記載なし。高緯度（70°12′ 超 78°15′ 未満）は OFF→ALIGN で最低 17 分置いてから位置を入れて NAV（FCOM p.194 (SP.11.4)）。
  - 完了には位置入力が要る（駐機中のみ）。入力は左右 CDU から FMC 経由（L FMC が無効なら R）（ATA34_2 p.304・p.340）。全 IRU が NAV に入るとアライン完了で SET IRS POS は空白になる。
- 位置の検査（ATA34_2 p.342–348）
  - 初回の入力は IRU が記憶する最後の位置と比べ、緯度か経度が 1° 以上違えば ENTER IRS POSITION と MSG 灯。直すか同じ値を再入力すれば受け付ける。
  - 10 分の終わりに IRU が求めた緯度と入力緯度を比べる（許容差は資料に記載なし）。外れれば ENTER IRS POSITION。正しい緯度を 2 回入れても外れれば IRU 故障（IRS L/C/R）で NAV に入らない。OFF で 30 秒置いてやり直す。
  - 10 分たっても位置が未入力なら ENTER IRS POSITION。
- 動き：align 中に動くとアラインを止め、memo を消して IRS MOTION。ATA は動きが止まって 30 秒後まで表示し、アラインを自動で再開する（ATA34_2 p.350）。FCOM は止まってから約 10 分で完了とする（FCOM p.1227）。
- NAV から出すとアラインを失う。ただし NAV→ALIGN は再アライン（FCOM p.1227）。前回のフルアラインから次の到着まで 18 時間を超えるならフルアライン（FCOM p.194）。
- fast realignment（FCOM p.1227・p.194、ATA34_2 p.352）：駐機中に ALIGN →（推奨）位置入力 → NAV で約 30 秒。track・GS・姿勢の誤差を除き、位置を更新する。ALIGN に置いたままなら速度を 0 にして誤差を直し続ける。位置の比較は緯度 1/2°・経度 1° 以内で、再入力でも外れれば CYCLE IRS OFF-NAV。
- ATT（ATA34_2 p.336・p.354、FCOM p.1216・p.1227–1228・p.1286）：NAV 故障か飛行中の電源喪失のときに使う。約 30 秒（ATA は 20–30 秒）水平を取り直し、その間 IRS ALIGN MODE。飛行中は一定速度・水平飛行が要る。出力は姿勢・角速度・方位・加速度・V/S で、位置と GS は出さない。方位は SET HDG で初期化（ドリフト量は資料に記載なし）。ATT はセレクターに関係なく OFF までラッチし、飛行中に失った NAV はその飛行では戻らない。
- 方位：IRU は真方位を求め、位置の変化表から磁方位も出す（ATA34_2 p.336）。高緯度では自動で真方位（FCOM p.1242）。
- 電源（ATA34_2 p.272–275・p.286–287・p.362–363、FCOM p.1217・p.1228・p.1429）
  - AC を失うと自動で DC（APU hot battery bus）へ移り >IRS AC。DC 側を失うと >IRS DC。両方失った IRU はアラインを失い、飛行中なら以後 ATT だけ。
  - C IRU：AC を失い、さらに DC bus 3 も失うと R7768 が消勢して R7475 の 5 分タイマーが動き（OFF 以外のモード）、5 分後に DC を切る（電池負荷のため）。
  - ON BAT 灯と地上員呼び出しホーン：地上（R733）で、いずれかの IRU の DC 動作が 10 秒続き（R7681）、かつ ground service bus が無電源（R7680 消勢）。FCOM は「バックアップ電源で動作中」としか書かない（p.1217）。点灯条件は ATA に従い、飛行中は灯が点かず >IRS AC だけと読む（推定）。
- ソース選択の副作用（ATA34_2 p.278・p.296–300）：機長の IRS select は左 PFD/ND（EIU への discrete）、左ブレーキチャンネル、WXR、失速警報の IRU を、F/O 側は右側と C IRU の ADC 入力ポートを切り替える。ADC 入力は L IRU = 機長選択 ADC、R IRU = F/O 選択 ADC、C IRU = F/O の IRS select が L か C なら F/O の ADC、R なら機長の ADC。
- critical fault は discrete で EIU へ送り IRS L/C/R を出す。前面のフォールトボールは電源の入れ直しで消える（ATA34_2 p.288・p.292・p.360）。

### 4.6 GPS（ATA34_2 p.378–418 (34-58)、FCOM p.1225・p.1286）

- 左右独立、同調は自動。モードは self-test → 初期化（約 30 秒）→ 捕捉（4 衛星以上）→ 航法 → 高度補助（3 衛星）→ 補助（30 秒未満の受信不良）→ 故障（p.411–412）。
- 初回測位は IRU の位置があれば電源投入から 75 秒以内、無ければ最大 10 分（p.378・p.411）。L GPS は L IRU（無効なら C）、R GPS は R IRU（無効なら C）を使う（p.386）。
- 出力は位置、時刻、HFOM、HIL など。RAIM は 5 衛星で完全性監視、6 衛星で故障衛星の除外。FMC は HIL を見て GPS を使うか決める（p.386・p.416）。
- POS INIT の GPS POS は L GPS が有効なら L、無ければ R、どちらも無効なら空白。UTC は L GPS → R GPS → 機長の時計（MAN）→ F/O の時計（p.394、FCOM p.1286）。乗員は POS REF 2/3 で GPS 更新を止められる（FCOM p.1225・p.1240）。

### 4.7 無線航法受信機と同調

- 同調の経路：CDU の入力は両 FMC へ。FMC master switch で決まる master FMC が全受信機の port B へ同調語を送る（ATA34_1 p.284 (34-57)、p.332 (34-51)、p.440 (34-31)、p.526・p.557 (34-55)）。選択 FMC が故障すると受信機は最後の有効周波数を保ち、master switch を回すと autotune が続く（p.350・p.440・p.460）。空中で master FMC 故障、地上で両 FMC 故障のとき、CDU が source select discrete を出し、受信機は port A で自側 CDU（ILS C は中央 CDU）から直接同調される（p.302・p.332・p.354・p.464・p.542）。
- VOR/DME の autotune：通常は選択 FMC が VOR 2 台を autotune（A）。autotune 中はコースを選べない（p.350）。手動入力で autotune を取り消し M、手動のときだけコースを入れられる（p.352）。FMC は位置更新用に VOR と同居 DME を同調し、REF NAV DATA で局を禁止できる。2 局とも手動にすると他の局を位置更新に使えない（FCOM p.1230 (11.20.6)）。
- DME：5 チャンネル。ch 1–4 を位置更新に使い、ch 3–4 は手動でも使える。手動 DME は FMC の DME 同調を妨げない。ch 5 は選択 ILS 用（FCOM p.1228）。E&M は 252 チャンネルを走査して近い 15 局を FMC へ渡す（ATA34_1 p.539）。DME の音声 ID は APP mode なら ILS と、ほかは VOR と対（1350 Hz、VOR/ILS ID 3〜4 回に 1 回）（p.528・p.544）。表示用の DME は常に自側 VOR/ILS と対（p.524）。
- ILS の autotune と禁止（FCOM p.1229 (11.20.5)、p.1305 (11.40.29)、ATA34_1 p.440・p.450・p.460・p.494）
  - autotune は飛行計画に進入があるときだけ。出発・折り返しは手動だけ。時期は §3.6。
  - 離陸後 10 分は ILS autotune を禁止。活性経路で新しい進入を選んで実行すれば 10 分以内でも同調し、目的地滑走路の変更で禁止は解除。2 回目以降の離陸には適用しない。手動同調中も autotune しない。
  - 同調禁止（autotune も手動も）：AP engage で LOC か GS capture、FD だけで capture かつ RA 500 ft 未満、地上で LOC alive・機首が LOC フロントコースの 45° 以内・GS 40 kt 超。解除は TOGA、または AP を外して両 FD OFF。実体は FCC から ILS 受信機への tune/test inhibit discrete。禁止中の操作で ILS TUNE INHIBITED - MCP。
  - ILS 受信機は偏位を 2 つのプロセッサーで別々に計算し、合わなければ invalid（p.494）。
- アンテナ切替（ATA34_1 p.436・p.438・p.482–492）：LOC は空中で FCC が APP/LOC でないとき尾翼の VOR アンテナ、APP/LOC で機首の LOC アンテナ。GS は前脚が down & locked でないとき capture アンテナ、down & locked で track アンテナ。切り替わらなければ LOC/G/S ANTENNA（status）、2 個以上で ILS ANTENNA。電源は図と本文で食い違う（図：L = main battery bus、C = DC bus 1、R = DC bus 2。本文：LOC スイッチ 3 個とも main battery bus）。
- PFD の過大偏位警告（scale 琥珀、指針 4 Hz 点滅。ATA34_1 p.468、FCOM p.987）：GS は APP 作動中・RA 100–500 ft で約 5/8 dot 超。LOC は APP 作動中・RA 0–500 ft で約 1/4 dot 超が 1 s 以上。LOC capture fail は LNAV で LOC arm のまま RA 0–950 ft、1,050 ft に戻るか capture で解除。
- ND の ILS 源は表示器が、アンテナ状態・偏位の状態・EIU source selector から決める（ATA34_1 p.474）。
- ADF：ANT では方位が NCD で指針が消える。BFO は 1020 Hz を混ぜる（p.312 (34-57)）。MB：400 Hz = OM、1300 Hz = MM、3000 Hz = IM（p.413 (34-32)）。
- 自己試験の手順（VOR 16 s、ILS 16 s、ADF、DME。ATA34_1 p.318・p.380–382・p.502–508・p.564）は実装しなくてよい。

### 4.8 電波高度計（ATA34_2 p.88–106）

- PFD の RA ソース：EIU 選択で優先順位が変わり、表示中の RA が故障すると次へ。機長 L/AUTO = L→C→R、C = C→L→R、R = R→L→C。F/O R/AUTO = R→C→L、C = C→R→L、L = L→R→C（p.88–89）。
- GPWC の RA：L が C か R と 500 ft 以内なら L、だめなら C が R と 500 ft 以内なら C、両方だめなら L（p.122 (34-46)）。GPWC への入力を p.70 は「L と R だけ」、p.122 は「3 台」と書く。詳しい p.122 に従う（推定）。
- DH alert（E&M）：DH + 75 ft の上昇通過で arm、DH の降下通過で発報、RST・DH + 75 ft の上昇・接地でリセット（p.95）。自己試験中は 40 ft、autoland 中は FCC が試験を禁止（p.106）。

### 4.9 GPWS・windshear（ATA34_2 p.122–206 (34-46)、FCOM p.1570–1585）

- 空地判定：地上→空中は air/gnd relay が air かつ RA ≥ 5 ft（relay が誤って ground のときは CAS ≥ 90 kt かつ RA ≥ 5 ft）。空中→地上は CAS ≤ 60 kt かつ RA ≤ 1 ft。地上では annunciation を禁止（p.127・p.205–206）。
- 入力：垂直速度は L IRU、無ければ ADC。CAS・baro は L ADC。G/S・LOC・滑走路方位は L ILS。磁方位は L FMC（故障で L IRU）。flaps は FCU の「25 以上」、gear は gear lever。AOA と stick shaker AOA は L stall warning card（故障で R）（p.122–123・p.147・p.157・p.189）。入力が損なわれるとそのモードだけ禁止（p.213、FCOM p.1581）。envelope modulation（約 100 地点で閾値を緩める）は省略可（p.200–202）。
- Mode 1（過大降下率）：上限 2,450 ft RA（降下率 ≥ 5,007 fpm）、下限 30 ft（998 fpm 未満では出ない）。G/S より上では境界を最大 300 fpm 緩める（2 dot 上で 300 fpm）。SINK RATE（反復）、続けば PULL UP。warning 曲線の数値は資料に記載なし（p.144）。
- Mode 2（過大接近率、closure = RA の変化率。p.151–157）
  - 2A（flaps ≤ 20 かつ G/S 偏位 > 2 dot）：CAS ≥ 310 kt・closure ≥ 9,800 fpm で 2,450 ft、CAS ≤ 220 kt・≥ 5,733 fpm で 1,650 ft、下限 30 ft。TERRAIN 2 回の後、続けば PULL UP。warning が 3 s 超続いた後に降下が止まり gear up なら、TERRAIN を止めて GND PROX 灯だけを 300 ft 上昇か 45 s か gear down まで残す。
  - 2B（flaps 25/30、または G/S 偏位 ≤ 2 dot）：closure ≥ 3,000 fpm で 789 ft、2,253 fpm で 200 ft。下限は flaps down で降下率 400 fpm 以下 200 ft〜1,000 fpm 以上 600 ft、flaps up で 30 ft。gear・flaps down なら TERRAIN の反復だけ。
- Mode 3（離陸・復行後の高度損失、landing config でない）：閾値は高度損失が RA の約 10–20%。上限は 190 kt 未満で約 700 ft、250 kt 超で約 1,350 ft。3B が 4A 閾値に達すると mode 4 へ（p.161–166）。
- Mode 4（landing config でない地表接近）：4A（gear up）500 ft（190 kt まで）、4B（gear down・flaps up）245 ft（159 kt まで）。速いと 250 kt で 1,000 ft まで増える。過大 closure 検出後 60 s は上限 800 ft。下限 30 ft。flaps down なら 4A は全速度 500 ft。4B 境界を gear・flaps down で通過すると mode 3 に戻る（p.166・p.168–172）。aural は TOO LOW GEAR（低速・gear up）/ TOO LOW FLAPS（低速・flaps up）/ TOO LOW TERRAIN（高速）（FCOM p.1577）。
- Mode 5（G/S 下方偏位）：1,000 ft RA 未満、gear down、500 ft より上で LOC 捕捉（2 dot 以内）で arm。1,000〜30 ft。1.3 dot 超で半音量、300 ft 未満かつ 2 dot 超で通常音量。back course（選択滑走路方位と track の差 > 90°）では禁止（p.174–178）。
- Mode 6：各 callout は 1 回だけで、1,000 ft 超への上昇でリセット。音量は他モードの 1/4。bank angle は L IRU の roll。E&M は 150 ft 以上で 40°、30 ft で 10°（間は線形）、20% 増すごとに反復（p.180–184）。FCOM 405 は 35°・40°・45°（FCOM p.1577）。
- Mode 7（reactive windshear）：1,500 ft RA 未満の離陸（rotation から）と最終進入。垂直・水平成分を合成し、flap 位置で決まる閾値と比べる（数値は資料に記載なし）。siren + WINDSHEAR 反復、PFD 赤 WINDSHEAR、master WARNING。windshear が続き、かつ AOA が stick shaker AOA の 4° 以内の間続き、最低 5 s。発報中は他の GPWS モードを禁止（p.186–190、FCOM p.1581）。
- look-ahead：GPS（無効時 IRS）位置・track・GS・高度で衝突までの時間を推定。caution 40–60 s、warning 20–30 s（E&M は約 60 s / 30 s。FCOM に従う）。FMC の経路は見ない。警報時、TERR 未選択の ND（MAP/MAP CTR/VOR/APP）に自動表示（FCOM p.1571–1573・p.1585、ATA34_2 p.193–194）。
- TCF：滑走路から 4 NM で 400 ft AGL、12 NM まで 400 ft、15 NM 以遠 700 ft の床。下回ると TOO LOW TERRAIN（高度 20% 減るごとに反復）、床の上に戻るまで GND PROX 灯。地上、離陸後 20 s 未満、30 ft RA 未満で禁止。landing config でも出る（p.197–199）。
- 優先と相互禁止（FCOM p.1582–1583、ATA34_2 p.124・p.130）：immediate windshear は TCAS の全警報と他の GPWS 警報、新しい TCAS・terrain の自動表示を禁止する。GPWS warning 中は TCAS が RA を止めて TA ONLY（RA 中なら TA に落とす）、warning が消えると TA/RA に戻る。warning の voice は新しい caution の voice を禁止する。モード間の voice 優先の全表は資料に記載なし（明記は mode 7 が最優先、3B > 3A だけ）。

### 4.10 トランスポンダ（ATA34_1 p.574–598・p.632–633 (34-53)）

- 選ばれた側だけが動き、STBY では両方止まる。Mode A（コード）、Mode C（高度）、Mode S（24 bit アドレス、毎秒 1 回の squitter）。地上では Mode A/C を返さない。故障は ATC FAIL 灯と 3 EIU へ。
- 高度は標準気圧高度。各トランスポンダは「L か C ADC」と「R か C ADC」の 2 バスを受け、ADC source select で切り替わる（p.586・p.632）。TCAS とは ARINC 429 で、ATC → TCAS は最大対気速度・気圧高度・アドレス・協調データ、TCAS → ATC はモード状態と協調データ（p.588、ATA34_2 p.21）。ATC・TCAS・DME は suppression 線で送信を止め合う（p.592・p.636）。

### 4.11 TCAS（ATA34_2 p.17–56 (34-45)、FCOM p.1560–1601）

- モード：STBY は送信・監視・追跡を止める。TA は RA を TA として出す。TA/RA は両方（ATA34_2 p.26）。30 nm 以内の 45 機を追跡し、近い 30 機を表示（p.24）。RA は相手が高度を報告しているときだけ（p.43）。RA は CPA の約 20–30 秒前、TA は約 25–45 秒前（FCOM p.1560–1561）。
- 入力：L/R RA（感度と抑止。1 台で動く）、F/O 選択 IRU の磁方位（ND の平滑化だけ）、GPWC からの windshear・GPWS warning・GPWS alert の discrete、脚レバー、air/ground、EIU からの RA 表示可否、高度上限 48,000 ft（CLIMB 系を出さない）（p.17–18・p.55–56）。
- パラメータ（ATA34_2 p.39 の表）

| 自機高度 | RA ≤ 500 ft | RA 500–2,500 ft | 気圧 ≤ 10,000 ft | 10,000–20,000 | 20,000–30,000 | > 30,000 |
|---|---|---|---|---|---|---|
| 感度レベル | 2 | 4 | 5 | 6 | 7 | 7 |
| RA tau（秒） | なし | 20 | 25 | 30 | 35 | 35 |
| TA tau（秒） | 20 | 35 | 40 | 45 | 45 | 45 |
| RA 相対高度（ft） | なし | 750 | 750 | 750 | 850 | 930 |
| DMOD（nm） | なし | 0.1 | 0.3 | 1.0 | 1.0 | 1.0 |
| RA 最小垂直間隔（ft） | なし | 400 | 400 | 500 | 640 | 740 |

- TA の相対高度は全域 1,200 ft。
- 高度による抑止（109、Ver 7.0）：離陸時は地上から TA 音声を約 500 ft RA まで、全 RA を約 1,000 ft まで（自動で TA ONLY、ND に TA ONLY）、DESCEND RA を約 1,100 ft まで抑止（FCOM p.1593 (15.20.47)）。着陸時は INCREASE DESCENT RA が約 1,500 ft 以下、DESCEND RA が約 1,100 ft 以下、全 RA が約 1,000 ft 以下（TA ONLY）、TA 音声が約 500 ft 以下で抑止。同じ高度での復行で解除（FCOM p.1600–1601）。Ver 6.04A は TA 音声も約 1,000 ft（FCOM p.1596）。E&M の「RA は 500 ft 未満、音声は 400 ft 未満」（ATA34_2 p.43）とは違うが FCOM に従う。
- GPWS・windshear との関係は §4.9 の末尾。両 PFD が RA を出せないとき、TA/RA なら ND に TCAS FAIL（ATA34_2 p.18）。

### 4.12 気象レーダー（ATA34_1 p.212–270 (34-43)）

- EFIS パネルの WXR スイッチはモーメンタリで、EFIS パネル側でラッチする。どちらからでも選択中の R/T が入り、表示の許可は自側の ND だけ。EFIS パネル故障で OFF、復帰で前の状態（p.253–254）。
- 姿勢は同じ側の IRU、予備は C IRU（IRS source select で切替）（p.242・p.263）。FCOM は SYS L = L と C、R = R と C の IRU（FCOM p.1222）。
- アンテナ走査 ±90°、安定化 ±40°（チルト ±15° を含む）（p.231）。ゲインは TEST・WX・WX+T で自動、WX(VAR) と MAP は手動（p.221・p.260）。乱気流は E&M が 50 nm 以下、FCOM が 40 nm 以下。FCOM に従う。
- 故障の優先：WEAK は ATT より優先し、WEAK・ATT の間は表示を続ける。FAIL ではデータを消す。EFIS パネルと R/T のレンジが違えば WXR RANGE DISAGREE、FMC も違えば MAP/WXR RANGE DISAGREE。IDU が 110°C でラスターを 30 秒後に消し RSTR INOP（p.246・p.248・p.250）。

## 5. 他系統とのつながり

- 電源（ATA 24）：§2.1 のとおり、ADC・EIU・VOR L・ILS L・MKR・GPS L・ATC L は standby / transfer bus、IRU の backup は APU hot battery bus、C IRU の 5 分は DC bus 3、ON BAT は ground service bus、standby attitude は main battery bus。いまの電源モジュールには transfer bus・standby bus・ground service bus の実体が無く、表示電源の flag だけ（B747.03.xt.electrical.lua:545-548）。受信機は X-Plane の avionics 電源だけで動く（xtlua/scripts/Avionics/Avionics.lua:29-38）。系統ごとの電源依存は ATA-24 の bus モデルが先に要る。
- AFDS（ATA 22）：ILS の偏位は自側 FCC へ。FCC は tune/test inhibit と VOR/LOC アンテナスイッチを出す（ATA34_1 p.436・p.446・p.450）。FCC L・C は Capt 側 ADC、R は F/O 側 ADC（§4.1）。altitude alert は FCC in command と G/S capture を使う。RA は autoland の進入ロジックへ。シムの AFDS は `nav_obs_deg_mag_pilot[0]` を LOC コースとし（B747.70.xt.autopilot.lua:2419・2519）、`laminar/B747/autopilot/ils_dots` で APP/LOC の arm を許す（同 2397・2430）。yaw damper の INOP 灯は最初の IRU がアラインするまで点く（FCOM p.107 (NP.21.13)）。
- FMC（ATA 34-61）：FMC master の選択、位置更新（GPS、DME/DME、VOR/DME、LOC）、局の ID 照合、POS REF ページ。IRS は FMC 位置の基準で、最低 1 台要る（FCOM p.1240 (11.31.6)）。同調状態は文字列 dataref `laminar/B747/radio/tuningmodes`（初期値 "AAAMM"）と `laminar/B747/radio/ilsData`（JSON）を FMS と autopilot が共有している（init/scripts/B747.68.fms/B747.68.fms.lua:21、B747.68.xt.fms.lua:193、B744.fms.pages.lua:389、B747.70.xt.autopilot.lua:352・1554・1741）。
- 警報（ATA 31）：EICAS メッセージは `laminar/B747/CAS/*_status` の index（§3.12、B747.87.xt.warning.lua）。GPWS・windshear・TCAS の voice の優先は警報系と GPWS の両方にまたがる。master WARNING はいま EICAS warning からだけ点く（B747.87.xt.warning.lua:818-833）。
- 脚・空地（ATA 32）：GS アンテナ切替、altitude alert の inhibit、GPWS の gear 条件、TCAS の脚レバー、トランスポンダの air/ground、IRS ON BAT の空地。
- 操縦系統（ATA 27）：FCU の flap 信号（GPWS、altitude alert）、stall warning の AOA（GPWS mode 7）、CONFIG GEAR と CONFIG GR OVRD（B747.45.xt.fltCtrls.lua:1030-1047）。
- 防氷（ATA 30）：probe heater の電流監視 → HEAT メッセージと ADC の HEAT ON discrete（B747.50.xt.antiice.lua:505-534）。
- ブレーキ：Capt 側で選んだ IRU が autobrake の基準（FCOM p.1044）。
- air data の現在の利用者：EEC（B747.42.xt.EEC.lua:53・194・213-215）、flap load relief（B747.45.xt.fltCtrls.lua:131・829-838）、油圧モデル（B747.19.xt.hydraulicsmodel.lua:76・167）、警報（B747.87.xt.warning.lua:570）、FDR。どれも X-Plane の pilot 系を直接読む。RA は `laminar/B747/efis/radio_altitude` を fltMgmt（B747.30.xt.fltMgmt.lua:422）と EEC（B747.42.xt.EEC.lua:319）が使い、AFDS（B747.70.xt.autopilot.lua:244-245）と CONFIG GEAR（B747.45.xt.fltCtrls.lua:1039）は X-Plane の RA を直接読む。

## 6. 実装上の注意

- X-Plane が持つもので土台にできるもの
  - pitot-static と ADC：pilot / copilot / standby の 3 系統と故障（`rel_pitot`・`rel_pitot2`・`rel_pitot_stby`、`rel_static*`、`rel_adc_comp`・`rel_adc_comp_2`、`rel_AOA`（pilot）・`rel_cop_AOA`（copilot））、standby 用の `airspeed_kts_stby`・`altitude_ft_stby`・`barometer_setting_in_hg_stby` と `barometer_stby_up/down`。案：ADC L ← pilot 系、ADC R ← copilot 系、ADC C は Lua で合成、standby ← stby 系（推定の設計案）。
  - IRS：AHARS 1/2（パネルが直接読む）、故障 `rel_g_arthorz`・`rel_lrn1/2`・`rel_gps`/`rel_gps2`。ATT の方位には `sim/cockpit/gyros/gyr_free_slaved` と `dg_drift_ahars_deg`（書込可）が使えそう（推定、シムで確認）。
  - 無線：NAV1–NAV6（12 要素配列）、ADF1/2、受信機ごとの DME（ch 5 相当の ILS DME も同時に出せる）。`nav_bearing_deg_mag` は「局への方位」なので radial はこれ + 180°。ADF の ANT/BFO は `adf1_power` の 1 = antenna、3 = tone で表せる（推定）。周波数は整数 kHz なので 0.5 kHz は表せない。
  - TCAS：X-Plane 12 の TCAS II（`transponder_mode` 6 = TA only、7 = TA/RA、`sim/cockpit2/tcas/indicators/tcas_message`、`tcas_active_advisory`、`tcas_vs_bands`、`targets/threat`）。判定は X-Plane に任せ、747 固有の層（GPWS・windshear 連動、高度抑止、EICAS、ND/PFD、音声）をプラグインで足すのが速い。抑止高度が FCOM と合うかは要確認。
  - WXR：X-Plane のレーダー（左右別の `EFIS_weather_mode`・`_gain`（0.95–1.05 が較正値）・`_tilt`・`_gcs`・`_stab`・`_pws`）。描画はこれを使い続ける。
  - windshear：`sim/cockpit2/annunciators/windshear_warning_systems` を mode 7 の検出器にし、高度・フェーズ・最低 5 s・禁止の論理だけ自前にする案（推定）。
- 表示の制約（純正 acf は変えない。カスタム acf の変更は承認が要る）
  - PFD 速度は Lua の `laminar/B747/gauges/indicators/airspeed_kts_pilot/copilot` なので Lua で切り替えられる。PFD 高度は `sim/cockpit2/gauges/indicators/altitude_ft_pilot/copilot`、Mach は真値の `sim/flightmodel/misc/machno` を直接読み（747-400.acf:85995 ほか）、SPD・ALT・MACH 旗の画像も無い。高度・Mach の source 切替と ADC 旗にはパネル変更が要る。`altitude_ft_*` を Lua で書いて X-Plane に上書きされないかは未確認。
  - PFD・ND の姿勢・方位は `{pitch,roll,heading}_AHARS_*_{pilot,copilot}` を直接読む。IRU ごとの値の違いは出せず、L/C/R の違いは有効・無効（`laminar/B747/pfd/{capt,fo}/irs`）で表す。
  - X-Plane の受信機割り当て（NAV1/2 = ILS L/R、NAV3/4 = VOR L/R）はパネル定義が前提にしている（`nav_frequency_hz[2]/[3]`、`nav3/4_nav_id`、`nav_dme_distance_nm[2]/[3]`、`nav_relative_bearing_deg[2]/[3]` など）。変えない。中央 ILS が要るなら NAV5（index 4 と推定）を使う手がある（AFDS と相談）。
  - パネルは文字列 dataref を読めない。ND の autotune 時の消去などには数値 dataref が要る。
  - standby 計器と RMI は obj が dataref を読む（Cockpit_Panel.obj:32047-32456）。独立させるには obj の変更（3D は対象外なので承認）が要る。Lua だけなら「Capt と同じ値」のまま。
  - PFD の PULL UP は `sim/cockpit/warnings/annunciators/GPWS`（書込可。ただし DataRefs.txt の説明は「GPWS failed」）、WINDSHEAR は `sim/cockpit2/annunciators/windshear_warning`（読取専用）を表示条件にしている（747-400.acf:87129-87154）。自前の GPWS の出力を出すには前者に書くか、パネルを変える。
  - TCAS の ND メッセージ・シンボル 4 種・データタグ、PFD の RA 領域、GPWS の terrain 表示、LOC/GS の琥珀 scale は、いまのパネルに計器が無い。
- 音声：GPWS の callout と警報は `fmod/747-400.snd` の条件式で鳴る。X-Plane 組込みの音声は `sounds/alert/*.wav`（stall.wav 以外は無音。tcas.wav・te_climb.wav・te_descend.wav も無音）で消している。二重発声を防ぐので無音 wav は残す。TCAS の音声素材は warnings.bank にあるが .snd にイベントが無い。GPWS・TCAS を自前にするなら、出力 dataref（例：`laminar/B747/gpws/*`、名前は案）を作り .snd の条件を付け替える。.snd の変更は音声資産の扱いなので利用者の判断が要る。`747-400_custom.acf` に対応する .snd は無い。
- 時間：アラインなどは `run_after_time` の 1 回タイマーでなく、機器ごとの状態と `simDRTime` で進める（ポーズ、リプレイ、時間加速、電源断の扱いが明確になる）。機体設定 `irs_align_time`（既定 600 秒）は残してよい。
- 省略してよいもの：ARINC の語と SSM、program pin、SSEC、BIT・自己試験、drain、アンテナ切替の実体、ports/SSD の配線、Mode S のデータリンク、suppression 線、GPWS の envelope modulation、GPS の衛星モードと RAIM、DME の 252 チャンネル走査（FMC 側で航法 DB から計算すればよい）。
- 省略してはいけないもの：3 ADC と電源、relay の interlock と C の代替先、Vmo/Mmo の OVERSPEED、altitude alert の閾値と inhibit、disagree の閾値と 5 s 遅延、FCC ごとの ADC 配分、IRS の OFF/ALIGN/NAV/ATT の遷移と ATT のラッチ、位置入力の検査、fast realignment、動きの検知と自動再開、AC→DC 切替と C IRU の 5 分、ILS の同調禁止と PARK/autotune の時期、手動優先と DELETE、ident 音声の受信機対応（乗員手順で ident を確認する。FCOM p.1231 (11.20.7)）、GPWS の alert→warning の二段と mode 3/4 の切替と override 条件、G/S inhibit のラッチ、windshear の最優先と TCAS への inhibit、master WARNING、空地判定、トランスポンダのモードごとの高度報告、TCAS のモードと抑止、TFC・TA ONLY・TRAFFIC の表示。

## 7. 現状実装との比較（GAP 候補）

コードの場所：`B747.60.xt.fltInst02.lua`・`B747.30.xt.fltMgmt.lua`・`B747.70.xt.autopilot.lua`・`B747.90.xt.lighting.lua` は `plugins/xtlua_keysystems/scripts/<モジュール>/`、`B747.68.xt.fms.lua`・`B744.fms.pages.lua`・`irs/*.lua`・`activepages/*`・`refonly/*` は `plugins/xtlua_keysystems/scripts/B747.68.xt.fms/`、`B747.15.xt.com.lua`・`B747.87.xt.warning.lua`・`B747.01.xt.manipulators.lua`・`B747.45.xt.fltCtrls.lua`・`B747.50.xt.antiice.lua` は `plugins/xtlua/scripts/<モジュール>/`、`B747.61.xt.nd.lua` は `plugins/xtlua_nd/scripts/B747.61.xt.nd/`、obj は `objects/747_cockpit/`。

| ID | 種別 | 重要度 | 規模 | 内容 | 根拠 | 該当コード |
|---|---|---|---|---|---|---|
| NAV-01 | 欠落 | 高 | L | ADC が 3 台として存在しない。AIR DATA 選択器は飾り（読む側なし）で、表示と全系統が X-Plane の pilot / copilot 系を固定で使う。C ADC、relay の interlock、電源依存、ADC 故障の扱いが無い。3D ノブとコマンドは 0–1 の 2 位置で、109 の L/C/R と合わない | FCOM p.1044・p.1079、ATA34_1 p.98–114 (34-12) | B747.60.xt.fltInst02.lua:568-577・632-641・3223-3234、Cockpit_Panel.obj:31894・31937 |
| NAV-02 | バグ | 高 | S | OVERSPEED の条件が誤り。(1) Vmo の代わりにフラップ・脚の placard を含む Vmax を使い、placard 超過でも siren が鳴る。(2) 28,620 ft 以下で Mmo = 0.88 としているので、約 26,500–28,620 ft で Vmo 未満でも鳴る（例：27,000 ft・360 kt ≈ M0.88、計算による推定）。資料は Vmo 365 kt / Mmo 0.92 の 1 本 | ATA34_1 p.140–143、FCOM p.1557・p.1605 | B747.60.xt.fltInst02.lua:2946-2983・3156-3164 |
| NAV-03 | 欠落 | 高 | M | ALTITUDE ALERT が無い（表だけ）。判定、beeper、PFD の白枠・琥珀枠が無く、パネルにも枠の要素が無い。EICAS と beeper は Lua で作れ、枠はパネル変更 | FCOM p.992・p.1559・p.1605、ATA34_1 p.178–194 | B747.87.xt.warning.lua:110、747-400.acf:87470-87560 |
| NAV-04 | 欠落 | 中 | S | IAS DISAGREE（≥ 5 kt、5 s）と ALT DISAGREE（> 200 ft、5 s）が無い（表だけ）。pilot / copilot 系は別々に故障させられるので Lua で作れる | FCOM p.1197–1198 | B747.87.xt.warning.lua:109・152 |
| NAV-05 | 欠落 | 中 | M | PFD に SPD・ALT・MACH 旗が無く、Mach は真値（machno）なので ADC・pitot 故障と source 選択が効かない。パネル変更が要る | ATA34_1 p.126–130、FCOM p.999 | 747-400.acf:85995-86000 |
| NAV-06 | 挙動の誤り | 中 | S | BARO STD：STD 押しで preselect を 29.92 に上書きするので、もう一度押しても STD 前の値に戻らない（preselect を回した場合を除く） | FCOM p.1037、ATA34_1 p.135–136 | B747.60.xt.fltInst02.lua:859-871・1030-1042 |
| NAV-07 | バグ | 低 | S | >AOA RIGHT が pilot 側（左）の AOA 故障 `rel_AOA` で出る。右は `rel_cop_AOA` | FCOM p.1198、X-Plane DataRefs.txt | B747.60.xt.fltInst02.lua:163・3176-3182 |
| NAV-08 | 欠落 | 低 | S | gear down / spare engine dispatch の Vmo 曲線（270 kt / M0.73）と VMO GEAR DOWN・VMO SPARE ENGINE メモが無い（整備上の設定。省略可） | ATA34_1 p.142–143、FCOM p.1557 | B747.87.xt.warning.lua:531-532 |
| NAV-09 | バグ | 低 | S | HEAT P/S L AUX・R AUX と TAT heat が無く、HEAT L/R AOA は float の着氷率が 6 のときという成立しない条件（ATA 30 と共有） | FCOM p.635、ATA34_1 p.60・p.164・p.166 | B747.50.xt.antiice.lua:84-85・505-519、B747.87.xt.warning.lua:372-379 |
| NAV-10 | 欠落 | 中 | S | FLT DIR・EIU（左右と中央）の選択器は読む側が無い（quick start とクリック音だけ）。IRS 選択器は PFD/ND の有効旗（`pfd/{capt,fo}/irs`）をどの IRU のアライン状態で決めるかにだけ使われ、姿勢・方位の値は選択によらず AHARS 1/2。EIU AUTO の優先順、中央 EIU の EICAS 切替、IRS 選択の副作用（autobrake の IRU、C IRU の ADC ポート、WXR・失速警報の IRU）が無い | FCOM p.1043–1044・p.1529、ATA34_2 p.278・p.296–300 | B747.60.xt.fltInst02.lua:520-565・584-629・648-656、irs/irs_system.lua:209-212 |
| NAV-11 | 挙動の誤り | 中 | M | NAV 選択器をパネルが ND の基準受信機（APP の ILS L/R、VOR の VOR L/R と周波数・コース・DME・指針）の選択に流用している（Capt：0 = ILS L、1 = ILS R、2 = VOR L、3 = VOR R。F/O：2/3 = ILS L/R、0/1 = VOR）。FCOM の FMC L/R・CDU の意味が無く、通常位置（FMC L）だと VOR モードで基準 VOR の欄とコース指針が出ない側がある。F/O の centered VOR は指針とヘッダの L/R が逆。実機は ILS を EIU 選択と表示器のロジックで決め、VOR は自側（推定）。パネル変更が要る | FCOM p.1038・p.1043–1044・p.1275、ATA34_1 p.474 (34-31)・p.550 (34-55) | 747-400.acf:99323-99497・100141-100315・107005-107438（F/O）、108772-108946・109590-109764・116454-116887（Capt）。カスタム acf も同じ |
| NAV-12 | 挙動の誤り | 中 | S | FMC master 選択器が X-Plane の `autopilot_source`（NAV1/NAV2）を切り替え、パネルでは ILS L/R の DME 表示選択に使われる。A/T 解除の行はコメントアウト。FCOM は誘導指令を出す FMC の選択で、A/T 作動中の切替で A/T 解除（FMC・A/T 担当と共有） | FCOM p.1215・p.666 | B747.60.xt.fltInst02.lua:660-666、747-400.acf:86810-86827 |
| NAV-13 | 欠落 | 低 | S | >SOURCE SEL ADC/EIU/F/D/IRS/NAV、>SNGL SOURCE RA、>EIU LEFT、ALT ALERT SYS は表だけで設定箇所なし。P/S XFR VLV は表にも無い（NAV-01・NAV-10 が前提） | FCOM p.1197・p.1199、ATA34_1 p.58・p.194 | B747.87.xt.warning.lua:190・277・452-457 |
| NAV-14 | 挙動の誤り | 中 | M | standby 計器が独立していない。standby ASI = Capt の速度、standby altimeter = Capt の高度と気圧設定（standby の BARO ノブは `sim/instruments/barometer_up/down` で Capt PFD の気圧を変え、EFIS の STD でも 29.92 になる）、standby attitude = X-Plane の AHRS（GYRO 旗、battery 依存、erect、caging、APP 表示なし）。直すには obj の dataref 変更が要る | ATA34_1 p.76–80、ATA34_2 p.244–252、FCOM p.1053–1056・p.1075 | Cockpit_Panel.obj:32047・32084・32100-32102・32126-32401、747-400_cockpit.obj:23167、B747.60.xt.fltInst02.lua:2389-2392 |
| NAV-15 | 挙動の誤り | 低 | S | RMI は 109 に無い（405 だけ）が 3D にある。heading カードは X-Plane の electric gyro で、405 の「F/O の IRS 選択で右か中央の IRU」と違う。指針は VOR L/R（`nav_relative_bearing_deg[2]/[3]`）と ADF の切替 | FCOM p.1056・p.1074–1075 | Cockpit_Panel.obj:32419-32456、B747.60.xt.fltInst02.lua:2217-2233 |
| NAV-16 | 挙動の誤り | 高 | M | MSU の遷移が実機と違う。(a) ALIGN 位置では何も進まず、アラインは NAV を選んでから 600 秒。(b) NAV→ALIGN でアラインを捨てる。fast realignment（約 30 秒）ができず毎回フル。(c) 高緯度アライン（ALIGN で 17 分）ができない。(d) memo は NAV でアライン中しか出ず、600 秒で消える（位置が未入力でも） | FCOM p.1216・p.1227・p.1430・p.194、ATA34_2 p.335・p.338・p.352 | B747.30.xt.fltMgmt.lua:168-208、irs/irs_system.lua:109-126・215-235 |
| NAV-17 | 欠落 | 中 | M | 位置入力の検査が無い。11 文字以上なら何でも受け付け、値は IRU 位置に使わない（IRU 位置は真位置 + 起動時の乱数 ±0.001°）。最後の位置との 1° 比較、終了時の緯度比較と 2 回失敗での IRU 故障、再アラインの 1/2°・1° 比較が無い。CYCLE IRS OFF-NAV と IRS POS/ORIGIN DISAGREE は定義だけ | ATA34_2 p.342–348・p.352、FCOM p.1287・p.1431・p.1433 | B744.fms.pages.lua:1223-1242、irs/irs_system.lua:29-63、B744.notifications.lua:7・25 |
| NAV-18 | 挙動の誤り | 中 | S | `irsSystem.setPos` を一度 true にすると戻さない（`irsSystem.off` はどこからも呼ばれない）。2 回目以降のフルアラインは位置入力なしで完了する。IRU が OFF でも位置が未入力ならボックスが出る | FCOM p.1286–1287、ATA34_2 p.338 | irs/irs_system.lua:150-156・284-295、activepages/B744.fms.pages.posinit.lua:107-111、B744.fms.pages.lua:1236 |
| NAV-19 | 欠落 | 中 | M | ATT モードが無い。ATT に回しても NAV のまま（位置・GS も有効）。約 30 秒の取り直し、memo、OFF までのラッチ、SET HDG による方位初期化が無い（SET HDG は 2 秒表示するだけ）。NAV デテントも無く NAV↔ATT/ALIGN が自由に動く | FCOM p.1216・p.1227–1228・p.1286、ATA34_2 p.294・p.336・p.354 | irs/irs_system.lua:192-204、B744.fms.pages.lua:1296-1307、B747.30.xt.fltMgmt.lua:168-208 |
| NAV-20 | 欠落 | 中 | M | IRS の電源モデルが無い。更新は `bus_volts[0] > 22` のときだけで、アラインのタイマーは電源と無関係に進む。AC→DC 切替、両方喪失での整列喪失、C IRU の 5 分、>IRS AC/DC、ON BAT 灯とホーンが無い（ON BAT 灯はライトテストでだけ点く）。ATA 24 の bus モデルが前提 | ATA34_2 p.272–275・p.286–287・p.362–363、FCOM p.1217・p.1228・p.1429 | B747.68.xt.fms.lua:1236-1238、irs/irs_system.lua:353-357、B747.90.xt.lighting.lua:1412・1882 |
| NAV-21 | 欠落 | 中 | S | IRS・GPS の EICAS は IRS ALIGN MODE と IRS MOTION 以外出ない。IRS L/C/R、>IRS AC/DC、>ATTITUDE、>HEADING、>TRACK、>GPS、>GPS L/R は表だけで、故障の入口（X-Plane の AHRS/GPS 故障を読む処理）も無い。表の綴りは CENTRE（FCOM は CENTER） | FCOM p.1197–1198・p.1429、ATA34_2 p.288・p.331 | B747.87.xt.warning.lua:111・368-371・411-420・477、irs/irs_system.lua:233-247 |
| NAV-22 | 挙動の誤り | 中 | S | 動きの判定は開始点から 0.0001°（約 11 m）の変位だけで、開始点は 3 台で共有の global。一度 motion になると IRS MOTION のまま止まり、セレクターを回し直すまで再開しない。実機は止まって 30 秒で消え、自動で再開 | ATA34_2 p.350、FCOM p.1227・p.1430 | irs/irs_system.lua:11-12・49-63・160-176・243-260 |
| NAV-23 | バグ | 中 | S | `toDMS` が負の緯度経度で分を誤る（符号付きの値で小数部を取る。W122.31° が W122°41.4 になり、正しくは 18.6）。西経・南緯の LAST POS、REF AIRPORT、GPS POS、POS REF の IRS/GPS 行がすべて誤る。FMC 共通関数なので CDU 担当とも共有 | 数式から（FCOM p.1285 の表示形式） | B747.68.xt.fms.lua:118-139 |
| NAV-24 | 欠落 | 中 | L | 他系統が IRS の有効性を見ていない：AFDS/FCC、yaw damper（最初の IRU のアラインまで INOP）、ブレーキ、失速警報、GPWS、FMC 位置（IRS が 1 台は要る）。IRS 状態を見るのは FMS、ND の地図、TCAS の ND 表示だけ | FCOM p.107・p.1240、ATA34_2 p.281 | B747.90.xt.lighting.lua:1329-1330、B747.61.xt.nd.lua:410-422 |
| NAV-25 | 欠落 | 低 | M | GPS のモデルが無い。`gpsL/gpsR` は常に有効でシムの真位置。電源、初回測位時間、故障が無く、GPS POS は空白にならず UTC は常に GPS。POS REF の GPS NAV INHIBIT と PURGE は文字だけ | ATA34_2 p.378・p.386・p.394・p.396・p.411–412、FCOM p.1225・p.1286 | irs/irs_system.lua:78-83、activepages/B744.fms.pages.posinit.lua:37・70・78・98-100 |
| NAV-26 | 欠落 | 低 | S | IRU 位置にドリフトが無い（乱数のずれが固定）。IRS MONITOR はドリフト率でなく状態文字列。POS REF の IRU の GS はシムの GS | ATA34_2 p.356・p.358 | irs/irs_system.lua:45-52、activepages/B744.fms.pages.maintirsmonitor.lua:1-18 |
| NAV-27 | バグ | 低 | S | ND の更新状態の行：GPS 行はどの IRU もアラインしていないときにだけ「GPS」を入れて消さない（エンジン始動状態で始めると出ない）。全 IRU を OFF にしても IRS 行が残る。IRS (3) から変わったときの 10 秒の緑枠が無い | FCOM p.1150・p.1225 | irs/irs_system.lua:180-190 |
| NAV-28 | 欠落 | 低 | S | HDG REF スイッチはアニメーションだけで真方位がどこにも出ない。高緯度の自動 TRU も無い。表示はパネル変更が要る | ATA34_2 p.302、FCOM p.1242 | B747.01.xt.manipulators.lua:1479-1481 |
| NAV-29 | 欠落 | 低 | S | EFIS の POS スイッチで出る IRU 位置と GPS 位置の記号が無い | FCOM p.1150・p.1225、ATA34_2 p.314・p.392 | B747.60.xt.fltInst02.lua:1204-1209・1365-1370 |
| NAV-30 | バグ | 低 | S | `validate_sethdg` は数字でない入力で Lua エラー（`tonumber(value) >= 0`）。`fmsModules["data"] ~= "---`"` はテーブルと文字列の比較で常に真 | — | B744.fms.pages.lua:720-727・1300 |
| NAV-31 | バグ | 低 | S | 冷えた機体で quick start を使うと status = 2 だけを立てて `irsSystem.align` を通らず、位置入力後に開始点 0 と比べて IRS MOTION で止まる可能性（要シム確認） | — | B747.30.xt.fltMgmt.lua:358-366、irs/irs_system.lua:53-61・163-176 |
| NAV-32 | バグ | 中 | S | ACP で VOR L/R を選ぶと X-Plane の NAV1/NAV2（= ILS L/R）の音声が開く。VOR は NAV3/NAV4。APP L/C/R でも ILS 音声は出ない（MKR だけ）。ダイヤルを回しても前の選択を消さない。VOR の ident が確認できない | ATA34_1 p.348 (34-51)・p.458 (34-31)、FCOM p.1231 | B747.15.xt.com.lua:3632-3668 |
| NAV-33 | バグ | 中 | S | NAV RADIO の VOR 行に識別符号や周波数/コースを入れると `tonumber` が nil になり、DELETE と同じく autotune に戻る。周波数範囲（108.00–117.95、50 kHz）の検査も無い | FCOM p.1304、ATA34_1 p.352 | B744.fms.pages.lua:2512・2555-2563 |
| NAV-34 | バグ | 中 | S | NAV RADIO の RADIAL に `nav_bearing_deg_mag`（局への方位）を出していて radial と 180° 違う。autotune 中は同じ値を OBS に書くので、VOR 偏位は常に TO 側で中立 | FCOM p.1305、ATA34_1 p.368 | B747.68.xt.fms.lua:171、B744.fms.pages.lua:458-459、irs/rnav_system.lua:40-41 |
| NAV-35 | 欠落 | 中 | M | VOR autotune は IRS 位置から最寄りの VOR を 10 s ごとに選ぶだけ（A のみ）。R・P、位置更新に適した局の選択、REF NAV DATA の禁止、2 局手動時の扱い、ヒステリシスが無い。FMC 故障・master 切替とも無関係 | FCOM p.1230・p.1303、ATA34_1 p.350 | irs/rnav_system.lua:24-88、B747.68.xt.fms.lua:1236-1239 |
| NAV-36 | バグ | 低 | S | autotune の「2 番目に近い局」の探索に else 節が無く、1 番目と 2 番目の間の距離の局で更新しない。VOR R が遠い局になるか同調されない | — | irs/rnav_system.lua:65-70・82-86 |
| NAV-37 | 挙動の誤り | 中 | M | ILS autotune は目的地まで 45 NM 以内でだけ同調し、選んだ進入でなく経路点の並びと LOC の向きから ILS を推定する。PARK → 周波数/コース PARK → A の段階が無く、CDU の PARK 表示は T/D までの距離だけで決めていて実際の同調と一致しない | FCOM p.1229・p.1306–1307、ATA34_1 p.540 | B747.70.xt.autopilot.lua:1621-1745、B744.fms.pages.lua:427-452 |
| NAV-38 | 欠落 | 中 | S | ILS の同調禁止（AP の LOC/GS capture、FD だけで capture かつ RA 500 ft 未満、地上の LOC alive・45°・40 kt）と解除（TOGA、AP 解除と両 FD OFF）、離陸後 10 分の autotune 禁止が無い。進入中に NAV RAD 入力や経路変更で NAV1/NAV2 が書き換わる。ILS TUNE INHIBITED - MCP は定義だけ | FCOM p.1229・p.1305・p.1432、ATA34_1 p.440・p.450 | B744.fms.pages.lua:355-410・2549-2553、B747.70.xt.autopilot.lua:1687-1786、B744.notifications.lua:18 |
| NAV-39 | 挙動の誤り | 中 | S | PFD の ILS 表示（approach ref、コース、LOC/GS scale、rising runway）を `ils_dots` で出し入れし、これは目的地まで 50 NM 以内（か LOC 中）でしか 1 にならない。実機は PARK 以外で同調していれば出る（出発時の手動同調も）。APP/LOC は `ils_dots` = 0 だと受け付けず RW/ILS CRS ERROR を出す | FCOM p.987・p.1304・p.1434 | B747.70.xt.autopilot.lua:1635-1637・1792-1797・2397-2398・2430-2431、747-400.acf:84907・84981・86770・87736 |
| NAV-40 | バグ | 低 | S | パネル定義の取り違え：機長 ND の「ILS R 2」の周波数が `nav3_frequency_hz`（VOR L）、ILS 欄の ID/周波数の切替に VOR の ID 有無を使う、機長 ND expanded の GS 指針が `hsi_vdef_dots_copilot`、dataref 名の無い表示条件（`SHOW_GREATER 2.31 [2]`）。両 acf 共通。パネル変更が要る | — | 747-400.acf:116632（カスタム 106343）・116482-116498・110018-110045・99470・100288 |
| NAV-41 | バグ | 中 | S | ACF_DIFF の「ADF 方位針」は実は ND の VOR L/R 指針。カスタム acf の機長 centered map のグループ（Bearing Pointers 2）だけ `nav_relative_bearing_deg[3]/[4]` で、VOR L 指針が VOR R の方位を、VOR R 指針が NAV5（未同調と推定）を指す。VOR L/R は NAV3/NAV4（index 2/3）なので純正の [2]/[3] が正しい。コード（RMI、FMS）は [2]/[3] 前提で、カスタム acf の値には依存しない。ADF 指針は両 acf とも scalar の `adf1/adf2_relative_bearing_deg` に `[10]` を付けて読む（要シム確認） | ACF_DIFF.md §2、X-Plane DataRefs.txt | 747-400_custom.acf:98755・98773、747-400.acf:99595・99613・99631・99649、B747.60.xt.fltInst02.lua:2221・2229 |
| NAV-42 | 欠落 | 中 | M | PFD の LOC/GS 過大偏位警告（scale 琥珀・指針 4 Hz 点滅。GS は RA 100–500 ft で約 5/8 dot 超、LOC は RA 0–500 ft で約 1/4 dot 超が 1 s、LOC capture fail は RA 0–950 ft）が無い。パネルに琥珀の scale も無い | FCOM p.987、ATA34_1 p.468 | なし |
| NAV-43 | 欠落 | 低 | M | autotune 中に ND の VOR 偏位・コース指針・TO/FROM を消す処理、手動 VOR + コースの radial 表示、POS スイッチの radial が無い。`tuningmodes` は文字列でパネルが読めない | ATA34_1 p.362・p.368、FCOM p.1040・p.1145 | B747.68.xt.fms.lua:193、irs/rnav_system.lua:40-41 |
| NAV-44 | 欠落 | 低 | S | ND の地図で同調中の VOR を緑で出すのは STA が ON のときだけ。FCOM は STA に関係なく緑 | FCOM p.1145 | B747.61.xt.nd.lua:293-302 |
| NAV-45 | 欠落 | 低 | S | ADF の ANT/BFO（入力の A/B）と周波数範囲の検査が無い。0.5 kHz は落ちる。小文字欄に FCOM に無い「M」を出す | FCOM p.1304、ATA34_1 p.300・p.312 | B744.fms.pages.lua:492-493・2566-2567 |
| NAV-46 | 欠落 | 低 | M | 受信機ごとの電源が無い（§2.1）。X-Plane の avionics 電源だけで全部動き、「VOR L 故障で MB 表示なし」も無い | ATA34_1 p.283・p.330・p.394・p.435・p.525、FCOM p.987 | なし（xtlua/scripts/Avionics/Avionics.lua:29-38） |
| NAV-47 | 欠落 | 低 | S | ILS ANTENNA と >SNGL SOURCE ILS は表だけ。ILS/G/S/LOC ANTENNA の status も無い。故障モデルと ILS 源の切替が無いので当面は出る条件が無い | FCOM p.1429–1430、ATA34_1 p.478 | B747.87.xt.warning.lua:155・165 |
| NAV-48 | 欠落 | 低 | S | ILS 入力：/コースだけの入力を受け付けない。入れたコースは ILS の選別にしか使わず、DB のコース + 磁差を OBS に書く。中央 ILS が無い | FCOM p.1305・p.1428 | B744.fms.pages.lua:355-410 |
| NAV-49 | 欠落 | 低 | S | FMC 故障時の代替同調（ALTN NAV RADIO）と FMC master による同調元の切替が無い（ALTN ページは雛形）。FMC 故障を作らない限り影響は無い | ATA34_1 p.302・p.354・p.464・p.542、FCOM p.1422・p.1427–1428 | refonly/B744.fms.pages.altnnavradio.lua:1-21 |
| NAV-50 | 欠落 | 低 | S | CDU の display_mode = 1 で出る無線ノブ（`laminar/B747/fms1/radio/*` 15 個）のコマンドがどこにも無い。実機に無い補助機能で、作らないなら INTERFACES の dynamic のまま | INTERFACES.tsv | 747-400_cockpit.obj:24608-24630 |
| NAV-51 | 欠落 | 中 | M | RA が 1 系統：機長側の X-Plane RA を両 PFD と全利用者に使う。L/C/R、電源、RA 旗・NCD、EIU 選択による優先順位、GPWC の比較選択、RADIO ALT L/C/R が無い | ATA34_2 p.70・p.76・p.88–89・p.96・p.99・p.122 | B747.60.xt.fltInst02.lua:112-115・2366-2378、747-400.acf:86916-86922 |
| NAV-52 | バグ | 高 | S | MINS RST が minimums を書き換える：RADIO なら両席の DH を 350 ft、BARO なら両席の baro minimums を 1,000 ft にする。F/O の RST も機長側を押す。CDU の DH RESET も同じコマンド。実機の RST は点滅のリセットだけ | FCOM p.982・p.1036 | B747.60.xt.fltInst02.lua:776-791・949-963、activepages/B744.fms.pages.efisctl.lua:1・50 |
| NAV-53 | 挙動の誤り | 中 | S | DH/RADIO alert は機長側だけで計算し、F/O PFD も同じ `dec_height/display_status` を見る（F/O の設定と無関係に点滅）。比較は生の RA、表示は RA − 8 ft で 8 ft ずれる | FCOM p.981–982、ATA34_2 p.95 | B747.60.xt.fltInst02.lua:2263-2311・2366-2378、747-400.acf:94008-94016 |
| NAV-54 | 挙動の誤り | 低 | S | DH 表示の細部：DH = 0 が非表示（実機は 0 未満で非表示）、点滅 5 s（E&M は 3 s）、arm が「RA > 75 ft」（E&M は DH + 75 ft） | ATA34_2 p.95、FCOM p.981 | 747-400.acf:86841-86843・94008-94010、B747.60.xt.fltInst02.lua:2248-2275 |
| NAV-55 | 欠落 | 高 | L | GPWS mode 1–5 の判定が無い。警報は X-Plane の annunciator と .snd の粗い条件だけ（SINK RATE = VVI < −2,500 fpm かつ RA < 2,500、TOO LOW TERRAIN = VVI < −200・gear down・IAS < 180 kt で普通の最終進入で成立、TOO LOW FLAPS は高度条件なしで終了条件の演算子が `=!`、TOO LOW GEAR = X-Plane の gear 警報音、GLIDE SLOPE = X-Plane の annunciator）。alert→warning の二段、DON'T SINK、mode 3/4 の切替、空地判定が無い | ATA34_2 p.144–178、FCOM p.1574–1577 | fmod/747-400.snd:6052-6095、B747.87.xt.warning.lua（GPWS の処理なし） |
| NAV-56 | バグ | 高 | S | GND PROX パネルの 4 スイッチは `button_switch/position[3]`〜`[6]` を切り替えるだけで、どのロジックも読まない。G/S INHB は alternate 動作（実機は momentary + 30 ft / 1,000 ft で解除されるラッチ） | FCOM p.1537–1538、ATA34_2 p.139・p.174 | B747.01.xt.manipulators.lua:570-584・1579-1582 |
| NAV-57 | 欠落 | 中 | S | CONFIG GR OVRD で CONFIG GEAR を止められない（config warning の担当と調整） | FCOM p.1538、ATA34_2 p.207 | B747.45.xt.fltCtrls.lua:1030-1047 |
| NAV-58 | 欠落 | 高 | S | GND PROX 灯・G/S INHIBIT 灯は常に消灯（TODO のまま）。PULL UP・WINDSHEAR で master WARNING が点かない | FCOM p.1532・p.1538、ATA34_2 p.142 | B747.90.xt.lighting.lua:1059-1064・1721-1724、B747.87.xt.warning.lua:818-833 |
| NAV-59 | 欠落 | 高 | M | mode 7 の論理が無い。PFD WINDSHEAR と siren/voice は X-Plane の `windshear_warning` そのままで、1,500 ft 未満・離陸/進入の限定、最低 5 s、他 GPWS と TCAS の禁止、master WARNING が無い。.snd の終了条件は bus 電圧 < 1 V だけ | ATA34_2 p.186–190、FCOM p.1581–1582 | 747-400.acf:87150-87154、fmod/747-400.snd:6098-6102 |
| NAV-60 | 挙動の誤り | 中 | M | mode 6：callout は生の X-Plane RA の通過で鳴り、「各 1 回、1,000 ft 超でリセット」が無い。400/300/200 は FCOM のどの型にも無い（CDU の設定で切る前提）。.snd は設定 `fmod/options/gpws` を参照しない。BANK ANGLE は 35° 一段で `bus_volts[0] == 28` の等号条件、低高度の規則と 40°/45° の段が無い | FCOM p.1577–1578、ATA34_2 p.180–184 | fmod/747-400.snd:5946-6043、B747.05.xt.simconfig.lua:78・131-145 |
| NAV-61 | バグ | 中 | S | MINIMUMS の FMOD イベントが `laminar/B747/altimeter/ft_adjusted == 1`（Capt 気圧高度 × 0.01 = 1、つまり約 100 ft MSL）で起動する。Lua が計算する `fmod/callouts/DH` は .snd で使われていない | FCOM p.1578 | fmod/747-400.snd:6111-6115・6123-6127、B747.60.xt.fltInst02.lua:2316-2350・2389-2395 |
| NAV-62 | 欠落 | 中 | L | look-ahead と TCF が無い。TERR OVRD は効果なし。ND の TERRAIN/OBSTACLE・TERR OVRD/FAIL/POS/TEST 表示がパネルに無く、警報時の terrain 自動表示も無い。TERR スイッチは外部の Terrain Radar 依存の表示切替だけ | FCOM p.1540–1543・p.1571–1573・p.1585、ATA34_2 p.193–199・p.208–210 | B747.60.xt.fltInst02.lua:1212-1218、B747.61.xt.nd.lua:706-713 |
| NAV-63 | 欠落 | 中 | S | GPWS の EICAS（>ALT CALLOUTS、GND PROX SYS、TERR POS、>TERR OVRD、WINDSHEAR SYS）を誰も立てない。override + 速度条件の GND PROX SYS も無い。表の名前 >WINDSHEAR SYS は FCOM（caret なし）と違う | FCOM p.1538・p.1604–1605 | B747.87.xt.warning.lua:192・367・474-475・484 |
| NAV-64 | バグ | 中 | S | PFD の PULL UP と pull_up の voice が `sim/cockpit/warnings/annunciators/GPWS` に結び付いている。DataRefs.txt ではこれは「GPWS failed」で、PULL UP は `sim/cockpit2/annunciators/GPWS`。誤配線の疑い（要シム確認） | X-Plane DataRefs.txt:968・3884 | 747-400.acf:87129-87133、fmod/747-400.snd:6059-6064、B747.90.xt.lighting.lua:142 |
| NAV-65 | 欠落 | 中 | M | 警報の相互禁止が無い：GPWS warning で TCAS を TA ONLY にしない、windshear で他 GPWS・TCAS・自動表示を止めない、voice の調停が無い（.snd の各イベントが独立に鳴り重なりうる） | FCOM p.1582–1583、ATA34_2 p.17–18・p.130・p.186 | B747.30.xt.fltMgmt.lua:421-433、fmod/747-400.snd:5942-6103 |
| NAV-66 | 挙動の誤り | 中 | S | トランスポンダのモード対応：STBY 以外はすべて X-Plane の mode 2（Mode A、高度報告なし）。ALT ON は 3、TA は 6、TA/RA は 7 にすべき（ALT OFF は 2）。このため X-Plane 内蔵の TCAS も働いていないと推定 | FCOM p.1219・p.1231、ATA34_1 p.632、DataRefs.txt:4692 | B747.30.xt.fltMgmt.lua:216-229 |
| NAV-67 | 挙動の誤り | 低 | S | ATC L/R セレクタは R でコード表示が INOP になる以外何も変わらない。実機は R も同じに動き ATC 1/ATC 2 を表示する（パネル変更が要る） | FCOM p.1219、ATA34_1 p.584・p.590 | B747.30.xt.fltMgmt.lua:234-242、747-400.acf:140892-140913 |
| NAV-68 | 欠落 | 低 | S | TEST 位置（トランスポンダ・TCAS の試験、ND の TCAS TEST、TEST OK/FAIL の音声）が無い。3D ノブに TEST の位置が無い | FCOM p.1219・p.1563、ATA34_2 p.50 | B747.30.xt.fltMgmt.lua:216-229、Cockpit_Pedestal1.obj:40246-40252 |
| NAV-69 | 欠落 | 高 | M | TCAS の TA/RA 判定が無い。X-Plane の threat、tcas_message、vs_bands を一切読まない | ATA34_2 p.37–43、FCOM p.1560–1561 | B747.30.xt.fltMgmt.lua:216-229、B747.61.xt.nd.lua:496-509 |
| NAV-70 | 欠落 | 高 | M | ND の TCAS 表示：全機を白い 1 種類のアイコン（icon 22）で描き、RA/TA/proximate/other の形と色、相対高度、上下矢印、no-bearing が無い。パネルは TFC と TCAS OFF だけで、TRAFFIC、OFFSCALE、TA ONLY、TCAS TEST、TCAS FAIL が無い（パネル変更が要る） | FCOM p.1032・p.1152–1154・p.1534–1535、ATA34_2 p.42–44 | B747.61.xt.nd.lua:274-279・496-509、747-400.acf:106929-106933・116378-116382 |
| NAV-71 | 欠落 | 高 | M | PFD の RA ガイダンス（赤枠の RA pitch region）が無い。パネル変更が要る | FCOM p.1536–1537・p.1562、ATA34_2 p.46 | なし |
| NAV-72 | 欠落 | 高 | S | TCAS の音声が鳴らない。.snd に TCAS のイベントが無く（bank に素材はある）、X-Plane 既定の音声は無音の wav で上書きされている。.snd を変えるかは利用者の判断 | FCOM p.1553・p.1563–1568、ATA34_2 p.49–50 | fmod/747-400.snd、sounds/alert/tcas.wav・te_climb.wav・te_descend.wav |
| NAV-73 | 欠落 | 中 | M | TCAS の高度・機体条件による抑止が無い（INCREASE DESCENT < 1,500 ft、DESCEND < 1,100 ft、全 RA < 1,000 ft で TA ONLY 表示、TA 音声 < 500 ft、48,000 ft で CLIMB 系なし）。X-Plane の TCAS がどこまで持つかは要確認 | FCOM p.1593・p.1600–1601、ATA34_2 p.17–18・p.43 | なし |
| NAV-74 | 欠落 | 中 | S | TFC の自動表示（TA/RA 時、EFIS パネル故障時）と表示モードの制限（VOR CTR、APP CTR、PLN では出さない）が無い。TFC スイッチは単純なトグル | FCOM p.1042・p.1534・p.1560・p.1584 | B747.60.xt.fltInst02.lua:1143-1151・1298-1307・2567-2603 |
| NAV-75 | 挙動の誤り | 低 | S | ND の TCAS OFF が、読み込み後に TA/RA を一度選ぶまで TFC 未選択でも両 ND に出る（`seenRASet`） | FCOM p.1032・p.1154 | B747.60.xt.fltInst02.lua:2566-2590 |
| NAV-76 | 挙動の誤り | 低 | S | >TCAS OFF が地上で IAS < 30 kt なら出る。FCOM は地上〜離陸後 400 ft RA と、進入の 400 ft RA 以下（復行 400 ft まで）で抑止 | FCOM p.1593・p.1601・p.1605 | B747.30.xt.fltMgmt.lua:421-426 |
| NAV-77 | バグ | 低 | S | traffic の高度フィルタ `abs(ele 差) < 2000` の単位は meter（約 6,560 ft）。通常の窓は ±2,700 ft。近い 30 機の制限も無い | ATA34_2 p.24・p.26・p.42、DataRefs.txt:5197 | B747.61.xt.nd.lua:497-498 |
| NAV-78 | 欠落 | 低 | M | 故障系：ATC FAIL 灯、R（応答）表示、>TRANSPONDER L/R、>TCAS SYSTEM、>TCAS RA CAPTAIN/F/O、ND の TCAS FAIL を出す論理が無い（定義だけ） | FCOM p.1219–1220・p.1430・p.1570・p.1605 | B747.87.xt.warning.lua:466-468・478-479、B747.30.xt.fltMgmt.lua:427-433 |
| NAV-79 | 欠落 | 中 | M | WXR パネル（570 型）の論理：LR/T・RR/T、TFR（反対側の表示、両側同時で TEST）、WX と WX+T の自動ゲイン、WX+T で 40 nm 超なら WX。ハンドラは空で、TEST は両側を TEST に固定するだけ、ゲインは 2 を 1 に戻すだけ、LR/T 灯は常時点灯 | FCOM p.1222–1224 | B747.15.xt.com.lua:3022-3041・3602-3607、B747.90.xt.lighting.lua:2125-2126 |
| NAV-80 | 欠落 | 低 | M | WXR の故障・注意表示（WXR FAIL と RT/ANT/CONT/ATT/WEAK、RANGE DISAGREE、RSTR INOP）と、安定化の IRU（IRS source select）・電源との連動が無い。X-Plane のレーダーは IRS や電源と無関係に動く | ATA34_1 p.242・p.246–250・p.263、FCOM p.1155・p.1222 | なし（`EFIS_weather_stab` などを書いていない） |
| NAV-81 | 挙動の誤り | 低 | S | ND の WXR 注記：mode 0 で "RT"（FCOM では R/T 故障の表示）、チルトを "+5.0" の形で出す、ゲイン（CAL/VAR）表示が無い、X-Plane 12.3 未満では空 | FCOM p.1013–1018・p.1155、ATA34_1 p.244 | B747.61.xt.nd.lua:365-395 |

- 件数：高 13（NAV-01・02・03・16・52・55・56・58・59・69・70・71・72）、中 37、低 31、計 81。
- ACF_DIFF の関係：§2 の方位針は NAV-41（カスタム acf の機長 centered map の 2 行を純正の `[2]/[3]` に戻せば直る。コードは依存しない）。この範囲の acf キー（`acf/_has_TCAS 1`、`acf/_wxr_radar/*`、`rel_xpndr`・`rel_wxr_radar` の bus 指定）は純正とカスタムで同じで、コードはどれも読まない（X-Plane 内蔵の TCAS とレーダーが使う）。
- 作り直しでも名前と意味を保つもの（INTERFACES.tsv。`{a,b}` は展開）
  - ソース選択：`laminar/B747/flt_inst/{flt_dir_src,nav_src,eiu_src,irs_src,air_data_src}/{capt,fo}/sel_dial_{up,dn,pos}`、`.../eiu_src/ctr_pnl/sel_dial_{up,dn,pos}`、`.../fmc_master_src/ctr_pnl/sel_dial`・`sel_dial_pos`（nav_src と fmc_master_src はパネルも読む）。
  - エアデータ・BARO：`laminar/B747/gauges/indicators/airspeed_kts_{pilot,copilot}`、`laminar/B747/altimeter/baro_hectopascal`・`ft_adjusted`、`laminar/B747/airspeed/Vmax`・`Vmaxm`、`laminar/B747/efis/baro/{capt,fo}/{preselect,set_dial_pos}`、`laminar/B747/efis/baro_ref/{capt,fo}`・`.../sel_dial_{up,dn,pos}`、`laminar/B747/efis/baro_set/{capt,fo}/sel_dial_{up,dn}`、`laminar/B747/efis/baro_std/{capt,fo}/{switch,switch_pos,show_preselect}`、`laminar/B747/rmi_{left,right}/captain/bearing`、`laminar/B747/light/spill/ratio/mag_compass`。
  - IRS：`laminar/B747/flt_mgmt/iru/mode_sel_dial_pos`（0 OFF、1 ALIGN、2 NAV、3 ATT）、`.../iru/mode_sel_dial_{L,C,R}_{up,dn}`、`laminar/B747/pfd/{capt,fo}/irs`、`laminar/B747/irs/{line1,line2,line3,line4,irs_display_line,gps_display_line}`、`laminar/B747/nd/pos/{capt,fo}/switch[_pos]`、`laminar/B747/toggle_switch/heading_ref`、`laminar/B747/annunciator/brightness_ratio`（[104] ON BAT）。INTERFACES には無いが FMC ページが使う `laminar/B747/flt_mgmt/iru/status` と `irsSystem.*` の API（posinit、maintirsmonitor、ATC の posreport/emergency、rnav_system などが呼ぶ）も形を保つ。
  - 無線：`laminar/B747/ap_{L,C,R}/{vor_adf,app_mkr}/{audio_sel_switch,audio_vol}`、`.../{vor_adf_rcvr,app_rcvr,nav_filter}/sel_dial_{up,dn,pos}`、`laminar/B747/comm/ap_{L,C,R}/{vor_adf_audio,app_mkr_audio}/vol_{up,dn}`、`laminar/B747/autopilot/ils_dots`、`laminar/B747/nd/{vorL,vorR,adfL,adfR}_id_flag/capt`、`laminar/B747/nd/data/{capt,fo}/vor_ndb`、`laminar/B747/fms{1,2,3}/func_key/navrad`、`laminar/B747/fms1/radio/*`（dynamic）。パネルが読む X-Plane 側の `sim/cockpit2/radios/...` と `sim/cockpit2/EFIS/EFIS_{1,2}_selection_{pilot,copilot}` も変えられない。`laminar/B747/radio/tuningmodes`・`ilsData` は INTERFACES に無いので作り直せるが、FMS と autopilot を同時に変える。
  - RA・GPWS：`laminar/B747/button_switch/gnd_prox_{gs_inhibit,flap_ovrd,gear_ovrd,terr_ovrd}`、`laminar/B747/button_switch/position`（[3]〜[6]）、`laminar/B747/annunciator/brightness_ratio`（[1] master WARNING、[2] GND PROX、[3] G/S INHIBIT）、`laminar/B747/efis/radio_altitude`、`laminar/B747/radio_alt/display_status`、`laminar/B747/dec_height/display_status`、`laminar/B747/efis/dh/{capt,fo}/reset_switch`、`laminar/B747/efis/{min_ref_alt,ref_alt}/{capt,fo}/...`、`laminar/B747/nd/terr/{capt,fo}/switch[_pos]`、`laminar/B747/nd/data/{capt,fo}/terr`、`laminar/B747/nd/terr_weather/{capt,fo}`、`laminar/B747/fmod/callouts/{appDH,v1}`、`laminar/B747/warning/master_warning`。G/S INHB の position[3] は「押している間 1」に意味が変わる（3D の見た目への影響は小さい）。
  - 監視：`laminar/B747/flt_mgmt/transponder/{ident_btn_pos,sel_dial_pos}`、`.../transponder/{mode_sel_dial_up,mode_sel_dial_dn,sel_dial}`、`laminar/B747/flt_mgmt/transponder_code/{digts_12_dial_pos,digts_34_dial_pos}`、`laminar/B747/flt_mgmt/txpdr/mode_sel_pos`、`laminar/B747/nd/{capt,fo}/{tcas_off,tfc}`、`laminar/B747/nd/traffic/{capt,fo}/switch`、`laminar/B747/nd/wxr/{capt,fo}/switch[_pos]`、`laminar/B747/nd/{capt,fo}/text/{wxr,tilt}`、`laminar/B747/wxr/buttons/{test,rr,lr,cpt_ftr,fo_ftr}`。3D は X-Plane の `sim/transponder/*`、`sim/instruments/EFIS_wxr_*`、`sim/instruments/barometer_up/down`、`sim/radios/RMI_L_tog/RMI_R_tog` も直接使う。

## 8. 作り直しか部分修正か

| 範囲 | 推奨 | 理由 |
|---|---|---|
| エアデータ・ソース切替・altitude alert | 作り直し（新モジュール） | ADC の実体が無く、選択器 6 種はほぼ飾り。動いている air data 系メッセージは OVERSPEED（誤り）、BARO DISAGREE、AOA RIGHT（側が誤り）だけで、残す価値のあるロジックは fltInst02 の数十行しかない |
| IRS・GPS | 作り直し（1 モジュール。M、他系統への口を含めて L） | `irs_system.lua`（364 行）の状態機械は `status` 0/1/2/4 とセレクター位置の組み合わせに分散し、1 回タイマー、共有 global、FMC ページ処理が絡む。NAV-16〜19・22 はどれもこの欠陥で、継ぎ足すと遷移の抜けが残る |
| 無線の同調 | 作り直し（同調ロジックを 1 モジュールに） | NAV RADIO ページ（B744.fms.pages.lua）、VOR autotune（rnav_system.lua）、ILS autotune と表示の出し入れ（B747.70.xt.autopilot.lua）に分かれ、文字列 dataref 2 本で状態を共有して NAV1/NAV2 を書き合っている。合わせて約 300 行と小さく、受信機ごとの状態（A/M/P/R/PARK、禁止、10 分タイマー、最後の有効周波数）を 1 か所に持てば NAV-33〜39・45・48 がまとめて直る |
| ACP の nav 音声 | 部分修正 | B747.15.xt.com.lua の数行（NAV-32） |
| 電波高度計・DH | 部分修正 | fltInst02 の RA・DH 部分（約 150 行）を 3 台の RA と左右独立の DH alert に置き換える |
| GPWS・windshear | 新規 | 直す対象のロジックが Lua に無い。新モジュール（例：xtlua に `B747.88.xt.gpws`、名前は案）で §4.9 を持ち、出力 dataref を PFD・照明・FMOD・CAS・TCAS が読む |
| トランスポンダ | 部分修正 | 約 40 行（fltMgmt.lua:216-242・421-434）。モード対応、EICAS の抑止、L/R |
| TCAS | 新規 | 白いアイコンと TCAS OFF しかなく土台が無い。X-Plane 12 の TCAS II を判定の核にし、747 固有の層を足す |
| 気象レーダー | 部分修正 | 描画は X-Plane のレーダーのまま、570 型パネルの論理と ND の注記・故障表示を足す |
| スタンバイ計器 | 保留 | Lua だけでは直せない。obj の dataref 変更（承認）と組で決める |

- 全体の推奨：部分修正では足りない。ATA 34 の大半は「X-Plane のセンサーをパネルが直接読む」構造で、資料どおりの冗長構成（ADC・IRS・RA・ILS の 3 台、ソース選択、故障旗、比較警報）を入れる場所が無い。センサー層を新しく作り、機器ごとの状態（電源・故障・モード）と「各席が選んだ源の値」を dataref で出し、表示・AFDS・FMC・警報がそれを読む形にするのが速くて安全。INTERFACES.tsv の名前と意味は保つ。
- すぐ直してよい小さな修正（作り直しを待たない）：NAV-02（OVERSPEED）、NAV-52（MINS RST）、NAV-23（toDMS）、NAV-30（SET HDG の検証）、NAV-32（ACP の nav 音声）、NAV-34（radial）、NAV-66（トランスポンダのモード）、NAV-07（AOA RIGHT）。
- 依存の順：ATA 24 の bus モデル → ADC・IRS・RA・GPS（センサー層）→ ソース選択と比較警報・altitude alert → 無線の同調 → GPWS → TCAS と相互禁止 → .snd の付け替え（利用者の判断）→ パネル表示（カスタム acf、承認）と standby 計器の obj（承認）。
- Lua だけでは届かないもの：PFD の高度・Mach の源と旗、TCAS・terrain・LOC/GS 過大偏位の表示、NAV 選択器の意味の是正、IRU ごとの姿勢値、standby 計器の独立。カスタム acf のパネル変更案としてまとめ、承認を取ってから行う。

## 9. 未確認事項

- effectivity の選択：109（旅客機）に合わせるか、3D の構成（WXR パネル 570 型、TERR OVRD・RADIO/BARO MINS は 405/570、RMI は 405）に合わせるか。GPWS の callout の組（109 の 100/50/30/10 か 405 の 2500〜10・APPROACHING MINIMUMS・BANK ANGLE か）、PWS の有無、TCAS の版（7.0 か 6.04A）も同じく利用者が決める。
- 3D の AIR DATA ノブ（2 位置）の 2 つ目の位置の刻印。NAV 選択器の 3D の目盛と 0–3 の対応、既定位置で ND の VOR モードに基準 VOR の欄が出るか。
- `sim/cockpit2/gauges/indicators/altitude_ft_pilot` などを Lua で書いたとき X-Plane が上書きするか。`rel_adc_comp(_2)` が cockpit2 の速度・高度・Mach にどう効くか。
- MAWEA PSU A の電源の表記「standby bus No. 3」（ATA34_1 p.188）の実体。WXR R/T の給電バス（資料に記載なし）。
- EFIS の BARO ノブの HPA 選択時の刻み（資料に記載なし。現コードは常に 0.01 inHg）。C ADC 選択時の V/S の遅れを再現するか。
- アライン中の PFD：ATA は旗なしで消す（NCD）、FCOM は旗を出す。現状は FCOM と同じ。ND の「TIME TO ALIGN」表示（`irs/line1-4`）が実機にあるか（資料に記載なし）。ON BAT 灯が飛行中に点くか。
- 緯度によるアライン時間、緯度比較の許容差、IRS のドリフト量、ATT での方位ドリフト、GPWS mode 1・2 の warning 曲線、mode 3 の曲線、mode 7 の閾値：資料に記載なし。外部資料を使うか近似で済ますか。
- X-Plane の AHARS：電源喪失・故障時の挙動、`gyr_free_slaved`・`dg_drift_ahars_deg` を ATT の方位に使えるか。XTLua の `run_after_time` がポーズ・時間加速で止まるか。
- NAV-23（toDMS）を西経の空港で、NAV-31（quick start 後の IRS MOTION）を冷えた機体で確かめる。
- パネルの細部：PFD の MB は `SHOW_GREATER 1.0` を 0/1 の dataref に使っている（747-400.acf:84807・84840・84873）。「より大きい」なら MB が出ない。scalar の `adf1/adf2_relative_bearing_deg[10]` を X-Plane がどう読むか（ADF 指針が動くか）。dataref 名の無い表示条件（`SHOW_GREATER 2.31 [2]`、`SHOW_LESS 0 [0]` など）の扱い。`HSI_source_select_copilot` の既定値。
- X-Plane の nav 配列の index 4 が NAV5 か。`navN_nav_id` が受信範囲外でも入るか。ILS コース計算の磁差の符号（B744.fms.pages.lua:390、B747.70.xt.autopilot.lua:1754・1775。片方だけ `int()` で丸める）。
- `sim/cockpit/warnings/annunciators/GPWS` の実際の意味（PULL UP か故障か）と、Lua から書いて上書きされないか。X-Plane の windshear と GPWS がこの acf で立つ条件。接地時の X-Plane RA の読み（−8 ft 補正の根拠）。
- FMOD：bank の中で `fmod/options/gpws` を使っているか、`=!`（.snd:6078）が解釈されるか、TOO LOW FLAPS・TOO LOW TERRAIN が普通の飛行で鳴っているか。カスタム acf で FMOD の音が出るか（`747-400_custom.snd` が無い）。
- XTLua で前方地形の標高と滑走路 DB を取れるか（look-ahead・TCF の可否）。
- X-Plane 12 の TCAS を mode 6/7 で動かしたときの抑止高度、感度、`tcas_message` と Ver 7.0 の文言の対応、TCAS 音声の鳴らし方（`sounds/alert` は無音で上書き済み）。`EFIS_tcas_on = 1` で X-Plane 自身も traffic を描いて二重にならないか。TCAS アイコンが PLN・VOR CTR・APP CTR で出るか。`laminar/B747/pfd/{capt,fo}/irs` を TCAS 表示の条件に使う意図（B747.60.xt.fltInst02.lua:2577-2589）。
- X-Plane のレーダーの PWS 既定値、640 nm 時の探知距離、IDENT の持続時間（実機 18 秒）。オンライン接続で mode 2 と 3 がどう扱われるか。
- GND PROX の OVRD 灯が 3D にあるか（747-400_cockpit.obj は押し込みのアニメーションだけ。22077-22079、23299-23351）。
- 資料の食い違い（本文で FCOM に従ったもの）：ILS autotune の時期（E&M p.460 と p.540・FCOM）、LOC アンテナスイッチの電源（図と本文）、MM の色、塗りつぶしの閾値（PFD 2 1/3 dot、ND 2 1/2 dot）、乱気流の表示レンジ（50 nm と 40 nm）、TCAS の抑止高度（E&M と FCOM）、GPWS mode 3・4 の aural、ON BAT の点灯条件（FCOM は条件を書かない）。
