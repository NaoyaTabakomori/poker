#AI<->server間の会話は"["で始まる発言をする
#server->AIの発言は基本的に
1. "::"でsplitして、::の左側がデータの大まかな説明
2. "&&"でsplitして、各項目を取り出す
3. 各項目を"="でsplitして、左側が関数名 右側が値
4. 各値を"-"でsplitして、値を分ける
例：[ *player2 :: yaku=TWO_PAIR && cards = d2-a2-c3-b3-d10 ]

人間が見やすくするために、スペースを無視する仕様にする

#人間->serverの会話は!で始まる発言をする
#server->人間の会話は+で始まる発言をする

#AIはサーバーの発言だけを拾えば全情報が集まるようにする

#大文字小文字の区別はしない

ルール：テキサスホールデム
http://www.pokerdou.com/texasholdem-first/rule/

以下、ゲームの進行概要

player1: !begin::initialcoin=1000&&BB=50] #まず代表者がゲームを開始 最初のコインとビッグブラインドを指定
server: +beginning gather please say "!hi" to join game
player2: !hi
server: +player2 join to player1's game
player3: !hi
server: +player2 join to player1's game
player4: !hi
server: +player2 join to player1's game

player1: !end_member
server: [ start_game ]
server: [ sort = player3-player2-player4-player1 ] #順番をランダムにする
server: [ dealer = player3 ]        #dealerは配列の先頭 この場合SB:player2 BB:player4

talk to player3: [ initial_cards = c5-d11 ] #最初のカードを伝える club=a daiya=b clover=c spade=d
talk to player2,4,1: 略

server: [ round = 1 ]   #第一ベッティングラウンド
server: [ turn = player1 && tablebed = 50 && yourbed = 0 ]  #ターンの人と、現在の場の賭け額・プレイヤーの賭け額を伝える(最初はbig blindと一緒)
#######
ここでplayer1は次の選択肢を取れる
本来はここでレイズをすることも可能だが、レイズとベッドは同じコマンドを用いる（つまり額を変えるだけ）
[fall]  #フォール
[check] #チェック
[call]  #コール
[bed100]   #100円ベッド
ここで不正な入力がプレイヤーから入る可能性がある。
無意味なfall->そのままfallさせる
不正なcheck->強制コール
不正なcall->強制check (不正なコールはチェック出来る場合にしかありえない)
不正なbed->最低額を下回る場合:最低額でbed
最高額を上回る場合:最高額でbed

所持金を上回るcall,bedをしようとした場合は、all-inとなる

1分以内に応答が無い->強制fall
#######
player1: [ call ]
server: [ @player1 = call ]
server: [ turn = player3 && tablebed = 50 && yourbed = 0 ]
player3: [bed100]
server: [ @player3 = bed100 ]
server: [ turn = player2 && tablebed = 100 && yourbed=25 ]
player4: [ fall ]
server: [ @player4 = fall ]
server: [ turn = player4 && tablebed = 100 && yourbed = 50 ]
player2: [ call ]
server: [ @player2 = call ]
以下略、player4以外全員コールしたとする

server: [ round = 2 &&pod =300 && member = player3-player2-player1 ] #第二ベッティングラウンド pod額,残っているプレイヤーを表示
server: [ cards2nd = c5-a1-a5 ]   #３枚のカードを表示
server: [ turn = player1 && tablebed=0 && yourbed=0 ]
player1: [ call ] #本来はcheckなので間違い、serverが修正して表示する
server: [ player1 = check ]

以下、全員がcheckし続けて、3rd round,4th roundが終わって全員checkしたとする
server: [ *player1 :: yaku = FLASH && cards = c1-c4-c5-c6-c9 ]
server: [ *player2 :: yaku = TWO_PAIR && cards = d2-a2-c3-b3-d10 ]
下りていない人のカードを表示
略

server: [ winner = player1 && price = 1550 ]
server: [ money :: player3 = 3550 && player2 = 200 && player4 = 950 && player1 = 300 ]

#次のゲームへ
server: [ dealer = player3 ]
以下繰り返し・・・

######################
allinの場合次のような挙動にする
player1: [ bed1000 ]
server: [ @player1 = allin1000]


