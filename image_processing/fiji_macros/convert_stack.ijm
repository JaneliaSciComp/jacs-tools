/*
 * Convert a file to a support output format, optionally splitting each channel into a separate file. 
 */
var args = split(getArgument(),",");
var inputFile = args[0];
var outputFile = args[1];
var splitChannels = args[2];

if (indexOf(inputFile, "/")<0 || indexOf(outputFile, "/")<0) {
    print("Paths must be fully qualified");
    run("Quit");
}

inputFilename = File.getName(inputFile);
inputBasename = substring(inputFilename, 0, indexOf(inputFilename, "."));
print("inputFile: "+inputFile);
//print("inputFilename: "+inputFilename);
//print("inputBasename: "+inputBasename);

outputFilename = File.getName(outputFile);
outputBasename = substring(outputFilename, 0, indexOf(outputFilename, "."));
outDir = substring(outputFile, 0, lastIndexOf(outputFile, "/"));
format = substring(outputFilename, indexOf(outputFilename, ".")+1);
print("outputFile: "+outputFile);
//print("outputFilename: "+outputFilename);
//print("outputDir: "+outDir);
//print("outputFormat: "+format);
print("splitChannels: "+splitChannels);

open(inputFile);
title = getTitle();
getDimensions(width, height, channels, slices, frames);

if (splitChannels=="1") {
    if (channels>1) {
        run("Split Channels");
    }
    titles = getList("image.titles");
    for(c=0; c<titles.length; c++) {
        selectWindow(titles[c]);
        run("Grays");
        saveCurrentWindow(format, outDir+"/"+outputBasename+"_c"+c+"."+format);  
    }
}
else {
    saveCurrentWindow(format, outDir+"/"+outputBasename+"."+format);
}

print("Done");
run("Close All");
run("Quit");

function saveCurrentWindow(format, outfile) {
    print("Saving "+outfile);
    if (format=='nrrd') {
        run("Nrrd Writer", "compressed nrrd="+outfile);
    }
    else if (format=='v3draw') {
        run("V3Draw...", "save=[" + outfile +"]");
    }
    else if (format=='tif' || format=='tiff') {
        saveAs("Tiff", outfile);
    }
    else if (format=='zip') {
        saveAs("ZIP", outfile);
    }
    else {
        print("Unsupported output format: "+format);
        run("Quit");
    }
    close();
}
