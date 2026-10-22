# ATA 49 APU 調査メモ

2026-10-23 調査。対象コードは `overhaul`（041c9ffa）。出典の書き方は REFERENCE_INDEX.md に従う。

## 1. 概要

- 対象: APU selector と APU START SOURCE、始動・運転・停止の順序、自動停止、STATUS 画面の APU 表示、APU の EICAS メッセージ、エンジン始動との取り合い。
- 対象外: APU 発電機の母線接続（ATA-24.md）、APU 抽気弁とダクト（ATA-36.md）、APU 用の燃料ポンプと弁（ATA-28.md）、APU の火災探知と消火（ATA 26）。§5 に取り合いだけ書く。
- 資料: APU の整備資料は無い。FCOM を基準にした。
  - FCOM 7.14 p.867–869、7.30 p.895–897、7.40 p.902。
  - 取り合い: FCOM 2.40 p.613、6.10 p.783、6.30 p.821・p.823、8.10 p.906–911、8.20 p.913、8.30 p.921、12.20 p.1464–1465、NP.21 p.104・p.126・p.149–150。ATA26_28 p.470–480 (28-25)、ATA70_80 p.556–557 (80-11)。
- APU の機種と数値の限界（EGT、回転数、オイル）は FCOM に記載なし。
- effectivity: 570（GE 機）は APU START SOURCE スイッチと APU start TR がある。109/405（PW 機）は電池始動だけ (FCOM p.868 (7.14.2)、p.895–896 (7.30.1–2))。エンジン型式の設定とは独立に、どちらの方式にするか決める必要がある（§9）。
- コードの略記は ATA-70-80.md §1 と同じ（ENG、ELEC、FUEL、AIR、FIRE、WARN.init、ACF）。

## 2. 構成

| 項目 | 内容 | 出典 |
|---|---|---|
| 本体 | 尾部の gas turbine。地上で始動し、離陸時に回しておけば空中でも 20,000 ft まで運転できる | FCOM p.895 (7.30.1) |
| 発電機 | 2 台。地上の全負荷をまかなえる。空中では電力は使えない。AVAIL light は APU 発電機の電力品質が受入れ可のとき | FCOM p.895、p.783 (6.10.5) |
| 抽気 | 地上では全 pack を回せる（エンジン始動中を除く）。空中では 1 pack、15,000 ft まで。APU bleed switch ON で、APU が抽気を出せるとき弁が開く。逆止弁でダクトから APU への逆流を防ぐ | FCOM p.895、p.613 (2.40.3) |
| 始動電源（570） | DC starter は utility bus 4 が生きていれば APU start TR、なければ 24 V の APU battery。starter 係合中は charger を切り離す | FCOM p.895 |
| 電源の分担（570） | APU battery: inlet door、APU controller、DC fuel pump、APU 火災探知。main battery: APU 消火器、APU fuel valve、APU controller の予備。battery 始動では starter 係合中、starter 以外は main battery から | FCOM p.895 |
| 始動電源（109/405） | main と APU の両 battery が必要。分担は上と同じ | FCOM p.896 (7.30.2) |
| 燃料 | main tank 2 から。AC があれば main pump 2 aft（109/570 は 3 aft も作動し、tank 間移送を防ぎ 2 aft の予備になる）。AC が無ければ main tank 2 の DC pump | FCOM p.1464–1465 (12.20.12–13) |
| DC pump と弁 | DC pump は 28 V DC battery bus、約 1,300 pph・18 psi。ground service bus が生きると main 2 aft pump が自動で入り、その圧が約 7 psi になると DC pump が切れる。APU fuel shutoff valve は 28 V DC の actuator | ATA26_28 p.470–480 (28-25) |
| 火災 | APU fire switch、APU 消火器 1 本、右 body gear wheel well の APU ground control panel（horn、APU STOP、消火、fire control handle） | FCOM p.906–911 (8.10.2–7) |

## 3. 操作と表示

### 3.1 APU selector（overhead）(FCOM p.867 (7.14.1))

- OFF: APU bleed air isolation valve を閉じ、通常停止を始める。自動停止の fault logic をリセットする（抽気ダクト漏れによる停止は除く）。
- ON（運転位置）: APU fuel valve と inlet door を開き、APU bleed air isolation valve を arm し、DC pump または AC fuel pump（109/570 は 2 台）を作動させる。
- START（瞬間位置、ON にばねで戻る）: 自動始動を始める。
- NP: START にしたあと ON へは手で戻す（ばね戻しにまかせない）。APU GEN の AVAIL を確認して接続 (FCOM p.104 (NP.21.10))。着陸後に START → ON (FCOM p.149–150 (NP.21.55–56))。Before Taxi で OFF (FCOM p.126 (NP.21.32))。

### 3.2 APU START SOURCE（570、overhead maintenance panel）(FCOM p.868 (7.14.2))

- TR（通常）: TR か APU battery で始動（TR の故障時を除く）。
- APU BATTERY: APU battery だけで始動。TR を始動回路から外す。

### 3.3 表示（STATUS 画面）(FCOM p.868–869 (7.14.2–3))

- EGT（°C）、N1・N2（%）、OIL QTY（1.00 = 満量）。油量が規定を下回ると RF または LO（magenta）。
- AC が無いときは停止の進み具合を STATUS 画面で監視する (FCOM p.897 (7.30.3))。

### 3.4 EICAS メッセージ

| message | level | 条件 | 出典 |
|---|---|---|---|
| APU | advisory | APU selector ON で自動停止した、または selector OFF なのに APU N1 >95% | FCOM p.902 (7.40.4) |
| APU DOOR | advisory | inlet door が指令位置にない | FCOM p.902 |
| APU FUEL | advisory | ポンプ作動時に低圧、または APU fuel valve が指令位置にない | FCOM p.902 |
| APU RUNNING | memo | selector ON かつ APU N1 >95% | FCOM p.897、p.902 |
| FIRE APU | warning、fire bell | APU 火災（ATA 26 担当） | FCOM p.921 (8.30.1) |
| >DET FIRE APU | advisory | APU 火災探知 loop A・B 故障（ATA 26 担当） | FCOM p.921 |
| >BOTTLE LOW APU | advisory | APU 消火器の圧低下（ATA 26 担当） | FCOM p.921 |
| >BAT DISCH APU | advisory | APU battery 放電（ATA 24 担当） | FCOM p.821 (6.30.1) |
| >STBY BUS APU | advisory | APU standby bus 無電源（109/570、ATA 24 担当） | FCOM p.823 (6.30.3) |

## 4. 内部ロジック

### 4.1 始動

- selector を START にすると APU fuel valve と inlet door が同時に開く。inlet door が全開になると starter が係合し、点火、light-off、定格回転までの加速と続く (FCOM p.896 (7.30.2))。
- 始動間の待ち時間 (FCOM p.896):

| 始動の間 | 570・TR | 570・battery | 109/405・battery |
|---|---|---|---|
| 1 と 2 | 1 min | 1 min | 1 min |
| 2 と 3 | 10 min | 5 min | 5 min |
| 3 と 4 | 20 min | 1 min | 1 min |
| 4 と 5 | 20 min | 20 min | 20 min |
| 5 と 6 | 20 min | 1 min | 1 min |
| それ以降 | 20 min ごと | 20 min の後、1 min と 20 min を交互 | 同左 |

- 570: TR が START SOURCE = TR で過熱すると、始動電源は battery に移って始動を続ける。過熱した TR での以後の始動は禁止。過熱以外の TR 故障では自動で battery に切り替わらないので、START SOURCE を BATTERY にする (FCOM p.897 (7.30.3))。
- 数値（始動時間、EGT の限界、light-off の判定）は資料に記載なし。

### 4.2 運転

- APU RUNNING memo は selector ON かつ N1 >95% (FCOM p.897、p.902)。
- 抽気: APU bleed switch ON で、APU が抽気を出せるとき APU bleed valve が開く。中央のダクト区画に入る (FCOM p.613 (2.40.3))。
- 発電機: AVAIL は電力品質が受入れ可のとき。空中では電力は使えない (FCOM p.783、p.895)。母線との接続は ATA-24.md。
- 運転範囲: 空中は 20,000 ft まで。空中の抽気は 1 pack、15,000 ft まで。エンジン始動中は全 pack を回す余裕が無い (FCOM p.895)。
- エンジン始動: CF6 機では engine start relay から APU 制御器に増風を要求する（手動始動は START を引いた時点、autostart は RUN の後）。50% N2 で要求が終わる (ATA70_80 p.556–557 (80-11))。PW 機の同様の連動は資料に記載なし。

### 4.3 停止と自動停止

- selector OFF で APU bleed valve が閉じ、無負荷で 60 s の cooldown の後に停止する (FCOM p.897 (7.30.3))。
- 停止が終わるまで Battery switch は ON のまま。cooldown が終わる前に Battery を OFF にすると即停止。火災探知も含めて停止を完了させるには、OFF の後 2 min 以上待ってから Battery を OFF にする (FCOM p.897)。
- 限界を超えるか火災を探知すると即停止 (FCOM p.897)。火災では自動停止し、地上では消火器も自動で放出する (FCOM p.907 (8.10.3))。
- 抽気ダクトの過熱で停止した場合は再始動できない (FCOM p.613)。selector OFF でもこの停止の fault はリセットされない (FCOM p.867)。
- APU fire switch を引くと、消火器の arm、APU fuel valve と bleed valve の閉、inlet door の閉、発電機の field と breaker の trip、APU 停止（自動停止していなければ）(FCOM p.907)。
- 自動停止の条件（どの限界か）と数値は資料に記載なし。

### 4.4 燃料の供給（ATA26_28 p.470–480 (28-25)）

- 始動の開始から relay R7200 が APU fuel shutoff valve の開と DC pump の relay（R295）に電源を送る。R295 が DC pump を APU battery bus につなぐ。
- ground service bus が生きると main 2 aft pump が自動で入り、その圧が約 7 psi に達すると DC pump の圧力スイッチが開いて DC pump が切れる。
- 運転中は main 2 と 3 の aft pump が APU 系統に圧をかけ、scavenge 系統が動いたときの不釣り合いを防ぐ。
- 弁の位置と DC pump の状態は FSEIC と VPLC が監視して表示に使う（APU FUEL の元）。

## 5. 他系統とのつながり

| 相手 | 内容 | 出典 |
|---|---|---|
| 電源（ATA 24） | 発電機 2 台（地上のみ）、APU battery・main battery・APU start TR・utility bus 4、APU standby bus | FCOM p.783、p.804、p.895–897 |
| 抽気（ATA 36） | APU bleed valve、エンジン始動の空気、pack の制限 | FCOM p.613、p.895 |
| 燃料（ATA 28） | main tank 2、main 2/3 aft pump、DC pump、APU fuel valve | FCOM p.1464–1465、ATA26_28 p.470–480 |
| 火災（ATA 26） | 火災探知で自動停止、fire switch の作用、地上の自動消火 | FCOM p.906–911 |
| エンジン（ATA 80） | 始動空気、始動中の増風要求 | FCOM p.879、ATA70_80 p.556–557 |
| EICAS（ATA 31） | STATUS 画面の APU 欄、メッセージ | FCOM p.868–869、p.902 |

- コード上の取り合い（再構築で壊さないもの）:
  - コマンド: `laminar/B747/electrical/apu/sel_dial_up`・`sel_dial_dn`（3D）。置き換えている X-Plane コマンド `sim/electrical/APU_start`・`APU_on`・`APU_off` (ELEC:201-241)。quick start（B747.95.xt.AI）は `sim/electrical/APU_start` と APU N1 >95% で始動完了を判断する。
  - dataref: `laminar/B747/electrical/apu/sel_dial_pos`（0 OFF、1 ON、2 START）、`apu_inlet_door`（3D）、`apu_volts`（パネル）、`apu_pwr1_on`・`apu_pwr2_on`（音）、`laminar/B747/apu/n2`・`apu/oil`（パネル）、`laminar/B747/air/apu/bleed_valve_pos`（パネル）。
  - パネルの APU 欄は X-Plane の `sim/cockpit2/electrical/APU_EGT_c` と `sim/cockpit/engine/APU_N1` も直接読む (ACF:129779)。

## 6. 実装上の注意

- 現状: APU の回転と EGT は X-Plane の APU モデル。プラグインは `APU_starter_switch`（0 = off、1 = on、2 = start）を書き、X-Plane が回転を上げる (ELEC:660-695)。selector、inlet door、cooldown、発電機、メッセージは ELEC、APU の N2 と油量は ENG、抽気は AIR、燃料は FUEL に分かれている。
- 方針案:
  - X-Plane の APU モデル（N1、EGT、running）は土台に残し、制御（OFF → door 開 → 始動 → 運転 → cooldown → 停止、自動停止と fault の保持、始動回数の制限）を 1 か所の状態機械にまとめる。
  - N2 は資料に関係式が無い。FCOM の表示例は N1 100.0 に対し N2 92.6 (FCOM p.868)。N1 からの換算で作るしかない（推定）。
  - 燃料が無ければ（弁閉、ポンプ圧なし、main 2 が空）停止させる。燃料消費は運転中だけにする（FUEL 担当と調整）。
  - 自動停止の限界値は資料に無いので、火災、抽気ダクト過熱、燃料切れ、Battery OFF のように資料で原因が分かるものだけを作る。
- 単純化してよいもの: 始動電源の電流や TR の過熱、始動間の待ち時間（警告か拒否だけで可）、APU ground control panel。
- 単純化してはいけないもの: selector の順序（door 全開で starter）、60 s cooldown と bleed valve の閉、自動停止と fault の保持、APU / APU DOOR / APU FUEL / APU RUNNING の条件、空中の運転範囲。

## 7. 現状実装との比較（GAP 候補）

| ID | 種別 | 重要度 | 規模 | 内容 | 根拠 | 該当コード |
|---|---|---|---|---|---|---|
| APU-01 | 挙動の誤り | 中 | S | APU N2 の表示が「85.5 × inlet door の開度」。APU が止まっていても door が開けば 85.5% になり、回転と関係しない | FCOM p.868 | ENG:1341 |
| APU-02 | 挙動の誤り | 低 | S | APU の油量は乱数の初期値（0.75〜1.0）から N2 × 0.003 を引くだけ。RF/LO（magenta）が無い | FCOM p.868–869 | ENG:1318、ENG:1326、ACF:129779 |
| APU-03 | バグ | 中 | S | APU DOOR が「door 全開で APU 停止中」か「door 全閉で運転中」で出る。selector ON から START までの正常な待ち（door 開・未始動）や停止直後にも出る。FCOM は door が指令位置にないとき | FCOM p.902 | ELEC:861-870 |
| APU-04 | 挙動の誤り | 中 | S | APU advisory が「selector ON（ON と START）で APU N1 <0.1%」で出るので、始動前の正常な状態でも出る。FCOM は selector ON で自動停止したとき（OFF なのに N1 >95% の側は cooldown を除外していて合っている） | FCOM p.902 | ELEC:852-859 |
| APU-05 | 挙動の誤り | 低 | S | APU RUNNING が selector に関係なく N1 >95% で出る（cooldown 中も出る）。FCOM は selector ON かつ N1 >95% | FCOM p.897、p.902 | ELEC:920-926 |
| APU-06 | 欠落 | 中 | M | 自動停止が無い。限界超過、火災（X-Plane の APU 火災故障で止まるかは未確認）、抽気ダクト過熱（再始動不可）。selector OFF での fault のリセットも無い。FIRE APU のメッセージを立てる処理も無い（ATA 26 担当） | FCOM p.613、p.867、p.897、p.907、p.921 | ELEC:649-746、FIRE:53・FIRE:330 |
| APU-07 | 挙動の誤り | 低 | S | 始動を許すのが inlet door 13% 開。FCOM は全開で starter 係合。door の動きは速度係数 0.04 の指数で非常に遅い（時定数 約 25 s） | FCOM p.896 | ELEC:684、ELEC:699 |
| APU-08 | 挙動の誤り | 低 | S | selector OFF の後の 60 s cooldown 中も APU bleed valve が開いたまま（弁は APU の圧だけで開閉）。FCOM は OFF で bleed valve を閉じ、無負荷で cooldown | FCOM p.867、p.897 | AIR:488-496、ELEC:663-671 |
| APU-09 | 欠落 | 低 | M | 始動電源と始動回数の制限が無い。APU battery・main battery・TR、570 の APU START SOURCE、TR 過熱時の battery 切替、始動間の待ち時間 | FCOM p.868、p.895–897 | なし |
| APU-10 | 欠落 | 低 | S | 運用範囲が無い。空中の運転上限 20,000 ft、空中の抽気は 1 pack・15,000 ft まで、エンジン始動中の pack の制限。発電機は地上でしか ON にならないが、地上で ON にしたものは空中でも ON のまま（要確認、ATA 24 担当） | FCOM p.895 | ELEC:710-721 |
| APU-11 | 欠落 | 低 | S | APU は燃料弁・ポンプ・main 2 の残量に関係なく回る。燃料消費は「弁開かつポンプ ON」で一定 500 kg/h（APU が止まっていても減る）。APU FUEL は弁位置と selector の不一致だけで、ポンプの低圧を見ない | FCOM p.902、p.1464–1465、ATA26_28 p.478–480 | FUEL:944-952、FUEL:1369-1374、FUEL:2100-2106、FUEL:2847-2856 |
| APU-12 | 欠落 | 低 | S | エンジン始動時の増風要求が無い。APU の抽気圧は APU N1 だけの関数（0–80% N1 で 0 → 35〜41 psi、上限は乱数） | ATA70_80 p.556–557、FCOM p.895 | AIR:425-440 |
| APU-13 | 挙動の誤り | 中 | S | 始動の指令が保持されない。FCOM の手順（selector を START に回して ON に戻す）では、吸気ドアが開く前に START を離すことになり、APU が始動しない。今の実装は、ON でドアを開けてから START に回し、ドアが 13% 開くまで START に置く必要がある（2026-10-23 の基準シナリオ s00 で確認。この項目はノートの作成後に追加） | FCOM p.180 (SP.6.2)、p.896 (7.30.2) | ELEC:682-688 |

- 件数: 高 0、中 4（APU-01・03・04・06）、低 8、計 12。

## 8. 作り直しか部分修正か

- 推奨: APU の制御を 1 つのモジュール（状態機械）に作り直す。規模は M。X-Plane の APU モデル（N1、EGT、running、`APU_starter_switch`）は土台に残し、§5 の dataref とコマンドの名前と意味は保つ。
- 理由: 今の処理は ELEC、ENG、AIR、FUEL に散らばり、メッセージの条件（APU-03・04・05）と表示（APU-01・02）が状態と食い違っている。自動停止や fault の保持を足すには、状態（OFF / door 開 / 始動 / 運転 / cooldown / fault 停止）を 1 か所で持つ必要がある。量が少ないので、部分修正を重ねるより作り直す方が速い。
- 暫定の小修正（S）: APU-01・03・04・05・08。

## 9. 未確認事項

- APU の機種、EGT・回転数・油の限界、始動時間、N1 と N2 の関係は資料に無い。
- 機体の始動方式を 570（TR + battery、START SOURCE あり）と 109/405（battery のみ）のどちらに合わせるか。エンジン型式と連動させるか、機体（旅客 / 貨物）の設定で決めるかは要相談（推定: 3D の overhead maintenance panel に START SOURCE があるかで決める）。
- X-Plane の APU が火災故障（`rel_apu_fire`）、燃料切れ、高高度でどう振る舞うか（自分で止まるか）はシムで確認する。
- X-Plane の APU の始動時間と N1 の上がり方が実機らしいか（資料に数値が無い）。
- 発電機を地上で ON にしたまま離陸したときに空中でも接続が残るか（APU-10、ATA 24 担当と確認）。
- PW 機にエンジン始動中の APU 増風要求があるかは資料に記載なし。
