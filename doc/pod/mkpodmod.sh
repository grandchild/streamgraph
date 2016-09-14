
dir=$(realpath $(dirname "$0"))
cd $dir
sourcepath="../../source/lib/"

if [[ $# -eq 0 ]]; then
	filecmd="find $sourcepath -name *.pm -not ( -path *View/Border* -o -path *View/Content* -o -path *View/HotSpot* )"
	total=$($filecmd | wc -l)
	echo -n [ ;	printf '%0.s ' $(seq 1 $total) ; echo -en "] $total\r" ; echo -en "["
	for pm in $($filecmd) ; do
		pm=${pm#$sourcepath}
		pm=${pm%.pm}
		./mkpodmod.sh $pm
		echo -n =
	done
	echo -en "\r"
	printf '%0.s ' $(seq 0 $total)
	echo -en "      \r"
else
	subdir=$(dirname $1)
	docdir="$subdir"
	modpath="$sourcepath/$1.pm"

	if [ -e "$modpath" ]; then
		mkdir -p $subdir
		pod2texi --unnumbered-sections "$modpath" > "$1.texi" || echo "Error creating TexInfo $1.texi"
		sed -i"" '/@node Top/d' "$1.texi"
		sed -i"" '/@top StreamGraph::.*/d' "$1.texi"
		texi2pdf -b "$1.texi" -o "$1.pdf" &> /dev/null || echo "Error creating PDF $1.pdf"
		# echo "$1.pdf"
	else
		echo No module $modpath!
	fi
fi
