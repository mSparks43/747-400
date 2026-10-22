# ATA 31 警報系統（Crew Alerting）実装ノート

GAP ID 接頭辞：`WARN`。2026-10-23 調査。コード・acf・snd は変更していない。メッセージ全表は [EICAS-MESSAGES.md](EICAS-MESSAGES.md)。

## 1. 概要

- 対象：EICAS の alert／memo／status メッセージの仕組み（レベル・色・並び順・ページ送り・CANC/RCL）、master WARNING/CAUTION 灯とリセット、警報音（bell・siren・wailer・beeper（owl）・chime）とその優先順位・抑止、GPWS・ウインドシア・TCAS の音声の優先関係、離陸／着陸形態警報、スピードブレーキ警報、スタビのグリーンバンド、失速警報（スティックシェーカー）、オーバースピード、AIRSPEED LOW、高度警報、乗員覚醒監視（PILOT RESPONSE）、STATUS ページ、メッセージが表示に届くまでの経路（CAS 行・パネル計器）。
- 対象外：各系統のメッセージ条件そのもの（EICAS-MESSAGES.md に一覧だけ載せる）。GPWS・TCAS の警報論理そのものと PFD/ND の描画は航法・表示のノートで扱う（ここでは警報系統との接点だけ）。
- 使った資料（ページは PDF ページ）：
  - FCOM 15.10 p.1527–1546、15.20 p.1547–1602、15.30 p.1603–1606。抑止の表（p.1586–1602）は列がずれるので p.1586–1595・1599–1602 を画像で読んだ。全章の EICAS Messages 節（EICAS-MESSAGES.md §0 の範囲）は `pdftotext -table` で読んだ。補助に FCOM 4.10 p.655（AP 切断スイッチ）、8.20 p.919–920（火災試験）、10.10 p.969・973（速度テープの最大速度・最小機動速度）。
  - ATA31 31-51 Aural Warning System p.83–274（本文ページすべて。図は p.181・189・197 を描画）。
  - ATA27 27-32 Stall Warning p.689–714、27-90 Configuration Warning p.715–748（図は p.743・745・747 を描画）。
  - 補助：ATA34_1 34-16 Altitude Alert p.169–200（警報系統の crew alerting card 上の機能なので要点だけ）。
- 型式：FCOM の機番 109（旅客機・PW）、405（Boeing 改造貨物機・PW）、570（貨物機・CF6）（FCOM p.5 (0.1.1)）。乗員に見える挙動は FCOM に従い、**109 を基準**にして 405/570 の違いを添える（燃料ノート ATA-28.md と同じ基準）。109 には SB の前後で違う項目（PILOT RESPONSE、OVERSPEED の消音可否、TCAS の版）がある。整備資料（ATA31・ATA27）は航空会社の訓練書で Config: ALL。
- エンジン型式で違うのは離陸推力の判定値（ATA27 p.730）と一部メッセージの文言（EICAS-MESSAGES.md の【PW】【GE】）だけ。RR の資料は無い。
- コード：`plugins/xtlua/scripts/B747.87.xt.warning/B747.87.xt.warning.lua`（1,163 行。うち約 470 行がメッセージ表）、`plugins/xtlua/init/scripts/B747.87.warning/B747.87.warning.lua`（表の複製、477 行）・`B747.87.warning02.lua`（dataref 作成、172 行）。関連：`B747.01.xt.manipulators.lua`（master リセット）、`B747.60.xt.fltInst02.lua`（CANC/RCL/STAT、OVERSPEED、AIRSPEED LOW、失速警報）、`B747.45.xt.fltCtrls.lua`（形態警報、SPEEDBRAKES EXT）、`B747.90.xt.lighting.lua`（master 灯）、`fmod/747-400.snd`（警報音）、`747-400.acf` 末尾のパネル計器（CAS 行）。

## 2. 構成

### 2.1 実機の構成要素

| 要素 | 役割 | 電源 | 出典 |
|---|---|---|---|
| MAWEA（modularized avionics warning electronics assembly） | 警報の中枢。カードファイルで、下の各カードと電源 2 台、モニタパネルを持つ | 電源 A：115 V AC standby bus（ATA27 は「standby bus 3」）、電源 B：115 V AC F/O instrument transfer bus。片方でも全機能を維持 | ATA31 p.96、p.100、p.153 (31-51)、ATA27 p.704 (27-32) |
| master monitor card A・B | level A（warning）の入力を受け、master WARNING 灯を点け、ASC に level A aural を要求。離陸形態警報の enable と抑止（warning inhibit）を作る。ARINC 429 6 本を他カードへ中継 | 同上 | ATA31 p.103、p.106、p.132、p.180、p.188 |
| configuration warning card | 離陸／着陸形態警報、スピードブレーキ警報、スタビのグリーンバンド、G/S アンテナ切替 | 同上 | ATA31 p.110、p.134 |
| crew alerting card | 操縦室チャイム、PA 音量、客室サイン（AUTO）、高度警報。ASC の利得を決める | 同上 | ATA31 p.114、p.134、p.166、ATA34_1 p.172 |
| aural synthesizer card（ASC）左・右 | 警報音を生成・増幅。GPWC と TCAS の音声は増幅だけ。左 ASC → 機長スピーカー、右 ASC → 副操縦士スピーカー。互いに 100 ms ごとの FAIL パルスを監視し、片方が故障すると残りが両スピーカーを駆動 | 同上 | ATA31 p.116、p.132、p.168、p.228 |
| stall warning management card（SWMC）左・右 | スティックシェーカー（失速・過回転）、PLI、速度テープのパラメータ | 同上 | ATA31 p.136、ATA27 p.690 |
| signal collection card 1・2、tail ID card | 離散信号を ARINC 429 にして EIU へ。機体識別 | 同上 | ATA31 p.118、p.136 |
| 警報スピーカー（機長・副操縦士） | 内蔵アンプ | 28 V DC | ATA31 p.100、p.146 |
| master WARNING 灯（赤）・master CAUTION 灯（琥珀）×2 | グレアシールド。押すとリセット | 資料に記載なし | FCOM p.1532 (15.10.6)、ATA31 p.144 |
| スティックシェーカー ×2 | 各操縦桿にモーター。各 SWMC が両方を駆動 | 28 V DC battery bus（P7 の CB）、接地は SWMC 経由 | ATA27 p.694、p.704 |
| EIU（L・C・R） | 全系統と MAWEA のデータから EICAS メッセージを作り、1 台が全 EICAS 表示を制御。EIU SEL で自動／手動選択 | （表示系のノート） | FCOM p.1529 (15.10.3)、p.1547 (15.20.1)、ATA31 p.256 |
| 表示選択パネル（グレアシールド） | CANC、RCL、STAT ほか synoptic 選択 | （表示系） | FCOM p.1530 (15.10.4) |

### 2.2 シムでの構成

- `B747.87.xt.warning.lua` が EICAS メッセージの待ち行列と表示行を作る。各系統のモジュールは `laminar/B747/CAS/{warning,caution,advisory,memo}_status[n]` に 0/1 を書くだけ（同ファイル 22–36 行の説明）。
- 状態配列の大きさは初期化側の表の件数で決まる：warning 32、caution 75、advisory 304、memo 46（`B747.87.warning02.lua:117–120`）。表は init 側と xt 側に 2 つあり、内容が少し違う（WARN-07）。
- 表示行は `laminar/B747/CAS/gen_{warning,caution,advisory,memo}_msg_000〜109`（文字列、各 110 本）。パネルが読むのは `000〜021` だけ（11 行 × 2 ページ）。
- master 灯の値は `laminar/B747/warning/master_warning`・`master_caution`（作成は `B747.01.manipulators`、灯の明るさは `B747.90.xt.lighting.lua:1711–1714` が `annunciator/brightness_ratio[0]`・`[1]` に出す）。
- 警報音は FMOD（`fmod/747-400.snd` の WARNINGS 節 5759–5940 行、GPWS 節 5942–6295 行）。Lua の `warning_bell`・`warning_siren`・`warning_wailer` はどの .snd も読んでいない（WARN-02）。

## 3. 操作と表示

### 3.1 EICAS メッセージ欄（primary EICAS）

- 11 行。warning は赤、caution は琥珀、advisory は琥珀で 1 字下げ、memo は白（FCOM p.1527–1528 (15.10.1–2)、p.1548 (15.20.2)）。
- 先頭の `>`（caret）は「チェックリストに操作手順が無い」印（FCOM p.1548）。
- 並び：warning を先頭に、その下に caution、その下に advisory。各レベルの中では**新しいものが先頭**で、既存のものは 1 行ずつ下がる。条件が消えたメッセージは消え、下のものが上がる（FCOM p.1548）。
- memo は最後の alert ページの下端に表示し、**新しい memo が一番下**（FCOM p.1548–1549）。alert が優先で、行が足りなければ memo の一部または全部はそのページに出ない（FCOM p.1528）。
- ページ：1 ページに収まらなければ番号付きの複数ページになり、ページ番号（PG、白）を出す。warning は各ページの先頭に繰り返す。warning だけで 1 ページを超えると PG を出さず、他のページも見られない（FCOM p.1549 (15.20.3)、p.1528）。
- 新しい非常事態のメッセージは**見ているページに**出る（例：3 ページ目を見ているときの新しい caution は warning の直下。RCL で 1 ページ目に戻ると 1 ページ目の先頭の caution になる）（FCOM p.1549）。
- RECALL 表示（白）：RCL を押している間と離してから 1 秒（FCOM p.1528）。
- STATUS cue（シアン）：新しい STATUS メッセージがあるとき。STATUS ページを表示すると消える。エンジン始動後からリフトオフ後 30 分まで抑止、secondary engine exceedance cue が出ている間も抑止（FCOM p.1528）。
- secondary engine exceedance cue（シアン）：補助 EICAS のエンジン値が超過している間（FCOM p.1529）。
- alert／memo とも、条件が無くなれば消える（FCOM p.1547）。

### 3.2 表示選択パネル

| スイッチ | 動作 | 出典 |
|---|---|---|
| CANC | 次のページの caution/advisory を表示。最後のページで押すと caution/advisory を消す（warning と memo は残る）。エンジン値の赤枠（超過が終わったもの）も消す | FCOM p.1530 (15.10.4)、p.1549 |
| RCL | 条件が残っている caution/advisory をすべて再表示し、1 ページ目を出す。赤枠も再表示。RECALL を離してから 1 秒出す | FCOM p.1530、p.1549 |
| STAT | 補助 EICAS に STATUS ページ。押すごとに次ページ、最後のページで消える | FCOM p.1530 |

- 最後のページで CANC を押すと、現在の memo がすべて表示されたことになる（FCOM p.1548）。

### 3.3 master WARNING/CAUTION 灯とリセットスイッチ

- master WARNING 灯（赤）：新しい EICAS warning メッセージ、または PFD に PULL UP・WINDSHEAR が出たとき点灯（FCOM p.1532 (15.10.6)）。ATA31 は GPWC の PULL UP・windshear 離散信号が master monitor card に入って点灯すると書く（ATA31 p.228）。
- master CAUTION 灯（琥珀）：新しい EICAS caution メッセージで点灯（FCOM p.1532）。ただし `>ENG SHUTDOWN` では点かない（FCOM p.902 (7.40.4)、p.1552 (15.20.6)）。
- リセットスイッチを押す（ATA31 は「master WARNING 灯を押す」と書き、灯がスイッチを兼ねる。ATA31 p.144、p.170）：両方の灯を消し、次の aural を止める：CABIN ALTITUDE、レバー閉が原因の CONFIG GEAR、FIRE、（405/570 と SB 後 109）OVERSPEED と PILOT RESPONSE（FCOM p.1532）。
- 灯は条件が無くなっても消える。新しい警報で再点灯（ATA31 p.144、p.173、p.228）。

### 3.4 警報音（109 を基準）

| 音 | 対象 | 消音 | 出典 |
|---|---|---|---|
| bell（鐘、間をおいて鳴る） | FIRE APU、FIRE CARGO AFT/FWD、FIRE ENG、FIRE WHEEL WELL（405/570 は FIRE MAIN DECK・FIRE MN DK も） | master リセットで消音、灯も消える | FCOM p.1550 (15.20.4)、ATA31 p.159、p.173 |
| wailer（109/405） | >AUTOPILOT DISC | 灯は master リセット。wailer は最低 1 秒鳴り、AP 切断スイッチの 2 回目の押下（自動切断なら 1 回目）または AP の再接続で止まる | FCOM p.1550、p.655 (4.10.17)、ATA31 p.170 |
| siren（リセット不可） | CONFIG FLAPS/GEAR/PARK BRK/SPOILERS/STAB、OVERSPEED（109 の SB 前）。570 は AUTOPILOT（DISC）もここ | 条件が消えるまで鳴る。master リセットは灯だけ | FCOM p.1550–1551 |
| siren（リセット可） | CABIN ALTITUDE（SB 後 109 は PILOT RESPONSE も、405/570 は OVERSPEED・PILOT RESPONSE も）。CONFIG GEAR のうちレバー閉が原因のもの | master リセットで消音 | FCOM p.1551–1552、p.1556 |
| siren ＋ 音声「WINDSHEAR ×3」 | GPWS の即時ウインドシア警報 | （灯は master リセット） | FCOM p.1555、p.1581 |
| beeper（owl） | 新しい EICAS caution（ENG SHUTDOWN を除く） | 灯は master リセット | FCOM p.1552、ATA31 p.163 |
| 音声 | GPWS（PULL UP、TERRAIN、SINK RATE、DON'T SINK、TOO LOW…、GLIDE SLOPE、BANK ANGLE、高度・ミニマム）、PWS、TCAS | — | FCOM p.1552–1556、p.1573–1581 |
| low chime | SELCAL、ACARS、客室インターホンの呼出し | — | ATA31 p.218 |

- ATA31 の音の種類：wailer は 125〜325 Hz を 400 ms 周期で変える定振幅音、siren は 250 Hz と 950 Hz の交互音、bell は間をおいた鐘、owl は 160 ms の掃引音 4 回、low chime は 580 Hz の減衰音（ATA31 p.159–160）。高度警報の level B 音は 0.8 秒（ATA34_1 p.194）。

### 3.5 STATUS ページ

- 補助 EICAS に 11 行。STATUS メッセージは MEL 参照が要る機器故障を示す（FCOM p.1545 (15.10.19)）。新しいものが先頭。STAT で複数ページを CANC/RCL と同様に送る（FCOM p.1549）。
- FCOM は STATUS メッセージの一覧を持たない（DDG に載る。FCOM p.1548）。整備資料に出る例は EICAS-MESSAGES.md §3。

### 3.6 PFD・ND 上の警報表示（警報系統との接点）

- PFD：PULL UP（赤）、WINDSHEAR（赤。他の GPWS 警報は抑止）（FCOM p.1531 (15.10.5)）。AIRSPEED LOW 時に現在速度の枠が琥珀（FCOM p.1556）。高度警報の白枠・琥珀枠（FCOM p.1559 (15.20.13)）。
- ND：TCAS の TRAFFIC、地形・障害物、PWS の表示と自動表示の規則（FCOM p.1583–1585）。表示系のノートで扱う。

### 3.7 警報系統が条件を持つ EICAS メッセージ

| メッセージ | Level | 条件 | 出典 |
|---|---|---|---|
| >CONFIG FLAPS / GEAR CTR / PARK BRK / SPOILERS / STAB | warning（siren） | §4.5 | FCOM p.1603–1604 (15.30.1–2) |
| >CONFIG GEAR | warning（siren） | §4.6 | FCOM p.1603 |
| >CONFIG SPOILERS（飛行中、405/570） | warning（siren） | §4.7 | FCOM p.1558 (15.20.12) |
| >SPEEDBRAKES EXT | caution（beeper） | §4.7 | FCOM p.958 (9.30.2) |
| >STAB GREENBAND | advisory（＋ status） | §4.8 | FCOM p.958、ATA31 p.202 |
| >CONFIG WARN SY | advisory（＋ status） | 離陸警報系統またはその EIU 入力の故障。故障時は CONFIG メッセージが出ないことも、誤って出ることもある | FCOM p.1558、p.1604、ATA31 p.270 |
| >OVERSPEED | warning（siren） | §4.10 | FCOM p.1605 (15.30.3) |
| >AIRSPEED LOW | caution（beeper） | §4.10 | FCOM p.1605 |
| >ALTITUDE ALERT | caution（beeper） | §4.11 | FCOM p.1605 |
| >PILOT RESPONSE | advisory → caution → warning | §4.12 | FCOM p.1606 (15.30.4) |
| ILS ANTENNA | caution（beeper） | G/S または LOC アンテナの切替不良（切替は configuration warning card） | FCOM p.1429、ATA31 p.226 |

## 4. 内部ロジック

### 4.1 メッセージの管理（EIU 側の振る舞いとして FCOM から組み立てる）

1. 各メッセージに属性を持たせる：文言、レベル、aural の種類、リセット可否、抑止の分類（§4.4）、「他メッセージで抑止される」関係、時間遅れ（§4.4.2）、型式。
2. 条件が立った時刻を記録し、レベルごとに新しい順に並べる。
3. caution/advisory には「CANC 済み」の印を個別に持つ。最後のページで CANC → その時点で出ている caution/advisory に印を付けて隠す。**その後に立ったものは表示する**。RCL → 印をすべて外し 1 ページ目へ（FCOM p.1530、p.1549）。
4. ページ割り：1 ページ 11 行。warning（W 行）は各ページの先頭。残り 11−W 行に caution → advisory の順。memo は最後の alert ページの下端から上へ（新しい memo が一番下）。足りなければ memo は出さない（ページ番号を増やして memo だけのページを作るかは資料に記載なし。FCOM は「最後のページで CANC すれば memo はすべて表示された」とだけ書く。推定：memo だけのページも作る）。
5. W ≥ 11 なら 1 ページだけ、PG なし、CANC でページ送りしない（FCOM p.1549）。
6. 新しい alert は見ているページに差し込む（FCOM p.1549）。実装は「表示順のリスト」と「見ているページの先頭位置」を分けて持てばよい。
7. ページ番号はページが 2 以上のときだけ出す（FCOM p.1528）。

### 4.2 master 灯

- master WARNING：新しい warning（PULL UP・WINDSHEAR を含む）が立った瞬間にラッチ。リセット押下または全 warning（と PULL UP・WINDSHEAR）の消滅で消灯（FCOM p.1532、ATA31 p.144、p.228）。
- master CAUTION：新しい caution（ENG SHUTDOWN を除く）でラッチ。リセットまたは全 caution 消滅で消灯（FCOM p.1532、p.902）。
- 抑止中（§4.4）に立ったものは灯も音も抑え、抑止が終わったときに灯を点け音を鳴らす（FCOM p.1588–1589、p.1594–1595）。

### 4.3 警報音の生成と優先順位

- 優先順位（ATA31 p.159–160）：wailer（最上位）> siren > bell > owl（beeper）> chime（最下位）。GPWC の音声は優先順位を持たず、他の音に重ねて流す。
- 低い音は高い音が止むまで待たされる（例：試験で siren と owl が同時に出ると、owl は siren がリセットされるまで遅れる）（ATA31 p.264）。
- level A aural（wailer・siren・bell）は master monitor card が種類ごとの離散信号で ASC に要求し、level B（owl）は configuration warning card・crew alerting card・EIU から直接 ASC へ（ATA31 p.163）。
- リセット可否（§3.4）。T/O CONFIG の siren は「形態の是正」「enable の消滅」「T/O WARN inhibit の開始」で止まる（ATA31 p.194）。OVERSPEED の siren は速度が戻るまで続く（ATA31 p.176。FCOM では 109 SB 前と同じ）。
- 音声の優先と抑止（FCOM p.1582–1583）：
  - GPWS の即時ウインドシア警報は、PWS（405/570）・TCAS・他の GPWS 警報をすべて抑止する。
  - GPWS（405/570 は PWS も）の warning 警報中、TA/RA 選択でも TCAS は TA ONLY になり、RA 中なら RA を打ち切って TA にする。警報が終われば TA/RA に戻る。
  - warning の音声は新しい caution の音声を抑止する。
  - 自動表示の優先：即時ウインドシアは新しい TCAS（405/570 は地形・PWS も）の自動表示を抑止する（FCOM p.1583）。
- ASC の利得は飛行状態（crew alerting card が master monitor card の飛行データと EIU の離陸推力信号から決める）で自動調整、データが無ければプログラムピンで 0 dB（ATA31 p.166）。シムでは不要（推定：FMOD の音量で足りる）。

### 4.4 抑止（inhibit）

#### 4.4.1 他メッセージによる抑止（FCOM の各章から）

- 例として FCOM 15.20 が挙げるもの：燃料・油圧の個別ポンプ圧メッセージは系統圧メッセージで抑止（FCOM p.1582 (15.20.36)）。
- 各章の表にある組合せ：ELEC BUS ISLN・ELEC GEN OFF ← ELEC AC BUS、ELEC DRIVE ← DRIVE DISC 押下、ELEC UTIL BUS ← 負荷制限中、FUEL PUMP ← FUEL PRESS ENG、HYD PRESS ENG・HYD PRESS DEM ← HYD PRESS SYS、JETT NOZ ON L/R ← JETT NOZ ON、FUEL JETT A/B ← FUEL JETT SYS、FUEL PMP STB ← FUEL STAB XFR、CON IGNITION ON ← ENG IGNITION、GEAR DOOR ← 代替脚下げ、FUEL LOW CTR・FUEL TANK/ENG ← ジェティソン中、ENG CONTROL・ENG CONTROLS・EIU LEFT・E/E CLNG CARD ← 飛行中（EICAS-MESSAGES.md の条件欄）。
- 実装は警報モジュールの表に「抑止元」を書く方式が扱いやすい（推定）。

#### 4.4.2 時間遅れ

- 弁は開／閉の位置しか検出しないので、移動中は「指令位置にない」系のメッセージを遅らせ、時間内に着かなければ表示する（FCOM p.1583 (15.20.37)）。遅れの秒数は資料に記載なし（系統ごとの値は各系統のノート）。ALT DISAGREE・IAS DISAGREE は 5 秒、BARO DISAGREE は 1 分（FCOM p.1197–1198）。

#### 4.4.3 エンジン始動前・停止後（FCOM p.1586 (15.20.40)）

- master CAUTION 灯と beeper：地上で**全** FUEL CONTROL が CUTOFF の間、すべての caution で抑止（メッセージは出る）。
- ELEC GEN OFF、ENG CONTROL、ENG SHUTDOWN、ENG EEC MODE、ENG FAIL、ENG OIL PRESS、HYD PRESS ENG、NAI VALVE：地上で当該 FUEL CONTROL が CUTOFF または当該 Fire スイッチが出ている間、メッセージを抑止。

#### 4.4.4 エンジン始動中（FCOM p.1587 (15.20.41)）

- 新しい caution/advisory を抑止。例外：BLEED、ENG AUTOSTART（405 には無い）、ENG FUEL VALVE、ENG SHUTDOWN、ENG START VLV、STARTER CUTOUT。
- 開始：Engine START スイッチを引いたとき。終了：エンジンがアイドル回転に達した、始動中止、または 5 分経過。

#### 4.4.5 離陸（109、FCOM p.1593–1595 (15.20.47–49)。405/570 の差は末尾）

| 抑止されるもの | 対象 | 開始 | 終了 |
|---|---|---|---|
| ENG FAIL（caution） | メッセージ | 地上 | リフトオフ |
| TCAS OFF（advisory） | メッセージ | 地上 | RA 400 ft |
| TCAS TA の音声 | TA | 地上 | 約 500 ft RA |
| すべての TCAS RA | RA（TA ONLY 表示） | 地上 | 約 1,000 ft RA |
| TCAS DESCEND RA | RA | 地上 | 約 1,100 ft RA |
| STATUS cue | 新しい STATUS メッセージ | エンジン始動 | リフトオフ後 30 分 |
| Hi chime | 客室乗務員呼出し | いずれかのエンジンが離陸推力域 | RA 400 ft |
| master CAUTION 灯・beeper | 新しい caution | 80 kt | RA 400 ft またはローテーション後 20 秒の早い方。80 kt 超で RTO なら 75 kt 未満まで継続 |
| WINDSHEAR SYS（advisory） | メッセージ | 80 kt | RA 400 ft |
| master WARNING 灯・bell | 新しい FIRE | V1 | RA 400 ft または V1 後 25 秒の早い方 |
| master WARNING 灯・siren | 新しい warning（CONFIG GEAR と FIRE を除く） | V1 | 同上 |
| CONFIG GEAR | メッセージ | リフトオフ | RA 800 ft または前脚ストラットのリフトオフ後 140 秒の早い方 |
| FUEL TANK/ENG（advisory） | リフトオフ後に条件が立った場合のメッセージ | リフトオフ | リフトオフ後 10 分 |

- 抑止前に点いた灯・鳴った音はそのまま続き、抑止中は消せない。抑止中に立った警報は終了時に音が鳴る（FCOM p.1594–1595 の注記）。
- 405：master CAUTION の終了が RA 800 ft またはローテーション後 30 秒（FCOM p.1591 (15.20.45)）。405/570：新しい PWS caution は 80 kt〜400 ft、新しい PWS warning は 100 kt〜50 ft で抑止（FCOM p.1588、p.1591）。
- 整備資料の論理（ATA31 p.180、p.196、図 p.181・p.197）：
  - level A（warning）と離陸警報の抑止は master monitor card が作る。開始：VCAS ≥ V1 かつ T/O 形態警報 enable。VCAS か V1 が無効ならピッチ 5° 超で開始。終了：RA > 400 ft、または開始から 25 秒。
  - V1 で離陸警報は disarm、グリーンバンド灯も消える（ATA31 p.180）。
  - 脚上げで 140 秒タイマーが始まり、リセット可の着陸形態警報を抑止（ATA31 p.180）。ATA27 は「脚の down & locked 信号が消えた時点から、RA 800 ft 超または 140 秒で解除。ただし 2 本を超えるスラストレバーがグライドスロープ出力位置より下に戻されたら抑止しない」（ATA27 p.736 (27-90)）。
  - SELCAL チャイムは離陸推力から RA 800 ft まで抑止（ATA31 p.181 の図）。FCOM の Hi chime（客室乗務員呼出し）は RA 400 ft まで。

#### 4.4.6 着陸（109、FCOM p.1600–1602 (15.20.54–56)）

| 抑止されるもの | 対象 | 開始 | 終了 |
|---|---|---|---|
| TCAS INCREASE DESCENT RA | RA | 約 1,500 ft RA | 約 1,500 ft でのゴーアラウンド |
| TCAS DESCEND RA | RA | 約 1,100 ft RA | 約 1,100 ft でのゴーアラウンド |
| すべての TCAS RA | RA（TA ONLY） | 約 1,000 ft RA | 約 1,000 ft でのゴーアラウンド |
| STATUS cue・Hi chime | | RA 800 ft | 75 kt |
| TCAS TA の音声 | | 約 500 ft RA | 約 500 ft でのゴーアラウンド |
| WINDSHEAR SYS（advisory） | | RA 400 ft | 80 kt |
| TCAS OFF（advisory） | | RA 400 ft | 400 ft でのゴーアラウンド |
| master CAUTION 灯・beeper | 全 caution。例外：AUTOPILOT、AUTOTHROTTLE DISC、NO AUTOLAND、SPEEDBRAKES EXT | PFD に LAND 2 または LAND 3 が出ていて RA 200 ft | 75 kt、40 秒経過、または RA 800 ft（ゴーアラウンド）の早い方 |

- 405/570：PWS は 2,300 ft〜1,200 ft で抑止、新しい PWS caution は 400 ft〜80 kt、新しい PWS warning は 50 ft〜100 kt（FCOM p.1599–1600）。

### 4.5 離陸形態警報（configuration warning card）

- 乗員に見える条件（FCOM p.1557 (15.20.11)、p.1603）：地上、FUEL CONTROL が RUN（15.30 は「3 本以上」）、エンジン 2 **または** 3 が離陸推力域、速度が V1 未満、かつ次のいずれか → 該当の CONFIG メッセージ＋siren＋master WARNING：
  - フラップが離陸位置でない（CONFIG FLAPS）
  - ボディギアが中立でない（CONFIG GEAR CTR）
  - 駐機ブレーキ ON（CONFIG PARK BRK）
  - スピードブレーキレバーが DN でない（CONFIG SPOILERS。ARMED も含む）
  - スタビがグリーンバンド外（CONFIG STAB）
- メッセージは、形態を直すまで、またはエンジン 2・3 の推力が離陸推力域を下回る（かつ V1 未満）まで残る（FCOM p.1557）。ATA27 は「離陸推力を外してから 10 秒、または正しい形態にした時点で消える」（ATA27 p.730）。
- enable（master monitor card、ATA31 p.188 と図 p.189）：T/O WARN inhibit が無く、かつ
  - 地上で（RA 失効 または RA ≤ 15 ft または V1 有効）、または
  - （V1 有効 または RA ≤ 0 ft）かつピッチ < 5°。
  - 一度立つと T/O WARN inhibit までラッチ。
- enable inop（ATA31 p.190）：CAS 入力が故障、または CAS が NCD で「空中でピッチの SSM が異常」か「RA・ピッチ・V1 の SSM がすべて異常」のとき enable を禁止。
- arm（ATA31 p.193、ATA27 p.729）：enable、enable inop でない、FUEL CONTROL 3 本以上 RUN、内側エンジン（2 か 3）のどちらかが離陸推力（どの EIU の信号でもよい）。
- 離陸推力の判定値（ATA27 p.730）：内側エンジンの N1 表示が P&W 66.5、RR 66.7、GE 75.0 を超える（単位の記載は無いが N1 % と読める）。シムでは型式で切り替える。
- 各条件の中身（ATA27 p.729–730、ATA31 p.193）：
  - フラップ：後縁が 10 または 20、かつ前縁全群が展開なら離陸位置。FCU はレバー位置と実位置も比べ、食い違えば警報（ATA31 p.193）。
  - CONFIG GEAR CTR：ボディギアのステアリング作動器が主系統と代替系統の両方で非ロック（ATA27 p.730、p.745）。
  - CONFIG PARK BRK：機長ブレーキペダル機構のマイクロスイッチ。
  - CONFIG SPOILERS：スピードブレーキドラムのマイクロスイッチ（レバーが DN 位置でない）。ATA31 は「speed brake armed」と書く（ATA31 p.193）。
  - CONFIG STAB：FCU のスタビ位置（左優先）をグリーンバンド（§4.8）と比べる。
- 空地・ステアリングロックは PSEU（バス A 優先）から、FUEL CONTROL の RUN は左 EIU 優先（ATA31 p.184–185）。
- リセット：siren はリセット不可。灯だけ消せる（ATA31 p.194）。
- 試験：CMC の T/O WARNING（押している間／10 秒）または MAWEA の T/O CONFIG ジャック。試験信号はエンジン 2・3 の N1 入力の代わりになる。グリーンバンド灯も点く（ATA27 p.742、ATA31 p.258–260）。

### 4.6 着陸形態警報（CONFIG GEAR）

- FCOM（p.1557–1558 (15.20.11–12)）：飛行中、いずれかの脚が down & locked でなく、かつ
  - いずれかのスラストレバーが閉で RA 800 ft 未満 → スラストレバーを進めるか脚が下りるまで表示。siren と灯は master リセットで止まる（FCOM p.1556）。
  - フラップが着陸位置（25 以上） → 脚が下りるか GND PROX GEAR OVRD を押すまで表示。siren はリセット不可。
- ATA31（p.209–214）と ATA27（p.732–736）：
  - **リセット可の警報**：RA ≤ 800 ft かつ いずれかのスロットルが TLRA 55° 未満 かつ 脚が down & locked でない。master リセットで灯と siren が止まり、その時点で戻されているレバーを記憶する。全レバーが 55° より前に出ると記憶を消し、別のレバーが 55° 以下に戻されると新しい警報。脚下げ、RA 800 ft 超、レバーを進める、で解除（EICAS メッセージはリセットしても残る）。
  - **リセット不可の警報**：フラップ 25 または 30 かつ脚が down & locked でない。GND PROX CONFIG GEAR OVRD スイッチで siren が止まる。ATA31 は「EICAS の CONFIG GEAR は残る」と書き、FCOM は「OVRD で消える」と書く → 表示は FCOM に従う。
  - レバーの判定値：ATA31 と ATA27 の図（p.745）は 55°、ATA27 の本文（p.735）は「グライドスロープ出力に相当する 75° TLRA」。2 資料が一致する 55° を採る。TLRA とシムのレバー比の対応は資料に記載なし（§6）。
  - RA は左優先、両方失うと 800 ft 未満とみなす（ATA27 p.735）。脚は PSEU バス A 優先（ATA31 p.210）。
  - 脚上げ後の抑止は §4.4.5。

### 4.7 スピードブレーキ警報（SPEEDBRAKES EXT）と飛行中の CONFIG SPOILERS

- FCOM（p.958 (9.30.2)）：レバーが ARMED より後ろ、かつ（RA 15〜800 ft、またはフラップ着陸位置、またはスラストレバー 2 本以上が閉より前） → caution＋beeper＋master CAUTION。
- ATA31 p.220–222：enable は「RA 15〜800 ft」「フラップ 25/30 かつ RA > 15 ft」「2 本以上のレバーが TLRA 43° 超かつ RA > 15 ft」のいずれか。ATA27 本文は 40° TLRA（p.740）、ATA27 の図は「アイドルストップより 5° 以上前」かつ「脚が down & locked でない」も条件に加える（p.747）。FCOM に脚の条件は無いので FCOM に従い、レバーは「閉位置より前」で判定する。
- 地上（RA < 15 ft）では出ない（各資料）。
- 飛行中の CONFIG SPOILERS（405/570 のみ、FCOM p.1558）：レバーが ARM より後ろ、かつ 2 本以上のレバーが上昇推力以上 → warning＋siren。レバーを DN/ARM に戻すか、3 本以上を上昇推力未満にするまで表示。109 には無い（FCOM p.1604）。

### 4.8 スタビのグリーンバンド

- configuration warning card が GW・CG・離陸推力定格（FMC → EIU。左 FMC 優先）から 3 つの帯（機首下げ、中間、機首上げ）を選ぶ（ATA31 p.200–201）。中間帯は計器照明で常時点灯、機首下げ／上げの灯は計算結果で点く。
- 灯が点くのは：地上で T/O 形態警報 enable があり、有効な CG を受け、FUEL CONTROL が 2 本以上 RUN のとき。warning inhibit（V1）で消える（ATA31 p.200、p.180）。
- 前脚オレオの圧力スイッチで粗いチェック：機首上げ帯なら「機首上げ（前方 CG）」、機首下げ帯なら「機首下げ（後方 CG）」を示すはず。中間帯は無視。食い違えば STAB GREENBAND（advisory と status）を出すが、選んだ帯はそのまま離陸警報に使う（ATA31 p.201–202）。ATA27 は「地上のみ」と書く（p.747）。
- CG が 33% MAC 超または 8.5% MAC 未満は無効：灯を全部消し STAB GREENBAND（ATA31 p.202）。
- 帯の具体的な境界（ユニット値）は資料に記載なし。FCOM の性能章・FMC の TAKEOFF REF の TRIM 値との関係も資料に記載なし。

### 4.9 失速警報（スティックシェーカー）

- SWMC 左右（ATA27 p.692、p.701）。
  - 入力：PSEU（脚位置）、FCU（フラップ位置）、スポイラー位置（Vmin 表示の計算だけに使う）、IRU（ピッチ角加速度）、ADC（AOA、TAS、Mach、CAS、高度、Vmo/Mmo）。
  - 前縁・後縁フラップ位置から alpha max を決め、Mach・CAS・前脚・スピードブレーキで補正して上限 AOA を作る。ピッチレートと速度で補正した AOA がこれを超えるとシェーカーの接地回路を閉じる。各 SWMC が両方のシェーカーを動かす。
  - 出力：PLI のパラメータ（GPWC と、EIU 経由で FMC → PFD の PLI）、速度テープのパラメータ（Vmo、Vss＝シェーカー速度）。
- FCOM：左右のスティックシェーカーが操縦桿を振る（FCOM p.1556 (15.20.10)）。PFD の minimum speed はシェーカーまたは低速バフェットの速度（FCOM p.973 (10.10.11)）。
- 過回転でもシェーカーを動かす（ATA31 p.136）。条件は資料に記載なし。
- 電源投入時の BITE ではシェーカーは動かない。CMC の確認試験と MAWEA の試験ジャックでは約 10 秒動き、STALL WARN SYS（status）が出る（ATA27 p.701、p.706、p.712）。
- 地上の扱い（空地で抑止するか）は資料に明記なし。試験が「地上、AOA と CAS が NCD」を条件にする（ATA27 p.706）ことから、通常は地上で動かないと推定。

### 4.10 オーバースピード、AIRSPEED LOW、PA 音量

- OVERSPEED：Vmo/Mmo を超えると表示し、下回るまで残る（FCOM p.1557 (15.20.11)）。ADC の overspeed 離散信号（左・中央 ADC → MMA、右・中央 ADC → MMB）で siren と灯（ATA31 p.176）。フラップ・脚の制限速度は対象外（FCOM の記述は Vmo/Mmo だけ。PFD の maximum speed は Vmo/Mmo・脚・フラップの最小値（FCOM p.969 (10.10.7)）だが、警報は Vmo/Mmo）。
- VMO GEAR DOWN／VMO SPARE ENGINE（memo）：電子機器室で選ぶと ADC の Vmo/Mmo が脚出し速度・スペアエンジン運搬速度になる（FCOM p.1557）。
- AIRSPEED LOW：速度が最小機動速度（amber 帯の上端）未満で caution と PFD の琥珀枠（FCOM p.1556）。最小機動速度はフラップ下げで「シェーカーまで 1.3 g」、フラップ上げで 20,200 ft 未満は「シェーカーまで 1.3 g または VREF+80 の小さい方」、それより上は「低速バフェットまで 1.3 g」。離陸後の最初のフラップ上げから表示（FCOM p.973）。
- PA 音量：Vmo/Mmo の 15 kt 以内で crew alerting card が PA の音量を上げる信号を出す（ATA31 p.230）。

### 4.11 高度警報（crew alerting card）

- 接近：選択高度の 900 ft 手前で PFD の選択高度と現在高度に白枠。300 ft 以内で消える（FCOM p.1559 (15.20.13)、ATA34_1 p.183）。
- 逸脱：選択高度に一度 300 ft 以内まで近づいて警報が arm された後、300 ft を超えて離れると ALTITUDE ALERT（caution）、master CAUTION、level B 音（0.8 秒）、現在高度の琥珀枠（ATA34_1 p.180、p.191、p.194）。
- 解除：300 ft 以内に戻る、新しい MCP 高度を選ぶ、900 ft を超えて離れる（FCOM p.1559、ATA34_1 p.184）。
- 抑止：グライドスロープ捕捉、または着陸フラップかつ脚 down & locked（FCOM p.1559）。ATA は選択高度の変更中（rate detector）も抑止し、地上で駐機ブレーキ ON なら抑止しない（試験用）（ATA34_1 p.192）。
- 高度は FCC の in-command に応じて左／右 ADC（ATA34_1 p.190）。

### 4.12 乗員覚醒監視（PILOT RESPONSE、405/570 と SB 後 109）

- FMC が MCP・EFIS パネル・EICAS パネル・CDU・VHF/HF の PTT の操作を監視。所定時間操作が無い、または最近の操作なしで T/D を過ぎると advisory、さらに短時間で caution（beeper）、さらに warning（siren、リセット可）。監視対象の操作で消える。20,000 ft 未満で抑止（FCOM p.1559、p.1606）。所定時間の値は資料に記載なし。

### 4.13 STATUS メッセージと STATUS cue

- STATUS cue の抑止：エンジン始動〜リフトオフ後 30 分（FCOM p.1528、p.1593）、着陸時 RA 800 ft〜75 kt（FCOM p.1600）、secondary engine exceedance cue 表示中（FCOM p.1528）。
- 一覧は DDG にあり資料に記載なし。MAWEA 関係は EICAS-MESSAGES.md §3。

### 4.14 チャイム

- low chime：SELCAL・ACARS・客室インターホンの呼出し。crew alerting card が離着陸中は抑止（ATA31 p.218）。期間は §4.4.5・§4.4.6（SELCAL は離陸推力〜800 ft、Hi chime は離陸 400 ft まで、着陸 800 ft〜75 kt）。

### 4.15 MAWEA の故障

- 電源 1 台の故障では機能は維持し、MAWEA PWR SUPPLY（status）（ATA31 p.153）。ASC 1 台の故障ではもう 1 台が両スピーカーを駆動（ATA31 p.168）。形態警報カードの故障で CONFIG WARN SY（ATA31 p.270）。シムでは故障の注入をしない限り不要（§6）。

## 5. 他系統とのつながり

| 相手 | 入力（→ 警報系統） | 出力（警報系統 →） | 出典 |
|---|---|---|---|
| PSEU（脚・空地） | 空地、全脚 down & locked、前脚 down & locked、ボディギアステアリングのロック | — | ATA31 p.184、p.210、p.226 |
| FCU 左・右（操縦） | 前縁・後縁フラップ位置、フラップレバー、スタビ位置 | — | ATA31 p.184、p.209 |
| 電波高度計 左・右 | RA | — | ATA31 p.209 |
| ADC 左・中央・右 | CAS、overspeed 離散、Vmo/Mmo、気圧高度、AOA | — | ATA31 p.103、p.176、ATA27 p.698 |
| IRS | ピッチ角（離陸警報の enable・抑止）、ピッチ角加速度（失速） | — | ATA31 p.188、ATA27 p.692 |
| EIU 左・中央・右（表示） | 内側エンジンの離陸推力信号、FUEL CONTROL の RUN、4 本のスラストレバー位置（TLRA）、客室高度、FMC の GW・CG・推力定格 | EICAS メッセージ（EIU が生成）、形態警報の内容 | ATA31 p.108、p.185、p.200、p.209 |
| FCC 左・中央・右（AFDS） | AP 切断（通常用と電池運用時の 2 系統） | — | ATA31 p.170 |
| GPWC | 音声（増幅のみ）、PULL UP・windshear 離散 | master WARNING 灯 | ATA31 p.228 |
| TCAS | 音声（増幅のみ） | — | ATA31 p.228 |
| 火災探知 | エンジン・APU・貨物室・脚格納部の火災離散、試験 | — | ATA31 p.173–174 |
| 与圧（EIU 経由） | 客室高度 > 10,000 ft | — | ATA31 p.178 |
| 操縦室スイッチ | master リセット、駐機ブレーキ、自動スピードブレーキ arm スイッチ（レバー DN）、スピードブレーキ extend スイッチ（ARM より後ろ）、前脚オレオ圧力スイッチ、GND PROX GEAR OVRD | グリーンバンド灯、master 灯 | ATA31 p.110、p.150、ATA27 p.720、p.735 |
| 通信 | SELCAL・ACARS・客室インターホンの呼出し | チャイム、PA 音量 | ATA31 p.114、p.218、p.230 |
| 客室サイン | 減圧リレー | サイン点灯（AUTO） | ATA31 p.233–234 |
| ILS | — | 中央 G/S アンテナ切替（前脚 down & locked でトラックアンテナへ） | ATA31 p.226 |
| FDR | — | DFDAC は MAWEA 内（警報機能なし） | ATA31 p.130 |

- シムの主な dataref／コマンド（INTERFACES.tsv にあり、名前と意味を変えないもの）：`laminar/B747/CAS/gen_{warning,caution,advisory,memo}_msg_000〜021`（パネル）、`CAS/msg_page`・`num_msg_pages`・`recall_ind`・`caution_status`（パネル）、`warning/master_warning`・`master_caution`・`master_caution_audio`（snd）、`button_switch/warn_caut_capt`・`_fo`（obj・snd）、`dsp/canc_switch`・`rcl_switch`・`stat_switch` とその `switch_pos`（obj・snd）、`dsp/synoptic_display`（パネル）、`fire/fire_ovht/button_pos`（obj・snd）、`annunciator/brightness_ratio`（obj）。

## 6. 実装上の注意

- **メッセージ表を 1 つにする**：init 側と xt 側に同じ表があり、すでに食い違っている（WARN-07）。init 側は配列の大きさにしか使わないので、件数だけ持つか、同じファイルを両方から読む形にする（XTLua の init と xt の両方から同じファイルを `dofile` できるかは未確認）。添字は他モジュールが直接書くので、作り直しでも既存の添字は動かさず、追加は末尾にする。
- **条件の判定は各系統、表示・灯・音・抑止は警報モジュール**という今の分担は残す。抑止（§4.4）と CANC 済みの印は警報モジュールで一括管理し、各系統は「条件が成立した」だけを書く。ただし離陸／着陸形態警報・スピードブレーキ警報・グリーンバンドは実機でも MAWEA の機能なので、fltCtrls から警報モジュールへ移すのが筋（推定：保守の見通しがよくなる）。
- **更新周期**：現在は 2 秒ごと（WARN-10）。表は数百件でも毎フレーム回して問題ない量。少なくとも 0.1〜0.2 秒にする。
- **XTLua の非同期書き込み**：dataref に書いた値は同じフレームでは読めない前提で、状態はローカル変数で持つ（ARCHITECTURE.md §1）。表示行を作ってから書くこと（今の `B747_CAS_display` は書いた直後の dataref を読んでいる：`B747.87.xt.warning.lua:932`）。
- **パネルの制約**：CAS 行は 11 行 × 2 ページ分（`gen_*_msg_000〜021`）しか描かれない。PG 表示は `num_msg_pages > 2` のときだけ（`747-400.acf:117872`）。STATUS メッセージ行・STATUS cue・secondary engine exceedance cue・高度警報の枠は描かれていない。これらを直すにはカスタム acf のパネル変更（要承認）が要る。純正 acf は変えない。Lua だけで直せるのは 2 ページ以内の並びと内容まで。
- **FMOD**：siren は `master_warning`、beeper は `master_caution` の立ち上がり、bell は X-Plane の `sim/cockpit/warnings/annunciators/engine_fire` と火災試験ボタン、wailer は X-Plane の `sim/cockpit/warnings/annunciators/autopilot_disconnect`、失速は `sim/cockpit2/annunciators/stall_warning` に結ばれている（`fmod/747-400.snd:5762–5865`）。リセット可否・優先順位を FCOM どおりにするには .snd の結線変更（`warning_bell`・`warning_siren`・`warning_wailer`・`master_caution_audio` を使う）が要る。音は対象外という前提なので、変更には承認が要る。代案は「`master_warning` を『level A の音が鳴っている』と定義し直し、灯は別の値で lighting に渡す」だが、INTERFACES の意味の変更になるので同じく承認が要る。
- **.snd のファイル名**：`fmod/` にあるのは `747-400.snd`、`747-400F.snd`、`747-400D.snd`、`747-400LCF.snd`、`747-400_XP11.snd` で、`747-400_custom.snd` は無い。X-Plane が acf と同名の .snd を読む規則なら、カスタム acf では FMOD の警報音が一切鳴らない（未確認。§9）。
- `sounds/alert/*.wav` は X-Plane の旧式警報音の差し替え。`747-400.snd` が `DISABLE_LEGACY_ALERT_SOUNDS` を指定しているので使われていないと推定。
- **X-Plane 本体の警報機能**：GPWS（`sim/cockpit/warnings/annunciators/GPWS` など）、高度警報（`baro_altimeter_alert_lit_pilot`）、失速警報を FMOD と PFD が直接使っている。acf の `_warn_*`・`_stall_warn_*` は純正・カスタムで同じ（`acf/_warn_alt_dep_100 1`、`acf/_warn_airliner 1`、`acf/_stall_warn_aoa 15` など。確認済み）。ACF_DIFF.md に警報系統の項目は無い。失速警報はコードが `acf_has_stallwarn = 0` にして X-Plane 側を止め、自前で `sim/flightmodel/failures/stallwarning` を書く（`B747.60.xt.fltInst02.lua:3577`、`3118–3123`）ので、acf の失速 AOA は効かない。
- **スラストレバーの位置**：EEC は `override_throttles` の下で推力を `sim/flightmodel/engine/ENGN_thro_use` に書き、場面によっては 4 本のレバーの**平均**を `sim/cockpit2/engine/actuators/throttle_jet_rev_ratio_all` に書く（`B747.42.xt.EEC.lua:805, 926, 994`）。警報のレバー判定は 1 本ずつ見る必要があるので `laminar/B747/engine/throttle[4]`（INTERFACES の obj・snd 参照。A/T も動かす表示上のレバー）を使う。TLRA（度）とこの 0〜1 の対応は資料に記載なし。推定案：「閉」＝アイドル位置（0 付近の小さい閾値）、離陸推力域は ATA27 の N1 判定値で判断し、レバー角は使わない。
- 簡略化してよいもの：MAWEA のカード構成、電源 2 台の冗長、ASC の相互監視、自動利得、BITE、カードの LED（故障注入をしない限り見えない）。チャイムは FMOD のイベント結線で十分。
- 簡略化してはいけないもの：レベルと色、新しい順の並び、CANC/RCL の意味、master 灯のラッチとリセット、音のリセット可否、離陸・着陸の抑止（特に 80 kt〜400 ft の master CAUTION 抑止と V1〜400 ft の warning 抑止）、形態警報の arm 条件と判定値、ENG SHUTDOWN で灯を点けないこと。

## 7. 現状実装との比較（GAP 候補）

| ID | 種別 | 重要度 | 規模 | 内容 | 根拠 | 該当コード |
|---|---|---|---|---|---|---|
| WARN-01 | バグ | 高 | S | 最後のページで CANC を押すと `caut_adv_display = 0` になり、**その後に立った caution/advisory も RCL を押すまで一切表示されない**（master CAUTION と beeper だけ出る）。FCOM は新しい非常事態のメッセージを表示する。個別の「CANC 済み」印が要る | FCOM p.1530 (15.10.4)、p.1549 (15.20.3) | `B747.60.xt.fltInst02.lua:1467-1479`、`B747.87.xt.warning.lua:943` |
| WARN-02 | 挙動の誤り | 高 | M | siren が master WARNING 灯（`master_warning`）に結ばれている。灯が点いている間は**どの warning でも siren**（火災なら bell と同時、AP 切断なら wailer と同時、火災試験でも）で、master リセットで灯を消すと siren も止まる → T/O CONFIG、フラップが原因の CONFIG GEAR、109 SB 前の OVERSPEED など**リセット不可の siren が止まってしまう**。Lua の `warning_bell/siren/wailer` はどの .snd も読まない。wailer は X-Plane の AP 切断 annunciator 駆動で、FCOM の「最低 1 秒、2 回目の押下で停止」とは別物。直すには .snd の結線変更（要承認） | FCOM p.1550–1552 (15.20.4–6)、p.655 (4.10.17)、ATA31 p.170、p.176、p.194 | `fmod/747-400.snd:5792-5823`、`B747.87.xt.warning.lua:804-834` |
| WARN-03 | 挙動の誤り | 高 | S | bell は X-Plane の `engine_fire` annunciator と火災試験ボタンで鳴るので、**master リセットで消音できない**。APU・貨物室・脚格納部の火災では鳴らない（FIRE APU・CARGO・WHEEL WELL の各メッセージ自体も立たない。条件は火災ノート）。火災試験の TEST IN PROG／FIRE TEST PASS/FAIL も出ない | FCOM p.1550 (15.20.4)、p.919 (8.20.7)、ATA31 p.173 | `fmod/747-400.snd:5825-5851`、`B747.87.xt.warning.lua:817-828`、`B747.35.xt.fire.lua:98-103, 487-513` |
| WARN-04 | 挙動の誤り | 中 | S | beeper は `master_caution` の立ち上がりで 1 回鳴るだけなので、master CAUTION が点いたまま次の caution が立っても**鳴らない**。1 秒パルスの `master_caution_audio` は `747-400_XP11.snd` しか使っていない | FCOM p.1552 (15.20.6) | `fmod/747-400.snd:5774-5791`、`B747.87.xt.warning.lua:842-844` |
| WARN-05 | 欠落 | 高 | M | **抑止が一切無い**：始動前（全 FUEL CONTROL CUTOFF の地上で master CAUTION・beeper を抑止）、始動中、離陸（80 kt〜400 ft/20 秒の caution、V1〜400 ft/25 秒の warning、リフトオフ〜800 ft/140 秒の CONFIG GEAR、ENG FAIL の地上抑止など）、着陸（LAND 2/3 かつ 200 ft〜）、STATUS cue、他メッセージによる抑止（§4.4.1）、時間遅れ。結果として電源投入時や離陸滑走中にも master CAUTION と beeper が出る。`>ENG SHUTDOWN` でも master CAUTION と beeper が出る | FCOM p.1586–1602 (15.20.40–56)、p.902 (7.40.4)、ATA31 p.180、p.196 | `B747.87.xt.warning.lua:795-887` |
| WARN-06 | 挙動の誤り | 高 | S | **表のレベル誤り**：ENG 1–4 FAIL が warning（FCOM は caution。赤・master WARNING・siren になる）、ELEC GEN OFF 1–4 が caution（109/570 は advisory）、FUEL PRES STB L/R が caution（advisory）、>SMOKE LAVATORY・TIRE PRESSURE の caution 版と DOOR U/D FLT LK の advisory 版という誤った重複定義。既報の caution 67・68（`FUEL PRES STAB L` が 2 つ）もここ | FCOM p.899 (7.40.1)、p.822 (6.30.2)、p.1476 (12.30.4)、p.923、p.1522、p.546 | `B747.87.xt.warning.lua:101-104, 161, 173, 175-176, 179-182, 264` |
| WARN-07 | バグ | 低 | S | **文言・添字の誤り**：memo の DRindex 41 が `ACARS CALL` と `ACARS VOICE` で重複、`PRINTER MESSAGE` が 2 つ、`FUEL OVRD CTR`（FCOM `>FUEL OVD CTR`）、`FUEL PMP STAB`（`>FUEL PMP STB`）、`>FUEL TEMP LOW`・`>WINDSHEAR SYS` の余分な `>`、`IRS … CENTRE`（`CENTER`）。init 側の表は `SPEEDBRAKE ARMED` が無く `IRS ALIGN MODE` の順が逆で、配列の大きさは偶然足りているだけ | EICAS-MESSAGES.md §2 | `B747.87.xt.warning.lua:339-340, 345-346, 358, 411-417, 484, 521, 534-536`、`init/scripts/B747.87.warning/B747.87.warning.lua:439-471` |
| WARN-08 | 欠落 | 中 | M | **表に無い FCOM メッセージ**（約 30 件：OVHT ENG NAC、>ENG LIM PROT、ENG EEC MODE・FUEL VLV・LOW IDLE・OIL FILT・OIL PRESS、>BTL LO ENG、>AUTOSTART OFF、>ENG CONTROLS、SATCOM 系、ATC MESSAGE、SATCOM CALL、貨物機の DOOR NOSE CARGO・SUPRNMRY OXY ON・>SMOKE CREW REST など）と、**FCOM に無い定義**（約 45 件）。立てているのは表の 36%（458 件中 165 件）。条件は各系統、表の整理は警報系統の作業 | EICAS-MESSAGES.md §1・§2 | `B747.87.xt.warning.lua:72-540` |
| WARN-09 | バグ | 中 | S | **ページ割りの不具合**：(1) warning を 2 ページ目に複製するときの使用印を元の位置に付けているため、2 ページ目の warning が最後に空白で消される、(2) ページ数の式が warning の繰り返し行を数えず、warning が 11 件以上だとページ数＝warning 件数になる、(3) パネルは 2 ページ分しか無く PG は 3 ページ以上でしか出ないので、2 ページあっても番号が出ない（パネル側）、(4) ページが減っても `msg_page` を詰めない、(5) memo のはみ出し処理の添字の誤り（`fmod(...,10)`、`page*11`）、(6) 新しいメッセージを見ているページに出さない | FCOM p.1528、p.1549 | `B747.87.xt.warning.lua:898-901, 925-938, 980-1007`、`747-400.acf:117872` |
| WARN-10 | 挙動の誤り | 中 | S | 待ち行列と表示を作るのが約 2 秒ごと、電源投入後は 4 秒待ってから。メッセージ・master 灯・FMOD の siren/beeper が最大約 2 秒遅れ、同じ周期内に立ったものは表の順に並ぶ | FCOM p.1548（新しい順）。遅れの許容値は資料に記載なし | `B747.87.xt.warning.lua:1137-1158` |
| WARN-11 | 挙動の誤り | 高 | M | **離陸形態警報**：内側エンジンの N1 > 90（CONFIG FLAPS は 96、FMC のフラップ設定があれば 86）を**エンジン 2 と 3 の両方**に要求（FCOM は 2 **または** 3、ATA27 は N1 66.5 PW／66.7 RR／75.0 GE）→ 減格離陸や片側の出遅れで鳴らない恐れ。enable のラッチ・V1 での disarm・10 秒の保持が無く毎フレーム IAS<V1 で判定。CONFIG FLAPS は前縁を見ず、FMC の離陸フラップとの一致を余分に要求。CONFIG GEAR CTR はタイヤの操舵角で代用。CONFIG STAB は「FMC のトリム ±2.25 ユニット」の近似（§4.8 の 3 帯なし、コード中に TODO）。試験機能なし | FCOM p.1557、p.1603–1604、ATA27 p.729–730、ATA31 p.188–194 | `B747.45.xt.fltCtrls.lua:995-1029, 1050-1143` |
| WARN-12 | 挙動の誤り | 高 | S | **着陸形態警報（CONFIG GEAR）**：「いずれかのレバーが閉」を全エンジン共通値 `throttle_jet_rev_ratio_all` < 0.05 で判定。この値は EEC が 4 本の平均を書く場面があり（`B747.42.xt.EEC.lua:926, 994`）、1 本だけ閉じても警報が出ない。レバー位置 `laminar/B747/engine/throttle` を 1 本ずつ見るべき。リセット可／不可の区別、戻したレバーの記憶、GND PROX GEAR OVRD、脚上げ後 140 秒の抑止、RA 喪失時の扱いが無い | FCOM p.1556–1558、ATA31 p.209–214、ATA27 p.735–736 | `B747.45.xt.fltCtrls.lua:980-988, 1031-1048` |
| WARN-13 | バグ | 中 | S | **SPEEDBRAKES EXT の条件式**：`and` が `or` より強いので「RA 15〜800 ft」**または**「フラップ着陸位置かつレバー 1 本以上が前」になっている。「2 本以上が閉より前（RA>15 ft）」の条件が無く、レバー数は全エンジン共通値から 1 本としか数えない。飛行中の CONFIG SPOILERS（405/570 のみの機能）は N1>90 の本数と 1 秒タイマーで判定 | FCOM p.958 (9.30.2)、p.1558、ATA31 p.220–222 | `B747.45.xt.fltCtrls.lua:943-963, 1101-1110, 1155-1168` |
| WARN-14 | 欠落 | 中 | M | **グリーンバンド機能が無い**：GW・CG・推力定格からの 3 帯選択、前脚オレオとの照合、CG の有効範囲、STAB GREENBAND（advisory/status）、グリーンバンド灯の点灯条件（地上・enable・V1 で消灯）。帯の境界値は資料に無いので推定が要る | ATA31 p.200–204、ATA27 p.747、FCOM p.958 | `B747.45.xt.fltCtrls.lua:1113-1143`（近似のみ） |
| WARN-15 | 挙動の誤り | 中 | S | **OVERSPEED** が Vmo/Mmo ではなく PFD の maximum speed（`Vmax`＝Vmo・フラップ・脚の制限の最小値）と比較するので、フラップ・脚の制限超過でも warning＋siren。28,620 ft 以下で Mmo=0.88 とする扱いも ADC の Vmo/Mmo とは別（値そのものは計器ノート）。**AIRSPEED LOW** が最小機動速度でなく Vmc か Vs（シェーカー速度）との比較で、RA 100 ft 以上という独自条件付き | FCOM p.1557、p.969 (10.10.7)、p.973 (10.10.11)、p.1556、ATA31 p.176 | `B747.60.xt.fltInst02.lua:2948-2983, 3156-3174` |
| WARN-16 | 欠落 | 中 | M | **高度警報が無い**：ALTITUDE ALERT（caution 2）を誰も立てず、master CAUTION・beeper も出ない。PFD の白枠・琥珀枠はパネルに無い（パネル変更が要る）。音は X-Plane 本体の高度警報（`baro_altimeter_alert_lit_pilot`、acf は `_warn_alt_dep_100`）で鳴り、747 の論理（arm 後の 300 ft 逸脱、900 ft で解除、G/S 捕捉・着陸形態で抑止）とは別 | FCOM p.1559 (15.20.13)、ATA34_1 p.183–192 | `B747.87.xt.warning.lua:110`、`fmod/747-400.snd:5762-5773` |
| WARN-17 | 欠落 | 中 | M | **STATUS メッセージと STATUS cue が無い**：STATUS ページ（synoptic 2）は数値表示だけでメッセージ行が無く、`CAS/status_cue`・`sec_eng_exceed_cue` は作るだけで誰も使わない。STAT のページ数は常に 1。表示にはパネル追加（カスタム acf、要承認） | FCOM p.1528、p.1545、p.1549 | `B747.60.xt.fltInst02.lua:1395-1409, 3432-3433`、`B747.87.xt.warning.lua:616-617`、`747-400.acf:129369` |
| WARN-18 | 挙動の誤り | 中 | M | **失速警報**が AOA ではなく「速度 < 表から作った Vs（失速要素の数で補正）」で `stallwarning` を立てる。フラップ・Mach・スピードブレーキで補正した alpha max と比べる論理ではないので、旋回・引き起こしなど荷重がかかった状態で早期警報にならない。シェーカーの 3D 動作は無く、音（FMOD の stall）だけ。過回転のシェーカーなし | ATA27 p.692、p.701、FCOM p.1556、p.973 | `B747.60.xt.fltInst02.lua:3012-3123, 3577` |
| WARN-19 | 欠落 | 中 | S | GPWS の PULL UP・WINDSHEAR で **master WARNING 灯が点かない**（PFD 表示は X-Plane の annunciator で出る）。音声の優先と抑止（即時ウインドシアが TCAS・他の GPWS を抑止、GPWS 警報中は TCAS を TA ONLY、warning 音声が caution 音声を抑止、低い音を待たせる）が無く、FMOD が各イベントを独立に鳴らす。TCAS と PWS の音声イベントは bank にあるが .snd に結線されていない | FCOM p.1532、p.1555、p.1582–1583、ATA31 p.159–160、p.228 | `B747.87.xt.warning.lua:795-834`、`fmod/747-400.snd:5942-6104`、`fmod/GUIDs.txt`（TCAS・PWS イベント） |
| WARN-20 | 欠落 | 低 | M | PILOT RESPONSE（乗員覚醒監視）が無い（405/570・SB 後 109 の機能。FMC 側で操作の監視が要る） | FCOM p.1559、p.1606 | `B747.87.xt.warning.lua:96, 159, 443`（表だけ） |
| WARN-21 | 欠落 | 低 | S | チャイムの論理が無い：SELCAL・ACARS・客室呼出しの low chime と離着陸時の抑止。FMOD の ding は外部電源接続や IRS 選択、FMC の EXEC 灯などに結ばれている | ATA31 p.218、p.181、FCOM p.1593、p.1600 | `fmod/747-400.snd:5866-5940` |
| WARN-22 | 挙動の誤り | 低 | S | 警報系統の電源判定が「sim のバス 0 が 5 V 未満、または `rel_esys2` 故障」。実機の MAWEA は AC standby bus と F/O instrument transfer bus、スピーカーは 28 V DC で、standby 電源だけでも動く（表示側の電源は表示ノート） | ATA31 p.100、ATA27 p.704 | `B747.87.xt.warning.lua:587, 1140` |
| WARN-23 | バグ | 低 | S | エンジン始動状態の quick start で未定義の global（`B747DR_sfty_no_smoke_sel_dial_pos` など）に代入しており、サインが設定されない | — | `B747.87.xt.warning.lua:1078-1083` |

- 重要度の内訳：高 7（WARN-01・02・03・05・06・11・12）、中 11、低 5。計 23 件。
- ACF_DIFF.md に警報系統の項目は無い。警報に関わる acf の値（`_warn_*`、`_stall_warn_*`、`_gear_warn_*`）は純正とカスタムで同じで、コードは失速警報について acf を使わない（§6）。

## 8. 作り直しか部分修正か

**警報モジュール（B747.87）は作り直しを勧める。**

- 中核のロジックは約 300 行しかなく（残りはメッセージ表）、その中にページ割り・CANC・更新周期・master 灯の不具合が重なっている（WARN-01、09、10）。さらに FCOM どおりにするには、今は存在しない「抑止の状態機械（始動前・始動中・離陸・着陸）」「メッセージ属性（音・リセット可否・抑止分類・抑止元）」「音の優先順位とラッチ」「個別の CANC 済み印」が要る（WARN-05、02、04）。直すより、同じ出力 dataref に書く新しい中核を書く方が速く安全。
- 残すもの（INTERFACES.tsv）：`laminar/B747/CAS/{warning,caution,advisory,memo}_status`（各系統の入口として配列のまま。既存の添字は変えない。`caution_status` はパネルの表示条件にも出てくる）、`gen_*_msg_000〜021`、`msg_page`、`num_msg_pages`、`recall_ind`、`warning/master_warning`・`master_caution`・`master_caution_audio`、`dsp/*` のコマンドと `switch_pos`、`button_switch/warn_caut_*`。`gen_*_msg_022〜109` はパネルが読まないが、外部が読んでいないことを確かめるまで作り続けてよい。
- 一緒に移すもの：離陸／着陸形態警報、スピードブレーキ警報、グリーンバンド（今は fltCtrls）、OVERSPEED・AIRSPEED LOW の判定（今は fltInst02）、CANC/RCL/STAT の処理（今は fltInst02）。実機でも MAWEA と EIU の機能で、抑止との結びつきが強い。
- 表の整理（WARN-06、07、08）は型式の方針を先に決める：FCOM 109 を基準にするなら ELEC GEN OFF は advisory、貨物機専用（405/570）のメッセージは `laminar/B747/freighter` で切り替える、FCOM に無い定義は消すか残すかを一覧（EICAS-MESSAGES.md §2）で決める。
- 承認が要る周辺作業：.snd の結線（WARN-02〜04、19）、カスタム acf のパネル（WARN-09 の PG、WARN-16 の枠、WARN-17 の STATUS）。承認が得られない場合でも、Lua 側の作り直しで WARN-01、05、06、07、09（パネル以外）、10〜15 は直せる。

## 9. 未確認事項

1. **カスタム acf（`747-400_custom.acf`）で FMOD の音が読まれるか**。`fmod/747-400_custom.snd` が無い。X-Plane が acf と同名の .snd を探すなら警報音が全部鳴らない。シムで確認する（最優先）。
2. `master_warning` と siren の結線（WARN-02）の実際の聞こえ方：火災時に bell と siren が同時に鳴るか、AP 切断時に wailer と siren が重なるか。`/old_vs_new_alarms` スナップショットと `laminar/B747/fmod/options/modernAlarms` で新旧どちらのイベントが鳴るか。
3. `throttle_jet_rev_ratio_all` を EEC が書かない場面（A/T 非作動時など）でこの値が何を返すか、`sim/cockpit2/engine/actuators/throttle_ratio[4]`（fltCtrls が上昇推力の本数に使う）が表示上のレバーと一致するか（WARN-12、13）。
4. `sim/flightmodel/failures/stallwarning` を書くと `sim/cockpit2/annunciators/stall_warning`（FMOD の stall イベント）が連動するか（WARN-18）。
5. X-Plane 本体の高度警報（`_warn_alt_dep_100`）がいつ `baro_altimeter_alert_lit_pilot` を点け、FMOD の altitude イベントがどの場面で鳴るか（WARN-16）。
6. ATA27 の離陸推力判定値（N1 66.5／66.7／75.0）の単位と意味（N1 % か、別の量か）。資料に単位の記載が無い。
7. TLRA（度）とレバー位置 `laminar/B747/engine/throttle`（0〜1）の対応。55°（着陸形態）、43°/40°（スピードブレーキ警報）の位置。資料に記載なし。
8. `>TCAS RA CAPTAIN, F/O` の実際の表示文言（`CAPT` 表記か）。EICAS の 1 行の最大文字数は資料に記載なし。
9. memo が 1 ページに入りきらないときの扱い（memo だけのページを作るか）。FCOM に明記なし。
10. 着陸時の CONFIG GEAR が GND PROX GEAR OVRD で消えるか（FCOM は消える、ATA31 は残る）。FCOM を採ったが、実機の版の違いの可能性がある。
11. 失速警報の地上での扱い、過回転シェーカーの条件（資料に記載なし）。
12. パネルの CAS 行と `gen_*_msg_022〜109` を外部（他のプラグイン、AutoATC など）が読んでいないか。
