#!/usr/bin/perl
use Yaku;

use strict;
use warnings;
use Test::More qw(no_plan);


my @test_case = (
    {
        name   => $Yaku::YAKU_CONFIG{royal_straight_flush}->{yaku_name},
        ar_ref => [0,1,2,3,4,5,6,7,15,8,9,10,11,12],
    },
    {
        name   => $Yaku::YAKU_CONFIG{straight_flush}->{yaku_name},
        ar_ref => [8,9,10,11,12],
    },
    {
        name   => $Yaku::YAKU_CONFIG{four_of_a_kind}->{yaku_name},
        ar_ref => [0,13,26,39,4,7],
    },
    {
        name   => $Yaku::YAKU_CONFIG{full_house}->{yaku_name},
        ar_ref => [0,13,26,1,14,17],
    },
    {
        name   => $Yaku::YAKU_CONFIG{flush}->{yaku_name},
        ar_ref => [0,1,2,3,5],
    },
    {
        name   => $Yaku::YAKU_CONFIG{straight}->{yaku_name},
        ar_ref => [0,1,2,4,16],
    },
    {
        name   => $Yaku::YAKU_CONFIG{three_of_a_kind}->{yaku_name},
        ar_ref => [0,14,27,40,4,7],
    },
    {
        name   => $Yaku::YAKU_CONFIG{two_pair}->{yaku_name},
        ar_ref => [0,13,27,40,4,7],
    },
    {
        name   => $Yaku::YAKU_CONFIG{one_pair}->{yaku_name},
        ar_ref => [0,14,27,5,4,7],
    },
    {
        name   => $Yaku::YAKU_CONFIG{high_card}->{yaku_name},
        ar_ref => [0,1,2,4,19],
    },
);

# 役が正常に判定できているかテスト
sub test1 {
    foreach my $hash_ref ( @test_case ){
        my $hoge = Yaku->new(+{
            cards => $hash_ref->{ar_ref},
        });
        my $expect = $hash_ref->{name};
        my $result = $hoge->get_hand_name();
        $hoge->output();
        is( $expect,$result,$expect );
    }
}



my @test_case2 = (
    {
        ar_ref  => [9,10,11,12,0], # ロイヤルストレート・フラッシュ
        ar_ref2 => [0,1,2,3,4],      # ストレート・フラッシュ
    },
    {
        ar_ref  => [8,9,10,11,12], # ストレート
        ar_ref2 => [0,1,2,3,4], # ストレート（最弱）
    },
);

# 強さが正常に判定できているかテスト
sub test2 {
    foreach my $hash_ref ( @test_case2 ){
        my $a = Yaku->new(+{
            cards => $hash_ref->{ar_ref},
        });
        my $b = Yaku->new(+{
            cards => $hash_ref->{ar_ref2},
        });
        ok (
            $a->get_hand_strength() > $b->get_hand_strength(),
            Common::conv_cards2str($hash_ref->{ar_ref}) . " > " . Common::conv_cards2str($hash_ref->{ar_ref2})
        );
    }
}



test1(); # 役判定のテスト
test2(); # 強さ判定のテスト



