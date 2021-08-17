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
  filepath: $B2/aligner_vnc2018_20x_40x/male_40x/BJD_122E10_AE_01-20180605_62_J4.v3dpbd
  gender: m
  image_size: 953x814x344
  mounting_protocol: DPX PBS Mounting
  neuron_mask: $B2/aligner_vnc2018_20x_40x/male_40x/BJD_122E10_AE_01-20180605_62_J4-ConsolidatedLabel.v3dpbd
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
assertExists REG_JRC2018_VNC_MALE.properties
assertExists REG_JRC2018_VNC_MALE.v3dpbd
assertExists REG_oldVNC_FEMALE.properties
assertExists REG_oldVNC_FEMALE.v3dpbd
assertExists REG_oldVNC_MALE.properties
assertExists REG_oldVNC_MALE.v3dpbd
assertExists REG_UNISEX_VNC_ConsolidatedLabel.v3dpbd
assertExists REG_UNISEX_VNC.properties
assertExists REG_UNISEX_VNC.v3dpbd
assertContains REG_JRC2018_VNC_MALE.properties "alignment.image.size=572x1164x229"
assertContains REG_JRC2018_VNC_MALE.properties "alignment.resolution.voxels=0.461122x0.461122x0.70"
assertContains REG_oldVNC_FEMALE.properties "alignment.image.size=512x1024x220"
assertContains REG_oldVNC_FEMALE.properties "alignment.resolution.voxels=0.4612588x0.4612588x0.7"
assertContains REG_oldVNC_MALE.properties "alignment.image.size=512x1100x220"
assertContains REG_oldVNC_MALE.properties "alignment.resolution.voxels=0.4611222x0.4611222x0.7"
assertContains REG_UNISEX_VNC.properties "alignment.image.size=573x1119x219"
assertContains REG_UNISEX_VNC.properties "alignment.resolution.voxels=0.461122x0.461122x0.70"

