# 純正 acf とカスタム acf の差分（ACF_DIFF）

2026-10-23 調査。**どちらの acf も変更していない。** ここに書く差分は、もともと 2 つのファイルの間にあるもの。

## 1. 比べたファイル

| | ファイル | 形式 | Plane Maker の版（`acf/_file_writer_version`） | P 行の数 |
|---|---|---|---|---|
| 純正 | `747-400.acf`（本家 041c9ffa、git 管理） | I / 1200（XP12） | 123015 | 84,605 |
| カスタム | `747-400_custom.acf`（未追跡、2026-10-22 23:27 に配置） | I / 1200（XP12） | 123300 | 74,316 |

- カスタム acf がどの純正 acf から作られたかは、行の差分の数で見た。`747-400.acf` が 32,455 行と最も少なく、`747-400LCF.acf` は 34,428 行、`747-400_XP11.acf` は 155,625 行。
- そこで比較用の「純正 acf」は **`747-400.acf`** とする。前回の報告で `747-400_XP11.acf` を純正 acf と呼んだのは誤りだった。
- 方法：`P <キー> <値>` の行をキーで突き合わせた（同じキーで値が違う 10,724、カスタムだけにある 355、純正だけにある 10,644）。末尾に埋め込まれたパネル計器の定義は別に比べた。

## 2. 同じもの（システムの土台は共通）

- **重量・重心**：空虚重量 404,600 lb、最大 850,000 lb、燃料 381,552 lb。重心位置と前後限界も同じ。
- **燃料タンク**：9 個。容量比（0.300 / 0.078 / 0.220 / 0.220 / 0.078 / 0.023 / 0.023 / 0.058 / 0）も同じ。違いは役割だけ（§3.6）。
- **電源**：バッテリー、バス（`acf/_bus_*`）、発電機、`acf/_esys*` は全項目が同じ。
- **油圧**：`acf/_hyd*` は同じ（舵面ごとの系統割り当ては違う。§3.5）。
- **エンジン**：4 発、`JET_2SPOOL`、推力上限 63,000 lbf は同じ。違いは位置・燃費・定格（§3.2）。
- **速度**：Vso 110、Vs 216、Vfe 280 / 180、Vle 270 kt。
- **パネル計器**（acf 末尾の generic instrument 2,850 個）：ほぼ同じ。違うのは機長 ND の VOR L/R の針 2 個の参照先で、純正は `sim/cockpit2/radios/indicators/nav_relative_bearing_deg[2]`・`[3]`、カスタムは `[3]`・`[4]`。コードは VOR L/R を nav の 2・3 番に合わせているので、正しいのは純正、カスタムが 1 つずれている（notes/ATA-31.md）。

## 3. 違うもの

### 3.1 参照しているオブジェクト（見た目。変更対象外）

- 純正：41 スロット（40 種類）。カスタム：68 スロット（68 種類）。カスタムが参照するファイルはすべて実在する（大半は 2026-10-22 に入ったローカル一式。ARCHITECTURE.md §0）。
- カスタムだけにあるもの：
  - コクピット：`Cockpit_Flashboi`、`Cockpit_Glass_2`、`Cockpit_Headset`、`Cockpit_Main_2/_3`、`Cockpit_acu`〜`_acu_5`、`Cockpit_bolts`、`Cockpit_circuit_breaker`・`_breraker_2`、`Cockpit_escape`、`Cockpit_floor`、`Cockpit_sticker`、`cockpit_glareshield_panel`
  - 外部：`Exterior_Detail`・`_detail_2`、`Exterior_Fuselage2/3`、`Exterior_Glass2`、`Exterior_VStab`、`Exterior_Windshield`、`Exterior_Wings1`、`Exterior_Wiper`、`Exterior_cargo`、`Landing_lights`
  - エンジン：`NEW_engines/` の GE と PW のエンジン・パイロン・ステッカー
- 純正だけにあるもの：`747_cabin/Cabin_Main`・`Cabin_Seats`、`Cockpit_Pilots`、`Exterior_Engine_F`・`_F_GE`、`Exterior_Engines`・`_Engines_GE`・`_EnginesR_GE`、`Exterior_Wings`、`Exterior_WndwFrm`、`chocks`
- エンジンの外観は `laminar/B747/engines/type` で切り替わる。カスタムの `NEW_engines` は PW（type 0）と GE（type 1）だけで、**RR（type 2）を選ぶとエンジンが表示されない**。

### 3.2 エンジン（システムに関係）

| キー | カスタム | 純正 | メモ |
|---|---|---|---|
| `_engn/0,3/_part_y`・`_part_z`（外側） | -7.0 / 123.70 | -4.0 / 125.80 | 外側エンジンは前へ 2.1 ft、下へ 3 ft。`_blad`、ナセルの body 21・24 も同じだけ動いている |
| `_engn/1,2/_part_y`・`_part_z`（内側） | -11.2 / 96.48 | -10.2 / 102.88 | 内側エンジンは前へ 6.4 ft、下へ 1 ft。body 22・23 も同じ |
| `acf/_jet_SFC_takeoff` / `_climb` / `_locrz` / `_hicrz` | 0.55 / 0.25 / 0.25 / 0.38 | 0.323 / 0.323 / 0.313 / 0.571 | 燃費。カスタムは離陸で多く、巡航で少ない。燃料の消費と FMC の予測に効く可能性あり（§4） |
| `acf/_n1_rated_thrust` | 95 | 100 | |
| `acf/_fadec_parameter` | 1 | 0 | |
| `acf/_inlet_max_KEAS` / `_face_jet` / `_exhaust_rat` | 950 / 37 / 0.3 | 750 / 47 / 0.5 | |

### 3.3 X-Plane の autopilot・保護機能の設定（システムに関係）

| キー | カスタム | 純正 |
|---|---|---|
| `acf/_fdir_needed_to_engage_servo` | 1 | 0 |
| `acf/_alt_always_armed` | 1 | 0 |
| `acf/_load_alt_presel_on_alt_hit`・`_load_presel_on_asi_hit`・`_load_presel_on_vvi_hit` | 1 | 0 |
| `acf/_vvi_but_adjusts_pitch` | 1 | 0 |
| `acf/_integrated_approach_navigation` | 1 | 0 |
| `acf/_auto_ptch_axis_defaults_free`・`_auto_roll_axis_defaults_free` | 1 | 0 |
| `acf/_ott_*`（X-Plane の AP / A/T の応答調整、16 項目） | 例：`_ott_the_deg_off_for_full_def` 5、`_ott_flare_begin` 10 / `_end` 3 | 例：90、15 / 5 |
| `acf/_flap_extend_protect`・`acf/_gear_extend_protect` | 1 | 0 |

- AFDS は X-Plane の autopilot の上に乗っている（ARCHITECTURE.md §3）。そのため、ここが違うと **2 つの acf で AFDS の動きが変わりうる**。

### 3.4 操縦系統・脚

| キー | カスタム | 純正 | メモ |
|---|---|---|---|
| `_gear/0/_steerdeg_lospeed` / `_hispeed` | 75 / 35 | 70 / 7 | 前輪ステアリングの角度。純正は tiller 70°、ペダル 7° の値（資料で要確認） |
| `_gear/0〜4` の位置、タイヤ径・幅、strut | 違う | — | 脚の位置は見た目（変更対象外）。タイヤと strut は物理 |
| `acf/_ailn1_v1`・`_v2` / `acf/_ailn2_v1`・`_v2` | 900・900 / 500・600 | 0・0 / 200・250 | X-Plane のエルロンの速度によるロックアウト |
| `acf/_ailn1_rat2` | 0.8 | 1.0 | |
| `acf/_ailn_def_time` / `_elev_def_time` | 0.35 / 0.2 s | 0.5 / 0.5 s | 舵面の動く速さ |
| `acf/_ailn_trim_time` / `_rudd_trim_time` / `_speedbrake_ext_time` | 12 / 13 / 1.5 s | 10 / 10 / 1.0 s | |
| `acf/_hdng_` / `_ptch_` / `_roll_max_full_def_KIAS` | 180 / 500 / 500 | 189 / 200 / 250 | 全舵角を使える速度 |
| `acf/_frc_*`（力のフィードバック、7 項目） | 値あり | 0 | ジョイスティックの力の帰還。システム外 |
| `acf/_cyclic_*_trim_rat`、`acf/_rrpm_trim_time` | 値あり | 0 | ヘリコプター用の項目 |

### 3.5 空力（翼・胴体。カスタムで変えてよい分類）

- **翼**（`_wing`）：
  - 違う 10,724 項目の大半は、Plane Maker が計算する形状点（`_geo_xyz`、`_chord_for_RIB`）。手で入れる値の違いは 103 項目。
  - 主翼の上反角：カスタム 7.1° / 7.6°、純正 8.1° / 12.6°。
  - 垂直尾翼：wing 11 の翼弦・位置・長さが違う。純正にだけ、見えない垂直翼面の wing 10 がある。
  - ウイングレット（wing 18・19）：上反角 65° と 61°、翼弦、位置、後退角が違う。
  - 小さな翼面（wing 12〜16）、パイロン（wing 32〜35）の位置と寸法も違う。
- **舵面の油圧系統の割り当て**（`_ailn1_hyd0123`、`_spoi1/2_hyd0123`、`_sbrk1_hyd0123`、`_rudd1/2_hyd0123`）：カスタムは値があり（1・2・5・6）、純正はすべて 0。X-Plane の油圧モデルがカスタムでだけ効いている可能性がある（§4）。
- **胴体**（`_body`）：どちらも全部「見えない」。カスタムには body 4・5・8・9・13・17 が無い（抵抗の計算が変わる）。body 10 の位置と、ナセルの 21〜24 も違う。
- `_sbrk`（スピードブレーキの形状点）にも違いがある。
- 計算値（`acf/_h_eqlbm`、`acf/_the_eqlbm`、`acf/_average_mac_acf`）も違う。

### 3.6 燃料・その他

| キー | カスタム | 純正 | メモ |
|---|---|---|---|
| `acf/_tank_role/7` | 0 | 1 | タンク 7（容量比 0.058、約 22,000 lb）。容量からみて stabilizer tank と推定 |
| `acf/_fixed_role/5`・`/6` | 0 | 1 | 固定重量の役割 |
| `acf/_pe_xyz/1`・`_pe_xyz_copilot/1` | 10.30 | 10.99 | 視点の高さ（見た目。変更対象外） |

## 4. システムとの食い違いの候補（GAP_ANALYSIS.md で扱う）

ここでは候補を挙げるだけにする。資料との照合と、コードが acf の値を使っているかの確認は GAP_ANALYSIS.md で行う。

1. 前輪ステアリング：カスタムはペダル 35°。ただし `override_wheel_steer` が使われているので、acf の値が効くかどうかを確認する。
2. `_fdir_needed_to_engage_servo` などの X-Plane AP 設定が acf で違い、AFDS の動きが acf によって変わる恐れ。
3. `_flap_extend_protect`・`_gear_extend_protect`：実機に無い保護。プラグインが動かすフラップと脚を X-Plane が止める恐れ。
4. 燃費（SFC）と `_n1_rated_thrust`・`_fadec_parameter`：燃料系統が `override_fuel_system` で X-Plane の燃料流量を使う場合、燃料の消費と FMC の予測がずれる。EEC の表が純正 acf の設定を前提に調整されているかも確認する。
5. タンク 7 の役割、舵面の油圧割り当て、エルロンのロックアウト（実機はフラップ位置で決まる）：自前のロジックと重ならないかを確認する。
6. 機長 ND の VOR L/R の針の index（カスタムが誤り。直すにはカスタム acf のパネル変更が要り、承認が必要）。
7. RR を選んだときに外部モデルのエンジンが出ない（カスタム acf）。

## 5. 作り直しの中でカスタム acf に入れた変更（2026-10-23 承認：PLAN.md §3）

パネル計器だけを変える。純正 acf は変えない。変更前の acf は `D:\747-400-local-assets\acf_backup\` と git の履歴にある。

| 日付・系統 | 場所（パネル） | 変更前 | 変更後 | 根拠 |
|---|---|---|---|---|
| 2026-10-23・警報（WARN-09） | 主 EICAS のページ番号（`GROUP Page #`） | `SHOW_GREATER 2.000000 laminar/B747/CAS/num_msg_pages`（3 ページ以上でだけ PG） | `SHOW_GREATER 1.000000 …`（2 ページ目から PG） | FCOM p.1548 |
| 同 | 主 EICAS のメッセージ（warning・caution・advisory・memo の各グループ） | 1・2 ページ（`gen_<level>_msg_000`〜`021`）だけ | 3〜10 ページのグループを追加（2 ページ目の写し。`SHOW_EQUAL p laminar/B747/CAS/msg_page`、枠 `022`〜`109`）。4,320 行の追加 | 警報モデルは 10 ページまで書く（ARCHITECTURE.md §4.3） |
| 2026-10-23・空圧（PNEU-10） | 主 EICAS のダクト圧（`GROUP Duct Pressure`） | 琥珀 `SHOW_LESS 11.000000`、白 `SHOW_GREATER 11.010000`。右の白の数字が `duct_pressure_L` で出し入れ | 琥珀・白とも 11.5 で切り替え（数字は整数に丸めて出るので、12 以上が白・11 以下が琥珀になる）。右の白は `duct_pressure_R` で | FCOM p.585 |
| 同 | ECS synoptic のダクト圧 | 琥珀・白とも 12.000000 で切り替え（12.0 ちょうどでは出ない） | 11.5 で切り替え | FCOM p.578 |
| 2026-10-23・警報（WARN-17） | STATUS ページ（`GROUP STAT Synoptic` の中に `GROUP Status Messages` を追加） | メッセージの行もページ番号も無い（油圧・APU・酸素・バッテリーの値と舵面の図だけ） | 1〜10 ページのグループ（`SHOW_EQUAL p laminar/B747/STAT/msg_page`）に 11 行ずつの文字（`TXT.2.28.white`、x 1570、y 97 から 24 ずつ下、`CAS/gen_status_msg_NNN`）。2 ページ以上で PG とページ番号（`SHOW_GREATER 1.000000 laminar/B747/STAT/num_msg_pages`）。1,380 行ほどの追加 | FCOM p.1527-1528、LH24 p.65（配置） |
| 同 | 主 EICAS の `GROUP CAS Messages` | STATUS cue が無い | cyan の "STATUS"（`TXT.8.27.blue`、`CAS/status_cue_text`、`SHOW_EQUAL 1.000000 laminar/B747/CAS/status_cue`、POS 1977, 826.5：メッセージ 11 行目の下、PG の行） | FCOM p.1545、p.1549 |
�� | AUTO（シアンの画像）は `dem_mode_n` = 1、OFF（白の画像）は `dem_mode_n` = 0（系統 4 は AUX（-1）で OFF、OFF（0）では何も出ない） | AUTO（シアンの画像）は `synoptic/dem[n-1]` = 3（AUTO で動いていない）。白の OFF の画像 4 個を外し、琥珀の gen_text "OFF"（`TXT.2.28.amber`、`synoptic/text_off`、`dem` = 4：セレクタ OFF、系統 4 の AUX）と "AUTO"（`text_auto`、`dem` = 2：AUTO で指令中に圧低）を丸の中心に。系統 4 の AUX の丸に白の OFF の画像（`synoptic/aux` = 0）。全体で約 130 行の追加 | ATA29_32 p.105-106、FCOM p.1486-1488 |
| 同 | HYD synoptic の EDP・SOV（`GROUP edp indication`） | SOV の開閉と EDP の OFF が同じ `valve_n`（供給遮断弁が開で ENGINE pump が ON のとき 1）で出し入れ | SOV の開は `synoptic/sov[n-1]` = 1、閉は = 0（火災スイッチ）。EDP OFF（琥珀の箱の画像）は `synoptic/edp[n-1]` = 4（ENGINE pump スイッチ OFF） | ATA29_32 p.105、FCOM p.1487、p.1490 |
| 2026-10-23・油圧（HYD-18） | HYD synoptic（`GROUP rsvr press` を追加） | RSVR PRESS の画像はあるが計器が無い | 各リザーバの右に RSVR PRESS の画像（`rsvr_press`、POS x = リザーバ + 58、y −72、`synoptic/rsvr_press[n-1]` = 1） | FCOM p.1488、p.1489、ATA29_32 p.38 |
| 2026-10-23・電源（ELEC-11 ほか） | ELEC synoptic の ISLN の枠（`isln1`〜`4`） | BUS TIE スイッチの位置（`button_switch/position[18]`〜`[21]` < 0.95）で出す | `electrical/breaker/btb[n-1]` = 0（BTB 開）で出す。自動で開いたときも出る | FCOM p.791 |
| 同 | ELEC synoptic の DRIVE の枠（`drive1_off`〜`4`） | エンジン滑油圧の `engines/EICAS2_oil_press_status[n-1]` > 0.1 で出す | `electrical/light/drive[n-1]` = 1（IDG の油圧低。P5 の DRIVE 灯と同じ条件）で出す | FCOM p.792、p.786 |
| 同 | STAT ページの MAIN BATT・APU BATT（`GROUP Main Batt`・`APU Batt`） | V-DC と A-DC は X-Plane のバッテリー（`battery_voltage_indicated_volts[0]`・`battery_amps[0]`）、APU の V-DC は `electrical/apu_volts`、A-DC は APU 発電機の電流（`generator_apu_amps`） | 電源モデルの `electrical/battery/volts[0]`・`[1]` と `battery/stat_amps[0]`・`[1]`（電流の符号なし） | FCOM p.793 |
