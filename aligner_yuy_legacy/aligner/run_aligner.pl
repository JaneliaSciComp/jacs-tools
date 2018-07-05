#!/usr/local/bin/perl

use Getopt::Std;
use strict;

our ($opt_v, $opt_b, $opt_l, $opt_t, $opt_w, $opt_i, $opt_r, $opt_c);

getopts("v:b:l:t:w:i:r:c:") || &usage("");

my $v3d         = $opt_v;
my $ba          = $opt_b;
my $lobeseg     = $opt_l;
my $templateDir = $opt_t;
my $workingDir  = $opt_w;
my $inputStack  = $opt_i;
my $opticalRes  = $opt_r;
my $refChannel  = $opt_c;

my ($opticalResX, $opticalResY, $opticalResZ) = ("0.3800","0.3800","0.3800");
if ($opticalRes) {
    ($opticalResX, $opticalResY, $opticalResZ) = split /x/,$opticalRes;
}

if (! -e $v3d) {
    &usage("Could not locate v3d progam at location $v3d");;
}

if (! -e $ba) {
    &usage("Could not locate brain_aligner program at location $ba");
}

if (! -e $lobeseg) {
    &usage("Could not locate lobeseg program at location $lobeseg");
}

if (! -d $templateDir) {
    &usage("Could not locate template directory at location $templateDir");
}

if (! -d $workingDir) {
    `mkdir $workingDir`;
    sleep(2);
    if (! -d $workingDir) {
	&usage("Could not find nor create working directory $workingDir");
    }
}

if (! -e $inputStack) {
    &usage("Could not locate input stack $inputStack");
}

&runInitialGlobalAlignment($inputStack);
&runLobeseg($inputStack);
&centralGlobalAlignment($inputStack);
&centralLocalAlignment($inputStack);
&centralLocalAlignment2($inputStack);
&addTemplateBoundary($inputStack);
&generateOutputFiles($inputStack);
#&addMips($inputStack);
&cleanup($inputStack);

exit;

#######################################################################################################

sub usage {
    print STDERR $_[0] . "\n";
    die "Usage: -v <v3d exe path> -b <brain_aligner path> -l <lobeseg path> -t <template dir> -w <working dir> -i <input stack> -r <opticalRes>\n";
}

sub getBaseNameFromFile {
    my $file=$_[0];
    my @arr=split /\//, $file;
    my $baseName=$arr[@arr-1];
    my @arr2=split /\./, $baseName;
    my $baseName2=$arr2[0];
    return $baseName2;
}

sub runInitialGlobalAlignment {
    print "Start runInitialGlobalAlignment\n";
    my $inputFile=$_[0];
    print "inputFile=$inputFile\n";
    my $baseName=&getBaseNameFromFile($inputFile);
    print "baseName=$baseName\n";
    my $outputFileBase="$workingDir\/$baseName";
    print "outputFileBase=$outputFileBase\n";
    my $logFile="$workingDir\/initialGlobalAlignment.log";

    my $cmd = "$ba " .
              " -s \"$inputFile\" " .
              " -c \"$refChannel\" " .
              " -t \"$templateDir\/GMR_36G04_AE_01_05-hanchuan_rot180_recentered_3chan.tif\" " .
              " -L \"$templateDir\/GMR_36G04_AE_01_05-hanchuan_rot180_recentered_3chan.marker\" " .
              " -C \"0\" " .
              " -o \"$outputFileBase\_\_FL-F-NT\_\_GWF\.v3draw\.tmp\_GF\.v3draw\" " .
              " -w 0 " .
              " -X 1.0000 " .
              " -Z 1.0000 " .
              " -x $opticalResX " .
              " -z $opticalResZ " .
              " -B 1024 " .
              " -e  1.00 " .
              " -R ";

    print "cmd=$cmd\n";
    system( "$cmd 1>$logFile 2>&1" );
}

sub runLobeseg {
    print "Start runLobeseg\n";
    my $inputFile=$_[0];
    print "inputFile=$inputFile\n";
    my $baseName=&getBaseNameFromFile($inputFile);
    print "baseName=$baseName\n";
    my $outputFileBase="$workingDir\/$baseName";
    print "outputFileBase=$outputFileBase\n";
    my $logFile="$workingDir\/lobeseg.log";

    my $cmd = "$lobeseg " .
	" -i \"$outputFileBase\_\_FL-F-NT\_\_GWF\.v3draw\.tmp\_GF\.v3draw\" " .
	" -c $refChannel " .
    " -o \"$outputFileBase\_\_FL-F-NT\_\_GWF\.v3draw\.tmp\.lobeseg\.v3draw\" ";

    print "cmd=$cmd\n";
    system( "$cmd 1>$logFile 2>&1" );
}

sub centralGlobalAlignment {
    print "Start centralGlobalAlignment\n";
    my $inputFile=$_[0];
    print "inputFile=$inputFile\n";
    my $baseName=&getBaseNameFromFile($inputFile);
    print "baseName=$baseName\n";
    my $outputFileBase="$workingDir\/$baseName";
    print "outputFileBase=$outputFileBase\n";
     my $logFile="$workingDir\/centralGlobalAlignment.log";

    my $cmd = "$ba " .
              " -s \"$outputFileBase\_\_FL-F-NT\_\_GWF\.v3draw\.tmp\.lobeseg\.v3draw\" " .
              " -c \"$refChannel\" " .
              " -t \"$templateDir\/GMR_36G04_AE_01_05-hanchuan_rot180_recentered_3chan_lobeseg.tif\" " .
              " -L \"$templateDir\/GMR_36G04_AE_01_05-hanchuan_rot180_recentered_3chan.marker\" " .
              " -C \"0\" " .
              " -o \"$outputFileBase\_\_FL-F-NT\_\_GWF\.v3draw\.tmp\_GF\_local\.v3draw\" " .
              " -w 0 " .
              " -X 1.0000 " .
              " -Z 1.0000 " .
              " -x $opticalResX " .
              " -z $opticalResZ " .
              " -B 1024 " .
              " -e  1.00 ";

    print "cmd=$cmd\n";
    system( "$cmd 1>$logFile 2>&1" );
}

sub centralLocalAlignment {
    print "Start centralLocalAlignment\n";
    my $inputFile=$_[0];
    print "inputFile=$inputFile\n";
    my $baseName=&getBaseNameFromFile($inputFile);
    print "baseName=$baseName\n";
    my $outputFileBase="$workingDir\/$baseName";
    print "outputFileBase=$outputFileBase\n";
    my $logFile="$workingDir\/centralLocalAlignment.log";

    my $cmd = "$ba " .
              " -s \"$outputFileBase\_\_FL-F-NT\_\_GWF\.v3draw\.tmp\_GF\_local\.v3draw\" " .
              " -c \"$refChannel\" " .
              " -t \"$templateDir\/GMR_36G04_AE_01_05-hanchuan_rot180_recentered_3chan_lobeseg.tif\" " .
              " -L \"$templateDir\/GMR_36G04_AE_01_05-hanchuan_rot180_recentered_3chan.marker\" " .
              " -C \"0\" " .
              " -o \"$outputFileBase\_\_FL-F-NT\_\_GWF\_loop1\.v3draw\" " .
              " -w 10 " .
              " -X 1.0000 " .
              " -Z 1.0000 " .
              " -x 1.0000 " .
              " -z 1.0000 " .
              " -B 1024 " .
              " -e  1.00 " .
              " -j 1 " .
              " -J \"$outputFileBase\_\_FL-F-NT\_\_GWF\_loop1\.v3draw\.vc\.v3draw\" " .
              " -H 2 ";

    print "cmd=$cmd\n";
    system( "$cmd 1>$logFile 2>&1" );
}

sub centralLocalAlignment2 {
    print "Start centralLocalAlignment2\n";
    my $inputFile=$_[0];
    print "inputFile=$inputFile\n";
    my $baseName=&getBaseNameFromFile($inputFile);
    print "baseName=$baseName\n";
    my $outputFileBase="$workingDir\/$baseName";
    print "outputFileBase=$outputFileBase\n";
    my $logFile="$workingDir\/centralLocalAlignment2.log";

    my $cmd = "$ba " .
              " -s \"$outputFileBase\_\_FL-F-NT\_\_GWF\_loop1\.v3draw\" " .
              " -c \"$refChannel\" " .
              " -t \"$templateDir\/GMR_36G04_AE_01_05-hanchuan_rot180_recentered_3chan_lobeseg.tif\" " .
              " -L \"$templateDir\/GMR_36G04_AE_01_05-hanchuan_rot180_recentered_3chan.marker\" " .
              " -C \"0\" " .
              " -o \"$outputFileBase\_\_FL-F-NT\_\_GWF\_loop2\.v3draw\" " .
              " -w 10 " .
              " -X 1.0000 " .
              " -Z 1.0000 " .
              " -x 1.0000 " .
              " -z 1.0000 " .
              " -B 1024 " .
              " -e  1.00 " .
              " -j 1 " .
              " -J \"$outputFileBase\_\_FL-F-NT\_\_GWF\_loop3\.v3draw\.vc\.v3draw\" " .
              " -H 2 ";

    print "cmd=$cmd\n";
    system( "$cmd 1>$logFile 2>&1" );
}

sub addTemplateBoundary {
    print "Start addTemplateBoundary\n";
    my $inputFile=$_[0];
    print "inputFile=$inputFile\n";
    my $baseName=&getBaseNameFromFile($inputFile);
    print "baseName=$baseName\n";
    my $outputFileBase="$workingDir\/$baseName";
    print "outputFileBase=$outputFileBase\n";
    my $logFile="$workingDir\/addTemplateBoundary.log";

    my $cmd = "$ba " .
              " -T " .
              " -s \"$outputFileBase\_\_FL-F-NT\_\_GWF\_loop2\.v3draw\" " .
              " -t \"$templateDir\/GMR_36G04_AE_01_05-hanchuan_rot180_recentered_3chan_mask_edgesinglecolor_center_16bit.raw\" " .
              " -o \"$outputFileBase\_\_FL-F-NT\_\_GWF\_loop2\_edge\.v3draw\" " .
	      " -A 0 " .
	      " -a $refChannel ";

    print "cmd=$cmd\n";
    system( "$cmd 1>$logFile 2>&1" );
}

sub generateOutputFiles {
    print "Start generateOutputFiles\n";
    my $inputFile=$_[0];
    print "inputFile=$inputFile\n";
    my $baseName=&getBaseNameFromFile($inputFile);
    print "baseName=$baseName\n";
    my $outputFileBase="$workingDir\/$baseName";
    print "outputFileBase=$outputFileBase\n";
    my $logFile="$workingDir\/generateOutputFiles.log";

    my $resultFile = "$outputFileBase\_\_FL-F-NT\_\_GWF\_loop2\.v3draw";
    if (! -e $resultFile) {
	die "Could not find result file $resultFile\n";
    }

    #my $cmd = "$v3d -cmd image-loader -convert $resultFile $workingDir\/Aligned\.v3dpbd";
    my $cmd = "mv $resultFile $workingDir\/Aligned\.v3draw";
    #$cmd = "$v3d -cmd image-loader -mapchannels $resultFile $workingDir\/Aligned\.v3draw \"3,0,0,1,1,2,2,3\"";
    print "cmd=$cmd\n";
    system( "$cmd 1>$logFile 2>&1" );

    #$cmd = "$v3d -cmd image-loader -convert8 $workingDir\/Aligned16\.v3draw $workingDir\/Aligned8\.v3draw";
    #print "cmd=$cmd\n";
    #system( "$cmd 1>>$logFile 2>&1" );

    #$cmd = "$v3d -cmd image-loader -mapchannels $resultFile $workingDir\/AlignedSignal\.v3dpbd \"0,0,1,1,2,2\"";
    #print "cmd=$cmd\n";
    #system( "$cmd 1>>$logFile 2>&1" );

    #$cmd = "$v3d -cmd image-loader -mapchannels $resultFile $workingDir\/AlignedReference\.v3dpbd \"3,0\"";
    #print "cmd=$cmd\n";
    #system( "$cmd 1>>$logFile 2>&1" );

    #$cmd = "$v3d -cmd image-loader -mapchannels $templateDir\/GMR_36G04_AE_01_05-hanchuan_rot180_recentered_3chan_mask_edgesinglecolor_center_16bit.raw $workingDir\/AlignedCompartments\.v3dpbd \"0,0\"";
    #print "cmd=$cmd\n";
    #system( "$cmd 1>>$logFile 2>&1" );
}

sub addMips {
    print "Start addMips\n";
    my $inputFile=$_[0];
    print "inputFile=$inputFile\n";
    my $baseName=&getBaseNameFromFile($inputFile);
    print "baseName=$baseName\n";
    my $outputFileBase="$workingDir\/$baseName";
    print "outputFileBase=$outputFileBase\n";
    my $logFile="$workingDir\/addMips.log";

    my $cmd = "$v3d -cmd image-loader -mip $workingDir\/AlignedSignal\.v3dpbd $workingDir\/AlignedSignalMIP\.tif";
    print "cmd=$cmd\n";
    system( "$cmd 1>$logFile 2>&1" );

    $cmd = "$v3d -cmd image-loader -mip $workingDir\/AlignedReference\.v3dpbd $workingDir\/AlignedReferenceMIP\.tif";
    print "cmd=$cmd\n";
    system( "$cmd 1>>$logFile 2>&1" );
}

sub cleanup {
    print "Start cleanup\n";
    my $inputFile=$_[0];
    print "inputFile=$inputFile\n";
    my $baseName=&getBaseNameFromFile($inputFile);
    print "baseName=$baseName\n";
    my $outputFileBase="$workingDir\/$baseName";
    print "outputFileBase=$outputFileBase\n";
    my $logFile="$workingDir\/cleanup.log";

    my $cmd = "rm $outputFileBase" . "*\.v3draw";
    print "cmd=$cmd\n";
    system( "$cmd 1>$logFile 2>&1" );
}


__END__

