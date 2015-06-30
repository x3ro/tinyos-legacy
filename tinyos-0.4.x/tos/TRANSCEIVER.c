/*									tab:4
 * c-basic-offset:8
 *
 * TRANSCEIVER.c - relays packets from serial port to radio, and from
 * radio to serial port
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
 * Authors:   Jeremy Elson, based on code from Jason Hill
 *
 * */

#include "tos.h"
#include "super.h"
#include "TRANSCEIVER.h"

#define NULL 0

#define TOS_FRAME_TYPE TRANSCEIVER_frame
TOS_FRAME_BEGIN(TRANSCEIVER_frame) {
  HostMote_Msg data_to_host;
  char data_to_host_busy;

  HostMote_Msg cdhn_to_host;
  char cdhn_to_host_busy;

  TOS_Msg msg_to_radio_buffer;
  TOS_MsgPtr msg_to_radio;
  char msg_to_radio_busy;

  char rdhn_pending;

  char tx_led_state;
  char rx_led_state;
  char error_led_state;
}
TOS_FRAME_END(TRANSCEIVER_frame);


/* I can't believe I have to write my own stupid memcpy function */
static void memcpy(void *dest_void, const void *src_void, int n)
{
  char *src = (char *) src_void;
  char *dest = (char *) dest_void;

  while (n--)
    *(dest++) = *(src++);
}


/* TRANSCEIVER_INIT:  called when we start up */
char TOS_COMMAND(TRANSCEIVER_INIT)()
{
  /* initialize lower components */
  TOS_CALL_COMMAND(TRANSCEIVER_SUB_INIT)();
  TOS_CALL_COMMAND(TRANSCEIVER_SUB_UART_INIT)();

  /* initialize our own state */
  VAR(data_to_host_busy) = 0;
  VAR(cdhn_to_host_busy) = 0;
  VAR(msg_to_radio_busy) = 0;
  VAR(rdhn_pending) = 0;
  VAR(tx_led_state) = 0;
  VAR(rx_led_state) = 0;
  VAR(error_led_state) = 0;
  VAR(msg_to_radio) = &VAR(msg_to_radio_buffer);

  printf("TRANSCEIVER initialized\n");
  return 1;
}


char TOS_COMMAND(TRANSCEIVER_START)()
{
  return 1;
}


/***********************************************************************/


/*
 * This is called when a packet arrives from the transceiver and needs
 * to be sent out to the UART
 */
TOS_MsgPtr TOS_EVENT(TRANSCEIVER_RX_PACKET)(TOS_MsgPtr data)
{
  if (data == NULL)
    goto done;

  /* don't bother delivering "null" packets that sometimes arrive */
  if (data->group == 0 && data->addr == 0 && data->type == 0)
    goto done;

#if 0
  /* FILTERING IS NOW DONE IN THE DRIVER */
  if (data->group != LOCAL_GROUP)
    goto done;

  if (data->addr != TOS_MOTENIC_ADDR)
    goto done;
#endif
  
  printf("TRANSCEIVER received packet\n");

  /* run the RX LED */
  if (VAR(rx_led_state))
    SET_GREEN_LED_PIN();
  else
    CLR_GREEN_LED_PIN();
  VAR(rx_led_state) = !VAR(rx_led_state);

  if (VAR(data_to_host_busy)) {
    printf("TRANSCEIVER_RX_PACKET: dropping packet received from radio");
    goto done;
  }

  printf("TRANSCEIVER forwarding packet to UART\n");
  VAR(data_to_host_busy) = 1;

  HOSTMOTE_SET_FRAME(&VAR(data_to_host.header));
  HOSTMOTE_SET_OPNUM(HOSTMOTE_DNH, &VAR(data_to_host.header));

#if 0
  /* ENTIRE TOS_MSG STRUCTURE IS NOW GIVEN TO DRIVER */
  HOSTMOTE_SET_DATALEN(data->length, &VAR(data_to_host.header));
  memcpy(VAR(data_to_host.data), data->data, data->length);

  TOS_COMMAND(TRANSCEIVER_SUB_UART_TX_PACKET)
    (&VAR(data_to_host), sizeof(hostmote_header) + data->length,
     &VAR(data_to_host_busy));
#endif

  HOSTMOTE_SET_DATALEN(sizeof(TOS_Msg), &VAR(data_to_host.header));
  memcpy(VAR(data_to_host.data), data, sizeof(TOS_Msg));

  TOS_COMMAND(TRANSCEIVER_SUB_UART_TX_PACKET)
    (&VAR(data_to_host), sizeof(hostmote_header) + sizeof(TOS_Msg),
     &VAR(data_to_host_busy));

 done:
  return data;
}



/***********************************************************************/


/* This function may (depending on state) send a CDHN (Clear for Data
 * from Host to NIC).  We only send one:
 *
 * 1- If we're waiting to send one (i.e., rdhn_pending is set)
 *
 * 2- If the buffer we use to send packets to radios is empty;
 * i.e. ready to receive a new packet.
 *
 * 3- The buffer we use to send the CDHN itself is not in use
 */
void maybe_launch_cdhn()
{
  if (!VAR(rdhn_pending))
    return;

  if (VAR(msg_to_radio_busy))
    return;

  if (VAR(cdhn_to_host_busy))
    return;

  VAR(cdhn_to_host_busy) = 1;
  HOSTMOTE_SET_FRAME(&VAR(cdhn_to_host.header));
  HOSTMOTE_SET_OPNUM(HOSTMOTE_CDHN, &VAR(cdhn_to_host.header));
  HOSTMOTE_SET_DATALEN(0, &VAR(cdhn_to_host.header));
  if (TOS_COMMAND(TRANSCEIVER_SUB_UART_TX_PACKET)
      (&VAR(cdhn_to_host), sizeof(hostmote_header),
       &VAR(cdhn_to_host_busy))) {
    VAR(rdhn_pending) = 0;
  }
}


void flip_error_led()
{
  if (VAR(error_led_state))
    SET_YELLOW_LED_PIN();
  else
    CLR_YELLOW_LED_PIN();
  VAR(error_led_state) = !VAR(error_led_state);
}



/*
 * This is called when a complete host-mote packet has arrived from
 * the UART
 */
void TOS_EVENT(TRANSCEIVER_UART_RX_PACKET)(HostMote_MsgPtr data)
{
  switch(HOSTMOTE_OPNUM(&(data->header))) {
  case HOSTMOTE_NOOP:
    break;

  case HOSTMOTE_DHN:
    if (VAR(msg_to_radio_busy)) {
      printf("!!! BUG - radio message busy, dropping packet from host\n");
      break;
    }

    /* run the TX LED */
    if (VAR(tx_led_state))
      SET_RED_LED_PIN();
    else
      CLR_RED_LED_PIN();
    VAR(tx_led_state) = !VAR(tx_led_state);

    /* copy the message out to the radio */
#if 0
    /* DRIVER NOW SENDS US A COMPLETE TOS_MSG STRUCTURE */
    VAR(msg_to_radio->addr) = TOS_MOTENIC_ADDR;
    VAR(msg_to_radio->group) = LOCAL_GROUP;
    VAR(msg_to_radio->length) = HOSTMOTE_DATALEN(&(data->header));
    memcpy(VAR(msg_to_radio->data),data->data,HOSTMOTE_DATALEN(&(data->header)));
#endif
    /* raise an error if the length is not exactly a TOS_Msg */
    if (HOSTMOTE_DATALEN(&(data->header)) != sizeof(TOS_Msg)) {
      flip_error_led();
    } else {
      memcpy(VAR(msg_to_radio), data->data, sizeof(TOS_Msg));

      printf("TRANSCEIVER forwarding packet from UART to RFM\n");
      if (TOS_COMMAND(TRANSCEIVER_TX_PACKET)(VAR(msg_to_radio)))
	VAR(msg_to_radio_busy) = 1;
    }
    break;

  case HOSTMOTE_RDHN:
    VAR(rdhn_pending) = 1;
    maybe_launch_cdhn();
    break;

  case HOSTMOTE_RST:
    TOS_COMMAND(TRANSCEIVER_INIT)();
    break;

  default:
    printf("Unsupported packet opnum received\n");
    break;
  }
}

/*
 * Signal telling us the radio is now available to send something
 */
char TOS_EVENT(TRANSCEIVER_TX_PACKET_DONE)(TOS_MsgPtr data)
{
  VAR(msg_to_radio) = data;
  VAR(msg_to_radio_busy) = 0;
  maybe_launch_cdhn();
  return 1;
}

/*
 * Signal telling us the UART is now available to send something
 */
char TOS_EVENT(TRANSCEIVER_SUB_UART_TX_PACKET_DONE)(TOS_MsgPtr data)
{
  maybe_launch_cdhn();
  return 1;
}
