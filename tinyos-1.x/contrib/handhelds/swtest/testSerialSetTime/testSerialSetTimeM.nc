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
 * Authors:  Andrew Christian
 *           Jamey Hicks
 *           March 2005
 * re-spin to test receiving and setting current time during runtime
 * from pc host via python script
 *          Steve Ayer
 *          March, 2010
 */

includes msp430baudrates;

module testSerialSetTimeM {
  provides {
    interface StdControl;
    interface ParamView;
  }

  uses {
    interface StdControl as IPStdControl;
    interface StdControl as TelnetStdControl;
    interface StdControl as PVStdControl;

    interface UIP;
    interface Client;
    interface Leds;
    interface Time;
    
    interface HPLUSARTControl as UARTControl;
    interface HPLUSARTFeedback as UARTData;
  }
}

implementation {
  extern int snprintf(char *str, size_t size, const char *format, ...) __attribute__ ((C));

  enum {
    NONE,
    BYTE_32,
    BYTE_24,
    BYTE_16,
    BYTE_8
  };

  struct tm g_tm;
  time_t g_host_time = 0;
  uint8_t sync_state, byte3, byte2, byte1, byte0;
  char g_timestring[128];
  //  uint16_t utime, ltime;

  void setupUART() {
    call UARTControl.setClockSource(SSEL_SMCLK);
    call UARTControl.setClockRate(UBR_SMCLK_115200, UMCTL_SMCLK_115200);

    call UARTControl.setModeUART();
    call UARTControl.enableTxIntr();
    call UARTControl.enableRxIntr();
  }

  command result_t StdControl.init() {
    call Leds.init();

    sync_state = NONE;

    setupUART();

    call PVStdControl.init();
    call TelnetStdControl.init();
    call IPStdControl.init();

    return SUCCESS;
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

  task void assemble_timestamp() {
    time_t time_now;

    g_host_time = byte3;
    g_host_time = g_host_time << 24;
    g_host_time = (g_host_time >> 16 | byte2) << 16;
    g_host_time = (g_host_time >> 8 | byte1) << 8;
    g_host_time = g_host_time | byte0;

    //utime = byte3 << 8 | byte2;
    //ltime = byte1 << 8 | byte0;

    call Time.setCurrentTime(g_host_time);
    
    call Time.time(&time_now);
    call Time.localtime(&time_now, &g_tm);
    call Time.asctime(&g_tm, g_timestring, 128);
  }

  async event result_t UARTData.rxDone(uint8_t data) {        
    switch (sync_state) {
    case NONE:
      byte3 = data;
      sync_state = BYTE_32;
      break;
    case BYTE_32:
      byte2 = data;
      sync_state = BYTE_24;
      break;
    case BYTE_24:
      byte1 = data;
      sync_state = BYTE_16;
      break;
    case BYTE_16:
      byte0 = data;
      sync_state = NONE;
      post assemble_timestamp();
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

  /*****************************************
   *  Client interface
   *****************************************/

  event void Client.connected( bool isConnected ) 
  {
    /*
    if (isConnected) 
      call Leds.greenOn();
    else
      call Leds.greenOff();
    */
  }


  /*****************************************
   *  ParamView interface
   *****************************************/

  const struct Param s_TestTime[] = {
    //    { "utime",    PARAM_TYPE_HEX16, &utime },
    //    { "ltime",    PARAM_TYPE_HEX16, &ltime },
    { "year",    PARAM_TYPE_UINT16, &g_tm.tm_year },
    { "mon",    PARAM_TYPE_UINT16, &g_tm.tm_mon },
    { "day",    PARAM_TYPE_UINT16, &g_tm.tm_mday },
    { "hour",    PARAM_TYPE_UINT16, &g_tm.tm_hour },
    { "min",    PARAM_TYPE_UINT16, &g_tm.tm_min },
    { "timestring",    PARAM_TYPE_STRING, &g_timestring[0] },
    { NULL, 0, NULL }
  };

  struct ParamList g_TestTimeList = { "test", &s_TestTime[0] };

  command result_t ParamView.init()
  {
    signal ParamView.add( &g_TestTimeList );
    return SUCCESS;
  }

}
