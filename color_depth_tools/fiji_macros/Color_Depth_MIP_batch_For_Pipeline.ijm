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
//argstr="/Users/otsunah/Downloads/Workstation/,76F06_AE_01-20190409_61_D5-REG_UNISEX_ColorMIP_HR.h5j,/Users/otsunah/test/Color_depthMIP_Test/result/,/Users/otsunah/test/Color_depthMIP_Test/Template_MIP/,Brain";

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

filesep=lastIndexOf(DataName,"/");
if(filesep!=-1)
DataName=substring(DataName,filesep+1,lengthOf(DataName));

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
function mipfunction(dir,DataName, dirCOLOR, AutoBRV,MIPtype,desiredmean,CropYN,usingLUT,lowerweight,lowthreM,startMIP,endMIP,unsharp,expand,secondjump,MaskDir){ 
	
	KeiNrrdShrink=0;
	GradientDim=false;
	CLAHE=true;
	colorcoding=true;
	neuronimg=0;
	autothre=0;//1 is FIJI'S threshold, 0 is DSLT thresholding
	colorscale=true;
	reverse0=false;
	multiDSLT=1;// 1 is multi step DSLT for better thresholding sensitivity
	easyADJ=false;
	DSLTver="Line";//"normal";
	GammaON=false;
	
	path = dir+DataName;
	PathExt=File.exists(path);
	filepath=dirCOLOR+"Color_depthMIP_log.txt";
	
	if(PathExt==1){
		
		titlelistOri=getList("image.titles");
		IJ.redirectErrorMessages();
		
		open(path);// for tif, comp nrrd, lsm", am, v3dpbd, mha
		
		titlelistAfter=getList("image.titles");
		
		if(titlelistOri.length == titlelistAfter.length){
			print("Error: The file cannot open 109; "+MaskPath);
			logsum=getInfo("log");
			File.saveString(logsum, filepath);
			run("Quit");
		}
		
		print(DataName+"  opened");
	}else{
		print("File is not existing; "+path);
		logsum=getInfo("log");
		
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
			
			logsum=getInfo("log");
			File.saveString(logsum, filepath);
			
			if(channels==3 || channels==2 ||  channels==4 || bitd==24){
				selectWindow(titlelist[MIPtry-1]);
				neuronCH=getTitle();
				NeuronID=getImageID();
				neuronimg="C"+MIPtry+"-";
				
				//	neuronCH=neuronimg+origi;
			}
			MedianSub=40;
			if(channels!=0){
				
				if(bitd==32 || unsharp=="Max"){
					setMinAndMax(0, 1);
					run("8-bit");
					bitd=8;
					unsharp="Max";//"NA", "Unsharp", "Max"
					DefMaxValue=1;
					AutoBRV=0;
				}
				
				stack=getImageID();
				stackSt=getTitle();
				
				MaskName2D=""; 	zeroexi=0;
				Mask3D="";
				
				///// pre- brightness adjustment ////////////////
				if(bitd==8){
					print("8bit file");
					desiredmean=200;
					lowerweight=0.3;
					secondjump=245;
					MedianSub=0;
					DefMaxValue=255;
					
					run("Z Project...", "projection=[Max Intensity]");
					run("Enhance Contrast", "saturated=0.3");
					getMinAndMax(min, Inimax);
					close();
					
					if(Inimax!=255){
						selectWindow(stackSt);
						setMinAndMax(0, Inimax);
						run("Apply LUT", "stack");
					}
					
					run("Max value");
					logsum=getInfo("log");
					maxStartindex=lastIndexOf(logsum,"Maxvalue");
					maxEndindex=lastIndexOf(logsum,"Minvalue");
					maxvalue=substring(logsum, maxStartindex+10, maxEndindex-2);
					maxvalue=round(maxvalue);
					
					print("3D stack brightness adjusted; maxvalue; "+maxvalue+"  Inimax; "+Inimax);
					
				}//if(bitd==8){
				
				if(bitd==16){
					getDimensions(width, height, channels2, slices, frames);
					print("stack dimension; width= "+width+"  height= "+height+"  slices= "+slices);
					
					run("Z Project...", "projection=[Max Intensity]");
					MIPtitle= getTitle();
					
					resetMinAndMax();
					getMinAndMax(Inimin, max);
					
					if(max>255 && max<4096)
					DefMaxValue=4095;
					else if (max>4095)
					DefMaxValue=65535;
					else if (max<256)
					DefMaxValue=255;
					
					if(max<=255){// 8 bit file in 16bit format
						desiredmean=205;
						lowerweight=0;// mip function subtraction
						
						MedianSub=100;
						print("desiremean 205  16bit file with 8bit data");
					}
					
					
					run("Enhance Contrast", "saturated=0.3");
					getMinAndMax(min, Inimax);
					
					RealInimax=Inimax;
					
					if(DefMaxValue==255){
						Inimax=round(Inimax*6);
						print("DefMaxValue = 255, 16 bit");
					}
					
					if(DefMaxValue==4095){
						if(Inimax<200 && Inimax>100)
						Inimax=Inimax*3.5;
						else if (Inimax>=200 && Inimax<300)
						Inimax=round(Inimax*3);
						else if (Inimax<100)
						Inimax=Inimax*4;
						else if (Inimax>=300 && Inimax<500)
						Inimax=Inimax*2;
					}
					
					if(DefMaxValue==65535){
						if(Inimax<3200 && Inimax>1600)
						Inimax=Inimax*3;
						else if (Inimax>=3200 && Inimax<4800)
						Inimax=round(Inimax*2.5);
						else if (Inimax<1600)
						Inimax=Inimax*4;
						else if (Inimax>=4800 && Inimax<8000)
						Inimax=Inimax*2;
					}
					
					
					selectWindow(MIPtitle);
					
					setMinAndMax(0, Inimax);
					run("Apply LUT");
					
					if(width==1401 && height==2740 && slices==402){//1401x2740x402, JRC2018 63x UNISEX
						MaskName2D="MAX_JRC2018_VNC_UNISEX_63x_2DMASK"; Mask3D="JRC2018_VNC_UNISEX_63x_3DMASK.nrrd";
					}else if(width==1402 && height==2851 && slices==377){//1402x2851x377), JRC2018 63x Female
						MaskName2D="MAX_JRC2018_VNC_FEMALE_63x_2DMASK.tif"; Mask3D="JRC2018_VNC_FEMALE_63x_3DMASK.nrrd";
					}else if(width==1401 && height==2851 && slices==422){//1401x2851x422), JRC2018 63x MALE
						MaskName2D="MAX_JRC2018_VNC_MALE_63x_2DMASK.tif"; Mask3D="JRC2018_VNC_MALE_63x_3DMASK.nrrd";
					}else if(width==573 && height==1119 && slices==219){//573x1119x219, JRC2018 20x UNISEX
						MaskName2D="MAX_JRC2018_VNC_UNISEX_447_2DMASK.tif"; Mask3D="JRC2018_VNC_UNISEX_447_3DMASK.nrrd";
					}else if(width==572 && height==1164 && slices==229){//512x1100x220, 2017_VNC 20x MALE
						MaskName2D="MAX_JRC2018_VNC_MALE_447_G15_2DMASK.tif"; Mask3D="JRC2018_VNC_MALE_447_G15_3DMASK.nrrd";
					}else if(width==573 && height==1164 && slices==205){//512x1100x220, 2017_VNC 20x MALE
						MaskName2D="MAX_JRC2018_VNC_FEMALE_447_G15_2DMASK.tif"; Mask3D="JRC2018_VNC_FEMALE_447_G15_3DMASK.nrrd";
					}else if(width==512 && height==1100 && slices==220){//512x1100x220, 2017_VNC 20x MALE
						MaskName2D="MAX_MaleVNC2017_2DMASK.tif"; Mask3D="MaleVNC2017_3DMASK.nrrd";
						zerovalue=239907;
						zeroexi=1;
					}else if(width==512 && height==1024 && slices==220){//512x1024x220, JRC2018 20x UNISEX
						MaskName2D="MAX_FemaleVNCSymmetric2017_2DMASK.tif"; Mask3D="FemaleVNCSymmetric2017_3DMASK.nrrd";
						zerovalue=239907;
						zeroexi=1;
						
					}else if(width==3333 && height==1560 && slices==456){
						MaskName2D="MAX_JRC2018_UNISEX_63xOri_2DMASK.tif"; Mask3D="JRC2018_UNISEX_63xOri_3DMASK.nrrd";
					}else if(width==1652 && height==773 && slices==456){
						MaskName2D="MAX_JRC2018_UNISEX_38um_iso_2DMASK.tif"; Mask3D="JRC2018_UNISEX_38um_iso_3DMASK.nrrd";
					}else if(width==1427 && height==668 && slices==394){
						MaskName2D="MAX_JRC2018_UNISEX_40x_2DMASK.tif"; Mask3D="JRC2018_UNISEX_40x_3DMASK.nrrd";
					}else if(width==1210 && height==566 && slices==174){//1210x566x174, JRC2018 BRAIN 20xHR UNISEX
						MaskName2D="MAX_JRC2018_UNISEX_20x_HR_2DMASK.tif"; Mask3D="JRC2018_UNISEX_20x_HR_3DMASK.nrrd";
					}else if(width==1010 && height==473 && slices==174){
						MaskName2D="MAX_JRC2018_UNISEX_20x_gen1_2DMASK.tif"; Mask3D="JRC2018_UNISEX_20x_gen1_3DMASK.nrrd";
						
					}else if(width==3333 && height==1550 && slices==478){
						MaskName2D="MAX_JRC2018_FEMALE_63x_2DMASK.tif"; Mask3D="JRC2018_FEMALE_63x_3DMASK.nrrd";
					}else if(width==1652 && height==768 && slices==478){
						MaskName2D="MAX_JRC2018_FEMALE_38um_iso_2DMASK.tif"; Mask3D="JRC2018_FEMALE_38um_iso_3DMASK.nrrd";
					}else if(width==1427 && height==664 && slices==413){
						MaskName2D="MAX_JRC2018_FEMALE_40x_2DMASK.tif"; Mask3D="JRC2018_FEMALE_40x_3DMASK.nrrd";
					}else if(width==1210 && height==563 && slices==182){
						MaskName2D="MAX_JRC2018_FEMALE_20x_HR_2DMASK.tif"; Mask3D="JRC2018_FEMALE_20x_HR_3DMASK.nrrd";
					}else if(width==1010 && height==470 && slices==182){
						MaskName2D="MAX_JRC2018_FEMALE_20x_gen1_2DMASK.tif"; Mask3D="JRC2018_FEMALE_20x_gen1_3DMASK.nrrd";
						
					}else if(width==3150 && height==1500 && slices==476){//3150x1500x476, JRC2018 BRAIN 63x MALE
						MaskName2D="MAX_JRC2018_MALE_63x_2DMASK.tif"; Mask3D="JRC2018_MALE_63x_3DMASK.nrrd";
					}else if(width==1561 && height==744 && slices==476){//1561x744x476, JRC2018 BRAIN 63xDW MALE
						MaskName2D="MAX_JRC2018_MALE_38um_iso_2DMASK.tif"; Mask3D="JRC2018_MALE_38um_iso_3DMASK.nrrd";
					}else if(width==1348 && height==642 && slices==411){
						MaskName2D="MAX_JRC2018_MALE_40x_2DMASK.tif"; Mask3D="JRC2018_MALE_40x_3DMASK.nrrd";
					}else if(width==1143 && height==545 && slices==181){
						MaskName2D="MAX_JRC2018_MALE_20xHR_2DMASK.tif"; Mask3D="JRC2018_MALE_20xHR_3DMASK.nrrd";
					}else if(width==955 && height==455 && slices==181){
						MaskName2D="MAX_JRC2018_MALE_20x_gen1_2DMASK.tif"; Mask3D="JRC2018_MALE_20x_gen1_3DMASK.nrrd";
						
					}else if(width==1184 && height==592 && slices==218){
						MaskName2D="MAX_JFRC2013_20x_New_dist_G16_2DMASK.tif"; Mask3D="JFRC2013_20x_New_dist_G16_3DMASK.nrrd";
					}else if(width==1450 && height==725 && slices==436){
						MaskName2D="MAX_JFRC2013_63x_New_dist_G16_2DMASK.tif"; Mask3D="JFRC2013_63x_New_dist_G16_3DMASK.nrrd";
						
					}else if(width==1024 && height==512 && slices==220){//1024x512x220, JFRC2010
						MaskName2D="MAX_JFRC2010_2DMask.tif"; Mask3D="JFRC2010_3DMask.nrrd";
					}
					
					FilePathArray=newArray(0, MaskName2D,"Open",MaskDir,MIPtitle);
					fileOpen(FilePathArray,filepath);
					print("330");
					
					if (MaskName2D==""){
						
						setMinAndMax(0, 65535);
						selectWindow(MIPtitle);
						
						makeRectangle(getWidth*0.1, getHeight*0.1, getWidth*0.8, getHeight*0.8);
						setForegroundColor(0, 0, 0);
						run("Fill", "slice");
					}//if(getWidth==512){
					
					selectWindow(MIPtitle);
					
					total=0; // getHistogram is broke;
					for(ix=0; ix<getWidth; ix++){
						for(iy=0; iy<getHeight; iy++){
							pxv = getPixel(ix,iy);
							total= total+pxv;
							
							if(pxv==0)
							if(zeroexi==0)
							zerovalue=zerovalue+1;
						}
					}//for(ix=0; ix<getWidth; ix++){
					
					//		zerovalue=counts[0];
					Inimin=round((total/((getHeight*getWidth)-zerovalue))*0.8);//239907 is female VNC size
					print("zerovalue; "+zerovalue+"  total; "+total+"  getHeight; "+getHeight+"  getWidth; "+getWidth);
					print("Initial Bri adjustment; Inimin; "+Inimin+"   max; "+Inimax+"   RealInimax; "+RealInimax+"   DefMaxValue; "+DefMaxValue);
					
					
					//		setBatchMode(false);
					//		updateDisplay();
					//		a
					
					while(isOpen(MIPtitle)){
						selectWindow(MIPtitle);
						close();
					}
					
					if(Inimin!=0 || Inimax!=65535){
						selectWindow(stackSt);
						
						if(easyADJ==true || AutoBRV==1){
							setMinAndMax(0, Inimax);
							run("Apply LUT", "stack");
						}
						
						//		setBatchMode(false);
						//		updateDisplay();
						//		a
						if(AutoBRV==1){
							setMinAndMax(Inimin, 65535);
							run("Apply LUT", "stack");
							
							run("Max value");
							logsum=getInfo("log");
							maxStartindex=lastIndexOf(logsum,"Maxvalue");
							maxEndindex=lastIndexOf(logsum,"Minvalue");
							maxvalue=substring(logsum, maxStartindex+10, maxEndindex-2);
							maxvalue=round(maxvalue);
							
							print("3D stack brightness adjusted; maxvalue; "+maxvalue);
						}
					}else
					maxvalue=65535;
					
				}//	if(bitd==16){
				
				
				//			setBatchMode(false);
				//			updateDisplay();
				//			a
				if(unsharp!="Max" && AutoBRV==1){
					if(lowerweight>0){
						
						if(MedianSub!=0){
							
							run("Z Project...", "projection=[Max Intensity]");
							
							getMinAndMax(min, max);
							if(max<=255){// 8 bit file in 16bit format
								desiredmean=200;
								lowerweight=0;
								
								MedianSub=100;
								print("16bit file with 8bit data");
							}
							close();
							
							if(File.exists(MaskDir+Mask3D)==1){
								open(MaskDir+Mask3D);
								
								if(bitd==16 && max>255){
									histave=50;
									MedianSub=60;
								}else
								histave=1;
								
								
								run("Mask Median Subtraction", "mask="+Mask3D+" data="+stackSt+" %="+MedianSub+" subtract histogram="+histave+"");
								selectWindow(Mask3D);
								close;
							}
						}//	if(MedianSub!=0){	
					}else{
						OrigiSlice=nSlices();
						if(MedianSub!=0){
							if(lowerweight>0){
								run("Z Project...", "start=10 stop="+OrigiSlice-10+" projection=[Max Intensity]");
								rename("MIP_mask.tif");
								setAutoThreshold("Mean dark");
								setOption("BlackBackground", true);
								run("Convert to Mask");
								
								//		setBatchMode(false);
								//		updateDisplay();
								//		a
								
								run("Select All");
								run("Copy");
								
								if(bitd==16)
								histave=50;
								else
								histave=5;
								
								for(islicen=2; islicen<=OrigiSlice; islicen++){
									run("Add Slice");
									run("Paste");
									//		print("slice added "+islicen);
								}
								
								//			setBatchMode(false);
								//					updateDisplay();
								//					a
								
								print("1278 lowerweight*0.3; "+lowerweight*0.3);
								run("Mask Median Subtraction", "mask=MIP_mask.tif data="+stackSt+" %="+lowerweight*30+" subtract histogram="+histave+"");
								
								//					setBatchMode(false);
								//										updateDisplay();
								//										a
								
								selectWindow("MIP_mask.tif");
								close;
							}
						}
						
					}//	if(lowerweight>0){
				}//if(unsharp!="Max"){
				//					setBatchMode(false);
				//					updateDisplay();
				//					a
			}//if(channels!=0){
			
			
			BasicMIP=newArray(bitd,0,stack,GradientDim,stackSt);
			basicoperation(BasicMIP);//rename MIP.tif
			
			
			MIP=getImageID();
			run("Canvas Size...", "width="+round(getWidth()*0.95)+" height="+round(getHeight()*0.95)+" position=Center zero");
			sigsize=0;
			
			print("basicoperation done");
			
			//			setBatchMode(false);
			//				updateDisplay();
			//				a
			applyV=1;
			
			if(AutoBRV==1){//to get brightness value from MIP
				selectImage(MIP);
				briadj=newArray(desiredmean, 0, 0, 0,lowerweight,lowthreM,autothre,maxvalue,MIP,stack,multiDSLT,secondjump);
				autobradjustment(briadj,DSLTver,DefMaxValue);
				applyV=briadj[2];
				sigsize=briadj[1];
				sigsizethre=briadj[3];
				sigsizethre=parseFloat(sigsizethre);
				sigsize=parseFloat(sigsize);
				
				if(isOpen("test.tif")){
					selectWindow("test.tif");
					close();
				}
				print("Auto-bri finished  channels; "+channels);
			}//	if(AutoBRV==1){
			
			if(colorcoding==1 && AutoBRV==1){
				
				if(channels==1)
				selectWindow(origi);
				
				if(channels==2 || channels==3 || channels==4)
				selectWindow(neuronCH);
				
				if(unsharp=="Unsharp")
				run("Unsharp Mask...", "radius=1 mask=0.35 stack");
				else if(unsharp=="Max")
				run("Maximum...", "radius=1.5 stack");
				
				if(bitd==16){
					if(DefMaxValue==4095)
					RealapplyV= round((applyV/16)*(Inimax/DefMaxValue));// adjusting from 65535 to 4095
					else if (DefMaxValue==255)
					RealapplyV=((applyV/(16*16))*(Inimax/DefMaxValue));// adjusting from 65535 to 4095
					else if (DefMaxValue==65535)
					RealapplyV= round(applyV*(Inimax/DefMaxValue));// adjusting from 65535 to 4095
				}
			}//if(colorcoding==1){
			
			if(AutoBRV==1){//to get brightness value from MIP
				if(bitd==8 || bitd==24)
				RealapplyV= round(applyV*(Inimax/255));
				
				print("After +Inimax RealapplyV; "+RealapplyV+"   applyV; "+applyV);
			}
			
			maxi2=0;
			if(sigsize<30){
				if(AutoBRV==1){
					brightnessapplyArray = newArray(applyV,RealapplyV,sigsize,sigsizethre,GammaON,0);
					brightnessapply(DefMaxValue,filepath,brightnessapplyArray, bitd,lowerweight,lowthreM,stack,MaskDir,secondjump,Inimax,MaskName2D);
					
					applyV=brightnessapplyArray[0];
					RealapplyV=brightnessapplyArray[1];
					maxi2=brightnessapplyArray[1];
				}
			}else{
				setMinAndMax(0, 65535);
				run("8-bit");
			}//if(sigsize<30){
			if(reverse0==1){
				run("Reverse");
				run("Flip Horizontally", "stack");
			}
			
			if(usingLUT=="royal")
			stackconcatinate();
			
			
			if(AutoBRV==0){
				
				if(isOpen(origi))
				selectWindow(origi);
				else
				selectWindow(neuronCH);
				
				applyV=255;
				if(bitd==16){
					
					if(easyADJ==false)
					setMinAndMax(0, DefMaxValue);
					
					run("8-bit");
				}
				
				print("line 1670 nImages; "+nImages);
			}//if(AutoBRV==0){
			
			if(AutoBRV==1){
				applyV = round(RealapplyV);
				print("Line 1518 RealapplyV; "+round(RealapplyV));
			}
			
			
			ColorCoder(slices, applyV, width, AutoBRV, bitd, CLAHE, colorscale, reverse0, colorcoding, usingLUT,DefMaxValue,startMIP,endMIP,expand,GammaON);
			
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
			}//if(AutoBRV==1){
			
			if(CropYN==true)
			CropOP(MIPtype,applyV,colorscale);
			
			
			TrueMaxValue=0;
			if(DefMaxValue<4096){
				
				TrueMaxValue=4095;
				if(DefMaxValue<256)
				TrueMaxValue=255;
				
			}else if(DefMaxValue>4095)
			TrueMaxValue=65535;
			
			print("dirCOLOR 654; "+dirCOLOR);
			
			//	setBatchMode(false);
			//			updateDisplay();
			//			a
			
			if(imageNum==1){
				if(AutoBRV==1){
					save(dirCOLOR+DataName+"_CH"+MIPtry+"_MIP.tif");
					//	saveAs("PNG", dirCOLOR+DataName+"_CH"+MIPtry+"_MIP.png");
					
					File.saveString("applied.brightness="+applyV+" / "+TrueMaxValue+"\n"+"dslt.signal.amount="+sigsize+"\n"+"thresholding.signal.amount="+sigsizethre+"\n"+"S/B ratio="+(sigsize/maxi2)*100, dirCOLOR+DataName+"_CH"+MIPtry+"_MIP.properties");
				}else
				saveAs("PNG", dirCOLOR+DataName+"_CH"+MIPtry+"_MIP.png");
				
				
			}else{
				if(AutoBRV==1){
					save(dirCOLOR+DataName+"_CH"+MIPtry+"_MIP.tif");
					//	saveAs("PNG", dirCOLOR+DataName+"_CH"+MIPtry+"_MIP.png");
					File.saveString("applied.brightness="+applyV+" / "+TrueMaxValue+"\n"+"dslt.signal.amount="+sigsize+"\n"+"thresholding.signal.amount="+sigsizethre+"\n"+"S/B ratio="+(sigsize/maxi2)*100, dirCOLOR+DataName+"_CH"+MIPtry+"_MIP.properties");
				}else
				save(dirCOLOR+DataName+"_CH"+MIPtry+"_MIP.tif");
				//			saveAs("PNG", dirCOLOR+DataName+"_CH"+MIPtry+"_MIP.png");
				
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
} //function mipfunction(mipbatch) { 
///////////////////////////////////////////////////////////////
function autobradjustment(briadj,DSLTver,DefMaxValue){
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
		setMinAndMax(0, maxvalue);
		run("Copy");
	}
	/////////////////////signal size measurement/////////////////////
	selectImage(MIP);
	run("Duplicate...", "title=test2.tif");
	setAutoThreshold("Triangle dark");
	getThreshold(lower, upper);
	setThreshold(lower, maxvalue);//is this only for 8bit??
	
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
		setThreshold(lower, maxvalue);
		
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
	
	dsltarray=newArray(autothre, bitd, totalpix, desiredmean, 0,multiDSLT,DSLTver);
	DSLTfun(dsltarray);
	desiredmean=dsltarray[3];
	area2=dsltarray[4];
	//////////////////////
	
	selectImage(MIP);//MIP
	resetMinAndMax();
	getMinAndMax(min1, max);
	
	//setBatchMode(false);
	//					updateDisplay();
	//					a
	
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
		applyV=150;
		
		if(bitd==8)
		applyV=40;
		
	}
	
	rename("MIP.tif");//MIP
	
	selectWindow("test.tif");//new window from DSLT
	close();
	/////////////////2nd time DSLT for picking up dimmer neurons/////////////////////
	
	
	if(applyV>30 && desiredmean<secondjump && bitd==8 && DOUBLEdslt==1 && applyV<80){
		applyVpre=applyV;
		selectImage(MIP);
		
		setMinAndMax(0, applyV);
		
		run("Duplicate...", "title=MIPtest.tif");
		
		setMinAndMax(0, applyV);
		run("Apply LUT");
		maxcounts=0; maxi=0;
		
		histoArray = newArray(256);
		for(ix=0; ix<getWidth; ix++){
			for(iy=0; iy<getHeight; iy++){
				pxv = getPixel(ix,iy);
				histoArray[pxv]=histoArray[pxv]+1;
			}
		}
		//getHistogram(values, counts,  256);  broken function
		for(i=0; i<100; i++){
			Val=histoArray[i];
			
			if(Val>maxcounts){
				maxcounts=histoArray[i];
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
		
		//	setBatchMode(false);
		//						updateDisplay();
		//						a
		
		setMinAndMax(changelower, 255);
		run("Apply LUT");
		
		print("Double DSLT");
		//	run("Multibit thresholdtwo", "w/b=Set_black max=207 in=[In macro]");
		
		desiredmean=secondjump;//230 for GMR
		
		dsltarray=newArray(autothre, bitd, totalpix, desiredmean, 0, multiDSLT,DSLTver);
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
	
	while(isOpen("test.tif")){
		selectWindow("test.tif");
		close();
	}
	
	sigsize=area2/totalpix;
	if(sigsize==1)
	sigsize=0;
	
	sigsizethre=areathre/totalpix;
	
	print("Signal brightness; after 65535 applyV;	"+applyV+"	 Signal Size DSLT; 	"+sigsize+"	 Sig size threshold; 	"+sigsizethre);
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
	DSLTver=dsltarray[6];
	
	if(autothre==0){//DSLT
		
		//	updateDisplay();
		//	setBatchMode(false);
		//	a
		
		run("Anisotropic Diffusion 2D", "number=6 smoothings=7 keep=20 a1=0.50 a2=0.90 dt=20 edge=2");// threads=1
		print("Anisotropic diffusion ON");
		//		updateDisplay();
		//		setBatchMode(false);
		//		a
		
		if(bitd==8){
			if(DSLTver=="Line")
			run("DSLT3D LINE2 Multi", "radius_r_max=15 radius_r_min=3 radius_r_step=3 rotation=8 weight=5 filter=MEAN close=None noise=5px parallel=3");
			else
			run("DSLT ", "radius_r_max=15 radius_r_min=1 radius_r_step=4 rotation=8 weight=5 filter=MEAN close=None noise=7px");
		}
		if(bitd==16){
			
			//		updateDisplay();
			//		setBatchMode(false);
			//		a
			resetMinAndMax();
			getMinAndMax(min,max);
			
			run("A4095 normalizer", "subtraction=0 max="+max+" start=1 end=1");
			print("A4095 normalizer max; "+max);
			
			//			updateDisplay();
			//			setBatchMode(false);
			//			a
			
			if(DSLTver=="Line")
			run("DSLT3D LINE2 Multi", "radius_r_max=15 radius_r_min=2 radius_r_step=3 rotation=8 weight=140 filter=GAUSSIAN close=None noise=5px parallel=3");
			else
			run("DSLT ", "radius_r_max=15 radius_r_min=2 radius_r_step=3 rotation=8 weight=140 filter=MEAN close=None noise=5px");
			
			FirstDSLT=getTitle();
			run("Remove Outliers...", "radius=1 threshold=90 which=Dark");
			
			run("DSLT ", "radius_r_max=5 radius_r_min=1 radius_r_step=2 rotation=8 weight=1 filter=GAUSSIAN close=None less=9");
			
			SecondDSLT=getTitle();
			
			selectWindow(FirstDSLT);
			close();
			
			selectWindow(SecondDSLT);
			run("Remove Outliers...", "radius=1 threshold=90 which=Dark");
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
	
	run("Canvas Size...", "width="+round(getWidth()*0.95)+" height="+round(getHeight()*0.95)+" position=Center zero");
	
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
	print("Area 1st time;  "+area1+"   mean; "+mean+"  totalpix; "+totalpix+"   presize; "+presize*100+" %   bitd; "+bitd);
	realArea=area1;
	
	//	setBatchMode(false);
	//		updateDisplay();
	//		a
	
	multiDSLT=0;
	if(multiDSLT==1){
		if(presize<0.3){// set DSLT more sensitive, too dim images, less than 5%
			selectWindow("test.tif");//new window from DSLT
			close();
			
			if(isOpen("test.tif")){
				selectWindow("test.tif");
				close();
			}
			
			selectWindow("MIP.tif");//MIP
			run("Anisotropic Diffusion 2D", "number=6 smoothings=7 keep=20 a1=0.50 a2=0.90 dt=20 edge=2");// threads=1
			//			setBatchMode(false);
			//	updateDisplay();
			//	a
			
			if(bitd==8){
				if(DSLTver=="Line")
				run("DSLT3D LINE2 Multi", "radius_r_max=15 radius_r_min=2 radius_r_step=3 rotation=8 weight=1 filter=MEAN close=None noise=5px parallel=3");
				else
				run("DSLT ", "radius_r_max=15 radius_r_min=1 radius_r_step=4 rotation=8 weight=2 filter=MEAN close=None noise=7px");
			}
			if(bitd==16){
				getMinAndMax(min,max);
				if(max!=65536){
					setMinAndMax(min, max);
					run("Apply LUT");
					max=65535;
				}
				
				run("A4095 normalizer", "subtraction=0 max="+max+" start=1 end=1");
				
				print("A4095 2nd normalizer max; "+max);
				
				if(DSLTver=="Line")
				run("DSLT3D LINE2 Multi", "radius_r_max=15 radius_r_min=2 radius_r_step=3 rotation=8 weight=35 filter=MEAN close=None noise=5px parallel=3");
				else
				run("DSLT ", "radius_r_max=15 radius_r_min=1 radius_r_step=4 rotation=8 weight=30 filter=MEAN close=None noise=5px");
			}
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
					weight=oriss/5;
					desiredmean=desiredmean+(desiredmean/4)*weight;
					desiredmean=round(desiredmean);
					
					if(desiredmean>secondjump || isNaN(desiredmean))
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
					
					if(desiredmean>204)
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
		else if(applyV<10)
		applyV=10;
	}else if(bitd==16){
		
		if(max<=4095)
		applyV=4095-applyV;
		
		if(max>4095)
		applyV=65535-applyV;
		
		if(applyV==0)
		applyV=max;
		else if(applyV<100)
		applyV=100;
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

function brightnessapply(DefMaxValue,filepath,brightnessapplyArray, bitd,lowerweight,lowthreM,stack,MaskDir,secondjump,Inimax,MaskName2D){
	stacktoApply=getTitle();
	
	applyV = brightnessapplyArray[0];
	RealapplyV=brightnessapplyArray[1];
	sigsize=brightnessapplyArray[2];
	sigsizethre=brightnessapplyArray[3];	
	GammaON=brightnessapplyArray[4];	
	
	sigsize=parseFloat(sigsize);//Chaneg string to number
	
	print("brightnessapply start, RealapplyV; "+RealapplyV+"   applyV; "+applyV+"  lowerweight; "+lowerweight+"   sigsize; "+sigsize+"  sigsizethre; "+sigsizethre);
	
	BackgroundMaskArray = newArray("","");
	brightnessNeed=0;
	changelower=0;
	
	if(bitd==8){
		if(applyV<255){
			setMinAndMax(0, applyV);
			
			if(applyV<secondjump){
				run("Z Project...", "projection=[Max Intensity]");
				MIPapply=getTitle();
				
				setMinAndMax(0, applyV);
				if(applyV!=255)
				run("Apply LUT");
				
				if(MaskName2D!=""){
					BackgroundMask (BackgroundMaskArray,MaskName2D,MaskDir,MIPapply,bitd,GammaON);
					brightnessNeed=BackgroundMaskArray[0];
					
				}else{
					
					newImage("MaskMIP.tif", "8-bit black", getWidth, getHeight, 1);
					setForegroundColor(255, 255, 255);
					
					makeRectangle(getWidth*0.2, getHeight*0.2, getWidth*0.6, getHeight*0.6);
					
					run("Make Inverse");
					run("Fill", "slice");
					
					imageCalculator("Max", MIPapply,"MaskMIP.tif");
					
					selectWindow("MaskMIP.tif");
					close();
					
					selectWindow(MIPapply);
					
				}//	
				
				if(lowthreM=="Peak Histogram"){//lowthre measurement
					maxcounts=0; maxi=0;
					getHistogram(values, counts,  256);
					for(i3=1; i3<200; i3++){
						
						sumave=0;
						for(ix=0; ix<getWidth; ix++){
							for(iy=0; iy<getHeight; iy++){
								pxv = getPixel(ix,iy);
								
								if(pxv>=i3)
								if(pxv<i3+5)
								sumave= sumave+pxv;
							}
						}//for(ix=0; ix<getWidth; ix++){
						
						aveave=sumave/5;
						
						if(aveave>maxcounts){
							
							maxcounts=aveave;
							maxi=i3+2;
							print("GrayValue; "+i3+"  "+aveave+"  maxi; "+maxi);
						}
					}//for(i3=0; i3<200; i3++){
					if(maxi!=2)
					changelower=maxi*0.6;//lowerweight
					else
					changelower=0;
					
				}else if(lowthreM=="Auto-threshold"){
					setAutoThreshold("Huang dark");
					getThreshold(lower, upper);
					resetThreshold();
					changelower=lower*0.6;
				}
				
				changelower=round(changelower);
				//		if(changelower>100)
				//		changelower=100;
				
				selectWindow(MIPapply);
				
				//	setBatchMode(false);
				//	updateDisplay();
				//	a
				
				close();
				
				selectWindow(stacktoApply);
				setMinAndMax(0, applyV);//brightness adjustment
				
				if(applyV!=255)
				run("Apply LUT", "stack");
				
				print("2269 ok  "+changelower);
				if(changelower>0){
					changelower=round(changelower);
					
					setMinAndMax(changelower, 255);//lowthre cut
					run("Apply LUT", "stack");
				}else
				changelower=0;
				
				print("  lower threshold; 	"+changelower);
			}
		}
	}//if(bitd==8){
	
	if(bitd==16){
		
		applyV2=applyV;
		if(applyV==65535)
		applyV2=65534;
		
		selectImage(stack);
		
		run("Z Project...", "projection=[Max Intensity]");
		MIP2=getImageID();
		getMinAndMax(min, max);
		setMinAndMax(min, max);
		MIPapply=getTitle();
		
		print("Line 1225 min; "+min+"   max; "+max);
		
		if(min!=0 && max!=65535)
		run("Apply LUT");
		
		run("Duplicate...", "title=MIPDUP.tif");
		MIPDUPid = getImageID();
		MIPthresholding=getTitle();
		
		print("Line 1252;  MIPthresholding; "+MIPthresholding);
		//		setBatchMode(false);
		//		updateDisplay();
		///		a
		
		print("getHeight; "+getHeight);
		
		if(MaskName2D!=""){
			
			BackgroundMask (BackgroundMaskArray,MaskName2D,MaskDir,MIPapply,bitd,GammaON);
			brightnessNeed= BackgroundMaskArray[0];
			
		}else{//	if(getHeight==512 && getWidth==1024){
			
			tissue="UNKNOWN";
			newImage("MaskMIP.tif", "16-bit", getWidth, getHeight, 1);
			setForegroundColor(255, 255, 255);
			makeRectangle(round(getWidth*(150/1500)), round(getHeight*(100/833)), round(getWidth*(1200/1500)), round(getHeight*(600/833)));			//		run("Make Inverse");
			run("Fill", "slice");
			setMinAndMax(0, 255);
			run("Apply LUT");
			
			run("Three D Ave");
			MaskBri = getTitle();
			MaskBri= parseFloat(MaskBri);//Chaneg string to number
			MaskBri = round(MaskBri);
			rename("MaskMIP.tif");
			
			selectImage(MIPDUPid);
			rename(MIPthresholding);
			
			imageCalculator("Min", MIPthresholding,"MaskMIP.tif");
			
			//	setBatchMode(false);
			if(GammaON==true){
				
				run("Gamma ", "gamma=1.40 in=InMacro cpu=6");
				gamma = getTitle();
				
				selectWindow(MIPthresholding);
				close();
				
				selectWindow(gamma);
				rename(MIPthresholding);
				MIPDUPid=getImageID();
				print("GAMMA 1.4 applied to 2D");
			}
			
			run("Three D Ave");
			//		setBatchMode(false);
			//		updateDisplay();
			//		a
			
			//	run("Mask Brightness Measure", "mask=MaskMIP.tif data="+MIPthresholding+" desired=150");
			
			brightnessNeed = getTitle();
			brightnessNeed= parseFloat(brightnessNeed);//Chaneg string to number
			brightnessNeed = round(brightnessNeed);
			brightnessNeed= round(brightnessNeed*(65535/MaskBri));
			
			selectImage(MIPDUPid);
			rename(MIPthresholding);
			
			print("brightnessNeed; "+brightnessNeed);
			
			//			setBatchMode(false);
			//				updateDisplay();
			//				a
			
			selectWindow("MaskMIP.tif");
			close();
			
			selectWindow(MIPthresholding);
			MIPDUPid=getImageID();// masked image
		}// if(MaskName2D!=""){ 	if(getHeight==512 || getHeight==592){
		
		if(DefMaxValue==4095)
		MinSigSize = 0;
		
		print("MIPthresholding; "+MIPthresholding);
		//// lower thresholding //////////////////////////////////	
		maxi=0;			 		countregion=10000;
		
		if(lowthreM=="Peak Histogram"){
			selectWindow(MIPthresholding);
			MIPDUPid = getImageID();
			
			//	setBatchMode(false);
			//					updateDisplay();
			//					a
			
			maxcounts=0; medianNum=400; 
			//	getHistogram(values, counts,  65536);
			
			counts=newArray(65536);
			
			for(ix=0; ix<getWidth; ix++){
				for(iy=0; iy<getHeight; iy++){
					pxv = getPixel(ix,iy);
					
					counts[pxv]=counts[pxv]+1;
				}
			}//for(ix=0; ix<getWidth; ix++){
			
			////Average value
			
			brightnessNeed=round(brightnessNeed);
			
			if(brightnessNeed>35000)
			countregion=16000;
			else
			countregion=brightnessNeed;
			
			for(i3=5; i3<countregion-medianNum; i3++){
				
				sumVal20=0; 
				
				for(aveval=i3; aveval<i3+medianNum; aveval++){
					Val20=counts[aveval]*aveval;
					sumVal20=sumVal20+Val20;
				}
				AveVal20=sumVal20/medianNum;
				
				if(AveVal20>maxcounts){
					maxcounts=AveVal20;
					maxi=i3+(medianNum/2);
					Final_i3 = i3;
					//	print("i3; "+i3);
				}
			}//		for(i3=5; i3<countregion-medianNum; i3++){
			
			maxiZero=0;
			if(maxi==0){
				maxi=brightnessNeed;
				maxiZero=1;
			}
			MinSigSize=0;
			print("Avebrightness; "+brightnessNeed+"  maxi"+maxi+"   countregion; "+countregion+"  sigsize; "+sigsize);
			
			if(brightnessNeed>40000){
				
				applyV2Ori=applyV2;//61539
				applyV2=applyV2*(brightnessNeed/40000);
				
				if(applyV2>65534)
				applyV2=65534;
				
				print("Too bright, applyV2 decreased from "+applyV2Ori+" to "+applyV2);
			}
			if(sigsize>=MinSigSize){
				//				setBatchMode(false);
				//				updateDisplay();
				//				a
				
				selectWindow("MIPDUP.tif");
				selectImage(MIPDUPid);
				close();
				numtry=0; 	minus2=0;
				if (maxi<1000 && brightnessNeed<2000){
					
					print("Decreasing maxi; original maxi = "+maxi);
					
					Orimaxi=maxi; avebrightness=0; previousmaxi=0;
					preapplyV2 = 0;
					
					///////////////////while ///////////////
					while(maxi<500 && avebrightness<2000){
						
						minus2=minus2-round(applyV2*0.03);
						selectImage(MIP2);//MIP
						run("Duplicate...", "title=MIPDUP2.tif");
						MIPthresholding=getTitle();
						
						print("minus2; "+minus2+"  applyV2; "+applyV2+"  maxi; "+maxi);
						
						if(applyV2+minus2>80){
							
							print("applyV2+minus2; "+applyV2+minus2+"  min; "+min);
							
							setMinAndMax(min, applyV2+minus2);
							run("Apply LUT");
							//save("/Users/otsunah/test/Color_depthMIP_Test/MCFO_unisex20xHR/"+numtry+".tif");
						}else{
							//Orimaxi
							break;
						}
						
						//	run("Apply LUT");
						if(MaskName2D!=""){
							
							BackgroundMask (BackgroundMaskArray,MaskName2D,MaskDir,"MIPDUP2.tif",bitd,GammaON);
							
							brightnessNeed=BackgroundMaskArray[0];
							
						}else if (MaskName2D==""){//	if(getHeight==512 && getWidth==1024){
							
							newImage("MaskMIP.tif", "16-bit", getWidth, getHeight, 1);
							setForegroundColor(255, 255, 255);
							makeRectangle(getWidth*0.2, getHeight*0.2, getWidth*0.6, getHeight*0.6);
							run("Make Inverse");
							run("Fill", "slice");
							
							//	setBatchMode(false);
							//		updateDisplay();
							//		a
							
							imageCalculator("Max", MIPthresholding,"MaskMIP.tif");
							
							selectWindow("MaskMIP.tif");
							close();
							
							selectWindow(MIPthresholding);
						}//if(MaskName2D!=""){
						
						maxcounts=0;	 medianNum=400; 
						getHistogram(values, counts, 65535);
						
						////Average value
						total=0;
						
						for(ix=0; ix<getWidth; ix++){
							for(iy=0; iy<getHeight; iy++){
								pxv = getPixel(ix,iy);
								total= total+pxv;
								
							}
						}//for(ix=0; ix<getWidth; ix++){
						
						//for(iave=1; iave<65535; iave++){
						//	total=total+(counts[iave]*iave);
						//					}
						
						avebrightness=round(total/(getHeight*getWidth));
						
						print("avebrightness; "+avebrightness);
						
						
						//		if(avebrightness>2000){
						//			setBatchMode(false);
						//							updateDisplay();
						//							a
						//		}
						
						for(i32=5; i32<countregion-medianNum; i32++){
							
							sumVal20=0; 
							
							for(aveval=i32; aveval<i32+medianNum; aveval++){
								Val20=counts[aveval];
								sumVal20=sumVal20+(Val20*aveval);
							}
							AveVal20=sumVal20/medianNum;
							
							if(AveVal20>maxcounts){
								maxcounts=AveVal20;
								maxi=round(i32+(medianNum/2));
								//			print("maxi; "+maxi+"   minus2; "+minus2);
							}
						}//		for(i3=5; i3<countregion-medianNum; i3++){
						
						if(isOpen(MIPthresholding)){
							selectWindow(MIPthresholding);
							
							//		setBatchMode(false);
							//						updateDisplay();
							//					a
							
							close();
						}
						
						if(previousmaxi == maxi && applyV2==preapplyV2){
							break;
						}
						
						previousmaxi=maxi;
						preapplyV2 = applyV2;
						
						numtry=numtry+1;
					}//while(maxi>7000){
					
					if(maxi<3000 && DefMaxValue<4096){
						applyV2 = applyV2+minus2;
						RealapplyV= round((applyV2/16)*(Inimax/4095));
					}
					
					print("Adjusted maxi; = "+maxi+"   minus2; "+minus2+"   RealapplyV; "+RealapplyV);
					changelower=maxi*0.3;
					
					
					minus = minus2;
					
				}else if (maxi>9000){
					changelower=maxi*0.9;
					if(sigsize<10){// background only
						changelower=maxi;
						preRealapplyV=RealapplyV;
						
						applyV2=applyV2*1.6;
						RealapplyV= round((applyV2/16)*(Inimax/4095));
						print("decreased RealapplyV; from "+preRealapplyV+" to "+RealapplyV);
					}
					
				}else if (maxi>3500 && maxi<=6000){
					
					changelower=maxi*0.7;
					if(sigsize>6){// if more neuron fibers, higher average brightness
						changelower=maxi*0.4;
						print("changelower=maxi*0.4  sigsize; "+sigsize);
					}
					
					if(sigsize<2.5){// if more neuron fibers, higher average brightness
						changelower=maxi*0.9;
						
						preRealapplyV=RealapplyV;
						
						applyV2=applyV2*1.6;
						RealapplyV= round((applyV2/16)*(Inimax/4095));
						print("decreased RealapplyV; from "+preRealapplyV+" to "+RealapplyV);
						
						print("changelower=maxi*0.7  sigsize; "+sigsize);
					}
					
					
				}else if (maxi>6000 && maxi<=9000){
					
					changelower=maxi*0.7;
					if(sigsize>6){// if more neuron fibers, higher average brightness
						changelower=maxi*0.4;
						print("changelower=maxi*0.4  sigsize; "+sigsize);
					}
					
					
				}else if (maxi>2500 && maxi<=3500){
					
					changelower=maxi*0.2;
					if(sigsize<3){
						changelower=maxi*0.5;
						print("changelower=maxi*0.5  sigsize; "+sigsize);
					}
					
				}else if (maxi<=2500)
				changelower=0;
				
				
				//	if(applyV>1000 && maxi>9000)
				//		changelower=0;
			}//if(sigsize>=1){
			if(sigsize<MinSigSize){
				applyV2 = 65535;
				
				if(applyV2>65535)
				applyV2=65535;
				
				if(DefMaxValue==4095)
				RealapplyV= round((applyV2/16)*(Inimax/DefMaxValue));// adjusting from 65535 to 4095
				else if (DefMaxValue==255)
				RealapplyV=((applyV2/(16*16))*(Inimax/DefMaxValue));// adjusting from 65535 to 4095
				else if (DefMaxValue==65535)
				RealapplyV= round(applyV2*(Inimax/DefMaxValue));// adjusting from 65535 to 4095
				
				print("sigsize too small, 2x lower brightness; sigsize; "+sigsize+"   RealapplyV; "+RealapplyV+"  applyV2; "+applyV2);
				
				selectWindow(stacktoApply);
				selectImage(stack);
				
				run("Z Project...", "projection=[Max Intensity]");
				MIPaveMeasure=getImageID();
				
				run("Three D Ave");
				print("end");
				logsum=getInfo("log");
				close();
				aveIndex = lastIndexOf(logsum, "AVEsamp;");
				endIndex = lastIndexOf(logsum, "end");
				
				avesamp = substring(logsum, aveIndex+9, endIndex-1);
				
				print("avesamp; "+avesamp);
				avesamp = parseFloat(avesamp);//Chaneg string to number
				
				maxi=round(avesamp);
				
				//changelower=maxi*0.4;
				//if(maxiZero==1)
				changelower=maxi*0.9;
			}
			
			if((sigsize/maxi)*100<0.13 && maxi<=2500)
			changelower=maxi*0.2;
			
			print("-- lower threshold; 	"+changelower+"   maxi; "+maxi+"  applyV2 16bit; "+applyV2+" S/B_ratio; "+(sigsize/maxi)*100);
			
			
			//		setBatchMode(false);
			//		updateDisplay();
			//		a
			
		}//if(lowthreM=="Peak Histogram"){
		
		selectWindow(stacktoApply);
		selectImage(stack);
		
		if(lowthreM=="Auto-threshold"){
			
			setAutoThreshold("Huang dark");
			getThreshold(lower, upper);
			resetThreshold();
			
			
			changelower=lower-lower/4;
			
			if(changelower>250)
			changelower=150;
		}//if(lowthreM=="Auto-threshold"){
		
		//		if(lowerweight==0)
		//		changelower=0;
		//	close();
		selectWindow(stacktoApply);
		selectImage(stack);
		
		
		if(GammaON==true){
			
			run("Gamma ", "gamma=1.40 3d in=InMacro cpu=6");
			gamma = getTitle();
			
			selectWindow(stacktoApply);
			close();
			
			selectWindow(gamma);
			rename(stacktoApply);
			stack = getImageID();
			print("GAMMA 1.4 applied to 3D stack");
		}
		
		if(sigsize>=MinSigSize){
			setMinAndMax(0, applyV2);//subtraction
			run("Apply LUT", "stack");
		}
		
		run("Max value");
		logsum=getInfo("log");
		maxStartindex=lastIndexOf(logsum,"Maxvalue");
		maxEndindex=lastIndexOf(logsum,"Minvalue");
		maxvalue=substring(logsum, maxStartindex+10, maxEndindex-2);
		maxvalue=round(maxvalue);
		
		print("stack maxvalue; "+maxvalue);
		
		//		setBatchMode(false);
		//				updateDisplay();
		//		a
		
		changelower=round(changelower);
		if(changelower!=0){
			setMinAndMax(changelower, maxvalue);//subtraction
			run("Apply LUT", "stack");
		}
		
		
		
		setMinAndMax(0, 65535);
		run("8-bit");
		
		brightnessapplyArray[0] = applyV2;
		brightnessapplyArray[1] = RealapplyV;
		
		brightnessapplyArray[5]=maxi;
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
	run("Z Project...", "start=15 stop="+nSlices+" projection=[Max Intensity]");
	rename("MIP.tif");
	if(bitd==16)
	resetMinAndMax();
	
	//updateDisplay();
	//setBatchMode(false);
	//a
	
	BasicMIP[1]=max;
}

function ColorCoder(slicesOri, applyV, width, AutoBRV, bitd, CLAHE, GFrameColorScaleCheck, reverse0, colorcoding, usingLUT,DefMaxValue,startMIP,endMIP,expand,GammaON) {//"Time-Lapse Color Coder" 
	
	if(usingLUT=="royal")
	var Glut = "royal";	//default LUT
	
	if(usingLUT=="PsychedelicRainBow2")
	var Glut = "PsychedelicRainBow2";	//default LUT
	
	var Gstartf = 1;
	
	getDimensions(width, height, channels, slices, frames);
	rename("Original_Stack.tif");
	
	//	setBatchMode(false);
	if(GammaON==true){
		
		run("Gamma ", "gamma=1.40 3d in=InMacro cpu=6");
		gamma = getTitle();
		
		selectWindow("Original_Stack.tif");
		close();
		
		selectWindow(gamma);
		rename("Original_Stack.tif");
		print("GAMMA 1.4 applied");
	}
	
	
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

function BackgroundMask (BackgroundMaskArray,MaskName2D,MaskDir,MIPapply,bitd,GammaON){
	
	brightnessNeed=BackgroundMaskArray[0];
	MaskName=MaskName2D;
	
	
	print("Mask path; "+MaskDir+MaskName2D);
	maskExist=File.exists(MaskDir+MaskName2D);
	if(maskExist==1){
		print("Used a Mask for background subtraction.; "+MaskName2D);
		open(MaskDir+MaskName2D);
		
		run("Set Measurements...", "area mean centroid center perimeter fit shape redirect=None decimal=2");
		run("Measure");
		
		meanvalue = getResult("Mean", 0);
		meanvalue = parseFloat(meanvalue);//Chaneg string to number
		
		BrightnessAdjustMaskValue = 65535/meanvalue;
		print("BrightnessAdjustMaskValue; "+BrightnessAdjustMaskValue+"   meanvalue; "+meanvalue+"  MaskName; "+MaskName);
		objective="40x";
		if(objective=="40x" &&	MaskName=="MAX_JFRC2010_2DMask.tif"){
			makePolygon(813,90,672,431,840,503,1022,488,1020,113);
			setForegroundColor(0, 0, 0);
			run("Fill", "slice");
			makePolygon(177,56,355,453,227,507,1,505,12,89);
			run("Fill", "slice");
			BrightnessAdjustMaskValue = 65535/25266;
		}
		
		if(bitd==8)
		run("8-bit");
		
		selectWindow(MIPapply);
		MIPid = getImageID();
		
		
		//	setBatchMode(false);
		if(GammaON==true){
			
			run("Gamma ", "gamma=1.40 in=InMacro cpu=6");
			gamma = getTitle();
			
			selectWindow(MIPapply);
			close();
			
			selectWindow(gamma);
			rename(MIPapply);
			MIPid = getImageID();
			print("GAMMA 1.4 applied to 2D");
		}//	if(GammaON==true
		
		if(MaskName!=""){
			imageCalculator("Min", MIPapply,MaskName);
			//	run("Three D Ave");
			
			selectImage(MIPid);
			selectWindow(MIPapply);
			
			//	setBatchMode(false);
			//			updateDisplay();
			//			a
			
			run("Mask MIP Brightness Measure", "mask="+MaskName+" data="+MIPapply+"");
			brightnessNeed = call("Mask_MIP_Brightness_Measure.getResult");
			
			//	brightnessNeed = getTitle();
			//		brightnessNeed= parseFloat(brightnessNeed);//Chaneg string to number
			//		brightnessNeed = round(brightnessNeed);
			
			brightnessNeed= round(brightnessNeed*BrightnessAdjustMaskValue);
			rename(MIPapply);
			
			print("brightnessNeed; 3405  "+brightnessNeed);
			
			//		setBatchMode(false);
			//		updateDisplay();
			//		a
			
			selectWindow(MaskName);
			close();
		}//if(MaskName!=0){
	}
	
	BackgroundMaskArray[0]=brightnessNeed;
	
	selectWindow(MIPapply);
}


function fileOpen(FilePathArray,filepath){
	MaskPath=FilePathArray[0];
	MIPname=FilePathArray[1];
	OpenorNot=FilePathArray[2];
	MaskDir=FilePathArray[3];
	MIPtitle=FilePathArray[4];
	
	//	print(MIPname+"; "+FilePath);
	if(isOpen(MIPname)){
		selectWindow(MIPname);
		MaskDir=getDirectory("image");
		MaskPath=MaskDir+MIPname;
	}else{
		if(MaskPath==0){
			
			MaskPath=MaskDir+MIPname;
			tempmaskEXI=File.exists(MaskPath);
			if(tempmaskEXI!=1){
				
				print("Error: Temp file is not existing; "+MaskPath);
				logsum=getInfo("log");
				File.saveString(logsum, filepath);
				run("Quit");
			}
			
			if(tempmaskEXI==1){
				if(OpenorNot!="DontOpen"){
					titlelistOri=getList("image.titles");
					IJ.redirectErrorMessages();
					open(MaskPath);
					
					titlelistAfter=getList("image.titles");
					
					if(titlelistOri.length == titlelistAfter.length){
						print("Error: The file cannot open; "+MaskPath);
						logsum=getInfo("log");
						File.saveString(logsum, filepath);
						run("Quit");
					}
				}
			}
			
		}else{
			tempmaskEXI=File.exists(MaskPath);
			if(tempmaskEXI!=1)
			MaskPath=MaskDir+MIPname;
			
			tempmaskEXI=File.exists(MaskPath);
			
			if(tempmaskEXI==1){
				if(OpenorNot!="DontOpen"){
					
					titlelistOri=getList("image.titles");
					IJ.redirectErrorMessages();
					open(MaskPath);
					
					titlelistAfter=getList("image.titles");
					
					if(titlelistOri.length == titlelistAfter.length){
						print("Error: The file cannot open; "+MaskPath);
						logsum=getInfo("log");
						File.saveString(logsum, filepath);
						run("Quit");
					}
				}
				
			}else{//if(tempmaskEXI==1){
				
				print("Error: Temp file is not existing; "+MaskPath);
				logsum=getInfo("log");
				File.saveString(logsum, filepath);
				run("Quit");
			}
		}
	}//if(isOpen("JFRC2013_63x_Tanya.nrrd")){
	
	if(OpenorNot=="Open"){
		imageCalculator("Subtract", MIPtitle,MIPname);
		
		while(isOpen(MIPname)){
			selectWindow(MIPname);
			close();
		}
		selectWindow(MIPtitle);
	}
	
	FilePathArray[0]=MaskPath;
	FilePathArray[3]=MaskDir;
}

function leftPad(n, width) {
	s = "" + n;
	while (lengthOf(s) < width)
	s = "0" + s;
	return s;
}

