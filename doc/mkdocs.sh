dir=$(realpath $(dirname "$0"))
cd $dir

echo ::: Generating Installation LaTeX PDF
echo -e "\pagenumbering{gobble}\n" | cat - Install.md |\
	pandoc -f markdown -V geometry="margin=2cm" -V colorlinks -t latex --latex-engine=xelatex -o Install.pdf

if [[ "$1" != "nopods" ]]; then

echo ::: Generating Perl module documentation \(pass \'nopods\' to skip\)
pod/mkpodmod.sh

outfilename="streamgraph_pl"
pod2texi --unnumbered-sections "../source/bin/streamgraph.pl" > "$outfilename.texi" || echo "Error creating TexInfo"
sed -i"" '/@node Top/d' "$outfilename.texi"
sed -i"" '/@top streamgraph.pl/d' "$outfilename.texi"
texi2pdf -b "$outfilename.texi" -o "$outfilename.pdf" &> /dev/null || echo "Error creating PDF"
rm $outfilename.{aux,toc,log,texi}

fi

echo ::: Generating main Documentation PDF
pdflatex -synctex=1 -interaction=nonstopmode Documentation.tex &> /dev/null || echo "Error creating PDF"
pdflatex -synctex=1 -interaction=nonstopmode Documentation.tex &> /dev/null || echo "Error creating PDF"
