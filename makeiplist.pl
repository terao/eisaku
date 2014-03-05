#!/usr/bin/perl

use v5.10;
use strict;
use warnings;
use Socket;

our $verbose = 0; # 0:off 1:on

sub increment_addr {
  my $addr = shift;
  my $inc = shift // 1;
  inet_ntoa(pack "N", ((unpack "N", inet_aton($addr)) + $inc));
}

foreach my $n (@ARGV) {
  my($start_addr, $nbits) = split "/", $n;
  $nbits ||= 32;
  my $end_addr = increment_addr($start_addr, 2**(32 - $nbits) - 1);
  my $next_addr = increment_addr($end_addr);

#  say "# $n -> $start_addr-$end_addr" if $verbose > 0;
  for(my $addr = $start_addr;
      $addr ne $next_addr;
      $addr = increment_addr($addr)) {
#    say $addr;
#    print "$addr\n";
    print " $addr";
  }
}



