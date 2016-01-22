#!/usr/bin/perl
# Set up the serial port
use Device::SerialPort;
use DBI;
use Switch;
use DateTime;
my $dbfile = "/home/wjw/weather.sql3";
my $dbh = DBI->connect("dbi:SQLite:dbname=$dbfile" ,"","");
my $sth;
my %last;    #last read values
my $port = Device::SerialPort->new("/dev/ttyAMA0");
my $debug = 1;	#set to 1 if debug print statements are to be displayed
# 19200, 81N on the USB ftdi driver
$port->baudrate(115200); # you may change this value
$port->databits(8); # but not this and the two following
$port->parity("none");
$port->stopbits(1);
 
# now catch gremlins at start
my $tEnd = time()+2; # 2 seconds in future
while (time()< $tEnd) { # end latest after 2 seconds
  my $c = $port->lookfor(); # char or nothing
  next if $c eq ""; # restart if noting
  # print $c; # uncomment if you want to see the gremlin
  last;
}
while (1) { # and all the rest of the gremlins as they come in one piece
  my $c = $port->lookfor(); # get the next one
  last if $c eq ""; # or we're done
  # print $c; # uncomment if you want to see the gremlin
}


#$port->write("Whatever you feel like sending");

while (1) {
    # Poll to see if any data is coming in
	my %hash;    #current vals incoming
    my $char = $port->lookfor();
    my $timestamp = uts_to_iso(time());
    my $q;
    # If we get data, then print it
    # Send a number to the arduino
    if ($char) {
        #print " $char \n";
		my $line = $char;
		chomp($line);
		$line =~ s/\{//g;
		$line =~ s/\}//g;
		$line =~ s/\"//g;
		$line =~ s/\n,//g;
		my @lines = split(/\,/, $line);
		foreach my $field (@lines) {
	   		($key, $val) = split(/\:/, $field);
	   		if ($debug == 1) {print "key " . $key . " = " . $val . "\n";}
	   		$hash{$key} = $val;
		}
		foreach (sort keys %hash) {	
			next if $_ =~ m/rr/;              #rain rate gets filled in when there is rain amount(ra)
			if (($_ =~ m/wv/) && ($hash{$_} != $last{$_})) {
	    		$q = qq(insert into speed (ts, speed) values ( '$timestamp', $hash{$_})); 
				$sth=$dbh->prepare($q);
				$sth->execute;
			}

 			if (($_ =~ m/wd/) && ($hash{$_} != $last{$_})) {
	    		$q = qq(insert into direction (ts, direction) values ( '$timestamp', $hash{$_})); 
				$sth=$dbh->prepare($q);
				$sth->execute;
			} 

	   		if (($_ =~ /ra/) && ($hash{$_} > 0)) { 
				$q = qq(insert into rain (ts, amount, rate) values ( '$timestamp', $hash{'ra'}, $hash{'rr'})); 
				print $q;
				$sth=$dbh->prepare($q);
				$sth->execute;
			}

        	if (($_ =~ /tF/) && ($hash{$_} != $last{$_})){ 
				$q = qq(insert into temp ( ts, temperature ) values ( '$timestamp', $hash{'tF'})); 
				$sth=$dbh->prepare($q);
				$sth->execute;
			}
			if ($debug == 1) {print "$q\n\n";}
			$q = '';	#clear the query string so debugging is not confusing.
    	}
		%last = %hash;  #copy current to last hash for next compare
	} 
    	# Uncomment the following lines, for slower reading,
    	# but lower CPU usage, and to avoid
    	# buffer overflow due to sleep function.
 
    	$port->lookclear;
    	sleep (1);
}


sub uts_to_iso {
	my $uts = shift;
	my $date = DateTime->from_epoch(epoch => $uts, time_zone => 'America/Chicago');
	return $date->ymd().'T'.$date->hms().'Z';
}
