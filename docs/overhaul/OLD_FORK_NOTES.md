# 旧フォーク（Gakugaku87/747-400）変更メモ

> **参照専用。** ここにある挙動・数値・コードは一切移植しない。再構築では Boeing/Honeywell のマニュアルから挙動を導き直す。

- 対象: 旧フォーク Gakugaku87/747-400 が上流 mSparks43/747-400 に加えた変更の要約（overhaul 再構築の参考用）。
- 範囲: 分岐点 `e6107a52`（2026-06-16）〜 `archive/old-master` = `45cce506`（2026-10-21）。369 コミット（非マージ 339）、PR #1〜#33 は全てマージ済み。
- P1〜P4 は 2026-10 の飛行試験由来の PR #26〜#29（積み上げ PR の #27〜#29 は #30 で master 入り）。PR #31 だけで 256 コミット、#31〜#33 は PR 本文なし。
- 規模: 129 ファイル、+33,351 / −983 行（約半分は `tests/`）。
- 上流の分岐後 4 コミット（2285a665, 05111a99, 5e1287a9, 041c9ffa）は旧フォークに無い。`overhaul` は upstream/master（041c9ffa）基点で旧フォークを含まない。
- `plugins/xtlua_keysystems/` は分岐点で既に上流に存在する。旧フォークは新設ではなく、その中でのファイル追加・改変。
- 「結果」はコミットメッセージ・PR 本文・`tests/README.md` だけを根拠にした。記述がなければ「不明」。
- 検証の質: #1〜#25 は X-Plane 飛行確認なし（多くの PR 本文に明記、残りは記載なし）。#26 以降は X-Plane 12.4.4 と外部の flight-test kit の記録（EINN 周回、EIDW–EHAM 路線、EINN の試験ルート TST744L）を引用。
- 最後に引用される飛行は p39-line1。#32/#33 適用後の飛行確認は不明。
- リポジトリ外の参照: flight-test kit とその記録、`NEXT_747_FIXES.md`（i-1b, B-xx 等の項目番号）、cckit の `research_*.md`、コミット中の「review N」の中身。

## 1. AFDS ピッチ（FD ピッチ指令: FLCH/VNAV SPD・ALT・V/S・TO/GA）
- 狙い: モード切替時の不感時間と段差、上昇中の速度補正による降下転換、ALT 捕捉/保持の不具合、上昇加速の不足、TO/GA が姿勢指令、手動飛行時に FD が無効 — の解消。
- 結果:
  - 0.70 s 線形ブレンド（#4）、上昇/降下の向きを越えない速度オンピッチ（#7）、古い FMA を見た ALT 捕捉競合の修正と ALT HOLD の V/S 制限 ±2,000 fpm（P1）。
  - 重度低速判定に使う最低安全速度を target−5 kt で頭打ち、上がった速度目標への加速ラッチ、FMA NONE 中は姿勢保持、上昇中の沈下回復を VSI でなく AoA 基準に（P3/P4）。
  - FLCH/VNAV SPD を「加速度誤差→飛行経路→ピッチ」の則（0.1 g 制限）に置換。推力変化のフィードフォワードは 4 発が揃うときだけ（#31）。
  - V/S・VNAV PTH・G/S・ALT のピッチ下限を −3.5°→−10°、速度モードの上限 25°。ALT/V/S へ移る際は上限まで 0.1 g で下げる（#31）。
  - TO/GA は空中で TO/GA 速度（V2+10 起点、上限 V2+25、GA は窓速度）をピッチで追い、MCP 高度に関係なく上昇。捕捉は 50 ft 超上の MCP 高度のみ、地上では捕捉しない（#31）。
  - サーボ OFF でも FD が誘導を出す（従来は姿勢に張り付き）、TO/GA バーの地上待機を 2°/s に（#33）。
  - 未解決: 旋回中に始まるステップで VNAV SPD 作動前に約 370 fpm・3 s 沈下（PR #29、以後の対処は不明）。AP ピッチループの初回 45% 行き過ぎが残る（4fee2ee7）。
- 根拠: 大半はキット記録に当てた点質量・姿勢ループのモデルで調整。TO/GA 速度は FCOM vol 2 の孫引き（Aerowinx フォーラム経由）、上昇再開の挙動は ADS-B。
- 主なファイル: `B747.19.xt.hydraulics_override.lua`, `B747.19.xt.hydraulics_afds_helpers.lua`, `B747.19.xt.hydraulicsmodel.lua`, `B747.70.xt.autopilot.lua`
- 関連PR: #4, #7, #26〜#29（P1〜P4）, #31, #33

## 2. AFDS ロール・MCP 操作・モード表示
- 狙い: ロール指令の遅れ（長い移動平均）、LNAV 旋回で 7°/s 超のロール、高 TAS でのロール発散、TO/GA ロール表示の残留、MCP ノブ押しの取りこぼし、高度ダイヤル中の AFDS 停止 — の解消。
- 結果:
  - 適応型ロールフィルタ（#4）→ 進入以外は 3°/s 上限、進入は 8°/s（#31）。ロール PID ゲインを TAS 340 kt 超で 340/TAS 倍（下限 0.7）、D ゲインは 0.05 固定（#31）。
  - HDG SEL/HDG HOLD/LNAV で TO/GA ロール表示を消す（P3）。ノブ押しは毎回作動し、VR の "use" は押下を保持する（P4）。
  - MCP 高度ノブは lastCommand を書かず、VNAV は 1.5 s 静止した値だけを水平目標にする。LNAV は 0.5 s 保留なしで毎フレーム方位を指令（#31）。
  - 未解決: ロールモデル上の余裕は舵面効き 120°/s 付近・18〜20 fps で尽きる（6645c307）。X-Plane での再確認は不明。
- 根拠: キット記録（方位変更試験、p33-line1 のロール発散）に当てたモデル。FCOM の引用なし。
- 主なファイル: `B747.19.xt.hydraulics_override.lua`, `B747.19.xt.hydraulicsmodel.lua`, `B747.70.xt.autopilot.lua`, `B747.99.VRcontrols.lua`
- 関連PR: #4, #28, #29, #31

## 3. A/T・EEC 推力
- 狙い: CLB が定格でなく EEC 独自抗力モデルの「設計上昇率分」、離陸推力の設定に 30〜40 s、空中の上昇推力が 4〜6 s で入り速度超過、最大 EPR が基準モードで変わる、フレア中の IDLE で推力が戻る — の解消。
- 結果:
  - CLB を全高度・重量・フラップで定格上昇推力に（PW/RR の FL200 以上は P4 で先行）。CLB 1/2 は 10,000 ft まで −10/−20%、15,000 ft までに戻す（#31）。
  - PW の最大上昇 EPR は FCOM の Max Climb 表から、低速域は Initial Climb 表から（表の誤記 1.7→1.47 も修正）。GE の CLB 1/2 は EEC の N1 モデル経由（#31）。
  - 離陸推力は TO/GA から約 5〜8 s（従来 30〜40 s、フレームレート非依存、レバー位置から開始）。空中の CLB/CRZ への増加は 0.025/s・最初の 10 s は 40% から（VNAV SPD/FLCH SPD のみ、GA は従来どおり）。
  - PW の最大 EPR（EICAS 線・レバー前端）は飛行中 GA 定格に固定（#31）。オートランド 50 ft 以下の IDLE は低速 SPD ループなしで約 2 s でアイドル、全発逆噴射は 0.5 s 以上保持して離すと逆噴射アイドル（P3）。
  - 未解決: GE/RR の最大 EPR は未変更。PW の EPR 表示モデルは推力に対し実機の半分しか動かない（fcd4ef28）。744 の A/T レバー速度を示す資料はない（a648c3d3）。
- 根拠: FCOM（Max Climb/Initial Climb EPR 表、CLB 1/2 の 10/20%）、Boeing 747-400 E&M ATA 34-61。レバー速度は ADS-B とキット記録。
- 主なファイル: `B747.42.xt.EEC.lua`, `B747.42.xt.EEC.PW.lua`, `B747.42.xt.EEC.GE.lua`, `B747.42.xt.EEC.RR.lua`, `B747.42.xt.EEC.tbls.lua`, `B747.40.xt.engines.lua`
- 関連PR: #9, #28, #29, #31

## 4. VNAV 上昇・巡航
- 狙い: 初期上昇の速度切替が約 100 ft AGL、clbspd/transpd の意味の取り違え（ECON 250・SPD TRANS 272）、ECON 固定 272 kt、上昇 Mach の選択誤り、SID の高度・速度制限の無視 — の解消。
- 結果:
  - 加速/推力減少高度は 100 KIAS 時の出発気圧高度基準（RA でない、到達は保持）、初期目標 V2+10〜V2+25（#21/#22）。地上の VNAV 押しは ARM のみ、400 ft RA まで VNAV ALT を捕捉しない（P1）。
  - SPD REST（既定空白）→ SPD TRANS 250/10000 → ECON。ECON CAS は T/C 重量・CI・風・ISA から 251〜349 kt（データなしは 340/.84）、上昇 Mach = T/C 条件の ECON 巡航 Mach、風は 60 s 遅れ（#11/#24/#25）。
  - CAS/Mach 切替は CAS 目標の現高度での Mach で判定（0.005 のヒステリシス）し、速度目標は新しい単位で同時に書く（P3）。速度の再計算はイベント駆動（#4）。
  - 巡航フェーズを持ち、ステップ上昇は巡航 Mach で飛ぶ（#31）。ALT セレクターで VNAV 上昇中・VNAV ALT・巡航中に CRZ ALT を MCP 値へ（#13/#23）。
  - CIFP の SID 天井で上昇を水平にし、速度制限で CAS/Mach を頭打ち（フラップ機動速度未満にはしない）。SPD REST/TRANS は CLB 速度との min として扱う（#31）。
  - 未解決: エンジン故障時の初期上昇 V2〜V2+15 は無し、VNAV 上昇中の ALT 押しで次の高度制限を消す機能も無し（PR #23）。
  - 未解決: ECON CAS と LRC/MRC 巡航 Mach 曲線は未校正の近似、CI 補間は線形（CI 90 で約 .015 低い、PR #25）。
- 根拠: FCOM（D6-30151-400、2009）4.20.9、FCTM Climb/Cruise 4.3〜4.4、FCOM p.1577 の LRC 表の回帰式、Boeing AERO（CI 230≒LRC）、`documentation/fms pages/fmcs/` の CDU 転記。
- 主なファイル: `B747.70.xt.autopilot.vnavspd.lua`, `B747.70.xt.autopilot.monitor.lua`, `B747.70.xt.autopilot.takeoff.lua`（新）, `B747.70.xt.autopilot.lua`, `B744.fms.performance.lua`（新）
- 関連PR: #1, #2, #4, #8, #11, #21〜#25, #26〜#29（P1〜P4）, #31

## 5. VNAV 降下・パス
- 狙い: T/D が降下制限を見ない、周回ルートやミスト進入のベクターで EOD が狂う、パス上空で推力が出る、A/T の IDLE/SPD 反復、各ポイントで水平になる、旋回でパスに段差 — の解消。
- 結果:
  - EOD は到着滑走路で打ち切り（ミスト進入の遠いベクター点を除外）、T/D は各降下制限と EOD 高度を 290 ft/nm で満たす最も手前（P1/P2）。
  - 降下パスの起点を常に T/D に（#32。従来は出発空港の標高が起点を奪い、全路線で T/D 直後に DRAG REQUIRED）。
  - VNAV PTH のエネルギー管理（パス上下×速度過不足の 4 象限、DRAG REQUIRED、#9）。降下目標はフラップ制限 −5 kt で頭打ち（#23）、スピードブレーキ展開中は推力なし（P3）。
  - 低速時の推力は目標 +2 kt・レバーアイドル・X-Plane の N1 下げ止まりまで保持。A/T FMA は IDLE→HOLD→SPD で、HOLD 中はパイロットのレバーを動かさない（#31）。
  - パスは CIFP 制約を通して引き、VNAV PTH の水平目標は MCP 高度のみ。VNAV SPD は制約の床で水平、MCP を機体より上にすると VNAV ALT、ALT 押し直後に降下再開（#31）。
  - 旋回の二等分線まで固定点の高度を保持し、LNAV の旋回を VNAV に渡してパスを連続化（段差は 2 nm で吸収）。STAR 速度制限は 0.5 kt/s 減速で手前から（#31）。
  - 未解決: T/D は減速と風を考慮しない（bba159bf）。T/D 後に古い CRZ ALT が残る経路では T/D の起点がずれる（c701d907）。
- 根拠: FCOM 4.10.5/4.10.7/4.20.7 を一部で引用。数値の大半は EIDW–EHAM 路線記録（p20〜p39）と進入モデルの閉ループ。
- 主なファイル: `B747.70.xt.autopilot.vnav.lua`, `B747.70.xt.autopilot.lua`, `B747.70.xt.autopilot.monitor.lua`, `B747.70.xt.autopilot.afds_helpers.lua`
- 関連PR: #9, #22, #23, #26〜#29（P1〜P4）, #31, #32

## 6. CIFP 制約の読込（新モジュール）
- 狙い: ネイティブ FMS から届く経路は各点 1 高度だけ（上昇の at-or-below は 0、速度なし）で、SID/STAR/進入の制限を守れない。
- 結果:
  - 出発/到着空港の CIFP（Custom Data 優先）を数行/フレームで読み、経路の識別子から SID/STAR/進入を特定し、経路インデックスごとに種類・床・天井・速度を保持（LFPG で 2 ms/フレーム）。
  - SID 天井・STAR 床・速度制限・最終進入角・降下パスに使う。FMC も同じ CIFP の滑走路端標高を APPROACH REF に使う。
  - 未解決: 実データでの検証は EIDW/EHAM/EINN のみ（`XPLANE_ROOT` 指定時）。他空港での妥当性は不明。
- 根拠: X-Plane の CIFP 形式とネイティブ FMS の挙動に合わせた実装（マニュアル引用なし）。
- 主なファイル: `B747.70.xt.autopilot.constraints.lua`（新）, `B747.70.xt.autopilot.lua`, init `B747.70.autopilot.lua`
- 関連PR: #31

## 7. 進入・G/S・オートランド
- 狙い: 遠ざかりながらの LOC 捕捉、LOC と同時の G/S 捕捉、1,000 ft 高いまま偽 G/S ローブを捕捉して約 9 km 先に接地、進入で A/T が切れる、フレアで浮いて −450〜−550 fpm で接地 — の解消。
- 結果:
  - LOC は両受信機・切込み 90° 以下・2 dot 以内で接近中（または 1 dot 以内で安定）のみ。G/S は LOC 後 0.5 s 以上かつ両方 1.5 dot 以内。APP は MCP 方位を変えず、LOC ARM 中も LNAV が誘導（P2）。
  - 滑走路まで 25 nm（27 nm まで保持）は VNAV PTH が TCH と CIFP の進入角（なければ 3.0°）のパスを飛び、速度はフラップ制限 −2 kt 内、A/T は SPD を維持（#31）。
  - G/S の偏差補正を dot でなく ft 換算に、G/S を経路角の PI 則に（#31）。フレアは沈下率指令（43 ft 開始、local_vy 使用）、接地後 1°/s のデローテーション、25 ft でリタード（P3）。
  - 周回で接地 −206/−225 fpm・浮きなし（PR #28）。進入モデルでは EHAM/EINN の全ケースで 1,000/500 ft に 0.75 dot 以内（モデル上のみ）。
  - 未解決: 重い路線機の接地率は −196〜−636 fpm とばらつき、調整せず（PR #28）。フレア則は当てはめモデルで調整しただけで検証ではない（28872db2）。LAND 2 は未変更。
- 根拠: キット記録（2026-10-10 周回、2026-10-16 路線）とそれに当てた点質量モデル。G/S・フレアの FCOM 引用なし。
- 主なファイル: `B747.autoland.lua`, `B747.70.xt.autopilot.monitor.lua`, `B747.70.xt.autopilot.vnav.lua`, `B747.19.xt.hydraulics_override.lua`, `B747.42.xt.EEC.lua`
- 関連PR: #27, #28, #31

## 8. LNAV
- 狙い: 旋回開始が遅く外へ膨らむ（BILTO 137° で 17 nm 等）、SID 最初の CA レグ "(650)" から抜けない、XTK が古いまま、経路誘導がない、LNAV を押すと 20 nm 離れていても即係合 — の解消。
- 結果:
  - 先行遷移に安全条件（多レグ飛ばし禁止など、#4）。高度終端レグ（CA/VA/FA）は高度到達かつ 400 ft RA 以上で遷移（P4）。旋回は HDG SEL のバンク限界・3°/s ロールイン・風から求めたリードで開始（#31）。
  - 経路誘導: 入航レグ・接線円弧・出航レグを純追跡で飛び（切込み最大 45°）、経路で飛ぶ旋回は二等分線で遷移。円弧半径は旋回中の最大対地速度で旋回開始時に固定、風は空気経路基準で 10 s 平滑（#31）。
  - 150° 超は 150° 旋回の開始点から飛ぶ上限つきフライバイ（ユーザー判断）。短レグの円弧共有、重複フィックス、400 ft 未満は円弧なし。XTK は毎フレーム符号付き、PROGRESS 2 に L/R（#31）。
  - LNAV ARM: 飛行中は ARM し、現行レグの線から 2.5 nm 以内か、90° 以内で向かう切込み旋回の開始点で係合。非係合中の FMC はアビーム（レグから 21 nm 以内）で遷移（#31）。
  - 未解決: 2.5 nm は Aerowinx PSX 準拠で「FCOM で要確認」。fly-over 指定の扱いは記述なし（経路 JSON に区別なし、PR #4）。経路誘導は p9〜p20 で飛行したが、最終版の飛行確認は不明。
- 根拠: 2026-10-11 の横方向記録に当てたモデルと、レビューのモデル掃引。非係合時のアビーム遷移は Honeywell 特許 US 7,024,287。
- 主なファイル: `B747.70.xt.autopilot.lua`, `B747.70.xt.autopilot.monitor.lua`, `B747.70.xt.autopilot.afds_helpers.lua`, `B744.fms.pages.progress.lua`
- 関連PR: #4, #29, #31

## 9. FMC/CDU ページ（PERF・TAKEOFF/APPROACH REF・CLB/CRZ/DES・LEGS・STEP・RTE）
- 狙い: 実機 CDU 転記（`documentation/fms pages/fmcs/*.txt`）との相違を埋め、計画ステップと EXEC の流れを足す。
- 結果:
  - TAKEOFF REF/THRUST LIM: ACCEL HT（既定 1500）、THR REDUCTION は高度（400〜9999、既定 1500）かフラップ（FLAPS 5/F5/5）。定格変更で TAKEOFF SPEEDS DELETED。
  - CLB は ECON/SEL SPD と CAS/Mach 対、題名 `ACT 230KT CLB`（#22 で KT を外し #23 で戻す）。CRZ は計算 ECON Mach、入力時は `ACT M.801 CRZ`、DELETE で ECON。SPD REST の既定は `---/-----`。
  - CRZ ALT: DELETE は INVALID DELETE、空押しでスクラッチパッドへ（#31）。ネイティブ FMS へは遷移高度以上を FLxxx で送り、拒否時は CRZ ALT SYNC FAULT（P2）。
  - STEP: STEP TO と S/C 予測は助言のみ（AT/NOW/AVAIL AT/NONE/TO T/D、T/D 200 NM 内は予測なし）。STEP SIZE 0 は計算最適ステップだけ止める。実行は MCP 高度＋ALT セレクター。
  - LEGS: `FLxxxS` 等で複数の計画ステップ、MOD RTE 1 LEGS・EXEC・ERASE、未受理ステップは NOW のまま保持、ネイティブの高度制限と MOD 題名は残す（#13〜#18, #21）。
  - APPROACH REF は VREF を四捨五入・FLAP/SPD 200 kt まで・目的地標高で 1 kt/4,000 ft 補正。RTE は FLT NO/CO ROUTE をラベルで解決。EXEC ランプはネイティブ＋計画ステップ MOD を合成（注意灯 [270]）。
  - 未解決: THR REDUCTION の既定値（FLAPS 5 か 1500）は資料間で食い違い（PR #23）。計画ステップは上昇のみで、ネイティブの下流予測は更新しない（tests/README）。
- 根拠: `documentation/fms pages/fmcs/` の CDU 転記（fmcs 1/6/9/10/11/12）と FCOM PI.10.2。
- 主なファイル: `B744.fms.pages.lua`, `B747.68.xt.fms.lua`, `B744.fms.step.lua`（新）, `B744.fms.performance.lua`（新）, `activepages/B744.fms.pages.*.lua`, `B744.createfms.lua`, `B747.90.xt.lighting.lua`, `Cockpit_Pedestal1.obj`, `fmod/*.snd`
- 関連PR: #1〜#3, #11〜#19, #21〜#24, #27, #31

## 10. 離着陸・失速速度（計器スクリプト）
- 狙い: V1/VR/V2 表に最小値がなく（233 t・F20・海面で 101/114/139、FCOM は 121/124/144）路線で 10 kt 早く回転、表の転記誤り、VREF と失速速度の補間・高度帯の誤り — の解消。
- 結果:
  - VMCG/VRMIN（PW4056、気圧高度・OAT、TO 1/TO 2）と V2 for VRMIN を適用、V1≤VR、整数 kt、V1 の風補正の符号を修正、表の範囲外は最寄り領域。
  - 表のセルを AOM ページどおりに修正（F10 領域 D の VR が 93〜111 kt、正しくは 156〜187 kt 等）。XTLua 名前空間で表が落ちる問題も修正（p32 で離陸フラップ入力時に停止していた）。
  - VREF30/25 は FCOM PI.10.2 の表を総重量だけで引く（従来は高度で段階変化）。失速速度は重量・高度を正しく補間（従来は 0〜2,000 ft 帯のみ）、表の誤字 2 か所。
  - 未解決: 標高補正は APPROACH REF の VREF のみで、計器側（フラップバグ・VNAV のフラップ速度・オートランド）は海面値のまま（bca0e003）。
- 根拠: FCOM PI.18.2/PI.10.10/PI.10.2。V1/VR/V2 表は上流からある PMDG 747-400 AOM（PW 4062）の写しで第三者資料。外部メモ research_vspeeds.md / research_vref.md。
- 主なファイル: `B747.60.xt.fltInst.lua`, `B747.60.xt.fltInst02.lua`, `B744.fms.pages.lua`, `activepages/B744.fms.pages.approach.lua`
- 関連PR: #31

## 11. ND
- 狙い: ステップ予測点の表示がない、PLN モードの見出し地点が更新されない。
- 結果:
  - 経路上の予測 S/C 地点に緑の S/C 記号（両 ND、MAP モードのみで T/C・T/D と同じ条件、#3）。
  - PLN の見出しは #20 で選択地点にしたが、#21 で FCOM 10.10.65〜68 に合わせアクティブ地点に戻した（左右別 dataref は互換用に残す）。
  - 未解決: S/C は MAP モードのみ（PR #23 で未評価として記載）。
- 主なファイル: `B747.61.xt.nd.lua`, `B744.fms.nd.lua`（新）, init `B747.68.fms.lua`
- 関連PR: #3, #20, #21

## 12. ヨーダンパー・操縦系（ロール PID は 2、ピッチ PID は 13）
- 狙い: 自前のヨーダンパーが 5° バンクで 2 つの則を切り替えて出力が跳ね、片方向にしか効かず、±19°・約 5 s のロール/ヨー振動が 62 分続いた（p9-L1）。
- 結果:
  - 単一の則: 安定軸ヨーレートから協調旋回分（g sinφ/TAS）を引き、2.72 s ウォッシュアウト・0.27 s 遅れ（X-Plane 側の 11 フレーム分を差引）、1.37°/(°/s)（フラップ時 2 倍）、各ダンパー ±4°。
  - 地上では出さない、NaN/inf で固まらない。ダッチロールモデルで 3 周期後の横滑りが 35% 未満（ダンパーなしでは 70% 超）。
  - 未解決: 地上で効くべきかは未決（990e4535）。747-100 の則にあるフラップ時のバンク項は採らず。X-Plane での再確認は不明。
- 根拠: NASA CR-2144（1972、Boeing D6-30643 由来の 747 シミュレーター則）Fig IX-4、FAA NPRM FAA-2011-0571（±4°）。速度非依存と作用位置はモデル側の解釈（febaed7d）。
- 主なファイル: `B747.19.xt.hydraulics_override.lua`, `B747.19.xt.hydraulics_afds_helpers.lua`, `B747.19.xt.hydraulicsmodel.lua`
- 関連PR: #31

## 13. hydraulics 側の AFDS 補助と制御ループ（構造メモ）
- 狙い: FD 指令・AP サーボ PID・ヨーダンパーが hydraulics スクリプトで動く構造のまま、テストできる純関数に切り出す。
- 結果:
  - `B747.19.xt.hydraulics_afds_helpers.lua`（#4 で新設）に速度オンピッチ制限、ALT 捕捉/保持目標、飛行経路則、G/S PI、TO/GA 目標速度、推力リード、ヨーダンパー則を集約。航法側は `B747.70.xt.autopilot.afds_helpers.lua`。
  - hydraulics の FD ピッチは autopilot の FMA 更新より先に走り、1 回分古い FMA を見る（P1 の捕捉競合の原因）。
  - 名前空間がスクリプトごとのため、hydraulics から書く autopilot の dataref（vvi_status, speed_status）が未結合で書込みが消えていた（P1）。
  - AP ピッチ PID はサーボ ON 後 2 s 適用されず積分が巻き上がっていた → 保持（P4）。D=0.07、オートランドはフレア則を調整した 0.0002 のまま。
  - 注: テストは本番コードを目印コメント間で切り出して読むため、このファイル構成に強く依存する。
- 主なファイル: `B747.19.xt.hydraulics_override.lua`, `B747.19.xt.hydraulics_afds_helpers.lua`（新）, `B747.19.xt.hydraulicsmodel.lua`
- 関連PR: #4, #6, #26, #29, #31

## 14. XTLua の読込・実行時の挙動
- 狙い: XTLua 固有の挙動でスクリプトが止まる、または誤った値を読む問題の解消。
- 結果（判明した性質と対処）:
  - 独自 `dofile` が戻り値を捨てていた → `return chunk()`（#6）。ヘルパーが nil になり MCP・BARO・MINS・ND ノブが効かなかった。
  - チャンク間で local は見えない → 使う側のチャンクでヘルパーを読む（#10）。autopilot の読込が止まり MCP ハンドラが未登録だった。
  - モジュール内で最初の dataref 読みは 0 → 要所の dataref を毎フレーム読む（"warm reads"、P2 以降）。
  - メタテーブルなしのグローバル表は名前空間にコピーされ、欠けた添字の読みでスタック溢れ・`#` は 0 → `setmetatable` を付ける（p32 で計器・FMC・AP が停止）。
  - xt autopilot の `deferred_dataref` は `find_dataref` 相当で、init スクリプトで作らないと存在しない（#31）。
  - 1 回発火のコマンドには終了フェーズが届かない（P4）。XTLua 2.4.6 は同フレームの書込みを即読み返す（95f2bdb2）。Web API は XTLua の double への小数を HTTP 400 で拒否（4fee2ee7）。
- 主なファイル: `plugins/xtlua_keysystems/init.lua`, init `B747.70.autopilot.lua`, init `B747.68.fms.lua`, `B747.70.xt.autopilot.lua`, `B747.70.xt.autopilot.monitor.lua`, `B747.60.xt.fltInst.lua`
- 関連PR: #6, #10, #27〜#29（P2〜P4）, #31

## 15. FlyWithLua 自動ステップクライム
- 狙い: 機体は助言のみ（#3）のまま、乗員の MCP 操作を外部スクリプトで代行する。
- 結果:
  - `laminar/B747/fms/data` の STEP TO/STEP ALT と `stepdistance` を監視し、将来の S/C を一度見て ARM、0.5 NM 手前か NOW で MCP 高度を設定、0.35 s 後に実際の ALT セレクターコマンドを出し、巡航高度の受理を確認（#5）。
  - #21 で受理条件（高度保持成立・巡航高度 ±500 ft）に合わせ、受理確認まで実行済みにしない。NOW でロードしても即上昇しない、乗員の MCP 変更で中止。
  - 未解決: X-Plane での動作は #5 時点で未確認、以後も不明。b113c46f は「押下を保持して後フレームで離す」と書くが、リポジトリ版は `command_once` を使う（食い違い）。
- 主なファイル: `FlyWithLua/B747_Auto_Step_Climb.lua`, `FlyWithLua/README.md`（日本語）
- 関連PR: #5, #21

## 16. オフラインテスト（`tests/`、LuaJIT）
- 内容: `*_test.lua` 76 本、本番コードを点質量等で回すモデル 4 本（approach/climb/mcp_alt_dial/roll）、キット記録 CSV 4 本（`tests/data/`）。リポジトリ直下から `luajit`（または `lua5.1`）で 1 本ずつ実行、X-Plane 不要。
- 方式: 本番 Lua を `dofile` か目印コメント間の切出しで読み、dataref・コマンド・タイマーをモック。一部は XTLua の名前空間内で実行し、`XPLANE_ROOT` 指定時は実 CIFP も確認。
- 範囲: 離陸プロファイル、FMC ページ、CRZ ALT 同期、離着陸・失速速度、AFDS 各モード、A/T・EEC、VNAV（上昇/降下/進入/旋回パス/CIFP）、LNAV、ヨーダンパー、逆噴射、XTLua の読込・warm reads・表。
- 状態: 最後の「全スイート通過」の記述は 63 本（2026-10-20）で、45cce506 での全通過は不明。README 自身が「ロジックと界面の検証のみ」とし、X-Plane で飛ぶべき 16 シナリオを残している。
- 旧フォークの関数名・ファイル構成・切出し目印を前提にしたテストなので、上流ベースの `overhaul`（`tests/` なし）には持ち込んでいない。参照用に `tests_old/` に置いてある（git 管理外）。流用する仕組みは TESTING.md にまとめた。

## 新規 dataref・コマンド（名前のみ。残すかは再構築で判断）
- dataref: `laminar/B747/fms/exec_light`, `laminar/B747/fms/crzalt_sync_fault`, `laminar/B747/nd/current_waypoint_capt`, `laminar/B747/nd/current_waypoint_fo`
- dataref: `laminar/B747/autopilot/lnav/vnav_hold_index`, `laminar/B747/autopilot/vnav/procedures`, `laminar/B747/autopilot/vnav/constraint_speed`
- dataref: `laminar/B747/autopilot/vnav/energy_active`, `…/energy_state`, `…/energy_thrust_policy`, `…/energy_thrust_reason`, `…/energy_path_trend_fpm`, `…/energy_target_vspeed_fpm`, `…/energy_drag_required`
- 拡張: `laminar/B747/annunciator/brightness_ratio` を 271 要素に（[270] = FMC EXEC）。EXEC の音・Pedestal OBJ・ACARS は `sim/cockpit2/radios/indicators/fms_exec_light_*` から付け替え。
- `laminar/B747/fms/data`（JSON）の新キー: `accelht`, `thrredht`, `thrredflap`, `clbmach`, `clbspdmode`, `crzspdmode`, `stepto`, `stepatwpt`, `plannedsteps`, `modplannedsteps`, `stepmodactive`, `stepdistance`
- 同 JSON の既定値変更: `clbspd` 250→340、`transpd` 272→250、SPD REST の 4 キー（`clbrestspd/alt`, `desrestspd/alt`）はダッシュ（`---/-----`）。
- コマンド: `FlyWithLua/B747_Auto_Step_Climb/enable`, `/disable`, `/toggle`（FWL のみ。機体側の新コマンドは差分に無い）

## リモートブランチ
- `origin/agent/*` 20 本、`origin/claude/*` 2 本、`origin/fix/*` 7 本。うち 26 本は `archive/old-master` に含まれる。
- `origin/fix/p1-afds-vnav-safety`・`p2-crzalt-approach`・`p3-flare-climbspeed-reverse` は、積み上げ PR #27〜#29 のマージコミット（ccfbc8b0, 58d45db9, 95d5d7ec）だけが未取込みでツリー差分なし。master に届かなかった内容はない。
- `origin/agent/fix-rte-flt-no-display` は PR なし・独自コミットなし（966dcf3f を指す）。`origin/master` は 45cce506。
