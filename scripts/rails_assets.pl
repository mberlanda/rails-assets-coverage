#!/usr/bin/perl

use strict;
use warnings;
use 5.014;

my $VERBOSE = $ENV{VERBOSE} // 0;
my $OUTPUT = $ENV{OUTPUT} // 0;

use Rails::Assets;
use Rails::Assets::Base;

if ($OUTPUT) {
  use YAML::Dumper;
}

my $rails_root = shift // '.';
say "Processing $rails_root..." if $VERBOSE;
chdir $rails_root or die "Channot chdir to $rails_root: $!";

my $assets = Rails::Assets->new();
$assets->analyse();

if ($VERBOSE) {
  foreach my $key (sort keys %{$assets->assets_hash()}) {
    say "My $key files are: " . scalar @{$assets->assets_hash()->{$key}};
    foreach (sort { "\L$a->{name}" cmp "\L$b->{name}" } @{$assets->assets_hash()->{$key}}){
      say "- $_->{name} ($_->{full_path})";
    };
    say "My $key references are:" . scalar @{$assets->template_hash()->{$key}};
    foreach (sort { "\L$a->{name}" cmp "\L$b->{name}" } @{$assets->template_hash()->{$key}}){
      say "- $_->{name} ($_->{full_path})";
    };
    say "My $key .scss references are:" . scalar @{$assets->scss_hash()->{$key}};
    foreach (sort { "\L$a->{name}" cmp "\L$b->{name}" } @{$assets->scss_hash()->{$key}}){
      say "- $_->{name} ($_->{referral})";
    };
    say "My $key .js references are:" . scalar @{$assets->map_hash()->{$key}};
    foreach (sort { "\L$a->{name}" cmp "\L$b->{name}" } @{$assets->map_hash()->{$key}}){
      say "- $_->{name} ($_->{referral})";
    };
  }
}

my $output = prepare_extensions_refs($assets->assets_ext());
foreach my $key (sort keys %{$assets->assets_hash()}) {
  foreach my $elem (sort { "\L$a->{name}" cmp "\L$b->{name}" } @{$assets->assets_hash()->{$key}}){
    $elem->{referrals} = [()];
    push  @{$elem->{referrals}}, $_->{full_path} foreach (
      grep {
        my $check = $_->{name};
        $check =~ s/#\{.*\}/\.\*/;
        $elem->{name} =~ m/$check/;
      } @{$assets->template_hash()->{$key}}
    );
    push  @{$elem->{referrals}}, $_->{referral} foreach (grep { $elem->{name} =~ $_->{name} } @{$assets->scss_hash()->{$key}});
    $elem->{refs_count} = scalar @{$elem->{referrals}};
    push @{$output->{$key}}, $elem;
  };
}

my $assets_status = {
  used => [()],
  unused => [()],
  broken_references => [()],
};

foreach my $key (sort keys %{$assets->assets_hash()}) {
  push @{$assets_status->{used}}, $_ foreach (grep { $_->{refs_count} > 0 } @{$assets->assets_hash()->{$key}});
  push @{$assets_status->{unused}}, $_ foreach (grep { $_->{refs_count} == 0 } @{$assets->assets_hash()->{$key}});
}

if ($OUTPUT){
  my $dumper = YAML::Dumper->new();
  open OUT, '>assets_status.yml';
  print OUT $dumper->dump($assets_status);
  close OUT;
}
