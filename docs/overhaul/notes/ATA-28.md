# ATA 28 燃料系統（Fuel）実装ノート

GAP ID 接頭辞：`FUEL`。2026-10-23 調査。コード・acf は変更していない。

## 1. 概要

- 対象：燃料の貯蔵（タンク）、エンジン・APU への供給（ポンプ、クロスフィード、spar valve）、自動移送（予備タンク、CWT スカベンジ、水平安定板タンク＝HST）、ジェティソン、燃料量・温度の表示、FUEL synoptic、EICAS メッセージ、乗員手順。給油（P42 パネル）と整備用の地上試験は要点だけ。
- 使った資料（ページは PDF ページ）：
  - ATA26_28 p.327–566（28-00 p.327–348、28-21 給油 p.349–382、28-41 FQIS p.383–436、28-26 抜き取り p.437–446、28-22 エンジン供給 p.447–468、28-25 APU 供給 p.469–482、28-16 予備／主タンク連結 p.483–504、28-15 CWT スカベンジ p.505–514、28-31 ジェティソン p.515–548、まとめ p.549–566）。図は p.335（容量表）、341（操縦室の操作部）、423（synoptic）、463（xfeed 2/3 論理）、499（予備移送論理）、529（O/J ポンプ制御）、541（ジェティソン論理）、551・553・555（運用の流れ）、557（系統図）を描画して読んだ。
  - FCOM 12.10 p.1439–1452、12.20 p.1453–1472、12.30 p.1473–1480、SP.12 p.199、L.10 p.77–81、NP.21 p.97・105–106・119–120・133–136・152。補助に FCOM 6.20 p.795・799・801・819–820（電源）、11.32 p.1274・11.42 p.1378–1379・11.60 p.1432（FMC の燃料）、PI.11 p.268（巡航 FF）、FCTM p.295–297。
- 型式：FCOM の機番は 405＝Boeing 改造貨物機（PW）、109＝旅客機（PW）、570＝貨物機（GE）（FCOM p.5 (0.1.1)）。乗員に見える挙動は FCOM に従い、数値は kg 表示の 109 を主にし、570 の lb 値を括弧で添える。ATA26_28 は航空会社の整備訓練書（ヘッダ "k engineering & maintenance"、Config: ALL）で、HST を持ち、ジェティソン選択器が SEL/MLW 式（ATA26_28 p.341、p.520）など FCOM と違う点がある。違う箇所は両方書き、FCOM を採った。
- **HST を持つ型**：FCOM では 109（旅客機・PW）だけが HST を持ち、405 と 570 は持たない（FCOM p.1453 (12.20.1)、p.1456 (12.20.4)）。ATA26_28 は HST を Config: ALL として扱い、HST 込みの総容量を PW/RR と GE の両方について示す（ATA26_28 p.335 (28-00)）。どの顧客仕様に付くかはそれ以上資料に記載なし。シムは acf の両方にタンク 7（`_tank_name/7 = Horizontal stab`）があり、コードも常に HST を扱う。
- コード：`plugins/xtlua/scripts/B747.25.xt.fuel/B747.25.xt.fuel.lua`（3,720 行）、`plugins/xtlua/init/scripts/B747.25.fuel/B747.25.fuel.lua`（405 行）。関連：`B747.90.xt.lighting.lua`（頭上パネルの灯）、`B747.87.xt.warning.lua`（CAS 表）、`B747.40.xt.engines.lua`（エンジン燃料弁）、FMC の `B744.fms.pages*.lua`、acf 末尾の synoptic。

## 2. 構成

### 2.1 タンク

| タンク | acf index・比率 | acf 容量（173,069 kg×比率） | 資料の容量（1 タンク） | コード定数 |
|---|---|---|---|---|
| CWT | 0・0.300 | 51,921 kg | 52,162 kg / 114,999 lb（ATA26_28 p.335）、52,167 kg（FCOM p.1456） | 52,167 |
| 主 1・4 | 1, 4・0.078 | 13,499 kg | PW/RR 13,621 kg / 30,029 lb、GE 13,287 kg / 29,292 lb（ATA26_28 p.335）、570 は 2 タンクで 58,585 lb（FCOM p.1456） | 13,622（型式共通） |
| 主 2・3 | 2, 3・0.220 | 38,075 kg | 38,128 kg / 84,058 lb（ATA26_28 p.335） | 38,132 |
| 予備 2・3 | 5, 6・0.023 | 3,981 kg | 4,018 kg / 8,857 lb（ATA26_28 p.335） | 4,018 |
| HST | 7・0.058 | 10,038 kg | 10,029 kg / 22,110 lb（ATA26_28 p.335）、10,030 kg（FCOM p.1456、109） | 10,030 |
| （8） | 8・0 | — | — | — |

- 総容量：109 は 173,740 kg（FCOM p.1456）、ATA は PW/RR+HST 173,725 kg、GE+HST 173,057 kg（ATA26_28 p.335）。acf の 381,552 lb＝173,069 kg は GE+HST の値に近い。密度は FCOM の表で 0.8029 kg/l（109/405）、6.7 lb/gal（570）（FCOM p.1456）。
- サージタンク：各翼端（貯蔵しない、ATA26_28 p.332）。109 は右水平安定板の外側にもある（FCOM p.1453）。
- 予備タンクは主 1・4 の外側にあり、主 2・3 へ重力で移送する（ATA26_28 p.486）。

### 2.2 ポンプ

| ポンプ | 数・電源 | 役割と数値 |
|---|---|---|
| 主ポンプ（FWD/AFT） | 各主タンク 2、AC 3 相 115 V、制御 28 V DC（ATA26_28 p.450、p.452） | 1 台で離陸時 1 発、巡航時 2 発分（FCOM p.1454）。主 1・4 のポンプは主 2・3 内のドライウェル（ATA26_28 p.450） |
| O/J ポンプ（主 2・3） | 各 2、AC（ATA26_28 p.522） | 主ポンプより高圧。スタンドパイプ約 3,200 kg（570：約 7,000 lb）まで（FCOM p.1454）。ATA は地上抜き取り時に約 4,800 kg（10,500 lb）で吸入口が出るとする（ATA26_28 p.442）。1 台で離陸・巡航とも 2 発分（FCOM p.1454） |
| CWT O/J ポンプ L/R | 2、AC。故障電流検出器 1.5 A・10 ms で停止、スイッチの入れ直しで復帰（ATA26_28 p.531） | 主ポンプを上書きし CWT を先に使う。ただし CWT 1 台では O/J 2・3 も外側主ポンプも上書きできない（FCOM p.1454）。約 390 gal（約 1,185 kg）まで汲む（ATA26_28 p.335、p.443） |
| HST 移送/ジェティソンポンプ L/R（109） | 2、AC。O/J と同一品（ATA26_28 p.519） | 1 台で HST の全量を CWT へ移せる。低圧で FUEL PRES STB、選択 OFF しないと短い遅延の後に自動停止（FCOM p.1455） |
| CWT スカベンジ | 109・570：ジェットポンプ 4（主 2・3 へ 2 本ずつ）。405：電動ポンプ 1（主 2 へ）（FCOM p.1454、p.1467） | ジェット式は合計約 1,200 lb/h（ATA26_28 p.512）。電動式は約 1,700 pph（ATA26_28 p.508） |
| APU DC ポンプ | 主 2 内、APU battery bus 28 V DC（ATA26_28 p.474、FCOM p.820） | 約 1,300 pph・18 psi。AC が無いとき APU に供給（ATA26_28 p.474） |

- 圧力スイッチは 4–7 psi で動作し、PRESS 灯と EIU（synoptic）へ出る（ATA26_28 p.416）。

### 2.3 バルブ

| バルブ | 数・電源 | 制御 |
|---|---|---|
| クロスフィード弁 1–4 | 28 V DC。1・4 は battery bus（ATA26_28 p.458）、2 は main battery bus（図、ATA26_28 p.463）。全 xfeed は main battery bus（FCOM p.819） | 1・4 は手動のみ。2・3 は手動＋FSMC の自動閉（§4.3） |
| spar valve（エンジン燃料遮断弁）1–4 | main hot battery bus（ATA26_28 p.466、FCOM p.820）。作動 3–5 s、xfeed 弁と同型（ATA26_28 p.464） | fuel control switch の RUN/CUTOFF。消火スイッチで閉（ATA26_28 p.466） |
| 予備移送弁 2A/2B/3A/3B | DC bus 1（ATA26_28 p.500） | FSMC（§4.2）、地上は P461 スイッチ |
| 主 1・4 移送弁 | DC bus 1（ATA26_28 p.502） | FUEL XFER MAIN 1 & 4 スイッチ、または FJCC |
| ジェティソン/移送弁 | CWT 2、主 2・3 各 1、28 V DC（ATA26_28 p.524） | FJCC。閉で O/J 出力は xfeed マニフォールドへ、開でジェティソン・マニフォールドへも（ATA26_28 p.524） |
| ジェティソン・ノズル弁 L/R | 28 V DC（ATA26_28 p.546） | スイッチ直結（ATA26_28 p.546） |
| HST 分離弁（2 組） | 資料に記載なし | P42（給油）、FJCC（ジェティソン）（ATA26_28 p.378、p.540） |
| APU 燃料遮断弁 | main hot battery bus（FCOM p.820） | APU 始動回路（ATA26_28 p.480） |

- モーター駆動の弁は電源が無いときは手動オーバーライドレバーで開閉し、レバーが位置表示を兼ねる（ATA26_28 p.454、p.464）。ここから、電源を失った弁はその位置に留まると推定。
- 制御カード（M7852）：FSMC×2（運用管理）、FJCC×2（ジェティソン）、FSEIC×2（EICAS 接続）、VPLC×4（弁位置）、SPS カード×2（ATA26_28 p.342）。FQIS processor は DC bus 3 または 4（ATA26_28 p.404）、HST の量は REU が計算（ATA26_28 p.398）。

### 2.4 電源（資料にある分）

- utility bus：主ポンプ 2・3 FWD、O/J 2・3 FWD、CWT O/J ポンプ 1 台（FCOM p.801）。負荷制限時は FUEL PUMP 3 FWD → FUEL OVRD 2 FWD → FUEL OVRD 3 FWD → FUEL OVD CTR L → FUEL PUMP 2 FWD の順に出うる（FCOM p.795 (6.20.1)）。
- ground service bus：APU 始動用の燃料ポンプ（主 2 AFT、ATA26_28 p.452）、109 は抜き取り用の HST ポンプ（FCOM p.799）。ground handling bus：給油系統（FCOM p.799）。
- main DC bus：ジェティソン制御器、移送・ジェティソン弁の制御（FCOM p.819）。main battery bus：エンジン燃料弁、全 xfeed 弁（FCOM p.819）。main hot battery bus：APU 燃料遮断弁、spar valve（FCOM p.820）。APU battery bus：APU DC ポンプ（FCOM p.820）。
- 上記以外の主ポンプの AC バス割り当ては資料に記載なし。

## 3. 操作と表示

### 3.1 頭上の燃料パネル（P5）

- X FEED 1・4：ON（バー表示）で開。VALVE 灯（amber）＝弁位置とスイッチの不一致（FCOM p.1440 (12.10.2)）。VPLC は移動中も不一致回路を接地する（ATA26_28 p.346）。
- X FEED 2・3（ガード付き、ATA26_28 p.414）：ON で系統論理が開を指令したとき開。VALVE 灯＝論理の指令位置と不一致（FCOM p.1439 (12.10.1)）。
- MAIN FWD/AFT 1–4：ON/OFF。PRESS 灯＝出口圧低下。主ポンプの低圧は機体に電源がある限り表示（ATA26_28 p.414）。
- OVRD 2・3 FWD/AFT：ON＝論理が指令したとき作動。PRESS は ON かつ FSMC/FJCC が作動を指令しているときだけ（ATA26_28 p.414、FCOM p.1440）。
- CTR L/R：ON/OFF。PRESS は ON のときだけ（ATA26_28 p.414）。
- STAB L/R（109）：ON＝論理が指令したとき作動（FCOM p.1440）。
- 始動前でスイッチ OFF のとき：主ポンプ PRESS 点灯、OVRD・CTR・STAB の PRESS 消灯（FCOM p.1465 (12.20.13)）。
- FUEL XFER MAIN 1 & 4：ON で主 1・4 移送弁開、OFF で閉（論理の指令時は開）（FCOM p.1443）。VALVE 灯は 405 のみ（FCOM p.1444）。
- 整備パネル（P461）：RSV 2 & 3 XFER（CLOSE＝論理の指令時のみ開、OPEN＝開）、CWT SCAVENGE PUMP（405：ON で作動、OFF で論理の指令時に作動）（FCOM p.1442–1443）。

### 3.2 ジェティソン・パネル

- FUEL TO REMAIN 選択器：回して残量を選ぶ、EICAS に表示（FCOM p.1441 (12.10.3)）。
- NOZZLE L/R：ON でノズル弁開。系統が armed なら燃料のあるタンクの O/J ポンプ（109 は HST ポンプも）を作動（ポンプスイッチ ON が条件）。VALVE 灯＝選択位置と不一致（FCOM p.1441）。
- Fuel Jettison 選択器：OFF＝解除・FTR 表示を消す、A/B＝armed・FTR を表示（FCOM p.1441–1442）。プラカード「フラップ 1–5 の移動中はジェティソンしない」（FCOM p.1441 の図）。
- ATA26_28 の機体は SEL A／MLW A／OFF／MLW B／SEL B の 5 位置で、MLW では FMC の ZFW から FJCC が FTR を計算する（ATA26_28 p.520、p.538）。FCOM には無いので採らない。

### 3.3 EICAS 主表示

- TOTAL FUEL（kg×1000、570 は lb×1000）、燃料温度（主 1 タンクで計測、白、−37 °C 以下で amber）（FCOM p.1444–1445、p.1453）。
- ジェティソン中は温度の位置に TO REMAIN（magenta）、完了で白に変わり 5 秒点滅（FCOM p.1449 (12.10.11)）。
- EICAS 表示が 1 面だけのときはコンパクト燃料表示（各タンク量）を主 EICAS に出す（FCOM p.1445–1446、ATA26_28 p.424）。

### 3.4 FUEL synoptic（下段 EICAS）

- 流れの表示は弁位置とポンプ状態から作る推定で、実流量ではない（FCOM p.1447 (12.10.9)）。
- タンク量：白。主タンクは不均衡または 900 kg 未満（570：2,000 lb 未満）で amber（FCOM p.1448）。ATA の不均衡条件は M1/M4 差 3,000 lb、M2/M3 差 6,000 lb で両タンクとも amber（ATA26_28 p.421）。予備タンクの枠は上が開く（ATA26_28 p.421）。
- ポンプ：白＝スイッチ OFF、緑＝作動、amber＝低圧。O/J と STAB は cyan＝論理待機（armed）（FCOM p.1447–1449）。ジェティソン中は CWT・O/J・HST ポンプが magenta（ATA26_28 p.421）。
- xfeed 弁：白、燃料が流れていれば緑、指令と不一致で amber（FCOM p.1448）。
- 吸引供給中はエンジン記号と、そのタンクからの流れ線が amber（ATA26_28 p.422）。
- PRESELECT：給油中のみ（翼の給油パネル扉を閉じると消える）（FCOM p.1448）。
- ジェティソン：ノズル記号 magenta（系統作動中）、ジェティソン流れ magenta、JETTISON TIME（残り時間、分）（FCOM p.1450–1452）。移送の矢印（予備→主、主 1→主 2、HST→CWT、スカベンジ）（ATA26_28 p.423 図、FCOM p.1447 図）。

### 3.5 EICAS メッセージ（FCOM 12.30。数値は 109/405、括弧内は 570）

| メッセージ | レベル | 条件 | 出典 |
|---|---|---|---|
| FUEL JETT SYS | Caution・beeper | 総量 < FTR でノズル弁が 1 つ以上開、または FJCC 両系故障 | FCOM p.1474 |
| >FUEL JETT A, B | Advisory | ジェティソン制御系故障。FUEL JETT SYS で抑止 | FCOM p.1474 |
| FUEL PRESS ENG 1–4 | Caution・beeper | 吸引供給（xfeed 閉で主ポンプ 2 台とも故障） | FCOM p.1477 |
| FUEL PUMP 1–4 FWD/AFT | Advisory | ポンプ低圧。FUEL PRESS ENG で抑止 | FCOM p.1477 |
| FUEL OVRD 2, 3 FWD/AFT | Advisory | 論理が作動させたのに低圧。tank-to-engine 前にスイッチ OFF でも表示 | FCOM p.1474 |
| >FUEL LOW CTR L, R | Advisory | ポンプ ON で、始動前 CWT < 7,700 kg（17,000 lb）、上昇中 ≈3,200 kg（7,000 lb）、巡航中 ≈1,300 kg（3,000 lb）。ジェティソン中は抑止 | FCOM p.1474–1475 |
| >FUEL OVD CTR L, R | Advisory | ポンプ OFF で、地上 CWT ≥ 7,700 kg（17,000 lb）、巡航中 ≥ 1,800 kg（4,000 lb） | FCOM p.1474–1475 |
| FUEL PRESS CTR L, R | Caution・beeper | FUEL LOW CTR が 60 s 続く、またはスイッチ ON で低圧。ジェティソン中は CWT < 900 kg（2,000 lb）まで抑止（405 は抑止記述なし） | FCOM p.1476 |
| >FUEL PMP STB L, R（109） | Advisory | 地上でスイッチ ON、または巡航中 HST ≥ 500 kg でスイッチ OFF。FUEL STAB XFR で抑止 | FCOM p.1475 |
| FUEL PRES STB L, R（109） | Advisory | 論理が作動させたのに低圧 | FCOM p.1476 |
| FUEL STAB XFR（109） | Caution・beeper | HST 燃料が移送されない | FCOM p.1477 |
| FUEL QTY LOW | Caution・beeper | 主タンクのどれかが 900 kg（2,000 lb）以下 | FCOM p.1477 |
| FUEL RES XFR 2, 3 | Advisory | 予備移送弁が指令位置にない | FCOM p.1477 |
| FUEL IMBAL 1-4 | Advisory | 主 1・4 差 1,360 kg（3,000 lb）、差 < 450 kg（1,000 lb）で消える | FCOM p.1473 |
| FUEL IMBAL 2-3 | Advisory | 主 2・3 差 2,720 kg（6,000 lb）、< 450 kg（1,000 lb）で消える | FCOM p.1473 |
| FUEL IMBALANCE | Advisory | FUEL TANK/ENG 成立後、内側（2+3）と外側（1+4）の差 2,720 kg（6,000 lb）、< 450 kg（1,000 lb）で消える | FCOM p.1473 |
| >FUEL TANK/ENG | Advisory | 主2 ≤ 主1 または 主3 ≤ 主4、かつ xfeed 1 か 4 が開。地上では（給油後・電源投入時・CMC 試験後）主2 ≤ 主1+500 kg（1,000 lb）かつ主3 ≤ 主4+500 kg も可（FQIS BLK B）。ジェティソン中は抑止 | FCOM p.1477–1478 |
| FUEL TEMP LOW / FUEL TEMP SYS | Advisory | −37 °C 以下 / 温度計測不能 | FCOM p.1478 |
| FUEL X FEED 1–4 | Advisory | xfeed 弁が指令位置と不一致 | FCOM p.1479 |
| >FUEL XFER 1+4 | Advisory | 飛行中に内側 > 外側でスイッチ ON、または地上でスイッチ ON | FCOM p.1479 |
| >JETT NOZ ON / >JETT NOZ ON L, R | Advisory | ノズル弁両方開 / 片方開（前者で抑止） | FCOM p.1479 |
| >JETT NOZZLE L, R | Advisory | ノズル弁が指令位置と不一致 | FCOM p.1479 |
| >SCAV PUMP ON（405） | Advisory | 地上で電動スカベンジポンプ作動 | FCOM p.1479 |
| >X FEED CONFIG | Advisory | xfeed 1 か 4 が閉で主タンク量が等しくない、または xfeed 2 か 3 が閉でフラップが離陸位置にない | FCOM p.1479 |

- ATA の内部論理：予備移送で弁 1 つが 10 s 以内に開かないと status、同じタンクの 2 弁とも閉のままなら status＋advisory（FUEL RES XFR）（ATA26_28 p.498–499）。xfeed 2・3 は閉指令中に 10 s 以上開いていると takeoff disagree を EICAS へ（ATA26_28 p.462）。
- FMC：FUEL DISAGREE - PROG 2（TOTALIZER と CALCULATED の差 4,080 kg、570 は 9,000 lb）、INSUFFICIENT FUEL（FCOM p.1432）。

## 4. 内部ロジック

### 4.1 圧力の優先とエンジン供給

- 共通の燃料マニフォールドが主タンクと CWT をつなぎ、4 つの xfeed 弁がある。作動ポンプと xfeed 弁の組み合わせでどのタンクがどのエンジンへ行くかが決まる（FCOM p.1455 (12.20.3)）。O/J と CWT ポンプは xfeed マニフォールドへ吐出する（ATA26_28 p.448）。
- 実装用の圧力順位（FCOM p.1454 から）：CWT ポンプ 2 台 > O/J 2・3 > 主ポンプ。CWT ポンプ 1 台は O/J 2・3 にも、主ポンプ 2 台が動いている外側主タンクにも勝てない。xfeed 開のエンジンは、自タンクのポンプ圧とマニフォールド上の最高圧の源（CWT、O/J 2・3、または xfeed 弁が開いている他の主タンクのポンプ）を比べて高い方から吸う。
- xfeed 閉で自タンクのポンプ圧が無いと、ポンプを迂回する吸引供給ラインで自タンクから吸う。上昇中は溶けた空気がたまり、高高度で推力低下やフレームアウトのおそれ。巡航で空気が抜けると巡航推力で吸引供給できることがある（FCOM p.1455）。FUEL PRESS ENG を出し、synoptic はエンジン記号を amber にする（§3.4・3.5）。
- 実機はポンプ出口圧にばらつきがあり、xfeed を開けると最も高圧のタンク（量が少ない方の場合もある）から流れる。シミュレーターは通常等圧でモデル化する（FCTM p.295 (8.17)）。
- shared flow：CWT が約 2,300 kg（5,000 lb）未満で総 FF が 6,800 kg/h（15,000 lb/h）を超えると、CWT ポンプは外側主ポンプを完全には上書きできず、FUEL LOW CTR までに外側主タンクから約 900 kg（2,000 lb）ずつ減る（FCOM p.1466）。

### 4.2 通常の運用の流れ（燃料が全タンクにある場合）

1. 地上・始動前：全 xfeed スイッチ ON、ポンプ OFF（NP p.106）。APU 始動中・運転中は ground service bus があれば主 2 AFT（109・570 は主 3 AFT も）が自動で回る。主 3 AFT はタンク間移送を防ぎ、主 2 AFT 故障時に供給する（ATA26_28 p.452、p.478、FCOM p.1465）。
2. 始動前：主タンクのポンプスイッチを全部 ON（NP p.119 (NP.21.25)。直後の TANK/ENG の手順で OVRD 2・3 を OFF にするので、OVRD も含むと読める）。CWT が 7,700 kg（17,000 lb）以上なら CTR L/R ON（NP p.119、FCOM p.1465）。FUEL TANK/ENG が出ていれば OVRD 2・3 OFF、xfeed 1・4 OFF（NP p.120）。
3. 離陸（地上でフラップ 10–20）：FSMC が xfeed 2・3 を閉じる。CWT ポンプ ON なら CWT→エンジン 1・4、主 2・3→エンジン 2・3。O/J 2・3 は CWT ポンプ 2 台の圧があると作動しない（FCOM p.1465）。CWT < 7,700 kg（CTR OFF）なら O/J 2→エンジン 1、O/J 3→エンジン 4（FCOM p.1466）。
4. 離陸後：フラップが 10–20 の範囲を出ると xfeed 2・3 が開く。CTR ON なら CWT が全エンジン、OFF なら O/J 2→エンジン 1・2、O/J 3→エンジン 3・4（FCOM p.1466）。
5. CTR の切り替え（乗員）：上昇中（ピッチ 5° 以上）に FUEL LOW CTR（≈3,200 kg）で CTR OFF、巡航（ピッチ 5° 未満）で FUEL OVD CTR（≥1,800 kg）なら ON、巡航中の FUEL LOW CTR（≈1,300 kg）で OFF（NP p.133–135）。
6. FSMC は、CTR スイッチ ON でどちらかの CWT ポンプが低圧、または CTR スイッチが両方 OFF のとき O/J 2・3 を作動させる（FCOM p.1467）。
7. HST 移送（109）：飛行中、フラップが 10–20 の範囲外、CWT ≤ 36,470 kg で HST→CWT（FCOM p.1466）。ATA26_28 は FQIS が FSMC に「CWT < 10,000 gal」を出し、HST 移送点を 10,000 gal（≈30,391 kg）とする（ATA26_28 p.335、p.400）。FCOM を採る。乗員は FUEL PMP STB（HST ≥ 500 kg）で STAB ON、FUEL PRES STB（HST ≤ 900 kg）で OFF、約 5 分後も残っていれば再び ON にしてよい（NP p.135）。
8. スカベンジ：109・570 のジェットポンプは主 2 か 3 が約 27,200 kg（60,000 lb）まで減ると始まる（FCOM p.1454）。ATA の条件は、ブースト／O/J ポンプで燃料移送ラインが加圧、CWT 底のフロート弁が開（CWT 約 4,000 lb 未満）、内側主タンク上部のフロート弁が開（主 2・3 約 60,000 lb 未満）で、左右独立（ATA26_28 p.512）。405 の電動ポンプは CWT O/J ポンプの低圧時、または主 2・3 ≈18,200 kg で起動し、約 2 時間か低圧で停止（FCOM p.1454、ATA26_28 p.553）。
9. 予備移送：主 2 か 3 が約 18,200 kg（40,200 lb）に下がると FSMC が予備 2・3 の移送弁を開き、重力で各主タンクへ（FCOM p.1464、p.1467）。ATA：主 2・主 3 の SPS と FQIS の 4 入力のうち 2 つが「6,000 gal 未満」かつ空中（または BITE）で、4 弁すべてに開指令（ATA26_28 p.498–499 図）。接地で閉（ATA26_28 p.555）。
10. tank-to-engine：FUEL TANK/ENG（主2 ≤ 主1 または 主3 ≤ 主4）で乗員が OVRD 2・3 OFF、xfeed 1・4 OFF。以後は各主タンクが自エンジンへ停止まで供給（NP p.135–136、FCOM p.1467）。
11. 停止：fuel control CUTOFF（spar valve とエンジン燃料弁が閉）、駐機後にポンプ OFF（NP p.152）。

- CWT が空なら、FSMC は O/J 2・3 を作動させ、xfeed 2・3 は同じく離陸時に閉・フラップ格納で開。予備移送と tank-to-engine は同じ（FCOM p.1468）。

### 4.3 xfeed 2・3 の FSMC 論理（ATA26_28 p.461–463）

- 自動制御はスイッチ ON（in）が前提。FSMC は auto control relay を励磁して閉、非励磁で開に戻す。スイッチ OFF は直接閉（ATA26_28 p.461）。
- 論理（図 p.463 のゲート）：
  - 地上でフラップが離陸範囲外（0–7.5、22.5–30 units）：閉指令は禁止、地上入力が arming。
  - 地上でフラップが離陸範囲に 40 s を超えて入る：閉指令。閉指令は自分で arming を保持する。
  - 空中でフラップが離陸範囲：閉指令を保持。空中でフラップ格納（範囲外）：閉指令が消え、保持も消える → 開。
  - 空中で着陸フラップ：閉指令なし。地上で着陸フラップ：閉指令なし。地上で格納途中に離陸範囲を通る：40 s 以内なら閉指令なし（ATA26_28 p.461–462）。
- 閉指令中に弁が 10 s 以上開いていれば takeoff disagree を EICAS へ（ATA26_28 p.462）。
- 疑似コード：`inhibit = (not flapsInTO) or (フラップが離陸範囲に入ってから 40 s 未満)`；`closeCmd = (onGround or closeCmd) and not inhibit`（前回値で保持）；`target(xfeed2,3) = switchOn and not closeCmd`。フラップ入力がレバーか実位置かは資料に記載なし。

### 4.4 O/J ポンプの制御（ATA26_28 p.528–536、p.542）

- CWT O/J：手動のみ（スイッチ→故障電流検出器→制御リレー）。スイッチ ON はバイパス回路を disarm する（ATA26_28 p.528）。
- 主 O/J：スイッチで arm、FSMC か FJCC が指令すると作動。CTR スイッチが両方 OFF ならバイパス回路が armed になり、FSMC によらずスイッチ ON で作動。FSMC は CWT ポンプが作動・加圧中は主 O/J を作動させない（ATA26_28 p.528、p.532、p.535）。
- ジェティソン選択器を A/B にすると management/jettison select relay が制御を FSMC から FJCC へ移す（ATA26_28 p.542）。

### 4.5 ジェティソン

- 起動条件：選択器 A か B、ノズル弁スイッチのどちらかが ON、総量 > FTR（ATA26_28 p.540 図 p.541）。FCOM：選択器 A/B で FTR 表示とマニフォールド・時間を synoptic に出し、ノズルスイッチ ON で燃料のあるタンクの O/J と（109）HST ポンプを作動、必要なジェティソン弁を開く（スイッチ ON が条件）（FCOM p.1468–1469）。ノズル弁自体はスイッチ直結（ATA26_28 p.546）。
- FJCC の動作（ATA26_28 p.538、p.540）：CWT 給油弁を閉、CWT・主 2・主 3 のジェティソン/移送弁を開。HST > 500 lb なら HST 分離弁を開き HST ポンプ ON（HST 燃料はマニフォールドから機外へ、CWT へは入らない、ATA26_28 p.519）。主 2・3 の O/J は個別制御で、片方が 4,000 lb 以上多ければ多い方だけ作動、差が 4,000 lb 未満で両方（ATA26_28 p.540）。FCOM は低い方のポンプを止めて均衡させるとだけ書く（FCOM p.1469）。
- 主 1・4 移送：主 2 か 3 が 9,072 kg（20,000 lb）まで減ると両方の移送弁を開（FCOM p.1469）。ATA は SPS（3,000 gal）と FQIS の 4 入力のうち 2 つが 20,000 lb 以下（ATA26_28 p.540）。外側主タンクは約 3,200 kg（7,000 lb）まで重力移送（FCOM p.1464）。
- 予備移送：18,140 kg（40,000 lb）で FSMC が開（FCOM p.1469）。
- 開始時、O/J 2・3 がエンジンに供給していると、ノズル弁が開いた圧力低下で FUEL OVRD が出ることがある。投棄は量の減少で確認（FCOM p.1469）。
- 終了：総量が FTR に達すると停止。FTR が magenta→白・5 秒点滅、作動中の O/J（と HST）ポンプを停止、関係する FUEL OVRD は選択器 OFF まで表示（FCOM p.1469–1470）。
- 時間：最初はあらかじめ決めた流量で推定し、開始 90 s 後から実際の量の変化率で更新（FCOM p.1468）。投棄流量そのものは資料に記載なし（synoptic の図の例「45MIN」だけ、FCOM p.1450）。
- 下限：スタンドパイプまで投棄したときの残量は約 12,700 kg（28,000 lb、ATA26_28 p.335「MAXIMUM JETTISON RESULT」）。最大性能が要るときはスタンドパイプまで投棄、4,000 ft AGL 以上で行う（FCTM p.296–297）。
- FMC：ジェティソン中は CALCULATED を FQIS 値に合わせ、終了後は FF で減算に戻る（FCOM p.1274）。

### 4.6 FQIS・燃料量

- タンクごとの容量式センサー、密度計・補償器で重量を計算（予備タンクは密度計なし）（ATA26_28 p.388、p.392）。HST は REU（ATA26_28 p.398）。
- FSMC への離散出力：主 2・3 < 6,000 gal、CWT < 10,000 gal、HST > 500 lb（ATA26_28 p.400）。SPS は主 2・3 内の約 3,000・6,000 gal（ATA26_28 p.406）。
- FMC は始動前 FQIS 値に合わせ、FF が出たら FF で減算する CALCULATED を使う。手入力は MANUAL、FF 無効なら SENSED/TOTALIZER（FCOM p.1274）。FUEL USED は FF から計算し、エンジン始動か地上の長時間電源断で消える（FCOM p.1274）。

### 4.7 燃料温度

- 主 1 タンクの温度球 1 個、FSEIC へ入力（ATA26_28 p.410）。−37 °C 以下で amber と FUEL TEMP LOW（FCOM p.1445、p.1478）。
- 制限：最高 54 °C（Jet A、JP-5 等）、離陸前は −43 °C と凝固点 +3 °C の高い方以上、飛行中は凝固点 +3 °C 以上（FCOM p.81 (L.10.5)）。温度変化のモデルは資料に記載なし。

### 4.8 APU 供給

- APU 始動の初めから R7200 が APU 燃料遮断弁を開き DC ポンプを回す。ground service bus が付くと主 2 AFT が自動で回り、約 7 psi で DC ポンプが止まる（ATA26_28 p.480）。燃料は通常主 2 から（FCOM p.1464–1465）。

### 4.9 給油（要点）

- 通常 55 psi、最大 65 psi（ATA26_28 p.350、p.368）。手動・top-off・preselect（総量または CWT）。preselect の各タンクへの配分は FQIS のプログラム（ATA26_28 p.370、p.376）で、配分表は資料に記載なし。サージタンクのフロートで給油停止（ATA26_28 p.380）。

### 4.10 定数一覧（実装用）

| 項目 | 値（109/405） | 570 | 出典 |
|---|---|---|---|
| O/J 2・3 スタンドパイプ | ≈3,200 kg | ≈7,000 lb | FCOM p.1454 |
| CWT O/J の下限 | ≈390 gal（≈1,185 kg） | — | ATA26_28 p.335、p.443 |
| 外側主の移送下限 | ≈3,200 kg | ≈7,000 lb | FCOM p.1464 |
| 予備移送開始 | 主 2/3 ≈18,200 kg | 40,200 lb | FCOM p.1464 |
| ジェティソン時の主 1・4 移送 | 主 2/3 9,072 kg | 20,000 lb | FCOM p.1469 |
| ジェティソンの主 2・3 均衡 | 4,000 lb | — | ATA26_28 p.540 |
| HST 移送許可 | CWT ≤ 36,470 kg | （HST なし） | FCOM p.1466 |
| ジェット式スカベンジ開始 | 主 2/3 ≈27,200 kg | 60,000 lb | FCOM p.1454 |
| xfeed 2・3 | 離陸フラップ 40 s、不一致 10 s | 同 | ATA26_28 p.461–462 |
| 予備移送弁の不一致 | 10 s | 同 | ATA26_28 p.498 |
| 弁の作動時間 | 3–5 s（spar、xfeed は同型） | 同 | ATA26_28 p.464 |
| 圧力スイッチ | 4–7 psi | 同 | ATA26_28 p.416 |
| 上昇/巡航の区別 | ピッチ ≥5° / <5° | 同 | NP p.133–134 |
| ジェティソン時間の更新 | 開始 90 s 後 | 同 | FCOM p.1468 |

## 5. 他系統とのつながり

- 電源（ATA 24）：§2.4。ポンプは AC、制御とバルブは DC。モーター駆動弁は電源喪失で位置を保つと推定（§2.3）。ELEC の作り直しでバス名が決まったら、ポンプ・バルブごとの給電元を表にして渡す。
- エンジン（ATA 73）：spar valve（燃料系）とエンジン燃料弁（エンジン側）。どちらも fuel control switch と消火スイッチで閉（ATA26_28 p.466）。シムでは `sim/flightmodel2/engines/has_fuel_flow_before_mixture` を燃料系が書き、エンジンモジュールが `mixture_ratio` を書く（`B747.40.xt.engines.lua:2051-2135`）。吸引供給時の推力低下はエンジン側と調整。
- 火災（ATA 26）：消火スイッチで spar valve 閉（ATA26_28 p.466）。
- 操縦系統：xfeed 2・3、HST 移送はフラップ位置（`laminar/B747/cablecontrols/flap_ratio`、レバー比、10＝0.5、20＝0.667）。
- 空地：予備移送（空中のみ）、xfeed 2・3、FUEL OVD/LOW CTR、FUEL PMP STB、FUEL XFER 1+4。
- APU（ATA 49）：主 2 AFT・主 3 AFT・DC ポンプ・APU 燃料弁。`APU FUEL` advisory は今は燃料モジュールが出す（`B747.25.xt.fuel.lua:2847-2856`）。
- 警報（ATA 31）：CAS の index は `B747.87.xt.warning.lua` の表（caution 31–37・67–70、advisory 148–179・235–239・263・299・302–303）。頭上の PRESS/VALVE 灯は照明モジュールが燃料の dataref から作る（`B747.90.xt.lighting.lua:1132-1272`）。
- FMC（ATA 34-61）：`laminar/B747/fuel/totaliser`（FUEL USED）、`m_fuel_total`（PERF INIT・PROGRESS）、FF（予測）、`refuel`・`add_fuel`・`preselect`・`fuel_preselect_temp`（地上サービスの給油）、タンク量（W&B・重心）。
- 重心：HST は acf で z=201 ft の後方（`_tank_xyz/7`）。HST の量はトリムと FMC の CG に効く。

## 6. 実装上の注意

- **燃料消費は X-Plane の FF を使っている**：`sim/cockpit2/engine/indicators/fuel_flow_kg_sec`（`B747.25.xt.fuel.lua:376`）をエンジンごとに供給タンクで割って減算（2274-2320）。FF を自前で計算・上書きするモジュールは無い（`ENGN_FF_` の書き込みなし）。FF は acf の `_jet_SFC_*` で決まるので、ACF_DIFF §3.2 の SFC 差（カスタム TO 0.55 / CLB 0.25 / LoCrz 0.25 / HiCrz 0.38、純正 0.323 / 0.323 / 0.313 / 0.571）は消費量、FUEL USED、EICAS の FF、FMC の予測（`B744.fms.pages.progress.lua:64`、`vnav.lua:230`）にそのまま効く。推定：FCOM の LRC 表で PW4056・300 t・FL290 が FF/ENG 2,597 kg/h（FCOM p.268 (PI.11.2)）。揚抗比を 17 前後とすると 1 発の推力は約 4,400 kgf、TSFC は約 0.59 で、純正の HiCrz 0.571 に近く、カスタムの 0.38 では巡航消費が 3 割以上少なくなる。acf を直す前に、両 acf で実測 FF を PI.11（PW）・PI.21（CF6）の表と比べること。
- `override_fuel_system`：`aircraft_load` で 1、`aircraft_unload` で 0（3620-3630、init 側 384-394）。DataRefs.txt の説明は「移送とダンプを止め、エンジンに燃料が行くかをプラグインが決める」。消費の減算もプラグインがしている前提のコードなので、二重減算が無いことはシムで確かめる（§9）。
- タンク 7 の役割（ACF_DIFF §3.6）：acf の `_tank_name/7` は "Horizontal stab"。`_tank_role` は Plane Maker の説明文字列の並び（Normal-Feeder-Aux-Trim）から 0=Normal、1=Feeder、2=Aux、3=Trim と推定。純正は Feeder、カスタムは Normal。override 中は X-Plane の移送が止まるので影響は無いと推定し、コードも役割を読まない。意味として正しいのは Trim だが、変える必要は薄い。
- タンク容量は acf（比率×381,552 lb）と揃える。今は定数がずれている（§2.1）。GE は主 1・4 が 13,287 kg。HST は機体仕様（109 型の旅客機）のときだけ有効にし、`laminar/B747/freighter`（simconfig の aircraft_type）と連動させる。
- **パネルの制約（acf は純正を変えない）**：
  - synoptic は `SHOW_EQUAL/LESS/GREATER` で燃料 dataref を読む（`engine1–4_status`、`gen/xfeed_vlv1–4_status`、`gen_XFmfld_status`、`oj_pump2/3_status`、`jett/*`、`jett_vlv_status`、`res2/res3/stab_xfr_status`、`ctr_scvg_L/R_status`、`*_pump_*_on`、`main1/4_tank/main_xfr_vlv_pos`、`center_tank/jett_vlv_L/R_pos`、`jett_nozzle_vlv_L/R_pos`、`refuel`、`fuel_display_units_eicas`、`fuel_jettison/sel_dial_pos`、`temperature`）。**これらは INTERFACES.tsv に載っていない**（DATAREF 行だけを拾っている）。作り直しでも名前と値の意味（0/1/2 などの状態コード）を残す。
  - ポンプの amber は acf 側で `sim/flightmodel/weight/m_fuel[i] < 10`（O/J も < 10）、主タンクの amber は < 900 kg だけで、不均衡の amber は無い（`747-400_custom.acf:122861`、`123098-123160`、`123306`）。故障や無電源の低圧を synoptic に出すには acf の変更（カスタムのみ、要承認）が要る。
  - 状態コードとの組み合わせ（`SHOW_GREATER 2 ... status` と `SHOW_GREATER 1 ... status` の対）から、SHOW_GREATER/LESS は「以上／以下」と推定。そうなら FTR は A・B で、温度は OFF で表示される（`747-400_custom.acf:114845`、`114883`）。
  - FTR（`fuel_to_remain/rheostat`、1000 kg 単位、ノブの範囲 9–173、`747-400_cockpit.obj:22182`）は LBS 表示でも換算されない。
- 照明モジュールが頭上灯を独自に判定しているので、燃料側で「ポンプ出口圧低」「弁の不一致」を dataref として出し、照明はそれを読むように分担を変える（新しい dataref の追加は可、既存名は残す）。
- 時間：0.1 s タイマーで `sim/time/total_running_time_sec` の差を使う（2124-2130）。一時停止・時間加速での挙動を確かめる。弁は 3–5 s で動かし、不一致の判定は時間遅れ付きにする（ATA26_28 p.346、p.464）。
- 簡略化してよいもの：P42 給油パネルと給油配分（FMC の地上サービスで代用）、抜き取り、CMCS 地上試験、VTO、密度計、FSMC/FJCC の二重系、ATA26_28 の機体の MLW ジェティソン、カード単位の BITE。
- 簡略化してはいけないもの：吸引供給（ポンプ停止でフレームアウトさせない）、クロスフィード・マニフォールド（SP.12 の均衡手順が成り立つこと）、圧力順位による CWT→O/J→主の順序、xfeed 2・3 の論理、予備移送、tank-to-engine とその EICAS、ジェティソンの FTR 終了・均衡・主 1・4 移送、HST 移送（109 型）、FCOM の EICAS 閾値。
- `SIM.auto_fuel_mgmt == "YES"` のときの `tank_helper`（2687-2771、3697）は乗員操作を自動化する補助で実機に無い。残すなら既定 NO のまま補助機能として扱う。

## 7. 現状実装との比較（GAP 候補）

コードの行番号は特記なければ `plugins/xtlua/scripts/B747.25.xt.fuel/B747.25.xt.fuel.lua`。

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

件数：高 5、中 8、低 12（計 25）。

## 8. 作り直しか部分修正か

**ロジック側（`B747.25.xt.fuel.lua`）は作り直しを勧める。** init 側の dataref・コマンド名はそのまま使い、足りないもの（ポンプ低圧、弁不一致など）は追加する。

- 中心のエンジン供給モデルが構造的に足りない（マニフォールドと吸引供給が無い、FUEL-01・02）。直すにはエンジンごとの判定を「圧力順位でマニフォールドを解く」形に書き換えるしかなく、部分修正では済まない。
- タンク・ポンプごとに同じ処理を 4 回書いた 3,720 行で、コピー誤りが複数ある（FUEL-06・10）。表駆動（タンク表、ポンプ表、弁表）にすれば 1,000–1,500 行程度に収まり、誤りも入りにくい（推定）。
- EICAS 部分はほぼ全部を FCOM の条件で書き直す必要がある（FUEL-03・04・06・16・25）。
- 電源の扱いは ELEC の作り直しと同時に差し替える必要がある（FUEL-09）。
- 外部とのつながりは少ない（照明、警報、FMC、パネル、サウンド、エンジンモジュール）。名前を守れば中だけを入れ替えられる。
- 守るもの：INTERFACES.tsv の `laminar/B747/fuel/*` と `button_switch/fuel_*` コマンド、§6 のパネル SHOW_* の dataref と状態コード、`fuel_control/toggle_sw_pos`（エンジン・空調・操縦系統・音・3D）、`totaliser`・`refuel`・`add_fuel`・`preselect`・`fuel_preselect_temp`（FMC）、`*_pump_*_on`（音、「モーター通電」の意味）、CAS の index（警報の作り直しと調整）。
- 規模：燃料モジュール単体は M（数日〜1 週間）。照明・警報・FMC・電源への波及を含めると L。急ぐなら FUEL-03・04・06・10（S）を先に部分修正し、本体は作り直しで置き換える。

構成案：①タンク・ポンプ・弁の状態（電源、故障、吸入口の露出、弁の移動時間）→ ②FSMC（xfeed 2・3、O/J 2・3、予備移送、スカベンジ、HST 移送）と FJCC（ジェティソン）→ ③マニフォールド解法（各エンジンの供給源と吸引供給）→ ④タンク量の積分（FF、移送、投棄、APU）→ ⑤FQIS 出力・EICAS・synoptic 状態コード・頭上灯の出力。

## 9. 未確認事項

1. `override_fuel_system` 中に X-Plane がタンクから燃料を減らさないか（二重減算が無いか）。1 分間の `m_fuel_total` の減少と FF の積分を比べる。
2. 両 acf での実際の FF と FCOM PI（PI.11 p.268 ほか、CF6 は PI.21）の FF/ENG の比較。EEC の推力表がどちらの acf を前提にしているか（エンジン担当と共有）。
3. 純正 acf のタンク 7（Feeder）で X-Plane が独自に移送しないか。
4. XP12 の `sim/cockpit2/fuel/fuel_temp_at_fuel_tank[9]`（冷却モデル）が override 中も更新されるか。使えれば燃料温度に流用できる。
5. パネルの SHOW_GREATER/LESS が「以上／以下」か（FTR が A で出るか、温度が OFF で出るか）。スカラー dataref に index を付けた条件（`ctr_scvg_L_status[0]`、`stab_xfr_status[7]`）と `blaminar/...` の誤記がどう扱われるか。
6. 現在の ELEC で sim bus 0 がいつ落ちるか（`cross_tie` は常に 1）。落ちたときに全発停止が起きるか。
7. 一時停止・時間加速・リプレイでの消費の積分（`total_running_time_sec` 差）。
8. 資料に記載なし：ジェティソン流量、重力移送（予備→主、主 1・4→2・3）の流量、HST 移送流量、HST ポンプ自動停止の「短い遅延」の秒数、主ポンプの AC バス割り当て、FSMC のフラップ入力がレバーか実位置か、給油の配分表、地上でスイッチ OFF のとき FUEL PUMP メッセージが出るか。
9. 資料間の食い違い（FCOM を採用）：HST 移送開始 CWT 36,470 kg（FCOM）と 10,000 gal（ATA26_28）、O/J 2・3 の下限 3,200 kg（FCOM）と 4,800 kg（ATA の地上抜き取り）、FUEL PMP STB の 500 kg（FCOM）と FJCC の HST 500 lb（ATA）、予備移送の ATA 本文中の 3,000 gal の記述（p.496、図と他の頁は 6,000 gal）。
10. CWT のパイロットフロート弁（13,000 gal、ATA26_28 p.335・368）が HST→CWT 移送で CWT の上限を決めるか（推定、資料は試験の記述だけ）。CWT の crossflow compensator（ATA26_28 p.557 の図の名称のみ）の働き。
