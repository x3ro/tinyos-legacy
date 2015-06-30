/*                                                                      tab:4
 * Copyright (c) 2003 Intel Corporation
 * All rights reserved Contributions to the above software program by Intel
 * Corporation is program is licensed subject to the BSD License, available at
 * http://www.opensource.org/licenses/bsd-license.html
 *
 */
/*
 * Authors:     Nithya Ramanathan
 *
 */
                                                                                

// Possible actions handled by the power-tracker
enum {
  RT_SEND_DATA  = 1,
  RT_RECV_DATA,
  RT_SEND_NACK, 
  RT_RECV_NACK,
  MOTE_OFF, 
  MOTE_ON,  
  RADIO_ON,  // includes idle mode and Receive mode
  RADIO_OFF,  

  // MUST call RADIO_STOP_SEND after RADIO_START_SEND!
  RADIO_START_SEND, 
  RADIO_STOP_SEND, 
  RADIO_START_RECV, 
  RADIO_STOP_RECV, 
  SENSOR_ON, 
  SENSOR_OFF,
  ANALOG_SENSOR_ON ,
  ANALOG_SENSOR_OFF ,
  DSDV_MSG_SEND ,
  DSDV_MSG_RECV ,
  CONTROL_POWERSAVE_PACKETS_SEND,  
  CONTROL_POWERSAVE_PACKETS_RECV ,
  CONTROL_DATASCHEDULER_PACKETS_SEND, 
  CONTROL_DATASCHEDULER_PACKETS_RECV, 
  MISC_PACKET_TX, 
  MISC_PACKET_RX, 
};

// Struct used to transfer statistics between components
typedef struct Statistics {
  // Power Tracker
  // Naming convention <type>_<module>_<action>_<units>
  // type = num or time
  uint32_t time_mote_on_msec;
  uint32_t time_radio_on_msec;
  uint32_t time_radio_tx_msec;
  uint32_t time_radio_rx_msec;
  uint32_t time_sensor_on_msec;
  uint32_t time_analog_sensor_on_msec;
  uint32_t time_total_sec; // Total time these counters were running
  uint32_t num_times_radio_switched_on;

  // Packet Counters
  // Naming convention <type>_<protocol>_<action>_<pkt_type>
  // type = num or time
  // protocol => rt = reliability, dsdv = routing, ps => power-save, 
  // 	ds => data-scheduler
  uint16_t num_rt_send_data;
  uint16_t num_rt_recv_data;
  uint16_t num_rt_send_nack;
  uint16_t num_rt_recv_nack;
  uint16_t num_dsdv_sent;
  uint16_t num_dsdv_recv;
  uint16_t num_packets_send_total;
  uint16_t num_packets_recv_total;
  uint16_t num_ps_send_ctrl;
  uint16_t num_ps_recv_ctrl;
  uint32_t num_ds_send_ctrl;
  uint32_t num_ds_recv_ctrl;
} Statistics_t;
