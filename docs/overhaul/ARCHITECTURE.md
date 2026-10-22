# コード構成（ARCHITECTURE）

対象は `overhaul` ブランチの出発点＝本家 mSparks43/747-400 master `041c9ffa`（2026-09-10、「Release XP12.4.3-2026/09/10 milestone」の直後）。2026-10-23 に調べた。行数はコメント込み。

## 0. 前提

- 機体は Sparky744（本家 README：CC BY-NC 4.0）。この PC の X-Plane は 12.4.4-b5（Log.txt、2026-10-22）。
- フォルダの acf：
  - `747-400.acf`：XP12 形式の純正 acf。**比較用。変更しない**
  - `747-400_XP11.acf`：XP11 形式
  - `747-400LCF.acf`：Dreamlifter
  - `747-400_custom.acf`：利用者のカスタム acf（未追跡。開発と試験の基準）
  - 違いは [ACF_DIFF.md](ACF_DIFF.md) にまとめた。
- 作業ツリーには、git に無いローカルの 3D 一式がある。72 ファイルは skip-worktree を付けてあり、`git ls-files -v | grep "^S "` で一覧できる。退避先は `D:\747-400-local-assets\`（README.txt 参照）。新しいオブジェクト約 200 個は未追跡のまま。

## 1. プラグイン

| フォルダ | 種類 | 役割 |
|---|---|---|
| `plugins/xtlua` | XTLua（1つめ） | 一般系統：スイッチ類、電源、ギア、無線、燃料、火災、エンジン、EEC、操縦系統、防氷、EICAS 警報、quick start |
| `plugins/xtlua_keysystems` | XTLua（2つめ） | 油圧、air（空調・抽気・与圧）、飛行計器、FMC/CDU、AFDS・autothrottle、照明 |
| `plugins/xtlua_nd` | XTLua（3つめ） | ND の地図データ |
| `plugins/xtlua_fdr` | XTLua（4つめ） | flight data recorder（解析用の記録） |
| `plugins/AutoATC` | 設定のみ | AutoATC の音声コマンド定義（`voice commands/voice_control.json`）。AutoATC 本体は別途インストール |

- XTLua の各インスタンスは同じ構成になっている。
  - `64/{win,lin,mac}.xpl`：本体。4つとも同じバイナリで、**手を入れない**。
  - `init.lua`・`init/init.lua`：グルーコード。
  - `init/scripts/<モジュール>/`：dataref とコマンドを**作る**側。`deferred_dataref`・`deferred_command` で、XLua の API を呼ぶ。
  - `scripts/<モジュール>/`：ロジック側。ファイル名に `.xt.` が入る。
- ロジック側は `find_dataref`・`deferred_dataref`・`replace_command`・`wrap_command` と、`run_timer` などのタイマーを使う。コールバックは `aircraft_load`・`flight_start`・`livery_load`・`before_physics`・`after_physics`・`aircraft_unload`。
- XTLua の仕組み（README：https://github.com/mSparks43/XTLua 、2026-10-23 確認）：
  - XLua を改造したもので、`before_physics` と `after_physics` をワーカースレッドで実行する。
  - `create_dataref` と `create_command` は `init/scripts/` の中でしか使えない。
  - dataref は flight model の 1 フレームに 1 回、X-Plane と同期する。読みは使った dataref だけ取りに行き、書きは X-Plane に**非同期で**反映される。書いた値をすぐ判定に使うときは、いったんローカル変数に入れる。
  - コマンドの handler は phase（0 押下、1 保持、2 解放）と duration を受け取る。`start()` には必ず `stop()` を対にする。
  - `after_physics` は、ポーズ中とリプレイ中以外の毎フレーム呼ばれる。
  - `print()` は Log.txt に `LUA:` 付きで出る。Developer メニューからスクリプトを再読み込みできる。
  - global のテーブルで不具合が出ることがある（XTLua issue #4）。旧フォークでも、メタテーブルなしの global テーブルで止まる事例があった（OLD_FORK_NOTES.md §14）。
- XTLua 本体が出す特別な dataref：`xtlua/fms`（X-Plane の FMS の飛行計画を JSON で）、`xtlua/navaids`、`xtlua/fltpln`、`xtlua/loadtoFMS`、`xtlua/currentFMS`、`xtlua/currentFMSID`、`xtlua/xpFMSData`、`xtlua/controlObject`。
- 外部との連携：
  - AutoATC と Hoppie（ACARS・CPDLC）
  - Avitab（`B747.xt.Avitab`）
  - Terrain Radar（`*.acf.terrain_radar_descr`）
  - librain（`objects/librain`）
  - FMOD（`fmod/*.bank`・`*.snd`）
- FlyWithLua NG+ 2.8.19 は、2026-10-23 に利用者が X-Plane に導入した（`Resources/plugins/FlyWithLua/`）。機体はこれに依存しない。飛行試験キットだけが使う（TESTING.md）。

## 2. スクリプト一覧（モジュール単位）

行数は「init 側 / ロジック側」。override は X-Plane の `sim/operation/override/*` のうち、そのモジュールが取るもの。

| プラグイン | モジュール | 行数 | 内容 | override |
|---|---|---|---|---|
| xtlua | B747.01.manipulators | 400 / 2419 | 操縦室のスイッチ・ボタン・ノブのコマンド（`button_switch`、`toggle_switch`）。防護カバー、ドアハンドルなど | |
| xtlua | B747.03.electrical | 164 / 1065 | 電源。init 側ヘッダの説明（4 つの main bus はすべての bus tie が閉じたときだけ同時に通電）は古い。今のコードは X-Plane の `cross_tie` を毎フレーム 1 にして全バスを一体で扱い、バスごとの状態は表示用のフラグしかない（notes/ATA-24.md） | GPU_volts |
| xtlua | B747.05.simconfig | 55 / 567 | 機体設定（エンジン型式、単位、音など）。リバリーごとの `B747-400_simconfig.dat`（JSON）を読み書きする。`version.lua` を含む | |
| xtlua | B747.10.gear | 165 / 1061 | 脚の上げ下げ、ブレーキ、オートブレーキ | toe_brakes |
| xtlua | B747.15.com | 565 / 3862 | 無線。ACP（`ap_L/C/R`）、RTP（`rtp_L/C/R`）、VHF/HF、call panel など | |
| xtlua | B747.25.fuel | 405 / 3720 | 燃料系統（タンク、ポンプ、クロスフィード、移送、ジェティソン、搭載量） | fuel_system |
| xtlua | B747.35.fire | 99 / 653 | 火災探知と消火（エンジン、APU、貨物室） | |
| xtlua | B747.40.engines | 106 / 2247 | エンジン始動・点火・燃料制御・逆推力・APU | |
| xtlua | B747.42.EEC | 67 / 4376 | EEC と推力制御。型式別の `EEC.PW` / `EEC.GE` / `EEC.RR`、表（`EEC.tbls`）、`pid.lua` | throttles |
| xtlua | B747.45.fltCtrls | 187 / 1370 | 操縦系統（フラップ、スポイラー・スピードブレーキ、トリム、代替フラップ） | |
| xtlua | B747.50.antiice | 86 / 663 | 防氷・防雨（主翼・ナセル防氷、ウインドウ・プローブ加熱、ワイパー） | |
| xtlua | B747.85.safety | 79 / 378 | サイン類（No Smoking、Seat Belts）、チェックリストの印 | |
| xtlua | B747.87.warning | 649 / 1163 | EICAS メッセージ（`laminar/B747/CAS/gen_{warning,caution,advisory,memo}_msg_NNN`）、master warning/caution、警報音 | |
| xtlua | B747.95.AI | 0 / 2709 | quick start（系統ごとの `laminar/B747/ai/*_quick_start`）。旧 B738 の流用 | |
| xtlua | B747.99.VRcontrols | 375 / 0 | VR 用の操作（init 側のみ） | |
| xtlua | Avionics・B747.Avitab | 5 / 130 | 補助（発電機の電流など）、Avitab の連携 | |
| xtlua_keysystems | B747.19.hydraulicsmodel | 186 / 2116 | 油圧 4 系統のモデル、舵面の駆動とステアリング（`hydraulics_override`）。同じ名前空間に AFDS の制御則（`afds_control`）・ヨーダンパー（`yaw_damper`）・スラット（`slats`）。R-1 で `hydraulics_override` から分けた（§2.1） | control_surfaces、wheel_steer |
| xtlua_keysystems | B747.20.hydraulics | 92 / 555 | 油圧パネルと表示 | |
| xtlua_keysystems | B747.30.fltMgmt | 112 / 452 | IRU のモードセレクタ、トランスポンダのパネル | |
| xtlua_keysystems | B747.55.air | 170 / 1220 | 空調パック、抽気、与圧、温度 | |
| xtlua_keysystems | B747.60.fltInst | 459 / 4716 | 飛行計器。`fltInst02` が PFD・EICAS・ND 補助・表示切替（`dsp`）、`03`・`04` が時計 | |
| xtlua_keysystems | B747.68.fms | 199 / 13196 | FMC/CDU（3 台、詳細は §6） | |
| xtlua_keysystems | B747.70.autopilot | 274 / 5449 | AFDS（MCP、FMA、LNAV/VNAV）、autothrottle、autoland（`B747.autoland`）、監視（`monitor`） | throttles、fms_advance |
| xtlua_keysystems | B747.90.lighting | 215 / 2403 | 照明（計器、フラッド、外部灯）、気象レーダーの表示操作（`wxr`） | |
| xtlua_nd | B747.61.nd | 532 / 1314 | ND の地図。ウェイポイント、航法施設、シンボル（`laminar/B747/nd/*`、633 個） | |
| xtlua_fdr | B747.01.fdr | 34 / 1038 | flight data recorder。モード変化のマーカー（`laminar/B747/fdr/*`）、解析用の記録 | |

### 2.1 R-1 で動かしたコードの行番号

notes と GAP_ANALYSIS.md の行番号は R-1 の前（041c9ffa）のもの。`B747.19.xt.hydraulics_override.lua` の行は、次のとおり移った（フォルダは `plugins/xtlua_keysystems/scripts/B747.19.xt.hydraulicsmodel/`。中身は変えていない）。

| 元の行 | 移った先（行） | 中身 |
|---|---|---|
| 1–17 | `hydraulics_override` 1–17 | 先頭のコメント |
| 18 | `hydraulicsmodel` の `dofile` の並び | `dofile("pid.lua")` |
| 20–21 | `afds_control` 6–7 | AFDS のモード枠の dataref |
| 22–341 | `hydraulics_override` 18–337（元 − 4） | 油圧の消費、舵面の出力 |
| 342–368 | `slats` 4–30（元 − 338） | スラット |
| 369–391、399–403、405–425 | `afds_control` 8–30、31–35、36–56 | トリムの変数、FD の記録、ロール指令 |
| 393–398、404、426–432 | `yaw_damper` 5–10、11、12–18 | ヨーの記録、ヨーの入力 |
| 433–835 | `afds_control` 57–459（元 − 376） | ピッチ指令（FLCH・ALT・V/S・G/S・TO/GA）、ロールの平均 |
| 836–899 | `yaw_damper` 19–82（元 − 817） | ヨーダンパーの入力の平均 |
| 900–1040 | `afds_control` 460–600（元 − 440） | ピッチの平均、autotrim、ピッチ・ロールのサーボ（PID） |
| 1041–1103 | `yaw_damper` 83–145（元 − 958） | ヨーダンパーの則（PID） |
| 1104–1154 | `hydraulics_override` 338–388（元 − 766） | `flight_controls_override`（毎フレームの呼び出し、ステアリング） |

## 3. X-Plane 本体の機能との関係

- **自前で置き換えているもの**（コメントを除いて確認）：燃料系統、推力（スロットルを EEC が設定）、舵面（油圧モデルが操縦入力と AP の指令から舵角を決める）、前輪ステアリング、ブレーキ、FMS のポイント切り替え（LNAV）、GPU 電圧。`override_joystick_*` と `override_artstab` はコメントにあるだけで、使われていない。
- **X-Plane の機能を土台にしているもの**：
  - 電源：X-Plane のバスをすべて 1 つにつないだ簡略モデル。ほかのモジュールは「電源があるか」を `sim/cockpit2/electrical/bus_volts[0] > 0` で判定しており、これはバッテリーだけでも真になる（notes/ATA-24.md）。
  - エンジン：acf は `JET_2SPOOL`。始動・燃料・推力の指令は自前。
  - AFDS：X-Plane の autopilot の dataref（`sim/cockpit2/autopilot/*`。heading、airspeed、VS、alt hold・nav・G/S の status、servos）を書き、その上にモードロジックを乗せている。
  - FMC：X-Plane の FMS の飛行計画と航法データベース（`xtlua/fms`、`xtlua/navaids`、`sim/FMS/*` コマンド、`sim/cockpit2/radios/indicators/fms_*`）。
  - 空調・与圧：X-Plane の与圧 dataref も使う。
- 実機に近づけるときは、X-Plane の機能のどこまでを土台に残すかを系統ごとに決める必要がある。特に電源の簡略化は、実機の bus tie・split system breaker の論理と合わない。系統ごとの評価は GAP_ANALYSIS.md に書く。

## 4. 主要な dataref とコマンド

Lua が作る名前の数：dataref 1617 個、コマンド 628 個。静的に拾える分だけで、ループで作る名前は含まない。

| 名前空間 `laminar/B747/…` | dataref 数 | 主に作るモジュール |
|---|---|---|
| nd | 633 | 61.nd、60.fltInst、68.fms |
| fuel | 216 | 25.fuel |
| autopilot | 211 | 70.autopilot（42.EEC、19.hydraulicsmodel なども） |
| flt_ctrls | 137 | 45.fltCtrls、19.hydraulicsmodel |
| ap_L / ap_C / ap_R | 各 98 | 15.com（audio control panel） |
| hydraulics | 97 | 19.hydraulicsmodel |
| engines / engine | 84 / 27 | 40.engines、42.EEC、05.simconfig |
| airspeed | 84 | 60.fltInst、70.autopilot |
| comm | 74 | 15.com、68.fms |
| efis / air | 各 66 | 60.fltInst / 55.air |
| cablecontrols | 63 | 19.hydraulicsmodel（舵面ごとの指令） |
| electrical | 58 | 03.electrical |
| fltInst・flt_inst / clock | 52・48 / 40 | 60.fltInst |
| light / wxr | 46 / 26 | 90.lighting |
| fire / CAS / warning | 38 / 20 / 11 | 35.fire / 87.warning |
| gear / dsp / fmod / misc / flt_mgmt | 19 / 22 / 21 / 14 / 14 | 10.gear / 60.fltInst / 各所 / 01.manipulators / 30.fltMgmt |

- コマンドの多い名前空間：`button_switch`（185）、`comm`（156）、`toggle_switch`（88）、`flt_inst`（62）、`ap_L/C/R`（各 62）、`nd`（52）、`efis`（48）、`ai`（34）、`fdr`（30）、`autopilot`（30）。
- 名前を変えてはいけないものの一覧：[INTERFACES.tsv](INTERFACES.tsv)。3D オブジェクト・パネル計器（`DATAREF` 行と表示条件 `SHOW_EQUAL/LESS/GREATER`）・FMOD サウンド・AutoATC が参照する `laminar/*` の名前が 2029 個あり、内訳は dataref 1072、コマンド 537、実行時に作られる名前（または未定義）420。
- 機体設定のよりどころ：`laminar/B747/simconfig`（JSON 文字列）と `laminar/B747/newsimconfig`（更新フラグ）。エンジン型式は `laminar/B747/engines/type`（§7）。

### 4.1 電源の公開 dataref（1-1 で新設）

電源モデル（`plugins/xtlua/scripts/B747.03.xt.electrical/B747.03.elec_model.lua`）の出力。init スクリプト `B747.03.electrical` で作り、`B747.03.xt.elec_buses.lua` が毎フレーム書く。他の系統は、電源の有無をここで判定する（`sim/cockpit2/electrical/bus_volts` はバッテリーだけでも真になるので使わない）。値は 1 が通電・閉、0 が非通電・開。配列の添字は 0 始まり。中身は notes/ATA-24.md。

| 名前 `laminar/B747/electrical/…` | 型 | 中身 |
|---|---|---|
| `bus/ac` | array[4] | AC 1-4 |
| `bus/dc` | array[4] | DC 1-4 |
| `bus/utility`・`bus/galley` | array[4] | utility 1-4・galley 1-4（109。L UTILITY が 1・2、R が 3・4） |
| `bus/sync` | array[2] | 同期バス 左・右 |
| `bus/any_ac` | number | AC 1-4 のどれかに電源 |
| `bus/xfr_capt`・`bus/xfr_fo` | number | CAPT・F/O transfer bus |
| `bus/stby_main`・`bus/stby_apu` | number | main・APU standby bus |
| `bus/bat_main`・`bus/bat_apu` | number | main・APU battery bus |
| `bus/hot_bat_main`・`bus/hot_bat_apu` | number | main・APU hot battery bus |
| `bus/dc_tie` | number | DC tie bus |
| `bus/gnd_svc`・`bus/gnd_svc_util` | number | ground service bus・ground service utility bus |
| `bus/gnd_hdlg`・`bus/gnd_hdlg_dc` | number | ground handling bus・DC ground handling bus |
| `breaker/gcb`・`breaker/btb`・`breaker/dcir` | array[4] | GCB・BTB・DCIR 1-4 |
| `breaker/xpc`・`breaker/apb` | array[2] | XPC 1/2（EXT）・APB 1/2（APU GEN） |
| `breaker/ssb` | number | split system breaker |
| `idg_connected` | array[4] | IDG の drive が接続 |
| `air_mode`・`load_shed` | number | BCU の air mode・負荷制限の実行中 |
| `battery/volts`・`battery/amps` | array[2] | main [0]・APU [1] バッテリーの電圧と電流（+ 放電、− 充電） |
| `light/ext_avail`・`light/apu_avail`・`light/util_off` | array[2] | P5 の AVAIL・UTILITY OFF 灯 |
| `light/isln`・`light/gen_off`・`light/drive` | array[4] | P5 の ISLN・GEN CONT OFF・DRIVE 灯 |

- 前からある名前（`bus1hot`〜`bus4hot`、`topleftbus`・`toprightbus`、`ssb`、`utilityleft1/2`・`utilityright1/2`、`ext_pwr1_on`・`apu_pwr1_on` など、`laminar/B747/rel_esys`〜`rel_esys4`、`capt_display_power`・`fo_display_power`、`display_has_power[6-8]`、`apu_volts`）も、同じモデルから意味を保って書く（notes/ATA-24.md §6）。
- X-Plane の電気系統は代理として残す：`cross_tie` は 1、`battery_on[0]` は BATTERY スイッチ、`gpu_on` は XPC のどれか、`APU_generator_on` は APB のどれか、`generator_on[n]` は GCB n。

### 4.2 空地判定（PSEU）の公開 dataref（1-2 で新設）

空地のモデル（`plugins/xtlua/scripts/B747.10.xt.gear/B747.10.pseu_model.lua`）の出力。init スクリプト `B747.10.gear` で作り、`B747.10.xt.pseu.lua` が毎フレーム書く。他の系統は、空地をここで判定する（`sim/flightmodel/failures/onground_any` はどれか 1 輪の接地で真になる）。値は 1 が真。中身は notes/ATA-32.md §4.1。

| 名前 `laminar/B747/gear/air_ground/…` | 中身 |
|---|---|
| `pri_air`・`pri_gnd` | primary の AIR・GND（ATA29_32 p.322 の式。片側の主脚だけの接地では AIR のまま、左右とも接地で GND） |
| `alt_air`・`alt_gnd` | alternate の AIR・GND（故障を入れるまでは primary と同じ） |
| `ng_compressed` | 前脚圧縮（主脚とは別の信号。ペダルのステアリング、離陸警報、失速警報が使う） |
| `all_gear_down`・`nose_not_down` | ALL GR DN（5 本ともダウンロック）・前脚がダウンロックでない |
| `lever_unlock` | LG LVR UNLK（主脚トラック 4 本とも傾き、かつ胴体脚ステアリングがロック：FCOM p.1512） |

- 乗り換え済み：電源の BCU（air mode・APU 発電機・地上ハンドリングバス）、脚レバーのロック。ほかの系統は、それぞれの作り直しで乗り換える（PROGRESS.md）。

### 4.3 乗員への警報（1-3）

警報のモデル（`plugins/xtlua/scripts/B747.87.xt.warning/B747.87.alert_model.lua`）を、グルー `B747.87.xt.alerts.lua` が警報モジュール（`B747.87.xt.warning.lua`）の中で 0.1 秒ごとに回す。中身は notes/ATA-31-warning.md §3・§4。

- 入口は今までどおり：各系統は `laminar/B747/CAS/{warning,caution,advisory,memo}_status[n]` に 0/1 を書く。添字は変えていない。
- 表示のレベルはメッセージ表（`B747.87.xt.warning.lua` の先頭）で決まる。`level` があれば、配列とは別のレベルで出す（例：ENG FAIL は warning の配列に書かれるが caution）。
- 出口（名前と意味は変えていない）：

| dataref | 書くもの | 読むもの |
|---|---|---|
| `CAS/gen_{warning,caution,advisory,memo}_msg_NNN` | ページ p の n 行目を NNN = 11(p−1)+n−1 に、その行のレベルの名前の方に書く（他のレベルは空白 1 字） | パネル（000〜021 の 2 ページ分だけ） |
| `CAS/msg_page`・`num_msg_pages` | 見ているページ、ページ数 | パネル（PG は `num_msg_pages > 2` のときだけ） |
| `CAS/caut_adv_display` | 0＝CANC で隠した caution/advisory がある（RCL で 1） | なし |
| `warning/master_warning`・`master_caution` | master 灯 | 3D、FMOD（サイレンと beeper） |
| `warning/master_caution_audio` | master CAUTION を点けた caution ごとに 1 秒 | `747-400_XP11.snd` |
| `warning/warning_bell`・`warning_siren`・`warning_wailer` | FCOM の音の要求（リセットの可否を含む） | なし（音の結線の変更は承認待ち） |

- 押した回数（1-3 で新設、init スクリプト `B747.87.warning02`）：別のプラグイン・モジュールにあるスイッチを、警報モジュールに渡す。値は押すたびに 1 増える。

| 名前 | 増やす側 | 意味 |
|---|---|---|
| `laminar/B747/CAS/canc_count` | fltInst02 の CANC（`laminar/B747/dsp/canc_switch`、CDU の EICAS CTL ページからも） | ページ送り、最後のページで caution/advisory を隠す |
| `laminar/B747/CAS/rcl_count` | fltInst02 の RCL（`laminar/B747/dsp/rcl_switch`） | 隠したものを戻して 1 ページ目。RECALL の表示（`CAS/recall_ind`）は今までどおり fltInst02 |
| `laminar/B747/warning/master_reset_count` | manipulators の master リセット（`button_switch/warn_caut_capt`・`_fo`） | 両方の master 灯を消す。灯は manipulators もその場で消す |

### 4.4 油圧（1-4）

油圧のモデル（`plugins/xtlua_keysystems/scripts/B747.19.xt.hydraulicsmodel/B747.19.hyd_model.lua`）を、グルー `B747.19.xt.hyd_power.lua` が油圧モジュール（`B747.19.xt.hydraulicsmodel.lua`）の中で毎フレーム回す。中身は notes/ATA-29.md §2〜§4。

- 毎フレームの順：`B747_hyd_power()`（モデル）→ `pressure_input()`（舵面が使える圧＝モデルの系統圧）→ `flight_controls_consumption()`（舵面が動くたびに圧を差し引き、900 psi 未満の系統しか無い舵面は止まる。前からの作り）→ `pressure_output()`（残りを `pressure_n` に書き、差し引いた量を次のフレームのモデルの需要にする）。舵面とモデルの受け渡しは同じ Lua の状態の関数（`B747_hyd_power_psi`・`B747_hyd_power_left`）で、dataref の読み直しはしない。
- 書く dataref（名前と意味は前と同じ。notes/ATA-29.md §6.2）：`hydraulics/pressure_1〜4`（系統圧、psi）、`edp_pressure_n`・`dem_pressure_n`・`aux_pressure`（ポンプの出口圧）、`dem_mode_n`（セレクタ。-1 AUX、0 OFF、1 AUTO、2 ON）、`valve_n`（1＝供給遮断弁が開で EDP が ON）、`pressure_13`・`23`・`24`・`234`（synoptic の不作動の絵）、`res_n`・`restotal_n`（作動油量。正規量 1.00 の比）、`temp_n`（℃）、`indicators/hydraulic_pressure_1_2_4`（ブレーキ accumulator 計）、`EICAS2/stat/RF`・`LO`（[1]〜[4]）。
- 新設（1-4、init スクリプト `B747.19.hydraulicsmodel`）：`laminar/B747/hydraulics/light/eng_press`・`dem_press`・`sys_fault`（[0]〜[3]＝系統 1〜4）、`light/brake_source`。照明モジュールが P5 の ENGINE PRESS・DEMAND PRESS・SYS FAULT と機長側の BRAKE SOURCE の灯に使う。
- EICAS：caution 9（>BRAKE SOURCE）、40〜43（HYD PRESS SYS）、advisory 200・201（HYD CONTROL 1・4）、202〜205（HYD OVHT SYS）、206〜209（HYD PRESS DEM）、210〜213（HYD PRESS ENG）、218〜221（>HYD QTY LOW）。
- X-Plane の油圧は「常に加圧、故障を書かない」（notes/ATA-29.md §6.1）。`B747.20` はポンプの故障（`rel_hydpmp*`）を書かなくなった。X-Plane の漏れ故障（`rel_hydleak*`）は、グルーが作動油量を減らす形で受ける。

## 5. 表示系（PFD・ND・EICAS・CDU）

- 描画は、各 acf の末尾（`P` 行の後ろ）に埋め込まれた X-Plane の generic instrument で行う。数は 2850 個で、内訳は rotary 1164、text 709、pointer 293、needle 122、tape 85、rolling 24。
  - パネルのテクスチャ `cockpit_3d/-PANELS-/panel.png` に描き、3D コクピットの画面に貼る。
  - 画像は `cockpit_3d/generic/`（CRT Displays 1014 枚、EFIS、FMS Displays、Clocks、Radios）。
- 計器が読む laminar 系の dataref は、`DATAREF` 行と表示条件（`SHOW_EQUAL` 1622 か所、`SHOW_GREATER` 1700 か所、`SHOW_LESS` 1102 か所）を合わせて 1008 個（重複を除く）。`DATAREF` 行では ND が 1005 か所、engines が 281、CAS が 89、gear が 87 など。
- synoptic の色や状態は、表示条件として acf に直接書かれていることが多い（例：燃料量が 900 kg 未満で amber）。故障による表示の変化が出せないときは、パネルを直す必要がある場合がある。
- データを作る側：
  - PFD・EICAS の数値は主に `B747.60.xt.fltInst02`。
  - エンジン計器は `B747.40.xt.engines`・`B747.42.xt.EEC`。
  - EICAS メッセージは `B747.87.xt.warning`。表示行は `CAS/gen_*_msg_NNN` に文字列で出す。
  - ND は `xtlua_nd`（地図）と `fltInst02`（モード・レンジ）。
  - CDU は `B747.68.xt.fms` が `laminar/B747/fms1〜3/*` に行の文字列を出す。
- **制約**：表示の定義は acf の中にある。純正 acf は変えないので、表示を直すときは dataref の値で直すのが基本になる。計器の追加や変更はカスタム acf にしかできず、見た目に関わるので承認が要る。カスタム acf と純正 acf のパネル定義は、ADF の方位針 2 個の参照 index を除いて同じ。

## 6. FMC

- CDU は 3 台：`fms1`（左）、`fms2`（右）、`fms3`（中央）。キーはコマンド（例：`laminar/B747/fms1/ls_key/L1`、`.../func_key/legs`、`.../alphanum_key/A`）で、ループで作る。
- ページ：
  - `B744.fms.pages.lua`：共通部と多くのページ
  - `activepages/*.lua`：動くページ（PERF INIT、POS INIT、TAKEOFF、THRUST LIM、PROGRESS、VNAV、DOORS、EFIS/EICAS CTL、地上作業、乗客・貨物、ATC/CPDLC など）
  - `refonly/*.lua`：見た目だけのページ（`***` の雛形。REF NAV DATA、NAV RAD、DEP/ARR、HOLD、FIX など）
- `B744.createfms.lua` が CDU を作り、`B747.68.xt.fms.lua` がページ遷移・入力・データ（`getFMSData`）を扱う。
- ACARS/CPDLC：`acars/*`（AutoATC と Hoppie の provider）。
- IRS：`irs/irs_system.lua`（アライン、位置）。`irs/rnav_system.lua`。
- ルート・航法：X-Plane の FMS（`xtlua/fms`）。LNAV のポイント切り替えは autopilot 側（`override_fms_advance`）。VNAV は `B744.fms.pages.vnav*.lua` と `B747.70.xt.autopilot.vnav*`。

## 7. エンジン型式

- 機体設定 `engines` の選択肢：PW4056 / PW4060 / PW4062、CF6-80C2-B1F / B5F / B1F1、RB211-524G / H / H8T。既定は PW4056。
- thrust ref は PW と RR が EPR、GE が N1。
- `laminar/B747/engines/type`：0=PW、1=GE（CF6）、2=RR。表示の切替用に `hidePW`・`hideGE`・`hideRR` もある。
- 設定はリバリーフォルダの `B747-400_simconfig.dat` に保存する。リバリーごとにエンジン型式が変わりうる。
- EEC は型式別のファイル（`B747.42.xt.EEC.{PW,GE,RR}.lua`）。
- 資料との対応：
  - PW：FCOM、LH24、LH36 がある。
  - CF6：FCOM、ATA70_80 がある。
  - RR：資料が無い。
- カスタム acf のエンジンモデル（`NEW_engines`）は PW と GE だけ。RR を選ぶと外部モデルにエンジンが出ない（ACF_DIFF.md）。

## 8. その他

- サウンド：`fmod/747-400.snd` と bank 群（FMOD）、`sounds/alert/*.wav`（コールアウトなど）。
- `documentation/`：`LNAV.VNAV.md`、試験飛行の手順と解析スクリプト（R）、FMC ページのテキスト（`fms pages/`）など。
- `build.sh`：リリース zip の作成。`add.sh`：版数を書いて README.pdf を作る。`test.lua`：作者の試し書き。

## 9a. 新しいコードの書き方（PLAN.md の R-2）

作り直す系統のコードは、次の取り決めで書く。XTLua の `init.lua`（4 つのプラグインで同じ）を読んで決めた。

- **ロジックとグルーを分ける**：
  - 系統の論理は、X-Plane に触らない純粋なモジュール（`<系統>.model.lua` など）に置く。入力の表と経過時間 dt を受け取り、状態と出力の表を返す形にする。
  - dataref とコマンドとの受け渡しは、xt スクリプト（グルー）だけが行う。
  - こうすると、モジュールは LuaJIT の回帰試験（`tests/<系統>/`）で X-Plane なしに試せる。グルーを含むモジュール全体も、`tests/lib/xtlua.lua` で X-Plane なしに回せる（TESTING.md §3）。
- **モジュールの読み込み**：
  - XTLua の `dofile`（`get_run_file_in_namespace`）は、読んだチャンクの戻り値を捨てる。
  - そこでモジュールは、表をスクリプトの名前空間のグローバルに置き（例：`B747_elec_model = M`）、同時に `return M` もする。
  - xt スクリプトはグローバルから使い、試験は `dofile` の戻り値を使う。
- **グローバルの表には必ずメタテーブルを付ける**（`local M = setmetatable({}, {})`）。
  - XTLua の名前空間（`namespace_write`）は、メタテーブルの無い表を代入すると、その時点の中身を別の表にコピーする。
  - そのため、あとで元の表を書き換えても反映されない。コピーの側で無いキーを読むと、`parent` を探す処理が自分を呼び続けてスタックが溢れる（旧フォークで計器・FMC・AP が止まった原因）。
  - コピーの側の `#`・`ipairs`・`pairs` は `__len` などのメタメソッドに頼る。手元の LuaJIT 2.1（回帰試験）はこれを無視して 0 件になる。XTLua の LuaJIT 2.1.0-beta3 がどうかは確かめていない。どちらでも同じに動くよう、新しいコードはコピーされた表を数えたり回したりしない。
  - ファイルの `local` の表を、`dofile` した別のチャンク（グルー）に渡すときは、メタテーブル付きの表に入れてグローバルに置く（例：`B747_alert_messages`）。
- **dataref**：
  - 新しい公開 dataref は init スクリプト（`init/scripts/<モジュール>/`）で作る。xt スクリプトの `deferred_dataref` は探すだけで、作らない。`tests/static/xt_bindings_created_test.lua` がこれを検査する。
  - 名前は既存の名前空間（`laminar/B747/<系統>/…`）に置く。INTERFACES.tsv の名前と意味は変えない（`tests/static/interfaces_test.lua`）。
  - 判定に使う dataref は毎フレーム読む（最初の読みが 0 になる問題への対策。TESTING.md §1.2）。
  - 書いた値は X-Plane に非同期で反映されるので、同じフレームで読み直して判定しない。
- **時間**：経過時間は dt として受け取り、フレームレートに頼らない（例：「1 フレームに 0.005 動かす」は使わない）。

## 9. 開発・試験の環境（2026-10-23 時点）

- Lua の構文チェックと回帰試験：LuaJIT 2.1 を用意した（PLAN の T-1。TESTING.md §3・§6）。
- FlyWithLua：NG+ 2.8.19 が導入済み。`Scripts/` に飛行試験の記録スクリプトを置いた（TESTING.md §4）。
- 試験の仕組み（旧フォークの試験 `tests_old/`、新しい回帰試験、飛行試験キット）：TESTING.md。
- X-Plane の Web API（localhost:8086）：飛行試験キットで使っている（TESTING.md §4。気をつけることは §4.6）。公式の説明（https://developer.x-plane.com/article/x-plane-web-api/ 、2026-10-23 確認）の要点：
  - X-Plane 12.4.0 以降は v3 が使える。REST は `http://localhost:8086/api/v3/…`、WebSocket は `ws://localhost:8086/api/v3`。`GET /api/capabilities` で対応版を確かめられる。
  - dataref：`GET /datarefs`（`filter[name]` で名前から ID を引く）、`GET /datarefs/{id}/value`、`PATCH /datarefs/{id}/value`（本体は `{"data": 値}`。配列の要素は `index` で指定）。
  - コマンド：`POST /command/{id}/activate`（本体は `{"duration": 秒}`、0 は押してすぐ離す）。
  - フライト：`POST /flight` で開始、`PATCH /flight` で更新（v3）。
  - 設定の Network タブで「Disable Incoming Traffic」が入っていると、すべて 403 になる。
  - 旧フォークでは、XTLua が作った double 型の dataref に Web API で小数を書くと HTTP 400 で拒否された（OLD_FORK_NOTES.md §14）。
- PDF のテキスト化には、Git for Windows 同梱の xpdf `pdftotext` 4.06 を使った。Python は入っていない。
