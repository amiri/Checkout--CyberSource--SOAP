#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 1;

BEGIN {
    use_ok( 'CyberSource::SOAP::Checkout' ) || print "Bail out!
";
}

diag( "Testing CyberSource::SOAP::Checkout $CyberSource::SOAP::Checkout::VERSION, Perl $], $^X" );
