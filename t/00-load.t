#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Catalyst::Model::CyberSource' ) || print "Bail out!
";
}

diag( "Testing Catalyst::Model::CyberSource $Catalyst::Model::CyberSource::VERSION, Perl $], $^X" );
