// v3dpbd to nrrd
setBatchMode(true);
args = split(getArgument(),",");

InputDirSeparation=args[0];
InputDir=args[1];
print("InputDirSeparation; "+InputDirSeparation);
print("VNC_InputDir; "+InputDir);

open(InputDir+"preprocResult_01.nrrd");
getVoxelSize(VxWidth, VxHeight, VxDepth, VxUnit);
close();

open(InputDirSeparation+"ConsolidatedSignal.v3dpbd");
getDimensions(width, height, channels, slices, frames);
run("Properties...", "channels="+channels+" slices="+slices+" frames=1 unit=microns pixel_width="+VxWidth+" pixel_height="+VxHeight+" voxel_depth="+VxDepth+"");

if(channels>1)
run("Split Channels");


for(i=1; i<=channels; i++){
	selectWindow("C"+i+"-ConsolidatedSignal.v3dpbd");
	run("Nrrd Writer", "compressed nrrd="+InputDir+"ConsolidatedSignal_"+i+".nrrd");
	close();
}
print("Done");
run("Quit");