#!/bin/bash
#
# 20x 40x VNC aligner by Hideo Otsuna
#
testmode=0

if [[ $testmode != 1 ]]; then
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
  #  $INPUT1_GENDER
  #  $INPUT1_MOUNTING_PROTOCOL
  #  $INPUT1_RESX
  #  $INPUT1_RESY
  #  $INPUT1_RESZ
  #  $NSLOTS
fi

export CMTK_WRITE_UNCOMPRESSED=1

# Tools
CMTK=/opt/CMTK/bin
FIJI=/opt/Fiji/ImageJ-linux64
Vaa3D=/opt/Vaa3D/vaa3d
MACRO_DIR=/opt/aligner/fiji_macros

# Fiji macros
NRRDCONV=$MACRO_DIR"/nrrd2v3draw.ijm"
PREPROCIMG=$MACRO_DIR"/VNC_preImageProcessing_Pipeline_02_02_2017.ijm"
SCOREGENERATION=$MACRO_DIR"/Score_Generator_Cluster.ijm"
TWELVEBITCONV=$MACRO_DIR"/12bit_Conversion.ijm"

templateBr="JRC2018_VNC_FEMALE" #"VNC_FEMALE_symmetric", "VNC_MALE", "JRC2018_VNC_MALE"
Path=$INPUT1_FILE
objective=$INPUT1_OBJECTIVE
OUTPUT=$WORK_DIR"/Output"
FINALOUTPUT=$WORK_DIR"/FinalOutputs"
TempDir=$TEMPLATE_DIR/vnc2018_20x_40x_templates

DEBUG_DIR=$FINALOUTPUT"/debug"
mkdir -p $DEBUG_DIR

# "-------------------Template----------------------"
JRC2018_VNC_Unisex=$TempDir"/JRC2018_VNC_UNISEX_447_G15.nrrd"
JRC2018_VNC_Female=$TempDir"/JRC2018_VNC_FEMALE_447_G15.nrrd"
JRC2018_VNC_Male=$TempDir"/JRC2018_VNC_MALE_447_G15.nrrd"

# For Score ########################################
if [[ $INPUT1_GENDER =~ "m" ]]
then
# male fly vnc
    Tfile=${TempDir}"/MaleVNC2017.nrrd"
    POSTSCOREMASK=$MACRO_DIR"/For_Score/Mask_Male_VNC.nrrd"
else
# female fly vnc
    Tfile=${TempDir}"/FemaleVNCSymmetric2017.nrrd"
    POSTSCOREMASK=$MACRO_DIR"/For_Score/flyVNCtemplate20xA_CLAHE_MASK2nd.nrrd"
fi

POSTSCORE=$MACRO_DIR"/Score_For_VNC_pipeline.ijm"

echo "$testmode; "$testmode
# For TEST ############################################
if [[ $testmode == "1" ]]; then
    echo "Test mode"
    TempDir=/Registration/JRC2018_VNC_align_test/Template
    DIR="/Registration/JRC2018_VNC_align_test"
    CMTK=/Applications/FijizOLD.app/bin/cmtk
    FIJI=/Applications/FijizOLD.app/Contents/MacOS/ImageJ-macosx
    NSLOTS=8

    INPUT1_GENDER="m"
    Path="/Users/otsunah/Downloads/Workstation/BJD_124H07_AE_01/BJD_124H07_AE_01_20180629_62_C1_stitched-2556301758204739682.v3dpbd"
    objective="40x"
    RESX=0.52
    RESY=0.52


    NRRDCONV=/Users/otsunah/Documents/otsunah/jacs-tools/aligner_vnc2017_20x/aligner/scripts/VNC_preImageProcessing_Plugins_pipeline/nrrd2v3draw_MCFO.ijm

    INPUT1_CHANNELS=4
    INPUT1_RESX=$RESX
    INPUT1_RESY=$RESX
    INPUT1_RESZ=1


    # For Score ########################################
    if [[ $INPUT1_GENDER =~ "m" ]]; then
    # male fly vnc
        Tfile=${TempDir}"/MaleVNC2017.nrrd"
        POSTSCOREMASK="/Users/otsunah/Documents/otsunah/jacs-tools/aligner_vnc2017_20x/aligner/scripts/VNC_preImageProcessing_Plugins_pipeline/For_Score/Mask_Male_VNC.nrrd"
    else
    # female fly vnc
        Tfile=${TempDir}"/FemaleVNCSymmetric2017.nrrd"
        POSTSCOREMASK="/Users/otsunah/Documents/otsunah/jacs-tools/aligner_vnc2017_20x/aligner/scripts/VNC_preImageProcessing_Plugins_pipeline/For_Score/flyVNCtemplate20xA_CLAHE_MASK2nd.nrrd"
    fi

    POSTSCORE="/Users/otsunah/Documents/otsunah/VNC_preImageProcessing_Plugins_pipeline/For_Score/Score_For_VNC_pipeline.ijm"

    WORK_DIR="/Registration/JRC2018_VNC_align_test"
    BaseDir="/Registration/JRC2018_VNC_align_test"
    OUTPUT=$WORK_DIR"/Output"
Global_Aligned_Separator_Result=$OUTPUT"/ConsolidatedLabel.nrrd"
Unaligned_Neuron_Separator_Result_V3DPBD="/Users/otsunah/Downloads/Workstation/BJD_124H07_AE_01/BJD_124H07_AE_01_20180629_62_C1_ConsolidatedLabel.v3dpbd"

    PREPROCIMG="/Users/otsunah/Documents/otsunah/jacs-tools/aligner_vnc2017_20x/aligner/scripts/VNC_preImageProcessing_Plugins_pipeline/VNC_preImageProcessing_Pipeline_02_02_2017.ijm"
    SCOREGENERATION="/Registration/JRC2018_align_test/Score_Generator_Cluster.ijm"

    
fi


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
        LOGFILE="$DEBUG_DIR/raw-${TS}.log"
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
        $FIJI --headless -macro $SCOREGENERATION $OUTPUT/,$_outname,$NSLOTS,$_scoretemp >$DEBUG_DIR/scoregen.log 2>&1
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
    local _pearson_coeff="$8"
    local _bridged_from="$9"

    raw_filename=`basename ${_raw_aligned}`
    prefix=${raw_filename%%.*}

    if [[ -f "$_raw_aligned" ]]; then
        META="${OUTPUT}/${prefix}.properties"
        echo "alignment.stack.filename="${raw_filename} > $META
        echo "alignment.image.area=VNC" >> $META
        echo "alignment.image.channels=$INPUT1_CHANNELS" >> $META
        echo "alignment.image.refchan=$INPUT1_REF" >> $META
        echo "alignment.space.name=$_alignment_space" >> $META
        echo "alignment.image.size=$_image_size" >> $META
        echo "alignment.resolution.voxels=$_voxel_size" >> $META
        echo "alignment.objective=$_objective" >> $META
        if [[ ! -z "$_ncc_score" ]]; then
            echo "alignment.quality.score.ncc=$_ncc_score" >> $META
        fi
        if [[ ! -z "$_pearson_coeff" ]]; then
            echo "alignment.object.pearson.coefficient=$_pearson_coeff" >> $META
        fi
        if [[ -e $_raw_aligned_neurons ]]; then
            raw_neurons_filename=`basename ${_raw_aligned_neurons}`
            echo "neuron.masks.filename=$raw_neurons_filename" >> $META
        fi
        if [[ ! -z "$_bridged_from" ]]; then
            echo "alignment.bridged.from=$_bridged_from" >> $META
        fi
    else
        echo "Output file does not exist: $_raw_aligned"
        exit 1
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
    echo "alignment.image.area=VNC" >> $META
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
Global_Aligned_Separator_Result=$OUTPUT"/ConsolidatedLabel.nrrd"

if [[ $INPUT1_GENDER == "f" ]]; then
    genderT="FEMALE"
    oldVNC=$TempDir"/FemaleVNCSymmetric2017.nrrd"
    reformat_JRC2018_to_oldVNC=$TempDir"/Deformation_Fields/oldFemale_JRC2018_VNC_FEMALE"
    TEMPNAME="JRC2018_VNC_Female"
    OLDSPACE="FemaleVNCSymmetric2017_20x"
    iniT=$JRC2018_VNC_Female
    OLDVOXELS="0.4612588x0.4612588x0.7"

elif [[ $INPUT1_GENDER == "m" ]]; then
    genderT="MALE"
    oldVNC=$TempDir"/MaleVNC2017.nrrd"
    reformat_JRC2018_to_oldVNC=$TempDir"/Deformation_Fields/oldMale_JRC2018_VNC_MALE"
    TEMPNAME="JRC2018_VNC_Male"
    OLDSPACE="MaleVNC2016_20x"
    iniT=$JRC2018_VNC_Male
    OLDVOXELS="0.4611222x0.4611222x0.7"

else
    echo "ERROR: invalid gender: $INPUT1_GENDER"
    exit 1
fi

filename="PRE_PROCESSED_"$genderT

echo "INPUT1_GENDER; "$INPUT1_GENDER
echo "genderT; "$genderT
echo "oldVNC; "$oldVNC
echo "OLDSPACE; "$OLDSPACE
echo "reformat_JRC2018_to_oldVNC; "$reformat_JRC2018_to_oldVNC


# "-------------------Global aligned files----------------------"
gloval_nc82_nrrd=$OUTPUT"/"$filename"_01.nrrd"
gloval_signalNrrd1=$OUTPUT"/"$filename"_02.nrrd"
gloval_signalNrrd2=$OUTPUT"/"$filename"_03.nrrd"
gloval_signalNrrd3=$OUTPUT"/"$filename"_04.nrrd"

# "-------------------Deformation fields----------------------"
registered_initial_xform=$OUTPUT"/initial.xform"
registered_affine_xform=$OUTPUT"/affine.xform"
registered_warp_xform=$OUTPUT"/warp.xform"

reformat_JRC2018_to_Uni=$TempDir"/Deformation_Fields/JRC2018_VNC_Unisex_JRC2018_"$genderT

LOGFILE="${OUTPUT}/VNC_pre_aligner_log.txt"
if [[ -e $LOGFILE ]]; then
    echo "Already exists: $LOGFILE"
else
    echo "+---------------------------------------------------------------------------------------+"
    echo "| Running Otsuna preprocessing step                                                     |"
    echo "| $FIJI -macro $PREPROCIMG \"$OUTPUT/,filename,$TempDir,$Path,ssr,$RESX,$RESY,$INPUT1_GENDER,$Unaligned_Neuron_Separator_Result_V3DPBD,$NSLOTS\" |"
    echo "+---------------------------------------------------------------------------------------+"
    START=`date '+%F %T'`
    # Expect to take far less than 1 hour
    $FIJI -macro $PREPROCIMG "$OUTPUT/,$filename,$TempDir/,$Path,ssr,$RESX,$RESY,$INPUT1_GENDER,$Unaligned_Neuron_Separator_Result_V3DPBD,$NSLOTS" >$DEBUG_DIR/preproc.log 2>&1
    STOP=`date '+%F %T'`
    echo "Otsuna preprocessing start: $START"
    echo "Otsuna preprocessing stop: $STOP"
    # check for prealigner errors
    cp $LOGFILE $DEBUG_DIR
    PreAlignerError=`grep "PreAlignerError: " $LOGFILE | head -n1 | sed "s/PreAlignerError: //"`
    if [[ ! -z "$PreAlignerError" ]]; then
        writeErrorProperties "PreAlignerError" "JRC2018_VNC_${genderT}" "$objective" "Pre-aligner rejection: $PreAlignerError"
        exit 0
    fi
fi

# For TEST ############################################
#if [[ $testmode == 1 ]]; then
 # gloval_nc82_nrrd=$OUTPUT"/JRC2018MALE_JFRC2014_63x_DistCorrected_01_warp.nrrd"
 # iniT=$TempDir"/JRC2018_VNC_FEMALE_447_G15.nrrd"
#fi

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
$FIJI --headless -macro $TWELVEBITCONV "${OUTPUT}/,${filename}_01.nrrd,${gloval_nc82_nrrd}" > $DEBUG_DIR/conv12bit.log 2>&1

########################################################################################################
# JRC2018 gender-specific reformat
########################################################################################################

banner "JRC2018 $genderT reformat"
FLIP_NEURON=""
DEFFIELD=$registered_warp_xform
fn="REG_JRC2018_VNC_"$genderT
main_aligned_file=${fn}".v3draw"
sig=$OUTPUT"/"$fn
TEMP="$iniT"
gsig=$OUTPUT"/"$filename
reformatAll "$gsig" "$TEMP" "$DEFFIELD" "$sig" "RAWOUT"
scoreGen $sig"_01.nrrd" $iniT "score2018"

#if [[ -e $Global_Aligned_Separator_Result ]]; then
#    prefix="${OUTPUT}/${fn}_ConsolidatedLabel"
#    sig=$prefix".nrrd"
#    RAWOUT_NEURON=$prefix"_flipped.v3draw"
#    gsig=$Global_Aligned_Separator_Result
#    reformat "$gsig" "$TEMP" "$DEFFIELD" "$sig" "" "ignore" "--nn"
#    nrrd2Raw "$RAWOUT_NEURON,$sig"
#    FLIP_NEURON=$prefix".v3draw"
#    # flip neurons back to Neuron Annotator format
#    flip "$RAWOUT_NEURON" "$FLIP_NEURON" "yflip"
#    rm $RAWOUT_NEURON
#fi

writeProperties "$RAWOUT" "" "JRC2018_VNC_${genderT}" "$objective" "0.461122x0.461122x0.70" "572x1164x229" "$score2018" "" ""


########################################################################################################
# JRC2018 unisex reformat
########################################################################################################

banner "JRC2018 unisex reformat"
FLIP_NEURON=""
DEFFIELD="$reformat_JRC2018_to_Uni $registered_warp_xform"
fn="REG_UNISEX_VNC"
sig=$OUTPUT"/"$fn
TEMP="$JRC2018_VNC_Unisex"
gsig=$OUTPUT"/"$filename
reformatAll "$gsig" "$TEMP" "$DEFFIELD" "$sig" "RAWOUT"

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

writeProperties "$RAWOUT" "$FLIP_NEURON" "JRC2018_VNC_Unisex" "$objective" "0.461122x0.461122x0.70" "573x1119x219" "" "" "$main_aligned_file"


########################################################################################################
# oldVNC_$genderT reformat
########################################################################################################

banner "oldVNC $genderT reformat"
#"--inverse takes 1.5h / channel for reformatting"
DEFFIELD="$reformat_JRC2018_to_oldVNC $registered_warp_xform"
sig=$OUTPUT"/REG_oldVNC_$genderT"
TEMP="$oldVNC"
gsig=$OUTPUT"/"$filename
reformatAll "$gsig" "$TEMP" "$DEFFIELD" "$sig" "RAWOUT"

scoreGen $sig"_01.nrrd" "$oldVNC" "oldVNC"

registered_otsuna_qual=$OUTPUT"/Hideo_OBJPearsonCoeff.txt"
if [[ -e $registered_otsuna_qual ]]; then
    echo "Already exists: $registered_otsuna_qual"
else
    echo "+--------------------------------------------------------------------------------------------------------+"
    echo "| Running Otsuna scoring step to old VNC"
    echo "| $FIJI -macro $POSTSCORE $sig"_01.nrrd,PostScore,$OUTPUT/,$Tfile,$POSTSCOREMASK,$INPUT1_GENDER,$NSLOTS
    echo "+--------------------------------------------------------------------------------------------------------+"
    START=`date '+%F %T'`
    $FIJI -macro $POSTSCORE $sig"_01.nrrd,PostScore,$OUTPUT/,$Tfile,$POSTSCOREMASK,$INPUT1_GENDER,$NSLOTS"
    STOP=`date '+%F %T'`
    if [[ ! -e $registered_otsuna_qual ]]; then
        echo -e "Error: Otsuna ObjPearsonCoeff score failed"
        exit -1
    fi
    echo "Otsuna_scoring start: $START"
    echo "Otsuna_scoring stop: $STOP"
fi

oldscore=`cat $registered_otsuna_qual`

writeProperties "$RAWOUT" "" "$OLDSPACE" "20x" "$OLDVOXELS" "512x1100x220" "$oldVNC" "$oldscore" "$main_aligned_file"

if [[ $INPUT1_GENDER =~ "m" ]]; then
    ########################################################################################################
    # oldVNC_"FEMALE" reformat
    ########################################################################################################

    banner "oldVNC FEMALE reformat"
    DEFFIELD=$TempDir"/Deformation_Fields/oldFemale_JRC2018_VNC_MALE $registered_warp_xform"
    sig=$OUTPUT"/REG_oldVNC_FEMALE"
    TEMP=$TempDir"/FemaleVNCSymmetric2017.nrrd"
    gsig=$OUTPUT"/"$filename
    reformatAll "$gsig" "$TEMP" "$DEFFIELD" "$sig" "RAWOUT"

    writeProperties "$RAWOUT" "" "FemaleVNCSymmetric2017_20x" "20x" "0.4612588x0.4612588x0.7" "512x1024x220" "$score2010" "" "$main_aligned_file"
fi

# -------------------------------------------------------------------------------------------

echo "Converting all v3draw files to v3dpbd format"
compressAllRaw "$Vaa3D" "$OUTPUT"


# -------------------------------------------------------------------------------------------

echo "+----------------------------------------------------------------------+"
echo "| Copying files to final destination"
echo "+----------------------------------------------------------------------+"
cp $OUTPUT/*.{png,log,txt} $FINALOUTPUT/debug
cp -R $OUTPUT/*.xform $FINALOUTPUT/debug
cp $OUTPUT/REG*.v3dpbd $FINALOUTPUT
cp $OUTPUT/REG*.properties $FINALOUTPUT

echo "$0 done"


