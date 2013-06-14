package Poker;

use strict;

sub new {
    my $class = shift;
    my @cards = $class->_drow_cards();
    my $args  = +{ cards => \@cards, };
    bless( $args, $class );
}

sub _drow_cards {
    my ($class) = @_;
    my @cards;
    for ( my $i = 0; $i < 5; $i++ ) {
        my $suit = $class->_pic_suit( int( rand 4 ) );
        my $num  = int( rand 13 ) + 1;
        $cards[$i] = $suit . $num;
    }
    if ( $class->_is_duplicate(@cards) == 1 ) {
        @cards = undef;
        @cards = $class->_drow_cards;
    }

    # $cards[0] = 'h10';
    # $cards[1] = 'h1';
    # $cards[2] = 'h11';
    # $cards[3] = 'h13';
    # $cards[4] = 'h12';
    return @cards;
}

sub _pic_suit {
    my ( $class, $num ) = @_;

    if ( $num == 0 ) {
        return 's';
    }
    if ( $num == 1 ) {
        return 'd';
    }
    if ( $num == 2 ) {
        return 'c';
    }
    return 'h';
}

sub _is_duplicate {
    my ( $class, @cards ) = @_;
    my %count;
    my $duplicate_flag = 0;

    @cards = grep { !$count{$_}++ } @cards;
    if ( $#cards < 4 ) {
        $duplicate_flag = 1;
    }
    return $duplicate_flag;
}

#------------instanece-method-----------------

sub show_hand_name {
    my ($self) = @_;
    my $hand = $self->calc_hand_number;

    if ( $hand == 1 ) {
        return 'one pair';
    }
    elsif ( $hand == 2 ) {
        return 'two pair';
    }
    elsif ( $hand == 3 ) {
        return 'three_card';
    }
    elsif ( $hand == 4 ) {
        return 'straight';
    }
    elsif ( $hand == 5 ) {
        return 'flush';
    }
    elsif ( $hand == 6 ) {
        return 'full house';
    }
    elsif ( $hand == 7 ) {
        return 'four card';
    }
    elsif ( $hand == 8 ) {
        return 'straight flush';
    }
    elsif ( $hand == 9 ) {
        return 'royal straight flush';
    }
    return 'pig';
}

sub calc_kicker_number {
    my ($self)    = @_;
    my $class     = ref $self;
    my $cards_ref = $self->{cards};
    my $suits_ref = $self->_split_suits;
    my $nums_ref  = $self->_split_nums;
    my $hand      = $self->calc_hand_number;
    my $kicker    = 0;
    my @sorted_no_pair;

    #並び替え
    my @sorted_nums = sort { $a <=> $b } @$nums_ref;

    #重複カウント
    my %counter;
    foreach my $key (@$nums_ref) {
        $counter{$key} = $counter{$key} + 1;
    }

    if ( $hand == 0 ) {
        $kicker = sprintf( "0%x%x%x%x%x",
            $sorted_nums[4], $sorted_nums[3], $sorted_nums[2],
            $sorted_nums[1], $sorted_nums[0] );
    }

    if ( $hand == 1 ) {
        my $pair = 0;
        my @no_pair;
        my $i = 0;
        my $ace_flag = 0;

        while ( my ( $key, $value ) = each %counter ) {
            if ($value == 2) {
                $pair = $key;
            } else {
                if($key == 1) {
                    $ace_flag = 1;
                }
                $no_pair[$i] = int($key);
            $i++;
            }
        }
        @sorted_no_pair = sort { $a <=> $b } @no_pair;
        if ($ace_flag) {
            $kicker = sprintf( "1%x%x%x00",$pair,$sorted_no_pair[0],$sorted_no_pair[2],$sorted_no_pair[1]);
        }
        else {
            $kicker = sprintf( "1%x%x%x00",$pair,$sorted_no_pair[2],$sorted_no_pair[1],$sorted_no_pair[0]);
        }
    }
    
    #todoそれ以外の時

    return $kicker;
}

sub calc_hand_number {
    my ($self)    = @_;
    my $class     = ref $self;
    my $cards_ref = $self->{cards};
    my $suits_ref = $self->_split_suits;
    my $nums_ref  = $self->_split_nums;

    #役の初期化
    my $hand = 0;

#ワンペア、ツーペア、スリー、フォーカード、フルハウスチェック
    my %counter;
    foreach my $key (@$nums_ref) {
        $counter{$key} = $counter{$key} + 1;
    }
    while ( my ( $key, $value ) = each %counter ) {
        if ( $value == 2 ) {
            if ( $hand == 1 ) {

                #ツーペア
                $hand = 2;
            }
            elsif ( $hand == 2 ) {

                #フルハウス
                $hand = 6;
            }
            else {
                #ワンペア
                $hand = 1;
            }
        }
        if ( $value == 3 ) {
            if ( $hand == 1 ) {

                #フルハウス
                $hand = 6;
            }
            else {
                #スリーカード
                $hand = 3;
            }
        }
        if ( $value == 4 ) {

            #フォーカード
            $hand = 7;
        }
    }

    #ストレートチェック
    my @sorted_nums = sort { $a <=> $b } @$nums_ref;
    my $straight_check = 0;

    for ( my $i = 0; $i < 4; $i++ ) {
        if ( ( $sorted_nums[$i] + 1 ) == $sorted_nums[ ( $i + 1 ) ] ) {
            $straight_check++;
        }
    }
    if ( $straight_check == 4 ) {
        $hand = 4;
    }

    #フラッシュチェック
    %counter = undef;
    foreach my $key (@$suits_ref) {
        $counter{$key} = $counter{$key} + 1;
    }
    while ( my ( $key, $value ) = each %counter ) {
        if ( $value == 5 ) {
            if ( $hand == 4 ) {
                $hand = 8;
            }
            else {
                $hand = 5;
            }
        }
    }

    #ロイヤルチェック
    if (   $sorted_nums[0] == 1
        && $sorted_nums[1] == 10
        && $sorted_nums[2] == 11
        && $sorted_nums[3] == 12
        && $sorted_nums[4] == 13 )
    {
        if ( $hand == 5 ) {
            $hand = 9;
        }
        else {
            $hand = 4;
        }
    }

    return $hand;
}

sub _split_suits {
    my ($self) = @_;
    my $cards_ref = $self->{cards};
    my @suits;

    for ( my $i = 0; $i < 5; $i++ ) {

        #数字で区切って 's' '10'のようになるので0
        my @arr = split( /\d/, @$cards_ref[$i] );
        $suits[$i] = $arr[0];
    }
    return \@suits;
}

sub _split_nums {
    my ($self) = @_;
    my $cards_ref = $self->{cards};
    my @nums;

    for ( my $i = 0; $i < 5; $i++ ) {

        #記号で区切って '' '10'のようにヒットするので1
        my @arr = split( /[a-z]/, @$cards_ref[$i] );
        $nums[$i] = $arr[1];
    }
    return \@nums;
}

1;

