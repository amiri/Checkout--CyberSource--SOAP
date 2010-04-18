#!/usr/bin/env perl

use strict;
use warnings;
use Test::More tests => 1;

BEGIN { use_ok( 'Checkout::CyberSource::SOAP' ) || print "Bail out!"; }

diag( "Testing Checkout::CyberSource::SOAP $Checkout::CyberSource::SOAP::VERSION, Perl $], $^X" );

done_testing();
