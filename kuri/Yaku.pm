package Yaku;
use strict;
use Data::Dumper;
use Readonly;
use base qw/Class::Accessor::Fast/;
use Common;
__PACKAGE__->mk_accessors(qw/ cards /);


# ここは触らない
Readonly my $YAKU_BIT_SHIFT_CNT => 24;
Readonly my $YAKU_BIT_MASK      => ~((1<<24)-1);

# 役の設定
Readonly our %YAKU_CONFIG => (
    royal_straight_flush => {
        yaku_name  => "ロイヤルストレート・フラッシュ",
        yaku_id    => 10,
    },
    straight_flush => {
        yaku_name  => "ストレート・フラッシュ",
        yaku_id    => 9,
    },
    four_of_a_kind => {
        yaku_name  => "フォーカード",
        yaku_id    => 8,
    },
    full_house => {
        yaku_name  => "フルハウス",
        yaku_id    => 7,
    },
    flush=> {
        yaku_name  => "フラッシュ",
        yaku_id    => 6,
    },
    straight => {
        yaku_name  => "ストレート",
        yaku_id    => 5,
    },
    three_of_a_kind => {
        yaku_name  => "スリーカード",
        yaku_id    => 4,
    },
    two_pair => {
        yaku_name  => "ツーペア",
        yaku_id    => 3,
    },
    one_pair => {
        yaku_name  => "ワンペア",
        yaku_id    => 2,
    },
    high_card => {
        yaku_name  => "ハイカード",
        yaku_id    => 1,
    },
);


# コンストラクタ
sub new {
    my ($class,$args) = @_;

    # カードの構成を解析
    my ($cards_ref,$suit_ref,$rank_ref) = $class->_analyze($args->{cards});

    # 解析結果をプライペートのメンバ変数として登録
    return $class->SUPER::new(+{
        _cards_ref    => $cards_ref, # 全てのカード（入力）
        _suit_ref     => $suit_ref,  # スートごとにカードID配列を保持
        _rank_ref     => $rank_ref,  # 数字に対応する、カード枚数   (ex:A=>3枚 J=>1枚 Q=>1枚)

        _hands_ref     => undef,     # 役を構成するカードの配列リファレンス
        _hand_strength => 0,         # 役の強さ（数字）
    });
}


# 手役を取得
sub get_hand_name {
    my ($self) = shift;

    # 手役探索済みでなければ、判定する
    $self->_judge() unless( $self->_is_already_judege() );

    # 該当する役を探し、出力
    foreach my $hash_ref( values(%YAKU_CONFIG) ){
        if( $self->_get_hand_id() == $hash_ref->{yaku_id} ){
            return $hash_ref->{yaku_name};
        }
    }
    print 'もしかして・・・[バグ]\n';
}

# 手の強さを返す
sub get_hand_strength {
    my ($self) = shift;

    # 手役探索済みでなければ、判定する
    $self->_judge() unless( $self->_is_already_judege() );

    return $self->{_hand_strength};
}


# 出力
sub output {
    my ($self) = shift;
    print "\n----------------------------------\n";
    print "手役：" . $self->get_hand_name() . "\n";
    print "hands:" ; Common::output($self->{_hands_ref});
    print "input:" ; Common::output($self->{_cards_ref});
    printf ("strength: %x\n",$self->{_hand_strength});
}



#------------------#
# Private Function #
#------------------#

# すでに探索したかどうか？
sub _is_already_judege {
    my ($self) = shift;
    return $self->{_hand_strength} != 0;
}

# 役の判定
sub _judge {
    my ($self) = @_;

    # ストレート・フラッシュ
    return if( $self->_check_straight_flush() );

    # フォーカード
    return if( $self->_check_four_of_a_kind() );

    # フルハウス
    return if( $self->_check_full_house() );

    # フラッシュ
    return if( $self->_check_flush() );

    # ストレート
    return if( $self->_check_straight() );

    # スリーカード
    return if( $self->_check_three_of_a_kind() );

    # ツーペア
    return if( $self->_check_two_pair() );

    # ワンペア
    return if( $self->_check_one_pair() );

    # ハイカード
    $self->_check_high_card();
}



# カード情報を解析し、ハンド判定の準備をする
sub _analyze {
    my ($self,$cards_ref) = @_;

    # カードをソート
    my @cards = sort{ Common::comp($a,$b) } @{$cards_ref};

    # スートごとに分ける(すでに全てのカードはソート済みのため、スートごとに分けた時もカードはソートされて状態である)
    my @cards_group_by_suit = (
        [ grep{ Common::get_suit_id($_)==0 }@cards ],
        [ grep{ Common::get_suit_id($_)==1 }@cards ],
        [ grep{ Common::get_suit_id($_)==2 }@cards ],
        [ grep{ Common::get_suit_id($_)==3 }@cards ],
    );

    # 数字ごとの枚数 (ストレート判定用に14個用意してある)
    my @card_num_group_by_rank = (0) x 14;
    foreach my $card_id(@cards){
        $card_num_group_by_rank[ Common::get_rank_id($card_id) ]++;
    }
    $card_num_group_by_rank[13] = $card_num_group_by_rank[0];

    return ( \@cards,\@cards_group_by_suit,\@card_num_group_by_rank );
}


# 役IDをセット
sub _set_hand_id {
    my ($self,$hand_name) = @_;
    $self->{_hand_strength} &= ( (1<<$YAKU_BIT_SHIFT_CNT)-1 );                                # 役IDをリセット
    $self->{_hand_strength} |= ( $YAKU_CONFIG{$hand_name}->{yaku_id} << $YAKU_BIT_SHIFT_CNT ); # 役IDをセット
}

# 役IDをゲット
sub _get_hand_id {
    my ($self) = shift;
    return $self->{_hand_strength} >> $YAKU_BIT_SHIFT_CNT;
}

# 役の強さをセット
sub _set_hand_strength {
    my ( $self,$hands_ref,$straight_flag ) = @_;
    my @hands = @{$hands_ref};
    my $strength = 0;
    for( my $i=0;$i<5;++$i ){

        # ストレートで先頭がAの場合、一番ストレートの中では弱いことになる => get_rank_id
        # ストレート以外なら、AはKよりも強い=> get_rank_id2
        if( $straight_flag&&$i==0 ){
            $strength |= Common::get_rank_id( $hands[$i] ) << (16-4*$i);
        }else{
            $strength |= Common::get_rank_id2( $hands[$i] ) << (16-4*$i);
        }
    }
    $self->{_hand_strength} = $strength;
    $self->{_hands_ref}     = \@hands;
}

# 配列を渡し、ストレートかチェックする
sub _check_straight_from_ar {
    my ($self,$ar_ref) = @_;
    my $bit = 0;
    my $mask = (1<<5)-1;

    # 数字に対応するビットを立てる
    foreach my $card_id( @{$ar_ref} ){
        $bit |=  ( 1<<(Common::get_rank_id($card_id)) );
    }
    $bit |= (1<<13) if( $bit&1 ); # ストレートはTJQKAも許容するので、Aを13でセットする

    for( my $shift_cnt = 9;$shift_cnt>=0;--$shift_cnt ){
        # ストレートなら
        if( ( ($bit>>$shift_cnt) & $mask ) == $mask ){
            my @hands = ();
            for( my $i=0;$i<5;++$i ){
                my $target_rank = ($shift_cnt + $i) % 13; # 対象のカードランク
                foreach my $card_id( @{$ar_ref} ){
                    if( Common::get_rank_id($card_id) == $target_rank ){
                        push( @hands,$card_id );
                        last;
                    }
                }
            }
            $self->_set_hand_strength( \@hands,$shift_cnt==0 );
            return 1;
        }
    }
    return 0;
}


# 枚数のセットを指定し、それに該当するセットがあるかどうかを返す
sub _check_pairs {
    my ($self,$req_pair_ref) = @_;

    my @req_pair = @{$req_pair_ref};      # ペアーのパターンを指定 ( フォーカード…[4,1] フルハウス…[3,2] ツーペア…[2,2,1] ワンペア…[2,1,1,1] )
    my @ranks    = @{$self->{_rank_ref}}; # 数字に対応するカードの枚数
    my @hands    = ();                    # 手役の構成

    foreach my $target_cnt(@req_pair){
        my $found = 0;
        # AはKよりも強いので、IDを13として扱う
        for( my $i=13;$i>=1;--$i ){
            if( $ranks[$i] >= $target_cnt ){
                $ranks[$i] = 0;   # 一度使ったカードは使えなくする
                $found = 1;       # 見つけたフラグを立てる

                my $cnt = 0;      # 指定した個数が見つかれば、探索を打ち切るので、個数を数える必要がある
                push( @hands,
                    grep{ ($i%13)==Common::get_rank_id($_) && $cnt++<$target_cnt } @{$self->{_cards_ref}}
                );
                last;
            }
        }
        # ペアが見つからなかったら、終了
        return 0 unless ( $found );
    }
    # 手役の構成
    $self->_set_hand_strength( \@hands );
    return 1;
}

# ハイカード
sub _check_high_card_from_ar {
    my ( $self,$ar_ref ) = @_;

    # 強い順に並び替える
    my @ar = sort{Common::get_rank_id2($b)<=>Common::get_rank_id2($a)}@{$ar_ref};

    # 上位５個を取得
    my $cnt = 0;
    my @hands = grep{ $cnt++<5 } @ar;
    $self->_set_hand_strength( \@hands );
    return 1;
}


# ストレート・フラッシュか？
sub _check_straight_flush {
    my ($self) = shift;

    # スートごとに調べる
    foreach my $ar_ref( @{ $self->{_suit_ref} } ){
        my $cnt = @{$ar_ref}; # スートの枚数

        # もしフラッシュ( 5枚以上 )なら
        if( $cnt >= 5 ){
            # ストレートが複合しているかチェック

            if ( $self->_check_straight_from_ar($ar_ref) ){
                # ロイヤルストレートフラッシュか？
                if( Common::get_rank_id($self->{_hands_ref}->[0]) == 9 ){
                    $self->_set_hand_id('royal_straight_flush');
                }else{
                    $self->_set_hand_id('straight_flush');
                }
                return 1;
            }
        }
    }
    return 0;
}

# フォーカード
sub _check_four_of_a_kind {
    my ($self) = shift;
    if( $self->_check_pairs([4,1]) ){
        $self->_set_hand_id( 'four_of_a_kind' );
        return 1;
    }
    return 0;
}

# フルハウス
sub _check_full_house{
    my ($self) = shift;
    if( $self->_check_pairs([3,2]) ){
        $self->_set_hand_id( 'full_house' );
        return 1;
    }
    return 0;
}

# フラッシュ
sub _check_flush{
    my ($self) = shift;

    # スートごとに調べる
    foreach my $ar_ref( @{ $self->{_suit_ref} } ){
        my $cnt = @{$ar_ref}; # スートの枚数
        # もしフラッシュ( 5枚以上 )なら
        if( $cnt >= 5 ){
            $self->_check_high_card_from_ar( $ar_ref );
            $self->_set_hand_id( 'flush' );
            return 1;
        }
    }
    return 0;
}

# ストレート
sub _check_straight {
    my ($self) = shift;
    if( $self->_check_straight_from_ar( $self->{_cards_ref} ) ){
        $self->_set_hand_id( 'straight' );
        return 1;
    };
    return 0;
}

# スリーカード
sub _check_three_of_a_kind{
    my ($self) = shift;
    if( $self->_check_pairs([3,1,1]) ){
        $self->_set_hand_id( 'three_of_a_kind' );
        return 1;
    }
    return 0;
}

# ツーペア
sub _check_two_pair{
    my ($self) = shift;
    if( $self->_check_pairs([2,2,1]) ){
        $self->_set_hand_id( 'two_pair' );
        return 1;
    }
    return 0;
}

# ワンペア
sub _check_one_pair{
    my ($self) = shift;
    if( $self->_check_pairs([2,1,1,1]) ){
        $self->_set_hand_id( 'one_pair' );
        return 1;
    }
    return 0;
}

# ハイカード
sub _check_high_card {
    my ($self) = shift;
    $self->_check_high_card_from_ar( $self->{_cards_ref} );
    $self->_set_hand_id( 'high_card' );
}




1;
