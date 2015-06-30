/*
 * Copyright (c) 2005 Hewlett-Packard Company
 * All rights reserved
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:

 *     * Redistributions of source code must retain the above copyright
 *       notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above
 *       copyright notice, this list of conditions and the following
 *       disclaimer in the documentation and/or other materials provided
 *       with the distribution.
 *     * Neither the name of the Hewlett-Packard Company nor the names of its
 *       contributors may be used to endorse or promote products derived
 *       from this software without specific prior written permission.

 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * Authors:             Brian Avery
 * This is an implementation of the LCD module, blocking.
 */

/**
 * @author Brian Avery
 */

includes lcd_types;
includes icons;

// for image drawing
#define RLE_MARKER_CHAR '\121'

/* LCD Definitions*/

//  LCD module is set internally to:
//  CS2 = H   LCD CS1 will enable I/O
//  CLS = H   Internal Osc active
//  C86 = L   8080 interface
//  P/S = H   Parallel Data mode

/* Fxnal */
#define LCD_MIN_PAGE 1  
#define LCD_MIN_ROW 6
#define LCD_MAX_PAGE 10  
#define LCD_MAX_ROW 125
#define LCD_MAX_WIDTH 80
#define LCD_PAGE_OFFSET 1
#define LCD_ROW_OFFSET 6


// make sure we dont overwrite stuff
#define GF_CHECK_BOUNDARY 1

// We need some macros to figure out where we are...
#define GF_SCREEN_NAME(x,y) ((x<LCD_MAX_WIDTH)?LCD_LEFT_L_VAL:LCD_RIGHT_L_VAL)
#define GF_SCREEN_NUM(x,y) ((x<LCD_MAX_WIDTH)?0:1)
#define GF_LOCAL_X(x,y) (x-(GF_SCREEN_NUM(x,y)*LCD_MAX_WIDTH))
#define GF_PAGE(x,y) ((uint8_t) (GF_LOCAL_X(x,y)/8) + LCD_PAGE_OFFSET)
#define GF_PAGE_BIT(x,y) ((uint8_t) (GF_LOCAL_X(x,y) - (8 *  (GF_PAGE(x,y)- LCD_PAGE_OFFSET))))
#define GF_ROW(x,y) ((uint8_t) y + LCD_ROW_OFFSET)


#define MIN(a,b) ( ((a) < (b))?(a):(b))
#define MAX(a,b) ( ((a) > (b))?(a):(b))


// battery size definitions
#define GF_BATTERY_OX 0
#define GF_BATTERY_OY 0
#define GF_BATTERY_DX 2
#define GF_BATTERY_DY 2
#define GF_BATTERY_HT 10

//time and date
#define GF_TIME_X0 124
#define GF_TIME_Y0 1
#define GF_TIME_W  35
#define GF_TIME_H  15


#define GF_DATE_X0 40
#define GF_DATE_Y0 1
#define GF_DATE_W  83
#define GF_DATE_H  15
#define GF_DATE_SPACE  10



#define GF_TEXT_HORZ_FUDGE 1
#define MAX_STRING_LEN 1000

#define SCATTERED_CMD_NET 1
//#undef SCATTERED_CMD_NET


#if !defined(SCATTERED_CMD_NET)
#define LCD_IDLE               (LCD_LEFT_L_VAL | LCD_RIGHT_L_VAL | LCD_RESET_L_VAL | LCD_CMD_L_VAL | LCD_WR_L_VAL | LCD_RD_L_VAL) // unselects lines a0 in data mode
#define LCD_WRITE_CMD_START    (LCD_LEFT_L_VAL | LCD_RIGHT_L_VAL | LCD_RESET_L_VAL | LCD_RD_L_VAL) 
#define LCD_WRITE_CMD_LATCH    (LCD_LEFT_L_VAL | LCD_RIGHT_L_VAL | LCD_RESET_L_VAL | LCD_WR_L_VAL | LCD_RD_L_VAL) //Latch w/ only delta WR
#define LCD_WRITE_DATA_START   (LCD_LEFT_L_VAL | LCD_RIGHT_L_VAL | LCD_RESET_L_VAL | LCD_CMD_L_VAL | LCD_RD_L_VAL) // unselects lines a0 in data mode
#define LCD_WRITE_DATA_LATCH   (LCD_LEFT_L_VAL | LCD_RIGHT_L_VAL | LCD_RESET_L_VAL | LCD_CMD_L_VAL | LCD_WR_L_VAL | LCD_RD_L_VAL) //Latch w/ only delta WR
#define LCD_READ_DATA_START    (LCD_LEFT_L_VAL | LCD_RIGHT_L_VAL | LCD_RESET_L_VAL | LCD_CMD_L_VAL | LCD_WR_L_VAL) // unselects lines a0 in data mode
#define LCD_READ_DATA_LATCH   (LCD_LEFT_L_VAL | LCD_RIGHT_L_VAL | LCD_RESET_L_VAL | LCD_CMD_L_VAL | LCD_WR_L_VAL | LCD_RD_L_VAL) //Latch w/ only delta RD


#else
#define LCD_IDLE {TOSH_SET_LCD_LEFT_L_PIN();TOSH_SET_LCD_RIGHT_L_PIN();TOSH_SET_LCD_CMD_L_PIN();TOSH_SET_LCD_WR_L_PIN();TOSH_SET_LCD_RD_L_PIN();}
#endif







/* LCD Data Values */
#define LCD_COM_REV       (0xc8)
#define LCD_COM_NORM      (0xc0)
#define LCD_OSC_ON        (0xab)
#define LCD_OSC_OFF       (0xaa)
#define LCD_VOL_MODE      (0x81)
#define LCD_VOL_REG       (0x40)    // TBD by testing
#define LCD_PWR_CKTS      (0x27)    // per spec on power control reg.
#define LCD_DISP_ON       (0xaf)
#define LCD_DISP_OFF      (0xae)
#define LCD_ALLPTS_ON     (0xa5)
#define LCD_ALLPTS_OFF    (0xa4)
#define LCD_ADC_REV       (0xa1)
#define LCD_ADC_NORM      (0xa0)
#define LCD_DISP_NORM     (0xa6)
#define LCD_DISP_REV      (0xa7)    
#define LCD_NLINE         (0x3c)    // 52 line reverse-- per spec
#define LCD_NLINE_CANCEL  (0xd4)    // reg 2 frame inversion
#define LCD_DUTY          (0x74)    // 1/84 Duty-- per spec
#define LCD_OSC_FREQ      (0x55)    // 33kHZ per spec
#define LCD_START_PT      (0x62)    // per spec line 2
#define LCD_LINE          (0x8a)    // LCD Starting line is followed by a data byte
#define LCD_PAGE          (0xb0)    // base cmd for page address
#define LCD_COL_HI        (0x10)    // base cmd for hi col address
#define LCD_COL_LO        (0x00)    // base cmd for hi col address
#define LCD_RMW           (0xe0)    // read modify write command (reads no advance row ptr
#define LCD_RESET         (0xe2)
#define LCD_NOP           (0xe3)
#define LCD_END           (0xee)    // end read modify write mode





/**************************************************************************************************************************
 *
 *  With this setup we have a left and right side chip
 *  Each is 80x120 pixels
 *  The columns occur in 8 bit pages with the pages running from 1 to 10
 *  The rows are col values starting at 6 and running to 125 ( This is probly changeable but I dont know how yet.
 *  Unfortunately, the natural rowstride is opposite the way the rows are oriented (2 consec data writes advance the
 *    cursor down the screen rather than across the screen e.g. we get -
 *                                                                     -
 *                                                                     -
 *    not ------
 *
 *
 **************************************************************************************************************************/


module LCD_BM {
#if 0
  uses 
    {
      interface Leds;
      interface StrOutput;

    }
#endif
  
  provides    {
      interface LCD;
    //interface StdControl;
    }
  
}

implementation
{
  extern int snprintf(char *str, size_t len, const char *format, ...) __attribute__ ((C));

  //maintains where we are
  

  int render_string_width(char *inbuf,const struct FONT *font,const Point *dest);
  int render_icon(const struct ICON *this,int which,const Point *dest,int mode);  
  void render_string_rect(char *inbuf,const struct FONT *font,const Point *dest, Rect *r);
  result_t gf_draw_multiline_string(char *str,int fontNum,Point *dest,int mode);
  
    
  // these contain the const struct defs for a test image and the fonts forcing them to be in ROM
  // they are part of the implementation thus they are included here.
#include "font.h"
  


  
  
  void render_string(char *inbuf,const struct FONT *font,const Point *dest,int mode);
  

  
  static const struct _Point dog = {10,10};

#if 0
#define LCD_CMD_DELAY {volatile int i;for (i=0;i < 2; i++);}
#else
#define LCD_CMD_DELAY {}
#endif


#undef DEBUG_LCD  
#ifdef DEBUG_LCD
#define LCD_ERROR(s,i ) {Error(s,i);}
#else
#define LCD_ERROR(s,i) {}  
#endif //DEBUG_LCD  
  
  void Error(char *s,int e)
    {
      char buf[128];
      Point p = {2,10};
      volatile int hold;

      call LCD.clear();
      snprintf(buf,128,"%s:%d",s,e);	
      for (hold = 1; hold < 50; hold++)
	call LCD.gf_draw_string(buf,FONT_HELVETICA_R_12,&p,GF_OR);
    }


  

  static void send_lcd_cmd(uint8_t lcdValue, uint8_t LeftRight_CS_N)
    {


      // latch data on data port
#if HANDLE_LCD_BITWISE
      if (lcdValue & (1<<0))
	TOSH_SET_LCD_D0_PIN();
      else
	TOSH_CLR_LCD_D0_PIN();
      if (lcdValue & (1<<1))
	TOSH_SET_LCD_D1_PIN();
      else
	TOSH_CLR_LCD_D1_PIN();
      if (lcdValue & (1<<2))
	TOSH_SET_LCD_D2_PIN();
      else
	TOSH_CLR_LCD_D2_PIN();
      if (lcdValue & (1<<3))
	TOSH_SET_LCD_D3_PIN();
      else
	TOSH_CLR_LCD_D3_PIN();
      if (lcdValue & (1<<4))
	TOSH_SET_LCD_D4_PIN();
      else
	TOSH_CLR_LCD_D4_PIN();
      if (lcdValue & (1<<5))
	TOSH_SET_LCD_D5_PIN();
      else
	TOSH_CLR_LCD_D5_PIN();
      if (lcdValue & (1<<6))
	TOSH_SET_LCD_D6_PIN();
      else
	TOSH_CLR_LCD_D6_PIN();
      if (lcdValue & (1<<7))
	TOSH_SET_LCD_D7_PIN();
      else
	TOSH_CLR_LCD_D7_PIN();

#else
      atomic
	{
	  LCD_DATA_OUT_PORT = lcdValue;                                // Data on bus
	}
      
#endif

      // this one might need to assert both.
      if (LeftRight_CS_N & LCD_LEFT_L_VAL)
	TOSH_CLR_LCD_LEFT_L_PIN();
      if (LeftRight_CS_N & LCD_RIGHT_L_VAL)
	TOSH_CLR_LCD_RIGHT_L_PIN();
      // write cmd start
      TOSH_CLR_LCD_CMD_L_PIN();
      TOSH_CLR_LCD_WR_L_PIN();
      //latch it on rising edge of the write
      TOSH_SET_LCD_WR_L_PIN();      
      LCD_IDLE;


      
    }
  
    
  static  void set_lcd_byte(uint8_t lcdValue, uint8_t LeftRight_CS_N)
    {

      
      // latch data on data port
#if HANDLE_LCD_BITWISE
      if (lcdValue & (1<<0))
	TOSH_SET_LCD_D0_PIN();
      else
	TOSH_CLR_LCD_D0_PIN();
      if (lcdValue & (1<<1))
	TOSH_SET_LCD_D1_PIN();
      else
	TOSH_CLR_LCD_D1_PIN();
      if (lcdValue & (1<<2))
	TOSH_SET_LCD_D2_PIN();
      else
	TOSH_CLR_LCD_D2_PIN();
      if (lcdValue & (1<<3))
	TOSH_SET_LCD_D3_PIN();
      else
	TOSH_CLR_LCD_D3_PIN();
      if (lcdValue & (1<<4))
	TOSH_SET_LCD_D4_PIN();
      else
	TOSH_CLR_LCD_D4_PIN();
      if (lcdValue & (1<<5))
	TOSH_SET_LCD_D5_PIN();
      else
	TOSH_CLR_LCD_D5_PIN();
      if (lcdValue & (1<<6))
	TOSH_SET_LCD_D6_PIN();
      else
	TOSH_CLR_LCD_D6_PIN();
      if (lcdValue & (1<<7))
	TOSH_SET_LCD_D7_PIN();
      else
	TOSH_CLR_LCD_D7_PIN();

#else
      atomic{
	LCD_DATA_OUT_PORT = lcdValue;                                // Data on bus
      }
      
#endif

      if (LeftRight_CS_N & LCD_LEFT_L_VAL)
	TOSH_CLR_LCD_LEFT_L_PIN();
      if (LeftRight_CS_N & LCD_RIGHT_L_VAL)
	TOSH_CLR_LCD_RIGHT_L_PIN();
      // write  start
      TOSH_CLR_LCD_WR_L_PIN();
      //latch it on rising edge of the write
      TOSH_SET_LCD_WR_L_PIN();      
      LCD_IDLE;


    }

  // assumes we are in a default write state
  // may change later to track it if we hafta care
  static uint8_t get_lcd_byte(uint8_t LeftRight_CS_N)
    {
      uint8_t b;


      if (LeftRight_CS_N & LCD_LEFT_L_VAL)
	TOSH_CLR_LCD_LEFT_L_PIN();
      if (LeftRight_CS_N & LCD_RIGHT_L_VAL)
	TOSH_CLR_LCD_RIGHT_L_PIN();
      // read  start
      TOSH_CLR_LCD_RD_L_PIN();

#if HANDLE_LCD_BITWISE
      TOSH_MAKE_LCD_D0_INPUT();
      TOSH_MAKE_LCD_D1_INPUT();
      TOSH_MAKE_LCD_D2_INPUT();
      TOSH_MAKE_LCD_D3_INPUT();
      TOSH_MAKE_LCD_D4_INPUT();
      TOSH_MAKE_LCD_D5_INPUT();
      TOSH_MAKE_LCD_D6_INPUT();
      TOSH_MAKE_LCD_D7_INPUT();

      b = 0x00;
      b |= (TOSH_READ_LCD_D0_PIN() << 0);
      b |= (TOSH_READ_LCD_D1_PIN() << 1);
      b |= (TOSH_READ_LCD_D2_PIN() << 2);
      b |= (TOSH_READ_LCD_D3_PIN() << 3);
      b |= (TOSH_READ_LCD_D4_PIN() << 4);
      b |= (TOSH_READ_LCD_D5_PIN() << 5);
      b |= (TOSH_READ_LCD_D6_PIN() << 6);
      b |= (TOSH_READ_LCD_D7_PIN() << 7);

      
      TOSH_MAKE_LCD_D0_OUTPUT();
      TOSH_MAKE_LCD_D1_OUTPUT();
      TOSH_MAKE_LCD_D2_OUTPUT();
      TOSH_MAKE_LCD_D3_OUTPUT();
      TOSH_MAKE_LCD_D4_OUTPUT();
      TOSH_MAKE_LCD_D5_OUTPUT();
      TOSH_MAKE_LCD_D6_OUTPUT();
      TOSH_MAKE_LCD_D7_OUTPUT();
      

#else
      atomic{
	LCD_DATA_DIR_PORT = LCD_DATA_READ; // settling? 
	b = LCD_DATA_IN_PORT;
	LCD_DATA_DIR_PORT = LCD_DATA_WRITE;
      }
      


#endif
      //set_lcd_cmd_port(LCD_READ_DATA_LATCH & (~LeftRight_CS_N));

      //latch it on rising edge of the read
      TOSH_SET_LCD_RD_L_PIN();      
      LCD_IDLE;      


      return b;
  
    }

  // this sets the pointer to the proper (byte aligned) row setting for a pt x,y
  // it does *not* set it to   x,y
  // e.g. if (x,y) = (0,11) and val = 0x69 it writes 0x69
  // starting from (0,8)
  void lcd_set_row(int x,int y)
    {
      int page;      
      int screen;
      int row ;


      
      page = GF_PAGE(x,y);
      screen = GF_SCREEN_NAME(x,y);
      row = GF_ROW(x,y);

      // boundary checking here. can turn off if we want to 
#ifdef GF_CHECK_BOUNDARY
      if ((page > LCD_MAX_PAGE) ||
	  (page < LCD_MIN_PAGE) ||
	  (row <  LCD_MIN_ROW) ||
	  (row >  LCD_MAX_ROW) ||
	  (GF_SCREEN_NUM(x,y) < 0) ||
	  (GF_SCREEN_NUM(x,y) > 1))
	return;
#endif      

      send_lcd_cmd(LCD_PAGE | (page & 0x0f) ,screen);
      send_lcd_cmd(LCD_COL_HI | ((row & 0xf0)>>4),screen);
      send_lcd_cmd(LCD_COL_LO | (row & 0x0f),screen);
    }



  
  // this writes out val to the byte containing x,y
  // it does *not* write out a byte from x,y
  // e.g. if (x,y) = (0,11) and val = 0x69 it writes 0x69
  // starting from (0,8)
  void lcd_write_byte(int x,int y, uint8_t val)
    {
      int page;      
      int screen;
      int row ;


      
      page = GF_PAGE(x,y);
      screen = GF_SCREEN_NAME(x,y);
      row = GF_ROW(x,y);

      // boundary checking here. can turn off if we want to 
#ifdef GF_CHECK_BOUNDARY
      if ((page > LCD_MAX_PAGE) ||
	  (page < LCD_MIN_PAGE) ||
	  (row <  LCD_MIN_ROW) ||
	  (row >  LCD_MAX_ROW) ||
	  (GF_SCREEN_NUM(x,y) < 0) ||
	  (GF_SCREEN_NUM(x,y) > 1))
	return;
#endif      

      send_lcd_cmd(LCD_PAGE | (page & 0x0f) ,screen);
      send_lcd_cmd(LCD_COL_HI | ((row & 0xf0)>>4),screen);
      send_lcd_cmd(LCD_COL_LO | (row & 0x0f),screen);
      set_lcd_byte(val,screen);           


    }

  // this writes out val to the byte containing x,y
  // it does *not* write out a byte from x,y
  // e.g. if (x,y) = (0,11) and val = 0x69 it writes 0x69
  // starting from (0,8)
  // this version does not reset the row pointer so it
  // relies on the advancement of 1 row per write
  void lcd_write_byte_cont(int x,int y, uint8_t val)
    {
      int screen;
      
      screen = GF_SCREEN_NAME(x,y);
      set_lcd_byte(val,screen);           
    }


  
  // this reads the  val to the byte 
  // it doesnt se the location it assumes we are in rmw mode
  uint8_t lcd_read_byte_cont(int x,int y)
    {
      uint8_t b;
      int screen;
      


      screen = GF_SCREEN_NAME(x,y);
      get_lcd_byte(screen);           // dummy read necessary
      b = get_lcd_byte(screen);           // actual read


      return b;
  
    }

  


  
  // this reads the  val to the byte containing x,y
  // it does *not* read out a byte from x,y
  // e.g. if (x,y) = (0,11) it reads the val
  // starting from (0,8)
  uint8_t lcd_read_byte(int x,int y)
    {
      uint8_t b;
      int page;      
      int screen;
      int row ;
      


      page = GF_PAGE(x,y);
      screen = GF_SCREEN_NAME(x,y);
      row = GF_ROW(x,y);

      // boundary checking here. can turn off if we want to 
      //#ifdef GF_CHECK_BOUNDARY
      // currently no good way to signal a bad read since we return a byte
      // maybe use an error led????
      // or a sw trap?
#ifdef GF_CHECK_BOUNDARY
      if ((page > LCD_MAX_PAGE) ||
	  (page < LCD_MIN_PAGE) ||
	  (row <  LCD_MIN_ROW) ||
	  (row >  LCD_MAX_ROW) ||
	  (GF_SCREEN_NUM(x,y) < 0) ||
	  (GF_SCREEN_NUM(x,y) > 1))
	return 0x00;
#endif      
  
      send_lcd_cmd(LCD_PAGE | (page & 0x0f) ,screen);
      send_lcd_cmd(LCD_COL_HI | ((row & 0xf0)>>4),screen);
      send_lcd_cmd(LCD_COL_LO | (row & 0x0f),screen);

      get_lcd_byte(screen);           // dummy read necessary
      b = get_lcd_byte(screen);           // actual read


      return b;
  
    }

  

  // this takes a rect from an RLE image somewhere (typically ram or a saved flash img) and copies it to
  // a point on the lcd using  the given mode
  // needs to be fastish so we cant do a lot of abstraction layers easily
  // only mode copy currently supported
  void gf_copy_RLE_rect(const Rect *r,const GF_Image *srcImage,const Point *dest,int mode)
    {
      unsigned char *p = (unsigned char *) srcImage->data;
      unsigned int count ;
      unsigned char c;
      unsigned int  colCount=0;
      unsigned rowCount=0;
      Point src;
      int xEnd = r->x + r->w;
      int yEnd = r->y + r->h;
      int yStart = r->y ;
      Point lDest = *dest;
      unsigned char destByte=0x0; // what we write out
      unsigned char curByte=0x0;  // what's currently on the screen needed for or's and end conditions
      int destBytePtr=0;
      int i,j;
      int srcByteStart;
      int srcByteEnd;
      int bitsPending = 0;
  
  
  
      src.x = r->x;
      src.y = r->y;
  
      destBytePtr = lDest.x%8;
      destByte = 0x0;
  
  
      
      while ((rowCount <= yEnd) && (rowCount < srcImage->h)){
	if (*p == RLE_MARKER_CHAR){
	  p++;
	  count = *p++;
	  c = *p++;
	}
	else {
	  c=*p++;
	  count=1;      
	}


	while (count--){
	  if ( (rowCount >= yStart) && (src.y <= rowCount)) {
	    if ((xEnd >= colCount) && (src.x >= colCount) && (src.x < (colCount+8))){
	      // now we pick out the parts of the src byte we want and either | or copy them to the dest byte
	      srcByteStart = src.x%8;
	      srcByteEnd = (xEnd >= colCount+8)? 8: xEnd%8;
	      for (i=srcByteStart; i < srcByteEnd; i++){
		bitsPending = 1;
		destByte |= (((c & (1 <<i)) >> i) << destBytePtr++);
		if (destBytePtr > 7){
		  // this read could be opt out for copy modes in the middle
		  curByte = lcd_read_byte(lDest.x,lDest.y);
		  // fill in the start values that we didnt copy from the src
		  for (j=0; j< lDest.x%8;j++)                
		    destByte |= (curByte & (1 <<j));
		  // store it
		  switch (mode){
		  case GF_OR:
		    destByte |= curByte;                
		    break;
		  case GF_COPY:
		    // destByte is already correct
		    break;
		  default:
		    break;
		  }              
		  lcd_write_byte(lDest.x,lDest.y,destByte);
		  bitsPending = 0;
		  // go to the start of the next byte
		  lDest.x += (8-lDest.x%8);
		  destByte = 0x0;
		  destBytePtr = 0;              
		} // write out a full dest byte
	      } // copy out the src byte
	      // go on to the next src byte
	      src.x = colCount+8;
	    } // we are still w/in the right columns
	    if (xEnd < (colCount + 8)){
	      //done with this row ...
	      if (bitsPending){
		// we have run off the end of the row and have some < 8 bit byte to write out
		// first we need to fill out the end of the byte
		curByte = lcd_read_byte(lDest.x,lDest.y);
		// fill in the end values that we didnt copy from the src
		for (j=destBytePtr; j< 8;j++)                
		  destByte |= (curByte & (1 <<j));
		// store it
		switch (mode){
		case GF_OR:
		  destByte |= curByte;                
		  break;
		case GF_COPY:
		  // destByte is already correct
		  break;
		default:
		  break;
		}              
		lcd_write_byte(lDest.x,lDest.y,destByte);
		bitsPending = 0;
	      } // partial filled byte
	      // and reset us for the next row
	      lDest.x = dest->x;              
	      destBytePtr = lDest.x%8;
	      destByte = 0x0;
	      lDest.y++;
	      src.y++; 
	    }
	  }// we are still w/in the right rows
	  colCount+=8;
	  if (colCount >= (srcImage->w)){
	    colCount=0;
	    rowCount++;
	    src.x = r->x;
	  }
	} // count--
      } // rowcount < yend & img->h
    }


  


  void gf_draw_point(uint8_t x,uint8_t y)
    {
      uint8_t val;
  
      val = lcd_read_byte(x,y);
      val |= (1 << GF_PAGE_BIT(x,y));

      //lcd_write_byte(GF_SCREEN_NAME(x,y),GF_PAGE(x,y),GF_ROW(x,y),val);
      lcd_write_byte(x,y,val);
  
    }

  void gf_clear_point(uint8_t x,uint8_t y)
    {
      uint8_t val;
  
      val = lcd_read_byte(x,y);
      val &= ~(1 << GF_PAGE_BIT(x,y));

      //lcd_write_byte(GF_SCREEN_NAME(x,y),GF_PAGE(x,y),GF_ROW(x,y),val);
      lcd_write_byte(x,y,val);
  
    }






  /*********************************************************************************************************************************************
   *	
   *  Below is the actual interface definitions
   *
   *
  *********************************************************************************************************************************************/
  // stub for work on the color one
  async command uint16_t  LCD.read(uint16_t addr)
    {
      return 0x0;
      
    }

  async command result_t LCD.init() {
    volatile int i;

    // put the lcd in reset
    TOSH_CLR_LCD_RESET_L_PIN();
    for (i=0; i < 5000; i++); // wait a bit important to be well defined
    // take it out of reset
    TOSH_CLR_LCD_RESET_L_PIN();
    for (i=0; i < 5000; i++);
    TOSH_SET_LCD_RESET_L_PIN();    
    LCD_IDLE;
    

    
    send_lcd_cmd( LCD_ADC_REV,LCD_RIGHT_L_VAL);          // make col go from 0 -> 119 (top to bottom)
    //send_lcd_cmd( LCD_ADC_REV,LCD_LEFT_L_VAL | LCD_RIGHT_L_VAL);          // make col go from 0 -> 119 (top to bottom)
    send_lcd_cmd(LCD_COM_REV,LCD_RIGHT_L_VAL);          // make pages go from left to right
    //send_lcd_cmd(LCD_COM_REV,LCD_LEFT_L_VAL | LCD_RIGHT_L_VAL);          // make pages go from left to right

    send_lcd_cmd(LCD_NLINE,LCD_LEFT_L_VAL | LCD_RIGHT_L_VAL);             // spec says clears up crosstalk. need to play w/ pix on it
    send_lcd_cmd(LCD_OSC_FREQ,LCD_LEFT_L_VAL | LCD_RIGHT_L_VAL);    // set master/slave OSC freq  
    send_lcd_cmd(LCD_OSC_ON,LCD_LEFT_L_VAL | LCD_RIGHT_L_VAL);      // turn on master/slave OSC

    // def val of 0x40 works many others do not (0x42 does no obv diff)
    send_lcd_cmd(LCD_VOL_MODE,LCD_LEFT_L_VAL | LCD_RIGHT_L_VAL);    // set LCD Volume 2 byte command
    send_lcd_cmd(LCD_VOL_REG,LCD_LEFT_L_VAL | LCD_RIGHT_L_VAL);     // LCD volume data

    send_lcd_cmd(LCD_LINE,LCD_LEFT_L_VAL | LCD_RIGHT_L_VAL);        // set LCD line 2 byte cmd
    send_lcd_cmd(0x00,LCD_LEFT_L_VAL | LCD_RIGHT_L_VAL);                  // LCD line data
  
    send_lcd_cmd(LCD_PWR_CKTS,LCD_LEFT_L_VAL | LCD_RIGHT_L_VAL);    // Turn on LCD power
    send_lcd_cmd(LCD_DISP_ON,LCD_LEFT_L_VAL | LCD_RIGHT_L_VAL);     // LCD display is turned on 


    return SUCCESS;
  }


  async command result_t LCD.clear() {
    uint8_t page;
    uint8_t col;


    
    for (page = LCD_MIN_PAGE; page < LCD_MAX_PAGE+1;page++){
      send_lcd_cmd((LCD_PAGE+page),LCD_LEFT_L_VAL | LCD_RIGHT_L_VAL);          // example of moving to an LCD page ADDR
      send_lcd_cmd(LCD_COL_HI | ((LCD_MIN_ROW & 0xf0)>>4),LCD_LEFT_L_VAL | LCD_RIGHT_L_VAL);
      send_lcd_cmd(LCD_COL_LO | (LCD_MIN_ROW & 0x0f),LCD_LEFT_L_VAL | LCD_RIGHT_L_VAL);
      for(col=LCD_MIN_ROW; col < LCD_MAX_ROW+1; col++)
        set_lcd_byte(0x00,LCD_LEFT_L_VAL | LCD_RIGHT_L_VAL);           // example of writing pixel
      
    }

    return SUCCESS;
  }


  async command result_t LCD.backlightOn() {
    TOSH_SET_LCD_BACKLIGHT_PIN();
    return SUCCESS;    
  }

  async command result_t LCD.backlightOff() {
    TOSH_CLR_LCD_BACKLIGHT_PIN();
    return SUCCESS;
  }

  async command result_t LCD.fill(uint16_t color) {
    uint8_t page;
    uint8_t col;
    
    for (page = LCD_MIN_PAGE; page < LCD_MAX_PAGE;page++){
      send_lcd_cmd((LCD_PAGE+page),LCD_LEFT_L_VAL | LCD_RIGHT_L_VAL);          // example of moving to an LCD page ADDR
      send_lcd_cmd(LCD_COL_HI | ((LCD_MIN_ROW & 0xf0)>>4),LCD_LEFT_L_VAL | LCD_RIGHT_L_VAL);
      send_lcd_cmd(LCD_COL_LO | (LCD_MIN_ROW & 0x0f),LCD_LEFT_L_VAL | LCD_RIGHT_L_VAL);
      for(col=0; col < 130; col++)
        set_lcd_byte(0xff,LCD_LEFT_L_VAL | LCD_RIGHT_L_VAL);           // example of writing pixel
    }
    return SUCCESS;
  }

  async command  result_t LCD.gf_draw_string_aligned(char *str,int fontNum,Point *dest,int mode, int alignment)
    { 


      switch (alignment) {
      case LCD_ALIGN_RIGHT:
	return call LCD.gf_draw_string_right(str,fontNum,dest,mode);
	break;	
      case LCD_ALIGN_CENTER:
	return call LCD.gf_draw_string_center(str,fontNum,dest,mode);
	break;
      case LCD_ALIGN_LEFT:
	return call LCD.gf_draw_string(str,fontNum,dest,mode);
	break;
      }
      return FAIL;
    }


  async command  result_t LCD.gf_draw_multiline_string_aligned(char *str,int fontNum,Point *dest,int mode, int alignment)
    { 


      switch (alignment) {
      case LCD_ALIGN_RIGHT:
	return FAIL;	
	break;	
      case LCD_ALIGN_CENTER:
	return FAIL;	
	break;
      case LCD_ALIGN_LEFT:
	return gf_draw_multiline_string(str,fontNum,dest,mode);
	break;
      }
      return FAIL;
    }


  
  async command  result_t LCD.gf_draw_icon(int iconFamily,int which,Point *dest,int mode)
    { 
      const struct ICON *icon;
      
      if (iconFamily >= NUM_ICONS)
	return FAIL;
      icon = LCD_ICONS[iconFamily];

      render_icon(icon,which,dest,mode);
      return SUCCESS;
    }

  result_t gf_draw_multiline_string(char *str,int fontNum,Point *dest,int mode)
    {
      char *cstart;
      char *csearch;
      char *cmark;
      int maxWidth;      
      int width;
      const struct FONT *font = MWfonts[fontNum];
      Point l_dest = *dest;
      int s_len;
      
      
      width = render_string_width(str,font,dest);
      maxWidth = (LCD_WIDTH - dest->x);
      
      if (width < maxWidth){
	render_string(str,MWfonts[fontNum],dest,mode);
	return SUCCESS;
      }
      // otherwise we need to break it up
      cstart = str;
      cmark = str;
      
      width = 0;
      s_len = strlen(str);
      // fill all spaces with'\0'
      while (cmark){
	if (*cmark == ' ')	  
	  *cmark = '\0';
	cmark++;
      }

      cstart=str;
      cmark=str;
      csearch=str;
      LCD_ERROR("start str",(int)str);
      
      while ((csearch - str) < s_len) {
	if (*csearch == '\0'){
	  LCD_ERROR("csearch",(int)csearch);
	  cmark = csearch;
	  *csearch = ' ';
	  width = render_string_width(cstart,font,&l_dest);
	  if (width >= maxWidth){
	    LCD_ERROR("cmark",(int)cmark);
	    *cmark = '\0';
	    render_string(cstart,font,&l_dest,mode);
	    l_dest.y += font->ascent + font->descent + 2;
	    *cmark = ' ';
	    cstart = cmark+1;	    
	  }
	}
	csearch++;
      }
      // print the last line
      render_string(cstart,font,&l_dest,mode);
      return SUCCESS;
      
    }
  
      
  async command  result_t LCD.gf_draw_string(char *str,int fontNum,Point *dest,int mode)
    { 

      if (fontNum > MAX_FONTNUM)
	fontNum = 0;
      
      render_string(str,MWfonts[fontNum],dest,mode);


      return SUCCESS;
    }

  command  result_t LCD.gf_erase_string(char *str,int fontNum,Point *dest,int alignment)
    {
      Point p = *dest;
      int width;
      Rect r;

      if (fontNum > MAX_FONTNUM)
	return FAIL;
      

      switch (alignment) {
      case LCD_ALIGN_RIGHT:
	width = render_string_width(str,MWfonts[fontNum],dest);
	p.x -= width;
	break;	
      case LCD_ALIGN_CENTER:
	width = render_string_width(str,MWfonts[fontNum],dest);
	p.x -= width/2;
	break;
      }

      call LCD.gf_get_string_rect(str,fontNum,&p,&r);    
      call LCD.gf_clear_rect(&r);    
      return SUCCESS;      
    }
  
  async command  result_t LCD.gf_draw_string_right(char *str,int fontNum,Point *dest,int mode)
    { 
      int width;
      Point p = *dest;

      if (fontNum > MAX_FONTNUM)
	fontNum = 0;

      width = render_string_width(str,MWfonts[fontNum],dest);
      p.x -= width;
      render_string(str,MWfonts[fontNum],&p,mode);
      return SUCCESS;
    }

  async command  result_t LCD.gf_draw_string_center(char *str,int fontNum,Point *dest,int mode)
    { 
      int width;
      Point p = *dest;

      if (fontNum > MAX_FONTNUM)
	fontNum = 0;

      width = render_string_width(str,MWfonts[fontNum],dest);
      p.x -= width/2;

      render_string(str,MWfonts[fontNum],&p,mode);
      return SUCCESS;
    }



  async command  result_t LCD.gf_get_string_rect(char *str,int fontNum,Point *p,Rect *sRect)
    {

      if (fontNum > MAX_FONTNUM)
	fontNum = 0;

      render_string_rect(str,MWfonts[fontNum],p,sRect);
      return SUCCESS;




      
    }
  
  async command  int LCD.gf_get_string_width(char *str,int fontNum)
    {
      int width;
      Point p = {1,20};

      if (fontNum > MAX_FONTNUM)
	fontNum = 0;

      width = render_string_width(str,MWfonts[fontNum],&p);
      return width;
    }

  
    async command  result_t LCD.gf_get_font_info(int fontNum,int *ascent,int *descent)
    { 

      if ((fontNum < 0) || (fontNum > MAX_FONTNUM))
	return FAIL;
      
      *ascent = MWfonts[fontNum]->ascent;
      *descent = MWfonts[fontNum]->descent;
      return SUCCESS;
    }




    // fills a rect 
  async command  result_t LCD.gf_fill_rect(const Rect *r,uint8_t value)
    {

      int curX;
      int curY;
      uint8_t  b;
      int xEnd = r->x + r->w;
      int yEnd = r->y + r->h;
      uint8_t mask;
      uint8_t val= (value & 0xff);
      uint8_t rmwMode; // read-modidy-write mode, no set row/page, reads no advance row ptr
      
      rmwMode = 0;
      curY = r->y;
      curX = r->x;    
      while (curX < xEnd) {
	curY = r->y;
	if (rmwMode){
	  rmwMode = 0;
	  // force both screens into and out of rmw mode together.
	  send_lcd_cmd( LCD_END,LCD_RIGHT_L_VAL| LCD_LEFT_L_VAL);
	}
	lcd_set_row(curX,curY);  
	while (curY < yEnd) {
	  mask = 0xff;
	  b = 0x0;
	  if (curX%8){	    
	    // go into rmwMode
	    send_lcd_cmd( LCD_RMW,LCD_RIGHT_L_VAL| LCD_LEFT_L_VAL);
	    rmwMode = 1;
	    // beginning not byte aligned
	    b = lcd_read_byte_cont(curX - curX%8,curY);
	    // mask off the end part we are changing
	    mask &= (0xff >> (8-curX%8));
	    // mask off any beginning part we are changing
	    if (xEnd  < (curX + (8-curX%8))){
	      mask |= (0xff << (xEnd%8));
	    }
	    mask = (~mask)&0xff;
	  }
	  else if (xEnd < (curX+8)){
	    // go into rmwMode
	    send_lcd_cmd( LCD_RMW,LCD_RIGHT_L_VAL| LCD_LEFT_L_VAL);
	    rmwMode = 1;

	    // ending not byte aligned
	    // use the low level read cuz we are not setting the row ptr
	    b = lcd_read_byte_cont(curX ,curY);
	    // mask off any beginning part we are changing
	    mask &= (0xff << (xEnd%8));
	    mask = (~mask)&0xff;
	  }      
	  b &= ~mask;
	  b |= (val&mask);
	  lcd_write_byte_cont(curX,curY,b);
	  curY++;
	}	
	curX += (8-curX%8);
      }
      if (rmwMode){
	rmwMode = 0;
	// force both screens into and out of rmw mode together.
	send_lcd_cmd( LCD_END,LCD_RIGHT_L_VAL| LCD_LEFT_L_VAL);
      }

      return SUCCESS;
    }
  
  // clears a rect 
  async command  result_t LCD.gf_clear_rect(const Rect *r)
    {
      call LCD.gf_fill_rect(r,0x0);
      return SUCCESS;
      
    }

  // frames a rect 
  async command  result_t LCD.gf_frame_rect(const Rect *r)
    {

      // top
      call LCD.gf_draw_line(r->x,r->y,r->x+r->w,r->y);
      // bottom
      call LCD.gf_draw_line(r->x,r->y+r->h,r->x+r->w,r->y+r->h);
      // left
      call LCD.gf_draw_line(r->x,r->y,r->x,r->y+r->h);
      // right
      call LCD.gf_draw_line(r->x+r->w,r->y,r->x+r->w,r->y+r->h);
      
      return SUCCESS;
      
    }
  
  // clears a frame rect 
  async command  result_t LCD.gf_clear_frame_rect(const Rect *r)
    {

      // top
      call LCD.gf_clear_line(r->x,r->y,r->x+r->w,r->y);
      // bottom
      call LCD.gf_clear_line(r->x,r->y+r->h,r->x+r->w,r->y+r->h);
      // left
      call LCD.gf_clear_line(r->x,r->y,r->x,r->y+r->h);
      // right
      call LCD.gf_clear_line(r->x+r->w,r->y,r->x+r->w,r->y+r->h);
      
      return SUCCESS;
      
    }


  async command  result_t LCD.gf_draw_point(int x,int y)
    {
      gf_draw_point(x,y);
      return SUCCESS;
      
    }

  async command  result_t LCD.gf_clear_point(int x,int y)
    {
      gf_clear_point(x,y);
      return SUCCESS;
      
    }

  void gf_draw_line(int x0,int l_y0,int x1,int l_y1,int skip)
    {
      //Bresenham's line algorithm
      int i;
      int steep = 1;
      int sx, sy;  /* step positive or negative (1 or -1) */
      int dx, dy;  /* delta (difference in X and Y between points) */
      int e;
      int count=skip;
      
      int tmpswap;

#define SWAP(a,b) tmpswap = a; a = b; b = tmpswap;

      /* * optimize for vertical and horizontal lines here */
      dx = abs(x1 - x0);
      sx = ((x1 - x0) > 0) ? 1 : -1;
      dy = abs(l_y1 - l_y0);
      sy = ((l_y1 - l_y0) > 0) ? 1 : -1;
      if (dy > dx) {
	steep = 0;
	SWAP(x0, l_y0);
	SWAP(dx, dy);
	SWAP(sx, sy);
      }
      e = (dy << 1) - dx;
      for (i = 0;i < dx; i++) {
	if (steep) {
	  if (count-- <= 0){
	    gf_draw_point(x0,l_y0);
	    if (count<0)
	      count=skip;
	  }	  
	} else {
	  if (count-- <= 0){
	    gf_draw_point(l_y0,x0);
	    if (count < 0)
	      count=skip;
	  }	  
	}
	while (e >= 0) {
	  l_y0 += sy;
	  e -= (dx << 1);
	}
	x0 += sx;
	e += (dy << 1);
      }
      
    }


  async command  result_t LCD.gf_draw_line(int x0,int l_y0,int x1,int l_y1)
    {
      gf_draw_line(x0,l_y0,x1,l_y1,0);
      return SUCCESS;
    }
  async command  result_t LCD.gf_draw_dashed_line(int x0,int l_y0,int x1,int l_y1,int skip)
    {
      gf_draw_line(x0,l_y0,x1,l_y1,skip);
      return SUCCESS;
    }

  async command  result_t LCD.gf_clear_line(int x0,int l_y0,int x1,int l_y1)
    {
      //Bresenham's line algorithm
      int i;
      int steep = 1;
      int sx, sy;  /* step positive or negative (1 or -1) */
      int dx, dy;  /* delta (difference in X and Y between points) */
      int e;

      int tmpswap;

#define SWAP(a,b) tmpswap = a; a = b; b = tmpswap;

      /* * optimize for vertical and horizontal lines here */
      dx = abs(x1 - x0);
      sx = ((x1 - x0) > 0) ? 1 : -1;
      dy = abs(l_y1 - l_y0);
      sy = ((l_y1 - l_y0) > 0) ? 1 : -1;
      if (dy > dx) {
	steep = 0;
	SWAP(x0, l_y0);
	SWAP(dx, dy);
	SWAP(sx, sy);
      }
      e = (dy << 1) - dx;
      for (i = 0;i < dx; i++) {
	if (steep) {
	  gf_clear_point(x0,l_y0);
	} else {
	  gf_clear_point(l_y0,x0);
	}
	while (e >= 0) {
	  l_y0 += sy;
	  e -= (dx << 1);
	}
	x0 += sx;
	e += (dy << 1);
      }
      return SUCCESS;
      
    }


  
  // presumes P4 (monochrome 1 bit per pixel P4 image)
  async command result_t  LCD.draw_RLE_image(const GF_Image *img)
    {
      unsigned char *p = (unsigned char *) img->data;
      unsigned int count ;
      unsigned char c;
      unsigned int  colCount=0;
      unsigned rowCount=0;
  

      while (rowCount < img->h){
	if (*p == RLE_MARKER_CHAR){
	  p++;
	  count = *p++;
	  c = *p++;
	}
	else{
	  c=*p++;
	  count=1;
	}

	while (count--){
	  //printf("\\%.3o",c);
        
	  lcd_write_byte(colCount,rowCount,c);
	  colCount+=8;
	  if (colCount >= (img->w)){
	    colCount=0;
	    rowCount++;
	  }
	}
      }
  
      return SUCCESS;      
    }

  async command result_t  LCD.copy_RLE_rect(const Rect *r,const GF_Image *srcImage,const Point *dest,int mode)
  {
    gf_copy_RLE_rect(r,srcImage,dest,mode);
    return SUCCESS;
    
  }


  /************************************************************************/
  /*   new stuff */
  /************************************************************************/

  extern int sprintf(char *str, const char *format, ...) __attribute__ ((C));
#define KERNING 1
#define LIGATURES 1  
  
#ifdef LIGATURES
#define LIGATURE_NUM(x) (x & 0x000f)
#define LIGATURE_INDEX(x) ((x&0x00f0)>>4)
  
#endif  


  /*****************************************************************************************************************************
   *
   *   much faster version main speedups:
   *  1) go down columns rather than acroos rows so no have to set page/row ptr so much
   *  2) do read-modifywrite mode so reads no advance row ptr
   *  
   *
   *
   *
   *
   *****************************************************************************************************************************/
  // pass in dest.y+1 dfor text!  
  void drawBitmap(const uint8_t *p,int8_t xOff,int8_t yOff,int byteWidth,const Point *dest,int height )
    {
      const  uint8_t *pp; 
      int x;
      int y;
      uint8_t b;
      uint8_t destByte;
      int i;
      uint8_t xm8;
      int xEnd;
      uint8_t destByteRowCtr;

      
      x = dest->x + xOff;	    
      xEnd = x + byteWidth*8;
      xm8 = x%8;


      // should we add one here?
      // if we dont add one then the letters sit on top of the line
      // e.g if ydest = 75 and we draw a C we can see the bottom of the C and the line beneath it.
      // also if we draw a p the 1 pixel down is eaten by the line so I/m guessing that
      // a 1 is necesary here. can ask andy later. seems like yes for text and no for icons
      // so add text 1 in render_char
      y = dest->y - yOff - height ;


      destByteRowCtr = 0;      
      while (x < xEnd){
	// all columns but the first will have been in rmw mode already
	if (x > dest->x + xOff)
	  send_lcd_cmd( LCD_END,LCD_RIGHT_L_VAL| LCD_LEFT_L_VAL);
	// get set to write out a destbyte column
	lcd_set_row(x,y);  
	send_lcd_cmd( LCD_RMW,LCD_RIGHT_L_VAL| LCD_LEFT_L_VAL);
	for (i=0; i < height; i ++){
	  // doesn't really matter that y is here x is just used to get the screen we are on
	  destByte = lcd_read_byte_cont(x,y);      
	  pp = p  + i * byteWidth + destByteRowCtr;
	  b = 0x00;	  
	  if (destByteRowCtr > 0)
	    b |= (*(pp-1)>>(8-xm8));
	  if (destByteRowCtr < byteWidth)
	    b |= (*pp << xm8);
	  // forcing GF_OR for now, text overlaps enough that GF_COPY really doesn't work.
	  destByte |= b;

	  lcd_write_byte_cont(x,y,destByte);
	  
	}
	destByteRowCtr++;
	
	x += 8;
        x -= x%8;        

      }
      send_lcd_cmd( LCD_END,LCD_RIGHT_L_VAL| LCD_LEFT_L_VAL);
      
    }
  
  
      
  

  
  // FONT CHAR *next is used for kerning/ligature info
  // the fxn returns where the next char origin should be deltax only
  int render_char(const struct FONT_CHAR *this, const struct FONT_CHAR *next,const struct FONT *font,const Point *dest,int mode)
    {
      Point l_dest = *dest;      
      const  uint8_t *p;
      int i;
      int delta;
      const struct KERN_INFO *ki;
      
      p = font->bitmap + this->offset;
      // distance to the next char origin.
      // can be modified by ligatures or kerning.
      delta = this->dwidth;
      

#ifdef KERNING
      if (this->kernNum && next){
	for (i=this->kernIndex; i < this->kernNum + this->kernIndex;i++)
	  {
	    ki= &(font->ki[i]);
	    if (next->encoding == ki->encoding){
	      delta += ki->offset;
	    }
	  }
      }
      
	
#endif // KERNING      
      
      // raise chars off baseline by 1
      l_dest.y++;

      drawBitmap(p,this->bbXOff,this->bbYOff,this->byteWidth,&l_dest,this->bbh);
      return delta;
    }



  // the fxn returns where the next origin should be deltax only
  int render_icon(const struct ICON *this,int which,const Point *dest,int mode)
    {

      const  uint8_t *p;
      int delta;

      
      
      
      if (which < 0)
	which =0;
      else if (which >= this->count)
	which = this->count-1;
      
      
      p = this->bitmap + which * (this->height*this->byteWidth);
      delta = this->byteWidth*8;


      drawBitmap(p,0,0,this->byteWidth,dest,this->height);	  

      return delta;
    }


  int render_char_rect(const struct FONT_CHAR *this, const struct FONT_CHAR *next,const struct FONT *font, Point *p,Rect *r)
    {
      int i;
      int delta;
      const struct KERN_INFO *ki;

      // distance to the next char origin.
      // can be modified by ligatures or kerning.
      delta = this->dwidth;

#ifdef KERNING
      if (this->kernNum && next){
	for (i=this->kernIndex; i < this->kernNum + this->kernIndex;i++)
	  {
	    ki= &(font->ki[i]);
	    if (next->encoding == ki->encoding){
	      delta += ki->offset;
	    }
	  }
      }
      
	
#endif // KERNING      
      // adjust the rect for the offsets
      r->w = delta ;      
      if (this->bbXOff < 0){	
	r->x = p->x + this->bbXOff;
	r->w -= this->bbXOff;
      }
      else
	r->x = p->x;
      
      r->y = p->y - this->bbYOff - this->bbh ;      
      r->h = this->bbh;
      
      
      return delta;
    }
  

  

  int render_char_width(const struct FONT_CHAR *this, const struct FONT_CHAR *next,const struct FONT *font)
    {
      int i;
      int delta;
      const struct KERN_INFO *ki;

      // distance to the next char origin.
      // can be modified by ligatures or kerning.
      delta = this->dwidth;

#ifdef KERNING
      if (this->kernNum && next){
	for (i=this->kernIndex; i < this->kernNum + this->kernIndex;i++)
	  {
	    ki= &(font->ki[i]);
	    if (next->encoding == ki->encoding){
	      delta += ki->offset;
	    }
	  }
      }
      
	
#endif // KERNING      

      return delta;
    }
  
  void unionRect(Rect *r1, Rect *r2)
    {
      int x1,x2;
      if (!r2->w || !r2->h)
	return;
      if (!r1->w || !r1->h) {
	*r1=*r2;
	return;
      }
      
      x1 = MIN(r1->x,r2->x);
      x2 = MAX(r1->x+r1->w,r2->x+r2->w);
      r1->w = x2-x1;
      r1->x = x1;      
      x1 = MIN(r1->y,r2->y);
      x2 = MAX(r1->y+r1->h,r2->y+r2->h);
      r1->h = x2-x1;
      r1->y = x1;
      
    }
  
  void expandRect(Rect *r,int i)
    {
      r->x = MAX(0,r->x-i);
      r->y = MAX(0,r->y-i);
      r->w += i*2;
      r->h += i*2;
      if ((r->x+r->w)> LCD_WIDTH)
	r->w = LCD_WIDTH - r->x;
      if ((r->y+r->h)> LCD_HEIGHT)
	r->h = LCD_HEIGHT - r->x;
    }
  void render_string_rect(char *inbuf,const struct FONT *font,const Point *dest,Rect *sRect)
    {
      Point p;      
      char *p1 = inbuf;
      char *p2 = p1+1;
      const struct FONT_CHAR *c1,*c2;
      const struct FONT_CHAR *li;
      int i;
      int mode;
      Rect r;
      
      sRect->x = dest->x;
      sRect->y = dest->y;
      sRect->w = 0;
      sRect->h = 0;
      
      p = *dest;
      mode = GF_NONE;
      
      while (*p2){
	c1= &(font->fc[*p1++ - font->encodingOffset]);
	c2= &(font->fc[*p2++ - font->encodingOffset]);
#ifdef LIGATURES
	if (LIGATURE_NUM(c1->ligatureInfo)){
	  for (i=LIGATURE_INDEX(c1->ligatureInfo); i < LIGATURE_NUM(c1->ligatureInfo) + LIGATURE_INDEX(c1->ligatureInfo);i++){
	    li= &(font->li[i]);
	    if (c2->encoding == li->encoding){
	      c1 = li;
	      p1++;
	      p2++;
	      break;	      
	    }
	  }
	}
#endif // LIGATURES      

	p.x += render_char_rect(c1,c2,font,&p,&r);	
	unionRect(sRect,&r);
      }
      c1= &(font->fc[*p1++ - font->encodingOffset]);
      p.x += render_char_rect(c1,0x0,font,&p,&r);	
      unionRect(sRect,&r);
      expandRect(sRect,1);
      return ;
      
    }

	    
  int render_string_width(char *inbuf,const struct FONT *font,const Point *dest)
    {

      Point p;      
      char *p1 = inbuf;
      char *p2 = p1+1;
      const struct FONT_CHAR *c1,*c2;
      const struct FONT_CHAR *li;
      int i;
      int mode;
      

      
      p = *dest;
      mode = GF_NONE;
      
      while (*p2){
	c1= &(font->fc[*p1++ - font->encodingOffset]);
	c2= &(font->fc[*p2++ - font->encodingOffset]);
#ifdef LIGATURES
	if (LIGATURE_NUM(c1->ligatureInfo)){
	  for (i=LIGATURE_INDEX(c1->ligatureInfo); i < LIGATURE_NUM(c1->ligatureInfo) + LIGATURE_INDEX(c1->ligatureInfo);i++){
	    li= &(font->li[i]);
	    if (c2->encoding == li->encoding){
	      c1 = li;
	      p1++;
	      p2++;
	      break;	      
	    }
	  }
	}
#endif // LIGATURES      

	p.x += render_char_width(c1,c2,font);	
      
      }
      c1= &(font->fc[*p1++ - font->encodingOffset]);
      p.x += render_char_width(c1,0x0,font);	      
      return (p.x - dest->x);
      
    }
  
  void render_string(char *inbuf,const struct FONT *font,const Point *dest,int mode)
    {
      Point p;      
      char *p1 = inbuf;
      char *p2 = p1+1;
      const struct FONT_CHAR *c1,*c2;
      const struct FONT_CHAR *li;
      int i;
      

      
      p = *dest;
      
      while (*p2){
	c1= &(font->fc[*p1++ - font->encodingOffset]);
	c2= &(font->fc[*p2++ - font->encodingOffset]);
#ifdef LIGATURES
	if (LIGATURE_NUM(c1->ligatureInfo)){
	  for (i=LIGATURE_INDEX(c1->ligatureInfo); i < LIGATURE_NUM(c1->ligatureInfo) + LIGATURE_INDEX(c1->ligatureInfo);i++){
	    li= &(font->li[i]);
	    if (c2->encoding == li->encoding){
	      c1 = li;
	      p1++;
	      p2++;
	      break;	      
	    }
	  }
	}
#endif // LIGATURES      

	p.x += render_char(c1,c2,font,&p,mode);	
      
      }
      c1= &(font->fc[*p1++ - font->encodingOffset]);
      render_char(c1,0x0,font,&p,mode);	      

    }
  
  
  void render_string_NOL(char *inbuf,const struct FONT *font,const Point *dest,int mode)
    {
      Point p;      
      char *p1 = inbuf;
      char *p2 = p1+1;
      const struct FONT_CHAR *c1,*c2;
      

      
      p = *dest;
      
      while (*p2){
	c1= &(font->fc[*p1++ - font->encodingOffset]);
	c2= &(font->fc[*p2++ - font->encodingOffset]);
	p.x += render_char(c1,c2,font,&p,GF_OR);	
      
      }
      c1= &(font->fc[*p1++ - font->encodingOffset]);
      render_char(c1,0x0,font,&p,GF_OR);	      

    }
  
  

  int render_char_NOK(const struct FONT_CHAR *this, const struct FONT_CHAR *next,const struct FONT *font,const Point *dest,int mode)
    {
      int x;
      int y;
      const  uint8_t *p; 
      uint8_t b;
      uint8_t destByte;
      uint8_t destPtr;
      uint8_t bit;
      int i,j,k;
      int delta;

      
      
      

      
      p = font->bitmap + this->offset;
      // distance to the next char origin.
      // can be modified by ligatures or kerning.
      delta = this->dwidth;
      

#if 0
      sprintf(buf,"dx:%d",dest->x);	  
      call LCD.gf_draw_string(buf,0,&pt,GF_OR);
      pt.y += 12;

      x = dest->x + this->bbXOff;
      sprintf(buf,"x:%d",x);	  
      call LCD.gf_draw_string(buf,0,&pt,GF_OR);
      pt.y += 12;

      destPtr = x % 8;
      sprintf(buf,"dp:%d",destPtr);	  
      call LCD.gf_draw_string(buf,0,&pt,GF_OR);
      pt.y += 12;
#endif
      
      for (i=0; i < this->bbh; i ++){
	x = dest->x + this->bbXOff;
	// should we add one here?
	// if we dont add one then the letters sit on top of the line
	// e.g if ydest = 75 and we draw a C we can see the bottom of the C and the line beneath it.
	// also if we draw a p the 1 pixel down is eaten by the line so I/m guessing that
	// a 1 is necesary here. can ask andy later.
	y = dest->y - this->bbYOff - this->bbh + i + 1;
	destByte = lcd_read_byte(x,y);      
	// how many bytes wide is this bitmap?	
	for (j = 0; j < this->byteWidth; j++) {
	  // this is a byte of our character
	  b = *p++;
#if 0
	  sprintf(buf,"S:%x",b);	  
	  call LCD.gf_draw_string(buf,0,&pt,GF_OR);
	  pt.y += 12;
#endif

	  // where in the lcd byte we start dumping the letter
	  // count down char bytes b7 b6 b5 b4 b3 b2 b1 b0
	  // count up lcd byte l0 l1 l2 l3 l4 l5 l6 l7
	  destPtr = x % 8;
	  // bitwise spit out the char
#if 0
	  pt.y += 12;
	  pt.x= 10;	  
#endif
	  for (k=0; k < 8; k++){
	    // the char bit we are currently dealing with
	    bit = (b & (1 << (7-k))) >> (7-k);
#if 0
	    // all right
	    sprintf(buf,"%x ",bit);	  
	    call LCD.gf_draw_string(buf,0,&pt,GF_OR);
	    pt.x += 12;	    
#endif

	    switch (mode){
	    case GF_OR:
	      destByte |= bit << destPtr ;
	      break;
	    case GF_COPY:
	      destByte &= ~(1<<destPtr);
	      destByte |= bit << destPtr ;
	      break;
			     
	    }

	    destPtr++;
	    if ((destPtr %8) == 0){
	      // we have filled tha last of the lcd byte so write it out
	      //debug
#if 0
	      sprintf(buf,"D8: %x ",destByte);	  
	      call LCD.gf_draw_string(buf,0,&pt,GF_OR);
	      pt.x += 52;
#endif

	      lcd_write_byte(x,y,destByte);
	      x += 8;
	      // grab the next dest byte
	      destByte = lcd_read_byte(x,y);
	      // start filling in from the beginning
	      destPtr = 0;
	    }
	  
	  } // end of the char byte
	} // end of the row of character bytes
	// here we write out the dest byte and reset our x to the original x value
#if 0
	sprintf(buf,"DE: %x ",destByte);	  
	call LCD.gf_draw_string(buf,0,&pt,GF_OR);
	pt.y += 12;
	pt.x = 10;	
#endif
	lcd_write_byte(x,y,destByte);
      }

      //lcd_write_byte(0,110,0x80);
      return delta;
    }
  

  void render_string_NOK(char *inbuf,const struct FONT *font,const Point *dest,int mode)
    {
      Point p;      
      char *p1 = inbuf;
      char *p2 = p1+1;
      const struct FONT_CHAR *c1,*c2;

      p = *dest;
      
      while (*p2){
	c1= &(font->fc[*p1++ - font->encodingOffset]);
	c2= &(font->fc[*p2++ - font->encodingOffset]);
	p.x += render_char_NOK(c1,c2,font,&p,GF_OR);	
      
      }
      c1= &(font->fc[*p1++ - font->encodingOffset]);
      render_char(c1,0x0,font,&p,GF_OR);	      

    }
  

  
  
  async command result_t  LCD.test()
    {
      const struct FONT *f;
      const struct FONT_CHAR *c1;
      Point p;
      int i;
      
      

#if 0
      for (i=0; i < 120; i+=5)
	call LCD.gf_draw_line(0,i,160,i);      
      for (i=0; i < 160; i+=5)
	call LCD.gf_draw_line(i,0,i,120);      


	
      
      
      // let's try to draw a Q
      f = &Helvetica_Medium_R_10_font;
      c1= &(f->fc['B'-f->encodingOffset]);
      p.x = 5;


      p.y = 25;
      render_string("AVE FAT fish",&Helvetica_Medium_R_18_font,&p,GF_OR);

      p.y = 50;
      render_string_NOL("AVE FAT fish",&Helvetica_Medium_R_18_font,&p,GF_OR);

      
      //render_char(c1,NULL,f,&p,GF_OR);
      p.y = 65;
      render_string_NOK("AVERY FAT jar fish flip",&Helvetica_Medium_R_10_font,&p,GF_OR);

      p.y = 80;
      render_string_NOL("AVERY FAT jar fish flip",&Helvetica_Medium_R_10_font,&p,GF_OR);

      p.y = 95;
      render_string("AVERY FAT jar fish flip",&Helvetica_Medium_R_10_font,&p,GF_OR);

      //call LCD.gf_draw_line(1,80,160,80);
      
      //render_string("A",&Helvetica_Medium_R_10_font,&p,GF_OR);
      



      //call LCD.gf_draw_line(5,100,100,100);
      
#endif
 {
   
   int page;      
   int screen;
   int row ;
   int x=0;
   int y=90;
   
   
      
   page = GF_PAGE(x,y);
   screen = GF_SCREEN_NAME(x,y);
    row = GF_ROW(x,y);

   send_lcd_cmd(LCD_PAGE | (page & 0x0f) ,screen);
   send_lcd_cmd(LCD_COL_HI | ((row & 0xf0)>>4),screen);
   send_lcd_cmd(LCD_COL_LO | (row & 0x0f),screen);

   set_lcd_byte(0xff,screen);
   set_lcd_byte(0x55,screen);
   set_lcd_byte(0xff,screen);
   set_lcd_byte(0xaa,screen);
   set_lcd_byte(0xff,screen);

   // check next page
   page +=1;   
   send_lcd_cmd(LCD_PAGE | (page & 0x0f) ,screen);
   send_lcd_cmd(LCD_COL_HI | ((row & 0xf0)>>4),screen);
   send_lcd_cmd(LCD_COL_LO | (row & 0x0f),screen);

   set_lcd_byte(0xff,screen);
   set_lcd_byte(0x55,screen);
   set_lcd_byte(0xff,screen);
   set_lcd_byte(0xaa,screen);
   set_lcd_byte(0xff,screen);

   // page +2 check row +1
   page += 2;   
   send_lcd_cmd(LCD_PAGE | (page & 0x0f) ,screen);
   send_lcd_cmd(LCD_COL_HI | ((row & 0xf0)>>4),screen);
   send_lcd_cmd(LCD_COL_LO | (row & 0x0f),screen);

   set_lcd_byte(0xff,screen);
   row ++;
   send_lcd_cmd(LCD_COL_HI | ((row & 0xf0)>>4),screen);
   send_lcd_cmd(LCD_COL_LO | (row & 0x0f),screen);

   set_lcd_byte(0x55,screen);
   row ++;
   send_lcd_cmd(LCD_COL_HI | ((row & 0xf0)>>4),screen);
   send_lcd_cmd(LCD_COL_LO | (row & 0x0f),screen);

   set_lcd_byte(0xff,screen);
      row ++;
   send_lcd_cmd(LCD_COL_HI | ((row & 0xf0)>>4),screen);
   send_lcd_cmd(LCD_COL_LO | (row & 0x0f),screen);

   set_lcd_byte(0xaa,screen);
   row ++;
   send_lcd_cmd(LCD_COL_HI | ((row & 0xf0)>>4),screen);
   send_lcd_cmd(LCD_COL_LO | (row & 0x0f),screen);

   set_lcd_byte(0xff,screen);

   // check reads for incr behaviour
   page +=2;
   row = GF_ROW(x,y);

   send_lcd_cmd(LCD_PAGE | (page & 0x0f) ,screen);
   send_lcd_cmd(LCD_COL_HI | ((row & 0xf0)>>4),screen);
   send_lcd_cmd(LCD_COL_LO | (row & 0x0f),screen);

   set_lcd_byte(0xff,screen);
   get_lcd_byte(screen); // dummy   
   set_lcd_byte(0x55,screen);
   get_lcd_byte(screen); // dummy   
   set_lcd_byte(0xff,screen);
   get_lcd_byte(screen); // dummy   
   set_lcd_byte(0xaa,screen);
   get_lcd_byte(screen); // dummy   
   set_lcd_byte(0xff,screen);


   // check reads for incr behaviour w/ read modify write 
   page +=2;
   row = GF_ROW(x,y);

   send_lcd_cmd(LCD_PAGE | (page & 0x0f) ,screen);
   send_lcd_cmd(LCD_COL_HI | ((row & 0xf0)>>4),screen);
   send_lcd_cmd(LCD_COL_LO | (row & 0x0f),screen);

   send_lcd_cmd(LCD_RMW,screen);

   set_lcd_byte(0xff,screen);
   get_lcd_byte(screen); // dummy
   get_lcd_byte(screen); // real
   set_lcd_byte(0x55,screen);
   get_lcd_byte(screen); // dummy
   get_lcd_byte(screen); // real
   set_lcd_byte(0xff,screen);
   get_lcd_byte(screen); // dummy
   get_lcd_byte(screen); // real
   set_lcd_byte(0xaa,screen);
   get_lcd_byte(screen); // dummy
   get_lcd_byte(screen); // real
   set_lcd_byte(0xff,screen);
   send_lcd_cmd(LCD_END,screen);   



   // check where rmw dumps us out at
   page +=2;
   send_lcd_cmd(LCD_PAGE | (page & 0x0f) ,screen);
   set_lcd_byte(0xff,screen);
   set_lcd_byte(0x55,screen);
   set_lcd_byte(0xff,screen);
   set_lcd_byte(0xaa,screen);
   set_lcd_byte(0xff,screen);



   
 }
 
      
      return SUCCESS;
    
    }




  
      
}

