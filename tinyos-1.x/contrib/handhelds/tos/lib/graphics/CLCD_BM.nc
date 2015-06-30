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
 * This is an implementation of the CLCD module,  Blocking.
 */

/**
 * @author Brian Avery
 */

includes lcd_types;








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


// shouldnt need to toggle cs at all as it is only one on bus but will try for completeness
#define LCD_IDLE {TOSH_SET_LCD_RS_PIN();TOSH_SET_LCD_WR_L_PIN();TOSH_SET_LCD_RD_L_PIN();TOSH_SET_LCD_CS_L_PIN(); }








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
#define LCD_NOP           (0xe3)




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


module CLCD_BM {
#if 0
  uses 
    {
      interface Leds;
      interface StrOutput;

    }
#endif
  
  provides
    {
      interface LCD;
    //interface StdControl;
    }
  
}

implementation
{
  enum {
    FONT_HELVETICA_R_10,
    FONT_HELVETICA_O_10,
    FONT_HELVETICA_R_12,
    FONT_HELVETICA_O_12,
    FONT_HELVETICA_R_14,
    FONT_HELVETICA_R_18,
    FONT_HELVETICA_R_24
  };


  // these contain the const struct defs for a test image and the fonts forcing them to be in ROM
  // they are part of the implementation thus they are included here.

  //#include "font.h"
  
  uint8_t busy;
  void render_string(char *inbuf,const struct FONT *font,const Point *dest,int mode);
  

  
  static const struct _Point dog = {10,10};

#if 0
#define LCD_CMD_DELAY {volatile int i;for (i=0;i < 2; i++);}
#else
#define LCD_CMD_DELAY {}
#endif
  // active pause that is 3 instr per number
void __inline__ brief_pause(register unsigned int n)
{
  volatile int i;
  for (i=0; i < n; i++);
  
}

 inline	 static uint8_t read_lcd_index_byte()
    {
      uint8_t b;
      
      // latch data on data port
#if HANDLE_LCD_BITWISE
      TOSH_MAKE_LCD_D0_INPUT();
      TOSH_MAKE_LCD_D1_INPUT();
      TOSH_MAKE_LCD_D2_INPUT();
      TOSH_MAKE_LCD_D3_INPUT();
      TOSH_MAKE_LCD_D4_INPUT();
      TOSH_MAKE_LCD_D5_INPUT();
      TOSH_MAKE_LCD_D6_INPUT();
      TOSH_MAKE_LCD_D7_INPUT();

#else
#error "ONLY BITWISE WORKS FOR NOW"
#endif
      // Assert RS Index mode
      TOSH_CLR_LCD_RS_PIN();
      // assetr cs
      TOSH_CLR_LCD_CS_L_PIN();
      // read cmd start
      TOSH_CLR_LCD_RD_L_PIN();

      b = 0x00;
      b |= (TOSH_READ_LCD_D0_PIN() << 0);
      b |= (TOSH_READ_LCD_D1_PIN() << 1);
      b |= (TOSH_READ_LCD_D2_PIN() << 2);
      b |= (TOSH_READ_LCD_D3_PIN() << 3);
      b |= (TOSH_READ_LCD_D4_PIN() << 4);
      b |= (TOSH_READ_LCD_D5_PIN() << 5);
      b |= (TOSH_READ_LCD_D6_PIN() << 6);
      b |= (TOSH_READ_LCD_D7_PIN() << 7);

      
      
      //latch it on rising edge of the write
      TOSH_SET_LCD_RD_L_PIN();
      // assetr cs
      TOSH_SET_LCD_CS_L_PIN();

      LCD_IDLE;

      return b;
      
    }
  


 inline	 static uint8_t read_lcd_byte()
    {
      uint8_t b;
      
      // latch data on data port
#if HANDLE_LCD_BITWISE
      TOSH_MAKE_LCD_D0_INPUT();
      TOSH_MAKE_LCD_D1_INPUT();
      TOSH_MAKE_LCD_D2_INPUT();
      TOSH_MAKE_LCD_D3_INPUT();
      TOSH_MAKE_LCD_D4_INPUT();
      TOSH_MAKE_LCD_D5_INPUT();
      TOSH_MAKE_LCD_D6_INPUT();
      TOSH_MAKE_LCD_D7_INPUT();

#else
#error "ONLY BITWISE WORKS FOR NOW"
#endif

      // test for completeness
      TOSH_CLR_LCD_CS_L_PIN();
      // deAssert RS Index mode
      TOSH_SET_LCD_RS_PIN();
      // read cmd start
      TOSH_CLR_LCD_RD_L_PIN();

      b = 0x00;
      b |= (TOSH_READ_LCD_D0_PIN() << 0);
      b |= (TOSH_READ_LCD_D1_PIN() << 1);
      b |= (TOSH_READ_LCD_D2_PIN() << 2);
      b |= (TOSH_READ_LCD_D3_PIN() << 3);
      b |= (TOSH_READ_LCD_D4_PIN() << 4);
      b |= (TOSH_READ_LCD_D5_PIN() << 5);
      b |= (TOSH_READ_LCD_D6_PIN() << 6);
      b |= (TOSH_READ_LCD_D7_PIN() << 7);

      
      
      //latch it on rising edge of the write
      TOSH_SET_LCD_RD_L_PIN();      
      LCD_IDLE;

      return b;
      
    }
  

 
 inline static void send_lcd_index_byte(uint8_t lcdValue)
    {
      TOSH_MAKE_LCD_D0_OUTPUT();
      TOSH_MAKE_LCD_D1_OUTPUT();
      TOSH_MAKE_LCD_D2_OUTPUT();
      TOSH_MAKE_LCD_D3_OUTPUT();
      TOSH_MAKE_LCD_D4_OUTPUT();
      TOSH_MAKE_LCD_D5_OUTPUT();
      TOSH_MAKE_LCD_D6_OUTPUT();
      TOSH_MAKE_LCD_D7_OUTPUT();

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
#error no way jose
#endif

      // Assert RS Index mode
      TOSH_CLR_LCD_RS_PIN();
      // assert CS
      TOSH_CLR_LCD_CS_L_PIN();
      // write cmd start
      TOSH_CLR_LCD_WR_L_PIN();
      //latch it on rising edge of the write
      TOSH_SET_LCD_WR_L_PIN();
      // assert CS
      TOSH_SET_LCD_CS_L_PIN();      
      LCD_IDLE;
    }
  

  inline static void send_lcd_data_byte(uint8_t lcdValue)
    {
      TOSH_MAKE_LCD_D0_OUTPUT();
      TOSH_MAKE_LCD_D1_OUTPUT();
      TOSH_MAKE_LCD_D2_OUTPUT();
      TOSH_MAKE_LCD_D3_OUTPUT();
      TOSH_MAKE_LCD_D4_OUTPUT();
      TOSH_MAKE_LCD_D5_OUTPUT();
      TOSH_MAKE_LCD_D6_OUTPUT();
      TOSH_MAKE_LCD_D7_OUTPUT();

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
#error "Not here either"
#endif

      // assert cs
      TOSH_CLR_LCD_CS_L_PIN();
      // Assert RS Data mode
      TOSH_SET_LCD_RS_PIN();
      // write cmd start
      TOSH_CLR_LCD_WR_L_PIN();
      //latch it on rising edge of the write
      TOSH_SET_LCD_WR_L_PIN();      
      LCD_IDLE;
    }


  inline static void send_lcd_cmd(uint8_t index_reg, uint16_t value)
    {
      uint8_t myByte;
      
      send_lcd_index_byte(0x00);
      send_lcd_index_byte(index_reg);
      myByte = (value & 0xff00) >> 8;
      send_lcd_data_byte(myByte);
      myByte = (value & 0x00ff);
      send_lcd_data_byte(myByte);

    }

  
  inline static uint16_t read_lcd_cmd(uint8_t index_reg)
    {
      uint16_t res;
      uint8_t tmp;
      
      send_lcd_index_byte(0x00);
      send_lcd_index_byte(index_reg);
      res = 0x00;
      tmp = read_lcd_byte();      
      res = (tmp << 8);
      tmp = read_lcd_byte();
      res |= tmp;
      return res;
      
    }

    inline static uint16_t read_lcd_status()
    {
      uint16_t res;
      uint8_t tmp;
      
      res = 0x00;
      tmp = read_lcd_index_byte();      
      res = (tmp << 8);
      tmp = read_lcd_index_byte();
      res |= tmp;
      return res;
      
    }
  

  
  //XXX 
  static inline void set_lcd_byte(uint8_t lcdValue, uint8_t LeftRight_CS_N)
    {
  
    }

  // assumes we are in a default write state
  // may change later to track it if we hafta care
  //XXX
  static inline uint8_t get_lcd_byte(uint8_t LeftRight_CS_N)
    {


      return 0x00;
  
    }

  // this writes out val to the byte containing x,y
  // it does *not* write out a byte from x,y
  // e.g. if (x,y) = (0,11) and val = 0x69 it writes 0x69
  // starting from (0,8)
  void lcd_write_byte(int x,int y, uint8_t val)
    {
  
    }


  
  // this reads the  val to the byte containing x,y
  // it does *not* read out a byte from x,y
  // e.g. if (x,y) = (0,11) it reads the val
  // starting from (0,8)
  uint8_t lcd_read_byte(int x,int y)
    {
      return 0;
  
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


  
  void gf_draw_char(const char c,const GF_Font *f,const Point *dest,int mode)
    {
      Rect r;
      Point p = *dest;
  
      r.x = f->fc[c-f->ascii_min].x;
      r.y = f->fc[c-f->ascii_min].y;
      r.w = f->fc[c-f->ascii_min].width;
      r.h = f->fc[c-f->ascii_min].height;

      p.y += r.y;  
      gf_copy_RLE_rect(&r,&(f->fi),&p,mode);
  
    }


  void gf_draw_point(uint8_t x,uint8_t y)
    {
      uint8_t val;
  

  
    }






  /*********************************************************************************************************************************************
   *	
   *  Below is the actual interface definitions
   *
   *
  *********************************************************************************************************************************************/
  

  async command result_t LCD.init() {
    volatile int i;
    atomic {
      busy = 0;
      
      dbg(DBG_BOOT, "LCD: initialized.\n");
    }

    TOSH_SET_ADC_6_PIN(); // debugging XXX

    // put the lcd in reset
    TOSH_CLR_LCD_RESET_L_PIN();
    for (i=0; i < 25000; i++); // wait a bit important to be well defined
    for (i=0; i < 25000; i++); // wait a bit important to be well defined
    for (i=0; i < 25000; i++); // wait a bit important to be well defined
    for (i=0; i < 25000; i++); // wait a bit important to be well defined
    // take it out of reset
    TOSH_SET_LCD_RESET_L_PIN();    
    LCD_IDLE;
    for (i=0; i < 25000; i++); // wait a bit
    
    send_lcd_cmd( 0x00,0x0001);          // osc on
    for (i=0; i < 25000; i++); // wait a bit
    for (i=0; i < 25000; i++); // wait a bit
    
    send_lcd_cmd( 0x01,0x0013);          // duty cycle 1/160
    send_lcd_cmd( 0x02,0x0000);          // waveform b/c
    send_lcd_cmd( 0x04,0x0664);          // contrast
    send_lcd_cmd( 0x03,0x6578);          // power1
    send_lcd_cmd( 0x0c,0x0005);          // power2
    for (i=0; i < 25000; i++); // wait a bit dunno why
    for (i=0; i < 25000; i++); // wait a bit dunno why
    send_lcd_cmd( 0x03,0x4d78);          // power1 again, dunno why we reset it, from sample code
    send_lcd_cmd( 0x05,0x0030);          // entry mode - 65K colors
    send_lcd_cmd( 0x06,0x0000);          // cmp reg
    send_lcd_cmd( 0x07,0x0001);          // display control -- display asleep here
    send_lcd_cmd( 0x0b,0x0100);          // frame
    send_lcd_cmd( 0x11,0x0000);          // vert scroll
    send_lcd_cmd( 0x14,0xa000);          // screen 1
    send_lcd_cmd( 0x15,0x0000);          // screen 2
    send_lcd_cmd( 0x16,0x8300);          // hram
    send_lcd_cmd( 0x17,0x9f00);          // vram    
    
    send_lcd_cmd( 0x20,0x0000);          // write mask
    send_lcd_cmd( 0x21 ,0x0000);          // ram address



    TOSH_CLR_ADC_6_PIN(); // debugging XXX
    // test read
    read_lcd_cmd(0x00);
    read_lcd_status();

    // vain attempt at a reset
    send_lcd_index_byte(0x00);
    send_lcd_index_byte(0x00);
    send_lcd_index_byte(0x00);
    send_lcd_index_byte(0x00);
    
    
    send_lcd_cmd( 0x04,0x0001);          // contrast
    read_lcd_status();
    send_lcd_cmd( 0x06,0x0000);          // cmp reg
    read_lcd_status();
    send_lcd_cmd( 0x04,0x0002);          // contrast
    read_lcd_status();
    send_lcd_cmd( 0x04,0x0004);          // contrast
    read_lcd_status();
    send_lcd_cmd( 0x04,0x0008);          // contrast
    read_lcd_status();
    send_lcd_cmd( 0x04,0x0010);          // contrast
    read_lcd_status();
    send_lcd_cmd( 0x04,0x0020);          // contrast
    read_lcd_status();
    send_lcd_cmd( 0x04,0x0040);          // contrast
    read_lcd_status();
    send_lcd_cmd( 0x04,0x0080);          // contrast
    read_lcd_status();


    send_lcd_cmd( 0x07,0x0003);          // display control - on

    return SUCCESS;
  }


  async command result_t LCD.clear() {
    
    return SUCCESS;
  }


  async command result_t LCD.backlightOn() {
#if 0
    TOSH_SET_LCD_BACKLIGHT_PIN();
#endif
    return SUCCESS;    
  }

  async command result_t LCD.backlightOff() {
#if 0
    TOSH_CLR_LCD_BACKLIGHT_PIN();
#endif
    return SUCCESS;
  }

  async command result_t LCD.fill(uint16_t color) {
    int i;
    int j;

    send_lcd_cmd( 0x21 ,0x0000);          // ram address
    for (i=0; i < 160; i++)
      for (j=0; j < 128; j++)
	send_lcd_cmd( 0x22 ,color);          // data color
    
    return SUCCESS;
  }
  
  async command  result_t LCD.gf_draw_string(char *str,int fontNum,Point *dest,int mode)
    { 

#if 0
      render_string(str,MWfonts[fontNum],dest,mode);
#endif
      return SUCCESS;
    }

  async command  result_t LCD.gf_draw_string_right(char *str,int fontNum,Point *dest,int mode)
    { 

#if 0
      render_string(str,MWfonts[fontNum],dest,mode);
#endif
      return SUCCESS;
    }

  async command  result_t LCD.gf_draw_string_center(char *str,int fontNum,Point *dest,int mode)
    { 

#if 0
      render_string(str,MWfonts[fontNum],dest,mode);
#endif
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
  
      curY = r->y;
      while (curY < yEnd) {
	curX = r->x;    
	while (curX < xEnd) {
	  mask = 0xff;
	  b = 0x0;      
	  if (curX%8){
	    // beginning not byte aligned
	    b = lcd_read_byte(curX - curX%8,curY);
	    // mask off the end part we are changing
	    mask &= (0xff >> (8-curX%8));

        
	    // mask off any beginning part we are changing
	    if (xEnd  < (curX + (8-curX%8))){
	      mask |= (0xff << (xEnd%8));
	    }
	    mask = (~mask)&0xff;
	  }
	  else if (xEnd < (curX+8)){
	    // ending not byte aligned
	    b = lcd_read_byte(curX,curY);
	    // mask off any beginning part we are changing
	    mask &= (0xff << (xEnd%8));
	    mask = (~mask)&0xff;
	  }      
	  b &= ~mask;
	  b |= (val&mask);
	  lcd_write_byte(curX,curY,b);          
	  curX += (8-curX%8);
	}
	curY++;        
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




  async command  result_t LCD.gf_draw_line(int x0,int l_y0,int x1,int l_y1)
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
	  gf_draw_point(x0,l_y0);
	} else {
	  gf_draw_point(l_y0,x0);
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
  
  // FONT CHAR *next is used for kerning/ligature info
  // the fxn returns where the next char origin should be deltax only
  int render_char(const struct FONT_CHAR *this, const struct FONT_CHAR *next,const struct FONT *font,const Point *dest,int mode)
    {
#if 0
      int x;
      int y;
      const  uint8_t *p; 
      uint8_t b;
      uint8_t destByte;
      uint8_t destPtr;
      uint8_t bit;
      int i,j,k;
      int delta;
      const struct KERN_INFO *ki;
      
      
      
#if 0
      Point pt = {10,10};
      char buf[24] = "z";      

      pt.x = 10;
      pt.y = 10;
#endif

      
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
	    case GF_NONE:
	      // probly being used to get the str width;
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
#endif
      return 0;
      
    }



  int render_string_width(char *inbuf,const struct FONT *font,const Point *dest,int mode)
    {
#if 0
      Point p;      
      char *p1 = inbuf;
      char *p2 = p1+1;
      const struct FONT_CHAR *c1,*c2;
      const struct FONT_CHAR *li;
      int i;
      

      
      p = *dest;
      mode = GF_NONE;
      
      while (*p2){
	c1= &(font->fc[*p1++ - font->encodingOffset]);
	c2= &(font->fc[*p2++ - font->encodingOffset]);
#ifdef LIGATURES
	if (c1->ligatureNum){
	  for (i=c1->ligatureIndex; i < c1->ligatureNum + c1->ligatureIndex;i++){
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

	p.x += render_char(c1,c2,font,&p,GF_OR);	
      
      }
      c1= &(font->fc[*p1++ - font->encodingOffset]);
      p.x += render_char(c1,0x0,font,&p,GF_OR);	      
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
	if (c1->ligatureNum){
	  for (i=c1->ligatureIndex; i < c1->ligatureNum + c1->ligatureIndex;i++){
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
#endif

    }
  
  
  void render_string_NOL(char *inbuf,const struct FONT *font,const Point *dest,int mode)
    {
#if 0
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
#endif

    }
  
  

  int render_char_NOK(const struct FONT_CHAR *this, const struct FONT_CHAR *next,const struct FONT *font,const Point *dest,int mode)
    {
#if 0
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
#endif
      return 0;
      
    }
  

  void render_string_NOK(char *inbuf,const struct FONT *font,const Point *dest,int mode)
    {
#if 0
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
#endif

    }
  
  async command uint16_t  LCD.read(uint16_t addr)
    {
      uint16_t val;

      val = read_lcd_cmd((addr & 0xff));
      return val;
      
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
      return SUCCESS;
    
    }




  
      
}

