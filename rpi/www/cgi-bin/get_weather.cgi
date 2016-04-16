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
<script src="../javascript/jquery-2.2.3.js"></script>
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
<div id="chartContainer" style="height: 600px; width:90%;"></div>

<div id="slider-holder" style="height: 75px; width:40%;">
<form action="http://192.168.0.11/cgi-bin/get_weather.cgi" method="get">
   Hours back in time:<br>
   <input id="slider" type="range" name="time" min="-36" max="-1" step="1" value="-1" width="40%" onchange="printValue('slider','textbox1')">
   <input id="textbox1" type="text" size="2"><br>
   <input type="radio" name="query" value="w" checked> Weather<br>
   <input type="radio" name="query" value="l"> Light<br>
   <input type="radio" name="query" value="o"> Operating Voltage<br>     
   <input type="submit">
</form>
</div><br/>
<script>
    function printValue(a, b) {
        var x = document.getElementById(a);
        var y = document.getElementById(b);
        y.value = x.value;
    }
</script>

</body>
</html>
END_END
##########################################################
print "$start\n";

my $args = {
   t => {
      q => qq(select temp.ts, temp.temperature from temp where temp.ts >= '$time_back' order by ts),
      l => "Temperature"
   },
   w => {
      q => qq(select speed.ts, speed.speed from speed where speed.ts >= '$time_back' order by ts),
      l => "Wind Speed"
   },
   ra => {
      q => qq(select rain.ts, rain.amount from rain where rain.ts >= '$time_back' order by ts),
      l => "Rain Amount"
   },     
   rr => {
      q => qq(select rain.ts, rain.rate from rain where rain.ts >= '$time_back' order by rain.ts),
      l => "Rain Rate"
   },
   l => {
      q => qq(select lux.ts, lux.lux from lux where lux.ts >= '$time_back' order by ts),
      l => "Lux"
   },
   bb => {
      q => qq(select lux.ts, lux.broadband from lux where lux.ts >= '$time_back' order by ts),
      l => "Broadband"
   },  
   ir => {
      q => qq(select lux.ts, lux.infrared from lux where lux.ts >= '$time_back' order by ts),
      l => "Infrared"
   },
   o => {
      q => qq(select op_volt.ts, (op_volt.volts * 1000) from op_volt where op_volt.ts >= '$time_back' order by ts),
      l => "Operating Volts (m/V)"
   }
};

if ( $params{'query'} eq "a") {
   get_data($args->{t}->{q}, $args->{t}->{l});
   get_data($args->{w}->{q}, $args->{w}->{l});
   get_data($args->{o}->{q}, $args->{o}->{l});
   get_data($args->{l}->{q}, $args->{l}->{l});
   get_data($args->{ir}->{q}, $args->{ir}->{l});
   get_data($args->{bb}->{q}, $args->{bb}->{l});
} elsif ($params{'query'} eq "w") {
   get_data($args->{t}->{q}, $args->{t}->{l});
   get_data($args->{w}->{q}, $args->{w}->{l});
   get_data($args->{rr}->{q}, $args->{rr}->{l});
   get_data($args->{ra}->{q}, $args->{ra}->{l});
} elsif ($params{'query'} eq "o") {
   get_data($args->{o}->{q}, $args->{o}->{l});
} elsif ($params{'query'} eq "l") {
   get_data($args->{l}->{q}, $args->{l}->{l});
   get_data($args->{ir}->{q}, $args->{ir}->{l});
   get_data($args->{bb}->{q}, $args->{bb}->{l});
   get_data($args->{o}->{q}, $args->{o}->{l});
}

################
print "$end\n";
$dbh->disconnect;

##########################################################################################################
sub get_data {
   my ($query, $label) = @_;
   my ($row, @items, $json, $y_header);
   my $sth = $dbh->prepare($query);
   $sth->execute();
   while ($row = $sth->fetchrow_hashref) {
      my %item;
      foreach my $header (keys %$row) {
         $item{$header} = $row->{$header};
         chomp($item{$header});
         if ($header !~ /^ts$/) {
            $y_header = $header;
         }
      }
      push(@items, exhibit_pm::canvasjs::make_item($y_header,\%item));
   }
   $sth->finish;
   $json = "";
   foreach my $item (@items) {
      $json = "$json" . "$item" . ",\n";
   }
   $json =~ s/\,\n$//;
   print qq( {
      type: "line",
      axisYType: "primary",
      showInLegend: true,
      legendText: '$label',       
      dataPoints: [ );
   print "\n$json \n]\n }, \n";
}
##############################################################
sub get_hour_back {
   my $hours = shift;
   return sprintf("%04d-%02d-%02dT%02d:%02d:%02dZ", Add_Delta_DHMS(Today_and_Now(), 0, $hours, 0, 0));
}
#####################################################################################
