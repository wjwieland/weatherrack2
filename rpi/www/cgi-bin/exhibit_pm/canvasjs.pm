package exhibit_pm::canvasjs;
use strict;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(make_date datax daaty make_item x_axis y_axis);

our $VERSION=0.10;



########################################################################
sub make_item {
	my $data_label = shift;
	my $db_row = shift;
	my $ds = %$db_row{"ts"};
	my $date_obj = make_date($ds);
	return $date_obj . 'y: ' . %$db_row{$data_label} . ' }';
}
#########################################################################
sub make_date {
	my $ts = shift;
	$ts =~ s/Z$//;
	my @ts = split(/[:\-T]/,$ts);
	my $start = '{x: new Date(';
	my $time =  join(',', @ts);
	my $end = ") ,";
	return $start . $time . $end;
}
#########################################################################
sub datay {

}
#########################################################################
sub datax {

}
#########################################################################
sub x_axis {

}
#########################################################################
sub y_axis {

}
#########################################################################