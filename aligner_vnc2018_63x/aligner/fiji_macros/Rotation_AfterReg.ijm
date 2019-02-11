
run("Misc...", "divide=Infinity save");

testArg=0;
setBatchMode(true);
//testArg="H:/Registration2/63x_align/reformatted/,Temp1_PRE_PROCESSED_01_warp_m0g80c8e1e-1x26r4.nrrd,H:/Registration2/63x_align/reformatted/Temp1_PRE_PROCESSED_01_warp_m0g80c8e1e-1x26r4.nrrd,N:/test_folder/JRC_SS23221_20160803_31_E5translation.txt,1";
//testArg="/test/63xVNC_align/samples/pro/,REG_JRC2018_FEMALE_63x_01.nrrd,/test/63xVNC_align/samples/pro/REG_JRC2018_FEMALE_63x_01.nrrd,/test/63xVNC_align/samples/pro/PRE_PROCESSED_translation.txt"

if(testArg!=0)
args = split(testArg,",");
else
args = split(getArgument(),",");

savedir = args[0];// save dir
filename = args[1];//file name
VolPath = args[2];//file path
TxtPath = args[3];// full file path for inport LSM


print("savedir; "+savedir);
print("filename; "+filename);
print("VolPath; "+VolPath);
print("TxtPath; "+TxtPath);

ExtTXT=File.exists(TxtPath);

if(ExtTXT!=1){
	print("TxtPath does not exist; "+TxtPath);
	logsum=getInfo("log");
	File.saveString(logsum, savedir+"Rotation_After_Warp.txt");
	
	run("Quit");
}


LF=10; TAB=9; swi=0; swi2=0; testline=0;
exi=File.exists(TxtPath);
List.clear();

if(exi==1){
	s1 = File.openAsRawString(TxtPath);
	swin=0;
	swi2n=-1;
	
	n = lengthOf(s1);
	String.resetBuffer;
	for (testnum=0; testnum<n; testnum++) {
		enter = charCodeAt(s1, testnum);
		
		if(enter==10)
		testline=testline+1;//line number
	}
	
	String.resetBuffer;
	for (si=0; si<n; si++) {
		c = charCodeAt(s1, si);
		
		if(c==10){
			swi=swi+1;
			swin=swin+1;
			swi2n=swi-1;
		}
		
		if(swi==swin){
			if(swi2==swi2n){
				String.resetBuffer;
				swi2=swi;
			}
			if (c>=32 && c<=127)
			String.append(fromCharCode(c));
		}
		if(swi==0){
			Tempwidth = String.buffer;
		}else if(swi==1 && swi<=testline){
			Tempheight = String.buffer;
		}else if(swi==2 && swi<=testline){
			TempSlice = String.buffer;
		}else if(swi==3 && swi<=testline){
			TotalRotationFrontal = String.buffer;
		}else if(swi==4 && swi<=testline){
			TotalXtranslation = String.buffer;
		}else if(swi==5 && swi<=testline){
			TotalYtranslation = String.buffer;
		}else if(swi==6 && swi<=testline){
			FrontalChangeRatio300px= String.buffer;
		}
	}
}

dotIndex=lastIndexOf(filename,".");
if(dotIndex!=-1)
trufilename=substring(filename,0,dotIndex);
else
trufilename=filename;

titlelistOri=getList("image.titles");
IJ.redirectErrorMessages();
open(VolPath);

titlelistAfter=getList("image.titles");

if(titlelistOri.length == titlelistAfter.length){
	print("The file cannot open; "+VolPath);
	logsum=getInfo("log");
	File.saveString(logsum, savedir+"Rotation_After_Warp.txt");
	
	run("Quit");
	
}

samporiH=getHeight();

print("Opened; "+VolPath);
logsum=getInfo("log");
logpath=savedir+"Rotation_After_Warp.txt";
File.saveString(logsum, logpath);

getVoxelSize(OriTempWidth, OriTempHeight, OriTempDepth, OriTempUnit);

Tempheight=round(Tempheight);
Tempwidth=round(Tempwidth);
TotalRotationFrontal=parseFloat(TotalRotationFrontal);//Chaneg string to number
samporiH=parseFloat(samporiH);
FrontalChangeRatio300px=parseFloat(FrontalChangeRatio300px);


print("TotalRotationFrontal; "+TotalRotationFrontal);
print("TotalXtranslation; "+TotalXtranslation);
print("TotalYtranslation; "+TotalYtranslation);
print("savedir; "+savedir);

print("");

print("Tempheight; "+Tempheight);
print("Tempwidth; "+Tempwidth);
print("samporiH; "+samporiH);
print("FrontalChangeRatio300px; "+FrontalChangeRatio300px);




ThreeDrotationArray = newArray(Tempwidth*1.5,Tempheight*1.2,TotalRotationFrontal,OriTempWidth,OriTempHeight,OriTempDepth);

ThreeDrotation (ThreeDrotationArray,TotalXtranslation,TotalYtranslation,savedir,trufilename,samporiH,0,FrontalChangeRatio300px,logpath);

selectWindow("FinalGamma.tif");


run("Canvas Size...", "width="+Tempwidth+" height="+Tempheight+" position=Center zero");

SliceNumberAdjustment(nSlices,TempSlice);

//run("Unsharp Mask...", "radius=0.5 mask=0.60 stack");
run("Nrrd Writer", "compressed nrrd="+VolPath);
close();



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

function ThreeDrotation (ThreeDrotationArray,TotalXtranslation,TotalYtranslation,myDir,trufilename,CanvasHeight,0,FrontalChangeRatio300px,filepath){
	imagesave=0;
	
	sampleLongLengthW=ThreeDrotationArray[0];
	sampleLongLengthH =ThreeDrotationArray[1];
	TotalRotationFrontal =ThreeDrotationArray[2];
	OriSampWidth =ThreeDrotationArray[3];
	OriSampHeight =ThreeDrotationArray[4];
	OriSampDepth =ThreeDrotationArray[5];
	
	WW=getWidth();
	HH=getHeight();
	
	longlength=round(sqrt(sampleLongLengthW*sampleLongLengthW+sampleLongLengthH*sampleLongLengthH));
	run("Canvas Size...", "width="+longlength+" height="+longlength+" position=Center zero");//CanvasWidth//TempResliceLateralWidth
	
	
	if(TotalRotationFrontal!=0){
		run("Rotation Hideo", "rotate="+TotalRotationFrontal+" 3d in=InMacro");
		run("Properties...", "channels=1 slices="+nSlices+" frames=1 unit=microns pixel_width="+OriSampWidth+" pixel_height="+OriSampHeight+" voxel_depth="+OriSampDepth+"");
		print("xy rotated; TotalRotationFrontal; "+TotalRotationFrontal);
	}//	if(TotalRotationFrontal>0){
	
	OrigiRotate=getImageID();
	
	run("Translate...", "x="+TotalXtranslation+" y="+TotalYtranslation+" interpolation=None stack");
	print("Translated 215; x; "+TotalXtranslation+"  y; "+TotalYtranslation);
	
	rename("FinalGamma.tif");
	
	
	//	setBatchMode(false);
	//		updateDisplay();
	//		"do"
	//		exit();
	
	if(imagesave==1){
		run("Z Project...", "projection=[Max Intensity]");
		
		saveAs("PNG", myDir+trufilename+"_After_Reslice.png");
		close();
		selectImage(OrigiRotate);
	}
	
	logsum=getInfo("log");
	File.saveString(logsum, filepath);
	
}//function ThreeDrotation


run("Misc...", "divide=Infinity save");
run("Quit");











