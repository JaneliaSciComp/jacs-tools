#!/bin/bash
#
# 63x Brain aligner by Hideo Otsuna
#

DIR=$(cd "$(dirname "$0")"; pwd)
. $DIR/common.sh
parseParameters "$@"
# refomat scale; 0; full only, 2; HFonly
REFSCALE=$3

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
CMTKM=$CMTK/munger
FIJI=/opt/Fiji/ImageJ-linux64
Vaa3D=/opt/Vaa3D/vaa3d
MACRO_DIR=/opt/aligner/fiji_macros

# Fiji macros
NRRDCONV=$MACRO_DIR"/nrrd2v3draw.ijm"
NRRDCOMP=$MACRO_DIR"/nrrd_compression.ijm"
PREPROCIMG=$MACRO_DIR"/63x_tile_aligner_Pipeline_TempRotate.ijm"
SCOREGENERATION=$MACRO_DIR"/Score_Generator_Cluster63x.ijm"
TWELVEBITCONV=$MACRO_DIR"/12bit_Conversion.ijm"
REGCROP=$MACRO_DIR"/TempCrop_after_affine.ijm"
ROTATEAFTERWARP=$MACRO_DIR"/Rotation_AfterReg.ijm"
TWENTYHRGENERATION=$MACRO_DIR"/TwentyHRgeneration.ijm"

glfilename="PRE_PROCESSED"
inputfilename=$INPUT1_FILE
Path=$INPUT1_FILE
objective=$INPUT1_OBJECTIVE
OUTPUT=$WORK_DIR"/Output"
FINALOUTPUT=$WORK_DIR"/FinalOutputs"
TempDir=`realpath $TEMPLATE_DIR/jrc2018_63x_templates`
Unaligned_Neuron_Separator_Result_V3DPBD=$INPUT1_NEURONS
testmode=0

DEBUG_DIR=$FINALOUTPUT"/debug"
mkdir -p $DEBUG_DIR

echo "testmode; "$testmode
# For TEST ############################################
if [[ $testmode == "1" ]]; then
  echo "Test mode ON"

  TempDir="/nrs/scicompsoft/otsuna/Masayoshi_63x/Template"
  Unaligned_Neuron_Separator_Result_V3DPBD="/Users/otsunah/Downloads/Workstation/BJD_124H07_AE_01/BJD_124H07_AE_01_20180629_62_C1_ConsolidatedLabel.v3dpbd"

  OUTPUT=$1
  inputfilename=$2

  echo "OUTPUT "$OUTPUT
  echo "inputfilename "$inputfilename
  REFSCALE=2

  RESX=0.1882680
  RESZ=0.3794261
  NSLOTS=6
  objective="63x"
  Path=$OUTPUT"/$inputfilename"

  FIJI=/Applications/Fiji.app/Contents/MacOS/ImageJ-macosx
  TempDir="/Volumes/otsuna/Masayoshi_63x/Template"
  CMTK=/Applications/Fiji.app/bin/cmtk
  PREPROCIMG="/Volumes/otsuna/Masayoshi_63x/63x_tile_aligner_Pipeline.ijm"
  NRRDCOMP="/Volumes/otsuna/Masayoshi_63x/nrrd_compression.ijm"
  SCOREGENERATION="/Volumes/otsuna/Masayoshi_63x/Score_Generator_Cluster63x.ijm"
  NSLOTS=11

  # for VMware windows
  FIJI=/Applications/Fiji.app/Contents/MacOS/ImageJ-macosx
  TempDir="/Volumes/Registration2/63x_align/Template"
  CMTK=/Applications/Fiji.app/bin/cmtk
  PREPROCIMG="/Users/hideVMware/Dropbox/Hideo_Daily_Coding/63x_tile_aligner_Pipeline.ijm"
  NRRDCOMP="/Users/hideVMware/Dropbox/Hideo_Daily_Coding/nrrd_compression.ijm"
  SCOREGENERATION="/Users/hideVMware/Dropbox/Hideo_Daily_Coding/Score_Generator_Cluster63x.ijm"
  reformat_JRC2018U_to_JFRC2010="/Volumes/Registration2/63x_align/Template/Deformation_Fields/JFRC2010_JRC2018_UNISEX"
  reformat_JRC2018U_to_JFRC2013="/Volumes/Registration2/63x_align/Template/Deformation_Fields/JFRC2013_JRC2018_UNISEX"

  #for MacBookPro
  TempDir="/test/63x_align/Template"
  CMTK="/Applications/FijizOLD.app/bin/cmtk"
  CMTKM="/Applications/FijizOLD.app/bin/cmtk/munger"
  PREPROCIMG="/test/63x_align/63x_tile_aligner_Pipeline_TempRotate.ijm"
  FIJI="/Applications/FijizOLD.app/Contents/MacOS/ImageJ-macosx"
  NRRDCOMP="/test/63x_align/nrrd_compression.ijm "
  SCOREGENERATION="/test/63x_align/Score_Generator_Cluster63x.ijm"

  REGCROP="/test/63x_align/TempCrop_after_affine.ijm"
  ROTATEAFTERWARP="/test/63x_align/Rotation_AfterReg.ijm"
  TWENTYHRGENERATION="/test/63x_align/TwentyHRgeneration.ijm"
  NRRDCOMP="/test/63x_align/nrrd_compression.ijm"
  FINALOUTPUT=$OUTPUT"/FinalOutputs"

  INPUT1_GENDER="m"
  
  NRRDCONV=/Users/otsunah/Documents/otsunah/jacs-tools/aligner_vnc2017_20x/aligner/scripts/VNC_preImageProcessing_Plugins_pipeline/nrrd2v3draw_MCFO.ijm

  INPUT1_FILE=$inputfilename;

  INPUT1_CHANNELS=4
  INPUT1_RESX=$RESX
  INPUT1_RESY=$RESX
  INPUT1_RESZ=$RESZ

fi #if [[ $testmode == "1" ]]

INTPUT_FILENAME=`basename $INPUT1_FILE`
TxtPath=$OUTPUT/"${glfilename}_translation.txt"

# "-------------------Template----------------------"
JFRC2010=$TempDir/JFRC2010_16bit.nrrd
JFRC2013=$TempDir/JFRC2013_63xNew_dist_G16.nrrd
JFRC2014=$TempDir/JFRC2014_63x_DistCorrected_G15.nrrd

JRC2018UNISEX=$TempDir/JRC2018_UNISEX_63x.nrrd
JRC2018UNISEX38um=$TempDir/JRC2018_UNISEX_38um_iso.nrrd
JRC2018UNISEX20xHR=$TempDir/JRC2018_UNISEX_20x_HR.nrrd

JRC2018_63x_CROPPED=$OUTPUT"/Temp1.nrrd"

# "-------------------Global aligned files----------------------"
GLOUTPUT=$OUTPUT/images
gloval_nc82_nrrd="$GLOUTPUT/"$glfilename"_01.nrrd"
gloval_signalNrrd1="$GLOUTPUT/"$glfilename"_02.nrrd"
gloval_signalNrrd2="$GLOUTPUT/"$glfilename"_03.nrrd"
gloval_signalNrrd3="$GLOUTPUT/"$glfilename"_04.nrrd"

# "-------------------Deformation fields----------------------"
registered_initial_xform=$OUTPUT"/initial.xform"
registered_affine_xform=$OUTPUT"/Registration/affine/Temp1_PRE_PROCESSED_01_9dof.list"
registered_warp_xform=$OUTPUT"/warp.xform"

#
# Expand resolutions from TMOG
#
function expandRes() {
  local _res="$1"
  local _result_var="$2"
  if [[ $_res == "0.19" ]]; then
    result="0.1882680"
  elif [[ $_res == "0.16" ]]; then
    result="0.1882680"
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
    local _fn="$7"

    RAWOUT="${_sig}.v3draw" # Raw output file combining all the aligned channels
    RAWCONVPARAM=$RAWOUT
    RAWCONVSUFFIX=""

    # Reformat each channel
    for ((i=1; i<=$INPUT1_CHANNELS; i++)); do
        GLOBAL_NRRD="${_gsig}_0${i}.nrrd"
        OUTPUT_NRRD="${_sig}_0${i}.nrrd"
        echo "reformat; $GLOBAL_NRRD" "$_TEMP" "$_DEFFIELD" "$OUTPUT_NRRD" "$i" "ignore" "$opts"
        reformat "$GLOBAL_NRRD" "$_TEMP" "$_DEFFIELD" "$OUTPUT_NRRD" "$i" "ignore" "$opts"

        echo "_fn; $_fn"
        if [[ $_fn = "REG_JRC2018_"$genderT"_"$TRESOLUTION ]]; then
          echo "+----------------------------------------------------------------------+"
          echo "| Rotation after registration"
          echo "| $FIJI -macro $ROTATEAFTERWARP \"$OUTPUT/,$_fn,$OUTPUT_NRRD,$TxtPath,$REFSCALE\""
          echo "+----------------------------------------------------------------------+"
          $FIJI -macro $ROTATEAFTERWARP "$OUTPUT/,$_fn,$OUTPUT_NRRD,$TxtPath,$REFSCALE"
        fi

        echo "+----------------------------------------------------------------------+"
        echo "| NRRD Compression"
        echo "| $FIJI --headless -macro $NRRDCOMP \"$OUTPUT_NRRD\""
        echo "+----------------------------------------------------------------------+"
        $FIJI --headless -macro $NRRDCOMP "$OUTPUT_NRRD"

     #   if [[ $_fn = "REG_UNISEX_"$TRESOLUTION ]]; then
     #     echo "+----------------------------------------------------------------------+"
     #     echo "| Unisex 20x HR generation"
     #     echo "| $FIJI -macro $TWENTYHRGENERATION \"$OUTPUT,$i,$OUTPUT_NRRD\""
     #     echo "+----------------------------------------------------------------------+"
     #     $FIJI -macro $TWENTYHRGENERATION "$OUTPUT/,$i,$OUTPUT_NRRD" 
     #     # will generate "REG_UNISEX_20x_HR_0"+i+".nrrd"
     #   fi

         if [[ $testmode = "0" ]]; then
           echo "testmode; "$testmode
          if (( i>1 )); then
            # Add all signal channels to the final RAW file
            RAWCONVPARAM="$RAWCONVPARAM,$OUTPUT_NRRD"
          else
            # Put reference channel last in RAW file
            RAWCONVSUFFIX="$OUTPUT_NRRD"
          fi
        fi
    done
    if [[ $testmode = "0" ]]; then
      # Create raw file
      nrrd2Raw "${RAWCONVPARAM},${RAWCONVSUFFIX}"
      eval $_result_var="'$RAWOUT'"
    fi
}

# Alignment score generation
function scoreGen() {
    local _outpath="$1"
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
        echo "| $FIJI --headless -macro $SCOREGENERATION $OUTPUT/,$_outpath,$NSLOTS,$_scoretemp"
        echo "+---------------------------------------------------------------------------------------+"

        START=`date '+%F %T'`
        # Expect to take far less than 1 hour
        # Alignment Score generation:ZNCC, does not need Xvfb
        $FIJI --headless -macro $SCOREGENERATION $OUTPUT/,$_outpath,$NSLOTS,$_scoretemp >$DEBUG_DIR/${tempname}_scoregen.log 2>&1
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

if [[ ! -d $GLOUTPUT ]]; then
  mkdir $GLOUTPUT
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

Global_Aligned_Separator_Result=$OUTPUT"/ConsolidatedLabel.nrrd"

if [[ $REFSCALE == 2 ]]; then
    TRESOLUTION="63x_DS"
elif [[ $REFSCALE == 0 ]]; then
    TRESOLUTION="63x"
fi

if [[ $INPUT1_GENDER == "f" ]]; then
    genderT="FEMALE"
    reformat_JRC2018_to_oldBRAIN=$TempDir"/Deformation_Fields/JFRC2013_JRC2018_FEMALE"
    reformat_JRC2018_to_JFRC2010=$TempDir"/Deformation_Fields/JFRC2010_JRC2018_FEMALE"
    reformat_JRC2018_to_Uni="/Deformation_Fields/JRC2018_Unisex_JRC2018_FEMALE"
    TEMPNAME="JRC2018_Female"
    OLDTEMPPATH=$JFRC2013
    OLDSPACE="JFRC2013_63x"
    iniT=${TempDir}"/JRC2018_FEMALE_63x.nrrd"

    if [[ $REFSCALE == 2 ]]; then
        scoreT=${TempDir}"/JRC2018_FEMALE_38um_iso.nrrd"
        JRC2018RESO="0.38x0.38x0.38"
        JRC2018SIZE="1652x768x478"
    fi

    if [[ $REFSCALE == 0 ]]; then
        scoreT=${TempDir}"/JRC2018_FEMALE_63x.nrrd"
        JRC2018RESO="0.1882680x0.1882680x0.38"
        JRC2018SIZE="3333x1550x478"
    fi

    OLDVOXELS="0.38x0.38x0.38"
    OLDSIZE="1450x725x436"

elif [[ $INPUT1_GENDER == "m" ]]; then

    genderT="MALE"
    reformat_JRC2018_to_oldBRAIN=$TempDir"/Deformation_Fields/JFRC2014_JRC2018_MALE"
    reformat_JRC2018_to_JFRC2010=$TempDir"/Deformation_Fields/JFRC2010_JRC2018_MALE"
    reformat_JRC2018_to_Uni="/Deformation_Fields/JRC2018_Unisex_JRC2018_MALE"
    TEMPNAME="JRC2018_Male"
    OLDTEMPPATH=$JFRC2014
    OLDSPACE="JFRC2014_63x"
    iniT=${TempDir}"/JRC2018_MALE_63x.nrrd"

    if [[ $REFSCALE == 2 ]]; then
        scoreT=${TempDir}"/JRC2018_MALE_38um_iso.nrrd"
        JRC2018RESO="0.38x0.38x0.38"
        JRC2018SIZE="1561x744x476"
    fi
    if [[ $REFSCALE == 0 ]]; then
        scoreT=${TempDir}"/JRC2018_MALE_63x.nrrd"
        JRC2018RESO="0.1882680x0.1882680x0.38"
        JRC2018SIZE="3150x1500x476"
    fi

    OLDVOXELS="0.38x0.38x0.38"
    OLDSIZE="1450x725x436"


else
    echo "ERROR: invalid gender: $INPUT1_GENDER"
    exit 1
fi

reformat_JRC2018_to_Uni=$TempDir"/Deformation_Fields/JRC2018_Unisex_JRC2018_"$genderT

echo "INPUT1_GENDER; "$INPUT1_GENDER
echo "genderT; "$genderT
echo "OLDSPACE; "$OLDSPACE
echo "OLDTEMPPATH; "$OLDTEMPPATH
echo "reformat_JRC2018_to_oldBRAIN; "$reformat_JRC2018_to_oldBRAIN

# Remove all special characters and convert to lower case
TILES=`echo $INPUT1_TILES | tr -dc '[:alnum:]\n\r' | tr '[:upper:]' '[:lower:]'`
echo "Tiles; $TILES"
#if [[ $TILES == 'rightopticlobe' || $TILES == 'leftopticlobe' ]]; then
#    writeErrorProperties "PreAlignerError" "JRC2018_${genderT}_${TRESOLUTION}" "$objective" "Cannot align unstitched optic lobe tiles"
#    exit 0
#fi

skip=0

if [[ $skip = 0 ]]; then

LOGFILE="${OUTPUT}/PRE_PROCESSED63x_brain_pre_aligner_log.txt"
if [[ -e $LOGFILE ]]; then
    echo "Already exists: $LOGFILE"
else
    echo "+---------------------------------------------------------------------------------------+"
    echo "| Running Otsuna preprocessing step"
    echo "| $FIJI -macro $PREPROCIMG \"$OUTPUT/,$glfilename,$Path,$TempDir/,$RESX,$RESZ,$NSLOTS,$objective,$INPUT1_GENDER\""
    echo "+---------------------------------------------------------------------------------------+"
    START=`date '+%F %T'`
    # Expect to take far less than 1 hour
    # TODO: doesnt take neurons?
    $FIJI -macro $PREPROCIMG "$OUTPUT/,$glfilename,$Path,$TempDir/,$RESX,$RESZ,$NSLOTS,$objective,$INPUT1_GENDER"  >$DEBUG_DIR/preproc.log 2>&1

    STOP=`date '+%F %T'`
    echo "Otsuna preprocessing start: $START"
    echo "Otsuna preprocessing stop: $STOP"
    # check for prealigner errors
    cp $LOGFILE $DEBUG_DIR
    PreAlignerError=`grep "PreAlignerError: " $LOGFILE | head -n1 | sed "s/PreAlignerError: //"`
    if [[ ! -z "$PreAlignerError" ]]; then
        writeErrorProperties "PreAlignerError" "JRC2018_${genderT}_${TRESOLUTION}" "$objective" "$PreAlignerError"
        exit 0
    fi
fi

# For TEST ############################################
#if [[ $testmode == 1 ]]; then
 # gloval_nc82_nrrd=$OUTPUT"/JRC2018MALE_JFRC2014_63x_DistCorrected_01_warp.nrrd"
# iniT=$TempDir"/JRC2018_FEMALE_63x.nrrd"
#fi

echo "iniT; "$iniT
echo "gloval_nc82_nrrd; "$gloval_nc82_nrrd
echo ""

# -------------------------------------------------------------------------------------------
if [[ -e $registered_initial_xform ]]; then
    echo "Already exists: $registered_initial_xform"
else
    echo "+---------------------------------------------------------------------------------------+"
    echo "| Running CMTK registration"
    echo "| OUTPUT; $OUTPUT"
    echo "| $CMTKM -b $CMTK -a -X 26 -C 8 -G 80 -R 4 -A '--accuracy 0.8' -W '--accuracy 0.8' -T $NSLOTS -s \"$JRC2018_63x_CROPPED\" images"
    echo "+---------------------------------------------------------------------------------------+"
    START=`date '+%F %T'`

    cd "$OUTPUT"
    $CMTKM -b "$CMTK" -a -X 26 -C 8 -G 80 -R 4 -A '--accuracy 0.8' -W '--accuracy 0.8'  -T $NSLOTS -s "$JRC2018_63x_CROPPED" images

    STOP=`date '+%F %T'`
    if [[ ! -e $registered_affine_xform ]]; then
        echo -e "Error: CMTK registration failed"
        exit -1
    fi
    echo "cmtk_registration start: $START"
    echo "cmtk_registration stop: $STOP"
fi

echo " "
echo "------------------------------------------------------------"
echo "Template cropping by an affine registered brain "
echo "------------------------------------------------------------"

sig=$OUTPUT"/Affine_${inputfilename%.*}_01.nrrd"
DEFFIELD=$registered_affine_xform
TSTRING="JRC2018 63X"
TEMP="$JRC2018_63x_CROPPED"
gsig="$GLOUTPUT/"$glfilename"_01.nrrd"

$CMTK/reformatx -o "$sig" --floating $gsig $TEMP $DEFFIELD

$FIJI -macro $REGCROP "$TEMP,$sig,$NSLOTS"
rm -rf $sig

# CMTK warping
if [[ -e $registered_warp_xform ]]; then
    echo "Already exists: $registered_warp_xform"
else
    echo " "
    echo "+----------------------------------------------------------------------+"
    echo "| Running CMTK warping"
    echo "| $CMTK/warp --threads $NSLOTS -v --registration-metric nmi --jacobian-weight 0 --fast -e 26 --grid-spacing 80 --energy-weight 1e-1 --refine 4 --coarsest 8 --ic-weight 0 --output-intermediate --accuracy 0.8 -o $registered_warp_xform $registered_affine_xform"
    echo "+----------------------------------------------------------------------+"
    START=`date '+%F %T'`

    $CMTK/warp --threads $NSLOTS -v --registration-metric nmi --jacobian-weight 0 --fast -e 26 --grid-spacing 80 --energy-weight 1e-1 --refine 4 --coarsest 8 --ic-weight 0 --output-intermediate --accuracy 0.8 -o $registered_warp_xform $registered_affine_xform

    STOP=`date '+%F %T'`
    if [[ ! -e $registered_warp_xform ]]; then
        echo -e "Error: CMTK warping failed"
        exit -1
    fi
    echo "cmtk_warping start: $START"
    echo "cmtk_warping stop: $STOP"
fi

rm -rf $registered_initial_xform

echo " "
echo "+----------------------------------------------------------------------+"
echo "| 12-bit conversion"
echo "| $FIJI -macro $TWELVEBITCONV \"${OUTPUT}/,${glfilename}_01.nrrd,${gloval_nc82_nrrd}\""
echo "+----------------------------------------------------------------------+"
$FIJI --headless -macro $TWELVEBITCONV "${OUTPUT}/,${glfilename}_01.nrrd,${gloval_nc82_nrrd}" > $DEBUG_DIR/conv12bit.log 2>&1

fi # skip

########################################################################################################
# JRC2018 gender-specific reformat
########################################################################################################

banner "JRC2018 $genderT reformat"
DEFFIELD=$registered_warp_xform
fn="REG_JRC2018_${genderT}_${TRESOLUTION}"
main_aligned_file=${fn}".v3draw"
sig=$OUTPUT"/"$fn
TEMP="$JRC2018_63x_CROPPED"
gsig=$OUTPUT"/images/"$glfilename

reformatAll "$gsig" "$TEMP" "$DEFFIELD" "$sig" "RAWOUT" "" "$fn"

scoreGen $sig"_01.nrrd" $scoreT "score2018"

if [[ $testmode = "0" ]]; then
    writeProperties "$RAWOUT" "" "JRC2018_${genderT}_${TRESOLUTION}" "$objective" "$JRC2018RESO" "$JRC2018SIZE" "$score2018" "" ""
fi

########################################################################################################
# JRC2018 unisex reformat
########################################################################################################

banner "JRC2018 unisex reformat"
DEFFIELD="$reformat_JRC2018_to_Uni"
fn="REG_UNISEX_${TRESOLUTION}"
sig=$OUTPUT"/"$fn
gsig=$OUTPUT"/REG_JRC2018_${genderT}_${TRESOLUTION}"

if [[ $REFSCALE == 2 ]]; then
  TEMP="$JRC2018UNISEX38um"
elif [[ $REFSCALE == 0 ]]; then
  TEMP="$JRC2018UNISEX"
fi

reformatAll "$gsig" "$TEMP" "$DEFFIELD" "$sig" "RAWOUT" "" "$fn"

if [[ $testmode = "0" ]]; then
    writeProperties "$RAWOUT" "" "JRC2018_Unisex_${TRESOLUTION}" "$objective" "0.38x0.38x0.38" "1652x773x456" "" "" "$main_aligned_file"
fi

########################################################################################################
# JRC2018 unisex 20x HR reformat
########################################################################################################

banner "JRC2018 unisex 20xHR reformat"
DEFFIELD="$reformat_JRC2018_to_Uni"
fn="REG_UNISEX_ColorMIP_HR"
sig=$OUTPUT"/"$fn

TEMP="$JRC2018UNISEX20xHR"

reformatAll "$gsig" "$TEMP" "$DEFFIELD" "$sig" "RAWOUT" "" "$fn"

if [[ $testmode = "0" ]]; then
    writeProperties "$RAWOUT" "" "JRC2018_Unisex_20x_HR" "20x" "0.5189161x0.5189161x1.0" "1210x566x174" "" "" "$main_aligned_file"
fi


########################################################################################################
# oldBRAIN_$genderT reformat
########################################################################################################

banner "$OLDSPACE $genderT reformat"
#"--inverse takes 1.5h / channel for reformatting"
DEFFIELD="$reformat_JRC2018_to_oldBRAIN"
fn="REG_$OLDSPACE"
sig=$OUTPUT"/REG_$OLDSPACE"
TEMP="$OLDTEMPPATH"

reformatAll "$gsig" "$TEMP" "$DEFFIELD" "$sig" "RAWOUT" "" "$fn"

scoreGen $sig"_01.nrrd" "$OLDTEMPPATH" "scoreOLD"

if [[ $testmode = "0" ]]; then
    writeProperties "$RAWOUT" "" "$OLDSPACE" "$objective" "$OLDVOXELS" "$OLDSIZE" "$scoreOLD" "" "$main_aligned_file"
fi

########################################################################################################
# JFRC2010 reformat
########################################################################################################

banner "JFRC2010 $genderT reformat"
DEFFIELD="$reformat_JRC2018_to_JFRC2010"
fn="REG_JFRC2010_20x"
sig=$OUTPUT"/"$fn
TEMP="$JFRC2010"

reformatAll "$gsig" "$TEMP" "$DEFFIELD" "$sig" "RAWOUT" "" "$fn"

if [[ $testmode = "0" ]]; then
    writeProperties "$RAWOUT" "" "JFRC2010_20x" "20x" "0.62x0.62x1.00" "1024x512x218" "" "" "$main_aligned_file"
fi

# -------------------------------------------------------------------------------------------

echo "Converting all v3draw files to v3dpbd format"
compressAllRaw "$Vaa3D" "$OUTPUT"


# -------------------------------------------------------------------------------------------

echo "+----------------------------------------------------------------------+"
echo "| Copying files to final destination"
echo "+----------------------------------------------------------------------+"
cp $OUTPUT/*.{png,log,txt} $DEBUG_DIR
cp -R $OUTPUT/*.xform $DEBUG_DIR
cp $OUTPUT/REG*.v3dpbd $FINALOUTPUT
cp $OUTPUT/REG*.properties $FINALOUTPUT

echo "$0 done"

