#!/usr/bin/perl

use strict;
use warnings;
use 5.014;
use experimental qw(smartmatch switch);

=head1 NAME

Rails Assets Coverage

=head1 SYNOPSYS

The purpose of this script is to find which assets are used by a Rails app.
I tried to not use any dependency in order to make it runnable on every UNIX
machine. This should be intended as a proof of concept for a future ruby gem.

Usage

  perl assets_coverage.pl [RAILS_ROOT|.]

=head1 SUBROUTINES

=head2 prepare_assets_refs
This returns all the global data structures needed by the script

=head2 process_asset_file
This anonymous subroutine contains all the operation made on asset files

=head2 process_template_file
This anonymous subroutine contains all the operation made on template files

=cut

my $rails_root = shift // '.';
say "Processing $rails_root...";
chdir $rails_root or die "Channot chdir to $rails_root: $!";

my $template_directories = [qw( app/views/)];
my $template_extensions = [qw(.haml .erb)];
my $assets_directories = [qw( app/assets/ public/ vendor/assets/ )];
my $assets_extensions = {
  fonts => [qw(.woff2 .woff .ttf .eot)],
  images => [qw(.png .jpg .gif .svg .ico)],
  javascripts => [qw(.js)],
  stylesheets => [qw(.css .scss)],
};

my $template_hash = prepare_template_refs($assets_extensions);
my ($assets_hash, $assets_paths, $reversed_ext) =
   prepare_assets_refs($assets_directories, $assets_extensions);

my $process_asset_file = sub {
  if (-f $_) {
    my ($ext) =  $_ =~ /(\.[a-zA-Z0-9]+)$/;
    my $type = $reversed_ext->{$ext} || 'unknown';

    if ($type ne 'unknown'){
      my $elem = format_asset_elem($_, $ext, $assets_paths);
      push @{$assets_hash->{$type}}, $elem;
    } else {
      say "Found unknown type: $ext ($_)";
    }
  }
};

my $process_template_file = sub {
  if (-f $_) {
    my $file_name = $_;
    my ($ext) =  $file_name =~ /(\.[a-zA-Z0-9]+)$/;
    if (grep /$ext/, @$template_extensions){

      open FILE, $_;
      while (my $line=<FILE>){
        given($line){
          when(/stylesheet_link_tag\s*\(*\s*['"](.+?)['"]\s*\)*/){
            my $elem = format_template_elem($file_name, $1);
            push @{$template_hash->{stylesheets}}, $elem;
          }
          when(/javascript_include_tag\s*\(*\s*['"](.+)['"]\s*\)*/){
            my $elem = format_template_elem($file_name, $1);
            push @{$template_hash->{javascripts}}, $elem;
          }
          when(/asset_path\s*\(*\s*['"](.+?)['"]\s*\)*/){
            my $elem = format_template_elem($file_name, $1);
            push @{$template_hash->{images}}, $elem;
          }
        }
      }
    }
  }
};

sub find_files {
  my $dirs = shift;
  my $find_cmd = "find " . join(" ", @$dirs);
  return [ split /\n/, `$find_cmd` ];
}

sub prepare_assets_refs {
  my ($dirs, $extensions) = @_;
  my @extensions_keys = sort keys %$extensions;
  my ($assets, $assets_path, $reversed_ext);
  $assets->{$_} = [()] foreach (@extensions_keys);
  foreach my $d (@$dirs){
    unless ($d =~ /public/) {
      push @$assets_path, "$d$_/" foreach (qw(fonts javascripts stylesheets));
    }
    push @$assets_path, $d;
  }
  foreach my $key (@extensions_keys){
    $reversed_ext->{$_} = $key foreach (@{$extensions->{$key}});
  }
  return ($assets, $assets_path, $reversed_ext);
}

sub prepare_template_refs {
  my ($extensions) = @_;
  my @extensions_keys = sort keys %$extensions;
  my ($assets);
  $assets->{$_} = [()] foreach (@extensions_keys);
  return $assets;
}

sub format_asset_elem {
  my ($asset_file, $ext, $assets_paths) = @_;
  my $asset_name = $asset_file;
  $asset_name =~ s/$_// foreach (@$assets_paths);
  return {
    name => $asset_name,
    full_path => $_,
    ext => $ext,
  };
}

sub format_template_elem {
  my ($template_file, $asset_name) = @_;
  return {
    name => $asset_name,
    full_path => $template_file,
  }
}

$process_template_file->($_) foreach @{find_files($template_directories)};
$process_asset_file->($_) foreach @{find_files($assets_directories)};

foreach my $key (sort keys %$assets_hash) {
  say "My $key files are: " . scalar @{$assets_hash->{$key}};
  foreach (sort { "\L$a->{name}" cmp "\L$b->{name}" } @{$assets_hash->{$key}}){
    say "- $_->{name} ($_->{full_path})";
  };
  say "My $key references are:" . scalar @{$template_hash->{$key}};
  foreach (sort { "\L$a->{name}" cmp "\L$b->{name}" } @{$template_hash->{$key}}){
    say "- $_->{name} ($_->{full_path})";
  };
}
