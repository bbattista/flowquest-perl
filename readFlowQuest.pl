#!/usr/bin/perl

# LinkQuest FlowQuest 300 file parser
#  Bradley Matthew Battista

use flowquest;

die "Usage readFlowQuest.pl filename\n" if $#ARGV !=0;

$adcp = flowquest->new();
$adcp->openfile($ARGV[0]);


# make this larger than the number of bins for any given ensemble
$trclen = 70;

while ($adcp->{status}<2) {
  $adcp->get_header();
  $adcp->e0();
  $adcp->e1();
  $adcp->e2();
  $adcp->e3();
  $adcp->e4();
  $adcp->e5();
  $adcp->e6();
  $adcp->e7();

  # uncomment if creating Seismic Unix output files (*.su)
  # $adcp->cwp($trclen); # input number of expected bins

  # uncomment for writing to MySQL
  $adcp->save();
}

# uncomment if creating Seismic Unix output files (*.su)
# $adcp->cwp_headers($trclen); # write trace headers into seismic unix file
