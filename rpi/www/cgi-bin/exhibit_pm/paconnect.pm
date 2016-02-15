package exhibit_pm::paconnect;

use strict;
use warnings;
use DBI;
use Win32::OLE;
use Win32::OLE::Const 'Microsoft ActiveX Data Objects';
use Win32::OLE::Variant;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(hist_dbh pa_dbh);

our $VERSION=0.10;
my $uname = "mesrprtadmin";
my $pword = "rea10ata";

sub pa_dbh {
   my $cgi_arg = shift(@_);
   my $server;
   if ($cgi_arg =~ /tremonton/i) {
      $server = "s300mes1";
   } elsif ($cgi_arg =~ /northfield/i) {
      $server = "s200mes1";
   } elsif ($cgi_arg =~ /asheboro/i) {
      $server = "s400mes1";
   } elsif ($cgi_arg =~ /devel/i) {
      $server = "smes1d";
   } else {
      $server = "s200mes1";
   }
   my $DSN = 'driver={SQL Server};' . "Server=$server;" . 'database=GBDB; uid=mesrprtadmin; pwd=rea10ata;';
   my $dbh  = DBI->connect("dbi:ODBC:$DSN") or die "$DBI::errstr\n";
   $dbh->{'LongTruncOk'} = 1; #use 1 if it is ok to trunc data
   $dbh->{'LongReadLen'} = 10000000; # i have seen upto 800,000 bytes already.
   return $dbh;
}

sub hist_dbh {
   my $server = shift(@_);
   my $qstring = shift(@_);
   my $hist_con = Win32::OLE->new('ADODB.Connection'); # creates a connection object
   my $dsn = "Provider=ihOLEDB.iHistorian.1;Data Source=$server";
   $hist_con->Open($dsn);
   if (Win32::OLE->LastError()) {
      print "This didn't go well: ", Win32::OLE->LastError(), "\n";
      exit;
   } else {
      my $hrs->Open($qstring, $hist_con);       
      return $hrs;
   }
}

1;
