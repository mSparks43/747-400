# Autothrottle・FMC 推力管理（ATA 34-61 thrust management）調査メモ

2026-10-23 調査。対象コードは `overhaul`（041c9ffa）。出典の書き方は REFERENCE_INDEX.md に従う。747-400 の autothrottle（A/T）は AFDS（ATA 22）ではなく FMC の thrust management function（ATA 34-61）に属する (ATA34_2 p.640 (34-61))。

## 1. 概要

- 対象: A/T の ARM・作動・解除、A/T モード（THR、THR REF、SPD、IDLE、HOLD、TEST）と飛行段階ごとの遷移、thrust lever servo、推力制限モード（TO、TO 1/2、D-TO、D-TO 1/2、CLB、CLB 1/2、CRZ、CON、GA）とその自動切替、assumed temperature と derate、EICAS の reference / target 表示、A/T の EICAS メッセージ、関係する CDU ページ（THRUST LIM、TAKEOFF REF、PERF FACTORS）。
- 対象外: EEC のエンジン制御（TRA→EPR/N1 指令、idle 選択、ALTN、max EPR の EEC 側計算）と AFDS の pitch/roll モード。境界は §5 に書く。ただし FMC の推力制限計算（現コードでは EEC モジュール内にある）は本メモの範囲とする。
- 使った資料:
  - ATA34_2 p.427–736 のうち、p.430・433・440・450–457・462・470–478・484・490–496・501–502・530–544・597・609–616・620–624・629–632・638–679・688–702。図は p.473・537・541・621・639–675 の奇数ページを描画して確認した（p.650・656 は NOTES）。PDF ページ = 34-61 の Page 番号 + 426。
  - LH3460 p.4–116（内容は ATA34_2 とほぼ同一。差分は p.60（S7/S9 が disconnect、S8/S10 が reset）、p.96（fixed derate 2 種あり）、p.116）。
  - FCOM 4.10 p.641–657、4.20 p.659–675、4.30 p.677、7.10 p.829–837、7.13 p.859–865、7.20 p.871・876–877、6.20 p.800、11.10 p.1215、11.31 p.1253–1269、11.32 p.1271–1275、11.40 p.1310–1321、11.41 p.1325–1342、11.42 p.1350、11.60 p.1429–1435、15.20 p.1596–1600、NP p.97・129、SP.4 p.172–175、SP.16 p.213–218、PI p.261–263・283・300・316・322・358–360・379。
  - FCTM p.43 (1.13)、63 (1.33)、92–106 (3.4–3.18)、112 (3.24)、119 (3.31)、123–137 (4.1–4.15)、157–209 (5.x)、238 (6.x)、301 (8.23)。
  - 補助: FMSPG p.30–33・100–111・266–267、ATA22 p.210・280・284・294・338。
- 型式: ATA34_2 は EICAS 図が N1 表示で、EEC ALTN の作動条件が GE（570）の FCOM 記述と一致するので CF6 機の資料と推定。FCOM の 109 = PW 旅客機、405 = PW 改造貨物機、570 = GE 貨物機。RR は資料なし（PW と同じ EPR 系として扱うのは推定）。

## 2. 構成

| 要素 | 内容 | 根拠 |
|---|---|---|
| MCP | A/T ARM スイッチ（ARM/OFF）、THR・SPD スイッチ（ライト付き）。A/T ARM は 28V の analog discrete として各 FMC へ直接入る | FCOM p.641 (4.10.3)、ATA34_2 p.470 (34-61)、ATA22 p.210 (22-10) |
| TO/GA スイッチ | thrust lever 2・3（S1–S6）。FMC は自前の GA 入力でなく AFDS の voted TO/GA status を使う | ATA34_2 p.472、LH3460 p.62 (Page 60) |
| A/T disconnect スイッチ | thrust lever 1・4。S7/S9 = disconnect、S8/S10 = caution reset | LH3460 p.60 (Page 58)、ATA34_2 p.473 図 |
| A/T servomotor generator | control stand 下。FMC ごとの 2 巻線、tach は 1 個で両 FMC へ。駆動 0–10°/s、115V AC excitation、28V DC から作る AC 駆動信号 | ATA34_2 p.472・490 (34-61) |
| FMC L/R | thrust management function = autothrottle（engage logic、control laws、mode logic、engine trim）+ thrust limit calculation。master FMC だけが A/T 指令・trim・MCP データを出す | ATA34_2 p.640–641、p.496、LH3460 p.90 (Page 88) |
| FMC master relay | A/T ARM 電圧は master switch と master relay の両方を通る。不一致なら ARM できない | ATA34_2 p.452 (34-61) |
| EIU | 実 N1/EPR を FMC へ返す。FMC の A/T disconnect discrete を受けて EICAS に出す | ATA34_2 p.462、p.638 |
| EEC | TRA で推力を決める。FMC から EPR/N1 trim 指令と bleed correction を受ける | ATA34_2 p.474、p.638 |

電源:

| 対象 | 電源 | 根拠 |
|---|---|---|
| FMC L / FMC R | 115V AC APU standby bus / F/O transfer bus | ATA34_2 p.450 (34-61)、FCOM p.800 (6.20.6) |
| servo tach excitation | F/O transfer bus | ATA34_2 p.450 |
| servo motor excitation | F/O transfer bus（master FMC 経由） | ATA34_2 p.450 |
| A/T drive power | 28V DC bus 1・bus 2 | ATA34_2 p.450、LH3460 p.22 (Page 20) |
| FMC 警報回路 | 28V DC battery bus | ATA34_2 p.450 |
| FMC master relay | 28V DC bus 1（R 位置で励磁） | ATA34_2 p.452 |

## 3. 操作と表示

### 3.1 MCP

- A/T ARM スイッチ (FCOM p.641 (4.10.3))
  - ARM: A/T を mode 選択可能にする（作動はしない）。VNAV・FLCH・TO/GA を押すと作動。SPD は pitch mode が ALT・V/S・G/S のとき作動。FMA が空白で pitch が VNAV xxx か FLCH SPD のときは OFF→ARM で作動。2 発以上停止で解除。
  - OFF: A/T 解除、作動禁止、engine trim 停止。
- THR スイッチ: 離陸後 400 ft から着陸まで有効 (FCOM p.641–642 (4.10.3–4))。
  - 推力制限機能（ライト消灯のまま）: 離陸後 VNAV か FLCH 選択時は armed climb limit（エンジン停止時 CON）へ、go-around 後は CLB（エンジン停止か CON 選択時は CON）へ。フラップ着陸位置か pitch G/S の間は GA のまま。
  - A/T mode 機能（ライト点灯）: limit が CLB/CLB1/CLB2/CRZ/CON で pitch が ALT か V/S、または limit が GA で pitch が G/S・FLARE（あるいは ALT/V/S かつフラップ着陸位置）のとき THR REF にする。
  - E&M は THR REF の条件に「GA limit でない」を挙げる (ATA34_2 p.672)。FCOM と食い違うので FCOM に従う。
- SPD スイッチ: 400 ft 以上で有効。押すと SPD（ライト点灯）。VNAV xxx、FLCH SPD、TO/GA pitch では無効。V/S では A/T の速度保護なし (FCOM p.642 (4.10.4)、p.663 (4.20.5))。
- IAS/MACH window は MCP 速度。VNAV 中は空白で FMC 速度（speed intervention で開く）(FCOM p.643 (4.10.5)、ATA34_2 p.623)。

### 3.2 thrust lever 上のスイッチ (FCOM p.656–657 (4.10.18–19))

- TO/GA（地上）: 50 kt 未満かつフラップ UP 以外で押すと THRUST LIM で選んだ limit で THR REF。50 kt までに押さなければ 400 ft まで A/T 作動不可。GPS 更新が無ければ FMC 位置を滑走路端（POS SHIFT 点）に更新。
- TO/GA（離陸後、takeoff limit 表示中）: takeoff derate を外し、HOLD 中の A/T を THR REF にする。50–400 ft は TO/GA roll、400 ft 以上は roll・pitch とも TO/GA。
- TO/GA（進入中、フラップ UP 以外か G/S 捕捉）: 1 回目 THR（GA limit 表示、2000 fpm）、2 回目 THR REF（full GA）。A/P・F/D なしでも FD・THR・TO/GA・TO/GA を表示 (FCOM p.657)。E&M は A/P・F/D off なら THR REF とする (ATA34_2 p.658)。FCOM に従う。
- A/T disconnect: 1 回目で A/T 解除、master caution、>AUTOTHROT DISC。自動解除後に押すと caution とメッセージを reset。2 回目で reset。A/T は ARM のまま (FCOM p.657 (4.10.19))。

### 3.3 CDU

- THRUST LIM（地上・takeoff limit 中）(FCOM p.1313–1316 (11.40.37–40)、ATA34_2 p.535–537)
  - 1L SEL: assumed temperature。初期空白。0–99°C / 32–210°F（F を付けると OAT も °F）。25% を超える減少になる温度は 25% になる温度に置換。V speed 選択後の入力で TAKEOFF SPEEDS DELETED。1C OAT。
  - 1R: 選択中の takeoff mode と limit（PW: EPR、GE: N1、PW の ALTN 時は N1）。温度で limit が下がると見出しに D。
  - 2L–4L: TO / TO 1 / TO 2（<SEL>）。405・570 では TO 1→CLB 1、TO 2→CLB 2 を arm。新しい rating の選択で TAKEOFF SPEEDS DELETED。derate 選択で 1L の温度は消える (FMSPG p.102 (3.2-42))。
  - 2R–4R: CLB / CLB 1 / CLB 2（<ARM>、climb 移行で <SEL>）。押すと自動選択を上書き。
  - 例示値: PW（109・405）TO 1 −8%、TO 2 −20%。GE（570）−5%、−15% (FCOM p.1313–1314)。
- THRUST LIM（空中）: 2L GA、3L CON、4L CRZ、2R–4R CLB/CLB 1/CLB 2、見出しに選択モードと limit（例 CLB 1 EPR 1.39）(FCOM p.1338–1340 (11.41.14–16)、ATA34_2 p.536)。takeoff mode からの thrust reduction で自動表示 (FMSPG p.103 (3.2-43))。
- TAKEOFF REF 3L THR REDUCTION: フラップ 5（入力 5）か 400–9999 ft HAA（滑走路標高を加えて MSL で判定）。3C に armed climb mode（例 FLAPS 5 CLB 1）。初期値は小文字の既定値 (FCOM p.1317–1319 (11.40.41–43)、ATA34_2 p.539)。
- PERF FACTORS（整備）: TO 1/TO 2 の derate %（0–30）、THR/CRZ（巡航の既定 limit を CLB か CRZ。既定 CLB）、THR RED（既定の thrust reduction）、ACCEL HT (ATA34_2 p.678–679、FMSPG p.266–267 (7-6/7))。

### 3.4 PFD FMA（A/T 欄）

- 表示（緑）: THR、THR REF、HOLD、IDLE、SPD。モード変化で 10 s 緑枠 (FCOM p.653 (4.10.15))。TEST は FMC 試験中 (ATA34_2 p.654)。
- 空白: A/T モードなし、または ARM OFF (ATA34_2 p.654)。master FMC 故障でも空白 (ATA34_2 p.630)。表示データは master FMC から (ATA34_2 p.502)。

### 3.5 EICAS（primary engine display）

| 表示 | 内容 | 根拠 |
|---|---|---|
| TAT | 白。master FMC が一次ソース、無効なら EIU が ADC を選ぶ | FCOM p.831 (7.10.3)、ATA34_2 p.651 |
| thrust reference mode | 緑。TO、TO 1、TO 2、D-TO、D-TO 1、D-TO 2、CLB、CLB 1、CLB 2、CON、CRZ、GA | FCOM p.831 |
| assumed temperature | 緑、°C（例 D-TO 1 +38C） | FCOM p.831 |
| reference EPR/N1（数字） | 緑。FMC の reference thrust（limit） | FCOM p.834 (7.10.6)、ATA34_2 p.653 図 |
| reference indicator（カーソル） | 緑 = reference、マゼンタ = FMC の target | FCOM p.834 |
| max EPR / max N1 線 | 琥珀（PW の max EPR 無効時は白）。どのモード・derate でも下げない。EEC は副ソース | FCOM p.833 (7.10.5)、ATA34_2 p.642・651 |
| command EPR/N1 | 白。lever 位置の指令（EEC 側） | FCOM p.834–835 |
| reverse 時 | PW: reference EPR 非表示。GE: command N1・reference N1 非表示 | FCOM p.832 (7.10.4) |

- マゼンタ target の条件: VNAV climb 中、VNAV idle descent かつ anti-ice ON、A/T ARM OFF のとき（手動推力の目安）。VNAV 中の他の段階は緑 (ATA34_2 p.652、LH3460 p.96)。A/T を切った乱気流巡航では FMC の cruise target を EICAS に表示 (FCOM p.215 (SP.16.15)、ATA34_2 p.612)。

### 3.6 EICAS メッセージと CDU メッセージ

| メッセージ | 種別 | 条件 | 根拠 |
|---|---|---|---|
| >AUTOTHROT DISC | caution、beeper | A/T が engage→off（手動・自動）。reverse thrust 選択による解除ではメッセージ・音とも出さない。A/T 再作動または disconnect スイッチで reset。着陸時の caution 抑止の例外（抑止されない） | FCOM p.677 (4.30.1)、p.657、p.1600 (15.20.54)、ATA34_2 p.644–645 |
| FMC LEFT / FMC RIGHT | advisory | FMC 故障（両方故障で A/T 使用不可） | FCOM p.1429 (11.60.1)、p.1275 (11.32.5) |
| >FMC MESSAGE | advisory | 優先度の高い FMC メッセージ（下の CDU メッセージ）がある | FCOM p.1429 |
| THRUST REQUIRED（CDU） | FMC alert | VNAV、A/T 解除中、path と速度維持に推力不足 | FCOM p.1434 (11.60.6)、p.1259 |
| DRAG REQUIRED（CDU） | FMC alert | VNAV で抗力が必要、または A/T 解除中で推力過大 | FCOM p.1431 (11.60.3) |
| TAKEOFF SPEEDS DELETED（CDU） | FMC alert | rating・assumed temp・フラップ等の変更で V speed 無効 | FCOM p.1435 (11.60.7)、p.1314–1315 |

## 4. 内部ロジック

### 4.1 engage logic と disconnect (ATA34_2 p.644–645 図、p.640)

- servo excitation（relay R1）の条件 = 次のすべて AND かつ reverse thrust でない、かつ throttle hold でない:
  - input sensors valid、FMC power valid、A/T ARM ON、A/T DISCONNECT（スイッチ）でない、flare retard A/T disconnect でない、3 発以上運転中、FMC self-test valid、A/T servo monitor valid、EEC の ALTN が 1–3 台でない、master FMC。
- throttle hold（excitation のみ切る。A/T は解除しない）= FLCH の pilot override、または TO で CAS >65 kt、または VNAV idle descent。
- A/T DISCONNECT latch: engage 条件が真→偽になったパルスで set し EIU へ出す（=EICAS）。reset は A/T 再 engage か disconnect スイッチ 2 回目。地上で reverse を引いた解除ではメッセージを出さない (ATA34_2 p.644)。
- servo loop monitor: 指令と tach が大きく食い違うと excitation を切る（R2）(ATA34_2 p.644)。閾値は資料に記載なし。
- 解除と再作動 (FCOM p.666 (4.20.8)、p.877 (7.20.7)、p.1215 (11.10.9))
  - ARM OFF、disconnect スイッチ、作動中モードの故障、reverse lever を reverse idle まで上げる → 解除。
  - FMC 両方故障、2 発以上停止 → 解除し再作動不可。FMC master スイッチ切替 → 解除、再作動可。
  - EEC が 1 台でも ALTN へ移ると解除。再作動: GE（570）は全 EEC を手動で ALTN にした後、PW（109・405）は全 EEC が NORM に戻った後。E&M の engage 条件（1–3 台 ALTN で不可）は GE の記述と一致。
- 着陸後: reverse lever を下げて 10 s 後からフラップ UP まで A/T は armed。TO/GA で THR REF (FCOM p.671 (4.20.13))。TO/GA スイッチは RA 5 ft 通過 2 s 後に抑止、上昇で 5 ft 通過 3 s 後に復帰 (FCOM p.673)。

### 4.2 モードの定義 (FCOM p.662–663 (4.20.4–5)、ATA34_2 p.646–648・654)

| モード | 制御 | 備考 |
|---|---|---|
| THR | V/S を制御する thrust（FLCH: 125 s で MCP 高度に達する V/S、GA 1 回目: 2000 fpm）。V/S が足りなければ増やすが、多すぎても減らさない。thrust limit で頭打ち | ATA34_2 p.646–647、p.670 |
| THR REF | reference thrust limit に合わせる。ただし実体は limit speed（Vmo/Mmo、フラップ placard）を thrust で制御し、thrust limit で頭打ち | ATA34_2 p.672、FCOM p.662 |
| SPD | MCP 速度または FMC 速度（TAS に換算して誤差を作る。Mach 保持も可）。thrust limit・speed limit・flap 速度保護あり。V/S pitch では速度保護なし | ATA34_2 p.646・668、FCOM p.663 |
| IDLE | lever を idle へ動かす間。VNAV idle、FLCH idle、flare retard。続いて HOLD | FCOM p.662、ATA34_2 p.654 |
| HOLD | servo 励磁を切る。パイロットが lever を手で動かせる。A/T は再配置しない | FCOM p.662・666 |
| TEST | FMC の試験中 | ATA34_2 p.654 |

### 4.3 飛行段階ごとのモード遷移

| 段階 | 遷移 | 根拠 |
|---|---|---|
| 離陸 | 条件（ARM、地上、フラップ UP 以外、limit = TO 系、TO/GA、CAS <50 kt）で THR REF → lever が TO limit へ（servo excitation が切れることを確かめてから）。65 kt で HOLD。VNAV が 400 ft で engage するか別の A/T モードを選ぶまで HOLD。20 kt 以上の向かい風では最終調整前に HOLD になりうる | ATA34_2 p.660–661、FCOM p.667 (4.20.9)、FCTM p.94 (3.6) |
| 離陸 RTO | HOLD 前に lever を戻すと離した瞬間に TO 推力へ戻る。HOLD 後は idle のまま | FCTM p.106 (3.18) |
| 離陸後 TO/GA | takeoff limit 表示中なら derate（assumed temp を含む）を外し THR REF で最大推力 | FCOM p.656・667、FCTM p.94・119 (3.31)、ATA34_2 p.661 図 |
| 400 ft VNAV | THR REF（armed climb limit）。thrust reduction 点で limit が CLB 系に変わりマゼンタ target | FCOM p.667、p.1255 (11.31.21)、ATA34_2 p.662–663 |
| FLCH 上昇・降下 | THR。降下で idle が要れば IDLE → HOLD。lever が後方 stop に達するか 8° override で HOLD | ATA34_2 p.670、FCOM p.173 (SP.4.3)、ATA22 p.284 |
| ALT/V/S/G/S 捕捉 | VNAV・FLCH からの移行は自動で SPD。TO/GA pitch のまま高度捕捉した場合は自動ではない（SPD を選ぶ）。GA の level-off も SPD を選ぶまで THR/THR REF | ATA34_2 p.654、FCTM p.124 (4.2)、FCOM p.673 (4.20.15) |
| VNAV 巡航・VNAV ALT | SPD（limit は CRZ か CLB、§4.5） | ATA34_2 p.664–665、FCOM p.1256 (11.31.22) |
| VNAV PTH 降下 | IDLE → lever が stop に着くか override で HOLD。浅い path は SPD。目標より 15 kt（最初の速度制限より下では 10 kt）以上遅いと IDLE/HOLD → SPD | ATA34_2 p.666–667、FCOM p.1258–1259 (11.31.24–25)、ATA22 p.280 |
| early descent | THR → HOLD（pitch VNAV SPD） | FCOM p.1260 (11.31.26) |
| VNAV SPD（speed intervention 降下） | thrust は idle のまま pitch で速度 | FCTM p.137 (4.15) |
| 進入 | G/S 中・手動進入は SPD | ATA34_2 p.658 |
| flare | LAND 3/2 で AFDS が 25 ft で flare retard 要求 → IDLE、lever を後方 stop へ 5°/s。rollout 中 IDLE、reverse で A/T 解除（メッセージなし） | FCOM p.671、ATA34_2 p.648、ATA22 p.294 |
| go-around | 1 回目 THR（2000 fpm、GA limit）、2 回目 THR REF（full GA）。VNAV を押すと limit は CLB | FCOM p.673–674、ATA34_2 p.674–675 |
| V/S、A/P・F/D なし | SPD か THR REF を選択可（降下で THR REF は通常使わない） | ATA34_2 p.657–658 |
| エンジン停止（離陸） | thrust reduction 前の検知なら TO の THR REF のまま。VNAV でフラップ UP 後 VREF+98 で CON | FCOM p.1266 (11.31.32)、p.1272 |
| ENG OUT 実行・driftdown | limit CON、A/T は CON まで推力。1 発停止では A/T 有効、2 発で解除 | FCOM p.1266–1269、FCTM p.133–134 (4.12) |

### 4.4 制御則と servo (ATA34_2 p.646–649、p.472、p.490、p.690)

- speed・V/S・thrust の各 section が「誤差率」指令を出し、servo control が積分して lever 位置指令にする。tach が指令に追いつくと一定速度で動き、誤差率 0 で停止 (ATA34_2 p.648)。
- servo 速度: 0–10°/s。ground servo loop test の合格は 6–10°/s。flare retard は 5°/s (ATA34_2 p.472、p.490、p.648、p.690)。lever の全行程角は資料に記載なし（3D の lever は 0→1 で 50° 回転: 747-400_cockpit.obj:24128-24133）。
- pilot override: FLCH で lever が指令から 8° ずれると HOLD（excitation off）。他のモードでは離すと指令位置へ戻り、モード表示は変わらない (ATA34_2 p.648)。
- 速度保護: FMC の最小（min maneuver）・最大（Vmo/Mmo、gear、flap placard）を 5 kt の余裕で使う。A/T の保護は reference limit と idle の範囲内。V/S と最大 engine-out 高度以上の engine failure では保護なし。FMC 無効時は FCC 内部の制限（フラップで決まる最小、Vmo/Mmo・placard）(FCOM p.675 (4.20.17))。保護の発効は TO と他モードで 400 ft RA から、GA では full GA 指令時から (ATA34_2 p.648)。
- 技法上の特性: 速度が下がると急速に推力を増し、上がるとゆっくり減らす (FCTM p.43 (1.13))。Vmo/Mmo に近いほど強く制御 (FCTM p.301 (8.23))。

### 4.5 推力制限（thrust limit）計算と自動切替

- 出力は 2 つ: maximum thrust（EICAS 用、どのモード・derate でも下げない）と thrust limit / THR REF（CDU・EICAS・A/T の上限）(ATA34_2 p.642)。入力は CDU/MCP のモード要求、A/T 制御モード、ADC（高度、温度、Mach）、EIU（実 N1、reverse、bleed discrete）、TO/GA・takeoff スイッチ (ATA34_2 p.643 図)。
- limit は thrust limit モードと温度・気圧・高度で決まり、max limit は EIU と EEC へ送る (ATA34_2 p.638)。PW・RR は EPR、GE は N1 (FCOM p.1271–1272 (11.32.1–2))。
- 表の出典（シムの値を合わせる先）: PW4056 Max Climb EPR p.262 (PI.10.36)、Go-around EPR p.263 (PI.10.37)、Max Continuous EPR p.283–284 (PI.13.1)、ALTN EEC の Takeoff EPR p.300 (PI.15.6)。CF6 Max Climb %N1 p.359 (PI.20.31)、Go-around %N1 p.360 (PI.20.32)、Max Continuous %N1 p.379–380 (PI.23.1)。通常モードの Takeoff EPR/N1 表と Max Cruise 表は FCOM に無い（資料に記載なし）。

| きっかけ | 新しい limit | 根拠 |
|---|---|---|
| 地上（既定） | TO（THRUST LIM の選択） | ATA34_2 p.535 |
| thrust reduction 点（フラップ 5 か入力高度）で VNAV 作動中 | armed climb（CLB/CLB 1/CLB 2） | FCOM p.667、p.1272、FMSPG p.105 (3.2-45)・p.111 (3.3-2) |
| VNAV なしで 400 ft 以上、THR スイッチ | armed climb（E/O なら CON） | FCOM p.642、ATA34_2 p.536、FMSPG p.111 |
| T/C（VNAV 巡航移行） | CRZ（PERF FACTORS で CRZ 指定時）。既定は CLB のまま。E&M の例は CRZ (ATA34_2 p.664) | FCOM p.1273 (11.32.3)、ATA34_2 p.536、FMSPG p.267 (7-7) |
| 空中でフラップ UP 以外、着陸位置、または G/S 捕捉 | GA。フラップ着陸位置か G/S 中は GA に固定 | FCOM p.672 (4.20.14) |
| GA 後の THR スイッチ / VNAV | CLB（E/O か CON 選択時は CON） | FCOM p.642、p.674 図 |
| VNAV・engine failure・フラップ UP・VREF+98 | CON（予定の thrust reduction は抑止） | FCOM p.1272 |
| ENG OUT（CLB/CRZ）実行 | CON | FCOM p.1341 (11.41.17)、p.1350 (11.42.6) |
| CDU の手動選択 | 押したもの（自動選択を上書き） | FCOM p.1316、p.1339 |

- 地上の takeoff 選択中は CLB 系を <ARM> 表示。ARM の CLB は thrust reduction で <SEL> (ATA34_2 p.535–536)。

### 4.6 derate と assumed temperature

- TO 1 / TO 2: operator 指定の %（1% 刻み、最大 certified derate まで）。fixed derate は離陸の limitation（エンジン故障時も越えない）(FCOM p.1272 (11.32.2)、FCTM p.102 (3.14))。PERF FACTORS で 0–30% (ATA34_2 p.678)。
- D-TO（assumed temperature）: 入力温度が実温度より高いと減少。最大減少 25%（derate との併用時は derated thrust から 25%）。limitation ではなく、必要なら手で full thrust (FCOM p.1273、FCTM p.101–102 (3.13–14))。選択温度は TAT より高いときだけ使う (ATA34_2 p.651)。limit が下がったときだけ D を付ける (ATA34_2 p.535)。TO/GA で離陸開始後は入力禁止 (FMSPG p.101 (3.2-41))。
- climb derate の自動選択（109）: takeoff 減少 <5% → CLB、5% 以上 15% 未満 → CLB 1、15% 以上 → CLB 2。takeoff 選択後に地上で手動上書き可（takeoff derate は変わらない）(FCOM p.1273、FCTM p.123 (4.1)、FMSPG p.103)。405・570 は TO 1→CLB 1、TO 2→CLB 2 (FCOM p.1315)。
- CLB 1 / CLB 2 の消去: 109 は 10,000 ft まで 10% / 20%、そこから CLB 1 は 30,000 ft、CLB 2 は 35,000 ft で線形に CLB へ。405・570 は両方 15,000 ft で CLB (FCOM p.1273)。FMSPG も 15,000 ft (FMSPG p.33 (2-21))。上昇率が約 500 fpm を下回ったら上の rating を選ぶ (FCTM p.123)。
- 離陸後の TO/GA で takeoff derate は外れる (§4.3)。

### 4.7 engine trim (ATA34_2 p.638・640・474)

- 手動・A/T とも作動。遅れているエンジンを最も高い推力に uptrim、authority 上限に達したら先行エンジンを downtrim。authority は 20,000 ft 未満 5%、以上 10%。master FMC → master relay 2 → EEC。A/T ARM discrete と trim enable relay（R7561）で有効化。

## 5. 他系統とのつながり

| 相手 | A/T → 相手 | 相手 → A/T | 根拠 |
|---|---|---|---|
| AFDS（FCC/MCP） | モード状態、速度データ（MCP の A/T ボタン点灯と IAS/MACH 窓の表示）、VNAV の速度・推力指令は FMC 内部 | pitch mode（FLCH・VNAV・G/S・ALT・V/S・TO/GA）、voted TO/GA、flare retard 要求（25 ft、LAND 3/2）、A/P・F/D 状態、MCP 速度・高度、SPD-through-elevator 中に A/T が SPD へ変わると V/S default | ATA34_2 p.470、p.472、p.647–648、ATA22 p.294・338 |
| FMC VNAV/性能 | — | 目標速度（TAS）、VNAV の thrust/idle/hold 要求、飛行段階、FMC target N1/EPR（level flight と A/T off cruise） | ATA34_2 p.597、p.612、p.615–616、p.649 図 |
| EEC | lever 位置（TRA）、EPR/N1 trim、bleed correction、max limit | 実 EPR/N1（EIU 経由）、ALTN 状態、command 表示、PW は ALTN で limit を N1 表示 | ATA34_2 p.474、p.638、FCOM p.1315、p.877 |
| ELEC | — | §2 の電源。電源喪失で A/T 不可 | ATA34_2 p.450、FCOM p.800、ATA-24.md ELEC-06/07 |
| EICAS・警報 | AUTOTHROT DISC、mode・limit・TAT・assumed temp・reference/target/max | — | ATA34_2 p.462、p.651–653 |
| エンジン・reverse | — | reverse lever（A/T 解除）、運転中エンジン数 | FCOM p.666、ATA34_2 p.645 |
| 空地・フラップ・ADC | — | 地上判定、フラップ位置（TO/GA 条件、GA limit、速度保護）、CAS・Mach・高度・温度 | ATA34_2 p.470、p.643、p.660、p.674 |

## 6. 実装上の注意

- 名前を変えてはいけないもの（INTERFACES.tsv）: `laminar/B747/autopilot/FMA/autothrottle_mode`（値 0 NONE、1 HOLD、2 IDLE、3 SPD、4 THR、5 THR REF。パネルは 1–5 の画像を持つ: 747-400.acf:86068-86156）、`.../FMA/autothrottle/mode_box_status`、`laminar/B747/engines/ref_thr_limit_mode`（文字列。パネルは緑の 1 行テキスト: 747-400.acf:119366-119378）、`.../display_EPR_ref`・`_max`・`display_N1_ref`・`_max`、`.../display_ref_line_magenta`、`.../thrust_ref`、`.../TRA`、`laminar/B747/engine/throttle`（3D lever 角）、コマンド `laminar/B747/toggle_switch/autothrottle`、`.../button_switch/thrust_mode`・`speed_mode`・`autothrottle_disco_L/R`、`laminar/B747/toggle_switch/position`（[29] = A/T ARM）。
- INTERFACES.tsv に無いがパネルが読む X-Plane dataref: `sim/cockpit2/engine/actuators/EPR_target_bug[0-3]`・`N1_target_bug[0-3]`（EICAS の reference 数字。747-400.acf:119420-119560）。3D の TO/GA スイッチは `sim/engines/TOGA_power`（747-400_cockpit.obj:24166、24228）、ハードウェアは `sim/autopilot/take_off_go_around`。
- 他モジュールが読む内部名（残すか同時に直す）: `laminar/B747/engines/autothrottle_active`・`autothrottle_fail`・`TOGA_mode`（エンジンの EGT 抑止も使う）、`laminar/B747/autothrottle/armed`、`laminar/B747/autopilot/thrust_mode`・`flightPhase`、`laminar/B747/engine/derate/TO`・`CLB`、`laminar/B747/engines/thrustref_throttle`。`ref_thr_limit_mode` の値は EEC が `string.match(…,"TO")`・`"CLB"`・`"CRZ"`・`== "GA"` で判定し（CON の分岐は無い）、PFD の minimums 表示も `"TO"` を見る（plugins/xtlua_keysystems/scripts/B747.60.xt.fltInst/B747.60.xt.fltInst02.lua:2870）。CON を足すなら EEC 側の対応が要る。
- パネルの制約（純正 acf は変えない。カスタム acf の変更は要承認）
  - マゼンタのカーソルは `autothrottle_mode == 5` かつ `display_ref_line_magenta > 0.1` のときだけ出る（747-400.acf:120056-120116、N1 は 121053 以降）。緑は magenta == 0 のとき。A/T OFF の cruise target（マゼンタ）は acf を直さないと出せない。
  - EICAS に assumed temperature の要素が無い。mode 文字列に温度を付けて出す（例 `D-TO 1 +38C`）か、カスタム acf に要素を足す（要承認）。文字列に付ける場合、`== "GA"` 判定には影響しないが、受け手全部を確認する。
  - reference の数字は target bug を表示する。target と limit を分けるなら、数字に limit、カーソルに target を出す必要があるが、現パネルは数字・カーソルとも別の dataref なので値の与え方で実現できる。
- lever の角度: 実機の全行程は資料に記載なし。3D は 50° なので、10°/s は全行程 5 s（推定）。servo 速度・8° override はこの換算で決める。
- ハードウェア・スロットル: 実機は A/T が lever を動かすが、ハードウェア軸は戻せない。A/T 作動中は軸の変化量がしきい値を超えたら override とみなし、FLCH では 8° 相当で HOLD、他モードでは軸が止まったら指令位置へ戻す、などの方針が要る（推定、要相談）。
- X-Plane の A/T は使わない（現コードは常に hard off: B747.70.xt.autopilot.monitor.lua:567-582）。`override_throttles` と lever→推力は EEC の担当。
- 単純化してよいもの: 2 台の FMC と master relay（電源・master 切替による解除だけ残す）、servo loop monitor の数値、TEST モード、engine trim（4 発同一モデルなら効果が小さい）、ground test。
- 単純化してはいけないもの: モードと遷移（特に HOLD の意味＝servo 停止）、THR の V/S 則、limit の自動切替と THR スイッチの二つの機能、assumed temp と derate、AUTOTHROT DISC の出し方と reset、EICAS の mode・limit・target・max の意味、pilot override。
- 状態の持ち主を 1 つにする: 今は A/T 状態（active、fail、TOGA_mode、thrust_mode、FMA）と `flightPhase` が 10 以上の場所から書かれ、推力制限モードは `flightPhase` から派生している（§7）。XTLua は dataref の書き込みが非同期なので、判定は Lua 内の状態で行い dataref は出力専用にする。

## 7. 現状実装との比較（GAP 候補）

該当コードの略記: AP = `plugins/xtlua_keysystems/scripts/B747.70.xt.autopilot/B747.70.xt.autopilot.lua`、MON = 同 `B747.70.xt.autopilot.monitor.lua`、ALND = 同 `B747.autoland.lua`、EEC = `plugins/xtlua/scripts/B747.42.xt.EEC/B747.42.xt.EEC.lua`、EPW / EGE / ERR = 同 `.PW.lua` / `.GE.lua` / `.RR.lua`、ENG = `plugins/xtlua/scripts/B747.40.xt.engines/B747.40.xt.engines.lua`、MAN = `plugins/xtlua/scripts/B747.01.xt.manipulators/B747.01.xt.manipulators.lua`、FMS = `plugins/xtlua_keysystems/scripts/B747.68.xt.fms/`、ACF = `747-400.acf`。

| ID | 種別 | 重要度 | 規模 | 内容 | 根拠 | 該当コード |
|---|---|---|---|---|---|---|
| ATHR-01 | 挙動の誤り | 高 | L | 推力制限モードが `flightPhase`（0→TO、1→CLB、2 以上→CRZ）だけから作られ、`flightPhase` は V/S ホイール、FLCH・SPD・ALT 押し、monitor など多数が書く。TO→CLB は THR REDUCTION（フラップ 5 / 入力高度、VNAV 条件）でなく、THR REF 中に RA 1,000 ft 未満なら TO、それ以上で MCP 高度が 1,000 ft 以上上なら CLB という固定則。中間の level-off で CRZ になる。T/C の CLB/CRZ 選択（PERF FACTORS）が無い。GA は「flightPhase≥2・フラップ>0・RA<1,500 ft」か TO/GA 押しだけで、G/S 捕捉では入らず、RA 1,500 ft で自動終了して TO/CLB/CRZ に落ちる。CON が無い（E/O VREF+98、ENG OUT、THR スイッチ）。THR スイッチの推力制限機能が無い | FCOM p.642、p.667、p.672、p.674、p.1266、p.1272–1273、p.1341、p.1350、ATA34_2 p.536、p.662–665、FMSPG p.105、p.111、p.267 | EEC:683-719、MON:393-414、MON:642-644、AP:1384-1414、AP:1883-1886、AP:2759 |
| ATHR-02 | バグ | 中 | S | 空中の THRUST LIM: <GA/<CON/<CRZ の LSK が TO/TO1/TO2 の setDref に繋がり、押すと toderate と clbderate を書き換える（GA→CLB、CON→CLB 1、CRZ→CLB 2 相当）。見出しにモードと limit が無い。<SEL> は clbderate で付く。R1 が入力を受け付ける。地上の見出しは `TO-1` 形式で D も出ない。derate % は固定表示 10/20 | FCOM p.1313–1316、p.1338–1340、ATA34_2 p.535–537 | FMS/activepages/B744.fms.pages.thrustlim.lua:13-15・50-70・77・83-85・165-173、FMS/B744.fms.pages.lua:2543-2548 |
| ATHR-03 | 欠落 | 高 | M | assumed temperature が推力に効かない。SEL 入力は `thrustsel` に文字列で保存されるだけで、EEC の使用箇所はコメントアウト。D-TO 表示、25% 上限、0–99°C/°F の検証、TAKEOFF SPEEDS DELETED、TO/GA 後の入力禁止、減少率による CLB 1/2 自動選択が無い。EICAS に assumed temp の表示要素が無い | FCOM p.831、p.1273、p.1314、ATA34_2 p.535、p.651–652、FMSPG p.101、p.103 | FMS/activepages/B744.fms.pages.thrustlim.lua:38・165、FMS/B747.68.xt.fms.lua:635、EPW:118-129、EGE:130-136、EEC:583-644、ACF:119366-119378 |
| ATHR-04 | 挙動の誤り | 高 | M | CLB の reference が rating でなく「固定の設計上昇率（PW4056 で 2,750 fpm など）に必要な推力」（max climb で頭打ち）。VNAV/FLCH の上昇で CLB 定格より少ない推力になる。CRZ の reference は M.85 巡航に必要な EPR の表（P85M）で、max cruise rating ではない。GA は近似式、GE は TO の N1 を流用。PI の Max Climb / GA / Max Continuous 表を使っていない | FCOM p.1271–1272、ATA34_2 p.642–643、PI p.262–263、p.283、p.359–360、p.379 | EPW:160-302・603-666、EGE:165-310・551-595、ERR:794-850、EEC:646-680 |
| ATHR-05 | 挙動の誤り | 低 | S | CLB 1/2 の消去を全型式 10,000→15,000 ft（405・570 の値）で行い、derate を「必要推力」に掛けている。109（PW 旅客）は 30,000/35,000 ft。TO 1/TO 2 は固定 10%/20%（FCOM の例は PW −8/−20%、GE −5/−15%、operator 指定）。PERF FACTORS は固定表示で機能しない | FCOM p.1272–1273、p.1313–1314、ATA34_2 p.678 | EEC:624-628・654-658、FMS/activepages/B744.fms.pages.maintperffactor.lua:2-14 |
| ATHR-06 | 欠落 | 高 | M | A/T の THR モード（FMA 値 4）を一度も出さない（パネルには画像がある）。FLCH の上昇・降下は THR REF 表示で、125 s の V/S 則が無く常に CLB reference まで推力を出す。FLCH 降下は THR REF のまま「target 0.9 EPR / N1 25%」の仮値で idle にする。GA 1 回目の THR（2000 fpm）が無く、即 THR REF で full GA。2 回目は効果なし。early descent の THR→HOLD も無い | FCOM p.657、p.662、p.673、p.1260、ATA34_2 p.646–647、p.654、p.670、p.674–675、ATA22 p.284 | AP:756・2840-2849、EPW:695-700、EGE:618-623、ERR:888-893、ENG:552-571 |
| ATHR-07 | 挙動の誤り | 高 | M | HOLD/IDLE の論理: VNAV 降下は lever が 0.1 未満になるまで SPD、その後は IDLE のまま HOLD にならない（monitor が lever <0.02 で A/T を非作動にして代用）。IDLE 中も servo が lever を idle に保ち、速度不足では FMA は IDLE のまま推力を足す（実機は SPD へ）。FLCH 降下の HOLD も無い | FCOM p.662、p.1259、ATA34_2 p.644・654、p.666–667、p.670 | AP:2858-2875、MON:337-350、EEC:942-946・974-976 |
| ATHR-08 | 挙動の誤り | 高 | M | TO/GA: 地上でフラップ UP・50 kt 以上・limit TO 以外でも作動する（50 kt 以上なら 400 ft まで不可が正）。65 kt の HOLD 後、RA 50 ft で TO/GA pitch のまま THR REF に戻る（VNAV か他モードまで HOLD が正）。TO/GA pitch・GA の level-off で monitor が自動的に SPD にする。離陸直後の TO/GA は「derate を外した TO」でなく GA limit になる。空中では TO/GA arm 条件（フラップ UP 以外か G/S）を見ない。touch-and-go の TO/GA は 65 kt 以上だと HOLD。manipulators の wrap は ARM OFF でも A/T active を立てる | FCOM p.656–657、p.667、p.671、p.673、FCTM p.94、p.124、ATA34_2 p.660–661、p.674 | ENG:542-578、MAN:438-444・500、AP:2840-2862、MON:634-666 |
| ATHR-09 | 欠落 | 高 | M | pilot override が無い。A/T 作動中（FMA>1）はハードウェア軸も 3D lever の入力も無視され、lever は A/T 指令のみ。FLCH の 8° override → HOLD、離すと指令位置へ戻る動きが無い | FCOM p.666 (4.20.8)、ATA34_2 p.648 | EEC:1105-1120・1134-1141 |
| ATHR-10 | 挙動の誤り | 中 | M | servo が速度制限付きの積分器になっていない。THR REF は誤差比例の積分で、時定数は PW/RR で約 17 s、GE で約 4 s（コードの係数からの推定）。PW/RR では 65 kt の HOLD までに TO 推力に届かない恐れ（旧フォークは 30–40 s を観察）。IDLE・flare retard は目標を即 0 にし、lever は 1–2 s で全行程（3D 換算 25–50°/s）。実機は最大 10°/s、flare 5°/s。増分がフレーム単位でフレームレートに依存 | ATA34_2 p.472、p.490、p.648、p.690、FMSPG p.110 (3.3-1)、OLD_FORK_NOTES.md §3 | EEC:878-927・929-1006 |
| ATHR-11 | 欠落 | 中 | M | SPD で reference limit を守らない（lever 1.0 = max 線まで出る）。THR REF に limit speed（Vmo/Mmo、placard）制御が無い。速度保護は MCP 目標の固定クランプ（Vmc+10、フラップ placard −5 kt の固定値、gear placard なし）で、V/S でも効く（実機は V/S で保護なし） | FCOM p.663、p.675、p.935 (9.10.9)、ATA34_2 p.646–648、p.668、p.672 | EEC:878-927・942-978、AP:1942-1972 |
| ATHR-12 | 挙動の誤り | 中 | S | flare retard: SPD なら autoland でなくても RA 25 ft で IDLE・lever 0（LAND 3/2 の要求が条件）。autoland は 40 ft で IDLE。接地で FMA を空白にする（reverse での解除まで IDLE が正） | FCOM p.671、ATA34_2 p.648、ATA22 p.294 | EEC:909-911、ALND:204-206・216-221・233 |
| ATHR-13 | バグ | 高 | S | reverse で A/T を落とすとき `autothrottle_fail=1` にするため、reverse を使った着陸のたびに >AUTOTHROT DISC（caution）が出て、disconnect・ARM 操作か TO/GA まで残る。reverse による解除ではメッセージと音を出さないのが正 | FCOM p.677、ATA34_2 p.644 | ENG:479-492・779-788、AP:3393-3398 |
| ATHR-14 | 挙動の誤り | 中 | S | disconnect スイッチが `autothrottle_fail` を反転するだけ。A/T 非作動時に押してもメッセージが出る。fail=1 の間はモードスイッチで再作動できない（2 回目か ARM の入れ直しが要る）。実機は 1 回目で解除（engage 中だった場合だけメッセージ）、A/T は ARM のまま、再 engage でもメッセージ reset | FCOM p.657、p.666、ATA34_2 p.492、p.645、LH3460 p.60 | AP:541-544・969-987、MAN:1437-1477 |
| ATHR-15 | 欠落 | 中 | M | engage interlock の不足: 電源（F/O XFR の servo、APU stby/F/O XFR の FMC、DC bus 1・2）、FMC 故障・master 切替による解除、servo monitor が無い。EEC ALTN は 1 台で解除するが、再作動の規則（PW は全 NORM、GE は全 ALTN）が無く、fail を戻せば 1–3 台 ALTN でも servo が動く。運転中エンジン数は表示 N1 >15% で判定 | ATA34_2 p.450、p.452、p.645、FCOM p.666、p.800、p.877、p.1215、p.1275 | AP:541-544、MON:597-616、EEC:1023-1030・1105、plugins/xtlua_keysystems/scripts/B747.60.xt.fltInst/B747.60.xt.fltInst02.lua:660-664 |
| ATHR-16 | 挙動の誤り | 中 | S | SPD スイッチが VNAV・FLCH 中でも効き、VNAV/FLCH を取り消して V/S にする（FCOM はこれらの pitch で無効）。400 ft の下限が無い。THR スイッチは 400 ft 未満でも A/T active を落とす。ALT・G/S では monitor が A/T を自動で作動させる | FCOM p.641–642、ATA34_2 p.654、p.668 | AP:553-609、MON:634-666 |
| ATHR-17 | 挙動の誤り | 中 | S | EICAS: reference の数字に target bug を出すため、降下の THR REF/IDLE では 0.90（GE は 25.0）と表示。max EPR/N1 線を地上で TO 1/2 の derate 分下げる（どの derate でも下げないのが正）。マゼンタは FLCH でも立つ一方、A/T OFF の cruise target と VNAV idle 降下・anti-ice のマゼンタは無い（パネルが FMA=5 を条件にしており acf 変更が要る） | FCOM p.833–834、p.215、ATA34_2 p.642、p.651–653、LH3460 p.96 | EPW:589-593・695-700、EGE:535-539・618-623、EEC:1052-1063、ACF:119420-119560・120056-120116 |
| ATHR-18 | 欠落 | 低 | M | engine trim equalization（uptrim/downtrim、5%/10% authority、A/T ARM で有効）が無い。EEC は各エンジンを TRA に個別 PID で合わせているだけ | ATA34_2 p.474、p.638、p.640 | なし |
| ATHR-19 | 欠落 | 低 | S | CDU の THRUST REQUIRED を出す処理が無い。DRAG REQUIRED は A/T の状態を見ない | FCOM p.1259、p.1431、p.1434 | AP:3400-3413、FMS/B744.notifications.lua:47 |
| ATHR-20 | 挙動の誤り | 低 | S | SPD の制御則が増減ほぼ対称（実機は増は速く減は遅い、Vmo/Mmo 付近は強く）。TEST モード表示なし | FCTM p.43、p.301、ATA34_2 p.654 | EEC:855-927 |

ACF_DIFF.md との関係: `acf/_ott_asi_kts_off_for_full_def`・`_ott_asi_sec_into_future`・`_ott_asi_thro_per_sec`（純正 22 / 7 / 0.2、カスタム 10 / 5 / 0.5）は X-Plane の A/T の調整値。コードは X-Plane の A/T を常に切り（MON:567-582）、lever と推力を自前で書くので、この値には依存しない（推定。X-Plane の A/T が一瞬でも入る経路が無いことはシムで確認）。`_ott_flare_*` は AFDS、`_fadec_parameter`・`_n1_rated_thrust` は EEC の担当。

## 8. 作り直しか部分修正か

作り直しを勧める（thrust management を 1 モジュールにまとめる）。

- A/T の状態（`autothrottle_active`、`autothrottle_fail`、`TOGA_mode`、`thrust_mode`、FMA 値）は autopilot・monitor・vnavspd・autoland・engines・manipulators・EEC の 7 ファイルから書かれ、FMA は毎フレーム if 連鎖で作り直される。推力制限モードは `flightPhase` に従属し、`flightPhase` は 20 か所以上が書く。部分修正では副作用を追い切れない（ATHR-01、06〜08 の多くは同じ根）。
- 実機の構造（engage logic → mode logic → control laws → servo、別に thrust limit calculation）に合わせて作ると、資料の論理図（ATA34_2 p.645、p.649）をそのまま状態機械にできる。
- 推奨の分担
  1. `thrust management`（新、FMC 側）: engage/disconnect（latch と AUTOTHROT DISC）、A/T モード状態機械、THR（V/S）・SPD・thrust の各則、servo（10°/s、flare 5°/s、override と 8° HOLD）、thrust limit calculation（モード選択・自動切替・derate・assumed temp・max）と EICAS/CDU への出力。
  2. EEC（別担当）: TRA→EPR/N1 指令、idle、ALTN、実値表示。今 EEC にある limit 計算（EPW/EGE/ERR の CLB/CRZ/GA 分岐と target bug の仮値）と A/T servo（EEC:751-1141 の大部分）は新モジュールへ移す。EEC 側は「limit を受け取って表示・max を返す」取り決めにする。
  3. AFDS（別担当）: pitch mode・TO/GA・flare retard 要求を出し、A/T モードを読む。SPD-through-elevator と A/T の関係（FLCH/VNAV では A/T は FMC が選ぶ）を取り決める。
- 守るもの: §6 の名前と意味（INTERFACES.tsv、パネルが読む `EPR_target_bug`/`N1_target_bug`、他モジュールが読む内部名、`ref_thr_limit_mode` の文字列値）。FMA の数値の意味（0–5）は FDR も使う（`plugins/xtlua_fdr/scripts/B747.01.xt.fdr/B747.01.xt.fdr.lua:266-279`）。
- 順序の案: (1) 推力制限モードの状態機械と CDU THRUST LIM/TAKEOFF REF（ATHR-01〜03）→ (2) limit の値を PI 表へ（ATHR-04・05。EEC 担当と調整）→ (3) A/T モード状態機械と servo・override（ATHR-06〜12・16）→ (4) disconnect/メッセージ/interlock（ATHR-13〜15）→ (5) EICAS 表示（ATHR-17。acf 変更が要る部分は承認を取る）。

## 9. 未確認事項

- thrust lever の全行程角と、lever 角→TRA の関係（資料に記載なし。3D は 50°）。10°/s・8° をどう換算するか。
- servo loop monitor の閾値、A/T ARM スイッチが故障時に OFF へ落ちる（solenoid 保持）かどうか（資料に記載なし）。
- 通常モードの Takeoff EPR/N1 表と Max Cruise rating（FCOM に無い）。assumed temp の limit をどう計算するか（現 EEC の corrected thrust モデルを使うか）。RR は資料なし。
- THR REF（limit speed 制御）の具体的な則、SPD の利得、FLCH の「125 s」が V/S 指令の計算式としてどう使われるか（式は資料に記載なし）。
- PERF FACTORS の既定値（THR RED がフラップ 5 か高度か、THR/CRZ が CLB か CRZ か）を本機でどうするか。109 の FCOM 例は TAKEOFF REF に FLAPS 5 を示す (FCOM p.1317)。
- 1 発停止時の A/T（3 発運転）の推力配分と、engine trim を実装する価値。
- ハードウェア・スロットル使用時の override の扱い（§6）。
- 現コードの THR REF 収束時間（PW/RR 約 17 s、GE 約 4 s の時定数という推定）と、65 kt 時点の推力不足が実際に起きるかをシムで確認する。
- FCOM と E&M の食い違い（GA で A/P・F/D off のときの A/T モード、THR スイッチの GA 時の条件）は FCOM に従ったが、E&M の CF6 機と FCOM 109 の版差の可能性がある。
