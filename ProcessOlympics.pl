#!/usr/bin/perl
use strict;
use warnings;
use Digest::MD5 qw(md5_hex);
use Set::Scalar;

use Path::Class;
use autodie; # die if problem reading or writing a file
print "Converting to Cypher\n";

open my $in_file, '<', 'london2012-gb-winners.csv' or die "Can't open file: $!";
open my $out_file, '>', 'london2012-olympics-cypher.txt' or die "Can't open file: $!";
my $countries = Set::Scalar->new;
my $events = Set::Scalar->new;
my $sports = Set::Scalar->new;
print $out_file "CREATE \(gold_medal:Medal { name : \"Gold\" })\n";
print $out_file "CREATE \(silver_medal:Medal { name : \"Silver\" })\n";
print $out_file "CREATE \(bronze_medal:Medal { name : \"Bronze\" })\n";
while (my $line = <$in_file>) {
	chomp($line);
	my $hash = md5_hex($line);
	my @fields = split "," , $line;
	my $name = $fields[0];
	my $country = $fields[1];
	my $country_hash = md5_hex($country);
	if (not $countries->has($country)) {
		$countries->insert($country);
		print $out_file "CREATE \(_$country_hash:Country { name : \"$country\" })\n";
	}
	my $age = $fields[2];
	my $height = $fields[3];
	my $weight = $fields[4];
	my $sex = $fields[5];
	my $dob = $fields[6];
	my $sport = $fields[7];
	my $sport_hash = md5_hex($sport);
	if (not $sports->has($sport)) {
		$sports->insert($sport);
		print $out_file "CREATE \(_$sport_hash:Sport { name : \"$sport\" })\n";
	}	
	my $athlete_events = $fields[8];
	$athlete_events =~ s/^"//;
    $athlete_events =~ s/"$//g;
    my @athlete_events_array = split ";", $athlete_events;
    my $athlete_events_cache = Set::Scalar->new;
    while(my $event = shift(@athlete_events_array)) {
		my $event_hash = md5_hex($event);	
		if (not $events->has($event)) {
			$events->insert($event);
			$athlete_events_cache->insert($event_hash);
			print $out_file "CREATE \(_$event_hash:Event { name : \"$event\" })\n";
			print $out_file "CREATE \(_$event_hash)-[:IS_EVENT_IN]->(_$sport_hash)\n";
		}
    }	
	my $medal = "NO";
	if (defined $fields[9]) { $medal = $fields[9]; }
	print $out_file "CREATE \(_$hash:Athlete { name : \"$name\", age : $age, height : $height, weight : $weight, sex : \"$sex\", dob : \"$dob\", medal : \"$medal\" })\n";
	print $out_file "CREATE \(_$hash\)-[:REPRESENTED]->\(_$country_hash\)\n";
	for my $athlete_event_hash ($athlete_events_cache->elements) {
		print $out_file "CREATE \(_$hash\)-[:COMPETED_IN]->\(_$athlete_event_hash\)\n";
	}	
	if (defined $fields[10]) {
		my $gold = $fields[10];
		print $out_file "CREATE \(_$hash\)-[:WON { weight : $gold }]->\(gold_medal\)\n";
	}
	if (defined $fields[11]) {
		my $silver = $fields[11];
		print $out_file "CREATE \(_$hash\)-[:WON { weight : $silver }]->\(silver_medal\)\n";
	}
	if (defined $fields[12]) {
		my $bronze = $fields[12];
		print $out_file "CREATE \(_$hash\)-[:WON { weight : $bronze }]->\(bronze_medal\)\n";
	}
}
close $in_file or die "Can't close file: $!";
close $out_file or die "Can't close file: $!";
