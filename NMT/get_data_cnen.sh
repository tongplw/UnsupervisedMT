# Copyright (c) 2018-present, Facebook, Inc.
# All rights reserved.
#
# This source code is licensed under the license found in the
# LICENSE file in the root directory of this source tree.
#

set -e

#
# Data preprocessing configuration
#

N_MONO=100000  # number of monolingual sentences for each language
CODES=60000      # number of BPE codes
N_THREADS=48     # number of threads in data preprocessing
N_EPOCHS=10      # number of fastText epochs


#
# Initialize tools and data paths
#

# main paths
UMT_PATH=$PWD
TOOLS_PATH=$PWD/tools
DATA_PATH=$PWD/data
MONO_PATH=$DATA_PATH/mono
PARA_PATH=$DATA_PATH/para

# create paths
mkdir -p $TOOLS_PATH
mkdir -p $DATA_PATH
mkdir -p $MONO_PATH
mkdir -p $PARA_PATH

# moses
MOSES=$TOOLS_PATH/mosesdecoder
TOKENIZER=$MOSES/scripts/tokenizer/tokenizer.perl
NORM_PUNC=$MOSES/scripts/tokenizer/normalize-punctuation.perl
INPUT_FROM_SGM=$MOSES/scripts/ems/support/input-from-sgm.perl
REM_NON_PRINT_CHAR=$MOSES/scripts/tokenizer/remove-non-printing-char.perl

# fastBPE
FASTBPE_DIR=$TOOLS_PATH/fastBPE
FASTBPE=$FASTBPE_DIR/fast

# fastText
FASTTEXT_DIR=$TOOLS_PATH/fastText
FASTTEXT=$FASTTEXT_DIR/fasttext

# muse
MUSE_DIR=$TOOLS_PATH/MUSE

# files full paths
SRC_RAW=$MONO_PATH/all.cn
TGT_RAW=$MONO_PATH/all.en
SRC_TOK=$MONO_PATH/all.cn.tok
TGT_TOK=$MONO_PATH/all.en.tok
BPE_CODES=$MONO_PATH/bpe_codes
CONCAT_BPE=$MONO_PATH/all.cn-en.$CODES
SRC_VOCAB=$MONO_PATH/vocab.cn.$CODES
TGT_VOCAB=$MONO_PATH/vocab.en.$CODES
FULL_VOCAB=$MONO_PATH/vocab.cn-en.$CODES
SRC_VALID=$PARA_PATH/dev.cn
TGT_VALID=$PARA_PATH/dev.en
SRC_TEST=$PARA_PATH/test.cn
TGT_TEST=$PARA_PATH/test.en
SRC_MON_EMB=$PARA_PATH/all_emb.cn
TGT_MON_EMB=$PARA_PATH/all_emb.en


#
# Download and install tools
#

# Download Moses
cd $TOOLS_PATH
if [ ! -d "$MOSES" ]; then
  echo "Cloning Moses from GitHub repository..."
  git clone --depth 1 https://github.com/moses-smt/mosesdecoder.git
fi
echo "Moses found in: $MOSES"

# Download fastBPE
cd $TOOLS_PATH
if [ ! -d "$FASTBPE_DIR" ]; then
  echo "Cloning fastBPE from GitHub repository..."
  git clone --depth 1 https://github.com/glample/fastBPE.git
fi
echo "fastBPE found in: $FASTBPE_DIR"

# Compile fastBPE
cd $TOOLS_PATH
if [ ! -f "$FASTBPE" ]; then
  echo "Compiling fastBPE..."
  cd $FASTBPE_DIR
  g++ -std=c++11 -pthread -O3 fastBPE/main.cc -IfastBPE -o fast
fi
echo "fastBPE compiled in: $FASTBPE"

# Download fastText
cd $TOOLS_PATH
if [ ! -d "$FASTTEXT_DIR" ]; then
  echo "Cloning fastText from GitHub repository..."
  git clone --depth 1 https://github.com/facebookresearch/fastText.git
fi
echo "fastText found in: $FASTTEXT_DIR"

# Compile fastText
cd $TOOLS_PATH
if [ ! -f "$FASTTEXT" ]; then
  echo "Compiling fastText..."
  cd $FASTTEXT_DIR
  make
fi
echo "fastText compiled in: $FASTTEXT"

# Download muse
cd $TOOLS_PATH
if [ ! -d "$MUSE_DIR" ]; then
  echo "Cloning muse from GitHub repository..."
  git clone --depth 1 https://github.com/facebookresearch/MUSE.git
fi
echo "muse found in: $MUSE_DIR"


#
# Download monolingual data
#

cd $MONO_PATH

# echo "Downloading English files..."
# wget -c http://www.statmt.org/wmt14/training-monolingual-news-crawl/news.2007.en.shuffled.gz
# wget -c http://www.statmt.org/wmt14/training-monolingual-news-crawl/news.2008.en.shuffled.gz
# wget -c http://www.statmt.org/wmt14/training-monolingual-news-crawl/news.2009.en.shuffled.gz
# wget -c http://www.statmt.org/wmt14/training-monolingual-news-crawl/news.2010.en.shuffled.gz
# wget -c http://www.statmt.org/wmt14/training-monolingual-news-crawl/news.2011.en.shuffled.gz
# wget -c http://www.statmt.org/wmt14/training-monolingual-news-crawl/news.2012.en.shuffled.gz
# wget -c http://www.statmt.org/wmt14/training-monolingual-news-crawl/news.2013.en.shuffled.gz
# wget -c http://www.statmt.org/wmt15/training-monolingual-news-crawl-v2/news.2014.en.shuffled.v2.gz
# wget -c http://data.statmt.org/wmt16/translation-task/news.2015.en.shuffled.gz
# wget -c http://data.statmt.org/wmt17/translation-task/news.2016.en.shuffled.gz
# wget -c http://data.statmt.org/wmt18/translation-task/news.2017.en.shuffled.deduped.gz

# echo "Downloading French files..."
# wget -c http://www.statmt.org/wmt14/training-monolingual-news-crawl/news.2007.fr.shuffled.gz
# wget -c http://www.statmt.org/wmt14/training-monolingual-news-crawl/news.2008.fr.shuffled.gz
# wget -c http://www.statmt.org/wmt14/training-monolingual-news-crawl/news.2009.fr.shuffled.gz
# wget -c http://www.statmt.org/wmt14/training-monolingual-news-crawl/news.2010.fr.shuffled.gz
# wget -c http://www.statmt.org/wmt14/training-monolingual-news-crawl/news.2011.fr.shuffled.gz
# wget -c http://www.statmt.org/wmt14/training-monolingual-news-crawl/news.2012.fr.shuffled.gz
# wget -c http://www.statmt.org/wmt14/training-monolingual-news-crawl/news.2013.fr.shuffled.gz
# wget -c http://www.statmt.org/wmt15/training-monolingual-news-crawl-v2/news.2014.fr.shuffled.v2.gz
# wget -c http://data.statmt.org/wmt17/translation-task/news.2015.fr.shuffled.gz
# wget -c http://data.statmt.org/wmt17/translation-task/news.2016.fr.shuffled.gz
# wget -c http://data.statmt.org/wmt17/translation-task/news.2017.fr.shuffled.gz

# # decompress monolingual data
# for FILENAME in news*gz; do
#   OUTPUT="${FILENAME::-3}"
#   if [ ! -f "$OUTPUT" ]; then
#     echo "Decompressing $FILENAME..."
#     gunzip -k $FILENAME
#   else
#     echo "$OUTPUT already decompressed."
#   fi
# done

# # concatenate monolingual data files
# if ! [[ -f "$SRC_RAW" && -f "$TGT_RAW" ]]; then
#   echo "Concatenating monolingual data..."
#   cat $(ls news*en* | grep -v gz) | head -n $N_MONO > $SRC_RAW
#   cat $(ls news*fr* | grep -v gz) | head -n $N_MONO > $TGT_RAW
# fi
# echo "EN monolingual data concatenated in: $SRC_RAW"
# echo "FR monolingual data concatenated in: $TGT_RAW"
if ! [[ -f "$SRC_RAW" && -f "$TGT_RAW" ]]; then
  curl https://raw.githubusercontent.com/tongplw/dummy/master/train.cn -o "$SRC_RAW"
  curl https://raw.githubusercontent.com/tongplw/dummy/master/train.en -o "$TGT_RAW"
fi
# check number of lines
# if ! [[ "$(wc -l < $SRC_RAW)" -eq "$N_MONO" ]]; then echo "ERROR: Number of lines doesn't match! Be sure you have $N_MONO sentences in your CN monolingual data."; exit; fi
# if ! [[ "$(wc -l < $TGT_RAW)" -eq "$N_MONO" ]]; then echo "ERROR: Number of lines doesn't match! Be sure you have $N_MONO sentences in your EN monolingual data."; exit; fi

# tokenize data
if ! [[ -f "$SRC_TOK" && -f "$TGT_TOK" ]]; then
  echo "Tokenize monolingual data..."
  cat $SRC_RAW | $NORM_PUNC -l zh | $TOKENIZER -l zh -no-escape -threads $N_THREADS > $SRC_TOK
  cat $TGT_RAW | $NORM_PUNC -l en | $TOKENIZER -l en -no-escape -threads $N_THREADS > $TGT_TOK
fi
echo "CN monolingual data tokenized in: $SRC_TOK"
echo "EN monolingual data tokenized in: $TGT_TOK"

# learn BPE codes
if [ ! -f "$BPE_CODES" ]; then
  echo "Learning BPE codes..."
  $FASTBPE learnbpe $CODES $SRC_TOK $TGT_TOK > $BPE_CODES
fi
echo "BPE learned in $BPE_CODES"

# apply BPE codes
if ! [[ -f "$SRC_TOK.$CODES" && -f "$TGT_TOK.$CODES" ]]; then
  echo "Applying BPE codes..."
  $FASTBPE applybpe $SRC_TOK.$CODES $SRC_TOK $BPE_CODES
  $FASTBPE applybpe $TGT_TOK.$CODES $TGT_TOK $BPE_CODES
fi
echo "BPE codes applied to CN in: $SRC_TOK.$CODES"
echo "BPE codes applied to EN in: $TGT_TOK.$CODES"

# extract vocabulary
if ! [[ -f "$SRC_VOCAB" && -f "$TGT_VOCAB" && -f "$FULL_VOCAB" ]]; then
  echo "Extracting vocabulary..."
  $FASTBPE getvocab $SRC_TOK.$CODES > $SRC_VOCAB
  $FASTBPE getvocab $TGT_TOK.$CODES > $TGT_VOCAB
  $FASTBPE getvocab $SRC_TOK.$CODES $TGT_TOK.$CODES > $FULL_VOCAB
fi
echo "CN vocab in: $SRC_VOCAB"
echo "EN vocab in: $TGT_VOCAB"
echo "Full vocab in: $FULL_VOCAB"

# binarize data
if ! [[ -f "$SRC_TOK.$CODES.pth" && -f "$TGT_TOK.$CODES.pth" ]]; then
  echo "Binarizing data..."
  $UMT_PATH/preprocess.py $FULL_VOCAB $SRC_TOK.$CODES
  $UMT_PATH/preprocess.py $FULL_VOCAB $TGT_TOK.$CODES
fi
echo "CN binarized data in: $SRC_TOK.$CODES.pth"
echo "EN binarized data in: $TGT_TOK.$CODES.pth"


#
# Download parallel data (for evaluation only)
#

cd $PARA_PATH

echo "Downloading parallel data..."
if ! [[ -f "$SRC_VALID" && -f "$TGT_VALID" && -f "$SRC_TEST" ]]; then
  curl https://raw.githubusercontent.com/tongplw/dummy/master/dev.cn -o "$SRC_VALID"
  curl https://raw.githubusercontent.com/tongplw/dummy/master/dev.en -o "$TGT_VALID"
  curl https://raw.githubusercontent.com/tongplw/dummy/master/test.cn -o "$SRC_TEST"
fi


cd $UMT_PATH

# check valid and test files are here
if ! [[ -f "$SRC_VALID" ]]; then echo "$SRC_VALID is not found!"; exit; fi
if ! [[ -f "$TGT_VALID" ]]; then echo "$TGT_VALID is not found!"; exit; fi
if ! [[ -f "$SRC_TEST" ]]; then echo "$SRC_TEST is not found!"; exit; fi
# if ! [[ -f "$TGT_TEST" ]]; then echo "$TGT_TEST is not found!"; exit; fi

echo "Tokenizing valid and test data..."
cat $SRC_VALID | $NORM_PUNC -l zh | $TOKENIZER -l zh -no-escape -threads $N_THREADS > $SRC_VALID.tok
cat $TGT_VALID | $NORM_PUNC -l en | $TOKENIZER -l en -no-escape -threads $N_THREADS > $TGT_VALID.tok
cat $SRC_TEST | $NORM_PUNC -l zh | $TOKENIZER -l zh -no-escape -threads $N_THREADS > $SRC_TEST.tok
# cat $TGT_TEST | $NORM_PUNC -l en | $TOKENIZER -l en -no-escape -threads $N_THREADS > $TGT_TEST


echo "Applying BPE to valid and test files..."
$FASTBPE applybpe $SRC_VALID.$CODES $SRC_VALID.tok $BPE_CODES $SRC_VOCAB
$FASTBPE applybpe $TGT_VALID.$CODES $TGT_VALID.tok $BPE_CODES $TGT_VOCAB
$FASTBPE applybpe $SRC_TEST.$CODES $SRC_TEST.tok $BPE_CODES $SRC_VOCAB
# $FASTBPE applybpe $TGT_TEST.$CODES $TGT_TEST $BPE_CODES $TGT_VOCAB

echo "Binarizing data..."
rm -f $SRC_VALID.$CODES.pth $TGT_VALID.$CODES.pth $SRC_TEST.$CODES.pth $TGT_TEST.$CODES.pth
python3 $UMT_PATH/preprocess.py $FULL_VOCAB $SRC_VALID.$CODES
python3 $UMT_PATH/preprocess.py $FULL_VOCAB $TGT_VALID.$CODES
python3 $UMT_PATH/preprocess.py $FULL_VOCAB $SRC_TEST.$CODES
# python3 $UMT_PATH/preprocess.py $FULL_VOCAB $TGT_TEST.$CODES


#
# Summary
#
echo ""
echo "===== Data summary"
echo "Monolingual training data:"
echo "    EN: $SRC_TOK.$CODES.pth"
echo "    FR: $TGT_TOK.$CODES.pth"
echo "Parallel validation data:"
echo "    EN: $SRC_VALID.$CODES.pth"
echo "    FR: $TGT_VALID.$CODES.pth"
echo "Parallel test data:"
echo "    EN: $SRC_TEST.$CODES.pth"
echo "    FR: $TGT_TEST.$CODES.pth"
echo ""


#
# Train fastText on concatenated embeddings
#

if ! [[ -f "$SRC_MON_EMB.vec" ]]; then
  echo "Training fastText on $SRC_MON_EMB..."
  $FASTTEXT skipgram -epoch $N_EPOCHS -minCount 0 -dim 512 -thread $N_THREADS -ws 5 -neg 10 -input $SRC_TOK.$CODES -output $SRC_MON_EMB
fi
echo "Monolingual embeddings in: $SRC_MON_EMB"

if ! [[ -f "$TGT_MON_EMB.vec" ]]; then
  echo "Training fastText on $TGT_MON_EMB..."
  $FASTTEXT skipgram -epoch $N_EPOCHS -minCount 0 -dim 512 -thread $N_THREADS -ws 5 -neg 10 -input $TGT_TOK.$CODES -output $TGT_MON_EMB
fi
echo "Monolingual embeddings in: $TGT_MON_EMB"

if ! [[ -f "$CONCAT_BPE" ]]; then
  echo "Aligning source and target monolingual embeddings..."
  python3 $MUSE_DIR/unsupervised.py --src_lang zh --tgt_lang en --src_emb $SRC_MON_EMB.vec --tgt_emb $TGT_MON_EMB.vec --n_refinement 5 --normalize_embeddings center --emb_dim 512
fi
echo "Cross-lingual embeddings in: $CONCAT_BPE.vec"