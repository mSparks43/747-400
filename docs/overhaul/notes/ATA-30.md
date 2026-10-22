# ATA 30 Ice and Rain Protection（防氷・防雨）調査メモ

2026-10-23 調査。対象コードは `overhaul`（041c9ffa）。出典の書き方は REFERENCE_INDEX.md に従う。

## 1. 概要

- 対象: ナセル防氷（NAI）、主翼防氷（WAI）、氷検知、窓加熱（前面窓 1 と側窓 2・3）、プローブ加熱（ピトー静圧、AOA、TAT）、ワイパー、ウォッシャー、防雨剤、WSHLD AIR、関係する EICAS メッセージ、主 EICAS と ECS synoptic の NAI/WAI 表示、防氷の推力への影響。
- 水・排水管のヒーター（30-70）は乗員に見える表示も操作も無いので省略する（ATA30_32_35_36 p.286–304 にある）。
- 抽気の供給側（PRV、ダクト圧）は ATA-36.md。
- 使った資料:
  - FCOM 3.10–3.30 p.625–636、SP.16 p.201–220、2.10 p.576–581（ECS synoptic）、2.40 p.611–614、7.20 p.876–878・p.883、L.10 p.82、PI p.261–262・p.358–360、NP p.106–107・p.126・p.152。
  - ATA30_32_35_36 p.151–308（E&M 30 章）。氷検知の AUTO 運用を含む OFF/AUTO/ON 切替スイッチの機体を書いている。
  - LH36 p.106–129（PW 機の 30-80 氷検知と 30-10 WAI。AUTO 付きと無しの両方の構成を書いている）。
- 構成の違い（重要）
  - FCOM の機体は NAI・WAI とも押しボタン（ON/off）と VALVE 灯で、AUTO は無い (FCOM p.625 (3.10.1))。氷検知（109 と 570 のみ）は EICAS メッセージを出すだけ (FCOM p.631 (3.20.1))。
  - LH36 と E&M は、OFF/AUTO/ON のスイッチで氷検知が NAI・WAI を自動で開く構成も書いている (LH36 p.106–116、ATA30_32_35_36 p.174・p.200)。
  - シムの 3D は押しボタン（`laminar/B747/button_switch/anti_ice_nacelle_1` など）なので、FCOM の構成に従う。AUTO は実装しない。
- FCOM の effectivity: 109 = PW 旅客機（氷検知あり、防雨剤あり）、405 = PW 改造貨物機（氷検知なし）、570 = GE 貨物機（氷検知あり）(FCOM p.5、p.627、p.631)。シムは旅客機なので 109 を基準にする（推定）。

## 2. 構成

### 2.1 ナセル防氷（NAI）

- エンジンごとに NAI 弁 1 個。電気で制御（28V DC ソレノイド）し空気圧で動く蝶形弁。開くと約 24 psig、約 90 lb/min に調節し、空気は支柱上のダクトからスプレーダクトへ行き、ナセル下部から機外へ出る (ATA30_32_35_36 p.192–196・p.202 (30-21))。
- 過熱スイッチ（カウル内、250°F/121°C で弁を閉じてラッチ）と圧力スイッチ（>30 psig で EICAS へ）(ATA30_32_35_36 p.198)。これらは E&M（CF6 と推定）の記述。PW の NAI の詳細は資料に記載なし（LH36 は 30-20 を扱っていない）。
- 空気はエンジン抽気の PRV・プレクーラーの下流、PRSOV の上流から取る (FCOM p.615 (2.40.5) の図)。ENGINE BLEED が ON でも off でも使える。使えないのは PRV failed closed、過熱で PRV が閉、始動弁が閉でないとき。off のときはさらに HPSOV failed open のときも使えない (FCOM p.612 (2.40.2))。

### 2.2 主翼防氷（WAI）

- 左右に 1 個ずつ、外側エンジン付近の LE フラップの空洞にある 3.5 in の蝶形弁（内蔵電動モーター）。Y 継手から内側・外側のスプレーダクトへ送り、前縁下面のスロットから出す (LH36 p.112・p.126 (30-10)、ATA30_32_35_36 p.170–172 (30-11))。
- 開閉は 3 s 未満 (LH36 p.126)。
- 電源: 115V AC bus 2（弁）と 28V DC bus 2（制御）(LH36 p.112・p.118)。
- 空気は左右のダクト区画から (FCOM p.615 の図)。
- 空地リレー R227 で地上では閉 (ATA30_32_35_36 p.176)。

### 2.3 氷検知（109・570）

- 前部胴体の左右に磁歪式プローブ 2 個（約 40 kHz で振動）。左は 115V AC bus 1、右は bus 3。空中だけで働く (LH36 p.106 (30-80)、ATA30_32_35_36 p.158・p.161 (30-81))。
- 約 0.5 mm（0.02 in）の氷が付くとプローブのヒーターが入り、周波数が戻ると切れる（通常 7–8 s）。この着氷・除氷の回数を数える (LH36 p.108、ATA30_32_35_36 p.161)。
- ヒーターが 25 s を超えて入っているか内部温度が 149°C を超えると、ヒーターと出力を止める（故障）(LH36 p.106、ATA30_32_35_36 p.161)。
- 回の間隔が 3 分を超えると回数を 0 に戻す。地上ではヒーターを止め、回数を 0 に保つ (ATA30_32_35_36 p.161)。
- AUTO 構成の出力（参考）: 2 回（または 1 回目の除氷に 15 s 超）で NAI を 180±10 s、10 回で WAI を 180±10 s 開く。その間に次の回があれば 180 s を数え直す (LH36 p.108、ATA30_32_35_36 p.162)。

### 2.4 窓加熱

- 前面窓 1（L/R）: 約 3000 W の導電膜。電力 115V AC、制御 28V DC。窓加熱制御器（左 M73 は E1-4、右 M273 は E2-3）が温度センサー（制御用と予備）を見て、徐々に電力を上げ、所定温度で一定に保つ (ATA30_32_35_36 p.242–248 (30-41))。
- 側窓 2・3（150 W と 210 W）: 主バスの 115V AC があれば自動で加熱。制御サーモスタット 105°F（41°C）、過熱 120°F（49°C）。操作子は無い (ATA30_32_35_36 p.254–258、FCOM p.633 (3.20.3))。
- 前面窓は外面の防氷と内面の曇り止め、側窓は内面の曇り止めだけ (FCOM p.633)。

### 2.5 プローブ加熱

- ピトー静圧 4 本（主 2、補助 2）、AOA 2 個、TAT 2 個。いずれも 115V AC のヒーターで、電流センサーが EICAS へ出す (ATA30_32_35_36 p.212–234 (30-31))。

### 2.6 ワイパー・ウォッシャー・防雨剤・WSHLD AIR

- ワイパー: 左右独立の 2 速。28V DC のモーター。LO 160 回/分、HI 250 回/分、約 70° で幅 22 in を拭く。OFF でモーターが逆転して格納位置で止まる。過熱用の 149°C 熱スイッチ（自動復帰）。牽引中は ground handling bus で動く (ATA30_32_35_36 p.264・p.272 (30-42)、FCOM p.628 (3.10.4)・p.633)。
- ウォッシャー: 1 quart の容器、ポンプは 115V AC、弁は 28V DC。スイッチを ON に保持するあいだ液を出す (ATA30_32_35_36 p.276・p.284 (30-44)、FCOM p.634 (3.20.4))。
- 防雨剤（RAIN REP、109 のみ）: 押すと決まった量を窓に吹く。乾いた窓には使わない (FCOM p.628、p.219 (SP.16.19))。
- WSHLD AIR（機長・副操縦士の補助パネル）: 操縦室の調和空気を窓に当てて曇りを止める (FCOM p.628–629、p.633)。

## 3. 操作と表示

### 3.1 頭上パネルの防氷スイッチ（FCOM p.625–626 (3.10.1–2)）

| 操作子・灯 | 動作 |
|---|---|
| NACELLE ANTI-ICE 1–4 | ON: 抽気圧があれば弁が開く。AUTO IGNITION で選んだ点火器と EEC が連続作動。PRV が開く（過熱、始動弁未閉、HPSOV failed open を除く）。off: 弁閉 |
| NAI VALVE 灯（琥珀） | 弁位置がスイッチ位置と不一致 |
| WING ANTI-ICE | ON: 飛行中は左右の弁が開く。地上では作動しない |
| WAI VALVE 灯（琥珀） | どちらかの弁の位置がスイッチ位置と不一致 |

- 現コードとの対応: `laminar/B747/button_switch/position` の [68]–[71] NAI 1–4、[72] WAI、[73]/[74] WINDOW HEAT L/R。灯は `laminar/B747/annunciator/brightness_ratio` の [60]–[63] NAI VALVE、[64] WAI VALVE、[65]/[66] WINDOW HEAT INOP（B747.90.xt.lighting.lua:1811-1817）。

### 3.2 窓加熱・ワイパー・ウォッシャー（FCOM p.627–628 (3.10.3–4)）

| 操作子・灯 | 動作 |
|---|---|
| WINDOW HEAT L/R | ON: 前面窓に制御された加熱 |
| WINDOW HEAT INOP 灯（琥珀） | 窓の過熱か制御器の故障を検知、または窓の電力が切れている (FCOM p.628)。E&M の条件: センサー・ヒーター配線の断線/短絡、115V AC 喪失、制御器不作動、過熱、要求があるのに加熱されない (ATA30_32_35_36 p.246) |
| WIPER L/R | OFF（停止・格納）/ LO / HI |
| WASHER L/R | 中立へばね戻り。ON で液を出す |
| RAIN REP L/R（109） | 押すと防雨剤を出す |

- 制御器の故障は WINDOW HEAT を 10 s 以上 off にしてから ON に戻すとリセット (FCOM p.633)。
- 現コードとの対応: ワイパーは `laminar/B747/antiice/wndshlsd_wiper_L/R/sel_dial_pos` とコマンド `…/sel_dial_up`・`…/sel_dial_dn`、ウォッシャーは `laminar/B747/toggle_switch/windshield_washer_L/R`（`toggle_switch/position` の [20]/[21]）。防雨剤と WSHLD AIR の操作子は INTERFACES.tsv に無い。

### 3.3 EICAS と synoptic の表示

- 主 EICAS: NAI 弁が開くと N1 の横に緑の NAI、WAI 弁が開くとその翼側の N1 の横に緑の WAI (FCOM p.626、p.631・p.633)。acf はこれを `sim/cockpit2/ice/ice_inlet_heat_on_per_engine[0-3]` と `sim/cockpit2/ice/ice_surfce_heat_left_on`・`_right_on` で出している（747-400.acf:119003-119245）。
- ECS synoptic: NAC TAI と WING TAI の流れ (FCOM p.579・p.581、LH36 p.124)。acf は `laminar/B747/antiice/nacelle/valve_pos[i]` > 0.1、`laminar/B747/antiice/wing/valve_pos[i]` > 0.1 で出す（747-400.acf:135282-135392）。

### 3.4 EICAS メッセージ

| メッセージ | レベル | 条件 | 根拠 |
|---|---|---|---|
| >ANTI-ICE | Advisory | NAI か WAI のどれかが ON、TAT >12°C、かつ氷検知が氷を検知していない（109/570。405 は最後の条件なし） | FCOM p.635 (3.30.1) |
| HEAT L, R TAT | Advisory | TAT プローブのヒーター故障、または空地ロジックの故障で地上でも加熱している。15 s 遅延 | FCOM p.635、ATA30_32_35_36 p.228 |
| HEAT P/S CAPT, F/O, L AUX, R AUX | Advisory | ピトー静圧プローブのヒーター故障（電力か導通の喪失） | FCOM p.635、ATA30_32_35_36 p.218・p.222 |
| HEAT L, R AOA | Advisory | AOA のヒーターの電力か導通の喪失 | ATA30_32_35_36 p.234（FCOM 3.30 の表には無い） |
| HEAT WINDOW L, R | Advisory | 前面窓の加熱に電力が来ていない（E&M: CB 断、過熱、導通喪失） | FCOM p.635、ATA30_32_35_36 p.250 |
| >ICING | Caution（beeper） | 氷検知が氷を検知（109/570） | FCOM p.635 |
| NAI VALVE 1–4 | Advisory | NAI 弁が指令位置に無い（E&M: エンジン運転中、3.5 s 遅延） | FCOM p.635、ATA30_32_35_36 p.206 |
| >NO ICING | Advisory | 氷が検知されなくなった（109/570） | FCOM p.635 |
| WAI VALVE LEFT, RIGHT | Advisory | WAI 弁が指令位置に無い（E&M: 5 s 遅延） | FCOM p.635、ATA30_32_35_36 p.184 |
| >ICE DETECTORS | Advisory | 氷検知器の故障。E&M は左右どちらか（2 s 遅延）、LH36 は両方の故障で出て片方だけなら STATUS のみ | ATA30_32_35_36 p.164、LH36 p.106（FCOM 3.30 の表には無い） |

- AUTO 構成だけのメッセージ（FCOM には無い）: >ICING NAC（caution）、>ICING WING、>ANTI-ICE NAC、>ANTI-ICE WING (LH36 p.106、ATA30_32_35_36 p.184・p.206)。
- STATUS: ANTI-ICE WING L/R（60 s）、ANTI-ICE NAC n（60 s）、NAI DUCT n LEAK、WINDOW HEAT 1L/1R/2L/2R（60 s）、ICE DETECTOR L/R（12 s）、HEAT …（60 s）(ATA30_32_35_36 p.164・p.184・p.206–208・p.250・p.260)。
- 警報モジュールの表（B747.87.xt.warning.lua）: >ICING (153)、>ICING NAC (154)、>ANTI-ICE (193)、>ANTI-ICE NAC (194)、>ANTI ICE WING (195)、HEAT … (372-381)、>ICE DETECTORS (408)、NAI VALVE 1–4 (428-431)、>NO ICING (433)、WAI VALVE LEFT/RIGHT (482-483)。表はそろっているが、立てるコードがあるのは >ICING、HEAT L/R AOA、HEAT P/S CAPT/F/O だけ。

## 4. 内部ロジック

### 4.1 ナセル防氷（NAI）

1. 指令: NAI スイッチ ON で弁を開く指令。弁は空気圧で動くので、抽気の圧があって初めて開く (FCOM p.625、ATA30_32_35_36 p.202)。
2. 供給: PRV が開いていること。PRV の開条件は ATA-36.md §4.1（NAI ON で開。過熱ラッチ、始動弁が閉になってから 15 s、ENGINE BLEED off のときは HPSOV の閉確認、火災スイッチ）。HPSOV failed open で PRV が閉になると、NAI ON のあとに NAI VALVE n が出る (FCOM p.614 (2.40.4))。
3. ENGINE BLEED off で NAI ON のとき、HPSOV は閉のままで IP 空気だけになる (FCOM p.632 (3.20.2))。
4. 逆推力中は NAI 弁が閉じる (ATA30_32_35_36 p.202)。E&M の記述（CF6 と推定）。PW については資料に記載なし。
5. 過熱: カウル内 250°F で弁を閉じラッチし、温度が下がっても閉のまま。E&M は「スイッチを一瞬 off にすると弁を開けられる」と書く（ラッチの解除と解釈。推定）(ATA30_32_35_36 p.202)。STATUS は NAI DUCT n LEAK (p.208)。
6. 圧力スイッチ（>30 psig）の情報は EICAS へ行く (ATA30_32_35_36 p.198)。どのメッセージかは資料に記載なし。
7. 表示: VALVE 灯は弁位置とスイッチの不一致 (FCOM p.625)。NAI VALVE n はエンジン運転中に不一致が 3.5 s 続いたとき (ATA30_32_35_36 p.206)。主 EICAS の NAI は弁が開のとき (FCOM p.631)。
8. 他の系統への出力
   - 点火: NAI ON で、そのエンジンの点火が選ばれる。点火器は燃料制御スイッチが RUN のとき通電 (FCOM p.625、p.883 (7.20.13)、L.10 p.82 (L.10.6))。
   - EEC: 飛行中に NAI ON なら進入アイドル（接地 5 s 後に最小アイドル）(FCOM p.877–878 (7.20.7–8))。
   - EEC の推力補正（NAI・WAI の抽気分を補う）(FCOM p.876 (7.20.6))。補正量は PI の表（ICE-11）。

### 4.2 主翼防氷（WAI）

1. 指令: WAI スイッチ ON かつ空中（空地リレー R227）で WAI リレー R7536 が入り、115V AC で両弁を開く。地上と off では閉 (ATA30_32_35_36 p.176、LH36 p.120–122、FCOM p.625)。
2. 弁はモーター駆動なので、ダクト圧に関係なく開閉する。翼に空気が流れるかはダクト圧次第で、ECS synoptic の流れバーは「弁が開で空気源がある」とき (LH36 p.124)。
3. LE フラップ: FCOM は「LE フラップが出ていると WAI は効かない」とだけ書く (FCOM p.633、p.208 (SP.16.8))。E&M は「LE フラップが完全に上でないと弁の作動を禁止」と書く (ATA30_32_35_36 p.176)。LH36 は LE フラップ条件を AUTO 位置にだけ付けており、ON 位置には付けていない (LH36 p.114・p.116・p.122)。FCOM の構成（AUTO なし）では LE フラップで禁止しない（LH36 に従う）。
4. 開閉は 3 s 未満 (LH36 p.126)。
5. 表示: VALVE 灯は「どちらかの弁の位置がスイッチ位置と不一致」(FCOM p.626)。回路では不一致リレー（R7534/R7535、R7427/R7428）が WAI リレー（指令）と弁位置を比べている (ATA30_32_35_36 p.178、LH36 p.123 の図)。地上でスイッチ ON のとき VALVE 灯が点くかは資料で確定できない（指令基準なら点かないと推定）。WAI VALVE LEFT/RIGHT は 5 s 遅延 (ATA30_32_35_36 p.184)。主 EICAS の WAI は弁が開のとき (FCOM p.633)。
6. 整備用の地上試験（CMC から弁を 7 s 開く）は実装不要 (ATA30_32_35_36 p.180)。

### 4.3 氷検知（109・570）

- 空中だけで働く。地上では回数が 0 のまま (ATA30_32_35_36 p.161)。
- >ICING: 氷を検知。>NO ICING: 検知しなくなった。>ANTI-ICE は「防氷 ON、TAT >12°C、氷を検知していない」(FCOM p.635)。
- FCOM の構成で「検知中」をどう定義するか（何回、何秒保持）は資料に記載なし。AUTO 構成の NAI 出力（2 回または 15 s 超で、最後の回から 180 s 保持、3 分以上回が無ければ 0 に戻す）を「検知中」として使う案（推定）。
- 故障: ヒーター 25 s 超または 149°C 超で出力停止 → >ICE DETECTORS（§3.4 の食い違いあり）。

### 4.4 窓加熱

- 前面窓: スイッチ ON → 制御器が徐々に電力を上げ、所定温度で一定に保つ。故障（過熱、センサー・ヒーター不良、電源喪失）で電力を切り INOP (FCOM p.628・p.633、ATA30_32_35_36 p.246–248)。HEAT WINDOW L/R は窓に電力が来ていないとき (FCOM p.635)。
- スイッチ off のときに INOP 灯と HEAT WINDOW が出るか: FCOM は INOP を「電力が切れている」でも点くと書くので、off でも点くと推定（要確認）。
- off 10 s → ON で制御器の故障をリセット (FCOM p.633)。
- 側窓: 115V AC があれば常に自動。乗員の操作も表示も無い（STATUS の WINDOW HEAT 2L/2R だけ）(ATA30_32_35_36 p.258–260)。

### 4.5 プローブ加熱

| プローブ | 地上・全エンジン停止 | 地上・どれかのエンジン運転 | 飛行中 | 根拠 |
|---|---|---|---|---|
| 主ピトー静圧（CAPT/F/O） | 切 | ストラットは全電力、ヘッドは減電力 | 全電力 | ATA30_32_35_36 p.216 |
| 補助ピトー静圧（L/R AUX） | 切 | 同上（エンジン 50% RPM で） | 全電力 | ATA30_32_35_36 p.220 |
| AOA（L/R） | 切 | 入 | 入 | ATA30_32_35_36 p.232 |
| TAT（L/R） | 切 | 切 | 入 | ATA30_32_35_36 p.226 |

- FCOM の要約: ピトー静圧 4 本と AOA 2 個はどれかのエンジンが運転中なら加熱、TAT 2 個は飛行中に加熱 (FCOM p.634 (3.20.4))。
- メッセージは電流センサーで「通電すべきなのに電流が無い」とき（推定: 加熱の指令が無いときは出さない）。HEAT TAT は地上で加熱してしまっているときも出る (FCOM p.635)。

### 4.6 ワイパー・ウォッシャー・防雨剤

- ワイパー: OFF で格納位置まで戻って止まる。LO 160 回/分、HI 250 回/分 (ATA30_32_35_36 p.264・p.272)。乾いた窓で使うと傷が付く (FCOM p.633)。
- ウォッシャー: 保持中だけ (FCOM p.634)。
- 防雨剤（109）: 1 回押すと決まった量。誤って乾いた窓に出したらウォッシャーを先に使う (FCOM p.219 (SP.16.19))。

### 4.7 使用基準（SP.16。ロジックではなく、メッセージの意味と試験の目安）

- 着氷条件: 地上は OAT、飛行中は TAT が 10°C 以下で、目に見える水分（雲、視程 1 sm 以下の霧、雨、雪など）があるか、滑走路などに氷・雪・水があるとき (FCOM p.202 (SP.16.2))。
- NAI: 地上で OAT >10°C、飛行中で TAT >10°C では使わない。着氷条件では全エンジン始動後すぐ ON。-40°C 未満では不要 (FCOM p.202–203・p.206)。
- WAI: TAT >10°C では使わない。主な使い方は除氷（付いてから ON）(FCOM p.207–208)。
- 地上の運転: NAI 必要かつ OAT 3°C 以下なら、PW（109/405）は 50% N1 で約 1 秒を 15 分以内ごと、GE（570）は 60% N1 で約 30 秒を 30 分以内ごと。離陸前にも同様 (FCOM p.204・p.206・p.211)。
- GE のファンの氷落とし: 中程度以上の着氷で N1 70% 以下が続くときなど、10 分ごとに 70% N1 以上を 10–30 秒 (FCOM p.207 (SP.16.7))。
- 強い雨・雹（109）: TAT 10°C 以下なら NAI ON（連続点火と進入アイドル）、それ以外は連続点火 ON (FCOM p.213 (SP.16.13))。

## 5. 他系統とのつながり

- ATA 36（抽気）: NAI は各エンジンの PRV 下流から、WAI は左右のダクト区画から。現コードは `laminar/B747/air/engineN/bleed_air_psi`、`laminar/B747/air/engineN/bleed_start_valve_pos`、`laminar/B747/air/duct_pressure_L/R` を読む（B747.50.xt.antiice.lua:103-115）。PRV の開条件に NAI スイッチが入る。
- ATA 74/80（点火・始動）: NAI ON で連続点火。現コードは X-Plane の inlet heat の状態（=弁が開）で点火器を入れている（B747.40.xt.engines.lua:1890-1980）。FCOM はスイッチ ON で点火を選ぶと書く (FCOM p.631)。
- ATA 73（EEC）: 進入アイドル（B747.42.xt.EEC.PW.lua:55-61、GE.lua:67-72、RR.lua:55-60 は NAI 弁全開で判定）、推力補正（ICE-11）。
- ATA 27: LE フラップが出ていると WAI は効かない。
- ATA 32（空地）: WAI の地上禁止、TAT の加熱、氷検知の地上停止。現コードは `sim/flightmodel/failures/onground_any` を使用。
- ATA 24（電源）: §2 の各バス。
- ATA 31（EICAS）: §3.4 のメッセージと遅延、主 EICAS の NAI/WAI（acf は X-Plane の ice dataref を参照）、ECS synoptic。
- ATA 34（航法）: ピトー・AOA・TAT の加熱が X-Plane のプローブ着氷に効く。TAT は地上で抽気による吸引が無いと高く出る (FCOM p.212)。
- X-Plane の着氷モデル: `sim/cockpit2/ice/*` のスイッチ類が X-Plane 側の着氷を防ぐ。acf の `acf/_esys_amperage/rel_dice_*` で X-Plane は各ヒーターを電気負荷として扱う（主翼 5 A ずつ、窓 4 A など。どのバスかは acf の設定次第）。

## 6. 実装上の注意

- 名前を変えてはいけないもの
  - INTERFACES.tsv: コマンド `laminar/B747/button_switch/anti_ice_nacelle_1`〜`_4`、`anti_ice_wing`、`anti_ice_window_L`・`_R`、`laminar/B747/antiice/wndshlsd_wiper_L`・`_R` の `sel_dial_up`・`sel_dial_dn`、`laminar/B747/toggle_switch/windshield_washer_L`・`_R`。dataref `laminar/B747/antiice/wndshlsd_wiper_L/R/sel_dial_pos`、`laminar/B747/button_switch/position`、`laminar/B747/toggle_switch/position`。
  - INTERFACES.tsv に無いが acf が参照するもの: `laminar/B747/antiice/nacelle/valve_pos`（4 要素）、`laminar/B747/antiice/wing/valve_pos`（2 要素）。X-Plane の `sim/cockpit2/ice/ice_inlet_heat_on_per_engine[0-3]`、`sim/cockpit2/ice/ice_surfce_heat_left_on`・`_right_on` も主 EICAS の NAI/WAI 表示に使われているので、弁の状態どおりに出し続ける。
  - 他モジュールが読むもの: `laminar/B747/antiice/nacelle/valve_pos`（EEC と照明）、`sim/cockpit2/ice/ice_inlet_heat_on_per_engine`（エンジンの点火）。
  - AI 用: `laminar/B747/ai/antiice_quick_start`、`laminar/B747/ice/init_CD`。
- X-Plane 側の使い方
  - 主翼は左右別のコマンド `sim/ice/wing_heat0_on/off`・`wing_heat1_on/off`（X-Plane 12 の Commands.txt にある）か、`ice_surfce_heat_left_on/right_on` を直接書く。左右共通の `sim/ice/wing_heat_on/off` は使わない（ICE-01）。
  - X-Plane には抽気式の `ice_surface_hot_bleed_air_left_on/right_on` もあるが、acf の WAI 表示は電熱式の `ice_surfce_heat_*` を見ているので、少なくとも後者は書き続ける。どちらが X-Plane の着氷除去に効くかは要確認。
  - プローブ: `ice_pitot_heat_on_pilot/copilot/standby`、`ice_static_heat_on_*`、`ice_AOA_heat_on`・`_copilot`、`ice_TAT_heat_on`・`_copilot`。故障は `rel_ice_pitot_heat1/2`、`rel_ice_static_heat/2`、`rel_ice_AOA_heat/2`。L/R AUX を X-Plane の standby に当てるかは推定。
  - 窓: `ice_window_heat_on_window[4]`（窓ごと）と故障 `rel_ice_window_heat`・`_cop`・`_l_side`・`_r_side`。
  - 氷検知: `ice_detect_on` と `sim/cockpit2/annunciators/ice`。故障は `rel_ice_detect`。
  - ワイパー: `sim/cockpit2/switches/wiper_speed_switch[2]` は 0 = 格納、1 = 25%、2 = 50%、3 = 100%。実際の速さは acf のワイパー設定による（要確認）。3D のワイパーは `sim/flightmodel2/misc/wiper_angle_deg` で動いている。
- EICAS の遅延（3.5 s、5 s、15 s）はこのモジュールで持つ。警報モジュールには遅延の仕組みが無い。
- 単純化してよいもの: NAI の過熱・圧力スイッチ（故障注入用だけ）、氷検知器の内部（回数と保持時間だけ）、窓加熱制御器の内部、整備用の地上試験、STATUS メッセージ。
- 単純化してはいけないもの: スイッチと VALVE 灯の論理、WAI の地上禁止、NAI が抽気（PRV、始動弁）に依存すること、§3.4 のメッセージ、NAI/WAI の表示用 dataref、点火と進入アイドルへの出力。
- AUTO 構成は作らない。将来 3D に AUTO 付きスイッチを入れる場合は LH36 p.106–116 の論理を使う。

## 7. 現状実装との比較（GAP 候補）

該当コードの略記: ICE = `plugins/xtlua/scripts/B747.50.xt.antiice/B747.50.xt.antiice.lua`、ICEI = `plugins/xtlua/init/scripts/B747.50.antiice/B747.50.antiice.lua`、LIT = `plugins/xtlua_keysystems/scripts/B747.90.xt.lighting/B747.90.xt.lighting.lua`、WRN = `plugins/xtlua/scripts/B747.87.xt.warning/B747.87.xt.warning.lua`、EEC = `plugins/xtlua/scripts/B747.42.xt.EEC/`、MAN = `plugins/xtlua/scripts/B747.01.xt.manipulators/B747.01.xt.manipulators.lua`。

| ID | 種別 | 重要度 | 規模 | 内容 | 根拠 | 該当コード |
|---|---|---|---|---|---|---|
| ICE-01 | バグ | 中 | S | 主翼防氷を X-Plane へ渡すのに左右共通のコマンド（`sim/ice/wing_heat_on/off`）を使っているため、左右の弁が食い違う（例: 片側のダクト圧が 12 psi 以下）と毎フレーム ON と OFF が入れ替わる。主 EICAS の WAI がちらつき、X-Plane の除氷も半分しか効かない | FCOM p.633、X-Plane 12 Commands.txt（wing_heat0/1 がある） | ICE:168-169、ICE:432-445 |
| ICE-02 | 挙動の誤り | 中 | S | WAI 弁の開条件に「ダクト圧 >12 psi」が入っている（実機はモーター弁で、空中かつスイッチ ON で開く）。弁はほぼ瞬時に動く（実機は 3 s 未満）。ダクト圧が低い側は VALVE 灯が点く。地上でスイッチ ON でも VALVE 灯が点く（指令基準なら点かないと推定） | FCOM p.625-626、LH36 p.120-126、ATA30_32_35_36 p.176-178 | ICE:398-427、LIT:1313-1323 |
| ICE-03 | バグ | 中 | S | >ANTI-ICE が出ない。条件の真偽にかかわらず両方の分岐で 0 を書いている。条件も OAT を使い（FCOM は TAT）、`or simDR_wing_heat_on_R` は Lua では 0 でも真になる | FCOM p.635 | ICE:487-503 |
| ICE-04 | 欠落 | 中 | S | NAI VALVE 1–4 と WAI VALVE LEFT/RIGHT が未実装（表だけある）。エンジン運転中の条件と遅延（3.5 s、5 s）も必要 | FCOM p.635、ATA30_32_35_36 p.184・p.206 | WRN:428-431、WRN:482-483 |
| ICE-05 | 挙動の誤り | 中 | M | NAI 弁が「スイッチ ON、エンジン抽気 >12 psi、始動弁閉」だけで開く。PRV 側の条件（過熱ラッチ、ENGINE BLEED off 時の HPSOV failed open、始動弁閉後 15 s、火災スイッチ）、NAI ダクトの過熱ラッチ、逆推力中の閉（E&M）、28V DC が無い。抽気側（PNEU-02）と一緒に直す | FCOM p.576・p.612・p.614・p.625、LH36 p.48、ATA30_32_35_36 p.198・p.202 | ICE:302-348 |
| ICE-06 | 欠落 | 中 | S | プローブ加熱: AOA と TAT のヒーターを X-Plane に出していない。ピトー静圧の加熱を「どれかのエンジン抽気 >12 psi」で代用（実機はエンジン運転、TAT は飛行中、地上は減電力）。HEAT L/R AOA は着氷量の比率 `aoa_ice`（0–1）を 6 と比べているので出ない。HEAT L/R TAT、HEAT P/S L/R AUX は未実装 | FCOM p.634-635、ATA30_32_35_36 p.216-234 | ICE:84-94、ICE:284-299、ICE:505-535 |
| ICE-07 | 欠落 | 中 | S | 窓加熱: HEAT WINDOW L/R が未実装。INOP 灯は「スイッチ ON かつ X-Plane の窓加熱故障」のときだけ（FCOM は電力が切れても点灯）。左右を X-Plane の 1 系統（`sim/ice/window_heat_on/off`）にまとめている。off 10 s→ON のリセット、電源の判定が無い | FCOM p.627-628・p.633・p.635、ATA30_32_35_36 p.246-250 | ICE:453-469、LIT:1325-1326 |
| ICE-08 | 欠落 | 低 | S | 氷検知: >NO ICING、>ICE DETECTORS が未実装。>ICING は X-Plane の ice アナンシエーターをそのまま使い、空中だけ・保持時間の扱いが無い | FCOM p.631・p.635、ATA30_32_35_36 p.161-164、LH36 p.106-108 | ICE:479-485 |
| ICE-09 | 挙動の誤り | 低 | S | ワイパーの速さ: LO→X-Plane の 1（25%）、HI→2（50%）。実機は LO 160・HI 250 回/分。28V DC の電源判定も無い | ATA30_32_35_36 p.264・p.272、X-Plane 12 DataRefs.txt | ICE:185-193 |
| ICE-10 | 欠落 | 低 | S | ウォッシャーは押しても効果なし。防雨剤（109）と WSHLD AIR は操作子も無い | FCOM p.627-629・p.633-634 | MAN:1211-1219 |
| ICE-11 | 挙動の誤り | 中 | M | 防氷の推力補正: PW はナセル防氷の補正がコメントアウトされ、PI の EPR 補正（engine anti-ice、engine & wing anti-ice）が無い。GE は Go-around の NAI 補正（PI.20.32）だけを離陸・上昇・巡航に使い、主翼防氷の補正が無い（PI.20.31 には高度別の上昇補正がある）。FCOM は EEC が NAI・WAI の抽気分を補うと書く | FCOM p.876 (7.20.6)、p.261-262 (PI.10.35-36)、p.358-360 (PI.20.30-32) | EEC/B747.42.xt.EEC.PW.lua:557-562、EEC/B747.42.xt.EEC.GE.lua:511-516、EEC/B747.42.xt.EEC.tbls.lua:103-106 |
| ICE-12 | バグ | 低 | S | init の型が `"array[4)"`・`"array[2)"`（括弧の誤り）。Lua 側は末尾 1 文字を捨てて数を読むので動くが、XTLua 本体側の解釈は未確認 | — | ICEI:65-66、EEC/B747.42.xt.EEC.lua:260 |
| ICE-13 | 欠落 | 低 | S | 防氷・防雨の電源依存（WAI は AC bus 2 + DC bus 2、氷検知は AC bus 1/3、窓は 115V AC + 28V DC、プローブは 115V AC、ワイパーは 28V DC）を見ていない | LH36 p.106・p.112、ATA30_32_35_36 p.216・p.248・p.272 | ICE:302-469 |

ACF_DIFF.md との関係: 防氷に関わる acf 値（`_bleed_draw_dice_engn`・`_dice_wing`、`_esys_amperage/rel_dice_*`）は純正とカスタムで同じ。差分項目にこの系統の項目は無い。コードは acf の値を読んでいない。

## 8. 作り直しか部分修正か

作り直しを勧める。

- ロジック部分（ICE:284-539）は 250 行ほどで、ICE-01〜ICE-08 の誤りがほぼ全体に散っている。抽気モジュール（ATA-36）を作り直すと入力（エンジン側の圧、PRV の状態、ダクト圧）の意味も変わるので、合わせて書き直すほうが速い。
- そのまま残してよいのはワイパーのコマンド処理（ICE:185-219）。速さの対応（ICE-09）だけ直す。
- 守るもの: §6 の名前（INTERFACES.tsv、acf の SHOW_* 条件、主 EICAS が読む X-Plane の ice dataref）、`button_switch/position` と `brightness_ratio` の添字。
- 順序: 抽気モジュールの出力が決まってから。EEC の推力補正（ICE-11）は EEC の担当と分担する。

## 9. 未確認事項

- 左右別の `sim/ice/wing_heat0/1_on` が X-Plane 12 で主翼の左右に別々に効くか。電熱式（`ice_surfce_heat_*`）と抽気式（`ice_surface_hot_bleed_air_*`）のどちらが X-Plane の除氷に効くか（シムで確認）。
- `"array[4)"` の dataref が正しく 4 要素で作られているか（DataRefEditor などで確認）。
- ワイパーの X-Plane 側の速さ（acf の設定）と、LO・HI に当てる値。
- 地上で WAI スイッチ ON のとき VALVE 灯が点くか。WINDOW HEAT off のとき INOP と HEAT WINDOW が出るか。
- FCOM の構成で >ICING・>NO ICING をどの時間で出し消しするか（資料に記載なし）。
- >ICE DETECTORS が片方の故障で出るか、両方で出るか（E&M と LH36 が食い違う）。
- PW 機で逆推力中に NAI 弁が閉じるか（E&M の記述だけ）。NAI の圧力スイッチ（>30 psig）が出す EICAS メッセージ名。
- HEAT L/R AOA が FCOM 3.30 の表に無い理由（機体構成の違いか、表の省略か）。
