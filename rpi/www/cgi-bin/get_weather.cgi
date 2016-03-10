#!/usr/bin/perl
use Modern::Perl;
use Date::Calc qw(Add_Delta_DHMS Today_and_Now);
use warnings;
use DBI;
use lib './';
use exhibit_pm::canvasjs;
use CGI;
use CGI::Carp 'fatalsToBrowser';
my $q = new CGI;
my %params = $q->Vars;
my $dbh = DBI->connect("dbi:SQLite:dbname=/home/wjw/weather.sql3","","");
my $time_back = get_hour_back($params{'time'});
print $q->header();
############################################################
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
         text: "Weather Readings"              
      },
      axisY: {
         minimum: -20,
         title: "Degrees(F)/Speed(mph)"
      },
      axisY2: {
         title: "Operating Volts(mV)"
      },
      axisX: {
         labelAngle: 90,
         valueFormatString: "HH:mm",
      },           
      data: [ 
END_START

##########################################################
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
##########################################################
print "$start\n";

if ( $params{'query'} eq "a") {
   get_temp();
   get_wind();
   get_op_volts();
   get_lux();
   get_ir();
   get_bb();
} elsif ($params{'query'} eq "w") {
   get_wind();
   get_temp();
   get_ra();
   get_rr();
} elsif ($params{'query'} eq "o") {
   get_op_volts();
} elsif ($params{'query'} eq "l") {
   get_lux();
   get_ir();
   get_bb();
} elsif ($params{'query'} eq "d") {
   get_temp();
}

################
print "$end\n";
$dbh->disconnect;
##########################################################################################################
# return json data of temperature readings
sub get_temp {
   my $row;
   my $query = qq(select * from temp where temp.ts >= '$time_back' order by ts);
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
   print "\n$json \n]\n }, \n";
}
##########################################################################
# return json data of wind readings
sub get_wind {
   my $row;
   my $query = qq(select * from speed where speed.ts >= '$time_back' order by ts);
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
      print "\n$json \n] \n},\n";
}

##########################################################################
# return json data of operating voltage readings
sub get_op_volts {
   my $row;
   my $query = qq(select * from op_volt where op_volt.ts >= '$time_back' order by ts);

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
      legendText: "Operating Volts(V)",
      valueFormatSting: "#,,.",
      dataPoints: [ ';
      print "\n$json \n] \n},\n";
}


#####################################################################################
# return json data of light sensor readings
sub get_lux {
   my $row;
   my $query = qq(select lux.ts, lux.lux from lux where lux.ts >= '$time_back' order by ts);

   my $sth = $dbh->prepare($query);

   $sth->execute();

   my (@items,$json);

   while ($row = $sth->fetchrow_hashref) {
      my %item;
      foreach my $header (keys %$row) {
         $item{$header} = $row->{$header};
         chomp($item{$header});
      }
      push(@items, exhibit_pm::canvasjs::make_item("lux",\%item));
   }

   $sth->finish;
   $json = "";
   foreach my $item (@items) {
      $json = "$json" . "$item" . ",\n";
   }
   $json =~ s/\,\n$//;
   print '{
      type: "line",
      showInLegend: true,
      legendText: "Light Intensity(V)",
      dataPoints: [ ';
   print "\n$json \n] \n},\n";
}


#####################################################################################
# return json data of light sensor readings (infrared)
sub get_ir {
   my $row;
   my $query = qq(select lux.ts, lux.infrared from lux where lux.ts >= '$time_back' order by ts);

   my $sth = $dbh->prepare($query);

   $sth->execute();

   my (@items,$json);

   while ($row = $sth->fetchrow_hashref) {
      my %item;
      foreach my $header (keys %$row) {
         $item{$header} = $row->{$header};
         chomp($item{$header});
      }
      push(@items, exhibit_pm::canvasjs::make_item("infrared",\%item));
   }

   $sth->finish;
   $json = "";
   foreach my $item (@items) {
      $json = "$json" . "$item" . ",\n";
   }
   $json =~ s/\,\n$//;
   print '{
      type: "line",
      showInLegend: true,
      legendText: "Infrared Intensity(V)",
      dataPoints: [ ';
   print "\n$json \n] \n},\n";
}
#####################################################################################
# return json data of light sensor readings (broadband)
sub get_bb {
   my $row;
   my $query = qq(select lux.ts, lux.broadband from lux where lux.ts >= '$time_back' order by ts);

   my $sth = $dbh->prepare($query);

   $sth->execute();

   my (@items,$json);

   while ($row = $sth->fetchrow_hashref) {
      my %item;
      foreach my $header (keys %$row) {
         $item{$header} = $row->{$header};
         chomp($item{$header});
      }
      push(@items, exhibit_pm::canvasjs::make_item("broadband",\%item));
   }

   $sth->finish;
   $json = "";
   foreach my $item (@items) {
      $json = "$json" . "$item" . ",\n";
   }
   $json =~ s/\,\n$//;
   print '{
      type: "line",
      showInLegend: true,
      legendText: "Broadband Intensity(V)",
      dataPoints: [ ';
   print "\n$json \n] \n},\n";
}
#####################################################################################
# return json data of rain sensor readings (amount)
sub get_ra {
   my $row;
   my $query = qq(select rain.ts, rain.amount from rain where rain.ts >= '$time_back' order by ts);

   my $sth = $dbh->prepare($query);

   $sth->execute();

   my (@items,$json);

   while ($row = $sth->fetchrow_hashref) {
      my %item;
      foreach my $header (keys %$row) {
         $item{$header} = $row->{$header};
         chomp($item{$header});
      }
      push(@items, exhibit_pm::canvasjs::make_item("rain_amount",\%item));
   }

   $sth->finish;
   $json = "";
   foreach my $item (@items) {
      $json = "$json" . "$item" . ",\n";
   }
   $json =~ s/\,\n$//;
   print '{
      type: "line",
      showInLegend: true,
      legendText: "Rain Amount",
      dataPoints: [ ';
   print "\n$json \n] \n},\n";
}
##############################################################
sub get_hour_back {
   my $hours = shift;
   return sprintf("%04d-%02d-%02dT%02d:%02d:%02dZ", Add_Delta_DHMS(Today_and_Now(), 0, $hours, 0, 0));
}
#####################################################################################
# return json data of rain sensor readings (rate)
sub get_rr {
   my $row;
   my $query = qq(select rain.ts, rain.rate from rain where rain.ts >= '$time_back' order by rain.ts);

   my $sth = $dbh->prepare($query);

   $sth->execute();

   my (@items,$json);

   while ($row = $sth->fetchrow_hashref) {
      my %item;
      foreach my $header (keys %$row) {
         $item{$header} = $row->{$header};
         chomp($item{$header});
      }
      push(@items, exhibit_pm::canvasjs::make_item("rain_rate",\%item));
   }

   $sth->finish;
   $json = "";
   foreach my $item (@items) {
      $json = "$json" . "$item" . ",\n";
   }
   $json =~ s/\,\n$//;
   print '{
      type: "line",
      showInLegend: true,
      legendText: "Rain Rate",
      dataPoints: [ ';
   print "\n$json \n] \n},\n";
}