/*
 * Copyright (c) 2004, Intel Corporation
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * Redistributions of source code must retain the above copyright notice,
 * this list of conditions and the following disclaimer.
 *
 * Redistributions in binary form must reproduce the above copyright notice,
 * this list of conditions and the following disclaimer in the documentation
 * and/or other materials provided with the distribution.
 *
 * Neither the name of the Intel Corporation nor the names of its contributors
 * may be used to endorse or promote products derived from this software
 * without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 */

interface AlphaDisp

{
  // initializes AlphaDisp
  // numStatusChars = number of characters used to display link status
  //                  each character can display up to 2 status
  //                  values range 0 to 2
  command result_t init(uint8 numStatusChars);
  
  // puts display to power-saving sleep mode
  command result_t sleep();
  
  // Display up to 4 static characters
  // c = pointer to the character array
  // count = number of characters to display (up to 4-numStatusChars)
  // bright = brightness of display (1 to 15)
  command result_t staticDisp(char *c, uint8 count, uint8 bright);
  
  // Scroll an array of characters in an infinite loop
  // c = pointer to the character array
  // count = number of characters to display (up to 40 characters)
  // bright = brightness of display (1 to 15)
  command result_t scrollInit(char *c, uint8 count, uint8 bright);
  
  // Sets the refresh rate of scroll
  // refresh = refresh interval (in msec)
  command result_t setRefresh(int refresh);
  
  // Update the link quality status indicator
  // dispID = ID of the link quality indicator.  The indicators use
  //          the right 2 (or 1) characters of the display in according
  //          to the following placement:
  //          | 2 | 0 |
  //          | 3 | 1 |
  // linkQuality = link quality in the range 0:15.  The number of dots
  //           showing up on the display indicates this value
  command result_t linkStatusDisp(uint8 dispID, uint8 linkQuality);
}

