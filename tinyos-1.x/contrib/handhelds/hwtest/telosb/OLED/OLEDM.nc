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
 * Test reading a serial number from the Dallas Semiconductor DS2411
 * chip.
 *
 * Author: Andrew Christian <andrew.christian@hp.com>
 *         14 March 2005
 *
 */

includes NVTParse;

module OLEDM {
  provides {
    interface StdControl;
  }
  uses {
    interface UIP;
    interface Client;
    interface Telnet as TelnetOLED;
    interface StdControl as IPStdControl;
    interface StdControl as TelnetStdControl;
    interface LCD;
    interface OLED_TEST;
    
    
    interface Leds;
  }
}
implementation {
  extern int snprintf(char *str, size_t len, const char *format, ...) __attribute__ ((C));
  
  /*****************************************
   *  StdControl interface
   *****************************************/

  command result_t StdControl.init() {
    call TelnetStdControl.init();
    call LCD.init();
    
    return call IPStdControl.init();
  }

  command result_t StdControl.start() {
    call IPStdControl.start();
    call TelnetStdControl.start();
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    call TelnetStdControl.stop();
    return call IPStdControl.stop();
  }

  /*****************************************
   *  Telnet
   *****************************************/

  event const char * TelnetOLED.token() { return "oled"; }
  
  struct cmdList 
  {
    char *name;
    void (*fxn)(char *line);
  };

  void wrapper_reset(char *line)
    {
      call OLED_TEST.test_reset();
    }
  void wrapper_unreset(char *line)
    {
      call OLED_TEST.test_unreset();
    }
  void wrapper_pixels_off(char *line)
    {
      call OLED_TEST.test_pixels_off();
    }
  void wrapper_pixels_on(char *line)
    {
      call OLED_TEST.test_pixels_on();
    }
  void wrapper_pixels_invert(char *line)
    {
      call OLED_TEST.test_pixels_invert();
    }
  void wrapper_pixels_normal(char *line)
    {
      call OLED_TEST.test_pixels_normal();
    }
  void wrapper_data_high(char *line)
    {
      call OLED_TEST.test_data_high();
    }
  void wrapper_data_low(char *line)
    {
      call OLED_TEST.test_data_low();
    }
  void wrapper_read_status(char *line)
    {
      call OLED_TEST.test_read_status();
    }
  void wrapper_lcd_off(char *line)
    {
      call OLED_TEST.test_lcd_off();
    }
  void wrapper_lcd_on(char *line)
    {
      call OLED_TEST.test_lcd_on();
    }
  void wrapper_lcd_clear(char *line)
    {
      call LCD.clear();
    }
  void wrapper_lcd_fill(char *line)
    {
      call LCD.fill(0xff);
      
    }
  
  void wrapper_0arg_reg(char *line)
    {
      uint8_t a1;
      char *next;
      char *addr = next_token(line, &next, ' ');
      
      a1 = (uint8_t) atoi(addr);      
      call OLED_TEST.test_0arg_reg(a1);
      
    }

  void wrapper_1arg_reg(char *line)
    {
      uint8_t a1;
      uint8_t d1;
      char *next;
      char *addr = next_token(line, &next, ' ');
      char *data1 = next_token(next, &next, ' ');
      
      a1 = (uint8_t) atoi(addr);
      d1 = (uint8_t) atoi(data1);      
      call OLED_TEST.test_1arg_reg(a1,d1);
      
    }

  void wrapper_2arg_reg(char *line)
    {
      uint8_t a1;
      uint8_t d1;
      uint8_t d2;
      char *next;
      char *addr = next_token(line, &next, ' ');
      char *data1 = next_token(line, &next, ' ');
      char *data2 = next_token(line, &next, ' ');      
      
      a1 = (uint8_t) atoi(addr);
      d1 = (uint8_t) atoi(data1);
      d2 = (uint8_t) atoi(data2);      
      call OLED_TEST.test_2arg_reg(a1,d1,d2);
      
    }

  void wrapper_vline(char *line)
    {
      call OLED_TEST.test_vline();
    }
  void wrapper_hline(char *line)
    {
      call OLED_TEST.test_hline();
    }
  void wrapper_read_vline(char *line)
    {
      call OLED_TEST.test_read_vline();
    }


  void wrapper_fill_lines(char *line)
    {
      uint8_t numLines;
      uint8_t colorTmp;
      char *next;
      char *lineS = next_token(line, &next, ' ');
      char *colorS = next_token(next, &next, ' ');
      uint8_t color;
      
      
      numLines = (uint8_t) atoi(lineS);
      colorTmp = (uint8_t) atoi(colorS);
      colorTmp &= 0x0f;
      color = (colorTmp <<4) | colorTmp;
      call OLED_TEST.test_fill_lines(numLines,color);
      
    }


  void wrapper_draw_bitmap(char *line)
    {
      call OLED_TEST.test_draw_bitmap();
    }
  
  
  static struct cmdList oledCmds[] = 
    {
      {"reset",
       &wrapper_reset
      },
      {"unreset",
       &wrapper_unreset
      },
      {"pixels_off",
       &wrapper_pixels_off
      },
      {"pixels_on",
       &wrapper_pixels_on
      },
      {"pixels_invert",
       &wrapper_pixels_invert
      },
      {"pixels_normal",
       &wrapper_pixels_normal
      },
      {"data_high",
       &wrapper_data_high
      },
      {"data_low",
       &wrapper_data_low
      },
      {"read_status",
       &wrapper_read_status
      },
      {"off",
       &wrapper_lcd_off
      },
      {"on",
       &wrapper_lcd_on
      },
      {"clear",
       &wrapper_lcd_clear
      },
      {"fill",
       &wrapper_lcd_fill
      },
      {"0arg_reg",
       &wrapper_0arg_reg
      },
      {"1arg_reg",
       &wrapper_1arg_reg
      },
      {"2arg_reg",
       &wrapper_2arg_reg
      },
      {"hline",
       &wrapper_hline
      },
      {"vline",
       &wrapper_vline
      },
      {"read_vline",
       &wrapper_read_vline
      },
      {"fill_lines",
       &wrapper_fill_lines
      },
      {"draw_bitmap",
       &wrapper_draw_bitmap
      },
      
      {NULL,
       &wrapper_reset       
      }

    };
  
  
     
  char helpBuf[512] = "";
  event const char * TelnetOLED.help() {
    char *p;
    int i;

    i=0;
    p = &helpBuf[0];
    p += snprintf(p,512,"Oled Commands:\r\n");
    while (oledCmds[i].name){
      p += snprintf(p,512,"%s\r\n",oledCmds[i].name);
      i++;
    }
    p += snprintf(p,512,"len=%d\r\n",strlen(helpBuf));
    return helpBuf;
    
  }
  
  event char * TelnetOLED.process( char *in, char *out, char *outmax )
  {
    char *next;
    char *cmd = next_token(in, &next, ' ');
    int i;
    int executed = 0;
    
    
    if (cmd){
      i=0;
      while (oledCmds[i].name){
	if (strcmp(cmd,oledCmds[i].name)==0){
	  (*(oledCmds[i].fxn))(next);
	  executed=1;	  
	}
	i++;
      }
      if (!executed)
	out += snprintf(out, outmax - out, "Unknown oled command:%s\r\n",cmd);    
    }    
    else
      out += snprintf(out, outmax - out, "Enter a valid oled command!\r\n");    
    return out;

  }
  
  event void Client.connected( bool isConnected )
  {
    if ( isConnected )
      call Leds.greenOn();
    else
      call Leds.greenOff();
  }
}


