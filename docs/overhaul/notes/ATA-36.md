# ATA 36 Pneumatic（抽気）調査メモ

2026-10-23 調査。対象コードは `overhaul`（041c9ffa）。出典の書き方は REFERENCE_INDEX.md に従う。

## 1. 概要

- 対象: エンジン抽気（IP/HP ポート、HPSOV、PRV、プレクーラー/FAMV、PRSOV）、左・中央・右のダクトと隔離弁（L/R ISLN）、APU 抽気、地上空気、ダクト圧の表示、過熱・過圧・ダクトリーク、エンジン始動用の空気、ECS synoptic の抽気部分、関係する EICAS メッセージ。
- 対象外: パック弁から先（パック、温度、与圧）は ATA 21、NAI・WAI の弁と防氷は ATA-30.md、始動弁とスターター本体は ATA 80 の担当。境界の取り合いは §5 に書く。
- 用語: FCOM の「engine bleed air valve」は整備資料の PRSOV（pressure regulating and shutoff valve）、「HP bleed valve」は HPSOV。本メモは整備資料の略号を使う。
- 使った資料:
  - FCOM 2.10 p.575–586、2.40 p.611–617、2.50 p.619–622。関連で 7.13 p.862–864、7.14 p.867、7.20 p.879・p.893、7.30 p.895–897、7.40 p.902、SP.7 p.183、NP p.104–110・p.123–126、PI p.261–263・p.300・p.358–360、0.1 p.5。
  - ATA30_32_35_36 p.3–148（E&M 36-00 / 36-10 / 36-20）。IP/HP を 8th/14th stage、PRV 97 psig、過圧 110 psig とし、ファンケースの GND SVC スイッチで逆推力へ空気を送る記述がある。CF6-80C2 機の資料と推定（PW 機の LH36 は 8th/15th、64 psig、76 psig）。
  - LH36 p.3–105（PW4000 機）。
  - ATA26_28 p.277–286（26-18 主翼前縁・ストラットの過熱検知。BLD DUCT LEAK の出どころ）。
- FCOM の effectivity は 109 = PW 旅客機、405 = PW 改造貨物機、570 = GE 貨物機 (FCOM p.5 (0.1.1))。シムの機体は旅客機なので、機体側の項目は 109、エンジン側の項目（逆推力、ポート段数、補正表）はエンジン型式で選ぶ（この扱いは推定）。RR は資料なし。

## 2. 構成

### 2.1 エンジン側（4 基とも同じ）

| 部品 | 働き | 根拠 |
|---|---|---|
| IP / HP ポート | PW: IP = 8th stage 2 か所、HP = 15th stage 3 か所。E&M（CF6 と推定）: 8th / 14th。低出力では HP、高出力では IP を使う | LH36 p.28 (36-10)、ATA30_32_35_36 p.6 (36-00)、FCOM p.611 (2.40.1) |
| IP check valve | HPSOV が開のとき HP 空気が IP 段へ逆流するのを防ぐ | LH36 p.42 (36-10) |
| HPSOV と制御器 HPSOVC | 開閉だけの弁（5.5 in、ばねで閉、サーボ圧 14 psi 以上で開）。HP 圧が切替圧に達すると閉じて IP 運用になる | LH36 p.30–40 (36-10) |
| PRV と制御器 PRVC | プレクーラー入口の圧力を制限。PW: 64±5 psig（59 以下で全開、69 超で全閉）。E&M: 97 psig。始動中は閉 | LH36 p.44–54、ATA30_32_35_36 p.64 (36-10) |
| プレクーラー・FAMV・FATS | ファン空気で冷やす。出口 177°C を目標に、160–193°C の間で FAMV が開度を調節 | LH36 p.56–62 (36-10) |
| 過熱スイッチ | プレクーラー下流 >243°C/470°F が 5 s 続くと ASCTU がラッチし HPSOV・PRV を閉じる | LH36 p.98–100 (36-20) |
| 過圧スイッチ・圧力センサー | プレクーラー出口。PW >76 psig、E&M >110 psig | LH36 p.96 (36-20)、ATA30_32_35_36 p.114 (36-10) |
| PRSOV（FCOM の engine bleed air valve） | ストラット内で主翼ダクトの入口。6 in、ばねで閉。スイッチで開閉、下流を 45 psi に調圧、温度制限、逆流防止、始動時の逆流許可。閉リミットスイッチが OFF 灯を点ける | LH36 p.64–76 (36-10)、ATA30_32_35_36 p.92–104 (36-10) |
| NAI の取出し | PRV・プレクーラーの下流、PRSOV の上流 | FCOM p.615 (2.40.5) の図、FCOM p.632 (3.20.2) |
| 始動弁（ATA 80） | PRSOV を逆向きに通ったダクトの空気をスターターへ送る | FCOM p.612 (2.40.2)、p.879 (7.20.9) |
| GE だけ | 逆推力は同じエンジンの抽気で動く | FCOM p.893 (7.20.23) |

### 2.2 ダクト

- 左（エンジン 1・2）、中央（クロスオーバー）、右（エンジン 3・4）の 3 区画。L ISLN・R ISLN（7 in、115V AC モーター駆動の蝶形弁）で区切る。通常は両方とも開 (FCOM p.613 (2.40.3)、ATA30_32_35_36 p.20 (36-00))。
- 区画ごとの主な消費先 (FCOM p.611 と p.615 の図、LH36 p.4 (36-00))
  - 左: パック 1、左の LE フラップ駆動、左 WAI、エンジン 1・2 の始動と NAI 側。油圧 1 の ADP（FCOM p.614 の「demand pump one or four」と図の左右対称から推定）
  - 中央: パック 2、トリムエア、後方貨物室加熱、貨物室煙検知、飲料水タンク加圧、APU、地上接続口
  - 右: パック 3、右の LE フラップ駆動、右 WAI、油圧 3・4 リザーバー加圧、油圧 4 の ADP、エンジン 3・4
  - TAT プローブの吸引（aspiration）にも抽気を使う (ATA30_32_35_36 p.4 (36-00))。どの区画からかは資料に記載なし
- ダクト圧トランスミッター 2 個（L、R）は各 ISLN のエンジン側（主翼側）にある (LH36 p.10 (36-00)、LH36 p.94 (36-20)、FCOM p.615 の図)。APU だけで両 ISLN が閉なら L/R とも 0 を示す (LH36 p.94)。
- APU: APU isolation valve（7 in、115V AC モーター）→ APU check valve → 中央区画 (LH36 p.80–82 (36-10))。
- 地上空気: 3 in の接続口 2 個（check valve 付き）が中央区画につながる (LH36 p.84 (36-10)、FCOM p.613)。

### 2.3 電源と制御

| 対象 | 電源 | 根拠 |
|---|---|---|
| ASCTU（2 チャンネル。エンジンごとの制御カード 4 枚） | 28V DC bus 1–4（CB: AIR SUPPLY CONT ENG 1–4） | LH36 p.90–92 (36-00) |
| HPSOVC・PRVC・PRSOV の開閉ソレノイド | 28V DC、0.5 s パルスのラッチ式。電源が切れても直前の状態を保つ | ATA30_32_35_36 p.54・p.68・p.100、LH36 p.74 |
| L ISLN / R ISLN | 115V AC bus 1 / bus 3 | LH36 p.87 (36-10) |
| APU isolation valve | 115V AC bus 2、制御は 28V DC bus 2 | LH36 p.89 (36-10) |

- ASCTU は P5 の bleed air control module（M7328）のスイッチ、エンジン火災スイッチ、NAI スイッチ、始動スイッチ、始動弁位置、逆推力、空地を受けて弁に指令を出し、SYS FAULT 灯と EICAS へ出力する (LH36 p.6・p.90)。
- ASCTU の一部が無電源になると、どの DC bus でも ENG n AUTOSTART（caution）、DC bus 1 で BLEED ASCTU A、DC bus 3 で BLEED ASCTU B（status）が出る (LH36 p.92)。

## 3. 操作と表示

### 3.1 P5 の Bleed Air Control（FCOM p.575–576 (2.10.23–24)）

| 操作子・灯 | 動作 |
|---|---|
| L / R ISLN スイッチ | ON（バー表示）で弁開、off で閉。スイッチがモーターを直接動かす (LH36 p.14) |
| ISLN VALVE 灯（琥珀） | 弁位置とスイッチ位置が不一致。移動中も点灯 (LH36 p.78) |
| APU bleed スイッチ | ON: APU RUNNING メモが出ているときに開指令。off: 閉 |
| APU VALVE 灯（琥珀） | APU 弁の位置が指令と不一致、または移動中 (FCOM p.576、LH36 p.14) |
| ENGINE BLEED 1–4 スイッチ | ON: 始動時に PRSOV を開く。抽気圧があれば PRSOV・PRV・HPSOV をシステムロジックで開く。off: 3 弁とも閉。ただし off でも NAI ON なら PRV は開く（過去・現在の過熱、始動弁が閉でない、HPSOV failed open のときを除く）。GE は逆推力でも HPSOV と PRV が開く（過熱、始動弁未閉を除く） |
| ENGINE BLEED OFF 灯（琥珀） | PRSOV が閉 (FCOM p.576、LH36 p.68) |
| SYS FAULT 1–4（琥珀） | 抽気過熱、抽気過圧、HPSOV が閉指令なのに開、PRV が閉指令なのに開 (FCOM p.575) |

- PW の SYS FAULT 条件 (LH36 p.12): HPSOV が開指令で開かない、HP 段 >127 psi で HPSOV が閉じない、PRV の開閉が指令と不一致（それぞれ 5 s。LH36 p.53 の図）、始動弁が閉でないのに PRV 開、>243°C、>76 psi。
- ENGINE BLEED スイッチを off から ON にすると故障検知（過熱ラッチ）がリセットされる (FCOM p.612 (2.40.2))。
- 現コードとの対応: `laminar/B747/button_switch/position` の [75] L ISLN、[76] R ISLN、[77]–[80] ENG BLEED 1–4、[81] APU。灯は `laminar/B747/annunciator/brightness_ratio` の [72]/[73] ISLN VALVE、[74] APU VALVE、[75]–[78] OFF、[118]–[121] SYS FAULT、[122]–[125] 始動灯（B747.90.xt.lighting.lua:1829-1835、1904-1913）。

### 3.2 始動スイッチ（抽気に関わる部分）

- Pull（autostart ON）: 始動弁を arm、PRSOV を開。Pull（autostart OFF）: 始動弁を開、PRSOV を開。50% N2 でスイッチが戻り、始動弁と PRSOV が閉じる (FCOM p.862 (7.13.4))。始動灯は始動弁が開で点灯 (FCOM p.864 (7.13.6))。
- autostart では燃料制御スイッチを RUN にすると EEC が始動弁を開く (FCOM p.879 (7.20.9))。

### 3.3 ECS synoptic の抽気部分

- 表示要素 (FCOM p.577–581 (2.10.25–29)、LH36 p.16–18 (36-00))
  - ダクト圧 L/R: 12 psi 以上は白、11 psi 以下は琥珀 (FCOM p.578)。LH36 p.18 は「11 psi 以上白、11 未満琥珀」と書く。乗員表示なので FCOM に従う。
  - エンジン弁（PRSOV）の記号: 開は緑で流れバー付き。OFF 白 = 閉でスイッチ off、または閉でスイッチ ON かつエンジン停止。OFF 琥珀 = 閉、スイッチ ON、エンジン運転中（N2 >50%）(LH36 p.16)。
  - ISLN・APU 弁の記号: 開と閉は白、空気が流れていれば緑の流れバー、移動中は琥珀 (LH36 p.16)。
  - 流れバー: 空気源と、空気を使う系統が同時に ON のとき表示。実際の流量ではなく、弁位置・スイッチ位置・パック状態から作る表示 (FCOM p.576、LH36 p.16)。
  - EXT AIR: APU もエンジンも止まっていて、パックが動いているかダクトが加圧されているとき。外部空気を外したあともしばらく残る (FCOM p.578)。LH36 p.18 は「APU 弁と全 PRSOV が閉で、ダクト圧センサーが圧力を感じている」。
  - NAC TAI・WING TAI の流れは ATA-30.md。
- 現在の acf の ECS synoptic（`laminar/B747/dsp/synoptic_display` = 5、747-400.acf:135168 から）
  - エンジン区間の流れ: `laminar/B747/air/engineN/bleed_air_psi` > 11
  - エンジン弁の記号: `laminar/B747/air/engineN/bleed_valve_pos` > 0.5 で開、< 0.5 で閉（白と琥珀の区別なし）
  - ダクト圧 LED: `duct_pressure_L/R` < 12 で琥珀、> 12 で白（12.0 ちょうどではどちらも出ない）
  - 左右区間の流れ: `duct_pressure_L/R` > 5.01、中央区間: `duct_pressure_C` > 5.01、APU 区間: `duct_pressure_C` > 0.01
  - ISLN・APU 弁の記号: `isolation_valve_L/R_pos`・`apu/bleed_valve_pos` の 0–1 で 0–90° 回転
  - EXT AIR の要素、琥珀の OFF・移動中の記号は acf に無い

### 3.4 主 EICAS のダクト圧ブロック

- ダクト圧、客室高度、変化率、着陸高度、差圧は、着陸高度 MAN、客室高度が注意/警告域、差圧が注意/警告域、または二次 EICAS で ECS か ENG synoptic を選んだときに出る (FCOM p.585 (2.10.33))。E&M は「二次エンジン表示、ECS synoptic、ECS 整備ページを選ぶと出て、ほかを選ぶと消える」(ATA30_32_35_36 p.128 (36-20))。
- ダクト圧の色は 3.3 と同じ (FCOM p.585)。
- acf（747-400.acf:124703-124781）: `laminar/B747/air/pressurization/EICAS1_display_status` = 1 で表示。L/R の LED は < 11 で琥珀、> 11.01 で白。右の白 LED の表示条件が `duct_pressure_L` を参照している（747-400.acf:124780。カスタム acf も同じ）。

### 3.5 EICAS メッセージ

| メッセージ | レベル | 条件 | 根拠 |
|---|---|---|---|
| BLD DUCT LEAK L, C, R | Caution（beeper） | 左・中央・右区画の抽気リークまたは過熱 | FCOM p.619 (2.50.1)、ATA26_28 p.286 (26-18)（L/R は主翼前縁・ストラットの温度スイッチ） |
| BLD 1–4 OVHT/PRV | Advisory | 抽気過熱、または PRV failed closed | FCOM p.619、LH36 p.100 |
| BLEED 1–4 | Advisory | 抽気過圧、または HPSOV か PRV が閉指令で閉じない | FCOM p.619、LH36 p.8・p.46・p.96 |
| >BLEED 1–4 OFF | Advisory | ENGINE BLEED off、エンジン運転中（LH36 は N2 >50%）、PRSOV 閉 | FCOM p.619、LH36 p.68 |
| BLEED HP ENG 1–4 | Advisory（beeper） | HPSOV failed closed | FCOM p.619 |
| BLEED ISLN L, R | Advisory（beeper） | ISLN のスイッチと弁位置の不一致が 10 s 以上 | FCOM p.619、ATA30_32_35_36 p.22 (36-00) |
| >BLEED ISLN APU | Advisory | APU 弁の位置が指令と不一致（10 s 以上） | FCOM p.619、ATA30_32_35_36 p.28 |
| APU RUNNING | Memo | APU セレクター ON かつ APU N1 >95% | FCOM p.902 (7.40.4) |

- STATUS（二次 EICAS、整備向け）: BLEED ASCTU A/B（20 s 遅延）、BLEED HP ENG n（60 s）、BLEED OVPRESS n、BLEED PRV ENG n（125 s）、BLEED FAMV ENG n、BLEED n OVHT（60 s）、BLEED ISLN L/R/APU、ENG n START VLV (ATA30_32_35_36 p.16・p.58・p.72・p.84・p.90、LH36 p.68・p.92)。
- 名前の違い: E&M は「BLEED 1 OVHT」(ATA30_32_35_36 p.90)、FCOM は「BLD 1 OVHT/PRV」。FCOM に従う。
- 警報モジュールの表（B747.87.xt.warning.lua:114-116、208-228）には FCOM 2.50 に無い「BLEED LOSS L/R」(223-224) もある。
- ATA 80 側の関連: ENG n START VLV（始動弁位置と指令の不一致）、STARTER CUTOUT n（始動弁が閉じない）(FCOM p.902)。

## 4. 内部ロジック

### 4.1 エンジン抽気の弁ロジック（1 基分）

入力: ENGINE BLEED スイッチ、エンジン火災スイッチ、NAI スイッチ、始動スイッチ、始動弁位置、逆推力（GE のみ）、過熱ラッチ、HP 段圧、高度、ダクト（下流）圧。

1. 過熱ラッチ: プレクーラー下流 >243°C が 5 s 続くとセット。ENGINE BLEED を off→ON（または ON→off→ON）でリセット。温度が下がっても自動では戻らない (LH36 p.100、FCOM p.612、ATA30_32_35_36 p.19 の注記)。
2. HPSOV（開閉だけ）
   - 開指令 = スイッチ ON（GE は逆推力展開でも）かつ火災スイッチ NORMAL かつ過熱ラッチなし (LH36 p.26・p.34、ATA30_32_35_36 p.54)。
   - 開指令があっても HP 圧が切替圧以上なら閉じる（IP 運用）。PW: 105±5 psig（27,000 ft 以下）、27,000→42,000 ft で 77 psig（LH36 p.8）または 74 psig（LH36 p.30）まで直線に下がり、42,000 ft 超はその値で閉。E&M: 105 psig@27,000 ft → 71 psig@45,000 ft (ATA30_32_35_36 p.50)。
   - スイッチ off で NAI ON のとき HPSOV は閉のまま、IP 空気だけになる (FCOM p.632 (3.20.2)、ATA30_32_35_36 p.19)。
3. PRV（調圧）
   - 開指令 = (スイッチ ON または NAI ON) かつ火災スイッチ NORMAL かつ過熱ラッチなし かつ始動弁が閉になってから 15 s 経過。スイッチ off・NAI ON のときは HPSOV の閉を確認してから (LH36 p.48・p.53 の図、ATA30_32_35_36 p.68)。GE は逆推力でも開 (FCOM p.576)。
   - 始動弁が閉でないあいだは閉 (FCOM p.612、LH36 p.26)。
   - 開のときは PW で 64±5 psig に調圧 (LH36 p.54)。
4. PRSOV（engine bleed air valve）
   - スイッチ ON（火災スイッチ NORMAL）でラッチ式ソレノイドが「有効」になり、空気圧で開く。作動に最低 10 psi、30 psig で全開 (LH36 p.74、ATA30_32_35_36 p.94)。スイッチ off と火災スイッチで閉 (LH36 p.74)。
   - 下流を 45 psi（30–50 psi）に調圧 (LH36 p.64)。
   - 温度制限: PW は 220°C で閉じ始め 232°C でほぼ全閉。E&M は 405°F（207°C）で閉じ始め 450°F（232°C）で全閉し OFF 灯。始動中は働かない (LH36 p.64、ATA30_32_35_36 p.94)。
   - 逆流防止: 下流（ダクト）圧が上流（エンジン）圧を 0.13 psi 上回ると閉じる (LH36 p.76)。APU・地上空気・他のエンジンのほうがダクト圧が高ければ閉じる (FCOM p.612)。
   - 始動時の逆流許可: スイッチ ON・火災スイッチ NORMAL・始動スイッチ pull で逆流ソレノイドが働き、ダクト圧で開いて始動弁へ空気を送る（LH36 は「始動弁が閉でない」で働くと書く）(LH36 p.64・p.74、ATA30_32_35_36 p.100)。このあいだ PRV は閉、温度制限と逆流防止は働かない (FCOM p.612、LH36 p.76)。
   - 50% N2 で始動弁が閉じると逆流許可が終わり、その 15 s 後に PRV が開いて通常の運用に戻る (FCOM p.612、LH36 p.48)。
   - 始動弁が閉じないときは PRV と PRSOV が閉のままでスターターへの空気が止まり、そのエンジンの NAI も使えない (FCOM p.612)。
5. 過熱のとき: HPSOV・PRV が閉 → PRSOV は上流圧を失って閉 → OFF 灯、SYS FAULT、BLD n OVHT/PRV (LH36 p.100)。
6. 過圧: PW は >76 psig が 5 s（一部の機体は 65 s。改修 ASCTU は 60 s 遅延リレー付き）続くと SYS FAULT と BLEED n。弁の動作は変えない (LH36 p.96・p.102)。E&M は 110 psig、60 s + 5 s (ATA30_32_35_36 p.114)。全パック OFF の離陸で出ることがある (LH36 p.102)。

E&M の弁状態表（ATA30_32_35_36 p.19 (36-00)）の要約（O = 開、C = 閉）

| 条件 | HPSOV | PRV | PRSOV | 灯 |
|---|---|---|---|---|
| スイッチ ON、アイドル | O | O | O | |
| スイッチ ON、離陸出力 | C | O | O | |
| スイッチ off | C | C | C | OFF |
| スイッチ ON、過圧 | C/O | O | O | SYS FAULT |
| スイッチ ON、過熱 | C | C | C | SYS FAULT（ラッチ）、OFF |
| スイッチ ON、NAI ON | C/O | O | O | |
| スイッチ off、NAI ON | C | O | C | PRV は HPSOV 閉の確認後 |
| 過熱中に NAI ON（スイッチ ON/off とも） | C | C | C | SYS FAULT（ラッチ）、OFF |
| スイッチ ON、逆推力（GE） | O/C | O | O | 低出力では HPSOV 開 |
| スイッチ off、逆推力（GE） | O/C | O | C | 同上 |
| スイッチ ON、火災スイッチ | C | C | C | OFF |
| スイッチ ON、始動中 | C | C | O | |
| スイッチ off、始動中 | C | C | C | OFF（ダクトから始動できない） |

### 4.2 ダクトと圧力

- 区画は §2.2 のとおり。ISLN が開なら隣の区画とつながる。L/R の表示は主翼側の区画の圧力 (LH36 p.94)。
- 圧力の源: 各エンジンの PRSOV 下流（最大 45 psi で調圧、30–50 psi）、APU、地上空気。逆流は check valve（APU、地上）と PRSOV の逆流防止で止まる (FCOM p.612–613)。
- 量の手がかり（モデルの調整目標）
  - FCOM の例示値は 30 psi (FCOM p.585)、LH36 の例示は 28 psi (LH36 p.18)。
  - APU は全パックを動かせるが、エンジン始動中は除く。飛行中は 1 パックまで、15,000 ft 以下 (FCOM p.895 (7.30.1))。
  - 地上空気での始動はダクト圧 30 psi 以上（気圧高度 1,000 ft ごとに 1 psi 減）(FCOM p.183 (SP.7.1))。
  - クロスブリード始動では、運転中のエンジンを約 70% N2 まで上げる (FCOM p.183)。アイドルの抽気では始動できない前提と読める（推定）。
  - 始動時はパックを 2 つか 3 つ OFF にする (FCOM p.123 (NP.21.29))。
  - 左右どちらかの区画を隔離したら、残る 2 エンジンの推力を確保するためパックは最大 1 つ (FCOM p.614 (2.40.4))。
  - APU 抽気時の具体的なダクト圧、アイドル時のダクト圧は資料に記載なし。
- 区画を隔離したときの影響 (FCOM p.614)
  - 中央: 後方貨物室加熱を OFF（逆流防止）、全温度ゾーンがトリムエア無しのバックアップ制御、飲料水加圧と貨物室煙検知は使えない。
  - 左/右: その側の LE フラップは電動（secondary）、ADP 1 または 4 を OFF にする（進入中の HYD PRESS DEM を避ける）、パックは最大 1 つ。

### 4.3 隔離弁（L/R ISLN）

- スイッチの ON/off がそのまま 115V AC モーターの開閉指令（L は AC bus 1、R は AC bus 3）(LH36 p.86–87)。
- VALVE 灯: 移動中、またはスイッチと位置が不一致。EICAS（BLEED ISLN L/R）は不一致が 10 s 以上続いたとき (ATA30_32_35_36 p.22)。
- 移動時間、電源喪失時の位置は資料に記載なし（モーター弁なので位置を保持すると推定）。

### 4.4 APU 抽気

- 開く条件: APU bleed スイッチ ON、APU セレクター ON か START（APU start latch relay）、APU 火災スイッチ NORMAL、APU N1 95% 以上 + 2 s (LH36 p.88–89 (36-10))。FCOM は「APU RUNNING メモが出ているとき開指令」(FCOM p.575)、APU RUNNING は APU セレクター ON かつ N1 >95% (FCOM p.897 (7.30.3)・p.902)。LH36 p.80 には「APU N1 100%」の記述もあるが、同書の回路説明（p.88）の 95% + 2 s を採る。
- 閉じる条件: 上の条件が一つでも欠けたとき。APU セレクター OFF で APU 抽気弁はすぐ閉じ、APU は 60 s 無負荷で冷却してから止まる (FCOM p.897、p.867 (7.14.1))。
- APU の抽気ダクトには過熱（リーク）検知があり、それで APU が止まると再始動できない (FCOM p.613)。
- VALVE 灯は移動中か指令と不一致。>BLEED ISLN APU は 10 s 以上の不一致 (ATA30_32_35_36 p.28、LH36 p.80)。
- APU 側の遅い・固着した可変案内翼の検出で APU 制御器が APU 弁を閉じ、ダクト圧が 0 になる事例がある (LH36 p.88 の整備ヒント)。

### 4.5 地上空気

- 地上の高圧空気源を中央区画の接続口 2 か所につなぐ (FCOM p.613、LH36 p.84)。
- 表示: EXT AIR（§3.3）。ダクト圧は ISLN を通じて L/R に出る。
- 地上空気での始動はダクト圧 30 psi 以上（1,000 ft ごとに 1 psi 減）(FCOM p.183)。
- 接続・切り離しの操作手段（機外の作業）は機体側の資料に無い。シムでは地上作業ページなどで扱う必要がある（推定）。

### 4.6 始動の空気

- 空気源は通常 APU。地上空気、運転中の別エンジン（クロスブリード）も使える (FCOM p.879)。
- 順序: 始動スイッチ pull → PRSOV が逆流許可で開く → 始動弁が開く（autostart は燃料制御 RUN で EEC が開く）→ ダクトの空気がスターターを回す → 50% N2 で始動スイッチが戻り、始動弁と PRSOV が閉じる → 15 s 後に PRV が開き、PRSOV は順流で開く (FCOM p.612・p.862・p.879、LH36 p.48)。
- ENGINE BLEED スイッチが off だと PRSOV が開かず、そのエンジンはダクトから始動できない (ATA30_32_35_36 p.19 の最終行、LH36 p.74)。
- スターターのトルクとダクト圧の関係（何 psi で何 % N2 まで回せるか）は資料に記載なし。下限の目安は §4.2 の 30 psi。

### 4.7 ダクトリークと過熱検知

- 主翼前縁に 9 個、各ストラットに 2 個の温度スイッチ（常時開、並列）。作動温度は主翼前縁の内外側 82–93°C、ストラット 132–149°C、中央の前縁 104–121°C と 82–93°C。どれかが閉じると BLD DUCT LEAK L/R (ATA26_28 p.280–286 (26-18))。中央（C）の検知の詳細は資料に記載なし（APU ダクトの過熱検知は §4.4）。
- 自動では隔離しない。乗員が該当区画の ISLN とエンジン抽気を閉じる (FCOM p.613)。

### 4.8 GE の逆推力

- GE は空気駆動の逆推力で、そのエンジンの抽気を使う。エンジンが止まっていると逆推力は動かない (FCOM p.893 (7.20.23))。PW は油圧駆動 (同)。
- 逆推力のとき HPSOV と PRV が開く（スイッチ off でも）。過熱ラッチと始動弁未閉のときは除く (FCOM p.576)。PRSOV はスイッチ off なら閉 (ATA30_32_35_36 p.19)。

### 4.9 PW と CF6 の数値

| 項目 | PW（LH36） | E&M（CF6 と推定） |
|---|---|---|
| ポート | 8th / 15th | 8th / 14th |
| HPSOV 切替圧 | 105±5 psig（≤27,000 ft）→ 77 または 74 psig（42,000 ft） | 105 psig（27,000 ft）→ 71 psig（45,000 ft） |
| PRV | 64±5 psig | 97 psig |
| 過圧スイッチ | 76 psig、5 s（または 65 s、60 s 遅延） | 110 psig、60 s + 5 s |
| PRSOV 調圧 | 45 psi（30–50） | 45 psi |
| PRSOV 温度制限 | 220→232°C | 207→232°C |
| 過熱スイッチ | 243°C、5 s | 243°C、5 s |
| プレクーラー出口 | 177°C（160–193） | 177°C（160–193） |
| 逆推力 | 油圧（FCOM 109/405） | 抽気（FCOM 570） |

## 5. 他系統とのつながり

- ATA 21（空調・与圧）: パック 1/2/3 は左/中央/右の区画から取る。パック弁の開閉と流量（高流量）はダクトの需要になる。現コードは X-Plane の `sim/cockpit2/pressurization/actuators/bleed_air_mode` を抽気状態から決めている（B747.55.xt.air.lua:770-791）。主 EICAS の与圧ブロックの表示判定は同じファイル（892-922）。
- ATA 29（油圧）: ADP 1・4 は L/R のダクト圧で動く。現コードは `ADP の圧力 = ダクト圧 × 110`（上限なし）(B747.19.xt.hydraulicsmodel.lua:410-455)。`laminar/B747/air/duct_pressure_L/R` を作っているのは油圧の init（plugins/xtlua_keysystems/init/scripts/B747.19.hydraulicsmodel/B747.19.hydraulicsmodel.lua:40-41）で、B747.55.air の init ではない（`duct_pressure_C` だけが B747.55.air の init で作られる）。
- ATA 27（操縦系統）: LE フラップは空気駆動。区画を隔離すると電動の secondary になる (FCOM p.614)。
- ATA 30（防氷）: NAI は PRSOV 上流から取り、PRV の開閉条件に NAI スイッチが入る。WAI は L/R 区画から取る。ATA-30.md 参照。
- ATA 80 / 73（エンジン・EEC）: 始動弁、50% N2 のカットアウト、autostart。抽気による推力補正（PI の補正表）、NAI による進入アイドル。X-Plane 側の抽気損失（§6）。
- ATA 26（火災）: エンジン火災スイッチで PRSOV・PRV・HPSOV を閉 (LH36 p.26)、APU 火災スイッチで APU 弁を閉 (LH36 p.88)。ダクトリーク検知（26-18）。
- ATA 49（APU）: N1 95% と APU RUNNING（現コードは電源モジュール B747.03.xt.electrical.lua:921-926 で N1 >95% だけを見ている）、APU セレクター。
- ATA 24（電源）: §2.3 のバス。ASCTU の DC bus が切れると ENG n AUTOSTART が出る (LH36 p.92)。
- ATA 31（EICAS）: §3.5 のメッセージ、10 s・5 s などの遅延、STATUS ページ。現在の警報モジュールには遅延や抑止の仕組みが無く、状態配列の 0/1 をそのまま表示する（B747.87.xt.warning.lua:795-894）。
- ATA 34（航法）: TAT プローブは抽気で吸引される。地上で冷房車の空気しか無いと TAT が高く出て、FMC が assumed temperature を受け付けないことがある (FCOM p.212 (SP.16.12))。
- ATA 38・26: 飲料水タンク加圧、貨物室煙検知は中央区画 (FCOM p.614)。

## 6. 実装上の注意

- 名前を変えてはいけないもの
  - INTERFACES.tsv: `laminar/B747/air/apu/bleed_valve_pos`、`laminar/B747/air/isolation_valve_L_pos`・`_R_pos`、`laminar/B747/air/duct_pressure_L`・`_R`、コマンド `laminar/B747/button_switch/bleed_air_isln_vlv_L`・`_R`・`bleed_air_vlv_apu`・`bleed_air_vlv_engine_1`〜`_4`、`laminar/B747/button_switch/position`。
  - INTERFACES.tsv に載っていないが acf の表示条件（SHOW_*）が参照しているもの: `laminar/B747/air/engine1`〜`4/bleed_air_psi`、`engine1`〜`4/bleed_valve_pos`、`laminar/B747/air/duct_pressure_C`、`laminar/B747/air/pressurization/EICAS1_display_status`、`laminar/B747/dsp/synoptic_display`。INTERFACES.tsv は acf の SHOW_* 条件を拾っていない（acf の SHOW_* に出る laminar 名 242 個のうち 175 個が未掲載）。書き換えではこれらも同じ名前と意味を保つ。
  - 他モジュールが読むもの: `laminar/B747/air/engineN/bleed_start_valve_pos`（エンジン、照明、防氷）、`engineN/bleed_air_psi`（防氷）、`duct_pressure_L/R`（油圧、防氷）。
- XTLua: ロジック側の `deferred_dataref` は `find_dataref` に置き換えてあるので、新しい dataref は必ず init スクリプトで作る。`duct_pressure_L/R` は油圧の init が作っているので、抽気モジュールの init で作り直すなら二重作成を避ける（油圧の担当と調整）。最初の読みが 0 になる件（OLD_FORK_NOTES §14）に注意。
- 表示の制約（acf は純正を変えない。変更はカスタム acf のみで要承認）
  - 主 EICAS の右の白 LED が左の圧を見ている。11.00〜11.01 psi ではどちらの LED も出ない。ECS synoptic は 12.0 ちょうどで出ない。プラグイン側で出力を整数に丸め、FCOM の「12 以上白・11 以下琥珀」に合う値を出す工夫が要る（例: 表示用の値を別に持つ）。右 LED の誤りはカスタム acf の修正でしか直らない。
  - ECS synoptic のエンジン区間の流れは `bleed_air_psi` > 11 だけで決まる。この dataref を「PRSOV 下流（ダクトへ流れ込む）圧」と定義し直せば、スイッチ off で流れが消える。防氷側は別の内部値（エンジン側の圧）を使うように同時に直す。
  - APU 区間の流れは `duct_pressure_C` > 0.01 で、APU 弁と無関係に出る。PRSOV の琥珀 OFF、移動中の琥珀記号、EXT AIR は acf に要素が無い。
- X-Plane 本体の抽気モデル
  - acf は `acf/_has_full_bleed_air 0`（純正・カスタムとも）。そのため現コードが書いている `sim/cockpit2/bleedair/actuators/isol_valve_left/right` は効いていない可能性が高い（推定、要確認）。
  - `sim/cockpit2/bleedair/indicators/engine_loss_from_bleed_air_ratio[16]` は `override_pressurization` を立てたときだけ書ける。立てなければ X-Plane が自分の判定（acf の `_bleed_draw_dice_engn 15`、`_bleed_draw_dice_wing 20`、`_bleed_draw_pressurization 10`、`_bleed_draw_starter 35`）で推力・効率を下げる（推定、要確認）。ATA 21 が `override_pressurization` を使うなら、この値も同じ担当が書く必要がある。
- 単純化してよいもの: プレクーラー・FAMV の温度（故障注入用の温度だけ持てばよい）、HP/IP 切替（N2 と高度の連続関数で近似）、ASCTU の BITE、STATUS メッセージ、整備ページ。
- 単純化してはいけないもの: P5 のスイッチと灯の論理、PRSOV の逆流防止と始動時の逆流許可、始動弁との連動（PRV 閉と 15 s）、APU 弁の条件、3 区画と ISLN、L/R 表示が主翼側の圧であること、EICAS メッセージと 10 s の遅延、過熱ラッチとスイッチでのリセット。
- 圧力の計算の案（推定。資料に式は無い）: 各源の供給能力（エンジン: N2・高度の関数で 45 psi 上限、APU: 定格、地上空気: 設定値）と、区画ごとの需要（パック、高流量、NAI、WAI、ADP、スターター、LE フラップ駆動、後方貨物室加熱など）の和から、区画の圧力を「源の圧力 − 需要 × 係数」のように下げる。ISLN が開なら区画を合わせて計算する。調整目標は §4.2 の数字（APU で全パック可、始動中は不可、アイドルのクロスブリードでは始動不可、ダクト隔離で 1 パック）。
- 故障の注入: SYS FAULT は今は X-Plane の `sim/cockpit2/annunciators/bleed_air_fail` をそのまま出している（B747.90.xt.lighting.lua:1434-1437）。書き換えでは内部の故障フラグ（過熱、過圧、HPSOV/PRV 固着、ダクトリーク）を持ち、X-Plane の故障（`sim/operation/failures/rel_bleed_air_lft/rgt` など）から設定できるようにする。
- 地上空気: 接続の操作を FMC の地上作業ページ（activepages の groundhandling。今は外部電源だけ）に足す案。EXT AIR 表示はカスタム acf の変更が要る。

## 7. 現状実装との比較（GAP 候補）

該当コードの略記: AIR = `plugins/xtlua_keysystems/scripts/B747.55.xt.air/B747.55.xt.air.lua`、LIT = `plugins/xtlua_keysystems/scripts/B747.90.xt.lighting/B747.90.xt.lighting.lua`、ENG = `plugins/xtlua/scripts/B747.40.xt.engines/B747.40.xt.engines.lua`、WRN = `plugins/xtlua/scripts/B747.87.xt.warning/B747.87.xt.warning.lua`、EEC = `plugins/xtlua/scripts/B747.42.xt.EEC/`、HYD = `plugins/xtlua_keysystems/scripts/B747.19.xt.hydraulicsmodel/B747.19.xt.hydraulicsmodel.lua`、ACF = `747-400.acf`。

| ID | 種別 | 重要度 | 規模 | 内容 | 根拠 | 該当コード |
|---|---|---|---|---|---|---|
| PNEU-01 | 欠落 | 高 | L | ダクト圧が「開いている源の最大値」で、需要（パック、NAI/WAI、ADP、スターター、LE フラップなど）に全く依存しない。源の圧は N1 から線形（エンジン 0–50% N1 で 0→約 35〜40 psi、APU 0–80% N1 で 0→約 35〜41 psi、上限は読込みごとの乱数）。APU で全パックのまま始動できる、ダクト隔離時の 1 パック制限が意味を持たない、ADP の出力も需要と無関係になる | FCOM p.895 (7.30.1)、p.183 (SP.7.1)、p.123 (NP.21.29)、p.614 (2.40.4)、LH36 p.64 | AIR:425-454、AIR:701-762、HYD:410-455 |
| PNEU-02 | 欠落 | 中 | M | エンジン側が PRSOV 1 弁だけ（「スイッチ ON かつ psi ≥12 で開」）。HPSOV/PRV、IP/HP 切替、PRSOV の逆流防止（ダクト圧のほうが高いと閉）、始動中の PRV 閉と 15 s 遅れ、過熱ラッチとスイッチでのリセットが無い。>BLEED n OFF は N2 >50% でなく X-Plane の ENGN_running で判定 | FCOM p.576 (2.10.24)、p.612 (2.40.2)、LH36 p.12・p.48・p.64・p.76・p.100、ATA30_32_35_36 p.19 | AIR:465-661、AIR:955-997 |
| PNEU-03 | 欠落 | 中 | M | 抽気系の故障と警報が無い。SYS FAULT 灯は X-Plane の bleed_air_fail アナンシエーターの直結。BLD n OVHT/PRV、BLEED n、BLEED HP ENG n、BLD DUCT LEAK L/C/R はメッセージ表にあるだけで、立てるコードが無い | FCOM p.575 (2.10.23)、p.619 (2.50.1)、LH36 p.12・p.100-102、ATA26_28 p.284-286 | LIT:1434-1437、WRN:114-116、WRN:208-219 |
| PNEU-04 | 欠落 | 中 | S | BLEED ISLN L/R（advisory、beeper、10 s）と >BLEED ISLN APU が未実装。弁の動きがほぼ瞬時（アニメーション速度 20）なので VALVE 灯も実際にはほとんど点かない | FCOM p.575、p.619、ATA30_32_35_36 p.22・p.28、LH36 p.78 | AIR:671-694、WRN:220-222、LIT:1338-1357 |
| PNEU-05 | 挙動の誤り | 中 | S | APU 抽気弁が APU N1 約 27%（psi >12）で開き、APU セレクター OFF（60 s の冷却中）や APU 火災スイッチで閉じない。電源も不要として扱っている。実機は APU RUNNING（N1 ≥95%、+2 s）で開き、セレクター OFF で即閉、115V AC bus 2 のモーター弁 | FCOM p.575、p.867 (7.14.1)、p.897 (7.30.3)、LH36 p.88-89 | AIR:440、AIR:488-496 |
| PNEU-06 | 挙動の誤り | 低 | S | ISLN の電源判定が X-Plane の bus 0 だけで、電源が切れると閉じる。実機は L が AC bus 1、R が AC bus 3 のモーター弁（電源喪失時の位置は資料に記載なし。保持すると推定） | LH36 p.86-87 | AIR:468-485 |
| PNEU-07 | 欠落 | 中 | M | 地上空気（エアカート）が無い（psi 0 固定、TODO）。地上空気での始動（30 psi 規定）、EXT AIR 表示が再現できない。EXT AIR は acf に要素が無い | FCOM p.183 (SP.7.1)、p.578 (2.10.26)、p.613 | AIR:435-437 |
| PNEU-08 | 欠落 | 中 | M | 始動の空気条件が緩い。始動弁はダクト圧 >12 psi で開き、スターターの回転はダクト圧に依存しない。`min_engine_start_duct_pressure = 25` は未使用。アイドルのエンジンからのクロスブリード始動や 3 パック ON のままの APU 始動もできてしまう（ENG 側との調整が要る） | FCOM p.183 (SP.7.1)、p.879 (7.20.9)、p.895 | AIR:469、AIR:499-536、ENG:1815-1872 |
| PNEU-09 | 挙動の誤り | 低 | S | 主 EICAS のダクト圧ブロックの表示条件に FCOM に無い条件（ダクト圧 <11、CABIN ALT AUTO、OUTFLOW VLV、変化率）が入っている。表示の大半は ATA 21 の担当なので調整して直す | FCOM p.585 (2.10.33)、ATA30_32_35_36 p.128 | AIR:892-922 |
| PNEU-10 | 挙動の誤り | 低 | S | 表示の閾値: 主 EICAS の右の白 LED が `duct_pressure_L` を参照し、11.00〜11.01 psi ではどの LED も出ない。ECS synoptic は 12.0 ちょうどで出ない。FCOM は 12 以上白・11 以下琥珀。プラグイン側の出力で回避し、右 LED はカスタム acf で直す（要承認） | FCOM p.578、p.585 | ACF:124722-124781、ACF:135413-135430 |
| PNEU-11 | 挙動の誤り | 低 | S | ECS synoptic のエンジン区間の流れが `bleed_air_psi` >11 だけで決まり、スイッチ off で PRSOV が閉でも流れが出る。APU 区間の流れも APU 弁と無関係。PRSOV の琥珀 OFF、移動中の記号が無い（acf の制約。§6 の再定義で一部は直る） | FCOM p.576、LH36 p.16 | AIR:442-452、ACF:135190-135260 |
| PNEU-12 | 欠落 | 低 | M | GE の逆推力用の抽気（スイッチ off でも HPSOV/PRV 開、低出力で HPSOV 開）が無い | FCOM p.576 (570)、p.893 (7.20.23)、ATA30_32_35_36 p.19 | なし |
| PNEU-13 | 挙動の誤り | 中 | M | EEC の抽気補正: パック数を選択器の値の合計で数えるため A（2）・B（3）を選ぶと誤る。実際の抽気源（APU→パック、エンジン抽気 off）を見ない。GE は Go-around の補正表（PI.20.32 と同じ値）を離陸・上昇・巡航に流用。防氷の補正は ATA-30 の ICE-11 | FCOM p.263 (PI.10.37)、p.300 (PI.15.6)、p.360 (PI.20.32) | EEC/B747.42.xt.EEC.GE.lua:501-516、EEC/B747.42.xt.EEC.PW.lua:547-562、EEC/B747.42.xt.EEC.tbls.lua:93-107・338-342 |
| PNEU-14 | 挙動の誤り | 低 | S | X-Plane 本体の抽気モデルとの関係が未整理。`isol_valve_left/right` を書いているが `_has_full_bleed_air 0` なので効かないと推定。X-Plane の抽気損失（engine_loss_from_bleed_air_ratio）はプラグインの弁状態と無関係に X-Plane が計算している（推定） | DataRefs.txt（X-Plane 12）、acf | AIR:102-103、AIR:712・717・739・744 |

ACF_DIFF.md との関係: 抽気に関わる acf 値（`_has_full_bleed_air`、`_has_APU_bleed_air`、`_bleed_draw_*`）は純正とカスタムで同じ。ACF_DIFF.md の差分項目にこの系統の項目は無い。コードは acf の値を読んでいない（X-Plane 本体が使うだけ）。

## 8. 作り直しか部分修正か

作り直しを勧める。

- 抽気部分（AIR:424-791 と AIR:955-997）は約 400 行で、源の最大値を取る単純な作り。必要なのは「エンジン 4 基の弁の状態機械 + 3 区画のダクト + 需要」で、構造が違うため直すより書き直すほうが速く安全。
- 同じファイルにパック・与圧（ATA 21）がある。ファイルを抽気（新モジュール）と空調・与圧に分け、抽気側は区画ごとの圧力と「供給可能かどうか」を出し、パック側は需要を返す取り決めにする。
- 守るもの: §6 の dataref・コマンドの名前と意味（INTERFACES.tsv と acf の SHOW_* 条件）、`button_switch/position` の添字、灯の `brightness_ratio` の添字、AI の自動手順（B747.95.xt.AI が同じコマンドを使う）。
- 順序の案: (1) 抽気モジュールを作り、今と同じ出力 dataref を出す → (2) 防氷（ATA-30）を新しい出力に合わせる → (3) パック需要（ATA 21）、ADP（ATA 29）、始動（ATA 80）とつなぐ → (4) 故障と EICAS メッセージ。

## 9. 未確認事項

- X-Plane の `isol_valve_left/right` に効果があるか、X-Plane の抽気損失（engine_loss_from_bleed_air_ratio）がどの条件でどれだけ推力・EGT に効いているか（シムで確認）。
- アイドルと APU のときのダクト圧の実値、スターターが回せる最低ダクト圧と N2 の関係（資料に記載なし）。
- HPSOV 切替圧の 42,000 ft の値（LH36 の中で 77 psig と 74 psig が食い違う）。
- ISLN と APU 弁の移動時間、電源喪失時の位置（資料に記載なし）。
- BLD DUCT LEAK C の検知元（ATA26_28 は L/R だけ）。
- ATA30_32_35_36 の 36 章が CF6 機の資料かどうか（14th stage と TR の記述からの推定）。
- INTERFACES.tsv が acf の SHOW_* 条件の dataref を拾っていない件（全系統に関わる。175 個）。
- `sim/cockpit2/annunciators/bleed_air_fail` の 4 発機での割り当て（どの故障で何番が立つか）。
