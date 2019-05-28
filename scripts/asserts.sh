#
# Assertions on output files to use in regression tests
#

dir=$1

assertExists() {
    local _filename="$1"
    if [[ ! -e $dir/$_filename ]]; then
        echo "Expected output file: $dir/$_filename"
        exit 1
    fi
}

assertNotEmpty() {
    local _filename="$1"
    if [[ ! -s $dir/$_filename ]]; then
        echo "Expected not empty output file: $dir/$_filename"
        exit 1
    fi
}

assertEqual() {
    local _filename1="$1"
    local _filename2="$2"
    if diff $_filename1 $_filename2 > /dev/null; then
        : # do nothing
    else
        echo "Expected these files to be identical:"
        echo "  $_filename1"
        echo "  $_filename2"
        exit 1
    fi
}

assertContains() {
    local _filename="$1"
    local _str="$2"
    if ! grep -q "$_str" $dir/$_filename; then
        echo "Expected output: $_str in $dir/$_filename"
        exit 1
    fi
}

