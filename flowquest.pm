#!/usr/bin/perl

# LinkQuest FlowQuest 300 file parser, saves to MySQL DB
#  Bradley Matthew Battista

package flowquest;
use DBI;
use constant PI => 4 * atan2(1, 1);

# MySQL CONFIG VARIABLES
       $dsn = 'DBI:mysql:mc118:devops.energeosol.com';
      $user = 'root';
        $pw = 'etracadmin42';
 $tablename = 'adcp';

# PERL MYSQL CONNECT
$mysql = DBI->connect($dsn, $user, $pw);

$|=1; #autoflush buffers

##############################################################################################
#                                         CONSTRUCTOR                                        #
##############################################################################################

sub new {
  my $class = shift;
  my $data = {
            fname => 'tmp.dat',             # input file name
               fh => 0,                     # input file handle
            fsize => 0,                     # input file size
             floc => 0,                     # input file position of cursor while reading
           status => 0,                     # reserved
         ensemble => 0,                     # ensemble ID
         datetime => '0000-00-00 00:00:00', # timestamp of ensemble
              lon => 0,                     # longitude of instrument
              lat => 0,                     # latitude of instrument
             temp => 0,                     # temperature (Celcius)
             volt => 0,                     # voltage (V)
        num_pings => 0,                     # number of pings per ensemble
          bgnoise => [],                    # background noise level (dB)
        trans_dir => 'up',                  # direction instrument is facing
      trans_depth => 0,                     # depth of instrument
       blank_dist => 0,                     # nearsighted "blindness" of instrument (meters)
        mean_roll => 0,                     # average roll of instrument for a given ensemble (degrees)
         std_roll => 0,                     # standard deviation roll of instrument for a given ensemble (degrees)
       mean_pitch => 0,                     # average pitch of instrument for a given ensemble (degrees)
        std_pitch => 0,                     # standard deviation pitch of instrument for a given ensemble (degrees)
         mean_hdg => 0,                     # average heading of instrument for a given ensemble (degrees)
          std_hdg => 0,                     # standard deviation heading of instrument for a given ensemble (degrees)
         ping_num => [],                    # ping number for the ensemble
             roll => [],                    # roll at ping number (degrees)
            pitch => [],                    # pitch at ping number (degrees)
              hdg => [],                    # heading at ping number (degrees)
          bin_len => 0,                     # length of each bin (meters)
          bin_num => [],                    # bin number for sample
         ch0_vrad => [],                    # radial velocity at bin for channel 0 (mm/sec)
         ch1_vrad => [],                    # radial velocity at bin for channel 1 (mm/sec)
         ch2_vrad => [],                    # radial velocity at bin for channel 2 (mm/sec)
         ch3_vrad => [],                    # radial velocity at bin for channel 3 (mm/sec)
              VIx => [],                    # instrument velocity at bin for x-dir (mm/sec)
              VIy => [],                    # instrument velocity at bin for y-dir (mm/sec)
              VIz => [],                    # instrument velocity at bin for z-dir (mm/sec)
              VEx => [],                    # earth velocity at bin for x-dir (mm/sec)
              VEy => [],                    # earth velocity at bin for y-dir (mm/sec)
              VEz => [],                    # earth velocity at bin for z-dir (mm/sec)
     ping_percent => [],                    # number of valid pings for this bin
     ch0_strength => [],                    # signal strength at this bin for channel 0 (dB)
     ch1_strength => [],                    # signal strength at this bin for channel 1 (dB)
     ch2_strength => [],                    # signal strength at this bin for channel 2 (dB)
     ch3_strength => [],                    # signal strength at this bin for channel 3 (dB)
          ch0_snr => [],                    # signal to noise ratio at this bin for channel 0 (dB)
          ch1_snr => [],                    # signal to noise ratio at this bin for channel 1 (dB)
          ch2_snr => [],                    # signal to noise ratio at this bin for channel 2 (dB)
          ch3_snr => [],                    # signal to noise ratio at this bin for channel 3 (dB)
         pressure => [],                    # pressure (not used for this instrument)
  };

  bless $data, $class;
  return $data;
}

##############################################################################################
#                                           METHODS                                          #
##############################################################################################

sub openfile {
  my ($obj,$file) = @_;
  ($obj->{fname},$ext) = split /\./, $file;
  $obj->{fsize} = -s "$file";
  sysopen($obj->{fh},$file,O_RDONLY) or die "Can't Open $file: $!";
}

sub find {
  my ($obj,$string) = @_;

  # setup search conditions
  my $strlen = length($string);
  my $msg_tag = "a$strlen";
  my ($data,$msg,$found,$where);

  # scan file for next occurrence

  while ($found==0) { 
    sysread($obj->{fh},$data,$strlen);
    $msg = unpack($msg_tag, $data);
    if ($msg eq $string) {
      #print "Found $string at " . $obj->{floc} . "\n";
      $obj->{floc} = sysseek($obj->{fh},-$strlen,1);
      $found=1;
      $obj->{status}=$found;
    } else {
      $obj->{floc} = sysseek($obj->{fh},-($strlen-1),1);
      if ($obj->{fsize} - $obj->{floc} <= $strlen) {
        $found=2;
        $obj->{status}=$found;
      }
    }
  }
}

sub get_header{
  my ($obj,$string) = @_;
  $obj->find('$#FQ');
  next unless $obj->{status}==1;

  # Read Message Header
  $msg_tag = "a8 S1 L1 s29";
  sysread($obj->{fh},$data,72);
  $obj->{floc} = sysseek($obj->{fh},0,1);
  ($ens_hdr,
   $ens_num, 
   $time,
   $temperature,
   $voltage,
   $num_ping,
   $compass_cal_flag,
   $ens_output_switch,
   $offset1,$offset2,$offset3,$offset4,$offset5,$offset6,$offset7,$offset8,
   $bin_len,
   $bgnoise0,$bgnoise1,$bgnoise2,$bgnoise3,
   $transducer_dir,
   $reserved,
   $operation_mode,
   $reserved,
   $transducer_depth,
   $blank_dist_cm,
   $error_code,
   $reserved,
   $rph_abnormal,
   $flag_forward,
   $flag_24_48,
   $reserved,
   $data_len) = unpack($msg_tag, $data);

   ($sec, $min, $hour, $day, $month, $year) = gmtime($time);
   $month+=1;
   $year+=1900;
   $timestamp = sprintf('%04d-%02d-%02d %02d:%02d:%02d', $year, $month, $day, $hour, $min,$sec);
   
  $temp = $temperature*0.1;
  $volt = $voltage*0.1;
  $compass = $compass_cal_flag==1 ? 'factory' : 'custom';
  $blank = $blank_dist_cm*.01;
  $bin = $bin_len*0.01;
  $transdir = $transducer_dir==1 ? 'down' : 'up';
  $serial = $flag_forward ? 'serial' : 'disabled';
  $power = $flag_24_48 ? 48 : 24;

     $obj->{ensemble} = $ens_num;
     $obj->{datetime} = $timestamp;
         $obj->{temp} = $temp;
         $obj->{volt} = $volt;
    $obj->{num_pings} = $num_ping;
      $obj->{bgnoise} = [map {$_ * .25} ($bgnoise0,$bgnoise1,$bgnoise2,$bgnoise3)];
    $obj->{trans_dir} = $transdir;
  $obj->{trans_depth} = $transducer_depth;
   $obj->{blank_dist} = $blank;
      $obj->{bin_len} = $bin;
}

sub e0 {
  my ($obj,$string) = @_;
  $obj->find('E0');
  next unless $obj->{status}==1;

  # Read Message Header
  $msg_tag = "a2 s1";

  sysread($obj->{fh},$data,4);
  ($hdr, $length) = unpack($msg_tag,$data);

  $msg_tag = "s$length";
  sysread($obj->{fh},$data,$length*2);

  ($mean_roll, 
   $std_roll, 
   $mean_pitch, 
   $std_pitch, 
   $mean_hdg, 
   $std_hdg) = unpack($msg_tag, $data);

   $mean_roll*=0.01;
   $mean_pitch*= 0.01;
   $mean_hdg*=0.1;

   $std_roll*=0.01;
   $std_pitch*=0.01;
   $std_hdg*=0.01;

    $obj->{mean_roll} = $mean_roll;
     $obj->{std_roll} = $std_roll;
   $obj->{mean_pitch} = $mean_pitch;
    $obj->{std_pitch} = $std_pitch;
     $obj->{mean_hdg} = $mean_hdg;
      $obj->{std_hdg} = $std_hdg;
}

sub e1 {
  my ($obj,$string) = @_;
  $obj->find('E1');
  next unless $obj->{status}==1;

  # Read Message Header
  $msg_tag = "a2 s1";
  sysread($obj->{fh},$data,4);
  ($hdr, $length) = unpack($msg_tag,$data);
  $length/=3;

  for ($i=0;$i<$length;$i++) {
    $msg_tag = "s3";
    sysread($obj->{fh},$data,6);
    ($roll, 
     $pitch, 
     $hdg) = unpack($msg_tag, $data);

     $roll*=0.01;
     $pitch*= 0.01;
     $hdg*=0.1;

    $pnum = $i+1;
    push($obj->{ping_num},$i+1);
    push($obj->{roll},$roll);
    push($obj->{pitch},$pitch);
    push($obj->{hdg},$hdg);
  }
}

sub e2 {
  my ($obj,$string) = @_;
  $obj->{ch0_vrad} = [];
  $obj->{ch1_vrad} = [];
  $obj->{ch2_vrad} = [];
  $obj->{ch3_vrad} = [];

  $obj->find('E2');
  next unless $obj->{status}==1;

  # Read Message Header
  $msg_tag = "a2 s1";
  sysread($obj->{fh},$data,4);
  ($hdr, $length) = unpack($msg_tag,$data);
  $num_bins = $length/4;
  $num_chn = 4;

  for ($chn=0;$chn<$num_chn;$chn++) {
    for ($j=0;$j<$num_bins;$j++) {
      $msg_tag = "s1";
      sysread($obj->{fh},$data,2);
      ($vrad) = unpack($msg_tag, $data);

      $obj->{bin_num}[$j] = $j;
      push($obj->{ch0_vrad},$vrad) if $chn==0;
      push($obj->{ch1_vrad},$vrad) if $chn==1;
      push($obj->{ch2_vrad},$vrad) if $chn==2;
      push($obj->{ch3_vrad},$vrad) if $chn==3;
    }
  }
}

sub e3 {
  my ($obj,$string) = @_;
  $obj->{VIx} = [];
  $obj->{VIy} = [];
  $obj->{VIz} = [];

  $obj->find('E3');
  next unless $obj->{status}==1;

  # Read Message Header
  $msg_tag = "a2 s1";
  sysread($obj->{fh},$data,4);
  ($hdr, $length) = unpack($msg_tag,$data);
  $num_bins = $length/3;

  for ($i=0;$i<$num_bins;$i++) {
    $msg_tag = "s3";
    sysread($obj->{fh},$data,6);
    ($VIx, 
     $VIy, 
     $VIz) = unpack($msg_tag, $data);

    push($obj->{VIx},$VIx);
    push($obj->{VIy},$VIy);
    push($obj->{VIz},$VIz);
  }
}

sub e4 {
  my ($obj,$string) = @_;
  $obj->{VEx} = [];
  $obj->{VEy} = [];
  $obj->{VEz} = [];

  $obj->find('E4');
  next unless $obj->{status}==1;

  # Read Message Header
  $msg_tag = "a2 s1";
  sysread($obj->{fh},$data,4);
  ($hdr, $length) = unpack($msg_tag,$data);
  $num_bins = $length/3;

  for ($i=0;$i<$num_bins;$i++) {
    $msg_tag = "s3";
    sysread($obj->{fh},$data,6);
    ($VEx, 
     $VEy, 
     $VEz) = unpack($msg_tag, $data);

    push($obj->{VEx},$VEx);
    push($obj->{VEy},$VEy);
    push($obj->{VEz},$VEz);
  }
}

sub e5 {
  my ($obj,$string) = @_;
  $obj->{ping_percent} = [];

  $obj->find('E5');
  next unless $obj->{status}==1;

  # Read Message Header
  $msg_tag = "a2 s1";
  sysread($obj->{fh},$data,4);
  ($hdr, $length) = unpack($msg_tag,$data);

  for ($i=0;$i<$length;$i++) {
    $msg_tag = "s1";
    sysread($obj->{fh},$data,2);
    ($pingstat) = unpack($msg_tag, $data);

    push($obj->{ping_percent},$pingstat);
  }
}

sub e6 {
  my ($obj,$string) = @_;
  $obj->{ch0_strength} = [];
  $obj->{ch1_strength} = [];
  $obj->{ch2_strength} = [];
  $obj->{ch3_strength} = [];

  $obj->find('E6');
  next unless $obj->{status}==1;

  # Read Message Header
  $msg_tag = "a2 s1";
  sysread($obj->{fh},$data,4);
  ($hdr, $length) = unpack($msg_tag,$data);
  $num_bins = $length/4;
  $num_chn = 4;

  for ($chn=0;$chn<$num_chn;$chn++) {
    for ($j=0;$j<$num_bins;$j++) {
      $msg_tag = "s1";
      sysread($obj->{fh},$data,2);
      ($sig_str) = unpack($msg_tag, $data);

      push($obj->{ch0_strength},$sig_str) if $chn==0;
      push($obj->{ch1_strength},$sig_str) if $chn==1;
      push($obj->{ch2_strength},$sig_str) if $chn==2;
      push($obj->{ch3_strength},$sig_str) if $chn==3;
    }
  }
}

sub e7 {
  my ($obj,$string) = @_;
  $obj->{ch0_snr} = [];
  $obj->{ch1_snr} = [];
  $obj->{ch2_snr} = [];
  $obj->{ch3_snr} = [];

  $obj->find('E7');
  next unless $obj->{status}==1;

  # Read Message Header
  $msg_tag = "a2 s1";
  sysread($obj->{fh},$data,4);
  ($hdr, $length) = unpack($msg_tag,$data);
  $num_bins = $length/4;
  $num_chn = 4;

  for ($chn=0;$chn<$num_chn;$chn++) {
    for ($j=0;$j<$num_bins;$j++) {
      $msg_tag = "s1";
      sysread($obj->{fh},$data,2);
      ($snr) = unpack($msg_tag, $data);

      push($obj->{ch0_snr},$snr) if $chn==0;
      push($obj->{ch1_snr},$snr) if $chn==1;
      push($obj->{ch2_snr},$snr) if $chn==2;
      push($obj->{ch3_snr},$snr) if $chn==3;
    }
  }
}

sub e8 {
  my ($obj,$string) = @_;
  $obj->find('E8');
  # Read Message Header
}

sub cwp {
  my ($obj,$len) = @_;
  my $outfile = "data.su";
  open(OF,">>$outfile");
  binmode OF;

  $datlen = scalar @{$obj->{bin_num}};

  for (my $i==0; $i<$len; $i++) {
    if ($i < $datlen) {

      $obj->{ch0_strength}[$i]=$obj->{bgnoise0}[$i] if $obj->{ping_percent}[$i] != 100;
      $obj->{ch1_strength}[$i]=$obj->{bgnoise1}[$i] if $obj->{ping_percent}[$i] != 100;
      $obj->{ch2_strength}[$i]=$obj->{bgnoise2}[$i] if $obj->{ping_percent}[$i] != 100;
      $obj->{ch3_strength}[$i]=$obj->{bgnoise3}[$i] if $obj->{ping_percent}[$i] != 100;

      # sum channels in Watts
      # $sum_strength = dBm2Watts(0.25*$obj->{ch0_strength}[$i]) + dBm2Watts(0.25*$obj->{ch1_strength}[$i]) + dBm2Watts(0.25*$obj->{ch2_strength}[$i]) + dBm2Watts(0.25*$obj->{ch3_strength}[$i]);
      # $strength = Watts2dBm($sum_strength);

      # sum channels in dBm (0.25 is scaling coeff, not average)
      $sum_strength = 0.25*($obj->{ch0_snr}[$i]+$obj->{ch1_snr}[$i]+$obj->{ch2_snr}[$i]+$obj->{ch3_snr}[$i]);
      $strength = $sum_strength;

      # spherical spreading = 2*dist*tan(theta), scaled to ping percentage
      $spreading = tan(22*PI/180)*2*$obj->{bin_len}*$obj->{bin_num}[$i]*$obj->{ping_percent}[$i]*0.01;

      # spherical spreading = dist**2, scaled to ping percentage
      # $spreading = ($obj->{bin_len}*$obj->{bin_num}[$i])**2*$obj->{ping_percent}[$i]*0.01;

      # apply spreading correction to result
      # $strength*=$spreading;
      print OF pack('f1',$strength);
    } else { 
      print OF pack('f1',0);
    }
  }
}

sub cwp_headers {
  my ($obj,$len) = @_;
  print "Writing data to " . $obj->{fname} . ".su" . "\n";
  my $outfile = $obj->{fname} . ".su";

  $ensemble = $obj->{ensemble};
  $static = sprintf('%0.3f',$obj->{blank_dist});
  $dt = sprintf('%3.0f',999*$obj->{bin_len});
  $cwp =<<EOF;
    suaddhead < data.su ns=$len | sushw key=dt,delrt a=$dt,$static b=0,0 | sushw key=fldr a=$ensemble b=1 | sugain mbal=1 > $outfile
    rm -f data.su
EOF

  print $cwp;
  system($cwp);
}

sub save {
  my ($obj) = @_;

      $obj->{ch0_strength}[$i]=$obj->{bgnoise0}[$i] if $obj->{ping_percent}[$i] != 100;
      $obj->{ch1_strength}[$i]=$obj->{bgnoise1}[$i] if $obj->{ping_percent}[$i] != 100;
      $obj->{ch2_strength}[$i]=$obj->{bgnoise2}[$i] if $obj->{ping_percent}[$i] != 100;
      $obj->{ch3_strength}[$i]=$obj->{bgnoise3}[$i] if $obj->{ping_percent}[$i] != 100;

  my $fields = "(ensemble, datetime, temp, volt, num_pings, bgnoise0, bgnoise1, bgnoise2, bgnoise3, trans_dir, trans_depth, " . 
               "blank_dist, mean_roll, std_roll, mean_pitch, std_pitch, mean_hdg, std_hdg, " .
               "bin_len, bin_num, ch0_vrad, ch1_vrad, ch2_vrad, ch3_vrad, VIx, VIy, VIz, VEx, VEy, VEz, " .
               "ping_percent, ch0_strength, ch1_strength, ch2_strength, ch3_strength, " .
               "ch0_snr, ch1_snr, ch2_snr, ch3_snr)";
  my $length = scalar @{$obj->{bin_num}};
  for ($i=0; $i<$length; $i++) {
    my @data = ($obj->{ensemble},
              $obj->{datetime},
              $obj->{temp},
              $obj->{volt},
              $obj->{num_pings},
              $obj->{bgnoise}[0],
              $obj->{bgnoise}[1],
              $obj->{bgnoise}[2],
              $obj->{bgnoise}[3],
              $obj->{trans_dir},
              $obj->{trans_depth},
              $obj->{blank_dist},
              $obj->{mean_roll},
              $obj->{std_roll},
              $obj->{mean_pitch},
              $obj->{std_pitch},
              $obj->{mean_hdg},
              $obj->{std_hdg},
              $obj->{bin_len},
              $obj->{bin_num}[$i],
              $obj->{ch0_vrad}[$i],
              $obj->{ch1_vrad}[$i],
              $obj->{ch2_vrad}[$i],
              $obj->{ch3_vrad}[$i],
              $obj->{VIx}[$i],
              $obj->{VIy}[$i],
              $obj->{VIz}[$i],
              $obj->{VEx}[$i],
              $obj->{VEy}[$i],
              $obj->{VEz}[$i],
              $obj->{ping_percent}[$i],
              $obj->{ch0_strength}[$i],
              $obj->{ch1_strength}[$i],
              $obj->{ch2_strength}[$i],
              $obj->{ch3_strength}[$i],
              $obj->{ch0_snr}[$i],
              $obj->{ch1_snr}[$i],
              $obj->{ch2_snr}[$i],
              $obj->{ch3_snr}[$i]);
    
    $values = "('" . join( "','", @data) . "')";  
    $query = "REPLACE INTO adcp " . $fields . " VALUES " . $values;
    $mysql->do($query);
  }
}

sub tan  { sin($_[0]) / cos($_[0]) }
sub log10 { $_[0] ? log($_[0])/log(10) : 0 }
sub dBm2Watts { 0.001*(10**(0.1*$_[0])) }
sub Watts2dBm { 10*log10(1000*$_[0]) }

##############################################################################################
#                       must return true to successfully load the class                      #
##############################################################################################
1;
