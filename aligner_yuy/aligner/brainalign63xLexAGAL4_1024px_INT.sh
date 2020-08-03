#!/bin/bash
#
# fly brain alignment pipeline version 1.0, 2012/12/12
#

################################################################################
#
# The pipeline is developed for solving 63x fly brain alignment problems.
# Target brain's resolution (0.19x0.19x0.38 um)
#
################################################################################


##################
# Basic Funcs
##################

DIR=$(cd "$(dirname "$0")"; pwd)
. $DIR/common.sh


##################
# Inputs
##################
parseParameters "$@"
CONFIGFILE=$DIR/systemvars.apconf
TMPLDIR=$TEMPLATE_DIR
TOOLDIR="${TOOL_DIR:-/opt}"
WORKDIR=$WORK_DIR
SUB=$INPUT1_FILE
SUBREF=$INPUT1_REF
NEUBRAIN=$INPUT1_NEURONS
RESX=$INPUT1_RESX
RESY=$INPUT1_RESY
RESZ=$INPUT1_RESZ

# tools
Vaa3D=`readItemFromConf $CONFIGFILE "Vaa3D"`
JBA=`readItemFromConf $CONFIGFILE "JBA"`
ANTS=`readItemFromConf $CONFIGFILE "ANTS"`
WARP=`readItemFromConf $CONFIGFILE "WARP"`
SMPL=`readItemFromConf $CONFIGFILE "SMPL"`

Vaa3D=${TOOLDIR}"/"${Vaa3D}
JBA=${TOOLDIR}"/"${JBA}
ANTS=${TOOLDIR}"/"${ANTS}
WARP=${TOOLDIR}"/"${WARP}
SMPL=${TOOLDIR}"/"${SMPL}

# templates
TAR=`readItemFromConf $CONFIGFILE "tgtFBSXAS"`
TARREF=`readItemFromConf $CONFIGFILE "REFNO"`
ATLAS=`readItemFromConf $CONFIGFILE "atlasFBTX"`
RES_X=`readItemFromConf $CONFIGFILE "VSZX_63X_AS"`
RES_Y=`readItemFromConf $CONFIGFILE "VSZY_63X_AS"`
RES_Z=`readItemFromConf $CONFIGFILE "VSZZ_63X_AS"`

TAR=${TMPLDIR}"/"${TAR}
ATLAS=${TMPLDIR}"/"${ATLAS}

# debug inputs
message "Inputs..."
echo "CONFIGFILE: $CONFIGFILE"
echo "TMPLDIR: $TMPLDIR"
echo "TOOLDIR: $TOOLDIR"
echo "WORKDIR: $WORKDIR"
echo "SUB: $SUB"
echo "SUBREF: $SUBREF"
message "Vars..."
echo "Vaa3D: $Vaa3D"
echo "JBA: $JBA"
echo "ANTS: $ANTS"
echo "WARP: $WARP"
echo "SMPL: $SMPL"
echo "TAR: $TAR"
echo "TARREF: $TARREF"
echo "ATLAS: $ATLAS"
echo "RES_X: $RES_X"
echo "RES_Y: $RES_Y"
echo "RES_Z: $RES_Z"
echo ""

# convert inputs to raw format
ensureRawFile "$Vaa3D" "$WORKDIR" "$SUB" SUB
echo "RAW SUB: $SUB"
if [ -e $NEUBRAIN ]; then
    ensureRawFile "$Vaa3D" "$WORKDIR" "$NEUBRAIN" NEUBRAIN
    echo "RAW NEUBRAIN: $NEUBRAIN"
fi

OUTPUT=$WORKDIR"/LexAGAL4"
FINALOUTPUT=$WORKDIR"/FinalOutputs"

if [ ! -d $OUTPUT ]; then 
mkdir $OUTPUT
fi

if [ ! -d $FINALOUTPUT ]; then 
mkdir $FINALOUTPUT
fi

##################
# Alignment
##################

#
### global alignment using ANTS Rigid/Affine Registration
#

TARREF=$((TARREF-1));
SUBREF=$((SUBREF-1));

MAXITERATIONS=10000x10000x10000x10000x10000
GRADDSCNTOPTS=0.5x0.95x1.e-4x1.e-4

SAMPLERATIO=2

# temporary target
TEMPTARGET=${OUTPUT}/temptarget.raw
if ( is_file_exist "$TEMPTARGET" )
then
echo "TEMPTARGET: $TEMPTARGET exists"
else
#---exe---#
cp ${TAR} ${TEMPTARGET}
fi
TAR=$TEMPTARGET

TEMPSUBJECT=${OUTPUT}/tempsubject.raw
if ( is_file_exist "$TEMPSUBJECT" )
then
echo "TEMPSUBJECT: $TEMPSUBJECT exists"
else
#---exe---#
cp ${SUB} ${TEMPSUBJECT}
fi
SUB=$TEMPSUBJECT

###
STRT=`echo $TAR | awk -F\. '{print $1}'`
STRS=`echo $SUB | awk -F\. '{print $1}'`

FIXED=$STRT"_c"$TARREF".nii"
MOVING=$STRS"_c"$SUBREF".nii"

MOVINGC1=$STRS"_c0.nii"
MOVINGC2=$STRS"_c1.nii"
MOVINGC3=$STRS"_c2.nii"

SUBGAC1=$STRS"_rrc0.nii"
SUBGAC2=$STRS"_rrc1.nii"
SUBGAC3=$STRS"_rrc2.nii"

SUBDeformed=${FINALOUTPUT}"/Aligned63xScale.v3draw"

STRT=`echo $FIXED | awk -F\. '{print $1}'`
FIXEDDS=$STRT"_ds.nii"
STRS=`echo $MOVING | awk -F\. '{print $1}'`
MOVINGDS=$STRS"_ds.nii"

#---exe---#
message " Converting raw/tif image to Nifti image"
$Vaa3D -x ireg -f NiftiImageConverter -i $SUB

if ( is_file_exist "$FIXED" )
then
echo "$FIXED exists"
else
#---exe---#
$Vaa3D -x ireg -f NiftiImageConverter -i $TAR
fi

#---exe---#
message " Downsampling "
$SMPL 3 $MOVING $MOVINGDS $SAMPLERATIO $SAMPLERATIO $SAMPLERATIO

if ( is_file_exist "$FIXEDDS" )
then
echo "$FIXEDDS exists"
else
#---exe---#
$SMPL 3 $FIXED $FIXEDDS $SAMPLERATIO $SAMPLERATIO $SAMPLERATIO
fi

SIMMETRIC=$OUTPUT"/cc"
AFFINEMATRIX=$OUTPUT"/ccAffine.txt"
FWDDISPFIELD=$OUTPUT"/ccWarp.nii.gz"
BWDDISPFIELD=$OUTPUT"/ccInverseWarp.nii.gz"

MAXITERSCC=30x90x20

#---exe---#
message " Global alignment "
$ANTS 3 -m  MI[ $FIXEDDS, $MOVINGDS, 1, 32] -o $SIMMETRIC -i 0 --use-Histogram-Matching  --number-of-affine-iterations $MAXITERATIONS --rigid-affine false

#
### local alignment using ANTS SyN
#

#---exe---#
message " Local alignment "
$ANTS 3 -m  CC[ $FIXEDDS, $MOVINGDS, 0.75, 4] -m MI[ $FIXEDDS, $MOVINGDS, 0.25, 32] -t SyN[0.25]  -r Gauss[3,0] -o $SIMMETRIC -i $MAXITERSCC --initial-affine $AFFINEMATRIX

#---exe---#
message " Warping to obtain the alignment result "
$WARP 3 $MOVINGC1 $SUBGAC1 -R $FIXED $FWDDISPFIELD $AFFINEMATRIX --use-BSpline
$WARP 3 $MOVINGC2 $SUBGAC2 -R $FIXED $FWDDISPFIELD $AFFINEMATRIX --use-BSpline
$WARP 3 $MOVINGC3 $SUBGAC3 -R $FIXED $FWDDISPFIELD $AFFINEMATRIX --use-BSpline

#---exe---#
message "$Vaa3D -x ireg -f NiftiImageConverter -i $SUBGAC1 $SUBGAC2 $SUBGAC3 -o $SUBDeformed -p \"#b 1 #v 1\" "
$Vaa3D -x ireg -f NiftiImageConverter -i $SUBGAC1 $SUBGAC2 $SUBGAC3 -o $SUBDeformed -p "#b 1 #v 1"

### Warping Neurons

STRN=`echo $NEUBRAIN | awk -F\. '{print $1}'`
STRN=`basename $STRN`
STRN=${OUTPUT}/${STRN}
NEUBRAINYFLIP=${STRN}"_yflip.v3draw"

if ( is_file_exist "$NEUBRAINYFLIP" )
then
echo " NEUBRAINYFLIP: $NEUBRAINYFLIP exists"
else
#---exe---#
message " Y-Flipping neurons first "
$Vaa3D -x ireg -f yflip -i $NEUBRAIN -o $NEUBRAINYFLIP
echo ""
fi

NEUBRAINNII=${STRN}"_yflip_c0.nii"

if ( is_file_exist "$NEUBRAINNII" )
then
echo "NEUBRAINNII: $NEUBRAINNII exists."
else
#---exe---#
message " Converting Neurons into Nifti "
$Vaa3D -x ireg -f NiftiImageConverter -i $NEUBRAINYFLIP
echo ""
fi

NEUBRAINDFMD=${OUTPUT}"/NeuronBrainAligned.nii"
NEUBRAINALIGNED=${OUTPUT}"/ConsolidatedLabel63xScale_yflip.v3draw"
NEUBRAINALIGNEDYFLIP=${FINALOUTPUT}"/ConsolidatedLabel63xScale.v3draw"

if ( is_file_exist "$NEUBRAINALIGNED" )
then
echo " NEUBRAINALIGNED: $NEUBRAINALIGNED exists"
else
#---exe---#
message " Warping Neurons "
$WARP 3 $NEUBRAINNII $NEUBRAINDFMD -R $FIXED $FWDDISPFIELD $AFFINEMATRIX --use-NN
$Vaa3D -x ireg -f NiftiImageConverter -i $NEUBRAINDFMD -o $NEUBRAINALIGNED -p "#b 1 #v 2 #r 0"
echo ""
fi

if ( is_file_exist "$NEUBRAINALIGNEDYFLIP" )
then
echo " NEUBRAINALIGNEDYFLIP: $NEUBRAINALIGNEDYFLIP exists"
else
#---exe---#
message " Y-Flipping neurons back "
$Vaa3D -x ireg -f yflip -i $NEUBRAINALIGNED -o $NEUBRAINALIGNEDYFLIP
echo ""
fi

##################
# 20x scale result
##################

SMPLRATIOXY=0.3065
SMPLRATIOZ=0.6129

LARS=${OUTPUT}"/cnvt20xscale.v3draw"

# ~ 20x final output
LAOUTPUTRS=${FINALOUTPUT}"/Aligned20xScale.v3draw"

message " Downsampling to obtain 20x alignment result"
#---exe---#
$Vaa3D -x ireg -f isampler -i $SUBDeformed -o $LARS -p "#x $SMPLRATIOXY #y $SMPLRATIOXY #z $SMPLRATIOZ"

#---exe---#
$Vaa3D -x ireg -f prepare20xData -o $LAOUTPUTRS -p "#s $LARS #t $ATLAS"

### neuron
NEUDeformed=${OUTPUT}"/ConsolidatedLabel20xScale.v3draw"
NEUDeformedTX=${FINALOUTPUT}"/ConsolidatedLabel20xScale.v3draw"

if ( is_file_exist "$NEUDeformedTX" )
then
echo " NEUDeformedTX: $NEUDeformedTX exists"
else
#---exe---#
message " Resizing Neuron to 20x scale "
$Vaa3D -x ireg -f isampler -i $NEUBRAINALIGNEDYFLIP -o $NEUDeformed -p "#x $SMPLRATIOXY #y $SMPLRATIOXY #z $SMPLRATIOZ #i 1"
$Vaa3D -x ireg -f prepare20xData -o $NEUDeformedTX -p "#s $NEUDeformedTX #t $ATLAS #k 1"
fi

##################
# Evaluation
##################

message " Generating Verification Movie "
ALIGNVERIFY=AlignVerify.mp4
$DIR/createVerificationMovie.sh -c $CONFIGFILE -k $TOOLDIR -w $WORKDIR -s $SUBDeformed -i $TAR -r $((SUBREF+1)) -o ${FINALOUTPUT}/$ALIGNVERIFY

##################
# Output Meta
##################

if [[ -f "$LAOUTPUTRS" ]]; then
META=${FINALOUTPUT}"/Aligned20xScale.properties"
echo "alignment.stack.filename=Aligned20xScale.v3draw" >> $META
echo "alignment.image.area=Brain" >> $META
echo "alignment.image.channels=$INPUT1_CHANNELS" >> $META
echo "alignment.image.refchan=$INPUT1_REF" >> $META
echo "alignment.space.name=JFRC2010_20x" >> $META
echo "alignment.resolution.voxels=0.62x0.62x0.62" >> $META
echo "alignment.image.size=1024x1023x218" >> $META
echo "alignment.objective=20x" >> $META
if [[ -f "$NEUDeformedTX" ]]; then
echo "neuron.masks.filename=ConsolidatedLabel20xScale.v3draw" >> $META
fi
fi

if [[ -f "$SUBDeformed" ]]; then
META=${FINALOUTPUT}"/Aligned63xScale.properties"
echo "alignment.stack.filename=Aligned63xScale.v3draw" >> $META
echo "alignment.image.area=Brain" >> $META
echo "alignment.image.channels=$INPUT1_CHANNELS" >> $META
echo "alignment.image.refchan=$INPUT1_REF" >> $META
echo "alignment.space.name=JFRC2010_63x" >> $META
echo "alignment.resolution.voxels=${RES_X}x${RES_Y}x${RES_Z}" >> $META
echo "alignment.image.size=3344x2052x361" >> $META
echo "alignment.bounding.box=" >> $META
echo "alignment.objective=63x" >> $META
if [[ -f "$NEUBRAINALIGNEDYFLIP" ]]; then
echo "neuron.masks.filename=ConsolidatedLabel63xScale.v3draw" >> $META
fi
fi

compressAllRaw $Vaa3D $WORKDIR
