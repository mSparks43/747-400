# ATA 29 Hydraulic Power — 実装ノート

GAP ID の接頭辞：`HYD`。2026-10-23 作成。コードは `overhaul` ブランチ（041c9ffa）時点。

## 1. 概要

- 対象：油圧 4 系統（EDP、demand pump、AUX pump）、リザーバと与圧、SOV、熱交換器、負荷の割り当て、表示（P5 パネル、STATUS、HYD synoptic、EICAS）、電源・抽気との依存。舵面の制御則・AFDS ループ・ブレーキ制御則・ステアリング制御則は他の担当（ATA 22/27/32）。ここでは「油圧が来ているか」でそれらをどう止めるかだけを扱う。
- 使った資料（ページは PDF ページ）：
  - ATA29_32 p.3–144（ATA 29 全体）。特に本文 p.8・20・26–30・36–48・50–56・61–64・68–72・74–78・84–88・92・98–108・114–116・119–120・126・134–136、図 p.21・31・63・71・89・105・109・139・141・143。ブレーキ源の油圧側だけ 32-41 の p.384–418 も見た。
  - ATA22 p.3–48（22-00 Hydraulic and Flight Control Systems Overview。本文は p.44 まで、残りは図）。
  - FCOM 13.10（p.1483–1488）、13.20（p.1489–1494）、13.30（p.1495）。関連：NP.21（p.104・118–119・126・151–153）、SP.6.1（p.179）、2.40（p.611・614）、6.20（p.799・819）、7.13.2（p.860）、7.20.23–24（p.893–894）、8.10.1（p.905）、9.10/9.20（p.928・940・942–953）、14.10–14.30（p.1503–1521）、15.20.36・15.20.40（p.1582・1586）、Bulletin TB1-14（p.49）・TB1-26（p.65–66）、Model Identification（p.5）。
  - FCTM p.286・297（技法）、LH36 p.29（リザーバ与圧の取り出し位置）。
- 型式差：FCOM の 109・405 は P&W、570 は GE（FCOM p.5 (0.1.1)）。逆推力装置は P&W が油圧（関連系統）、GE が抽気（FCOM p.893 (7.20.23)）。RR は `資料に記載なし`。
- 資料の食い違いと採用：
  - AUX pump：E&M は系統 1 と 4 にあると書く（ATA29_32 p.8・30・p.31 図）。FCOM は系統 4 だけ（FCOM p.1483 (13.10.1)、p.1489 (13.20.1)）。乗員操作は FCOM に従い **系統 4 のみ**（3D コクピットと現コードも 4 のみ）。
  - 熱交換器の最低燃料：系統 1・4 で 300 US gal（2000 lb）（ATA29_32 p.76 (29)）と 375 US gal（2400 lb）（ATA22 p.21 (22-00)）。2・3 は 805 US gal で重量が 5400 lb と 5200 lb。整備上の条件で表示には影響しない。どちらが新しいか分からないので、使うなら大きい方（ATA22）を採る。

## 2. 構成

### 2.1 系統ごとの構成

| 系統 | 主ポンプ | demand pump | 補助 | 主な負荷（§2.4） |
|---|---|---|---|---|
| 1 | EDP（エンジン 1） | ADP（抽気タービン駆動） | なし（E&M 構成は AUX あり） | 内側 TE flap、nose/body gear、steering、alternate brakes（第 1 候補）、AP C |
| 2 | EDP（エンジン 2） | ACMP（AC bus 2） | なし | spoiler 2/3/10/11、stab trim、elev feel、lower YD、alternate brakes（第 2 候補）、AP R |
| 3 | EDP（エンジン 3） | ACMP（AC bus 3） | なし | spoiler 1/4/9/12、stab trim、elev feel、upper YD、AP L |
| 4 | EDP（エンジン 4） | ADP | AUX ACMP（ground handling bus、地上専用） | 外側 TE flap、wing gear、normal brakes と brake accumulator、spoiler 5–8 |

- 4 系統は独立で、作動油の混合はない（ATA29_32 p.10 (29)、FCOM p.1489 (13.20.1)）。ポンプは系統ごとに並列（ATA29_32 p.8 (29)）。
- 典拠：ATA29_32 p.8・20 (29)、FCOM p.1489–1490 (13.20.1–2)、p.1491 (13.20.3)。

### 2.2 部品（実装に関係するもの）

- リザーバ：系統 1・4 は同寸、2・3 は小さい。DC の静電容量式量計 → HYQUIM。空気圧で与圧、過圧リリーフは機外へ（ATA29_32 p.36 (29)）。全系統の作動油量は 178 US gal（ATA29_32 p.114 (29)）。各リザーバ容量は `資料に記載なし`。
- リザーバ与圧モジュール：抽気ダクトの空気を約 45 psi に調圧。下流の低圧スイッチが 6.3 psig（21 psia）未満で STATUS メッセージと synoptic の RSVR PRESS（ATA29_32 p.38・104 (29)、FCOM p.1488 (13.10.6)）。取り出しはストラット内ダクトの PRSOV 下流（LH36 p.29 図）→ エンジン抽気弁が閉じてもマニホールド側から与圧されると `推定`。
- 供給遮断弁（SOV）：EDP 供給ライン上、28V DC モーター駆動のゲート弁。エンジン fire switch で閉。位置は HYDIM が検知。熱リリーフ 100 psid（ATA29_32 p.40 (29)）。demand pump は SOV を通らずリザーバから直接（ATA29_32 p.20 (29)）。
- EDP：圧力補償型。スイッチ ON で減圧ソレノイド非励磁＝通常吐出。OFF でソレノイド励磁 → blocking valve 閉、最小ストローク、内部 800 psi でケースドレンのみ（ATA29_32 p.44 (29)）。
- ADP turbine drive：シャットオフ弁と速度制御弁の 2 つのバタフライ弁（両方開で駆動）。continuous run ソレノイドか run-on-demand ソレノイドのどちらかの励磁でシャットオフ弁が開く。ガバナでポンプ 3,200 rpm（タービン 25,400 rpm）。約 32,000 rpm で過回転トリップ → シャットオフ弁閉（地上で手動リセット）（ATA29_32 p.52–56 (29)）。シャットオフ弁の位置スイッチ（閉でない）が HYDIM の「DEM PUMP RUN」入力（ATA29_32 p.52 (29)、p.63 図）。
- ACMP（2・3）：可変容量、モーターは作動油で冷却（ATA29_32 p.68 (29)）。ELCU 経由で 115V AC 3 相（ATA29_32 p.70 (29)、p.71 図）。
- 圧力モジュール：逆止弁 4、圧力スイッチ 2（EDP 用と demand 用。逆止弁で各ポンプの出口圧だけを感知）、リリーフ弁 3500 psi。系統 1・4 は AUX ポンプの入力が 1 つ多い（ATA29_32 p.78 (29)）。
- ケースドレンモジュール：温度センサ（ケースドレン油温）（ATA29_32 p.74 (29)）。熱交換器は各主翼メインタンク内（44 ft のコイル）（ATA29_32 p.76 (29)）。
- HYDIM：系統ごとに 1 枚、計 4 枚。P5 パネルの入力と系統状態を処理し、demand/AUX ポンプの制御、パネルの灯、EIU（EICAS）への出力を出す（ATA29_32 p.16・34 (29)）。HYQUIM：4 系統の量を 1 台で処理、プロセッサカード 2 枚冗長（ATA29_32 p.18・96 (29)）。
- 系統圧トランスミッタ（各系統 1）→ HYDIM → EIU（ATA29_32 p.98 (29)）。

### 2.3 ポンプ定格

| ポンプ | 駆動 | 定格 | 典拠 |
|---|---|---|---|
| EDP ×4 | エンジン補機ギアボックス | 37.5 gpm @2850 psi @3750 rpm | ATA29_32 p.26 (29) |
| ADP（1・4） | 抽気タービン | 32 gpm @2850 psi @3200 rpm | ATA29_32 p.26 (29) |
| ACMP（2・3） | 115V AC 3 相 | 6 gpm @2850 psi @5700 rpm、2850 psi 未満で増え 1200 psi で 12 gpm。始動 167 A、運転 45 A | ATA29_32 p.68・70 (29) |
| AUX ACMP（4） | 115V AC ground handling bus | 5.7 gpm @2700 psi @5800 rpm | ATA29_32 p.84・86 (29) |

- 系統圧は無流量で 3000 psi（ATA22 p.6 (22-00)）、地上点検の基準は 2800–3200 psi（ATA29_32 p.119–120 (29)）。
- EDP のポンプ回転数とエンジン N2 の比：`資料に記載なし`。

### 2.4 負荷の割り当て（P&W 109/405 構成）

| 負荷 | 系統 | 典拠 |
|---|---|---|
| L OUTBD AIL / L INBD AIL / R INBD AIL / R OUTBD AIL | 1+2 / 1+3 / 2+4 / 3+4 | FCOM p.948 (9.20.8)、p.1491 (13.20.3) |
| L OUTBD ELEV / L INBD ELEV / R INBD ELEV / R OUTBD ELEV | 1 / 1+2 / 3+4 / 4 | FCOM p.943 (9.20.3)、p.1491、ATA22 p.12 |
| UPPER RUDDER（アクチュエータ 3 本）/ LOWER RUDDER（2 本） | 1+3 / 2+4 | FCOM p.950 (9.20.10)、p.1491、ATA22 p.38 |
| YAW DAMPER 上 / 下 | 3 / 2 | FCOM p.949 (9.20.9)、ATA22 p.12 |
| ELEV FEEL | 2+3（両方失うとばねのみ、速度依存なし） | FCOM p.943 (9.20.3) |
| STAB TRIM（STCM 2 台） | 2 と 3（STAB TRIM cutout スイッチで遮断） | FCOM p.945 (9.20.5)、ATA22 p.12 |
| SPLR 2,3,10,11 / 1,4,9,12 / 5,6,7,8 | 2 / 3 / 4 | FCOM p.1490 (13.20.2)、p.1491 |
| AP サーボ C / R / L（elevator、lateral、rollout） | 1 / 2 / 3 | FCOM p.1490、ATA22 p.10–12 |
| 内側 TE flap / 外側 TE flap（一次。二次は電動） | 1 / 4 | FCOM p.953 (9.20.13) |
| nose・body gear 作動 / wing gear 作動 | 1 / 4 | FCOM p.1511 (14.20.1) |
| nose・body gear steering | 1 | FCOM p.1513 (14.20.3) |
| normal brakes と brake accumulator | 4 | FCOM p.1514・1516 (14.20.4–6) |
| alternate brakes | 1、だめなら 2 | FCOM p.1514、ATA29_32 p.390 (32-41) |
| 逆推力装置（P&W） / （GE） | 関連系統 / 関連エンジン抽気 | FCOM p.1490、p.893 (7.20.23) |
| 脚上げ時の de-spin braking | 1 | ATA29_32 p.390 (32-41) |
| LE flap | 油圧ではなく抽気（一次） | FCOM p.953 (9.20.13) |

- GE（570）の 13.20.2 は逆推力装置を負荷に含めない（FCOM p.1490）。
- E&M の系統図（ATA29_32 p.139）では、AP サーボ、STCM などの前にモーター駆動弁、系統 4 の lower rudder にヒューズがある。舵面側の遮断弁（FLT CONTROL HYD POWER、§3.2）とあわせて ATA 27 側で扱う。

### 2.5 電源と抽気

| 機器 | 電源 | 典拠 |
|---|---|---|
| ADP 1 制御（HYDRAULIC 1 DEMAND CB） / HYDIM-1 | 28V DC bus 1 / 28V DC bus 4 | ATA29_32 p.63 図 |
| ADP 4 制御 / HYDIM-4 | 28V DC bus 4 / `推定` DC bus 1（p.63 と対称） | ATA22 p.22（ADP は DC bus 1 か 4 が要る） |
| ACMP 2：モーター / 制御（HYD 2 DEMAND CB） / HYDIM-2 | AC bus 2 / 28V DC bus 2 / 28V DC bus 3 | ATA29_32 p.71 図、ATA22 p.24 |
| ACMP 3：モーター / 制御 / HYDIM-3 | AC bus 3 / `推定` DC bus 3 / `推定` DC bus 2 | ATA29_32 p.71 図（AC bus 3）、ATA22 p.24 |
| AUX ACMP 4：モーター / 制御 | 115V AC ground handling bus / 28V DC ground handling bus | ATA29_32 p.86 (29)、ATA22 p.22 |
| EDP 減圧ソレノイド、SOV | 28V DC（fire switch の接点経由）。bus は `資料に記載なし` | ATA29_32 p.40・46 (29) |
| 量計トランスミッタ | DC | ATA29_32 p.36 (29) |

- ground handling bus は地上で APU gen 1 か external power 1 が使えるときに通電し、aux hydraulic pump 4 を給電する（FCOM p.799 (6.20.5)）。
- main DC bus が EDP と demand pump の制御を給電する（FCOM p.819 (6.20.25)）。
- 抽気：ADP 1・4 は抽気マニホールドの空気で回り、排気は機外（FCOM p.1489 (13.20.1)、ATA29_32 p.50 (29)）。ADP 1 が左ダクト、ADP 4 が右ダクトから取るとは明記されていないが、左右ダクト区画を隔離したとき「該当する」demand pump 1 か 4 を OFF にする（FCOM p.614 (2.40.4)）ので、ADP 1＝左、ADP 4＝右と `推定`。ASCTU 故障で全抽気が止まると ADP は回らず、運転指令中は HYD PRESS DEM が出る（FCOM p.49、TB1-14）。リザーバ与圧も抽気（FCOM p.611 (2.40.1)、p.1489）。

## 3. 操作と表示

### 3.1 P5 HYD パネル（FCOM p.1483–1484 (13.10.1–2)、ATA29_32 p.29–30 (29)、p.31 図）

- ENGINE pump スイッチ（交互押し、ON で白 ON 表示）：ON でエンジン回転時に EDP が加圧。下半分が PRESS 灯（EDP 出口圧低）。
- DEMAND pump セレクタ（回転）：OFF / AUTO / ON。系統 4 だけ AUX あり（AUX はディテント、ATA29_32 p.89 図）。
  - AUTO：EDP 出口圧が低いか fuel control switch が CUTOFF で運転。1・4 はさらにフラップ移動中か、空中でフラップが UP 以外のとき運転。
  - ON：連続運転。
  - AUX（系統 4）：地上で EDP が加圧するまで AUX ポンプが運転。demand pump は止まる。EDP が加圧してもセレクタは OFF に戻らない。
- DEMAND PRESS 灯（琥珀）：セレクタ OFF か AUX／運転中で出口圧低／指令しても動かない。
- SYS FAULT 灯（琥珀）：系統圧低／量低／油温過大。
- 典型的な点灯状態（手順で確認するもの）：
  - Preflight（エンジン停止、DEMAND 全 OFF、ENGINE ON）：SYS FAULT 4 灯点灯、DEMAND PRESS 点灯、ENGINE PRESS 点灯（FCOM p.104 (NP.21.10)）。
  - Before Start：先に系統 4 を AUX → SYS FAULT 4 消灯、DEMAND PRESS 4 は点灯のまま。次に 1・2・3 を AUTO → SYS FAULT と PRESS が消灯（FCOM p.119 (NP.21.25)）。系統 4 を最初に加圧するのは、パーキングブレーキ側から他系統の作動油が系統 4 に移るのを防ぐため（同頁、FCOM p.1516 (14.20.6)）。
  - Before Taxi：DEMAND 全 AUTO（4 も AUX → AUTO）（FCOM p.126 (NP.21.32)）。
  - Shutdown：エンジン停止前に 4 を AUX、駐機なら 1・2・3 を OFF、Secure 前に 4 を OFF（FCOM p.151–153 (NP.21.57–59)）。Electrical Power Up では DEMAND 全 OFF（FCOM p.179 (SP.6.1)）。
  - エンジン停止・電源投入状態で demand セレクタを OFF にしておくのは、抽気がかかったとき ADP が不意に回らないため（ATA29_32 p.62 (29)）。

### 3.2 他のパネル

- エンジン fire switch（引く）：SOV 閉、EDP 減圧（他に燃料弁・抽気弁・発電機など）（FCOM p.905 (8.10.1)）。関連 demand pump が運転する（FCOM p.1490 (13.20.2)）。
- FUEL CONTROL switch CUTOFF：AUTO の demand pump に運転を指令（FCOM p.860 (7.13.2)）。
- FLT CONTROL HYD POWER（overhead maintenance panel）：系統ごとに TAIL と WING の NORM / SHUT OFF、VALVE CLOSED 灯（FCOM p.940 (9.10.14)、ATA22 p.18）。
- STAB TRIM cutout（ON / AUTO / CUTOUT、系統 2 と 3）（FCOM p.928 (9.10.2)、p.945 (9.20.5)）。
- 機長パネル：BRAKE SOURCE 灯（系統 4・1・2 すべて低圧）と BRAKE ACCUMULATOR PRESSURE 計（FCOM p.1503–1504 (14.10.5–6)）。

### 3.3 STATUS 画面（FCOM p.1485 (13.10.3)、ATA29_32 p.102 (29)）

- HYD QTY（正規量 1.00 に対する比、例 `0.75RF`、`0.34LO`）、HYD PR（psi）、HYD TEMP（°C）。
- RF（マゼンタ）：地上で補給が必要。空中は出さない（FCOM p.1489 (13.20.1)）。LO（マゼンタ）：量低。LO は RF に置き換わる。
- 油圧の STATUS メッセージも出る（§3.6）。

### 3.4 HYD synoptic（FCOM p.1486–1488 (13.10.4–6)、ATA29_32 p.104–109 (29)）

- 流れの表示は、弁位置・ポンプ状態・油量から作った絵で、実際の流れではない（FCOM p.1486）。流れ線は緑（ATA29_32 p.109 図）。
- 各系統：EDP の箱、DEM の丸、SOV の丸（流路の向きで開閉）、系統 4 の AUX の丸、リザーバの液面、数値（QTY、PRESS、TEMP）、RF/LO（マゼンタ）、RSVR PRESS（白）。
- 状態と色（ATA29_32 p.107–108 (29)）：
  - DEM：ON 白＝ON で圧正常、または AUTO で運転中かつ圧正常。ON 琥珀＝ON で圧低。AUTO 琥珀＝AUTO で運転中かつ圧低。AUTO シアン＝AUTO で停止中。OFF 琥珀＝セレクタ OFF。
  - EDP：ON 白＝ON で圧正常（FCOM の図では空の箱）。ON 琥珀＝ON で圧低。OFF 琥珀＝スイッチ OFF。FCOM は「OFF＝EDP が動いていない」（FCOM p.1487 (13.10.5)）。
  - AUX：ON 白＝AUX で EDP 圧低（運転中）。ON 琥珀＝AUX で EDP 圧低（E&M の記述が白と同じ条件で、区別は `資料に記載なし`）。ON シアン＝AUX で EDP 圧正常（待機）。OFF 白＝AUX 以外。
  - データ無効時は白い箱か丸。
  - QTY は白、TEMP と PRESS は白／琥珀（ATA29_32 p.109 図）。琥珀にする閾値は `資料に記載なし`（EICAS の閾値 1200 psi・104 °C に合わせると `推定`）。
- QTY 0.00 は EDP のスタンドパイプの高さ。そこから下に外側（1・4）1.12 gal、内側（2・3）1.30 gal が残り、demand pump だけが使える（ATA29_32 p.104 (29)）。
- 不作動項目（405）：1 系統が失われると、その系統の絵の上に使えなくなった項目を出す。複数系統なら、共通する項目をさらに上に出し、線で失われた系統につなぐ（FCOM p.1490 (13.20.2)）。例：系統 2・3 喪失で ELEV FEEL / STAB TRIM（共通）、AUTOPILOT R・SPLR 2,3,10,11・YAW DAMPER LWR・THRUST REV、AUTOPILOT L・SPLR 1,4,9,12・YAW DAMPER UPR・THRUST REV（FCOM p.1487 (13.10.5)）。

### 3.5 EICAS メッセージ

| メッセージ | レベル | 条件 | 典拠 |
|---|---|---|---|
| HYD PRESS SYS 1–4 | Caution（beeper） | 系統圧低。内部は系統圧 < 1200 psi が 2 秒 | FCOM p.1495 (13.30.1)、ATA29_32 p.98・141・143 (29) |
| HYD PRESS ENG 1–4 | Advisory | EDP 出口圧低（< 1400 psi が 2 秒）。HYD PRESS SYS で抑止。地上で該当 FUEL CONTROL が CUTOFF か fire switch が引かれていれば抑止（FCOM）。E&M の論理は CUTOFF で抑止（空地の区別なし） | FCOM p.1495、p.1586 (15.20.40)、ATA29_32 p.141・143 |
| HYD PRESS DEM 1–4 | Advisory | セレクタ OFF、または運転指令中で出口圧 < 1400 psi が 2 秒、または系統 4 が AUX。HYD PRESS SYS で抑止 | FCOM p.1495、ATA29_32 p.141・143 |
| HYD OVHT SYS 1–4 | Advisory | 油温過大（ケースドレン油温 > 104 °C） | FCOM p.1495、ATA29_32 p.100 (29) |
| >HYD QTY LOW 1–4 | Advisory | 量低（LO、0.34） | FCOM p.1495、ATA29_32 p.116 (29) |
| HYD CONTROL 1, 4 | Advisory | 油圧制御系統の不作動。demand pump の自動切替（または油圧系統）が使えないことがある。発生条件の詳細は `資料に記載なし`（§4.2 末尾） | FCOM p.1495 |
| >BRAKE SOURCE | Caution（beeper） | 系統 1・2・4 からのブレーキ圧がすべて低 | FCOM p.1521 (14.30.1)、ATA29_32 p.392 (32-41) |

- 系統圧低は B レベル、他は C レベル。系統圧低・量低・ポンプ圧低・過熱では、対応する琥珀の灯もパネルに点く（ATA29_32 p.134 (29)）。
- 個々のポンプ圧メッセージは系統圧メッセージで抑止（FCOM p.1582 (15.20.36)）。
- 地上で全 FUEL CONTROL が CUTOFF のとき、Caution の master caution 灯と beeper は出ない（FCOM p.1586 (15.20.40)）。エンジン始動中（START switch を引いてからアイドル到達・中止・5 分経過まで）は新しい Caution/Advisory を抑止（同頁、p.1587）。これらは EICAS 共通の規則で、実装は ATA 31 側。
- `>HYD QTY LOW 1` と `>HYD QTY LOW 4` は、ブレーキ系の漏れで系統 4→1→2 と連続して失う事例のため手順付きになり、IDS 更新で caret を外す予定（FCOM p.65–66、TB1-26）。LO 表示から系統が使えなくなるまで少なくとも 35 分（同）。

### 3.6 STATUS メッセージ

- 種類：各 EDP の圧、各 demand pump の圧、系統の過熱、リザーバ与圧の故障、HYDIM バス不作動（ATA29_32 p.136 (29)）。過熱は空中では NVM に記録（ATA29_32 p.100 (29)）。
- メッセージの文言は `資料に記載なし`。

## 4. 内部ロジック

以下の論理式は HYDIM の論理図（ATA29_32 p.141（系統 1・4）、p.143（系統 2・3）、p.89（AUX））と本文を合わせたもの。`T↑a`＝立ち上がり遅れ a 秒、`T↓b`＝立ち下がり遅れ b 秒。

### 4.1 圧力スイッチ

- EDP 圧スイッチ：EDP 出口圧が 1400 psi まで下がると「低」、1600 psi まで上がると解除（ヒステリシス）（ATA29_32 p.61 (29)）。demand 圧スイッチも 1400 psi（ATA29_32 p.141）。解除値の記述は EDP のみで、demand も同じと `推定`。
- 各スイッチは逆止弁で自分のポンプの出口だけを見る（ATA29_32 p.78 (29)）。→ AUX や demand pump が系統を加圧しても EDP スイッチは「低」のまま。この性質が demand pump の連続運転と AUX の動作の前提になる。
- 系統圧トランスミッタ：アナログ値。< 1200 psi が閾値（ATA29_32 p.98 (29)）。

### 4.2 系統 1・4（ADP）（ATA29_32 p.29・61–64 (29)、p.141 図、p.63 図）

```
ADP_RUN = ON                                             -- continuous run ソレノイド（HYDIM を通らない）
        | AUTO & GND & FLAPS_IN_TRANSIT(FCU)
        | AUTO & AIR & T?10(FLAP_POS>0(FCU))             -- 10 秒タイマー。立ち上がりか立ち下がりかは図から判別できない
        | AUTO & FUEL_CUTOFF                             -- continuous
        | T↑0.3/T↓14(AUTO & EDP_PS_LOW)                  -- run-on-demand ソレノイド
条件：28V DC（HYD n DEMAND CB）、抽気ダクト圧、過回転トリップしていないこと
```

- フラップ信号は系統 1 が右 FCU、系統 4 が左 FCU から。3 台の FCU は同じ物だが、この機能は左右の取付位置の FCU だけが持ち、FCU 間で移らない。左右の FCU が不作動なら、乗員が離着陸で ON を選ぶ（ATA29_32 p.61–62 (29)）。
- P&W・GE 機の説明：空中でフラップが出ていれば連続運転、地上ではフラップがレバーに一致するまで運転（ATA29_32 p.61 (29)）。FCOM も「フラップ移動中、または空中でフラップが UP 以外」（FCOM p.1483 (13.10.1)）。
- 食い違い：ATA29_32 p.64 は「空中でフラップレバーが 0 より大」、p.62 は「フラップレバー 5 以上」と書く。論理図（FCU のフラップ位置 > 0°）と FCOM に従う。
- 10 秒タイマーの種類は `資料に記載なし`。`推定` で「立ち下がり遅れ（空中でフラップが UP に戻ってから 10 秒運転を続ける）」とし、試験で決める。
- 空地は「AIR/GROUND ALT RELAY R183」（ATA29_32 p.63 図）。
- HYD CONTROL 1・4：ON の経路は HYDIM を通らないので、HYDIM が働かないと AUTO の自動切替だけが失われる（p.63 図、p.141 図）。HYD CONTROL を HYDIM 1・4 の電源喪失か故障、または FCU からのフラップ信号喪失で出すのは `推定`（FCOM の文言が「自動切替が使えない」なので）。

### 4.3 系統 2・3（ACMP）（ATA29_32 p.30・70–72 (29)、p.143 図）

```
ON'   = T↑d(ON)、AUTO' = T↑d(AUTO)        d = 1.5 s（系統 2）、3.0 s（系統 3）。OFF から AUTO/ON に動かしたとき
ACMP_RUN = ON' | AUTO' & FUEL_CUTOFF | T↑0.3/T↓14(AUTO' & EDP_PS_LOW)
ELCU が閉じても、AC bus 2/3 が無ければモーターは回らない（→ 圧低で PRESS 灯）
```

- 遅れは 2 台の同時起動を避けるため。始動電流 167 A、運転 45 A（ATA29_32 p.70 (29)）。
- ON 経路も HYDIM を通らない（p.143 図）。

### 4.4 系統 4 の AUX ポンプ（ATA29_32 p.86–88 (29)、p.89 図、FCOM p.1483）

```
AUX_RUN = AUX & GND & GH_BUS_AC & GH_BUS_DC & EDP_PS_LOW & DEM_PS_LOW
```

- AUX では ADP は止まる（FCOM p.1483）。EDP が加圧すると止まり、EDP 圧が下がれば再び回る。セレクタは AUX のまま（同）。
- 主用途は牽引時のブレーキ（ATA29_32 p.30・82 (29)）。系統全体を加圧する（ATA29_32 p.30）。

### 4.5 EDP（ATA29_32 p.44–48 (29)、p.141 図下段）

```
EDP_DEPRESS = (EDP_SW == OFF & FIRE_SW == NORMAL) | (EDP_SW == ON & FIRE_SW == FIRE)   -- 実質 OFF か fire
SOV_CLOSE   = FIRE_SW == FIRE
EDP 出口圧  = 加圧中かつ SOV 開かつ供給あり（量 > 0.00）なら、N2 に応じた流量能力の範囲で系統要求を満たす
```

- fire switch を引くと SOV が閉じ、EDP が減圧し、関連 demand pump が運転（FCOM p.1490 (13.20.2)）。demand pump が回るのは EDP 圧スイッチ「低」による（AUTO のとき）。
- 減圧ソレノイドは 28V DC で励磁して OFF にする。DC を失うと EDP は加圧側に戻ると `推定`（ON＝非励磁、ATA29_32 p.44 (29)）。
- 風車回転：全エンジン推力喪失でも風車回転の EDP で操縦できる（最低 160 kt）。脚下げに最大 2.5 分、フラップは不作動（FCTM p.286 (8)）。→ EDP の流量能力は N2 に比例させ、低い N2 では「圧は保つが流量が小さい」振る舞いにすべき（N2 とポンプ回転数の関係は `資料に記載なし`、比例とするのは `推定`）。

### 4.6 HYDIM の出力（灯・EICAS）

```
EDP_LOW_2s  = T↑2(EDP_PS_LOW)
SYS_LOW_2s  = T↑2(SYS_PRESS < 1200)
DEM_LOW_2s  = T↑2(DEM_COMMANDED & DEM_PS_LOW)      -- 1・4：ADP の SOV が閉でない、2・3：ELCU が閉
ENG PRESS 灯       = EDP_LOW_2s
HYD PRESS ENG      = EDP_LOW_2s & !FUEL_CUTOFF & !SYS_LOW_2s  (+ 地上で fire switch out なら抑止：FCOM)
DEM PRESS 灯       = DEM_SEL == OFF | DEM_SEL == AUX | DEM_LOW_2s
HYD PRESS DEM      = DEM PRESS 灯の条件 & !SYS_LOW_2s
SYS FAULT 灯       = SYS_LOW_2s | QTY_LO | TEMP > 104 °C
HYD PRESS SYS      = SYS_LOW_2s
HYD OVHT SYS       = TEMP > 104 °C
>HYD QTY LOW       = QTY_LO
```

- ENG PRESS 灯は CUTOFF で抑止しない。系統 1・4 の図（p.141）は灯を抑止の前から取り、系統 2・3 の図（p.143）は抑止の後から取っている。FCOM の Preflight でエンジン停止中に ENGINE PRESS 灯が点灯することを確認する（FCOM p.104 (NP.21.10)）ので、全系統で p.141 の形に従う。
- 「指令したのに回らない」も DEM PRESS 灯の条件（FCOM p.1484 (13.10.2)）。上の DEM_LOW_2s で表せる。

### 4.7 系統圧（モデル化の方針）

- 資料にある値：無流量 3000 psi（2800–3200）、リリーフ 3500 psi、各ポンプの定格流量（§2.3）。
- 圧力の時間変化（ポンプ停止後の減衰、流量不足時の降下の仕方）は `資料に記載なし`。実装は、系統の流量需要（舵面・脚・フラップ・ブレーキ・逆推力の動作量から算出）と利用できるポンプ能力の和を比べ、能力が足りれば 3000 psi 付近、不足すれば比例して下げ、供給が無ければ時定数で減衰させる、という簡単なモデルで十分（`推定`）。
- ポンプ出口圧（synoptic の `edp_pressure_n`・`dem_pressure_n`・`aux_pressure`）はポンプが加圧していれば系統圧と同程度、止まっていれば 0。

### 4.8 作動油量（ATA29_32 p.104・114–116 (29)、FCOM p.1489）

- 表示は正規量 1.00 に対する比。OF（≥ 1.15、整備ページのみ、地上のみ）、RF（≤ 0.75、STATUS・synoptic・整備ページ、地上のみ）、LO（≤ 0.34、SYS FAULT 灯と >HYD QTY LOW）。
- 量は温度と作動機器の動作で変わる（FCOM p.1489）。実装では、脚・ブレーキ・フラップの作動で少し下がる程度で十分（`推定`）。
- 0.00 で EDP の吸入が尽き、demand pump（と AUX）は残量 1.12/1.30 gal を使える（ATA29_32 p.104）。
- HYQUIM の過電圧故障で、全 4 系統の SYS FAULT 灯の点滅、>HYD QTY LOW の出入り、量表示の増減が起こる（FCOM p.1490 (13.20.2)）。故障モードとして任意。

### 4.9 油温

- ケースドレン油温（熱交換器入口）を測る（ATA29_32 p.100 (29)、ATA22 p.21）。> 104 °C（220 °F）で SYS FAULT、advisory、STATUS（ATA29_32 p.100・126 (29)）。
- 熱交換器はメインタンク内。地上で 15 分を超えてポンプを回すにはタンクに最低燃料が要る（§1 の食い違い参照）。
- 温度上昇の速さ、通常値（FCOM の例は 50 °C）以外は `資料に記載なし`。実装は「外気温 + ポンプ運転による発熱 − 燃料による冷却」の 1 次遅れで十分で、タンク燃料が最低量を下回ると冷却が落ちる、程度にする（`推定`）。

### 4.10 リザーバ与圧

- 抽気ダクト圧 → 約 45 psi に調圧（ATA29_32 p.38 (29)）。6.3 psig 未満で RSVR PRESS（synoptic）と STATUS（ATA29_32 p.38・104 (29)）。
- 与圧はポンプのキャビテーションを防ぐため（FCOM p.1489 (13.20.1)）。与圧低下がポンプ性能に与える影響は `資料に記載なし`（表示だけで十分）。

### 4.11 ブレーキ源（油圧側。制御則は ATA 32）（ATA29_32 p.384–418 (32-41)、FCOM p.1514–1516）

- 系統 4 が normal。系統 4 < 1200 psi で系統 1 を選ぶ。さらに系統 1 < 1500 psi で系統 2 を選ぶ。選択は圧力作動弁で自動（ATA29_32 p.390 (32-41)）。
- 系統 4・1・2 がすべて低圧で、accumulator 隔離弁が開いて accumulator から供給（ATA29_32 p.388・390 (32-41)）。accumulator は系統 4 が充圧、200 in³、窒素予圧 750 psi。パーキング用で、機体を止める能力は無い（ATA29_32 p.408 (32-41)、FCOM p.1516 (14.20.6)）。
- BRAKE ACCUMULATOR 計は accumulator 圧を示す（ATA29_32 p.410 (32-41)）。予圧 750 psi なので、作動油が無くても計器は 0 にならないと `推定`（トランスミッタが窒素側にある、p.408）。
- BRAKE SOURCE：系統 4 用と系統 1/2 用の 2 つの圧力スイッチを直列にして判定（ATA29_32 p.392 (32-41)）。スイッチの作動圧は `資料に記載なし`（1200/1500 psi に合わせるのは `推定`）。
- autobrake は normal 系統でのみ働き、normal ブレーキ圧を失うと解除（FCOM p.1515–1516 (14.20.5–6)）。

### 4.12 その他

- auto event（整備ページ）：系統圧 < 1200 psi、量 < 35 %、油温 > 104 °C。全エンジン運転中かつパーキングブレーキ解除のときだけ記録（ATA29_32 p.126・134 (29)）。CMC が無いので実装不要。
- 牽引時はノーズギアステアリングをロックアウトしてから油圧を加圧・変化させる（FCOM p.119 (NP.21.25)、p.152 (NP.21.58)）。ステアリング側の論理は ATA 32。

## 5. 他系統とのつながり

| 方向 | 相手 | 内容 | 典拠 |
|---|---|---|---|
| 入力 | エンジン（ATA 72/77） | N2（EDP 流量能力）。エンジン停止で EDP 停止 | FCOM p.1489 |
| 入力 | 燃料（ATA 28） | FUEL CONTROL switch（CUTOFF で demand 運転指令、HYD PRESS ENG 抑止）。メインタンク燃料量（熱交換器） | FCOM p.860、ATA29_32 p.76 |
| 入力 | 火災（ATA 26） | エンジン fire switch（SOV 閉、EDP 減圧） | FCOM p.905 |
| 入力 | 電源（ATA 24） | DC bus 1–4（制御、HYDIM、ソレノイド）、AC bus 2/3（ACMP）、ground handling bus AC/DC（AUX） | §2.5 |
| 入力 | 抽気（ATA 36） | 左右ダクト圧（ADP 1/4、リザーバ与圧） | §2.5 |
| 入力 | 空地（ATA 32-09） | GND/AIR（ADP のフラップ論理、AUX、EICAS 抑止） | ATA29_32 p.63 図・p.88 |
| 入力 | フラップ（ATA 27-50） | 右 FCU → 系統 1、左 FCU → 系統 4：TE flap 移動中、TE flap > 0、FCU 有効 | ATA29_32 p.61–64 |
| 出力 | 舵面（ATA 27） | 系統ごとの圧（§2.4 の組で「動力あり」を判定）。stab trim、elev feel、YD | §2.4 |
| 出力 | AFDS（ATA 22） | AP サーボ L/C/R の圧（系統 3/1/2） | FCOM p.1490 |
| 出力 | 脚・ブレーキ・ステアリング（ATA 32） | 系統 1・4 の圧、ブレーキ源圧、accumulator 圧、BRAKE SOURCE | §4.11 |
| 出力 | 逆推力（ATA 78） | P&W：関連系統の圧。GE：抽気 | FCOM p.893 |
| 出力 | 電源 | ACMP の負荷（始動 167 A、運転 45 A） | ATA29_32 p.70 |
| 出力 | 抽気 | ADP とリザーバ与圧の消費（量は `資料に記載なし`） | — |
| 出力 | EICAS（ATA 31） | §3.5・§3.6、synoptic・STATUS の値 | — |

## 6. 実装上の注意

### 6.1 X-Plane の油圧モデルとの関係（ACF_DIFF §3.5・§4.5）

- 両 acf とも X-Plane の油圧モデルは有効：エンジンポンプはエンジン 1・4 → 系統 1（A）、2・3 → 系統 2（B）（`acf/_hyd_engn_pump_0123` = 1,2,2,1）。電動ポンプ 1 台が両系統（`acf/_hyd_ele_pump_0123/0` = 3）。脚・ブレーキ・ノーズステアリング・フラップ・スラット・操縦系が油圧依存（`acf/_hyd_gear`・`_hyd_brakes`・`_hyd_nw_steer`・`_hyd_flaps`・`_hyd_slats`・`_hyd_flightcons` = 3）。油圧喪失時の操縦系とブレーキの残存比（Plane Maker の manual reversion）は 1.0（`acf/_no_hydro_force_mult_flcons`・`_brakes`）。脚の油圧故障時の振る舞いは `_hyd_gear_fail_mode` 2・`_hyd_gear_fail_speed` 200 で、「200 KIAS 未満なら下げて固定」と `推定`（Plane Maker Manual の 3 択の説明と速度値から）。これらは 2 つの acf で同じ。
- カスタム acf だけが舵面ごとの系統（`_wing/n/_*_hyd0123`）を持つ。値は 1・2・5・6。X-Plane 12 の油圧は A/B/C の 3 系統（DataRefs.txt の `engine_pumpA/B/C`、`hydraulic_pressure_1/2/3`）なので、ビット 1=A、2=B、4=C と `推定`。C にはポンプが割り当てられていない。
- 舵面への影響：プラグインは毎フレーム `override_control_surfaces` = 1 にし（`B747.19.xt.hydraulics_override.lua:1119`）、舵面角を自分で書く。manual reversion も 1.0。したがって、カスタム acf の舵面別割り当ては舵面の動きに効かない見込み（`推定`、要確認）。コードは acf の `_hyd*` を読まない。
- 舵面以外への影響（こちらが問題）：
  - `B747.20.xt.hydraulics.lua:245-280` が ENGINE pump スイッチに合わせて `sim/operation/failures/rel_hydpmp`〜`rel_hydpmp4` を毎フレーム 0/6 に書く。XP12 ではこれは「Hydraulic System 1〜4 (pump fail)」（DataRefs.txt）で、エンジン単位ではない。さらに `electric_hydraulic_pump_on` = 1 を毎フレーム書く（同 286-325）。
  - 結果：X-Plane 側の油圧はほぼ常に加圧され、X-Plane が自前で動かす脚（`B747.10.xt.gear.lua` は X-Plane の gear handle を使う）、ブレーキ、20 kt 未満のノーズステアリング（override 0 のとき）は、プラグインの 4 系統モデルと無関係に動く。
  - 逆に、ENGINE pump 1・2 を OFF にすると X-Plane の系統 A・B のポンプ故障になり、電動ポンプが救わなければ脚の「200 KIAS 未満で下げ」が発動しうる（未確認）。
  - 利用者が X-Plane の故障メニューで設定したポンプ故障は毎フレーム上書きされる。
- 推奨：X-Plane の油圧は「常に加圧、故障を書かない」に固定し（`rel_hydpmp*` を書くのをやめ、電動ポンプ ON は維持）、油圧による制限はすべてプラグイン側で行う。脚・ブレーキの制限手段は ATA 32 担当が選ぶ（候補：`override_gearbrake`、`override_toe_brakes`、`sim/aircraft/parts/acf_gear_deploy`、`rel_lagear*`。意味は DataRefs.txt の説明からの `推定`）。カスタム acf の `_hyd0123` は 0 に戻してよい（承認事項）。

### 6.2 表示（acf のパネル定義）の制約

- HYD synoptic と STATUS は acf 末尾の generic instrument で、純正 acf は変えられない。使える dataref と見え方は次のとおり（`747-400.acf:136170-137410` 付近、STATUS は `:129397` 付近）：
  - `pressure_n` > 2000 で系統の流れ線、< 2000 で不作動項目の絵（`fail1`〜`fail4`）。`edp_pressure_n`・`dem_pressure_n`・`aux_pressure` > 2000 でポンプの流れ線。
  - `dem_mode_n`：1 で AUTO の文字、0 で OFF の文字（系統 4 は `SHOW_LESS 0` なので AUX（-1）で OFF、OFF（0）では何も出ない）。ON（2）の文字の画像は無い。色の変化も無い。
  - `valve_n`：> 0.95 で SOV 開、< 0.1 で SOV 閉と EDP OFF を同時に出す（1 つの dataref で 2 つの意味）。
  - `pressure_13`・`pressure_23`・`pressure_24`・`pressure_234` < 2000 で複数系統の不作動項目の絵。絵の文字は実際の組み合わせと一部合わない（例：`fail13` の絵に 1+2 の項目 L OUTBD AIL・L INBD ELEV が入る、`fail24` に BRAKES、`fail234` は 3+4 の項目）。`fail12` の絵はあるが参照されていない。
  - `res_n`（液面と数値）、`temp_n`、`pressure_dsp_n`、`laminar/B747/EICAS2/stat/RF[n]`・`LO[n]`。
  - RSVR PRESS の画像（`rsvr_press-1.png`）はあるが、計器として配置されていない。
- **INTERFACES.tsv の漏れ**：上の `valve_n`、`dem_mode_n`、`dem_pressure_n`、`edp_pressure_n`、`aux_pressure`、`pressure_13/23/24/234`、`EICAS2/stat/RF`・`LO` は `SHOW_*` 条件や配列添字付きで参照されているため INTERFACES.tsv に載っていない。作り直しでもこれらの名前と意味を保つこと。`pressure_n` も「> 2000 で流れ線」の閾値つきで使われている。
- 3D コクピットの BRAKE ACCUMULATOR 計は `laminar/B747/hydraulics/indicators/hydraulic_pressure_1_2_4`（0–4000 psi、`objects/747_cockpit/Cockpit_Panel.obj:32424`）。

### 6.3 簡略化してよいもの・いけないもの

- してよい：圧力の時間変化の細部、流量の厳密計算（需要と能力の比較で十分）、ADP の加速・過回転、温度の物理、量の細かい変動、CMC と auto event、HYQUIM の故障表示。
- してはいけない：§4.2–4.6 の論理と閾値・タイマー（乗員の操作と表示に直結）、fire switch と SOV、電源・抽気への依存、§2.4 の負荷の組（片系統喪失で何が残るか）、RF の地上限定、ブレーキ源の順序、系統 4 先行加圧の意味（パーキングブレーキ）。
- 圧力を他モジュールに渡すとき、舵面の「動力あり」判定の閾値は `資料に記載なし`。現状は 900 psi（`B747.19.xt.hydraulics_override.lua:185`）、AP は 1000 psi（`B747.70.xt.autopilot.lua:2480-2497`）、ステアリングは 1000 psi。統一した定数（例：1000 psi、`推定`）を 1 か所に置く。

### 6.4 コード構造上の注意

- `B747.19.xt.hydraulics_override.lua` の大半（概ね 342–1104 行）は AFDS の FD・AP サーボ PID・ヨーダンパー則・スラットで、油圧ではない（OLD_FORK_NOTES.md §13 も同じ構造を指摘）。油圧部分を作り直す前に、これらを別ファイルに分けて担当（ATA 22/27）に渡すのが安全。
- `after_physics` の順序（圧力計算 → 消費 → 舵面）を保つ。同じ値を 2 つのモジュールが初期化している（`restotal_n`：`B747.19.xt.hydraulicsmodel.lua:706-713` と `B747.20.xt.hydraulics.lua:439-450`）ので、所有者を 1 つにする。
- quick start（`B747.95.xt.AI.lua`）はセレクタを途中の位置を通らずに直接書く（AUX -1 → AUTO 1、`:1608`・`:2398`）。新しいモデルは「前フレームの位置」に頼らないこと。

## 7. 現状実装との比較（GAP 候補）

ファイル名は一意なので名前だけ書く。`B747.19.xt.hydraulicsmodel.lua`・`B747.19.xt.hydraulics_override.lua`・`B747.20.xt.hydraulics.lua`・`B747.60.xt.fltInst02.lua`・`B747.70.xt.autopilot.lua`・`B747.90.xt.lighting.lua` は `plugins/xtlua_keysystems/scripts/<モジュール>/` 配下、`B747.10/40/45/87/95.*` は `plugins/xtlua/scripts/<モジュール>/` 配下。

| ID | 種別 | 重要度 | 規模 | 内容 | 根拠 | 該当コード |
|---|---|---|---|---|---|---|
| HYD-01 | 挙動の誤り | 高 | M | EDP 圧を `40×N1` で出している。アイドル（N1 20 % 台）で 1000 psi 前後、停止で 0、風車回転では使えない。実機は圧力補償型で、回っていれば約 3000 psi、流量能力が N2 に比例。fire switch・SOV・量（スタンドパイプ）も見ていない。系統圧も最大 3300 psi・毎フレーム最大 50 psi の乱数、ポンプ停止で数秒で 0 になる作り | ATA29_32 p.26・44、ATA22 p.6、FCTM p.286 | `B747.19.xt.hydraulicsmodel.lua:384-408`、`:478-497` |
| HYD-02 | 挙動の誤り | 高 | M | demand pump の AUTO が「EDP < 2500 psi」だけ。1400/1600 psi のスイッチ、0.3 s/14 s タイマー、FUEL CONTROL CUTOFF での運転、系統 1・4 のフラップ論理（地上で移動中、空中で > 0、右/左 FCU）が無い。HYD-01 と合わせ、アイドルでは demand pump が常時回る | ATA29_32 p.29–30・61–64・70–72・141・143、FCOM p.1483 | `B747.19.xt.hydraulicsmodel.lua:410-455` |
| HYD-03 | 欠落 | 高 | M | demand pump の電源・抽気依存が無い。ACMP 2/3 は常に 3000 psi（AC bus 2/3、DC 制御、HYDIM 電源を見ない）。1.5/3.0 s の始動遅れ、電気負荷も無い。ADP は `duct_pressure×110` で、DC bus 1/4 の制御電源を見ない（調速されず、ダクト圧に比例） | ATA29_32 p.63 図・p.70–71・p.54、ATA22 p.22・24 | `B747.19.xt.hydraulicsmodel.lua:411-446` |
| HYD-04 | バグ | 高 | S | AUX：セレクタが AUX なら空地・ground handling bus・EDP 圧に関係なく 2950 psi。AUX から OFF を経ずに AUTO/ON に移ると `aux_pressure` が 0 に戻らない（OFF の分岐でしか 0 にしない）。quick start がまさに -1 → 1 と書くので、以後ずっと系統 4 が AUX で加圧され synoptic に AUX の流れが出る | ATA29_32 p.86–88、FCOM p.1483 | `B747.19.xt.hydraulicsmodel.lua:448-462`、`B747.95.xt.AI.lua:2398` |
| HYD-05 | 欠落 | 高 | S | エンジン fire switch が油圧に何もしない（SOV 閉、EDP 減圧、demand pump 起動）。synoptic の SOV（`valve_n`）は ENGINE pump スイッチの位置をそのまま出している | FCOM p.905・p.1490、ATA29_32 p.40・44–48 | `B747.19.xt.hydraulicsmodel.lua:344-375` |
| HYD-06 | 挙動の誤り | 高 | S | 舵面の系統の組の誤り：upper rudder が 1+2（正：1+3）、L INBD AIL が 1+2（正：1+3）、R OUTBD AIL が 2+3+4（正：3+4）。L OUTBD AIL 1+2、R INBD AIL 2+4、昇降舵 4 枚、lower rudder 2+4、spoiler 3 群は正しい | FCOM p.948・950・1491 | `B747.19.xt.hydraulics_override.lua:296`、`:319`、`:331` |
| HYD-07 | バグ | 低 | S | spoiler 8 の消費量に lower rudder の変化量（`controlDiff[1]`）を使っている（正：`controlDiff[18]`） | — | `B747.19.xt.hydraulics_override.lua:266` |
| HYD-08 | バグ | 中 | S | X-Plane の `rel_hydleak3` 処理で `hydfailed3` ではなく `hydfailed2` を立てる。毎フレーム故障先（系統 3 か 4）と速さを選び直し、結局 3 と 4 の両方が抜ける | — | `B747.19.xt.hydraulicsmodel.lua:775-779` |
| HYD-09 | 欠落 | 高 | M | ブレーキが油圧源で制限されない。normal（4）→ alternate（4 < 1200 で 1、さらに 1 < 1500 で 2）→ accumulator の選択も、autobrake の normal 系統依存も無い。ブレーキは X-Plane の標準（X-Plane 側の油圧は常に加圧、§6.1）。BRAKE SOURCE だけは 1・2・4 < 1000 psi で出す。ATA 32 と調整 | ATA29_32 p.388–392、FCOM p.1514–1516 | `B747.10.xt.gear.lua:727-734`、`B747.20.xt.hydraulics.lua:339-344`、`B747.90.xt.lighting.lua:1375-1376` |
| HYD-10 | 挙動の誤り | 中 | S | brake accumulator（計器 `hydraulic_pressure_1_2_4`）を系統 1・2・4 の最大値で充圧（正：系統 4 のみ）。減るのはパーキングブレーキを掛けた量だけで、0 まで下がる（予圧 750 psi は下回らない `推定`）。< 1000 psi でパーキングブレーキを外す処理が fltCtrls 側にある | ATA29_32 p.408–416、FCOM p.1516 | `B747.19.xt.hydraulicsmodel.lua:503`、`B747.19.xt.hydraulics_override.lua:198-213`、`B747.45.xt.fltCtrls.lua:1056` |
| HYD-11 | 欠落 | 高 | L | 舵面以外の負荷が 4 系統モデルで止まらない：脚（nose/body 1、wing 4。X-Plane 標準の gear handle）、逆推力（P&W は関連系統。`hydraulic_pressure_ratio` を宣言したが未使用）、stab trim（2/3、X-Plane 標準のトリム）、elev feel（2/3）、YD（上 3/下 2。ON 条件に油圧が無い）。油圧側は「動力あり」信号を出し、各担当が使う | FCOM p.893・943・945・949・1511、§2.4 | `B747.10.xt.gear.lua:146-170`、`B747.40.xt.engines.lua:142-143`、`:351`、`B747.45.xt.fltCtrls.lua:715-738` |
| HYD-12 | 挙動の誤り | 中 | S | 系統 1 < 1000 psi でステアリングを override したまま何も書かず、前輪が直前の角度で固まる（正：操向不能。前輪はセンタリングか自由キャスター `推定`）。20 kt の切替に IAS を使う（FCOM は対地速度、ATA 32）。低速で override 0 のとき acf の `_steerdeg_*`（custom 75/35、純正 70/7）が効く | FCOM p.1513、FCTM p.297 | `B747.19.xt.hydraulics_override.lua:1123-1136` |
| HYD-13 | 挙動の誤り | 中 | S | X-Plane 油圧への干渉（§6.1）：ENGINE pump スイッチで `rel_hydpmp`〜`rel_hydpmp4`（XP12 では系統単位のポンプ故障）を毎フレーム書き、電動ポンプを常時 ON。故障メニューの上書き、ENG 1・2 OFF で脚の下げ固定が起きる恐れ（未確認）。ENGINE PRESS 灯もこの故障 dataref をスイッチ代わりに読む | DataRefs.txt、acf `_hyd_*` | `B747.20.xt.hydraulics.lua:245-325`、`B747.90.xt.lighting.lua:1122-1125` |
| HYD-14 | 挙動の誤り | 高 | S | パネル灯：ENGINE PRESS＝エンジン停止かスイッチ OFF（正：EDP 圧 < 1400 が 2 秒）。DEMAND PRESS＝セレクタ OFF のときだけ（正：OFF・AUX・指令中の圧低・不始動。Before Start で「AUX で点灯のまま」を確認できない）。SYS FAULT＝< 1000 psi か量 < 0.1（正：< 1200 psi 2 秒、量 0.34、> 104 °C） | FCOM p.1483–1484・p.119、ATA29_32 p.30・98・141 | `B747.90.xt.lighting.lua:1121-1125`、`:1414-1424` |
| HYD-15 | 欠落 | 高 | S | EICAS：HYD PRESS ENG・HYD PRESS DEM・HYD OVHT SYS・HYD CONTROL は定義だけで一度も立たない。HYD PRESS SYS は 1000 psi・遅れ無し（正：1200 psi・2 秒）。抑止（SYS による ENG/DEM の抑止、CUTOFF・fire switch）も無い | FCOM p.1495・1582・1586、ATA29_32 p.98・141・143 | `B747.20.xt.hydraulics.lua:346-366`、`B747.87.xt.warning.lua:386-399` |
| HYD-16 | 挙動の誤り | 中 | S | 作動油量：飛行開始ごとに 0.55–0.95 の乱数（2 モジュールが別々に初期化し、後から走る B747.20 が勝つ）→ RF が頻繁に出る（正規量は 1.00）。RF を空中でも出す（正：地上のみ）。LO（< 0.35）では SYS FAULT 灯が点かない（灯は量 < 0.1、HYD-14）。量の変化は「圧 3000 psi で -0.10」だけ | FCOM p.1485・1489、ATA29_32 p.116 | `B747.20.xt.hydraulics.lua:376-389`、`:439-450`、`B747.19.xt.hydraulicsmodel.lua:499-502`、`:706-713` |
| HYD-17 | 挙動の誤り | 低 | M | 油温＝外気温 + (1 − 量)×20。ポンプ運転や熱交換器（タンク燃料）と無関係で、104 °C に届かず過熱が起こりえない | ATA29_32 p.74–76・100 | `B747.19.xt.hydraulicsmodel.lua:505-508` |
| HYD-18 | 欠落 | 低 | M | リザーバ与圧（抽気、45 psi、< 6.3 psig で RSVR PRESS と STATUS）が無い。synoptic への表示は計器追加（カスタム acf のみ、承認事項）が要る | ATA29_32 p.38・104、FCOM p.1488 | なし |
| HYD-19 | 挙動の誤り | 低 | M | synoptic の表現力不足（§6.2）：DEM の ON 文字・色・AUX の ON/OFF 文字が無い、系統 4 の OFF が出ない、SOV と EDP OFF が同じ dataref、不作動項目の組み合わせ（`pressure_13/24/234`）が負荷の組と合わない。コード側で直せるのは組み合わせ dataref の定義だけで、残りはカスタム acf のパネル変更 | FCOM p.1487・1490、ATA29_32 p.107–109 | `B747.19.xt.hydraulicsmodel.lua:494-497`、`747-400.acf:136170-137410` |
| HYD-20 | 欠落 | 低 | M | 油圧の STATUS メッセージ（ポンプ圧、過熱、リザーバ与圧、HYDIM バス）が無い。STATUS のメッセージ欄自体が固定 1 ページで未実装（ATA 31 と共通） | ATA29_32 p.136 | `B747.60.xt.fltInst02.lua:3432-3433` |
| HYD-21 | 欠落 | 低 | S | スタンドパイプ：量 0.00 で EDP だけが吸入を失い、demand pump は残量で回る。現状は `restotal` ≤ 0.1 で系統圧を丸ごと 0 にする | ATA29_32 p.104 | `B747.19.xt.hydraulics_override.lua:95-114` |
| HYD-22 | 欠落 | 低 | M | FLT CONTROL HYD POWER（系統ごとの TAIL/WING 遮断弁と VALVE CLOSED 灯）が無い。灯の明るさは常に 0、Lua 側にスイッチのコマンドも無い（3D の操作子の有無は未確認） | FCOM p.940、ATA22 p.18 | `B747.90.xt.lighting.lua:1381-1389` |
| HYD-23 | 挙動の誤り | 低 | S | ACF_DIFF §3.5：カスタム acf の舵面別油圧割り当て（1・2・5・6）。`override_control_surfaces`=1 と manual reversion 1.0 のため舵面には効かない見込み。コードはこの値を読まない。ビット 4 は X-Plane の系統 C（ポンプ無し）と `推定`。要確認、必要なら 0 に戻す | ACF_DIFF §3.5、DataRefs.txt | `B747.19.xt.hydraulics_override.lua:1119` |

- 件数：高 10（HYD-01, 02, 03, 04, 05, 06, 09, 11, 14, 15）、中 5（HYD-08, 10, 12, 13, 16）、低 8（HYD-07, 17, 18, 19, 20, 21, 22, 23）。合計 23。
- 正しく実装されている点：AP サーボ L/C/R の系統 3/1/2 依存（`B747.70.xt.autopilot.lua:2480-2497`）、昇降舵 4 枚・lower rudder・spoiler 3 群・TE flap 内外の系統の組（`B747.19.xt.hydraulics_override.lua:214-269`・`288`・`301-313`）、synoptic の数値表示の更新間隔（0.5 秒、10 psi 丸め、`B747.19.xt.hydraulicsmodel.lua:466-477`）、demand pump セレクタのコマンドと位置（系統 4 のみ AUX、`B747.20.xt.hydraulics.lua:149-191`）。

## 8. 作り直しか部分修正か

**推奨：油圧の「動力源と表示」部分は作り直す。消費側（舵面の動力判定）は表で駆動する形に置き換え、AFDS のコードは先に切り出す。**

- 理由：
  - 土台の式が違う。EDP 圧（N1 比例）、demand pump の判定（2500 psi）、ACMP の固定圧、AUX、温度・量の式は、資料の論理（§4）と構造から合わない。直すとほぼ全行を書き換えることになる。該当部分は合計 300 行程度（`B747.19.xt.hydraulicsmodel.lua:344-509`、`B747.20.xt.hydraulics.lua:245-417`、`B747.90.xt.lighting.lua` の油圧の灯）で、作り直しても規模が小さい。
  - 論理が資料にそのまま書いてある（HYDIM の論理図 p.141・p.143・p.89、タイマー・閾値）。状態機械として素直に組める。
  - 表示側の約束（§6.2 の dataref、`pressure_n` の psi 単位、`dem_mode_n` の -1/0/1/2、`valve_n` の 0/1、`res_n` の比、`EICAS2/stat/RF/LO`、コマンド `laminar/B747/hydraulics/sel_dial/dmd_pump_0n_up/dn`・`laminar/B747/button_switch/hyd_pump_n`・`laminar/B747/ai/hyd_quick_start`）がはっきりしているので、名前と意味を保ったまま中身を替えられる。
  - 消費側の「どの系統の組で動くか」は表（§2.4）1 つにまとめれば、舵面・脚・ブレーキ・逆推力・stab trim・YD の各担当が同じ判定を使える。現状は関数ごとに組を手書きしていて誤り（HYD-06）とバグ（HYD-07）が入りやすい。
- 進め方の案：
  1. すぐ直せるもの（作り直しを待たない）：HYD-04 の `aux_pressure` リセット、HYD-06 の 3 か所、HYD-07、HYD-08。いずれも 1 行程度。
  2. `B747.19.xt.hydraulics_override.lua` の AFDS・スラット部分（概ね 342–1104 行）を別ファイルへ移す（ATA 22/27 担当と調整）。
  3. 新しい油圧モジュール：入力（§5）→ ポンプ状態（§4.1–4.5）→ 系統圧・量・温度（§4.7–4.10）→ HYDIM 出力（§4.6）→ 既存 dataref への書き出し。灯の明るさと EICAS の status 配列への書き込みもこのモジュールから行い、`B747.90.xt.lighting.lua` と `B747.20.xt.hydraulics.lua` の油圧の式は削除する。
  4. X-Plane の油圧には故障を書かない（§6.1）。脚・ブレーキ・ステアリング・逆推力の制限は各担当の作り直しで、新モジュールの出力を使う。
- 前提として必要な他系統の出力：DC bus 1–4・AC bus 2/3・ground handling bus の状態（ATA 24 の作り直しで定義）、空地（ATA 32-09）、FCU のフラップ信号（ATA 27-50）、左右ダクト圧（ATA 36、既存 `laminar/B747/air/duct_pressure_L/R`）、N2（既存 `laminar/B747/engines/display_N2`）、FUEL CONTROL（既存 `laminar/B747/fuel/fuel_control/toggle_sw_pos`、1=RUN）、fire switch（既存 `laminar/B747/fire/engine0n/ext_switch/pos_arm`、1=引いた状態）。

## 9. 未確認事項

- X-Plane 側：
  - `rel_hydpmp`〜`rel_hydpmp4` = 6 で X-Plane の系統 A/B の圧（`sim/cockpit2/hydraulics/indicators/hydraulic_pressure_1/2/3`）がどう変わるか。電動ポンプ（`electric_hydraulic_pump_on`=1）で保たれるか。電動ポンプの電源（`acf/_esys_bus_bit_add/rel_hyd_pump_ele` = 0 の意味）。
  - 上が 0 になったとき、脚の「200 KIAS 未満で下げ固定」が飛行中に発動するか。ブレーキ・ノーズステアリングへの影響（manual reversion 1.0 の効き方）。
  - `override_control_surfaces` = 1 のとき、カスタム acf の舵面別割り当て（`_hyd0123`）が舵面・スピードブレーキに本当に効かないか。`_hyd0123` のビットの意味。
  - `SHOW_LESS 0.0` が「< 0」か「≤ 0」か（系統 4 の DEM OFF 表示）。
- 資料に無いもの（`推定` で決めて試験する）：
  - ADP の 10 秒タイマーの種類（立ち上がり／立ち下がり）。
  - EDP の流量と N2 の関係、風車回転での圧と流量、ポンプ停止後の系統圧の減衰の速さ、ADP の起動時間。
  - demand 圧スイッチの解除圧（EDP と同じ 1600 psi としている）。
  - HYD CONTROL 1・4 の発生条件。STATUS メッセージの文言。
  - BRAKE SOURCE の圧力スイッチの作動圧。accumulator 計が 0 まで下がるか（予圧 750 psi）。
  - 油温の上昇の速さと通常値の範囲、synoptic の数値を琥珀にする閾値、AUX の「ON 琥珀」の条件。
  - HYDIM-3・HYDIM-4 と ADP 4・ACMP 3 制御の DC bus（p.63・p.71 からの対称推定）。
  - RR 機の逆推力の動力源、RR 機で ADP のフラップ論理が同じか（E&M は P&W・GE と明記）。
  - 各リザーバの容量（gal）。
- 実機の構成差：本 FCOM（109/405/570）は AUX が系統 4 のみ。E&M（Config ALL）は 1・4。採用は FCOM。
- 本ノートで INTERFACES.tsv の漏れ（§6.2）を見つけた。INTERFACES.tsv の生成方法（`SHOW_*` 条件を拾っていない）を見直す必要がある。
