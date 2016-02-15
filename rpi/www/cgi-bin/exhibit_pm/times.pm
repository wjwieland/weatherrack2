package exhibit_pm::times;

use strict;
use Date::Calc qw(:all);

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(make_date htag_time_minus htag_time_plus adj_time compare_time timeplot_time);

our $VERSION=0.10;

########################################################################
# take a date in yyyy-mm-dd hh:mm:ss and return yyyy-mm-ddThh:mm:ssZ
sub make_exhibit_time {
   my $time = shift(@_);
   $time =~ s/\s/T/;
   $time =~ s/\.\d\d\d$/Z/;
   return $time;
}

########################################################################
# returns two date/times.  One which is now (localtime) and one which is now - $hrs
# both are returned in 'yyyy-mm-dd hh:mm:ss' format
# defaults to 24 hours if nothing handed in
sub make_date {
   my $hrs = shift(@_);
   my ($start,$end,@start,@end);
   if (! $hrs) {
      $hrs = -24;
   }
   @start = Add_Delta_DHMS(Today_and_Now(), 0,-$hrs,0,0);
   @end = Today_and_Now();
   $end = sprintf("%d\-%02d\-%02d %02d:%02d:%02d",($end[0],$end[1],$end[2],$end[3],$end[4],$end[5]));
   $start = sprintf("%d\-%02d\-%02d %02d:%02d:%02d",($start[0],$start[1],$start[2],$start[3],$start[4],$start[5]));
   return ($start, $end);
}
########################################################################
# returns a date/time 15 minutes previous to that which is handed in
# incoming date/time must me in 'yyyy-mm-ddThh:mm:ss.000' format
sub htag_time_minus {
   my $time1 = shift(@_);
   $time1 =~ s/Z$//;
   my ($Y,$M,$D,$h,$m,$s) = split(/[-:T. ]/,$time1);
   my ($year,$month,$day, $hour,$min,$sec) = Add_Delta_YMDHMS($Y,$M,$D,$h,$m,$s,0,0,0,0,-15,0);
   my $ret = sprintf("%d\-%02d\-%02d %02d:%02d:%02d",($year,$month,$day,$hour,$min,$sec));

   return $ret;
}
########################################################################
# returns a date/time 15 minutes past that which is handed in
# incoming date/time must me in 'yyyy-mm-ddThh:mm:ss.000' format

sub htag_time_plus {
   my $time1 = shift(@_);
   $time1 =~ s/Z$//;
   my ($Y,$M,$D,$h,$m,$s) = split(/[-:T. ]/,$time1);
   my ($year,$month,$day, $hour,$min,$sec) = Add_Delta_YMDHMS($Y,$M,$D,$h,$m,$s,0,0,0,0,+15,0);
   my $ret = sprintf("%d\-%02d\-%02d %02d:%02d:%02d",($year,$month,$day,$hour,$min,$sec));
   return $ret;
}
#############################################
# intended to return a date/time in exhibit format when the incoming date/time is in the AM/PM format
# returns date/time in 24 hour time
sub adj_time {
   my $str = shift(@_);
   my ($date,$time,$am_pm) = split(/ /,$str);
   my @date = split(/\//,$date);
   my $newdate = sprintf("%d\-%02d\-%02d",($date[2],$date[0],$date[1]));
   my @time = split(/:/,$time);
   if(($time[0] < 12) && ($am_pm =~ /PM/)) {
      $time[0] = ($time[0] + 12);
   }

   my $newtime = sprintf("%02d:%02d:%02d",@time);
   my $ret = "$newdate" . "T" . "$newtime" . "Z";
   return $ret;
}
#############################################
sub compare_time {
   my $time1 = shift(@_);
   my $time2 = shift(@_);
   $time1 =~ s/Z$//;
   $time2 =~ s/Z$//;
   my @time1 = split(/[-:T]/,$time1);
   my @time2 = split(/[-:T]/,$time2);
   my ($D_y,$D_m,$D_d, $Dh,$Dm,$Ds) = Delta_YMDHMS(@time1,@time2);
   return $Dm;
}

########################################################################
# requires a date as an arg in the format 'yyyy-mm-ddThh:mm:ssZ'
# return the same date in the format 'yyyy-mm-dd hh:mm:ss'
sub timeplot_time {
   my @date = split(/[-T:Z]/,shift(@_));
   my $ret = "$date[0]-$date[1]-$date[2] $date[3]:$date[4]:$date[5]";
   return  $ret;
}

1;
