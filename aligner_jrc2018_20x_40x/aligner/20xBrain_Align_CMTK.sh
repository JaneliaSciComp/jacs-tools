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
    local _res="$1"
    local _result_var="$2"
    if [[ $_res == "0.44" ]]; then
        result="0.4413373"
    elif [[ $_res == "0.52" ]]; then
        result="0.5189161"
    elif [[ $_res == "0.62" ]]; then
        result="0.621481"
    else
        result=$_res
    fi
    eval $_result_var="'$result'"
}

export CMTK_WRITE_UNCOMPRESSED=1

# Tools
CMTK=/opt/CMTK/bin
FIJI=/opt/Fiji/ImageJ-linux64
Vaa3D=/opt/Vaa3D/vaa3d

# Fiji macros
NRRDCONV=$DIR"/nrrd2v3draw.ijm"
PREPROCIMG=$DIR"/20x_40x_Brain_Global_Aligner_Pipeline.ijm"
SCOREGENERATION=$DIR"/Score_Generator_Cluster.ijm"

templateBr="JRC2018" #"JFRC2014", "JFRC2013", "JFRC2014", "JRC2018"

filename="PRE_PROCESSED"
Path=$INPUT1_FILE
objective=$INPUT1_OBJECTIVE
expandRes $INPUT1_RESX RESX
expandRes $INPUT1_RESY RESY
expandRes $INPUT1_RESZ RESZ
OUTPUT=$WORK_DIR"/Output"
FINALOUTPUT=$WORK_DIR"/FinalOutputs"
TempDir=$TEMPLATE_DIR/jrc2018_20x_40x_templates
testmode=0

# Possible values: "Intact", "Both_OL_missing (40x)", "Unknown"
BrainShape=$3

if [[ ! -d $OUTPUT ]]; then
    mkdir $OUTPUT
fi

if [[ ! -d $FINALOUTPUT ]]; then
    mkdir $FINALOUTPUT
fi

if [[ ! -e $PREPROCIMG ]]; then
    echo "Preprocess macro could not be found at $PREPROCIMG"
    exit 1
fi

if [[ ! -e $FIJI ]]; then
    echo "Fiji cannot be found at $FIJI"
    exit 1
fi

Unaligned_Neuron_Separator_Result_V3DPBD=$INPUT1_NEURONS
Global_Aligned_Separator_Result=$OUTPUT"/GLOBAL_ConsolidatedLabel.nrrd"

if [[ $RESX == "0.621481" ]]; then
    TRESOLUTION="20x_gen1"
elif [[ $RESX == "0.5189161" ]]; then
    TRESOLUTION="20x_HR"
elif [[ $RESX == "0.4413373" ]]; then
    TRESOLUTION="40x"
fi

echo "TRESOLUTION "$TRESOLUTION

if [[ $GENDER == "f" ]]; then

    genderT="FEMALE"
    JFRC20DPX=$TempDir"/JFRC2013_20x_New_dist_G16.nrrd"
    reformat_JRC2018_to_JFRC20DPX=$TempDir"/Deformation_Fields/JFRC2013_JRC2018_FEMALE_20x_gen1"
    TEMPNAME="JFRC2013"

elif [[ $GENDER == "m" ]]; then

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

if [[ $GENDER == "f" ]]; then
    reformat_JRC2018_to_JFRC2010=$TempDir"/Deformation_Fields/JFRC2010_JRC2018_"$genderT"_20x_gen1"
elif [[ $GENDER == "m" ]]; then
    reformat_JRC2018_to_JFRC2010=$TempDir"/Deformation_Fields/JFRC2010_JRC2018_"$genderT"_40x"
fi

# "Somehow, 20x_gen1 is the best aligned result than the 40x alignment"


# -------------------------------------------------------------------------------------------
OLSHAPE="$OUTPUT/OL_shape.txt"
if [[ -e $OLSHAPE ]]; then
    echo "Already exists: $OLSHAPE"
else
    echo "+---------------------------------------------------------------------------------------+"
    echo "| Running OtsunaBrain preprocessing step"
    echo "| $FIJI -macro $PREPROCIMG \"$OUTPUT/,$filename.,$Path,$TempDir,$RESX,$RESZ,$NSLOTS,$objective,$templateBr,$BrainShape,$Unaligned_Neuron_Separator_Result_V3DPBD\""
    echo "+---------------------------------------------------------------------------------------+"
    START=`date '+%F %T'`
    # Expect to take far less than 1 hour
    #timeout --preserve-status 6000m 
    # Note that this macro does not seem to work in --headless mode
    $FIJI -macro $PREPROCIMG "$OUTPUT/,$filename.,$Path,$TempDir/,$RESX,$RESZ,$NSLOTS,$objective,$templateBr,$BrainShape,$Unaligned_Neuron_Separator_Result_V3DPBD" >$OUTPUT/preproc.log 2>&1

    STOP=`date '+%F %T'`
    echo "Otsuna_Brain preprocessing start: $START"
    echo "Otsuna_Brain preprocessing stop: $STOP"
fi

OL="$(<$OLSHAPE)"
echo $OL

if [[ "$OL" == "Intact" ]]; then
    iniT=$JRC2018_20x
elif [[ "$OL" == "Left_OL_missing" ]]; then
    iniT=$JRC2018_20x_noLOL
elif [[ "$OL" == "Right_OL_missing" ]]; then
    iniT=$JRC2018_20x_noROL
elif [[ "$OL" == "Both_OL_missing" ]]; then
    iniT=$JRC2018_20x_noOL
elif [[ "$OL" == "Both_OL_missing (40x)" ]]; then
    iniT=$JRC2018_20x_noOL
fi

if [[ $GENDER == "f" ]]; then
    if [[ $RESX == "0.621481" ]]; then
        reformat_JRC2018_to_U=$reformat_JRC2018F_gen1_to_U
    elif [[ $RESX == "0.5189161" ]]; then
        reformat_JRC2018_to_U=$reformat_JRC2018F_HR_to_U
    elif [[ $RESX == "0.4413373" ]]; then
        reformat_JRC2018_to_U=$reformat_JRC2018F_40x_to_U
        iniT=$JRC2018_40x_NOOL
    fi
fi

# For TEST ############################################
if [[ $testmode == 1 ]]; then
    gloval_nc82_nrrd=$OUTPUT"/JRC2018MALE_JFRC2014_63x_DistCorrected_01_warp.nrrd"
    iniT=$TempDir"/JFRC2014_63x_DistCorrected_G15.nrrd"
fi

echo "iniT; "$iniT
echo "gloval_nc82_nrrd; "$gloval_nc82_nrrd

# -------------------------------------------------------------------------------------------
if [[ -e $registered_initial_xform ]]; then
    echo "Already exists: $registered_initial_xform"
else
    echo "+---------------------------------------------------------------------------------------+"
    echo "| Running CMTK/make_initial_affine"
    echo "| $iniT $gloval_nc82_nrrd $registered_initial_xform"
    echo "+---------------------------------------------------------------------------------------+"
    START=`date '+%F %T'`
    $CMTK/make_initial_affine --principal_axes $iniT $gloval_nc82_nrrd $registered_initial_xform
    STOP=`date '+%F %T'`
    if [[ ! -e $registered_initial_xform ]]; then
        echo -e "Error: CMTK make initial affine failed"
        exit -1
    fi
    echo "cmtk_initial_affine start: $START"
    echo "cmtk_initial_affine stop: $STOP"

    echo " "
    echo "+----------------------------------------------------------------------+"
    echo "| Running CMTK registration"
    echo "| $CMTK/registration --threads $NSLOTS --initial $registered_initial_xform --dofs 6,9 --auto-multi-levels 4 --accuracy 0.8 -o $registered_affine_xform $iniT $gloval_nc82_nrrd "
    echo "+----------------------------------------------------------------------+"
    START=`date '+%F %T'`
    $CMTK/registration --threads $NSLOTS --initial $registered_initial_xform --dofs 6,9 --accuracy 0.8 -o $registered_affine_xform $iniT $gloval_nc82_nrrd
    STOP=`date '+%F %T'`
    if [[ ! -e $registered_affine_xform ]]; then
        echo -e "Error: CMTK registration failed"
        exit -1
    fi
    echo "cmtk_registration start: $START"
    echo "cmtk_registration stop: $STOP"
fi

# CMTK warping
if [[ -e $registered_warp_xform ]]; then
    echo "Already exists: $registered_warp_xform"
else
    echo " "
    echo "+----------------------------------------------------------------------+"
    echo "| Running CMTK warping"
    echo "| $CMTK/warp --threads $NSLOTS -o $registered_warp_xform --grid-spacing 80 --exploration 30 --coarsest 4 --accuracy 0.8 --refine 4 --energy-weight 1e-1 --initial $registered_affine_xform $iniT $gloval_nc82_nrrd"
    echo "+----------------------------------------------------------------------+"
    START=`date '+%F %T'`
    $CMTK/warp --threads $NSLOTS -o $registered_warp_xform --grid-spacing 80 --fast --exploration 26 --coarsest 8 --accuracy 0.8 --refine 4 --energy-weight 1e-1 --ic-weight 0 --initial $registered_affine_xform $iniT $gloval_nc82_nrrd
    STOP=`date '+%F %T'`
    if [[ ! -e $registered_warp_xform ]]; then
        echo -e "Error: CMTK warping failed"
        exit -1
    fi
    echo "cmtk_warping start: $START"
    echo "cmtk_warping stop: $STOP"
fi


# Convert multiple NRRD files into a single v3draw file.
# Params for this function are the same as for the Fiji macro, a single parameter with comma-delimited file names:
#   "output.v3draw,input1.nrrd,input2.nrrd..."
function nrrd2Raw() {
    local _PARAMS="$1"
    OUTPUTRAW=${_PARAMS%%,*}
    if [[ -e $OUTPUTRAW ]]; then
        echo "Already exists: $OUTPUTRAW"
    else
        TS=`date +%Y%m%d-%H%M%S`
        LOGFILE="$OUTPUT/raw-${TS}.log"
        echo "+----------------------------------------------------------------------+"
        echo "| Running NRRD -> v3draw conversion"
        echo "| $FIJI --headless -macro $NRRDCONV $_PARAMS >$LOGFILE"
        echo "+----------------------------------------------------------------------+"
        START=`date '+%F %T'`
        $FIJI --headless -macro $NRRDCONV $_PARAMS >$LOGFILE 2>&1
        STOP=`date '+%F %T'`
        if [[ ! -e $OUTPUTRAW ]]; then
            echo -e "Error: NRRD -> raw conversion failed"
            exit -1
        fi
        echo "nrrd_raw_conversion start: $START"
        echo "nrrd_raw_conversion stop: $STOP"
    fi
}

# Reformat a single NRRD file to the target deformation field
function reformat() {
    local _TSTRING="$1"
    local _gsig="$2"
    local _TEMP="$3"
    local _DEFFIELD="$4"
    local _sig="$5"
    local _channel="$6"
    local _result_var="$7"

    if [[ -e $_sig ]]; then
        echo "Already exists: $_sig"
    else
        echo " "
        echo "+----------------------------------------------------------------------+"
        echo "| Running CMTK $_TSTRING $_channel reformatting"
        echo "| $CMTK/reformatx -o $_sig --floating $_gsig $_TEMP $_DEFFIELD"
        echo "+----------------------------------------------------------------------+"
        START=`date '+%F %T'`
        $CMTK/reformatx -o "$_sig" --floating $_gsig $_TEMP $_DEFFIELD
        STOP=`date '+%F %T'`

        if [[ ! -e $_sig ]]; then
            echo -e "Error: CMTK reformatting signal failed"
            exit -1
        fi

        echo "cmtk_reformatting $TSTRING $_channel start: $START"
        echo "cmtk_reformatting $TSTRING $_channel stop: $STOP"
    fi
    eval $_result_var="'$_sig'"
}

# Reformat all the channels to the same template
function reformatAll() {
    local _TSTRING="$1"
    local _gsig="$2"
    local _TEMP="$3"
    local _DEFFIELD="$4"
    local _sig="$5"
    local _result_var="$6"

    RAWOUT="${_sig}.v3draw" # Raw output file combining all the aligned channels
    RAWCONVPARAM=$RAWOUT
    RAWCONVSUFFIX=""

    # Reformat each channel
    for ((i=1; i<=$INPUT1_CHANNELS; i++)); do
        GLOBAL_NRRD="${_gsig}_0${i}.nrrd"
        OUTPUT_NRRD="${_sig}_0${i}.nrrd"
        reformat "$_TSTRING" "$GLOBAL_NRRD" "$_TEMP" "$_DEFFIELD" "$OUTPUT_NRRD" "$i" "ignore"
        if (( i>1 )); then
            # Add all signal channels to the final RAW file
            RAWCONVPARAM="$RAWCONVPARAM,$OUTPUT_NRRD"
        else
            # Put reference channel last in RAW file
            RAWCONVSUFFIX="$OUTPUT_NRRD"
        fi
    done

    # Create raw file
    nrrd2Raw "${RAWCONVPARAM},${RAWCONVSUFFIX}"
    eval $_result_var="'$RAWOUT'"
}

# Alignment score generation
function scoreGen() {
    local _outname="$1"
    local _scoretemp="$2"
    local _result_var="$3"

    tempfilename=`basename $_scoretemp`
    tempname=${tempfilename%%.*}
    scorepath="$OUTPUT/${tempname}_Score.property"

    if [[ -e $scorepath ]]; then
        echo "Already exists: $scorepath"
    else
        echo "+---------------------------------------------------------------------------------------+"
        echo "| Running Score generation"
        echo "| $FIJI --headless -macro $SCOREGENERATION $OUTPUT/,$_outname,$NSLOTS,$_scoretemp"
        echo "+---------------------------------------------------------------------------------------+"

        START=`date '+%F %T'`
        # Expect to take far less than 1 hour
        # Alignment Score generation:ZNCC, does not need Xvfb
        $FIJI --headless -macro $SCOREGENERATION $OUTPUT/,$_outname,$NSLOTS,$_scoretemp >$OUTPUT/scoregen.log 2>&1
        STOP=`date '+%F %T'`

        echo "ZNCC JRC2018 score generation start: $START"
        echo "ZNCC JRC2018 score generation stop: $STOP"
    fi

    score=`cat $scorepath`
    eval $_result_var="'$score'"
}

# write output properties for JACS
function writeProperties() {
    local _raw_aligned="$1"
    local _raw_aligned_neurons="$2"
    local _alignment_space="$3"
    local _objective="$4"
    local _voxel_size="$5"
    local _image_size="$6"
    local _ncc_score="$7"

    raw_filename=`basename ${_raw_aligned}`
    prefix=${raw_filename%%.*}

    if [[ -f "$_raw_aligned" ]]; then
        META="${OUTPUT}/${prefix}.properties"
        echo "alignment.stack.filename="${raw_filename} > $META
        echo "alignment.image.area=Brain" >> $META
        echo "alignment.image.channels=$INPUT1_CHANNELS" >> $META
        echo "alignment.image.refchan=$INPUT1_REF" >> $META
        echo "alignment.space.name=$_alignment_space" >> $META
        echo "alignment.image.size=$_image_size" >> $META
        echo "alignment.resolution.voxels=$_voxel_size" >> $META
        echo "alignment.objective=$_objective" >> $META
        if [[ ! -z "$_ncc_score" ]]; then
            echo "alignment.quality.score.ncc=$_ncc_score" >> $META
        fi
        if [[ -e $_raw_aligned_neurons ]]; then
            raw_neurons_filename=`basename ${_raw_aligned_neurons}`
            echo "neuron.masks.filename=$raw_neurons_filename" >> $META
        fi
    fi
}


########################################################################################################
# JRC2018 gender-specific alignment
########################################################################################################

DEFFIELD=$registered_warp_xform
sig=$OUTPUT"/REG_JRC2018_"$genderT"_"$TRESOLUTION
TSTRING="JRC2018 $genderT"
TEMP="$iniT"
gsig=$OUTPUT"/"$filename
reformatAll "$TSTRING" "$gsig" "$TEMP" "$DEFFIELD" "$sig" "RAWOUT"
scoreGen $sig"_01.nrrd" $iniT "score2018"

if [[ -e $Global_Aligned_Separator_Result ]]; then
    prefix=$OUTPUT"/REG_JRC2018_"$genderT"_ConsolidatedLabel_"$TRESOLUTION
    sig=$prefix".nrrd"
    sigraw=$prefix".v3draw"
    gsig=$Global_Aligned_Separator_Result
    TSTRING="JRC2018 "$genderT"_neuron_separator"
    reformat "$TSTRING" "$gsig" "$TEMP" "$DEFFIELD" "$sig" "" "RAWOUT_NEURON"
    nrrd2Raw "$sigraw,$sig"
fi

writeProperties "$RAWOUT" "$RAWOUT_NEURON" "JRC2018_${genderT}_${TRESOLUTION}" "$TRESOLUTION" "0.44x0.44x0.44" "1348x642x472" "$score2018"


########################################################################################################
# JRC2018 unisex alignment
########################################################################################################

DEFFIELD="$reformat_JRC2018_to_Uni $registered_warp_xform"
sig=$OUTPUT"/REG_UNISEX_"$TRESOLUTION
TSTRING="JRC2018 UNISEX"
TEMP="$JRC2018_Unisex"
gsig=$OUTPUT"/"$filename
reformatAll "$TSTRING" "$gsig" "$TEMP" "$DEFFIELD" "$sig" "RAWOUT"

if [[ -e $Global_Aligned_Separator_Result ]]; then
    prefix=$OUTPUT"/REG_UNISEX_ConsolidatedLabel_"$TRESOLUTION
    sig=$prefix".nrrd"
    sigraw=$prefix".v3draw"
    gsig=$Global_Aligned_Separator_Result
    TSTRING="JRC2018 UNISEX_neuron_separator"
    reformat "$TSTRING" "$gsig" "$TEMP" "$DEFFIELD" "$sig" "" "RAWOUT_NEURON"
    nrrd2Raw "$sigraw,$sig"
fi

writeProperties "$RAWOUT" "$RAWOUT_NEURON" "JRC2018_Unisex_${TRESOLUTION}" "$TRESOLUTION" "0.44x0.44x0.44" "1427x668x394" ""


########################################################################################################
# JFRC2010 alignment
########################################################################################################

#"--inverse takes 1.5h / channel for reformatting"
DEFFIELD="$reformat_JRC2018_to_JFRC2010 $registered_warp_xform"
sig=$OUTPUT"/REG_JFRC2010_"$TRESOLUTION
TSTRING="JFRC2010"
TEMP="$JFRC2010"
gsig=$OUTPUT"/"$filename
reformatAll "$TSTRING" "$gsig" "$TEMP" "$DEFFIELD" "$sig" "RAWOUT"

SCORETEMP=$JFRC2010
if [[ "$OL" == "Both_OL_missing (40x)" ]]; then
    SCORETEMP=$JFRC2010NOOL
elif [[ "$OL" == "Both_OL_missing" ]]; then
    SCORETEMP=$JFRC2010NOOL
fi
scoreGen $sig"_01.nrrd" "$SCORETEMP" "score2010"

writeProperties "$RAWOUT" "" "$UNIFIED_SPACE" "20x" "0.62x0.62x1.00" "1024x512x218" $score2010


########################################################################################################
# JFRC2013/JFRC2014 aligmment
########################################################################################################

DEFFIELD="$reformat_JRC2018_to_JFRC20DPX $registered_warp_xform"
sig=$OUTPUT"/REG_"$TEMPNAME"_"$TRESOLUTION
TSTRING="JFRC2013/2014"
TEMP="$JFRC20DPX"
gsig=$OUTPUT"/"$filename
reformatAll "$TSTRING" "$gsig" "$TEMP" "$DEFFIELD" "$sig" "RAWOUT"

if [[ $GENDER =~ "m" ]]; then
    ALIGNMENT_SPACE="JFRC2014_20x"
else
    ALIGNMENT_SPACE="JFRC2013_20x"
fi

writeProperties "$RAWOUT" "" "$ALIGNMENT_SPACE" "20x" "0.4653716x0.4653716x0.76" "1184x592x218" ""


########################################################################################################
# JFRC2018 Unisex High-resolution (for color depth search)
########################################################################################################

DEFFIELD="$reformat_JRC2018_to_Uni $registered_warp_xform"
sig=$OUTPUT"/REG_UNISEX_ColorMIP_HR"
TSTRING="JRC2018 UNISEX HR for ColorMIP"
TEMP=$TempDir"/JRC2018_UNISEX_20x_HR.nrrd"
gsig=$OUTPUT"/"$filename
reformatAll "$TSTRING" "$gsig" "$TEMP" "$DEFFIELD" "$sig" "RAWOUT"

writeProperties "$RAWOUT" "" "JRC2018_Unisex_20x_HR" "20x" "0.5189161x0.5189161x1.0" "1210x566x174" ""


# -------------------------------------------------------------------------------------------

echo "Converting all v3draw files to v3dpbd format"
compressAllRaw "$Vaa3D" "$OUTPUT"


# -------------------------------------------------------------------------------------------

echo "+----------------------------------------------------------------------+"
echo "| Copying files to final destination"
echo "+----------------------------------------------------------------------+"
mkdir -p $FINALOUTPUT/debug
cp $OUTPUT/*.{png,jpg,log,txt} $FINALOUTPUT/debug
cp $OUTPUT/REG*.v3dpbd $FINALOUTPUT
cp $OUTPUT/REG*.properties $FINALOUTPUT

echo "$0 done"


