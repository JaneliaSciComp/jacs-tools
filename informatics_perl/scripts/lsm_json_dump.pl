#!/usr/bin/perl
#
# Dump Zeiss LSM metadata in JSON format. 
#
# Requires the following modules installed:
# Pegex::Base
# YAML
# JSYNC
# Zeiss::LSM
#

#use lib '/misc/local/perl5/lib/perl5/site_perl/5.8.5';
#use lib '/groups/jacs/jacsHosts/servers/jacs/executables/perl/lib/perl5';

use Zeiss::LSM;
use Data::Dumper;
use JSYNC;

my $file = $ARGV[0] || die "Usage: $0 <filename.lsm>";

my $lsm;
eval { $lsm = new Zeiss::LSM({stack => $file}); };

#print Dumper(\%INC);

# TMI
delete $lsm->{ascii} if exists $lsm->{ascii};
delete $lsm->{cz_private} if exists $lsm->{cz_private};
delete $lsm->{zeiss_tag} if exists $lsm->{zeiss_tag};

my $jsync = JSYNC::dump($lsm, {pretty => 1});

# Remove extra cruft needed for re-serialization
$jsync =~ s/^\s+"!".*?$//gm;
$jsync =~ s/^\s*\n+//mg;

if ($jsync !~ /{}\s*/) {
    print $jsync;
}

