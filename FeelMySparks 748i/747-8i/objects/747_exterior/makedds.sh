for f in *.png
do
	filename="HELLO.png"
	#cho  "\"${f%.*}\""
	./DDSTool --png2dxt --std_mips --gamma_22 --scale_none "/media/storage2/X-Plane 11/XP11.50/X-Plane 11/Aircraft/wip/YA747/747-400/objects/747_exterior/$f" "/media/storage2/X-Plane 11/XP11.50/X-Plane 11/Aircraft/wip/YA747/747-400/objects/747_exterior/${f%.*}.dds"

done
