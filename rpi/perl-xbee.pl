#!/usr/bin/perl
# Set up the serial port
use Device::SerialPort;
use DBI;
use Switch;
use DateTime;
my $dbfile = "/home/wjw/weather.sql3";
my $dbh = DBI->connect("dbi:SQLite:dbname=$dbfile" ,"","");
my $sth;
my %hash;    #current vals incoming
my %last;    #last read values
my $port = Device::SerialPort->new("/dev/ttyAMA0");
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
#	   		print "key " . $key . " = " . $val . "\n";
	   		$hash{$key} = $val;
		}
		foreach (sort keys %hash) {	
			next if $hash{$_} == $last{$_};  #don't store values that have not changed
			if ($_ =~ m/wv|wd/) {
	    		$q = qq(insert into wind (ts, velocity, direction) values ( \'$timestamp\', $hash{$_}, $hash{'wd'})); 
				$sth=$dbh->prepare($q);
				$sth->execute;
			}
  
	   		if ($_ =~ /ra|rr/) { 
				$q = qq(insert into rain (ts, amount, rate) values ( \'$timestamp\', $hash{'ra'}, $hash{'rr'})); 
				print $q;
				$sth=$dbh->prepare($q);
				$sth->execute;
			}

        	if ($_ =~ /tF/) { 
				$q = qq(insert into temp ( ts, temperature ) values ( \'$timestamp\', $hash{'tF'})); 
				$sth=$dbh->prepare($q);
				$sth->execute;
			}
    	}
		%last = %hash;  #copy current to last hash for next compare
#		print $q;
	} 
    	# Uncomment the following lines, for slower reading,
    	# but lower CPU usage, and to avoid
    	# buffer overflow due to sleep function.
 
    	$port->lookclear;
    	sleep (1);
}


sub uts_to_iso {
	my $uts = shift;
	my $date = DateTime->from_epoch(epoch => $uts, time_zone => 'UTC');
	return $date->ymd().'T'.$date->hms().'Z';
}
