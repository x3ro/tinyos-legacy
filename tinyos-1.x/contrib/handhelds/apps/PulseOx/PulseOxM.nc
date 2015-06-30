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
 * Authors:  Andrew Christian
 *           20 January 2005
 */

includes msp430baudrates;

module PulseOxM {
  provides {
    interface PulseOx;
    interface ParamView;
  }
  uses {
    interface HPLUART;
    interface HPLUSARTControl as USARTControl;
    interface Telnet as TelnetPulse;
  }
}

implementation {

  enum {
    SYNC_BYTE         = 0x01,
    STATUS_7          = 0x80,   // Should be set always

    FRAME_SYNC_BYTE   = 0,
    FRAME_STATUS_BYTE = 1,
    FRAME_PLETH_BYTE  = 2,
    FRAME_EXTRA_BYTE  = 3,
    FRAME_CHK_BYTE    = 4,

    OUT_OF_FRAME_SYNC  = -2,
    OUT_OF_PACKET_SYNC = -1,
  };

  struct XpodStats {
    uint16_t lost_frame_sync;
    uint16_t lost_packet_sync;
    uint32_t datasets_received;
    uint32_t frames_received;
    uint32_t bytes_received;
  };

  norace static struct XpodStats g_stats;

  static struct XpodData g_data[2]; 
  static int             g_active_index;   // Current g_data structure we're filling
  static int             g_lock;           // Is the other data structure in use?
  static int             g_packet_index;  

  static int             g_frame_index;
  static uint8_t         g_status_byte;
  static uint8_t         g_pleth_byte;
  static uint8_t         g_extra_byte;

  command void PulseOx.init()
  {
    atomic {
      g_lock = 0;
      g_active_index = 0;
      g_packet_index = OUT_OF_FRAME_SYNC;
      g_frame_index = FRAME_SYNC_BYTE;
      memset(&g_stats,0,sizeof(g_stats));
    }

    call HPLUART.init();
    call USARTControl.setClockRate(UBR_SMCLK_9600, UMCTL_SMCLK_9600);
  }

  command const struct XpodData *PulseOx.get()
  {
    struct XpodData *xd;
    atomic {
      g_lock++;
      xd = g_data + 1 - g_active_index;
    }
    return xd;
  }

  command void PulseOx.release()
  {
    atomic {
      g_lock--;
    }
  }

  /* A complete data set has been completed */
  task void push_dataset()
  {
    signal PulseOx.data_received();
  }

  /*
   * Handle a single 5 byte frame of data from the sensor 
   * Runs in interrupt context.
   */

  void pulseox_process_frame()
  {
    struct XpodData *xd = g_data + g_active_index;
    struct StatusPleth *sp;

    g_stats.frames_received++;

    if ( g_packet_index == OUT_OF_PACKET_SYNC ) {
      if ( !(g_status_byte & STATUS_FRAME_SYNC) ) 
	return;

      g_packet_index = 0;
    }
    else {
      if ( ((g_status_byte & STATUS_FRAME_SYNC) && g_packet_index != 0) ||
	   (!(g_status_byte & STATUS_FRAME_SYNC) && g_packet_index == 0)) {
	g_packet_index = OUT_OF_PACKET_SYNC;
	g_stats.lost_packet_sync++;
	return;
      }
    }

    sp = xd->status_pleth + g_packet_index;
    sp->status = g_status_byte;
    sp->pleth  = g_pleth_byte;

    switch (g_packet_index) {
    case PACKET_HR_MSB:
      xd->heart_rate = ((uint16_t) g_extra_byte) << 7;
      break;
    case PACKET_HR_LSB:
      xd->heart_rate |= g_extra_byte;
      break;
    case PACKET_SPO2:
      xd->spo2 = g_extra_byte;
      break;
    case PACKET_REV:
      xd->firmware_rev = g_extra_byte;
      break;
    case PACKET_SPO2_D:
      xd->spo2_display = g_extra_byte;
      break;
    case PACKET_SPO2_SLEW:
      xd->spo2_slew = g_extra_byte;
      break;
    case PACKET_SPO2_BTOB:
      xd->spo2_beat_to_beat = g_extra_byte;
      break;
    case PACKET_E_HR_MSB:
      xd->extended_heart_rate = ((uint16_t) g_extra_byte) << 7;
      break;
    case PACKET_E_HR_LSB:
      xd->extended_heart_rate |= g_extra_byte;
      break;
    case PACKET_E_SPO2:
      xd->extended_spo2 = g_extra_byte;
      break;
    case PACKET_E_SPO2_D:
      xd->extended_spo2_display = g_extra_byte;
      break;
    case PACKET_HR_D_MSB:
      xd->heart_rate_display = ((uint16_t) g_extra_byte) << 7;
      break;
    case PACKET_HR_D_LSB:
      xd->heart_rate_display |= g_extra_byte;
      break;
    case PACKET_E_HR_D_MSB:
      xd->extended_heart_rate_display = ((uint16_t) g_extra_byte) << 7;
      break;
    case PACKET_E_HR_D_LSB:
      xd->extended_heart_rate_display |= g_extra_byte;
      break;
    }

    g_packet_index++;
    if ( g_packet_index == 25 ) {
      g_packet_index = 0;
      g_stats.datasets_received++;
      // Only swap buffers IF someone isn't reading it right now
      // Otherwise, we quietly refill it.
      if ( !g_lock ) {
	xd->number = g_stats.datasets_received;
	g_active_index = 1 - g_active_index;
	post push_dataset();
      }
    }
  }

  event async result_t HPLUART.get(uint8_t data) 
  {
    int chksum;

    g_stats.bytes_received++;

    switch (g_frame_index) {
    case FRAME_SYNC_BYTE:
      if ( data == SYNC_BYTE ) {
	g_frame_index = FRAME_STATUS_BYTE;
      	return SUCCESS;
      }
      break;

    case FRAME_STATUS_BYTE:
      if ( data & STATUS_7 ) {
      	g_frame_index = FRAME_PLETH_BYTE;
      	g_status_byte = data;
      	return SUCCESS;
      }
      break;

    case FRAME_PLETH_BYTE:
      g_frame_index = FRAME_EXTRA_BYTE;
      g_pleth_byte = data;
      return SUCCESS;

    case FRAME_EXTRA_BYTE:
      g_frame_index = FRAME_CHK_BYTE;
      g_extra_byte = data;
      return SUCCESS;

    case FRAME_CHK_BYTE:
      chksum = 1 + g_status_byte + g_pleth_byte + g_extra_byte - data;
      if ( (chksum & 0x00ff) == 0 ) {
      	if ( g_packet_index == OUT_OF_FRAME_SYNC )
      	  g_packet_index = OUT_OF_PACKET_SYNC;
	pulseox_process_frame(); 
      	g_frame_index = FRAME_SYNC_BYTE;
      	return SUCCESS;
      }
      break;
    }

    // If we've gotten here, we're out of sync

    if ( g_packet_index >= 0 ) {
      g_stats.lost_frame_sync++;
      g_packet_index = OUT_OF_FRAME_SYNC;
      g_frame_index = FRAME_SYNC_BYTE;
    }

    return SUCCESS;
  }

  event async result_t HPLUART.putDone() 
  {
    return SUCCESS;
  }

  /*****************************************
   *  TelnetPulse interface
   *****************************************/

  event const char * TelnetPulse.token() { return "pulse"; }
  event const char * TelnetPulse.help() { return "Pulse-ox control\r\n"; }

  event char * TelnetPulse.process( char *in, char *out, char *outmax )
  {
    struct XpodData *xd;
    atomic {
      g_lock++;
      xd = g_data + 1 - g_active_index;
    }

    out += snprintf(out, outmax - out, 
		    "Set\t%lu\r\nHR\t%d\r\nE-HR\t%d\r\nHR-D\t%d\r\nE-HR-D\t%d\r\n",
		    xd->number, xd->heart_rate, xd->extended_heart_rate, 
		    xd->heart_rate_display, xd->extended_heart_rate_display );

    out += snprintf(out, outmax - out, 
		    "SpO2\t%d\r\nSpO2-D\t%d\r\nSpO2-slew\t%d\r\nSpO2-BtoB\t%d\r\nE-SpO2\t%d\r\n",
		    xd->spo2, xd->spo2_display, xd->spo2_slew, 
		    xd->spo2_beat_to_beat, xd->extended_spo2 );
    out += snprintf(out, outmax - out, 
		    "E-SpO2-D\t%d\r\nFirmware\t%d\r\n",
		    xd->extended_spo2_display, xd->firmware_rev);
    atomic {
      g_lock--;
    }
    return out;
  }

  /*****************************************
   *  ParamView interface
   *****************************************/

  const struct Param s_Pulse[] = {
    { "lost_frame_sync",   PARAM_TYPE_UINT16, &g_stats.lost_frame_sync },
    { "lost_packet_sync",  PARAM_TYPE_UINT16, &g_stats.lost_packet_sync },
    { "datasets", PARAM_TYPE_UINT32, &g_stats.datasets_received },
    { "frames",   PARAM_TYPE_UINT32, &g_stats.frames_received },
    { "bytes",    PARAM_TYPE_UINT32, &g_stats.bytes_received },
    { NULL, 0, NULL }
  };

  struct ParamList g_PulseList = { "pulse", &s_Pulse[0] };

  command result_t ParamView.init()
  {
    signal ParamView.add( &g_PulseList );
    return SUCCESS;
  }
}
