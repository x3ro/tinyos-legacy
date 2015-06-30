/*
 ***************************************************************************
 *     Filename: IO_Cards.h
 *       Author: Mike Bechtold
 ***************************************************************************
*/
#ifndef _IO_CardsH
#define _IO_CardsH

#include "TVicPort.h" // this must be the last header file

#define LPT1        0x0378
#define LPT2        0x03BC


// base + 5 -- port b
   #define SCK                1 //pin 16
   #define DOUT               2 //pin 15
   #define RESET              16 //pin 10
// base + 6 -- port c
   #define DIN                11 //pin 23

#define setb(x,y) SetPin(x, 1)
#define clrb(x,y) SetPin(x, 0)
#define inb(x) GetPin(x)


   #define SET_RESET_HIGH()   setb(RESET, BASE+5)
   #define SET_RESET_LOW()    clrb(RESET, BASE+5)
   #define SET_SCLK_HIGH()    setb(SCK,   BASE+5)
   #define SET_SCLK_LOW()     clrb(SCK,   BASE+5)
   #define SET_DOUT_HIGH()    setb(DOUT,  BASE+5)
   #define SET_DOUT_LOW()     clrb(DOUT,  BASE+5)
   #define Is_DIN_HIGH()      (inb(DIN) & 0x1 )

#endif