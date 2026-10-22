# 資料索引（REFERENCE_INDEX）

資料の PDF は `_ref/` にある。`_ref/` は `.git/info/exclude` で git の管理から外してあり、どのブランチにもコミットしない。

## 使い方

- このファイルのページ番号は、すべて **PDF のページ番号**（1 始まり）。資料自身のページ番号（FCOM の `6.20.3`、整備訓練マニュアルの `ATA 24-20 Page 5` など）とは別物。
- テキストは `_ref/text/` にある（xpdf の `pdftotext -layout` で抽出）。
  - `_ref/text/<ID>.txt`：全ページを1ファイルにしたもの。各ページの前に `==== [<ID> p.N] ====` の行が入る。
  - `_ref/text/<ID>/pNNNN.txt`：1ページ1ファイル（`p0123.txt` が PDF の p.123）。
  - `_ref/text/<ID>.pages.tsv`：ページ番号、空白以外の文字数、先頭行、末尾行。
  - `_ref/text/SOURCES.tsv`：ID と PDF ファイル名の対応。
- 検索するとき：`_ref/` は git の管理外なので、Grep ツールではパスを必ず明示する（例：`path: "_ref/text/FCOM"`）。
- 文字数が 400 未満のページは、図が本体であることが多い。整備訓練マニュアルは「左ページが図、右ページが本文」の見開き構成で、ページの約半分がこれにあたる。図は Read ツールで PDF を `pages` 指定して画像として読む（1回 20 ページまで）。
- 引用の書き方（notes/、GAP_ANALYSIS.md、コミットメッセージで共通）：`ID p.<PDFページ>`。資料自身の番号があれば括弧で添える。
  - 例：`FCOM p.801 (6.20.7)`、`ATA22 p.212 (22-10)`、`LH24 p.95 (24-20)`、`FCTM p.160 (5.4)`、`FMSPG p.100 (3.2-40)`

## 資料一覧

| ID | 資料 | ページ数 | 図が主のページ (<400字) | 型式・版 |
|---|---|---|---|---|
| FCOM | Boeing 747-400 Flight Crew Operations Manual（D6-30151-400） | 1606 | 240 | Rev. 23（2009-10-01）。性能（PI 章）は PW4056 と CF6-80C2B1F（747-400F）を収録 |
| FCTM | Boeing 747-400 Flight Crew Training Manual | 318 | 24 | 2006-10-31 版。エンジン型式によらない。FCOM と食い違えば FCOM を優先 |
| FMSPG | Honeywell B747-400 FANS FMS Pilot's Guide | 415 | 34 | ©1996。FMC/CDU の操作と画面 |
| LH24 | Lufthansa Technical Training B1：ATA 24 Electrical Power（B747-4 PW 24 B1 E） | 256 | 133 | PW 機、2003 年 |
| LH36 | Lufthansa Technical Training B1：ATA 36 Pneumatic（B747-4 PW 36 B1 E） | 138 | 31 | PW 機、2005 年。主翼防氷・氷検知（ATA 30）も一部含む |
| LH3460 | Lufthansa Technical Training B1：ATA 34-60 FMCS（B747-4 34-60 B1 E） | 136 | 79 | 2001〜2005 年 |
| ATA21 | E&M 整備訓練マニュアル：ATA 21 Environmental Control | 616 | 354 | Config: ALL |
| ATA22 | 同：ATA 22 Autopilot/Flight Director System | 408 | 233 | autothrottle（推力管理）は ATA 34-61（ATA34_2・LH3460）にある |
| ATA23 | 同：ATA 23 Communication | 702 | 415 | 大半は客室系（PA、IFE、PSS） |
| ATA26_28 | 同：ATA 26 Fire Protection ＋ ATA 28 Fuel | 566 | 324 | |
| ATA27 | 同：ATA 27 Flight Controls | 748 | 401 | |
| ATA29_32 | 同：ATA 29 Hydraulics ＋ ATA 32 Landing Gear | 674 | 377 | |
| ATA30_32_35_36 | 同：ATA 36 Pneumatic ＋ ATA 30 Ice and Rain ＋ ATA 35 Oxygen | 386 | 229 | ファイル名に 32 とあるが、ATA 32 の内容は無い |
| ATA31 | 同：ATA 31 Indicating/Recording | 564 | 348 | EFIS/EICAS（IDS）、aural warning、FDR、ACMS、W&B |
| ATA33 | 同：ATA 33 Lights | 362 | 206 | |
| ATA34_1 | 同：ATA 34 Navigation（1）：air data、無線航法、気象レーダー、ATC | 646 | 372 | 先頭に ATA 20-11 Digital Systems |
| ATA34_2 | 同：ATA 34 Navigation（2）：TCAS、RA、GPWS、IRS、GPS、FMCS | 736 | 410 | FMCS（34-61）が 310 ページある |
| ATA38_51_52_56 | 同：ATA 38 Water/Waste、51 Structures、52 Doors、56 Windows | 614 | 327 | |
| ATA70_80 | 同：ATA 71〜80 Powerplant | 576 | 298 | CF6-80C2 |

- APU（ATA 49）の整備資料は無い。APU は FCOM 7.14・7.30・7.40 を基準にする。
- 電源（ATA 24）は LH24 だけ（PW 機）。整備訓練マニュアルには ATA 24 の巻が無い。
- 資料にない ATA 章：24（LH24 で代替）、25、45（CMC）、46、49。

## FCOM（D6-30151-400）

| 章 | 節 | 内容 | PDF p. |
|---|---|---|---|
| 0 Preface | 0.1 / 0.2 / 0.3 / 0.4 / 0.5 / 0.6 | Model Identification / Introduction / Abbreviations / Revision Record / List of Effective Pages / Bulletin Record | 5-6 / 7-14 / 15-20 / 21-34 / 35-42 / 43-74 |
| L Limitations | L.10 | Operating Limitations | 75-84 |
| NP Normal Procedures | NP.11 / NP.21 | Introduction / Amplified Procedures | 87-94 / 95-154 |
| SP Supplementary Procedures | SP.05 | Introduction | 159-160 |
| | SP.1 / SP.2 / SP.4 / SP.5 | Airplane General / Air Systems / Automatic Flight / Communications | 161-166 / 167-170 / 171-176 / 177-178 |
| | SP.6 / SP.7 / SP.8 / SP.10 | Electrical / Engines, APU / Fire Protection / Flight Instruments, Displays | 179-182 / 183-186 / 187-188 / 189-190 |
| | SP.11 / SP.12 / SP.16 | Flight Management, Navigation / Fuel / Adverse Weather | 191-198 / 199-200 / 201-220 |
| PI Performance Inflight（747-400/PW4056） | PI.10〜PI.18 | General、All Engines、Advisory、One/Two Engines Inop、Alternate Mode EEC、Gear Down、Text | 223-324 |
| PI Performance Inflight（747-400F/CF6-80C2B1F） | PI.20〜PI.27 | 同上（Alternate Mode EEC の節は無い） | 325-412 |
| 1 Airplane General, Emergency Equipment, Doors, Windows | 1.10 | Dimensions | 419-422 |
| | 1.20〜1.23 | Flight Deck Panels（overhead、forward、control stand、aisle stand） | 423-434 |
| | 1.30 | Controls and Indicators（照明、非常灯、酸素、避難、ELT、ドア） | 435-498 |
| | 1.40 / 1.45 / 1.50 | Systems Description（照明・酸素など / 非常装備 / ドア・窓） | 499-514 / 515-526 / 527-544 |
| | 1.60 | EICAS Messages | 545-548 |
| 2 Air Systems | 2.10 | Controls and Indicators | 553-586 |
| | 2.20 / 2.30 / 2.40 | Air Conditioning / Pressurization / Bleed Air System Description | 587-606 / 607-610 / 611-618 |
| | 2.50 | EICAS Messages | 619-622 |
| 3 Anti-Ice, Rain | 3.10 / 3.20 / 3.30 | Controls and Indicators / System Description / EICAS Messages | 625-630 / 631-634 / 635-636 |
| 4 Automatic Flight | 4.10 / 4.20 / 4.30 | Controls and Indicators / System Description / EICAS Messages | 639-658 / 659-676 / 677-678 |
| 5 Communications | 5.10 / 5.20 / 5.30 | Controls and Indicators / System Description / Interphone | 683-712 / 713-718 / 719-724 |
| | 5.33 / 5.34 / 5.40 | ATC Datalink / Company Datalink / EICAS Messages | 725-770 / 771-774 / 775-776 |
| 6 Electrical | 6.10 / 6.20 / 6.30 | Controls and Indicators / System Description / EICAS Messages | 779-794 / 795-820 / 821-824 |
| 7 Engines, APU | 7.10 / 7.11 / 7.12 | Primary / Secondary / Compact Engine Indications | 829-840 / 841-854 / 855-858 |
| | 7.13 / 7.14 | Engine Controls / APU Controls and Indications | 859-866 / 867-870 |
| | 7.20 / 7.30 / 7.40 | Engine System Description / APU System Description / EICAS Messages | 871-894 / 895-898 / 899-902 |
| 8 Fire Protection | 8.10 / 8.20 / 8.30 | Controls and Indicators / System Description / EICAS Messages | 905-912 / 913-920 / 921-924 |
| 9 Flight Controls | 9.10 / 9.20 / 9.30 | Controls and Indicators / System Description / EICAS Messages | 927-940 / 941-956 / 957-958 |
| 10 Flight Instruments, Displays | 10.10 | Controls and Indicators | 963-1068 |
| | 10.20 / 10.30 / 10.40 | System Description / PFD / ND | 1069-1080 / 1081-1108 / 1109-1158 |
| | 10.45 / 10.50 | EFB / EICAS Messages | 1159-1196 / 1197-1200 |
| 11 Flight Management, Navigation | 11.10 / 11.20 | Controls and Indicators / Navigation Systems Description（IRS、GPS、無線航法） | 1207-1224 / 1225-1232 |
| | 11.30 / 11.31 / 11.32 | FMS Introduction / FMS Operation / FMC（データベース、thrust management） | 1233-1234 / 1235-1270 / 1271-1276 |
| | 11.40 / 11.41 / 11.42 / 11.43 | FMC Preflight / Takeoff and Climb / Cruise / Descent and Approach | 1277-1324 / 1325-1344 / 1345-1388 / 1389-1420 |
| | 11.50 / 11.60 | FMS Alternate Navigation / EICAS Messages | 1421-1428 / 1429-1436 |
| 12 Fuel | 12.10 / 12.20 / 12.30 | Controls and Indicators / System Description / EICAS Messages | 1439-1452 / 1453-1472 / 1473-1480 |
| 13 Hydraulics | 13.10 / 13.20 / 13.30 | Controls and Indicators / System Description / EICAS Messages | 1483-1488 / 1489-1494 / 1495-1496 |
| 14 Landing Gear | 14.10 / 14.20 / 14.30 | Controls and Indicators / System Description / EICAS Messages | 1499-1510 / 1511-1520 / 1521-1522 |
| 15 Warning Systems | 15.10 / 15.20 / 15.30 | Controls and Indicators / System Description（EICAS、aural、GPWS、TCAS など） / EICAS Messages | 1527-1546 / 1547-1602 / 1603-1606 |

- 各章の先頭ページ（目次）は表の範囲の直前にある（例：6 Electrical の目次は p.777-778）。
- この FCOM には非常操作のチェックリスト（QRH / NNC）は入っていない。

## FCTM

| 章 | 内容 | PDF p. |
|---|---|---|
| 前付け | Preface、目次、改訂記録 | 1-27 |
| 1 | General Information（AFDS・FMC の使い方の原則など） | 28-71 |
| 2 | Ground Operations | 72-87 |
| 3 | Takeoff and Initial Climb | 88-120 |
| 4 | Climb, Cruise, Descent and Holding | 121-143 |
| 5 | Approach and Missed Approach | 144-211 |
| 6 | Landing | 212-247 |
| 7 | Maneuvers | 248-275 |
| 8 | Non-Normal Operations | 276-318 |

## FMSPG（Honeywell FANS FMS Pilot's Guide）

| 節 | 内容 | PDF p. |
|---|---|---|
| 前付け | 目次 | 1-11 |
| 1 | Pilot Overview | 12-14 |
| 2 | Flight Management（概要、構成、インターフェース、飛行段階、機能、データベース、MCDU） | 15-55 |
| 3.1 / 3.2 | Flight Data / Preflight（IDENT、POS INIT、RTE、PERF INIT、THRUST LIM、TAKEOFF REF など） | 57-60 / 61-109 |
| 3.3 / 3.4 | Takeoff/Climb / Cruise | 110-129 / 130-184 |
| 3.5 / 3.6 | Descent / Approach | 185-202 / 203-211 |
| 4 | Advanced Flight Planning（pilot-defined waypoints、conditional waypoints、holding、風） | 212-237 |
| 5 | Backup Functions（EFIS / EICAS control panel、standby navigation） | 238-254 |
| 6 | FMS-MCDU Messages | 255-260 |
| 7 | Additional Information（cost index、maintenance pages） | 261-269 |
| 8 | ATS Data Link（ADS、ATC index / uplink / request / report / emergency / log） | 270-366 |
| 9 | Company Data Link | 367-383 |
| App. A / B / C | Index / Abbreviations / List of Illustrations | 384-401 / 402-407 / 408-415 |

## Lufthansa B1（LH24・LH36・LH3460）

| ID | ATA | 内容 | PDF p. |
|---|---|---|---|
| LH24 | 24-00 | General（負荷分配、電源の構成、ELEC synoptic） | 3-49 |
| LH24 | 24-10 | Generator Drive（IDG） | 50-91 |
| LH24 | 24-20 | AC Generation（GCU、BTB、split system breaker など） | 92-161 |
| LH24 | 24-30 | DC Generation（TRU、バッテリー、充電器） | 162-213 |
| LH24 | 24-40 | External Power | 214-225 |
| LH24 | 24-50 | Electrical Load Distribution（バス、ground handling / ground service bus） | 226-256 |
| LH36 | 36-00 | General（ASCTU を含む） | 3-27 |
| LH36 | 36-10 | Distribution（エンジン抽気、PRV、HPSOV、precooler、manifold、isolation valve） | 28-93 |
| LH36 | 36-20 | Indication / Ground Test | 94-105 |
| LH36 | 30-xx | Ice Detection / Wing Thermal Anti-Ice | 106-129 |
| LH36 | — | 系統図と図の一覧 | 130-138 |
| LH3460 | 34-61 | Flight Management Computer System | 3-129 |
| LH3460 | — | 資格・図の一覧 | 130-136 |

## E&M 整備訓練マニュアル（ATA 章別）

各巻の p.1-2 は表紙。各小章の先頭ページに、その小章の目次（題目と小章内のページ番号）がある。

| ID | PDF p. | ATA | 章 / 小章 |
|---|---|---|---|
| ATA21 | 3-30 | 21-00 | ENVIRONMENTAL CONTROL SYSTEM / Airconditioning |
| ATA21 | 31-114 | 21-50 | ENVIRONMENTAL CONTROL SYSTEM / Cooling |
| ATA21 | 115-204 | 21-20 | ENVIRONMENTAL CONTROL SYSTEM / Distribution |
| ATA21 | 205-214 | 21-23 | ENVIRONMENTAL CONTROL SYSTEM / Main Deck Cargo Compartment Flapper Valves |
| ATA21 | 215-228 | 21-29 | ENVIRONMENTAL CONTROL SYSTEM / Overhead Crewrest |
| ATA21 | 229-258 | 21-40 | ENVIRONMENTAL CONTROL SYSTEM / Cargo Heating |
| ATA21 | 259-336 | 21-27 | ENVIRONMENTAL CONTROL SYSTEM / Forward Cargo Air Conditioning |
| ATA21 | 337-392 | 21-60 | ENVIRONMENTAL CONTROL SYSTEM / Temperature Control |
| ATA21 | 393-484 | 21-30 | ENVIRONMENTAL CONTROL SYSTEM / Pressurization |
| ATA21 | 485-616 | 21-58 | ENVIRONMENTAL CONTROL SYSTEM / Equipment Cooling |
| ATA22 | 3-48 | 22-00 | AUTOPILOT/FLIGHT DIRECTOR SYSTEM / General |
| ATA22 | 49-100 | 22-21 | AUTOPILOT/FLIGHT DIRECTOR SYSTEM / Yaw Damper |
| ATA22 | 101-174 | 22-22 | AUTOPILOT/FLIGHT DIRECTOR SYSTEM / Automatic Stabilizer Trim |
| ATA22 | 175-300 | 22-10 | AUTOPILOT/FLIGHT DIRECTOR SYSTEM / AFDS General |
| ATA22 | 301-326 | 22-11 | AUTOPILOT/FLIGHT DIRECTOR SYSTEM / Engage Interlocks |
| ATA22 | 327-364 | 22-12 | AUTOPILOT/FLIGHT DIRECTOR SYSTEM / Control |
| ATA22 | 365-408 | 22-14 | AUTOPILOT/FLIGHT DIRECTOR SYSTEM / Annunciations and Warnings |
| ATA23 | 3-80 | 23-51 | COMMUNICATION / Flight Interphone System |
| ATA23 | 81-100 | 23-41 | COMMUNICATION / Service Interphone System |
| ATA23 | 101-126 | 23-28 | COMMUNICATION / SELCAL |
| ATA23 | 127-164 | 23-30 | COMMUNICATION / ACESS Introduction |
| ATA23 | 165-284 | 23-42 | COMMUNICATION / Cabin Interphone System |
| ATA23 | 285-386 | 23-31 | COMMUNICATION / Passenger Address System |
| ATA23 | 387-460 | 23-34 | COMMUNICATION / Passenger Entertainment System (Audio Economy Class) |
| ATA23 | 461-542 | 23-32 | COMMUNICATION / Overhead Video System |
| ATA23 | 543-608 | 23-32 | COMMUNICATION / Passenger Entertainment System (Business Class) |
| ATA23 | 609-702 | 23-33 | COMMUNICATION / Passenger Service System |
| ATA26_28 | 3-16 | 26-00 | FIRE PROTECTION / General |
| ATA26_28 | 17-58 | 26-11 | FIRE PROTECTION / Engine Overheat and Fire Protection |
| ATA26_28 | 59-84 | 26-21 | FIRE PROTECTION / Engine Fire Extinguishing |
| ATA26_28 | 85-112 | 26-15 | FIRE PROTECTION / APU Fire Detection |
| ATA26_28 | 113-136 | 26-22 | FIRE PROTECTION / APU Fire Extinguishing |
| ATA26_28 | 137-166 | 26-16 | FIRE PROTECTION / Cargo Compartment Smoke Detection |
| ATA26_28 | 167-200 | 26-23 | FIRE PROTECTION / Cargo Fire Extinguishing |
| ATA26_28 | 201-232 | 26-14 | FIRE PROTECTION / Main Deck Cargo Compartment Smoke Detection System |
| ATA26_28 | 233-266 | 26-24 | FIRE PROTECTION / Main Deck Cargo Fire Extinguishing |
| ATA26_28 | 267-276 | 26-17 | FIRE PROTECTION / Wheel Well Fire Detection |
| ATA26_28 | 277-288 | 26-18 | FIRE PROTECTION / Wing Leading Edge Overheat Detection |
| ATA26_28 | 289-298 | 26-13 | FIRE PROTECTION / Smoke Detection |
| ATA26_28 | 299-304 | 26-27 | FIRE PROTECTION / Lavatory Fire Protection |
| ATA26_28 | 305-310 | 26-12 | FIRE PROTECTION / Crew Rest Smoke Detection |
| ATA26_28 | 311-324 | 26-14 | FIRE PROTECTION / Overhead Crew Rest Smoke Detection |
| ATA26_28 | 327-348 | 28-00 | FUEL / Introduction |
| ATA26_28 | 349-382 | 28-21 | FUEL / Fueling System |
| ATA26_28 | 383-436 | 28-41 | FUEL / Fuel Quantity Indicating System |
| ATA26_28 | 437-446 | 28-26 | FUEL / Defueling and Check Valve Assembly |
| ATA26_28 | 447-468 | 28-22 | FUEL / Engine Fuel Feed System |
| ATA26_28 | 469-482 | 28-25 | FUEL / APU Fuel Feed System |
| ATA26_28 | 483-504 | 28-16 | FUEL / Reserve and Main Tank Interconnection |
| ATA26_28 | 505-514 | 28-15 | FUEL / Center Wing Tank Scavenge System |
| ATA26_28 | 515-548 | 28-31 | FUEL / Fuel Jettison System |
| ATA26_28 | 549-566 | ? | FUEL / Summary |
| ATA27 | 3-48 | 27-00 | FLIGHT CONTROLS / Introduction |
| ATA27 | 49-136 | 27-10 | FLIGHT CONTROLS / Ailerons |
| ATA27 | 137-210 | 27-60 | FLIGHT CONTROLS / Spoilers |
| ATA27 | 211-340 | 27-50 | FLIGHT CONTROLS / Flaps |
| ATA27 | 341-414 | 27-80 | FLIGHT CONTROLS / Lift Augmenting |
| ATA27 | 415-524 | 27-40 | FLIGHT CONTROLS / Stabilizer |
| ATA27 | 525-590 | 27-30 | FLIGHT CONTROLS / Elevator |
| ATA27 | 591-688 | 27-20 | FLIGHT CONTROLS / Rudder |
| ATA27 | 689-714 | 27-32 | FLIGHT CONTROLS / Stall Warning System |
| ATA27 | 715-748 | 27-90 | FLIGHT CONTROLS / Configuration Warning System |
| ATA29_32 | 3-144 | 29 | HYDRAULICS / — |
| ATA29_32 | 147-290 | 32-00 | LANDING GEAR / Landing Gear Structures |
| ATA29_32 | 291-342 | 32-09 | LANDING GEAR / Air/Ground relay-PSEU Systems |
| ATA29_32 | 343-380 | 32-40 | LANDING GEAR / Wheels and Brakes |
| ATA29_32 | 381-442 | 32-41 | LANDING GEAR / Hydraulic Brakes |
| ATA29_32 | 443-496 | 32-42 | LANDING GEAR / Brake Control System |
| ATA29_32 | 497-564 | 32-42 | LANDING GEAR / Autobrake System |
| ATA29_32 | 565-634 | 32-50 | LANDING GEAR / Landing Gear Steering |
| ATA29_32 | 635-674 | 32-61 | LANDING GEAR / Landing Gear Position Indication & Warning |
| ATA30_32_35_36 | 3-34 | 36-00 | PNEUMATIC / Introduction |
| ATA30_32_35_36 | 35-118 | 36-10 | PNEUMATIC / Engine Bleed Air |
| ATA30_32_35_36 | 119-148 | 36-20 | PNEUMATIC / Engine Bleed Air Press Indication |
| ATA30_32_35_36 | 151-308 | 30-00 | ICE AND RAIN PROTECTION / — |
| ATA30_32_35_36 | 311-386 | 35-00 | OXYGEN / — |
| ATA31 | 3-58 | 31-62 | INDICATING/RECORDING SYSTEMS / Electronic Flight Instrument System |
| ATA31 | 59-82 | 31-25 | INDICATING/RECORDING SYSTEMS / Clocks |
| ATA31 | 83-274 | 31-51 | INDICATING/RECORDING SYSTEMS / Aural Warning System |
| ATA31 | 275-334 | 31-31 | INDICATING/RECORDING SYSTEMS / Flight Data Recorder System |
| ATA31 | 335-408 | 31-35 | INDICATING/RECORDING SYSTEMS / Airplane Condition and Monitoring System |
| ATA31 | 409-564 | 31-41 | INDICATING/RECORDING SYSTEMS / Weight & Balance System |
| ATA33 | 3-362 | 33 | LIGHTS / — |
| ATA34_1 | 3-32 | 20-11 | DIGITAL SYSTEMS / Digital Systems |
| ATA34_1 | 33-70 | 34-11 | NAVIGATION / Pitot/Static System |
| ATA34_1 | 71-82 | 34-13 | NAVIGATION / Standby Air Data Instruments |
| ATA34_1 | 83-168 | 34-12 | NAVIGATION / Air Data Computer System |
| ATA34_1 | 169-200 | 34-16 | NAVIGATION / Altitude Alert System |
| ATA34_1 | 201-274 | 34-43 | NAVIGATION / Weather Radar System |
| ATA34_1 | 275-322 | 34-57 | NAVIGATION / Automatic Direction Finder System |
| ATA34_1 | 323-386 | 34-51 | NAVIGATION / VOR Navigation System |
| ATA34_1 | 387-422 | 34-32 | NAVIGATION / Marker Beacon System |
| ATA34_1 | 423-512 | 34-31 | NAVIGATION / Instrument Landing System |
| ATA34_1 | 513-572 | 34-55 | NAVIGATION / Distance Measuring Equipment |
| ATA34_1 | 573-646 | 34-53 | NAVIGATION / Air Traffic Control |
| ATA34_2 | 3-68 | 34-45 | NAVIGATION / TCAS |
| ATA34_2 | 69-110 | 34-33 | NAVIGATION / Radio Altimeter System |
| ATA34_2 | 111-240 | 34-46 | NAVIGATION / Ground Proximity Warning System |
| ATA34_2 | 241-256 | 34-24 | NAVIGATION / Standby Attitude Reference System |
| ATA34_2 | 257-262 | 34-22 | NAVIGATION / Standby Magnetic Compass |
| ATA34_2 | 263-374 | 34-21 | NAVIGATION / Inertial Reference System |
| ATA34_2 | 375-426 | 34-58 | NAVIGATION / Global Positioning System |
| ATA34_2 | 427-736 | 34-61 | NAVIGATION / Flight Management Computer System |
| ATA38_51_52_56 | 3-134 | 38-00 | WATER AND WASTE / — |
| ATA38_51_52_56 | 137-206 | 51-00 | STRUCTURES / — |
| ATA38_51_52_56 | 209-564 | 52-00 | DOORS / — |
| ATA38_51_52_56 | 567-614 | 56-00 | WINDOWS / — |
| ATA70_80 | 3-64 | 71-00 | POWERPLANT / General |
| ATA70_80 | 65-102 | 72-00 | POWERPLANT / Engine |
| ATA70_80 | 103-248 | 73-00 | POWERPLANT / Engine fuel & control |
| ATA70_80 | 249-272 | 74-00 | POWERPLANT / Ignition |
| ATA70_80 | 273-316 | 75-00 | POWERPLANT / Air |
| ATA70_80 | 317-396 | 77-00 | POWERPLANT / Engine Indicating |
| ATA70_80 | 397-482 | 78-00 | POWERPLANT / Exhaust |
| ATA70_80 | 483-530 | 79-00 | POWERPLANT / Oil |
| ATA70_80 | 531-576 | 80-00 | POWERPLANT / Engine start system operation and interface |
