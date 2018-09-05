
run("Misc...", "divide=Infinity save");
List.clear();
setBatchMode(true);



TempMaskdir=0;
Tempdir=0;
UseMask=false;
JpegMovie=true;
tempAve=0;
Allnrrd=true;
FlipZ=false;
SkipDup=false;
scorePosi="top";
movieEx=0;// 0 is no movie export


ScoreMethod = "Zero-Normalized cross-correlation";//"OBJ person coeff", "OBJ person coeff with -Ave", "Normalized Cross-correlation", "Zero-Normalized cross-correlation"

testArg=0;

if(testArg!=0)
args = split(testArg,",");
else
args = split(getArgument(),",");

savedir = args[0];// save dir
path = args[1];// full file path for inport LSM
NumCPU = args[2];// slice depth
temppath = args[3];


NumCPU=round(NumCPU);



tempMaskpath=0; tempMaskFilename=0;


filepath=savedir+"Score_log.txt";
print("temppath; "+temppath);

TempExt=File.exists(temppath);//"JFRC2010_symetric_R_flip.nrrd"
if(TempExt!=1){
	print("Template: "+temppath+" is not Existing");
	
	logsum=getInfo("log");
	File.saveString(logsum, filepath);
	
	run("Quit");
	
}



if(UseMask==true){
	tempMaskpathExt=File.exists(TempMaskdir+tempMaskFilename);//"JFRC2010_symmetric_Mask.nrrd";
	if(tempMaskpathExt!=1){
		TempMaskdir=getDirectory("Choose a Directory for Template Mask ("+tempMaskFilename+")");
		tempMaskpath=TempMaskdir+tempMaskFilename;
	}else
	tempMaskpath=TempMaskdir+tempMaskFilename;
	
}//if(MaskUse!=0){
open(temppath);

tempFilename=getTitle();
truename=tempFilename;

dotIndex= lastIndexOf(tempFilename, ".");
if(dotIndex!=-1)
truename=substring(tempFilename,0,dotIndex);

print("template open");

filepath=savedir+"Score_log_"+truename+".txt";

if(UseMask==false){// make template brighter
	run("Z Project...", "projection=[Max Intensity]");
	getStatistics(area, mean, minSample, maxSample, std, histogram);
	
	run("Enhance Contrast", "saturated=1");
	getMinAndMax(min, max);
	
	print("detected tempMin; "+minSample+"  temp adjusted min"+min+"   detected tempMax; "+maxSample+"   adjusted temp max; "+max);
	
	close();
	
	selectWindow(tempFilename);
	setMinAndMax(min, max);
	if(max!=maxSample)
	run("Apply LUT", "stack");
}


///2ch & 3ch lsm file detection ///

MaxFileSize=0;
SecondFileSize=0;MaxNum=0;
FirstTime=0; resultNum=0; Tempmin=0; Tempmax=0;


/// skeletoniztion ///////////////////////////////////////////////////


if(Allnrrd==true)
nc82Nrrd = 1;


h5jindex= lastIndexOf(h5jindex, ".h5j");
v3dpbdindex = lastIndexOf(h5jindex, ".v3dpbd");


open(path);
origi=getTitle();
dotindex=lastIndexOf(origi,".");
truname = substring(origi, 0, dotindex);

logsum=getInfo("log");
//filepath=savedir+truname+"_log.txt";
File.saveString(logsum, filepath);

getDimensions(width, height, channels, slices, frames);
getVoxelSize(VxWidth, VxHeight, VxDepth, VxUnit);
bitd=bitDepth();


print("sample open  "+path);
logsum=getInfo("log");
File.saveString(logsum, filepath);

if(FlipZ==true){
	
	run("Flip Z");
	
	//JFRC2013_BJD_126F04_AE_01_20170929_19_B1_01_warp_m0g80c8e1e-1x30r4.nrrd
	
	truname2=substring(listFolder[iF],0,warpIndex);
	
	
	run("Nrrd Writer", "compressed nrrd="+dir+truname2+"_APflip.nrrd");
	
	File.delete(dir+listFolder[iF]);
	
	if(nc82Nrrd==-1)
	close();
}
if(VxWidth==1){
	if(width==1024)
	if(height==512)
	if(slices==218){
		VxDepth=1;
		VxWidth=0.62;
		VxHeight=0.62;
		run("Properties...", "channels="+channels+" slices="+nSlices/channels+" frames=1 unit=microns pixel_width="+VxWidth+" pixel_height="+VxHeight+" voxel_depth="+VxDepth+"");
	}
}//if(VxWidth==1){

if(h5jindex!=-1 || v3dpbdindex!=-1){
	run("Split Channels");
	titlelist0=getList("image.titles");
	
	for(closei=0; closei<titlelist0.length-1; closei++){
		selectWindow(titlelist0[closei]);
		close();
	}
	print("h5j nImages open; "+nImages);
	selectWindow(titlelist0[titlelist0.length-1]);
	origi=getTitle();
}

////// For Nc82 //////////////////////////////////////
if(endsWith(path,".tif") || endsWith(path,".h5j") || endsWith(path,".v3dpbd") || endsWith(path,".nrrd")){
	print("The file is nc82!");
	logsum=getInfo("log");
	File.saveString(logsum, filepath);
	
	selectWindow(origi);//nc82 sample
	
	//		setBatchMode(false);
	//			updateDisplay();
	//			"do"
	//			exit();
	
	
	originalWidth=getWidth();
	originalHeight=getHeight();
	
	stack=getImageID();
	tempAveBriArray = newArray(tempAve,Tempmin,Tempmax);
	
	print("Before score 3D");
	logsum=getInfo("log");
	File.saveString(logsum, filepath);
	
	Score3D(NumCPU,stack,temppath,tempMaskpath,tempFilename,tempMaskFilename,UseMask,tempAveBriArray,ScoreMethod);// check alignment score
	
	print("Score3D function done");
	logsum=getInfo("log");
	File.saveString(logsum, filepath);
	
	//tempAve=tempAveBriArray[0];
	Tempmin=tempAveBriArray[1];
	Tempmax=tempAveBriArray[2];
	
	print("Array filled; Tempmin "+Tempmin+"   Tempmax; "+Tempmax);
	logsum=getInfo("log");
	File.saveString(logsum, filepath);
	
	OBJscore = call("Alignment_Scores.getResult");
	OBJscore=parseFloat(OBJscore);
	print("ResultsTable\n\n"+OBJscore); //tab separated
	
	print("OBJscore pre; "+OBJscore);
	
	//	if(isNaN(OBJscore)){
	//		OBJscore=substring(logsum,scoreposition+7,scoreposition+12);
	//		OBJscore=parseFloat(OBJscore);//Chaneg string to number
	//	}
	//	if(isNaN(OBJscore)){
	//		OBJscore=substring(logsum,scoreposition+7,scoreposition+11);
	//		OBJscore=parseFloat(OBJscore);//Chaneg string to number
	//	}
	//	if(isNaN(OBJscore)){
	//		OBJscore=substring(logsum,scoreposition+7,scoreposition+10);
	//		OBJscore=parseFloat(OBJscore);//Chaneg string to number
	//	}
	
	
	print("OBJscore; "+OBJscore);
	
	logsum=getInfo("log");
	File.saveString(logsum, filepath);
	
	selectWindow(origi);
	run("Z Project...", "projection=[Max Intensity]");
	getStatistics(area, mean, minSample, maxSample, std, histogram);
	width2=getWidth();
	height2=getHeight();
	
	run("Enhance Contrast", "saturated=2");
	getMinAndMax(min, max);
	
	print("detected minSample; "+minSample+"  adjusted min; "+min+"   detected maxSample; "+maxSample+"   adjusted max; "+max);
	
	logsum=getInfo("log");
	File.saveString(logsum, filepath);
	
	close();
	
	selectWindow(origi);
	setSlice(round(nSlices/2));
	setMinAndMax(min, max);
	
	if(max!=maxSample)
	run("Apply LUT", "stack");
	
	print("line 286");
	logsum=getInfo("log");
	File.saveString(logsum, filepath);
	
	selectWindow(tempFilename);
	rename("Temp.tif");
	
	//	setSlice(round(nSlices/2));
	//	setMinAndMax(Tempmin, Tempmax);
	//	run("Apply LUT", "stack");
	
	run("Merge Channels...", "c1=Temp.tif c2="+origi+" c3=Temp.tif");
	
	print("line 299");
	logsum=getInfo("log");
	File.saveString(logsum, filepath);
	
	framer=nSlices/10;
	framer=round(framer);
	
	
	
	if(movieEx!=0){
		if(scorePosi=="Bottom"){
			if(JpegMovie==true)
			run("AVI... ", "compression=JPEG frame=25 save="+savedir+truname+"_"+OBJscore+".avi");//JPG
			else
			run("AVI... ", "compression=Uncompressed frame=25 save="+savedir+truname+"_"+OBJscore+".avi");
		}else{
			if(JpegMovie==true)
			run("AVI... ", "compression=JPEG frame=25 save="+savedir+OBJscore+"_"+truname+".avi");//JPG
			else
			run("AVI... ", "compression=Uncompressed frame=25 save="+savedir+OBJscore+"_"+truname+".avi");
		}
	}//	if(movieEx!=0){
	
	logsum=getInfo("log");
	File.saveString(logsum, filepath);
	
	File.saveString(OBJscore,savedir+truename+"_Score.property");
	
	selectWindow("RGB");
	close();
	
	
}//if(endsWith(listFolder[iF],".tif") || endsWith(listFolder[iF],".h5j") || endsWith(listFolder[iF],".v3dpbd"  || nc82Nrrd!=-1)){


titlelist=getList("image.titles");

for(iclose=0; iclose<nImages; iclose++){
	
	print("titlelist[iclose]; "+titlelist[iclose]);
	
	if(titlelist[iclose]!=tempFilename && titlelist[iclose]!=tempMaskFilename){
		if(isOpen(titlelist[iclose])){
			selectWindow(titlelist[iclose]);
			close();
			print(titlelist[iclose]+"  closed");
		}
	}
}



function Score3D (NumCPU,stack,temppath,tempMaskpath,tempFilename,tempMaskFilename,UseMask,tempAveBriArray,ScoreMethod){
	selectImage(stack);
	stackname=getTitle();
	lowerM=0;
	tempopen=isOpen(tempFilename);
	if(tempopen!=1){
		open(temppath);
		
	}
	
	print("tempFilename; "+tempFilename+"   stackname; "+stackname+"   ScoreMethod; "+ScoreMethod+"  UseMask; "+UseMask);
	
	logsum=getInfo("log");
	File.saveString(logsum, filepath);
	
	print("");
	
	
	run("Z Project...", "projection=[Max Intensity]");
	getStatistics(area, mean, minSample, maxSample, std, histogram);
	
	run("Enhance Contrast", "saturated=1");
	getMinAndMax(Tempmin, Tempmax);
	
	print("detected tempMin; "+minSample+"  temp adjusted min"+min+"   detected tempMax; "+maxSample+"   adjusted temp max; "+max);
	logsum=getInfo("log");
	File.saveString(logsum, filepath);
	close();
	
	selectWindow(tempFilename);
	
	tempAveBriArray[1]=Tempmin;
	tempAveBriArray[2]=Tempmax;
	
	//	if(max!=255)
	//	run("Apply LUT", "stack");
	
	
	if(UseMask==false){
		
		print("before Alignment Scores run");
		logsum=getInfo("log");
		File.saveString(logsum, filepath);
		
		run("Alignment Scores", "template="+tempFilename+" sample="+stackname+" show weight=[Equal weight (temp and sample)] score="+ScoreMethod+" parallel="+NumCPU+"");
	}
	print("Alignment Scores run");
	logsum=getInfo("log");
	File.saveString(logsum, filepath);
	//	run("Alignment Scores", "template=JFRC2013_20x_Yoshi.nrrd sample=C4-JRC_SS31259_20170616_24_C1_m_0.1955_ch.h5j show weight=[Equal weight (temp and sample)] score=[Zero-Normalized cross-correlation] parallel=8");
	
	if(UseMask==true){
		
		print("Use mask mode");
		logsum=getInfo("log");
		File.saveString(logsum, filepath);
		
		tempMaskopen=isOpen(tempMaskFilename);
		if(tempMaskopen!=1){
			open(tempMaskpath);
			
			run("Z Project...", "projection=[Average Intensity]");
			oriname=getTitle();
			run("Three D Ave");
			tempAve=getTitle();
			close();
			tempAve=parseFloat(tempAve);
			tempAve=round(tempAve);
			tempAveBriArray[0] = tempAve;
		}else//if(tempMaskopen!=1){
		tempAve = tempAveBriArray[0];
		
		print("template ave bri; "+tempAve);
		selectWindow(stackname);// sample nc82
		
		run("Z Project...", "projection=[Average Intensity]");
		getStatistics(area, mean, min, max, std, histogram);
		close();
		InitialAve=mean;
		print("InitialAve; "+InitialAve);
		
		maxGap=2; 
		meangap=100;// 60.56 is ave of tempMask at 185 slices
		Bad=0; premeangap=0; Threweight=1;
		
		while(meangap>maxGap){
			print("");
			if(isOpen("ANDresult2.tif")){
				selectWindow("ANDresult2.tif");
				close();
			}
			
			selectWindow(stackname);
			selectImage(stack);
			run("Duplicate...", "title=ANDresult2.tif duplicate");
			ANDst2=getImageID();
			
			Threweight=Threweight+0.05;
			
			setThreshold(round(InitialAve*Threweight), 65535);
			run("Convert to Mask", "method=Default background=Default black");
			
			run("Remove Outliers...", "radius=1 threshold=50 which=Bright stack");
			run("Remove Outliers...", "radius=2 threshold=50 which=Dark stack");
			
			run("Three D Ave");
			ave=getTitle();
			rename("ANDresult2.tif");
			ave=parseFloat(ave);
			meangap=ave-tempAve;
			
			if(premeangap==meangap){
				meangap=0;
				print("Bad alignment");
				Bad=1;
				break;
			}
			
			premeangap=meangap;
			
			print("meangap; "+meangap+"  lower thre; InitialAve*Threweight; "+round(InitialAve*Threweight));
			
			
			if(meangap>10)
			Threweight=Threweight+0.1;
		}
		
		//	setBatchMode(false);
		//	updateDisplay();
		//	"do"
		//	exit();
		
		run("Alignment Scores", "template="+tempMaskFilename+" sample=ANDresult2.tif show weight=[Equal weight (temp and sample)] score=["+ScoreMethod+"] parallel="+NumCPU+"");
		tempAveBriArray[0] = tempAve;
	}
	
	print("end of function");
	logsum=getInfo("log");
	File.saveString(logsum, filepath);
}

run("Close All");
run("Misc...", "divide=Infinity save");

run("Quit");



