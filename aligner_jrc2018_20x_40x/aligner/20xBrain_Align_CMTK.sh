#!/bin/bash
#
# 20x 40x brain aligner by Hideo Otsuna
#

DIR=$(cd "$(dirname "$0")"; pwd)
. $DIR/common.sh
parseParameters "$@"

# Available input variables:
#  $TEMPLATE_DIR
#  $WORK_DIR 
#  $INPUT1_FILE
#  $INPUT1_REF
#  $INPUT1_NEURONS
#  $INPUT1_CHANNELS
#  $GENDER
#  $MOUNTING_PROTOCOL
#  $INPUT1_RESX
#  $INPUT1_RESY
#  $INPUT1_RESZ
#  $NSLOTS

function expandRes() {
    local result_var="$1"
    local res="$2"
    if [ $res == "0.44" ]; then
        result="0.4413373"
    elif [ $res == "0.52" ]; then
        result="0.5189161"
    elif [ $res == "0.62" ]; then
        result="0.621481"
    else
        result=$res
    fi
    eval $result_var="'$result'"
}

CMTK=/opt/CMTK/bin/cmtk
FIJI=/opt/Fiji/ImageJ-linux64

BaseDir=$DIR
PREPROCIMG=$BaseDir"/20x_40x_Brain_Global_Aligner_Pipeline.ijm"
SCOREGENERATION=$BaseDir"/Score_Generator_Cluster.ijm"

templateBr="JRC2018"
#"JFRC2014", "JFRC2013", "JFRC2014", "JRC2018"

filename="PRE_PROCESSED"
Path=$INPUT1_FILE
objective=$INPUT1_OBJECTIVE
expandRes RESX $INPUT1_RESX
expandRes RESY $INPUT1_RESY
expandRes RESZ $INPUT1_RESZ
OUTPUT=$WORK_DIR"/Output"
FINALOUTPUT=$WORK_DIR"/FinalOutputs"
TempDir=$TEMPLATE_DIR/jrc2018_20x_40x_templates

# Possible values: "Intact", "Both_OL_missing (40x)", "Unknown"
BrainShape=$3

if [ ! -d $OUTPUT ]; then·
    mkdir $OUTPUT
fi

if [ ! -d $FINALOUTPUT ]; then·
    mkdir $FINALOUTPUT
fi

if [ ! -e $PREPROCIMG ]; then
    echo "Preprocess macro could not be found at $PREPROCIMG"
    exit 1
fi

if [ ! -e $FIJI ]; then
    echo "Fiji cannot be found at $FIJI"
    exit 1
fi

Unaligned_Neuron_Separator_Result_V3DPBD=$INPUT1_NEURONS
Global_Aligned_Separator_Result=$OUTPUT"/GLOBAL_ConsolidatedLabel.nrrd"

if [ $RESX == "0.621481" ]; then
    TRESOLUTION="20x_gen1"
elif [ $RESX == "0.5189161" ]; then
    TRESOLUTION="20x_HR"
elif [ $RESX == "0.4413373" ]; then
    TRESOLUTION="40x"
fi

echo "TRESOLUTION "$TRESOLUTION

if [ $GENDER == "f" ]; then
    
    genderT="FEMALE"
    JFRC20DPX=$TempDir"/JFRC2013_20x_New_dist_G16.nrrd"
    reformat_JRC2018_to_JFRC20DPX=$TempDir"/Deformation_Fields/JFRC2013_JRC2018_FEMALE_20x_gen1"
    TEMPNAME="JFRC2013"

elif [ $GENDER == "m" ]; then
    
    genderT="MALE"
    JFRC20DPX=$TempDir"/JFRC2014_20x_New_dist_G15.nrrd"
    reformat_JRC2018_to_JFRC20DPX=$TempDir"/Deformation_Fields/JFRC2014_JRC2018_MALE_40x"
    TEMPNAME="JFRC2014"

fi

echo "GENDER; "$GENDER
echo "genderT; "$genderT
echo "JFRC20DPX; "$JFRC20DPX
echo "reformat_JRC2018_to_JFRC20DPX; "$reformat_JRC2018_to_JFRC20DPX

# "-------------------Template----------------------"
JRC2018_20x=$TempDir"/JRC2018_"$genderT"_"$TRESOLUTION".nrrd"
JRC2018_20x_noLOL=$TempDir"/JRC2018_"$genderT"_"$TRESOLUTION"_noLOL.nrrd"
JRC2018_20x_noROL=$TempDir"/JRC2018_"$genderT"_"$TRESOLUTION"_noROL.nrrd"
JRC2018_20x_noOL=$TempDir"/JRC2018_"$genderT"_"$TRESOLUTION"_noOL.nrrd"

JRC2018_40x=$TempDir"/JRC2018_"$genderT"_"$TRESOLUTION".nrrd"
JRC2018_40x_NOOL=$TempDir"/JRC2018_"$genderT"_"$TRESOLUTION"_noOL.nrrd"

JRC2018_Unisex=$TempDir"/JRC2018_UNISEX_"$TRESOLUTION".nrrd"

JFRC2010=$TempDir"/JFRC2010_16bit.nrrd"
JFRC2010NOOL=$TempDir"/JFRC2010_16bit_noOL.nrrd"

# "-------------------Global aligned files----------------------"

gloval_nc82_nrrd=$OUTPUT"/"$filename"_01.nrrd"
gloval_signalNrrd1=$OUTPUT"/"$filename"_02.nrrd"
gloval_signalNrrd2=$OUTPUT"/"$filename"_03.nrrd"
gloval_signalNrrd3=$OUTPUT"/"$filename"_04.nrrd"


# "-------------------Deformation fields----------------------"
registered_initial_xform=$OUTPUT"/initial.xform"
registered_affine_xform=$OUTPUT"/affine.xform"
registered_warp_xform=$OUTPUT"/warp.xform"

reformat_JRC2018_to_Uni=$TempDir"/Deformation_Fields/JRC2018_Unisex_JRC2018_"$genderT"_"$TRESOLUTION

if [ $GENDER == "f" ]; then
    reformat_JRC2018_to_JFRC2010=$TempDir"/Deformation_Fields/JFRC2010_JRC2018_"$genderT"_20x_gen1"
elif [ $GENDER == "m" ]; then
    reformat_JRC2018_to_JFRC2010=$TempDir"/Deformation_Fields/JFRC2010_JRC2018_"$genderT"_40x"
fi

# "Somehow, 20x_gen1 is the best aligned result than the 40x alignment"


# Ensure existence of required inputs from unaligned neuron separation.
UNSR_TO_DEL="sentinel_nonexistent_file"
UNALIGNED_NEUSEP_EXISTS=1
if [ ! -e $Unaligned_Neuron_Separator_Result_V3DPBD ]; then
echo -e "Warning: unaligned neuron separation result $Unaligned_Neuron_Separator_Result_V3DPBD nor $Unaligned_Neuron_Separator_Result_RAW exists. Perhaps user has deleted neuron separations?"
UNALIGNED_NEUSEP_EXISTS=0
fi


# -------------------------------------------------------------------------------------------
echo "+---------------------------------------------------------------------------------------+"
echo "| Running OtsunaBrain preprocessing step                                                     |"
echo "| $FIJI -macro $PREPROCIMG \"$OUTPUT/,$filename.,$Path,$TempDir,$RESX,$RESZ,$NSLOTS,$objective\" |"
echo "+---------------------------------------------------------------------------------------+"
START=`date '+%F %T'`
# Expect to take far less than 1 hour
if [ ! -e $Unaligned_Neuron_Separator_Result_RAW ]
then
echo "Warning: $PREPROCIMG will be given a nonexistent $Unaligned_Neuron_Separator_Result_V3DPBD"
fi

#timeout --preserve-status 6000m 

$FIJI -macro $PREPROCIMG "$OUTPUT/,$filename.,$Path,$TempDir/,$RESX,$RESZ,$NSLOTS,$objective,$templateBr,$BrainShape,$Unaligned_Neuron_Separator_Result_V3DPBD"

STOP=`date '+%F %T'`
echo "Otsuna_Brain preprocessing start: $START"
echo "Otsuna_Brain preprocessing stop: $STOP"

OL="$(<$OUTPUT/OL_shape.txt)"
echo $OL

if [ "$OL" == "Intact" ]
 then
 iniT=$JRC2018_20x
fi

if [ "$OL" == "Left_OL_missing" ]
 then
 iniT=$JRC2018_20x_noLOL
fi

if [ "$OL" == "Right_OL_missing" ]
 then
 iniT=$JRC2018_20x_noROL
fi

if [ "$OL" == "Both_OL_missing" ]
 then
 iniT=$JRC2018_20x_noOL
fi

if [ "$OL" == "Both_OL_missing (40x)" ]
then
iniT=$JRC2018_20x_noOL
fi

#exit -1

if [ $GENDER == "f" ]; then
 if [ $RESX == "0.621481" ]; then
  reformat_JRC2018_to_U=$reformat_JRC2018F_gen1_to_U
 elif [ $RESX == "0.5189161" ]; then
  reformat_JRC2018_to_U=$reformat_JRC2018F_HR_to_U
 elif [ $RESX == "0.4413373" ]; then
  reformat_JRC2018_to_U=$reformat_JRC2018F_40x_to_U
  iniT=$JRC2018_40x_NOOL
 fi
fi

# For TEST ############################################
if [ $testmode == 1 ]
then
gloval_nc82_nrrd=$OUTPUT"/JRC2018MALE_JFRC2014_63x_DistCorrected_01_warp.nrrd"
iniT=$TempDir"/JFRC2014_63x_DistCorrected_G15.nrrd"
fi

echo "iniT; "$iniT
echo "gloval_nc82_nrrd; "$gloval_nc82_nrrd

# -------------------------------------------------------------------------------------------
echo "+---------------------------------------------------------------------------------------+"
echo "| Running CMTK/make_initial_affine                                                      |"
echo "| $iniT $gloval_nc82_nrrd $registered_initial_xform |"
echo "+---------------------------------------------------------------------------------------+"
START=`date '+%F %T'`
$CMTK/make_initial_affine --principal_axes $iniT $gloval_nc82_nrrd $registered_initial_xform
STOP=`date '+%F %T'`
if [ ! -e $registered_initial_xform ]
then
echo -e "Error: CMTK make initial affine failed"
exit -1
fi
echo "cmtk_initial_affine start: $START"
echo "cmtk_initial_affine stop: $STOP"


# CMTK registration
echo " "
echo "+----------------------------------------------------------------------+"
echo "| Running CMTK registration                                            |"
echo "| $CMTK/registration --threads $NSLOTS --initial $registered_initial_xform --dofs 6,9 --auto-multi-levels 4 --accuracy 0.8 -o $registered_affine_xform $iniT $gloval_nc82_nrrd |"
echo "+----------------------------------------------------------------------+"
START=`date '+%F %T'`
$CMTK/registration --threads $NSLOTS --initial $registered_initial_xform --dofs 6,9 --accuracy 0.8 -o $registered_affine_xform $iniT $gloval_nc82_nrrd
STOP=`date '+%F %T'`
if [ ! -e $registered_affine_xform ]
then
echo -e "Error: CMTK registration failed"
exit -1
fi
echo "cmtk_registration start: $START"
echo "cmtk_registration stop: $STOP"

# CMTK warping
echo " "
echo "+----------------------------------------------------------------------+"
echo "| Running CMTK warping                                                 |"
echo "| $CMTK/warp --threads $NSLOTS -o $registered_warp_xform --grid-spacing 80 --exploration 30 --coarsest 4 --accuracy 0.8 --refine 4 --energy-weight 1e-1 --initial $registered_affine_xform $iniT $gloval_nc82_nrrd |"
echo "+----------------------------------------------------------------------+"
START=`date '+%F %T'`
$CMTK/warp --threads $NSLOTS -o $registered_warp_xform --grid-spacing 80 --fast --exploration 26 --coarsest 8 --accuracy 0.8 --refine 4 --energy-weight 1e-1 --ic-weight 0 --initial $registered_affine_xform $iniT $gloval_nc82_nrrd
STOP=`date '+%F %T'`
if [ ! -e $registered_warp_xform ]
then
echo -e "Error: CMTK warping failed"
exit -1
fi
echo "cmtk_warping start: $START"
echo "cmtk_warping stop: $STOP"

#"for TEST"
#exit -1

export CMTK_WRITE_UNCOMPRESSED=1

for d in 1 2 3 4 5
do

# i for 1 2 3 4 5
for i in 1 
do

if [ $d == 1 ]
then
DEFFIELD=$registered_warp_xform
sig=$OUTPUT"/REG_JRC2018_"$genderT"_"$TRESOLUTION"_0"$i".nrrd"
echo "d==1"
TSTRING="JRC2018 $genderT"
TEMP="$iniT"
gsig=$OUTPUT"/"$filename"_0"$i".nrrd"

if [ $i == 5 ]
then 
if [ -e $Global_Aligned_Separator_Result ]
then 

sig=$OUTPUT"/REG_JRC2018_"$genderT"_ConsolidatedLabel_"$TRESOLUTION".nrrd"
gsig=$Global_Aligned_Separator_Result
TSTRING="JRC2018 "$genderT"_neuron_seprator"
fi

fi
fi

if [ $d == 2 ]
then
DEFFIELD="$reformat_JRC2018_to_Uni $registered_warp_xform"
sig=$OUTPUT"/REG_UNISEX_"$TRESOLUTION"_0"$i".nrrd"
TSTRING="JRC2018 UNISEX"
TEMP="$JRC2018_Unisex"
gsig=$OUTPUT"/"$filename"_0"$i".nrrd"

if [ $i == 5 ]
then 
if [ -e $Global_Aligned_Separator_Result ]
then 

sig=$OUTPUT"/REG_UNISEX_ConsolidatedLabel_"$TRESOLUTION".nrrd"
gsig=$Global_Aligned_Separator_Result
TSTRING="JRC2018 UNISEX_neuron_seprator"
fi

fi
fi

if [ $d == 3 ]
then

#"--inverse takes 1.5h / channel for reformatting"

DEFFIELD="$reformat_JRC2018_to_JFRC2010 $registered_warp_xform"
sig=$OUTPUT"/REG_JFRC2010_"$TRESOLUTION"_0"$i".nrrd"
TSTRING="JFRC2010"
TEMP="$JFRC2010"
gsig=$OUTPUT"/"$filename"_0"$i".nrrd"
#gsig=$OUTPUT"/JRC2018MALE40x_JFRC2010_16bit_G16_01_warp.nrrd"
fi

if [ $d == 4 ]
then

DEFFIELD="$reformat_JRC2018_to_JFRC20DPX $registered_warp_xform"
sig=$OUTPUT"/REG_"$TEMPNAME"_"$TRESOLUTION"_0"$i".nrrd"
TSTRING="JFRC2013/2014"
TEMP="$JFRC20DPX"
#"$JFRC20DPX"
#gsig="$gloval_nc82_nrrd"
#echo "gsig; "$gsig
gsig=$OUTPUT"/"$filename"_0"$i".nrrd"
fi

if [ $d == 5 ]
then

DEFFIELD="$reformat_JRC2018_to_Uni $registered_warp_xform"
sig=$OUTPUT"/REG_UNISEX_ColorMIP_HR_0"$i".nrrd"
TSTRING="JRC2018 UNISEX HR for ColorMIP"
TEMP=$TempDir"/JRC2018_UNISEX_20x_HR.nrrd"
gsig=$OUTPUT"/"$filename"_0"$i".nrrd"
fi

# ------------ For Test ------------------
if [ $testmode == 1 ]
then
gsig=$gloval_nc82_nrrd
fi

if [ -e $gsig ]
then
# CMTK reformatting
echo " "
echo "+----------------------------------------------------------------------+"
echo "| Running CMTK $TSTRING $i reformatting                                            |"
echo "| $CMTK/reformatx -o $sig --floating $gsig $TEMP $DEFFIELD |"
echo "+----------------------------------------------------------------------+"
START=`date '+%F %T'`
$CMTK/reformatx -o "$sig" --floating $gsig $TEMP $DEFFIELD

STOP=`date '+%F %T'`
if [ ! -e $sig ]
then
echo -e "Error: CMTK reformatting signal "$i" failed"
exit -1
fi
echo "cmtk_reformatting $TSTRING "$i" start: $START"
echo "cmtk_reformatting $TSTRING "$i" stop: $STOP"

fi
done
done


#exit -1
# "--------------- Score generation ---------------"
for s in 1 2
do

if [ $s == 1 ]
then
OUTNAME="$OUTPUT/REG_JRC2018_"$genderT"_"$TRESOLUTION"_01.nrrd"
SCORETEMP=$iniT
fi

if [ $s == 2 ]
then
OUTNAME="$OUTPUT/REG_JFRC2010_"$TRESOLUTION"_01.nrrd"
SCORETEMP=$JFRC2010

if [ "$OL" == "Both_OL_missing (40x)" ]
then
SCORETEMP=$JFRC2010NOOL
fi

if [ "$OL" == "Both_OL_missing" ]
then
SCORETEMP=$JFRC2010NOOL
fi
fi

# -------------------------------------------------------------------------------------------
echo "+---------------------------------------------------------------------------------------+"
echo "| Running Score generation $JRC2018_20x                                                    |"
echo "| $FIJI -macro $SCOREGENERATION "$OUTPUT/,$OUTNAME,$NSLOTS,$SCORETEMP" |"
echo "+---------------------------------------------------------------------------------------+"
START=`date '+%F %T'`
# Expect to take far less than 1 hour
if [ ! -e $Unaligned_Neuron_Separator_Result_RAW ]
then
echo "Warning: Alignement Score generation:ZNCC, does not need Xvfb"
fi

#timeout --preserve-status 6000m 

$FIJI -macro $SCOREGENERATION $OUTPUT/,$OUTNAME,$NSLOTS,$SCORETEMP

STOP=`date '+%F %T'`
echo "ZNCC JRC2018 score generation start: $START"
echo "ZNCC JRC2018 score generation stop: $STOP"

done


echo "+----------------------------------------------------------------------+"
echo "| Copying file to final destination                                    |"
echo "+----------------------------------------------------------------------+"
cp -R $OUTPUT/AlignedFlyBrain* $FINALOUTPUT

if [[ -f "$registered_pp_warp_v3draw" ]]; then

    META=${FINALOUTPUT}"/AlignedFlyBrain.properties"
    echo "alignment.stack.filename="${registered_pp_warp_v3draw_filename} >> $META
    echo "alignment.image.area=Brain" >> $META
    echo "alignment.image.channels=$INPUT1_CHANNELS" >> $META
    echo "alignment.image.refchan=$INPUT1_REF" >> $META
    if [[ $GENDER =~ "m" ]]
    then
        # male fly brain
        echo "alignment.space.name=JRC2018_Male_20x" >> $META
    else
        # female fly brain
        echo "alignment.space.name=JRC2018_Female_20x" >> $META
    fi
    echo "alignment.otsuna.object.pearson.coefficient=$OTSUNA_PEARSON_COEFF" >> $META
    echo "alignment.overlap.coefficient=$OVERLAP_COEFF" >> $META
    echo "alignment.object.pearson.coefficient=$PEARSON_COEFF" >> $META
    echo "alignment.resolution.voxels=0.52x0.52x1.00" >> $META
    echo "alignment.image.size=512x1024x185" >> $META
    echo "alignment.objective=20x" >> $META
    if [ -e $Aligned_Consolidated_Label_V3DPBD ]; then
        echo "neuron.masks.filename=$CONSLABEL_FN" >> $META
    else
        echo "WARNING: No $CONSLABEL_FN produced."
    fi
    echo "default=true" >> $META
fi

# TODO: need to compress raws?
#compressAllRaw $Vaa3D $WORKDIR


