today=`date '+%Y/%m/%d %H:%M'`;
versionid="XP12-30-$today";
versionline="fmcVersion=\"$versionid\"";
echo $versionline >> plugins/xtlua/scripts/B747.05.xt.simconfig/version.lua
pandoc --pdf-engine=xelatex -o README.pdf README.md
git add --all
