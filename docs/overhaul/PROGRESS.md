# 進み具合（PROGRESS）

次のセッションは、ここと [PLAN.md](PLAN.md) を読んでから続きに入る。

最終更新：2026-10-23（夜間の自動作業中）

## いまどこか

- フェーズ0-A：完了。
- フェーズ0-B：完了。資料索引・コード構成・acf の比較・ATA 章ごとの notes（20 本）・GAP_ANALYSIS・PLAN・試験の方針・CLAUDE.md を書いた。
- フェーズ1：利用者の許可（2026-10-23 就寝前、「承認は自動でよい、X-Plane での試験も自由に」）により、PLAN.md を私（Claude）が承認して開始した。
- **段階 T（試験の土台）：完了**（コミット 27e8f854）。純正 acf とカスタム acf の両方で基準シナリオが通った。
- **段階 0**：
  - R-2（新しいコードの書き方）：完了（d8adfdd8、ARCHITECTURE.md §9a）。
  - R-1（AFDS のコードを油圧のファイルから切り出す）：完了（5af549c6）。X-Plane なしで全フレーム同じ出力、X-Plane で Lua の誤りなし。
  - R-3（早く効く小修正）：任意。まだ手を付けていない。
- **段階 1**：
  - 1-1（電源）：モデル（4fb1fa46）と、機体への組み込み（f38d0baf。電源モジュール、P5 の灯、EICAS、表示器と時計の電源）まで。X-Plane でカスタム acf の `s02_elec_panel` 59/59、`s00` 64/64、純正 acf の `s00` 64/64。残りは使う側の乗り換え（下）。
  - 1-2（空地判定、PSEU）：モデル・脚モジュールへの組み込み・公開 dataref まで。乗り換え済みは電源の BCU（air mode など）、脚レバーのロック、逆推力のロックアウト（前脚を含む全輪の接地 → 主脚左右の接地）。残りの系統は各作り直しで。

## 次にやること

1. 1-1（電源）の残り：電源の有無を `bus_volts` で見ている系統を、バスごとの dataref（ARCHITECTURE.md §4.1）に乗り換える。
   - 済：表示器（fltInst02。機長 PFD・ND は APU standby、upper EICAS は main standby、ほかは F/O transfer）、EICAS の計算（warning。EIU のどれかに電源）、時計の計時（fltInst03・04。main hot battery bus）、ELEC パネルの灯（lighting）。
   - 残り：燃料のポンプと弁（fuel：AC・utility・battery bus の割り当て。APU の DC 燃料ポンプとの関係があるので 2-2 と一緒に）、抽気弁と装備冷却（air：DC bus）、IRS と NAV RAD（fms）、表示灯の輝度（lighting：`bus_volts[0]`・`[2]`）、客室灯（lighting）、ヨーダンパー（fltCtrls：`battery_array_on`）、STAT ページの main バッテリー（X-Plane の値）。
2. 1-2（空地判定）の残り：`onground_any` を読んでいる 17 モジュール（warning、autopilot、fms、fltInst02、antiice、fltCtrls、EEC、engines、fuel、hydraulicsmodel、gear の autobrake、manipulators、fdr、lighting など）を、PSEU の dataref（ARCHITECTURE.md §4.2）に乗り換える。どの信号（pri/alt の AIR・GND、前脚圧縮）を使うかは notes/ATA-32.md §4.1 の表。各系統の作り直しのときに行う。
3. 1-3（警報の枠組み）へ。
4. R-3 は、作り直しが先になる系統の害の大きい誤りだけ、合間に入れる。

## 段階 T の状態

| ID | 状態 | メモ |
|---|---|---|
| T-1 LuaJIT | 済 | `C:\Users\gakug\tools\luajit\bin\luajit.exe`（LuaJIT 2.1.1791988261、MSYS2 公式リポジトリの `mingw-w64-ucrt-x86_64-luajit-2.1.1791988261-1`。SHA256 `1e73f6eb…3e66` を packages.msys2.org と照合）。`tests/syntax_check.sh` で機体の Lua と試験がすべて通る |
| T-2 回帰試験の土台 | 済 | `tests/lib/`（判定、ソースの読み込み、XTLua の再現 `xtlua.lua`）、`tests/static/` の 3 本（26 モジュールすべてが X-Plane なしで読み込み・60 フレームを通ることを含む）、`tests/tools/same_behaviour.lua`（挙動を変えない変更の確認）、`tests/run.sh` |
| T-3 Web API | 済 | `tests/flight/xp.ps1`。名前→ID、読み書き（文字列の dataref は自動で復号）、コマンド、フライト開始、スクリーンショット |
| T-4 FlyWithLua の記録 | 済 | `tests/flight/fwl/B747_flighttest.lua`（版 3）。X-Plane の `Resources/plugins/FlyWithLua/Scripts/` に置いた。55 列（先頭 17 列は `tests_old/data` と同じ。列の出典は TESTING.md §4.2）、約 55 fps で記録できた |
| T-5 シナリオ実行と基準シナリオ | 済 | `tests/flight/run_scenario.ps1`、`s00_baseline_start.json`。カスタム acf・純正 acf とも 56 件すべて合格 |
| T-6 ベースライン | 済 | 下の「作り直し前のベースライン」。出力一式は `tests/flight/runs/`（git 管理外） |

## 作り直し前のベースライン（T-6、2026-10-23）

基準シナリオ `s00_baseline_start`（RJAA 34L、エンジン停止で開始。BATTERY → STANDBY POWER → FUEL CONTROL CUTOFF → APU → APU GEN → 抽気・燃料ポンプ → 4→3→2→1 の順に始動）。

| 項目 | カスタム acf | 純正 acf |
|---|---|---|
| 実行 | `20261023_021753_..._custom`（`-Reload` で読み直し） | `20261023_023824_..._747-400`（X-Plane を起動し直した直後） |
| 判定 | 合格 56・不合格 0・注意 0 | 合格 56・不合格 0・注意 0 |
| 開始時の状態 | BATTERY ON、STANDBY AUTO、FUEL CONTROL は 4 つとも RUN、`bus_volts[0]` 24.0 V（電池だけ） | 同じ（24.0 V） |
| APU 吸気ドアが 20 % 開くまで（selector ON から） | 5.7 s | 5.4 s |
| APU N1 95 % まで（START から） | 56.6 s | 55.9 s |
| 始動前のダクト圧（APU 抽気、L・C・R とも） | 40.6 psi | 40.0 psi |
| START → N2 20 % | 22.6 s（4 発とも） | 22.6 s（4 発とも） |
| N2 20 → 50 %（燃料投入から） | 2〜4 番 24.6 s、**1 番 7.0 s** | 同じ |
| 始動中の EGT の最大 | 2〜4 番 479 ℃、**1 番 301 ℃** | 同じ |
| idle（4 発、20 秒後） | N1 27.2 %、N2 69.7 %、EGT 280 ℃、EPR 1.023 | N1 27.2 %、N2 69.7 %、EGT 280 ℃、EPR 1.020、燃料流量 0.020 kg/s（約 72 kg/h） |
| Log.txt の Lua の誤り | 無し | 無し |

- 記録した値は X-Plane の dataref の値で、まだ資料と照らしていない。資料との比較は各系統の作り直しで行う（例：APU の始動時間は FCOM p.897、エンジン始動は FCOM の 7.30 章と ATA 70〜80）。
- EICAS（両 acf でほぼ同じ。読んだ瞬間による差がある）：
  - 電池だけ：HYD PRESS SYS 1・4（2・3 は出ない）、ELEC AC BUS 1〜4、>FUEL LOW CTR L・R、PARK BRAKE SET、PASS SIGNS ON、ACARS NO COMM。
  - APU 始動後：FUEL PRESS CTR L・R が加わる（純正 acf では >BAT DISCH MAIN も）。
  - APU GEN 投入後：ELEC AC BUS は 1〜2 秒遅れて消える。
  - 主燃料ポンプ ON の後：HYD PRESS SYS 4、>FUEL LOW CTR L・R、PACKS OFF、APU RUNNING。
  - 4 発始動後：FUEL PRESS CTR L・R、PARK BRAKE SET、PASS SIGNS ON、ACARS NO COMM、APU RUNNING、PACKS OFF。
  - FUEL PRESS CTR と >FUEL LOW CTR が場面ごとに入れ替わる（中央タンクのポンプのスイッチは触っていない）。燃料系の作り直しで確かめる。

## 夜の間に自分で決めたこと（利用者の確認待ち）

- PLAN.md を承認してフェーズ1に入った（利用者の許可による）。
- カスタム acf `747-400_custom.acf` と、その音の定義 `fmod/747-400_custom.snd` を `.git/info/exclude` で git の管理外にした。元に戻すのは簡単（exclude の行を消す）。コミットするかは利用者が決める。
- `fmod/747-400_custom.snd` は `fmod/747-400.snd` の複製（利用者の提案）。カスタム acf で X-Plane 標準の音になっていた問題への対処。機体を読み直すと機体の FMOD バンクが読まれることを Log.txt で確かめた。今後 `.snd` を変えるときは、複製も同じにする。
- LuaJIT を上記のとおり導入した（利用者の許可あり）。
- FlyWithLua の記録スクリプト `B747_flighttest.lua` を X-Plane の Scripts フォルダに置き、版を上げるたびに写した（版 3）。747 以外の機体では何もしない。
- FlyWithLua 付属の `please read the manual.lua` は、スクリーンショットに吹き出しを出すが、利用者のファイルなので消していない。要らなければ消してよい。
- X-Plane を起動し、Web API で両方の acf のフライトを開始して試験した。X-Plane が「応答なし」で止まったとき、`Log.txt` を残してから強制終了し、起動し直した（下の「気づいたこと」）。
- `.gitattributes` を足し、`tests/*.sh` を常に LF で取り出すようにした（CRLF だと bash が動かない）。対象はこの 2 本だけ。
- git の作者：この PC には `user.name`／`user.email` が無いので、旧フォークと同じ作者をコミットごとに `-c` で渡している（設定は変えていない）。

## 承認待ち（利用者に決めてもらうこと）

PLAN.md §3 と GAP_ANALYSIS.md §4・§5 の一覧。主なもの：

- カスタム acf のパネル（表示）の変更。
- `.snd` の変更（サイレン・ファイアベルの結線）と 3D の操作子の追加。
- FCOM の機体番号（109・405・570）と、機体設定（エンジン型式、`freighter`）の対応。
- 資料で決まらない既定値。
- RR エンジンを今のまま残すこと。

## 推定で作った部分

- 試験の許容幅（`s00`・`s01` の数値の幅）は推定。シナリオに「推定」と書いてある。
- 電源モデル（1-1。`B747.03.elec_model.lua` に「estimate」と書いてある）：
  - バッテリーの負荷電流（main battery bus 12 A、main inverter 28 A、APU battery bus 8 A、APU inverter 15 A、APU starter 250 A など）。資料に値が無いので、バッテリー 1 個で standby bus を約 1 時間保つように決めた（FCOM p.804 は「最低 30 分」）。
  - BAT DISCH の表示までの遅れ 60 秒（FCOM p.181 は「最大 3 分」とだけ書く）。
  - バッテリー電圧の曲線（放電で 25→22 V）。
  - DRIVE 灯：IDG の回転が on line の回転未満で点く（油圧が回転で立つとみなした）。
  - DRIVE DISC：エンジン停止中に押しても切れない（実機は「不完全」）。
  - ELEC GEN OFF n を、同じ番号の ELEC AC BUS 表示中は出さない。
  - 中央 CDU の電源（資料に無い）：今までどおり F/O transfer bus。
- 空地判定（1-2。`B747.10.pseu_model.lua`・`B747.10.xt.pseu.lua` に「estimate」と書いてある）：
  - トラックの「傾き」：X-Plane の `eagle_claw_angle_deg` が 1° を超えたら傾き（X-Plane には傾きセンサーが無い）。
  - 前脚圧縮：前輪の接地（`on_ground[0]`）。実機は strut が 8 in を超えて縮んだとき。
  - HYDIM 1・4 の「高圧」：1,500 psi 以上（資料に値が無い）。
  - 胴体脚ステアリングの「ロック」：胴体脚の車輪の角度が 0。

## 電源（1-1）の GAP の状態

| ID | 状態 |
|---|---|
| ELEC-01 バス単位のモデル | 済（モデル） |
| ELEC-02 バス単位の公開 | dataref は済。使う側の乗り換えは 1-1 の次の段 |
| ELEC-03 電源切替 | 済（LH24 p.123 の表と FCOM p.796-797） |
| ELEC-04 GCB/BTB の自動制御 | 一部。許可ラッチと on line の回転は済。保護トリップ・3.5 秒の break power transfer・last source on は故障を入れるときに |
| ELEC-05 SSB | 一部。自動の開閉は済。手動の SSB スイッチと OPEN 灯は無し（3D に無い） |
| ELEC-06 standby | 済 |
| ELEC-07 表示器と CDU の電源 | 一部。CDU は済。upper EICAS（main standby）は fltInst02 の乗り換えで |
| ELEC-08 ELEC GEN OFF | 済（advisory、GCB 開で） |
| ELEC-09 ELEC AC BUS | 済 |
| ELEC-10 ELEC BUS ISLN | 済 |
| ELEC-11 DRIVE 灯 | 一部。灯と ELEC DRIVE は済。synoptic の DRIVE 枠はパネル（acf）のまま |
| ELEC-12 DRIVE DISC | 済 |
| ELEC-13 GHB/GSB | 一部。ground service switch（客室のパネル）は無し |
| ELEC-14 ELCU と load shed | 済（発電機の台数で決める簡略版） |
| ELEC-15 DC とバッテリー母線 | 済 |
| ELEC-16 バッテリーの表示 | 一部。APU バッテリーと BAT DISCH は済。STAT の main バッテリーは X-Plane の値のまま |
| ELEC-17〜18、21〜24 | 未 |
| ELEC-19 air mode | 済 |
| ELEC-20 故障 dataref の上書き | 済（書くのをやめた） |

## 気づいたこと（作業の途中で）

- 純正 acf として比べるのは `747-400.acf`（XP12）。カスタム acf はこれを元にしている（ACF_DIFF.md）。
- カスタム acf の新しい外部オブジェクトが参照するテクスチャ 4 枚（`Exterior_Wiper.png`・`Exterior_Detail.png`・`Exterior_Detail_2.png`・`Exterior_cargo.png`）が無い（Log.txt）。3D 一式の問題で対象外。
- Web API でフライトを開始しても、同じ機体なら機体は読み直されない（Log.txt に `Loading airplane` が出ない）。系統の状態は前のフライトから続く。試験で真っさらな状態が要るときは `-Reload`。
- Web API の `/flight` は、機体の読み込みに 2 分以上かかる間、応答しない。
- X-Plane のスクリーンショットは、シムが一時停止や読み込み中だと撮れず、動き出してからまとめて保存される。
- 今の機体を Web API の「エンジン停止」で開始すると、BATTERY は ON、STANDBY POWER は AUTO、燃料制御スイッチは RUN（エンジンは止まっている）になる。
- **X-Plane が止まった件（02:26 ごろ）**：カスタム acf から純正 acf へ Web API で切り替え、すぐ機体の読み直しを送った後、X-Plane が「応答なし」になった（CPU は約 2 コア分使い続け、sim の時計が止まり、Web API だけ答える）。10 分待っても戻らず、Log.txt を `runs/20261023_022542_..._747-400/Log_hung.txt` に残して強制終了した。起動し直した後は、純正 acf でもカスタム acf でも問題なく動いた。
  - 原因は分からない。Log.txt には誤りが出ていない。カスタム acf の読み込みでは、GPU のメモリ（RTX 3070、8 GB）の予算超過の警告が出ている（`Memory heap 0 has overstepped its budget`）。acf を何度も切り替えると、メモリが足りなくなるのかもしれない（推定）。
  - 対策：`-Reload` は Log.txt に新しい読み込みが出るのを待ち、出なければ送り直す。`run_scenario.ps1` は sim の時計が 30 秒動かなければやめる。acf を切り替えるときは、必要なら X-Plane を起動し直す。
- **1 番エンジンだけ始動が速い**（両 acf で再現）：燃料投入から N2 50 % まで 7 秒（他は 25 秒）、EGT の山が出ない（301 ℃、他は 479 ℃）。ENG-16（スターターを止めるとき 2〜4 番が 1 番の igniter を切る）を記録で確かめたが、それだけでは説明できない。エンジンの作り直し（段階 2-3）で調べる。
- **始動中の燃料流量が負**：燃料系と EICAS が使う `sim/cockpit2/engine/indicators/fuel_flow_kg_sec` が、始動中に約 -0.08 kg/s になる。燃料系がそのまま引くと、始動のたびにタンクの量がわずかに増える（推定。燃料系の作り直しで確かめる）。
- idle の燃料流量が 1 発あたり約 72 kg/h と小さい（推定。資料の値と比べるのはエンジン・燃料の作り直しで）。
- **HDG HOLD が無い**：MCP の HDG HOLD のコマンド（`laminar/B747/autopilot/button_switch/hdg_hold_mode`）は init スクリプトでコメントアウトされていて存在しない。FCOM には HDG HOLD がある（notes/ATA-22.md、FCOM p.647・p.663）。AFDS-01 は HDG HOLD がある前提で書いてあるので、AFDS の作り直しで扱う。
- 空中開始（Web API の `lle_air_start`）では、A/P が既に入った状態で始まる（ピッチのモード 9、ロール 7、A/T 3）。
- XTLua の本体が持つ C の関数名は `XlLuaReplaceCommand`（綴りどおり）。init/init.lua の綴りは誤りではない。
- 同じ global に 2 回 `find_dataref` すると、2 回目の代入でその dataref に 0（文字列の dataref なら何も書かない）が書かれる（XTLua の名前空間の作り）。油圧モジュールの `altitude_hold_status` などで起きている。読み込み時だけなので今は害は小さい。
- 静的検査で見つかった既存の不具合：
  - `fltInst02` が、init スクリプトで作られていない時計の dataref 40 個と `electrical/oil` を使っている。
  - 3D の CHRONO スイッチが使う `glareshiled/*/chrono_switch_pos` は、xt スクリプトでしか宣言されていない。存在しない可能性がある。
  - いずれも `tests/static/` の既知の一覧に入れた。

## 日誌

- 2026-10-22 23:27〜23:44：利用者が、別の 3D 一式（git に無い）とカスタム acf を作業ツリーに上書きコピー。
- 2026-10-23 00:0x：
  - 変更のあった追跡ファイル 110 個を `D:\747-400-local-assets\` に退避。
  - `archive/old-master`（45cce506）を push。
  - 本家を upstream に追加し、`overhaul`（041c9ffa）を作成。
  - 3D 一式の 72 ファイルを戻して skip-worktree を付けた。
- 2026-10-23 00:3x〜：PDF のテキスト化、REFERENCE_INDEX・ARCHITECTURE・ACF_DIFF・INTERFACES を作成。
- 2026-10-23 00:36〜02:xx：ATA 章ごとの 19 班で notes を作成。
- 2026-10-23 01:0x：利用者が `tests_old/` を置き、試験の方針を追加。TESTING.md と CLAUDE.md を更新。
- 2026-10-23 01:3x：LuaJIT を導入。X-Plane を起動し、Web API・FlyWithLua の記録・スクリーンショットを確認。
- 2026-10-23 01:58：基準シナリオ（カスタム acf）1 回目。APU が始動せず（APU-13）、手順を直した。
- 2026-10-23 02:17：カスタム acf で 2 回目、全項目合格。カスタム acf の FMOD バンクが読まれることを確認。
- 2026-10-23 02:25：純正 acf へ切り替えた直後に X-Plane が止まる。02:37 に起動し直した。
- 2026-10-23 02:38：純正 acf で全項目合格。XTLua の再現（`tests/lib/xtlua.lua`）と、挙動を変えない変更の確認の道具を作った。
- 2026-10-23 02:4x：R-1 の切り出し。X-Plane なしで、切り出し前と全フレーム同じ出力になることを確かめた。試験一式（27e8f854）、R-2（d8adfdd8）、APU-13（cc1a7ce2）をコミット。
- 2026-10-23 02:5x：R-1 の X-Plane での確認（`s01_ap_basic`、カスタム acf）。Lua の誤りなし。R-1 をコミット（5af549c6）。`s01` の 2 回目は機体を読み直さなかったため、低速の空中開始から地面に降りた（シナリオに `"reload": true` を足した、85092512）。
- 2026-10-23 03:0x：電源モデルと試験 115 件（4fb1fa46）。
- 2026-10-23 03:1x〜：電源モデルの組み込み。P5 の灯、EICAS、表示器・CDU・時計の電源、EICAS の計算の電源を乗り換え。カスタム acf で `s02_elec_panel` 59/59。
