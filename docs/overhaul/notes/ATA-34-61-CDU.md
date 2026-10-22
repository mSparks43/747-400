# ATA 34-61 FMC CDU（ページと操作）— 調査ノート

対象コード：`overhaul` ブランチ（feedd8a9。plugins と acf は本家 041c9ffa のまま）。2026-10-23 調査。GAP の ID 接頭辞は `CDU`。
コードのパスは、断りがなければ `plugins/xtlua_keysystems/scripts/B747.68.xt.fms/` からの相対。

## 1. 概要

- 範囲：CDU のキー・scratchpad・メッセージ・ページの表示と入力受付、MOD/ACT/EXEC、3 台の CDU の関係、FMC/CDU 故障時の挙動。データリンクのページは要約（3.4）。
- 範囲外：ページの裏の計算（性能、VNAV/LNAV の予測）は FMC のノート、IRS の整列・位置は航法のノート。ここでは「ページが実機と同じものを出し、同じ入力を受け付けるか」を判断した。
- 資料と範囲：
  - FCOM 11.10（p.1207-1224）、11.30-11.31（p.1233-1270）、11.40-11.43（p.1277-1420）、11.50（p.1421-1428）、11.60（p.1429-1436）。補助に 10.10 の CDU による EFIS/DSP 代替操作（p.1060-1068）、5.20（p.715-718）、6.20（p.800, p.804）。
  - FMSPG 2.2-2.8（p.17-55、MCDU の一般則）、3 章（p.56-211）、5 章（p.238-254）、6 章（p.255-260）、7.2（p.263-269）。8・9 章（データリンク）は p.270-383 を要約。
  - FCOM 5.33・5.34（p.725-774）、5.40（p.775-776）。
  - repo の実機画面の写し：`documentation/fms pages/fmcs/fmcs 1-36.txt`、`posinit/POSINIT_FMS.txt`、`satcom/*.txt`、`flight controls/*.txt`（CMC 地上試験）。内容は FCOM・FMSPG の図とほぼ同じ。
- FCOM の型式番号：109 = 旅客（PW）、405 = 改造貨物機（PW）、570 = 貨物機（GE）（FCOM p.5 (0.1.1)）。ATA-24 のノートに合わせて **109 を基準**にし、CDU に効く違いは次のとおり。
  - 推力表示：THRUST LIM・CRZ は 109/405 が EPR、570 が N1（FCOM p.1314, p.1347）。
  - PROGRESS：109/405 は 3 ページ（3/3 が RTA）、570 は 2 ページ（FCOM p.1371, p.1373）。
  - DES ページの WPT/ALT と FPA・V/B・V/S は 570 だけ（FCOM p.1391, p.1394）。
  - APPROACH REF の QFE/QNH は 405/570 だけ（FCOM p.1412）。TAKEOFF REF の POS SHIFT は 109/405 が m、570 が ft（FCOM p.1321）。
  - データリンク（ATC キー・FMC COMM キー）は 405/570 だけ。109 では両キーとも KEY/FUNCTION INOP（FCOM p.725 (5.33.1), p.1211 (11.10.5)）。
- 資料どうしの食い違い（採った方）：
  - 中央 CDU：FMSPG は「FMS と無関係の 3 台目」（FMSPG p.17 (2-5)）、FCOM は「3 台の CDU で FMC を操作する」（FCOM p.1234 (11.30.2)）→ FCOM。
  - NEXT PAGE：FMSPG は最終ページで 1 ページ目に戻ると書く（FMSPG p.42 (2-30)）。FCOM は記載なし → FMSPG を採る。
  - ページ番号：FCOM は 1 ページだけなら空白（FCOM p.1214 (11.10.8)）、FMSPG は増えうるページだけ 1/1（FMSPG p.43 (2-31)）。両立する。
  - STANDBY ONE の閾値：FCOM 4 秒（p.1435 (11.60.7)）、FMSPG 6 秒（p.260 (6-6)）→ FCOM。
  - SP キー：FCOM は ACARS/SATCOM 使用時だけ（p.1213 (11.10.7)）、FMSPG は FMC でも有効（p.41 (2-29)）→ FCOM。
  - CDU の色：両資料とも字体（大・小）しか書いていない。色は資料に記載なし。パネルは緑の単色フォント（`TXT.fms.38_2.green`/`34_2.green`）で描いている。

## 2. 構成

### 2.1 実機

- CDU は 3 台（左右は前方 aisle stand、中央は後方）。CDU-152 と CDU-161 の 2 種類がある（FCOM p.1207-1209）。
- 画面は 14 行 × 24 字。1 行目が題名とページ番号、2-13 行目が 6 組の「小字の見出し行＋データ行」、14 行目が scratchpad（FMSPG p.39 (2-27)）。
- キー（FCOM p.1208-1213）：
  - LSK 1L-6L・1R-6R。
  - 機能キー：INIT REF、RTE、DEP ARR、ATC、VNAV、FIX、LEGS、HOLD、FMC COMM、PROG、MENU、NAV RAD、PREV PAGE、NEXT PAGE、EXEC（ライトバー付き）。
  - 英数字、`/`、`+/-`、`.`、SP、DEL、CLR、BRT ノブ。
- 表示灯：DSPY（白）、FAIL（琥珀）、MSG（白）、OFST（白）、EXEC（白）（FCOM p.1210-1212; FMSPG p.40-41）。
- FMC は 2 台。通常は左 FMC がキー操作のマスターで、キーの順序を決めて右 FMC へ送り、各 FMC が自分の CDU を更新する（FCOM p.1233 (11.30.1); FMSPG p.24 (2-12), p.49 (2-37)）。誘導に使う FMC は FMC master selector（L/R）で選ぶ。A/T 作動中に切り替えると A/T が切れる（FCOM p.1215 (11.10.9)）。
- 電源：左 CDU は main standby bus（FCOM p.804 (6.20.10)）、右 CDU は F/O transfer bus（FCOM p.800 (6.20.6)）、中央 CDU は資料に記載なし。左 FMC は APU standby bus、右 FMC は F/O transfer bus（FCOM p.800, p.804）。
- 他系統との接点：
  - EICAS：>FMC MESSAGE、FMC LEFT/RIGHT（FCOM p.1429 (11.60.1)）。ATC MESSAGE（405/570）。
  - MENU から ACARS、SATCOM、ACMS、CMC。ACARS と SATCOM は通常、中央 CDU で見る（FCOM p.718 (5.20.6)）。
  - EFIS 操作パネルと DSP の代替操作（FCOM p.1060）。
  - 両 FMC 故障時は CDU 自身が代替航法を行い、NAV source selector で ND の情報源を CDU に切り替える（FCOM p.1421-1422 (11.50.1-2)）。

### 2.2 現在のコードの構成

- 3 台の CDU は Lua の `fmsL`・`fmsC`・`fmsR` オブジェクト。各オブジェクトが scratchpad、notify（メッセージ）、現在ページ、ページ番号を持つ（B744.createfms.lua:7-16）。FMC のデータは共有の `fmsModules["data"]` 1 つで、JSON にして `laminar/B747/fms/data` に出す（B747.68.xt.fms.lua:578-716）。
- ページは 2 種類。
  - 独自ページ：`fmsPages[名前]` の getPage（大字 13 行）と getSmallPage（小字 13 行）、LSK の割り当て `fmsFunctionsDefs[名前][L1..R6]`。
  - 標準ページ：X-Plane 標準 FMS の CDU 1 の文字列（`sim/cockpit2/radios/indicators/fms_cdu1_text_line0-15`）を写す。キーは `sim/FMS/*` コマンドで標準 FMS へ送る（B744.createfms.lua:313-410）。
  - RTE と LEGS は両者の混成。標準の行を並べ替え、一部の行を独自の文字で上書きする（B744.fms.pages.lua:95-244; activepages/B744.fms.pages.legs.lua）。
- `refonly/*.lua`（REF NAV DATA、IRS LEGS、ALTN NAV RADIO、DEP/ARR、HOLD、FIX など 17 本）はどこからも読み込まれない静的な雛形（dofile なし）。

**物理的な対応（重要）**：名前が交差している。

| 物理 CDU | Lua | キーのコマンド | 画面の dataref | acf のパネル群（名前） | 表示条件 | 輝度 |
|---|---|---|---|---|---|---|
| 左 | fmsL | `laminar/B747/fms1/*` | `laminar/B747/fms3/LineNN_L/_S` | "FMS C"（x=1706） | `display_has_power[8]`（機長側） | rheostat 12 |
| 中央 | fmsC | `laminar/B747/fms3/*` | `laminar/B747/fms1/LineNN_L/_S` | "FMS L"（x=346） | `display_has_power[6]`（F/O 側） | rheostat 12 |
| 右 | fmsR | `laminar/B747/fms2/*` | `laminar/B747/fms2/LineNN_L/_S` | "FMS R"（x=1026） | `display_has_power[7]`（F/O 側） | rheostat 13 |

- 根拠：
  - Lua の割り当て：B747.68.xt.fms.lua:805-830。
  - 3D のキーの位置：fms1 の L1 は x=-0.27・z=4.89（左）、fms2 は x=+0.11（右）、fms3 は x=-0.08・z=5.47（後方の中央）（747-400_cockpit.obj:22522, 22656, 22792 の TRIS から算出）。
  - 3D の画面の UV：左画面は fms3 の群、中央画面は fms1 の群の領域を読む（747-400_cockpit.obj の TRIS 20808-21113 から算出）。
  - 電源の割り当て：B747.03.xt.electrical.lua:615-626 のコメント（[6]=FMS C、[7]=FMS R、[8]=FMS L）とも合う。
- パネル群の名前 "FMS L"/"FMS C" は物理と逆。ATA-24 の ELEC-07（「CDU L/R は F/O 側、CDU C は機長側」）はパネル群の名前による読み違いで、実際は L=機長側、C・R=F/O 側。
- 純正 acf とカスタム acf の CDU パネル定義（3 群）は同一。該当範囲の md5 で確認した。

**キーの対応**：コマンド名は汎用 CDU の名前で、744 の刻印とは違う。対応はキーの位置で決まる（747-400_cockpit.obj から算出、B744.createfms.lua:44-121）。

| コマンド（`.../func_key/…`） | 744 のキー | 現在の動作 |
|---|---|---|
| index | INIT REF | 独自の INIT/REF INDEX を常に表示 |
| fpln | RTE | 標準 FMS の FPLN キーを押し、独自の RTE1（混成）を表示 |
| clb | DEP ARR | 標準 FMS の DEP/ARR ページ |
| crz | ATC | 独自の ATC INDEX |
| des | VNAV | 独自の VNAV 1/3 を常に表示 |
| dir_intc | FIX | 標準 FMS の FIX ページ |
| legs | LEGS | 標準 FMS の LEGS（独自の枠付き）。XP 12.0.12 未満の空中では標準の DIR INTC |
| dep_arr | HOLD | 標準 FMS の HOLD ページ |
| hold | FMC COMM | 独自の FMC COMM |
| prog | PROG | 独自の PROGRESS |
| fix | MENU | 独自の MENU（INDEX） |
| navrad | NAV RAD | 独自の NAV RADIO |
| prev_pg / next_pg | PREV / NEXT PAGE | 独自ページはページ番号を増減。標準ページは標準へ送る |
| `.../key/execute` | EXEC | 標準 FMS の EXEC を押すだけ |

- 左と中央の CDU の NAV RAD キーの manipulator は、CDU のキー列から外れた位置にある（fms1：x=-0.20, z=5.11、fms3：z=5.465）。3D 側の問題とみられ、範囲外（9 章）。

## 3. 操作と表示

### 3.1 キーと scratchpad の規則（実機）

- **文字の入力**：英数字は左から scratchpad に入る（FMSPG p.41 (2-29)）。メッセージが出ている間は scratchpad に入力できない（FMSPG p.39 (2-27)）。
- **+/-**：1 回目は "-"。続けて押すと "+"、"-" と交互に切り替わる（FCOM p.1212 (11.10.6); FMSPG p.42 (2-30)）。
- **CLR**：
  - 1 回押すと最後の 1 字を消す。メッセージがあればメッセージを 1 つ消す。
  - 1 秒以上押し続けると scratchpad 全体を消す。
  - 最後のメッセージを消すと MSG 灯が消える。
  - 根拠：FCOM p.1213 (11.10.7); FMSPG p.43 (2-31)。
- **DEL**：
  - scratchpad が空のときだけ "DELETE" を入れる。データかメッセージがあれば効かない。
  - CLR で DELETE を取り消せる。
  - DELETE を LSK で行に送ると、既定値・ダッシュ・ボックス・空白に戻る。削除できない項目では INVALID DELETE。
  - 根拠：FCOM p.1213, p.1237 (11.31.3), p.1435; FMSPG p.43。
- **LSK**（FCOM p.1209-1210 (11.10.3-4); FMSPG p.40, p.49）：
  - scratchpad → 行への入力。
  - scratchpad が空なら行 → scratchpad への複写（複写できる項目だけ）。
  - ページや手順の選択（`<`・`>` 付き）。
  - DELETE の送り込み。
- **規則**（FCOM p.1210）：
  - 空の行には送れない。空の scratchpad は送れない。
  - 変更できない項目がある。
  - 不適切な入力ではメッセージが出る。
- scratchpad の入力と消去は、その CDU だけに効く。FMC のメッセージは両 CDU に同時に出て、同時に消える（FMSPG p.39）。ページを替えても scratchpad は消えない（FMSPG p.43）。
- **字体とプロンプト**（FCOM p.1213-1214; FMSPG p.48 (2-36)）：
  - 大字：乗員の入力・確認済みの値。小字：FMC の計算値・既定値・予測値、見出し行。
  - ボックス：必須の入力。ダッシュ：任意の入力。
  - `<`/`>`：ページへの移動や操作。
  - 題名の ACT/MOD：アクティブか、変更中か。
- **入力の形式**（FCOM p.1269-1270 (11.31.35-36)）：
  - 高度：XXX（100 ft 単位、先頭の 0 が必要）、XXXX（≦9,994 ft、10 ft に丸め）、XXXXX、FLXXX。表示は transition altitude で ft か FL か決まる。-1000 ft まで入力できる。
  - 速度：CAS は 3 桁、Mach は小数点の後ろ 1-3 桁。
  - 対の値：
    - 外側（LSK 側）の値だけなら `/` は不要。内側の値だけなら `/` が必要。
    - `/` が抜けていると通常 INVALID ENTRY。
    - FMSPG は「中央寄りの項目は `/` 必須、LSK 側は任意」と同じことを書いている（FMSPG p.41）。

### 3.2 メッセージ

FMC のメッセージは重要度の順に出す。CLR か条件の解消で、次のメッセージに替わる。alert メッセージは EICAS に >FMC MESSAGE を出す。どのメッセージでも CDU の MSG 灯が点く（FCOM p.1430 (11.60.2); FMSPG p.255-256 (6-1, 6-2)）。

| メッセージ | 種類 | 条件（要約） | 根拠 | コードの状態 |
|---|---|---|---|---|
| >FMC MESSAGE | EICAS advisory | 優先度の高い FMC メッセージがある | FCOM p.1429 | alert 表の通知がひとつでもあれば advisory 145 を立てる（B747.68.xt.fms.lua:1131-1135） |
| FMC LEFT / FMC RIGHT | EICAS advisory | その FMC が故障 | FCOM p.1429 | 表（warning.lua:330-332）にあるが、立てる処理なし |
| INVALID ENTRY | advisory | 入力の形式・範囲の誤り。航路の不整合 | FCOM p.1435 | 独自ページの一部で出す（3.3）。多くの項目は検査なし |
| INVALID DELETE | advisory | 削除できない項目への DELETE | FCOM p.1435 | 出さない（ほぼ全項目を既定値に戻す） |
| DELETE | advisory | DEL キー | FCOM p.1435 | DEL で scratchpad に "DELETE" を入れる |
| KEY/FUNCTION INOP | advisory | 機能がない | FCOM p.1435 | 割り当てのない LSK で出す（B744.createfms.lua:183-185） |
| TAKEOFF SPEEDS DELETED | advisory | V speeds が無効になった | FCOM p.1309, p.1314-1315, p.1319-1320 | GR WT/ZFW の入力時だけ（B744.fms.pages.lua:1401-1407, 1429-1435） |
| MAX ALT FLXXX / UNABLE CRZ ALT | advisory | CRZ ALT が性能の上限を超える／T/D と干渉 | FCOM p.1435-1436 | なし。代わりに独自の "INVALID CRZ ALT"（B744.fms.pages.lua:1203） |
| NOT IN DATA BASE, ROUTE FULL ほか航路系 | advisory | — | FCOM p.1435 | 標準 FMS の scratchpad から写ったものだけ |
| STANDBY ONE / TIME OUT - RESELECT | advisory | 応答が 4 秒超／相手システムとの通信断で MENU 表示 | FCOM p.1435 | なし |
| NAV DATA OUT OF DATE | alert | 日付が DB の有効期間を過ぎた（地上だけ表示：FMSPG） | FCOM p.1433; FMSPG p.63 | 標準 FMS が出すと自動で CLR して消している（B744.createfms.lua:520） |
| ENTER IRS POSITION | alert | IRS の位置が未入力、または比較で不合格 | FCOM p.1431 | IRS 側で立てる（irs_system.lua:106） |
| PERF/VNAV UNAVAILABLE | alert | GW・CI・CRZ ALT なしで VNAV | FCOM p.1433 | CRZ ALT だけを見る（autopilot.lua:1025-1027） |
| RESET MCP ALT / DRAG REQUIRED | alert | — | FCOM p.1431, p.1433 | autopilot 側で立てる（monitor.lua:455-465; autopilot.lua:3400-3412） |
| RW/ILS CRS ERROR | alert | ILS コースが目的地滑走路と不一致 | FCOM p.1434 | APP/LOC を押したとき ILS 未同調だと出す（意味が違う：autopilot.lua:2398, 2431） |
| DESTINATION NOT SET | — | 実機になし | — | sim 独自（autopilot.lua:2379） |
| その他の alert（VERIFY POSITION、INSUFFICIENT FUEL、UNABLE NEXT ALT、SINGLE FMC OPERATION、END OF ROUTE など） | alert | — | FCOM p.1431-1435 | 表（B744.notifications.lua:3-56）にあるが、立てる処理なし |

### 3.3 ページ対応表

状態：yes＝独自ページで動く／一部＝独自ページだが項目や動作が欠ける／標準依存＝X-Plane 標準 FMS のページを写すだけ（744 との一致は未確認）／mock-up＝固定文字だけ／no＝ない。

**MENU・起動・preflight**

| 実機のページ（入口） | コード | 状態 | 主な差異（項目・プロンプト・字体・LSK） | 根拠 | 該当コード |
|---|---|---|---|---|---|
| MENU（MENU キー、電源投入時） | INDEX | 一部 | 配置（1L <FMC、2L <ACARS、3L <SAT、5L <ACMS、6L <CMC、1R/2R SELECT>）は FCOM の図と一致。<ACT> は常に FMC。<SAT は無効。EFIS CP・EICAS CP の SELECT> が常に出る（FMSPG は操作パネル故障時だけ、FCOM の -161 は CTL PNL ON か故障時）。CDU-161 の CTL PNL OFF/ON がない。<FMC は常に IDENT を開く（実機は最後に使ったページ）。sim 独自の GROUND HANDLING（4R）と AIRCRAFT CONFIG（6R）がある | FCOM p.1322-1324 (11.40.46-48), p.1061-1062; FMSPG p.53 (2-41), p.238 (5-1) | B744.fms.pages.lua:29-93 |
| INIT/REF INDEX | INITREF | yes | 項目は一致。空中で <TAKEOFF を消す（FMSPG の空中の図では <TAKEOFF は残り、消えるのは MAINT> だけ）。INIT REF キーの文脈による分岐はない（4.5） | FCOM p.1280-1281; FMSPG p.66-68 (3.2-6〜8, 図 3.2-8) | B744.fms.pages.lua:312-351 |
| IDENT | IDENT | 一部 | NAV DATA の識別子、非アクティブ DB の期間と ACTIVE への切替、OPC がない。CO DATA が入力できる（実機は表示のみ）。DB の日付は標準 FMS の行から取る | FCOM p.1282-1284; FMSPG p.62-65 | activepages/B744.fms.pages.identpage.lua:4-53 |
| POS INIT 1/3 | POSINIT p1 | 一部 | 配置は一致。GATE を入れると機体の現在位置が入る（ゲート DB がない）。SET HDG と SET IRS POS の表示条件は IRS 側の判定。IRS 部分は航法のノート | FCOM p.1285-1287; FMSPG p.68-73 | activepages/B744.fms.pages.posinit.lua:3-42; B744.fms.pages.lua:1085-1111, 1278-1289 |
| POS REF 2/3 | POSINIT p2 | 一部 | RNP/ACTUAL は固定値で、RNP の入力ができない。<PURGE・GPS NAV INHIBIT>・BRG/DIST> に割り当てがない。見出し "FMS POS" は repo の画面写しと同じ（FCOM の図は FMC POS） | FCOM p.1367-1369; FMSPG p.74-75 | posinit.lua:43-81 |
| POS REF 3/3 | POSINIT p3 | 一部 | BRG/DIST> に割り当てがない | FCOM p.1370; FMSPG p.76 | posinit.lua:82-104 |
| RTE 1 page 1 | RTE1（混成） | 一部 | 題名が "ACT RTE 1" 固定。6 行目を独自の文字で上書きするため、ACTIVATE>・ERASE が出ない。地上の 6L は KEY/FUNCTION INOP、6R は未アクティブでも PERF INIT。FLT NO は標準 FMS へ送るだけで、FMC の便名（ACARS・ATC が使う）にならない。RUNWAY はローカルに保存するだけ。REQUEST・LOAD・PURGE（405/570）はない | FCOM p.1288-1295; FMSPG p.78-85, p.92-93 | B744.fms.pages.lua:95-244 |
| RTE 1 page 2/X（VIA/TO） | RTE1 p≥2 | 標準依存 | 標準の行の写し。題名は "ACT RTE 1" 固定、字体の区別なし、6 行目は上書き | FCOM p.1296-1298 | B744.fms.pages.lua:131-152 |
| RTE OFFSET（空中、RTE 6R） | RTE1 R6 | 一部 | L/R XX の入力は可。MOD/EXEC を通らず即時に効く。OFST 灯と END OF OFFSET がない | FCOM p.1298-1299; FMSPG p.155-156 | B744.fms.pages.lua:107-121, 1124-1145 |
| RTE 2（全ページ） | なし | no | <RTE 2 は標準 FMS の DIR INTC ページを開く | FCOM p.1287, p.1292 | B744.fms.pages.lua:123, 554-557 |
| DEP/ARR INDEX・DEPARTURES・ARRIVALS | 標準 FMS の DEP/ARR | 標準依存 | DEP ARR キーの文脈による分岐（地上で active route があれば DEPARTURES、空中は目的地の ARRIVALS、離陸直後は出発地の ARRIVALS）は標準任せ。全行が大字。<SEL>/<ACT> と ERASE/INDEX の切替は未確認 | FCOM p.1299-1302, p.1343-1344, p.1400-1408; FMSPG p.86-91, p.194-200 | B744.createfms.lua:57-62 |
| NAV RADIO | NAVRAD | 一部 | 識別子での VOR 入力ができない（識別子を入れると autotune に戻る）。周波数/コースの同時入力もできない。状態は A/M だけ（P/R なし）。ADF の ANT/BFO（A/B 接尾）がなく、状態は "M" 固定。ILS の PARK/A は T/D までの距離だけで決める。ILS TUNE INHIBITED がない | FCOM p.1303-1307; FMSPG p.205-211 | B744.fms.pages.lua:355-513, 2549-2567 |
| PERF INIT | PERFINIT | 一部 | FUEL は常に sim の燃料量で、見出しは CALC 固定（SENSED/MANUAL なし、手入力は保存されるが使われない）。"GR WT ADV" と `<` 付きの値は 405 の WBS 仕様（109/570 はボックス）。COST INDEX と CRZ CG の範囲検査がない（CRZ CG に文字を入れると描画エラー：CDU-09）。CRZ ALT は標準 FMS 経由で設定する | FCOM p.1307-1312; FMSPG p.94-99 | activepages/B744.fms.pages.perfinit.lua:15-141; B744.fms.pages.lua:1187-1209, 1367-1466 |
| THRUST LIM（地上） | THRUSTLIM | 一部 | SEL（仮定温度）の範囲検査・"D-" 表示・25 % 上限がない。TO EPR/N1 の行に入力できる（実機は表示のみ）。定格や SEL を変えても TAKEOFF SPEEDS DELETED を出さない。TO 1/TO 2 の % は固定の 10/20。derate を選んでも SEL を消さない | FCOM p.1312-1316; FMSPG p.100-103 | activepages/B744.fms.pages.thrustlim.lua:9-49, 165-173 |
| TAKEOFF REF | TAKEOFF | 一部 | フラップを入れると V speeds を直接 PFD に出し、大字で表示する（REF 付き小字の計算値→選択の流れがない）。ACCEL HT、E/O ACCEL HT、THR REDUCTION は固定文字で入力できない。WIND/SLOPE がない。滑走路と POS SHIFT は固定の "RW***"/"--00M"。PRE-FLT が固定（未完了ページへの誘導と THRUST LIM> がない）。V1MIN がない。V speeds の入力範囲が 100-200（実機は 100-300：FMSPG） | FCOM p.1316-1321; FMSPG p.104-109 | activepages/B744.fms.pages.takeoff.lua:23-135; B747.60.xt.fltInst02.lua:2783-2812 |

**離陸・上昇・巡航**

| 実機のページ | コード | 状態 | 主な差異 | 根拠 | 該当コード |
|---|---|---|---|---|---|
| CLB（VNAV 1/3） | VNAV p1 | 一部 | 題名に速度モード（XXXKT、M.XXX、MCP SPD、LIM SPD、E/O）が出ない。ACT は飛行段階だけで決まり、MOD がない。ECON SPD は CAS の単値（実機は CAS/Mach）。SEL SPD の見出しがない。SPD TRANS が入力できる（実機は削除のみ）。AT 制限を削除できない。<ECON（5L）がなく、ENG OUT>（5R）・CLB DIR>（6R）に割り当てがない。行の配置は FCOM の図と一致 | FCOM p.1327-1329; FMSPG p.111-118 | activepages/B744.fms.pages.vnav.lua:47-175; B744.fms.pages.lua:1000-1033 |
| E/O CLB | なし | no | — | FCOM p.1341-1342; FMSPG p.115-116 | なし |
| RTE LEGS（ACT/MOD、DIR/INTC、ABEAM PTS、RTE COPY、HOLD AT、CTR STEP、GP 角） | LEGS（標準を写す） | 標準依存 | 題名が "ACT RTE 1 LEGS" 固定で、MOD と非アクティブが見えない。全行が大字。DELETE を文字列として標準 FMS へ打ち込む（CDU-17） | FCOM p.1330-1334, p.1405; FMSPG p.119-129, p.134-145 | activepages/B744.fms.pages.legs.lua:1-53; B744.fms.pages.lua:598-614 |
| SELECT DESIRED WPT | 標準 FMS | 標準依存 | 未確認 | FCOM p.1335-1336; FMSPG p.175-177 | — |
| THRUST LIM（空中） | THRUSTLIM | 誤り | <GA・<CON・<CRZ の LSK が TO/TO1/TO2 の処理につながっており、CLB/CLB 1/CLB 2 を選ぶうえ TO derate も変える（CDU-10）。推力値（EPR/N1）を表示しない。<SEL> が EICAS の推力モードと連動しない | FCOM p.1337-1340; FMSPG p.103-104 | thrustlim.lua:50-69, 166-168 |
| CRZ（VNAV 2/3） | VNAV p2 | 一部 | 題名にモード（CRZ CLB/DES、LRC、XXXKT、M.XXX、MCP SPD、LIM SPD、E/O、RTA）が出ず、MOD もない。速度の入力は Mach だけ。<ECON がない。"N1 %" 固定（109/405 は EPR）。STEP SIZE は固定文字 "ICAO" で、PERF INIT の値を映さず、入力もできない。STEP TO を入力しても描画のたびに上書きされる。ENG OUT> に割り当てがない。<RTA PROGRESS が標準 FMS の PROG を開く | FCOM p.1346-1350; FMSPG p.130-133, p.152-154 | vnav.lua:176-331; B744.fms.pages.lua:529-533, 1034-1045 |
| E/O CRZ（D/D を含む） | なし | no | — | FCOM p.1350-1353 | なし |
| LRC CRZ | LRC | 誤り | 実機は CRZ と同じ配置の MOD LRC CRZ で、EXEC で LRC になる（FCOM p.1347, p.1350）。コードは別の配置（OPT/MAX、TGT SPD、TURB N1、FUEL AT DEST）で、題名は "ACT LRC CRZ" 固定。実行の概念がない | FCOM p.1347, p.1350 | activepages/B744.fms.pages.vnav.lrc.lua:5-129 |
| RTA CRZ | なし | no | — | FCOM p.1354 | なし |
| REF NAV DATA | なし | no | NAV DATA> は標準 FMS の INDEX 2R のページを開く。NAVAID INHIBIT、VOR ONLY INHIBIT、VOR/DME NAV INHIBIT がない（refonly の雛形は未ロード） | FCOM p.1355-1357; FMSPG p.170-174 | B744.fms.pages.lua:351, 545-549 |
| FIX INFO 1/2・2/2 | 標準 FMS の FIX | 標準依存 | 未確認 | FCOM p.1358-1359; FMSPG p.166-169 | B744.createfms.lua:74-79 |
| RTE DATA / WIND | なし | no | 標準 FMS にあるかは未確認。refonly に静的雛形 | FCOM p.1360-1366; FMSPG p.120-124 | refonly/B744.fms.pages.actrte1data.lua |
| PROGRESS 1/3 | PROGRESS p1 | 一部 | 題名に便名がない。LAST の ALT が空白。DEST 行への入力（DIR TO ALTERNATE、EN ROUTE WPT、MOD）がない。速度行の見出しは "SEL SPD" 固定で、値は MCP の速度。TO の行は T/D・T/C だけ（STEP CLB、E/D、LEVEL AT がない）。予測値はページ内の簡易計算（FMC のノート） | FCOM p.1371-1376; FMSPG p.146-148 | activepages/B744.fms.pages.progress.lua:46-140, 216-242 |
| PROGRESS 2/3 | PROGRESS p2 | 一部 | XTK ERROR の前に常に "L"。VTK ERROR は固定の "+**FT"。<USE（2 つ）に割り当てがない。TOTALIZER と CALCULATED が同じ値で、FUEL DISAGREE がない | FCOM p.1380-1382; FMSPG p.149-151 | progress.lua:142-192, 243-262 |
| RTA PROGRESS 3/3 | PROGRESS p3 | mock-up | 固定文字。FIX、RTA、MAX SPD の入力がない | FCOM p.1383-1385; FMSPG p.181-184 | progress.lua:193-212 |
| POS REPORT（109） | POSREPORT（ATC 版） | 一部 | 3.4 参照 | FCOM p.1386-1387 | activepages/atc/B744.fms.pages.posreport.lua |
| RTE HOLD・HOLD AT | 標準 FMS の HOLD | 標準依存 | HOLD キーの分岐（hold がなければ LEGS の HOLD AT、あれば RTE HOLD）、EXIT HOLD/ARMED、BEST SPEED、HOLD AVAIL は標準任せ。未確認 | FCOM p.1413-1419; FMSPG p.157-165 | B744.createfms.lua:94-99 |

**降下・進入・代替機能・保守**

| 実機のページ | コード | 状態 | 主な差異 | 根拠 | 該当コード |
|---|---|---|---|---|---|
| DES（VNAV 3/3） | VNAV p3 | 一部 | E/D がなくても題名 "DES" だけの空白ページにならない。題名にモード（XXXKT、END OF DES、MCP SPD など）が出ず、MOD もない。SPD TRANS が入力できる。AT 制限を削除できない。FORECAST>・<OFFPATH DES・DES DIR>/DES NOW> に割り当てがない。FPA・V/B・V/S の行は 570 仕様で、WPT/ALT の入力はない | FCOM p.1389-1394; FMSPG p.186-190 | vnav.lua:332-449; B744.fms.pages.lua:1046-1084 |
| DESCENT FORECAST | なし | no | refonly の雛形だけ | FCOM p.1395-1397; FMSPG p.178-179 | refonly/B744.fms.pages.descentforecast.lua |
| OFFPATH DES | なし | no | — | FCOM p.1398-1399; FMSPG p.191-193 | なし |
| APPROACH REF | APPROACH | 一部 | 4R を空の scratchpad で押すと FLAP/SPEED が消える（CDU-28）。入力は "XX/YYY" だけ。GROSS WT は入力しても使われない。滑走路と長さの行は固定の伏せ字 | FCOM p.1409-1412; FMSPG p.203-205 | activepages/B744.fms.pages.approach.lua:6-56; B744.fms.pages.lua:1342-1366 |
| EFIS CONTROL | EFISCTL152 | 一部 | BARO と RANGE が両席に効く。BARO・DH・MDA に範囲と単位の検査がない（I/H 指定、hPa 745-1084、inHg 22.00-32.00 など）。RANGE が 640↔10 で循環しない。いつでも開ける | FCOM p.1062-1064; FMSPG p.239-241 | activepages/B744.fms.pages.efisctl.lua:2-99; B744.fms.pages.lua:905-992 |
| EFIS OPTIONS | EFISOPTIONS152 | 一部 | CDU-152 と -161 の項目が混在（TERR/TFC はあり、MTRS/FPV はない）。<POS と DATA> に割り当てがない | FCOM p.1065-1067; FMSPG p.242-243 | efisctl.lua:106-164 |
| EICAS MODES / EICAS SYNOPTICS | EICASMODES / EICASSYN | yes | 2 ページ目の題名も "EICAS MODES"。LSK の配置は FCOM と一致（FMSPG は CANC/RCL を 3L/3R と書く） | FCOM p.1067-1068; FMSPG p.244-246 | activepages/B744.fms.pages.eicasctl.lua:11-67 |
| IRS LEGS・IRS PROGRESS・ALTN NAV RADIO | なし | no | refonly の雛形は未ロード | FCOM p.1421-1428; FMSPG p.247-254 | refonly/B744.fms.pages.actirslegs.lua, irsprogress.lua, altnnavradio.lua |
| MAINTENANCE INDEX | MAINT | mock-up | <INDEX が ACMS を開く（実機は INIT/REF INDEX） | FCOM p.1239 (11.31.5); FMSPG p.263 | activepages/B744.fms.pages.maint.lua:1-27 |
| CROSS LOAD・PERF FACTORS・BITE | 各ページ | mock-up | 固定文字。PERF FACTORS の値は TAKEOFF REF の既定値と連動しない | FMSPG p.264-268 | maintcrossload.lua, maintperffactor.lua, maintbite.lua |
| IRS MONITOR | MAINTIRSMONITOR | yes | 値は IRS 側 | FMSPG p.269 | maintirsmonitor.lua |
| ACMS・CMC | ACMS・CMC | mock-up | 他の系統（ATA 31・45）の範囲 | FCOM p.1323-1324 | acms.lua, cmc.lua |
| SATCOM | なし | no | <SAT は無効。repo に実機画面の写しがある | FCOM p.717-718 | B744.fms.pages.lua:52 |

- sim 独自のページ（実機にない）：GROUND HANDLING、PAX/CARGO、DOORS、AIRCRAFT CONFIG（SIM CONFIG）、SOUND CONFIG。実機の挙動とは関係しないので、残すかどうかは方針で決める。

### 3.4 データリンク（要約）

- **実機**（FCOM 5.33・5.34; FMSPG 8・9 章）：
  - ATC キーは状態で振り分ける：未接続なら LOGON/STATUS、新着 1 件なら XXXXz ATC UPLINK、複数なら ATC LOG、それ以外は ATC INDEX。接続中に押し続けると EMERGENCY REPORT（FMSPG p.44, p.277, p.286; FCOM p.728, p.752, p.755, p.758）。
  - ログオン：1R が SEND → SENDING → SENT → ACCEPTED/REJECTED（RESEND あり）。接続が確立すると ATC COMM ESTABLISHED（FCOM p.755-757, p.1431）。
  - アップリンク：ACCEPT（WILCO/ROGER/AFFIRM）、REJECT（UNABLE/NEGATIVE、DUE TO）、STANDBY、LOAD。LOAD は現用ルートに MOD を作り、乗員が EXEC か ERASE する（FCOM p.759-765; FMSPG p.288-297）。
  - ATC MESSAGE（メモ、小さなチャイム）。FMC COMM 1/2・2/2、RTE の REQUEST/LOAD/PURGE、風・降下予報・PERF・TAKEOFF のアップリンク（FCOM p.771-776, p.1289-1291）。
- **コード**：
  - ATC INDEX、LOGON/STATUS、REQUEST（ALT/SPEED/OFFSET/ROUTE）、WHEN CAN WE、EMERGENCY、VERIFY 系、POS REPORT、ATC LOG（ACARS の一覧で代用）、FMC COMM がある。
  - アップリンク画面は ACARS の電文表示で代用。STATUS・ACCEPT・REJECT・STANDBY・LOAD・ARM はない。応答は WILCO/UNABLE の手入力だけ（acars/acars.pages.lua:229-342）。
  - REJECT DUE TO のファイルは dofile されない。ATC REPORT は固定文字（activepages/atc/B744.fms.pages.atcreport.lua:2-60）。
- **プロバイダ**：AutoATC（`autoatc/acars/*`）と Hoppie（AutoATC の通信を経由）。
  - Hoppie は受信の解析が空で、何も届かない（acars/autoatcHoppieProvider.lua:17-41）。
  - AutoATC の SQUAWK 電文がトランスポンダのコードを直接書き換える。COM 周波数と ACP の同期もする。実機にない連携（acars/autoatcProvider.lua:73-96, 316-428）。
- **EICAS**：未読があれば ACARS MESSAGE メモを出す。オフラインで中央 RTP が ON だと、FCOM にない ACARS NO COMM メモを出す（B747.68.xt.fms.lua:1240-1265）。ATC MESSAGE と >DATALINK LOST/AVAIL/SYS は出ない。
- **扱いの方針**：109 にはデータリンクがない。sim の機能として simconfig で入切できる形にし、入のときは 405/570 の挙動に合わせる（推定。方針の判断が要る）。

## 4. 内部ロジック

### 4.1 キー処理と scratchpad（作るべき状態機械）

- CDU ごとに持つ状態：scratchpad の文字列（最大 24 字）、メッセージの列、表示中のメッセージ、DELETE 状態、+/- の直前状態、現在ページとページ番号、MSG 灯。
- **英数字・`/`・`.`・SP**：
  - メッセージ表示中は受け付けない（FMSPG p.39）。
  - SP は ACARS/SATCOM の使用中だけ有効（FCOM p.1213）。
- **+/-**：
  - 直前のキーが +/- なら、末尾の "-" と "+" を入れ替える。
  - それ以外なら "-" を足す（FCOM p.1212）。
- **CLR**：
  - 押下（phase 0）で、メッセージ表示中なら 1 件消して次のメッセージへ。なければ末尾の 1 字を消す。DELETE 状態なら取り消す。
  - 押し続け（phase 1 で duration ≥1 秒）で全消去（FCOM p.1213; FMSPG p.43）。
- **DEL**：
  - scratchpad が空で、メッセージがないときだけ DELETE 状態にする。
  - それ以外は効かない（FMSPG p.43）。
- **LSK**：ページの項目定義で決まる。種類は 5 つ。
  1. 入力欄：scratchpad を検査し、合格なら値を設定して scratchpad を消す。不合格なら INVALID ENTRY を出し、scratchpad の内容は残す（推定。メッセージは scratchpad の内容に関係なく上に出る：FMSPG p.255）。
  2. 複写できる欄：scratchpad が空なら値を scratchpad に写す。ボックスやダッシュは写さない（FCOM p.1210）。
  3. プロンプト：ページの移動や操作。
  4. DELETE：削除できる欄なら既定値に戻す。できない欄なら INVALID DELETE。
  5. 割り当てなし：何もしないか KEY/FUNCTION INOP。どちらかは資料に明記なし。
- **メッセージの列**：
  - FCOM の alert（EICAS に FMC MESSAGE）と advisory を分け、優先順に並べる。
  - 条件が解消したメッセージは列から消す（FCOM p.1430）。
  - advisory（入力の誤りなど）は操作した CDU にだけ出す。alert は全 CDU に出し、どの CDU で CLR しても全 CDU から消す（FMSPG p.39）。
  - MSG 灯は列が空でなければ点灯。EICAS の FMC MESSAGE は alert が 1 件でもあれば出す。

### 4.2 入力の検査（代表）

- **高度**：3.1 の規則。
  - CRZ ALT（PERF INIT）は、地上では現在高度より上。空中ではボックスへの入力は可だが、既存の値の上書きは不可（CLB/CRZ ページで変える）。最大認定高度を超えると INVALID ENTRY（FMSPG p.97 (3.2-37), p.131）。
  - 性能上の MAX を超える値は受け付け、MAX ALT FLXXX を出す（FMSPG p.131 (3.4-2)）。
- **速度**：
  - CLB/CRZ/DES の速度欄は CAS 100-400、Mach .100-.990、CAS/Mach の対（FMSPG p.113 (3.3-4), p.132）。
  - SPD RESTR は CAS/高度。高度は現在高度以上かつ巡航高度未満（上昇）（FMSPG p.114）。DES 側は E/D より上、現在高度より下（FMSPG p.188）。
- **重量**：XXX か XXX.X。性能 DB で妥当性を見る（FCOM p.1309-1311; FMSPG p.95）。
- **COST INDEX**：0-9999。T/D の 10 NM 以内は INVALID ENTRY（FMSPG p.97）。
- **CRZ CG**：8.5-33.0（FCOM p.1311）。
- **STEP SIZE**：0-9000（1000 単位）か ICAO（FCOM p.1312）。
- **TAKEOFF REF**：
  - FLAP は 10/20。ACCEL HT と E/O ACCEL HT は 400-9999 HAA。THR REDUCTION は 5（FLAPS 5）か 400-9999（FCOM p.1318-1319）。
  - WIND は H/T と 1-2 桁、SLOPE は U/D と 0.0-2.0（FMSPG p.106）。
  - CG は 0-40（FCOM p.1320）。POS SHIFT は ±（109 は m、570 は ft の 100 単位）（FCOM p.1321）。
- **THRUST LIM の SEL**：0-99 °C か 32-210 °F（FCOM p.1314）。
- **NAV RADIO**：
  - VOR：識別子か周波数（XXX.X/XXX.XX）、または識別子/周波数とコースの組。
  - ADF：XXX.X/XXXX.X に A か B を付けてもよい。
  - ILS：周波数/コース、または /コース（FCOM p.1304-1305）。
- **EFIS CONTROL**：
  - BARO：22.00-32.00、2200-3200、745-1084、I、H、S、STD。
  - DH：20-999（-161 は RAD で -20-999）。
  - MDA：-1001-15000（FCOM p.1064; FMSPG p.240）。

### 4.3 MOD/ACT/EXEC/ERASE

- **MOD になる変更**：現用ルートか現用の性能モードを変えたとき。題名が MOD になり、6L に ERASE が出て、EXEC 灯が点く。EXEC で反映、ERASE で取り消し（FCOM p.1238 (11.31.4); FMSPG p.42）。
- 例：
  - CLB の速度の入力 → EXEC で ACT 320KT CLB になる（FMSPG p.118）。
  - CRZ ALT の入力で、題名が CRZ CLB/CRZ DES になる（FCOM p.1348）。
  - OFFSET → EXEC（FMSPG p.156）。
  - DES DIR/DES NOW → EXEC（FMSPG p.188-189）。
  - ENG OUT → MOD（FCOM p.1350）。
  - RTA → EXEC（FCOM p.1385）。
- **EXEC なしで反映する変更**：preflight の入力（PERF INIT、THRUST LIM など）、MCP の高度ノブによる CRZ ALT の変更（FCOM p.1348; FMSPG p.180）。
- **ルートの activation**：ACTIVATE → EXEC。activation 後、6R は PERF INIT（性能データが未完のとき）か TAKEOFF に替わる（FCOM p.1290; FMSPG p.92-93）。
- **同時の変更**：一度に処理するルート変更は 1 つだけ（FMSPG p.49）。左右の CDU は同じ MOD を見る（推定。FMC が 1 つの MOD を持つため）。

### 4.4 ページ番号と NEXT/PREV

- ページ番号は右上に小字で出す（FMSPG p.48）。
- NEXT は次のページへ進み、最終ページでは 1 ページ目に戻る（FMSPG p.42）。PREV は前のページへ（FMSPG p.43）。
- VNAV の CLB/CRZ/DES は 1/3・2/3・3/3 の連続ページで、VNAV キーはアクティブなフェーズのページを開く（FMSPG p.111, p.130, p.186）。

### 4.5 機能キーの選択ロジック（文脈で変わるもの）

- **INIT REF**：
  - 地上で IRS 位置が未入力（または ATT の IRU があるとき）→ POS INIT（FCOM p.1285）。
  - 地上で IRS 位置が入力済み → PERF INIT（FCOM p.1308; FMSPG p.94）。
  - 空中 → APPROACH REF（FCOM p.1409; FMSPG p.203）。
  - それ以外の場合は資料に記載なし。
- **VNAV**：アクティブなフェーズの CLB/CRZ/DES（FMSPG p.111）。
- **DEP ARR**（FCOM p.1299, p.1301, p.1343, p.1401）：
  - active route がないか、非アクティブの RTE/LEGS を表示中 → DEP/ARR INDEX（非アクティブ側の DEPARTURES も）。
  - 地上で route がアクティブ → DEPARTURES。
  - 上昇中で出発地から 400 NM 未満かつ目的地より出発地に近い → 出発地の ARRIVALS。
  - 空中で route がアクティブ → ARRIVALS。
- **HOLD**：hold がなければ RTE LEGS の HOLD AT ボックス。あれば RTE HOLD（FCOM p.1413, p.1416）。
- **ATC**：3.4 のとおり。109 では KEY/FUNCTION INOP。
- **LEGS・PROG・NAV RAD**：両 FMC が故障すると IRS LEGS、IRS PROGRESS、ALTN NAV RADIO（FCOM p.1422; FMSPG p.45-46）。

### 4.6 自動のページ変更と表示灯

- 570 では、フラップ上げを始めると TAKEOFF REF が VNAV CLB に替わる（FCOM p.1325 (11.41.1)）。109 については記載なし。
- THRUST LIM は推力が減ると空中用の表示に替わる（FMSPG p.103。ページが自動で開くのか表示が替わるだけなのかは文から読み切れない：推定）。
- **DSPY 灯**：表示中のページがアクティブな leg や性能モードと関係ないとき点灯（FCOM p.1210）。
- **OFST 灯**：offset 経路で LNAV 中に点灯（FCOM p.1210）。
- **FAIL 灯**：FMC の故障（FCOM p.1210）。

### 4.7 3 台の CDU と中央 CDU

- 左右の CDU は独立に操作でき、同じページでも別のページでも同時に入力できる。scratchpad も別々（FMSPG p.39, p.49）。
- FMC の操作手順として、両 CDU で同時に入力しない、resync 中（約 15 秒。その CDU は故障表示、もう一方は RESYNCING OTHER FMC）はキーを押さない（FCOM p.1277 (11.40.1)）。
- 中央 CDU：
  - 通常は ACARS・SATCOM 用（FCOM p.718）。
  - 代替航法では左右どちらの ND の情報源にも選べ、中央 ILS を同調する（FCOM p.1421-1422）。
  - FMC のページを使えるかは FCOM の記述（3 台で FMC を操作）による（1 章の食い違い）。

### 4.8 電源投入・故障・飛行終了

- **電源投入**：MENU を表示し、<FMC の横に <ACT>。<FMC を押すと初回は IDENT、以後は最後のページ（FMSPG p.53）。他のシステムが CDU を要求すると <REQ>（FCOM p.1324）。
- **FMC の故障**：
  - その CDU に MENU と TIME OUT - RESELECT を出す。NAV source selector を正常な FMC に回すと戻る（FCOM p.1422）。EICAS に FMC LEFT/RIGHT（FCOM p.1429）。
  - 1 台が使えなければ SINGLE FMC OPERATION。resync に失敗すると RESYNC FAIL - SINGLE FMC（FCOM p.1433-1434）。
- **両 FMC の故障**：
  - CDU が自前で代替航法を行う。航路は FMC から写したものを保持し、条件付き waypoint、offset、hold は消える。新しい waypoint は緯度経度だけ。
  - 3 台は独立に動き、自分の IRU を使う（FCOM p.1421-1422; FMSPG p.247）。
- **データの保持**：
  - PERF INIT の入力は電源喪失かエンジン停止で消える（FCOM p.1307）。
  - エンジン停止の 30 秒後に飛行完了となり、active flight plan と load data を消す（FCOM p.1236 (11.31.2)）。
  - LAST POS は電源を切っても残る（FMSPG p.70）。

### 4.9 現在のコードの動作（要約）

- **キーの受付**：押下（phase 0）だけを受ける（B744.createfms.lua:195-269）。ページ変更は 0.5 秒後に `switchCustomMode` で 3 台まとめて反映し、その間は画面全体（scratchpad を含む）を空白にする（B744.createfms.lua:36, 506-512; B747.68.xt.fms.lua:744-758）。
- **独自ページでの入力**：`setdata`・`setDref` が項目名ごとに分岐する。多くの項目は検査なしで共有データへ文字列のまま入る（B744.fms.pages.lua:2500-2507）。
- **標準ページ・混成ページでの入力**：`custom2fmc`・`key2fmc` が scratchpad を 1 字ずつ標準 FMS へ打ち込み、標準の LSK を押す（B744.fms.pages.lua:578-614）。キーの表は空白 " " を "space" という名前でしか持たないため（B744.createfms.lua:363-410）、空白を含む scratchpad をこの経路で送ると nil を呼んで Lua エラーになる。
- **CRZ ALT の同期**：巡航高度（`laminar/B747/autopilot/dist/cruise_alt`）が変わると、左 CDU のキーで標準 FMS の FPLN → CLB → NEXT を押し、値を打ち込んで R1 を押す（B744.fms.pages.lua:630-654）。どの CDU が標準ページを表示していても割り込む。
- **メッセージ**：通知の配列（`laminar/B747/fms/notification`）を 10 秒ごとに調べ、最も若い番号の 1 件だけを 3 台の notify に入れる。notify は scratchpad より優先して表示される（B747.68.xt.fms.lua:1110-1136; B744.createfms.lua:553-557）。
- **表示の更新**：毎フレーム 3 台とも描き直す。電源の有無は見ない（パネル側の表示条件だけ）（B747.68.xt.fms.lua:1233-1239）。

## 5. 他系統とのつながり

- **出力**（CDU の入力が他系統へ渡るもの）：
  - `laminar/B747/fms/data`（JSON）：
    - autopilot の vnavspd が costindex を読む（B747.70.xt.autopilot.vnavspd.lua:233）。
    - EEC が thrustsel（仮定温度）を読む処理は、コメントアウトされていて効かない（B747.42.xt.EEC.PW.lua:77-84）。
    - 新しい CDU でもキーの名前と意味を保つか、読む側と一緒に変える必要がある。
  - `laminar/B747/engine/derate/TO`・`/CLB`：EEC が推力モードと TOGA 推力の割引に使う（B747.42.xt.EEC.lua:624-628, 690-705）。
  - `laminar/B747/airspeed/flapsRef`・`V1`・`Vr`・`V2`：fltInst02 が V speeds を計算し、PFD に出す（B747.60.xt.fltInst02.lua:2783-2812）。`Vref`・`VrefFlap`：APPROACH REF の FLAP/SPEED。
  - `laminar/B747/fmc/elevator_trim`：TAKEOFF REF の TRIM。stab trim の green band に使う（B747.68.xt.fms.lua:459-460）。
  - 航法無線：`sim/cockpit2/radios/actuators/nav_frequency_hz` ほか、`laminar/B747/radio/ilsData`・`tuningmodes`（NAV RADIO と ILS 自動同調）。
  - LNAV：`laminar/B747/autopilot/lnav/xtk_target`（OFFSET）、`lnavHeading_mode`（direct-to。現在は LEGS で使っていない）。
  - EFIS/DSP の代替操作：ND のモード・range・中心、baro、DH・MDA、`laminar/B747/dsp/*` コマンド。
  - 地上作業：燃料（preselect、refuel）、payload、CG（`sim/flightmodel/misc/cgz_ref_to_default`）。
  - ND の補助値：`laminar/B747/nd/waypoint_eta`・`current_waypoint` など（B747.68.xt.fms.lua:918-1042）。このモジュールが作るので、作り直しても残す。
  - EICAS：advisory 145（>FMC MESSAGE）、memo 0（ACARS MESSAGE）・40（ACARS NO COMM）。
- **入力**（CDU が他系統から受けるもの）：
  - X-Plane 標準 FMS：CDU 1 の文字列、`xtlua/fms` の航路 JSON、`sim/FMS/*` コマンド。
  - IRS（`irsSystem`）。
  - autopilot：flightPhase、T/D・T/C・残距離、VNAV の状態。
  - 通知の配列：autopilot と IRS が書く。
  - 燃料・重量、ADC（OAT、TAS、風）、推力の目標（`EPR_target_bug`・`N1_target_bug`）、simconfig（エンジン型式・単位）、AutoATC/Hoppie。
- **電源**：CDU の表示の有無はパネル側（`display_has_power[6-8]` と `sim/cockpit/electrical/avionics_on`）だけで決まる。電源のモデルを作り直すときは、ATA-24 の公開 dataref に合わせてこの 3 要素を出し直す必要がある（2.2 の対応表）。

## 6. 実装上の注意

- **残す名前**（INTERFACES.tsv）：
  - キーのコマンド：`laminar/B747/fms1-3/{ls_key,func_key,alphanum_key,key}/*`。3D と FMOD が参照する。
  - 画面の dataref：`laminar/B747/fms1-3/LineNN_L`・`_S`（84 個）。
  - BRT ノブ：`laminar/B747/fms1-3/display_brightness`。fms2 と fms3 はまだ作られていない（INTERFACES で dynamic）。
  - 2.2 の交差した対応（fms1 のキーで fms3 の行を描く等）と、`func_key` の名前と刻印のずれは、そのまま守る必要がある。
- **パネルでできること**：
  - 24 字 × 14 行で、大字と小字の 2 行を重ねて描く。色は緑 1 色だけで、色分けはできない。
  - パネルは変更しない前提なので、表示は dataref の文字列で作る。
  - ボックスは "*"、度は "`" で表す（cleanFMSLine の慣習。B747.68.xt.fms.lua:85-91）。
- **表示灯**：MSG・DSPY・FAIL・OFST 灯を駆動する dataref も 3D の参照も見つからなかった。点灯させるには 3D の変更が要る（範囲外、承認が必要）。
- **EXEC 灯**：3D は X-Plane 標準の `sim/cockpit2/radios/indicators/fms_exec_light_pilot`・`_copilot` を読む（Cockpit_Pedestal1.obj:40911-40913）。
  - 独自の MOD で点けるには、これらに書く（X-Plane 側で書き込めるかは未確認）か、3D を付け替える必要がある。中央 CDU の EXEC 灯がどちらの dataref に属するかも未確認。
  - 旧フォークは annunciator[270] に付け替えた（OLD_FORK_NOTES §9。参照のみ）。
- **XTLua**：
  - CLR と ATC キーの長押しは、command handler の phase 1 と duration で判定できる。
  - ページの描画でエラーが起きると、after_physics の残りの処理が止まる（推定）。3 台の描画は分けて、`pcall` で保護するのが安全。
  - 描画は毎フレーム 3 台分あるので、計算はページの外（FMC のモデル）で行い、描画は文字列の組み立てだけにする。
- **標準 FMS の扱い**（作り直しの最大の分岐点）：
  - 案 (a)：航路の保存と LNAV の基準は X-Plane 標準 FMS に任せる。ただし CDU の表示はすべて Lua で作り（`xtlua/fms` から読む）、変更は Lua がコマンドで行う。
  - 案 (b)：航路のモデルを Lua に持ち、`xtlua/loadtoFMS` で標準へ流し込む。
  - いずれにしても、3 台が 1 つの標準 CDU のページ状態を共有する今の作りはやめる。
  - X-Plane には標準 CDU が 2 つ（`fms_cdu1/2`、`sim/FMS/`・`sim/FMS2/`）あるが、中央 CDU の分は無い。
  - 標準ページを残すなら、`fms_cdu1_style_line*` で大字と小字を分ける。
- **簡略化してよいもの**：
  - データリンク（sim の機能として）。保守ページ、ACMS、CMC、SATCOM の静的表示。ゲートの位置。WBS（405 だけ）。
  - RTE 2 は保存と表示だけでもよい（推定。LNAV は現用ルートしか使わない）。
- **簡略化してはいけないもの**：
  - scratchpad・CLR・DEL・メッセージの規則。
  - 高度・速度・重量・CRZ ALT の入力検査。
  - 現用データの MOD/EXEC/ERASE。
  - VNAV キーのフェーズ連動。
  - TAKEOFF REF の V speeds の計算→選択の流れ（PFD の表示に効く）。
  - THRUST LIM の空中の GA/CON/CRZ（EEC に効く）。
  - FMC MESSAGE の連動。

## 7. 現状実装との比較（GAP 候補）

| ID | 種別 | 重要度 | 規模 | 内容 | 根拠 | 該当コード |
|---|---|---|---|---|---|---|
| CDU-01 | 挙動の誤り | 高 | S | CLR は押すたびに scratchpad 全体を消す（1 字消しも長押しもない）。DEL は文字があると末尾の 1 字を消す（実機は効かない）。+/- は常に "-"。メッセージ表示中でも打鍵を受け付け、見えないまま scratchpad に溜まる。押下（phase 0）しか見ない | FCOM p.1212-1213; FMSPG p.39, p.42-43 | B744.createfms.lua:142-171, 195-269, 237 |
| CDU-02 | 挙動の誤り | 高 | L | 3 台が X-Plane 標準 CDU 1 つ（cdu1 の文字列と `sim/FMS/` コマンド）を共有する。標準ページ（RTE、LEGS、DEP ARR、HOLD、FIX）は、ある CDU のキーで他の CDU のページも変わる。標準の scratchpad のメッセージは独自ページを出している全 CDU の notify に写る。CRZ ALT が変わるたび、左 CDU のキーで標準 FMS を操作して表示中の標準ページに割り込む | FMSPG p.39, p.49 | B744.createfms.lua:313-410, 549-552; B747.68.xt.fms.lua:805-830; B744.fms.pages.lua:630-654 |
| CDU-03 | 欠落 | 高 | L | 独自ページに MOD/ACT/EXEC/ERASE の仕組みがない。VNAV の速度・SPD TRANS/RESTR・STEP TO、OFFSET、THRUST LIM などは即時に効く。題名は MOD にならず、ERASE も出ない。EXEC 灯は標準 FMS の変更でしか点かない | FCOM p.1238, p.1327, p.1347, p.1391; FMSPG p.42, p.118, p.156 | B744.fms.pages.lua:1000-1084, 1124-1145; Cockpit_Pedestal1.obj:40911-40913 |
| CDU-04 | 挙動の誤り | 中 | S | RTE と LEGS の題名が "ACT RTE 1"/"ACT RTE 1 LEGS" 固定で、非アクティブや MOD が見えない。RTE の 6 行目を上書きするため、ACTIVATE> と ERASE が出ない。地上の 6L は KEY/FUNCTION INOP、6R は未アクティブでも PERF INIT。<RTE 2 は標準の DIR INTC を開き、RTE 2 自体がない | FCOM p.1287-1295, p.1331; FMSPG p.92-93 | B744.fms.pages.lua:100-129, 138, 162, 554-557; activepages/B744.fms.pages.legs.lua:5 |
| CDU-05 | 挙動の誤り | 中 | M | 標準ページは全行を大字の dataref に入れ、小字の見出しや予測値も大字で出す。括弧は空白に置き換える。style 行（`fms_cdu1_style_line*`）を読んでいるが使っていない | FCOM p.1213-1214; FMSPG p.48 | B744.createfms.lua:521-532; B747.68.xt.fms.lua:85-91, 1108 |
| CDU-06 | 挙動の誤り | 中 | S | 機能キーのページ選択が文脈で変わらない。INIT REF は常に INIT/REF INDEX（実機は POS INIT/PERF INIT/APPROACH REF）。VNAV は常に CLB 1/3（実機はアクティブなフェーズ）。DEP ARR と HOLD は標準任せ | FCOM p.1285, p.1299-1301, p.1308, p.1343, p.1401, p.1409, p.1413; FMSPG p.94, p.111, p.130, p.186, p.203 | B744.createfms.lua:44-48, 57-62, 68-73, 94-99 |
| CDU-07 | 挙動の誤り | 中 | M | 入力受付の共通処理が不正確。(1) 多くの項目が文字列を検査なしで保存する（COST INDEX、PRESELECT、THRUST LIM の SEL と TO EPR、CO DATA など）。(2) 欄より長い値は黙って 3 字に切られる。(3) 空の scratchpad で LSK を押すと、ボックスやダッシュの伏せ字（"****"）まで scratchpad に写す。(4) DELETE はほぼ全項目で通り、INVALID DELETE を出さない。(5) PERF INIT の FUEL と APPROACH REF の GROSS WT の入力は保存されるだけで使われない | FCOM p.1210, p.1269-1270, p.1435; FMSPG p.43, p.49 | B744.fms.pages.lua:2500-2507; B747.68.xt.fms.lua:705-708; identpage.lua:52; perfinit.lua:133; approach.lua:53; thrustlim.lua:165, 170 |
| CDU-08 | 挙動の誤り | 中 | S | 高度と速度の検査が誤り。validAlt は 2,000 ft 未満と、重量から求めた MAX を超える値を拒否する（実機は MAX 超えを受け付けて MAX ALT FLXXX、INVALID は認定高度超えだけ。低高度・負の高度・FL/ft の表示規則もある）。validateSpeed は CAS 130-300 だけ（実機は CAS 100-400、Mach、CAS/Mach の対）。CRZ の速度は Mach だけ。SPD TRANS は入力できる（実機は削除のみ）。"INVALID CRZ ALT" は実機にない文言 | FCOM p.1269-1270, p.1328, p.1348, p.1392; FMSPG p.97, p.113, p.131-132 | B744.fms.pages.lua:667-706, 1000-1084, 1203 |
| CDU-09 | バグ | 中 | S | CRZ CG に数字でない文字列を入れると、そのまま保存される。以後、PERF INIT を描くたびに string.format に nil が渡ってエラーになり、そのフレームの after_physics が止まる（他の CDU の描画、IRS・ND・ACARS の更新も止まる：推定）。範囲 8.5-33.0 の検査もない | FCOM p.1311 | B744.fms.pages.lua:1450-1456; perfinit.lua:38-43; B747.68.xt.fms.lua:1233-1285 |
| CDU-10 | バグ | 高 | S | 空中の THRUST LIM で <GA・<CON・<CRZ を押すと、TO/TO1/TO2 の処理が動く。CLB/CLB 1/CLB 2 を選び、TO derate を 0/1/2 にする。EEC は TO derate を TOGA 推力に掛けるので、GA 推力が 10/20 % 下がる。GA/CON/CRZ は選べない。推力値の表示がなく、<SEL> は EICAS の推力モードを映さない | FCOM p.1337-1340; FMSPG p.100, p.103-104 | thrustlim.lua:50-69, 166-168; B744.fms.pages.lua:2543-2548; B747.42.xt.EEC.lua:624-628, 690-705 |
| CDU-11 | 欠落 | 中 | S | 地上の THRUST LIM：SEL の範囲検査（0-99 °C、32-210 °F）、"D-" 表示、25 % 上限、derate 選択による SEL の消去、定格・SEL 変更時の TAKEOFF SPEEDS DELETED、derate の % による CLB の自動 ARM がない | FCOM p.1314-1316; FMSPG p.101-103 | thrustlim.lua:9-49, 165-173 |
| CDU-12 | 挙動の誤り | 高 | M | TAKEOFF REF：フラップを入れると V speeds を即座に PFD に出す（REF 付き小字の計算値 → LSK で選択 → 大字、の流れがない。選択前の NO V SPD もない）。ACCEL HT、E/O ACCEL HT、THR REDUCTION は固定文字で入力できない。WIND/SLOPE がない。滑走路と POS SHIFT が固定。PRE-FLT が固定で、未完ページへの誘導と THRUST LIM> がない。V1MIN がない。入力範囲が 100-200 kt | FCOM p.1316-1321; FMSPG p.104-109 | takeoff.lua:23-135; B747.60.xt.fltInst02.lua:2783-2812; B744.fms.pages.lua:2568-2596 |
| CDU-13 | 挙動の誤り | 中 | M | PERF INIT：FUEL は CALC 固定（SENSED/MANUAL なし）。GR WT と ZFW は字数でしか検査しない。RESERVES・COST INDEX の範囲検査と、T/D 10 NM 以内の CI 入力禁止がない。"GR WT ADV" と `<` 付き値は 405 の WBS 仕様（109/570 はボックス） | FCOM p.1307-1312; FMSPG p.94-98 | perfinit.lua:15-141; B744.fms.pages.lua:1367-1449 |
| CDU-14 | 欠落 | 中 | L | VNAV ページ：(1) 題名に速度モードと MOD が出ない。(2) <ECON、ENG OUT>、CLB DIR>、DES DIR>/DES NOW>、FORECAST>、<OFFPATH DES がない（押しても効かない）。<RTA PROGRESS は標準の PROG を開く。(3) AT 制限を削除できない。(4) CRZ の表示が "N1 %" 固定（PW/RR は EPR）。STEP SIZE は固定の "ICAO" で、入力もできない。STEP TO を入れても毎フレーム上書きされる。(5) E/D がないときに空白の DES にならない。(6) LRC は実機と違う配置。(7) E/O CLB/CRZ、RTA CRZ のページがない。表示値はページ内の簡易計算で、FMC のノートの範囲 | FCOM p.1327-1329, p.1341-1354, p.1390-1394; FMSPG p.111-118, p.130-133, p.186-190 | vnav.lua:47-449; vnav.lrc.lua:5-129 |
| CDU-15 | 欠落 | 中 | M | PROGRESS：題名に便名がない。DEST 行への入力（代替地、途中の waypoint）がない。LAST の ALT が空白。速度行の見出しとモードが固定。TO の行は T/D・T/C だけ。2/3 の XTK は常に "L"、VTK は固定、<USE が効かない、TOTALIZER と CALCULATED が同じ値。3/3（RTA）は固定文字 | FCOM p.1371-1385; FMSPG p.146-151, p.181-184 | progress.lua:46-301 |
| CDU-16 | 挙動の誤り | 中 | S | NAV RADIO：VOR の識別子入力と、周波数/コースの同時入力ができない（識別子を入れると autotune に戻る）。状態表示は A/M だけ。ADF の A/B 接尾（ANT/BFO）がない。ILS の PARK/A は T/D までの距離だけで決まり、中間点・150 NM・降下中の条件がない。ILS TUNE INHIBITED がない | FCOM p.1303-1307; FMSPG p.205-211 | B744.fms.pages.lua:355-513, 2549-2567 |
| CDU-17 | 挙動の誤り | 中 | M | 標準 FMS へ送る入力（`custom2fmc`・`key2fmc`）は、scratchpad を 1 字ずつ打ち込む方式。DELETE は "D-E-L-E-T-E" の文字として送られ、標準の DELETE にならない（推定。標準側の解釈は未確認）。空白を含む scratchpad を送ると Lua エラーになる（キー表に " " がない） | FCOM p.1213 | B744.fms.pages.lua:578-614; B744.createfms.lua:363-410 |
| CDU-18 | 欠落 | 中 | L | 独自にも標準にもないページ：RTE 2、REF NAV DATA（NAVAID/VOR ONLY/VOR-DME NAV の INHIBIT）、DESCENT FORECAST、OFFPATH DES、E/O CLB/CRZ、RTA CRZ、RTA PROGRESS（固定文字のみ）、RTE DATA/WIND（標準にあるかは未確認）。refonly の雛形 17 本は読み込まれていない | FCOM p.1287, p.1354-1366, p.1383-1385, p.1395-1399; FMSPG p.120-124, p.170-174, p.178-193 | B744.fms.pages.lua:279-309, 351; refonly/*.lua |
| CDU-19 | 欠落 | 中 | L | FMC/CDU の故障の挙動がない：FMC L/R の故障、FMC LEFT/RIGHT advisory（表にあるが立てない）、SINGLE FMC・RESYNC 系のメッセージ、FAIL 灯、MENU 表示＋TIME OUT - RESELECT、両 FMC 故障時の代替航法（IRS LEGS、IRS PROGRESS、ALTN NAV RADIO）。FMC master selector は X-Plane の autopilot source を切り替えるだけ | FCOM p.1215, p.1421-1429, p.1433-1435; FMSPG p.40, p.247-254 | B747.60.xt.fltInst02.lua:660-663; B747.87.xt.warning.lua:330-332 |
| CDU-20 | 欠落 | 中 | M | 電源と輝度。CDU の表示に電源がなくてもキーを処理し、状態も保持する。電源投入時に MENU へ戻らない。電源喪失で PERF INIT が消えない。飛行完了（エンジン停止 30 秒後）の消去がない。BRT ノブは、fms1 は dataref があるが未使用、fms2/fms3 は dataref 自体がない（3D のノブが効かない）。中央 CDU は表示が F/O 側電源（[6]）、輝度が機長側（rheostat 12） | FCOM p.800, p.804, p.1210, p.1236, p.1307; FMSPG p.53 | B747.68.xt.fms.lua:1233-1239; init/scripts/B747.68.fms/B747.68.fms.lua:74; B747.90.xt.lighting.lua:903-913; 747-400.acf:139301-140101 |
| CDU-21 | 挙動の誤り | 中 | S | メッセージの扱い：alert は 10 秒ごとに調べ、最上位の 1 件だけを出す（列にしない）。CLR で通知の元のフラグを 0 にするため、条件が続いていても消える。advisory も notify の 1 枠に入る。標準 FMS のメッセージは全 CDU に写る。NAV DATA OUT OF DATE を自動で消す。alert の大半は立てる処理がない。RW/ILS CRS ERROR を「ILS 未同調」の意味で使っている。DESTINATION NOT SET・NO LOGON・NA - WAITING FOR FUEL TRUCK は実機にない | FCOM p.1430-1436; FMSPG p.39, p.255-260 | B747.68.xt.fms.lua:1110-1136; B744.createfms.lua:20-33, 520, 549-552; B744.notifications.lua:3-77; B747.70.xt.autopilot.lua:2379, 2398, 2431 |
| CDU-22 | 欠落 | 低 | S | MSG・DSPY・OFST・FAIL 灯がない（dataref も 3D の参照もない） | FCOM p.1210; FMSPG p.40-41 | なし |
| CDU-23 | 挙動の誤り | 低 | S | ページを変えると 0.5 秒間、3 台の画面全体（scratchpad を含む）が空白になる。NEXT が最終ページで 1 ページ目に戻らない。ページ番号の出し方が不統一 | FMSPG p.42-43; FCOM p.1214 | B744.createfms.lua:36, 172-179, 506-512; B744.fms.pages.lua:569 |
| CDU-24 | 挙動の誤り | 低 | S | MENU：<ACT> が固定、<SAT が無効、EFIS/EICAS CP の SELECT> が常に出る、CTL PNL OFF/ON がない、<FMC が最後のページでなく IDENT を開く（項目の配置は FCOM の図と一致） | FCOM p.1061-1062, p.1322-1324; FMSPG p.53, p.238, p.244 | B744.fms.pages.lua:29-93 |
| CDU-25 | 挙動の誤り | 低 | S | EFIS CONTROL/OPTIONS：BARO（STD も）と RANGE が両席に効く。RANGE が循環しない。BARO・DH・MDA の範囲と単位の検査がない。-152 と -161 の項目が混在。<POS と DATA> が効かない。CDU で操作中の >EFIS CONTROL advisory（-161）がない | FCOM p.1060-1068, p.1198; FMSPG p.238-246 | B744.fms.pages.lua:905-992; efisctl.lua:43-164 |
| CDU-26 | 挙動の誤り | 低 | S | IDENT：CO DATA が入力できる。NAV DATA の識別子、非アクティブ DB とその切替、OPC がない | FCOM p.1282-1284; FMSPG p.62-65 | identpage.lua:4-53 |
| CDU-27 | 挙動の誤り | 低 | S | POS REF 2/3・3/3：RNP/ACTUAL が固定値で RNP を入力できない（VERIFY RNP ENTRY もない）、<PURGE・GPS NAV INHIBIT>・BRG/DIST> が効かない（IRS の中身は航法のノート） | FCOM p.1367-1370, p.1436; FMSPG p.74-76 | posinit.lua:43-104 |
| CDU-28 | バグ | 中 | S | APPROACH REF：空の scratchpad で 4R を押すと、写すのではなく FLAP/SPEED と PFD の VREF を消す。入力は "XX/YYY" だけ（実機は /YYY と YYY も可）。25 以外のフラップは 30 扱い。GROSS WT の入力は無視される。滑走路と長さの行が固定の伏せ字 | FCOM p.1409-1412; FMSPG p.203-205 | B744.fms.pages.lua:1348-1366; approach.lua:6-56 |
| CDU-29 | 挙動の誤り | 低 | S | RTE の FLT NO は標準 FMS へ送るだけで、FMC の便名（ACARS・ATC のログオンが使う `fltno`）にならない。fltno は ACARS INITIALIZE と ATC LOGON/STATUS でしか入らない。PROGRESS の題名にも出ない | FCOM p.1289-1290, p.1371 | B744.fms.pages.lua:153-158, 226-240; acars/acars.pages.lua:159; activepages/atc/B744.fms.pages.atclogonstatus.lua:61 |
| CDU-30 | 欠落 | 低 | S | 自動のページ変更がない（570 の TAKEOFF REF → CLB）。DSPY 灯の判定もない | FCOM p.1210, p.1325 | なし |
| CDU-31 | 欠落 | 低 | M | 保守ページは固定文字。MAINTENANCE INDEX の <INDEX が ACMS を開く。PERF FACTORS（THR RED、ACCEL HT、derate %）が TAKEOFF REF・THRUST LIM の既定値と連動しない | FCOM p.1239; FMSPG p.263-269 | maint.lua:25; maintperffactor.lua |
| CDU-32 | 挙動の誤り | 低 | S | 109（旅客）では ATC と FMC COMM のキーは KEY/FUNCTION INOP のはずだが、常にデータリンクのページを開く。sim の機能として simconfig で切り替えられるようにする | FCOM p.725, p.1211 | B744.createfms.lua:63-67, 100-104 |
| CDU-33 | バグ | 高 | S | EMERGENCY REPORT の 2L（DIVERT TO）が `setdata fltdst` になっている。RTE の目的地を書き換えて標準 FMS に送る。DELETE なら出発地・目的地・飛行計画を消す（データリンクの調査より。コードで確認） | FCOM p.729; FMSPG p.348 | activepages/atc/B744.fms.pages.emergency.lua:72; B744.fms.pages.lua:1326-1341 |
| CDU-34 | バグ | 中 | S | ATC の送信文は共有の 1 本の `acarsMessage` に入る。POS REPORT・EMERGENCY・VERIFY の各ページは描画のたびにここへ書き込み、3 台は毎フレーム描かれる。そのため、他の CDU が出しているページの文が送られる | FCOM p.744-745 | activepages/atc/B744.fms.pages.posreport.lua:20; emergency.lua:52; request.lua:320; whencanwe.lua:118 |
| CDU-35 | 欠落 | 中 | L | ATC アップリンクの処理（XXXXz ATC UPLINK、VERIFY RESPONSE、REJECT DUE TO、応答の属性、電文の状態、ARM）と、クリアランスの LOAD（現用ルートの MOD、UNABLE TO LOAD/PARTIAL CLEARANCE LOADED）がない | FCOM p.753-765, p.1433-1434; FMSPG p.288-297 | acars/acars.pages.lua:229-342; acars/autoatcProvider.lua:188-268 |
| CDU-36 | 挙動の誤り | 中 | M | ATC キーが常に ATC INDEX を開く（状態による振り分けも長押しの EMERGENCY もない）。LOGON/STATUS の手順が実機と違う（SEND/SENT/REJECTED/RESEND がない、即送信、SELECT OFF が効かない、ATC COMM ESTABLISHED/TERMINATED を出さない）。ACARS の WEATHER/INITIALIZE が ATC のログオン先を変える | FCOM p.728, p.752-758, p.1431, p.1433; FMSPG p.44, p.277-285 | B744.createfms.lua:63-67; activepages/atc/B744.fms.pages.atclogonstatus.lua:3-36; acars/acars.lua:38-59; acars/acars.pages.weatherrequest.lua:49-55 |
| CDU-37 | 挙動の誤り | 中 | S | データリンクの EICAS 表示：ATC アップリンクに ACARS MESSAGE メモを使う。ATC MESSAGE（メモ＋チャイム）がない。FCOM にない ACARS NO COMM メモを出し続ける。>DATALINK AVAIL/LOST/SYS を立てる処理がない | FCOM p.725, p.775-776; FMSPG p.255 | B747.68.xt.fms.lua:1240-1265; B747.87.xt.warning.lua:241-243, 492-546 |
| CDU-38 | 欠落 | 中 | M | Hoppie の受信が未実装（解析が空で、読む dataref も誤り）。Hoppie を選んでも AutoATC が必須 | sim 独自 | acars/autoatcHoppieProvider.lua:17-41, 70-75 |
| CDU-39 | 欠落 | 低 | L | ATC LOG（区別・状態・削除・容量）、REQUEST の要素と制限、ATC REPORT（報告リスト・ARM）、POS REPORT（送信・上書き）、EMERGENCY（CANCEL・FUEL REMAINING）、CLEARANCE/VOICE の細部が実機と違うか、ない | FCOM p.728-754, p.766-770; FMSPG p.298-363 | acars/acars.lua:414-545; activepages/atc/*.lua |
| CDU-40 | 欠落 | 低 | L | カンパニーデータリンクの FMC 側：FMC COMM の UPLINK 表示と 2/2 の SEND、RTE の REQUEST/LOAD/PURGE、風・降下予報・PERF/THRUST LIM/TAKEOFF のアップリンク。受け取った経路は .fms ファイルに書くだけ | FCOM p.771-774, p.1289-1291, p.1310-1320; FMSPG p.367-383 | activepages/B744.fms.pages.fmccomm.lua:2-83; acars/autoatcProvider.lua:178-187 |
| CDU-41 | 欠落 | 低 | L | ADS（ARM/ACT/OFF、緊急モード、契約による自動報告）がない。LOGON/STATUS の ADS 欄は固定表示 | FCOM p.725, p.756-757; FMSPG p.270-276 | activepages/atc/B744.fms.pages.atclogonstatus.lua:24-36 |
| CDU-42 | バグ | 低 | S | データリンクの細かな不具合：sendCompany が未定義の fmsO を参照する。POSTFLIGHT の LSK 名が小文字 "l1"。FMC COMM 2/2 の 1L が RTE 1 を開く。AutoATC 接続中は ACP の R/T・INT で MIC 選択を書き換える。MENU の <ACARS は接続中かつ中央 RTP が ON のときだけ出る | FCOM p.683-684, p.715, p.718 | acars/autoatcProvider.lua:126, 339-359; acars/acars.pages.lua:88; fmccomm.lua:83; B744.fms.pages.lua:38-43 |

- 集計：**高 6（01, 02, 03, 10, 12, 33）、中 22、低 14**。計 42 件。うちデータリンク関係は 32-42 の 11 件（データリンク調査の 22 項目を統合した）。
- ACF_DIFF：CDU のパネル定義（fms1-3 の 3 群）は純正とカスタムで同一（md5 で確認）。差分による GAP はない。コードが依存しているパネル側の値：
  - 表示条件 `display_has_power[6-8]` と `avionics_on`。
  - BUS_SRC 2/4。
  - rheostat 12/13。
  - 2.2 の交差した dataref の割り当て。

## 8. 作り直しか部分修正か

- **CDU の枠組み（キー処理、scratchpad、メッセージ、ページ登録、入力検査、MOD/EXEC、描画）は作り直しを勧める。** 規模は L。
  1. 根本の構造（3 台が標準 CDU 1 つを共有し、標準ページを写して上書きする）では、CDU の独立（CDU-02）、字体（CDU-05）、MOD 題名（CDU-04）を部分修正で直せない。
  2. 項目の定義（型・範囲・既定値・削除の可否・複写の可否・字体）を一元管理する仕組みがない。そのため検査（CDU-07, 08）、DELETE、伏せ字の複写が項目ごとの `elseif` に散らばり、`setData` の切り詰めのような共通のバグが全項目に効く。
  3. ページの描画関数が計算と副作用を持っている（PERF INIT が grwt を書く、VNAV が stepalt を上書き、POS REPORT が送信文を書く）。描画のエラーが全体を止める（CDU-09）。部分修正では再発を防ぎにくい。
  4. 既存のページの大半は 13 行の文字列テンプレートで、ロジックは薄い。項目定義型の枠組みに載せ替える方が、個別に直すより速い。
- **残すもの**：
  - INTERFACES の名前と意味（キーのコマンド、`LineNN_L/S`、BRT、2.2 の交差した対応）。
  - `laminar/B747/fms/data` の JSON のキー（読む側があるもの）。
  - 通知の配列（または新しい API に置き換えて、書く側と一緒に移す）。
  - ND の補助 dataref。
  - sim 独自のページ（地上作業、AIRCRAFT CONFIG、SOUND）は、文字列を新しい枠組みにそのまま移せる。
- **進め方の案**：
  1. 枠組み：CDU ごとの状態、キーの状態機械（4.1）、項目定義と検査器（4.2）、メッセージの列、描画（大字・小字・ページ番号）、`pcall` による保護。
  2. preflight のページ：IDENT、POS INIT/REF、PERF INIT、THRUST LIM、TAKEOFF REF、APPROACH REF、NAV RADIO、MENU、EFIS/EICAS CP。
  3. 標準 FMS の扱い（6 章の案 (a)/(b)）を FMC の担当と決め、RTE/LEGS/DEP ARR/HOLD/FIX/REF NAV DATA を Lua で描く。
  4. MOD/EXEC：VNAV ページは FMC のモデル（速度モード、E/O、RTA）とセットで作る。
  5. PROGRESS、代替航法、故障時の挙動、最後にデータリンク（simconfig で入切）。
- **当面の小修正**：本格的な作り直しの前でも、CDU-10（THRUST LIM 空中の誤配線）、CDU-33（DIVERT TO が目的地を書き換える）、CDU-09（CRZ CG の描画エラー）、CDU-28（APPROACH REF の 4R）は局所的に直せて、害が大きい。

## 9. 未確認事項

- **X-Plane 12.4 の標準 FMS**：
  - route の ACTIVATE/EXEC が必要か。混成 RTE ページで ACTIVATE が出ない状態で、route がアクティブになるか。
  - "DELETE" を文字で打ち込んだときの解釈。
  - style 行の中身。
  - CDU 2（`fms_cdu2`）が使えるか。パネルの COPILOT 付き CDU739 は、そのために置いてあるのか。
- **中央 CDU**：FMC のページをどこまで使うか（FCOM と FMSPG の食い違い）。電源の系統（資料に記載なし）。
- **3D の表示灯**：MSG・DSPY・FAIL・OFST 灯がテクスチャ上にあるか。点灯させる手段があるか。
- **3D の manipulator**：左と中央の CDU の NAV RAD キーの位置がずれていないか（sim で目視）。3D が参照する `laminar/B747/fms1/display_mode` と `fms1/radio/*` のコマンドは存在しない（旧版の名残と推定。ノブは隠れている）。
- **XTLua のエラー**：after_physics でエラーが出たとき、次のフレームも呼ばれるか、その後の処理（他の CDU、IRS、ND）がどうなるか（CDU-09 の影響範囲）。
- **基準の型式**：109 を基準にする方針の確認。GE を選んだときに 570（N1、PROGRESS 2 ページ、DES の FPA など）の表示を当てるか。データリンクを 109 でも有効にするか。
- **INIT REF キーの分岐**：PERF INIT 完了後の行き先（TAKEOFF REF か）は資料に記載なし。
- **割り当てのない LSK を押したときの実機の反応**：資料に記載なし。
- **ページ切替の遅れ**：実機で表示が一瞬消えるか。資料に記載なし（STANDBY ONE は 4 秒超）。
- **データリンクのプロバイダ**：AutoATC/Hoppie の電文仕様から、応答の属性やロードできる要素をどこまで取れるか（CDU-35 の規模に効く）。
