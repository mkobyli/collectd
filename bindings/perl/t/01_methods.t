#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 12;
use Collectd::Unixsock;
use Collectd::MockDaemon;

my $path = mockd_start();
END { mockd_stop(); }

my $s = Collectd::Unixsock->new($path);
isnt($s, undef, "Collectd::Unixsock object created");

my %queries = (
    'w83df6600/vmem/vmpage_number-vmscan_write' => [ 1, { value => 0 } ],
    'a1d8f6310/load/load' => [ 3, { longterm => '0.07', shortterm => 0, midterm => '0.06' } ],
    'w83df6600/disk-sda/disk_octets' => [ 2, { read => 0, write => 0 } ],
);

test_query($s, $_, $queries{$_}) for sort keys %queries;

my @values = $s->listval;
is(scalar @values, 4984, "Correct number of results from LISTVAL");
delete $values[1234]{time};     # won't be constant
is_deeply($values[1234], {
        type_instance => 'nice',
        plugin_instance => 21,
        plugin => 'cpu',
        type => 'cpu',
        host => 'h2gdf6120'
    }, "Correct data returned for select element");

# TODO more test for putval() and the like

sub test_query {
    my ($s, $attr, $results) = @_;
    my ($nresults, $resultdata) = @$results;
    my $r = $s->getval(%{Collectd::Unixsock::_parse_identifier($attr)});
    is(ref $r, 'HASH', "Got a result for $attr");
    is(scalar keys $r, $nresults, "$nresults result result for $attr");
    is_deeply($r, $resultdata, "Data or $attr matches");
}
