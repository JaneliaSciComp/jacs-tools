#!/bin/bash
#
# fly alignment pipeline, version 1.0, 2013/2/15
#

################################################################################
#
# The pipeline is developed for aligning 20x fly (brain + VNC) and then
# rescaling the output back to itensity range of the original input
# Target brain's resolution (0.62x0.62x0.62 um)
#
################################################################################

DIR=$(cd "$(dirname "$0")"; pwd)
. $DIR/common.sh

CONFIGFILE=$DIR/systemvars.apconf
TOOLDIR="${TOOL_DIR:-/opt}"

YAML_FILE=$1
parseParameters "$@"

OUTPUT=${WORK_DIR}"/tmp"
FINALOUTPUT=${WORK_DIR}"/FinalOutputs"

echo "~ Executing flyalign20x_dpx_1024px_INT.sh"
$DIR/flyalign20x_dpx_1024px_INT.sh $YAML_FILE $WORK_DIR

FINAL_BRAIN="${FINALOUTPUT}/AlignedFlyBrain.v3dpbd"
FINAL_BRAIN_PROPS="${FINALOUTPUT}/AlignedFlyBrain.properties"

RESCALED_FILE="${FINALOUTPUT}/AlignedFlyBrainIntRescaled.v3dpbd"
RESCALED_FILE_PROPS="${FINALOUTPUT}/AlignedFlyBrainIntRescaled.properties"

echo "~ Rescaling intensity range"
$DIR/rescaleIntensityRange.sh -c $CONFIGFILE -k $TOOLDIR -w $OUTPUT -s $INPUT1_FILE -i $FINAL_BRAIN -o $RESCALED_FILE

echo "~ Replacing output with rescaled file"
sed -i 's/AlignedFlyBrain/AlignedFlyBrainIntRescaled/' $FINAL_BRAIN_PROPS
mv $FINAL_BRAIN_PROPS $RESCALED_FILE_PROPS
rm $FINAL_BRAIN

