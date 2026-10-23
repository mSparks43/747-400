# 進み具合（PROGRESS）

次のセッションは、ここと [PLAN.md](PLAN.md) を読んでから続きに入る。

最終更新：2026-10-23 朝（1-5 空圧）

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
  - 1-1（電源）：モデル（4fb1fa46）と、機体への組み込み（f38d0baf。電源モジュール、P5 の灯、EICAS、表示器と時計の電源）まで。X-Plane でカスタム acf の `s02_elec_panel` 63/63・`s00` 64/64、純正 acf の `s02` 63/63・`s00` 64/64。残りは使う側の乗り換え（下）。
  - 1-2（空地判定、PSEU）：モデル・脚モジュールへの組み込み・公開 dataref まで。乗り換え済みは電源の BCU（air mode など）、脚レバーのロック、逆推力のロックアウト（前脚を含む全輪の接地 → 主脚左右の接地）。X-Plane で地上（`s02`、両 acf）と空中（`s01`、カスタム acf）の判定を確認。残りの系統は各作り直しで。
  - 1-3（警報の枠組み）：モデル（001f345e）と、機体への組み込みまで（警報モジュールの新しいグルー、fltInst02 の CANC/RCL と manipulators の master リセットは押した回数の dataref で渡す、メッセージ表のレベルと文言を FCOM に合わせた）。試験はモデル 94 件・モジュール 41 件、X-Plane の `s03_alerts`。残りは下の「警報（1-3）の GAP の状態」。
  - 1-4（油圧）：モデル（0df481e3）と、機体への組み込みまで（油圧モジュールの圧・synoptic・accumulator 計、P5 の灯、EICAS、X-Plane の油圧に故障を書かない、X-Plane の漏れ故障を作動油量で受ける、舵面の系統の組の誤り HYD-06・07）。試験はモデル 94 件・モジュール 68 件、X-Plane の `s04_hydraulics`。残りは下の「油圧（1-4）の GAP の状態」。
  - 1-5（空圧）：モデルと、空調モジュールへの組み込みまで（エンジン 4 基の HPSOV・PRV・PRSOV・始動弁、3 区画のダクトと ISLN、APU 弁、需要に応じたダクト圧、P5 の SYS FAULT・VALVE 灯、EICAS）。前の抽気のコードは外した。試験はモデル 71 件・モジュール 19 件、X-Plane の `s05_bleed`（カスタム acf）。残りは下の「空圧（1-5）の GAP の状態」。

## 次にやること

1. 承認済みの `.snd` の結線とパネル（カスタム acf）の変更：済んだ系統の分から。音は 1-3、パネルは 1-3（2 ページ目の PG、3 ページ目以降、STATUS）、1-4（HYD synoptic、STATUS、リザーバ与圧）、1-1（synoptic の ISLN・DRIVE の箱）、1-5（ダクト圧の表示 PNEU-09・10）。
2. 段階 2 の最初は 2-1（APU）。1-1 と 1-5 に依存（PLAN.md）。
3. 1-5（空圧）の残り：故障の入れ方（過熱、過圧、HPSOV・PRV の固着、ダクトリーク）、地上空気の操作、スターターがダクト圧で回ること（エンジン 2-3）。
4. 1-4（油圧）の残り：脚・ブレーキ・ステアリング・逆推力・stab trim・ヨーダンパーの「油圧で動くか」（HYD-09・11・12）は、それぞれの作り直しで、モデルの負荷の表（`B747_hyd_model.LOADS`）を使って入れる。リザーバ与圧と STATUS のメッセージの表示はパネルが要る（承認済み。上の 1）。
5. 1-1（電源）の残り：電源の有無を `bus_volts` で見ている系統を、バスごとの dataref（ARCHITECTURE.md §4.1）に乗り換える。どれも後の作り直し（空圧 1-5、空調 3-1、燃料 2-2、IRS と無線、照明、操縦系統 4-1）と絡むので、1-2 と同じく各系統の作り直しのときに行う（2026-10-23 に決めた。利用者の確認待ち）。
   - 済：表示器（fltInst02。機長 PFD・ND は APU standby、upper EICAS は main standby、ほかは F/O transfer）、EICAS の計算（warning。EIU のどれかに電源）、時計の計時（fltInst03・04。main hot battery bus）、ELEC パネルの灯（lighting）。
   - 残り：燃料のポンプと弁（fuel：AC・utility・battery bus の割り当て。APU の DC 燃料ポンプとの関係があるので 2-2 と一緒に）、装備冷却（air：DC bus。抽気弁は 1-5 で乗り換えた）、IRS と NAV RAD（fms）、表示灯の輝度（lighting：`bus_volts[0]`・`[2]`）、客室灯（lighting）、ヨーダンパー（fltCtrls：`battery_array_on`）、STAT ページの main バッテリー（X-Plane の値）。
6. 1-2（空地判定）の残り：`onground_any` を読んでいる 16 モジュール（autopilot、fms、fltInst02、antiice、fltCtrls、EEC、engines、fuel、hydraulicsmodel、gear の autobrake、manipulators、fdr、lighting など）を、PSEU の dataref（ARCHITECTURE.md §4.2）に乗り換える。どの信号（pri/alt の AIR・GND、前脚圧縮）を使うかは notes/ATA-32.md §4.1 の表。各系統の作り直しのときに行う。
7. 1-3 の残り：他のメッセージによる抑止（notes/ATA-31-warning.md §4.4.1）と時間遅れは、各系統の作り直しで表に足す。音（`.snd`）とパネル（PG・3 ページ目以降・STATUS）は承認済み（上の 1）。
8. R-3 は、作り直しが先になる系統の害の大きい誤りだけ、合間に入れる。

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
- カスタム acf `747-400_custom.acf` と、その音の定義 `fmod/747-400_custom.snd` を `.git/info/exclude` で git の管理外にした。元に戻すのは簡単（exclude の行を消す）。コミットするかは利用者が決める。（朝、利用者の指示で git に入れた：936222b0）
- `fmod/747-400_custom.snd` は `fmod/747-400.snd` の複製（利用者の提案）。カスタム acf で X-Plane 標準の音になっていた問題への対処。機体を読み直すと機体の FMOD バンクが読まれることを Log.txt で確かめた。今後 `.snd` を変えるときは、複製も同じにする。
- LuaJIT を上記のとおり導入した（利用者の許可あり）。
- FlyWithLua の記録スクリプト `B747_flighttest.lua` を X-Plane の Scripts フォルダに置き、版を上げるたびに写した（版 3）。747 以外の機体では何もしない。
- FlyWithLua 付属の `please read the manual.lua` は、スクリーンショットに吹き出しを出すが、利用者のファイルなので消していない。要らなければ消してよい。（朝、利用者が消した）
- X-Plane を起動し、Web API で両方の acf のフライトを開始して試験した。X-Plane が「応答なし」で止まったとき、`Log.txt` を残してから強制終了し、起動し直した（下の「気づいたこと」）。
- `.gitattributes` を足し、`tests/*.sh` を常に LF で取り出すようにした（CRLF だと bash が動かない）。対象はこの 2 本だけ。
- git の作者：この PC には `user.name`／`user.email` が無いので、旧フォークと同じ作者をコミットごとに `-c` で渡している（設定は変えていない）。
- 1-1 の残り（電源を使う側の乗り換え）は、空圧・空調・燃料・IRS・照明・操縦系統の作り直しと絡むので、1-2 と同じく各系統の作り直しのときに行うことにした（次にやること 2）。
- 警報の組み込みで、CANC・RCL・master リセットを「押した回数」の dataref（新設 3 本）で警報モジュールに渡すことにした（プラグインやモジュールが別で、Lua の状態を共有できないため。ARCHITECTURE.md §4.3）。
- 油圧の組み込みでは、X-Plane 自身の油圧に故障を書かないことにした（notes/ATA-29.md §6.1 の推奨）。X-Plane の油圧はいつも加圧され、脚・ブレーキ・ステアリングの油圧による制限は、それぞれの作り直しでモデルの出力を使って入れる。X-Plane の故障メニューの漏れ（`rel_hydleak*`）は作動油量を減らす形で残した。
- 油圧の組み込みは作業用のローカルブランチ `wip/hyd-integration` で進め、X-Plane の試験が通ってから `overhaul` に 1 つのコミットにまとめて取り込んだ（朝に途中の状態の機体が読み込まれないように）。

## 決まったこと（2026-10-23 朝、利用者の回答）

PLAN.md §3 に書いた。要点：

- カスタム acf のパネルの変更（GAP_ANALYSIS.md §4）と `.snd` の警報音の結線の変更は承認。パネルは系統ごとの作業で、CLAUDE.md の手順（バックアップ、前後の値、外観のスクリーンショット）に従って直す。純正 acf は変えない。
- 機体側は 109 を基準、エンジン側はエンジン型式で選ぶ。`freighter` は貨物機の項目を 405・570 から。RR は PW と同じ扱いで残す。
- 推定で作った値（下の一覧）は承認。「推定」の印は残す。
- カスタム acf と `747-400_custom.snd` は git に入れた（936222b0）。`overhaul` は origin に push してよい。
- FlyWithLua の `please read the manual.lua` は利用者が消した。

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
- 乗員への警報（1-3。`B747.87.alert_model.lua`・`B747.87.xt.alerts.lua` に「estimate」と書いてある）：
  - モデルを回す周期 0.1 秒（資料に値が無い。前は約 2 秒ごと）。EIU が電源投入から 4 秒で動き出すのは前の値のまま。
  - 始動中の抑止の終わりの「アイドル到達」：N2 60 %（CF6 の min idle は 61.6 %：ATA70_80 p.206。PW の値は資料に無い）。
  - 離陸の抑止は、地上で 30 kt 未満になった後の離陸滑走でだけ働く（着陸滑走で 80 kt を逆向きに通るのを離陸と取らないため）。
  - CONFIG GEAR のサイレンは master リセットで止まらない方にした（原因がレバーかフラップかを、メッセージだけでは区別できない。FCOM p.1551）。
  - wailer は >AUTOPILOT DISC の表示中、最低 1 秒（表示を消すのは AP の側）。
  - beeper のある advisory（BLEED ISLN L・R、BLEED HP ENG）の beeper は、caution と同じ抑止（始動前・離陸・着陸など）で待たせる（FCOM に記載なし）。
  - memo が最後のページに入りきらないときは、memo だけのページを作る（FCOM に記載なし）。
  - 火災ハンドルを「引いた」とみなすのは、動きの途中の値 `pos_arm` が 0.5 を超えたとき。
- 油圧（1-4。`B747.19.hyd_model.lua` に「estimate」と書いてある）：
  - 舵面などが「油圧で動く」とみなす圧 1000 psi（資料に無い。前のコードは 900 と 1000）。
  - demand pump の圧力スイッチの解除 1600 psi（EDP の値を流用）。ADP の 10 秒タイマーは「空中でフラップが上がってから 10 秒運転を続ける」とした（論理図からタイマーの種類が読めない）。
  - HYDIM-3・4 と ACMP 3 の制御の DC バス、ADP 1＝左ダクト・4＝右ダクト（資料の 1・2 系統の図からの対称）。
  - EDP の流量は N2 に比例。EDP を減圧するソレノイドは DC bus n（バスは資料に無い）で、DC が無いと加圧する。
  - 系統の漏れ 0.5 gpm、ADP のタービンが要るダクト圧 5〜15 psi、圧の立ち上がり 0.5 秒・減衰 4 秒、accumulator の充圧 1 秒。
  - 油温：ポンプが回っていれば外気温 ＋30 ℃ に 600 秒で近づく（FCOM の例が 50 ℃）。リザーバの与圧は抽気が無くなってから 300 秒で抜ける。
  - ブレーキ源の系統 2 の切替圧 1500 psi。accumulator の計器は予圧 750 psi より下がらない。HYD CONTROL 1・4 は HYDIM 1・4 の電源喪失で出す。
  - 組み込み（`B747.19.xt.hyd_power.lua`）：舵面が差し引いた圧（前からの作り）を流量に直す係数 0.03 gpm／(psi/s)、パーキングブレーキを 1 回掛けるのに accumulator から使う作動油 20 in³、フラップが「動いている」「出ている」とみなす角度 0.2°・0.5°。
  - エンジン始動中、EDP の圧は N2 が 10 % 前後で立ち、ENGINE PRESS 灯が消える（上の推定「流量は N2 に比例」「漏れ 0.5 gpm」の結果。どの回転で消えるかは資料に無い）。
- 空圧（1-5。`B747.55.bleed_model.lua` に「estimate」と書いてある。資料に式も値も無い部分）：
  - 流量は「パック 1 台＝1」の単位。エンジン 1 基が出せる量は N2 50 % で 0、90 % で 4.0（idle の 65 % で 1.5、70 % で 2.0。FCOM p.183 の「クロスブリード始動は供給側を 70 % N2 に」に合わせた）。APU は 42 psi・3.2（3 パックは賄えるが 3 パックと始動は賄えない：FCOM p.895）。地上空気 3.0。使う側はスターター 1.8、主翼防氷 0.5、ADP 0.3。
  - ダクト圧は、使う量が出せる量いっぱいのとき 30 % 下がり、超えると（出せる量／使う量）² で下がる。ダクト圧の遅れ 1 秒。
  - エンジン側の圧（PRV の下流）は N2 25 % で 0、65 % で 60 psi。PRSOV の調圧 45 psi は資料の値（LH36 p.64）。
  - 始動に要るダクト圧は、海面で 25 psi、1,000 ft ごとに 1 psi 下げる（FCOM p.183 の地上空気 30 psi から）。始動弁は、そのスターターの流量を足してもダクト圧がこれを満たすなら開き、始動の指令が終わるかダクト圧が 10 psi 未満になるまで開いたまま。スターターの流量は始動弁が開いているエンジンの分だけ数える（START を何本引いても、空気が足りる分だけ開く）。
  - ISLN と APU 弁が動く時間 2 秒。モーターの電源（AC）が無いと、その位置で止まる（LH36 p.86-87 に記載なし。GAP の推定のとおり）。APU 弁は、制御の DC bus 2 が無いと閉じる方へ動く（資料に記載なし）。
  - エンジンの HPSOV・PRV・PRSOV は、ASCTU の DC bus が無いと最後の位置のまま（ラッチ式のソレノイド。ATA30_32_35_36 p.20・p.66 の記載どおり）。電源が戻ったら、スイッチの位置に合わせて動く（実機の ASCTU はスイッチが変わったときにパルスを出すので、電源が無い間にスイッチを動かした場合は違いうる。簡略化）。
  - HPSOV は N2 85 % 未満で開（高圧段との切替の近似。ダクト圧には効かせていない）。
  - PRSOV と始動弁の動きの見かけ（アニメーションの速さ 20）は前のまま。

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

## 警報（1-3）の GAP の状態

| ID | 状態 |
|---|---|
| WARN-01 CANC 後の新しいメッセージ | 済（メッセージごとの CANC 済みの印） |
| WARN-02 サイレンの結線 | 一部。Lua 側の要求（`warning_siren`・`warning_bell`・`warning_wailer`。リセットの可否つき）は済。`.snd` はまだ master WARNING 灯でサイレンを鳴らす（`.snd` の変更は承認待ち） |
| WARN-03 bell | 一部。Lua 側の要求は済（master リセットで止まる）。`.snd` は X-Plane の火災 annunciator のまま。FIRE APU・CARGO などのメッセージ自体は火災（3-4）で |
| WARN-04 caution ごとの beeper | 一部。caution ごとの 1 秒の `master_caution_audio` は済（`747-400_XP11.snd` が使う）。beeper のある advisory（BLEED ISLN L・R、BLEED HP ENG。FCOM p.619）も同じ合図を出す（master CAUTION は点けない）。`747-400.snd` は master CAUTION の立ち上がりで鳴らすまま（承認済み、これから） |
| WARN-05 抑止 | 一部。始動前・始動中・離陸・着陸は済。他のメッセージによる抑止（notes/ATA-31-warning.md §4.4.1）と時間遅れは各系統で。STATUS cue はパネルが要る |
| WARN-06 表のレベル | 済（表の `level`） |
| WARN-07 文言・添字 | 一部。文言は済。memo の添字の重複（41）と init 側の表（配列の大きさを決めている）は残した |
| WARN-08 足りないメッセージ | 未（各系統の作り直しで） |
| WARN-09 ページ割り | 済。ただしパネルが描くのは 2 ページまでで、2 ページのときの PG はパネルの変更が要る |
| WARN-10 更新の遅れ | 済（0.1 秒ごと） |
| WARN-11〜21 | 未（形態警報・速度・高度警報・失速・GPWS などは、それぞれの作り直しで） |
| WARN-22 警報系統の電源 | 一部。EIU は新しい電源のバス（1-1）。MAWEA とスピーカーの電源は分けていない |
| WARN-23 quick start の未定義の global | 未 |

## 油圧（1-4）の GAP の状態

| ID | 状態 |
|---|---|
| HYD-01 EDP の圧 | 済（圧力補償型、流量は N2 に比例、fire switch・SOV・スタンドパイプ） |
| HYD-02 demand pump の AUTO | 済（1400/1600 psi、0.3/14 秒、CUTOFF、系統 1・4 のフラップ） |
| HYD-03 demand pump の電源・抽気 | 済（DC の制御と HYDIM、AC bus 2・3、ダクト圧。電気の負荷は電源モデルに入れていない） |
| HYD-04 AUX | 済 |
| HYD-05 fire switch | 済（SOV 閉、EDP 減圧、demand pump 起動） |
| HYD-06・07 舵面の系統の組 | 済（upper rudder 1+3、L INBD AIL 1+3、R OUTBD AIL 3+4、spoiler 8） |
| HYD-08 漏れ故障の取り違え | 済（故障ごとに系統を 1 回だけ選ぶ） |
| HYD-09 ブレーキ源 | 一部。源の選択・accumulator・>BRAKE SOURCE は済。ブレーキの効きを源で制限するのは脚・ブレーキ（4-2）で |
| HYD-10 accumulator | 済（系統 4 だけが充圧、予圧 750 psi） |
| HYD-11 舵面以外の負荷 | 未（各系統の作り直しで、負荷の表を使う） |
| HYD-12 ステアリング | 未（脚・ブレーキで） |
| HYD-13 X-Plane の油圧への干渉 | 済（故障を書かない） |
| HYD-14 P5 の灯 | 済 |
| HYD-15 EICAS | 済（抑止を含む） |
| HYD-16 作動油量 | 済（乱数をやめ 1.00 から。RF は地上だけ） |
| HYD-17 油温 | 一部（ポンプ運転で上がる一次遅れ。燃料の冷却は無し） |
| HYD-18 リザーバ与圧 | 一部（モデルにはある。表示はパネルが要る） |
| HYD-19・20 synoptic・STATUS の表現 | 未（パネルが要る） |
| HYD-21 スタンドパイプ | 済 |
| HYD-22 FLT CONTROL HYD POWER | 未 |
| HYD-23 カスタム acf の舵面別割り当て | 未（要確認） |

## 空圧（1-5）の GAP の状態

| ID | 状態 |
|---|---|
| PNEU-01 需要と供給 | 済（区画ごとに使う量と出せる量からダクト圧。値は推定） |
| PNEU-02 エンジンの弁 | 済（HPSOV・PRV・PRSOV、逆流防止、始動時の逆流、始動弁が閉じてから PRV が開くまで 15 秒、過熱ラッチとスイッチでのリセット、>BLEED n OFF は N2 50 % 以上）。高圧段との切替は近似 |
| PNEU-03 故障と警報 | 一部。過熱（SYS FAULT、BLD n OVHT/PRV）はモデルにあるが、つなぐ故障がまだ無い（X-Plane に相当する故障が無い）。過圧の BLEED n、BLEED HP ENG、BLD DUCT LEAK は未（故障の入れ方と、火災・過熱検知 3-4 で） |
| PNEU-04 BLEED ISLN と VALVE 灯 | 済（弁は 2 秒で動く。VALVE 灯は移動中と不一致。10 秒の不一致で BLEED ISLN L・R、>BLEED ISLN APU）。BLEED ISLN の beeper は警報モデルの側で（下の「気づいたこと」） |
| PNEU-05 APU 弁 | 済（APU RUNNING＝N1 95 % ＋ 2 秒、セレクタ OFF で閉、AC bus 2 のモーター、DC bus 2 の制御）。APU の消火ハンドルは 3D に無い（火災 3-4 で） |
| PNEU-06 ISLN の電源 | 済（L は AC bus 1、R は AC bus 3。電源が無いと止まる） |
| PNEU-07 地上空気 | 一部（モデルに入力はある。つなぐ操作が無い。FMC の地上作業ページに足す案） |
| PNEU-08 始動の空気 | 一部。空気の側は済（APU で 3 パックのままでは始動できない、クロスブリードは供給側 70 % N2）。スターターの回り方がダクト圧に依らないのはエンジン（2-3、ENG-38）で |
| PNEU-09〜11 表示 | 未（ダクト圧の表示条件と ECS synoptic。パネルの変更で） |
| PNEU-12 GE の逆推力の抽気 | 未（エンジン 2-3 で） |
| PNEU-13 EEC の抽気補正 | 未（エンジン 2-3 で） |
| PNEU-14 X-Plane の抽気 | 一部（X-Plane には `bleed_air_mode` だけを書く：ダクトに空気があれば 5、無ければ 0。X-Plane の isolation valve は mode に連動するので書かない。抽気による推力の損失は X-Plane の計算のまま） |

## 気づいたこと（作業の途中で）

- **X-Plane 自身の抽気の mode と isolation valve は連動している**：X-Plane（acf は `_has_full_bleed_air 0`）は、`bleed_air_mode` を 4（APU）にすると isolation valve を両方閉じ、5（auto）と 2 で両方開け、0 で両方閉じる。片方の弁を閉じると mode は 0 になる（Web API で確かめた）。1-5 の組み込みの最初の版は、APU だけのとき mode 4 を書いた。そのため X-Plane のエアスターターに APU の空気が届かず、カスタム acf の `s00` で 4 発とも回らなかった（モデルの始動弁は開いていた。X-Plane の弁を Web API で開けると回り出した）。前のコードも mode を書いていたが、読まずに書いていたので最初の 1 回しか届かず、毎フレーム読んで書いていた isolation valve の方が効いて、結果として弁が開いていた。グルーは mode だけを、ダクトに空気があれば 5、無ければ 0 にする。`s00`・`s05` に X-Plane の mode と弁の確認を足した。
- **XTLua は X-Plane の dataref への書き込みをキャッシュと比べる**：読むと次のフレームでキャッシュを X-Plane から読み直し、書くとキャッシュと違うときだけ次のフレームで 1 回 X-Plane に渡す（XTLua のソース xpmtdatarefs.cpp）。読まずに同じ値を書き続けると、X-Plane が値を変えた後は直らない（Web API で cross tie を 0 にすると、毎フレーム 1 を書いている電源のグルーが戻さなかった）→ X-Plane の dataref は毎フレーム読んで、違うときだけ書く（ARCHITECTURE.md §9a、TESTING.md §1.2）。電源のグルー（X-Plane の cross tie・バッテリー・GPU・APU 発電機・発電機）は読まずに書いているので、別のコミットで直す。
- `s00` の始動は AUTOSTART OFF のままの手動始動（START を引き、N2 20 % で FUEL CONTROL を RUN）。AUTOSTART ON のときは、START を引くと始動弁は準備だけで、FUEL CONTROL を RUN にすると EEC が開く（FCOM p.879）。新しい空圧のモデルはこれに従う。AI の自動始動（B747.95.xt.AI）は AUTOSTART ON・パック OFF で「START → すぐ RUN」なので、この順で動く。
- **advisory なのに beeper が鳴るメッセージ**：FCOM p.619（2.50.1）の表では、BLEED ISLN L・R と BLEED HP ENG 1〜4 は「Advisory、Beeper」（改訂で足された行）。警報モデルは beeper を caution にしか鳴らさなかったので、advisory の beeper を足した（master CAUTION は点けない）。テキスト化した FCOM では、ほかにも「Advisory Beeper」に見える行（>CREW OXY LOW、ENG EEC MODE、ENG START VLV、IRS MOTION、UNABLE RNP）があるが、原本のページ（p.545、p.899、p.902、p.1430）では列のずれで、beeper は無い。
- **ピトー加熱がエンジンの抽気圧を見ている**：防氷モジュールは、どれかのエンジンの `bleed_air_psi` が 12 psi を超えることを「エンジン運転中」の代わりに使っている。新しい空圧では PRV が閉じると 0 になるので、4 基とも ENGINE BLEED が OFF（NAI も OFF）だとピトー加熱が切れる。始動のときも、始動弁が閉じてから PRV が開くまでの 15 秒だけ遅れる。防氷（3-2）で「エンジン運転中」に直す。
- P5 の抽気パネルは機長の目の位置から遠く、斜めにしか見えない。試験キットの視点に視野角を足し、`bleed`（pitch 19、heading 70、視野角 25°）で灯が読めるようにした。視野角は次の視点とシナリオの終わりで元に戻す。

- **EICAS に出るメッセージが増えた（1-3 の後）**：前の表示は実質 1 ページ（11 行）分しか正しく出せず、2 ページ目に回ったものが見えていなかった（WARN-09）。1-3 の後は、立っているものがすべて並ぶ。例：純正 acf の `s00` の APU 始動後に、HYD PRESS SYS 2・3（demand pump の OFF で系統 2・3 が無圧）、>BRAKE SOURCE（系統 1・2・4 が低圧）、>YAW DAMPER LWR・UPR（ヨーダンパーのスイッチ OFF）、>X FEED CONFIG が加わって 20 行・2 ページ。各系統が立てている状態は前と同じ。パネルは 2 ページ目の番号（PG）を出せないので、2 ページ目があることは画面では分からない（承認待ち）。
- **空中開始の試験（`s01`）は、機体の読み込み方で結果が変わる**：フライトの開始で機体が読み込まれたとき（03:45）は A/T が入り、A/P が機首上げを 13 秒ほどで立て直した。フライトを開始してから読み直したとき（04:59）は、読み直すまでの 20 秒に前の状態で飛んで失速し、急降下から始まった。読み直してからフライトを開始したとき（05:06）は A/T が入らず、ピッチ 35°・17,700 ft まで上がった。最後のものは古い油圧でも同じ（05:14）なので、油圧の組み込みとは関係ない。空中開始の AFDS の初期化（A/T と A/P のモード）の問題で、AFDS の作り直しで扱う。それまでは `s01` は X-Plane を起動し直した後の最初のフライト（機体が読み込まれる）で回す。
- 純正 acf として比べるのは `747-400.acf`（XP12）。カスタム acf はこれを元にしている（ACF_DIFF.md）。
- カスタム acf の新しい外部オブジェクトが参照するテクスチャ 4 枚（`Exterior_Wiper.png`・`Exterior_Detail.png`・`Exterior_Detail_2.png`・`Exterior_cargo.png`）が無い（Log.txt）。3D 一式の問題で対象外。
- Web API でフライトを開始しても、同じ機体なら機体は読み直されない（Log.txt に `Loading airplane` が出ない）。系統の状態は前のフライトから続く。試験で真っさらな状態が要るときは `-Reload`。
- Web API の `/flight` は、機体の読み込みに 2 分以上かかる間、応答しない。
- X-Plane のスクリーンショットは、シムが一時停止や読み込み中だと撮れず、動き出してからまとめて保存される。
- 今の機体を Web API の「エンジン停止」で開始すると、BATTERY は ON、STANDBY POWER は AUTO、燃料制御スイッチは RUN（エンジンは止まっている）になる。
- **X-Plane が止まった件（02:26 ごろ）**：カスタム acf から純正 acf へ Web API で切り替え、すぐ機体の読み直しを送った後、X-Plane が「応答なし」になった（CPU は約 2 コア分使い続け、sim の時計が止まり、Web API だけ答える）。10 分待っても戻らず、Log.txt を `runs/20261023_022542_..._747-400/Log_hung.txt` に残して強制終了した。起動し直した後は、純正 acf でもカスタム acf でも問題なく動いた。
  - 原因は分からない。Log.txt には誤りが出ていない。カスタム acf の読み込みでは、GPU のメモリ（RTX 3070、8 GB）の予算超過の警告が出ている（`Memory heap 0 has overstepped its budget`）。acf を何度も切り替えると、メモリが足りなくなるのかもしれない（推定）。
  - 対策：`-Reload` は Log.txt に新しい読み込みが出るのを待ち、出なければ送り直す。`run_scenario.ps1` は sim の時計が 30 秒動かなければやめる。acf を切り替えるときは、必要なら X-Plane を起動し直す。
  - **2 回目（03:42 ごろ）**：X-Plane を起動し直した直後の最初のフライト（カスタム acf を読み込み）で、`s01` の `"reload": true` により読み直しを送った直後に、同じく応答なしになった。Log.txt は機体の読み込み完了（state_Normal）で止まっている。2 回とも「読み込んだ直後の読み直し」が共通なので、`run_scenario.ps1` は、フライトの開始で機体が読み込まれたときは読み直さず、読み直すときも sim の時計が 20 秒進んでから送るようにした。その後の実行（`s01`・`s02`）では起きていない。
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
- 2026-10-23 03:30：電源の組み込みをコミット（f38d0baf）。X-Plane を起動し直し、純正 acf で `s00` 64/64、`s02` 63/63（PSEU の地上の確認を含む）。
- 2026-10-23 03:41：空地判定（PSEU）のモデルと組み込みをコミット（8a7632aa）。
- 2026-10-23 03:42：X-Plane が 2 回目の応答なし（上の「気づいたこと」）。`run_scenario.ps1` を直し、起動し直してカスタム acf で `s01` 15/15（PSEU の air、BCU の air mode を含む）。
- 2026-10-23 03:52：警報の枠組みのモデルと試験 69 件をコミット（001f345e）。カスタム acf で `s02` 63/63（PSEU の地上の確認を含む）。Lua の誤りなし。
- 2026-10-23 03:57：試験ランナーの読み直しの修正と進み具合をコミット（66ca7677）。
- 2026-10-23 04:0x〜：警報の組み込み（1-3 の 2 段目）。モデルに音の要求・caution ごとの beeper・CANC 済みの報告を足し、グルー `B747.87.xt.alerts.lua` を新設、古い待ち行列と表示を外した。CANC/RCL と master リセットは押した回数の dataref で渡す。表のレベルと文言を FCOM に合わせた。試験：モデル 94 件、モジュール 41 件。
- 2026-10-23 04:20〜：X-Plane で `s03_alerts`（新シナリオ）。1 回目は Web API の長さ 0 のコマンドで押しボタンが押されたままになり 25/26（TESTING.md §4.6）。0.2 秒押す形に直してカスタム acf 26/26、純正 acf 26/26。純正 acf の `s00` 64/64。
- 2026-10-23 04:4x：警報の組み込みをコミット（2e0b4cda）。カスタム acf の `s00` も 64/64。油圧（1-4）のモデルと試験 94 件。
- 2026-10-23 05:0x〜：油圧の組み込み（1-4 の 2 段目）を作業用ブランチ `wip/hyd-integration` で。カスタム acf で `s04_hydraulics`（新シナリオ）29/29。`s01` の機首上げを切り分け（上の「気づいたこと」）。
- 2026-10-23 05:2x〜05:4x：X-Plane を起動し直し、油圧の組み込みを両方の acf で確認。カスタム acf：`s01` 15/15（古い油圧の 03:45 とほぼ同じ飛び方）、`s00` 64/64。純正 acf：`s04` 29/29、`s00` 64/64。Lua の誤りなし。`overhaul` に 1 つのコミットで取り込み、作業用ブランチは消した。
- 2026-10-23 07:4x：利用者の回答（承認待ちの件）を PLAN.md §3・CLAUDE.md に記録（fc2635ed）。カスタム acf と `747-400_custom.snd` を git に入れた（936222b0）。`overhaul` を origin に push。
- 2026-10-23 07:5x〜：空圧（1-5）。モデルと試験、空調モジュールへの組み込み（前の抽気のコードを外した）、モジュールの試験。カスタム acf で `s05_bleed`（新シナリオ）41/41。試験キットの視点に視野角を足し、P5 の抽気パネルの VALVE 灯・OFF 灯を画像で確認。
- 2026-10-23 08:1x〜08:4x：カスタム acf の `s00` で 4 発とも回らず（46/60）。原因は X-Plane 自身の抽気の mode と isolation valve の連動（APU の mode で弁が閉じる）で、XTLua の書き込みのキャッシュの仕組みも XTLua のソースで確かめた（上の「気づいたこと」）。グルーは X-Plane に mode だけを書くようにした。見直しの中で、DC が切れたときの弁のラッチ（ATA30_32_35_36 の記載どおり）と、START を何本も引いたときにダクト圧が 10 psi の境目で揺れるのも直した。FCOM p.619 で BLEED ISLN の beeper を見つけた。
- 2026-10-23 08:4x〜09:0x：カスタム acf で `s05` 45/45、`s00` 67/67（始動の時間はベースラインと同じ）、`s04` 29/29。Lua の誤りなし。
