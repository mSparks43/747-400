# ATA 52 Doors（ATA 38・51・56 を含む）— 実装ノート

GAP ID の接頭辞：`DOOR`。2026-10-23 作成。コードは `overhaul` ブランチ（041c9ffa）時点。

## 1. 概要

- 対象：乗員に見えるドアの表示（door warning switch → EIU → EICAS メッセージと DRS synoptic）、flight deck door（ロックと access system）、upper deck emergency door の flight lock、cargo door の操作と interlock（乗員に関わる範囲）、main entry door の mode（ARM/DISARM）の要点。ATA 38・51・56 は §10 に短くまとめた。窓の加熱は ATA 30。
- 使った資料（ページは PDF ページ）：
  - ATA38_51_52_56：52-00 p.209–416（本文 p.212・242・254・262・298・300・302・304・306・308–324・342–346・354–362・368・382–396、図 p.303・305・391）、52-30 p.419–564（本文 p.422–426・434–436・474–492・506–510・516–534・560–562、図 p.519・561）。38-00 p.3–134・51-00 p.137–206・56-00 p.567–614 は流し読み。
  - FCOM 1.30（p.466–498）、1.50（p.527–543）、1.60（p.545–546）。関連：L.10（p.79）、NP（p.118）、SP.1.1（p.161）、2.40（p.611・614）、6.20（p.799）、15.20（p.1586–1587）。
- 構成：FCOM の 109（旅客型）を基準にする。405（貨物型、upper deck emergency door 2 枚）と 570（貨物型、nose cargo door、upper deck crew service door）の違いは表に書く。E&M（Config: ALL）はドアの mode 表示（A/M）と DOORS AUTO/MAN の memo を持つ構成で、FCOM 109 には無い。
- 資料の食い違いと採用：
  1. flight deck door：E&M は旧型（aisle stand P8 の FLT DK DOOR switchlight、UNLKD/LKD 表示）（ATA38_51_52_56 p.308・310・318）。FCOM 109 は強化ドア（Door Lock selector UNLKD/AUTO/DENY、LOCK FAIL、AUTO UNLK、keypad）（FCOM p.469–472・528–529）。FCOM に従う。
  2. synoptic の mode 表示（A/M）と memo DOORS AUTO / DOORS AUTO/MAN / DOORS MANUAL：E&M だけ（ATA38_51_52_56 p.304・306・394・561）。FCOM 109 の synoptic と memo 一覧に無い（FCOM p.466・547）。FCOM に従い、既定では出さない（構成の選択肢として残す）。
  3. DOOR U/D FLT LK：FCOM は「離陸後に自動ロックが働かない」（FCOM p.546 (1.60.2)）。E&M は「flight lock と air/ground の不一致」で、地上でロックしたままでも caution、加えて status message（ATA38_51_52_56 p.390・392）。文言とレベル（caution・beeper）は FCOM、条件の細部は E&M（内部論理）に従う。
  4. upper deck door の電源：FCOM は GSB が upper deck emergency doors を給電（FCOM p.799 (6.20.5)）。E&M は制御の 28V DC を ground handling bus（GHB）か bus 1（左）/ bus 2（右）、モーターは 115V AC（ATA38_51_52_56 p.368・396）。内部は E&M に従う。

## 2. 構成

### 2.1 ドアと検知（109）

| ドア | 数 | 検知 | EICAS | synoptic | 典拠 |
|---|---|---|---|---|---|
| Main entry door | 10（L1–L5、R1–R5） | door warning switch（door 1–4 は下部後方、door 5 は上部後方の latch fitting。latch roller が押すと latched）。mode switch 2 個（MANUAL / AUTOMATIC の proximity switch） | DOOR ENTRY Lx/Rx、DOORS ENTRY L/R | ENTRY 1–5 の左右 | ATA38_51_52_56 p.298・300・302、FCOM p.527・545–546 |
| Upper deck emergency door | 2（L/R） | door warning switch（not closed）、flight lock switch、auto mode switch。ほかに制御用（master latch、latch open、door open/closed） | DOOR L/R UPPER DK、DOORS UPR DECK、DOOR U/D FLT LK | UPPER DECK の左右 | ATA38_51_52_56 p.354・390、FCOM p.546 |
| FWD / AFT cargo door | 各 1 | door warning switch（negative pressure relief door の torque tube＝master latch lock handle で動く）。ほかに制御用 8 個 | DOOR FWD/AFT CARGO（caution） | FWD CARGO、AFT CARGO | ATA38_51_52_56 p.426・482・484・518–520、FCOM p.545 |
| Bulk cargo door | 1 | door warning switch | DOOR BULK CARGO | BULK CARGO | ATA38_51_52_56 p.518–520 |
| Main / center E/E access door | 各 1 | latch pin で動く switch | DOOR ELEC MAIN/CTR、DOORS ELEC | MAIN ELEC、CTR ELEC | ATA38_51_52_56 p.524・526・528・530–534 |
| Flight deck door | 1 | 電動ロック | なし（LOCK FAIL 灯） | なし | FCOM p.471・528–529 |
| Flight deck overhead hatch | 1 | — | なし（405/570 は DOOR F/D OVHD） | なし（405/570 は F/D OVHD） | FCOM p.467・536・545 |

- そのほかの外部点検口（給油、水、APU、空調区画など）には操縦室の表示が無い。表示があるのは機外の扉では E/E の 2 枚だけ（ATA38_51_52_56 p.212・524）。
- 405：main deck entry door は L1 と L5 の 2 枚、upper deck emergency door 2 枚、cargo door は下部 3 枚と side cargo door。570：entry door L1・L5、upper deck crew service door、下部 3 枚、side と nose cargo door（FCOM p.527–528・537–538）。

### 2.2 信号の流れ

- door warning switch は「latched でない／closed でない」とき EIU に地気を出し、EIU が EICAS の synoptic とメッセージを作る（ATA38_51_52_56 p.302・390・518・530）。
- mode switch（AUTOMATIC / MANUAL）は MAWEA に地気を出し、MAWEA から EIU へ。レバーが中間でどちらも導通しないと mode は出ない（ATA38_51_52_56 p.302、図 p.303）。
- upper deck door の flight lock switch（LOCKED / NOT LOCKED）は、R627 air/ground relay の接点と組み合わせて EIU に入る（ATA38_51_52_56 p.390、図 p.391）。

### 2.3 電源

- FWD/AFT cargo door：actuator（latch、hook、lift）は GHB の 115V AC、制御は 28V DC（ATA38_51_52_56 p.488–492・506）。制御の 28V DC の出どころは資料に記載なし（DC GHB と推定）。GHB は地上で APU GEN 1 か EXT PWR 1 があるときだけ（FCOM p.799）。
- upper deck door：モーター 115V AC、制御 28V DC（GHB または bus 1/2）。非常開の squib は 28V DC bus 1 か扉の 6V NiCd battery（ATA38_51_52_56 p.368・382・384・396）。FCOM は GSB（§1 の食い違い 4）。
- flight deck door：電源があり閉じていればロック、電源が無ければ解錠（FCOM p.528 (1.50.2)）。電源の母線は資料に記載なし。
- door warning の入力先の EIU（ATA 31）。

## 3. 操作と表示

### 3.1 DRS synoptic

- 二次 EICAS に表示。扉の箱は「開（closed and latched でない）」で琥珀、閉で表示なし。名称は常に cyan（FCOM p.466 (1.30.32)）。109 は MAIN ELEC、ENTRY 1–5（左右）、UPPER DECK（左右）、FWD CARGO、CTR ELEC、AFT CARGO、BULK CARGO（FCOM p.466 図）。405/570 の配置は FCOM p.467–468。
- 選択：display select panel の DRS スイッチ。現コードは `laminar/B747/dsp/drs_switch` で `laminar/B747/dsp/synoptic_display` を 7 と 0 で切り替える（`plugins/xtlua_keysystems/scripts/B747.60.xt.fltInst/B747.60.xt.fltInst02.lua:1449-1454`）。
- E&M の構成では各ドアの横に mode を A（AUTOMATIC）か M（MANUAL）で出す（ATA38_51_52_56 p.306・394、図 p.561）。
- 現在のパネル（純正 `747-400.acf:137429-137497`、カスタム `747-400_custom.acf:127140-127208`、同じ内容）：背景画像（109 の名称と引き出し線）と、琥珀の箱が 2 つだけ。
  - 「Entry 1」：`sim/flightmodel2/misc/door_open_ratio[1]` > 0.05。
  - 「Upper Deck L」：`door_open_ratio[0]` > 0.05。
  - ほかのドアの箱は無い。読んでいるのは X-Plane の読み取り専用の dataref（DataRefs.txt で書き込み不可）。

### 3.2 EICAS メッセージ

| メッセージ | 種類 | 条件 | 構成 | 典拠 | 現コード |
|---|---|---|---|---|---|
| DOOR ENTRY L1–L5、R1–R5 | advisory | entry door が closed and latched でない | 109（405/570 は L1・L5） | FCOM p.545、ATA38_51_52_56 p.304 | L1 だけ：adv[66] ← `door_open_ratio[1]` > 0.01（SAF:219-223）。他は定義だけ（WRN:253-261） |
| DOORS ENTRY L / R | advisory | 同じ側の 2 枚以上。個別のメッセージを抑止 | 109 | FCOM p.546、ATA38_51_52_56 p.304 | 定義だけ（WRN:266-267） |
| DOOR L UPPER DK / DOOR R UPPER DK | advisory | upper deck door が closed and latched でない | 109・405（570 は R のみ） | FCOM p.546、ATA38_51_52_56 p.392 | L だけ：adv[76] ← `door_open_ratio[0]` > 0.01（SAF:227-231）。R は定義だけ（WRN:263） |
| DOORS UPR DECK | advisory | 両方 | 109・405 | FCOM p.546、ATA38_51_52_56 p.392 | 定義だけ（WRN:268） |
| DOOR U/D FLT LK | caution・beeper | 離陸後に自動ロックが働かない（E&M：flight lock と空地の不一致） | 109・405 | FCOM p.546、ATA38_51_52_56 p.390・392 | 定義だけ。caution[14]（WRN:122）と advisory[78]（WRN:264）の 2 か所にある |
| DOOR FWD CARGO / DOOR AFT CARGO | caution・beeper | closed and latched and locked でない | 全構成 | FCOM p.545、ATA38_51_52_56 p.520 | 定義だけ（WRN:119-120） |
| DOOR BULK CARGO | advisory | closed and latched でない | 全構成 | FCOM p.545、ATA38_51_52_56 p.520 | 定義だけ（WRN:249） |
| DOOR ELEC MAIN / DOOR ELEC CTR | advisory | E/E door が closed and latched でない | 全構成 | FCOM p.545、ATA38_51_52_56 p.532 | 定義だけ（WRN:250-251） |
| DOORS ELEC | advisory | 両方。個別を抑止 | 全構成 | FCOM p.546、ATA38_51_52_56 p.532 | 定義だけ（WRN:265） |
| DOOR SIDE CARGO | caution・beeper | closed and latched and locked でない | 405・570 | FCOM p.546 | 定義だけ（WRN:121） |
| DOOR NOSE CARGO | caution・beeper | 同上 | 570 | FCOM p.546 | なし |
| DOOR F/D OVHD | advisory | overhead hatch が closed and latched でない | 405・570 | FCOM p.545 | なし |
| DOORS AUTO / DOORS AUTO/MAN / DOORS MANUAL | memo | 全部 AUTOMATIC（離陸推力から着陸後 1 分までは抑止）／混在／全部 MANUAL（地上のみ） | E&M の構成のみ | ATA38_51_52_56 p.304 | 定義だけ（WRN:502-504） |
| DOOR U/D FLT LK | status | flight lock と空地の不一致 | E&M | ATA38_51_52_56 p.392 | なし |

- 遅延時間は資料に記載なし。エンジン始動中は新しい caution・advisory が抑止される（FCOM p.1586–1587 (15.20.40–41)。ATA 31 の扱い）。

### 3.3 flight deck door（FCOM 109）

- deadbolt：両方のレバーを水平にすると客室側の鍵で開けられない。前側だけだと鍵で開く（FCOM p.469・529）。
- emergency access panel（客室側のドア枠）：3–8 桁の code と ENT。正しい code で操縦室にチャイム。灯は赤＝ロック中か access system OFF、琥珀＝正しい code が入力された、緑＝解錠（FCOM p.470 (1.30.36)）。
- FLIGHT DECK ACCESS SYSTEM スイッチ（overhead hatch panel、guard 付き）：OFF でドアロックの電源を切る、NORM で飛行用（FCOM p.471・161）。
- aft aisle stand の FLT DK DOOR lock selector（AUTO に戻るばね付き。UNLKD へは押して回す）：UNLKD は回している間だけ解錠。AUTO はロックし、code 入力と時間経過で解錠を許す。DENY は code の要求を拒否し、一定時間 keypad を受け付けない（FCOM p.472 (1.30.38)）。
- 灯：LOCK FAIL（琥珀）＝selector が AUTO でロックが故障、または access system が OFF。AUTO UNLK（琥珀）＝正しい code が入力された。解錠の直前は点滅し、チャイムが鳴り続ける（FCOM p.471–472）。
- 手順と制限：Before Start で「Flight deck door … Closed and locked、LOCK FAIL 消灯を確認」（FCOM p.118 (NP.21.24)）。access system の試験（FCOM p.161 (SP.1.1)）を毎飛行日に行う（FCOM p.79 (L.10.3)）。

### 3.4 そのほかの乗員操作

- main entry door：mode select lever（ARM / DISARM、窓で確認）。ARM でハンドルを開けると動力で開き slide が出る。外から開けるとレバーは DISARM に移る。mode は扉が閉じているときだけ変える（FCOM p.473–474・530）。乗客がいるときは地上走行・離着陸の前に ARM（FCOM p.79）。
- upper deck emergency door（109）：扉の上に DOOR GND MODE（青。地上、または飛行中に flight lock が locked でない）と BATTERY OK（緑。3–5 秒押すと点く）（FCOM p.479–480）。操縦室からは見えない。
- Before Start で「Exterior doors … Verify closed」（FCOM p.118）。DRS synoptic と EICAS で確かめる。
- 風の制限：ドアの位置で 40 kt を超えるときは entry・cargo door を操作しない。突風が 65 kt を超えるときは開けたままにしない（FCOM p.527 (1.50.1)、ATA38_51_52_56 p.424）。

## 4. 内部ロジック

### 4.1 ドアの状態

- 各ドアの状態は「開度」「latched（閉じて latch がかかった）」「locked（cargo の handle がしまわれた）」「mode（entry と upper deck）」「flight lock（upper deck）」。
- main entry door：
  - 内側のハンドルを latched から 20–30° 回すと latch が外れ、操縦室の表示が「開」になる（扉はまだ動かない）。warning switch の調整は 4–12° で表示が出ること（ATA38_51_52_56 p.242・298）。
  - 閉めるときは、扉が閉位置まで戻り、さらにハンドルを回して latch roller がかかったときに表示が「閉」に戻る（ATA38_51_52_56 p.254）。
- FWD/AFT cargo door：warning switch は master latch lock handle が動かす torque tube にあるので、扉が閉じて latch がかかっても handle をしまう（lock sector と vent door を閉じる）までは「開」のまま（ATA38_51_52_56 p.434・436・484）。FCOM の「closed and latched and locked」と同じ（FCOM p.545）。
- bulk cargo door・E/E door：closed and latched で「閉」（FCOM p.545、ATA38_51_52_56 p.526・528）。

### 4.2 メッセージの組み立て

- entry door：片側で「開」が 1 枚ならその DOOR ENTRY、2 枚以上なら DOORS ENTRY L/R だけ（個別は抑止）（ATA38_51_52_56 p.304、FCOM p.546）。
- E/E door：両方なら DOORS ELEC だけ（ATA38_51_52_56 p.532）。
- upper deck door：両方なら DOORS UPR DECK（FCOM p.546）。個別を抑止するかは資料に記載なし（entry・E/E と同じと推定）。
- cargo door：各ドアごと（FWD/AFT は caution と beeper、BULK は advisory）（FCOM p.545）。
- 空地・飛行段階による抑止は資料に記載なし（ドアのメッセージは地上でも飛行中でも出る）。

### 4.3 upper deck door の flight lock

- flight lock actuator は飛行中に通電してハンドルの軸を止める。電源が切れるとばねで解錠側へ（ATA38_51_52_56 p.342）。制御は air/ground（ATA38_51_52_56 p.346）。
- DOOR GND MODE（扉の上の青灯）は actuator が locked でないときに点く（ATA38_51_52_56 p.344・346）。
- EICAS（ATA38_51_52_56 p.390 の表）：

| flight lock | air/ground | EICAS |
|---|---|---|
| locked でない | 地上 | なし |
| locked でない | 空中 | DOOR U/D FLT LK（caution） |
| locked | 地上 | DOOR U/D FLT LK（caution） |
| locked | 空中 | なし |

- 自動ロックが働かないと、客室の差圧が低いときは飛行中でも開けられる（FCOM p.534 (1.50.8)）。

### 4.4 flight deck door の access system（FCOM 109）

- 電源があり閉じていればロック。電源を外すと解錠（FCOM p.528）。access system OFF はドアロックの電源を切る（FCOM p.471）。
- 状態の流れ（FCOM p.529 (1.50.3)）：
  1. 正しい code + ENT → 操縦室でチャイム、AUTO UNLK 点灯。時間遅れの後に解錠する予定になる。
  2. 乗員が DENY → 拒否し、数分間 keypad を受け付けない。UNLKD（保持）→ 保持の間だけ解錠。
  3. 乗員が何もしない → 時間遅れの満了前にチャイムが鳴り続け AUTO UNLK が点滅し、満了で解錠。
  4. 「1」+ ENT でチャイム（設定されていれば）。
- 操縦室側からはいつでもハンドルを回して開けられる（FCOM p.528）。減圧時は圧力変化率センサーでドアが解錠される（FCOM p.529）。
- 時間遅れと DENY の時間は資料に記載なし。

### 4.5 FWD/AFT cargo door の操作と interlock（E&M）

- 開：handle を回す → lock sector が rotary latch を放し、vent door（negative pressure relief door）が開く → master latch lock switch で制御回路に電源 → OPEN を保持：restraint solenoid と latch actuator で rotary・mid span latch を外す → mid span latch switch で hook actuator が hook を外す → K1 hook position relay で lift actuator が扉を上げる → door up switch で止まり、貨物の荷役装置が使えるようになる（ATA38_51_52_56 p.474・488・490・492）。
- 閉：CLOSE を保持：lift が下げ、hook が pin にかかると K1 が落ちて lift が止まる → hook actuator が hook を閉じる → latch actuator が latch を閉じ、latch closed switch で止まる → handle をしまうと lock sector と vent door が閉じる（ATA38_51_52_56 p.474・488・490・492）。
- スイッチで止めることも逆転もいつでもできる（ATA38_51_52_56 p.506）。actuator は GHB（地上のみ）。
- lift actuator の冷却：開けてから閉めるまで 1 分以上、開閉 1 回の後は 10 分以上あける（ATA38_51_52_56 p.492）。
- bulk cargo door：手動、内開き。開位置は天井の uplatch hook で保持（ATA38_51_52_56 p.508・510・516）。
- 機外の操作パネルは機外（乗員の操作ではない）。

### 4.6 upper deck door と main entry door の動力

- upper deck door：通常は電動（115V AC モーター、door open/closed switch で停止）。非常時は mode が AUTOMATIC でハンドルを上げると squib で pneumatic motor が働き、slide も出る。外からの非常開では slide は出ない（ATA38_51_52_56 p.362・368・384・396、FCOM p.534）。BATTERY OK の試験は 2.1 秒の遅れの後に判定（ATA38_51_52_56 p.388）。
- main entry door：ARM でハンドルを 180° 回すと power assist（窒素）が働き、扉が全開して slide が展開する（FCOM p.530、ATA38_51_52_56 p.256・258・262）。
- 非常灯：EMER LIGHTS が ARMED で、ドアの mode が ARM のとき、ハンドルを開けるとそのドアの外部灯と客室の非常灯が点く（FCOM p.504。ATA-33 ノート §4.7）。

## 5. 他系統とのつながり

| 相手 | 内容 | 典拠 |
|---|---|---|
| EIU / EICAS（ATA 31） | メッセージのレベルと beeper、synoptic の表示（`synoptic_display` = 7）、エンジン始動中の抑止 | FCOM p.545–546・1586–1587 |
| air/ground（ATA 32-09） | upper deck door の flight lock（R627） | ATA38_51_52_56 p.346・391 |
| ELEC（ATA 24） | GHB（cargo door、upper deck door の制御）、bus 1/2、DC bus 1（squib）、flight deck door のロック | ATA38_51_52_56 p.368・396・488–492、FCOM p.528・799 |
| 与圧（ATA 21） | ドアが閉まっていないと与圧できない。cargo door の vent door は handle で開閉。upper deck door は flight lock が効かないと低差圧で開く | ATA38_51_52_56 p.426・434、FCOM p.534 |
| 照明（ATA 33） | ドアごとの非常灯（mode ARM + handle 開） | FCOM p.504 |
| 通信（ATA 23） | flight deck door の keypad で操縦室にチャイム | FCOM p.470・529 |
| X-Plane のドア | `sim/cockpit2/switches/door_open[20]`（書き込み可）、`sim/flightmodel2/misc/door_open_ratio[20]`（読み取り専用）、コマンド `sim/flight_controls/door_open_N`・`door_close_N` | X-Plane DataRefs.txt |

### 5.1 X-Plane のドア番号の現状

| X-Plane の index | 実機のドア | 使っているもの |
|---|---|---|
| 0 | upper deck L | 客室 OBJ のアニメーション（`objects/747_cabin/Cabin_Seats.obj:142931`。純正 acf だけが読む）、DRS「Upper Deck L」、DOOR L UPPER DK（SAF:227）、FMC DOORS「Upper L」 |
| 1 | entry L1 | 客室 OBJ（Cabin_Seats.obj:142891-142918。純正のみ）、DRS「Entry 1」、DOOR ENTRY L1（SAF:219）、FMC DOORS「FWD L」 |
| 9 | flight deck door | `747-400_cockpit.obj:22083・24383` の操作子（`door_open[9]` の toggle）、`objects/747_cockpit/Cockpit_acu.obj:321734`・`Cockpit_Glass.obj:34040` のアニメーション、FMOD のドア音（fmod/747-400.snd:109-133）、FMC DOORS「Cockpit」。cold & dark で開ける（MAN:2055） |
| 2–8、10–19 | 未使用 | — |

- 機外の OBJ にはドアのアニメーションが見つからない。カスタム acf は Cabin_Seats.obj を参照しない（ACF_DIFF §3.1）ので、カスタム acf では door 0・1 を開けても 3D は動かず、表示だけが変わる。
- FMC の DOORS ページ（`B744.fms.pages.doors.lua`）は Boeing の CDU に無いシム用のページ。door 2（L1）、door 1（UD L）、door 10（flight deck door）の開閉コマンドを出し、ほかの行は INOP（FMSD:13-101）。

## 6. 実装上の注意

- ドアの状態は Lua の変数（または新しい dataref）で持ち、X-Plane の door 0・1・9 はアニメーション用に連動させる。ほかのドアは X-Plane のドアを割り当てなくても、状態とメッセージだけで作れる（3D のアニメーションは対象外）。
- DRS の箱は X-Plane の `door_open_ratio`（読み取り専用）で決まるので、純正 acf では L1 と UD L の箱しか出せず、「latched でない」が「開度 > 0.05」で代用される。ほかのドアの箱、latched との区別、E&M の A/M 表示はカスタム acf にパネル計器を足す必要がある（見た目の変更。承認事項）。
- `sim/cockpit2/switches/door_open_ratio[20]` は書き込み可（DataRefs.txt）。これを書くと `flightmodel2` 側も追従するかは未確認（§9）。追従するなら、パネルを変えずに L1/UD L の箱を Lua の状態で動かせる。
- メッセージの添字は今の警報表（WRN）を使い、advisory[78] の DOOR U/D FLT LK（重複・レベル違い）は使わない。ドアのメッセージは今の SAF から、新しいドアのモジュールへ移す。
- 簡略化してよいもの：ハンドルの角度、girt bar、power assist と slide の機構、cargo door の 3 段の actuator（「開閉に何秒」の 1 段にしてよい。ただし handle を戻すまで caution が消えないことは残す）、DOOR GND MODE と BATTERY OK（扉の上で操縦室から見えない）。
- 簡略化してはいけないもの：メッセージのレベルと beeper、まとめのメッセージと抑止、cargo door の「closed and latched and locked」、flight lock の空地の論理、cargo door は地上（GHB）でしか動かないこと、flight deck door の LOCK FAIL の条件。
- 普段はすべてのドアが閉じているので、通常運航の見た目への影響は小さい。優先は（1）今ある L1・UD L の意味を正す、（2）地上作業で cargo door と entry door を開けたときのメッセージ、（3）flight lock と flight deck door（故障と手順）。

## 7. 現状実装との比較（GAP 候補）

略記：SAF = `plugins/xtlua/scripts/B747.85.xt.safety/B747.85.xt.safety.lua`、WRN = `plugins/xtlua/scripts/B747.87.xt.warning/B747.87.xt.warning.lua`、MAN = `plugins/xtlua/scripts/B747.01.xt.manipulators/B747.01.xt.manipulators.lua`、FMSD = `plugins/xtlua_keysystems/scripts/B747.68.xt.fms/activepages/B744.fms.pages.doors.lua`、ACF = `747-400.acf`、ACFC = `747-400_custom.acf`、CKPT = `747-400_cockpit.obj`。

| ID | 種別 | 重要度 | 規模 | 内容 | 根拠 | 該当コード |
|---|---|---|---|---|---|---|
| DOOR-01 | 欠落 | 中 | M | entry door は L1 だけ、upper deck door は L だけ。残りの entry door 9 枚と UD R には状態もメッセージも synoptic の箱も無い（X-Plane のドアも割り当てていない） | FCOM p.466・527・545–546 | SAF:217-231、WRN:253-263 |
| DOOR-02 | 欠落 | 中 | M | cargo door（FWD/AFT/BULK）と E/E door（MAIN/CTR）が無い。DOOR FWD/AFT CARGO（caution・beeper）、DOOR BULK CARGO、DOOR ELEC MAIN/CTR が出ない。cargo door の handle・GHB の interlock と開閉の流れも無い | FCOM p.537・545、ATA38_51_52_56 p.474・488–492・506・518–520・530–532 | WRN:119-120・249-251（定義のみ） |
| DOOR-03 | 挙動の誤り | 低 | S | 表示を X-Plane の開度で判定している（メッセージは > 0.01、synoptic は > 0.05 で食い違う）。実機はハンドルで latch が外れた時点で「開」、latch roller がかかるまで「開」。開け始めの最初の数 % では表示が出ず、メッセージと箱の出るタイミングもずれる | ATA38_51_52_56 p.242・254・298 | SAF:219・227、ACF:137456-137480 |
| DOOR-04 | 欠落 | 低 | S | まとめのメッセージ（DOORS ENTRY L/R、DOORS UPR DECK、DOORS ELEC）と個別の抑止が無い | FCOM p.546、ATA38_51_52_56 p.304・392・532 | WRN:265-268（定義のみ） |
| DOOR-05 | 欠落 | 低 | S | upper deck door の flight lock と DOOR U/D FLT LK（caution・beeper）が無い。警報表では同じ文言が caution[14] と advisory[78] の 2 か所にあり、advisory は誤り（E&M は caution と status） | FCOM p.534・546、ATA38_51_52_56 p.342–346・390・392 | WRN:122・264 |
| DOOR-06 | 欠落 | 低 | M | flight deck door の access system（ロック、LOCK FAIL、AUTO UNLK、lock selector、keypad、access system スイッチ、電源喪失と減圧での解錠）が無い。door 9 は X-Plane のドアを開閉するだけで、lock panel の操作子も無い。Before Start の「LOCK FAIL 消灯を確認」ができない | FCOM p.118・161・469–472・528–529 | MAN:2055、CKPT:22083・24383 |
| DOOR-07 | 欠落 | 低 | M | DRS synoptic の箱が L1 と UD L の 2 つだけ（両 acf 同じ）。ほかのドアの箱、latched との区別にはカスタム acf のパネル計器の追加が要る（承認事項）。背景の名称は 109 の配置で揃っている | FCOM p.466 | ACF:137429-137497、ACFC:127140-127208 |
| DOOR-08 | 挙動の誤り | 低 | S | FMC の DOORS ページや X-Plane のコマンドで、飛行中でも L1・UD L を開けられる（与圧中の plug door は開かず、UD door は flight lock で止まる）。開けても与圧に影響しない（ATA 21 と調整。X-Plane の与圧が反応するかは未確認） | FCOM p.529・534、ATA38_51_52_56 p.342 | FMSD:20-41 |

- 件数：高 0、中 2（DOOR-01、02）、低 6（DOOR-03〜08）。合計 8。
- 正しく実装されている点：DOOR ENTRY L1 と DOOR L UPPER DK のメッセージの文言とレベル（advisory）、DRS の背景（109 の名称）と DRS スイッチでの切り替え、flight deck door の 3D の開閉とドア音。
- ACF_DIFF の関係：DRS のパネル定義は両 acf で同じ（ACF_DIFF §2）。客室のドアのアニメーションは純正 acf の Cabin_Seats.obj だけにある（ACF_DIFF §3.1 の「純正だけ」の OBJ）。どちらもコードは acf の値を読まない。`acf/_dock_door_selection/*` は両 acf ともすべて -1（747-400.acf:82947-82966）で、X-Plane のドアの位置定義は acf に無い。

## 8. 作り直しか部分修正か

**推奨：ドアの小さなモジュールを新しく作る（既存の処理はほぼ無いので、作り直しというより新規）。**

- 理由：
  - 今あるのは SAF の 2 つのメッセージ（約 15 行）、FMC のシム用ページ、cold & dark で door 9 を開けることだけ。直す対象がほとんど無い。
  - ドアの状態（開度・latched・locked・mode・flight lock）とメッセージの組み立ては表で書ける。照明の非常灯（ATA 33）や与圧（ATA 21）に状態を渡す口も 1 か所にまとまる。
  - 保つもの：X-Plane のドア番号 0・1・9 とコマンド `sim/flight_controls/door_open_N`・`door_close_N`（FMC と 3D と FMOD が使う）、`sim/cockpit2/switches/door_open[9]`（3D の操作子）、警報表の添字（DOOR U/D FLT LK は caution[14] を使う）、`laminar/B747/dsp/drs_switch`・`synoptic_display` = 7。
- 進め方の案：
  1. 新しいドアのモジュール（xtlua 側。警報表と同じプラグインに置くと、プラグインをまたぐ dataref の遅れを避けられると推定）：状態、地上作業用のコマンド（FMC DOORS ページを全ドアに広げる）、メッセージ（§4.2）。SAF のドアの処理を移す。
  2. flight lock は ATA 32-09 の air/ground、cargo door の電源は ELEC の GHB を使う（各章の公開 dataref が前提）。
  3. flight deck door の LOCK FAIL・AUTO UNLK は、3D の操作子と灯（承認事項）が決まってから。それまでは状態と手順の確認用の dataref だけ。
  4. synoptic の箱の追加はカスタム acf のパネル変更として、承認を得てから。

## 9. 未確認事項

- X-Plane：`sim/cockpit2/switches/door_open_ratio` を書くと `sim/flightmodel2/misc/door_open_ratio` が追従するか。X-Plane の与圧（ATA 21 のモデル）が開いたドアに反応するか。X-Plane 12 の地上サービスがドア番号を使うか。
- DRS の箱「Entry 1」「Upper Deck L」が画面の左右どちらに描かれるか（パネル座標からは左と推定）。
- 資料に無いもの：メッセージの遅延、flight deck door の時間遅れと DENY の時間、flight lock の caution の遅れ（離陸直後に一瞬出ないか）、cargo door の制御用 28V DC の母線、flight deck door のロックの電源、upper deck door の個別メッセージをまとめのときに抑止するか。
- 構成：LCF（`747-400LCF.acf`）と貨物型のリバリーで 405/570 のドア構成（side cargo、nose cargo、F/D OVHD）を出すか。今の警報表には DOOR SIDE CARGO だけがある。
- E&M の mode 表示（A/M）と DOORS AUTO 系の memo を構成の選択肢として作るか（FCOM 109 には無い）。

## 10. ATA 38・51・56

### 10.1 ATA 38 Water/Waste

- 操縦室に操作子も表示も無い。水量計は給水パネルと purser station、遮断弁のスイッチも purser station（ATA38_51_52_56 p.48・54・56）。EICAS メッセージも資料に無い。
- 飲料水タンクの与圧は pneumatic manifold の空気、無いときは電動 compressor（30 psig で ON、39 psig で OFF。給水パネルの扉が開いていると止まる）（ATA38_51_52_56 p.28・32・34・36・38）。FCOM も抽気の用途に「potable water tank pressurization」を挙げ、center duct を分離すると使えないとする（FCOM p.611 (2.40.1)・p.614）。抽気の負荷としては小さく、ATA 36 側で無視してよい（推定）。実装は不要。

### 10.2 ATA 51 Structures

- 構造の説明だけで、乗員に見える内容は無い（ATA38_51_52_56 p.137–138）。与圧の逃がし（relief valve、blowout panel）は ATA 21 の範囲。実装は不要。

### 10.3 ATA 56 Windows

- 操縦室の窓は 6 枚（1L/1R が windshield、2・3 が側窓）で、すべて固定。開けられない（ATA38_51_52_56 p.568・570）。現コードにも窓を開ける処理は無く、食い違いは無い。
- 窓の加熱（導電膜、サーモスタット）は ATA 30（ATA38_51_52_56 p.572・584・588）。flight deck door の覗き窓は p.594（構造のみ）。実装は不要。
