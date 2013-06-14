
<?php 
require_once("/usr/lib/php/pear/Net/SmartIRC.php"); 

if($argc == 1){
                $irc->message(SMARTIRC_TYPE_NOTICE, $data->channel,  "引数にチャンネル名を入力してください");
    return;
}

class mybot 
{

function check_hand(&$irc,&$data) {
    $argv = split('-',$data->message);

if(!isset($argv[1],$argv[2],$argv[3],$argv[4],$argv[5])){
                $irc->message(SMARTIRC_TYPE_NOTICE, $data->channel,  '5個引数入れて');
    return;
}

for($i=1;$i<6;$i++){
    $suit[$i] = substr($argv[$i],0,1); $num[$i] = (int)(substr($argv[$i],1));
}

//入力値チェック
for($i=1;$i<6;$i++){
    if(!preg_match("/^(\d)+$/",$num[$i])) {
                    $irc->message(SMARTIRC_TYPE_NOTICE, $data->channel,  '数字入れて');
        return;
    }
    if (!(0 < $num[$i] && $num[$i] <= 13)) {
                    $irc->message(SMARTIRC_TYPE_NOTICE, $data->channel,  '1-13いれて');
        return;
    }
    if(!preg_match("/(h|c|d|s)/", $suit[$i])) {
                    $irc->message(SMARTIRC_TYPE_NOTICE, $data->channel,  's,c,d,hのどれか入れて');
        return;
    }
}

//同じカードがないかチェック

$duplicate = array_count_values($argv);
foreach ($duplicate as $duplicate_count) {
    if($duplicate_count > 1){
                    $irc->message(SMARTIRC_TYPE_NOTICE, $data->channel,  '同じカードあります');
        return;
    }
}

//役の初期化

$hands['pair'] = 0;
$hands['three_card'] = 0;
$hands['four_card'] = 0;
$hands['full_house'] = 0;
$hands['straight'] = 0;
$hands['royal'] = 0;
$hands['flash'] = 0;
$hands['pig'] = 0;


//ペアチェック
//スリー、フォーカードチェック

$pair_counts = array_count_values($num);
$pair = 0;
$three_card = 0;
$four_card = 0;
foreach ($pair_counts as $pair_count) {
    if ($pair_count == 2) {
        $hands['pair']++;
    }
    if ($pair_count == 3) {
        $hands['three_card']++;
    }
    if ($pair_count == 4) {
        $hands['four_card']++;
    }
}

//フルハウスチェック
if($hands['pair'] && $hands['three_card']) {
    $hands['full_house'] = 1;
}
//             $irc->message(SMARTIRC_TYPE_NOTICE, $data->channel,  $pair);
//             $irc->message(SMARTIRC_TYPE_NOTICE, $data->channel,  $three_card);
//             $irc->message(SMARTIRC_TYPE_NOTICE, $data->channel,  $four_card);

//ストレートチェック
$sort_num = $num;
sort($sort_num);
$s_check = 0;

for ($i=0;$i<4;$i++) {
    if($this->next_check($sort_num[$i],$sort_num[($i+1)])){
        $s_check++;
    }
}
//             $irc->message(SMARTIRC_TYPE_NOTICE, $data->channel,  $s_check);
if ($s_check == 4) {
    $hands['straight'] = 1;
}

//ロイヤルチェック
$royal = 0;
if($this->royal_check($sort_num)) {
    $hands['royal'] = 1;
}


//フラッシュチェック
$flash_check = array_count_values($suit);
foreach ($flash_check as $flash_count) {
    if ($flash_count == 5) {
        $hands['flash'] = 1;
    }
}

//豚を入れる
if($sort_num[0] == 1) {
    $hands['pig'] = 1;
} else {
    $hands['pig'] = $sort_num[4];
}

            $irc->message(SMARTIRC_TYPE_NOTICE, $data->channel,  $this->answer_hand($hands));
}
function answer_hand($hands) {
    if($hands['royal'] && $hands['flash']) {
        return 'royal straight flash';
    }
    if($hands['straight'] && $hands['flash']) {
        return 'straight flash';
    }
    if($hands['four_card']) {
        return 'four cards';
    }
    if($hands['full_house']) {
        return 'full house';
    }
    if($hands['flash']) {
        return 'flash';
    }
    if($hands['straight']) {
        return 'straight';
    }
    if($hands['three_card']) {
        return 'three_card';
    }
    if($hands['pair'] == 2) {
        return 'two pair';
    }
    if($hands['pair'] == 1) {
        return 'one pair';
    }
    return 'no hand your max card is ' . $hands['pig'];
}

function next_check($pre_num,$next_num){
    if(($pre_num + 1) == $next_num) {
        return 1;
    }
    return 0;
}

function royal_check($sort_num){
    if (
    $sort_num[0] == 1 &&
    $sort_num[1] == 10 &&
    $sort_num[2] == 11 &&
    $sort_num[3] == 12 &&
    $sort_num[4] == 13 
    ) {
        return 1;
    }
    return 0;
}

} 

$bot = new mybot(); 
$irc = new Net_SmartIRC(); 

$irc->registerActionhandler(SMARTIRC_TYPE_CHANNEL, '.', $bot, 'check_hand'); 

$irc->connect("10.33.146.108", 6667); 
$irc->login("hands_checker", "test"); 
$irc->join(array("#{$argv[1]}")); 

$irc->listen(); 

?>
