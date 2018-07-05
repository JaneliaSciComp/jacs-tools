#!/bin/bash

#
# fly optic lobe alignment pipeline, version 1.0, 2013/3/4
#

################################################################################
#
# The pipeline is developed for aligning fly optic lobe.
# Target brain's resolution (63x 0.38x0.38x0.38 um and 20x 0.62x0.62x0.62 um)
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
NEURONS=$INPUT1_NEURONS
RESX=$INPUT1_RESX
RESY=$INPUT1_RESY
RESZ=$INPUT1_RESZ

# tools
Vaa3D=`readItemFromConf $CONFIGFILE "Vaa3D"`
ANTS=`readItemFromConf $CONFIGFILE "ANTSMT"`
WARP=`readItemFromConf $CONFIGFILE "WARPMT"`

Vaa3D=${TOOLDIR}"/"${Vaa3D}
ANTS=${TOOLDIR}"/"${ANTS}
WARP=${TOOLDIR}"/"${WARP}

# templates
ATLAS=`readItemFromConf $CONFIGFILE "atlasFBTX"`
TAR=`readItemFromConf $CONFIGFILE "tgtFROLSX"`
TARREF=`readItemFromConf $CONFIGFILE "REFNO"`
RESSX_X=`readItemFromConf $CONFIGFILE "VSZX_63X_IS"`
RESSX_Y=`readItemFromConf $CONFIGFILE "VSZY_63X_IS"`
RESSX_Z=`readItemFromConf $CONFIGFILE "VSZZ_63X_IS"`

CROPMATRIX=`readItemFromConf $CONFIGFILE "FROLCROPMATRIX"`
ROTMATRIX=`readItemFromConf $CONFIGFILE "FROLROTMATRIX"`
INVROTMATRIX=`readItemFromConf $CONFIGFILE "FROLINVROTMATRIX"`

TAR=${TMPLDIR}"/"${TAR}
ATLAS=${TMPLDIR}"/"${ATLAS}
CROPMATRIX=${TMPLDIR}"/"${CROPMATRIX}
ROTMATRIX=${TMPLDIR}"/"${ROTMATRIX}
INVROTMATRIX=${TMPLDIR}"/"${INVROTMATRIX}

# debug inputs
message "Inputs..."
echo "CONFIGFILE: $CONFIGFILE"
echo "TMPLDIR: $TMPLDIR"
echo "TOOLDIR: $TOOLDIR"
echo "WORKDIR: $WORKDIR"
echo "SUB: $SUB"
echo "SUBREF: $SUBREF"
echo "RESX: $RESX"
echo "RESY: $RESY"
echo "RESZ: $RESZ"
echo "NEURONS: $NEURONS"
message "Vars..."
echo "Vaa3D: $Vaa3D"
echo "ANTS: $ANTS"
echo "WARP: $WARP"
echo "TAR: $TAR"
echo "TARREF: $TARREF"
echo "ATLAS: $ATLAS"
echo "CROPMATRIX: $CROPMATRIX"
echo "ROTMATRIX: $ROTMATRIX"
echo "INVROTMATRIX: $INVROTMATRIX"
echo ""

OUTPUT=$WORKDIR"/Outputs"
FINALOUTPUT=$WORKDIR"/FinalOutputs"

if [ ! -d $OUTPUT ]; then 
mkdir $OUTPUT
fi

if [ ! -d $FINALOUTPUT ]; then 
mkdir $FINALOUTPUT
fi

# convert inputs to raw format
ensureRawFile "$Vaa3D" "$OUTPUT" "$SUB" SUB
echo "RAW SUB: $SUB"

ensureRawFile "$Vaa3D" "$OUTPUT" "$NEURONS" NEURONS
echo "RAW NEURONS: $NEURONS"

##################
# Alignment
##################

###
# global alignment
###


#
### align rotation into (-15, 15) degrees  
#

### temporary target
TEMPTARGET=${OUTPUT}"/temptarget.v3draw"
if ( is_file_exist "$TEMPTARGET" )
then
echo "TARGET: $TEMPTARGET exists"
else
#---exe---#
message " Creating a symbolic link to right optic lobe target "
ln -s ${TAR} ${TEMPTARGET}
fi

TAR=$TEMPTARGET

### resize subject
SUBRAW=${OUTPUT}"/subexp.v3draw"
if ( is_file_exist "$SUBRAW" )
then
echo " SUBRAW: $SUBRAW exists"
else
#---exe---#
message " Resizing the subject to the same size with the target "
$Vaa3D -x ireg -f prepare20xData -o $SUBRAW -p "#s $SUB #t $TAR"
fi


### estimate rotations
SUBRR=${OUTPUT}"/subrigidreg.v3draw"
ROTMAT=${OUTPUT}"/subrigidregAffine.txt"

if ( is_file_exist "$ROTMAT" )
then
echo " ROTMAT: $ROTMAT exists"
else
#---exe---#
message " Estimating roations "
$Vaa3D -x ireg -f rigidreg -o $SUBRR -p "#s $SUBRAW #cs $SUBREF #t $TAR #ct $TARREF"
fi

SUBROT=${OUTPUT}"/subrot.v3draw"
if ( is_file_exist "$SUBROT" )
then
echo " SUBROT: $SUBROT exists"
else
#---exe---#
message " Rotating "
$Vaa3D -x ireg -f iwarp -o $SUBROT -p "#s $SUBRAW #t $TAR #a $ROTMAT"
fi

#
### rigid registration  
#

#TARREF=`expr $TARREF - 1`;
#SUBREF=`expr $SUBREF - 1`;

TARREF=$((TARREF-1))
SUBREF=$((SUBREF-1))

MAXITERATIONS=10000x10000x10000
GRADDSCNTOPTS=0.5x0.95x1.e-4x1.e-4
DSRATIO=0.5

STRT=`echo $TAR | awk -F\. '{print $1}'`
STRS=`echo $SUBROT | awk -F\. '{print $1}'`

FIXED=$STRT"_c"$TARREF".nii"
MOVING=$STRS"_c"$SUBREF".nii"

MOVINGC1=$STRS"_c0.nii"
MOVINGC2=$STRS"_c1.nii"
MOVINGC3=$STRS"_c2.nii"
MOVINGC4=$STRS"_c3.nii"

SUBAC1=$STRS"_c0_deformed.nii"
SUBAC2=$STRS"_c1_deformed.nii"
SUBAC3=$STRS"_c2_deformed.nii"
SUBAC4=$STRS"_c3_deformed.nii"

STRT=`echo $FIXED | awk -F\. '{print $1}'`
FIXEDGF=$STRT"_gf.nii"
STRS=`echo $MOVING | awk -F\. '{print $1}'`
MOVINGGF=$STRS"_gf.nii"

### Nifti images
if ( is_file_exist "$FIXED" )
then
echo "FIXED: $FIXED exists."
else
#---exe---#
message " Converting target into Nifti "
$Vaa3D -x ireg -f NiftiImageConverter -i $TAR
echo ""
fi

if ( is_file_exist "$MOVING" )
then
echo "MOVING: $MOVING exists."
else
#---exe---#
message " Converting subject into Nifti "
$Vaa3D -x ireg -f NiftiImageConverter -i $SUBROT
echo ""
fi

### gaussian filter
WZ=7

if ( is_file_exist "$FIXEDGF" )
then
echo "FIXEDGF: $FIXEDGF exists."
else
#---exe---#
message " Smoothing the target "
$Vaa3D -x ireg -f gaussianfilter -i $FIXED -o $FIXEDGF -p "#x $WZ #y $WZ #z $WZ"
echo ""
fi

if ( is_file_exist "$MOVINGGF" )
then
echo "MOVINGGF: $MOVINGGF exists."
else
#---exe---#
message " Smoothing the subject "
$Vaa3D -x ireg -f gaussianfilter -i $MOVING -o $MOVINGGF -p "#x $WZ #y $WZ #z $WZ"
echo ""
fi

### rigid registration
SIMMETRIC=${OUTPUT}"/mi"
AFFINEMATRIX=${OUTPUT}"/mi0GenericAffine.mat"
if ( is_file_exist "$AFFINEMATRIX" )
then
echo "AFFINEMATRIX: $AFFINEMATRIX exists."
else
#---exe---#
message " Running global alignment "
$ANTS -d 3 -m mattes[ $FIXEDGF, $MOVINGGF, 1, 32, regular, 0.1] -t affine[0.1]  -s 8x6x4x2x1  -f 10x8x6x4x2 -c [1000x1000x1000x1000x1000,1e-8, 20] -l 1 -o $SIMMETRIC
echo ""
fi

# global alignment result

SUBGA=${OUTPUT}"/subGlobalaligned.nii"

if ( is_file_exist "$SUBGA" )
then
echo "SUBGA: $SUBGA exists."
else
#---exe---#
message " Obtaining global aligned "
$WARP -d 3 -i $MOVINGGF -r $FIXED -n linear -t $AFFINEMATRIX -o $SUBGA
echo ""
fi


###
# local alignment
###

SIMMETRIC=${OUTPUT}"/mattes"
FWDDISPFIELD=${OUTPUT}"/mattes0Warp.nii.gz"
BWDDISPFIELD=${OUTPUT}"/mattes0InverseWarp.nii.gz"

MAXITERSCC=30x90x20

STRT=`echo $FIXEDGF | awk -F\. '{print $1}'`
FIXEDDS=$STRT"_ds.nii"
STRS=`echo $SUBGA | awk -F\. '{print $1}'`
MOVINGDS=$STRS"_ds.nii"

### Downsampling
if ( is_file_exist "$FIXEDDS" )
then
echo "FIXEDDS: $FIXEDDS exists."
else
#---exe---#
message " Downsampling target "
$Vaa3D -x ireg -f resamplebyspacing -i $FIXEDGF -o $FIXEDDS -p "#x $DSRATIO #y $DSRATIO #z $DSRATIO"
echo ""
fi

if ( is_file_exist "$MOVINGDS" )
then
echo "MOVINGDS: $MOVINGDS exists."
else
#---exe---#
message " Downsampling target "
$Vaa3D -x ireg -f resamplebyspacing -i $SUBGA -o $MOVINGDS -p "#x $DSRATIO #y $DSRATIO #z $DSRATIO"
echo ""
fi

if ( is_file_exist "$FWDDISPFIELD" )
then
echo "FWDDISPFIELD: $FWDDISPFIELD exists."
else
#---exe---#
message " Running local alignment "
$ANTS -d 3 -m mattes[ $FIXEDDS, $MOVINGDS, 1, 32] -t syn[0.3, 3, 0.0]  -s 2x1x0  -f 4x2x1 -c [$MAXITERSCC] -l 1 -o $SIMMETRIC
echo ""
fi

### warp
SUBDeformed=${FINALOUTPUT}"/Aligned63xScale.v3draw"

if ( is_file_exist "$SUBDeformed" )
then
echo " SUBDeformed: $SUBDeformed exists"
else
#---exe---#
message " Warping "
$WARP -d 3 -i $MOVINGC1 -r $FIXED -n BSpline -t $AFFINEMATRIX -t $FWDDISPFIELD -o $SUBAC1
$WARP -d 3 -i $MOVINGC2 -r $FIXED -n BSpline -t $AFFINEMATRIX -t $FWDDISPFIELD -o $SUBAC2
$WARP -d 3 -i $MOVINGC3 -r $FIXED -n BSpline -t $AFFINEMATRIX -t $FWDDISPFIELD -o $SUBAC3
$WARP -d 3 -i $MOVINGC4 -r $FIXED -n BSpline -t $AFFINEMATRIX -t $FWDDISPFIELD -o $SUBAC4

$Vaa3D -x ireg -f NiftiImageConverter -i $SUBAC1 $SUBAC2 $SUBAC3 $SUBAC4 -o $SUBDeformed -p "#b 1 #v 1"
echo ""
fi

### warp Neurons

#flip neurons along y

STRN=`echo $NEURONS | awk -F\. '{print $1}'`
echo "STRN=$STRN"
STRN=`basename $STRN`
STRN=${OUTPUT}/${STRN}
NEURONSYFLIP=${STRN}"_yflip.v3draw"

if ( is_file_exist "$NEURONSYFLIP" )
then
echo " NEURONSYFLIP: $NEURONSYFLIP exists"
else
#---exe---#
message " Y-Flipping neurons first "
$Vaa3D -x ireg -f yflip -i $NEURONS -o $NEURONSYFLIP
echo ""
fi

# resize
NEUREC=${STRN}"_yflip_rec.v3draw"
if ( is_file_exist "$NEUREC" )
then
echo " NEUREC: $NEUREC exists"
else
#---exe---#
message " Resizing the neuron to the same size with the target "
$Vaa3D -x ireg -f prepare20xData -o $NEUREC -p "#s $NEURONSYFLIP #t $TAR #k 1"
fi

# rotation
NEURONSYFLIPROT=${STRN}"_yflip_rot.v3draw"
if ( is_file_exist "$NEURONSYFLIPROT" )
then
echo " NEURONSYFLIPROT: $NEURONSYFLIPROT exists"
else
#---exe---#
message " Rotating "
$Vaa3D -x ireg -f iwarp -o $NEURONSYFLIPROT -p "#s $NEUREC #t $TAR #a $ROTMAT #i 1"
fi

NEURONSNII=${STRN}"_yflip_rot_c0.nii"

NEURONDFMD=${OUTPUT}"/NeuronAligned63xScale.nii"
NEURONALIGNEDYFLIP=${OUTPUT}"/NeuronAligned63xScale_yflip.v3draw"
NEURONALIGNED=${FINALOUTPUT}"/NeuronAligned63xScale.v3draw"

if ( is_file_exist "$NEURONSNII" )
then
echo "NEURONSNII: $NEURONSNII exists."
else
#---exe---#
message " Converting Neurons into Nifti "
$Vaa3D -x ireg -f NiftiImageConverter -i $NEURONSYFLIPROT
echo ""
fi

if ( is_file_exist "$NEURONALIGNEDYFLIP" )
then
echo " NEURONALIGNEDYFLIP: $NEURONALIGNEDYFLIP exists"
else
#---exe---#
message " Warping Neurons "
$WARP -d 3 -i $NEURONSNII -r $FIXED -n MultiLabel[0.8x0.8x0.8vox,4.0] -t $AFFINEMATRIX -t $FWDDISPFIELD -o $NEURONDFMD

$Vaa3D -x ireg -f NiftiImageConverter -i $NEURONDFMD -o $NEURONALIGNEDYFLIP -p "#b 1 #v 2 #r 0"
echo ""
fi

if ( is_file_exist "$NEURONALIGNED" )
then
echo " NEURONALIGNED: $NEURONALIGNED exists"
else
#---exe---#
message " Y-Flipping neurons back "
$Vaa3D -x ireg -f yflip -i $NEURONALIGNEDYFLIP -o $NEURONALIGNED
echo ""
fi

##################
# 20x scale result
##################

### padding zeros
SUBDeformedZeroPadded=${OUTPUT}"/subAlignedZeroPadded.v3draw"
NEURONDeformedZeroPadded=${OUTPUT}"/neuronAlignedZeroPadded.v3draw"
if ( is_file_exist "$NEURONDeformedZeroPadded" )
then
echo "NEURONDeformedZeroPadded: $NEURONDeformedZeroPadded exists."
else
#---exe---#
message " Zero padding "
$Vaa3D -x ireg -f zeropadding -i $SUBDeformed -o $SUBDeformedZeroPadded -p "#c $CROPMATRIX"
$Vaa3D -x ireg -f zeropadding -i $NEURONALIGNEDYFLIP -o $NEURONDeformedZeroPadded -p "#c $CROPMATRIX"
echo ""
fi

### rotate back
SUBDeformedZeroPaddedRotated=${OUTPUT}"/subAlignedZeroPaddedRotated.v3draw"
if ( is_file_exist "$SUBDeformedZeroPaddedRotated" )
then
echo "SUBDeformedZeroPaddedRotated: $SUBDeformedZeroPaddedRotated exists."
else
#---exe---#
message " Rotating back "
$Vaa3D -x ireg -f iwarp -o $SUBDeformedZeroPaddedRotated -p "#s $SUBDeformedZeroPadded #t $SUBDeformedZeroPadded #a $INVROTMATRIX"
echo ""
fi

NEURONDeformedZeroPaddedRotated=${OUTPUT}"/neuronAlignedZeroPaddedRotated.v3draw"
if ( is_file_exist "$NEURONDeformedZeroPaddedRotated" )
then
echo "NEURONDeformedZeroPaddedRotated: $NEURONDeformedZeroPaddedRotated exists."
else
#---exe---#
message " Rotating back "
$Vaa3D -x ireg -f iwarp -o $NEURONDeformedZeroPaddedRotated -p "#s $NEURONDeformedZeroPadded #t $NEURONDeformedZeroPadded #a $INVROTMATRIX #i 1"
echo ""
fi


### convert to 20x scale
SUBDeformed20xScaled=${OUTPUT}"/subalignedcnvt20xscale.v3draw"
NeuronDeformed20xScaled=${OUTPUT}"/neuronalignedcnvt20xscale.v3draw"
if ( is_file_exist "$NeuronDeformed20xScaled" )
then
echo "NeuronDeformed20xScaled: $NeuronDeformed20xScaled exists."
else
#---exe---#
message " Converting to 20x scale "
$Vaa3D -x ireg -f isampler -i $SUBDeformedZeroPaddedRotated -o $SUBDeformed20xScaled -p "#x 0.7474 #y 0.7474 #z 0.5190"
$Vaa3D -x ireg -f isampler -i $NEURONDeformedZeroPaddedRotated -o $NeuronDeformed20xScaled -p "#x 0.7474 #y 0.7474 #z 0.5190 #i 1"
echo ""
fi

### resize to unified target brain
SUBDeformedAtlasSpaced=${FINALOUTPUT}"/Aligned20xScale.v3draw"
NeuronDeformedAtlasSpacedYFLIP=${OUTPUT}"/NeuronAligned20xScale_yflip.v3draw"
NeuronDeformedAtlasSpaced=${FINALOUTPUT}"/NeuronAligned20xScale.v3draw"
if ( is_file_exist "$NeuronDeformedAtlasSpacedYFLIP" )
then
echo "NeuronDeformedAtlasSpacedYFLIP: $NeuronDeformedAtlasSpacedYFLIP exists."
else
#---exe---#
message " Converting to 20x scale "
$Vaa3D -x ireg -f prepare20xData -o $SUBDeformedAtlasSpaced  -p "#s $SUBDeformed20xScaled  #t $ATLAS"
$Vaa3D -x ireg -f prepare20xData -o $NeuronDeformedAtlasSpacedYFLIP  -p "#s $NeuronDeformed20xScaled  #t $ATLAS #k 1"
echo ""
fi

if ( is_file_exist "$NeuronDeformedAtlasSpaced" )
then
echo " NeuronDeformedAtlasSpaced: $NeuronDeformedAtlasSpaced exists"
else
#---exe---#
message " Y-Flipping neurons back "
$Vaa3D -x ireg -f yflip -i $NeuronDeformedAtlasSpacedYFLIP -o $NeuronDeformedAtlasSpaced
echo ""
fi

##################
# Evaluation
##################

message " Generating Verification Movie "
ALIGNVERIFY=AlignVerify.mp4
echo "$DIR/createVerificationMovie.sh -c $CONFIGFILE -k $TOOLDIR -w $WORKDIR -s $SUBDeformed -i $TAR -r $((SUBREF+1)) -o ${FINALOUTPUT}/$ALIGNVERIFY"
$DIR/createVerificationMovie.sh -c $CONFIGFILE -k $TOOLDIR -w $WORKDIR -s $SUBDeformed -i $TAR -r $((SUBREF+1)) -o ${FINALOUTPUT}/$ALIGNVERIFY

##################
# Output Meta
##################

if [[ -f "$SUBDeformedAtlasSpaced" ]]; then
META=${FINALOUTPUT}"/Aligned20xScale.properties"
echo "alignment.stack.filename=Aligned20xScale.v3draw" >> $META
echo "alignment.image.area=Brain" >> $META
echo "alignment.image.channels=$INPUT1_CHANNELS" >> $META
echo "alignment.image.refchan=$INPUT1_REF" >> $META
echo "alignment.space.name=$UNIFIED_SPACE" >> $META
echo "alignment.resolution.voxels=0.62x0.62x0.62" >> $META
echo "alignment.image.size=1024x512x218" >> $META
echo "alignment.objective=20x" >> $META
if [[ -f "$NeuronDeformedAtlasSpaced" ]]; then
echo "neuron.masks.filename=NeuronAligned20xScale.v3draw" >> $META
fi
fi

if [[ -f "$SUBDeformed" ]]; then
META=${FINALOUTPUT}"/Aligned63xScale.properties"
echo "alignment.stack.filename=Aligned63xScale.v3draw" >> $META
echo "alignment.image.area=Brain" >> $META
echo "alignment.image.channels=$INPUT1_CHANNELS" >> $META
echo "alignment.image.refchan=$INPUT1_REF" >> $META
echo "alignment.space.name=$UNIFIED_SPACE" >> $META
echo "alignment.resolution.voxels=${RESX}x${RESY}x${RESZ}" >> $META
echo "alignment.image.size=1712x1370x492" >> $META
echo "alignment.bounding.box=990x1610x180x860x0x491" >> $META
echo "alignment.objective=63x" >> $META
echo "default=true" >> $META
if [[ -f "$NEURONALIGNED" ]]; then
echo "neuron.masks.filename=NeuronAligned63xScale.v3draw" >> $META
fi
fi

compressAllRaw $Vaa3D $WORKDIR
