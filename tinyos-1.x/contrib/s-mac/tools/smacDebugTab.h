/*
 * this file is the messages to be printed out for S-MAC debugging
 * This table of states and events of S-MAC is used by uartDebugServer.c
 * and uartDebugParser.c
 *
 * Author: Wei Ye (USC/ISI)
 * Date: 03/10/2003
 *
 */

#ifndef STATE_EVENT
#define STATE_EVENT

char *stateEvent[72] = {
   /* S-MAC states */
   "state_SLEEP",
   "state_IDLE",
   "state_CARR_SENSE",
   "state_TX_PKT",
   "state_BACKOFF",
   "state_WAIT_CTS",
   "state_WAIT_DATA",
   "state_WAIT_ACK",
   "state_TX_NEXT_FRAG",
   "state_DATA_SENSE1",
   "state_DATA_SENSE2",
   
   /* pkt transmission events */
   "event_TX_SYNC_DONE",
   "event_TX_RTS_DONE",
   "event_TX_CTS_DONE",
   "event_TX_BCAST_DONE",
   "event_TX_UCAST_DONE",
   "event_TX_ACK_DONE",
   
   /* pkt reception events */
   "event_RX_SYNC_DONE",
   "event_RX_RTS_DONE",
   "event_RX_CTS_DONE",
   "event_RX_BCAST_DONE",
   "event_RX_UCAST_DONE",
   "event_RX_ACK_DONE",
   "event_RX_ERROR",
   "event_RX_UNKNOWN_PKT",
   
   /* timer events */
   "event_TIMER_FIRE_NAV",
   "event_TIMER_FIRE_NEIGHBOR_NAV",
   "event_TIMER_FIRE_DATA_SENSE1",
   "event_TIMER_FIRE_DATA_SENSE2",
   "event_TIMER_FIRE_WAIT_CTS",
   "event_TIMER_FIRE_WAIT_ACK",
   "event_TIMER_FIRE_LISTEN_SYNC",
   "event_TIMER_FIRE_LISTEN_DATA",
   "event_TIMER_FIRE_SCHED_SLEEP",
   "event_TIMER_FIRE_NEED_TX_SYNC",
   "event_TIMER_FIRE_TX_DELAY",
   "event_TIMER_FIRE_ADAP_LISTEN_DONE",
   "event_TIMER_FIRE_TX_RETRY",
   
   /* carrier sense events */
   "event_CHANNEL_BUSY_DETECTED",
   "event_CHANNEL_IDLE_DETECTED",
   "event_START_SYMBOL_DETECTED",
   
   /* other events */
   "event_TRYTOSEND_FAIL_NOT_IDLE",
   "event_TRYTOSEND_FAIL_NAV",
   "event_TRYTOSEND_FAIL_NEIGHBNAV",
   
   /* tx related flags and events */
   "SMAC_TX_REQUEST_IS_0",
   "SMAC_TX_REQUEST_IS_1",
   "SMAC_BCAST_REQUEST_REJECTED_TXREQUEST_IS_1",
   "SMAC_BCAST_REQUEST_REJECTED_DATA_IS_0",
   "SMAC_BCAST_REQUEST_REJECTED_PKTLEN_ERROR",
   "SMAC_UCAST_REQUEST_REJECTED_TXREQUEST_IS_1",
   "SMAC_UCAST_REQUEST_REJECTED_DATA_IS_0",
   "SMAC_UCAST_REQUEST_REJECTED_PKTLEN_ERROR",
   "SMAC_UCAST_REQUEST_REJECTED_NUMFRAGS_IS_0",

   /* application layer */
   "APP_TX_PENDING_IS_0",
   "APP_TX_PENDING_IS_1",
   "APP_TX_BCAST_ACCEPTED_BY_MAC",
   "APP_TX_BCAST_REJECTED_BY_MAC",
   "APP_TX_UCAST_ACCEPTED_BY_MAC",
   "APP_TX_UCAST_REJECTED_BY_MAC",
   "APP_POST_TX_TASK_FAILED",
   "APP_TIME_COUNT_IS_0",
   "APP_TIME_COUNT_NOT_RENEW",
   
   /* physical layer */
   "PHY_RX_BUF_FULL",
   "PHY_STATE_IS_RECEIVING",
   "PHY_STATE_IS_TRANSMITTING",
   
   "event_TIMER_FIRE_TX_ERR",
   "event_TIMER_FIRE_TX_HOLD_PKT",
   "event_TIMER_FIRE_DATA_ACTIVE",
   "event_TIMER_FIRE_UPD_NEIGHB_LIST",
   "event_PHY_RESET_CALLED",
   "event_NUM_NEIGHB_BECOMES_0",
   "event_SYNC_BLOCKED"
   
};

#endif
