
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
 * Authors:   Jeremy Elson
 *
 * */


#include "tos.h"
#include "super.h"
#include "TRANSCEIVER.h"
#include "string.h"

#define MAGIC 0xabcd


#define TOS_FRAME_TYPE TRANSCEIVER_frame
TOS_FRAME_BEGIN(TRANSCEIVER_frame) {

  /* buffer for data from host */
  TOS_Msg msg_to_radio_buffer;
  TOS_MsgPtr msg_to_radio;
  char msg_to_radio_busy;

  /* buffer for data to host */
  hostmote_header data_to_host;
  TOS_Msg data_msg;
  TOS_Msg data_msg2;
  char data_to_host_busy;
  char data_to_host_queued;
  char data_to_host_inprogress;

  /* header for CDHN message */
  hostmote_header cdhn_to_host;
  char cdhn_to_host_busy;

  /* header and CONF/STAT message */
  hostmote_header conf_to_host;
  struct mote_conf conf;
  uint8_t conf_to_host_busy;

#ifdef USE_HOSTMOTE_SENS
  /* header and SENS message */
  hostmote_header sens_to_host;
  struct mote_sens sens;
  uint8_t sensor_readings[32];
  uint32_t sens_clock;
  uint8_t sens_clock_valid;
  uint8_t sens_count;
  uint8_t sens_to_host_busy;

  uint8_t sens_send_needed;
  uint8_t sens_send_inprogress;
#endif

  uint8_t conf_send_needed;
  uint8_t uart_inuse;
  uint8_t rdhn_pending;
  uint8_t tx_led_state;
  uint8_t rx_led_state;
  uint8_t error_led_state;

  uint16_t magic;
}
TOS_FRAME_END(TRANSCEIVER_frame);


/*
 *  useful function to cast header to correct type for UART_PACKET
 */

static inline
HostMote_MsgPtr cast_hostmote_header(hostmote_header *header)
{ return (HostMote_MsgPtr)header; }


/*
 *  MUTEX macro
 *    tests and sets var, does prog if originally clear
 *    if reset, clears var after prog
 */

#define MUTEX(var, reset, prog) \
do { \
  cli(); \
  if (!var) { \
    var = 1; \
    sei(); \
    do prog while (0); \
    if (reset) var = 0; \
  } else sei(); \
} while (0)

#define RESET_VAR  1
#define DONT_RESET 0


/* prototypes */
TOS_TASK(trysend);

/* resets most transceiver state */
void transceiver_reset()
{
  /* initialize our own state */
  memset(&VAR(msg_to_radio_buffer), 0, sizeof(TOS_FRAME_TYPE));

  VAR(msg_to_radio) = &VAR(msg_to_radio_buffer);
  VAR(magic) = MAGIC;

	CLR_YELLOW_LED_PIN();
	CLR_RED_LED_PIN();
	CLR_GREEN_LED_PIN();
  printf("TRANSCEIVER initialized\n");
}


void flip_error_led()
{
  if (VAR(error_led_state))
    SET_YELLOW_LED_PIN();
  else
    CLR_YELLOW_LED_PIN();
  VAR(error_led_state) = !VAR(error_led_state);
}

void flip_tx_led()
{
	if (VAR(tx_led_state))
		SET_RED_LED_PIN();
	else
		CLR_RED_LED_PIN();
	VAR(tx_led_state) = !VAR(tx_led_state);
}

void flip_rx_led()
{
	if (VAR(rx_led_state))
		SET_GREEN_LED_PIN();	
	else
		CLR_RED_LED_PIN();
	VAR(rx_led_state) = !VAR(rx_led_state);
}

/* TRANSCEIVER_INIT:  called when we start up */
char TOS_COMMAND(TRANSCEIVER_INIT)()
{
  /* initialize lower components */
  TOS_CALL_COMMAND(TRANSCEIVER_SUB_INIT)();
  TOS_CALL_COMMAND(TRANSCEIVER_SUB_UART_INIT)();
#if CLOCK_COUNTER_NUM == ITC_16
  TOS_CALL_COMMAND(TRANSCEIVER_TIMER1CLOCK_INIT)(itc16_tick1ps);
#elif CLOCK_COUNTER_NUM == ETC_8
  TOS_CALL_COMMAND(TRANSCEIVER_TIMER1CLOCK_INIT)(etc8_tick1ps);
#endif
  TOS_CALL_COMMAND(TRANSCEIVER_POT_INIT)(50);
#ifdef USE_HOSTMOTE_SENS
  TOS_CALL_COMMAND(TRANSCEIVER_PHOTO_INIT)();
  TOS_CALL_COMMAND(TRANSCEIVER_TEMP_INIT)();
#endif

#ifdef USE_HOSTMOTE_SYNC
  cbi(DDRD, 3);       // set D3 as input
  cbi(DDRB, 7);       // set B7 as input
  sbi(MCUCR, ISC11);  // select trigger on falling edge
  cbi(MCUCR, ISC10);
  sbi(GIMSK, INT1);   // enable INT1
#endif
  
  transceiver_reset();
  return 1;
}


void conf_fillmsg(char sync)
{
  MUTEX(VAR(conf_to_host_busy), RESET_VAR,
  {
    // get timestamp
    if (!sync) TOS_CALL_COMMAND(TRANSCEIVER_TIMER1CLOCK_GET_TIME32)(&(VAR(conf).clock));
   
 
    // fill header
    HOSTMOTE_SET_OP(HOSTMOTE_CONF, sync ? CONF_SYNC : CONF_STAT, &VAR(conf_to_host));
    HOSTMOTE_SET_FRAME(&VAR(conf_to_host));
    HOSTMOTE_SET_DATALEN(sizeof(struct mote_conf), &VAR(conf_to_host));
    VAR(conf).tos_addr = TOS_LOCAL_ADDRESS;
    VAR(conf).tos_group = LOCAL_GROUP;
    VAR(conf).pot = TOS_CALL_COMMAND(TRANSCEIVER_POT_GET)();
    VAR(conf_send_needed) = 1;
  });
}


#ifdef USE_HOSTMOTE_SYNC
/* capture sync interrupt */
TOS_INTERRUPT_HANDLER(SIG_INTERRUPT1, (void)) 
{
  clock_get_time_32(&(VAR(conf).clock));
  
  flip_error_led();
  
  // if we're busy, do nothing
  if (VAR(conf_to_host_busy)) return;

  // update conf message and trigger output
  conf_fillmsg(1);
  TOS_POST_TASK(trysend);
}
#endif


char TOS_COMMAND(TRANSCEIVER_START)()
{
  return 1;
}


/***********************************************************************/


/*
 * trysend() tries to send some more stuff to the serial port.
 */

static inline
char sens_test()
{
#ifdef USE_HOSTMOTE_SENS
  if (VAR(sens_send_needed)) {
    MUTEX(VAR(sens_to_host_busy), RESET_VAR, 
    {
      HOSTMOTE_SET_OP(HOSTMOTE_SENS, SENS_DATA, &VAR(sens_to_host));
      HOSTMOTE_SET_FRAME(&VAR(sens_to_host));
      HOSTMOTE_SET_DATALEN(sizeof(struct mote_sens) + VAR(sens_count),
			   &VAR(sens_to_host));
      VAR(sens).clock = VAR(sens_clock);
      VAR(sens_clock_valid) = 0;
      if (TOS_COMMAND(TRANSCEIVER_SUB_UART_TX_PACKET)
	  (cast_hostmote_header(&VAR(sens_to_host)), 
	   sizeof(hostmote_header)+sizeof(struct mote_sens)+VAR(sens_count),
	   &VAR(sens_to_host_busy))) {
	VAR(sens_send_inprogress) = 1;
	VAR(sens_send_needed) = 0;
	return 1;
      }
    });
  }
#endif 
  return 0;
}

TOS_TASK(trysend)
{
  /* atomic change of uart state */
  MUTEX(VAR(uart_inuse), RESET_VAR, 
  {

    /* need to send data to host? */
    if (VAR(data_to_host_busy)) {
      if (TOS_COMMAND(TRANSCEIVER_SUB_UART_TX_PACKET)
	  (cast_hostmote_header(&VAR(data_to_host)), 
	   sizeof(hostmote_header) + sizeof(TOS_Msg),
	   &VAR(data_to_host_busy))) {
	VAR(data_to_host_inprogress) = 1;
	goto sending;
      }
    }

    /* need to send sync/conf response? */
    else if (VAR(conf_send_needed)) {
      MUTEX(VAR(conf_to_host_busy), RESET_VAR, 
      {
	if (TOS_COMMAND(TRANSCEIVER_SUB_UART_TX_PACKET)
	    (cast_hostmote_header(&VAR(conf_to_host)), 
	     sizeof(hostmote_header)+sizeof(struct mote_conf),
	     &VAR(conf_to_host_busy))) {
	  VAR(conf_send_needed) = 0;
	  goto sending;
	}
      });
    }

    /* need to send sensor data response? */
    else if (sens_test()) goto sending;
    
    /* send CHDN? */
    else if (VAR(rdhn_pending) &&           /* if pending */
	     !VAR(msg_to_radio_busy) &&     /* and radio is free */
	     !VAR(cdhn_to_host_busy)) {     /* and our buffer is free */
      VAR(cdhn_to_host_busy) = 1;
      HOSTMOTE_SET_FRAME(&VAR(cdhn_to_host));
      HOSTMOTE_SET_OP(HOSTMOTE_NIC, NIC_CDHN, &VAR(cdhn_to_host));
      HOSTMOTE_SET_DATALEN(0, &VAR(cdhn_to_host));
      if (TOS_COMMAND(TRANSCEIVER_SUB_UART_TX_PACKET)
	  (cast_hostmote_header(&VAR(cdhn_to_host)), sizeof(hostmote_header),
	   &VAR(cdhn_to_host_busy))) {
	VAR(rdhn_pending) = 0;
	goto sending;
      }
      VAR(cdhn_to_host_busy) = 0;
    }
  
  });
  return;

 sending:
  return;
}


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

  printf("TRANSCEIVER received packet\n");

  /* run the RX LED */
  if (VAR(rx_led_state))
    SET_GREEN_LED_PIN();
  else
    CLR_GREEN_LED_PIN();
  VAR(rx_led_state) = !VAR(rx_led_state);

  if (VAR(data_to_host_busy)) {

    if (VAR(data_to_host_queued)) {
      printf("TRANSCEIVER_RX_PACKET: dropping packet received from radio");
      flip_error_led();
    }

    else {
      VAR(data_to_host_queued) = 1;
      memcpy(&(VAR(data_msg2)), data, sizeof(TOS_Msg));
    }
    goto done;
  }
  
  printf("TRANSCEIVER forwarding packet to UART\n");

  HOSTMOTE_SET_FRAME(&VAR(data_to_host));
  HOSTMOTE_SET_OP(HOSTMOTE_NIC, NIC_DNH, &VAR(data_to_host));
  HOSTMOTE_SET_DATALEN(sizeof(TOS_Msg), &VAR(data_to_host));
  memcpy(&(VAR(data_msg)), data, sizeof(TOS_Msg));

  // trigger output
  VAR(data_to_host_busy) = 1;
  TOS_POST_TASK(trysend);

 done:
  return data;
}



/*
 *  HOSTMOTE protocol handlers
 */

static inline void hostmote_nic(HostMote_MsgPtr data)
{
  switch (HOSTMOTE_SUBOP(&(data->header))) {
    
  case NIC_DHN:
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
    
  case NIC_RDHN:
    VAR(rdhn_pending) = 1;
    TOS_POST_TASK(trysend);
    break;
  }  
}


static inline void hostmote_conf(HostMote_MsgPtr data)
{
  struct mote_conf *mc = (struct mote_conf *)data->data;

  switch (HOSTMOTE_SUBOP(&(data->header))) {
    
  case CONF_CONF:
    // set configuration parameters
    if (mc->set_flags & CONF_SET_ADDR)
      TOS_LOCAL_ADDRESS = mc->tos_addr;
    if (mc->set_flags & CONF_SET_GROUP)
      LOCAL_GROUP = mc->tos_group;
    if (mc->set_flags & CONF_SET_CLOCK)
      TOS_CALL_COMMAND(TRANSCEIVER_TIMER1CLOCK_SET_TIME64)(mc->clock);
    if (mc->set_flags & CONF_SET_POT)
      TOS_CALL_COMMAND(TRANSCEIVER_POT_SET)(mc->pot);

    /* fall through to send reply... */

  case CONF_STAT:
 
    // update conf message
    conf_fillmsg(0);
    
    // indicate ready to go and trigger output
    VAR(conf_send_needed) = 1;
    TOS_POST_TASK(trysend);
    break;
  }
}
  
  
#ifdef USE_HOSTMOTE_SENS
static inline void hostmote_sens_(HostMote_MsgPtr data)
{
  struct mote_sens *ms = (struct mote_sens *)data->data;

  switch (HOSTMOTE_SUBOP(&(data->header))) {
    
  case SENS_CONF:

    // need to change rate?
    if (VAR(sens).delta != ms->delta) {
      if (ms->delta == 0) {
#if CLOCK_COUNTER_NUM==ITC_16
	TOS_CALL_COMMAND(TRANSCEIVER_TIMER1CLOCK_CONFIG)(itc16_tick1ps);
#elif CLOCK_COUNTER_NUM==ETC_8
	TOS_CALL_COMMAND(TRANSCEIVER_TIMER1CLOCK_CONFIG)(etc8_tick1ps);
#endif
	ms->type = 0;
      }
      else 
	TOS_CALL_COMMAND(TRANSCEIVER_TIMER1CLOCK_CONFIG)(ms->delta >> 8, ms->delta & 0xFF);
    }

    // set sensor params
    VAR(sens) = *ms;
    
    // clear sensor buffer
    VAR(sens_count) = 0;
    VAR(sens_clock_valid) = 0;

    // init report level
    if (VAR(sens).report == 0)
      VAR(sens).report = 16;

    /* fall through to send reply... */
    
  case SENS_REPORT:
    
    // indicate ready to go and trigger output
    VAR(sens_send_needed) = 1;
    TOS_POST_TASK(trysend);
    break;
  }
}
#endif  
  

/*
 * This is called when a complete host-mote packet has arrived from
 * the UART.. dispatches to different handlers
 */

void TOS_EVENT(TRANSCEIVER_UART_RX_PACKET)(HostMote_MsgPtr data)
{
  switch(HOSTMOTE_OPNUM(&(data->header))) {
  case HOSTMOTE_NOOP:
    break;

  case HOSTMOTE_RST:
    transceiver_reset();
    break;
    
  case HOSTMOTE_SLEEP: {

    cli();

    // turn off radio
    MAKE_RFM_TXD_OUTPUT();
    MAKE_RFM_CTL0_OUTPUT();
    MAKE_RFM_CTL1_OUTPUT();
    CLR_RFM_TXD_PIN();
    CLR_RFM_CTL0_PIN();
    CLR_RFM_CTL1_PIN();

#ifdef USE_HOSTMOTE_SYNC
    // select interrupt 1 trigger on level 
    cbi(MCUCR, ISC11);
    cbi(MCUCR, ISC10);
#endif
    
    // turn off LEDs
    SET_YELLOW_LED_PIN();
    SET_RED_LED_PIN();
    SET_GREEN_LED_PIN();
    
    // set sleep mode to POWER DOWN 
    sbi(MCUCR, SM1);
    cbi(MCUCR, SM0);
    sbi(MCUCR, SE); 

    // reenable interrupts
    sei();

    asm volatile ("sleep" ::);
    asm volatile ("nop" ::);
    asm volatile ("nop" ::);

    cli();

    // restore sleep mode to IDLE
    cbi(MCUCR, SM1);

#ifdef USE_HOSTMOTE_SYNC
    // select trigger on falling edge
    sbi(MCUCR, ISC11);  
    cbi(MCUCR, ISC10);
#endif

    sei();

    // reinit transceiver
    transceiver_reset();

    break;
  }
    
  case HOSTMOTE_NIC:
    hostmote_nic(data);
    break;

  case HOSTMOTE_CONF:
    hostmote_conf(data);
    break;
    
#ifdef USE_HOSTMOTE_SENS
  case HOSTMOTE_SENS:
    hostmote_sens_(data);
    break;
#endif
    
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

  /* try to send something else */
  TOS_POST_TASK(trysend);
  return 1;
}

/*
 * Signal telling us the UART is now available to send something
 */
char TOS_EVENT(TRANSCEIVER_SUB_UART_TX_PACKET_DONE)(TOS_MsgPtr data)
{
#ifdef USE_HOSTMOTE_SENS
  // check for sensor data done
  if (VAR(sens_send_inprogress)) {
    uint8_t i;
    uint8_t datalen = 
      HOSTMOTE_DATALEN(&(VAR(sens_to_host))) -
      sizeof(struct mote_sens);
    VAR(sens_send_inprogress) = 0;
    if (datalen > 0) {
      cli();
      VAR(sens_count) -= datalen;
      for (i=0; i<VAR(sens_count); i++)
	VAR(sensor_readings)[i] = VAR(sensor_readings)[i+datalen];
      sei();
    }
  }
#endif

  // check for queued data
  if (VAR(data_to_host_inprogress) &&
      VAR(data_to_host_queued)) {
    VAR(data_to_host_queued) = 0;
    VAR(data_to_host_inprogress) = 0;
    VAR(data_to_host_busy) = 1;
    memcpy(&(VAR(data_msg)), &(VAR(data_msg2)), sizeof(TOS_Msg));
  }

  // when we are done with the UART, mark it as free  
  VAR(uart_inuse) = 0;
  
  // retrigger output
  TOS_POST_TASK(trysend);
  return 1;
}


/*
 * clock event does sampling, etc
 */

void TOS_EVENT(TRANSCEIVER_TIMER1CLOCK_EVENT)()
{
#ifdef USE_HOSTMOTE_SENS
  if (VAR(sens).type == SENS_LIGHT) 
    TOS_CALL_COMMAND(TRANSCEIVER_PHOTO_GET_DATA)(); /* start data reading */
  else if(VAR(sens).type == SENS_TEMP)
    TOS_CALL_COMMAND(TRANSCEIVER_TEMP_GET_DATA)(); /* start data reading */
#endif

  if (VAR(magic) == MAGIC) flip_error_led();
  return;
}


char TOS_EVENT(TRANSCEIVER_PHOTO_DATA_EVENT)(short data)
{
#ifdef USE_HOSTMOTE_SENS
  // store clock if needed
  if (VAR(sens_clock_valid) == 0) {
    VAR(sens_clock_valid) = 1;
    TOS_CALL_COMMAND(TRANSCEIVER_TIMER1CLOCK_GET_TIME32)(&(VAR(sens_clock)));
  }
  
  VAR(sensor_readings)[VAR(sens_count)] = data >> 2;
  VAR(sens_count)++;
  if (VAR(sens_count) >= VAR(sens).report) {
    VAR(sens_send_needed) = 1;
    TOS_POST_TASK(trysend);
  }
#endif

  return 1;
}


char TOS_EVENT(TRANSCEIVER_TEMP_DATA_EVENT)(short data)
{
#ifdef USE_HOSTMOTE_SENS
  // store clock if needed
  if (VAR(sens_clock_valid) == 0) {
    VAR(sens_clock_valid) = 1;
    TOS_CALL_COMMAND(TRANSCEIVER_TIMER1CLOCK_GET_TIME32)(&(VAR(sens_clock)));
  }
  
  VAR(sensor_readings)[VAR(sens_count)] = data >> 2;
  VAR(sens_count)++;
  if (VAR(sens_count) >= VAR(sens).report) {
    VAR(sens_send_needed) = 1;
    TOS_POST_TASK(trysend);
  }
#endif

  return 1;
}
