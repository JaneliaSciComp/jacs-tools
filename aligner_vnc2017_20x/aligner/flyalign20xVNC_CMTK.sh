#!/bin/bash
# Program locations: (assumes running this in vnc_align script directory)
#
# 20x fly vnc alignment pipeline using CMTK, version 1.0, June 6, 2013
#

################################################################################
#
# The pipeline is developed for aligning 20x fly vnc using CMTK
# The standard brain's resolution (0.62x0.62x0.62 um)
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
LATTIF="$DIR/" # The directory which contains VNC_Lateral_M.tif and VNC_Lateral_F.tif. Must end in slash.

SUBVNC=$INPUT1_FILE
SUBREF=$INPUT1_REF
CONSLABEL=$INPUT1_NEURONS
CHN=$INPUT1_CHANNELS
GENDER=$GENDER
MP=$MOUNTING_PROTOCOL

RESX=$INPUT1_RESX
RESY=$INPUT1_RESY
RESZ=$INPUT1_RESZ

# special parameters
ZFLIP=$ZFLIP
GENDER=$GENDER

# tools
Vaa3D=`readItemFromConf $CONFIGFILE "Vaa3D"`
CMTK=`readItemFromConf $CONFIGFILE "CMTK"`
FIJI=`readItemFromConf $CONFIGFILE "Fiji"`

Vaa3D=${TOOLDIR}/${Vaa3D}
CMTK=${TOOLDIR}"/"${CMTK}
FIJI=${TOOLDIR}"/"${FIJI}
VNCScripts=${DIR}"/scripts/"

# templates
VNCTEMPLATEFEMALE=`readItemFromConf $CONFIGFILE "tgtVNC20xAFemale"`
VNCTEMPLATEMALE=`readItemFromConf $CONFIGFILE "tgtVNC20xAMale"`


if [[ $GENDER =~ "m" ]]
then
# male fly vnc
Tfile=${TMPLDIR}"/"${VNCTEMPLATEMALE}
POSTSCOREMASK=$VNCScripts"VNC_preImageProcessing_Plugins_pipeline/For_Score/Mask_Male_VNC.nrrd"
else
# female fly vnc
Tfile=${TMPLDIR}"/"${VNCTEMPLATEFEMALE}
POSTSCOREMASK=$VNCScripts"VNC_preImageProcessing_Plugins_pipeline/For_Score/flyVNCtemplate20xA_CLAHE_MASK2nd.nrrd"
fi

# debug inputs
message "Inputs..."
echo "CONFIGFILE: $CONFIGFILE"
echo "TMPLDIR: $TMPLDIR"
echo "TOOLDIR: $TOOLDIR"
echo "WORKDIR: $WORKDIR"
echo "SUBVNC: $SUBVNC"
echo "SUBREF: $SUBREF"
echo "MountingProtocol: $MP"
echo "Gender: $GENDER"
echo "RESX: $RESX"
echo "RESY: $RESY"
echo "RESZ: $RESZ"
message "Vars..."
echo "Vaa3D: $Vaa3D"
echo "CMTK: $CMTK"
echo "FIJI: $FIJI"
echo "VNCScripts: $VNCScripts"
echo "TEMPLATE: $Tfile"
echo ""

OUTPUT=${WORKDIR}"/Outputs"
FINALOUTPUT=${WORKDIR}"/FinalOutputs"

if [ ! -d $OUTPUT ]; then 
mkdir $OUTPUT
fi

if [ ! -d $FINALOUTPUT ]; then 
mkdir $FINALOUTPUT
fi

PREPROCIMG=$VNCScripts"VNC_preImageProcessing_Plugins_pipeline/VNC_preImageProcessing_Pipeline_02_02_2017.ijm"
POSTSCORE=$VNCScripts"VNC_preImageProcessing_Plugins_pipeline/For_Score/Score_For_VNC_pipeline.ijm"
RAWCONV=$VNCScripts"raw2nrrd.ijm"
#NRRDCONV=$VNCScripts"nrrd2raw.ijm"
NRRDCONV=$VNCScripts"nrrd2v3draw_MCFO.ijm" 
ZPROJECT=$VNCScripts"z_project.ijm"
PYTHON='/usr/bin/python'
PREPROC=$VNCScripts"PreProcess.py"
QUAL=$VNCScripts"OverlapCoeff.py"
QUAL2=$VNCScripts"ObjPearsonCoeff.py"
LSMR=$VNCScripts"lsm2nrrdR.ijm"

echo "Job started at" `date` "on" `hostname`
SAGE_IMAGE="$grammar{sage_image}"
echo "$sage_image"

# Shepherd VNC alignment
#preproc_result=$OUTPUT"/preprocResult.nrrd"
#unregistered_raw=$OUTPUT"/unregVNC.v3draw"
#registered_pp_raw=$OUTPUT"/VNC-PP.raw"
#registered_pp_c1_nrrd=$OUTPUT"/VNC-PP_C1.nrrd"
#registered_pp_c2_nrrd=$OUTPUT"/VNC-PP_C2.nrrd"

registered_pp_sg1_nrrd=$OUTPUT"/preprocResult_02.nrrd"
registered_pp_sg2_nrrd=$OUTPUT"/preprocResult_03.nrrd"
registered_pp_sg3_nrrd=$OUTPUT"/preprocResult_04.nrrd"

# Hideo output always sets reference as the first channel exported.
registered_pp_bg_nrrd=$OUTPUT"/preprocResult_01.nrrd"
registered_pp_initial_xform=$OUTPUT"/VNC-PP-initial.xform"
registered_pp_affine_xform=$OUTPUT"/VNC-PP-affine.xform"
registered_pp_warp_xform=$OUTPUT"/VNC-PP-warp.xform"
registered_pp_bgwarp_nrrd=$OUTPUT"/VNC-PP-BGwarp.nrrd"
registered_pp_warp_qual=$OUTPUT"/VNC-PP-warp_qual.csv"
registered_pp_warp_qual_temp=$OUTPUT"/VNC-PP-warp_qual.tmp"
registered_pp_sgwarp1_nrrd=$OUTPUT"/VNC-PP-SGwarp1.nrrd"
registered_pp_sgwarp2_nrrd=$OUTPUT"/VNC-PP-SGwarp2.nrrd"
registered_pp_sgwarp3_nrrd=$OUTPUT"/VNC-PP-SGwarp3.nrrd"

registered_pp_warp_png=$OUTPUT"/VNC-PP-warp.png"
#registered_pp_warp_raw=$OUTPUT"/VNC-PP-warp.raw"
registered_pp_warp_v3draw_filename="AlignedFlyVNC.v3draw"
registered_pp_warp_v3draw=$OUTPUT"/"${registered_pp_warp_v3draw_filename}
registered_otsuna_qual=$OUTPUT"/Hideo_OBJPearsonCoeff.txt"

# Neuron separation definitions. Expecting consolidated label to be sibling of signal.
Unaligned_Neuron_Separator_Dir=$(dirname "${CONSLABEL}")"/"
Unaligned_Neuron_Separator_Result_V3DPBD=${Unaligned_Neuron_Separator_Dir}"ConsolidatedLabel.v3dpbd"
CONSLABEL_FN="ConsolidatedLabel.v3draw"
Aligned_Consolidated_Label_V3DPBD=${OUTPUT}"/"${CONSLABEL_FN}

NRRD2V3DRAW_NS=$VNCScripts"VNC_preImageProcessing_Plugins_pipeline/nrrd2v3draw_N_separator_result.ijm"

# Make sure the input file exists
if [ -e $SUBVNC ]
then
   echo "Input file exists: "$SUBVNC
else
  echo -e "Error: image $SUBVNC does not exist"
  exit -1
fi

### temporary subject
TEMPSUBJECT=${OUTPUT}"/tempsubjectsx.v3draw"
if ( is_file_exist "$TEMPSUBJECT" )
then
echo "TEMPSUBJECT: $TEMPSUBJECT exists"
else

if [[ $ZFLIP =~ "zflip" ]]
then
#---exe---#
message " Flipping subject along z-axis "
time $Vaa3D -x ireg -f zflip -i ${SUBVNC} -o ${TEMPSUBJECT}
else
#---exe---#
message " Creating a symbolic link to 63x subject "
ln -s ${SUBVNC} ${TEMPSUBJECT}
fi

fi
SUBVNC=$TEMPSUBJECT

# Ensure existence of required inputs from unaligned neuron separation.
UNSR_TO_DEL="sentinel_nonexistent_file"
UNALIGNED_NEUSEP_EXISTS=1
if [ ! -e $Unaligned_Neuron_Separator_Result_V3DPBD ]; then
    echo -e "Warning: unaligned neuron separation result $Unaligned_Neuron_Separator_Result_V3DPBD does not exist. Perhaps user has deleted neuron separations?"
    UNALIGNED_NEUSEP_EXISTS=0
fi

if [ $UNALIGNED_NEUSEP_EXISTS == 1 ]; then
    NEURONSZFLIP=${OUTPUT}"/ConsolidatedLabel_zflip.v3draw"
    if [[ $ZFLIP =~ "zflip" ]]; then
        #---exe---#
        message " Flipping the neurons along z-axis "
        time $Vaa3D -x ireg -f zflip -i $Unaligned_Neuron_Separator_Result_V3DPBD -o $NEURONSZFLIP
        Unaligned_Neuron_Separator_Result_V3DPBD=$NEURONSZFLIP
    fi
fi

STARTDIR=`pwd`
cd $OUTPUT
# -------------------------------------------------------------------------------------------
echo "+---------------------------------------------------------------------------------------+"
echo "| Running Otsuna preprocessing step                                                     |"
echo "| $FIJI -macro $PREPROCIMG \"$OUTPUT/,preprocResult,$LATTIF,$SUBVNC,ssr,$RESX,$RESY,$GENDER,$Unaligned_Neuron_Separator_Result_V3DPBD,$NSLOTS\" |"
echo "+---------------------------------------------------------------------------------------+"
START=`date '+%F %T'`
# Expect to take far less than 1 hour
if [ ! -e $Unaligned_Neuron_Separator_Result_V3DPBD ]
then
  echo "Warning: $PREPROCIMG will be given a nonexistent $Unaligned_Neuron_Separator_Result_V3DPBD"
fi
$FIJI -macro $PREPROCIMG "$OUTPUT/,preprocResult,$LATTIF,$SUBVNC,ssr,$RESX,$RESY,$GENDER,$Unaligned_Neuron_Separator_Result_V3DPBD,$NSLOTS" >$OUTPUT/preproc.log 2>&1 &
fpid=$!
echo "Monitoring port=$XVFB_PORT pid=$fpid"
. ${TOOLDIR}/jacs-scripts/monitorXvfb.sh $XVFB_PORT $fpid 3600
STOP=`date '+%F %T'`
echo "Otsuna preprocessing start: $START"
echo "Otsuna preprocessing stop: $STOP"
# -------------------------------------------------------------------------------------------
# NRRD conversion
#echo "+--------------------------------------------------------------------------------------+"
#echo "| Running raw -> NRRD conversion                                                       |"
#echo "| xvfb-run --auto-servernum --server-num=200 $FIJI -macro $LSMR $preproc_result -batch |"
#echo "+--------------------------------------------------------------------------------------+"
#START=`date '+%F %T'`
#xvfb-run --auto-servernum --server-num=200 $FIJI -macro $LSMR $preproc_result -batch
#STOP=`date '+%F %T'`
if [ ! -e $registered_pp_bg_nrrd ]
then
  echo -e "Error: Otsuna preprocessing step failed"

  META=${FINALOUTPUT}"/AlignedFlyVNC.properties"
  echo "alignment.error=Otsuna preprocessing step failed" >> $META
  echo "alignment.stack.filename=" >> $META
  echo "alignment.image.area=VNC" >> $META
  echo "alignment.image.channels=$INPUT1_CHANNELS" >> $META
  echo "alignment.image.refchan=$INPUT1_REF" >> $META
  if [[ $GENDER =~ "m" ]]
  then
    # male fly brain
    echo "alignment.space.name=MaleVNC2016_20x" >> $META
  else
    # female fly brain
    echo "alignment.space.name=FemaleVNCSymmetric2017_20x" >> $META
  fi
  echo "alignment.resolution.voxels=0.52x0.52x1.00" >> $META
  echo "alignment.image.size=512x1024x185" >> $META
  echo "alignment.objective=20x" >> $META
  echo "default=true" >> $META

  exit -1
fi
#/usr/local/pipeline/bin/add_operation -operation raw_nrrd_conversion -name "$SAGE_IMAGE" -start "$START" -stop "$STOP" -operator $USERID -program "$FIJI" -version '1.47q' -parm imagej_macro="$LSMR"
sleep 2

#
#  The preprocessing step reverses the order from what is
#  required elsewhere in the pipeline.
#  This cannot be done before the files are created.
#
if [ -e $registered_pp_sg3_nrrd ]
then
  echo "+---------------------------------------------------------------------------------------+"
  echo "| Reordering sgwarp3 nrrd wih sgwarp1 nrrd.                                             |"
  echo "+---------------------------------------------------------------------------------------+"
  
  # Switching ordering of channels between 3 and 1.
  registered_pp_sg3_nrrd=$OUTPUT"/preprocResult_02.nrrd"
  registered_pp_sg2_nrrd=$OUTPUT"/preprocResult_03.nrrd"
  registered_pp_sg1_nrrd=$OUTPUT"/preprocResult_04.nrrd"
elif [ -e $registered_pp_sgwarp2_nrrd ]
then
  echo "+---------------------------------------------------------------------------------------+"
  echo "| Reordering sgwarp2 nrrd wih sgwarp1 nrrd.                                             |"
  echo "+---------------------------------------------------------------------------------------+"
  
  # Switching ordering of channels between 2 and 1.
  registered_pp_sg2_nrrd=$OUTPUT"/preprocResult_02.nrrd"
  registered_pp_sg1_nrrd=$OUTPUT"/preprocResult_03.nrrd"
fi

# Pre-processing
#echo "+----------------------------------------------------------------------+"
#echo "| Running pre-processing                                               |"
#echo "| $PYTHON $PREPROC $registered_pp_c1_nrrd $registered_pp_c2_nrrd C 10  |"
#echo "+----------------------------------------------------------------------+"
#START=`date '+%F %T'`
#$PYTHON $PREPROC $registered_pp_c1_nrrd $registered_pp_c2_nrrd C 10
#STOP=`date '+%F %T'`
#RGB='GRB'
#echo "MIP order: $RGB"
# CMTK make initial affine
echo "+----------------------------------------------------------------------+"
echo "| Running CMTK make_initial_affine                                     |"
echo "| $CMTK/make_initial_affine --principal_axes $Tfile $registered_pp_bg_nrrd $registered_pp_initial_xform |"
echo "+----------------------------------------------------------------------+"
START=`date '+%F %T'`
$CMTK/make_initial_affine --principal_axes $Tfile $registered_pp_bg_nrrd $registered_pp_initial_xform
STOP=`date '+%F %T'`
if [ ! -e $registered_pp_initial_xform ]
then
  echo -e "Error: CMTK make initial affine failed"
  exit -1
fi
echo "cmtk_initial_affine start: $START"
echo "cmtk_initial_affine stop: $STOP"
#/usr/local/pipeline/bin/add_operation -operation cmtk_initial_affine -name "$SAGE_IMAGE" -start "$START" -stop "$STOP" -operator $USERID -program "$CMTK/make_initial_affine" -version '2.2.6' -parm alignment_target="$Tfile"
# CMTK registration
echo "+----------------------------------------------------------------------+"
echo "| Running CMTK registration                                            |"
echo "|$CMTK/registration --threads $NSLOTS --initial $registered_pp_initial_xform --dofs 6,9 --accuracy 0.8 -o $registered_pp_affine_xform $Tfile $registered_pp_bg_nrrd |"
echo "+----------------------------------------------------------------------+"
START=`date '+%F %T'`
$CMTK/registration --threads $NSLOTS --initial $registered_pp_initial_xform --dofs 6,9 --accuracy 0.8 -o $registered_pp_affine_xform $Tfile $registered_pp_bg_nrrd
STOP=`date '+%F %T'`
if [ ! -e $registered_pp_affine_xform ]
then
  echo -e "Error: CMTK registration failed"
  exit -1
fi
echo "cmtk_registration start: $START"
echo "cmtk_registration stop: $STOP"
#/usr/local/pipeline/bin/add_operation -operation cmtk_registration -name "$SAGE_IMAGE" -start "$START" -stop "$STOP" - operator $USERID -program "$CMTK/registration" -version '2.2.6' -parm alignment_target="$Tfile"
# CMTK warping
echo "+----------------------------------------------------------------------+"
echo "| Running CMTK warping                                                 |"
echo "|$CMTK/warp --threads $NSLOTS -o $registered_pp_warp_xform --grid-spacing 80 --fast --exploration 26 --coarsest 8 --accuracy 0.8 --refine 4 --energy-weight 1e-1 --ic-weight 0 --initial $registered_pp_affine_xform $Tfile $registered_pp_bg_nrrd |"
echo "+----------------------------------------------------------------------+"
START=`date '+%F %T'`
$CMTK/warp --threads $NSLOTS -o $registered_pp_warp_xform --grid-spacing 80 --fast --exploration 26 --coarsest 8 --accuracy 0.8 --refine 4 --energy-weight 1e-1 --ic-weight 0 --initial $registered_pp_affine_xform $Tfile $registered_pp_bg_nrrd
    

STOP=`date '+%F %T'`
if [ ! -e $registered_pp_warp_xform ]
then
  echo -e "Error: CMTK warping failed"
  exit -1
fi
echo "cmtk_warping start: $START"
echo "cmtk_warping stop: $STOP"
#/usr/local/pipeline/bin/add_operation -operation cmtk_warping -name "$SAGE_IMAGE" -start "$START" -stop "$STOP" -operator $USERID -program "$CMTK/warp" -version '2.2.6' -parm alignment_target="$Tfile"
# CMTK reformatting
echo "+----------------------------------------------------------------------+"
echo "| Running CMTK reformatting                                            |"
echo "| $CMTK/reformatx -o $registered_pp_bgwarp_nrrd --floating $registered_pp_bg_nrrd $Tfile $registered_pp_warp_xform |"
echo "+----------------------------------------------------------------------+"
START=`date '+%F %T'`
$CMTK/reformatx -o $registered_pp_bgwarp_nrrd --floating $registered_pp_bg_nrrd $Tfile $registered_pp_warp_xform
STOP=`date '+%F %T'`
if [ ! -e $registered_pp_bgwarp_nrrd ]
then
  echo -e "Error: CMTK reformatting failed"
  exit -1
fi
echo "cmtk_reformatting start: $START"
echo "cmtk_reformatting stop: $STOP"
#/usr/local/pipeline/bin/add_operation -operation cmtk_reformatting -name "$SAGE_IMAGE" -start "$START" -stop "$STOP" -operator $USERID -program "$CMTK/reformatx" -version '2.2.6' -parm alignment_target="$Tfile"
# QC
echo "+----------------------------------------------------------------------+"
echo "| Running QC                                                           |"
echo "| $PYTHON $QUAL $registered_pp_bgwarp_nrrd $Tfile $registered_pp_warp_qual |"
echo "| $PYTHON $QUAL2 $registered_pp_bgwarp_nrrd $Tfile $registered_pp_warp_qual |"
echo "+----------------------------------------------------------------------+"
START=`date '+%F %T'`
$PYTHON $QUAL $registered_pp_bgwarp_nrrd $Tfile $registered_pp_warp_qual
$PYTHON $QUAL2 $registered_pp_bgwarp_nrrd $Tfile $registered_pp_warp_qual
STOP=`date '+%F %T'`
if [ ! -e $registered_pp_warp_qual ]
then
  echo -e "Error: quality check failed"
  exit -1
fi
echo "alignment_qc start: $START"
echo "alignment_qc stop: $STOP"
#/usr/local/pipeline/bin/add_operation -operation alignment_qc -name "$SAGE_IMAGE" -start "$START" -stop "$STOP" -operator $USERID -program "$QUAL" -version '1.0' -parm alignment_target="$Tfile"
# -------------------------------------------------------------------------------------------                                                                                                                                                   
# CMTK reformatting
echo "+----------------------------------------------------------------------+"
echo "| Running CMTK reformatting                                            |"
echo "| $CMTK/reformatx -o $registered_pp_sgwarp1_nrrd --floating $registered_pp_sg1_nrrd $Tfile $registered_pp_warp_xform |"
echo "+----------------------------------------------------------------------+"
START=`date '+%F %T'`
$CMTK/reformatx -o $registered_pp_sgwarp1_nrrd --floating $registered_pp_sg1_nrrd $Tfile $registered_pp_warp_xform
STOP=`date '+%F %T'`
if [ ! -e $registered_pp_sgwarp1_nrrd ]
then
  echo -e "Error: CMTK reformatting sg1 failed"
  exit -1
fi
echo "cmtk_reformatting start: $START"
echo "cmtk_reformatting stop: $STOP"

if [ -e $registered_pp_sg2_nrrd ]
then
	#/usr/local/pipeline/bin/add_operation -operation alignment_qc -name "$SAGE_IMAGE" -start "$START" -stop "$STOP" -operator $USERID -program "$QUAL" -version '1.0' -parm alignment_target="$Tfile"
	# -------------------------------------------------------------------------------------------                                                                                                                                                   
	# CMTK reformatting
	echo "+----------------------------------------------------------------------+"
	echo "| Running CMTK reformatting                                            |"
	echo "| $CMTK/reformatx -o $registered_pp_sgwarp2_nrrd --floating $registered_pp_sg2_nrrd $Tfile $registered_pp_warp_xform |"
	echo "+----------------------------------------------------------------------+"
	START=`date '+%F %T'`
	$CMTK/reformatx -o $registered_pp_sgwarp2_nrrd --floating $registered_pp_sg2_nrrd $Tfile $registered_pp_warp_xform
	STOP=`date '+%F %T'`
	if [ ! -e $registered_pp_sgwarp2_nrrd ]
	then
		echo -e "Error: CMTK reformatting sg2 failed"
		exit -1
	fi
    echo "cmtk_reformatting start: $START"
    echo "cmtk_reformatting stop: $STOP"
fi

if [ -e $registered_pp_sg3_nrrd ]
then
	#/usr/local/pipeline/bin/add_operation -operation alignment_qc -name "$SAGE_IMAGE" -start "$START" -stop "$STOP" -operator $USERID -program "$QUAL" -version '1.0' -parm alignment_target="$Tfile"
	# -------------------------------------------------------------------------------------------                                                                                                                                                   
	# CMTK reformatting
	echo "+----------------------------------------------------------------------+"
	echo "| Running CMTK reformatting                                            |"
	echo "| $CMTK/reformatx -o $registered_pp_sgwarp3_nrrd --floating $registered_pp_sg3_nrrd $Tfile $registered_pp_warp_xform |"
	echo "+----------------------------------------------------------------------+"
	START=`date '+%F %T'`
	$CMTK/reformatx -o $registered_pp_sgwarp3_nrrd --floating $registered_pp_sg3_nrrd $Tfile $registered_pp_warp_xform
	STOP=`date '+%F %T'`
	if [ ! -e $registered_pp_sgwarp3_nrrd ]
	then
		echo -e "Error: CMTK reformatting3 failed"
		exit -1
	fi
    echo "cmtk_reformatting start: $START"
    echo "cmtk_reformatting stop: $STOP"
fi

if [ $UNALIGNED_NEUSEP_EXISTS == 1 ]
then
        #/usr/local/pipeline/bin/add_operation -operation alignment_qc -name "$SAGE_IMAGE" -start "$START" -stop "$STOP" -operator $USERID -program "$QUAL" -version '1.0' -parm alignment_target="$Tfile"
        # -------------------------------------------------------------------------------------------
        # CMTK reformatting for neuron separator result
 
        Neuron_Separator_ResultNRRD=${OUTPUT}"/ConsolidatedLabel.nrrd"
        if [ -e $Neuron_Separator_ResultNRRD ]
        then
                echo "+----------------------------------------------------------------------+"
                echo "| Running CMTK reformatting for Neuron separator result                |"
                echo "| $CMTK/reformatx --nn -o $Reformatted_Separator_result_nrrd --floating $Neuron_Separator_ResultNRRD $Tfile $registered_pp_warp_xform |"
                echo "+----------------------------------------------------------------------+"
                START=`date '+%F %T'`
 
                Reformatted_Separator_result_nrrd=${OUTPUT}"/Reformatted_Separator_Result.nrrd"
 
                $CMTK/reformatx --nn -o $Reformatted_Separator_result_nrrd --floating $Neuron_Separator_ResultNRRD $Tfile $registered_pp_warp_xform
                STOP=`date '+%F %T'`
                echo "neuron_reformatting start: $START"
                echo "neuron_reformatting stop: $STOP"
                if [ ! -e $Reformatted_Separator_result_nrrd ]
                then
                        echo -e "Error: CMTK reformatting Neuron separation failed"
                        exit -1
                fi
                echo "+----------------------------------------------------------------------+"
                echo "| Running nrrd -> v3draw conversion                                    |"
                echo "| $FIJI -macro $NRRD2V3DRAW_NS ${OUTPUT}"/" |"
                echo "+----------------------------------------------------------------------+"
                START=`date '+%F %T'`
                $FIJI -macro $NRRD2V3DRAW_NS ${OUTPUT}"/"
                STOP=`date '+%F %T'`
                if [ ! -e $Aligned_Consolidated_Label_V3DPBD ]
                then
                        echo -e "Error: nrrd -> v3draw conversion of Neuron separator failed"
                        exit -1
                fi
                echo "neuron_conversion start: $START"
                echo "neuron_conversion stop: $STOP"
 
        fi
fi


#/usr/local/pipeline/bin/add_operation -operation cmtk_reformatting -name "$SAGE_IMAGE" -start "$START" -stop "$STOP" -operator $USERID -program "$CMTK/reformatx" -version '2.2.6' -parm alignment_target="$Tfile"
# NRRD conversion
echo "+----------------------------------------------------------------------+"
echo "| Running NRRD -> v3draw conversion                                    |"
echo "| $FIJI -macro $NRRDCONV $registered_pp_warp_v3draw                    |"
echo "+----------------------------------------------------------------------+"
START=`date '+%F %T'`
$FIJI -macro $NRRDCONV $registered_pp_warp_v3draw
STOP=`date '+%F %T'`
if [ ! -e $registered_pp_warp_v3draw ]
then
  echo -e "Error: NRRD -> raw conversion failed"
  exit -1
fi
echo "nrrd_raw_conversion start: $START"
echo "nrrd_raw_conversion stop: $STOP"
#/usr/local/pipeline/bin/add_operation -operation nrrd_raw_conversion -name "$SAGE_IMAGE" -start "$START" -stop "$STOP" -operator $USERID -program "$FIJI" -version '1.47q' -parm imagej_macro="$NRRDCONV"
sleep 2

# Z projection
echo "+----------------------------------------------------------------------+"
echo "| Running Z projection                                                 |"
echo "| $FIJI -macro $ZPROJECT "$registered_pp_warp_v3draw $RGB $registered_pp_warp_qual_temp" |"
echo "+----------------------------------------------------------------------+"
START=`date '+%F %T'`
awk -F"," '{print $3}' $registered_pp_warp_qual | head -1 | sed 's/^  *//' >$registered_pp_warp_qual_temp
awk -F"," '{print $1 $2}' $registered_pp_warp_qual >>$registered_pp_warp_qual_temp
$FIJI -macro $ZPROJECT "$registered_pp_warp_v3draw $RGB $registered_pp_warp_qual_temp"
#/bin/rm -f $registered_pp_warp_qual_temp
STOP=`date '+%F %T'`
echo "z_projection start: $START"
echo "z_projection stop: $STOP"

# -------------------------------------------------------------------------------------------                                                                                                                                                           
echo "+--------------------------------------------------------------------------------------------------------+"
echo "| Running Otsuna scoring step                                                                            |"
echo "| $FIJI -macro $POSTSCORE \"$registered_pp_bgwarp_nrrd,PostScore,$OUTPUT/,$Tfile,$POSTSCOREMASK,$GENDER\"|"
echo "+--------------------------------------------------------------------------------------------------------+"
START=`date '+%F %T'`
$FIJI -macro $POSTSCORE "$registered_pp_bgwarp_nrrd,PostScore,$OUTPUT/,$Tfile,$POSTSCOREMASK,$GENDER"
STOP=`date '+%F %T'`
if [ ! -e $registered_otsuna_qual ]
then
  echo -e "Error: Otsuna ObjPearsonCoeff score failed"
  exit -1
fi
echo "Otsuna_scoring start: $START"
echo "Otsuna_scoring stop: $STOP"

# -------------------------------------------------------------------------------------------                                                                 
# raw to v3draw                                                                                                                                               
#echo "+----------------------------------------------------------------------+"                                                                              
#echo "| Running raw -> v3draw conversion                                     |"                                                                              
#echo "| $Vaa3D -cmd image-loader -convert $registered_pp_warp_raw $registered_pp_warp_v3draw |"                                                              
#echo "+----------------------------------------------------------------------+"                                                                            
#$Vaa3D -cmd image-loader -convert $registered_pp_warp_raw $registered_pp_warp_v3draw                                                     

# -------------------------------------------------------------------------------------------                                                                                                                                                                                                    
if [ ! -e $registered_pp_warp_v3draw ]
then
  echo -e "Error: Final v3draw conversion failed"
  exit -1
fi

echo "+----------------------------------------------------------------------+"
echo "| Copying file to final destination                                    |"
echo "+----------------------------------------------------------------------+"
cp -R $OUTPUT/AlignedFlyVNC* $FINALOUTPUT
cp -R $OUTPUT/ConsolidatedLabel.v3draw $FINALOUTPUT

FINALDEBUG=$FINALOUTPUT/debug
mkdir $FINALDEBUG
cp -R $OUTPUT/Hideo_OBJPearsonCoeff.txt $FINALDEBUG
cp -R $OUTPUT/VNC-PP-initial.xform $FINALDEBUG
cp -R $OUTPUT/VNC-PP-affine.xform $FINALDEBUG
cp -R $OUTPUT/VNC-PP-warp.xform $FINALDEBUG
cp -R $OUTPUT/VNC-PP-warp_qual.csv $FINALDEBUG
cp -R $OUTPUT/*log.txt $FINALDEBUG
cp -R $OUTPUT/Shape_problem $FINALDEBUG
cp -R $OUTPUT/High_background_cannot_segment_VNC $FINALDEBUG
cp -R $OUTPUT/preprocResult_Lateral.png $FINALDEBUG
cp -R $OUTPUT/preprocResult.png $FINALDEBUG

if [[ -f "$registered_pp_warp_v3draw" ]]; then
OVERLAP_COEFF=`grep Overlap $registered_pp_warp_qual | awk -F"," '{print $1}'`
PEARSON_COEFF=`grep Pearson $registered_pp_warp_qual | awk -F"," '{print $1}'`

# Check for Hideo score file
OTSUNA_PEARSON_COEFF=`cat $registered_otsuna_qual | awk '{print $1}'`

META=${FINALOUTPUT}"/AlignedFlyVNC.properties"
echo "alignment.stack.filename="${registered_pp_warp_v3draw_filename} >> $META
echo "alignment.image.area=VNC" >> $META
echo "alignment.image.channels=$INPUT1_CHANNELS" >> $META
echo "alignment.image.refchan=$INPUT1_REF" >> $META
if [[ $GENDER =~ "m" ]]
then
# male fly brain
echo "alignment.space.name=MaleVNC2016_20x" >> $META
else
# female fly brain
echo "alignment.space.name=FemaleVNCSymmetric2017_20x" >> $META
fi
echo "alignment.otsuna.object.pearson.coefficient=$OTSUNA_PEARSON_COEFF" >> $META
echo "alignment.overlap.coefficient=$OVERLAP_COEFF" >> $META
echo "alignment.object.pearson.coefficient=$PEARSON_COEFF" >> $META
echo "alignment.resolution.voxels=0.52x0.52x1.00" >> $META
echo "alignment.image.size=512x1024x185" >> $META
echo "alignment.objective=20x" >> $META
if [ -e $Aligned_Consolidated_Label_V3DPBD ]
then
  echo "neuron.masks.filename=$CONSLABEL_FN" >> $META
else
  echo "WARNING: No $CONSLABEL_FN produced.  Not picked up by warped-result alignment step."
fi
echo "default=true" >> $META
fi

compressAllRaw $Vaa3D $WORKDIR

# Cleanup
# tar -zcf $registered_pp_warp_xform.tar.gz $registered_pp_warp_xform                                                                                                                                                                                
#x/bin/rm -rf $lsmname*-PP-*.xform $lsmname*-PP.raw $lsmname*.nrrd                                                                                                                                                                                    
#x/bin/rm -rf *-PP-*.xform *-PP.raw $registered_pp_sgwarp_nrrd $registered_pp_sg_nrrd $registered_pp_bgwarp_nrrd

# Check whether a temp file needs to be deleted.
if [ -e $UNSR_TO_DEL ]
then
  rm -rf $UNSR_TO_DEL
fi
echo "Job completed at "`date`
#xtrap "rm -f $0"           
