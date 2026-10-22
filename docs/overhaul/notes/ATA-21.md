# ATA 21 空調・与圧・機器冷却（Air Conditioning, Pressurization, Equipment Cooling）

GAP ID：`AIR-nn`。2026-10-23 調査。コードと acf は変更していない。

## 1. 概要

- 範囲：パック弁から下流。パック、流量スケジュール、再循環ファン、トリム空気とゾーン温度、貨物室暖房、与圧（CPC A/B、手動、着陸高度、外流弁、正負圧リリーフ、客室高度警報）、機器冷却（NORM/STBY/OVRD、煙）、ECS synoptic と EICAS メッセージ。
- 抽気（エンジン抽気弁、隔離弁、APU 抽気、地上空気、ダクト圧）は ATA 36 の担当。ここでは接続点（ダクト圧の入力、パック需要）だけ扱う。現行コードでは抽気も同じファイル（`B747.55.xt.air.lua:424-791`）にある。
- 基準の型：FCOM の機体番号 109（旅客型・PW）（FCOM p.5 (0.1.1)）。405/570（貨物機）の下部貨物室空調・FLT DECK FAN などは扱わない。
- ATA21 はある航空会社の整備訓練資料で、温度表示が °C（ATA21 p.29, 250）、前方貨物室空調オプション（21-27）がある。FCOM 109 と違う所はその旨を書いた。
- 使った資料
  - FCOM 2.10 p.553–586、2.20 p.587–606、2.30 p.607–610、2.50 p.619–622、SP.2 p.167–170、NP.21 p.107–108・123・126・130・153、L.10 p.77・79。関連して 2.40 p.613–614、7.30 p.895、8.10 p.908、10.10 p.993、11.30 p.1233、11.43 p.1400、15.10 p.1532、15.20 p.1551。
  - ATA21：21-00 p.3–30、21-50 p.31–114、21-20 p.115–204、21-40 p.229–258、21-60 p.337–392、21-30 p.393–484、21-58 p.485–616。21-23（combi の flapper）、21-29（overhead crew rest の ACU）、21-27（前方貨物室空調）は相互作用だけ拾った。図は p.29, 139, 141, 385, 389, 425, 429, 433, 437, 449, 453, 609, 611 を描画して確認した。
  - コード：`plugins/xtlua_keysystems/scripts/B747.55.xt.air/B747.55.xt.air.lua`（1220 行）、`plugins/xtlua_keysystems/init/scripts/B747.55.air/B747.55.air.lua`（170 行）。関連：manipulators、lighting、EEC、Avionics、warning、acf のパネル定義、`747-400_cockpit.obj`、`fmod/747-400.snd`、X-Plane の `Resources/plugins/DataRefs.txt`。

## 2. 構成

### 2.1 パック
- 3 基、中央翼下の非与圧部。pack 1・2 は左、pack 3 は右（ATA21 p.16 (21-00)）。
- 供給元：pack 1 = 左ダクト、pack 2 = 中央ダクト、pack 3 = 右ダクト（FCOM p.590 (2.20.4) 図、ATA21 p.29 (21-00) 図）。
- 主要部品：flow control and shutoff valve（FCSOV）、熱交換器（primary/secondary）、ACM、turbine bypass valve（TBV）、ram air inlet/exit door、水分離器（ATA21 p.37–44, 54 (21-50)）。
- FCSOV：電気で制御し空圧で動く。ばねで閉。開くには 12 psi 以上が要る。ソレノイドは ON/OFF 用と normal/high 用の 2 個（ATA21 p.40, 42 (21-50)）。
- PTC（pack temperature controller）A・B：各 3 チャンネル。1 台が制御し、他方は監視（ATA21 p.26 (21-00), p.110 (21-50)）。
  - 電源：A は 28V DC bus 3 と 115V AC bus 3、B は bus 4（ATA21 p.84 (21-50)）。
- ECS miscellaneous card：CPC の飛行段階（climb/cruise/descent）を PTC と ZTC に渡す（ATA21 p.76, 110 (21-50), p.382 (21-60)）。

### 2.2 分配・再循環・温度制御
- 温度ゾーンは 7 つ：F/D、U/D、A〜E（FCOM p.587 (2.20.1)）。
  - A は door 1 より前、B は door 1–2、C は 2–3、D は 3–4、E は door 4 より後（ATA21 p.206 (21-23)）。
  - F/D は zone E の riser から分岐する（ATA21 p.14 (21-00), p.152 (21-20)）。
- 制御器：ZTC（zone temperature controller）1 台、zone A alternate controller 1 台（ATA21 p.26 (21-00)）。
- トリム空気
  - master trim air PRSOV：中央ダクトから取り、客室圧 + 10 psig に調圧する（ATA21 p.346 (21-60), FCOM p.591 (2.20.5)）。
  - ゾーンごとの trim air modulation valve 7 個（115V AC）（ATA21 p.354 (21-60)）。
- 再循環ファン：上 2 基・下 2 基。115V AC 3 相、制御は 28V DC、各 1360 cfm（ATA21 p.126–134 (21-20), p.386 (21-60)）。
- cabin temperature panel：door 2R にある客室乗務員用（FCOM p.591 (2.20.5)）。
- その他：gasper fan、lav/galley vent fan（後方機器冷却を兼ねる）、humidifier、foot/shoulder heater、WSHLD AIR（FCOM p.558–559, 571–572 (2.10); ATA21 p.164–200 (21-20)）。これらの操作部は 3D 操縦室に無い（`747-400_cockpit.obj` の manipulator を確認）。

### 2.3 貨物室暖房
- 後方（aft・bulk）：中央ダクトの抽気を使う（FCOM p.602 (2.20.16)）。
  - override（shutoff）弁と control 弁（115V AC）。
  - 温度選択スイッチ 40°F/65°F（bulk 貨物室内）。90°F で過熱（ATA21 p.232–244 (21-40)）。
- 前方：機器冷却の排気（inboard exhaust 弁が開のとき）と電気ヒーター 2 個（ATA21 p.254–256 (21-40); FCOM p.602）。

### 2.4 与圧
- CPC（cabin pressure controller）A・B：どちらも左右両方の外流弁を制御する（FCOM p.607 (2.30.1)）。
  - 電源：A は 28V DC bus 1、B は 28V DC bus 2（ATA21 p.437 図 (21-30)）。
- ICU 2 台：左右の弁に 1 台ずつ（ATA21 p.400, 406 (21-30)）。
- 外流弁 2 個：bulk 貨物室の後ろ。AC モーターが自動用、DC モーターが手動用。位置はポテンショメーターで取る（ATA21 p.410–418 (21-30)）。
- 手動系の電源：28V DC battery bus（CABIN PRESS MAN）と APU hot battery bus（OUTFLOW VALVE）（ATA21 p.449 図）。
- M181 CABIN PRESSURE SELECTOR（P5）。
- 正圧リリーフ弁 2 個、負圧リリーフドア 4 枚（前後の貨物ドア）（ATA21 p.398, 462, 472 (21-30)）。
- 前方 overboard valve：CPC が制御する通風用の弁（ATA21 p.156–158 (21-20)）。
- CPC への入力（ATA21 p.435–437 (21-30)）
  - FMC（左右を FMC select switch で選ぶ）
  - ADC（静圧。気圧補正は機長側が primary）
  - air/ground relay（primary と alternate）
  - AP・VNAV の状態

### 2.5 機器冷却
- 前方系（ATA21 p.498–600 (21-58)、p.611 図）
  - supply fan・exhaust fan：115V AC、各約 1300 cfm。
  - 弁：inboard supply・inboard exhaust・bypass（115V AC）、ground exhaust（115V AC bus 1）、smoke/override（28V DC main battery bus）、E6/E9（28V DC bus 1）。弁の制御電源は 28V DC bus 2。
  - センサー：skin temperature switch（45°F）、overheat switch（130°F）、low flow detector 2 個、smoke detector、差圧スイッチ（OVRD 用）。
  - equipment cooling card：弁が指令位置にあるかを監視する。
- 後方系：lav/galley vent fan（primary/secondary）で吸い出し、外流弁から機外へ出す（ATA21 p.490–496 (21-58)）。

## 3. 操作と表示

### 3.1 オーバーヘッドの ECS パネル（109）と sim の対応
`button_switch/position[n]` の番号は `B747.01.xt.manipulators.lua:766-812` による。ノブの値の意味は `Cockpit_OH1.obj` の回転キーから読んだ。

| 操作 | 実機の機能（要点） | 根拠 | sim の名前・値 | 現状 |
|---|---|---|---|---|
| PASS TEMP | AUTO：C–W で 65–85°F（18–29°C）の master 温度を決める。ALTN：ゾーン弁は最後の位置のまま、master trim 弁は開のまま、ZTC を迂回、パック出口で平均 75°F、cabin temp panel を禁止 | FCOM p.554 (2.10.2) | `air/pass_temp_ctrl/rheostat` 0..1。3D ノブは C–W の弧だけで、ALTN に回せない | 初期化で 0.5 を書くだけ |
| FLT DECK TEMP | AUTO：65–85°F。MAN（6 時位置、ばね戻り）：C/W で F/D の trim 弁を手で動かす | FCOM p.554 | `air/flt_deck_temp_ctrl/rheostat` 0..1。MAN 位置は無い | 同上 |
| ZONE RST / SYS FAULT | 押す：ZTC をリセットし、overheat が消えていれば master trim 弁を再び開く。灯の点灯条件：ダクト過熱、ZTC 故障、master trim 弁の閉故障、TRIM AIR off | FCOM p.555 (2.10.3) | cmd `button_switch/temp_zone_rst`（[36]、モメンタリ）。灯は `annunciator/brightness_ratio[69]` | 灯は TRIM AIR off のときだけ点く（`B747.90.xt.lighting.lua:1333`） |
| TRIM AIR | ON：master trim 弁を開き、ゾーン弁は自動。PTC A/B の選択を許す。Off：master trim 弁を閉じて backup 制御、PTC は A 固定（A 故障なら B） | FCOM p.555–556 | `temp_trim_air`（[37]） | 灯だけ |
| UPR / LWR RECIRC | ON：自動制御。Off：停止 | FCOM p.556 (2.10.4) | `temp_recirc_upr` / `temp_recirc_lwr`（[38]/[39]） | 効果なし |
| AFT CARGO HT / TEMP | ON：overheat shutoff 弁を開き、control 弁で温度を保つ。TEMP 灯（amber）：過熱で shutoff 弁が閉じた | FCOM p.557 (2.10.5) | `temp_aft_cargo_ht`（[40]）。灯は [70] | 効果なし、灯は常に 0 |
| EQUIP COOLING | STBY / NORM / OVRD（4.6 参照） | FCOM p.557–558 | `air/equip_cooling/sel_dial_pos`：0=STBY、1=NORM、2=OVRD | `equip_cooling/state` を書くだけ |
| HI FLOW | ON：運転中の全パックを high flow にし、memo PACKS HIGH FLOW を出す | FCOM p.558 (2.10.6) | `temp_hi_flow`（[41]） | memo だけ |
| PACK RST / SYS FAULT | 押す：保護系をリセットし、原因が消えていれば自動停止したパックを再起動。灯：パック過熱など | FCOM p.560 (2.10.8) | `temp_pack_rst`（[42]、モメンタリ）。灯は [71] | 効果なし、灯は常に 0 |
| PACK 1/2/3 | OFF：弁を閉じ、その SYS FAULT を消し、保護系をリセット。NORM：便ごとに A/B を交互に使う。A/B：主 controller を指定（故障なら他方） | FCOM p.560 | `air/pack_ctrl/sel_dial_pos[0..2]`：0=OFF、1=NORM、2=A、3=B。cmd `pack_ctrl_0N/sel_dial_up/dn` | memo・音・synoptic の OFF/A/B だけ |
| GASPER、HUMID | ON で作動 | FCOM p.558–559 | 3D に操作部なし | なし |

### 3.2 CABIN ALTITUDE パネル（M181）

| 操作・表示 | 機能 | 根拠 | sim の名前・値 | 現状 |
|---|---|---|---|---|
| LDG ALT スイッチ | 押すたびに AUTO/MAN が切り替わる。MAN：ノブで設定し、EICAS に MAN と LANDING ALT advisory。AUTO：FMC の値 | FCOM p.573 (2.10.21) | `air/landing_alt/button`、`button_pos`：1=AUTO、0=MAN | 切替だけ |
| LDG ALT ノブ | MAN のとき設定する。-1,000〜+14,000 ft、50 ft 刻み | FCOM p.573, 608; ATA21 p.426 | `air/land_alt_sel/rheostat`。obj の manipulator は 0〜5000（`747-400_cockpit.obj:22164`） | 値をそのまま着陸高度にしている |
| OUTFLOW VALVES 計 | OP–CL | FCOM p.574 (2.10.22) | `air/outflow_valve_left/pos`、`.../right/pos` -1..1。針は ±90°（`Cockpit_OH1.obj:137141`） | 客室 V/S から作った値 |
| MAN L / MAN R | ON：その弁を手動にする。自動制御と高度リミッタを迂回 | FCOM p.574 | `button_switch/press_outflow_vlv_L/R`（[34]/[35]） | 片側だけでも全体が手動になる |
| OPEN / CLOSE | 押している間、手動の弁を開／閉の方向へ動かす | FCOM p.574 | `toggle_switch/outflow_valve_open/close`（toggle [22] = +1/-1） | 1 フレームに 0.005 ずつ |
| AUTO SELECT | NORM：A/B を交互に使う。A/B：主 controller を指定 | FCOM p.574 | `air/cabin_alt_auto/sel_dial_pos`：0=NORM、1=A、2=B | アニメーションだけ |
| placard | MAX ΔP .11 PSI T/O & LDG | FCOM p.573 図、L.10 p.79 | — | — |

### 3.3 主 EICAS の ECS data block
- 内容：DUCT PRESS L/R、CAB ALT、RATE、LDG ALT と AUTO/MAN、ΔP（FCOM p.585 (2.10.33)）。
- 表示条件（FCOM p.585）
  - LDG ALT が MAN
  - 客室高度が amber か red の範囲
  - ΔP が amber か red の範囲
  - ECS または ENG synoptic を選んでいる
- ATA21 はこれに次を加える（ATA21 p.451 (21-30)）：BLD DUCT LEAK、CABIN ALT AUTO、OUTFLOW VLV、LANDING ALT、両 CPC 故障、FMC 着陸高度の喪失、ダクト圧 11 psi 未満、客室高度 7,400 ft 超、ΔP +8.9 超、客室昇降率（上昇 700 fpm 超・降下 500 fpm 超）。
  - FCOM と矛盾しないものは採用する。客室高度のしきい値だけは FCOM の amber 範囲（8,500 ft）を採る。
- 色（ATA21 p.451–452; FCOM p.585–586）
  - CAB ALT：白 −2,000〜8,499、amber 8,500〜9,999、red 10,000 以上。
  - ΔP：白 −0.4〜+8.8、amber +8.9〜+9.0 と −0.5〜−0.9、red +9.1 以上と −1.0〜−2.0。
  - DUCT PRESS：白 12 psi 以上、amber 11 psi 以下。
- LDG ALT：両 controller 故障か、両外流弁 MAN のときは表示しない（FCOM p.586 (2.10.34)）。AUTO は白、MAN は amber。
- パネル定義：`747-400.acf:124702-125054`。上の色分けは実装済み。

### 3.4 ECS synoptic（下 EICAS）
- 要素（109）（FCOM p.576–578 (2.10.24–26)）
  - ゾーン温度 F/D・U/D・A〜E：左が target、右が actual。target は「1 パック以上運転中・PASS TEMP が AUTO・backup でない」ときだけ出す。
  - MASTER（PASS TEMP の設定値）、FWD/AFT 貨物室の実温度。
  - 外流弁の位置と MAN/AUTO。
  - HI FLOW。
  - パック記号：OFF＝弁が閉、A/B＝使用中の controller。
  - EXT AIR。
  - ダクト圧、WAI/NAI、隔離弁・APU 弁・エンジン抽気弁、流れの線。流れの線は弁・スイッチ・パック状態から作る表示で、実際の流れではない。
- 外流弁の表示は MAN で amber、AUTO で白（ATA21 p.420 (21-30)）。
- 温度単位：FCOM の図は °F、ATA21 の図は °C（ATA21 p.29, 250）。
- AFT 貨物室の温度は aft と bulk の平均（ATA21 p.248 (21-40)）。
- 現状のパネル（`747-400.acf:135167-136142` の "ECS Synoptic"）
  - 抽気側（エンジン、NAI/WAI、ダクト圧、流れの線、隔離弁、APU 弁、パックの OFF/A/B）だけを描く。
  - 背景画像（`cockpit_3d/generic/CRT Displays/EICAS Lower/ECS/background-1.png`）にはゾーン枠・MASTER・FWD/AFT・外流弁計が描いてある。しかし数字と針を出す計器が無い。
  - `hiflow`・`ext_air`・`temp_c`・`temp_f` の画像はあるが使っていない。

### 3.5 EICAS メッセージ
CAS 番号は `B747.87.xt.warning.lua` の表による（行 74, 118, 135, 273, 383, 426, 435–440, 444, 470, 473, 480, 511–518）。BLD DUCT LEAK、BLEED n、>BLEED n OFF などは ATA 36 の担当。

| メッセージ | 種別 | 条件 | 根拠 | 番号・現状 |
|---|---|---|---|---|
| CABIN ALTITUDE | warning（siren、master WARNING） | 客室高度 10,000 ft 超 | FCOM p.619 (2.50.1), p.1551 (15.20.5); ATA21 p.474–480 | warning[1]。実装済み（`air:943`） |
| CABIN ALT AUTO | caution（beeper） | 両 CPC 故障、または両外流弁 MAN ON | FCOM p.619 | caution[10]。片側 MAN で出る（誤り） |
| EQUIP COOLING | caution（beeper） | NORM/STBY で流量不足・過熱・煙。OVRD で逆流冷却の差圧不足。ground exhaust 弁が指令位置にない | FCOM p.619; ATA21 p.530, 548, 578, 598 | caution[27]。未実装 |
| >E/E CLNG CARD | advisory | 機器冷却カードの故障。飛行中は出さない | FCOM p.619; ATA21 p.510 | adv[87]。未実装 |
| >HUMID FLT DK | advisory | F/D humidifier の故障 | FCOM p.619 | adv[197]。未実装（humidifier が無い） |
| LANDING ALT | advisory | controller と FMC の着陸高度が違う、または MAN | FCOM p.620 (2.50.2) | adv[240]。未実装 |
| OUTFLOW VLV L, R | advisory | その弁の自動制御ができない、または MAN ON | FCOM p.620 | adv[249]/[250]。スイッチの分だけ実装 |
| PACK 1, 2, 3 | advisory | PTC 故障、パック動作の異常、過熱、またはリリーフ弁が開いて pack 2 が止まった | FCOM p.620; ATA21 p.102（両 PTC が 30 s 制御していない等） | adv[252–254]。未実装 |
| PACK CONTROL | advisory | 全パックの出口温度の自動制御が故障 | FCOM p.620 | adv[251]。未実装 |
| PRESS RELIEF | advisory | 全パック運転中にリリーフ弁が開いた（ATA は「運転中のパックが high flow 指令中」） | FCOM p.620; ATA21 p.470 | adv[258]。未実装 |
| TEMP CARGO HEAT | advisory | 後方暖房の運転中に過熱（90°F 超） | FCOM p.620; ATA21 p.252 | adv[284]。未実装 |
| TEMP ZONE | advisory | ゾーンダクト過熱、master trim 弁の閉故障、ZTC 故障。master trim 弁を閉じ backup | FCOM p.620 | adv[287]。未実装 |
| >TRIM AIR OFF | advisory | master trim 弁が閉。全パック off のときは出さない | FCOM p.621 (2.50.3); ATA21 p.350 | adv[294]。未実装 |
| PACK n OFF、PACKS 1+2 / 1+3 / 2+3 OFF、PACKS OFF | memo | 選択器が OFF | FCOM p.622 (2.50.4) | memo[18–23], [25]。実装済み（`air:1009-1062`） |
| PACKS HIGH FLOW | memo | HI FLOW スイッチ ON | FCOM p.622 | memo[24]。実装済み |

- ATA21 では、PACK n OFF の memo は PACK n advisory が出ていれば出さない（ATA21 p.102）。
- 補助 EICAS の status メッセージ（ATA21 p.92, 102, 144, 160, 350, 444, 454, 470, 476, 496, 528–598）は ECS 側にも STATUS ページ側にも無い。
  - 例：CABIN ALT AUTO A/B、CPCS AIR/GND、CPCS BACKUP SENS、UPR/LWR PRESS RELIEF、PACK CONTROL A/B、RECIRC FAN UPR/LWR L/R、ZONE TEMP、EE CLNG …、EQUIPMENT SMOKE、LAV-GALLEY FANS。

## 4. 内部ロジック

### 4.1 パック
1. 弁の開閉
   - 選択器が NORM・A・B なら pack control relay が落ち、弁は空圧で開く。OFF なら relay が入って閉じる（ATA21 p.86 (21-50)）。
   - 開くにはダクト圧 12 psi 以上が要る（ATA21 p.42）。
2. 流量
   - normal は high の 2/3。HI FLOW スイッチで運転中の全パックが high（ATA21 p.86; FCOM p.558）。
   - 自動で high にする条件：地上、上昇、降下、運転パック 3 基未満、再循環ファン故障。巡航が確立すると normal（ATA21 p.86, 90）。
3. 出口温度
   - 最も冷たい要求のゾーンに合わせる（FCOM p.591; ATA21 p.74, 110）。
   - 下限は 25,000 ft 未満で 35°F、25,000 ft 超で 28°F（高度は CPC の値）。上限 135°F（ATA21 p.38, 90）。
4. ram door：地上では全開、飛行中は調節、閉じるのは飛行中にパック OFF のときだけ（ATA21 p.70, 81）。
5. controller の選択
   - NORM は便ごとに A/B を交互に使う（FCOM p.560）。接地で他方の PTC に切り替わる（FCOM p.588 (2.20.2)）。
   - あるチャンネルが故障すると、選択器の位置に関係なく他方へ切り替わる（FCOM p.588; ATA21 p.81）。
   - TRIM AIR off のときは A 固定（FCOM p.556）。
   - 両 PTC が故障してもパックは動き続け、過熱保護も働く（FCOM p.589 (2.20.3)）。
6. 保護（ラッチ）
   - pack discharge（ACM 出口）185°F、compressor discharge 425°F（425°F スイッチが働かなければ温度センサーで 15 s 後に閉）、ram door と TBV の順序異常（out-of-sequence）で FCSOV を閉じる。
   - SYS FAULT 灯と advisory を出す。冷えた後に PACK RST でリセット（ATA21 p.78, 82, 94）。
   - 選択器 OFF でもリセットされる（FCOM p.560）。
7. 過圧：リリーフ弁が開くと pack 2 の FCSOV を閉じ、pack 1・3 を high にする。pack 2 はリリーフ弁が両方閉じると自動で戻る（ATA21 p.94; FCOM p.609 (2.30.3)）。
8. 貨物室火災 ARM：pack 3 を止め、pack 1・2 を high にする（ATA21 p.94; FCOM p.908 (8.10.4)）。
9. PACK n advisory の論理：両 PTC が 30 s 制御していない、pack 出口過熱、compressor 出口過熱、順序異常、FCSOV 故障（ATA21 p.102）。
10. 燃料への影響：パック 1 基を normal flow にすると約 0.3% 減る（FCOM p.588）。HI FLOW で燃料流量が約 1% 増える（FCOM p.168 (SP.2.2)）。

### 4.2 流量スケジュールと再循環ファン
- 地上・初期上昇・降下：パックは high、上ファン 2 基 ON、下ファン 2 基 OFF（ATA21 p.138 (21-20), p.386 (21-60)）。
- 巡航
  - cruise clamp：FMS 高度の 100 ft 以内、または ±100 fpm 未満が 45 s を超えたとき。25,000 ft 超でだけ有効で、ラッチし、地上でリセット（ATA21 p.382, 386）。
  - cruise clamp でパックを normal にし、下ファンも ON（計 4 基）（ATA21 p.386）。
  - 客室温度が target から 1°C 以上ずれている間は normal への切替を待つ。ただし最長 20 分（ATA21 p.386）。
- 降下
  - descent detect（FMC の T/D、または 1,000 ft 降下）でパックを high、下ファンを OFF（ATA21 p.382, 387）。
  - 降下中に ±250 ft・2 分の高度保持があると cruise clamp になり、normal・下ファン ON。その後の降下で再び high・下ファン OFF（ATA21 p.387）。降下量の数値は原文で欠落している。
- 切替の順序：パックの流量は 15 s 間隔、ファンは 5 s 間隔（ATA21 p.387, p.389 図）。
- 電源 ON で全パック OFF のとき：4 基とも運転（ATA21 p.389 図, p.139 図）。
- 故障時の表（ATA21 p.139・141 図）。ファン番号：上 1＝右、上 2＝左、下 1＝左、下 2＝右。
  - 地上・上昇・降下：上ファンが 1 基故障すると、下ファン 1 基を ON（上 1 故障なら下 1、上 2 故障なら下 2）。上 2 基故障なら下 2 基。パック 1 基が故障・OFF なら残り 2 基が high、ファン 4 基。全パック OFF ならファン 4 基。
  - 巡航でファン 1 基故障：上 1 または上 2 なら pack 2 を high、下 1 なら pack 1 を high、下 2 なら pack 3 を high。他のパックは normal。
  - ファン 2 基故障：全パック high、残り 2 基のファンが運転。
  - パック 1 基 OFF とファン 1 基故障：残り 2 パック high、ファン 3 基。
  - 前方・後方の貨物室火災：pack 1・2 high、pack 3 OFF、ファン全停止。
- HI FLOW スイッチ ON で 3 パック high のとき、ファンを 2 基止める（ATA21 p.23 (21-00)）。
- RECIRC スイッチ OFF（故障ではない）を high flow の条件に数えるか：資料に記載なし。
- ファン監視：電流センサーで見る。status メッセージは上 10 s、下 60 s の遅れ（ATA21 p.142–144）。
- ファンの 28V DC 制御電源は貨物室火災 ARM で切れる（ATA21 p.134）。
- 上記の切替条件の基になる飛行段階（cruise clamp と descent detect）は CPC が作る（ATA21 p.74, 382）。

### 4.3 温度制御
- target 温度
  - PASS TEMP で master 65–85°F。cabin temp panel でゾーンごとに ±10°F（65–85°F の範囲内）。panel が効くのはエンジン 2 基以上運転中（FCOM p.591 (2.20.5)）。
  - ATA は「どれか 1 基運転中か飛行中」とする（ATA21 p.338, p.385 図）。FCOM を採る。
- comfort bias（ATA21 p.384 (21-60), p.385 図; FCOM p.591）
  - cruise clamp かつ 25,000 ft 超のとき、target を 2°F/h で 2 時間上げる（最大 +4°F、上限 85°F）。
  - descent detect で 5 分以内に戻す。最初の descent detect の後は使えない。
  - 手で選び直すと、その値で上書き。
- 通常制御
  - パック出口は最も冷たいゾーンの要求に合わせる。他のゾーンには trim 空気を足す。ゾーンダクトの温度センサーで補正する（ATA21 p.362）。
  - master trim PRSOV は TRIM AIR が ON で、パックが 1 基以上運転しているときに開く（ATA21 p.346, 348）。
  - 中央ダクトが隔離されると trim 空気は無い（FCOM p.591, p.614 (2.40.4)）。
- FLT DECK MAN
  - ZTC を迂回し、C/W で F/D の trim 弁を動かす。離すと止まる（ATA21 p.366）。
  - MAN の間は F/D を「最も冷たいゾーン」の判定から外す（ATA21 p.366）。
- ダクト過熱（ATA21 p.348, 360）
  - overheat スイッチ 185°F が 10 s：PRSOV をラッチで閉じ、SYS FAULT、TEMP ZONE、backup。ZONE RST で解除（原因が消えていれば）。
  - 温度センサー 165°F が 30 s：advisory。185°F が 15 s：advisory と SYS FAULT。
- backup without trim air
  - 入る条件：ダクト過熱、PRSOV の閉故障、TRIM AIR off、ZTC の重大故障（ATA21 p.368）。
  - ゾーン弁は 10% 開に固定。PTC がパック出口を制御して客室の平均温度を合わせる（ATA21 p.368）。
  - 目標温度：PASS TEMP の値（65–85°F）。それが使えなければ最後の設定値、それも無ければ 75°F（FCOM p.592 (2.20.6)）。ATA は 75°F としか書いていない（ATA21 p.368）ので、FCOM を採る。
  - F/D は最高 85°F（ATA21 p.368）。
  - APU が抽気源なら、APU に最大流量を要求する（ATA21 p.368）。
- ALTN（PASS TEMP）
  - ゾーン弁は最後の位置のまま。master trim 弁は開のまま。パック出口で平均 75°F（FCOM p.554）。
  - zone A は専用の controller が 75°F に保つ（ATA21 p.370, 374）。
  - 飛行中は U/D・B〜E の 125°F 過熱スイッチを有効にし、その弁を閉じる（ATA21 p.370, 378）。
  - ZTC が故障しても、自動で ALTN にはならない（ATA21 p.370）。
- target が出せないときの表示：target を空白にする（3.4）。
- 温度変化の動特性（ゾーン温度の時間変化）：資料に記載なし。

### 4.4 貨物室暖房
- 後方（ATA21 p.240–244 (21-40); FCOM p.557, 602）
  - AFT CARGO HT を ON にすると override 弁が開く（区画温度が 90°F 以下のとき）。control 弁は選択温度（40°F または 65°F）でサーモスタットのように開閉する。
  - 動くのはエンジン運転中だけ（ATA21 p.242）。
  - 90°F を超えると両弁を閉じ、TEMP 灯（地上では点かない）と TEMP CARGO HEAT を出す（ATA21 p.244, 252）。
  - 後方の貨物室火災 ARM で両弁を閉じる（ATA21 p.240, 242）。
  - スイッチは、APU や地上空気の抽気を始動に回すため、エンジン始動後まで OFF にしておく（FCOM p.602）。
- 前方（ATA21 p.256）
  - 前方貨物室の温度スイッチが 50°F で開き 40°F で閉じて、ヒーターの回路を入り切りする（ATA21 p.254）。
  - 条件：inboard exhaust 弁が開、エンジン 2 基が 50% 以上。
  - ヒーター内部のサーモスタット（180°F・225°F）は保護用（ATA21 p.256）。

### 4.5 与圧

| モード | 入る条件 | 客室・弁の動き | 根拠 |
|---|---|---|---|
| ground | 地上 | 外流弁全開。客室＝場の高度 | ATA21 p.412, 428 |
| takeoff | 地上で GS 65 kt 超。65 kt 未満に戻れば ground | 500 fpm（公称）で場の高度 −50 ft まで下げる。弁は少し閉 | ATA21 p.412, 428, p.429 図。p.435 は「各翼 1 発が N2 45% 超」でも入ると書く（不一致） |
| climb | air/ground が air | 外部（FMC）：巡航時の客室高度へ一定率で上げる（最大 600 sea-level fpm）。率は FMC の time to climb から決め、途中の水平飛行も時間に含める。内部：巡航 39,000 ft を仮定、最大 1,000 fpm。FMC の経路より上を飛んで ΔP が最大になったら、機体の上昇率に合わせて ΔP を超えないようにする | FCOM p.607 (2.30.1); ATA21 p.428, 435 |
| cruise | FMC 巡航高度の 100 ft 以内。内部では上昇率 100 fpm 未満が 45 s（p.436 は 1 分） | 客室を ±25 ft に保つ。ΔP は最大 8.9 psi。客室の最高高度 8,000 ft。離陸場が 8,000 ft より高いときは、上昇中に巡航時の客室高度まで下げる | FCOM p.608 (2.30.2); ATA21 p.431, 436 |
| descent | FMC の T/D、または巡航高度から約 1,000 ft 降下（内部は 1,000±50 ft） | 着陸高度の少し下に向けて客室を上げ下げする。外部：機体の降下率に見合う率。内部：公称 300 fpm（250〜450）。±250 ft・2 分の高度保持中は、着陸高度か降下開始時の ΔP まで客室を下げ続ける。その後 ±500 ft 以上変われば climb/descent に戻る | FCOM p.608; ATA21 p.431 |
| 着陸後 | 接地（air→ground） | 接地時の客室は場の高度 −50 ft。500 fpm で減圧し、1 分後から 2,000 fpm、外気と同じになるまで。外流弁全開 | FCOM p.608; ATA21 p.432 |

- 着陸高度
  - AUTO では FMC の値を使う。FMC が目的地の値を送るのは、出発地から 400 NM 超・経路の半分超・T/C 通過・T/D の 2 分前・T/D 通過のどれかを過ぎたとき。それまでは出発地の値（FCOM p.1400 (11.43.12), p.993 (10.10.31)）。
  - approach を選ぶまでは目的地空港の標高を使う（FCOM p.1400）。
  - FMC から値が来ず MAN でもなければ、2,000 ft を仮定し LANDING ALT を出す。EICAS には 2000 AUTO と出る（FCOM p.608; ATA21 p.452）。
  - MAN では FMC を使わず、controller 内部の率スケジュールで制御する（FCOM p.608）。
  - 範囲は −1,000〜14,000 ft（FCOM p.608）。気圧補正は機長の高度計規正値（FCOM p.608; ATA21 p.437 図）。
  - 着陸場が 8,000〜10,000 ft のとき：上昇・巡航中は MAN 8,000 ft にしておき、降下前に AUTO に戻す（FCOM p.169 (SP.2.3), p.608）。
- CPC が受け取る FMC のデータ：巡航高度、着陸場高度、time for climb、time until T/D、time for descent、AP mode、FMC master、VNAV mode、engine speed（ATA21 p.437 図）。
  - 時間の情報は AP が入っているときだけ有効。AP が入るまでは内部スケジュールを使う（ATA21 p.435）。
  - FMC が故障したら内部スケジュール。左右の FMC の切替は手動（ATA21 p.436）。
- CPC の選択（ATA21 p.426, 432, 436）
  - 電源投入時は A。NORM では ground mode に入ると A と B を入れ替え、電源を切るまでその controller が担当する。電源を入れ直すと A に戻る。touch-and-go のように電源が途切れなければ、入れ替えた側のまま次の区間を飛ぶ。
  - 次の 3 つで他方が引き継ぐ：機体高度が変わらないのに客室の変化率が 2,000 ft/min、ΔP が 9.07 psi 超、電源断が 2 s 超。
  - 両方が auto enable なら A。
- 客室高度リミッタ
  - ICU の高度スイッチが 11,000±500 ft で両外流弁を閉方向へ動かす。作動点の 750 ft 下で解除。自動モードだけ（ATA21 p.406, 442）。
  - MAN はリミッタも迂回する（FCOM p.574, 608）。
- 手動
  - MAN L/R でその弁の AC モーターを止めてブレーキをかけ、OPEN/CLOSE を押している間だけ DC モーターで動かす。左右は別々に動く（ATA21 p.446–448）。
  - 両方 MAN なら自動機能はすべて迂回する。このときと「片側だけ自動で他方が不動」のときは、パックを 1 基 OFF にする（FCOM p.608–609）。
  - 弁の動く速さ：資料に記載なし。
- リリーフ
  - 正圧：9.25 psid（遠隔検知）で開く。9.75 psid（本体）は予備。blowout door は開いたままになる（ATA21 p.462–466）。FCOM の限界は 9.4 psi（FCOM p.79 (L.10.3)）。
  - 開くと pack 2 を止める（両方閉じれば戻る）。PRESS RELIEF を出す（FCOM p.609, 620）。
  - 負圧：0.2〜0.4 psi で開き始め、1 psi で全開（ATA21 p.472）。
- 警報：10,000 ft で CABIN ALTITUDE。siren、master WARNING、CAB ALT が赤。master WARNING/CAUTION reset で消音（FCOM p.1532 (15.10.6), p.1551; ATA21 p.474–480）。
- 限界：離着陸時の最大 ΔP は 0.11 psi（FCOM p.79）。
- 巡航時の客室高度
  - 最大運用 ΔP は 8.9 psid。45,000 ft なら客室は 7,300 ft（ATA21 p.424, p.425 図）。
  - 巡航中、客室は「できるだけ低く」保つ。FMC の巡航高度から決まった ΔP スケジュールで客室高度を決める（ATA21 p.424, 435）。
  - 推定（ATA21 p.424 の例と p.425 の図から）：巡航時の客室高度は、FMC 巡航高度で ΔP 8.9 psi になる高度（上限 8,000 ft）。実機のスケジュール表は資料に記載なし。
- 前方 overboard valve（ATA21 p.158）
  - 閉：takeoff、25,000 ft 未満の climb、descent detect、客室 11,000 ft、前方貨物室火災。
  - 開：cruise、降下中の高度保持、ground、25,000 ft 超の climb。
  - 乗員向けの表示は status（FWD OVBD VLV）だけ。

### 4.6 機器冷却
- NORM、地上、エンジン停止：skin temperature が 45°F（7°C）超なら ground exhaust を開き inboard exhaust を閉じて機外へ。45°F 未満なら ground exhaust を閉じ inboard exhaust を開いて前方貨物室へ（FCOM p.605 (2.20.19) 図; ATA21 p.512, 538, 546）。
- 各翼 1 基以上のエンジンが運転すると flight 構成（ground exhaust 閉、前方貨物室へ）（FCOM p.603 (2.20.17); ATA21 p.512, 546）。FCOM p.557 は「2 基以上」と書くが、p.603 と ATA を採る。
- STBY：ground exhaust を閉にする以外は NORM と同じ。NORM で ground exhaust が閉じないときに使う（FCOM p.557; ATA21 p.504, 550）。
- ファン 1 基故障（NORM/STBY）
  - closed loop に組み替える：inboard supply・inboard exhaust・ground exhaust を閉じ、bypass を開く。EICAS メッセージは出ない（FCOM p.605 図; ATA21 p.552–556）。
  - 10 s 回らなければ故障と判定。リセットは OVRD に 30 s 置いて戻す（ATA21 p.524）。
- OVRD（飛行中に使う）
  - ファン停止。inboard supply/exhaust・ground exhaust・bypass を閉じ、smoke/override 弁を開く。客室の差圧で逆向きに空気を流し機外へ出す（FCOM p.558, 604 (2.20.18); ATA21 p.580–584）。
  - 差圧スイッチは OVRD のときだけ有効。55 s の遅れで EQUIP COOLING（ATA21 p.594–598）。地上で OVRD にすると差圧が無いので出る（推定）。差圧のしきい値は資料に記載なし。
- 異常（ATA21 p.560–578）
  - overheat 130°F（120°F で自動復帰。地上では 55 s 後に ground crew call horn）。
  - low flow 2 か所、smoke。
  - いずれも EQUIP COOLING と status を出し、対処は OVRD。
- EQUIP COOLING（ground exhaust の位置不一致）：NORM、地上、各翼 1 基以上が運転しているのに flight 構成になっていない（FCOM p.604; ATA21 p.548）。
- clean mode：NORM、飛行中、10 回目の descent detect、パック 2 基以上で、2 分間 OVRD 構成にする（ATA21 p.508, 600–602）。乗員向けの表示は無い。
- 後方系：lav/galley fan は電源が入ると自動で回る。primary が 5 s 回らなければ secondary（ATA21 p.200, 494）。

### 4.7 貨物室火災 ARM のときの空調（109）
- FWD または AFT を ARM（FCOM p.908 (8.10.4); ATA21 p.141 図）
  - pack 3 を止め、pack 1・2 を high。
  - 再循環ファンを全部止める。
  - 機器冷却を OVRD 構成にする。FWD なら E6/E9 弁も閉じる（ATA21 p.580, 590）。
  - 前方貨物室への気流と暖房を止める。
- AFT は後方暖房も止める（FCOM p.908; ATA21 p.240–242）。
- lav/galley fan も止まる（ATA21 p.200, 494）。gasper fan は fire cutoff relay で止まる（ATA21 p.170）。この relay が貨物室火災 ARM で入るというのは推定。
- sim の ARM スイッチは `button_switch/position[84]`（FWD）・`[85]`（AFT）（`B747.01.xt.manipulators.lua:978-984`）。

## 5. 他系統とのつながり

| 相手 | 方向 | 内容 | 根拠 |
|---|---|---|---|
| ATA 36 抽気 | 入力 | 左・中央・右のダクト圧（pack 1/2/3）。trim 空気と後方暖房は中央ダクト。中央が隔離されると trim 空気と後方暖房が無くなり、全ゾーンが backup without trim air になる | FCOM p.590 図, 591, 614 |
| ATA 36 / APU | 出力 | パックの空気需要。APU はエンジン始動中以外なら全パックを賄える。飛行中は 15,000 ft まで 1 パック。ZTC は APU に流量を要求し、ZTC 故障時は最大を要求する | FCOM p.895 (7.30.1); ATA21 p.18, 112, 368 |
| ATA 24 電源 | 入力 | CPC A＝DC bus 1、B＝DC bus 2。手動＝battery bus と APU hot battery bus。PTC A＝bus 3、B＝bus 4。機器冷却の弁と fan の電源 | ATA21 p.84, 437, 449, 611 図 |
| air/ground | 入力 | 与圧モード、地上の ram door 全開、TEMP 灯の抑止、機器冷却の構成。PTC は primary と alternate が食い違うと 75 s 後に status を出し、空中側に倒す。CPC も食い違いで status | ATA21 p.74, 92, 244, 428, 454 |
| FMC | 入力 | 巡航高度、着陸高度（400 NM・半分・T/C・T/D の切替）、時間の情報、VNAV。現行の FMC はどれも出していない | FCOM p.1233 (11.30.1), 1400; ATA21 p.437 |
| ADC・高度計 | 入力 | 静圧、機長の規正値（着陸高度の補正） | ATA21 p.437; FCOM p.608 |
| AFDS | 入力 | AP が入っているか（時間の情報を使う条件） | ATA21 p.435 |
| ATA 26 火災 | 入力 | 貨物室火災 ARM（4.7） | FCOM p.908 |
| ATA 31 EICAS | 出力 | CAS の状態（3.5）、data block、synoptic、警報音 | — |
| EEC（ATA 73） | 出力 | 運転中のパック数と high flow。推力の抽気補正に使う | `B747.42.xt.EEC.PW.lua:547` |
| 照明・サイン | 出力 | `sim/cockpit2/pressurization/indicators/cabin_altitude_ft` が 10,000 ft を超えると No Smoking と Seat Belt の AUTO が点く | `B747.90.xt.lighting.lua:169, 1615, 1641` |
| ATA 35 酸素 | 出力 | 客室高度約 14,000 ft で乗客酸素が作動（ATA 35 の担当） | FCOM p.456 (1.30.22) |

## 6. 実装上の注意

- X-Plane の与圧モデル
  - 現状は X-Plane 内蔵の与圧に任せている。acf の値は両 acf で同じ（`_auto_pressurization 1`、`_max_press_diff 9.4`、`_dump_press_below_1k 1`、`_dump_press_wow 0`、`_has_full_bleed_air 0`。`747-400.acf:81878, 82994, 83637, 83843`、`747-400_custom.acf:71589, 72705, 73348, 73554`）。ACF_DIFF.md に空調関係の差は無い。
  - コードは actuator（`cabin_altitude_ft`、`cabin_vvi_fpm`、`max_allowable_altitude_ft`）を書くだけ。auto pressurization 有効のときにこれがどう扱われるかは不明。
  - 推奨：`sim/operation/override/override_pressurization` を使い、自前で客室圧を計算して `sim/cockpit/pressure/cabin_altitude_actual_ft`・`cabin_vvi_actual_fpm`・`outflow_valve` に書く。
  - この override はダクトの `bleed_available_*` と `engine_loss_from_bleed_air_ratio` の書込みも同時に乗っ取る。ATA 36 と所有者を一本化すること。
  - パネル（`indicators/cabin_altitude_ft`・`cabin_vvi_fpm`・`pressure_diffential_psi`）と照明モジュールは indicator 側を読む。override 中に indicator が自前の値を映すか、最初に確認する。
- 客室の計算は質量収支で作る
  - パック流入 − 外流弁の流出 − 漏れ（＋リリーフ）で客室圧を出し、CPC は昇降率を目標に弁位置を動かす。
  - こうすると、手動モード、全パック OFF、リリーフ、ICU リミッタが同じ式から自然に出る。弁位置もそのまま計器に出せる。
  - パック流量、客室容積、弁の面積、漏れは資料に記載なし。調整値にする。
  - 標準大気の気圧と高度の換算は、資料外の一般式を使う。ATA21 p.425 図の表（0 ft 14.7、10,000 ft 10.11、30,000 ft 4.36、45,000 ft 2.14 psia）で検算できる。
  - X-Plane の減圧故障（`rel_depres_slow`・`rel_depres_fast`）は漏れの増加として受ける。
  - 空中でフライトを始めたときは、客室をスケジュール上の値で初期化する。そうしないと CABIN ALTITUDE が出る。
- 名前と意味を変えないもの（INTERFACES.tsv）
  - `air/pack_ctrl/sel_dial_pos`：0..3。音は 1 以上を「ON」として使う（`fmod/747-400.snd:6300-6340`）。
  - `air/outflow_valve_left|right/pos`：-1..1。外装の obj は 0..1 と -1..1 の両方で使う。どちらの端が OP かは要確認。
  - `air/landing_altitude`：ft。`air/landing_alt/button_pos`：1=AUTO。
  - `air/cabin_alt_auto/sel_dial_pos`：0..2。`air/equip_cooling/sel_dial_pos`：0..2。
  - 温度ノブ 3 本：0..1。
  - コマンド名（3.1・3.2 の表）。
- INTERFACES.tsv の漏れ（パネルが読むが表に無い、または panel の印が無い）
  - `laminar/B747/air/duct_pressure_C`、`engine1..4/bleed_air_psi`、`engine1..4/bleed_valve_pos`、`pressurization/EICAS1_display_status`。
  - `landing_alt/button_pos` と `pack_ctrl/sel_dial_pos[i]` も、acf のパネルが読んでいる。
- 新しく要る dataref（案）
  - パック：弁位置、high flow、使用中の PTC、故障。
  - 温度：ゾーンの target/actual ×7、MASTER、FWD/AFT 貨物室温度。
  - 再循環ファンの運転状態、外流弁の AUTO/MAN、使用中の CPC、与圧モード、EXT AIR 表示。
  - EEC 向け：運転中のパック数。
  - synoptic に出すにはカスタム acf のパネル追加が要る（承認事項）。
- LDG ALT ノブ
  - obj の manipulator は 0〜5000 で変えられない（3D は対象外）。
  - rheostat の変化量だけを拾って本当の着陸高度（-1,000〜14,000 ft、50 ft 刻み）に足し、rheostat を中央へ戻すと、範囲を全部使える。
- PASS TEMP の ALTN と FLT DECK の MAN
  - 3D ノブでは選べない。必要ならキー割当て用のコマンドを足すが、操作部が無いので優先度は低い。
  - `cargo_temp_ctrl/rheostat`（3D にある）は、109 にない前方貨物室空調用。何にも使わないか、オプションとして扱う。
- 簡略化してよいもの
  - ACM・TBV・ram door の内部動作、水分離器、clean mode、前方 overboard valve、crew rest、gasper、humidifier、補助ヒーター。
  - ゾーン温度の熱的な動き（一次遅れで十分）。
  - パック出口温度は、最も冷たい要求と限界値（35/28/135°F）だけ守ればよい。
- 簡略化してはいけないもの
  - 与圧のモードと数値（65 kt、−50 ft、600/1,000 fpm、8.9 psi、8,000 ft、T/D・1,000 ft、300/250/450 fpm、500→2,000 fpm、11,000±500/−750 ft、9.25 psid、10,000 ft）。
  - 着陸高度の出所と LANDING ALT、CPC A/B の切替、手動の弁操作、パック ON/OFF が与圧に効くこと。
  - high/normal の切替（HI FLOW 表示と燃料）、貨物室火災 ARM の再構成、地上で OVRD にしたときの EQUIP COOLING。
  - EICAS メッセージの条件と抑止、data block と synoptic の表示条件。
- 動きはすべて SIM_PERIOD で正規化する。現行の手動弁は 1 フレーム 0.005 で、フレームレートに依存している。
- 電源の判定：ATA 24 の作り直し後は、バスごとの状態（DC 1/2/3/4、battery、APU hot battery、AC 1/3/4）で CPC・PTC・手動系・機器冷却を個別に落とす。

## 7. 現状実装との比較（GAP 候補）

コードの行番号は、断りのない限り `plugins/xtlua_keysystems/scripts/B747.55.xt.air/B747.55.xt.air.lua`。

| ID | 種別 | 重要度 | 規模 | 内容 | 根拠 | 該当コード |
|---|---|---|---|---|---|---|
| AIR-01 | 欠落 | 高 | M | パック弁のモデルが無い。選択器（OFF/NORM/A/B）は memo・音・synoptic に使うだけ。弁の開閉、12 psi 未満で開かないこと、トリップ、流量（normal＝high の 2/3）が無い。X-Plane にもパック状態を渡していない（`sim/cockpit2/bleedair/actuators/pack_*` を書かず、`bleed_air_mode` はダクト圧だけで 0/2/4 を決める）。全パック OFF でも与圧が続くと推定 | FCOM p.560, 588; ATA21 p.42, 86 | :770-791, :1009-1062 |
| AIR-02 | 挙動の誤り | 高 | M | 自動与圧のスケジュールが実機と別物。客室の目標は min(8000, 機長の指示高度) で、機体が 8,000 ft に達するまで与圧しない。客室昇降率は機体 V/S を 500〜2,000 fpm に挟んだ値。takeoff（65 kt・−50 ft）、FMC による上昇（≤600/1,000 fpm）、巡航 ΔP 8.9、descent（T/D・1,000 ft）、着陸高度への降下、着陸後の減圧が無い。上昇中に客室 V/S が 700 fpm を超えるので、data block が毎回自動で出る（推定）。進入中の負の ΔP も出うる（推定） | FCOM p.607–608; ATA21 p.424, 428, 431–432, 435–436 | :806-866（:808, :844-845）、:917 |
| AIR-03 | 欠落 | 高 | M | 着陸高度。AUTO は固定 2,000 ft で、FMC との連携も LANDING ALT advisory も無い。MAN は 3D ノブの範囲 0〜5,000 ft をそのまま使う（実機は -1,000〜14,000 ft、50 ft 刻み）。着陸高度を与圧制御に使っていない。FMC 側に着陸高度・巡航高度・T/D を渡す仕組みが無い | FCOM p.573, 608, 620, 1400; ATA21 p.426, 437, 452 | :873-885; `747-400_cockpit.obj:22164` |
| AIR-04 | バグ | 高 | M | 手動モード。MAN L/R の片側でも系統全体が手動になる。弁は 1 フレームに 0.005 動く（フレームレート依存）。客室昇降率を弁位置の絶対値だけで決め、目標は機体高度なので、CLOSE で客室を下げられない。片側だけ手動にして他方を自動に残す動きも無い | FCOM p.574, 608–609; ATA21 p.446–448 | :811-839 |
| AIR-05 | 挙動の誤り | 高 | S | CABIN ALT AUTO を MAN スイッチ片側 ON で出している。FCOM では、両 CPC 故障か、両方 MAN のとき | FCOM p.619; ATA21 p.454 | :947-953 |
| AIR-06 | 挙動の誤り | 中 | S | 客室高度リミッタが 11,000 ft 超で常に働き（MAN でも）、昇降率 2,000 fpm を書く。実機は自動のときだけ、ICU が 11,000±500 ft で両弁を閉じ、750 ft 下で解除する。MAN は迂回 | FCOM p.574, 608; ATA21 p.406, 442 | :854-859 |
| AIR-07 | 欠落 | 中 | M | CPC A/B が無い。NORM/A/B、便ごとの交代（着陸で切替、電源投入で A）、引継ぎ条件（2,000 fpm・9.07 psi・電源断 2 s）、電源（DC 1/2）。AUTO SELECT ノブは動くだけ | FCOM p.574, 607; ATA21 p.426, 432, 437 | :241-250 |
| AIR-08 | 欠落 | 中 | M | 正圧リリーフ（9.25/9.75 psid。FCOM 限界 9.4）が開いたときの pack 2 停止と PRESS RELIEF、負圧リリーフ（0.2〜0.4 psi で開き始め、1 psi で全開）が無い。X-Plane の `_max_press_diff` 9.4（両 acf 同じ）任せ | FCOM p.79, 609, 620; ATA21 p.462–472 | なし |
| AIR-09 | 挙動の誤り | 中 | S | 外流弁計を客室 V/S から作っている（-2,000 fpm→+1、+2,000 fpm→-1）。実機の弁位置（地上で全開、65 kt で少し閉、巡航で調節）ではない。地上でも中央を指す | ATA21 p.412, 420, p.429・433 図 | :846-847, :863-864 |
| AIR-10 | 欠落 | 中 | M | 温度制御が全く無い。PASS / FLT DECK / CARGO の各ノブは初期値 0.5 を書くだけ。ゾーンの target/actual、トリム空気（master PRSOV とゾーン弁）、ALTN・MAN、backup（PASS TEMP 値 → 最後の値 → 75°F）、comfort bias、TRIM AIR OFF・TEMP ZONE が無い。TRIM AIR スイッチは zone SYS FAULT 灯を点けるだけ | FCOM p.554–556, 591–592, 620–621; ATA21 p.338, 346–370, 384 | :1108-1110; `B747.90.xt.lighting.lua:1333` |
| AIR-11 | 欠落 | 中 | M | パック流量のスケジュール（地上・上昇・降下 high、cruise clamp で normal、3 基未満やファン故障で high、パック間 15 s・ファン間 5 s）と再循環ファンの論理（ATA21 p.139・141 の表）が無い。HI FLOW は memo だけ。UPR/LWR RECIRC は効果なし | FCOM p.558, 588–589; ATA21 p.23, 86, 138–141, 382, 386–389 | :1064-1070 |
| AIR-12 | 欠落 | 中 | M | パック保護（185°F・425°F・順序異常でラッチ停止）、PACK RST、PACK SYS FAULT 灯（常に 0）、PACK n と PACK CONTROL、PTC A/B の自動切替が無い | FCOM p.560, 588–589, 620; ATA21 p.94, 102 | `B747.90.xt.lighting.lua:1335` |
| AIR-13 | 欠落 | 中 | M | 機器冷却。`equip_cooling/state` を書くだけで、誰も読んでいない。NORM/STBY/OVRD の弁構成、45°F の判定、各翼 1 基運転で flight 構成、EQUIP COOLING（地上で OVRD・ground exhaust 不一致・低流量・過熱・煙）、貨物室火災 ARM で自動 OVRD が無い | FCOM p.557–558, 603–605, 619; ATA21 p.504–598 | :793-799 |
| AIR-14 | 欠落 | 低 | S | 後方貨物室暖房。スイッチに効果が無く、TEMP 灯（annun [70]）は常に 0。TEMP CARGO HEAT も貨物室温度も無い | FCOM p.557, 602, 620; ATA21 p.234–252 | `B747.90.xt.lighting.lua:1334` |
| AIR-15 | 欠落 | 高 | M | ECS synoptic の上半分が無い。ゾーン温度・MASTER・FWD/AFT・外流弁計の枠は背景にあるが、数字と針の計器が無い。HI FLOW・EXT AIR・MAN/AUTO も無い（画像はある）。パックの OFF/A/B は選択器の位置で出しており、実機の「弁閉＝OFF／使用中の PTC」と違う。A は「1 < pos < 2」の条件なので、NORM と A で出ない可能性がある。直すにはカスタム acf のパネル追加（承認が要る） | FCOM p.576–578; ATA21 p.28–29, 100, 420 | `747-400.acf:135167-136142`（A の条件は 135698 付近） |
| AIR-16 | バグ | 中 | S | EEC の packs 補正が、パック数を選択器の値の合計で数えている（A＝2、B＝3 で多く数える）。選択器ではなく、運転中のパック数を使うべき | FCOM p.560（選択器の位置） | `B747.42.xt.EEC.PW.lua:547`、`GE.lua:501`、`RR.lua:732` |
| AIR-17 | 欠落 | 中 | S | 貨物室火災 ARM 時の空調の組替え（pack 3 停止・1/2 high・再循環ファン全停止・機器冷却 OVRD・AFT なら後方暖房停止）が無い。air は `button_switch/position[84]`・`[85]` を読んでいない | FCOM p.908, 589; ATA21 p.94, 134, 141, 240–242, 580 | なし |
| AIR-18 | 挙動の誤り | 低 | S | ECS data block。自動表示の条件に、負の ΔP（−0.5 以下）と LANDING ALT が無い。両 CPC 故障・両 MAN のとき LDG ALT を消せない（パネルに条件が無い）。右ダクト圧の白表示の条件が左ダクト圧になっている（acf。ATA 36 と共通） | FCOM p.585–586; ATA21 p.451–452 | :892-922; `747-400.acf:124780` |
| AIR-19 | バグ | 低 | S | 初期状態。ER 開始で EQUIP COOLING が STBY（0）のまま（CD で 0 を書き、ER で NORM にしない）。RECIRC が ON にならない。manipulators の ER で TRIM AIR の位置を [83] に書いている。`sim/cockpit2/Cooling/Packs_EXT` は A/B を数えず、誰も読まない | FCOM p.107–108 (NP.21.13–14) | :1121-1143; `B747.01.xt.manipulators.lua:2176-2178`; `Avionics.lua:43-49` |
| AIR-20 | 挙動の誤り | 中 | M | X-Plane 内蔵の与圧に依存。override を使わず、actuator の書込みがどう扱われるか分からない。減圧故障（`rel_depres_*`）や X-Plane のパック・抽気モデルとの関係も整理されていない。ATA 36 と方針を決める必要がある | 6 章の acf 値; X-Plane DataRefs.txt | :122-138, :806-866 |
| AIR-21 | 欠落 | 低 | S | 電源との関係。与圧と温度制御は電源と無関係に動く（機器冷却だけが bus_volts[0] を見る）。実機は CPC A＝DC 1、B＝DC 2、手動＝battery と APU hot battery、PTC A＝bus 3、B＝bus 4 | ATA21 p.84, 437, 449, 611 | :794, :806-866 |
| AIR-22 | 欠落 | 低 | M | ECS の status メッセージ（CABIN ALT AUTO A/B、PACK CONTROL A/B、RECIRC FAN、OUTFLOW VLV、PRESS RELIEF、EE CLNG …）が無い。STATUS ページにメッセージ表の仕組みが無い（ATA 31 と共通） | ATA21 p.92–598 の各 status 項 | なし |

件数：高 6（AIR-01〜05, 15）、中 11（AIR-06〜13, 16, 17, 20）、低 5（AIR-14, 18, 19, 21, 22）。

## 8. 作り直しか部分修正か

推奨：ECS の部分（パック、流量とファン、温度、貨物室暖房、与圧、機器冷却、ECS の EICAS 出力）は作り直す。抽気の部分（:424-791）は ATA 36 の担当として別モジュールに分け、ダクト圧を受け渡しの dataref にする。

理由
- 今の ECS ロジックは実質 250 行ほどで、大半が仮置き。
  - 与圧：60 行。機器冷却：6 行。温度制御：無し。
  - 残す価値がある動きは、memo の論理と data block の色・条件（パネル側）くらいしかない。
- 与圧は考え方の土台が違う。
  - X-Plane の actuator に min(8,000, 高度) を書く方式で、手動・リリーフ・パック OFF を表せない。
  - 部分修正を重ねても、FCOM と ATA の数値には近づかない。
- 1 ファイルに抽気と空調が混ざっている。
  - 抽気と空調を分けないと、`override_pressurization` の所有も試験もはっきりしない。
- 残すべき名前は 30 程度で（3.1・3.2 の表、6 章）、作り直しても守るのは簡単。

進め方（案）
1. パネル変更なしでできる部分（規模 M〜L）
   - スイッチと電源、パック弁と流量、流量スケジュールとファン、CPC（モード・着陸高度・A/B・リミッタ・手動）
   - 質量収支の客室モデル（override の方針を ATA 36 と決めてから）、リリーフ
   - 警報・注意・advisory・memo、data block の条件
   - 機器冷却、後方暖房、貨物室火災 ARM の組替え、EEC 向けのパック数
2. 温度制御（規模 M）
   - ゾーン温度の簡易熱モデル、トリム空気、backup・ALTN、TRIM AIR OFF・TEMP ZONE・PACK CONTROL、灯。
3. カスタム acf の synoptic 追加（承認が要る。規模 M）
   - ゾーン温度、MASTER、FWD/AFT、外流弁の針と MAN/AUTO の色、HI FLOW、EXT AIR、新しい dataref によるパックの OFF/A/B。

全体の規模は L（1〜2 週間）。他系統への波及
- FMC：着陸高度・巡航高度・T/D を出す。
- EEC：パック数の読み先を変える。
- 火災：ARM の受渡し。
- 電源：バスごとの状態。
- ATA 36：ダクト圧と override の分担。

## 9. 未確認事項

- X-Plane（Web API で確かめる）
  1. `_auto_pressurization 1` のとき、`actuators/cabin_altitude_ft`・`cabin_vvi_fpm`・`max_allowable_altitude_ft` への書込みを X-Plane が上書きするか。
  2. 現状、進入中に ΔP が負になるか、data block が上昇中に毎回出るか（AIR-02 の推定）。
  3. 全パック OFF で与圧が止まるか。`_has_full_bleed_air 0` で legacy の bleed_air_mode が効いているか。`pack_*` の既定値は何か。
  4. `override_pressurization` 中に、`indicators/cabin_altitude_ft`・`cabin_vvi_fpm`・`pressure_diffential_psi` が `sim/cockpit/pressure/*_actual*` を映すか。
  5. `_dump_press_below_1k` の働き。
- パネル
  6. generic instrument の SHOW_LESS / SHOW_GREATER が等号を含むか。含まなければパックの A が出ない（AIR-15）。
- 3D
  7. 外流弁計で -1 と +1 のどちらが OP か（`Cockpit_OH1.obj:137141`）。外装の obj は同じ dataref を 0..1 と -1..1 の両方で使っている（`Exterior_Fuselage3.obj:6520-6644`）。
- 資料どうしの食い違い・欠落
  8. takeoff モードに入る条件：GS 65 kt（ATA21 p.412, 428, 429）か、各翼 1 基が N2 45% 超（p.435）か。本書は 65 kt を採った。
  9. PRESS RELIEF の条件：FCOM「全パック運転中」と ATA「運転中のパックが high flow 指令中」。FCOM を採った。ただし pack 2 がすぐ止まるので、成立のタイミングは要検討。
  10. 降下中の高度保持から抜けるときの降下量（ATA21 p.387 で数値が欠落）。cruise 判定の時間：45 s（p.431）と 1 分（p.436）。
  11. 巡航時の客室高度スケジュール。本書の推定は「巡航高度で ΔP 8.9」。実機の表は資料に無い。パック流量、客室容積、外流弁の特性、漏れも資料に無い。
  12. RECIRC スイッチ OFF（故障ではない）で high flow にするか。OVRD の差圧不足のしきい値。ゾーン温度の動特性。いずれも資料に記載なし。
  13. 温度の単位：FCOM 109 の synoptic は °F、ATA21 の図は °C。simconfig の単位設定に従わせるか。
- コード以外
  14. INTERFACES.tsv の漏れ（6 章）。表を直すかどうか。
  15. LCF（`747-400LCF.acf`）の ECS は貨物機の構成（FCOM 405/570）に寄せるか。今の air モジュールは全型で共通。
