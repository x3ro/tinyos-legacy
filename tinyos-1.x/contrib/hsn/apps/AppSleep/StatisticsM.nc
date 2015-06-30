
/*
 * Copyright (c) 2002-2003 Intel Corporation
 * All rights reserved.
 */
                                                                                
/*
 * Authors:             Nithya Ramanathan
 *
 *
 */
                                                                                
/**
 * Generic Interface to report a countable event to the counter component
 */

includes PacketTypes;

module StatisticsM
{
  provides {
    interface StdControl;
    interface RetreiveStatistics;
    interface ReportPacketEvent;
  }
  uses {
    interface SysTime; //fixme - assuming SysTime procides time in msec!!
  }
}

implementation
{
  Statistics_t stats;
  Statistics_t stats_start; // Records when an event starts
  Statistics_t stats_on; // Indicates if an event's start time is valid!
  uint32_t start_time_msec;

  command result_t RetreiveStatistics.ResetStatistics()
  {
    memset(&stats, 0, sizeof(Statistics_t));
    memset(&stats_start, 0, sizeof(Statistics_t));
    memset(&stats_on, 0, sizeof(Statistics_t));
    start_time_msec = call SysTime.getTime32();
    return SUCCESS;
  }

  command result_t RetreiveStatistics.Retreive(Statistics_t* statistics)
  {
    uint32_t t = call SysTime.getTime32();
    atomic stats.time_total_sec = (t - start_time_msec) / 1000;
  
    // For the time related ones, we want to get the current
    // snap shot, so we just signal each to go off and then on again
    // if they were initially on.
    atomic {
      if (stats_on.time_mote_on_msec == 1) {
        call ReportPacketEvent.PacketEvent(MOTE_OFF, 0);
        call ReportPacketEvent.PacketEvent(MOTE_ON, 0);
      }
    }
    atomic {
      if (stats_on.time_radio_on_msec == 1) {
        call ReportPacketEvent.PacketEvent(RADIO_OFF, 0);
        call ReportPacketEvent.PacketEvent(RADIO_ON, 0);
      }
    }
    atomic {
      if (stats_on.time_radio_tx_msec == 1) {
        call ReportPacketEvent.PacketEvent(RADIO_STOP_SEND, 0);
        call ReportPacketEvent.PacketEvent(RADIO_START_SEND, 0);
      }
    }
    atomic {
      if (stats_on.time_radio_rx_msec == 1) {
        call ReportPacketEvent.PacketEvent(RADIO_STOP_RECV, 0);
        call ReportPacketEvent.PacketEvent(RADIO_START_RECV, 0);
      }
    }
    atomic {
      if (stats_on.time_sensor_on_msec == 1) {
        call ReportPacketEvent.PacketEvent(SENSOR_OFF, 0);
        call ReportPacketEvent.PacketEvent(SENSOR_ON, 0);
      }
    }
    atomic {
      if (stats_on.time_analog_sensor_on_msec == 1) {
        call ReportPacketEvent.PacketEvent(ANALOG_SENSOR_OFF, 0);
        call ReportPacketEvent.PacketEvent(ANALOG_SENSOR_ON, 0);
      }
    }

    atomic *statistics = stats;
    return SUCCESS;
  }

  command result_t StdControl.init()
  {
    return SUCCESS;
  }

  command result_t StdControl.start()
  {
    call RetreiveStatistics.ResetStatistics();
    return SUCCESS;
  }

  command result_t StdControl.stop()
  {
    return SUCCESS;
  }

  void task CallStopSend()
  {
    call ReportPacketEvent.PacketEvent(RADIO_STOP_SEND, 0);
  }

  async command result_t ReportPacketEvent.PacketEvent(uint16_t type, uint32_t seqno)
  {
    uint32_t t = 0;
    uint32_t time_diff;
                                                                                
    switch(type) {
      case(RT_SEND_DATA):
        atomic stats.num_packets_send_total++;
        atomic stats.num_rt_send_data++;
        break;
      case(RT_RECV_DATA):
        atomic stats.num_packets_recv_total++;
        atomic stats.num_rt_recv_data++;
        break;
      case(RT_SEND_NACK): 
        atomic stats.num_packets_send_total++;
        atomic stats.num_rt_send_nack++;
        break;
      case(RT_RECV_NACK):
        atomic stats.num_packets_recv_total++;
        atomic stats.num_rt_recv_nack++;
        break;
      case(DSDV_MSG_SEND ):
        atomic stats.num_packets_send_total++;
        atomic stats.num_dsdv_sent++;
        break;
      case(DSDV_MSG_RECV ):
        atomic stats.num_packets_recv_total++;
        atomic stats.num_dsdv_recv++;
        break;
      case(CONTROL_POWERSAVE_PACKETS_SEND):  
        atomic stats.num_packets_send_total++;
        atomic stats.num_ps_send_ctrl++;
        break;
      case(CONTROL_POWERSAVE_PACKETS_RECV ):
        atomic stats.num_packets_recv_total++;
        atomic stats.num_ps_recv_ctrl++;
        break;
      case(CONTROL_DATASCHEDULER_PACKETS_SEND): 
        atomic stats.num_packets_send_total++;
        atomic stats.num_ds_send_ctrl++;
        break;
      case(CONTROL_DATASCHEDULER_PACKETS_RECV): 
        atomic stats.num_packets_recv_total++;
        atomic stats.num_ds_recv_ctrl++;
        break;
      case(MISC_PACKET_RX ):
        atomic stats.num_packets_recv_total++;
        break;
      case(MISC_PACKET_TX ):
        atomic stats.num_packets_send_total++;
        break;

      // The remainder are time-based
      default:
        t = call SysTime.getTime32();
        switch(type) {
	  case(MOTE_ON):  
            atomic {
            if (stats_on.time_mote_on_msec == 0) {
              stats_start.time_mote_on_msec = t;
              stats_on.time_mote_on_msec = 1;
            }
            }
	    break;
          case(MOTE_OFF): 
            atomic {
              if (stats_on.time_mote_on_msec == 1) {
                time_diff = t - stats_start.time_mote_on_msec;
                stats.time_mote_on_msec += time_diff;
                stats_on.time_mote_on_msec = 0;
              }
            }
	    break;
	  case(RADIO_ON):  // includes idle mode and Receive mode
            atomic {
            if (stats_on.time_radio_on_msec == 0) {
              stats.num_times_radio_switched_on++; 
              atomic stats_start.time_radio_on_msec = t;
              atomic stats_on.time_radio_on_msec = 1;
            }
            }
	    break;
	  case(RADIO_OFF):  
            atomic {
              if (stats_on.time_radio_on_msec == 1) {
                time_diff = t - stats_start.time_radio_on_msec;
	        stats.time_radio_on_msec += time_diff;
	        stats_on.time_radio_on_msec = 0;

                // If the radio was sending, and not turned off, then we know
                // it stopped sending!
	        if (stats_on.time_radio_tx_msec == 1) { 
                  post CallStopSend();
                }
              }
            }
	    break;
	  case(RADIO_START_SEND): 
            atomic {
              if (stats_on.time_radio_tx_msec == 0) {
                stats_start.time_radio_tx_msec = t;
                stats_on.time_radio_tx_msec = 1;
              }
            }
	    break;
	  case(RADIO_STOP_SEND): 
            atomic {
              if (stats_on.time_radio_tx_msec == 1) {
                time_diff = t - stats_start.time_radio_tx_msec;
                stats.time_radio_tx_msec += time_diff;
                stats_on.time_radio_tx_msec = 0;
              }
            }
	    break;
	  case(RADIO_START_RECV): 
            atomic {
              if (stats_on.time_radio_rx_msec == 0) {
                stats_start.time_radio_rx_msec = t;
                stats_on.time_radio_rx_msec = 1;
              }
            }
	    break;
	  case(RADIO_STOP_RECV): 
            atomic {
              if (stats_on.time_radio_rx_msec == 1) {
                time_diff = t - stats_start.time_radio_rx_msec;
                stats.time_radio_rx_msec += time_diff;
                stats_on.time_radio_rx_msec = 0;
              }
            }
	    break;
	  case(SENSOR_ON): 
            atomic {
            if (stats_on.time_sensor_on_msec == 0) {
              stats_start.time_sensor_on_msec = t;
              stats_on.time_sensor_on_msec = 1;
            }
            }
	    break;
	  case(SENSOR_OFF):
            atomic {
              if (stats_on.time_sensor_on_msec == 1) {
	        time_diff = t - stats_start.time_sensor_on_msec;
	        stats.time_sensor_on_msec += time_diff;
	        stats_on.time_sensor_on_msec = 0;
              }
            }
	    break;
	  case(ANALOG_SENSOR_ON ):
            atomic {
              if (stats_on.time_analog_sensor_on_msec == 0) {
	        stats_start.time_analog_sensor_on_msec = t;
                stats_on.time_analog_sensor_on_msec = 1;
              }
            }
	    break;
	  case(ANALOG_SENSOR_OFF ):
            atomic {
              if (stats_on.time_analog_sensor_on_msec == 1) {
	        time_diff = t - stats_start.time_analog_sensor_on_msec;
	        stats.time_analog_sensor_on_msec += time_diff;
	        stats_on.time_analog_sensor_on_msec = 0;
              }
            }
	    break;
        }
        break;
    }
    return SUCCESS;
  }
}
