# ATA 23 通信（Communications）実装ノート

GAP ID 接頭辞：`COM`。2026-10-23 調査。コード・acf・obj は変更していない。

## 1. 概要

- 対象：VHF/HF 無線機と radio tuning panel（RTP）、audio control panel（ACP：送信選択、受信と音量、PTT の R/T–INT、VOICE/BOTH/RANGE フィルター、VOR/ADF・APP 選択、SPKR）、audio management unit（AMU）の音声経路、flight / service / cabin interphone、SELCAL、CALL 灯とチャイム、操縦室からの PA、各機器の電源、通信の EICAS メッセージ、ATC/company datalink の乗員側の操作と表示。CDU のデータリンク画面は FMS 担当、ATC トランスポンダは航法担当なので、インターフェースだけ書く。CVR・プリンター・SATCOM・貨物機の cargo interphone は要点だけ。
- 資料（ページは PDF ページ）：
  - FCOM 5.10 p.683–712、5.20 p.713–718、5.30 p.719–724、5.40 p.775–776。5.33（p.725–770）と 5.34（p.771–774）は乗員側の表示（memo、チャイム、DATA LINK 状態）だけ読んだ（p.725、p.755–757、p.771–773）。補助に L.10 p.77・p.80、NP.21 p.95・p.104–105・p.112–113・p.117、SP.1 p.164、6.20 p.798–800・p.819–820、15.20 p.1559・p.1588–1601、FCTM p.135・p.308。
  - ATA23：23-51 flight interphone p.3–80、23-41 service interphone p.81–100、23-28 SELCAL p.101–126、23-42 cabin interphone p.165–284（乗員側）。23-31 PA は乗員側の要点（p.288–289、304、308、317–318、323–326、329、376）。ACESS（23-30）、IFE（23-32/34）、PSS（23-33）は飛ばし読みで、乗員に見えるのは PCP の VIDEO IN USE と客室サインのチャイムだけだった。ATA31 p.160・p.218（31-51 のチャイム）。
  - 描画して確認した図：FCOM p.683（ACP）、p.685（RTP）、p.432（後方 aisle stand）、p.775–776（EICAS 表）、p.1599（着陸時の抑止表）、ATA23 p.121（SELCAL チャイムの抑止論理）。
  - この PC の X-Plane 12 の `Resources/plugins/DataRefs.txt`・`Commands.txt` で、無線と audio panel の dataref・コマンドを確かめた（行番号は §6 に書く）。
- 型式：FCOM の機番は 109＝旅客機（PW）、405＝改造貨物機（PW）、570＝貨物機（GE）（FCOM p.5 (0.1.1)）。通信の違いは旅客機か貨物機かによるもので、エンジン型式（PW/GE/RR）とは関係しない。シムは旅客機（客室オブジェクト、PA 音声のバンク）なので 109 を基準にし、405/570 の違いは括弧で添える。ただし 3D の CALL パネルは貨物機型（U/D、CREW REST L/R、CARGO、GND の灯）で、FCOM p.432 (1.23.2) の図と同じ並び。
- コード：`plugins/xtlua/scripts/B747.15.xt.com/B747.15.xt.com.lua`（3,862 行。以下 `com.lua`）、`plugins/xtlua/init/scripts/B747.15.com/B747.15.com.lua`（565 行。以下 init）。関連：`B747.90.xt.lighting.lua`（ACP・RTP・CALL パネルの灯）、`B747.87.xt.warning.lua`（CAS 表）、`B747.68.xt.fms.lua`・`B744.fms.pages.lua`・`acars/*.lua`（ACARS、AutoATC）、`B747.01.xt.manipulators.lua`（頭上のスイッチ）、`747-400_cockpit.obj`（操作部）、`objects/747_cockpit/Cockpit_Pedestal1.obj`（灯とノブ）、acf 末尾の RTP 表示（`747-400_custom.acf:130244-130600`、純正 acf も同じ）。

## 2. 構成

### 2.1 機器

| 機器 | 数・場所 | 要点 | 根拠 |
|---|---|---|---|
| VHF 送受信機 | 3（L/C/R） | どの RTP からも同調できる。109/405：L・R は音声専用、C は音声か ACARS データ（通常はデータ）。570：3 台とも音声/データ。405/570 は 8.33 kHz 間隔（109 は資料に記載なし） | FCOM p.714 (5.20.2) |
| HF 送受信機 | 2（L/R） | アンテナ共用。片方の音声送信中はもう片方が止まり、同時に使えるのは受信だけ。570 は HF もデータ可 | FCOM p.715 (5.20.3) |
| RTP | 3（後方 aisle stand） | 本来の組：左＝VHF L・HF L、右＝VHF R・HF R、中央＝VHF C | FCOM p.686 (5.10.4), p.714 |
| ACP | 機長・F/O・第 1 observer は aisle stand、第 2 observer は側壁（109/570） | 送信選択、受信、PTT、選択器 | FCOM p.713 (5.20.1); ATA23 p.8 |
| AMU | 1（MEC） | 機長・F/O・第 1 observer のカードと interface card。全音声の振り分け、SELCAL・ACARS・CIC の呼出と解除、CMC への BITE | ATA23 p.6, p.34, p.76 |
| SELCAL decoder | 1 | 5 チャンネル（VHF L/C/R、HF L/R）を監視。自機の符号は 16 本のプログラムピン | ATA23 p.108, p.117, p.124 |
| CIC・PCP（109） | 各 1 | 客室インターホンの中枢と操縦室の呼出パネル（16 文字表示、9 ボタン） | ATA23 p.171, p.196, p.200 |
| PAC | 1 | 機内放送。操縦室からの放送は priority 1 | ATA23 p.288, p.308 |
| マイク・ヘッドセット・スピーカー | 各席 | boom mic、hand mic、酸素マスク mic、headphone、機長・F/O のスピーカー、操縦輪の MIC/INT スイッチ | FCOM p.688–691; ATA23 p.24, p.42 |
| CVR | 1 | ACP で選んだ送受信音と area mic を常時記録 | FCOM p.713 |

### 2.2 電源

| 負荷 | バス | 根拠 |
|---|---|---|
| VHF L、左 RTP、captain interphone | main battery bus（通常 DC 3。AC 3 か DC 3 を失うと main hot battery bus、BATTERY ON が条件） | FCOM p.819 (6.20.25), p.820 |
| F/O・service・cargo（貨物機）interphone、PA | APU battery bus（切替は上と同じ） | FCOM p.820 (6.20.26); ATA23 p.90 |
| HF L | captain transfer bus（AC 3、失えば AC 1） | FCOM p.800 (6.20.6) |
| HF R | F/O transfer bus（AC 2、失えば AC 1） | FCOM p.800 |
| SELCAL decoder | 28 V DC bus 3 | ATA23 p.108 (23-28) |
| ACP の CALL・MIC・受信灯 | master dim & test の 28 V DC（パネル照明は 5 V AC） | ATA23 p.18, p.54 |
| 機長席の音声（牽引時） | main hot battery bus、ground handling bus、APU battery bus のどれか（towing power と standby power のスイッチで決まる） | ATA23 p.20 |
| VHF-L DIRECT（570） | main battery bus | ATA23 p.22 |
| CIC・LAC・PCP | cabin interphone の CB（PCP は CIC から 28 V DC）。バスは資料に記載なし | ATA23 p.184, p.264 |
| VHF C、VHF R、中央・右 RTP、observer の interphone、ACARS MU、SATCOM | 資料に記載なし | — |

- ACARS は電源が確立すると使える（FCOM p.715 (5.20.3)）。
- 推定（上の表から）：AC が無くバッテリーだけのときに乗員が使えるのは、VHF L・左 RTP・機長の interphone と、F/O の interphone・PA。HF は transfer bus なので AC が要る。

## 3. 操作と表示

### 3.1 ACP（FCOM p.683–685 (5.10.1–3)）

| 操作部・表示 | 働き |
|---|---|
| Transmitter select（VHF L/C/R、FLT、CAB、PA、HF L/R、SAT L/R） | 押すと MIC 灯（白）が点き、他の MIC 灯は消える。その席の送信先は 1 つだけ。手動で受信を入れていなければ受信も入る。109：CAB を 3 秒以内に 2 回押すと選んだ客室ステーションへ priority call。109：ACARS 運用中は VHF C を ATC 音声に使わない |
| PTT（R/T・中立・INT、ばねで中立） | R/T：boom mic か酸素マスク mic を選んだ送信先へキー。INT：flight interphone へキー |
| VOR/ADF receiver selector | VOR L、VOR R、ADF L、ADF R |
| Navigation filter（V/B/R） | V：音声、B：音声と識別符号、R：識別符号（モールス） |
| MIC lights（白） | 選んだ送信先 |
| CALL lights（白、チャイム付き） | CAB（旅客機）、FLT、ACARS（VHF C、109/405）、上部デッキ crew rest・main deck cargo（FLT、570）、SATCOM（SAT）、SELCAL（VHF/HF）。送信選択を押すと消え、選択済みなら MIC/INTERPHONE スイッチで消える。SATCOM は通話終了まで点灯。PA には CALL が無い |
| Receiver lights（緑） | 受信を手動で入れたことを示す |
| Receiver volume controls | 押して ON、回して音量、もう一度押して OFF。その送信先を選んでいるか、RTP の ACTIVE が 121.500 なら OFF にならない |
| SPKR（機長・F/O） | 押してスピーカー ON、回して音量、もう一度押して OFF。働くのは機長・F/O の ACP だけ（ATA23 p.32） |
| APP receiver selector | APP L/C/R（ILS L/C/R）、MKR |

### 3.2 RTP（FCOM p.685–688 (5.10.3–6), p.714–716）

| 操作部・表示 | 働き |
|---|---|
| Offside tuning light | (a) 本来の組でない無線機を同調している、(b) 本来の組の無線機を他の RTP が同調している、(c) 405 のみ：他の RTP が OFF |
| ACTIVE window | 同調中の周波数。109/405：VHF C がデータモードなら ACARS。570：VHF/HF がデータモードなら DATA |
| STANDBY window | 予備周波数。109/405：transfer を押すと VHF C がデータモードになる状態なら ACARS（570 は DATA） |
| HF SENS | 回してその側の HF の感度。RTP の故障や OFF の影響を受けない。右 RTP は右 HF があるときだけ、中央は不作動 |
| OFF switch / OFF light（白） | 押すと RTP を無線機から切り離し、点灯 |
| AM switch / AM light（白） | 選んだ HF の AM と USB を切り替える。点灯＝AM、消灯＝USB |
| Frequency transfer switch | STANDBY を ACTIVE に移して無線機を同調し、ACTIVE を STANDBY へ |
| Frequency selector | 外側＝小数点の左、内側＝右。STANDBY を設定する |
| Radio tuning switches / lights（白） | 押して同調する無線機を選び、その active/standby を表示。570：VHF を押し続ける間は squelch 解除 |

### 3.3 その他の操作部

| 操作部 | 働き | 根拠 |
|---|---|---|
| Flight deck speaker（上部側壁） | ACP の SPKR で制御 | FCOM p.688 |
| Headphone・boom mic（4 席） | ACP の音量で聞く。405 は ANR スイッチ | FCOM p.689 |
| Hand microphone | PTT を押して ACP で選んだ系統へ | FCOM p.690 |
| 酸素マスク mic | マスク収納箱の左扉が開くと有効で boom mic は無効。扉を閉めて RESET/TEST を押して離すと boom mic に戻る | FCOM p.684, p.691, p.713 |
| 操縦輪の MIC/INT | MIC：選んだ送信先、INT：flight interphone。中立が OFF。109/570 は INT もばねで中立へ戻る（405 は記載なし） | FCOM p.691 |
| SERV INT（109）/ SERV INTERPHONE（405/570） | ON で service と flight interphone をつなぐ | FCOM p.692 |
| CARGO/CABIN INTERPHONE（405/570） | ON で cargo（570 は upper deck も）と flight interphone をつなぐ | FCOM p.693 |
| OBS AUDIO SYSTEM（CAPT/NORM/F/O） | CAPT：observer の ACP を機長の mic・headset・headphone・マスク mic・スピーカー・PTT につなぐ。F/O も同様 | FCOM p.693–694 |
| CAPT AUDIO SYSTEM（570：NORM / VHF-L DIRECT） | AMU を通さず機長の boom mic と PTT を VHF L へ直結。音量調整なし | FCOM p.708; ATA23 p.22 |
| Pilots' interphone handset（109、aisle stand 後方） | PA PTT と reset | FCOM p.694 |
| VOICE RECORDER（405）・CVR panel | AUTO：最初のエンジン始動から最後の停止 5 分後まで記録、空中は常時 | FCOM p.705–707 |
| Printer | ACARS の印刷 | FCOM p.710–712 |

### 3.4 呼出パネル

- 109 の PCP（FCOM p.695–697）：NXT（保存した呼出の確認、呼出が無ければ directory）、1–6 と P（2 桁の dial code）、RST（取消）、表示（呼出元/呼出先の場所と code、保存数、CABIN READY、PA IN USE、PILOT ALERT、VIDEO IN USE、PARTY LINE）。CAB の送信選択か handset を外すと有効になる（FCOM p.721）。
- 405/570 の CALL パネル（FCOM p.697–698）：U/D（570：上部デッキにチャイム、405：不作動）、CREW REST LEFT/RIGHT（570：受信で点灯、押すと crew rest の handset の Flight Deck スイッチが点灯しチャイム、405：不作動）、GND（nose wheel well からの呼出で点灯、押すと nose wheel well で 3 秒のホーン）、CARGO（main deck cargo からの呼出で点灯、押すと loadmaster panel などに点灯とトーン）。

### 3.5 EICAS メッセージ（FCOM p.775–776 (5.40.1–2)）

| メッセージ | 種類 | 条件 | 型式 |
|---|---|---|---|
| >DATALINK AVAIL | advisory | 一時的に失った ACARS 能力が回復 | 全 |
| >DATALINK LOST | advisory | 通信を失って ACARS が使えない | 全 |
| >DATALINK SYS | advisory | ACARS システムの故障 | 全 |
| >HF DATA | advisory | 選んだ HF が故障し ACARS データに使えない | 570 |
| RADIO TRANSMIT | advisory | VHF か HF が 30 秒以上キーされている | 570 |
| >SATCOM | advisory | SATCOM の故障 | 全 |
| >SATCOM DATA | advisory | SATCOM 経由の ACARS データが使えない | 全 |
| >SATCOM VOICE | advisory | SATCOM 音声が使えない（データは可）。音声系の故障による | 全 |
| >SATVOICE AVAIL | advisory | 一時的に失った SATCOM 音声が回復 | 全 |
| >SATVOICE LOST | advisory | SATCOM 音声を一時的に失った（故障以外の理由） | 全 |
| ACARS MESSAGE | memo | CDU で ACARS を見る必要がある、または受信メッセージあり | 全 |
| ATC MESSAGE | memo | ATC の上りメッセージ受信。低いレベルのチャイムを伴う（FCOM p.725） | 405, 570 |
| HF DATA OFF | memo | 選んだ HF が音声モードでデータに使えない | 570 |
| PRINTER MESSAGE | memo | ACARS メッセージを印刷中 | 全 |
| SATCOM CALL | memo | 地上からの音声呼出 | 全 |
| SATCOM MESSAGE | memo | CDU の SATCOM ページに通話状態の情報あり | 全 |
| VHF DATA OFF | memo | 109/405：VHF C が音声モード。570：全 VHF が音声モード | 全 |

- advisory に音は無い（表の Aural 欄が空）。

### 3.6 データリンクの乗員側（CDU 画面は FMS 担当）

- CDU MENU の `<ACARS`・`<SAT`（全 CDU、通常は中央 CDU で見る）（FCOM p.718 (5.20.6)）。
- 109/405 の ACARS は VHF C か SATCOM 経由で、VHF 圏外では自動で SATCOM に切り替わる。通信できない間の送信は保存し、回復すると自動で送る（FCOM p.715–716）。
- VHF C のデータモード（109/405）：transfer switch で選択/解除し、ACTIVE に ACARS と出ている間がデータモード。405：VHF C の standby を active に移すと standby 窓に ACARS が出て、新しい周波数を選ぶと置き換わり、範囲外の周波数を選ぶと ACARS に戻る。データモード中の VHF C は音声に使えない。109：データモードを外しても ACARS は動いており、故障時に音声へ干渉しうるので VHF C での ATC 音声は禁止（FCOM p.716 (5.20.4)、L.10 p.80）。
- CDU の DATA LINK 状態は READY / NO COMM / VOICE / FAIL（FCOM p.757 (5.33.33), p.772 (5.34.2)）。VOICE の意味は資料に記載なし（推定：データに使う VHF が音声モード）。
- 405/570：ATC datalink は CDU で行い、上りメッセージで memo ATC MESSAGE と低いレベルのチャイム。ADS は自動（FCOM p.725 (5.33.1)）。
- PILOT RESPONSE（405/570、109 は SB で装備）：FMC が MCP、EFIS/EICAS control panel、CDU と VHF/HF の PTT の操作を監視する（FCOM p.1559 (15.20.13)）。

### 3.7 手順での扱い

- preflight：OBSERVER'S AUDIO SYSTEM NORM、SERVICE INTERPHONE OFF、CARGO INTERPHONE as needed（405/570）、CAPTAIN'S AUDIO SYSTEM NORM（570）、VOICE RECORDER as needed（405）（FCOM p.95, p.104–105）。RTP L/C/R は Set で OFF 灯が消えていることを確認、ACP は as needed（FCOM p.112–113, p.117）。
- 酸素試験：FLIGHT INTERPHONE の送信選択、SPEAKER ON、PTT を INT にして酸素の流れる音をスピーカーで聞く（FCOM p.164 (SP.1.4)）。
- 制限：給油中は HF を使わない（FCOM p.77 (L.10)）。109：ACARS が動いている間は VHF C を ATC 音声に使わない（FCOM p.80）。
- FCTM：北緯 82 度以北は SATCOM が使えず、HF と HF SELCAL を事前に手配する。地上で SATCOM を使うには IRU の整列が要る（FCTM p.135 (4)）。

## 4. 内部ロジック

### 4.1 無線機と RTP

1. 無線機は active・standby の周波数とモード（音声/データ）、HF は AM/USB を持ち、どの RTP が表示しているかに関係なく動き続ける（推定：FCOM p.714 の「どの無線機もどの RTP からも操作できる」から）。
2. RTP は押した無線機を選び（灯）、その active/standby を表示する（FCOM p.687）。複数の RTP が同じ無線機を選べるかは資料に記載なし（推定：選べる。offside の条件 (b) がそれを前提にしている）。
3. offside 灯：§3.2 の (a)(b)(c)（FCOM p.686, p.714）。
4. ノブは STANDBY だけを変え、transfer で入れ替えて無線機を新しい active に同調する（FCOM p.687）。
5. OFF：RTP を無線機から切り離し、OFF 灯を点ける（FCOM p.686）。切り離した後も無線機は最後の周波数で動くと推定（FCOM p.714 が RTP 故障時の切り離し手段としているため）。OFF 中の表示は資料に記載なし。
6. 121.5 MHz：ACTIVE が 121.5 になると RTP が AMU に discrete を送り、その VHF の音声は全席で受信ノブを押さなくても聞こえる（ATA23 p.26, p.64）。その受信は OFF にできない（FCOM p.685）。
7. VHF C のデータモードは §3.6。HF：周波数を変えた後に初めて送信すると antenna tuning のトーンが聞こえ、7 秒を超えたら同調失敗（FCOM p.715）。片方の HF の音声送信中はもう片方が止まる。感度は on-side の RTP のノブだけで変わる（FCOM p.715）。
8. stuck mic：地上で VHF が 35 秒を超えて送信すると警告のビープの後に止まり、マイクスイッチを離すと戻る（FCOM p.715）。570 は 30 秒以上で RADIO TRANSMIT（FCOM p.775）。

### 4.2 ACP と AMU の音声経路

1. 送信選択は席ごとに 1 つ（スイッチは電気的に interlock）。押すと MIC 灯と、その系統の受信が受信ノブの音量で入る。ACP に電源が入った時点では送信選択なし（ATA23 p.30, p.54）。
2. 受信は push-on/push-off で、何をいくつ入れてもよい（ATA23 p.31）。送信選択中と 121.5 のときは OFF にできない（FCOM p.685）。緑灯は手動で入れたことを示すので、送信選択で自動的に入った受信では点かない（推定：FCOM p.683, p.685 の書き方から）。送信選択を外したときに自動で入った受信が切れるかは資料に記載なし。
3. PTT：R/T（ACP の PTT、操縦輪の MIC、hand mic）で、選んだ送信先へ mic 音声と PTT を送る（ATA23 p.56, p.59）。INT（ACP の PTT、操縦輪の INT）は送信選択に関係なく flight interphone へ送る。INT の音声は送信選択の回路を迂回するので、他席は FLT の受信を入れていなくても聞こえる（ATA23 p.31, p.44, p.60）。第 1 observer は hand mic と ACP の PTT だけ（ATA23 p.56）。
4. マイク：hand mic は headset か mask mic の音声と合成される。マスク収納箱が開くと mask mic に切り替わり、閉めて reset スイッチを押すと headset mic に戻る（ATA23 p.59）。
5. スピーカーの減衰：機長か F/O がキーし、酸素マスクを使っていなければ両スピーカーを減衰する（ハウリング防止）。OBS AUDIO が NORM 以外なら第 1 observer の PTT も対象（ATA23 p.60, p.62）。
6. 航法受信：VOR/ADF から 1 つ、ILS/MKR から 1 つを選ぶ。V は 1020 Hz を除く notch filter、R は 1020 Hz だけを通す band filter、B は素通し。MKR はフィルターを通らない。DME は R と B のときだけ聞こえ、EFIS が APP なら ILS、VOR・MAP・PLAN なら VOR の音声と組になる（pairing は on-side の CDU から）（ATA23 p.28, p.32, p.71–72）。
7. 受信音の和は headset、スピーカー、CVR へ行く（ATA23 p.62）。
8. OBS AUDIO：CAPT なら機長の入出力を第 1 observer のカードへつなぎ替え、機長は observer の ACP を使う。F/O も同じ。observer の PTT と音声出力はリレーを通らないので、observer は選択を聞ける（ATA23 p.36, p.74）。
9. VHF-L DIRECT（570）：main battery bus で emergency communication relay を付勢し、機長のジャックパネルを VHF L に直結する。つながるのは VHF L の音声、boom mic、機長 ACP の R/T PTT。音量は最大固定（ATA23 p.22）。

### 4.3 CALL 灯とチャイム

1. 呼出元：
   - SELCAL：decoder が 5 チャンネルを監視し、自機の符号で該当無線機の call を latch する。AMU が全 ACP のその CALL 灯を点け、MAWEA にチャイムを要求する（ATA23 p.104, p.108, p.117）。符号は 4 文字（2 組のトーン）で、1 組目の検出は 2 秒保持されて 2 組目と AND（ATA23 p.117）。
   - ACARS：音声通話の要求を受けると、VHF C の SELCAL と同じ扱いで VHF C の CALL（ATA23 p.68; FCOM p.684 の 109/405）。
   - CAB：attendant からの呼出（dial 31 など）で CIC が CAB の CALL、PCP の場所表示、チャイムを出す（ATA23 p.171; FCOM p.722）。
   - FLT：nose wheel well（P37）の flight deck call スイッチで全 ACP の FLT CALL（ATA23 p.40; FCOM p.719）。貨物機は GND 灯も点き、570 は crew rest と wing station からも（FCOM p.704, p.709, p.720）。
   - SAT：SATCOM の着信（FCOM p.684）。
2. リセット：MIC が消えていればその送信選択スイッチを押す、点いていればその席の PTT（INT を除く）を押す。どの席で解除しても全 ACP の灯が消える（ATA23 p.68, p.112, p.118）。FLT の CALL は ACP の PTT の INT でも消える（ATA23 p.31）。FCOM は「送信選択を押すか、選択済みなら MIC/INTERPHONE スイッチ」と書く（FCOM p.684）。
   - FLT（地上員）は 30 秒（旅客機）、60 秒（貨物機）で自動的に消える（FCOM p.719–720）。CAB は pilots' interphone handset を取り上げても消える（FCOM p.722）。SAT は通話終了まで（FCOM p.684）。
3. チャイム：MAWEA の crew alerting card が SELCAL・ACARS・CIC の要求でチャイムを出す（ATA31 p.218）。音は 580 Hz の 1 打の減衰音（low chime）で、aural の中で優先度が最も低い（ATA31 p.160）。FCOM は attendant call のチャイムを「Hi Chime」と呼ぶ（FCOM p.1588 ほか）。音の種類は資料で食い違う（§9）。
4. チャイムの抑止：
   - FCOM：attendant call の Hi Chime は、離陸では「いずれかのエンジンが離陸推力域」から 400 ft RA まで、着陸では 800 ft RA から 75 kt まで抑止（FCOM p.1588 (15.20.42), p.1590, p.1593, p.1596, p.1599 (15.20.53)–p.1601）。
   - ATA：(N1 > 離陸推力 かつ 地上) または (空中 かつ RA < 800 ft) のとき SELCAL のチャイムを抑止（ATA23 p.120–121）。この抑止は cabin、SELCAL、ACARS のチャイムに共通（ATA31 p.218）。
   - 違い：離陸後の解除（FCOM 400 ft、ATA 800 ft）と着陸後の解除（FCOM 75 kt、ATA は接地）。乗員に見える挙動なので FCOM の区間を採り、SELCAL・ACARS にも同じ区間を使う（ATA31 p.218 に従う）。抑止中に来た呼出で、解除後にチャイムが鳴るかは資料に記載なし（CALL 灯は点く）。

### 4.4 interphone と PA

1. flight interphone：各席の音声と地上員の音声（P37 と MEC の jack）を AMU の interface card で混合する（ATA23 p.66）。
2. service interphone：19 個の jack を前・中・後の 3 群にまとめ、AMU で増幅して戻す。SERV INT が ON なら flight interphone と混合（ATA23 p.84, p.88, p.90, p.98）。
3. cabin interphone（109）：
   - 操縦室からは CAB 送信選択（boom/mask/hand mic）か handset。相手は PCP で dial（FCOM p.721）。
   - 優先順位：pilot alert（PP）＞ all call（55）＞ priority line（33）＞ attendant all call（54）＞ 通常（ATA23 p.206, p.220）。上位の呼出は下位を切る（FCOM p.721）。pilot alert は priority call を上書きできるが、操縦室の PA は上書きしない（FCOM p.721; ATA23 p.208）。
   - priority line は primary station（通常 DR 1L）だけ。dial 33 か、CAB を 3 秒以内に 2 回押す（FCOM p.721; ATA23 p.214）。
   - dial 31 は同時に 3 者まで（PARTY LINE 表示）。超えた呼出は busy になり場所を保存し、「W」と件数を表示、NXT で順に見る（FCOM p.722）。CIC が保存するのは最大 4 件（ATA23 p.196, p.226）。
   - PCP の表示：PA IN USE（PA 中）、VIDEO IN USE、CABIN READY（6P）、PILOT ALERT。呼出が 5 分無いと表示を消す（ATA23 p.224, p.246–250, p.260）。
   - 操縦室のチャイム：通常の呼出、all call、cabin ready、pilot alert で low chime（ATA23 p.211, p.218, p.224, p.240, p.260）。pilot alert のチャイム回数は構成で 0–8 回（ATA23 p.280）。
   - 地上員の呼出：109 は PCP で P1（nose wheel well のホーン）、貨物機は GND で 3 秒のホーン（FCOM p.698, p.719; ATA23 p.172, p.220）。
4. PA：操縦室からは PA 送信選択と R/T（boom/mask）か hand mic。PA の受信ノブで sidetone を聞く（FCOM p.720; ATA23 p.308, p.326）。優先順位は ACP からの操縦室 ＞ direct access ＞ priority（全エリア）＞ 通常（FCOM p.720）。操縦室からの放送は全エリア（ATA23 p.308）。PA 中は PCP に PA IN USE（ATA23 p.376）。客室サインの変化で PA に low chime（ATA23 p.317）。PA の音量はエンジン運転・空中・Vmo–15 kt・減圧で段階的に上がる（ATA23 p.289, p.323–324）。

### 4.5 ACARS / データリンク（乗員側）

- EICAS：通信を失うと >DATALINK LOST、回復で >DATALINK AVAIL、システム故障で >DATALINK SYS。109/405 は VHF C が音声モードなら memo VHF DATA OFF。未読メッセージや CDU 操作要求で memo ACARS MESSAGE（FCOM p.775–776）。
- ACARS の音声通話要求は VHF C の CALL とチャイム（§4.3）。

## 5. 他系統とのつながり

- 電源：§2.2。ELEC の作り直しで出すバス単位の通電（ATA-24 ノートの ELEC-02）を読む。必要なのは main/APU battery bus、CAPT/F/O transfer bus、DC 3。
- 航法受信（ATA 34、航法担当）：ACP に VOR L/R、ADF L/R、ILS L/C/R、MKR、DME L/R の音声が入る（ATA23 p.28）。DME pairing は EFIS のモードから CDU 経由（ATA23 p.28, p.71）。シムでは VOR L/R を X-Plane の NAV3/NAV4 に同調している（`B744.fms.pages.lua:2562-2563`、`irs/rnav_system.lua:76-85`）。ILS は NAV1/NAV2 と推定（AFDS が nav1/nav2 の LOC/GS を使う：`B747.70.xt.autopilot.lua:187-215`）。
- 警報（ATA 31、警報担当）：チャイム要求と抑止の入力（air/ground、N1 の離陸推力域、RA、速度）、EICAS メッセージ、PILOT RESPONSE の PTT 入力。
- FMC / ACARS（FMS 担当）：CDU MENU、VHF C のデータモード、ACARS の音声要求 → VHF C の CALL、DATA LINK 状態、memo。
- 酸素（ATA 35）：マスク収納箱の扉 → mask mic。SP の酸素試験（FCOM p.164）。
- 照明（ATA 33）：ACP の灯は master dim & test の明るさで、lights test で全点灯（ATA23 p.54）。シムは照明モジュールが `laminar/B747/annunciator/brightness_ratio[126–250]` に出す。
- 客室（23-3x）：PA、PCP、客室サインのチャイム。
- 外部：X-Plane の ATC（COM1/COM2、`audio_com_selection`、PTT コマンド）、AutoATC（`autoatc/*`、左 RTP の選択、左 ACP の送信選択、`ap/toggle_sw_pos[0]`、COM の周波数と電源。音声コマンドは `sim/cockpit/radios/com1_freq_hz`：`plugins/AutoATC/voice commands/voice_control.json`）、Hoppie（CPDLC）。
- トランスポンダ（航法担当、インターフェースのみ）：`B747.30.fltMgmt` が `laminar/B747/flt_mgmt/transponder/*`・`txpdr/mode_sel_pos`・`transponder_code/*` を持ち、com モジュールとは独立。NP では RTP・ACP と続けて「Transponder panel Set」（FCOM p.113）。

## 6. 実装上の注意

### 6.1 X-Plane 12 で使えるもの

- 通信機は COM1/COM2 だけ（COM3 は無い）。VHF L ↔ COM1、VHF R ↔ COM2 の対応は残す（パネルの RTP 表示、AutoATC、音声コマンドが COM1/2 を読む）。VHF C と HF は Lua の中だけの無線機（周波数とモードを持つが音は無い）にするしかない。
- `sim/cockpit2/radios/actuators/audio_com_selection` は 6=COM1、7=COM2 だけ。9=none があるのは `audio_nav_selection` のほう（DataRefs.txt 4695–4697 行）。
- 副操縦士側の audio panel がある：`audio_selection_*_copilot`、`audio_volume_*_copilot`、`audio_com_selection_man_copilot`、コマンド `sim/audio_panel_copilot/*`、聞く側の切替 `sim/audio_panel/use_pilot_audio`・`use_copilot_audio`、`sim/operation/sound/radio_copilot_audio_panel_volume_ratio`（DataRefs.txt 3542, 4723–4750 行、Commands.txt 1652–1684 行）。機長の ACP を pilot 側、F/O の ACP を copilot 側に写せば、3 枚の ACP を連動させる必要は無い。observer の ACP は OBS AUDIO スイッチに応じて機長か F/O の代わりに写す。
- NAV3/NAV4 の音声（`audio_selection_nav3/nav4`、`audio_volume_nav3/nav4`）、DME（`audio_selection_dme1/dme2`、`audio_dme_enabled`、音量 `dme1/dme2`）がある（DataRefs.txt 4705–4722 行）。X-Plane の航法音声は識別符号だけと推定されるので、V（voice）＝航法音声を消す、B・R＝出す、DME は B・R だけ、で近似できる。
- PTT：`sim/operation/contact_atc_ptt`（Contact ATC の PTT）と `sim/operation/intercom_ptt`（Commands.txt 2932–2934 行）。送信中かどうかは `sim/atc/com1_tx`・`com2_tx`・`user_aircraft_transmitting`（DataRefs.txt 583–596 行）で読めるので、stuck mic や RADIO TRANSMIT に使える。
- `sim/atc/company_msg`（未読 ACARS）と `sim/atc/unread_cpdlc_msg`（DataRefs.txt 597–598 行）もある。X-Plane 内蔵のデータリンクとつなぐかは FMS 担当と決める。
- X-Plane は acf の `_esys_bus_bit_add/rel_navcom1`・`rel_navcom2 = 5`（推定：bus 1 か 3）で COM1/2 の通電を決めている（両 acf 同じ：`747-400_custom.acf:72998-72999`、`747-400.acf:83287-83288`）。ELEC の作り直し後は、Lua 側で `com1_power`・`com2_power` を実機のバスで決める。

### 6.2 表示（acf パネルと obj）

- RTP の 2 つの窓は acf の generic instrument。`laminar/B747/comm/rtp_X/lcd_to_display` が 0 なら COM1、1 なら COM2 の active/standby（`com*_frequency_hz_833`、`com*_standby_frequency_hz_833`）、99 なら INOP の絵、98 なら ACARS の絵（中央 RTP の ACTIVE 窓だけ）を出し、それ以外は何も出さない（`747-400_custom.acf:130244-130600`）。HF や VHF C の周波数を出すには計器の追加が要る（カスタム acf のみ、要承認）。追加しないなら「HF と VHF C 音声は INOP、VHF C データは ACARS」が限界。
- 灯は照明モジュールが `annunciator/brightness_ratio` の 126–250 に出す（RTP 126–149、ACP L 150–181、C 182–213、R 214–245、CALL パネル 246–250：`B747.90.xt.lighting.lua:1449-1594, 1919-2060`）。明るさは `max(bus_volts[0], bus_volts[2])` と IND LTS、lights test で全点灯。obj が使うのは 127–250 で、126（左 RTP の offside）は使われていない。
- ボタンの押し込みは `laminar/B747/ap/button_sw_pos[30]`（左 0–9、中央 10–19、右 20–29。各 vhf_L, vhf_C, vhf_R, flt, cab, pa, hf_L, hf_R, sat_L, sat_R の順）、PTT は `ap/toggle_sw_pos[3]`（+1＝R/T、−1＝INT。obj は [0] と [2]、AutoATC は [0] を読む）。

### 6.3 簡略化してよいもの・いけないもの

- 簡略化してよい：AMU のカード構成と BITE、牽引時の電源、CVR、プリンター、SATCOM（>SATCOM 系の EICAS を含む）、cargo intercom、VHF-L DIRECT（3D に無い）、HF の伝搬と antenna tuning、SELCAL のトーン復号（呼出の入口だけ用意）、PCP の directory と party line の細部、PA の音量制御、客室側の呼出。
- 簡略化してはいけない：席ごとの送信選択と受信（他席を巻き込まない）、無線機と RTP の独立（表示を変えても無線機は止まらない、OFF は切り離すだけ）、offside 灯の条件、AM は HF のモード切替であること、送信選択中・121.5 で受信を切れないこと、CALL 灯の点灯と解除の規則（全 ACP 共通）、チャイムの離着陸抑止、EICAS の FCOM の文言と条件、電源の割当（特に main battery bus の VHF L と左 RTP）。

## 7. 現状実装との比較（GAP 候補）

### 7.1 現状の実装の要点

- RTP：VHF L を選ぶと `lcd_to_display=0`（COM1）、VHF R で 1（COM2）、それ以外（VHF C、HF L/R、AM）は `comm/acars` が 0 なら 99、1 なら 98。毎フレーム、どれかの RTP が VHF L を表示していれば `com1_power=1`、いなければ 0（COM2 も同じ）（`com.lua:3369-3427`）。ノブは表示中の COM の standby を X-Plane のコマンドで動かす（`com.lua:472-568` ほか）。OFF は `off_status=1`・`lcd_to_display=90`（`com.lua:413-423`）。offside は (a)(b) を実装（`com.lua:3463-3494`）。
- ACP：送信選択は MIC 状態と、その受信の状態（緑灯にも使う）を 1 にする。VHF L/R だけは押すと他の 2 枚の ACP の同じボタンのコマンドを呼ぶ（`com.lua:892-924, 1610-1642, 2311-2343`）。X-Plane の送信は「どの ACP でも VHF L なら 6、そうでなく VHF R なら 7、それ以外は 9」（`com.lua:3551-3564`）。受信は COM1・COM2・NAV/ADF・MKR を 3 枚の OR で X-Plane に渡す（`com.lua:3598-3670`）。VOR/ADF・APP の選択器と VHF L/R・VOR/ADF・APP/MKR の音量は 3 枚で同じ値（`com.lua:1178-1220, 1222-1297, 1496-1601`）。V/B/R、SPKR、VHF C・HF・SAT・FLT・CAB・PA の音量と受信は状態だけ。
- PTT：位置のアニメーションだけ（`com.lua:1145-1176, 1864-1882, 2565-2583`）。CALL 灯の状態を書く処理はどこにも無い。電源の判定も無い。
- 他モジュール：照明が状態を灯にする。FMS が `comm/acars`（ACARS provider がオンラインなら 1）を出し、`rtp_C/off_status` で ACARS の可否と memo を決める（`B747.68.xt.fms.lua:1240-1265`、`B744.fms.pages.lua:38`）。AutoATC provider が左 RTP の選択と左 PTT を読み、左 ACP の送信選択を書き換える（`acars/autoatcProvider.lua:316-358`）。
- com モジュールに WXR パネルの処理が同居している（`laminar/B747/wxr/buttons/*` の 5 コマンド、TEST、受信処理の中の WX gain の補正：`com.lua:3018-3050, 3599-3607`）。

### 7.2 GAP 表

行番号は特記なければ `com.lua`（`plugins/xtlua/scripts/B747.15.xt.com/B747.15.xt.com.lua`）。

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

件数：高 1、中 9、低 6（計 16）。ACF_DIFF.md に通信の項目は無い。パネルの RTP 表示と `_esys` の bus bit は両 acf で同じなので、acf による挙動の差は無い。

## 8. 作り直しか部分修正か

**ロジック側（`com.lua`）は作り直しを勧める。init 側の dataref・コマンドの名前はそのまま使う。**

- 3,862 行の大半は「3 枚 × 13 系統 × ハンドラ 4 種」の複写で、モデルと呼べる部分は `B747_lcd_display_status`・`B747_radio_sel_swap`・`B747_xmt_sel_swap`・`B747_radio_audio_status` の約 300 行しか無い。複写の誤りが既に複数ある（COM-11・12・14）。
- 主な誤り（COM-01・02・04）は「無線機の状態が無い」「席の状態が無い」という構造から来ており、部分修正では連動のための回り道が増えるだけ。表駆動（無線機の表、RTP の表、ACP の席の表、呼出の表）にすれば 800–1,200 行程度に収まる（推定）。
- 外とのつながりは少なく明確：INTERFACES.tsv の名前、照明が読む状態、FMS と AutoATC が読み書きする状態、X-Plane の COM1/2。名前を守れば中身だけを入れ替えられる。
- 守るもの：
  - INTERFACES.tsv の `laminar/B747/ap_{L,C,R}/*`（`xmt_sel_switch`、`audio_sel_switch`、`ptt/sel_switch_up|dn`、選択器の `sel_dial_up|dn|pos`、`audio_vol`）、`laminar/B747/comm/ap_*/*_audio/vol_up|dn`、`laminar/B747/rtp_*/*`、`laminar/B747/comm/rtp_*/{freq_MHz,freq_khz}/sel_dial_pos`・`hf_sens_ctrl/rheostat`・`lcd_to_display`、`laminar/B747/ap/button_sw_pos`・`toggle_sw_pos`（§6.2 の index と符号）、`laminar/B747/toggle_switch/{srvc_interphone,observer_audio_left,observer_audio_right}`、`laminar/B747/wxr/buttons/*`（WXR は航法担当へ移すか残すかを決める）。
  - `lcd_to_display` の値の意味（0、1、98、99）。表示を増やすならパネル側の追加と一緒に新しい値を足す。
  - 他モジュールが読む状態：`comm/rtp_*/{off_status, vhf_L_status …, offside_tuning_status}`、`ap_*/*/{xmt_status, audio_status, call_status}`、`call_pnl/*/call_status`（照明）、`rtp_C/off_status`（FMS）、`rtp_L/vhf_L|vhf_R_status`・`ap_L/{vhf_L,vhf_R,flt}/xmt_status`・`ap/toggle_sw_pos[0]`（AutoATC）、`comm/acars`（FMS が作る）、`com/init_CD`・`ai/com_quick_start`（AI）、`debug/com`。
  - AutoATC provider が左 ACP の送信選択を書き換える処理（COM-06）は、com モジュールに「PTT の状態」と「各席の送信先」を出させ、provider は読むだけにする（FMS 担当と調整）。
- 構成案：① 無線機（VHF L/C/R、HF L/R：active・standby・モード・AM・電源・送受信中）→ ② RTP（選択、OFF、offside、表示値）→ ③ ACP の席（送信選択、受信と音量、選択器、フィルター、SPKR、PTT）→ ④ X-Plane への写像（機長 → pilot の audio panel、F/O → copilot、observer は OBS AUDIO で置き換え、COM1/2 の電源と周波数）→ ⑤ 呼出（入口：SELCAL・ACARS・CAB・FLT・SAT のコマンド/dataref、全 ACP 共通の latch、解除、警報モジュールへのチャイム要求と抑止）→ ⑥ EICAS の状態（datalink、VHF DATA OFF、ACARS 系の memo の整理）。
- 規模：com モジュール単体は M（数日）。電源（ELEC 後）、警報（チャイム・EICAS）、FMS/AutoATC、照明への波及を含めると M〜L。急ぐなら S の COM-01・04・11 を先に直し、本体は作り直しで置き換える。HF・VHF C の周波数表示はパネルの追加（カスタム acf、要承認）が要るので別に判断する。

## 9. 未確認事項

1. X-Plane 12 の ATC がどの COM で送信するか（`audio_com_selection` か `audio_selection_com_auto` か）、`contact_atc_ptt` が選択中の COM を使うか、`audio_com_selection` に 9 を書いたときの挙動。
2. pilot/copilot の audio panel：X-Plane が座席や視点で聞く側を自動で切り替えるか、どちらを聞いているかを読む dataref があるか。
3. NAV3/NAV4 の識別符号が `audio_selection_nav3/nav4` で実際に聞こえるか。ILS L/C/R と X-Plane の受信機の対応（航法担当）。
4. パネルの `BUS_SRC 4` と acf の `_esys_bus_bit_add = 5` の意味（どのバスで RTP 表示と COM1/2 が落ちるか）。シムで、バッテリーだけのとき・バスを落としたときの RTP 表示と COM の受信を確かめる。
5. AutoATC や Hoppie から SELCAL や音声通話要求（CALL 灯の入口）を受け取れるか。
6. 3D：左 RTP の offside 灯が本当に描かれないか、CALL パネルが貨物機型で押しボタンが無いこと、F/O の HF R・SAT R の音量ノブが下がらないことをシムで確認する。
7. 資料に記載なし：VHF C・VHF R・中央/右 RTP・observer の interphone・ACARS MU・SATCOM の電源バス、OFF 中の RTP 表示、送信選択を外したとき自動で入った受信が切れるか、抑止の解除後にチャイムが鳴るか、VHF/HF の周波数範囲、電源投入時の RTP と無線機の状態、DATA LINK の VOICE の意味、109 の 8.33 kHz の可否（シムは 8.33 kHz のコマンドを使う）。
8. 資料の食い違い（採った側）：チャイムの音（FCOM「Hi Chime」/ ATA31 の low chime。音は FMOD の範囲で、ロジックは同じ）、抑止の区間（FCOM 400 ft・75 kt を採用 / ATA 800 ft・接地）、CALL の解除（FCOM「MIC/INTERPHONE スイッチ」、ATA は SELCAL は INT を除く PTT・FLT は INT でも可。ATA の区別を採る）、offside の条件 (c) は 405 だけ。
9. AutoATC を使わない利用者に「ACARS NO COMM」の代わりに >DATALINK LOST を常時出すのか、ACARS 未装備として何も出さないのか（利用者の判断）。
