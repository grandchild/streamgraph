echo ::: Generating Installation LaTeX PDF
pandoc -f markdown -V geometry="margin=2cm" -V colorlinks -t latex --latex-engine=xelatex -o Install.pdf Install.md

echo ::: Generating Perl module documentation
pod/mkpodmod.sh

echo ::: Generating streamgraph.pl documentation
echo TODO

