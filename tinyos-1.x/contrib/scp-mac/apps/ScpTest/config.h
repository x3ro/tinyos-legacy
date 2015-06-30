/*
 * Copyright (C) 2005 the University of Southern California.
 * All rights reserved.
 *
 * This program is free software; you can redistribute it and/or modify it
 * under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation; either version 2.1 of the License, or (at
 * your option) any later version.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
 * or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public
 * License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program; if not, write to the Free Software Foundation,
 * Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301, USA.
 *
 * In addition to releasing this program under the LGPL, the authors are
 * willing to dual-license it under other terms. You may contact the authors
 * of this project by writing to Wei Ye, USC/ISI, 4676 Admirality Way, Suite 
 * 1001, Marina del Rey, CA 90292, USA.
 */
/*
 * Authors: Wei Ye, Fabio Silva, Asif Pathan
 *
 * This file configures parameters of all components used by the application.
 * It is supposed to be included before any other files in an 
 * application's configuration (wiring) file, such as Test.nc, so that these
 * macro definations will override default definations in other files.
 * These macros are in the global name space, so use a prefix to indicate
 * which layers they belong to.
 *
 */

#ifndef CONFIG
#define CONFIG

/* Disable CPU sleep mode when radio is off.
 * should disable CPU sleep when UART debugging is used
 */
//#define DISABLE_CPU_SLEEP

/* Configure Physical layer. Definitions here override default values
 * Default values are defined in PhyMsg.h and PhyConst.h
 * Max value: Mica2 -- 250 (bytes), MicaZ -- 127 (bytes)
 * --------------------------------------------------------------
 */
#define PHY_MAX_PKT_LEN 100

/* configure radio transmission power (0x01--0xff)
 * NOTE: Currently this parameter only works on Mica2
 * Following sample values are for 433MHz mica2: 0x0f=0dBm (TinyOS default)
 * 0x0B = -3dBm, 0x08 = -6dBm, 0x05 = -9dBm, 0x03 = -14dBm 0x01 = -20dBm
 * 0x0f =  0dBm, 0x50 =  3dBm, 0x80 =  6dBm, 0xe0 =  9dBm, 0xff =  10dBm
 */
//#define RADIO_TX_POWER 0x03

/* Tell PHY to measure radio energy usage, for performace analysis.
 */
//#define RADIO_MEASURE_ENERGY

/* Configure CSMA. Look for CsmaConst.h for details.
 * -------------------------------------------------
 */
//#define CSMA_CW 32              // contention window size, must be 2^n
//#define CSMA_BACKOFF_TIME 20
#define CSMA_RTS_THRESHOLD 101
//#define CSMA_BACKOFF_LIMIT 7
//#define CSMA_RETX_LIMIT 3
//#define CSMA_ENABLE_OVERHEARING  // overhearing is disabled by default

/* Configure LPL. Look for LplConst.h for details.
 * -----------------------------------------------
 */
//#define LPL_POLL_PERIOD 512  // LPL polling period (binary ms)

/* Configure SCP. Look for ScpConst.h for details.
 * -----------------------------------------------
 */
//#define SCP_POLL_PERIOD 1024  // SCP polling period (binary ms)

/* There are two ways to set up a sleep/wakup schedule.
 * The default one is using a automatic boot process with the following
 * configurable parameters.
 * NOTE: automatic booting does not fully work on MicaZ now
 */
//#define SCP_PASSIVE_DISCOVERY_TIMEOUT 1
//#define SCP_ACTIVE_DISCOVERY_TIMEOUT 3
//#define NUM_SCP_ACTIVE_DISCOVERY_REQUESTS 5

/* The manual boot specifies one master node to start a schedule.
 * To use this boot process, define the following macro
 * NOTE: we suggest to use manual boot for MicaZ now. 
 */
//#define USE_FIXED_BOOT

/* To specify the master, define the following macro.
 * Otherwise, the node will be configured as a slave.
 * Start all slave nodes before the master.
 * Slave nodes only perform LPL and wait to synchronize with the master.
 */
//#define SCP_MASTER_SCHEDULE

#define GLOBAL_SCHEDULE

/* Adaptive listen is enabled by default. 
 * define the following macro to disable it
 */
//#define SCP_DISABLE_ADAPTIVE_POLLING

/* Define the following macro to maintaion schedule age for the
 * global schedule algorithm.
 */
//#define MAINTAIN_SCHEDULE_AGE

/* Configure the test application
 * -------------------------------
 */
/* Node ID range. Should at least have 2 nodes.
 * Node IDs must be consecutive from min to max
 */
#define TST_MIN_NODE_ID 1
#define TST_MAX_NODE_ID 2

/* TST_MSG_INTERVAL controls how fast a node generates a message.
 * Setting it to 0 makes it generates second packet right after the 
 * first is sent.
 */
#define TST_MSG_PERIOD   0     // in binary ms

/* By default, each node keeps sending until it is powered off.
 * To let a node automatically stops after sending a sepecified number
 * of messages, define the following macro
 */
//#define TST_NUM_MSGS 20

/* By default, each node alternate in sending broadcast and unicast.
 * You can let a node to only send broadcast or unicast as follows.
 * NOTE: currently unicast on MicaZ is not very stable
 */
//#define TST_BROADCAST_ONLY   // test broadcast only
//#define TST_UNICAST_ONLY     // test unicast only

/* For unicast, node i sends to (i+1), and node MaxId sends to MinId
 * But you can explicitly specify unicast address for each node
 */
//#define TST_UNICAST_ADDR 2   // specify unicast address

/* The following macro makes a node receive only (no data transmission)
 */
//#define TST_RECEIVE_ONLY

/* A receive-only node can optionally report result after a delay from 
 * last reception. The following macro enables reporting, and defines 
 * how large the delay is (binary ms)
 */
//#define TST_REPORT_DELAY 5120


/* Define one of the following macros to enables LED debugging at a 
 * specific component.
 */
//#define SCP_LED_DEBUG
#define LPL_LED_DEBUG
//#define CSMA_LED_DEBUG
//#define PHY_LED_DEBUG

/* For Phy LED debugging, choose ONE of the following three
 * NOTE: they are only used for MicaZ now
 */
//#define PHY_LED_STATE_DEBUG
//#define PHY_LED_SEND_RCV_DEBUG
//#define PHY_LED_CS_DEBUG

/* Debugging with the oscilloscope by toggling pins
 * NOTE: they are only used for MicaZ now
 */
//#define PHY_SHOW_CS_PW3
//#define PHY_SHOW_TP_PW3
//#define PHY_SHOW_TP_PW4
#define PHY_SHOW_RADIO_ON_PW4
//#define PHY_SHOW_RECV_PW6
//#define PHY_SHOW_SEND_DELAY_PW6
//#define LPL_SHOW_POLLING

/* Debugging with a snooper by adding debugging info to data pkts.
 * You don't need to enable it if you don't add anything to data pkts.
 */
//#define SCP_SNOOPER_DEBUG

/* debugging with a serial port (UART)
 * -----------------------------------
 * Don't enable it unless you know what's going to happen.
 * There is a known problem on Mica2 motes. If UART debugging is enabled
 * but the mote is not connected with the serial board/cable, very often
 * it fails to start. It occasionally happens when the mote connects with
 * the serial board/cable.
 */
/* Debugging with predefined states and events
 * The following macros are mutually exclusive. You should only define one.
 * They also don't work simultaneously with XXX_UART_DEBUG_BYTE macros.
 */
//#define SCP_UART_DEBUG_STATE_EVENT
//#define LPL_UART_DEBUG_STATE_EVENT
//#define CSMA_UART_DEBUG_STATE_EVENT
//#define TIMER_UART_DEBUG_STATE_EVENT

/* Debugging by sending an arbitrary byte to UART
 * The following macros are not mutually exclusive. You can define multiples.
 * But they don't work simultaneously with XXX_UART_DEBUG_STATE_EVENT macros.
 */
//#define SCP_UART_DEBUG_BYTE
//#define LPL_UART_DEBUG_BYTE
//#define CSMA_UART_DEBUG_BYTE
//#define PHY_UART_DEBUG_BYTE
//#define TIMER_UART_DEBUG_BYTE

/* include MAC message and header definitions
 */
#include "ScpMsg.h"
typedef ScpHeader MacHeader;

#endif  // CONFIG
