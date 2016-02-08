#!/usr/bin/perl
use Device::SerialPort;
use DBI;
use Switch;
use DateTime;
use Device::XBee::API;
use strict;
use warnings;

my $dbfile = "/home/wjw/weather.sql3";
my $dbh = DBI->connect("dbi:SQLite:dbname=$dbfile" ,"","");
my $sth;
my %last;    #last read values
my %hash;
my ($key,$val,%rx,$q,$cnt);
# Set up the serial port
my $dev = Device::SerialPort->new("/dev/ttyUSB0");
my $debug = 1;	#set to 1 if debug print statements are to be displayed
# 19200, 81N on the USB ftdi driver
$dev->baudrate(115200); # you may change this value
$dev->databits(8); # but not this and the two following
$dev->parity("none");
$dev->stopbits(1);

my $xb = Device::XBee::API->new( { fh => $dev, timeout => 20 } ) || die 'no xbee';
if ($debug == 1) {warn 'got xbee';}

while (1) {
    # Poll to see if any data is coming in
	my $rx = $xb->rx();
	if (defined $rx->{'data'}) {
	    my $timestamp = uts_to_iso(time());
		$cnt++;
		my $line = $rx->{'data'};
		chomp($line);
		$line =~ s/\{//g;
		$line =~ s/\}//g;
		$line =~ s/\"//g;
		$line =~ s/\n,//g;
		$line =~ s/'\cM'//g;
		my @lines = split(/\,/, $line);
		$hash{'count'} = $cnt;
		foreach my $field (@lines) {
	   		($key, $val) = split(/\:/, $field);
	   		if ($debug == 1) {
				print $timestamp . ": key " . $key . " = " . $val . "\n";
			}
	   		$hash{$key} = $val;
		}
		if ($debug == 1) {
			print "\n";
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

       		if (($_ =~ /tF/) && ($hash{$_} - $last{$_} >= 1.0 )) { 
				$q = qq(insert into temp (ts, temperature) values ( '$timestamp', $hash{'tF'})); 
				$sth=$dbh->prepare($q);
				$sth->execute;
			}

			if ( ( $_ =~ /ov/i ) && ($hash{$_} != $last{$_} ) ) {
				$q = qq(insert into op_volt (ts, volts) values ('$timestamp', $hash{'ov'}));
				$sth=$dbh->prepare($q);
				$sth->execute;
			}
			
			if ($debug == 1) {
				if ($q !~ m/""/) {
					print "$q\n";
				}
			}
			$q = '';	#clear the query string so debugging is not confusing.
   		}
		%last = %hash;  #copy current to last hash for next compare
#   		sleep (1);
	}
}

sub uts_to_iso {
	my $uts = shift;
	my $date = DateTime->from_epoch(epoch => $uts, time_zone => 'America/Chicago');
	return $date->ymd().'T'.$date->hms().'Z';
}
