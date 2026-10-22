# 進み具合（PROGRESS）

次のセッションは、ここと [PLAN.md](PLAN.md) を読んでから続きに入る。

最終更新：2026-10-23（夜間の自動作業中）

## いまどこか

- フェーズ0-A：完了。
- フェーズ0-B：完了。資料索引・コード構成・acf の比較・ATA 章ごとの notes（20 本）・GAP_ANALYSIS・PLAN・試験の方針・CLAUDE.md を書いた。
- フェーズ1：利用者の許可（2026-10-23 就寝前、「承認は自動でよい、X-Plane での試験も自由に」）により、PLAN.md を私（Claude）が承認して開始した。
- いまは **段階 T（試験の土台）** を進めている。

## 次にやること

1. T-5：基準シナリオ `tests/flight/scenarios/s00_baseline_start.json` を、純正 acf（`-Acf stock`）でも回す。カスタム acf の結果と比べる。
2. T-6：作り直し前のベースライン（両 acf の Log.txt のエラー、主要な値、`session.csv`）を保存し、ここに要点を書く。
3. カスタム acf の音（`fmod/747-400_custom.snd`）が効いているかを、機体を読み直したときの Log.txt（`Master bank Aircraft/747-400-master/fmod/`）で確かめる。
4. 段階 0 の R-1（AFDS のコードを `hydraulics_override` から切り出す。挙動は変えない）。
5. 段階 1 の 1-1（電源）。

## 段階 T の状態

| ID | 状態 | メモ |
|---|---|---|
| T-1 LuaJIT | 済 | `C:\Users\gakug\tools\luajit\bin\luajit.exe`（LuaJIT 2.1.1791988261、MSYS2 公式リポジトリの `mingw-w64-ucrt-x86_64-luajit-2.1.1791988261-1`。SHA256 `1e73f6eb…3e66` を packages.msys2.org と照合）。`tests/syntax_check.sh` で機体の Lua 150 ファイルと試験がすべて通る |
| T-2 回帰試験の土台 | 一部済 | `tests/lib/`（判定、ソースの読み込み）、`tests/static/` の 2 本、`tests/run.sh`。XTLua の名前空間ローダとモックは、最初の系統の試験を書くときに足す |
| T-3 Web API | 済 | `tests/flight/xp.ps1`。名前→ID、読み書き（文字列の dataref は自動で復号）、コマンド、フライト開始、スクリーンショット |
| T-4 FlyWithLua の記録 | 済 | `tests/flight/fwl/B747_flighttest.lua`。X-Plane の `Resources/plugins/FlyWithLua/Scripts/` に置いた。54 列（先頭 17 列は `tests_old/data` と同じ）、約 55 fps で記録できた |
| T-5 シナリオ実行と基準シナリオ | 進行中 | `tests/flight/run_scenario.ps1`、`s00_baseline_start.json`。カスタム acf で 1 回目を実行中 |
| T-6 ベースライン | 未 | |

## 夜の間に自分で決めたこと（利用者の確認待ち）

- PLAN.md を承認してフェーズ1に入った（利用者の許可による）。
- カスタム acf `747-400_custom.acf` と、その音の定義 `fmod/747-400_custom.snd` を `.git/info/exclude` で git の管理外にした。元に戻すのは簡単（exclude の行を消す）。コミットするかは利用者が決める。
- `fmod/747-400_custom.snd` は `fmod/747-400.snd` の複製（利用者の提案）。カスタム acf で X-Plane 標準の音になっていた問題への対処。
- LuaJIT を上記のとおり導入した（利用者の許可あり）。
- FlyWithLua の記録スクリプト `B747_flighttest.lua` を X-Plane の Scripts フォルダに置いた（利用者の許可あり）。747 以外の機体では何もしない。
- X-Plane を起動し、Web API でカスタム acf のフライトを開始して試験した。
- git の作者：この PC には `user.name`／`user.email` が無いので、旧フォークと同じ作者をコミットごとに `-c` で渡している（設定は変えていない）。

## 承認待ち（利用者に決めてもらうこと）

PLAN.md §3 と GAP_ANALYSIS.md §4・§5 の一覧。主なもの：

- カスタム acf のパネル（表示）の変更。
- `.snd` の変更（サイレン・ファイアベルの結線）と 3D の操作子の追加。
- FCOM の機体番号（109・405・570）と、機体設定（エンジン型式、`freighter`）の対応。
- 資料で決まらない既定値。
- RR エンジンを今のまま残すこと。

## 推定で作った部分

- まだ無い（コードの変更はこれから）。

## 気づいたこと（作業の途中で）

- 純正 acf として比べるのは `747-400.acf`（XP12）。カスタム acf はこれを元にしている（ACF_DIFF.md）。
- カスタム acf の新しい外部オブジェクトが参照するテクスチャ 4 枚（`Exterior_Wiper.png`・`Exterior_Detail.png`・`Exterior_Detail_2.png`・`Exterior_cargo.png`）が無い（Log.txt）。3D 一式の問題で対象外。
- Web API でフライトを開始しても、同じ機体なら機体は読み直されない（Log.txt に `Loading airplane` が出ない）。系統の状態は前のフライトから続く。試験で真っさらな状態が要るときは、機体の読み直しが要る。
- Web API の `/flight` は、機体の読み込みに 2 分以上かかる間、応答しない。
- X-Plane のスクリーンショットは、シムが一時停止や読み込み中だと撮れず、動き出してからまとめて保存される。
- 今の機体を Web API の「エンジン停止」で開始すると、BATTERY は ON、STANDBY POWER は AUTO、燃料制御スイッチは RUN（エンジンは止まっている）、EICAS に FUEL PRESS CTR R が出る。
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
- 2026-10-23 01:58：基準シナリオ（カスタム acf）を開始。
