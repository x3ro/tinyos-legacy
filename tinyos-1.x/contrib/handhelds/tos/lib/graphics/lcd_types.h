/*
 * Copyright (c) 2004,2005 Hewlett-Packard Company
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
 */

#ifndef _LCD_TYPES_H_
#define _LCD_TYPES_H_


#define LCD_WIDTH 160
#define LCD_HEIGHT 120

enum GF_Mode {GF_OR,GF_AND,GF_COPY,GF_XOR,GF_NONE};

enum {
  LCD_ALIGN_LEFT,
  LCD_ALIGN_RIGHT,
  LCD_ALIGN_CENTER
};


#if defined(MANY_FONTS)
#define MAX_FONTNUM 6
enum {
  FONT_HELVETICA_R_10,
  FONT_HELVETICA_O_10,
  FONT_HELVETICA_R_12,
  FONT_HELVETICA_O_12,
  FONT_HELVETICA_R_14,
  FONT_HELVETICA_R_18,
  FONT_HELVETICA_R_24
};

#else
#define MAX_FONTNUM 1
enum {
  FONT_HELVETICA_R_12,
  FONT_HELVETICA_R_18
};

#endif

// structs
typedef struct _GF_Image
{
        int w;
        int h;
        unsigned char data[];
}GF_Image;






typedef struct _Rect 
{
  int x; // top left corner x
  int y; // top left corner y
  int w;
  int h;
} Rect;
typedef struct _Point 
{
  int x;
  int y;
} Point;


/***********************************************************************************
 *
 * new font stuff will eventually replace the above stuff
 *
 *
 **********************************************************************************/
struct KERN_INFO {
	uint16_t encoding; // the second letter for which this is the kern info for
    	int8_t offset; // the offset in device pixels to add to the dwidth before determining the next origin 
};


struct FONT_CHAR {
  uint8_t encoding; // ascii 
  //uint16_t swidth;
  uint8_t dwidth;
  //uint8_t bbw;  *** this was never needed so i tossed it
  uint8_t bbh;  
  int8_t  bbXOff;  
  int8_t  bbYOff;  
  uint8_t byteWidth;
  uint8_t ligatureInfo;  // high nibble: offset into the ligature table for this starting letter
                        // low nibble: number of ligature entries with this char as the starting number.
  uint8_t kernIndex; // offset into the kern table for this starting letter
  uint8_t  kernNum;  // number of kern entries with this char as the starting number.
  uint16_t offset;
  
};


struct FONT {  
  uint8_t ascent;
  uint8_t descent;
  uint8_t resolution;
  uint16_t pointSize;
  const unsigned char *bitmap;
  uint16_t bitmapSize;
  const struct FONT_CHAR *fc;
  uint8_t fcSize;
  const struct KERN_INFO *ki;
  uint8_t kiSize;
  const struct FONT_CHAR *li;
  uint8_t liSize;
  uint8_t encodingOffset;
  
};

struct ICON {
  uint8_t width;
  uint8_t height;
  uint8_t byteWidth;
  uint8_t count;
  uint8_t *bitmap;
};



#endif // LCD_TYPES_H

















