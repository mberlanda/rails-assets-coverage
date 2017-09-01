#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More tests => 1;

BEGIN {
    use_ok( 'Rails::Assets' ) || print "Bail out!\n";
}

diag( "Testing Rails::Assets $Rails::Assets::VERSION, Perl $], $^X" );
