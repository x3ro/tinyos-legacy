/*
 * ident.c - simple people identifier application
 *	     each mote has a (programmable) ID which it broadcasts
 *	     continuously
 *
 * Authors: David Gay
 * History: created 12/6/01
 *          adaptive rate extension 12/14/01
 */

#include "tos.h"
#include "dbg.h"
#include "IDENT.h"

typedef unsigned short fp_type;
typedef unsigned long fp_bigger;
#define FP_BITS 8 /* 8.8 fixed point values */
#include "FP.h"

#ifdef rene
#define INITIAL_POT 73
#define LOWBAT_POT 70
#define LOWBAT_THRESHOLD 0x1c0
#else
/* mica */
#define INITIAL_POT 81
#endif

#define IDENTITY_LEN 8

/* Period (in seconds) for identity broadcast */
#define MINIMUM_IDENTITY_PERIOD INT_TO_FP(10)
#define MAXIMUM_IDENTITY_PERIOD INT_TO_FP(60)

#define MSG_DECAY_RATE 248 /* 0.969 */

#define PERIOD_ADJUST_RATE 320 /* 1.25 */
#define FREQUENCRY_INCREASE 3 /* ~0.01Hz */

/* Maximum rate of id messages per second (an FP number) */
#define MAX_IDMSG_RATE INT_TO_FP(1)
#define MIN_IDMSG_RATE 128 /* 0.5 */

typedef unsigned char u8;
typedef unsigned short u16;

struct ident_msg {
  u16 seqno;
  fp_type broadcast_period;
  char identity[IDENTITY_LEN];
  fp_type msg_rate;
  u16 vcc;
  u8 pot;
  u8 pot2;
};

//Frame Declaration
#define TOS_FRAME_TYPE IDENT_frame
TOS_FRAME_BEGIN(IDENT_frame) {
  char pending1;
  TOS_Msg msg1;

  char timer_port;

  char identity[IDENTITY_LEN];
  char identity_length; /* == 0 for no identity */

  u8 seconds;
  u8 message_count; /* In the last second */
  fp_type scaled_msg_rate; 
  fp_type broadcast_period; 
  u16 seqno;
  u16 vcc;
  u8 pot;
}
TOS_FRAME_END(IDENT_frame);

#define FALSE 0
#define TRUE 1

#define DBG(act) TOS_CALL_COMMAND(IDENT_LEDS)(led_ ## act)

static void memcpy(void *to, void *from, unsigned int n)
{
  char *cto = to, *cfrom = from;

  while (n--) *cto++ = *cfrom++;
}

/* 3 messages:
   SEND_ID: Sent by mote. Reports a mote's 
   SET_ID: Sent by PC. Any mote that receives it, that doesn't have an id, sets
                       its id to the message contents 
   CLEAR_ID: Sent by PC. Any mote that receives it loses its identity
*/

static void clear_identity(void)
{
  TOS_CALL_COMMAND(SUB_STOP_TIMER)(VAR(timer_port)); 
  VAR(identity_length) = 0;
  //DBG(r_on);
  //DBG(g_off);
}

static void set_identity(char *newid, int length)
{
  memcpy(VAR(identity), newid, length);
  VAR(identity_length) = length;

  /* We reset these variables because we stop keeping track of
     message rates while we have no id */
  VAR(seconds) = 0;
  VAR(message_count) = 0;
  TOS_CALL_COMMAND(SUB_START_TIMER)(VAR(timer_port), 8); 
  //DBG(r_off);
  //DBG(g_on);
}

static void set_pot(u8 newval)
{
  u8 i;

  /* Do this rather than absolute set as some other components may
     be doing temporary power increases for their own messages */
  if (newval > VAR(pot))
    for (i = VAR(pot); i < newval; i++)
      TOS_CALL_COMMAND(SUB_POT_INC)();
  else if (newval < VAR(pot))
    for (i = newval; i < VAR(pot); i++)
      TOS_CALL_COMMAND(SUB_POT_DEC)();

  VAR(pot) = newval;
}

char TOS_COMMAND(IDENT_INIT)(short port)
{
  VAR(pot) = INITIAL_POT;
#ifndef TOSSIM
  TOS_CALL_COMMAND(SUB_POT_SET)(VAR(pot));
#endif
  TOS_CALL_COMMAND(IDENT_SUB_INIT)();

  VAR(timer_port) = port;
  VAR(seqno) = 0;
  VAR(vcc) = 0xffff;

  DBG(y_off);
  clear_identity();
  
  return 1;
}

/* START: 
*/
char TOS_COMMAND(IDENT_START)(void)
{
  VAR(pending1) = FALSE;
  VAR(broadcast_period) = MINIMUM_IDENTITY_PERIOD;
  VAR(scaled_msg_rate) = FPDIV(FPDIV(INT_TO_FP(1), MINIMUM_IDENTITY_PERIOD),
			       INT_TO_FP(1) - MSG_DECAY_RATE);
  //DBG(r_on);
  return 1;
}

char TOS_COMMAND(CLEAR_ID)(void)
{
  clear_identity();
  return 1;
}

char TOS_COMMAND(SET_ID)(unsigned char *id, short len)
{
  if (len <= 0 || len > IDENTITY_LEN)
    return 0;

  set_identity(id, len);
  return 1;
}

TOS_MsgPtr TOS_MSG_EVENT(SEND_ID)(TOS_MsgPtr msg)
{
  DBG(y_toggle);
  VAR(message_count)++;
  return msg;
}

/* All this stuff should worry about overflow */
static void update_msg_rate(void)
{
  VAR(scaled_msg_rate) = FPMUL(VAR(scaled_msg_rate), MSG_DECAY_RATE) +
    INT_TO_FP(VAR(message_count));
  VAR(message_count) = 0;
}

static void adapt_broadcast_period(void)
{
  fp_type newperiod = VAR(broadcast_period);
  fp_type msg_rate = FPMUL(VAR(scaled_msg_rate), INT_TO_FP(1) - MSG_DECAY_RATE);

  if (msg_rate > MAX_IDMSG_RATE) /* Increase broadcast period */
    {
      //DBG(g_toggle);
      newperiod = FPMUL(newperiod, PERIOD_ADJUST_RATE);
    }
  else if (msg_rate < MIN_IDMSG_RATE)
    {
      // increase frequency additively
      newperiod = FPDIV(newperiod, INT_TO_FP(1) + FPMUL(FREQUENCRY_INCREASE, newperiod));
      //DBG(r_toggle);
    }


  if (newperiod < MINIMUM_IDENTITY_PERIOD)
    VAR(broadcast_period) = MINIMUM_IDENTITY_PERIOD;
  else if (newperiod > MAXIMUM_IDENTITY_PERIOD)
    VAR(broadcast_period) = MAXIMUM_IDENTITY_PERIOD;
  else
    VAR(broadcast_period) = newperiod;


}

/* Clock Event Handler:
   Broadcast identity
 */
void TOS_EVENT(TIMER_EVENT)(short port)
{
  update_msg_rate();

  if (INT_TO_FP(++VAR(seconds)) < VAR(broadcast_period))
    return;

  adapt_broadcast_period();

  VAR(seconds) = 0;

  if (VAR(identity_length) && !VAR(pending1))
    {
      struct ident_msg *m = (struct ident_msg *)VAR(msg1).data;

      m->seqno = VAR(seqno)++;
      m->broadcast_period = VAR(broadcast_period);
      memcpy(m->identity, VAR(identity), VAR(identity_length));
      m->msg_rate = VAR(scaled_msg_rate);
      m->vcc = VAR(vcc);
      m->pot = VAR(pot);
      m->pot2 = TOS_CALL_COMMAND(SUB_POT_GET)();

      if (TOS_COMMAND(SUB_SEND_MSG)(TOS_BCAST_ADDR, 21/*AM_MSG(SEND_ID)*/, &VAR(msg1)))
	{
	  VAR(message_count)++; /* This message counts too! */
	  DBG(g_toggle);
	  VAR(pending1) = TRUE;
	}
    }
}

#ifdef rene
char TOS_EVENT(VCC_READY)(short data)
{
  VAR(vcc) = data;

  /* Simplistic power increase hack */
  if (VAR(pot) != LOWBAT_POT && data >= LOWBAT_THRESHOLD)
      set_pot(LOWBAT_POT);

  return 1;
}
#endif

char TOS_EVENT(SUB_MSG_SEND_DONE)(TOS_MsgPtr sentBuffer)
{
  if (VAR(pending1) && sentBuffer == &VAR(msg1)) 
    {
      VAR(pending1) = FALSE;
#ifdef rene
      TOS_CALL_COMMAND(VCC_GET)(30);
#endif
      return 1;
    }
  return 0;
}
