//Wrote by Hideo Otsuna (HHMI Janelia Research Campus), Aug 4, 2017


setBatchMode(true);

AutoBRV=true;
desiredmean=190;
usingLUT="PsychedelicRainBow2";

lowerweight=0.7;
lowthreM="Peak Histogram";
unsharp="NA";//"NA", "Unsharp", "Max"

secondjump=235;
CropYN=false;// crop optic lobe
MIPtype="MCFO_MIP";

startMIP=1;
endMIP=1000;
argstr=" ";

run("Close All");
pluginDir=getDirectory("plugins");
///argstr="/test/Color_depthMIP_Test/,GMR_45H06_AE_01-20161123_19_B6.h5j,/test/Color_depthMIP_Test/result/,"+pluginDir+",Brain";

if(argstr==" ")
argstr = getArgument();//Argument
args = split(argstr,",");

if (lengthOf(args)>1) {
	dir=args[0];//input directory
	DataName = args[1];//input file Name
	dirCOLOR = args[2];//save directory
	MaskDir = args[3];//Directory of masks.tif
	AnatomicalArea= args [4];//"VNC" or "Brain"
	//chanspec = toLowerCase(args[5]);// channel spec
}
print("Input Dir: "+dir);
print("Output Name: "+DataName);//file name
print("Output dir: "+dirCOLOR);// save location
print("MaskDir: "+MaskDir);

print("AnatomicalArea: "+AnatomicalArea);
//print("Desired mean; "+desiredmean);

savedirext=File.exists(dirCOLOR);

if(savedirext!=1){
	File.makeDirectory(dirCOLOR);
	print("made save directory!");
}

setBatchMode(true);
run("Close All");

expand=false;
if(AnatomicalArea=="VNC")
expand=true;

JFRCexist=File.exists(MaskDir);
if(JFRCexist==0){
	print("MaskDir is not exist; "+MaskDir);
	
	logsum=getInfo("log");
	filepath=dirCOLOR+"Color_depthMIP_log.txt";
	File.saveString(logsum, filepath);
	
	run("Quit");
}


mipfunction(dir,DataName, dirCOLOR, AutoBRV,MIPtype,desiredmean,CropYN,usingLUT,lowerweight,lowthreM,startMIP,endMIP,unsharp,expand,secondjump,MaskDir);


logsum=getInfo("log");
filepath=dirCOLOR+"Color_depthMIP_log.txt";
File.saveString(logsum, filepath);
run("Quit");



/////////Function//////////////////////////////////////////////////////////////////
function mipfunction(dir,listP, dirCOLOR, AutoBRV,MIPtype,desiredmean,CropYN,usingLUT,lowerweight,lowthreM,startMIP,endMIP,unsharp,expand,secondjump,MaskDir){ 
	
	KeiNrrdShrink=0;
	GradientDim=false;
	CLAHE=true;
	colorcoding=true;
	neuronimg=0;
	autothre=0;//1 is FIJI'S threshold, 0 is DSLT thresholding
	colorscale=true;
	reverse0=false;
	multiDSLT=1;// 1 is multi step DSLT for better thresholding sensitivity
	
	IJ.redirectErrorMessages();
	
	path = dir+listP;
	PathExt=File.exists(path);
	
	if(PathExt==1){
		open(path);// for tif, comp nrrd, lsm", am, v3dpbd, mha
		print(listP+"  opened");
	}else{
		print("File is not existing; "+path);
		logsum=getInfo("log");
		filepath=dirCOLOR+"Color_depthMIP_log.txt";
		File.saveString(logsum, filepath);
		
		run("Quit");
	}
	//	}else{
	//		print("file size is too small, "+filesize/10000000+" MB, less than 60MB.  "+listP+"	 ;	 "+i+" / "+endn);
	//	print(listP+"	 ;	 "+i+" / "+endn+"  too small");
	//	}
	
	
	
	if(nImages>0){
		
		bitd=bitDepth();
		totalslice=nSlices();
		origi=getTitle();
		getDimensions(width, height, channels, slices, frames);
		getVoxelSize(VxWidth, VxHeight, VxDepth, VxUnit);
		
		if(bitd==32){
			setMinAndMax(0, 20);
			run("8-bit");
			bitd=8;
			unsharp="Max";//"NA", "Unsharp", "Max"
		}
		
		
		print("Channel number; "+channels);
		if(bitd==8)
		print("8bit file");
		
		if(channels>1 || bitd==24)
		run("Split Channels");
		titlelist=getList("image.titles");
		imageNum=nImages();
		print("imageNum; "+imageNum);
		
		
		
		for(MIPtry=1; MIPtry<=imageNum; MIPtry++){
			
			if(channels==3 || channels==2 ||  channels==4 || bitd==24){
				selectWindow(titlelist[MIPtry-1]);
				neuronCH=getTitle();
				NeuronID=getImageID();
				neuronimg="C"+MIPtry+"-";
				
				//	neuronCH=neuronimg+origi;
			}
			
			
			if(channels!=0){
				stack=getImageID();
				stackSt=getTitle();
			}
			
			BasicMIP=newArray(bitd,0,stack,GradientDim,stackSt);
			basicoperation(BasicMIP);//rename MIP.tif
			
			
			MIP=getImageID();
			DefMaxValue=BasicMIP[1];//actual max value in stack
			sigsize=0;
			
			print("basicoperation done");
			
			if(AutoBRV==1){//to get brightness value from MIP
				selectImage(MIP);
				briadj=newArray(desiredmean, 0, 0, 0,lowerweight,lowthreM,autothre,DefMaxValue,MIP,stack,multiDSLT,secondjump);
				autobradjustment(briadj);
				applyV=briadj[2];
				sigsize=briadj[1];
				sigsizethre=briadj[3];
				sigsizethre=round(sigsizethre);
				sigsize=round(sigsize);
				
				if(isOpen("test.tif")){
					selectWindow("test.tif");
					close();
				}
				
			}//	if(AutoBRV==1){
			
			if(colorcoding==true){
				
				if(channels==1)
				selectWindow(origi);
				
				if(channels==2 || channels==3 || channels==4)
				selectWindow(neuronCH);
				
				if(unsharp=="Unsharp")
				run("Unsharp Mask...", "radius=1 mask=0.35 stack");
				else if(unsharp=="Max")
				run("Maximum...", "radius=1.5 stack");
				
				if(AutoBRV==1)
				brightnessapply(applyV, bitd,lowerweight,lowthreM,stack,MaskDir);
				
				if(reverse0==1)
				run("Reverse");
				
				if(usingLUT=="royal")
				stackconcatinate();
				
				if(AutoBRV==0){
					applyV=255;
					if(bitd==16){
						setMinAndMax(0, DefMaxValue);
						run("8-bit");
					}
				}
				
				ColorCoder(slices, applyV, width, AutoBRV, bitd, CLAHE, colorscale, reverse0, colorcoding, usingLUT,DefMaxValue,startMIP,endMIP,expand);
				
				if(AutoBRV==1){
					if(sigsize>9)
					DSLTst="_DSLT";
					else if(sigsize<10)
					DSLTst="_DSLT0";
					
					if(sigsizethre>9)
					threST="_thre";
					else if (sigsizethre<10)
					threST="_thre0";
					
					if(bitd==8){
						if(applyV<100)
						applyVST="_0";
						else
						applyVST="_";
					}else if(bitd==16){
						if(applyV<1000)
						applyVST="_0";
						else if (applyV>999)
						applyVST="_";
						else if(applyV<100)
						applyVST="_00";
					}
				}
				
				if(CropYN==true)
				CropOP(MIPtype,applyV,colorscale);
				
				TrueMaxValue=0;
				if(DefMaxValue<4096){
					
					TrueMaxValue=4095;
					if(DefMaxValue<256)
					TrueMaxValue=255;
					
				}else if(DefMaxValue>4095)
				TrueMaxValue=65535;
				
				if(imageNum==1){
					if(AutoBRV==1){//saveAs("PNG", dirCOLOR+DataName+"_MIP.png");
						//save(dirCOLOR+DataName+applyVST+applyV+DSLTst+sigsize+threST+sigsizethre+".tif");
						saveAs("PNG", dirCOLOR+DataName+"_CH"+MIPtry+"_MIP.png");
						File.saveString("applied.brightness="+applyV+" / "+TrueMaxValue+"\n"+"dslt.signal.amount="+sigsize+"\n"+"thresholding.signal.amount="+sigsizethre, dirCOLOR+DataName+"_CH"+MIPtry+"_MIP.properties");
					}else
					saveAs("PNG", dirCOLOR+DataName+"_CH"+MIPtry+"_MIP.png");
					
					
				}else{
					if(AutoBRV==1){
						//save(dirCOLOR+DataName+"_CH"+MIPtry+applyVST+applyV+DSLTst+sigsize+threST+sigsizethre+".tif");
						saveAs("PNG", dirCOLOR+DataName+"_CH"+MIPtry+"_MIP.png");
						File.saveString("applied.brightness="+applyV+" / "+TrueMaxValue+"\n"+"dslt.signal.amount="+sigsize+"\n"+"thresholding.signal.amount="+sigsizethre, dirCOLOR+DataName+"_CH"+MIPtry+"_MIP.properties");
					}else
					saveAs("PNG", dirCOLOR+DataName+"_CH"+MIPtry+"_MIP.png");
					
				}
				
				close();
				
				if(isOpen("MIP.tif")){
					selectWindow("MIP.tif");
					close();
				}
				
				selectWindow("Original_Stack.tif");
				close();
				
				if(channels==4){
					OpenImage=nImages(); OpenTitlelist=getList("image.titles");
					for(iImage=0; iImage<OpenImage; iImage++){
						//		print("OpenImage; "+OpenTitlelist[iImage]);
						DontClose=0;
						for(sameornot=0; sameornot<titlelist.length; sameornot++){
							
							if(OpenTitlelist[iImage]==titlelist[sameornot])
							DontClose=1;
						}
						if(DontClose==0){
							selectWindow(OpenTitlelist[iImage]);
							close();
						}
					}
				}//if(channels>1){
			}//if(colorcoding==1){
			
		}//	for(MIPtry=1; MIPtry<=imageNum; MIPtry++){
		run("Close All");
		
		
	}//	if(nImages>0){
} //function mipfunction(mipbatch) { 
///////////////////////////////////////////////////////////////
function autobradjustment(briadj){
	DOUBLEdslt=0;
	desiredmean=briadj[0];
	lowerweight=briadj[4];
	lowthreM=briadj[5];
	autothre=briadj[6];
	DefMaxValue=briadj[7];
	MIP=briadj[8];
	stack=briadj[9];
	multiDSLT=briadj[10];
	secondjump=briadj[11];
	
	if(autothre==1)//Fiji Original thresholding
	run("Duplicate...", "title=test.tif");
	
	bitd=bitDepth();
	run("Properties...", "channels=1 slices=1 frames=1 unit=px pixel_width=1 pixel_height=1 voxel_depth=1");
	getDimensions(width2, height2, channels, slices, frames);
	totalpix=width2*height2;
	
	run("Select All");
	if(bitd==8){
		run("Copy");
	}
	
	if(bitd==16){
		setMinAndMax(0, DefMaxValue);
		run("Copy");
	}
	/////////////////////signal size measurement/////////////////////
	selectImage(MIP);
	run("Duplicate...", "title=test2.tif");
	setAutoThreshold("Triangle dark");
	getThreshold(lower, upper);
	setThreshold(lower, DefMaxValue);//is this only for 8bit??
	
	run("Convert to Mask", "method=Triangle background=Dark black");
	
	selectWindow("test2.tif");
	
	if(bitd==16)
	run("8-bit");
	
	run("Create Selection");
	getStatistics(areathre, mean, min, max, std, histogram);
	if(areathre!=totalpix){
		if(mean<200){
			selectWindow("test2.tif");
			run("Make Inverse");
		}
	}
	getStatistics(areathre, mean, min, max, std, histogram);
	close();//test2.tif
	
	
	if(areathre/totalpix>0.4){
		
		selectImage(MIP);
		
		run("Duplicate...", "title=test2.tif");
		setAutoThreshold("Moments dark");
		getThreshold(lower, upper);
		setThreshold(lower, DefMaxValue);
		
		run("Convert to Mask", "method=Moments background=Dark black");
		
		selectWindow("test2.tif");
		
		if(bitd==16)
		run("8-bit");
		
		run("Create Selection");
		getStatistics(areathre, mean, min, max, std, histogram);
		if(areathre!=totalpix){
			if(mean<200){
				selectWindow("test2.tif");
				run("Make Inverse");
			}
		}
		getStatistics(areathre, mean, min, max, std, histogram);
		close();//test2.tif
		
	}//if(area/totalpix>0.4){
	
	/////////////////////Fin signal size measurement/////////////////////
	
	selectImage(MIP);
	
	dsltarray=newArray(autothre, bitd, totalpix, desiredmean, 0,multiDSLT);
	DSLTfun(dsltarray);
	desiredmean=dsltarray[3];
	area2=dsltarray[4];
	//////////////////////
	
	selectImage(MIP);//MIP
	getMinAndMax(min1, max);
	if(max>4095){//16bit
		minus=0;
		getMinAndMax(min, max1);
		while(max<65530){
			minus=minus+100;
			selectImage(MIP);//MIP
			run("Duplicate...", "title=MIPDUP.tif");
			
			
			//		print("premax; "+max+"premin; "+min);
			run("Histgram stretch", "lower=0 higher="+max1-minus+"");//histogram stretch	\
			getMinAndMax(min, max);
			//		print("postmax; "+max+"postmin; "+min);
			close();
		}
		
		//		print("minus; "+minus);
		
		selectImage(MIP);//MIP
		run("Histgram stretch", "lower="+min1+" higher="+max1-minus-100+"");//histogram stretch	\
		getMinAndMax(min, max);
		//		print("after max; "+max);
		
		selectImage(stack);
		run("Histgram stretch", "lower="+min1+" higher="+max1-minus-100+" 3d");//histogram stretch	
		selectImage(MIP);//MIP
	}//if(max>4095){//16bit
	
	run("Mask Brightness Measure", "mask=test.tif data=MIP.tif desired="+desiredmean+"");
	selectImage(MIP);//MIP
	
	fff=getTitle();
	print("fff 1202; "+fff);
	applyvv=newArray(1,bitd,stack,MIP);
	applyVcalculation(applyvv);
	applyV=applyvv[0];
	
	selectImage(MIP);//MIP
	
	
	if(fff=="MIP.tif"){
		if(bitd==16)
		applyV=400;
		
		if(bitd==8)
		applyV=40;
		
	}
	
	rename("MIP.tif");//MIP
	
	selectWindow("test.tif");//new window from DSLT
	close();
	/////////////////2nd time DSLT for picking up dimmer neurons/////////////////////
	
	
	if(applyV>50 && applyV<secondjump && bitd==8 && DOUBLEdslt==1){
		applyVpre=applyV;
		selectImage(MIP);
		
		setMinAndMax(0, applyV);
		
		run("Duplicate...", "title=MIPtest.tif");
		
		setMinAndMax(0, applyV);
		run("Apply LUT");
		maxcounts=0; maxi=0;
		getHistogram(values, counts,  256);
		for(i=0; i<100; i++){
			Val=counts[i];
			
			if(Val>maxcounts){
				maxcounts=counts[i];
				maxi=i;
			}
		}
		
		changelower=maxi*lowerweight;
		if(changelower<1)
		changelower=1;
		
		selectWindow("MIPtest.tif");
		close();
		
		selectImage(MIP);
		setMinAndMax(0, applyV);
		run("Apply LUT");
		
		setMinAndMax(changelower, 255);
		run("Apply LUT");
		
		print("Double DSLT");
		//	run("Multibit thresholdtwo", "w/b=Set_black max=207 in=[In macro]");
		
		desiredmean=secondjump;//230 for GMR
		
		dsltarray=newArray(autothre, bitd, totalpix, desiredmean, 0, multiDSLT);
		DSLTfun(dsltarray);//will generate test.tif DSLT thresholded mask
		desiredmean=dsltarray[3];
		area2=dsltarray[4];
		
		selectImage(MIP);//MIP
		
		run("Mask Brightness Measure", "mask=test.tif data=MIP.tif desired="+desiredmean+"");
		
		selectImage(MIP);//MIP
		
		fff=getTitle();
		print("fff 1279; "+fff);
		
		applyvv=newArray(1,bitd,stack,MIP);
		applyVcalculation(applyvv);
		applyV=applyvv[0];
		
		if(applyVpre<applyV){
			applyV=applyVpre;
			print("previous applyV is brighter");
		}
		
		selectImage(MIP);//MIP
		rename("MIP.tif");//MIP
		close();
		
		selectWindow("test.tif");//new window from DSLT
		close();
	}//	if(applyV>50 && applyV<150 && bitd==8){
	
	
	sigsize=area2/totalpix;
	if(sigsize==1)
	sigsize=0;
	
	sigsizethre=areathre/totalpix;
	
	print("Signal brightness; 	"+applyV+"	 Signal Size DSLT; 	"+sigsize+"	 Sig size threshold; 	"+sigsizethre);
	briadj[1]=(sigsize)*100;
	briadj[2]=applyV;
	briadj[3]=sigsizethre*100;
}//function autobradjustment

function DSLTfun(dsltarray){
	
	autothre=dsltarray[0];
	bitd=dsltarray[1];
	totalpix=dsltarray[2];
	desiredmean=dsltarray[3];
	multiDSLT=dsltarray[5];
	
	if(autothre==0){//DSLT
		
		if(bitd==8)
		//	run("DSLT ", "radius_r_max=4 radius_r_min=2 radius_r_step=2 rotation=6 weight=14 filter=GAUSSIAN close=None noise=5px");
		run("DSLT ", "radius_r_max=8 radius_r_min=2 radius_r_step=2 rotation=6 weight=3 filter=GAUSSIAN close=None noise=7px");
		
		if(bitd==16){
			run("DSLT ", "radius_r_max=10 radius_r_min=2 radius_r_step=2 rotation=6 weight=130 filter=GAUSSIAN close=None noise=9px");
			
			run("16-bit");
			run("Mask255 to 4095");
		}
		rename("test.tif");//new window from DSLT
	}//if(autothre==0){//DSLT
	
	
	selectWindow("test.tif");
	
	//setBatchMode(false);
	//	updateDisplay();
	//	a
	
	run("Duplicate...", "title=test2.tif");
	selectWindow("test2.tif");
	
	if(bitd==16)
	run("8-bit");
	
	run("Create Selection");
	getStatistics(area1, mean, min, max, std, histogram);
	
	
	if(area1!=totalpix){
		if(mean<200){
			selectWindow("test2.tif");
			run("Make Inverse");
			getStatistics(area1, mean, min, max, std, histogram);
		}
	}
	
	close();//test2.tif
	
	//	print("Area 1412;  "+area+"   mean; "+mean);
	
	presize=area1/totalpix;
	
	if(area1==totalpix){
		presize=0.0001;
		print("Equal");
	}
	print("Area 1st time;  "+area1+"   mean; "+mean+"  totalpix; "+totalpix+"   presize; "+presize+"   bitd; "+bitd);
	realArea=area1;
	
	if(multiDSLT==1){
		if(presize<0.05){// set DSLT more sensitive, too dim images, less than 5%
			selectWindow("test.tif");//new window from DSLT
			close();
			
			if(isOpen("test.tif")){
				selectWindow("test.tif");
				close();
			}
			
			selectWindow("MIP.tif");//MIP
			
			//			setBatchMode(false);
			//	updateDisplay();
			//	a
			
			if(bitd==8){
				//run("DSLT ", "radius_r_max=4 radius_r_min=2 radius_r_step=2 rotation=6 weight=5 filter=GAUSSIAN close=None noise=10px");
				run("DSLT ", "radius_r_max=8 radius_r_min=2 radius_r_step=2 rotation=8 weight=2 filter=GAUSSIAN close=None noise=7px");
				
			}
			if(bitd==16)
			run("DSLT ", "radius_r_max=10 radius_r_min=2 radius_r_step=2 rotation=8 weight=60 filter=GAUSSIAN close=None noise=9px");
			
			run("Create Selection");
			getStatistics(area2, mean, min, max, std, histogram);
			if(area2!=totalpix){
				if(mean<200){
					run("Make Inverse");
					print("Inverted 1430");
					getStatistics(area2, mean, min, max, std, histogram);
				}
			}
			
			if(bitd==16){
				run("16-bit");
				run("Mask255 to 4095");
			}//if(bitd==16){
			
			
			rename("test.tif");//new window from DSLT
			run("Select All");
			print("2nd measured size;"+area2);
			realArea=area2;
			
			sizediff=(area2/totalpix)/presize;
			print("2nd_sizediff; 	"+sizediff);
			if(bitd==16){
				if(sizediff>1.3){
					repeatnum=(sizediff-1)*10;
					oriss=1;
					
					for(rep=1; rep<repeatnum+1; rep++){
						oriss=oriss+oriss*0.11;
					}
					weight=oriss/3;
					desiredmean=desiredmean+(desiredmean/4)*weight;
					desiredmean=round(desiredmean);
					
					if(desiredmean>secondjump || desiredmean==NaN)
					desiredmean=secondjump;
					
					print("desiredmean; 	"+desiredmean+"	 sizediff; "+sizediff+"	 weight *25%;"+(desiredmean/4)*weight);
				}
			}else if(bitd==8){
				if(sizediff>2){
					repeatnum=(sizediff-1);//*10
					oriss=1;
					
					for(rep=1; rep<=repeatnum+1; rep++){
						oriss=oriss+oriss*0.08;
					}
					weight=oriss/7;
					desiredmean=desiredmean+(desiredmean/7)*weight;
					desiredmean=round(desiredmean);
					
					if(desiredmean>225)
					desiredmean=secondjump;
					
					print("desiredmean; 	"+desiredmean+"	 sizediff; "+sizediff+"	 weight *25%;"+(desiredmean/4)*weight);
				}
			}
		}//if(area2/totalpix<0.01){
	}//	if(multiDSLT==1){
	
	dsltarray[3]=desiredmean;
	dsltarray[4]=realArea;
}//function DSLTfun

function applyVcalculation(applyvv){
	bitd=applyvv[1];
	stack=applyvv[2];
	MIP=applyvv[3];
	
	selectImage(MIP);//MIP
	applyV=getTitle();
	
	if(applyV=="MIP.tif")
	applyV=200;
	
	applyV=round(applyV);
	run("Select All");
	getMinAndMax(min, max);
	
	//print("applyV max; "+max+"   bitd; "+bitd+"   applyV; "+applyV);
	
	if(bitd==8){
		applyV=255-applyV;
		
		if(applyV==0)
		applyV=255;
		else if(applyV<20)
		applyV=20;
	}else if(bitd==16){
		
		if(max<=4095)
		applyV=4095-applyV;
		
		if(max>4095)
		applyV=65535-applyV;
		
		if(applyV==0)
		applyV=max;
		else if(applyV<150)
		applyV=1500;
	}
	applyvv[0]=applyV;
}

function stackconcatinate(){
	
	getDimensions(width2, height2, channels2, slices, frames);
	addingslices=slices/10;
	addingslices=round(addingslices);
	
	for(GG=1; GG<=addingslices; GG++){
		setSlice(nSlices);
		run("Add Slice");
	}
	run("Reverse");
	for(GG=1; GG<=addingslices; GG++){
		setSlice(nSlices);
		run("Add Slice");
	}
	run("Reverse");
}

function brightnessapply(applyV, bitd,lowerweight,lowthreM,stack,MaskDir){
	stacktoApply=getTitle();
	
	
	if(bitd==8){
		if(applyV<255){
			setMinAndMax(0, applyV);
			
			if(applyV<secondjump){
				run("Z Project...", "projection=[Max Intensity]");
				MIPapply=getTitle();
				
				setMinAndMax(0, applyV);
				run("Apply LUT");
				
				if(getHeight==512 || getHeight==592){
					if(getWidth==1024 || getWidth==1184){
						tissue="Brain";
						BackgroundMask (tissue,MaskDir,MIPapply,bitd);
					}
				}else if (getHeight==1024 || getHeight==1100 ){// VNC
					if(getWidth==512){
						
						tissue="VNC";
						BackgroundMask (tissue,MaskDir,MIPapply,bitd);
					}
				}//	if(getHeight==512 && getWidth==1024){
				
				if(lowthreM=="Peak Histogram"){//lowthre measurement
					maxcounts=0; maxi=0;
					getHistogram(values, counts,  256);
					for(i3=0; i3<200; i3++){
						
						sumave=0;
						for(peakave=i3; peakave<i3+5; peakave++){
							Val=counts[peakave];
							sumave=sumave+Val;
						}
						aveave=sumave/5;
						
						if(aveave>maxcounts){
							
							maxcounts=aveave;
							maxi=i3+2;
							print("GrayValue; "+i3+"  "+aveave+"  maxi; "+maxi);
						}
					}//for(i3=0; i3<200; i3++){
					if(maxi!=2)
					changelower=maxi*lowerweight;
					else
					changelower=0;
					
				}else if(lowthreM=="Auto-threshold"){
					setAutoThreshold("Huang dark");
					getThreshold(lower, upper);
					resetThreshold();
					changelower=lower*lowerweight;
				}
				
				selectWindow(MIPapply);
				close();
				
				selectWindow(stacktoApply);
				setMinAndMax(0, applyV);//brightness adjustment
				run("Apply LUT", "stack");
				
				
				if(changelower>0){
					changelower=round(changelower);
					
					setMinAndMax(changelower, 255);//lowthre cut
					run("Apply LUT", "stack");
				}else
				changelower=0;
				print("  lower threshold; 	"+changelower);
			}
		}
	}
	if(bitd==16){
		
		applyV2=applyV;
		if(applyV==4095)
		applyV2=4094;
		
		selectImage(stack);
		run("Z Project...", "projection=[Max Intensity]");
		MIP2=getImageID();
		getMinAndMax(min, max);
		
		minus=0;
		while(max<65530){
			minus=minus+50;
			selectImage(MIP2);//MIP
			run("Duplicate...", "title=MIPDUP.tif");
			
			//		print("premax; "+max+"premin; "+min);
			run("Histgram stretch", "lower="+min+" higher="+applyV2-minus+"");//histogram stretch	
			getMinAndMax(min, max);
			//	print("postmax; "+max+"postmin; "+min);
			close();
		}
		selectImage(MIP2);//MIP
		close();
		selectImage(stack);
		
		run("Histgram stretch", "lower=0 higher="+applyV2-minus+" 3d");//histogram stretch
		
		
		countregion=65500;
		
		run("Z Project...", "projection=[Max Intensity]");
		MIPthresholding=getTitle();
		//	setBatchMode(false);
		//	updateDisplay();
		//	a
		
		if(getHeight==512 || getHeight==592){
			if(getWidth==1024 || getWidth==1184){
				tissue="Brain";
				BackgroundMask (tissue,MaskDir,MIPthresholding,bitd);
			}
		}else if (getHeight==1024 || getHeight==1100){
			if(getWidth==512){
				tissue="VNC";
				BackgroundMask (tissue,MaskDir,MIPthresholding,bitd);
			}
		}//	if(getHeight==512 && getWidth==1024){
		
		maxi=0;
		if(lowthreM=="Peak Histogram"){
			maxcounts=0;
			getHistogram(values, counts,  65530);
			for(i3=5; i3<countregion; i3++){
				
				sumVal20=0; 
				if(i3<countregion-20){
					for(aveval=i3; aveval<i3+20; aveval++){
						Val20=counts[aveval];
						
						sumVal20=sumVal20+Val20;
					}
					AveVal20=sumVal20/20;
					
					if(AveVal20>maxcounts){
						maxcounts=AveVal20;
						maxi=i3+10;
					}
				}//if(i3<280){
			}
			changelower=maxi*lowerweight;
			print("lower threshold; 	"+changelower+"   maxi; "+maxi);
		}//if(lowthreM=="Peak Histogram"){
		
		if(lowthreM=="Auto-threshold"){
			
			setAutoThreshold("Huang dark");
			getThreshold(lower, upper);
			resetThreshold();
			
			
			changelower=lower-lower/4;
			
			if(changelower>250)
			changelower=150;
		}//if(lowthreM=="Auto-threshold"){
		
		close();
		selectWindow(stacktoApply);
		changelower=round(changelower);
		setMinAndMax(changelower, 65535);//subtraction
		
		run("8-bit");
	}//if(bitd==16){
}//function brightnessapply(applyV, bitd){

function basicoperation(BasicMIP){
	//	run("Mean Thresholding", "-=30 thresholding=Subtraction");//new plugins
	bitd=BasicMIP[0];
	stack=BasicMIP[2];
	GradientDim=BasicMIP[3];
	stackSt=BasicMIP[4];
	
	
	if(GradientDim==true && bitd==8){
		
		selectWindow(stackSt);
		run("16-bit");
		
		LF=10; TAB=9; swi=0; swi2=0; testline=0;
		filepath0=getDirectory("temp");
		filepath2=filepath0+"Gradient.txt";
		exi2=File.exists(filepath2);
		GradientPath=0;
		
		if(exi2==1){
			print("exi2==1");
			s1 = File.openAsRawString(filepath2);
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
					GradientPath = String.buffer;
				}
			}
			print("GradientPath; "+GradientPath);
		}//if(exi2==1){
		
		tempmaskEXI=File.exists(GradientPath);
		if(tempmaskEXI==1){
			open(GradientPath);
		}else{
			Gradient=getDirectory("Choose a Directory for Gradient.tif");
			GradientPath=Gradient+"Gradient.tif";
			open(GradientPath);
		}
		
		GradientID=getImageID();
		
		File.saveString(GradientPath+"\n", filepath2);
		//	print("Image cal pre");
		imageCalculator("Multiply stack", ""+stackSt+"", "Gradient.tif");
		//	print("Image cal done");
		selectWindow("Gradient.tif");
		close();
		
		selectWindow(stackSt);
		run("Z Project...", "projection=[Max Intensity]");
		getMinAndMax(min, max);
		close();
		
		selectImage(stack);
		setMinAndMax(0, max);
		run("8-bit");
		max=255;
	}else{
		
		if(bitd==16){
			run("Z Project...", "projection=[Max Intensity]");
			getMinAndMax(min, max);
			close();
			
			selectImage(stack);
			setMinAndMax(0, max);
		}
		if(bitd==8)
		max=255;
	}
	run("Z Project...", "projection=[Max Intensity]");
	rename("MIP.tif");
	if(bitd==16)
	resetMinAndMax();
	
	//updateDisplay();
	//setBatchMode(false);
	//a
	
	BasicMIP[1]=max;
}

function ColorCoder(slicesOri, applyV, width, AutoBRV, bitd, CLAHE, GFrameColorScaleCheck, reverse0, colorcoding, usingLUT,DefMaxValue,startMIP,endMIP,expand) {//"Time-Lapse Color Coder" 
	
	if(usingLUT=="royal")
	var Glut = "royal";	//default LUT
	
	if(usingLUT=="PsychedelicRainBow2")
	var Glut = "PsychedelicRainBow2";	//default LUT
	
	var Gstartf = 1;
	
	getDimensions(width, height, channels, slices, frames);
	rename("Original_Stack.tif");
	
	//	setBatchMode(false);
	
	
	
	if(frames>slices)
	slices=frames;
	
	newImage("lut_table.tif", "8-bit black", slices, 1, 1);
	for(xxx=0; xxx<slices; xxx++){
		per=xxx/slices;
		colv=255*per;
		colv=round(colv);
		setPixel(xxx, 0, colv);
	}
	
	run(Glut);
	run("RGB Color");
	
	selectWindow("Original_Stack.tif");
	//print("1992 pre MIP");
	run("Z Code Stack HO", "data=Original_Stack.tif 1px=lut_table.tif");
	
	selectWindow("Depth_color_RGB.tif");
	//print("1996 post MIP");
	if(endMIP>nSlices)
	endMIP=nSlices;
	
	if(usingLUT=="royal"){
		addingslices=slicesOri/10;
		addingslices=round(addingslices);
		startMIP=addingslices+startMIP;
		endMIP=addingslices+endMIP;
		
		if(endMIP>nSlices)
		endMIP=nSlices;
		
		run("Z Project...", "start="+startMIP+" stop="+endMIP+" projection=[Max Intensity] all");
	}
	
	if(usingLUT=="PsychedelicRainBow2")
	run("MIP right color", "start="+startMIP+" end="+endMIP+"");
	
	max=getTitle();
	
	selectWindow("Depth_color_RGB.tif");
	close();
	
	selectWindow("lut_table.tif");
	close();
	
	selectWindow(max);
	rename("color.tif");
	if (GFrameColorScaleCheck==1){
		CreateScale(Glut, Gstartf, slicesOri, reverse0);
		
		selectWindow("color time scale");
		run("Select All");
		run("Copy");
		close();
	}
	
	selectWindow("color.tif");
	run("Properties...", "channels=1 slices=1 frames=1 unit=pixel pixel_width=1.0000 pixel_height=1.0000 voxel_depth=0 global");
	if(CLAHE==1 && usingLUT=="royal" )
	run("Enhance Local Contrast (CLAHE)", "blocksize=127 histogram=256 maximum=1.5 mask=*None*");
	
	if (GFrameColorScaleCheck==1){
		
		if(expand==1)
		run("Canvas Size...", "width="+width+" height="+height+90+" position=Bottom-Left zero");
		makeRectangle(width-257, 1, 256, 48);
		run("Paste");
		
		if(AutoBRV==1){
			setFont("Arial", 20, " antialiased");
			setColor("white");
			if(applyV>999 && applyV<10000){
				
				if(bitd==16 && DefMaxValue>4095)
				drawString("Max: 0"+applyV+" /65535", width-210, 78);
				
				if(bitd==16 && DefMaxValue<=4095)
				drawString("Max: "+applyV+" /4095", width-180, 78);
				
			}else if(applyV>99 && applyV<1000){
				if(bitd==8)
				drawString("Max: "+applyV+" /255", width-180, 78);
				
				if(bitd==16 && DefMaxValue>4095)
				drawString("Max: 00"+applyV+" /65535", width-210, 78);
				
				if(bitd==16 && DefMaxValue<=4095)
				drawString("Max: 0"+applyV+" /4095", width-180, 78);
				
			}else if(applyV<100){
				if(bitd==8)
				drawString("Max: 0"+applyV+" /255", width-180, 78);
				if(bitd==16 && DefMaxValue<=4095)
				drawString("Max: 00"+applyV+" /4095", width-180, 78);
				if(bitd==16 && DefMaxValue>4095)
				drawString("Max: 000"+applyV+" /65535", width-210, 78);
				
			}else if(applyV>9999){
				drawString("Max: "+applyV+" /65535", width-210, 78);
			}
			setMetadata("Label", applyV+"	 DSLT; 	"+sigsize+"	Thre; 	"+sigsizethre);
		}//if(AutoBRV==1){
	}//if (GFrameColorScaleCheck==1){
	run("Select All");
	
}//function ColorCoder(slicesOri, applyV, width, AutoBRV, bitd) {//"Time-Lapse Color Coder" 

function CreateScale(lutstr, beginf, endf, reverse0){
	ww = 256;
	hh = 32;
	newImage("color time scale", "8-bit White", ww, hh, 1);
	if(reverse0==0){
		for (j = 0; j < hh; j++) {
			for (i = 0; i < ww; i++) {
				setPixel(i, j, i);
			}
		}
	}//	if(reverse0==0){
	
	if(reverse0==1){
		valw=ww;
		for (j = 0; j < hh; j++) {
			for (i = 0; i < ww; i++) {
				setPixel(i, j, valw);
				valw=ww-i;
			}
		}
	}//	if(reverse0==1){
	
	if(usingLUT=="royal"){
		makeRectangle(25, 0, 204, 32);
		run("Crop");
	}
	
	run(lutstr);
	run("RGB Color");
	op = "width=" + ww + " height=" + (hh + 16) + " position=Top-Center zero";
	run("Canvas Size...", op);
	setFont("SansSerif", 12, "antiliased");
	run("Colors...", "foreground=white background=black selection=yellow");
	drawString("Slices", round(ww / 2) - 12, hh + 16);
	
	if(usingLUT=="PsychedelicRainBow2"){
		drawString(leftPad(beginf, 3), 10, hh + 16);
		drawString(leftPad(endf, 3), ww - 30, hh + 16);
	}else{
		drawString(leftPad(beginf, 3), 24, hh + 16);
		drawString(leftPad(endf, 3), ww - 50, hh + 16);
	}
}

function CropOP (MIPtype,applyV,colorscale){
	setPasteMode("Max");
	setForegroundColor(0, 0, 0);
	setFont("Arial", 22);
	
	
	if(MIPtype=="MCFO_MIP"){
		makeRectangle(0, 0, 239, 60);//Line
		run("Copy");
		makeRectangle(195, 455, 239, 60);
		run("Paste");
		
		makeRectangle(6, 58, 129, 26);//AD DBD
		run("Copy");
		
		makeRectangle(606, 482, 129, 26);
		run("Paste");
		
		makeRectangle(197, 0, 617, 512);
		run("Crop");
		setForegroundColor(0, 0, 0);
		makeRectangle(567, 0, 50, 46);
		run("Fill", "slice");
		
		makeRectangle(0, 0, 42, 55);
		run("Fill", "slice");
		
		setFont("Arial", 22); 
		
		setForegroundColor(0, 0, 0);
		makeRectangle(542, 455, 70, 49);
		run("Fill", "slice");
		
		BriValue=round(applyV);
		
		print("BriValue; "+BriValue+"   MIPtype; "+MIPtype);
		if(BriValue>255 && BriValue<4096){
			MaxVal=4095;
			
			if(BriValue<1000)
			BriValue="0"+BriValue;
			
			if(colorscale){
				setForegroundColor(255, 255, 255);
				drawString(BriValue, 543, 483);
				drawString(MaxVal, 543, 509);
				
				setLineWidth(2);
				drawLine(543, 482, 595, 482);
			}//if(colorscale)
			
		}else if(BriValue<256){
			MaxVal=255;
			
			if(BriValue<100)
			BriValue="0"+BriValue;
			
			if(colorscale){
				setForegroundColor(255, 255, 255);
				drawString(BriValue, 543, 483);
				drawString(MaxVal, 543, 509);
				
				setLineWidth(2);
				
				drawLine(543, 482, 581, 482);
			}///if(colorscale){
			//		setBatchMode(false);
			//		updateDisplay();
			//		a
			
		}else if(BriValue>4095){
			MaxVal=65535;
			
			if(BriValue<10000){
				if(BriValue<1000)
				BriValue="00"+BriValue;
				else
				BriValue="0"+BriValue;
			}
			
			if(colorscale){
				setForegroundColor(255, 255, 255);
				drawString(BriValue, 543, 483);
				drawString(MaxVal, 543, 509);
				
				setLineWidth(2);
				drawLine(543, 482, 609, 482);
			}
		}
		
		//	if(DrawName!="NA")
		//	drawString(DrawName, 574, 30);
		
		
	}else if(MIPtype=="Gen1_Gal4"){
		makeRectangle(3, 0, 227, 60);
		run("Copy");
		makeRectangle(195, 455, 227, 60);
		run("Paste");
		
		makeRectangle(833, 49, 149, 43);
		run("Copy");
		
		makeRectangle(308, 482, 149, 43); 
		run("Paste");
		
		makeRectangle(197, 0, 617, 512);
		run("Crop");
		
		makeRectangle(0, 0, 38, 35);
		setForegroundColor(0, 0, 0);
		run("Fill", "slice");
		makeRectangle(567, 0, 50, 46);
		run("Fill", "slice");
	}
	
	setForegroundColor(255, 255, 255);
	setPasteMode("Copy");
}

function BackgroundMask (tissue,MaskDir,MIPapply,bitd){
	MaskName=0;
	if(tissue=="Brain"){
		
		if(getHeight==512)
		MaskName="JFRC2010_Mask.tif";
		
		if(getHeight==592)
		MaskName="JFRC2013_20x_Mask.tif";
		
	}else if (tissue=="VNC"){
		
		if(getHeight==1024)
		MaskName="Mask_VNC_Female.tif";
		
		if(getHeight==1100)
		MaskName="Mask_VNC_Male.tif";
	}
	openPath=MaskDir+MaskName;
	print("Mask path; "+openPath);
	maskExist=File.exists(openPath);
	if(maskExist==1){
		print("Used a Mask for background subtraction.");
		open(openPath);
		filename=getTitle();
		
		if(bitd==8)
		run("8-bit");
		
		imageCalculator("Max", MIPapply,filename);
		
		selectWindow(filename);
		close();
	}
	
	selectWindow(MIPapply);
}

function leftPad(n, width) {
	s = "" + n;
	while (lengthOf(s) < width)
	s = "0" + s;
	return s;
}

"done"
