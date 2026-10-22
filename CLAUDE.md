# CLAUDE.md

Boeing 747-400（Sparky744）のシステムとアビオニクスを、実機にできるだけ忠実に作り直す作業のルール。報告は日本語で書く。

## このフォルダ

- X-Plane 12 の `Aircraft/747-400-master`。X-Plane 本体はこのフォルダの2つ上（`../../`）で、`Log.txt` もそこにある。
- 利用者のフォーク `Gakugaku87/747-400`（origin）の作業ツリー。本家 `mSparks43/747-400` を `upstream` として登録してある。
- ブランチ：
  - `overhaul`：作り直しの作業ブランチ。本家 master `041c9ffa` から作った。
  - `archive/old-master`：旧フォークの最終状態。参照専用。
  - `master`：旧フォーク。
- 3D モデル・テクスチャ・サウンドは対象外。
- 進み具合：`docs/overhaul/PROGRESS.md`。計画：`docs/overhaul/PLAN.md`。

## 資料

- PDF は `_ref/`（19 冊、約 1 万ページ）。`.git/info/exclude` で除外してあり、**どのブランチにもコミットしない**。
- テキストは `_ref/text/`。索引（資料 × 章 × PDF ページ）は `docs/overhaul/REFERENCE_INDEX.md`。
- `_ref/` は git の管理外なので、Grep ツールではパスを必ず明示する（例：`_ref/text/FCOM`）。
- 文字の少ないページは系統図が本体。`docs/overhaul/tools/render_pdf_pages.ps1 -Id <ID> -Pages <範囲>` で PNG にして読む（出力先は `_ref/text/img/`）。
- 系統ごとの要点：`docs/overhaul/notes/ATA-xx.md`。操縦技法と試験シナリオの基準：`docs/overhaul/notes/FCTM.md`。
- 資料の優先順位：
  - 乗員から見える挙動は FCOM、内部ロジックは整備マニュアル（`ATA*`、`LH*`）を優先する。迷ったら利用者に聞く。
  - FCTM と FCOM が食い違えば FCOM を優先する。
- APU は整備資料が無いので FCOM を基準にする。
- エンジン関連は型式に合う資料を使う。PW は FCOM・LH24・LH36、CF6 は FCOM・ATA70_80。RR には資料が無い。
- 資料の文章は長く転載しない。要約と出典（`FCOM p.801 (6.20.7)` の形）で書く。
- 資料に無いことは推測で作らない。やむを得ず推定で作る部分は、コードと PROGRESS.md に「推定」と明記する。

## acf

- 開発と試験の基準は、利用者のカスタム acf `747-400_custom.acf`（git 管理外）。
- 比較用の純正 acf は `747-400.acf`。**変更しない。**
  - 区切りごとに、純正 acf でも起動・電源投入・エンジン始動までの簡単な試験をする。
- 機体の設定（エンジン型式、タンク数など）は、カスタム acf の値を決め打ちせず dataref から読む。エンジン型式は `laminar/B747/engines/type`（リバリーごとの `B747-400_simconfig.dat` で決まる）。
- カスタム acf で変えてよいのは、重量・エンジン・空力・システムの設定だけ。
  - 見た目に関わる項目は変えない：オブジェクトの一覧と位置、ライト、視点、ギア・舵面・フラップの位置と角度、acf に埋め込まれたパネル計器。
  - どうしても必要なら、理由を示して承認を取る。
- カスタム acf を変えるときの手順：
  1. 変更前にバックアップを取る。
  2. 変えた項目を、変更前後の値つきで一覧にして報告する。
  3. 外から見たスクリーンショットで、見た目が変わっていないことを確かめる。
- 2 つの acf の違い：`docs/overhaul/ACF_DIFF.md`。

## ローカルの 3D 一式（コミットしない）

- 作業ツリーには、git に無い 3D 一式がある。
  - 72 ファイルは skip-worktree を付けてある（一覧：`git ls-files -v | grep "^S "`）。
  - 約 200 ファイルは未追跡。
  - バックアップは `D:\747-400-local-assets\`（README.txt を参照）。
- これらを `git add`・restore・checkout で上書きしない。ブランチの切り替えで衝突したら、止まって利用者に聞く。
- 旧フォークのコードはブランチを切り替えずに読む：`git show archive/old-master:<path>`。

## 実装のルール

- 実装は既存と同じ XTLua に統一する。XTLua 本体（`plugins/*/64/*.xpl`）には手を入れない。
- XLua 2.0 や C++ は、それを使うのが最善と判断できるなら採用してよい（2026-10-23 利用者の許可）。採用するときは、XTLua では足りない理由・代わりの案・影響を PROGRESS.md に書く。基本はシステムのロジックを XTLua に置き、受け渡しは dataref とコマンドで行う。
- 既存の構造は活かす。系統ごとに、部分修正より中身を作り直す方が早いなら、GAP_ANALYSIS.md でそう提案してよい。ただし実行は承認を取ってから。
- 作り直す場合も、3D コクピット・表示・サウンドが使っている dataref とコマンドの名前と意味は変えない（一覧：`docs/overhaul/INTERFACES.tsv`）。
- 毎フレームの処理を重くしない。
- 旧フォークの修正（`docs/overhaul/OLD_FORK_NOTES.md`、`archive/old-master`）は見るだけ。そのまま移植せず、資料に照らして作り直す。

## 進め方（フェーズ1以降）

承認された項目を1つずつ、次の順で進める。

1. 着手前に、変更方針を短く示す。
2. 実装する。
3. 構文チェックをする（`luajit -bl` か `luac -p`）。
4. `tests/` の回帰試験を回す（LuaJIT、X-Plane なし）。旧試験の仕組みを流用して、系統ごとに作る。
5. 飛行試験キットと Web API で X-Plane での試験をし、`Log.txt` のエラーも確認する。試験のやり方が分からなければ聞く。
6. 結果と、利用者が X-Plane で目視確認すべき点を報告する。
7. コミットする。
- 表示系（PFD・ND・EICAS・CDU）は自分で確かめる。
  - 中身（CDU の各行、EICAS メッセージ、FMA、速度など）は、X-Plane の Web API（localhost:8086）で dataref を読んで確かめる。CDU のキー操作もコマンドで行う。
  - 色・配置・記号は、視点を計器に寄せて X-Plane のスクリーンショットを撮り、画像を見て確かめる。
  - 自分で確かめられなかった点だけを、利用者の目視確認に回す。
- 1 コミット 1 テーマ。コミットメッセージに根拠（資料名とページ）を書く。
- `docs/overhaul/PROGRESS.md` を常に更新し、次のセッションが続きから再開できるようにする。

## 試験

- 試験の仕組みは `docs/overhaul/TESTING.md` にまとめてある。
- 旧フォークの試験は `tests_old/` に置いてある（`archive/old-master` の `tests/` と同じ）。
  - FlyWithLua ではなく、LuaJIT で X-Plane なしに回す回帰試験（本番の Lua をモックで読み込む）。
  - `.git/info/exclude` で管理外にしてある。旧フォークのコード向けなので、そのまま通す必要はない。
  - 流用するのは仕組み（モック、読み込み方、静的検査、記録データ `tests_old/data`、README の X-Plane での確認シナリオ）だけ。期待値は、資料と照らして使えるものだけを新しい試験に移す。
- 新しい回帰試験は `tests/`（git 管理）に、系統ごとに作る。LuaJIT が無ければ用意してよい（入手元を示す）。
- 飛行試験キットは新しく作る。
  - 中心は Web API（dataref の読み書き、コマンド、スクリーンショット）。毎フレームの精度が要る部分だけ FlyWithLua で補う。
  - 記録の列は `tests_old/data` の CSV に合わせる。
  - FlyWithLua のスクリプトは `../../Resources/plugins/FlyWithLua/Scripts/` に自分で置いてよい。置いたものは報告する。正本はリポジトリに置く。
  - キット作りは PLAN.md の最初の項目。系統の変更より先に完成させ、純正 acf とカスタム acf の両方で動くことを確かめる。

## git

- コミットは自分が変更したファイルだけを指定して行う。`git add -A` などで未追跡ファイルをまとめて入れない。
- `_ref/` は絶対にコミットしない。
- push は `archive/old-master` 以外、利用者が指示するまでしない。
- この PC には git の `user.name` と `user.email` が設定されていない。設定は変えず、旧フォークと同じ作者をコミットごとに渡す（`git -c user.name=... -c user.email=... commit`。値は `git log -1 --format='%an <%ae>' archive/old-master` で確かめる）。

## この PC の環境

- Windows 11。シェルは PowerShell と Git Bash。
- Python は入っていない。`python`・`py` を呼ぶと Windows の Python install manager が更新やダウンロードを始めるので、呼ばない。
- FlyWithLua NG+ 2.8.19 は利用者が導入済み（`../../Resources/plugins/FlyWithLua/`）。
- Lua（`luac`・`luajit`）は入っていない。PLAN の最初の項目で用意する。
- PDF のテキスト化には、Git for Windows 同梱の `pdftotext`（xpdf 4.06）を使う。
