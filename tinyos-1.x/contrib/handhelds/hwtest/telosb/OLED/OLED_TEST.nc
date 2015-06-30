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
 * convenience test interface for the oled lcd
 * provides hooks for the telnet commands i wanna be able to run
 *
 * @author Brian Avery
 */
interface OLED_TEST {

  command result_t test_reset();
  command result_t test_unreset();
  command result_t test_pixels_off();
  command result_t test_pixels_on();
  command result_t test_pixels_invert();
  command result_t test_pixels_normal();
  command result_t test_data_high();
  command result_t test_data_low();
  command result_t test_read_status();
  command result_t test_lcd_off();
  command result_t test_lcd_on();

  command result_t test_0arg_reg(uint8_t a1);
  command result_t test_1arg_reg(uint8_t a1,uint8_t d1);
  command result_t test_2arg_reg(uint8_t a1,uint8_t d1,uint8_t d2);

  command result_t test_vline();
  command result_t test_hline();  
  command result_t test_read_vline();

  command result_t test_fill_lines(uint8_t lines,uint8_t color);

  command result_t test_draw_bitmap();

}

