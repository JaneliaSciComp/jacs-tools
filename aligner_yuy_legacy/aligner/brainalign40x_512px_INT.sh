#!/bin/bash
#
# 40x fly brain alignment pipeline 2.0, Janurary 14, 2013
# Modified with new API and Added Neuron Warping, May 14, 2013
#

################################################################################
# 
# The pipeline is developed for solving 40x fly brain alignment problems.
# Target brain's resolution (0.3x0.3x0.38 um)
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
CHN=$INPUT1_CHANNELS

# tools
Vaa3D=`readItemFromConf $CONFIGFILE "Vaa3D"`
ANTS=`readItemFromConf $CONFIGFILE "ANTS"`
WARP=`readItemFromConf $CONFIGFILE "WARP"`
MAGICK=`readItemFromConf $CONFIGFILE "MAGICK"`

Vaa3D=${TOOLDIR}"/"${Vaa3D}
ANTS=${TOOLDIR}"/"${ANTS}
WARP=${TOOLDIR}"/"${WARP}
MAGICK=${TOOLDIR}"/"${MAGICK}

# templates
TAR=`readItemFromConf $CONFIGFILE "tgtFBRCTX"`
TARREF=`readItemFromConf $CONFIGFILE "REFNO"`
ATLAS=`readItemFromConf $CONFIGFILE "atlasFBTX"`
RES_X=`readItemFromConf $CONFIGFILE "VSZX_20X_IS"`
RES_Y=`readItemFromConf $CONFIGFILE "VSZY_20X_IS"`
RES_Z=`readItemFromConf $CONFIGFILE "VSZZ_20X_IS"`
CMPBND=`readItemFromConf $CONFIGFILE "ORICMPBND"`
TMPMIPNULL=`readItemFromConf $CONFIGFILE "TMPMIPNULL"`

TAR=${TMPLDIR}"/"${TAR}
ATLAS=${TMPLDIR}"/"${ATLAS}
CMPBND=${TMPLDIR}"/"${CMPBND}
TMPMIPNULL=${TMPLDIR}"/"${TMPMIPNULL}

# debug inputs
message "Inputs..."
echo "CONFIGFILE: $CONFIGFILE"
echo "WORKDIR: $WORKDIR"
echo "SUB: $SUB"
echo "SUBREF: $SUBREF"
echo "NEUBRAIN: $NEUBRAIN"
echo "RESX: $RESX"
echo "RESY: $RESY"
echo "RESZ: $RESZ"
message "Vars..."
echo "Vaa3D: $Vaa3D"
echo "ANTS: $ANTS"
echo "WARP: $WARP"
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
ensureRawFile "$Vaa3D" "$WORKDIR" "$NEUBRAIN" NEUBRAIN
echo "RAW NEUBRAIN: $NEUBRAIN"

OUTPUT=$WORKDIR"/Outputs"
FINALOUTPUT=$WORKDIR"/FinalOutputs"

if [ ! -d $OUTPUT ]; then 
mkdir $OUTPUT
fi

if [ ! -d $FINALOUTPUT ]; then 
mkdir $FINALOUTPUT
fi

# mips
MIP1=$OUTPUT"/mip1.tif"
MIP2=$OUTPUT"/mip2.tif"
MIP3=$OUTPUT"/mip3.tif"

# png mips
PNG_MIP1=$FINALOUTPUT"/mip1.png"
PNG_MIP2=$FINALOUTPUT"/mip2.png"
PNG_MIP3=$FINALOUTPUT"/mip3.png"

##################
# Pre-processing
##################

TARREF=$((TARREF-1));
SUBREF=$((SUBREF-1));

# temporary target
TEMPTARGET=${OUTPUT}/temptarget.raw
if ( is_file_exist "$TEMPTARGET" )
then
echo "TEMPTARGET: $TEMPTARGET exists"
else
message " Link to target "
ln -s ${TAR} ${TEMPTARGET}
fi
TAR=$TEMPTARGET

# temporary subject
TEMPSUBJECT=${OUTPUT}/tempsubject.raw
if ( is_file_exist "$TEMPSUBJECT" )
then
echo "TEMPSUBJECT: $TEMPSUBJECT exists"
else
message " Link to subject "
ln -s ${SUB} ${TEMPSUBJECT}
fi
SUB=$TEMPSUBJECT

### isotropic interpolation
SRX=`echo $RESX/$RES_X | bc -l`
SRY=`echo $RESY/$RES_Y | bc -l`
SRZ=`echo $RESZ/$RES_Z | bc -l`

SUBIS=${OUTPUT}"/subis.v3draw"

if ( is_file_exist "$SUBIS" )
then
echo " SUBIS: $SUBIS exists"
else
message " Isotropic sampling subject to 20x scale "
$Vaa3D -x ireg -f isampler -i $SUB -o $SUBIS -p "#x $SRX #y $SRY #z $SRZ"
fi

### zflip
SUBISZFLIP=${OUTPUT}"/subiszflip.v3draw"

if ( is_file_exist "$SUBISZFLIP" )
then
echo " SUBISZFLIP: $SUBISZFLIP exists"
else
message " Flipping along z "
$Vaa3D -x ireg -f zflip -i $SUBIS -o $SUBISZFLIP
fi

### resize
SUBISZFLIPRS=${OUTPUT}"/subiszfliprs.v3draw"

if ( is_file_exist "$SUBISZFLIPRS" )
then
echo " SUBISZFLIPRS: $SUBISZFLIPRS exists"
else
message " Resizing subject to the same size to target "
$Vaa3D -x ireg -f prepare20xData -o $SUBISZFLIPRS -p "#s $SUBISZFLIP #t $TAR"
fi

##################
# Alignment
##################

DSRATIO=0.5
USRATIO=2

### alignment
STRT=`echo $TAR | awk -F\. '{print $1}'`
STRS=`echo $SUBISZFLIPRS | awk -F\. '{print $1}'`

FIXED=$STRT"_c"$TARREF".nii"
MOVING=$STRS"_c"$SUBREF".nii"

MOVINGC1=$STRS"_c0.nii"
MOVINGC2=$STRS"_c1.nii"
MOVINGC3=$STRS"_c2.nii"
MOVINGC4=$STRS"_c3.nii"

SUBGAC1=$STRS"_rrc0.nii"
SUBGAC2=$STRS"_rrc1.nii"
SUBGAC3=$STRS"_rrc2.nii"
SUBGAC4=$STRS"_rrc3.nii"

SUBGARC=$STRS"_rrc"${SUBREF}".nii"

SUBDeformed=${OUTPUT}"/Aligned20xScaleRC.v3draw"
SUBAligned=${FINALOUTPUT}"/Aligned20xScale.v3draw"

STRT=`echo $FIXED | awk -F\. '{print $1}'`
FIXEDDS=$STRT"_ds.nii"
STRS=`echo $MOVING | awk -F\. '{print $1}'`
MOVINGDS=$STRS"_ds.nii"

MAXITERATIONS=10000x10000x10000x10000x10000

if ( is_file_exist "$MOVING" )
then
echo " MOVING: $MOVING exists"
else
message " Converting subject to Nifti image "
$Vaa3D -x ireg -f NiftiImageConverter -i $SUBISZFLIPRS
fi

if ( is_file_exist "$FIXED" )
then
echo "FIXED: $FIXED exists"
else
message " Converting target to Nifti image "
$Vaa3D -x ireg -f NiftiImageConverter -i $TAR
fi

if ( is_file_exist "$MOVINGDS" )
then
echo "MOVINGDS: $MOVINGDS exists"
else
message " Downsampling subject "
$Vaa3D -x ireg -f resamplebyspacing -i $MOVING -o $MOVINGDS -p "#x $DSRATIO #y $DSRATIO #z $DSRATIO"
fi

if ( is_file_exist "$FIXEDDS" )
then
echo "FIXEDDS: $FIXEDDS exists"
else
message " Downsampling target "
$Vaa3D -x ireg -f resamplebyspacing -i $FIXED -o $FIXEDDS -p "#x $DSRATIO #y $DSRATIO #z $DSRATIO"
fi

SIMMETRIC=$OUTPUT"/ccmi"
AFFINEMATRIX=$OUTPUT"/ccmiAffine.txt"
FWDDISPFIELD=$OUTPUT"/ccmiWarp.nii.gz"
BWDDISPFIELD=$OUTPUT"/ccmiInverseWarp.nii.gz"

MAXITERSCC=30x90x20

if ( is_file_exist "$AFFINEMATRIX" )
then
echo "AFFINEMATRIX: $AFFINEMATRIX exists"
else
message " Global alignment "
$ANTS 3 -m  MI[ $FIXEDDS, $MOVINGDS, 1, 32] -o $SIMMETRIC -i 0 --number-of-affine-iterations $MAXITERATIONS --rigid-affine false
fi

if ( is_file_exist "$FWDDISPFIELD" )
then
echo "FWDDISPFIELD: $FWDDISPFIELD exists"
else
message " Local alignment "
$ANTS 3 -m  CC[ $FIXEDDS, $MOVINGDS, 0.75, 4] -m MI[ $FIXEDDS, $MOVINGDS, 0.25, 32] -t SyN[0.25]  -r Gauss[3,0] -o $SIMMETRIC -i $MAXITERSCC --initial-affine $AFFINEMATRIX
fi

### warping
if ( is_file_exist "$SUBGARC" )
then
echo "SUBGARC: $SUBGARC exists"
else
message " Warping subject "

if(($CHN>0))
then
$WARP 3 $MOVINGC1 $SUBGAC1 -R $FIXED $FWDDISPFIELD $AFFINEMATRIX --use-BSpline
fi

if(($CHN>1))
then
$WARP 3 $MOVINGC2 $SUBGAC2 -R $FIXED $FWDDISPFIELD $AFFINEMATRIX --use-BSpline
fi

if(($CHN>2))
then
$WARP 3 $MOVINGC3 $SUBGAC3 -R $FIXED $FWDDISPFIELD $AFFINEMATRIX --use-BSpline
fi

if(($CHN>3))
then
$WARP 3 $MOVINGC4 $SUBGAC4 -R $FIXED $FWDDISPFIELD $AFFINEMATRIX --use-BSpline
fi

fi

#
if ( is_file_exist "$SUBDeformed" )
then
echo "SUBDeformed: $SUBDeformed exists"
else
message " Converting NII to RAW "
if(($CHN==1))
then
$Vaa3D -x ireg -f NiftiImageConverter -i $SUBGAC1 -o $SUBDeformed -p "#b 1 #v 1"
fi

if(($CHN==2))
then
$Vaa3D -x ireg -f NiftiImageConverter -i $SUBGAC1 $SUBGAC2 -o $SUBDeformed -p "#b 1 #v 1"
fi

if(($CHN==3))
then
$Vaa3D -x ireg -f NiftiImageConverter -i $SUBGAC1 $SUBGAC2 $SUBGAC3 -o $SUBDeformed -p "#b 1 #v 1"
fi

if(($CHN==4))
then
$Vaa3D -x ireg -f NiftiImageConverter -i $SUBGAC1 $SUBGAC2 $SUBGAC3 $SUBGAC4 -o $SUBDeformed -p "#b 1 #v 1"
fi
fi

# unified space

VECTARI=0.6944

SUBDeformedTX=${OUTPUT}"/Aligned20xScaleRCRC.v3draw"

if ( is_file_exist "$SUBDeformedTX" )
then
echo " SUBDeformedTX $SUBDeformedTX exists"
else
#---exe---#
message " Refractive index correction "
$Vaa3D -x ireg -f isampler -i $SUBDeformed -o $SUBDeformedTX -p "#x 1.0 #y 1.0 #z $VECTARI"
fi

SUBDeformedTXRC=${OUTPUT}"/Aligned20xScaleRCRCRS.v3draw"


if ( is_file_exist "$SUBDeformedTXRC" )
then
echo "SUBDeformedTXRC: $SUBDeformedTXRC exists"
else
message " Scaling to the unified space "
$Vaa3D -x ireg -f prepare20xData -o $SUBDeformedTXRC -p "#s $SUBDeformedTX #t $ATLAS"
fi

SUBDeformedTXCI=${OUTPUT}"/Aligned20xScaleRCRCRS_c0.v3draw"
SUBDeformedTXCII=${OUTPUT}"/Aligned20xScaleRCRCRS_c1.v3draw"
SUBDeformedTXCIII=${OUTPUT}"/Aligned20xScaleRCRCRS_c2.v3draw"
SUBDeformedTXCIV=${OUTPUT}"/Aligned20xScaleRCRCRS_c3.v3draw"

if ( is_file_exist "$SUBAligned" )
then
echo "SUBAligned: $SUBAligned exists"
else
message " Adding boundaries "

$Vaa3D -x ireg -f splitColorChannels -i $SUBDeformedTXRC

if(($CHN==1))
then
$Vaa3D -x ireg -f mergeColorChannels -i $SUBDeformedTXCI $CMPBND -o $SUBAligned
fi

if(($CHN==2))
then
$Vaa3D -x ireg -f mergeColorChannels -i $SUBDeformedTXCI $SUBDeformedTXCII $CMPBND -o $SUBAligned
fi

if(($CHN==3))
then
$Vaa3D -x ireg -f mergeColorChannels -i $SUBDeformedTXCI $SUBDeformedTXCII $SUBDeformedTXCIII $CMPBND -o $SUBAligned
fi

if(($CHN==4))
then
$Vaa3D -x ireg -f mergeColorChannels -i $SUBDeformedTXCI $SUBDeformedTXCII $SUBDeformedTXCIII $SUBDeformedTXCIV $CMPBND -o $SUBAligned
fi

fi


##################
# Warping Neurons
##################

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

NEUIS=${STRN}"_is.v3draw"

if ( is_file_exist "$NEUIS" )
then
echo " NEUIS: $NEUIS exists"
else
message " Isotropic sampling neuron to 20x scale "
$Vaa3D -x ireg -f isampler -i $NEUBRAINYFLIP -o $NEUIS -p "#x $SRX #y $SRY #z $SRZ #i 1"
fi


NEUISZFLIP=${STRN}"_iszflip.v3draw"

if ( is_file_exist "$NEUISZFLIP" )
then
echo " NEUISZFLIP: $NEUISZFLIP exists"
else
message " Flipping neuron along z "
$Vaa3D -x ireg -f zflip -i $NEUIS -o $NEUISZFLIP
fi

NEUISZFLIPRS=${STRN}"_iszfliprs.v3draw"

if ( is_file_exist "$NEUISZFLIPRS" )
then
echo " NEUISZFLIPRS: $NEUISZFLIPRS exists"
else
message " Resizing neuron to the same size to target "
$Vaa3D -x ireg -f prepare20xData -o $NEUISZFLIPRS -p "#s $NEUISZFLIP #t $TAR #k 1"
fi

NEUBRAINNII=${STRN}"_iszfliprs_c0.nii"

if ( is_file_exist "$NEUBRAINNII" )
then
echo "NEUBRAINNII: $NEUBRAINNII exists."
else
#---exe---#
message " Converting Neurons into Nifti "
$Vaa3D -x ireg -f NiftiImageConverter -i $NEUISZFLIPRS
echo ""
fi

NEUBRAINDFMD=${OUTPUT}"/NeuronBrainAligned.nii"
NEUBRAINALIGNED=${OUTPUT}"/ConsolidatedLabel20xScale_yflip.v3draw"
NEUBRAINALIGNEDYFLIP=${OUTPUT}"/ConsolidatedLabel20xScale.v3draw"
NEUBRAINALIGNEDYFLIPRC=${OUTPUT}"/ConsolidatedLabel20xScaleRc.v3draw"
NEUBRAINALIGNEDYFLIPUS=${FINALOUTPUT}"/ConsolidatedLabel.v3draw"

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

# unified space

if ( is_file_exist "$NEUBRAINALIGNEDYFLIPRC" )
then
echo " NEUBRAINALIGNEDYFLIPRC: $NEUBRAINALIGNEDYFLIPRC exists"
else
#---exe---#
message " Refractive index correction "
$Vaa3D -x ireg -f isampler -i $NEUBRAINALIGNEDYFLIP -o $NEUBRAINALIGNEDYFLIPRC -p "#x 1.0 #y 1.0 #z $VECTARI #i 1"
fi


if ( is_file_exist "$NEUBRAINALIGNEDYFLIPUS" )
then
echo "NEUBRAINALIGNEDYFLIPUS: $NEUBRAINALIGNEDYFLIPUS exists"
else
message " Scaling to the unified space "
$Vaa3D -x ireg -f prepare20xData -o $NEUBRAINALIGNEDYFLIPUS -p "#s $NEUBRAINALIGNEDYFLIPRC #t $ATLAS #k 1"
fi


##################
# MIPS
##################

SUBAlignedLink=${OUTPUT}"/Aligned20xScale.v3draw"

ln -s $SUBAligned $SUBAlignedLink

# GAOUTPUT_C3 is the reference
AOUTPUT_C0=$OUTPUT"/Aligned20xScale_c0.v3draw"
AOUTPUT_C1=$OUTPUT"/Aligned20xScale_c1.v3draw"
AOUTPUT_C2=$OUTPUT"/Aligned20xScale_c2.v3draw"
AOUTPUT_C3=$OUTPUT"/Aligned20xScale_c3.v3draw"

echo "~ Running splitColorChannels on $SUBAlignedLink"
$Vaa3D -x ireg -f splitColorChannels -i $SUBAlignedLink
TMPOUTPUT=$OUTPUT"/tmp.v3draw"

echo "~ Running mergeColorChannels to generate $TMPOUTPUT"
$Vaa3D -x ireg -f mergeColorChannels -i $AOUTPUT_C0 $AOUTPUT_C1 $AOUTPUT_C2 -o $TMPOUTPUT
echo "~ Running ireg's zmip on $TMPOUTPUT"
$Vaa3D -x ireg -f zmip -i $TMPOUTPUT -o $MIP3

STR=`echo $MIP3 | awk -F\. '{print $1}'`
TOUTPUT_C0=$STR"_c0.v3draw"
TOUTPUT_C1=$STR"_c1.v3draw"
TOUTPUT_C2=$STR"_c2.v3draw"

echo "~ Running splitColorChannels on $MIP3"
$Vaa3D -x ireg -f splitColorChannels -i $MIP3
echo "~ Running mergeColorChannels to generate $MIP2"
$Vaa3D -x ireg -f mergeColorChannels -i $TOUTPUT_C0 $TMPMIPNULL $TOUTPUT_C2 -o $MIP2
echo "~ Running mergeColorChannels to generate $MIP1"
$Vaa3D -x ireg -f mergeColorChannels -i $TMPMIPNULL $TOUTPUT_C1 $TOUTPUT_C2 -o $MIP1

echo "~ Running iContrastEnhancer"
$Vaa3D -x ireg -f iContrastEnhancer -i $MIP1 -o $MIP1 -p "#m 5"
$Vaa3D -x ireg -f iContrastEnhancer -i $MIP2 -o $MIP2 -p "#m 5"
$Vaa3D -x ireg -f iContrastEnhancer -i $MIP3 -o $MIP3 -p "#m 5"

export LD_LIBRARY_PATH="$MAGICK/../lib:$LD_LIBRARY_PATH"
$MAGICK/convert -flip $MIP1 $PNG_MIP1
$MAGICK/convert -flip $MIP2 $PNG_MIP2
$MAGICK/convert -flip $MIP3 $PNG_MIP3

##################
# evalutation
##################

AQ=${OUTPUT}"/AlignmentQuality.txt"

SUBREF=$((SUBREF+1))

if ( is_file_exist "$AQ" )
then
echo " AQ exists"
else
#---exe---#
message " Evaluating "
$Vaa3D -x ireg -f esimilarity -o $AQ -p "#s $SUBAligned #cs $SUBREF #t $ATLAS"
fi

while read LINE
do
read SCORE
done < $AQ;

message " Generating Verification Movie "
ALIGNVERIFY=AlignVerify.mp4
$DIR/createVerificationMovie.sh -c $CONFIGFILE -k $TOOLDIR -w $WORKDIR -s $SUBAligned -i $ATLAS -r $SUBREF -o ${FINALOUTPUT}/$ALIGNVERIFY

##################
# Output Meta
##################

if [[ -f "$SUBAligned" ]]; then
META=${FINALOUTPUT}"/Aligned20xScale.properties"
echo "alignment.stack.filename=Aligned20xScale.v3draw" >> $META
echo "alignment.image.area=Brain" >> $META
echo "alignment.image.channels=$INPUT1_CHANNELS" >> $META
echo "alignment.image.refchan=$INPUT1_REF" >> $META
echo "alignment.space.name=$UNIFIED_SPACE" >> $META
echo "alignment.resolution.voxels=0.62x0.62x0.62" >> $META
echo "alignment.image.size=1024x512x218" >> $META
echo "alignment.objective=20x" >> $META
echo "alignment.mip1=mip1.png" >> $META
echo "alignment.mip2=mip2.png" >> $META
echo "alignment.mip3=mip3.png" >> $META
echo "alignment.quality.score.ncc=$SCORE" >> $META
if [[ -f "$NEUBRAINALIGNEDYFLIPUS" ]]; then
echo "neuron.masks.filename=ConsolidatedLabel.v3draw" >> $META
fi
fi

compressAllRaw $Vaa3D $WORKDIR

