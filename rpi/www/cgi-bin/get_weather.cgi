#!/usr/bin/perl
use Modern::Perl;
use warnings;
use DBI;
use lib './';
use exhibit_pm::canvasjs;
use CGI;
use CGI::Carp 'fatalsToBrowser';
my $q = new CGI;
my %params = $q->Vars;
my $dbh = DBI->connect("dbi:SQLite:dbname=/home/wjw/weather.sql3","","");
my $time_back = '-1 day';
print $q->header();

my $start = << 'END_START';
<!DOCTYPE HTML>
<html>
<head>
<meta http-equiv="Refresh" content="30"/>
<script src="../javascript/canvasjs.min.js"></script>
<script src="../javascript/jquery-2.2.0.min.js"></script>
<script type="text/javascript">

window.onload = function () {
   var chart1 = new CanvasJS.Chart("chartContainer", {
      zoomEnabled: true,
      zoomType: "xy",
      title:{
         text: "24 Hour Readings"              
      },
      axisY: {
         minimum: -20,
         title: "Degrees(F)/Speed(mph)"
      },
      axisY2: {
         title: "Operating Volts(mV)"
      },             
      data: [ 
END_START

my $end = << 'END_END';
      ]
   }
   );
   chart1.render();
}
</script>
</head>
<body>
<div id="chartContainer" style="height: 600px; width: 100%;"></div>
</body>
</html>
END_END

print "$start\n";

if ( $params{'query'} eq "a") {
   get_temp();
   get_wind();
   get_op_volts();
   get_lux();
} elsif ($params{'query'} eq "w") {
   get_wind();
} elsif ($params{'query'} eq "o") {
   get_op_volts();
} elsif ($params{'query'} eq "l") {
   get_lux();
} elsif ($params{'query'} eq "t") {
   get_temp();
}
print "$end\n";
$dbh->disconnect;
##########################################################################################################
# return json data of temperature readings
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
   $json = "";
   foreach my $item (@items) {
      $json = "$json" . "$item" . ",\n";
   }
   $json =~ s/\,\n$//;
   print '{
      type: "line",
      axisYType: "primary",
      showInLegend: true,
      legendText: "Temperature(F)",       
      dataPoints: [ ';
   print "\n$json ] }, \n";
}
##########################################################################
# return json data of wind readings
sub get_wind {
   my $row;
   my $query = qq(select * from speed where speed.ts >= (select datetime('now', '$time_back')) order by ts);

   my $sth = $dbh->prepare($query);

   $sth->execute();

   my (@items,$json);

   while ($row = $sth->fetchrow_hashref) {
      my %item;
      foreach my $header (keys %$row) {
         $item{$header} = $row->{$header};
         chomp($item{$header});
      }
      push(@items, exhibit_pm::canvasjs::make_item("speed",\%item));
   }

   $sth->finish;
   $json = "";
   foreach my $item (@items) {
      $json = "$json" . "$item" . ",\n";
   }
   $json =~ s/\,\n$//;
   print '{
      type: "line",
      axisYType: "primary",
      showInLegend: true,
      legendText: "Wind Speed(mph)",         
      dataPoints: [ ';
      print "$json ] },\n";
}

##########################################################################
# return json data of operating voltage readings
sub get_op_volts {
   my $row;
   my $query = qq(select * from op_volt where op_volt.ts >= (select datetime('now', '$time_back')) order by ts);

   my $sth = $dbh->prepare($query);

   $sth->execute();

   my (@items,$json);

   while ($row = $sth->fetchrow_hashref) {
      my %item;
      foreach my $header (keys %$row) {
         if ($header =~ 'ts') {
            $item{$header} = $row->{$header};
         } else {
            $item{$header} = $row->{$header} * 0.01;
         }
         chomp($item{$header});
      }
      push(@items, exhibit_pm::canvasjs::make_item("volts",\%item));
   }

   $sth->finish;
   $json = "";
   foreach my $item (@items) {
      $json = "$json" . "$item" . ",\n";
   }
   $json =~ s/\,\n$//;
   print '{
      type: "line",
      axisYType: "secondary",
      showInLegend: true,
      legendText: "Operating Volts(mv)",
      valueFormatSting: "#,,.",
      dataPoints: [ ';
      print "$json ] },\n";
}


#####################################################################################
# return json data of light sensor readings
sub get_lux {
   my $row;
   my $query = qq(select * from lux where lux.ts >= (select datetime('now', '$time_back')) order by ts);

   my $sth = $dbh->prepare($query);

   $sth->execute();

   my (@items,$json);

   while ($row = $sth->fetchrow_hashref) {
      my %item;
      foreach my $header (keys %$row) {
         $item{$header} = $row->{$header};
         chomp($item{$header});
      }
      push(@items, exhibit_pm::canvasjs::make_item("analog_val",\%item));
   }

   $sth->finish;
   $json = "";
   foreach my $item (@items) {
      $json = "$json" . "$item" . ",\n";
   }
   $json =~ s/\,\n$//;
   print '{
      type: "line",
      dataPoints: [ ';
   print "$json ] }\n";
}


#####################################################################################