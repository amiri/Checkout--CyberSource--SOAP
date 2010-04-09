#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Moose;
use Data::Dumper;

BEGIN { use_ok 'Catalyst::Model::CyberSource' }
BEGIN { use_ok 'Catalyst::Model::CyberSource::Response' }

my $cy = Catalyst::Model::CyberSource->new( id => $ENV{CYBS_ID}, key => $ENV{CYBS_KEY});
my $cy2 = Catalyst::Model::CyberSource::Response->new;

meta_ok($cy, 'C::M::CyberSource is a Moose object');

my @methods = qw/agent response test_server prod_server cybs_version wsse_prefix wsse_nsuri refcode password_text process/;

my @methods2 = qw/handler respond payment_info error successful FAULT DEFAULT EMPTY/;

can_ok($cy, @methods);
can_ok($cy2, @methods2);

like( $cy2->handler->{101}->(), qr/omitted necessary/, 'Spot check: C::M::C::Response->handler handler coderefs return correct stuff');
like( $cy2->handler->{100}->(), qr/Success/, 'Spot check: C::M::C::Response->handler coderefs return correct stuff');

my $data = {
    'expiry.month'=> '09',
    'expiry.year' => '2010',
    address1      => '15 Top Drive #12',
    amount        => '500',
    cardnumber    => '4111-1111-1111-1111',
    city          => 'Los Angeles',
    country       => 'USA',
    currency      => 'USD',
    document      => '12',
    email         => 'amiri@metalabel.com',
    firstname     => 'Amiri',
    ip            => '192.168.100.2',
    lastname      => 'Barksdale',
    quantity      => '1',
    state           => 'CA',
    zip           => '90064',
};

ok($cy->process($data), 'C::M::CyberSource can process my correct data');
is($cy->response->success->{message}, 'Successful transaction', 'Success message is correct');
ok(!$cy->response->{error}, 'No error exists');

##################### INCORRECT DATA

my $cy3 = Catalyst::Model::CyberSource->new;
my $data2 = {
    address1      => '48 Blueberry Hill #2',
    amount        => '500',
    cardnumber    => '4111111111111111',
    city          => 'Los Angeles',
    currency      => 'USD',
    document      => '12',
    'expiry.month'=> '09',
    'expiry.year' => '2010',
    firstname     => 'Amiri',
    lastname      => 'Barksdale',
    zip           => '90016',
    country       => 'USA',
    email         => 'amiri@metalabel.com',
    quantity      => '1',
    #state           => 'CA',
    ip            => '192.168.100.2'
};

ok($cy3->process($data2), 'C::M::CyberSource can process my incorrect data (state missing)');
like($cy3->response->error->{message}, qr/Your purchase failed for an unknown reason/, 'Error message is correct');
ok(!$cy3->response->{success}, 'No success message exists');

is($cy->response->payment_info->{expmonth}, '09', 'Correct data is in the returned payment_info hash');

done_testing();
