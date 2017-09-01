#!perl -T

use strict;
use warnings;
use Test::More tests => 10;
use Test::Deep;

BEGIN {
  use_ok( 'Rails::Assets' ) || BAIL_OUT();
}
diag( "Testing Rails::Assets $Rails::Assets::VERSION, Perl $], $^X" );

# they have to be defined in Rails::Assets.pm
ok( defined &Rails::Assets::format_extensions_list, 'format_extensions_list() is defined' );
ok( defined &prepare_extensions_refs, 'prepare_extensions_refs() is defined' );

my $assets_extensions = {
  fonts => [qw(.ttf)],
  images => [qw(.png)],
  javascripts => [qw(.js)],
  stylesheets => [qw(.css)],
};
my $assets_directories = [qw( app/assets/ public/)];

{
  my $assets_ext = [qw(fonts images javascripts stylesheets)];
  is_deeply(
    Rails::Assets::format_extensions_list($assets_extensions),
    $assets_ext, 'format_extensions_list() works with an HASH reference'
  );
  is_deeply(
    Rails::Assets::format_extensions_list($assets_ext),
    $assets_ext, 'format_extensions_list() works with an ARRAY reference'
  );

  my $invalid_ref = sub { return 1 };
  eval { Rails::Assets::format_extensions_list($invalid_ref) } or my $at = $@;
  like(
    $at, qr/Invalid extension argument provided/,
    'format_extensions_list() dies with a message when invalid reference provided'
  );
}

{
  my $expected_assets = {
    fonts => [()], images => [()],
    javascripts => [()], stylesheets => [()],
  };
  my $expected_paths = [
    qw(app/assets/fonts/ app/assets/javascripts/ app/assets/stylesheets/ app/assets/ public/)
  ];

  my $expected_reversed_ext = {
    '.ttf' => 'fonts', '.png' => 'images', '.js' => 'javascripts', '.css' => 'stylesheets'
  };

  is_deeply(
    prepare_extensions_refs($assets_extensions),
    $expected_assets, 'prepare_extensions_refs() subroutine works as expected'
  );

  my ($actual_assets, $actual_paths, $actual_eversed_ext) =
      prepare_assets_refs($assets_directories, $assets_extensions);

  print join("\t", (sort @{$actual_paths})) . "\n";
  print join("\t", (sort @{$expected_paths})) . "\n";

  is_deeply($actual_assets, $expected_assets, 'prepare_assets_refs() returns expected assets');
  is_deeply($actual_paths, $expected_paths, 'prepare_assets_refs() returns expected paths');
  is_deeply($actual_eversed_ext, $expected_reversed_ext, 'prepare_assets_refs() returns expected reversed ext');
}
