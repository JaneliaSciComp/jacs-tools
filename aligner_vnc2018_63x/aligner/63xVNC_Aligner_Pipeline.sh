#!/bin/bash
# # 63x VNC aligner by Hideo Otsuna #

testmode=0

export CMTK_WRITE_UNCOMPRESSED=1

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
#  alltiles e.g. "prothoracic;mesothoracic;metathoracic;abdominal"

echo "testmode; "$testmode

if [[ $testmode == "0" ]]; then

  DIR=$(cd "$(dirname "$0")"; pwd)
  . $DIR/common.sh
  parseParameters "$@"
  # refomat scale; 0; full only, 2; HFonly
  REFSCALE=$3
  # Empty or "bridging" to enable bridging transformations to legacy templates
  Bridging=$4

  # Remove all special characters and convert to lower case
  TILES=$(echo $INPUT1_TILES | tr -dc '[:alnum:],' | tr '[:upper:]' '[:lower:]' | tr ',' ';')
  echo "Tiles; $TILES"
  alltiles=$TILES

  # Tools
  CMTK=/opt/CMTK/bin
  CMTKM=$CMTK/munger
  FIJI=/opt/Fiji/ImageJ-linux64
  Vaa3D=/opt/Vaa3D/vaa3d
  MACRO_DIR=/opt/aligner/fiji_macros

  # Fiji macros
  NRRDCONV=$MACRO_DIR"/nrrd2v3draw.ijm"
  NRRDCOMP=$MACRO_DIR"/nrrd_compression.ijm"
  PREPROCIMG=$MACRO_DIR"/63xVNC_pre_aligner_pipeline.ijm"
  SCOREGENERATION=$MACRO_DIR"/Score_Generator_Cluster63x.ijm"
  TWELVEBITCONV=$MACRO_DIR"/12bit_Conversion.ijm"
  REGCROP=$MACRO_DIR"/TempCrop_after_affine.ijm"
  ROTATEAFTERWARP=$MACRO_DIR"/Rotation_AfterReg.ijm"

  glfilename="PRE_PROCESSED"
  inputfilename=$INPUT1_FILE
  Path=$INPUT1_FILE
  objective=$INPUT1_OBJECTIVE
  OUTPUT=$WORK_DIR"/Output"
  FINALOUTPUT=$WORK_DIR"/FinalOutputs"
  TempDir=`realpath $TEMPLATE_DIR/vnc2018_63x_templates`

  DEBUG_DIR=$FINALOUTPUT"/debug"
  mkdir -p $DEBUG_DIR

else

  echo "Test mode ON"

  INPUT1_GENDER="m"
  NSLOTS=3

  OUTPUT=$1
  glfilename="PRE_PROCESSED"
  inputfilename=$2
  alltiles=$3
  #prothoracic;mesothoracic;metathoracic;abdominal

  echo "OUTPUT "$OUTPUT
  echo "inputfilename "$inputfilename
  REFSCALE=2

  RESX=0.1882680
  RESZ=0.3794261
  objective="63x"
  Path=$OUTPUT"/$inputfilename"

  # for LSF cluster
  MACRO_DIR=/nrs/scicompsoft/otsuna/63x_VNC/aligner_vnc_jrc2018_63x/aligner/fiji_macros 
  TempDir="/nrs/scicompsoft/otsuna/template/63x_VNC"

  CMTK=/nrs/scicompsoft/otsuna/CMTK_new2019
  CMTKM="/nrs/scicompsoft/otsuna/CMTK_new2019/munger"
  PREPROCIMG="$MACRO_DIR/63xVNC_pre_aligner_pipeline.ijm"
  FIJI="/groups/terraincognita/home/otsunah/Desktop/Fiji.app/ImageJ-linux64"
  NRRDCOMP="$MACRO_DIR/nrrd_compression.ijm "
  SCOREGENERATION="$MACRO_DIR/Score_Generator_Cluster63x.ijm"

  REGCROP="$MACRO_DIR/TempCrop_after_affine.ijm"
  ROTATEAFTERWARP="$MACRO_DIR/Rotation_AfterReg.ijm"
  NRRDCOMP="$MACRO_DIR/nrrd_compression.ijm"


# for VMware windows
  FIJI=/Applications/Fiji.app/Contents/MacOS/ImageJ-macosx
  TempDir="/Volumes/Registration2/63x_align/Template"
  CMTK=/Applications/Fiji.app/bin/cmtk
  PREPROCIMG="/Users/hideVMware/Dropbox/Hideo_Daily_Coding/63x_tile_aligner_Pipeline.ijm"
  NRRDCOMP="/Users/hideVMware/Dropbox/Hideo_Daily_Coding/nrrd_compression.ijm"
  SCOREGENERATION="/Users/hideVMware/Dropbox/Hideo_Daily_Coding/Score_Generator_Cluster63x.ijm"

#for MacBookPro
  MACRO_DIR=/Users/otsunah/Documents/jacs-tools/aligner_vnc2018_63x/aligner/fiji_macros
  TempDir="/test/63xVNC_align/template"
  CMTK="/Applications/FijizOLD.app/bin/cmtk"
  CMTKM="/Applications/FijizOLD.app/bin/cmtk/munger"
  PREPROCIMG="$MACRO_DIR/63xVNC_pre_aligner_pipeline.ijm"
  FIJI="/Applications/FijizOLD.app/Contents/MacOS/ImageJ-macosx"
  NRRDCOMP="$MACRO_DIR/nrrd_compression.ijm "
  SCOREGENERATION="$MACRO_DIR/Score_Generator_Cluster63x.ijm"

  REGCROP="$MACRO_DIR/TempCrop_after_affine.ijm"
  ROTATEAFTERWARP="$MACRO_DIR/Rotation_AfterReg.ijm"
  NRRDCOMP="$MACRO_DIR/nrrd_compression.ijm"
 // FINALOUTPUT=$OUTPUT"/FinalOutputs"

  filename=${inputfilename%.*}
  INPUT1_GENDER=${filename##*_}

  NRRDCONV=/Users/otsunah/Documents/otsunah/jacs-tools/aligner_vnc2017_20x/aligner/scripts/VNC_preImageProcessing_Plugins_pipeline/nrrd2v3draw_MCFO.ijm

  INPUT1_FILE=$inputfilename;

  INPUT1_CHANNELS=4
  INPUT1_RESX=$RESX
  INPUT1_RESY=$RESX
  INPUT1_RESZ=$RESZ

fi #if [[ $testmode == "1" ]]

TxtPath=$OUTPUT/"${glfilename}_translation.txt"
UTxtPath=$OUTPUT/"${glfilename}_U_translation.txt"
# "-------------------Template----------------------"
JRC2018_VNC_Unisex_63x=$TempDir"/JRC2018_VNC_UNISEX_63x.nrrd"
JRC2018_VNC_Female_63x=$TempDir"/JRC2018_VNC_FEMALE_63x.nrrd"
JRC2018_VNC_Male_63x=$TempDir"/JRC2018_VNC_MALE_63x.nrrd"

JRC2018_VNC_Unisex_40x=$TempDir"/JRC2018_VNC_UNISEX_447.nrrd"
JRC2018_VNC_Female_40x=$TempDir"/JRC2018_VNC_FEMALE_447.nrrd"
JRC2018_VNC_Male_40x=$TempDir"/JRC2018_VNC_MALE_447.nrrd"

VNC2017_Female=$TempDir"/20x_flyVNCtemplate_Female_symmetric_16bit.nrrd"
VNC2017_Male=$TempDir"/2017Male_VNC.nrrd"

#JRC2018_63x_CROPPED=$OUTPUT"/Temp.nrrd"
JRC2018_63xDW_CROPPED=$OUTPUT"/TempDW.nrrd"

JRC2018_63x_UNISEX_CROPPED=$OUTPUT"/TempUnisex.nrrd"
JRC2018_63xDW_UNISEX_CROPPED=$OUTPUT"/TempUnisex_DW.nrrd"

# "-------------------Global aligned files----------------------"
GLOUTPUT=$OUTPUT/images
gloval_nc82_nrrd="$GLOUTPUT/"$glfilename"_01.nrrd"
gloval_nc82_DW_nrrd="$OUTPUT/"$glfilename"_DW_01.nrrd"
#gloval_signalNrrd1="$GLOUTPUT/"$glfilename"_02.nrrd"
#gloval_signalNrrd2="$GLOUTPUT/"$glfilename"_03.nrrd"
#gloval_signalNrrd3="$GLOUTPUT/"$glfilename"_04.nrrd"

# "-------------------Deformation fields----------------------"
registered_affine_xform=$OUTPUT"/Registration/affine/TempDW_PRE_PROCESSED_01_9dof.list"
registered_warp_xform=$OUTPUT"/warp.xform"

registered_affine_unisex_xform=$OUTPUT"/Registration/affine/TempUnisex_PRE_PROCESSED_01_9dof.list"
registered_warp_unisex_xform=$OUTPUT"/warp_unisex.xform"

oldFemale_JRC2018_VNC_MALE=$TempDir"/Deformation_Fields/oldFemale_JRC2018_VNC_MALE"
UNISEX_RESIZE=$TempDir"/Deformation_Fields/JRC2018U_VNC_resize"

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
    for ((i=1; i<=INPUT1_CHANNELS; i++)); do
        GLOBAL_NRRD="${_gsig}_0${i}.nrrd"
        OUTPUT_NRRD="${_sig}_0${i}.nrrd"
        NRRDCOMPNEED=1
	
       if [[ -e "$GLOBAL_NRRD" ]]; then
          echo "reformat; $GLOBAL_NRRD" "$_TEMP" "$_DEFFIELD" "$OUTPUT_NRRD" "$i" "ignore" "$opts"
          reformat "$GLOBAL_NRRD" "$_TEMP" "$_DEFFIELD" "$OUTPUT_NRRD" "$i" "ignore"

          if [[ $testmode == "0" ]]; then
            genderfn="REG_JRC2018_"$genderT"_"$TRESOLUTION
          else
            genderfn="REG_JRC2018_${genderT}_${TRESOLUTION}_${inputfilename%.*}"
          fi
          echo "genderfn; $genderfn""  $_fn; "$_fn

          if [[ $_fn = "$genderfn" ]]; then
            if [[ -e "$TxtPath" ]]; then
              echo "+----------------------------------------------------------------------+"
              echo "| Rotation after registration"
              echo "| $FIJI -macro $ROTATEAFTERWARP \"$OUTPUT/,$genderfn,$OUTPUT_NRRD,$TxtPath,$REFSCALE\""
              echo "+----------------------------------------------------------------------+"
              $FIJI -macro $ROTATEAFTERWARP "$OUTPUT/,$genderfn,$OUTPUT_NRRD,$TxtPath,$REFSCALE"
              NRRDCOMPNEED=0
            fi
          fi
	
          if [[ $testmode == "0" ]]; then
            unisexfn="REG_UNISEX_"$TRESOLUTION
          else
            unisexfn="REG_JRC2018_UNISEX_${TRESOLUTION}_${inputfilename%.*}"
          fi
          echo "unisexfn; $unisexfn""  $_fn; "$_fn
          if [[ $_fn = "$unisexfn" ]]; then
            if [[ -e "$UTxtPath" ]]; then
              echo "+----------------------------------------------------------------------+"
              echo "| Rotation after registration Unisex"
              echo "| $FIJI -macro $ROTATEAFTERWARP \"$OUTPUT/,$unisexfn,$OUTPUT_NRRD,$TxtPath,$REFSCALE\""
              echo "+----------------------------------------------------------------------+"
              $FIJI -macro $ROTATEAFTERWARP "$OUTPUT/,$unisexfn,$OUTPUT_NRRD,$UTxtPath,$REFSCALE"
              NRRDCOMPNEED=0
            fi
          fi
	
          if [[ $NRRDCOMPNEED = 1 ]];then
            echo "+----------------------------------------------------------------------+"
            echo "| NRRD Compression"
            echo "| $FIJI --headless -macro $NRRDCOMP \"$OUTPUT_NRRD\""
            echo "+----------------------------------------------------------------------+"
            $FIJI --headless -macro $NRRDCOMP "$OUTPUT_NRRD"
            fi
          fi #if [[ -e "$GLOBAL_NRRD" ]]; then

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
    local _movie_var="$4"

    outfilename=`basename $_outpath`
    tempfilename=`basename $_scoretemp`
    outname=${outfilename%%.*}
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
        if [[ $testmode = "0" ]]; then
          $FIJI --headless -macro $SCOREGENERATION $OUTPUT/,$_outpath,$NSLOTS,$_scoretemp >$DEBUG_DIR/${tempname}_scoregen.log 2>&1
        else
          $FIJI --headless -macro $SCOREGENERATION $OUTPUT/,$_outpath,$NSLOTS,$_scoretemp
        fi
        STOP=`date '+%F %T'`

        echo "ZNCC JRC2018 score generation start: $START"
        echo "ZNCC JRC2018 score generation stop: $STOP"
    fi

    score=`cat $scorepath`
    eval $_result_var="'$score'"
    echo "returning score: $_score"

    verifyname="${outname}"
    verifypath="$OUTPUT/${verifyname}.avi"

    echo "Check for verification movie: $verifypath"
    # Is there an alignment verification movie?
    if [[ -e "$verifypath" ]]; then
        verifymp4="${verifyname}.mp4"
        echo "Converting $verifypath to MP4"
        ffmpeg -y -r 30 -i "$verifypath" -vcodec libx264 -b:v 2000000 -preset slow -tune film -pix_fmt yuv420p "$OUTPUT/$verifymp4" && rm $verifypath
        eval $_movie_var="'$verifymp4'"
        echo "returning movie: $verifymp4"
    fi
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
    local _verify_movie="${10}"

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
        if [[ ! -z "$_verify_movie" ]]; then
            echo "alignment.verify.filename=$_verify_movie" >> $META
        fi
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

if [[ ! -d $GLOUTPUT ]]; then
  mkdir $GLOUTPUT
fi

if [[ $testmode = "0" ]]; then
  if [[ ! -d $FINALOUTPUT ]]; then
    mkdir $FINALOUTPUT
  fi
fi

if [[ ! -e $PREPROCIMG ]]; then
    echo "Preprocess macro could not be found at $PREPROCIMG"
    exit 1
fi

if [[ ! -e $FIJI ]]; then
    echo "Fiji cannot be found at $FIJI"
    exit 1
fi

TRESOLUTION="63x"

if [[ $INPUT1_GENDER == "f" ]]; then
    genderT="FEMALE"
    reformat_JRC2018_to_oldVNC=$TempDir"/Deformation_Fields/oldFemale_JRC2018_VNC_FEMALE"
    OLDTEMPPATH=$VNC2017_Female
    OLDSPACE="VNC2017F"
    OLDSPACEWS="FemaleVNCSymmetric2017_20x"
    iniT=${JRC2018_VNC_Female_63x}


    scoreT=${JRC2018_VNC_Female_40x}
    JRC2018RESO="0.4611220x0.4611220x0.70"
    JRC2018SIZE="573x1164x205"


    OLDVOXELS="0.4612588x0.4612588x0.7"
    OLDSIZE="512x1024x220"

elif [[ $INPUT1_GENDER == "m" ]]; then

    genderT="MALE"
    reformat_JRC2018_to_oldVNC=$TempDir"/Deformation_Fields/oldMale_JRC2018_VNC_MALE"
    OLDTEMPPATH=$VNC2017_Male
    OLDSPACE="VNC2017M"
    OLDSPACEWS="MaleVNC2016_20x"
    iniT=${JRC2018_VNC_Male_63x}

    scoreT=${JRC2018_VNC_Male_40x}
    JRC2018RESO="0.4611220x0.4611220x0.70"
    JRC2018SIZE="572x1164x229"

    OLDVOXELS="0.4611222x0.4611222x0.7"
    OLDSIZE="512x1100x220"

else
    echo "ERROR: invalid gender: $INPUT1_GENDER"
    exit 1
fi


echo "INPUT1_GENDER; "$INPUT1_GENDER
echo "genderT; "$genderT
echo "OLDSPACE; "$OLDSPACE
echo "OLDTEMPPATH; "$OLDTEMPPATH
echo "reformat_JRC2018_to_oldVNC; "$reformat_JRC2018_to_oldVNC


LOGFILE="${OUTPUT}/PRE_PROCESSED63x_VNC_pre_aligner_log.txt"
if [[ -e $LOGFILE ]]; then
    echo "Already exists: $LOGFILE"
else
    echo "+---------------------------------------------------------------------------------------+"
    echo "| Running 63x VNC Otsuna preprocessing step"
    echo "| $FIJI -macro $PREPROCIMG \"$OUTPUT/,$glfilename,$Path,$TempDir/,$RESX,$RESZ,$NSLOTS,$alltiles,$INPUT1_GENDER\""
    echo "+---------------------------------------------------------------------------------------+"
    START=`date '+%F %T'`
    # Expect to take far less than 1 hour
    # TODO: doesnt take neurons?
    if [[ $testmode == "0" ]]; then
      $FIJI -macro $PREPROCIMG "$OUTPUT/,$glfilename,$Path,$TempDir/,$RESX,$RESZ,$NSLOTS,$alltiles,$INPUT1_GENDER"  >$DEBUG_DIR/preproc.log 2>&1
    else
      $FIJI -macro $PREPROCIMG "$OUTPUT/,$glfilename,$Path,$TempDir/,$RESX,$RESZ,$NSLOTS,$alltiles,$INPUT1_GENDER"
    fi

    STOP=`date '+%F %T'`
    echo "Otsuna preprocessing start: $START"
    echo "Otsuna preprocessing stop: $STOP"

    if [[ $testmode == "0" ]]; then
      # check for prealigner errors
      cp $LOGFILE $DEBUG_DIR
      PreAlignerError=`grep "PreAlignerError: " $LOGFILE | head -n1 | sed "s/PreAlignerError: //"`
      if [[ ! -z "$PreAlignerError" ]]; then
        writeErrorProperties "PreAlignerError" "JRC2018_${genderT}_${TRESOLUTION}" "$objective" "$PreAlignerError"
        exit 0
      fi
    fi
fi

if [[ ! -e $TxtPath ]]; then
    JRC2018_63xDW_CROPPED=$scoreT
    registered_affine_unisex_xform=$OUTPUT"/Registration/affine/JRC2018_PRE_PROCESSED_01_9dof.list"
    JRC2018_63xDW_UNISEX_CROPPED=${JRC2018_VNC_Unisex_40x}
fi

# For TEST ############################################
#if [[ $testmode == "1" ]]; then
 # gloval_nc82_nrrd=$OUTPUT"/JRC2018MALE_JFRC2014_63x_DistCorrected_01_warp.nrrd"
# iniT=$TempDir"/JRC2018_FEMALE_63x.nrrd"
#fi

echo "iniT; "$iniT
echo "gloval_nc82_nrrd; "$gloval_nc82_nrrd
echo ""

# -------------------------------------------------------------------------------------------
if [[ -e ${registered_warp_xform} ]]; then
    echo "Already exists: $registered_warp_xform"
else
    echo "+---------------------------------------------------------------------------------------+"
    echo "| Running CMTK registration"
    echo "| OUTPUT; $OUTPUT"
    echo "| $CMTKM -b $CMTK -a -X 26 -C 8 -G 80 -R 4 -A '--accuracy 0.8' -W '--accuracy 0.8' -T $NSLOTS -s \"$JRC2018_63xDW_CROPPED\" images"
    echo "+---------------------------------------------------------------------------------------+"
    START=`date '+%F %T'`

    cd "$OUTPUT"
    #$CMTKM -b "$CMTK" -a -X 26 -C 8 -G 80 -R 4 -A '--accuracy 0.8' -W '--accuracy 0.8'  -T $NSLOTS -s "$JRC2018_63xDW_CROPPED" images
    $CMTK/registration -i -v --dofs 6 --dofs 9 --accuracy 0.8 -o Registration/affine/TempDW_PRE_PROCESSED_01_9dof.list ${JRC2018_63xDW_CROPPED} ${gloval_nc82_DW_nrrd}

    STOP=`date '+%F %T'`
    if [[ ! -e ${registered_affine_xform} ]]; then
        echo -e "Error: CMTK registration failed"
        exit -1
    fi
    echo "cmtk_gender_registration start: $START"
    echo "cmtk_gender_registration stop: $STOP"

    if [[ -e $TxtPath ]]; then
        echo " "
        echo "------------------------------------------------------------"
        echo "Template cropping by an affine registered brain "
        echo "------------------------------------------------------------"

        sig=$OUTPUT"/Affine_${inputfilename%.*}_01.nrrd"
        DEFFIELD=$registered_affine_xform
        TSTRING="JRC2018 63X"
        TEMP="$JRC2018_63xDW_CROPPED"
        gsig="${gloval_nc82_DW_nrrd}"

        $CMTK/reformatx -o "$sig" --floating $gsig $TEMP $DEFFIELD
        $FIJI -macro $REGCROP "$TEMP,$sig,$NSLOTS"
        rm -rf $sig
    fi
    START=`date '+%F %T'`

        cd "$OUTPUT"
        #$CMTKM -b "$CMTK" -a -X 26 -C 8 -G 80 -R 4 -A '--accuracy 0.8' -W '--accuracy 0.8'  -T $NSLOTS -s "$JRC2018_63x_UNISEX_CROPPED" images
        $CMTK/registration -i -v --dofs 6 --dofs 9 --accuracy 0.8 -o ${registered_affine_unisex_xform} ${JRC2018_63xDW_UNISEX_CROPPED} ${gloval_nc82_DW_nrrd}

        STOP=`date '+%F %T'`
       if [[ ! -e ${registered_affine_xform} ]]; then
            echo -e "Error: CMTK registration failed"
            exit -1
        fi
        echo "cmtk_unisex_registration start: $START"
        echo "cmtk_unisex_registration stop: $STOP"

    if [[ -e $TxtPath ]]; then
        sig=$OUTPUT"/Affine_${inputfilename%.*}_01.nrrd"
        DEFFIELD=$registered_affine_unisex_xform
        TEMP="$JRC2018_63x_UNISEX_CROPPED"
        gsig="$GLOUTPUT/"$glfilename"_01.nrrd"

        $CMTK/reformatx -o "$sig" --floating $gsig $TEMP $DEFFIELD
        $FIJI -macro $REGCROP "$TEMP,$sig,$NSLOTS"
        rm -rf $sig
    fi
fi

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
    
    $CMTK/warp --threads $NSLOTS -v --registration-metric nmi --jacobian-weight 0 --fast -e 26 --grid-spacing 80 --energy-weight 1e-1 --refine 4 --coarsest 8 --ic-weight 0 --output-intermediate --accuracy 0.8 -o $registered_warp_xform --initial ${registered_affine_xform} ${JRC2018_63xDW_CROPPED} ${gloval_nc82_DW_nrrd}
    STOP=`date '+%F %T'`

    echo "cmtk_gender_warping start: $START"
    echo "cmtk_gender_warping stop: $STOP"

    START=`date '+%F %T'`
    $CMTK/warp --threads $NSLOTS -v --registration-metric nmi --jacobian-weight 0 --fast -e 26 --grid-spacing 80 --energy-weight 1e-1 --refine 4 --coarsest 8 --ic-weight 0 --output-intermediate --accuracy 0.8 -o $registered_warp_unisex_xform --initial $registered_affine_unisex_xform ${JRC2018_63xDW_UNISEX_CROPPED} ${gloval_nc82_DW_nrrd}

    STOP=`date '+%F %T'`

    echo "cmtk_unisex_warping start: $START"
    echo "cmtk_unisex_warping stop: $STOP"
    if [[ ! -e $registered_warp_xform ]]; then
        echo -e "Error: CMTK warping failed"
        exit -1
    fi

fi

#if [[ $testmode == "1" ]]; then
#  rm -rf $registered_affine_xform
#  rm -rf $OUTPUT"/Registration"
#fi

if [[ $testmode == "0" ]]; then
  echo " "
  echo "+----------------------------------------------------------------------+"
  echo "| 12-bit conversion"
  echo "| $FIJI -macro $TWELVEBITCONV \"${GLOUTPUT}/,${glfilename}_01.nrrd,${gloval_nc82_nrrd}\""
  echo "+----------------------------------------------------------------------+"
  $FIJI --headless -macro $TWELVEBITCONV "${GLOUTPUT}/,${glfilename}_01.nrrd,${gloval_nc82_nrrd}" > $DEBUG_DIR/conv12bit.log 2>&1
fi



########################################################################################################
# JRC2018 gender-specific reformat
########################################################################################################

banner "JRC2018 $genderT reformat"
DEFFIELD=$registered_warp_xform
if [[ $testmode == "0" ]]; then
  fn="REG_JRC2018_${genderT}_${TRESOLUTION}"
else
  fn="REG_JRC2018_${genderT}_${TRESOLUTION}_${inputfilename%.*}"
fi
main_aligned_file=${fn}".v3draw"
sig=$OUTPUT"/"$fn
TEMP="${JRC2018_63xDW_CROPPED}"
gsig=$GLOUTPUT"/"$glfilename

if [[ ! -e $sig"_01.nrrd" ]]; then
  reformatAll "$gsig" "$TEMP" "$DEFFIELD" "$sig" "RAWOUT" "" "$fn"

  scoreGen $sig"_01.nrrd" $scoreT "score2018" "verify2018"

  if [[ $testmode = "0" ]]; then
    writeProperties "$RAWOUT" "" "JRC2018_VNC_${genderT}_${TRESOLUTION}" "$TRESOLUTION" "$JRC2018RESO" "$JRC2018SIZE" "$score2018" "" "" "$verify2018"
  fi
fi #if [[ ! -e $sig ]]; then


########################################################################################################
# JRC2018 unisex 63x reformat
########################################################################################################

banner "JRC2018 unisex 63x reformat"
DEFFIELD="$registered_warp_unisex_xform"
if [[ $testmode == "0" ]]; then
  fn="REG_UNISEX_${TRESOLUTION}"
  gsig=$GLOUTPUT"/"$glfilename
else
  fn="REG_JRC2018_UNISEX_${TRESOLUTION}_${inputfilename%.*}"
  gsig=$GLOUTPUT"/"$glfilename
fi
sig=$OUTPUT"/"$fn

if [[ -e $TxtPath ]]; then
    TEMP="$JRC2018_63x_UNISEX_CROPPED"
else
    TEMP="$JRC2018_VNC_Unisex_63x"
fi

if [[ ! -e $sig"_01.nrrd" ]]; then
    reformatAll "$gsig" "$TEMP" "$DEFFIELD" "$sig" "RAWOUT" "" "$fn"

  if [[ $testmode = "0" ]]; then
    writeProperties "$RAWOUT" "" "JRC2018_VNC_Unisex_${TRESOLUTION}" "$TRESOLUTION" "0.1882689x0.1882689x0.38" "1401x2740x402" "" "" "$main_aligned_file"
  fi
fi

########################################################################################################
# JRC2018 unisex 40x reformat
########################################################################################################

banner "JRC2018 unisex 40x reformat"
DEFFIELD="$UNISEX_RESIZE"
if [[ $testmode == "0" ]]; then
  fn="REG_UNISEX_20x"
  gsig=$OUTPUT"/REG_UNISEX_${TRESOLUTION}"
else
  fn="REG_JRC2018_UNISEX_20x_${inputfilename%.*}"
  gsig=$OUTPUT"/REG_JRC2018_UNISEX_${TRESOLUTION}_${inputfilename%.*}"
fi
sig=$OUTPUT"/"$fn

TEMP="$JRC2018_VNC_Unisex_40x"

if [[ ! -e $sig"_01.nrrd" ]]; then

  reformatAll "$gsig" "$TEMP" "$DEFFIELD" "$sig" "RAWOUT" "" "$fn"

  scoreGen $sig"_01.nrrd" "$TEMP" "score2018U" "verify2018U"

  if [[ $testmode = "1" ]]; then
    rm $OUTPUT"/Score_log_"$fn"_01.txt"
    rm $OUTPUT"/JRC2018_VNC_UNISEX_447_Score.property"
  fi

  if [[ $testmode = "0" ]]; then
    writeProperties "$RAWOUT" "" "JRC2018_VNC_Unisex_40x_DS" "40x_DS" "0.461122x0.461122x0.70" "573x1119x219" "$score2018U" "" "$main_aligned_file" "$verify2018U"
  fi
fi

if [[ $testmode = "1" ]]; then
  rm $OUTPUT"/Score_log_"$fn"_01.txt"
  rm $OUTPUT"/JRC2018_VNC_${genderT}_63x_Score.property"
#  rm -rf $GLOUTPUT
#  rm $JRC2018_63x_CROPPED
#  rm $JRC2018_63x_UNISEX_CROPPED
fi

if [[ $Bridging == "bridging" ]]; then

    ########################################################################################################
    # oldVNC_$genderT reformat
    ########################################################################################################

    banner "$OLDSPACE reformat"
    #"--inverse takes 1.5h / channel for reformatting"
    DEFFIELD="$reformat_JRC2018_to_oldVNC"
    if [[ $testmode == "0" ]]; then
      fn="REG_$OLDSPACE"
    else
      fn="REG_${OLDSPACE}_${inputfilename%.*}"
    fi

    if [[ $testmode == "0" ]]; then
        gsig="REG_JRC2018_${genderT}_${TRESOLUTION}"
    else
        gsig="REG_JRC2018_${genderT}_${TRESOLUTION}_${inputfilename%.*}"
    fi

    sig=$OUTPUT"/"$fn
    TEMP="$OLDTEMPPATH"

    if [[ ! -e $sig"_01.nrrd" ]]; then
      reformatAll "$gsig" "$TEMP" "$DEFFIELD" "$sig" "RAWOUT" "" "$fn"


      if [[ $testmode = "0" ]]; then
        writeProperties "$RAWOUT" "" "$OLDSPACEWS" "$objective" "$OLDVOXELS" "$OLDSIZE" "" "" "$main_aligned_file"
      fi
    fi

    if [[ $INPUT1_GENDER == "m" ]]; then
      ########################################################################################################
      # oldVNC_FEMALE reformat
      ########################################################################################################

      banner "oldVNC_FEMALE reformat for MALE"
      DEFFIELD="$oldFemale_JRC2018_VNC_MALE"
      if [[ $testmode == "0" ]]; then
        fn="REG_VNC2017F"
      else
        fn="REG_VNC2017F_${inputfilename%.*}"
      fi

      sig=$OUTPUT"/"$fn
      TEMP="$VNC2017_Female"

      if [[ ! -e $sig"_01.nrrd" ]]; then
        reformatAll "$gsig" "$TEMP" "$DEFFIELD" "$sig" "RAWOUT" "" "$fn"
      fi

      if [[ $testmode = "0" ]]; then
        writeProperties "$RAWOUT" "" "FemaleVNCSymmetric2017_20x" "63x" "0.4612588x0.4612588x0.7" "512x1024x220" "" "" "$main_aligned_file"
      fi
    fi #if [[ $INPUT1_GENDER == "m" ]]; then

fi

# -------------------------------------------------------------------------------------------
if [[ $testmode == "0" ]]; then
  echo "Converting all v3draw files to v3dpbd format"
  compressAllRaw "$Vaa3D" "$OUTPUT"


  # -------------------------------------------------------------------------------------------

  echo "+----------------------------------------------------------------------+"
  echo "| Copying files to final destination"
  echo "+----------------------------------------------------------------------+"
  cp $OUTPUT/*.{png,jpg,log,txt} $DEBUG_DIR
  cp -R $OUTPUT/*.xform $DEBUG_DIR
  cp $OUTPUT/REG*.{v3dpbd,properties,mp4} $FINALOUTPUT

  echo "$0 done"
fi
