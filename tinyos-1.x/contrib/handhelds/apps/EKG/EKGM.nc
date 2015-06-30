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
 *           Jamey Hicks
 *           March 2005
 */

/* includes msp430baudrates; */

includes hardware;

module EKGM {
  provides {
    interface EKG;
    interface ParamView;
  }
  uses {
    interface Timer;
    interface ADC as ADC0;
    interface ADC as ADC1;
    interface ADCControl;
    interface Telnet as TelnetEKG;
    interface Leds;
  }
}

implementation {

  struct EKGStats {
    uint32_t datasets_received;
    uint32_t samples_received;
    uint32_t bytes_received;
  };

  norace static struct EKGStats g_stats;

  static struct EKGData  g_data[2]; 
  static int             g_active_index;   // Current g_data structure we're filling
  static int             g_lock;           // Is the other data structure in use?
  static int             g_packet_index;  
  static int             g_samples_per_packet = EKG_SAMPLES_PER_PACKET;
  static uint16_t        g_sample_rate = 4;
  static uint8_t         g_uid[6];
  static uint8_t         g_lead = 1;

  command void EKG.init()
  {
    atomic {
      g_lock = 0;
      g_active_index = 0;
      g_packet_index = 0;
      memset(&g_stats,0,sizeof(g_stats));
    }
    call ADCControl.init();
  }

  static int adc_port_info[] = {
    [1] = ASSOCIATE_ADC_CHANNEL(
				INPUT_CHANNEL_A0, REFERENCE_VREFplus_AVss, REFVOLT_LEVEL_1_5
				),
    [2] = ASSOCIATE_ADC_CHANNEL(
				INPUT_CHANNEL_A1, REFERENCE_VREFplus_AVss, REFVOLT_LEVEL_1_5
				),
  };
  command result_t EKG.start(uint8_t lead)
  {
    g_lead = lead;
#ifdef TOS_ADC_ADC0_PORT
    if (lead == 2)
      call ADCControl.bindPort(TOS_ADC_ADC1_PORT, adc_port_info[1]);
    else
      call ADCControl.bindPort(TOS_ADC_ADC0_PORT, adc_port_info[0]);
#endif    

    call Timer.start(TIMER_REPEAT, g_sample_rate);
    return SUCCESS;
  }
  command result_t EKG.stop()
  {
    call Timer.stop();
    return SUCCESS;
  }

  command const struct EKGData *EKG.get()
  {
    struct EKGData *xd;
    atomic {
      g_lock++;
      xd = g_data + 1 - g_active_index;
    }
    return xd;
  }

  command void EKG.release()
  {
    atomic {
      g_lock--;
    }
  }

  /* A complete data set has been completed */
  task void push_dataset()
  {
    signal EKG.data_received();
  }

  event result_t Timer.fired() {
    call ADC0.getData();
    return SUCCESS;
  }

  void processSample(uint8_t channel, uint16_t sample) {
      struct EKGData *xd = g_data + g_active_index;
#if EKG_SAMPLE_SIZE == 2
      xd->samples[g_packet_index++] = sample;
#else
      xd->samples[g_packet_index++] = (sample >> 5);
#endif
      g_stats.samples_received++;

      if (g_packet_index >= g_samples_per_packet) {

	g_packet_index = 0;
	g_stats.datasets_received++;

	// Only swap buffers IF someone isn't reading it right now
	// Otherwise, we quietly refill it.
	if ( !g_lock ) {
	  xd->number = g_stats.datasets_received;
	  xd->sample_size = EKG_SAMPLE_SIZE;
	  g_active_index = 1 - g_active_index;
	  post push_dataset();
	}
      }
    }

  async event result_t ADC0.dataReady(uint16_t sample){ 
    atomic {
      processSample(0, sample);
    }
    return SUCCESS;
  } 

  async event result_t ADC1.dataReady(uint16_t sample){ 
    atomic {
      processSample(1, sample);
    }
    return SUCCESS;
  } 

  /*****************************************
   *  TelnetEKG interface
   *****************************************/

  event const char * TelnetEKG.token() { return "ekg"; }
  event const char * TelnetEKG.help() { return "EKG control\r\n"; }

  event char * TelnetEKG.process( char *in, char *out, char *outmax )
  {
    struct EKGData *xd;
    atomic {
      g_lock++;
      xd = g_data + 1 - g_active_index;
    }

#if 0
    out += snprintf(out, outmax - out, 
		    "Set\t%lu\r\nHR\t%d\r\nE-HR\t%d\r\nHR-D\t%d\r\nE-HR-D\t%d\r\n",
		    xd->number, xd->heart_rate, xd->extended_heart_rate, 
		    xd->heart_rate_display, xd->extended_heart_rate_display );
#endif

    atomic {
      g_lock--;
    }
    return out;
  }

  /*****************************************
   *  ParamView interface
   *****************************************/

  const struct Param s_EKG[] = {
    { "datasets", PARAM_TYPE_UINT32, &g_stats.datasets_received },
    { "samples",   PARAM_TYPE_UINT32, &g_stats.samples_received },
    { "bytes",    PARAM_TYPE_UINT32, &g_stats.bytes_received },
    { "sample_rate",    PARAM_TYPE_UINT16, &g_sample_rate },
//    { "samples/pkt",    PARAM_TYPE_UINT16, &g_samples_per_packet },
    { NULL, 0, NULL }
  };

  struct ParamList g_EKGList = { "ekg", &s_EKG[0] };

  command result_t ParamView.init()
  {
    signal ParamView.add( &g_EKGList );
    return SUCCESS;
  }
}
