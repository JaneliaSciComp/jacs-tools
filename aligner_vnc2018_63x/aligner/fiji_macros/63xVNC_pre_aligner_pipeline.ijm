
argstr=0;
Rev=0;//reverse stack is 1
run("Misc...", "divide=Infinity save");

//argstr="/test/63xVNC_align/,test.nrrd,/test/63xVNC_align/samples/pro/JRC_SS42707_20180608_22_E1_.h5j,/test/63xVNC_align/template/,f,mesothoracic-metathoracic-abdominal,0.1882689,0.38,11";

//argstr="/test/63xVNC_align/,test.nrrd,/test/63xVNC_align/samples/JRC_SS29619_20161111_19_B3_stitched-2339236317382049829_m.h5j,/test/63xVNC_align/template/,0.1882689,0.38,11,mesothoracic;metathoracic;abdominal,m";//single tile

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


if(gender == "f")
templateVNC="JRC2018_VNC_FEMALE_63x.nrrd";
else if (gender == "m")
templateVNC="JRC2018_VNC_MALE_63x.nrrd";

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

open(MatchingDir+templateVNC);
getDimensions(tempCanvasWidth, tempCanvasHeight, tempchannels, tempslices, tempframes);
//split channels & assign channels to array ////

print("tempCanvasWidth; "+tempCanvasWidth+"   tempCanvasHeight; "+tempCanvasHeight+"   tempslices; "+tempslices);

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

if(sampW<2000 && sampH<2000){
	sampleLongLengthW=round(tempCanvasWidth*1.8);//round(sqrt(sampH*sampH+sampW*sampW)*2);
	sampleLongLengthH=round(tempCanvasHeight);//round(sqrt(sampH*sampH+sampW*sampW));
}else{
	sampleLongLengthW=round(tempCanvasWidth*1.8);//round(sqrt(sampH*sampH+sampW*sampW)*2);
	sampleLongLengthH=round(tempCanvasHeight*1.6);//round(sqrt(sampH*sampH+sampW*sampW));
}

print("maxY; "+maxY+"   maxX; "+maxX+"  addX; "+addX+"  addY; "+addY+"  maxrotation; "+maxrotation);
/// template rotation /////////////
selectWindow(templateVNC);

tempXranslation=round((maxX*resizefactor)*-1);
tempYranslation=round((maxY*resizefactor)*-1);
padding=200;
temptype="Gender";

TempRotation (tempXranslation,tempYranslation,sampleLongLengthW,sampleLongLengthH,maxrotation,resx,resz,VNCcrop,sampW,sampH,padding,temptype);

//setBatchMode(false);
	//updateDisplay();
	//a

run("Nrrd Writer", "compressed nrrd="+savedir+"Temp.nrrd");

TempMIPcreation (VNCcrop,sampW,padding,sampH,savedir,filename,temptype);

selectWindow(templateVNC);
close();

CLEAR_MEMORY();

/////////////// Unisex temp //////////////////////////////
open(MatchingDir+templateVNCunisex);
getDimensions(UtempCanvasWidth, UtempCanvasHeight, Utempchannels, Utempslices, Utempframes);

TempRotation (tempXranslation,tempYranslation,sampleLongLengthW,sampleLongLengthH,maxrotation,resx,resz,VNCcrop,sampW,sampH,padding,temptype);

run("Nrrd Writer", "compressed nrrd="+savedir+"TempUnisex.nrrd");

temptype="Unisex";
TempMIPcreation (VNCcrop,sampW,padding,sampH,savedir,filename,temptype);

selectWindow(templateVNCunisex);
close();

CLEAR_MEMORY();

selectWindow("nc82ori.tif");
run("Gamma ", "gamma=1.4 in=InMacro cpu="+NSLOTS+"");
gammaup=getTitle();

selectWindow("nc82ori.tif");
close();



File.saveString(tempCanvasWidth+"\n"+tempCanvasHeight+"\n"+tempslices+"\n"+maxrotation+"\n"+tempXranslation*-1+"\n"+tempYranslation*-1+"\n"+resizefactor, savedir+filename+"_translation.txt");

File.saveString(UtempCanvasWidth+"\n"+UtempCanvasHeight+"\n"+Utempslices+"\n"+maxrotation+"\n"+tempXranslation*-1+"\n"+tempYranslation*-1+"\n"+resizefactor, savedir+filename+"_U_translation.txt");

selectWindow(gammaup);
run("Nrrd Writer", "compressed nrrd="+savedir+"images/PRE_PROCESSED_01.nrrd");
close();

for(ineuron=1; ineuron<=channels-1; ineuron++){
	selectWindow(neuronST[ineuron]);
	run("Nrrd Writer", "compressed nrrd="+savedir+"images/PRE_PROCESSED_0"+ineuron+1+".nrrd");
	close();
}

run("Misc...", "divide=Infinity save");
run("Close All");
run("Quit");


function TempRotation (tempXranslation,tempYranslation,sampleLongLengthW,sampleLongLengthH,maxrotation,resx,resz,VNCcrop,sampW,sampH,padding,temptype) {
	if(temptype=="Unisex")
	tempYranslation=tempYranslation-52;
	
	run("Translate...", "x="+round(tempXranslation)+" y="+round(tempYranslation)+" interpolation=None stack");
	print("Translated template line 230; X; "+tempXranslation+"   Y; "+tempYranslation);
	print("temp rotate W; "+sampleLongLengthW+"  H; "+sampleLongLengthH);
	if(maxrotation!=0){
		run("Canvas Size...", "width="+sampleLongLengthW+" height="+sampleLongLengthH+" position=Center zero");
		
		run("Rotation Hideo", "rotate="+maxrotation*-1+" 3d in=InMacro");
		run("Properties...", "channels=1 slices="+nSlices+" frames=1 unit=microns pixel_width="+resx+" pixel_height="+resx+" voxel_depth="+resz+"");
	}//	if(maxrotation>0){

	if(VNCcrop==1)
	run("Canvas Size...", "width="+sampW+padding+" height="+sampH+padding+" position=Center zero");
	else
	run("Canvas Size...", "width=2250 height=2350 position=Center zero");
}//function TempRotation (tempXranslation,tempYranslation,sampleLongLengthW,sampleLongLengthH,maxrotation,resx,resz,VNCcrop,sampW,sampH) {

function TempMIPcreation (VNCcrop,sampW,padding,sampH,savedir,filename,temptype){
	run("Z Project...", "projection=[Max Intensity]");
	tempMIP = getImageID();
	tempMIPst = getTitle();
	
	selectWindow("nc82ori.tif");
	run("Z Project...", "projection=[Max Intensity]");
	
	if(VNCcrop==1)
	run("Canvas Size...", "width="+sampW+padding+" height="+sampH+padding+" position=Center zero");
	else
	run("Canvas Size...", "width=2250 height=2350 position=Center zero");
	
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








