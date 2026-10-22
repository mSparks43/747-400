# EICAS メッセージ一覧（FCOM 全章）と現状実装の対応

2026-10-23 調査。コード・acf・snd は変更していない。警報系統の本文は [ATA-31-warning.md](ATA-31-warning.md)。

## 0. この表の読み方

- 出典：FCOM（D6-30151-400 Rev.23）の各章 EICAS Messages 節（1.60 p.545–548、2.50 p.619–622、3.30 p.635–636、4.30 p.677–678、5.40 p.775–776、6.30 p.821–824、7.40 p.899–902、8.30 p.921–924、9.30 p.957–958、10.50 p.1197–1200、11.60 p.1429–1436、12.30 p.1473–1480、13.30 p.1495–1496、14.30 p.1521–1522、15.30 p.1603–1606）。表は `pdftotext -table` で読み、列ずれは p.545・p.619 を画像で確かめた。
- 並びは FCOM の章順。番号違いの同型メッセージ（`FIRE ENG 1..4` など）は 1 行にまとめた。
- 型式（FCOM の機番）：109 = 旅客機・PW4056、405 = Boeing 改造貨物機・PW、570 = 貨物機・CF6-80C2B1F（FCOM p.5 (0.1.1)）。表記の無い行は全機共通。`(109)` などは FCOM がその機番だけに載せている行。
- **エンジン型式で文言・条件が違う行**には【PW】（109/405 の PW 機の記述）・【GE】（570 の CF6 機の記述）を付けた。RR（RB211）の資料は無いので、RR は PW と同じ扱いになると推定するしかない（推定：シムの EEC が RR を PW と同じ EPR 系で扱っているため）。
- Level：warning（赤）/ caution（琥珀）/ advisory（琥珀・1 字下げ）/ memo（白）/ status（補助 EICAS の STATUS ページ）。色と字下げは FCOM p.1527–1528 (15.10.1–2)、p.1548 (15.20.2)。
- Aural：FCOM の表の Aural 欄。beeper は ATA31 の owl（level B aural）と同じもの（ATA31 p.160 (31-51)、p.163）。
- 実装：
  - **yes** = `B747.87.xt.warning.lua` の表に正しい文言・レベルで存在し、どこかのモジュールが状態配列に 1 を書く。条件の正しさは各系統のノートで扱う（ここでは見ない）。
  - **partly** = 表にあるが文言かレベルが違う、番号の一部しか立たない、または条件式に警報系統側で問題がある（ATA-31-warning.md の GAP 番号を付記）。
  - **no** = 表に無い、または表にあるが誰も立てない。
- 実装欄の書式：`c31 L139 ← fuel:2830`。
  - `w`/`c`/`a`/`m` + 数字 = `laminar/B747/CAS/{warning,caution,advisory,memo}_status` の添字（= 表の `DRindex`）。
  - `L139` = `plugins/xtlua/scripts/B747.87.xt.warning/B747.87.xt.warning.lua` の表の行番号。
  - `← fuel:2830` = その添字に書き込んでいる行（複数あるときは代表の 1 つ）。略称：air = `B747.55.xt.air.lua`、antiice = `B747.50.xt.antiice.lua`、autopilot = `B747.70.xt.autopilot.lua`、electrical = `B747.03.xt.electrical.lua`、engines = `B747.40.xt.engines.lua`、fire = `B747.35.xt.fire.lua`、fltCtrls = `B747.45.xt.fltCtrls.lua`（`fltCtrls(init)` は `init/scripts/B747.45.fltCtrls/B747.45.fltCtrls.lua`）、fltInst02 = `B747.60.xt.fltInst02.lua`、fltMgmt = `B747.30.xt.fltMgmt.lua`、fms = `B747.68.xt.fms.lua`、irs = `B747.68.xt.fms/irs/irs_system.lua`、fuel = `B747.25.xt.fuel.lua`、gear = `B747.10.xt.gear.lua`、hydraulics = `B747.20.xt.hydraulics.lua`、lighting = `B747.90.xt.lighting.lua`、safety = `B747.85.xt.safety.lua`。
- 所掌系統：条件ロジックを持つ系統（ATA 番号）。条件の分析はその系統のノートに任せる。

## 1. FCOM の EICAS メッセージ全表

| メッセージ | Level | 条件の要約 | Aural | FCOM | 実装 | 所掌系統 |
|---|---|---|---|---|---|---|
| >CREW OXY LOW | advisory | 乗員酸素圧低下 | — | p.545 (1.60.1) | no：a53 L239 | 酸素 (35) |
| DOOR AFT CARGO | caution | 後部貨物ドアが閉・ラッチ・ロックされていない | beeper | p.545 (1.60.1) | no：c11 L119 | ドア (52) |
| DOOR BULK CARGO | advisory | バルク貨物ドアが閉・ラッチされていない | — | p.545 (1.60.1) | no：a63 L249 | ドア (52) |
| DOOR ELEC CTR | advisory | 電子機器室ドア（中央）が閉・ラッチされていない | — | p.545 (1.60.1) | no：a64 L250 | ドア (52) |
| DOOR ELEC MAIN | advisory | 電子機器室ドア（主）が閉・ラッチされていない | — | p.545 (1.60.1) | no：a65 L251 | ドア (52) |
| DOOR ENTRY L1..L5, R1..R5（405/570 は L1・L5 のみ） | advisory | 主デッキ客室ドアが閉・ラッチされていない | — | p.545 (1.60.1) | partly：a66–75 L252–261。L1 だけ立つ（a66 ← safety:220） | ドア (52) |
| DOOR F/D OVHD (405, 570) | advisory | 操縦室天井ドアが閉・ラッチされていない | — | p.545 (1.60.1) | no：表に無い | ドア (52) |
| DOOR FWD CARGO | caution | 前部貨物ドアが閉・ラッチ・ロックされていない | beeper | p.545 (1.60.1) | no：c12 L120 | ドア (52) |
| DOOR L, R UPPER DK (109, 405) | advisory | 上階ドアが閉・ラッチされていない | — | p.546 (1.60.2) | partly：a76 L262 ← safety:228（L のみ）、a77 L263 は立たない | ドア (52) |
| DOOR NOSE CARGO (570) | caution | ノーズ貨物ドアが閉・ラッチ・ロックされていない | beeper | p.546 (1.60.2) | no：表に無い | ドア (52) |
| DOOR R UPPER DK (570) | advisory | 上階ドア（右）が閉・ラッチされていない | — | p.546 (1.60.2) | no：a77 L263 | ドア (52) |
| DOOR SIDE CARGO (405, 570) | caution | サイド貨物ドアが閉・ラッチ・ロックされていない | beeper | p.546 (1.60.2) | no：c13 L121 | ドア (52) |
| DOOR U/D FLT LK (109, 405) | caution | 離陸後に上階ドアの自動ロックが作動しない | beeper | p.546 (1.60.2) | no：c14 L122。a78 L264 に advisory の重複定義（誤り） | ドア (52) |
| DOORS ELEC | advisory | 電子機器室ドア 2 枚とも閉・ラッチされていない | — | p.546 (1.60.2) | no：a79 L265 | ドア (52) |
| DOORS ENTRY L, R (109) | advisory | 同じ側の客室ドア 2 枚以上が閉・ラッチされていない | — | p.546 (1.60.2) | no：a80–81 L266–267 | ドア (52) |
| DOORS UPR DECK (109, 405) | advisory | 上階ドア 2 枚とも閉・ラッチされていない | — | p.546 (1.60.2) | no：a82 L268 | ドア (52) |
| >ELT ON (405, 570) | advisory | ELT 作動 | — | p.546 (1.60.2) | no：a107 L293 | 非常装備 (25) |
| >EMER LIGHTS | advisory | 非常灯スイッチが ARMED でない、または ARMED で客室側スイッチにより点灯 | — | p.547 (1.60.3) | no：a108 L294 | 照明 (33) |
| PASS OXYGEN ON (109) | advisory | 旅客酸素系統が作動 | — | p.547 (1.60.3) | no：a256 L442 | 酸素 (35) |
| SUPRNMRY OXY ON (405, 570) | advisory | 同乗者用酸素が作動 | — | p.547 (1.60.3) | no：表に無い | 酸素 (35) |
| NO SMOKING ON (109) | memo | No Smoking スイッチ ON（Seat Belts は OFF） | — | p.547 (1.60.3) | yes：m17 L510 ← safety:238 | サイン (33) |
| PASS SIGNS ON (109) | memo | No Smoking と Seat Belts が両方 ON | — | p.547 (1.60.3) | yes：m27 L520 ← safety:246 | サイン (33) |
| SEATBELTS ON (109) | memo | Seat Belts スイッチ ON（No Smoking は OFF） | — | p.547 (1.60.3) | yes：m33 L526 ← safety:256 | サイン (33) |
| THERAP OXYGEN ON (109) | memo | 治療用酸素系統が作動 | — | p.547 (1.60.3) | no：m36 L529 | 酸素 (35) |
| BLD DUCT LEAK L, C, R | caution | 左・中央・右ダクト区間で抽気漏れまたは過熱 | beeper | p.619 (2.50.1) | no：c6–8 L114–116 | 抽気 (36) |
| BLD 1..4 OVHT/PRV | advisory | エンジン抽気の過熱、または PRV 閉固着 | — | p.619 (2.50.1) | no：a22–25 L208–211 | 抽気 (36) |
| BLEED 1..4 | advisory | 抽気過圧、または HP 弁・PRV が閉指令で閉じない | — | p.619 (2.50.1) | no：a26–29 L212–215 | 抽気 (36) |
| >BLEED 1..4 OFF | advisory | Bleed スイッチ OFF・エンジン運転中・抽気弁閉 | — | p.619 (2.50.1) | yes：a39–42 L225–228 ← air:961 | 抽気 (36) |
| BLEED HP ENG 1..4 | advisory | HP 抽気弁閉固着 | beeper（FCOM の表の記載のまま。advisory に beeper は異例） | p.619 (2.50.1) | no：a30–33 L216–219 | 抽気 (36) |
| BLEED ISLN L, R | advisory | アイソレーション弁のスイッチ位置と弁位置の不一致 | beeper（同上） | p.619 (2.50.1) | no：a35–36 L221–222 | 抽気 (36) |
| >BLEED ISLN APU | advisory | APU 抽気アイソレーション弁位置と指令の不一致 | — | p.619 (2.50.1) | no：a34 L220 | 抽気 (36) |
| CABIN ALT AUTO | caution | 客室高度制御器 2 台とも故障、または Outflow Valve Manual 2 つとも ON | beeper | p.619 (2.50.1) | yes：c10 L118 ← air:950 | 与圧 (21) |
| CABIN ALTITUDE | warning | 客室高度過大 | siren（reset で消音可） | p.619 (2.50.1)、p.1551 (15.20.5) | yes：w1 L74 ← air:943。aural は WARN-02 | 与圧 (21) |
| >E/E CLNG CARD | advisory | 機器冷却系統の故障（飛行中は抑止） | — | p.619 (2.50.1) | no：a87 L273 | 機器冷却 (21) |
| EQUIP COOLING | caution | NORM/STBY で風量不足・過熱・煙、OVRD で逆流冷却の差圧不足、または地上排気弁が指令位置にない | beeper | p.619 (2.50.1) | no：c27 L135 | 機器冷却 (21) |
| >HUMID FLT DK (109) | advisory | 操縦室加湿器の故障 | — | p.619 (2.50.1) | no：a197 L383 | 空調 (21) |
| LANDING ALT | advisory | 与圧制御器と FMC の着陸高度が不一致、または着陸高度 MAN | — | p.620 (2.50.2) | no：a240 L426 | 与圧 (21) |
| OUTFLOW VLV L, R | advisory | アウトフロー弁の自動制御不能、または Manual スイッチ ON | — | p.620 (2.50.2) | yes：a249–250 L435–436 ← air:1001 | 与圧 (21) |
| PACK 1, 2, 3 | advisory | パック制御器故障・運転故障・過熱、または逃し弁開でパック 2 停止 | — | p.620 (2.50.2) | no：a252–254 L438–440 | 空調 (21) |
| PACK CONTROL | advisory | 全パックの出口温度の自動制御が故障 | — | p.620 (2.50.2) | no：a251 L437 | 空調 (21) |
| PRESS RELIEF | advisory | 全パック運転中に圧力逃し弁が開 | — | p.620 (2.50.2) | no：a258 L444 | 与圧 (21) |
| TEMP CARGO HEAT | advisory | 後部貨物室加熱の作動中に過熱検出 | — | p.620 (2.50.2) | no：a284 L470 | 空調 (21) |
| TEMP ZONE | advisory | ゾーンダクト過熱、トリム空気弁閉固着、ゾーン温度制御器故障（405/570 は貨物ゾーンも） | — | p.620–621 (2.50.2–3) | no：a287 L473 | 空調 (21) |
| >TRIM AIR OFF | advisory | マスタートリム空気弁閉（温度はバックアップ制御） | — | p.621–622 (2.50.3–4) | no：a294 L480 | 空調 (21) |
| PACK 1, 2, 3 OFF | memo | パックスイッチ OFF | — | p.622 (2.50.4) | yes：m18–20 L511–513 ← air:1043 | 空調 (21) |
| PACKS 1 + 2, 1 + 3, 2 + 3 OFF | memo | パックスイッチ 2 つ OFF | — | p.622 (2.50.4) | yes：m21–23 L514–516 ← air:1019 | 空調 (21) |
| PACKS HIGH FLOW | memo | High Flow スイッチ ON | — | p.622 (2.50.4) | yes：m24 L517 ← air:1067 | 空調 (21) |
| PACKS OFF | memo | 全パックスイッチ OFF | — | p.622 (2.50.4) | yes：m25 L518 ← air:1010 | 空調 (21) |
| >ANTI-ICE | advisory | ナセル／主翼防氷 ON で TAT>12°C（109/570 は氷検知なしも条件） | — | p.635 (3.30.1) | yes：a7 L193 ← antiice:500 | 防氷 (30) |
| HEAT L, R TAT | advisory | TAT プローブのヒーター故障、または地上で加熱が切れない | — | p.635 (3.30.1) | no：a187・a193 L373・L379 | 防氷 (30) |
| HEAT P/S CAPT, F/O, L AUX, R AUX | advisory | ピトー静圧プローブのヒーター故障 | — | p.635 (3.30.1) | partly：a188–189 L374–375 ← antiice:524・532。AUX（a190–191 L376–377）は立たない | 防氷 (30) |
| HEAT WINDOW L, R | advisory | 風防ヒーター無電源 | — | p.635 (3.30.1) | no：a194–195 L380–381 | 防氷 (30) |
| >ICING (109, 570) | caution | 氷検知器が着氷を検知 | beeper | p.635 (3.30.1) | yes：c45 L153 ← antiice:482 | 防氷 (30) |
| NAI VALVE 1..4 | advisory | ナセル防氷弁が指令位置にない | — | p.635 (3.30.1) | no：a242–245 L428–431 | 防氷 (30) |
| >NO ICING (109, 570) | advisory | 防氷 ON のまま着氷が検知されなくなった | — | p.635 (3.30.1) | no：a247 L433 | 防氷 (30) |
| WAI VALVE LEFT, RIGHT | advisory | 主翼防氷弁が指令位置にない | — | p.635 (3.30.1) | no：a296–297 L482–483 | 防氷 (30) |
| >AUTOPILOT | caution | 選択中の AP が縮退モード（ロール／ピッチモード故障の可能性） | beeper | p.677 (4.30.1) | yes：c4 L112 ← autopilot:3387 | AFDS (22) |
| >AUTOPILOT DISC | warning | 全 AP が切断 | wailer（109/405）、siren（570） | p.677 (4.30.1)、p.655 (4.10.17) | yes：w0 L73 ← autopilot:835 ほか。wailer は X-Plane の annunciator 駆動（WARN-02） | AFDS (22) |
| >AUTOTHROT DISC | caution | A/T 切断（逆推力選択による切断では表示・音とも抑止） | beeper | p.677 (4.30.1) | yes：c5 L113 ← autopilot:3395 | A/T (22) |
| >NO AUTOLAND | caution / advisory | オートランド不能。LAND 2/3 表示後なら caution、表示前なら advisory | beeper（caution 時） | p.677 (4.30.1) | partly：a246 L432 ← autopilot:2993 だけ。c49 L157 は立たない | AFDS (22) |
| >NO LAND 3 | caution / advisory | 3 系統オートランドの冗長なし。LAND 3 表示後なら caution、前なら advisory | beeper（caution 時） | p.677 (4.30.1) | no：c50 L158・a248 L434 | AFDS (22) |
| >DATALINK AVAIL | advisory | ACARS が一時喪失から回復 | — | p.775 (5.40.1) | no：a55 L241 | 通信 (23) |
| >DATALINK LOST | advisory | 通信喪失で ACARS 不可 | — | p.775 (5.40.1) | no：a56 L242 | 通信 (23) |
| >DATALINK SYS | advisory | ACARS 系統故障 | — | p.775 (5.40.1) | no：a57 L243 | 通信 (23) |
| >HF DATA (570) | advisory | 選択 HF が故障し ACARS データ不可 | — | p.775 (5.40.1) | no：表に無い | 通信 (23) |
| RADIO TRANSMIT (570) | advisory | VHF/HF が 30 秒以上送信状態 | — | p.775 (5.40.1) | no：表に無い | 通信 (23) |
| >SATCOM | advisory | SATCOM 故障 | — | p.775 (5.40.1) | no：表に無い | 通信 (23) |
| >SATCOM DATA | advisory | SATCOM 経由の ACARS データ不可 | — | p.775 (5.40.1) | no：表に無い | 通信 (23) |
| >SATCOM VOICE | advisory | SATCOM 音声不可（データは可） | — | p.775 (5.40.1) | no：表に無い | 通信 (23) |
| >SATVOICE AVAIL | advisory | SATCOM 音声が回復 | — | p.775 (5.40.1) | no：表に無い | 通信 (23) |
| >SATVOICE LOST | advisory | SATCOM 音声が一時喪失 | — | p.775 (5.40.1) | no：表に無い | 通信 (23) |
| ACARS MESSAGE | memo | CDU で ACARS の操作が必要、またはメッセージ受信 | — | p.776 (5.40.2) | yes：m0 L493 ← fms:1256 | 通信 (23) |
| ATC MESSAGE (405, 570) | memo | ATC アップリンク受信 | — | p.776 (5.40.2) | no：表に無い | 通信 (23) |
| HF DATA OFF (570) | memo | 選択 HF が音声モード | — | p.776 (5.40.2) | no：m12 L505 | 通信 (23) |
| PRINTER MESSAGE | memo | ACARS メッセージ印字中 | — | p.776 (5.40.2) | no：m28 L521 と m42 L536 に同じ文言が 2 つ | 通信 (23) |
| SATCOM CALL | memo | 地上からの音声呼出し受信 | — | p.776 (5.40.2) | no：表に無い | 通信 (23) |
| SATCOM MESSAGE | memo | 通話状態の情報が CDU の SATCOM ページにある | — | p.776 (5.40.2) | no：m32 L525 | 通信 (23) |
| VHF DATA OFF | memo | VHF C（570 は全 VHF）が音声モード | — | p.776 (5.40.2) | no：m37 L530 | 通信 (23) |
| >BAT DISCH APU | advisory | APU バッテリー放電中 | — | p.821 (6.30.1) | yes：a19 L205 ← electrical:838 | 電源 (24) |
| >BAT DISCH MAIN | advisory | 主バッテリー放電中 | — | p.821 (6.30.1) | yes：a20 L206 ← electrical:839、fltInst02:3202（2 か所から書く） | 電源 (24) |
| >BATTERY OFF | advisory | Battery スイッチ OFF | — | p.821 (6.30.1) | yes：a21 L207 ← fltInst02:3213 | 電源 (24) |
| >DRIVE DISC 1..4 | advisory | Drive Disconnect スイッチ押しで IDG 切離し | — | p.821 (6.30.1) | yes：a83–86 L269–272 ← electrical:875 | 電源 (24) |
| ELEC AC BUS 1..4 | caution | AC バス無電源（関連機器のメッセージも出る） | beeper | p.821 (6.30.1) | yes：c15–18 L123–126 ← electrical:595 | 電源 (24) |
| ELEC BUS ISLN 1..4 | advisory | BTB 開（ELEC AC BUS 表示中は抑止） | — | p.821 (6.30.1) | no：a92–95 L278–281 | 電源 (24) |
| ELEC DRIVE 1..4 | advisory | IDG 油圧低・油温高（570・SB 後 109 は周波数故障の GCB 開も）。Drive Disc 押し時は抑止 | — | p.821 (6.30.1) | no：a96–99 L282–285 | 電源 (24) |
| ELEC GEN OFF 1..4 | advisory（109, 570）/ caution（405） | GCB 開（ELEC AC BUS 表示中は抑止） | 405 のみ beeper | p.822 (6.30.2) | partly：caution 版 c71–74 L179–182 ← electrical:770 を使用（109/570 では advisory が正）。advisory 版 a100–103 L286–289 は未使用 | 電源 (24) |
| >ELEC SSB OPEN | advisory | SSB が閉指令なのに開 | — | p.822 (6.30.2) | no：a104 L290 | 電源 (24) |
| ELEC UTIL BUS L, R | advisory | ギャレー／ユーティリティバス無電源（負荷制限中は抑止） | — | p.822 (6.30.2) | yes：a105–106 L291–292 ← electrical:907 | 電源 (24) |
| >STBY BUS APU (109, 570) | advisory | APU スタンバイバス無電源 | — | p.823 (6.30.3) | no：a276 L462 | 電源 (24) |
| >STBY BUS MAIN (109, 570) | advisory | 主スタンバイバス無電源 | — | p.823 (6.30.3) | no：a277 L463 | 電源 (24) |
| >STBY POWER OFF (405) | advisory | スタンバイバス無電源 | — | p.823 (6.30.3) | no：a278 L464 | 電源 (24) |
| >AUTOSTART OFF (109, 570) | advisory | Autostart スイッチ OFF | — | p.899 (7.40.1) | no：表に無い | エンジン始動 (80) |
| >EEC 1..4 TEST PWR (405)【PW】 | advisory | EEC 整備電源スイッチが TEST | — | p.899 (7.40.1) | no：表に無い | エンジン制御 (73) |
| ENG 1..4 AUTOSTART (109, 570) | caution | 地上始動でオートスタートが始動できない、または Autostart OFF で低回転のまま Fuel Control RUN | beeper | p.899 (7.40.1) | no：c19–22 L127–130 | エンジン始動 (80) |
| >ENG 1..4 CONTROL | advisory | EEC 系統の故障（飛行中は抑止） | — | p.899 (7.40.1) | no：a110–113 L296–299 | エンジン制御 (73) |
| >ENG CONTROLS | advisory | 3〜4 台の EEC が縮退で冗長なし（飛行中は抑止） | — | p.899 (7.40.1) | no：表に無い | エンジン制御 (73) |
| ENG 1..4 EEC MODE | advisory | EEC が alternate モード | — | p.899 (7.40.1) | no：表に無い | エンジン制御 (73) |
| ENG 1..4 FAIL | caution | エンジン故障・フレームアウト（地上では抑止） | beeper | p.899 (7.40.1) | partly：**warning 表** w28–31 L101–104 ← engines:1404 に置かれている（赤・master WARNING・siren になる。WARN-06） | エンジン (72) |
| ENG 1..4 FUEL FILT | advisory | 燃料フィルタのバイパス切迫 | — | p.900 (7.40.2) | yes：a114–117 L300–303 ← fuel:2861 | エンジン燃料 (73) |
| ENG 1..4 FUEL VLV | advisory | エンジン燃料弁または spar valve の位置が指令と不一致 | — | p.900 (7.40.2) | no：表に無い | エンジン燃料 (73)／燃料 (28) |
| ENG IGNITION【PW/GE で条件差】 | advisory | Continuous Ignition ON で点火されない（109/405 は後縁フラップ UP 以外のときも） | — | p.900 (7.40.2) | no：a109 L295 | 点火 (74) |
| >ENG 1..4 LIM PROT【PW/GE で条件差】 | caution | EEC alternate で推力が最大定格に接近（【GE】570 は指令 N1 が最大定格を超える） | beeper | p.900 (7.40.2) | no：表に無い | エンジン制御 (73) |
| ENG 1..4 LOW IDLE | advisory | 進入アイドルを指令したのに選ばれない | — | p.900 (7.40.2) | no：表に無い | エンジン制御 (73) |
| ENG 1..4 OIL FILT【PW/GE で条件差】 | advisory | オイルフィルタ汚損でバイパス接近（【PW】109/405 は primary フィルタ） | — | p.900–901 (7.40.2–3) | no：表に無い | エンジン潤滑 (79) |
| ENG 1..4 OIL PRESS | advisory | オイル圧が赤線 | — | p.901 (7.40.3) | no：表に無い | エンジン潤滑 (79) |
| ENG 1..4 OIL TEMP | advisory | オイル温度が amber 帯 | — | p.901 (7.40.3) | yes：a118–121 L304–307 ← engines:1522 | エンジン潤滑 (79) |
| >ENG 1..4 REVERSER（SB 後 109・405・570）/ ENG 1..4 REVERSER（SB 前 109） | advisory | 逆推力装置系統の故障 | — | p.901 (7.40.3) | partly：> 無し版 a126–129 L312–315 ← engines:1538 が立つ。> 付き版 a130–133 L316–319 は立たない | 逆推力 (78) |
| >ENG 1..4 RPM LIM【PW/GE で条件差】 | advisory | 【PW】N1 または N2 の赤線で推力制限、【GE】N2 赤線で制限 | — | p.901 (7.40.3) | yes：a134–137 L320–323 ← engines:1555 | エンジン制御 (73) |
| >ENG 1..4 SHUTDOWN | caution | Fire スイッチ引き、または Fuel Control CUTOFF。master CAUTION 灯は点かない | なし | p.902 (7.40.4)、p.1552 (15.20.6) | partly：c23–26 L131–134 ← engines:1414。master CAUTION と beeper を出してしまう（WARN-05） | エンジン (72) |
| ENG 1..4 START VLV | advisory | 始動弁位置と指令の不一致 | — | p.902 (7.40.4) | no：a138–141 L324–327 | エンジン始動 (80) |
| >IDLE DISAGREE | advisory | いずれかのエンジンのアイドル設定が指令と不一致 | — | p.902 (7.40.4) | no：a223 L409 | エンジン制御 (73) |
| STARTER CUTOUT 1..4 | caution | 始動弁が閉じない | beeper | p.902 (7.40.4) | yes：c61–64 L169–172 ← engines:1485 | エンジン始動 (80) |
| APU | advisory | APU selector ON で自動停止、または OFF なのに APU N1>95% | — | p.902 (7.40.4) | yes：a13 L199 ← electrical:856 | APU (49) |
| APU DOOR | advisory | APU ドアが指令位置にない | — | p.902 (7.40.4) | yes：a14 L200 ← electrical:867 | APU (49) |
| APU FUEL | advisory | ポンプ作動時の低圧、または APU 燃料弁が指令位置にない | — | p.902 (7.40.4) | yes：a15 L201 ← fuel:2853 | APU (49) |
| CON IGNITION ON | memo | Continuous Ignition ON（ENG IGNITION 表示中は抑止） | — | p.902 (7.40.4) | yes：m8 L501 ← engines:1609 | 点火 (74) |
| STBY IGNITION ON | memo | Standby Ignition が 1 または 2 | — | p.902 (7.40.4) | yes：m34 L527 ← electrical:933 | 点火 (74) |
| APU RUNNING | memo | APU selector ON で APU N1>95% | — | p.902 (7.40.4) | yes：m1 L494 ← electrical:923 | APU (49) |
| >BOTTLE LOW APU | advisory | APU 消火ボトル圧低下 | — | p.921 (8.30.1) | no：a44 L230 | 火災 (26) |
| >BTL LO L, R ENG A, B | advisory | 左右翼のエンジン消火ボトル A/B 圧低下 | — | p.921 (8.30.1) | no：表に無い（表の a47–48 `>BTL LOW APU A/B` は FCOM に無い文言） | 火災 (26) |
| >CARGO DET AIR (109, 570) | advisory | 貨物室煙探知の空気流不足 | — | p.921 (8.30.1) | no：a49 L235 | 火災 (26) |
| >CGO BTL DISCH | advisory | 地上：貨物消火ボトル圧低下、飛行中：ボトル A・B 放出済み | — | p.921–922 (8.30.1–2) | no：a51 L237 | 火災 (26) |
| >DET FIRE APU | advisory | APU 火災探知ループ A・B とも故障 | — | p.921 (8.30.1) | no：a58 L244 | 火災 (26) |
| >DET FIRE/OHT 1..4 | advisory | エンジン火災／過熱探知ループ A・B とも故障 | — | p.921 (8.30.1) | no：a59–62 L245–248 | 火災 (26) |
| FIRE APU | warning | APU 火災 | bell（reset で消音可） | p.921 (8.30.1)、p.1550 (15.20.4) | no：w8 L81 | 火災 (26) |
| FIRE CARGO AFT, FWD | warning | 下部貨物室の煙 | bell（同上） | p.921 (8.30.1) | no：w9–10 L82–83 | 火災 (26) |
| FIRE ENG 1..4 | warning | エンジン火災 | bell（同上） | p.921 (8.30.1) | yes：w11–14 L84–87 ← fire:488。bell は X-Plane の annunciator 駆動で reset 不可（WARN-03） | 火災 (26) |
| FIRE MAIN DECK (405, 570) | warning | 主デッキ貨物区画の複数ゾーンで煙 | bell | p.922 (8.30.2) | no：w15 L88 | 火災 (26) |
| FIRE MN DK AFT, FWD, MID (405, 570) | warning | 主デッキ貨物区画の煙 | bell | p.922 (8.30.2) | no：w16–18 L89–91 | 火災 (26) |
| FIRE WHEEL WELL | warning | 主脚格納部の火災 | bell | p.922 (8.30.2) | no：w21 L94 | 火災 (26) |
| OVHT ENG 1..4 NAC | caution | エンジンナセル過熱 | beeper | p.922 (8.30.2) | no：表に無い | 火災 (26) |
| >SMOKE CREW REST (570) | caution | 上階クルーレストの煙 | beeper | p.922 (8.30.2) | no：表に無い | 火災 (26) |
| SMOKE DR 5 REST (109) | caution | ドア 5 クルーレストの煙 | beeper | p.923 (8.30.3) | no：c52 L160 | 火災 (26) |
| >SMOKE LAVATORY (109) | advisory | ラバトリーの煙 | — | p.923 (8.30.3) | no：a264 L450。c53 L161 に caution の重複定義（誤り） | 火災 (26) |
| >FIRE TEST FAIL | warning | 手動火災試験で探知系統が不合格（不合格系統のメッセージも出る） | なし（試験中は bell） | p.923 (8.30.3)、p.919 (8.20.7) | no：w19 L92 | 火災 (26) |
| >FIRE TEST PASS | warning | 手動火災試験が完了 | なし（同上） | p.923 (8.30.3) | no：w20 L93 | 火災 (26) |
| >TEST IN PROG | warning | 手動火災試験中 | なし（同上） | p.923 (8.30.3) | no：w24 L97 | 火災 (26) |
| >VALVE TEST FAIL (405, 570) | warning | 主デッキ遮断弁・パックダンプ弁の試験で不合格 | なし | p.924 (8.30.4) | no：w25 L98 | 火災 (26) |
| >VALVE TEST PASS (405, 570) | warning | 同試験で不合格なし | なし | p.924 (8.30.4) | no：w26 L99 | 火災 (26) |
| >VLV TST IN PROG (405, 570) | warning | 同試験中 | なし | p.924 (8.30.4) | no：w27 L100 | 火災 (26) |
| AILERON LOCKOUT | advisory | エルロンロックアウト作動器の位置と指令の不一致 | — | p.957 (9.30.1) | no：a3 L189 | 操縦 (27) |
| >FLAP RELIEF | advisory | フラップ荷重緩和が作動中 | — | p.957 (9.30.1) | yes：a142 L328 ← fltCtrls:1188 | 操縦 (27) |
| FLAPS CONTROL | caution | フラップ制御装置不作動、または Alternate Flaps Arm が ALTN | beeper | p.957 (9.30.1) | yes：c28 L136 ← fltCtrls:1150 | 操縦 (27) |
| FLAPS DRIVE | caution | セカンダリ駆動の失敗、または非対称を検出 | beeper | p.957 (9.30.1) | no：c29 L137 | 操縦 (27) |
| FLAPS PRIMARY | caution | フラップ群がセカンダリ制御で作動中 | beeper | p.957 (9.30.1) | no：c30 L138 | 操縦 (27) |
| >FLT CONT VLVS | advisory | 操縦系統遮断弁のいずれかが閉 | — | p.957 (9.30.1) | no：a143 L329 | 操縦 (27)／油圧 (29) |
| RUD RATIO DUAL | advisory | ラダー比変換器 2 台故障 | — | p.957 (9.30.1) | no：a261 L447 | 操縦 (27) |
| RUD RATIO SNGL | advisory | ラダー比変換器 1 台故障 | — | p.957 (9.30.1) | no：a262 L448 | 操縦 (27) |
| SPEEDBRAKE AUTO | advisory | 自動グラウンドスポイラー系統の故障 | — | p.957 (9.30.1) | no：a272 L458 | 操縦 (27) |
| >SPEEDBRAKES EXT | caution | レバーが ARMED より後ろで、RA 15〜800 ft、またはフラップ着陸位置、またはスラストレバー 2 本以上が閉位置より前 | beeper | p.958 (9.30.2) | partly：c59 L167 ← fltCtrls:1165。条件式の誤り（WARN-13） | 警報 (31)／操縦 (27) |
| >STAB GREENBAND | advisory | 前脚圧力スイッチと計算グリーンバンドの不一致（ATA は無効 CG も） | — | p.958 (9.30.2) | no：a273 L459 | 警報 (31) |
| >STAB TRIM 2, 3 | advisory | スタビトリム自動カットアウト、カットアウトスイッチ、または作動器不作動 | — | p.958 (9.30.2) | no：a274–275 L460–461 | 操縦 (27) |
| STAB TRIM UNSCHD | caution | 非指令のスタビ作動で自動カットアウトしない、または AP 中に代替トリム使用 | beeper | p.958 (9.30.2) | no：c60 L168 | 操縦 (27) |
| >YAW DAMPER LWR, UPR | advisory | ヨーダンパー故障・無電源（IRU OFF/ALIGN、スイッチ OFF を含む） | — | p.958 (9.30.2) | yes：a300–301 L486–487 ← fltCtrls:1173 | AFDS (22) |
| SPEEDBRAKE ARMED | memo | スピードブレーキレバーが ARM | — | p.958 (9.30.2) | yes：m45 L539 ← fltCtrls(init):101、fltCtrls:668（init 側の表には無い。WARN-07） | 操縦 (27) |
| >SNGL SOURCE RA | advisory | 両操縦士の表示が同じ電波高度計 | — | p.1197 (10.50.1) | no：a266 L452 | 計器 (34) |
| >SOURCE SEL ADC | advisory | 両操縦士の表示が同じ ADC | — | p.1197 (10.50.1) | no：a267 L453 | 計器 (34) |
| >SOURCE SEL EIU | advisory | 両操縦士の表示が同じ EIU | — | p.1197 (10.50.1) | no：a268 L454 | 表示 (31) |
| >SOURCE SEL F/D | advisory | 両操縦士の表示が同じ FCC | — | p.1197 (10.50.1) | no：a269 L455 | AFDS (22) |
| >SOURCE SEL IRS | advisory | 両操縦士の表示が同じ IRU | — | p.1197 (10.50.1) | no：a270 L456 | 計器 (34) |
| >SOURCE SEL NAV | advisory | 両操縦士の表示が同じ FMC | — | p.1197 (10.50.1) | no：a271 L457 | 計器 (34) |
| ALT DISAGREE | caution | 機長・副操縦士の未補正高度が 200 ft 超不一致（5 秒続くまで抑止） | beeper | p.1197 (10.50.1) | no：c1 L109 | 計器 (34) |
| >ATTITUDE | caution | 選択 IRS の姿勢が 3° 以上不一致 | beeper | p.1197 (10.50.1) | no：c3 L111 | 計器 (34) |
| >BARO DISAGREE | advisory | 気圧設定が 1 分超不一致 | — | p.1198 (10.50.2) | yes：a18 L204 ← fltInst02:3148 | 計器 (34) |
| >HEADING | advisory | 表示機首方位が 4° 以上不一致 | — | p.1198 (10.50.2) | no：a185 L371 | 計器 (34) |
| IAS DISAGREE | caution | 対気速度が 5 kt 以上不一致（5 秒続くまで抑止） | beeper | p.1198 (10.50.2) | no：c44 L152 | 計器 (34) |
| >TRACK | advisory | 選択トラックが 6° 以上不一致 | — | p.1198 (10.50.2) | no：a291 L477 | 計器 (34) |
| >AOA RIGHT (109, 405) | advisory | 右 AOA センサー故障 | — | p.1198 (10.50.2) | yes：a12 L198 ← fltInst02:3179 | 計器 (34) |
| >EFIS CONTROL L, R | advisory | EFIS コントロールパネル不作動（CDU-161 は CDU 代替制御中も） | — | p.1198 (10.50.2) | no：a88–89 L274–275 | 表示 (31) |
| >EFIS/EICAS C/P | advisory | 両 EFIS パネルと EICAS 表示選択パネルが不作動（または CDU 代替制御中） | — | p.1199 (10.50.3) | no：a90 L276 | 表示 (31) |
| >EIU LEFT | advisory | 左 EIU 故障（飛行中は抑止） | — | p.1199 (10.50.3) | no：a91 L277 | 表示 (31) |
| FMC LEFT, RIGHT | advisory | 当該 FMC 故障 | — | p.1429 (11.60.1) | no：a144・a146 L330・L332 | FMC (34) |
| >FMC MESSAGE | advisory | FMC alert message がある（CDU の個々の文言は p.1430–1436） | — | p.1429–1430 (11.60.1–2) | yes：a145 L331 ← fms:1132 | FMC (34) |
| >FMC RUNWAY DIS (405) | caution | 離陸推力で位置・機首方位が FMC の出発滑走路の範囲外 | beeper | p.1429 (11.60.1) | no：表に無い | FMC (34) |
| >GPS | advisory | GPS 2 台故障 | — | p.1429 (11.60.1) | no：a182 L368 | 航法 (34) |
| >GPS LEFT, RIGHT | advisory | GPS センサー故障 | — | p.1429 (11.60.1) | no：a183–184 L369–370 | 航法 (34) |
| ILS ANTENNA | caution | G/S または LOC アンテナの切替不良 | beeper | p.1429 (11.60.1) | no：c47 L155 | 航法 (34)／警報 (31) |
| IRS CENTER, LEFT, RIGHT | advisory | IRU 故障 | — | p.1429 (11.60.1) | no：a228・a232・a234 L414・L418・L420（表の綴りは `IRS CENTRE`） | 航法 (34) |
| >IRS AC CENTER, LEFT, RIGHT | advisory | IRU の AC 電源喪失 | — | p.1429 (11.60.1) | no：a225–227 L411–413（綴り `CENTRE`） | 航法 (34) |
| >IRS DC CENTER, LEFT, RIGHT | advisory | IRU のバックアップ DC 喪失 | — | p.1429 (11.60.1) | no：a229–231 L415–417（綴り `CENTRE`） | 航法 (34) |
| IRS MOTION | advisory | アライン中に過大な機体運動 | — | p.1430 (11.60.2) | yes：a233 L419 ← irs:244、fms:1149 | 航法 (34) |
| >SNGL SOURCE ILS | caution | 両操縦士の表示が同じ LOC/GS 受信機 | beeper | p.1430 (11.60.2) | no：c57 L165 | 航法 (34) |
| >TRANSPONDER L, R | advisory | ATC トランスポンダ故障 | — | p.1430 (11.60.2) | no：a292–293 L478–479 | 航法 (34) |
| UNABLE RNP | advisory（進入以外）/ caution（進入） | 航法性能が RNP を満たさない（極域で抑止） | beeper（caution 時） | p.1430 (11.60.2) | partly：c66 L174 ← autopilot:2228 だけ。a295 L481 は立たない | FMC (34) |
| IRS ALIGN MODE C, L, R | memo | IRS がアラインモード（全 IRU が NAV に入ると消える） | — | p.1430 (11.60.2) | yes：m14–16 L507–509 ← irs:233 | 航法 (34) |
| FUEL IMBAL 1-4【GE は lb 値】 | advisory | 主 1・4 の差 1,360 kg（570：3,000 lb）、450 kg（1,000 lb）未満で消える | — | p.1473 (12.30.1) | yes：a149 L335 ← fuel:2910 | 燃料 (28) |
| FUEL IMBAL 2-3【GE は lb 値】 | advisory | 主 2・3 の差 2,720 kg（570：6,000 lb）、450 kg 未満で消える | — | p.1473 (12.30.1) | yes：a150 L336 ← fuel:2925 | 燃料 (28) |
| FUEL IMBALANCE【GE は lb 値】 | advisory | TANK/ENG 後に内側（2+3）と外側（1+4）の差 2,720 kg（570：6,000 lb） | — | p.1473 (12.30.1) | yes：a148 L334 ← fuel:2896 | 燃料 (28) |
| >FUEL JETT A, B | advisory | ジェティソン制御系統故障（FUEL JETT SYS 表示中は抑止） | — | p.1474 (12.30.2) | no：a151–152 L337–338 | 燃料 (28) |
| FUEL JETT SYS | caution | 残す燃料より少ないのにノズル弁開、または両ジェティソンカード故障 | beeper | p.1474 (12.30.2) | yes：c31 L139 ← fuel:2830 | 燃料 (28) |
| FUEL OVRD 2, 3 AFT | advisory | O/J ポンプ作動時の低圧（スイッチ OFF なら TANK/ENG 前でも表示） | — | p.1474 (12.30.2) | yes：a155–156 L341–342 ← fuel:2962 | 燃料 (28) |
| FUEL OVRD 2, 3 FWD | advisory | 同上 | — | p.1474 (12.30.2) | yes：a157–158 L343–344 ← fuel:2978 | 燃料 (28) |
| >FUEL LOW CTR L, R【GE は lb 値】 | advisory | ポンプ ON で CWT 量が始動前 7,700 kg 未満・上昇中約 3,200 kg・巡航中約 1,300 kg（ジェティソン中は抑止） | — | p.1474–1475 (12.30.2–3) | yes：a302–303 L488–489 ← fuel:2996 | 燃料 (28) |
| >FUEL OVD CTR L, R【GE は lb 値】 | advisory | ポンプ OFF で CWT 量が地上 7,700 kg 以上・巡航 1,800 kg 以上 | — | p.1474–1475 (12.30.2–3) | partly：a153–154 L339–340 の文言が `FUEL OVRD CTR L/R`（`>` が無く OVRD と綴る） ← fuel:2943 | 燃料 (28) |
| >FUEL PMP STB L, R (109) | advisory | 地上で STAB ポンプ ON、または巡航で HST 500 kg 以上なのにスイッチ OFF（FUEL STAB XFR 表示中は抑止） | — | p.1475 (12.30.3) | partly：a159–160 L345–346 の文言が `FUEL PMP STAB L/R`（`>` 無し・STAB） ← fuel:3035 | 燃料 (28) |
| FUEL PRES STB L, R (109) | advisory | HST ポンプ作動時の低圧 | — | p.1476 (12.30.4) | no：c67–68 L175–176 に **caution** として 2 つとも `FUEL PRES STAB L` で定義され、誰も立てない（R が無い） | 燃料 (28) |
| FUEL PRESS CTR L, R | caution | FUEL LOW CTR が 60 秒続く、またはスイッチ ON で低圧（ジェティソン中は CWT 900 kg 未満まで抑止） | beeper | p.1476 (12.30.4) | yes：c69–70 L177–178 ← fuel:2799 | 燃料 (28) |
| FUEL PRESS ENG 1..4 | caution | 吸引供給（同タンクの主ポンプ 2 台とも故障で xfeed 閉） | beeper | p.1477 (12.30.5) | no：c32–35 L140–143 | 燃料 (28) |
| FUEL PUMP 1..4 AFT | advisory | 主ポンプ低圧（FUEL PRESS ENG 表示中は抑止） | — | p.1477 (12.30.5) | yes：a161–164 L347–350 ← fuel:3061 | 燃料 (28) |
| FUEL PUMP 1..4 FWD | advisory | 同上 | — | p.1477 (12.30.5) | yes：a165–168 L351–354 ← fuel:3109 | 燃料 (28) |
| FUEL QTY LOW【GE は lb 値】 | caution | いずれかの主タンクが 900 kg（570：2,000 lb）以下 | beeper | p.1477 (12.30.5) | yes：c36 L144 ← fuel:2842 | 燃料 (28) |
| FUEL RES XFR 2, 3 | advisory | 予備タンク移送弁が指令位置にない | — | p.1477 (12.30.5) | no：a169–170 L355–356 | 燃料 (28) |
| FUEL STAB XFR (109) | caution | HST 燃料が移送されない | beeper | p.1477 (12.30.5) | no：c37 L145 | 燃料 (28) |
| >FUEL TANK/ENG | advisory | 主 2≦主 1 または主 3≦主 4 で xfeed 1/4 開（SB 後は給油後の地上条件も）。ジェティソン中は抑止、リフトオフ後 10 分は抑止 | — | p.1477–1478 (12.30.5–6)、p.1595 (15.20.49) | yes：a171 L357 ← fuel:3155 | 燃料 (28) |
| FUEL TEMP LOW | advisory | 燃料温度 -37°C 以下 | — | p.1478 (12.30.6) | partly：a172 L358 の文言に余分な `>` ← fuel:3170 | 燃料 (28) |
| FUEL TEMP SYS | advisory | 燃料温度センサー不作動 | — | p.1478 (12.30.6) | no：a173 L359 | 燃料 (28) |
| FUEL X FEED 1..4 | advisory | クロスフィード弁位置が指令と不一致 | — | p.1479 (12.30.7) | no：a175–178 L361–364 | 燃料 (28) |
| >FUEL XFER 1+4 | advisory | 飛行中に内側＞外側で Main 1&4 移送スイッチ ON、または地上で ON | — | p.1479 (12.30.7) | yes：a179 L365 ← fuel:3184 | 燃料 (28) |
| >JETT NOZ ON | advisory | ジェティソンノズル弁 2 つとも開 | — | p.1479 (12.30.7) | yes：a235 L421 ← fuel:3195 | 燃料 (28) |
| >JETT NOZ ON L, R | advisory | ノズル弁開（JETT NOZ ON 表示中は抑止） | — | p.1479 (12.30.7) | yes：a236–237 L422–423 ← fuel:3204 | 燃料 (28) |
| >JETT NOZZLE L, R | advisory | ノズル弁位置が指令と不一致 | — | p.1479 (12.30.7) | no：a238–239 L424–425 | 燃料 (28) |
| >SCAV PUMP ON (405) | advisory | 地上で CWT スカベンジポンプ作動 | — | p.1479 (12.30.7) | yes：a263 L449 ← fuel:3232 | 燃料 (28) |
| >X FEED CONFIG | advisory | xfeed 1/4 閉で主タンク不均等、または xfeed 2/3 閉でフラップが離陸位置でない | — | p.1479 (12.30.7) | yes：a299 L485 ← fuel:3254 | 燃料 (28) |
| HYD CONTROL 1, 4 | advisory | 油圧制御系統の不作動 | — | p.1495 (13.30.1) | no：a200–201 L386–387 | 油圧 (29) |
| HYD OVHT SYS 1..4 | advisory | 作動油温度過大 | — | p.1495 (13.30.1) | no：a202–205 L388–391 | 油圧 (29) |
| HYD PRESS DEM 1..4 | advisory | デマンドポンプ出口圧低（selector OFF、指令時の低圧、系統 4 の AUX）。HYD PRESS SYS で抑止 | — | p.1495 (13.30.1) | no：a206–209 L392–395 | 油圧 (29) |
| HYD PRESS ENG 1..4 | advisory | エンジン駆動ポンプ出口圧低。HYD PRESS SYS で抑止 | — | p.1495 (13.30.1) | no：a210–213 L396–399 | 油圧 (29) |
| HYD PRESS SYS 1..4 | caution | 油圧系統の圧力喪失 | beeper | p.1495 (13.30.1) | yes：c40–43 L148–151 ← hydraulics:348 | 油圧 (29) |
| >HYD QTY LOW 1..4 | advisory | 作動油量低下 | — | p.1495 (13.30.1) | yes：a218–221 L404–407 ← hydraulics:394 | 油圧 (29) |
| AIR/GND SYSTEM | advisory | 空地感知系統が air 側で故障 | — | p.1521 (14.30.1) | no：a5 L191 | 脚 (32) |
| ANTISKID | advisory | アンチスキッド故障 | — | p.1521 (14.30.1) | no：a10 L196 | 脚 (32) |
| ANTISKID OFF | advisory | 全車輪のアンチスキッド電源 OFF、駐機ブレーキ解除後に弁が全開でない、BSCU 電源喪失 | — | p.1521 (14.30.1) | no：a11 L197 | 脚 (32) |
| AUTOBRAKES | advisory | オートブレーキ解除・不作動、selector OFF で armed、または 85 kt 超の RTO で作動しない | — | p.1521 (14.30.1) | yes：a17 L203 ← gear:440 | 脚 (32) |
| >BODY GEAR STRG | advisory | ボディギアステアリングが指令ロック時に非ロック、または非指令で加圧 | — | p.1521 (14.30.1) | no：a43 L229 | 脚 (32) |
| BRAKE LIMITER | advisory | トルクリミッタ故障（1 トラックで 2 輪以上）など | — | p.1521 (14.30.1) | no：a45 L231 | 脚 (32) |
| >BRAKE SOURCE | caution | 油圧系統 1・2・4 のブレーキ圧がすべて低い | beeper | p.1521 (14.30.1) | yes：c9 L117 ← hydraulics:341 | 脚 (32) |
| BRAKE TEMP | advisory | ブレーキ温度 5 以上 | — | p.1521 (14.30.1) | yes：a46 L232 ← gear:868 | 脚 (32) |
| GEAR DISAGREE | caution | 通常作動時間後に脚位置がレバーと不一致 | beeper | p.1522 (14.30.2) | no：c38 L146 | 脚 (32) |
| GEAR DOOR | advisory | 通常作動時間後に脚扉が閉じない（代替脚下げ時は抑止） | — | p.1522 (14.30.2) | no：a180 L366 | 脚 (32) |
| GEAR TILT | caution | 主脚トラックが全傾斜位置でない | beeper | p.1522 (14.30.2) | no：c39 L147 | 脚 (32) |
| >TIRE PRESSURE (109) | advisory | タイヤ圧が範囲外 | — | p.1522 (14.30.2) | no：a290 L476。c65 L173 に caution の重複定義（`TIRE PRESSURE`、誤り） | 脚 (32) |
| AUTOBRAKES 1..4 | memo | オートブレーキ段階を選択 | — | p.1522 (14.30.2) | yes：m2–5 L495–498 ← gear:874 | 脚 (32) |
| AUTOBRAKES MAX | memo | オートブレーキ MAX 選択 | — | p.1522 (14.30.2) | yes：m6 L499 ← gear:906 | 脚 (32) |
| AUTOBRAKES RTO | memo | オートブレーキ RTO 選択 | — | p.1522 (14.30.2) | yes：m7 L500 ← gear:914 | 脚 (32) |
| PARK BRAKE SET | memo | 駐機ブレーキ弁閉 | — | p.1522 (14.30.2) | yes：m26 L519 ← hydraulics:371 | 脚 (32) |
| >CONFIG FLAPS | warning | 地上・V1 未満・Fuel Control 3 本以上 RUN・エンジン 2 か 3 が離陸推力域で、フラップが離陸位置でない | siren（reset 不可） | p.1603 (15.30.1)、p.1557 (15.20.11) | partly：w2 L75 ← fltCtrls:1013（WARN-11） | 警報 (31) |
| >CONFIG GEAR | warning | いずれかの脚が down & locked でなく、RA 800 ft 未満でスラストレバーが閉、またはフラップ着陸位置 | siren（レバー閉が原因のときだけ reset 可） | p.1603 (15.30.1)、p.1556 (15.20.10) | partly：w3 L76 ← fltCtrls:1045（WARN-12） | 警報 (31) |
| >CONFIG GEAR CTR | warning | 上の離陸条件でボディギア非中立 | siren（reset 不可） | p.1603 (15.30.1) | partly：w4 L77 ← fltCtrls:1026（WARN-11） | 警報 (31) |
| >CONFIG PARK BRK | warning | 上の離陸条件で駐機ブレーキ ON | siren（reset 不可） | p.1603 (15.30.1) | partly：w5 L78 ← fltCtrls:1086（WARN-11） | 警報 (31) |
| >CONFIG SPOILERS | warning | 上の離陸条件でスピードブレーキレバーが DOWN でない。405/570 は飛行中にレバーが ARM 超で 2 本以上が上昇推力以上も | siren（reset 不可） | p.1603–1604 (15.30.1–2)、p.1558 (15.20.12) | partly：w6 L79 ← fltCtrls:1101・1110・962（WARN-11） | 警報 (31) |
| >CONFIG STAB | warning | 上の離陸条件でスタビがグリーンバンド外 | siren（reset 不可） | p.1604 (15.30.2) | partly：w7 L80 ← fltCtrls:1140（WARN-11） | 警報 (31) |
| >CONFIG WARN SY | advisory | 形態警報系統の故障（ATA は status も） | — | p.1604 (15.30.2)、p.1558 (15.20.12) | no：a52 L238 | 警報 (31) |
| >ALT CALLOUTS【PW/GE で条件差】 | advisory | 進入中の高度音声（405/570 はミニマム音声も）が出ない | — | p.1604 (15.30.2) | no：a6 L192 | GPWS (34) |
| GND PROX SYS | advisory | GPWS 警報が出ない可能性（FLAP OVRD で 250 kt・GEAR OVRD で 290 kt を 60 秒超えたときも） | — | p.1604 (15.30.2)、p.1538–1539 (15.10.12–13) | no：a181 L367 | GPWS (34) |
| >TERR OVRD (405, 570) | advisory | GND PROX TERR OVRD スイッチ OVRD | — | p.1604 (15.30.2) | no：a289 L475 | GPWS (34) |
| TERR POS (405, 570) | advisory | GPS 故障でルックアヘッド地形警報・表示不可 | — | p.1605 (15.30.3) | no：a288 L474 | GPWS (34) |
| WINDSHEAR SYS | advisory | ウインドシア警報が出ない可能性 | — | p.1605 (15.30.3) | no：a298 L484（文言に余分な `>`） | GPWS (34) |
| >TCAS OFF | advisory | トランスポンダで TA または TA/RA が選ばれていない（離陸時 400 ft まで抑止） | — | p.1605 (15.30.3) | yes：a279 L465 ← fltMgmt:423 | TCAS (34) |
| >TCAS RA CAPTAIN, F/O | advisory | 当該 PFD に RA ガイダンスを出せない | — | p.1605 (15.30.3) | no：a280–281 L466–467（文言 `>TCAS RA CAPT`、設定行 fltMgmt:427–433 はブロックコメント） | TCAS (34) |
| >TCAS SYSTEM | advisory | TCAS 故障 | — | p.1605 (15.30.3) | no：a282 L468 | TCAS (34) |
| >AIRSPEED LOW | caution | 速度が最小機動速度（amber 帯の上端）未満 | beeper | p.1605 (15.30.3)、p.1556 (15.20.10)、p.973 (10.10.11) | partly：c0 L108 ← fltInst02:3171（Vmc/Vs と比較。WARN-15） | 警報 (31)／計器 (34) |
| >ALTITUDE ALERT | caution | MCP 選択高度から 300 ft 超逸脱 | beeper | p.1605 (15.30.3)、p.1559 (15.20.13) | no：c2 L110（WARN-16） | 高度警報 (34-16) |
| >OVERSPEED | warning | 速度が Vmo/Mmo を超過 | siren（109 SB 前は reset 不可、405/570・SB 後 109 は reset 可） | p.1605 (15.30.3)、p.1557 (15.20.11) | partly：w22 L95 ← fltInst02:3161（フラップ・脚の制限速度でも出る。WARN-15） | 警報 (31) |
| >PILOT RESPONSE (405, 570, SB 後 109) | advisory → caution → warning | FMC が監視スイッチの操作を一定時間検知しない（段階的に昇格。20,000 ft 未満で抑止） | なし → beeper → siren（reset 可） | p.1606 (15.30.4)、p.1559 (15.20.13) | no：a257 L443・c51 L159・w23 L96 | FMC (34) |
| VMO GEAR DOWN | memo | 電子機器室で脚下げディスパッチを選択 | — | p.1606 (15.30.4)、p.1557 (15.20.11) | no：m38 L531 | ADC (34) |
| VMO SPARE ENGINE | memo | 電子機器室でスペアエンジン運搬ディスパッチを選択 | — | p.1606 (15.30.4) | no：m39 L532 | ADC (34) |

- FMC の CDU スクラッチパッド文言（FMC alert / advisory messages、p.1430–1436）は EICAS メッセージではない。FMC alert message があるときに `>FMC MESSAGE` が出る（FCOM p.1430 (11.60.2)）。

## 2. コードの表にあって FCOM（Rev.23）に無いもの、または定義の誤り

`B747.87.xt.warning.lua` の表 458 件（warning 32、caution 75、advisory 304、memo 47）のうち、FCOM に対応しないもの。多くは FCOM の他の版・他の顧客仕様（PVD、MLS、IFF など）からの流用と推定（推定：FCOM の 109/405/570 のどれにも無く、名前が他機種仕様の装備を指すため）。残すか消すかは型式の決め方による（ATA-31-warning.md §8）。

| 表の定義 | 行 | 誰が立てるか | 内容 |
|---|---|---|---|
| c53 `>SMOKE LAVATORY` | L161 | なし | **レベル誤り**。FCOM は advisory（a264 と重複） |
| c65 `TIRE PRESSURE` | L173 | なし | **レベル・文言誤り**。FCOM は `>TIRE PRESSURE` advisory（a290 と重複） |
| c67・c68 `FUEL PRES STAB L` | L175–176 | なし | **文言・レベル誤り**。2 つとも L で R が無い。FCOM は `FUEL PRES STB L, R` advisory（109） |
| c71–74 `ELEC GEN OFF 1..4` | L179–182 | electrical:770 | **型式でレベルが違う**。109/570 は advisory（a100–103 L286–289 が未使用のまま残る）。405 なら caution で正しい |
| w28–31 `ENG 1..4 FAIL` | L101–104 | engines:1404 | **レベル誤り**。FCOM は caution（beeper） |
| a78 `DOOR U/D FLT LK` | L264 | なし | **レベル誤り**。FCOM は caution（c14 と重複） |
| m41 `ACARS CALL`・`ACARS VOICE` | L534–535 | なし | **添字の重複**（どちらも DRindex 41。memo_status[41] が立つと 2 行出る） |
| m28・m42 `PRINTER MESSAGE` | L521・L536 | なし | 同じ文言が 2 添字 |
| a153–154 `FUEL OVRD CTR L/R` | L339–340 | fuel:2943 | 文言誤り（FCOM `>FUEL OVD CTR L, R`） |
| a159–160 `FUEL PMP STAB L/R` | L345–346 | fuel:3035 | 文言誤り（FCOM `>FUEL PMP STB L, R`） |
| a172 `>FUEL TEMP LOW` | L358 | fuel:3170 | `>` が余分（FCOM `FUEL TEMP LOW`） |
| a298 `>WINDSHEAR SYS` | L484 | なし | `>` が余分（FCOM `WINDSHEAR SYS`） |
| a225–231 `IRS ... CENTRE` | L411–417 | なし | 綴り（FCOM `CENTER`） |
| a280–281 `>TCAS RA CAPT`・`>TCAS RA F/O` | L466–467 | なし（fltMgmt:427–433 はコメント） | FCOM の表記は `>TCAS RA CAPTAIN, F/O`。実機の表示文字数から `CAPT` 表記の可能性もある（未確認） |
| c46 `>ICING NAC` | L154 | なし | FCOM に無い |
| c48 `MLS ANTENNA`、c58 `>SNGL SOURCE MLS` | L156・L166 | なし | FCOM に無い（MLS 装備） |
| c54 `>SMOKE LAV/COMP`、a265 同 | L162・L451 | なし | FCOM に無い |
| c55 `>SMOKE ZN B REST`、c56 `>SMOKE ZN F REST` | L163–164 | なし | FCOM に無い |
| a0–2 `>ADC CENTRE/LEFT/RIGHT` | L186–188 | なし | FCOM に無い |
| a4 `>ALT ALERT SYS` | L190 | なし | FCOM に無い |
| a8 `>ANTI-ICE NAC`、a9 `>ANTI ICE WING` | L194–195 | なし | FCOM に無い |
| a16 `>APU GEN 1` | L202 | なし | FCOM に無い |
| a37–38 `BLEED LOSS L/R` | L223–224 | なし | FCOM に無い |
| a47–48 `>BTL LOW APU A/B` | L233–234 | なし | FCOM に無い（FCOM は `>BOTTLE LOW APU` と `>BTL LO L, R ENG A, B`） |
| a50 `>CDU MENU` | L236 | なし | FCOM に無い |
| a54 `CREW RST OXY ON` | L240 | なし | FCOM に無い |
| a122–125 `ENG 1..4 REV LIMTD` | L308–311 | なし | FCOM に無い |
| a147 `>FMC STATUS` | L333 | なし | FCOM に無い |
| a174 `>FUEL WING ISOL` | L360 | なし | FCOM に無い |
| a186・a192 `HEAT L AOA`・`HEAT R AOA` | L372・L378 | antiice:508・516 | FCOM（Rev.23）の 3.30 に無い |
| a196・a198・a199 `>HUMID DOOR 5`・`>HUMID MAIN CAB`・`>HUMID ZONE F` | L382・L384・L385 | なし | FCOM に無い（`>HUMID FLT DK` だけ 109 にある） |
| a214–217 `>HYD QTY HALF 1..4` | L400–403 | なし | FCOM に無い |
| a222 `>ICE DETECTORS` | L408 | なし | FCOM に無い |
| a224 `>IFF MODE 4` | L410 | なし | FCOM に無い |
| a241 `>LE FLAPS DIS` | L427 | なし | FCOM に無い |
| a255 `>PASS OXY LOW` | L441 | なし | FCOM に無い |
| a259–260 `>PVD SYS CAPT/F/O`、m29–31 `PVD ... ON` | L445–446・L522–524 | なし | FCOM に無い（PVD 装備） |
| a283 `>TEMP CARGO A/C`、a285–286 `TEMP DEV CGO HI/LO` | L469・L471–472 | なし | FCOM に無い |
| m9–11 `DOORS AUTO`・`DOORS AUTO/MAN`・`DOORS MANUAL` | L502–504 | なし | FCOM に無い |
| m13 `HIGH ALT LDG` | L506 | なし | FCOM に無い |
| m35 `STROBE LIGHT OFF` | L528 | lighting:2148（常に 0） | FCOM に無い |
| m40 `ACARS NO COMM`、m43 `ACARS ALERT`、m44 `ACARS VOICE BUSY` | L533・L537・L538 | m40 ← fms:1241 | FCOM に無い（Hoppie 等の独自表示として残す判断はあり得る） |

- 初期化側 `init/scripts/B747.87.warning/B747.87.warning.lua` にも同じ表の複製がある。memo の `SPEEDBRAKE ARMED`（m45）が無く、`IRS ALIGN MODE` の L と C の順が xt 側と逆。配列の大きさはこの複製の件数で決まる（`B747.87.warning02.lua:117–120`）。memo は添字 41 の重複で件数が 1 多く、偶然 m45 まで収まっている。

## 3. STATUS メッセージ（補助 EICAS の STATUS ページ）

- FCOM は STATUS メッセージの一覧を持たない。STATUS メッセージは DDG（Dispatch Deviation Guide）に載り、MEL を参照させるもの（FCOM p.1548 (15.20.2)、p.1545 (15.10.19)）。FCOM の図の例は `CABIN ALT AUTO A`、`CARGO HEAT FWD L`（FCOM p.1545）。
- 今回読んだ整備資料に出てくる警報系統関係の STATUS メッセージ：

| メッセージ | Level | 条件 | 出典 | 実装 |
|---|---|---|---|---|
| CONFIG WARN SY(S) | status（advisory と同時） | 形態警報カードの故障、またはその入力の喪失 | ATA31 p.270 (31-51)、ATA27 p.724・p.747 (27-90) | no |
| STAB GREENBAND | status（advisory と同時） | 前脚圧力スイッチとグリーンバンドの不一致、または CDU の CG が範囲外 | ATA31 p.202・p.272、ATA27 p.747 | no |
| MAWEA PWR SUPPLY | status | MAWEA 電源 A/B の故障・OFF、または SCID カード 1/2 の入力喪失 | ATA31 p.153・p.270 | no |
| AURAL SYNTH CARD | status | 左右どちらかの aural synthesizer card 故障 | ATA31 p.270 | no |
| AURAL WARN SPKR | status | 左右どちらかの警報スピーカー故障（MAWEA より先にスピーカーに電源が無いと誤表示） | ATA31 p.154・p.270 | no |
| MAWEA MASTER MON | status | master monitor card A または B の故障 | ATA31 p.272 | no |
| MAWEA SCID CARD | status | signal collection card 1/2 の故障または入力喪失 | ATA31 p.272 | no |
| MAWEA ID CARD | status | 機体識別カードの故障または入力喪失 | ATA31 p.272 | no |
| STALL WARN SYS | status | 失速警報系統の故障（試験ジャック接地時にも出る） | ATA27 p.706 (27-32) | no |

- シムのパネルの STATUS ページ（`laminar/B747/dsp/synoptic_display` = 2）は油圧・APU・酸素・バッテリー・舵面位置の数値だけで、メッセージ行が無い（`747-400.acf` 129369 行付近）。STATUS メッセージの表示にはパネルの追加が要る（ATA-31-warning.md WARN-17）。

## 4. 集計

- FCOM の行（番号違いをまとめた 256 行）：yes 70、partly 21、no 165。
- コード表 458 件のうち、どこかで立てられているのは 165 件（36%）。
- 警報系統が条件を持つ 12 行（CONFIG 6 件、SPEEDBRAKES EXT、AIRSPEED LOW、OVERSPEED、CONFIG WARN SY、STAB GREENBAND、ALTITUDE ALERT）は yes 0、partly 9、no 3。
