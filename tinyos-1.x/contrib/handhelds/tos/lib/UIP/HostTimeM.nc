/*
 * Copyright (c) 2010, Shimmer Research, Ltd.
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
 *     * Neither the name of Shimmer Research, Ltd. nor the names of its
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
 * @author Steve Ayer
 * @date   June 2010
 */

module HostTimeM {
  provides { 
    interface StdControl;
    interface HostTime;
  }
  uses {
    interface Time;
    interface HPLUSARTControl as UARTControl;
    interface HPLUSARTFeedback as UARTData;
  }
}

implementation {

  enum {
    NONE,
    TIMEBYTE_32,
    TIMEBYTE_24,
    TIMEBYTE_16,
    TIMEBYTE_8,
    YEARBYTE_32,
    YEARBYTE_24,
    YEARBYTE_16,
    YEARBYTE_8,
    ZERODAY,
    DST_FDAY1,
    DST_FDAY0,
    DST_LDAY1,
    DST_LDAY0,
    YEAR1,
    YEAR0
  };

  struct tm g_tm;
  time_t g_host_time = 0, g_year_time;
  uint8_t byte3, byte2, byte1, byte0, byte7, byte6, byte5, byte4, byte9, byte8, byte10, byte11, byte12, byte14, byte13;
  uint8_t sync_state, g_zero_day;
  uint16_t g_dst_fday, g_dst_lday, g_year;
  char g_timestring[128];

  void setupUART() {
    call UARTControl.setClockSource(SSEL_SMCLK);
    call UARTControl.setClockRate(UBR_SMCLK_115200, UMCTL_SMCLK_115200);

    call UARTControl.setModeUART();
    call UARTControl.enableTxIntr();
    call UARTControl.enableRxIntr();
  }

  command result_t StdControl.init() {
    sync_state = NONE;

    setupUART();

    return SUCCESS;
  }

  command result_t StdControl.start() {
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    return SUCCESS;
  }

  task void assemble_timestamp() {
    time_t time_now;

    g_host_time = byte3;
    g_host_time = g_host_time << 24;
    g_host_time = (g_host_time >> 16 | byte2) << 16;
    g_host_time = (g_host_time >> 8 | byte1) << 8;
    g_host_time = g_host_time | byte0;

    g_year_time = byte7;
    g_year_time = g_year_time << 24;
    g_year_time = (g_year_time >> 16 | byte6) << 16;
    g_year_time = (g_year_time >> 8 | byte5) << 8;
    g_year_time = g_year_time | byte4;

    g_zero_day = byte8;
    
    g_dst_fday = byte10;
    g_dst_fday = (g_dst_fday << 8) | byte9;

    g_dst_lday = byte12;
    g_dst_lday = (g_dst_lday << 8) | byte11;

    g_year = byte14;
    g_year = (g_year << 8) | byte13;

    call Time.setCurrentTime(g_host_time);
    call Time.setZoneInfo(g_year, g_year_time, g_zero_day, g_dst_fday, g_dst_lday);


    call Time.time(&time_now);
    call Time.localtime(&time_now, &g_tm);
    call Time.asctime(&g_tm, g_timestring, 128);

    signal HostTime.timeAndZoneSet(g_timestring);
  }

  async event result_t UARTData.rxDone(uint8_t data) {        
    switch (sync_state) {
    case NONE:
    case TIMEBYTE_32:
      byte3 = data;
      sync_state = TIMEBYTE_24;
      break;
    case TIMEBYTE_24:
      byte2 = data;
      sync_state = TIMEBYTE_16;
      break;
    case TIMEBYTE_16:
      byte1 = data;
      sync_state = TIMEBYTE_8;
      break;
    case TIMEBYTE_8:
      byte0 = data;
      sync_state = YEARBYTE_32;
      break;
    case YEARBYTE_32:
      byte7 = data;
      sync_state = YEARBYTE_24;
      break;
    case YEARBYTE_24:
      byte6 = data;
      sync_state = YEARBYTE_16;
      break;
    case YEARBYTE_16:
      byte5 = data;
      sync_state = YEARBYTE_8;
      break;
    case YEARBYTE_8:
      byte4 = data;
      sync_state = ZERODAY;
      break;
    case ZERODAY:
      byte8 = data;
      sync_state = DST_FDAY1;
      break;
    case DST_FDAY1:
      byte10 = data;
      sync_state = DST_FDAY0;
      break;
    case DST_FDAY0:
      byte9 = data;
      sync_state = DST_LDAY1;
      break;
    case DST_LDAY1:
      byte12 = data;
      sync_state = DST_LDAY0;
      break;
    case DST_LDAY0:
      byte11 = data;
      sync_state = YEAR1;
      break;
    case YEAR1:
      byte14 = data;
      sync_state = YEAR0;
      break;
    case YEAR0:
      byte13 = data;
      post assemble_timestamp();
      sync_state = NONE;
      break;
    default:
      break;
    }
    
    return SUCCESS;
  }

  event async result_t UARTData.txDone() {
    return SUCCESS;
  }

  event void Time.tick() { }

} 
