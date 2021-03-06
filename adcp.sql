CREATE TABLE `adcp` (
 `ensemble`         int(11) NOT NULL COMMENT 'sample ID',
 `datetime`        datetime NOT NULL COMMENT 'time of sampling',
 `lon`                float NOT NULL COMMENT 'longitude',
 `lat`                float NOT NULL COMMENT 'latitude',
 `temp`               float NOT NULL COMMENT 'temperature (C)',
 `volt`               float NOT NULL COMMENT 'voltage (V)',
 `num_pings`        int(11) NOT NULL COMMENT 'number of pings per bin',
 `bgnoise0`           float NOT NULL COMMENT 'ch0 background noise (dB)',
 `bgnoise1`           float NOT NULL COMMENT 'ch1 background noise (dB)',
 `bgnoise2`           float NOT NULL COMMENT 'ch2 background noise (dB)',
 `bgnoise3`           float NOT NULL COMMENT 'ch3 background noise (dB)',
 `trans_dir`    varchar(10) NOT NULL COMMENT 'transducer direction',
 `trans_depth`        float NOT NULL COMMENT 'transducer depth (m)',
 `blank_dist`         float NOT NULL COMMENT 'blanking distance (m)',
 `mean_roll`          float NOT NULL COMMENT 'average roll (deg)',
 `std_roll`           float NOT NULL COMMENT 'stand. dev roll (deg)',
 `mean_pitch`         float NOT NULL COMMENT 'average pitch (deg)',
 `std_pitch`          float NOT NULL COMMENT 'stand. dev pitch (deg)',
 `mean_hdg`           float NOT NULL COMMENT 'average heading (deg)',
 `std_hdg`            float NOT NULL COMMENT 'stand. dev heading (deg)',
 `bin_len`            float NOT NULL COMMENT 'bin length (m)',
 `bin_num`            float NOT NULL COMMENT 'bin number',
 `ch0_vrad`           float NOT NULL COMMENT 'radial velocity (mm/sec)',
 `ch1_vrad`           float NOT NULL COMMENT 'radial velocity (mm/sec)',
 `ch2_vrad`           float NOT NULL COMMENT 'radial velocity (mm/sec)',
 `ch3_vrad`           float NOT NULL COMMENT 'radial velocity (mm/sec)',
 `VIx`                float NOT NULL COMMENT 'instrument x-velocity (mm/sec)',
 `VIy`                float NOT NULL COMMENT 'instrument y-velocity (mm/sec)',
 `VIz`                float NOT NULL COMMENT 'instrument z-velocity (mm/sec)',
 `VEx`                float NOT NULL COMMENT 'earth x-velocity (mm/sec)',
 `VEy`                float NOT NULL COMMENT 'earth y-velocity (mm/sec)',
 `VEz`                float NOT NULL COMMENT 'earth z-velocity (mm/sec)',
 `ping_percent`       float NOT NULL COMMENT 'number of valid pings per bin',
 `ch0_strength`       float NOT NULL COMMENT 'signal strength (dBm)',
 `ch1_strength`       float NOT NULL COMMENT 'signal strength (dBm)',
 `ch2_strength`       float NOT NULL COMMENT 'signal strength (dBm)',
 `ch3_strength`       float NOT NULL COMMENT 'signal strength (dBm)',
 `ch0_snr`            float NOT NULL COMMENT 'signal to noise ratio (dB)',
 `ch1_snr`            float NOT NULL COMMENT 'signal to noise ratio (dB)',
 `ch2_snr`            float NOT NULL COMMENT 'signal to noise ratio (dB)',
 `ch3_snr`            float NOT NULL COMMENT 'signal to noise ratio (dB)',
 PRIMARY KEY (`ensemble`,`datetime`,`bin_num`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1
