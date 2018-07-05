#!/bin/bash
#
# The alignment pipeline for high-resolution MCFO central fly brain, version 1.0, January 10, 2017
# developed by Yang Yu (yuy@janleia.hhmi.org)
#

################################################################################
#
# Subject: 40x MCFO central fly brains
# Target: downsampled 63x JFRC2013
# Voxel Size: (63x) 0.38x0.38x0.38
# Dimensions : (63x) 1450x725x436
# Dims("rec"): (63x) 1933x1713x640
#
################################################################################

start=`date +%s.%N`

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

MP=$MOUNTING_PROTOCOL
NEUBRAIN=$INPUT1_NEURONS

# subject parameters
SUBSX=$INPUT1_FILE
SUBSXREF=$INPUT1_REF
SUBSXNEURONS=$INPUT1_NEURONS
RESSX=$INPUT1_RESX
RESSY=$INPUT1_RESY
RESSZ=$INPUT1_RESZ
CHN=$INPUT1_CHANNELS

# special parameters
ZFLIP=$ZFLIP
GENDER=$GENDER

# tools
Vaa3D=`readItemFromConf $CONFIGFILE "Vaa3D"`
JBA=`readItemFromConf $CONFIGFILE "JBA"`
ANTS=`readItemFromConf $CONFIGFILE "ANTS"`
WARP=`readItemFromConf $CONFIGFILE "WARP"`
FLIRT=`readItemFromConf $CONFIGFILE "FSLFLIRT"`

Vaa3D=${TOOLDIR}"/"${Vaa3D}
JBA=${TOOLDIR}"/"${JBA}
ANTS=${TOOLDIR}"/"${ANTS}
WARP=${TOOLDIR}"/"${WARP}
FLIRT=${TOOLDIR}"/"${FLIRT}

# templates
TARREF=`readItemFromConf $CONFIGFILE "REFNO"`

if [[ $GENDER =~ "m" ]]
then
# male fly brain
TARSX=`readItemFromConf $CONFIGFILE "tgtMFBSXDPXCropped"`
TARSXEXT=`readItemFromConf $CONFIGFILE "tgtMFBSXDPXEXTCropped"`
else
# female fly brain
TARSX=`readItemFromConf $CONFIGFILE "tgtCBMCFO"`
TARSXEXT=`readItemFromConf $CONFIGFILE "tgtCBMCFOEXT"`
fi

RESSX_X=`readItemFromConf $CONFIGFILE "VSZX_63X_IS"`
RESSX_Y=`readItemFromConf $CONFIGFILE "VSZY_63X_IS"`
RESSX_Z=`readItemFromConf $CONFIGFILE "VSZZ_63X_IS"`

INITAFFINE=`readItemFromConf $CONFIGFILE "IDENTITYMATRIX"`

TARSX=${TMPLDIR}"/"${TARSX}
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

message "Vars..."
echo "Vaa3D: $Vaa3D"
echo "ANTS: $ANTS"
echo "WARP: $WARP"
echo "FLIRT: $FLIRT"

echo "TARREF: $TARREF"
echo "TARSX: $TARSX"
echo "TARSXEXT: $TARSXEXT"

echo "RESSX_X: $RESSX_X"
echo "RESSX_Y: $RESSX_Y"
echo "RESSX_Z: $RESSX_Z"

echo "INITAFFINE: $INITAFFINE"

echo ""

# convert inputs to raw format
ensureRawFile "$Vaa3D" "$WORKDIR" "$SUBSX" SUBSX
echo "RAW SUB SX: $SUBSX"

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
#
# FinalOutputs/
#               Brains/
#               Neurons/
#               Transformations/
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

if ( $processSeparatedNeuron )
then

OUTNEURONS=${WORKDIR}"/FinalOutputs/Neurons"
if [ ! -d $OUTNEURONS ]; then
mkdir $OUTNEURONS
fi

fi

OUTTRANSFORMATIONS=${WORKDIR}"/FinalOutputs/Transformations"
if [ ! -d $OUTTRANSFORMATIONS ]; then
mkdir $OUTTRANSFORMATIONS
fi

#############

TARSXEXTDX=1933
TARSXEXTDY=1713
TARSXEXTDZ=640

#############

#############
#
### preprocessing
#
#############

### temporary target
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

TEMPTARGET=${OUTPUT}"/temptargetsxext.v3draw"
if ( is_file_exist "$TEMPTARGET" )
then
echo "TEMPTARGET: $TEMPTARGET exists"
else
#---exe---#
message " Creating a symbolic link to 63x target "
ln -s ${TARSXEXT} ${TEMPTARGET}
fi
TARSXEXT=$TEMPTARGET

### temporary subject
TEMPSUBJECT=${OUTPUT}"/tempsubjectsx.v3draw"
if ( is_file_exist "$TEMPSUBJECT" )
then
echo "TEMPSUBJECT: $TEMPSUBJECT exists"
else

if [[ $ZFLIP =~ "zflip" ]]
then
#---exe---#
message " Flipping 63x subject along z-axis "
time $Vaa3D -x ireg -f zflip -i ${SUBSX} -o ${TEMPSUBJECT}
else
#---exe---#
message " Creating a symbolic link to 63x subject "
ln -s ${SUBSX} ${TEMPSUBJECT}
fi

fi
SUBSX=$TEMPSUBJECT

#############

# FIXED
TARSXNII=${OUTPUT}"/temptargetsxext_c0.nii"
if ( is_file_exist "$TARSXNII" )
then
echo " TARSXNII: $TARSXNII exists"
else
#---exe---#
message " Converting the target into Nifti image "
time $Vaa3D -x ireg -f NiftiImageConverter -i $TARSXEXT
fi

# MOVING

# sampling the subject if the voxel size is not the same to the target

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

message " The resolution of the subject is the same to the target "
ln -s $SUBSX $SUBSXIS

else

message "sampling with ratio $ISRX $ISRY $ISRZ"
if ( is_file_exist "$SUBSXIS" )
then
echo " SUBSXIS: $SUBSXIS exists"
else
#---exe---#
message " Isotropic sampling 63x subject "
time $Vaa3D -x ireg -f isampler -i $SUBSX -o $SUBSXIS -p "#x $ISRX #y $ISRY #z $ISRZ"
fi

fi

SUBSXRS=${OUTPUT}"/subsxRs.v3draw"
if ( is_file_exist "$SUBSXRS" )
then
echo " SUBSXRS: $SUBSXRS exists"
else
#---exe---#
message " Resizing the 63x subject to 63x target "
time $Vaa3D -x ireg -f resizeImage -o $SUBSXRS -p "#s $SUBSXIS #t $TARSXEXT #y 1"
fi

SUBSXRSRFC=${OUTPUT}"/subsxRsRefChn.v3draw"
if ( is_file_exist "$SUBSXRSRFC" )
then
echo " SUBSXRSRFC: $SUBSXRSRFC exists"
else
#---exe---#
message " Extracting the reference of the 63x subject "
time $Vaa3D -x refExtract -f refExtract -i $SUBSXRS -o $SUBSXRSRFC -p "#c $SUBSXREF";
fi

#############
#
### global alignment
#
#############

message " Global alignment : affine transformations"

### 1) estimate rotations

SUBSXRSRFCNII=${OUTPUT}"/subsxRsRefChn_c0.nii"
if ( is_file_exist "$SUBSXRSRFCNII" )
then
echo " SUBSXRSRFCNII: $SUBSXRSRFCNII exists"
else
#---exe---#
message " Converting the subject reference channel into a Nifti image "
time $Vaa3D -x ireg -f NiftiImageConverter -i $SUBSXRSRFC
fi

DSFAC=0.125
FDS=${OUTPUT}"/tar_ds.nii"
MDS=${OUTPUT}"/sub_ds.nii"

if ( is_file_exist "$FDS" )
then
echo " FDS: $FDS exists"
else
#---exe---#
message " Downsampling the target with ratio 1/8"
time $Vaa3D -x ireg -f resamplebyspacing -i $TARSXNII -o $FDS -p "#x $DSFAC #y $DSFAC #z $DSFAC"
fi

if ( is_file_exist "$MDS" )
then
echo " MDS: $MDS exists"
else
#---exe---#
message " Downsampling the subject with ratio 1/8"
time $Vaa3D -x ireg -f resamplebyspacing -i $SUBSXRSRFCNII -o $MDS -p "#x $DSFAC #y $DSFAC #z $DSFAC"
fi

RCMAT=${OUTPUT}"/rotations.mat"
RCOUT=${OUTPUT}"/rotations.txt"
RCAFFINE=${OUTPUT}"/rotationsAffine.txt"

if ( is_file_exist "$RCMAT" )
then
echo " RCMAT: $RCMAT exists"
else
#---exe---#
message " Find the rotations with FSL/flirt "
export FSLOUTPUTTYPE=NIFTI_GZ
time $FLIRT -v -in $MDS -ref $FDS -omat $RCMAT -cost normmi -searchrx -120 120 -searchry -120 120 -searchrz -120 120 -dof 12 -datatype char
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
time $Vaa3D -x ireg -f extractRotMat -i $RCOUT -o $RCAFFINE
fi


### 2) global alignment with ANTs

MAXITERATIONS=10000x10000x10000x10000

SUBSXRFCROT=${OUTPUT}"/subsxRefChnRsRot.v3draw"
if ( is_file_exist "$SUBSXRFCROT" )
then
echo " SUBSXRFCROT: $SUBSXRFCROT exists"
else
#---exe---#
message " Rotate the subject "
time $Vaa3D -x ireg -f iwarp -o $SUBSXRFCROT -p "#s $SUBSXRSRFC #t $TARSXEXT #a $RCAFFINE"
fi

# MOVING
SUBNII=${OUTPUT}"/subsxRefChnRsRot_c0.nii"
if ( is_file_exist "$SUBNII" )
then
echo " SUBNII: $SUBNII exists"
else
#---exe---#

message " Sleeping 10 seconds to wait for $SUBSXRFCROT"
sleep 10
ls -l $SUBSXRFCROT

message " Converting the subject into a Nifti image "
time $Vaa3D -x ireg -f NiftiImageConverter -i $SUBSXRFCROT
fi

SIMMETRIC=${OUTPUT}"/txmi"
AFFINEMATRIX=${OUTPUT}"/txmiAffine.txt"

if ( is_file_exist "$AFFINEMATRIX" )
then
echo " AFFINEMATRIX: $AFFINEMATRIX exists"
else
#---exe---#
message " Global aligning the subject to the target with ANTs"
time $ANTS 3 -m  MI[ $TARSXNII, $SUBNII, 1, 32] -o $SIMMETRIC -i 0 --number-of-affine-iterations $MAXITERATIONS #--rigid-affine true
fi

#############
#
### local alignment
#
#############

message "Local alignment : to find nonlinear transformations"

# warp the subject with linear transformations: $RCAFFINE and $AFFINEMATRIX

SUBSXRSROT=${OUTPUT}"/subsxRsRotated.v3draw"
if ( is_file_exist "$SUBSXRSROT" )
then
echo " SUBSXRSROT: $SUBSXRSROT exists"
else
#---exe---#
message " Rotated the recentered subject "
time $Vaa3D -x ireg -f iwarp2 -o $SUBSXRSROT -p "#s $SUBSXRS #a $RCAFFINE #dx $TARSXEXTDX #dy $TARSXEXTDY #dz $TARSXEXTDZ"
fi

SUBSXRSROTGA=${OUTPUT}"/subjectGlobalAligned.v3draw"
if ( is_file_exist "$SUBSXRSROTGA" )
then
echo " SUBSXRSROTGA: $SUBSXRSROTGA exists"
else
#---exe---#
message " Affine transforming rotated the subject "
time $Vaa3D -x ireg -f iwarp2 -o $SUBSXRSROTGA -p "#s $SUBSXRSROT #a $AFFINEMATRIX #dx $TARSXEXTDX #dy $TARSXEXTDY #dz $TARSXEXTDZ"
fi

### extract VOIs and then align VOIs

# MOVING
SUBSXRSROTGARS=${OUTPUT}"/subjectGlobalAligned_rs.v3draw"
TARSXRS=${OUTPUT}"/temptargetsx_rs.v3draw"
if ( is_file_exist "$SUBSXRSROTGARS" )
then
echo " SUBSXRSROTGARS: $SUBSXRSROTGARS exists"
else
#---exe---#
message " Resizing the subject to the original target "
time $Vaa3D -x ireg -f genVOIs -p "#s $SUBSXRSROTGA #t $TARSX"
fi

#
if(($CHN>0))
then
MOVINGNIICI=${OUTPUT}"/subjectGlobalAligned_rs_c0.nii"
fi

if(($CHN>1))
then
MOVINGNIICII=${OUTPUT}"/subjectGlobalAligned_rs_c1.nii"
fi

if(($CHN>2))
then
MOVINGNIICIII=${OUTPUT}"/subjectGlobalAligned_rs_c2.nii"
fi

if(($CHN>3))
then
MOVINGNIICIV=${OUTPUT}"/subjectGlobalAligned_rs_c3.nii"
fi

SUBSXREF_ZEROIDX=$((SUBSXREF-1));
MOVINGNIICR=${OUTPUT}"/subjectGlobalAligned_rs_c"${SUBSXREF_ZEROIDX}".nii"
if ( is_file_exist "$MOVINGNIICR" )
then
echo " MOVINGNIICR: $MOVINGNIICR exists"
else
#---exe---#
message " Converting 63x subject VOI into Nifti image "
time $Vaa3D -x ireg -f NiftiImageConverter -i $SUBSXRSROTGARS
fi

# FIXED
FIXEDNII=${OUTPUT}"/temptargetsx_rs_c0.nii"
if ( is_file_exist "$FIXEDNII" )
then
echo " FIXEDNII: $FIXEDNII exists"
else
#---exe---#
message " Converting the target into Nifti image "
time $Vaa3D -x ireg -f NiftiImageConverter -i $TARSXRS
fi

# local alignment

FIX=$FIXEDNII
MOV=$MOVINGNIICR

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
message " Local alignment "
time $ANTS 3 -m  CC[ $FIX, $MOV, 1, 8] -t SyN[0.25]  -r Gauss[3,0] -o $SIMMETRIC -i $MAXITERSCC
fi

#############
#
### warping
#
#############

#
### warp brains
#

MOVINGDFRMDCR=${OUTPUT}"/subjectGlobalAlignedRs_c"${SUBSXREF_ZEROIDX}"_deformed.nii"

SUBSXDFRMD=${OUTPUT}"/Aligned63xScaleRs.v3draw"
SUBSXALINGED=${OUTBRAINS}"/Aligned63xScale.v3draw"

if ( is_file_exist "$MOVINGDFRMDCR" )
then
echo " MOVINGDFRMDCR: $MOVINGDFRMDCR exists"
else
#---exe---#
message " Warping 63x subject "

if(($CHN>0))
then
MOVINGDFRMDCI=${OUTPUT}"/subjectGlobalAlignedRs_c0_deformed.nii"
time $WARP 3 $MOVINGNIICI $MOVINGDFRMDCI -R $FIXEDNII $FWDDISPFIELD $AFFINEMATRIXLOCAL --use-BSpline
fi

if(($CHN>1))
then
MOVINGDFRMDCII=${OUTPUT}"/subjectGlobalAlignedRs_c1_deformed.nii"
time $WARP 3 $MOVINGNIICII $MOVINGDFRMDCII -R $FIXEDNII $FWDDISPFIELD $AFFINEMATRIXLOCAL --use-BSpline
fi

if(($CHN>2))
then
MOVINGDFRMDCIII=${OUTPUT}"/subjectGlobalAlignedRs_c2_deformed.nii"
time $WARP 3 $MOVINGNIICIII $MOVINGDFRMDCIII -R $FIXEDNII $FWDDISPFIELD $AFFINEMATRIXLOCAL --use-BSpline
fi

if(($CHN>3))
then
MOVINGDFRMDCIV=${OUTPUT}"/subjectGlobalAlignedRs_c3_deformed.nii"
time $WARP 3 $MOVINGNIICIV $MOVINGDFRMDCIV -R $FIXEDNII $FWDDISPFIELD $AFFINEMATRIXLOCAL --use-BSpline
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
time $Vaa3D -x ireg -f NiftiImageConverter -i $MOVINGDFRMDCI -o $SUBSXDFRMD -p "#b 1 #v 1"
fi

if(($CHN==2))
then
time $Vaa3D -x ireg -f NiftiImageConverter -i $MOVINGDFRMDCI $MOVINGDFRMDCII -o $SUBSXDFRMD -p "#b 1 #v 1"
fi

if(($CHN==3))
then
time $Vaa3D -x ireg -f NiftiImageConverter -i $MOVINGDFRMDCI $MOVINGDFRMDCII $MOVINGDFRMDCIII -o $SUBSXDFRMD -p "#b 1 #v 1"
fi

if(($CHN==4))
then
time $Vaa3D -x ireg -f NiftiImageConverter -i $MOVINGDFRMDCI $MOVINGDFRMDCII $MOVINGDFRMDCIII $MOVINGDFRMDCIV -o $SUBSXDFRMD -p "#b 1 #v 1"
fi

fi

if ( is_file_exist "$SUBSXALINGED" )
then
echo " SUBSXALINGED: $SUBSXALINGED exists"
else
#---exe---#
message " Resize the brain to the tamplate's space"
time $Vaa3D -x ireg -f resizeImage -o $SUBSXALINGED -p "#s $SUBSXDFRMD #t $TARSX #y 1"
fi

#
### warp neurons
#

if ( $processSeparatedNeuron )
then


if ( is_file_exist "$SUBSXNEURONS" )
then

STRN=${OUTPUT}"/subsxNeuSegs"
NEURONSYFLIP=${STRN}"_yflip.v3draw"
if ( is_file_exist "$NEURONSYFLIP" )
then
echo " NEURONSYFLIP: $NEURONSYFLIP exists"
else
#---exe---#
message " Y-Flipping the neurons first "
time $Vaa3D -x ireg -f yflip -i $SUBSXNEURONS -o $NEURONSYFLIP

if [[ $ZFLIP =~ "zflip" ]]
then
#---exe---#
message " Flipping the neurons along z-axis "
time $Vaa3D -x ireg -f zflip -i ${NEURONSYFLIP} -o ${NEURONSYFLIP}
fi

fi

NEURONSYFLIPIS=${STRN}"_yflipIs.v3draw"
if [ $(bc <<< "$ASRXC < 0.01") -eq 1 ] && [ $(bc <<< "$ASRYC < 0.01") -eq 1 ] && [ $(bc <<< "$ASRZC < 0.01") -eq 1 ]; then

message " The resolution of the the neurons is the same to the target "
ln -s $NEURONSYFLIPIS $NEURONSYFLIP

else

if ( is_file_exist "$NEURONSYFLIPIS" )
then
echo " NEURONSYFLIPIS: $NEURONSYFLIPIS exists"
else
#---exe---#
message " Isotropic sampling the neurons "
time $Vaa3D -x ireg -f isampler -i $NEURONSYFLIP -o $NEURONSYFLIPIS -p "#x $ISRX #y $ISRY #z $ISRZ #i 1"
fi

fi

NEURONSYFLIPISRS=${STRN}"_yflipIsRs.v3draw"
if ( is_file_exist "$NEURONSYFLIPISRS" )
then
echo " NEURONSYFLIPISRS: $NEURONSYFLIPISRS exists"
else
#---exe---#
message " Resizing the the neurons to the target "
time $Vaa3D -x ireg -f resizeImage -o $NEURONSYFLIPISRS -p "#s $NEURONSYFLIPIS #t $TARSXEXT #k 1 #i 1 #y 1"
fi

NEURONSYFLIPISRSRT=${STRN}"_yflipIsRsRot.v3draw"
if ( is_file_exist "$NEURONSYFLIPISRSRT" )
then
echo " NEURONSYFLIPISRSRT: $NEURONSYFLIPISRSRT exists"
else
#---exe---#
message " Rotating the neurons "
time $Vaa3D -x ireg -f iwarp2 -o $NEURONSYFLIPISRSRT -p "#s $NEURONSYFLIPISRS #a $RCAFFINE #dx $TARSXEXTDX #dy $TARSXEXTDY #dz $TARSXEXTDZ #i 1"
fi

NEURONSYFLIPISRSRTAFF=${STRN}"_yflipIsRsRotAff.v3draw"
if ( is_file_exist "$NEURONSYFLIPISRSRTAFF" )
then
echo " NEURONSYFLIPISRSRTAFF: $NEURONSYFLIPISRSRTAFF exists"
else
#---exe---#
message " Transforming the neurons "
time $Vaa3D -x ireg -f iwarp2 -o $NEURONSYFLIPISRSRTAFF -p "#s $NEURONSYFLIPISRSRT #a $AFFINEMATRIX #dx $TARSXEXTDX #dy $TARSXEXTDY #dz $TARSXEXTDZ #i 1"
fi

NEURONSYFLIPISRSRTAFFRS=${STRN}"_yflipIsRsRotAffRs.v3draw"
if ( is_file_exist "$NEURONSYFLIPISRSRTAFFRS" )
then
echo " NEURONSYFLIPISRSRTAFFRS: $NEURONSYFLIPISRSRTAFFRS exists"
else
#---exe---#
message " Resize the neurons "
time $Vaa3D -x ireg -f resizeImage -o $NEURONSYFLIPISRSRTAFFRS -p "#s $NEURONSYFLIPISRSRTAFF #t $TARSXRS #k 1 #i 1 #y 1"
fi

NEURONSNII=${STRN}"_yflipIsRsRotAffRs_c0.nii"

NEURONDFMD=${STRN}"NeuronAligned63xScale.nii"
NEURONALIGNEDYFLIP=${OUTPUT}"/NeuronAligned63xScale_yflip.v3draw"
XSNEURONALIGNED_FN="NeuronAligned63xScale.v3draw"
SXNEURONALIGNED=${OUTNEURONS}"/"${XSNEURONALIGNED_FN}
SXNEURONALIGNEDRS=${OUTPUT}"/NeuronAligned63xScaleRS.v3draw"

if ( is_file_exist "$NEURONSNII" )
then
echo "NEURONSNII: $NEURONSNII exists."
else
#---exe---#
message " Converting 63x neurons into Nifti "
time $Vaa3D -x ireg -f NiftiImageConverter -i $NEURONSYFLIPISRSRTAFFRS
echo ""
fi

if ( is_file_exist "$NEURONALIGNEDYFLIP" )
then
echo " NEURONALIGNEDYFLIP: $NEURONALIGNEDYFLIP exists"
else
#---exe---#
message " Warping 63x neurons "
$WARP 3 $NEURONSNII $NEURONDFMD -R $FIXEDNII $FWDDISPFIELD $AFFINEMATRIXLOCAL --use-NN

time $Vaa3D -x ireg -f NiftiImageConverter -i $NEURONDFMD -o $NEURONALIGNEDYFLIP -p "#b 1 #v 2 #r 0"
fi

if ( is_file_exist "$SXNEURONALIGNEDRS" )
then
echo " SXNEURONALIGNEDRS: $SXNEURONALIGNEDRS exists"
else
#---exe---#
message " Resize the neurons to the tamplate's space"
time $Vaa3D -x ireg -f resizeImage -o $SXNEURONALIGNEDRS -p "#s $NEURONALIGNEDYFLIP #t $TARSX #k 1 #i 1 #y 1"
fi

if ( is_file_exist "$SXNEURONALIGNED" )
then
echo " SXNEURONALIGNED: $SXNEURONALIGNED exists"
else
#---exe---#
message " Y-Flipping 63x neurons back "
time $Vaa3D -x ireg -f yflip -i $SXNEURONALIGNEDRS -o $SXNEURONALIGNED
fi

else
echo " SUBSXNEURONS: $SUBSXNEURONS does not exist"
fi

fi

### keep all the transformations

RCAFFINESAVE=${OUTTRANSFORMATIONS}"/rotationsAffine.txt"
AFFINEMATRIXSAVE=${OUTTRANSFORMATIONS}"/txmiAffine.txt"
FWDDISPFIELDSAVE=${OUTTRANSFORMATIONS}"/ccmiWarp.nii.gz"
BWDDISPFIELDSAVE=${OUTTRANSFORMATIONS}"/ccmiInverseWarp.nii.gz"
AFFINEMATRIXLOCALSAVE=${OUTTRANSFORMATIONS}"/ccmiAffine.txt"

cp $RCAFFINE $RCAFFINESAVE
cp $AFFINEMATRIX $AFFINEMATRIXSAVE
# KR 10/6/17: these files are too large to keep around
#cp $FWDDISPFIELD $FWDDISPFIELDSAVE
#cp $BWDDISPFIELD $BWDDISPFIELDSAVE
cp $AFFINEMATRIXLOCAL $AFFINEMATRIXLOCALSAVE


#############
#
### Evaluations
#
#############


AQ=${OUTPUT}"/AlignmentQuality.txt"

if ( is_file_exist "$AQ" )
then
echo " AQ exists"
else
#---exe---#
message " Evaluating "
time $Vaa3D -x ireg -f esimilarity -o $AQ -p "#s $SUBSXALINGED #cs $SUBSXREF #t $TARSX"
fi

while read LINE
do
read SCORE
done < $AQ;


message " Generating Verification Movie "
ALIGNVERIFY=VerifyMovie.mp4
$DIR/createVerificationMovie.sh -c $CONFIGFILE -k $TOOLDIR -w $WORKDIR -s $SUBSXALINGED -i $TARSX -r $SUBSXREF -o ${FINALOUTPUT}/$ALIGNVERIFY

#############
#
### Output Meta
#
#############

### Brains

if [[ -f "$SUBSXALINGED" ]]; then
META=${OUTBRAINS}"/Aligned63xScale.properties"
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
if [[ -f "$SXNEURONALIGNED" ]]; then
    echo "neuron.masks.filename="${XSNEURONALIGNED_FN} >> $META
fi
echo "default=true" >> $META
fi

compressAllRaw $Vaa3D $WORKDIR

# execution time
end=`date +%s.%N`
runtime=$( echo "$end - $start" | bc -l )
echo "brainalign40xMCFO runs $runtime seconds"


