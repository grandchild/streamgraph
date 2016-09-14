
dir=$(realpath $(dirname "$0"))
sourcepath="$dir/../../source/lib/"

if [[ $# -eq 0 ]]; then
	for pm in $(find $sourcepath -name "*.pm") ; do
		pm=${pm#$sourcepath}
		pm=${pm%.pm}
		$dir/mkpodmod.sh $pm
	done
else
	subdir=$(dirname $1)
	docdir="$dir/$subdir"
	modpath="$sourcepath/$1.pm"

	if [ -e "$modpath" ]; then
		cd $dir
		mkdir -p $dir/$subdir
		pod2texi --unnumbered-sections "$modpath" > "$1.texi" || echo "Error creating TexInfo"
		sed -i"" '/@node Top/d' "$1.texi"
		sed -i"" '/@top StreamGraph::.*/d' "$1.texi"
		texi2pdf "$1.texi" -o "$1.pdf" &> /dev/null || echo "Error creating PDF"
		echo "$1.pdf"
	else
		echo No module $modpath!
	fi
fi
