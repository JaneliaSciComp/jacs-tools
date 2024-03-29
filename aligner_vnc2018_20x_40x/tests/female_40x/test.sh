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
- area: VNC
  filepath: $B2/aligner_vnc2018_20x_40x/female_40x/BJD_113D09_AE_01-20180316_64_F3-VNC.v3dpbd
  gender: f
  image_size: 913x865x330
  mounting_protocol: DPX PBS Mounting
  neuron_mask: $B2/aligner_vnc2018_20x_40x/female_40x/BJD_113D09_AE_01-20180316_64_F3-VNC-ConsolidatedLabel.v3dpbd
  num_channels: 4
  objective: 40x
  ref_channel: 4
  voxel_size: 0.44x0.44x0.44
EOL

if [[ -e $OUT/stdout.log ]]; then
    echo "Test was already run"
else
    bsub -K $LSF_OPTS -e $OUT/stderr.log -o $OUT/stdout.log -n $NSLOTS $TOOLS_DIR/scripts/testAligner.sh \
        "singularity run -B $B1 -B $B2 --app align $CONTAINER" $NSLOTS $OUT $OUT/align.yml debug
fi

. $TOOLS_DIR/scripts/asserts.sh $OUT
assertExists REG_JRC2018_VNC_FEMALE.properties
assertExists REG_JRC2018_VNC_FEMALE.v3dpbd
assertExists REG_UNISEX_VNC_ConsolidatedLabel.v3dpbd
assertExists REG_UNISEX_VNC.properties
assertExists REG_UNISEX_VNC.v3dpbd
assertContains REG_JRC2018_VNC_FEMALE.properties "alignment.image.size=573x1164x205"
assertContains REG_JRC2018_VNC_FEMALE.properties "alignment.resolution.voxels=0.461122x0.461122x0.70"
assertContains REG_UNISEX_VNC.properties "alignment.image.size=573x1119x219"
assertContains REG_UNISEX_VNC.properties "alignment.resolution.voxels=0.461122x0.461122x0.70"

