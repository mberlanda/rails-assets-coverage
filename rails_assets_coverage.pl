#!/usr/bin/perl

use strict;
use warnings;
use 5.014;

my $VERBOSE = $ENV{VERBOSE} // 0;
my $OUTPUT = $ENV{OUTPUT} // 0;

if ($OUTPUT) {
  use lib "$ENV{PWD}/lib";
  use YAML::Dumper;
}

=head1 NAME

Rails Assets Coverage

=head1 SYNOPSYS

The purpose of this script is to find which assets are used by a Rails app.
I tried to not use any dependency in order to make it runnable on every UNIX
machine. This should be intended as a proof of concept for a future ruby gem.

Usage

  $ [VERBOSE=1|OUTPUT=1|] perl assets_coverage.pl [RAILS_ROOT|.]

If you enable VERBOSE option, this would print on the result of the parsing.
If you enable OUTPUT option, this would generate an output.yml report inside
your rails root. Please note that the OUTPUT option requires two packages from
cpanm:

  $ sudo [apt|brew] install cpanminus
  $ sudo cpanm -i YAML::Dumper

In case you don't want to install cpanminus, it would still work for now since
I copied the source of YAML v1.23 under the lib/ subfolder

=head1 SUBROUTINES

=head2 prepare_assets_refs, prepare_extensions_refs
These subroutines return global data structures needed by the script

=head2 process_asset_file, process_template_file, process_scss_file
These anonymous subroutines contains all the operation made on the file list

=cut


my $rails_root = shift // '.';
say "Processing $rails_root..." if $VERBOSE;
chdir $rails_root or die "Channot chdir to $rails_root: $!";

my $template_directories = [qw( app/views/)];
my $template_extensions = [qw(.haml .erb)];
my $assets_directories = [qw( app/assets/ public/ vendor/assets/ )];
my $assets_extensions = {
  fonts => [qw(.woff2 .woff .ttf .eot .otf)],
  images => [qw(.png .jpg .gif .svg .ico)],
  javascripts => [qw(.js)],
  stylesheets => [qw(.css .scss)],
};

my $template_hash = prepare_extensions_refs($assets_extensions);
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
      say "Found unknown type: $ext ($_)" if $VERBOSE;
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
        my @stylesheet_tags = $line =~ /stylesheet_link_tag\s*\(*\s*['"](.+?)['"]\s*\)*/g;
        my @javascript_tags = $line =~ /javascript_include_tag\s*\(*\s*['"](.+)['"]\s*\)*/g;
        my @image_tags = $line =~ /asset_path\s*\(*\s*['"](.+?)['"]\s*\)*/g;

        push @{$template_hash->{stylesheets}}, $_ foreach (map {format_template_elem($file_name, $_)} @stylesheet_tags);
        push @{$template_hash->{javascripts}}, $_ foreach (map {format_template_elem($file_name, $_)} @javascript_tags);
        push @{$template_hash->{images}}, $_ foreach (map {format_template_elem($file_name, $_)} @image_tags);
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

sub prepare_extensions_refs {
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
    full_path => $asset_file,
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

sub format_scss_elem {
  my ($asset_name, $ext, $referral) = @_;
  return {
    name => $asset_name,
    referral => $referral,
    ext => $ext,
  };
}

# ----

$process_template_file->($_) foreach @{find_files($template_directories)};
$process_asset_file->($_) foreach @{find_files($assets_directories)};


my $scss_hash = prepare_extensions_refs($assets_extensions);
my $scss_files = [grep { $_->{ext} eq '.scss' } @{$assets_hash->{stylesheets}}];

my $process_scss_file = sub {
  my $file_name = $_;
  if (-f $file_name) {
    open FILE, $_;
    while (my $line=<FILE>){
      my @assets_tags = $line =~ /asset\-url\s*\(*\s*['"](.+?)['"]\s*\)*/g;
      foreach my $asset (@assets_tags){
        my $clean_name = $asset;
        $clean_name =~ s/([\?#].*)//;
        my ($ext) =  $clean_name =~ /(\.[a-zA-Z0-9]+)$/;
        my $type = $reversed_ext->{$ext} || 'unknown';
        if ($type ne 'unknown'){
          my $elem = format_scss_elem($clean_name, $ext, $file_name);
          push @{$scss_hash->{$type}}, $elem;
        } else {
          say "Found unknown type: $ext ($_)" if $VERBOSE;
        }
      };
    }
  }
};

$process_scss_file->($_) foreach map {$_->{full_path}} @{$scss_files};

if ($VERBOSE) {
  foreach my $key (sort keys %$assets_hash) {
    say "My $key files are: " . scalar @{$assets_hash->{$key}};
    foreach (sort { "\L$a->{name}" cmp "\L$b->{name}" } @{$assets_hash->{$key}}){
      say "- $_->{name} ($_->{full_path})";
    };
    say "My $key references are:" . scalar @{$template_hash->{$key}};
    foreach (sort { "\L$a->{name}" cmp "\L$b->{name}" } @{$template_hash->{$key}}){
      say "- $_->{name} ($_->{full_path})";
    };
    say "My $key .scss references are:" . scalar @{$scss_hash->{$key}};
    foreach (sort { "\L$a->{name}" cmp "\L$b->{name}" } @{$scss_hash->{$key}}){
      say "- $_->{name} ($_->{referral})";
    };
  }
}

my $output = prepare_extensions_refs($assets_extensions);;

foreach my $key (sort keys %$assets_hash) {
  foreach my $elem (sort { "\L$a->{name}" cmp "\L$b->{name}" } @{$assets_hash->{$key}}){
    $elem->{referrals} = [()];
    push  @{$elem->{referrals}}, $_->{full_path} foreach (
      grep {
        my $check = $_->{name};
        $check =~ s/#\{.*\}/\.\*/;
        $elem->{name} =~ m/$check/;
      } @{$template_hash->{$key}}
    );
    push  @{$elem->{referrals}}, $_->{referral} foreach (grep { $elem->{name} =~ $_->{name} } @{$scss_hash->{$key}});
    $elem->{refs_count} = scalar @{$elem->{referrals}};
    push @{$output->{$key}}, $elem;
  };
}

if ($OUTPUT){
  my $dumper = YAML::Dumper->new();
  open OUT, '>output.yml';
  print OUT $dumper->dump($output);
  close OUT;
}
