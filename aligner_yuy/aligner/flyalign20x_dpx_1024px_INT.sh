#!/bin/bash
#
# 1. fly alignment pipeline, version 1.0, July 5, 2013
# 2. fix warping downsampled bug but might need more memory to save the transformations,
# version 2.0, May 1, 2017
#

################################################################################
#
# The pipeline is developed for aligning 20x fly (brain + VNC).
# Target brain's resolution (0.46x0.46x0.46 um)
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
SUBBRAIN=$INPUT1_FILE
SUBVNC=$INPUT2_FILE
SUBREF=$INPUT1_REF
MP=$INPUT1_MOUNTING_PROTOCOL
NEUBRAIN=$INPUT1_NEURONS
NEUVNC=$INPUT2_NEURONS
RESX=$INPUT1_RESX
RESY=$INPUT1_RESY
RESZ=$INPUT1_RESZ
CHN=$INPUT1_CHANNELS
VNCRES="${INPUT2_RESX}x${INPUT2_RESY}x${INPUT2_RESZ}"
DIMX=$INPUT2_DIMX
DIMY=$INPUT2_DIMY
DIMZ=$INPUT2_DIMZ
VNCDIMS="${DIMX}x${DIMY}x${DIMZ}"
GENDER=$INPUT1_GENDER

# tools
Vaa3D=`readItemFromConf $CONFIGFILE "Vaa3D"`
JBA=`readItemFromConf $CONFIGFILE "JBA"`
ANTS=`readItemFromConf $CONFIGFILE "ANTS"`
WARP=`readItemFromConf $CONFIGFILE "WARP"`
WARPMT=`readItemFromConf $CONFIGFILE "WARPMT"`

Vaa3D=${TOOLDIR}"/"${Vaa3D}
ANTS=${TOOLDIR}"/"${ANTS}
WARP=${TOOLDIR}"/"${WARP}
WARPMT=${TOOLDIR}"/"${WARPMT}

# templates
if [[ $GENDER =~ "m" ]]
then
# male fly brain
TARTX=`readItemFromConf $CONFIGFILE "tgtMFBTXDPX"`
TARTXEXT=`readItemFromConf $CONFIGFILE "tgtMFBTXRECDPX"`
else
# female fly brain
TARTX=`readItemFromConf $CONFIGFILE "tgtFBTXDPX"`
TARTXEXT=`readItemFromConf $CONFIGFILE "tgtFBTXRECDPX"`
fi

TARREF=`readItemFromConf $CONFIGFILE "REFNO"`
RESTX_X=`readItemFromConf $CONFIGFILE "VSZX_20X_IS_DPX"`
RESTX_Y=`readItemFromConf $CONFIGFILE "VSZY_20X_IS_DPX"`
RESTX_Z=`readItemFromConf $CONFIGFILE "VSZZ_20X_IS_DPX"`

TARTX=${TMPLDIR}"/"${TARTX}
TARTXEXT=${TMPLDIR}"/"${TARTXEXT}

# debug inputs
message "Inputs..."
echo "CONFIGFILE: $CONFIGFILE"
echo "TMPLDIR: $TMPLDIR"
echo "TOOLDIR: $TOOLDIR"
echo "WORKDIR: $WORKDIR"
echo "SUBBRAIN: $SUBBRAIN"
echo "SUBVNC: $SUBVNC"
echo "SUBREF: $SUBREF"
echo "MountingProtocol: $MP"
echo "NEUBRAIN: $NEUBRAIN"
echo "NEUVNC: $NEUVNC"
message "Vars..."
echo "Vaa3D: $Vaa3D"
echo "ANTS: $ANTS"
echo "WARP: $WARP"
echo "WARPMT: $WARPMT"
echo "TARTX: $TARTX"
echo "TARREF: $TARREF"
echo "TARTXEXT: $TARTXEXT"
echo "RESX: $RESX"
echo "RESY: $RESY"
echo "RESZ: $RESZ"
echo "DIMX (VNC): $DIMX"
echo "DIMY (VNC): $DIMY"
echo "DIMZ (VNC): $DIMZ"
echo ""

OUTPUT=${WORKDIR}"/Outputs"
FINALOUTPUT=${WORKDIR}"/FinalOutputs"

if [ ! -d $OUTPUT ]; then 
mkdir $OUTPUT
fi

if [ ! -d $FINALOUTPUT ]; then 
mkdir $FINALOUTPUT
fi

processSeparatedNeuronBrain=true;
if ( is_file_exist "$NEUBRAIN" )
then
echo "NEUBRAIN: $NEUBRAIN need to be warped after brain is aligned"
else
processSeparatedNeuronBrain=false;
fi

if ( $processSeparatedNeuronBrain )
then
ensureRawFileWdiffName "$Vaa3D" "$OUTPUT" "$NEUBRAIN" "${NEUBRAIN%.*}_Brain.v3draw" NEUBRAIN
echo "RAW NEUBRAIN: $NEUBRAIN"
fi

processSeparatedNeuronVNC=true;
if ( is_file_exist "$NEUVNC" )
then
echo "NEUVNC: $NEUVNC need to be warped after brain is aligned"
else
processSeparatedNeuronVNC=false;
fi

if ( $processSeparatedNeuronVNC )
then
ensureRawFileWdiffName "$Vaa3D" "$OUTPUT" "$NEUVNC" "${NEUVNC%.*}_VNC.v3draw" NEUVNC
echo "RAW NEUVNC: $NEUVNC"
fi

##################
# Preprocessing
##################

### temporary target
TEMPTARGET=${OUTPUT}"/temptargettx.v3draw"
if ( is_file_exist "$TEMPTARGET" )
then
echo "Temp TARGET exists"
else
#---exe---#
message " Creating a symbolic link to 20x target "
ln -s ${TARTXEXT} ${TEMPTARGET}
fi

TARTXEXT=$TEMPTARGET

### convert to 8bit v3draw file
SUBBRAW=${OUTPUT}/"subbrain.v3draw"
SUBVRAW=${OUTPUT}/"subvnc.v3draw"

if ( is_file_exist "$SUBBRAW" )
then
echo " SUBBRAW: $SUBBRAW exists"
else
#---exe---#
message " Converting to v3draw file "
$Vaa3D -cmd image-loader -convert8 $SUBBRAIN $SUBBRAW
fi

if ( is_file_exist "$SUBVRAW" )
then
echo " SUBVRAW $SUBVRAW exists"
else
#---exe---#
message " Converting to v3draw file "
$Vaa3D -cmd image-loader -convert8 $SUBVNC $SUBVRAW
fi

### shrinkage ratio
# VECTASHIELD/DPXEthanol = 0.82
# VECTASHIELD/DPXPBS = 0.86
DPXSHRINKRATIO=1.0

if [[ $MP =~ "DPX Ethanol Mounting" ]]
then
    DPXSHRINKRATIO=0.9535
elif [[ $MP =~ "DPX PBS Mounting" ]]
then
    DPXSHRINKRATIO=1.0
elif [[ $MP =~ "" ]]
then
    echo "Mounting protocol not specified, proceeding with DPXSHRINKRATIO=$DPXSHRINKRATIO"
else
    # other mounting protocol
    echo "Unknown mounting protocol: $MP"
fi
 
echo "echo $DPXSHRINKRATIO*$RESTX_X | bc -l"
RESTX_X=`echo $DPXSHRINKRATIO*$RESTX_X | bc -l`
echo "echo $DPXSHRINKRATIO*$RESTX_Y | bc -l"
RESTX_Y=`echo $DPXSHRINKRATIO*$RESTX_Y | bc -l`
echo "echo $DPXSHRINKRATIO*$RESTX_Z | bc -l"
RESTX_Z=`echo $DPXSHRINKRATIO*$RESTX_Z | bc -l`

#DPXRI=1.55
DPXRI=1.0

### isotropic interpolation
SRX=`echo $RESX/$RESTX_X | bc -l`
SRY=`echo $RESY/$RESTX_Y | bc -l`
SRZ=`echo $RESZ/$RESTX_Z | bc -l`
#SRZ=`echo $SRZ*$DPXRI | bc -l`

### isotropic
SUBTXIS=${OUTPUT}"/subtxIS.v3draw"

if ( is_file_exist "$SUBTXIS" )
then
echo " SUBTXIS: $SUBTXIS exists"
else
#---exe---#
message " Isotropic sampling 20x subject "
$Vaa3D -x ireg -f isampler -i $SUBBRAW -o $SUBTXIS -p "#x $SRX #y $SRY #z $SRZ"
fi

# for warping the neurons
if ( $processSeparatedNeuronBrain )
then

SMLMAT=${OUTPUT}"/neubrainSampling.txt"

NWSRX=`echo 1.0/$SRX | bc -l`
NWSRY=`echo 1.0/$SRY | bc -l`
NWSRZ=`echo 1.0/$SRZ | bc -l`

if ( is_file_exist "$SMLMAT" )
then
echo " SMLMAT: $SMLMAT exists"
else
#---exe---#
message " Generating transformation matrix for sampling brain neurons "
echo "#Insight Transform File V1.0" >> $SMLMAT
echo "#Transform 0" >> $SMLMAT
echo "Transform: AffineTransform_double_3_3" >> $SMLMAT
echo "Parameters: $NWSRX 0 0 0 $NWSRY 0 0 0 $NWSRZ 0 0 0" >> $SMLMAT
echo "FixedParameters: 0 0 0" >> $SMLMAT
echo "" >> $SMLMAT
fi

fi

##################
# Alignment
##################

#
### global alignment
#

message " Global alignment "

MAXITERATIONS=10000x10000x10000x0
GRADDSCNTOPTS=0.5x0.95x1.e-4x1.e-4

TARREF=$((TARREF-1));
SUBREF_ZEROIDX=$((SUBREF-1));

### global align $SUBTXIS to $TARTX

STRT=`echo $TARTXEXT | awk -F\. '{print $1}'`
STRS=`echo $SUBTXIS | awk -F\. '{print $1}'`

FIXED=$STRT"_c"$TARREF".nii"
MOVING=$STRS"_c"$SUBREF_ZEROIDX".nii"

if(($CHN>0))
then
MOVINGNIICI=$STRS"_c0.nii"
MOVINGWRPCI=$STRS"_c0_deformed.nii"
fi

if(($CHN>1))
then
MOVINGNIICII=$STRS"_c1.nii"
MOVINGWRPCII=$STRS"_c1_deformed.nii"
fi

if(($CHN>2))
then
MOVINGNIICIII=$STRS"_c2.nii"
MOVINGWRPCIII=$STRS"_c2_deformed.nii"
fi

if(($CHN>3))
then
MOVINGNIICIV=$STRS"_c3.nii"
MOVINGWRPCIV=$STRS"_c3_deformed.nii"
fi

SUBBRAINDeformed=${OUTPUT}"/AlignedFlyBrain.v3draw"

SIMMETRIC=${OUTPUT}"/txmi"
AFFINEMATRIX=${OUTPUT}"/txmiAffine.txt"

if ( is_file_exist "$FIXED" )
then
echo " FIXED: $FIXED exists"
else
#---exe---#
message " Converting 20x target into Nifti image "
$Vaa3D -x ireg -f NiftiImageConverter -i $TARTXEXT
fi

if ( is_file_exist "$MOVING" )
then
echo " MOVING: $MOVING exists"
else
#---exe---#
message " Converting 20x subject into Nifti image "
$Vaa3D -x ireg -f NiftiImageConverter -i $SUBTXIS
fi

if ( is_file_exist "$AFFINEMATRIX" )
then
echo " AFFINEMATRIX: $AFFINEMATRIX exists"
else
#---exe---#
message " Global aligning 20x fly brain to 20x target brain "
$ANTS 3 -m MI[ $FIXED, $MOVING, 1, 32] -o $SIMMETRIC -i 0 --number-of-affine-iterations $MAXITERATIONS --rigid-affine true --affine-gradient-descent-option $GRADDSCNTOPTS
fi


### extract rotation matrix from the affine matrix

ROTMATRIX=${OUTPUT}"/txmiRotation.txt"

if ( is_file_exist "$ROTMATRIX" )
then
echo " ROTMATRIX: $ROTMATRIX exists"
else
#---exe---#
message " Extracting roations from the rigid transformations "
$Vaa3D -x ireg -f extractRotMat -i $AFFINEMATRIX -o $ROTMATRIX
fi

#
### local alignment
#

message " Local alignment "

SIMMETRIC=${OUTPUT}"/ccmi"
AFFINEMATRIXLOCAL=${OUTPUT}"/ccmiAffine.txt"
FWDDISPFIELD=${OUTPUT}"/ccmiWarp.nii.gz"
BWDDISPFIELD=${OUTPUT}"/ccmiInverseWarp.nii.gz"

MAXITERSCC=100x70x50x0

if ( is_file_exist "$AFFINEMATRIXLOCAL" )
then
echo " AFFINEMATRIXLOCAL: $AFFINEMATRIXLOCAL exists"
else
#---exe---#
message " Local aligning 20x fly brain to 20x target brain "
$ANTS 3 -m  CC[ $FIXED, $MOVING, 0.75, 4] -m MI[ $FIXED, $MOVING, 0.25, 32] -t SyN[0.25]  -r Gauss[3,0] -o $SIMMETRIC -i $MAXITERSCC --initial-affine $AFFINEMATRIX
fi

### warp

# brain

if ( is_file_exist "$MOVINGWRPCI" )
then
echo " MOVINGWRPCI: $MOVINGWRPCI exists"
else
#---exe---#
message " Warping 20x subject "

if(($CHN>0))
then
$WARP 3 $MOVINGNIICI $MOVINGWRPCI -R $FIXED $FWDDISPFIELD $AFFINEMATRIXLOCAL --use-BSpline
fi

if(($CHN>1))
then
$WARP 3 $MOVINGNIICII $MOVINGWRPCII -R $FIXED $FWDDISPFIELD $AFFINEMATRIXLOCAL --use-BSpline
fi

if(($CHN>2))
then
$WARP 3 $MOVINGNIICIII $MOVINGWRPCIII -R $FIXED $FWDDISPFIELD $AFFINEMATRIXLOCAL --use-BSpline
fi

if(($CHN>3))
then
$WARP 3 $MOVINGNIICIV $MOVINGWRPCIV -R $FIXED $FWDDISPFIELD $AFFINEMATRIXLOCAL --use-BSpline
fi

fi

if ( is_file_exist "$SUBBRAINDeformed" )
then
echo " SUBBRAINDeformed: $SUBBRAINDeformed exists"
else
#---exe---#
message " Combining the aligned single channel images into one stack "

if(($CHN>0))
then
$Vaa3D -x ireg -f NiftiImageConverter -i $MOVINGWRPCI -o $SUBBRAINDeformed -p "#b 1 #v 1"
fi

if(($CHN>1))
then
$Vaa3D -x ireg -f NiftiImageConverter -i $MOVINGWRPCI $MOVINGWRPCII -o $SUBBRAINDeformed -p "#b 1 #v 1"
fi

if(($CHN>2))
then
$Vaa3D -x ireg -f NiftiImageConverter -i $MOVINGWRPCI $MOVINGWRPCII $MOVINGWRPCIII -o $SUBBRAINDeformed -p "#b 1 #v 1"
fi

if(($CHN>3))
then
$Vaa3D -x ireg -f NiftiImageConverter -i $MOVINGWRPCI $MOVINGWRPCII $MOVINGWRPCIII $MOVINGWRPCIV -o $SUBBRAINDeformed -p "#b 1 #v 1"
fi

fi

# vnc

SUBVNCRotated=${FINALOUTPUT}"/AlignedFlyVNC.v3draw"

if ( is_file_exist "$SUBVNCRotated" )
then
echo " SUBVNCRotated: $SUBVNCRotated exists"
else
#---exe---#
message " Warping VNC images "
$Vaa3D -x ireg -f iwarp -o $SUBVNCRotated -p "#s $SUBVRAW #t $SUBVRAW #a $ROTMATRIX"
fi

## brain neurons

if ( $processSeparatedNeuronBrain )
then

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

NEURONSNII=${STRN}"_yflip_c0.nii"

if ( is_file_exist "$NEURONSNII" )
then
echo "NEURONSNII: $NEURONSNII exists."
else
#---exe---#
message " Converting Neurons into Nifti "
$Vaa3D -x ireg -f NiftiImageConverter -i $NEUBRAINYFLIP
echo ""
fi

NEUBRAINSMPLD=${STRN}"_yflip_c0_sampled.nii"

if ( is_file_exist "$NEUBRAINSMPLD" )
then
echo "NEUBRAINSMPLD: $NEUBRAINSMPLD exists."
else
#---exe---#
message " Sampling neurons with the same ratio "
$WARPMT -d 3 -i $NEURONSNII -r $MOVING -t $SMLMAT -n MultiLabel[0.8x0.8x0.8vox,4.0] -o $NEUBRAINSMPLD
echo ""
fi

NEUBRAINDFMD=${OUTPUT}"/NeuronBrainAligned.nii"
NEUBRAINALIGNED=${OUTPUT}"/NeuronBrainAligned.v3draw"

if ( is_file_exist "$NEUBRAINALIGNED" )
then
echo " NEUBRAINALIGNED: $NEUBRAINALIGNED exists"
else
#---exe---#
message " Warping Neurons "
$WARPMT -d 3 -i $NEUBRAINSMPLD -r $FIXED -n MultiLabel[0.8x0.8x0.8vox,4.0] -t $AFFINEMATRIXLOCAL -t $FWDDISPFIELD -o $NEUBRAINDFMD

$Vaa3D -x ireg -f NiftiImageConverter -i $NEUBRAINDFMD -o $NEUBRAINALIGNED -p "#b 1 #v 2 #r 0"
echo ""
fi

NEUBRAINALIGNEDRS=${OUTPUT}"/NeuronBrainAligned_resize.v3draw"

if ( is_file_exist "$NEUBRAINALIGNEDRS" )
then
echo " NEUBRAINALIGNEDRS: $NEUBRAINALIGNEDRS exists"
else
#---exe---#
message " Resizing brain neuron "
$Vaa3D -x ireg -f prepare20xData -o $NEUBRAINALIGNEDRS -p "#s $NEUBRAINALIGNED #t $TARTX #k 1"
echo ""
fi

NEUBRAINALIGNEDYFLIP=${FINALOUTPUT}"/ConsolidatedLabelBrain.v3draw"

if ( is_file_exist "$NEUBRAINALIGNEDYFLIP" )
then
echo " NEUBRAINALIGNEDYFLIP: $NEUBRAINALIGNEDYFLIP exists"
else
#---exe---#
message " Y-Flipping neurons back "
$Vaa3D -x ireg -f yflip -i $NEUBRAINALIGNEDRS -o $NEUBRAINALIGNEDYFLIP
echo ""
fi

fi

## vnc neurons

if ( $processSeparatedNeuronVNC )
then

STRNVNC=`echo $NEUVNC | awk -F\. '{print $1}'`
STRNVNC=`basename $STRNVNC`
STRNVNC=${OUTPUT}/${STRNVNC}
NEUVNCYFLIP=${STRNVNC}"_yflip.v3draw"

if ( is_file_exist "$NEUVNCYFLIP" )
then
echo " NEUVNCYFLIP: $NEUVNCYFLIP exists"
else
#---exe---#
message " Y-Flipping neurons first "
$Vaa3D -x ireg -f yflip -i $NEUVNC -o $NEUVNCYFLIP
echo ""
fi

NEUVNCNII=${STRNVNC}"_yflip_c0.nii"

if ( is_file_exist "$NEUVNCNII" )
then
echo "NEUVNCNII: $NEUVNCNII exists."
else
#---exe---#
message " Converting Neurons into Nifti "
$Vaa3D -x ireg -f NiftiImageConverter -i $NEUVNCYFLIP
echo ""
fi

NEUVNCDFMD=${OUTPUT}"/NeuronVNCAligned.nii"
NEUVNCALIGNED=${OUTPUT}"/NeuronVNCAligned.v3draw"

VNCROTMAT=${OUTPUT}"/vncrotmat.txt"

if ( is_file_exist "$VNCROTMAT" )
then
echo " VNCROTMAT: $VNCROTMAT exists"
else
#---exe---#
message " Generating transformation matrix for warping vnc neurons"

CENTERX=`echo ${DIMX} / 2.0 | bc -l`
CENTERY=`echo ${DIMY} / 2.0 | bc -l`
CENTERZ=`echo ${DIMZ} / 2.0 | bc -l`

while read LINE
do

if [[ $LINE =~ "#Insight Transform File" ]]
then
echo $LINE >> $VNCROTMAT
elif [[ $LINE =~ "#Transform" ]]
then
echo $LINE >> $VNCROTMAT
elif [[ $LINE =~ "Transform:" ]]
then
echo $LINE >> $VNCROTMAT
elif [[ $LINE =~ "Parameters:" ]] && [[ ! $LINE =~ "FixedParameters:" ]]
then
echo $LINE >> $VNCROTMAT
elif [[ $LINE =~ "FixedParameters:" ]]
then
echo "FixedParameters: $CENTERX $CENTERY $CENTERZ" >> $VNCROTMAT
fi

done < $ROTMATRIX
echo "" >> $VNCROTMAT
fi

if ( is_file_exist "$NEUVNCALIGNED" )
then
echo " NEUVNCALIGNED: $NEUVNCALIGNED exists"
else
#---exe---#
message " Warping Neurons "
$WARPMT -d 3 -i $NEUVNCNII -r $NEUVNCNII -n MultiLabel[0.8x0.8x0.8vox,4.0] -t $VNCROTMAT -o $NEUVNCDFMD

$Vaa3D -x ireg -f NiftiImageConverter -i $NEUVNCDFMD -o $NEUVNCALIGNED -p "#b 1 #v 2 #r 0"
echo ""
fi

NEUVNCALIGNEDYFLIP=${FINALOUTPUT}"/ConsolidatedLabelVNC.v3draw"

if ( is_file_exist "$NEUVNCALIGNEDYFLIP" )
then
echo " NEUVNCALIGNEDYFLIP: $NEUVNCALIGNEDYFLIP exists"
else
#---exe---#
message " Y-Flipping neurons back "
$Vaa3D -x ireg -f yflip -i $NEUVNCALIGNED -o $NEUVNCALIGNEDYFLIP
echo ""
fi

fi

##################
# 20x unified
##################

SUBALIGNEDUNIFIED=${FINALOUTPUT}"/AlignedFlyBrain.v3draw"

echo $SUBALIGNEDUNIFIED

if ( is_file_exist "$SUBALIGNEDUNIFIED" )
then
echo " SUBALIGNEDUNIFIED: $SUBALIGNEDUNIFIED exists"
else
#---exe---#
message " Rescale to Yoshi 20x Alignment space "
$Vaa3D -x ireg -f prepare20xData -o $SUBALIGNEDUNIFIED -p "#s $SUBBRAINDeformed #t $TARTX"
fi


##################
# evalutation
##################

AQ=${OUTPUT}"/AlignmentQuality.txt"

if ( is_file_exist "$AQ" )
then
echo " AQ exists"
else
#---exe---#
message " Evaluating "
#$Vaa3D -x ireg -f evalAlignQuality -o $AQ -p "#s $SUBALIGNEDUNIFIED #cs $SUBREF #t $TARTX"
$Vaa3D -x ireg -f esimilarity -o $AQ -p "#s $SUBALIGNEDUNIFIED #cs $SUBREF #t $TARTX"
fi

while read LINE
do
read SCORE
done < $AQ; 

message " Generating Verification Movie "
ALIGNVERIFY=VerifyMovie.mp4
$DIR/createVerificationMovie.sh -c $CONFIGFILE -k $TOOLDIR -w $WORKDIR -s $SUBALIGNEDUNIFIED -i $TARTX -r $SUBREF -o ${FINALOUTPUT}/$ALIGNVERIFY

if [[ -f "$SUBALIGNEDUNIFIED" ]]; then
META=${FINALOUTPUT}"/AlignedFlyBrain.properties"
echo "alignment.stack.filename=AlignedFlyBrain.v3draw" >> $META
echo "alignment.image.area=Brain" >> $META
echo "alignment.image.channels=$INPUT1_CHANNELS" >> $META
echo "alignment.image.refchan=$INPUT1_REF" >> $META
echo "alignment.verify.filename=${ALIGNVERIFY}" >> $META

if [[ $GENDER =~ "m" ]]
then
# male fly brain
echo "alignment.space.name=JFRC2014_20x" >> $META
else
# female fly brain
echo "alignment.space.name=JFRC2013_20x" >> $META
fi

echo "alignment.resolution.voxels=0.46x0.46x0.46" >> $META
echo "alignment.image.size=1184x592x218" >> $META
echo "alignment.objective=20x" >> $META
if [[ -f "$NEUBRAINALIGNEDYFLIP" ]]; then
echo "neuron.masks.filename=ConsolidatedLabelBrain.v3draw" >> $META
fi
echo "alignment.quality.score.ncc=$SCORE" >> $META
fi

if [[ -f "$SUBVNCRotated" ]]; then
META=${FINALOUTPUT}"/AlignedFlyVNC.properties"
echo "alignment.stack.filename=AlignedFlyVNC.v3draw" >> $META
echo "alignment.image.area=VNC" >> $META
echo "alignment.image.channels=$INPUT2_CHANNELS" >> $META
echo "alignment.image.refchan=$INPUT2_REF" >> $META
echo "alignment.space.name=RotatedVNC_20x" >> $META
echo "alignment.resolution.voxels=${VNCRES}" >> $META
echo "alignment.image.size=${VNCDIMS}" >> $META
echo "alignment.objective=20x" >> $META
if [[ -f "$NEUVNCALIGNEDYFLIP" ]]; then
echo "neuron.masks.filename=ConsolidatedLabelVNC.v3draw" >> $META
fi
fi

compressAllRaw $Vaa3D $WORKDIR
