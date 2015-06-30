/*
 *
 * Authors:		Jeremey Elson, Naim Busek
 * Date last modified:  6/25/02
 *
 */

/* 
 * This component handles the packet abstraction on the network stack 
 */

module HostMotePacketM {
  provides {
    interface StdControl as Control;
    interface SendHostMoteMsg as Send;
    interface ReceiveHostMoteMsg as Receive;
  }
  uses {
    interface ByteComm;
    interface StdControl as ByteControl;
    interface Leds;
  }
}

//#ifndef NULL
//#define NULL (void *)0
//#endif

implementation {
  /*
   * uart_tx_state is  = -1 if transmitter is idle
   *                   >= 0  if it is busy, representing byte number
   *                         of the uart_tx_msg that we are transmitting.
   */
  #include "host_mote_macros.h"

  int16_t uart_tx_state;		
  int8_t *uart_tx_buf_busy;
  void *uart_tx_msg;
  int16_t uart_tx_msg_len;


  int16_t uart_rx_state;
  HostMote_Msg uart_rx_msg;
  int8_t *uart_rx_msg_write;
  int16_t uart_rx_msg_count;
  int16_t uart_rx_msg_len;
   
  uint8_t *recPtr;
  uint8_t *sendPtr;

  static inline void uart_tx_state_reset();
  static inline void uart_rx_state_reset();

  /* Initialization of this component */
  command result_t Control.init() {
    uart_tx_buf_busy = NULL;
    uart_tx_state_reset();
    uart_rx_state_reset();

    return call ByteControl.init();
  }

  /* Command to control the power of the network stack */
  command result_t Control.start() {
    // apply your power management algorithm
    return call ByteControl.start();
  }

  /* Command to control the power of the network stack */
  command result_t Control.stop() {
    // apply your power management algorithm
    return call ByteControl.stop();
  }
  

  /* ********************* UART Packet Transmission Functions ***************/

  /* utility function used when a UART transmission is finished */
  static inline void uart_tx_state_reset() {
    uart_tx_state = -1;
    uart_tx_msg = NULL;
    uart_tx_msg_len = -1;
    if (uart_tx_buf_busy != NULL) {
      *(uart_tx_buf_busy) = 0;
      uart_tx_buf_busy = NULL;
    }
  }

  /*
   * Transmits the next byte pointed at by uart_tx_state.
   * Increments uart_tx_state
   * Returns the success (or lack thereof) of transmitting the byte
   */
  static inline int uart_tx_next_byte() {
    return call ByteComm.txByte(((char *)uart_tx_msg)[(uint8_t)(uart_tx_state++)]);
  }

  /*
   * Function called when someone wants to send data to the UART.  The
   * caller passes us a pointer to a msg and a length.  The 3rd
   * argument, buf_busy, should be reset to 0 when we are done using the
   * memory pointed to by msg.
   */
  /* Command to transmit a packet */
  command result_t Send.send(void *msg, int len, char *buf_busy) {
    if (uart_tx_state >= 0 || len <= 0 || buf_busy == NULL) {
      /* Transmitter busy, or error in the call */
      return FAIL;
    } else {
      uart_tx_msg = msg;
      uart_tx_msg_len = (int16_t)len;
      uart_tx_buf_busy = buf_busy;
      uart_tx_state = 0;  // tx byte 0

      if (uart_tx_next_byte()) {
        return SUCCESS;
      } else {
        uart_tx_state_reset();
        return FAIL;
      }
    }
  }


  /* Byte level component signals it is ready to accept the next byte.
     Send the next byte if there are data pending to be sent */
  event result_t ByteComm.txByteReady(bool success) {
    /* if we don't think we're in the middle of transmitting a packet,
     * we are very confused indeed; stop here */
    if (uart_tx_state < 0)
      return SUCCESS;
    
    /* If the most recently transmitted byte failed... we're done */
    if (success == 0)
      goto packet_done;
    
    /* If we've transmitted the entire message... we're done */
    if (uart_tx_state >= uart_tx_msg_len)
      goto packet_done;

    
    /* Now try to transmit the next byte.  If it fails... we're done */
    if (!uart_tx_next_byte()) 
      goto packet_done;
    
    return SUCCESS;

  packet_done:
    {
      //void *tmp = uart_tx_msg;
      /* This is a non-ack based layer
         if (success)
         uart_tx_msg->ack = TRUE;
      */
      uart_tx_state_reset();
      signal Send.sendDone(uart_tx_msg, success);
    }
    return SUCCESS;
  }

  event result_t ByteComm.txDone() {
    return SUCCESS;
  }
  /* ******************* Receiving Messages from the UART ********************/


  static inline void uart_rx_state_reset()
    {
      uart_rx_state = 0;
      uart_rx_msg_write = (uint8_t *) &uart_rx_msg;
      uart_rx_msg_count = 0;
      uart_rx_msg_len = -1;
    }

  static inline void uart_rx_save_byte(uint8_t c)
    {
      *(uart_rx_msg_write++) = c;
      uart_rx_msg_count++;
    }


  /* The handles the latest decoded byte propagated by the Byte Level
     component*/
event result_t ByteComm.rxByteReady(uint8_t data, bool error, uint16_t strength)
{
  if (error) {
    uart_rx_state_reset();
    return FAIL;
  }
  
  switch (uart_rx_state) {
  case 0:
    /* State 0: nothing has been received yet; loop in this state
     * until we've received the first framing byte. */
    if (data == HOSTMOTE_FRAME_1) {
      uart_rx_save_byte(data);
      uart_rx_state++;
    }
    break;

    case 1:
      /* State 1: The first framing byte was received; now we're looking
       * for the 2nd framing byte. */
      switch (data) {
      case HOSTMOTE_FRAME_2:
        /* common case: we got the 2nd framing byte; advance to state 2 */
        uart_rx_save_byte(data);
        uart_rx_state++;
        break;

      case HOSTMOTE_FRAME_1:
        /* got another copy of the first framing byte: stay in this
         * state and continue looking for the 2nd */
        break;

      default:

        /* we got some other garbage byte; go back to looking for the
         * first framing byte */
        uart_rx_state_reset();
        break;
      }
      break;


    case 2:
      /* State 2: Both framing bytes have been received; stay in this
       * state until the entire remainder of the header has been read as
       * well (5 bytes) */
      uart_rx_save_byte(data);

      if (uart_rx_msg_count < (int)sizeof(hostmote_header))
        break;

      /* at this point we know we've just now read the entire header */
      uart_rx_msg_len=HOSTMOTE_DATALEN((hostmote_header *)&uart_rx_msg);

      /* if the length is crazy, reset */
      if (uart_rx_msg_len < 0 ||
          uart_rx_msg_len > HOSTMOTE_MAX_DATA_PAYLOAD) {
        uart_rx_state_reset();
        break;
      }

      uart_rx_state++;
      goto check_if_packet_done; /* in case we get datalen = 0 */
      break;


    case 3:
      /* State 3: a complete, valid host-mote header has been read.
       * Now, keep reading bytes until we've read the number specified
       * in the header's length field. */
      uart_rx_save_byte(data);

    check_if_packet_done:
      /* if we've read enough data, we're done */
      if (uart_rx_msg_count-(int)sizeof(hostmote_header) >= uart_rx_msg_len){
        call Leds.redOff();
        signal Receive.receive(&uart_rx_msg);
        uart_rx_state_reset();
      }
      break;
    }
    return SUCCESS;
  }
}



































