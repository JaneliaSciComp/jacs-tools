//Pre-Image processing for Brain before CMTK operation
//Wrote by Hideo Otsuna, Jan 16, 2018

MIPsave=1;
ShapeAnalysis=1;//perform shape analysis and kick strange sample
CLAHEwithMASK=1;
Batch=1;
BWd=0; //BW decision at 793 line
PrintSkip=0;
templateBr="JFRC2014";//JFRC2013, JFRC2014, JRC2018
ForceUSE=false;
nrrdEx=true;
revstack=false;

cropWidth=1200;
cropHeight=750;
ChannelInfo = "01 02 nrrd files";
blockposition=1;
totalblock=1;
Frontal50pxPath=0;
MCFOYN=false;
TwentyMore=false;
nc82decision="Color base";
DecidedColor="Red";
ShapeMatchingMaskPath=0;
JFRC2010AveProPath=0;
Slice50pxPath=0;
LateralMIPPath=0;
dir=0;
savedir=0;
saveOK=0;
lsmOK=0;
rotationYN="No";
BrainShape= "Unknown";//"Both_OL_missing (40x)";//"Intact", "Both_OL_missing (40x)", "Unknown"
shrinkTo2010=false;

shiftY=15;
DesireX=512;

setBatchMode(true);
testArg=0;

// 40x
//testArg= "/test/20x_brain_alignment/pre_Align_Test_Vol,BJD_103A02_AE_01_40x.h5j,/test/20x_brain_alignment/Pipeline_Test_Sample/BJD_103A02_AE_01_40x.h5j,/Users/otsunah/Documents/otsunah/20x_brain_aligner/,0.44,0.44,7,40x"

//for 20x
//testArg= "/test/20x_brain_alignment/Pipeline/,tile-2559915496522645525.v3dpbd,/test/20x_brain_alignment/Pipeline/tile-2559915496522645525.v3dpbd,/Users/otsunah/Documents/otsunah/20x_brain_aligner/,0.62,1,7,20x,JRC2018,Unknown,/test/20x_brain_alignment/Pipeline/ConsolidatedLabel.v3dpbd"

if(testArg!=0)
args = split(testArg,",");
else
args = split(getArgument(),",");

savedir = args[0];// save dir
filename = args[1];//file name
path = args[2];// full file path for inport LSM
MatchingFilesDir = args[3];
widthVx = args[4];// X voxel size
depth = args[5];// slice depth
NumCPU=args[6];
objective = args [7];//"40x" or "20x"
templateBr = args [8];//"JFRC2014", JFRC2013, JFRC2014, JRC2018
BrainShape = args [9];//"Both_OL_missing (40x)";//"Intact", "Both_OL_missing (40x)", "Unknown"
PathConsolidatedLabel=args[10];// full file path for ConsolidatedLabel.v3dpbd

Frontal50pxPath = MatchingFilesDir+"JFRC2010_50pxMIP.tif";// full file path for "JFRC2010_50pxMIP.tif"
LateralMIPPath = MatchingFilesDir+"Lateral_JFRC2010_5time_smallerMIP.tif";//  full file path for "Lateral_JFRC2010_5time_smallerMIP.tif"
Slice50pxPath = MatchingFilesDir+"JFRC2010_50pxSlice.tif";//  full file path for "JFRC2010_50pxSlice.tif"
ShapeMatchingMaskPath = MatchingFilesDir+"JFRC2010_ShapeMatchingMask.tif";//"JFRC2010_ShapeMatchingMask.tif";
JFRC2010AveProPath = MatchingFilesDir+"JFRC2010_AvePro.png"; //"JFRC2010_AvePro.png"

widthVx=parseFloat(widthVx);//Chaneg string to number
depth=parseFloat(depth);//Chaneg string to number
heightVx=widthVx;
NumCPU= parseFloat(NumCPU);//Chaneg string to number

Ori_widthVx = widthVx;
Ori_heightVx = widthVx;

if(objective=="40x"){
	cropWidth=1260;
	cropHeight=750;
}

print("path;"+path);
print("savedir; "+savedir);
print("X resolution; "+widthVx+" micron");
print("Frontal50pxPath; "+Frontal50pxPath);
print("LateralMIPPath; "+LateralMIPPath);
print("Slice50pxPath; "+Slice50pxPath);
print("ShapeMatchingMaskPath; "+ShapeMatchingMaskPath);
print("JFRC2010AveProPath; "+JFRC2010AveProPath);
print("NumCPU; "+NumCPU);
print("objective; "+objective);
print("PathConsolidatedLabel; "+PathConsolidatedLabel);
print("");
print("BrainShape; "+BrainShape);
print("cropWidth; "+cropWidth+"   cropHeight; "+cropHeight);

savedirext=File.exists(savedir);
if(savedirext!=1)
File.makeDirectory(savedir);

logsum=getInfo("log");
filepath=savedir+"20x_brain_pre_aligner_log.txt";
File.saveString(logsum, filepath);

String.resetBuffer;
n3 = lengthOf(savedir);
for (si=0; si<n3; si++) {
	c = charCodeAt(savedir, si);
	if(c==32){// if there is a space
		print("There is a space, please eliminate the space from saving directory.");
		
		logsum=getInfo("log");
		filepath=savedir+"20x_brain_pre_aligner_log.txt";
		File.saveString(logsum, filepath);
		exit();
	}
	//	String.append(fromCharCode(c));
	//	filename = String.buffer;
}
String.resetBuffer;

myDir0 = savedir+"Shape_problem"+File.separator;
File.makeDirectory(myDir0);

myDir4 = savedir+"High_background_cannot_segment_VNC"+File.separator;
File.makeDirectory(myDir4);

logsum=getInfo("log");
filepath=savedir+"20x_brain_pre_aligner_log.txt";
File.saveString(logsum, filepath);

mask=savedir+"Mask"+File.separator;
File.makeDirectory(mask);

ID20xMIP=0;

FilePathArray=newArray(Frontal50pxPath, "JFRC2010_50pxMIP.tif");
fileOpen(FilePathArray);
Frontal50pxPath=FilePathArray[0];

FilePathArray=newArray(LateralMIPPath, "Lateral_JFRC2010_5time_smallerMIP.tif");
fileOpen(FilePathArray);
LateralMIPPath=FilePathArray[0];

FilePathArray=newArray(Slice50pxPath, "JFRC2010_50pxSlice.tif");
fileOpen(FilePathArray);
Slice50pxPath=FilePathArray[0];

FilePathArray=newArray(ShapeMatchingMaskPath, "JFRC2010_ShapeMatchingMask.tif");
fileOpen(FilePathArray);
ShapeMatchingMaskPath=FilePathArray[0];

FilePathArray=newArray(JFRC2010AveProPath, "JFRC2010_AvePro.png");
fileOpen(FilePathArray);
JFRC2010AveProPath=FilePathArray[0];

noext2=0;


///// Duplication check //////////////////////////////////////////////////////////////

filepathcolor=0; 
NRRD_02_ext=0; 
Nrrdnumber=0;


List.clear();

beforeopen=getTime();
open(path);// for tif, comp nrrd, lsm", am, v3dpbd, mha
afteropen=getTime();

fileopentime=(afteropen-beforeopen)/1000;
print("file open time; "+fileopentime+" sec");

logsum=getInfo("log");
filepath=savedir+"20x_brain_pre_aligner_log.txt";
File.saveString(logsum, filepath);

starta=getTime();
getDimensions(width, height, channels, slices, frames);


if(Ori_widthVx>0.43 && objective=="40x" && Ori_widthVx<0.46){
	print("40x vx size changed!! from "+Ori_widthVx+" to 0.4713");
	Ori_widthVx = 0.4713;
	Ori_heightVx = 0.4713;
	widthVx = Ori_widthVx;
	heightVx = Ori_heightVx;
	
	run("Properties...", "channels="+channels+" slices="+nSlices/channels+" frames=1 unit=microns pixel_width="+Ori_widthVx+" pixel_height="+Ori_heightVx+" voxel_depth="+depth+"");
}else
run("Properties...", "channels="+channels+" slices="+nSlices/channels+" frames=1 unit=microns pixel_width="+widthVx+" pixel_height="+widthVx+" voxel_depth="+depth+"");


print(bitDepth+" bit");

DotIndex = lastIndexOf(filename, ".");
noext = substring(filename, 0, DotIndex);

if(width<height)
longlength=height;
else
longlength=width;

if(channels==2 || channels==3 || channels==4)
run("Split Channels");

print("channels; "+channels);

logsum=getInfo("log");
File.saveString(logsum, filepath);

titlelist=getList("image.titles");
signal_count = 0;
neuron=newArray(titlelist.length);
UnknownChannel=newArray(titlelist.length);
posicolor=newArray(titlelist.length);
Original3D=newArray(titlelist.length);

posicolorNum=0;

if(channels==1 && nSlices>240){
	roundSlices = round(nSlices/4);
	actualSlice = nSlices/4;
	
	while(roundSlices!=actualSlice){
		setSlice(nSlices);
		run("Delete Slice");
		actualSlice = nSlices/4;
	}
	run("Stack to Hyperstack...", "order=xyczt(default) channels=4 slices="+nSLices/4+" frames=1 display=Composite");
	getDimensions(width, height, channels, slices, frames);
	run("Split Channels");
}

if(channels==1 && nSlices<240){
	print("There is no neuron channel; slice num; "+nSlices);
	
	logsum=getInfo("log");
	filepath=savedir+"20x_brain_pre_aligner_log.txt";
	File.saveString(logsum, filepath);
	
	run("Quit");
}


titlelist=getList("image.titles");
signal_count = 0; neuron2=0; neuron3=0;
neuron=newArray(titlelist.length);
UnknownChannel=newArray(titlelist.length);
posicolor=newArray(titlelist.length);
Original3D=newArray(titlelist.length);

for (iCh=0; iCh<titlelist.length; iCh++) {
	selectWindow(titlelist[iCh]);
	
	if(nSlices>1){
		//	cc = substring(chanspec,iCh,iCh+1);
		print("titlelist[iCh]; "+titlelist[iCh]);
		UnknownChannel[posicolorNum]=getImageID();
		posicolorNum=posicolorNum+1;
	}
}//for (i=0; i<lengthOf(chanspec); i++) {

logsum=getInfo("log");
File.saveString(logsum, filepath);

if(channels==2){
	
	selectImage(UnknownChannel[1]);//ch2
	nc82=getImageID();//White
	
	selectImage(UnknownChannel[0]);//ch1
	neuron=getImageID();
	
}//if(channels==2){

if(channels==3){
	
	selectImage(UnknownChannel[2]);//ch3
	nc82=getImageID();
	
	selectImage(UnknownChannel[0]);//ch1
	neuron=getImageID();
	
	selectImage(UnknownChannel[1]);//ch2
	neuron2=getImageID();
}//if(posicolor0=="Red" && posicolor1=="White"){


if(channels==4){
	selectImage(UnknownChannel[3]);
	nc82=getImageID();
	
	selectImage(UnknownChannel[0]);
	neuron=getImageID();
	
	selectImage(UnknownChannel[1]);
	neuron2=getImageID();	
	
	selectImage(UnknownChannel[2]);
	neuron3=getImageID();	
}//if(channels==4){


maxvalue0=255;

if(channels!=1){
	selectImage(nc82);
	NC82SliceNum=nSlices();
	
}

if(bitDepth==16)
maxvalue0=65535;

maxsizeData=0; SizeM=0;

ID20xMIP=0; positiveAR=0; lowerM=3; threTry=0; prelower=0; finalMIP=0; ABSMaxARShape=0; ABSmaxSize=0;
maxARshape=1.7; ABSmaxCirc=0; MaxOBJScore=0; MaxRot=0; angle=400;

elipsoidArea = 0;//area of mask
elipsoldAngle = 0;//angle of mask
numberResults=0; mask1st=0; invertON=0; shortARshapeGap=0;

selectImage(nc82);
rename("nc82.tif");
bitd=bitDepth();

if(bitDepth==8)
run("16-bit");

run("Z Project...", "start=10 stop="+nSlices-10+" projection=[Max Intensity]");
run("Enhance Contrast", "saturated=0.35");
run("Apply LUT");
run("8-bit");
saveAs("PNG", ""+myDir4+noext+"_Max01.png");
close();
selectWindow("nc82.tif");

run("Duplicate...", "title=nc82_Ori.tif duplicate");
selectWindow("nc82.tif");

VoxSizeADJArray=newArray(widthVx,heightVx,depth);
VoxSizeADJ(VoxSizeADJArray,DesireX,objective);

widthVx = VoxSizeADJArray[0];
heightVx = VoxSizeADJArray[1];
depthVox = VoxSizeADJArray[2];

ZoomratioSmall=Ori_widthVx/6.2243;
Zoomratio=Ori_widthVx/0.62243;
if(Zoomratio>0.99 && Zoomratio<1.01)
Zoomratio=1;

xcenter=round(getWidth/2); ycenter=round(getHeight/2);

DupAvePprocessing (nc82,NumCPU,bitd);// DUPaveP.tif creation from nc82.tif

selectWindow("DUPaveP.tif");
print("ZoomratioSmall; "+ZoomratioSmall+"   widthVx; "+widthVx+"  round(getWidth/ZoomratioSmall); "+round(getWidth/ZoomratioSmall)+"   Zoomratio; "+Zoomratio);
run("Size...", "width="+round(getWidth*ZoomratioSmall)+" height="+round(getHeight*ZoomratioSmall)+" depth=1 constrain interpolation=None");
run("Canvas Size...", "width=102 height=102 position=Center zero");


//	setBatchMode(false);
//		updateDisplay();
//		"do"
//		exit();

rotSearch=60; 	MaxZoom=1; 	setForegroundColor(0, 0, 0);

if(objective=="40x")
BrainShape="Both_OL_missing (40x)";

if(BrainShape=="Intact" || BrainShape=="Unknown"){
	ImageCarray=newArray(0, 0, 0, 0);
	ImageCorrelation2 ("DUPaveP.tif", "JFRC2010_AvePro.png", rotSearch,ImageCarray,90,NumCPU);
	
	OBJScoreOri=ImageCarray[0];
	OriginalRot=ImageCarray[1];
	OriginalYshift=ImageCarray[2];
	OriginalXshift=ImageCarray[3];
	
	maxX=OriginalXshift/2;
	maxY=OriginalYshift/2;
	
	print("772 BrainShape; "+BrainShape+"   OBJScore; "+OBJScoreOri+"  OriginalRot; "+OriginalRot);
	
	logsum=getInfo("log");
	File.saveString(logsum, filepath);
	
	if(objective=="20x"){
		ImageCorrelationArray=newArray(nc82, 0,0,0,0,0,0);
		ImageCorrelation(ImageCorrelationArray,Ori_widthVx,NumCPU);// with zoom adjustment, it was widthVx
		
		//		OriginalRot=ImageCorrelationArray[4];
		//		OBJScoreOri=ImageCorrelationArray[5];
		MaxZoom=ImageCorrelationArray[6];
		//		OriginalXshift = ImageCorrelationArray[2];
		//		OriginalYshift = ImageCorrelationArray[3];
		
		if(MaxZoom!=1){
			print("MaxZoom is not 1; "+MaxZoom);
			
			widthVx=widthVx*MaxZoom; heightVx=heightVx*MaxZoom;
			
			Ori_widthVx = Ori_widthVx*MaxZoom; Ori_heightVx = Ori_heightVx*MaxZoom;
			ZoomratioSmall=ZoomratioSmall*MaxZoom; Zoomratio = Zoomratio*MaxZoom;
			
			selectWindow("OriginalProjection.tif");
			close();
			
			selectWindow("DUPaveP.tif");
			close();
			
			while(isOpen("nc82.tif")){
				selectWindow("nc82.tif");
				close();
			}
			if(isOpen("nc82.tif"))
			exit("nc82 cannot close 897");
			
			wait(100);
			call("java.lang.System.gc");
			
			selectWindow("nc82_Ori.tif");
			rename("nc82.tif");
			nc82=getImageID();
			
			run("Properties...", "channels=1 slices="+nSlices+" frames=1 unit=microns pixel_width="+Ori_widthVx+" pixel_height="+Ori_heightVx+" voxel_depth="+depth+"");
			
			run("Duplicate...", "title=nc82_Ori.tif duplicate");
			nc82Ori=getImageID();
			
			selectWindow("nc82.tif");
			
			DupAvePprocessing (nc82,NumCPU,bitd);// DUPaveP.tif creation from nc82.tif
			
			selectWindow("DUPaveP.tif");
			print("ZoomratioSmall; "+ZoomratioSmall+"   widthVx; "+widthVx+"  round(getWidth/ZoomratioSmall); "+round(getWidth/ZoomratioSmall));
			run("Size...", "width="+round(getWidth*ZoomratioSmall)+" height="+round(getHeight*ZoomratioSmall)+" depth=1 constrain interpolation=None");
			run("Canvas Size...", "width=102 height=102 position=Center zero");
			
			ImageCarray=newArray(0, 0, 0, 0);
			ImageCorrelation2 ("DUPaveP.tif", "JFRC2010_AvePro.png", rotSearch,ImageCarray,90,NumCPU);
			
			OBJScoreOri=ImageCarray[0];
			OriginalRot=ImageCarray[1];
			OriginalYshift=ImageCarray[2];
			OriginalXshift=ImageCarray[3];
			
			maxX=OriginalXshift/2;
			maxY=OriginalYshift/2;
			
			print("   OBJScore after Zoom; "+OBJScoreOri+"  OriginalRot; "+OriginalRot);	
		}//if(MaxZoom!=1){
	}//if(objective=="20x"){
	
	finalshiftX=round((OriginalXshift/ZoomratioSmall)/2);
	finalshiftY=round((OriginalYshift/ZoomratioSmall)/2);
	print("MaxZoom; "+MaxZoom+"   widthVx; "+Ori_widthVx+"   heightVx; "+Ori_heightVx+"   Zoomratio; "+Zoomratio);
}//	if(BrainShape=="Intact" || BrainShape=="Unknown"){

if(BrainShape=="Unknown"){
	//	if(OBJScoreOri<500){
	print("  Optic lobe checking!!  OBJScoreOri; "+OBJScoreOri);
	selectWindow("JFRC2010_AvePro.png");
	run("Duplicate...", "title=JFRC2010_AvePro-Rop.png");
	makePolygon(82,34,74,52,66,65,69,76,90,80,99,72,101,58,100,34);// elimination of the R-Op
	
	run("Fill", "slice");
	BrainShape="Intact";
	
	ImageCarray=newArray(0, 0, 0, 0);
	ImageCorrelation2 ("DUPaveP.tif", "JFRC2010_AvePro-Rop.png", rotSearch,ImageCarray,90,NumCPU);
	
	OBJScoreR=ImageCarray[0];
	RotR=ImageCarray[1];
	ShiftYR = ImageCarray[2];
	ShiftXR = ImageCarray[3];
	selectWindow("JFRC2010_AvePro-Rop.png");
	close();//"JFRC2010_AvePro-Rop.png"
	print("OBJScoreR; "+OBJScoreR);
	
	selectWindow("JFRC2010_AvePro.png");
	makePolygon(17,31,22,42,31,51,37,65,31,79,14,79,2,74,2,54,1,38);//L-OL elimination
	run("Fill", "slice");
	ImageCarray=newArray(0, 0, 0, 0);
	
	//		setBatchMode(false);
	//		updateDisplay();
	//		"do"
	//		exit();
	
	
	ImageCorrelation2 ("DUPaveP.tif", "JFRC2010_AvePro.png", rotSearch,ImageCarray,90,NumCPU);
	
	OBJScoreL=ImageCarray[0];
	RotL=ImageCarray[1];
	ShiftYL = ImageCarray[2];
	ShiftXL = ImageCarray[3];
	print("OBJScoreL; "+OBJScoreL);
	
	selectWindow("JFRC2010_AvePro.png");
	makePolygon(82,34,74,52,66,65,69,76,90,80,99,72,101,58,100,34);// elimination of the R-Op
	run("Fill", "slice");
	ImageCarray=newArray(0, 0, 0, 0);
	ImageCorrelation2 ("DUPaveP.tif", "JFRC2010_AvePro.png", rotSearch,ImageCarray,90,NumCPU);
	
	OBJScoreBoth=ImageCarray[0];
	RotBoth=ImageCarray[1];
	ShiftYboth = ImageCarray[2];
	ShiftXboth = ImageCarray[3];
	print("OBJScoreBoth; "+OBJScoreBoth);
	
	if(OBJScoreL>OBJScoreR && OBJScoreL>OBJScoreOri && OBJScoreL>OBJScoreBoth){
		OBJScoreOri = OBJScoreL;
		BrainShape="Left_OL_missing";
		OriginalRot=RotL;
		OriginalXshift = ShiftXL;
		OriginalYshift = ShiftYL;
		ID20xMIP=1;
		finalMIP="Max projection";
		SizeM=1; 
		
	}
	if(OBJScoreR>OBJScoreL && OBJScoreR>OBJScoreOri && OBJScoreR>OBJScoreBoth){
		OBJScoreOri = OBJScoreR;
		BrainShape="Right_OL_missing";
		OriginalRot=RotR;
		OriginalXshift = ShiftXR;
		OriginalYshift = ShiftYR;
		
		ID20xMIP=1;
		finalMIP="Max projection";
		SizeM=1; 
	}
	if(OBJScoreBoth>OBJScoreR && OBJScoreBoth>OBJScoreL && OBJScoreBoth>OBJScoreOri){
		OBJScoreOri = OBJScoreBoth;
		BrainShape="Both_OL_missing";
		OriginalRot=RotBoth;
		OriginalXshift = ShiftXboth;
		OriginalYshift = ShiftYboth;
		
		ID20xMIP=1;
		finalMIP="Max projection";
		SizeM=1; 
	}
	maxX=OriginalXshift;
	maxY=OriginalYshift;
	
	finalshiftX=round((OriginalXshift/ZoomratioSmall)/2);
	finalshiftY=round((OriginalYshift/ZoomratioSmall)/2);
}//if(BrainShape=="Unknown"){

if(BrainShape=="Both_OL_missing (40x)"){
	selectWindow("JFRC2010_AvePro.png");
	makePolygon(17,31,22,42,31,51,37,65,31,79,14,79,2,74,2,54,1,38);//L-OL elimination
	run("Fill", "slice");
	
	makePolygon(82,34,74,52,66,65,69,76,90,80,99,72,101,58,100,34);// elimination of the R-Op
	run("Fill", "slice");
	ImageCarray=newArray(0, 0, 0, 0);
	ImageCorrelation2 ("DUPaveP.tif", "JFRC2010_AvePro.png", rotSearch,ImageCarray,80,NumCPU);
	
	OBJScoreOri=ImageCarray[0];
	OriginalRot=ImageCarray[1];
	OriginalYshift = ImageCarray[2];
	OriginalXshift = ImageCarray[3];
	print("OBJScoreBoth; "+OBJScoreOri);
	
	maxX=OriginalXshift;
	maxY=OriginalYshift;
	
	finalshiftX=round((OriginalXshift/ZoomratioSmall)/2);
	finalshiftY=round((OriginalYshift/ZoomratioSmall)/2);
	
	ID20xMIP=1;
	finalMIP="Max projection";
	SizeM=1; 
}


while(isOpen("JFRC2010_AvePro.png")){
	selectWindow("JFRC2010_AvePro.png");
	close();//"JFRC2010_AvePro.png"
}

while(isOpen("DUPaveP.tif")){
	selectWindow("DUPaveP.tif");
	close();
}

elipsoidAngle=OriginalRot;
OBJScore=OBJScoreOri;
print("");
print("BrainShape; "+BrainShape+"   OBJScore; "+OBJScoreOri+"  OriginalRot; "+OriginalRot+"   maxX; "+maxX+"   maxY; "+maxY);

File.saveString(BrainShape, savedir+"OL_shape.txt");

while(isOpen("OriginalProjection.tif")){
	selectWindow("OriginalProjection.tif");
	close();
}

run("Set Measurements...", "area centroid center perimeter fit shape redirect=None decimal=2");

if(BrainShape=="Intact"){
	firstTime=0; 
	for(MIPstep=1; MIPstep<3; MIPstep++){// Segmentation of the brain
		endthre=0; lowestthre=100000; maxARshapeGap=100000; maxThreTry=100; MaxCirc=0.18; 
		for(ThreTry=0; ThreTry<=maxThreTry; ThreTry++){
			
			showStatus("Brain rotation");
			selectImage(nc82);
			
			//	setBatchMode(false);
			//		updateDisplay();
			//		"do"
			//exit();
			
			if(ThreTry>0){
				selectImage(OriginalProjection);
				
				
			}else if(ThreTry==0){
				if(MIPstep==1)
				run("Z Project...", "start=10 stop="+nSlices-10+" projection=[Average Intensity]");// imageID is AR
				else if(MIPstep==2)
				run("Z Project...", "start=15 stop="+nSlices-10+" projection=[Max Intensity]");// imageID is AR
				
				//		run("Minimum...", "radius=5");
				//		run("Maximum...", "radius=5");
				
				rename("OriginalProjection.tif");
				OriginalProjection=getImageID();
			}
			
			selectWindow("OriginalProjection.tif");
			run("Duplicate...", "title=DUPprojection.tif");// for Masking
			DUPprojection=getImageID();
			
			//			setBatchMode(false);
			//			updateDisplay();
			//			aa
			
			if(ThreTry>3){
				
				lowestthre=lowestthre+increment16bit;
				
				setThreshold(lowestthre, maxvalue0);
				setForegroundColor(255, 255, 255);
				setBackgroundColor(0, 0, 0);
				run("Make Binary", "thresholded remaining");
				
				//	run("Fill Holes");
				
				if(firstTime==1)
				ThreTry=maxThreTry+1;
				
			}else{
				
				run("8-bit");
				
				if(ThreTry==0)
				setAutoThreshold("Triangle dark");
				else if(ThreTry==1)
				setAutoThreshold("Default dark");
				else if(ThreTry==2)
				setAutoThreshold("Huang dark");
				else if(ThreTry==3)
				setAutoThreshold("Percentile dark");
				
				getThreshold(lower, upper);
				setThreshold(lower, maxvalue0);
				print("MIPstep; "+MIPstep+"   ThreTry; "+ThreTry+"   "+lower+"  lower");
				
				//			setOption("BlackBackground", true);
				
				setForegroundColor(255, 255, 255);
				setBackgroundColor(0, 0, 0);
				run("Make Binary", "thresholded remaining");
				
				//			run("Fill Holes");
				
				//		if(ThreTry==2){
				//			setBatchMode(false);
				//			updateDisplay();
				//			aa
				//		}
				
				if(lowestthre>lower)
				lowestthre=lower;
				
				if(endthre<lower)
				endthre=lower;
				
				if(ThreTry==3){
					maxThreTry=100;
					increment16bit=(endthre-lowestthre)/100;
					increment16bit=round(increment16bit);
					
					if(increment16bit<1)
					increment16bit=1;
					
					print("MIPstep; "+MIPstep+"   Gap thresholding; from "+lowestthre+" to "+endthre+" Gap; "+endthre-lowestthre+"  increment16bit; "+increment16bit);
				}//	if(ThreTry==3){
			}//	if(ThreTry>3){
			//		run("Median...", "radius=2");
			
			run("Minimum...", "radius=5");
			run("Maximum...", "radius=5");
			
			//		setBatchMode(false);
			//		updateDisplay();
			//		aa
			
			
			run("Analyze Particles...", "size="+round((130000*MaxZoom)*Zoomratio)+"-Infinity display clear");
			
			updateResults();
			maxsizeData=0;
			
			if(getValue("results.count")>0){
				numberResults=getValue("results.count");	 ARshape=0;
				
				for(inn=0; inn<getValue("results.count"); inn++){
					maxsize0=getResult("Area", inn);
					
					if(maxsize0>maxsizeData){
						ARshape=getResult("AR", inn);// AR value from Triangle
						Anglemax=getResult("Angle", inn);
						Circ=getResult("Circ.", inn);
						Circ=parseFloat(Circ);//Chaneg string to number
						//		print(Circ+" Circ");
						maxsizeData=maxsize0;
						
						ixcenter=getResult("X", inn);
						iycenter=getResult("Y", inn);
						
						//					print("maxsizeData; "+maxsizeData+"   ARshape; "+ARshape);
					}
				}//for(inn=0; inn<nResults; inn++){
				
				if(ABSMaxARShape<ARshape){
					ABSMaxARShape=ARshape;
					
					ABSmaxSize=maxsizeData;
					ABSmaxCirc=Circ;
				}
				
				if(maxsizeData>(130000*MaxZoom)*Zoomratio && maxsizeData<(570000*MaxZoom)*Zoomratio && ARshape>1.3){
					
					selectWindow("DUPprojection.tif");// binary mask
					
					//			setBatchMode(false);
					//					updateDisplay();
					//					aa
					
					run("Size...", "width="+round(getWidth*ZoomratioSmall)+" height="+round(getHeight*ZoomratioSmall)+" depth=1 constrain interpolation=None");
					
					run("Canvas Size...", "width=102 height=102 position=Center zero");
					
					//	setBatchMode(false);
					//	updateDisplay();
					//	aa
					
					if(bitDepth==8)
					run("16-bit");
					if(OBJScoreOri>600){
						run("Rotation Hideo", "rotate="+OriginalRot+" in=InMacro");
						rotSearch=5;
					}else
					rotSearch=55;
					
					setMinAndMax(0, 255);
					run("Apply LUT");
					run("8-bit");
					
					//					setBatchMode(false);
					//					updateDisplay();
					//					"do"
					//					exit();
					
					
					ImageCarray=newArray(0, 0, 0, 0);
					ImageCorrelation2 ("DUPprojection.tif", "JFRC2010_ShapeMatchingMask.tif", rotSearch,ImageCarray,90,NumCPU);
					
					OBJScore=ImageCarray[0];
					Rot=ImageCarray[1];
					ShiftY=ImageCarray[2];
					ShiftX=ImageCarray[3];
					
					//		print("OBJScore from Image2; "+OBJScore+"   ARshape; "+ARshape +"   Circ; "+Circ);
					
					if(OBJScore>MaxOBJScore){
						MaxOBJScore=OBJScore;
						MaxRot=Rot;
						
						//		if(MaxOBJScore>680){
						//			print("Circ; "+Circ);
						//			print("ARshape; "+ARshape);
						
						//			setBatchMode(false);
						//			updateDisplay();
						//			aa
						//		}
						
						if(ARshape>maxARshape){//&& ARshape>1.7
							if(Circ>MaxCirc-0.04){//0.16 is min
								maxARshape=ARshape;
								
								if(MaxCirc<Circ)
								MaxCirc=Circ;
								
								print("MIPstep; "+MIPstep+"   lower; "+lower+"   maxARshape; "+maxARshape+"   Circ; "+Circ+"   ThreTry; "+ThreTry+"   maxsizeData; "+maxsizeData+"  MaxOBJScore; "+MaxOBJScore);
								
								ID20xMIP=1;
								numberResults=1;
								
								elipsoidAngle = Anglemax;
								
								if (elipsoidAngle>90) 
								elipsoidAngle = -(180 - elipsoidAngle);
								
								if (MIPstep==1)
								finalMIP="Ave projection";
								
								if (MIPstep==2)
								finalMIP="Max projection";
								
								positiveAR=0; firstTime=1;
								lowerM=lower; threTry=ThreTry; angle=elipsoidAngle; SizeM=maxsizeData;
								
								xcenter=ixcenter; ycenter=iycenter;
								//		if(MIPstep==2){
								//			setBatchMode(false);
								//			updateDisplay();
								//			"do"
								//			exit();
								//		}
								
							}else{
								positiveAR=positiveAR+1;
							}
						}//	if(ARshape>maxARshape){//&& ARshape>1.7
					}
				}else{
					
					positiveAR=positiveAR+1;
				}//if(maxsizeData>250000 && maxsizeData<470000){
			}else{
				positiveAR=positiveAR+1;
				
			}//if(nResults>0){
			
			if(positiveAR>=40){
				if(firstTime==1)
				ThreTry=maxThreTry+1;
			}
			
			if(firstTime==1 && ThreTry>3)
			ThreTry=maxThreTry+1;
			
			while(isOpen(DUPprojection)){
				selectImage(DUPprojection);
				close();
			}
			while(isOpen("DUPprojection.tif")){
				selectWindow("DUPprojection.tif");
				close();
			}
			
			
			//			titlelist=getList("image.titles");
			//			for(iImage=0; iImage<titlelist.length; iImage++){
			//				print("Opened; "+titlelist[iImage]);
			//			}
			
			
			//		if(titlelist.length>channels+2){
			//				for(iImage=0; iImage<titlelist.length; iImage++){
			//					if(channels==2){
			//						if(titlelist[iImage]!=Original3D[0] && titlelist[iImage]!=Original3D[1] && titlelist[iImage]!=Original3D[2] && titlelist[iImage]!="OriginalProjection.tif"){
			//							selectWindow(titlelist[iImage]);
			//							close();
			//						print("Closed; "+titlelist[iImage]);
			//					}
			//					}//if(channels==2){
			
			//					}
			//				}//	if(titlelist.length>channels){
		}//for(ThreTry=0; ThreTry<3; ThreTry++){
		
		if(lowerM!=3 && prelower!=lowerM){
			print("MIPstep; "+MIPstep+"   lowerM; "+lowerM+"   threTry; "+threTry+"   angle; "+angle+"   SizeM; "+SizeM+"   maxARshape; "+maxARshape+"  MaxCirc; "+MaxCirc+"   ID20xMIP; "+ID20xMIP);
			prelower=lowerM;
		}
		while(isOpen(OriginalProjection)){
			selectImage(OriginalProjection);
			close();
		}
	}//for(MIPstep=1; MIPstep<3; MIPstep++){
	
	if(OBJScoreOri>600 || angle==400)// angle ==400 is initial setting, could not detect the brain in the mask process
	elipsoidAngle=OriginalRot;
	else
	elipsoidAngle=angle;
	
	ImageAligned=0;
	
	print("MaxOBJScore; "+MaxOBJScore+"   MaxRot; "+angle);
}else{//if(BrainShape=="Intact"){ // if brain is not intact
	maxY = OriginalYshift/2;
	maxX = OriginalXshift/2;
	ID20xMIP=1;
	ImageAligned=1;// this means, xy shift + rotation are already known
	finalMIP="Max projection";
	SizeM=1; 
}//	if(BrainShape=="Intact"){
if(ID20xMIP==0){
	print("could not segment by normal method");
	/// rescue code with Image correlation ////////////////////////////
	ImageCorrelationArray=newArray(nc82, ImageAligned,0,0,0,0,0);
	ImageCorrelation (ImageCorrelationArray,Ori_widthVx,NumCPU);
	ImageAligned=ImageCorrelationArray[1];
	//		maxX=ImageCorrelationArray[2];
	//		maxY=ImageCorrelationArray[3];
	//		elipsoidAngle=ImageCorrelationArray[4];
	OBJScore=ImageCorrelationArray[5];
	
	if(ImageAligned==1){// if rescued
		
		ID20xMIP=1;
		finalMIP="Max projection";
		SizeM=1; 
		MIPstep=2;
	}else{
		print("AR shape/size is too low, might be no optic lobe; ABSMaxARShape; "+ABSMaxARShape+"  ABSmaxSize; "+ABSmaxSize+"  ABSmaxCirc; "+ABSmaxCirc);
		
		maxY = OriginalYshift/2;
		maxX = OriginalXshift/2;
		
		ID20xMIP=1;
		finalMIP="Max projection";
		SizeM=1; 
		MIPstep=2;
		
		selectImage(nc82);
		run("Z Project...", "start=15 stop="+nSlices-10+" projection=[Max Intensity]");
		run("Grays");
		resetMinAndMax();
		run("8-bit");
		saveAs("PNG", ""+myDir0+noext+"_MaxAR_"+ABSMaxARShape+"_Shape.png");//save 20x MIP mask
		saveAs("PNG", ""+mask+noext+"_MaxAR_"+ABSMaxARShape+"_Shape.png");//save 20x MIP mask
		saveAs("PNG", ""+savedir+noext+"_MaxAR_Shape.png");
		close();
	}//if(ID20xMIP==0){
}//if(NRRD_02_ext==0){
logsum=getInfo("log");
File.saveString(logsum, filepath);
if(NRRD_02_ext==1 || nrrdEx==true){
	ID20xMIP=1;
	SizeM=1;
}

if(SizeM!=0){
	if(ID20xMIP!=0){// AR shape is more than 1.7
		
		if(NRRD_02_ext==0){
			
			resliceLongLength=round(sqrt(height*height+width*width));
			print("elipsoidAngle; "+elipsoidAngle);
			OpticLobeSizeGap=60000*Zoomratio; x1_opl=0; x2_opl=0; sizediff2=0; sizediff1=0; y1_opl=0;
			
			if(BrainShape=="Intact"){
				MIPstep=1;
				if(finalMIP=="Max projection")
				MIPstep=2;
				
				print("   finalMIP; "+finalMIP+"   MIPstep; "+MIPstep+"   ImageAligned; "+ImageAligned);
				
				selectImage(nc82);
				
				if(MIPstep==1)
				run("Z Project...", "start=10 stop="+nSlices-10+" projection=[Average Intensity]");// imageID is AR
				else if(MIPstep==2)
				run("Z Project...", "start=15 stop="+nSlices-10+" projection=[Max Intensity]");// imageID is AR
				
				MIP2nd=getImageID();
				NewID20xMIPgeneration=0;
				
				if(ImageAligned==0){ // brain shape is intact
					print("lowerM; final "+lowerM);
					run("8-bit");
					
					logsum=getInfo("log");
					File.saveString(logsum, filepath);
					
					setThreshold(lowerM, maxvalue0);
					setForegroundColor(255, 255, 255);
					setBackgroundColor(0, 0, 0);
					run("Make Binary", "thresholded remaining");
					
					run("Minimum...", "radius=5");// previously size was 5, 5 gives me lower thresholding value than 2, then 2 can give OL connection this time
					run("Maximum...", "radius=5");
					
					//			setBatchMode(false);
					//			updateDisplay();
					//			"do"
					//			exit();
					
					run("Select All");
					run("Copy");
					
					run("Fill Holes");
					getStatistics(area, meanHole, minHole, maxHole, stdHole, histogramHole);
					
					if(meanHole==0){
						run("Paste");
						run("Grays");
						run("Fill Holes");
					}
					
					if(meanHole==255)
					run("Paste");
					
					
					run("Analyze Particles...", "size="+(130000*MaxZoom)*Zoomratio+"-Infinity show=Masks display clear");//run("Analyze Particles...", "size=200000-Infinity show=Masks display exclude clear");
					ID20xMIP=getImageID();//このマスクを元にしてローテーション、中心座標を得る
					ID20xMIPtitle=getTitle();
					run("Grays");
					
					//			setBatchMode(false);
					//						updateDisplay();
					//						"do"
					//						exit();
					
					run("Canvas Size...", "width="+cropWidth+300+" height="+cropWidth+300+" position=Center zero");
					run("Rotate... ", "angle="+elipsoidAngle+" grid=1 interpolation=None enlarge");//Rotate mask to horizontal
					
					AFxsize=getWidth();
					AFysize=getHeight();
					
					run("Size...", "width="+AFxsize*MaxZoom*Zoomratio+" height="+AFysize*MaxZoom*Zoomratio+" constrain interpolation=None");
					run("Canvas Size...", "width="+AFxsize+" height="+AFysize+" position=Center zero");
					run("Properties...", "channels=1 slices=1 frames=1 unit=microns pixel_width=1 pixel_height=1 voxel_depth=1");
					
					print("after rotation; AFxsize; "+AFxsize+"   AFysize; "+AFysize);
					
					ScanMakeBinary ();
					
					//		setBatchMode(false);
					//			updateDisplay();
					//			"do"
					//			exit();
					
					if(getValue("results.count")==0){
						"Could not detect brain mask in line 1306";
						exit();
					}else{
						
						AnalyzeCArray=newArray(SizeM, 0, 0);
						analyzeCenter(AnalyzeCArray);
						
						xcenter=AnalyzeCArray[1];
						ycenter=AnalyzeCArray[2];
						
						xcenter=round(xcenter);
						ycenter=round(ycenter);
						
						print("CX="+xcenter);
						print("CY="+ycenter);
						
						finalshiftX=round(getWidth/2)-xcenter;
						finalshiftY=round(getHeight/2)-ycenter;
						
						xgapleft=0;
						if(xcenter<=cropWidth/2)
						xgapleft=cropWidth/2-xcenter;
						
						print("finalshiftX; "+round(finalshiftX)+"   round(maxX*20*Zoomratio); "+round(maxX*20*Zoomratio)+"  finalshiftY; "+round(finalshiftY)+"   round(maxY*20/Zoomratio); "+round(maxY*20/Zoomratio)+"maxX; "+maxX+"   maxY; "+maxY+"  Zoomratio; "+Zoomratio);
						print("1069 cropWidth; "+cropWidth+"   cropHeight; "+cropHeight+"   Zoomratio; "+Zoomratio);
						
						
						selectImage(ID20xMIP);
						selectWindow(ID20xMIPtitle);
						
						run("Translate...", "x="+finalshiftX+" y="+finalshiftY+" interpolation=None");
						run("Canvas Size...", "width="+cropWidth*Zoomratio+" height="+cropHeight*Zoomratio+" position=Center zero");
						
						//				setBatchMode(false);
						//					updateDisplay();
						//				"do"
						//				exit();
						
						run("Duplicate...", "title=DupMask2D.tif");
						DupMask=getImageID();
						
					}//if(getValue("results.count")==0){
					
					//				setBatchMode(false);
					//				updateDisplay();
					//				"do"
					//				exit();
				}//ImageAligned==0
				
				if(ImageAligned==1){// brain shape not intact
					ID20xMIP=getImageID();//Z projection.. may need threshold to be mask
					ID20xMIPtitle=getTitle();
					NewID20xMIPgeneration = 1;
					
					run("Canvas Size...", "width="+resliceLongLength+" height="+resliceLongLength+" position=Center zero");
					getVoxelSize(LVxWidth, LVxHeight, LVxDepth, LVxUnit);//reslice
					if(bitDepth==8)
					run("16-bit");
					run("Rotation Hideo", "rotate="+elipsoidAngle+" in=InMacro");
					
					finalshiftX=round(maxX*20*Zoomratio);
					finalshiftY=round(maxY*20*Zoomratio);
					
					run("Translate...", "x="+finalshiftX+" y="+finalshiftY+" interpolation=None");
					setVoxelSize(LVxWidth*MaxZoom, LVxHeight*MaxZoom, LVxDepth, LVxUnit);//reslice
					run("Canvas Size...", "width="+round(cropWidth*Zoomratio)+" height="+round(cropHeight*Zoomratio)+" position=Center zero");
					
					run("Duplicate...", "title=DupMask2D.tif");
					DupMask=getImageID();
					
					xsize=getWidth();
					ysize=getHeight();
				}//if(ImageAligned==1){
				
				
				//	setBatchMode(false);
				//	updateDisplay();
				//	"do"
				//	exit();
				
				
				//print("1404 shiftY; "+shiftY);
				ycenterCrop=round((cropHeight*Zoomratio)/2);//(cropHeight/2)-((cropHeight/2)*0.1);
				//	ycenterCrop=cropHeight/2+shiftY-30;
				
				logsum=getInfo("log");
				File.saveString(logsum, filepath);
				
				//		setBatchMode(false);
				//		updateDisplay();
				//		"do"
				//		exit();
				
				run("8-bit");
				setThreshold(1, 255);
				setForegroundColor(255, 255, 255);
				setBackgroundColor(0, 0, 0);
				run("Make Binary", "thresholded remaining");
				//// optic lobe detection //////////////////////////////////////////
				run("Watershed");// clip optic lobe out
				
				
				
				run("Analyze Particles...", "size=4000-Infinity display clear");
				
				//		setBatchMode(false);
				//		updateDisplay();
				//		"do"
				//		exit();
				
				sizeDiffOp= newArray(getValue("results.count")); sizediff1=300000; sizediff2=300000;
				minX1position=10000;
				
				xdistancearray=newArray(getValue("results.count")); ydistancearray=newArray(getValue("results.count")); AreaArray=newArray(getValue("results.count"));
				
				for(xdistance=0; xdistance<getValue("results.count"); xdistance++){// array creation for analyzed objects
					xdistancearray[xdistance]=getResult("X", xdistance);
					ydistancearray[xdistance]=getResult("Y", xdistance);
					AreaArray[xdistance]=getResult("Area", xdistance);
				}
				
				//// optic lobe detection and building OL from smaller segments ///////////////////////////////
				optic1_Xposition_sum=0; optic1_object=0; optic1_Area_sum=0; optic1_Yposition_sum=0;
				optic2_Xposition_sum=0; optic2_object=0; optic2_Area_sum=0; optic2_Yposition_sum=0;
				oticLobe2Area=0; oticLobe1Area=0; sizediff2=0; sizediff1=0;
				
				for(opticL1=0; opticL1<getValue("results.count"); opticL1++){
					
					opticlobe1Gap=abs(xdistancearray[opticL1]-((220/1200)*(cropWidth*Zoomratio)));//  300 220 is average of left optic lobe central X
					opticlobe2Gap=abs(xdistancearray[opticL1]-((950/1200)*(cropWidth*Zoomratio)));// 920 981 is average of left optic lobe central X
					
					if(opticlobe1Gap<120*Zoomratio)
					optic1_Area_sum=optic1_Area_sum+AreaArray[opticL1];
					
					
					if(opticlobe2Gap<120*Zoomratio)
					optic2_Area_sum=optic2_Area_sum+AreaArray[opticL1];
				}
				
				print("optic1_Area_sum; "+optic1_Area_sum+"  optic2_Area_sum; "+optic2_Area_sum);
				
				for(opticL=0; opticL<getValue("results.count"); opticL++){
					
					opticlobe1Gap=abs(xdistancearray[opticL]-((220/1200)*(cropWidth*Zoomratio)));//  300 220 is average of left optic lobe central X
					opticlobe2Gap=abs(xdistancearray[opticL]-((950/1200)*(cropWidth*Zoomratio)));// 920 981 is average of left optic lobe central X
					
					if(opticlobe1Gap<120*Zoomratio){
						print("opticlobe1Gap; "+opticlobe1Gap);
						
						optic1_Xposition_sum=optic1_Xposition_sum+(xdistancearray[opticL]*(AreaArray[opticL]/optic1_Area_sum));
						
						optic1_Yposition_sum=optic1_Yposition_sum+(ydistancearray[opticL]*(AreaArray[opticL]/optic1_Area_sum));
						
						
						optic1_object=optic1_object+1;
					}
					
					if(opticlobe2Gap<120*Zoomratio){
						print("opticlobe2Gap; "+opticlobe2Gap);
						optic2_Xposition_sum=optic2_Xposition_sum+(xdistancearray[opticL]*(AreaArray[opticL]/optic2_Area_sum));
						
						optic2_Yposition_sum=optic2_Yposition_sum+(ydistancearray[opticL]*(AreaArray[opticL]/optic2_Area_sum));
						
						
						optic2_object=optic2_object+1;
					}
				}//for(opticL=0; opticL<nResults; opticL++){
				
				x1_opl=optic1_Xposition_sum;
				y1_opl=optic1_Yposition_sum;
				sizediff1=abs(80000*Zoomratio-optic1_Area_sum);
				
				x2_opl=optic2_Xposition_sum;
				y2_opl=optic2_Yposition_sum;
				sizediff2=abs(80000*Zoomratio-optic2_Area_sum);
				print("getValue(results.count); "+getValue("results.count"));
				print("oticLobe1Area; "+optic1_Area_sum+"  OL1 is "+optic1_object+" peaces. "+"  oticLobe2Area; "+optic2_Area_sum+"  optic2_Area_sum; "+optic2_Area_sum+"  OL2 is "+optic2_object+" peaces. ");
				ImageAligned2=0; 
				x1_opl=round(x1_opl); x2_opl=round(x2_opl); y1_opl=round(y1_opl); y2_opl=round(y2_opl);
				
				logsum=getInfo("log");
				File.saveString(logsum, filepath);
				
				print("sizediff1; "+sizediff1+"   sizediff2; "+sizediff2+"   OpticLobeSizeGap; "+OpticLobeSizeGap);
				//		setBatchMode(false);
				//		updateDisplay();
				//		"do"
				//		exit();
				
				// if optioc lobe is not exist ///////////////////////////
				if(sizediff2>OpticLobeSizeGap || sizediff1>OpticLobeSizeGap){
					if(BrainShape=="Intact"){		
						print("Optic lobe shape / segmentation problem!!!!!!!!!");
						print("Opticlobe1 size gap; "+sizediff1+"  Opticlobe1 center X,Y; ("+x1_opl+" , "+y1_opl+") / "+ycenterCrop+"  Opticlobe2 size gap; "+sizediff2+"  Opticlobe2 center X,Y; ("+x2_opl+" , "+y2_opl+")");
						
						wait(100);
						call("java.lang.System.gc");
						ImageCorrelationArray=newArray(nc82, ImageAligned2,0,0,0,0,0);
						ImageCorrelation (ImageCorrelationArray,Ori_widthVx,NumCPU);
						ImageAligned2=ImageCorrelationArray[1];
						
						print("ImageAligned2; "+ImageAligned2);
						
						logsum=getInfo("log");
						File.saveString(logsum, filepath);
						
						maxX=ImageCorrelationArray[2];
						maxY=ImageCorrelationArray[3];
						//		elipsoidAngle=ImageCorrelationArray[4];
						ImageAligned=ImageAligned2;// obj score, if more than 0.6, will be 1
						OBJScore=ImageCorrelationArray[5];
						
						if(ImageAligned2==0){// if shape problem
							selectImage(DupMask);
							run("Grays");
							
							saveAs("PNG", ""+myDir0+noext+"_OL_Shape_MASK.png");//save 20x MIP mask
							saveAs("PNG", ""+savedir+noext+"_OL_Shape_MASK.png");
							
							selectImage(nc82);
							run("Z Project...", "start=15 stop="+nSlices-10+" projection=[Max Intensity]");// imageID is AR
							MIP2ID=getImageID();
							run("Enhance Contrast", "saturated=0.35");
							getMinAndMax(min, max);
							setMinAndMax(min, max);
							print("max; "+max);
							
							if(max!=maxvalue0 && max!=255)
							run("Apply LUT");
							
							run("8-bit");
							run("Grays");
							saveAs("PNG", ""+myDir0+noext+"_OL_Shape.png");//save 20x MIP mask
							
							while(isOpen(MIP2ID)){
								selectImage(MIP2ID);
								close();
							}
							
							y1_opl=cropHeight*2;
							y2_opl=cropHeight;
						}// if(ImageAligned2==0){// if shape problem
						//		selectImage(ID20xMIP);
						//		close();
					}
				}//if(sizediff2>50000 || sizediff1>50000){
				
				while(isOpen(DupMask)){
					selectImage(DupMask);
					close();
				}
				
				if(NewID20xMIPgeneration==0){
					while(isOpen(MIP2nd)){
						selectImage(MIP2nd);
						close();
					}
				}
				
				selectImage(ID20xMIP);
				selectWindow(ID20xMIPtitle);
				if(y1_opl!=cropHeight*2)// if no shape problem
				print("Opticlobe1 size gap; "+sizediff1+"  Opticlobe1 center X,Y; ("+x1_opl+" , "+y1_opl+") / "+ycenterCrop+"  Opticlobe2 size gap; "+sizediff2+"  Opticlobe2 center X,Y; ("+x2_opl+" , "+y2_opl+")");
				
				logsum=getInfo("log");
				File.saveString(logsum, filepath);
				
				//	setBatchMode(false);
				//			updateDisplay();
				//			"do"
				//			exit();
				
				wait(100);
				call("java.lang.System.gc");
				
				/// if brain is upside down /////////////////////////////
				xcenter2=xcenter;
				if(y1_opl<ycenterCrop && y2_opl<ycenterCrop && ImageAligned==0){// if optic lobe is higer position, upside down
					if(bitDepth==8)
					run("16-bit");
					run("Rotation Hideo", "rotate=180 in=InMacro");
					print(" 180 rotated");
					
					rotationYN="Yes";
					
					//	run("Translate...", "x="+round(maxX*20/Zoomratio)+" y="+round(maxY*20/Zoomratio)+" interpolation=None");
					
					orizoomratio=Zoomratio;
					if(shrinkTo2010==false)
					Zoomratio=1;
					
					run("Canvas Size...", "width="+round(cropWidth*Zoomratio)+" height="+round(cropHeight*Zoomratio)+" position=Center zero");
					
					Zoomratio=orizoomratio;
				}//if(y1_opl<ycenterCrop && y2_opl<ycenterCrop){// if optic lobe is higer position, upside down
				
				
				if(y1_opl!=cropHeight*2){// if no shape problem
					OBJV="";
					if(ImageAligned2==1){
						
						rotateshift3D (resliceLongLength,finalshiftX,Zoomratio,finalshiftY,elipsoidAngle,shrinkTo2010,cropWidth,cropHeight,Ori_widthVx,Ori_heightVx,depth);
						
						OBJV="_"+OBJScore;
					}
					
					path20xmask=mask+noext;
					
					resetMinAndMax();
					run("8-bit");
					print("8bit");
					
					setThreshold(1, 255);
					setForegroundColor(255, 255, 255);
					setBackgroundColor(0, 0, 0);
					run("Make Binary", "thresholded remaining");
					
					run("Watershed");
					run("Properties...", "channels=1 slices="+nSlices+" frames=1 unit=microns pixel_width="+widthVx+" pixel_height="+heightVx+" voxel_depth="+depth+"");
					
					run("Grays");
					saveAs("PNG", ""+path20xmask+OBJV+".png");//save 20x MIP mask
					
				}
				selectImage(ID20xMIP);
				//		selectWindow(ID20xMIPtitle);
				close();// MIP
				//		setBatchMode(false);
				
				logsum=getInfo("log");
				File.saveString(logsum, filepath);
				
				selectImage(nc82);
				wait(100);
				call("java.lang.System.gc");
			}
			
			print("1292");
			//	setBatchMode(false);
			//	updateDisplay();
			//	"do"
			//	exit();
			
			selectImage(nc82);
			print("nc82 selected 1837; "+getTitle());
			
			rotateshift3D (resliceLongLength,finalshiftX,Zoomratio,finalshiftY,elipsoidAngle,shrinkTo2010,cropWidth,cropHeight,Ori_widthVx,Ori_heightVx,depth);
			
			if(ImageAligned==1){
				sizediff2=OpticLobeSizeGap; sizediff1=OpticLobeSizeGap;
			}
			
			resetBrightness(maxvalue0);				
			
			print("nImages 1801; "+nImages);
		}//if(NRRD_02_ext==0){
		if(ChannelInfo=="01 02 nrrd files" || ChannelInfo=="Both formats"){
			
			
			logsum=getInfo("log");
			File.saveString(logsum, filepath);
			
			selectImage(nc82);
			lateralArray=newArray(0, 0,0,0,0,0);
			lateralDepthAdjustment(x1_opl,x2_opl,lateralArray,nc82,templateBr,NumCPU,shrinkTo2010,objective);
			incredepth=lateralArray[0];
			nc82=lateralArray[1];
			maxrotation=lateralArray[2];
			LateralXtrans=lateralArray[3];
			LateralYtrans=lateralArray[4];
			OBJL=lateralArray[5];
			
			LateralYtrans=round(LateralYtrans);
			
			if(widthVx==1 || ForceUSE==true){
				heightVx=DesireX;
				widthVx=DesireX;
				print("Voxel size changed from 1 to "+widthVx);
			}
			
			if(OBJL<500){
				if(templateBr=="JFRC2010" || templateBr=="JFRC2013"){
					incredepth=218/NC82SliceNum;//ADJUSTING sample depth size to template , z=1 micron template
					
					if(TwentyMore!=0)
					incredepth=incredepth*(1+TwentyMore/100);
					print("TwentyMore; "+TwentyMore+"   1+TwentyMore/100; "+1+TwentyMore/100);
					
				}else if(templateBr=="JFRC2014" || templateBr=="JRC2018"){
					
					if(depth!=1){
						tempthinkness=151;
						sampthickness=depth*NC82SliceNum;
						
						incredepth=tempthinkness/sampthickness;//ADJUSTING sample depth size to template 
					}else
					incredepth=(218/NC82SliceNum)*0.69;
					
				}//	if(templateBr=="JFRC2010"){
			}else{//if(OBJL>500){
				
				if(TwentyMore!=0){
					print("TwentyMore; "+TwentyMore+"   1+TwentyMore/100; "+1+TwentyMore/100);
					incredepth=incredepth*(1+TwentyMore/100);
					
				}
			}
			
			String.resetBuffer;
			n3 = lengthOf(noext);
			for (si=0; si<n3; si++) {
				c = charCodeAt(noext, si);
				if(c==32){// if there is a space
					print("There is a space, replaced to _.");
					c=95;
				}
				if (c>=32 && c<=127)
				String.append(fromCharCode(c));
				
				noext3 = String.buffer;
			}//	for (si=0; si<n3; si++) {
			noext=noext3;
			String.resetBuffer;
			
			
			if(NRRD_02_ext==0){
				
				while(isOpen("nc82.tif")){
					selectWindow("nc82.tif");
					close();
				}
				
				wait(100);
				call("java.lang.System.gc");
				
				selectWindow("nc82_Ori.tif");
				run("Properties...", "channels=1 slices="+NC82SliceNum+" frames=1 unit=microns pixel_width="+Ori_widthVx+" pixel_height="+Ori_heightVx+" voxel_depth="+incredepth+"");
				
				//	setBatchMode(false);
				//					updateDisplay();
				//					"do"
				//					exit();
				
				
				if(shrinkTo2010==true){
					VoxSizeADJArray=newArray(Ori_widthVx,Ori_heightVx,incredepth);
					VoxSizeADJ(VoxSizeADJArray,DesireX,objective);
				}
				
				nc82=getImageID();
				
				rotateshift3D (resliceLongLength,finalshiftX,Zoomratio,finalshiftY,elipsoidAngle,shrinkTo2010,cropWidth,cropHeight,Ori_widthVx,Ori_heightVx,incredepth);
				
				run("Properties...", "channels=1 slices="+NC82SliceNum+" frames=1 unit=microns pixel_width=1 pixel_height=1 voxel_depth=1");
				run("Reslice [/]...", "output=1.000 start=Left rotate avoid");
				rename("resliceN.tif");
				print("Reslice nc82 Done 1967");
				if(bitDepth==8)
				run("16-bit");
				
				run("Rotation Hideo", "rotate="+maxrotation+" 3d in=InMacro");
				//		run("Translate...", "x=0 y="+LateralYtrans+" interpolation=None stack");
				//		print("nc82 Lateral Trans Y; "+LateralYtrans);
				
				run("Reslice [/]...", "output=1 start=Left rotate avoid");
				rename("RealSignal.tif");
				RealSignal=getImageID();
				
				while(isOpen("resliceN.tif")){
					selectWindow("resliceN.tif");
					close();
				}
				
				while(isOpen("nc82_Ori.tif")){
					selectWindow("nc82_Ori.tif");
					close();
				}
				
				wait(100);
				call("java.lang.System.gc");
				
				selectWindow("RealSignal.tif");
				
				print("After reslice; width; "+getWidth()+"   height; "+getHeight()+"   nSlices; "+nSlices);
				
				//			if(nrrdindex!=-1){////???
				//				if(nSlices()!=NC82SliceNum){
				//					slicegapNrrd=NC82SliceNum-nSlices();
				//					print("Slice number Gap; "+slicegapNrrd+"   NC82SliceNum; "+NC82SliceNum);
				//					for(igap=0; igap<slicegapNrrd; igap++){
				//						setSlice(nSlices);
				//						run("Add Slice");
				//					}
				//				}
				//			}
				
				run("Gamma ", "gamma=1.60 3d in=InMacro cpu="+NumCPU+"");
				nc82=getImageID();
				rename("nc82.tif");
				
				
				if(isOpen("RealSignal.tif")){
					selectWindow("RealSignal.tif");
					close();
				}
				
				wait(100);
				call("java.lang.System.gc");
				
				selectWindow("nc82.tif");
				
				if(BrainShape=="Intact"){
					if(y1_opl<ycenterCrop && y2_opl<ycenterCrop && ImageAligned==0){// if optic lobe is higer position, upside down
						if(bitDepth==8)
						run("16-bit");
						run("Rotation Hideo", "rotate=180 3d in=InMacro");
						print(" 180 rotated nc82 signal");
					}
				}//if(BrainShape=="Intact"){
				
				if(shrinkTo2010==false)
				run("Properties...", "channels=1 slices="+NC82SliceNum+" frames=1 unit=microns pixel_width="+Ori_widthVx+" pixel_height="+Ori_heightVx+" voxel_depth="+incredepth+"");
				else
				run("Properties...", "channels=1 slices="+NC82SliceNum+" frames=1 unit=microns pixel_width="+widthVx+" pixel_height="+heightVx+" voxel_depth="+incredepth+"");
				
				if(sizediff2>OpticLobeSizeGap || sizediff1>OpticLobeSizeGap || y1_opl==cropHeight*2)
				run("Nrrd Writer", "compressed nrrd="+myDir0+noext+"_01.nrrd");
				else
				run("Nrrd Writer", "compressed nrrd="+savedir+noext+"_01.nrrd");
				
				run("Z Project...", "start=15 stop="+nSlices-10+" projection=[Max Intensity]");
				run("Grays");
				run("8-bit");
				rename("nc82Max.jpg");
				
				if(ImageAligned==1)
				saveAs("JPEG", ""+savedir+noext+"_obj"+OBJScore+".jpg");//save 20x MIP
				else
				saveAs("JPEG", ""+savedir+noext+".jpg");//save 20x MIP
				
				close();
				
				while(isOpen("nc82Max.jpg")){
					selectWindow("nc82Max.jpg");
					close();
				}
			}//if(NRRD_02_ext==0){
			
			selectImage(nc82);
			if(ChannelInfo!="Both formats"){
				close();
				while(isOpen("nc82.tif")){
					selectWindow("nc82.tif");
					close();
				}
			}
			
			wait(100);
			call("java.lang.System.gc");
			
			print("");
			titlelist=getList("image.titles");
			for(iImage=0; iImage<titlelist.length; iImage++){
				print("Opened; "+titlelist[iImage]);
			}
			
			if(NRRD_02_ext==0){
				startNeuronNum=1;
				AdjustingNum=-1;
				
				if(MCFOYN==false)
				maxvalue1=newArray(channels);
				else
				maxvalue1=newArray(5);
				
			}else if (channels>1){
				startNeuronNum=2;
				AdjustingNum=-1;
			}else if (channels==1){
				startNeuronNum=0;
				AdjustingNum=0;
			}
			
			Neuron_SepEXT = File.exists(PathConsolidatedLabel);
			if(Neuron_SepEXT==1){
				print("Neuron separator result existing; ");
				AdjustingNum=AdjustingNum+1;
			}
			
			print("nImages 1939; "+nImages+"   startNeuronNum; "+startNeuronNum+"   AdjustingNum; "+AdjustingNum+"  channels; "+channels);
			
			for(neuronNum=startNeuronNum; neuronNum<channels+startNeuronNum+AdjustingNum; neuronNum++){
				if(neuronNum==startNeuronNum){
					selectImage(neuron);
				}else if (neuronNum==startNeuronNum+1){
					if(isOpen(neuron2)){
						selectImage(neuron2);
					}else if(Neuron_SepEXT==1){
						open(PathConsolidatedLabel);
						run("Flip Vertically", "stack");
						
						if(nSlices!=NC82SliceNum){
							print("Neuron separator result has different slice number; "+nSlices+"  nc82; "+NC82SliceNum);
							
							logsum=getInfo("log");
							File.saveString(logsum, filepath);
							run("Quit");
						}
					}else
					break;
					
				}else if (neuronNum==startNeuronNum+2){
					
					if(isOpen(neuron3)){
						selectImage(neuron3);
					}else if(Neuron_SepEXT==1){
						open(PathConsolidatedLabel);
						run("Flip Vertically", "stack");
						
						if(nSlices!=NC82SliceNum){
							print("Neuron separator result has different slice number; "+nSlices+"  nc82; "+NC82SliceNum);
							
							logsum=getInfo("log");
							File.saveString(logsum, filepath);
							run("Quit");
						}
					}else
					break;
					
				}else if (neuronNum==startNeuronNum+3){
					open(PathConsolidatedLabel);
					run("Flip Vertically", "stack");
					
					if(nSlices!=NC82SliceNum){
						print("Neuron separator result has different slice number; "+nSlices+"  nc82; "+NC82SliceNum);
						
						logsum=getInfo("log");
						File.saveString(logsum, filepath);
						run("Quit");
					}
				}
				
				run("Properties...", "channels=1 slices="+NC82SliceNum+" frames=1 unit=microns pixel_width="+Ori_widthVx+" pixel_height="+Ori_heightVx+" voxel_depth="+incredepth+"");
				//	getVoxelSize(widthVx, heightVx, depth, unit);
				
				if(shrinkTo2010==true){
					VoxSizeADJArray=newArray(Ori_widthVx,Ori_heightVx,incredepth);
					VoxSizeADJ(VoxSizeADJArray,DesireX,objective);
				}
				
				if(neuronNum==startNeuronNum)
				neuron = getImageID();
				else if (neuronNum==startNeuronNum+1)
				neuron2 = getImageID();
				else if (neuronNum==startNeuronNum+2)
				neuron3 = getImageID();
				
				rotateshift3D (resliceLongLength,finalshiftX,Zoomratio,finalshiftY,elipsoidAngle,shrinkTo2010,cropWidth,cropHeight,Ori_widthVx,Ori_heightVx,incredepth);			
				
				rename("signalCH.tif");
				signalCH=getImageID();
				
				logsum=getInfo("log");
				File.saveString(logsum, filepath);
				
				run("Properties...", "channels=1 slices="+NC82SliceNum+" frames=1 unit=microns pixel_width=1 pixel_height=1 voxel_depth=1");
				run("Reslice [/]...", "output=1.000 start=Left rotate avoid");
				rename("resliceN.tif");
				print("Reslice Done 1568");
				if(bitDepth==8)
				run("16-bit");
				
				run("Rotation Hideo", "rotate="+maxrotation+" 3d in=InMacro");
				//		run("Translate...", "x=0 y="+LateralYtrans+" interpolation=None stack");
				//		print("signal Lateral Trans Y; "+LateralYtrans);
				
				run("Reslice [/]...", "output=1 start=Left rotate avoid");
				rename("RealSignal.tif");
				RealSignal=getImageID();
				
				print("Neuron reslice & rotated; "+neuronNum);
				
				if(BrainShape=="Intact"){
					if(y1_opl<ycenterCrop && y2_opl<ycenterCrop && ImageAligned==0){// if optic lobe is higer position, upside down
						if(bitDepth==8)
						run("16-bit");
						run("Rotation Hideo", "rotate=180 3d in=InMacro");
						print(" 180 rotated neuron signal "+neuronNum);
					}
				}//if(BrainShape=="Intact"){
				
				if(shrinkTo2010==false)
				run("Properties...", "channels=1 slices="+NC82SliceNum+" frames=1 unit=microns pixel_width="+Ori_widthVx+" pixel_height="+Ori_heightVx+" voxel_depth="+incredepth+"");
				else
				run("Properties...", "channels=1 slices="+NC82SliceNum+" frames=1 unit=microns pixel_width="+widthVx+" pixel_height="+heightVx+" voxel_depth="+incredepth+"");
				
				if(Nrrdnumber==0){
					
					if (neuronNum<4){
						if(sizediff2>OpticLobeSizeGap || sizediff1>OpticLobeSizeGap|| y1_opl==cropHeight*2)
						run("Nrrd Writer", "compressed nrrd="+myDir0+noext+"_0"+neuronNum+1+".nrrd");
						else
						run("Nrrd Writer", "compressed nrrd="+savedir+noext+"_0"+neuronNum+1+".nrrd");
					}
					if (neuronNum==4){
						run("Nrrd Writer", "compressed nrrd="+savedir+"GLOBAL_ConsolidatedLabel.nrrd");					
					}
				}else
				run("Nrrd Writer", "compressed nrrd="+savedir+noext+"_0"+neuronNum+".nrrd");					
				
				
				if(ChannelInfo!="Both formats"){
					close();//RealSignal
					while(isOpen("RealSignal.tif")){
						selectWindow("RealSignal.tif");
						close();
					}
				}
				
				
				while(isOpen("signalCH.tif")){
					selectWindow("signalCH.tif");
					close();
				}
				
				while(isOpen("resliceN.tif")){
					selectWindow("resliceN.tif");
					close();
				}
				if(isOpen("RealSignal.tif"))
				selectWindow("RealSignal.tif");
				
			}//for(neuronNum=1; neuronNum<channels; neuronNum++){
			
			if(ChannelInfo=="Both formats"){
				selectImage(nc82);
				run("Half purple");
				rename("nc82.tif");
				
				selectImage(neuron);
				rename("neuron.tif");
				
				if(channels==3){
					selectImage(neuron2);
					rename("neuron2.tif");
				}
				if(channels==4){
					selectImage(neuron3);
					rename("neuron3.tif");
				}
				
				MergeCH(channels,bitDepth,maxvalue0);
				
				if(sizediff2>OpticLobeSizeGap || sizediff1>OpticLobeSizeGap || y1_opl==cropHeight*2)
				saveAs("ZIP", ""+myDir0+noext+".zip");
				else
				saveAs("ZIP", ""+savedir+noext+".zip");
				close();
			}//	if(ChannelInfo=="Both formats"){
		}//	if(ChannelInfo=="01 02 nrrd files"){
		
		if(ChannelInfo=="multi-colors, single file .tif.zip"){
			selectImage(nc82);
			run("Half purple");
			rename("nc82.tif");
			
			for(neuronNum=1; neuronNum<channels; neuronNum++){
				if(neuronNum==1)
				selectImage(neuron);
				else if (neuronNum==2)
				selectImage(neuron2);
				else if (neuronNum==3)
				selectImage(neuron3);
				
				if(ImageAligned==0){
					run("Canvas Size...", "width="+cropWidth+300+" height="+cropWidth+300+" position=Center zero");
					if(bitDepth==8)
					run("16-bit");
					run("Rotation Hideo", "rotate="+elipsoidAngle+" 3d in=InMacro");
					//	run("Rotate... ", "angle="+elipsoidAngle+" grid=0 interpolation=None enlarge stack");//Rotate mask to horizontal
					canvasenlarge(xcenter,cropWidth);
					
					if(rotationYN=="Yes"){
						run("Rotation Hideo", "rotate=180 3d in=InMacro");
						//			run("Rotate... ", "angle=180 grid=1 interpolation=None stack");//Rotate mask to 180 degree
						canvasenlarge(xcenter2,cropWidth);
					}
					makeRectangle(round(xcenter2+xgapleft-(cropWidth/2)*Zoomratio), round(ycenter-(cropHeight/2)*Zoomratio-shiftY), round(cropWidth*Zoomratio), round(cropHeight*Zoomratio));//cropping brain
					run("Crop");
				}else{
					run("Canvas Size...", "width="+resliceLongLength+" height="+resliceLongLength+" position=Center zero");
					getVoxelSize(LVxWidth, LVxHeight, LVxDepth, LVxUnit);//reslice
					print("Translated X; "x="+finalshiftX+" y="+finalshiftY+", nc82," elipsoidAngle; "+elipsoidAngle);
					if(bitDepth==8)
					run("16-bit");
					run("Rotation Hideo", "rotate="+elipsoidAngle+" 3d in=InMacro");
					
					run("Translate...", "x="+finalshiftX+" y="+finalshiftY+" interpolation=None stack");
					
					setVoxelSize(LVxWidth*MaxZoom, LVxHeight*MaxZoom, LVxDepth, LVxUnit);//reslice
					run("Canvas Size...", "width="+round(cropWidth*Zoomratio)+" height="+round(cropHeight*Zoomratio)+" position=Center zero");
				}
				
				logsum=getInfo("log");
				File.saveString(logsum, filepath);
				
				if(bitDepth==16){
					if(neuronNum==1)
					maxvalue1=newArray(channels);
					
					realresetArray=newArray(maxvalue1,0);
					RealReset(realresetArray);
					maxvalue1[neuronNum-1]=realresetArray[0];
				}
				
				if(neuronNum==1)
				rename("neuron.tif");
				else if (neuronNum==2)
				rename("neuron2.tif");
				else if (neuronNum==3)
				rename("neuron3.tif");
			}
			
			MergeCH(channels,bitDepth,maxvalue0);
			
			setVoxelSize(widthVx, heightVx, depth*incredepth, unit);
			rename(noext+".tif");
			
			if(sizediff2>OpticLobeSizeGap || sizediff1>OpticLobeSizeGap || y1_opl==cropHeight*2)
			saveAs("ZIP", ""+myDir0+noext+".zip");
			else
			saveAs("ZIP", ""+savedir+noext+".zip");
		}//if(ChannelInfo=="multi-colors, single file .tif.zip"){
	}//if(ID20xMIP!=0){
	
}else{//if(maxsizeData!=0){
	
	selectImage(nc82);
	run("Z Project...", "start=15 stop="+nSlices-10+" projection=[Max Intensity]");// imageID is AR
	MIP2ID=getImageID();
	run("Enhance Contrast", "saturated=0.35");
	getMinAndMax(min, max);
	setMinAndMax(min, max);
	print("max; "+max);
	
	if(max!=maxvalue0 && max!=255)
	run("Apply LUT");
	
	run("8-bit");
	run("Grays");
	saveAs("PNG", ""+myDir0+noext+"_OL_Shape.png");//save 20x MIP mask
	saveAs("PNG", ""+savedir+noext+"_OL_Shape_MASK.png");
}

run("Close All");

List.clear();
"Done"

enda=getTime();
gaptime=(enda-starta)/1000;

print("processing time; "+gaptime/60+" min");

logsum=getInfo("log");
File.saveString(logsum, filepath);

run("Quit");

function TwoDfillHole (){// accept binary
	run("Select All");
	run("Copy");
	
	run("Fill Holes");
	
	for(ix=0; ix<getWidth; ix++){
		if(getPixel(ix, 0)!=0){
			posiSum=posiSum+1;
		}
	}
	
	if(posiSum>(getWidth/2)){
		run("Paste");
		run("Invert LUT");
		run("RGB Color");
		run("8-bit");
		
		run("Fill Holes");
	}
	
}

function ScanMakeBinary (){
	
	run("Select All");
	run("Copy");
	
	setThreshold(1, 255);
	setForegroundColor(255, 255, 255);
	setBackgroundColor(0, 0, 0);
	run("Make Binary", "thresholded remaining");
	
	posiSum=0;
	for(ix=0; ix<getWidth; ix++){
		if(getPixel(ix, 0)!=0){
			posiSum=posiSum+1;
		}
	}
	
	if(posiSum>(getWidth*0.4)){
		run("Paste");
		run("Grays");
		setThreshold(1, 255);
		setForegroundColor(255, 255, 255);
		setBackgroundColor(0, 0, 0);
		run("Make Binary", "thresholded remaining");
	}
	posiSum2=0;
	for(ix2=0; ix2<getWidth; ix2++){
		if(getPixel(ix2, 0)!=0){
			posiSum2=posiSum2+1;
		}
	}
	if(posiSum2>(getWidth/2)){
		run("Paste");
		setThreshold(1, 255);
		setForegroundColor(255, 255, 255);
		setBackgroundColor(0, 0, 0);
		run("Make Binary", "thresholded remaining");
		
		run("Invert LUT");
		run("RGB Color");
		run("8-bit");
	}
}

function fileOpen(FilePathArray){
	FilePath=FilePathArray[0];
	MIPname=FilePathArray[1];
	
	//	print(MIPname+"; "+FilePath);
	if(isOpen(MIPname)){
		selectWindow(MIPname);
		tempMask=getDirectory("image");
		FilePath=tempMask+MIPname;
	}else{
		if(FilePath==0){
			
			FilePath=getDirectory("plugins")+MIPname;
			
			tempmaskEXI=File.exists(FilePath);
			if(tempmaskEXI!=1)
			FilePath=getDirectory("plugins")+"Brain_Aligner_Plugins"+File.separator+MIPname;
			
			tempmaskEXI=File.exists(FilePath);
			
			if(tempmaskEXI==1){
				open(FilePath);
			}else{
				print("no file ; "+FilePath);
			}
		}else{
			tempmaskEXI=File.exists(FilePath);
			if(tempmaskEXI==1)
			open(FilePath);
			else{
				print("no file ; "+FilePath);
			}
		}
	}//if(isOpen("JFRC2013_63x_Tanya.nrrd")){
	
	FilePathArray[0]=FilePath;
}

function VoxSizeADJ (VoxSizeADJArray,DesireX,objective){
	
	widthVx = VoxSizeADJArray[0];
	heightVx = VoxSizeADJArray[1];
	depthVox = VoxSizeADJArray[2];
	
	if(widthVx!=1 && heightVx!=1){
		getDimensions(Oriwidth, Oriheight, channels, slices, frames);
		
		if(objective!="40x")
		changeratio=widthVx/0.5189;
		else
		changeratio=1.1;
		
		print("objective; "+objective+"  Oriwidth; "+Oriwidth+"   changeratio; "+changeratio+"  Oriwidth*changeratio; "+Oriwidth*changeratio+"   Oriheight*changeratio; "+Oriheight*changeratio);
		if(changeratio!=1){
			run("Size...", "width="+round(Oriwidth*changeratio)+" height="+round(Oriheight*changeratio)+" depth="+nSlices+" constrain interpolation=None");
			run("Canvas Size...", "width="+Oriwidth+" height="+Oriheight+" position=Center zero");
			print("VoxelResized; originally "+widthVx+" to 0.5189161   changeratio; "+changeratio);
			getVoxelSize(widthVx, heightVx, depth, unit);	
		}
		
	}else{//if(widthVx!=1 && heightVx!=1){
		run("Properties...", "channels=1 slices="+nSlices+" frames=1 unit=microns pixel_width="+DesireX+" pixel_height="+DesireX+" voxel_depth="+DesireX+"");
		getVoxelSize(widthVx, heightVx, depth, unit);	
	}
	
	run("Properties...", "channels=1 slices="+nSlices+" frames=1 unit=microns pixel_width=1 pixel_height=1 voxel_depth=1");
	
	VoxSizeADJArray[0] = widthVx;
	VoxSizeADJArray[1] = heightVx;
	VoxSizeADJArray[2] = depthVox;
}//function VoxSizeADJ (VoxSizeADJArray){


function ImageCorrelation(ImageCorrelationArray,widthVx,NumCPU){
	nc82=ImageCorrelationArray[0];
	ImageAligned=ImageCorrelationArray[1];
	
	selectImage(nc82);
	run("Z Project...", "start=15 stop="+nSlices-10+" projection=[Max Intensity]");
	run("Grays");
	rename("SampMIP.tif");
	//	run("Enhance Local Contrast (CLAHE)", "blocksize=127 histogram=4095 maximum=5 mask=*None* fast_(less_accurate)");
	
	newImage("Mask", "8-bit white", getWidth, getHeight, 1);
	run("Mask Median Subtraction", "mask=Mask data=SampMIP.tif %=90 histogram=100");
	selectWindow("Mask");
	close();
	
	Zoomratio=widthVx/0.62;
	print("1798 Zoomratio; "+Zoomratio+"   widthVx; "+widthVx);
	selectWindow("SampMIP.tif");
	run("Size...", "width="+round((getWidth/20)*Zoomratio)+" height="+round((getHeight/20)*Zoomratio)+" depth=1 constrain interpolation=None");
	run("Canvas Size...", "width=60 height=60 position=Center zero");
	
	//	setBatchMode(false);
	//		updateDisplay();
	//			"do"
	//		exit();
	
	run("Image Correlation Atomic", "samp=SampMIP.tif temp=JFRC2010_50pxMIP.tif +=179 -=180 overlap=80 parallel="+NumCPU+" rotation=1 result calculation=[OBJ peasonCoeff] weight=[Equal weight (temp and sample)]");
	
	OBJ=getResult("OBJ score", 0);
	OBJScore=parseFloat(OBJ);
	
	Rot=getResult("rotation", 0);
	Rot=parseFloat(Rot);
	elipsoidAngle=parseFloat(Rot);
	if (elipsoidAngle>90) 
	elipsoidAngle = -(180 - elipsoidAngle);
	
	ShiftY=getResult("shifty", 0);
	maxY=parseFloat(ShiftY);
	
	ShiftX=getResult("shiftx", 0);
	maxX=parseFloat(ShiftX);
	print("initial objectscore; "+OBJScore);
	OBJScore=round(OBJScore);
	MaxZoom=1;
	MaxinSlice=0;
	if(OBJScore<630){
		selectImage(nc82);
		run("Duplicate...", "title=Samp.tif, duplicate");
		run("16-bit");
		rename("Samp.tif");
		
		run("Size...", "width="+round((getWidth/20)*Zoomratio)+" height="+round((getHeight/20)*Zoomratio)+" depth="+round(nSlices/2)+" constrain interpolation=None");
		run("Canvas Size...", "width=60 height=60 position=Center zero");
		
		//		setBatchMode(false);
		//		updateDisplay();
		//		"do"
		//		exit();
		
		MaxOBJ3Dscan=0;
		print("resizd nSlices; "+nSlices);
		for(inSlice=6; inSlice<nSlices-10; inSlice++){
			selectWindow("Samp.tif");
			setSlice(inSlice);
			run("Duplicate...", "title=SingleSamp.tif");
			
			run("Image Correlation Atomic", "samp=SingleSamp.tif temp=JFRC2010_50pxSlice.tif +=55 -=55 overlap=90 parallel="+NumCPU+" rotation=1 result calculation=[OBJ peasonCoeff] weight=[Equal weight (temp and sample)]");
			
			OBJ=getResult("OBJ score", 0);
			OBJScore=parseFloat(OBJ);
			
			selectWindow("SingleSamp.tif");
			close();
			
			if(OBJScore>MaxOBJ3Dscan){
				
				MaxinSlice=inSlice;
				MaxOBJ3Dscan=OBJScore;
				Rot=getResult("rotation", 0);
				Rot=parseFloat(Rot);
				elipsoidAngle=parseFloat(Rot);
				if (elipsoidAngle>90) 
				elipsoidAngle = -(180 - elipsoidAngle);
				
				ShiftY=getResult("shifty", 0);
				maxY=parseFloat(ShiftY);
				
				ShiftX=getResult("shiftx", 0);
				maxX=parseFloat(ShiftX);
			}
		}
		print("MaxinSlice; "+MaxinSlice+"   MaxOBJ3Dscan; "+MaxOBJ3Dscan+"  elipsoidAngle; "+elipsoidAngle);
		OBJScore=MaxOBJ3Dscan;
		selectWindow("Samp.tif");
		close();
		
		if(OBJScore<630){
			print("2D Zoom adjustment, due to low obj score; <630");
			PreMaxOBJ=OBJScore; PreOBJ=OBJScore;
			for(iZoom=0.85; iZoom<1.4; iZoom+=0.05){
				selectWindow("SampMIP.tif");
				run("Duplicate...", "title=ZOOM.tif");
				run("Size...", "width="+round(getWidth*iZoom)+" height="+round(getHeight*iZoom)+" depth=1 constrain interpolation=None");
				run("Canvas Size...", "width=60 height=60 position=Center zero");
				
				run("Image Correlation Atomic", "samp=ZOOM.tif temp=JFRC2010_50pxMIP.tif +=180 -=179 overlap=70 parallel="+NumCPU+" rotation=1 result calculation=[OBJ peasonCoeff] weight=[Equal weight (temp and sample)]");
				
				OBJ=getResult("OBJ score", 0);
				OBJScore=parseFloat(OBJ);
				
				print("iZoom; "+iZoom+"   OBJScore; "+OBJScore);
				
				if(OBJScore>PreMaxOBJ){
					PreMaxOBJ=OBJScore;
					Rot=getResult("rotation", 0);
					Rot=parseFloat(Rot);
					elipsoidAngle=parseFloat(Rot);
					if (elipsoidAngle>90) 
					elipsoidAngle = -(180 - elipsoidAngle);
					
					ShiftY=getResult("shifty", 0);
					maxY=parseFloat(ShiftY);
					
					ShiftX=getResult("shiftx", 0);
					maxX=parseFloat(ShiftX);
					
					MaxZoom=iZoom;
				}
				selectWindow("ZOOM.tif");
				close();
			}
			print("PreOBJ; "+PreOBJ+" NewOBJ; "+PreMaxOBJ+"   elipsoidAngle; "+elipsoidAngle+"   maxY; "+maxY+"   maxX; "+maxX+"   MaxZoom; "+MaxZoom);
			OBJScore=PreMaxOBJ;
		}
		
	}
	
	//setBatchMode(false);
	//updateDisplay();
	//"do"
	//exit();
	
	
	
	while(isOpen("SampMIP.tif")){
		selectWindow("SampMIP.tif");
		close();
	}
	
	if(OBJScore>600){
		ImageAligned=1;
		print("OBJScore; "+OBJScore);
	}
	
	ImageCorrelationArray[1]=ImageAligned;
	ImageCorrelationArray[2]=maxX;
	ImageCorrelationArray[3]=maxY;
	ImageCorrelationArray[4]=elipsoidAngle;
	ImageCorrelationArray[5]=OBJScore;
	ImageCorrelationArray[6]=MaxZoom;
}

function MergeCH(channels,bitDepth,maxvalue0){
	if(channels==3)
	run("Merge Channels...", "c1=nc82.tif c2=neuron.tif c3=neuron2.tif create");
	else if (channels==2)
	run("Merge Channels...", "c1=nc82.tif c2=neuron.tif create");
	else if (channels==4)
	run("Merge Channels...", "c1=nc82.tif c2=neuron.tif c3=neuron2.tif c4=neuron3.tif create");
	
	run("Make Composite");
	
	if(bitDepth==16){
		resetMax(maxvalue0);
		run("Next Slice [>]");
		setMinAndMax(0, maxvalue1[0]);
		
		if(channels==3){
			run("Next Slice [>]");
			setMinAndMax(0, maxvalue1[1]);
		}
		if(channels==4){
			run("Next Slice [>]");
			setMinAndMax(0, maxvalue1[2]);
		}
	}
}

function RealReset(realresetArray){
	run("Max value");
	logsum=getInfo("log");
	endlog=lengthOf(logsum);
	maxposition=lastIndexOf(logsum, "Maxvalue;");
	
	maxvalue1=substring(logsum, maxposition+10, endlog);
	maxvalue1=round(maxvalue1);
	setMinAndMax(0, maxvalue1);
	
	realresetArray[0]=maxvalue1;
}

function resetMax(maxvalue0){
	if(maxvalue0<4096)
	call("ij.ImagePlus.setDefault16bitRange", 12);
	else
	call("ij.ImagePlus.setDefault16bitRange", 16);
}

function canvasenlarge(xcenter,cropWidth){
	xsize3=getWidth();
	ysize3=getHeight();
	done=0;
	if(xcenter<=cropWidth/2){
		run("Canvas Size...", "width="+xsize3+cropWidth/2-xcenter+" height="+ysize3+" position=Top-Right zero");
		done=1;
	}
	xsize3=getWidth();
	if ((xsize3-xcenter)<=cropWidth/2 && xcenter>=cropWidth/2)
	run("Canvas Size...", "width="+cropWidth/2-(xsize3-xcenter)+xsize3+" height="+ysize3+" position=Top-Left zero");
	
	if(xcenter<cropWidth/2 && xsize3<=cropWidth && done==0)
	run("Canvas Size...", "width="+cropWidth+" height="+ysize3+" position=Top-Right zero");
	
	//	setBatchMode(false);
	//	updateDisplay();
	//	aa
}

function analyzeCenter(AnalyzeCArray){
	run("Analyze Particles...", "size="+AnalyzeCArray[0]/2+"-Infinity display clear");
	
	maxarea=0;
	for(maxdecide=0; maxdecide<nResults; maxdecide++){
		
		brainArea = getResult("Area", maxdecide);
		if(brainArea>maxarea){
			maxarea=brainArea;
			xcenterCrop=getResult("X", maxdecide);
			ycenterCrop=getResult("Y", maxdecide);
		}
	}//for(maxdecide=0; maxdecide<nResults; maxdecide++){
	
	AnalyzeCArray[1]=xcenterCrop;
	AnalyzeCArray[2]=ycenterCrop;
}//function analyzeCenter(AnalyzeC_Array){


function resetBrightness(maxvalue0){// resetting brightness if 16bit image
	if(maxvalue0<4096)
	call("ij.ImagePlus.setDefault16bitRange", 12);
	else
	call("ij.ImagePlus.setDefault16bitRange", 16);
}


function colordecision(colorarray){
	posicolor=colorarray[0];
	run("Z Project...", "projection=[Max Intensity]");
	setMinAndMax(0, 10);
	run("RGB Color");
	run("Size...", "width=5 height=5 constrain average interpolation=Bilinear");
	posicolor=0;
	for(colorsizeX=0; colorsizeX<5; colorsizeX++){
		for(colorsizeY=0; colorsizeY<5; colorsizeY++){
			
			Red=0; Green=0; Blue=0;
			colorpix=getPixel(colorsizeX, colorsizeY);
			
			Red = (colorpix>>16)&0xff;  
			Green = (colorpix>>8)&0xff; 
			Blue = colorpix&0xff;
			
			if(Red>0){
				posicolor="Red";
				
				if(Green>0 && Blue>0)
				posicolor="White";
				
				if(Blue>0 && Green==0)
				posicolor="Purple";
				
			}
			if(Green>0 && Red==0 && Blue==0)
			posicolor="Green";
			
			if(Green==0 && Red==0 && Blue>0)
			posicolor="Blue";
			
			if(Green>0 && Red==0 && Blue>0)
			posicolor="Green";
			
			if(Green>0 && Red>0 && Blue==0)
			posicolor="Yellow";
		}
	}
	close();
	
	colorarray[0]=posicolor;
}

function rotationF(rotation,unit,vxwidth,vxheight,depth,xTrue,yTrue){
	setBackgroundColor(0, 0, 0);
	run("Rotate... ", "angle="+rotation+" grid=1 interpolation=None fill enlarge stack");
	wait(1000);
	makeRectangle(xTrue-300, yTrue-465, 600, 1024);
	run("Crop");
	
	getDimensions(width, height, channels, slices, frames);
	if(height<1024 || width<600)
	run("Canvas Size...", "width=600 height=1024 position=Top-Left zero");
	run("Select All");
	run("Properties...", "channels=1 slices="+nSlices+" frames=1 unit=microns pixel_width="+vxwidth+" pixel_height="+vxheight+" voxel_depth="+depth+"");
	run("Grays");
}//function


function ImageCorrelation2 (sample, templateImg, rotSearch,ImageCarray,overlap,NumCPU){
	
	run("Image Correlation Atomic", "samp="+sample+" temp="+templateImg+" +="+rotSearch+" -="+rotSearch+" overlap="+overlap+" parallel="+NumCPU+" rotation=1 result calculation=[OBJ peasonCoeff] weight=[Equal weight (temp and sample)]");
	
	OBJ=getResult("OBJ score", 0);
	OBJScore=parseFloat(OBJ);
	
	Rot=getResult("rotation", 0);
	Rot=parseFloat(Rot);
	
	ShiftY=getResult("shifty", 0);
	ShiftY=parseFloat(ShiftY);
	
	ShiftX=getResult("shiftx", 0);
	ShiftX=parseFloat(ShiftX);
	
	ImageCarray[0]=OBJScore;
	ImageCarray[1]=Rot;
	ImageCarray[2]=ShiftY;
	ImageCarray[3]=ShiftX;
}

function C1C20102Takeout(takeout){// using
	origi=takeout[0];
	
	dotIndex = lastIndexOf(origi, "_C1.tif");
	if (dotIndex!=-1)
	origi = substring(origi, 0, dotIndex); 
	
	dotIndex = lastIndexOf(origi, "_C2.tif");
	if (dotIndex!=-1)
	origi = substring(origi, 0, dotIndex);
	
	dotIndex = lastIndexOf(origi, "_C1.nrrd");
	if (dotIndex!=-1)
	origi = substring(origi, 0, dotIndex); 
	
	dotIndex = lastIndexOf(origi, "_C2.nrrd");
	if (dotIndex!=-1)
	origi = substring(origi, 0, dotIndex);
	
	dotposition=lastIndexOf(origi, "_01.tif");
	if (dotposition!=-1)
	origi=substring(origi, 0, dotposition);
	
	dotposition=lastIndexOf(origi, "_02.tif");
	if (dotposition!=-1)
	origi=substring(origi, 0, dotposition);
	
	dotposition=lastIndexOf(origi, "_01.nrrd");
	if (dotposition!=-1)
	origi=substring(origi, 0, dotposition);
	
	dotposition=lastIndexOf(origi, "_02.nrrd");
	if (dotposition!=-1)
	origi=substring(origi, 0, dotposition);
	
	dotposition=lastIndexOf(origi, "_01.zip");
	if (dotposition!=-1)
	origi=substring(origi, 0, dotposition);
	
	dotposition=lastIndexOf(origi, "_02.zip");
	if (dotposition!=-1)
	origi=substring(origi, 0, dotposition);
	
	dotposition=lastIndexOf(origi, "_R.mha");
	if (dotposition!=-1)
	origi=substring(origi, 0, dotposition);
	
	dotposition=lastIndexOf(origi, "_G.mha");
	if (dotposition!=-1)
	origi=substring(origi, 0, dotposition);
	
	dotposition=lastIndexOf(origi, "_C1.zip");
	if (dotposition!=-1)
	origi=substring(origi, 0, dotposition);
	
	dotposition=lastIndexOf(origi, "GMR");
	if (dotposition!=-1)
	origi=substring(origi, dotposition, lengthOf(origi));
	
	dotposition=lastIndexOf(origi, "VT");
	if (dotposition!=-1)
	origi=substring(origi, dotposition, lengthOf(origi));
	
	dotposition=lastIndexOf(origi, "_C2.zip");
	if (dotposition!=-1)
	origi=substring(origi, 0, dotposition);
	
	dotposition=lastIndexOf(origi, ".");
	if (dotposition!=-1)
	origi=substring(origi, 0, dotposition);
	
	takeout[0]=origi;
}


function CLEAR_MEMORY() {
	//	d=call("ij.IJ.maxMemory");
	//	e=call("ij.IJ.currentMemory");
	for (trials=0; trials<2; trials++) {
		call("java.lang.System.gc");
		wait(100);
	}
}

function FILL_HOLES(DD2, DD3) {
	
	if(DD3==1){
		MASKORI=getImageID();
		run("Duplicate...", "title=MaskBWtest.tif duplicate");
		MaskBWtest2=getImageID();
		
		run("Invert LUT");
		run("RGB Color");
		run("8-bit");
		
		run("Fill Holes", "stack");
		
		run("Invert LUT");
		run("RGB Color");
		run("8-bit");
		
		//	print(nSlices+"   2427");
		run("Z Project...", "start=15 stop="+nSlices-10+" projection=[Average Intensity]");
		getStatistics(area, MaskINV_AVEmean, min, max, std, histogram);
		close();
		
		if(MaskINV_AVEmean<5 || MaskINV_AVEmean>250){
			selectImage(MaskBWtest2);
			close();
			
			selectImage(MASKORI);
			run("Fill Holes", "stack");
		}else{
			selectImage(MASKORI);
			close();
			selectImage(MaskBWtest2);
		}
		
		
	}else if (DD2==1){
		MASKORI=getImageID();
		run("Duplicate...", "title=MaskBWtest.tif");
		MaskBWtest2=getImageID();
		
		run("Invert LUT");
		run("RGB Color");
		run("8-bit");
		
		run("Fill Holes", "stack");
		
		run("Invert LUT");
		run("RGB Color");
		run("8-bit");
		
		getStatistics(area, MaskINV_AVEmean, min, max, std, histogram);
		
		if(MaskINV_AVEmean<20 || MaskINV_AVEmean>230){
			selectImage(MaskBWtest2);
			close();
			
			selectImage(MASKORI);
			run("Fill Holes", "stack");
		}else{
			selectImage(MASKORI);
			close();
			selectImage(MaskBWtest2);
		}
	}//if (2DD==1){
}

function lateralDepthAdjustment(op1center,op2center,lateralArray,nc82,templateBr,NumCPU,shrinkTo2010,objective){
	
	nc82ID=getImageID();
	orizslice=nSlices();
	
	run("Reslice [/]...", "output=1.000 start=Left rotate avoid");
	resliceW=getWidth(); resliceH=getHeight();
	print("Original op1center; "+op1center+"  op2center; "+op2center);
	wait(100);
	call("java.lang.System.gc");	
	
	rename("reslice.tif");
	Resliced=getImageID();
	
	if(op1center!=0 && op2center!=0){
		
	}else if(op1center==0 && op2center!=0){
		op1center=280;
	}else if(op1center!=0 && op2center==0){
		op2center=921;
	}else{
		op1center=280; op2center=921;
	}
	
	print("lateral Z-Projection; from "+op1center+" to "+op2center+"  or center of image; "+round(nSlices/2));
	
	
	if(op2center<round(nSlices/2)){
		print("lateral Z-Projection; from "+op1center+" to "+op2center+"  or center of image; "+round(nSlices/2));
		run("Z Project...", "start="+op1center+" stop="+op2center+" projection=[Max Intensity]");
	}else{
		print("lateral Z-Projection; from "+op1center+200+" to "+op2center-200+"  or center of image; "+round(nSlices/2));
		run("Z Project...", "start="+op1center+200+" stop="+op2center-200+" projection=[Max Intensity]");
	}
	getVoxelSize(VxWidthF, VxHeightF, VxDepthF, VxUnitF);
	getDimensions(widthF, heightF, channelsF, slicesF, frames);
	rename("smallMIP.tif");
	print("widthF Lateral (z-slice); "+widthF);
	
	//	newImage("mask1.tif", "8-bit white", widthF, heightF, 1);
	//	run("Mask Median Subtraction", "mask=mask1.tif data=smallMIP.tif %=100 histogram=100");
	
	//	selectWindow("mask1.tif");
	//	close();
	
	//selectWindow("smallMIP.tif");
	
	run("Enhance Contrast", "saturated=2");
	getMinAndMax(a,b);
	
	run("16-bit");
	print("a; "+a+"  b; "+b);
	if(a!=0 && b!=65535 && b!=255 && round(b*1.1)!=65535){
		setMinAndMax(0, round(b*1.1));
		run("Apply LUT");
	}
	
	print("VxWidthF; "+VxWidthF+"   VxHeightF; "+VxHeightF+"  VxDepthF; "+VxDepthF);
	
	xyRatio=5.0196078/VxWidthF;// just 5 time smaller, 5 micron vx width
	yRatio=3.1122/VxHeightF;
	
	FinalHsize=round(heightF/yRatio);
	FinalWsize=round(widthF/xyRatio);
	
	print("xyRatio; "+xyRatio+"   FinalHsize; "+FinalHsize+"  FinalWsize; "+FinalWsize+"   yRatio; "+yRatio);
	
	run("Gamma ", "gamma=1.60 in=InMacro cpu=1");
	lateralMIP=getImageID();
	rename("LateralMIP.tif");
	
	selectWindow("smallMIP.tif");
	close();
	
	selectWindow("LateralMIP.tif");
	rename("smallMIP.tif");
	
	
	//	setBatchMode(false);
	//	updateDisplay();
	//	"do"
	//	exit();
	
	startiWidth=40;
	endiWidth=180;
	
	if(VxDepthF<0.3){
		startiWidth=15;
		endiWidth=90;
	}
	
	setAutoThreshold("Otsu dark");//Mean Otsu mean 127 micron
	getThreshold(lower, upper);
	setThreshold(lower, upper);
	setOption("BlackBackground", true);
	
	setForegroundColor(255, 255, 255);
	setBackgroundColor(0, 0, 0);
	run("Make Binary", "thresholded remaining");
	
	run("Size...", "width="+round(FinalWsize)+" height="+round(FinalHsize)+" interpolation=None");
	
	run("Canvas Size...", "width=65 height=110 position=Center zero");
	run("Properties...", "channels=1 slices=1 frames=1 unit=microns pixel_width="+VxWidthF*xyRatio+" pixel_height="+VxHeightF*xyRatio+" voxel_depth="+VxDepthF+"");
	run("Select All");
	run("Copy");
	MaxOBJL=0; MaxWidth=0; negativeOBJ=0;
	run("Properties...", "channels=1 slices=1 frames=1 unit=microns pixel_width="+VxWidthF*xyRatio+" pixel_height="+VxHeightF*xyRatio+" voxel_depth="+VxDepthF+"");
	
	for(iWidth=startiWidth; iWidth<endiWidth; iWidth++){
		run("Properties...", "channels=1 slices=1 frames=1 unit=microns pixel_width="+VxWidthF*xyRatio+" pixel_height="+VxHeightF*xyRatio+" voxel_depth="+VxDepthF+"");
		
		selectWindow("smallMIP.tif");
		
		run("Size...", "width="+iWidth+" height=80 interpolation=None");
		run("Remove Outliers...", "radius=2 threshold=50 which=Dark");
		run("Fill Holes");
		
		run("Canvas Size...", "width=65 height=110 position=Center zero");
		
		//		setBatchMode(false);
		//				updateDisplay();
		//			"do"
		//			exit();
		
		run("Image Correlation Atomic", "samp=smallMIP.tif temp=Lateral_JFRC2010_5time_smallerMIP.tif +=10 -=10 overlap=90 parallel="+NumCPU+" rotation=1 result calculation=[OBJ peasonCoeff] weight=[Equal weight (temp and sample)]");
		
		OBJ=getResult("OBJ score", 0);
		OBJScoreL=parseFloat(OBJ);
		
		if(OBJScoreL>MaxOBJL){
			//		print(OBJScoreL);
			MaxOBJL=OBJScoreL;
			Rot=getResult("rotation", 0);
			Rot=parseFloat(Rot);
			elipsoidAngle=parseFloat(Rot);
			if (elipsoidAngle>90) 
			elipsoidAngle = -(180 - elipsoidAngle);
			
			ShiftY=getResult("shifty", 0);
			maxY=parseFloat(ShiftY);
			
			ShiftX=getResult("shiftx", 0);
			maxX=parseFloat(ShiftX);
			
			MaxWidth=iWidth;
			negativeOBJ=0;
		}else{
			negativeOBJ=negativeOBJ+1;
		}
		
		//	if(negativeOBJ==20)
		//	iWidth=350;
		
		run("Paste");
	}
	
	print("2949 nImages; "+nImages()+"   MaxWidth; "+MaxWidth);
	
	run("Size...", "width="+MaxWidth+" height=110 interpolation=None");
	run("Canvas Size...", "width=65 height=110 position=Center zero");
	setMinAndMax(0, 254);
	run("Apply LUT");
	run("8-bit");
	saveAs("PNG", ""+savedir+noext+"_Lateral.png");
	close();
	
	while(isOpen(noext+"_Lateral.png")){
		selectWindow(noext+"_Lateral.png");
		close();
	}
	
	while(isOpen("smallMIP.tif")){
		selectWindow("smallMIP.tif");
		close();
	}
	
	if(templateBr=="JFRC2010" || templateBr=="JFRC2013"){
		if(objective=="20x")
		Zsize=195;
		else
		Zsize=200;
	}else
	Zsize=151;
	
	Realvxdepth2=Zsize/((35/((FinalWsize/65)*MaxWidth))*widthF); //is real width of stack Z 
	
	maxrotation=elipsoidAngle/(Realvxdepth2/VxWidthF);
	
	print("MaxOBJL Lateral; "+MaxOBJL+"   BestiW; "+MaxWidth+"  Yshift; "+maxY+"  maxX; "+maxX+"  lateral rotation; "+maxrotation+"   Realvxdepth; "+Realvxdepth2);
	
	selectImage(nc82);
	close();
	
	if(isOpen(nc82ID)){
		selectImage(nc82ID);
		close();
	}
	if(isOpen("nc82.tif")){
		selectWindow("nc82.tif");
		close();
	}
	
	//titlelist=getList("image.titles");
	//for(iImage=0; iImage<titlelist.length; iImage++){
	//	print("Opened; "+titlelist[iImage]);
	//}
	
	
	selectWindow("reslice.tif");
	if(shrinkTo2010==true){
		if(bitDepth==8)
		run("16-bit");
		
		run("Rotation Hideo", "rotate="+maxrotation+" 3d in=InMacro");
		run("Translate...", "x=0 y="+round(maxY*yRatio)+" interpolation=None stack");
		run("Reslice [/]...", "output=1 start=Left rotate avoid");
		rename("nc82.tif");
		nc82=getImageID();
		print("nc82 lateral translated; "+round(maxY*yRatio)+"  shrinkTo2010; "+shrinkTo2010);
	}
	
	
	while(isOpen("reslice.tif")){
		selectWindow("reslice.tif");
		close();
	}
	
	CLEAR_MEMORY();
	
	
	//	setBatchMode(false);
	//				updateDisplay();
	//				"do"
	//				exit();
	
	
	lateralArray[0]=Realvxdepth2;
	lateralArray[1]=nc82;
	lateralArray[2]=maxrotation;
	lateralArray[3]=round((maxX*xyRatio)/2);
	lateralArray[4]=round(maxY*yRatio);
	lateralArray[5]=MaxOBJL;
}

function DupAvePprocessing (nc82,NumCPU,bitd){
	
	selectWindow("nc82.tif");
	oriwidth=getWidth(); oriheight=getHeight(); orislice=nSlices();
	
	if(bitd!=8){
		print("Mask dimension; oriwidth; "+oriwidth+"   oriheight; "+oriheight+"  orislice; "+orislice);
		
		newImage("mask.tif", "8-bit white", oriwidth, oriheight, orislice);
		run("Mask Median Subtraction", "mask=mask.tif data=nc82.tif %=100 histogram=100");
		
		selectWindow("mask.tif");
		close();
	}
	selectImage(nc82);
	
	run("Z Project...", "start=10 stop="+nSlices-10+" projection=[Average Intensity]");// imageID is AR
	rename("OriginalProjection.tif");
	
	run("Duplicate...", "title=DUPaveP.tif");
	getMinAndMax(min, max);
	if(min!=0 && max!=255)
	run("Apply LUT");
	
	run("Gamma ", "gamma=2.1 in=InMacro cpu="+NumCPU+"");
	gammaup=getTitle();
	
	selectWindow("DUPaveP.tif");
	close();
	
	selectWindow(gammaup);
	rename("DUPaveP.tif");
	
	run("Enhance Contrast", "saturated=0.35");
	getMinAndMax(min, max);
	
	bitd=bitDepth();
	if(bitd==8)
	run("16-bit");
	
	if(bitd!=8){
		newImage("mask.tif", "8-bit white", oriwidth, oriheight, 1);
		run("Mask Median Subtraction", "mask=mask.tif data=nc82.tif %=100 histogram=100");
		
		selectWindow("mask.tif");
		close();
	}
	selectWindow("DUPaveP.tif");
	
	setMinAndMax(min, max);
	if(min!=0 && max!=65535)
	run("Apply LUT");
}

function rotateshift3D (resliceLongLength,finalshiftX,Zoomratio,finalshiftY,elipsoidAngle,shrinkTo2010,cropWidth,cropHeight,Ori_widthVx,Ori_heightVx,depth){
	run("Canvas Size...", "width="+resliceLongLength+" height="+resliceLongLength+" position=Center zero");
	run("Properties...", "channels=1 slices="+nSlices+" frames=1 unit=microns pixel_width="+Ori_widthVx+" pixel_height="+Ori_heightVx+" voxel_depth="+depth+"");
	
	print("3311 Translated X; "+round(finalshiftX)+"  Y; "+round(finalshiftY)+", nc82, elipsoidAngle; "+elipsoidAngle+"   Zoomratio; "+Zoomratio+"  Canvas W; "+round(cropWidth/Zoomratio)+"   Canvas H; "+round(cropHeight/Zoomratio));
	if(bitDepth==8)
	run("16-bit");
	run("Rotation Hideo", "rotate="+elipsoidAngle+" 3d in=InMacro");
	
	run("Translate...", "x="+round(finalshiftX)+" y="+round(finalshiftY)+" interpolation=None stack");
	
	run("Properties...", "channels=1 slices="+nSlices+" frames=1 unit=microns pixel_width="+Ori_widthVx+" pixel_height="+Ori_heightVx+" voxel_depth="+depth+"");
	
	orizoomratio=Zoomratio;
	if(shrinkTo2010==false)
	Zoomratio=1;
	run("Canvas Size...", "width="+round(cropWidth/Zoomratio)+" height="+round(cropHeight/Zoomratio)+" position=Center zero");
	
	Zoomratio=orizoomratio;
}












