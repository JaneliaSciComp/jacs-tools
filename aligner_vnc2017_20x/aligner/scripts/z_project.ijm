arg = split(getArgument());
name = arg[0];
if (name=="") exit ("No image argument!");
setBatchMode(true);

// Open stack
open(name);
Stack.getDimensions(width, height, channels, slices, frames);

// Color assignment
color = newArray();
chanstring = 'RGB';
if (arg.length > 1) {
  chanstring = arg[1];
}
for (i=0; i<lengthOf(chanstring); i++) {
  cc = substring(chanstring,i,i+1);
  if (cc == 'B') {
    color = Array.concat(color,"Blue");
  }
  else if (cc == 'C') {
    color = Array.concat(color,"Cyan");
  }
  else if (cc == 'G') {
    color = Array.concat(color,"Green");
  }
  else if (cc == 'M') {
    color = Array.concat(color,"Magenta");
  }
  else if (cc == 'R') {
    color = Array.concat(color,"Red");
  }
  else if (cc == 'Y') {
    color = Array.concat(color,"Yellow");
  }
  else if (cc == '1') {
    color = Array.concat(color,"Fire");
  }
  else if (cc == '2') {
    color = Array.concat(color,"Grays");
  }
  else if (cc == '3') {
    color = Array.concat(color,"Red/Green");
  }
}
for (i=1; i<=channels; i++) {
  Stack.setChannel(i);
  run(color[i-1]);
}

// Z projection
run("Z Project...", "start=1 stop="+slices+" projection=[Max Intensity]");

// Contrast enhancement
for (i=1; i<=channels; i++) {
  Stack.setChannel(i);
  run("Enhance Contrast", "saturated=0.1");
}

// Composite assembly
run("Make Composite");
run("Stack to RGB");

// Add text to image (optional)
if (arg.length > 2) {
  filestring=File.openAsString(arg[2]);
  setColor(0,255,255);
  setFont("Serif", 14, "antiliased");
  setJustification("left");
  drawString(filestring,5,getHeight()-32);
}

// Write file
zproj = replace(name, ".v3draw", ".png");
saveAs("PNG",zproj);

// We're done!
close();
run("Quit");
