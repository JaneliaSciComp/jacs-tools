DIR=$(cd "$(dirname "$0")"; pwd)

TOOLS_DIR=$1
CONTAINER=$2
OUT=$3

NSLOTS=2
B1=$TEMPLATES_DIR/configured_templates
B2=$TEST_DATA_DIR

cat >$OUT/align.yml <<EOL
template_dir: $B1
inputs:
- area: Brain
  filepath: $B2/aligner_jrc2018_20x_40x/female_40x/BJD_113D09_AE_01-20180316_64_F3-Brain.v3dpbd
  gender: f
  image_size: 688x688x405
  mounting_protocol: DPX PBS Mounting
  neuron_mask: $B2/aligner_jrc2018_20x_40x/female_40x/BJD_113D09_AE_01-20180316_64_F3-Brain-ConsolidatedLabel.v3dpbd
  num_channels: 4
  objective: 40x
  ref_channel: 4
  voxel_size: 0.44x0.44x0.44
EOL

if [[ -e $OUT/stdout.log ]]; then
    echo "Test was already run"
else
    bsub -K $LSF_OPTS -e $OUT/stderr.log -o $OUT/stdout.log -n $NSLOTS $TOOLS_DIR/scripts/testAligner.sh \
        "singularity run -B $B1 -B $B2 --app align_both_ol_missing $CONTAINER" $NSLOTS $OUT $OUT/align.yml debug
fi

. $TOOLS_DIR/scripts/asserts.sh $OUT
assertExists REG_JRC2018_FEMALE_40x.v3dpbd
assertExists REG_UNISEX_40x.v3dpbd
assertExists REG_UNISEX_ColorMIP_HR.v3dpbd
assertContains REG_JRC2018_FEMALE_40x.properties "alignment.image.size=1427x664x413"
assertContains REG_JRC2018_FEMALE_40x.properties "alignment.resolution.voxels=0.44x0.44x0.44"
assertContains REG_UNISEX_40x.properties "alignment.image.size=1427x668x394"
assertContains REG_UNISEX_40x.properties "alignment.resolution.voxels=0.44x0.44x0.44"
assertContains REG_UNISEX_ColorMIP_HR.properties "alignment.image.size=1210x566x174"
assertContains REG_UNISEX_ColorMIP_HR.properties "alignment.resolution.voxels=0.5189161x0.5189161x1.0"

