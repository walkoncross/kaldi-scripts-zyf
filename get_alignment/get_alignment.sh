#!/bin/bash
#
# Copyright Johns Hopkins University (Author: Daniel Povey) 2016.  Apache 2.0.

# This script does the same type of diagnostics as analyze_alignments.sh, except
# it starts from lattices (so it has to convert the lattices to alignments
# first).

# begin configuration section.
iter=final
cmd=run.pl
acwt=0.1
#end configuration section.

echo "$0 $@"  # Print the command line for logging

[ -f ./path.sh ] && . ./path.sh
. parse_options.sh || exit 1;

if [ $# -ne 2 ]; then
  echo "Usage: $0 [options] (<lang-dir>|<graph-dir>) <decode-dir>"
  echo " Options:"
  echo "    --cmd (run.pl|queue.pl...)      # specify how to run the sub-processes."
  echo "    --acwt <acoustic-scale>         # Acoustic scale for getting best-path (default: 0.1)"
  echo "e.g.:"
  echo "$0 data/lang exp/tri4b/decode_dev"
  echo "This script writes some diagnostics to <decode-dir>/log/alignments.log"
  exit 1;
fi

lang=$1
dir=$2

model=$dir/../${iter}.mdl

for f in $lang/phones/align_lexicon.int $lang/words.txt $model $dir/lat.1.gz $dir/num_jobs; do
  [ ! -f $f ] && echo "$0: expecting file $f to exist" && exit 1;
done

num_jobs=$(cat $dir/num_jobs) || exit 1

mkdir -p $dir/log

$cmd JOB=1:$num_jobs $dir/log/lattice_to_get_word_ali.JOB.log \
  lattice-1best --acoustic-scale=$acwt "ark:gunzip -c $dir/lat.JOB.gz|"  ark:- \| \
  lattice-align-words-lexicon "$lang/phones/align_lexicon.int" "$model" ark:- ark:- \| \
  nbest-to-ctm ark:- $dir/JOB.word.ctm || exit 1

echo "$0: see align of word in $dir/word.ctm"

$cmd JOB=1:$num_jobs $dir/log/lattice_to_get_phone_ali.JOB.log \
  lattice-1best --acoustic-scale=$acwt "ark:gunzip -c $dir/lat.JOB.gz|"  ark:- \| \
  lattice-align-phones --replace-output-symbols=true "$model" ark:- ark:- \| \
  nbest-to-ctm ark:- $dir/JOB.phone.ctm || exit 1

echo "$0: see align of phone in $dir/phone.ctm"

exit 0
