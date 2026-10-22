# FCTM 操縦技法の要点と自動試験シナリオ案

2026-10-23 作成（Phase 0-B）。コードは読んで比較していない（GAP 表なし）。Part 2 の「観測手段」だけ、現行コードの dataref 名を確認した。

## 0. 概要

- 目的
  - Part 1：FCTM の技法のうち、実装が再現しなければならない「乗員の操作」と「その前提になっている機体の応答」をまとめる。
  - Part 2：FlyWithLua か X-Plane Web API で回す自動試験の標準フライトを、スクリプトに起こせる粒度で定義する。
- 読んだ範囲
  - FCTM（2006-10-31 版 Rev.5、FCTM p.1）全頁：前付け p.1-27（改訂記録 p.15-23）、1章 p.28-71、2章 p.72-87、3章 p.88-120、4章 p.121-143、5章 p.144-211、6章 p.212-247、7章 p.248-275、8章 p.276-318（p.311-318 は索引）。
  - 図表は画像で確認した：FCTM p.65, 90, 96, 109, 110, 113, 115, 155, 167, 168, 185, 195, 199, 205, 223, 225, 233, 253, 257。
  - FCOM（照合）：L.10 p.75-84（p.77-78 は画像）、NP.11 p.87-94、NP.21 p.95-154、SP p.155-219。
  - FCOM（シナリオの観測点のため追加）：4.10 p.639-640, 655-657、4.20 p.659-675、4.30 p.677、6.10 p.789-793、6.30 p.821-823、7.20 p.877-880、7.30 p.895-897、7.40 p.899-902（p.902 は画像）、9.20 p.951-954、9.30 p.957-958、11.20 p.1227-1228、11.31 p.1253-1269、11.32 p.1271-1273、11.41 p.1325-1342、11.42 p.1345-1353、11.43 p.1389-1392、11.60 p.1429-1435、13.10 p.1483-1485、13.30 p.1495、14.20 p.1515-1516、14.30 p.1521-1522、15.30 p.1603-1605。
  - 電源の切替と EICAS は ATA-24.md を参照した（同じ資料を読み直していない）。
- 資料の扱い
  - FCTM と FCOM が食い違えば FCOM を採る（FCTM p.7 (0.2.1)）。食い違いは §1.11 にまとめた。
  - FCTM の図と数値は訓練用の典型値（FCTM p.7 (0.2.1)）。試験では目安として使い、資料に許容幅が無いものは `推定` と書いた。
  - FCTM はエンジン型式によらない。FCOM の型式別の記述は 109（PW 旅客）を採る（ATA-24.md と同じ方針）。GE を選んだときは 570 の値を当てる（推定）。RR は FCOM が無く、FCTM にだけ RR の値がある（初期 EPR、逆推力を絞り始める速度）。
  - FCOM に非常操作のチェックリスト（QRH/NNC）は無い（REFERENCE_INDEX）。FCTM が「QRH を見よ」とする手順の中身（RTO maneuver、エンジン故障の NNC など）は `資料に記載なし`。

## Part 1 要点

### 1.1 自動化の使い方（全段階に共通）

- 分担
  - MCP は PF の担当。手動飛行中は PF の指示で PM が操作する（FCOM p.89 (NP.11.3); FCTM p.64 (1.34)）。
  - 手動飛行中でも、ATC の HDG/ALT と flap に伴う速度は PM が指示なしで設定してよい。ただし「HEADING 170 SET」のように宣言する（FCTM p.64 (1.34)）。
  - A/P 使用中は PF がモードを選ぶ。PM は高度を設定してよいが PF に知らせる（FCTM p.64 (1.34)）。
  - CDU：地上ではどちらが入力してもよく、もう一方が確認する。地上走行中は PM。飛行中は通常 PM が入力し、相手の確認後に EXEC（FCOM p.89 (NP.11.3); FCTM p.57 (1.27)）。高負荷時は CDU より MCP の HDG/ALT/SPD を使う（FCOM p.89）。
- 確認の作法
  - MCP の値を変えたら計器に反映されたことを確かめ、モード変化は FMA で確認してコールする（FCOM p.90 (NP.11.4)）。
  - LNAV/VNAV 中は進路・経路・推力・速度の変化を確認する（FCOM p.90）。
- 自動化の水準
  - 思ったように動かなければ水準を下げる。例：holding の exit を選び忘れたら HDG SEL。VNAV が上昇・降下中に予期せず水平になったら、FMC を直すまで FLCH（FCTM p.64 (1.34)）。
  - すぐ水平にしたいときは A/P を切って手で止め、MCP 高度と pitch mode を設定してから A/P を入れ直す。A/P に逆らって操縦したら速やかに切る（FCTM p.65 (1.35)）。
  - A/P を入れるのはトリムが取れ、F/D の指示が満たされ、経路が安定しているときだけ（FCTM p.63 (1.33)）。離陸後は 250 ft 未満で入れてはならない（FCOM p.79 (L.10.3); FCTM p.112 (3.24)）。
  - A/T は離陸と上昇では手動・自動飛行とも使う。それ以外の段階は A/P 使用中だけ使う（FCTM p.63 (1.33)）。
- 推奨モード
  - LEGS と map が正しければ LNAV/VNAV。VNAV を使わないときは FLCH（小さな高度変更でも浅く上昇・降下する論理があり、乗客のために V/S を使う必要はない）。予定外の速度・高度制限が続く到着では FLCH か V/S（FCTM p.65 (1.35)）。
  - FCTM 本文は「次の表のモードを推奨」と書くが、PDF に表は無い（p.65 を画像で確認）。
- MCP の不具合（スイッチ故障。故障表示が出ないことが多い）
  - A/P を切り、両 F/D を OFF にすると全モードが消える。A/P か F/D を入れ直すと既定モードに戻る（FCTM p.65 (1.35)）。飛行中の既定は pitch V/S、roll HDG HOLD（109 はバンク 5° 超なら ATT）（FCOM p.639-640 (4.10.1-2)）。
  - 代わりのモード（FCTM p.66 (1.36)）：HDG SEL/HOLD 不良→手で水平にして A/P を入れ直す（その方位を保つ）。LNAV 不良→HDG SEL で航路をなぞる。上昇降下の VNAV 不良→FLCH か V/S（final は V/S）。巡航の VNAV PTH 不良→ALT（直接選べなければ FLCH で自動的に ALT へ）。LOC 不良→LNAV と raw data。G/S 不良→V/S か VNAV PTH と raw data。
- FMC の予測
  - 性能予測は通常形態が前提。gear・flap・spoiler を出した形態では上昇降下経路と燃料の予測は使えない。ただし進入の VNAV PTH は使える（FCTM p.57-58 (1.27-1.28)）。holding 可能時間は clean と flaps 1 で正しい（FCTM p.58）。
  - ルートの確認：計画の総距離・到着時燃料を PROGRESS ページと比べる。洋上は LEGS の各区間を照合する（FCTM p.57 (1.27)）。
- RNP
  - RNP 運航には LNAV が必須。ANP が RNP を超えると警報。XTK ERROR が大きくても警報は出ない（FCTM p.59 (1.29)）。
  - RNP 0.15 以下は A/P と LNAV が前提で、VNAV PTH 必須の進入もある。A/P が使えなければ F/D と、10 NM 以下のレンジにした map を使う（FCTM p.60 (1.30)）。
  - RF leg：直接 RF leg に入らない。FMC が故障すると RF leg は route discontinuity になる（FCTM p.61 (1.31)）。
  - RNAV 進入は DME-DME か GPS の更新が有効なこと。RNP 警報を持たない FMC でも RNP 0.5 の進入は飛べる（FCTM p.62 (1.32)）。
- 表示の分担：気象と地形の恐れがあれば、一人は WXR、もう一人は terrain を見る（FCTM p.63 (1.33)）。synoptic は燃料量を除き手順に含まれない（FCTM p.33 (1.3)）。
- status：preflight で確認し、エンジン始動後は見なくてよい（必要なものは EICAS の alert に出る）。停止後に見る（FCTM p.31 (1.1); FCOM p.88 (NP.11.2)）。

### 1.2 速度と flap の基準

- flap 機動速度（全重量。FCTM p.34-35 (1.4-1.5)）

  | flap | 機動速度 |
  |---|---|
  | UP | VREF30+80（309,000 kg / 680,000 lb 超は VREF30+100） |
  | 1 | VREF30+60 |
  | 5 | VREF30+40 |
  | 10 | VREF30+20 |
  | 20 | VREF30+10 |
  | 25 / 30 | VREF25 / VREF30 |

  - この速度なら stick shaker まで 40° 以上のバンク余裕（25° + overshoot 15°）がある（FCTM p.34 (1.4)）。
  - 309,000 kg 超では flaps up のままバンク 15° 以下、VREF30+100 まで（FCTM p.34, p.113 (3.25)）。FCOM は「UP+20 kt まで」と書く（FCOM p.132 (NP.21.38)）。UP は VREF30+80 なので同じ値。
  - FMC load 16 以降は CDU preflight で APPROACH REF の flap/speed 行が消える（それより前は離陸前に空欄であることを確かめる。値があると重量ではなくその値で flap 速度を出す）（FCTM p.34 (1.4)）。
- flap の操作：上げるときは「次の位置の速度以上で、かつ加速中」に選ぶ。下げるときは「今の位置の速度を割る前」に選ぶ（FCTM p.35 (1.5)）。
- command speed（FCTM p.43-44 (1.13-1.14)）
  - 離陸：V2。乗員が変えるか、FLCH/VNAV が入るまでそのまま。FLCH なら速度を上げて加速させる。
  - 上昇・巡航・降下：VNAV なら FMC、そうでなければ MCP。進入：選んだ flap の機動速度を MCP で。
  - 着陸：A/T 使用時は VREF+5（A/T は速度低下に速く、超過に遅く反応するので、風の補正は不要）。A/T を使わないときは VREF に「定常向かい風成分の半分＋ガスト分全部」を足す。上限 VREF+20、下限 VREF+5。向かい風成分の半分は、正面 50 %、45° 35 %、真横 0 % で近似。ガスト分は接地まで保ち、定常分は接地に向けて減らす。追い風では補正しない（VREF+5）。
  - 例（滑走路 360°）：360/16 → +8、無風 → +5、360/20G30 → +20、060/24 → +6、090/15 → +5、090/15G25 → +10。
  - NNC が指定する「adjusted VREF」（例 VREF30+20）は新しい VREF として扱い、A/T を使わなければさらに風の補正（5〜20 kt）を足す（FCTM p.44 (1.14)）。
- speed bug：V1/VR/V2 と重量を入れると V1・VR・V2 と次の flap の上げ速度が出る。V2 は MCP で設定する。V2 で 30° のバンク余裕（15°+15°）。着陸 flap と VREF を入れると VREF と、今の flap・次の flap の機動速度が出る（FCTM p.45 (1.15)）。
- 標準コール（FCTM p.46-50 (1.16-1.20)）
  - 共通：「TRANSITION ALTITUDE/LEVEL, ALTIMETERS RESET」、「1000 FT TO LEVEL OFF」、「10,000/FL100」。
  - ILS：「LOCALIZER ALIVE」「GLIDE SLOPE ALIVE」「OUTER MARKER/FIX ___ FT」「500 FEET」＋autoland status（「LAND 2/LAND 3/NO AUTOLAND」）、「APPROACHING MINIMUMS」（DA の 100 ft 上）、「ALERT HEIGHT」（fail operational）、「MINIMUMS」、PF「CONTINUE」か「GO AROUND」、PF「LANDING」。
  - 離陸：「80 KNOTS」「V1」「ROTATE」。自動コールが無ければ PM が RA 100/50/30 ft をコール（FCTM p.46）。

### 1.3 地上（taxi）

- taxi 前：駐機位置が FMC に入っていることを両者で確認（FCTM p.75 (2.3)）。pushback は全油圧加圧、nose wheel steering lockout で行う（FCTM p.74 (2.2)）。
- 推力：taxi はおおむね idle で足りる。動き出しだけ少し上げ、反応を待つ。逆推力で後退するのは禁止（FCTM p.76 (2.4); FCOM p.82 (L.10.6)）。
- 速度：通常 約 20 kt、長い直線は 30 kt まで（20 kt 超で tiller を過大に使わない）。高速離脱路より大きく曲がるときは乾燥路面で約 10 kt。約 30° を超える旋回は入る前に 10 kt 以下（FCTM p.77 (2.5), p.79 (2.7)）。最大重量で 15,000 ft（4,575 m）を超える taxi は最大 20 kt（タイヤ側壁の過熱）（FCTM p.77）。
- ブレーキ：強めの 1 回のほうが軽い何回より摩耗が少ない。引きずらない（FCTM p.77 (2.5)）。antiskid 不作動ならごく軽いブレーキで済む速度にする（FCTM p.77）。
- V speeds を入れた後に逆推力を選ぶと、速度計の V speeds が消え、離陸推力の上限が full TO になる（FCTM p.77 (2.5)）。
- steering：tiller は低速で全範囲、rudder pedal steering は限られた範囲。body gear steering は nose gear 角が 20° を超え、速度が約 20 kt 未満で自動的に働く（FCTM p.78 (2.6)）。操縦席は nose gear の 2.2 m、main gear の 29.3 m 前（FCTM p.79 (2.7)）。180° 旋回は停止、tiller 一杯、外側エンジンだけで 5〜10 kt（FCTM p.81 (2.9)）。
- 悪天候：滑りやすい面では減速。低温では steering を左右に動かして油を温める。氷結条件の地上 run-up は FCOM どおり。低温で slush・水たまりを通るとき、氷点下で降水があるときは flaps up で taxi（FCTM p.85 (2.13); FCOM p.204 (SP.16.4)）。
- 一部エンジン停止の taxi：出発時は推奨しない。到着後は 3 発なら 3 番、2 発なら 2・3 番を止める（FCTM p.85-86 (2.13-2.14)）。

### 1.4 離陸

- 準備
  - before start で TAKEOFF REF を確認し、MCP に V2。map・LEGS・CLB ページの制限を出発方式と照合（FCTM p.91 (3.3)）。
  - PF は CDU に TAKEOFF REF（V speeds がすぐ見える）、PM は LEGS を出す。離陸直後の上昇制限の変更は MCP で行う（FCTM p.91; FCOM p.118 (NP.21.24)）。
  - secondary EICAS は通常消しておく（FCTM p.91）。
- 推力の設定（FCTM p.92-94 (3.4-3.6); FCOM p.129-131 (NP.21.35-37)）
  - A/T と F/D を全離陸で使う。F/D は浮揚まで追わない。
  - rolling takeoff を推奨：滑走路に正対したら tiller を離し、約 1.10 EPR（PW）／約 70 % N1（GE）まで進め、安定したら TO/GA を押す。RR は 1.2 EPR まで可（FCTM のみ）。停止しての離陸は brake を保持して安定を待つ。安定待ちが約 2 秒を超えると離陸距離に響く。
  - 横風 20 kt 超・追い風 10 kt 超は rolling takeoff を強く推奨（エンジン surge 防止）（FCTM p.99 (3.11)）。
  - 目標推力は 80 kt までに設定（微調整は 80 kt 直後まで可）。強い向かい風で 80 kt までに推力に届かなければ手で進める（FCOM p.131 (NP.21.37)）。向かい風 20 kt 以上では推力が整う前に HOLD になることがある（FCTM p.94 (3.6)）。
  - 推力設定後の多少の N1/EPR の差では中止しない。設定後の超過は 400 ft AGL 以上まで絞らない（絞ると性能が成り立たない）（FCTM p.93 (3.5)）。
  - HOLD：PM は離陸推力と HOLD を確認する。HOLD 中 A/T はレバーを動かさないが手では動かせる。HOLD は VNAV が入るか別の推力モードを選ぶまで続く。HOLD が出なくても故障が無ければ何もしない（FCTM p.94 (3.6)）。
  - 浮揚後に TO/GA を押すと最大推力（THR REF）（FCTM p.94）。VMCG で制限される離陸では、非常時以外は固定 derate を超えない（FCTM p.94）。
- 滑走（FCTM p.93 (3.5)）：tiller は 30 kt 超で使わない（20 kt 超は注意）。軽く操縦桿を前に押す。rudder は 40〜60 kt で効き始める。機長は V1 まで推力レバーに手を置く。PM は 80 kt をコールし、PF は自分の速度計と照合（ピトー閉塞の早期発見）。
- 引き起こし（FCTM p.95-97 (3.7-3.9)）
  - 80 kt を過ぎたら操縦桿を中立へ。VR で 15° に向けて滑らかに連続して引き起こす。平均 約 2.5°/s、浮揚まで 3〜5 秒。引き起こし中は stabilizer trim を使わない。F/D の pitch は引き起こしに使わない。浮揚後は F/D が主な pitch の目安。
  - 典型図：VR から約 4 秒で浮揚、約 6.5 秒で 35 ft、V2+10（p.95 の図）。
  - 尾部クリアランス：flaps 10 は浮揚姿勢 10.1°・最小 39 in（99 cm）、flaps 20 は 10.0°・40 in（102 cm）。脚伸びきりで尾部接地する姿勢は 12.5°（FCTM p.96 (3.8)、画像で確認）。
  - V2+10 を過ぎても引き起こさないと、F/D の目標は引き起こし時の速度（最大 V2+25）になる。遅い・浅い引き起こしは 35 ft までの距離が最大 700 ft 延びる（FCTM p.97 (3.9)）。
  - 突風が VR 付近で来たら、引き起こしを少し待つ。早く・速く引き起こさない（FCTM p.101 (3.13)）。
  - 後方 CG・軽量では 80 kt まで前に押して nose wheel steering を効かせる（FCTM p.98 (3.10)）。
- 初期上昇（FCTM p.111 (3.23)）
  - 浮揚後は姿勢指示器が主。F/D は別の pitch mode が入るまで V2+10〜V2+25 を指示する。V2+10 が最適。超えたら加速を止めるが V2+10 まで戻さない。
  - 高度計で正の上昇率を見てから gear up。浮揚後にブレーキは踏まない（gear UP で自動的に止まる）。
  - 離陸直後の旋回は 400 ft AGL 以上で、T/O flap のまま V2+10〜V2+25。V2+10 なら最大バンク 25°（FCTM p.111 (3.23)）。
  - 最少燃料での離陸：main tank の pump に low pressure が出ても pump を切らない。急加速を避け、機首上げ姿勢を最小にする（FCTM p.111）。
- roll / pitch mode（FCTM p.112 (3.24)）
  - LNAV を離陸前に arm しておけば 50 ft AGL 以上で入る。arm していなければ 400 ft AGL 以上で選ぶ。経路が滑走路端から始まらなければ 400 ft で HDG SEL。出発方式が flight plan に無ければ HDG SEL/HOLD。
  - VNAV は離陸前に arm し、400 ft AGL で入るのが標準の使い方（加速と flap 上げが計画どおりになる）。
  - A/P は 250 ft AGL 以上で入れられる（FCTM p.112; FCOM p.79 (L.10.3)）。
- 加速と flap 上げ（FCTM p.112-113 (3.24-3.25); FCOM p.132 (NP.21.38)）
  - 訓練では 1,000 ft AFE で推力を減らし加速を始める。路線では騒音対策で、推力減少は約 1,500 ft AFE、加速は 1,500〜3,000 ft AFE。flap 上げの最低高度は 400 ft（FCTM p.42 (1.12)）。
  - VNAV（加速高度を地上で入れておく）が推奨。VNAV が加速を指令するので、flap を計画どおり上げ、EICAS の推力基準が TAKEOFF REF で選んだ点で TO から CLB に変わるのを確かめる。climb thrust は通常 flaps 5 で入る。
  - VNAV を使わなければ、加速高度で FLCH、command speed を flaps up 機動速度 +20 kt。flaps 5 で MCP の THR を押して CLB にし、TO→CLB を確認する。
  - 上げる順序（T/O flap 20 か 10）：speedtape の「10」（VREF30+20）で 10、「5」（+40）で 5、「1」（+60）で 1、「UP」（+80）で UP。T/O flap 10 なら「5」から（FCTM p.113, 画像で確認; FCOM p.132）。flaps up の機動は少なくとも「UP」。
  - 騒音対策：推力減少と加速の高度を TAKEOFF REF に入れ、騒音経路を満たすまで flaps up 機動速度を保つ（CLB ページの速度制限、speed intervention、FLCH のどれか）（FCTM p.113 (3.25)）。
  - 離陸図（FCTM p.90 (3.2)、画像）：thrust set（手で進めて安定、TO/GA）→ 滑走（80 kt までに推力、軽く前押し）→ VR → 正の上昇率で gear up → 400 ft RA 以上で roll mode → thrust reduction height で climb thrust → acceleration height で flap 上げ → flaps up で After Takeoff checklist。
- 減推力離陸（FCTM p.101-102 (3.13-3.14)）
  - ATM：最大推力の 25 % 減まで。EPR/N1 は制限値ではなく、windshear などでは full まで手で進めてよい。汚染滑走路と windshear の恐れがあるときは使わない（wet は性能を考慮すれば可）。
  - 固定 derate（TO 1 / TO 2）：制限値として扱う。全エンジンで推力が要る場合（windshear）以外は超えない。片発故障後に増すと方向保持を失うおそれ。
  - 併用：derate からさらに 25 % まで。improved climb は flaps 20 のみ。
  - FCOM：汚染滑走路では固定 derate は可、ATM（単独・併用）は不可（FCOM p.201 (SP.16.1)）。
- 横風と悪条件
  - 横風の目安（FCTM p.99 (3.11)）：dry 40、wet 25、standing water/slush 15、雪（融解なし）15、氷（融解なし）15 kt。FCOM は「最大離着陸横風 30 kt（制限ではない）」（FCOM p.77 (L.10.1)）→ §1.11。
  - slush・standing water・wet snow は 0.5 in（12.7 mm）、乾雪は 4 in（102 mm）まで（FCTM p.103 (3.15)）。FCOM は 1/2 in（13 mm）、4 in（102 mm）（FCOM p.201 (SP.16.1)）。
  - 低視程離陸は RVR 500 ft/150 m、条件を満たせば 300 ft/75 m（FCTM p.103）。凍結滑走路で rudder が効く前に centerline を保てなければ直ちに中止（FCTM p.104 (3.16)）。
- 離陸中止（RTO）
  - 約 80 kt までは軽微な不具合（Master Caution、異常振動、タイヤ破損）でも止める。中止の判断は V1 前に。V1 後の中止は機体が飛べないと機長が判断したときだけ（FCTM p.105-106 (3.17-3.18)）。
  - V speeds が消えていても他に異常が無ければ続ける。PM が V1・VR をコール。VR が分からなければ表示中の V2 の 5〜10 kt 前で引き起こす（FCTM p.106 (3.18)）。
  - HOLD が出る前に中止したら、レバーを idle にするとき A/T を切る。切らないと手を離したときレバーが離陸推力に戻る。HOLD 後はレバーは idle に留まる。手順をそろえるため、すべての RTO で A/T を切る（FCTM p.106 (3.18)）。
  - 実運用の RTO では逆推力と RTO autobrake を使う（認定データは使わない前提）（FCTM p.104 (3.16)）。RTO 後は brake 冷却を守る（FCTM p.107 (3.19)）。
  - 遅れの影響（FCTM p.109-110 (3.21-3.22)、重量大・乾燥）：基準（片発、brake＋speedbrake、逆推力なし）に対し、逆推力 2 基で -120 ft、全発・逆推力 4 基で -200 ft、speedbrake なしで +400 ft（端で 55 kt）、speedbrake が 5 秒遅れると +190 ft、V1 の 2 秒後に中止すると +850 ft（端で 75 kt）、片発・逆推力 2 基でも brake 圧 3/4 なら +870 ft（端で 60 kt）、全発・逆推力 4 基でもタイヤ 2 本破裂で +60 ft（15 kt）、乾燥用の重量と V1 を wet で使うと +1,420 ft（80 kt）（p.109-110 は画像で確認）。
  - 手順の中身（QRH の Rejected Takeoff maneuver）は `資料に記載なし`（FCTM p.106 は QRH を参照）。
- 離陸中のエンジン故障（FCTM p.114-119 (3.26-3.31)）
  - VMCA は VR と VREF より低い。故障の兆候はまず偏揺れ。方位を見て rudder で止める。control wheel を傾けたままや過大な aileron trim は spoiler を立てる。
  - V1〜浮揚の故障は推力の落ち方に合わせて rudder。VR で通常より 2〜3° 低い姿勢へ、毎秒 0.5° 遅く引き起こす。典型：約 5 秒で浮揚（10.6°）、10〜12 秒で 35 ft・12〜13°、V2〜V2+10。尾部クリアランス最小 34 in（86 cm）（p.115-116、画像）。
  - 浮揚後：F/D は最低 V2、故障時の速度（最大 V2+10）を指示。V2〜V2+10 で故障したらその速度、V2+10 を超えていたら V2+10 まで減速して flap 上げ高度まで保つ。F/D の roll は LNAV か別の roll mode まで地上航跡を保つ（FCTM p.117 (3.29)）。
  - 火災・分解・限界超過は、操縦が落ち着き、gear が上がり、安全高度（通常 400 ft AGL 以上）で recall 項目を行う。参照項目は flap 上げ後（FCTM p.117; p.284 (8.6)）。
  - 旋回は 400 ft AGL 以上、T/O flap のまま V2〜V2+10。AFDS は（LNAV/HDG SEL、bank limit AUTO で）V2+10 までバンクを 15° に制限する。V2+10 では 25° まで可（FCTM p.118 (3.30)）。
  - A/P は 250 ft AGL 以上、rudder か rudder trim が正しければ入れてよい（FCTM p.118）。
  - flap 上げ：最低 400 ft AGL、訓練は 1,000 ft AGL。VNAV 中ならほぼ水平の加速区間を指令し、flaps up 機動速度+20（VREF30+100）へ。flaps up で VREF30+98 を超えると VNAV が推力上限を CON にする。VNAV なしなら FLCH と flaps up 機動速度+20（F/D はほぼ水平を指令）。F/D なしならほぼ水平に pitch を下げる。加速に合わせて rudder を調整し、trim で踏力を抜く（FCTM p.118 (3.30)）。
  - flaps up 後、VNAV でなければ THR を押して CON を確かめ、障害物クリアの高度まで上昇。NNC → After Takeoff checklist（FCTM p.118-119 (3.30-3.31)）。エンジン故障後は騒音対策は不要（FCTM p.119）。
  - 2 発目の故障：推力を増す。同じ側の 2 発なら低速では外側を少し絞る。aileron lockout 速度以上では A/P の aileron が足りず手動になることがある（FCTM p.117 (3.29)）。
  - ATM 離陸での故障：推力を増す必要はないが、地上では手で、空中では TO/GA で full まで増してよい。固定 derate（併用を含む）では、地形衝突が迫らない限り derate を超えない（FCTM p.119 (3.31)）。

### 1.5 上昇・巡航・降下・待機

- 上昇
  - 減推力上昇：THRUST LIM で CLB 1（10 %）、CLB 2（20 %）。離陸の減推力に応じて FMC が自動で選ぶ。上昇率が約 500 fpm を下回ったら一段上を選ぶ（FCTM p.123 (4.1)）。FCOM の詳しい規則は §1.11。
  - 上昇制限：方式を選べば自動で入り、手でも入れられる。MCP 高度で水平になると FMC はそれを上昇制限として扱う。「at or below」を含む硬い高度制限はすべて MCP に入れ、制限を満たすか新しい許可が出てから次を入れる（FCTM p.123 (4.1)）。
  - 制限が外れたら、混んだ空域・高負荷時は FLCH か VNAV＋altitude intervention。altitude intervention＝次の高度を MCP に入れて altitude selector を押す。高度制限が消えて MCP 高度まで上昇する（FCTM p.124 (4.2); FCOM p.1256 (11.31.22)）。
  - 低高度での水平：近づくと ALT か VNAV ALT になり、A/T が SPD で目標速度を保つ。TO/GA の pitch のまま捕捉したら SPD を選び速度を入れる。軽量・大推力では浮揚直後に捕捉が始まり行き過ぎることがある：減推力離陸、早めに climb thrust、手で止める、手動推力（FCTM p.124 (4.2)）。
  - 障害物を越えるまで flaps up 機動速度+20、その後すみやかに上昇速度へ（FCTM p.124）。
  - 上昇速度：VNAV の command speed。speed transition altitude より下は、出発空港の transition speed（FAA 空域は 10,000 ft MSL 未満 250 kt）か flaps up 機動速度+20 の大きい方。waypoint の速度制限と CLB ページの高度別速度制限を守る（FCTM p.125 (4.3)）。FCOM は「transition speed か VREF+100 の大きい方」（FCOM p.667 (4.20.9), p.1328 (11.41.4)）→ 重量大では差がある（§1.11）。
  - ECON 上昇：一定 CAS / 一定 Mach（Mach は CRZ ALT の ECON 巡航 Mach）。TOC 重量・風・ISA 偏差・cost index で決まる。通常 250 kt 超（FCTM p.125 (4.3)）。FMC が使えなければ 10,000 ft 未満 250 kt か VREF30+100 の大きい方、以上は 340 kt/0.84M（FCTM p.126 (4.4)）。
  - 最大上昇率は flaps up 機動速度+60 kt で 0.82M まで（FMC は出さない）。最大上昇角は FMC が出し、flaps up 機動速度+20 とほぼ同じ勾配（FCTM p.126）。
  - 片発の上昇：flap 上げと障害物クリアの後に ENG OUT CLIMB。CLB ページの ENG OUT で、CRZ ALT か片発最大高度の低い方まで VNAV が E/O 上昇速度で上昇し、水平後は E/O LRC。速度が上がるまで CON のまま。速度が出なければ flaps up 機動速度+20 と CON（FCTM p.126 (4.4)）。
  - エンジン防氷は氷結条件で AUTO か ON（FCTM p.125, p.141）。
- 巡航
  - 最大高度：構造・推力・buffet（FAA 0.2 g＝33°、CAA/JAA 0.3 g＝40°）の最も低いもの。重量・巡航 CG・温度偏差を正しく入れる。LNAV 以外では amber band の 10 kt 以上上、バンク 10° 以下。amber band を割ったらバンクを減らす・CON まで推力・降下。FMC 最大高度より上では燃料予測も VNAV も使えない（FCTM p.127-128 (4.5-4.6)）。
  - 最適高度：ECON なら最小コスト、LRC/指定速度なら最少燃料。約 1.5 g（48°）の buffet 余裕。2,000 ft 上で約 45°（FCTM p.128 (4.6)）。
  - 巡航速度：既定は ECON（重量・高度・CI・向かい風で変わる。CI 0 は最大航続、CI 5000 以上は推力か最大速度で頭打ち）。LRC は最大航続の 99 %（風補正なし）。RTA もある（FCTM p.129 (4.7)）。最適高度±2,000 ft なら LRC は約 0.86M（-400F は 0.85M）（FCTM p.132 (4.10)）。
  - step climb：燃料が減ると最適高度が上がるので、FMC に step の値を入れて段階的に上げる。FMC の step 点は最小コスト。できるだけ step 点の近くで上昇を始める。RVSM・メートル空域では既定値が合わないので手で入れる。4,000 ft の上昇で追加燃料 500〜650 lb（225〜300 kg）（FCTM p.129-130 (4.7-4.8)）。
  - 燃料温度：Jet A -40 °C、Jet A-1 -47 °C、TS-1/RT -50 °C。冷え方は約 3 °C/h（最大 12 °C/h）。TAT を上げるには高度変更、迂回、Mach 増（0.01M で 0.5〜0.7 °C）。安定まで 15 分〜1 時間。多くは最適高度の 3,000〜5,000 ft 下で足りる（FCTM p.130-131 (4.8-4.9)）。FCOM の限界：離陸前のタンク燃料は -43 °C 以上かつ凝固点+3 °C 以上、飛行中は凝固点+3 °C 以上（109）（FCOM p.81 (L.10.5)）。
  - 燃料の割増（FCTM p.132 (4.10)）：ISA+10 で +1 %、最適高度の 2,000 ft 上で +1〜2 %、4,000 ft 下で +2〜6 %、8,000 ft 下で +6〜14 %、計画より 0.01M 速いと +2 %。説明できない差は燃料漏れを疑う。
  - 片発の巡航・driftdown（FCTM p.133-134 (4.11-4.12)）：rudder と trim で control wheel を水平にして A/P を保つ。VNAV CRZ ページの ENG OUT を選んで即 EXEC。FMC は E/O LRC と CON を指令し、A/T は片発でも働く。降下を遅らせるなら水平高度を MCP に入れ、E/O LRC より遅く（ただし flaps up 機動速度以上で）なってから altitude selector を押す（最も燃料効率がよい）。地形が問題なら MCP を片発最大高度にし、E/O SPD を選ぶ（最も浅い降下、最も高い水平高度）。どちらも不要なら全発 LRC/ECON で、片発最大高度より下を MCP に入れて selector を押す。2 発目の故障では E/O SPD で 2 発停止のデータになり、A/T は働かない。FCOM の詳細は §1.12。
  - 高高度・高速：Mach tuck なし。MMO 付近は抗力が急増する（FCTM p.134 (4.12)）。
  - 極地：LNAV が主な roll mode（heading reference NORM で使える）。HDG SEL/HOLD は TRUE が要る。82°N 以北は SATCOM 不可。GPS 2 基喪失で ANP 増、UNABLE RNP が出ることがある。IRU 1 基だけなら最寄りへ（FCTM p.135-136 (4.13-4.14)）。
- 降下
  - 速度：既定は巡航高度から到着空港の speed transition altitude まで ECON、その下は transition speed の 10 kt 下。LEGS と DES ページの制限で調整。DES ページで Mach・Mach/IAS・IAS に変えられる（FCTM p.137 (4.15)）。FCOM：ECON の目標は 349 kt（VMO-16）を超えない、手入力は 354 kt（VMO-11）まで。減速は transition altitude（通常 10,000 ft 未満 250 kt）で、計画速度は 10 kt 下（FCOM p.1258 (11.31.24)）。
  - 経路：巡航高度より下の waypoint 高度制限が 1 つでもあれば path ができる。最も低い制限から上へ、idle（DESCENT FORECAST の防氷高度より下は approach idle）で作る。風は DESCENT FORECAST の値（FCTM p.137 (4.15)）。
  - 降下制限：必須の高度制限と「at or above」はすべて MCP に入れ、確実になってから次を入れる。浅い区間は A/T が推力を足す。idle より急な区間は speedbrake が要る。巡航高度より下の減速（例 10,000 ft）は約 500 fpm の降下で、T/D での減速は水平で行う（FCTM p.137; FCOM p.1264 (11.31.30)）。
  - speed intervention：VNAV SPD では推力 idle のまま pitch で速度を合わせる。VNAV PTH では speedbrake か推力が要る（FCTM p.137 (4.15)）。
  - offpath descent circle：外円は clean、内円は speedbrake 使用で E/D に届く範囲（FCTM p.138 (4.16)）。
  - 計画：無風・ECON で約 3 NM / 1,000 ft。直進なら滑走路の約 12 NM、横から入るなら約 8 NM で場周高度・flaps up 機動速度。目安は「10,000 ft AGL、30 NM、250 kt」。降下手順は巡航高度を離れる前に始め 10,000 ft MSL までに終える。進入手順は transition level で始める（FCTM p.138-139 (4.16-4.17); FCOM p.136, p.138 (NP.21.42, 21.44)）。
  - 降下率（20,000 ft 未満、idle。FCTM p.138 (4.16)）：0.83M/340 kt で 2,800 fpm（speedbrake 4,300）、250 kt で 1,300（2,100）、VREF30+100 で 1,200（1,900）。
  - 減速：水平で 340→250 kt に約 90 秒・8 NM、さらに flaps up 機動速度まで 13 秒・1 NM。speedbrake で約 40 % 短縮（FCTM p.139 (4.17)）。
  - speedbrake：使用中 PF は手をレバーに置く。推力を上げる前に戻す。flaps 5 を超えて使わない（buffet）。1,000 ft AGL までに格納（FCTM p.139 (4.17)）。FCOM は「flaps 20 を超えて使わない（109）」（FCOM p.83 (L.10.7)）→ §1.11。VMO 付近で A/P 中にすばやく戻すと一瞬 VMO を超える。VMO 付近の高度捕捉でも同じ（FCTM p.140 (4.18)）。
  - 降下率を増すために flap は使わない。gear は防氷で降下率が足りないときや ATC の要求のときだけ。flaps 5 は進入 fix を outbound に向かう前、visual なら downwind に入る直前（FCTM p.140 (4.18)）。
  - ATC の速度指示は ±10 kt で守る（FCTM p.140）。重量大で最小機動速度が制限を超えるなら flap を出すか ATC に許可を求める（FCTM p.140）。
- 待機（FCTM p.141-142 (4.19-4.20)）
  - fix 到着の 3 分前から減速を始め、最初の通過は最大待機速度以下。
  - FMC の待機速度が最大待機速度を超えるなら flaps 1 で flaps 1 機動速度（燃料 約 10 % 増）。FMC の待機速度は flaps up 機動速度を下回らない。氷結・乱気流中は clean。なお FCOM は 20,000 ft より上で flap を出すことを禁じる（FCOM p.82 (L.10.6)）。
  - FMC に入れていなければ outbound は高度に応じて 1 分か 1.5 分。
  - 最大速度：ICAO 14,000 ft 以下 230 kt、14,000〜20,000 ft 240 kt、20,000〜34,000 ft 265 kt、34,000 ft 超 0.83M。FAA 6,000 ft 以下 200 kt、6,001〜14,000 ft 230 kt（ワシントン・ニューヨーク FIR は 210 kt）、14,001 ft 以上 265 kt。
  - PROC HOLD が active なら exit は自動（EXIT HOLD 不要）。残るなら新しい hold を入れる。
  - FMC の速度が無ければ低高度は flaps up 機動速度、FL250 より上は VREF30+100。750,000 lb（341,000 kg）超では buffet 余裕が 1.2 g（33°）に減る。

### 1.6 進入

- 共通（FCTM p.147-153 (5.1-5.7)）
  - LEGS・高度制限・map を管制許可に合わせる。直前の変更は MCP の HDG/ALT で吸収し、LEGS の修正は余裕があるとき。DA(H) か MDA(H) を設定。ILS/VOR/ADF の tune と識別（PFD/ND で周波数が識別符号に置き換わればよい）。course と G/S は flag が無く、pointer が見え、識別が聞こえるときだけ有効。
  - 747 は直進進入で Category D（FCTM p.149 (5.3)）。
  - 安定進入（FCTM p.151 (5.5)）：IMC は 1,000 ft AFE、VMC は 500 ft AFE までに、正しい経路、小さな修正で保てる、VREF〜VREF+20、着陸形態、降下率 1,000 fpm 以下、推力が形態に合う、briefing と checklist 済み。ILS は G/S・LOC とも 1 dot 以内。circling は 300 ft AFE で final に wings level。その高度より下で崩れたら直ちに go-around。threshold 通過時は目標速度 +10 kt 以内（flare で降下を止めるまで）、接地は最初の 3,000 ft か 1/3 の短い方。
  - 必ず missed approach にするとき（目視参照が無い場合）：航法機器や計器の故障、計器の大きな不一致、ILS final で LOC か G/S が振り切れ、RNP 進入で ANP>RNP、レーダー進入で通信途絶（FCTM p.152 (5.6)）。
  - MAP：ILS は DA(H) と G/S。非 ILS は、VNAV path で DA/MDA に達した点、または map 上の VDP/MAP。FMC で位置を出せるので時間計測は主手段ではない（DME-DME 更新中、または UNABLE RNP が出ていなければ不要）（FCTM p.153 (5.7)）。
- ILS（FCTM p.155-161 (5.9-5.15)、p.155 は画像; FCOM p.140-142 (NP.21.46-48)）
  - 進入図：レーダー誘導は HDG SEL、fix へは LNAV/VNAV。flaps 1 → 5（intercept heading に近づいたら 5）。intercept heading で flaps 10（任意）、ILS の tune と識別、LOC と G/S の pointer、APP を arm。LOC 捕捉で heading bug は final course へ。G/S alive で gear down、flaps 20、speedbrake ARM。G/S 捕捉で着陸 flap、missed approach altitude を MCP、Landing checklist。fix（LOM、MKR、DME）で通過高度を確認。500 ft で autoland status を確認。
  - procedure turn fix は flaps 5 機動速度で通過（FCTM p.157 (5.11)）。降下は VNAV（programmed なら）、使えなければ FLCH（FCTM p.157）。
  - LOC へは flaps 5、大きな intercept 角なら flaps 10 と flaps 10 速度で旋回半径を小さくしてよい（FCTM p.157）。
  - speed intervention か SPD のとき、flap を出したら抗力が効き始めた時に次の低い速度を選ぶ（遅いと推力が増え、早いと減ってから増える）（FCTM p.157）。
  - APP を選ぶのは、ILS の tune と識別、inbound の intercept heading、両 pointer が正しい位置、進入許可の 4 つがそろってから（FCTM p.157-158）。
  - G/S は LOC より先に捕捉することがある（405 は LOC 捕捉まで G/S 捕捉を抑止：FCOM p.670 (4.20.12)）。上下どちらからも捕捉できる。LOC への intercept 角が 80° を超えると G/S は捕捉しない。LOC の最大 intercept 角は 120°。不要な G/S 捕捉を避けるには、まず LOC、後で APP（FCTM p.158 (5.12)）。
  - LNAV で final course に入るとき、LOC と平行に飛んで捕捉せず G/S で降下することがある。raw data で LOC 捕捉を確かめる（FCTM p.158; FCOM p.141 (NP.21.47)）。
  - LOC 捕捉で heading bug は自動で inbound course へ動く。捕捉中は 30° までバンク（FCTM p.158 (5.12)）。
  - G/S alive で gear down、flaps 20、flaps 20 速度。G/S 捕捉で FMA を確認、着陸 flap、VREF+5（手動着陸なら VREF＋風補正）、Landing checklist。A/T で接地するなら風補正は不要。G/S に乗ったら missed approach altitude を MCP に。flaps 20 速度を超えて着陸 flap を出すと flap load relief が働き推力が大きく変わる（FCTM p.158 (5.12)）。
  - 偽の G/S：FAF 通過高度、VNAV path、通常の pitch と降下率、3° なら 1 NM あたり約 300 ft HAT で照合（FCTM p.159 (5.13)）。
  - 1,500 ft RA 未満で FLARE と ROLLOUT が arm、autoland status は LAND 3 か LAND 2。AH より上で status が下がり minima が上がったら、目視参照が無い限りその minima より下へ行かない。AH は少なくとも 200 ft HAT。AH より下では、明らかに必要なとき以外は操作しない（FCTM p.159 (5.13)）。
  - 横風の autoland は forward slip で接地時の crab を減らす（FCTM：500 ft RA 以下で始まり slip は 5° まで。強い横風では少し crab が残る。常に風上翼が下がる）（FCTM p.159）。FCOM の詳細は §1.11。
  - A/P と autobrake は、安全に止まると分かり、目視で操縦できる視程になるまで入れたまま（FCTM p.159）。
  - delayed flap（騒音対策）：flaps 20・gear down・flaps 20 速度で G/S を捕捉（推力はほぼ idle）。1,000 ft AFE 手前で着陸 flap を選び、速度が落ちたら推力で保つ。特に騒音が厳しければ flaps 10 で捕捉し、1,000 ft 手前で 20、着陸 flap（FCTM p.159-160 (5.13-5.14)）。
  - raw data（F/D なし）：LOC の目盛りは拡大されない（F/D か A/P で LOC 捕捉中は約 5/8 dot で拡大表示になる）。inbound の追従はバンク 5〜10°（FCTM p.160 (5.14)）。
  - autoland：Cat III の autoland を始めるには全油圧系統が必要。fail operational の進入で AH より下で油圧が 1 系統失われても、NO AUTOLAND が出なければ続けてよい。autoland の flap は 25 か 30。LOC が滑走路中心線とずれている場合は autoland しない（ROLLOUT で滑走路を外れる）（FCTM p.161 (5.15)）。
  - ILS の critical area：米国では ceiling 800 ft 未満か視程 2 mile 未満で保護。保護されていなければ beam の曲がりで急な操舵がありうるので操縦装置に手を添える。AFDS は ILS の干渉を監視し、検出すると誤信号を無視して慣性で姿勢を保つ。続けば PFD に表示（FCTM p.161-162 (5.15-5.16)）。
  - 汚染滑走路では ROLLOUT の性能は保証されない（FCTM p.162 (5.16)）。
  - 低視程：Cat I/II は TDZE の 100 ft より下で red terminating bar か red side row bar が必要。fail passive の Cat III は DH 50 ft 程度。fail operational は AH より下で目視参照の要件なし（FCTM p.163 (5.17)）。
  - Cat II：A/P 1 基でも複数でも F/D でもよい、3 発か 4 発。A/P 1 基なら FCOM の制限高度までに A/P を切り、A/T も切る（FCTM p.164 (5.18)）。Cat IIIa は LAND 2 か LAND 3、IRU 2〜3 基、油圧 4 系統、3〜4 発。Cat IIIb は LAND 3、IRU 3 基、油圧 4 系統、A/T、3〜4 発。Cat IIIb は 4 発か 3 発・flaps 25/30 で認定（FCTM p.164-165 (5.18-5.19)）。
  - AFDS の故障（FCTM p.166 (5.20)）：AH より上では autoland status を確かめ、変わっていなければ（その装備が不要か切り替えられるなら）続行、変わっていれば minima を上げるか go-around。AH 以下では NO AUTOLAND でない限り autoland と rollout まで続ける（200 ft AGL より下では想定されるどの故障でも安全に着陸できる）。AH 以下の master caution/warning では A/P が操縦できていない場合を除き切らない。autobrake の故障なら手でブレーキ。A/P が AH 以下で切れたら目視参照があれば着陸してよい。A/P が切れた状態で go-around するときは TO/GA を押す（押さないと F/D は approach mode のまま）。
  - 進入・着陸・go-around 中の alert への対応（FCTM p.167 (5.21)、画像で確認）

    | alert | 200 ft AGL 超 | 200 ft AGL 未満 | rollout 中 | go-around 中 |
    |---|---|---|---|---|
    | AUTOPILOT DISC（warning） | 手動 go-around（*） | 手動 go-around（**） | 手動 rollout | 手動 go-around |
    | AUTOPILOT（caution） | go-around（*） | go-around（**） | A/P を切り手動 rollout | A/P を切り手動 go-around |
    | AUTOTHROT DISC（caution） | 手動推力で続行（Cat IIIb は ***） | *** | — | 手動推力で続行 |
    | SPEEDBRAKES EXT（caution） | speedbrake を格納 | go-around（**） | — | speedbrake を格納 |
    | NO LAND 3 / LAND 2 | 続行（Cat IIIb なら go-around）（*） | —（表示抑止） | — | — |
    | NO AUTOLAND | go-around（*） | go-around（**） | — | — |
    | ILS deviation alert（G/S・LOC 点滅） | go-around（*） | go-around（**） | — | — |

    （*）目視参照が無ければ。（**）目視参照があれば着陸。（***）AFM か承認手順による。その他の EICAS は QRH。
  - 幾何（FCTM p.168 (5.22)、画像。flaps 30、VREF30+5、典型重量、ILS アンテナが threshold を 50 ft で通過）：G/S 2.5° では機体姿勢 2.5°、主脚 31 ft、目の高さ 67 ft、flare なしの主脚接地点は threshold から 701 ft。3.0° では 2.0°、31 ft、66 ft、584 ft。G/S 送信機は threshold から 954 ft（3°）／1,145 ft（2.5°）。速度が 5 kt 増すごとに姿勢 1° 減（FCTM p.167）。
  - 片発の ILS（FCTM p.168-169 (5.22-5.23)）：AFDS の使い方は通常どおり。複数 A/P では LAND 2/3 が出るまで rudder と rudder trim で偏揺れを抑え、出たら A/P が rudder を受け持つ（LOC と ROLLOUT 中は rudder trim が偏揺れに効かない）。A/P 1 基（APP で 1 基だけ使える機体）や F/D では全区間を乗員が rudder で受け持ち、minimums で A/P を切る。A/T は A/P 中なら使える。故障エンジン側からの横風では sideslip で wings level にし、反対側からの中・強の横風では sideslip を入れない。rudder trim は 500 ft AFE までに中立へ戻してもよい（FCTM p.169）。
  - 2 発停止の ILS（FCTM p.170-172 (5.24-5.26)）：A/T は自動で切れ、再接続できない。gear を出す点が commit point（その後の go-around は試みない）。gear down・flaps 20 で G/S、1,000 ft AGL 手前で flaps 25、VREF25+5 以上か風補正。2 発停止の autoland は認定されていない。rudder trim は約 1,000 ft AGL で中立に戻し、A/P は通常より高めに切ることを考える。
- 非 ILS（FCTM p.173-193 (5.27-5.47); FCOM p.143-146 (NP.21.49-52), p.174-175 (SP.4.4-4.5)）
  - 種類：RNAV、GPS（RNP 0.3 以下、無ければ手入力）、VOR、NDB、LOC 系（LOC、LOC-BC、LDA、SDF、IGS、TACAN）。通常 VNAV か V/S で飛ぶ。CDFA（一定角の連続降下）を使う（FCTM p.173 (5.27)）。
  - VNAV が推奨（LEGS に適切な path がある場合）。V/S は代わりの方法。A/P は目視参照が得られるまで使う（VNAV PTH には path 偏位の警報が無い）（FCTM p.174 (5.28)）。
  - raw data：LOC 系は全区間で監視が必須。FMC で飛ぶ非 LOC 系は、FMC・IRS・GPS が 2 系統ずつあるか RNP/ANP 対応なら監視不要（FCTM p.174-175 (5.28-5.29)）。
  - 推奨 roll mode（FCOM p.143 (NP.21.49)）：RNAV・GPS は LNAV。LOC-BC・VOR・NDB は LNAV。LOC・SDF・LDA は LNAV か LOC。V/S の場合は RNAV・GPS・LOC-BC・VOR・NDB が LNAV か HDG SEL（FCOM p.174 (SP.4.4)）。
  - 進入は database から選ぶ（RNAV・GPS は必須）。FAF〜MAP の間に waypoint を足したり消したりしない（FMC の「on approach」論理が一部または全部働かなくなる）。参照が欲しければ FIX ページ。手入力の waypoint は RNAV・GPS では使わず、FAF 後の VNAV でも使わない（FCTM p.178 (5.32)）。FIX ページの course 線は LNAV で追えない（HDG SEL）。手入力 waypoint では自動 procedure tuning と速度介入つき VNAV PTH が使えない。10,000 ft AGL 未満で map を作らない（FCTM p.179 (5.33)）。
  - VNAV に使える path：約 3°、threshold を約 50 ft で通る。LEGS の final に GP 角が出ているか、RWxx か滑走路手前の MAP（MXxx など）があること。MAP が threshold の先にある VOR 進入と circling 専用の進入は不可。RNP か DA(H) を使う進入では FAF から先を変えない（寒冷時の補正だけ可）（FCTM p.180 (5.34)）。
  - path の作り方（FCTM p.182-184 (5.36-5.38)）：MAP（RWxx/MXxx）の高度から GP 角（通常 3.00°、2.75〜3.77°）で FAF 方向へ上に延ばし、次の制限高度（MAP 手前の「at」高度、次の「at or above」、speed transition か速度制限の高度の低い方、巡航高度のうち最も厳しいもの）で止める。MAP を過ぎると VNAV は水平を指令。FAF に「at」制限があると短い水平区間（fly-off）ができることがある。FACF と FAF がともに「at or above」なら FACF を「at」に変えると減速しやすい。GP 角は ISA より暖かいと実質的に急、寒いと浅い。
  - 準備（FCTM p.186 (5.40)）：ARRIVALS から選ぶ。vector 中は FAF への straight-in intercept course。RNP を確認、baro minimums に DA(H)。MDA(H) を使うなら MDA+50 ft（missed approach で MDA を割らないため）。進入の RNP は最初の進入 waypoint を通過するまで表示されない（手入力か database にあれば別）。
  - 移行（FCTM p.186-187 (5.40-5.41)）：FLCH・V/S で FAF 高度へ降りてきた、または FAF 高度で ALT なら、FAF の約 2 NM 手前で MCP に DA(H)/MDA(H)、VNAV と speed intervention を入れる → VNAV PTH で final を降下。すでに VNAV PTH で降下中なら、そのまま形態を作る（FAF の速度制限まで自動で減速）。約 2 NM 手前で MCP を DA/MDA にし、speed intervention。VNAV SPD なら、path 上か下にいれば FAF 手前で自動で VNAV PTH に変わる。FAF を過ぎて VNAV ALT になったら、すぐ MCP に DA/MDA を入れて altitude intervention。path より上にずれて安定進入が無理なら missed approach。
  - final より前は MCP に次の waypoint の高度制限を入れ、確実になったら次を入れる（不要な水平を防ぐ）（FCTM p.181 (5.35), p.187）。
  - final（FCTM p.187 (5.41); FCOM p.144 (NP.21.50)）：intercept heading に近づいたら flaps 5（任意で 10）、LNAV か適切な roll mode を arm。FAF の約 2 NM 手前、ALT・VNAV PTH・VNAV ALT のどれかが出た後で：A/P を確認、MCP に DA(H)/MDA(H)（100 ft 単位でなければ下の 100 ft）、VNAV を選ぶ（VNAV PTH と roll mode を確認）、speed intervention。PM「APPROACHING GLIDE PATH」、gear down、flaps 20、speedbrake ARM。final の降下開始で着陸 flap、final 速度、Landing checklist。GP 角が FAF より前から始まる進入では、その角に乗った時点で MCP を DA/MDA にしてよい。missed approach altitude の少なくとも 300 ft 下で安定したら MCP に missed approach altitude。FAF で通過高度と高度計を照合。
  - 最終進入の速度は speed intervention で（final の waypoint に速度制限を足さない）（FCTM p.181 (5.35)）。
  - altitude intervention は、VNAV ALT になって path より上にいて降下を続けたいときだけ（MCP を次の制限か DA/MDA にして selector を押す。path の偏位表示は一瞬消える）。on approach 中なら path に戻るまで水平、その後 path を捕捉（FCTM p.181 (5.35)）。
  - minimums（FCTM p.188-189 (5.42-5.43)）：認められていれば VNAV DA(H) か、MDA(H) を DA として使う。認められていなければ MDA(H)（MAP は MDA+50 ft として扱う：FCTM p.154 (5.8)）。DA/MDA で A/P を切り A/T を切って着陸するか、直ちに go-around。目視後は path を保ち、視覚の glide path より下へ行かない。MAP を過ぎると VNAV は水平。FCOM の制限：ILS の G/S と LOC に結合しているか go-around mode でない限り、MDA から 50 ft より下へ降りる前に A/P を切る（FCOM p.80 (L.10.4)）。
  - V/S 進入（FCTM p.190-192 (5.44-5.46); FCOM p.174-175 (SP.4.4-4.5)）：FAF の約 2 NM 手前で gear down、flaps 20。MCP は最初の中間制限か MDA。FAF 以降で V/S を選び、チャートの推奨値（無ければ約 -700〜-800 fpm）。MDA で水平区間を作らない。path の偏位表示、高度弧を VDP に置く、1 NM あたり 300 ft のコールなどで一定角に保つ。MDA の約 300 ft 上で missed approach altitude。MDA を離れるとき A/P と A/T を切り、両 F/D を OFF にしてから PM 側だけ ON（PF に不要な指令を出さず、PM には go-around の指令を残す）。
  - VDP：MDA の HAA ÷ 300 ft/NM。HAA 300/400/450/500/600/700 ft → 1.0/1.3/1.5/1.7/2.0/2.3 NM。VNAV path に乗っていれば DA/MDA 到達点が VDP（FCTM p.193 (5.47)）。
  - VNAV の練習を ILS で行うのは VMC に限る（ISA より暖かいと G/S より少し上、寒いと下になる）（FCTM p.189 (5.43)）。
  - 片発でも非 ILS 進入は全発と同じ（FCTM p.181 (5.35)）。
- circling（FCTM p.195-198 (5.49-5.52)、p.195 は画像; FCOM p.175 (SP.4.5)）
  - gear down、flaps 20、flaps 20 機動速度（任意で 25/30）。circling 速度に合った minima を使う。MDA は ALT HOLD で保ち（00 で終わらなければ到達時に ALT HOLD）、旋回部分は HDG SEL/HOLD。ILS から circling するなら LOC と VNAV か V/S。circling への降下に APP は使わない（MCP 高度で水平にならない、抜けるには go-around か A/P 解除と F/D OFF が要る）。
  - MDA で水平になったら missed approach altitude を設定。base に入る前に着陸 flap、approach 速度＋風補正、Landing checklist。final は threshold の内側の端を狙う。visual profile に乗るまで MDA を割らない。MDA を離れるとき A/P と A/T を切り、profile に乗ったら両 F/D を OFF、PM の F/D を ON。片方の F/D が OFF のまま go-around すると、その側の bar は最初の pitch/roll mode 選択で消える。
  - 障害物クリアの半径：FAA は C 1.7 NM・D 2.3 NM、ICAO は C 4.2 NM・D 5.28 NM。
  - circling 中の missed approach：滑走路の方へ上昇旋回し（180° を超えることもある）、計器進入の missed approach course に入る。近距離の機動が終わるまで missed approach の flap を保つ。
- visual（FCTM p.199-201 (5.53-5.55)、p.199 は画像）
  - 場周 1,500 ft、downwind に flaps 5・flaps 5 機動速度で入り、滑走路から約 2 NM。abeam で flaps 10（任意）。base に入る前に gear down、flaps 20、speedbrake ARM、flaps 20 速度、必要なら降下開始。base で着陸 flap、Landing checklist。base の降下は約 600〜700 fpm。700〜500 ft で profile に安定、final は 2〜2.5 NM。
  - final は 1 NM あたり約 300 ft、降下率 700〜900 fpm、trim を取り、500 ft までに安定。1,000 fpm 超は避ける。進入路は 2.5〜3°（FCTM p.200）。
- touch and go / stop and go（FCTM p.202-204 (5.56-5.58)）：speedbrake は arm しない、autobrake OFF。接地後に教官が flaps 20、stabilizer trim、speedbrake down、レバー vertical の後に推力。VREF で ROTATE、約 15°、VREF+10 で上昇。逆推力を使ったら必ず停止。stop and go は T/O flap、trim、speedbrake down、autobrake RTO、rudder trim、bug を設定。brake の熱は積算される。

### 1.7 go-around と missed approach

- 図（FCTM p.205 (5.59)、画像）と手順（FCOM p.147 (NP.21.53)）
  - 開始：TO/GA を押し「FLAPS 20」（3〜4 発）。go-around 姿勢への回転と推力増を確認、推力が足りなければ調整。PM「POSITIVE RATE」、PF「GEAR UP」。
  - 400 ft RA 超：roll mode を選び、missed approach altitude と経路を確認。
  - 加速高度：FLCH か VNAV（2 発停止は FLCH）。FLCH なら予定 flap の機動速度。VNAV なら必要に応じ speed intervention で機動速度。flap を計画どおり上げる。
  - 予定の flap になったら、FLCH なら THR を押して climb thrust。高度捕捉を確認、gear lever OFF、After Takeoff checklist。
  - 手動の go-around：手で引き起こし、go-around 推力を確認、必要なら A/P を入れる。
- 全発（FCTM p.206-207 (5.60-5.61)）
  - A/P 進入からの go-around は A/P を入れたまま TO/GA。通常の重量では必要推力は最大 go-around 推力よりかなり小さい（windshear 用の余裕）。全推力が欲しければ TO/GA をもう一度押す。
  - 手動進入からは TO/GA、flaps 20、go-around 推力、15° へ滑らかに引き起こし、F/D に従う。
  - 100 ft より上で始めた自動の go-around では約 40 ft 降下する。go-around 開始後に接地しても go-around は続く。接地後、または 5 ft RA 未満が 2 秒続いた後は自動 go-around を始められない。
  - TO/GA の pitch は go-around 姿勢から速度制御に移る（command speed〜+25 kt）。TO/GA の roll は今の地上航跡を保つ。400 ft AGL より下で pitch/roll mode を選んでもモードは変わらない。
  - 複数 A/P の go-around では、400 ft AGL より上で roll か pitch mode を選ぶか高度を捕捉すると A/P 1 基に戻る（FCTM p.207; FCOM p.673 (4.20.15)）。
  - 最初に旋回が要るなら gear up まで済ませてから。旋回が終わり安全高度・適切な速度まで flap を上げない。flap 上げ高度までは command speed を上げない（訓練は 1,000 ft AGL）。flaps up で機動速度に近づいたら THR を押し CLB。
  - VNAV で go-around すると、FMC の missed approach の速度と高度に従う（speed intervention で修正可）。VNAV ALT が出たら早すぎる水平になることがあり、FLCH が要る。代替空港へ向かうなら FMC を直してから VNAV（FCTM p.207 (5.61)）。
  - 軽量で低い高度に止めるとき：A/T を使う、TO/GA は 1 回だけ（約 2,000 fpm の推力）、full 推力なら早めに climb thrust、行き過ぎそうなら手で止める（FCTM p.208 (5.62)）。
- 接地後の go-around（FCTM p.208 (5.62)）：接地前に始めた go-around は接地しても続き、F/D も指示を出し続ける。接地後・逆推力選択前に始めると、レバーを進めたとき auto speedbrake が戻り autobrake が解除される。F/D の go-around は浮揚後に選び直すまで出ない。逆推力を使った後は必ず停止（逆推力が残れば安全な飛行は不可）。
- 片発・2 発停止（FCTM p.208-210 (5.62-5.64)）：片発の go-around は通常と同じ。手動なら rudder と trim。複数 A/P では最初は A/P が偏揺れを抑えるが、400 ft より上で mode を変えると A/P 1 基に戻り rudder の自動制御が止まるので、すぐ rudder を踏む。2 発停止は TO/GA を使わず、rudder で抑えられる速さで推力を上げ、必要なら降下して加速、flaps 1 まで上げる（最低速度より遅ければ作動側へ少しバンク、外側レバーは rudder 一杯の手前で止める）。go-around 中の故障は flaps 20 の離陸と同じ扱い。

### 1.8 着陸

- 形態：通常は flaps 30（着陸距離が最短、尾部のすき間が大きい）。flaps 25 は騒音と flap の負荷を減らす（FCTM p.213 (6.1)）。機動速度かやや上で飛べば 25°＋15° の余裕がある。flaps 20・VREF30+5 で go-around 推力なら full の機動余裕（FCTM p.213）。
- 視覚的な進入角（FCTM p.215-222 (6.3-6.10)）：2-bar VASI は使わない（3°、aim 1,000 ft、目 47 ft、主脚 12 ft で threshold 通過、主脚の接地は 233 ft）。3-bar の上側（3.25°、aim 1,800 ft）は目 97 ft、主脚 62 ft、接地 1,091 ft。PAPI は 3° で白 2・赤 2、1,000〜1,500 ft に向く。主脚の接地は threshold の 1,000 ft 以上先に。
- flare と接地（FCTM p.222-224 (6.10-6.12)、p.223/225 は画像）
  - threshold が機首の下に隠れたら視点を滑走路の先端へ。主脚が約 30 ft で pitch を 2〜3° 上げて flare を始め、その後レバーを滑らかに idle へ（理想は idle と接地が同時）。接地は VREF＋ガスト分程度。flare 中と接地後に trim しない（tail strike）。
  - flare 図（3°、flaps 30、進入 VREF30+5・接地 VREF30）：threshold 50 ft で姿勢約 2°、接地 4〜5°。flare 距離は threshold から 1,000〜2,000 ft、時間は 4〜8 秒。速度 5 kt 増ごとに 1° 減。
  - 浮かせない。滑らかな接地のために flare を延ばさない。nose wheel を浮かせ続けない（FCTM p.223）。長い flare は姿勢を 2〜3° 上げ、高さの誤判断と重なると尾部接地の恐れ（FCTM p.227 (6.15)）。
  - bounce：浅ければ姿勢を保つ。高く強い bounce は go-around（正の上昇率まで gear を上げない）。接地時に推力が idle より上だと auto speedbrake が働かない（FCTM p.223 (6.11)）。
  - 接地速度は VREF30〜VREF30-5、VREF-5 を下回らない。接地姿勢（flaps 30、前方 CG、-150 fpm、海面標準）：VREF30 で約 4.6°（460,000 lb）〜4.2°（740,000 lb）、VREF30-5 で約 6.4°〜5.4°、VREF30-10 で約 10.1°〜7.0°。11°（脚が縮んだ状態）〜12.5°（伸びた状態）で胴体が接地しうる（FCTM p.224-225 (6.12-6.13)）。
  - rejected landing は FCOM/QRH に専用手順が無く、接地前なら go-around 手順で行う（FCTM p.224 (6.12)）。
- 着陸滑走（FCTM p.229-236 (6.17-6.24); FCOM p.148 (NP.21.54)）
  - 推力が idle より上で接地しない。主脚接地で landing roll 手順。speedbrake が自動で上がらなければすぐ手で UP。nose wheel を遅れなく下ろす（操縦桿を中立より前に押す必要はない、full down elevator は使わない）。PM は speedbrake の状態をコール（「SPEEDBRAKES UP」「SPEEDBRAKES NOT UP」）。
  - speedbrake を立てないと初期の制動効果は最大 60 % 落ちる（FCTM p.229）。地上ではすべての spoiler、空中では flight spoiler だけが立つ（FCTM p.229）。
  - rudder は約 60 kt まで効く。tiller は taxi 速度になってから。横風では control wheel を風上へ（FCTM p.230 (6.18)）。
  - 着陸距離：最大制動の実停止距離は乾燥 field length の約 60 %。滑走路上の減速率は空中の約 3 倍。3° で threshold を 100 ft で通ると 50 ft より約 950 ft 延びる（FCTM p.230）。
  - 不適切な技法による延び（FCTM p.233 (6.21)、画像。基準は flaps 30・最大制動）：3 秒の float +670〜820 ft、threshold 100 ft +950 ft、speedbrake なし +590〜870 ft、speedbrake も逆推力もなし +940〜1,340 ft、brake 圧半分 +1,020〜1,490 ft、進入速度 +10 kt で +350〜360 ft。
  - autobrake（FCTM p.234-235 (6.22-6.23)）：滑走路長に余裕がない、進入速度が高い、滑りやすい、横風のときに使う。MAX AUTO は最短距離が要るとき（手動の最大制動より弱い）。3 か 4 は wet・滑りやすい・距離が限られるとき。1 か 2 は通常。2 以上は連続して制動する。接地直後に逆推力を全開にすると autobrake は圧を下げられる（最小逆推力だと brake のエネルギーが倍になりうる）。PM は autobrake の解除をコール。止まれないと思ったら PF はすぐ手動制動。
  - 手動制動への移行：taxi 速度まで speedbrake と逆推力を保つ。解除方法は speedbrake lever を戻す、pedal を踏んで autobrake を解除してから緩める、selector を OFF（PM）。PF が PM に知らせる（FCTM p.235 (6.23)）。
  - 手動制動：接地直後から一定の踏力、短い・滑りやすい滑走路は一杯。踏み直さない（antiskid が最適）。手動制動は接地から 4〜5 秒遅れがちで 800〜1,000 ft 失う（FCTM p.235-236 (6.23-6.24)）。antiskid 不作動：nose wheel 接地と speedbrake を確かめ、約 500,000 lb 未満は軽く、重ければ軽〜中程度、踏み直さない（FCTM p.236）。
  - brake 冷却（FCTM p.237 (6.25)）：温度計は吸収後約 15 分で安定する。温度計が無ければ、前回の地上時間＋今回の飛行時間が 90 分未満なら gear を 5 分早く（着陸 7 分前に）出す。温度計があれば平常より 1 単位上がるごとに約 1 分早く出す。
  - 逆推力（FCTM p.238-239 (6.26-6.27)）：接地後、レバーが idle なら逆推力レバーを素早く interlock まで上げ、外れたら必要なだけ（最大まで）。約 60 kt（RR は 70 kt）から絞り始め、taxi 速度までに reverse idle、エンジンが idle になってから full down。PM は 60 kt（RR 70 kt）をコールし、前進推力の誤選択もコール。逆推力中の surge は全エンジン reverse idle。FCOM も「60 kt までに reverse idle に向けて動かし始め、taxi 速度前に reverse idle」（FCOM p.148 (NP.21.54)）。
  - 滑りやすい滑走路で横風に流されたら、reverse idle にして brake を離し、rudder と差動ブレーキで中心線へ戻してから再び最大制動と対称の逆推力（FCTM p.240 (6.28)）。EEC alternate では FMC の最大 N1 を超えないように（FCTM p.240）。片発・2 発停止では対称の逆推力。距離が厳しければ非対称も可、方向が乱れたら reverse idle（FCTM p.241 (6.29)）。
  - taxi 速度の前に autobrake を解除、手動制動。滑走路を出る前に A/P を切る（FCOM p.148 (NP.21.54)）。
- 横風（FCTM p.241-243 (6.29-6.31)）
  - 目安（定常風、10 m の風、幅 45 m 以上）：dry 36、wet 32、standing water/slush 20、雪（融解なし）25、氷（融解なし）15 kt。wet・汚染で非対称の逆推力を使うなら 5 kt 減。crab なしの sideslip だけの着陸は 20 kt 超では勧めない。FCOM の値とは §1.11。
  - 技法：flare で de-crab（風下側 rudder と風上側 aileron で wings level のまま両脚同時に接地）、crab のまま接地（乾燥・強風では勧めない、滑りやすい滑走路では有効）、sideslip（風上側から接地。バンクしすぎると nacelle か外側 flap が接地）。crab を残すなら操縦席を中心線の風上側にずらし、主脚を中心に下ろす。
- 重量超過着陸（FCTM p.243-245 (6.31-6.33)）：通常の技法でよい。flaps 25/30 なら全重量で brake のエネルギー限界を超えない。flaps 30 の進入速度（VREF30＋風）が 167 kt を超えるなら flaps 25 と VREF25。flaps up の command speed は VREF+100 以上。最長の滑走路、追い風・下り勾配を避ける、速度を余らせない、長くなりそうなら go-around、接地後すぐ最大逆推力、早く滑走路を出ない。重量超過の autoland は勧めない（MLW を超えた autoland は認定されていない。flare 高度の前に A/P を切って手で着陸）。やむを得ず行うなら接地点が延び、沈下率が大きくなりうる。自動 go-around は接地直前まで始められる。

### 1.9 機動（Maneuvers）

- VMO への加減速の体験：10,000〜15,000 ft、A/T で VMO 保護を確認。overspeed 警報で idle、250 kt へ減速（FCTM p.249-250 (7.1-7.2)）。
- 片発・2 発停止の慣熟：rudder は推力変化と同じ速さで踏み、control wheel がほぼ水平になるまで rudder trim。作動側へ少しバンク、slip/skid は作動側へ少しずれる。旋回中は rudder を一定に保ち、aileron と協調させない。A/P 中の故障では rudder で wheel を中立に戻し推力を増し、rudder trim で踏力を抜く。A/T は A/P 中で rudder を乗員が受け持てば片発でも使える（FCTM p.250-252 (7.2-7.4)）。
- 高高度の g buffet の体験：0.88〜0.90M、バンク 45° まで（FCTM p.252 (7.4)）。stick shaker は initial buffet に近い。
- 急降下（FCTM p.253-256 (7.5-7.8)、p.253 は画像）
  - A/P と FLCH を推奨（V/S は推奨しない）。宣言 → MCP に低い高度 → FLCH → レバーを閉じ speedbrake → 直進か HDG SEL で旋回 → 速度と水平高度を調整 → ATC と高度計規正 → 高度コール → 最低安全高度か 14,000 ft（該当すれば 10,000 ft）の高い方で水平 → speedbrake を戻す → LRC か 300 kt → 今後の判断。
  - 重量大・高高度では 4,000 ft 降下して速度が増すまで旋回しない。RVSM では降下と同時の旋回（15° 未満）も可。
  - A/T は入れたまま（レバーは idle に下がる）。降下中に IAS/MACH 窓は約 310 KIAS で Mach から IAS に変わる。必要なら VMO に合わせ直す。水平の前に command speed を LRC か 300 kt にすると滑らか（FCTM p.254 (7.6)）。
  - 手動：A/T を切り idle、speedbrake、A/P を切り約 10° 機首下げ、目標の 10 kt 手前から pitch を上げる（FCTM p.255 (7.7)）。
  - 構造損傷の疑いがあれば速度を今以下に。gear を出した降下は placard を守り、最小機動速度より遅ければバンク 15° まで。水平後もキャビン高度が 10,000 ft を超えていればマスクを外さない（FCTM p.255-256）。
- 失速への接近（FCTM p.257-259 (7.9-7.11)、p.257 は画像）
  - 進入条件と推力（約 1 kt/s で減速）：flaps up・gear up・0° は N1 が PW 33・GE 35・RR 35 %、flaps 20・gear up・25° は 61・64・63 %、flaps 25・gear down・0° は 66・69・67 %。command speed は各 flap の機動速度、着陸形態は VREF25+5。
  - 回復（地面が問題でない）：buffet か stick shaker で最大推力、pitch を約 5° へ、wings level、機動速度へ加速、降下を止め目標高度へ。20,000 ft 超では 5° 未満が要ることもある。地面が問題なら最大推力、地形を避ける姿勢、断続的な stick shaker を pitch の上限にする。
  - 回復中に gear と flap を上げない。A/P 中なら最大推力で速度を戻す（高高度では降下が要ることも）。
- 完全な失速：A/P と A/T を切る。機首下げの elevator（必要なら一杯）と少しの機首下げ trim。下翼のエンジン配置では推力を減らす必要があることも。機首上げが止まらなければ 45°（最大 60°）のバンクで機首を下げる。rudder はごく少量（FCTM p.263-264 (7.15-7.16)）。
- 急旋回：280 kt、45°、trim しない。15〜20° 手前で戻し始める（FCTM p.264-265 (7.16-7.17)）。
- 地形回避：GPWS の PULL UP で直ちに QRH の maneuver。地形クリアが確実になるまで A/P と A/T を入れない。RNP 0.3 未満の運航では短い caution は経路上なら続行してよい（FCTM p.265 (7.17)）。
- TCAS：離陸直前から着陸直後まで TA/RA。TA だけで機動しない。RA には小さな pitch 変化ですぐ従う。F/D は TCAS の指令を反映しないので、RA を満たす V/S になる場合だけ従う。windshear・GPWS・失速警報が TCAS より優先（FCTM p.266-267 (7.18-7.19)）。TA ONLY が適するのは、片発運航など（FCTM p.266）。
- upset：pitch 25° 超の機首上げ、10° 超の機首下げ、バンク 45° 超、または状況に合わない速度。まず失速から回復。機首上げは機首下げ elevator と少しの trim、効かなければバンクで機首を下げる。機首下げは機首上げ elevator・推力減・speedbrake。67° を超えるバンクでは荷重制限内で水平を保てない。大きなバンクではまず最短方向に wings level（FCTM p.268-271 (7.20-7.23)）。
- windshear：500 ft 未満では風はほぼ水平。速度低下で機首が下がり、そこへ機首を下げると降下率が急増する。5 秒しかないこともある。速度を高度に替え、最大推力で pitch を保つ。回避・予防は FCOM SP.16、回復は QRH（FCTM p.272-273 (7.24-7.25)）。FCOM の予防：離陸は最大推力、flaps 20、最長の滑走路、F/D 使用、VR を性能上の値（実重量 VR+20 まで）に上げる。着陸は flaps 25/30、1,000 ft までに安定、A/T を使わないなら最大 20 kt の補正（FCOM p.217-218 (SP.16.17-18)）。

### 1.10 非常時の操作（系統に関わるもの）

- 一般（FCTM p.279-282 (8.1-8.4)）：認識してコール → PF が飛び PM が NNC（自動化を最大限）→ すべての EICAS を見て故障系統を特定 → 処置 → 着陸の要否。NNC にない reset や CB の再投入はしない。進入前に処置を終え、長い straight-in にする。autobrake と speedbrake は NNC が禁じない限り arm（FCTM p.281 (8.3)）。4 発機は 1 発停止なら最寄りでなくても同等に安全な空港へ行ける。消えない煙・火災は最寄りの空港（FCTM p.281-282）。
- エンジン
  - 離陸後の故障と火災：故障の NNC は flap 上げ後。火災は操縦が落ち着き、gear が上がり、安全高度（最低 400 ft AGL）で recall 項目。PM が PF の識別を確認してから PF が該当レバーを絞る（FCTM p.284 (8.6)）。
  - tailpipe fire：motoring が主な消火手段。engine fire switch は使わない（motoring できなくなり、消火剤も tailpipe 内には効かない）（FCTM p.284）。
  - 推力制御の喪失：レバーに反応しない（固定回転、停止、最後の位置の推力など）。疑わしければ Engine Limit/Surge/Stall NNC ができるまで離陸を続けるか空中に留まる。低速の地上では方向保持のため即停止もありうる（FCTM p.285 (8.7)）。
  - 多発故障：recall 項目と、直ちに windmill 再始動の速度。速いほど・30,000 ft 未満ほど成功しやすい（FCTM p.285）。全エンジン停止（windmill の油圧）：flap は使えない。gear 下げは最大 2.5 分。最低 160 kt か最小機動速度の大きい方、200 kt 未満での操舵は避ける。着水なら gear up（FCTM p.286 (8.8)）。
  - 激しい振動：減速と降下で減らす（FCTM p.286）。
  - 停止の技法：PF が該当エンジンを口頭で確認しゆっくり絞る。PM が fuel control switch（fire switch）に手を置いて読み上げ、PF が確認して指示（FCTM p.286-287 (8.8-8.9)）。
  - 消火剤：fire warning が無くてもエンジンに火災の兆候・報告があれば 2 本とも、APU なら APU の bottle。関係の無い避難では使わない（FCTM p.288 (8.10)）。
- 電源：standby 電源だけでの着陸（FCTM p.283-284 (8.5-8.6)）：左の nav radio、CDU、通信が使える。flaps 1 を選ぶと FLAPS DRIVE（LE flap は AC の制御が要り出ない）→ FLAPS DRIVE NNC の adjusted VREF と flap。control wheel の trim は不作動、aisle stand の alternate trim は使える。TE flap の表示は右だけ。antiskid、auto speedbrake、逆推力は無い。
- 操縦系統
  - LE/TE の故障：flaps 25/30 の位置に無ければ autoland は認定外。all flaps up の NNC は無い（FCTM p.288 (8.10)）。
  - LE flap：primary（空気圧）が壊れた部分は secondary（電動）へ自動で移り FLAPS PRIMARY。電動でも動かないか非対称なら FLAPS DRIVE。flaps 1 で動くのは inboard と midspan の LE だけで、出なければ flap 表示がグループ別の拡大表示になる。adjusted VREF で wings level、接地姿勢は普段より低い（FCTM p.289 (8.11)）。
  - TE flap：primary（油圧）→ secondary（電動）。FLAPS DRIVE NNC。動く flap を flaps 25 まで。final の速度が flap load relief 速度を超えることがある。outboard を出すと機首下げ、inboard で機首上げ。adjusted VREF＋風を保つ（adjusted VREF まで落ちると 40° の余裕がない）。final の姿勢は普段より数度高く、flare で adjusted VREF を割ると尾部接地（FCTM p.289-290 (8.11-8.12)）。
  - secondary・alternate で flap を出すときは、flap が位置に着いてから command speed を下げる（動きが遅い）（FCTM p.290 (8.12)）。油圧が多系統失われると secondary で 0→5 に最大 4 分（FCTM p.297 (8.19)）。
  - 舵の固着：兆候は説明のつかない A/P 解除、A/P が入らない、高度捕捉の行き過ぎ・不足、形態や速度の変化で舵が重い。両パイロットで力を加え、外れなければ override（aileron にある）。固着していない側が PF。trim での打ち消し：elevator → stabilizer、aileron → rudder、rudder → aileron（非対称推力も有効）。進入では接地まで idle にしない。elevator 固着の go-around はできるだけ避ける（FCTM p.290-292 (8.12-8.14)）。
  - stabilizer の固着は NNC の速度。予期しない stabilizer trim は操縦桿を逆に動かすと trim 指令が止まる（FCTM p.292 (8.14)）。
- 計器：速度計の異常（FCTM p.293-294 (8.15-8.16)）
  - ピトーの入口が塞がると drain から抜けて速度は 0 へ。drain も塞がると上昇で増え、降下で減り、巡航では不定。
  - 気づいたらその飛行段階の目標姿勢と推力に戻し、QRH の Flight With Unreliable Airspeed 表で姿勢・推力・V/S を合わせる。GS を照合。AOA 計があれば針を 3 時の位置に。FPV は速度異常時の pitch の目安になる（FCTM p.53 (1.23)）。
  - 降下は姿勢と表の降下率で、水平高度の 2,000 ft 上で 1,000 fpm に。ILS があれば使う、早めに着陸形態、G/S 捕捉か降下開始で表の推力と姿勢、降下率は推力で。接地は threshold の 1,000〜1,500 ft 先。autobrake を使う。
  - 姿勢の目安（全エンジン型式、訓練重量）：巡航（gear・flap up）3°、降下 0°、進入の機動 5〜9°（flap による）、final（VREF+10）は flaps 25 で 2.5°、flaps 30 で 1°。
- 燃料（FCTM p.295-297 (8.17-8.19)）
  - 不均衡の制限は機体構造と脚の寿命のためで、操縦性はほとんど変わらない。alert が出たら FUEL IMBALANCE NNC。エンジンを止めた直後に crossfeed を開けない（漏れがあれば燃料を捨てることになる。実機の pump は吐出圧がばらつき、圧の高いタンクから流れる。シミュレーターの pump が等圧なので誤解が強まる、と FCTM 自身が書いている）。日常の balancing はしない。進入中の不均衡は原因が明らかなら放置。
  - 漏れ：専用の表示は無い。燃料記録と計画の比較、予期しない量・不均衡で気づく。疑ったら NNC。
  - 燃料少（いずれかの main tank が 2,000 lb / 900 kg 以下）：降下と進入はできるだけ clean。燃料が前に寄らないよう早めに緩やかに減速。強いブレーキと大きな逆推力を避ける（pump が露出してフレームアウト）。go-around は推力を滑らかに、機首上げは最小、wing tank の pump に low pressure が出ても切らない。
  - 投棄：4,000 ft AGL より上（完全に蒸発）、1,000 ft の落下で 1 mile 以上流れる、holding で下に機がいるときは避ける、最大性能が要るなら standpipe まで。
- 油圧（FCTM p.297 (8.19)）：alternate で出した gear は上げられない。多系統の喪失は flaps 25 と adjusted VREF（浮きやすい）。4 系統目が失われていると auto speedbrake で outboard spoiler だけが立ち急な機首上げ（尾部接地）→ 手でゆっくり speedbrake を出し前に押す。nose wheel steering が無ければ約 60 kt 以下は brake が方向制御の主。滑走路を出たら taxi を続けない。
- 脚（FCTM p.297-300 (8.19-8.22)）
  - 離陸中のタイヤ破損：他の損傷の兆候が無ければ目的地まで続けることを考える。
  - パンクでの着陸：前輪なら静かに nose を下ろし、軽いブレーキと idle 逆推力、autobrake は低い設定まで。主輪ならブレーキが効かず偏向するので逆推力を最大、autobrake は使わない。どちらか分からなければ autobrake なし。
  - gear disagree：出ている脚で着陸。recycle しない。必要なら GPWS を抑止。nose と両側が接地してから speedbrake。60 kt 未満は steering と差動ブレーキ。止まったら taxi しない。組合せ別の注意（nose だけ出ないと静かに nose を下ろす、wing と nose だけなら尻もちの恐れで door 1 の slide が使えない、など）。
- overspeed（FCTM p.300-301 (8.22-8.23)）：A/T は VMO/MMO に近いほど強く制御するが、windshear や山岳波では短い超過がありうる。高高度で idle まで絞らない（加速に時間がかかる）。部分的な speedbrake で補う。降下中は VNAV path 捕捉か高度捕捉が終わるまで speedbrake を戻さない。windshear の多い経路では上昇・降下速度を 5〜10 kt 下げる。A/P が修正していれば入れたまま（切ると急な pitch 変化）。VNAV か FLCH で直らなければ一時的に V/S で pitch を上げる。超過時の最大速度を記録。
- 尾部接地（FCTM p.301-304 (8.23-8.26)）：離陸は stabilizer の設定誤り（重量・CG の誤り）、早すぎる引き起こし、引き起こし中の trim、速すぎる回転、F/D の bar に向けた急な引き起こし（正しい回転なら 35 ft で約 15°）。着陸は不安定進入（最大要因）、flare の引き延ばし、flare 中の trim、横風の扱い、遅い go-around での過回転（遅い go-around で一瞬接地するのは許容）。
- 車輪格納部の火災：270 kt / 0.82M を超えていれば gear を出す前に減速（FLCH で約 265 kt 以下、または ALT HOLD で速度を下げる。A/T は入れたまま）（FCTM p.304-305 (8.26-8.27)）。
- 前面窓：両方の前面窓が層間剥離して前が見えなければ、ILS が使えれば autoland（FCTM p.305 (8.27)）。
- NNC の範囲外（FCTM p.305-309 (8.27-8.31)）：elevator が効かなければ stabilizer trim、バンク、推力で pitch（推力増で機首上げ）。操縦性が疑わしければバンク 15° まで。どの flap 位置でも（up でも）着陸はできる。flap の作動が疑わしければ動かさない。flap の移動中に横揺れが増えたら（非対称が自動停止していない）前の位置へ戻す。安全な高度で、ゆっくり減速しながら flap を出して操縦性を確かめ、stick shaker か大きな wheel・rudder 一杯が要る速度を最小進入速度とする。推力でロールを補っているなら接地まで推力を残す。
- 着水（FCTM p.282-283 (8.4-8.5)）：7700。flaps 30 か適切な flap、VREF、降下率 200〜300 fpm、うねりに平行に風上側へ。接地姿勢 10〜12°。

### 1.11 FCTM と FCOM の食い違い

| 項目 | FCTM | FCOM | 採用 |
|---|---|---|---|
| 離着陸の横風 | 離陸の目安 dry 40、wet 25 kt ほか（FCTM p.99 (3.11)）。着陸の目安 dry 36、wet 32 kt ほか（FCTM p.241 (6.29)）。どちらも「制限ではない」 | 最大離着陸横風 30 kt（制限ではない）（FCOM p.77 (L.10.1)）。autoland の横風 25 kt（FCOM p.80 (L.10.4)） | FCOM。試験の気象は横風 25 kt 以下にする |
| flap を出した状態での speedbrake | flaps 5 を超えたら使わない（buffet）（FCTM p.139 (4.17)） | flaps 20 を超えての使用は勧めない（109, 570）。405 は flaps 10 を超えて（FCOM p.83 (L.10.7)） | FCOM（20）。試験の操作は FCTM の 5 を守れば両方を満たす |
| CLB 1 / CLB 2 | 「一定の 10 %／20 % の derate」で、上昇とともに徐々に戻る（FCTM p.123 (4.1)） | 109：CLB 1 は 10,000 ft まで 10 %、以後 30,000 ft で CLB に線形に戻す。CLB 2 は 20 %、35,000 ft で戻す（405/570 は 15,000 ft で戻す）。自動選択は離陸の減推力 5 % 未満で CLB、5〜15 % 未満で CLB 1、15 % 以上で CLB 2（FCOM p.1273 (11.32.3)） | FCOM |
| エンジンの暖機と冷却 | 何時間も止めていたら離陸前に数分低推力で回す、停止前に冷却（数値なし）（FCTM p.85 (2.13)） | 暖機：油温が下側の amber band より上（要件）。2 時間を超えて止めていたら 5 分（推奨）（109/405）。冷却：taxi 推力以下で 90 秒以上（要件）、5 分（推奨）（FCOM p.127, p.149 (NP.21.33, 21.55)）。570 は暖機 3 分、冷却 3 分 | FCOM |
| autoland の runway alignment | 500 ft RA 以下で始まり、forward slip は 5° まで（FCTM p.159 (5.13)） | crab 10° 超：500 ft AGL で 5° の sideslip を接地まで。5〜10°：500 ft と 200 ft の 2 段。5° 未満：200 ft。エンジン故障が進入前なら 1,300 ft AGL で wings level の sideslip（FCOM p.670 (4.20.12)） | FCOM |
| 重量大での 10,000 ft 未満の上昇速度 | transition speed か「flaps up 機動速度+20」の大きい方（FCTM p.125 (4.3)）。309,000 kg 超では flaps up 機動速度が VREF30+100 なので VREF30+120 になる | VNAV の上昇速度は VREF+100 か transition speed の大きい方（FCOM p.667 (4.20.9), p.1328 (11.41.4)） | FCOM（VNAV の論理はこれで作る）。重量大での FCTM の意図は §未確認 |
| 単一 A/P の ILS で A/P を切る高さ | minimums で切る（FCTM p.169 (5.23)） | 100 ft AGL より下へ降りる前に切る（FCOM p.80 (L.10.4)） | 両方を満たす（minimums が 100 ft 以上なら minimums） |
| LNAV の作動 | 50 ft AGL 以上かつ active leg の 2.5 NM 以内で入る（FCTM p.112 (3.24)） | 50 ft 以上で、active leg に乗れる位置なら入る。飛行中に選んだときは 2.5 NM 以内なら即作動（FCOM p.663 (4.20.5)） | FCOM |
| 離着陸の追い風 | 追い風 10 kt 超は rolling takeoff（FCTM p.99 (3.11)） | 制限 15 kt（109）、10 kt（405, 570）。autoland も 15 kt（109）（FCOM p.77, p.80） | 両方。制限は FCOM |
| 汚染滑走路の深さ | 0.5 in（12.7 mm）（FCTM p.103 (3.15)） | 1/2 in（13 mm）（FCOM p.201 (SP.16.1)） | 実質同じ。FCOM |
| RR の数値 | 初期 EPR 1.2 まで可、逆推力は 70 kt から絞る（FCTM p.92, p.238） | 記載なし（PW・GE だけ） | FCTM（他に資料が無い） |

- 食い違いではないが組み合わせが要るもの：flaps 1 での待機（FCTM p.141）は 20,000 ft 以下に限る（FCOM p.82 (L.10.6)）。乱気流の突入速度は FCTM が SP を参照し、FCOM は 290〜310 KIAS / 0.82〜0.85M の低い方（FCOM p.77 (L.10.1), p.215 (SP.16.15)）。
- 一致を確かめたもの（主なもの）：離陸の初期推力（1.10 EPR / 70 % N1）、15° への引き起こし、V2+10〜V2+25、flap 上げ速度（speedtape の bug＝VREF30+20/40/60/80）、重量大のバンク制限、A/P の最低高度 250 ft、降下手順は 10,000 ft までに完了・進入手順は transition level、240 kt の計画速度、汚染滑走路での ATM 禁止、TO/GA 1 回目で 2,000 fpm、逆推力 60 kt、autoland の flap 25/30。

### 1.12 実装が再現すべき機体の応答（FCTM の技法の前提）

FCTM の技法は次の応答を前提にしている。系統を作り直すとき、ここが崩れると技法が成り立たない。右端は Part 2 で確かめるシナリオ。

| # | 応答 | 根拠 | 試験 |
|---|---|---|---|
| R01 | preflight で最初の F/D を ON → FD・A/T 空白・TO/GA・TO/GA、pitch bar 約 8° 上 | FCOM p.111 (NP.21.17), p.666 (4.20.8) | S01 |
| R02 | 地上で 50 kt 未満に TO/GA → A/T が THR REF で基準推力へ。50 kt までに入らなければ 400 ft まで A/T は入らない。押すと FMC の位置が threshold に更新 | FCOM p.656 (4.10.18), p.667 (4.20.9) | S03 |
| R03 | 65 kt で HOLD。HOLD 中は A/T がレバーを動かさない（手では動く）。HOLD 前の RTO で A/T を切らないと離した後レバーが戻る | FCOM p.667; FCTM p.94, p.106 | S03, S11 |
| R04 | 浮揚後の F/D pitch の目標：V2+10（5 秒超えていればその速度、最大 V2+25）。地上でエンジン故障なら V2 か浮揚速度の大きい方。浮揚後の故障は V2 / そのときの速度 / V2+10 | FCOM p.664 (4.20.6), p.667 | S03, S08 |
| R05 | 浮揚後に TO/GA → 離陸 derate を外し THR REF（50〜400 ft は roll だけ TO/GA） | FCOM p.656; FCTM p.94, p.119 | S08 変形 |
| R06 | LNAV は 50 ft、VNAV は 400 ft で入る。VNAV は 400 ft で THR REF | FCOM p.667; FCTM p.112 | S03 |
| R07 | 加速高度（または最初の flap 操作）で VNAV は今の flap の placard −5 kt へ、flap が上がるごとに次の placard −5 kt、flaps up で VREF+100 か transition speed の大きい方 | FCOM p.667, p.1255 (11.31.21), p.1326 (11.41.2) | S03 |
| R08 | thrust reduction 点（400〜9,999 ft か flaps 5）で推力基準が CLB/CLB 1/CLB 2 に。derate の自動選択と高度による解除 | FCOM p.1272-1273 (11.32.2-3); FCTM p.112, p.123 | S03 |
| R09 | VNAV 中のエンジン故障：加速高度まで V2+10 と離陸推力、加速して VREF+100、flaps up で VREF+98 に達すると CON（予定の推力減少点は無効） | FCOM p.1266 (11.31.32), p.1272; FCTM p.118 | S08 |
| R10 | A/T は 1 発停止で使える、2 発停止で切れて戻せない | FCOM p.666 (4.20.8); FCTM p.133-134, p.171 | S08 |
| R11 | 捕捉：FLCH/V/S は ALT、VNAV は VNAV ALT（MCP 高度が FMC と矛盾）。MCP 高度で水平になると FMC はそれを上昇制限として扱う。TO/GA で捕捉すると A/T は SPD を選ぶまで THR/THR REF のまま | FCOM p.665 (4.20.7), p.673 (4.20.15); FCTM p.123-124 | S03, S07 |
| R12 | altitude intervention：MCP 高度を変えて selector を押すと、上昇中は次の高度制限を消し、巡航中は CRZ ALT が MCP 高度になる（cruise climb / descent、modification を作らない）。PROC HOLD 中は次の制限を消して降下 | FCOM p.1256-1257 (11.31.22-23), p.1348 (11.42.4); FCTM p.124, p.181 | S04 |
| R13 | step climb の予測（STEP SIZE、STEP TO、AT／NOW、S/C 表示、OPT/MAX） | FCOM p.1257, p.1348-1350 (11.42.4-6); FCTM p.129-130 | S04 |
| R14 | 降下 path：最も低い制限から上に idle で作る。transition altitude で減速（10 kt 下の速度）、速度制限の前は約 500 fpm の減速区間。T/D では水平で減速。経路から 150 ft 以内に保ち、外れると VNAV SPD に戻り THRUST REQUIRED / DRAG REQUIRED | FCOM p.1258-1260 (11.31.24-26), p.1264; FCTM p.137 | S05 |
| R15 | speed intervention：VNAV SPD は idle のまま pitch、VNAV PTH は推力か speedbrake で速度を合わせる。on approach 中は IAS 窓を開いたまま VNAV PTH | FCOM p.1261 (11.31.27); FCTM p.137, p.181 | S05, S09 |
| R16 | T/D の 2 分前に MCP が巡航高度のままなら RESET MCP ALT。DES NOW / 50 NM 以内の selector 操作で early descent（THR→HOLD、VNAV SPD） | FCOM p.665, p.1260-1261 (11.31.26-27), p.1433 (11.60.5) | S05 |
| R17 | 片発の巡航：ENG OUT で E/O LRC と CON。片発最大高度より上では driftdown（最低 300 fpm）、selector を先に押すと約 1,250 fpm の cruise descent | FCOM p.1267-1269 (11.31.33-35); FCTM p.133 | 追加候補 |
| R18 | APP の arm と捕捉：LOC は 120° 以内、LOC への角が 80° を超えると G/S を捕捉しない、G/S は上下どちらからも、405 は LOC 捕捉まで G/S を抑止。LOC 捕捉で heading bug が inbound course へ | FCOM p.669-670 (4.20.11-12); FCTM p.158 | S06 |
| R19 | F/D か A/P で LOC 捕捉中は LOC の目盛りが約 5/8 dot で拡大表示になる（raw data では拡大しない） | FCTM p.160 (5.14) | S06 |
| R20 | 1,500 ft RA 未満で LAND 3/LAND 2、FLARE と ROLLOUT を arm。200 ft 未満で LAND 3→2 は表示しない。runway alignment（§1.11）、flare は約 50 ft（60〜40 ft）、25 ft で A/T IDLE、約 5 ft で ROLLOUT。接地で FLARE 消灯、nose を下ろす。rollout は A/P を切るまで | FCOM p.662 (4.20.4), p.665, p.670-672 (4.20.12-14); FCTM p.159 | S06 |
| R21 | 3 系統の autoland で電源のバス分離と ELEC synoptic の抑止（「ELECTRICAL SYNOPTIC INHIBITED FOR AUTOLAND」） | FCOM p.789 (6.10.11); ATA-24.md §4.13 | S06 |
| R22 | ILS 干渉の監視：誤信号を無視して慣性で姿勢を保ち、続けば PFD に表示 | FCTM p.162 (5.16) | 未定 |
| R23 | TO/GA（進入）：1 回目は THR で 2,000 fpm、2 回目で THR REF（GA 全推力）。推力基準は flap が up を外れるか G/S 捕捉で GA、着陸 flap か G/S 捕捉で固定。RA 5 ft 未満から 2 秒で TO/GA を抑止、5 ft を超えて 3 秒で解除。go-around 中に接地しても続く。400 ft より上で mode を変えると A/P 1 基に戻る | FCOM p.672-673 (4.20.14-15); FCTM p.206-208 | S07 |
| R24 | 接地後・逆推力前の go-around：レバーを進めると speedbrake が戻り autobrake が解除。F/D の go-around は浮揚後に選び直すまで出ない | FCTM p.208; FCOM p.951 (9.20.11), p.1515 (14.20.5) | S07 変形 |
| R25 | ground spoiler：ARM・レバー 1 と 3 がほぼ閉・主脚接地で UP。DN でもレバー 1・3 閉で逆推力レバー 2 か 4 を idle detent まで上げると UP（RTO と着陸の予備）。レバー 1 か 3 を進めると DN | FCOM p.951 (9.20.11); FCTM p.229 | S06, S11 |
| R26 | autobrake：RTO は地上・GS 85 kt 超・全レバー閉で最大圧。着陸は全レバー閉・ground mode・車輪の spin-up で開始、逆推力と spoiler の分だけ圧を下げる。解除条件（pedal、レバー前進、speedbrake を DN、DISARM/OFF、故障）。着陸後の解除で selector は DISARM へ | FCOM p.1515-1516 (14.20.5-6); FCTM p.234-235 | S06, S11 |
| R27 | 逆推力：interlock、reverse idle で A/T が切れる（AUTOTHROT DISC は出さない）。逆推力レバーを下げて 10 秒後から flaps UP まで A/T は arm（TO/GA で THR REF） | FCOM p.666, p.671 (4.20.13), p.677 (4.30.1); FCTM p.238 | S06 |
| R28 | flap load relief：flaps 30 → 25 → 20、flaps 25 → 20。レバーは動かない。secondary/alternate では働かない | FCOM p.954 (9.20.14); FCTM p.158 | S06 |
| R29 | flap の secondary/alternate は遅い（0→5 に最大 4 分）。LE の flaps 1 は inboard と midspan だけ。拡大表示 | FCTM p.289-290, p.297; FCOM p.954 | 追加候補 |
| R30 | V speeds 設定後に逆推力を選ぶと V speeds が消え、離陸の推力上限が full TO になる | FCTM p.77 (2.5) | S02 変形 |
| R31 | body gear steering は nose gear 角 20° 超・約 20 kt 未満で自動 | FCTM p.78 (2.6) | S02 |
| R32 | approach idle：飛行中に nacelle 防氷 ON か着陸 flap で選ばれ、接地 5 秒後に minimum idle | FCOM p.877-878 (7.20.7-8) | S06 |
| R33 | 速度保護：A/T と AFDS（VNAV SPD、FLCH SPD、TO/GA）がそれぞれ最小機動速度と VMO/placard を守る（FMC は 5 kt の余裕）。V/S と片発最大高度より上の故障では保護なし | FCOM p.663 (4.20.5), p.675 (4.20.17); FCTM p.301 | S05 |
| R34 | windshear：TO/GA で 15° か PLI の少し下、上昇率 600〜1,200 fpm（片発 0〜600）で速度制御へ | FCOM p.674 (4.20.16) | 追加候補 |
| R35 | MCP 故障の回復：A/P 解除と両 F/D OFF で全モード解除、入れ直すと既定モード | FCTM p.65; FCOM p.639-640 (4.10.1-2) | 追加候補 |
| R36 | HDG SEL 中に heading reference を切り替えると HDG HOLD に変わる | FCOM p.189 (SP.10.1) | 追加候補 |
| R37 | standby 電源だけ：LE flap は出ず FLAPS DRIVE、alternate trim だけ、antiskid・auto speedbrake・逆推力なし | FCTM p.283-284 (8.5-8.6) | 追加候補 |
| R38 | 油圧 4 系統目なしの auto speedbrake は outboard spoiler だけ | FCTM p.297 (8.19) | 追加候補 |

### 1.13 代表値の早見表

| 項目 | 値 | 根拠 |
|---|---|---|
| taxi 速度 | 通常 約 20 kt、直線 30 kt まで、30° 超の旋回は 10 kt 以下で進入、最大重量で 15,000 ft 超なら 20 kt まで | FCTM p.77, p.79 |
| 離陸の初期推力 | 約 1.10 EPR（PW）、約 70 % N1（GE）、RR は 1.2 EPR まで可。安定待ちは約 2 秒まで | FCTM p.92; FCOM p.129-130 |
| 離陸推力の設定 | 80 kt まで | FCTM p.93; FCOM p.131 |
| rudder の効き | 40〜60 kt（離陸）、約 60 kt まで（着陸滑走） | FCTM p.93, p.230 |
| 引き起こし | 平均 約 2.5°/s で 15° へ、浮揚まで 3〜5 秒、浮揚姿勢 10.0°（flaps 20）／10.1°（10） | FCTM p.95-96 |
| 尾部接地の姿勢 | 12.5°（脚が伸びた状態）、11°（縮んだ状態） | FCTM p.96, p.225 |
| 片発の引き起こし | 0.5°/s 遅く、2〜3° 低く。浮揚 約 5 秒・10.6°、35 ft で 12〜13°（10〜12 秒） | FCTM p.114-116 |
| 初期上昇速度 | V2+10〜V2+25（全発）、V2〜V2+10（片発） | FCTM p.90, p.111, p.117; FCOM p.667 |
| 離陸 flap での最大バンク | V2+10 で 25°。片発では V2+10 まで AFDS が 15° に制限 | FCTM p.111, p.118 |
| 加速高度 | 訓練 1,000 ft AFE。路線 1,500〜3,000 ft AFE（推力減少は約 1,500 ft）。最低 400 ft | FCTM p.42, p.112 |
| flap 上げ | VREF30+20（→10）、+40（→5）、+60（→1）、+80（→UP） | FCTM p.113; FCOM p.132 |
| 上昇速度（FMC なし） | 10,000 ft 未満 250 kt か VREF30+100 の大きい方、以上 340 kt / 0.84M。最大上昇率は flaps up+60 で 0.82M まで | FCTM p.126 |
| 最大高度付近 | amber band の 10 kt 以上上、バンク 10° 以下 | FCTM p.128 |
| LRC | 約 0.86M（-400F は 0.85M） | FCTM p.132 |
| step climb の燃料 | 4,000 ft で 500〜650 lb（225〜300 kg） | FCTM p.130 |
| 降下計画 | 3 NM / 1,000 ft。10,000 ft AGL・30 NM・250 kt。場周高度は直進 12 NM、横から 8 NM | FCTM p.138-139 |
| 降下率（idle） | 0.83M/340 kt 2,800（SB 4,300）、250 kt 1,300（2,100）、VREF30+100 1,200（1,900）fpm | FCTM p.138 |
| 減速 | 水平で 340→250 kt 90 秒・8 NM、flaps up まで +13 秒・1 NM。SB で 40 % 短縮 | FCTM p.139 |
| 待機 | 3 分前に減速開始。ICAO 230/240/265 kt/0.83M、FAA 200/230/265 kt | FCTM p.141-142 |
| 安定進入 | 1,000 ft（IMC）/500 ft（VMC）、VREF〜VREF+20、1,000 fpm 以下、1 dot 以内 | FCTM p.151 |
| G/S と VDP | 3° で 1 NM あたり約 300 ft。HAA 300〜700 ft → VDP 1.0〜2.3 NM | FCTM p.159, p.193 |
| V/S 進入 | チャートの値、無ければ -700〜-800 fpm | FCTM p.191 |
| visual | 場周 1,500 ft・2 NM、base 600〜700 fpm、final 700〜900 fpm、500 ft までに安定 | FCTM p.199-201 |
| go-around | 自動で約 40 ft 降下（100 ft より上で開始）、TO/GA 1 回で約 2,000 fpm | FCTM p.206, p.208; FCOM p.673 |
| 着陸の幾何 | 3°・flaps 30・VREF30+5 で姿勢 2.0°、目 66 ft、主脚 31 ft、flare なしの接地 584 ft | FCTM p.168 |
| flare | 主脚 約 30 ft で 2〜3° 上げる。flare は 1,000〜2,000 ft・4〜8 秒、接地姿勢 4〜5° | FCTM p.222-223 |
| 接地速度 | VREF30〜VREF30-5、VREF-5 を下回らない | FCTM p.224 |
| 逆推力 | 60 kt（RR 70 kt）から絞り taxi 速度までに reverse idle | FCTM p.238; FCOM p.148 |
| 手動制動の遅れ | 4〜5 秒、800〜1,000 ft | FCTM p.236 |
| 急降下 | 14,000 ft か最低安全高度（該当すれば 10,000 ft）、LRC か 300 kt、IAS/MACH は約 310 KIAS で切替 | FCTM p.253-254 |
| 失速接近の推力 | N1 33/35/35 %（flaps up）、61/64/63 %（20・25°）、66/69/67 %（25・gear down）（PW/GE/RR） | FCTM p.257 |
| 速度計異常の姿勢 | 巡航 3°、降下 0°、進入機動 5〜9°、final（VREF+10）は flaps 25 で 2.5°・30 で 1° | FCTM p.294 |
| 燃料少 | いずれかの main tank が 2,000 lb / 900 kg 以下 | FCTM p.296 |
| 全エンジン停止 | 最低 160 kt か最小機動速度、200 kt 未満の操舵を避ける、gear 最大 2.5 分 | FCTM p.286 |

## Part 2 自動試験のシナリオ案

### 2.0 共通事項

- 枠組み
  - ハーネスは FlyWithLua でも Web API（v3、localhost:8086）でもよい書き方にする。FlyWithLua はこの X-Plane に入っておらず、Web API は Phase 1 で試す予定（ARCHITECTURE.md §1, §9）。
  - 各シナリオは「前提」「手順と確認」「合否」の 3 部。手順の各行は「きっかけ（条件）→ 操作 → 確認（観測値と許容、期限）」で、そのままスクリプトの 1 ステップにできる。
  - 操作は FCOM のスイッチ名で書いた。スイッチ名 → command / dataref の対応表は Phase 1 で INTERFACES.tsv から作る（本ノートの範囲外）。CDU の入力は `laminar/B747/fms1/ls_key/L1` などのキー command で行う（ARCHITECTURE.md §6）。
  - 時間加速は使わない。記録は 10 Hz 以上（推定）。
  - 重量・燃料・CG・気象・初期位置の設定方法（FMC の地上作業ページ、dataref、Web API の flight 開始）は Phase 1 で決める。
- 観測手段（現行コードで名前を確かめたもの）

  | 観測 | 名前 | 値 | 出典 |
  |---|---|---|---|
  | FMA の A/T | `laminar/B747/autopilot/FMA/autothrottle_mode` | 0 なし、1 HOLD、2 IDLE、3 SPD、4 THR、5 THR REF | plugins/xtlua_keysystems/init/scripts/B747.70.autopilot/B747.70.autopilot.lua:124-135 |
  | FMA の roll | `.../FMA/active_roll_mode`、`.../FMA/armed_roll_mode` | 0 なし、1 TO/GA、2 LNAV、3 LOC、4 ROLLOUT、5 ATT、6 HDG SEL、7 HDG HOLD | 同 :137-159 |
  | FMA の pitch（active） | `.../FMA/active_pitch_mode` | 0 なし、1 TO/GA、2 G/S、3 FLARE、4 VNAV SPD、5 VNAV ALT、6 VNAV PTH、7 V/S、8 FLCH SPD、9 ALT | 同 :173-185 |
  | FMA の pitch（armed） | `.../FMA/armed_pitch_mode` | 0 なし、1 TO/GA、2 G/S、3 FLARE、4 VNAV、7 V/S、8 FLCH SPD、9 ALT | 同 :161-171 |
  | AFDS status | `laminar/B747/autopilot/AFDS/status_annun_pilot`（`_copilot`） | 0 なし、1 FD、2 CMD、3 LAND 2、4 LAND 3、5 NO AUTOLAND | 同 :194-203 |
  | EICAS メッセージ | `laminar/B747/CAS/gen_{warning,caution,advisory,memo}_msg_000`〜`_109` | 文字列。全行を走査して文字列一致で判定 | plugins/xtlua/init/scripts/B747.87.warning/B747.87.warning02.lua:57, :123-141 |
  | 推力基準（EICAS 上部） | `laminar/B747/engines/ref_thr_limit_mode` | 文字列（TO、CLB、CON、GA など） | INTERFACES.tsv |
  | エンジン計器 | `laminar/B747/engines/display_N1`、`display_N2`、`display_EPR`、`display_EGT`、`oil_press_psi` | 配列 [0-3] | INTERFACES.tsv |
  | CDU の表示 | `laminar/B747/fms1/Line01_L`〜（大文字）、`..._S`（小文字） | 文字列 | INTERFACES.tsv |
  | MCP 高度 | `laminar/B747/autopilot/altitude_dial_ft` | ft | plugins/xtlua_fdr/scripts/B747.01.xt.fdr/B747.01.xt.fdr.lua:22 |
  | 指示対気速度 | `laminar/B747/gauges/indicators/airspeed_kts_pilot` | kt | 同 :25 |
  | 姿勢 | `sim/cockpit2/gauges/indicators/pitch_AHARS_deg_pilot`、`roll_AHARS_deg_pilot` | deg | 同 :16-17 |
  | 昇降率・高度・電波高度 | `sim/cockpit2/gauges/indicators/vvi_fpm_pilot`、`altitude_ft_pilot`、`radio_altimeter_height_ft_pilot` | fpm、ft | 同 :21-24 |
  | 対地速度・接地・重量・燃料 | `sim/flightmodel2/position/groundspeed`（m/s）、`sim/flightmodel/failures/onground_any`、`sim/flightmodel/weight/m_total`、`m_fuel_total` | | 同 :12, :20, :26-27 |
  | flap 位置 | `laminar/B747/cablecontrols/flap_ratio` | 0-1 | 同 :28 |
  | 位置・方位・航跡 | `sim/flightmodel/position/latitude`、`longitude`、`psi`、`sim/cockpit2/gauges/indicators/ground_track_mag_pilot` | | 同 :13-19 |

  - FMA・AFDS・CAS・推力基準・エンジン計器・CDU 行は INTERFACES.tsv に載っている（パネルが使う）。作り直しても名前と意味は残るので、試験の観測点として安定している。数値コードの割当ては現行のもの。
  - 既存の flight data recorder（`plugins/xtlua_fdr`）は FMA・AFDS status・姿勢・速度・高度などを livery フォルダの `flight_data.jdat` に書く（B747.01.xt.fdr.lua:74, :193）。ハーネスの記録に流用できる。
  - 灯火（GEN CONT OFF、APU GEN AVAIL、PRESS、SYS FAULT など）は主に B747.90.xt.lighting で計算されている（共通 brief の知見）。名前は対応表を作るときに拾う。
- 判定の決まり
  - 許容幅は、資料にある値はその値（根拠つき）、無いものは `推定` と書いた。推定の値は最初の試験結果で見直す前提。
  - 離散的な事象（FMA の変化、メッセージの出現）は、きっかけから期限内に起これば合格。期限の既定は 2 秒（推定）。
  - 共通の不合格条件（全シナリオ）：想定外の EICAS warning、>OVERSPEED（FCOM p.1605 (15.30.3)）、stick shaker、指令していない >AUTOPILOT DISC・>AUTOTHROT DISC（FCOM p.677 (4.30.1)）、地上での CONFIG warning（FCOM p.1603 (15.30.1)。S03-N を除く）、主脚接地中の pitch ≥ 11°（胴体接地の可能性。FCTM p.225 (6.13)）。
  - 想定外の caution・advisory は「警告（不合格にしない）」として記録する。シナリオごとに「出てよいメッセージ」を挙げた。
- 機体と型式
  - 既定は PW4056（`laminar/B747/engines/type` = 0）、109 の手順と値。S02・S03・S06・S08・S11 は GE（type 1）と RR（type 2）でも回す。GE は 570 の値（初期推力 70 % N1、始動の中止条件など）、RR は FCTM の値（初期 EPR 1.2 まで、逆推力 70 kt）を使い、それ以外の RR の値は推定。
  - 重量の上限（109）：最大離陸 394,625 kg、最大着陸 285,763 kg、最大無燃料 244,939 kg（FCOM p.78 (L.10.2)）。
- 空港と気象
  - 既定は ISA、無風、CAVOK、乾燥滑走路。ILS（Cat III 相当）のある 3,000 m 以上の滑走路（例：RJAA 34L）。滑走路長・ILS・進入方式の有無は実行時に X-Plane の航法データで確かめる。
  - 横風を入れる変形は 25 kt 以下（autoland の限界：FCOM p.80 (L.10.4)。FCOM の非限界値は 30 kt：p.77）。追い風は 15 kt 以下（109、FCOM p.77 (L.10.1)）。

### 2.1 S01 cold and dark → 電源投入 → APU 始動 → IRS アライン → FMC preflight

- 目的：電源投入（SP.6）と preflight（NP.21）の順で、電源・APU・IRS・FMC・AFDS の初期状態が FCOM どおりになるかを見る。
- 前提
  - 駐機中、チョックあり。全スイッチ OFF（BATTERY OFF、STANDBY POWER OFF、IRS OFF、APU OFF、外部電源は使わない）。燃料 60,000 kg。ISA、昼間。
  - 想定時間 25 分（IRS 約 10 分を含む）。
- 手順と確認

  | # | きっかけ | 操作 | 確認（観測・許容） | 根拠 |
  |---|---|---|---|---|
  | 1 | 開始 | BATTERY ON | BATTERY の OFF 灯が消える。>BATTERY OFF が消える | FCOM p.179 (SP.6.1), p.821 (6.30.1) |
  | 2 | — | STANDBY POWER AUTO、DEMAND pump 全 OFF、wiper OFF、ALTN FLAPS OFF、gear lever DN、flap lever を flap 表示に合わせる、BUS TIE 全 AUTO | 交流バスは無電源なので ELEC AC BUS 1-4（caution）が出る（推定：battery で EICAS が表示されている場合） | FCOM p.179, p.821 |
  | 3 | — | APU selector を START に回して ON に戻す（ばねで ON に戻させない） | 燃料弁と inlet door が開き、door 全開で starter が入る。APU DOOR・APU FUEL・APU が出ない | FCOM p.180 (SP.6.2), p.896 (7.30.2), p.902 (7.40.4) |
  | 4 | APU N1 > 95 % | — | APU RUNNING（memo）。APU GEN 1・2 の AVAIL 灯。START から 120 秒以内（推定） | FCOM p.897 (7.30.3), p.902, p.180 |
  | 5 | AVAIL 灯 | APU GEN 1 を押し、続いて APU GEN 2 を押す | 各 ON 灯。ELEC AC BUS 1-4 が消える。ELEC synoptic：BUS 1-4 緑、BUS TIE の bar あり、GEN CONT は 4 つとも OFF（amber）。2 つ目の APU GEN で SSB が開く。ELEC GEN OFF 1-4（advisory、GCB 開）が出る（FCOM の条件文どおりなら） | FCOM p.180, p.791-792 (6.10.13-14), p.822 (6.30.2); ATA-24.md §4.2（LH24 p.123） |
  | 6 | — | IRS mode selector 3 つを OFF → NAV | IRS ALIGN MODE C, L, R（memo）。UNABLE RNP はアライン完了まで出てよい。YAW DAMPER の INOP 灯は最初の IRU がアラインするまで点灯 | FCOM p.95 (NP.21.1), p.1430 (11.60.2), p.107 (NP.21.13) |
  | 7 | — | STATUS 表示 | 酸素圧、油圧の量、エンジン油量が出る | FCOM p.95 |
  | 8 | — | F/O preflight：ENGINE AUTOSTART ON、EEC NORM、STBY POWER AUTO、UTILITY ON、BUS TIE AUTO、GEN CONT ON | EEC の ALTN 灯・UTILITY の OFF 灯・ISLN 灯が消灯。GEN CONT の OFF 灯と DRIVE 灯が点灯（エンジン停止で IDG 油圧が低い） | FCOM p.103-104 (NP.21.9-10); ATA-24.md §4.11 |
  | 9 | — | HYD：DEMAND 全 OFF、ENGINE pump 全 ON | SYS FAULT 灯と demand の PRESS 灯が点灯、ENGINE pump の PRESS 灯が点灯 | FCOM p.104 |
  | 10 | — | 燃料：X FEED 全 on、pump 全 off | X FEED の VALVE 灯消灯、main pump の PRESS 灯点灯。APU 運転中は main 2・3 aft pump の PRESS 灯は消灯、override 2・3 と center の PRESS 灯は消灯 | FCOM p.106 (NP.21.12) |
  | 11 | — | 防氷 OFF、WINDOW HEAT ON、YAW DAMPER ON、与圧（LDG ALT AUTO）、ECS、bleed（pack NORM、ISOLATION on、APU bleed ON、ENGINE BLEED ON）、灯火 | WINDOW HEAT の INOP 灯消灯、ISOLATION と APU bleed の VALVE 灯消灯 | FCOM p.106-109 (NP.21.12-15) |
  | 12 | — | FLIGHT DIRECTOR switch ON | FMA：A/T 空白、roll TO/GA、pitch TO/GA、AFDS FD（コード 0/1/1/1）。pitch bar 約 8° 上 | FCOM p.111 (NP.21.17), p.666 (4.20.8) |
  | 13 | — | CDU：IDENT（MODEL・ENGINES・nav DB の ACTIVE 日付）、POS INIT の SET IRS POS に現在位置 | 受け付けられる。ENTER IRS POSITION が出たら入れ直す | FCOM p.96-97 (NP.21.2-3), p.1431 (11.60.3) |
  | 14 | — | RTE：出発・目的地・経路、ACTIVATE と EXEC。DEPARTURES：滑走路と SID、EXEC。RNP を確認 | RTE・LEGS が計画どおり | FCOM p.97 |
  | 15 | — | PERF INIT：ZFW（GR WT に入れない）、燃料、reserve、cost index、CRZ ALT。THRUST LIM：TO（または derate）と CLB。TAKEOFF REF：flaps 20、CG、V speeds を選ぶ | CDU と EICAS の燃料が一致。両 CDU の V speeds が一致。VNAV を押しても PERF/VNAV UNAVAILABLE が出ない | FCOM p.97-98 (NP.21.3-4), p.1433 (11.60.5) |
  | 16 | 手順 6 から約 10 分、位置入力済み | — | IRS ALIGN memo が消え、SET IRS POS の入力が空になる。YAW DAMPER INOP 灯消灯。期限：位置入力と手順 6 の遅い方から 12 分（推定。FCOM は約 10 分） | FCOM p.1227 (11.20.3), p.107 |
  | 17 | アライン完了 | 計器を確認 | flag は TCAS OFF と NO VSPD（V speeds 選択前）だけ。V speeds 選択後は NO VSPD が消え、V1・VR・V2 と次の flap 上げの bug が出る | FCOM p.111; FCTM p.45 (1.15) |
  | 18 | — | 機長 preflight：MCP の FD ON、A/T ARM、BANK LIMIT AUTO、A/P DISENGAGE bar を上げる。SPEEDBRAKE DN、逆推力レバー下、推力レバー閉、flap lever を合わせる | FMA は手順 12 のまま | FCOM p.114, p.117 (NP.21.20, 21.23) |
  | 19 | — | PARKING BRAKE set、FUEL CONTROL 全 CUTOFF、AUTOBRAKES RTO | PARK BRAKE SET（memo）、AUTOBRAKES RTO（memo） | FCOM p.113, p.117, p.1522 (14.30.2) |

- 合否
  - 不合格：APU RUNNING が期限内に出ない、APU 系の advisory、APU GEN 投入後の ELEC AC BUS、IRS が期限内にアラインしない（位置を入れないのにアラインが完了するのも不合格）、手順 12 の FMA が違う、手順 17 で余分な flag、手順 19 の memo が出ない。
  - 警告：ELEC GEN OFF 1-4 の有無（FCOM の条件文の解釈。§未確認）、synoptic の SSB、手順 2 の ELEC AC BUS。
  - 出てよいメッセージ：ELEC GEN OFF 1-4、UNABLE RNP（アライン完了まで）、IRS ALIGN MODE、HYD PRESS DEM 1-4・HYD PRESS SYS 1-4（エンジン停止・pump OFF のため。推定）、PARK BRAKE SET、AUTOBRAKES RTO。

### 2.2 S02 エンジン始動（4 発）と taxi out

- 目的：Before Start から Before Takeoff まで。油圧と燃料の加圧、autostart、IDG への切替、APU の停止、taxi の速度と steering。
- 前提
  - S01 の終了状態（APU GEN 2 つで給電、IRS アライン済み、FMC 済み、parking brake set）。扉は閉。
  - 燃料 90,000 kg（center tank に 7,700 kg 以上入れ、center pump の手順を通す）。ISA（OAT 15 °C、防氷不要）。
  - pushback は省略（FCOM p.122 (NP.21.28) の手順は別試験）。
- 手順と確認

  | # | きっかけ | 操作 | 確認（観測・許容） | 根拠 |
  |---|---|---|---|---|
  | 1 | 開始 | CDU：機長は TAKEOFF REF、F/O は LEGS。MCP：IAS/MACH を V2、LNAV arm、VNAV arm、初期 heading、初期高度（例 5,000 ft） | PFD に MCP の IAS。FMA の roll・pitch の下段に LNAV・VNAV（armed：2 と 4）。active は TO/GA のまま | FCOM p.118 (NP.21.24), p.663-664 (4.20.5-6), p.669 (4.20.11) |
  | 2 | — | HYD：DEMAND 4 を AUX | SYS FAULT 4 消灯、demand 4 の PRESS 灯は点灯のまま。HYD PRESS DEM 4（advisory） | FCOM p.119 (NP.21.25), p.1495 (13.30.1) |
  | 3 | — | DEMAND 1・2・3 を AUTO | SYS FAULT 1-3 と demand の PRESS 灯が消える。STAT の HYD PR が 4 系統とも約 3,000 psi（±200 psi、推定）。HYD PRESS SYS が出ない | FCOM p.119, p.1483, p.1485 (13.10.1, 13.10.3) |
  | 4 | — | main tank の pump 全 ON。center tank 7,700 kg 以上なら CENTER pump ON | 各 PRESS 灯が消える | FCOM p.119 |
  | 5 | — | BEACON BOTH、RECALL、CANCEL | 想定どおりのメッセージだけ（FUEL TANK/ENG が出たら FCOM p.120 の処置） | FCOM p.119-120 (NP.21.25-26) |
  | 6 | — | stabilizer trim を TAKEOFF REF の値（greenband 内）、aileron trim 0、rudder trim 0 | trim 表示が greenband 内。STAB GREENBAND（advisory：nose gear の圧力センサーと計算した greenband の不一致）が出ない。greenband を外れたまま離陸推力にすると >CONFIG STAB（S03 で確認） | FCOM p.120-121 (NP.21.26-27), p.958 (9.30.2), p.1604 (15.30.2) |
  | 7 | — | 下 EICAS に secondary engine。pack を 2 つ（同時始動なら 3 つ）OFF | — | FCOM p.124 (NP.21.30) |
  | 8 | 各エンジン（順序は資料に記載なし。試験は 4→3→2→1） | START switch を引く | START 灯点灯（start valve 開） | FCOM p.879 (7.20.9) |
  | 9 | 直後 | FUEL CONTROL を RUN | 油圧が上がる。N2 40 % までに N1 が回る。所定の N2 で燃料と点火（EGT が上がる）。N2 50 % で starter cutout：START switch が戻り START 灯消灯。EGT は start limit 未満。idle で安定。RUN から安定まで 120 秒以内（推定。手動始動の中止条件「2 分で idle に達しない」を流用） | FCOM p.124, p.879-880 (7.20.9-10), p.185-186 (SP.7.3-4) |
  | 10 | 安定後 | — | ENG n AUTOSTART・STARTER CUTOUT n・ENG n START VLV が出ない。そのエンジンの ELEC GEN OFF n が消え、GEN CONT の OFF 灯と DRIVE 灯が消える。ENGINE pump の PRESS 灯が消える。期限：idle 安定から 30 秒（推定） | FCOM p.899, p.902 (7.40.1, 7.40.4), p.822, p.1484 (13.10.2); ATA-24.md §4.2, §4.11 |
  | 11 | 4 発とも idle | Before Taxi：APU selector OFF、DEMAND pump 全 AUTO、NACELLE ANTI-ICE は OFF のまま、pack NORM | APU RUNNING が消える（60 秒の cooldown の後に停止。OFF から 90 秒以内、推定）。HYD PRESS DEM 4 が消える。ELEC synoptic：GEN CONT の bar 4 つ、APU の接続なし | FCOM p.126 (NP.21.32), p.897 (7.30.3) |
  | 12 | — | 「FLAPS 20」、flap lever 20 | primary EICAS の flap 表示が 20 | FCOM p.126, p.954 (9.20.14) |
  | 13 | — | 操縦系統の確認（操縦輪・操縦桿・rudder pedal を全量、一方向ずつゆっくり） | EICAS の舵面表示が動き、中立に戻る | FCOM p.126 |
  | 14 | — | 下 EICAS を消す、transponder（STBY か TCAS 以外の active）、RECALL | 想定どおりのメッセージだけ | FCOM p.126-127 |
  | 15 | — | parking brake を外し、推力を少し上げ、動いたら idle | PARK BRAKE SET が消える。GS > 0 | FCTM p.76 (2.4); FCOM p.1522 |
  | 16 | 直線 | GS 20 kt 前後で taxi | GS ≤ 30 kt を常に守る。直線の平均 20 kt ±5 kt（推定） | FCTM p.77 (2.5) |
  | 17 | 30° を超える旋回の手前 | 減速して tiller で旋回 | 旋回に入るときの GS ≤ 10 kt。nose gear 角 > 20° かつ GS < 約 20 kt で body gear steering が働く | FCTM p.79 (2.7), p.78 (2.6) |
  | 18 | 待機点 | Before Takeoff：油温を確認、BEFORE TAKEOFF checklist | 全エンジンの油温が下側の amber band より上 | FCOM p.127 (NP.21.33) |

- 合否
  - 不合格：始動中止のメッセージ、N1 が 40 % N2 までに回らない、cutout が 50 % N2 ±2 %（推定）を外れる、START 灯が消えない、idle 安定後に ELEC GEN OFF n が残る、APU が止まらない、HYD PRESS SYS、GS > 30 kt、30° 超の旋回に 10 kt を超えて入る、逆推力を使う。
  - 警告：HYD PRESS DEM 4（手順 2）、旋回中の body gear steering の作動。
  - 変形 S02-V1：V speeds を入れた後に逆推力を選ぶ → 速度計の V speeds が消え、離陸の推力上限が full TO になる（FCTM p.77 (2.5)）。

### 2.3 S03 A/T による離陸、VNAV/LNAV arm、flap 上げ、巡航高度まで上昇

- 目的：離陸の FMA の流れ、引き起こし、初期上昇速度、VNAV の加速と推力基準の変化、flap 上げ、上昇から巡航への移行。
- 前提
  - S02 の終了状態で滑走路に入る直前。重量 300,000 kg（309,000 kg 未満で通常の flap 速度）、燃料 70,000 kg、flaps 20、TO（全推力）。
  - TAKEOFF REF：推力減少と加速の高度は 1,000 ft AFE（訓練の値。FCTM p.112 (3.24)）。CRZ ALT FL330。SID は 3,000 ft 未満に高度制限が無いもの。
  - 変形 S03-H：重量 370,000 kg（重量大の規則）。変形 S03-D：assumed temperature で 15 % 以上の減推力（CLB 2 の自動選択）。
- 手順と確認

  | # | きっかけ | 操作 | 確認（観測・許容） | 根拠 |
  |---|---|---|---|---|
  | 1 | 滑走路に入る | STROBE ON、transponder TA/RA、brake 解除、正対、離陸許可で inboard LANDING light ON | 滑走路方位が指定どおり | FCOM p.130 (NP.21.36) |
  | 2 | 正対 | 推力レバーを約 1.10 EPR（GE は約 70 % N1、RR は約 1.1〜1.2 EPR）へ進め、安定を待つ（2 秒以内） | 4 発の EPR（N1）がそろう | FCOM p.129-130; FCTM p.92 (3.4) |
  | 3 | 安定、IAS < 50 kt | TO/GA を押す | FMA：THR REF・TO/GA・TO/GA（5/1/1）、下段に LNAV・VNAV。AFDS FD。推力基準 TO。レバーが離陸推力へ。CONFIG 系の warning が出ない | FCOM p.656 (4.10.18), p.667 (4.20.9), p.669, p.1603 (15.30.1) |
  | 4 | IAS 65 kt | — | A/T が HOLD（1）。65 kt ±5 kt（推定） | FCOM p.667 |
  | 5 | IAS 80 kt | — | 離陸推力が整っている（EPR/N1 が基準 ±1 %、推定）。PM「80 KNOTS」 | FCTM p.93 (3.5); FCOM p.131 (NP.21.37) |
  | 6 | IAS = VR | 15° に向けて引き起こす（平均 2.5°/s） | 平均 pitch rate 2.0〜3.0°/s（推定）。VR から 3〜5 秒で浮揚。浮揚姿勢 約 10°（flaps 20 は 10.0°）。VR から約 6.5 秒で 35 ft | FCTM p.95-96 (3.7-3.8) |
  | 7 | 浮揚後 | F/D に従う | IAS が V2+10〜V2+25（下は -3 kt、上は +5 kt まで許す：推定）。V2 を割らない | FCTM p.111 (3.23); FCOM p.667 |
  | 8 | 高度計で正の上昇率 | gear lever UP | GEAR DISAGREE が出ない | FCOM p.131, p.1522; FCTM p.111 |
  | 9 | 50 ft（滑走路標高から） | — | roll が LNAV（2）（経路が滑走路から始まる場合。そうでなければ TO/GA のまま航跡を保つ） | FCOM p.667; FCTM p.112 (3.24) |
  | 10 | 400 ft AFE | — | pitch が VNAV SPD（4）、A/T が THR REF（5）。400 ft ±50 ft（推定） | FCOM p.667; FCTM p.112 |
  | 11 | 400〜1,000 ft（250 ft 以上） | A/P（C か L）を engage | AFDS が CMD（2）。モードは変わらない | FCOM p.79 (L.10.3), p.662 (4.20.4) |
  | 12 | 1,000 ft AFE（加速・推力減少の高度） | — | 推力基準が TO → CLB。VNAV の目標が T/O flap の placard −5 kt へ | FCOM p.667, p.1272 (11.32.2); FCTM p.112 |
  | 13 | IAS が speedtape の「10」（VREF30+20） | flap lever 10 | 目標が flaps 10 の placard −5 kt へ | FCOM p.132 (NP.21.38), p.667; FCTM p.113 (3.25) |
  | 14 | 「5」（VREF30+40） | flap lever 5 | 同上 | 同上 |
  | 15 | 「1」（VREF30+60） | flap lever 1 | 同上 | 同上 |
  | 16 | 「UP」（VREF30+80） | flap lever UP | 目標が VREF+100 と 250 kt の大きい方（10,000 ft 未満）。flap 表示は全上げの 10 秒後に消える | FCOM p.667, p.1328 (11.41.4), p.954 |
  | 17 | flap 上げ中 | — | 各 flap は bug 以上の速度で選ばれる。>AIRSPEED LOW・FLAP RELIEF が出ない。バンク ≤ 25°（S03-H は flaps up で UP+20 までバンク ≤ 15°） | FCTM p.35 (1.5), p.111; FCOM p.132, p.1605, p.957 |
  | 18 | flap 上げ完了 | gear lever OFF、pack を確認、After Takeoff checklist | — | FCOM p.130 |
  | 19 | 10,000 ft | inboard landing light OFF | VNAV が ECON 上昇速度へ加速。CLB ページは ACT ECON CLB | FCOM p.134 (NP.21.40), p.1326 (11.41.2), p.1327 |
  | 20 | transition altitude | 高度計を STD | — | FCOM p.134 |
  | 21 | FL330 に近づく | — | 水平になり、CDU は CLB → CRZ。FMA は SPD・LNAV・VNAV PTH（3/2/6。推定：FCOM の進入図と降下の説明から）。推力基準は CRZ か CLB（整備の設定） | FCOM p.1345 (11.42.1), p.672, p.1264, p.1273 (11.32.3) |
  | 22 | 水平後 5 分 | — | 高度 FL330 ±100 ft（推定。>ALTITUDE ALERT は 300 ft：FCOM p.1605） | — |

- 合否
  - 不合格：手順 3・4・9・10・12 の FMA と推力基準の変化が起きない・期限を外れる、主脚接地中の pitch ≥ 11°（尾部接地の姿勢は 12.5°：FCTM p.96）、浮揚後に V2 を割る、bug 未満で flap を上げる、>AIRSPEED LOW・>OVERSPEED・>ALTITUDE ALERT、手順 22 の高度。
  - 警告：引き起こしの率と時間、35 ft の時刻、初期上昇速度の帯、ECON 速度。
  - 変形 S03-D：THRUST LIM で CLB 2 が自動で選ばれる（減推力 15 % 以上）。109 は 10,000 ft まで 20 % 減で、35,000 ft で CLB に戻る（FCOM p.1273）。上昇率が約 500 fpm を割らない（FCTM p.123 (4.1)）。
  - 変形 S03-N（負の試験）：parking brake を set したまま推力を離陸範囲へ → >CONFIG PARK BRK。flap を離陸位置以外にして同様 → >CONFIG FLAPS（FCOM p.1603）。

### 2.4 S04 巡航と step climb

- 目的：CRZ ページの step climb の予測と、MCP の altitude selector による cruise climb。
- 前提：巡航 FL310、重量 290,000 kg、ISA、無風。A/P CMD、LNAV、VNAV（VNAV PTH）、A/T SPD。T/D まで 500 NM 以上。STEP SIZE は ICAO。FL350 への許可が出ている想定。
- 手順と確認

  | # | きっかけ | 操作 | 確認（観測・許容） | 根拠 |
  |---|---|---|---|---|
  | 1 | 開始 | VNAV キーで CRZ ページ | 表題 ACT ECON CRZ。STEP TO（OPT より上）、AT（step 点の ETA と距離）、OPT・MAX が出る | FCOM p.1347-1350 (11.42.3-6) |
  | 2 | AT が NOW（step 点を通過） | MCP 高度を STEP TO（例 FL350）にして altitude selector を押す | 表題 ACT ECON CRZ CLB、CRZ ALT が新しい高度（modification を作らない）。pitch は VNAV SPD、A/T は基準推力（推定：上昇中の altitude intervention の説明から） | FCOM p.1257 (11.31.23), p.1348 (11.42.4), p.1256 (11.31.22) |
  | 3 | 上昇中 | — | LNAV を保つ。速度は ECON（±5 kt か ±0.01M、推定） | FCTM p.129 (4.7) |
  | 4 | 新しい高度に近づく | — | 水平になり表題 ACT ECON CRZ。FMA は SPD・LNAV・VNAV PTH（推定） | FCOM p.1345 (11.42.1), p.1264 (11.31.30) |
  | 5 | 水平後 | — | OPT・MAX・STEP TO が更新される。高度 ±100 ft（推定） | FCOM p.1349-1350 |

- 合否
  - 不合格：selector を押しても上昇しない、CRZ ALT が変わらない、上昇中に A/P が切れる、>ALTITUDE ALERT・>AIRSPEED LOW・>OVERSPEED。
  - 警告：上昇中の A/T モードと推力基準（資料に記載なし）、速度の帯。
  - 変形 S04-V1：STEP TO を CRZ ページに手で入れる → ND に S/C、CRZ ページの AT がその点を示す（FCOM p.1257, p.1348）。
  - 変形 S04-V2：T/D の 50 NM より手前で MCP 高度を下げて selector を押す → cruise descent（表題 ACT ECON CRZ DES）（FCOM p.1257）。

### 2.5 S05 VNAV PTH による降下（速度制限つき）

- 目的：降下 path の生成、T/D、速度制限の手前の減速、speed intervention、path からのずれの扱い。
- 前提
  - 巡航 FL330、T/D の 150 NM 以上手前。重量 260,000 kg（最大着陸重量未満）。ISA、無風。DESCENT FORECAST は無風、防氷高度なし。
  - LEGS：目的地の約 40 NM 手前の waypoint W1 に「250/10000」（at）、その先の W2 に「/4000A」（入力形式：FCOM p.1332 (11.41.8)）。DES ページの SPD TRANS は 240/10000（目的地の制限速度の 10 kt 下。database に無ければ既定 240 kt・10,000 ft：FCOM p.1392 (11.43.4)）。
  - 目的地は ILS のある空港（S06 に続ける）。
- 手順と確認

  | # | きっかけ | 操作 | 確認（観測・許容） | 根拠 |
  |---|---|---|---|---|
  | 1 | T/D の前 | 到着と進入の経路を整え RNP を確認。Descent Procedure：alert の見直し、APPROACH REF で flaps 30 の VREF、minimums、NAV RADIO、AUTOBRAKES 2 | AUTOBRAKES 2（memo）。LEGS の W1・W2 に大きな字で制限 | FCOM p.136 (NP.21.42), p.1522, p.1332 |
  | 2 | T/D の 2 分前、MCP は FL330 のまま | — | CDU に RESET MCP ALT | FCOM p.665 (4.20.7), p.1433 (11.60.5) |
  | 3 | — | MCP 高度を 10,000 ft（W1 の制限）にする | — | FCTM p.137 (4.15) |
  | 4 | T/D | — | 降下開始。A/T は IDLE の後 HOLD（2→1）、pitch は VNAV PTH（6）。T/D で減速が要れば水平で減速 | FCOM p.662 (4.20.4), p.1264 (11.31.30); FCTM p.137 |
  | 5 | 降下中（W1 より上） | — | 経路からのずれ ≤ 150 ft。速度は ECON 降下速度（349 kt を超えない）。DRAG REQUIRED・THRUST REQUIRED が出ない（無風なので。推定） | FCOM p.1258-1259 (11.31.24-25) |
  | 6 | 10,000 ft の手前 | — | VNAV PTH のまま約 500 fpm の減速区間で 240 kt へ（降下率 300〜700 fpm：推定） | FCOM p.1258, p.1264; FCTM p.137 |
  | 7 | W1 通過 | — | 高度 10,000 ft ±100 ft（推定）、IAS ≤ 250 kt（+5 kt まで許す：推定） | FCOM p.1332（速度制限は「以下」） |
  | 8 | W1 通過後 | MCP 高度を 4,000 ft、IAS/MACH selector を押して 220 kt（speed intervention） | DES ページの表題が MCP SPD。VNAV PTH なら推力か speedbrake で 220 kt ±10 kt（ATC の許容） | FCOM p.1391 (11.43.3); FCTM p.137, p.140 (4.18) |
  | 9 | DRAG REQUIRED が出たら | speedbrake を出す（PF は lever に手）。目標に近づいたら戻す | flaps 20 を超えて使わない（FCTM の技法では 5）。1,000 ft AGL までに格納。戻した後に VMO を超えない | FCTM p.139-140 (4.17-4.18); FCOM p.83 (L.10.7) |
  | 10 | transition level | 高度計 QNH、Approach Procedure、inboard landing light ON（10,000 ft 以上で。すでに下なら到達時） | — | FCOM p.138 (NP.21.44) |
  | 11 | W2 | — | 4,000 ft 以上で通過 | FCOM p.1332 |

- 合否
  - 不合格：降下中に計画外で VNAV PTH から VNAV SPD に戻る、経路のずれ > 150 ft、W1 の高度・速度、10,000 ft 未満で 250 kt +5 kt を超える、>OVERSPEED、手順 2 の RESET MCP ALT が出ない。
  - 警告：減速区間の降下率、T/D の位置が「3 NM / 1,000 ft」から ±15 % を超えてずれる（推定。FCTM p.138 (4.16) の目安）。
  - 変形 S05-V1：T/D の 50 NM 以内で DES NOW → early descent（A/T は THR の後 HOLD、pitch VNAV SPD）、idle の path に乗ったら VNAV PTH（FCOM p.1260-1261 (11.31.26-27)）。
  - 変形 S05-V2：DES FORECAST に無い向かい風を入れる → 遅れると A/T が SPD で推力を足す。150 ft を保てなければ VNAV SPD に戻り THRUST REQUIRED（FCOM p.1259）。

### 2.6 S06 ILS 進入、autoland、rollout、autobrake

- 目的：APP の arm と捕捉、LAND 3、flare・idle・rollout の高さ、ground spoiler、autobrake、逆推力と A/T、着陸後の処置。
- 前提
  - S05 の続き、または IAF 相当の状態から開始：滑走路から約 15 NM、3,000 ft AGL、LOC への intercept heading（30°）を HDG SEL、ALT（または VNAV PTH）、flaps 5・flaps 5 機動速度、A/P 1 基で CMD、A/T SPD。
  - 重量 250,000 kg、着陸 flap 30、AUTOBRAKES 3。無風、乾燥、ILS 3.0°（Cat III 相当）。油圧 4 系統とも正常（Cat III の autoland に必要：FCTM p.161 (5.15)）。
  - 変形 S06-X：横風 15 kt。変形 S06-E：進入前にエンジン 4 を停止（片発の autoland）。
- 手順と確認

  | # | きっかけ | 操作 | 確認（観測・許容） | 根拠 |
  |---|---|---|---|---|
  | 1 | 開始 | flap 展開表に従う（「UP」で 1・速度「1」、「1」で 5・速度「5」） | 各 flap は今の flap の速度を割る前に選ばれる | FCOM p.138-139 (NP.21.44-45); FCTM p.35 (1.5) |
  | 2 | intercept heading 上 | ILS の tune と識別（周波数が識別符号に変わる）、LOC と G/S の pointer を確認、APP を arm | armed roll が LOC（3）、armed pitch が G/S（2） | FCOM p.141 (NP.21.47), p.669 (4.20.11); FCTM p.147, p.157-158 |
  | 3 | LOC 捕捉 | — | active roll が LOC（3）。heading bug が inbound course へ動く。捕捉中のバンク ≤ 30°。LOC の目盛りが約 5/8 dot で拡大表示になる | FCTM p.158 (5.12), p.160 (5.14); FCOM p.672 (4.20.14) |
  | 4 | G/S alive（G/S pointer が動き始める。2 dot 以内に入ったとき：推定） | 「GEAR DOWN」「FLAPS 20」、gear DN、flap 20、SPEEDBRAKE ARM、速度「20」 | SPEEDBRAKE ARMED（memo）。>CONFIG GEAR が出ない | FCOM p.141, p.958 (9.30.2), p.1603 (15.30.1); FCTM p.158 |
  | 5 | G/S 捕捉 | 着陸 flap 30、MCP 速度 VREF+5、MCP に missed approach altitude（例 3,000 ft）、Landing checklist | active pitch が G/S（2）。推力基準 GA。FLAP RELIEF が出ない | FCOM p.141, p.672, p.957 (9.30.1); FCTM p.43 (1.13), p.158 |
  | 6 | FAF（OM） | — | 通過高度が公示値 ±100 ft（推定） | FCOM p.141; FCTM p.158 |
  | 7 | 1,500 ft RA 未満 | — | AFDS が LAND 3（4）。armed roll が ROLLOUT（4）、armed pitch が FLARE（3）。ELEC synoptic に「ELECTRICAL SYNOPTIC INHIBITED FOR AUTOLAND」 | FCOM p.662 (4.20.4), p.664-665 (4.20.6-7), p.672, p.789 (6.10.11); FCTM p.159 (5.13); ATA-24.md §4.13 |
  | 8 | 1,000 ft AFE | — | 安定進入：LOC・G/S とも 1 dot 以内、VREF〜VREF+20、降下率 ≤ 1,000 fpm、着陸形態 | FCTM p.151 (5.5) |
  | 9 | 500 ft RA | — | LAND 3 のまま（「500 FEET」「LAND 3」） | FCOM p.142 (NP.21.48); FCTM p.48 (1.18) |
  | 10 | 60〜40 ft RA | — | active pitch が FLARE（3）。許容 70〜30 ft（推定） | FCOM p.665, p.671 (4.20.13) |
  | 11 | 25 ft RA | — | A/T が IDLE（2）、レバーが idle へ。許容 ±5 ft（推定） | FCOM p.671 |
  | 12 | 約 5 ft RA | — | active roll が ROLLOUT（4）。10 ft 以下で（推定） | FCOM p.664, p.671 |
  | 13 | 主脚接地 | — | FLARE の表示が消え nose が下がる。SPEEDBRAKE lever が UP（2 秒以内：推定）。autobrake が効き始める（3 秒以内：推定）。接地点は TDZ 内（最初の 3,000 ft か 1/3 の短い方）。接地時の pitch 4〜5° 前後（7° 超は警告：推定。11° 以上は不合格）。降下率 ≤ 360 fpm（警告）、≤ 600 fpm（不合格の境：推定。資料に記載なし）。中心線からの横ずれ ≤ 8 m（推定） | FCOM p.671, p.951 (9.20.11), p.1515 (14.20.5); FCTM p.151, p.223 (6.11), p.225 (6.13) |
  | 14 | 接地後 | 逆推力レバーを interlock まで上げ、外れたら必要な量 | A/T が切れる（FMA の A/T が空白：推定）。>AUTOTHROT DISC は出ない | FCOM p.148 (NP.21.54), p.666 (4.20.8), p.677 (4.30.1); FCTM p.238 (6.26) |
  | 15 | 60 kt | 逆推力を絞り始め、taxi 速度までに reverse idle、その後 full down | taxi 速度（30 kt：推定）で reverse idle | FCOM p.148; FCTM p.238 |
  | 16 | taxi 速度の前 | brake pedal を踏んで autobrake を解除 | AUTOBRAKES selector が DISARM。手動制動に移る | FCOM p.148, p.1516 (14.20.6) |
  | 17 | 滑走路を出る前 | A/P disengage switch を 2 回押す | 1 回目で >AUTOPILOT DISC・master warning・wailer（1 秒以上）、2 回目で消える。ELEC synoptic の抑止が解ける | FCOM p.148, p.655 (4.10.17); ATA-24.md §4.13 |
  | 18 | 滑走路を出た | After Landing：SPEEDBRAKE DOWN、APU START→ON、WXR off、AUTOBRAKES OFF、flap UP、transponder | SPEEDBRAKE ARMED・AUTOBRAKES memo が消える。flap 表示は全上げ 10 秒後に消える | FCOM p.149 (NP.21.55), p.954 (9.20.14) |

- 合否
  - 不合格：手順 2・3・5・7・10・11・12 の FMA が起きない・期限外、500 ft RA で LAND 3 でない、NO AUTOLAND、指令していない A/P 解除、TDZ の外で接地、接地時の pitch ≥ 11°、ground spoiler か autobrake が働かない、滑走路を外れる（横ずれ > 8 m：推定）、手順 14 で >AUTOTHROT DISC が出る。
  - 警告：手順 8 の安定条件、FAF の通過高度、接地の降下率と姿勢、LOC 目盛りの拡大、synoptic の抑止。
  - 変形 S06-X（横風 15 kt）：crab が 10° を超えれば 500 ft AGL で 5° の sideslip、5〜10° なら 500 ft と 200 ft の 2 段、5° 未満なら 200 ft で整列。接地時は風上翼が下がる（FCOM p.670 (4.20.12); FCTM p.159）。
  - 変形 S06-E（進入前にエンジン 4 停止）：LAND 2/3 の後は A/P が rudder を受け持つ。1,300 ft AGL で wings level の sideslip。故障エンジン側からの横風なら sideslip で wings level、反対側からの中・強の横風なら sideslip なし（FCOM p.670; FCTM p.168-169 (5.22-5.23)）。A/T は使える（FCTM p.169）。

### 2.7 S07 進入からの go-around

- 目的：TO/GA の推力と FMA、高度の損失、A/P の 1 基への復帰、flap 上げ、climb thrust、missed approach altitude の捕捉。
- 前提：S06 の手順 9 までと同じ状態（LAND 3、flaps 30、gear down、VREF+5、MCP に missed approach altitude 3,000 ft）。DA 200 ft RA。missed approach の経路が FMC に入っている。目視参照は得られない設定。
- 手順と確認

  | # | きっかけ | 操作 | 確認（観測・許容） | 根拠 |
  |---|---|---|---|---|
  | 1 | 200 ft RA | TO/GA を押し、同時に「FLAPS 20」で flap lever 20 | FMA が THR・TO/GA・TO/GA（4/1/1）、1 秒以内（推定）。推力が増える（推力基準 GA）。go-around 姿勢へ回転（pitch ≤ 20°：推定）。A/P は切れない | FCOM p.147 (NP.21.53), p.672-673 (4.20.14-15); FCTM p.206 (5.60) |
  | 2 | 開始から 10 秒 | — | 高度の損失 ≤ 40 ft（許容 60 ft：推定）。昇降率は約 2,000 fpm（±500 fpm：推定）。IAS は MCP 速度〜MCP 速度+25 kt（+5 kt まで許す：推定）。>AIRSPEED LOW が出ない。TO/GA かつ RA 100 ft 超で autoland のバス分離が解け、ELEC synoptic の抑止が消える | FCTM p.206, p.208 (5.62); FCOM p.664 (4.20.6), p.673; ATA-24.md §4.13 |
  | 3 | 高度計で正の上昇率 | 「GEAR UP」、gear lever UP | — | FCOM p.147 |
  | 4 | 400 ft RA 超 | LNAV を押す | active roll が LNAV（2）。A/P が 1 基に戻り AFDS は CMD（2）。>AUTOPILOT DISC は出ない（1 基残る） | FCOM p.673, p.677; FCTM p.207 (5.61) |
  | 5 | — | missed approach altitude と経路を確認 | 経路の横ずれ ≤ 0.3 NM（推定） | FCOM p.147 |
  | 6 | 1,000 ft AGL（訓練の加速高度） | FLCH を押し、MCP 速度を予定 flap（UP）の機動速度に | active pitch が FLCH SPD（8） | FCOM p.147; FCTM p.207 |
  | 7 | speedtape の「10」「5」「1」「UP」 | 順に flap lever を 10、5、1、UP | bug 以上の速度で選ばれる。>AIRSPEED LOW・>OVERSPEED が出ない | FCOM p.132 (NP.21.38), p.147 |
  | 8 | 予定の flap（UP） | MCP の THR を押す | 推力基準が CLB | FCOM p.147; FCTM p.207 |
  | 9 | 3,000 ft に近づく | — | active pitch が ALT（9）、A/T は SPD（3）（推定：FCOM に FLCH の捕捉後の A/T モードの記述なし）。3,000 ft ±100 ft（推定）、>ALTITUDE ALERT が出ない | FCOM p.665 (4.20.7), p.1605 |
  | 10 | 水平後 | gear lever OFF、After Takeoff checklist | — | FCOM p.147 |

- 合否
  - 不合格：手順 1 の FMA、高度の損失 > 60 ft、地面への接触、手順 4 で A/P が全部切れる（>AUTOPILOT DISC）か 1 基に戻らない、flap の過速度、手順 8 で CLB にならない、手順 9 の捕捉。
  - 警告：昇降率と速度の帯。
  - 変形 S07-V1：TO/GA を 2 回押す → A/T が THR REF（5）で GA 全推力（FCOM p.673）。
  - 変形 S07-V2：手順 6 で VNAV を押す（1,000 ft RA 超）→ THR REF・LNAV・VNAV SPD、推力基準 CLB。missed approach altitude で VNAV PTH・A/T SPD（FCOM p.674 (4.20.16)）。missed approach の最高高度が新しい CRZ ALT になる（FCOM p.1262 (11.31.28)）。
  - 変形 S07-V3（接地後の go-around。逆推力は使わない）：接地後に推力レバーを進める → SPEEDBRAKE lever が DN に戻り、autobrake が解除される（FCOM p.951, p.1515; FCTM p.208）。接地で RA 5 ft 未満になって 2 秒後から TO/GA は効かず、5 ft を超えて 3 秒後に効く（FCOM p.673）。F/D の go-around は浮揚後に選び直すまで出ない（FCTM p.208）。
  - 変形 S07-V4（軽量で低い高度に止める）：重量 230,000 kg、MCP 1,500 ft AFE。TO/GA は 1 回だけ。行き過ぎ ≤ 200 ft（推定。FCTM p.208 の注意点の確認）。

### 2.8 S08 V1 後のエンジン故障（手動操縦）

- 目的：V1 後の片発での方向保持、引き起こし、F/D の目標速度、VNAV の片発加速と CON への切替、A/T の継続。
- 前提
  - S03 と同じ（300,000 kg、flaps 20、TO 全推力、乾燥、無風、LNAV・VNAV arm）。A/P は flap 上げ完了まで入れない（F/D で手動）。
  - 操縦モデル（ハーネス側）：pitch と roll は F/D の指令に追従。地上は rudder（と rudder pedal steering）で中心線を保ち、浮揚後は rudder で control wheel をほぼ中立にして rudder trim で踏力を抜く（FCTM p.114 (3.26), p.251 (7.3)）。F/D 指令の候補は機体が作る `laminar/B747/autopilot/flight_director_pitch_deg`（INTERFACES.tsv にあり、PFD が使う）と `.../flight_director_roll_deg`（plugins/xtlua_keysystems/init/scripts/B747.19.hydraulicsmodel/B747.19.hydraulicsmodel.lua:25-26）。roll 側は INTERFACES.tsv に無いので、作り直しで残るかは要確認。
  - 故障の注入：エンジン 1（左外側）を V1+3 kt（推定。「V1 後」を満たす値）で停止させる。ENG 1 FAIL を見るので fuel control の CUTOFF ではなく、X-Plane の engine failure などで燃焼を止める（方法は要確認。CUTOFF だと >ENG 1 SHUTDOWN になる：FCOM p.902 (7.40.4)）。
- 手順と確認

  | # | きっかけ | 操作 | 確認（観測・許容） | 根拠 |
  |---|---|---|---|---|
  | 1 | — | S03 の手順 1〜5（TO/GA、65 kt で HOLD、80 kt） | S03 と同じ | S03 |
  | 2 | V1+3 kt | エンジン 1 を停止させる | 推力の非対称。ハーネスは推力の減り方に合わせて rudder。浮揚まで中心線からのずれ ≤ 8 m、方位 ±2°（推定）。地上では ENG 1 FAIL は出ない（地上で抑止） | FCTM p.114 (3.26); FCOM p.899 (7.40.1) |
  | 3 | VR | 通常より 0.5°/s 遅く、12〜13° へ引き起こす | 約 5 秒で浮揚、浮揚姿勢 約 10.6°。主脚接地中の pitch < 11°。10〜12 秒で 35 ft | FCTM p.114-116 (3.26-3.28) |
  | 4 | 浮揚後 | F/D に従う | F/D の目標は V2 か浮揚時の速度の大きい方。IAS は V2〜V2+10（V2-5 kt を 3 秒以上割れば不合格、上は +5 kt まで許す：推定）。roll は TO/GA で航跡を保つ（±3°：推定）。バンク ≤ 15°（推定。旋回は計画しない）。ENG 1 FAIL（caution、master caution と beeper）が浮揚後 5 秒以内（推定） | FCOM p.667 (4.20.9), p.899; FCTM p.117 (3.29) |
  | 5 | 正の上昇率 | gear lever UP | — | FCTM p.117 |
  | 6 | 400 ft AFE | — | pitch が VNAV SPD（4）、目標 V2+10。A/T は THR REF（5）で離陸推力。A/T は切れない（1 発停止では切れない） | FCOM p.667, p.1266 (11.31.32), p.666 (4.20.8); FCTM p.133 (4.11) |
  | 7 | 1,000 ft AFE（訓練の片発加速高度） | F/D に従ってほぼ水平で加速、flap を bug ごとに上げる（20→10→5→1→UP）、rudder と trim で wheel を中立に | VNAV の目標が VREF+100（flap placard まで）、CLB ページ表題 ACT VREF + 100 CLB。加速中の高度の減少 ≤ 100 ft（推定）。>AIRSPEED LOW が出ない | FCOM p.1265-1266 (11.31.31-32), p.132; FCTM p.118 (3.30) |
  | 8 | flaps up かつ IAS ≥ VREF+98 | — | 推力基準が CON（自動）。VREF+100 で上昇（±5 kt：推定） | FCOM p.1266, p.1272 (11.32.2); FCTM p.118 |
  | 9 | rudder trim が取れた（250 ft 以上） | A/P を engage（任意） | CMD。方位が保たれる | FCTM p.118; FCOM p.79 (L.10.3) |
  | 10 | 3,000 ft（障害物クリアの高度として） | CLB ページの ENG OUT → EXEC | E/O CLB が active、pitch VNAV SPD、推力基準 CON | FCOM p.1341 (11.41.17), p.1266; FCTM p.126 (4.4) |
  | 11 | — | After Takeoff checklist（エンジン故障の NNC は資料に記載なし） | — | FCTM p.119 (3.31), p.284 (8.6) |

- 合否
  - 不合格：滑走路上で中心線から 8 m を超えてずれる（推定）、主脚接地中の pitch ≥ 11°、IAS が V2-5 kt を 3 秒以上割る、バンク > 15°、浮揚後に ENG 1 FAIL が出ない、>AUTOTHROT DISC、手順 8 で CON にならない、stick shaker・>AIRSPEED LOW、正の上昇勾配を失う（加速区間を除く）。
  - 警告：引き起こしの率と時間、35 ft の時刻、V2〜V2+10 の帯、航跡のずれ。
  - 変形 S08-ATM：assumed temperature で離陸し、浮揚後に TO/GA を押す → 離陸の減推力が外れ THR REF で最大推力（FCOM p.656 (4.10.18); FCTM p.119）。
  - 変形 S08-2：flap 上げ中に 2 発目（同じ側のエンジン 2）を停止 → 推力を増し、低速では外側を少し絞る。A/T は切れ戻せない（FCTM p.117; FCOM p.666）。

### 2.9 S09 VNAV による非 ILS 進入

- 目的：RNAV 進入での LNAV/VNAV PTH、speed intervention、MCP の高度の扱い（DA → missed approach altitude）、DA での A/P・A/T 解除。
- 前提
  - final に GP 角（例 3.00°）がある RNAV（GNSS）進入を ARRIVALS から選ぶ。FAF の約 20 NM 手前を vector 中、4,000 ft、flaps 1、A/P CMD、A/T SPD、HDG SEL、ALT。
  - 重量 250,000 kg、着陸 flap 30、AUTOBRAKES 2、ISA、無風。baro minimums に LNAV/VNAV の DA（MDA しか無ければ MDA+50 ft）。missed approach altitude はチャートどおり。
  - 変形 S09-C：ISA-20 °C（GP が実質浅くなる。寒冷補正：FCTM p.181, p.184; FCOM p.209 (SP.16.9)）。
- 手順と確認

  | # | きっかけ | 操作 | 確認（観測・許容） | 根拠 |
  |---|---|---|---|---|
  | 1 | 開始 | waypoint を足さない。FAF への straight-in intercept course。RNP 0.3 を確認。baro minimums を設定 | LEGS の final に GP 角。進入の RNP は最初の進入 waypoint を通過すると表示 | FCTM p.177 (5.31), p.186 (5.40); FCOM p.143 (NP.21.49) |
  | 2 | intercept heading に近づく | flap 5（速度「5」）、LNAV を arm | armed roll が LNAV（2） | FCOM p.143; FCTM p.187 (5.41) |
  | 3 | 捕捉 | — | active roll が LNAV（2） | FCOM p.143 |
  | 4 | FAF の約 2 NM 手前、ALT・VNAV PTH・VNAV ALT のどれかが出ている | A/P を確認、MCP 高度を DA（100 ft 単位に切り下げ）、VNAV を押す、speed intervention（IAS 窓を開く）。PM「APPROACHING GLIDE PATH」、gear DN、flap 20、SPEEDBRAKE ARM | active pitch が VNAV PTH（6）。IAS 窓が開き VNAV PTH のまま指定速度になる（on approach の機能）。DES ページの表題が MCP SPD。SPEEDBRAKE ARMED（memo） | FCOM p.144 (NP.21.50), p.1261 (11.31.27), p.1391 (11.43.3), p.958; FCTM p.186-187 |
  | 5 | final の降下開始 | 着陸 flap 30、速度 VREF+5、Landing checklist | VNAV PTH のまま。path からのずれ ≤ 75 ft（推定）、150 ft を超えたら不合格（FMC が VNAV SPD に戻す境）。LNAV の横ずれ ≤ 0.15 NM（推定：RNP 0.3 の半分。FCTM p.59 の「RNP は許容偏位の 50 %」）。VREF〜VREF+20、降下率 ≤ 1,000 fpm。UNABLE RNP が出ない | FCOM p.144, p.1262 (11.31.28); FCTM p.59 (1.29), p.151 (5.5), p.152 (5.6) |
  | 6 | FAF に「at」制限がある場合 | — | FAF 付近の短い水平区間（fly-off）は 0.5 NM まで許す（推定） | FCTM p.183 (5.37) |
  | 7 | missed approach altitude の 300 ft 以上下 | MCP 高度を missed approach altitude に | VNAV PTH のまま降下を続ける（VNAV ALT にならない） | FCOM p.144, p.1261; FCTM p.187 |
  | 8 | FAF | — | 通過高度が制限 ±50 ft（推定）。高度計の照合 | FCOM p.144 |
  | 9 | DA（目視ありの設定） | A/P disengage switch を 2 回、A/T disconnect switch を 2 回 | >AUTOPILOT DISC（master warning、wailer）→ 2 回目で消える。>AUTOTHROT DISC（master caution）→ 2 回目で消える。A/P は DA-50 ft より上で切れている（推定：FCOM の MDA の制限を DA にも当てる） | FCOM p.144, p.80 (L.10.4), p.655-657 (4.10.17-19); FCTM p.188 (5.42) |
  | 10 | DA-100 ft | 終了（任意で手動着陸を続ける） | — | — |

- 合否
  - 不合格：final で VNAV PTH を保てない（VNAV SPD・VNAV ALT への計画外の変化）、path のずれ > 150 ft、UNABLE RNP、手順 7 で水平になる、手順 9 で A/P が DA-50 ft までに切れていない、>AIRSPEED LOW。
  - 警告：path のずれ 75〜150 ft、横ずれ、FAF の通過高度、安定条件。
  - 変形 S09-MA（DA で目視なし）：TO/GA → VNAV と LNAV は 400 ft RA を超えてから入る。現在高度より下の降下制限が消え、missed approach の最高高度が新しい CRZ ALT、FMC は active climb。missed approach では VNAV SPD、missed approach altitude で VNAV PTH（FCOM p.1262 (11.31.28), p.1264 (11.31.30)）。VNAV の path 指令は missed approach fix を過ぎると水平（FCTM p.189 (5.43)）。
  - 変形 S09-VS（V/S 進入、MDA）：FAF 以降で V/S -700〜-800 fpm（チャートが無い場合）、MDA で水平区間を作らない、MDA の約 300 ft 上で missed approach altitude、MDA を割る前に A/P と A/T を切る（FCTM p.190-192 (5.44-5.46); FCOM p.174-175 (SP.4.4-4.5)）。

### 2.10 S10 エンジン停止と secure

- 目的：After Landing・Shutdown・Secure・Electrical Power Down の順で、電源の引継ぎ、エンジン停止、APU の停止を見る。
- 前提：S06 の後、滑走路を出て駐機場へ taxi 中。APU は After Landing で始動済み。エンジンは taxi 推力。
- 手順と確認

  | # | きっかけ | 操作 | 確認（観測・許容） | 根拠 |
  |---|---|---|---|---|
  | 1 | 滑走路を出た | After Landing（S06 の手順 18） | APU RUNNING（memo）。AUTOBRAKES memo が消える | FCOM p.149 (NP.21.55), p.902 |
  | 2 | taxi | FCTM の taxi 速度で駐機場へ | 最後の推力増（taxi 推力超）から停止まで 90 秒以上（要件。推奨は 5 分） | FCOM p.149; FCTM p.77 |
  | 3 | 停止 | PARKING BRAKE set | PARK BRAKE SET（memo） | FCOM p.150 (NP.21.56), p.1522 |
  | 4 | — | APU GEN 1・2 の AVAIL を確かめて押す | ON 灯。ELEC AC BUS が出ない（断なしで引き継ぐ） | FCOM p.150-151 (NP.21.56-57); ATA-24.md §4.2 |
  | 5 | — | DEMAND 4 を AUX。駐機なので DEMAND 1・2・3 を OFF | — | FCOM p.151-152 (NP.21.57-58) |
  | 6 | — | FUEL CONTROL 全 CUTOFF | 4 発とも N2 が下がり 3 分以内に 5 % 未満（推定）。EGT が下がる。ELEC AC BUS は出ない。ELEC GEN OFF 1-4 が出る（GCB 開。警告扱い） | FCOM p.152, p.822 (6.30.2) |
  | 7 | — | SEATBELTS OFF、燃料 pump 全 OFF、NACELLE・WING ANTI-ICE OFF、BEACON OFF、FD 全 OFF、status を確認・記録、transponder STBY | FD の bar が消える | FCOM p.152 |
  | 8 | チョック設置 | parking brake を外す、DEMAND 4 OFF、APU は残す、SHUTDOWN checklist | PARK BRAKE SET が消える | FCOM p.152-153 (NP.21.58-59) |
  | 9 | — | Secure：IRS 全 OFF、EMERGENCY LIGHTS OFF、AFT CARGO HEAT OFF、PACK 全 OFF、SECURE checklist | IRS のアラインが失われる | FCOM p.153 (NP.21.59), p.1227 (11.20.3) |
  | 10 | — | Power Down：APU selector OFF | APU bleed valve が閉じ、60 秒の cooldown の後に停止。APU RUNNING が消える | FCOM p.180 (SP.6.2), p.897 (7.30.3) |
  | 11 | — | STANDBY POWER OFF | — | FCOM p.180 |
  | 12 | APU OFF から 2 分以上、停止完了 | BATTERY OFF | 表示がすべて消える（推定） | FCOM p.180, p.897 |

- 合否
  - 不合格：手順 4・6 で ELEC AC BUS、エンジンが止まらない、APU が cooldown なしで止まる（BATTERY を早く切った場合を除く）か止まらない、PARK BRAKE SET の出入りが違う。
  - 警告：冷却時間、ELEC GEN OFF 1-4、HYD PRESS SYS 1-3（pump OFF とエンジン停止のため出るはず：推定）、>ENG n SHUTDOWN の有無（§未確認）。
  - 変形 S10-V1：APU の cooldown 中に BATTERY OFF → APU はすぐ止まる（FCOM p.897）。

### 2.11 S11 離陸中止（追加）

- 目的：RTO autobrake、逆推力レバーによる ground spoiler、A/T の扱い（HOLD の前後）。
- 前提：S03 と同じ。AUTOBRAKES RTO、SPEEDBRAKE DN。
- 手順と確認

  | # | きっかけ | 操作 | 確認（観測・許容） | 根拠 |
  |---|---|---|---|---|
  | 1 | — | S03 の手順 1〜5 | S03 と同じ | S03 |
  | 2 | V1-20 kt（GS > 85 kt） | エンジン 1 を停止させる | — | — |
  | 3 | 1 秒後（認識） | 推力レバーを閉じ A/T disconnect switch を押す、逆推力レバーを interlock まで上げて逆推力 | RTO autobrake が最大圧（減速が 2 秒以内に始まる：推定）。逆推力レバー 2 か 4 を idle detent まで上げた時点で SPEEDBRAKE lever が UP（arm していなくても）。>AUTOTHROT DISC（2 回目で消える）。AUTOBRAKES（advisory）が出ない | FCTM p.104 (3.16), p.106 (3.18); FCOM p.1515 (14.20.5), p.951 (9.20.11), p.656-657, p.1521 (14.30.1) |
  | 4 | 60 kt | 逆推力を絞り始め、taxi 速度までに reverse idle | — | FCTM p.238 |
  | 5 | 停止 | parking brake set | 滑走路上で停止。中心線から 8 m 以内（推定）。BRAKE TEMP（advisory）は出てよい | FCOM p.1521; FCTM p.107 (3.19) |

- 合否
  - 不合格：autobrake が効かない、speedbrake が上がらない、滑走路内で止まらない、推力レバーが再び進む。
  - 変形 S11-V1（HOLD 前、50 kt で中止）：レバーを閉じて手を離し、A/T を切らない → レバーが離陸推力に戻る（FCTM p.106）。GS が 85 kt 未満なので RTO autobrake は働かない（FCOM p.1515）→ 手動制動。
  - 変形 S11-V2（HOLD 後、75 kt で中止）：レバーを閉じて手を離す → idle のまま（FCTM p.106）。85 kt 未満なので RTO autobrake は働かない（FCOM p.1515）。

### 2.12 追加候補のシナリオ

- 片発の巡航と driftdown（R17：FCOM p.1267-1269; FCTM p.133）。
- windshear の回復（R34：FCOM p.674; FCTM p.272-273）。
- MCP の故障からの回復（R35：FCTM p.65-66）。
- standby 電源だけでの進入（R37：FCTM p.283-284）。
- LE/TE flap の drive 故障と secondary での展開（R29：FCTM p.289-290; FCOM p.957）。
- 速度計の異常（FCTM p.293-294。姿勢と推力の表で飛べるか）。
- 急降下（FCTM p.253-255。FLCH・speedbrake・IAS/MACH の切替）。
- PROC HOLD の自動 exit と待機速度（FCTM p.141-142）。
- circling（FCTM p.196; FCOM p.175）。
- 寒冷時の地上運用（nacelle 防氷、run-up：FCOM p.203-206 (SP.16.3-6)）。

## 未確認事項

- ELEC GEN OFF 1-4：FCOM の条件は「GCB 開、ELEC AC BUS 表示中は抑止」だけ（FCOM p.822）。全エンジン停止の地上でも出るのかは、この条件文からの解釈。ATA-24 の担当と合わせる。
- >ENG n SHUTDOWN：条件は「fire switch を引いたか fuel control が CUTOFF」で、地上での抑止の記述が無い（FCOM p.902）。preflight と停止後に出るのか不明。
- 複数 A/P の autoland で残りの A/P がどう入るか（FCTM の改訂記録は「747-400 では全 A/P を手で arm/engage しない」とだけ書く：FCTM p.20）。今回の範囲には仕組みの記述が無く、AFDS の資料（ATA22）で確かめる。S06 は「1,500 ft RA 未満で LAND 3」という見える結果だけで判定している。
- 複数 A/P の go-around 中の AFDS status（CMD か LAND 3 か）。FCOM の go-around 図は CMD を描いている（FCOM p.674）が、本文に記述なし。
- cruise climb 中（S04）の A/T モードと推力基準、FLCH で高度を捕捉した後の A/T モード（S07）、巡航で水平になったときの FMA（S03・S04）は資料に明記が無く、推定で書いた。
- 重量大での 10,000 ft 未満の上昇速度：FCTM の「flaps up 機動速度+20」は 309,000 kg 超で VREF30+120 になり、FCOM の VNAV（VREF+100）と食い違う。FCTM の意図が「UP bug（VREF30+80）+20」なら一致する。
- AUTOBRAKES advisory：条件「disarmed or inoperative」が、pedal による通常の解除後にも出るのか不明（FCOM p.1521）。
- 時間の値（APU の始動時間、エンジン始動の所要時間、IDG が入るまでの時間、gear の動作時間、IRS が NAV に入るまでの正確な時間）は資料に記載なし。試験の期限はすべて推定。
- 接地の許容（降下率、横ずれ）は資料に記載なし。推定の値で合意が要る。
- S08 の操縦モデルが読む F/D 指令（roll 側の `laminar/B747/autopilot/flight_director_roll_deg` は INTERFACES.tsv に無い）と、エンジン故障の注入方法（X-Plane の failure がこの機体の EEC モデルで ENG FAIL になるか）。
- body gear steering の状態を外から観測できる dataref があるか。
- RR の値は FCTM にある 2 つ（初期 EPR、逆推力 70 kt）以外は資料が無い。
- PACK OFF の memo（FCOM 2.50）は読んでいないので S02 の確認から外した。
- FCTM p.65 の「推奨モードの表」は PDF に無い（本文だけ）。
