

run("Misc...", "divide=Infinity save");
testArg=0;

//testArg="/test/63x_align/Temp1.nrrd,/test/63x_align/images/PRE_PROCESSED_01.nrrd,11";

if(testArg!=0)
args = split(testArg,",");
else
args = split(getArgument(),",");


TempPath = args[0];
SampPath = args[1];
NSLOTS = args[2];
NSLOTS=round(NSLOTS);

tempExt=File.exists(TempPath);
sampExt=File.exists(SampPath);

if(tempExt==1 && sampExt==1){
	open(TempPath);
	temp=getImageID();
	tempST=getTitle();
	
	open(SampPath);
	samp=getImageID;
	sampST=getTitle();
	
	setThreshold(1, 65535);
	run("Convert to Mask", "method=Huang background=Dark black");
	//run("Remove Outliers...", "radius=50 threshold=50 which=Dark stack");
	
	//print("Finished Remove Outliers...", "radius=50 threshold=50 which=Dark stack");
	
	run("Max Filter2D", "expansion=10 cpu="+NSLOTS+" scaling=3");
	print("Finished Max filter");
	
	run("Min Filter2D", "expansion=10 cpu="+NSLOTS+" scaling=3");
	print("Finished Min filter");
	
	run("16-bit");
	setMinAndMax(0, 255);
	run("Apply LUT", "stack");
	
	//setBatchMode(false);
	//updateDisplay();
	//"do"
	//exit();
	
	imageCalculator("AND create stack", ""+tempST+"",sampST);
	
	////run("Properties...", "channels=1 slices="+nSlices+" frames=1 unit=microns pixel_width="+TempVxWidth+" pixel_height="+TempVxHeight+" voxel_depth="+TempVxDepth+"");
	run("Nrrd Writer", "compressed nrrd="+TempPath);
	
	File.delete(SampPath);
}else{
	print("PreAlignerError: File is not exist; TempPath"+TempPath+"   SampPath; "+SampPath);
	logsum=getInfo("log");
	File.saveString(logsum, TempPath+"_CMTK_error.txt");
}
run("Misc...", "divide=Infinity save");
run("Quit");