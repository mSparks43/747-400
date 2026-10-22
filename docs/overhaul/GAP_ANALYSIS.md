# 現状実装と実機の差（GAP_ANALYSIS）

フェーズ0-Bの調査結果。`overhaul` ブランチ（本家 041c9ffa）のコードを、資料（FCOM・FCTM・整備訓練マニュアル・Lufthansa B1・Honeywell FMS Pilot's Guide）と比べた。系統ごとの詳しい内容と出典は `notes/` にある。この文書はその要約と一覧。

## 0. 読み方

- **種別**：欠落（実機にある機能が無い）／挙動の誤り（あるが実機と違う）／バグ（実装の誤り）。
- **重要度**：高（乗員から見える挙動が違う、または他系統の前提が崩れる）／中／低。
- **規模**：S（1 日程度、局所修正）／M（数日、1 モジュール内の作り直し）／L（1 週間以上、系統の作り直し、または他系統への波及）。
- ID は notes の各表と同じ（`ELEC-01` など）。根拠は `ID p.<PDF ページ>` の形。
- 基準の機体：系統ごとの調査は、FCOM の機体番号 109（旅客機、PW4056）を基準にし、405（PW の改造貨物機）と 570（GE の貨物機）の違いを添えた。RR には資料が無い。
- 調査はコードと資料の読み比べで、X-Plane で動かして確かめたものではない。各ノートの「未確認事項」は、フェーズ1の試験で確かめる。

## 1. まとめ

- 合計 550 件（高 111・中 252・低 187）。表は依存関係の順（PLAN.md の段階の順）。
- ほとんどの系統で、部分修正ではなくモジュールの作り直しを勧める。今のコードは X-Plane の機能の上に表示を載せた薄い層が多く、実機の論理（状態機械、タイマー、閾値、冗長構成）を入れる場所が無いため。作り直しても、名前と意味は INTERFACES.tsv のとおり保つ。

| ID | 系統 | ノート | 件数 | 高 / 中 / 低 | 欠落 / 誤り / バグ | S / M / L | 推奨 |
|---|---|---|---|---|---|---|---|
| ELEC | 電源（ATA 24） | [ATA-24.md](notes/ATA-24.md) | 24 | 5 / 10 / 9 | 11 / 10 / 3 | 15 / 7 / 2 | 作り直し（L）。バス単位のモデルと、バスごとの公開 dataref。消費側を乗り換える |
| HYD | 油圧（ATA 29） | [ATA-29.md](notes/ATA-29.md) | 23 | 10 / 5 / 8 | 9 / 11 / 3 | 13 / 9 / 1 | 動力源と表示を作り直し、消費側は表で判定（M〜L）。先に AFDS のコードを切り出す |
| PNEU | 空圧（ATA 36） | [ATA-36.md](notes/ATA-36.md) | 14 | 1 / 7 / 6 | 7 / 7 / 0 | 7 / 6 / 1 | 新しい抽気モジュール（M）。空調・与圧と同じファイルから分ける |
| APU | APU（ATA 49） | [ATA-49.md](notes/ATA-49.md) | 13 | 0 / 5 / 8 | 5 / 7 / 1 | 11 / 2 / 0 | 1 つの状態機械に作り直し（M）。今は電源・エンジン・空調・燃料に散らばっている |
| FUEL | 燃料（ATA 28） | [ATA-28.md](notes/ATA-28.md) | 25 | 5 / 8 / 12 | 5 / 17 / 3 | 18 / 7 / 0 | 表駆動で作り直し（M〜L）。マニフォールドと吸引供給を入れる |
| ENG | エンジン（ATA 71〜80） | [ATA-70-80.md](notes/ATA-70-80.md) | 38 | 6 / 20 / 12 | 14 / 18 / 6 | 23 / 12 / 3 | engines と EEC を作り直し（L）。推力基準と A/T のサーボは推力管理へ移す |
| AIR | 空調・与圧・機器冷却（ATA 21） | [ATA-21.md](notes/ATA-21.md) | 22 | 6 / 11 / 5 | 13 / 6 / 3 | 9 / 13 / 0 | 空調・与圧・機器冷却を作り直し（L）。表示の追加はパネル変更（承認） |
| ICE | 防氷・防雨（ATA 30） | [ATA-30.md](notes/ATA-30.md) | 13 | 0 / 8 / 5 | 6 / 4 / 3 | 11 / 2 / 0 | 作り直し（M）。抽気モジュールの後 |
| OXY | 酸素（ATA 35） | [ATA-35.md](notes/ATA-35.md) | 5 | 0 / 3 / 2 | 5 / 0 / 0 | 4 / 1 / 0 | 新規（S〜M） |
| FIRE | 火災防護（ATA 26） | [ATA-26.md](notes/ATA-26.md) | 20 | 4 / 11 / 5 | 12 / 6 / 2 | 11 / 8 / 1 | 表駆動で作り直し（M〜L）。ファイアベルは .snd の変更（承認） |
| FCTL | 操縦系統（ATA 27） | [ATA-27.md](notes/ATA-27.md) | 25 | 4 / 9 / 12 | 9 / 14 / 2 | 15 / 8 / 2 | FCU・SRM・スピードブレーキを新しいモジュールに（L）。舵面への書き出し（controlObject）は残す |
| GEAR | 脚・ブレーキ・ステアリング（ATA 32） | [ATA-32.md](notes/ATA-32.md) | 23 | 7 / 7 / 9 | 11 / 7 / 5 | 12 / 10 / 1 | 作り直し（L）。空地判定（PSEU）を先に作り、各系統が乗り換える |
| WARN | 乗員への警報（EICAS メッセージ、警報音、形態・失速警報） | [ATA-31-warning.md](notes/ATA-31-warning.md) | 23 | 7 / 11 / 5 | 8 / 10 / 5 | 14 / 9 / 0 | 作り直し（L）。抑止の状態機械、CANC/RCL、階層。音の結線は .snd の変更（承認） |
| DSP | 表示（PFD・ND・EICAS の画面、表示の切替） | [ATA-31.md](notes/ATA-31.md) | 35 | 6 / 19 / 10 | 15 / 12 / 8 | 17 / 13 / 5 | 表示ロジックは作り直し、ND の地図と時計は部分修正、FDR は現状維持（L）。多くはパネル変更（承認） |
| NAV | 航法センサーと無線（ATA 34） | [ATA-34.md](notes/ATA-34.md) | 81 | 13 / 37 / 31 | 45 / 18 / 18 | 52 / 25 / 4 | センサー層（ADC・IRS・無線の同調・GPWS・TCAS）を作り直し・新規（L）。一部は部分修正 |
| FMC | FMC の航法・性能・誘導（ATA 34-61） | [ATA-34-61-FMC.md](notes/ATA-34-61-FMC.md) | 40 | 13 / 22 / 5 | 18 / 19 / 3 | 15 / 16 / 9 | 作り直し（XL）。自前の経路モデルを段階的に。LNAV・VNAV・性能 DB |
| CDU | CDU のページと操作（ATA 34-61） | [ATA-34-61-CDU.md](notes/ATA-34-61-CDU.md) | 42 | 6 / 22 / 14 | 15 / 21 / 6 | 23 / 10 / 9 | CDU の枠組み（キー処理、項目の定義と入力検査、メッセージ、MOD/EXEC、字体つきの描画）を作り直し（L）。X-Plane 標準 FMS の使い方は FMC と一緒に決める |
| AFDS | 自動操縦・FD・ヨーダンパー・安定板トリム（ATA 22） | [ATA-22.md](notes/ATA-22.md) | 24 | 7 / 12 / 5 | 8 / 14 / 2 | 10 / 10 / 4 | 作り直し（L）。FCC の状態機械、ロールも自前に。ヨーダンパーと安定板の自動トリムは新規 |
| ATHR | オートスロットルと推力管理 | [ATA-22-AT.md](notes/ATA-22-AT.md) | 20 | 8 / 8 / 4 | 7 / 11 / 2 | 9 / 10 / 1 | 推力管理を 1 つのモジュールに作り直し（L） |
| COM | 通信（ATA 23） | [ATA-23.md](notes/ATA-23.md) | 16 | 1 / 9 / 6 | 6 / 6 / 4 | 10 / 6 / 0 | 表駆動で作り直し（M） |
| LIGHT | 照明（ATA 33） | [ATA-33.md](notes/ATA-33.md) | 16 | 2 / 6 / 8 | 5 / 6 / 5 | 13 / 3 / 0 | 作り直し（M）。他系統の灯の条件は各系統の作り直しで移す |
| DOOR | ドア（ATA 52） | [ATA-52.md](notes/ATA-52.md) | 8 | 0 / 2 / 6 | 6 / 2 / 0 | 4 / 4 / 0 | 新規（S〜M） |

- 「作り直しを待たずに直してよい」と各ノートが挙げた S の修正は、PLAN.md の R-3（任意）にまとめた。
- 乗員への警報は、別に [notes/EICAS-MESSAGES.md](notes/EICAS-MESSAGES.md) に、FCOM の全 EICAS メッセージと実装の有無の一覧がある。

## 2. 系統をまたぐ問題

ここに挙げるものは、ひとつの系統の作り直しでは片づかない。PLAN.md の順番は、主にこれで決まる。

1. **電源のバス単位のモデルが無い**（ELEC-01・02）。
   - X-Plane の `cross_tie` を毎フレーム 1 にしていて、全バスが一体になっている。
   - ほかの系統は `sim/cockpit2/electrical/bus_volts[0] > 0` で「電源あり」と判定している。これはバッテリーだけでも真になる。燃料・抽気・FMS・警報・計器・照明・操縦系統・quick start がこれに頼っている。
   - 照明モジュールが外部電源・APU 電源の接続状態を書き、それを電源モジュールが読んでいる（LIGHT-01）。
   - → まず電源を作り直し、バスごとの状態を公開する dataref を出す。各系統はそれに乗り換える。
2. **空地判定（PSEU）が無い**（GEAR-01）。
   - どのモジュールも `sim/flightmodel/failures/onground_any` を使っている。最初の 1 輪が接地した時点で地上になる。
   - 実機では、主脚のトラックの傾きセンサーで左右とも接地したときに地上になる。前脚の圧縮信号は、ペダルのステアリング、離陸警報、失速警報が使う。
   - → 空地のモジュールを作り、各系統が順に乗り換える。
3. **油圧の「どの系統で動くか」の表が無い**（HYD-09・11・13、GEAR-09・12、FCTL-20）。
   - 舵面は関数ごとに系統の組を手書きしていて、3 か所が FCOM と違う（HYD-06）。
   - 脚・ブレーキ・逆推力・安定板トリム・ヨーダンパーは、4 系統のモデルに従っていない。
   - 脚とブレーキは X-Plane の油圧で動き、コードは X-Plane のポンプ故障の dataref を毎フレーム書き換えて圧を保っている。
4. **空圧（抽気）の需要と供給が無い**（PNEU-01・02）。ダクト圧は、開いている供給源の最大値。デマンドポンプ（ADP）、防氷、パック、エンジン始動の前提になる。
5. **乗員への警報の枠組みが不完全**（WARN-01〜06、FIRE-06、EICAS-MESSAGES.md）。
   - 警報の抑止（始動前後、離陸中、着陸）が無い。
   - CANC/RCL の処理に誤りがある。
   - メッセージの階層（警報・注意・勧告）の誤りがある。
   - コードの表にある 458 件のうち、どこかで立てられるのは 165 件だけ。FCOM の 256 行のうち、実装済みは 70、一部は 21、未実装は 165。
   - サイレンとファイアベルは `fmod/747-400.snd` で X-Plane の警報灯や火災表示に直結している。Lua の判定が音に届かない。
6. **表示の定義が acf のパネルにある**（ARCHITECTURE.md §5）。
   - synoptic の色や状態の多くは、パネルの表示条件として acf に直接書かれている。
   - 純正 acf は変えないので、Lua の値だけでは直せない表示がある。§4 に一覧を置いた。直すにはカスタム acf のパネル変更が要り、承認が必要。
7. **X-Plane 本体の機能との境界が系統ごとにばらばら**。系統ごとに、X-Plane に任せるか自前にするかを決める必要がある。
   - AFDS：ロールは X-Plane の HDG SEL を流用し（AFDS-01）、ピッチは自前。
   - A/T：X-Plane の A/T は止め、自前で動かしている。
   - 与圧：X-Plane の与圧に値を書いている（AIR-02）。
   - 燃料の消費：X-Plane の燃料流量を使うので、acf の燃費の値がそのまま効く（FUEL-05）。
   - 脚・ブレーキ・オートブレーキ：X-Plane 任せ（GEAR-02・03・09）。
   - スピードブレーキ 1 とスラット：X-Plane 任せの可能性（FCTL）。
8. **コードの置き場所が系統と一致していない**。
   - AFDS の制御則とヨーダンパーが、油圧のファイル `B747.19.xt.hydraulics_override.lua` の中にあった（約 340〜1100 行）。R-1 で別ファイルに分けた（2026-10-23。行の対応は ARCHITECTURE.md §2.1）。
   - 推力制限と A/T のサーボが EEC のファイルにある（ENG・ATHR）。
   - 多くの系統の表示灯が照明モジュール `B747.90.xt.lighting.lua` で計算されている（ATA-33 §5.3 に一覧）。
   - quick start（`B747.95.xt.AI.lua`）が各系統の内部の値を直接書いている。
   - → 系統を作り直すときに、その系統の灯・メッセージ・quick start も一緒に移す。油圧・操縦系統の作り直しの前に、AFDS のコードを別ファイルへ切り出す。
9. **機体の型式・仕様の扱い**。
   - エンジン型式はリバリーごとの設定（`laminar/B747/engines/type`）。貨物機は `laminar/B747/freighter`。
   - FCOM の機体番号ごとの違い（109・405・570）を、どの設定に対応させるかを決める必要がある。
   - RR には資料が無いので、今の動きのまま残す。
10. **毎フレームの負荷**。照明モジュールが毎フレーム `collectgarbage("collect")` を実行している（LIGHT-08）。
11. **X-Plane 12 への追従**。
   - 旧名の dataref `sim/cockpit2/controls/parking_brake_ratio` を使っていて、Log.txt に警告が出る。
   - 旧 SDK の FMS 経路を使っていて、経路に脚の種別や制限の種別が無い（FMC-01）。

## 3. acf（ACF_DIFF.md）とシステムの食い違い

各担当がコードを読んで、acf の値に頼っているかを確かめた結果。

| 項目 | コードが頼っているか | 影響と対応 |
|---|---|---|
| 燃費（`_jet_SFC_*`）：カスタムは巡航で約 30% 少なく、離陸で多い | **頼っている**（燃料の消費、FMC の FUEL USED と予測） | FUEL-05・FMC-23。カスタム acf の値を純正と同じにする案（燃費はカスタム acf で変えてよい項目） |
| `_n1_rated_thrust` 95 / `_fadec_parameter` 1 | GE の N1 表示と推力の補正が純正の 100 を前提（推定） | ENG-34。試験で確かめる |
| X-Plane の AP 設定（`_ott_psi/phi_*` など） | ロールの指令だけ頼っている（AFDS-01・22） | 2 つの acf でロールの動きが違いうる。AFDS の作り直しで X-Plane のロールを使わなくなれば影響は消える |
| 他の AP 設定（`_fdir_needed_to_engage_servo` など）、A/T 設定（`_ott_asi_*`） | 頼っていない（X-Plane の A/T は止めている） | 対応不要（試験で確認） |
| 前輪ステアリング（カスタム 75/35、純正 70/7） | 20 kt 未満では X-Plane が acf の値を使う | GEAR-06・07。コードから `acf_nw_steerdeg1/2` に 70/7 を書く案（acf は変えない） |
| `_flap_extend_protect`・`_gear_extend_protect` | 不明 | 試験で確かめる |
| 舵面の油圧割り当て（`_hyd0123`）、エルロンのロックアウト速度、舵の動く速さ | 頼っていない（`override_control_surfaces` で迂回、推定） | 試験で確かめる |
| トリムの速さ（`_ailn_trim_time` など） | 頼っている（X-Plane のトリムのコマンドを使うため） | FCTL の作り直しで自前にする |
| タンク 7 の役割 | 頼っていない（燃料系統は自前） | 対応不要 |
| 機長 ND の VOR 針の index（カスタムは `[3]/[4]`） | パネルの定義 | カスタムが誤り。直すにはパネル変更（承認） |
| カスタム acf に `747-400_custom.snd` が無かった | — | X-Plane は機体の FMOD バンクを読まず、標準の音になっていた。利用者の提案で `fmod/747-400.snd` を `fmod/747-400_custom.snd` に複製した（git 管理外）。機体を読み直すと `Master bank Aircraft/747-400-master/fmod/` が読まれることを Log.txt で確認した（2026-10-23） |
| カスタム acf の新しい外部オブジェクト | — | テクスチャが 4 枚見つからない（`Exterior_Wiper.png` など、Log.txt）。3D 一式の問題で対象外 |

## 4. パネル（acf）の変更が要る表示の一覧（承認待ち）

Lua の値だけでは直せず、カスタム acf のパネル定義を変える必要があるもの。純正 acf は変えない。各ノートの GAP 表に、パネル変更が要るかを書いてある。

- 表示（DSP）：DSP-01（PFD の方位目盛りが ND の向きで回る）、03（ND の基準受信機）、04、10、12、15、20、22〜26、35。一部はパネル変更も要る：02、11、16〜18、30。
- 警報（WARN）：WARN-09 のページ表示、16 の枠、17 の STATUS。
- 燃料：synoptic の amber 表示が、量の閾値でパネルに固定されている（ATA-28 §6）。
- 空調：ECS synoptic のゾーン温度、アウトフローバルブの針、HI FLOW、EXT AIR（AIR-15）。
- エンジン：red box のラッチ、超過の合図、partial / compact 形式、X-BLD と空中始動の範囲、VIB の表示、GE の EGT の色（ATA-70-80）。
- 脚：synoptic のドアの箱、タイヤ圧の LED 3 個、展開形の表示（ATA-32）。
- ドア：DRS synoptic の箱が 2 つしかない（DOOR-01・02）。
- 電源：synoptic の ISLN の箱、DRIVE の箱、ギャレー、STAT ページの CHG/DIS（ATA-24）。
- 酸素：STAT ページの酸素圧の表示（ATA-35）。

## 5. サウンド・3D の変更が要るもの（対象外。承認待ち）

- `fmod/747-400.snd`：サイレン・ファイアベル・ウェイラーの結線（WARN-02〜04、FIRE-06）。
- カスタム acf 用の `.snd`：複製で対処した（上の §3）。`fmod/747-400.snd` を変えるときは、複製の `747-400_custom.snd` も同じにする。
- 3D の操作子が無いもの：安定板トリムの cutout と ALTN trim、非常灯、飛行制御の油圧遮断スイッチ、APU の消火ハンドル、CALL パネルのボタン（各ノート）。
- 3D の小さな誤り：
  - `Cockpit_OH1.obj:136606` の `zight_level`（ATA-26）
  - `Cockpit_Pedestal1.obj:40255` の `[126z`（ATA-33）
  - 副操縦士の ACP の HF R・SAT R の音量ノブ（ATA-23）

## 5a. ノート間の訂正

- ELEC-07（CDU の電源）：パネル群の名前 "FMS L"／"FMS C" は物理の配置と逆。3D のキーの位置と画面の UV から見ると、左 CDU は `fms1` のキーと `fms3` の表示行、中央 CDU は `fms3` のキーと `fms1` の表示行を使う。左 CDU が機長側の電源（`display_has_power[8]`）、中央と右が F/O 側（[6]・[7]）になる（notes/ATA-34-61-CDU.md）。
- ACF_DIFF.md の「ADF の方位針」は、機長 ND の VOR L/R の針だった。正しいのは純正 acf の `[2]/[3]`（notes/ATA-31.md、notes/ATA-34.md。ACF_DIFF.md は訂正済み）。
- ARCHITECTURE.md の override の一覧にあった `override_joystick_*`・`override_artstab` は、コメントにしか無い（訂正済み）。
## 6. 系統ごとの一覧

各ノートの GAP 表をそのまま並べた（内容・根拠・該当コードは各ノートの記述）。

### 電源（ATA 24）（ELEC、24 件：高 5・中 10・低 9）

詳細と出典の全文：[notes/ATA-24.md](notes/ATA-24.md)

| ID | 種別 | 重要度 | 規模 | 内容 | 根拠 | 該当コード |
|---|---|---|---|---|---|---|
| ELEC-01 | 欠落 | 高 | L | 実機のバス構成を表す電源モデルが無い：AC1-4、同期バス左右、SSB、XFR、standby 2 本、GS/GH、DC1-4、DC tie、バッテリー系 4 本、utility/galley。X-Plane は cross_tie 固定で全バスが一体。バス単位の状態は表示フラグだけで、GCB/BTB/SSB/APB/XPC が遮断器として存在しない | LH24 p.7, p.9; FCOM p.796-820 | B747.03.xt.electrical.lua:500, :540-592 |
| ELEC-02 | 欠落 | 高 | L | 他系統がバス単位の通電を問い合わせる手段が無い。各モジュールは `bus_volts[0]`（バッテリーだけでも真）で判定する。燃料ポンプ（AC/utility）、抽気弁（DC）、IRS、EICAS などが実機と違う電源条件で動く。公開 dataref を作り、各モジュールを移す必要がある | FCOM p.798-801, p.819-820 | fuel.lua:704, :1221; air.lua:468, :794; fms.lua:1236; warning.lua:1140; fltInst03.lua:269; lighting.lua:1691; fltCtrls.lua:722 |
| ELEC-03 | 挙動の誤り | 高 | M | 電源切替が違う。(a) IDG が入ると同じ側の EXT/APU しか落とさない。実機はどちら側でも落とす。(b) 同じ側の IDG が発電中は、EXT/APU を押しても毎フレーム switch_mode が 0 に戻り、選べない。実機は GCB を落として引き継ぐ（同種のもう一方が available かで、全 GCB か SSB＋GCB1/2 かが変わる）。(c) EXT1 と IDG3/4 が並列のまま続く（SUSP 無し） | LH24 p.102, p.123; FCOM p.796-797 | electrical.lua:573-583, :627-634; manipulators.lua:624-680 |
| ELEC-04 | 挙動の誤り | 中 | M | GCB/BTB の自動制御が無い。GCB は GEN CONT と X-Plane の発電状態だけ、BTB はスイッチだけで決まる。無いもの：故障トリップ、auto reclose、3.5 秒の break power transfer、last source on、「BTB の自動分離では DCIR を開かない」。IDG が入る回転（PW 54.3 % N2 ほか）は X-Plane 任せ | LH24 p.66, p.102-108; FCOM p.798, p.819 | electrical.lua:589-592, :760-833 |
| ELEC-05 | 挙動の誤り | 中 | S | SSB：異種電源（EXT1＋APU2 など）では常に分割する。実機は、同種のもう一方が available かで、分割か片方トリップかが決まる。>ELEC SSB OPEN（adv 104）、手動 SSB スイッチ、OPEN 灯が無い | LH24 p.120-123; FCOM p.788, p.822 | electrical.lua:566-583; warning.lua:290 |
| ELEC-06 | 欠落 | 高 | M | standby 電源が無い（main/APU standby bus、両インバーター、R7224/R7223、CAPT IBVSU）。表示の通電式で近似している。STBY PWR OFF では AC 電源があっても両 standby bus が落ちるはずだが、そうならない。F/O XFR の AC1 backup が STBY PWR の位置に依存している（誤り）。>STBY BUS MAIN/APU（adv 276-277）が無い | LH24 p.150-159, p.182; FCOM p.780-781, p.803-806, p.823 | electrical.lua:546-548; fltInst02.lua:3245-3272; warning.lua:462-463 |
| ELEC-07 | 挙動の誤り | 中 | S | 表示器と CDU の電源の割当が違う。現状：CDU L/R は F/O 側、CDU C は機長側、upper EICAS は機長側（APU standby 相当）。実機：CDU L と primary EICAS は main standby、CDU R と lower EICAS は F/O XFR、機長 PFD/ND と FMC L は APU standby。バッテリーだけの状態で CDU L が消え、CDU C が点く | FCOM p.800, p.804 | electrical.lua:624-626; fltInst02.lua:3267-3272 |
| ELEC-08 | 挙動の誤り | 高 | S | ELEC GEN OFF を caution（71-74）で出し、GEN CONT を操作したときしか更新しない。エンジン停止、drive disc、故障で GCB が開いても出ない。109 では advisory で、条件は「GCB 開」。ELEC AC BUS 表示中は抑止する | FCOM p.822 | electrical.lua:766-831; warning.lua:179-182, :286-289 |
| ELEC-09 | 挙動の誤り | 中 | S | ELEC AC BUS n の条件に BUS TIE AUTO が入っている。BUS TIE OFF にすると、自分の IDG が給電していても caution が出る | FCOM p.798, p.821 | electrical.lua:589-613 |
| ELEC-10 | 欠落 | 中 | S | ELEC BUS ISLN 1-4（adv 92-95）が無い。ISLN 灯はスイッチ OFF（と、常に 1 の cross_tie が 0 のとき）だけで、BTB の自動トリップと autoland 中の消灯が無い | FCOM p.785, p.802, p.821 | lighting.lua:1104-1107; warning.lua:278-281 |
| ELEC-11 | 挙動の誤り | 中 | S | DRIVE 灯が「X-Plane の発電機故障か generator_off」で点く。GEN CONT OFF でも点き、IDG の油圧・油温とは無関係。ELEC DRIVE 1-4（adv 96-99）が無い。synoptic の DRIVE 枠はエンジン滑油圧で代用（acf のため直せない） | LH24 p.72-73; FCOM p.786, p.792, p.821 | lighting.lua:1116-1119; 747-400.acf:131062-131132 |
| ELEC-12 | 挙動の誤り | 低 | S | DRIVE DISC が回転や電源に関係なく即座に切れる。実機は idle 以上で切れ（停止中は不完全）、電源は main battery bus（FCOM）／hot battery bus（LH24 の図） | FCOM p.785, p.819; LH24 p.60-61 | manipulators.lua:714-748; electrical.lua:763-765 |
| ELEC-13 | 欠落 | 中 | M | GHB/GSB（GHR・GSSR・GSTR、ground service switch、DC GHB）が無い。aux hydraulic pump 4、給油、充電器の電源を判定できない | LH24 p.36-40, p.214-217; FCOM p.799 | なし |
| ELEC-14 | 欠落 | 中 | M | ELCU と load shed が無い。utility の通電は「スイッチ AND（bus hot か gen on）」だけ。ELEC UTIL BUS と UTIL OFF 灯はスイッチ OFF だけで、load shed 中の抑止と galley（109）が無い | LH24 p.230-242; FCOM p.781-782, p.795, p.800-801, p.822 | electrical.lua:584-587, :904-918; lighting.lua:1077-1078 |
| ELEC-15 | 欠落 | 中 | M | DC 系（TRU、DCIR、DC tie、ELEC TR UNIT、single TRU）とバッテリー母線（main/APU battery bus、hot battery bus）が無い。BATTERY OFF で X-Plane のバッテリーごと切れて `bus_volts[0]` が 0 になる。実機では BATTERY OFF でも hot battery bus（消火器、IRU の DC backup、時計、APU inlet door など）は生きている。逆に消火器などは今は電源を見ていない | LH24 p.20, p.162-186; FCOM p.819-820 | electrical.lua:414-432 |
| ELEC-16 | 挙動の誤り | 中 | S | バッテリーの表示と BAT DISCH。APU バッテリーをモデル化しておらず、`apu_volts` は 28 固定、A-DC は APU 発電機の電流。>BAT DISCH APU は STBY PWR=BAT の 10 秒後に MAIN と一緒に強制、MAIN は X-Plane の Wh 減少で判定。実機：放電 ≥2 A と EIU の遅延（最大約 3 分）、BAT で充電器が止まる | LH24 p.192-204; FCOM p.793, p.181 | electrical.lua:429-431, :837-851; fltInst02.lua:3197-3207; 747-400.acf:129930-129957 |
| ELEC-17 | 挙動の誤り | 低 | S | 外部電源の available。XP12 では X-Plane の GPU 電圧次第で、`connect_power`（FMC の GRND POWER、AutoATC）だけでは翌フレームに 0 に戻るように読める（要確認）。EXT1/2 は常に同時。輪止めが条件。C&D で EXT2/APU2 の switch_mode を戻していない | LH24 p.214, p.218 | electrical.lua:338-346, :456-476; manipulators.lua:2056-2057 |
| ELEC-18 | 欠落 | 低 | M | autoland のバス分離（config A-E、DCIR、ISLN 消灯、synoptic 抑止）が無い。AFDS の LAND 3 との連携が要る | LH24 p.244-249; FCOM p.789, p.802 | なし |
| ELEC-19 | 欠落 | 低 | S | air mode（IDG 3/4 台 ≥6100 rpm、または空中）が無い。XPC/APB/SSB 操作の抑止、GHB の遮断、APU GEN AVAIL の抑止は一部だけ | LH24 p.66, p.146-148, p.214 | electrical.lua:703-725 |
| ELEC-20 | バグ | 低 | S | 未定義の global（failCapt、failFO）を参照し、毎フレーム X-Plane の故障 dataref `rel_esys2`・`rel_esys3` に 0 を書く。ユーザーがかけたバス故障を消してしまう | — | electrical.lua:549-555 |
| ELEC-21 | バグ | 低 | S | Avionics.lua:70 の `puOn` は `gpuOn` の誤記（XP12 では gpuOn が常に false）。出力の Ext_Power_Av・Eng_Gen_on はどこからも使われていない。X-Plane の avionics_on（LIT テクスチャ）は BATTERY スイッチ連動で、バスの通電とは無関係 | — | Avionics.lua:66-90 |
| ELEC-22 | 欠落 | 低 | S | GEN FIELD MAN RESET、SSB スイッチ、FIELD OFF/OPEN 灯（overhead maintenance panel）が無い。3D にも操作部が無い | FCOM p.788; LH24 p.28 | なし |
| ELEC-23 | 欠落 | 低 | S | EICAS status（DRIVE DISC n、ELEC DRIVE n、BAT CHARGER MAIN/APU、ELEC TR UNIT、ELEC IDG VALVE）が無い | LH24 p.64, p.72, p.82, p.186, p.198 | なし |
| ELEC-24 | バグ | 低 | S | `laminar/B747/electrical/oil` をどこでも作っていない（find しているだけで、使っていない） | — | electrical.lua:104 |

### 油圧（ATA 29）（HYD、23 件：高 10・中 5・低 8）

詳細と出典の全文：[notes/ATA-29.md](notes/ATA-29.md)

| ID | 種別 | 重要度 | 規模 | 内容 | 根拠 | 該当コード |
|---|---|---|---|---|---|---|
| HYD-01 | 挙動の誤り | 高 | M | EDP 圧を `40×N1` で出している。アイドル（N1 20 % 台）で 1000 psi 前後、停止で 0、風車回転では使えない。実機は圧力補償型で、回っていれば約 3000 psi、流量能力が N2 に比例。fire switch・SOV・量（スタンドパイプ）も見ていない。系統圧も最大 3300 psi・毎フレーム最大 50 psi の乱数、ポンプ停止で数秒で 0 になる作り | ATA29_32 p.26・44、ATA22 p.6、FCTM p.286 | `B747.19.xt.hydraulicsmodel.lua:384-408`、`:478-497` |
| HYD-02 | 挙動の誤り | 高 | M | demand pump の AUTO が「EDP < 2500 psi」だけ。1400/1600 psi のスイッチ、0.3 s/14 s タイマー、FUEL CONTROL CUTOFF での運転、系統 1・4 のフラップ論理（地上で移動中、空中で > 0、右/左 FCU）が無い。HYD-01 と合わせ、アイドルでは demand pump が常時回る | ATA29_32 p.29–30・61–64・70–72・141・143、FCOM p.1483 | `B747.19.xt.hydraulicsmodel.lua:410-455` |
| HYD-03 | 欠落 | 高 | M | demand pump の電源・抽気依存が無い。ACMP 2/3 は常に 3000 psi（AC bus 2/3、DC 制御、HYDIM 電源を見ない）。1.5/3.0 s の始動遅れ、電気負荷も無い。ADP は `duct_pressure×110` で、DC bus 1/4 の制御電源を見ない（調速されず、ダクト圧に比例） | ATA29_32 p.63 図・p.70–71・p.54、ATA22 p.22・24 | `B747.19.xt.hydraulicsmodel.lua:411-446` |
| HYD-04 | バグ | 高 | S | AUX：セレクタが AUX なら空地・ground handling bus・EDP 圧に関係なく 2950 psi。AUX から OFF を経ずに AUTO/ON に移ると `aux_pressure` が 0 に戻らない（OFF の分岐でしか 0 にしない）。quick start がまさに -1 → 1 と書くので、以後ずっと系統 4 が AUX で加圧され synoptic に AUX の流れが出る | ATA29_32 p.86–88、FCOM p.1483 | `B747.19.xt.hydraulicsmodel.lua:448-462`、`B747.95.xt.AI.lua:2398` |
| HYD-05 | 欠落 | 高 | S | エンジン fire switch が油圧に何もしない（SOV 閉、EDP 減圧、demand pump 起動）。synoptic の SOV（`valve_n`）は ENGINE pump スイッチの位置をそのまま出している | FCOM p.905・p.1490、ATA29_32 p.40・44–48 | `B747.19.xt.hydraulicsmodel.lua:344-375` |
| HYD-06 | 挙動の誤り | 高 | S | 舵面の系統の組の誤り：upper rudder が 1+2（正：1+3）、L INBD AIL が 1+2（正：1+3）、R OUTBD AIL が 2+3+4（正：3+4）。L OUTBD AIL 1+2、R INBD AIL 2+4、昇降舵 4 枚、lower rudder 2+4、spoiler 3 群は正しい | FCOM p.948・950・1491 | `B747.19.xt.hydraulics_override.lua:296`、`:319`、`:331` |
| HYD-07 | バグ | 低 | S | spoiler 8 の消費量に lower rudder の変化量（`controlDiff[1]`）を使っている（正：`controlDiff[18]`） | — | `B747.19.xt.hydraulics_override.lua:266` |
| HYD-08 | バグ | 中 | S | X-Plane の `rel_hydleak3` 処理で `hydfailed3` ではなく `hydfailed2` を立てる。毎フレーム故障先（系統 3 か 4）と速さを選び直し、結局 3 と 4 の両方が抜ける | — | `B747.19.xt.hydraulicsmodel.lua:775-779` |
| HYD-09 | 欠落 | 高 | M | ブレーキが油圧源で制限されない。normal（4）→ alternate（4 < 1200 で 1、さらに 1 < 1500 で 2）→ accumulator の選択も、autobrake の normal 系統依存も無い。ブレーキは X-Plane の標準（X-Plane 側の油圧は常に加圧、§6.1）。BRAKE SOURCE だけは 1・2・4 < 1000 psi で出す。ATA 32 と調整 | ATA29_32 p.388–392、FCOM p.1514–1516 | `B747.10.xt.gear.lua:727-734`、`B747.20.xt.hydraulics.lua:339-344`、`B747.90.xt.lighting.lua:1375-1376` |
| HYD-10 | 挙動の誤り | 中 | S | brake accumulator（計器 `hydraulic_pressure_1_2_4`）を系統 1・2・4 の最大値で充圧（正：系統 4 のみ）。減るのはパーキングブレーキを掛けた量だけで、0 まで下がる（予圧 750 psi は下回らない `推定`）。< 1000 psi でパーキングブレーキを外す処理が fltCtrls 側にある | ATA29_32 p.408–416、FCOM p.1516 | `B747.19.xt.hydraulicsmodel.lua:503`、`B747.19.xt.hydraulics_override.lua:198-213`、`B747.45.xt.fltCtrls.lua:1056` |
| HYD-11 | 欠落 | 高 | L | 舵面以外の負荷が 4 系統モデルで止まらない：脚（nose/body 1、wing 4。X-Plane 標準の gear handle）、逆推力（P&W は関連系統。`hydraulic_pressure_ratio` を宣言したが未使用）、stab trim（2/3、X-Plane 標準のトリム）、elev feel（2/3）、YD（上 3/下 2。ON 条件に油圧が無い）。油圧側は「動力あり」信号を出し、各担当が使う | FCOM p.893・943・945・949・1511、§2.4 | `B747.10.xt.gear.lua:146-170`、`B747.40.xt.engines.lua:142-143`、`:351`、`B747.45.xt.fltCtrls.lua:715-738` |
| HYD-12 | 挙動の誤り | 中 | S | 系統 1 < 1000 psi でステアリングを override したまま何も書かず、前輪が直前の角度で固まる（正：操向不能。前輪はセンタリングか自由キャスター `推定`）。20 kt の切替に IAS を使う（FCOM は対地速度、ATA 32）。低速で override 0 のとき acf の `_steerdeg_*`（custom 75/35、純正 70/7）が効く | FCOM p.1513、FCTM p.297 | `B747.19.xt.hydraulics_override.lua:1123-1136` |
| HYD-13 | 挙動の誤り | 中 | S | X-Plane 油圧への干渉（§6.1）：ENGINE pump スイッチで `rel_hydpmp`〜`rel_hydpmp4`（XP12 では系統単位のポンプ故障）を毎フレーム書き、電動ポンプを常時 ON。故障メニューの上書き、ENG 1・2 OFF で脚の下げ固定が起きる恐れ（未確認）。ENGINE PRESS 灯もこの故障 dataref をスイッチ代わりに読む | DataRefs.txt、acf `_hyd_*` | `B747.20.xt.hydraulics.lua:245-325`、`B747.90.xt.lighting.lua:1122-1125` |
| HYD-14 | 挙動の誤り | 高 | S | パネル灯：ENGINE PRESS＝エンジン停止かスイッチ OFF（正：EDP 圧 < 1400 が 2 秒）。DEMAND PRESS＝セレクタ OFF のときだけ（正：OFF・AUX・指令中の圧低・不始動。Before Start で「AUX で点灯のまま」を確認できない）。SYS FAULT＝< 1000 psi か量 < 0.1（正：< 1200 psi 2 秒、量 0.34、> 104 °C） | FCOM p.1483–1484・p.119、ATA29_32 p.30・98・141 | `B747.90.xt.lighting.lua:1121-1125`、`:1414-1424` |
| HYD-15 | 欠落 | 高 | S | EICAS：HYD PRESS ENG・HYD PRESS DEM・HYD OVHT SYS・HYD CONTROL は定義だけで一度も立たない。HYD PRESS SYS は 1000 psi・遅れ無し（正：1200 psi・2 秒）。抑止（SYS による ENG/DEM の抑止、CUTOFF・fire switch）も無い | FCOM p.1495・1582・1586、ATA29_32 p.98・141・143 | `B747.20.xt.hydraulics.lua:346-366`、`B747.87.xt.warning.lua:386-399` |
| HYD-16 | 挙動の誤り | 中 | S | 作動油量：飛行開始ごとに 0.55–0.95 の乱数（2 モジュールが別々に初期化し、後から走る B747.20 が勝つ）→ RF が頻繁に出る（正規量は 1.00）。RF を空中でも出す（正：地上のみ）。LO（< 0.35）では SYS FAULT 灯が点かない（灯は量 < 0.1、HYD-14）。量の変化は「圧 3000 psi で -0.10」だけ | FCOM p.1485・1489、ATA29_32 p.116 | `B747.20.xt.hydraulics.lua:376-389`、`:439-450`、`B747.19.xt.hydraulicsmodel.lua:499-502`、`:706-713` |
| HYD-17 | 挙動の誤り | 低 | M | 油温＝外気温 + (1 − 量)×20。ポンプ運転や熱交換器（タンク燃料）と無関係で、104 °C に届かず過熱が起こりえない | ATA29_32 p.74–76・100 | `B747.19.xt.hydraulicsmodel.lua:505-508` |
| HYD-18 | 欠落 | 低 | M | リザーバ与圧（抽気、45 psi、< 6.3 psig で RSVR PRESS と STATUS）が無い。synoptic への表示は計器追加（カスタム acf のみ、承認事項）が要る | ATA29_32 p.38・104、FCOM p.1488 | なし |
| HYD-19 | 挙動の誤り | 低 | M | synoptic の表現力不足（§6.2）：DEM の ON 文字・色・AUX の ON/OFF 文字が無い、系統 4 の OFF が出ない、SOV と EDP OFF が同じ dataref、不作動項目の組み合わせ（`pressure_13/24/234`）が負荷の組と合わない。コード側で直せるのは組み合わせ dataref の定義だけで、残りはカスタム acf のパネル変更 | FCOM p.1487・1490、ATA29_32 p.107–109 | `B747.19.xt.hydraulicsmodel.lua:494-497`、`747-400.acf:136170-137410` |
| HYD-20 | 欠落 | 低 | M | 油圧の STATUS メッセージ（ポンプ圧、過熱、リザーバ与圧、HYDIM バス）が無い。STATUS のメッセージ欄自体が固定 1 ページで未実装（ATA 31 と共通） | ATA29_32 p.136 | `B747.60.xt.fltInst02.lua:3432-3433` |
| HYD-21 | 欠落 | 低 | S | スタンドパイプ：量 0.00 で EDP だけが吸入を失い、demand pump は残量で回る。現状は `restotal` ≤ 0.1 で系統圧を丸ごと 0 にする | ATA29_32 p.104 | `B747.19.xt.hydraulics_override.lua:95-114` |
| HYD-22 | 欠落 | 低 | M | FLT CONTROL HYD POWER（系統ごとの TAIL/WING 遮断弁と VALVE CLOSED 灯）が無い。灯の明るさは常に 0、Lua 側にスイッチのコマンドも無い（3D の操作子の有無は未確認） | FCOM p.940、ATA22 p.18 | `B747.90.xt.lighting.lua:1381-1389` |
| HYD-23 | 挙動の誤り | 低 | S | ACF_DIFF §3.5：カスタム acf の舵面別油圧割り当て（1・2・5・6）。`override_control_surfaces`=1 と manual reversion 1.0 のため舵面には効かない見込み。コードはこの値を読まない。ビット 4 は X-Plane の系統 C（ポンプ無し）と `推定`。要確認、必要なら 0 に戻す | ACF_DIFF §3.5、DataRefs.txt | `B747.19.xt.hydraulics_override.lua:1119` |

### 空圧（ATA 36）（PNEU、14 件：高 1・中 7・低 6）

詳細と出典の全文：[notes/ATA-36.md](notes/ATA-36.md)

| ID | 種別 | 重要度 | 規模 | 内容 | 根拠 | 該当コード |
|---|---|---|---|---|---|---|
| PNEU-01 | 欠落 | 高 | L | ダクト圧が「開いている源の最大値」で、需要（パック、NAI/WAI、ADP、スターター、LE フラップなど）に全く依存しない。源の圧は N1 から線形（エンジン 0–50% N1 で 0→約 35〜40 psi、APU 0–80% N1 で 0→約 35〜41 psi、上限は読込みごとの乱数）。APU で全パックのまま始動できる、ダクト隔離時の 1 パック制限が意味を持たない、ADP の出力も需要と無関係になる | FCOM p.895 (7.30.1)、p.183 (SP.7.1)、p.123 (NP.21.29)、p.614 (2.40.4)、LH36 p.64 | AIR:425-454、AIR:701-762、HYD:410-455 |
| PNEU-02 | 欠落 | 中 | M | エンジン側が PRSOV 1 弁だけ（「スイッチ ON かつ psi ≥12 で開」）。HPSOV/PRV、IP/HP 切替、PRSOV の逆流防止（ダクト圧のほうが高いと閉）、始動中の PRV 閉と 15 s 遅れ、過熱ラッチとスイッチでのリセットが無い。>BLEED n OFF は N2 >50% でなく X-Plane の ENGN_running で判定 | FCOM p.576 (2.10.24)、p.612 (2.40.2)、LH36 p.12・p.48・p.64・p.76・p.100、ATA30_32_35_36 p.19 | AIR:465-661、AIR:955-997 |
| PNEU-03 | 欠落 | 中 | M | 抽気系の故障と警報が無い。SYS FAULT 灯は X-Plane の bleed_air_fail アナンシエーターの直結。BLD n OVHT/PRV、BLEED n、BLEED HP ENG n、BLD DUCT LEAK L/C/R はメッセージ表にあるだけで、立てるコードが無い | FCOM p.575 (2.10.23)、p.619 (2.50.1)、LH36 p.12・p.100-102、ATA26_28 p.284-286 | LIT:1434-1437、WRN:114-116、WRN:208-219 |
| PNEU-04 | 欠落 | 中 | S | BLEED ISLN L/R（advisory、beeper、10 s）と >BLEED ISLN APU が未実装。弁の動きがほぼ瞬時（アニメーション速度 20）なので VALVE 灯も実際にはほとんど点かない | FCOM p.575、p.619、ATA30_32_35_36 p.22・p.28、LH36 p.78 | AIR:671-694、WRN:220-222、LIT:1338-1357 |
| PNEU-05 | 挙動の誤り | 中 | S | APU 抽気弁が APU N1 約 27%（psi >12）で開き、APU セレクター OFF（60 s の冷却中）や APU 火災スイッチで閉じない。電源も不要として扱っている。実機は APU RUNNING（N1 ≥95%、+2 s）で開き、セレクター OFF で即閉、115V AC bus 2 のモーター弁 | FCOM p.575、p.867 (7.14.1)、p.897 (7.30.3)、LH36 p.88-89 | AIR:440、AIR:488-496 |
| PNEU-06 | 挙動の誤り | 低 | S | ISLN の電源判定が X-Plane の bus 0 だけで、電源が切れると閉じる。実機は L が AC bus 1、R が AC bus 3 のモーター弁（電源喪失時の位置は資料に記載なし。保持すると推定） | LH36 p.86-87 | AIR:468-485 |
| PNEU-07 | 欠落 | 中 | M | 地上空気（エアカート）が無い（psi 0 固定、TODO）。地上空気での始動（30 psi 規定）、EXT AIR 表示が再現できない。EXT AIR は acf に要素が無い | FCOM p.183 (SP.7.1)、p.578 (2.10.26)、p.613 | AIR:435-437 |
| PNEU-08 | 欠落 | 中 | M | 始動の空気条件が緩い。始動弁はダクト圧 >12 psi で開き、スターターの回転はダクト圧に依存しない。`min_engine_start_duct_pressure = 25` は未使用。アイドルのエンジンからのクロスブリード始動や 3 パック ON のままの APU 始動もできてしまう（ENG 側との調整が要る） | FCOM p.183 (SP.7.1)、p.879 (7.20.9)、p.895 | AIR:469、AIR:499-536、ENG:1815-1872 |
| PNEU-09 | 挙動の誤り | 低 | S | 主 EICAS のダクト圧ブロックの表示条件に FCOM に無い条件（ダクト圧 <11、CABIN ALT AUTO、OUTFLOW VLV、変化率）が入っている。表示の大半は ATA 21 の担当なので調整して直す | FCOM p.585 (2.10.33)、ATA30_32_35_36 p.128 | AIR:892-922 |
| PNEU-10 | 挙動の誤り | 低 | S | 表示の閾値: 主 EICAS の右の白 LED が `duct_pressure_L` を参照し、11.00〜11.01 psi ではどの LED も出ない。ECS synoptic は 12.0 ちょうどで出ない。FCOM は 12 以上白・11 以下琥珀。プラグイン側の出力で回避し、右 LED はカスタム acf で直す（要承認） | FCOM p.578、p.585 | ACF:124722-124781、ACF:135413-135430 |
| PNEU-11 | 挙動の誤り | 低 | S | ECS synoptic のエンジン区間の流れが `bleed_air_psi` >11 だけで決まり、スイッチ off で PRSOV が閉でも流れが出る。APU 区間の流れも APU 弁と無関係。PRSOV の琥珀 OFF、移動中の記号が無い（acf の制約。§6 の再定義で一部は直る） | FCOM p.576、LH36 p.16 | AIR:442-452、ACF:135190-135260 |
| PNEU-12 | 欠落 | 低 | M | GE の逆推力用の抽気（スイッチ off でも HPSOV/PRV 開、低出力で HPSOV 開）が無い | FCOM p.576 (570)、p.893 (7.20.23)、ATA30_32_35_36 p.19 | なし |
| PNEU-13 | 挙動の誤り | 中 | M | EEC の抽気補正: パック数を選択器の値の合計で数えるため A（2）・B（3）を選ぶと誤る。実際の抽気源（APU→パック、エンジン抽気 off）を見ない。GE は Go-around の補正表（PI.20.32 と同じ値）を離陸・上昇・巡航に流用。防氷の補正は ATA-30 の ICE-11 | FCOM p.263 (PI.10.37)、p.300 (PI.15.6)、p.360 (PI.20.32) | EEC/B747.42.xt.EEC.GE.lua:501-516、EEC/B747.42.xt.EEC.PW.lua:547-562、EEC/B747.42.xt.EEC.tbls.lua:93-107・338-342 |
| PNEU-14 | 挙動の誤り | 低 | S | X-Plane 本体の抽気モデルとの関係が未整理。`isol_valve_left/right` を書いているが `_has_full_bleed_air 0` なので効かないと推定。X-Plane の抽気損失（engine_loss_from_bleed_air_ratio）はプラグインの弁状態と無関係に X-Plane が計算している（推定） | DataRefs.txt（X-Plane 12）、acf | AIR:102-103、AIR:712・717・739・744 |

### APU（ATA 49）（APU、13 件：高 0・中 5・低 8）

詳細と出典の全文：[notes/ATA-49.md](notes/ATA-49.md)

| ID | 種別 | 重要度 | 規模 | 内容 | 根拠 | 該当コード |
|---|---|---|---|---|---|---|
| APU-01 | 挙動の誤り | 中 | S | APU N2 の表示が「85.5 × inlet door の開度」。APU が止まっていても door が開けば 85.5% になり、回転と関係しない | FCOM p.868 | ENG:1341 |
| APU-02 | 挙動の誤り | 低 | S | APU の油量は乱数の初期値（0.75〜1.0）から N2 × 0.003 を引くだけ。RF/LO（magenta）が無い | FCOM p.868–869 | ENG:1318、ENG:1326、ACF:129779 |
| APU-03 | バグ | 中 | S | APU DOOR が「door 全開で APU 停止中」か「door 全閉で運転中」で出る。selector ON から START までの正常な待ち（door 開・未始動）や停止直後にも出る。FCOM は door が指令位置にないとき | FCOM p.902 | ELEC:861-870 |
| APU-04 | 挙動の誤り | 中 | S | APU advisory が「selector ON（ON と START）で APU N1 <0.1%」で出るので、始動前の正常な状態でも出る。FCOM は selector ON で自動停止したとき（OFF なのに N1 >95% の側は cooldown を除外していて合っている） | FCOM p.902 | ELEC:852-859 |
| APU-05 | 挙動の誤り | 低 | S | APU RUNNING が selector に関係なく N1 >95% で出る（cooldown 中も出る）。FCOM は selector ON かつ N1 >95% | FCOM p.897、p.902 | ELEC:920-926 |
| APU-06 | 欠落 | 中 | M | 自動停止が無い。限界超過、火災（X-Plane の APU 火災故障で止まるかは未確認）、抽気ダクト過熱（再始動不可）。selector OFF での fault のリセットも無い。FIRE APU のメッセージを立てる処理も無い（ATA 26 担当） | FCOM p.613、p.867、p.897、p.907、p.921 | ELEC:649-746、FIRE:53・FIRE:330 |
| APU-07 | 挙動の誤り | 低 | S | 始動を許すのが inlet door 13% 開。FCOM は全開で starter 係合。door の動きは速度係数 0.04 の指数で非常に遅い（時定数 約 25 s） | FCOM p.896 | ELEC:684、ELEC:699 |
| APU-08 | 挙動の誤り | 低 | S | selector OFF の後の 60 s cooldown 中も APU bleed valve が開いたまま（弁は APU の圧だけで開閉）。FCOM は OFF で bleed valve を閉じ、無負荷で cooldown | FCOM p.867、p.897 | AIR:488-496、ELEC:663-671 |
| APU-09 | 欠落 | 低 | M | 始動電源と始動回数の制限が無い。APU battery・main battery・TR、570 の APU START SOURCE、TR 過熱時の battery 切替、始動間の待ち時間 | FCOM p.868、p.895–897 | なし |
| APU-10 | 欠落 | 低 | S | 運用範囲が無い。空中の運転上限 20,000 ft、空中の抽気は 1 pack・15,000 ft まで、エンジン始動中の pack の制限。発電機は地上でしか ON にならないが、地上で ON にしたものは空中でも ON のまま（要確認、ATA 24 担当） | FCOM p.895 | ELEC:710-721 |
| APU-11 | 欠落 | 低 | S | APU は燃料弁・ポンプ・main 2 の残量に関係なく回る。燃料消費は「弁開かつポンプ ON」で一定 500 kg/h（APU が止まっていても減る）。APU FUEL は弁位置と selector の不一致だけで、ポンプの低圧を見ない | FCOM p.902、p.1464–1465、ATA26_28 p.478–480 | FUEL:944-952、FUEL:1369-1374、FUEL:2100-2106、FUEL:2847-2856 |
| APU-12 | 欠落 | 低 | S | エンジン始動時の増風要求が無い。APU の抽気圧は APU N1 だけの関数（0–80% N1 で 0 → 35〜41 psi、上限は乱数） | ATA70_80 p.556–557、FCOM p.895 | AIR:425-440 |
| APU-13 | 挙動の誤り | 中 | S | 始動の指令が保持されない。FCOM の手順（selector を START に回して ON に戻す）では、吸気ドアが開く前に START を離すことになり、APU が始動しない。今の実装は、ON でドアを開けてから START に回し、ドアが 13% 開くまで START に置く必要がある（2026-10-23 の基準シナリオ s00 で確認。この項目はノートの作成後に追加） | FCOM p.180 (SP.6.2)、p.896 (7.30.2) | ELEC:682-688 |

### 燃料（ATA 28）（FUEL、25 件：高 5・中 8・低 12）

詳細と出典の全文：[notes/ATA-28.md](notes/ATA-28.md)

| ID | 種別 | 重要度 | 規模 | 内容 | 根拠 | 該当コード |
|---|---|---|---|---|---|---|
| FUEL-01 | 欠落 | 高 | M | 吸引供給が無い。xfeed 閉で自タンクのポンプが止まる（スイッチ OFF・無電源）と供給源が空になり `has_fuel=0` でフレームアウト。さらに電源（sim bus 0）が無いと spar valve が閉じる（「無電源で閉」の扱い）ので全発停止。FUEL PRESS ENG 1–4（caution 32–35）は誰も立てない | FCOM p.1455、p.1477、ATA26_28 p.454・464・466 | 1769-1779、1221、1327-1333、2013-2016 |
| FUEL-02 | 挙動の誤り | 高 | M | マニフォールドの供給源が CWT・O/J 2・3 だけで、xfeed 経由の他の主タンクのポンプを考えない。xfeed 開で自タンクのポンプが OFF だと O/J も OFF のとき供給源なし → SP.12 の均衡手順（1↔4、2↔3、前後）はどれもエンジン停止になる | FCOM p.199 (SP.12.1)、p.1454–1455 | 1722-1740、1744-1748、1785-1790 ほか各エンジン |
| FUEL-03 | バグ | 高 | S | 不均衡メッセージ：IMBAL 2-3 の閾値が 1,360 kg（正 2,720）。1-4・2-3 の解除処理が 0 でなく 1 を代入し、実質ヒステリシス無し（閾値で消える）。FUEL IMBALANCE は式が `(m2+m3)-(m3+m4)` の誤りで、立つ条件も FCOM と別（片側差 2,720 kg） | FCOM p.1473 | 2890-2935 |
| FUEL-04 | 挙動の誤り | 高 | S | CWT 関連：FUEL LOW CTR は 1,300 kg の場合だけで、始動前 < 7,700 kg・上昇中 ≈3,200 kg・ピッチによる上昇/巡航の区別・ジェティソン中の抑止が無い（抑止に FUEL STAB XFR の caution[37] を使っている）。FUEL OVD CTR の空中 1,800 kg が上昇中にも出て NP の手順と食い違う。FUEL PRESS CTR に「スイッチ ON で低圧」の経路が無い | FCOM p.1474–1476、NP p.133–135 | 2797-2807、2937-2957、2991-3028 |
| FUEL-05 | 挙動の誤り（acf） | 高 | S | 消費が X-Plane の FF（acf SFC）依存。カスタム acf の SFC は純正と大差で、推定では巡航で過少・離陸で過大。消費・FUEL USED・FMC 予測がずれる（コードは acf 値に依存している） | ACF_DIFF §3.2、FCOM p.268 | 376、2274-2320、`progress.lua:64`、acf `_jet_SFC_*` |
| FUEL-06 | バグ | 中 | S | FUEL PUMP 2/3/4 FWD/AFT が主 1 のポンプ状態を参照（コピー誤り）。低圧はタンク ≤ 10 kg のときだけで、スイッチ OFF・無電源・故障を検出しない | FCOM p.1477、ATA26_28 p.414 | 3057-3151 |
| FUEL-07 | 挙動の誤り | 中 | S | xfeed 2・3：40 s 遅延なし、空中での閉指令保持なし（離陸と同時に開く。正しくはフラップが 10–20 を出たとき）、takeoff disagree なし | ATA26_28 p.461–463、FCOM p.1465–1466 | 1344-1353、1397-1410 |
| FUEL-08 | 挙動の誤り | 中 | S | 頭上灯：主ポンプ PRESS は「スイッチ OFF かつエンジン停止」か「ON でタンク空」のときだけ（飛行中に OFF でも消灯）。xfeed 2・3 とノズルの VALVE 灯は常に 0。CTR PRESS は無電源で点かない | FCOM p.1439–1441、ATA26_28 p.414 | `B747.90.xt.lighting.lua:1133-1140`、`1143-1158`、`1175-1244` |
| FUEL-09 | 欠落 | 中 | M | 電源：全ポンプ・弁が sim bus 0 の有無だけで動く。AC バス別、utility bus の負荷制限、battery／hot battery bus のバルブ、弁の位置保持が無い。O/J 2・3 は通常モードで電源を見ない | FCOM p.795・801・819–820、ATA26_28 p.452・458・463・466・500・502 | 704、1221、900、935、1006、1041 |
| FUEL-10 | バグ | 中 | S | HST（109 型）：R ポンプのジェティソンモードが L スイッチ [54] を参照、ジェティソン時の HST 移送/投棄弁の条件が逆（総量 ≤ FTR で開）、HST 燃料が機外へ投棄されない、FUEL STAB XFR・FUEL PRES STB を立てない。CAS 67・68 は両方 "FUEL PRES STAB L" で caution 表にある（FCOM は advisory の FUEL PRES STB L/R） | FCOM p.1455・1466・1468・1476–1477、ATA26_28 p.519・540 | 1164、1510、1531、2046-2047、2236-2248、`B747.87.xt.warning.lua:175-176` |
| FUEL-11 | 挙動の誤り | 中 | S | 予備移送が片側ずつ（主 2→予備 2 だけ）。正しくは主 2 か 3 で 4 弁とも開、空中のみ、接地で閉。予備が空になると閉じ、ラッチは解除されない。FUEL RES XFR を立てない | FCOM p.1464・1467、ATA26_28 p.498–500・555 | 1556-1615 |
| FUEL-12 | 挙動の誤り | 中 | M | ジェティソン：主 2・3 の均衡なし、主 1・4 移送弁が片側ずつ、CWT が 3,200 kg で止まる（正：約 390 gal）、ノズル弁が選択器 A/B のときだけ開く（正：スイッチ直結）、時間の 90 s 後更新なし、完了後の FUEL OVRD なし、>FUEL JETT A/B なし | FCOM p.1441・1468–1470・1474、ATA26_28 p.335・443・540・546 | 1296-1309、1457-1470、1625-1642、2085-2094、2775-2794 |
| FUEL-13 | 欠落 | 中 | M | FMC 側：TOTALIZER と CALCULATED が同じ `m_fuel_total`、PERF INIT の CALC/SENSED/MANUAL なし、FUEL DISAGREE なし、FUEL USED がエンジン始動で消えず APU 消費を含む（FMC 担当と調整） | FCOM p.1274・1378–1379・1432 | `B744.fms.pages.progress.lua:146-150,185-189`、`perfinit.lua:47-68`、2285-2321 |
| FUEL-14 | 挙動の誤り | 低 | S | スカベンジ流量がジェットポンプ 1 本 545 kg/h×4（計約 2,180 kg/h）。ATA は 4 本合計で約 1,200 lb/h。>SCAV PUMP ON（405 の電動ポンプ用）をジェットポンプで出す | ATA26_28 p.512、FCOM p.1454・1479 | 2068-2075、3224-3238 |
| FUEL-15 | 欠落 | 低 | M | 故障・不一致：ポンプ・弁の故障モデルが無い。FUEL X FEED 1–4、>JETT NOZZLE L/R、FUEL TEMP SYS を立てない。弁の移動が約 0.3 s（実機 3–5 s） | FCOM p.1478–1479、ATA26_28 p.346・464 | 1665-1718、CAS 173・175–178・238–239 |
| FUEL-16 | 挙動の誤り | 低 | S | FUEL OVRD 2・3：スイッチ OFF の場合だけ。作動中の低圧（スタンドパイプ以下）を出さない。「tank-to-engine 前」を量でなくスイッチ状態で判定 | FCOM p.1467・1474 | 2812-2823、2959-2989 |
| FUEL-17 | 挙動の誤り | 低 | S | O/J 2・3 の起動条件：CWT ポンプ片方の低圧を検出しない（両方 ON かつ CWT < 900 kg、または両方 OFF のときだけ）。shared flow なし | FCOM p.1466–1467、ATA26_28 p.528・535 | 893-898、928-933、999-1004、1034-1039 |
| FUEL-18 | 挙動の誤り | 低 | S | spar valve が消火スイッチで閉じない（`sim/cockpit2/annunciators/engine_fires < 6` は常に真）。エンジン燃料弁はエンジンモジュールが閉じるので停止はする | ATA26_28 p.466 | 1327-1333 ほか、`B747.40.xt.engines.lua:2051-2066` |
| FUEL-19 | 挙動の誤り | 低 | S | タンク容量定数が acf の容量とずれる。GE の主 1・4 容量を区別しない。貨物機設定でも HST がある | ATA26_28 p.335、FCOM p.1453・1456 | 78-85 |
| FUEL-20 | 挙動の誤り | 低 | S | 燃料温度は TAT への一次遅れ（係数 0.0001）で根拠なし。EICAS の amber はパネルに無い。FUEL TEMP LOW が `<`（FCOM は以下） | FCOM p.1445・1453・1478 | 2338-2355、3167-3173 |
| FUEL-21 | 挙動の誤り | 低 | S | 起動時・給油：100 t 超で開始すると固定配分に書き換え差分を給油待ちにする、給油開始時に全燃料を再配分、給油順は資料で確認できない、飛行中の増加を巻き戻す、タンク量が負になりうる | ATA26_28 p.370・376 | 2141-2164、2282、3262-3454 |
| FUEL-22 | 挙動の誤り | 低 | S | APU 消費は APU の運転状態によらず 500 kg/h を主 2・3 から半分ずつ。FCOM は通常主 2 から | FCOM p.1464–1465 | 2101-2110、2271-2272 |
| FUEL-23 | 挙動の誤り（acf） | 低 | S | タンク 7 の `_tank_role`（純正 Feeder、カスタム Normal）。override 中は影響なしと推定、コードは読まない | ACF_DIFF §3.6 | なし |
| FUEL-24 | 欠落（表示） | 低 | M | synoptic の制約：ポンプ amber はタンク < 10 kg（O/J も）、主タンク amber は < 900 kg だけ、FTR は LBS 表示でも kg、コンパクト表示なし、主 2 O/J AFT のジェティソン表示の dataref が `blaminar/...` の誤記 | FCOM p.1445–1448、ATA26_28 p.421 | `747-400_custom.acf:122861,123098-123160,123306,123378,114869` |
| FUEL-25 | 挙動の誤り | 低 | S | EICAS の文言：`FUEL OVRD CTR`（FCOM `>FUEL OVD CTR`）、`FUEL PMP STAB`（`>FUEL PMP STB`）、`>FUEL TEMP LOW`（`FUEL TEMP LOW`）、この FCOM に無い `>FUEL WING ISOL`。TANK/ENG の地上 +500 kg 許容なし | FCOM p.1474–1479 | `B747.87.xt.warning.lua:339-346,358,360`、3153-3165 |

### エンジン（ATA 71〜80）（ENG、38 件：高 6・中 20・低 12）

詳細と出典の全文：[notes/ATA-70-80.md](notes/ATA-70-80.md)

| ID | 種別 | 重要度 | 規模 | 内容 | 根拠 | 該当コード |
|---|---|---|---|---|---|---|
| ENG-01 | 挙動の誤り | 高 | L | レバーと推力指令の関係が違う。GE はレバー 0–1 を N1 25–116% に直線で割り当て、外気・高度・rating に依らない。PW/RR は EPR 0.95 から display_EPR_max までで、display_EPR_max は FMC のモード（TO/CLB/CRZ/GA）の基準値なので、同じレバー位置の推力が FMC のモードで変わる。full forward が EEC の max rated thrust にならず、上昇中にレバーを固定しても推力が一定にならない | FCOM p.873、p.875–876、ATA70_80 p.146–151・p.208–209 | EEC.GE:17-30、EEC.PW:17-20、EEC.RR:17-20、EEC:751-819 |
| ENG-02 | 挙動の誤り | 高 | M | Max N1/EPR の amber 線が EEC の max rated thrust でなく FMC の基準値。TO は離陸基準（derate 込みで下がる）、CLB は max(基準, 最大上昇)、CRZ は最大上昇、GA は GA 基準 | FCOM p.833、p.873、p.876、ATA70_80 p.331 | EEC.GE:535-594、EEC.PW:589-666、EEC.RR:771-856 |
| ENG-03 | 欠落 | 高 | M | 推力の上限が rating でなく acf の最大推力。full throttle で表示値が目標に届かないと acf_tmax を毎フレーム +200 N 増やし、1,500 ft RA 超で戻す。overspeed 保護は GE に無く（指令上限 116%）、PW/RR は表示 N1 >110.1% で EPR 目標を下げるだけ。N2 は監視しない | FCOM p.878、ATA70_80 p.205 | EEC:776-778、EEC.GE:597-610、EEC.PW:669-687、EEC.RR:860-878 |
| ENG-04 | 挙動の誤り | 中 | S | >ENG RPM LIM を「表示 N1 が red line 以上」（PW 111.41、GE 117.51、RR 111.51）で出す。FCOM は EEC が red line で推力を制限している状態で、GE は N2、PW は N1 か N2 | FCOM p.901 | ENG:1552-1604 |
| ENG-05 | 欠落 | 高 | M | ALTN にしても A/T が切れるだけ。制御量の切替（PW: EPR → N1）、max 制限の喪失、手動選択での推力増、自動 reversion、ALTN light の自動点灯、ENG EEC MODE、>ENG LIM PROT が無い。GE で 4 基とも ALTN にしたときの A/T 再使用もできない | FCOM p.864–865、p.876–877、p.899–900、p.322、ATA70_80 p.202–207 | EEC:1023-1030、EEC:1052-1099 |
| ENG-06 | 挙動の誤り | 中 | M | approach idle が空中で解除されない（条件が外れても high_idle_ratio 2.625 のまま着陸まで）。接地後 5 s の遅れが無い。high_idle_ratio は全エンジン共通でエンジン別にできない。109 では CON を条件に入れない（FCOM）点も未対応 | FCOM p.863、p.877–878、ATA70_80 p.206–211 | EEC.PW:37-65、EEC.GE:47-77、EEC.RR:37-65 |
| ENG-07 | 欠落 | 中 | S | ENG n LOW IDLE と >IDLE DISAGREE が出ない（IDLE DISAGREE は表にあるが誰も立てない、LOW IDLE は表にも無い） | FCOM p.900、p.902、ATA70_80 p.230 | WARN.init:341 |
| ENG-08 | 挙動の誤り | 高 | S | ENG n FAIL が warning の表にある（赤、master warning と siren）。FCOM は caution と beeper。判定は空中で表示 N2 <15%（CF6 は N2 <52% など）。ENG-19 の N2 書き換えと合わせると、風車回転の N2 が 22% 以上残る速度では出ない（推定）。最初の N1 <15% の判定は直後に上書きされ無効 | FCOM p.899、ATA70_80 p.230 | ENG:1400-1479、WARN.init:33-36 |
| ENG-09 | 挙動の誤り | 中 | S | >ENG n SHUTDOWN は空中だけで、fire switch は DISCH 位置（回したとき）で判定し、引いただけでは出ない。caution 共通の処理で master caution と beeper が出る（FCOM は master caution light なし、ATA は aural なしで他のエンジン msg を抑止） | FCOM p.902、ATA70_80 p.230 | ENG:1409-1471、WARN:836-852 |
| ENG-10 | バグ | 中 | S | STARTER CUTOUT は「start valve >0.05 かつ表示 N2 >45%」で遅れが無い。START switch の自動解除も 45% なので、正常な始動のたびに valve が閉じるまでの数フレーム caution が出る可能性がある（推定、要確認）。ATA は N2 >54% が 5 s | FCOM p.902、ATA70_80 p.558–559 | ENG:1480-1518 |
| ENG-11 | 挙動の誤り | 低 | S | starter cutout（START switch の解除と starter 停止）が表示 N2 45%。FCOM は 50%。starter を止めるのに X-Plane の `sim/starters/shut_down_n`（燃料と mags を切るコマンド）を送っている。同じ処理の中で mixture を書き戻すので影響は小さいと推定 | FCOM p.862、p.879 | ENG:1773-1798、ENG:1815-1879 |
| ENG-12 | 欠落 | 高 | L | autostart が無い。AUTOSTART ON でも「START と RUN の両方で start valve を開く」「N2 >15% で engine fuel valve を開く」だけ。EGT・N2・N1 の監視、no light-off・hot・hung の検出、再試行（GE 3 回、109 2 回）と 30 s motoring、中止、空中始動と windmill の燃料制御、auto-relight、ENG AUTOSTART、>AUTOSTART OFF が無い。405（autostart なし）と 109（4 スイッチ）の区別も無い | FCOM p.861、p.879–881、p.899、ATA70_80 p.561–569 | ENG:2047-2135、AIR:519-536 ほか 4 基分 |
| ENG-13 | バグ | 中 | S | AUTOSTART ON のとき engine fuel valve が N2 >15% で FUEL CONTROL の位置に関係なく開く（CUTOFF でも開）。燃料は spar valve で止まるのでエンジンは止まるが、弁の状態が誤りで FUEL VLV の判定の土台にならない | FCOM p.860、p.886 | ENG:2058-2062、2081-2085、2104-2108、2127-2131 |
| ENG-14 | 挙動の誤り | 中 | S | Fire switch を引くと engine fuel valve だけ閉じ、spar valve は X-Plane のエンジン火災故障（engine_fires = 6）で閉じる。FCOM は fire switch out で全弁閉 | FCOM p.886、ATA70_80 p.169 | ENG:2051-2052、FUEL:1325-1333 |
| ENG-15 | 欠落 | 中 | S | ENG n FUEL VLV が無い（表にも無い） | FCOM p.900、ATA70_80 p.168–169 | なし |
| ENG-16 | バグ | 中 | S | 計算した igniter の状態（B747_igniter_status）をどこにも使っていない（適用部はコメントアウト）。X-Plane の igniter は starter と一緒に ON になり、starter OFF で Eng 2〜4 は自分でなく igniter[0] を切る。結果、Eng 2〜4 は始動後ずっと連続点火、Eng 1 は他のエンジンの cutout で切れる | FCOM p.882 | ENG:1787-1798、ENG:1892-2038 |
| ENG-17 | 欠落 | 中 | M | AUTO IGNITION と STBY IGNITION が無効（STBY IGNITION ON memo だけ）。igniter 2 本の区別、AC BUS 1/3/STBY の電源、地上の交代、空中と flameout の両方、flaps・NAI・CON での点火、auto-relight が無い。X-Plane の auto_ignite は読込み直後の 1 回だけ | FCOM p.861–864、p.881–883、ATA70_80 p.260–271 | ELEC:294-319、ELEC:928-936、ENG:1372-1389 |
| ENG-18 | 欠落 | 低 | S | ENG IGNITION が出ない（表の index 109 を誰も立てない）。CON IGNITION ON の抑止条件で参照だけしている | FCOM p.900、p.902 | ENG:1606-1612、WARN.init:227 |
| ENG-19 | バグ | 中 | S | 燃料を燃やしておらず starter も回っていないエンジンで X-Plane の N2 が 22% 未満だと、毎フレーム 0 に書き換える（egt_thermal_profile 内）。空中では風車回転が消え、windmill 始動と N2 表示が成り立たない | FCOM p.879、p.881、ATA70_80 p.568–569 | EEC:565-568 |
| ENG-20 | 挙動の誤り | 中 | M | EGT の色と抑止。PW/RR の amber 抑止は A/T の TOGA 保持状態（TOGA_mode == 1）に連動し、それが解除されると（1,500 ft RA など）即解除。「TO/GA を押してから 5 min」でない。TOGA 中は amber band の線も消える。GE はパネルの固定閾値（925/960）で抑止なし。start limit の値（CF6 870。ATA は 750）はコードで未使用で、パネルは X-Plane の N2 <55% で固定画像を出すだけ | FCOM p.837–838、p.872、p.879、ATA70_80 p.356–357・p.395 | ENG:836-1172、ENG:2189-2201、ACF:122000、ACF:122091、ACF:122260 |
| ENG-21 | 欠落 | 中 | M | 超過の red box（正常域に戻っても枠が赤、CANC/RCL）と N2 の 20 s 規則が無い | FCOM p.873、ATA70_80 p.334・p.345–346・p.355–356 | なし（パネル追加が要る） |
| ENG-22 | 欠落 | 中 | M | partial format、compact format、二次エンジン exceedance cue、自動表示（N2 限界、油の caution・限界、OIL Q の low・differential、VIB high）が無い。`CAS/sec_eng_exceed_cue` は作るだけで誰も書かず、パネルも使わない | FCOM p.839–840、p.852–857、p.874–875 | WARN:616、FI02:1389 |
| ENG-23 | 挙動の誤り | 低 | S | 二次エンジン表示の自動選択が FUEL CONTROL の操作（RUN・CUTOFF とも、地上でも）で起きる。FCOM は空中で CUTOFF にしたときと最初の通電時 | FCOM p.843、p.872 | FUEL:569-596、FI02:3441 |
| ENG-24 | 欠落 | 中 | M | in-flight start envelope と X-BLD（magenta）が無い | FCOM p.840、p.851、p.879 | なし（パネル追加が要る） |
| ENG-25 | 挙動の誤り | 中 | S | 油圧の赤は全型式で固定 70 psi（starter 係合中で RUN でないときを除く）。CF6 の赤は 10 psid（N2 で 35 psi まで）。GE の amber band と ENG OIL PRESS が無い。値は X-Plane の油圧に乱数を足しただけ | FCOM p.846–847、p.901、ATA70_80 p.395・p.522 | ENG:1193-1213 |
| ENG-26 | 挙動の誤り | 低 | S | 油温: ENG OIL TEMP は全型式で 160 °C 超。パネルの閾値（amber 低 <50、amber 高、赤 >175）は型式に依らない。PW の値は資料に記載なし | FCOM p.847–848、p.901、ATA70_80 p.395 | ENG:1520-1534、ACF:128310 |
| ENG-27 | 挙動の誤り | 低 | S | 油量は乱数の初期値（約 33〜37）から N1 に応じて 7〜11 引く合成値。単位は全型式 liters（GE は US qt）。magenta（low、differential）が無い。Eng 2〜4 も Eng 1 の故障比率（oil_quantity_ratio[0]）を使う | FCOM p.848–849、p.890、ATA70_80 p.395 | ENG:69-77、ENG:1320-1327 |
| ENG-28 | 欠落 | 低 | S | ENG n OIL FILT が無い | FCOM p.900–901、ATA70_80 p.522–523 | なし |
| ENG-29 | 挙動の誤り | 低 | M | 振動は N2 比例の飾り（上限は乱数 ≤1.3、火災で 2〜3）。source はパネルの BB 画像固定。FAN/LPT/N2（GE）・N1/N2（PW）の選択、high band、自動表示が無い | FCOM p.849–850、p.894、ATA70_80 p.365–369 | ENG:1235-1311、ACF:129073 |
| ENG-30 | バグ | 低 | S | 型式文字列の判定順で "B1F" が "B1F1" に、"524H" が "524H8T" に先に一致し、B1F1 と H8T の分岐に入らない（推力と上昇率が B1F・H のまま） | — | EEC:598-603、EEC.GE:185-200・467-487、EEC.RR:180-250・694-717 |
| ENG-31 | 欠落 | 中 | M | 逆推力の deploy・stow は X-Plane 任せ。PW の油圧、GE の抽気とエンジン運転の条件が無い（油圧の dataref は読むだけ）。interlock は「deploy ratio >0.98 まで推力 0」でレバーは止まらない。90% 制限が無い（RR だけ N1 91% で acf 推力を削る）。auto-restow、REV INTERLOCK・REV POS が無く、ENG REVERSER は X-Plane の故障（rel_revers = 6）だけ | FCOM p.893–894、p.901、ATA70_80 p.206・p.442–475 | ENG:142-143、ENG:343-529、ENG:744-794、ENG:1536-1550、EEC:800-818、EEC.RR:504-513 |
| ENG-32 | バグ | 低 | S | B747_prop_mode の条件でループ外の未定義の `i` を添字に使う。XTLua は nil 添字で nil を返すので、その項は常に偽 | — | ENG:758 |
| ENG-33 | 挙動の誤り | 中 | L | 表示値の作り方。N1・EPR は推力からの回帰式、N2 は表示 N1 の関数、EGT は X-Plane EGT の比例換算（PW ×654/960、RR ×785/960）。GE は離陸中（TO 基準、または基準なしで 2,000 ft 未満）だけ X-Plane N1 × 離陸 N1/100 に切り替わり、基準モードが変わると表示が不連続になりうる（推定）。N1 と N2 が独立に動く故障を再現できない | FCOM p.833–834、p.843–844 | EEC.PW:306-482、EEC.GE:314-439、EEC.RR:394-660 |
| ENG-34 | 挙動の誤り | 中 | S | ACF_DIFF §3.2 との依存。(1) `_n1_rated_thrust`（カスタム 95、純正 100）: GE の離陸中の N1 表示と推力 boost の条件（X-Plane N1 >99.99）は「X-Plane N1 100% = 定格推力」、つまり純正 acf の値を前提にしている。カスタムでは表示が約 5% 低いか、PID が推力を余分に出す（推定）。(2) `_fadec_parameter`（カスタム 1 = N1、純正 0）: throttle は override しているが、X-Plane の FADEC が throttle_used を変える可能性がある（要確認）。(3) SFC: EEC は使わないが FF 表示（X-Plane の燃料流量）と消費に効く。カスタムは離陸 0.55、高高度巡航 0.38（純正 0.323、0.571）。(4) acf の最大推力と face area は EEC が実行時に上書きするので acf の値は効かない。(5) エンジン位置はコードが参照しない | ACF_DIFF §3.2 | EEC.GE:360-363、EEC.GE:599-603、EEC.PW:513-541、EEC.PW:671-675、FUEL:3563-3566 |
| ENG-35 | 挙動の誤り | 低 | S | acf のスプール時間を「4 基運転中 5 s、0 基 26 s」に書き換える（1〜3 基は直前の値）。加減速スケジュールは無い | ATA70_80 p.205 | ENG:870-881、ENG:1685 |
| ENG-36 | 欠落 | 低 | S | >ENG CONTROL と >ENG CONTROLS（EEC fault、空中抑止）が出ない（EEC の故障モデルが無い）。EEC MAINT POWER と >EEC TEST PWR（405）も無い | FCOM p.865、p.899 | WARN.init:228-231 |
| ENG-37 | 挙動の誤り | 低 | S | fuel-on indicator は CUTOFF なら fire switch を引いていても出る（ATA は引かれていないこと）。位置は固定画像 | FCOM p.844、p.851、ATA70_80 p.346 | ENG:1180-1188、ACF:125459 |
| ENG-38 | 欠落 | 中 | M | 始動空気の条件。starter はダクト圧に関係なく回り、start valve はダクト圧 >12 psi で開く。最低ダクト圧、クロスブリードの 70% N2、APU の増風、pack の影響が無い。ATA-36 の PNEU-08 と同じ問題で、エンジン側（starter のトルクと N2 の上がり方）も直す | FCOM p.183、p.879、ATA70_80 p.549–557 | ENG:1815-1879、AIR:469-536 |

### 空調・与圧・機器冷却（ATA 21）（AIR、22 件：高 6・中 11・低 5）

詳細と出典の全文：[notes/ATA-21.md](notes/ATA-21.md)

| ID | 種別 | 重要度 | 規模 | 内容 | 根拠 | 該当コード |
|---|---|---|---|---|---|---|
| AIR-01 | 欠落 | 高 | M | パック弁のモデルが無い。選択器（OFF/NORM/A/B）は memo・音・synoptic に使うだけ。弁の開閉、12 psi 未満で開かないこと、トリップ、流量（normal＝high の 2/3）が無い。X-Plane にもパック状態を渡していない（`sim/cockpit2/bleedair/actuators/pack_*` を書かず、`bleed_air_mode` はダクト圧だけで 0/2/4 を決める）。全パック OFF でも与圧が続くと推定 | FCOM p.560, 588; ATA21 p.42, 86 | :770-791, :1009-1062 |
| AIR-02 | 挙動の誤り | 高 | M | 自動与圧のスケジュールが実機と別物。客室の目標は min(8000, 機長の指示高度) で、機体が 8,000 ft に達するまで与圧しない。客室昇降率は機体 V/S を 500〜2,000 fpm に挟んだ値。takeoff（65 kt・−50 ft）、FMC による上昇（≤600/1,000 fpm）、巡航 ΔP 8.9、descent（T/D・1,000 ft）、着陸高度への降下、着陸後の減圧が無い。上昇中に客室 V/S が 700 fpm を超えるので、data block が毎回自動で出る（推定）。進入中の負の ΔP も出うる（推定） | FCOM p.607–608; ATA21 p.424, 428, 431–432, 435–436 | :806-866（:808, :844-845）、:917 |
| AIR-03 | 欠落 | 高 | M | 着陸高度。AUTO は固定 2,000 ft で、FMC との連携も LANDING ALT advisory も無い。MAN は 3D ノブの範囲 0〜5,000 ft をそのまま使う（実機は -1,000〜14,000 ft、50 ft 刻み）。着陸高度を与圧制御に使っていない。FMC 側に着陸高度・巡航高度・T/D を渡す仕組みが無い | FCOM p.573, 608, 620, 1400; ATA21 p.426, 437, 452 | :873-885; `747-400_cockpit.obj:22164` |
| AIR-04 | バグ | 高 | M | 手動モード。MAN L/R の片側でも系統全体が手動になる。弁は 1 フレームに 0.005 動く（フレームレート依存）。客室昇降率を弁位置の絶対値だけで決め、目標は機体高度なので、CLOSE で客室を下げられない。片側だけ手動にして他方を自動に残す動きも無い | FCOM p.574, 608–609; ATA21 p.446–448 | :811-839 |
| AIR-05 | 挙動の誤り | 高 | S | CABIN ALT AUTO を MAN スイッチ片側 ON で出している。FCOM では、両 CPC 故障か、両方 MAN のとき | FCOM p.619; ATA21 p.454 | :947-953 |
| AIR-06 | 挙動の誤り | 中 | S | 客室高度リミッタが 11,000 ft 超で常に働き（MAN でも）、昇降率 2,000 fpm を書く。実機は自動のときだけ、ICU が 11,000±500 ft で両弁を閉じ、750 ft 下で解除する。MAN は迂回 | FCOM p.574, 608; ATA21 p.406, 442 | :854-859 |
| AIR-07 | 欠落 | 中 | M | CPC A/B が無い。NORM/A/B、便ごとの交代（着陸で切替、電源投入で A）、引継ぎ条件（2,000 fpm・9.07 psi・電源断 2 s）、電源（DC 1/2）。AUTO SELECT ノブは動くだけ | FCOM p.574, 607; ATA21 p.426, 432, 437 | :241-250 |
| AIR-08 | 欠落 | 中 | M | 正圧リリーフ（9.25/9.75 psid。FCOM 限界 9.4）が開いたときの pack 2 停止と PRESS RELIEF、負圧リリーフ（0.2〜0.4 psi で開き始め、1 psi で全開）が無い。X-Plane の `_max_press_diff` 9.4（両 acf 同じ）任せ | FCOM p.79, 609, 620; ATA21 p.462–472 | なし |
| AIR-09 | 挙動の誤り | 中 | S | 外流弁計を客室 V/S から作っている（-2,000 fpm→+1、+2,000 fpm→-1）。実機の弁位置（地上で全開、65 kt で少し閉、巡航で調節）ではない。地上でも中央を指す | ATA21 p.412, 420, p.429・433 図 | :846-847, :863-864 |
| AIR-10 | 欠落 | 中 | M | 温度制御が全く無い。PASS / FLT DECK / CARGO の各ノブは初期値 0.5 を書くだけ。ゾーンの target/actual、トリム空気（master PRSOV とゾーン弁）、ALTN・MAN、backup（PASS TEMP 値 → 最後の値 → 75°F）、comfort bias、TRIM AIR OFF・TEMP ZONE が無い。TRIM AIR スイッチは zone SYS FAULT 灯を点けるだけ | FCOM p.554–556, 591–592, 620–621; ATA21 p.338, 346–370, 384 | :1108-1110; `B747.90.xt.lighting.lua:1333` |
| AIR-11 | 欠落 | 中 | M | パック流量のスケジュール（地上・上昇・降下 high、cruise clamp で normal、3 基未満やファン故障で high、パック間 15 s・ファン間 5 s）と再循環ファンの論理（ATA21 p.139・141 の表）が無い。HI FLOW は memo だけ。UPR/LWR RECIRC は効果なし | FCOM p.558, 588–589; ATA21 p.23, 86, 138–141, 382, 386–389 | :1064-1070 |
| AIR-12 | 欠落 | 中 | M | パック保護（185°F・425°F・順序異常でラッチ停止）、PACK RST、PACK SYS FAULT 灯（常に 0）、PACK n と PACK CONTROL、PTC A/B の自動切替が無い | FCOM p.560, 588–589, 620; ATA21 p.94, 102 | `B747.90.xt.lighting.lua:1335` |
| AIR-13 | 欠落 | 中 | M | 機器冷却。`equip_cooling/state` を書くだけで、誰も読んでいない。NORM/STBY/OVRD の弁構成、45°F の判定、各翼 1 基運転で flight 構成、EQUIP COOLING（地上で OVRD・ground exhaust 不一致・低流量・過熱・煙）、貨物室火災 ARM で自動 OVRD が無い | FCOM p.557–558, 603–605, 619; ATA21 p.504–598 | :793-799 |
| AIR-14 | 欠落 | 低 | S | 後方貨物室暖房。スイッチに効果が無く、TEMP 灯（annun [70]）は常に 0。TEMP CARGO HEAT も貨物室温度も無い | FCOM p.557, 602, 620; ATA21 p.234–252 | `B747.90.xt.lighting.lua:1334` |
| AIR-15 | 欠落 | 高 | M | ECS synoptic の上半分が無い。ゾーン温度・MASTER・FWD/AFT・外流弁計の枠は背景にあるが、数字と針の計器が無い。HI FLOW・EXT AIR・MAN/AUTO も無い（画像はある）。パックの OFF/A/B は選択器の位置で出しており、実機の「弁閉＝OFF／使用中の PTC」と違う。A は「1 < pos < 2」の条件なので、NORM と A で出ない可能性がある。直すにはカスタム acf のパネル追加（承認が要る） | FCOM p.576–578; ATA21 p.28–29, 100, 420 | `747-400.acf:135167-136142`（A の条件は 135698 付近） |
| AIR-16 | バグ | 中 | S | EEC の packs 補正が、パック数を選択器の値の合計で数えている（A＝2、B＝3 で多く数える）。選択器ではなく、運転中のパック数を使うべき | FCOM p.560（選択器の位置） | `B747.42.xt.EEC.PW.lua:547`、`GE.lua:501`、`RR.lua:732` |
| AIR-17 | 欠落 | 中 | S | 貨物室火災 ARM 時の空調の組替え（pack 3 停止・1/2 high・再循環ファン全停止・機器冷却 OVRD・AFT なら後方暖房停止）が無い。air は `button_switch/position[84]`・`[85]` を読んでいない | FCOM p.908, 589; ATA21 p.94, 134, 141, 240–242, 580 | なし |
| AIR-18 | 挙動の誤り | 低 | S | ECS data block。自動表示の条件に、負の ΔP（−0.5 以下）と LANDING ALT が無い。両 CPC 故障・両 MAN のとき LDG ALT を消せない（パネルに条件が無い）。右ダクト圧の白表示の条件が左ダクト圧になっている（acf。ATA 36 と共通） | FCOM p.585–586; ATA21 p.451–452 | :892-922; `747-400.acf:124780` |
| AIR-19 | バグ | 低 | S | 初期状態。ER 開始で EQUIP COOLING が STBY（0）のまま（CD で 0 を書き、ER で NORM にしない）。RECIRC が ON にならない。manipulators の ER で TRIM AIR の位置を [83] に書いている。`sim/cockpit2/Cooling/Packs_EXT` は A/B を数えず、誰も読まない | FCOM p.107–108 (NP.21.13–14) | :1121-1143; `B747.01.xt.manipulators.lua:2176-2178`; `Avionics.lua:43-49` |
| AIR-20 | 挙動の誤り | 中 | M | X-Plane 内蔵の与圧に依存。override を使わず、actuator の書込みがどう扱われるか分からない。減圧故障（`rel_depres_*`）や X-Plane のパック・抽気モデルとの関係も整理されていない。ATA 36 と方針を決める必要がある | 6 章の acf 値; X-Plane DataRefs.txt | :122-138, :806-866 |
| AIR-21 | 欠落 | 低 | S | 電源との関係。与圧と温度制御は電源と無関係に動く（機器冷却だけが bus_volts[0] を見る）。実機は CPC A＝DC 1、B＝DC 2、手動＝battery と APU hot battery、PTC A＝bus 3、B＝bus 4 | ATA21 p.84, 437, 449, 611 | :794, :806-866 |
| AIR-22 | 欠落 | 低 | M | ECS の status メッセージ（CABIN ALT AUTO A/B、PACK CONTROL A/B、RECIRC FAN、OUTFLOW VLV、PRESS RELIEF、EE CLNG …）が無い。STATUS ページにメッセージ表の仕組みが無い（ATA 31 と共通） | ATA21 p.92–598 の各 status 項 | なし |

### 防氷・防雨（ATA 30）（ICE、13 件：高 0・中 8・低 5）

詳細と出典の全文：[notes/ATA-30.md](notes/ATA-30.md)

| ID | 種別 | 重要度 | 規模 | 内容 | 根拠 | 該当コード |
|---|---|---|---|---|---|---|
| ICE-01 | バグ | 中 | S | 主翼防氷を X-Plane へ渡すのに左右共通のコマンド（`sim/ice/wing_heat_on/off`）を使っているため、左右の弁が食い違う（例: 片側のダクト圧が 12 psi 以下）と毎フレーム ON と OFF が入れ替わる。主 EICAS の WAI がちらつき、X-Plane の除氷も半分しか効かない | FCOM p.633、X-Plane 12 Commands.txt（wing_heat0/1 がある） | ICE:168-169、ICE:432-445 |
| ICE-02 | 挙動の誤り | 中 | S | WAI 弁の開条件に「ダクト圧 >12 psi」が入っている（実機はモーター弁で、空中かつスイッチ ON で開く）。弁はほぼ瞬時に動く（実機は 3 s 未満）。ダクト圧が低い側は VALVE 灯が点く。地上でスイッチ ON でも VALVE 灯が点く（指令基準なら点かないと推定） | FCOM p.625-626、LH36 p.120-126、ATA30_32_35_36 p.176-178 | ICE:398-427、LIT:1313-1323 |
| ICE-03 | バグ | 中 | S | >ANTI-ICE が出ない。条件の真偽にかかわらず両方の分岐で 0 を書いている。条件も OAT を使い（FCOM は TAT）、`or simDR_wing_heat_on_R` は Lua では 0 でも真になる | FCOM p.635 | ICE:487-503 |
| ICE-04 | 欠落 | 中 | S | NAI VALVE 1–4 と WAI VALVE LEFT/RIGHT が未実装（表だけある）。エンジン運転中の条件と遅延（3.5 s、5 s）も必要 | FCOM p.635、ATA30_32_35_36 p.184・p.206 | WRN:428-431、WRN:482-483 |
| ICE-05 | 挙動の誤り | 中 | M | NAI 弁が「スイッチ ON、エンジン抽気 >12 psi、始動弁閉」だけで開く。PRV 側の条件（過熱ラッチ、ENGINE BLEED off 時の HPSOV failed open、始動弁閉後 15 s、火災スイッチ）、NAI ダクトの過熱ラッチ、逆推力中の閉（E&M）、28V DC が無い。抽気側（PNEU-02）と一緒に直す | FCOM p.576・p.612・p.614・p.625、LH36 p.48、ATA30_32_35_36 p.198・p.202 | ICE:302-348 |
| ICE-06 | 欠落 | 中 | S | プローブ加熱: AOA と TAT のヒーターを X-Plane に出していない。ピトー静圧の加熱を「どれかのエンジン抽気 >12 psi」で代用（実機はエンジン運転、TAT は飛行中、地上は減電力）。HEAT L/R AOA は着氷量の比率 `aoa_ice`（0–1）を 6 と比べているので出ない。HEAT L/R TAT、HEAT P/S L/R AUX は未実装 | FCOM p.634-635、ATA30_32_35_36 p.216-234 | ICE:84-94、ICE:284-299、ICE:505-535 |
| ICE-07 | 欠落 | 中 | S | 窓加熱: HEAT WINDOW L/R が未実装。INOP 灯は「スイッチ ON かつ X-Plane の窓加熱故障」のときだけ（FCOM は電力が切れても点灯）。左右を X-Plane の 1 系統（`sim/ice/window_heat_on/off`）にまとめている。off 10 s→ON のリセット、電源の判定が無い | FCOM p.627-628・p.633・p.635、ATA30_32_35_36 p.246-250 | ICE:453-469、LIT:1325-1326 |
| ICE-08 | 欠落 | 低 | S | 氷検知: >NO ICING、>ICE DETECTORS が未実装。>ICING は X-Plane の ice アナンシエーターをそのまま使い、空中だけ・保持時間の扱いが無い | FCOM p.631・p.635、ATA30_32_35_36 p.161-164、LH36 p.106-108 | ICE:479-485 |
| ICE-09 | 挙動の誤り | 低 | S | ワイパーの速さ: LO→X-Plane の 1（25%）、HI→2（50%）。実機は LO 160・HI 250 回/分。28V DC の電源判定も無い | ATA30_32_35_36 p.264・p.272、X-Plane 12 DataRefs.txt | ICE:185-193 |
| ICE-10 | 欠落 | 低 | S | ウォッシャーは押しても効果なし。防雨剤（109）と WSHLD AIR は操作子も無い | FCOM p.627-629・p.633-634 | MAN:1211-1219 |
| ICE-11 | 挙動の誤り | 中 | M | 防氷の推力補正: PW はナセル防氷の補正がコメントアウトされ、PI の EPR 補正（engine anti-ice、engine & wing anti-ice）が無い。GE は Go-around の NAI 補正（PI.20.32）だけを離陸・上昇・巡航に使い、主翼防氷の補正が無い（PI.20.31 には高度別の上昇補正がある）。FCOM は EEC が NAI・WAI の抽気分を補うと書く | FCOM p.876 (7.20.6)、p.261-262 (PI.10.35-36)、p.358-360 (PI.20.30-32) | EEC/B747.42.xt.EEC.PW.lua:557-562、EEC/B747.42.xt.EEC.GE.lua:511-516、EEC/B747.42.xt.EEC.tbls.lua:103-106 |
| ICE-12 | バグ | 低 | S | init の型が `"array[4)"`・`"array[2)"`（括弧の誤り）。Lua 側は末尾 1 文字を捨てて数を読むので動くが、XTLua 本体側の解釈は未確認 | — | ICEI:65-66、EEC/B747.42.xt.EEC.lua:260 |
| ICE-13 | 欠落 | 低 | S | 防氷・防雨の電源依存（WAI は AC bus 2 + DC bus 2、氷検知は AC bus 1/3、窓は 115V AC + 28V DC、プローブは 115V AC、ワイパーは 28V DC）を見ていない | LH36 p.106・p.112、ATA30_32_35_36 p.216・p.248・p.272 | ICE:302-469 |

### 酸素（ATA 35）（OXY、5 件：高 0・中 3・低 2）

詳細と出典の全文：[notes/ATA-35.md](notes/ATA-35.md)

| ID | 種別 | 重要度 | 規模 | 内容 | 根拠 | 該当コード |
|---|---|---|---|---|---|---|
| OXY-01 | 欠落 | 中 | M | 乗客酸素が無い。客室高度での自動作動、手動 ON/RESET（12,000 ft 条件）、PASS OXYGEN ON、治療用の同時作動、NO SMOKING / FASTEN SEAT BELTS の強制点灯が全て無い（サインの判定には TODO だけ） | FCOM p.437・p.456・p.502・p.513・p.547、ATA30_32_35_36 p.346・p.368 | LIT:1596-1645、WRN:442 |
| OXY-02 | 欠落 | 中 | S | 乗員・乗客の酸素圧と >CREW OXY LOW（500 psi 以下）が無い | FCOM p.455・p.545、ATA30_32_35_36 p.338-340・p.370-374 | WRN:239 |
| OXY-03 | 欠落 | 中 | S | STATUS ページの OXY PR が表示できない。acf の LED は DATAREF が空（`[0]`）で 3 桁。準備の手順（酸素圧の確認と試験）が再現できない。直すにはカスタム acf の変更（要承認） | FCOM p.455、p.110 (NP.21.16) | ACF:129850-129886 |
| OXY-04 | 欠落 | 低 | S | PASS OXYGEN・THERAPEUTIC OXYGEN スイッチと乗員マスクの操作手段（3D 操作子もコマンドも）が無い。THERAP OXYGEN ON のメモも無い | FCOM p.456-460・p.547 | WRN:529 |
| OXY-05 | 欠落 | 低 | S | X-Plane の乗員酸素・低酸素のモデルとの関係を扱っていない（減圧時に利用者が酸素を使う手段が無い。X-Plane 側の効果は要確認） | X-Plane 12 DataRefs.txt | なし |

### 火災防護（ATA 26）（FIRE、20 件：高 4・中 11・低 5）

詳細と出典の全文：[notes/ATA-26.md](notes/ATA-26.md)

| ID | 種別 | 重要度 | 規模 | 内容 | 根拠 | 該当コード |
|---|---|---|---|---|---|---|
| FIRE-01 | 欠落 | 高 | M | 検知モデルが無い。エンジンは X-Plane の注釈 `engine_fires` の素通し、APU は故障 enum の素通し。loop A/B、AND と単ループへの組替え、故障の判定、>DET FIRE/OHT n・>DET FIRE APU（advisory 58–62）、status（LP A/B、FIRE/OVHT SYS）、検知の電源依存、故障を起こす入力（ループ故障など）がどれも無い | FCOM p.914、p.919、p.921；ATA26_28 p.20、p.25–46、p.93–102 | FIR:52-53、319-331、483-514；WRN:244-248 |
| FIRE-02 | 欠落 | 中 | S | エンジン過熱が無い。OVHT ENG 1–4 NAC（caution・beeper）は CAS 表にも無い。過熱の入力（X-Plane に無い）も無い | FCOM p.914、p.922；ATA26_28 p.20、p.25、p.34 | なし（WRN:107-183 の表に無い） |
| FIRE-03 | 欠落 | 高 | M | APU 火災：FIRE APU（warning 8）を誰も立てない（master WARNING もベルも出ない）。APU 消火スイッチ（コマンド・dataref・3D 操作）、自動停止、地上の自動放出（95% 未満で 10 秒）、APU ボトル、APU BTL DISCH（常に 0）、>BOTTLE LOW APU、M869（ホーン・操作）、試験中の停止・放出の抑止が無い | FCOM p.897、p.906–907、p.910–911、p.913–914、p.916；ATA26_28 p.93–94、p.104–110、p.124–125 | FIR:53、327-331；LIT:1431；WRN:81、230；`747-400_cockpit.obj`（manipulator 無し）；`B747.03.xt.electrical.lua:650-675`（火災で停止しない） |
| FIRE-04 | バグ | 中 | S | APU の火災判定が failure_enum をそのまま使う。故障を予約しただけ（1–5）で APU の赤灯が点く（作動中は 6）。警報モジュールのベル判定 `> 0` も同じ誤り（その出力 `warning_bell` は今は未使用、FIRE-06） | X-Plane failure_enum（作動中＝6） | FIR:330（灯）；WRN:631、824 |
| FIRE-05 | 欠落 | 高 | M | 下部貨物室：ARM・DISCH のスイッチ位置を誰も読まない。FWD/AFT・DISCH 灯は常に 0。煙検知（zone 1–4）、FIRE CARGO FWD/AFT（warning 10・9）、ボトル A–D、即時＋30 分／接地の 2 段放出と lock-in、DISCH 灯、>CGO BTL DISCH・>CARGO DET AIR が無い。ARM による空調の組替えも無い（AIR-17） | FCOM p.907–908、p.914、p.917、p.921；ATA26_28 p.140–198 | MAN:978-994（`button_switch_position[84]`–`[86]` の読み手なし）；LIT:1128-1130；WRN:82-83、235、237 |
| FIRE-06 | 挙動の誤り | 高 | M | 火災ベル：SND が X-Plane の `engine_fire` 注釈と試験ボタンに直結。master WARNING のリセットで止まらない、APU・貨物・車輪格納部では鳴らない、断続（2 s/3 s、570 は 1 s/10 s）を制御できない。警報モジュールの `warning_bell` は計算しているが誰も使わない。直すには .snd の付け替え（承認）と警報側の aural 選択の作り直しが要る | FCOM p.913、p.1550；ATA31 p.159、p.173 | SND:5825-5851；WRN:817-832 |
| FIRE-07 | 欠落 | 中 | S | 離陸中の火災警報の抑止（V1 → 400 ft RA か 25 秒、速度が無ければピッチ 5°、抑止明けのベル）が無い。警報モジュール（ATA 31）と共同 | FCOM p.1595、p.1589；ATA26_28 p.8、p.12；ATA31 p.173 | WRN:800-832 |
| FIRE-08 | 挙動の誤り | 中 | S | FIRE/OVHT TEST：消火スイッチと APU の赤灯、master WARNING、ベル（SND）だけ。>TEST IN PROG → 約 5 秒で >FIRE TEST PASS/FAIL、離したときの消去と中断、貨物 FWD/AFT 灯、FUEL CONTROL の赤灯（OBJ が読み取り専用の X-Plane 注釈に付いている）、地上の APU ホーン、車輪格納部・ダクトリークの試験、試験中の解錠が無い | FCOM p.910、p.919–920、p.923、p.187；ATA26_28 p.30、p.42、p.94、p.272、p.284 | FIR:98-104、321-331；WRN:817-820；LIT:1128-1129；`Cockpit_TQ.obj:31477-31495` |
| FIRE-09 | 挙動の誤り | 中 | S | エンジン消火スイッチのロックが無く、いつでも引ける（TODO のまま）。火災警報・CUTOFF・試験・override での解錠、hot battery bus の要否が無い。override は 3D にも無い | FCOM p.905–906、p.916；ATA26_28 p.48、p.50–51 | FIR:304-311、110-148 |
| FIRE-10 | 挙動の誤り | 中 | S | 消火の効果がボトルと無関係。回している間は `fire_extinguisher_on` を常に 1 にするので、空のボトル（隣のエンジンで使用済みの共用ボトルを含む）でも消える。squib の電源も見ない。ボトル圧は 40 psi/s で減り、BTL DISCH（225 psi）まで約 9 秒かかる | FCOM p.905、p.915–916；ATA26_28 p.64–76、p.170 | FIR:354-399、409-473；LIT:1427-1430 |
| FIRE-11 | 欠落 | 中 | S | ボトル低圧の EICAS：>BTL LO L/R ENG A/B が表に無く、代わりに FCOM に無い「>BTL LOW APU A/B」がある。>BOTTLE LOW APU を誰も立てない | FCOM p.921；ATA26_28 p.78、p.130 | WRN:230、233-234 |
| FIRE-12 | バグ | 中 | S | >ENG n SHUTDOWN の条件がスイッチの回転（`pos_disch > 0.95`、エンジン 1 では B 側だけ）で、引いただけでは出ない。空中で引いてエンジンが止まると、代わりに ENG n FAIL（コードでは warning）が出る | FCOM p.902、p.899 | ENG:1411、1430、1448、1465 |
| FIRE-13 | 挙動の誤り | 中 | M | 消火スイッチを引いたときの他系統への作用が不揃い：燃料弁・抽気弁は閉じるが、spar valve（FUEL-18）、油圧 SOV・EDP 減圧・demand pump（HYD-05）、GCR トリップ（ELEC-04 の論理に含める）は無い。各モジュールがアニメーション値を別々の閾値で読む | FCOM p.905、p.1490；ATA26_28 p.50–51；LH24 p.108 | ENG:2051；`B747.55.xt.air.lua:501`；`B747.25.xt.fuel.lua:1327-1328`；油圧・電源は参照なし |
| FIRE-14 | 欠落 | 中 | M | 車輪格納部の火災：FIRE WHEEL WELL（warning 21）を立てるコードも検知も試験も無い。X-Plane に故障が無いので自前の入力が要る | FCOM p.913–915、p.920、p.922；ATA26_28 p.268–274；FCTM p.304 | WRN:94 |
| FIRE-15 | 欠落 | 中 | M | 主翼前縁・ストラットの過熱検知と BLD DUCT LEAK L/C/R（caution 6–8）が無い。FIRE/OVHT TEST での試験も無い（ATA-36 PNEU-03 と共同） | FCOM p.613、p.619、p.910、p.920；ATA26_28 p.278–286 | WRN:114-116 |
| FIRE-16 | 欠落 | 低 | S | 化粧室・クルーレストの煙：検知が無い。SMOKE DR 5 REST（caution 52）を立てない。>SMOKE LAVATORY が caution 53 と advisory 264 の二重（109 は advisory）。570 の >SMOKE CREW REST は表に無い | FCOM p.915、p.922–923、p.589；ATA26_28 p.290–320 | WRN:160-161、450 |
| FIRE-17 | 欠落 | 低 | S | スクイブ試験：灯はある（常に 0、灯試験だけで点く）が、TEST 1・2 のスイッチ（manipulator・コマンド）が無い | FCOM p.187–188、p.920；ATA26_28 p.80–82、p.132–134、p.196–198 | LIT:1400-1409、1870-1879 |
| FIRE-18 | 欠落 | 低 | M | 電源：検知・解錠・放出・灯が電源を見ない（APU battery bus、main hot battery bus、DC bus 1/2、AC bus 2）。FIRE/OVHT SYS が無い。ELEC の作り直し（ELEC-02・ELEC-15）が前提 | FCOM p.820、p.896–897；ATA26_28 p.27、p.39、p.51、p.72、p.124–125、p.185、p.273、p.285 | FIR 全体（電源判定なし） |
| FIRE-19 | 欠落 | 低 | L | 貨物機（405/570）：主デッキの検知・ARM・DEPRESS/DISCH、弁試験、ベルの断続 1 s/10 s が無い。CAS 表には FIRE MAIN DECK などがある。`laminar/B747/freighter` はあるが 3D に操作部が無い | FCOM p.908–909、p.913、p.918、p.920、p.922、p.924；ATA26_28 p.202–264 | WRN:88-91、98-100 |
| FIRE-20 | 挙動の誤り | 低 | S | CAS の更新が 2 秒ごとなので、FIRE メッセージと master WARNING が最大 2 秒遅れ、試験の master WARNING の点灯・消灯も遅れる（ATA 31 と共通） | FCOM p.913（火災中は表示） | WRN:1140-1154 |

### 操縦系統（ATA 27）（FCTL、25 件：高 4・中 9・低 12）

詳細と出典の全文：[notes/ATA-27.md](notes/ATA-27.md)

| ID | 種別 | 重要度 | 規模 | 内容 | 根拠 | 該当コード |
|---|---|---|---|---|---|---|
| FCTL-01 | 欠落 | 高 | L | FCU 論理が無い：TE・LE とも primary だけで secondary（電動）が無い。TE は油圧 > 900 psi を「指令が変わった瞬間」にしか見ず（移動中に油圧を失っても動き続け、priority valve 2000 psi でもない）、不一致 7 s/42 s・1400/1600 psi・非対称 6.2/3.4 %・逸走・moving away の保護が無い。LE は空気圧（ダクト圧）を見ない。FLAPS PRIMARY・FLAPS DRIVE は定義だけで立たない | FCOM p.953、ATA27 p.284・290・292・294・363・381・384 | `B747.19.xt.hydraulics_override.lua:214-227`、`:342-368`、`B747.87.xt.warning.lua:137-138` |
| FCTL-02 | 欠落 | 高 | M | ALTN FLAPS：ARM スイッチは FLAPS CONTROL を出すだけで、選択器（RET/OFF/EXT）は位置を変えるだけ。レバーは不作動にならず、電動駆動・25 制限・LE 格納 interlock も無い。FLAPS CONTROL のもう一つの条件は X-Plane の `rel_flap_act` 故障だが、舵面はプラグインが書くのでその故障でもフラップは動く（`推定`） | FCOM p.935・954・957、ATA27 p.296–302・390 | `B747.45.xt.fltCtrls.lua:218-227`、`:1145-1153`、`B747.01.xt.manipulators.lua:558-560` |
| FCTL-03 | 欠落 | 高 | L | 安定板トリム系統：手動スイッチは X-Plane の `pitch_trim_up/down` を handler の各 phase で `once()` するだけ（速度は X-Plane 任せ＝acf `_elev_trim_time` 25 s で、対気速度に依存しない。実速度は要確認。`simDR_electric_trim` は未定義の global への代入）。電気トリム制限（1.8/11.6、0.8、13.5）が無く 0–15 units 全域。系統 2/3 依存と半速、cutout（ON/AUTO/CUTOUT）と自動遮断、ALTN トリム（コマンドも無い）、column cutout、手動トリムでの AP 解除（1 台）/無効（複数）が無い。>STAB TRIM 2・3、STAB TRIM UNSCHD は立たない。AP の autotrim は `elevator_trim` を直接書く | FCOM p.928–929・944–946・958、ATA27 p.450–458・476・483・488・490・520 | `B747.45.xt.fltCtrls.lua:233-289`、`:486-487`、`B747.19.xt.hydraulics_override.lua:925-957`、`B747.19.xt.hydraulicsmodel.lua:596` |
| FCTL-04 | バグ | 高 | S | ラダートリムが舵面に入らない見込み：ラダー指令は `total_heading_ratio`×32×ratio＋YD だけで `rudder_trim` を足していない（エルロンは `aileron_trim` を足している）。X-Plane の `total_heading_ratio` がトリムを含まないことを要確認 | FCOM p.949、ATA27 p.612–614 | `B747.19.xt.hydraulicsmodel.lua:566-573`、`:602` |
| FCTL-05 | 挙動の誤り | 中 | S | lockout：機長 IAS 232–238 kt の直線補間（ヒステリシスの保持でない）。Mach（0.51/0.53）、LE group A 展開での unlock、SRM/ADC/FCU 故障時の扱い（空中 default unlock）が無い。フラップを出したまま 238 kt 超で外側がロックされ、高高度の低 IAS で unlock する。AILERON LOCKOUT は立たない | FCOM p.947・957、ATA27 p.106–110、FCOM p.53 | `B747.19.xt.hydraulics_override.lua:1142-1143`、`B747.19.xt.hydraulicsmodel.lua:607-611` |
| FCTL-06 | 挙動の誤り | 中 | S | RRC：機長 IAS 150→450 kt で 1.0→0.156 の直線。実機の曲線より中速で舵角が大きい（250 kt で約 23° 対 約 15°、`推定`）。上下共通の 1 値、ADC 喪失時の 329/209 kt 固定・autoland 0 kt・故障位置保持が無い。YD 入力にも ratio を掛けている（実機は下流で加算、`推定`）。RUD RATIO SNGL/DUAL は立たない | FCOM p.949・957、ATA27 p.634–648・656 | `B747.19.xt.hydraulics_override.lua:1140`、`B747.19.xt.hydraulicsmodel.lua:566-570` |
| FCTL-07 | 挙動の誤り | 中 | M | 自動スピードブレーキ：着陸展開は X-Plane 本体（ARM＝ratio -0.5）に任せ、レバーを追従させるだけ。TL1/TL3 アイドル条件、地上判定（系統 1/4 > 1600 psi と脚 tilt）、DC bus 1 依存が無い。RTO は「どれかのエンジンが reverse」でレバー UP（実機はリバースレバー 2 か 4 と TL1/TL3 アイドル）。ゴーアラウンドの格納（TL1 か TL3）はコードに無い（X-Plane 任せか要確認）。SPEEDBRAKE AUTO は立たない | FCOM p.933・951–952、ATA27 p.172–184 | `B747.45.xt.fltCtrls.lua:654-708`、`:852-872`、`B747.45.fltCtrls.lua:97-155`（init） |
| FCTL-08 | 挙動の誤り | 中 | S | >SPEEDBRAKES EXT：`num_thrust_levers_open` が全レバー共通の `throttle_jet_rev_ratio_all` から作られ最大 1、演算子の結合で推力条件がフラップ条件にしか掛からない。「推力レバー 2 本以上」が欠け、着陸フラップ条件は RA > 15 ft でなく `onground` で判定。さらに空中の「スピードブレーキ＋推力レバー前方」を CONFIG SPOILERS（赤の warning）で出している | FCOM p.958、ATA27 p.740 | `B747.45.xt.fltCtrls.lua:1155-1168`、`:957-965`、`:1102-1111` |
| FCTL-09 | 挙動の誤り | 中 | S | 横操縦の対応：エルロンはホイールに比例（実機は約 45° で全舵角の曲線）、スポイラーは 0 から比例（実機は 8–14° の不感帯）。スピードブレーキ展開中に下げ側の翼のスポイラーが横操縦で下がらない（上げ側の対応しか無い） | FCOM p.947、ATA27 p.59 図・p.88・150・206 | `B747.19.xt.hydraulicsmodel.lua:600-629` |
| FCTL-10 | 挙動の誤り | 中 | M | greenband：FMC trim ±2.25 units の帯（CONFIG STAB）と、FMC trim に応じて平行移動する 1 本の帯。実機は固定の 3 帯（3.35–8.15／3.35–10.15／1.35–8.15）を MAWEA が選び、V1 で消灯。前脚オレオ圧スイッチとの比較（>STAB GREENBAND）が無い。OFF フラグは X-Plane のトリム故障で、指示器の電源でない | FCOM p.944・958、ATA27 p.502・508–514・521 | `B747.45.xt.fltCtrls.lua:912-921`、`:1113-1143` |
| FCTL-11 | 挙動の誤り | 低 | S | normal 表示：テープにレバー由来の 0–0.15 が足され、レバーを 1 にした瞬間に「1」を示す（group A の移動中・展開を反映しない）。テープは 4 枚の最大値（最も速い面。実機は最も遅い TE 群）。expanded への切替条件は TE の不一致だけ | FCOM p.936・954、ATA27 p.318、p.399 図 | `B747.19.xt.hydraulicsmodel.lua:655-679`、`B747.45.xt.fltCtrls.lua:818`、`:880-906` |
| FCTL-12 | 欠落 | 中 | M | expanded/alternate 表示：パネルに LE 6 箱、amber、amber X、alternate の index mark、expanded での緑が無い（画像も無い）。カスタム acf のパネル変更が必要（承認事項） | FCOM p.937–938、ATA27 p.320–322・398–400 | `747-400.acf:123890-124290`（パネル） |
| FCTL-13 | 挙動の誤り | 低 | S | LE の順序：group A の格納条件が IB TE（実機は OB TE）。リバースでの自動格納が「レバー > 0.5 とどれか 1 基の reverse」（実機は地上・空気圧モードでエンジン 1&4 か 2&3）、再展開がスピードブレーキを下げるまで遅れる | FCOM p.954–955、ATA27 p.381–382 | `B747.19.xt.hydraulics_override.lua:342-368` |
| FCTL-14 | 挙動の誤り | 低 | S | load relief：レバー 30 で 20→25 に戻る速度が 203 kt（実機 195 kt）。モード条件（油圧モードのときだけ）が無い。FLAP LOAD RELIEF（STATUS）が無い | FCOM p.954、ATA27 p.288、p.289 図 | `B747.45.xt.fltCtrls.lua:826-843` |
| FCTL-15 | 欠落 | 中 | S | YD の INOP 灯と >YAW DAMPER：条件はスイッチ・IRS 1 台以上 NAV・バッテリーだけ。油圧（上 3、下 2）、FCE 電源（上は左 PSM＝standby bus、下は PSM 1R＝AC bus 1）、ADC 有効、アクチュエータ故障が無い。制御則は ATA 22 | FCOM p.931・949–950・958、ATA27 p.22–24・44 | `B747.45.xt.fltCtrls.lua:714-744`、`:1170-1184`、`B747.90.xt.lighting.lua:1328-1330` |
| FCTL-16 | 欠落 | 低 | M | speed stability trim（SRM、Vc ≤ 220 kt、空中 20 s 後、半速）が無い。STAB SPEED TRIM も無い | FCOM p.945、ATA27 p.486 | なし |
| FCTL-17 | 挙動の誤り | 低 | S | エルロントリム：`aileron_trim` をロール入力にそのまま加算。権限は acf `_roll_acft_lf/rt_trim_rat` 0.05（全舵角の 5 % と `推定`）で、実機の 6 units＝ホイール 47° より大幅に小さい見込み。速度は acf `_ailn_trim_time`（カスタム 12 s／純正 10 s）。要確認 | FCOM p.947–948、ATA27 p.76 | `B747.19.xt.hydraulicsmodel.lua:602`、`B747.45.xt.fltCtrls.lua:481-482` |
| FCTL-18 | 挙動の誤り | 低 | S | エレベーター舵角が 22° 上・17° 下（acf も同じ）。E&M は 25°/15°。外側の中立 2° 下げも無い | ATA27 p.548・552 | `B747.19.xt.hydraulicsmodel.lua:580-595`、`B747.19.xt.hydraulics_override.lua:123-126` |
| FCTL-19 | 挙動の誤り | 低 | S | 舵面位置のスポイラー：`outer_spoilers` が 1–5／8–12 の平均。実機は左＝スポイラー 4、右＝スポイラー 12（右には空中のスピードブレーキが出ない） | FCOM p.939・951 | `B747.19.xt.hydraulics_override.lua:149-159` |
| FCTL-20 | 欠落 | 低 | M | FLT CONTROL HYD POWER：スイッチ・弁・舵面の遮断が無く、VALVE CLOSED 灯は常に 0、>FLT CONT VLVS は立たない。HYD-22 と同じ項目（実装は 1 か所） | FCOM p.940・957、ATA27 p.10–14 | `B747.90.xt.lighting.lua:1381-1389`、`B747.87.xt.warning.lua:329` |
| FCTL-21 | 欠落 | 低 | M | 故障で出るメッセージと STATUS：AILERON LOCKOUT、RUD RATIO、SPEEDBRAKE AUTO などは定義だけ。§3.3 末尾の STATUS メッセージ（ELEVATOR FEEL を含む）は無い（STATUS ページ自体が ATA 31 の課題）。この FCOM に無い `>LE FLAPS DIS` が定義されている | FCOM p.957–958、ATA27 §3.3 の図 | `B747.87.xt.warning.lua:189`、`:427`、`:447-448`、`:458-461` |
| FCTL-22 | 挙動の誤り | 低 | S | ACF_DIFF §3.4・§3.5：舵面系の値（`_ailnN_v1/_v2`、`_ailn1_rat2`、`_def_time`、`_max_full_def_KIAS`、`_hyd0123`）は override で迂回されコードも読まない（`推定`）。トリム時間は効く。`_speedbrake_ext_time` と `_sbrk1_*` は X-Plane の speedbrake 面、`_flap_extend_protect` はレバーに効く可能性。要確認、不要なら純正値に戻すか 0 | ACF_DIFF §3.4–3.5 | `B747.19.xt.hydraulics_override.lua:1119` |
| FCTL-23 | バグ | 低 | S | フラップのスナップ用タイマーの停止条件が逆（予定されていないときに stop）。`B747_flap_move_to_slot` のコメントの detent 名がずれている | — | `B747.45.xt.fltCtrls.lua:804-809`、`:747-766` |
| FCTL-24 | 挙動の誤り | 低 | S | スポイラー 6・7：プラグインは X-Plane の speedbrake 面を書かず、空力は X-Plane が `speedbrake_ratio` から比例で出す見込み（実機は 0/20/45 の 3 位置、系統 4 依存）。3D・表示（step）と空力（比例）が食い違う。地上で 5・8 が 45° まで出るかは controlObject の切り詰め次第（要確認） | ATA27 p.165 図・p.188–190 | `B747.19.xt.hydraulicsmodel.lua:682-701`、`B747.45.fltCtrls.lua:113`、`:144`（init、レバー→`speedbrake_ratio`） |
| FCTL-25 | 欠落 | 中 | M | 電源依存が無い：FCE（PSM）、input actuator（AC 1）、TE/LE の電動・alternate モーター（AC 1/3/4）、auto speedbrake（DC 1）、RRC（AC 2/3）、lever lock、trim 表示。standby だけでの amber X や「フラップ 1 で FLAPS DRIVE」が出ない。ATA 24 の作り直しが前提 | §2.3、FCOM p.955、FCTM p.283 | なし |

### 脚・ブレーキ・ステアリング（ATA 32）（GEAR、23 件：高 7・中 7・低 9）

詳細と出典の全文：[notes/ATA-32.md](notes/ATA-32.md)

| ID | 種別 | 重要度 | 規模 | 内容 | 根拠 | 該当コード |
|---|---|---|---|---|---|---|
| GEAR-01 | 欠落 | 高 | L | 空地判定（PSEU）が無い。全モジュールが `onground_any`（どれか 1 輪接地）を直接読む。実機は主脚トラック傾きによる pri/alt の air/ground（片側接地では air のまま、両側で ground）と、別信号の前脚圧縮。着地で 1 輪触れただけで全系統が ground に切り替わる。逆推力だけは前輪を含む全輪接地を要求（実機は主脚の ground relay）。前脚圧縮・ALL GR DN・LG LVR UNLK も無い | ATA29_32 p.296–323・336–338、FCOM p.1511 | §5 の各ファイル（例 `B747.10.xt.gear.lua:79`、`B747.40.xt.engines.lua:752-757`） |
| GEAR-02 | バグ | 高 | S | コードがセレクタを DISARM/OFF に動かしても X-Plane の `auto_brake_level` を書かない：着地後の disarm（ペダル・スラスト・スピードブレーキ・故障）、30 kt 以下の自動 DISARM（GEAR-05）、離陸後の RTO → OFF。表示は DISARM/OFF なのに X-Plane の autobrake が残る（X-Plane が自分で解除するかは要確認）。RTO で離陸すると空中でも X-Plane は RTO のまま | FCOM p.1515–1516 | `B747.10.xt.gear.lua:404-442`、`B747.45.xt.fltCtrls.lua:1195-1197`・`:1352-1361` |
| GEAR-03 | 挙動の誤り | 高 | M | autobrake の中身が X-Plane 任せで 747 と違う。対応付けで AUTOBRAKES 4 が X-Plane の max（0.4 g）になり MAX と同じ（実機 0.233 / 0.342 g）。3 も 0.225 g（実機 0.186）。arm 条件（系統 4、antiskid、IRS、スラスト idle）、normal 系だけ、適用条件（60 kt・3 s のスピンアップ）、セレクタが保持されない条件、AUTOBRAKES advisory の条件（DISARM 位置だけ）が無い | ATA29_32 p.502–531、FCOM p.1515–1516、DataRefs.txt `acf_autofbrk_decels` | `B747.10.xt.gear.lua:369-401`・`:857-920` |
| GEAR-04 | 挙動の誤り | 中 | S | RTO：X-Plane の RTO を入れるのはスロットル軸 > 0.8 か軸 = 0.0 のとき。それまで AUTOBRAKES RTO memo も出ない。85 kt の条件、ペダルによる disable、RTO の AUTOBRAKES advisory は X-Plane 任せか無し | FCOM p.1503・1515、ATA29_32 p.525–531 | `B747.10.xt.gear.lua:233-236`・`:379`・`:396`・`:913-917` |
| GEAR-05 | 挙動の誤り | 中 | S | 地上・IAS 30 kt 以下・逆推力なし・スピードブレーキ < 0.3 で、着陸用レベルが 1 s 後に DISARM になる。実機は停止まで制動を続け、地上（スラスト idle）でも arm できる | FCOM p.1515、ATA29_32 p.519 図 | `B747.45.xt.fltCtrls.lua:1195-1197`・`:1352-1361` |
| GEAR-06 | 挙動の誤り | 高 | M | ステアリング：IAS 20 kt で切替（実機は対地・車輪速）。20 kt 未満は X-Plane 任せで acf の `_steerdeg_*` が効く（カスタムは低速 75°・高速 35°。tiller 軸が無ければペダルでその角度まで、`推定`）。20 kt 以上は総ヨー入力 ×7° で tiller が効かない（向かい風 20 kt なら停止中も）。前脚圧縮の条件が無く空中でも前輪がラダーで動く。レバー DN（脚 DOWN 圧）の条件なし。胴体脚は X-Plane の算法（acf 15°）で、20° 起動・最大 13°・15/20 kt・IRU 40/50 kt・ground 10 s が無い。系統 1 喪失で前輪が直前の角度で固まる（HYD-12 を含む） | FCOM p.1500・1513、ATA29_32 p.570・604・622–623 | `B747.19.xt.hydraulics_override.lua:1123-1136` |
| GEAR-07 | 挙動の誤り | 中 | S | ACF_DIFF §3.4：前輪 `_steerdeg_lospeed/hispeed` はカスタム 75/35、純正 70/7（FCOM の tiller 70・ペダル 7 と一致）。胴体脚はどちらも 15（実機 13）。コードは読まないが、`override_wheel_steer` = 0（IAS < 20 kt）の間は X-Plane が使う。`acf_nw_steerdeg1/2` は書き込み可なのでコードで 70/7 にできる。カスタムの `_gear_extend_protect` 1 は実機に無い保護（acf の Vle 270 kt 超で下げられない恐れ、要確認） | FCOM p.1500–1501、ATA29_32 p.604、ACF_DIFF §3.3–3.4 | `B747.19.xt.hydraulics_override.lua:1125-1126`、`747-400_custom.acf`（`_gear/0/_steerdeg_*`） |
| GEAR-08 | 欠落 | 中 | M | レバーロックが効かない。実際に使われる init 側のハンドラはロック変数（常に 0）を見るだけ。xt 側のロック計算は死んだコードで、しかも [1] を 2 回見て左胴体脚を見ず、傾きは翼脚の claw 角だけ。地上でもレバーを UP にできる（実際に上がるかは X-Plane の `_gear_retract_protect` 次第、要確認） | FCOM p.1512、ATA29_32 p.224–225 | `B747.10.gear.lua:98-133`、`B747.10.xt.gear.lua:146-174`・`:528-551` |
| GEAR-09 | 欠落 | 高 | M | 脚の作動が 747 の油圧と無関係（X-Plane のハンドル 1 本と X-Plane の油圧）。前・胴体脚＝系統 1、翼脚＝系統 4 の分離、ドアの順序、OFF での減圧、de-spin が無い。HYD-11 の脚の部分と同じ | FCOM p.1511–1513、ATA29_32 p.242–262 | `B747.10.gear.lua:101-133`、`B747.10.xt.gear.lua:232-248` |
| GEAR-10 | 欠落 | 高 | M | 代替下げが無い。ALTN スイッチはボタン位置 [1]・[2] を反転するだけで、どこからも読まれない。2 系統の自由落下、ドアが開いたまま、展開形表示、GEAR DOOR の抑止、電源（AC 4・AC 1）が無い | FCOM p.1499–1500・1513、ATA29_32 p.268–282 | `B747.01.xt.manipulators.lua:562-568` |
| GEAR-11 | 欠落 | 中 | M | 位置監視のメッセージが無い：GEAR DISAGREE（30 s）、GEAR DOOR（30 s）、GEAR TILT（15 s）は一覧にあるが立てるコードが無い。X-Plane の脚故障（`rel_lagear*`）を出せない。展開形と故障形はパネルに無い（追加はカスタム acf、承認事項） | FCOM p.1505–1506・1522、ATA29_32 p.336–337・660–666 | `B747.87.warning.lua:78-79`・`:298`（定義のみ）、`747-400.acf:123804-123890` |
| GEAR-12 | 欠落 | 高 | M | ブレーキが油圧源で制限されない（HYD-09 と同じ不具合。実装は ATA 32 側）。normal → alternate（2 輪単位 antiskid）→ accumulator（駐機用で止める力なし）の順、autobrake は normal だけ。ブレーキは X-Plane の標準のまま | FCOM p.1514–1516、ATA29_32 p.388–390 | `B747.10.xt.gear.lua:727-734`、`B747.19.xt.hydraulics_override.lua:198-213` |
| GEAR-13 | 挙動の誤り | 中 | M | BTMS：加熱はペダル比とパーキング比×車輪回転だけで、X-Plane の autobrake・RTO の制動は入らない見込み（`tire_part_brake` を使っていない、要確認）。重量・速度²によらず、冷却は一律 1.8 °C/s。表示は floor(T/100)（コメントは 482 °C = 5、864 °C = 9 なのに）で、482–499 °C では BRAKE TEMP が出るのに数字は 4。10 以上にもなる。パネルの琥珀は 484.1 °C。500 °C 超で 25–45 s 後に脚ごとタイヤ故障。リプレイ中（空中）は外気温に戻しパーキングブレーキを外す | FCOM p.282・320、ATA29_32 p.428 | `B747.10.xt.gear.lua:736-847` |
| GEAR-14 | 欠落 | 低 | S | TIRE PRESSURE が立たない（caution 一覧にも "TIRE PRESSURE" があり、レベルが違う）。圧は乱数 198–210 psi＋地上で 10 psi、故障時 5 psi。±18 %・車軸 25 %・前脚 12 % の判定が無い。パネルの色は 100/240 psi の固定値 | FCOM p.1522、ATA29_32 p.376 | `B747.10.xt.gear.lua:618-697`、`B747.87.warning.lua:105`・`:408` |
| GEAR-15 | 欠落 | 低 | M | ANTISKID、ANTISKID OFF、BRAKE LIMITER が立たない。パーキング弁の不一致（2 s）、空中で弁閉、antiskid 故障による autobrake 抑止が無い。X-Plane の ABS と antiskid の電源・故障が結びついていない | FCOM p.1514–1515・1521、ATA29_32 p.420・480・550 | `B747.87.warning.lua:128-129`・`:163`（定義のみ） |
| GEAR-16 | バグ | 低 | S | パーキングブレーキの副作用：レバーが DN を離れるとパーキングブレーキを外す。リプレイ中（空中）に外す。X-Plane のパーキングブレーキのコマンド（`brakes_toggle_max` など）は wrap されず、レバーと X-Plane がずれる | FCOM p.1516 | `B747.10.gear.lua:129-132`、`B747.10.xt.gear.lua:749-757` |
| GEAR-17 | 挙動の誤り | 中 | S | configuration warning の脚の部分：CONFIG GEAR は「いずれかのレバーが閉」を全体のスロットル比で見る、空中の条件なし、ラッチなし、GND PROX GEAR OVRD（ボタン [5]、どこからも読まれない）による解除なし、`deploy_ratio` で判定。CONFIG GEAR CTR と PARK BRK はエンジン 2 と 3 の両方を要求（FCOM は 2 か 3）。CTR はロックスイッチでなく操向角 > 0.5° | FCOM p.1557–1558・1603 | `B747.45.xt.fltCtrls.lua:1018-1048`・`:1050-1090` |
| GEAR-18 | 欠落 | 低 | S | GEAR synoptic のパネル：ドアの箱が脚の位置（`deploy_ratio`）で、脚が下りていると「開」。タイヤ圧の LED 3 か所の定義誤り（§6.5）。どちらもパネルの変更（カスタム acf、承認事項）が要る | FCOM p.1508、ATA29_32 p.668–670 | `747-400.acf:137644-137688`・`:138345`・`:138397`・`:138798` |
| GEAR-19 | 欠落 | 低 | S | X-Plane のコマンドが wrap されていない：`brakes_toggle_auto`・`brakes_dn_auto`・`brakes_up_auto`（X-Plane の autobrake だけ変わりセレクタと食い違う）、`landing_gear_emer_on`、`brakes_toggle_max/regular` | — | `B747.10.xt.gear.lua:337-340`（wrap はこの 4 つだけ） |
| GEAR-20 | バグ | 低 | S | autobrake の誤 disarm：スロットル（全体比と軸の大きい方）が少しでも増えれば disarm（軸のノイズ、逆推力収納で起こりうる）。ブレーキ故障の判定 `> 0` は「故障を予約しただけ」でも成立 | FCOM p.1515 | `B747.10.xt.gear.lua:421-434` |
| GEAR-21 | バグ | 低 | S | wing sweep 軸が一度でも動くと `override_toe_brakes` を 1 にし、以後戻さない（1 本のブレーキ軸を wing sweep に割り当てる人向けの工夫）。他の利用者ではペダル軸が効かなくなる恐れ（`推定`） | — | `B747.10.xt.gear.lua:727-734` |
| GEAR-22 | 欠落 | 低 | M | AIR/GND SYSTEM、>BODY GEAR STRG の advisory と、脚関係の status（GEAR MONITOR、A/G DISAGREE、BRAKE TEMP SYS、PARK BRK VALVE、BODY GR STRG SYS、PEDAL STEERING、TIRE PRESS SYS）が無い。STATUS 画面自体が未実装（ATA 31 と共通） | FCOM p.1521、ATA29_32 p.338・626–633 | `B747.87.warning.lua:123`・`:161`（定義のみ） |
| GEAR-23 | バグ | 低 | S | 空中で飛行を始めると、X-Plane が脚を下ろして置いた場合（進入開始など）でもレバーを UP へ動かして脚を上げる | — | `B747.10.xt.gear.lua:1003` |

### 乗員への警報（EICAS メッセージ、警報音、形態・失速警報）（WARN、23 件：高 7・中 11・低 5）

詳細と出典の全文：[notes/ATA-31-warning.md](notes/ATA-31-warning.md)

| ID | 種別 | 重要度 | 規模 | 内容 | 根拠 | 該当コード |
|---|---|---|---|---|---|---|
| WARN-01 | バグ | 高 | S | 最後のページで CANC を押すと `caut_adv_display = 0` になり、**その後に立った caution/advisory も RCL を押すまで一切表示されない**（master CAUTION と beeper だけ出る）。FCOM は新しい非常事態のメッセージを表示する。個別の「CANC 済み」印が要る | FCOM p.1530 (15.10.4)、p.1549 (15.20.3) | `B747.60.xt.fltInst02.lua:1467-1479`、`B747.87.xt.warning.lua:943` |
| WARN-02 | 挙動の誤り | 高 | M | siren が master WARNING 灯（`master_warning`）に結ばれている。灯が点いている間は**どの warning でも siren**（火災なら bell と同時、AP 切断なら wailer と同時、火災試験でも）で、master リセットで灯を消すと siren も止まる → T/O CONFIG、フラップが原因の CONFIG GEAR、109 SB 前の OVERSPEED など**リセット不可の siren が止まってしまう**。Lua の `warning_bell/siren/wailer` はどの .snd も読まない。wailer は X-Plane の AP 切断 annunciator 駆動で、FCOM の「最低 1 秒、2 回目の押下で停止」とは別物。直すには .snd の結線変更（要承認） | FCOM p.1550–1552 (15.20.4–6)、p.655 (4.10.17)、ATA31 p.170、p.176、p.194 | `fmod/747-400.snd:5792-5823`、`B747.87.xt.warning.lua:804-834` |
| WARN-03 | 挙動の誤り | 高 | S | bell は X-Plane の `engine_fire` annunciator と火災試験ボタンで鳴るので、**master リセットで消音できない**。APU・貨物室・脚格納部の火災では鳴らない（FIRE APU・CARGO・WHEEL WELL の各メッセージ自体も立たない。条件は火災ノート）。火災試験の TEST IN PROG／FIRE TEST PASS/FAIL も出ない | FCOM p.1550 (15.20.4)、p.919 (8.20.7)、ATA31 p.173 | `fmod/747-400.snd:5825-5851`、`B747.87.xt.warning.lua:817-828`、`B747.35.xt.fire.lua:98-103, 487-513` |
| WARN-04 | 挙動の誤り | 中 | S | beeper は `master_caution` の立ち上がりで 1 回鳴るだけなので、master CAUTION が点いたまま次の caution が立っても**鳴らない**。1 秒パルスの `master_caution_audio` は `747-400_XP11.snd` しか使っていない | FCOM p.1552 (15.20.6) | `fmod/747-400.snd:5774-5791`、`B747.87.xt.warning.lua:842-844` |
| WARN-05 | 欠落 | 高 | M | **抑止が一切無い**：始動前（全 FUEL CONTROL CUTOFF の地上で master CAUTION・beeper を抑止）、始動中、離陸（80 kt〜400 ft/20 秒の caution、V1〜400 ft/25 秒の warning、リフトオフ〜800 ft/140 秒の CONFIG GEAR、ENG FAIL の地上抑止など）、着陸（LAND 2/3 かつ 200 ft〜）、STATUS cue、他メッセージによる抑止（§4.4.1）、時間遅れ。結果として電源投入時や離陸滑走中にも master CAUTION と beeper が出る。`>ENG SHUTDOWN` でも master CAUTION と beeper が出る | FCOM p.1586–1602 (15.20.40–56)、p.902 (7.40.4)、ATA31 p.180、p.196 | `B747.87.xt.warning.lua:795-887` |
| WARN-06 | 挙動の誤り | 高 | S | **表のレベル誤り**：ENG 1–4 FAIL が warning（FCOM は caution。赤・master WARNING・siren になる）、ELEC GEN OFF 1–4 が caution（109/570 は advisory）、FUEL PRES STB L/R が caution（advisory）、>SMOKE LAVATORY・TIRE PRESSURE の caution 版と DOOR U/D FLT LK の advisory 版という誤った重複定義。既報の caution 67・68（`FUEL PRES STAB L` が 2 つ）もここ | FCOM p.899 (7.40.1)、p.822 (6.30.2)、p.1476 (12.30.4)、p.923、p.1522、p.546 | `B747.87.xt.warning.lua:101-104, 161, 173, 175-176, 179-182, 264` |
| WARN-07 | バグ | 低 | S | **文言・添字の誤り**：memo の DRindex 41 が `ACARS CALL` と `ACARS VOICE` で重複、`PRINTER MESSAGE` が 2 つ、`FUEL OVRD CTR`（FCOM `>FUEL OVD CTR`）、`FUEL PMP STAB`（`>FUEL PMP STB`）、`>FUEL TEMP LOW`・`>WINDSHEAR SYS` の余分な `>`、`IRS … CENTRE`（`CENTER`）。init 側の表は `SPEEDBRAKE ARMED` が無く `IRS ALIGN MODE` の順が逆で、配列の大きさは偶然足りているだけ | EICAS-MESSAGES.md §2 | `B747.87.xt.warning.lua:339-340, 345-346, 358, 411-417, 484, 521, 534-536`、`init/scripts/B747.87.warning/B747.87.warning.lua:439-471` |
| WARN-08 | 欠落 | 中 | M | **表に無い FCOM メッセージ**（約 30 件：OVHT ENG NAC、>ENG LIM PROT、ENG EEC MODE・FUEL VLV・LOW IDLE・OIL FILT・OIL PRESS、>BTL LO ENG、>AUTOSTART OFF、>ENG CONTROLS、SATCOM 系、ATC MESSAGE、SATCOM CALL、貨物機の DOOR NOSE CARGO・SUPRNMRY OXY ON・>SMOKE CREW REST など）と、**FCOM に無い定義**（約 45 件）。立てているのは表の 36%（458 件中 165 件）。条件は各系統、表の整理は警報系統の作業 | EICAS-MESSAGES.md §1・§2 | `B747.87.xt.warning.lua:72-540` |
| WARN-09 | バグ | 中 | S | **ページ割りの不具合**：(1) warning を 2 ページ目に複製するときの使用印を元の位置に付けているため、2 ページ目の warning が最後に空白で消される、(2) ページ数の式が warning の繰り返し行を数えず、warning が 11 件以上だとページ数＝warning 件数になる、(3) パネルは 2 ページ分しか無く PG は 3 ページ以上でしか出ないので、2 ページあっても番号が出ない（パネル側）、(4) ページが減っても `msg_page` を詰めない、(5) memo のはみ出し処理の添字の誤り（`fmod(...,10)`、`page*11`）、(6) 新しいメッセージを見ているページに出さない | FCOM p.1528、p.1549 | `B747.87.xt.warning.lua:898-901, 925-938, 980-1007`、`747-400.acf:117872` |
| WARN-10 | 挙動の誤り | 中 | S | 待ち行列と表示を作るのが約 2 秒ごと、電源投入後は 4 秒待ってから。メッセージ・master 灯・FMOD の siren/beeper が最大約 2 秒遅れ、同じ周期内に立ったものは表の順に並ぶ | FCOM p.1548（新しい順）。遅れの許容値は資料に記載なし | `B747.87.xt.warning.lua:1137-1158` |
| WARN-11 | 挙動の誤り | 高 | M | **離陸形態警報**：内側エンジンの N1 > 90（CONFIG FLAPS は 96、FMC のフラップ設定があれば 86）を**エンジン 2 と 3 の両方**に要求（FCOM は 2 **または** 3、ATA27 は N1 66.5 PW／66.7 RR／75.0 GE）→ 減格離陸や片側の出遅れで鳴らない恐れ。enable のラッチ・V1 での disarm・10 秒の保持が無く毎フレーム IAS<V1 で判定。CONFIG FLAPS は前縁を見ず、FMC の離陸フラップとの一致を余分に要求。CONFIG GEAR CTR はタイヤの操舵角で代用。CONFIG STAB は「FMC のトリム ±2.25 ユニット」の近似（§4.8 の 3 帯なし、コード中に TODO）。試験機能なし | FCOM p.1557、p.1603–1604、ATA27 p.729–730、ATA31 p.188–194 | `B747.45.xt.fltCtrls.lua:995-1029, 1050-1143` |
| WARN-12 | 挙動の誤り | 高 | S | **着陸形態警報（CONFIG GEAR）**：「いずれかのレバーが閉」を全エンジン共通値 `throttle_jet_rev_ratio_all` < 0.05 で判定。この値は EEC が 4 本の平均を書く場面があり（`B747.42.xt.EEC.lua:926, 994`）、1 本だけ閉じても警報が出ない。レバー位置 `laminar/B747/engine/throttle` を 1 本ずつ見るべき。リセット可／不可の区別、戻したレバーの記憶、GND PROX GEAR OVRD、脚上げ後 140 秒の抑止、RA 喪失時の扱いが無い | FCOM p.1556–1558、ATA31 p.209–214、ATA27 p.735–736 | `B747.45.xt.fltCtrls.lua:980-988, 1031-1048` |
| WARN-13 | バグ | 中 | S | **SPEEDBRAKES EXT の条件式**：`and` が `or` より強いので「RA 15〜800 ft」**または**「フラップ着陸位置かつレバー 1 本以上が前」になっている。「2 本以上が閉より前（RA>15 ft）」の条件が無く、レバー数は全エンジン共通値から 1 本としか数えない。飛行中の CONFIG SPOILERS（405/570 のみの機能）は N1>90 の本数と 1 秒タイマーで判定 | FCOM p.958 (9.30.2)、p.1558、ATA31 p.220–222 | `B747.45.xt.fltCtrls.lua:943-963, 1101-1110, 1155-1168` |
| WARN-14 | 欠落 | 中 | M | **グリーンバンド機能が無い**：GW・CG・推力定格からの 3 帯選択、前脚オレオとの照合、CG の有効範囲、STAB GREENBAND（advisory/status）、グリーンバンド灯の点灯条件（地上・enable・V1 で消灯）。帯の境界値は資料に無いので推定が要る | ATA31 p.200–204、ATA27 p.747、FCOM p.958 | `B747.45.xt.fltCtrls.lua:1113-1143`（近似のみ） |
| WARN-15 | 挙動の誤り | 中 | S | **OVERSPEED** が Vmo/Mmo ではなく PFD の maximum speed（`Vmax`＝Vmo・フラップ・脚の制限の最小値）と比較するので、フラップ・脚の制限超過でも warning＋siren。28,620 ft 以下で Mmo=0.88 とする扱いも ADC の Vmo/Mmo とは別（値そのものは計器ノート）。**AIRSPEED LOW** が最小機動速度でなく Vmc か Vs（シェーカー速度）との比較で、RA 100 ft 以上という独自条件付き | FCOM p.1557、p.969 (10.10.7)、p.973 (10.10.11)、p.1556、ATA31 p.176 | `B747.60.xt.fltInst02.lua:2948-2983, 3156-3174` |
| WARN-16 | 欠落 | 中 | M | **高度警報が無い**：ALTITUDE ALERT（caution 2）を誰も立てず、master CAUTION・beeper も出ない。PFD の白枠・琥珀枠はパネルに無い（パネル変更が要る）。音は X-Plane 本体の高度警報（`baro_altimeter_alert_lit_pilot`、acf は `_warn_alt_dep_100`）で鳴り、747 の論理（arm 後の 300 ft 逸脱、900 ft で解除、G/S 捕捉・着陸形態で抑止）とは別 | FCOM p.1559 (15.20.13)、ATA34_1 p.183–192 | `B747.87.xt.warning.lua:110`、`fmod/747-400.snd:5762-5773` |
| WARN-17 | 欠落 | 中 | M | **STATUS メッセージと STATUS cue が無い**：STATUS ページ（synoptic 2）は数値表示だけでメッセージ行が無く、`CAS/status_cue`・`sec_eng_exceed_cue` は作るだけで誰も使わない。STAT のページ数は常に 1。表示にはパネル追加（カスタム acf、要承認） | FCOM p.1528、p.1545、p.1549 | `B747.60.xt.fltInst02.lua:1395-1409, 3432-3433`、`B747.87.xt.warning.lua:616-617`、`747-400.acf:129369` |
| WARN-18 | 挙動の誤り | 中 | M | **失速警報**が AOA ではなく「速度 < 表から作った Vs（失速要素の数で補正）」で `stallwarning` を立てる。フラップ・Mach・スピードブレーキで補正した alpha max と比べる論理ではないので、旋回・引き起こしなど荷重がかかった状態で早期警報にならない。シェーカーの 3D 動作は無く、音（FMOD の stall）だけ。過回転のシェーカーなし | ATA27 p.692、p.701、FCOM p.1556、p.973 | `B747.60.xt.fltInst02.lua:3012-3123, 3577` |
| WARN-19 | 欠落 | 中 | S | GPWS の PULL UP・WINDSHEAR で **master WARNING 灯が点かない**（PFD 表示は X-Plane の annunciator で出る）。音声の優先と抑止（即時ウインドシアが TCAS・他の GPWS を抑止、GPWS 警報中は TCAS を TA ONLY、warning 音声が caution 音声を抑止、低い音を待たせる）が無く、FMOD が各イベントを独立に鳴らす。TCAS と PWS の音声イベントは bank にあるが .snd に結線されていない | FCOM p.1532、p.1555、p.1582–1583、ATA31 p.159–160、p.228 | `B747.87.xt.warning.lua:795-834`、`fmod/747-400.snd:5942-6104`、`fmod/GUIDs.txt`（TCAS・PWS イベント） |
| WARN-20 | 欠落 | 低 | M | PILOT RESPONSE（乗員覚醒監視）が無い（405/570・SB 後 109 の機能。FMC 側で操作の監視が要る） | FCOM p.1559、p.1606 | `B747.87.xt.warning.lua:96, 159, 443`（表だけ） |
| WARN-21 | 欠落 | 低 | S | チャイムの論理が無い：SELCAL・ACARS・客室呼出しの low chime と離着陸時の抑止。FMOD の ding は外部電源接続や IRS 選択、FMC の EXEC 灯などに結ばれている | ATA31 p.218、p.181、FCOM p.1593、p.1600 | `fmod/747-400.snd:5866-5940` |
| WARN-22 | 挙動の誤り | 低 | S | 警報系統の電源判定が「sim のバス 0 が 5 V 未満、または `rel_esys2` 故障」。実機の MAWEA は AC standby bus と F/O instrument transfer bus、スピーカーは 28 V DC で、standby 電源だけでも動く（表示側の電源は表示ノート） | ATA31 p.100、ATA27 p.704 | `B747.87.xt.warning.lua:587, 1140` |
| WARN-23 | バグ | 低 | S | エンジン始動状態の quick start で未定義の global（`B747DR_sfty_no_smoke_sel_dial_pos` など）に代入しており、サインが設定されない | — | `B747.87.xt.warning.lua:1078-1083` |

### 表示（PFD・ND・EICAS の画面、表示の切替）（DSP、35 件：高 6・中 19・低 10）

詳細と出典の全文：[notes/ATA-31.md](notes/ATA-31.md)

| ID | 種別 | 重要度 | 規模 | 内容 | 根拠 | 該当コード |
|---|---|---|---|---|---|---|
| DSP-01 | 挙動の誤り | 高 | S | PFD の方位目盛が `laminar/B747/nd/up/*` で回る。ND が MAP なら航跡、PLN なら 0（真北）が上になり、PFD の方位ポインターが IRS 方位を示さない。ND 側は同じ dataref が必要なので Lua だけでは直せない【パネル変更要：PFD を方位の dataref に】 | FCOM p.997 (10.10.35) | nd.lua:698-721; 747-400.acf:88024, 88078, 91613, 91667, 95171, 95225, 98739, 98793 |
| DSP-02 | 欠落 | 高 | L | ソース選択が無い。FLT DIR・NAV・EIU・AIR DATA の選択器と中央 EIU SEL は位置を変えるだけ。IRS 選択器は姿勢の有効判定にだけ効く。PFD/ND は常に X-Plane の pilot/copilot 側、RA は両 PFD とも機長側（`efis/radio_altitude`）。比較監視（SOURCE SEL、SNGL SOURCE）も無い【一部パネル変更要：速度テープは Lua のみ】 | FCOM p.1043-1044, p.1197; ATA31 p.16 | fltInst02.lua:520-657, 2366-2379; irs_system.lua:209-210 |
| DSP-03 | 挙動の誤り | 高 | M | パネルが NAV ソース選択器（FMC L/FMC R/CDU）を ND の基準受信機の選択に流用。機長 ND は NAV=0 で ILS L、1 で ILS R、2 で VOR L、3 で VOR R（副は 2=ILS L、3=ILS R、0/1=VOR で、要素によって 0 と 1 が入れ違い）。通常位置 FMC L では VOR モードにコース・偏位・受信機表示が出ない。PFD の ILS コースと DME は FMC master 選択器で nav1/nav2 を切り替える【パネル変更要：基準受信機用の dataref を新設】 | FCOM p.1043-1044, p.1144 | 747-400.acf:108772, 108834, 108900（機長 ND）、86769, 87735（PFD）; fltInst02.lua:3453-3454 |
| DSP-04 | 欠落 | 中 | L | PFD の故障フラグは ATT・HDG・VERT（どれも IRS 未整列で一斉）と NO V SPD だけ。SPD・ALT・MACH・FD・G/S・LOC・RA・DH・FPV・SEL SPD・SPD LIM・NO TDZ・PITCH/ROLL が無い（PITCH/ROLL は画像だけある）。NCD と invalid の区別も無い【パネル変更要】 | FCOM p.999; ATA31 p.15-17 | 747-400.acf:87107, 88117 |
| DSP-05 | 挙動の誤り | 高 | M | 速度テープの帯が違う。最大機動速度は常に Vmax−10（高高度・高重量でだけ出るはず）。最小機動速度は重量とフラップの独自式（20,200 ft の区分、1.3 g、VREF+80 が無い）。表示開始は推力基準が TO 以外になったとき（最初のフラップ上げではない）【Lua のみ】 | FCOM p.969, p.973 | fltInst02.lua:2858-2876, 2986 |
| DSP-06 | 挙動の誤り | 高 | S | OVERSPEED を Vmax（フラップ・脚 placard 込み）で出している。FCOM では Vmo/Mmo のみ【Lua のみ】 | FCOM p.1557 (15.20.11) | fltInst02.lua:3156-3164 |
| DSP-07 | バグ | 中 | S | 最小速度（Vs）の高度区分で 0 ft 以上は常に 0〜2,000 ft 帯（elseif が届かない）。2,000 ft 超の値が 2,000 ft で頭打ち【Lua のみ】 | — | fltInst02.lua:3018-3032 |
| DSP-08 | バグ | 中 | S | 表の誤記：VsData F20 10,000 ft 200 t＝133.60、F20 0 ft 360 t＝156.66、VR F10 D 領域 320〜420 t＝93〜111、VR F20 D 220 t＝97、V2 F20 E 380 t＝149（V 速度は FMC 担当と調整）【Lua のみ】 | — | fltInst.lua:116, 137, 193, 274, 277 |
| DSP-09 | バグ | 高 | S | DH RST を押すと、両席の DH を 350 ft（MDA 選択中は MDA を 1,000 ft）に書き換える。RST は点滅を消すだけ。副の RST は機長側のスイッチ位置も 1 にして離しても戻さないので、機長が RST を押し直すまで DH 警報が毎フレーム即解除される（3D のボタンも押されたまま）【Lua のみ】 | FCOM p.1036 | fltInst02.lua:778-792, 949-963 |
| DSP-10 | 挙動の誤り | 中 | M | DH 警報は機長の DH・RA だけで計算し、両 PFD が同じ `dec_height/display_status` を読む（副の PFD も機長の DH で表示が変わる）。点滅は 5 秒で止まり点灯のまま（時間は資料に記載なし）。RA の amber グループの条件が矛盾（`<= DH`）【パネル変更要：席ごとの dataref】 | FCOM p.981-982 | fltInst02.lua:2248-2311; 747-400.acf:86841, 86915 |
| DSP-11 | 挙動の誤り | 中 | S | STD を押すと preselect を 29.92 にするので、戻すと「STD 前の値」でなく 29.92 になる。遷移高度の amber 枠が無い（パネル）。CDU の BARO 入力・STD が両席に効く【一部パネル変更要】 | FCOM p.995, p.1037, p.1064 | fltInst02.lua:859-871, 1030-1042; B744.fms.pages.lua:957-984 |
| DSP-12 | 欠落 | 中 | L | PFD の記号が無い：FPV（スイッチもラッチしない）、PLI、TDZ、選択高度枠の白強調と amber、LCD のバンク 35° amber、範囲外の V1・VREF の数字、VR の「R」、ILS 偏位過大の amber・点滅、ILS 周波数・コース不一致の線【パネル変更要】 | FCOM p.972-993 | fltInst02.lua:875-881 |
| DSP-13 | 挙動の誤り | 低 | S | フラップ機動速度バグをレバー位置（flap_ratio）の重なった範囲で出す。フラップ 30 で 20 のバグが残る。25 の値が VREF30+5（FCOM は VREF25）【Lua のみで近似可】 | FCOM p.972, p.229 | fltInst02.lua:2882-2902; 747-400.acf:85859 |
| DSP-14 | 挙動の誤り | 中 | S | PFD の ILS 表示（`ils_dots`）が「目的地から 50 NM 以内」を条件にしている。FCOM は同調で目盛表示（現状では離陸時に同調しても LOC が出ない）【Lua のみ】 | FCOM p.987 | autopilot.lua:1635-1638, 1792-1797 |
| DSP-15 | バグ | 中 | S | パネルの参照誤り：機長 ND の TRK/HDG 表示が副の ND モード選択器、中心表示の方位ポインターが副の方位、拡大 APP の G/S が副の偏位、ILS R の周波数が nav3、ILS/VOR の識別符号フラグの取り違え、空の dataref 名の条件 182 か所、EICAS の表示条件が存在しない `display/fo/(pri_)eicas_pos`【パネル変更要】 | INTERFACES.tsv | 747-400.acf:109432, 109475, 109516, 108994, 110018-110045, 116618, 116632, 116915, 99470, 117804, 125278 |
| DSP-16 | 欠落 | 中 | M | DATA・POS が機能しない（スイッチが状態を持たず、CDU でもコメントアウト）。WPT の ETA・高度、IRU/GPS 位置、VOR radial が無い【一部パネル変更要】 | FCOM p.1040 | fltInst02.lua:1196-1210, 1357-1371; B744.fms.pages.lua:855, 890 |
| DSP-17 | 欠落 | 低 | M | STA に高・低高度の区別が無く、同調施設も STA オフでは出ない。出発・到着空港と滑走路を常時出さない。60 個で黙って打ち切り（EXCESS DATA なし）。MAP フラグは IRS 未整列のときだけ。109 では出ない TAS を出す【一部パネル変更要】 | FCOM p.1040, p.1111, p.1149 | nd.lua:254, 256-316; B747.68.xt.fms.lua:1032-1034 |
| DSP-18 | 欠落 | 中 | M | TCAS：TA/RA での TFC 自動選択（4.5）が無い。記号は白の菱形 1 種（相対高度 2,000 ft 以内を全部）。アイコン画像 `nd_icons-1.png` には RA 赤・TA amber・白の菱形と上下矢印があるのに使っていない。近接（白塗り）の絵と amber の相対高度文字は無い。TCAS OFF を TFC 未選択でも出す、TA ONLY が無い。X-Plane の地図の TCAS 表示は `EFIS_tcas_on_copilot` を使わず、どちらかの TFC で機長側の 1 本を立てる【一部パネル変更要（色分けと矢印は Lua のみ）】 | FCOM p.1032, p.1152-1154, p.1584 | fltInst02.lua:2566-2603; nd.lua:274-279, 496-509 |
| DSP-19 | 欠落 | 低 | M | TERR は外部 Terrain Radar 頼みで、この X-Plane には入っていない。カスタム acf には `*.terrain_radar_descr` も無い。地形・PWS 警報での自動表示も無い【Lua のみ（外部依存を除く）】 | FCOM p.1585 | fltInst02.lua:1212-1219; nd.lua:705-714 |
| DSP-20 | 欠落 | 中 | M | HDG REF スイッチが 3D の位置しか動かさない。TRU 表示、高緯度の自動 TRU、amber 点滅枠、HDG SEL→HDG HOLD が無い【パネル変更要（TRU 表示）】 | FCOM p.1046, p.1110 | manipulators.lua:1479-1481 |
| DSP-21 | バグ | 低 | S | 航跡線の判定に CTR の押しボタン位置（押している間だけ 1）を使い、副の判定に機長の WXR 状態を使う。ND のアイコン作り直しの 0.2 秒判定が `diff2` でなく `diff`（2 秒周期の基準）を見ており、ほぼ毎フレーム全アイコンを作り直す【Lua のみ】 | FCOM p.1143 | fltInst02.lua:2610-2630; nd.lua:748-752 |
| DSP-22 | 挙動の誤り | 低 | S | MAP で LNAV/LOC/ROLLOUT 中、選択方位の破線だけでなくバグごと消す（バグと破線が同じグループ）【パネル変更要】 | FCOM p.1142 | fltInst02.lua:3588-3625; 747-400.acf:109809 |
| DSP-23 | 欠落 | 低 | M | トレンドベクトル、S/C・E/D・減速点、待機・PT、エネルギー円、FIX 基準点が無い【パネル変更要】 | FCOM p.1147-1150 | nd.lua:466-495 |
| DSP-24 | 欠落 | 中 | L | EICAS の compact・部分表示・二次エンジン逸脱差が無い。ENG の自動表示を地上・RUN 方向でも出す（空中の CUTOFF のみのはず）。電源投入時の自動表示は flight start のときだけで、停電からの復帰では出さない【パネル変更要（自動表示の条件は Lua のみ）】 | FCOM p.843, p.872-875 | fuel.lua:568-594; fltInst02.lua:1386-1393, 3441 |
| DSP-25 | 欠落 | 中 | M | STAT ページにステータスメッセージの行が無い（Lua のページ送りだけある）。STATUS 差も無い【パネル変更要】 | FCOM p.1528, p.1545 | fltInst02.lua:1395-1411; 747-400.acf:129368 |
| DSP-26 | 欠落 | 低 | S | CAS の表示はパネルが 2 ページ分だけ。警報モジュールは最大 10 ページ作る【パネル変更要】 | FCOM p.1548-1549 | 747-400.acf:118045; warning.lua:898-902 |
| DSP-27 | 欠落 | 中 | L | 表示器と EIU の故障が無く、自動切替（PFD→inboard、PRI EICAS→lower）、EIU の AUTO 切替、「standby 電源で左 EIU 故障なら全消灯」が無い【Lua のみ（compact を除く）】 | FCOM p.1045, p.1072, p.1529 | fltInst02.lua:3236-3404 |
| DSP-28 | バグ | 中 | S | 選択器の組み合わせ 81 通りのうち 11 通りしか処理せず、他は直前の配置のまま。INBD EICAS で ND を lower へ、INBD PFD で secondary EICAS を outboard へ移すなど資料に無い入れ替えをする【Lua のみ】 | FCOM p.1045, p.1073 | fltInst02.lua:3239-3403 |
| DSP-29 | 挙動の誤り | 中 | M | 表示の電源が粗い：副表示の AC1 代替を STBY POWER 選択器に依存させ、upper EICAS を機長表示と同じ扱い、EIU は無い。APU 始動中に機長表示を消す処理は資料に記載なし（ATA-24 の ELEC-01/02 が前提）【Lua のみ】 | FCOM p.800, p.804 | electrical.lua:546-548, 624-626; fltInst02.lua:3245-3250 |
| DSP-30 | 欠落 | 低 | S | 輝度が表示器でなく内容に付く（PFD を inboard に移しても outboard のつまみ）。3D のつまみが操作する `instrument_brightness_ratio[1]`・`[4]`・`[11]`（WXR の内側つまみと推定）を使う計器が無い。周囲光の自動補正なし【一部パネル変更要（WXR）】 | FCOM p.1047-1048, p.1071 | lighting.lua:893-918 |
| DSP-31 | 挙動の誤り | 中 | S | CDU の EFIS 操作：RANGE が両席に効く、WXR は常に機長側、MODE が X-Plane の map_mode を更新しない、POS/DATA 不可、SELECT が常時出る（パネル故障の概念なし）【Lua のみ】 | FCOM p.1060-1068 | B744.fms.pages.lua:849-993, 45-90 |
| DSP-32 | 欠落 | 中 | M | 表示系メッセージの大半（3.8 の「未実装」）が無い。文言は表にあるが立てる処理が無い【Lua のみ（DSP-02 に依存）】 | FCOM p.1197-1199, p.1430 | warning.lua:109-111, 152, 165, 274-277, 371, 452-457, 477 |
| DSP-33 | バグ | 低 | S | 時計：CHR が 60 分で 59:99 に止まる（99:59 まで）。CHR 表示中は ET の開始・リセットが効かない。SET 選択器が何もしない。UTC・日付・ET の表示に電源条件が無く、年は OS の日付。表示消灯は `clock_utc_display=2` などパネルの値で可能【Lua のみ】 | ATA31 p.67-68, p.74; FCOM p.1075 | fltInst03.lua:127-149, 190-204, 216-225, 260-262, 318-346（fltInst04 も同じ） |
| DSP-34 | 挙動の誤り | 中 | M | 計器モジュールが他系統の出力を書く：stick shaker を「速度 < 表の Vs」で出し、`TOGA_pitch_deg` を書き、BAT DISCH MAIN・BATTERY OFF を立てる（ATA 27・22・24 へ移す）【Lua のみ】 | ATA27 p.701 | fltInst02.lua:3083-3123, 3197-3216 |
| DSP-35 | バグ | 低 | S | ACF_DIFF §2 の「ADF 方位針 2 個」は実は機長 ND 中心表示の VOR L/R 針。コードは VOR L/R を nav 番号 2/3 に同調するので純正の `[2]`・`[3]` が正しく、カスタムの `[3]`・`[4]` は誤り（VOR L 針が VOR R を指す）。ADF 針の `adf1/2_relative_bearing_deg[10]`（スカラーに添字）も要確認【パネル変更要（カスタム acf）】 | ACF_DIFF.md §2 | 747-400.acf:109044, 109062; 747-400_custom.acf:98755, 98773; 747-400.acf:99631 |

### 航法センサーと無線（ATA 34）（NAV、81 件：高 13・中 37・低 31）

詳細と出典の全文：[notes/ATA-34.md](notes/ATA-34.md)

| ID | 種別 | 重要度 | 規模 | 内容 | 根拠 | 該当コード |
|---|---|---|---|---|---|---|
| NAV-01 | 欠落 | 高 | L | ADC が 3 台として存在しない。AIR DATA 選択器は飾り（読む側なし）で、表示と全系統が X-Plane の pilot / copilot 系を固定で使う。C ADC、relay の interlock、電源依存、ADC 故障の扱いが無い。3D ノブとコマンドは 0–1 の 2 位置で、109 の L/C/R と合わない | FCOM p.1044・p.1079、ATA34_1 p.98–114 (34-12) | B747.60.xt.fltInst02.lua:568-577・632-641・3223-3234、Cockpit_Panel.obj:31894・31937 |
| NAV-02 | バグ | 高 | S | OVERSPEED の条件が誤り。(1) Vmo の代わりにフラップ・脚の placard を含む Vmax を使い、placard 超過でも siren が鳴る。(2) 28,620 ft 以下で Mmo = 0.88 としているので、約 26,500–28,620 ft で Vmo 未満でも鳴る（例：27,000 ft・360 kt ≈ M0.88、計算による推定）。資料は Vmo 365 kt / Mmo 0.92 の 1 本 | ATA34_1 p.140–143、FCOM p.1557・p.1605 | B747.60.xt.fltInst02.lua:2946-2983・3156-3164 |
| NAV-03 | 欠落 | 高 | M | ALTITUDE ALERT が無い（表だけ）。判定、beeper、PFD の白枠・琥珀枠が無く、パネルにも枠の要素が無い。EICAS と beeper は Lua で作れ、枠はパネル変更 | FCOM p.992・p.1559・p.1605、ATA34_1 p.178–194 | B747.87.xt.warning.lua:110、747-400.acf:87470-87560 |
| NAV-04 | 欠落 | 中 | S | IAS DISAGREE（≥ 5 kt、5 s）と ALT DISAGREE（> 200 ft、5 s）が無い（表だけ）。pilot / copilot 系は別々に故障させられるので Lua で作れる | FCOM p.1197–1198 | B747.87.xt.warning.lua:109・152 |
| NAV-05 | 欠落 | 中 | M | PFD に SPD・ALT・MACH 旗が無く、Mach は真値（machno）なので ADC・pitot 故障と source 選択が効かない。パネル変更が要る | ATA34_1 p.126–130、FCOM p.999 | 747-400.acf:85995-86000 |
| NAV-06 | 挙動の誤り | 中 | S | BARO STD：STD 押しで preselect を 29.92 に上書きするので、もう一度押しても STD 前の値に戻らない（preselect を回した場合を除く） | FCOM p.1037、ATA34_1 p.135–136 | B747.60.xt.fltInst02.lua:859-871・1030-1042 |
| NAV-07 | バグ | 低 | S | >AOA RIGHT が pilot 側（左）の AOA 故障 `rel_AOA` で出る。右は `rel_cop_AOA` | FCOM p.1198、X-Plane DataRefs.txt | B747.60.xt.fltInst02.lua:163・3176-3182 |
| NAV-08 | 欠落 | 低 | S | gear down / spare engine dispatch の Vmo 曲線（270 kt / M0.73）と VMO GEAR DOWN・VMO SPARE ENGINE メモが無い（整備上の設定。省略可） | ATA34_1 p.142–143、FCOM p.1557 | B747.87.xt.warning.lua:531-532 |
| NAV-09 | バグ | 低 | S | HEAT P/S L AUX・R AUX と TAT heat が無く、HEAT L/R AOA は float の着氷率が 6 のときという成立しない条件（ATA 30 と共有） | FCOM p.635、ATA34_1 p.60・p.164・p.166 | B747.50.xt.antiice.lua:84-85・505-519、B747.87.xt.warning.lua:372-379 |
| NAV-10 | 欠落 | 中 | S | FLT DIR・EIU（左右と中央）の選択器は読む側が無い（quick start とクリック音だけ）。IRS 選択器は PFD/ND の有効旗（`pfd/{capt,fo}/irs`）をどの IRU のアライン状態で決めるかにだけ使われ、姿勢・方位の値は選択によらず AHARS 1/2。EIU AUTO の優先順、中央 EIU の EICAS 切替、IRS 選択の副作用（autobrake の IRU、C IRU の ADC ポート、WXR・失速警報の IRU）が無い | FCOM p.1043–1044・p.1529、ATA34_2 p.278・p.296–300 | B747.60.xt.fltInst02.lua:520-565・584-629・648-656、irs/irs_system.lua:209-212 |
| NAV-11 | 挙動の誤り | 中 | M | NAV 選択器をパネルが ND の基準受信機（APP の ILS L/R、VOR の VOR L/R と周波数・コース・DME・指針）の選択に流用している（Capt：0 = ILS L、1 = ILS R、2 = VOR L、3 = VOR R。F/O：2/3 = ILS L/R、0/1 = VOR）。FCOM の FMC L/R・CDU の意味が無く、通常位置（FMC L）だと VOR モードで基準 VOR の欄とコース指針が出ない側がある。F/O の centered VOR は指針とヘッダの L/R が逆。実機は ILS を EIU 選択と表示器のロジックで決め、VOR は自側（推定）。パネル変更が要る | FCOM p.1038・p.1043–1044・p.1275、ATA34_1 p.474 (34-31)・p.550 (34-55) | 747-400.acf:99323-99497・100141-100315・107005-107438（F/O）、108772-108946・109590-109764・116454-116887（Capt）。カスタム acf も同じ |
| NAV-12 | 挙動の誤り | 中 | S | FMC master 選択器が X-Plane の `autopilot_source`（NAV1/NAV2）を切り替え、パネルでは ILS L/R の DME 表示選択に使われる。A/T 解除の行はコメントアウト。FCOM は誘導指令を出す FMC の選択で、A/T 作動中の切替で A/T 解除（FMC・A/T 担当と共有） | FCOM p.1215・p.666 | B747.60.xt.fltInst02.lua:660-666、747-400.acf:86810-86827 |
| NAV-13 | 欠落 | 低 | S | >SOURCE SEL ADC/EIU/F/D/IRS/NAV、>SNGL SOURCE RA、>EIU LEFT、ALT ALERT SYS は表だけで設定箇所なし。P/S XFR VLV は表にも無い（NAV-01・NAV-10 が前提） | FCOM p.1197・p.1199、ATA34_1 p.58・p.194 | B747.87.xt.warning.lua:190・277・452-457 |
| NAV-14 | 挙動の誤り | 中 | M | standby 計器が独立していない。standby ASI = Capt の速度、standby altimeter = Capt の高度と気圧設定（standby の BARO ノブは `sim/instruments/barometer_up/down` で Capt PFD の気圧を変え、EFIS の STD でも 29.92 になる）、standby attitude = X-Plane の AHRS（GYRO 旗、battery 依存、erect、caging、APP 表示なし）。直すには obj の dataref 変更が要る | ATA34_1 p.76–80、ATA34_2 p.244–252、FCOM p.1053–1056・p.1075 | Cockpit_Panel.obj:32047・32084・32100-32102・32126-32401、747-400_cockpit.obj:23167、B747.60.xt.fltInst02.lua:2389-2392 |
| NAV-15 | 挙動の誤り | 低 | S | RMI は 109 に無い（405 だけ）が 3D にある。heading カードは X-Plane の electric gyro で、405 の「F/O の IRS 選択で右か中央の IRU」と違う。指針は VOR L/R（`nav_relative_bearing_deg[2]/[3]`）と ADF の切替 | FCOM p.1056・p.1074–1075 | Cockpit_Panel.obj:32419-32456、B747.60.xt.fltInst02.lua:2217-2233 |
| NAV-16 | 挙動の誤り | 高 | M | MSU の遷移が実機と違う。(a) ALIGN 位置では何も進まず、アラインは NAV を選んでから 600 秒。(b) NAV→ALIGN でアラインを捨てる。fast realignment（約 30 秒）ができず毎回フル。(c) 高緯度アライン（ALIGN で 17 分）ができない。(d) memo は NAV でアライン中しか出ず、600 秒で消える（位置が未入力でも） | FCOM p.1216・p.1227・p.1430・p.194、ATA34_2 p.335・p.338・p.352 | B747.30.xt.fltMgmt.lua:168-208、irs/irs_system.lua:109-126・215-235 |
| NAV-17 | 欠落 | 中 | M | 位置入力の検査が無い。11 文字以上なら何でも受け付け、値は IRU 位置に使わない（IRU 位置は真位置 + 起動時の乱数 ±0.001°）。最後の位置との 1° 比較、終了時の緯度比較と 2 回失敗での IRU 故障、再アラインの 1/2°・1° 比較が無い。CYCLE IRS OFF-NAV と IRS POS/ORIGIN DISAGREE は定義だけ | ATA34_2 p.342–348・p.352、FCOM p.1287・p.1431・p.1433 | B744.fms.pages.lua:1223-1242、irs/irs_system.lua:29-63、B744.notifications.lua:7・25 |
| NAV-18 | 挙動の誤り | 中 | S | `irsSystem.setPos` を一度 true にすると戻さない（`irsSystem.off` はどこからも呼ばれない）。2 回目以降のフルアラインは位置入力なしで完了する。IRU が OFF でも位置が未入力ならボックスが出る | FCOM p.1286–1287、ATA34_2 p.338 | irs/irs_system.lua:150-156・284-295、activepages/B744.fms.pages.posinit.lua:107-111、B744.fms.pages.lua:1236 |
| NAV-19 | 欠落 | 中 | M | ATT モードが無い。ATT に回しても NAV のまま（位置・GS も有効）。約 30 秒の取り直し、memo、OFF までのラッチ、SET HDG による方位初期化が無い（SET HDG は 2 秒表示するだけ）。NAV デテントも無く NAV↔ATT/ALIGN が自由に動く | FCOM p.1216・p.1227–1228・p.1286、ATA34_2 p.294・p.336・p.354 | irs/irs_system.lua:192-204、B744.fms.pages.lua:1296-1307、B747.30.xt.fltMgmt.lua:168-208 |
| NAV-20 | 欠落 | 中 | M | IRS の電源モデルが無い。更新は `bus_volts[0] > 22` のときだけで、アラインのタイマーは電源と無関係に進む。AC→DC 切替、両方喪失での整列喪失、C IRU の 5 分、>IRS AC/DC、ON BAT 灯とホーンが無い（ON BAT 灯はライトテストでだけ点く）。ATA 24 の bus モデルが前提 | ATA34_2 p.272–275・p.286–287・p.362–363、FCOM p.1217・p.1228・p.1429 | B747.68.xt.fms.lua:1236-1238、irs/irs_system.lua:353-357、B747.90.xt.lighting.lua:1412・1882 |
| NAV-21 | 欠落 | 中 | S | IRS・GPS の EICAS は IRS ALIGN MODE と IRS MOTION 以外出ない。IRS L/C/R、>IRS AC/DC、>ATTITUDE、>HEADING、>TRACK、>GPS、>GPS L/R は表だけで、故障の入口（X-Plane の AHRS/GPS 故障を読む処理）も無い。表の綴りは CENTRE（FCOM は CENTER） | FCOM p.1197–1198・p.1429、ATA34_2 p.288・p.331 | B747.87.xt.warning.lua:111・368-371・411-420・477、irs/irs_system.lua:233-247 |
| NAV-22 | 挙動の誤り | 中 | S | 動きの判定は開始点から 0.0001°（約 11 m）の変位だけで、開始点は 3 台で共有の global。一度 motion になると IRS MOTION のまま止まり、セレクターを回し直すまで再開しない。実機は止まって 30 秒で消え、自動で再開 | ATA34_2 p.350、FCOM p.1227・p.1430 | irs/irs_system.lua:11-12・49-63・160-176・243-260 |
| NAV-23 | バグ | 中 | S | `toDMS` が負の緯度経度で分を誤る（符号付きの値で小数部を取る。W122.31° が W122°41.4 になり、正しくは 18.6）。西経・南緯の LAST POS、REF AIRPORT、GPS POS、POS REF の IRS/GPS 行がすべて誤る。FMC 共通関数なので CDU 担当とも共有 | 数式から（FCOM p.1285 の表示形式） | B747.68.xt.fms.lua:118-139 |
| NAV-24 | 欠落 | 中 | L | 他系統が IRS の有効性を見ていない：AFDS/FCC、yaw damper（最初の IRU のアラインまで INOP）、ブレーキ、失速警報、GPWS、FMC 位置（IRS が 1 台は要る）。IRS 状態を見るのは FMS、ND の地図、TCAS の ND 表示だけ | FCOM p.107・p.1240、ATA34_2 p.281 | B747.90.xt.lighting.lua:1329-1330、B747.61.xt.nd.lua:410-422 |
| NAV-25 | 欠落 | 低 | M | GPS のモデルが無い。`gpsL/gpsR` は常に有効でシムの真位置。電源、初回測位時間、故障が無く、GPS POS は空白にならず UTC は常に GPS。POS REF の GPS NAV INHIBIT と PURGE は文字だけ | ATA34_2 p.378・p.386・p.394・p.396・p.411–412、FCOM p.1225・p.1286 | irs/irs_system.lua:78-83、activepages/B744.fms.pages.posinit.lua:37・70・78・98-100 |
| NAV-26 | 欠落 | 低 | S | IRU 位置にドリフトが無い（乱数のずれが固定）。IRS MONITOR はドリフト率でなく状態文字列。POS REF の IRU の GS はシムの GS | ATA34_2 p.356・p.358 | irs/irs_system.lua:45-52、activepages/B744.fms.pages.maintirsmonitor.lua:1-18 |
| NAV-27 | バグ | 低 | S | ND の更新状態の行：GPS 行はどの IRU もアラインしていないときにだけ「GPS」を入れて消さない（エンジン始動状態で始めると出ない）。全 IRU を OFF にしても IRS 行が残る。IRS (3) から変わったときの 10 秒の緑枠が無い | FCOM p.1150・p.1225 | irs/irs_system.lua:180-190 |
| NAV-28 | 欠落 | 低 | S | HDG REF スイッチはアニメーションだけで真方位がどこにも出ない。高緯度の自動 TRU も無い。表示はパネル変更が要る | ATA34_2 p.302、FCOM p.1242 | B747.01.xt.manipulators.lua:1479-1481 |
| NAV-29 | 欠落 | 低 | S | EFIS の POS スイッチで出る IRU 位置と GPS 位置の記号が無い | FCOM p.1150・p.1225、ATA34_2 p.314・p.392 | B747.60.xt.fltInst02.lua:1204-1209・1365-1370 |
| NAV-30 | バグ | 低 | S | `validate_sethdg` は数字でない入力で Lua エラー（`tonumber(value) >= 0`）。`fmsModules["data"] ~= "---`"` はテーブルと文字列の比較で常に真 | — | B744.fms.pages.lua:720-727・1300 |
| NAV-31 | バグ | 低 | S | 冷えた機体で quick start を使うと status = 2 だけを立てて `irsSystem.align` を通らず、位置入力後に開始点 0 と比べて IRS MOTION で止まる可能性（要シム確認） | — | B747.30.xt.fltMgmt.lua:358-366、irs/irs_system.lua:53-61・163-176 |
| NAV-32 | バグ | 中 | S | ACP で VOR L/R を選ぶと X-Plane の NAV1/NAV2（= ILS L/R）の音声が開く。VOR は NAV3/NAV4。APP L/C/R でも ILS 音声は出ない（MKR だけ）。ダイヤルを回しても前の選択を消さない。VOR の ident が確認できない | ATA34_1 p.348 (34-51)・p.458 (34-31)、FCOM p.1231 | B747.15.xt.com.lua:3632-3668 |
| NAV-33 | バグ | 中 | S | NAV RADIO の VOR 行に識別符号や周波数/コースを入れると `tonumber` が nil になり、DELETE と同じく autotune に戻る。周波数範囲（108.00–117.95、50 kHz）の検査も無い | FCOM p.1304、ATA34_1 p.352 | B744.fms.pages.lua:2512・2555-2563 |
| NAV-34 | バグ | 中 | S | NAV RADIO の RADIAL に `nav_bearing_deg_mag`（局への方位）を出していて radial と 180° 違う。autotune 中は同じ値を OBS に書くので、VOR 偏位は常に TO 側で中立 | FCOM p.1305、ATA34_1 p.368 | B747.68.xt.fms.lua:171、B744.fms.pages.lua:458-459、irs/rnav_system.lua:40-41 |
| NAV-35 | 欠落 | 中 | M | VOR autotune は IRS 位置から最寄りの VOR を 10 s ごとに選ぶだけ（A のみ）。R・P、位置更新に適した局の選択、REF NAV DATA の禁止、2 局手動時の扱い、ヒステリシスが無い。FMC 故障・master 切替とも無関係 | FCOM p.1230・p.1303、ATA34_1 p.350 | irs/rnav_system.lua:24-88、B747.68.xt.fms.lua:1236-1239 |
| NAV-36 | バグ | 低 | S | autotune の「2 番目に近い局」の探索に else 節が無く、1 番目と 2 番目の間の距離の局で更新しない。VOR R が遠い局になるか同調されない | — | irs/rnav_system.lua:65-70・82-86 |
| NAV-37 | 挙動の誤り | 中 | M | ILS autotune は目的地まで 45 NM 以内でだけ同調し、選んだ進入でなく経路点の並びと LOC の向きから ILS を推定する。PARK → 周波数/コース PARK → A の段階が無く、CDU の PARK 表示は T/D までの距離だけで決めていて実際の同調と一致しない | FCOM p.1229・p.1306–1307、ATA34_1 p.540 | B747.70.xt.autopilot.lua:1621-1745、B744.fms.pages.lua:427-452 |
| NAV-38 | 欠落 | 中 | S | ILS の同調禁止（AP の LOC/GS capture、FD だけで capture かつ RA 500 ft 未満、地上の LOC alive・45°・40 kt）と解除（TOGA、AP 解除と両 FD OFF）、離陸後 10 分の autotune 禁止が無い。進入中に NAV RAD 入力や経路変更で NAV1/NAV2 が書き換わる。ILS TUNE INHIBITED - MCP は定義だけ | FCOM p.1229・p.1305・p.1432、ATA34_1 p.440・p.450 | B744.fms.pages.lua:355-410・2549-2553、B747.70.xt.autopilot.lua:1687-1786、B744.notifications.lua:18 |
| NAV-39 | 挙動の誤り | 中 | S | PFD の ILS 表示（approach ref、コース、LOC/GS scale、rising runway）を `ils_dots` で出し入れし、これは目的地まで 50 NM 以内（か LOC 中）でしか 1 にならない。実機は PARK 以外で同調していれば出る（出発時の手動同調も）。APP/LOC は `ils_dots` = 0 だと受け付けず RW/ILS CRS ERROR を出す | FCOM p.987・p.1304・p.1434 | B747.70.xt.autopilot.lua:1635-1637・1792-1797・2397-2398・2430-2431、747-400.acf:84907・84981・86770・87736 |
| NAV-40 | バグ | 低 | S | パネル定義の取り違え：機長 ND の「ILS R 2」の周波数が `nav3_frequency_hz`（VOR L）、ILS 欄の ID/周波数の切替に VOR の ID 有無を使う、機長 ND expanded の GS 指針が `hsi_vdef_dots_copilot`、dataref 名の無い表示条件（`SHOW_GREATER 2.31 [2]`）。両 acf 共通。パネル変更が要る | — | 747-400.acf:116632（カスタム 106343）・116482-116498・110018-110045・99470・100288 |
| NAV-41 | バグ | 中 | S | ACF_DIFF の「ADF 方位針」は実は ND の VOR L/R 指針。カスタム acf の機長 centered map のグループ（Bearing Pointers 2）だけ `nav_relative_bearing_deg[3]/[4]` で、VOR L 指針が VOR R の方位を、VOR R 指針が NAV5（未同調と推定）を指す。VOR L/R は NAV3/NAV4（index 2/3）なので純正の [2]/[3] が正しい。コード（RMI、FMS）は [2]/[3] 前提で、カスタム acf の値には依存しない。ADF 指針は両 acf とも scalar の `adf1/adf2_relative_bearing_deg` に `[10]` を付けて読む（要シム確認） | ACF_DIFF.md §2、X-Plane DataRefs.txt | 747-400_custom.acf:98755・98773、747-400.acf:99595・99613・99631・99649、B747.60.xt.fltInst02.lua:2221・2229 |
| NAV-42 | 欠落 | 中 | M | PFD の LOC/GS 過大偏位警告（scale 琥珀・指針 4 Hz 点滅。GS は RA 100–500 ft で約 5/8 dot 超、LOC は RA 0–500 ft で約 1/4 dot 超が 1 s、LOC capture fail は RA 0–950 ft）が無い。パネルに琥珀の scale も無い | FCOM p.987、ATA34_1 p.468 | なし |
| NAV-43 | 欠落 | 低 | M | autotune 中に ND の VOR 偏位・コース指針・TO/FROM を消す処理、手動 VOR + コースの radial 表示、POS スイッチの radial が無い。`tuningmodes` は文字列でパネルが読めない | ATA34_1 p.362・p.368、FCOM p.1040・p.1145 | B747.68.xt.fms.lua:193、irs/rnav_system.lua:40-41 |
| NAV-44 | 欠落 | 低 | S | ND の地図で同調中の VOR を緑で出すのは STA が ON のときだけ。FCOM は STA に関係なく緑 | FCOM p.1145 | B747.61.xt.nd.lua:293-302 |
| NAV-45 | 欠落 | 低 | S | ADF の ANT/BFO（入力の A/B）と周波数範囲の検査が無い。0.5 kHz は落ちる。小文字欄に FCOM に無い「M」を出す | FCOM p.1304、ATA34_1 p.300・p.312 | B744.fms.pages.lua:492-493・2566-2567 |
| NAV-46 | 欠落 | 低 | M | 受信機ごとの電源が無い（§2.1）。X-Plane の avionics 電源だけで全部動き、「VOR L 故障で MB 表示なし」も無い | ATA34_1 p.283・p.330・p.394・p.435・p.525、FCOM p.987 | なし（xtlua/scripts/Avionics/Avionics.lua:29-38） |
| NAV-47 | 欠落 | 低 | S | ILS ANTENNA と >SNGL SOURCE ILS は表だけ。ILS/G/S/LOC ANTENNA の status も無い。故障モデルと ILS 源の切替が無いので当面は出る条件が無い | FCOM p.1429–1430、ATA34_1 p.478 | B747.87.xt.warning.lua:155・165 |
| NAV-48 | 欠落 | 低 | S | ILS 入力：/コースだけの入力を受け付けない。入れたコースは ILS の選別にしか使わず、DB のコース + 磁差を OBS に書く。中央 ILS が無い | FCOM p.1305・p.1428 | B744.fms.pages.lua:355-410 |
| NAV-49 | 欠落 | 低 | S | FMC 故障時の代替同調（ALTN NAV RADIO）と FMC master による同調元の切替が無い（ALTN ページは雛形）。FMC 故障を作らない限り影響は無い | ATA34_1 p.302・p.354・p.464・p.542、FCOM p.1422・p.1427–1428 | refonly/B744.fms.pages.altnnavradio.lua:1-21 |
| NAV-50 | 欠落 | 低 | S | CDU の display_mode = 1 で出る無線ノブ（`laminar/B747/fms1/radio/*` 15 個）のコマンドがどこにも無い。実機に無い補助機能で、作らないなら INTERFACES の dynamic のまま | INTERFACES.tsv | 747-400_cockpit.obj:24608-24630 |
| NAV-51 | 欠落 | 中 | M | RA が 1 系統：機長側の X-Plane RA を両 PFD と全利用者に使う。L/C/R、電源、RA 旗・NCD、EIU 選択による優先順位、GPWC の比較選択、RADIO ALT L/C/R が無い | ATA34_2 p.70・p.76・p.88–89・p.96・p.99・p.122 | B747.60.xt.fltInst02.lua:112-115・2366-2378、747-400.acf:86916-86922 |
| NAV-52 | バグ | 高 | S | MINS RST が minimums を書き換える：RADIO なら両席の DH を 350 ft、BARO なら両席の baro minimums を 1,000 ft にする。F/O の RST も機長側を押す。CDU の DH RESET も同じコマンド。実機の RST は点滅のリセットだけ | FCOM p.982・p.1036 | B747.60.xt.fltInst02.lua:776-791・949-963、activepages/B744.fms.pages.efisctl.lua:1・50 |
| NAV-53 | 挙動の誤り | 中 | S | DH/RADIO alert は機長側だけで計算し、F/O PFD も同じ `dec_height/display_status` を見る（F/O の設定と無関係に点滅）。比較は生の RA、表示は RA − 8 ft で 8 ft ずれる | FCOM p.981–982、ATA34_2 p.95 | B747.60.xt.fltInst02.lua:2263-2311・2366-2378、747-400.acf:94008-94016 |
| NAV-54 | 挙動の誤り | 低 | S | DH 表示の細部：DH = 0 が非表示（実機は 0 未満で非表示）、点滅 5 s（E&M は 3 s）、arm が「RA > 75 ft」（E&M は DH + 75 ft） | ATA34_2 p.95、FCOM p.981 | 747-400.acf:86841-86843・94008-94010、B747.60.xt.fltInst02.lua:2248-2275 |
| NAV-55 | 欠落 | 高 | L | GPWS mode 1–5 の判定が無い。警報は X-Plane の annunciator と .snd の粗い条件だけ（SINK RATE = VVI < −2,500 fpm かつ RA < 2,500、TOO LOW TERRAIN = VVI < −200・gear down・IAS < 180 kt で普通の最終進入で成立、TOO LOW FLAPS は高度条件なしで終了条件の演算子が `=!`、TOO LOW GEAR = X-Plane の gear 警報音、GLIDE SLOPE = X-Plane の annunciator）。alert→warning の二段、DON'T SINK、mode 3/4 の切替、空地判定が無い | ATA34_2 p.144–178、FCOM p.1574–1577 | fmod/747-400.snd:6052-6095、B747.87.xt.warning.lua（GPWS の処理なし） |
| NAV-56 | バグ | 高 | S | GND PROX パネルの 4 スイッチは `button_switch/position[3]`〜`[6]` を切り替えるだけで、どのロジックも読まない。G/S INHB は alternate 動作（実機は momentary + 30 ft / 1,000 ft で解除されるラッチ） | FCOM p.1537–1538、ATA34_2 p.139・p.174 | B747.01.xt.manipulators.lua:570-584・1579-1582 |
| NAV-57 | 欠落 | 中 | S | CONFIG GR OVRD で CONFIG GEAR を止められない（config warning の担当と調整） | FCOM p.1538、ATA34_2 p.207 | B747.45.xt.fltCtrls.lua:1030-1047 |
| NAV-58 | 欠落 | 高 | S | GND PROX 灯・G/S INHIBIT 灯は常に消灯（TODO のまま）。PULL UP・WINDSHEAR で master WARNING が点かない | FCOM p.1532・p.1538、ATA34_2 p.142 | B747.90.xt.lighting.lua:1059-1064・1721-1724、B747.87.xt.warning.lua:818-833 |
| NAV-59 | 欠落 | 高 | M | mode 7 の論理が無い。PFD WINDSHEAR と siren/voice は X-Plane の `windshear_warning` そのままで、1,500 ft 未満・離陸/進入の限定、最低 5 s、他 GPWS と TCAS の禁止、master WARNING が無い。.snd の終了条件は bus 電圧 < 1 V だけ | ATA34_2 p.186–190、FCOM p.1581–1582 | 747-400.acf:87150-87154、fmod/747-400.snd:6098-6102 |
| NAV-60 | 挙動の誤り | 中 | M | mode 6：callout は生の X-Plane RA の通過で鳴り、「各 1 回、1,000 ft 超でリセット」が無い。400/300/200 は FCOM のどの型にも無い（CDU の設定で切る前提）。.snd は設定 `fmod/options/gpws` を参照しない。BANK ANGLE は 35° 一段で `bus_volts[0] == 28` の等号条件、低高度の規則と 40°/45° の段が無い | FCOM p.1577–1578、ATA34_2 p.180–184 | fmod/747-400.snd:5946-6043、B747.05.xt.simconfig.lua:78・131-145 |
| NAV-61 | バグ | 中 | S | MINIMUMS の FMOD イベントが `laminar/B747/altimeter/ft_adjusted == 1`（Capt 気圧高度 × 0.01 = 1、つまり約 100 ft MSL）で起動する。Lua が計算する `fmod/callouts/DH` は .snd で使われていない | FCOM p.1578 | fmod/747-400.snd:6111-6115・6123-6127、B747.60.xt.fltInst02.lua:2316-2350・2389-2395 |
| NAV-62 | 欠落 | 中 | L | look-ahead と TCF が無い。TERR OVRD は効果なし。ND の TERRAIN/OBSTACLE・TERR OVRD/FAIL/POS/TEST 表示がパネルに無く、警報時の terrain 自動表示も無い。TERR スイッチは外部の Terrain Radar 依存の表示切替だけ | FCOM p.1540–1543・p.1571–1573・p.1585、ATA34_2 p.193–199・p.208–210 | B747.60.xt.fltInst02.lua:1212-1218、B747.61.xt.nd.lua:706-713 |
| NAV-63 | 欠落 | 中 | S | GPWS の EICAS（>ALT CALLOUTS、GND PROX SYS、TERR POS、>TERR OVRD、WINDSHEAR SYS）を誰も立てない。override + 速度条件の GND PROX SYS も無い。表の名前 >WINDSHEAR SYS は FCOM（caret なし）と違う | FCOM p.1538・p.1604–1605 | B747.87.xt.warning.lua:192・367・474-475・484 |
| NAV-64 | バグ | 中 | S | PFD の PULL UP と pull_up の voice が `sim/cockpit/warnings/annunciators/GPWS` に結び付いている。DataRefs.txt ではこれは「GPWS failed」で、PULL UP は `sim/cockpit2/annunciators/GPWS`。誤配線の疑い（要シム確認） | X-Plane DataRefs.txt:968・3884 | 747-400.acf:87129-87133、fmod/747-400.snd:6059-6064、B747.90.xt.lighting.lua:142 |
| NAV-65 | 欠落 | 中 | M | 警報の相互禁止が無い：GPWS warning で TCAS を TA ONLY にしない、windshear で他 GPWS・TCAS・自動表示を止めない、voice の調停が無い（.snd の各イベントが独立に鳴り重なりうる） | FCOM p.1582–1583、ATA34_2 p.17–18・p.130・p.186 | B747.30.xt.fltMgmt.lua:421-433、fmod/747-400.snd:5942-6103 |
| NAV-66 | 挙動の誤り | 中 | S | トランスポンダのモード対応：STBY 以外はすべて X-Plane の mode 2（Mode A、高度報告なし）。ALT ON は 3、TA は 6、TA/RA は 7 にすべき（ALT OFF は 2）。このため X-Plane 内蔵の TCAS も働いていないと推定 | FCOM p.1219・p.1231、ATA34_1 p.632、DataRefs.txt:4692 | B747.30.xt.fltMgmt.lua:216-229 |
| NAV-67 | 挙動の誤り | 低 | S | ATC L/R セレクタは R でコード表示が INOP になる以外何も変わらない。実機は R も同じに動き ATC 1/ATC 2 を表示する（パネル変更が要る） | FCOM p.1219、ATA34_1 p.584・p.590 | B747.30.xt.fltMgmt.lua:234-242、747-400.acf:140892-140913 |
| NAV-68 | 欠落 | 低 | S | TEST 位置（トランスポンダ・TCAS の試験、ND の TCAS TEST、TEST OK/FAIL の音声）が無い。3D ノブに TEST の位置が無い | FCOM p.1219・p.1563、ATA34_2 p.50 | B747.30.xt.fltMgmt.lua:216-229、Cockpit_Pedestal1.obj:40246-40252 |
| NAV-69 | 欠落 | 高 | M | TCAS の TA/RA 判定が無い。X-Plane の threat、tcas_message、vs_bands を一切読まない | ATA34_2 p.37–43、FCOM p.1560–1561 | B747.30.xt.fltMgmt.lua:216-229、B747.61.xt.nd.lua:496-509 |
| NAV-70 | 欠落 | 高 | M | ND の TCAS 表示：全機を白い 1 種類のアイコン（icon 22）で描き、RA/TA/proximate/other の形と色、相対高度、上下矢印、no-bearing が無い。パネルは TFC と TCAS OFF だけで、TRAFFIC、OFFSCALE、TA ONLY、TCAS TEST、TCAS FAIL が無い（パネル変更が要る） | FCOM p.1032・p.1152–1154・p.1534–1535、ATA34_2 p.42–44 | B747.61.xt.nd.lua:274-279・496-509、747-400.acf:106929-106933・116378-116382 |
| NAV-71 | 欠落 | 高 | M | PFD の RA ガイダンス（赤枠の RA pitch region）が無い。パネル変更が要る | FCOM p.1536–1537・p.1562、ATA34_2 p.46 | なし |
| NAV-72 | 欠落 | 高 | S | TCAS の音声が鳴らない。.snd に TCAS のイベントが無く（bank に素材はある）、X-Plane 既定の音声は無音の wav で上書きされている。.snd を変えるかは利用者の判断 | FCOM p.1553・p.1563–1568、ATA34_2 p.49–50 | fmod/747-400.snd、sounds/alert/tcas.wav・te_climb.wav・te_descend.wav |
| NAV-73 | 欠落 | 中 | M | TCAS の高度・機体条件による抑止が無い（INCREASE DESCENT < 1,500 ft、DESCEND < 1,100 ft、全 RA < 1,000 ft で TA ONLY 表示、TA 音声 < 500 ft、48,000 ft で CLIMB 系なし）。X-Plane の TCAS がどこまで持つかは要確認 | FCOM p.1593・p.1600–1601、ATA34_2 p.17–18・p.43 | なし |
| NAV-74 | 欠落 | 中 | S | TFC の自動表示（TA/RA 時、EFIS パネル故障時）と表示モードの制限（VOR CTR、APP CTR、PLN では出さない）が無い。TFC スイッチは単純なトグル | FCOM p.1042・p.1534・p.1560・p.1584 | B747.60.xt.fltInst02.lua:1143-1151・1298-1307・2567-2603 |
| NAV-75 | 挙動の誤り | 低 | S | ND の TCAS OFF が、読み込み後に TA/RA を一度選ぶまで TFC 未選択でも両 ND に出る（`seenRASet`） | FCOM p.1032・p.1154 | B747.60.xt.fltInst02.lua:2566-2590 |
| NAV-76 | 挙動の誤り | 低 | S | >TCAS OFF が地上で IAS < 30 kt なら出る。FCOM は地上〜離陸後 400 ft RA と、進入の 400 ft RA 以下（復行 400 ft まで）で抑止 | FCOM p.1593・p.1601・p.1605 | B747.30.xt.fltMgmt.lua:421-426 |
| NAV-77 | バグ | 低 | S | traffic の高度フィルタ `abs(ele 差) < 2000` の単位は meter（約 6,560 ft）。通常の窓は ±2,700 ft。近い 30 機の制限も無い | ATA34_2 p.24・p.26・p.42、DataRefs.txt:5197 | B747.61.xt.nd.lua:497-498 |
| NAV-78 | 欠落 | 低 | M | 故障系：ATC FAIL 灯、R（応答）表示、>TRANSPONDER L/R、>TCAS SYSTEM、>TCAS RA CAPTAIN/F/O、ND の TCAS FAIL を出す論理が無い（定義だけ） | FCOM p.1219–1220・p.1430・p.1570・p.1605 | B747.87.xt.warning.lua:466-468・478-479、B747.30.xt.fltMgmt.lua:427-433 |
| NAV-79 | 欠落 | 中 | M | WXR パネル（570 型）の論理：LR/T・RR/T、TFR（反対側の表示、両側同時で TEST）、WX と WX+T の自動ゲイン、WX+T で 40 nm 超なら WX。ハンドラは空で、TEST は両側を TEST に固定するだけ、ゲインは 2 を 1 に戻すだけ、LR/T 灯は常時点灯 | FCOM p.1222–1224 | B747.15.xt.com.lua:3022-3041・3602-3607、B747.90.xt.lighting.lua:2125-2126 |
| NAV-80 | 欠落 | 低 | M | WXR の故障・注意表示（WXR FAIL と RT/ANT/CONT/ATT/WEAK、RANGE DISAGREE、RSTR INOP）と、安定化の IRU（IRS source select）・電源との連動が無い。X-Plane のレーダーは IRS や電源と無関係に動く | ATA34_1 p.242・p.246–250・p.263、FCOM p.1155・p.1222 | なし（`EFIS_weather_stab` などを書いていない） |
| NAV-81 | 挙動の誤り | 低 | S | ND の WXR 注記：mode 0 で "RT"（FCOM では R/T 故障の表示）、チルトを "+5.0" の形で出す、ゲイン（CAL/VAR）表示が無い、X-Plane 12.3 未満では空 | FCOM p.1013–1018・p.1155、ATA34_1 p.244 | B747.61.xt.nd.lua:365-395 |

### FMC の航法・性能・誘導（ATA 34-61）（FMC、40 件：高 13・中 22・低 5）

詳細と出典の全文：[notes/ATA-34-61-FMC.md](notes/ATA-34-61-FMC.md)

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

### CDU のページと操作（ATA 34-61）（CDU、42 件：高 6・中 22・低 14）

詳細と出典の全文：[notes/ATA-34-61-CDU.md](notes/ATA-34-61-CDU.md)

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

### 自動操縦・FD・ヨーダンパー・安定板トリム（ATA 22）（AFDS、24 件：高 7・中 12・低 5）

詳細と出典の全文：[notes/ATA-22.md](notes/ATA-22.md)

| ID | 種別 | 重要度 | 規模 | 内容 | 根拠 | 該当コード |
|---|---|---|---|---|---|---|
| AFDS-01 | 挙動の誤り | 高 | L | ロール指令を X-Plane の AP に頼っている。HDG SEL/HOLD は X-Plane の FD roll、LNAV と LOC は目標 heading を X-Plane の HDG SEL に渡す近似、TO/GA roll は X-Plane に lateral mode が無いまま（track 保持なし）。FD roll は 10 サンプルの移動平均で遅れる。ATT は 30° 制限・5° 未満での HDG HOLD 移行が無い。bank limit AUTO は X-Plane の `bank_angle_mode`=4（20° 固定） | ATA22 p.348、p.352、p.358；FCOM p.647、p.663；FCTM p.118 | `hydraulics_override.lua:408-425`、`:805-834`；`autopilot.lua:2633-2640`、`:1362-1382`、`:3454`；`monitor.lua:741-863` |
| AFDS-02 | 挙動の誤り | 高 | M | LOC/APP：両受信機に信号があるだけで LOC 捕捉（遠方・full scale でも捕捉し LNAV を解除）。追従は dots と方位差からの heading。いったん乗った後に両受信機の dots の和が 4 を超えると捕捉を解除し、信号断でも armed に戻る（inertial path なし）。G/S は LOC 捕捉後・1.5 dots 以内（405 の挙動だけ）、arm は 3500 ft RA 未満。APP 押下で即 HDG を course に（実機は LOC 捕捉時）。ILS 自動同調が無いと LOC/APP を arm せず RW/ILS CRS ERROR。LOC の 2 回目で disarm しない | FCOM p.646–647、p.650–652；ATA22 p.290–292、p.342–343、p.356–358 | `monitor.lua:731-776`；`autopilot.lua:2397`、`:2419`、`:2430-2444`、`:2519-2537` |
| AFDS-03 | 挙動の誤り | 高 | M | TO/GA：ピッチ目標が速度に比例する姿勢（Vs で 2°、V2+10 で 12°）で、V2+10〜V2+25／MCP+25 の速度保持、600–1200 fpm の混合、片発目標、windshear 15° が無い。pitch と roll を 1 つのフラグ（TOGA_status）で持つので、ALT 捕捉・FLCH で roll の TO/GA も消え、HDG SEL/HOLD を選んでも FMA は TO/GA のまま。ALT 捕捉の窓に入ると高度に関係なく TO/GA を消す（実機は T/O・G/A からの捕捉は 800 ft RA 以上）。飛行中の TO/GA switch は arm 条件（flap UP 以外か G/S 捕捉）を見ない。離陸後 50–400 ft の roll だけ、接地後 2 s の無効化、F/D 自動表示（>80 kt）が無い | FCOM p.656–657、p.661、p.663–668、p.672–675；ATA22 p.264、p.298、p.336–337、p.344 | `B747.60.xt.fltInst02.lua:3083-3117`；`hydraulics_override.lua:754-763`、`:612-619`；`autopilot.lua:2623`；`B747.40.xt.engines.lua:542-575` |
| AFDS-04 | バグ | 高 | L | autoland：flare/rollout は engaged 3 チャンネルのときだけ動き、LAND 2 では flare せず G/S のまま接地。flare は 50 ft 固定、目標ピッチは事前平均ピッチ＋1–2.5°（1.5 ft/s・GS 送信所 450 ft 先の接地則ではない）。IDLE 表示 40 ft（FCOM 25 ft）、ROLLOUT は 4.5 ft＋pitch。rollout は HSI OBS との heading 差で rudder trim を動かす（LOC 偏差・NWS なし）。runway align・decrab・片発補償が無い。接地後 65 kt で A/P を自動解除し、AUTOPILOT DISC も出さない | FCOM p.670–672；ATA22 p.294–296、p.342、p.346、p.360–362、図 p.295 | `autoland.lua:21`、`:63-84`、`:101-104`、`:148-160`、`:219-221`、`:287-297`、`:354-359` |
| AFDS-05 | 欠落 | 中 | L | multi-channel：APP 押下（1500 ft 超、A/P engaged）で 3 チャンネルの CMD を即 1、1500 ft 未満の LOC+GS 捕捉で即 engage（5 s 遅れ・2° 条件なし）。LAND 3/2 は engaged の数だけで決め、bus isolation・センサ冗長・200 ft 以下の抑止なし。PFD の NO AUTOLAND は 200–1000 ft で LOC も GS も未捕捉のとき（実機は 600 ft までに LAND 3/2 が出ないとき）。first-in-command、GA 後の巡航モード選択・ALT 捕捉での単一化が無い | FCOM p.651、p.653、p.662、p.673；ATA22 p.192–196、p.250、p.288、p.294、p.318–324、p.384–386 | `autopilot.lua:2406-2412`、`:2475-2489`、`:2959-2991` |
| AFDS-06 | 欠落 | 高 | S | A/P engage の既定モード：F/D OFF で CMD を押しても V/S＋HDG HOLD/ATT にならない。モードが何も選ばれていなければ FMA は空白のまま、A/P サーボは何もしない。F/D が地上 TO/GA・LOC/GS 捕捉中の engage の扱いも無い。F/D 側の ATT は 30° 制限と 570 型の区別が無い | FCOM p.639–640、p.663；ATA22 p.266、p.338、p.352 | `autopilot.lua:830-895`；`hydraulics_override.lua:986`、`:1026`；`B747.01.xt.manipulators.lua:1256-1270` |
| AFDS-07 | 挙動の誤り | 高 | S | V/S の同期：V/S 押下で目標を 0 fpm にする。F/D ON の既定 V/S も前回の dial 値。実機は現 V/S（前が ALT か TO/GA で降下中なら 000） | FCOM p.648、p.665；ATA22 p.282、p.344 | `autopilot.lua:786-792`；`B747.01.xt.manipulators.lua:217-223`、`:1261` |
| AFDS-08 | 挙動の誤り | 高 | M | LNAV/VNAV/SPD：LNAV は arm 後 RA 50 ft 超で無条件 engage（2.5 NM・intercept 判定、NOT ON INTERCEPT HEADING なし）。active の LNAV/VNAV を押すと解除する（実機は armed のときだけ disarm）。SPD switch が VNAV を解除する（実機は VNAV/FLCH/TO/GA 中は無効）。TO/GA が VNAV を解除しない（`vnav_state` が残り、VNAV の処理が内部のピッチフラグと目標高度を書き続けるので、ALT 則に落ちて TO/GA が消えうる）。VNAV のサブモード表示は内部フラグからの推定（−500 fpm を VNAV SPD とみなす等）で、speed intervention 中の PTH→SPD 表示が無い | FCOM p.642–645、p.663–665；ATA22 p.270、p.279–280、p.340–341、p.354–355 | `autopilot.lua:2877-2881`、`:1029-1037`、`:1064-1066`、`:582`、`:2761-2787`；`monitor.lua:469-530`；`hydraulics_override.lua:603-619`；`B747.40.xt.engines.lua:542-575` |
| AFDS-09 | 挙動の誤り | 中 | M | 遷移規則と相互 disarm：FLCH・V/S・ALT が G/S 捕捉後も内部フラグを変える（FMA は G/S を優先表示）。LOC 捕捉後・G/S 前に HDG SEL/HOLD へ戻せない。GA の 400 ft 未満でも HDG SEL などを選べる。LOC/APP で LNAV arm が消えない、LNAV/VNAV で APP が消えない、APP で VNAV arm が消えない。A/P を使わず両 F/D を OFF にするとモードが残る | ATA22 p.335、p.343、p.351、p.354–357；FCOM p.651、p.660 | `autopilot.lua:732-827`、`:2596`、`:2700`、`:2724`；`monitor.lua:741-776` |
| AFDS-10 | 挙動の誤り | 中 | L | ピッチ制御則：全モードを「ピッチ目標を少しずつ増減する」則で作り、10 サンプル平均とモード変化後 0.7 s の固定がある。ALT 捕捉は V/S に比例する窓（200–1000 ft）と「誤差×2 fpm」で 0.05 g の捕捉則ではない。ピッチ制限は V/S 系 −3.5〜10°、FLCH −3.5〜15°。G/S は dots を fpm に換算（RA による直線偏差・inertial path なし）。integrator・versine・inner/outer loop の構造が無い | ATA22 p.286、p.330–332、p.344–346 | `hydraulics_override.lua:436-456`、`:463-483`、`:504-803`、`:901-923`；`autopilot.lua:2348` |
| AFDS-11 | 欠落 | 中 | M | 速度保護と自動反転：min/max は Vmc+10 と flap 別の固定値で、全モードの速度目標を切る。FMC の min/max（5 kt 余裕）、FMC 無効時の FCC 計算、保護が VNAV SPD/FLCH/TO/GA だけ、が無い。V/S 既定（speed-through-elevator 中に A/T が SPD）、ALT HOLD 既定（FLCH の 8000 ft 逆行、VNAV の条件）、V/S での 1.3 Vs caution が無い | FCOM p.675；ATA22 p.338、p.344、p.382 | `autopilot.lua:1942-1997` |
| AFDS-12 | バグ | 中 | S | AUTOPILOT caution が出ない：`simDR_autopilot_fail` を定義していない。mode fail の amber 線、FD 故障旗、TEST を出す dataref も無い（表示には custom acf のパネル変更が要る） | FCOM p.653、p.660、p.677；ATA22 p.252、p.369、p.376–383 | `autopilot.lua:3386-3390` |
| AFDS-13 | 欠落 | 中 | M | NO LAND 3／NO AUTOLAND の EICAS：caution [49]・[50] と advisory [248] を誰も立てない。advisory [246] を PFD の NO AUTOLAND 条件で出している。表示前後でのレベル切替、地上の level C、接地後表示が無い | FCOM p.662、p.677；ATA22 p.373–374、p.384–386 | `autopilot.lua:2992-2996`；`B747.87.xt.warning.lua:157-158`、`:432-434` |
| AFDS-14 | 挙動の誤り | 低 | S | AUTOPILOT DISC：型式によらず wailer（570 は siren）、wailer の最低 1 秒なし。disengage bar を上げると warning が消える（実機は disengage switch か再 engage） | FCOM p.640、p.655、p.677；ATA22 p.254、p.380 | `B747.87.xt.warning.lua:806-808`；`autopilot.lua:919-921` |
| AFDS-15 | 欠落 | 中 | M | engage インターロック：CMD は RA > 400 ft と他チャンネル無しだけを見る（実機は地上でも engage でき、250 ft は運用制限）。MCP 有効、DC STBY、センサ有効、SRM の autotrim valid、25° wheel 超過、detent/camout（単一は caution、複数は解除）が無い。pilot の入力は A/P 出力に足されるだけ | ATA22 p.302–322；FCOM p.79–80、p.47 | `autopilot.lua:837`、`:863`、`:884`；`hydraulicsmodel.lua:577-578`、`:600-601` |
| AFDS-16 | 欠落 | 中 | S | AFDS の電源：FCC L/C/R（AC 3/1/2・DC 3/1/2）、MCP（DC 3/2）、警報（DC STBY）を見ない。油圧だけ 1000 psi で見る | ATA22 p.191、p.304 | `autopilot.lua:2480-2499` |
| AFDS-17 | 挙動の誤り | 中 | M | YD の則：bank < 5° は 0.9 s の heading 平均との差、> 5° は sideslip を PID で戻す（5° で則が切り替わる）。地上でも動く（ground op、5 s fade-in/out なし）。出力 ±3.5 を rudder ratio changer で縮める。dutch roll 減衰・turn coordination・modal suppression・±4° と IRU/ADC 数による縮小・overspeed で modal 停止が無い | ATA22 p.50–52、p.83–90、図 p.85・87；FCOM p.949 | `hydraulics_override.lua:426-432`、`:836-899`、`:1048-1103`；`hydraulicsmodel.lua:566-567` |
| AFDS-18 | 挙動の誤り | 低 | S | YD の有効条件：battery switch と IRS 切替位置 NAV（align 中も有効）だけで INOP を決める。電源（FCEPSM/AC standby、AC 1、DC 1/2、battery）、油圧 3/2、power-up test（地上で最大 5 s INOP）、fault と autorecovery、FCC の YD 指令（両 YDM 無効の multi approach）が無い | ATA22 p.60–64、p.83–84、p.88、p.96、p.362；FCOM p.931、p.958 | `B747.45.xt.fltCtrls.lua:714-744`、`:1170-1184`；`B747.90.xt.lighting.lua:1329-1330` |
| AFDS-19 | 挙動の誤り | 中 | M | A/P 中の autotrim：pitch ratio（pilot 入力込み）が窓を越えると `elevator_trim` を 1 フレームだけ動かして 1.2 s 待つ。速度は 220/230 kt で 30/60 s フルレンジ（≈0.5/0.25 unit/s）。RA 500 ft 未満は trim しない。実機は elevator サーボ指令 0.4°（G/S 0.6°）〜0.25°、SRM で 3.5 s 遅れ、単一チャンネル 0.25°/s・0.1°/s、LAND 2 の full rate と trim bias、rollout で禁止、unscheduled/dead trim 監視と autosequence | ATA22 p.144–152、p.165–166、図 p.149 | `hydraulics_override.lua:925-957` |
| AFDS-20 | 欠落 | 中 | M | stab trim（ASTS 側）：手動 trim は X-Plane の pitch_trim を 1 スイッチで直接動かし、速さは acf の `_elev_trim_time`（25 s、`推定`）で速度に依らない。2 スイッチ同時、速度別レート、油圧 2/3（片方で半速）、モード別の限界、column cutout、単一 A/P での trim による解除・multi での無効、cutout switch・ALTN trim、unscheduled trim の自動 shutdown、STAB TRIM 2/3・UNSCHD・GREENBAND、speed trim が無い。ATA 27 担当と重なる | FCOM p.927–929、p.944–946、p.958；ATA22 p.131–166、図 p.159 | `B747.45.xt.fltCtrls.lua:233-289` |
| AFDS-21 | 挙動の誤り | 低 | S | MCP の細部：IAS の初期値 100 kt（実機 200）。MCP 高度の変更を 3 s 後に反映し、その間は古い高度で捕捉する。HDG REF（TRUE）を AFDS が使わない。F/D source 切替が効かない。ALT selector 押しの制約削除・reduced rate descent が無い（FMC 担当と重なる）。TO/GA→FLCH で現速度と選択速度の大きい方にしない | FCOM p.643、p.646、p.649、p.1043；ATA22 p.220、p.236、p.344 | `autopilot.lua:3434`、`:1426-1479`、`:660-716`；`B747.01.xt.manipulators.lua:1479-1481` |
| AFDS-22 | 挙動の誤り | 中 | S | acf 依存（ACF_DIFF §3.3）：ロール FD を X-Plane が計算するため、`_ott_psi_*`・`_ott_phi_*`・`_ott_roll_rate`・`_auto_roll_axis_defaults_free` の違いで HDG SEL/HOLD・LNAV・LOC・TO/GA の bank の取り方が 2 つの acf で変わる（`推定`）。ほかの §3.3 の項目はコードが使っていない（§6.2）。AFDS-01 で解消する | ACF_DIFF §3.3 | `hydraulicsmodel.lua:181`（`flight_director_roll_deg` の読み込み）；`hydraulics_override.lua:422-423` |
| AFDS-23 | 欠落 | 低 | S | ILS/RA の inhibit：LOC/GS 捕捉後も ILS 自動同調が 2 s ごとに周波数とコースを書く。ILS TUNE INHIBIT、RA TEST INHIBIT、アンテナ切替の監視が無い（ATA 34 担当との境界） | ATA22 p.212–216 | `autopilot.lua:1621-1800` |
| AFDS-24 | 挙動の誤り | 低 | S | VNAV 上昇中に遷移高度で自動的に両高度計を STD にする。資料に無い機能（FMC・EFIS 担当と重なる可能性） | FCOM p.645、p.664–665（VNAV の機能に記載なし） | `B747.70.xt.autopilot.vnavspd.lua:426-433` |

### オートスロットルと推力管理（ATHR、20 件：高 8・中 8・低 4）

詳細と出典の全文：[notes/ATA-22-AT.md](notes/ATA-22-AT.md)

| ID | 種別 | 重要度 | 規模 | 内容 | 根拠 | 該当コード |
|---|---|---|---|---|---|---|
| ATHR-01 | 挙動の誤り | 高 | L | 推力制限モードが `flightPhase`（0→TO、1→CLB、2 以上→CRZ）だけから作られ、`flightPhase` は V/S ホイール、FLCH・SPD・ALT 押し、monitor など多数が書く。TO→CLB は THR REDUCTION（フラップ 5 / 入力高度、VNAV 条件）でなく、THR REF 中に RA 1,000 ft 未満なら TO、それ以上で MCP 高度が 1,000 ft 以上上なら CLB という固定則。中間の level-off で CRZ になる。T/C の CLB/CRZ 選択（PERF FACTORS）が無い。GA は「flightPhase≥2・フラップ>0・RA<1,500 ft」か TO/GA 押しだけで、G/S 捕捉では入らず、RA 1,500 ft で自動終了して TO/CLB/CRZ に落ちる。CON が無い（E/O VREF+98、ENG OUT、THR スイッチ）。THR スイッチの推力制限機能が無い | FCOM p.642、p.667、p.672、p.674、p.1266、p.1272–1273、p.1341、p.1350、ATA34_2 p.536、p.662–665、FMSPG p.105、p.111、p.267 | EEC:683-719、MON:393-414、MON:642-644、AP:1384-1414、AP:1883-1886、AP:2759 |
| ATHR-02 | バグ | 中 | S | 空中の THRUST LIM: <GA/<CON/<CRZ の LSK が TO/TO1/TO2 の setDref に繋がり、押すと toderate と clbderate を書き換える（GA→CLB、CON→CLB 1、CRZ→CLB 2 相当）。見出しにモードと limit が無い。<SEL> は clbderate で付く。R1 が入力を受け付ける。地上の見出しは `TO-1` 形式で D も出ない。derate % は固定表示 10/20 | FCOM p.1313–1316、p.1338–1340、ATA34_2 p.535–537 | FMS/activepages/B744.fms.pages.thrustlim.lua:13-15・50-70・77・83-85・165-173、FMS/B744.fms.pages.lua:2543-2548 |
| ATHR-03 | 欠落 | 高 | M | assumed temperature が推力に効かない。SEL 入力は `thrustsel` に文字列で保存されるだけで、EEC の使用箇所はコメントアウト。D-TO 表示、25% 上限、0–99°C/°F の検証、TAKEOFF SPEEDS DELETED、TO/GA 後の入力禁止、減少率による CLB 1/2 自動選択が無い。EICAS に assumed temp の表示要素が無い | FCOM p.831、p.1273、p.1314、ATA34_2 p.535、p.651–652、FMSPG p.101、p.103 | FMS/activepages/B744.fms.pages.thrustlim.lua:38・165、FMS/B747.68.xt.fms.lua:635、EPW:118-129、EGE:130-136、EEC:583-644、ACF:119366-119378 |
| ATHR-04 | 挙動の誤り | 高 | M | CLB の reference が rating でなく「固定の設計上昇率（PW4056 で 2,750 fpm など）に必要な推力」（max climb で頭打ち）。VNAV/FLCH の上昇で CLB 定格より少ない推力になる。CRZ の reference は M.85 巡航に必要な EPR の表（P85M）で、max cruise rating ではない。GA は近似式、GE は TO の N1 を流用。PI の Max Climb / GA / Max Continuous 表を使っていない | FCOM p.1271–1272、ATA34_2 p.642–643、PI p.262–263、p.283、p.359–360、p.379 | EPW:160-302・603-666、EGE:165-310・551-595、ERR:794-850、EEC:646-680 |
| ATHR-05 | 挙動の誤り | 低 | S | CLB 1/2 の消去を全型式 10,000→15,000 ft（405・570 の値）で行い、derate を「必要推力」に掛けている。109（PW 旅客）は 30,000/35,000 ft。TO 1/TO 2 は固定 10%/20%（FCOM の例は PW −8/−20%、GE −5/−15%、operator 指定）。PERF FACTORS は固定表示で機能しない | FCOM p.1272–1273、p.1313–1314、ATA34_2 p.678 | EEC:624-628・654-658、FMS/activepages/B744.fms.pages.maintperffactor.lua:2-14 |
| ATHR-06 | 欠落 | 高 | M | A/T の THR モード（FMA 値 4）を一度も出さない（パネルには画像がある）。FLCH の上昇・降下は THR REF 表示で、125 s の V/S 則が無く常に CLB reference まで推力を出す。FLCH 降下は THR REF のまま「target 0.9 EPR / N1 25%」の仮値で idle にする。GA 1 回目の THR（2000 fpm）が無く、即 THR REF で full GA。2 回目は効果なし。early descent の THR→HOLD も無い | FCOM p.657、p.662、p.673、p.1260、ATA34_2 p.646–647、p.654、p.670、p.674–675、ATA22 p.284 | AP:756・2840-2849、EPW:695-700、EGE:618-623、ERR:888-893、ENG:552-571 |
| ATHR-07 | 挙動の誤り | 高 | M | HOLD/IDLE の論理: VNAV 降下は lever が 0.1 未満になるまで SPD、その後は IDLE のまま HOLD にならない（monitor が lever <0.02 で A/T を非作動にして代用）。IDLE 中も servo が lever を idle に保ち、速度不足では FMA は IDLE のまま推力を足す（実機は SPD へ）。FLCH 降下の HOLD も無い | FCOM p.662、p.1259、ATA34_2 p.644・654、p.666–667、p.670 | AP:2858-2875、MON:337-350、EEC:942-946・974-976 |
| ATHR-08 | 挙動の誤り | 高 | M | TO/GA: 地上でフラップ UP・50 kt 以上・limit TO 以外でも作動する（50 kt 以上なら 400 ft まで不可が正）。65 kt の HOLD 後、RA 50 ft で TO/GA pitch のまま THR REF に戻る（VNAV か他モードまで HOLD が正）。TO/GA pitch・GA の level-off で monitor が自動的に SPD にする。離陸直後の TO/GA は「derate を外した TO」でなく GA limit になる。空中では TO/GA arm 条件（フラップ UP 以外か G/S）を見ない。touch-and-go の TO/GA は 65 kt 以上だと HOLD。manipulators の wrap は ARM OFF でも A/T active を立てる | FCOM p.656–657、p.667、p.671、p.673、FCTM p.94、p.124、ATA34_2 p.660–661、p.674 | ENG:542-578、MAN:438-444・500、AP:2840-2862、MON:634-666 |
| ATHR-09 | 欠落 | 高 | M | pilot override が無い。A/T 作動中（FMA>1）はハードウェア軸も 3D lever の入力も無視され、lever は A/T 指令のみ。FLCH の 8° override → HOLD、離すと指令位置へ戻る動きが無い | FCOM p.666 (4.20.8)、ATA34_2 p.648 | EEC:1105-1120・1134-1141 |
| ATHR-10 | 挙動の誤り | 中 | M | servo が速度制限付きの積分器になっていない。THR REF は誤差比例の積分で、時定数は PW/RR で約 17 s、GE で約 4 s（コードの係数からの推定）。PW/RR では 65 kt の HOLD までに TO 推力に届かない恐れ（旧フォークは 30–40 s を観察）。IDLE・flare retard は目標を即 0 にし、lever は 1–2 s で全行程（3D 換算 25–50°/s）。実機は最大 10°/s、flare 5°/s。増分がフレーム単位でフレームレートに依存 | ATA34_2 p.472、p.490、p.648、p.690、FMSPG p.110 (3.3-1)、OLD_FORK_NOTES.md §3 | EEC:878-927・929-1006 |
| ATHR-11 | 欠落 | 中 | M | SPD で reference limit を守らない（lever 1.0 = max 線まで出る）。THR REF に limit speed（Vmo/Mmo、placard）制御が無い。速度保護は MCP 目標の固定クランプ（Vmc+10、フラップ placard −5 kt の固定値、gear placard なし）で、V/S でも効く（実機は V/S で保護なし） | FCOM p.663、p.675、p.935 (9.10.9)、ATA34_2 p.646–648、p.668、p.672 | EEC:878-927・942-978、AP:1942-1972 |
| ATHR-12 | 挙動の誤り | 中 | S | flare retard: SPD なら autoland でなくても RA 25 ft で IDLE・lever 0（LAND 3/2 の要求が条件）。autoland は 40 ft で IDLE。接地で FMA を空白にする（reverse での解除まで IDLE が正） | FCOM p.671、ATA34_2 p.648、ATA22 p.294 | EEC:909-911、ALND:204-206・216-221・233 |
| ATHR-13 | バグ | 高 | S | reverse で A/T を落とすとき `autothrottle_fail=1` にするため、reverse を使った着陸のたびに >AUTOTHROT DISC（caution）が出て、disconnect・ARM 操作か TO/GA まで残る。reverse による解除ではメッセージと音を出さないのが正 | FCOM p.677、ATA34_2 p.644 | ENG:479-492・779-788、AP:3393-3398 |
| ATHR-14 | 挙動の誤り | 中 | S | disconnect スイッチが `autothrottle_fail` を反転するだけ。A/T 非作動時に押してもメッセージが出る。fail=1 の間はモードスイッチで再作動できない（2 回目か ARM の入れ直しが要る）。実機は 1 回目で解除（engage 中だった場合だけメッセージ）、A/T は ARM のまま、再 engage でもメッセージ reset | FCOM p.657、p.666、ATA34_2 p.492、p.645、LH3460 p.60 | AP:541-544・969-987、MAN:1437-1477 |
| ATHR-15 | 欠落 | 中 | M | engage interlock の不足: 電源（F/O XFR の servo、APU stby/F/O XFR の FMC、DC bus 1・2）、FMC 故障・master 切替による解除、servo monitor が無い。EEC ALTN は 1 台で解除するが、再作動の規則（PW は全 NORM、GE は全 ALTN）が無く、fail を戻せば 1–3 台 ALTN でも servo が動く。運転中エンジン数は表示 N1 >15% で判定 | ATA34_2 p.450、p.452、p.645、FCOM p.666、p.800、p.877、p.1215、p.1275 | AP:541-544、MON:597-616、EEC:1023-1030・1105、plugins/xtlua_keysystems/scripts/B747.60.xt.fltInst/B747.60.xt.fltInst02.lua:660-664 |
| ATHR-16 | 挙動の誤り | 中 | S | SPD スイッチが VNAV・FLCH 中でも効き、VNAV/FLCH を取り消して V/S にする（FCOM はこれらの pitch で無効）。400 ft の下限が無い。THR スイッチは 400 ft 未満でも A/T active を落とす。ALT・G/S では monitor が A/T を自動で作動させる | FCOM p.641–642、ATA34_2 p.654、p.668 | AP:553-609、MON:634-666 |
| ATHR-17 | 挙動の誤り | 中 | S | EICAS: reference の数字に target bug を出すため、降下の THR REF/IDLE では 0.90（GE は 25.0）と表示。max EPR/N1 線を地上で TO 1/2 の derate 分下げる（どの derate でも下げないのが正）。マゼンタは FLCH でも立つ一方、A/T OFF の cruise target と VNAV idle 降下・anti-ice のマゼンタは無い（パネルが FMA=5 を条件にしており acf 変更が要る） | FCOM p.833–834、p.215、ATA34_2 p.642、p.651–653、LH3460 p.96 | EPW:589-593・695-700、EGE:535-539・618-623、EEC:1052-1063、ACF:119420-119560・120056-120116 |
| ATHR-18 | 欠落 | 低 | M | engine trim equalization（uptrim/downtrim、5%/10% authority、A/T ARM で有効）が無い。EEC は各エンジンを TRA に個別 PID で合わせているだけ | ATA34_2 p.474、p.638、p.640 | なし |
| ATHR-19 | 欠落 | 低 | S | CDU の THRUST REQUIRED を出す処理が無い。DRAG REQUIRED は A/T の状態を見ない | FCOM p.1259、p.1431、p.1434 | AP:3400-3413、FMS/B744.notifications.lua:47 |
| ATHR-20 | 挙動の誤り | 低 | S | SPD の制御則が増減ほぼ対称（実機は増は速く減は遅い、Vmo/Mmo 付近は強く）。TEST モード表示なし | FCTM p.43、p.301、ATA34_2 p.654 | EEC:855-927 |

### 通信（ATA 23）（COM、16 件：高 1・中 9・低 6）

詳細と出典の全文：[notes/ATA-23.md](notes/ATA-23.md)

| ID | 種別 | 重要度 | 規模 | 内容 | 根拠 | 該当コード |
|---|---|---|---|---|---|---|
| COM-01 | 挙動の誤り | 高 | S | VHF の電源が RTP の表示で決まる。どの RTP（OFF でないもの）も VHF L を表示していなければ毎フレーム `com1_power=0`（VHF R も同じ）。左 RTP で VHF R や HF を選ぶ、または OFF にすると VHF L が受信も送信もできなくなる（X-Plane の ATC と AutoATC の `com_power` も）。実機は無線機と RTP は独立 | FCOM p.686, p.714 | 3369-3427（3423-3426）, 413-423 |
| COM-02 | 挙動の誤り | 中 | M | ACP 3 枚が連動する。VHF L/R の送信選択を押すと他 2 枚も同じ選択になる。VOR/ADF・APP 選択器と VHF L/R・VOR/ADF・APP/MKR の音量ノブは 3 枚で同じ値。X-Plane の受信は 3 枚の OR、送信は VHF L 優先で、どの席も VHF L/R でなければ定義外の 9 を書く。SPKR は効果なし。実機は席ごとに独立で、XP12 の pilot/copilot の audio panel で写せる | FCOM p.683, p.713; ATA23 p.24, p.30–31, p.54; DataRefs.txt 4695, 4723–4750 | 892-924, 1178-1220, 1222-1297, 1496-1601, 1610-1642, 1884-1926, 2311-2343, 2585-2627, 3551-3564, 3608-3668 |
| COM-03 | 欠落 | 中 | M | VHF C と HF L/R の無線機が無い。周波数を持たず、表示は INOP（99）か ACARS（98）の絵だけ。VHF C のデータ⇔音声の切替（transfer で ACARS ⇔ 周波数、範囲外選択で ACARS に戻す）、VHF DATA OFF の条件、HF の AM/USB・感度・antenna tuning・同時送信の禁止が無い。98 の絵は中央 RTP の ACTIVE 窓にしか無く、左右 RTP では空白、中央でも HF を選ぶと ACARS と出る | FCOM p.686–688, p.714–716, p.776 | 3369-3422, 462-470; init 283-291; `747-400_custom.acf:130446-130488` |
| COM-04 | バグ | 中 | S | AM スイッチが無線機の選択として扱われる。押すとその RTP の VHF/HF 選択が外れて AM 灯が点き、表示は INOP/ACARS、左右 RTP では offside 灯が点く。実機は選択中の HF の AM/USB 切替 | FCOM p.686 (item 6), p.688 (item 12) | 450-454, 611-615, 769-773, 3433-3494 |
| COM-05 | 欠落 | 中 | M | CALL 灯とチャイムが動かない。`ap_*/*/call_status`・`call_pnl/*/call_status` を書く処理が無く、lights test 以外では点かない。呼出元（SELCAL、ACARS の音声要求、CAB、地上員の FLT、SAT）、解除（送信選択・PTT・INT・30/60 秒）、全 ACP 共通の点灯、チャイムと離着陸の抑止が無い | FCOM p.684, p.717, p.719–722, p.1588–1601; ATA23 p.31, p.68, p.112, p.118, p.121; ATA31 p.160, p.218 | init 106-115, 163-172, 220-229, 266-270; `B747.90.xt.lighting.lua:1504-1594, 1974-2060` |
| COM-06 | 欠落 | 中 | M | PTT（R/T–INT）に機能が無い。位置のアニメーションだけで、X-Plane の送信（`contact_atc_ptt`）、flight interphone、CALL の解除、スピーカーの減衰、stuck mic（地上 35 秒）、PILOT RESPONSE への操作入力が無い。代わりに AutoATC provider が左 PTT の位置を読み、左 ACP の送信選択を VHF L/R と FLT の間で書き換える（実機は INT を押しても送信選択は変わらない）。左 PTT は押している間、毎フレーム Log.txt に出力する | FCOM p.683–684, p.715, p.1559; ATA23 p.31, p.60, p.112 | 1145-1176（1149, 1164）, 1864-1882, 2565-2583; `acars/autoatcProvider.lua:316-358` |
| COM-07 | 挙動の誤り | 中 | S | 航法受信の音声経路。VOR L/R を X-Plane の NAV1/NAV2 に送るが、シムは VOR L/R を NAV3/NAV4 に同調している（NAV1/2 は ILS と推定）。選択器を回しても前の受信が切れない（`audio_selection_nav1=1` のまま adf1 も 1）。APP L/C/R（ILS）の音声経路が無い（MKR だけ）。V/B/R は位置だけ。DME の音声なし。VOR/ADF の音量は 4 受信機に同じ値 | ATA23 p.31–32, p.71–72; FCOM p.684–685; DataRefs.txt 4701–4722 | 3632-3668, 1194-1204, 1496-1555; `B744.fms.pages.lua:2562-2563`; `irs/rnav_system.lua:76-85` |
| COM-08 | 欠落 | 中 | M | 電源に依存しない。ACP・RTP・無線機・interphone・SELCAL がどのバスも見ない（X-Plane が acf の bus 1/3 で COM1/2 を止めるだけ、灯は bus 1/3 の電圧、RTP 表示は `BUS_SRC 4`）。実機はバッテリーだけでは VHF L・左 RTP・機長 interphone（main battery bus）と F/O・service interphone・PA（APU battery bus）だけ、HF は transfer bus。ELEC の作り直し（ELEC-02）と一緒に直す。acf の bus bit に依存している（両 acf 同じ） | FCOM p.800, p.819–820; ATA23 p.18, p.90, p.108 | 3369-3427（判定なし）; `B747.90.xt.lighting.lua:1691-1694`; `747-400_custom.acf:72998-72999` |
| COM-09 | 挙動の誤り | 中 | S | 通信の EICAS。>DATALINK AVAIL/LOST/SYS（advisory 55–57）を立てる処理が無い。FCOM に無い memo「ACARS NO COMM」（memo 40）が、ACARS provider（AutoATC）がオフラインで中央 RTP が OFF でない間ずっと出る（AutoATC を使わない環境では常時）。「ACARS CALL」と「ACARS VOICE」が同じ index 41、PRINTER MESSAGE が 28 と 42 に重複。ATC MESSAGE（405/570）と SATCOM CALL が無い。VHF DATA OFF（memo 37）を立てる処理が無い | FCOM p.725, p.775–776 | `B747.87.xt.warning.lua:241-243, 493-538`; `B747.68.xt.fms.lua:1240-1265` |
| COM-10 | 挙動の誤り | 低 | S | ACARS の可否を中央 RTP の OFF で決めている（OFF なら CDU MENU の `<ACARS` と memo 40 を消す）。ACARS は電源と VHF C/SATCOM で決まり、RTP の OFF は無線機を止めない（推定）。ACARS が機体の電源に依存しない | FCOM p.686, p.715–716 | `B744.fms.pages.lua:38`; `B747.68.xt.fms.lua:1240-1265` |
| COM-11 | バグ | 中 | S | 右 RTP の内側（kHz）ノブを上方向に保持すると周波数が下がる（phase 1 で `stby_com1/2_fine_dn` を呼ぶ） | FCOM p.687 | 849-860（853, 855） |
| COM-12 | バグ | 低 | S | RTP の OFF の扱い。中央 RTP の kHz up と、右 RTP の MHz down の保持は OFF でも同調する。OFF で offside を再計算しない（405 の「他の RTP が OFF」も無い）。OFF 中の表示 90 はパネルに絵が無く空白 | FCOM p.686, p.714 | 683-701, 827-835, 413-423, 575-585, 733-743, 3463-3494 |
| COM-13 | 挙動の誤り | 低 | S | 受信の自動 ON と 121.5。送信選択で受信の手動状態（緑灯）を 1 にし、送信選択を外しても残る。FCOM の緑灯は手動選択だけを示す。121.5 MHz の自動受信（全席、OFF 不可）が無い | FCOM p.683, p.685; ATA23 p.26, p.30–31, p.64 | 892-994, 996-1114（C・R も同型） |
| COM-14 | バグ | 低 | S | コピーの誤りと初期化。中央 ACP の VOR/ADF 音量が左 ACP の受信状態を見る（2209, 2238, 2251）。右 ACP の VOR/ADF 音量が中央に反映されない（2908, 2937 が自分への代入）。連動しているのに初期値が不一致（VHF L：左 180、中央・右 30）、COM2 の X-Plane 音量は設定しない。flight start のたびに全 ACP/RTP を初期化し、3 枚とも VHF L の MIC を点ける（実機は電源投入時に送信選択なし） | ATA23 p.30 | 2209, 2238, 2251, 2908, 2937, 3694-3764, 3795-3814, 3843-3848 |
| COM-15 | 欠落 | 低 | M | interphone・PA・呼出パネルの機能が無い。FLT・CAB・PA・SAT は状態だけ。SERV INTERPHONE と OBS AUDIO SYSTEM のスイッチは位置（`toggle_switch_position[14]/[15]`）を誰も読まない。CAB の 2 回押しの priority call、PCP（109）、地上員の呼出（P1/GND とホーン）、PA の sidetone と PA IN USE が無い | FCOM p.692–698, p.719–723; ATA23 p.36, p.74, p.90, p.214, p.308, p.326 | `B747.01.xt.manipulators.lua:1121-1143`; 926-954, 1032-1066 |
| COM-16 | 欠落（obj） | 低 | S | 3D の操作部。F/O の ACP の HF R と SAT R の音量ノブが両方向とも `vol_up`（下げられない。INTERFACES.tsv に `ap_R/hf_R_audio/vol_dn` と `sat_R_audio/vol_dn` が無いのはこのため）。左 RTP の offside 灯（`brightness_ratio[126]`）を obj が使っていない。CALL パネル（灯 246–250）に押しボタンが無い。obj の変更は範囲外（要承認） | FCOM p.685–686, p.697–698 | `747-400_cockpit.obj:23229, 23235`; `Cockpit_Pedestal1.obj` |

### 照明（ATA 33）（LIGHT、16 件：高 2・中 6・低 8）

詳細と出典の全文：[notes/ATA-33.md](notes/ATA-33.md)

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

### ドア（ATA 52）（DOOR、8 件：高 0・中 2・低 6）

詳細と出典の全文：[notes/ATA-52.md](notes/ATA-52.md)

| ID | 種別 | 重要度 | 規模 | 内容 | 根拠 | 該当コード |
|---|---|---|---|---|---|---|
| DOOR-01 | 欠落 | 中 | M | entry door は L1 だけ、upper deck door は L だけ。残りの entry door 9 枚と UD R には状態もメッセージも synoptic の箱も無い（X-Plane のドアも割り当てていない） | FCOM p.466・527・545–546 | SAF:217-231、WRN:253-263 |
| DOOR-02 | 欠落 | 中 | M | cargo door（FWD/AFT/BULK）と E/E door（MAIN/CTR）が無い。DOOR FWD/AFT CARGO（caution・beeper）、DOOR BULK CARGO、DOOR ELEC MAIN/CTR が出ない。cargo door の handle・GHB の interlock と開閉の流れも無い | FCOM p.537・545、ATA38_51_52_56 p.474・488–492・506・518–520・530–532 | WRN:119-120・249-251（定義のみ） |
| DOOR-03 | 挙動の誤り | 低 | S | 表示を X-Plane の開度で判定している（メッセージは > 0.01、synoptic は > 0.05 で食い違う）。実機はハンドルで latch が外れた時点で「開」、latch roller がかかるまで「開」。開け始めの最初の数 % では表示が出ず、メッセージと箱の出るタイミングもずれる | ATA38_51_52_56 p.242・254・298 | SAF:219・227、ACF:137456-137480 |
| DOOR-04 | 欠落 | 低 | S | まとめのメッセージ（DOORS ENTRY L/R、DOORS UPR DECK、DOORS ELEC）と個別の抑止が無い | FCOM p.546、ATA38_51_52_56 p.304・392・532 | WRN:265-268（定義のみ） |
| DOOR-05 | 欠落 | 低 | S | upper deck door の flight lock と DOOR U/D FLT LK（caution・beeper）が無い。警報表では同じ文言が caution[14] と advisory[78] の 2 か所にあり、advisory は誤り（E&M は caution と status） | FCOM p.534・546、ATA38_51_52_56 p.342–346・390・392 | WRN:122・264 |
| DOOR-06 | 欠落 | 低 | M | flight deck door の access system（ロック、LOCK FAIL、AUTO UNLK、lock selector、keypad、access system スイッチ、電源喪失と減圧での解錠）が無い。door 9 は X-Plane のドアを開閉するだけで、lock panel の操作子も無い。Before Start の「LOCK FAIL 消灯を確認」ができない | FCOM p.118・161・469–472・528–529 | MAN:2055、CKPT:22083・24383 |
| DOOR-07 | 欠落 | 低 | M | DRS synoptic の箱が L1 と UD L の 2 つだけ（両 acf 同じ）。ほかのドアの箱、latched との区別にはカスタム acf のパネル計器の追加が要る（承認事項）。背景の名称は 109 の配置で揃っている | FCOM p.466 | ACF:137429-137497、ACFC:127140-127208 |
| DOOR-08 | 挙動の誤り | 低 | S | FMC の DOORS ページや X-Plane のコマンドで、飛行中でも L1・UD L を開けられる（与圧中の plug door は開かず、UD door は flight lock で止まる）。開けても与圧に影響しない（ATA 21 と調整。X-Plane の与圧が反応するかは未確認） | FCOM p.529・534、ATA38_51_52_56 p.342 | FMSD:20-41 |

