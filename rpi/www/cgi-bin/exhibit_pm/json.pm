package exhibit_pm::json;
use strict;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(json_preamble_out json_postamble_out json_items_out make_json_item);

our $VERSION=0.10;



########################################################################

sub json_preamble_out {
   my $types = shift(@_);
   my $props = shift(@_);
   my ($output,@output,$ret);
   push(@output, qq({\n\t'types': \{\n));
   foreach my $type (@$types) {
      my $type_plural = "$type" . "s";
      push(@output,  qq(\n\t\t"$type": {pluralLablel: "$type_plural"}));
   }
   push(@output, qq(\n\t\},));
   push(@output, qq(\t\n\t'properties': {));
   my $count = 0;
   foreach my $prop (keys %$props) {
      $count++;
      my $valuetype = $$props{$prop};
      push(@output, qq(\n\t\t"$prop": {\n\t\t\t"valueType": "$valuetype"}));
      if($count < scalar(keys %$props)) {
         push(@output, qq(,));
      } else {
         push(@output, qq(},));
      }
   }
   foreach my $line (@output) {
      $ret = $ret . "$line\n";
   }
   return $ret;
}

########################################################################

sub json_postamble_out {
   return "\t\]\n\}";
}

########################################################################

sub json_items_out {
   my @items = @_;
   my ($count,$ret);
   $ret = qq(\t"items" :\n\t\[);
   foreach my $item (@items) {
      $count ++;
      if ($count < scalar(@items)) {
         $ret = $ret . "$item,\n";
      } else {
         $ret = $ret . "$item\n";
      }
   }
   return $ret;
}

########################################################################

sub make_json_item {
   my $type = shift(@_);
   my $label = shift(@_);
   my $item = shift(@_);
   my $item_string  = "\t\t\{\n";
   $item_string = $item_string . qq(\t\t"type" : "$type",\n\t\t"label" : "$label",\n);
   my $count = 0;
   foreach my $key (keys %$item) {
      $count++;
      $item_string = "$item_string" . "\t\t\"$key\" : \"$$item{$key}\"";
      if($count < scalar(keys %$item)) {
         $item_string = $item_string . ",\n";
      } else {
         $item_string .= "\n";
      }
   }
#   $item_string = "$item_string" . "\t\t\"id\" : \"$id\"\t\t}";
    $item_string = "$item_string" . "\t\t}";
   return $item_string;

}

########################################################################
# this is an attempt to make the output of exhibit formatted json a single call
# I wonder if most all of this could be done with a map call from each row returned
# to this whole set of routines?
sub spew_json {
   my $types = shift(@_);
   my $props = shift(@_);
   my $items = shift (@_);
   my (@output, $output, $ret, $prop, $value, $count, $type_plural);

   print "Content-type: application/json\n\n";

   #this was originally the preable out
   push(@output, qq(\{\n\t"types": \{\n));
   foreach my $type (@$types) {
      $count ++;
      if ($type =~ m/s$/i) { 
         $type_plural = $type;
      } else {
         $type_plural = "$type" ."s";      
      }
      if ($count < scalar(@$types)) {
         push(@output,  qq(\n\t\t"$type": {"pluralLablel": "$type_plural"},));
      } else {
         push(@output,  qq(\n\t\t"$type": {"pluralLablel": "$type_plural"}));
      }
   }
   push(@output, qq(\n\t\},));
   push(@output, qq(\t\n\t"properties": {));
#   while (($prop, $value) = each %$props) {
   $count = 0;
   foreach $prop (keys %$props) {
      $count ++;      
      my $valuetype = $$props{$prop};
      if($count < scalar(keys %$props)) {
         push(@output, qq(\n\t\t"$prop": {\n\t\t\t"valueType": "$$props{$prop}"},));
      } else {
         push(@output, qq(\n\t\t"$prop": {\n\t\t\t"valueType": "$$props{$prop}"}\n\t},));
      }
   }
   foreach my $line (@output) {
      print "$line\n";
   }
   #this was json items out
   my $item_count;
   $ret = qq(\t"items" :\n\t\[);
   foreach my $item (@$items) {
      $item_count ++;
      if ($item_count < scalar(@$items)) {
         $ret = $ret . "$item,\n";
      } else {
         $ret = $ret . "$item\n";
      }
   }
   print $ret;
   #this was the postamble out
   print "\t\]\n\}";
}
########################################################################

1;
