/*									tab:4
 *
 *
 * "Copyright (c) 2000 and The Regents of the University 
 * of California.  All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice and the following
 * two paragraphs appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 *
 * Authors:		Jason Hill
 *
 *
 */



#include "tos.h"
#include "super.h"
#include "UART_PACKET_HOSTMOTE.h"


#ifdef FULLPC
#include "Fullpc_uart_connect.h"
#endif

#define NULL 0

#define TOS_FRAME_TYPE UART_PACKET_HOSTMOTE_obj_frame
TOS_FRAME_BEGIN(UART_PACKET_HOSTMOTE_obj_frame) {
  /*
   * uart_tx_state is  = -1 if transmitter is idle
   *                   >= 0  if it is busy, representing byte number
   *                         of the uart_tx_msg that we are transmitting.
   */
  char uart_tx_state;		
  char *uart_tx_buf_busy;
  void *uart_tx_msg;
  char uart_tx_msg_len;


  char uart_rx_state;
  HostMote_Msg uart_rx_msg;
  char *uart_rx_msg_write;
  char uart_rx_msg_count;
  char uart_rx_msg_len;
}
TOS_FRAME_END(UART_PACKET_HOSTMOTE_obj_frame);



static inline void uart_tx_state_reset();
static inline void uart_rx_state_reset();


char TOS_COMMAND(UART_PACKET_HOSTMOTE_INIT)()
{
#ifdef FULLPC
  udp_init_socket();
  printf("UART Packet handler initialized.\n");
#endif

  VAR(uart_tx_buf_busy) = NULL;
  uart_tx_state_reset();
  uart_rx_state_reset();
  TOS_CALL_COMMAND(UART_PACKET_HOSTMOTE_SUB_INIT)();

  return 1;
} 


#ifndef FULLPC


/********************** UART Packet Transmission Functions ***************/

/* utility function used when a UART transmission is finished */
static inline void uart_tx_state_reset()
{
  if (VAR(uart_tx_buf_busy) != NULL) {
    *(VAR(uart_tx_buf_busy)) = 0;
    VAR(uart_tx_buf_busy) = NULL;
  }
  VAR(uart_tx_state) = -1;
  VAR(uart_tx_msg) = NULL;
  VAR(uart_tx_msg_len) = -1;
}


/*
 * Transmits the next byte pointed at by uart_tx_state.
 * Increments uart_tx_state
 * Returns the success (or lack thereof) of transmitting the byte
 */
static inline int uart_tx_next_byte(void)
{
  return TOS_CALL_COMMAND(UART_PACKET_HOSTMOTE_SUB_TX_BYTES)
    (((char *)VAR(uart_tx_msg))[(int)(VAR(uart_tx_state)++)]);
}


/*
 * Function called when someone wants to send data to the UART.  The
 * caller passes us a pointer to a msg and a length.  The 3rd
 * argument, buf_busy, should be reset to 0 when we are done using the
 * memory pointed to by msg.
 */
char TOS_COMMAND(UART_PACKET_HOSTMOTE_TX_PACKET)(void *msg, short len, char *buf_busy)
{
  if (VAR(uart_tx_state) >= 0 || len <= 0 || buf_busy == NULL) {
    /* Transmitter busy, or error in the call */
    *buf_busy = 0;
    return 0;
  } else {
    VAR(uart_tx_msg) = msg;
    VAR(uart_tx_msg_len) = len;
    VAR(uart_tx_buf_busy) = buf_busy;
    VAR(uart_tx_state) = 0;

    if (uart_tx_next_byte()) {
      return 1;
    } else {
      uart_tx_state_reset();
      return 0;
    }
  }
}


/* called every time we finish sending one byte over the radio */
char TOS_EVENT(UART_PACKET_HOSTMOTE_TX_BYTE_READY)(char success)
{
  /* if we don't think we're in the middle of transmitting a packet,
   * we are very confused indeed; stop here */
  if (VAR(uart_tx_state) < 0)
    return 1;

  /* If the most recently transmitted byte failed... we're done */
  if (success == 0)
    goto packet_done;

  /* If we've transmitted the entire message... we're done */
  if (VAR(uart_tx_state) >= VAR(uart_tx_msg_len))
    goto packet_done;

  /* Now try to transmit the next byte.  If it fails... we're done */
  if (!uart_tx_next_byte())
    goto packet_done;

  return 1;

 packet_done:
  TOS_SIGNAL_EVENT(UART_PACKET_HOSTMOTE_TX_PACKET_DONE)(VAR(uart_tx_msg));
  uart_tx_state_reset();
  return 1;
}


#endif



/******************** Receiving Messages from the UART ********************/


static inline void uart_rx_state_reset()
{
  VAR(uart_rx_state) = 0;
  VAR(uart_rx_msg_write) = (char *) &VAR(uart_rx_msg);
  VAR(uart_rx_msg_count) = 0;
  VAR(uart_rx_msg_len) = -1;
}

static inline void uart_rx_save_byte(char c)
{
  *(VAR(uart_rx_msg_write)++) = c;
  VAR(uart_rx_msg_count)++;
}


char TOS_EVENT(UART_PACKET_HOSTMOTE_RX_BYTE_READY)(char data, char error)
{
#ifdef FULLPC_DEBUG
  printf("UART PACKET: byte arrived: %x, STATE: %d, COUNT: %d\n", data, VAR(state), VAR(count));
#endif
  if (error) {
    uart_rx_state_reset();
    return 0;
  }

  switch (VAR(uart_rx_state)) {
  case 0: /* nothing received yet: look for 1st framing byte */
    if (data == MOTENIC_FRAME_1) {
      uart_rx_save_byte(data);
      VAR(uart_rx_state)++;
    }
    break;
  case 1: /* first framing byte received: look for 2nd framing byte */
    if (data == MOTENIC_FRAME_2) {
      uart_rx_save_byte(data);
      VAR(uart_rx_state)++;
    } else {
      uart_rx_state_reset();
    }
    break;
  case 2: /* framing bytes received: read the header */
    uart_rx_save_byte(data);

    if (VAR(uart_rx_msg_count) < sizeof(hostmote_header))
      break;

    /* at this point we know we've just now read the entire header */
    VAR(uart_rx_msg_len)=HOSTMOTE_DATALEN((hostmote_header *)&VAR(uart_rx_msg));

    /* if the length is crazy, reset */
    if (VAR(uart_rx_msg_len) < 0 ||
	VAR(uart_rx_msg_len) > HOSTMOTE_MAX_DATA_PAYLOAD) {
      uart_rx_state_reset();
      break;
    }

    VAR(uart_rx_state)++;
    goto check_if_packet_done; /* in case we get datalen = 0 */
    break;
  case 3: /* we've read a valid header; now read data */
    uart_rx_save_byte(data);

  check_if_packet_done:
    /* if we've read enough data, we're done */
    if (VAR(uart_rx_msg_count)-sizeof(hostmote_header)>= VAR(uart_rx_msg_len)){
      TOS_SIGNAL_EVENT(UART_PACKET_HOSTMOTE_RX_PACKET_DONE)(&VAR(uart_rx_msg));
      uart_rx_state_reset();
    }
    break;
  }

  return 1;
}


//char TOS_EVENT(UART_PACKET_HOSTMOTE_BYTE_TX_DONE)(){
//    return 1;
//}


void TOS_COMMAND(UART_PACKET_HOSTMOTE_POWER)(char mode){
    //do this later;
    ;
}

/********************* Stuff only used in FullPC Mode **********************/

#ifdef FULLPC

char TOS_COMMAND(UART_PACKET_HOSTMOTE_TX_PACKET)(char *msg, short len, char *buf_busy)
{
  int i;

  *buf_busy = 0;

  if(uart_send != 0)
    printf("uart sending packet: %d \n", write(uart_send, msg, len));

  for(i = 0; i < len; i ++)
    printf("%x,", msg[i]);

  printf("\n");

  return 0;
}

/* should never be called I think */
char TOS_EVENT(UART_PACKET_HOSTMOTE_TX_BYTE_READY)(char success)
{
  return 0;
}

void uart_packet_evt()
{
  int avilable;
  ioctl(uart_send, FIONREAD, &avilable);
  if(avilable > sizeof(TOS_Msg)){
    read(uart_send, VAR(rec_ptr), sizeof(TOS_Msg));
    TOS_SIGNAL_EVENT(UART_PACKET_HOSTMOTE_RX_PACKET_DONE)((TOS_MsgPtr)VAR(rec_ptr));
    printf("got packet\n");
  }

}



#endif
