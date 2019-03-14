
argstr=0;
Rev=0;//reverse stack is 1
run("Misc...", "divide=Infinity save");

//argstr="/test/63xVNC_align/,GMR_36E12_AE_01_20161028_27_A1__m.h5j,/test/63xVNC_align/Failed/GMR_36E12_AE_01_20161028_27_A1__m.h5j,/test/63xVNC_align/template/,0.1882689,0.38,11,mesothoracic;metathoracic;abdominal,m";

//argstr="/test/63xVNC_align/,JRC_SS42707_20180608_22_E1_f.h5j,/test/63xVNC_align/Failed/JRC_SS42707_20180608_22_E1_f.h5j,/test/63xVNC_align/template/,0.1882689,0.38,11,prothoracic,f";

setBatchMode(true);

if(argstr!=0)
args = split(argstr,",");
else
args = split(getArgument(),",");


savedir = args[0];// save dir
filename = args[1];//file name
path = args[2];// full file path for inport file
MatchingDir = args[3];// directory VNC_Lateral_F.tif or VNC_Lateral_M.tif
resx = args[4];
resz = args[5];
NSLOTS = args[6];
alltiles = args[7];// tile position
gender = args[8];// f or m


resx=parseFloat(resx);//Change string to number
resz=parseFloat(resz);//Change string to number

tileposi = split(alltiles,";");

filepath=savedir+filename+"63x_VNC_pre_aligner_log.txt";

File.makeDirectory(savedir+"images/");

//prothoracic
//mesothoracic
//metathoracic
//abdominal

CLEAR_MEMORY();

tilenum=lengthOf(tileposi);

print("savedir; "+savedir);
print("filename; "+filename);
print("path; "+path);
print("MatchingDir; "+MatchingDir);
print("resx; "+resx);
print("resz; "+resz);
print("NSLOTS; "+NSLOTS);
print("alltiles; "+alltiles);
print("gender; "+gender);
print("tilenum; "+tilenum);
print("");


addX = 0;
addY = 0;
addRot = 0;
prot=55;
mrot=55;
//// VNC temoplate decision /////////////////////////


if(gender == "f"){
	//templateVNC="JRC2018_VNC_FEMALE_63x.nrrd";
	templateVNC="JRC2018_VNC_FEMALE_447.nrrd";
}else if (gender == "m"){
	//templateVNC="JRC2018_VNC_MALE_63x.nrrd";
	templateVNC="JRC2018_VNC_MALE_447.nrrd";
}
templateVNCunisex="JRC2018_VNC_UNISEX_63x.nrrd";

if(tilenum==1){
	if(tileposi[0]=="prothoracic"){
		
		matchingimage="small_F_median_prothora.tif";///"small_F_median_prothra.tif";
		//	addX = 0;
		addY = -65;
		//	addRot = 45;
		
	}else if(tileposi[0]=="mesothoracic"){
		
		matchingimage="small_F_median_mesothora.tif";
		
	}else if(tileposi[0]=="metathoracic" || tileposi[0]=="abdominal"){
		
		addY = 60;
		matchingimage="small_F_median_metathora.tif";
	}
	VNCcrop=1;
	
}else if(tilenum==2){
	if(tileposi[0]=="prothoracic" && tileposi[1]=="mesothoracic"){
		matchingimage="small_F.tif";
	}else if(tileposi[1]=="prothoracic" && tileposi[0]=="mesothoracic"){
		matchingimage="small_F.tif";
	}
	
	if(tileposi[0]=="prothoracic" && tileposi[1]=="metathoracic")
	matchingimage="small_F.tif";
	else if(tileposi[1]=="prothoracic" && tileposi[0]=="metathoracic")
	matchingimage="small_F.tif";
	
	if(tileposi[0]=="metathoracic" && tileposi[1]=="mesothoracic")
	matchingimage="small_F.tif";
	if(tileposi[1]=="metathoracic" && tileposi[0]=="mesothoracic")
	matchingimage="small_F.tif";
	
	if(tileposi[0]=="metathoracic" && tileposi[1]=="abdominal")
	matchingimage="small_F.tif";
	if(tileposi[1]=="metathoracic" && tileposi[0]=="abdominal")
	matchingimage="small_F.tif";
	
	VNCcrop=1;
	
}else if(tilenum==3 || tilenum==4){
	
	matchingimage="small_F.tif";
	
	prot=55;
	mrot=55;
	
	VNCcrop=0;
}
open(MatchingDir+matchingimage);
rename("smalltemp.tif");
getDimensions(smalltempW, smalltempH, smalltempC, smalltempS, smalltempF);
print("smalltempW; "+smalltempW+"  smalltempH; "+smalltempH);

titlelistOri=getList("image.titles");

IJ.redirectErrorMessages();
open(path);

titlelistAfter=getList("image.titles");

if(titlelistOri.length == titlelistAfter.length){
	print("PreAlignerError: The file cannot open; "+path);
	logsum=getInfo("log");
	File.saveString(logsum, filepath);
	
	run("Quit");
	
}

bitd=bitDepth();
getDimensions(sampW, sampH, channels, slices, frames);
SampleTitle=getTitle();


print("Channels; "+channels+"  slices; "+nSlices()/channels+"  sampW; "+sampW+"   sampH; "+sampH);
run("Properties...", "channels="+channels+" slices="+nSlices()/channels+" frames=1 unit=microns pixel_width="+resx+" pixel_height="+resx+" voxel_depth="+resz+"");

logsum=getInfo("log");
File.saveString(logsum, filepath);


if(channels>1){
	print(channels+" channels");
	run("Split Channels");
	
	selectWindow("C"+channels+"-"+SampleTitle);
	nc82ChannelID=getImageID();
	rename("nc82ori.tif");
	
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
		run("A4095 normalizer", "subtraction=1 start=1 end="+nSlices+"");
	}//if(bitd==8){
	
	nc82ChannelID=getImageID();
	
	neuronCH = newArray(channels);
	neuronST = newArray(channels);
	for(ichannel=1; ichannel<=channels-1; ichannel++){
		
		selectWindow("C"+ichannel+"-"+SampleTitle);
		
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
			run("A4095 normalizer", "subtraction=1 start=1 end="+nSlices+"");
		}//if(bitd==8){
		
		if(Rev==1){
			run("Reverse");
			print("reverse stack");
		}
		neuronCH[ichannel]=getImageID();
		neuronST[ichannel]=getTitle();
	}//for(ichannel=0; ichannel<channels; ichannel++){
}else{// channels == 1
	
	print("PreAlignerError: only 1 channel exist");
	File.saveString(logsum, filepath);
	run("Quit");
}//if(channels>1){

for(ineuron=1; ineuron<=channels-1; ineuron++){
	selectWindow(neuronST[ineuron]);
	
	if(tilenum==3 || tilenum==4)
	run("Canvas Size...", "width="+sampW+100+" height="+sampH+100+" position=Center zero");
	
	run("Nrrd Writer", "compressed nrrd="+savedir+"images/PRE_PROCESSED_0"+ineuron+1+".nrrd");
	close();
}

CLEAR_MEMORY();

print("Line 165 nImages; "+nImages);

selectWindow("nc82ori.tif");
// resize median projection //

run("Max value");/// need new plugin
logsum=getInfo("log");
endlog=lengthOf(logsum);
maxposition=lastIndexOf(logsum, "Maxvalue;");
minposition=lastIndexOf(logsum, "  Minvalue;");

maxvalue0=substring(logsum, maxposition+10, minposition);
maxvalue0=round(maxvalue0);

if(maxvalue0!=65535){
	setMinAndMax(0, maxvalue0);
	run("Apply LUT", "stack");
}

run("Z Project...", "projection=Median");//Median//[Max Intensity]

run("Enhance Contrast", "saturated=0.35");

run("16-bit");
rename("samp.tif");
maxrotation=0;

resizefactor = 1.7892/resx;
print("resizefactor; "+resizefactor+"  sampW; "+sampW+"  sampH; "+sampH);

run("Size...", "width="+round(sampW/resizefactor)+" height="+round(sampH/resizefactor)+" average interpolation=Bicubic");
run("Canvas Size...", "width="+smalltempW+" height="+smalltempH+" position=Center zero");

saveAs("PNG", savedir+filename+"_originalSmall.png");
rename("samp.tif");

run("Image Correlation Atomic SD", "samp=samp.tif temp=smalltemp.tif +="+prot+" -="+mrot+" overlap=70 parallel="+NSLOTS+" rotation=1 show calculation=OBJPeasonCoeff");

selectWindow("DUP_samp.tif");
run("Enhance Contrast", "saturated=0.35");
getMinAndMax(min, max);

if(min!=0 && max!=65535)
run("Apply LUT");

run("Merge Channels...", "c1=smalltemp.tif c2=DUP_samp.tif  c3=smalltemp.tif keep");
saveAs("PNG", savedir+filename+"_"+matchingimage+".png");
close();

selectWindow("DUP_samp.tif");
close();

CLEAR_MEMORY();

totalLog=getInfo("log");
OBJindex = lastIndexOf(totalLog, "score;");

xindex = lastIndexOf(totalLog,"shiftx");
yindex = lastIndexOf(totalLog,"shifty");
rotindex = lastIndexOf(totalLog,"rotation");


OBJScore=substring(totalLog,OBJindex+6, lengthOf(totalLog));//getResult("OBJ score", 0);
OBJScore=parseFloat(OBJScore);//Chaneg string to number

maxrotation= substring(totalLog,rotindex+9, OBJindex-6);//getResult("rotation", 0);
maxrotation=parseFloat(maxrotation);//Chaneg string to number

if(addRot!=0)
maxrotation=addRot-maxrotation;


maxX= substring(totalLog,xindex+7, yindex-2);//getResult("shiftx", 0);
maxX=parseFloat(maxX);//Chaneg string to number

if(addX!=0)
maxX=addX-maxX;


maxY=substring(totalLog,yindex+7, rotindex-2);//getResult("shifty", 0);
maxY=parseFloat(maxY);//Chaneg string to number

if(addY!=0)
maxY=addY+maxY;

padding=200;

/////////////// Unisex temp //////////////////////////////
open(MatchingDir+templateVNCunisex);
getDimensions(UtempCanvasWidth, UtempCanvasHeight, Utempchannels, Utempslices, Utempframes);

print("UtempCanvasWidth; "+UtempCanvasWidth+"   UtempCanvasHeight; "+UtempCanvasHeight+"   Utempslices; "+Utempslices);

tempXranslation=round((maxX*resizefactor)*-1);
tempYranslation=round((maxY*resizefactor)*-1);
smallerchangeratio=1;//smallerchangeratio=resx/0.1882689

if(sampW<2000 && sampH<2000){
	sampleLongLengthW=round(UtempCanvasWidth*1.8);//round(sqrt(sampH*sampH+sampW*sampW)*2);
	sampleLongLengthH=round(UtempCanvasHeight);//round(sqrt(sampH*sampH+sampW*sampW));
}else{
	sampleLongLengthW=round(UtempCanvasWidth*1.8);//round(sqrt(sampH*sampH+sampW*sampW)*2);
	sampleLongLengthH=round(UtempCanvasHeight*1.2);//round(sqrt(sampH*sampH+sampW*sampW));
}

tempYranslation=tempYranslation+52;

temptype="Unisex";
TempRotation (tempXranslation,tempYranslation,sampleLongLengthW+padding,sampleLongLengthH,maxrotation,resx,resz,VNCcrop,sampW,sampH,padding,temptype,smallerchangeratio);

selectWindow(templateVNCunisex);

TempMIPcreation (VNCcrop,sampW,padding,sampH,savedir,filename,temptype);

selectWindow(templateVNCunisex);
run("Nrrd Writer", "compressed nrrd="+savedir+"TempUnisex.nrrd");

while(isOpen(templateVNCunisex)){
	selectWindow(templateVNCunisex);
	close();
	print(templateVNCunisex+" closed");
}
File.saveString(UtempCanvasWidth+"\n"+UtempCanvasHeight+"\n"+Utempslices+"\n"+maxrotation+"\n"+tempXranslation*-1+"\n"+tempYranslation*-1+"\n"+resizefactor, savedir+filename+"_U_translation.txt");
CLEAR_MEMORY();

selectWindow("nc82ori.tif");
run("Gamma ", "gamma=1.4 in=InMacro cpu="+NSLOTS+"");
gammaup=getTitle();

while(isOpen("nc82ori.tif")){
	selectWindow("nc82ori.tif");
	close();
}
CLEAR_MEMORY();

selectWindow(gammaup);

if(tilenum==3 || tilenum==4)
run("Canvas Size...", "width="+sampW+100+" height="+sampH+100+" position=Center zero");
run("Nrrd Writer", "compressed nrrd="+savedir+"images/PRE_PROCESSED_01.nrrd");
rename("nc82ori.tif");

/// resize sample for smaller VNC ////////////////////////////
smallerchangeratio=resx/0.4611220;
smallerchangeratioZ=resz/1;
resizefactor = 1.7892/0.4611220;

run("Size...", "width="+round(sampW*smallerchangeratio)+" height="+round(sampH*smallerchangeratio)+" depth="+round(slices*smallerchangeratioZ)+" constrain average interpolation=Bilinear");
getDimensions(sampW, sampH, channels, slices, frames);
run("Nrrd Writer", "compressed nrrd="+savedir+"PRE_PROCESSED_DW_01.nrrd");

print("");
/////////////// Gender template ///////////////////////////////
open(MatchingDir+templateVNC);
getDimensions(tempCanvasWidth, tempCanvasHeight, tempchannels, tempslices, tempframes);
getVoxelSize(tempVxWidth, tempVxHeight, tempVxDepth, VxUnit);

print("tempCanvasWidth; "+tempCanvasWidth+"   tempCanvasHeight; "+tempCanvasHeight+"   tempslices; "+tempslices);
print("tempVxWidth; "+tempVxWidth+"  tempVxHeight; "+tempVxHeight+"  tempVxDepth; "+tempVxDepth);

if(sampW<2000 && sampH<2000){
	sampleLongLengthW=round(tempCanvasWidth*2);//round(sqrt(sampH*sampH+sampW*sampW)*2);
	sampleLongLengthH=round(tempCanvasHeight);//round(sqrt(sampH*sampH+sampW*sampW));
}else{
	sampleLongLengthW=round(tempCanvasWidth*1.8);//round(sqrt(sampH*sampH+sampW*sampW)*2);
	sampleLongLengthH=round(tempCanvasHeight*1.2);//round(sqrt(sampH*sampH+sampW*sampW));
}

print("maxY; "+maxY+"   maxX; "+maxX+"  addX; "+addX+"  addY; "+addY+"  maxrotation; "+maxrotation);
/// template rotation /////////////



selectWindow(templateVNC);

tempXranslation=round((maxX*resizefactor)*-1);
tempYranslation=round((maxY*resizefactor)*-1);

padding=round(padding*smallerchangeratio);
temptype="Gender";

TempRotation (tempXranslation,tempYranslation,sampleLongLengthW+padding,sampleLongLengthH,maxrotation,resx,resz,VNCcrop,sampW,sampH,padding,temptype,smallerchangeratio);

selectWindow(templateVNC);

run("Nrrd Writer", "compressed nrrd="+savedir+"TempDW.nrrd");
TempMIPcreation (VNCcrop,sampW,padding,sampH,savedir,filename,temptype);

//selectWindow(templateVNC);
//getDimensions(TempRotW, TempRotH, TempRotCH, TempRotSlice, TempRotF);
//run("Size...", "width="+round(TempRotW/2)+" height="+round(TempRotH/2)+" depth="+TempRotSlice+" constrain average interpolation=Bilinear");

//setBatchMode(false);
//updateDisplay();
//a

//run("Nrrd Writer", "compressed nrrd="+savedir+"TempDW.nrrd");

logsum=getInfo("log");
File.saveString(logsum, filepath);

while(isOpen(templateVNC)){
	selectWindow(templateVNC);
	close();
}

File.saveString(tempCanvasWidth+"\n"+tempCanvasHeight+"\n"+tempslices+"\n"+maxrotation+"\n"+tempXranslation*-1+"\n"+tempYranslation*-1+"\n"+resizefactor, savedir+filename+"_translation.txt");




logsum=getInfo("log");
File.saveString(logsum, filepath);
run("Misc...", "divide=Infinity save");
run("Close All");
run("Quit");


function TempRotation (tempXranslation,tempYranslation,sampleLongLengthW,sampleLongLengthH,maxrotation,resx,resz,VNCcrop,sampW,sampH,padding,temptype,smallerchangeratio) {
	
	run("Canvas Size...", "width="+sampleLongLengthW+" height="+sampleLongLengthH+" position=Center zero");
	
	run("Translate...", "x="+round(tempXranslation)+" y="+round(tempYranslation)+" interpolation=None stack");
	print("Translated template line 230; X; "+tempXranslation+"   Y; "+tempYranslation);
	print("temp rotate W; "+sampleLongLengthW+"  H; "+sampleLongLengthH);
	if(maxrotation!=0){
		getVoxelSize(VxWidth, VxHeight, VxDepth, VxUnit);
		run("Rotation Hideo", "rotate="+maxrotation*-1+" 3d in=InMacro");
		run("Properties...", "channels=1 slices="+nSlices+" frames=1 unit=microns pixel_width="+VxWidth+" pixel_height="+VxHeight+" voxel_depth="+VxDepth+"");
	}//	if(maxrotation>0){
	
	if(VNCcrop==1)
	run("Canvas Size...", "width="+sampW+padding+" height="+sampH+padding+" position=Center zero");
	else if (temptype=="Unisex")
	run("Canvas Size...", "width=2550 height=2350 position=Center zero");
	else
	run("Canvas Size...", "width="+round(2550*smallerchangeratio)+" height="+round(2350*smallerchangeratio)+" position=Center zero");
	
}//function TempRotation (tempXranslation,tempYranslation,sampleLongLengthW,sampleLongLengthH,maxrotation,resx,resz,VNCcrop,sampW,sampH) {

function TempMIPcreation (VNCcrop,sampW,padding,sampH,savedir,filename,temptype){
	run("Z Project...", "projection=[Max Intensity]");
	tempMIP = getImageID();
	tempMIPst = getTitle();
	
	selectWindow("nc82ori.tif");
	run("Z Project...", "projection=[Max Intensity]");
	
	if(VNCcrop==1)
	run("Canvas Size...", "width="+sampW+padding+" height="+sampH+padding+" position=Center zero");
	else if (temptype=="Unisex")
	run("Canvas Size...", "width=2550 height=2350 position=Center zero");
	else
	run("Canvas Size...", "width="+round(2550*smallerchangeratio)+" height="+round(2350*smallerchangeratio)+" position=Center zero");
	
	sampMIPst = getTitle();
	
	run("Merge Channels...", "c1="+tempMIPst+" c2="+sampMIPst+"  c3="+tempMIPst+"");
	//saveAs("PNG", savedir+filename+"_TempP_SampG.png");
	
	if(temptype=="Gender")
	saveAs("Jpeg", savedir+filename+"_TempP_SampG.jpg");
	else
	saveAs("Jpeg", savedir+filename+"_Unisex_TempP_SampG.jpg");
	close();
}//function TempMIPcreation (VNCcrop,sampW,padding,sampH,savedir,filename,temptype){

function CLEAR_MEMORY() {
	d=call("ij.IJ.maxMemory");
	e=call("ij.IJ.currentMemory");
	for (trials=0; trials<3; trials++) {
		wait(100);
		call("java.lang.System.gc");
	}
}








