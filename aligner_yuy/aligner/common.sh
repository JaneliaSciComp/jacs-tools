#!/bin/bash
#
# Common functions for use in alignment scripts.
#

export UNIFIED_SPACE="JFRC2010_20x"
export ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS=$NSLOTS

readItemFromConf()
{
    local FILE="$1"
    local ITEM="$2"
    VAL=`grep "<$ITEM>.*<.$ITEM>" $FILE | sed -e "s/^.*<$ITEM/<$ITEM/" | cut -f2 -d">"| cut -f1 -d"<"`
    echo ${VAL}
}

parseParameter()
{
    local result_var="$1"
    local yaml_path="$2"
    # "-r" is necessary so that string values is returned without quotes
    # "// empty" is necessary to suppress "null" into empty string
    value=`yq -r "$yaml_path // empty" $YAML_CONFIG`
    eval $result_var="'$value'"
}

parseParameters()
{
    YAML_CONFIG=$1
    WORK_DIR="${2:-`pwd`"/temp"}"
    parseParameter CONFIG_FILE ".config_file"
    parseParameter TEMPLATE_DIR ".template_dir"
    parseParameter TOOL_DIR ".tool_dir"
    parseParameter GENDER ".gender"
    parseParameter MOUNTING_PROTOCOL ".mounting_protocol"
    parseParameter INPUT1_FILE ".inputs[0].filepath"
    parseParameter INPUT1_CHANNELS ".inputs[0].num_channels"
    parseParameter INPUT1_REF ".inputs[0].ref_channel"
    parseParameter INPUT1_RES ".inputs[0].voxel_size"
    parseParameter INPUT1_DIMS ".inputs[0].image_size"
    parseParameter INPUT1_NEURONS ".inputs[0].neuron_mask"
    parseParameter INPUT2_FILE ".inputs[1].filepath"
    parseParameter INPUT2_CHANNELS ".inputs[1].num_channels"
    parseParameter INPUT2_REF ".inputs[1].ref_channel"
    parseParameter INPUT2_RES ".inputs[1].voxel_size"
    parseParameter INPUT2_DIMS ".inputs[1].image_size"
    parseParameter INPUT2_NEURONS ".inputs[1].neuron_mask"

    INPUT1_RESX=$(echo $INPUT1_RES | cut -f1 -d'x')
    INPUT1_RESY=$(echo $INPUT1_RES | cut -f2 -d'x')
    INPUT1_RESZ=$(echo $INPUT1_RES | cut -f3 -d'x')
    INPUT1_DIMX=$(echo $INPUT1_DIMS | cut -f1 -d'x')
    INPUT1_DIMY=$(echo $INPUT1_DIMS | cut -f2 -d'x')
    INPUT1_DIMZ=$(echo $INPUT1_DIMS | cut -f3 -d'x')

    INPUT2_RESX=$(echo $INPUT2_RES | cut -f1 -d'x')
    INPUT2_RESY=$(echo $INPUT2_RES | cut -f2 -d'x')
    INPUT2_RESZ=$(echo $INPUT2_RES | cut -f3 -d'x')
    INPUT2_DIMX=$(echo $INPUT2_DIMS | cut -f1 -d'x')
    INPUT2_DIMY=$(echo $INPUT2_DIMS | cut -f2 -d'x')
    INPUT2_DIMZ=$(echo $INPUT2_DIMS | cut -f3 -d'x')
}

message()
{
    echo ""
    echo " ~ DEBUG: ${1} ~ "
    echo ""
}

is_file_exist()
{
    local f="$1"
    [[ -f "$f" ]] && return 0 || return 1
}

checkInputs()
{
   if ( is_file_exist "$1" );
   then
       message "$1 exists"
   else
       message "Input $1 does not exist!";
       exit 1;
   fi
}

ensureRawFile()
{
    local _Vaa3D="$1"
    local _WORKING_DIR="$2"
    local _FILE="$3"
    local _RESULTVAR="$4"
    local _EXT=${_FILE#*.}
    if [ "$_EXT" != "v3draw" ] && [ "$_EXT" != "raw" ] ; then
        local _PBD_FILE=$_FILE
        local _FILE_STUB=`basename $_PBD_FILE`
        _FILE="$_WORKING_DIR/${_FILE_STUB%.*}.v3draw"
        echo "Converting input file to V3DRAW format"
        $_Vaa3D -cmd image-loader -convert "$_PBD_FILE" "$_FILE"
    fi
    eval $_RESULTVAR="'$_FILE'"
}

ensureRawFileWdiffName()
{
    local _Vaa3D="$1"
    local _WORKING_DIR="$2"
    local _FILE="$3"
    local _OUTFILE="$4"
    local _RESULTVAR="$5"
    local _EXT=${_FILE#*.}

    if [ "$_EXT" == "v3dpbd" ]; 
    then
        local _FILE_STUB=`basename $_OUTFILE`
        _OUTFILE="$_WORKING_DIR/${_FILE_STUB%.*}.v3draw"
    if ( is_file_exist "$_OUTFILE" )
        then
            echo "_OUTFILE: $_OUTFILE exists."
        else
            message "Converting PBD to RAW format"
            $_Vaa3D -cmd image-loader -convert "$_FILE" "$_OUTFILE"
        fi

     elif [ "$_EXT" == "v3draw" ];
     then
        local _FILE_STUB=`basename $_OUTFILE`
        _OUTFILE="$_WORKING_DIR/${_FILE_STUB}"
        if ( is_file_exist "$_OUTFILE" )
        then
            echo "_OUTFILE: $_OUTFILE exists."
        else
            message "Creating symbolic link to neuron"
            ln -s "$_FILE" "$_OUTFILE"
        fi
     fi

    eval $_RESULTVAR="'$_OUTFILE'"
}

compressAllRaw()
{
    local _Vaa3D="$1"
    local _DIR="$2"
    echo "~ Compressing final outputs in: $_DIR"
    pushd $_DIR
    shopt -s nullglob
    # Recursively compress all v3draw files, and update propeties files to refer to the new v3dpbd files.
    for fin in $(find . -name "*.v3draw"); do
        fout=${fin%.v3draw}.v3dpbd
        $_Vaa3D -cmd image-loader -convert $fin $fout && rm $fin
    done
    shopt -u nullglob
    grep -rl --include=*.properties 'v3draw' ./ | xargs sed -i 's/v3draw/v3dpbd/g'
    popd
}
