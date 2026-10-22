# ATA 34-61 FMC（航法・性能・誘導）調査メモ

2026-10-23 調査。対象コードは `overhaul`（041c9ffa）。出典の書き方は REFERENCE_INDEX.md に従う。

## 1. 概要

- 対象：FMC の航法（FMC 位置、IRS/GPS/無線の混合、ANP/RNP、無線の自動同調、航法 DB）、経路（RTE 1/2、ACT/MOD と EXEC、discontinuity、オフセット、direct-to・intercept、ホールド、手続きのレグ）、LNAV（経路の組立て、旋回、シーケンス、捕捉）、VNAV（上昇・巡航・降下、速度・高度制限、T/C・T/D・E/D、パス降下と速度降下、早期降下、ステップ、進入パス、ミスト進入）、性能（CI と ECON、予測、OPT/MAX、燃料監視、風）、それらの FMC メッセージ、FMC 二重系と CDU の代替航法。
- 対象外：CDU ページの体裁・入力書式（別担当）、A/T・推力制限・エンジントリム（別担当）、離陸速度・VREF・トリムの表、IRS 本体（アライン・IRU 故障）、ATC/AOC データリンク。取り合いは §5。
- 資料
  - FCOM 11.30–11.32 p.1233–1275、11.40–11.43 の機能部分 p.1277–1419、11.50 p.1421–1428、11.60 p.1429–1436。補助：4.10 p.643–649・4.20 p.663–667（MCP と LNAV/VNAV の作動）、10.40 p.1149（ND の VNAV パス）、PI.18 p.316–318・p.323（FMC と同じ前提の性能表の説明）。
  - ATA34_2 p.427–707（E&M 34-61）。図は p.603、p.607、p.617、p.619、p.621 を描画して見た。
  - LH3460 p.3–116。大半は ATA34_2 と同文。時刻源、UNABLE RNP の段階、FMC の割り当て（p.90–93）だけ追加で使った。
  - FMSPG 2 章 p.15–55、4 章 p.212–237、7.1 p.261–262、補助に p.164・p.266。FMSPG は 1996 年版で、FCOM（2009 年改訂）と値が違う箇所は FCOM を採った（§9）。
- effectivity：FCOM の 109＝PW 旅客機、405＝PW 改造貨物機、570＝GE 貨物機（FCOM p.5 (0.1.1)）。シムは旅客機なので 109 を採る（推定。ATA-36.md と同じ扱い）。RR の性能資料は無い。
- コードの略号（以下 `略号:行`）
  - FMS＝`plugins/xtlua_keysystems/scripts/B747.68.xt.fms/B747.68.xt.fms.lua`、CRE・PG・NOTI＝同フォルダの `B744.createfms.lua`・`B744.fms.pages.lua`・`B744.notifications.lua`
  - VPG・PRG・PINIT・LEGS＝同 `activepages/B744.fms.pages.{vnav,progress,perfinit,legs}.lua`、IRS・RNAV＝同 `irs/{irs_system,rnav_system}.lua`
  - AP＝`plugins/xtlua_keysystems/scripts/B747.70.xt.autopilot/B747.70.xt.autopilot.lua`、MON・VN・VS＝同 `B747.70.xt.autopilot.{monitor,vnav,vnavspd}.lua`
- OLD_FORK_NOTES.md §4–6・§8 は参照だけ（移植しない）。

## 2. 構成

### 2.1 機器・電源・データベース

| 項目 | 内容 | 根拠 |
|---|---|---|
| FMC ×2 | SDP-185×2、不揮発メモリ（OP program、nav DB、perf DB、APF）、A/T サーボカード。左右とも全計算を行い intersystem bus で突き合わせる | ATA34_2 p.434, p.456, p.484; LH3460 p.8 |
| CDU ×3 | L・C は通常 L FMC、R は R FMC につながる。C は FMC へ入力できない。FMC 両系故障で代替航法・代替同調 | ATA34_2 p.433, p.456 |
| button push master | 通常 L FMC。両 CDU のキーを L FMC が順番づけて R へ渡す。経路変更は同時に 1 件 | FCOM p.1233; FMSPG p.24, p.49 |
| FMC master switch（P2）・master relay ×3 | L で消磁＝L FMC が FCC 誘導、航法無線同調、EEC トリム、MCP、A/T を受け持つ。switch と relay が不一致なら A/T を ARM できない | ATA34_2 p.452, p.496 |
| 電源 | L FMC：APU standby bus（115V AC）、R FMC：F/O transfer bus、警報回路：battery bus、master relay：28V DC bus 1、CDU：standby・captain transfer・F/O transfer bus（どの CDU がどれかは資料に記載なし） | ATA34_2 p.450, p.452, p.454 |
| nav DB | 2 組（各 28 日）。地上でのみ切替、切替で経路データを消す。飛行中に失効しても着陸まで使う。未有効側は該当日 0901Z から有効 | FCOM p.1271, p.1284 |
| perf DB・係数 | 抗力・エンジン模型、最大・最適高度、最大・最小速度。保守ページで drag/FF 係数、MNVR MARGIN 1.20–1.30（包囲線とバンク限界）、MIN CRZ TIME（OPT 計算）、最大高度の残余上昇率（CLB/CRZ 推力、0–500 fpm、既定 100） | FCOM p.1271; ATA34_2 p.678–679; FMSPG p.266 |
| 機能ブロック | FMC：入出力、航法と同調、性能、誘導、推力管理、EFIS、DB、BITE。CDU：EFIS 地図、代替航法、代替同調、ARINC 739 | ATA34_2 p.596–598 |

### 2.2 入力と源の選び方

| 入力 | 使い方・選び方 | 根拠 |
|---|---|---|
| IRU ×3 | 位置・速度は 3 台を混合（§4.2）。姿勢・方位・トラックは作動中の AP/FD チャンネルで L・C・R を選ぶ | ATA34_2 p.459 |
| ADC | 作動中の AP チャンネル（無ければ L ADC 選択信号）で選ぶ | ATA34_2 p.459 |
| GPS L/R | 位置、HFOM・HIL・SAT FAIL（ANP と RNP の比較に使う）、時刻 | LH3460 p.32 |
| 航法無線 | L FMC：L・R VOR、L DME、L ILS。R FMC：R・L VOR、R DME、R ILS。DME は自側無効なら他側 | ATA34_2 p.458 |
| 時計 | GPS L → GPS R → 機長時計 → F/O 時計（ATA34_2 p.458 は機長 → F/O の旧仕様） | LH3460 p.30 |
| FQIS・EIU | 総燃料（L FMC は出力 A、R は B）、FF、ジェティソン、Vmin/Vmax、フラップ・脚位置、エンジンデータ、電波高度。低速データは L → C → R | ATA34_2 p.458, p.462 |
| MCP・FCC | 選択高度・方位・速度、ボタン、介入、TO/GA、A/T ARM。FCC からの ILS 同調禁止 | ATA34_2 p.470 |
| その他 | EFIS CP（CDU 経由）、HDG REF、air/ground（DB 書込み許可と飛行段階）、WBS（405 のみ） | ATA34_2 p.462, p.477–478 |

## 3. 操作と表示

### 3.1 操作（FMC に関わる部分）

| 操作 | 働き | 根拠 |
|---|---|---|
| LNAV スイッチ | arm/選択/解除。滑走路標高 +50 ft 以上で、アクティブレグから 2.5 NM 以内、またはそれ以遠でも切込みヘディングならレグ接近で作動。切込まないなら NOT ON INTERCEPT HEADING。HDG HOLD・HDG SEL・LOC 捕捉・FMC 両系故障で解除 | FCOM p.644–645, p.663 |
| VNAV スイッチ | arm/選択/解除。滑走路標高 +400 ft で作動。データ不足（GW 無効、降下で E/D 無し等）なら PERF/VNAV UNAVAILABLE。TO/GA・FLCH・V/S・ALT・G/S・FMC 両系故障で解除 | FCOM p.645, p.664–665 |
| IAS/MACH セレクター押し | VNAV 中に窓を開閉。開＝速度介入。VNAV PTH 降下中に開くと VNAV SPD（制限高度に掛かると VNAV PTH）。on approach 中は VNAV PTH のまま A/T が速度 | FCOM p.643; ATA34_2 p.623 |
| 高度セレクター押し | ①上昇・降下中、機体と MCP 高度の間の次の高度制限を 1 個削除 ②上昇中で制限が無く MCP > CRZ ALT なら CRZ ALT＝MCP ③巡航中は CRZ ALT＝MCP、VNAV PTH/ALT なら上昇・降下開始 ④T/D 50 NM 以内で MCP < CRZ ALT なら減率降下 | FCOM p.649; ATA34_2 p.623–624 |
| BANK LIMIT | HDG SEL のときだけ（AUTO は TAS・フラップ・V2 で 15–25°）。LNAV には効かない | FCOM p.647 |
| TO/GA | 地上：takeoff 段階開始。GPS 更新が無いとき FMC 位置を滑走路端（POS SHIFT 入力時はその点）へ。空中：ミスト進入 | FCOM p.1240, p.1262, p.1321, p.1325 |
| FMC master selector（P2） | master FMC を選ぶ（§2.1） | ATA34_2 p.496 |
| NAV source selector | FMC L / FMC R / CDU L(R) / CDU C。ND・PFD の源と CDU の接続先。CDU は ND の地図だけ | ATA34_2 p.456, p.496; LH3460 p.90 |
| HDG REF（NORM/TRUE） | 地図と誘導の基準方位。高緯度では自動で真方位 | FCOM p.1242; ATA34_2 p.477 |
| EXEC キー | ACTIVATE や MOD（経路・性能モードの変更）で点灯、押すと有効化 | FCOM p.1238; FMSPG p.42 |

### 3.2 表示（FMC が出すもの）

| 表示 | 内容 | 根拠 |
|---|---|---|
| PFD 速度テープ | 最小機動速度（amber、FMC が制御に使う下限）、高速バフェット（amber、上限）、V1・VR・VREF・フラップ機動速度、VNAV 中の目標速度（magenta、離陸時は V2）。A/T FMA は master FMC、ドリフト角は選択 FMC、着陸高度は master FMC（無効なら CPCS） | ATA34_2 p.501–502 |
| ND 経路 | active：マゼンタ実線、非 active：シアン破線、activate 済み未 EXEC：シアン/白の交互破線、変更：白破線、変更点：白、実行済みオフセット：マゼンタ破線 | FCOM p.1251 |
| ND 点と数値 | アクティブ点（マゼンタ、通過で白）、ETA・距離、T/C・T/D・S/C・E/D（緑の円）、高度到達弧、トレンドベクター（30/60/90 s）、風（TAS > 100 kt かつ風 > 5 kt）、更新モード（LOC GPS、LOC DD、LOC VD、LOC、GPS、DD、VD、IRS(3/L/C/R)。IRS(3) との切替で 10 s 緑枠） | ATA34_2 p.504–506; LH3460 p.72 |
| ND VNAV パス | 降下中だけ。目盛 ±400 ft、超えると数値（ATA34_2 は ±420 ft・50 ft 刻み・最大 9,999 ft。FCOM を採る） | FCOM p.1149; ATA34_2 p.505 |
| ND ホールド | 小記号（レンジ > 80 NM か保持点が TO 点でない）、大記号（保持点が TO 点かつ ≤ 80 NM。風・速度で大きさが変わる） | FMSPG p.223 |
| CDU 灯 | MSG、DSPY（表示ページがアクティブなレグ/モードでない）、FAIL（空中で master FMC 故障か NAV 選択の FMC 故障）、OFST（オフセット中）。CDU は GS > 100 kt か GS 無効で空中とみなす | LH3460 p.56; FMSPG p.40–41 |

### 3.3 EICAS メッセージ

| メッセージ | レベル | 条件 | 根拠 | 現状 |
|---|---|---|---|---|
| FMC LEFT, RIGHT | advisory | その FMC の故障（内部故障、センサー無効、ARINC バス）。30 s 後 | FCOM p.1429; LH3460 p.116; ATA34_2 p.702 | adv[144]/[146] は定義だけ |
| >FMC MESSAGE | advisory | CDU に FMC の alert メッセージがある（alert だけ） | FCOM p.1430; ATA34_2 p.635 | adv[145]。どのメッセージでも点く（FMS:1110-1136） |
| UNABLE RNP | advisory（beeper） | approach 以外で ANP > RNP。極域で抑止 | FCOM p.1430; LH3460 p.116 | adv[295] 未使用 |
| UNABLE RNP | caution（beeper） | approach 段階で ANP > RNP。極域で抑止 | FCOM p.1430; LH3460 p.116 | caution[66] を XTK から出す（AP:2220-2232） |
| FMC LEFT/RIGHT（status） | status | FMC 故障 60 s でラッチ | ATA34_2 p.702 | 無し |
| >PILOT RESPONSE | advisory | 乗員操作が一定時間無い（巡航 FL200 超 54 分、降下 5 分。APF の設定） | ATA34_2 p.480; LH3460 p.116 | 表に定義だけ |

GPS・IRS の EICAS は各担当（FCOM p.1429–1430）。

### 3.4 FMC メッセージ（航法・誘導・性能。データリンク系は除く）

△＝一部・不正確、×＝無し（仕様どおりに実装されたものは無い）。

| メッセージ | 種別 | 条件 | 根拠 | 現状 |
|---|---|---|---|---|
| CHECK ALT TGT | alert | VNAV が MCP 高度と FMC 目標高度の間で作動、水平を保つ | FCOM p.1431 | × |
| DESCENT PATH DELETED | alert | VNAV 中に降下パスを決める高度制限が全部消えた | FCOM p.1431 | × |
| DISCONTINUITY | alert | LNAV 中に discontinuity に入った。AFDS は最後のヘディング | FCOM p.1431 | × |
| DRAG REQUIRED | alert | VNAV 中に抵抗が必要、または A/T OFF で推力減が必要 | FCOM p.1431 | △ AP:3400-3413 |
| END OF OFFSET / END OF ROUTE | alert | オフセット終点の 5 NM 手前 / 経路終点を通過（最後のヘディング保持） | FCOM p.1431 | × |
| ENTER IRS POSITION | alert | 入力位置が IRS 比較に不合格、または NAV 移行可能なのに位置未入力 | FCOM p.1431 | △ IRS:102-126 |
| FUEL DISAGREE - PROG 2 | alert | TOTALIZER と CALCULATED の差 4,080 kg 以上（570 は 9,000 lb） | FCOM p.1432 | × |
| ILS TUNE INHIBITED - MCP | alert | FCC の同調禁止中に手動同調か新しい ILS 進入を activate | FCOM p.1432 | × |
| INSUFFICIENT FUEL | alert | 目的地予測燃料 < RESERVES | FCOM p.1432 | × |
| IRS POS/ORIGIN DISAGREE | alert | IRS 位置が出発空港と違う | FCOM p.1433 | × |
| LIMIT ALT FLXXX | alert | VNAV 中で CRZ ALT が VNAV 制限高度より上 | FCOM p.1433 | × |
| NAV DATA OUT OF DATE | alert | 日付が active DB の有効期間外 | FCOM p.1433 | × ネイティブのものを自動で消す（CRE:520） |
| NAV INVALID-TUNE AAA | alert | 進入に必要な局の信号が無い | FCOM p.1433 | × |
| NO ACTIVE ROUTE | alert | active 経路が無いのに LNAV 選択 | FCOM p.1433 | × |
| PERF/VNAV UNAVAILABLE | alert | GW・CI・CRZ ALT 未入力で VNAV 選択 | FCOM p.1433 | △ CRZ ALT だけ（AP:1025-1028） |
| PURGE UPDATES - POS 2 | alert | FMC 位置の誤りで無線データが DME 妥当性検査で棄却 | FCOM p.1433 | × |
| RESET MCP ALT | alert | VNAV 中、T/D の 2 分前に MCP が巡航高度のまま | FCOM p.665, p.1433 | △ 約 1 分前（MON:451-467） |
| RESYNCING OTHER FMC / RESYNC FAIL / SINGLE FMC OPERATION | alert | §4.12 | FCOM p.1433–1434 | × |
| RTA FIX DELETED / UNABLE RTA / UNABLE FLXXX AT RTA FIX | alert | RTA 点の削除、到着時刻・高度が達成不能 | FCOM p.1434 | × |
| RW/ILS FREQ ERROR / RW/ILS CRS ERROR | alert | 選択 ILS の周波数・コースが目的地滑走路と不一致 | FCOM p.1434 | CRS だけ誤用（AP:2397-2402） |
| SET CLOCK TO UTC TIME | alert | GPS の UTC と機長時計の差 > 12 s | FCOM p.1434 | × |
| SPLIT IRS OPERATION | alert | 極域か IRU 間の大差で単一 IRU 更新 | FCOM p.1434 | × |
| THRUST REQUIRED | alert | VNAV 中、A/T 切断で推力が必要 | FCOM p.1434 | × |
| UNABLE NEXT ALT | alert | VNAV の上昇が次の高度制限に間に合わない | FCOM p.1434 | × |
| VERIFY POSITION | alert | 更新センサーと FMC 位置、または左右 FMC の位置が違う | FCOM p.1435 | × |
| VERIFY RNP - POS REF 2 | alert | 既定 RNP が段階で変わり手入力 RNP が新既定を超える（APF） | FCOM p.1435 | × |
| ARR N/A FOR RUNWAY / RUNWAY N/A FOR SID | advisory | 滑走路と手続きが合わない | FCOM p.1435 | ネイティブ次第 |
| CRS REVERSAL AT FA FIX | advisory | procedure turn 無しで FA 点に course reversal | FCOM p.1435 | × |
| MAX ALT FLNNN / UNABLE CRZ ALT | advisory | CRZ ALT > 最大高度 / 上昇が降下パスと交差か巡航時間が最小未満 | FCOM p.1435–1436 | × |
| NOT ON INTERCEPT HEADING | advisory | LNAV 選択時に捕捉条件外で切込まない | FCOM p.1435 | × |
| ROUTE FULL | advisory | 変更で 120 点を超える | FCOM p.1435 | × |
| VERIFY RNP ENTRY | advisory | 手入力 RNP が既定を超えるか ANP 未満 | FCOM p.1436 | × |

## 4. 内部ロジック

### 4.1 飛行段階

| 段階 | 始まり → 終わり | 根拠 |
|---|---|---|
| preflight | 電源投入 → TO/GA | FCOM p.1235 |
| takeoff | TO/GA → 上昇推力への減推力 | FCOM p.1236, p.1325 |
| climb | 減推力 → T/C（PERF INIT の CRZ ALT 到達） | FCOM p.1236 |
| cruise | T/C → T/D（ステップ上昇・途中降下を含む） | FCOM p.1236 |
| descent | T/D、または VNAV DES ページが active（早期降下） → approach | FCOM p.1236, p.1389 |
| approach | 手続きの最初の点を通過、または滑走路がアクティブ点で残り 25 NM 未満 → 着陸。ゴーアラウンドで climb | FCOM p.1236, p.1389 |
| flight complete | エンジン停止 30 s 後。active 経路と搭載データを消し、一部を既定値へ | FCOM p.1236 |

- 段階は VNAV の推力基準、VNAV キーで出るページ、RNP 既定値、到着ページ、CPCS への値に使われる（FCOM p.1272, p.1400; ATA34_2 p.517, p.552）。
- 電源断から復帰すると FMC は再起動し、PERF INIT は再入力、経路が残っていれば activate が要る。LNAV の前に direct-to か intercept が要る（FCOM p.1274–1275。FMSPG p.23 は「完全に復帰」と書くが FCOM を採る）。

### 4.2 位置の計算

- 源の優先：LOC+GPS > LOC+DME-DME > LOC+VOR/DME > IRS+LOC > IRS+GPS > IRS+DME-DME > IRS+VOR/DME > IRS。POS REF の表題/ND 表示：LOC-GPS/LOC GPS、LOC-RADIO/LOC DD、LOC-RADIO/LOC VD、LOC/LOC、GPS L・GPS R/GPS、RADIO/DD、RADIO/VD、INERTIAL/IRS(X)（FCOM p.1241）。FMC は IRS の位置を必ず要し、他の源は IRS 位置と照合する。地上は IRS と GPS（FCOM p.1240）。FMC は IRS を更新しない（FMSPG p.28）。
- LOC 更新の条件：目的地滑走路の LOC、LOC 局の標高 +6,000 ft 未満、局から 20 NM 未満（back course 12 NM）、入航コースの 25° 扇内、トラックとコースの差 < 45°（FCOM p.1241）。LOC は横方向、縦方向は GPS か DME/VOR で補う（FMSPG p.26）。
- GPS：完全性監視で有効ならそのまま位置に使い、完全性を失っても他センサーと整合すれば使い続ける（FMSPG p.25）。GPS の ACTUAL が RNP の 2 倍以上で GPS 更新をやめる（FCOM p.1368）。GPS NAV INHIBIT/ENABLE は電源断でも保持、flight complete で既定（使用）に戻る（FCOM p.1369）。POS INIT の GPS POS は HIL ≤ 0.5 NM の側（L 優先）（LH3460 p.81）。
- 無線：DME の斜距離を水平距離にし、2 円の交点のうち IRS に近い方（ATA34_2 p.601）。VOR/DME は方位と距離。誤差見積り ET（1–30 NM）の内側の無線位置だけ使う（ATA34_2 p.606）。NAVAID INHIBIT（VOR/DME/VORTAC/DME を 2 局）、VOR ONLY INHIBIT（2 局）、VOR/DME NAV INHIBIT（全 VOR/DME、DME-DME は残る）。flight complete で消える（FCOM p.1356–1357; ATA34_2 p.548）。
- IRS の混合：3 台有効なら重み付き平均。1 台が平均から 30 NM 超が 5 s 続くとその飛行中は使わない。速度は 3 台の N/E 成分の平均、1 台が 20 kt 超ずれて 5 s で除外。DME-DME で速度も補正。2 台なら各 FMC が 1 台（L FMC は L か C、R FMC は C か R）、2 台の差が閾値を超えると VERIFY POSITION。1 台なら両 FMC がそれを使う（ATA34_2 p.601–602; FMSPG p.28）。高度は慣性と ADC の合成（ATA34_2 p.602）。
- ANP/RNP：ANP は 95% の円。RNP 既定は段階別：離陸 1.0、洋上 12.0、国内 2.0、ターミナル 1.0、進入 0.5 NM。手入力 0.01–99.9（ATA34_2 p.517; FCOM p.1368）。ANP > RNP で UNABLE RNP（FCOM p.1430）。
- PURGE：FMC 位置を混合 IRS 位置に置き換え、局があれば無線更新を再開（FCOM p.1368）。TO/GA で滑走路端（＋POS SHIFT）へ更新（GPS 更新が無いとき。FCOM p.1240, p.1321）。
- 極域：FMC 位置が 84° を超えると split IRS（各 FMC が 1 台、L FMC は L→C→R、R FMC は R→C→L。互いに最も近い 2 台を選ぶ）、SPLIT IRS OPERATION、無線補正は消え、IRU 位置へ徐々に移す。GPS 更新は 88.5° まで続き、88.0° 未満で再開。両 FMC が 83.5° 未満で 3 台混合へ戻る。UNABLE RNP は抑止。89° 超で IRS 故障なら即 IRU 位置（FCOM p.1241–1242; FMSPG p.219–220）。
- 真方位：82°N（80°W–130°W は 70°N）以北、82°S（120°E–160°E は 60°S）以南で FMC と IRU は真方位（FCOM p.1242）。

### 4.3 無線の自動同調

- VOR の状態：P（出発・到着手続きの局）、R（経路上の直前の VOR か、前方 250 NM 以内の VOR）、A（位置計算に最良の局）、M（手動）。手動は自動より優先、削除で自動へ。VOR を手動にすると VOR の自動同調は止まるが DME-DME の同調は続く（FCOM p.1240, p.1303–1304; ATA34_2 p.605）。
- DME：走査型。master FMC が 5 チャンネルを指定：1–2＝幾何が最良の組、3–4＝次の組か P/M/R 局、5＝ILS DME。候補は nav DB から EFIS の最大レンジ内を探し、条件と幾何で絞り、15 局の背景走査で確認（ATA34_2 p.605）。12,500 ft 未満は交差角 30–150° に最も近い組、以上は 90° に最も近い組（FMSPG p.26）。局の種別と到達距離・高度の figure of merit を使う（FMSPG p.27）。
- VOR 進入：IAF/FAF の通過で VOR を P 同調、滑走路点があれば入航コースを入れる（FCOM p.1304）。
- ILS：初期 PARK（PFD の表示を消す）。ILS/LOC/BC か ILS 滑走路への VOR・滑走路・VFR 進入を選ぶと、「T/D まで 200 NM 未満」か「経路の半分を過ぎた」（目的地に近い方）で周波数/コース＋PARK（小文字）、「T/D まで 50 NM 未満」か「滑走路端まで 150 NM 未満」か「降下段階」で A（同調）（FCOM p.1306–1307。ATA34_2 p.586 は 200 NM と書く。FCOM を採る）。
- ILS の禁止：離陸後 10 分と手動中は自動同調しない（目的地滑走路の変更で解除）。自動・手動とも禁止：AP 作動で LOC か G/S 捕捉、FD のみで捕捉かつ 500 ft RA 未満、地上で LOC 受信・ヘディングが前コースの 45° 以内・GS > 40 kt（FCC の信号）。手動の許可：TO/GA を押す、または AP 解除で両 FD OFF（FCOM p.1305; ATA34_2 p.470）。
- ADF は手動のみ（FCOM p.1303）。master FMC が故障（空中）か両系故障（地上）なら CDU が自側の無線を手動同調（ATA34_2 p.468）。

### 4.4 経路と EXEC

- RTE 1 と RTE 2、片方が active。非 active 側の ACTIVATE で EXEC 点灯、EXEC で active。active を変えると MOD・ERASE・EXEC 点灯。性能モードの変更も同じ（FCOM p.1238, p.1290）。最小の経路は出発・到着空港と 1 レグ（FCOM p.1278）。
- 地上で ORIGIN を入れ直すと経路を消す。空中は非 active 側だけ。滑走路は最初の点を通過で消す（FCOM p.1288–1289）。エアウェイは TO 点と前の TO 点を含むか前のエアウェイと交差すること。連続 2 本で交点（XJ52）を作り、120 点を超える変更は拒否（FCOM p.1250, p.1297）。
- SID 等の選択は discontinuity を生むことがあり、RTE/LEGS で解消（FCOM p.1236）。滑走路を変えると選択済み手続きを消す（FCOM p.1302）。到着ページは「出発地から 400 NM 超」「経路の半分超」「T/C 後で T/D の 2 分前」「T/D 通過」のどれかで目的地、それまでは出発地（FCOM p.1400）。上昇中に出発地まで 400 NM 未満かつ出発地が近ければ DEP ARR で出発地の到着（FCOM p.1343）。
- DIRECT TO/INTC CRS：アクティブ点の行へ入力。EXEC 前は到着コース、後は現在の要求トラック。大円。経路にない点は intercept コースを入力。ABEAM PTS で飛ばした点の真横に点（FCOM p.1237, p.1333–1334）。同じ点が経路に 2 回あれば direct-to・HOLD は最初の方（FCOM p.1237）。
- 定義点：lat/lon、PBD・PB/PB（SEA01。RTE 1 は 01–49、RTE 2 は 51–99）、along-track（discontinuity を作らない、隣の点までの距離未満）、緯度・経度の報告点（W060-10）。条件点は手入力不可（FCOM p.1249–1251; FMSPG p.212–215）。
- オフセット：空中、SID・STAR・transition 上でないとき。L/R 1–99 NM。STAR・進入・進入 transition・discontinuity・経路終点・135° 超の経路変化・ホールドまで。削除・0・direct-to で解除。LNAV 中の EXEC で捕捉旋回（FCOM p.1298–1299）。END OF OFFSET は 5 NM 手前（FCOM p.1431）。
- シーケンス：オフセットでなく経路から 21 NM 超離れているとアクティブ点を進めない。21 NM 超のオフセットへの出入りは 200 NM まで許す。VECTORS は終点の無い線で、先へは direct-to か intercept（FCOM p.1237, p.1298）。

### 4.5 レグ種別と手続き

- LNAV は通常、点間の大円。手続きでは FMC がヘディング、トラック、DME arc を指令（FCOM p.1245）。LEGS の脚方向：計算コース、手続きのコース/トラック、arc（半径・L/R）、HDG、TRK、HOLD AT、PROC TURN、PROC HOLD（FCOM p.1331）。570 は constant radius to fix（例：1.9 ARC R）（FCOM p.1247）。
- 条件点：高度通過、ヘディングで radial/DME まで、コース切込み、ヘディングでベクター。高度と切込みは括弧表示。例 (1000)：180° を 1,000 ft まで保持、その後 140°（FCOM p.1249; FMSPG p.215）。手続き上の無名の旋回点は lat/lon 点になる（FCOM p.1248）。
- 進入：transition 無しなら FAF の 4–8 NM 外（チャートの点か CFxxx）から直線進入。transition 選択で FAF intercept（PELLY INTC 等）に置き換え。INTC で進入コースを入航コースとするアクティブ点（FCOM p.1404–1405）。GP 角（ILS、B/C、GPS、LOC、RNV、NDB、VOR 進入、STAR にもある）を LEGS に出し、VNAV PTH はその角で誘導（FCOM p.1262, p.1405）。
- VFR 進入：滑走路から 8 NM の FAxxx（170 kt／滑走路 +2,000 ft）→ 滑走路 50 ft。FPA 既定 3.0°（2.4–3.7）。RWY EXT 1.0–25.0 NM。パスに乗るまで水平（FCOM p.1407–1408）。
- fly-by と fly-over の区別、通常の旋回のバンクと旋回開始点：資料に記載なし。資料にあるのは「区間の間は曲線でつなぐ」（ATA34_2 p.615）、「EFIS は全点を滑らかにつなぐ」（ATA34_2 p.626）、「捕捉は最大 25° で滑らかに」（ATA34_2 p.618）だけ。

### 4.6 ホールド

| 項目 | 内容 | 根拠 |
|---|---|---|
| 旋回半径 | 保持点が TO 点になった時に計算。性能初期化済みなら現在 GS＋風の大きさ、未初期化なら TAS＋風で、25° バンク。以後は保持点通過ごとに「保持速度の TAS＋風」で再計算。FAA/ICAO の保護空域内に制限 | FMSPG p.224; FCOM p.1413 |
| 保持速度 | 速度介入中は MCP。制限速度があれば min(制限, best hold)、無ければ best hold（Vgmin が下限）。best hold は最大航続時間速度とフラップ機動速度の大きい方 | FMSPG p.224; FCOM p.1419, PI p.318 |
| 脚長 | LEG TIME（≤ 14,000 ft 1.0 分、> 14,000 ft 1.5 分）か LEG DIST（排他）。時間なら 時間/60 ×（保持 TAS＋入航方向の風）。比較高度：上昇・降下中はホールドの制限高度（窓は上限）→ 直前の脚の制限 → 1 分、巡航中は CRZ ALT。VNAV 中に 14,000 ft を通過し SPD/TGT ALT が大文字なら自動切替 | FCOM p.1417–1418; FMSPG p.222–224 |
| 進入 | 保持点通過時のトラックで parallel/teardrop/direct。最初の外側脚は計算距離。parallel：入航に平行な脚（半径 × 2.41）と保持点側への 180°。teardrop：入航の逆から 40° の脚（半径 × 2.95）と 180°。direct：区間なし | FCOM p.1413; FMSPG p.225 |
| バンク | ホールドと進入は最大 30° | FCOM p.1413; FMSPG p.164 |
| 終了 | 高度終了（AT OR ABOVE、上昇のみ。到達で exit armed、既に上なら飛ばない）、点終了（1 周）、手動（EXIT HOLD → EXIT ARMED → 保持点で離脱）。exit armed で最短で保持点へ戻る形に変える。direct-to で即離脱。HOLD AT 点の削除・飛ばしで次の点へ直行。PROC HOLD は入航で保持点に着いたら出る | FCOM p.1416, p.1419; FMSPG p.221–222 |
| 作成 | HOLD キー：経路にホールドが無ければ LEGS に HOLD AT 枠と PPOS（EXEC 時の位置）。入航コース既定は前の脚のコース、右旋回。手で作れるのは手動終了型だけ。変更は次の保持点通過で有効 | FCOM p.1413–1416; FMSPG p.222 |
| 減速・縦 | 上昇・巡航は事前に保持速度へ減速、降下はホールドに高度制限があるときだけ。上昇中は降下指令を、降下中は上昇指令を出さない（制限種別ごとの目標は FMSPG） | FMSPG p.225–227 |
| 予測 | FIX ETA、EFC TIME（下流の ETA・燃料に反映）、HOLD AVAIL（予備燃料を使わずに待てる時間）、BEST SPEED | FCOM p.1419 |

### 4.7 LNAV

- 作動（ATA34_2 p.619 の図）：FMC 側は「software monitor valid、IRS valid、ADC valid、active route、50 ft 超、捕捉条件、LNAV ARM/OPERATE」の AND で横誘導指令の SSM を NCD → valid にし、FCC が SSM を見て arm（白）→ engaged（緑）。捕捉条件：アクティブレグから 2.5 NM 以内、またはトラックがレグに交わり最大 25° バンクで滑らかに乗れる（ATA34_2 p.618）。作動高度は滑走路標高 +50 ft、標高は 100 kt 通過時の気圧高度（FCOM p.644, p.667）。ゴーアラウンド後は 400 ft RA 超（FCOM p.1262）。
- 現ヘディング保持：最終点、discontinuity 手前の点、オフセット最終点の通過。経路の activate やエアウェイ切込みで捕捉条件外のとき（FCOM p.644）。
- 誘導：前後の点の位置と現在位置からクロストラック誤差を作り、横の誘導指令を FCC へ（ATA34_2 p.615, p.617）。バンクは捕捉 25°、ホールド 30°。通常の旋回の限界は資料に記載なし（推定：25° と予測 GS の半径で旋回開始を決める）。
- 解除：HDG HOLD、HDG SEL、LOC 捕捉、FMC 両系故障（FCOM p.644–645）。

### 4.8 VNAV

- 作動（ATA34_2 p.621 の図）：共通 AND＝software monitor valid、sensor data valid、PERF ページ入力済み、400 ft 超、VNAV ARM/OPERATE。VNAV SPD＝(climb 段階 OR step descent)、VNAV ALT＝MCP 高度を横切る、VNAV PTH＝active route AND (cruise OR descent 段階)。性能解は GW・CI・目標高度・経路が揃って初めて出る（FMSPG p.30）。
- 誘導の 4 形態（ATA34_2 p.615–616）：speed/thrust（ピッチで速度、推力は目標値。上昇・早期降下・driftdown）、path/speed（ピッチでパス、推力で速度。巡航・浅い降下）、path/idle（ピッチでパス、推力アイドル。基本の降下）、speed/hold（ピッチで速度、A/T HOLD。step descent）。FMA は VNAV SPD/PTH/ALT（FCOM p.645, p.664–665）。

上昇（FCOM p.1255, p.1326, p.667）：

| 区間 | 目標速度 | 根拠 |
|---|---|---|
| 離陸〜400 ft | V2+10〜V2+25（回転の速さで決まる）。VNAV 作動までは目標を現速度に合わせ続ける | FCOM p.1255, p.1325 |
| ACCEL HT かフラップ上げ開始 | 現フラップのプラカード −5 kt。格納ごとに次のプラカード −5 kt | FCOM p.1255, p.667 |
| 減推力点（400–9,999 ft HAA か flaps 5） | 推力基準を armed CLB（CLB/CLB 1/CLB 2）へ | FCOM p.1255, p.1272, p.1319 |
| フラップ格納後（か AFDS 捕捉高度） | max(VREF+100, 出発地の速度移行値)、形態で制限 | FCOM p.1255, p.667 |
| SPD TRANS 高度通過 | ECON 上昇速度（CAS → Mach）を巡航まで | FCOM p.1326 |

- 制限：手続きの速度制限、点の速度制限、SPD RESTR、選択速度。点の速度制限は VREF+100 か移行速度より大きいときに優先。制限と性能速度の遅い方。高度制限での一時水平は指令速度の VNAV PTH。届かなければ UNABLE NEXT ALT（速度介入で遅くするか CLB 減格を消す）。CLB ページの ERROR：制限点で 200 ft 以上低いか 1 NM 以上遠いとき（FCOM p.1255, p.1326, p.1329; ATA34_2 p.553）。
- 上昇 SPD TRANS：出発地の nav DB 値、または max(出発地の移行速度, VREF+100)（例 272/10000）。移行高度より上は出さない、削除可（FCOM p.1328）。ATA34_2 p.552 は既定を「10,000 ft まで 250 kt、以後 ECON」の 2 区間と書く。SPD RESTR：CRZ ALT 未満の点に結びつかない制限（例 240/8000）、入力前はダッシュ、通過でダッシュ（FCOM p.1328; ATA34_2 p.553）。TRANS ALT：出発地の nav DB、無ければ 18,000 ft。CDU の表示を FL にするだけ（FCOM p.1329）。
- T/C：CRZ ALT に達する点、緑の円。MCP 高度で一時水平すると VNAV ALT、ノブを押すと VNAV SPD で上昇再開（FCOM p.1256）。

巡航：

- 速度：ECON（CI）、LRC、E/O、選択、RTA。CI 0＝最大航続（燃料最小）、9999＝包囲線最大、範囲 0–9999。CI の変更は T/D の 10 NM 手前まで（FCOM p.1238, p.1257, p.1311）。ECON は重量・高度・温度・CI（と風）の関数（FMSPG p.261–262; ATA34_2 p.610）。
- 巡航上昇・降下：MCP を CRZ ALT と違う値にしてノブ → CRZ ALT＝MCP、ACT ECON CRZ CLB/DES（ノブ経由は MOD を作らない）。降下は T/D の 50 NM より手前のとき。MCP が SPD TRANS/RESTR 高度より下なら両者を消す（乗員が守る）。降下パスを捕捉しないことがある（FCOM p.1257, p.1261, p.1348）。降下率は資料に記載なし（E/O では約 1,250 fpm：FCOM p.1269）。
- ステップ：STEP SIZE 0–9000（1000 刻み）か ICAO（既定）。0 は一定高度で予測。STEP TO は OPT より上。ICAO は「離陸前の CRZ ALT で決まる飛行方向」の OPT 直上の高度（FL280・OPT FL337 → FL350）、数値は CRZ ALT＋n×STEP SIZE の OPT 直上。LEGS の S 付き高度が優先。ステップ点は OPT が 2 高度の中間になる重量の点。AT（ECON は運航費、他は燃料が最小の点）→ NOW。MAX 不足なら AVAIL AT。T/D 200 NM 以内は TO T/D で STEP TO 空白（FCOM p.1257, p.1332, p.1348–1349）。予測はステップを予定どおり行う前提、点を過ぎたら即上昇の前提（FMSPG p.234）。
- OPT/MAX：OPT は ECON なら運航費、LRC・選択速度なら燃料が最小。MAX は総重量・作動エンジン数・速度モード・残余上昇率（既定 100 fpm）で、制限は無視（FCOM p.1349–1350）。予定上昇速度と巡航速度が包囲線内（ATA34_2 p.611）。CRZ CG（既定 20.0%、8.5–33.0%）を最大高度とバフェット余裕に使う（FCOM p.1311）。性能表の前提は「推力とバフェットの厳しい方、OPT は 1.5 g 以上の余裕、上限 45,000 ft」（FCOM PI p.316–317）。CRZ ALT ≥ MAX なら燃料予測を出さない（ATA34_2 p.611）。
- RTA（109/405）：指定点に ±30 s、巡航のみ、E/O 不可、MAX SPD 既定 M.880、不能で UNABLE RTA（FCOM p.1269, p.1383–1384）。

降下：

- E/D：到着・進入手続きを入れると作る。滑走路点の 50 ft 上、VOR 進入は MAP。巡航中に下流の点へ高度制限を入れても作る。DES ページの E/D は降下段階の最も低い高度制限。無ければ DES ページは空白（FCOM p.1258, p.1389, p.1392）。
- T/D とパス：最初の制限までのパスはアイドル推力・スピードブレーキ収納・予報風と巡航風・防氷の予測・目標速度で作る。最初の制限より後は点間の直線。浅すぎる区間は A/T SPD で速度、昇降舵でパス（FCOM p.1258）。図の順序：T/D で水平減速（VNAV PTH）→ 降下 → 速度制限高度の手前で目標速度へ減速（VNAV PTH、約 500 fpm）→ 目標速度で降下・進入（FCOM p.1263–1264）。
- 速度：ECON か手入力の Mach/CAS。ECON は 349 kt（VMO/MMO −16）、手入力は 354 kt（−11）を超えない。移行高度で減速し、目標は移行速度の 10 kt 下（FCOM p.1258）。降下 SPD TRANS は目的地の制限速度 −10 kt（無ければ 240）/nav DB の高度（無ければ 10,000 ft）、高度未満で空白。SPD RESTR は E/D より高い点に結びつかない制限（CAS）（FCOM p.1392; ATA34_2 p.564）。既定の降下は「ECON で 10,000 ft まで、以後 240 kt」（ATA34_2 p.563）。

| パスと速度の許容（FCOM p.1259–1260） | 最初の速度制限より上 | 最初の速度制限より下 |
|---|---|---|
| 遅い | 目標 −15 kt 超で A/T を IDLE/HOLD → SPD（A/T 不作動なら THRUST REQUIRED）。最小機動速度まで許し、その後パスの下へ。150 ft 以内に保てなければ VNAV SPD に反転、目標 max(best hold, 最小機動)+5 kt、THRUST REQUIRED 再表示 | 目標 −10 kt 超で同様。反転時の目標は目的地移行速度 −10 kt（最小機動以上） |
| 速い | 349 kt 超で DRAG REQUIRED。354 kt まで加速を許し、パスの上 150 ft まで。保てなければ VNAV SPD に反転、目標 349 kt | 目標 +10 kt 超で DRAG REQUIRED。目標 +15 kt まで（移行高度以下は移行速度 +5 kt、フラップ時はプラカード −5 kt まで）、150 ft 上まで。反転時は移行速度 −10 kt |

- 早期降下：DES NOW（T/D があり降下段階でないとき）、または T/D 50 NM 以内で MCP ノブ、あるいは MCP を最も高い降下制限より下にしてノブ → 降下段階。約 1,250 fpm、現在の降下速度スケジュール、A/T は THR → HOLD（レバーで率を調整可）、VNAV SPD。アイドルパスに交わったら VNAV PTH（FCOM p.1260–1261, p.1389, p.1393, p.665）。DES DIR/CLB DIR：機体と MCP 高度の間の高度制限を全部削除、CRZ ALT は変えない（FCOM p.1329, p.1393）。
- MCP 高度との関係：VNAV のプロファイルと MCP 高度が衝突すると水平になり VNAV ALT。高度を変えてノブ、またはパスより下ならパスとの交差で降下継続。T/D の 2 分前に MCP が巡航高度のままなら RESET MCP ALT（FCOM p.645, p.665）。VNAV 作動時に MCP と FMC 目標の間にいれば CHECK ALT TGT（FCOM p.1431）。
- 進入（FCOM p.1261–1262）：on approach になるのは VFR 進入で FAxxx を通過、RWyyy へ direct/intercept で滑走路端 25 NM 以内、計器進入の最初の点を通過。抜けるのは TOGA、着陸、最終点を越えて ACT END OF DES。on approach 中は IAS/MACH 窓を開けても VNAV PTH のまま、MCP を機体より 300 ft 以上上に設定しても降下継続。フラッププラカードの 5 kt 以内かつパスの上 150 ft 超で VNAV SPD。GP 角の脚は VNAV PTH でその角、その手前の点を過ぎたらパスに交わるまで水平。
- ミスト進入（FCOM p.1262–1264）：TOGA。LNAV/VNAV は 400 ft RA 超でのみ。機体より下の降下制限を消す（点は残す）。手続きの最高高度を新しい CRZ ALT にして descent → climb。巡航段階の速度目標は min(移行速度, best hold, ECON 巡航)。VNAV SPD で上昇し、ミスト進入高度で VNAV PTH。
- E/O（FCOM p.1265–1269, p.1341–1342, p.1350–1353）：VNAV 作動後で E/O 加速高度・減推力点より下で故障 → VNAV SPD で V2+10、TO 推力維持。加速高度かフラップ上げで VREF+100 へ加速（ACT VREF+100 CLB）、VREF+98 で TO → CON（フラップ全上げ時）。ENG OUT> を EXEC：E/O 上昇、上昇の移行・制限を削除、CON。E/O MAX より上なら E/O LRC driftdown（MCP を E/O MAX 以下にして EXEC、CON、最小 300 fpm、E/O MAX を捕捉して E/O LRC 巡航）。2 発故障で 2E/O。降下に E/O 専用ページは無い（FCOM p.1400）。

### 4.9 性能と予測

- 性能機能の出力（ATA34_2 p.609–612）：重量・燃料、速度包囲線（フラップ・荷重倍数・脚で最小・最大）、最適 VNAV 速度（最小移行上昇、ECON 上昇・巡航・降下、最大角上昇、LRC、E/O LRC、E/O 最小抗力、best hold）、軌跡予測、最大・最適高度、推力目標（巡航の目標推力、水平到達時の推力）、離陸速度・トリム、VREF。どれかが無効になると全速度目標を無効にし CDU から消す（ATA34_2 p.610）。
- 軌跡予測の入力：必須は GW、CI、CRZ ALT、目的地、点、緯度経度、作動中の誘導、高度、燃料、2 点以上の横経路、E/D。任意は点ごとの風・温度、降下の着氷予報、FF 係数、上昇減格、抗力係数。降下データが無いと降下パスも T/D も作らず、T/C 以後を巡航の続きで予測（ATA34_2 p.610–611）。GW は ZFW から計算（または GW から ZFW）。全性能計算は GW が要る（FCOM p.1309–1310; ATA34_2 p.609）。
- 予測の出力：目的地の ETA・燃料（ステップ前提）、各点の ETA・燃料（RTE DATA、discontinuity は直行で計算）、T/C・T/D・S/C・E/D・LEVEL AT までの時間・距離、DEST の代わりに代替地（DIR TO ALTERNATE）や経路上の点（EN ROUTE WPT）（FCOM p.1349, p.1363, p.1372–1373）。脚・フラップを出したままの飛行は予測に入らない（FCOM p.1274, PI p.323）。
- 風（FCOM p.1364–1366; FMSPG p.228–233）：点ごとに 4 高度。ある高度の最初の入力は全点（前後）へ、以後の入力は下流へ次の入力まで伝搬。OAT は標準減率で他高度へ。巡航高度が入力の間なら補間。全入力が巡航高度より上なら最低入力から出発地（上昇）・目的地（巡航）の高度で 0 へ、全部下なら最高入力を巡航高度まで延長。降下予報（4 高度、TRANS LVL 既定 FL180、TAI ON 高度）は巡航風と混ぜる（FCOM p.1395–1397）。計測風との混合：機位で 100%、前方 200 NM（上昇・降下は 5,000 ft）で 50/50、その先はほぼ予報。
- その他：OFFPATH DES の clean/drag circle（FCOM p.1398–1399）、FIX INFO の交点の ETA・距離・高度と PRED ETA-ALT（FCOM p.1358–1359）。

### 4.10 燃料監視

- CALC：始動前は FQIS 値、FF 信号で切り離して FF で減算。ジェティソン中は FQIS に合わせ、終了後に再び減算。全エンジン停止後に FQIS へ戻す。MANUAL：乗員入力を FF で減算（TOTALIZER 表示を消す）。SENSED：始動後に FF が無効になったら FQIS（PROG は TOTALIZER）（FCOM p.1273–1274, p.1310, p.1379; ATA34_2 p.531 は FF 無効 2 分超）。
- FUEL USED：FF からエンジンごと。flight complete まで保持し、エンジン始動か地上の長時間電源断で消える。始動後 2 分超の FF 無効か地上で無効なら空白（FCOM p.1274）。
- FUEL DISAGREE - PROG 2：差 4,080 kg 以上（109/405）で、PROG 2 の USE（TOTALIZER/CALCULATED）で選ぶ。FF 公差で 25–40 kg/h の差は普通（FCOM p.1381–1382）。ATA34_2 p.569 は 9,000 lb が 5 分続いたとき。
- INSUFFICIENT FUEL：目的地の予測燃料 < RESERVES（FCOM p.1274, p.1432）。

### 4.11 メッセージの扱い

- alert と advisory、どちらも MSG 灯。alert だけが EICAS の FMC MESSAGE（level C）。alert は advisory より優先して上書き、新しい alert が来ると古いものはスタックへ。CLR で上から 1 件ずつ（押し続けても連続で消えない）。原因が解消すれば消える。滑走路が経路にある進入中の 500 ft AGL 未満は alert を出さず、flight complete か 1,000 ft AGL 上昇通過で出す。advisory は条件が起きた CDU だけ、入力誤りの advisory が一般 advisory より優先（ATA34_2 p.635–636; FCOM p.1430）。

### 4.12 二重系・故障・代替航法

- resync：比較で差が出た、または内部試験失敗で再起動したとき。master が経路・性能データを送る（約 15 s）。その間相手 CDU は故障表示、他方に RESYNCING OTHER FMC。失敗で一方を停止（FCOM p.1277; ATA34_2 p.632）。
- 単一故障：resync、active 経路が非 active、性能データ喪失、LNAV/VNAV 喪失がありうる。地上はどちらでも SINGLE FMC OPERATION。空中で非選択側が故障：その CDU に TIMEOUT - RESELECT、他に SINGLE FMC OPERATION。選択側（master）が故障：両 CDU に TIMEOUT - RESELECT、3 台の FAIL 灯、その FMC を源とする ND が消え、遅れて FMC LEFT/RIGHT。selector を回すと復帰（FCOM p.1275）。故障 FMC は出力を止め、PFD の A/T FMA 空白、ND に MAP（30 s 後）と VTK 旗（ATA34_2 p.630）。両系故障：LNAV・VNAV・A/T 不可（FCOM p.1275）。LH3460 p.90–93 に正常時と片系故障時の割り当て図。
- 代替航法（FCOM p.1421–1428; ATA34_2 p.589–592）：CDU は自側 IRU で計算。FMC の active 経路を常にコピーし、故障時は条件点・オフセット・ホールド以外を保持。新しい点は lat/lon だけ。大円、active 点の変更は「現在位置から直行」だけ。CDU ごとに独立。L CDU は機長 ND、R は F/O ND、C は切替（F/O ND でレンジが機長と違うと MAP RANGE DISAGREE）。active 点だけ磁方位、以後は真方位。無線は各 CDU で手動（L：L VOR/DME/ADF/ILS、R：右側、C：C ILS）。故障時 autotune 中の ILS はコピー。ページは IRS LEGS、IRS PROGRESS（LAST/TO/NEXT/DEST の DTG・TTG、IRS 位置、XTK、DTK、TK、GS）、ALTN NAV RADIO。

## 5. 他系統とのつながり

| 相手 | FMC への入力 | FMC からの出力 | 根拠 |
|---|---|---|---|
| AFDS（MCP・FCC。ATA 22） | 選択値・ボタン・介入・TO/GA・A/T ARM、ILS 同調禁止 | LNAV/VNAV の誘導指令、V/S 指令、速度制限、MCP の窓表示・モード | ATA34_2 p.470 |
| A/T・EEC（別担当） | エンジンデータ（EIU） | VNAV の推力モード要求と目標推力 | ATA34_2 p.615–617 |
| IRS・GPS・航法無線・ADC | 位置・速度・方位・距離・偏位・高度・温度 | POS INIT 位置、SET HDG、無線の周波数・コース | ATA34_2 p.458–459, p.468, p.478 |
| 表示（EIU/IDU） | EFIS CP | PFD 速度テープ・A/T FMA、ND 地図、GW など | ATA34_2 p.462–466, p.501–506 |
| CPCS（ATA 21） | — | 着陸高度、上昇・降下のプロファイル（T/D など） | FCOM p.1400; ATA34_2 p.477 |
| GPWC・失速警報（MAWEA） | — | 位置・トラック（L FMC）／GW・CG | ATA34_2 p.477–478 |
| 燃料（ATA 28） | 総燃料・FF・ジェティソン | 予測、FUEL DISAGREE、INSUFFICIENT FUEL | FCOM p.1273–1274 |

- 現コードの実際：AP が `laminar/B747/fms/data`（JSON）の速度・高度・CI を読む（VS:168, VS:204, VS:233 など）。EEC と FDR も同じ JSON を読む（`B747.42.xt.EEC.lua:318, 411`）。ND は `autopilot/dist/top_of_descent_lat` などと `xtlua/fms` を読む（`B747.61.xt.nd.lua:27-34, 69`）。CPCS の着陸高度は FMC から来ず 2,000 ft の既定値（`B747.55.xt.air.lua:881`、ATA-21.md と対）。PFD の速度帯（Vmc/Vmo）は計器モジュールが計算（`B747.60.xt.fltInst02.lua:2861-2956`）。

## 6. 実装上の注意

### 6.1 ネイティブ FMS に頼ることの限界

- 受け取れるもの：XTLua の本体（`plugins/xtlua_keysystems/64/win.xpl`）が使う SDK は旧来の FMS API だけ（バイナリ内の名前：XPLMCountFMSEntries、XPLMGetFMSEntryInfo、XPLMGetDisplayedFMSEntry、XPLMGetDestinationFMSEntry、XPLMSetDestinationFMSEntry、XPLMSetFMSEntryLatLon、XPLMClearFMSEntry、XPLMLoadFMSFlightPlan）。この API の 1 点は「種類・ID・航法施設・高度 1 つ・緯経度」で、`xtlua/fms` はこれに active 印を足した配列（推定）。コードが使うのは [2] 種類（1＝空港、2048＝lat/lon）、[5][6] 緯経度、[8] ID（"latlon"、"VECTOR"、"(1000)"、"PPOS"）、[9] 高度、[10] active（AP:1670, AP:2186, AP:2323, MON:38, FMS:845）。

| 欠ける情報 | できない・難しいこと | GAP |
|---|---|---|
| 脚の種類、旋回方向、arc の中心・半径 | HDG/TRK 脚、コース → 高度、radial/DME まで、INTC、VECTORS、DME arc、RF、PROC TURN を本物どおりに飛ぶこと。条件点の位置はネイティブが置いた点を使うしかない | FMC-01 |
| fly-over 印 | fly-over 点（DER・MAP など）での旋回の遅らせ | FMC-01, 04 |
| ホールドの定義 | 形・進入・出口・HOLD AVAIL | FMC-02 |
| 高度制限の種類（AT/A/B/窓/S） | at or above の通過、窓、ステップ点、UNABLE NEXT ALT、E/D（最も低い制限） | FMC-07, 12 |
| 速度制限 | SID/STAR の速度と減速区間の計画 | FMC-08 |
| 手続きの区切り（SID/STAR/進入/ミスト）、FAF・MAP、GP 角、滑走路端標高 | approach 段階、on approach、GP 角の VNAV PTH、VOR 進入の E/D、ミスト進入の CRZ ALT、オフセットの終了、到着ページ・CPCS の切替 | FMC-16, 34, 37 |
| 空港の移行高度・制限速度 | SPD TRANS、TRANS ALT/LVL | FMC-10 |
| RTE 2、ACT/MOD の区別、discontinuity（入るか未確認） | 非 active 経路、RTE COPY、MOD の白破線、性能変更を含む EXEC、DISCONTINUITY での保持 | FMC-06, 34 |

- 副作用：3 台の CDU が同じネイティブ CDU（`cdu1`、`sim/FMS/`）を写すので、ネイティブのページを左右で別に出せない（CRE:313-328, FMS:808, FMS:817, FMS:826）。EXEC 灯と MOD はネイティブのもので、自前のページ（CRZ ALT・速度）は MOD を作らない。CRZ ALT はネイティブの VNAV ページ 2 に打ち込んで読み戻している（PG:618-654, PG:1187-1209）。ND の経路線はネイティブの EFIS 地図が描く（`747-400.acf:98958`、`:99872`）。自前の描画に変えるにはパネル定義の変更が要る（純正 acf は不可、カスタム acf は承認が要る：ARCHITECTURE.md §5）。
- 選択肢（どちらも推定）
  - A：ネイティブを経路入力に残し、CIFP（Custom Data 優先）を自前で読み、選ばれた手続きの脚・制限・速度・fly-over・GP 角を点列に対応づける。工数は小さいが、乗員が LEGS を編集すると対応が崩れやすく、ホールド・RTE 2・MOD は解決しない。
  - B：経路を自前で持つ（nav DB を X-Plane のデータファイルと CIFP から読み、RTE/LEGS/DEP-ARR/HOLD/EXEC を実装）。ネイティブには ND の線のためだけに緯経度を流すか、ND を自前の記号で描く。FCOM どおりにするにはこれしかないが L 規模で、CDU 担当と重なる。§8 で B を段階的に勧める。

### 6.2 AFDS・推力との境界

- 今の LNAV は X-Plane の HDG SEL と X-Plane の FD ロール（`sim/cockpit2/autopilot/flight_director_roll_deg`：AP:225、`B747.19.xt.hydraulics_override.lua:408-425`）を使い、バンク限界は X-Plane の `bank_angle_mode`（AP:1362-1382, AP:3454）。VNAV は自前の `vvi_status`・`speed_status`・`altitude_hold_status` を切り替え、油圧モジュールにピッチを作らせている（MON:136-175, MON:238-330）。作り直しでは FMC が「ロール指令（か目標トラックと XTK）」「目標速度」「目標パス（高度・FPA）」「A/T モード要求」を出し、AFDS がそれを使う形に分ける。ATA 22 の作り直しと一緒に決める。
- 推力の値（CLB/CON/GA、減格）は別担当。VNAV から渡すのはモード要求（THR REF、THR、IDLE、HOLD、SPD）と目標だけ。

### 6.3 簡略化してよいもの・いけないもの

- よい：FMC 2 台は「1 つの計算＋master・故障の状態」で表し、resync は表示と遅延だけ。BITE・データローダー・クロスロード。nav DB の 2 サイクル（X-Plane のサイクルを表示）。FMC 位置はシムの真値＋更新モードに応じた ANP と IRS ドリフトの簡易模型（ANP の式は資料に記載なし、推定）。DME-DME は仮想でよいが、VOR/ILS の同調と P/R/A/M 表示は残す。性能 DB は FCOM PI の表から作る（PW4056：p.223–324、CF6-80C2B1F：p.325–412。RR は資料が無いので PW で代用、推定）。ECON の CI 依存は資料に表が無いので推定。
- いけない：高度・速度制限を守ること、T/D・E/D とアイドルパス・減速区間、パスと速度の許容と反転、MCP の高度・速度ノブとの関係、LNAV の捕捉とシーケンス（21 NM）、ホールドの進入と出口、乗員の行動を促すメッセージ（UNABLE NEXT ALT、DRAG/THRUST REQUIRED、RESET MCP ALT、DISCONTINUITY、END OF ROUTE、INSUFFICIENT FUEL、UNABLE RNP）。
- 速度の上限は ECON 降下 349 kt、手入力 354 kt（FCOM p.1258）。保持速度は max(最大航続時間速度, フラップ機動速度)（FCOM PI p.318）。

### 6.4 XTLua と負荷

- `xtlua/fms` は変わったときだけ decode する（今は毎フレーム：AP:3535、FMS:936、VPG:69）。`collectgarbage("collect")` を毎フレーム呼ばない（AP:3504）。
- m/s と kt、NM と m の混在が誤りを生んでいる（FMC-15, FMC-21）。単位を変数名に付ける。グローバルの表は metatable 付き（ARCHITECTURE.md §1）。

## 7. 現状実装との比較（GAP 候補）

現状の作り（要約）：
- 経路は X-Plane のネイティブ FMS が持つ。RTE の 2 ページ目以降と LEGS はネイティブ CDU の行を写してキーを `sim/FMS/` へ送るだけ（PG:96-177, LEGS:1-52）。
- LNAV：`override_fms_advance`=1 で自前にアクティブ点を選び（`xtlua/currentFMSID` に書く）、その点への方位に風補正をして X-Plane の HDG SEL に入れる（AP:2183-2316, MON:789-863）。
- VNAV：T/D・E/D・パスは 290 ft/NM、上昇は FLCH、降下は計算した V/S、巡航は ALT HOLD（AP:2014-2171, MON:26-357, VN:16-124）。速度は高度帯の状態機械（VS:101-494）。
- 予測：OPT/MAX は GW の一次式、燃料は現在の FF × 時間か 51.6 lb/NM（VPG:190-310, PRG:64-119）。位置はシムの真値（IRS:29-63）。

| ID | 種別 | 重要度 | 規模 | 内容 | 根拠 | 該当コード |
|---|---|---|---|---|---|---|
| FMC-01 | 欠落 | 高 | L | 経路モデルが無い。ネイティブの点列（種類・ID・緯経度・高度 1 つ・active）だけで、レグ種別（HDG/TRK、コース → 高度、radial/DME まで、INTC、VECTORS、DME arc、RF、PROC TURN）、fly-over、手続きの区切りを知らず、全レグを点間の直線で扱う | FCOM p.1245, p.1247, p.1249, p.1331; ATA34_2 p.615 | AP:3534-3537, AP:2183-2316, MON:789-863 |
| FMC-02 | 欠落 | 高 | L | ホールドが無い（形、進入、30° バンク、種類別の出口、EXIT HOLD、HOLD AVAIL・BEST SPEED・EFC、減速区間）。HOLD キーはネイティブの HOLD ページを出すだけで、自前の LNAV はホールドを飛べない | FCOM p.1413–1419; FMSPG p.164, p.221–227; ATA34_2 p.573–574 | CRE:94-99, MON:789-863 |
| FMC-03 | 挙動の誤り | 高 | M | LNAV は arm 後、電波高度 50 ft で無条件に作動。2.5 NM・切込み・25° で乗れるかの判定、active route の確認、NOT ON INTERCEPT HEADING が無い。基準も滑走路標高 +50 ft（100 kt で記録した気圧高度）でない | FCOM p.644, p.663, p.667; ATA34_2 p.618–619; FMSPG p.21 | AP:1058-1074, AP:2877-2880 |
| FMC-04 | 挙動の誤り | 高 | M | 横誘導が無く、アクティブ点への方位（残り 10 NM 超ならレグ上 5 NM 先）を HDG SEL に入れるだけ。旋回の曲線遷移が無く、旋回開始は方位変化と GS の経験式（1–8 NM）。バンクは BANK LIMIT（HDG SEL 用）と X-Plane の FD ロールに依存し、acf の AP 設定（ACF_DIFF §3.3）でも変わりうる | ATA34_2 p.615, p.617–618, p.626; FCOM p.647, p.1413 | MON:789-863, AP:2272-2285, AP:1362-1382, AP:3454 |
| FMC-05 | 挙動の誤り | 中 | S | シーケンスに 21 NM の制限が無い（100 NM まで次のレグを探す）、オフセット移行の 200 NM も無い。重複点の「最初の方」規則が無い。RA 1,000 ft 未満かつ V/S 500 fpm 未満では止まる | FCOM p.1237, p.1298 | AP:2185, AP:2194, AP:2267 |
| FMC-06 | 欠落 | 高 | M | 経路終点・discontinuity・オフセット終点で現ヘディングを保持しない（最後の点へ向け続ける）。DISCONTINUITY・END OF ROUTE・END OF OFFSET を出さない | FCOM p.644, p.1431 | MON:778-863, NOTI:10-13 |
| FMC-07 | 欠落 | 高 | L | 高度制限の種類（AT/A/B/窓/S）が無い。上昇は「次に高度を持つ点」で水平（at or above でも止まる）、降下は移行高度より下の高度だけ使う。CRZ ALT 未満の検査、UNABLE NEXT ALT、CLB DIR/DES DIR、DESCENT PATH DELETED が無い | FCOM p.1253, p.1255, p.1329, p.1332, p.1393 | MON:26-101 |
| FMC-08 | 欠落 | 高 | L | 点・手続きの速度制限が無い（ネイティブの点に速度が無い）。「制限と性能速度の遅い方」「VREF+100/移行速度より大きい制限を優先」も無い | FCOM p.1326, p.1329, p.1332 | なし（VS:101-129 は SPD RESTR/TRANS だけ） |
| FMC-09 | 挙動の誤り | 高 | S | 上昇速度の取り違え：SPD TRANS 高度未満は `clbspd`（250、ECON SPD 欄）、以上は `transpd`（272、SPD TRANS の速度）を飛び、ECON 上昇 CAS が無いまま 272 kt で Mach 移行まで上がる。VREF+100 は計算せず固定 272。離陸後は 100 ft AGL まで V2、すぐ SPD RESTR へ。ACCEL HT とフラップ格納中の「プラカード −5 kt」が無い（フラップ位置ごとの上限 `modFlapSpeed` で代用） | FCOM p.1255, p.1326, p.1328, p.667 | VS:37-39, VS:156-229, FMS:612-618 |
| FMC-10 | 挙動の誤り | 中 | S | 既定値：上昇 SPD RESTR 250/5000・降下 180/5000 が最初から入る（本来ダッシュ）。上昇 SPD TRANS、TRANS ALT（18,000 固定）、降下の制限速度を出発地・目的地の nav DB から取らない | FCOM p.1328–1329, p.1392, p.1396 | FMS:612-626 |
| FMC-11 | 挙動の誤り | 中 | M | CI を使うのは巡航 Mach の経験式だけ（LRC＝388+0.62·GW[t]+7.8·高度[kft] の千分率、CI 230＝LRC）。ECON 上昇・降下（.805/270）は固定、349/354 kt の上限なし。CI を入れると乗員の巡航速度入力が無視される。CRZ ページの ECON SPD は保存値で飛んでいる Mach と違う | FCOM p.1238, p.1258, p.1311, p.1348; FMSPG p.29, p.261–262 | VS:230-309, VPG:321 |
| FMC-12 | 挙動の誤り | 高 | L | E/D は「目的地 10 NM 以内の最初の点」、T/D は E/D から (CRZ ALT − 高度)/290 ft/NM。パスは 290 ft/NM かネイティブの高度間の直線。アイドルパス（速度・風・防氷）、T/D の水平減速と速度制限前の減速、RW+50 ft・VOR は MAP の E/D、巡航中の制限入力での E/D 生成が無い。EOD の高度に `fms[eod][3]` を使う（他所の高度は [9]。[3] の意味は未確認） | FCOM p.1258, p.1263–1264, p.1392; ATA34_2 p.563, p.610–611 | AP:2103-2109, AP:2161-2170, VN:48-72 |
| FMC-13 | 挙動の誤り | 高 | M | VNAV PTH 降下は「目標高度までの差 ÷ 時間」の V/S（−2,500〜+1,500 fpm）。パス許容（15/10 kt、上下 150 ft）、VNAV SPD への反転、THRUST REQUIRED が無い。DRAG REQUIRED は「MCP 速度 +10 kt 超で増速中・V/S 中・推力アイドル」の近似 | FCOM p.1258–1260, p.1431, p.1434; ATA34_2 p.615–616 | VN:16-124, MON:218-357, AP:3400-3413 |
| FMC-14 | 欠落 | 中 | M | 早期降下：T/D 50 NM 以内の MCP ノブで、約 1,250 fpm・THR → HOLD の VNAV SPD を経ずにパス追従へ入る。50 NM より手前の巡航降下が無い（元の CRZ ALT へ戻る、SPD TRANS/RESTR を消さない）。DES NOW と「最も高い降下制限より下」の条件が無い | FCOM p.1257, p.1260–1261, p.1389, p.1393; ATA34_2 p.623–624 | AP:660-716, MON:469-530 |
| FMC-15 | 欠落 | 中 | S | MCP 高度ノブで制限を 1 個ずつ消す機能、CHECK ALT TGT が無い。RESET MCP ALT は NM ÷ m/s の比較で T/D の約 1 分前に出る（本来 2 分） | FCOM p.649, p.665, p.1431, p.1433 | AP:660-716, MON:451-467 |
| FMC-16 | 欠落 | 高 | M | approach 段階・on approach（速度介入中も VNAV PTH、MCP を 300 ft 上でも降下継続）、GP 角の VNAV PTH、VFR 進入、ミスト進入（下の制限削除、最高高度を CRZ ALT、climb へ、400 ft RA 以上で作動）が無い。15 NM 未満は空港標点へ 290 ft/NM | FCOM p.1236, p.1261–1264, p.1405–1408 | AP:2161-2165 |
| FMC-17 | 挙動の誤り | 中 | M | 飛行段階を MCP のボタンで決める（FLCH/V/S は MCP と現高度の大小で climb/descent、ALT HOLD で cruise）。T/C・T/D・approach・flight complete（停止 30 s 後の消去）の論理が無く、VNAV ページの ACT 表示もこれに従う | FCOM p.1235–1236, p.1325 | AP:591-595, AP:751-755, AP:781-785, AP:822, MON:380-414, VPG:157 |
| FMC-18 | 挙動の誤り | 中 | S | VNAV の作動条件は CRZ ALT と、地上で T/D まで 10 NM 未満かだけ（GW・CI・active route・降下時の E/D を見ない）。終点が空港でない経路では LNAV/VNAV を切り、Boeing に無い DESTINATION NOT SET を出す | FCOM p.645, p.1433; ATA34_2 p.620–621; FMSPG p.30 | AP:1020-1057, AP:2376-2384, NOTI:56 |
| FMC-19 | 挙動の誤り | 中 | M | OPT/MAX は GW の一次式（速度モード・温度・残余上昇率・CRZ CG・エンジン数なし）。STEP TO は常に CRZ+2,000 ft（STEP SIZE・ICAO 無視）、ステップ点は MAX から逆算、予測に入らない。MAX ALT・LIMIT ALT・UNABLE CRZ ALT が無い | FCOM p.1257, p.1311–1312, p.1348–1350, p.1433–1436, PI p.316–317; ATA34_2 p.611 | VPG:190-256 |
| FMC-20 | 欠落 | 高 | L | 軌跡予測が無い。PROGRESS の燃料は現在の FF × 時間、CRZ の目的地燃料・ETA は 51.6 lb/NM などの経験式で、風・ステップ・降下・制限を考えない。RTE DATA も無い | FCOM p.1274, p.1349, p.1360–1363, p.1372–1373; ATA34_2 p.610–611 | PRG:64-119, VPG:258-310 |
| FMC-21 | バグ | 中 | S | ETA の速度下限が `275 * 1.944`（534.6 kt）で、GS がそれ未満なら ETA が早すぎる（ND の ETA、PROGRESS、燃料予測）。T/C 距離も `250 * 1.944`（486 kt）を下限にする | FCOM p.1372–1373 | FMS:870-872, PRG:74-82, AP:2022-2025 |
| FMC-22 | 欠落 | 中 | M | CALCULATED が無い（TOTALIZER と CALCULATED の両方がタンク合計）。MANUAL/SENSED、FUEL DISAGREE、USE の選択、INSUFFICIENT FUEL（RESERVES は入力できるが未使用）が無い | FCOM p.1273–1274, p.1310–1311, p.1378–1382, p.1432; ATA34_2 p.531, p.569 | PRG:146-150, PRG:189, PINIT:22 |
| FMC-23 | 挙動の誤り | 中 | S | ACF_DIFF §3.2・§4-4：予測は X-Plane の FF（acf の `_jet_SFC_*` で決まる）を直接使うので、カスタム（巡航 0.25/0.38）と純正（0.313/0.571）で予測が変わる。コードは acf 値に依存する | ACF_DIFF §3.2; ATA-28.md; FCOM p.1274 | FMS:13, PRG:64-118, VPG:230, VPG:287 |
| FMC-24 | 挙動の誤り | 低 | S | 性能の GW はシムの真の総重量。乗員の ZFW・GW 入力が VNAV と予測に効かない | FCOM p.1309–1310; ATA34_2 p.609 | PINIT:18-30, VS:241, VPG:190 |
| FMC-25 | 欠落 | 中 | M | 点ごとの風（4 高度）、伝搬・補間・計測風との混合、DESCENT FORECAST（TRANS LVL、TAI ON 高度）が無い（ページも読み込まれていない） | FCOM p.1364–1366, p.1395–1397; FMSPG p.228–233 | PG:279-309 |
| FMC-26 | 欠落 | 中 | L | E/O の VNAV（V2+10 維持、VREF+100、E/O CLB/CRZ・E/O SPD・E/O MAX ALT、LRC driftdown 最小 300 fpm、2E/O）が無い。ENG OUT> は表示だけ | FCOM p.1265–1269, p.1341–1342, p.1350–1353 | VPG:172, VPG:328 |
| FMC-27 | 欠落 | 低 | M | RTA（109/405）が無い（ページは固定文字） | FCOM p.1269, p.1354, p.1383–1385 | PRG:193-212 |
| FMC-28 | 欠落 | 中 | M | FMC 位置はシムの真値。IRS は真値＋整列時の固定乱数（±0.001°）でドリフトなし。GPS/無線/LOC 更新、IRS 混合・棄却、ANP、RNP、GPS INHIBIT、PURGE、TO/GA 更新、split IRS、VERIFY POSITION が無い。ND の更新モードは IRS の整列状態だけ | FCOM p.1240–1245, p.1367–1370; ATA34_2 p.517, p.601–602, p.606; FMSPG p.25–28 | IRS:29-63, IRS:178-190, FMS:253-254 |
| FMC-29 | 挙動の誤り | 高 | S | UNABLE RNP：目的地 40 NM 以内で LNAV のクロストラック > 1 NM（APP 中 0.3 NM）なら caution、40 NM を出ても消さない。ANP と RNP の比較でなく、approach 以外は advisory のはず。ベクター中に誤警報 | FCOM p.1430; LH3460 p.116 | AP:2220-2232 |
| FMC-30 | 挙動の誤り | 中 | M | VOR の自動同調は 10 s ごとに最寄りの VOR 2 局を入れるだけ。P/R 同調、DME-DME の組（30–150°/90°）、局の禁止、手動との関係、VOR 進入の同調が無い。2 番目の局の選び方にバグ（最寄り更新時の旧値しか入らない） | FCOM p.1240, p.1303–1304, p.1355–1357; ATA34_2 p.605–606; FMSPG p.26–27 | RNAV:24-89, RNAV:65-70 |
| FMC-31 | 挙動の誤り | 中 | M | ILS は目的地 45 NM 以内で、経路点と近くの ILS の幾何から推定して同調（選んだ進入と無関係）。PARK → 小文字 → A の距離条件は NAV RAD の表示だけ、離陸後 10 分と FCC の禁止、ILS TUNE INHIBITED、RW/ILS FREQ ERROR が無い。RW/ILS CRS ERROR を「ILS 未同調で APP/LOC を押した」に流用 | FCOM p.1305–1307, p.1432, p.1434; ATA34_2 p.470, p.586 | AP:1621-1806, AP:2397-2402, AP:2430-2435, PG:428-453 |
| FMC-32 | 挙動の誤り | 中 | S | メッセージは 54 件の表のうち 6 件だけ（DRAG REQUIRED、ENTER IRS POSITION、PERF/VNAV UNAVAILABLE、RESET MCP ALT、RW/ILS CRS ERROR〔誤用〕、DESTINATION NOT SET〔Boeing に無い〕）。10 s ごとに 1 件、どれでも FMC MESSAGE。alert/advisory の区別、スタック、進入中 500 ft 未満の抑止が無い。ネイティブの NAV DATA OUT OF DATE を消す | FCOM p.1430–1436; ATA34_2 p.635–636 | FMS:1110-1136, NOTI:2-77, CRE:520 |
| FMC-33 | 挙動の誤り | 中 | S | VNAV 上昇中に TRANS ALT を越えると両 EFIS の気圧を STD・29.92 に自動で切り替える。FMC にこの機能は無い | FCOM p.1329 | VS:420-434 |
| FMC-34 | 欠落 | 中 | L | 経路管理（RTE 2、RTE COPY、ABEAM PTS、INTC CRS など）はネイティブ任せで、自前の FMC は経路を持たない。性能変更（CRZ ALT・速度）は MOD/EXEC を経ずに即時有効。オフセットは L/R 入力と平行線だけで、終了条件・END OF OFFSET・direct-to での解除が無い | FCOM p.1238, p.1287–1299, p.1333–1334, p.1431 | PG:96-177, PG:1124-1145, PG:1187-1209, MON:823-852, LEGS:1-52 |
| FMC-35 | 挙動の誤り | 中 | M | ND の経路線はネイティブの EFIS 地図が描き、機体は自前 LNAV の別の経路を飛ぶ（旋回・ホールドの見た目と実際が一致しない）。T/C・T/D の位置は自前計算 | ATA34_2 p.626; FCOM p.1251 | `747-400.acf:98958`, `747-400.acf:99872`, AP:2083-2101 |
| FMC-36 | 欠落 | 中 | L | 二重 FMC（master 選択、resync、単一 FMC 運用、FMC 故障時の FMC LEFT/RIGHT・TIMEOUT - RESELECT・LNAV/VNAV/A/T 喪失・ND の旗）と代替航法（IRS LEGS/PROGRESS、ALTN NAV RADIO）が無い。FMC master selector は X-Plane の AP 源を切り替えるだけ、代替航法のページは読み込まれていない | FCOM p.1275, p.1421–1428; ATA34_2 p.456, p.468, p.496, p.589–592, p.629–632 | `B747.60.xt.fltInst02.lua:660-664`, PG:279-309 |
| FMC-37 | 欠落 | 低 | S | CPCS へ着陸高度（到着ページの切替点で目的地・進入の値）を送らない。CPCS は 2,000 ft の既定値。ATA-21.md と対 | FCOM p.1400; ATA34_2 p.477 | `B747.55.xt.air.lua:881` |
| FMC-38 | バグ | 低 | S | PROGRESS 2 の XTK は常に "L"（符号なしの値）、VTK ERROR は "+**FT" 固定 | FCOM p.1377–1378 | PRG:175-181, AP:2292 |
| FMC-39 | 欠落 | 低 | S | nav DB の 2 サイクル切替・失効の扱い、ROUTE FULL（120 点）が無い | FCOM p.1250, p.1271, p.1284, p.1435 | CRE:520 |
| FMC-40 | バグ | 中 | S | AP が毎フレーム `xtlua/fms` の JSON を decode し `collectgarbage("collect")` を呼ぶ。FMS の ETA 表示と VNAV ページも毎回 decode | ARCHITECTURE.md §1 | AP:3504, AP:3535, FMS:936, VPG:69 |

件数：高 13（01, 02, 03, 04, 06, 07, 08, 09, 12, 13, 16, 20, 29）、中 22、低 5。合計 40。

## 8. 作り直しか部分修正か

- 推奨：**作り直し**。FMC の航法・経路・LNAV・VNAV・性能の中核を新しいモジュールにする。CDU ページの体裁は CDU 担当の作業と合わせる。
- 理由
  1. 経路モデルが無い（FMC-01）ので、ホールド、制限、速度制限、E/D、進入、オフセット、メッセージのほぼ全部の土台が無い。部分修正は「ネイティブの点列に推測を足す」方向にしか進めない。旧フォークは 33,000 行規模の修正で CIFP の読込みまで足したが、FCOM の挙動には届いていない（OLD_FORK_NOTES.md 冒頭・§4–8。参照のみ）。
  2. LNAV/VNAV が AFDS のモジュール（MON）の中で X-Plane の HDG SEL・FLCH・V/S・ALT HOLD を切り替える状態機械になり、FMC の段階・目標と AFDS のモードが混ざっている（FMC-17）。ATA 22 の作り直しと同時に「FMC → FCC の誘導指令」の境界を作るほうが安全。
  3. 数値の大半が資料に根拠の無い経験式（290 ft/NM、GW の一次式、51.6 lb/NM、534 kt など）で、個別に直しても全体の整合が取れない。
- 構成案（推定）：nav DB 読込み（X-Plane のデータファイル・CIFP）→ 経路モデル（RTE 1/2、ACT/MOD/EXEC、discontinuity、ホールド、オフセット、制限）→ 経路形状（脚種別、fly-by/fly-over、旋回半径）→ LNAV（捕捉、シーケンス、ロール指令）→ 性能 DB（FCOM PI の表）→ 軌跡予測（上昇・巡航・アイドル降下・減速・風）→ VNAV（モード、目標、許容、メッセージ）→ 航法センサー（位置・ANP/RNP・同調）→ メッセージ管理。ネイティブ FMS は ND の線のためだけに使うか、使わない（§6.1 の B）。
- 進め方：①先に入れてよい小修正（S）＝FMC-21、FMC-09 の速度の取り違え、FMC-10、FMC-33、FMC-29、FMC-30 の 2 番目の局、FMC-15 の RESET MCP ALT、FMC-40。②経路モデルと LNAV（ホールド・オフセット・メッセージを含む）。③性能 DB・軌跡予測・VNAV。④燃料監視・無線同調・二重系・代替航法。
- 残す名前：INTERFACES.tsv の `laminar/B747/fms1〜3/*`（行とキー）、`nd/current_waypoint`・`waypoint_distance`・`waypoint_eta`・`gs_tas_line*`・`range_display_*`・`wind_line`・`wind_bearing`・`toc/*`、`irs/gps_display_line`・`irs_display_line`・`irs/line1〜4`、`autopilot/dist/flight_path_error`、`autopilot/vnav/after_tod`、`autopilot/ils_dots`、`autopilot/button_switch/LNAV`・`VNAV`、`flt_inst/fmc_master_src/ctr_pnl/*`、FMA 系（ATA 22 と共通）。内部の `laminar/B747/fms/data`（EEC・FDR が読む）、`autopilot/dist/*`（ND が読む）、`fms/notification` は互換で残すか、読む側を同時に直す。

## 9. 未確認事項

- `xtlua/fms` の要素の意味（[1][3][4][7]）、discontinuity・ホールド・条件点（"(1000)"、"VECTOR"）がどう入るか、at or above・at or below・窓がどの高度値で来るか（旧フォークは「上昇の at-or-below は 0」と記録。参照のみ）、点数の上限。XTLua のソースか実機で確かめる。
- XP 12.4 の SDK に脚種別・制限種別を読む API があるか（XTLua が使うのは旧 API だけ）。ネイティブの EFIS 地図がホールド・arc・オフセットを描くか。
- `sim/flightmodel/position/magnetic_variation` の符号と、コードが真方位に加算していること（MON:860, PG:390）の整合。
- ACF_DIFF §3.3（`_ott_*` など）が X-Plane の FD ロール、つまり今の LNAV の旋回にどれだけ効くか。
- 資料の食い違い（採った方）：RNP 既定値（ATA34_2 p.517：1.0/12.0/2.0/1.0/0.5、FMSPG p.25：12.0/2.8/1.7/0.5 → ATA）、真方位への切替範囲（FCOM p.1242：82° 等、ATA34_2 p.577・FMSPG p.219：73°N/60°S → FCOM）、ILS が A になる距離（FCOM p.1307：150 NM、ATA34_2 p.586：200 NM → FCOM）、FUEL DISAGREE（FCOM：4,080 kg、ATA34_2 p.569：9,000 lb が 5 分 → 量は FCOM、持続時間は要判断）、ND の VNAV 目盛（FCOM ±400 ft、ATA ±420 ft → FCOM）、電源断後の性能データ（FCOM p.1274：再入力、FMSPG p.23：完全復帰 → FCOM）、到着ページの切替（FCOM p.1400 と ATA34_2 p.527 → FCOM）。
- 資料に記載なし：fly-by/fly-over の扱い、通常の旋回のバンクと旋回開始点、ANP の計算式、ECON 速度の CI 依存（FCOM PI に表が無い）、最小機動速度の作り方、VNAV の推力目標の値、CDU と電源 bus の対応、DME-DME の更新式。
- 実機で見ること：ネイティブで STAR・進入を選んだときの `xtlua/fms` の中身、ND の ETA（534 kt の影響）、ベクター中の UNABLE RNP、VNAV 上昇の速度（250/272）、ネイティブの HOLD を入れたときの LNAV の動き。
- 乗員応答監視（PILOT RESPONSE）は APF のオプション（ATA34_2 p.480）。入れるかはユーザーの判断。
