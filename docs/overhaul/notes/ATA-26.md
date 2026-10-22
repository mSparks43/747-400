# ATA 26 火災防護（Fire Protection）実装ノート

GAP ID 接頭辞：`FIRE`。2026-10-23 調査。コード・acf・音・3D は変更していない。

## 1. 概要

- 対象：エンジンの火災・過熱の検知と消火、APU の火災検知と消火（自動停止、地上の自動放出、脚格納部のホーン）、下部貨物室の煙検知と消火（ARM/DISCH と時間差放出）、主脚格納部の火災検知、主翼前縁・ストラットの過熱検知（BLD DUCT LEAK）、化粧室・クルーレストの煙検知、FIRE/OVHT TEST、火災関係の EICAS メッセージと火災ベル（MAWEA）。主デッキ貨物室（combi・貨物機）は要点だけ。
- 使った資料（ページは PDF ページ）：
  - ATA26_28 p.3–324：26-00 p.3–16、26-11 p.17–58、26-21 p.59–84、26-15 p.85–112、26-22 p.113–136、26-16 p.137–166、26-23 p.167–200、26-14（主デッキ）p.201–232、26-24 p.233–266、26-17 p.267–276、26-18 p.277–288、26-13 p.289–298、26-27 p.299–304、26-12 p.305–310、26-14（OCR）p.311–324。図は p.13（master fire warning）、27・39（エンジン過熱・火災の検知回路）、51（エンジン消火スイッチ回路）、111（APU fire shutdown module）、125（APU 自動放出回路）、145（venturi 圧力スイッチ）、185・187（貨物室の放出回路）、189（ARM の機能）、193（貨物 DISCH 表示回路）、273（車輪格納部）、285（主翼前縁）を描画して読んだ。
  - FCOM 8.10 p.905–912、8.20 p.913–920、8.30 p.921–924、SP.8 p.187–188（図は p.905・907・910・921・922 を描画）。補助に FCOM 1.30 p.465、2.10 p.559、2.20 p.589、2.40 p.613、2.50 p.619、6.20 p.820、7.10 p.840、7.13 p.860、7.20 p.886、7.30 p.895–897、7.40 p.899・902、13.20 p.1490、15.20 p.1550・1586・1588・1589・1595（p.1589 は描画）、NP.21 p.101・105・117、ATA31 p.159・173（aural）、LH24 p.108・144（GCR）、FCTM p.284・304。
- 型式：FCOM の機番 109（旅客・PW）を基準にし、405（改造貨物・PW）・570（貨物・GE）との差は注記する（ATA-28 と同じ扱い）。ATA26_28 は航空会社の訓練書（Config: ALL）で、下部貨物室のボトルは A–D の 4 本（FCOM 109 と同じ）。エンジン型式による検知・消火の違いは資料に記載なし（RR は資料が無い）。
- 乗員に見える挙動は FCOM、内部の論理（AFOLTS、リレー、時間）は ATA26_28 に従った。食い違いは §9 にまとめた。
- コード：`plugins/xtlua/scripts/B747.35.xt.fire/B747.35.xt.fire.lua`（653 行）、`plugins/xtlua/init/scripts/B747.35.fire/B747.35.fire.lua`（99 行）。関係するもの：`B747.87.xt.warning.lua`（CAS 表、master warning、ベル）、`B747.90.xt.lighting.lua`（BTL DISCH・貨物・スクイブの灯）、`B747.01.xt.manipulators.lua`（貨物 ARM/DISCH）、`B747.40.xt.engines.lua`（燃料弁、>ENG SHUTDOWN）、`B747.55.xt.air.lua`（抽気弁）、`B747.25.xt.fuel.lua`（spar valve）、`B747.03.xt.electrical.lua`（APU の起動・停止）、`fmod/747-400.snd`（ベル）、3D（`747-400_cockpit.obj` の manipulator、`Cockpit_OH1.obj`・`Cockpit_TQ.obj` の灯）。
- ACF_DIFF：火災系統に関係する差分は無い。`acf/_warn_fire_EQ 1` と `acf/_ann_wav_file/61–68 Firebell.wav` は両 acf で同じ（wav ファイルは機体フォルダに無い）。コードはこれらを読まない。

## 2. 構成

### 2.1 検知器

| 区画 | 検知器 | 論理 | 作動 | 出力 | 出典 |
|---|---|---|---|---|---|
| エンジン火災（1–4） | 気体封入式の双ループ検知器 3 組（上に 1、側面と下に 2）。各素子に警報（常開）と健全性（常閉）の圧力スイッチ | 通常は loop A AND B。片ループ故障で残りのループだけで判定。両方故障で >DET FIRE/OHT n | 全長平均 399°C、局所（30 cm）593°C | スイッチの赤灯と解錠ソレノイド、FUEL CONTROL の赤灯、MAWEA（ベル・master WARNING）、EICAS | ATA26_28 p.18–20、p.37、p.44；FCOM p.914 (8.20.2) |
| エンジン過熱（1–4） | 双ループ 1 組（エンジン上部） | 同上 | 平均 288°C、局所 483°C | MAWEA（beeper・master CAUTION）、EICAS | ATA26_28 p.20、p.25、p.32 |
| APU | 双ループ 2 組（上部、左扉の内側） | **常に A OR B**。片ループ故障は残りで検知 | 平均 210°C、局所 308°C | 上記に加え APU 自動停止、地上の自動放出、M869 の赤灯とホーン | ATA26_28 p.88、p.93、p.100；FCOM p.914 |
| 下部貨物室 | 光電式の煙検知器。前方 zone 1・2、後方 zone 3（aft）・4（bulk）。各 zone に検知器 A・B（EICAS では loop A/B） | zone ごとに A AND B。片方故障の組替えは電源投入時と手動試験のときだけ | 煙（試験は検知器内の LED） | FWD/AFT 赤灯、MAWEA、EICAS | ATA26_28 p.140、p.148–162；FCOM p.914 |
| 主脚格納部 | 連続式 1 ループ（左右の胴体脚・主翼脚に 2 本ずつ、計 8 本を直列） | 単ループ | 204°C で導通、冷えると復帰 | MAWEA（ベル・master WARNING）、EICAS | ATA26_28 p.270–272；FCOM p.915 |
| 主翼前縁・ストラット | 温度スイッチ（常開、並列）。片翼に前縁 9 個＋各ストラット 2 個 | どれか 1 個 | 前縁の内外側 82–93°C、ストラット 132–149°C、中央の前縁 104–121°C と 82–93°C | EICAS BLD DUCT LEAK L/R | ATA26_28 p.280–286 |
| 化粧室 | イオン化式（天井） | — | 煙 | 検知器のホーンと赤灯、客室表示、EICAS | ATA26_28 p.290–296 |
| クルーレスト | 操縦室側は電池式で局所警報のみ。OCR は 5 個 → 制御パネル → R9014 → EIU | — | 煙 | EICAS（109 は SMOKE DR 5 REST） | ATA26_28 p.306–320；FCOM p.923 |

- ループ選択スイッチは操縦室に無い（FCOM 8.10 の操作部 p.905–911 に該当なし）。単ループへの組替えは AFOLTS カードが自動で行う（ATA26_28 p.25–26）。
- 検知カードは E/E 室の M826 card file にある。エンジンごとに火災 A/B・過熱 A/B・AFOLTS の 5 枚、APU 3 枚、車輪格納部 1 枚、貨物 AFOLTS 2 枚（ATA26_28 p.10）。
- MAWEA（master monitor card A/B の二重系、115V AC）が master WARNING 灯とベル（aural synthesizer card）を出す（ATA26_28 p.12–13、p.216）。

### 2.2 消火器

| ボトル | 本数・場所 | 中身 | 低圧スイッチ | 放出 | 出典 |
|---|---|---|---|---|---|
| エンジン用 A・B | 各翼 2 本（左はエンジン 1・2、右は 3・4 用） | 630 in³、Halon 18 lb、窒素で 600 psig（21°C） | 225 psig | 各ボトルに squib 2 個（翼の 2 エンジン用）。1 エンジンに 2 本とも放出できる | ATA26_28 p.60–76；FCOM p.915 (8.20.3) |
| APU 用 | 1 本（APU 防火壁の前） | 同上 | 225 psig | squib 1 個。P5 の APU スイッチ、M869、地上の自動放出 | ATA26_28 p.116–124 |
| 下部貨物室 A・B・C・D | 4 本（前方貨物室の右後方） | A・B は Halon 55 lb、C・D は 80 lb、360 psig（21°C） | 300 psig（A・B の前方行きラインは 25 psig） | 各ボトルに squib 2 個（前方・後方用）。A・B は即時、C・D はフィルタ／ドライヤと調圧弁（約 100 psig）経由で約 2 時間 | ATA26_28 p.170–180 |
| 化粧室 | 各化粧室の洗面台下 | Halon 1301 125 g | — | 約 77°C で共晶はんだが溶けて自動放出。操縦室表示なし | ATA26_28 p.302 |

- 熱で 1200–1400 psig になると破裂板が開き、ボトルは周囲へ放出される（ATA26_28 p.64、p.116、p.172）。
- 405 の下部貨物室は 6 本（A–F）（FCOM p.918 (8.20.6)）。

### 2.3 操作部の場所

- P5 の M7326 ENGINE/APU/CARGO FIRE CONTROL：エンジン消火スイッチ 4、BTL A/B DISCH 灯（左右 2 組）、APU 消火スイッチと APU BTL DISCH 灯、CARGO FIRE ARM FWD/AFT と DISCH（ATA26_28 p.48、p.70、p.182；FCOM p.905–908）。
- P5 の M7317：FIRE/OVHT TEST スイッチ（ATA26_28 p.210；FCOM p.910）。
- P461（頭上整備パネル）の M7327 SQUIB TEST：TEST 1・2 と緑灯（ATA26_28 p.80、p.132、p.196）。
- 右胴体脚格納部の M869 APU FIRE SHUTDOWN（FCOM p.910–911 (8.10.6–7)）。P8 の FUEL CONTROL スイッチの赤灯（FCOM p.906）。

### 2.4 電源

| 負荷 | 電源 | 出典 |
|---|---|---|
| エンジン・APU の検知ループ A・B | APU battery bus。ATA の図は loop A が 28V DC BAT BUS＋DC bus 1（代替）、loop B が BAT BUS | FCOM p.820 (6.20.26)；ATA26_28 p.27、p.39 |
| APU 火災ホーン | APU battery bus（ATA は BAT BUS） | FCOM p.820；ATA26_28 p.111 |
| エンジン消火スイッチの解錠 | main hot battery bus（ATA は BAT BUS、CUTOFF 経由の経路は DC bus 1） | FCOM p.820；ATA26_28 p.51 |
| エンジン・APU・下部貨物室の消火（squib） | main hot battery bus | FCOM p.820；ATA26_28 p.72、p.124–125、p.185 |
| 車輪格納部の検知カード | 115V AC bus 2 | ATA26_28 p.273 |
| 主翼前縁の過熱検知 | 28V DC bus 2（代替）＋BAT BUS | ATA26_28 p.285 |
| MAWEA | 115V AC | ATA26_28 p.216 |
| 下部貨物室の煙検知 | 資料に記載なし | — |

- APU の火災検知は APU battery、APU の消火器は main battery から（FCOM p.896 (7.30.2)）。APU を OFF にしたあと 2 分待ってから BATTERY を OFF にすれば、停止シーケンス中も火災検知が保たれる（FCOM p.897 (7.30.3)）。
- 検知系の電源喪失は status FIRE/OVHT SYS（20 秒遅れ）（ATA26_28 p.34）。
- BATTERY スイッチ OFF でも hot battery bus は電池に直結なので消火はできると推定（FCOM p.820 の構成から）。

## 3. 操作と表示

### 3.1 エンジン火災パネル（P5）

- 消火スイッチ（FCOM p.905 (8.10.1)、p.916 (8.20.4)）
  - In：通常位置で機械的にロック。火災警報か、FUEL CONTROL の CUTOFF で解錠。下の Fire Override スイッチを押すと個別に解錠（FCOM p.906）。試験中も解錠（ATA26_28 p.48）。
  - Out：エンジン燃料弁と spar valve を閉、抽気弁を閉、発電機をトリップ、EDP への作動油を遮断して EDP を減圧、その翼の 2 本のボトルの squib を arm。
  - 回す：A か B を選んで放出。エンジン 1・3 は反時計回りで A・時計回りで B、2・4 は逆（ATA26_28 p.70、p.72；FCOM p.905 の図）。
- 赤灯（スイッチ内）：火災検知中か試験中（FCOM p.905）。
- BTL A DISCH・BTL B DISCH（amber、左翼用と右翼用）：ボトルが放出済みか低圧（FCOM p.905；ATA26_28 p.74–76）。

### 3.2 FUEL CONTROL スイッチ（P8）

- 赤灯：関連エンジンの火災検知中か試験中（FCOM p.906 (8.10.2)）。CUTOFF は燃料弁を閉じ、消火スイッチを解錠する（FCOM p.860 (7.13.2)）。

### 3.3 APU 火災パネル（P5）

- APU 消火スイッチ：In は機械的にロック、火災警報で解錠（override あり）。Out：ボトルを arm、APU 燃料弁を閉、APU 抽気弁を閉、空気取入口扉を閉、APU 発電機の field と breaker をトリップ、（自動停止しなかったときは）APU を停止。回す：APU 室へ放出（FCOM p.906–907）。ATA は左右どちらに回しても放出、引くとホーンもリセットと書く（ATA26_28 p.104–106、p.124）。
- 赤灯：APU 火災検知か試験。APU は火災で自動停止し、地上では消火器が自動で放出される（FCOM p.907 (8.10.3)）。
- APU BTL DISCH（amber）：放出済みか低圧（FCOM p.907）。

### 3.4 貨物室火災パネル（109）

- ARM FWD・AFT（交互動作。上が白の ARMED、下が赤の FWD/AFT）（FCOM p.907–908；ATA26_28 p.182、p.184）
  - FWD：消火器を arm、機器冷却を override にして前方区画への気流と暖房を止め、pack 3 と全ファンを止める。AFT：同じ内容に加え後方暖房を止める（FCOM p.908 (8.10.4)）。
  - ATA の一覧は、機器冷却 override、再循環・lav/galley・gasper ファン停止、pack 3 停止、前方暖房停止と前方 overboard 弁閉（FWD）、後方暖房停止と flapper 弁閉（AFT）、下部貨物室への空調停止（ATA26_28 p.189）。空調側の詳細は ATA-21 §4.7。
- 赤灯 FWD・AFT：その区画の火災か試験（FCOM p.908）。
- DISCH スイッチ（ガード付き、押している間だけ）：放出シーケンスを始める。109 は有効濃度 195 分（FCOM p.908）。ARM していない区画には放出されない（ATA26_28 p.185 の図）。
- DISCH 灯（amber）：消火器が放出済み（FCOM p.908）。
- 405・570 は MAIN DECK ARM と DEPRESS/DISCH があり、主デッキは減圧で消火する。下部の有効濃度は 405 が 334 分、570 が 210 分（FCOM p.909、p.918）。

### 3.5 FIRE/OVHT TEST・M869・その他

- FIRE/OVHT TEST（押し続ける）：エンジン・APU・車輪格納部・貨物・抽気ダクトの検知器へ試験信号を送り、操縦室の表示を試す（FCOM p.910 (8.10.6)）。流れは §4.7。
- M869（右胴体脚格納部）：APU FIRE WARNING HORN（地上での APU 火災と試験で鳴る）、APU STOP（5 秒以上押す）、APU EXTINGUISHER DISCHARGE（arm されていれば放出）、APU FIRE 灯、APU FIRE CONTROL（引き下げで APU 停止と消火器の arm）（FCOM p.910–911）。
- スクイブ試験（P461）：TEST 1・TEST 2 を押すとエンジン・APU・貨物の squib 灯が点く（FCOM p.187–188 (SP.8)）。TEST 1 がボトル A（貨物は前方用）、TEST 2 がボトル B（後方用）の squib を通す。貨物 ARM 中は A・B の試験を抑止（ATA26_28 p.80–82、p.198）。
- 煙排出ハンドル：引くと操縦室の煙排出口を開く。与圧中だけ有効（FCOM p.465 (1.30.31)）。
- 飛行前：消火スイッチ In、BTL DISCH・APU BTL DISCH・貨物 DISCH 消灯、貨物 ARM OFF と FWD/AFT 消灯、FUEL CONTROL の赤灯消灯（FCOM p.105 (NP.21.11)、p.117）。外部点検で M869 の APU FIRE CONTROL が In（FCOM p.101）。

### 3.6 EICAS メッセージ（109 を基準）

| メッセージ | レベル・音 | 条件 | 出典 | 現コード（CAS index） |
|---|---|---|---|---|
| FIRE ENG 1–4 | Warning・ベル | エンジン火災検知 | FCOM p.921 | warning 11–14（X-Plane の注釈で立つ） |
| FIRE APU | Warning・ベル | APU 火災検知 | FCOM p.921 | warning 8（立てるコード無し） |
| FIRE CARGO FWD, AFT | Warning・ベル | 下部貨物室の煙 | FCOM p.921 | warning 10, 9（無し） |
| FIRE WHEEL WELL | Warning・ベル | 主脚格納部の火災 | FCOM p.922 | warning 21（無し） |
| OVHT ENG 1–4 NAC | Caution・beeper | ナセル過熱 | FCOM p.922 | 表に無い |
| BLD DUCT LEAK L, C, R | Caution・beeper | ダクトのリーク・過熱 | FCOM p.619 (2.50.1)；ATA26_28 p.286 | caution 7, 6, 8（無し） |
| SMOKE DR 5 REST | Caution・beeper | door 5 クルーレストの煙 | FCOM p.923 | caution 52（無し） |
| >SMOKE LAVATORY | Advisory | 化粧室の煙（ATA は caution） | FCOM p.923；ATA26_28 p.296 | caution 53 と advisory 264 の二重（無し） |
| >BTL LO L, R ENG A, B | Advisory | 翼のエンジン用ボトル A/B の低圧 | FCOM p.921；ATA26_28 p.78 | 表に無い（advisory 47–48 が誤った「>BTL LOW APU A/B」） |
| >BOTTLE LOW APU | Advisory | APU ボトル低圧 | FCOM p.921；ATA26_28 p.130 | advisory 44（無し） |
| >CGO BTL DISCH | Advisory | 地上：貨物ボトルのどれかが低圧。空中：A と B が放出済み | FCOM p.921 | advisory 51（無し） |
| >CARGO DET AIR | Advisory | 煙検知の吸引空気不足。エンジン 2 基未満の運転で抑止 | FCOM p.921；ATA26_28 p.144 | advisory 49（無し） |
| >DET FIRE APU | Advisory | APU の loop A・B 故障 | FCOM p.921 | advisory 58（無し） |
| >DET FIRE/OHT 1–4 | Advisory | エンジン火災か過熱の loop A・B 故障 | FCOM p.921 | advisory 59–62（無し） |
| >TEST IN PROG | Warning | 手動試験中 | FCOM p.923 (8.30.3) | warning 24（無し） |
| >FIRE TEST PASS / FAIL | Warning | 手動試験の完了／1 系統以上が不合格 | FCOM p.923 | warning 20 / 19（無し） |
| >ENG 1–4 SHUTDOWN | Caution（master CAUTION なし） | 消火スイッチを引いた、または FUEL CONTROL が CUTOFF | FCOM p.902 (7.40.4) | caution 23–26（エンジン側、条件が違う。FIRE-12） |
| 405/570：FIRE MAIN DECK、FIRE MN DK FWD/MID/AFT、>VLV TST IN PROG、>VALVE TEST PASS/FAIL、570：>SMOKE CREW REST（caution） | — | 主デッキ・弁試験・上層クルーレスト | FCOM p.922、p.924 | warning 15–18・25–27（無し）、>SMOKE CREW REST は表に無い |

- status（補助 EICAS、ATA だけに記載）：ENG n FIRE LP A/B、ENG n OVHT LP A/B、APU FIRE LOOP A/B、FWD CARGO 1/2 LP A/B、AFT CARGO 3/4 LP A/B（いずれも「その loop の火災または故障」、20 秒遅れ）、CARGO DET FWD/AFT（両 loop 故障、20 秒）、CARGO DET AIR（60 秒）、FIRE/OVHT SYS（電源喪失、20 秒）、BTL LOW L/R ENG A/B、BOTTLE LOW APU、BTL LOW CARGO A–D、BLD DUCT LEAK L/R（60 秒）、NAC TEMP ENG n（ATA26_28 p.34、p.46、p.56、p.78、p.102、p.130、p.164、p.194、p.286）。
- 表にあるが FCOM に無いもの：>SMOKE LAV/COMP、>SMOKE ZN B REST、>SMOKE ZN F REST（`B747.87.xt.warning.lua:162-164,451`）。

### 3.7 警報音と master WARNING

- ベル：109・405 は 2 秒鳴って 3 秒休み、570 は 1 秒鳴って 10 秒休み。火災が消えるか、どちらかの Master WARNING/CAUTION Reset を押すと止まる（FCOM p.913 (8.20.1)、p.1550 (15.20.4)）。新しい火災警報が来ると灯とベルが再び出る（ATA31 p.173 (31-51)）。aural の優先度は wailer、siren に次ぐ 3 番目（ATA31 p.159）。
- 灯：両方の master WARNING（火災中でもリセットできる）、関連する消火スイッチ・貨物の赤灯、エンジン火災では FUEL CONTROL の赤灯。後の 3 つは火災信号がある間は消えない（FCOM p.914）。FIRE メッセージも火災中は出たまま（FCOM p.913）。
- 過熱：beeper、master CAUTION、OVHT メッセージ（FCOM p.914）。
- APU 火災の地上ホーン：火災が消えるか、M869 の APU FIRE CONTROL を引くと止まる（FCOM p.913）。P5 の APU 消火スイッチを引いても止まる（ATA26_28 p.104、p.110–111 の図）。

## 4. 内部ロジック

### 4.1 AFOLTS の共通論理（双ループ）

- 素子の警報スイッチ（常開）が閉じると「警報」、健全性スイッチ（常閉）が開くと「故障」。カードはこの違いで火災と故障を分ける（ATA26_28 p.20、p.25、p.37）。
- 通常は 2 ループの AND。1 ループが故障なら、もう一方だけで判定する（実質 OR）。両ループ故障なら警報は出せず、故障出力が >DET を出す（ATA26_28 p.25、p.32、p.37、p.44；FCOM p.914、p.921）。
- 組替えの時機：初回の電源投入時の自動試験、手動試験、CMC 試験。エンジンのループは常時監視している。どの試験でも、健全なら双ループ運用に戻る（FCOM p.919 (8.20.7)；ATA26_28 p.26、p.38）。貨物は電源投入時と手動試験のときだけ組み替える（ATA26_28 p.154、p.162）。
- APU は最初から OR（ATA26_28 p.93、p.100；FCOM p.914）。
- 片ループだけが警報を出している状態（AND で不成立）は status の「LP A/B（火災または故障）」になる。570 だけは貨物・ダクトリークで追加試験をし、60 分ごとに再試験する（FCOM p.919）。109 には無い。
- 過熱と火災が同時に出るか（優先や抑止）は資料に記載なし。

### 4.2 エンジン消火スイッチ

- 解錠：AFOLTS の火災出力か試験で解錠ソレノイドが励磁。FUEL CONTROL の CUTOFF で R8142 経由で励磁。override（スイッチ下のプランジャ）は機械式（ATA26_28 p.48、p.50–51；FCOM p.905–906）。
- 引いたときの作用と現状：

| 対象 | 作用 | 出典 | 現コード |
|---|---|---|---|
| エンジン燃料弁 | 閉 | FCOM p.905、p.886 (7.20.16) | 閉じる（`B747.40.xt.engines.lua:2051,2074,2097,2120`、`pos_arm==1`） |
| spar valve | 閉 | FCOM p.905；ATA26_28 p.50 | 閉じない（`B747.25.xt.fuel.lua:1327-1328`。ATA-28 FUEL-18） |
| PRSOV・PRV・HPSOV | 閉 | FCOM p.905；ATA26_28 p.51 の図 | PRSOV 相当が閉じる（`B747.55.xt.air.lua:501,542,583,624`、`pos_arm==0` が条件） |
| 発電機 | GCR トリップ（GEN CONT の OFF→ON で復帰） | FCOM p.905；LH24 p.108 (24-20) | 何もしない（エンジン停止で発電は止まる） |
| 油圧 | SOV 閉、EDP 減圧、demand pump（AUTO）作動 | FCOM p.905、p.1490 (13.20.2) | 何もしない（ATA-29 HYD-05） |
| 消火器 | その翼の A・B の squib を arm。回せるようになる | FCOM p.905、p.916 | 回転は `pos_arm==1` のときだけ（`B747.35.xt.fire.lua:154` ほか） |
| EICAS | >ENG n SHUTDOWN（master CAUTION なし） | FCOM p.902 | 回転位置で判定（FIRE-12） |
| 地上の抑止 | ELEC GEN OFF、ENG FAIL、ENG OIL PRESS、HYD PRESS ENG、NAI VALVE などを抑止 | FCOM p.1586 (15.20.40) | 各系統の担当 |
| 始動 | motoring できなくなる（抽気弁が閉じる）。空中始動 envelope の表示はスイッチ In が条件 | FCTM p.284 (8.6)；FCOM p.840 (7.10.12) | 始動弁の逆流は止まる（`B747.55.xt.air.lua:519`）。envelope は未実装 |

### 4.3 エンジン消火器

- 左翼の A・B はエンジン 1・2、右翼の A・B は 3・4 に共用。スイッチを回すと hot battery bus から squib に電流が流れ、そのボトルが空になる。圧力が 225 psig まで下がると圧力スイッチが閉じ、BTL DISCH 灯と EIU（>BTL LO）へ出る（ATA26_28 p.62–78；FCOM p.915）。
- 空のボトルを選んでも放出される剤は無い。一度放出したボトルは機上で再充填できない（ATA26_28 p.64）。
- 放出にかかる時間は資料に記載なし。貨物の A・B は「瞬時」に出ると書かれている（ATA26_28 p.170）ので、同じ squib 式のエンジン用も 1–2 秒程度と推定。

### 4.4 APU

- 検知は OR。火災で APU は空中でも地上でも直ちに停止する（FCOM p.897、p.907、p.914；ATA26_28 p.93）。手動試験中は停止させない（ATA26_28 p.94）。
- 地上の自動放出：火災（R7792）かつ APU 回転 95% 未満（R7715 が落ちる）かつ地上（R263）が 10 秒続くと R7791 が squib に通電する。試験中は R7690 が止める（ATA26_28 p.124、p.125 の図）。空中では自動放出しない。
- ホーン：地上で火災（または試験）のとき R825 で鳴る。P5 の APU スイッチか M869 のハンドルを引くと回路が切れる（ATA26_28 p.108–111 の図；FCOM p.913）。
- 手動：P5 のスイッチを引いて回す。M869 はハンドルを引き下げ（R7204 で arm と APU 停止）、DISCHARGE を押す（ATA26_28 p.122–124）。
- APU セレクター ON のまま自動停止すると、APU の側で advisory APU（自動停止）が出る（FCOM p.902）。これは APU 担当の論理。

### 4.5 下部貨物室

- 煙検知：venturi ejector が空気圧マニホールド（中央ダクト）の空気で吸引し、各ポートの空気を検知器に通す（ATA26_28 p.138–142；FCOM p.914）。吸引不足は圧力スイッチ（水柱 7 in で閉、11 in で開）→ >CARGO DET AIR。エンジン 2 基未満の運転では抑止（ATA26_28 p.142–145）。吸引が無いと煙を拾えない（推定）。
- 放出の順序（ATA26_28 p.184–187 と図 p.185・p.187；FCOM p.917 (8.20.5)）
  1. 片方だけ ARM して DISCH を押すと、その区画へ A・B を即時放出し、区画の lock-in リレー（前方 R7452、後方 R7453）が自己保持する。
  2. 空中なら 30 分のタイマーのあと R7454 が C・D を同じ区画へ放出する。C・D は調圧弁で約 2 時間かけて出る（ATA26_28 p.170、p.180）。
  3. 30 分前に着陸すると接地で C・D を放出する（空地リレー R988）。
  4. 地上で押すと A・B・C・D を同時に放出する。
  5. 両方 ARM して押すと A・B は両区画へ出る（ATA26_28 p.184）。このとき図ではどちらの lock-in も入らない配線に見え、C・D は出ないと読める（推定）。
  6. lock-in のリセットは P6 の FIRE EXT LOWER CARGO CB を一度抜く（ATA26_28 p.184）。
- FCOM は「2 本を即時、残り 2 本を少し後か接地時」と書くだけで時間は無い（FCOM p.917）。時間は ATA の 30 分を採る（§9）。
- 表示：DISCH 灯は A か B の圧力スイッチ（300 psig）か、A/B の前方行きライン圧力スイッチ（25 psig、前方は配管が短くボトル圧の低下が遅いため）。C・D の圧力スイッチは EICAS だけ（ATA26_28 p.178、p.192–193）。>CGO BTL DISCH は地上ならどれかの低圧、空中なら A と B の放出（FCOM p.921）。
- ARM の空調への作用は ATA-21 §4.7（AIR-17）。lock-in の接点も空調系へ出ている（ATA26_28 p.185 の図）。

### 4.6 車輪格納部・抽気ダクト・化粧室・クルーレスト

- 車輪格納部：8 本のどれかが 204°C で接地 → K1 → MAWEA（ベル・master WARNING）と EICAS FIRE WHEEL WELL。冷えれば復帰。試験は R8048 がループを接地する（ATA26_28 p.270–274）。消火設備は無く、乗員は脚を下げる（FCOM p.913；FCTM p.304 (8.26)）。
- 抽気ダクト：温度スイッチのどれかが閉じると R7420 → EIU → BLD DUCT LEAK L/R。試験は R8052（ATA26_28 p.284–285）。自動隔離は無く、乗員が ISLN と抽気弁を閉じる（FCOM p.613 (2.40.3)）。C の検知元は資料に記載なし（ATA-36 §4.7）。メッセージの所有は ATA 36（PNEU-03）、試験信号は火災側。
- 化粧室：局所のホーン・赤灯・客室表示と EICAS。廃物入れの自動消火は独立（ATA26_28 p.290–302）。
- door 5 クルーレスト（109）：SMOKE DR 5 REST と同時に給気弁が閉じ再循環ファンが止まり、Door 5 Crew Rest Reset を押すまで戻らない（煙が消えていれば戻る）（FCOM p.589 (2.20.3)、p.559 (2.10.7)）。空調側は ATA 21。

### 4.7 FIRE/OVHT TEST

1. 押すと全検知器（エンジン火災・過熱、APU、貨物、車輪格納部、抽気ダクト）に試験信号が入る（FCOM p.910）。
2. 109 で出るもの：ベル、地上なら APU ホーン、>TEST IN PROG、master WARNING、エンジン消火スイッチの赤灯、APU 赤灯、貨物 FWD/AFT 赤灯、FUEL CONTROL の赤灯（FCOM p.919）。個別の FIRE メッセージは一覧に無い（FIRE WHEEL WELL が一瞬出ることはある、FCOM p.920）。過熱の caution も一覧に無い（推定で出さない、§9）。
3. 約 5 秒後に >FIRE TEST PASS か >FIRE TEST FAIL が >TEST IN PROG を置き換える。FAIL のときは故障した系統のメッセージも出る（ATA26_28 p.30、p.42；FCOM p.919）。
4. 離すと試験メッセージは全部消える。>TEST IN PROG の間に離すと試験は完了しない（FCOM p.919）。
5. 試験中は APU を停止させず、APU 消火器も放出しない（ATA26_28 p.94、p.124）。エンジン・APU のスイッチは解錠される（ATA26_28 p.48、p.104）。
6. 車輪格納部とダクトリークのループは手動試験でしか試されない（FCOM p.920）。
7. 405・570 は PASS/FAIL の後に >VLV TST IN PROG、離して約 90 秒後に >VALVE TEST PASS（FCOM p.920、p.187）。

### 4.8 火災警報（MAWEA）と離陸中の抑止

- 入力：エンジン 1–4、APU、前方・後方貨物、車輪格納部の火災と試験 → master monitor card A・B → 両 master WARNING とベル（ATA26_28 p.12–13 の図；ATA31 p.173）。
- リセット：どちらかの master WARNING を押すと灯とベルが止まる。火災が続いていても止まる。新しい火災警報で再び出る（ATA31 p.173；FCOM p.914）。
- 離陸中の抑止（109：FCOM p.1595 (15.20.49)、570：p.1589 (15.20.43)）：新しい FIRE 警告の master WARNING 灯とベルを、V1 から「電波高度 400 ft か V1 後 25 秒の早い方」まで抑止する。V1 前から出ていたものは続ける。抑止中に出た FIRE は抑止の終わりにベルを鳴らす。メッセージ自体は抑止しないと推定（表で抑止の対象に挙がっているのが灯とベルだけ）。
- 抑止の開始は計算対気速度が V1 を超えたとき。ADC・FMC の速度が無ければピッチ 5° 超（ATA26_28 p.8、p.12）。
- OVHT（caution）の master CAUTION・beeper は一般の caution 抑止（80 kt から 400 ft か回転後 20 秒）に従う（FCOM p.1588 (15.20.42)）。ATA 31 の担当。

### 4.9 擬似コード（109）

```
-- 検知ゾーン z（エンジン火災×4、過熱×4、APU、貨物 zone 1-4）
pwrA, pwrB = 検知電源（APU battery bus / DC bus 1 など）
okA = pwrA and not loopFault[z].A ; okB = pwrB and not loopFault[z].B
alA = okA and (heat[z] or test) ; alB = okB and (heat[z] or test)
if z == APU              then alarm = alA or alB
elseif cfg[z] == DUAL    then alarm = alA and alB
elseif cfg[z] == ONLY_A  then alarm = alA                 -- 単ループ（B 故障）
else                          alarm = alB                 -- 単ループ（A 故障）
end
-- 組替え: 電源投入・手動試験（エンジンは常時）で、故障ループを外す／健全なら DUAL に戻す
detFail[z] = not okA and not okB                       -- >DET ...
-- エンジン消火スイッチ i
unlock[i] = hotBat and (fireAlarm[i] or test or fuelCutoff[i]) or overridePushed[i]
switchOut[i]: 燃料弁・spar 閉、PRSOV/PRV/HPSOV 閉、GCR トリップ(ラッチ)、油圧 SOV 閉・EDP 減圧
rotate A/B (switchOut のときだけ): hotBat かつ squib 未使用 → ボトル放出（共用ボトル）
btlDisch[b] = psi[b] <= 225
-- APU
if apuFire and not test then APU 即停止 end
autoDisch = apuFire and onGround and apuN1 < 95 and not test が 10 s 続く
horn = onGround and (apuFire or test) and not apuSwitchOut and not m869Pulled
-- 貨物
on DISCH: for c in armed: fire A,B → c ; if #armed == 1 then latch = c ; t0 = now
if latch and (onGround or now - t0 >= 30 min) then fire C,D → latch (調圧で約 2 h)
-- MAWEA
fireWarn = any(FIRE ENG/APU/CARGO/WHEEL WELL) or test
newFire = 立ち上がり ; inhibit = V1(またはピッチ>5°)～min(RA 400 ft, 25 s)
if newFire and not inhibit then mwLight = 1 ; bell = 1 end   -- 抑止明けに残っていれば鳴らす
reset 押下 or not fireWarn → bell = 0（灯もリセット）
bell の断続: 2 s 鳴る / 3 s 休む（570 は 1 s / 10 s）
```

## 5. 他系統とのつながり

| 相手 | 方向 | 内容 | 出典 |
|---|---|---|---|
| 電源（ATA 24） | 入力 | APU battery bus（検知・ホーン）、main hot battery bus（解錠・squib）、DC bus 1/2、AC bus 2（車輪格納部）、115V AC（MAWEA）。ELEC 側に bus ごとの通電を問う手段が要る（ELEC-02・ELEC-15） | FCOM p.820；本ノート §2.4 の出典 |
| 電源 | 出力 | エンジン消火スイッチ → GCR トリップ（ラッチ）。APU スイッチ → APU 発電機の field と breaker | FCOM p.905、p.907；LH24 p.108、p.144 |
| 燃料（ATA 28） | 出力 | spar valve 閉（FUEL-18）。APU 燃料弁閉 | FCOM p.905、p.907 |
| エンジン（ATA 73/77） | 双方向 | 出力：燃料弁閉、>ENG SHUTDOWN。入力：FUEL CONTROL の CUTOFF（解錠）、N2・運転状態（CARGO DET AIR の抑止、2 基） | FCOM p.860、p.886、p.902；ATA26_28 p.144 |
| 抽気（ATA 36） | 双方向 | 出力：PRSOV・PRV・HPSOV 閉、APU 抽気弁閉。入力：中央ダクト圧（貨物煙検知の吸引）、ダクトリーク（BLD DUCT LEAK）は ATA 36 と分担 | FCOM p.905、p.907、p.613–619；ATA26_28 p.142 |
| 空調（ATA 21） | 出力 | 貨物 ARM → pack 3 停止、ファン停止、機器冷却 override、暖房停止（AIR-17）。クルーレストの煙 → 給気弁・ファン | FCOM p.908、p.589；ATA26_28 p.189 |
| 油圧（ATA 29） | 出力 | SOV 閉、EDP 減圧、demand pump 作動（HYD-05） | FCOM p.1490 |
| APU（ATA 49） | 双方向 | 出力：火災で即停止（60 秒の冷却なし）、取入口扉閉。入力：APU N1（95%）、APU 運転 | FCOM p.897、p.907；ATA26_28 p.124 |
| 脚・空地（ATA 32） | 入力 | 空地（APU 自動放出、ホーン、貨物 C・D、>CGO BTL DISCH）。ブレーキ温度（車輪格納部の推定入力） | ATA26_28 p.124、p.185 |
| 警報（ATA 31） | 出力 | CAS の status、ベル要求、master WARNING。離陸中の抑止（V1、電波高度、ピッチ） | FCOM p.1550、p.1595；ATA31 p.173 |
| 照明 | 出力 | 消火スイッチ・APU の赤灯（`laminar/B747/annunciators/engine_fires`）、BTL DISCH、貨物 FWD/AFT/DISCH、スクイブ灯（`annunciator/brightness_ratio`） | `B747.90.xt.lighting.lua:1127-1130,1400-1431` |
| FMC | 入力 | `laminar/B747/airspeed/V1`（抑止の開始） | `B744.fms.pages.lua:8` |

## 6. 実装上の注意

- **火災の元は X-Plane の故障を使い、検知は自前で作る。**
  - エンジン：`sim/operation/failures/rel_engfir0–3` → `sim/flightmodel2/engines/is_on_fire[i]`（0–1）を「ナセル内の熱」とし、ループ・電源・試験は自前で判定する。今は注釈 `sim/cockpit2/annunciators/engine_fires` の素通し。
  - APU：`sim/operation/failures/rel_apu_fire`。failure_enum なので**作動中は 6**。1–5 は「予約」で火災ではない（コード内でも故障は `== 6` で判定している。例 `B747.90.xt.lighting.lua:1116`）。
  - X-Plane に無いもの（過熱、貨物の煙、車輪格納部、ダクトリーク、化粧室・クルーレスト、ループ故障、ボトル漏れ）は自前の故障 dataref を新設する（例 `laminar/B747/fire/fail/...`。新しい名前なので INTERFACES には当たらない）。車輪格納部はブレーキ温度 `laminar/B747/gear/brake_temp[18]` と脚上げの組み合わせで発火させる案もある（推定。資料はブレーキとの関係を書いていない）。
- **消火**：`sim/cockpit2/engine/actuators/fire_extinguisher_on[i]` は「剤が実際に出ている間」だけ 1 にする（ボトル圧あり、hot battery bus 通電、squib 未使用）。X-Plane がこれで火を消すか、1 本で必ず消えるかは未確認（§9）。APU には X-Plane の消火 dataref が無いので、放出成功で `rel_apu_fire` を 0 に戻す設計になる（推定。X-Plane の APU の反応は要確認）。
- **他モジュールへの出力**：今は各モジュールがアニメーション値 `fire/engine0N/ext_switch/pos_arm` を `==1`・`==0`・`>0.95` とばらばらの閾値で読む。論理状態（例 `laminar/B747/fire/eng_switch_out[4]`、`apu_switch_out`、火災・過熱・故障の状態、ベル要求）を新設し、燃料・抽気・油圧・電源・エンジン・空調・照明・警報はそれを読む。アニメーション値の名前と意味は残す（3D・音が使う）。
- **ベル（音）の制約**：ベルは `fmod/747-400.snd:5825-5851` で X-Plane の `sim/cockpit/warnings/annunciators/engine_fire` と試験ボタン `fire/fire_ovht/button_pos` に直結している（`747-400D.snd`・`747-400F.snd` も同じ）。警報モジュールが作る `laminar/B747/warning/warning_bell` は音にもパネルにも使われていない。リセットで止まる、APU・貨物・車輪格納部で鳴る、離陸中に抑止する、型式で断続を変える、を実現するには、.snd のベルを `warning_bell`（または新しい火災ベル dataref）に付け替える必要がある。音は対象外の資産なので**利用者の承認が要る**。断続（2 s/3 s）は FMOD イベント側に入っているかが不明なので、プラグインで dataref を断続させる方が確実（推定）。
- **3D の制約**（3D は対象外。変えるなら承認が要る）：
  - APU 消火スイッチは灯（`Cockpit_OH1.obj:137080`）だけで、manipulator もアニメーションも無い（`747-400_cockpit.obj` に該当なし）。Fire Override スイッチ、スクイブ試験ボタン、主デッキの ARM・DEPRESS/DISCH も無い。キー割り当て用のコマンドを新設して補う。
  - FUEL CONTROL の赤灯は `Cockpit_TQ.obj:31477-31495` で X-Plane の読み取り専用 `sim/cockpit2/annunciators/engine_fires` に付いている。試験や自前検知に合わせて点けるには OBJ の付け替えが要る。
  - 貨物 ARM の白い ARMED は、スイッチごとに光源が 1 つ（`brightness_ratio[35]`・`[36]`、`Cockpit_OH1.obj:136788,136793`）しかなく、表現できるかは要確認。
- **CAS 表**：メッセージの追加・修正（OVHT ENG n NAC、>BTL LO L/R ENG A/B、>SMOKE LAVATORY の二重解消）は init（`B747.87.warning.lua`）と xt の両方の表を直す。index は配列の位置なので、ATA 31 の作り直しと調整する。メッセージごとに aural（なし／beeper／ベル／siren）を持たせ、FIRE 系はベル、試験メッセージは音なし（ベルは試験信号から）にする。
- **時間**：試験 5 秒、APU 自動放出 10 秒、貨物 C・D 30 分、抑止 25 秒、status 20・60 秒。30 分タイマーは `SIM_PERIOD` の積算にして一時停止で止まり、時間加速で進むようにする。flight start でボトル・ラッチ・タイマーを初期化する（今も `B747_set_fire_all_modes` でボトルを 600 psi に戻している）。
- **簡略化してよいもの**：NAC TEMP（整備ページ）、CMC の地上試験、熱による過圧放出、ボトル圧の温度変化、化粧室の自動消火、クルーレストの局所パネル、主デッキ（3D が無い間）、status メッセージ（status 表示の仕組みができるまで）。
- **簡略化してはいけないもの**：双ループの AND と単ループへの組替え（>DET が乗員に見える）、スイッチのロックと引いたときの作用（燃料・抽気・油圧・発電機）、翼ごとのボトル共用と BTL DISCH、APU の自動停止と地上の自動放出・ホーン、貨物の 2 段放出（即時＋30 分／接地）と DISCH 灯、ベルのリセットと離陸中の抑止、試験の流れ（TEST IN PROG → 約 5 秒で PASS、離すと消える）。
- 煙排出ハンドル（`fire/snoke_evac/handle`、名前の綴り違いは INTERFACES にあるので残す）は init 側の notifier で、ハンドル 0.95 以上かつ差圧 1 psi 超のとき X-Plane の操縦室煙の故障を 0 にする（`B747.35.fire.lua:58-69`）。FCOM の「与圧中だけ有効」には合う。排出口からの漏れを与圧モデルへ入れるかは ATA 21 と相談。

## 7. 現状実装との比較（GAP 候補）

略号：FIR＝`plugins/xtlua/scripts/B747.35.xt.fire/B747.35.xt.fire.lua`、WRN＝`plugins/xtlua/scripts/B747.87.xt.warning/B747.87.xt.warning.lua`、LIT＝`plugins/xtlua_keysystems/scripts/B747.90.xt.lighting/B747.90.xt.lighting.lua`、MAN＝`plugins/xtlua/scripts/B747.01.xt.manipulators/B747.01.xt.manipulators.lua`、ENG＝`plugins/xtlua/scripts/B747.40.xt.engines/B747.40.xt.engines.lua`、SND＝`fmod/747-400.snd`。

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

件数：高 4、中 11、低 5（計 20）。他章の GAP と重なるもの：FIRE-05 と AIR-17、FIRE-13 と FUEL-18・HYD-05・ELEC-04、FIRE-15 と PNEU-03、FIRE-18 と ELEC-02・ELEC-15。

## 8. 作り直しか部分修正か

**火災モジュール（`B747.35.xt.fire.lua`）は作り直しを勧める。** init 側の dataref・コマンドの名前と意味は残し、足りないものを足す。

- 今の 653 行は、4 エンジン分の同じ処理の繰り返しと X-Plane の値の素通しがほとんどで、残すべき論理が少ない。検知・APU・貨物・試験・ベルはどれも新しく書くことになるので、部分修正の利点が無い。
- 表駆動にする（検知ゾーン表：ループ、論理、組替えの時機、電源、出力。ボトル表：中身、共用先、squib、圧力スイッチ、電源。スイッチ表：解錠条件、作用）。エンジンごとに 4 回書き写す形をやめれば、写し間違いや閾値の不揃い（今は他モジュールが `pos_arm` を `==1`・`==0`・`>0.95` で読む）が入りにくくなる。
- 構成案：① 入力（X-Plane の故障、自前の故障、電源、空地、APU N1、エンジン運転、V1・電波高度・ピッチ、中央ダクト圧）→ ② 検知（AFOLTS 相当、ゾーンごと）→ ③ 操作（消火スイッチの解錠・引く・回す、APU、貨物 ARM/DISCH、試験、override・スクイブ試験・M869 のコマンド）→ ④ 消火（ボトル、squib、`fire_extinguisher_on`、APU 故障の解除）→ ⑤ 自動（APU 停止・放出、貨物タイマーと接地、試験シーケンス）→ ⑥ 出力（灯、CAS、ベル要求、他系統向けの論理状態）。
- 守るもの（INTERFACES.tsv）：`laminar/B747/fire/engine01–04/ext_switch/pos_arm`・`pos_disch`（3D・音・エンジン・空調が読む）、コマンド `fire/engine01–04/ext_switch_arm`・`ext_switch_A`・`ext_switch_B`、`fire/button/fire_ovht_test`、`fire/fire_ovht/button_pos`（3D・音・警報）、`fire/snoke_evac/handle`、`annunciators/engine_fires[0–4]`（3D の赤灯。作成はエンジンの init）、`button_switch/cargo_fire_arm_fwd`・`_aft`・`_disch`（manipulator 側）、`annunciator/brightness_ratio` の index 35–37・95–103・113–117。INTERFACES 外でも残すもの：ボトル圧 `fire/engine01_02A/ext_bottle/psi` など 4 本（照明）、`fire/init_CD` と `ai/fire_quick_start`（quick start）、`debug/fire`。
- 規模：火災モジュール単体は M（1 週間程度）。警報（aural の選択、抑止、CAS 表）、照明、エンジン（>ENG SHUTDOWN）、燃料・油圧・電源（引いたときの作用）、空調（貨物 ARM）、APU 停止への波及と、.snd・3D の変更（承認）を含めると L。
- 急ぐなら先に部分修正できるもの（S）：FIRE-04（`== 6`）、FIRE-12（引いた状態で判定）、FIRE-11（CAS 表の文言）、FIRE-10（ボトル圧が無ければ `fire_extinguisher_on` を出さない）、FIRE-09（ロック）。どれも作り直しの設計と矛盾しない。

## 9. 未確認事項

1. X-Plane：`fire_extinguisher_on` でエンジン火災（`rel_engfir`）が消えるか、1 回で必ず消えるか、燃料を止めないと再燃するか、故障の enum が 0 に戻るか。`engine_fires` 注釈が無電源でも 1 になるか。
2. X-Plane：`rel_apu_fire = 6` で APU が止まるか、`rel_apu_fire` に 0 を書けば火が消えるか、そのあと再始動できるか。
3. 音：FMOD イベント `Warnings/master-warning` の中身（siren か）。エンジン火災や試験で master-warning とベルが同時に鳴っていないか。`Warnings/fire bell` に 2 s/3 s の断続が入っているか、ループか。
4. FUEL CONTROL の赤灯：書き込み可の `sim/cockpit/warnings/annunciators/engine_fires`（DataRefs.txt で y）に書けば `sim/cockpit2/...` 側に反映されるか。だめなら OBJ の付け替えしかない。
5. 3D：貨物 ARM の白い ARMED を表せるか。`Cockpit_OH1.obj:136606` の行頭が `zight_level`（`ATTR_light_level` の破損）で、スクイブ灯（貨物 A、`brightness_ratio[100]`）の光源が効かない可能性。Log.txt に OBJ の警告が出ていないか。
6. 試験中に OVHT の caution・beeper を出すか。FCOM の一覧には無く、ATA は「過熱検知と同じ反応」と書く。FCOM の一覧を採り、出さないことにした。
7. 過熱と火災が同時に起きたときの表示の優先・抑止（資料に記載なし）。
8. ボトルの放出時間、検知の応答時間（資料に記載なし）。
9. 資料間の食い違い（採った方）：貨物 C・D の遅れは FCOM「少し後」と ATA「30 分」（ATA）。>SMOKE LAVATORY は FCOM advisory と ATA caution（FCOM）。試験メッセージの文言は ATA の TEST IN PROGRESS/TEST PASSED と FCOM の >TEST IN PROG/>FIRE TEST PASS（FCOM）。貨物ボトル低圧は ATA の >BTL LOW CGO A/D と FCOM の >CGO BTL DISCH（FCOM）。FCOM 15.20 の表は APU FIRE、8.30 は FIRE APU（8.30）。APU ホーンを止める操作に P5 の APU スイッチを含むか（ATA は含む、FCOM は M869 だけ書く。両方採る）。検知ループの電源は FCOM が APU battery bus、ATA が BAT BUS＋DC bus 1。
10. 貨物の両区画 ARM で DISCH したときの C・D（図からは放出されないと読めるが確証なし）。
11. CARGO DET AIR の閾値をダクト圧（`laminar/B747/air/duct_pressure_C`）でどう置き換えるか（水柱 7/11 in と psi の対応は資料に記載なし）。
12. 車輪格納部の火災をブレーキ温度から起こす場合の閾値と、脚とブレーキの対応（推定の設計）。
13. エンジン型式（PW・CF6・RR）による検知器の配置や温度の違い（資料に記載なし）。
14. `acf/_warn_fire_EQ 1` と `_ann_wav_file/61–68 Firebell.wav`（ファイルは無い）で、XP12 が FMOD とは別に何か鳴らすか。
15. 貨物機（`laminar/B747/freighter` = 1）を選んだとき、主デッキの火災をどこまで作るか（3D の操作部が無い）。
