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
 * This is an implementation of the OLED LCD module, Blocking.
 */

/**
 * @author Brian Avery
 */

includes lcd_types;
includes icons;
includes beth_logan;





// make sure we dont overwrite stuff
#define GF_CHECK_BOUNDARY 1

#define MIN(a,b) ( ((a) < (b))?(a):(b))
#define MAX(a,b) ( ((a) > (b))?(a):(b))




#define LCD_IDLE {TOSH_CLR_LCD_ENABLE_PIN();TOSH_SET_LCD_CMD_L_PIN();TOSH_SET_LCD_WR_L_PIN();}








/* LCD Commands data Table 11 */
// 2 byte follow 
#define LCD_COL_SET		  (0x15)
// 2 byte follow 
#define LCD_ROW_SET		  (0x75)
// 1 byte follow 
#define LCD_CONTRAST_SET	  (0x81)
// 0 byte follow 
#define LCD_QUARTER_CURRENT       (0x84)
// 0 byte follow 
#define LCD_HALF_CURRENT	  (0x85)
// 0 byte follow 
#define LCD_FULL_CURRENT	  (0x86)
// 1 byte follow 
#define LCD_REMAP		  (0xa0)
// 1 byte follow 
#define LCD_START_LINE_SET        (0xa1)
// 1 byte follow 
#define LCD_DISPLAY_OFFSET        (0xa2)
// 0 byte follow 
#define LCD_PIXELS_NORMAL         (0xa4)
// 0 byte follow 
#define LCD_PIXELS_ON             (0xa5)
// 0 byte follow 
#define LCD_PIXELS_OFF	         (0xa6)
// 0 byte follow 
#define LCD_PIXELS_INVERT        (0xa7)
// 1 byte follow 
#define LCD_MULTIPLEX_RATIO_SET   (0xa8)
// 1 byte follow 
#define LCD_DC_CONVERTER_SET	  (0xad)
// 0 byte follow 
#define LCD_OFF			  (0xae)
// 0 byte follow 
#define LCD_ON			  (0xaf)
// 1 byte follow 
#define LCD_SEGMENT_VOLTAGE_SET   (0xbf)
// 1 byte follow 
#define LCD_COMH_VOLTAGE_SET      (0xbe)
// 1 byte follow 
#define LCD_PRECHARGE_VOLTAGE_SET (0xbc)
// 1 byte follow 
#define LCD_PHASE_LENGTH_SET	  (0xb1)
// 1 byte follow 
#define LCD_ROW_PERIOD_SET	  (0xb2)
// 1 byte follow 
#define LCD_CLOCK_DIVISOR_SET	  (0xb3)
// 8 byte follow 
#define LCD_GREYSCALE_TABLE_SET   (0xb8)
// 0 byte follow 
#define LCD_NOP			  (0xe3)


module OLED_LCD_BM {
#if 0
  uses 
    {
      interface Leds;
      interface StrOutput;

    }
#endif
  
  provides    {
      interface LCD;
      interface OLED_TEST;      
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


  

  static uint8_t  read_lcd_status()
    {
      uint8_t swizzled_b,b;

      atomic
	{
	  LCD_DATA_DIR_PORT = LCD_DATA_READ; // settling?
	  TOSH_CLR_LCD_CMD_L_PIN();
	  TOSH_SET_LCD_ENABLE_PIN();
	  swizzled_b = LCD_DATA_IN_PORT;
	  LCD_IDLE;
	  LCD_DATA_DIR_PORT = LCD_DATA_WRITE;
	}

      b = (swizzled_b & 0xcf)|((swizzled_b & 0x20)>>1) | ((swizzled_b & 0x10)<<1);
      return b;
      
    }
  static void send_lcd_cmd(uint8_t lcdValue)
    {
      uint8_t lcdSwizzledValue;
      
      lcdSwizzledValue = (lcdValue & 0xcf)|((lcdValue & 0x20)>>1) | ((lcdValue & 0x10)<<1);
      
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
	  LCD_DATA_OUT_PORT = lcdSwizzledValue;                                // Data on bus
	}
      
#endif

      // write cmd start
      TOSH_CLR_LCD_CMD_L_PIN();
      TOSH_CLR_LCD_WR_L_PIN();
      //latch it on falling edge of the enable
      TOSH_SET_LCD_ENABLE_PIN();
      LCD_IDLE;

      
      
    }
  
  
    
  static  void set_lcd_byte(uint8_t lcdValue)
    {
      uint8_t lcdSwizzledValue;
      
      lcdSwizzledValue = (lcdValue & 0xcf)|((lcdValue & 0x20)>>1) | ((lcdValue & 0x10)<<1) ;
      

      
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
	LCD_DATA_OUT_PORT = lcdSwizzledValue;                                // Data on bus
      }
      
#endif

      // write  start
      TOSH_CLR_LCD_WR_L_PIN();
      //latch it on rising edge of the write
      TOSH_SET_LCD_ENABLE_PIN();      
      LCD_IDLE;


    }

  static uint8_t get_lcd_byte()
    {
      uint8_t b;
      uint8_t swizzled_b;
      
      

      TOSH_SET_LCD_WR_L_PIN();
      TOSH_SET_LCD_ENABLE_PIN();

      atomic{
	LCD_DATA_DIR_PORT = LCD_DATA_READ; // settling? 
	swizzled_b = LCD_DATA_IN_PORT;
	LCD_DATA_DIR_PORT = LCD_DATA_WRITE;
      }

      LCD_IDLE;
      b = (swizzled_b & 0xcf)|((swizzled_b & 0x20)>>1) | ((swizzled_b & 0x10)<<1);
      
      return b;
  
    }

  // this sets the pointer to the proper (byte aligned) row setting for a pt x,y
  // it does *not* set it to   x,y
  // e.g. if (x,y) = (0,11) and val = 0x69 it writes 0x69
  // starting from (0,8)
  void lcd_set_row(int x,int y)
    {
#if 0
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
#endif
    }



  
  // this writes out val to the byte containing x,y
  // it does *not* write out a byte from x,y
  // e.g. if (x,y) = (0,11) and val = 0x69 it writes 0x69
  // starting from (0,8)
  void lcd_write_byte(int x,int y, uint8_t val)
    {
#if 0
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

#endif

    }

  // this writes out val to the byte containing x,y
  // it does *not* write out a byte from x,y
  // e.g. if (x,y) = (0,11) and val = 0x69 it writes 0x69
  // starting from (0,8)
  // this version does not reset the row pointer so it
  // relies on the advancement of 1 row per write
  void lcd_write_byte_cont(int x,int y, uint8_t val)
    {
#if 0
      int screen;
      
      screen = GF_SCREEN_NAME(x,y);
      set_lcd_byte(val,screen);           
#endif
    }


  
  // this reads the  val to the byte 
  // it doesnt se the location it assumes we are in rmw mode
  uint8_t lcd_read_byte_cont(int x,int y)
    {
      uint8_t b;
      int screen;
      


#if 0
      screen = GF_SCREEN_NAME(x,y);
      get_lcd_byte(screen);           // dummy read necessary
      b = get_lcd_byte(screen);           // actual read


#endif
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
      

#if 0

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

#endif

      return b;
  
    }

  
  


  void gf_draw_point(uint8_t x,uint8_t y)
    {
#if 0
      uint8_t val;
  
      val = lcd_read_byte(x,y);
      val |= (1 << GF_PAGE_BIT(x,y));

      //lcd_write_byte(GF_SCREEN_NAME(x,y),GF_PAGE(x,y),GF_ROW(x,y),val);
      lcd_write_byte(x,y,val);
  
#endif
    }

  void gf_clear_point(uint8_t x,uint8_t y)
    {
#if 0
      uint8_t val;
  
      val = lcd_read_byte(x,y);
      val &= ~(1 << GF_PAGE_BIT(x,y));

      //lcd_write_byte(GF_SCREEN_NAME(x,y),GF_PAGE(x,y),GF_ROW(x,y),val);
      lcd_write_byte(x,y,val);
#endif
  
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
    TOSH_SET_LCD_RESET_L_PIN();
    for (i=0; i < 5000; i++); // wait a bit important to be well defined
    // put the lcd in reset again
    TOSH_CLR_LCD_RESET_L_PIN();
    for (i=0; i < 5000; i++); // wait a bit important to be well defined
    // take it out of reset
    TOSH_SET_LCD_RESET_L_PIN();


    LCD_IDLE;
    
    // now we begin guessing at the startup sequence for the display.
    // this startup sequence is fom the macro file in their dev kit
    send_lcd_cmd(LCD_FULL_CURRENT);          

    send_lcd_cmd(LCD_CONTRAST_SET);
    send_lcd_cmd(0x33);          

    /* com split odd/even
     * com remap
     * horz address incr
     * nibble remap -- D 76543210 -> D 32107654
     * disable column address remap
     */
    send_lcd_cmd(LCD_REMAP);
    //send_lcd_cmd(0x52);
    send_lcd_cmd(0x43); // left 2 right, swap nibbles

    send_lcd_cmd(LCD_START_LINE_SET);
    send_lcd_cmd(0x0);          


    send_lcd_cmd(LCD_DISPLAY_OFFSET);
    send_lcd_cmd(0);          


    send_lcd_cmd(LCD_PIXELS_NORMAL);

    send_lcd_cmd(LCD_MULTIPLEX_RATIO_SET);
    send_lcd_cmd(63);          

    send_lcd_cmd(LCD_ROW_PERIOD_SET);
    send_lcd_cmd(70);          

    send_lcd_cmd(LCD_CLOCK_DIVISOR_SET);
    send_lcd_cmd(65);          

    send_lcd_cmd(LCD_PHASE_LENGTH_SET);
    send_lcd_cmd(34);          

    send_lcd_cmd(LCD_PRECHARGE_VOLTAGE_SET);
    send_lcd_cmd(11);          

    send_lcd_cmd(LCD_DC_CONVERTER_SET);
    send_lcd_cmd(0x02);// off
    
    send_lcd_cmd(LCD_ON);          


    return SUCCESS;
  }


  async command result_t LCD.clear() {
    int i;
    
    //call LCD.fill(0x00);
    

    send_lcd_cmd(LCD_COL_SET);
    send_lcd_cmd(0);
    send_lcd_cmd(63);

    send_lcd_cmd(LCD_ROW_SET);
    send_lcd_cmd(0);
    send_lcd_cmd(79);
    

    // 128x64/2 -- relies on address auto advancing = 4096 max
    // but ram is 128*80 so this gives 5120
    for(i=0; i < 5120; i++)
      set_lcd_byte(0x00);           

    return SUCCESS;
  }


  async command result_t LCD.backlightOn() {
    return SUCCESS;    
  }

  async command result_t LCD.backlightOff() {
    return SUCCESS;
  }

  async command result_t LCD.fill(uint16_t color) {
    int i;

    send_lcd_cmd(LCD_COL_SET);
    send_lcd_cmd(0);
    send_lcd_cmd(63);

    send_lcd_cmd(LCD_ROW_SET);
    send_lcd_cmd(0);
    send_lcd_cmd(79);
    

    // 128x64/2 -- relies on address auto advancing = 4096 max
    // but ram is 128*80 so this gives 5120
    // this should be 10 lines
    for(i=0; i < 4096; i++)
      set_lcd_byte(color);           

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

#if 0
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
#endif
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
    return SUCCESS;
    }

  async command result_t  LCD.copy_RLE_rect(const Rect *r,const GF_Image *srcImage,const Point *dest,int mode)
  {
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
#if 0
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
#endif
      
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
 
#endif      
      return SUCCESS;
    
    }


  // oled test interface
  command result_t  OLED_TEST.test_reset()
    {
      TOSH_CLR_LCD_RESET_L_PIN();
      return SUCCESS;
    }
  command result_t  OLED_TEST.test_unreset()
    {
      TOSH_SET_LCD_RESET_L_PIN();
      return SUCCESS;
    }
  command result_t  OLED_TEST.test_pixels_off()
    {
      send_lcd_cmd(LCD_PIXELS_OFF);                
      return SUCCESS;
    }  
  command result_t  OLED_TEST.test_pixels_on()
    {
      send_lcd_cmd(LCD_PIXELS_ON);          
      return SUCCESS;
    }
  command result_t  OLED_TEST.test_pixels_normal()
    {
      send_lcd_cmd(LCD_PIXELS_NORMAL);          
      return SUCCESS;
    }
  command result_t  OLED_TEST.test_pixels_invert()
    {
      send_lcd_cmd(LCD_PIXELS_INVERT);          

      return SUCCESS;
    }
  command result_t  OLED_TEST.test_data_high()
    {
      send_lcd_cmd(0x40);          

      return SUCCESS;
    }
  command result_t  OLED_TEST.test_data_low()
    {
      send_lcd_cmd(0x20);          
      return SUCCESS;
    }

  command result_t  OLED_TEST.test_read_status()
    {
      read_lcd_status();          
      return SUCCESS;
    }
  command result_t  OLED_TEST.test_lcd_off()
    {
      send_lcd_cmd(LCD_OFF);          
      return SUCCESS;
    }
  command result_t  OLED_TEST.test_lcd_on()
    {
      send_lcd_cmd(LCD_ON);          
      return SUCCESS;
    }

  command result_t  OLED_TEST.test_0arg_reg(uint8_t a1)
    {
      send_lcd_cmd(a1);          
      return SUCCESS;
    }
  command result_t  OLED_TEST.test_1arg_reg(uint8_t a1,uint8_t d1)
    {
      send_lcd_cmd(a1);
      send_lcd_cmd(d1);                
      return SUCCESS;
    }
  command result_t  OLED_TEST.test_2arg_reg(uint8_t a1,uint8_t d1,uint8_t d2)
    {
      send_lcd_cmd(a1);
      send_lcd_cmd(d1);
      send_lcd_cmd(d2);                
      return SUCCESS;
    }

  command result_t  OLED_TEST.test_hline()
    {
      int i;
      uint8_t color;
      uint8_t c;
      int j;
      
      
      
      send_lcd_cmd(LCD_COL_SET);
      send_lcd_cmd(0);
      send_lcd_cmd(63);
      send_lcd_cmd(LCD_ROW_SET);
      send_lcd_cmd(16);
      send_lcd_cmd(48);

      c = 0x0f;
      for(i=0; i < 31; i++){
	color = (c<<4)|c;      
	if (i < 15)
	  c--;
	else
	  c++;

	// now do a row in that color
	for (j=0; j < 64; j++)
	  set_lcd_byte(color);
      }
      return SUCCESS;
    } 
  command result_t  OLED_TEST.test_vline()
    {

      int i;
      uint8_t color;
      uint8_t c;
      int row;
      
      
      
      send_lcd_cmd(LCD_COL_SET);
      send_lcd_cmd(16);
      send_lcd_cmd(47);


      for (row = 0; row < 64; row++){
	c = 0x0f;
	send_lcd_cmd(LCD_ROW_SET);
	send_lcd_cmd(row);
	send_lcd_cmd(63);

	for(i=0; i < 32; i++){
	  color = (c<<4)|c;      
	  if (i < 15)
	    c--;
	  else if (i==15)
	    c=0;
	  else
	    c++;
	  set_lcd_byte(color);
#if 0
	  // these advance the address pointer 
	  get_lcd_byte(); //dummy
	  get_lcd_byte(); //real 
#endif
	}
      }
      
      return SUCCESS;
    } 
  command result_t  OLED_TEST.test_read_vline()
    {

      int i;
      uint8_t color;
      uint8_t c;
      int row;
      
      
      
      send_lcd_cmd(LCD_COL_SET);
      send_lcd_cmd(16);
      send_lcd_cmd(47);


      for (row = 0; row < 64; row++){
	c = 0x0f;
	send_lcd_cmd(LCD_ROW_SET);
	send_lcd_cmd(row);
	send_lcd_cmd(63);
	get_lcd_byte(); //dummy
	for(i=0; i < 32; i++){
	  color = (c<<4)|c;      
	  if (i < 15)
	    c--;
	  else if (i==15)
	    c=0;
	  else
	    c++;
	  // these advance the address pointer 
	  get_lcd_byte(); //real 
	}
      }
      
      return SUCCESS;
    } 


  command result_t OLED_TEST.test_fill_lines(uint8_t number, uint8_t color) {
    int i;

    send_lcd_cmd(LCD_COL_SET);
    send_lcd_cmd(0);
    send_lcd_cmd(63);

    send_lcd_cmd(LCD_ROW_SET);
    send_lcd_cmd(0);
    send_lcd_cmd(79);
    

    // 128x64/2 -- relies on address auto advancing = 4096 max
    // but ram is 128*80 so this gives 5120
    // this should be 10 lines
#if 0
    for(i=0; i < 128*number/2; i++)
      set_lcd_byte(color);           
#endif

    for(i=0; i < number; i++)
      set_lcd_byte(color);           

    return SUCCESS;
  }



  command result_t OLED_TEST.test_draw_bitmap() {
    int i;

    send_lcd_cmd(LCD_COL_SET);
    send_lcd_cmd(0);
    send_lcd_cmd(63);

    send_lcd_cmd(LCD_ROW_SET);
    send_lcd_cmd(0);
    send_lcd_cmd(79);
    

    // 128x64/2 -- relies on address auto advancing = 4096 max
    // but ram is 128*80 so this gives 5120
    // this should be 10 lines
    for(i=0; i < 4096; i++)
      set_lcd_byte(beth_logan_screen_data[i]);           

    return SUCCESS;
  }

  
}



