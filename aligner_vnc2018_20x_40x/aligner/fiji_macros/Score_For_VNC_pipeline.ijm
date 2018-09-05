//VNC score macro. Wrote by Hideo Otsuna Jan 2016.
//This macro requires VNC template (flyVNCtemplate20xA_CLAHE_16bit.nrrd") and the mask (flyVNCtemplate20xA_CLAHE_MASK2nd.nrrd)
//This macro requires "ObjPearsonCoeff_.class" plugin
//The input data is the signal of nc82 of 20x VNC (aligned)
//This macro will generate .avi movie; template: purple, sample: green

run("Misc...", "divide=Infinity save");
scoreT1=0; SampleDup=0;
setForegroundColor(65535, 65535, 65535);

//argstr="/Registration/reformatted/Male_GMR_119_09_01_warp_m0g40c4e1e-1x16r3.nrrd,BJD_116F12_AE_01,/test/VNC_Test/,/Registration/refbrain/flyVNCtemplate20xA_CLAHE_16bit.nrrd,/Registration/refbrain/flyVNCtemplate20xA_CLAHE_MASK2nd.nrrd,Male,/Registration/refbrain/Male_VNC.nrrd,/Registration/refbrain/Mask_Male_VNC.nrrd"//for test
//args = split(argstr,",");


argstr = getArgument();//Argument
args = split(argstr,",");

if (lengthOf(args)>1) {
	path = args[0];// full file path for Open
	DataName = args[1];//Name for save
	savedir = args[2];//save directory
	templocation =args[3];//Female template full file path
	tempMasklocation = args[4];//Female template mask full file path
	temptype = args[5];//"f" or "Male"
	NSLOTS = args[6];
}

print("path; "+path);
print("DataName; "+DataName);
print("savedir; "+savedir);
print("Gender; "+temptype);

filepath=savedir+"Hideo_OBJPearsonCoeff.txt";
setBatchMode(true);

open(tempMasklocation);

OrigiMask2=getImageID();// Template Mask
tempMaskName=getTitle();

if(nSlices==220){
	run("Make Substack...", "delete slices=11-195");
	OrigiMask3=getImageID();// Template Mask
	
	selectImage(OrigiMask2);
	close();
	CLEAR_MEMORY();
	selectImage(OrigiMask3);
	rename(tempMaskName);
	OrigiMask2=getImageID();// Template Mask
}

open(templocation);
if(temptype=="f"){
	tempAve=60.56;
}else{
	tempAve=49.18;
}
setMinAndMax(0, 65535);
tempName=getTitle();
TempOri=getImageID();

histostretch=1;
	
///// start processing /////////////////////////////////////////////////
		
open(path);

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
		
if(nSlices==220){// aligned VNC should have 220 slices
		
	Sample=getImageID();// Sample
			
	run("Z Project...", "projection=[Max Intensity]");
	getStatistics(area, mean, minSample, maxSample, std, histogram);
	width2=getWidth();
	height2=getHeight();
			
// empty region filling, this allows to detect if sample is hitting edge = distortion or upside down /////////////////////////////
	yscanUP=0; positiveup=0;
	while(positiveup==0){//UPPER SCAN, for fill empty on data
				
		for(vup=0; vup<width2; vup++){
			PIXV=getPixel(vup, yscanUP);
			
			if(PIXV>0)
			positiveup=1;
		}
		if(positiveup==0)
		yscanUP=yscanUP+1;//UPPER LINE FOR EMPTY PX
	}
	
	yscanDW=0; positivedw=0;
	while(positivedw==0){//BOTTOM SCAN
		
		for(vdw=0; vdw<width2; vdw++){
			PIXV=getPixel(vdw, yscanDW);
			
			if(PIXV>0)
			positivedw=1;
		}
		if(positivedw==0)
		yscanDW=yscanDW+1;//BOTTOM LINE FOR EMPTY PX
	}
	
	xscanLF=0; positiveLF=0;
	while(positiveLF==0){//left SCAN
		
		for(vLF=0; vLF<height2; vLF++){
			PIXV=getPixel(xscanLF, vLF);
			
			if(PIXV>0)
			positiveLF=1;
		}
		if(positiveLF==0)
		xscanLF=xscanLF+1;//left LINE FOR EMPTY PX
	}
	
	xscanRI=0; positiveRI=0;
	while(positiveRI==0){//right SCAN
		
		for(vRI=0; vRI<height2; vRI++){
			PIXV=getPixel(xscanRI, vRI);
			
			if(PIXV>0)
			positiveRI=1;
		}
		if(positiveRI==0)
		xscanRI=xscanRI+1;//right LINE FOR EMPTY PX
	}
	close();
	
	selectImage(Sample);
	rename("Samp.tif");
	setMinAndMax(minSample, maxSample);
	run("Apply LUT", "stack");
	
/// score measurement  //////////////////////		
	run("Select All");
	run("Duplicate...", "title=MaskSampleTitle.tif duplicate");
	SampleDup2=getImageID();
	
	if(nSlices==220){
		run("Make Substack...", "slices=11-195");// eliminate empty regions. This gives us more meaningful score.
		SampleDup3=getImageID();
		
		selectImage(SampleDup2);
		close();
		selectImage(SampleDup3);
		rename("MaskSampleTitle.tif");
	}
	SampleDup2=getImageID();
	
	//		setBatchMode(false);
	//			updateDisplay();
	//						"do"
	//						exit;
	
	selectImage(SampleDup2);
	run("Z Project...", "projection=[Average Intensity]");
	oriname=getTitle();
	run("Three D Ave");
	lowerM=getTitle();
	close();
	lowerM=parseFloat(lowerM);
	lowerM=round(lowerM);
	
	print("sample thresholding; "+lowerM);
	
	//	setBatchMode(false);
	//			updateDisplay();
	//					"do"
	//				exit;
	
	selectImage(SampleDup2);
	if(nSlices==186){
		setSlice(1);
		run("Delete Slice");
		print("deleted slice; "+nSlices);
	}
	
	if(temptype=="f"){
		Threweight=1;
		incriweight=0.03;
		maxGap=3;
	}else{
		Threweight=2;
		incriweight=0.06;
		maxGap=2;
	}
	run("Duplicate...", "title=ANDresult2.tif duplicate");
	ANDst2=getImageID();
	
	setThreshold(lowerM*Threweight, 65535);
	run("Convert to Mask", "method=Default background=Default black");
	
	oriname=getTitle();
	run("Three D Ave");
	ave=getTitle();
	rename(oriname);
	ave=parseFloat(ave);
	meangap=tempAve-ave;// 60.56 is ave of tempMask at 185 slices
	Bad=0; premeangap=0;
	if(meangap>maxGap){
		while(meangap>maxGap && Threweight>=0.1){
			selectImage(ANDst2);
			close();
			
			selectImage(SampleDup2);
			run("Duplicate...", "title=ANDresult2.tif duplicate");
			ANDst2=getImageID();
			
			Threweight=Threweight-0.03;
			
			setThreshold(lowerM*Threweight, 65535);
			run("Convert to Mask", "method=Default background=Default black");
			
			run("Remove Outliers...", "radius=1 threshold=50 which=Bright stack");
			oriname=getTitle();
			run("Three D Ave");
			ave=getTitle();
			rename(oriname);
			ave=parseFloat(ave);
			meangap=tempAve-ave;
			if(premeangap==meangap){
				meangap=0;
				print("Bad alignment");
				Bad=1;
			}
			premeangap=meangap;
		}
		selectImage(ANDst2);
		close();
		CLEAR_MEMORY();
	}else if(meangap<-maxGap){
		while(meangap<-maxGap && Threweight<3){
			
			if(isOpen(ANDst2)){
				selectImage(ANDst2);
				close();
			}
			
			selectImage(SampleDup2);
			run("Duplicate...", "title=ANDresult2.tif duplicate");
			ANDst2=getImageID();
			
			Threweight=Threweight+0.03;
			
			setThreshold(lowerM*Threweight, 65535);
			run("Convert to Mask", "method=Default background=Default black");
			
			run("Remove Outliers...", "radius=1 threshold=50 which=Bright stack");
			oriname=getTitle();
			run("Three D Ave");
			ave=getTitle();
			rename(oriname);
			ave=parseFloat(ave);
			meangap=tempAve-ave;
			
			if(premeangap==meangap){
				meangap=0;
				print("Bad alignment");
				Bad=1;
			}
			
			premeangap=meangap;
		}
		if(isOpen(ANDst2)){
			selectImage(ANDst2);
			close();
		}
		CLEAR_MEMORY();
	}//if(meangap>1000)
	
	selectImage(SampleDup2);
	setThreshold(lowerM*Threweight, 65535);
	run("Convert to Mask", "method=Default background=Default black");
	run("Remove Outliers...", "radius=1 threshold=50 which=Bright stack");
	
	print("3D thre sample threshold; "+lowerM*Threweight+"  Threweight; "+Threweight+"   meangap; "+meangap);

	
	run("Z Project...", "projection=[Max Intensity]");
	getStatistics(area, mean5, minSample, maxSample, std, histogram);
	close();
	
	if(isOpen("ANDresult2.tif")){
		selectImage("ANDresult2.tif");
		close();
	}
	
	selectWindow("MaskSampleTitle.tif");
	
	if(mean5>0){
	//	run("ObjPearson Coeff", "template="+tempMaskName+" sample=MaskSampleTitle.tif show change");
		run("ObjPearson Coeff", "template="+tempMaskName+" sample=MaskSampleTitle.tif show change weight=[Equal weight (temp and sample)] parallel="+NSLOTS+"");
		
		scoreT=getTitle();
		scoreT=parseFloat(scoreT);//Chaneg string to number
	//	scorearray=newArray(0, 0);
	//	scoreCal(scorearray);
	//	scoreT=scorearray[0];
		
	}else
	scoreT=0;
	
	if(scoreT==NaN)
	scoreT=scoreT1;
	
	if(isOpen(SampleDup3)){
		selectImage(SampleDup3);
		close();
	}
	
	print(scoreT+"  Score");
	ScoreT=scoreT*1000;
	
		//		setBatchMode(false);
		//			updateDisplay();
		//			"do"
		//			exit;
		
	if(ScoreT<0)
	ScoreT=abs(ScoreT);

//	ScoreT=round(ScoreT);
	
	/////// test ///////////////////////////////////////////
	selectImage(TempOri);
	run("Duplicate...", "title=Temp.tif duplicate");
	
	selectImage(Sample);
	setFont("SansSerif" , 28, "antialiased");
	for(stringslice=1; stringslice<=nSlices; stringslice++){
		setSlice(stringslice);
		drawString("Score; "+scoreT, width2*0.05, height2-height2*0.03);
	}
	
	selectWindow("Samp.tif");
	
	run("Z Project...", "projection=[Max Intensity]");
	getStatistics(area, mean, minSample, maxSample, std, histogram);
	close();
	
	selectWindow("Samp.tif");
	setSlice(round(nSlices/2));
	run("Enhance Contrast", "saturated=2");
	getMinAndMax(min, max);
	setMinAndMax(min, max);
	
	if(max!=maxSample)
	run("Apply LUT", "stack");
	
	run("Merge Channels...", "c1=Temp.tif c2=Samp.tif c3=Temp.tif");
	run("AVI... ", "compression=JPEG frame=25 save="+savedir+ScoreT+"_"+DataName+".avi");
	
	File.saveString(scoreT, filepath);
	
	selectWindow("RGB");
	close();
	
	if(isOpen(SampleDup)){
		selectImage(SampleDup);
		close();
	}
	
	if(isOpen(Sample)){
		selectImage(Sample);
		close();
	}
	if(isOpen("Samp.tif")){
		selectWindow("Samp.tif");
		close();
	}
	
	if(isOpen("Temp.tif")){
		selectWindow("Temp.tif");
		close();
	}
	
	CLEAR_MEMORY(); 
}else{
	close();
	print("Slice number is not 220; "+path);
	print("Sample file has "+nSlices+" slices, this is not 220 slices for female template");
}
	//	if(isOpen("Max.tif")){
	//		selectWindow("Max.tif");
	//		close();
	//	}
if(isOpen("MaskSampleTitle.tif")){
	selectWindow("MaskSampleTitle.tif");
	close();
}
if(nImages>3){// incase, if Fiji has bug. The opened images will accumulate
	print("imageNo; "+nImages);
	s=getList("image.titles");
	
	for(ee=0; ee<s.length; ee++){
		print("open title; "+s[ee]);
	}
}//	if(nImages>3){


"Done"
setBatchMode(false);
run("Misc...", "divide=Infinity save");
run("Quit");




function scoreCal(scorearray){
	loginfo=getInfo("log");
	
	lengthoflog=lengthOf(loginfo);
	dotIndex20 = lastIndexOf(loginfo, "valSum; ");
	valsum=substring(loginfo, dotIndex20+8, lengthoflog);
	valsum=parseFloat(valsum);
	
	dotIndex10 = lastIndexOf(loginfo, "Cross; ");
	cross=substring(loginfo, dotIndex10+7, dotIndex20);
	cross=parseFloat(cross);
	
	score=valsum/sqrt(cross);
	scorearray[0]=score;
}

function CLEAR_MEMORY() {
	d=call("ij.IJ.maxMemory");
	e=call("ij.IJ.currentMemory");
	for (trials=0; trials<3; trials++) {
		call("java.lang.System.gc");
		wait(50);
	}
}
