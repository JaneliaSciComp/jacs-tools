DIR=$(cd "$(dirname "$0")"; pwd)
NSLOTS=2
TOOLS_DIR=$1
CONTAINER=$2
OUT=$3
cd $OUT
B1=/groups/jacs/jacsDev/AlignTemplates/configured_templates
B2=/groups/jacs/jacsDev/devstore/testData
bsub -K -e $OUT/stderr.log -o $OUT/stdout.log -n $NSLOTS $TOOLS_DIR/scripts/testAligner.sh "singularity run -B $B1 -B $B2 --app align $CONTAINER" $NSLOTS $OUT $DIR/align.yml debug
