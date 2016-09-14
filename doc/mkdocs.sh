dir=$(realpath $(dirname "$0"))
cd $dir

echo ::: Generating Installation LaTeX PDF
pandoc -f markdown -V geometry="margin=2cm" -V colorlinks -t latex --latex-engine=xelatex -o Install.pdf Install.md

if [[ "$1" != "nopods" ]]; then
echo ::: Generating Perl module documentation
pod/mkpodmod.sh
fi

echo ::: Generating streamgraph.pl documentation
outfilename="streamgraph_pl"
pod2texi --unnumbered-sections "../source/bin/streamgraph.pl" > "$outfilename.texi" || echo "Error creating TexInfo"
sed -i"" '/@node Top/d' "$outfilename.texi"
sed -i"" '/@top streamgraph.pl/d' "$outfilename.texi"
texi2pdf -b "$outfilename.texi" -o "$outfilename.pdf" &> /dev/null || echo "Error creating PDF"
rm $outfilename.{aux,toc,log,texi}
echo $outfilename.pdf

echo ::: Generating main Documentation PDF
pdflatex -synctex=1 -interaction=nonstopmode Documentation.tex &> /dev/null || echo "Error creating PDF"
pdflatex -synctex=1 -interaction=nonstopmode Documentation.tex &> /dev/null || echo "Error creating PDF"
echo Documentation.pdf
