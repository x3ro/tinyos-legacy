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
 * Authors:		Brian Avery
 * Date last modified:  7/25/04
 *
 *
 */

/**
 * Abstraction of the LCD.
 *
 * @author Brian Avery
 */
includes lcd_types;
includes icons;
interface LCD {

  /**
   * Initialize the LCD; among other things, initialization clears the 
   * screen and turns off the backlight
   *
   * @return SUCCESS always.
   *
   */
  
  async command result_t init();

  /**
   * clear the LCD
   *
   * @return SUCCESS always.
   *
   */

  async command result_t clear();

  /**
   * fill the LCD
   *
   * @return SUCCESS always.
   *
   */

  async command result_t fill(uint16_t color);


  /**
   * read a value from an lcd address
   *
   * @return value.
   *
   */

  async command uint16_t read(uint16_t addr);

  
  /**
   * turn on the backLight
   *
   * @return SUCCESS always.
   *
   */

  async command result_t backlightOn();

  /**
   * turn off the backLight
   *
   * @return SUCCESS always.
   *
   */

  async command result_t backlightOff();


  /**
   * get basic font info
   *   ascent,descent
   *
   * @return SUCCESS if font # exists.
   *
   */

  async command  result_t gf_get_font_info(int fontNum,int *ascent,int *descent);


  /**
   * get the width of a string
   *
   * @return width always.
   *
   */

  async command  int gf_get_string_width(char *str,int fontNum);

  /**
   * get the rect of a string
   *
   * @return SUCCESS always.
   *
   */

  command  result_t gf_erase_string(char *str,int fontNum,Point *p,int alignment);

  
  /**
   * get the rect of a string
   *
   * @return SUCCESS always.
   *
   */

  async command  result_t gf_get_string_rect(char *str,int fontNum,Point *p,Rect *r);


    /**
   * draw an icon from a family
   *   
   *
   * @return SUCCESS always .
   *
   */

  async command  result_t gf_draw_icon(int iconFamily,int which,Point *dest,int mode);

  /**
   * draw a string on the lcd at th given point (x,y) in a font and aligned left, right or center
   * do space line breaks as needed and advence the line by the fonts descent.  
   *
   * @return result .
   *
   */

  async command  result_t gf_draw_multiline_string_aligned(char *str,int fontNum,Point *dest,int mode, int alignment);


  /**
   * draw a string on the lcd at th given point (x,y) in a font and aligned left, right or center
   *   
   *
   * @return result .
   *
   */

  async command  result_t gf_draw_string_aligned(char *str,int fontNum,Point *dest,int mode, int alignment);

  
  /**
   * draw a string on the lcd at th given point (x,y) in a font (small
   *   medium, large
   *
   * @return SUCCESS always.
   *
   */

  async command  result_t gf_draw_string(char *str,int fontNum,Point *dest,int mode);

  /**
   * draw a string on the lcd at th given point (x,y) in a font (small
   *   medium, large, right justified
   *
   * @return SUCCESS always.
   *
   */

  async command  result_t gf_draw_string_right(char *str,int fontNum,Point *dest,int mode);

  /**
   * draw a string on the lcd at th given point (x,y) in a font (small
   *   medium, large, center justified
   *
   * @return SUCCESS always.
   *
   */

  async command  result_t gf_draw_string_center(char *str,int fontNum,Point *dest,int mode);

  
  /**
   * draw a point at x,y
   *   
   *
   * @return SUCCESS always.
   *
   */

  async command  result_t gf_draw_point(int x,int y);
  
  /**
   * clear a point at x,y
   *   
   *
   * @return SUCCESS always.
   *
   */

  async command  result_t gf_clear_point(int x,int y);

  /**
   * draw a line from x0,y0 to x1,y1
   *   
   *
   * @return SUCCESS always.
   *
   */

  async command  result_t gf_draw_line(int x0,int l_y0,int x1,int l_y1);

  /**
   * draw a dashed line from x0,y0 to x1,y1
   *   
   *
   * @return SUCCESS always.
   *
   */

  async command  result_t gf_draw_dashed_line(int x0,int l_y0,int x1,int l_y1,int skip);

  
  /**
   * clear a line from x0,y0 to x1,y1
   *   
   *
   * @return SUCCESS always.
   *
   */

  async command  result_t gf_clear_line(int x0,int l_y0,int x1,int l_y1);




  /**
   * fill a rect with a given byte
   *   
   *
   * @return SUCCESS always.
   *
   */

  async command  result_t gf_fill_rect(const Rect *r,uint8_t value);

  /**
   * frame a rect 
   *   
   *
   * @return SUCCESS always.
   *
   */

  async command  result_t gf_frame_rect(const Rect *r);

  
  /**
   * clear a frame  rect 
   *   
   *
   * @return SUCCESS always.
   *
   */

  async command  result_t gf_clear_frame_rect(const Rect *r);

  /**
   * clear the rect on the lcd
   *   
   *
   * @return SUCCESS always.
   *
   */

  async command  result_t gf_clear_rect(const Rect *r);
  
  /**
   * draw an image to the lcd from an RLE encoded image
   *   
   *
   * @return SUCCESS always.
   *
   */

  async command result_t  draw_RLE_image(const GF_Image *img);

  /**
   * copy a rect from the source image and copy it to the screen at the given point
   *   
   *
   * @return SUCCESS always.
   *
   */
  async command result_t  copy_RLE_rect(const Rect *r,const GF_Image *srcImage,const Point *dest,int mode);
  

  /**
   * test fxn to call when bringing new things up
   *   
   *
   * @return SUCCESS always.
   *
   */
  async command result_t  test();

}

