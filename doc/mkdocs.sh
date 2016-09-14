dir=$(realpath $(dirname "$0"))

echo ::: Generating Installation LaTeX PDF
pandoc -f markdown -V geometry="margin=2cm" -V colorlinks -t latex --latex-engine=xelatex -o $dir/Install.pdf $dir/Install.md

echo ::: Generating Perl module documentation
$dir/pod/mkpodmod.sh

echo ::: Generating streamgraph.pl documentation
echo TODO

echo ::: Generating main Documentation PDF
pdflatex -synctex=1 -interaction=nonstopmode $dir/Documentation.tex

