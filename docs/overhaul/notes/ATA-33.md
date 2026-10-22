# ATA 33 Lights — 実装ノート

GAP ID の接頭辞：`LIGHT`。2026-10-23 作成。コードは `overhaul` ブランチ（041c9ffa）時点。

## 1. 概要

- 対象：操縦室照明（計器盤の integral と flood、dome、map・chart、STORM、standby 照明）、master dim and test（IND LTS）、外部灯（landing inboard/outboard、runway turnoff、taxi、nav、beacon、strobe、logo、wing）、非常灯、客室サイン（NO SMOKING / SEATBELTS と EICAS memo。ATA 33-20 のうち乗員が操作するもの）。
- 対象外：客室照明（ACESS）、貨物室・整備区画の照明、crew rest と貨物機の主甲板照明、表示器（PFD/ND/EICAS/CDU）の輝度と通電（ATA 31）、他系統の表示灯の点灯条件（各章。照明モジュールが持っている分は §5.3 に一覧）。
- 使った資料（ページは PDF ページ）：
  - ATA33 33-10 p.3–83（本文 p.6・8・10・12・14・16・18・20–50・52・54・56・64・67・68・70・72・74・76・78・81、図 p.17・53・69・73）、33-20 p.85–88・130・200・208・211–212・224–226、33-50 p.239–270（非常灯）・p.318–360（外部灯。図 p.267・321・331・335）。
  - FCOM 1.30（p.436–453）、1.40（p.499–505）、1.60（p.547）。関連：6.20（p.798・799・819）、NP（p.104・107・109・128・152–153）、LH24 p.8（towing power）。
  - 整備・試験の節は、乗員に見える論理か内部論理に関わるところだけ読んだ。
- 型式・構成：エンジン型式による差は無い。FCOM は 109（旅客型）を基準にする（ATA-24 ノートと同じ）。E&M（Config: ALL）は TAXI 灯を書いていない（ATA33 p.318、図 p.321）など構成が違う。乗員に見える点は FCOM に従う。
- 資料の食い違いと採用：
  1. STORM と表示灯：FCOM 1.40.3 は STORM ON で「点いている annunciator もすべて最大輝度」と書く（FCOM p.501 (1.40.3)）。FCOM 1.30.4 と E&M の回路は flood・dome・aisle stand flood だけ（FCOM p.438 (1.30.4)、ATA33 p.72 (33-10)）。乗員に見える挙動なので FCOM p.501 に従う。
  2. 燃料制御スイッチの灯の DIM：E&M p.52 は「DIM で減光する（fire handle は減光しない）」、p.68 は「DIM で減光しない」。回路の節（p.68）に従い減光しないとする（推定）。
  3. 操縦室 flood の電源：FCOM は ground service bus（GSB）が「flight deck flood」を給電と書く（FCOM p.799 (6.20.5)）。E&M は計器盤 flood の dimmer を AC bus 3、dome を GSB の 28V AC とする（ATA33 p.26・30・36・72 (33-10)）。内部の電源は E&M に従い、FCOM の flood は dome を指すと推定する。
  4. AISLE STAND PANEL/FLOOD：FCOM は「overridden by storm」を外側（panel）ノブの説明に書く（FCOM p.440 (1.30.6)）。E&M では STORM が上書きするのは aisle stand floodlight（ATA33 p.46・72）。E&M に従う。

## 2. 構成

### 2.1 操縦室照明

| 照明 | 操作 | 照らすもの | 通常の電源 | 電源喪失時 | 典拠 |
|---|---|---|---|---|---|
| Captain panel（integral） | PANEL 外側ノブ（glareshield 左） | P1、P44、P2 左、P72 の lightplate・計器灯 | AC bus 4 が R7733/R7736 を付勢し、dimmer を通す | AC 4 喪失で standby bus から固定輝度。非必須灯は R7736 で消灯 | ATA33 p.20・24、FCOM p.441 |
| Captain/center flood | PANEL 内側ノブ | P1・P2 の flood（glareshield 下の lightplate） | dimmer は AC bus 3（R7734 経由。R7734 は AC 4 で付勢） | AC 4 喪失で standby bus・固定。STORM で固定（最大） | ATA33 p.14・20・26、FCOM p.441 |
| F/O panel（integral） | F/O PANEL 外側 | P3、P45、P2 右 | AC bus 3 | 資料に記載なし | ATA33 p.28・30 |
| F/O flood | F/O PANEL 内側 | P3 の flood | AC bus 3 | STORM で固定 | ATA33 p.28・30 |
| Glareshield（integral） | GLARESHIELD PANEL/FLOOD 外側 | P10（MCP）、standby compass | AC 4 が R7735–R7737 を付勢 | standby bus → T137 固定。点くのは compass、機長 EFIS control、EICAS module の lightplate だけ | ATA33 p.32・34・36、FCOM p.439 |
| Glareshield flood | 同 内側 | P10 上の flood | AC bus 3（T961） | STORM で固定 | ATA33 p.36 |
| Overhead | CKT BKR/OVHD PANEL | P5、P7、P461 | AC 4 が R7733/R8098 を付勢（T44・T38）。追加分は AC 3（T40/T44） | standby bus → T44 固定。cabin pressure control、engine ignition/fuel jettison、anti-ice/rain の各 module | ATA33 p.38・40・42・44、FCOM p.439 |
| Aisle stand（integral） | AISLE STAND PANEL/FLOOD 外側 | P8、P9 | AC 4（T144、R7734/R7737、T951） | standby bus → T951 固定。左 CDU、機長 RCP、audio panel | ATA33 p.46・48・50 |
| Aisle stand flood | 同 内側 | aisle stand（頭上の灯） | main battery bus の 28V DC | GSB 喪失でノブが固定抵抗に置き換わる（減光）。STORM で battery bus 直結（最大） | ATA33 p.46・72、FCOM p.501 |
| Dome（3 灯） | DOME | 操縦室全体 | GSB の 28V AC（autotransformer） | GSB 喪失で機長・F/O の dome は battery bus から抵抗経由の固定輝度。aft dome は消灯と推定（図 p.73） | ATA33 p.70・72・73、FCOM p.440 |
| STORM | P5 のトグル | flood・dome・aisle stand flood を最大 | battery bus の 28V DC で R236・R8068 を付勢 | — | ATA33 p.70・72・73、FCOM p.438 |
| Map・utility・worktable・observer | MAP（pull/rotate）、CHART LIGHT、observer の MAP/PANEL | 局所照明 | AC bus 3（28V AC）。observer panel は T143（AC 3） | 資料に記載なし | ATA33 p.74・76・78、FCOM p.442–443 |

- dimmer は 115V AC を受けて 0–5V AC を出す（ATA33 p.18）。standby 照明は決まった輝度で点き、ノブに依らない（ATA33 p.22・34・40・48）。FCOM：通常電源を失うと flood は standby 電源で点き、aisle stand の integral を失うと aisle stand flood が減光で点く（FCOM p.501 (1.40.3)）。
- 機長側の standby 計器灯：時計、standby attitude、standby airspeed、standby altimeter（ATA33 p.22）。
- towing power（オプション）：GSB が無いときの牽引中、towing static inverter（または towing/battery power circuit）が nav、flood、panel lights とブレーキ圧計の灯を給電（LH24 p.8、ATA33 p.20・24・26・340）。
- 操縦室天井には非常灯も 1 灯ある（ATA33 p.248）。

### 2.2 master dim and test

- M886 module（coat closet の奥）：dimmer card 7 枚、dim relay 4、test relay 4、time delay relay 1（ATA33 p.52・64）。
- 対象：表示灯（indicator light。各 2 電球）、switch light の status/caution 部、aisle stand の digital display（ATA33 p.52・54・56）。switch light の位置表示（押し込んだときの白い legend）は panel 照明の 5V AC 系で点き、IND LTS の試験の対象外（ATA33 p.10・56・81）。
- 電源：28V DC battery bus（CAPT IND LIGHTS、CAPT IND & DGTL DISP LIGHTS。fire handles もここ）、DC bus 1（F/O IND LIGHTS、F/O IND & DGTL DISP LIGHTS）、DC bus 3（PILOT MISC IND LTS 1・2）。IND LTS スイッチ自体へは DC 1・DC 3 側の回路から給電（ATA33 p.69 図）。どの表示灯がどの回路かは資料に記載なし。FCOM：main battery bus が dome、storm、一部の表示灯を給電（FCOM p.819 (6.20.25)）。
- 電圧：BRT は 28V DC、DIM は dimmer card の 12V DC（ATA33 p.56・67）。

### 2.3 外部灯

| 灯 | 位置・数 | スイッチ（P5） | 電源 | 条件 | 典拠 |
|---|---|---|---|---|---|
| Landing | 各翼前縁の付け根に inboard・outboard（計 4） | LANDING OUTBD L/R、INBD L/R | R INBD：AC bus 1、R OUTBD：AC bus 3（左側は資料に記載なし） | gear lever DOWN で最大、UP/OFF で減光（70 %） | ATA33 p.318・328・330・331、FCOM p.450・499 |
| Runway turnoff | 前脚 strut に 2（左右 65°） | RWY TURNOFF L/R | GSB 115V AC（変圧して 28V） | ground mode のときだけ（R7333） | ATA33 p.318・332・334・335、FCOM p.450・500 |
| Taxi | 前脚に 2 | TAXI | 資料に記載なし | ground mode のときだけ | FCOM p.451・500 |
| Nav | 右翼端 緑 2、左翼端 赤 2、尾部 白 2 | NAV | GSB（R763） | towing 時は towing circuit | ATA33 p.318・340、FCOM p.451・500 |
| Beacon | 胴体上下の赤い strobe | BEACON LWR / OFF / BOTH | GSB | 約 48 回/分 | ATA33 p.318・342・348、FCOM p.451–452 |
| Strobe | 翼端 2、尾部 1（白） | STROBE | GSB | 約 48 回/分 | ATA33 p.318・342・354、FCOM p.452・500 |
| Logo | 左右の水平尾翼の上面（垂直尾翼の社章を照らす） | LOGO | GSB（R267） | — | ATA33 p.318・356・358、FCOM p.452 |
| Wing | 胴体側面 2（前縁と nacelle を照らす） | WING | GSB | 地上・飛行中とも | ATA33 p.318・322・326、FCOM p.452・500 |

- GSB は AC bus 1 が生きていれば地上・飛行中とも通電。地上で AC 1 が無いときは ground service switch で GHB と同じ電源につなげる（FCOM p.799 (6.20.5)、ATA33 p.326）。
- 夜間の dispatch 要件（MMEL の要約）：landing は任意の 2 灯、beacon 2 灯か strobe 3 灯、nav は赤・緑・白が各 1（ATA33 p.360）。故障注入を作るときの参考。

### 2.4 非常灯

- 客室通路、出口サイン、出口の内外、slide、overwing を照らす（ATA33 p.242、FCOM p.504 (1.40.6)）。
- 電源：遠隔の NiCd battery pack（6 セル）。充電は DC bus 4 の 28V（CHG EMER LT FWD/AFT）。満充電で 15 分以上点く（ATA33 p.258・266・267、FCOM p.504）。
- スイッチ：P5 の EMER LIGHTS（OFF / ARMED / ON、guard 付き）、客室乗務員パネル（109 は door 1L）の EMER LIGHTS 押しボタン（ATA33 p.264、FCOM p.452–453 (1.30.18–19)）。
- ロジック回路は各 battery pack にあり、2 つのスイッチと DC bus 4 の電圧を入力にする。EIU にスイッチの状態を出す（ATA33 p.266・267 図）。

### 2.5 客室サイン

- 選択器：aft aisle stand の NO SMOKING と SEATBELTS（各 OFF / AUTO / ON）（FCOM p.436–437 (1.30.2–3)）。
- AUTO の判定は MAWEA。入力は flap lever、gear、客室高度、機体高度（ARINC 429）と、乗客酸素の圧力スイッチ（ATA33 p.211 (33-20)）。信号は ESC → ACESS → OEU で各サインへ。チャイムは PAC（ATA33 p.208）。

## 3. 操作と表示

### 3.1 操縦室照明の操作子と現コードの対応

略記は §7 の冒頭と同じ。CKPT = `747-400_cockpit.obj`。

| 操作子 | 3D の操作子 | dataref | Lua での扱い |
|---|---|---|---|
| CAPT PANEL 外側 / 内側 | CKPT:22134 / :22188 | `laminar/B747/switches/instrument_brightness_ratio[6]` / `laminar/B747/light/flood/rheostat/captain_panel` | [6] を `sim/cockpit2/switches/instrument_brightness_ratio[6]` へ（× generic[63]、LIT:916-919）。flood は spill の captain_panel と center_panel（LIT:1018-1019） |
| F/O PANEL 外側 / 内側 | CKPT:22138 / :22190 | `…instrument_brightness_ratio[8]` / `…flood/rheostat/first_officer_panel` | 同上（LIT:1022） |
| CKT BKR/OVHD PANEL | CKPT:22178 | `…instrument_brightness_ratio[7]` | 同上 |
| GLARESHIELD 外側 / 内側 | CKPT:22142 / :22192 | `sim/cockpit2/switches/panel_brightness_ratio[3]` / `…flood/rheostat/mcp_panel` | compass の spill（LIT:1036）、MCP の spill（LIT:1026） |
| AISLE STAND 外側 / 内側 | CKPT:22140 / :22186 | `sim/cockpit2/switches/panel_brightness_ratio[2]` / `…flood/rheostat/aisle_stand` | spill（LIT:1027） |
| DOME | CKPT:22174 | `laminar/B747/light/flood/rheostat/overhead` | `panel_brightness_ratio[0]` に写す（LIT:1030）。acf の cockpit spot light 3 灯がこれを読む（747-400.acf:84228-84230、custom:73939-73941） |
| MAP（機長/F/O/observer）、CHART | CKPT:22154・22176・24759・22170・22172 | `laminar/B747/light/map|chart/rheostat/*` | spill（LIT:1020-1025）。observer panel は `panel_brightness_ratio[1]`（CKPT:24764） |
| STORM | CKPT:23838 | `toggle_switch/position[0]`：0 = ON、1 = OFF | MAN:1026-1030、LIT:1018-1030 |
| IND LTS | CKPT:23920 | `toggle_switch/position[13]`：1 = TEST（押している間）、0 = BRT、-1 = DIM | MAN:1097-1118、LIT:1682-1689 |

- 非常灯スイッチ、FLIGHT DECK ACCESS LIGHTS の操作子は 3D に無い（CKPT に該当の manipulator が無い）。

### 3.2 外部灯スイッチと現コードの対応

| スイッチ | コマンド（`laminar/B747/toggle_switch/…`） | position | ON の値（Lua） | 書く X-Plane dataref |
|---|---|---|---|---|
| LANDING OUTBD L / R | `landing_light_OBL` / `_OBR` | [1] / [2] | 0 | `sim/cockpit2/switches/landing_lights_switch[0]` / `[3]` |
| LANDING INBD L / R | `landing_light_IBL` / `_IBR` | [3] / [4] | 0 | `landing_lights_switch[1]` / `[2]` |
| RWY TURNOFF L / R | `rwy_tunoff_L` / `_R` | [5] / [6] | 0 | `sim/cockpit2/switches/generic_lights_switch[0]` / `[1]` |
| TAXI | `taxi_light` | [7] | 0 | `sim/cockpit2/switches/taxi_light_on` |
| BEACON | `beacon_light_up` / `_down` | [8] | ±1（LWR と BOTH を区別しない） | `sim/cockpit/electrical/beacon_lights_on` |
| NAV | `nav_light` | [9] | 0 | `sim/cockpit2/switches/navigation_lights_on` |
| STROBE | `strobe_light` | [10] | **1** | `sim/cockpit2/switches/strobe_lights_on` |
| WING / LOGO | `wing_light` / `logo_light` | [11] / [12] | 0 | `generic_lights_switch[2]` / `[3]` |

- 典拠：LIT:751-864、MAN:1032-1094・1729-1762。cold & dark では [1]–[12] をすべて 1、BEACON を 0 にする（MAN:2060-2084）。
- 3D の NAV・STROBE・WING・LOGO は同じ回転（position 0 → +16°、1 → −16°）（objects/747_cockpit/Cockpit_OH1.obj:136263-136278）。STROBE だけ Lua の向きが逆（LIGHT-04）。
- 外部灯の OBJ：カスタム acf の `objects/Landing_lights.obj` は landing の index 0–3、taxi 0、generic 0–3、beacon（上下とも index 0。:235-239）を使う。純正 acf の `objects/747_exterior/Exterior_Wings.obj` は landing 0–3、taxi 0、generic 0–1 を使う（純正の generic 2・3 と beacon は手元の OBJ で見つからない）。
- FCOM の実機：BEACON は上が LWR、中が OFF、下が BOTH。ほかは上 OFF・下 ON（FCOM p.451 (1.30.17) 図）。

### 3.3 IND LTS と STORM

- IND LTS：TEST（spring-loaded）は全 annunciator を 10 秒間最大輝度で点け、その後は押している間減光する。BRT は最大、DIM は低輝度（FCOM p.441 (1.30.7)、ATA33 p.52）。
- TEST で点かないもの：エンジンと APU の fire handle、FUEL CONTROL スイッチの灯（どちらも master dim の電源を使う）。cargo fire の灯は TEST で点くが DIM では減光しない（ATA33 p.52・68）。
- STORM ON：機長・F/O の flood、glareshield の灯、aisle stand flood、dome を最大（FCOM p.438 (1.30.4)）。点いている annunciator もすべて最大（FCOM p.501 (1.40.3)）。

### 3.4 非常灯

- EMER LIGHTS（P5）：OFF は電源喪失時も作動させない。ARMED は機体の電源が落ちるか切られると全非常灯を点ける。ON は全点灯（FCOM p.452 (1.30.18)）。
- 客室側の押しボタン（109 は door 1L の handset cradle）：押すと赤く点灯し、客室と外部の非常灯を点ける（P5 を bypass）。もう一度押すと消える（FCOM p.453 (1.30.19)）。客室側からは、P5 が ON のときや ARMED で電源を失ったときに非常灯を消せない（ATA33 p.264）。
- 手順：preflight で ARMED（guard closed）（FCOM p.104 (NP.21.10)）、secure で OFF（FCOM p.153）。電源の無い機体ではスイッチを OFF にしないと点灯してバッテリーが放電する（ATA33 p.266）。

### 3.5 客室サイン（FCOM 109）

- NO SMOKING・SEATBELTS とも OFF / AUTO / ON（FCOM p.437–438）。AUTO の条件は §4.8。
- 乗客酸素が落ちると、選択位置にかかわらず NO SMOKING と FASTEN SEAT BELTS が点き、RETURN TO SEAT が消える（FCOM p.437–438 (1.30.3–4)）。

### 3.6 EICAS メッセージ

| メッセージ | 種類 | 条件 | 典拠 | 現コード |
|---|---|---|---|---|
| >EMER LIGHTS | advisory | EMER LIGHTS が ARMED でない。または ARMED で客室側スイッチにより点灯 | FCOM p.547 (1.60.3)、ATA33 p.268 | 定義だけ（WRN:294、adv[108] を誰も立てない） |
| NO SMOKING ON | memo | NO SMOKING が ON 位置。両方 ON のときは抑止 | FCOM p.502 (1.40.4)・p.547 | SAF:233-241（点灯状態で判定） |
| SEATBELTS ON | memo | SEATBELTS が ON 位置。両方 ON のときは抑止 | 同上 | SAF:251-259（同上） |
| PASS SIGNS ON | memo | NO SMOKING と SEATBELTS が両方 ON 位置 | 同上 | SAF:243-249（同上） |
| STROBE LIGHT OFF | memo | 資料に記載なし（FCOM の memo 一覧に無い） | FCOM p.547 | 定義（WRN:528）、常に 0（LIT:2143-2153） |
| ACESS MGT UNIT、PASS SERVICES 1/2 | status（60 秒遅延） | ACESS の故障 | ATA33 p.130 | なし（対象外） |

- PASS OXYGEN ON、THERAP OXYGEN ON は ATA 35（FCOM p.547）。

## 4. 内部ロジック

### 4.1 操縦室照明（通常と standby）

- 通常：各ノブ → dimmer（0–5V AC）→ lightplate/flood。輝度はノブに比例とみてよい（推定）。
- AC bus 4 を失うと：機長 panel、glareshield、overhead、aisle stand の integral は standby bus からの固定輝度に切り替わり、必須でない灯（R7736/R7737/R8098 の先）は消える。点き続ける灯は §2.1 の standby 一覧（ATA33 p.24・36・42・50）。
- AC bus 3 を失うと：F/O 側の integral と flood、glareshield flood、map などが消える（ATA33 p.30・36・76）。機長 flood の dimmer も AC 3（ATA33 p.26）。
- GSB を失うと：dome（3 灯）の通常給電が止まり、機長・F/O の dome と aisle stand flood は battery bus から固定輝度。DOME ノブは効かない（ATA33 p.72）。
- battery bus だけのとき（AC 無し）：STORM、aisle stand flood、機長・F/O の dome（固定）が使える（ATA33 p.72・73、FCOM p.819）。standby bus がインバーターで生きていれば standby の計器灯も点く（ATA-24 ノートの standby 電源と合わせる）。

### 4.2 STORM

- STORM ON（battery bus が必要）：R8068 で機長・F/O・glareshield の flood ノブが固定抵抗に置き換わり最大。R236 で aisle stand flood は battery bus 直結、dome は DOME ノブを迂回して GSB の 28V AC を直接受ける（ATA33 p.20・28・32・72）。
- 表示灯：DIM の位置でも最大輝度にする（FCOM p.501）。
- GSB が無いと dome は STORM でも最大にならない（battery bus の固定輝度）（ATA33 p.72・73 から推定）。

### 4.3 master dim and test

- 各表示灯 = 系統の条件 OR TEST 中。輝度：BRT（28V）か DIM（12V）。TEST は 28V で、10 秒経つと time delay relay が dim relay を付勢して減光（ATA33 p.67）。
- 状態遷移：
  - TEST を押す → 全灯 BRT（t = 0）→ t ≥ 10 s で DIM → 離すと元の BRT/DIM に戻る（ATA33 p.52・67、FCOM p.441）。
  - STORM ON の間は DIM でも BRT（FCOM p.501）。
- 例外：fire handle と FUEL CONTROL スイッチの灯は TEST の対象外で、DIM でも減光しない（ATA33 p.68。§1 の食い違い 2）。cargo fire の灯は TEST の対象、DIM は効かない（ATA33 p.68）。switch light の白い legend は panel 照明側（ATA33 p.81）。
- 電源：灯ごとの回路の割り当てが無いので、実装では battery bus、DC bus 1、DC bus 3 のどれかがあれば点くとみなす（推定。ATA33 p.69 図）。DIM と TEST の制御は DC 1・DC 3 側の電源が要る（図 p.69 の IND LTS SWITCH への給電からの推定）。
- aisle stand の digital display（RTP など）は BRT/DIM に従う（ATA33 p.52）。TEST で全セグメントが点くかは資料に記載なし。
- DIM の輝度比：資料に記載なし（12V/28V。推定で 0.3–0.5）。

### 4.4 landing lights

- 各スイッチ ON → その灯が点く（FCOM p.450 (1.30.16)）。
- 減光：R84（gear lever position relay）は gear lever DOWN で付勢。lever が UP/OFF で R INBD スイッチが ON のとき R1042 が付勢し、右の inboard と outboard を変圧器の別タップ（減光）に切り替える（ATA33 p.330・331）。
  - INBD OFF・OUTBD ON なら、outboard は lever の位置にかかわらず最大（ATA33 p.330）。
  - 輝度：lever DOWN で最大、UP で最大の 70 %（ATA33 p.328）。FCOM は「UP/OFF で dimmed」（FCOM p.499 (1.40.1)）。
- 判定は gear lever の位置で、脚の位置ではない（ATA33 p.330、FCOM p.450）。
- 電源：R INBD は AC bus 1、R OUTBD は AC bus 3（図 p.331）。本文は「左右の switch は AC bus 1 と 3」（ATA33 p.330）。左側の割り当てと減光リレーは資料に記載なし（右と対称と推定）。

### 4.5 runway turnoff・taxi

- runway turnoff：スイッチ ON かつ ground mode（R7333 が GND）で R7770/R7771 が付勢し点灯。air mode では消灯（ATA33 p.332・334・335、FCOM p.450・500）。
- taxi：スイッチ ON かつ ground mode（FCOM p.451・500）。電源は資料に記載なし（turnoff と同じ GSB と推定）。

### 4.6 nav・beacon・strobe・logo・wing

- いずれもスイッチ ON かつ GSB 通電で点く（ATA33 p.326・340・348・354・358）。
- BEACON：LWR は下の 1 灯、BOTH は上下（FCOM p.451–452）。点滅は約 48 回/分、xenon 管に約 500 V のパルス。電源 unit は 5 台（beacon 2、strobe 3）（ATA33 p.342・348）。
- STROBE：翼端 2 と尾部の白 3 灯、約 48 回/分（ATA33 p.342・354）。翼端 strobe には無線への干渉防止フィルタがある（ATA33 p.354）。
- 点滅の位相（3 灯が同時か順番か）は資料に記載なし。

### 4.7 非常灯

- 入力：P5 スイッチ（OFF/ARMED/ON）、客室側スイッチ（NORMAL/ON）、DC bus 4 の通電、各 battery pack の残量。
- 点灯条件（ATA33 p.264・266、FCOM p.452–453・504）：
  - 客室側が ON → 点灯（P5 の位置に依らない）。
  - P5 が ON → 点灯。
  - P5 が ARMED で DC bus 4 が無い → 点灯（FCOM は「DC power fails or is turned off」）。
  - P5 が OFF → 電源喪失でも点かない。
- 充電：DC bus 4 があれば trickle charge（OFF でも ARMED でも）（ATA33 p.266）。満充電から 15 分以上（FCOM p.504）。それより先の減衰は資料に記載なし。
- EICAS：>EMER LIGHTS =（P5 ≠ ARMED）OR（P5 = ARMED かつ 客室側 ON）（FCOM p.547、ATA33 p.268）。
- ドアとの関係（109）：P5 が ARMED で、ドアの mode select lever が ARM のとき、そのドアのハンドルを開位置にすると、そのドアの外部灯と客室の非常灯が点く（FCOM p.504）。操縦室からは見えない。

### 4.8 客室サイン

- AUTO の条件（FCOM 109。FCOM p.502 (1.40.4)）：
  - FASTEN SEAT BELTS：gear が up and locked でない、または flap lever が UP でない、または機体高度 < 10,300 ft、または客室高度 > 10,000 ft、または乗客酸素作動。
  - NO SMOKING：gear が up and locked でない、または客室高度 > 10,000 ft、または乗客酸素作動。
  - E&M は gear を「down」、flaps を「not retracted」と書く（ATA33 p.211–212）。乗員に見える条件なので FCOM に従う。
- 選択器 OFF でも乗客酸素作動なら両サインが点く（FCOM p.502）。RETURN TO SEAT は FASTEN SEAT BELTS と一緒に点き、酸素作動中は消える（FCOM p.502）。
- サインが点く・消えるときに PA で low tone（FCOM p.503 (1.40.5)）。
- memo（FCOM p.502、p.547）：
  - SEATBELTS ON：SEATBELTS が ON 位置。NO SMOKING ON：NO SMOKING が ON 位置。
  - 両方 ON 位置なら PASS SIGNS ON だけを出し、ほかの 2 つは抑止。
  - AUTO で点灯しているときは memo を出さない（E&M も「EICAS messages indicate selection of manual sign control」。ATA33 p.211）。
- 機体高度の出どころ（気圧高度か補正後の高度か）とヒステリシスは資料に記載なし。

## 5. 他系統とのつながり

### 5.1 入力

| 入力 | 使い道 | 出どころ |
|---|---|---|
| AC bus 1・3・4、GSB、main standby bus、main battery bus、DC bus 1・3・4 の通電 | §2.1–2.4 の各灯 | ATA 24（ELEC-02 のバス単位の公開 dataref） |
| gear lever の位置（`laminar/B747/actuator/gear_handle`：0 = DOWN、1 = OFF、2 = UP） | landing の減光 | ATA 32（B747.10.xt.gear.lua:151-157） |
| air/ground（ground mode） | runway turnoff、taxi | ATA 32-09（現状は X-Plane の `onground_any`） |
| flap lever、gear up and locked、機体高度、客室高度、乗客酸素 | 客室サイン | ATA 27、32、34（ADC）、21、35（OXY-01） |
| ドアの mode と handle | ドアごとの非常灯 | ATA 52（操縦室からは見えない） |

### 5.2 出力

- EICAS（EIU）：>EMER LIGHTS、サインの memo（ATA 31 の表 WRN:294・510・520・526）。
- PA チャイム：FMOD が `sim/cockpit2/annunciators/no_smoking` と `fasten_seatbelt` の変化で鳴らす（fmod/747-400.snd:5920-5938）。照明モジュールがこれらの元の `sim/cockpit2/switches/no_smoking`・`fasten_seat_belts` をサインの点灯状態として書く（LIT:1619・1646）。
- 表示灯の輝度：`laminar/B747/annunciator/brightness_ratio[0..269]`（OBJ が使うのは 0–250 と 257–269）。

### 5.3 照明モジュールが持っている他系統の処理

`B747.90.xt.lighting.lua` は照明以外の処理を多く持つ。照明の作り直しでは、各章の作り直しと時期を合わせて移す。

| 内容 | 行（LIT） | 担当章・関係ノート |
|---|---|---|
| 表示器の輝度と通電のアニメーション（`instrument_brightness_ratio` を表示器ごとの通電で掛ける） | 889-919 | ATA 31 |
| 客室照明 `generic_lights_switch[25]`（夜間、10,000 ft 未満かつ 15 kt 超で減光） | 920-964 | ATA 33-20（客室。乗員の操作子は無い） |
| **ELEC の状態を書く**：`laminar/B747/electrical/ext_pwr1_on/2_on`、`apu_pwr1_on/2_on` | 1084-1101 | ATA 24。ELEC がバス論理で読む（ELEC:560-579）→ LIGHT-01 |
| ELEC パネル灯（EEC ALTN [4]–[7]、UTIL [8]–[9]、BATT OFF [10]、EXT/APU [11]–[18]、ISLN [19]–[22]、GEN CONT [23]–[26]、DRIVE [27]–[30]、GEN FIELD・SSB [88]–[94]＝0） | 1071-1119、1391-1398 | ATA 24（ELEC-10/11）、EEC は ATA 73 |
| HYD（ENG PRESS [31]–[34]、BRAKE SOURCE [79]、FLT CTL VALVE [80]–[87]＝0、SYS FAULT [105]–[108]、DEMAND PRESS [109]–[112]） | 1121-1125、1376-1424 | ATA 29（HYD-09/13/14/22） |
| FIRE（CARGO FIRE [35]–[37]＝0、SQUIB TEST [95]–[103]＝0、BTL DISCH [113]–[117]） | 1127-1130、1400-1431 | ATA 26 |
| FUEL（JETT NOZZLE [38]–[39]＝0、XFEED [40]–[43]、ポンプ PRESS [44]–[59]） | 1132-1272 | ATA 28（FUEL-08） |
| 防氷（NAI/WAI VALVE [60]–[64]、WINDOW HEAT INOP [65]–[66]） | 1274-1326 | ATA 30（ICE-07） |
| YAW DAMPER INOP [67]–[68] | 1328-1330 | ATA 22 |
| 空調（ZONE RST [69]、AFT CARGO HEAT [70]＝0、PACK RST [71]＝0） | 1332-1335 | ATA 21（AIR-14） |
| 抽気（ISLN [72]–[73]、APU BLEED [74]、ENG BLEED OFF [75]–[78]、SYS FAULT [118]–[121]、START VLV [122]–[125]） | 1337-1362、1433-1443 | ATA 36・80 |
| IRS ON BAT [104]＝0、GND PROX [2]・G/S INHIBIT [3]＝0 | 1059-1064、1412 | ATA 34 |
| 無線（RTP/ACP/call panel [126]–[250]、LCD とガラス [253]–[256]、`instrument_brightness_ratio[15]`） | 1449-1594、2067-2071 | ATA 23 |
| MCP のモード灯 [257]–[269]（ここで AFDS のモード判定をしている） | 1653-1667 | ATA 22 |
| 気象レーダー操作パネルの灯（`laminar/B747/wxr/*`。OBJ からの参照は見つからない） | 2093-2127 | ATA 34 |
| MASTER WARNING/CAUTION 灯 [0]–[1] | 1049-1053、1711-1714 | ATA 31 |

- ほかのモジュールにある照明の処理：ストロボの点滅（ELEC の init スクリプト。ELECI:130-161。LIGHT-05）、客室サインの memo とドアのメッセージ（SAF:215-262）。

## 6. 実装上の注意

### 6.1 X-Plane の灯、acf、OBJ

- 外部灯は X-Plane の灯（landing・taxi・nav・beacon・strobe）と generic light（turnoff L/R = 0/1、wing = 2、logo = 3）で描く。名前と index は両方の acf の OBJ が使うので変えない（§3.2）。
- acf の `acf/_esys_bus_bit_add/rel_lites_beac/ins/land/nav/pan/strobe/taxi` = 1（747-400.acf:83278-83285。ACF_DIFF §2 のとおり電源の項目は両 acf で同じ）。X-Plane は自分の bus 1 で灯を通電させていると推定する。現コードは 747 のバスを見ないので、外部灯が点くかどうかは X-Plane 側の通電（bus 1 と generic light の扱い）だけで決まる。
- 作り直しでは「スイッチ値 × 747 のバスの通電 × 空地などの条件」を Lua で計算して書く。X-Plane の bus 1 が切れると二重に消えるので、ELEC の作り直しと X-Plane のバスの扱いを合わせる（ATA-24 ノート）。
- beacon と strobe：`sim/flightmodel2/lights/override_beacons_and_strobes` を 1 にすると `beacon_brightness_ratio[4]`・`strobe_brightness_ratio[4]` を書ける（X-Plane の DataRefs.txt）。約 48 回/分の点滅と、LWR/BOTH の区別ができる。ただし上下の beacon は OBJ で同じ index 0（Landing_lights.obj:235-239）なので、LWR だけを光らせるには OBJ の変更が要る（見た目の変更。承認事項）。
- generic[63] は「照明の電源」として使われている（flight_start で 1 にする。LIT:2288）。X-Plane が generic light を電源で消すかは未確認（§9）。作り直しでは使わず、グループごとの通電を直接掛ける。

### 6.2 表示灯（annunciator）の作り方

- 現状は 270 個の添字ごとに同じ三項演算を書いている（LIT:1711-2091）。作り直しでは「添字 → {点灯条件, 電源グループ, TEST 対象か, DIM が効くか}」の表にし、輝度は 1 つの関数で計算する。
  - 輝度 =（TEST 中で対象 → 試験輝度）か（条件成立 → 通常輝度）× 電源。
  - 通常輝度 = STORM ON なら BRT、そうでなければ IND LTS の BRT/DIM。試験輝度は TEST 開始から 10 秒は BRT、その後 DIM。
- EXT PWR AVAIL と APU AVAIL は、その電源自身で点く扱い（機体の電源が無くても点く）を残す（LIT:1696-1700）。実機もこれらはその電源で点くと推定。
- 点灯条件は各章のモジュールが持ち、照明は「どの灯をどの輝度で」だけを持つ形にする（§8）。

### 6.3 簡略化してよいもの・いけないもの

- してよい：dimmer の電圧（0–5V、12V/28V）→ 0–1 の比、standby 照明を「グループごとに固定輝度」で表す、ACESS と客室照明の細部、towing power、整備用の試験、lamp の故障。
- してはいけない：
  - 各スイッチの位置と意味（§3.1–3.2）。
  - landing の減光（gear lever、INBD スイッチとの関係、70 %）。
  - turnoff と taxi は地上だけ。
  - 非常灯の ARMED による自動点灯（DC bus 4 喪失）と >EMER LIGHTS。
  - サインの memo は手動 ON のときだけ。
  - STORM の上書き。
  - TEST で fire handle と FUEL CONTROL の灯を点けないこと。

### 6.4 コードの構造

- `after_physics` で毎フレーム `collectgarbage("collect")`（完全 GC）を呼んでいる（LIT:2377）。作り直しでは使わない。
- ストロボを 2 つのプラグインが書いている（LIT:840 と ELECI:140）。作り直しでは書き手を 1 つにする。
- 照明は xtlua_keysystems、スイッチの位置（manipulators）と safety と warning は xtlua にある。dataref は 1 フレーム遅れて届くので、プラグインをまたぐ判定（サインの memo など）は遅れを考える（OLD_FORK_NOTES §14）。
- quick start（AI）の照明スイッチの向きが照明モジュールと食い違っている（AI:1177、1250-1263）。スイッチの向きは 1 か所で定数にする。

## 7. 現状実装との比較（GAP 候補）

略記：LIT = `plugins/xtlua_keysystems/scripts/B747.90.xt.lighting/B747.90.xt.lighting.lua`、MAN = `plugins/xtlua/scripts/B747.01.xt.manipulators/B747.01.xt.manipulators.lua`、SAF = `plugins/xtlua/scripts/B747.85.xt.safety/B747.85.xt.safety.lua`、WRN = `plugins/xtlua/scripts/B747.87.xt.warning/B747.87.xt.warning.lua`、ELEC = `plugins/xtlua/scripts/B747.03.xt.electrical/B747.03.xt.electrical.lua`、ELECI = `plugins/xtlua/init/scripts/B747.03.electrical/B747.03.electrical.lua`、AI = `plugins/xtlua/scripts/B747.95.xt.AI/B747.95.xt.AI.lua`、OH1 = `objects/747_cockpit/Cockpit_OH1.obj`。

| ID | 種別 | 重要度 | 規模 | 内容 | 根拠 | 該当コード |
|---|---|---|---|---|---|---|
| LIGHT-01 | バグ | 高 | S | 照明モジュールが ELEC の状態 `electrical/ext_pwr1_on/2_on`・`apu_pwr1_on/2_on` を計算して書き、ELEC がそれをバス論理（topleftbus、bus tie、SSB）で読む。照明を作り直すときにこれを落とすと外部電源と APU 電源がバスにつながらなくなる。ELEC へ先に移す | ATA-24 ノート §6–7 | LIT:1084-1101、ELEC:560-579 |
| LIGHT-02 | 挙動の誤り | 高 | S | サインの memo（NO SMOKING ON / SEATBELTS ON / PASS SIGNS ON）を選択器の位置でなくサインの点灯状態で出している。AUTO で gear down や 10,300 ft 未満のたびに memo が出る（地上ではほぼ常時） | FCOM p.502・547、ATA33 p.211 | SAF:233-259、LIT:1619・1646 |
| LIGHT-03 | 欠落 | 中 | M | 外部灯が 747 のバスに依存しない。点くかどうかは X-Plane の bus 1（acf の `rel_lites_*` = 1）と generic light の扱いだけで決まる。バッテリーだけでも landing・nav・beacon・strobe・taxi が点きうる。実機は landing が AC 1/3、ほかは GSB（AC 1 か地上の ground service switch） | ATA33 p.326・330・331・334・340・348・354・358、FCOM p.799 | LIT:751-864、747-400.acf:83278-83285（両 acf 同じ） |
| LIGHT-04 | バグ | 中 | S | STROBE だけスイッチの値の向きが逆（strobe = position、ほかは 1 − position）。cold & dark は [1]–[12] を 1 にするので、STROBE スイッチが OFF 側のままストロボが点く。3D の回転は NAV・WING・LOGO と同じ。要確認（3D のどちらが ON か） | FCOM p.451–452 | LIT:838-842、MAN:2060-2075、OH1:136263-136278 |
| LIGHT-05 | バグ | 中 | S | ストロボの dataref を 2 か所が書く。ELEC の init スクリプトは `fs/lighting/strobes_on`（書き手なし、常に 0）を見て毎フレーム `strobe_lights_on` = 0 を書く。値が 1 なら「3 回光って 2 秒消える」点滅を作るが、実機は約 48 回/分の単発（beacon も同じ） | ATA33 p.342・348・354 | ELECI:130-161、LIT:838-842 |
| LIGHT-06 | 欠落 | 中 | S | 非常灯が無い。EMER LIGHTS スイッチの dataref・コマンド・3D の操作子、ARMED の自動点灯（DC bus 4 喪失）、客室側スイッチ、>EMER LIGHTS（adv 108 を誰も立てない）が無い。preflight の ARMED、secure の OFF ができない。3D の操作子の追加は承認事項 | FCOM p.104・153・452–453・504・547、ATA33 p.264・266・268 | WRN:294（定義のみ） |
| LIGHT-07 | 欠落 | 中 | M | 操縦室照明の電源の扱いが無い。AC 4 喪失時の standby 照明（固定輝度、必須灯だけ）、AC 3 喪失時の F/O 側消灯、GSB 喪失時の dome と aisle stand flood の固定輝度、battery だけのときの STORM/dome が無い。電源の扱いは generic[63] を掛けるか、X-Plane の panel 照明の通電（bus 1）に任せるだけで、ノブはいつも効く。ELEC のバス公開（ELEC-02/06）が前提 | ATA33 p.22–50・72、FCOM p.501・819 | LIT:916-919、971-1039、2288 |
| LIGHT-08 | バグ | 中 | S | `after_physics` の先頭で毎フレーム `collectgarbage("collect")`（完全 GC）。照明に限らずフレーム時間を食う。要計測 | — | LIT:2377 |
| LIGHT-09 | 挙動の誤り | 低 | S | landing の減光が 50 %（正：70 %）。INBD スイッチ OFF・OUTBD ON のとき outboard は最大のはずが、全灯を一律に減光する。gear lever で判定している点は正しい | ATA33 p.328・330・331、FCOM p.499 | LIT:751-761 |
| LIGHT-10 | 挙動の誤り | 低 | S | IND LTS：TEST が 10 秒後に減光しない。DIM は全灯一律 0.4（MASTER WARNING/CAUTION だけ 0.05）。TEST で客室サイン [251]–[252]、無線 LCD [253]–[256]、気象レーダー操作パネルも点く。TEST の輝度（1.0）が BRT（0.8）より明るい | FCOM p.441、ATA33 p.52・67・68・81 | LIT:1682-1714、2063-2071、2093-2127 |
| LIGHT-11 | 挙動の誤り | 低 | S | STORM：表示灯を最大にしない（DIM のまま）。STORM 時の flood（1.9 × lightMod）がノブ最大（2.0 × lightMod）より暗い | FCOM p.438・501、ATA33 p.72 | LIT:1013-1030、1682-1694 |
| LIGHT-12 | 挙動の誤り | 低 | M | BEACON の LWR と BOTH が同じ（X-Plane の beacon 1 つで上下とも点く）。点滅の間隔も X-Plane 任せ。分けるには override と OBJ の index 分け（承認事項）が要る | FCOM p.451–452、ATA33 p.342・348 | LIT:810-821、objects/Landing_lights.obj:235-239 |
| LIGHT-13 | 挙動の誤り | 低 | S | turnoff と taxi の地上判定が X-Plane の `onground_any`（変数名は all_wheels だが any）。747 の air/ground（ATA 32-09）の出力に替える | FCOM p.450・500、ATA33 p.334 | LIT:95-96、771-802 |
| LIGHT-14 | 欠落 | 低 | S | サインの AUTO に乗客酸素の条件が無い（TODO）。選択器 OFF でも酸素作動なら点灯、も無い。機体高度は `altitude_ft_pilot` を使う（出どころは資料に記載なし）。酸素は ATA 35（OXY-01）が前提 | FCOM p.437–438・502、ATA33 p.211–212 | LIT:1597-1646 |
| LIGHT-15 | バグ | 低 | S | quick start（auto-board）のスイッチの向きが照明モジュールと逆（NAV・LOGO は position 1 を ON とみなす）。NAV はスイッチを動かさずステップが時間切れになり、LOGO は点いていれば消して「成功」とする | — | AI:1177・1190、1250-1263、LIT:827-831・860-864 |
| LIGHT-16 | 欠落 | 低 | S | FLIGHT DECK ACCESS LIGHTS（GHB 給電時に押すと出入口の経路を照らす）が無い。3D の操作子も無い | FCOM p.444、ATA33 p.224・226 | なし |

- 件数：高 2（LIGHT-01、02）、中 6（LIGHT-03〜08）、低 8（LIGHT-09〜16）。合計 16。
- 正しく実装されている点：landing の減光を脚でなく gear lever（`actuator/gear_handle` < 0.05 = DOWN）で判定（LIT:753-754）、turnoff と taxi を地上だけにする（LIT:771-802）、IND LTS の TEST が spring-loaded（MAN:1097-1110）、STORM で flood と dome を固定輝度にする（LIT:1018-1030）、EXT PWR/APU の AVAIL 灯が機体の電源に依らない（LIT:1696-1700）、center panel の flood を機長の内側ノブで動かす（LIT:1019）、glareshield の外側ノブで standby compass も明るくなる（LIT:1036）、サイン変化で PA のチャイム（fmod/747-400.snd:5920-5938）。
- ACF_DIFF の関係：照明に関わる acf の値（`_esys_bus_bit_add/rel_lites_*`、cockpit spot light の `_spot_name_3d`、DRS などのパネル定義）は両 acf で同じ（ACF_DIFF §2）。カスタム acf だけにある `Landing_lights.obj` は純正の外部 OBJ と同じ index で灯を定義しているので、Lua はどちらの acf でも同じでよい。コードは acf の値を直接読まないが、X-Plane 側の灯の通電は acf の `rel_lites_*` に依存する（LIGHT-03）。

## 8. 作り直しか部分修正か

**推奨：照明モジュールは作り直す。ただし他系統の表示灯の点灯条件は、各章の作り直しと一緒に移す。先に LIGHT-01（ELEC の状態の書き込み）を ELEC へ移す。**

- 理由：
  - 照明そのもののロジックは少なく（外部灯 約 120 行、flood/storm 約 70 行、IND LTS の輝度 約 20 行）、ほぼ全部を電源・空地・STORM・TEST のタイマーを入れて書き直すことになる。部分修正の利点が小さい。
  - 表示灯の 270 行のコピペ（LIT:1711-2091）は表にすれば数十行になり、誤りが入りにくい。
  - 名前と意味（INTERFACES.tsv）がはっきりしている：`laminar/B747/annunciator/brightness_ratio`、`laminar/B747/light/*` の rheostat と spill、`laminar/B747/switches/instrument_brightness_ratio`、`laminar/B747/toggle_switch/*` のコマンドと `toggle_switch/position` の値の意味（§3.1–3.2）、`laminar/B747/safety/*`、`laminar/B747/light/cockpit_lightsOn/Off`（AutoATC）。X-Plane 側の灯の dataref と index（§6.1）も OBJ が読むので保つ。
  - 他系統の灯の条件（§5.3）は、照明の作り直しで直すと各章の作り直しと二重になる。照明側は「点灯条件を各系統の dataref から読む表」にしておき、各章が自分の作り直しで条件を正しくする。
- 進め方の案：
  1. すぐ直せるもの：LIGHT-02（memo を選択器の位置で判定）、LIGHT-08（GC の削除）、LIGHT-05（ELEC init のストロボの書き込みをやめる）、LIGHT-04（シムで 3D の向きを確かめてから）。
  2. LIGHT-01：`ext_pwr*_on`・`apu_pwr*_on` の計算を ELEC へ移す（ATA 24 の担当と合わせる）。
  3. 新しい照明モジュール：入力（スイッチ、§5.1 のバス・空地・gear lever）→ 灯ごとの状態 → X-Plane の dataref と spill/rheostat へ。表示灯は §6.2 の表と輝度関数。非常灯とサインの memo もここに入れる（サインの判定は SAF から移す）。
  4. 表示器の輝度アニメーション（LIT:889-919）は ATA 31、客室照明（LIT:920-964）はこのモジュールに残すか客室側へ移すかを決める。
- 前提：ELEC のバス単位の公開 dataref（ATA-24 の ELEC-02。AC 1・3・4、GSB、GHB、main standby、main battery bus、DC 1・3・4）、ATA 32-09 の air/ground、ATA 35 の乗客酸素。

## 9. 未確認事項

- X-Plane の挙動：
  - generic light（turnoff、wing、logo、generic[63]）が X-Plane の電源で消えるか。消えないなら、今は電源が全く無くても計器盤の照明と generic の外部灯が点く。
  - X-Plane の灯（landing など）が acf の `rel_lites_*` = 1（X-Plane の bus 1）で通電されるか。バッテリーだけのときに bus 1 が生きているか（ATA-24 ノートでは `bus_volts[0]` はバッテリーだけでも真）。
  - 3D の NAV/STROBE スイッチで、position 0 と 1 のどちらが ON 側（下）か（LIGHT-04）。
  - ELEC の init スクリプトの `after_physics` が実際に毎フレーム走り、照明モジュールの書き込みとどちらが勝つか（LIGHT-05）。
  - landing の X-Plane index と実際の灯（OBL/IBL/IBR/OBR）の対応（OBJ の位置で確認）。
- 資料に無いもの（推定で決めて試験する）：
  - 左の landing light の AC バスと減光リレー。taxi light の電源。
  - 通常時の dimmer の電源（AC 4 か AC 3 か）。standby に切り替わる灯の細かい一覧（standby で消える「非必須」灯がどれか）。
  - DIM の輝度比、DIM が aisle stand の digital display をどれだけ暗くするか、TEST で digital display が全点灯するか。
  - FUEL CONTROL スイッチの灯が DIM で減光するか（E&M の 2 か所が逆）。
  - STORM で annunciator が最大になる回路（FCOM 1.40.3 だけが書く）。
  - beacon/strobe の点滅の位相、非常灯の 15 分以降の減衰、サインの 10,300 ft のヒステリシス。
- 3D・パネル（変更は承認事項）：
  - EMER LIGHTS スイッチ、FLIGHT DECK ACCESS LIGHTS スイッチの操作子が無い。
  - `objects/747_cockpit/Cockpit_Pedestal1.obj:40255` の `annunciator/brightness_ratio[126z`（添字の書き誤り）で RTP L の OFFSIDE TUNING 灯が点かない可能性。
  - annunciator の [251]–[256]（客室サイン、無線のガラス）と `laminar/B747/wxr/*` の灯を読む OBJ が見つからない（ローカルに無い OBJ が使っているかもしれない）。
- `fs/lighting/strobes_on`（ELECI:130）の用途。外部から書く想定か。
