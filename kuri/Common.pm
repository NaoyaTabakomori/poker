package Common;

use strict;
use Readonly;
use Data::Dumper;

#use Test::Simple tests => 1;

=pod
 - 仕様 -

    ※トランプの数値(rank)は、実際の数字-1である 0-12で表す
        'A' => 0,
        '2' => 1,
        'K' => 12

    ※スートをあらわす文字は、暫定で SHDC を使用した
        S (スペード)，
        H (ハート),
        D (ダイヤ)，
        C (クラブ)
=cut


# トランプの文字列マッピング（SHDCは仕様に合わせて変更する）
Readonly my $CARD_NUMBER_STR => 'A23456789TJQK'; # [0-12] => ['A'-'K']
Readonly my $CARD_SUIT_STR   => 'SHDC';          # [0-3]  => [SHDC],  S=>スペード H=>ハート D=>ダイヤ C=>クラブ
Readonly my @CARD_NUMBER_AR     => split(//, $CARD_NUMBER_STR);
Readonly my @CARD_SUIT_AR       => split(//, $CARD_SUIT_STR);


# スートIDを取得 ( 引数:カードID 返り値:スートID )
sub get_suit_id {
    my $id = shift;
    return int( $id/13 )&3;
}

# スートを文字として取得 ( 引数:カードID 返り値:スート文字 )
sub get_suit_str {
    my $id = shift;
    return $CARD_SUIT_AR[ get_suit_id($id) ];
}

# ランクIDを取得
sub get_rank_id {
    my $id = shift;
    return int($id)%13;
}

# 役の強さを比べるときに使う（get_rank_idとの違いは、Aを0ではなく、13として扱うところのみ）
sub get_rank_id2 {
    my $id = shift;
    my $val = get_rank_id( $id );
    return $val==0 ? 13:$val;
}

# ランクを文字として取得
sub get_rank_str {
    my $id = shift;
    return $CARD_NUMBER_AR[ get_rank_id($id) ];
}

# カードID => トランプの文字列
sub conv_id2str {
    my $id = shift;
    return get_suit_str( $id ) . get_rank_str( $id );
}

# トランプの文字列 => カードID
sub conv_str2id {
    my $str = shift;
    my $idx_suit = index( $CARD_SUIT_STR,   substr($str,0,1) );
    my $idx_num  = index( $CARD_NUMBER_STR, substr($str,1,1) );
    if( $idx_suit<0 || $idx_num<0 ){
        print "Error $str\n";
        exit;
    }
    return 13*$idx_suit + $idx_num;
}

# 出力
sub output {
    my $ar_ref = shift;
    print conv_cards2str( $ar_ref ) . "\n";
}

# カード配列のリファレンスを受け取り、文字列として返す
sub conv_cards2str{
    my $ar_ref = shift;
    my $str = "( ";
    foreach my $id( @{$ar_ref} ) {
        $str .= conv_id2str( $id ) . " ";
    }
    return $str . ")";
}

# 並び替え用の比較関数(数字順,スート順に並び替える。強さ順ではない点に注意)
sub comp {
    my ($a,$b) = @_;

    if( get_rank_id($a) == get_rank_id($b) ){
        return get_suit_id( $a ) > get_suit_id ( $b ) ? 1 : -1;
    }
    return get_rank_id( $a ) > get_rank_id ( $b ) ? 1 : -1;
}

# ID<=>文字列の相互変換テスト
sub test {
    for( my $i=0;$i<52;++$i ){
        my $str = conv_id2str( $i );
        my $id = conv_str2id( $str );
        print "$i $str $id\n";
    }
}



1;
