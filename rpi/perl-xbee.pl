#!/usr/bin/perl -w
use Modern::Perl;
use Device::SerialPort;
use DBI;
use DateTime;
#use Device::XBee::API;
my $dbfile = "/home/wjw/weather.sql3";
my $dbh = DBI->connect("dbi:SQLite:dbname=$dbfile" ,"","");
my ($key,$val, %rx, $q, $cnt, %last, %hash, $sth, $char_cnt, $char, $timeout, $buffer);

%last = 
    (
        "wv"  => 0,
        "wd"  => 0,
        "ra"  => 0,
        "rr"  => 0,
		"lux" => 0,
		"tF"  => 0,
		"ov"  => 0,
		"bbl" => 0,
		"irl" => 0
    );
# Set up the serial port
my $dev = Device::SerialPort->new("/dev/ttyUSB0") || warn "Can't open /dev/ttyUSB0  $!";
my $debug = 0;	#set to 1 if debug print statements are to be displayed
my $profile = 0; # set to '1' when running NYTProfile.  Limits run length...
# 19200, 81N on the USB ftdi driver
$dev->baudrate(115200); # you may change this value
$dev->databits(8);      # but not this and the two following
$dev->parity("none");
$dev->stopbits(1);
$dev->read_char_time( 0 );        # don't wait for each character
$dev->read_const_time( 1000 );    # 1 second per unfulfilled "read" call


#my $xb = Device::XBee::API->new( { fh => $dev, timeout => 20 } ) || warn 'no xbee   $!';
#if ($debug == 1) {warn 'got xbee';}

while (1) {
# Poll to see if any data is coming in
#	my $rx = $xb->rx();
#	my $match = $dev->are_match("-re", '^{.*}$');  
    my $char = $dev->lookfor();
	$cnt++;	
	if ($char) {
   		if ($debug == 1) {
 			say "Raw input is -> $char";
       	}
       	my $timestamp = uts_to_iso(time());
		my $line = $char;
		chomp($line);
		$line =~ s/\{//g; $line =~ s/\}//g;	$line =~ s/\"//g; $line =~ s/\n,//g;
		my @lines = split(/\,/, $line);
		$hash{'count'} = $cnt;
		foreach my $field (@lines) {
	   		($key, $val) = split(/\:/, $field);
	   		$hash{$key} = $val;
	   		if ($debug == 1) {
				say "$timestamp $key  =  $val";
			}
		}
		foreach (sort keys %hash) {	
			if ($debug == 1) {
				say "Found key $_ = $hash{$_}";
				say "Prev. val    = $last{$_}";
			}
			next if $_ =~ m/rr/;              #rain rate gets filled in when there is rain amount(ra)
	  		if (($_ =~ m/wv/) && ($hash{$_} != $last{$_})) {
   				$q = qq(insert into speed (ts, speed) values ( '$timestamp', $hash{$_})); 
				$dbh->do($q);
	  		}
	  		if (($_ =~ m/wd/i) && ($hash{$_} != $last{$_}) && ($_ >= 0) ) {
				$q = qq(insert into direction (ts, direction) values ( '$timestamp', $hash{$_})); 
				$dbh->do($q);			
	 		} 
				if (($_ =~ m/ra/i) && ($hash{$_} > 0)) { 
				$q = qq(insert into rain (ts, amount, rate) values ( '$timestamp', $hash{'$_'}, $hash{'rr'})); 
				$dbh->do($q);				
	 		}
       		if ( ($_ =~ m/tF/i) && ($hash{$_} != $last{$_}) ) { 
				$q = qq(insert into temp (ts, temperature) values ( '$timestamp', $hash{'tF'})); 
				$dbh->do($q);			
		 	}
	    	if ( ( $_ =~ m/ov/i ) && ($hash{$_} != $last{$_} ) ) {
				$q = qq(insert into op_volt (ts, volts) values ('$timestamp', $hash{'ov'}));
				$dbh->do($q);			
			}
		  	if ( ($_ =~ m/lux/i) && ($hash{$_} != $last{$_}) ) {
				$q = qq(insert into lux (ts, lux, broadband, infrared) values ('$timestamp', $hash{'lux'}, $hash{'bbl'}, $hash{'irl'}));
				$dbh->do($q);		
			}
			if ( ($debug == 1) && (length($q) > 0) ) {
				sayq($q);
			} elsif ( ($debug == 1) && (length($q) < 1) ) {
				say "empty query!";
			}
		}
		say "";
		say "";
		$q = '';	#clear the query string so debugging is not confusing.	
		%last = %hash;  #copy current to last hash for next compare
		$dev->lookclear;		
		if ($profile == 1) {
			if ($cnt >= 25) {
				exit;
	 		} else {
				print "Count is $cnt\n";
			}
		}
	}
	sleep(1);
}
################################
sub uts_to_iso {
    my $uts = shift;
    my $date = DateTime->from_epoch(epoch => $uts, time_zone => 'America/Chicago');
    return $date->ymd().'T'.$date->hms().'Z';
}
################################
sub sayq {
	my $qs = shift @_;
	if (length($qs) > 0) {
		say $qs;
	}
}
