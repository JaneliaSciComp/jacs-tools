#!/bin/bash
#
# Common functions 
#

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
        echo "Converting PBD to RAW format"
        $_Vaa3D -cmd image-loader -convert "$_PBD_FILE" "$_FILE"
    fi
    eval $_RESULTVAR="'$_FILE'"
}

ensureLocalFile()
{
    local _SYNC_SCRIPT="$1"
    local _WORKING_DIR="$2"
    local _FILE="$3"
    local _RESULTVAR="$4"
    if [[ ! -e $_FILE ]]; then
        local _FILE_PATH=$_FILE
        local _FILE_STUB=`basename $_FILE_PATH`
        _FILE="$_WORKING_DIR/$_FILE_STUB"
        echo "Copying to local file"
        $_SYNC_SCRIPT "$_FILE_PATH" "$_FILE"
    fi
    eval $_RESULTVAR="'$_FILE'"
}

ensureUncompressedFile()
{
    local _WORKING_DIR="$1"
    local _FILE="$2"
    local _RESULTVAR="$3"
    local _INFILE=$_FILE
    local _FILE_STUB=`basename ${_FILE%.*}`
    case "$_FILE" in
    *.gz )
        _FILE="$_WORKING_DIR/$_FILE_STUB"
        gunzip -c $_INFILE > $_FILE
        ;;
    *.bz2 )
        echo "Using $NSLOTS cores for pbzip2"
        _FILE="$_WORKING_DIR/$_FILE_STUB"
        pbzip2 -dc -p$NSLOTS $_INFILE > $_FILE
        ;;
    *)
        ;;
    esac
    eval $_RESULTVAR="'$_FILE'"
}


