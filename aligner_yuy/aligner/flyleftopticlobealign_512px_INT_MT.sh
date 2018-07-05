#!/bin/bash
#
# fly optic lobe alignment pipeline, version 1.1, 2013/8/13
#

################################################################################
#
# The pipeline is developed for aligning fly left optic lobe.
# Target brain's resolution (63x 0.38x0.38x0.38 um and 20x 0.62x0.62x0.62 um)
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
SUB=$INPUT1_FILE
SUBREF=$INPUT1_REF
NEURONS=$INPUT1_NEURONS
RESX=$INPUT1_RESX
RESY=$INPUT1_RESY
RESZ=$INPUT1_RESZ
CHN=$INPUT1_CHANNELS

# tools
Vaa3D=`readItemFromConf $CONFIGFILE "Vaa3D"`
ANTS=`readItemFromConf $CONFIGFILE "ANTSMT"`
WARP=`readItemFromConf $CONFIGFILE "WARPMT"`

Vaa3D=${TOOLDIR}"/"${Vaa3D}
ANTS=${TOOLDIR}"/"${ANTS}
WARP=${TOOLDIR}"/"${WARP}

# templates
ATLAS=`readItemFromConf $CONFIGFILE "atlasFBTX"`
TAR=`readItemFromConf $CONFIGFILE "tgtFROLSX"`
TARREF=`readItemFromConf $CONFIGFILE "REFNO"`
RESSX_X=`readItemFromConf $CONFIGFILE "VSZX_63X_IS"`
RESSX_Y=`readItemFromConf $CONFIGFILE "VSZY_63X_IS"`
RESSX_Z=`readItemFromConf $CONFIGFILE "VSZZ_63X_IS"`

CROPMATRIX=`readItemFromConf $CONFIGFILE "FROLCROPMATRIX"`
ROTMATRIX=`readItemFromConf $CONFIGFILE "FROLROTMATRIX"`
INVROTMATRIX=`readItemFromConf $CONFIGFILE "FROLINVROTMATRIX"`

TAR=${TMPLDIR}"/"${TAR}
ATLAS=${TMPLDIR}"/"${ATLAS}
CROPMATRIX=${TMPLDIR}"/"${CROPMATRIX}
ROTMATRIX=${TMPLDIR}"/"${ROTMATRIX}
INVROTMATRIX=${TMPLDIR}"/"${INVROTMATRIX}

# debug inputs
message "Inputs..."
echo "CONFIGFILE: $CONFIGFILE"
echo "TMPLDIR: $TMPLDIR"
echo "TOOLDIR: $TOOLDIR"
echo "WORKDIR: $WORKDIR"
echo "SUB: $SUB"
echo "SUBREF: $SUBREF"
echo "RESX: $RESX"
echo "RESY: $RESY"
echo "RESZ: $RESZ"
echo "NEURONS: $NEURONS"
message "Vars..."
echo "Vaa3D: $Vaa3D"
echo "ANTS: $ANTS"
echo "WARP: $WARP"
echo "TAR: $TAR"
echo "TARREF: $TARREF"
echo "ATLAS: $ATLAS"
echo "CROPMATRIX: $CROPMATRIX"
echo "ROTMATRIX: $ROTMATRIX"
echo "INVROTMATRIX: $INVROTMATRIX"
echo ""

if [ ! -d $WORKDIR ]; then 
mkdir $WORKDIR
fi

OUTPUT=$WORKDIR"/Outputs"
FINALOUTPUT=$WORKDIR"/FinalOutputs"

if [ ! -d $OUTPUT ]; then 
mkdir $OUTPUT
fi

if [ ! -d $FINALOUTPUT ]; then 
mkdir $FINALOUTPUT
fi

# convert inputs to raw format
ensureRawFile "$Vaa3D" "$OUTPUT" "$SUB" SUB
echo "RAW SUB: $SUB"

ensureRawFile "$Vaa3D" "$OUTPUT" "$NEURONS" NEURONS
echo "RAW NEURONS: $NEURONS"


##################
# Prepare Data
##################

# preprocess left optic lobe image stack

SUBPP=$OUTPUT"/subleftopticlobe.v3draw"

if ( is_file_exist "$SUBPP" )
then
echo "SUBPP: $SUBPP exists"
else
#---exe---#
message " Rotate left optic lobe and flip alogn x-axis "
$Vaa3D -x ireg -f ppleftopticlobe -i $SUB -o $SUBPP
fi

# preprocess separated neurons

NEURONSYFLIP=$OUTPUT"/subNeurons_yflipped.v3draw"

if ( is_file_exist "$NEURONSYFLIP" )
then
echo " NEURONSYFLIP: $NEURONSYFLIP exists"
else
#---exe---#
message " Y-Flipping neurons first "
$Vaa3D -x ireg -f yflip -i $NEURONS -o $NEURONSYFLIP
echo ""
fi

INPUTNEURONSPP=$OUTPUT"/subNeurons_pp.v3draw"

if ( is_file_exist "$INPUTNEURONSPP" )
then
echo "INPUTNEURONSPP: $INPUTNEURONSPP exists"
else
#---exe---#
message " Rotate left optic lobe and flip alogn x-axis "
$Vaa3D -x ireg -f ppleftopticlobe -i $NEURONSYFLIP -o $INPUTNEURONSPP
fi

NEURONSPP=$OUTPUT"/subNeurons.v3draw"

if ( is_file_exist "$NEURONSPP" )
then
echo " NEURONSPP: $NEURONSPP exists"
else
#---exe---#
message " Y-Flipping neurons first "
$Vaa3D -x ireg -f yflip -i $INPUTNEURONSPP -o $NEURONSPP
echo ""
fi

##################
# Alignment
##################

RIGHT_YML_FILE=$WORKDIR/align_right.yml
SUBPP_ESCAPED=${SUBPP//\//\\/}
echo "Got SUBPP_ESCAPED=$SUBPP_ESCAPED"
echo "Processing $YAML_CONFIG into $RIGHT_YML_FILE"
cat $YAML_CONFIG | sed -e "s/- filepath: .*/- filepath: $SUBPP_ESCAPED/" > $RIGHT_YML_FILE
echo "~ Executing flyrightopticlobealign_512px_INT_MT.sh with $RIGHT_YML_FILE"
$DIR/flyrightopticlobealign_512px_INT_MT.sh $RIGHT_YML_FILE $WORKDIR

