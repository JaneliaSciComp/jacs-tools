//Pre-Image processing for VNC before CMTK operation
//Wrote by Hideo Otsuna, October 21, 2015, last update; 2016 08 03
// This macro requires 6 Fiji plugins (Hideo wrote these plugins) "Histgram_stretch.class", "Size_based_Noise_elimination.class", "Mask255_to_4095.class"
//"Gamma_.jar", "Size_to_Skelton.jar", "Nrrd_Writer.class" (modified for compressed nrrd option)

MIPsave=1;
handleCH=2;//number of handling channels for 01, 02 ZIP file
ShapeAnalysis=1;//perform shape analysis and kick strange sample
CLAHEwithMASK=1;
Batch=1;
FrontBackAnalysis=0;
BWd=0; //BW decision at 793 line
PrintSkip=0;
StackWidth=600;
StackHeight=1024;

// Arguments

argstr="/test/VNC_pipeline/,tile-2030851234574893154.v3draw,0,/test/VNC_Test/failed_sample/tile-2147098802673156194.v3dpbd,sr,0.51,0.51,f,/test/VNC_Test/failed_sample/tile-2147098802673156194.v3dpbd"//for test
args = split(argstr,",");

//args = split(getArgument(),",");
savedir = args[0];// save dir
prefix = args[1];//file name
mode = args[2];
path = args[3];// full file path for inport LSM
chanspec = toLowerCase(args[4]);// channel spec
Xresolution = toUpperCase(args[5]);
Yresolution = toLowerCase(args[6]);
temptype=args[7];//"f" or "m"
PathConsolidatedSignal=args[8];


print("Output dir: "+savedir);// save location
print("Output prefix: "+prefix);//file name
print("Processing mode: "+mode);
print("Input image: "+path);//full file path for open data
print("Channel spec: "+chanspec);//channel spec
print("X resolution: "+Xresolution);
print("Y resolution: "+Yresolution);
print("Gender: "+temptype);
print("ConsolidatedSignal Path; "+PathConsolidatedSignal);

exi=File.exists(savedir);
if(exi!=1){
	File.makeDirectory(savedir);
	print("savedir created!");
}
logsum=getInfo("log");
filepath=savedir+"VNC_pre_aligner_log.txt";
File.saveString(logsum, filepath);

myDir0 = savedir+"Shape_problem"+File.separator;
File.makeDirectory(myDir0);

myDir4 = savedir+"High_background_cannot_segment_VNC"+File.separator;
File.makeDirectory(myDir4);

String.resetBuffer;
n3 = lengthOf(savedir);
for (si=0; si<n3; si++) {
	c = charCodeAt(savedir, si);
	if(c==32){// if there is a space
		print("There is a space, please eliminate the space from saving directory.");
		logsum=getInfo("log");
		filepath=savedir+"VNC_pre_aligner_log.txt";
		File.saveString(logsum, filepath);
		print("line 57; log file saved");
		run("Quit");
	}
}
String.resetBuffer;

run("Close All");
List.clear();


// open files //////////////////////////////////			
filesize=File.length(path);

print(path);
setBatchMode(true);

if(filesize>1000000){// if more than 1MB
	print("Try Open");
	logsum=getInfo("log");
	filepath=savedir+"VNC_pre_aligner_log.txt";
	File.saveString(logsum, filepath);
	
	open(path);// for tif, comp nrrd, lsm", am, v3dpbd, mha
	
	print("Opened File");
	logsum=getInfo("log");
	filepath=savedir+"VNC_pre_aligner_log.txt";
	File.saveString(logsum, filepath);
	
}else{
	print("file size is too small, "+filesize/1000000+" MB, less than 1MB.");
	logsum=getInfo("log");
	filepath=savedir+"VNC_pre_aligner_log.txt";
	File.saveString(logsum, filepath);
	print("line 80; log file saved");
	run("Quit");
}

origi=getTitle();

//		takeout=newArray(origi,0);
//		C1C20102Takeout(takeout);
noext = prefix;

God(savedir, noext,origi,Batch,myDir0,chanspec,Xresolution,Yresolution,temptype,StackWidth,StackHeight,PathConsolidatedSignal);

updateDisplay();
//run("Close All");
//List.clear();
"Done"

logsum=getInfo("log");
filepath=savedir+"VNC_pre_aligner_log.txt";
File.saveString(logsum, filepath);
print("line 100; log file saved");
run("Quit");


function God(savedir, noext,origi,Batch,myDir0,chanspec,Xresolution,Yresolution,temptype,StackWidth,StackHeight,PathConsolidatedSignal){
	
	bitd=bitDepth();
	
	maxV=65535;
	lowthreRange=300;
	lowthreMin=40;
	lowthreAveRange=20;
	//	setMinAndMax(0, 4095);
	
	if (bitd==8){
		setMinAndMax(0, 255);
		run("16-bit");
		run("Histgram stretch", "lower=0 higher=255 3d");
		setMinAndMax(0, maxV);
		
		print("8bit");
		//	maxV=255;
		//	lowthreRange=20;
		//	lowthreMin=5;
		//	lowthreAveRange=6
	}
	//origi=getTitle();
	donotOperate=0;
	
	getDimensions(width, height, channels, slices, frames);
	
	if(channels>1){
		run("Split Channels");//C2 is nc82
		
		titlelist=getList("image.titles");
		signal_count = 0;
		neuronTitle=newArray(titlelist.length);
		////Channel spec /////////////////////////////////////////////		
		nc82=0;
		for (i=titlelist.length-1; i>=0; i--) {
			//	wname = "C" + (i+1) + "-original";
			selectWindow(titlelist[i]);
			
			if(titlelist.length>1){
				if(nc82==0){
					selectWindow(titlelist[titlelist.length-1]);
					nc82=getImageID();
				}else if(signal_count==0){
					neuron=getImageID();
					neuronTitle[0]=getTitle();
					signal_count=signal_count+1;
					print("neuron; "+neuron+"  "+titlelist[i]);
				}else if(signal_count==1){
					neuron2=getImageID();
					print("neuron2; "+neuron2+"  "+titlelist[i]);
					neuronTitle[1]=getTitle();
					signal_count=signal_count+1;
				}else if(signal_count==2){
					neuron3=getImageID();
					print("neuron3; "+neuron3+"  "+titlelist[i]);
					neuronTitle[2]=getTitle();
					signal_count=signal_count+1;
				}else if(signal_count==3){
					neuron4=getImageID();
					neuronTitle[3]=getTitle();
					signal_count=signal_count+1;
				}else if(signal_count==4){
					neuron5=getImageID();
					neuronTitle[4]=getTitle();
				}
			}
		}//for (i=0; i<lengthOf(chanspec); i++) {
		
		selectImage(nc82);
		
		logsum=getInfo("log");
		filepath=savedir+"VNC_pre_aligner_log.txt";
		File.saveString(logsum, filepath);
		
		//	setBatchMode(false);
		//	updateDisplay();
		//	"do"
		//	exit();
		
		if(donotOperate==0){
			getVoxelSize(vxwidth, vxheight, depth, unit1);
			
			vxwidth=Xresolution;
			vxheight=Yresolution;
			
			run("Properties...", "channels=1 slices="+nSlices+" frames=1 unit=pixels pixel_width=1 pixel_height=1 voxel_depth=1");//setting property, voxel size 1,1,1 for later translation.
			
			run("Set Measurements...", "area centroid center perimeter fit shape redirect=None decimal=2");
			
			/////////// background histogram analysis /////////////////////
			avethre=0;
			
			ThreArray=newArray(lowthreAveRange, lowthreMin, lowthreRange, maxV, avethre);
			lowerThresholding (ThreArray);//creating array for background value
			avethre=ThreArray[4];// background average value
			
			////// lower value thresholding & Histogram stretch /////////////////////////
			for(n2=1; n2<=nSlices; n2++){
				setSlice(n2);
				lowthre=List.get("Slicen"+n2);// background value, slice by slice
				lowthre=round(lowthre);
				
				run("Histgram stretch", "lower="+lowthre+" higher=65535");
				//	print("lowerthreshold; "+lowthre+"  Slice No; "+n2);
			}//for(n2=1; n2<=nSlices; n2++){
			
			//	setBatchMode(false);
			//	updateDisplay();
			//	"do"
			//	exit();
			
			//// Mask creation//////////////////////////////
			if(CLAHEwithMASK==1){//CLAHE with Mask
				run("Duplicate...", "title=Mask.tif duplicate");
				Mask=getImageID();
				highthre=0;
				highthreSum=0;
				
				//setBatchMode(false);
				//	updateDisplay();
				//	"do"
				//	exit();
				
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
				for(i=1; i<=nSlices; i++){
					showStatus("Creating Mask");
					prog=i/nSlices;
					showProgress(prog);
					
					setSlice(i);
					setMinAndMax(0, 255);
					
					//run("Enhance Local Contrast (CLAHE)", "blocksize=15 histogram=256 maximum=3 mask=*None* fast_(less_accurate)");
					
					setAutoThreshold("Huang dark");
					//	setAutoThreshold("Default dark");
					
					getThreshold(lower, upper);
					//		print(i+"  lower; "+lower+"  upper; "+upper);
					
					List.set("Lowthre1st"+i-1, lower)
					
				}//for(i=1; i<=nSlices; i++){
				
				print("avethreDef; "+avethreDef);
				
				logsum=getInfo("log");
				File.saveString(logsum, filepath);
				
				for(ig=1; ig<=nSlices; ig++){
					setSlice(ig);
					
					lowList=List.get("Lowthre1st"+ig-1);
					lowList=round(lowList);
					
					if(lowList<avethreDef)
					lowList=avethreDef;
					
					setThreshold(lowList, maxV);
					run("Convert to Mask", "method=Default background=Default only black");
				}
				
				run("Size based Noise elimination", "ignore=229 less=6");
				
				//	setBatchMode(false);
				//	updateDisplay();
				//	"do"
				//	exit();
				
				run("16-bit");
				run("Mask255 to 4095");//Mask.tif
			}//if(CLAHEwithMASK==1){//CLAHE with Mask
			
			selectImage(nc82);
			run("Gamma ", "gamma=1.60 3d in=[In macro]");
			DUP=getImageID();
			
			
			selectImage(nc82);
			close();
			
			CLEAR_MEMORY();
			
			//	setBatchMode(false);
			//	updateDisplay();
			//	"do"
			//	exit();
			
			/// CLAHE, brightness equalization /////////////////////////////////////////////
			for(ii=1; ii<=nSlices; ii++){
				prog=ii/nSlices;
				showProgress(prog);
				showStatus("Enhance Local Contrast (CLAHE)");
				
				if(CLAHEwithMASK==1){//CLAHE with Mask
					selectImage(Mask);
					setSlice(ii);
				}
				
				selectImage(DUP);
				setSlice(ii);
				setMinAndMax(0, maxV);
				
				if(CLAHEwithMASK==1)//CLAHE with Mask
				run("Enhance Local Contrast (CLAHE)", "blocksize=60 histogram=4095 maximum=12 mask=Mask.tif fast_(less_accurate)");
				else
				run("Enhance Local Contrast (CLAHE)", "blocksize=60 histogram=4095 maximum=8 mask=*None* fast_(less_accurate)");
			}
			
			if(CLAHEwithMASK==1){//CLAHE with Mask
				selectImage(Mask);
				close();
				CLEAR_MEMORY();
			}
			
			////// VNC segmentatiom & rotation, Findout best threshold for better AR ////////////////////////////////////////////////
			numberResults=0; mask1st=0; invertON=0;	maxARshape=0; ARshape=0; maxsizeData=0; maxsizeData=0;
			
			for(MIPstep=1; MIPstep<3; MIPstep++){
				for(ThreTry=0; ThreTry<3; ThreTry++){
					
					showStatus("VNC rotation");
					selectImage(DUP);
					
					//	setBatchMode(false);
					//		updateDisplay();
					//		"do"
					//exit();
					
					if(MIPstep==1)
					run("Z Project...", "projection=[Average Intensity]");
					
					if(MIPstep==2)
					run("Z Project...", "projection=[Max Intensity]");
					
					AIP=getImageID();
					
					run("Minimum...", "radius=2");
					run("Maximum...", "radius=2");
					//		
					//		setBatchMode(false);
					//		updateDisplay();
					//		"do"
					//		exit();
					
					if(ThreTry==0)
					setAutoThreshold("Triangle dark");
					
					if(ThreTry==1)
					setAutoThreshold("Default dark");
					
					if(ThreTry==2)
					setAutoThreshold("Huang dark");
					
					//setAutoThreshold("Intermodes dark");
					getThreshold(lower, upper);
					setThreshold(lower, maxV);
					run("Make Binary");
					
					run("Analyze Particles...", "size=20000.00-Infinity show=Masks display exclude clear");
					
					run("Grays");
					updateResults();
					
					if(nResults==0){
						run("Invert LUT");
						run("RGB Color");
						run("8-bit");
						
						run("Analyze Particles...", "size=10000-Infinity show=Nothing display exclude clear");
						if(nResults>0){
							invertON=1;
							print("542 Inverted BW");
							updateResults();
						}
					}
					maskTest=getImageID();
					
					DD2=1; DD3=0;
					FILL_HOLES(DD2, DD3);
					maskTest=getImageID();
					
					maxsizeOri=0;
					
					if(nResults>0){
						numberResults=nResults;
						for(inn=0; inn<nResults; inn++){
							maxsize0=getResult("Area", inn);
							
							if(maxsize0>maxsizeOri){
								ARshape=getResult("AR", inn);// AR value from Triangle
								maxsizeOri=maxsize0;
								angleT=getResult("Angle", inn);
								SizeMT=maxsize0;
							}
						}//for(inn=0; inn<nResults; inn++){
						
						
						
						if(ARshape>1.8){
							if(maxsizeData<maxsizeOri){
								maxsizeData=maxsizeOri;
								if(maxARshape<ARshape){
									maxARshape=ARshape;
									//			print("seg_ARshape; "+ARshape);
									if(mask1st!=0){//previous mask result
										selectImage(mask1st);
										close();
									}
									selectImage(maskTest);
									mask1st=getImageID();//このマスクを元にしてローテーション、中心座標を得る
									numberResults=1;
									lowerM=lower; threTry=ThreTry; angle=angleT; SizeM=SizeMT; finalMIP=MIPstep;
									print("   lowerM; "+lowerM+"   threTry; "+threTry+"   angle; "+angle+"   SizeM; "+SizeM+"   maxARshape; "+maxARshape+"   finalMIP; "+finalMIP);
									
									logsum=getInfo("log");
									File.saveString(logsum, filepath);
								}
							}//	if(maxARshape<ARshape){
						}else{
							selectImage(maskTest);
							close();
						}//if(ARshape>1.75){
					}else{
						selectImage(maskTest);
						close();
					}//if(nResults>0){
					
					if(isOpen(AIP)){
						selectImage(AIP);
						close();
					}
				}//for(ThreTry=0; ThreTry<3; ThreTry++){
			}//for(MIPstep=1; MIPstep<3; MIPstep++){
			
			//	selectImage(mask1st);
			//			setBatchMode(false);
			//			updateDisplay();
			//			"do"
			//			exit();
			donotOperate=0;
			pretitle=-1; Threstep=10;
			
			if(maxARshape<1.8 && maxARshape!=0)
			donotOperate=1;
			
			
			
			if(maxARshape==0){//All 3 thresholding 0 result, connecting with brain, or short VNC
				selectImage(DUP);
				run("Z Project...", "projection=[Average Intensity]");
				AIP=getImageID();
				ThreTry=3;
				numberResults=0;
			}
			
			//	selectImage(mask1st);
			print("numberResults; "+numberResults+"  maxARshape; "+maxARshape);
			
			logsum=getInfo("log");
			File.saveString(logsum, filepath);
			
			//	setBatchMode(false);
			//		updateDisplay();
			//		"do"
			//			exit();
			
			startlower=1; trynum=0; step1=0;
			while(numberResults==0 && donotOperate==0){
				//		print(lower+"  No; "+trynum+"   Images; "+nImages);
				
				if(mask1st!=0){
					if(isOpen(mask1st)){
						selectImage(mask1st);
						close();
					}
				}
				
				selectImage(AIP);
				run("Duplicate...", "title=DUP_AVEP.tif");
				DUP_AVEP=getImageID();
				
				lower=lower+2;
				
				if(lower>3000){
					if(step1==1){
						donotOperate=1;
						print("Check data, no signals? or VNC is hitting edge of data");
						
						logsum=getInfo("log");
						File.saveString(logsum, filepath);
					}
					if(step1==0){
						close();
						selectImage(DUP);
						run("Z Project...", "projection=[Max Intensity]");
						DUP_AVEP=getImageID();
						numberResults=0;
						lower=1;
						step1=1;
					}
				}
				
				
				setThreshold(lower, maxV);
				
				run("Make Binary");
				
				if(invertON==1){
					run("Invert LUT");
					run("RGB Color");
					run("8-bit");
					print("inverted 755");
				}
				
				run("Analyze Particles...", "size=10000.00-Infinity show=Masks display exclude clear");
				
				if(nResults==0){
					run("Invert LUT");
					run("RGB Color");
					run("8-bit");
					
					run("Analyze Particles...", "size=10000-Infinity show=Nothing display exclude clear");
					if(nResults>0){
						invertON=1;
						print("542 Inverted BW");
						updateResults();
					}
				}
				
				mask1st=getImageID();
				
				run("Grays");
				updateResults();
				
				selectImage(DUP_AVEP);
				close();
				
				lowerM=lower;
				
				if(nResults>0){
					maxsize=40000;
					for(i=0; i<nResults; i++){
						Size=getResult("Area", i);
						ARshape=getResult("AR", i);// AR value from Triangle
						
						if(ARshape>1.9){
							if(Size>maxsize){
								maxsize=Size;
								angle=getResult("Angle", i);
								SizeM=getResult("Area", i);
								numberResults=nResults;
								print("increment method");
								logsum=getInfo("log");
								File.saveString(logsum, filepath);
							}
						}
					}//for(i=0; i<nResults; i++){
				}else{
					
					selectImage(mask1st);
					close();
				}//if(nResults>0){
				
				
				trynum=trynum+1;
			}//while(nResults==0  && donotOperate==0){
			
			
			if(isOpen(AIP)){
				selectImage(AIP);
				close();
			}
			
			if(donotOperate==0){
				
				if(ThreTry==0)
				ThreMethod="Triangle";
				
				if(ThreTry==1)
				ThreMethod="Default";
				
				if(ThreTry==2)
				ThreMethod="Huang";
				
				if(ThreTry==3)
				ThreMethod="Histogram 2 increment method";
				
				print("lower thresholding for Br and VNC separation; "+lowerM+"  ThreMethod; "+ThreMethod);
				
				logsum=getInfo("log");
				File.saveString(logsum, filepath);
				
				selectImage(mask1st);
				
				run("Grays");
				run("Maximum...", "radius=20");
				run("Minimum...", "radius=20");
				run("Make Binary");
				
				run("Fill Holes");
				
				if(invertON==1){
					run("Invert LUT");
					run("RGB Color");
					run("8-bit");
					print("invert 870");
				}
				
				rotation=270+angle;
				print("angle; "+angle);
				
				logsum=getInfo("log");
				File.saveString(logsum, filepath);
				
				//		setBatchMode(false);
				//		updateDisplay();
				//				"do"
				//				exit();
				
				CLEAR_MEMORY();	
				///// BW analysis ////////////////////////////////////////////////////////
				
				run("Duplicate...", " ");
				makeRectangle(10,14,74,22);
				getStatistics(area, mean2, min, max, std, histogram);
				
				if(mean2>200){
					run("Invert LUT");
					run("RGB Color");
					invertON=1;
				}
				run("Select All");
				
				rotation=round(rotation);
				run("16-bit");
				sampleLongLength=round(sqrt(height*height+width*width));
				run("Canvas Size...", "width="+sampleLongLength+" height="+sampleLongLength+" position=Center zero");
				run("Rotation Hideo", "rotate="+rotation+" in=InMacro");
				
				//		run("Rotate... ", "angle="+rotation+" grid=1 interpolation=None fill enlarge");
				MIPduplicateRotation=getImageID();
				
				run("Select All");
				run("Make Binary");
				
				if(nResults>1)
				setSize=SizeM/2;
				else
				setSize=10000;
				
				run("Analyze Particles...", "size="+setSize+"-Infinity show=Nothing display exclude clear");//exclude object on the edge
				updateResults();
				
				//	setBatchMode(false);
				//		updateDisplay();
				//		"do"
				//		exit();
				
				///// BW analysis ////////////////////////////////////////////////////////
				if(nResults==0){
					run("Invert LUT");
					run("RGB Color");
					run("8-bit");
					invertON=1;
					run("Analyze Particles...", "size="+setSize+"-Infinity show=Nothing display exclude clear");
					updateResults();
				}
				
				if(nResults>1){
					//		setBatchMode(false);
					//		updateDisplay();
					print("not single sample, skipped");
					
					logsum=getInfo("log");
					File.saveString(logsum, filepath);
					
					donotOperate=1;
				}
				xTrue=0; yTrue=0;
				if(donotOperate==0 && nResults==1){
					xTrue=getResult("X", 0);
					yTrue=getResult("Y", 0);
					
					
					selectImage(mask1st);
					
					//		setBatchMode(false);
					//			updateDisplay();
					//			"do"
					//			exit();
					close();
					
					selectImage(MIPduplicateRotation);
					close();
					
					selectImage(DUP);
					//		setBatchMode(false);
					//		updateDisplay();
					//			"do"
					//		exit();
					
					rotationF(rotation,unit1,vxwidth,vxheight,depth,xTrue,yTrue,StackWidth,StackHeight);
					
					///// Z- start and ending slice detection ////////////////////////////////////////////////
					selectImage(DUP);
					run("Duplicate...", "title=Mask.tif duplicate");
					Mask=getImageID();
					
					highthre=0;
					highthreSum=0;
					
					for(i=1; i<=nSlices; i++){
						showStatus("Creating Mask");
						prog=i/nSlices;
						showProgress(prog);
						
						setSlice(i);
						//	setAutoThreshold("Default dark");
						setAutoThreshold("RenyiEntropy dark");
						getThreshold(lower, upper);
						
						if(lower>highthre){
							if(i>10){
								highthre=lower;
								highslice=i;
							}
						}
						highthreSum=highthreSum+lower;
					}//for(i=1; i<=nSlices; i++){
					avehighThre=highthreSum/nSlices;
					print("highslice; "+highslice+"  highthre; "+highthre/2+"  avehighThre; "+avehighThre);
					
					logsum=getInfo("log");
					File.saveString(logsum, filepath);
					
					//		setBatchMode(false);
					//			updateDisplay();
					//			"do"
					//			exit();
					avehighThre=round(avehighThre);
					//		print("maxV; "+maxV);
					
					setSlice(highslice);// set slice that has highest lower thresholding
					setThreshold(avehighThre, maxV);//setting threshold, this value will apply to entire slices
					
					run("Make Binary", "method=Huang background=Dark black");
					
					run("Remove Outliers...", "radius=2 threshold=50 which=Bright");
					run("Minimum...", "radius=2 stack");
					run("Maximum...", "radius=2 stack");
					
					//		setBatchMode(false);
					//		updateDisplay();
					//		"do"
					//		exit();
					
					if(BWd==1){//BW decision
						makeRectangle(69, 144, 383, 860);
						////////// BW decision //////////////
						maxmean=0;
						for(areaS=1; areaS<nSlices; areaS++){
							setSlice(areaS);
							getStatistics(area, mean, min, max, std, histogram);
							
							if(maxmean<mean){
								maxmean=mean;
								maxmeanSlice=areaS;
							}
						}
						
						run("Select All");
						
						setSlice(maxmeanSlice);
						run("Duplicate...", " ");
						MaxBWdup=getImageID();
						run("Analyze Particles...", "size=10000-Infinity display exclude clear");
						
						if(nResults==0){
							run("Invert LUT");
							run("RGB Color");
							run("8-bit");
							invertON=1;
							print("864 Inverted BW");
							run("Analyze Particles...", "size=10000-Infinity display exclude clear");
						}
						
						//			setBatchMode(false);
						//			updateDisplay();
						//				"do"
						//			exit();
						
						if(nResults==0){
							print("Check data, zero data");
							
							logsum=getInfo("log");
							File.saveString(logsum, filepath);
						}
						
						selectImage(MaxBWdup);
						close();
					}//if(BWd==1){
					
					selectImage(Mask);
					//		print(nSLices+"   1021");
					DD2=0; DD3=1;
					FILL_HOLES(DD2, DD3);
					
					Mask=getImageID();
					rename("Mask.tif");
					
					run("Remove Outliers...", "radius=2 threshold=50 which=Bright");
					run("Make Binary", "method=Huang background=Dark black");
					
					setSlice(nSlices);
					scan_for_invert ();
					
					//	setBatchMode(false);
					//		updateDisplay();
					//			"do"
					//			exit();
					
					/// Start and End slice decision /////////////////////////////////////////////
					//print("preskelton");
					run("Size to Skelton");
					//print("postskelton");
					getDimensions(width, height, channels, slices, frames);
					startslice=0;
					endslice=0;
					posiSnum=newArray(slices);
					SizeMAX=newArray(slices+1);
					makeRectangle(38, round(width/3), width*(435/600), height*(700/1024));
					
					sumSeven=0;
					for(b=1; b<=nSlices; b++){
						setSlice(b);
						
						sevencounts=0; maxI=0;
						getHistogram(values, counts,  256);
						for(i=0; i<50; i++){
							Val=counts[i];
							
							if(i==7){
								sevencounts=counts[i];
								sumSeven=sumSeven+sevencounts;
							}
							if(i>maxI){
								if(Val>0){
									maxI=i;	
								}
							}
						}
						List.set("SliceSeven"+b-1, sevencounts);
						List.set("MaxValue"+b-1, maxI);
						//			print("SLice; "+b+"   value; "+maxI);
					}//for(b=1; b<=nSlices; b++){
					aveSeven=sumSeven/nSlices;
					
					insideSD0=0;
					for(stdThre0=1; stdThre0<5; stdThre0++){
						
						insideSD0=((0-aveSeven)*(0-aveSeven))+insideSD0;
					}
					sqinside0=insideSD0/5;
					sd0 = sqrt(sqinside0);
					endsliceDeside=0; minus1stTime=0;
					
					for(startdeci=0; startdeci<nSlices; startdeci++){
						sumVal5=0; insideSD=0;
						for(stdThre=startdeci; stdThre<startdeci+5; stdThre++){
							val5=List.get("SliceSeven"+stdThre);
							val5=round(val5);
							insideSD=((val5-aveSeven)*(val5-aveSeven))+insideSD;
							sumVal5=sumVal5+val5;
						}
						sqinside=insideSD/5;
						sd = sqrt(sqinside);
						
						sdGap=sd0-sd;
						//	print("SD; "+sd+"  Slice; "+startdeci+1+"   sdgap; "+sdGap);
						
						if(sdGap<0)
						minus1stTime=1;
						
						if(sdGap!=NaN){
							if(sdGap>0){
								if(minus1stTime==1){
									if(startslice==0)
									startslice=startdeci;
								}
							}
						}
						
						if(startslice==0){
							
							MaxSize=List.get("MaxValue"+startdeci);
							MaxSize=round(MaxSize);
							if(MaxSize>20){
								
								startslice=startdeci;
								print("Start slice is...; "+startdeci+"  MaxVal; "+MaxSize);
								logsum=getInfo("log");
								File.saveString(logsum, filepath);
							}
						}//if(startslice==0){
						List.set("SDGAP"+startdeci, sdGap);
					}//for(startdeci=0; startdeci<slices; startdeci++){
					minus1stTime=0;
					for(endS=nSlices-1; endS>=0; endS--){
						SdGend=List.get("SDGAP"+endS);
						SdGend=round(SdGend);
						
						if(SdGend<0)
						minus1stTime=1;
						
						if(SdGend!=NaN){
							if(SdGend>0){
								if(minus1stTime==1){
									if(endslice==0){
										endslice=endS+1;
									}
								}
							}
						}
					}
					sliceGap=endslice-startslice;
					
					print("1st slice position;  startslice; "+startslice+"   endslice; "+endslice);
					if(endslice==0 || sliceGap<70){
						for(endS2=nSlices-1; endS2>=0; endS2--){
							if(endsliceDeside==0){
								MaxSize2=List.get("MaxValue"+endS2);
								MaxSize2=round(MaxSize2);
								if(MaxSize2>19){
									
									endslice=endS2;
									print("End slice is...; "+endS2+"  MaxVal; "+MaxSize2);
									logsum=getInfo("log");
									File.saveString(logsum, filepath);
									endsliceDeside=1;
								}
							}//if(endsliceDeside==0){
						}//for(endS2=nSlices-1; endS2>=0; endS2--){
					}//if(endslice==0){
					
					sliceGap=endslice-startslice;
					if(startslice==endslice || sliceGap<40)
					endslice=startslice+110;
					
					print("startslice; "+startslice+"  endslice; "+endslice);
					
					logsum=getInfo("log");
					File.saveString(logsum, filepath);
					
					selectImage(DUP);
					slicePosition=newArray(startslice,endslice,slices,0,0);
					addingslice(slicePosition);
					
					Rstartslice=slicePosition[3];
					Rendslice=slicePosition[4];
					
					//			setBatchMode(false);
					//				updateDisplay();
					//				"do"
					//			exit();
					
					/// Front & Back detection //////////////////////////////////////////
					if(FrontBackAnalysis==1){
						selectImage(Mask);
						run("Z Project...", "start="+startslice+" stop="+startslice+10+" projection=[Max Intensity]");
						setThreshold(2, 255);
						run("Convert to Mask");
						
						if(invertON==1){
							run("Invert LUT");
							run("RGB Color");
							run("8-bit");
						}
						aveF=getImageID();
						//	run("Analyze Particles...", "size=1000-Infinity circularity=0.00-1.00 show=Nothing display clear");
						run("Analyze Particles...", "size=1000-Infinity show=Nothing display exclude clear");
						
						sumAR=0; sumAF=0; sumAC=0;
						for(frontR=0; frontR<nResults; frontR++){//AR result measurement
							AR=getResult("AR", frontR);
							sumAR=sumAR+AR;
							AreaF=getResult("Area", frontR);
							sumAF=sumAF+AreaF;
							Circ=getResult("Circ.", frontR);
							sumAC=sumAC+Circ;
						}
						aveARF=sumAR/nResults;//average AR front slices
						aveAreaF=sumAF/nResults;//average Area front slices
						aveCircF=sumAC/nResults;
						resultNumF=nResults;
						//		selectImage(aveF);
						//	close();
						
						selectImage(Mask);
						run("Z Project...", "start="+endslice-10+" stop="+endslice+" projection=[Max Intensity]");
						setThreshold(2, 255);
						run("Convert to Mask");
						
						if(invertON==1){
							run("Invert LUT");
							run("RGB Color");
							run("8-bit");
						}
						
						aveR=getImageID();
						run("Analyze Particles...", "size=1000-Infinity show=Nothing display exclude clear");
						
						sumAR=0; sumAF=0; sumAC=0;
						for(rearR=1; rearR<nResults; rearR++){//Area result measurement
							AR=getResult("AR", rearR);
							sumAR=sumAR+AR;
							AreaR=getResult("Area", rearR);
							sumAF=sumAR+AreaR;
							Circ=getResult("Circ.", rearR);
							sumAC=sumAC+Circ;
						}
						aveARR=sumAR/nResults;//average AR rear slices
						aveAreaR=sumAF/nResults;//average Area rear slices
						aveCircR=sumAC/nResults;
						resultNumR=nResults;
					}//	if(FrontBackAnalysis==1){
					//	setBatchMode(false);
					//		updateDisplay();
					//		"do"
					//		exit();
					
					selectImage(Mask);
					close();
					CLEAR_MEMORY();
					selectImage(DUP);
					
					if(Rstartslice<Rendslice)
					run("Make Substack...", "  slices="+Rstartslice+"-"+Rendslice+"");
					
					//		setBatchMode(false);
					//	updateDisplay();
					//		"do"
					//		exit();
					
					realVNC=getImageID();
					
					if(Rstartslice<Rendslice){
						selectImage(DUP);
						close();
						CLEAR_MEMORY();
					}
					
					//	selectImage(realVNC);
					//	rename(nc82);
					
					FrontAndBack=0;
					
					if(FrontBackAnalysis==1){
						if(aveCircR>aveCircF){//if rear is ventral slice
							FrontAndBack=FrontAndBack+1;
						}
						if(resultNumR>2)
						FrontAndBack=FrontAndBack+1;
						
						selectImage(realVNC);
						//color depth MIP, measure blue and red in the center of data. brighter is front
						if(FrontAndBack>0){
							run("Reverse");
							
							for(addingSF=1; addingSF<=5; addingSF++){
								setSlice(1);
								run("Add Slice");
							}
							for(addingSR=1; addingSR<=5; addingSR++){
								setSlice(nSlices);
								run("Delete Slice");
							}
							print("Ventral - Dorsal inverted!"+"  resultNumR; "+resultNumR+"  resultNumF; "+resultNumF+"  aveCircR; "+aveCircR+"  aveCircF; "+aveCircF);
							
							logsum=getInfo("log");
							File.saveString(logsum, filepath);
						}
					}//if(FrontBackAnalysis==1){
					
					sliceGap=endslice-startslice;
					
					if(temptype=="f")
					depth=(170/sliceGap)*0.7;//depth adjustment same as template
					
					if(temptype=="m")
					depth=(160/sliceGap)*0.7;//depth adjustment same as template
					
					selectImage(realVNC);//final product for nc82
					
					run("Properties...", "channels=1 slices="+nSlices+" frames=1 unit=microns pixel_width="+vxwidth+" pixel_height="+vxheight+" voxel_depth="+depth+"");
					
					
					///// Shape analysis, for kicking broken / not well aligned sample ///////////////////
					if(ShapeAnalysis==1){
						//		print(nSlices+"  1264");
						run("Z Project...", "projection=[Max Intensity]");
						resetMinAndMax();
						origiMIPID0=getImageID();
						run("Gamma ", "gamma=0.60 in=[In macro]");
						origiMIPID=getImageID();
						resetMinAndMax();
						run("8-bit");
						
						selectImage(origiMIPID0);
						close();
						
						//	setBatchMode(false);
						//		updateDisplay();
						//		"do"
						//			exit();
						
						MarkProblem=1;// create a white Mark on right top
						
						ShapeProblem=0;
						selectImage(origiMIPID);
						print("");
						
						lowthreMIP=0; MaxARshape=0; MaxAngle=0; Angle_AR_measure=1; FirstAR=0;
						
						SmeasurementArray=newArray(origiMIPID,0,2,3,4,MaxARshape,MaxAngle,Angle_AR_measure,0,0,MarkProblem,11,12,13,invertON,realVNC,0,FirstAR,StackWidth,StackHeight,savedir);
						shapeMeasurement(SmeasurementArray);
						
						lowthreMIP=SmeasurementArray[2];
						LXminsd=SmeasurementArray[3];
						LYminsd=SmeasurementArray[4];
						MaxARshape=SmeasurementArray[5];
						MaxAngle=SmeasurementArray[6];
						
						ShapeProblem=SmeasurementArray[9];
						RXminsd=SmeasurementArray[12];
						RYminsd=SmeasurementArray[13];
						MaxShapeNo=SmeasurementArray[16];
						FirstAR=SmeasurementArray[17];
						
						//			print("   LXsd; "+LXminsd+"  LYsd; "+LYminsd);
						//			print("   RXsd; "+RXminsd+"  RYsd; "+RYminsd+"  Threshold; "+lowthreMIP+"  MaxARshape; "+MaxARshape);
						
						//if the shape is strange, rotation and measure again ////////////////////////////
						if(LXminsd>20 || LYminsd>75 || RXminsd>20 || RYminsd>75){
							print("   Rotation angle; "+MaxAngle);
							
							logsum=getInfo("log");
							File.saveString(logsum, filepath);
							
							Angle_AR_measure=0;
							SmeasurementArray=newArray(origiMIPID,0,2,LXminsd,LYminsd,MaxARshape,MaxAngle,Angle_AR_measure,0,ShapeProblem,MarkProblem,11,12,13,invertON,realVNC,0,FirstAR,StackWidth,StackHeight,savedir);
							shapeMeasurement(SmeasurementArray);
							
							lowthreMIP=SmeasurementArray[2];
							LXminsd=SmeasurementArray[3];
							LYminsd=SmeasurementArray[4];
							MaxAngle=SmeasurementArray[6];
							
							ShapeProblem=SmeasurementArray[9];
							RXminsd=SmeasurementArray[12];
							RYminsd=SmeasurementArray[13];
							MaxShapeNo=SmeasurementArray[16];
							FirstAR=SmeasurementArray[17];
							
							//		setBatchMode(false);
							//			updateDisplay();
							//			"do"
							//			exit();
							
							updateDisplay();
							
							print("   LXsd2; "+LXminsd+"  LYsd2; "+LYminsd);
							print("   RXsd2; "+RXminsd+"  RYsd2; "+RYminsd+"  Threshold2; "+lowthreMIP+"  MaxARshape2; "+MaxARshape);
							
							logsum=getInfo("log");
							File.saveString(logsum, filepath);
							
							if(LXminsd>24 || LYminsd>75){
								//	if(Xminsd>20){
								print("Left side VNC shape has problem! ");
								logsum=getInfo("log");
								File.saveString(logsum, filepath);
								ShapeProblem=1;
							}
							if(RXminsd>24 || RYminsd>75){
								//	if(Xminsd>20){
								print("Right side VNC shape has problem! ");
								logsum=getInfo("log");
								File.saveString(logsum, filepath);
								ShapeProblem=1;
							}
						}//	if(Xminsd>20 || Yminsd>065){
						
						
						/// Copy to Original image/stack ///////////////////////
						if(MaxShapeNo<=6 || MaxShapeNo>=8 ){
							selectImage(origiMIPID);
							run("Duplicate...", "title=DUP_MIP");
						}
						if(MaxShapeNo==7){
							selectImage(realVNC);
							run("Z Project...", "projection=[Average Intensity]");
							run("Properties...", "channels=1 slices=1 frames=1 unit=microns pixel_width=1 pixel_height=1 voxel_depth=1");
							setThreshold(lowthreMIP, 65536);
						}
						VNCDUP2=getImageID();
						
						if(MaxShapeNo==4){
							//	run("Enhance Local Contrast (CLAHE)", "blocksize=60 histogram=256 maximum=6 mask=*None* fast_(less_accurate)");
							run("Gamma ", "gamma=1.70 in=InMacro");
						}
						
						if(MaxShapeNo<=6 || MaxShapeNo>=8)
						setThreshold(lowthreMIP, 255);
						
						
						run("Make Binary");
						
						MIPgenerateArray=newArray(0,1,invertON);
						MIPgenerate(MIPgenerateArray);
						
						VNCmask=getImageID();
						
						scan_for_invert();
						
						if(ShapeProblem==1 && MarkProblem==1){
							selectImage(VNCmask);
							makeRectangle(15, 22, 55, 55);
							setForegroundColor(255, 255, 255);
							run("Fill", "slice");
							run("Select All");
							
							saveAs("PNG", savedir+noext+"_Mask.png");
							saveAs("PNG", myDir0+noext+"_Mask.png");
						}
						
						run("Make Binary");
						run("Copy");
						
						selectImage(VNCDUP2);
						close();
						
						selectImage(VNCmask);
						close();
						
						if(isOpen("DUP_DUP_MIP")){
							selectWindow("DUP_DUP_MIP");
							close();
						}
						//			CLEAR_MEMORY();
						
						selectImage(origiMIPID);
						run("Paste");
						run("Make Binary");
						
					}//if(ShapeAnalysis==1){
					////// scan left/right both side to detect 3 x2 leg //////////////				
					
					
					///// file save as nrrd /////////////////////////////////////////////
					if(donotOperate==0){//open from directory, not from Image
						
						if(MIPsave==1){
							selectImage(realVNC);
							run("Z Project...", "start=1 stop="+nSlices+" projection=[Max Intensity]");
							resetMinAndMax();
							run("8-bit");
							
							if(ShapeProblem==0)
							saveAs("PNG", savedir+noext+".png");
							else
							saveAs("PNG", myDir0+noext+".png");
							
							close();
						}
						selectImage(realVNC);
						//		run("Nrrd ... ", "nrrd="+savedir+noext+"_01.nrrd");
						
						if(ShapeProblem==0){
							if(FrontAndBack==0)
							run("Nrrd Writer", "compressed nrrd="+savedir+noext+"_01.nrrd");
							
							if(FrontAndBack>0)
							run("Nrrd Writer", "compressed nrrd="+savedir+noext+"_Rev_01.nrrd");
						}else{//ShapeProblem==1
							if(FrontAndBack==0)
							run("Nrrd Writer", "compressed nrrd="+myDir0+noext+"_01.nrrd");
							
							if(FrontAndBack>0)
							run("Nrrd Writer", "compressed nrrd="+myDir0+noext+"_Rev_01.nrrd");
						}
						
						close();
						
						if(titlelist.length>1){
							for(exportchannel=1; exportchannel<titlelist.length; exportchannel++){
								
								if(exportchannel==1){
									if(isOpen(neuron))
									selectImage(neuron);
									
									if(isOpen(neuronTitle[0]))
									selectWindow(neuronTitle[0]);
									
								}
								
								if(exportchannel==2){
									if(isOpen(neuron2))
									selectImage(neuron2);
									
									if(isOpen(neuronTitle[1]))
									selectWindow(neuronTitle[1]);
								}
								if(exportchannel==3){
									if(isOpen(neuron3))
									selectImage(neuron3);
									
									if(isOpen(neuronTitle[2]))
									selectWindow(neuronTitle[2]);
								}
								if(exportchannel==4)
								selectImage(neuron4);
								
								if(exportchannel==5)
								selectImage(neuron5);
								
								selectedNeuron=getImageID();
								run("Select All");
								
								slicePosition=newArray(startslice,endslice,slices,0,0);
								addingslice(slicePosition);
								
								run("Make Substack...", "  slices="+Rstartslice+"-"+Rendslice+"");
								realNeuron=getImageID();//substack, duplicated
								
								if(FrontAndBack>0)
								run("Reverse");
								
								run("Properties...", "channels=1 slices="+nSlices+" frames=1 unit=pixels pixel_width=1 pixel_height=1 voxel_depth=1");
								rotationF(rotation,unit1,vxwidth,vxheight,depth,xTrue,yTrue,StackWidth,StackHeight);
								selectImage(realNeuron);
								run("Properties...", "channels=1 slices="+nSlices+" frames=1 unit=microns pixel_width="+vxwidth+" pixel_height="+vxheight+" voxel_depth="+depth+"");
								
								if(ShapeProblem==0){
									if(FrontAndBack>0)
									run("Nrrd Writer", "compressed nrrd="+savedir+noext+"_Rev_0"+exportchannel+1+".nrrd");
									if(FrontAndBack==0)
									run("Nrrd Writer", "compressed nrrd="+savedir+noext+"_0"+exportchannel+1+".nrrd");
								}else{//ShapeProblem==1
									if(FrontAndBack>0)
									run("Nrrd Writer", "compressed nrrd="+myDir0+noext+"_Rev_0"+exportchannel+1+".nrrd");
									
									if(FrontAndBack==0)
									run("Nrrd Writer", "compressed nrrd="+myDir0+noext+"_0"+exportchannel+1+".nrrd");
								}
								
								selectImage(realNeuron);
								close();
								selectImage(selectedNeuron);
								close();
							}//for(exportchannel=1; exportchannel<=titlelist.length; exportchannel++){
							
							run("Close All");
							
							ConsoliExi=File.exists(PathConsolidatedSignal);//neuron separator consolidatedsignal
							if(ConsoliExi==1){
								print("Try Open Neuron separator result");
								logsum=getInfo("log");
								File.saveString(logsum, filepath);
								
								open(PathConsolidatedSignal);
								print("Opened Neuron separator result");
								logsum=getInfo("log");
								File.saveString(logsum, filepath);
								
								run("Split Channels");
								
								SeparatorTitle=newArray(titlelist.length);
								
								
								for(SeparatorChannel=1; SeparatorChannel<=titlelist.length; SeparatorChannel++){
									
									if(SeparatorChannel==1){
										
										if(isOpen(SeparatorTitle[0]))
										selectWindow(SeparatorTitle[0]);
									}
									
									if(SeparatorChannel==2){
										
										if(isOpen(SeparatorTitle[1]))
										selectWindow(SeparatorTitle[1]);
									}
									if(SeparatorChannel==3){
										
										if(isOpen(SeparatorTitle[2]))
										selectWindow(SeparatorTitle[2]);
									}
									if(SeparatorChannel==4)
									selectImage(SeparatorTitle[3]);
									
									if(SeparatorChannel==5)
									selectImage(SeparatorTitle[4]);
									
									selectedNeuron=getImageID();
									run("Select All");
									
									slicePosition=newArray(startslice,endslice,slices,0,0);
									addingslice(slicePosition);
									
									run("Make Substack...", "  slices="+Rstartslice+"-"+Rendslice+"");
									realNeuron=getImageID();//substack, duplicated
									
									if(FrontAndBack>0)
									run("Reverse");
									
									run("Properties...", "channels=1 slices="+nSlices+" frames=1 unit=pixels pixel_width=1 pixel_height=1 voxel_depth=1");
									rotationF(rotation,unit1,vxwidth,vxheight,depth,xTrue,yTrue,StackWidth,StackHeight);
									selectImage(realNeuron);
									run("Properties...", "channels=1 slices="+nSlices+" frames=1 unit=microns pixel_width="+vxwidth+" pixel_height="+vxheight+" voxel_depth="+depth+"");
									
									if(ShapeProblem==0){
										if(FrontAndBack>0)
										run("Nrrd Writer", "compressed nrrd="+savedir+"ConsolidatedSignal__Rev_"+SeparatorChannel+".nrrd");
										if(FrontAndBack==0)
										run("Nrrd Writer", "compressed nrrd="+savedir+"ConsolidatedSignal__"+SeparatorChannel+".nrrd");
									}else{//ShapeProblem==1
										if(FrontAndBack>0)
										run("Nrrd Writer", "compressed nrrd="+myDir0+"ConsolidatedSignal__Rev_"+SeparatorChannel+".nrrd");
										
										if(FrontAndBack==0)
										run("Nrrd Writer", "compressed nrrd="+myDir0+"ConsolidatedSignal__"+SeparatorChannel+".nrrd");
									}
									
									selectImage(realNeuron);
									close();
									selectImage(selectedNeuron);
									close();
								}//for(SeparatorChannel=1; SeparatorChannel<=titlelist.length; SeparatorChannel++){
							}else{//if(ConsoliExi==1){
								print("There is no ConsolodatedSignal.v3dpbd!!; "+PathConsolidatedSignal);
								logsum=getInfo("log");
								File.saveString(logsum, filepath);
							}//	if(ConsoliExi==1){
						}//if(titlelist.length>1){
					}//
				}
			}	//699: if(donotOperate==0){
			if(donotOperate==1){
				
				if(isOpen(DUP))
				selectImage(DUP);
				
				run("Nrrd Writer", "compressed nrrd="+myDir4+noext+"_Cannot_segment_AR_short"+maxARshape+".nrrd");
				donotOperate=0;
			}
		}//if(donotOperate==0){209
		
		if(donotOperate==1){
			selectImage(DUP);
			run("Nrrd Writer", "compressed nrrd="+myDir4+noext+"_No_nc82.nrrd");
		}
	}else{//if(channel>1)
		
		print("This stack has only single channel!");
		logsum=getInfo("log");
		File.saveString(logsum, filepath);
	}
}//function God(path, dir, savedir, filen,noext){

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
		}
	}
	close();
	
	colorarray[0]=posicolor;
}

function rotationF(rotation,unit,vxwidth,vxheight,depth,xTrue,yTrue,StackWidth,StackHeight){
	setBackgroundColor(0, 0, 0);
	
	getDimensions(width, height, channels, slices, frames);
	sampleLongLength=round(sqrt(height*height+width*width));
	run("Canvas Size...", "width="+sampleLongLength+" height="+sampleLongLength+" position=Center zero");
	run("Rotation Hideo", "rotate="+rotation+" 3d in=InMacro");
	
	makeRectangle(xTrue-round(StackWidth/2), yTrue-StackHeight*(485/1024), StackWidth, StackHeight);
	run("Crop");
	
	getDimensions(width, height, channels, slices, frames);
	if(height<StackHeight || width<StackWidth)
	run("Canvas Size...", "width="+StackWidth+" height="+StackHeight+" position=Top-Left zero");
	run("Select All");
	run("Properties...", "channels=1 slices="+nSlices+" frames=1 unit=microns pixel_width="+vxwidth+" pixel_height="+vxheight+" voxel_depth="+depth+"");
	run("Grays");
}//function

function lowerThresholding (ThreArray){
	lowthreAveRange=ThreArray[0];
	lowthreMin=ThreArray[1];
	lowthreRange=ThreArray[2];
	maxV=ThreArray[3];
	
	for(step=1; step<=2; step++){
		maxisum=0;
		for(n=1; n<=nSlices; n++){
			setSlice(n);
			maxcounts=0; maxi=0;
			
			getHistogram(values, counts, maxV);
			for(i2=0; i2<maxV/2; i2++){
				Val2=0;
				for(iave=i2; iave<i2+lowthreAveRange; iave++){
					Val=counts[iave];
					Val2=Val2+Val;
				}
				ave=Val2/lowthreAveRange;
				if(step==1){
					if(ave>maxcounts){
						if(i2>lowthreMin){
							maxcounts=ave;
							maxi=i2+lowthreAveRange/2;
						}
					}
				}else{
					if(ave>maxcounts){
						if(i2>avethre){
							if(i2<avethre+lowthreRange){
								maxcounts=ave;
								maxi=i2+lowthreAveRange/2;
							}
						}
					}
				}//step==2
			}
			if(step==2){
				List.set("Slicen"+n, maxi);
				//	print("maxi  "+maxi)
				maxisum=maxisum+maxi;
			}
		}//for(n=1; n<=nSlices; n++){
		avethre=maxisum/n;
	}//for(step=1; step<=2; step++){
	ThreArray[4]=avethre;
}//function

function C1C20102Takeout(takeout){
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
	
	dotposition=lastIndexOf(origi, "_C1.zip");
	if (dotposition!=-1)
	origi=substring(origi, 0, dotposition);
	
	dotposition=lastIndexOf(origi, "_C2.zip");
	if (dotposition!=-1)
	origi=substring(origi, 0, dotposition);
	
	dotposition=lastIndexOf(origi, ".");
	if (dotposition!=-1)
	origi=substring(origi, 0, dotposition);
	
	takeout[0]=origi;
}

function addingslice(slicePosition){
	
	startslice=slicePosition[0];
	endslice=slicePosition[1];
	slices=slicePosition[2];
	
	Rstartslice=startslice-10;
	
	if(Rstartslice<1){
		addingStrN=abs(Rstartslice);
		Rstartslice=1;
		
		if(addingStrN>10)
		addingStrN=10;
		
		run("Reverse");
		for(addstr=0; addstr<addingStrN; addstr++){// adding front slices
			
			setSlice(nSlices);
			run("Add Slice");
		}
		run("Reverse");
	}
	
	Rendslice=endslice+40;
	
	if(Rendslice>slices){
		gapEnd=Rendslice-slices;
		if(gapEnd>30)
		gapEnd=30;
		
		for(addend=0; addend<gapEnd; addend++){
			setSlice(nSlices);
			run("Add Slice");
		}
		Rendslice=nSlices;
	}
	
	slicePosition[3]=Rstartslice;
	slicePosition[4]=Rendslice;
}//function addingslice(startslice,endslice){


function shapeMeasurement(SmeasurementArray){
	ResultNstep=0;
	origiMIPID=SmeasurementArray[0];
	MaxARshape=SmeasurementArray[5];
	BestThreM=-1;
	Xminsd=100;
	Yminsd=100;
	lowthreMIP=0;
	FirstAR=SmeasurementArray[17];
	MaxAngle=SmeasurementArray[6];
	MaxShapeNo=0;
	StackWidth=SmeasurementArray[18];
	StackHeight=SmeasurementArray[19];
	savedir=SmeasurementArray[20];
	
	//	print("MaxARshape; from array: "+MaxARshape);
	
	for(LeftRight=0; LeftRight<2; LeftRight++){// for left right 
		
		ARshape=-1;
		Angle_AR_measure=SmeasurementArray[7];
		MarkProblem=SmeasurementArray[10];
		
		invertON=SmeasurementArray[14];
		realVNC=SmeasurementArray[15];
		maxTotalSd=1000000; maxTotalSd2=1000000;
		
		//	setBatchMode(false);
		//		updateDisplay();
		//		"do"
		//	exit();
		
		for(stepMask=1; stepMask<=9; stepMask++){
			AreaMax=0;
			
			if(stepMask<=6 || stepMask>=8){
				selectImage(origiMIPID);
				run("Duplicate...", "title=DUP_MIP");
			}
			if(stepMask==7){
				selectImage(realVNC);
				run("Z Project...", "projection=[Average Intensity]");
			}
			
			run("Properties...", "channels=1 slices=1 frames=1 unit=microns pixel_width=1 pixel_height=1 voxel_depth=1");
			VNCDUP=getImageID();
			
			//	setBatchMode(false);
			//		updateDisplay();
			//		"do"
			//		exit();
			
			getStatistics(area, mean2, min, upperM2, std, histogram);
			
			if(stepMask==1){
				selectImage(VNCDUP);
				getHistogram(values, Scounts,  256);
				totalVal=0; totalValMax=0;
				for(iS=0; iS<256; iS++){
					Val=Scounts[iS];
					totalVal=totalVal+Val;
				}
				for(iSMax=255; iSMax>=0; iSMax--){
					ValMax=Scounts[iSMax];
					totalValMax=totalValMax+ValMax;
					
					TotalRatio=totalValMax/totalVal;
					
					if(TotalRatio>=0.29){
						LowThreMax=iSMax;
						iSMax=-1;
					}
				}//for(iSMax=255; iSMax>=0; iSMax--){
				
				setThreshold(LowThreMax, upperM2);
				run("Make Binary");
				
			}else if(stepMask==2){
				selectImage(VNCDUP);
				setAutoThreshold("Default dark");
				getThreshold(LowThreMax, upperM);
				setThreshold(LowThreMax, upperM2);
				run("Make Binary");
				
			}else if(stepMask==3){
				selectImage(VNCDUP);
				setAutoThreshold("Huang dark");
				getThreshold(LowThreMax, upperM);
				setThreshold(LowThreMax, upperM2);
				run("Make Binary");
				
			}else if(stepMask==4){
				selectImage(VNCDUP);
				VNCDUP3=getImageID();
				
				//	run("Enhance Local Contrast (CLAHE)", "blocksize=60 histogram=256 maximum=6 mask=*None* fast_(less_accurate)");
				run("Gamma ", "gamma=1.60 in=InMacro");
				setAutoThreshold("Default dark");
				getThreshold(LowThreMax, upperM);
				setThreshold(LowThreMax, upperM2);
				run("Make Binary");
				VNCDUP=getImageID();
				
				selectImage(VNCDUP3);
				close();
				
			}else if (stepMask==5){//Moments dark
				selectImage(VNCDUP);
				setAutoThreshold("Moments dark");
				getThreshold(LowThreMax, upperM);
				setThreshold(LowThreMax, upperM2);
				run("Make Binary");
				
			}else if(stepMask==6){
				selectImage(VNCDUP);
				setAutoThreshold("MaxEntropy dark");
				getThreshold(LowThreMax, upperM);
				setThreshold(LowThreMax, upperM2);
				run("Make Binary");
				
			}else if(stepMask==7){
				inv1845=0;
				lowthreSeparation=0; ResultSeparation=0;
				
				while(ResultSeparation==0){
					
					selectImage(VNCDUP);
					run("Duplicate...", "title=DUP16_MIP");
					TestAIP=getImageID();
					
					lowthreSeparation=lowthreSeparation+20;
					setThreshold(lowthreSeparation, 65536);
					run("Make Binary");
					
					run("Analyze Particles...", "size=10000-Infinity show=Nothing display exclude clear");
					
					if(nResults==0){
						run("Invert LUT");
						run("RGB Color");
						run("8-bit");
						run("Analyze Particles...", "size=10000-Infinity show=Nothing display exclude clear");
						inv1845=1;
						//				print("inv1851");
					}//if(nResults==0){
					selectImage(TestAIP);
					close();//	run("Duplicate...", "title=DUP16_MIP");
					
					if(nResults>0){
						ResultSeparation=1;
						selectImage(VNCDUP);
						setThreshold(lowthreSeparation, 65536);
						LowThreMax=lowthreSeparation;
						run("Make Binary");
						
						if(inv1845==1){
							run("Invert LUT");
							run("RGB Color");
							run("8-bit");
						}
						
						//		setBatchMode(false);
						//				updateDisplay();
						//				"do"
						//						exit();
					}//if(nResults>0){
					
					
					if(lowthreSeparation>20000){
						ResultSeparation=1;
						print("Cannot separate Br and VNC for shape measurement");
						logsum=getInfo("log");
						filepath=savedir+"VNC_pre_aligner_log.txt";
						File.saveString(logsum, filepath);
						stepMask=8;
					}//if(lowthreSeparation>20000){
				}//while(ResultSeparation==0){
			}//if(stepMask==1){
			
			if(stepMask==8){
				selectImage(VNCDUP);
				setAutoThreshold("Huang dark");
				getThreshold(halfHuang, upperM);
				LowThreMax=halfHuang/2;
				LowThreMax=round(LowThreMax);
				setThreshold(LowThreMax, upperM2);
				run("Make Binary");
				
			}else if(stepMask==9){
				selectImage(VNCDUP);
				setAutoThreshold("RenyiEntropy dark");
				getThreshold(LowThreMax, upperM);
				setThreshold(LowThreMax, upperM2);
				run("Make Binary");
			}//if(stepMask==8){
			
			selectImage(VNCDUP);
			run("Grays");
			scan_for_invert();
			
			//setBatchMode(false);
			//updateDisplay();
			//"do"
			//exit();
			
			MIPgenerateArray=newArray(0,0,invertON);
			MIPgenerate(MIPgenerateArray);//applying min and max filters and Analyze particle
			donotOperate=MIPgenerateArray[0];
			VNCmask=getImageID();
			
			//		setBatchMode(false);
			//				updateDisplay();
			//			"do"
			//			exit();
			
			if(donotOperate==0){
				run("Make Binary");
				
				if(Angle_AR_measure==1 && LeftRight==0){// 1st run, left side only
					run("Analyze Particles...", "size=10000-Infinity show=Nothing display clear");
					updateResults();
					
					if(nResults==0){
						run("Invert LUT");
						run("RGB Color");
						run("8-bit");
						run("Analyze Particles...", "size=10000-Infinity show=Nothing display clear");
						updateResults();
					}
					
					
					
					if(nResults>0){
						for(shapen=0; shapen<nResults; shapen++){
							AreaN=getResult("Area", shapen);
							
							if(AreaN>AreaMax){//biggest area
								AreaMax=AreaN;
								ARshapeFunc=getResult("AR", shapen);
								angleFunc=getResult("Angle", shapen);
								MaxShapeNo=stepMask;
								ResultNstep=nResults;
								//			print("ARshapeFunc; "+ARshapeFunc+"  nResults; "+nResults);
							}
						}//for(shapen=0; shapen<nResults; shapen++){
					}
				}else if(Angle_AR_measure==0){// 2nd run, rotation
					setBackgroundColor(0, 0, 0);
					rotation2=270+MaxAngle;
					//			print("rotation within function  "+rotation2);
					//			setBatchMode(false);
					//			updateDisplay();
					//				"do"
					//			exit();
					
					run("Rotate... ", "angle="+rotation2+" grid=1 interpolation=None fill enlarge");
					run("Make Binary");
					
					run("Analyze Particles...", "size=10000-Infinity show=Nothing display clear");
					updateResults();
					
					if(nResults==0){
						run("Invert LUT");
						run("RGB Color");
						run("8-bit");
						run("Analyze Particles...", "size=10000-Infinity show=Nothing display clear");
						updateResults();
					}
					
					xTrue=0; yTrue=0;
					for(shapen2=0; shapen2<nResults; shapen2++){
						
						AreaN=getResult("Area", shapen2);
						
						if(AreaN>AreaMax){
							AreaMax=AreaN;
							xTrue=getResult("X", shapen2);
							yTrue=getResult("Y", shapen2);
						}
					}//for(shapen2=0; shapen2<nResults; shapen2++){
					
					if(xTrue!=0 && yTrue!=0){
						makeRectangle(xTrue-round(StackWidth/2), yTrue-round((465/1024)*StackHeight), StackWidth, StackHeight);
						run("Crop");
						getDimensions(width, height, channels, slices, frames);
						if(height<StackHeight || width<StackWidth)
						run("Canvas Size...", "width="+StackWidth+" height="+StackHeight+" position=Top-Left zero");
					}
				}//if(Angle_AR_measure==0){// 2nd run
				
				run("Grays");
				
				if(LeftRight==0){ // L leg
					Xmin1=StackHeight-20; Xmin2=StackHeight-20; Xmin3=StackHeight-20;
				}
				
				if(LeftRight==1){ // R leg
					Xmin1=StackWidth/3; Xmin2=StackWidth/3; Xmin3=StackWidth/3;
				}
				
				firstTime1=0; firstTime2=0; firstStep=1; secondStep=0; theirdStep=0; firstTime3=0;
				firstTurning=0; secondTurning=0; Xmin3_Result=10000; Ymin3_Result=0; Xmin2_Result=StackHeight-20; Ymin2_Result=0; 
				Xmin1_Result=100000; Ymin1_Result=0; Xmin1Turning=0;
				
				///		BW decision ///////////////////////
				scan_for_invert();
				
				// Shape Scan start /////////////////////////////////////////////////////
				for (Yscan=100; Yscan<StackHeight-20; Yscan++){
					
					posiPX=0; 
					if(LeftRight==1){ // R leg
						Xmin_Result=StackWidth/3;
						for(Xscan=StackWidth-10; Xscan>=StackWidth/3; Xscan--){
							
							ScanPix=getPixel(Xscan, Yscan);
							
							if(posiPX>0){
								if(ScanPix==0)
								posiPX=posiPX-1;
							}
							
							if(ScanPix==255){
								posiPX=posiPX+1;
								
								if(posiPX==3){
									Xmin_Result=Xscan;
									
									Xscan=StackWidth/3-1;
									//			List.set("PosiXL"+Yscan, Xscan);
								}//	if(posiPX==3){
							}//if(ScanPix==255){
						}//for(Xscan=510; Xscan>=260; Xscan--){
						
						if(firstStep==1){
							if(Xmin_Result>Xmin1){
								if(Xmin2==StackWidth/3){
									if(Xmin3==StackWidth/3){
										
										Xmin1_Result=Xmin_Result;//1st Right leg from top
										Ymin1_Result=Yscan;
										Xmin1=Xmin_Result;
										firstTime1=1;
									}
								}
							}
						}//if(firstStep==1){
						
						if(Xmin_Result<Xmin1-20){
							if(firstTime1==1){
								
								firstStep=0;
								firstTime1=0;
								firstTurning=1;
								Xmin1Turning=Xmin_Result;//1st bottom from top
							}
						}
						if(firstTurning==1){
							//	print("Xmin_Result; "+Xmin_Result+"  Xmin1Turning; "+Xmin1Turning);
							if(Xmin_Result<Xmin1Turning)
							Xmin1Turning=Xmin_Result;//1st bottom from top
							
							else if(Xmin_Result>Xmin1Turning+15){
								secondStep=1;
								firstTurning=0;
							}
						}//if(firstTurning==1){
						
						if(secondStep==1){
							if(Xmin_Result>Xmin2){
								if(Xmin3==StackWidth/3){
									
									Xmin2_Result=Xmin_Result;//2nd Left leg from top
									Ymin2_Result=Yscan;
									Xmin2=Xmin_Result;
									firstTime2=1;
								}
							}
						}//if(secondStep==1){
						if(Xmin_Result<Xmin2-20){
							if(firstTime2==1){
								
								firstTime2=0;
								secondStep=0;
								secondTurning=1;
								Xmin2Turning=Xmin_Result;//2nd bottom from top
							}
						}
						
						if(secondTurning==1){
							if(Xmin_Result<Xmin2Turning){
								
								Xmin2Turning=Xmin_Result;//2nd bottom from top
								
							}else if(Xmin_Result>Xmin2Turning+15){
								
								theirdStep=1;
								secondTurning=0;
							}
						}//if(secondTurning==1){
						
						if(theirdStep==1){
							if(Xmin_Result>Xmin3){
								
								Xmin3_Result=Xmin_Result;//3rd Left leg from top
								Ymin3_Result=Yscan;
								Xmin3=Xmin_Result;
								//				firstTime3=1;
							}
						}//if(theirdStep==1){
					}//if(LeftRight==1){
					
					
					
					if(LeftRight==0){ // L leg
						Xmin_Result=StackHeight-20;
						for(Xscan=0; Xscan<=StackWidth/2; Xscan++){
							
							ScanPix=getPixel(Xscan, Yscan);
							
							if(posiPX>0){
								if(ScanPix==0)
								posiPX=posiPX-1;
							}
							
							if(ScanPix==255){
								posiPX=posiPX+1;
								if(posiPX==3){
									
									Xmin_Result=Xscan;
									Xscan=301;
									//			List.set("PosiXL"+Yscan, Xscan);
								}
							}
						}//for(Xscan=0; Xscan<=200; Xscan++){	
						if(firstStep==1){
							if(Xmin_Result<Xmin1){
								if(Xmin2==StackHeight-20){
									if(Xmin3==StackHeight-20){
										
										Xmin1_Result=Xmin_Result;//1st Left leg from top
										Ymin1_Result=Yscan;
										Xmin1=Xmin_Result;
										firstTime1=1;
										
									}//	if(Xmin3==1000){
								}
							}
						}//if(firstStep==1){
						if(Xmin_Result>Xmin1+20){
							if(firstTime1==1){
								
								firstStep=0;
								firstTime1=0;
								firstTurning=1;
								Xmin1Turning=Xmin_Result;//1st bottom from top
							}
						}
						if(firstTurning==1){
							//	print("Xmin_Result; "+Xmin_Result+"  Xmin1Turning; "+Xmin1Turning);
							if(Xmin_Result>Xmin1Turning)
							Xmin1Turning=Xmin_Result;//1st bottom from top
							
							else if(Xmin_Result<Xmin1Turning-15){
								secondStep=1;
								firstTurning=0;
							}
						}//if(firstTurning==1){
						
						if(secondStep==1){
							if(Xmin_Result<Xmin2){
								if(Xmin3==StackHeight-20){
									
									Xmin2_Result=Xmin_Result;//2nd Left leg from top
									Ymin2_Result=Yscan;
									Xmin2=Xmin_Result;
									firstTime2=1;
								}
							}
						}//if(secondStep==1){
						
						if(Xmin_Result>Xmin2+20){
							if(firstTime2==1){
								
								firstTime2=0;
								secondStep=0;
								secondTurning=1;
								Xmin2Turning=Xmin_Result;//2nd bottom from top
							}
						}
						
						if(secondTurning==1){
							if(Xmin_Result>Xmin2Turning){
								
								Xmin2Turning=Xmin_Result;//2nd bottom from top
								
							}else if(Xmin_Result<Xmin2Turning-15){
								
								theirdStep=1;
								secondTurning=0;
							}
						}//if(secondTurning==1){
						
						if(theirdStep==1){
							if(Xmin_Result<Xmin3){
								
								Xmin3_Result=Xmin_Result;//3rd Left leg from top
								Ymin3_Result=Yscan;
								Xmin3=Xmin_Result;
								//				firstTime3=1;
							}
						}
					} //if(LeftRight==0){
				}////		for (Yscan=0; Yscan<1000; Yscan++){
				
				if(LeftRight==0)
				print("   "+stepMask+"   LlegOne; "+Xmin1_Result+", "+Ymin1_Result+"  LlegTwo; "+Xmin2_Result+", "+Ymin2_Result+"  LlegThree; "+Xmin3_Result+", "+Ymin3_Result);
				
				if(LeftRight==1)
				print("   "+stepMask+"   RlegOne; "+Xmin1_Result+", "+Ymin1_Result+"  RlegTwo; "+Xmin2_Result+", "+Ymin2_Result+"  RlegThree; "+Xmin3_Result+", "+Ymin3_Result);
				
				logsum=getInfo("log");
				filepath=savedir+"VNC_pre_aligner_log.txt";
				File.saveString(logsum, filepath);
				
				aveX=(Xmin1_Result+Xmin2_Result+Xmin3_Result)/3;
				Xsd=sqrt(((aveX-Xmin1_Result)*(aveX-Xmin1_Result)+(aveX-Xmin2_Result)*(aveX-Xmin2_Result)+(aveX-Xmin3_Result)*(aveX-Xmin3_Result))/3);
				
				YminGap1=Ymin2_Result-Ymin1_Result;
				YminGap2=Ymin3_Result-Ymin2_Result;
				
				aveY=(YminGap1+YminGap2)/2;
				Ysd=sqrt(((aveY-YminGap1)*(aveY-YminGap1)+(aveY-YminGap2)*(aveY-YminGap2))/2);
				
				if(Xmin1_Result==0 && Xmin2_Result==0 && Xmin3_Result==0)
				Xsd=100;
				
				if(aveY==0)
				Ysd=100;
				
				TotalsdV=Xsd*3.3+Ysd;
				
				//	print("TotalsdV; "+TotalsdV+"   ThreStep; "+stepMask);
				
				if(TotalsdV<maxTotalSd){
					maxTotalSd=TotalsdV;
					Xminsd=Xsd; Yminsd=Ysd;
					lowthreMIP=LowThreMax;
					BestThreM=stepMask;
					
				}//if(TotalsdV<maxTotalSd){
				
				if(ResultNstep==1){
					if(TotalsdV<maxTotalSd2){
						maxTotalSd2=TotalsdV;
						if(Angle_AR_measure==1 && LeftRight==0){// 1st run, left side 
							
							MaxARshape=ARshapeFunc;
							MaxAngle=angleFunc;
							
							print("MaxARshape; "+MaxARshape);
							
							logsum=getInfo("log");
							filepath=savedir+"VNC_pre_aligner_log.txt";
							File.saveString(logsum, filepath);
						}
					}
				}//if(ResultNstep==1){
			}//if(donotOperate==0){ 230
			
			selectImage(VNCmask);
			close();
			
			selectImage(VNCDUP);
			close();
			
			
		}//for(stepMask=1; stepMask<=6; stepMask++){
		
		
		
		if(LeftRight==0){
			
			print("Thresholding Method for shape Left;  "+BestThreM+"   L_Xsd; "+Xminsd+"  L_Ysd; "+Yminsd+"  ThreVal; "+lowthreMIP+"  MaxARshape; "+MaxARshape);
			LXminsd=Xminsd;
			LYminsd=Yminsd;
			
			logsum=getInfo("log");
			File.saveString(logsum, filepath);
			
		}else if(LeftRight==1){
			
			print("Thresholding Method for shape Right.  "+BestThreM+"   R_Xsd; "+Xminsd+"  R_Ysd; "+Yminsd+"  ThreVal; "+lowthreMIP);
			RXminsd=Xminsd;
			RYminsd=Yminsd;
			
			logsum=getInfo("log");
			File.saveString(logsum, filepath);
		}
		
	}//for(LeftRight=0; LeftRight<2; LeftRight++){// for left right 
	
	if(MaxARshape<1.75){// 
		if(FirstAR==0){
			print("The VNC is short! "+MaxARshape);
			
			logsum=getInfo("log");
			filepath=savedir+"VNC_pre_aligner_log.txt";
			File.saveString(logsum, filepath);
			
			ShapeProblem=1;
		}
	}
	if(MaxARshape>=1.75){// 2nd run, can fix AR short.
		ShapeProblem=0;
		FirstAR=1;
	}
	
	//	if(Angle_AR_measure==1)
	//	print("   MaxAngle; "+MaxAngle);
	
	SmeasurementArray[2]=lowthreMIP;
	SmeasurementArray[3]=LXminsd;
	SmeasurementArray[4]=LYminsd;
	SmeasurementArray[5]=MaxARshape;
	SmeasurementArray[6]=MaxAngle;
	
	SmeasurementArray[9]=ShapeProblem;
	
	SmeasurementArray[12]=RXminsd;
	SmeasurementArray[13]=RYminsd;
	SmeasurementArray[16]=MaxShapeNo;
	SmeasurementArray[17]=FirstAR;
}

function MIPgenerate(MIPgenerateArray){
	donotOperate=0;
	secondMIP=MIPgenerateArray[1];
	invertON=MIPgenerateArray[2];
	origiBinary=getImageID();
	
	run("Remove Outliers...", "radius=2 threshold=50 which=Bright");
	
	run("Minimum...", "radius=2");
	run("Remove Outliers...", "radius=2 threshold=50 which=Bright");
	run("Maximum...", "radius=2");
	run("Remove Outliers...", "radius=2 threshold=50 which=Dark");
	
	if (secondMIP==0)
	run("Analyze Particles...", "size=10000.00-Infinity show=Masks display exclude clear");// Creating Mask only VNC
	else
	run("Analyze Particles...", "size=10000.00-Infinity show=Masks display clear");// Creating Mask only VNC
	
	if(nResults==0){
		close();
		selectImage(origiBinary);
		run("Invert LUT");
		run("RGB Color");
		run("8-bit");
		if (secondMIP==0)
		run("Analyze Particles...", "size=10000.00-Infinity show=Masks display exclude clear");// Creating Mask only VNC
		else
		run("Analyze Particles...", "size=10000.00-Infinity show=Masks display clear");// Creating Mask only VNC
	}
	
	run("Grays");
	//	if (secondMIP==0){
	//setBatchMode(false);
	//updateDisplay();
	//"do"
	//exit();
	//	}
	
	if(nResults>0){
		VNCmask0=getImageID();
		
		updateResults();
		DD2=1; DD3=0;
		FILL_HOLES(DD2, DD3);//need 3d stack
		
		VNCmask0=getImageID();
		
		run("Maximum...", "radius=25");
		FILL_HOLES(DD2, DD3);
		VNCmask0=getImageID();
		
		run("Minimum...", "radius=25");
		run("Minimum...", "radius=30");
		run("Maximum...", "radius=30");
		
		if (secondMIP==0){
			
			run("Analyze Particles...", "size=10000.00-Infinity show=Masks display exclude clear");// Creating Mask only VNC
			if(nResults==0){
				close();
				selectImage(VNCmask0);
				run("Invert LUT");
				run("RGB Color");
				run("8-bit");
				run("Analyze Particles...", "size=10000.00-Infinity show=Masks display exclude clear");// Creating Mask only VNC
			}//if(nResults==0){
			
		}else{
			//			setBatchMode(false);
			//				updateDisplay();
			//			"do"
			//			exit();
			
			run("Analyze Particles...", "size=10000.00-Infinity show=Masks display clear");// Creating Mask only VNC
			
			if(nResults==0){
				close();
				selectImage(VNCmask0);
				run("Invert LUT");
				run("RGB Color");
				run("8-bit");
				run("Analyze Particles...", "size=10000.00-Infinity show=Masks display clear");// Creating Mask only VNC
			}//if(nResults==0){
		}//	if (secondMIP==0){
		VNCmask1=getImageID();
		
		selectImage(VNCmask0);
		close();
		
		//	if(nResults>1)
		//	print("  "+nResults+" of objects");
		
		selectImage(VNCmask1);
		run("Grays");
	}else{
		print("  0 object");
		donotOperate=1;
	}
	MIPgenerateArray[0]=donotOperate;
}

function CLEAR_MEMORY() {
	d=call("ij.IJ.maxMemory");
	e=call("ij.IJ.currentMemory");
	for (trials=0; trials<3; trials++) {
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
		run("Z Project...", "projection=[Average Intensity]");
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

function scan_for_invert (){
	posiPX=0;
	for (YscanT=0; YscanT<1000; YscanT++){
		
		
		ScanPixT=getPixel(0, YscanT);
		ScanPixT2=getPixel(510, YscanT);
		
		if(ScanPixT==255)
		posiPX=posiPX+1;
		
		if(ScanPixT2==255)
		posiPX=posiPX+1;
		
	}//for (YscanT=100; YscanT<201; YscanT++){
	
	if(posiPX>1000){
		run("Invert LUT");
		run("RGB Color");
		run("8-bit");
		run("Grays");
		//				print("inverted BW for shape analysis");
	}
}




