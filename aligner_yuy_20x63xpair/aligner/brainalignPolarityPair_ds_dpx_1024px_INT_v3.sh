#!/bin/bash
#
# The alignment pipeline for high-resolution partial fly brain, version 3.0, Feburary 24, 2017
# developed by Yang Yu (yuy@janleia.hhmi.org)
#

################################################################################
#
# Target: 20x and 63x DPX fly brains
# Voxel Size: (63x) 0.38x0.38x0.38 (20x) 0.46x0.46x0.46
# Upsampling ratio  : 1.2227x1.2227x2.00 (20x -> 63x) Then resize image.
# Dimensions : (63x) 1450x725x436  (20x) 1184x592x218
# Dims("rec"): (63x) 1933x1713x640 (20x) 1581x1401x320
# Downsampling ratio: 0.8179x0.8179x0.5 (63x -> 20x)
#
################################################################################

##################
#
### Basic Funcs
#
##################

DIR=$(cd "$(dirname "$0")"; pwd)
. $DIR/common.sh

##################
#
### Inputs
#
##################

parseParameters "$@"

CONFIGFILE=$DIR/systemvars.apconf
TMPLDIR=$TEMPLATE_DIR
TOOLDIR="${TOOL_DIR:-/opt}"
WORKDIR=$WORK_DIR

MP=$INPUT1_MOUNTING_PROTOCOL
NEUBRAIN=$INPUT1_NEURONS

# 63x parameters
SUBSX=$INPUT1_FILE
SUBSXREF=$INPUT1_REF
SUBSXNEURONS=$INPUT1_NEURONS
RESSX=$INPUT1_RESX
RESSY=$INPUT1_RESY
RESSZ=$INPUT1_RESZ
CHN=$INPUT1_CHANNELS

# 20x parameters
SUBTX=$INPUT2_FILE
SUBTXREF=$INPUT2_REF
SUBTXNEURONS=$INPUT2_NEURONS
RESTX=$INPUT2_RESX
RESTY=$INPUT2_RESY
RESTZ=$INPUT2_RESZ
CHNTX=$INPUT2_CHANNELS

ZFLIP=$ZFLIP
GENDER=$INPUT1_GENDER

# tools
Vaa3D=`readItemFromConf $CONFIGFILE "Vaa3D"`
ANTS=`readItemFromConf $CONFIGFILE "ANTS"`
WARP=`readItemFromConf $CONFIGFILE "WARP"`
FLIRT=`readItemFromConf $CONFIGFILE "FSLFLIRT"`

Vaa3D=${TOOLDIR}"/"${Vaa3D}
ANTS=${TOOLDIR}"/"${ANTS}
WARP=${TOOLDIR}"/"${WARP}

FLIRT=${TOOLDIR}"/"${FLIRT}

# templates
TARREF=`readItemFromConf $CONFIGFILE "REFNO"`

if [[ $GENDER =~ "m" ]]
then
# male fly brain
TARTX=`readItemFromConf $CONFIGFILE "tgtMFBTXDPX"`
TARSX=`readItemFromConf $CONFIGFILE "tgtMFBSXDPX"`
TARTXEXT=`readItemFromConf $CONFIGFILE "tgtMFBTXDPXEXT"`
TARSXEXT=`readItemFromConf $CONFIGFILE "tgtMFBSXDPXEXT"`
else
# female fly brain
TARTX=`readItemFromConf $CONFIGFILE "tgtFBTXDPX"`
TARSX=`readItemFromConf $CONFIGFILE "tgtFBSXDPXSS"`
TARTXEXT=`readItemFromConf $CONFIGFILE "tgtFBTXDPXEXT"`
TARSXEXT=`readItemFromConf $CONFIGFILE "tgtFBSXDPXEXT"`
fi

RESTX_X=`readItemFromConf $CONFIGFILE "VSZX_20X_IS_DPX"`
RESTX_Y=`readItemFromConf $CONFIGFILE "VSZY_20X_IS_DPX"`
RESTX_Z=`readItemFromConf $CONFIGFILE "VSZZ_20X_IS_DPX"`

RESSX_X=`readItemFromConf $CONFIGFILE "VSZX_63X_IS"`
RESSX_Y=`readItemFromConf $CONFIGFILE "VSZY_63X_IS"`
RESSX_Z=`readItemFromConf $CONFIGFILE "VSZZ_63X_IS"`

INITAFFINE=`readItemFromConf $CONFIGFILE "IDENTITYMATRIX"`

TARTX=${TMPLDIR}"/"${TARTX}
TARSX=${TMPLDIR}"/"${TARSX}
TARTXEXT=${TMPLDIR}"/"${TARTXEXT}
TARSXEXT=${TMPLDIR}"/"${TARSXEXT}
INITAFFINE=${TMPLDIR}"/"${INITAFFINE}

# debug inputs
message "Inputs..."
echo "CONFIGFILE: $CONFIGFILE"
echo "TMPLDIR: $TMPLDIR"
echo "TOOLDIR: $TOOLDIR"
echo "WORKDIR: $WORKDIR"

echo "MountingProtocol: $MP"

echo "SUBSX: $SUBSX"
echo "SUBSXREF: $SUBSXREF"
echo "SUBSXNEURONS: $SUBSXNEURONS"
echo "RESSX: $RESSX"
echo "RESSY: $RESSY"
echo "RESSZ: $RESSZ"
echo "CHN: $CHN"

echo "SUBTX: $SUBTX"
echo "SUBTXREF: $SUBTXREF"
echo "SUBTXNEURONS: $SUBTXNEURONS"
echo "RESTX: $RESTX"
echo "RESTY: $RESTY"
echo "RESTZ: $RESTZ"

message "Vars..."
echo "Vaa3D: $Vaa3D"
echo "ANTS: $ANTS"
echo "WARP: $WARP"

echo "FLIRT: $FLIRT"

echo "TARTX: $TARTX"
echo "TARSX: $TARSX"
echo "TARREF: $TARREF"
echo "TARTXEXT: $TARTXEXT"
echo "TARSXEXT: $TARSXEXT"

echo "RESTX_X: $RESTX_X"
echo "RESTX_Y: $RESTX_Y"
echo "RESTX_Z: $RESTX_Z"

echo "RESSX_X: $RESSX_X"
echo "RESSX_Y: $RESSX_Y"
echo "RESSX_Z: $RESSX_Z"

echo "INITAFFINE: $INITAFFINE"

echo ""

# convert inputs to raw format
ensureRawFile "$Vaa3D" "$WORKDIR" "$SUBSX" SUBSX
ensureRawFile "$Vaa3D" "$WORKDIR" "$SUBTX" SUBTX
echo "RAW SUB SX: $SUBSX"
echo "RAW SUB TX: $SUBTX"

processSeparatedNeuron=true;
if ( is_file_exist "$SUBSXNEURONS" )
then
echo "SUBSXNEURONS: $SUBSXNEURONS need to be warped after brain is aligned"
else
processSeparatedNeuron=false;
fi

if ( $processSeparatedNeuron )
then
ensureRawFileWdiffName "$Vaa3D" "$WORKDIR" "$SUBSXNEURONS" "${SUBSXNEURONS%.*}_SX.v3draw" SUBSXNEURONS
echo "RAW SUBSXNEURONS: $SUBSXNEURONS"
fi

# Outputs/
#         temporary files will be deleted
#         20x brain will be fully aligned in the other alignment pipeline
#
# FinalOutputs/
#               Brains/
# *removed             20x/
#                      63x/
#               Neurons/
# *removed              20x/
#                       63x/
#               Transformations/
# *removed                      20x/
#                               63x/
#
OUTPUT=${WORKDIR}"/Outputs"
FINALOUTPUT=${WORKDIR}"/FinalOutputs"

if [ ! -d $OUTPUT ]; then 
mkdir $OUTPUT
fi

if [ ! -d $FINALOUTPUT ]; then 
mkdir $FINALOUTPUT
fi

OUTBRAINS=${WORKDIR}"/FinalOutputs/Brains"
if [ ! -d $OUTBRAINS ]; then
mkdir $OUTBRAINS
fi

OUTBRAINSSX=${WORKDIR}"/FinalOutputs/Brains/63x"
if [ ! -d $OUTBRAINSSX ]; then
mkdir $OUTBRAINSSX
fi

if ( $processSeparatedNeuron )
then

OUTNEURONS=${WORKDIR}"/FinalOutputs/Neurons"
if [ ! -d $OUTNEURONS ]; then
mkdir $OUTNEURONS
fi

OUTNEURONSSX=${WORKDIR}"/FinalOutputs/Neurons/63x"
if [ ! -d $OUTNEURONSSX ]; then
mkdir $OUTNEURONSSX
fi

fi

OUTTRANSFORMATIONS=${WORKDIR}"/FinalOutputs/Transformations"
if [ ! -d $OUTTRANSFORMATIONS ]; then
mkdir $OUTTRANSFORMATIONS
fi

OUTTRANSFORMATIONSSX=${WORKDIR}"/FinalOutputs/Transformations/63x"
if [ ! -d $OUTTRANSFORMATIONSSX ]; then
mkdir $OUTTRANSFORMATIONSSX
fi

#############

TARSXEXTDX=1933
TARSXEXTDY=1713
TARSXEXTDZ=640

SRSTX=0.8179
SRSTY=0.8179
SRSTZ=0.5

SRTSX=1.2227
SRTSY=1.2227
SRTSZ=2.0

#############

#############
#
### preprocessing
#
#############

START=`date '+%F %T'`

### temporary target
TEMPTARGET=${OUTPUT}"/temptargettx.v3draw"
if ( is_file_exist "$TEMPTARGET" )
then
echo "TEMPTARGET: $TEMPTARGET exists"
else
#---exe---#
message " Creating a symbolic link to 20x target "
ln -s ${TARTX} ${TEMPTARGET}
fi
TARTX=$TEMPTARGET

TEMPTARGET=${OUTPUT}"/temptargetsx.v3draw"
if ( is_file_exist "$TEMPTARGET" )
then
echo "TEMPTARGET: $TEMPTARGET exists"
else
#---exe---#
message " Creating a symbolic link to 63x target "
ln -s ${TARSX} ${TEMPTARGET}
fi
TARSX=$TEMPTARGET

TEMPTARGET=${OUTPUT}"/temptargettxext.v3draw"
if ( is_file_exist "$TEMPTARGET" )
then
echo "TEMPTARGET: $TEMPTARGET exists"
else
#---exe---#
message " Creating a symbolic link to 63x target "
ln -s ${TARTXEXT} ${TEMPTARGET}
fi
TARTXEXT=$TEMPTARGET

### temporary subject
TEMPSUBJECT=${OUTPUT}"/tempsubjecttx.v3draw"
if ( is_file_exist "$TEMPSUBJECT" )
then
echo "TEMPSUBJECT: $TEMPSUBJECT exists"
else

if [[ $ZFLIP =~ "zflip" ]]
then
#---exe---#
message " Flipping 20x subject along z-axis "
$Vaa3D -x ireg -f zflip -i ${SUBTX} -o ${TEMPSUBJECT}
else
#---exe---#
message " Creating a symbolic link to 20x subject "
ln -s ${SUBTX} ${TEMPSUBJECT}
fi

fi
SUBTX=$TEMPSUBJECT

TEMPSUBJECT=${OUTPUT}"/tempsubjectsx.v3draw"
if ( is_file_exist "$TEMPSUBJECT" )
then
echo "TEMPSUBJECT: $TEMPSUBJECT exists"
else

if [[ $ZFLIP =~ "zflip" ]]
then
#---exe---#
message " Flipping 63x subject along z-axis "
$Vaa3D -x ireg -f zflip -i ${SUBSX} -o ${TEMPSUBJECT}
else
#---exe---#
message " Creating a symbolic link to 63x subject "
ln -s ${SUBSX} ${TEMPSUBJECT}
fi

fi
SUBSX=$TEMPSUBJECT

STOP=`date '+%F %T'`
echo "Preprocessing start: $START"
echo "Preprocessing stop: $STOP"

#############

START=`date '+%F %T'`

# FIXED TX
TARTXNII=${OUTPUT}"/temptargettxext_c0.nii"
if ( is_file_exist "$TARTXNII" )
then
echo " TARTXNII: $TARTXNII exists"
else
#---exe---#
message " Converting 20x target into Nifti image "
$Vaa3D -x ireg -f NiftiImageConverter -i $TARTXEXT
fi

# MOVING TX

# sampling 20x subject if the voxel size is not the same to the 20x target

TXISRX=`echo $RESTX/$RESTX_X | bc -l`
TXISRY=`echo $RESTY/$RESTX_Y | bc -l`
TXISRZ=`echo $RESTZ/$RESTX_Z | bc -l`

TXSRXC=$(bc <<< "$TXISRX - 1.0")
TXSRYC=$(bc <<< "$TXISRY - 1.0")
TXSRZC=$(bc <<< "$TXISRZ - 1.0")

TXASRXC=`echo $TXSRXC | awk '{ print ($1 >= 0) ? $1 : 0 - $1}'`
TXASRYC=`echo $TXSRYC | awk '{ print ($1 >= 0) ? $1 : 0 - $1}'`
TXASRZC=`echo $TXSRZC | awk '{ print ($1 >= 0) ? $1 : 0 - $1}'`

SUBTXIS=${OUTPUT}"/subtxIS.v3draw"
if [ $(bc <<< "$TXASRXC < 0.01") -eq 1 ] && [ $(bc <<< "$TXASRYC < 0.01") -eq 1 ] && [ $(bc <<< "$TXASRZC < 0.01") -eq 1 ]; then

message " The resolution of the 20x subject is the same to the 20x target "
ln -s $SUBTX $SUBTXIS

else

if ( is_file_exist "$SUBTXIS" )
then
echo " SUBTXIS: $SUBTXIS exists"
else
#---exe---#
message " Isotropic sampling 20x subject "
$Vaa3D -x ireg -f isampler -i $SUBTX -o $SUBTXIS -p "#x $TXISRX #y $TXISRY #z $TXISRZ"
fi

fi

SUBTXRS=${OUTPUT}"/subtxRs.v3draw"
if ( is_file_exist "$SUBTXRS" )
then
echo " SUBTXRS: $SUBTXRS exists"
else
#---exe---#
message " Resizing the 20x subject to 20x target "
$Vaa3D -x ireg -f resizeImage -o $SUBTXRS -p "#s $SUBTXIS #t $TARTXEXT"
fi

# SUBTXRFC -> affine -> non-rigid -> translation
SUBTXRFC=${OUTPUT}"/subtxRsRef.v3draw"
if ( is_file_exist "$SUBTXRFC" )
then
echo " SUBTXRFC: $SUBTXRFC exists"
else
#---exe---#
message " Extracting the reference of the 20x subject "
$Vaa3D -x refExtract -f refExtract -i $SUBTXRS -o $SUBTXRFC -p "#c $SUBTXREF";
fi

STOP=`date '+%F %T'`
echo "Moving_tx start: $START"
echo "Moving_tx stop: $STOP"


# MOVING SX

START=`date '+%F %T'`

# sampling 63x subject if the voxel size is not the same to the 63x target

ISRX=`echo $RESSX/$RESSX_X | bc -l`
ISRY=`echo $RESSY/$RESSX_Y | bc -l`
ISRZ=`echo $RESSZ/$RESSX_Z | bc -l`

SRXC=$(bc <<< "$ISRX - 1.0")
SRYC=$(bc <<< "$ISRY - 1.0")
SRZC=$(bc <<< "$ISRZ - 1.0")

ASRXC=`echo $SRXC | awk '{ print ($1 >= 0) ? $1 : 0 - $1}'`
ASRYC=`echo $SRYC | awk '{ print ($1 >= 0) ? $1 : 0 - $1}'`
ASRZC=`echo $SRZC | awk '{ print ($1 >= 0) ? $1 : 0 - $1}'`

SUBSXIS=${OUTPUT}"/subsxIS.v3draw"
if [ $(bc <<< "$ASRXC < 0.01") -eq 1 ] && [ $(bc <<< "$ASRYC < 0.01") -eq 1 ] && [ $(bc <<< "$ASRZC < 0.01") -eq 1 ]; then

message " The resolution of the 63x subject is the same to the 63x target "
ln -s $SUBSX $SUBSXIS

else

if ( is_file_exist "$SUBSXIS" )
then
echo " SUBSXIS: $SUBSXIS exists"
else
#---exe---#
message " Isotropic sampling 63x subject "
$Vaa3D -x ireg -f isampler -i $SUBSX -o $SUBSXIS -p "#x $ISRX #y $ISRY #z $ISRZ"
fi

fi

SUBSXRS=${OUTPUT}"/subsxRs.v3draw"
if ( is_file_exist "$SUBSXRS" )
then
echo " SUBSXRS: $SUBSXRS exists"
else
#---exe---#
message " Resizing the 63x subject to 63x target "
$Vaa3D -x ireg -f resizeImage -o $SUBSXRS -p "#s $SUBSXIS #t $TARSXEXT"
fi

SUBSXRSRFC=${OUTPUT}"/subsxRsRefChn.v3draw"
if ( is_file_exist "$SUBSXRSRFC" )
then
echo " SUBSXRSRFC: $SUBSXRSRFC exists"
else
#---exe---#
message " Extracting the reference of the 63x subject "
$Vaa3D -x refExtract -f refExtract -i $SUBSXRS -o $SUBSXRSRFC -p "#c $SUBSXREF";
fi

# SUBSXRSRFCDS -> translation
SUBSXRSRFCDS=${OUTPUT}"/subsxRsRefChnDs.v3draw"
if ( is_file_exist "$SUBSXRSRFCDS" )
then
echo " SUBSXRSRFCDS: $SUBSXRSRFCDS exists"
else
#---exe---#
message " Downsampling the reference of the 63x subject "
$Vaa3D -x ireg -f isampler -i $SUBSXRSRFC -o $SUBSXRSRFCDS -p "#x $SRSTX #y $SRSTY #z $SRSTZ";
fi


# 63x mask
SUBSXMASK=${OUTPUT}"/subsxMask.v3draw"
if ( is_file_exist "$SUBSXMASK" )
then
echo " SUBSXMASK: $SUBSXMASK exists"
else
#---exe---#
message " Creating a mask image for the 63x subject "
$Vaa3D -x ireg -f createMaskImage -i $SUBSXIS -o $SUBSXMASK
fi

SUBSXMASKRS=${OUTPUT}"/subsxMaskRs.v3draw"
if ( is_file_exist "$SUBSXMASKRS" )
then
echo " SUBSXMASKRS: $SUBSXMASKRS exists"
else
#---exe---#
message " Resizing the 63x mask to 63x target "
$Vaa3D -x ireg -f resizeImage -o $SUBSXMASKRS -p "#s $SUBSXMASK #t $TARSXEXT"
fi

STOP=`date '+%F %T'`
echo "Moving_sx start: $START"
echo "Moving_sx stop: $STOP"

#############
#
### global alignment
#
#############

START=`date '+%F %T'`
message " Global alignment : to find linear transformations"

### 1) match downsampled $SUBSX to $SUBTX

STITCHFOLDER=${OUTPUT}"/stitch"

if [ ! -d $STITCHFOLDER ]; then 
mkdir $STITCHFOLDER
fi

TCFILE=$STITCHFOLDER"/stitched_image.tc"
TCTEXT=$STITCHFOLDER"/stitched_image.txt"
TCAFFINE=$OUTPUT"/translationsAffine.txt"
SUBSXFORSTITCH=$STITCHFOLDER"/subsx.v3draw"
SUBTXFORSTITCH=$STITCHFOLDER"/subtx.v3draw"

if ( is_file_exist "$SUBTXFORSTITCH" )
then
echo " SUBTXFORSTITCH: $SUBTXFORSTITCH exists"
else
#---exe---#
message " Creating symbolic link for stitching "
ln -s $SUBTXRFC $SUBTXFORSTITCH
fi

if ( is_file_exist "$SUBSXFORSTITCH" )
then
echo " SUBSXFORSTITCH: $SUBSXFORSTITCH exists"
else
#---exe---#
message " Creating symbolic link for stitching "
ln -s $SUBSXRSRFCDS $SUBSXFORSTITCH
fi

if ( is_file_exist "$TCFILE" )
then
echo " TCFILE: $TCFILE exists"
else
#---exe---#
message " Matching downsampled 63x subject to 20x subject "
$Vaa3D -x imageStitch -f v3dstitch -i $STITCHFOLDER -p "#c 1 #si 0";
fi

if ( is_file_exist "$TCTEXT" )
then
echo " TCTEXT: $TCTEXT exists"
else
#---exe---#
message " Creating symbolic link "
ln -s $TCFILE $TCTEXT
fi

if ( is_file_exist "$TCAFFINE" )
then
echo " TCAFFINE: $TCAFFINE exists"
else
#---exe---#
message " Convert tc file to insight transform "
$Vaa3D -x ireg -f convertTC2AM -i $TCTEXT -o $TCAFFINE -p "#x $SRTSX #y $SRTSY #z $SRTSZ"
fi


### 2) estimate rotations

SUBTXRFCNII=${OUTPUT}"/subtxRsRef_c0.nii"
if ( is_file_exist "$SUBTXRFCNII" )
then
echo " SUBTXRFCNII: $SUBTXRFCNII exists"
else
#---exe---#
message " Converting 20x subject reference channel into Nifti image "
$Vaa3D -x ireg -f NiftiImageConverter -i $SUBTXRFC
fi

DSFAC=0.25
FDS=${OUTPUT}"/tartx_ds.nii"
MDS=${OUTPUT}"/subtx_ds.nii"

if ( is_file_exist "$FDS" )
then
echo " FDS: $FDS exists"
else
#---exe---#
message " Downsampling 20x target " 
$Vaa3D -x ireg -f resamplebyspacing -i $TARTXNII -o $FDS -p "#x $DSFAC #y $DSFAC #z $DSFAC" 
fi

if ( is_file_exist "$MDS" )
then
echo " MDS: $MDS exists"
else
#---exe---#
message " Downsampling 20x target " 
$Vaa3D -x ireg -f resamplebyspacing -i $SUBTXRFCNII -o $MDS -p "#x $DSFAC #y $DSFAC #z $DSFAC" 
fi

RCMAT=${OUTPUT}"/rotations.mat"
RCOUT=${OUTPUT}"/rotations.txt"
RCAFFINE=${OUTPUT}"/rotationsAffine.txt"

if ( is_file_exist "$RCMAT" )
then
echo " RCMAT: $RCMAT exists"
else
#---exe---#
message " Initial align 20x subject " 
export FSLOUTPUTTYPE=NIFTI_GZ
$FLIRT -v -in $MDS -ref $FDS -omat $RCMAT -cost normmi -searchrx -120 120 -searchry -120 120 -searchrz -120 120 -dof 12 -datatype char
fi

if ( ! is_file_exist "$RCMAT" )
then
    echo "Missing FLIRT output file $RCMAT"
    exit(1)
fi

if ( is_file_exist "$RCOUT" )
then
echo " RCOUT: $RCOUT exists"
else
#---exe---#
message " convert Affine matrix .mat to Insight Transform File .txt " 
cnt=1
while IFS=' ' read -ra str;
do

if(( cnt == 1))
then

r11=${str[0]}
r21=${str[1]}
r31=${str[2]}

elif ((cnt == 2))
then

r12=${str[0]}
r22=${str[1]}
r32=${str[2]}

elif ((cnt == 3))
then

r13=${str[0]}
r23=${str[1]}
r33=${str[2]}

fi

cnt=$((cnt+1))

done < $RCMAT

message "Parameters: $r11 $r12 $r13 $r21 $r22 $r23 $r31 $r32 $r33"

echo "#Insight Transform File V1.0" > $RCOUT
echo "#Transform 0" >> $RCOUT
echo "Transform: MatrixOffsetTransformBase_double_3_3" >> $RCOUT
echo "Parameters: $r11 $r12 $r13 $r21 $r22 $r23 $r31 $r32 $r33 0 0 0" >> $RCOUT
echo "FixedParameters: 0 0 0" >> $RCOUT

fi

if ( is_file_exist "$RCAFFINE" )
then
echo " RCAFFINE: $RCAFFINE exists"
else
#---exe---#
message " Estimate rotations "
$Vaa3D -x ireg -f extractRotMat -i $RCOUT -o $RCAFFINE
fi


### 3) global align $SUBTX to $TARTX

MAXITERATIONS=10000x10000x10000x10000

SUBTXRFCROT=${OUTPUT}"/subtxRefChnRsRot.v3draw"
if ( is_file_exist "$SUBTXRFCROT" )
then
echo " SUBTXRFCROT: $SUBTXRFCROT exists"
else
#---exe---#
message " Rotate the 20x subject "
$Vaa3D -x ireg -f iwarp -o $SUBTXRFCROT -p "#s $SUBTXRFC #t $TARTXEXT #a $RCAFFINE"
fi

# MOVING TX
SUBTXNII=${OUTPUT}"/subtxRefChnRsRot_c0.nii"
if ( is_file_exist "$SUBTXNII" )
then
echo " SUBTXNII: $SUBTXNII exists"
else
#---exe---#
message " Converting 20x subject into Nifti image "
$Vaa3D -x ireg -f NiftiImageConverter -i $SUBTXRFCROT
fi

SIMMETRIC=${OUTPUT}"/txmi"
AFFINEMATRIX=${OUTPUT}"/txmiAffine.txt"

if ( is_file_exist "$AFFINEMATRIX" )
then
echo " AFFINEMATRIX: $AFFINEMATRIX exists"
else
#---exe---#
message " Global aligning 20x subject to 20x target "
$ANTS 3 -m  MI[ $TARTXNII, $SUBTXNII, 1, 32] -o $SIMMETRIC -i 0 --number-of-affine-iterations $MAXITERATIONS #--rigid-affine true
fi

STOP=`date '+%F %T'`
echo "Global_align start: $START"
echo "Global_align stop: $STOP"

#############
#
### local alignment
#
#############

START=`date '+%F %T'`
message "Local alignment : to find nonlinear transformations"

# warp 63x subject with linear transformations: $TCAFFINE, $RCAFFINE, and $AFFINEMATRIX

SUBSXRSTL=${OUTPUT}"/subsxRsTranslated.v3draw"
if ( is_file_exist "$SUBSXRSTL" )
then
echo " SUBSXRSTL: $SUBSXRSTL exists"
else
#---exe---#
message " Translating recentered 63x subject "
$Vaa3D -x ireg -f iwarp2 -o $SUBSXRSTL -p "#s $SUBSXRS #a $TCAFFINE #dx $TARSXEXTDX #dy $TARSXEXTDY #dz $TARSXEXTDZ"
fi

SUBSXRSTLROT=${OUTPUT}"/subsxRsTranslatedRotated.v3draw"
if ( is_file_exist "$SUBSXRSTLROT" )
then
echo " SUBSXRSTLROT: $SUBSXRSTLROT exists"
else
#---exe---#
message " Translating recentered 63x subject "
$Vaa3D -x ireg -f iwarp2 -o $SUBSXRSTLROT -p "#s $SUBSXRSTL #a $RCAFFINE #sx $SRTSX #sy $SRTSY #sz $SRTSZ #dx $TARSXEXTDX #dy $TARSXEXTDY #dz $TARSXEXTDZ"
fi

SUBSXRSTLROTTF=${OUTPUT}"/subjectGlobalAligned63xScale.v3draw"
if ( is_file_exist "$SUBSXRSTLROTTF" )
then
echo " SUBSXRSTLROTTF: $SUBSXRSTLROTTF exists"
else
#---exe---#
message " Transforming translated 63x subject "
$Vaa3D -x ireg -f iwarp2 -o $SUBSXRSTLROTTF -p "#s $SUBSXRSTLROT #a $AFFINEMATRIX #sx $SRTSX #sy $SRTSY #sz $SRTSZ #dx $TARSXEXTDX #dy $TARSXEXTDY #dz $TARSXEXTDZ"
fi

### mask

SUBSXMASKRSTL=${OUTPUT}"/subsxMaskRsTranslated.v3draw"
if ( is_file_exist "$SUBSXMASKRSTL" )
then
echo " SUBSXMASKRSTL: $SUBSXMASKRSTL exists"
else
#---exe---#
message " Translating recentered 63x mask "
$Vaa3D -x ireg -f iwarp2 -o $SUBSXMASKRSTL -p "#s $SUBSXMASKRS #a $TCAFFINE #dx $TARSXEXTDX #dy $TARSXEXTDY #dz $TARSXEXTDZ"
fi

SUBSXMASKRSTLROT=${OUTPUT}"/subsxMaskRsTranslatedRotated.v3draw"
if ( is_file_exist "$SUBSXMASKRSTLROT" )
then
echo " SUBSXMASKRSTLROT: $SUBSXMASKRSTLROT exists"
else
#---exe---#
message " Translating recentered 63x mask "
$Vaa3D -x ireg -f iwarp2 -o $SUBSXMASKRSTLROT -p "#s $SUBSXMASKRSTL #a $RCAFFINE #sx $SRTSX #sy $SRTSY #sz $SRTSZ  #dx $TARSXEXTDX #dy $TARSXEXTDY #dz $TARSXEXTDZ"
fi

SUBSXMASKRSTLROTTF=${OUTPUT}"/subsxMaskRsTranslatedRotatedTransformed.v3draw"
if ( is_file_exist "$SUBSXMASKRSTLROTTF" )
then
echo " SUBSXMASKRSTLROTTF: $SUBSXMASKRSTLROTTF exists"
else
#---exe---#
message " Transforming translated 63x mask "
$Vaa3D -x ireg -f iwarp2 -o $SUBSXMASKRSTLROTTF -p "#s $SUBSXMASKRSTLROT #a $AFFINEMATRIX #sx $SRTSX #sy $SRTSY #sz $SRTSZ #dx $TARSXEXTDX #dy $TARSXEXTDY #dz $TARSXEXTDZ"
fi

### crop image

TARSXCROP=${OUTPUT}"/temptargetsx_cropped.v3draw"
TARSXCROPCONFIG=${OUTPUT}"/temptargetsx_cropped_cropconfigure.txt"
if ( is_file_exist "$TARSXCROP" )
then
echo " TARSXCROP: $TARSXCROP exists"
else
#---exe---#
message " Cropping transformed 63x subject images "
$Vaa3D -x ireg -f cropImage -i $TARSXEXT -o $TARSXCROP -p "#m $SUBSXMASKRSTLROTTF"
fi

SUBSXRSTLROTTFCROP=${OUTPUT}"/subjectGlobalAligned63xScale_crop.v3draw"
if ( is_file_exist "$SUBSXRSTLROTTFCROP" )
then
echo " SUBSXRSTLROTTFCROP: $SUBSXRSTLROTTFCROP exists"
else
#---exe---#
message " Cropping transformed 63x subject images "
$Vaa3D -x ireg -f cropImage -i $SUBSXRSTLROTTF -o $SUBSXRSTLROTTFCROP -p "#m $TARSXCROPCONFIG"
fi

FIXEDRAW=${OUTPUT}"/targetvoi63x.v3draw"
if ( is_file_exist "$FIXEDRAW" )
then
echo " FIXEDRAW: $FIXEDRAW exists"
else
#---exe---#
ln -s $TARSXCROP $FIXEDRAW
fi

MOVINGRAW=${OUTPUT}"/subjectvoi63x.v3draw"
if ( is_file_exist "$MOVINGRAW" )
then
echo " MOVINGRAW: $MOVINGRAW exists"
else
#---exe---#
ln -s $SUBSXRSTLROTTFCROP $MOVINGRAW
fi

FIXEDNII=${OUTPUT}"/targetvoi63x_c0.nii"
if ( is_file_exist "$FIXEDNII" )
then
echo " FIXEDNII: $FIXEDNII exists"
else
#---exe---#
message " Converting 63x target VOI into Nifti image "
$Vaa3D -x ireg -f NiftiImageConverter -i $FIXEDRAW
fi

if(($CHN>0))
then
MOVINGNIICI=${OUTPUT}"/subjectvoi63x_c0.nii"
fi

if(($CHN>1))
then
MOVINGNIICII=${OUTPUT}"/subjectvoi63x_c1.nii"
fi

if(($CHN>2))
then
MOVINGNIICIII=${OUTPUT}"/subjectvoi63x_c2.nii"
fi

if(($CHN>3))
then
MOVINGNIICIV=${OUTPUT}"/subjectvoi63x_c3.nii"
fi

SUBSXREF_ZEROIDX=$((SUBSXREF-1));
MOVINGNIICR=${OUTPUT}"/subjectvoi63x_c"${SUBSXREF_ZEROIDX}".nii"
if ( is_file_exist "$MOVINGNIICR" )
then
echo " MOVINGNIICR: $MOVINGNIICR exists"
else
#---exe---#
message " Converting 63x subject VOI into Nifti image "
$Vaa3D -x ireg -f NiftiImageConverter -i $MOVINGRAW
fi

# local alignment

### 63x partial brain

SIMMETRIC=${OUTPUT}"/ccmi"
AFFINEMATRIXLOCAL=${OUTPUT}"/ccmiAffine.txt"
FWDDISPFIELD=${OUTPUT}"/ccmiWarp.nii.gz"
BWDDISPFIELD=${OUTPUT}"/ccmiInverseWarp.nii.gz"

MAXITERSCC=100x70x50x0x0

if ( is_file_exist "$AFFINEMATRIXLOCAL" )
then
echo " AFFINEMATRIXLOCAL: $AFFINEMATRIXLOCAL exists"
else
#---exe---#
message " Local align 63x partial brain "
$ANTS 3 -m  CC[ $FIXEDNII, $MOVINGNIICR, 0.75, 8] -m MI[ $FIXEDNII, $MOVINGNIICR, 0.25, 32] -t SyN[0.25]  -r Gauss[3,0] -o $SIMMETRIC -i $MAXITERSCC --initial-affine $INITAFFINE
fi


STOP=`date '+%F %T'`
echo "Local_align start: $START"
echo "Local_align stop: $STOP"

#############
#
### warping
#
#############

START=`date '+%F %T'`
#
### warp brains
#

### 63x partial brain

if(($CHN>0))
then
MOVINGDFRMDCI=${OUTPUT}"/subjectvoi63x_c0_deformed.nii"
fi

if(($CHN>1))
then
MOVINGDFRMDCII=${OUTPUT}"/subjectvoi63x_c1_deformed.nii"
fi

if(($CHN>2))
then
MOVINGDFRMDCIII=${OUTPUT}"/subjectvoi63x_c2_deformed.nii"
fi

if(($CHN>3))
then
MOVINGDFRMDCIV=${OUTPUT}"/subjectvoi63x_c3_deformed.nii"
fi

MOVINGDFRMDCR=${OUTPUT}"/subjectvoi63x_c"${SUBSXREF_ZEROIDX}"_deformed.nii"

SUBSXDFRMD=${OUTPUT}"/subject63xWarped.v3draw"

if ( is_file_exist "$MOVINGDFRMDCR" )
then
echo " MOVINGDFRMDCR: $MOVINGDFRMDCR exists"
else
#---exe---#
message " Warping 63x subject "

if(($CHN>0))
then
$WARP 3 $MOVINGNIICI $MOVINGDFRMDCI -R $FIXEDNII $FWDDISPFIELD $AFFINEMATRIXLOCAL --use-BSpline
fi

if(($CHN>1))
then
$WARP 3 $MOVINGNIICII $MOVINGDFRMDCII -R $FIXEDNII $FWDDISPFIELD $AFFINEMATRIXLOCAL --use-BSpline
fi

if(($CHN>2))
then
$WARP 3 $MOVINGNIICIII $MOVINGDFRMDCIII -R $FIXEDNII $FWDDISPFIELD $AFFINEMATRIXLOCAL --use-BSpline
fi

if(($CHN>3))
then
$WARP 3 $MOVINGNIICIV $MOVINGDFRMDCIV -R $FIXEDNII $FWDDISPFIELD $AFFINEMATRIXLOCAL --use-BSpline
fi

fi

if ( is_file_exist "$SUBSXDFRMD" )
then
echo " SUBSXDFRMD: $SUBSXDFRMD exists"
else
#---exe---#
message " Combining the aligned 63x image channels into one stack "

if(($CHN==1))
then
$Vaa3D -x ireg -f NiftiImageConverter -i $MOVINGDFRMDCI -o $SUBSXDFRMD -p "#b 1 #v 1"
fi

if(($CHN==2))
then
$Vaa3D -x ireg -f NiftiImageConverter -i $MOVINGDFRMDCI $MOVINGDFRMDCII -o $SUBSXDFRMD -p "#b 1 #v 1"
fi

if(($CHN==3))
then
$Vaa3D -x ireg -f NiftiImageConverter -i $MOVINGDFRMDCI $MOVINGDFRMDCII $MOVINGDFRMDCIII -o $SUBSXDFRMD -p "#b 1 #v 1"
fi

if(($CHN==4))
then
$Vaa3D -x ireg -f NiftiImageConverter -i $MOVINGDFRMDCI $MOVINGDFRMDCII $MOVINGDFRMDCIII $MOVINGDFRMDCIV -o $SUBSXDFRMD -p "#b 1 #v 1"
fi

fi

STOP=`date '+%F %T'`
echo "Warp_brain start: $START"
echo "Warp_brain stop: $STOP"

#
### warp neurons
#
START=`date '+%F %T'`

if ( $processSeparatedNeuron )
then

### 63x

STRN=${OUTPUT}"/subsxNeuSegs"
NEURONSYFLIP=${STRN}"_yflip.v3draw"
if ( is_file_exist "$NEURONSYFLIP" )
then
echo " NEURONSYFLIP: $NEURONSYFLIP exists"
else
#---exe---#
message " Y-Flipping 63x neurons first "
$Vaa3D -x ireg -f yflip -i $SUBSXNEURONS -o $NEURONSYFLIP

if [[ $ZFLIP =~ "zflip" ]]
then
#---exe---#
message " Flipping 63x neurons along z-axis "
$Vaa3D -x ireg -f zflip -i ${NEURONSYFLIP} -o ${NEURONSYFLIP}
fi

fi

NEURONSYFLIPIS=${STRN}"_yflipIs.v3draw"
if [ $(bc <<< "$ASRXC < 0.01") -eq 1 ] && [ $(bc <<< "$ASRYC < 0.01") -eq 1 ] && [ $(bc <<< "$ASRZC < 0.01") -eq 1 ]; then

message " The resolution of the 63x neurons is the same to the 63x target "
ln -s $NEURONSYFLIPIS $NEURONSYFLIP

else

if ( is_file_exist "$NEURONSYFLIPIS" )
then
echo " NEURONSYFLIPIS: $NEURONSYFLIPIS exists"
else
#---exe---#
message " Isotropic sampling 63x neurons "
$Vaa3D -x ireg -f isampler -i $NEURONSYFLIP -o $NEURONSYFLIPIS -p "#x $ISRX #y $ISRY #z $ISRZ #i 1"
fi

fi

NEURONSYFLIPISRS=${STRN}"_yflipIsRs.v3draw"
if ( is_file_exist "$NEURONSYFLIPISRS" )
then
echo " NEURONSYFLIPISRS: $NEURONSYFLIPISRS exists"
else
#---exe---#
message " Resizing the 63x neurons to 63x target "
$Vaa3D -x ireg -f resizeImage -o $NEURONSYFLIPISRS -p "#s $NEURONSYFLIPIS #t $TARSXEXT #k 1 #i 1"
fi

NEURONSYFLIPISRSTL=${STRN}"_yflipIsRsTrans.v3draw"
if ( is_file_exist "$NEURONSYFLIPISRSTL" )
then
echo " NEURONSYFLIPISRSTL: $NEURONSYFLIPISRSTL exists"
else
#---exe---#
message " Translating 63x neurons "
$Vaa3D -x ireg -f iwarp2 -o $NEURONSYFLIPISRSTL -p "#s $NEURONSYFLIPISRS #a $TCAFFINE #dx $TARSXEXTDX #dy $TARSXEXTDY #dz $TARSXEXTDZ #i 1"
fi

NEURONSYFLIPISRSTLRT=${STRN}"_yflipIsRsTransRot.v3draw"
if ( is_file_exist "$NEURONSYFLIPISRSTLRT" )
then
echo " NEURONSYFLIPISRSTLRT: $NEURONSYFLIPISRSTLRT exists"
else
#---exe---#
message " Rotating 63x neurons "
$Vaa3D -x ireg -f iwarp2 -o $NEURONSYFLIPISRSTLRT -p "#s $NEURONSYFLIPISRSTL #a $RCAFFINE #sx $SRTSX #sy $SRTSY #sz $SRTSZ #dx $TARSXEXTDX #dy $TARSXEXTDY #dz $TARSXEXTDZ #i 1"
fi

NEURONSYFLIPISRSTLRTAFF=${STRN}"_yflipIsRsTransRotAff.v3draw"
if ( is_file_exist "$NEURONSYFLIPISRSTLRTAFF" )
then
echo " NEURONSYFLIPISRSTLRTAFF: $NEURONSYFLIPISRSTLRTAFF exists"
else
#---exe---#
message " Transforming 63x neurons "
$Vaa3D -x ireg -f iwarp2 -o $NEURONSYFLIPISRSTLRTAFF -p "#s $NEURONSYFLIPISRSTLRT #a $AFFINEMATRIX #sx $SRTSX #sy $SRTSY #sz $SRTSZ #dx $TARSXEXTDX #dy $TARSXEXTDY #dz $TARSXEXTDZ #i 1"
fi


NEURONSYFLIPISRSTLRTAFFCP=${STRN}"_yflipIsRsTransRotAffCrop.v3draw"
if ( is_file_exist "$NEURONSYFLIPISRSTLRTAFFCP" )
then
echo " NEURONSYFLIPISRSTLRTAFFCP: $NEURONSYFLIPISRSTLRTAFFCP exists"
else
#---exe---#
message " Cropping transformed 63x neurons "
$Vaa3D -x ireg -f cropImage -i $NEURONSYFLIPISRSTLRTAFF -o $NEURONSYFLIPISRSTLRTAFFCP -p "#m $TARSXCROPCONFIG"
fi

NEURONSNII=${STRN}"_yflipIsRsTransRotAffCrop_c0.nii"

NEURONDFMD=${STRN}"NeuronAligned63xScale.nii"
NEURONALIGNEDYFLIP=${OUTPUT}"/NeuronAligned63xScale_yflip.v3draw"

if ( is_file_exist "$NEURONSNII" )
then
echo "NEURONSNII: $NEURONSNII exists."
else
#---exe---#
message " Converting 63x neurons into Nifti "
$Vaa3D -x ireg -f NiftiImageConverter -i $NEURONSYFLIPISRSTLRTAFFCP
echo ""
fi

if ( is_file_exist "$NEURONALIGNEDYFLIP" )
then
echo " NEURONALIGNEDYFLIP: $NEURONALIGNEDYFLIP exists"
else
#---exe---#
message " Warping 63x neurons "
$WARP 3 $NEURONSNII $NEURONDFMD -R $FIXEDNII $FWDDISPFIELD $AFFINEMATRIXLOCAL --use-NN

$Vaa3D -x ireg -f NiftiImageConverter -i $NEURONDFMD -o $NEURONALIGNEDYFLIP -p "#b 1 #v 2 #r 0"
fi

fi

STOP=`date '+%F %T'`
echo "Warp_neurons start: $START"
echo "Warp_neurons stop: $STOP"

#############
#
### Resize brains and neurons to target space
#
#############

START=`date '+%F %T'`

### brains

# 63x

SUBSXWBS=${OUTPUT}"/subsxAlignedWholeBrainSpace.v3draw"
SUBSXALINGED=${OUTBRAINSSX}"/Aligned63xScale.v3draw"

if ( is_file_exist "$SUBSXWBS" )
then
echo " SUBSXWBS: $SUBSXWBS exists"
else
#---exe---#
message " Padding zeros "
$Vaa3D -x ireg -f zeropadding -i $SUBSXDFRMD -o $SUBSXWBS -p "#c $TARSXCROPCONFIG"
fi

if ( is_file_exist "$SUBSXALINGED" )
then
echo " SUBSXALINGED: $SUBSXALINGED exists"
else
#---exe---#
message " Resizing the 63x aligned subject to 63x target "
$Vaa3D -x ireg -f prepare20xData -o $SUBSXALINGED -p "#s $SUBSXWBS #t $TARSX"
fi

### Neurons

if ( $processSeparatedNeuron )
then

# 63x

NEUSXWBS=${OUTPUT}"/neusxAlignedWholeBrainSpace.v3draw"
if ( is_file_exist "$NEUSXWBS" )
then
echo " NEUSXWBS: $NEUSXWBS exists"
else
#---exe---#
message " Padding zeros "
$Vaa3D -x ireg -f zeropadding -i $NEURONALIGNEDYFLIP -o $NEUSXWBS -p "#c $TARSXCROPCONFIG"
fi

SXNEURONALIGNED=${OUTPUT}"/NeuronAligned63xScale.v3draw"
if ( is_file_exist "$SXNEURONALIGNED" )
then
echo " SXNEURONALIGNED: $SXNEURONALIGNED exists"
else
#---exe---#
message " Resizing the 63x aligned neurons to 63x target "
$Vaa3D -x ireg -f prepare20xData -o $SXNEURONALIGNED -p "#s $NEUSXWBS #t $TARSX #k 1"
fi

NEUSXALINGED=${OUTNEURONSSX}"/NeuronAligned63xScale.v3draw"
if ( is_file_exist "$NEUSXALINGED" )
then
echo " NEUSXALINGED: $NEUSXALINGED exists"
else
#---exe---#
message " Y-Flipping 63x neurons back "
$Vaa3D -x ireg -f yflip -i $SXNEURONALIGNED -o $NEUSXALINGED
fi

fi

### keep all the transformations

# 63x

TCAFFINESAVE=${OUTTRANSFORMATIONSSX}"/translationsAffine.txt"
RCAFFINESAVE=${OUTTRANSFORMATIONSSX}"/rotationsAffine.txt"
AFFINEMATRIXSAVE=${OUTTRANSFORMATIONSSX}"/txmiAffine.txt"
FWDDISPFIELDSAVE=${OUTTRANSFORMATIONSSX}"/ccmiWarp.nii.gz"
BWDDISPFIELDSAVE=${OUTTRANSFORMATIONSSX}"/ccmiInverseWarp.nii.gz"
AFFINEMATRIXLOCALSAVE=${OUTTRANSFORMATIONSSX}"/ccmiAffine.txt"

cp $TCAFFINE $TCAFFINESAVE
cp $RCAFFINE $RCAFFINESAVE
cp $AFFINEMATRIX $AFFINEMATRIXSAVE
# KR 10/6/17: these files are too large to keep around
#cp $FWDDISPFIELD $FWDDISPFIELDSAVE
#cp $BWDDISPFIELD $BWDDISPFIELDSAVE
cp $AFFINEMATRIXLOCAL $AFFINEMATRIXLOCALSAVE

STOP=`date '+%F %T'`
echo "Resize_to_target start: $START"
echo "Resize_to_target stop: $STOP"

#############
#
### Evaluations
#
#############

START=`date '+%F %T'`
AQ=${OUTPUT}"/AlignmentQuality.txt"

if ( is_file_exist "$AQ" )
then
echo " AQ exists"
else
#---exe---#
message " Evaluating "
$Vaa3D -x ireg -f esimilarity -o $AQ -p "#s $SUBSXDFRMD #cs $SUBSXREF #t $TARSXCROP"
fi

while read LINE
do
read SCORE
done < $AQ;


message " Generating Verification Movie "
ALIGNVERIFY=VerifyMovie.mp4
$DIR/createVerificationMovie.sh -c $CONFIGFILE -k $TOOLDIR -w $WORKDIR -s $SUBSXALINGED -i $TARSX -r $SUBSXREF -o ${FINALOUTPUT}/$ALIGNVERIFY

STOP=`date '+%F %T'`
echo "Evaluations start: $START"
echo "Evaluations stop: $STOP"

#############
#
### Output Meta
#
#############

### Brains

# 63x

if [[ -f "$SUBSXALINGED" ]]; then
META=${OUTBRAINSSX}"/Aligned63xScale.properties"
echo "alignment.stack.filename=Aligned63xScale.v3draw" >> $META
echo "alignment.image.area=Brain" >> $META
echo "alignment.image.channels=$INPUT1_CHANNELS" >> $META
echo "alignment.image.refchan=$INPUT1_REF" >> $META
echo "alignment.verify.filename=${ALIGNVERIFY}" >> $META

if [[ $GENDER =~ "m" ]]
then
# male fly brain
echo "alignment.space.name=JFRC2014_63x" >> $META
else
# female fly brain
echo "alignment.space.name=JFRC2013_63x" >> $META
fi

echo "alignment.resolution.voxels=${RESSX_X}x${RESSX_Y}x${RESSX_Z}" >> $META
echo "alignment.image.size=1450x725x436" >> $META
echo "alignment.bounding.box=" >> $META
echo "alignment.objective=63x" >> $META
echo "alignment.quality.score.ncc=$SCORE" >> $META
if [[ -f "$NEUSXALINGED" ]]; then
    echo "neuron.masks.filename=NeuronAligned63xScale.v3draw" >> $META
fi
fi

compressAllRaw $Vaa3D $WORKDIR

