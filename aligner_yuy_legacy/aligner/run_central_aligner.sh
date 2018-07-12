#!/bin/bash

#
# Currently this pipeline is broken because we don't have a working lobe_seger implementation
#

DIR=$(cd "$(dirname "$0")"; pwd)
. $DIR/common.sh

parseParameters "$@"

CONFIGFILE=$DIR/systemvars.apconf
TMPLDIR=$TEMPLATE_DIR
TOOLDIR=$TOOL_DIR
WORKDIR=$WORK_DIR
RESX=$INPUT1_RESX
RESY=$INPUT1_RESY
RESZ=$INPUT1_RESZ

Vaa3D=`readItemFromConf $CONFIGFILE "Vaa3D"`
JBA=`readItemFromConf $CONFIGFILE "JBA"`

Vaa3D=${TOOLDIR}"/"${Vaa3D}
JBA=${TOOLDIR}"/"${JBA}

message "Inputs..."
echo "CONFIGFILE: $CONFIGFILE"
echo "TMPLDIR: $TMPLDIR"
echo "TOOLDIR: $TOOLDIR"
echo "WORKDIR: $WORKDIR"
echo "INPUT1_FILE: $INPUT1_FILE"
echo "RESX: $RESX"
echo "RESY: $RESY"
echo "RESZ: $RESZ"
message "Vars..."
echo "Vaa3D: $Vaa3D"

OUTPUT=${WORKDIR}"/Outputs"
FINALOUTPUT=${WORKDIR}"/FinalOutputs"

if [ ! -d $OUTPUT ]; then
    mkdir $OUTPUT
fi

if [ ! -d $FINALOUTPUT ]; then
    mkdir $FINALOUTPUT
fi

/usr/local/bin/perl run_aligner.pl -v $Vaa3D -b $JBA -l $LobeSeger -t $TMPLDIR -w $OUTPUT -i $INPUT1_FILE -r "${RESX}x${RESY}x${RESZ}" -c $INPUT1_REF

ALIGNED=$FINALOUTPUT/AlignedFlyBrain.v3draw

#TODO: move output file


if [[ -f "$ALIGNED" ]]; then
META=${FINALOUTPUT}"/AlignedFlyBrain.properties"
echo "alignment.stack.filename=AlignedFlyBrain.v3draw" >> $META
echo "alignment.image.area=Brain" >> $META
echo "alignment.image.channels=$INPUT1_CHANNELS" >> $META
echo "alignment.image.refchan=$INPUT1_REF" >> $META
echo "alignment.space.name=$UNIFIED_SPACE" >> $META
echo "alignment.resolution.voxels=0.62x0.62x0.62" >> $META
echo "alignment.image.size=1024x512x218" >> $META
echo "alignment.objective=20x" >> $META
fi

compressAllRaw $Vaa3D $WORKDIR
