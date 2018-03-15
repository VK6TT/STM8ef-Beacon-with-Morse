\ Load PLL chip
\ Tx when PLL is in locked state
\ Ident via morse

RAM
\ Enable compile mode, compile code to set|reset the bit at addr.
: ]B! ( 1|0 addr bit -- )
  ROT 0= 1 AND SWAP 2* $10 + + $72 C, C, , ]
  ; IMMEDIATE

  
NVM

VARIABLE timer
: tSet TIM 30000 + timer ! ; 
: tTest TIM timer @ - 0 < ;
: delay130us 
   3 0 do
      tSet begin ttest until 
   loop
   ;
: ms 	8 * 0 do 	delay130us loop ; \ rough but close enough for now

 \ translate bit n to byte code  eg 2 bit2byte returns 4
: Bit2byte ( bit --- byte )
   1 swap 0 do 2* loop   \ 2 becomes 4 ie 0b00000100
   ;
   

\ define the pins we need on micro

\ Port C outputs 01111000 assume all are push pull
6 constant _SD 
5 constant _Clk 
4 constant _LE
3 constant _Tx 

\ On port D we have
3 constant _LED \ output
2 constant _LD  \ input

300 constant duration
$500A constant PC_ODR 
$500C constant PC_DDR
$500D constant PC_CR1
$500F constant PD_ODR 
$5010 constant PD_IDR 
$5011 constant PD_DDR
$5012 constant PD_CR1
: setup_pins
   $78 ( 0b01111000 ) PC_DDR c! \ Port C outputs
   $78 ( 0b01111000 ) PC_CR1 c! \ set up as push pull outputs
   $08 ( 0b00001000 ) PD_DDR c! \ pin 3 is output
   $0A ( 0b00001000 ) PD_CR1 c! \ pin 3 push pull output 
   ;
   
: TX.on ( -- )  [ 1 PC_ODR _Tx ]B! ;
: TX.off ( -- ) [ 0 PC_ODR _Tx ]B! ;

\ inverted LED since we sink, not source, current to turn on
: LED.on ( -- )  [ 0 PD_ODR _LED ]B! ;
: LED.off ( -- ) [ 1 PD_ODR _LED ]B! ;

\ for bit banging 
: Clk.high [ 1 PC_ODR _Clk ]B! ;
: Clk.low [ 0 PC_ODR _Clk ]B! ;
: SD.high [ 1 PC_ODR _SD ]B! ;
: SD.low [ 0 PC_ODR _SD ]B! ;
: LE.high [ 1 PC_ODR _LE ]B! ;
: LE.low [ 0 PC_ODR _LE ]B! ;

: Locked? 
   _LD bit2byte 
   PD_IDR C@  
   and 0= ;

: TxOff Led.off Tx.Off ;
: TxON Led.On Locked? if Tx.On else Txoff then ;

: dot TxON duration ms TxOff duration ms ;
: dash TxON duration 3 * ms TxOff duration ms ;
: mspace duration 3 * ms ;
: a dot dash ;
: b dash dot dot dot ;
: c dash dot dot dot ;
: d dash dot dot ;
: e dot ;
: f dot dot dash dot ;
: g dash dash dot ;
: h dot dot dot dot ;
: ii dot dot ;
: jj dot dash dash dash ;
: kk dash dot dash ;
: l dot dash dot dot ;
: m dash dash ;
: n dash dot ;
: o dash dash dash ;
: p dot dash dash dot ;
: q dash dash dot dash ;
: r dot dash dot ;
: s dot dot dot ;
: t dash ;
: u dot dot dash ;
: v dot dot dash ;
: w dot dash dash ;
: x dash dot dash ;
: y dash dot dash dash ;
: z dash dash dot dot ;
: n1 dot dash dash dash dash ;
: n2 dot dot dash dash dash ;
: n3 dot dot dot dash dash ;
: n4 dot dot dot dot dash ;
: n5 dot dot dot dot dot ;
: n6 dash dot dot dot dot ;
: n7 dash dash dot dot dot ;
: n8 dash dash dash dot dot ;
: n9 dash dash dash dash dot ;
: n0 dash dash dash dash dash ;

: Ident \ could be done mroe elegantly but it works.
   TxOFF mspace
   d mspace 
   e mspace  
   v mspace 
   kk mspace 
   n6 mspace 
   t mspace 
   t mspace 
   mspace  
   ;

\ PLL output on 1296.5 MHz, 
\ reference of 125 KHz  from 4MHz crystal
\ division of 32
\ prescaler then 14 bit ref then control loaded with 1000 0000 0100 0001 
: delay 10 ms ;
: toggleclk delay clk.high delay clk.low delay ;
: toggleLE delay LE.high delay LE.low ;
: sendbyte ( n1 --- )
   delay
   8 0 do
      dup 128 and
      if SD.high then
      toggleclk
      SD.low
      2 *
   loop
   drop
   ;
: LoadRef
   LE.low
   Clk.low
   delay
   128 sendbyte 
   65 sendbyte
   toggleLE
   ;
\ load programmable divider with 81 and swallow counter with 4
\ 20 bit shift register used as follows
\ becomes with control bit  0000 0000 1010 0010 0000 1000
\                                ^           ^          ^
\                                S19         S9        ctl

: LoadN
\ To give a freq of 1316.5MHz for testing (+20MHz) , check if PD1 low
   8 162 0   
   sendbyte sendbyte sendbyte 
   toggleLE
   ;
   
: PLL!
      setup_pins
      Loadref
      LoadN
	  ;
: Main
	PLL!
    begin
		60 0 do 
			TxOn 1000 ms 
		loop  \ 60 second carrier
      ident
    again
     ;
' main 'Boot !  
RAM
