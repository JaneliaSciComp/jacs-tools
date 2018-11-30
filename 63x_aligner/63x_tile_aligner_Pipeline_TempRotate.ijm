
FromDir=1; LateralMedianComparizon=0; LateralSingleComparizon=0; 
ThrdTrans=0;//frontal single img
TempCreationForTile=0;
HorizontalAlign=0;
TempCrop=0;
RotateSample=1;
Rev=false;
VLPRADD=0;
tempRotate=1;

startT=getTime();

if(RotateSample==1)
TempCrop=1;

rotationOriginal=0; TotalXtranslation=0; TotalYtranslation=0;
Frontal300pxSingle=0;
testArg=0;

starttime=getTime();
run("Misc...", "divide=Infinity save");

//for VMware Mac
//testArg = "/Volumes/otsuna/Masayoshi_63x/Failed_Pipeline/,JRC_SS24921_20161101_32_F1up.v3dpbd,/Volumes/otsuna/Masayoshi_63x/Failed_Pipeline/JRC_SS24921_20161101_32_F1up.v3dpbd,/Volumes/otsuna/Masayoshi_63x/Template/";

//testArg = "/Volumes/Registration2/63x_align/,GMR_14G10_AE_01_20130712_1_D1.h5j,/Volumes/Registration2/63x_align/GMR_14G10_AE_01_20130712_1_D1.h5j,/Volumes/Registration2/63x_align/Template/,0.188,0.38,12,63x";

//testArg = "/test/63x_align/OUTPUT/,GMR_14G10_AE_01_20130712_1_D1.h5j,/test/63x_align/GMR_14G10_AE_01_20130712_1_D1.h5j,/test/63x_align/Template/,0.188,0.38,12,63x";

//testArg = "H:/Registration2/Gab_failAlign/JRC_SS38164_20170712_31_D5/,JRC_SS38164_20170712_31_D5.h5j,H:/Registration2/Gab_failAlign/JRC_SS38164_20170712_31_D5.h5j,H:/Registration2/63x_align/Template/,0.188,0.38,12,63x"; // Gal


//testArg = "H:/Registration2/63x_align/Hemi_Brain/,GMR_14G10_AE_01_20130712_1_E2.v3dpbd,H:/Registration2/63x_align/Hemi_Brain/GMR_14G10_AE_01_20130712_1_E2.v3dpbd,H:/Registration2/63x_align/Template/,0.188,0.38,15,63x";

//testArg = "/test/63x_align/,Pre_PROCESSED,/test/63x_align/stitched-2547130846393925730.v3draw,/test/63x_align/Template/,0.188,0.38,11,63x,f";


//testArg = "N:/test_folder/,JRC_SS23221_20160803_31_E5.v3dpbd,N:/test_folder/JRC_SS23221_20160803_31_E5.v3dpbd,H:/Registration2/63x_align/Template/,0.188,0.38,15,63x";

//testArg = "/test/63x_align/,JRC_SS42965_20171006_21_C5.v3dpbd,/test/63x_align/JRC_SS42965_20171006_21_C5.v3dpbd,/test/63x_align/Template/,0.188,0.38,12,63x";

print("LateralSingleComparizon; "+LateralSingleComparizon);
print("LateralMedianComparizon; "+LateralMedianComparizon);
print("ThrdTrans; "+ThrdTrans);
print("HorizontalAlign; "+HorizontalAlign);

if(testArg!=0)
args = split(testArg,",");
else
args = split(getArgument(),",");

savedir = args[0];// save dir
filename = args[1];//file name
path = args[2];// full file path for inport LSM
MatchingFilesDir = args[3];
ResX = args[4];
ResZ = args[5];
NSLOTS = args[6];
objective = args[7];
gender=args[8];

NSLOTS=round(NSLOTS);
tempMask=MatchingFilesDir;

if(gender=="m")
temptype="JRC2018M"; // "JRC2018F", "JRC2018M"temptype string

if(gender=="f")
temptype="JRC2018F";

if(gender=="u")
temptype="JRC2018U";

TempNrrdPath=0; FrontalAVG100pxPath=0; Frontal100pxPath=0; CLAHEon=0; temp100pxHori=0;
temp300pxHori=0; temp300pxLateralPath=0; Auto300Generation="No";
if(FromDir==1){
	
	if(File.exists(savedir)!=1){
		File.makeDirectory(savedir);
		
	}
	
	
	print("savedir; "+savedir);
	print("filename; "+filename);
	print("path; "+path);
	print("MatchingFilesDir; "+MatchingFilesDir);
	print("ResX; "+ResX);
	print("ResZ; "+ResZ);
	print("NSLOTS; "+NSLOTS);
	print("objective; "+objective);
	
	listsave=getFileList(savedir);
	Array.sort(listsave);
	temp100pxFront=0; temp63x=0; startRegNo=1; temp100pxLateral665=0;
	
	
	List.clear();
	
	Auto300Generation = "No";// temptype string
	Rev=0;
	
	startRegNo=1;
	CLAHEon=false;
	
	print("temptype; "+temptype);
	savedirExt = File.exists(savedir);
	
	if(savedirExt!=1){
		File.makeDirectory(savedir);
	}
	
	linename=filename;
	
	logsum=getInfo("log");
	filepath=savedir+filename+"63x_brain_pre_aligner_log.txt";
	File.saveString(logsum, filepath);
	
	if(temptype=="Active_Image"){
		OriginaltempST=getTitle();
		Temp63X=getImageID();
		
		FrontalMED300px="AVG_35_A3_20130108185430177_100px.tif";
		Frontal100px="35_A3_Frontal_S34_100px.tif";// 3rd adjustment small temp frontal limited slices 24-39
		Frontal50px="35_A3_Frontal_S34_50px.tif";
		
		HoriSingle300px="35_A3_580_300px_Horizontal.tif";//"AVG_35_A3_269_305_Horizontal.tif";
		Hori100px="35_A3_580_100px_Horizontal.tif";//"AVG_35_A3_269_305_Horizontal.tif";
		Hori50px="35_A3_50px_Horizontal.tif";//"AVG_35_A3_269_305_Horizontal.tif";
		
		Lateral50px="Lateral_35_A3_50px_Sli831.tif";
		Lateral100px="Lateral_35_A3_100px_Sli831.tif";
		Lateral300px="Lateral_35_A3_300px_Sli831.tif";
		
		Small300pxImageGeneration(FrontalMED300px,Lateral300px,HoriSingle300px);
		TempSlice=nSlices();
		CanvasWidth=getWidth();
		CanvasHeight=getHeight();
		
		print("CanvasWidth; "+CanvasWidth+"   CanvasHeight; "+CanvasHeight);
		
		SmallCanvasWidth=round(CanvasWidth/CanvasHeight*100);
		ReslicedSmallZprojectionStart=round(ReslicedZprojectionStart/(CanvasWidth/SmallCanvasWidth));
		ReslicedSmallZprojectionEnd=round(ReslicedZprojectionEnd/(CanvasWidth/SmallCanvasWidth));
		
		//// Horizontal /////////////////////////////////////////////////////
		Direction="Horizontal";
		
		TempImageCreation=newArray(HoriSingle300px,Hori100px,Hori50px,tempMask,temp300pxHori,Direction);
		Small_Temp_Image_Creation (TempImageCreation);
		
		
		temp300pxHori=TempImageCreation[4];
		
		
		////// Lateral ///////////////////////////////////////////////////
		Direction="Lateral";
		
		TempImageCreation=newArray(Lateral300px,Lateral100px,Lateral50px,tempMask,temp300pxLateralPath,Direction);
		Small_Temp_Image_Creation (TempImageCreation);
		
		
		temp300pxLateralPath=TempImageCreation[4];
		
	}
	
	
	
	tempPreparationArray=newArray(40);
	tempPreparationArray[39] = MatchingFilesDir;
	tempPreparationArray[38] = savedir;
	tempPreparation (temptype,Auto300Generation,tempPreparationArray);
	
	OriginaltempST=tempPreparationArray[0];
	FrontalMED300px=tempPreparationArray[1];
	HoriSingle300px=tempPreparationArray[2];
	Lateral300px=tempPreparationArray[3];
	Frontal100px=tempPreparationArray[4];
	Hori100px=tempPreparationArray[5];
	Hori50px=tempPreparationArray[6];
	Lateral50px=tempPreparationArray[7];
	Lateral100px=tempPreparationArray[8];
	
	ReslicedZprojectionStart=tempPreparationArray[9];
	ReslicedZprojectionEnd=tempPreparationArray[10];
	ThiredZprojectionStart=tempPreparationArray[11];
	ThiredZprojectionEnd=tempPreparationArray[12];
	
	Temp63X=tempPreparationArray[13];//image ID
	TempSlice=tempPreparationArray[14];
	CanvasWidth=tempPreparationArray[15];
	CanvasHeight=tempPreparationArray[16];
	TempResliceLateralWidth=tempPreparationArray[17];
	TempVxWidth=tempPreparationArray[18];
	TempVxHeight=tempPreparationArray[19];
	TempVxDepth=tempPreparationArray[20];
	
	TempVxUnit=tempPreparationArray[21];
	SmallCanvasWidth=tempPreparationArray[22];
	ReslicedSmallZprojectionStart=tempPreparationArray[23];
	ReslicedSmallZprojectionEnd=tempPreparationArray[24];
	
	FrontalMED300pxWidth=tempPreparationArray[25];
	FrontalMED300pxHeight=tempPreparationArray[26];
	
	Temp100pxMED=tempPreparationArray[27];//image ID
	WidthFrontal100px=tempPreparationArray[28];
	HeightFrontal100px=tempPreparationArray[29];
	Frontal50px=tempPreparationArray[30];
	
	temp300pxLateralPath=tempPreparationArray[31];
	Horizon300Width=tempPreparationArray[32];
	Hrizon300height=tempPreparationArray[33];
	Lateral300Width=tempPreparationArray[34];
	Lateral300height=tempPreparationArray[35];
	tempMask=tempPreparationArray[36];
	Frontal300pxSingle=tempPreparationArray[37];
	
	print("CanvasWidth2; "+CanvasWidth+"   CanvasHeight2; "+CanvasHeight);
	
	
	selectWindow(Frontal50px);
	
	//setBatchMode(false);
	//updateDisplay();
	//"do"
	//exit();
	
	wait(100);
	call("java.lang.System.gc");
	
	a=0; nc82Nrrd=0;
	
	myDir=savedir;
	myDirimages=myDir+"images"+File.separator;
	
	dotIndex = lastIndexOf(filename, ".");
	
	if(dotIndex!=-1)
	trufilename = substring(filename,0,dotIndex); 
	else
	trufilename = filename;
	
	print("trufilename; "+trufilename);
	
	//	selectWindow(Lateral50px);
	//	setBatchMode(false);
	//			updateDisplay();
	//		"do"
	//			exit();
	
	noext2=0;
	setBatchMode(true);
	
	
	print("path; "+path);
	CLEAR_MEMORY();
	
	titlelistOri=getList("image.titles");
	
	IJ.redirectErrorMessages();
	open(path);
	
	titlelistAfter=getList("image.titles");
	
	if(titlelistOri.length == titlelistAfter.length){
		print("PreAlignerError: The file cannot open; "+path);
		logsum=getInfo("log");
		File.saveString(logsum, savedir+"FileBroke_63x_brain_pre_aligner_log.txt");
		
		run("Quit");
		
	}
	
	SampleTitle=getTitle();
	print("");
	print(SampleTitle);
	
	startT2=getTime();
	
	//// nc82 channel desision////////////////////////
	maxMean=0;
	getDimensions(width, height, channels, slices, frames);
	
	print("Channels; "+channels+"  slices; "+nSlices()/channels+"  voxel size changed");
	run("Properties...", "channels="+channels+" slices="+nSlices()/channels+" frames=1 unit=microns pixel_width="+ResX+" pixel_height="+ResX+" voxel_depth="+ResZ+"");
	
	
	print("channels; "+channels);
	
	logsum=getInfo("log");
	File.saveString(logsum, filepath);
	//	setBatchMode(false);
	//			updateDisplay();
	//			"do"
	//			exit();
	
	bitd=bitDepth();
	if(bitd==8){
		run("16-bit");
		
		run("Max value");/// need new plugin
		logsum=getInfo("log");
		endlog=lengthOf(logsum);
		maxposition=lastIndexOf(logsum, "Maxvalue;");
		minposition=lastIndexOf(logsum, "  Minvalue;");
		
		maxvalue0=substring(logsum, maxposition+10, minposition);
		maxvalue0=round(maxvalue0);
		
		setMinAndMax(0, maxvalue0);
		run("Apply LUT", "stack");
		
	}
	if(channels>1){
		print(channels+" channels");
		run("Split Channels");
		meanArray=newArray(channels);
		
		nc82Channel=channels;
		
		selectWindow("C"+nc82Channel+"-"+SampleTitle);
	}else{
		rename("C1-"+SampleTitle);
		nc82Channel=5;
		
		if(isOpen("C"+nc82Channel+"-"+SampleTitle))
		selectWindow("C"+nc82Channel+"-"+SampleTitle);
	}//if(channels>1){
	
	wait(100);
	call("java.lang.System.gc");
	
	nc82Ori=getImageID();
	nc82OriST= getTitle();
	run("Grays");
	
	getVoxelSize(OriSampWidth, OriSampHeight, OriSampDepth, OriSampUnit);
	
	print("OriSampWidth; "+OriSampWidth+"  OriSampHeight;"+OriSampHeight+"   OriSampDepth; "+OriSampDepth);
	gapVxXsize=abs(0.19-OriSampWidth); gapVxYsize=abs(0.19-OriSampHeight);
	
	if(gapVxXsize>0.01 && gapVxXsize>0.01){
		
		shrinkratio=OriSampWidth/0.19;
		resizeX=width*shrinkratio; resizeY=height*shrinkratio;
		print("adjusting image size");
		run("Size...", "width="+round(resizeX)+" height="+round(resizeY)+" depth="+nSlices+" constrain interpolation=None");
		//OriSampHeight=0.19; OriSampWidth=0.19; OriSampDepth=0.38;
		
		wait(100);
		call("java.lang.System.gc");
		
		OriSampUnit="microns";
		
		getVoxelSize(OriSampWidth, OriSampHeight, OriSampDepth, OriSampUnit);
		print("voxel size adjusted to 63x");
		print("OriSampWidth; "+OriSampWidth+"  OriSampHeight;"+OriSampHeight+"   OriSampDepth; "+OriSampDepth);
	}	//if(OriSampWidth==1 && OriSampHeight==1){
	
	logsum=getInfo("log");
	File.saveString(logsum, filepath);
	getVoxelSize(LVxWidth, LVxHeight, LVxDepth, LVxUnit);
	
	samporiH=round(getHeight());
	samporiW=round(getWidth());
	
	print("samporiW; "+samporiW+"   samporiH; "+samporiH);
	
	if(samporiW<2000 && samporiH<2000){
		sampleLongLengthW=round(CanvasWidth*1.1);//round(sqrt(samporiH*samporiH+samporiW*samporiW)*2);
		sampleLongLengthH=round(CanvasHeight*1.8);//round(sqrt(samporiH*samporiH+samporiW*samporiW));
	}else{
		sampleLongLengthW=round(CanvasWidth*1.4);//round(sqrt(samporiH*samporiH+samporiW*samporiW)*2);
		sampleLongLengthH=round(CanvasHeight*2.1);//round(sqrt(samporiH*samporiH+samporiW*samporiW));
	}
	TotalXtranslation=0; TotalYtranslation=0; TotalRotationFrontal=0;
	// creating 100 x 100px smaler image for image correlatio
	//File.makeDirectory(myDir);
	
	ExmyDirimages = File.exists(myDirimages);
	
	if(ExmyDirimages != 1)
	File.makeDirectory(myDirimages);
	
	print("myDirimages; "+myDirimages+"   sampleLongLengthW; "+sampleLongLengthW+"   sampleLongLengthH; "+sampleLongLengthH);
	
	logsum=getInfo("log");
	File.saveString(logsum, filepath);
	
	if(RotateSample==1){// rotation sample with 100px image size, XY is 0.19 micron
		selectImage(nc82Ori);
		
		run("Gamma ", "gamma=1.6 in=InMacro cpu="+NSLOTS+"");
		gammaup=getTitle();
		
		selectWindow(nc82OriST);
		close();
		
		wait(100);
		call("java.lang.System.gc");
		
		selectWindow(gammaup);
		rename(nc82OriST);
		nc82Ori=getImageID();
		
		//		setBatchMode(false);
		//								updateDisplay();
		//									"do"
		//									exit();
		
		run("Z Project...", "projection=Median");
		resetMinAndMax();
		run("16-bit");
		
		run("Enhance Contrast", "saturated=0.35");
		getMinAndMax(min, max);
		
		if(min!=0 && max!=65535)
		run("Apply LUT");
		
		
		WHratio=0; HWratio=0;
		Sample=getImageID();//median projection of sample
		rename("100pxSample.tif");
		
		if(temptype=="JRC2018U")
		frontal100vxsize=2.9370;
		
		if(temptype=="JRC2018F")
		frontal100vxsize=2.9186;
		
		if(temptype=="JRC2018M")
		frontal100vxsize=2.8240;
		
		zoomratio100=frontal100vxsize/0.1882680;
		
		
		pixRatio100=zoomratio100;//CanvasWidth/zoomratio100;		//	10.4366667
		
		print("HeightFrontal100px; "+HeightFrontal100px+"   pixRatio100; "+pixRatio100+"   samporiW/pixRatio100; "+samporiW/pixRatio100);
		run("Size...", "width="+round(samporiW/pixRatio100)+" height="+round(samporiH/pixRatio100)+" depth=1 interpolation=None");
		run("Canvas Size...", "width="+WidthFrontal100px+" height="+HeightFrontal100px+" position=Center zero");// 100 x 100
		
		
		Sample100px=getImageID();//small sample
		rename("Small_Sample100px.tif");
		
		ApplyLUT();//1725
		run("Grays");
		
		rotationp=55; rotationN=10; overLap=70; 
		
		//	setBatchMode(false);
		//	updateDisplay();
		//	"do"
		//	exit();
		
		a=getTime();
		
		sampimg="Small_Sample100px.tif"; tempimg=Frontal100px; Sdominant=1;
		CorrelationPlugin=newArray(sampimg, tempimg, rotationp, overLap,0,0,0,0,rotationN,Sdominant,NSLOTS);
		ImageCorrelationPlugin(CorrelationPlugin);// frontal 100px projection
		
		rotationOriginal=CorrelationPlugin[4];
		maxYOri=CorrelationPlugin[5];
		maxXOri=CorrelationPlugin[6];
		OBJScore=CorrelationPlugin[7];
		OBJScore=parseFloat(OBJScore);//Chaneg string to number
		//			maxrotation=49; maxY=8; maxX=2;
		print("rotationOriginal; "+rotationOriginal+"   maxX100px; "+maxXOri+"  maxY100px; "+maxYOri+"  OBJScore; "+OBJScore);
		
		
		
		logsum=getInfo("log");
		File.saveString(logsum, filepath);
		
		selectImage(Sample100px);
		
		//	setBatchMode(false);
		//		updateDisplay();
		//		"do"
		//		exit();
		
		close();
		
		///// original sample stack rotation /////////////////////////////
		
		selectImage(nc82Ori);
		
		OriginalBIG=getImageID();
		OriginalBIGST=getTitle();
		run("Duplicate...", "title=NC82original.tif duplicate");
		
		nc82Ori=getImageID();
		
		
		if(rotationOriginal!=0){
			if(getWidth!=sampleLongLengthW)
			run("Canvas Size...", "width="+sampleLongLengthW+" height="+sampleLongLengthH+" position=Center zero");
			
			run("Rotation Hideo", "rotate="+rotationOriginal+" 3d in=InMacro");
			run("Properties...", "channels=1 slices="+nSlices+" frames=1 unit=microns pixel_width="+OriSampWidth+" pixel_height="+OriSampHeight+" voxel_depth="+OriSampDepth+"");
		}//	if(rotationOriginal>0){
		
		run("Translate...", "x="+round(maxXOri*pixRatio100)+" y="+round(maxYOri*pixRatio100)+" interpolation=None stack");
		print("Translated "+nc82Ori+" Stack line 465; X; "+round(maxXOri*pixRatio100)+"   Y; "+round(maxYOri*pixRatio100));
		
		TotalXtranslation=TotalXtranslation+round(maxXOri*pixRatio100); 
		TotalYtranslation=TotalYtranslation+round(maxYOri*pixRatio100);
		TotalRotationFrontal=rotationOriginal;
		print("530 TotalXtranslation; "+TotalXtranslation+"   TotalYtranslation; "+TotalYtranslation+"   TotalRotationFrontal; "+TotalRotationFrontal);
	}//		if(RotateSample==1){
	
	//	setBatchMode(false);
	//	updateDisplay();
	//	"do"
	//	exit();
	
	selectImage(nc82Ori);// 1879 x 1879 px
	
	//	setBatchMode(false);
	//	updateDisplay();
	//	"do"
	//	exit();
	
	frontMarray = newArray(12);
	frontmedianPcreation (frontMarray,Sample,CanvasHeight,CanvasWidth,sampleLongLengthW,RotateSample,filepath,FrontalMED300px,nc82Ori,CLAHEon,sampleLongLengthH,FrontalMED300pxWidth,FrontalMED300pxHeight,temptype);
	
	selectWindow("Small_Sample.tif");
	
	rotationp=frontMarray[0];
	overLap=frontMarray[1];
	rotationN=frontMarray[2];
	//	pixRatio=frontMarray[3];
	Sample=frontMarray[4];
	
	
	//	setBatchMode(false);
	//	updateDisplay();
	//	"do"
	//	exit();
	
	/// frontal ///////////////////////////////////////////////////////////////
	if(RotateSample==0)
	a=getTime();
	print("Image correlation start");
	sampimg="Small_Sample.tif"; tempimg=""+FrontalMED300px+""; Sdominant=1;
	CorrelationPlugin=newArray(sampimg, tempimg, rotationp, overLap,0,0,0,0,rotationN,Sdominant,NSLOTS);
	ImageCorrelationPlugin(CorrelationPlugin);// frontal 100px projection
	
	maxrotation=CorrelationPlugin[4];
	maxY=CorrelationPlugin[5];
	maxX=CorrelationPlugin[6];
	OBJScore=CorrelationPlugin[7];
	
	frontal300vxsize=2.0255; zoomratio300=frontal300vxsize/0.1882680;
	pixRatio=zoomratio300;
	
	print("maxrotation300F; "+maxrotation+"   maxX; "+maxX+"  maxY; "+maxY+"  OBJScore; "+OBJScore+"  pixRatio; "+pixRatio);
	print("sampleLongLengthW; "+sampleLongLengthW+"  sampleLongLengthH"+sampleLongLengthH+"   CanvasWidth; "+CanvasWidth+"   CanvasHeight; "+CanvasHeight);
	selectImage(sampimg);
	close();
	//	setBatchMode(false);
	//			updateDisplay();
	//			"do"
	//			exit();
	
	endT=getTime();
	gapT=endT-startT;
	gapT2=endT-startT2;
	
	print("Time; "+(gapT/60)/1000+" min   After file open"+(gapT2/60)/1000+" min");
	
	logsum=getInfo("log");
	File.saveString(logsum, filepath);
	
	
	
	///// original sample stack rotation /////////////////////////////
	selectImage(nc82Ori);
	
	//		setBatchMode(false);
	//		updateDisplay();
	//		"do"
	//		exit();
	
	if(maxrotation!=0){
		if(getWidth!=sampleLongLengthW)
		run("Canvas Size...", "width="+sampleLongLengthW+" height="+sampleLongLengthH+" position=Center zero");
		run("Rotation Hideo", "rotate="+maxrotation+" 3d in=InMacro");
		//	setVoxelSize(OriSampWidth, OriSampHeight, OriSampDepth, OriSampUnit);
		run("Properties...", "channels=1 slices="+nSlices+" frames=1 unit=microns pixel_width="+OriSampWidth+" pixel_height="+OriSampHeight+" voxel_depth="+OriSampDepth+"");
		
	}//	if(maxrotation>0){
	
	//	setBatchMode(false);
	//	updateDisplay();
	//	"do"
	//	exit();
	
	//		print("929");
	
	run("Translate...", "x="+round(maxX*pixRatio)+" y="+round(maxY*pixRatio)+" interpolation=None stack");
	print("Translated "+nc82Ori+" Stack line 628; X; "+round(maxX*pixRatio)+"   Y; "+round(maxY*pixRatio));
	
	run("Canvas Size...", "width="+CanvasWidth+" height="+CanvasHeight+" position=Center zero");// equal xy to template
	nc82Ori=getImageID();
	nc82OriST=getTitle();
	//		print("936");
	TotalXtranslation=TotalXtranslation+round(maxX*pixRatio); 
	TotalYtranslation=TotalYtranslation+round(maxY*pixRatio);
	TotalRotationFrontal=TotalRotationFrontal+maxrotation;
	print("661 TotalXtranslation; "+TotalXtranslation+"   TotalYtranslation; "+TotalYtranslation);
	
	//	setBatchMode(false); // cropped top, but temporary file.
	//			updateDisplay();
	//			"do"
	//		exit();
	
	////// Lateral ////////////////////////////////////////////////////////////////////		
	maxrotationL=0;
	maxXL=0;
	maxYL=0;
	LateralW=0;
	zoomratiolateral300=0;
	OBJScoreL665=0;
	diminishMove=0;
	
	if(LateralSingleComparizon==1 || LateralMedianComparizon==1){
		
		run("Reslice [/]...", "output="+OriSampDepth+" start=Left rotate");//avoid
		resliceGamma=getImageID();
		resliceGammaST = getTitle();
		LateralH=getHeight();// resliced height
		LateralW=getWidth();//resliced width
		print("LateralW; "+LateralW+"   LateralH; "+LateralH);
		
		//		setBatchMode(false);
		//		updateDisplay();
		//		"do"
		//		exit();
		
		//// Lateral Median projection //////////////////////////////////////////
		if(LateralMedianComparizon==1){// small lateral sample Median image creation ///////////////////////
			
			run("Z Project...", "start="+ReslicedZprojectionStart+" stop="+ReslicedZprojectionEnd+" projection=Median");
			resetMinAndMax();
			run("16-bit");
			
			resliceH=round(getHeight());
			resliceW=getWidth();
			resliceLongLength=round(sqrt(resliceH*resliceH+resliceW*resliceW));
			
			SmallWidth=round(resliceW/7.25);
			run("Size...", "width="+SmallWidth+" height=100 interpolation=None");
			if(SmallWidth<100)
			run("Canvas Size...", "width=100 height=100 position=Center zero");
			
			ApplyLUT();
			
			resliceGammaAVsmall=getImageID();
			rename("resliceGammaAVsmall.tif");
			
			// small lateral template cropping and AIP creation //////////////////////
			if(TempCreationForTile==1){
				selectImage(nc82Ori);
				run("Z Project...", "projection=[Max Intensity]");
				MIPmask=getImageID();
				rename("MIPmask.tif");
				
				//	setBatchMode(false);
				//				updateDisplay();
				//				"do"
				//				exit();
				
				
				setThreshold(1, 65535);
				run("Convert to Mask");
				run("Remove Outliers...", "radius=50 threshold=50 which=Dark");
				
				run("16-bit");
				run("Mask255 to 4095");
				
				TempNrrdPath=tempMask+OriginaltempST;
				
				tempmaskEXI=File.exists(TempNrrdPath);
				if(tempmaskEXI==1){
					print("TempNrrdPath; "+TempNrrdPath);
					
					
					
					titlelistOri=getList("image.titles");
					
					IJ.redirectErrorMessages();
					open(TempNrrdPath);
					
					titlelistAfter=getList("image.titles");
					
					if(titlelistOri.length == titlelistAfter.length){
						print("PreAlignerError: The file cannot open; "+TempNrrdPath);
						logsum=getInfo("log");
						File.saveString(logsum, savedir+"TempCannotOpen_63x_brain_pre_aligner_log.txt");
						
						run("Quit");
					}
					
				}else{
					print("PreAlignerError: Template does not exist; "+TempNrrdPath);
					
					logsum=getInfo("log");
					File.saveString(logsum, filepath);
					
					run("Quit");
				}
				
				imageCalculator("AND create stack", ""+OriginaltempST+"","MIPmask.tif");//temp crop same as tile
			}else
			run("Duplicate...", "title=A.tif duplicate");
			run("Size...", "width="+SmallCanvasWidth+" height=100 depth="+round(nSlices/7.25)+" interpolation=None");
			rename("Smalltemp.tif");
			SmallTemp=getImageID();
			getVoxelSize(widthVXsmall, heightVXsmall, depthVXsmall, unitVX);
			
			if(isOpen(OriginaltempST)){
				selectWindow(OriginaltempST);
				close();
				selectWindow("Smalltemp.tif");
			}
			
			
			//		setBatchMode(false);
			//	updateDisplay();
			//	"do"
			//		exit();
			
			run("Reslice [/]...", "output="+depthVXsmall+" start=Left rotate");
			SmallTempReslice=getImageID();
			
			run("Z Project...", "start="+ReslicedSmallZprojectionStart+" stop="+ReslicedSmallZprojectionEnd+" projection=Median");
			resetMinAndMax();
			run("16-bit");
			rename("JFRC2013_63x_Tanya_temp100px_Lateral.tif");
			smallTempAIP=getImageID();
			run("Canvas Size...", "width=100 height=100 position=Center zero");
			ApplyLUT();
			
			//			setBatchMode(false);
			//					updateDisplay();
			//					"do"
			//					exit();
			selectImage(SmallTempReslice);
			close();
			
			
			if(TempCreationForTile==1){
				selectImage(MIPmask);
				close();
			}
			
			if(isOpen(SmallTemp)){
				selectImage(SmallTemp);
				close();
			}
			wait(100);
			call("java.lang.System.gc");
			maxYL=0; maxXL=0; OBJScoreL=0; maxrotationL=0;
			
			rotationp=15; rotationN=15; overLap=90; sampimg="resliceGammaAVsmall.tif"; tempimg=Lateral100px;
			Sdominant=0;
			CorrelationPlugin=newArray(sampimg, tempimg, rotationp, overLap,0,0,0,0,rotationN,Sdominant,NSLOTS);
			ImageCorrelationPlugin(CorrelationPlugin);// lateral median projection
			
			maxrotationL=CorrelationPlugin[4];
			maxYL=CorrelationPlugin[5];
			maxXL=CorrelationPlugin[6];
			OBJScoreL=CorrelationPlugin[7];
			
			//			maxrotationL=-3;   maxXL=-4;  maxYL=1;  
			
			print("Lateral maxrotation; "+maxrotationL+"   maxXL; "+maxXL+"  maxYL; "+maxYL+"  OBJScoreL; "+OBJScoreL);
			
			//			setBatchMode(false);
			//				updateDisplay();
			//				"do"
			//					exit();
			
			logsum=getInfo("log");
			File.saveString(logsum, filepath);
			
			selectImage(resliceGammaAVsmall);
			close();
			selectImage(smallTempAIP);
			close();
			wait(100);
			call("java.lang.System.gc");
		}//if(LateralMedianComparizon==1){
		
		selectImage(resliceGamma);// full size reslice sample
		
		//		setBatchMode(false);
		//		updateDisplay();
		//		"do"
		//			exit();
		//Lateral;  maxObjSliceOri; 776  maxObjScore; 710.011  maxObjSlice; 107
		
		resliceLongLength=0;
		///////// lateral single slice analysis ///////////////////////////
		if(LateralSingleComparizon==1){
			resliceLongLength=round(sqrt(LateralH*LateralH+LateralW*LateralW));
			
			depthLateral=round(nSlices/7.25);//248
			
			print("depthLateral; "+depthLateral+"   resliceLongLength: "+resliceLongLength);
			
			Lateral50pxvoxelsize=5.8740;
			
			run("Duplicate...", "title=Hstack_Small.tif duplicate");// for small horizontal stack
			
			changeratio50px=Lateral50pxvoxelsize/0.1882680;
			
			run("Size...", "width="+round(LateralW/changeratio50px)+" height="+round(LateralH/changeratio50px)+" depth="+round(depthLateral)+" average interpolation=None");//Bicubic
			run("Canvas Size...", "width=50 height=50 position=Center zero");// sample stack
			SampSmallHreslice=getImageID();
			
			//			setBatchMode(false);
			//			updateDisplay();
			//			"do"
			//				exit();
			
			ScanStartSlice=round(nSlices*0.3); ScanEndSlice=round(nSlices*0.7); SliMethod="Lateral";
			// 831 original slice number, 57 at small template
			
			stackScanArray=newArray(ScanStartSlice,ScanEndSlice,SampSmallHreslice,SliMethod,0,Lateral50px,NSLOTS);
			stack_scan(stackScanArray);
			maxObjSliceOri=stackScanArray[4];
			maxObjSliceOri=round(maxObjSliceOri);
			
			selectImage(resliceGamma);// original image lateral reslice
			selectWindow(resliceGammaST);
			setSlice(maxObjSliceOri);
			
			//	setBatchMode(false);
			//										updateDisplay();
			//									"do"
			//										exit();
			
			print("Lateral small slice single number after scan; "+maxObjSliceOri);
			run("Duplicate...", "title=Sample665.tif");
			rename("DUP_sample_665.tif");
			DUP_lateral665=getImageID();
			
			lateral300vxsize = 0.9789937; zoomratiolateral300 = lateral300vxsize/0.1882680;
			
			//	setBatchMode(false);
			//									updateDisplay();
			//									"do"
			//									exit();
			
			run("Size...", "width="+round(LateralW/zoomratiolateral300)+" height="+round(LateralH/zoomratiolateral300)+" interpolation=None");
			run("Canvas Size...", "width="+Lateral300Width+" height="+Lateral300height+" position=Center zero");
			//			resetMinAndMax();
			
			run("Enhance Contrast", "saturated=0.35");
			getMinAndMax(min, max);
			print("minL; "+min+"   maxL; "+max);
			if(min!=0 || max!=65535){
				run("Apply LUT");
				print("Apply LUT Lateral");
			}
			//		run("Gaussian Blur...", "sigma=0.5");
			
			//			setBatchMode(false);
			//								updateDisplay();
			//								"do"
			//								exit();
			
			logsum=getInfo("log");
			File.saveString(logsum, filepath);
			
			rotationp=20; rotationN=20; overLap=80; sampimg="DUP_sample_665.tif"; tempimg=Lateral300px;
			Sdominant=1;
			CorrelationPlugin=newArray(sampimg, tempimg, rotationp, overLap,0,0,0,0,rotationN,Sdominant,NSLOTS);
			ImageCorrelationPlugin(CorrelationPlugin);// single lateral slice 
			
			maxrotationL665=CorrelationPlugin[4];
			maxYL665=CorrelationPlugin[5];
			maxXL665=CorrelationPlugin[6];
			OBJScoreL665=CorrelationPlugin[7];
			selectImage(DUP_lateral665);	
			save(myDirimages+"Lateral300px_"+maxObjSliceOri+".tif");
			//			setBatchMode(false);
			//			updateDisplay();
			//			"do"
			//			exit();
			
			close();
			//		setBatchMode(false);
			//		updateDisplay();
			//		"do"
			//		exit();
			
			maxrotationL=0;
			maxXL=0;
			maxYL=0;
			
			if(maxrotationL665!=20 && maxrotationL665!=-20){
				maxrotationL=maxrotationL665;
				maxXL=maxXL665;
				maxYL=maxYL665;
			}
		}//if(LateralSingleComparizon==1){
		
		selectImage(resliceGamma);
		
		getVoxelSize(LVxWidth, LVxHeight, LVxDepth, LVxUnit);
		diminishMove=LVxWidth/LVxDepth;
		print("maxrotationL; "+maxrotationL+"   maxXL; "+maxXL+"   maxXL*zoomratiolateral300; "+maxXL*zoomratiolateral300+"  maxYL665; "+maxYL+"  OBJScoreL665; "+OBJScoreL665+"  diminishMove; "+diminishMove);// Y ELIMINATED diminishMove
		
		//			setBatchMode(false);
		//			updateDisplay();
		//			"do"
		//			exit();
		
		
		if(ThrdTrans==0)
		close();
		else{
			
			run("Translate...", "x="+round(maxXL*zoomratiolateral300)+" y="+round(maxYL*zoomratiolateral300)+" interpolation=None stack");
			print( "xL ="+round(maxXL*zoomratiolateral300)+" yL ="+round(maxYL*zoomratiolateral300));
			
			run("Canvas Size...", "width="+LateralW+" height="+round(CanvasHeight*1.2)+" position=Center zero");//LateralW//TempResliceLateralWidth
			
			
			run("Reslice [/]...", "output="+OriSampDepth+" start=Left rotate");//avoid
		}//else{
		FinalGamma=getImageID();
		
		if(isOpen(resliceGamma)){
			selectImage(resliceGamma);
			close();
		}
		
		selectImage(FinalGamma);
	}//if(LateralSingleComparizon==1 || LateralMedianComparizon==1){
	FinalGamma=getImageID();
	rename("FinalGamma.tif");
	
	
	if(isOpen(nc82Ori)){
		selectImage(nc82Ori);
		close();
	}
	if(isOpen(nc82OriST)){
		selectImage(nc82OriST);
		close();
	}
	
	CLEAR_MEMORY();
	//// original image translation /////////////////////////
	
	while(isOpen("Reslice of Reslice")){
		selectWindow("Reslice of Reslice");
		close();
	}
	
	
	
	OBJScore3=0; maxY3=0; maxrotation3=0; maxX3=0;
	FrontalChangeRatio300px=0;
	/// 3rd time XY shifting from frontal section //////////////////////
	if(ThrdTrans==1){// 3rd alignment from front
		selectImage(FinalGamma);
		
		HoriW=getWidth();
		HoriH=getHeight();
		print("HoriH; "+HoriH+"  HoriW; "+HoriW);
		depthLateral=round(nSlices/7.25);//248
		
		run("Duplicate...", "title=Fstack_Small.tif duplicate");// for small horizontal stack
		
		FrontalChangeRatio50px=5.8740/0.1882680;
		
		run("Size...", "width="+round(CanvasWidth/FrontalChangeRatio50px)+" height="+round(CanvasHeight/FrontalChangeRatio50px)+" depth="+round(depthLateral)+" average interpolation=None");
		run("Canvas Size...", "width=50 height=50 position=Center zero");// sample stack
		SampSmallF=getImageID();
		
		//							setBatchMode(false);
		//							updateDisplay();
		//							"do"
		//							exit();
		
		ScanStartSlice=round(depthLateral*0.2); ScanEndSlice=round(depthLateral*0.8); SliMethod="Frontal";
		
		print("SliMethod; "+SliMethod+"  ScanStartSlice; "+ScanStartSlice+"  ScanEndSlice; "+ScanEndSlice);
		logsum=getInfo("log");
		File.saveString(logsum, filepath);
		
		stackScanArray=newArray(ScanStartSlice,ScanEndSlice,SampSmallF,SliMethod,0,Frontal50px,NSLOTS);
		stack_scan(stackScanArray);
		
		if(isOpen("Fstack_Small.tif")){
			selectWindow("Fstack_Small.tif");
			close();
		}
		
		maxObjSliceOri=stackScanArray[4];
		
		selectWindow(Frontal300pxSingle);
		WidthFrontal300pxsingle=getWidth(); HeightFrontal300pxsingle=getHeight();
		
		FrontalChangeRatio300px=2.0978/0.1882680;
		selectImage(FinalGamma);
		//		print("1148");
		setSlice(maxObjSliceOri);
		run("Duplicate...", " ");
		run("Size...", "width="+round(CanvasWidth/FrontalChangeRatio300px)+" height="+round(CanvasHeight/FrontalChangeRatio300px)+" interpolation=None");
		run("Canvas Size...", "width="+WidthFrontal300pxsingle+" height="+HeightFrontal300pxsingle+" position=Center zero");
		rename("AIP3.tif");
		AIP3=getImageID();
		
		selectWindow(Frontal300pxSingle);
		W300px = getWidth(); H300px = getHeight();
		
		selectWindow("AIP3.tif");
		run("Canvas Size...", "width="+W300px+" height="+H300px+" position=Center zero");
		//		print("1161");
		resetMinAndMax();
		getMinAndMax(min, max);
		print("max; "+max);
		
		if(max<256){
			setMinAndMax(0, max);
			run("Apply LUT");
		}
		//	setBatchMode(false);
		//	updateDisplay();
		//	"do"
		//	exit();
		
		
		rotationp=15; rotationN=15; overLap=95; sampimg="AIP3.tif"; tempimg=Frontal300pxSingle; Sdominant=1;
		CorrelationPlugin=newArray(sampimg, tempimg, rotationp, overLap,0,0,0,0,rotationN,Sdominant,NSLOTS);
		ImageCorrelationPlugin(CorrelationPlugin);// frontal, limited slices projection
		
		maxrotation3=CorrelationPlugin[4];
		maxY3=CorrelationPlugin[5];
		maxX3=CorrelationPlugin[6];
		OBJScore3=CorrelationPlugin[7];
		
		selectImage(AIP3);
		close();
		
		
		selectWindow("FinalGamma.tif");
		close();
	}//if(ThrdTrans==1){// 3rd alignment from front
	
	logsum=getInfo("log");
	File.saveString(logsum, filepath);
	maxrotationH=0;
	
	
	if(tempRotate==0){
		/////////////////////////////////////// OriginalBIG
		selectImage(OriginalBIG);
		selectWindow(OriginalBIGST);
		//	setBatchMode(false);
		//				updateDisplay();
		//				"do"
		//				exit();
		
		ThreeDrotationArray=newArray(sampleLongLengthW,sampleLongLengthH,TotalRotationFrontal,OriSampWidth,OriSampHeight,OriSampDepth,0);
		ThreeDrotation (ThreeDrotationArray,TotalXtranslation,TotalYtranslation,myDir,trufilename,maxrotationL,maxXL,maxYL,CanvasHeight,zoomratiolateral300,ThrdTrans,maxrotation3,maxX3,maxY3,OBJScore3,FrontalChangeRatio300px,filepath,tempRotate,LateralSingleComparizon);
		
		selectWindow("FinalGamma.tif");
		FinalGamma=getImageID();// final 3D image
		run("Duplicate...", "title=FinalGammaoriginal.tif duplicate");
		FinalGammaoriginal=getImageID();
		
		selectWindow("FinalGamma.tif");
		run("Canvas Size...", "width="+CanvasWidth+" height="+CanvasHeight+" position=Center zero");
		
		
		//	setBatchMode(false);
		//				updateDisplay();
		//				"do"
		//				exit();
		
		// Horizontal re-slice ////////////////////////
		if(HorizontalAlign==1){
			selectImage(FinalGamma);
			run("Reslice [/]...", "output="+OriSampDepth+" start=Top");
			SampHstack=getImageID();
			Hwidth=getWidth();
			Hheight=getHeight();
			//		setBatchMode(false);
			//		updateDisplay();
			//		"do"
			//		exit();
			medianPH=0;
			
			if(medianPH==1){
				if(temptype!="35_A5"){
					setSlice(241);
					run("Duplicate...", " ");
					run("Canvas Size...", "width=750 height=750 position=Center zero");
					run("Size...", "width=100 height=100 constrain average interpolation=Bicubic");
					shiftX=7.5;
					shiftY=7.5;
				}else if(temptype=="35_A5" || temptype=="Active_Image"){
					run("Z Project...", "start="+HorizontalAvePstart+" stop="+HorizontalAvePend+" projection=Median");
					resetMinAndMax();
					run("16-bit");
					HoriH=getHeight();
					SmallHoriH=round(HoriH/7.25);
					run("Size...", "width=100 height="+SmallHoriH+" average interpolation=Bicubic");
					run("Canvas Size...", "width=100 height=100 position=Center zero");
					shiftX=18;
					shiftY=7.25;
					
				}
			}else{//if(medianPH==1){
				
				HoriH=getHeight();
				HoriW=getWidth();
				
				HoriChangeRatio50px=6.4081/0.1882680;
				
				getVoxelSize(widthH, heightH, depthH, unitH);
				
				depthHorizontal=round(nSlices/7.25);
				print("  SmallHoriH; "+round(HoriH/HoriChangeRatio50px)+"   HoriH; "+HoriH+"   HoriW; "+HoriW+"   HoriChangeRatio50px; "+HoriChangeRatio50px);
				
				run("Duplicate...", "title=Hstack_Small.tif duplicate");// for small horizontal stack
				
				run("Size...", "width="+round(HoriW/HoriChangeRatio50px)+" height="+round(HoriH/HoriChangeRatio50px)+" depth="+round(depthHorizontal/2)+" average interpolation=Bicubic");
				
				run("Canvas Size...", "width=50 height=30 position=Center zero");// sample stack
				SampSmallHreslice=getImageID();
				
				//	setBatchMode(false);
				//	updateDisplay();
				//	"do"
				//	exit();
				
				ScanStartSlice=17; ScanEndSlice=round(nSlices*0.5); SliMethod="Horizontal";
				
				stackScanArray=newArray(ScanStartSlice,ScanEndSlice,SampSmallHreslice,SliMethod,0,Hori50px,NSLOTS);
				stack_scan(stackScanArray);
				
				maxObjSliceOriH=stackScanArray[4];
				
				selectWindow(HoriSingle300px);
				Hori300H=getHeight();
				Hori300W=getWidth();
				
				print("Hrizon300height; "+Hrizon300height+"   Horizon300Width; "+Horizon300Width);
				
				selectImage(SampHstack);
				
				setSlice(maxObjSliceOriH);
				print("  maxObjSliceOriH Horizontal; "+maxObjSliceOriH+"  depthHorizontalSlineNo; "+depthHorizontal);
				
				//	setBatchMode(false);
				//	updateDisplay();
				//	"do"
				//	exit();
				
				HoriChangeRatio300px=1.0814/0.1882680;
				run("Duplicate...", " ");
				
				run("Size...", "width="+round(HoriW/HoriChangeRatio300px)+" height="+round(HoriH/HoriChangeRatio300px)+" average interpolation=None");
				run("Canvas Size...", "width="+Horizon300Width+" height="+Hrizon300height+" position=Center zero");
				
				//	setBatchMode(false);
				//	updateDisplay();
				//	"do"
				//	exit();
				
				
				//		if(tempis!="JFRC2010"){
				//			shiftX=18;
				//			shiftY=7.25;
				//		}else{
				//			shiftX=round(CanvasWidth/300);// already same size as template
				//			shiftY=round(HoriH/SmallHoriH);
				//		}
			}
			
			//	resetMinAndMax();
			//	run("Apply LUT");
			rename("SingleHorizontal.tif");
			SingleHorizontal=getImageID();
			
			run("Enhance Contrast", "saturated=0.3");
			run("Apply LUT");
			
			//	setBatchMode(false);
			//	updateDisplay();
			//	"do"
			//	exit();
			
			
			rotationp=20; rotationN=20; overLap=90; sampimg="SingleHorizontal.tif"; tempimg=HoriSingle300px;
			Sdominant=1;
			CorrelationPlugin=newArray(sampimg, tempimg, rotationp, overLap,0,0,0,0,rotationN,Sdominant,NSLOTS);
			ImageCorrelationPlugin(CorrelationPlugin);// horizontal limited slice projection
			
			maxrotationH=CorrelationPlugin[4];
			maxYH=CorrelationPlugin[5];
			maxXH=CorrelationPlugin[6];
			OBJScoreH=CorrelationPlugin[7];
			print("maxrotationH; "+maxrotationH+"   maxXH; "+maxXH+"  maxYH; "+maxYH+"  OBJScore; "+OBJScoreH);
			
			logsum=getInfo("log");
			File.saveString(logsum, filepath);
			
			OBJScoreH=parseFloat(OBJScoreH);//Chaneg string to number
			
			if(OBJScoreH>300){
				
				selectImage(SampHstack);
				getVoxelSize(LVxWidth, LVxHeight, LVxDepth, LVxUnit);
				run("Rotation Hideo", "rotate="+maxrotationH+" 3d in=InMacro");
				//		run("Translate...", "x="+round(maxXH*HoriChangeRatio300px)+" y="+round(maxYH*HoriChangeRatio300px)+" interpolation=None stack");//+round(maxYH*shiftY)+
				
				//		print("Horizontally translated; x; "+round(maxXH*HoriChangeRatio300px)+"   y; "+round(maxYH*HoriChangeRatio300px));
				setVoxelSize(LVxWidth, LVxHeight, LVxDepth, LVxUnit);
				run("Properties...", "channels=1 slices="+nSlices+" frames=1 unit=microns pixel_width="+LVxWidth+" pixel_height="+LVxHeight+" voxel_depth="+LVxDepth+"");
			}else{
				maxYH=0;
				maxXH=0;
				maxrotationH=0;
			}
			selectImage(SingleHorizontal);
			close();
			
			alreadyDone=1;
			selectImage(SampHstack);
			
			if(alreadyDone==0){
				setSlice(maxObjSliceOriH);
				run("Duplicate...", " ");
				
				run("Size...", "width=300 height="+SmallHoriH*3+" average interpolation=Bicubic");
				run("Canvas Size...", "width=300 height=160 position=Center zero");
				rename("SingleHorizontal.tif");
				SingleHorizontal=getImageID();
				
				rotationp=3; rotationN=3; overLap=95; sampimg="SingleHorizontal.tif"; tempimg=HoriSingle300px;
				Sdominant=1;
				CorrelationPlugin=newArray(sampimg, tempimg, rotationp, overLap,0,0,0,0,rotationN,Sdominant,NSLOTS);
				ImageCorrelationPlugin(CorrelationPlugin);// horizontal limited slice projection
				
				maxrotationH300=CorrelationPlugin[4];
				maxYH300=CorrelationPlugin[5];
				maxXH300=CorrelationPlugin[6];
				OBJScoreH300=CorrelationPlugin[7];
				print("maxrotationH300; "+maxrotationH300+"   maxXH300; "+maxXH300+"  maxYH300; "+maxYH300+"  OBJScore300; "+OBJScoreH300);
				
				selectImage(SampHstack);
				getVoxelSize(LVxWidth, LVxHeight, LVxDepth, LVxUnit);
				run("Rotation Hideo", "rotate="+maxrotationH300+" 3d in=InMacro");
				run("Translate...", "x="+round(maxXH300*(shiftX/3))+" y="+round(maxYH300*(shiftY/3))+" interpolation=None stack");
				run("Canvas Size...", "width="+Hwidth+" height="+Hheight+" position=Center zero");
				run("Properties...", "channels=1 slices="+nSlices+" frames=1 unit=microns pixel_width="+LVxWidth+" pixel_height="+LVxHeight+" voxel_depth="+LVxDepth+"");
				
			}//if(alreadyDone==0){
			run("Reslice [/]...", "output="+LVxDepth+" start=Top");
			SampFinalStack=getImageID();
			
			if(isOpen(SingleHorizontal)){
				selectImage(SingleHorizontal);
				close();
			}
			selectImage(SampHstack);
			close();
			
			selectImage(FinalGamma);
			close();
			
			while(isOpen("FinalGamma.tif")){
				selectWindow("FinalGamma.tif");
				close();
				print("extra FinalGamma.tif closed!");
			}
			
			selectImage(SampFinalStack);
			FinalGamma=getImageID();
			rename("FinalGamma.tif");
			
			wait(100);
			call("java.lang.System.gc");
		}else{//if(HorizontalAlign==1){
			selectImage(FinalGamma);
			rename("FinalGamma.tif");
		}//if(HorizontalAlign==1){
		//	setBatchMode(false);
		//	updateDisplay();
		//	"do"
		//	exit();
		
		if(TempCrop!=0){
			selectWindow("FinalGamma.tif");
			if(maxrotationH!=0){
				
				
				//	setBatchMode(false);
				//	updateDisplay();
				//	"do"
				//	exit();
				
				mediananalysis=0;
				
				if(mediananalysis==1){
					frontmedianPcreation (frontMarray,Sample,CanvasHeight,CanvasWidth,sampleLongLengthW,RotateSample,filepath,FrontalMED300px,FinalGamma,CLAHEon,sampleLongLengthH,FrontalMED300pxWidth,FrontalMED300pxHeight,temptype);
					
					a=getTime();
					print("Image correlation Frontal MedianP again");
					
					selectWindow("Small_Sample.tif");
					
					//		setBatchMode(false);
					//				updateDisplay();
					//				"do"
					//				exit();
					
					rotationp=20; rotationN=20; overLap=90;
					sampimg="Small_Sample.tif"; tempimg=""+FrontalMED300px+""; Sdominant=0;
					CorrelationPlugin=newArray(sampimg, tempimg, rotationp, overLap,0,0,0,0,rotationN,Sdominant,NSLOTS);
					ImageCorrelationPlugin(CorrelationPlugin);// frontal 100px projection
					
					maxrotation2nd=CorrelationPlugin[4];
					maxY2=CorrelationPlugin[5];
					maxX2=CorrelationPlugin[6];
					OBJScore=CorrelationPlugin[7];
					
					if(isOpen(sampimg)){
						selectWindow(sampimg);
						close();
					}
					
					TotalXtranslation=TotalXtranslation+round(maxX2*pixRatio);
					TotalYtranslation=TotalYtranslation+round(maxY2*pixRatio);
					TotalRotationFrontal=TotalRotationFrontal+maxrotation2nd;
				}
				
				if(mediananalysis==0){
					print("single slice frontal again");
					setSlice(maxObjSliceOri);
					run("Duplicate...", " ");
					run("Size...", "width="+round(CanvasWidth/FrontalChangeRatio300px)+" height="+round(CanvasHeight/FrontalChangeRatio300px)+" interpolation=None");
					run("Canvas Size...", "width="+WidthFrontal300pxsingle+" height="+HeightFrontal300pxsingle+" position=Center zero");
					rename("AIP3.tif");
					AIP3=getImageID();
					
					selectWindow(Frontal300pxSingle);
					W300px = getWidth(); H300px = getHeight();
					
					selectWindow("AIP3.tif");
					run("Canvas Size...", "width="+W300px+" height="+H300px+" position=Center zero");
					//		print("1161");
					resetMinAndMax();
					getMinAndMax(min, max);
					print("max; "+max);
					
					if(max<256){
						setMinAndMax(0, max);
						run("Apply LUT");
					}
					//	setBatchMode(false);
					//	updateDisplay();
					//	"do"
					//	exit();
					
					
					rotationp=15; rotationN=15; overLap=95; sampimg="AIP3.tif"; tempimg=Frontal300pxSingle; Sdominant=1;
					CorrelationPlugin=newArray(sampimg, tempimg, rotationp, overLap,0,0,0,0,rotationN,Sdominant,NSLOTS);
					ImageCorrelationPlugin(CorrelationPlugin);// frontal, limited slices projection
					
					if(isOpen("AIP3.tif")){
						selectWindow("AIP3.tif");
						close();
					}
					
					maxrotation2nd=CorrelationPlugin[4];
					maxY2=CorrelationPlugin[5];
					maxX2=CorrelationPlugin[6];
					OBJScore=CorrelationPlugin[7];
					
					TotalXtranslation=TotalXtranslation+round(maxX2*FrontalChangeRatio300px);
					TotalYtranslation=TotalYtranslation+round(maxY2*FrontalChangeRatio300px);
					TotalRotationFrontal=TotalRotationFrontal+maxrotation2nd;
				}//	if(mediananalysis==0){
				
				
				
				selectWindow("FinalGamma.tif");
				
				if(maxrotation2nd!=0){
					run("Rotation Hideo", "rotate="+maxrotation2nd+" 3d in=InMacro");
					run("Properties...", "channels=1 slices="+nSlices+" frames=1 unit=microns pixel_width="+OriSampWidth+" pixel_height="+OriSampHeight+" voxel_depth="+OriSampDepth+"");
				}
				
				if(mediananalysis==1){
					run("Translate...", "x="+round(maxX2*pixRatio)+" y="+round(maxY2*pixRatio)+" interpolation=None stack");
					print("Translated "+nc82Ori+" Stack line 698; X; "+round(maxX2*pixRatio)+"   Y; "+round(maxY2*pixRatio));
					
				}else if(mediananalysis==0){
					run("Translate...", "x="+round(maxX2*FrontalChangeRatio300px)+" y="+round(maxY2*FrontalChangeRatio300px)+" interpolation=None stack");
					print("Translated "+nc82Ori+" Stack line 698; X; "+round(maxX2*FrontalChangeRatio300px)+"   Y; "+round(maxY2*FrontalChangeRatio300px));
				}
				
				run("Canvas Size...", "width="+CanvasWidth+" height="+CanvasHeight+" position=Center zero");
				
				print("After Hori maxrotation2nd; "+maxrotation2nd+"   maxX; "+maxX2+"  maxY2; "+maxY2+"  OBJScore; "+OBJScore+"  pixRatio; "+pixRatio);
				print("sampleLongLengthW; "+sampleLongLengthW+"sampleLongLengthH; "+sampleLongLengthH+"   CanvasWidth; "+CanvasWidth+"   CanvasHeight; "+CanvasHeight);
				
			}//if(maxrotationH!=0){
			
			
			run("Duplicate...", "duplicate");
			rename("Mask3D.tif");
			Mask3D=getImageID();
			
			SliceNumberAdjustment(nSlices,TempSlice);
			
			//	setBatchMode(false);
			//	updateDisplay();
			//	"do"
			//	exit();
			
			setThreshold(1, 65535);
			run("Convert to Mask", "method=Huang background=Dark black");
			run("Remove Outliers...", "radius=50 threshold=50 which=Dark stack");
			
			//----------------Upper Brain area measurement ------------------
			
			mean1=0; mean2=0; mean3=0; mean4=0;
			
			run("Set Measurements...", "area mean centroid center perimeter fit shape redirect=None decimal=2");
			setSlice(337);
			//		makeRectangle(2343, 243, 57, 36);
			//		run("Measure");
			//		mean1 = getResult("Mean", 0);
			//		IJ.deleteRows(0, 1);
			
			//		makeRectangle(912, 237, 63, 51);
			//		run("Measure");
			//		mean2 = getResult("Mean", 0);
			//		IJ.deleteRows(0, 1);
			
			makeRectangle(780, 366, 78, 57);
			run("Measure");
			updateResults();
			mean3 = getResult("Mean", 0);
			IJ.deleteRows(0, 1);
			
			makeRectangle(2450, 366, 51, 63);
			run("Measure");
			updateResults();
			mean4 = getResult("Mean", 0);
			IJ.deleteRows(0, 1);
			
			if(mean3!=0){
				open(tempMask+"upper_brain_left.tif");
				imageCalculator("Add stack", "Mask3D.tif","upper_brain_left.tif");
				selectWindow("upper_brain_left.tif");
				close();
				selectWindow("Mask3D.tif");
				print("Dorsal_Temp_added!!");
			}
			
			if(mean4!=0){
				open(tempMask+"upper_brain_right.tif");
				imageCalculator("Add stack", "Mask3D.tif","upper_brain_right.tif");
				selectWindow("upper_brain_right.tif");
				close();
				selectWindow("Mask3D.tif");
				print("Dorsal_Temp_added!!");
			}
			
			
			if(VLPRADD==1){
				//-----------------Left VLPR measurement --------------
				
				mean1=0; mean2=0; mean3=0;
				
				setSlice(260);
				makeRectangle(836, 658, 28, 60);
				run("Measure");
				updateResults();
				mean1 = getResult("Mean", 0);
				IJ.deleteRows(0, 1);
				
				makeRectangle(840, 754, 52, 68);
				run("Measure");
				updateResults();
				mean2 = getResult("Mean", 0);
				IJ.deleteRows(0, 1);
				
				//			makeRectangle(964, 886, 48, 54);
				//			run("Measure");
				//			mean3 = getResult("Mean", 0);
				//			IJ.deleteRows(0, 1);
				
				if(mean1!=0 || mean2!=0 || mean3!=0){
					
					open(tempMask+"vlpr_left_maskUnisex.nrrd");
					imageCalculator("Add stack", "Mask3D.tif","vlpr_left_maskUnisex.nrrd");
					selectWindow("vlpr_left_maskUnisex.nrrd");
					close();
					selectWindow("Mask3D.tif");
					print("LeftVLPR_Temp_added!!");
				}
				
				//-----------------Right VLPR measurement --------------
				
				mean1=0; mean2=0; mean3=0;
				
				makeRectangle(2454, 594, 42, 88);
				run("Measure");
				updateResults();
				mean1 = getResult("Mean", 0);
				IJ.deleteRows(0, 1);
				
				makeRectangle(2462, 738, 26, 78);
				run("Measure");
				updateResults();
				mean2 = getResult("Mean", 0);
				IJ.deleteRows(0, 1);
				
				//			makeRectangle(2350, 878, 36, 38);
				//			run("Measure");
				//			mean3 = getResult("Mean", 0);
				//			IJ.deleteRows(0, 1);
				
				if(mean1!=0 || mean2!=0 || mean3!=0){
					
					open(tempMask+"vlpr_right_maskUnisex.nrrd");
					imageCalculator("Add stack", "Mask3D.tif","vlpr_right_maskUnisex.nrrd");
					selectWindow("vlpr_right_maskUnisex.nrrd");
					close();
					selectWindow("Mask3D.tif");
					print("RightVLPR_Temp_added!!");
				}//if(mean1!=0 || mean2!=0 || mean3!=0){
				
				//		setBatchMode(false);
				//		updateDisplay();
				//		"do"
				//		exit();
			}//if(VLPRADD==1){
			//		oritempslice=nSlices();
			
			//-----------------medulla measurement --------------
			setSlice(307);
			mean1=0; mean2=0; 
			
			makeRectangle(2886, 956, 63, 45);
			run("Measure");
			updateResults();
			mean1 = getResult("Mean", 0);
			IJ.deleteRows(0, 1);
			
			makeRectangle(369, 977, 71, 59);
			run("Measure");
			updateResults();
			mean2 = getResult("Mean", 0);
			IJ.deleteRows(0, 1);
			
			if(mean1!=0){
				
				open(tempMask+"ME_right_maskUnisex.png");
				imageCalculator("Add stack", "Mask3D.tif","ME_right_maskUnisex.png");
				selectWindow("ME_right_maskUnisex.png");
				close();
				selectWindow("Mask3D.tif");
				print("Right_ME_Temp_added!!");
			}//if(mean1!=0
			
			if(mean2!=0){
				
				open(tempMask+"ME_left_maskUnisex.png");
				imageCalculator("Add stack", "Mask3D.tif","ME_left_maskUnisex.png");
				selectWindow("ME_left_maskUnisex.png");
				close();
				selectWindow("Mask3D.tif");
				print("Left_ME_Temp_added!!");
			}//if(mean1!=0
			
			
			print("CanvasWidth; "+CanvasWidth+"   CanvasHeight; "+CanvasHeight);
			
			
			run("Max Filter2D", "expansion=10 cpu="+NSLOTS+" scaling=2");
			run("Min Filter2D", "expansion=10 cpu="+NSLOTS+" scaling=2");
			
			run("Mask area measure");
			logsum=getInfo("log");
			
			bestIndex = lastIndexOf(logsum, "BestSlice;");
			last2000Index = lastIndexOf(logsum, "last2000;");
			bestslice=substring(logsum, bestIndex+11, last2000Index-2);
			bestslice=round(bestslice);
			
			print("detected bestslice; "+bestslice);
			
			setSlice(bestslice);
			run("Select All");
			run("Copy");
			
			for(ibest=bestslice+1; ibest<=nSlices; ibest++){
				setSlice(ibest);
				run("Paste");
				
				if(ibest==1)
				print("pasted");
			}
			
			setSlice(233);
			run("Select All");
			run("Copy");
			
			for(ifront=1; ifront<=232; ifront++){
				setSlice(ifront);
				run("Paste");
				
				if(ifront==1)
				print("Front_pasted");
			}
			
			//		setBatchMode(false);
			//		updateDisplay();
			//		"do"
			//		exit();
			
			CLEAR_MEMORY();
			
			
			run("16-bit");
			run("Mask255 to 4095");
			
			TempNrrdPath=tempMask+OriginaltempST;
			
			tempmaskEXI=File.exists(TempNrrdPath);
			if(tempmaskEXI==1){
				print("TempNrrdPath; "+TempNrrdPath);
				
				titlelistTempNrrdPath=getList("image.titles");
				
				IJ.redirectErrorMessages();
				open(TempNrrdPath);
				
				titlelistAfter=getList("image.titles");
				
				if(titlelistTempNrrdPath.length == titlelistAfter.length){
					print("PreAlignerError: The file cannot open; "+TempNrrdPath);
					logsum=getInfo("log");
					File.saveString(logsum, savedir+"FileBroke_63x_brain_pre_aligner_log.txt");
					
					run("Quit");
				}
				
			}else{
				print("Template does not exist; "+TempNrrdPath);
				
				logsum=getInfo("log");
				File.saveString(logsum, filepath);
				
				run("Quit");
			}
			
			imageCalculator("AND create stack", ""+OriginaltempST+"","Mask3D.tif");
			
			run("Properties...", "channels=1 slices="+nSlices+" frames=1 unit=microns pixel_width="+TempVxWidth+" pixel_height="+TempVxHeight+" voxel_depth="+TempVxDepth+"");
			//run("Properties...", "channels=1 slices="+nSlices+" frames=1 unit=microns pixel_width="+OriSampWidth+" pixel_height="+OriSampHeight+" voxel_depth="+OriSampDepth+"");
			
			endT=getTime();
			gapT=endT-startT;
			gapT2=endT-startT2;
			
			print("Time before temp.nrrd writing; "+(gapT/60)/1000+" min   After file open"+(gapT2/60)/1000+" min");
			
			
			run("Nrrd Writer", "compressed nrrd="+myDir+"Temp"+startRegNo+".nrrd");
			rename("Temp.nrrd");
			
			run("Z Project...", "projection=[Max Intensity]");
			TempMIP=getImageID();
			rename("TempMIP.tif");
			
			tempW=getWidth;
			tempH=getHeight;
			
			print("tempW; "+tempW+"   tempH"+tempH);
			
			run("Enhance Contrast", "saturated=0.3");
			run("Apply LUT");
			run("8-bit");
			
			selectWindow("FinalGamma.tif");
			run("Z Project...", "projection=[Max Intensity]");
			SampMIP=getImageID();
			rename("SampMIP.tif");
			
			sampW=getWidth;
			sampH=getHeight;
			
			//	setBatchMode(false);
			//			updateDisplay();
			//			"do"
			//			exit();
			
			if(sampW!=tempW || sampH!=tempH){
				run("Size...", "width="+tempW+" height="+tempH+" average interpolation=Bicubic");
			}
			
			
			run("Enhance Contrast", "saturated=0.3");
			run("Apply LUT");
			run("8-bit");
			
			run("Merge Channels...", "c1=[TempMIP.tif] c2=[SampMIP.tif] c3=[TempMIP.tif]");
			saveAs("PNG", myDir+trufilename+"_TempP_SampG.png");
			close();
			
			
			//		setBatchMode(false);
			///		updateDisplay();
			//		"do"
			//		exit();
			
			selectWindow("Temp.nrrd");
			close();// cropped temp
			
			while (isOpen("Mask3D.tif")){
				selectWindow("Mask3D.tif");
				close();
			}
			
			selectWindow(OriginaltempST);
			close();
			
			titlelist3=getList("image.titles");
			print(" ");
			for( ititle=0; ititle<titlelist3.length; ititle++){
				print(titlelist3[ititle]);
			}
			
			logsum=getInfo("log");
			File.saveString(logsum, filepath);
			
			wait(100);
			call("java.lang.System.gc");
			
			//	CMTKcontents="#!/bin/sh"+"\r\n"+"# 2015-11-20_15.57.11"+"\r\n"+"cd \"/Volumes/Registration2/Tanya/Registration"+startRegNo+"\""+"\r\n"+"\"/Fiji.app/bin/cmtk/munger\" -b \"/Fiji.app/bin/cmtk\" -a -w -r 0102030405 -X 26 -C 8 -G 80 -R 4 -A '--accuracy 0.8' -W '--accuracy 0.8'  -T 4 -s ";
			//	filepathCMTK=myDir+"Tanya_63x"+trufilename+".command";
			//		File.saveString(CMTKcontents+"\"Temp"+startRegNo+".nrrd\" images", filepathCMTK);
			
		}//		if(TempCrop!=0){
		
		selectWindow("FinalGamma.tif");
		close();
		
		selectWindow("FinalGammaoriginal.tif");
		ApplyLUT();
		
		SliceNumberAdjustment(nSlices,TempSlice);
		
		run("Canvas Size...", "width="+round(CanvasWidth*1.1)+" height="+round(CanvasHeight*1.2)+" position=Center zero");
		
	}//if(tempRotate==0){
	
	if(tempRotate==1){
		
		while(isOpen("FinalGamma.tif")){
			selectWindow("FinalGamma.tif");
			close();
		}
		
		titlelistTempNrrdPath=getList("image.titles");
		
		IJ.redirectErrorMessages();
		open(MatchingFilesDir+OriginaltempST);
		
		titlelistAfter=getList("image.titles");
		
		if(titlelistTempNrrdPath.length == titlelistAfter.length){
			print("PreAlignerError: The file cannot open; "+MatchingFilesDir+OriginaltempST);
			logsum=getInfo("log");
			File.saveString(logsum, savedir+"FileBroke_63x_brain_pre_aligner_log.txt");
			
			run("Quit");
		}
		
		print("1862; OriginaltempST; "+OriginaltempST);
		
		getVoxelSize(OriTempWidth, OriTempHeight, OriTempDepth, OriTempUnit);
		Tempwidth = getWidth();
		Tempheight = getHeight();
		TempSlice=nSlices();
		
		//	setBatchMode(false);
		//			updateDisplay();
		//				"do"
		
		print("Tempwidth; "+Tempwidth);
		print("Tempheight; "+Tempheight);
		print("TotalRotationFrontal*-1; "+TotalRotationFrontal*-1);
		print("OriTempWidth; "+OriTempWidth);
		print("OriTempHeight; "+OriTempHeight);
		print("OriTempDepth; "+OriTempDepth);
		print("TotalXtranslation*-1; "+TotalXtranslation*-1);
		print("TotalYtranslation*-1; "+TotalYtranslation*-1);
		print("maxrotationL*-1; "+maxrotationL*-1);
		print("maxXL*-1; "+maxXL*-1);
		print("maxYL*-1; "+maxYL*-1);
		print("samporiH; "+samporiH);
		print("zoomratiolateral300; "+zoomratiolateral300);
		print("ThrdTrans; "+ThrdTrans);
		print("maxrotation3*-1; "+maxrotation3*-1);
		print("maxX3*-1; "+maxX3*-1);
		print("maxY3*-1; "+maxY3*-1);
		print("FrontalChangeRatio300px; "+FrontalChangeRatio300px);
		print("");
		
		ThreeDrotationArray=newArray(Tempwidth,Tempheight*1.6,TotalRotationFrontal*-1,OriTempWidth,OriTempHeight,OriTempDepth,0);
		ThreeDrotation (ThreeDrotationArray,TotalXtranslation*-1,TotalYtranslation*-1,myDir,trufilename,maxrotationL*-1,maxXL*-1,maxYL*-1,samporiH,zoomratiolateral300,ThrdTrans,maxrotation3*-1,maxX3*-1,maxY3*-1,OBJScore3,FrontalChangeRatio300px,filepath,tempRotate,LateralSingleComparizon);
		
		if(maxrotationL!=0 || maxXL!=0 || maxYL!=0)
		LateralW=ThreeDrotationArray[6];
		
		selectWindow("FinalGamma.tif");
		
		
		run("Canvas Size...", "width="+samporiW+150+" height="+samporiH+150+" position=Center zero");
		
		//		setBatchMode(false);
		//		updateDisplay();
		//			"do"
		//		exit();
		SliceNumberAdjustment(nSlices,TempSlice);
		
		run("Nrrd Writer", "compressed nrrd="+myDir+"Temp1.nrrd");
		rename("Temp.nrrd");
		
		run("Z Project...", "projection=[Max Intensity]");
		TempMIP=getImageID();
		rename("TempMIP.tif");
		
		tempW=getWidth;
		tempH=getHeight;
		
		print("tempW; "+tempW+"   tempH"+tempH);
		
		run("Enhance Contrast", "saturated=0.3");
		run("Apply LUT");
		run("8-bit");
		
		selectWindow(OriginalBIGST);
		run("Z Project...", "projection=[Max Intensity]");
		SampMIP=getImageID();
		rename("SampMIP.tif");
		
		sampW=getWidth;
		sampH=getHeight;
		
		//	setBatchMode(false);
		//			updateDisplay();
		//			"do"
		//			exit();
		
		if(sampW!=tempW || sampH!=tempH){
			run("Canvas Size...", "width="+tempW+" height="+tempH+" position=Center zero");
		}
		
		
		run("Enhance Contrast", "saturated=0.3");
		run("Apply LUT");
		run("8-bit");
		
		run("Merge Channels...", "c1=[TempMIP.tif] c2=[SampMIP.tif] c3=[TempMIP.tif]");
		saveAs("PNG", myDir+trufilename+"_TempP_SampG.png");
		close();
		
		
		selectImage(OriginalBIG);
		selectWindow(OriginalBIGST);
		ApplyLUT();
		
		SliceNumberAdjustment(nSlices,TempSlice);
		
		
		File.saveString(Tempwidth+"\n"+Tempheight+"\n"+TempSlice+"\n"+TotalRotationFrontal+"\n"+TotalXtranslation+"\n"+TotalYtranslation+"\n"+maxrotationL+"\n"+maxXL+"\n"+maxYL+"\n"+zoomratiolateral300+"\n"+ThrdTrans+"\n"+maxrotation3+"\n"+maxX3+"\n"+maxY3+"\n"+FrontalChangeRatio300px+"\n"+LateralW, savedir+linename+"_translation.txt");
	}//if(tempRotate==1){
	
	trufilename="PRE_PROCESSED";
	run("Nrrd Writer", "compressed nrrd="+myDirimages+trufilename+"_01.nrrd");
	close();
	
	wait(100);
	call("java.lang.System.gc");
	
	if(isOpen(nc82Ori)){
		selectImage(nc82Ori);
		close();
	}
	startNrrdNo=0;
	
	
	if(isOpen("C"+nc82Channel+"-"+SampleTitle)){
		selectWindow("C"+nc82Channel+"-"+SampleTitle);
		close();
	}
	
	wait(100);
	call("java.lang.System.gc");
	
	oneNrrd=File.exists(myDirimages+trufilename+"_01.nrrd"); 
	
	startNrrdNo=2;
	print("startNrrdNo; "+startNrrdNo);
	
	while(isOpen("Hstack_Small.tif")){
		selectWindow("Hstack_Small.tif");
		close();
	}
	
	if(isOpen("Reslice of C4-"+trufilename)){
		selectWindow("Reslice of C4-"+trufilename);
		close();
	}
	
	
	if(startNrrdNo!=0){
		
		for(iCH=1; iCH<=channels; iCH++){
			print(" ");
			titlelist4=getList("image.titles");
			for( ititle=0; ititle<titlelist4.length; ititle++){
				print(titlelist4[ititle]);
			}
			print("");
			print("iCH; "+iCH+"  channels; "+channels+"   nImages; "+nImages());
			print("iCH; "+iCH+"  nc82Channel; "+nc82Channel);
			if(iCH!=nc82Channel || isOpen(filename)){
				print("SampleTitle; "+SampleTitle+"  filename; "+filename);
				if(isOpen("C"+iCH+"-"+SampleTitle) || isOpen(SampleTitle) || isOpen(filename)){
					print("Channel iCH; "+iCH);
					
					if(isOpen("C"+iCH+"-"+SampleTitle)){
						selectWindow("C"+iCH+"-"+SampleTitle);
						print("Selected neuron window; "+"C"+iCH+"-"+SampleTitle);
					}else if(isOpen(SampleTitle)){
						selectWindow(SampleTitle);
						print("Selected neuron window; "+SampleTitle);
					}
					
					logsum=getInfo("log");
					File.saveString(logsum, filepath);
					
					if(tempRotate==0){
						getVoxelSize(OriSampWidth, OriSampHeight, OriSampDepth, OriSampUnit);
						if(gapVxXsize>0.01 && gapVxYsize>0.01){
							run("Size...", "width="+round(resizeX)+" height="+round(resizeY)+" depth="+nSlices+" constrain interpolation=None");
							
						}
						
						run("Canvas Size...", "width="+sampleLongLengthW+" height="+sampleLongLengthH+" position=Center zero");
						
						if((rotationOriginal+maxrotation)!=0)
						run("Rotation Hideo", "rotate="+rotationOriginal+maxrotation+" 3d in=InMacro");
						
						run("Properties...", "channels=1 slices="+nSlices+" frames=1 unit=microns pixel_width="+LVxWidth+" pixel_height="+LVxHeight+" voxel_depth="+LVxDepth+"");
						run("Translate...", "x="+TotalXtranslation+" y="+TotalYtranslation+" interpolation=None stack");
						run("Canvas Size...", "width="+round(CanvasWidth*1.1)+" height="+round(CanvasHeight*1.2)+" position=Center zero");
						
						print("Translated neurons line 1918; x; "+TotalXtranslation+"  y; "+TotalYtranslation);
						//	setBatchMode(false);
						//		updateDisplay();
						//		"do"
						//		exit();
						getVoxelSize(LVxWidth, LVxHeight, LVxDepth, LVxUnit);
						resliceSignalST=0;
						if(maxrotationL!=0 || maxXL!=0 || maxYL!=0){
							run("Reslice [/]...", "output="+OriSampDepth+" start=Left rotate");
							resliceSignal=getImageID(); resliceW=getWidth();
							resliceSignalST=getTitle();
							
							while(isOpen(SampleTitle)){
								selectWindow(SampleTitle);
								close();
							}
							
							selectImage(resliceSignal);
							if(maxrotationL!=0){
								
								run("Canvas Size...", "width="+resliceLongLength+" height="+resliceLongLength+" position=Center zero");
								run("Rotation Hideo", "rotate="+maxrotationL+" 3d in=InMacro");
								run("Properties...", "channels=1 slices="+nSlices+" frames=1 unit=microns pixel_width="+LVxWidth+" pixel_height="+LVxHeight+" voxel_depth="+LVxDepth+"");
							}
							
							if(ThrdTrans==1){
								run("Translate...", "x="+round(maxXL*zoomratiolateral300)+" y="+round(maxYL*zoomratiolateral300)+" interpolation=None stack");
								print( "xL ="+round(maxXL*zoomratiolateral300)+" yL ="+round(maxYL*zoomratiolateral300));
							}else{
								run("Translate...", "x="+round(maxXL*zoomratiolateral300)+" y=0 interpolation=None stack");
								print( "xL Trans ="+round(maxXL*zoomratiolateral300));
							}
							run("Canvas Size...", "width="+LateralW+" height="+round(CanvasHeight*1.2)+" position=Center zero");
							
							
							run("Reslice [/]...", "output="+OriSampDepth+" start=Left rotate");
							tempreslice = getImageID();
							
							if(isOpen(resliceSignalST)){
								selectImage(resliceSignal);
								close();
							}				
							
							selectImage(tempreslice);
						}
						
						if(ThrdTrans==1){
							if(maxrotation3!=0)
							run("Rotation Hideo", "rotate="+maxrotation3+" 3d in=InMacro");
							
							run("Translate...", "x="+round(maxX3*FrontalChangeRatio300px)+" y="+round(maxY3*FrontalChangeRatio300px)+" interpolation=None stack");
							
							print("Translated neurons line 1966; x; "+round(maxX3*FrontalChangeRatio300px)+"  y; "+round(maxY3*FrontalChangeRatio300px));
						}
						lateralfinneuron=getImageID();
						lateralfinneuronST = getTitle();
						print("lateralfinneuronST; "+lateralfinneuronST);
						
						if(lateralfinneuronST!="C"+iCH+"-"+SampleTitle){
							while(isOpen("C"+iCH+"-"+SampleTitle)){
								selectWindow("C"+iCH+"-"+SampleTitle);
								close();
							}
						}
						
						CLEAR_MEMORY();
						
						selectImage(lateralfinneuron);
						neuronFinal=getImageID();
						
						if(maxrotationH!=0){
							neuronHori=0;
							if(HorizontalAlign==1){
								run("Reslice [/]...", "output="+OriSampDepth+" start=Top");
								neuronHori=getImageID();
								Cheight=getHeight();
								getVoxelSize(LVxWidth, LVxHeight, LVxDepth, LVxUnit);//reslice
								run("Rotation Hideo", "rotate="+maxrotationH+" 3d in=InMacro");
								//		run("Translate...", "x="+round(maxXH*HoriChangeRatio300px)+" y="+round(maxYH*HoriChangeRatio300px)+" interpolation=None stack");//+round(maxYH*shiftY)+
								
								run("Properties...", "channels=1 slices="+nSlices+" frames=1 unit=microns pixel_width="+LVxWidth+" pixel_height="+LVxHeight+" voxel_depth="+LVxDepth+"");
								
								run("Canvas Size...", "width="+CanvasWidth+" height="+Cheight+" position=Center zero");
								run("Reslice [/]...", "output="+OriSampDepth+" start=Top");
							}//	if(HorizontalAlign==1){
							neuronFinal=getImageID();
							
							if(maxrotation2nd!=0){
								run("Rotation Hideo", "rotate="+maxrotation2nd+" 3d in=InMacro");
								run("Properties...", "channels=1 slices="+nSlices+" frames=1 unit=microns pixel_width="+OriSampWidth+" pixel_height="+OriSampHeight+" voxel_depth="+OriSampDepth+"");
								
							}
							
							run("Translate...", "x="+round(maxX2*pixRatio)+" y="+round(maxY2*pixRatio)+" interpolation=None stack");
							
						}//if(maxrotationH!=0){
						
						
						selectImage(neuronFinal);
						run("Canvas Size...", "width="+round(CanvasWidth*1.1)+" height="+round(CanvasHeight*1.2)+" position=Center zero");
					}//if(tempRotate==0){
					
					SliceNumberAdjustment(nSlices,TempSlice);
					run("Properties...", "channels=1 slices="+nSlices+" frames=1 unit=microns pixel_width="+OriSampWidth+" pixel_height="+OriSampHeight+" voxel_depth="+OriSampDepth+"");
					
					run("Nrrd Writer", "compressed nrrd="+myDirimages+trufilename+"_0"+startNrrdNo+".nrrd");
					close();
					
					
					if(isOpen("Reslice of C"+iCH+"-"+trufilename)){
						selectWindow("Reslice of C"+iCH+"-"+trufilename);
						close();
					}
					
					while(isOpen("Reslice of Reslice")){
						selectWindow("Reslice of Reslice");
						close();
					}
					
					while(isOpen(SampleTitle)){
						selectWindow(SampleTitle);
						close();
					}
					
					CLEAR_MEMORY();
					startNrrdNo=startNrrdNo+1;
				}//if(isOpen("C"+iCH+"-"+SampleTitle)){
			}//if(iCH!=nc82Channel){
		}//for(iCH=0; iCH<channels; iCH++){
	}else{
		//			print("Check nrrd files; "+trufilename);
		//			exit();
	}//if(startNrrdNo!=0){
	
	b=getTime();
	
	if(a!=0){
		gaptime=b-a;
		gaptimesec=gaptime/1000;
		gaptimesec=gaptimesec/60;
		print(gaptimesec+" min for the operation");
	}
//	if(dotIndexFolder==-1)
	startRegNo=startRegNo+1;
	
	if(nImages>10){
		NumberOfImages=getList("image.titles");
		
		OriNumbIMG=nImages; 
		
		for(NI=0; NI<OriNumbIMG; NI++){
			if(NumberOfImages[NI]!=Frontal300pxSingle && NumberOfImages[NI]!=Lateral300px && NumberOfImages[NI]!=Lateral100px && NumberOfImages[NI]!=HoriSingle300px && NumberOfImages[NI]!=Frontal50px && NumberOfImages[NI]!=OriginaltempST && NumberOfImages[NI]!=FrontalMED300px && NumberOfImages[NI]!=Frontal100px && NumberOfImages[NI]!=Hori100px && NumberOfImages[NI]!=Hori50px && NumberOfImages[NI]!=Lateral50px){
				print(NumberOfImages[NI]);
				selectWindow(NumberOfImages[NI]);
				close();
			}
		}//for(NI=0; NI<OriNumbIMG; NI++){
	}//if(nImages>3){
	//	open(filepathCMTK);
	//	saveAs("Text", filepathCMTK);
	
}//if(FromDir==1){

if(FromDir==0){
	Sample=getImageID();
	
	if(nc82Nrrd!=1){//if previous _01.nrrd file is not exist
		CorrelationArray=newArray(Sample, 0, 0, 0,0,0);
		a=getTime();
		ImageCorrelation(CorrelationArray)
		maxrotation=CorrelationArray[1];
	}
	
	
	setResult("Min Score",0,minscore);
	setResult("Max X",0,maxX-tempWW/2);
	setResult("Max Y",0,maxY-tempHH/2);
	setResult("rotation",0,maxrotation);
	b=getTime();
	gaptime=b-a;
	gaptimesec=gaptime/1000;
	gaptimesec=gaptimesec/60;
	print(gaptimesec+" min for the operation");
}//if(FromDir==0){

setBatchMode(false);
updateResults();

"Done";

endtime=getTime();
gaptime=endtime-starttime;

print("processing time; "+d2s(gaptime/60000, 2)+" min");

logsum=getInfo("log");
File.saveString(logsum, filepath);
run("Misc...", "divide=Infinity save");
run("Quit");

function ThreeDrotation (ThreeDrotationArray,TotalXtranslation,TotalYtranslation,myDir,trufilename,maxrotationL,maxXL,maxYL,CanvasHeight,zoomratiolateral300,ThrdTrans,maxrotation3,maxX3,maxY3,OBJScore3,FrontalChangeRatio300px,filepath,tempRotate,LateralSingleComparizon){
	imagesave=0;
	
	sampleLongLengthW=ThreeDrotationArray[0];
	sampleLongLengthH =ThreeDrotationArray[1];
	TotalRotationFrontal =ThreeDrotationArray[2];
	OriSampWidth =ThreeDrotationArray[3];
	OriSampHeight =ThreeDrotationArray[4];
	OriSampDepth =ThreeDrotationArray[5];
	
	OrigiRotate=getImageID();
	
	print("2184 tempRotate; "+tempRotate);
	
	run("Canvas Size...", "width="+sampleLongLengthW+" height="+sampleLongLengthH+" position=Center zero");//CanvasWidth//TempResliceLateralWidth
	
	if(tempRotate==0){
		
		if(TotalRotationFrontal!=0){
			run("Rotation Hideo", "rotate="+TotalRotationFrontal+" 3d in=InMacro");
			run("Properties...", "channels=1 slices="+nSlices+" frames=1 unit=microns pixel_width="+OriSampWidth+" pixel_height="+OriSampHeight+" voxel_depth="+OriSampDepth+"");
		}//	if(TotalRotationFrontal>0){
		
		run("Translate...", "x="+TotalXtranslation+" y="+TotalYtranslation+" interpolation=None stack");
		print("Translated 2102; x; "+TotalXtranslation+"  y; "+TotalYtranslation);
		
		if(imagesave==1){
			run("Z Project...", "projection=[Max Intensity]");
			
			saveAs("PNG", myDir+trufilename+"_1st_trans1005.png");
			close();
			selectImage(OrigiRotate);
		}
		
		// cropped upper part
		//	setBatchMode(false);
		//	updateDisplay();
		//	"do"
		//	exit();
		
		resliceGamma=0;
		if(maxrotationL!=0 || maxXL!=0 || maxYL!=0){
			//----------------lateral resliced --------------------------------------
			run("Reslice [/]...", "output="+OriSampDepth+" start=Left rotate");//avoid
			resliceGamma=getImageID();
			LateralW=getWidth();//resliced width
			resliceH=round(getHeight());
			
			//	resliceLongLength=round(sqrt(resliceH*resliceH+LateralW*LateralW));
			//setBatchMode(false);
			//			updateDisplay();
			//			"do"
			//			exit();
			getVoxelSize(LVxWidth, LVxHeight, LVxDepth, LVxUnit);
			if(maxrotationL!=0){
				run("Canvas Size...", "width="+round(LateralW*1.3)+" height="+round(CanvasHeight*1.2)+" position=Center zero");
				run("Rotation Hideo", "rotate="+maxrotationL+" 3d in=InMacro");
				run("Properties...", "channels=1 slices="+nSlices+" frames=1 unit=microns pixel_width="+LVxWidth+" pixel_height="+LVxHeight+" voxel_depth="+LVxDepth+"");
			}
			print("Reslice Depth; "+LVxDepth+"   round(maxXL*zoomratiolateral300); "+round(maxXL*zoomratiolateral300)+"  maxXL; "+maxXL);
			
			//	setBatchMode(false);
			//					updateDisplay();
			//					"do"
			//					exit();
			if(ThrdTrans==1){
				run("Translate...", "x="+round(maxXL*zoomratiolateral300)+" y="+round(maxYL*zoomratiolateral300)+" interpolation=None stack");
				print( "xL ="+round(maxXL*zoomratiolateral300)+" yL ="+round(maxYL*zoomratiolateral300));
			}else{
				run("Translate...", "x="+round(maxXL*zoomratiolateral300)+" y=0 interpolation=None stack");
				print( "xL Trans ="+round(maxXL*zoomratiolateral300));
			}
			run("Canvas Size...", "width="+LateralW+" height="+round(CanvasHeight*1.2)+" position=Center zero");//LateralW//TempResliceLateralWidth
			
			if(imagesave==1){
				run("Z Project...", "projection=[Max Intensity]");
				saveAs("PNG", myDir+trufilename+"_lateral_trans1053.png");
				close();
				selectImage(resliceGamma);
			}
			
			run("Reslice [/]...", "output="+OriSampDepth+" start=Left rotate");
		}//	if(maxrotationL!=0 || maxXL!=0 || maxYL!=0){
		
		rename("FinalGamma.tif");
		//-------------------- reslice finish ---------------------------------
		
		if(ThrdTrans==1){
			print("Translated ThrdTrans maxrotation3; "+maxrotation3+"   maxX3; "+maxX3+"  maxY3; "+maxY3+"  OBJScore3; "+OBJScore3+"   maxX3*FrontalChangeRatio300px; "+round(maxX3*FrontalChangeRatio300px)+"  maxY3*FrontalChangeRatio300px; "+round(maxY3*FrontalChangeRatio300px));
			
			if(maxrotation3!=0){
				getVoxelSize(LVxWidth, LVxHeight, LVxDepth, LVxUnit);
				run("Rotation Hideo", "rotate="+maxrotation3+" 3d in=InMacro");
				run("Properties...", "channels=1 slices="+nSlices+" frames=1 unit=microns pixel_width="+LVxWidth+" pixel_height="+LVxHeight+" voxel_depth="+LVxDepth+"");
			}
			run("Translate...", "x="+round(maxX3*FrontalChangeRatio300px)+" y="+round(maxY3*FrontalChangeRatio300px)+" interpolation=None stack");
		}//if(ThrdTrans==1){
	}//tempRotate==0
	
	if(tempRotate==1){
		
		if(ThrdTrans==1){
			print("Translated ThrdTrans maxrotation3; "+maxrotation3+"   maxX3; "+maxX3+"  maxY3; "+maxY3+"  OBJScore3; "+OBJScore3+"   maxX3*FrontalChangeRatio300px; "+round(maxX3*FrontalChangeRatio300px)+"  maxY3*FrontalChangeRatio300px; "+round(maxY3*FrontalChangeRatio300px));
			
			if(maxrotation3!=0){
				getVoxelSize(LVxWidth, LVxHeight, LVxDepth, LVxUnit);
				run("Rotation Hideo", "rotate="+maxrotation3+" 3d in=InMacro");
				run("Properties...", "channels=1 slices="+nSlices+" frames=1 unit=microns pixel_width="+LVxWidth+" pixel_height="+LVxHeight+" voxel_depth="+LVxDepth+"");
			}
			run("Translate...", "x="+round(maxX3*FrontalChangeRatio300px)+" y="+round(maxY3*FrontalChangeRatio300px)+" interpolation=None stack");
		}//if(ThrdTrans==1){
		
		resliceGamma=0;
		if(maxrotationL!=0 || maxXL!=0 || maxYL!=0){
			//----------------lateral resliced --------------------------------------
			run("Reslice [/]...", "output="+OriSampDepth+" start=Left rotate");//avoid
			resliceGamma=getImageID();
			LateralW=getWidth();//resliced width
			resliceH=round(getHeight());
			
			//	resliceLongLength=round(sqrt(resliceH*resliceH+LateralW*LateralW));
			//setBatchMode(false);
			//			updateDisplay();
			//			"do"
			//			exit();
			getVoxelSize(LVxWidth, LVxHeight, LVxDepth, LVxUnit);
			if(maxrotationL!=0){
				run("Canvas Size...", "width="+round(LateralW*1.3)+" height="+round(CanvasHeight*1.2)+" position=Center zero");
				run("Rotation Hideo", "rotate="+maxrotationL+" 3d in=InMacro");
				run("Properties...", "channels=1 slices="+nSlices+" frames=1 unit=microns pixel_width="+LVxWidth+" pixel_height="+LVxHeight+" voxel_depth="+LVxDepth+"");
			}
			print("Reslice Depth; "+LVxDepth+"   round(maxXL*zoomratiolateral300); "+round(maxXL*zoomratiolateral300)+"  maxXL; "+maxXL);
			
			//	setBatchMode(false);
			//					updateDisplay();
			//					"do"
			//					exit();
			if(ThrdTrans==1){
				run("Translate...", "x="+round(maxXL*zoomratiolateral300)+" y="+round(maxYL*zoomratiolateral300)+" interpolation=None stack");
				print( "xL ="+round(maxXL*zoomratiolateral300)+" yL ="+round(maxYL*zoomratiolateral300));
			}else{
				run("Translate...", "x="+round(maxXL*zoomratiolateral300)+" y=0 interpolation=None stack");
				print( "xL Trans ="+round(maxXL*zoomratiolateral300));
			}
			run("Canvas Size...", "width="+LateralW+" height="+round(CanvasHeight*1.2)+" position=Center zero");//LateralW//TempResliceLateralWidth
			
			if(imagesave==1){
				run("Z Project...", "projection=[Max Intensity]");
				saveAs("PNG", myDir+trufilename+"_lateral_trans1053.png");
				close();
				selectImage(resliceGamma);
			}
			
			run("Reslice [/]...", "output="+OriSampDepth+" start=Left rotate");
		}//	if(maxrotationL!=0 || maxXL!=0 || maxYL!=0){
		
		rename("FinalGamma.tif");
		
		run("Translate...", "x="+TotalXtranslation+" y="+TotalYtranslation+" interpolation=None stack");
		print("Translated 2102; x; "+TotalXtranslation+"  y; "+TotalYtranslation);
		
		if(TotalRotationFrontal!=0){
			run("Rotation Hideo", "rotate="+TotalRotationFrontal+" 3d in=InMacro");
			run("Properties...", "channels=1 slices="+nSlices+" frames=1 unit=microns pixel_width="+OriSampWidth+" pixel_height="+OriSampHeight+" voxel_depth="+OriSampDepth+"");
		}//	if(TotalRotationFrontal>0){
		
	}//if(tempRotate==1){
	
	
	//	setBatchMode(false);
	//	updateDisplay();
	//	"do"
	//	exit();
	
	logsum=getInfo("log");
	File.saveString(logsum, filepath);
	
	if(isOpen(resliceGamma)){
		selectImage(resliceGamma);
		close();
	}
	
	if(maxrotationL!=0 || maxXL!=0 || maxYL!=0){
		selectImage(OrigiRotate);
		close();
		print("OrigiRotate closed; "+OrigiRotate);
	}
	
	wait(100);
	call("java.lang.System.gc");
	
	if(maxrotationL!=0 || maxXL!=0 || maxYL!=0)
	ThreeDrotationArray[6]=LateralW;
	
}//function ThreeDrotation

function frontmedianPcreation (frontMarray,Sample,CanvasHeight,CanvasWidth,sampleLongLengthW,RotateSample,filepath,FrontalMED300px,nc82Ori,CLAHEon,sampleLongLengthH,FrontalMED300pxWidth,FrontalMED300pxHeight,temptype){
	
	run("Z Project...", "projection=Median");
	resetMinAndMax();
	run("16-bit");
	
	Sample=getImageID();//median projection of sample
	
	WHratio=0; HWratio=0;
	
	selectWindow(FrontalMED300px);
	frontalWidth=getWidth(); frontalHeight=getHeight();
	
	if(temptype=="JRC2018U")
	frontal300vxsize=2.0255;
	
	if(temptype=="JRC2018F")
	frontal300vxsize=2.0844;
	
	if(temptype=="JRC2018M")
	frontal300vxsize=1.9748;
	
	zoomratio300=frontal300vxsize/0.1882680;
	pixRatio=zoomratio300;
	
	
	
	
	selectImage(Sample);
	samporiH=getHeight();
	samporiW=getWidth();
	
	print("samporiH; "+samporiH+"   samporiW; "+samporiW+"   sampleLongLengthW; "+sampleLongLengthW+"  sampleLongLengthH; "+sampleLongLengthH);
	
	//	setBatchMode(false);
	//	updateDisplay();
	//	"do"
	//	exit();
	
	logsum=getInfo("log");
	File.saveString(logsum, filepath);
	
	CenterOnly=0;
	if(samporiW==samporiH)
	CenterOnly=1;
	
	run("Size...", "width="+round(samporiW/pixRatio)+" height="+round(samporiH/pixRatio)+" depth="+nSlices+" interpolation=None");
	run("Canvas Size...", "width="+frontalWidth+" height="+frontalHeight+" position=Center zero");
	
	Sample=getImageID();//small sample
	
	
	rename("Small_Sample.tif");
	resetMinAndMax();
	run("Apply LUT");
	
	
	logsum=getInfo("log");
	File.saveString(logsum, filepath);
	
	//setBatchMode(false);
	//		updateDisplay();
	//		"do"
	//		exit();
	
	selectImage(nc82Ori);
	if(CLAHEon==1){// from dialog
		run("Duplicate...", "duplicate");
		rename("Mask3D.tif");
		Mask3D=getImageID();
		
		run("Max value");/// need new plugin
		logsum=getInfo("log");
		endlog=lengthOf(logsum);
		maxposition=lastIndexOf(logsum, "Maxvalue;");
		minposition=lastIndexOf(logsum, "  Minvalue;");
		
		maxvalue0=substring(logsum, maxposition+10, minposition);
		maxvalue0=round(maxvalue0);
		
		minvalue0=substring(logsum, minposition+11, endlog);
		minvalue0=round(minvalue0);
		
		setMinAndMax(minvalue0, maxvalue0);
		
		run("8-bit");
		sumlower=0;
		
		// to get average threshold ///////////////////
		for(islice=1; islice<=nSlices; islice++){
			setSlice(islice);
			//	setAutoThreshold("Default dark");
			setAutoThreshold("Huang dark");
			getThreshold(lower, upper);
			
			sumlower=sumlower+lower;
		}
		avethreDef=round(sumlower/nSlices);
		avethreDef=round(avethreDef-(avethreDef*0.1));
		
		// creating mask ////////////////////////
		for(i4=1; i4<=nSlices; i4++){
			showStatus("Creating Mask");
			prog=i4/nSlices;
			showProgress(prog);
			
			setSlice(i4);
			setMinAndMax(0, 255);
			
			setAutoThreshold("Huang dark");
			//	setAutoThreshold("Default dark");
			
			getThreshold(lower, upper);
			
			List.set("Lowthre1st"+i4-1, lower)
		}//for(i=1; i<=nSlices; i++){
		
		print("avethreDef; "+avethreDef);
		
		for(ig=1; ig<=nSlices; ig++){
			setSlice(ig);
			
			lowList=List.get("Lowthre1st"+ig-1);
			lowList=round(lowList);
			
			if(lowList<avethreDef)
			lowList=avethreDef;
			
			setThreshold(lowList, 255);
			run("Convert to Mask", "method=Default background=Default only black");
		}
		
		run("Remove Outliers...", "radius=0.5 threshold=50 which=Bright stack");
		print("Removed Outliers");
		for(ii=1; ii<=nSlices; ii++){
			selectImage(Mask3D);
			setSlice(ii);
			
			selectImage(nc82Ori);
			setSlice(ii);
			run("Enhance Local Contrast (CLAHE)", "blocksize=125 histogram=4095 maximum=12 mask=Mask3D.tif fast_(less_accurate)");
		}
		run("Grays");
		
		logsum=getInfo("log");
		File.saveString(logsum, filepath);
		
		selectWindow("Mask3D.tif");
		selectImage(Mask3D);
		close();
	}//	if(CLAHEon){
	wait(100);
	call("java.lang.System.gc");
	
	if(RotateSample==1){
		rotationp=5; rotationN=5; overLap=90; 
		selectWindow("Small_Sample.tif");
	}else{
		rotationp=55; rotationN=55; overLap=89;
		selectWindow("Small_Sample.tif");
		run("Canvas Size...", "width="+FrontalMED300pxWidth+" height="+FrontalMED300pxHeight+" position=Center zero");
	}
	run("Grays");
	
	frontMarray[0] = 	rotationp;
	frontMarray[1] = overLap;
	frontMarray[2] = rotationN;
	frontMarray[3] = pixRatio;
	frontMarray[4] = Sample;
	
}//function frontmedianPcreation

function SliceNumberAdjustment(nSlices,TempSlice){
	while(nSlices<TempSlice){
		setSlice(1);
		run("Add Slice");
		
		if(nSlices<TempSlice){
			setSlice(nSlices);
			run("Add Slice");
		}
	}
	while(nSlices>TempSlice){// slice number adjustment to temple
		setSlice(nSlices);
		run("Delete Slice");
		
		if(nSlices>TempSlice){
			setSlice(1);
			run("Delete Slice");
		}
	}
}//function SliceNumberAdjustment(SampSlice,TempSlice){

function ApplyLUT(){
	run("Max value");
	bitd=bitDepth();
	
	Maxvalue=65535;
	if(bitd==8)
	Maxvalue=255;
	
	totalLogMAX=getInfo("log");
	
	lengthofLog=lengthOf(totalLogMAX);
	MINposi=lastIndexOf(totalLogMAX, "Minvalue;");
	MINV=substring(totalLogMAX, MINposi+10, lengthofLog);
	MINV=parseFloat(MINV);
	
	MAXposi=lastIndexOf(totalLogMAX, "Maxvalue;");
	MAXV=substring(totalLogMAX, MAXposi+10, MINposi-2);
	MAXV=parseFloat(MAXV);
	
	if(MAXV!=Maxvalue && MINV!=0){
		setMinAndMax(MINV, MAXV);
		if(nSlices>1)
		run("Apply LUT", "stack");
		else
		run("Apply LUT");
	}
}


function ImageCorrelationPlugin(CorrelationPlugin){
	
	sampimg=CorrelationPlugin[0];
	tempimg=CorrelationPlugin[1];
	rotationp=CorrelationPlugin[2];
	overLap=CorrelationPlugin[3];
	rotationN=CorrelationPlugin[8];
	Sdominant=CorrelationPlugin[9];
	NSLOTS=CorrelationPlugin[10];
	
	rotationp=round(rotationp);
	rotationN=round(rotationN);
	overLap=round(overLap);
	NSLOTS=round(NSLOTS);
	
	OBJScore=0; trynum=0;
	
	wait(100);
	call("java.lang.System.gc");
	
	//	while(OBJScore<600){
	
	selectWindow(sampimg);
	rename("Samp.tif");
	
	selectWindow(tempimg);
	rename("TempC.tif");
	
	//setBatchMode(false);
	//updateDisplay();
	//exit();
	
	
	
	print("  ImageCorrelation; sampimg; "+sampimg+"  tempimg; "+tempimg+"  rotationp; "+rotationp+"  rotationN; "+rotationN+"  overLap; "+overLap+"  Sdominant; "+Sdominant);
	
	if(Sdominant==1)
	run("Image Correlation Atomic SD", "samp=Samp.tif temp=TempC.tif +="+rotationp+" -="+rotationN+" overlap="+overLap+" parallel="+NSLOTS+" rotation=1 show calculation=OBJPeasonCoeff");
	else
	run("Image Correlation Atomic EQ", "samp=Samp.tif temp=TempC.tif +="+rotationp+" -="+rotationN+" overlap="+overLap+" parallel="+NSLOTS+" rotation=1 show calculation=OBJPeasonCoeff");
	
	selectWindow("DUP_Samp.tif");
	run("Enhance Contrast", "saturated=0.35");
	getMinAndMax(min, max);
	
	if(min!=0 && max!=65535)
	run("Apply LUT");
	
	run("Merge Channels...", "c1=TempC.tif c2=DUP_Samp.tif  c3=TempC.tif keep");
	saveAs("PNG", myDir+trufilename+"_"+tempimg+".png");
	close();
	
	selectWindow("DUP_Samp.tif");
	close();
	
	selectWindow("Samp.tif");
	rename(sampimg);
	
	selectWindow("TempC.tif");
	rename(tempimg);
	
	totalLog=getInfo("log");
	//updateResults();
	//wait(5);
	OBJindex = lastIndexOf(totalLog, "score;");
	
	xindex = lastIndexOf(totalLog,"shiftx");
	yindex = lastIndexOf(totalLog,"shifty");
	rotindex = lastIndexOf(totalLog,"rotation");
	
	
	OBJScore=substring(totalLog,OBJindex+6, lengthOf(totalLog));//getResult("OBJ score", 0);
	OBJScore=parseFloat(OBJScore);//Chaneg string to number
	
	maxrotation= substring(totalLog,rotindex+9, OBJindex-6);//getResult("rotation", 0);
	maxrotation=parseFloat(maxrotation);//Chaneg string to number
	
	maxX= substring(totalLog,xindex+7, yindex-2);//getResult("shiftx", 0);
	maxX=parseFloat(maxX);//Chaneg string to number
	
	maxY=substring(totalLog,yindex+7, rotindex-2);//getResult("shifty", 0);
	maxY=parseFloat(maxY);//Chaneg string to number
	
	if(Sdominant==1)
	print("Sample Dominant");
	
	CorrelationPlugin[4]=maxrotation;
	CorrelationPlugin[5]=maxY;
	CorrelationPlugin[6]=maxX;
	CorrelationPlugin[7]=OBJScore;
}//function ImageCorrelationPlugin(CorrelationPlugin){

function stack_scan(stackScanArray){
	ScanStartSlice=stackScanArray[0];
	ScanEndSlice=stackScanArray[1];
	IDSmallSamp=stackScanArray[2];
	SliMethod=stackScanArray[3];
	TitleSmalltemp50px=stackScanArray[5];
	NSLOTS=stackScanArray[6];
	NSLOTS=round(NSLOTS);
	//	DepthRatio=stackScanArray[6];
	//	W100ratio=stackScanArray[7];
	
	print("SliMethod; "+SliMethod+"  ScanStartSlice; "+ScanStartSlice+"  ScanEndSlice; "+ScanEndSlice+"   TitleSmalltemp50px; "+TitleSmalltemp50px+"  IDSmallSamp; "+IDSmallSamp);
	
	selectWindow(TitleSmalltemp50px);
	rename("temp50.tif");
	
	maxobjScore=0; maxObjSlice=0;
	for(slicenn=ScanStartSlice; slicenn<=ScanEndSlice; slicenn++){
		selectImage(IDSmallSamp);
		
		//	setBatchMode(false);
		//	updateDisplay();
		//	"do"
		//	exit();
		
		setSlice(slicenn);
		//		print("slice; "+slicenn*7.25);
		run("Duplicate...", "title=singleS.tif");
		
		run("Enhance Contrast", "saturated=0.35");
		getMinAndMax(min, max);
		setMinAndMax(min, max);
		if(min!=0 && max!=65535)
		run("Apply LUT");
		
		if(SliMethod=="Lateral")
		if(slicenn==ScanStartSlice)
		print("SliMethod==Lateral");
		
		//	setBatchMode(false);
		//	updateDisplay();
		//	"do"
		//	exit();
		
		if(SliMethod=="Lateral")
		run("Image Correlation Atomic EQ", "samp=singleS.tif temp=temp50.tif +=20 -=20 overlap=80 parallel="+NSLOTS+" rotation=1 calculation=OBJPeasonCoeff");  //[Sample dominant]//[Equal weight (temp and sample)]");
		else
		run("Image Correlation Atomic SD", "samp=singleS.tif temp=temp50.tif +=20 -=20 overlap=90 parallel="+NSLOTS+" rotation=1 calculation=OBJPeasonCoeff");  //[Sample dominant]//[Equal weight (temp and sample)]");
		
		//		updateResults();
		//		wait(5);
		//		OBJScore=getResult("OBJ score", 0);
		//		OBJScore=parseFloat(OBJScore);//Chaneg string to number
		
		
		totalLog=getInfo("log");
		lengthofLog=lengthOf(totalLog);
		OBJPosi=lastIndexOf(totalLog, "score;");
		OBJ=substring(totalLog, OBJPosi+6, lengthofLog);
		OBJScore=parseFloat(OBJ);
		//	List.set("Slice"+slicenn, OBJScore);
		
		
		print("OBJScore; "+OBJScore+"   slicenn; "+slicenn);
		
		
		if(OBJScore>maxobjScore && OBJScore!=1000){
			maxobjScore=OBJScore;
			maxObjSlice=slicenn;
			
			xindex = lastIndexOf(totalLog, "shiftx;");
			yindex = lastIndexOf(totalLog, "shifty;");
			rotindex = lastIndexOf(totalLog, "rotation;");
			
			maxXL = substring(totalLog, xindex+7, yindex-2);
			maxYL = substring(totalLog, yindex+7, rotindex-2);
			maxRL = substring(totalLog, rotindex+9, OBJPosi-6);
			
			//	maxXL=getResult("shiftx", 0);
			//	maxYL=getResult("shifty", 0);
			//	maxRL=getResult("rotation", 0);
		}
		while(isOpen("singleS.tif")){
			selectWindow("singleS.tif");
			close();
			print("singleS closed");
		}
	}//for(slicenn=ScanStartSlice; slicenn<=ScanEndSlice; slicenn++){
	
	
	selectWindow("temp50.tif");
	rename(TitleSmalltemp50px);	
	
	if(SliMethod=="Horizontal")
	maxObjSliceOri=round(maxObjSlice*7.25*2);// for 50px smaller stack
	else if(SliMethod=="Lateral")
	maxObjSliceOri=round(maxObjSlice*7.25);// for 50px smaller stack
	else if(SliMethod=="Frontal")
	maxObjSliceOri=round(maxObjSlice*7.25);
	
	print(SliMethod+";  maxObjSliceOri; "+maxObjSliceOri+"  maxObjScore; "+maxobjScore+"  maxObjSlice; "+maxObjSlice);
	print("maxXL; "+maxXL+"   maxYL; "+maxYL+"   maxRL; "+maxRL);
	
	selectImage(IDSmallSamp);
	//if(SliMethod=="Lateral"){
	//		setBatchMode(false);
	//		updateDisplay();
	//			"do"
	//		exit();
	//	}
	
	close();
	
	stackScanArray[4]=maxObjSliceOri;
}//function stack_scan(stackScanArray){


function Small_Temp_Image_Creation (TempImageCreation,tempPreparationArray){
	Temp300px=TempImageCreation[0];
	Temp100px=TempImageCreation[1];
	Temp50px=TempImageCreation[2];
	tempMask=TempImageCreation[3];
	FullFilePath=TempImageCreation[4];
	Direction=TempImageCreation[5];
	
	print("tempMask; "+tempMask);
	
	if(isOpen(Temp300px)){// horizontal 300px image, 184 x 300 px
		selectWindow(Temp300px);
		
		FullFilePath=tempMask+Temp300px;
	}else{
		
		
		FullFilePath=tempMask+Temp300px;
		
		tempmaskEXI=File.exists(FullFilePath);
		if(tempmaskEXI==1){
			print("FullFilePath; "+FullFilePath);
			titlelistTempNrrdPath=getList("image.titles");
			
			IJ.redirectErrorMessages();
			open(FullFilePath);
			
			titlelistAfter=getList("image.titles");
			
			if(titlelistTempNrrdPath.length == titlelistAfter.length){
				print("PreAlignerError: The file cannot open; "+FullFilePath);
				logsum=getInfo("log");
				File.saveString(logsum, savedir+"63x_brain_pre_aligner_log.txt");
				
				run("Quit");
			}
		}else{
			print("PreAlignerError: Temp300px does not exist; "+tempMask+Temp300px);
			
			logsum=getInfo("log");
			filepath=tempPreparationArray[38]+"63x_brain_pre_aligner_log.txt";
			File.saveString(logsum, filepath);
			
			run("Quit");	
			
			
		}
	}//if(isOpen(Temp300px)){
	Temp300pxID=getImageID();
	
	Height300px=getHeight();
	Width300px=getWidth();
	
	selectImage(Temp300pxID);
	if(isOpen(Temp100px)!=true){
		run("Duplicate...", " ");
		run("Size...", "width="+round(Width300px/3)+" height="+round(Height300px/3)+" constrain interpolation=Bicubic");
		
		if(Direction=="Horizontal")
		run("Canvas Size...", "width=100 height=60 position=Center zero");
		
		if(Direction=="Lateral")
		run("Canvas Size...", "width=100 height=100 position=Center zero");
		
		resetMinAndMax();
		run("Apply LUT");
		
		rename(Temp100px);// horizontal 50px image
	}
	
	selectImage(Temp300pxID);
	if(isOpen(Temp50px)!=true){
		run("Duplicate...", " ");
		run("Size...", "width="+round(Width300px/6)+" height="+round(Height300px/6)+" constrain interpolation=None");
		
		if(Direction=="Horizontal")
		run("Canvas Size...", "width=50 height=30 position=Center zero");
		
		if(Direction=="Lateral")
		run("Canvas Size...", "width=50 height=50 position=Center zero");
		
		resetMinAndMax();
		run("Apply LUT");
		
		rename(Temp50px);// horizontal 50px image
	}
	
	TempImageCreation[3]=tempMask;
	TempImageCreation[4]=FullFilePath;
}// function


function CLEAR_MEMORY() {
	d=call("ij.IJ.maxMemory");
	e=call("ij.IJ.currentMemory");
	for (trials=0; trials<3; trials++) {
		wait(100);
		call("java.lang.System.gc");
	}
}

function Small300pxImageGeneration(FrontalMED300px,Lateral300px,HoriSingle300px) {// generating 300 px single slice temp generation
	OritempNrrd=getImageID();
	getVoxelSize(widthVX, heightVX, depthVX, unitVX);
	OriWidth=getHeight();
	OriHeight=getWidth();
	
	HeightDepthratio=depthVX/heightVX;
	ZsliceNo300=HeightDepthratio*(300/OriHeight)*nSlices;
	
	run("Z Project...", "projection=Median");
	
	
	/// frontal image //////////////////////////////////////////////////////////
	W100ratio=100/OriWidth;
	H100ratio=100/OriHeight;
	
	setSlice(round(nSlices/2));
	
	run("Duplicate...", " ");
	
	if(OriWidth>=OriHeight)
	run("Size...", "width=100 height="+round(OriHeight*W100ratio)+" constrain interpolation=Bicubic");
	else
	run("Size...", "width="+round(OriWidth*H100ratio)+" height=100 constrain interpolation=Bicubic");
	rename(FrontalMED300px);
	
	/// lateral image //////////////////////////////////////////////////////////////
	selectImage(OritempNrrd);
	run("Duplicate...", "duplicate");
	rename("300PX_Temp_Stack.tif");
	TempStack300=getImageID();
	
	if(OriWidth>=OriHeight)
	run("Size...", "width=300 height="+round(OriHeight*W100ratio*3)+" depth="+ZsliceNo300+" interpolation=Bicubic");
	else
	run("Size...", "width="+round(OriWidth*H100ratio*3)+" height=300 depth="+ZsliceNo300+" constrain interpolation=Bicubic");
	
	
	getVoxelSize(widthSmall, heightSmall, depthSmall, unitVX);
	run("Reslice [/]...", "output="+depthSmall+" start=Left rotate");
	TempStackLateral300=getImageID();
	
	setSlice(round(nSlices/2));
	run("Duplicate...", " ");
	
	rename(Lateral300px);// Lateral300px 300px slice
	
	selectImage(TempStackLateral300);
	close();
	
	
	/// horizontal image //////////////////////////////////////////////////////////
	selectImage(TempStack300);
	tempstackST=getTitle();
	run("Reslice [/]...", "output="+depthSmall+" start=Top");
	TempStackHori300=getImageID();
	
	setSlice(round(nSlices/2));
	run("Duplicate...", " ");
	
	rename(HoriSingle300px);// horizontal 300px slice
	
	selectImage(TempStackHori300);
	close();
	
	if(isOpen(tempstackST)){
		selectWindow(tempstackST);
		//	selectImage(TempStack300);
		close();
	}
}//function Small300pxImageGeneration(FrontalMED300px,) {// generating 300 px single slice

function tempPreparation (temptype,Auto300Generation,tempPreparationArray){
	
	tempMask=tempPreparationArray[39];
	
	if(temptype=="35_A5"){
		
		tempis="35_A5";//"2010_2013"//"35_A5"//"35E1" //"JFRC2010"
		
		if(tempis=="35E1"){
			OriginaltempST="JFRC2010_35E1.nrrd";
			FrontalMED300px="Frontal_100.tif";
			HoriSingle300px="Horizontal_300.tif";
			Lateral300px="Lateral_300.tif";
			Frontal100px="JFRC2010_Enlarge_Frontal300.tif";// 3rd adjustment small temp frontal limited slices 24-39
		}else if(tempis=="35_A5"){
			OriginaltempST="35A3_JFRC2013_Dist_Stitched_half.nrrd";//"35_A3_20130108185430177_16bit_Gamma.nrrd";//35_A3_20130108185430177_16bit_Gamma.nrrd// "35_A3_20130108185430177_16bit_Gamma_Center.nrrd"
			FrontalMED300px="35_A3_24_39MED300px.tif";
			HoriSingle300px="35_A3_580_300px_Horizontal.tif";//"AVG_35_A3_269_305_Horizontal.tif";
			Lateral300px="35_A3_706_300px_Lateral.tif";
			Frontal300pxSingle="35_A3_JFRC2013_Frontal300Slice.tif";// 3rd adjustment small temp frontal limited slices 24-39
			Frontal100px="MED_35_A3_100px.tif";
		}else if(tempis=="2010_2013"){
			OriginaltempST="JFRC2010_converted_JFRC2013.nrrd";
			FrontalMED300px="Frontal_2010_2013.tif";
			HoriSingle300px="Horixontal_2010_2013.tif";//"AVG_35_A3_269_305_Horizontal.tif";
			Lateral300px="Lateral_2010_2013.tif";
			Frontal100px="JFRC2010_Enlarge_Frontal300.tif";// 3rd adjustment small temp frontal limited slices 24-39
		}else if(tempis=="JFRC2010"){
			OriginaltempST="JFRC2010_Enlarge_to_2013_half.nrrd";
			FrontalMED300px="JFRC2010_Enlarge_MedianP.tif";
			HoriSingle300px="JFRC2010_Enlarge_Horizontal300.tif";//"AVG_35_A3_269_305_Horizontal.tif";
			
			Frontal100px="JFRC2010_Enlarge_Frontal300.tif";// 3rd adjustment small temp frontal limited slices 24-39
			Lateral300px="JFRC2010_Enlarge_Lateral300.tif";
			
		}//if(tempis=="35E1"){
		
		Hori100px="35_A3_580_100px_Horizontal.tif";//"AVG_35_A3_269_305_Horizontal.tif";
		Hori50px="35_A3_50px_Horizontal.tif";//"AVG_35_A3_269_305_Horizontal.tif";
		
		Lateral50px="Lateral_35_A3_50px_Sli831.tif";
		Lateral100px="Lateral_35_A3_100px_Sli831.tif";
		
		Frontal50px="35_A3_JFRC2013Frontal_50px.tif";
		
		ReslicedZprojectionStart=661;
		ReslicedZprojectionEnd=1173;
		ThiredZprojectionStart=247;//170;
		ThiredZprojectionEnd=248;//281;
		
		TempResliceLateralWidth=893;
	}//if(temptype=="35_A5"){
	
	if(temptype=="JRC2018U"){
		
		/// Open these tif files for template mathcing ///////////////
		
		OriginaltempST="JRC2018_UNISEX_63x.nrrd";//"JRC2018_JFRC2013_Original_Dist_Stitched_01_warp_m0g80c8e1e-1x26r4.nrrd";
		FrontalMED300px="JRC2018_JFRC2013_MED_Frontal300px.tif";
		HoriSingle300px="JRC2018_JFRC2013_Horizontal300px.tif";
		Lateral300px="JRC2018_JFRC2013_Lateral300px.tif";
		Frontal300pxSingle="JRC2018_JFRC2013_Slice_Frontal300px.tif";
		Frontal100px="JRC2018_JFRC2013_MED_Frontal100px.tif";
		
		/// Just name for smaller size creation ///////////////////////
		Hori100px="JRC2018_JFRC2013_100px_Horizontal.tif";//"AVG_35_A3_269_305_Horizontal.tif";
		Hori50px="JRC2018_JFRC2013_50px_Horizontal.tif";//"AVG_35_A3_269_305_Horizontal.tif";
		
		Lateral50px="Lateral_JRC2018_JFRC2013_50px_Sli831.tif";
		Lateral100px="Lateral_JRC2018_JFRC2013_100px_Sli831.tif";
		
		Frontal50px="JRC2018_JFRC2013_JFRC2013Frontal_50px.tif";
		
		ReslicedZprojectionStart=681;
		ReslicedZprojectionEnd=1170;
		ThiredZprojectionStart=247;//170;
		ThiredZprojectionEnd=248;//281;
		
		TempResliceLateralWidth=893;
	}//if(temptype=="JRC2018U"){
	
	if(temptype=="JRC2018F"){
		
		/// Open these tif files for template mathcing ///////////////
		
		OriginaltempST="JRC2018_FEMALE_63x.nrrd";//"JRC2018_JFRC2013_Original_Dist_Stitched_01_warp_m0g80c8e1e-1x26r4.nrrd";
		FrontalMED300px="JRC2018F_JFRC2013_MED_Frontal300px.tif";
		HoriSingle300px="JRC2018F_JFRC2013_Horizontal300px.tif";
		Lateral300px="JRC2018F_JFRC2013_Lateral300px.tif";
		Frontal300pxSingle="JRC2018F_JFRC2013_Slice_Frontal300px.tif";
		Frontal100px="JRC2018F_JFRC2013_MED_Frontal100px.tif";
		
		/// Just name for smaller size creation ///////////////////////
		Hori100px="JRC2018_JFRC2013_100px_Horizontal.tif";//"AVG_35_A3_269_305_Horizontal.tif";
		Hori50px="JRC2018_JFRC2013_50px_Horizontal.tif";//"AVG_35_A3_269_305_Horizontal.tif";
		
		Lateral50px="Lateral_JRC2018_JFRC2013_50px_Sli831.tif";
		Lateral100px="Lateral_JRC2018_JFRC2013_100px_Sli831.tif";
		
		Frontal50px="JRC2018_JFRC2013_JFRC2013Frontal_50px.tif";
		
		ReslicedZprojectionStart=681;
		ReslicedZprojectionEnd=1170;
		ThiredZprojectionStart=247;//170;
		ThiredZprojectionEnd=248;//281;
		
		TempResliceLateralWidth=893;
	}//if(temptype=="JRC2018F"){
	
	if(temptype=="JRC2018M"){
		
		/// Open these tif files for template mathcing ///////////////
		print("temptype==JRC2018M");
		OriginaltempST="JRC2018_MALE_63x.nrrd";//"JRC2018_JFRC2013_Original_Dist_Stitched_01_warp_m0g80c8e1e-1x26r4.nrrd";
		FrontalMED300px="JRC2018M_JFRC2014_MED_Frontal300px.tif";
		HoriSingle300px="JRC2018F_JFRC2013_Horizontal300px.tif";
		Lateral300px="JRC2018F_JFRC2013_Lateral300px.tif";
		Frontal300pxSingle="JRC2018F_JFRC2013_Slice_Frontal300px.tif";
		Frontal100px="JRC2018M_JFRC2014_MED_Frontal100px.tif";
		
		/// Just name for smaller size creation ///////////////////////
		Hori100px="JRC2018_JFRC2013_100px_Horizontal.tif";//"AVG_35_A3_269_305_Horizontal.tif";
		Hori50px="JRC2018_JFRC2013_50px_Horizontal.tif";//"AVG_35_A3_269_305_Horizontal.tif";
		
		Lateral50px="Lateral_JRC2018_JFRC2013_50px_Sli831.tif";
		Lateral100px="Lateral_JRC2018_JFRC2013_100px_Sli831.tif";
		
		Frontal50px="JRC2018_JFRC2013_JFRC2013Frontal_50px.tif";
		
		ReslicedZprojectionStart=681;
		ReslicedZprojectionEnd=1170;
		ThiredZprojectionStart=247;//170;
		ThiredZprojectionEnd=248;//281;
		
		TempResliceLateralWidth=893;
	}//if(temptype=="JRC2018U"){
	
	
	if(temptype=="JFRC2013"){
		OriginaltempST="JFRC2013_63xNew_dist_originalLSM_NoOP.nrrd";
		FrontalMED300px="Frontal_100.tif";
		HoriSingle300px="Horizontal_300.tif";
		Lateral300px="Lateral_JFRC2013_63x_300px.tif";
		Frontal100px="MED_35_A3_100px.tif";
		
		LateralSingleSlice=665;
		LateralSingleSlice100px=91;
		//	SmallCanvasWidth=200;
		
		Hori100px="35_A3_580_100px_Horizontal.tif";//"AVG_35_A3_269_305_Horizontal.tif";
		Hori50px="35_A3_50px_Horizontal.tif";//"AVG_35_A3_269_305_Horizontal.tif";
		
		Lateral50px="Lateral_JFRC2013_63x_50px_Sli831.tif";
		Lateral100px="Lateral_JFRC2013_63x_100px_Sli831.tif";
		
		Frontal50px="35_A3_JFRC2013Frontal_50px.tif";
		
		ReslicedZprojectionStart=661;// need change
		ReslicedZprojectionEnd=1173;//need change
		ThiredZprojectionStart=247;//170;
		ThiredZprojectionEnd=248;//281;
		
	}//if(temptype=="JFRC2013"){
	
	
	
	
	if(temptype!="JRC2018U" && temptype!="JRC2018F" && temptype!="JRC2018M"){
		if(isOpen(OriginaltempST)){// temp nrrd file
		}else{
			
			TempNrrdPath=tempMask+OriginaltempST;
			
			tempmaskEXI=File.exists(TempNrrdPath);
			if(tempmaskEXI==1){
				print("TempNrrdPath; "+TempNrrdPath);
				open(TempNrrdPath);
				
			}else{
				print("Template does not exist; "+TempNrrdPath);
				
				logsum=getInfo("log");
				filepath=tempPreparationArray[38]+"63x_brain_pre_aligner_log.txt";
				File.saveString(logsum, filepath);
				
				run("Quit");
			}
		}//if(isOpen("JFRC2013_63xNew_dist_originalLSM_NoOP.nrrd")){
		
		selectWindow(OriginaltempST);
		Temp63X=getImageID();
		TempSlice=nSlices();
		CanvasWidth=getWidth();
		CanvasHeight=getHeight();
		getVoxelSize(TempVxWidth, TempVxHeight, TempVxDepth, TempVxUnit);
		close();
	}else if(temptype=="JRC2018U"){
		Temp63X=0;
		TempSlice=456;
		CanvasWidth=3333;
		CanvasHeight=1560;
		
		TempVxWidth=0.1882680;
		TempVxHeight=0.1882680;
		TempVxDepth=0.3794261;
		TempVxUnit="microns";
	}else if(temptype=="JRC2018F"){
		Temp63X=0;
		TempSlice=478;
		CanvasWidth=3333;
		CanvasHeight=1550;
		
		TempVxWidth=0.1882680;
		TempVxHeight=0.1882680;
		TempVxDepth=0.3800808;
		TempVxUnit="microns";
	}else if(temptype=="JRC2018M"){
		Temp63X=0;
		TempSlice=476;
		CanvasWidth=3150;
		CanvasHeight=1500;
		
		TempVxWidth=0.1882680;
		TempVxHeight=0.1882680;
		TempVxDepth=0.3797002;
		TempVxUnit="microns";
	}
	
	
	
	wait(100);
	call("java.lang.System.gc");
	
	print("Temp CanvasWidth;"+CanvasWidth+"   CanvasHeight; "+CanvasHeight);
	
	SmallCanvasWidth=round(CanvasWidth/CanvasHeight*100);
	ReslicedSmallZprojectionStart=round(ReslicedZprojectionStart/(CanvasWidth/SmallCanvasWidth));
	ReslicedSmallZprojectionEnd=round(ReslicedZprojectionEnd/(CanvasWidth/SmallCanvasWidth));
	
	if(Auto300Generation=="No"){
		// Frontal /////////////////////////////////////////////////////////////////
		FrontalAVG100pxPath=tempMask+FrontalMED300px;
		if(isOpen(FrontalMED300px)){// 100px frontal median projection
			selectWindow(FrontalMED300px);
			
			FrontalAVG100pxPath=tempMask+FrontalMED300px;
		}else{
			
			tempmaskEXI=File.exists(FrontalAVG100pxPath);
			if(tempmaskEXI==1){
				print("FrontalAVG100pxPath; "+FrontalAVG100pxPath);
				
				titlelistTempNrrdPath=getList("image.titles");
				
				IJ.redirectErrorMessages();
				open(FrontalAVG100pxPath);
				
				titlelistAfter=getList("image.titles");
				
				if(titlelistTempNrrdPath.length == titlelistAfter.length){
					print("PreAlignerError: The file cannot open; "+FrontalAVG100pxPath);
					logsum=getInfo("log");
					File.saveString(logsum, savedir+"63x_brain_pre_aligner_log.txt");
					
					run("Quit");
				}
				
			}else{
				print("Template does not exist; "+TempNrrdPath);
				
				logsum=getInfo("log");
				filepath=tempPreparationArray[38]+"63x_brain_pre_aligner_log.txt";
				File.saveString(logsum, filepath);
				
				run("Quit");
				
			}
		}//	if(isOpen(FrontalMED300px)){// 100px frontal median projection
		
		FrontalMED300pxWidth=getWidth();
		FrontalMED300pxHeight=getHeight();
		
		
		if(isOpen(Frontal100px)){// frontal 100px single slice
			selectWindow(Frontal100px);
			
			//	Frontal100pxPath=tempMask+Frontal100px;
		}else{
			
			changeratio100 = 100/FrontalMED300pxHeight;
			
			print("changeratio100; "+changeratio100+"  FrontalMED300pxWidth; "+FrontalMED300pxWidth+"  FrontalMED300pxHeight; "+FrontalMED300pxHeight);
			selectWindow(FrontalMED300px);
			run("Duplicate...", "title="+Frontal100px+"");
			run("Size...", "width="+round(FrontalMED300pxWidth*changeratio100)+" height=100 interpolation=None");
			
		}//if(isOpen("JFRC2013_63xNew_dist_originalLSM_NoOP.nrrd")){
		Temp100pxMED=getImageID();
		WidthFrontal100px=getWidth();
		HeightFrontal100px=getHeight;
		
		//	setBatchMode(false);
		//	updateDisplay();
		//	"do"
		//	exit();
		
		Frontal300pxPath=0;
		
		if(isOpen(Frontal300pxSingle)){// frontal 100px single slice
			selectWindow(Frontal300pxSingle);
			
			Frontal300pxPath=tempMask+Frontal300pxSingle;
		}else{
			
			Frontal300pxPath=tempMask+Frontal300pxSingle;
			
			tempmaskEXI=File.exists(Frontal300pxPath);
			if(tempmaskEXI==1){
				print("Frontal300pxPath; "+Frontal300pxPath);
				open(Frontal300pxPath);
			}else{
				print("Frontal300pxSingle does not exist; "+Frontal300pxSingle);
				
				logsum=getInfo("log");
				filepath=tempPreparationArray[38]+"63x_brain_pre_aligner_log.txt";
				File.saveString(logsum, filepath);
				
				run("Quit");
				
				
			}
		}//if(isOpen("JFRC2013_63xNew_dist_originalLSM_NoOP.nrrd")){
		
		//	selectImage(Frontal300pxSingle);
		
		//	run("Duplicate...", "title=35_A3_JFRC2013Frontal_50px.tif");
		//	run("Canvas Size...", "width="+getHeight+" height="+getHeight+" position=Center zero");// sample stack
		//	run("Size...", "width=50 height=50 interpolation=None");
		
		
	}else{//if(Auto300Generation=="No"){
		selectImage(Temp63X);
		Small300pxImageGeneration(FrontalMED300px,Lateral300px,HoriSingle300px);
		
	}
	
	if(isOpen(Frontal50px)){
		
	}else{
		selectWindow(Frontal300pxSingle);
		run("Duplicate...", " ");
		
		HoriW=getWidth();
		HoriH=getHeight();
		
		run("Canvas Size...", "width="+HoriH+" height="+HoriH+" position=Center zero");// sample stack
		
		//run("Size...", "width=50 height="+round(HoriH*(50/HoriW))+" constrain interpolation=None");
		
		run("Size...", "width=50 height=50 constrain interpolation=None");
		//		run("Canvas Size...", "width=50 height=50 position=Center zero");// sample stack
		
		ApplyLUT();
		rename(Frontal50px);
	}
	
	////// Horizontal ////////////////////////////////////////
	Direction="Horizontal";
	
	TempImageCreation=newArray(HoriSingle300px,Hori100px,Hori50px,tempMask,temp300pxHori,Direction);
	Small_Temp_Image_Creation (TempImageCreation,tempPreparationArray);
	
	
	temp300pxHori=TempImageCreation[4];
	
	
	////// Lateral ///////////////////////////////////////////////////
	Direction="Lateral";
	
	
	TempImageCreation=newArray(Lateral300px,Lateral100px,Lateral50px,tempMask,temp300pxLateralPath,Direction);
	Small_Temp_Image_Creation (TempImageCreation,tempPreparationArray);
	
	
	temp300pxLateralPath=TempImageCreation[4];
	
	selectWindow(HoriSingle300px);
	Horizon300Width=getWidth();
	Hrizon300height=getHeight();
	
	selectWindow(Lateral300px);
	Lateral300Width=getWidth();
	Lateral300height=getHeight();
	print("Lateral300Width; "+Lateral300Width+"   Lateral300height; "+Lateral300height);
	print("2172");
	
	tempPreparationArray[0]=OriginaltempST;
	tempPreparationArray[1]=FrontalMED300px;
	tempPreparationArray[2]=HoriSingle300px;
	tempPreparationArray[3]=Lateral300px;
	tempPreparationArray[4]=Frontal100px;
	tempPreparationArray[5]=Hori100px;
	tempPreparationArray[6]=Hori50px;
	tempPreparationArray[7]=Lateral50px;
	tempPreparationArray[8]=Lateral100px;
	
	tempPreparationArray[9]=ReslicedZprojectionStart;
	tempPreparationArray[10]=ReslicedZprojectionEnd;
	tempPreparationArray[11]=ThiredZprojectionStart;
	tempPreparationArray[12]=ThiredZprojectionEnd;
	
	tempPreparationArray[13]=Temp63X;//image ID
	tempPreparationArray[14]=TempSlice;
	tempPreparationArray[15]=CanvasWidth;
	tempPreparationArray[16]=CanvasHeight;
	tempPreparationArray[17]=TempResliceLateralWidth;
	tempPreparationArray[18]=TempVxWidth;
	tempPreparationArray[19]=TempVxHeight;
	tempPreparationArray[20]=TempVxDepth;
	
	tempPreparationArray[21]=TempVxUnit;
	tempPreparationArray[22]=SmallCanvasWidth;
	tempPreparationArray[23]=ReslicedSmallZprojectionStart;
	tempPreparationArray[24]=ReslicedSmallZprojectionEnd;
	
	tempPreparationArray[25]=FrontalMED300pxWidth;
	tempPreparationArray[26]=FrontalMED300pxHeight;
	
	tempPreparationArray[27]=Temp100pxMED;//image ID
	tempPreparationArray[28]=WidthFrontal100px;
	tempPreparationArray[29]=HeightFrontal100px;
	tempPreparationArray[30]=Frontal50px;
	
	tempPreparationArray[31]=temp300pxLateralPath;
	tempPreparationArray[32]=Horizon300Width;
	tempPreparationArray[33]=Hrizon300height;
	tempPreparationArray[34]=Lateral300Width;
	tempPreparationArray[35]=Lateral300height;
	tempPreparationArray[36]=tempMask;
	tempPreparationArray[37]=Frontal300pxSingle;
}//function tempPreparation





