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
 *
 * Implementation for TestFonts application.
 * 
 * Draw some text on the screen in response to button pushes.
 * Uses the first two clipboard buttons to turn on and off the backlight,
 * the second pair of buttons to change the number of lines of text displayed.
 * 
 * Author:  Brian Avery, Andrew Christian
 **/

module TestFontsM {
  provides {
    interface StdControl;
  }
  uses {
    interface LCD;    
    interface Leds;
    interface Buttons;
  }
}

implementation {
  norace int counter;

  /*****************************************
   *  StdControl interface
   *****************************************/
  command result_t StdControl.init() {
    call LCD.init();
    
    return call Leds.init();
  }

  command result_t StdControl.start() {
    call LCD.backlightOn();
    call LCD.clear();

    call Buttons.enable();
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    return call Buttons.disable();
  }

  /*******************************************************************************/

  void displayData( int count ) 
  {
    Point p;
    int i;

    p.x = 80;
    p.y = 15;
    
    for ( i = 0 ; i < count ; i++ ) {
      call LCD.gf_draw_string_center("*** This is a line of text ***",FONT_HELVETICA_R_12,&p,GF_OR);
      p.y += 14;
    }
  }

  void incrementDisplay()
  {
    counter++;
    if ( counter > 8 ) {
      call LCD.clear();
      counter = 1;
    }
    
    displayData( counter );
  }

  async event result_t Buttons.down( uint8_t buttonState, bool isAutoRepeat )
  {
    if ( buttonState & 0x01 )
      call LCD.backlightOff();
    else if (buttonState & 0x02)
      call LCD.backlightOn();
    else if (buttonState & 0x04)
      call LCD.clear();
    else if (buttonState & 0x08)
      incrementDisplay();

    return SUCCESS;
  }

  async event result_t Buttons.up( uint8_t buttonState)
  {
    return SUCCESS;
  }
}
