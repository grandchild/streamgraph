
dir=$(realpath $(dirname "$0"))
subdir=$(dirname $1)
docdir="$dir/$subdir"
modpath="$dir/../../source/lib/StreamGraph/$1.pm"

if [ -e "$modpath" ]; then
	cd $dir
	mkdir -p $dir/$subdir
	pod2texi "$modpath" > "$1.texi" || echo "Error creating TexInfo"
	texi2pdf "$1.texi" -o "$1.pdf" &> /dev/null || echo "Error creating PDF"
else
	echo No module $modpath!
fi
