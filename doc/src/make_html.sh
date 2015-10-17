#!/bin/sh
set -x

name=book
topicname=scaling
CHAPTER=chapter
BOOK=book
APPENDIX=appendix

function system {
  "$@"
  if [ $? -ne 0 ]; then
    echo "make.sh: unsuccessful command $@"
    echo "abort!"
    exit 1
  fi
}

pwd
preprocess -DFORMAT=html newcommands_keep.p.tex > newcommands_keep.tex

opt="CHAPTER=$CHAPTER BOOK=$BOOK APPENDIX=$APPENDIX --allow_refs_to_external_docs"

# Compile Bootstrap HTML
html=${topicname}-book
system doconce format html $name $opt --html_style=bootswatch_readable --html_code_style=inherit --html_output=$html --without_solutions --without_answers
system doconce split_html $html.html

hash=82dee82e1274a586571086dca04d00308d3a0d86  # "book with solutions"
# Compile Bootstrap HTML with solutions
html=.trash${hash}
system doconce format html $name $opt --html_style=bootswatch_readable --html_code_style=inherit --html_output=$html #--without_solutions --without_answers
system doconce split_html $html.html
cp password.html ${topicname}-book-sol.html
doconce replace DESTINATION "$html" ${topicname}-book-sol.html
doconce replace PASSWORD "d!e!cay" ${topicname}-book-sol.html

# Compile solarized HTML
html=${topicname}-book-solarized
system doconce format html $name $opt --html_style=solarized3 --html_output=$html --without_solutions --without_answers
system doconce split_html $html.html --nav_button=text

# Compile standard sphinx
theme=cbc
system doconce format sphinx $name $opt --sphinx_keep_splits --without_solutions --without_answers
system doconce split_rst $name
system doconce sphinx_dir theme=$theme dirname=sphinx-${theme} $name
system python automake_sphinx.py

# Publish
repo=../pub
dest=${repo}/book
if [ ! -d $dest ]; then mkdir $dest; fi
if [ ! -d $dest/html ]; then mkdir $dest/html; fi
if [ ! -d $dest/sphinx ]; then mkdir $dest/sphinx; fi

cp *book*.html ._*book*.html .*trash*.html $dest/html
figdirs="fig-* mov-*"
for figdir in $figdirs; do
    # slash important for copying files in links to dirs
    if [ -d $figdir/ ]; then
        cp -r $figdir/ $dest/html
    fi
done
rm -rf ${dest}/sphinx
cp -r sphinx-${theme}/_build/html ${dest}/sphinx

cd $dest
git add .
