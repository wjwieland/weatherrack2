#!/usr/bin/perl
use Modern::Perl;
use JSON;
use warnings;
use DBI;
use lib './';
use exhibit_pm::canvasjs;
use CGI qw(:standard);
use CGI::Carp 'fatalsToBrowser';
my $q = new CGI;
my %params = $q->Vars;
my $dbh = DBI->connect("dbi:SQLite:dbname=/home/wjw/weather.sql3","","");
my $time_back = '-1 day';
print $q->header('application/json');
get_temp();
$dbh->disconnect;
###################################################################################
sub get_temp {
   my $row;
   my $query = qq(select * from temp where temp.ts >= (select datetime('now', '$time_back')) order by ts);

   my $sth = $dbh->prepare($query);

   $sth->execute();

   my (@items,$json);

   while ($row = $sth->fetchrow_hashref) {
      my %item;
      foreach my $header (keys %$row) {
         $item{$header} = $row->{$header};
         chomp($item{$header});
      }
      push(@items, exhibit_pm::canvasjs::make_item("temperature",\%item));
   }
   $sth->finish;
	$json->{"entries"} = @items;
 	my $json_text = to_json($json);
 	print $json;
   $json = "";
   foreach my $item (@items) {
      $json = "$json" . "$item" . ",\n";
   }
   $json =~ s/\,\n$//;
   print "\n$json\n";
}