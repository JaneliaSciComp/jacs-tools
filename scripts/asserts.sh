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

assertContains() {
    local _filename="$1"
    local _str="$2"
    if ! grep -q "$_str" $dir/$_filename; then
        echo "Expected output: $_str in $dir/$_filename"
        exit 1
    fi
}

