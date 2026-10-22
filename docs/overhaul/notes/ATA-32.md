# ATA 32 Landing Gear — 実装ノート

GAP ID の接頭辞：`GEAR`。2026-10-23 作成。コードは `overhaul` ブランチ（041c9ffa）時点。

## 1. 概要

- 対象：脚の上げ下げ（通常・代替）、空地判定（PSEU と air/ground relay）、車輪とブレーキ（normal / alternate / accumulator、antiskid、torque limiter、パーキングブレーキ）、autobrake、前輪・胴体脚ステアリング、BTMS（ブレーキ温度）、TPIS（タイヤ空気圧）、脚位置表示・GEAR synoptic・EICAS メッセージ、脚に関わる configuration warning の入力。ブレーキ源の油圧の値（系統圧、accumulator 計）は ATA 29 ノート（HYD-09・HYD-10・HYD-12）と重なる。ここでは制御則と X-Plane への出し方を扱う。
- 資料（PDF ページ）：
  - ATA29_32 32-00（p.147–290。本文 p.150–156・166–170・190・222–228・230–288、図 p.225・279・281）、32-09（p.291–342。本文 p.292–340、図 p.297・299・301・303・321・323・335・337・341）、32-40（p.343–380。p.344–376、図 p.371・377）、32-41（p.381–442。p.382–436、図 p.393・421・427・439・441）、32-42 brake control（p.443–496。p.444–494、図 p.459・481）、32-42 autobrake（p.497–564。p.498–562、図 p.499・503・517–531・561・563）、32-50（p.565–634。p.566–632、図 p.583・623・633）、32-61（p.635–674。p.636–672、図 p.663・673）。
  - FCOM 14.10–14.30（p.1499–1522。p.1505・1508・1509・1522 は画像で確認）。関連：15.20.11–12（p.1557–1558）、15.30.1（p.1603）、NP.21.18–19・22・35–36・43・53–54・56（p.112–113・116・129–130・137・147–148・150）、PI.12.8（p.282、ブレーキ冷却表）、PI.18.8（p.320）、10.10.82（p.1044）、Bulletin TB1-27（p.67–68）。FCTM p.78（2.6）・p.93（3.5）。
- 型式差：FCOM の 109・405 は P&W、570 は GE（FCOM p.5 (0.1.1)）。脚の論理に型式差は無く、違うのは表示と配置だけ。autobrake セレクタは 109/405 が aisle stand、570 が機長パネル（FCOM p.1502 (14.10.4)）。GEAR synoptic は 109 がタイヤ圧つき、405 は TILT/ANTISKID/LIMITER の disabled message つき、570 はどちらも無い（FCOM p.1507–1510 (14.10.9–12)）。>TIRE PRESSURE は 109 だけ（FCOM p.1522 (14.30.2)）。今の 3D（autobrake ノブは pedestal）と synoptic（タイヤ圧あり）は 109 に合う。RR は `資料に記載なし`。
- 資料の食い違いと採用：
  - ground mode の式：図（ATA29_32 p.323）は「傾き・ダウンロック」と「油圧低＋前脚圧縮」だけ。本文（p.322）は wing gear 非傾斜に「系統 4 圧 HI」、body gear に「系統 1 圧 HI」を足す。両方を満たす式（§4.1）を採る（`推定`）。
  - PSEU primary の電源は 28V DC battery bus（p.297・335 図）と APU battery bus（p.583 図）。GND SAFETY RLY は 28V DC bus 1（p.297 図）と bus 3（p.335 図）。どちらも `要確認`。
  - autobrake と系統 4 喪失：FCOM は「normal brake 圧を失うと disarm」（p.1516 (14.20.6)）。E&M は「arm 後の系統 4 喪失ではセレクタは trip しない（disabled、AUTOBRAKES advisory）」（p.518・530 (32-42)）、適用中は「control pressure low かつ減速不足」で disarm（p.523 図）。§4.8 で両立させた。
  - 胴体脚ステアリングの IRU 速度：disarm 40 kt（本文 p.622）と、arm < 40 kt・disarm > 50 kt（図 p.623、p.630）。図のヒステリシスを採る。
  - TIRE PRESSURE：E&M 本文は caution とも advisory とも書く（p.376）。FCOM（p.1522）と E&M 図（p.377）の advisory を採る。表示範囲は FCOM 0–400 psi（p.1516）、E&M 0–300 psi（p.374）。

## 2. 構成

### 2.1 脚とドア
- 前脚 1（2 輪、操向、ブレーキ無し）、胴体脚 2（4 輪トラック、操向）、翼脚 2（4 輪トラック、非操向）。主脚トラックは空中で油圧で傾き、格納には傾きとセンタリングが要る（FCOM p.1511 (14.20.1)）。
- 作動油圧：前脚・胴体脚は系統 1、翼脚は系統 4（FCOM p.1511）。選択弁は翼脚用（系統 4）と胴体・前脚用（系統 1）の 2 個で、レバーからケーブルで動く（ATA29_32 p.224–228 (32-00)）。
- トラック傾き：胴体は系統 1 を 2000 psi に減圧したアクチュエータ（+15°〜−25°）、着地で 2500 psi を超えた分を逃がす（p.156）。翼脚は系統 4（+51.7°〜−24°）で、油圧を失っても傾きを保つ機械式ロックがある（p.166–170）。
- ドア：油圧の wheel well door は移行中だけ開く。strut door はリンクで脚と連動（p.190）。前脚は油圧 2・機械 2、胴体は油圧 1・機械 2、翼脚は油圧 1・機械 1（FCOM p.1512 (14.20.2)）。

### 2.2 レバーモジュール（center panel）
- レバー UP / OFF / DN。プレートは 270K-.82M（上げ下げ）、320K-.82M（下げたまま）（FCOM p.1499 (14.10.1)）。コードの Vlo 270・Vle 320 と一致（`B747.60.xt.fltInst02.lua:2923-2932`）。
- LOCK OVRD スイッチ（押している間ロックを外す）。ロックソレノイド M926 は 28V DC bus 2（F24）。PSEU の LG LVR UNLK が R391 を付勢し、ソレノイドに通電してロック解除（ATA29_32 p.225 図）。無電源ではロック側と `推定`（同図）。
- レバーの DN / not DN マイクロスイッチ 2 個 → PSEU（GEAR DISAGREE）、BSCU（脚上げ時の antiskid 抑止、hydroplane 有効化）（p.452 (32-42)、p.663 図）。
- ALTN GEAR EXTEND スイッチ：NOSE/BODY（S1867）と WING（FCOM p.1499–1500）。

### 2.3 PSEU と air/ground relay（32-09）
- PSEU（E1-3）に primary と alternate の 2 つの landing gear subsystem。電源は別々（primary：battery bus F22、alternate：28V DC bus 2 F23）で、片方を失ってももう片方は動く（ATA29_32 p.316、p.297・301・335 図）。
- センサー（各位置に pri/alt 1 個ずつ）：主脚 up/down lock、前脚 up と lock link、ドア、主脚トラック傾き（左右の翼・胴体）、前脚 strut 圧縮。スイッチ入力：レバー 2、胴体脚ステアリングアクチュエータのロックスイッチ 8、HYDIM 1・4 の低圧（p.319、p.321 図）。
- 出力：discrete（ALL GR DN、NG NOT DN/LKD、LG LVR UNLK、AIR MODE、GND MODE、NG COMPRESSED、AUTO SPLR ENABLE）と EIU へのデータバス 2 本（p.320、p.321 図）。
- master relay：primary は AIR 側 R952・R910、GND 側 R778・R7073。alternate は AIR 側 R1128、GND 側 R988。system relay は P414・P415（p.297・301・335 図）。

### 2.4 ブレーキ・BSCU・BTMS・TPIS
- 主脚 16 輪にカーボンブレーキ、前輪は無し（FCOM p.1513 (14.20.3)）。
- 油圧源：normal＝系統 4、alternate＝系統 1、次に 2、最後に accumulator。圧力作動弁で自動選択（ATA29_32 p.388–390 (32-41)、FCOM p.1514 (14.20.4)、p.1519 図）。
- ペダル → ケーブル → 各翼脚 wheel well の metering valve module（normal 弁と alternate 弁）→ normal antiskid module（1 輪ずつ）または alternate antiskid module（同じ車軸の 2 輪ずつ）→ shuttle valve → ブレーキ（p.384・398–400・448、p.441 図）。
- brake accumulator：200 in³、窒素 750 psi、系統 4 で充圧。トランスミッタ（28V AC）→ 機長パネルの BRAKE ACCUMULATOR 計（p.408–410）。
- パーキングブレーキ弁：モーター駆動、28V DC battery bus（PARK BRAKE L18）、レバースイッチ S313（p.416–421、p.421 図）。
- BSCU（E9）：wheel card 8 枚、autobrake card、torque limiter card 4 枚、BITE card 2 枚。antiskid の電源は 28V DC bus 1（wheel 1/3・14/16）、bus 2（2/4・13/15）、bus 3（5/7・10/12）、bus 4（6/8・9/11）、BITE は bus 4 と bus 2（p.456–459、p.459 図）。
- autobrake：セレクタモジュール（スプリング＋磁気ラッチ）、BSCU の autobrake card、autobrake pressure control module（右翼脚 wheel well。ソレノイド遮断弁と制御弁を直列、各 1000±100 psi の圧力スイッチ）、左右の autobrake shuttle valve（metering 側に 750±50 psi スイッチ）、ペダル位置スイッチ（全行程 17° のうち 12° で作動）（p.500–516）。
- BTMS：熱電対 16、補償器 4、BTMU（E6、28V DC bus 2）→ EIU（p.422–428、p.427 図）。
- TPIS（109）：トランスデューサ 18、WIU、TPMU（E1-2、28V DC bus 4、地上は ground handling bus）。WIU 出力 50–100 kHz が 0–300 psi、精度 ±4 psi（100–200 psi）（p.358–374）。

### 2.5 ステアリング
- 前輪：系統 1 の「脚 DOWN 圧」で動く（ATA29_32 p.566 (32-50)）。tiller（各席、±70°、tiller 150° 回転で最大）と rudder pedal（±7°）。tiller がペダルに優先（FCOM p.1500 (14.10.2)、p.1513 (14.20.3)、ATA29_32 p.570–572）。ペダル操向は前脚が圧縮されると 2 個の電動アクチュエータでつながる（PSEU → R853 primary／R854 alternate squat relay、アクチュエータ電源 28V DC bus 2 G25 / bus 3 G26）（p.578–582、p.583 図）。
- 胴体脚：ECU（115V AC bus 2）、arming は BSCU の条件で R7500・R7501（28V DC bus 1）、前輪 20° スイッチ S808、左右の油圧制御モジュール（ソレノイド弁、1000 psi 圧力スイッチ、サーボ弁）、各脚 2 本のアクチュエータ（引き込み位置でロック、ロックスイッチ pri/alt）（p.602–620、p.623 図）。

## 3. 操作と表示

### 3.1 操作（FCOM p.1499–1503 (14.10.1–5)）
- 脚レバー：UP＝上げ、OFF＝脚の油圧を抜く、DN＝下げ。地上では OFF → UP をロックで阻止（FCOM p.1512）。
- ALTN GEAR EXTEND NOSE/BODY・WING：押すとそれぞれ代替系で下げる。
- tiller：±70°、ペダル操向に優先。位置指示あり。rudder pedal：全踏みで前輪 ±7°、胴体脚ステアリングは動かさない。上部を踏むとブレーキ。
- AUTOBRAKES：RTO / OFF / DISARM / 1 / 2 / 3 / 4 / MAX AUTO。OFF＝停止とリセット。DISARM＝autobrake を外し圧を抜く。1–MAX AUTO＝着地で減速率に応じて作動。RTO＝85 kt 超でスラストレバーをアイドルにすると最大圧（FCOM p.1502–1503）。
- パーキングブレーキレバー：両ペダルを踏んで引くと設定、両ペダルを踏むと解除（FCOM p.1503、p.1516 (14.20.6)）。
- 機長パネル：BRAKE SOURCE 灯（琥珀、系統 4・1・2 すべて低圧）、BRAKE ACCUMULATOR PRESSURE 計（0–4 ×1000 psi）（FCOM p.1503–1504）。
- 手順での使い方：Preflight で レバー DN・ALTN スイッチ off（FCOM p.112 (NP.21.18)）、AUTOBRAKES RTO（p.113・116）。離陸は正の上昇率で UP、格納後 OFF（p.129–130 (NP.21.35–36)）。降下で autobrake を設定（p.137 (NP.21.43)）、着地後 autobrake の作動確認（p.148 (NP.21.54)）、駐機前に OFF とパーキングブレーキ・PARK BRAKE SET の確認（p.150 (NP.21.56)）。

### 3.2 EICAS の脚位置表示（FCOM p.1505–1506 (14.10.7–8)、ATA29_32 p.658–660 (32-61)）
- 通常：DOWN（緑）＝全脚ダウンロック。斜線（白）＝移行中。UP（白）＝全脚アップロック、10 秒で消える。空箱（白）＝全位置指示が故障。
- 展開形（脚ごとに DN 緑 / 斜線 / UP 白）：GEAR DISAGREE が出たとき、または ALTN スイッチが押されているとき（p.660）。故障形は琥珀の X。
- 各脚の up/down は pri か alt のどちらかが up/down なら成立（p.658）。

### 3.3 GEAR synoptic（FCOM p.1507–1510、ATA29_32 p.668–670）
- ブレーキ温度：車輪記号の中に 0–9。白が通常、琥珀が高温（level 5 以上）。
- ドア状態：CLOSED（白）／斜線の箱（開または移行中）／空箱（指示故障）。
- タイヤ圧（109）：車輪の横に psi。白が通常、琥珀が異常（高すぎ・低すぎ）。
- 405 だけ：TILT（琥珀）、ANTISKID・LIMITER（白または琥珀）の disabled message。表示が 1 面だけのときは compacted のブレーキ温度。

### 3.4 EICAS メッセージ
| メッセージ | レベル | 条件 | 典拠 |
|---|---|---|---|
| >CONFIG GEAR | Warning（siren） | 空中で、どれかの脚がダウンロックでなく、かつ（いずれかのスラストレバーが閉で RA < 800 ft、または flaps 25 以上）。前者はレバーを進めるか脚が下がるまで、後者は脚が下がるか GND PROX GEAR OVRD を押すまで残る | FCOM p.1557–1558 (15.20.11–12)、p.1603 |
| >CONFIG GEAR CTR | Warning（siren） | 地上、V1 未満、FUEL CONTROL 3 個以上 RUN、エンジン 2 か 3 が離陸推力域で、胴体脚がセンターでない | FCOM p.1557、p.1603 |
| >CONFIG PARK BRK | Warning（siren） | 同じ条件でパーキングブレーキ設定 | FCOM p.1557、p.1603 |
| GEAR DISAGREE | Caution（beeper） | 脚位置がレバーと合わない（通常の移行時間後）。内部は同じ脚について pri と alt の両方が disagree で 30 s（status は 60 s） | FCOM p.1522、ATA29_32 p.662・673 |
| GEAR TILT | Caution（beeper） | 主脚トラックが傾ききっていない。内部は pri・alt の両方が「どれかの脚が非傾斜」かつ両方が air mode で 15 s（status 60 s）。系統 1 か 4 が無圧なら抑止 | FCOM p.1522、ATA29_32 p.336・337 図・341 |
| >BRAKE SOURCE | Caution（beeper） | 系統 1・2・4 のブレーキ圧がすべて低（2 個の圧力スイッチを直列） | FCOM p.1521、ATA29_32 p.392 |
| GEAR DOOR | Advisory | 移行時間後もドアが閉じない。内部は pri・alt 両方で 30 s（status 60 s）。代替下げ選択中は抑止 | FCOM p.1522、ATA29_32 p.664・673 |
| AIR/GND SYSTEM | Advisory | 空地判定が air 側で故障 | FCOM p.1521 |
| ANTISKID | Advisory | 使用中の antiskid 系（normal か alternate）の故障。ANTISKID OFF で抑止 | FCOM p.1521、ATA29_32 p.480・561 |
| ANTISKID OFF | Advisory | 全輪の antiskid 電源断、またはレバー解除なのにパーキング弁が開ききらない、または BSCU 電源断 | FCOM p.1521、ATA29_32 p.480・561 |
| AUTOBRAKES | Advisory | disarm または不作動、セレクタ OFF なのに armed（遮断弁下流が高圧）、85 kt 超で RTO を始めたのに作動しない（E&M：故障あり、または手動で override） | FCOM p.1521、ATA29_32 p.511・530 |
| >BODY GEAR STRG | Advisory | 指令していないのにアクチュエータ unlock、または加圧 | FCOM p.1521、ATA29_32 p.626・633 |
| BRAKE LIMITER | Advisory | 1 トラックで 2 輪以上の torque limiter 故障、レバー解除でパーキング弁が開ききらない、BSCU 電源断 | FCOM p.1521、ATA29_32 p.550・561 |
| BRAKE TEMP | Advisory | いずれかのブレーキが 5 以上。4 まで冷えると消える | FCOM p.1521、p.320 (PI.18.8) |
| >TIRE PRESSURE（109） | Advisory | タイヤ圧が範囲外（§4.11） | FCOM p.1522、ATA29_32 p.376 |
| AUTOBRAKES 1/2/3/4、MAX、RTO | Memo | そのレベルが選ばれている（E&M：セレクタがラッチ＝armed） | FCOM p.1522、ATA29_32 p.530・563 |
| PARK BRAKE SET | Memo | レバー SET かつパーキング弁閉 | FCOM p.1522、ATA29_32 p.420 |

- Status だけのもの（E&M）：GEAR MONITOR、A/G DISAGREE・NOSE A/G DISAGREE（pri/alt 不一致 10 s）、BRAKE TEMP SYS、PARK BRK VALVE、BODY GR STRG SYS、PEDAL STEERING、TIRE PRESS SYS（ATA29_32 p.338・341・376・439・630・633・666・673）。

## 4. 内部ロジック

### 4.1 空地判定（PSEU、ATA29_32 p.304–338 (32-09)）
- センサーの向き：トラックが傾く（strut が伸びる）とターゲットが近づく＝傾き。前脚圧縮センサーは strut が伸びると近づき、8 in を超えて縮むと離れる（p.306–310・574）。胴体脚はダウンロックしていないと「非傾斜」と見なさない（p.334）。
- 各 subsystem（pri・alt が独立に）の式（p.322 本文、p.323 図）：
  - `AIR = (LWG傾 ∧ LBG傾) ∨ (RWG傾 ∧ RBG傾)`
  - `GND = [(LWG非傾 ∧ H4hi) ∨ (LBG_DN ∧ LBG非傾 ∧ H1hi)] ∧ [(RWG非傾 ∧ H4hi) ∨ (RBG_DN ∧ RBG非傾 ∧ H1hi)] ∨ [(H1low ∨ H4low) ∧ NG圧縮]`
  - 油圧・ダウンロックの条件を除けば `GND = ¬AIR`。つまり air になるのは片側の翼脚と胴体脚がそろって傾いたとき、ground は左右それぞれで翼脚か胴体脚の少なくとも 1 本に荷重がかかって傾きが戻ったとき。片側の主脚だけ接地した状態は air のまま。
  - 油圧が低いとトラックが傾けられないので、前脚圧縮で ground を補う（`推定`、式から）。
- relay：AIR 出力が AIR 側 master relay、GND 出力が GND 側 master relay を付勢し、各 system relay は「air で付勢」か「ground で付勢」に分かれる（p.296–303）。
- 前脚圧縮（NG COMPRESSED）は主脚の空地とは別の出力。rudder pedal steering の接続、takeoff warning、stall warning に使う（p.310・312・320、FCOM p.1511）。
- タイマー：BSCU の胴体脚ステアリング入力は air → ground に 10 s 遅れ（p.623 図）。GEAR TILT 15 s、A/G DISAGREE 10 s（p.336–338）。power-up test は ground（前脚圧縮かつ全主脚非傾斜）でだけ（p.325）。
- 使う系統（relay 表は「TYPICAL」、全部ではない）（p.299・303 図）：

| 利用系統 | relay（系・付勢する状態） |
|---|---|
| 電源：GCU 1–4、APU GEN 1/2、BCU 1/2、GND HANDLING 1 | R121・R183・R226・R227（ALT・GND）、R228（PRI・AIR）、R229・R230（ALT・AIR）、R7321（PRI・AIR）・R983（PRI・GND）、R284（ALT・AIR） |
| エンジン：flight/ground idle、EEC control、逆推力 | R228・R628（PRI・AIR）、R768・R769（PRI・GND）、R637・R733（ALT・AIR）、R770・R777・R226（ALT・GND）、R7363・R7364（PRI・GND：TR 1・4）、R7365・R7366（ALT・GND：TR 2・3） |
| autobrake | R628（PRI・AIR）、R230（ALT・AIR）。BSCU は pri/alt の空地を直接も受ける（§4.8・4.9） |
| 油圧 HYDIM | R768・R769（PRI・GND）、R770・R183（ALT・GND） |
| 燃料：FQIS 1/2、FUEL SYS MGMT、FSMC | R768・R769（PRI・GND）、R628（PRI・AIR）、R637（ALT・AIR） |
| 空調・与圧：PTC A/B、CPCS A/B、ASCTU、zone temp、ECS、E/E cooling | R7330・R7331（PRI・GND）、R7334・R7335・R7333（ALT・GND） |
| AFDS、air data computer、FCU/SRM/YDM、pitot-static | R7332・R330・R627（PRI・GND）、R7335・R770・R777・R7334（ALT・GND） |
| 防氷：wing anti-ice、ice detection、window heat、CAPT/F/O heater | R227・R226（ALT・GND）、R985（ALT・AIR） |
| FMC L/R、radio nav、ATC、IRU on DC | R121・R183（ALT・GND）、R628（PRI・AIR）・R768・R769（PRI・GND）、R777（ALT・GND）、R733（ALT・AIR） |
| 灯火 runway/taxi、ドア（flight lock、upper deck、nose cargo）、APU（inlet door、remote、fire warn）、DFDAC、voice recorder、tire pressure、その他客室 | R7333、R627・R983・R226、R263（PRI・AIR）、R330、R121、R284、R262・R229・R230・R637・R7321 |

- PSEU の他の discrete：ALL GR DN → MAWEA（CONFIG GEAR）、NG NOT DN/LKD → ILS アンテナ切替、LG LVR UNLK → レバーロック、AUTO SPLR ENABLE（傾き・胴体脚 DN・HYDIM 1/4 圧）→ 自動スピードブレーキの地上動作、胴体脚ステアリングのロックスイッチ → MAWEA（CONFIG GEAR CTR）（p.320）。

### 4.2 レバーロック（FCOM p.1512、ATA29_32 p.224–225）
- `unlock = 全主脚 4 本が傾き ∧ 胴体脚ステアリングのアクチュエータ 8 本がロック`（pri か alt のどちらかで成立、ダイオード OR）。地上（非傾斜）ではロックし、OFF → UP を阻止。DN → OFF は可。LOCK OVRD でいつでも外せる。

### 4.3 上げ下げの順序
- UP：ドアが開き、自動ブレーキ（de-spin）、脚が上がりアップロック、ドアが閉じる。前脚は機械的に上でロック。EICAS は斜線 → UP 10 s → 消灯（FCOM p.1512 (14.20.2)、ATA29_32 p.222）。
- de-spin：レバー UP で系統 4 が de-spin アクチュエータを押し、系統 1 の減圧した圧をブレーキへ送る（ATA29_32 p.390・400）。レバーが DN を離れてから 12.5 s は alternate antiskid の解放を抑止（p.452・476）。
- DN（主脚、p.242–248）：ドアが約 2 s で開く → アップロックを外す → 脚が下がる（ドアは開いたまま保持）→ ダウンロック → ドアが約 5 s で閉じる → 脚アクチュエータの圧を切る。その後トラックが飛行姿勢（傾き）に戻る（FCOM p.1513）。前脚はドア約 2 s で開閉（p.256–262）。
- OFF：脚の油圧系を抜く（FCOM p.1512）。ステアリングは「脚 DOWN 圧」で動くので、地上で OFF にするとステアリングも抜ける（`推定`、ATA29_32 p.566 から）。
- 移行時間：GEAR DISAGREE の 30 s が上限の目安。実機の上げ下げ時間は `資料に記載なし`。

### 4.4 代替下げ（FCOM p.1513、ATA29_32 p.268–282）
- NOSE/BODY スイッチ：115V AC bus 4 で前脚・左右胴体脚の回転アクチュエータを回す（リレー制御は 28V DC bus 4）。ドアの safety valve を OFF、ドアのロックを外し、アップロックを外す → 自重と風圧で下がり、ばねでダウンロック。ドアが開ききらなくても脚が押し開ける。3 個のリレーが戻り、PSEU の ALL GEAR DOWN が来ると R1220 で 1 サイクルを最後まで回す（p.270・276–282、p.279 図）。
- WING スイッチ：115V AC bus 1、R7510/R7511 → R126/R127。まずドアを開け、ドアが 45° を超えるまで待ってからアップロックを外す（p.272–274・280、p.281 図）。系統 4 が無圧のときは逆止弁の絞りで、上から下まで約 20 s（p.250）。
- 代替下げの後、ドアは開いたまま（FCOM p.1513）。EICAS は展開形、GEAR DOOR は抑止（p.660・673）。

### 4.5 位置監視（ATA29_32 p.658–666）
- disagree（pri/alt それぞれ）：主脚は lever DN でダウンロックでない、または lever not DN でアップロックでない。前脚は「DN でロックでない、または not DN で上ロックでない」（p.663 図）。同じ脚で pri・alt 両方なら 30 s で GEAR DISAGREE と展開形。
- GEAR DOOR：同じドアで pri・alt 両方が「閉でない」→ 30 s。GEAR MONITOR（status）：pri と alt の位置指示の不一致（展開形は出さない）（p.666）。

### 4.6 ブレーキ源・accumulator・パーキングブレーキ（ATA29_32 p.384–420、FCOM p.1514–1516）
- `src = 系統4 ≥ 1200 psi ? 4 : (系統1 ≥ 1500 psi ? 1 : (系統2 加圧 ? 2 : accumulator))`。系統 1・2 で制動するとき accumulator は切り離す（p.390）。normal（系統 4）は 1 輪ずつ antiskid、alternate（1・2）は同じ車軸の 2 輪ずつ（FCOM p.1514）。autobrake は normal だけ（FCOM p.1511）。
- accumulator はパーキング用で、機体を止める能力は無い（FCOM p.1516）。設定前に 3000 psi を確認（ATA29_32 p.416）。
- BRAKE SOURCE：系統 4 用と alternate 源用の圧力スイッチを直列（p.392）。作動圧は `資料に記載なし`（ATA-29 ノートは 1200/1500 psi を `推定`）。
- パーキング：レバー SET で S313 → モーターで弁を閉じ、圧を閉じ込める。OFF で開く。R732＝弁開、R7514＝弁閉。PARK BRAKE SET は S313 と R7514。レバー OFF で 2 s 以内に開かなければ BRAKE LIMITER と ANTISKID OFF。air mode で弁が閉なら同じ 2 つ（p.420、p.421 図）。熱逃がし 3400 psi で開き 3100 psi で閉じる（p.418）。
- 最初に加圧した系統の作動油が少しブレーキ配管に入り、解除で系統 4 へ戻る。系統 4 を先に加圧すれば移らない（FCOM p.1516）。

### 4.7 antiskid・torque limiter（ATA29_32 p.446–480・540–550）
- 常時電源（スイッチ無し）（p.386）。normal は 1 輪ずつ、alternate は車軸の 2 輪ずつ（どちらかの滑りで 2 輪とも緩める）。
- locked wheel：同じ側の前後輪で、片方がもう片方の 30 % 未満なら遅い方を全解放。どちらかが 25 kt 超で有効（p.478）。
- touchdown / hydroplane：後輪が IRS 対地速度より 50 kt 遅ければ後輪を全解放。着地前は後輪に圧をかけない。左 IRU → 内側後輪、右 IRU → 外側後輪。レバーが両方 not DN なら無効（p.450・478）。
- 低速 dropout：車輪速約 8 kt 未満では解放信号を出さない（p.474）。
- torque limiter：約 30,000 ft-lb で圧を下げる。故障は BRAKE LIMITER（p.548–550）。
- ANTISKID か ANTISKID OFF が出ていると autobrake は使えない（p.480）。

### 4.8 autobrake（ATA29_32 p.498–563、FCOM p.1515–1516）
- 減速率（セレクタモジュール、p.503 図）：

| 位置 | 減速 ft/s²（g） | 最大圧 psi |
|---|---|---|
| 1 / 2 / 3 / 4 | 4.0 (0.124) / 5.0 (0.155) / 6.0 (0.186) / 7.5 (0.233) | 1,300 / 1,500 / 1,750 / 2,050 |
| MAX AUTO | 11.0 (0.342) | 3,000 |
| RTO | 減速計算なし | 3,000 |

  - 遅れ 0.1 s（同図）。乾いた滑走路では MAX AUTO もペダル全踏みより弱い（FCOM p.1515）。減速は機長側で選んだ IRU から（FCOM p.1044 (10.10.82)）。逆推力・スピードブレーキが効く分だけ圧を下げ、一定の減速を保つ（FCOM p.1515）。
- 着陸の arm（p.519 図）：セレクタ 1–MAX ∧（pri と alt が air mode ∨ スラストレバーがアイドル）∧ 機長側 IRS が有効 ∧ 左右の metered 圧が低 ∧ autobrake 故障なし ∧ normal antiskid 故障なし ∧ 系統 4 圧 HI → ラッチコイルでセレクタを保持。条件が欠けるとセレクタは保持されない（p.502）。arm 後の系統 4 喪失ではセレクタは外れない（p.518）。
- 適用（p.520・521 図）：armed ∧ スラストレバーが retard ∧ ground mode（pri か alt）∧ 車輪スピンアップ（前側 8 輪の速い方から 4–7 番目の平均が 60 kt 超を 3 s、その後 30 kt 超を保つ。ラッチ）。弁の電源はスラストレバー 2 と 4 のスイッチ経由。FCOM の表現は「全スラストレバー閉、ground、車輪スピンアップ」。適用後に ground か spin-up を失うと制動は外すが disarm はしない。停止まで、または disarm まで続ける（FCOM p.1515）。
- disarm（p.522–523、FCOM p.1515–1516）：ペダル（metered 圧 750 psi スイッチ、左右どちらか）、着地後にいずれかのスラストレバーを進める、地上で展開したスピードブレーキを DOWN に戻す、DISARM か OFF の選択、autobrake 故障、normal antiskid 故障、機長側 IRS 故障、適用後に control 圧低かつ減速が指令より 1 ft/s² 以上不足（＝normal 圧喪失）。disarm するとセレクタが DISARM に戻り AUTOBRAKES。OFF にすると電源が切れリセット。disarm 時の圧は 0.070 in のオリフィスでゆっくり抜ける（p.512）。
- RTO arm（p.525 図）：セレクタ RTO ∧ 故障なし ∧ pri と alt の両方が ground mode。RTO は地上でだけ選べる（FCOM p.1515）。
- RTO 適用（p.527 図）：スラストレバー retard ∧ ラッチ（前側車輪速の平均（最高 2・最低 2 を除く）が 85 kt 超で IRS 対地速度と一致）∧ 故障なし ∧ ペダルスイッチが踏まれていない → 最大圧（3000 psi）。85 kt 未満で中止すると働かない（FCOM p.1515）。
- RTO の disable（適用後）：ペダル 12° 以上、スラストレバー前進、故障、スピードブレーキ展開→収納。弁の電源だけ切り、セレクタは RTO のまま（p.528–529）。
- RTO の disarm：セレクタ OFF、または pri か alt が air mode → セレクタが OFF へ trip、表示なし（p.502・528）。FCOM の表現は「離陸中の disarm ではセレクタは RTO のまま、離陸後に OFF」（p.1516）。
- 表示（p.530–531 図）：memo＝セレクタ armed（レベルつき）。AUTOBRAKES＝disarm 位置、armed なのに disabled（電源、系統 4、内部故障）、セレクタ OFF なのに遮断弁下流が高圧、RTO 開始で故障、RTO 開始で手動 override。

### 4.9 ステアリング（ATA29_32 p.566–633、FCOM p.1513）
- 前輪：strut が 8 in 以上縮み、センタリングカムが外れたときだけ操向できる（空中はカムで中立）（p.570）。指令 `nose = tiller ≠ 0 ? tiller×70° : pedal×7°`（tiller 優先、FCOM p.1500・1513）。rollout 中の AP もペダル経由で ±7° まで（p.570）。tiller・ペダルを離すとばねで中立に戻る（p.595）。約 54–55° まで 2 本で押し引き、そこから 70° までは 1 本で押す（p.595–596）。shimmy damper 200 psi（p.596）。無圧時は bypass 弁で牽引可能（p.596–598）。tiller は 30 kt を超えて使うことを勧めない（FCTM p.93 (3.5)）。
- 胴体脚：
  - arm（BSCU）：両 A/G 入力が ground を 10 s 以上 ∧ 翼脚 8 輪の 4 番目に速い車輪速 < 15 kt ∧ 左か右の IRU 対地速度 < 40 kt → R7500・R7501 → ECU に電源。前輪が 20° を超えると S808 でソレノイド弁を付勢（p.622、p.623 図）。
  - disarm：車輪速 > 20 kt、IRU 対地速度 > 50 kt（本文は 40 kt）、air mode、前輪 20° 未満（p.622–623）。disarm でソレノイドが外れ、トラックは油圧でセンターへ（FCOM p.1513）。
  - 指令：前輪と逆向き。20° から動き始め、約 70° で最大 13°（p.604）。間は比例（`推定`、p.608「前輪角に比例」から）。
- EICAS：>BODY GEAR STRG、BODY GR STRG SYS（arm A と B の不一致、armed で IRS 対地速度 > 50 kt、20° スイッチ閉で > 50 kt も含む）、PEDAL STEERING（p.626・630・633）。

### 4.10 BTMS（ATA29_32 p.426–436、FCOM p.320・282）
- 表示は 0–9 の整数で温度に比例。level 5 = 482 °C で数字が琥珀になり BRAKE TEMP（p.428）。比例なら 1 level ≈ 96.4 °C（`推定`）。4 まで下がると消える（FCOM p.320 (PI.18.8)）。
- ブレーキ冷却表（FCOM p.282 (PI.12.8)）：ブレーキ 1 個あたりのエネルギー（百万 ft-lb）と、停止 10–15 分後の BTMS 表示の目安。15 以下＝2 まで、16–20＝2、22–27＝3、31＝4、34–45＝5–6（caution zone、ヒューズプラグが溶けうる）、45 以上＝7 以上（fuse plug melt zone）。地上冷却時間は 16＝10 分、20＝28 分、22＝35 分、24＝42 分、27＝52 分、31＝62 分。タキシー 1 mile ごとに 1.0 を足す。
- ヒューズプラグはブレーキ熱でタイヤを抜く（ATA29_32 p.348、FCOM p.282）。温度は `資料に記載なし`。

### 4.11 TPIS（ATA29_32 p.374–376）
- TIRE PRESSURE（主脚）：100 psi 未満、平均から ±18 %、同じ車軸の 2 本の差が低い方の 25 % 超。前脚：100 psi 未満、2 本の差が 12 % 超。故障チャンネルは平均に含めない。E&M は「地上で離陸推力でないとき」とも書く（抑止条件と `推定`）。
- 車輪番号（p.371 図）：1–4 左翼脚（1 前外・2 前内・3 後外・4 後内）、5–8 左胴体、9–12 右胴体、13–16 右翼脚、17–18 前脚（左・右）。コードの配列（`B747.10.xt.gear.lua:627-655` のコメント）と一致。

## 5. 他系統とのつながり

| 向き | 系統 | 信号・内容 | 典拠 |
|---|---|---|---|
| 入力 | 油圧（ATA 29） | 系統 1（前・胴体脚、ステアリング、alternate brake 1 番手、de-spin）、系統 4（翼脚、normal brake、accumulator 充圧、de-spin 作動）、系統 2（alternate 2 番手）。HYDIM 1・4 の低圧 → PSEU | FCOM p.1511–1516、ATA29_32 p.319・390 |
| 入力 | 電源（ATA 24） | §2 の各 bus（PSEU：battery bus・DC 2、ロック：DC 2、antiskid：DC 1–4、BTMU：DC 2、ECU：AC 2、arm：DC 1、代替下げ：AC 4・AC 1、パーキング弁：battery bus） | §2 |
| 入力 | IRS（ATA 34） | 機長側 IRU（autobrake の減速・速度）、左/右 IRU（hydroplane、胴体脚ステアリング） | ATA29_32 p.478・498・622、FCOM p.1044 |
| 入力 | 推力（ATA 76） | スラストレバースイッチ（idle / 前進、レバー 2・4 経由で autobrake 弁に給電） | p.519–529 |
| 入力 | 操縦（ATA 27） | スピードブレーキレバー（autobrake disarm）、rudder pedal（ペダル操向） | p.523、p.570 |
| 出力 | 全系統 | 空地（pri/alt の air/ground、§4.1 の表）、NG COMPRESSED | ATA29_32 p.296–323 |
| 出力 | 警報（ATA 31） | ALL GR DN・胴体脚ロック・パーキングレバー → MAWEA。位置・故障 → EIU | p.320・421 |
| 出力 | GPWS・ILS（ATA 34） | 脚位置（TOO LOW GEAR）、NG NOT DN/LKD（アンテナ） | FCOM p.68、ATA29_32 p.320 |
| 出力 | 灯火（ATA 33） | レバーが UP/OFF なら翼の着陸灯を減光（コードはレバー位置で実装済み、`B747.90.xt.lighting.lua:753-759`） | FCOM p.499 (1.40.1) |

- 今のコードの空地：全モジュールが `sim/flightmodel/failures/onground_any`（どれか 1 輪が接地）を直接読む。変数名は `all_wheels_on_ground` でも中身は any。逆推力のロックアウトだけ `onground_all`（前輪を含む全輪）を使う（`B747.40.xt.engines.lua:752-757`）。使っているのは、燃料（`B747.25.xt.fuel.lua:1114-3226` の 20 か所）、エンジン・EEC、電源（APU 発電機）、防氷（主翼）、操縦（configuration warning、スピードブレーキ）、AFDS（A/T、モード）、計器、灯火、FMC、FDR、手動操作（FD スイッチ）。

## 6. 実装上の注意

### 6.1 空地（PSEU）の作り方
- 1 か所（脚モジュール）で計算し、pri/alt の air・ground、NG COMPRESSED、ALL GR DN、LG LVR UNLK、AUTO SPLR ENABLE を dataref で出す。名前は新規（例 `laminar/B747/gear/air_ground/pri_air`）。各系統はこれに順に乗り換える（L：全モジュールに波及）。
- X-Plane からの入力（acf の脚の順番は 0 前脚、1 右胴体、2 左胴体、3 右翼、4 左翼。`747-400.acf` の `_gear/n/_gear_x`）：
  - トラック傾き：`sim/flightmodel2/gear/eagle_claw_angle_deg[1..4]`。acf の `_eagle_claw_deg`（胴体 8°、翼 58°、両 acf 同じ）に達していれば傾き、と `推定`。根拠はコードの使い方だけ（`B747.10.xt.gear.lua:544`、FMOD `fmod/747-400.snd` の autobrake_reset が 8/58 との一致を離陸の合図にしている）。代わりに `on_ground[i]`、`tire_vertical_deflection_mtr[i]` にヒステリシスを付ける方法もある。
  - 胴体脚ダウンロック：`deploy_ratio[1,2] ≥ 0.99`。前脚圧縮：`tire_vertical_deflection_mtr[0]` か `on_ground[0]`（8 in に当たる量は要確認）。系統 1・4 の HI/low は ATA 29 のモデル。
- 故障（片系の誤り）を入れられるようにすると AIR/GND SYSTEM、A/G DISAGREE、GEAR TILT が意味を持つ。

### 6.2 脚の作動
- X-Plane の脚は 1 本のハンドル（`sim/cockpit2/controls/gear_handle_down`）。両 acf とも `_hyd_gear` 3（X-Plane の油圧に依存。ATA-29 §6.1 のとおり X-Plane 側はほぼ常に加圧）、`_cyc_time` は前 12 s・胴体 9 s・翼 7 s、`_gear_retract_protect` 1。カスタムだけ `_gear_extend_protect` 1（ACF_DIFF §3.3）。
- 系統 1 と 4 で別々に動かすには、`override_gearbrake` と `sim/aircraft/parts/acf_gear_deploy[i]`（DataRefs.txt で書き込み可）が候補。脚ごとの順序、代替下げ（翼は約 20 s）、GEAR DISAGREE の故障、ドアの状態を作れる。ただし `override_gearbrake` がブレーキも奪うかは不明（要シム確認）。だめなら X-Plane のハンドルのまま、油圧が無ければハンドル指令を止め、代替下げは `sim/flight_controls/landing_gear_emer_on` で全脚を下げる（翼と胴体を分けられない）。
- 空中開始では、X-Plane が置いた脚の状態（`deploy_ratio`）に合わせてレバーを決める。

### 6.3 ブレーキと autobrake
- 使える X-Plane の口：`left/right_brake_ratio`（`override_toe_brakes` で plugin が書ける）、`sim/cockpit2/controls/parking_brake_ratio`（XP12 の DataRefs.txt では REPLACED。今も fltCtrls・gear・hydraulics が使う。3D のレバーは `laminar/B747/flt_ctrls/parking_brake_ratio`）と `park_brake_valve`、`auto_brake_level`（0 RTO、1 OFF、2–5）と `sim/aircraft/specialcontrols/acf_autofbrk_decels[4]`（書き込み可、既定 0.125・0.155・0.225・0.4 g。acf に設定なし）、`sim/aircraft/gear/acf_has_abs`（書き込み可）、`sim/flightmodel2/gear/brake_absorbed_J`・`tire_part_brake`（全入力の合計制動）。
- 推奨：
  1. 先にすぐ直す（S）：毎フレーム、セレクタ位置から `auto_brake_level` を決めて書く（DISARM/OFF → 1）。1–3 は `acf_autofbrk_decels[0..2]` を 0.124・0.155・0.186 g に、4 と MAX は X-Plane の max 枠を共用し、選択に応じて 0.233 / 0.342 g を書く。
  2. 本命（M）：`override_toe_brakes` を常時 1 にし、ブレーキ比 = max(ペダル, autobrake 指令) × 源の可否（§4.6）で書く。autobrake は §4.8 の論理と減速 PID（対地速度の微分）で自前にし、X-Plane の autobrake は OFF 固定。ペダル入力は joystick 軸（`joy_mapped_axis_value` の toe brake の添字は要確認）と `sim/flight_controls/brakes_regular/max` の wrap で取る。
- BTMS：`brake_absorbed_J`（脚ごと、÷4 でブレーキ 1 個）を FCOM の冷却表（§4.10）で level に写し、熱の遅れと冷却時間を合わせる。`brake_temp` は °C のまま出す（`Exterior_Gear1/2.obj` のブレーキの光が `brake_temp[0]`・`[1]` を使う）。
- antiskid：X-Plane の ABS（両 acf `_hyd_brakes_abs` 1）に任せ、ANTISKID OFF のときだけ `acf_has_abs` を 0 にする（効果は要確認）。

### 6.4 ステアリング
- `override_wheel_steer` を常に 1 にし、§4.9 の論理で前輪と胴体脚を書く（X-Plane の大型機用の胴体脚ステアリングと acf の `_steerdeg_*` は使わない）。条件は「前脚圧縮 ∧ 系統 1 圧 ∧ レバー DN」。空中は 0。系統 1 を失ったら操向しない（前輪の扱いは要確認）。
- tiller の入力：X-Plane の tiller 軸（`joy_mapped_axis_value` の添字は要確認）。cockpit の 3D には tiller の操作子が無い（`747-400_cockpit.obj` に該当なし）。tiller 軸を持たない利用者はペダル ±7° では地上走行できないので、「低速でペダルに全角を与える」設定を simconfig に置くかは利用者の判断（非実機）。
- 最小限の手当てなら、`sim/aircraft/gear/acf_nw_steerdeg1/2`（書き込み可）に 70 と 7 を書けば acf を変えずにカスタム acf の 75/35 を打ち消せる。

### 6.5 表示（acf のパネル定義）
- EICAS の脚表示（`747-400.acf:123804-123890`、カスタム `:113515` 付近）は通常形だけ：`gear/EICAS1_display_status` = 1 で表示、`gear/gear_position/annun_status` 0＝UP、1＝DOWN、2＝斜線。展開形と故障形は無い（追加はカスタム acf の変更で、承認が要る）。
- GEAR synoptic（`747-400.acf:137498-139300`、カスタム `:127209` 付近、`dsp/synoptic_display` = 8）：
  - ブレーキ温度：数字は `brake_temp_ind[i]`、色は `brake_temp[i]`（< 484.0 白、> 484.1 琥珀）。数字は 1 桁。
  - タイヤ圧：`tire_pressure[i]`（< 100 と > 240 で琥珀、その間は白）。3 か所に定義の誤り：左胴体 [6] の琥珀（低）が [9] を見ている（`747-400.acf:138345`、カスタム `:128056`）、左胴体 [7] と右翼 [15] の白に表示条件が無い（`:138397`・`:138798`、カスタム `:128108`・`:128509`）。
  - ドアの箱：`sim/flightmodel2/gear/deploy_ratio[i]` で切り替え（CLOSED は `SHOW_LESS 0`、斜線は `SHOW_GREATER 0.01`）。脚の位置であってドアではないので、脚が下りていると「開」になる（実機は CLOSED）。Lua からは直せない。
- 名前と意味を保つもの（INTERFACES.tsv）：`actuator/gear_handle`（0 DN・1 OFF・2 UP）、`gear_handle_detent`、`gear_lock_ovrd/position`、`gear_lock/override`、`gear/overrideUp/Down/Off`（AutoATC）、`gear/autobrakes/sel_dial_pos`（0 RTO・1 OFF・2 DISARM・3–6 = 1–4・7 MAX）と `sel_dial_up/dn`、`gear/brake_temp`（°C、[18]）、`brake_temp_ind`（[18]）、`tire_pressure`（psi、[18]）、`gear_position/annun_status`、`EICAS1_display_status`、`gear/chocked`、`flt_ctrls/parking_brake_ratio`、`button_switch/altn_nose_gear_extend`・`altn_wing_gear_extend`、`hydraulics/indicators/hydraulic_pressure_1_2_4`、`dsp/gear_switch`。FMOD は `sel_dial_pos` の変化と `< 3`、`parking_brake_ratio` == 0/1、`gear_handle`・`gear_handle_detent` の値で音を鳴らす（`fmod/747-400.snd:5020-5511`）。

### 6.6 簡略化してよいもの・いけないもの
- してよい：torque limiter（メッセージだけ）、antiskid の車輪ごとの細部（X-Plane の ABS）、BITE・CMC・ground test、PSEU の pri/alt の二重化（1 つのモデル＋故障注入で足りる）、ドアの油圧の細部（時定数だけ）、de-spin、TPMU の細かい計算。
- してはいけない：空地の式（左右両側、前脚圧縮は別信号）、レバーロック、autobrake の arm・適用・disarm と減速率、RTO の 85 kt とスラスト条件、胴体脚ステアリングの arm/disarm（20°・15/20 kt・40/50 kt・10 s）と 13°、操向角 70°/7°、ブレーキ源の順序と accumulator の意味、BRAKE TEMP の level 5、メッセージの遅れ（15 s・30 s）、代替下げの 2 系統。

## 7. 現状実装との比較（GAP 候補）

ファイル名は一意なので名前だけ書く。`B747.10.xt.gear.lua`・`B747.45.xt.fltCtrls.lua`・`B747.01.xt.manipulators.lua`・`B747.40.xt.engines.lua`・`B747.25.xt.fuel.lua` は `plugins/xtlua/scripts/<モジュール>/`、`B747.10.gear.lua`・`B747.87.warning.lua` は init 側（`plugins/xtlua/init/scripts/<モジュール>/`）、`B747.19.xt.hydraulics_override.lua`・`B747.19.xt.hydraulicsmodel.lua`・`B747.20.xt.hydraulics.lua`・`B747.60.xt.fltInst02.lua`・`B747.90.xt.lighting.lua` は `plugins/xtlua_keysystems/scripts/<モジュール>/` 配下。

| ID | 種別 | 重要度 | 規模 | 内容 | 根拠 | 該当コード |
|---|---|---|---|---|---|---|
| GEAR-01 | 欠落 | 高 | L | 空地判定（PSEU）が無い。全モジュールが `onground_any`（どれか 1 輪接地）を直接読む。実機は主脚トラック傾きによる pri/alt の air/ground（片側接地では air のまま、両側で ground）と、別信号の前脚圧縮。着地で 1 輪触れただけで全系統が ground に切り替わる。逆推力だけは前輪を含む全輪接地を要求（実機は主脚の ground relay）。前脚圧縮・ALL GR DN・LG LVR UNLK も無い | ATA29_32 p.296–323・336–338、FCOM p.1511 | §5 の各ファイル（例 `B747.10.xt.gear.lua:79`、`B747.40.xt.engines.lua:752-757`） |
| GEAR-02 | バグ | 高 | S | コードがセレクタを DISARM/OFF に動かしても X-Plane の `auto_brake_level` を書かない：着地後の disarm（ペダル・スラスト・スピードブレーキ・故障）、30 kt 以下の自動 DISARM（GEAR-05）、離陸後の RTO → OFF。表示は DISARM/OFF なのに X-Plane の autobrake が残る（X-Plane が自分で解除するかは要確認）。RTO で離陸すると空中でも X-Plane は RTO のまま | FCOM p.1515–1516 | `B747.10.xt.gear.lua:404-442`、`B747.45.xt.fltCtrls.lua:1195-1197`・`:1352-1361` |
| GEAR-03 | 挙動の誤り | 高 | M | autobrake の中身が X-Plane 任せで 747 と違う。対応付けで AUTOBRAKES 4 が X-Plane の max（0.4 g）になり MAX と同じ（実機 0.233 / 0.342 g）。3 も 0.225 g（実機 0.186）。arm 条件（系統 4、antiskid、IRS、スラスト idle）、normal 系だけ、適用条件（60 kt・3 s のスピンアップ）、セレクタが保持されない条件、AUTOBRAKES advisory の条件（DISARM 位置だけ）が無い | ATA29_32 p.502–531、FCOM p.1515–1516、DataRefs.txt `acf_autofbrk_decels` | `B747.10.xt.gear.lua:369-401`・`:857-920` |
| GEAR-04 | 挙動の誤り | 中 | S | RTO：X-Plane の RTO を入れるのはスロットル軸 > 0.8 か軸 = 0.0 のとき。それまで AUTOBRAKES RTO memo も出ない。85 kt の条件、ペダルによる disable、RTO の AUTOBRAKES advisory は X-Plane 任せか無し | FCOM p.1503・1515、ATA29_32 p.525–531 | `B747.10.xt.gear.lua:233-236`・`:379`・`:396`・`:913-917` |
| GEAR-05 | 挙動の誤り | 中 | S | 地上・IAS 30 kt 以下・逆推力なし・スピードブレーキ < 0.3 で、着陸用レベルが 1 s 後に DISARM になる。実機は停止まで制動を続け、地上（スラスト idle）でも arm できる | FCOM p.1515、ATA29_32 p.519 図 | `B747.45.xt.fltCtrls.lua:1195-1197`・`:1352-1361` |
| GEAR-06 | 挙動の誤り | 高 | M | ステアリング：IAS 20 kt で切替（実機は対地・車輪速）。20 kt 未満は X-Plane 任せで acf の `_steerdeg_*` が効く（カスタムは低速 75°・高速 35°。tiller 軸が無ければペダルでその角度まで、`推定`）。20 kt 以上は総ヨー入力 ×7° で tiller が効かない（向かい風 20 kt なら停止中も）。前脚圧縮の条件が無く空中でも前輪がラダーで動く。レバー DN（脚 DOWN 圧）の条件なし。胴体脚は X-Plane の算法（acf 15°）で、20° 起動・最大 13°・15/20 kt・IRU 40/50 kt・ground 10 s が無い。系統 1 喪失で前輪が直前の角度で固まる（HYD-12 を含む） | FCOM p.1500・1513、ATA29_32 p.570・604・622–623 | `B747.19.xt.hydraulics_override.lua:1123-1136` |
| GEAR-07 | 挙動の誤り | 中 | S | ACF_DIFF §3.4：前輪 `_steerdeg_lospeed/hispeed` はカスタム 75/35、純正 70/7（FCOM の tiller 70・ペダル 7 と一致）。胴体脚はどちらも 15（実機 13）。コードは読まないが、`override_wheel_steer` = 0（IAS < 20 kt）の間は X-Plane が使う。`acf_nw_steerdeg1/2` は書き込み可なのでコードで 70/7 にできる。カスタムの `_gear_extend_protect` 1 は実機に無い保護（acf の Vle 270 kt 超で下げられない恐れ、要確認） | FCOM p.1500–1501、ATA29_32 p.604、ACF_DIFF §3.3–3.4 | `B747.19.xt.hydraulics_override.lua:1125-1126`、`747-400_custom.acf`（`_gear/0/_steerdeg_*`） |
| GEAR-08 | 欠落 | 中 | M | レバーロックが効かない。実際に使われる init 側のハンドラはロック変数（常に 0）を見るだけ。xt 側のロック計算は死んだコードで、しかも [1] を 2 回見て左胴体脚を見ず、傾きは翼脚の claw 角だけ。地上でもレバーを UP にできる（実際に上がるかは X-Plane の `_gear_retract_protect` 次第、要確認） | FCOM p.1512、ATA29_32 p.224–225 | `B747.10.gear.lua:98-133`、`B747.10.xt.gear.lua:146-174`・`:528-551` |
| GEAR-09 | 欠落 | 高 | M | 脚の作動が 747 の油圧と無関係（X-Plane のハンドル 1 本と X-Plane の油圧）。前・胴体脚＝系統 1、翼脚＝系統 4 の分離、ドアの順序、OFF での減圧、de-spin が無い。HYD-11 の脚の部分と同じ | FCOM p.1511–1513、ATA29_32 p.242–262 | `B747.10.gear.lua:101-133`、`B747.10.xt.gear.lua:232-248` |
| GEAR-10 | 欠落 | 高 | M | 代替下げが無い。ALTN スイッチはボタン位置 [1]・[2] を反転するだけで、どこからも読まれない。2 系統の自由落下、ドアが開いたまま、展開形表示、GEAR DOOR の抑止、電源（AC 4・AC 1）が無い | FCOM p.1499–1500・1513、ATA29_32 p.268–282 | `B747.01.xt.manipulators.lua:562-568` |
| GEAR-11 | 欠落 | 中 | M | 位置監視のメッセージが無い：GEAR DISAGREE（30 s）、GEAR DOOR（30 s）、GEAR TILT（15 s）は一覧にあるが立てるコードが無い。X-Plane の脚故障（`rel_lagear*`）を出せない。展開形と故障形はパネルに無い（追加はカスタム acf、承認事項） | FCOM p.1505–1506・1522、ATA29_32 p.336–337・660–666 | `B747.87.warning.lua:78-79`・`:298`（定義のみ）、`747-400.acf:123804-123890` |
| GEAR-12 | 欠落 | 高 | M | ブレーキが油圧源で制限されない（HYD-09 と同じ不具合。実装は ATA 32 側）。normal → alternate（2 輪単位 antiskid）→ accumulator（駐機用で止める力なし）の順、autobrake は normal だけ。ブレーキは X-Plane の標準のまま | FCOM p.1514–1516、ATA29_32 p.388–390 | `B747.10.xt.gear.lua:727-734`、`B747.19.xt.hydraulics_override.lua:198-213` |
| GEAR-13 | 挙動の誤り | 中 | M | BTMS：加熱はペダル比とパーキング比×車輪回転だけで、X-Plane の autobrake・RTO の制動は入らない見込み（`tire_part_brake` を使っていない、要確認）。重量・速度²によらず、冷却は一律 1.8 °C/s。表示は floor(T/100)（コメントは 482 °C = 5、864 °C = 9 なのに）で、482–499 °C では BRAKE TEMP が出るのに数字は 4。10 以上にもなる。パネルの琥珀は 484.1 °C。500 °C 超で 25–45 s 後に脚ごとタイヤ故障。リプレイ中（空中）は外気温に戻しパーキングブレーキを外す | FCOM p.282・320、ATA29_32 p.428 | `B747.10.xt.gear.lua:736-847` |
| GEAR-14 | 欠落 | 低 | S | TIRE PRESSURE が立たない（caution 一覧にも "TIRE PRESSURE" があり、レベルが違う）。圧は乱数 198–210 psi＋地上で 10 psi、故障時 5 psi。±18 %・車軸 25 %・前脚 12 % の判定が無い。パネルの色は 100/240 psi の固定値 | FCOM p.1522、ATA29_32 p.376 | `B747.10.xt.gear.lua:618-697`、`B747.87.warning.lua:105`・`:408` |
| GEAR-15 | 欠落 | 低 | M | ANTISKID、ANTISKID OFF、BRAKE LIMITER が立たない。パーキング弁の不一致（2 s）、空中で弁閉、antiskid 故障による autobrake 抑止が無い。X-Plane の ABS と antiskid の電源・故障が結びついていない | FCOM p.1514–1515・1521、ATA29_32 p.420・480・550 | `B747.87.warning.lua:128-129`・`:163`（定義のみ） |
| GEAR-16 | バグ | 低 | S | パーキングブレーキの副作用：レバーが DN を離れるとパーキングブレーキを外す。リプレイ中（空中）に外す。X-Plane のパーキングブレーキのコマンド（`brakes_toggle_max` など）は wrap されず、レバーと X-Plane がずれる | FCOM p.1516 | `B747.10.gear.lua:129-132`、`B747.10.xt.gear.lua:749-757` |
| GEAR-17 | 挙動の誤り | 中 | S | configuration warning の脚の部分：CONFIG GEAR は「いずれかのレバーが閉」を全体のスロットル比で見る、空中の条件なし、ラッチなし、GND PROX GEAR OVRD（ボタン [5]、どこからも読まれない）による解除なし、`deploy_ratio` で判定。CONFIG GEAR CTR と PARK BRK はエンジン 2 と 3 の両方を要求（FCOM は 2 か 3）。CTR はロックスイッチでなく操向角 > 0.5° | FCOM p.1557–1558・1603 | `B747.45.xt.fltCtrls.lua:1018-1048`・`:1050-1090` |
| GEAR-18 | 欠落 | 低 | S | GEAR synoptic のパネル：ドアの箱が脚の位置（`deploy_ratio`）で、脚が下りていると「開」。タイヤ圧の LED 3 か所の定義誤り（§6.5）。どちらもパネルの変更（カスタム acf、承認事項）が要る | FCOM p.1508、ATA29_32 p.668–670 | `747-400.acf:137644-137688`・`:138345`・`:138397`・`:138798` |
| GEAR-19 | 欠落 | 低 | S | X-Plane のコマンドが wrap されていない：`brakes_toggle_auto`・`brakes_dn_auto`・`brakes_up_auto`（X-Plane の autobrake だけ変わりセレクタと食い違う）、`landing_gear_emer_on`、`brakes_toggle_max/regular` | — | `B747.10.xt.gear.lua:337-340`（wrap はこの 4 つだけ） |
| GEAR-20 | バグ | 低 | S | autobrake の誤 disarm：スロットル（全体比と軸の大きい方）が少しでも増えれば disarm（軸のノイズ、逆推力収納で起こりうる）。ブレーキ故障の判定 `> 0` は「故障を予約しただけ」でも成立 | FCOM p.1515 | `B747.10.xt.gear.lua:421-434` |
| GEAR-21 | バグ | 低 | S | wing sweep 軸が一度でも動くと `override_toe_brakes` を 1 にし、以後戻さない（1 本のブレーキ軸を wing sweep に割り当てる人向けの工夫）。他の利用者ではペダル軸が効かなくなる恐れ（`推定`） | — | `B747.10.xt.gear.lua:727-734` |
| GEAR-22 | 欠落 | 低 | M | AIR/GND SYSTEM、>BODY GEAR STRG の advisory と、脚関係の status（GEAR MONITOR、A/G DISAGREE、BRAKE TEMP SYS、PARK BRK VALVE、BODY GR STRG SYS、PEDAL STEERING、TIRE PRESS SYS）が無い。STATUS 画面自体が未実装（ATA 31 と共通） | FCOM p.1521、ATA29_32 p.338・626–633 | `B747.87.warning.lua:123`・`:161`（定義のみ） |
| GEAR-23 | バグ | 低 | S | 空中で飛行を始めると、X-Plane が脚を下ろして置いた場合（進入開始など）でもレバーを UP へ動かして脚を上げる | — | `B747.10.xt.gear.lua:1003` |

- 件数：高 7（GEAR-01・02・03・06・09・10・12）、中 7（04・05・07・08・11・13・17）、低 9。GEAR-12 は HYD-09 と、GEAR-06 は HYD-12 と、GEAR-09 は HYD-11 の一部と重なる。
- ACF_DIFF §3.4（前輪 75/35 vs 70/7）は GEAR-07。答え：コードは acf の値を読まないが、IAS 20 kt 未満で `override_wheel_steer` を 0 にしている間は X-Plane がその値で操向する。20 kt 以上ではコードが ±7° を直書きする。

## 8. 作り直しか部分修正か

- 推奨：**作り直し**（脚モジュール `B747.10` を書き直し、ステアリングを `B747.19.xt.hydraulics_override.lua` から移す）。理由：
  - 今の `B747.10.xt.gear.lua`（1061 行）は、X-Plane の脚・ブレーキ・autobrake の上に表示を載せた薄い層。肝心の論理（空地、ロック、油圧依存、代替下げ、autobrake、ステアリング、監視メッセージ）がほぼ無く、直すより書く方が早い。
  - 継ぎはぎの副作用が多い：init と xt に同名のハンドラがあって片方が死んでいる、3 つのモジュール（gear・fltCtrls・hydraulics_override）がセレクタやパーキングブレーキを別々に書く。所有者を 1 つにしないと直しても戻る。
  - ステアリングは AFDS の PID が詰まったファイル（ATA-29 §6.4）にあるので、脚側へ移すのが安全。
- 順序：
  1. すぐ効く S の手直し（作り直しの前でもよい）：GEAR-02（`auto_brake_level` をセレクタに常に合わせる）、GEAR-03 の減速率（`acf_autofbrk_decels`）、GEAR-07（`acf_nw_steerdeg1/2` = 70/7）、GEAR-16・GEAR-23。
  2. PSEU（空地）を作り、新しい dataref を出す（GEAR-01）。各系統の担当が順に乗り換える（L）。
  3. 脚の作動・ロック・代替下げ・監視（GEAR-08–11）。`override_gearbrake` の試験が先（§6.2）。展開形の表示とドアの箱はカスタム acf のパネル変更として承認を取る。
  4. ブレーキ源と autobrake 自前化（GEAR-03–05・12・20、`override_toe_brakes`）、ステアリング（GEAR-06）。
  5. BTMS・TPIS・antiskid のメッセージ（GEAR-13–15・22）。
- 作り直しでも §6.5 の dataref・コマンドの名前と意味（値の範囲、°C、psi、セレクタの番号）を保つ。

## 9. 未確認事項

- X-Plane の挙動：
  - autobrake：`auto_brake_level` を残したまま、ペダル・スラスト・スピードブレーキで X-Plane が自分で解除するか。RTO の速度閾値と、空中で RTO のまま着陸したときに制動がかかるか（GEAR-02・04）。`left/right_brake_ratio` や `l_brake_add` に autobrake の制動が出るか（GEAR-13・20）。
  - `eagle_claw_angle_deg` が「荷重が抜けるとトラックが傾く」角度か、格納中の角度か（§6.1）。`tire_vertical_deflection_mtr[0]` と前脚の 8 in の関係。
  - `override_gearbrake` と `acf_gear_deploy` で脚ごとに動かせるか、ブレーキにも及ぶか。`_gear_retract_protect` で地上の UP が止まるか、カスタムの `_gear_extend_protect` で何が止まるか。
  - `override_wheel_steer` = 0 のときの lo/hi speed 角の補間（速度）と、X-Plane の胴体脚ステアリング算法。tiller 軸と toe brake 軸の `joy_mapped_axis_value` の添字、`joy_mapped_axis_value[4]` がスロットルか。
  - `acf_has_abs`・`acf_autofbrk_decels`・`acf_nw_steerdeg1/2` を実行中に書いて効くか。`parking_brake_ratio`（REPLACED）の XP12 での後継。
  - パネルの `SHOW_LESS 0` が「< 0」か「≤ 0」か（ドアの CLOSED が出る瞬間があるか）、`HIDE` の意味。
- 資料：
  - GND SAFETY RLY の bus（1 か 3）、PSEU primary の bus（battery bus か APU battery bus）。
  - BRAKE SOURCE の圧力スイッチの作動圧、ブレーキ源選択弁の戻りのヒステリシス。
  - 脚の上げ下げ時間、ヒューズプラグの温度、BTMS の温度と level の正確な対応（比例と `推定`）。
  - 胴体脚の角度の詳細（20°→13° の間の形）、前輪のステアリング速度、無圧時の前輪（自由かセンターか）。
  - TIRE PRESSURE の抑止条件（地上・離陸推力でない）の扱い。
- シムで確かめること：着地で片側の主脚だけ接地したときの各系統の切替、タッチアンドゴー、向かい風 20 kt での tiller、autobrake 各レベルの実減速（ft/s²）、RTO の作動速度、ブレーキ温度の上がり方（autobrake 着陸で BRAKE TEMP が出るか）。
