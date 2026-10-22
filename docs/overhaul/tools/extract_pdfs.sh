#!/usr/bin/env bash
# Dump every reference PDF in _ref/ to text, one file per page plus one
# whole-document file with page markers, and a per-page stats table.
#   usage: docs/overhaul/tools/extract_pdfs.sh "<aircraft dir>"   (Git Bash; uses Git for Windows' xpdf pdftotext)
set -u
AC="$1"
REF="$AC/_ref"
OUT="$REF/text"
PDFTOTEXT=/ucrt64/bin/pdftotext
mkdir -p "$OUT"

# ID <TAB> file name
cat > "$OUT/SOURCES.tsv" <<'EOF'
id	file
FCOM	Boeing 747-400 Flight Crew Operations Manual by The Boeing Company.pdf
FCTM	747-400_FCTM.pdf
FMSPG	860089957-Fmc-Pilots-Guide.pdf
LH24	468095365-b744pw-24-b1-pdf.pdf
LH36	468095229-b744-pw-36-b1-pdf.pdf
LH3460	468094743-b747-4-34-60-b1-e.pdf
ATA21	678024365-ATA-21-03-00.pdf
ATA22	678024367-ATA-22-03-00.pdf
ATA23	678024369-ATA-23-1-03-01.pdf
ATA26_28	678024994-ATA-26-et-28.pdf
ATA27	678038267-ATA-27-03-00.pdf
ATA29_32	678038262-ATA-29-et-32.pdf
ATA30_32_35_36	678038247-ATA-30-32-35-et-36.pdf
ATA31	678038249-ATA-31-03-01.pdf
ATA33	678038242-ATA-33-03-00.pdf
ATA34_1	678031596-ATA-34-1-03-01.pdf
ATA34_2	678031603-ATA-34-2-03-01.pdf
ATA38_51_52_56	678025063-ATA-38-51-52-et-56.pdf
ATA70_80	678025050-ATA-70-80-03-00.pdf
EOF

tail -n +2 "$OUT/SOURCES.tsv" | while IFS=$'\t' read -r id file; do
    pdf="$REF/$file"
    [ -f "$pdf" ] || { echo "MISSING $file"; continue; }
    raw="$OUT/$id.raw"
    "$PDFTOTEXT" -q -layout -enc UTF-8 -eol unix "$pdf" "$raw"
    rm -rf "$OUT/$id"
    mkdir -p "$OUT/$id"
    # Pages are separated by form feeds. Write p0001.txt..., the whole file
    # with a marker line per page, and stats: page, non-blank chars, first
    # and last non-blank lines (headers/footers carry the page labels).
    LC_ALL=C.UTF-8 awk -v id="$id" -v dir="$OUT/$id" -v whole="$OUT/$id.txt" \
        -v stats="$OUT/$id.pages.tsv" '
        BEGIN { RS = "\f"; printf "" > whole; print "page\tchars\tfirst_line\tlast_line" > stats }
        {
            n = NR
            if (n > 1 && $0 == "" ) { }   # trailing empty record after last FF
            f = sprintf("%s/p%04d.txt", dir, n)
            printf "%s", $0 > f
            close(f)
            printf "==== [%s p.%d] ====\n%s\n", id, n, $0 >> whole
            t = $0; gsub(/[ \t\r\n]/, "", t)
            m = split($0, L, "\n"); first = ""; last = ""
            for (i = 1; i <= m; i++) { s = L[i]; gsub(/^[ \t]+|[ \t]+$/, "", s); if (s != "") { if (first == "") first = s; last = s } }
            gsub(/\t/, " ", first); gsub(/\t/, " ", last)
            print n "\t" length(t) "\t" substr(first, 1, 120) "\t" substr(last, 1, 120) >> stats
        }' "$raw"
    # The record after the final form feed is empty: drop it.
    lastp=$(ls "$OUT/$id" | tail -1)
    if [ ! -s "$OUT/$id/$lastp" ]; then
        rm -f "$OUT/$id/$lastp"
        sed -i '$d' "$OUT/$id.pages.tsv"
        # remove the trailing marker of the empty page from the whole file
        n=$(grep -n "^==== \[$id p\." "$OUT/$id.txt" | tail -1 | cut -d: -f1)
        head -n $((n - 1)) "$OUT/$id.txt" > "$OUT/$id.txt.tmp" && mv "$OUT/$id.txt.tmp" "$OUT/$id.txt"
    fi
    rm -f "$raw"
    pages=$(ls "$OUT/$id" | wc -l)
    low=$(awk -F'\t' 'NR > 1 && $2 < 400' "$OUT/$id.pages.tsv" | wc -l)
    echo "$id	pages=$pages	lowtext(<400 chars)=$low"
done
