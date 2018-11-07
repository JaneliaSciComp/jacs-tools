
run("Misc...", "divide=Infinity save");

testArg=0;

//testArg="H:/Registration2/63x_align/reformatted/,Temp1_PRE_PROCESSED_01_warp_m0g80c8e1e-1x26r4.nrrd,H:/Registration2/63x_align/reformatted/Temp1_PRE_PROCESSED_01_warp_m0g80c8e1e-1x26r4.nrrd,N:/test_folder/JRC_SS23221_20160803_31_E5translation.txt,1";


if(testArg!=0)
args = split(testArg,",");
else
args = split(getArgument(),",");

savedir = args[0];// save dir
filename = args[1];//file name
VolPath = args[2];//file path
TxtPath = args[3];// full file path for inport LSM
HFneed = args[4];// 0 is no HF, 1 is HF + full, 2 is HF only


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
			maxrotationL = String.buffer;
		}else if(swi==7 && swi<=testline){
			maxXL = String.buffer;
		}else if(swi==8 && swi<=testline){
			maxYL = String.buffer;
		}else if(swi==9 && swi<=testline){
			zoomratiolateral300= String.buffer;
		}else if(swi==10 && swi<=testline){
			ThrdTrans = String.buffer;
		}else if(swi==11 && swi<=testline){
			maxrotation3= String.buffer;
		}else if(swi==12 && swi<=testline){
			maxX3= String.buffer;
		}else if(swi==13 && swi<=testline){
			maxY3= String.buffer;
		}else if(swi==14 && swi<=testline){
			FrontalChangeRatio300px= String.buffer;
		}else if(swi==15 && swi<=testline){
			LateralW= String.buffer;
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
maxXL=parseFloat(maxXL);
maxYL=parseFloat(maxYL);
samporiH=parseFloat(samporiH);
zoomratiolateral300=parseFloat(zoomratiolateral300);
maxrotation3=parseFloat(maxrotation3);
maxX3=parseFloat(maxX3);
maxY3=parseFloat(maxY3);
FrontalChangeRatio300px=parseFloat(FrontalChangeRatio300px);
ThrdTrans=parseFloat(ThrdTrans);
LateralW=round(LateralW);

print("TotalRotationFrontal; "+TotalRotationFrontal);
print("TotalXtranslation; "+TotalXtranslation);
print("TotalYtranslation; "+TotalYtranslation);
print("savedir; "+savedir);

print("");

print("Tempheight; "+Tempheight);
print("Tempwidth; "+Tempwidth);
print("maxrotationL; "+maxrotationL);
print("maxXL; "+maxXL);
print("maxYL; "+maxYL);
print("samporiH; "+samporiH);
print("zoomratiolateral300; "+zoomratiolateral300);
print("maxrotation3; "+maxrotation3);
print("maxX3; "+maxX3);
print("maxY3; "+maxY3);
print("FrontalChangeRatio300px; "+FrontalChangeRatio300px);
print("ThrdTrans; "+ThrdTrans);




ThreeDrotationArray = newArray(Tempwidth,Tempheight*1.5,TotalRotationFrontal,OriTempWidth,OriTempHeight,OriTempDepth);

ThreeDrotation (ThreeDrotationArray,TotalXtranslation,TotalYtranslation,savedir,trufilename,maxrotationL,maxXL,maxYL,samporiH,zoomratiolateral300,ThrdTrans,maxrotation3,maxX3,maxY3,0,FrontalChangeRatio300px,logpath,LateralW);

selectWindow("FinalGamma.tif");


run("Canvas Size...", "width="+Tempwidth+" height="+Tempheight+" position=Center zero");

SliceNumberAdjustment(nSlices,TempSlice);


//aa

if(HFneed==2){
	if(Tempwidth==3333)//female
	run("Size...", "width=1652 height=768 depth=478 interpolation=Bicubic");
	
	else if(Tempwidth==3150) //male
	run("Size...", "width=1561 height=744 depth=476 interpolation=Bicubic");
}

run("Unsharp Mask...", "radius=0.5 mask=0.60 stack");
run("Nrrd Writer", "compressed nrrd="+VolPath);

if(HFneed==0){
	run("Z Project...", "projection=[Max Intensity]");
	run("Enhance Contrast", "saturated=0.3");
	run("Apply LUT");
	run("8-bit");
	
	saveAs("PNG", savedir+"/"+trufilename+"_MIP.png");
	close();
}


if(HFneed==1){
	run("Size...", "width="+round(getWidth/2)+" height="+round(getHeight/2)+" depth="+nSlices+" constrain interpolation=Bicubic");

	run("Nrrd Writer", "compressed nrrd="+savedir+"/"+trufilename+"_HF.nrrd");
	
	run("Z Project...", "projection=[Max Intensity]");
	run("Enhance Contrast", "saturated=0.3");
	run("Apply LUT");
	run("8-bit");
	
	saveAs("PNG", savedir+"/"+trufilename+"_MIP.png");
	close();
}
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

function ThreeDrotation (ThreeDrotationArray,TotalXtranslation,TotalYtranslation,myDir,trufilename,maxrotationL,maxXL,maxYL,CanvasHeight,zoomratiolateral300,ThrdTrans,maxrotation3,maxX3,maxY3,0,FrontalChangeRatio300px,filepath,LateralW){
	imagesave=0;
	
	sampleLongLengthW=ThreeDrotationArray[0];
	sampleLongLengthH =ThreeDrotationArray[1];
	TotalRotationFrontal =ThreeDrotationArray[2];
	OriSampWidth =ThreeDrotationArray[3];
	OriSampHeight =ThreeDrotationArray[4];
	OriSampDepth =ThreeDrotationArray[5];
	
	WW=getWidth();
	HH=getHeight();
	
	longlength=round(sqrt(WW*WW+HH*HH));
	run("Canvas Size...", "width="+longlength+" height="+longlength+" position=Center zero");//CanvasWidth//TempResliceLateralWidth
	
	
	if(TotalRotationFrontal!=0){
		run("Rotation Hideo", "rotate="+TotalRotationFrontal+" 3d in=InMacro");
		run("Properties...", "channels=1 slices="+nSlices+" frames=1 unit=microns pixel_width="+OriSampWidth+" pixel_height="+OriSampHeight+" voxel_depth="+OriSampDepth+"");
		print("xy rotated; TotalRotationFrontal; "+TotalRotationFrontal);
	}//	if(TotalRotationFrontal>0){
	
	OrigiRotate=getImageID();
	run("Canvas Size...", "width="+sampleLongLengthW+" height="+round(CanvasHeight*1.5)+" position=Center zero");//CanvasWidth//TempResliceLateralWidth
	
	
	run("Translate...", "x="+TotalXtranslation+" y="+TotalYtranslation+" interpolation=None stack");
	print("Translated 2102; x; "+TotalXtranslation+"  y; "+TotalYtranslation);
	
	
	
	
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
		
		if(maxrotationL!=0){
			getVoxelSize(LVxWidth, LVxHeight, LVxDepth, LVxUnit);
			//	run("Canvas Size...", "width="+resliceLongLength+" height="+round(CanvasHeight*1.2)+" position=Center zero");
			run("Rotation Hideo", "rotate="+maxrotationL+" 3d in=InMacro");
			run("Properties...", "channels=1 slices="+nSlices+" frames=1 unit=microns pixel_width="+LVxWidth+" pixel_height="+LVxHeight+" voxel_depth="+LVxDepth+"");
		}
		print("maxrotationL; "+maxrotationL+"   Reslice Depth; "+LVxDepth+"   round(maxXL*zoomratiolateral300); "+round(maxXL*zoomratiolateral300)+"   maxXL; "+maxXL);
		
		//	setBatchMode(false);
		//					updateDisplay();
		//					"do"
		//					exit();
		if(ThrdTrans==1){
			run("Translate...", "x="+round(maxXL*zoomratiolateral300)+" y="+round(maxYL*zoomratiolateral300)+" interpolation=None stack");
			print( "xL ="+round(maxXL*zoomratiolateral300)+" yL ="+round(maxYL*zoomratiolateral300));
		}else{
			
			if(maxXL!=0)
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
	
	
	//	setBatchMode(false);
	//		updateDisplay();
	//		"do"
	//		exit();
	
	
	
	
	
	
	if(isOpen(resliceGamma)){
		selectImage(resliceGamma);
		close();
	}
	
	selectWindow("FinalGamma.tif");
	
	if(imagesave==1){
		run("Z Project...", "projection=[Max Intensity]");
		
		saveAs("PNG", myDir+trufilename+"_After_Reslice.png");
		close();
		selectImage(OrigiRotate);
	}
	
	
	
	//	setBatchMode(false);
	//	updateDisplay();
	//	"do"
	//	exit();
	
	logsum=getInfo("log");
	File.saveString(logsum, filepath);
	
	if(maxrotationL!=0 || maxXL!=0 || maxYL!=0){
		selectImage(OrigiRotate);
		close();
	}
}//function ThreeDrotation


run("Misc...", "divide=Infinity save");
run("Quit");











