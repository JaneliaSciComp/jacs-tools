#!/bin/bash
#
# 20x 40x brain aligner by Hideo Otsuna
#

DIR=$(cd "$(dirname "$0")"; pwd)
. $DIR/common.sh
parseParameters "$@"
# Possible values: "Intact", "Both_OL_missing (40x)", "Unknown"
BrainShape=$3

# Available input variables:
#  $TEMPLATE_DIR
#  $WORK_DIR
#  $INPUT1_FILE
#  $INPUT1_REF
#  $INPUT1_NEURONS
#  $INPUT1_CHANNELS
#  $INPUT1_GENDER
#  $INPUT1_MOUNTING_PROTOCOL
#  $INPUT1_RESX
#  $INPUT1_RESY
#  $INPUT1_RESZ
#  $NSLOTS

export CMTK_WRITE_UNCOMPRESSED=1

# Tools
CMTK=/opt/CMTK/bin
FIJI=/opt/Fiji/ImageJ-linux64
Vaa3D=/opt/Vaa3D/vaa3d

# Fiji macros
NRRDCONV=$DIR"/nrrd2v3draw.ijm"
PREPROCIMG=$DIR"/20x_40x_Brain_Global_Aligner_Pipeline.ijm"
TWELVEBITCONV=$DIR"/12bit_Conversion.ijm"
SCOREGENERATION=$DIR"/Score_Generator_Cluster.ijm"

templateBr="JRC2018" #"JFRC2014", "JFRC2013", "JFRC2014", "JRC2018"
filename="PRE_PROCESSED"
Path=$INPUT1_FILE
objective=$INPUT1_OBJECTIVE
OUTPUT=$WORK_DIR"/Output"
FINALOUTPUT=$WORK_DIR"/FinalOutputs"
TempDir=$TEMPLATE_DIR/jrc2018_20x_40x_templates
testmode=0

#
# Expand resolutions from TMOG
#
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

#
# Reverse a stack in some dimension
# The third argument can be "xflip", "yflip", or "zflip"
#
function flip() {
    local _input="$1"
    local _output="$2"
    local _op="$3"
    if [[ -e $_output ]]; then
        echo "Already exists: $_output"
    else
        #---exe---#
        message " Flipping $_input with $_op"
        $Vaa3D -x ireg -f $_op -i $_input -o $_output
        echo ""
    fi
}

# Reformat a single NRRD file to the target deformation field
function reformat() {
    local _gsig="$1"
    local _TEMP="$2"
    local _DEFFIELD="$3"
    local _sig="$4"
    local _channel="$5"
    local _result_var="$6"
    local _opts="$7"

    if [[ -e $_sig ]]; then
        echo "Already exists: $_sig"
    else
        echo "--------------"
        echo "Running CMTK reformatting on channel $_channel"
        echo "$CMTK/reformatx --threads $NSLOTS -o $_sig $_opts --floating $_gsig $_TEMP $_DEFFIELD"
        START=`date '+%F %T'`
        $CMTK/reformatx --threads $NSLOTS -o "$_sig" $_opts --floating $_gsig $_TEMP $_DEFFIELD
        STOP=`date '+%F %T'`

        if [[ ! -e $_sig ]]; then
            echo -e "Error: CMTK reformatting signal failed"
            exit -1
        fi

        echo "--------------"
        echo "cmtk_reformatting $TSTRING $_channel start: $START"
        echo "cmtk_reformatting $TSTRING $_channel stop: $STOP"
        echo " "
    fi
    eval $_result_var="'$_sig'"
}

# Reformat all the channels to the same template
function reformatAll() {
    local _gsig="$1"
    local _TEMP="$2"
    local _DEFFIELD="$3"
    local _sig="$4"
    local _result_var="$5"
    local _opts="$6"

    RAWOUT="${_sig}.v3draw" # Raw output file combining all the aligned channels
    RAWCONVPARAM=$RAWOUT
    RAWCONVSUFFIX=""

    # Reformat each channel
    for ((i=1; i<=$INPUT1_CHANNELS; i++)); do
        GLOBAL_NRRD="${_gsig}_0${i}.nrrd"
        OUTPUT_NRRD="${_sig}_0${i}.nrrd"
        reformat "$GLOBAL_NRRD" "$_TEMP" "$_DEFFIELD" "$OUTPUT_NRRD" "$i" "ignore" "$opts"
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
    local _bridged_from="$8"

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
        if [[ ! -z "$_bridged_from" ]]; then
            echo "alignment.bridged.from=$_bridged_from" >> $META
        fi
    fi
}

# write output properties for JACS
function writeErrorProperties() {
    local _prefix="$1"
    local _alignment_space="$2"
    local _objective="$3"
    local _error="$4"

    META="${FINALOUTPUT}/${_prefix}.properties"
    echo "alignment.error="${_error} > $META
    echo "alignment.image.area=Brain" >> $META
    echo "alignment.space.name=$_alignment_space" >> $META
    echo "alignment.objective=$_objective" >> $META
}


function banner() {
    echo "------------------------------------------------------------------------------------------------------------"
    echo " $1"
    echo "------------------------------------------------------------------------------------------------------------"
}


# Main Script

expandRes $INPUT1_RESX RESX
expandRes $INPUT1_RESY RESY
expandRes $INPUT1_RESZ RESZ

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

if [[ $INPUT1_GENDER == "f" ]]; then
    genderT="FEMALE"
    JFRC20DPX=$TempDir"/JFRC2013_20x_New_dist_G16.nrrd"
    reformat_JRC2018_to_JFRC20DPX=$TempDir"/Deformation_Fields/JFRC2013_JRC2018_FEMALE_20x_gen1"
    TEMPNAME="JFRC2013"
elif [[ $INPUT1_GENDER == "m" ]]; then
    genderT="MALE"
    JFRC20DPX=$TempDir"/JFRC2014_20x_New_dist_G15.nrrd"
    reformat_JRC2018_to_JFRC20DPX=$TempDir"/Deformation_Fields/JFRC2014_JRC2018_MALE_40x"
    TEMPNAME="JFRC2014"
fi

if [[ $RESX == "0.621481" ]]; then
    TRESOLUTION="20x_gen1"
elif [[ $RESX == "0.5189161" ]]; then
    TRESOLUTION="20x_HR"
elif [[ $RESX == "0.4413373" ]]; then
    TRESOLUTION="40x"
else

    gapGen1=$(echo "$RESX-0.621481" | bc -l)
    gapMCFO=$(echo "$RESX-0.5189161" | bc -l)
    gap40x=$(echo "$RESX-0.4413373" | bc -l)

    if [[ 0${gapGen1#-} < 0${gapMCFO#-} ]]; then
        TRESOLUTION="20x_gen1"
    fi

    if [[ 0${gapMCFO#-} < 0${gapGen1#-} ]]; then
        TRESOLUTION="20x_HR"
        if [[ 0${gap40x#-} < 0${gapMCFO#-} ]]; then
            TRESOLUTION="40x"
        fi
    fi
fi

echo "TRESOLUTION: "$TRESOLUTION

echo "INPUT1_GENDER; "$INPUT1_GENDER
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

reformat_JRC2018_to_Uni=$TempDir"/Deformation_Fields/JRC2018_Unisex_JRC2018_"$genderT"_40x"

if [[ $INPUT1_GENDER == "f" ]]; then
    reformat_JRC2018_to_JFRC2010=$TempDir"/Deformation_Fields/JFRC2010_JRC2018_"$genderT"_20x_gen1"
elif [[ $INPUT1_GENDER == "m" ]]; then
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
    # check for prealigner errors
    LOGFILE="${OUTPUT}/20x_brain_pre_aligner_log.txt"
    PreAlignerError=`grep "PreAlignerError: " $LOGFILE | head -n1 | sed "s/PreAlignerError: //"`
    if [[ ! -z "$PreAlignerError" ]]; then
        writeErrorProperties "PreAlignerError" "JRC2018_${genderT}" "$objective" "$PreAlignerError"
        exit 0
    fi
fi

OL="$(<$OLSHAPE)"
echo "OLSHAPE; "$OL

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

# For TEST ############################################
if [[ $testmode == 1 ]]; then
    gloval_nc82_nrrd=$OUTPUT"/JRC2018MALE_JFRC2014_63x_DistCorrected_01_warp.nrrd"
    iniT=$TempDir"/JFRC2014_63x_DistCorrected_G15.nrrd"
fi

echo "iniT; "$iniT
echo "gloval_nc82_nrrd; "$gloval_nc82_nrrd
echo ""

# -------------------------------------------------------------------------------------------
if [[ -e $registered_initial_xform ]]; then
    echo "Already exists: $registered_initial_xform"
else
    echo "+---------------------------------------------------------------------------------------+"
    echo "| Running CMTK/make_initial_affine"
    echo "| $CMTK/make_initial_affine --threads $NSLOTS --principal_axes $iniT $gloval_nc82_nrrd $registered_initial_xform"
    echo "+---------------------------------------------------------------------------------------+"
    START=`date '+%F %T'`
    $CMTK/make_initial_affine --threads $NSLOTS --principal_axes $iniT $gloval_nc82_nrrd $registered_initial_xform
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

echo " "
echo "+----------------------------------------------------------------------+"
echo "| 12-bit conversion"
echo "| $FIJI -macro $TWELVEBITCONV \"${OUTPUT}/,${filename}_01.nrrd,${gloval_nc82_nrrd}\""
echo "+----------------------------------------------------------------------+"
$FIJI --headless -macro $TWELVEBITCONV "${OUTPUT}/,${filename}_01.nrrd,${gloval_nc82_nrrd}" > $OUTPUT/conv12bit.log 2>&1

########################################################################################################
# JRC2018 gender-specific alignment
########################################################################################################

banner "JRC2018 $genderT alignment"
FLIP_NEURON=""
DEFFIELD=$registered_warp_xform
fn="REG_JRC2018_"$genderT"_"$TRESOLUTION
main_aligned_file=${fn}".v3draw"
sig=$OUTPUT"/"$fn
TEMP="$iniT"
gsig=$OUTPUT"/"$filename
reformatAll "$gsig" "$TEMP" "$DEFFIELD" "$sig" "RAWOUT"
scoreGen $sig"_01.nrrd" $iniT "score2018"

if [[ -e $Global_Aligned_Separator_Result ]]; then
    prefix="${OUTPUT}/${fn}_ConsolidatedLabel"
    sig=$prefix".nrrd"
    RAWOUT_NEURON=$prefix"_flipped.v3draw"
    gsig=$Global_Aligned_Separator_Result
    reformat "$gsig" "$TEMP" "$DEFFIELD" "$sig" "" "ignore" "--nn"
    nrrd2Raw "$RAWOUT_NEURON,$sig"
    FLIP_NEURON=$prefix".v3draw"
    # flip neurons back to Neuron Annotator format
    flip "$RAWOUT_NEURON" "$FLIP_NEURON" "yflip"
    rm $RAWOUT_NEURON
fi

writeProperties "$RAWOUT" "" "JRC2018_${genderT}_${TRESOLUTION}" "$TRESOLUTION" "0.44x0.44x0.44" "1348x642x472" "$score2018" ""


########################################################################################################
# JRC2018 unisex alignment
########################################################################################################
if [[ $TRESOLUTION != "20x_gen1" ]]; then

    banner "JRC2018 unisex alignment"
    FLIP_NEURON=""
    DEFFIELD="$reformat_JRC2018_to_Uni $registered_warp_xform"
    fn="REG_UNISEX_"$TRESOLUTION
    sig=$OUTPUT"/"$fn
    TEMP="$JRC2018_Unisex"
    gsig=$OUTPUT"/"$filename
    reformatAll "$gsig" "$TEMP" "$DEFFIELD" "$sig" "RAWOUT"

    if [[ -e $Global_Aligned_Separator_Result ]]; then
        prefix=$sig"_ConsolidatedLabel"
        sig=$prefix".nrrd"
        RAWOUT_NEURON=$prefix"_flipped.v3draw"
        gsig=$Global_Aligned_Separator_Result
        reformat "$gsig" "$TEMP" "$DEFFIELD" "$sig" "" "ignore" "--nn"
        nrrd2Raw "$RAWOUT_NEURON,$sig"
        FLIP_NEURON=$prefix".v3draw"
        # flip neurons back to Neuron Annotator format
        flip "$RAWOUT_NEURON" "$FLIP_NEURON" "yflip"
        rm $RAWOUT_NEURON
    fi

    writeProperties "$RAWOUT" "$FLIP_NEURON" "JRC2018_Unisex_${TRESOLUTION}" "$TRESOLUTION" "0.44x0.44x0.44" "1427x668x394" "" "$main_aligned_file"
fi



########################################################################################################
# JFRC2010 alignment
########################################################################################################

banner "JFRC2010 alignment"
#"--inverse takes 1.5h / channel for reformatting"
DEFFIELD="$reformat_JRC2018_to_JFRC2010 $registered_warp_xform"
sig=$OUTPUT"/REG_JFRC2010_"$TRESOLUTION
TEMP="$JFRC2010"
gsig=$OUTPUT"/"$filename
reformatAll "$gsig" "$TEMP" "$DEFFIELD" "$sig" "RAWOUT"

SCORETEMP=$JFRC2010
if [[ "$OL" == "Both_OL_missing (40x)" ]]; then
    SCORETEMP=$JFRC2010NOOL
elif [[ "$OL" == "Both_OL_missing" ]]; then
    SCORETEMP=$JFRC2010NOOL
fi
scoreGen $sig"_01.nrrd" "$SCORETEMP" "score2010"

writeProperties "$RAWOUT" "" "$UNIFIED_SPACE" "20x" "0.62x0.62x1.00" "1024x512x218" "$score2010" "$main_aligned_file"


########################################################################################################
# JFRC2013/JFRC2014 aligmment
########################################################################################################

banner "JFRC2013/JFRC2014 aligmment"
DEFFIELD="$reformat_JRC2018_to_JFRC20DPX $registered_warp_xform"
sig=$OUTPUT"/REG_"$TEMPNAME"_"$TRESOLUTION
TEMP="$JFRC20DPX"
gsig=$OUTPUT"/"$filename
reformatAll "$gsig" "$TEMP" "$DEFFIELD" "$sig" "RAWOUT"

if [[ $INPUT1_GENDER =~ "m" ]]; then
    ALIGNMENT_SPACE="JFRC2014_20x"
else
    ALIGNMENT_SPACE="JFRC2013_20x"
fi

writeProperties "$RAWOUT" "" "$ALIGNMENT_SPACE" "20x" "0.4653716x0.4653716x0.76" "1184x592x218" "" "$main_aligned_file"


########################################################################################################
# JFRC2018 Unisex High-resolution (for color depth search)
########################################################################################################
if [[ $TRESOLUTION != "20x_HR" ]]; then

    banner "JFRC2018 Unisex High-resolution (for color depth search)"
    DEFFIELD="$reformat_JRC2018_to_Uni $registered_warp_xform"
    sig=$OUTPUT"/REG_UNISEX_ColorMIP_HR"
    TEMP=$TempDir"/JRC2018_UNISEX_20x_HR.nrrd"
    gsig=$OUTPUT"/"$filename
    reformatAll "$gsig" "$TEMP" "$DEFFIELD" "$sig" "RAWOUT"

    writeProperties "$RAWOUT" "" "JRC2018_Unisex_20x_HR" "20x" "0.5189161x0.5189161x1.0" "1210x566x174" "" "$main_aligned_file"

fi

# -------------------------------------------------------------------------------------------

echo "Converting all v3draw files to v3dpbd format"
compressAllRaw "$Vaa3D" "$OUTPUT"


# -------------------------------------------------------------------------------------------

echo "+----------------------------------------------------------------------+"
echo "| Copying files to final destination"
echo "+----------------------------------------------------------------------+"
mkdir -p $FINALOUTPUT/debug
cp $OUTPUT/*.{png,jpg,log,txt} $FINALOUTPUT/debug
cp -R $OUTPUT/*.xform $FINALOUTPUT/debug
cp $OUTPUT/REG*.v3dpbd $FINALOUTPUT
cp $OUTPUT/REG*.properties $FINALOUTPUT

echo "$0 done"


