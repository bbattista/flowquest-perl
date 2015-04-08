#!/usr/bin/perl

# LinkQuest FlowQuest 300 file parser
#  Bradley Matthew Battista

use flowquest;
use Data::Dumper;

die "Usage readFlowQuest.pl filename\n" if $#ARGV !=0;

$adcp = flowquest->new();
$adcp->openfile($ARGV[0]);
$trclen = 70;

while ($adcp->{status}<2) {
  #$msg = sprintf('%s, %0.2f, %0.2f, %0.2f', $adcp->{datetime}, $adcp->{mean_pitch}, $adcp->{mean_roll}, $adcp->{mean_hdg});
  #print $msg . "\n";
  #print "Ensemble: " . $adcp->{ensemble} . "\n";
  #print Dumper($adcp->{ch0_strength});

  $adcp->get_header();
  $adcp->e0();
  $adcp->e1();
  $adcp->e2();
  $adcp->e3();
  $adcp->e4();
  $adcp->e5();
  $adcp->e6();
  $adcp->e7();
  $adcp->cwp($trclen); # input number of expected bins
  $adcp->save();
}

$adcp->cwp_headers($trclen); # write trace headers into seismic unix file
