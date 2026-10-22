# ATA 27 Flight Controls — 実装ノート

GAP ID の接頭辞：`FCTL`。2026-10-23 作成。コードは `overhaul` ブランチ（041c9ffa）時点。

## 1. 概要

- 対象：エルロン（内側・外側と外側ロックアウト）、スポイラーとスピードブレーキ（自動を含む）、後縁（TE）・前縁（LE）フラップ（FCU による制御・保護・表示）、水平安定板トリム（SRM・STCM・cutout・alternate・greenband）、エレベーターとフィール、ラダー（rudder ratio changer、トリム）、FLT CONTROL HYD POWER、フラップ表示、FCOM 9.30 の EICAS メッセージ。
- 担当外（接点だけ書く）：ヨーダンパーの制御則・AP サーボ・autotrim 指令の計算（ATA 22）、油圧の発生（ATA 29、`notes/ATA-29.md`）、stall / configuration warning（27-32・27-90、crew alerting 担当）、STATUS ページそのもの（ATA 31）。
- 使った資料（ページは PDF ページ）：
  - ATA27：27-00 p.3–48、27-10 p.49–136、27-60 p.137–210、27-50 p.211–340、27-80 p.341–414、27-40 p.415–524、27-30 p.525–590、27-20 p.591–688。見た図：p.57・59・107・133・165・181・183・205・207・289・335・337・339・345・399・411・413・521・523・587・637・685。27-90 は接点だけ（p.726–740）。
  - FCOM 9.10（p.927–940）、9.20（p.941–956）、9.30（p.957–958）。関連：L.10（p.79・80・82・83）、NP.21（p.107・117・120–121・126・140・148–149）、Bulletin TB1-4（p.47）・TB1-14（p.49）・TB1-15（p.53–54）、2.40.4（p.614）、6.20（p.803・804・819）、11.40.44（p.1320）。FCTM p.283（8.5）、p.289–290（8.11–8.12）。
- 型式差（FCOM の 109/405/570）：舵面位置表示は 109 が STATUS、405/570 が secondary engine 画面（FCOM p.938 (9.10.12)）。Mach stability trim は 570 だけ（FCOM p.945 (9.20.5)）。greenband の mid 帯の照明方式（FCOM p.944 (9.20.4)）。スピードブレーキ使用の非推奨はフラップ 10 超（405）／20 超（109, 570）（FCOM p.83 (L.10)）。エンジン型式（PW/GE/RR）による操縦系統の違いは資料に無い（takeoff configuration warning の N1 閾値だけ：ATA27 p.730 (27-90)）。
- 資料の食い違いと採用：
  1. 外側エルロンのロックアウト：FCOM は「238 kt で中立に固定」（FCOM p.947 (9.20.7)）、E&M は 232/238 kt・M 0.51/0.53 のヒステリシスと LE group A の条件（ATA27 p.106 (27-10)）。内部論理は E&M に従う（矛盾しない）。
  2. >SPEEDBRAKES EXT：FCOM（p.958 (9.30.2)）、ATA27 p.205（脚 down&locked でないことを追加、推力レバー「アイドルから 5° 以上」）、ATA27 p.740（27-90：TRA 40°）で食い違う。条件の組み立ては FCOM、閾値は p.740 を採用。
  3. >STAB GREENBAND：FCOM は Advisory（p.958）、ATA27 p.523 は caution/status で「地上のみ・CG 入力無効」を付記。レベルは FCOM、条件に E&M の付記を採用。
  4. stab trim cutout の復帰：FCOM は「自動遮断後は ON にするまで遮断のまま」（p.945 (9.20.5)）、E&M は「ON か CUTOUT から AUTO に戻すと 5 s 後に開」（ATA27 p.450）。両立するので両方実装する。
  5. エレベーターの可動範囲：E&M は内側 25° 上・15° 下（ATA27 p.548）。コードと acf は 22°/17°。E&M を採用（要確認）。
  6. LE フラップが secondary に切り替わる遅れ：FCOM は 20–45 s（p.953 (9.20.13)）、E&M は「time delays」とだけ（ATA27 p.381）。FCOM の値を使う。TE は E&M の 7 s（脚の動作中 42 s）（ATA27 p.284）。

## 2. 構成

### 2.1 舵面とアクチュエータ

| 舵面 | 駆動 | 油圧系統 | 可動範囲 | 典拠 |
|---|---|---|---|---|
| 内側エルロン ×2 | PCP 1 台（2 系統、内部で分離） | L 1+3、R 2+4 | ±20°（ホイール約 45° で最大） | FCOM p.948 図、ATA27 p.94・98、p.59 図 |
| 外側エルロン ×2 | PCP 1 台（2 系統）＋ lockout 機構（電動アクチュエータ） | L 1+2、R 3+4 | 上 25°・下 15° | FCOM p.948 図、ATA27 p.102・112・114 |
| CLCP ×2 | デュアルタンデムの油圧ブースター。AP サーボ弁内蔵。第 3 AP 横アクチュエータは系統 1 | 2 系統（組は資料に記載なし） | ±2 in | ATA27 p.80–86 |
| スポイラー 1–12 | 各 1 本（単系統）。1–5・8–12 が flight、6・7 が ground | 2: 2,3,10,11／3: 1,4,9,12／4: 5–8 | 45°（5・8 は空中 20°、6・7 は 0/20/45 の 3 位置） | FCOM p.952 図、ATA27 p.138・156・160・190 |
| 内側エレベーター ×2 | PCP（2 系統） | L 1+2、R 3+4 | 上 25°・下 15° | FCOM p.943 図、ATA27 p.532・548 |
| 外側エレベーター ×2 | 内側に機械的に追従（単系統）。リンク破断で中立へ | L 1、R 4 | 内側に追従（中立は内側より 2° 下） | ATA27 p.550・552 |
| 水平安定板 | ボールねじ。油圧モーター 2（STCM 2 台）、モーター毎の油圧ブレーキ | 左 STCM＝3、右 STCM＝2 | 0–15 units（電気トリムの制限は §4.5） | ATA27 p.418・432・462・468–470 |
| 上ラダー | アクチュエータ 3（PCM） | 上 1、中・下 3。YD 上は 3 | 低速 32°、高速 5° | ATA27 p.600・652・658、FCOM p.950 図 |
| 下ラダー | アクチュエータ 2（PCM） | 上 4、下 2。YD 下は 2。系統 4 にヒューズ | 同上 | ATA27 p.600・602・650 |
| TE フラップ ×4 | 各翼 IB・OB（triple slotted）。IB と OB で別の PDU（油圧モーター＋電動モーター、トルクチューブ、ボールねじ） | IB 1、OB 4（電動は交流） | 0–30 units | FCOM p.953、ATA27 p.216・234・244・248 |
| LE フラップ 28 | VC 22（1A–10、17–27）＋ Krueger 6（11–16）。PDU 8（空気圧モーター＋電動モーター） | 空気圧（左右ダクト） | 格納／展開の 2 位置 | ATA27 p.344・346・359・368・374 |
| エレベーターフィール | フィール計算機＋フィールユニット | 2+3（遮断弁の上流から取る） | — | FCOM p.943、ATA27 p.532・564 |

- 一次操縦系統に manual reversion は無い（FCOM p.941 (9.20.1)）。
- LE の群（FCOM の表示は各翼 outboard・midspan・inboard の 3 箱）：PDU は各翼 1–4（外→内）（ATA27 p.359）。group A＝PDU 2・3・4、group B＝PDU 1（ATA27 p.413 図）。outboard＝1A–5、midspan＝6–10、inboard＝Krueger 11–13（ATA27 p.368・372）。midspan が PDU 2・3、outboard が PDU 1 なのは p.345 の図の配置からの `推定`。

### 2.2 Flight Control Electronics（FCE）

- FCU ×3（L/C/R、同一品で取付位置で機能が決まる）：フラップの制御・保護・表示。安定板位置の中継も行う（ATA27 p.16・35–36・228）。
- SRM ×2（stab trim / rudder ratio module）：stab trim、aileron lockout、RRC。各機能は双方の SRM が持ち、一方が制御・他方が待機（ATA27 p.16・31–32・104・640）。
- YDM ×2：上下ヨーダンパー（ATA 22）（ATA27 p.16・38）。
- PSM ×4：左 PSM 1L・2L が左 FCU・左 SRM・上 YDM、右 PSM 1R が中央 FCU・下 YDM、2R が右 FCU・右 SRM（ATA27 p.18–24）。

### 2.3 電源

| 機器 | 電源 | 典拠 |
|---|---|---|
| PSM 1L・2L | 115V AC standby bus、監視は 28V DC battery bus | ATA27 p.22 |
| PSM 1R／2R | 115V AC bus 1＋28V DC bus 1／AC bus 2＋DC bus 2 | ATA27 p.24 |
| フラップ input actuator（一次） | 115V AC bus 1（PRI TE FLAPS）、28V DC bus 1 | ATA27 p.232、p.339 図 |
| TE alternate モーター | 115V AC bus 4（IB）、bus 3（OB）。ALT FLAP リレーは 28V DC bus 3（OB は bus 4） | ATA27 p.339 図 |
| LE 駆動制御・alternate モーター | 例（左翼 group A）：制御 115V AC bus 3・28V DC bus 3、alternate モーターは drive 2＝AC bus 3、drive 3＝bus 4、drive 4＝bus 1 | ATA27 p.413 図 |
| TE フラップ制御 | main battery bus にも負荷あり（詳細は資料に記載なし） | FCOM p.819 (6.20.25) |
| auto speedbrake | 28V DC bus 1（AUTO SPD BRK） | ATA27 p.181・183 図 |
| speedbrake lever lock solenoid | 28V DC（bus は資料に記載なし） | ATA27 p.166 |
| RRC（上／下） | 115V AC・28V AC・28V DC の bus 3／bus 2 | ATA27 p.639 |
| stab trim（手動） | L STAB CONTROL CB（bus は資料に記載なし）。位置表示は 28V AC（STAB TRIM POS IND CB 2 つ） | ATA27 p.483・512 |
| 舵面・トリム位置トランスミッタ | 28V DC（SPD カード）、28V AC（synchro） | ATA27 p.120・202・580 |

- standby bus だけの状態：左翼 TE の位置センサーが非通電（expanded 表示で amber X）（FCOM p.955 (9.20.15)、ATA27 p.320）。LE は AC 制御が要るので展開できず、フラップ 1 選択後に FLAPS DRIVE（FCTM p.283 (8.5)）。

## 3. 操作と表示

### 3.1 操作（FCOM p.927–940 (9.10.1–14)）

- 操縦輪・操縦桿・ペダル：機長の操縦輪は ±90°、F/O は ±100°（ATA27 p.64・66）。操縦桿を押す／引くとトリムの反対方向を阻止（FCOM p.927）。ペダル約 4 in（ATA27 p.608）。
- 操縦輪の STAB TRIM スイッチ（2 個を同時に押す、ばねで中立）（FCOM p.927）。
- STAB TRIM cutout（2・3、ガード付き）：ON／AUTO（予定外のトリムで自動遮断）／CUTOUT（FCOM p.928 (9.10.2)）。
- ALTN STAB TRIM スイッチ（2 個同時、別チャンネル）（FCOM p.929）。
- AILERON トリムスイッチ（2 個同時）、RUDDER トリム選択器（ばねで中立）（FCOM p.930–931）。
- YAW DAMPER UPPER/LOWER スイッチと INOP 灯（スイッチ OFF か YD 不作動）（FCOM p.931）。
- SPEEDBRAKE レバー：DN／ARM／FLIGHT DETENT／UP。空中は自動ストップで FLIGHT DETENT まで（FCOM p.933 (9.10.7)）。
- フラップレバー：0（UP）・1・5・10・20・25・30、ゲートは 1 と 20（FCOM p.934–935、ATA27 p.224）。
- ALTN FLAPS ARM スイッチ（ALTN）と ALTN FLAPS 選択器（RET／OFF／EXT、最大フラップ 25）（FCOM p.935 (9.10.9)）。
- FLT CONTROL HYD POWER（overhead maintenance panel）：系統ごとに TAIL・WING の NORM／SHUT OFF と VALVE CLOSED 灯（FCOM p.940）。

### 3.2 表示

- 安定板トリム指示器（ペデスタル両側）：0–15 units、greenband（mid・nose down・nose up の 3 帯）、OFF フラグ（FCOM p.929・944、ATA27 p.502）。
- エルロントリム指示（操縦輪、最大 6 units）、ラダートリム指示（左右 10 units、不作動で黒いテープ）（FCOM p.930・949、ATA27 p.76・614）。
- EICAS のフラップ表示：normal／expanded（secondary）／alternate（§4.4）（FCOM p.936–938）。
- 舵面位置（STATUS または secondary engine 画面）：上下ラダー、左右外側エレベーター、4 枚のエルロン、スポイラー（左はスポイラー 4＝flight・speedbrake・ground、右はスポイラー 12＝flight・ground のみ）（FCOM p.939・947・951）。

### 3.3 EICAS メッセージ（FCOM p.957–958 (9.30.1–2)）

| メッセージ | レベル | 条件 | 典拠 |
|---|---|---|---|
| AILERON LOCKOUT | Advisory | lockout アクチュエータ位置が指令と不一致（両 SRM で検出） | FCOM p.957、ATA27 p.110・p.133 図 |
| >FLAP RELIEF | Advisory | load relief 作動中（relief 20 か 25） | FCOM p.957、ATA27 p.288・p.335 図 |
| FLAPS CONTROL | Caution・beeper | 3 台の FCU が制御不能、または ALTN FLAPS ARM、または flap lever RVDT 2 個故障 | FCOM p.957、ATA27 p.335・411 図 |
| FLAPS DRIVE | Caution・beeper | secondary でも駆動できない、または非対称 | FCOM p.957、ATA27 p.290・294・384 |
| FLAPS PRIMARY | Caution・beeper | 1 つ以上の群が secondary（電動）で動作 | FCOM p.957、ATA27 p.284・381 |
| >FLT CONT VLVS | Advisory | 操縦系統の遮断弁が 1 つ以上「全開でない」 | FCOM p.957、ATA27 p.14 |
| RUD RATIO DUAL／SNGL | Advisory | RRC が両方／片方故障 | FCOM p.957、ATA27 p.647 |
| SPEEDBRAKE AUTO | Advisory | 自動スピードブレーキの故障（§4.2） | FCOM p.957、ATA27 p.184・p.205 図 |
| >SPEEDBRAKES EXT | Caution・beeper | §4.2 | FCOM p.958、ATA27 p.740 |
| >STAB GREENBAND | Advisory | 前脚オレオ圧スイッチと選択 greenband の不一致 | FCOM p.958、ATA27 p.510・523 |
| >STAB TRIM 2, 3 | Advisory | 自動遮断、cutout が CUTOUT、または指令したが該当アクチュエータが動かない | FCOM p.958、ATA27 p.455–456 |
| STAB TRIM UNSCHD | Caution・beeper | 予定外の動きで自動遮断しない、または AP engage 中に ALTN トリム使用 | FCOM p.958、ATA27 p.458 |
| >YAW DAMPER LWR, UPR | Advisory | YD 故障・電源喪失（モジュール、アクチュエータ、IRU OFF/ALIGN、スイッチ OFF、電源 OFF） | FCOM p.958 |
| SPEEDBRAKE ARMED | Memo | レバーが ARM | FCOM p.958 |

- STATUS（E&M）：AILERON LOCKOUT、SPEEDBRAKE AUTO、TE FLAPS、FLAP SYS MONITOR、FLAP CONTROL (L,C,R)、FLAP LOAD RELIEF（エアデータ喪失）、LE SINGLE DRIVE、LE MULT DRIVE、STAB TRIM UNSCHD、STAB AUTO CUTOUT、STAB TRIM、STAB SPEED TRIM、STAB AUTO TRIM、ELEVATOR FEEL、RUDDER RATIO、RUD TRIM CTR（ATA27 p.133・205・337・411・523・587・685 の各図）。

## 4. 内部ロジック

擬似コードの「A が t s」は条件 A が t 秒続いたら成立の意味。角度はホイール・レバーの角度、units はフラップ／トリムの単位。

### 4.1 エルロンと外側ロックアウト

- 横操縦の入力は左ケーブル→feel・trim・centering 機構→左右 CLCP→aileron programmer→内側 PCP と（lockout 経由で）外側 PCP。programmer は初期の舵角が大きく、ホイール約 45° で全舵角、それ以上はスポイラーだけが増える（ATA27 p.54・88・134）。曲線（p.59 図からの読み取り、`推定`）：内側 10°→5.5°、20°→11°、30°→15.5°、40°→19°、45°→20°。外側上げ 10°→7.5°、20°→14°、30°→20°、47°→25°。外側下げ 10°→4.5°、20°→8.5°、30°→12.5°、45°→15°。
- AP：CLCP を逆駆動。約 14 lb で乗員が override、AP の権限はホイール約 25°（ATA27 p.82）。
- トリム：feel 機構の中立を電動アクチュエータで移動。最大 6 units＝ホイール 47°（±3°）（ATA27 p.76、FCOM p.947–948）。AP engage 中のエルロントリムは禁止（FCOM p.79 (L.10)）。

```
LOCK   = GRP_A_LE_RETRACTED & (Vc > 238 | M > 0.53)
UNLOCK = !GRP_A_LE_RETRACTED | (Vc < 232 & M < 0.51)
それ以外は前回の指令を保持                              -- ATA27 p.106、p.107 図
制御 SRM：電源投入時にランダムで 1 台、他方は待機。左 SRM は左 ADC が主・右 ADC が副（右は逆）（p.104・108、p.44）
FCU のフラップ入力喪失 → 速度/Mach だけで判定（p.108）
両 SRM の lockout 機能が無効 & 空中 → 両方 unlock（default）（p.108）
監視：指令から 45 s 以内に lock/unlock しない → 他 SRM へ移管、移管後も同じ → AILERON LOCKOUT（advisory＋status）
      locked と unlocked の位置信号が同時に 40 s → 同様（p.110）
```

- 3 台の FCU が同時に故障した事例では外側エルロンが unlock した（FCOM p.53 (TB1-15)）。乗員から見える挙動はこれに従う。
- アクチュエータの移動時間は `資料に記載なし`。

### 4.2 スポイラー・スピードブレーキ

- 横操縦：差動機構 2 台。左は 3・4・5 と 8・9・10、右は 1・2 と 11・12 を動かす（ATA27 p.143）。ホイール約 8–14° で動き始め、比例して 1–4・9–12 は最大 45°、5・8 は最大 20°、6・7 は横操縦では動かない（ATA27 p.206、p.207 図）。スピードブレーキ展開中も横操縦で上下に動く（mixer）（ATA27 p.150、FCOM p.947 (9.20.7)）。スピードブレーキ展開中は横操縦のロール率が増す（ATA27 p.207 図）。
- レバーの位置：DN 0°、ARM 約 3°（ARM で S217 が閉）、FLIGHT DETENT 約 37°、UP 約 80°（ATA27 p.162、p.165 図）。空中は 28V DC の lock solenoid が FLIGHT DETENT で止める。solenoid 故障時もばねのローラーが detent を作る（ATA27 p.166）。

| スポイラー | 空中（FLIGHT DETENT まで） | 地上（UP まで） | 典拠 |
|---|---|---|---|
| 3,4,9,10 | 約 6° から増え、FLIGHT DETENT で 45° | 45° | ATA27 p.164、p.165 図 |
| 5,8 | 約 6° から増え、約 35° で 20°（ratio changer 格納で 20° 制限） | 約 49° で 45°（系統 4 の U2 で ratio changer 伸長） | ATA27 p.156・194、p.165 図 |
| 6,7 | 約 28° で 20°（ground spoiler valve の U1） | 約 49° で 45°（U1＋U2） | ATA27 p.188・190、p.165 図 |
| 1,2,11,12 | 動かない | 約 43° から増え、約 74° で 45° | ATA27 p.164・186、p.165 図 |

```
IDLE13  = TL1 と TL3 がアイドルから 6–8° 以内（S1B・S3B → R7519・R7520）            -- ATA27 p.176・179
GND     = R837（primary）と R838（alternate）がともに GND：
          (HYD1 > 1600 psi & 胴体脚 down&locked & 胴体脚 not tilted) | (HYD4 > 1600 psi & 主翼脚 not tilted)  -- p.182、p.183 図
EXTEND  = IDLE13 & (S217=ARM | S861=リバースレバー 2 か 4 を引いた) & GND → R835 → アクチュエータ伸長 → レバー UP（全スポイラー 45°）
RETRACT = TL1 か TL3 を進める → R834 → アクチュエータ格納 → レバー DN（自動・手動どちらで出したときも）  -- p.180、FCOM p.951
          空中でも R834 側に給電される（p.181 図からの `推定`）
レバーを手で DN にすると no-back brake が滑り、アクチュエータは格納側へ電気的に戻る（p.170）
リバースレバー 2/4 はクラッチパックのカムでレバーを DN から機械的に持ち上げる（p.174）
電源：28V DC bus 1
SPEEDBRAKE AUTO = (S217 が非 ARM & アクチュエータが格納でない) | (R834 & R835 が同時) | (R837 ≠ R838)  -- p.184、p.205 図
```

- 用途：着陸（ARM）、RTO と ARM し忘れの着陸（リバース）、接地後のゴーアラウンドで格納（FCOM p.933・951 (9.20.11)、ATA27 p.158）。
- SPEEDBRAKE AUTO が出ているとき：自動展開を失う恐れ。ARM なら空中で不意に展開する恐れ。DN なら不意の展開は無い（FCOM p.952 (9.20.12)）。
- CONFIG SPOILERS 用に S217 が「レバー DN でない」を MAWEA へ出す（ATA27 p.169）。

```
>SPEEDBRAKES EXT = レバーが ARM より後ろ & RA > 15 ft &
                   ( RA ≤ 800 ft | TE フラップ 25/30 | 推力レバー 2 本以上が speedbrake power level（TRA 40°）より前 )
                   -- FCOM p.958、ATA27 p.740（MAWEA。left EIU の推力レバー、left 側の LRRA を優先）
```

- レバーの RVDT 3 個は FCC へ（FMC 喪失時の最小速度計算に使う）（ATA27 p.198）。スポイラー位置の表示はスポイラー 4 と 12 のトランスミッタ（ATA27 p.200）。

### 4.3 フラップ（FCU）

```
FCU の役割：L＝primary 油圧（TE）・空気圧（LE）、R＝primary 電動、C＝EIU への位置出力（C→L→R）。
           3 台とも故障保護と位置表示を常時行い、1 台で全機能を持てる              -- ATA27 p.230・316・352
レバー：RVDT 3 個の median（p.284）
順序（primary・secondary 共通）：UP→1：group A（inboard＋midspan）展開、TE は UP のまま
      1→5：TE 5、group B（outboard）展開。10/20/25/30：TE のみ
      格納：レバー 1 で IB TE < 4.5 units になったら group B 格納、レバー UP で OB TE が UP になったら group A 格納
      -- FCOM p.954 (9.20.14)、ATA27 p.381
TE primary（油圧）：input actuator（115V AC）→ IB/OB の PDU。priority valve は 2000 psi 超で開く（脚を優先）  -- p.232・241
```

- TE が secondary（電動）に移る条件（ATA27 p.284・290・292・294、FCOM p.953）：
  - 指令と位置の不一致（動かない）が 7 s（脚の動作中は 42 s）→ その群を右 FCU の電動へ（FLAPS PRIMARY）。動いた群は左 FCU の油圧のまま。
  - 油圧 < 1400 psi が 4 s → 電動。> 1600 psi が 4 s → 油圧へ戻る。油圧があるのに電動になった群は、格納して 10 s 後に油圧へ戻る（不具合が残っていれば次の操作で再び不一致）。
  - 逆方向に動く（moving away）0.5 s → bypass valve を閉じて電動。油圧中の逸走（uncommanded motion）0.5 s → 電動。電動中の逸走 4.0 s → electric disable relay で停止（FLAPS DRIVE）。
  - 電動で 25 s 動かない → FLAPS DRIVE と STATUS の TE FLAPS。
- TE 非対称：左右の IB の差が全行程の 6.2 %、OB は 3.4 % を超えて 0.1 s → bypass valve を閉じて停止、その群は電動も禁止（FLAPS DRIVE）。位置が一致したら監視はリセットするが、制御はレバー操作を待つ（ATA27 p.290・292、FCOM p.953）。
- LE（ATA27 p.381・384・387、FCOM p.953）：
  - primary は空気圧 PDU（約 9 s）、secondary は電動（約 90 s）（ATA27 p.363）。左右ダクトが各翼の LE を駆動。ダクト区画を隔離するとその側の LE は電動（FCOM p.614 (2.40.4)）。全抽気が止まると全フラップが secondary（FCOM p.49 (TB1-14)）。
  - 空気圧での不一致 → 遅れの後（FCOM：20–45 s）その群を両翼対称で電動へ。inboard か midspan のどちらかが故障したら両方。FLAPS PRIMARY、STATUS は LE SINGLE DRIVE（1 台）／LE MULT DRIVE（複数）。目標位置に着いたら空気圧へ戻る。
  - 空気圧での逸走 → 電動、空気圧は禁止のまま（LE MULT DRIVE）。電動での不一致 → flap protection relay で停止、FLAPS DRIVE（このとき FLAPS PRIMARY は抑止）。電動での逸走 → 停止、電源再投入まで復帰しない。
  - LE に非対称保護と load relief は無い（ATA27 p.352）。
- LE の自動格納（ATA27 p.382、FCOM p.955）：地上で空気圧モードのとき、エンジン 1・4 か 2・3 がリバース → group A を格納（9 s）、リバース信号が消えたら再展開。PDU が空気圧で故障していればその区画は格納しない。15 s で左 FCU が不一致を検出して右 FCU に移り、格納した group A を電動で展開する。
- load relief（ATA27 p.288、p.289 図、FCOM p.954）：IB と OB がともに油圧モードのときだけ。レバーは動かない。>FLAP RELIEF。エアデータを失うと STATUS の FLAP LOAD RELIEF。

| レバー | 速度増 | 速度減 |
|---|---|---|
| 30 | 178 kt で 30→25、203 kt で 25→20 | 195 kt で 20→25、170 kt で 25→30 |
| 25 | 203 kt で 25→20 | 195 kt で 20→25 |

- alternate（ATA27 p.296–302・388–390、FCOM p.935・954）：ALTN ARM → FCU は位置出力だけ（standby）、bypass valve を bypass、flap lever は不作動。選択器 EXT/RET で TE・LE の電動モーターを直接駆動（open loop）。EXT では全群がすぐ動き、TE は 25 で止まる（limit switch）。RET では LE は IB TE が完全に格納されるまで出たまま（interlock）、その後一斉に格納。途中で止めるには OFF。非対称保護・load relief なし。解除するとフラップはレバー位置へ動く（レバー・input actuator・位置が一致していなければ）。
- 3 FCU 同時故障の影響（FCOM p.53–54 (TB1-15)）：FLAPS CONTROL、primary/secondary の制御と位置表示が不作動、alternate は使えるが expanded 表示が出ない、AP 不作動、FD が出ないことがある、PFD のフラップ速度が出ない、外側エルロン unlock、アイドルは approach idle、stall warning のマージン減、GPWS の TOO LOW FLAPS。
- 時間：TE の primary・secondary の所要時間は `資料に記載なし`（secondary は primary よりずっと遅い：FCOM p.953、FCTM p.290 (8.12)）。

### 4.4 フラップ表示（FCOM p.936–938・954–955、ATA27 p.318–322・398–400、p.399 図）

```
SHOW = (レバー ≠ UP) | (いずれかの面が UP でない) | (全面 UP になってから 10 s 以内)
MODE = ALTN ARM なら ALTERNATE、secondary 動作中か非正常位置なら EXPANDED、それ以外 NORMAL
NORMAL  ：テープ 1 本。UP と 1 の間＝group A 移動中（½ unit）、1＝group A 展開・TE UP、1–30＝最も遅い TE 群の実位置
EXPANDED：TE 4 本（白＝正常、amber＝非対称か駆動故障）、LE 6 箱（白枠＝格納、白斜線＝移動中、緑塗り＝展開、amber＝駆動不作動）
          位置データ無効の TE は amber X（STATUS の FLAP SYS MONITOR）
ALTERNATE：EXPANDED と同じ。ただしレバーの線と数字は出さず、5 と 25 に index mark
レバーの線と数字：移動中は magenta、全面がレバー位置に一致したら green
```

- 位置センサー：TE は各フラップ外側トランスミッションの RVDT（4）と PDU の RVDT（2）、LE は PDU の位置スイッチ（ATA27 p.310–314・394–396）。
- リバースによる LE 自動格納中は表示が「移動中」になる（FCOM p.955）。

### 4.5 水平安定板トリム

```
指令源：ALTN スイッチ（両 STCM のソレノイドへ直接）、操縦輪スイッチ（SRM の auto/manual transfer relay 経由）、
       autotrim（FCC→SRM）、speed trim（SRM）                                    -- ATA27 p.430・483・490
STCM：MOV（常時開）→ arm/control ソレノイド対 → ブレーキ解除 → 油圧モーター。片方だけなら半速（p.462・470）
速度（rate solenoid：Vc ≤ 220 kt で ON、≥ 230 kt で OFF）                       -- p.452
  manual・ALTN・full-rate autotrim（2 モーター）：0.5°/s（低速）、0.2°/s（高速）
  autotrim・speed trim（1 モーター）：0.25°/s、0.1°/s。両 SRM の rate 制御故障 → 低速側の値
電気トリムの制限：ANU 11.6、AND 1.8。脚 down か LE フラップが UP でない、または speed trim 中 → AND 0.8。FRAT → ANU 13.5
ALTN：0.25–14.75（安定板のリミットスイッチ）                                    -- p.483・490・520、p.521 図
column cutout：操縦桿がトリム方向と逆に約 4.5° → 電気トリム（manual/auto/speed）の control ソレノイドを遮断。ALTN は遮断しない  -- p.476・483、FCOM p.945
両スイッチの不一致（機長と F/O、ALTN と操縦輪が逆）→ トリムしない（FCOM p.944）
```

- AP との関係（FCOM p.945 (9.20.5)、ATA27 p.483・488）：AP 1 台 engage 中に操縦輪スイッチ → AP 解除＋トリム。複数 engage 中は操縦輪スイッチ無効（autoland の autotrim 中は FCC が手動入力を無視して engage を保つ）。ALTN は AP の指令に優先し AP を外さない（autotrim 中の使用で STAB TRIM UNSCHD）。
- autotrim：左 SRM は L/C FCC、右 SRM は C/R FCC。エレベーター偏位に基づく指令が 3.5 s 続いたら作動（autoland 中は遅延なし）。FRAT は LAND 2・RA < 120 ft・両 SRM 有効（ATA27 p.488）。指令の計算は ATA 22。
- speed trim（ATA27 p.486、FCOM p.945）：1 台の SRM（ランダム）が半速で行う。空中 20 s 後、Vc ≤ 220 kt、手動/ALTN の入力なし、autotrim でないとき engage。速度増 → ANU、速度減 → AND（engage 時の速度と安定板位置に同期）。手動/ALTN 入力、FCC の engage/解除、column cutout で解除。両 SRM で失うと STATUS の STAB SPEED TRIM。
- cutout と自動遮断（ATA27 p.450、FCOM p.945）：CUTOUT＝MOV 閉。AUTO＝両 SRM が両 STCM の MOV を制御（AUTO に 5 s で開指令、開閉指令は 10 s パルス）。STCM のブレーキ解除圧スイッチが「圧あり」で unscheduled monitor が動きを検出 → 両 SRM が閉。ON は自動遮断を無効にして開。自動遮断後に開くには ON（FCOM）か、ON/CUTOUT から AUTO に戻す（E&M）。閉じない MOV は STATUS の STAB AUTO CUTOUT。

```
>STAB TRIM n = (有効な手動指令中に片方のブレーキ解除圧スイッチだけ「圧あり」＝半速) | 自動遮断 | cutout n = CUTOUT
  ラッチ（CUTOUT 以外）。解除：手動指令で全速に戻る | 系統圧の回復（低→高） | 自動開指令 | ON。CUTOUT→AUTO で 5 s 後に消える
  両 cutout が AUTO で自動遮断したら 2 と 3 の両方                                -- ATA27 p.455–456
STAB TRIM UNSCHD = (autotrim/speed trim/default mode で有効な指令なしに動く | 指令と逆に動く) & 自動遮断していない
  停止後 30 s 表示。自動遮断した場合は抑止（代わりに >STAB TRIM 2・3）               -- ATA27 p.458
```

### 4.6 greenband と STAB GREENBAND

- 帯（units）：mid 3.35–8.15、nose up 帯（前方 CG）3.35–10.15、nose down 帯（後方 CG）1.35–8.15（ATA27 p.521 図）。FCOM は「mid、mid＋AND 側、mid＋ANU 側の 3 種」（FCOM p.944 (9.20.4)）。
- 選択：MAWEA が FMC の CG・GW・thrust から表で選び、takeoff enable 中に点灯、V1（takeoff inhibit）を超えたら消灯（ATA27 p.514）。表の中身は `資料に記載なし`。TAKEOFF REF で CG を入れると FMC が離陸トリム（0.1 unit 刻み）を出し、指示器の greenband を更新する（109, 570）。405 では trim が greenband 内のときだけ小文字で出る（FCOM p.1320 (11.40.44)）。
- 実装案（`推定`）：FMC の離陸トリムが 8.15 を超えたら nose up 帯、3.35 未満なら nose down 帯、それ以外は mid 帯を選ぶ。3D は帯 1 本の平行移動しかできないので、選んだ帯の中心に置く（幅の違いは出せない）。
- 前脚オレオ圧スイッチ：圧高（前方 CG）で接地＝FWD、開＝AFT。mid 帯なら比較しない。選択帯と不一致 → >STAB GREENBAND（地上のみ、CG 入力無効でも出る）。設定圧は `資料に記載なし`（ATA27 p.508–510、p.523 図）。
- CONFIG STAB：離陸推力で安定板が選択帯の外（MAWEA、左 FCU の安定板位置を優先）（ATA27 p.496・729–730）。crew alerting 担当。
- 指示器：電源喪失で全体が暗く OFF フラグ、信号喪失は暗くなるだけ（ATA27 p.502・512）。

### 4.7 エレベーターとフィール

- 操縦桿→前後クアドラント→内側 PCP、外側は内側に追従（ATA27 p.528・534・552）。AP は後部クアドラントの 3 本のアクチュエータ（同 p.528）。
- フィール計算機は pitot/static（速度）と安定板位置（CG 補正）から系統 2・3 の圧を調圧してデュアルのフィールアクチュエータへ。片系統喪失でフィールは変わらない。両系統喪失ではセンタリングばねだけ（速度に依存しない）。安定板入力リンクの故障では high feel 側（FCOM p.943、ATA27 p.564–574）。調圧出力の差 25 % で STATUS の ELEVATOR FEEL（ATA27 p.564、p.587 図）。

### 4.8 ラダー・RRC・トリム

- ペダル→後部クアドラント→feel・centering・trim→上下 RRC→上下 PCM。YD は PCM 内で加算され、ペダルを動かさない。YD の権限は ±4°（ATA27 p.596・598・656、FCOM p.949）。
- RRC（ATA27 p.634・636、p.637 図）：アクチュエータは 155.5 kt まで 0 in、450 kt 以上で 1.0 in（全行程 1.02 in）。ラダー舵角は 0 in で 32°、1.0 in で 5°。曲線の読み取り（`推定`）：170 kt≒0.2、195≒0.4、245≒0.6、310≒0.8、355≒0.9、420≒0.97 in。延長量と舵角の関係は `資料に記載なし`（直線と仮定すると 250 kt で約 15°、367 kt で約 7°。地上試験の「367 kt 位置で 6–8°」（p.682）と合う）。
- RRC の制御（ATA27 p.636・639–648）：1 台の SRM（ランダム）が上下を制御、上下を別の SRM が持つこともある。ADC は SRM ごとに主・副。有効な速度を失うと上は 329 kt、下は 209 kt 相当に固定。SRM が autotrim/autoland なら 0 kt（全権限）。故障したアクチュエータは最後の位置のまま（FCOM p.949）。50 kt 未満が 20 s 続くと一定の格納信号（stall current limit）。監視は 2 s 系（feedback < 0.35 V、28V DC/AC 基準、励磁）と latch 系（servo 誤差 > 0.01 in で 160 kt 未満は抑止、mode/command/output coincidence）。片方失うと RUD RATIO SNGL、両方で DUAL、STATUS は RUDDER RATIO（latch）。
- 片方故障時：その舵面の応答は故障時のまま。高速での急な操作は過大舵角、低速では全舵角が出ないことがある、横風能力が減る（FCOM p.949）。
- トリム（ATA27 p.614–620・625–626、FCOM p.949）：28V DC アクチュエータが feel 機構を回し、ペダルの中立が動く。±10 units（全行程の 80 %）。指示はアクチュエータの RVDT（信号喪失で 0、電源喪失で OFF フラグ）。E&M には press-to-center（1° 以内で停止、30 s 超などで RUD TRIM CTR）があるが FCOM の操作子には無い。
- 系統 4 のヒューズ：14–16 gpm が 2 s で閉（ATA27 p.602）。

### 4.9 FLT CONTROL HYD POWER 遮断弁

- 主翼 4 個（エルロン・スポイラー）、尾翼 4 個（エレベーター・ラダー）、28V DC モーター。全開でないと VALVE CLOSED 灯と >FLT CONT VLVS（ATA27 p.10–14、FCOM p.940・957）。フィール計算機と STCM の供給は遮断弁を通らない（ATA27 p.432・532）。HYD-22（`notes/ATA-29.md`）と同じ部品。

## 5. 他系統とのつながり

| 方向 | 相手 | 内容 | 典拠 |
|---|---|---|---|
| 入力 | 油圧（ATA 29） | 系統 1–4 の圧で各舵面（§2.1）。フラップは 2000 psi の priority valve、FCU は 1400/1600 psi の判定。auto speedbrake は系統 1/4 > 1600 psi（HYDIM 経由）。STCM のブレーキ解除圧 | ATA27 p.40・183・241・292・455 |
| 入力 | 空気（ATA 36） | 左右ダクト圧 → 各翼の LE PDU | FCOM p.614・953、ATA27 p.346 |
| 入力 | 電源（ATA 24） | §2.3 | — |
| 入力 | エアデータ（ATA 34） | Vc・M → SRM（lockout・RRC・trim 速度・speed trim）、Vc → FCU（load relief）、TAS・impact pressure → YDM、pitot/static → フィール計算機 | ATA27 p.44・564 |
| 入力 | 空地・脚（ATA 32） | lever lock solenoid、auto speedbrake（脚の tilt と down&locked）、SRM（gear down でトリム制限）、FCU（LE 自動格納） | ATA27 p.31・35・166・183 |
| 入力 | エンジン・推力レバー | TL1/TL3 アイドル、リバースレバー 2/4、リバース信号（1&4、2&3） | ATA27 p.176・174・382 |
| 入力 | AFDS（ATA 22） | autotrim 指令・FRAT・AP engage 状態、AP サーボ、rollout | ATA27 p.488・628 |
| 入力 | FMC | CG・GW・thrust → greenband | FCOM p.944 |
| 出力 | EICAS（ATA 31） | フラップ位置・表示モード・メッセージ、舵面位置、STATUS | §3 |
| 出力 | MAWEA | TE/LE 位置（離陸は TE 10/20 かつ LE 全展開）、安定板位置と greenband、レバー非 DN、着陸フラップ（speedbrake alert・landing config） | ATA27 p.36・729–740 |
| 出力 | FCC（ATA 22） | フラップ・安定板位置、speedbrake lever RVDT | ATA27 p.36・198 |
| 出力 | HYDIM（ATA 29） | 右 FCU→系統 1、左 FCU→系統 4 の ADP 用（TE 移動中・TE > 0） | ATA27 p.36、ATA-29 §4.2 |
| 出力 | 燃料 FSMC（ATA 28） | フラップ位置（xfeed 2・3） | ATA27 p.36、ATA-28 §4.3 |
| 出力 | エンジン FGI | フラップ非格納で approach idle | ATA27 p.36 |
| 出力 | stall warning・GPWS・PFD | LE/TE フラップ位置、スピードブレーキ位置 | ATA27 p.36・701（27-32）、FCOM p.53–54 |

- コードの現状：他モジュールは位置ではなく指令（`laminar/B747/cablecontrols/flap_ratio`、load relief 後のレバー比）を「フラップ位置」として使う（エンジン、燃料、防氷、FDR）。AFDS と飛行計器はレバー（`sim/cockpit2/controls/flap_ratio`）を使う。作り直しでは FCU の出力として「群ごとの実位置」「フラップ非格納」「離陸範囲」を出し、利用側を移す。

## 6. 実装上の注意

### 6.1 X-Plane 側の仕組み

- 舵面：`B747.19.xt.hydraulics_override.lua:1119` が毎フレーム `override_control_surfaces`=1 にし、舵角（`wing2l_ail1def`、`wing4l_ail2def`、`hstab1/2_elv1/2def`、`vstab2_rud1/2def`、`wing1/3*_spo*def`、`wing1/3*_fla*def`）とスラット比を自分で書く。`override_joystick_*` はコメントだけで使っていない（ARCHITECTURE.md の表と違う）。
- 指令の大半は `xtlua/controlObject` の JSON 対応表（`B747.19.xt.hydraulicsmodel.lua:563-702`）。XTLua 本体（xpmtdatarefs.cpp、2026-10-23 確認）の動作：入力を minin..maxin に切り詰めて線形変換し、出力に scale（`scaledref` があればその値）を掛ける。同じ dst への複数の対応は加算して範囲で切り詰める（順序依存）。Lua の書き込みより後に毎回上書きする。利点は Lua の 1 フレーム遅れが無いこと。欠点は非線形の表（programmer、spoiler の不感帯、RRC 曲線）を折れ線の和で書く必要があることと、切り詰めの規則の確認が要ること。
- X-Plane 本体の機能をまだ使っている部分：トリム（`sim/flight_controls/pitch_trim_*`・`aileron_trim_*`・`rudder_trim_*` と acf の時間）、接地時の自動スピードブレーキ（`speedbrake_ratio`=-0.5 と acf `_sbrk_on_td_EQ` 1）、speedbrake 1 の面（acf `_sbrk1_up_flit` 20、`_up_grnd` 45。プラグインは書かないので、スポイラー 6・7 の空力は X-Plane が出すと `推定`）、スラット（acf `_slat1/2_dn` と時間 0.1 s。プラグインの書き込みと競合しないか要確認）。
- ACF_DIFF §3.4・§3.5：`_ailnN_v1/_v2`（速度ロックアウト）、`_ailn1_rat2`、`_ailn/_elev_def_time`、`_*_max_full_def_KIAS`、舵面別の `_hyd0123` は override で迂回され、コードも読まない（`推定`、FCTL-22）。`_ailn_trim_time`・`_rudd_trim_time` は X-Plane のトリムコマンド経由で効く。`_speedbrake_ext_time` は speedbrake 1 の面に効く可能性がある。`_flap_extend_protect` がレバー（`flap_ratio`）を止めるかは要確認。
- `B747.19.xt.hydraulics_override.lua` の約 369–1104 行は AFDS（FD・PID・autotrim・YD）。操縦系統を作り直す前に分離する（ATA-29 §6.4 と同じ）。

### 6.2 表示・3D の制約

- フラップ表示（`747-400.acf:123890-124700` 付近）：group「Flaps」（`EICAS1_display_status`=1）はテープ 1 本（`flap_deployed_ratio`）とレバー位置の数字・線（`sim/cockpit2/controls/flap_ratio`、`flap/transition_status` 0＝緑・1＝magenta）。group「Flaps Disagree」（=2）は TE テープ 4 本（`flap_deployed_ratio1`＝左 OB、`2`＝左 IB、`3`＝右 IB、`4`＝右 OB）と magenta の数字・線だけ。テープ目盛は 0＝UP、1/6＝1、2/6＝5、3/6＝10、4/6＝20、5/6＝25、1＝30。LE の箱、amber、amber X、alternate の目盛、expanded での緑は無く、画像も無い。直すにはカスタム acf のパネル変更と画像追加（承認事項）。
- 舵面位置（`747-400.acf:129993-130152`）：`rudder_upr/lwr_pos`（±25° で振り切り）、`outer_spoilers[0/1]`、`spoilers[6/7]`、`l/r_elev_outer`、4 枚のエルロン（外側は +15/-25 の目盛）。
- 3D：安定板の指針は `sim/flightmodel2/controls/elevator_trim`（−1..1 → 0..15 units）、greenband は `laminar/B747/flt_ctrls/elevator_trim/mid/indicator` で 1 本の帯を平行移動、OFF フラグは `sim/operation/failures/rel_trim_elv`（`objects/747_cockpit/Cockpit_Pedestal1.obj:40888-40908`）。3 区画の点灯、V1 での消灯、電源喪失の OFF は 3D を変えないと出せない。ラダートリムは `sim/cockpit2/controls/rudder_trim`、エルロントリムは `sim/cockpit2/controls/aileron_trim` で動く。
- 3D の操作子（`ATTR_manip` を持つのは `747-400_cockpit.obj` だけ）：stab trim up/dn（capt・fo）、フラップレバー（`flap_ratio`）、スピードブレーキレバー、ALTN FLAPS 選択器と ARM、エルロントリム・ラダートリム（X-Plane コマンド）、YD スイッチはある。STAB TRIM cutout、ALTN STAB TRIM、FLT CONTROL HYD POWER の操作子は無い → 論理とコマンドだけ作る（3D は範囲外）。
- 保つ名前（INTERFACES.tsv）：`laminar/B747/flt_ctrls/` の `aileron_trim/switch_pos`、`alt_flaps/sel_dial_pos`、`elevator_trim/mid/indicator`、`flap/transition_status`、`flap_lever_detent`、`flaps`（[1..4]＝TE の角度）、`flaps/EICAS1_display_status`、`flaps/alt_flaps/sel_dial_up/dn`、`l/r_aileron_inner/outer`、`l/r_elev_inner/outer`、`outer_spoilers`、`parking_brake_ratio`、`rudder_lwr/upr_pos`、`rudder_trim/sel_dial_pos`、`speedbrake_lever`、`speedbrake_lever_detent`、`spoilers`、`stab_trim_up/dn_capt/fo`、`laminar/B747/gauges/indicators/flap_deployed_ratio`・`1-4`、`laminar/B747/button_switch/altn_flap`・`yaw_damper_upr/lwr`。値の意味（TE の角度は detent 0/1/5/10/20/25/30 に対し 0/0/5/10/20/22/30°、`B747.19.xt.hydraulicsmodel.lua:633-651`）も保つ。

### 6.3 簡略化してよいもの・いけないもの

- してよい：CMC・BITE・地上試験、PSM の内部、SRM・FCU の二重チャンネル（「有効」フラグと優先順位で十分）、位置トランスミッタと SPD、ジャム時の override、フィールの力（FFB が無ければ表示用の STATUS だけ）、アクチュエータの過熱・duty cycle、LE の 28 枚個別（群単位で十分）。
- してはいけない：フラップの順序と primary/secondary/alternate の切替（時間・閾値を含む）、非対称保護、load relief の表、LE の自動格納、lockout の表とヒステリシス、RRC の速度表と故障時の固定、stab trim の制限・速度・cutout・alternate・column cutout・AP との関係、スピードブレーキの表と自動展開/格納の条件、表示の規則（§4.4）と EICAS の条件、油圧・空気・電源への依存。
- X-Plane の制約：LE のスラット比は 2 本（group A・B）で両翼共通 → LE の左右非対称は表示だけで再現し、空力と 3D は対称のままにする（`推定` で許容）。TE は 4 枚別に書けるので非対称は空力でも再現できる。

## 7. 現状実装との比較（GAP 候補）

`B747.45.xt.fltCtrls.lua`・`B747.01.xt.manipulators.lua`・`B747.87.xt.warning.lua` は `plugins/xtlua/scripts/<モジュール>/`、`B747.19.xt.hydraulicsmodel.lua`・`B747.19.xt.hydraulics_override.lua`・`B747.90.xt.lighting.lua` は `plugins/xtlua_keysystems/scripts/<モジュール>/` 配下。

| ID | 種別 | 重要度 | 規模 | 内容 | 根拠 | 該当コード |
|---|---|---|---|---|---|---|
| FCTL-01 | 欠落 | 高 | L | FCU 論理が無い：TE・LE とも primary だけで secondary（電動）が無い。TE は油圧 > 900 psi を「指令が変わった瞬間」にしか見ず（移動中に油圧を失っても動き続け、priority valve 2000 psi でもない）、不一致 7 s/42 s・1400/1600 psi・非対称 6.2/3.4 %・逸走・moving away の保護が無い。LE は空気圧（ダクト圧）を見ない。FLAPS PRIMARY・FLAPS DRIVE は定義だけで立たない | FCOM p.953、ATA27 p.284・290・292・294・363・381・384 | `B747.19.xt.hydraulics_override.lua:214-227`、`:342-368`、`B747.87.xt.warning.lua:137-138` |
| FCTL-02 | 欠落 | 高 | M | ALTN FLAPS：ARM スイッチは FLAPS CONTROL を出すだけで、選択器（RET/OFF/EXT）は位置を変えるだけ。レバーは不作動にならず、電動駆動・25 制限・LE 格納 interlock も無い。FLAPS CONTROL のもう一つの条件は X-Plane の `rel_flap_act` 故障だが、舵面はプラグインが書くのでその故障でもフラップは動く（`推定`） | FCOM p.935・954・957、ATA27 p.296–302・390 | `B747.45.xt.fltCtrls.lua:218-227`、`:1145-1153`、`B747.01.xt.manipulators.lua:558-560` |
| FCTL-03 | 欠落 | 高 | L | 安定板トリム系統：手動スイッチは X-Plane の `pitch_trim_up/down` を handler の各 phase で `once()` するだけ（速度は X-Plane 任せ＝acf `_elev_trim_time` 25 s で、対気速度に依存しない。実速度は要確認。`simDR_electric_trim` は未定義の global への代入）。電気トリム制限（1.8/11.6、0.8、13.5）が無く 0–15 units 全域。系統 2/3 依存と半速、cutout（ON/AUTO/CUTOUT）と自動遮断、ALTN トリム（コマンドも無い）、column cutout、手動トリムでの AP 解除（1 台）/無効（複数）が無い。>STAB TRIM 2・3、STAB TRIM UNSCHD は立たない。AP の autotrim は `elevator_trim` を直接書く | FCOM p.928–929・944–946・958、ATA27 p.450–458・476・483・488・490・520 | `B747.45.xt.fltCtrls.lua:233-289`、`:486-487`、`B747.19.xt.hydraulics_override.lua:925-957`、`B747.19.xt.hydraulicsmodel.lua:596` |
| FCTL-04 | バグ | 高 | S | ラダートリムが舵面に入らない見込み：ラダー指令は `total_heading_ratio`×32×ratio＋YD だけで `rudder_trim` を足していない（エルロンは `aileron_trim` を足している）。X-Plane の `total_heading_ratio` がトリムを含まないことを要確認 | FCOM p.949、ATA27 p.612–614 | `B747.19.xt.hydraulicsmodel.lua:566-573`、`:602` |
| FCTL-05 | 挙動の誤り | 中 | S | lockout：機長 IAS 232–238 kt の直線補間（ヒステリシスの保持でない）。Mach（0.51/0.53）、LE group A 展開での unlock、SRM/ADC/FCU 故障時の扱い（空中 default unlock）が無い。フラップを出したまま 238 kt 超で外側がロックされ、高高度の低 IAS で unlock する。AILERON LOCKOUT は立たない | FCOM p.947・957、ATA27 p.106–110、FCOM p.53 | `B747.19.xt.hydraulics_override.lua:1142-1143`、`B747.19.xt.hydraulicsmodel.lua:607-611` |
| FCTL-06 | 挙動の誤り | 中 | S | RRC：機長 IAS 150→450 kt で 1.0→0.156 の直線。実機の曲線より中速で舵角が大きい（250 kt で約 23° 対 約 15°、`推定`）。上下共通の 1 値、ADC 喪失時の 329/209 kt 固定・autoland 0 kt・故障位置保持が無い。YD 入力にも ratio を掛けている（実機は下流で加算、`推定`）。RUD RATIO SNGL/DUAL は立たない | FCOM p.949・957、ATA27 p.634–648・656 | `B747.19.xt.hydraulics_override.lua:1140`、`B747.19.xt.hydraulicsmodel.lua:566-570` |
| FCTL-07 | 挙動の誤り | 中 | M | 自動スピードブレーキ：着陸展開は X-Plane 本体（ARM＝ratio -0.5）に任せ、レバーを追従させるだけ。TL1/TL3 アイドル条件、地上判定（系統 1/4 > 1600 psi と脚 tilt）、DC bus 1 依存が無い。RTO は「どれかのエンジンが reverse」でレバー UP（実機はリバースレバー 2 か 4 と TL1/TL3 アイドル）。ゴーアラウンドの格納（TL1 か TL3）はコードに無い（X-Plane 任せか要確認）。SPEEDBRAKE AUTO は立たない | FCOM p.933・951–952、ATA27 p.172–184 | `B747.45.xt.fltCtrls.lua:654-708`、`:852-872`、`B747.45.fltCtrls.lua:97-155`（init） |
| FCTL-08 | 挙動の誤り | 中 | S | >SPEEDBRAKES EXT：`num_thrust_levers_open` が全レバー共通の `throttle_jet_rev_ratio_all` から作られ最大 1、演算子の結合で推力条件がフラップ条件にしか掛からない。「推力レバー 2 本以上」が欠け、着陸フラップ条件は RA > 15 ft でなく `onground` で判定。さらに空中の「スピードブレーキ＋推力レバー前方」を CONFIG SPOILERS（赤の warning）で出している | FCOM p.958、ATA27 p.740 | `B747.45.xt.fltCtrls.lua:1155-1168`、`:957-965`、`:1102-1111` |
| FCTL-09 | 挙動の誤り | 中 | S | 横操縦の対応：エルロンはホイールに比例（実機は約 45° で全舵角の曲線）、スポイラーは 0 から比例（実機は 8–14° の不感帯）。スピードブレーキ展開中に下げ側の翼のスポイラーが横操縦で下がらない（上げ側の対応しか無い） | FCOM p.947、ATA27 p.59 図・p.88・150・206 | `B747.19.xt.hydraulicsmodel.lua:600-629` |
| FCTL-10 | 挙動の誤り | 中 | M | greenband：FMC trim ±2.25 units の帯（CONFIG STAB）と、FMC trim に応じて平行移動する 1 本の帯。実機は固定の 3 帯（3.35–8.15／3.35–10.15／1.35–8.15）を MAWEA が選び、V1 で消灯。前脚オレオ圧スイッチとの比較（>STAB GREENBAND）が無い。OFF フラグは X-Plane のトリム故障で、指示器の電源でない | FCOM p.944・958、ATA27 p.502・508–514・521 | `B747.45.xt.fltCtrls.lua:912-921`、`:1113-1143` |
| FCTL-11 | 挙動の誤り | 低 | S | normal 表示：テープにレバー由来の 0–0.15 が足され、レバーを 1 にした瞬間に「1」を示す（group A の移動中・展開を反映しない）。テープは 4 枚の最大値（最も速い面。実機は最も遅い TE 群）。expanded への切替条件は TE の不一致だけ | FCOM p.936・954、ATA27 p.318、p.399 図 | `B747.19.xt.hydraulicsmodel.lua:655-679`、`B747.45.xt.fltCtrls.lua:818`、`:880-906` |
| FCTL-12 | 欠落 | 中 | M | expanded/alternate 表示：パネルに LE 6 箱、amber、amber X、alternate の index mark、expanded での緑が無い（画像も無い）。カスタム acf のパネル変更が必要（承認事項） | FCOM p.937–938、ATA27 p.320–322・398–400 | `747-400.acf:123890-124290`（パネル） |
| FCTL-13 | 挙動の誤り | 低 | S | LE の順序：group A の格納条件が IB TE（実機は OB TE）。リバースでの自動格納が「レバー > 0.5 とどれか 1 基の reverse」（実機は地上・空気圧モードでエンジン 1&4 か 2&3）、再展開がスピードブレーキを下げるまで遅れる | FCOM p.954–955、ATA27 p.381–382 | `B747.19.xt.hydraulics_override.lua:342-368` |
| FCTL-14 | 挙動の誤り | 低 | S | load relief：レバー 30 で 20→25 に戻る速度が 203 kt（実機 195 kt）。モード条件（油圧モードのときだけ）が無い。FLAP LOAD RELIEF（STATUS）が無い | FCOM p.954、ATA27 p.288、p.289 図 | `B747.45.xt.fltCtrls.lua:826-843` |
| FCTL-15 | 欠落 | 中 | S | YD の INOP 灯と >YAW DAMPER：条件はスイッチ・IRS 1 台以上 NAV・バッテリーだけ。油圧（上 3、下 2）、FCE 電源（上は左 PSM＝standby bus、下は PSM 1R＝AC bus 1）、ADC 有効、アクチュエータ故障が無い。制御則は ATA 22 | FCOM p.931・949–950・958、ATA27 p.22–24・44 | `B747.45.xt.fltCtrls.lua:714-744`、`:1170-1184`、`B747.90.xt.lighting.lua:1328-1330` |
| FCTL-16 | 欠落 | 低 | M | speed stability trim（SRM、Vc ≤ 220 kt、空中 20 s 後、半速）が無い。STAB SPEED TRIM も無い | FCOM p.945、ATA27 p.486 | なし |
| FCTL-17 | 挙動の誤り | 低 | S | エルロントリム：`aileron_trim` をロール入力にそのまま加算。権限は acf `_roll_acft_lf/rt_trim_rat` 0.05（全舵角の 5 % と `推定`）で、実機の 6 units＝ホイール 47° より大幅に小さい見込み。速度は acf `_ailn_trim_time`（カスタム 12 s／純正 10 s）。要確認 | FCOM p.947–948、ATA27 p.76 | `B747.19.xt.hydraulicsmodel.lua:602`、`B747.45.xt.fltCtrls.lua:481-482` |
| FCTL-18 | 挙動の誤り | 低 | S | エレベーター舵角が 22° 上・17° 下（acf も同じ）。E&M は 25°/15°。外側の中立 2° 下げも無い | ATA27 p.548・552 | `B747.19.xt.hydraulicsmodel.lua:580-595`、`B747.19.xt.hydraulics_override.lua:123-126` |
| FCTL-19 | 挙動の誤り | 低 | S | 舵面位置のスポイラー：`outer_spoilers` が 1–5／8–12 の平均。実機は左＝スポイラー 4、右＝スポイラー 12（右には空中のスピードブレーキが出ない） | FCOM p.939・951 | `B747.19.xt.hydraulics_override.lua:149-159` |
| FCTL-20 | 欠落 | 低 | M | FLT CONTROL HYD POWER：スイッチ・弁・舵面の遮断が無く、VALVE CLOSED 灯は常に 0、>FLT CONT VLVS は立たない。HYD-22 と同じ項目（実装は 1 か所） | FCOM p.940・957、ATA27 p.10–14 | `B747.90.xt.lighting.lua:1381-1389`、`B747.87.xt.warning.lua:329` |
| FCTL-21 | 欠落 | 低 | M | 故障で出るメッセージと STATUS：AILERON LOCKOUT、RUD RATIO、SPEEDBRAKE AUTO などは定義だけ。§3.3 末尾の STATUS メッセージ（ELEVATOR FEEL を含む）は無い（STATUS ページ自体が ATA 31 の課題）。この FCOM に無い `>LE FLAPS DIS` が定義されている | FCOM p.957–958、ATA27 §3.3 の図 | `B747.87.xt.warning.lua:189`、`:427`、`:447-448`、`:458-461` |
| FCTL-22 | 挙動の誤り | 低 | S | ACF_DIFF §3.4・§3.5：舵面系の値（`_ailnN_v1/_v2`、`_ailn1_rat2`、`_def_time`、`_max_full_def_KIAS`、`_hyd0123`）は override で迂回されコードも読まない（`推定`）。トリム時間は効く。`_speedbrake_ext_time` と `_sbrk1_*` は X-Plane の speedbrake 面、`_flap_extend_protect` はレバーに効く可能性。要確認、不要なら純正値に戻すか 0 | ACF_DIFF §3.4–3.5 | `B747.19.xt.hydraulics_override.lua:1119` |
| FCTL-23 | バグ | 低 | S | フラップのスナップ用タイマーの停止条件が逆（予定されていないときに stop）。`B747_flap_move_to_slot` のコメントの detent 名がずれている | — | `B747.45.xt.fltCtrls.lua:804-809`、`:747-766` |
| FCTL-24 | 挙動の誤り | 低 | S | スポイラー 6・7：プラグインは X-Plane の speedbrake 面を書かず、空力は X-Plane が `speedbrake_ratio` から比例で出す見込み（実機は 0/20/45 の 3 位置、系統 4 依存）。3D・表示（step）と空力（比例）が食い違う。地上で 5・8 が 45° まで出るかは controlObject の切り詰め次第（要確認） | ATA27 p.165 図・p.188–190 | `B747.19.xt.hydraulicsmodel.lua:682-701`、`B747.45.fltCtrls.lua:113`、`:144`（init、レバー→`speedbrake_ratio`） |
| FCTL-25 | 欠落 | 中 | M | 電源依存が無い：FCE（PSM）、input actuator（AC 1）、TE/LE の電動・alternate モーター（AC 1/3/4）、auto speedbrake（DC 1）、RRC（AC 2/3）、lever lock、trim 表示。standby だけでの amber X や「フラップ 1 で FLAPS DRIVE」が出ない。ATA 24 の作り直しが前提 | §2.3、FCOM p.955、FCTM p.283 | なし |

- 件数：高 4（FCTL-01, 02, 03, 04）、中 9（FCTL-05, 06, 07, 08, 09, 10, 12, 15, 25）、低 12（FCTL-11, 13, 14, 16, 17, 18, 19, 20, 21, 22, 23, 24）。合計 25。
- 油圧の組の誤り（HYD-06：上ラダー、L INBD AIL、R OUTBD AIL）とスポイラー 8 の消費（HYD-07）は ATA-29 の項目。ここでは重複させない。
- `B747.45.fltCtrls.lua`（init）は `plugins/xtlua/init/scripts/B747.45.fltCtrls/` 配下。
- 正しく実装されている点：エルロン（内側 ±20°、外側 25/15°）とラダー（最大 32°、高速 5°）の端点（`B747.19.xt.hydraulics_override.lua:116-135`、`B747.19.xt.hydraulicsmodel.lua:569-570・604-611`）。スポイラーの番号・flight/ground の区別と空中・地上の角度、スピードブレーキの表は p.165 の図に概ね一致（`B747.19.xt.hydraulicsmodel.lua:682-701`）。空中の FLIGHT DETENT ストップ（`B747.45.xt.fltCtrls.lua:637-646`）、SPEEDBRAKE ARMED memo。フラップの detent と TE の IB=系統 1・OB=系統 4、LE group A＝1・group B＝5、LE の約 9 s（8.5 s）、load relief の主な速度と >FLAP RELIEF、表示の 10 s 消去と magenta/緑。AP autotrim の速度切替 220/230 kt。

## 8. 作り直しか部分修正か

**推奨：ロジック（FCU・SRM・スピードブレーキ制御・表示用出力）は新しいモジュールとして作り直す。舵面への書き出しは controlObject の対応表を残して整理する。**

- 理由：
  - 主要機能が「無い」。secondary/alternate フラップ、FCU の保護、stab trim の制限・cutout・alternate・AP 連携、自動スピードブレーキの条件、greenband の 3 帯は既存コードに土台が無く、部分修正でも新規に書くことになる。
  - 処理が 2 つのプラグインの 3 ファイル（`B747.45.xt.fltCtrls.lua`、`B747.19.xt.hydraulicsmodel.lua`、`B747.19.xt.hydraulics_override.lua`）に散り、AFDS のコードと混ざっている。状態（モード、故障、タイマー）を持つ論理を 1 か所に集めないと、表示・EICAS・他系統への出力の整合が取れない。
  - 論理が資料に具体的に書いてある（閾値・タイマー・表）。状態機械として素直に組める。
  - 一方、controlObject による舵面の書き出しは遅れが無く、スポイラー表・フラップ角の表は概ね正しい。これは残し、Lua 側は scaledref（lockout の状態、RRC の比、スポイラーの mixer 限界など）と目標値を出す形にする。同じ dst を Lua と controlObject の両方から書かない。
- 進め方の案：
  1. すぐ直せる小物：FCTL-04（ラダートリムの加算。確認後）、FCTL-08、FCTL-14、FCTL-19、FCTL-23。
  2. AFDS 部分（`B747.19.xt.hydraulics_override.lua` の約 369–1104 行）を ATA 22 担当と分離。
  3. 新モジュール：FCU（フラップの指令・モード・保護・位置出力・表示状態）、SRM（stab trim・lockout・RRC）、スピードブレーキ制御（レバー・自動展開/格納・SPEEDBRAKE AUTO）、表示/EICAS 出力。入力は油圧（ATA 29 の「動力あり」）、ダクト圧（ATA 36）、bus 状態（ATA 24）、空地・脚（ATA 32）、エアデータ。
  4. X-Plane 本体任せの部分（自動スピードブレーキ、speedbrake 1、スラット、トリム）を一つずつプラグイン側に移し、acf の該当値は効かない状態に固定する。
  5. 表示の拡張（FCTL-12）と 3D の不足（cutout、ALTN trim、FLT CONT HYD POWER の操作子）は承認・範囲の判断を待つ。

## 9. 未確認事項

- X-Plane（シムで確認）：
  - `total_heading_ratio` にラダートリムが含まれるか（FCTL-04）。
  - `override_control_surfaces`=1 でも speedbrake 1 の面とスラットを X-Plane が動かすか、`_speedbrake_ext_time`・`_slat_ext*_time` が効くか。
  - X-Plane の自動スピードブレーキの条件（接地の判定、推力レバー、ゴーアラウンドでの格納）。
  - `_flap_extend_protect`=1（カスタム）がレバーや面を止めるか。
  - controlObject の加算と切り詰めの規則（地上のスポイラー 5・8 が 45° になるか、スポイラーの mixer を折れ線で書けるか）。
  - `aileron_trim` の範囲（±0.05 か）とトリム指示器の units の対応。`pitch_trim_up/down` を毎フレーム `once()` したときの実速度。
  - 安定板の units と角度の関係（コードは −1..1→±15°、1 unit＝2°）。実機の関係は `資料に記載なし`。
- 資料に無いもの（`推定` で決めて試験する）：TE の primary/secondary の所要時間、lockout アクチュエータの移動時間、RRC の延長量と舵角の関係、greenband の選択表、前脚オレオ圧スイッチの設定圧、TRA 40° と X-Plane のスロットル比の対応、LE の midspan 箱と PDU 2・3 の対応、CLCP の油圧系統の組。
- 資料の食い違い：エレベーターの可動範囲（E&M 25/15、コード・acf 22/17）、>SPEEDBRAKES EXT の脚条件（ATA27 p.205 だけにある）。
- 3D：操作子（`ATTR_manip`）を持つ obj は `747-400_cockpit.obj` だけで、STAB TRIM cutout・ALTN STAB TRIM・FLT CONTROL HYD POWER は無い（全 obj を検索）。スイッチの外形が 3D にあるか（操作子だけ足せるか）は未確認。
