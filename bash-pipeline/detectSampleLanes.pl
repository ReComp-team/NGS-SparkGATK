#!/usr/bin/perl
use strict;
use warnings;

my ($sample_path, $sample_id)  = @ARGV;
$sample_path =~ s/\/$//;
#my $folder=$sample_path."/".$sample_id;
my $folder=$sample_path;
my $lanes="";
opendir (DIR, $folder) or die "Can't find the directory $folder";
while (my $file = readdir(DIR)) {
	next if ($file =~ m/^\./);
#	if($file =~ m/$sample_id\_(\d+)\_1\_sequence\.txt$/) {
#	if($file =~ m/$sample_id\_(\d+)\_sequence\.txt$/) {
#		$lanes=$1." ".$lanes;
#	}
	if ($file =~ m/$sample_id\_L(\d+)\_R1_001.fastq/) {
          $lanes = $1." ".$lanes;
        }
}
close DIR;
chomp $lanes;
if (length($lanes) == 0) {
  die "No lanes detected";
}
print $lanes."\n";
exit;

