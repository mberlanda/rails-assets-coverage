#!/usr/bin/perl

use strict;
use warnings;
use 5.014;

my $VERBOSE = $ENV{VERBOSE} // 0;
my $OUTPUT = $ENV{OUTPUT} // 0;

use Rails::Assets;
use Rails::Assets::Formatter;

if ($OUTPUT) {
  use YAML::Dumper;
}

my $rails_root = shift // '.';
say "Processing $rails_root..." if $VERBOSE;
chdir $rails_root or die "Channot chdir to $rails_root: $!";

my $template_directories = [qw( app/views/)];
my $template_extensions = [qw(.haml .erb)];
my $assets_directories = [qw( app/assets/ public/ vendor/assets/ )];
my $assets_extensions = {
  fonts => [qw(.woff2 .woff .ttf .eot .otf)],
  images => [qw(.png .jpg .gif .svg .ico)],
  javascripts => [qw(.js .map)],
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
          my $elem = format_referral_elem($clean_name, $ext, $file_name);
          push @{$scss_hash->{$type}}, $elem;
        } else {
          say "Found unknown type: $ext ($_)" if $VERBOSE;
        }
      };
    }
  }
};
$process_scss_file->($_) foreach map {$_->{full_path}} @{$scss_files};

my $map_hash = prepare_extensions_refs($assets_extensions);
my $js_files = [grep { $_->{ext} eq '.js' } @{$assets_hash->{javascripts}}];

my $process_map_file = sub {
  my $file_name = $_;
  if (-f $file_name) {
    open FILE, $_;
    while (my $line=<FILE>){
      my @assets_tags = $line =~ /sourceMappingURL=(.+\.map)/;
      foreach my $asset (@assets_tags){
        my $clean_name = $asset;
        $clean_name =~ s/([\?#].*)//;
        my ($ext) =  $clean_name =~ /(\.[a-zA-Z0-9]+)$/;
        my $type = $reversed_ext->{$ext} || 'unknown';
        if ($type ne 'unknown'){
          my $elem = format_referral_elem($clean_name, $ext, $file_name);
          push @{$map_hash->{$type}}, $elem;
        } else {
          say "Found unknown type: $ext ($_)" if $VERBOSE;
        }
      };
    }
  }
};
$process_map_file->($_) foreach map {$_->{full_path}} @{$js_files};

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
    say "My $key .js references are:" . scalar @{$map_hash->{$key}};
    foreach (sort { "\L$a->{name}" cmp "\L$b->{name}" } @{$map_hash->{$key}}){
      say "- $_->{name} ($_->{referral})";
    };
  }
}

my $output = prepare_extensions_refs($assets_extensions);
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

my $assets_status = {
  used => [()],
  unused => [()],
  broken_references => [()],
};

foreach my $key (sort keys %$assets_hash) {
  push @{$assets_status->{used}}, $_ foreach (grep { $_->{refs_count} > 0 } @{$assets_hash->{$key}});
  push @{$assets_status->{unused}}, $_ foreach (grep { $_->{refs_count} == 0 } @{$assets_hash->{$key}});
}

if ($OUTPUT){
  my $dumper = YAML::Dumper->new();
  open OUT, '>assets_status.yml';
  print OUT $dumper->dump($assets_status);
  close OUT;
}
