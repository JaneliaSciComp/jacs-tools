#!/bin/bash
#
# Common functions for use in alignment scripts.
#

export UNIFIED_SPACE="JFRC2010_20x"
export ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS=$NSLOTS

# Parse a YAML string at a given path into a variable
parseParameter()
{
    local result_var="$1"
    local yaml_path="$2"
    # "-r" is necessary so that string values is returned without quotes
    # "// empty" is necessary to suppress "null" into empty string
    value=`yq -r "$yaml_path // empty" $YAML_CONFIG`
    eval $result_var="'$value'"
}

# Parse a YAML array of strings into a comma-delimited string of values
parseArray()
{
    local result_var="$1"
    local yaml_path="$2"
    value=`yq -r "$yaml_path // empty | join(\",\")" $YAML_CONFIG`
    eval $result_var="'$value'"
}

parseParameters()
{
    YAML_CONFIG=$1
    WORK_DIR="${2:-`pwd`"/temp"}"

    parseParameter CONFIG_FILE ".config_file"
    parseParameter TEMPLATE_DIR ".template_dir"
    parseParameter TOOL_DIR ".tool_dir"

    parseParameter INPUT1_FILE ".inputs[0].filepath"
    parseParameter INPUT1_AREA ".inputs[0].area"
    parseParameter INPUT1_OBJECTIVE ".inputs[0].objective"
    parseParameter INPUT1_CHANNELS ".inputs[0].num_channels"
    parseParameter INPUT1_REF ".inputs[0].ref_channel"
    parseParameter INPUT1_RES ".inputs[0].voxel_size"
    parseParameter INPUT1_DIMS ".inputs[0].image_size"
    parseParameter INPUT1_NEURONS ".inputs[0].neuron_mask"
    parseParameter INPUT1_GENDER ".inputs[0].gender"
    parseParameter INPUT1_MOUNTING_PROTOCOL ".inputs[0].mounting_protocol"
    parseArray     INPUT1_TILES ".inputs[0].tiles"

    parseParameter INPUT2_FILE ".inputs[1].filepath"
    parseParameter INPUT2_AREA ".inputs[1].area"
    parseParameter INPUT2_OBJECTIVE ".inputs[1].objective"
    parseParameter INPUT2_CHANNELS ".inputs[1].num_channels"
    parseParameter INPUT2_REF ".inputs[1].ref_channel"
    parseParameter INPUT2_RES ".inputs[1].voxel_size"
    parseParameter INPUT2_DIMS ".inputs[1].image_size"
    parseParameter INPUT2_NEURONS ".inputs[1].neuron_mask"
    parseParameter INPUT2_GENDER ".inputs[1].gender"
    parseParameter INPUT2_MOUNTING_PROTOCOL ".inputs[1].mounting_protocol"
    parseArray     INPUT2_TILES ".inputs[1].tiles"

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
