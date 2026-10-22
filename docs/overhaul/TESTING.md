# 試験（TESTING）

作り直しの各項目は、次の 4 段で確かめる。

1. **構文チェック**：LuaJIT（`luajit -bl`）、または Lua 5.1 の `luac -p`。
2. **回帰試験**（`tests/`）：LuaJIT で X-Plane なしに回す。旧フォークの試験の仕組みを流用し、系統ごとに作る（§3）。
3. **X-Plane での試験**：飛行試験キット（§4）と Web API で回し、`Log.txt` のエラーも確認する。
4. **利用者の目視確認**：自分で確かめられなかった点だけを回す。

## 1. 旧フォークの試験（`tests_old/`、参照専用）

### 1.1 扱い

- `tests_old/` は `archive/old-master` の `tests/` と同じ中身（85 ファイル）。`ap_pitch_loop_test.lua` だけ改行コードが違う。
- `.git/info/exclude` で git の管理から外してある。旧フォークのコード向けなので、そのまま通す必要はない。
- 中身は FlyWithLua のスクリプトではなく、**LuaJIT で X-Plane なしに回す回帰試験**。本番の Lua をモックの上で読み込む。
  - 試験 76 本、閉ループのモデル 4 本（`approach_model.lua`、`climb_model.lua`、`roll_model.lua`、`mcp_alt_dial_model.lua`）、記録データ 4 本（`data/*.csv`）。
- 回し方は、リポジトリの直下から `luajit tests/<名前>_test.lua` を 1 本ずつ（1 本に 1 つのインタプリタ）。`lua5.1` でも動く（README）。

### 1.2 仕組み（4 つの手法）

| 手法 | やり方 | 例 |
|---|---|---|
| a. 純粋なモジュール | 本番のロジックを、表を返すモジュールに分けておく。試験は `dofile` で読み、入力の表を渡して出力を確かめる | `takeoff_profile_test.lua`（`B747.70.xt.autopilot.takeoff.lua` の `new` / `update`） |
| b. XTLua の名前空間の再現 | 本物の `plugins/xtlua_keysystems/init.lua` を `loadfile` と `setfenv` で読み、`create_namespace()` で XTLua と同じ名前空間を作る。本番ソースから目印（関数名など）の間を切り出し、`loadstring` と `setfenv(fn, ns)` でその中で実行する。dataref は名前空間の変数として与える（`ns.simDR_x = 値`） | `xtlua_route_constraints_test.lua` |
| c. ソースの静的検査 | 本番の Lua を文字列で読み、規則を検査する：xt スクリプトが `deferred_dataref` で使う `laminar/` の名前を init スクリプトが作っているか、名前空間で束ねていない dataref 名に書いていないか、必要な dataref を毎フレーム読んでいるか（warm read） | `hydraulics_dataref_binding_test.lua`、`xtlua_warm_reads_test.lua` |
| d. 閉ループのモデル | 点質量の 747 と、記録に合わせた X-Plane の姿勢応答のモデルで本番の制御則を回す。フレームレート（15・20・34 fps）を変えても結果が変わらないことを確かめる | `approach_model.lua`、`climb_model.lua`、`afds_speed_on_pitch_test.lua` |

- **モック**：
  - dataref は名前空間の変数、コマンドは関数の呼び出しで置き換える。
  - タイマー（`run_at_interval` など）、`print`、境界の関数（`getFMSData` など）は、試験側で差し替える。
- **判定**：`check` / `equal` / `near(実際, 期待, 許容)` で数える。失敗を集めて最後に `error` を出し、成功すれば件数を表示する。
- **XTLua の落とし穴**（旧フォークで分かったこと。新しい試験でも押さえる）：
  - スクリプトのモジュール内で、dataref の最初の読みは 0 になる → 要る dataref は毎フレーム読む。
  - xt スクリプトの `deferred_dataref` は `find_dataref` と同じ → init スクリプトで作っていないと存在しない。
  - メタテーブルの無い global テーブルの、無い添字を読むとスタックが溢れる。
  - チャンクをまたいで local は見えない。XTLua 独自の `dofile` の戻り値。1 回だけのコマンドには phase 2 が来ない。
  - Web API で XTLua の double 型 dataref に小数を書くと HTTP 400 になる。

### 1.3 記録データ（`tests_old/data`）

- 旧フォークの飛行試験キットが X-Plane で記録した `session.csv` から切り出したもの。キット本体は見つからない。
- 列（意味は旧試験のコメントからの**推定**。フェーズ1で dataref と照らして確かめる）：

| ファイル | 列 |
|---|---|
| `p32-line1_gs_pitch.csv`（EHAM ILS 18R の G/S、2,300→400 ft） | `t, fd, pitch, q, alpha, trim, ias, elevator_ratio` |
| `p34-L1_speed_pitch.csv`、`p35-line1_speed_pitch.csv`、`p35-line1_takeoff.csv` | `t, alt, ias, vs, pitch, thrust, tgt, flap, fma, mcp_alt, window, weight` |

| 列 | 意味（推定） | 単位 |
|---|---|---|
| `t` | 記録開始からの時間 | s |
| `fd` | FD のピッチ指令 | deg |
| `pitch` / `q` / `alpha` | ピッチ角 / ピッチレート / 迎角 | deg / deg/s / deg |
| `trim` | 安定板トリム | 不明（要確認） |
| `elevator_ratio` | 昇降舵の比（-1〜1） | — |
| `alt` / `ias` / `vs` | 高度 / 指示対気速度 / 昇降率 | ft / kt / fpm |
| `thrust` | エンジン 1 基あたりの推力（`sim/flightmodel/engine/POINT_thrust`） | N |
| `tgt` | AFDS の目標速度 | kt |
| `flap` | フラップハンドルの比（0〜1） | — |
| `fma` | ピッチの FMA モード番号（`B747DR_ap_FMA_active_pitch_mode`。旧試験では 1 TO/GA、4 VNAV SPD、8 FLCH） | — |
| `mcp_alt` / `window` / `weight` | MCP 高度 / 高度捕捉の窓（`B747DR_alt_capture_window`） / 重量 | ft / ft / kg |

### 1.4 X-Plane での確認シナリオ（README の末尾）

- README の末尾に 16 件ある。旧フォークで作った VNAV・FMC の機能が中心。例：出発の加速高度、ステップ上昇、CRZ ALT、ECON の切り替わり、SPD REST、フラップの速度制限。
- 新しいキットのシナリオには、資料で裏付けが取れるものだけを移す（§4.5）。

## 2. 流用するもの・しないもの

- **流用する**：
  - 1 本に 1 つのインタプリタで回す形、判定の道具（`check` / `equal` / `near`、失敗を集めて最後に出す）
  - XTLua の名前空間の再現（本物の `init.lua` を読む方式）
  - 静的検査（init で作られているか、束ねていない名前への書き込み、warm read、global テーブルのメタテーブル）
  - CSV の読み込みと補間、閉ループのモデルの骨組み（フレームレートを変えて回す形）
  - README の X-Plane での確認シナリオ（§1.4）のうち、資料で裏付けが取れるもの
- **流用しない**：
  - 旧コードの関数名や目印に頼った切り出し。新しいコードでは、試したいロジックを純粋なモジュールに分け、`dofile` で読む形を基本にする。
  - 旧コードの調整値。記録に合わせただけのモデルの定数も含む。
- **期待値**：
  - 旧試験の期待値は、資料（FCOM・FCTM・整備マニュアル）で裏付けが取れたものだけを新しい試験に移す。移した値には、コメントで出典（`FCOM p.801 (6.20.7)` の形）を付ける。
  - 裏付けの無い値は移さない。どうしても要るときは「推定」と書く。

## 3. 新しい回帰試験（`tests/`、git 管理）

- 構成（予定）：
  - `tests/lib/`：判定の道具、XTLua の名前空間ローダ、dataref・コマンド・タイマーのモック、CSV の読み込み
  - `tests/<系統>/*_test.lua`：系統ごとの試験。電源から作る
  - `tests/static/*_test.lua`：全系統に共通の静的検査（§2 の静的検査、`INTERFACES.tsv` の名前が残っているか）
  - `tests/run.sh`・`tests/run.ps1`：全部回す
- 系統を作り直すときに、その系統の試験を一緒に書く。
- 1 件の試験は「入力（スイッチ、dataref の値、経過時間）→ 期待される出力（dataref、EICAS メッセージ、ライト）」の形にし、出典のページを付ける。
- 時間で進む処理は、dt を渡して回す。フレームレートを変えても結果が同じになることも確かめる。
- LuaJIT はまだ入っていない。PLAN の最初の項目で、入手元を示して用意する。

## 4. 飛行試験キット（新規。PLAN の最初の項目）

旧フォークの飛行試験キット（X-Plane で飛ばして `session.csv` に記録し、判定するもの）は見つからないので、新しく作る。系統の変更より先に完成させ、純正 acf とカスタム acf の両方で動くことを確かめる。

### 4.1 方針

- **Web API が中心**。X-Plane 12.4 以降の v3 で、dataref の読み書き、コマンドの実行、フライトの開始（`POST /flight`）を使う。スクリーンショットは X-Plane のスクリーンショットのコマンドを Web API から実行し、出てきた画像を取る。
- **毎フレームの精度が要る部分だけ FlyWithLua で補う**。毎フレームの記録（`session.csv`）、FMA の変化などのイベントの時刻、最大値・最小値のような細かい判定がそれにあたる。Web API の更新は、WebSocket で約 10 Hz。
- FlyWithLua のスクリプトは `../../Resources/plugins/FlyWithLua/Scripts/` に置く（利用者の許可あり。置いたものは報告する）。正本はリポジトリに置き、コピーして使う。

### 4.2 構成（予定）

| 置き場所 | 中身 |
|---|---|
| `tests/flight/xp.ps1` | Web API クライアント。`/api/capabilities` の確認、名前→ID の解決とキャッシュ、dataref の読み書き、コマンドの実行、フライトの開始、スクリーンショットの取得 |
| `tests/flight/run_scenario.ps1` | シナリオの実行。手順を順に実行し、条件を待ち（タイムアウト付き）、判定する。結果は JSON と Markdown で書く |
| `tests/flight/scenarios/` | シナリオの定義。手順、待つ条件、判定、出典。`docs/overhaul/notes/FCTM.md` の案から作る |
| `tests/flight/fwl/B747_flighttest.lua` | FlyWithLua 用のスクリプト。毎フレームの記録、イベント、細かい判定を受け持つ。自分で作るコマンド（開始・停止・印）を Web API から操作する。747 以外の機体では何もしない |
| `tests/flight/runs/<日時>_<シナリオ>_<acf>/` | 出力。`session.csv`、`events.csv`、`result.json`、スクリーンショット、その回の `Log.txt` の抜粋。git の管理外にする |

- `session.csv` の列：
  - §1.3 の列（`t, alt, ias, vs, pitch, thrust, tgt, flap, fma, mcp_alt, window, weight, fd, q, alpha, trim, elevator_ratio`）を、同じ名前・単位で必ず含める。
  - その後ろに足す列の例：ロール、方位、対地速度、電波高度、N1・N2・EPR・燃料流量（4 発分）、ロールと A/T の FMA、EICAS のメッセージ数、主要な系統の状態。
  - 各列の出典 dataref は、フェーズ1で確かめて、この文書に表で書く。

### 4.3 判定

- 判定の数値は FCOM・FCTM・整備マニュアルから取り、シナリオに出典を書く。
- 許容幅が資料に無いときは「推定」と書く。

### 4.4 完成の条件（PLAN 項目 1）

- 純正 acf（`747-400.acf`）とカスタム acf（`747-400_custom.acf`）の両方で、少なくとも「起動 → 電源投入 → APU → エンジン始動」のシナリオが自動で回る。
- `session.csv`、スクリーンショット、判定結果が出る。
- 作り直しの前の機体で、ベースライン（`Log.txt` のエラーと主要な値）を記録してある。

### 4.5 シナリオ

- 標準の飛ばし方は `docs/overhaul/notes/FCTM.md` の案から作る。
  - 例：cold & dark からの電源投入、エンジン始動、離陸、上昇、巡航とステップ上昇、VNAV 降下、ILS とオートランド、ゴーアラウンド、V1 後のエンジン故障、非 ILS 進入、停止。
- 旧 README の 16 件（§1.4）は、資料で裏付けが取れるものだけを加える。

### 4.6 気をつけること

- Web API は、フライトを読み込むまで dataref の一覧が空。
- X-Plane の Network 設定で「Disable Incoming Traffic」が入っていると、すべて 403 になる。
- XTLua の double 型 dataref に小数を書くと 400 になる（旧フォーク）。キットでは書き方を工夫するか、FlyWithLua 側で書く。
- 機体の設定（エンジン型式、タンク数など）は、dataref から読んで判定に使う。カスタム acf の値を決め打ちしない。

## 5. 1 項目ごとの流れ（フェーズ1以降）

1. 着手前に、変更方針を短く示す。
2. 実装する。
3. 構文チェック。
4. `tests/` の回帰試験（LuaJIT、X-Plane なし）。
5. 飛行試験キットと Web API で X-Plane での試験をし、`Log.txt` のエラーも確認する。区切りごとに純正 acf でも、起動・電源投入・エンジン始動まで回す。
6. 結果と、利用者が X-Plane で目視確認すべき点を報告する。
7. コミットする（1 テーマ 1 コミット、根拠の資料とページを書く）。

## 6. 環境（2026-10-23 時点）

- X-Plane 12.4.4-b5。Web API は v3 が使える（ARCHITECTURE.md §9）。
- FlyWithLua NG+ 2.8.19 は利用者が導入済み。`Scripts/` には付属の説明スクリプトだけがある。
- LuaJIT と Lua は入っていない（PLAN の最初の項目で用意する）。
- Python は使わない（CLAUDE.md）。
