#!/usr/bin/perl
use lib '.';
use Poker;
use Data::Dumper;
use strict;

my $poker = Poker->new();
# my @cards = Poker->_drow_cards;
my $name = $poker->show_hand_name;
my $kicker = $poker->calc_kicker_number;
warn Dumper $poker,$name,$kicker;