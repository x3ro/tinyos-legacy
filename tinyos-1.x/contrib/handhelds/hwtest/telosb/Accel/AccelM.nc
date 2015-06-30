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
 *           July 2005
 */

includes msp430baudrates;

module AccelM {
  provides {
    interface StdControl;
    interface Accel;
    interface ParamView;
  }
  uses {
    interface ADC as XADC;
    interface ADC as YADC;
    interface ADCControl as ADCControl;
    interface Timer;
  }
}

implementation {

  struct AccelStats {
    uint32_t bytes_read;
    uint32_t datasets_read;
    uint32_t packets_sent;
    uint32_t swap_loss;
  };

  norace static struct AccelStats g_stats;

  static struct AccelData  g_data[2];        // Flip buffer of accel data

  static int               g_active_index;   // Current g_data structure we're filling
  static int               g_lock;           // Is the other data structure in use?
  static int               g_packet_index;  

  command result_t StdControl.init()
  {
    TOSH_SEL_ADC0_MODFUNC();
    TOSH_SEL_ADC1_MODFUNC();
    call ADCControl.init();
    return SUCCESS;
  }

  command result_t StdControl.start()
  {
    call ADCControl.init();
    call ADCControl.bindPort(TOS_ADC_ACCEL_X_PORT, TOSH_ACTUAL_ADC_ACCEL_X_PORT);
    call ADCControl.bindPort(TOS_ADC_ACCEL_Y_PORT, TOSH_ACTUAL_ADC_ACCEL_Y_PORT);
    call Timer.start(TIMER_REPEAT, 50 );
    return SUCCESS;
  }

  command result_t StdControl.stop()
  {
    call Timer.stop();
    return SUCCESS;
  }

  event result_t Timer.fired() {
    call XADC.getData();
    return SUCCESS;
  }


  command const struct AccelData *Accel.get()
  {
    struct AccelData *xd;
    atomic {
      g_lock++;
      xd = g_data + 1 - g_active_index;
    }
    return xd;
  }

  command void Accel.release()
  {
    atomic {
      g_lock--;
    }
  }

  /* A complete data set has been completed */
  task void push_dataset()
  {
    signal Accel.data_received();
  }

  void processSample(uint16_t sample) {
      struct AccelData *data = g_data + g_active_index;
      data->samples[g_packet_index++] = sample;
      g_stats.bytes_read++;

      if (g_packet_index >= ACCEL_SAMPLES_PER_PACKET) {
	g_packet_index = 0;
	g_stats.datasets_read++;

	// Only swap buffers IF someone isn't reading it right now
	// Otherwise, we quietly refill it.
	if ( !g_lock ) {
	  data->number = g_stats.datasets_read;
	  g_active_index = 1 - g_active_index;
	  g_stats.packets_sent++;
	  post push_dataset();
	}
	else
	  g_stats.swap_loss++;
      }
    }

  task void start_y_conversion() { call YADC.getData(); }

  async event result_t XADC.dataReady(uint16_t sample){ 
    atomic {
      processSample(sample);
    }
    post start_y_conversion();
    return SUCCESS;
  } 

  async event result_t YADC.dataReady(uint16_t sample){ 
    atomic {
      processSample(sample);
    }
    return SUCCESS;
  } 

  /*****************************************
   *  ParamView interface
   *****************************************/

  const struct Param s_Accel[] = {
    { "bytes",    PARAM_TYPE_UINT32, &g_stats.bytes_read },
    { "datasets", PARAM_TYPE_UINT32, &g_stats.datasets_read },
    { "packets",  PARAM_TYPE_UINT32, &g_stats.packets_sent },
    { "swaploss", PARAM_TYPE_UINT32, &g_stats.swap_loss },
    { NULL, 0, NULL }
  };

  struct ParamList g_AccelList = { "accel", &s_Accel[0] };

  command result_t ParamView.init()
  {
    signal ParamView.add( &g_AccelList );
    return SUCCESS;
  }
}
