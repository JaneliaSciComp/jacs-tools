#!/bin/bash
#
# 20x fly brain alignment pipeline using JBA, version 1.0, June 6, 2013
#

################################################################################
#
# The pipeline is developed for aligning 20x fly brain with JBA.
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

SUBBRAIN=$INPUT1_FILE
SUBREF=$INPUT1_REF
CHN=$INPUT1_CHANNELS

MP=$INPUT1_MOUNTING_PROTOCOL

RESX=$INPUT1_RESX
RESY=$INPUT1_RESY
RESZ=$INPUT1_RESZ

# tools
Vaa3D=`readItemFromConf $CONFIGFILE "Vaa3D"`
JBA=`readItemFromConf $CONFIGFILE "JBA"`
ANTS=`readItemFromConf $CONFIGFILE "ANTS"`
WARP=`readItemFromConf $CONFIGFILE "WARP"`

Vaa3D=${TOOLDIR}"/"${Vaa3D}
JBA=${TOOLDIR}"/"${JBA}
ANTS=${TOOLDIR}"/"${ANTS}
WARP=${TOOLDIR}"/"${WARP}

# templates
ATLAS=`readItemFromConf $CONFIGFILE "atlasFBTX"`
TAR=`readItemFromConf $CONFIGFILE "tgtFBTX"`
TARMARKER=`readItemFromConf $CONFIGFILE "tgtFBTXmarkers"`
TARREF=`readItemFromConf $CONFIGFILE "REFNO"`
RESTX_X=`readItemFromConf $CONFIGFILE "VSZX_20X_IS"`
RESTX_Y=`readItemFromConf $CONFIGFILE "VSZY_20X_IS"`
RESTX_Z=`readItemFromConf $CONFIGFILE "VSZZ_20X_IS"`
LCRMASK=`readItemFromConf $CONFIGFILE "LCRMASK"`
CMPBND=`readItemFromConf $CONFIGFILE "CMPBND"`

TAR=${TMPLDIR}"/"${TAR}
ATLAS=${TMPLDIR}"/"${ATLAS}
TARMARKER=${TMPLDIR}"/"${TARMARKER}
LCRMASK=${TMPLDIR}"/"${LCRMASK}
CMPBND=${TMPLDIR}"/"${CMPBND}

# debug inputs
message "Inputs..."
echo "CONFIGFILE: $CONFIGFILE"
echo "TMPLDIR: $TMPLDIR"
echo "TOOLDIR: $TOOLDIR"
echo "WORKDIR: $WORKDIR"
echo "SUBBRAIN: $SUBBRAIN"
echo "SUBREF: $SUBREF"
echo "MountingProtocol: $MP"
echo "RESX: $RESX"
echo "RESY: $RESY"
echo "RESZ: $RESZ"
message "Vars..."
echo "Vaa3D: $Vaa3D"
echo "ANTS: $ANTS"
echo "WARP: $WARP"
echo "TAR: $TAR"
echo "TARMARKER: $TARMARKER"
echo "TARREF: $TARREF"
echo "ATLAS: $ATLAS"
echo "LCRMASK: $LCRMASK"
echo "CMPBND: $CMPBND"
echo ""

OUTPUT=${WORKDIR}"/Outputs"
FINALOUTPUT=${WORKDIR}"/FinalOutputs"

if [ ! -d $OUTPUT ]; then 
mkdir $OUTPUT
fi

if [ ! -d $FINALOUTPUT ]; then 
mkdir $FINALOUTPUT
fi


##################
# Preprocessing
##################

### temporary target
TEMPTARGET=${OUTPUT}"/temptargettx.tif"
if ( is_file_exist "$TEMPTARGET" )
then
echo "Temp TARGET exists"
else
#---exe---#
message " Creating a symbolic link to 20x target "
ln -s ${TAR} ${TEMPTARGET}
fi
TAR=$TEMPTARGET

### convert to 8bit v3draw file
SUBBRAW=${OUTPUT}/"subbrain.v3draw"

if ( is_file_exist "$SUBBRAW" )
then
echo " SUBBRAW: $SUBBRAW exists"
else
#---exe---#
message " Converting to v3draw file "
checkInputs $SUBBRAIN
$Vaa3D -x ireg -f prepare20xData -o $SUBBRAW -p "#s $SUBBRAIN #t $SUBBRAIN"
fi

### shrinkage ratio
# VECTASHIELD/DPXEthanol = 0.82
# VECTASHIELD/DPXPBS = 0.86
DPXSHRINKRATIO=1.0

if [[ $MP =~ "Vector Shield Mounting" ]]
then
    DPXSHRINKRATIO=1.0
elif [[ $MP =~ "DPX Ethanol Mounting" ]]
then
    DPXSHRINKRATIO=0.82
elif [[ $MP =~ "DPX PBS Mounting" ]]
then
    DPXSHRINKRATIO=0.86
elif [[ $MP =~ "" ]]
then
    echo "Mounting protocol not specified, proceeding with DPXSHRINKRATIO=$DPXSHRINKRATIO"
else
    # other mounting protocol
    echo "Unknown mounting protocol: $MP"
fi
 

RESTX_X=`echo $DPXSHRINKRATIO*$RESTX_X | bc -l`
RESTX_Y=`echo $DPXSHRINKRATIO*$RESTX_Y | bc -l`
RESTX_Z=`echo $DPXSHRINKRATIO*$RESTX_Z | bc -l`

DPXRI=1.55

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
checkInputs $SUBBRAW
$Vaa3D -x ireg -f isampler -i $SUBBRAW -o $SUBTXIS -p "#x $SRX #y $SRY #z $SRZ"
fi

SUBTXPP=${OUTPUT}"/subtxPP.v3draw"

if ( is_file_exist "$SUBTXPP" )
then
echo " SUBTXPP: $SUBTXPP exists"
else
#---exe---#
message " Resizing the 20x subject "
checkInputs $SUBTXIS
$Vaa3D -x ireg -f prepare20xData -o $SUBTXPP -p "#s $SUBTXIS #t $TAR"
fi

SUBREF=$((SUBREF-1));
TARREF=$((TARREF-1));


##################
# Alignment
##################

#
### global alignment
#

message " Global alignment "

SUBTXGA=${OUTPUT}"/subtxGlobalAligned.v3draw"

if ( is_file_exist "$SUBTXGA" )
then
echo " SUBTXGA: $SUBTXGA exists"
else
#---exe---#
message " Global aligning the 20x subject "
checkInputs $SUBTXPP
$JBA -t $TAR -C $TARREF -s $SUBTXPP -c $SUBREF -w 0 -o $SUBTXGA -B 1280 -H 2
fi

if(($CHN>0))
then
SUBTXGACI=${OUTPUT}"/subtxGlobalAligned_c0.v3draw"
SUBTXLACI=${OUTPUT}"/subtxLocalAligned_c0.v3draw"
fi

if(($CHN>1))
then
SUBTXGACII=${OUTPUT}"/subtxGlobalAligned_c1.v3draw"
SUBTXLACII=${OUTPUT}"/subtxLocalAligned_c1.v3draw"
fi

if(($CHN>2))
then
SUBTXGACIII=${OUTPUT}"/subtxGlobalAligned_c2.v3draw"
SUBTXLACIII=${OUTPUT}"/subtxLocalAligned_c2.v3draw"
fi

if(($CHN>3))
then
SUBTXGACIV=${OUTPUT}"/subtxGlobalAligned_c3.v3draw"
SUBTXLACIV=${OUTPUT}"/subtxLocalAligned_c3.v3draw"
fi

SUBTXGACR=${OUTPUT}"/subtxGlobalAligned_c"${SUBREF}".v3draw"
SUBTXLACR=${OUTPUT}"/subtxLocalAligned_c"${SUBREF}".v3draw"

if ( is_file_exist "$SUBTXGACR" )
then
echo " SUBTXGACR: $SUBTXGACR exists"
else
#---exe---#
message " Splitting the color channels of the global aligned 20x subject "
checkInputs $SUBTXGA
$Vaa3D -x ireg -f splitColorChannels -i $SUBTXGA
fi

# further improve the global alignment

MOVNII=${OUTPUT}"/subtxGlobalAligned_c"${SUBREF}"_c0.nii"
FIXNII=${OUTPUT}"/temptargettx_c0.nii"

MAXITERATIONS=10000x10000x10000x0
SIMMETRIC=${OUTPUT}"/txmi"
AFFINEMATRIX=${OUTPUT}"/txmiAffine.txt"

if ( is_file_exist "$FIXNII" )
then
echo " FIXNII: $FIXNII exists"
else
#---exe---#
message " Converting 20x target into Nifti image "
checkInputs $TAR
$Vaa3D -x ireg -f NiftiImageConverter -i $TAR
fi

if ( is_file_exist "$MOVNII" )
then
echo " MOVNII: $MOVNII exists"
else
#---exe---#
message " Converting 20x subject into Nifti image "
checkInputs $SUBTXGACR
$Vaa3D -x ireg -f NiftiImageConverter -i $SUBTXGACR
fi

if ( is_file_exist "$AFFINEMATRIX" )
then
echo " AFFINEMATRIX: $AFFINEMATRIX exists"
else
#---exe---#
message " Global aligning 20x fly brain to 20x target brain "
checkInputs $MOVNII
checkInputs $FIXNII
$ANTS 3 -m MI[ $FIXNII, $MOVNII, 1, 32] -o $SIMMETRIC -i 0 --number-of-affine-iterations $MAXITERATIONS --rigid-affine false
fi

SUBTXGAIMP=${OUTPUT}"/subtxGlobalAligned_imprvd.v3draw"

if ( is_file_exist "$SUBTXGAIMP" )
then
echo " SUBTXGAIMP: $SUBTXGAIMP exists"
else
#---exe---#
message " Obtaining improved global alignment "
checkInputs $SUBTXGA
$Vaa3D -x ireg -f iwarp -o $SUBTXGAIMP -p "#s $SUBTXGA #t $TAR #a $AFFINEMATRIX"
fi

if(($CHN>0))
then
SUBTXGACI=${OUTPUT}"/subtxGlobalAligned_imprvd_c0.v3draw"
fi

if(($CHN>1))
then
SUBTXGACII=${OUTPUT}"/subtxGlobalAligned_imprvd_c1.v3draw"
fi

if(($CHN>2))
then
SUBTXGACIII=${OUTPUT}"/subtxGlobalAligned_imprvd_c2.v3draw"
fi

if(($CHN>3))
then
SUBTXGACIV=${OUTPUT}"/subtxGlobalAligned_imprvd_c3.v3draw"
fi

SUBTXGACR=${OUTPUT}"/subtxGlobalAligned_imprvd_c"${SUBREF}".v3draw"
SUBTXLACR=${OUTPUT}"/subtxLocalAligned_c"${SUBREF}".v3draw"

if ( is_file_exist "$SUBTXGACR" )
then
echo " SUBTXGACR: $SUBTXGACR exists"
else
#---exe---#
message " Splitting the color channels of the global aligned 20x subject "
checkInputs $SUBTXGAIMP
$Vaa3D -x ireg -f splitColorChannels -i $SUBTXGAIMP
fi

message " Local alignment "

if ( is_file_exist "$SUBTXLACR" )
then
echo " SUBTXLACR: $SUBTXLACR exists"
else
#---exe---#
message " Local aligning the 20x subject "
checkInputs $SUBTXGACR
checkInputs $TAR
$JBA -t $TAR -s $SUBTXGACR -w 10 -o $SUBTXLACR -L $TARMARKER -B 1280 -H 2
fi

CSVT=$SUBTXLACR"_target.csv"
CSVS=$SUBTXLACR"_subject.csv"

if(($CHN>1 && $SUBREF!=0))
then
if ( is_file_exist "$SUBTXLACI" )
then
echo " SUBTXLACI: $SUBTXLACI exists"
else
$JBA -t $TAR -s $SUBTXGACI -w 10 -o $SUBTXLACI -L $CSVT -l $CSVS -B 1280 -H 2
fi
fi

if(($CHN>1 && $SUBREF!=1))
then
if ( is_file_exist "$SUBTXLACII" )
then
echo " SUBTXLACII: $SUBTXLACII exists"
else
$JBA -t $TAR -s $SUBTXGACII -w 10 -o $SUBTXLACII -L $CSVT -l $CSVS -B 1280 -H 2
fi
fi

if(($CHN>2 && $SUBREF!=2))
then
if ( is_file_exist "$SUBTXLACIII" )
then
echo " SUBTXLACIII: $SUBTXLACIII exists"
else
$JBA -t $TAR -s $SUBTXGACIII -w 10 -o $SUBTXLACIII -L $CSVT -l $CSVS -B 1280 -H 2
fi
fi

if(($CHN>3 && $SUBREF!=3))
then
if ( is_file_exist "$SUBTXLACIV" )
then
echo " SUBTXLACIV: $SUBTXLACIV exists"
else
$JBA -t $TAR -s $SUBTXGACIV -w 10 -o $SUBTXLACIV -L $CSVT -l $CSVS -B 1280 -H 2
fi
fi

SUBTXLA=${OUTPUT}"/subtxLocalAligned.v3draw"

if ( is_file_exist "$SUBTXLA" )
then
echo " SUBTXLA: $SUBTXLA exists"
else
#---exe---#
message " Merging aligned colors into one image stack "

if(($CHN>0))
then
$Vaa3D -x ireg -f mergeColorChannels -i $SUBTXLACI -o $SUBTXLA
fi

if(($CHN>1))
then
$Vaa3D -x ireg -f mergeColorChannels -i $SUBTXLACI $SUBTXLACII -o $SUBTXLA
fi

if(($CHN>2))
then
$Vaa3D -x ireg -f mergeColorChannels -i $SUBTXLACI $SUBTXLACII $SUBTXLACIII -o $SUBTXLA
fi

if(($CHN>3))
then
$Vaa3D -x ireg -f mergeColorChannels -i $SUBTXLACI $SUBTXLACII $SUBTXLACIII $SUBTXLACIV -o $SUBTXLA
fi

fi


SUBTXALIGNED=${FINALOUTPUT}"/AlignedFlyBrain.v3draw"

if ( is_file_exist "$SUBTXALIGNED" )
then
echo " SUBTXALIGNED: $SUBTXALIGNED exists"
else
#---exe---#
message " Local aligning the 20x subject "
checkInputs $SUBTXLA
checkInputs $ATLAS
$Vaa3D -x ireg -f prepare20xData -o $SUBTXALIGNED -p "#s $SUBTXLA #t $ATLAS"
fi



##################
# evalutation
##################

AQ=${OUTPUT}"/AlignmentQuality.txt"

SUBREF=$((SUBREF+1))
#TARREF=$((TARREF+1))

if ( is_file_exist "$AQ" )
then
echo " AQ exists"
else
#---exe---#
message " Evaluating "
checkInputs $SUBTXALIGNED
$Vaa3D -x ireg -f esimilarity -o $AQ -p "#s $SUBTXALIGNED #cs $SUBREF #t $ATLAS"
fi

while read LINE
do
read SCORE
done < $AQ; 

QISCOREFILE=${FINALOUTPUT}"/QiScore.csv"

if ( is_file_exist "$QISCOREFILE" )
then
echo " QISCOREFILE: $QISCOREFILE exists"
else
#---exe---#
message " Calculating Qi scores "
checkInputs $CSVT
checkInputs $TARMARKER
checkInputs $LCRMASK
$Vaa3D -x ireg -f QiScoreStas -o $QISCOREFILE -p "#l $CSVT #t $TARMARKER #m $LCRMASK" 
fi

while read LINE
do
read QISCORE
done < $QISCOREFILE;


QIMSCOREFILE=$SUBTXLACR"_matching_quality.csv"

if ( is_file_exist "$QIMSCOREFILE" )
then
while read LINE
do
read QiQmScores
done < $QIMSCOREFILE
else
echo " QIMSCOREFILE: $QIMSCOREFILE does not exist!!!"
fi

IFS=',' read -ra SCORES <<< "$QiQmScores"

JBAQiScore=${SCORES[0]}
JBAQmScore=${SCORES[1]}

if [[ -f "$SUBTXALIGNED" ]]; then
META=${FINALOUTPUT}"/AlignedFlyBrain.properties"
echo "alignment.stack.filename=AlignedFlyBrain.v3draw" >> $META
echo "alignment.image.area=Brain" >> $META
echo "alignment.image.channels=$INPUT1_CHANNELS" >> $META
echo "alignment.image.refchan=$INPUT1_REF" >> $META
echo "alignment.space.name=$UNIFIED_SPACE" >> $META
echo "alignment.resolution.voxels=0.62x0.62x0.62" >> $META
echo "alignment.image.size=1024x512x218" >> $META
echo "alignment.objective=20x" >> $META
echo "alignment.quality.score.ncc=$SCORE" >> $META
echo "alignment.quality.score.qi=$QISCORE" >> $META
echo "alignment.quality.score.jbaqi=$JBAQiScore" >> $META
echo "alignment.quality.score.jbaqm=$JBAQmScore" >> $META
fi

compressAllRaw $Vaa3D $WORKDIR

