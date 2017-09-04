#!perl -T

use strict;
use warnings;
use Test::More tests => 15;
use Test::Deep;
use File::Basename qw(dirname);
use File::Spec::Functions qw(catdir);

BEGIN {
  use_ok( 'Rails::Assets' ) || BAIL_OUT();
}
diag( "Testing Rails::Assets $Rails::Assets::VERSION, Perl $], $^X" );

# Test some class constants in Rails::Assets.pm
is( ref($Rails::Assets::TEMPLATE_DIR), 'ARRAY', 'class constant TEMPLATE_DIR is an ARRAY');
is( ref($Rails::Assets::TEMPLATE_EXT), 'ARRAY', 'class constant TEMPLATE_EXT is an ARRAY');
is( ref($Rails::Assets::ASSETS_DIR), 'ARRAY', 'class constant ASSETS_DIR is an ARRAY');
is( ref($Rails::Assets::ASSETS_EXT), 'HASH', 'class constant ASSETS_EXT is an HASH');

# Test default for class constants and initializer
my $template_directories = [qw( app/views/)];
my $template_extensions = [qw(.haml .erb)];
my $assets_directories = [qw( app/assets/ public/ vendor/assets/ )];
my $assets_extensions = {
  fonts => [qw(.woff2 .woff .ttf .eot .otf)],
  images => [qw(.png .jpg .gif .svg .ico)],
  javascripts => [qw(.js .map)],
  stylesheets => [qw(.css .scss)],
};

is_deeply( $Rails::Assets::TEMPLATE_DIR, $template_directories, 'TEMPLATE_DIR has the expected default');
is_deeply( $Rails::Assets::TEMPLATE_EXT, $template_extensions, 'TEMPLATE_EXT has the expected default');
is_deeply( $Rails::Assets::ASSETS_DIR, $assets_directories, 'ASSETS_DIR has the expected default');
is_deeply( $Rails::Assets::ASSETS_EXT, $assets_extensions, 'ASSETS_EXT has the expected default');

my $assets = Rails::Assets->new();
is_deeply( $assets->template_dir(), $template_directories, 'template_dir() has the expected default');
is_deeply( $assets->template_ext(), $template_extensions, 'template_ext() has the expected default');
is_deeply( $assets->assets_dir(), $assets_directories, 'assets_dir() has the expected default');
is_deeply( $assets->assets_ext(), $assets_extensions, 'assets_ext() has the expected default');

{
  push @{$assets->template_dir}, 'app/';
  is_deeply($assets->template_dir, [qw(app/views/ app/)], 'Can push elements into template_dir reference');
  is_deeply($Rails::Assets::TEMPLATE_DIR, $template_directories, 'Pushing elements into instance reference does not affect constants');
}

