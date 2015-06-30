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
#include "IDENT.h"

typedef unsigned short fp_type;
typedef unsigned long fp_bigger;
#define FP_BITS 8 /* 8.8 fixed point values */
#include "FP.inc"

/* line of eeprom that holds identity.
   First byte is 0 for no identity, non-zero for identity set.
   Remaining 15 bytes are the null-terminated identity string */
#define IDENT_LINE 4 

/* Maximum name length */
#define IDENTITY_LEN 15

/* Period (in seconds) for identity broadcast */
#define MINIMUM_IDENTITY_PERIOD INT_TO_FP(2)
#define MAXIMUM_IDENTITY_PERIOD INT_TO_FP(20)

#define MSG_DECAY_RATE 253 /* 0.988 */

#define PERIOD_ADJUST_RATE 320 /* 1.25 */

/* Maximum rate of id messages per second (an FP number) */
#define MAX_IDMSG_RATE INT_TO_FP(1)
#define MIN_IDMSG_RATE FPDIV(MAX_IDMSG_RATE, FPMUL(PERIOD_ADJUST_RATE, 282))

//Frame Declaration
#define TOS_FRAME_TYPE IDENT_frame
TOS_FRAME_BEGIN(IDENT_frame) {
  char pending1;
  TOS_Msg msg1;
  char have_identity;
  char identity[IDENTITY_LEN];
  char eeprom_line[16];
  char eeprom_line_inuse;
  char save_id_pending;
  char seconds;
#if IDENTITY_LEN + 1 > 16
#error IDENTITY_LEN and other information must fit in 16 bytes
#endif

  unsigned char message_count; /* In the last second */
  fp_type scaled_msg_rate; 
  fp_type broadcast_period; 
}
TOS_FRAME_END(IDENT_frame);

#define FALSE 0
#define TRUE 1

#if 0
#define DBG(act) 0
#else
#define DBG(act) TOS_CALL_COMMAND(LED ## act)()
#endif

/* 3 messages:
   SEND_ID: Sent by mote. Reports a mote's 
   SET_ID: Sent by PC. Any mote that receives it, that doesn't have an id, sets
                       its id to the message contents 
   CLEAR_ID: Sent by PC. Any mote that receives it loses its identity
*/

static void memcpy(char *to, char *from, int n)
{
  while (n--) *to++ = *from++;
}

static void save_id(void)
{
  if (VAR(eeprom_line_inuse))
    {
      VAR(save_id_pending) = TRUE;
      return;
    }

  VAR(save_id_pending) = FALSE;
  VAR(eeprom_line_inuse) = TRUE;
  if (!VAR(have_identity))
    VAR(eeprom_line)[0] = FALSE;
  else
    {
      VAR(eeprom_line)[0] = TRUE;
      memcpy(VAR(eeprom_line) + 1, VAR(identity), IDENTITY_LEN);
    }
  TOS_CALL_COMMAND(WRITE_EEPROM)((short)IDENT_LINE, VAR(eeprom_line));
}

static void check_for_save_id(void)
{
  if (VAR(save_id_pending))
    save_id();
}

char TOS_EVENT(WRITE_EEPROM_DONE)(char success)
{
  VAR(eeprom_line_inuse) = FALSE;
  check_for_save_id();
  return 0;
}

static void clear_identity(void)
{
  VAR(have_identity) = FALSE;
  DBG(r_on);
  DBG(g_off);
}

static void set_identity(char *newid)
{
  VAR(have_identity) = TRUE;
  memcpy(VAR(identity), newid, IDENTITY_LEN);
  DBG(r_off);
  DBG(g_on);
}

static void read_id(void)
{
  /* At init only, so we get to steal the eeprom line */
  VAR(eeprom_line_inuse) = TRUE;
  if (TOS_CALL_COMMAND(READ_EEPROM)((short)IDENT_LINE, VAR(eeprom_line)))
    ;
}

char TOS_EVENT(READ_EEPROM_DONE)(char *packet, char success)
{
  if (success && packet == VAR(eeprom_line))
    {
      if (packet[0])
	set_identity(packet + 1);
      else
	clear_identity();
    }
  VAR(save_id_pending) = FALSE; /* We kill any id we received during startup */
  VAR(eeprom_line_inuse) = FALSE;
  
  return 0;
}

char TOS_COMMAND(INIT)(void)
{
  TOS_CALL_COMMAND(SUB_POT_SET)(73);
  TOS_CALL_COMMAND(SUB_INIT)();

  VAR(save_id_pending) = FALSE;
  VAR(eeprom_line_inuse) = FALSE;
  VAR(seconds) = 0;

  DBG(y_off);
  clear_identity();
  
  read_id();
  return 1;
}

/* START: 
*/
char TOS_COMMAND(START)(void)
{
  VAR(pending1) = FALSE;
  VAR(broadcast_period) = MINIMUM_IDENTITY_PERIOD;
  VAR(scaled_msg_rate) = FPDIV(FPDIV(INT_TO_FP(1), MINIMUM_IDENTITY_PERIOD),
			       INT_TO_FP(1) - MSG_DECAY_RATE);
  VAR(message_count) = 0;
  TOS_CALL_COMMAND(SUB_START_CLOCK)(tick1ps); 
  DBG(r_on);
  return 1;
}

TOS_MsgPtr TOS_MSG_EVENT(SEND_ID)(TOS_MsgPtr msg)
{
  DBG(r_toggle);
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
      DBG(g_toggle);
      newperiod = FPMUL(newperiod, PERIOD_ADJUST_RATE);
    }
  else if (msg_rate < MIN_IDMSG_RATE)
    {
      newperiod = FPMUL(newperiod, FPDIV(INT_TO_FP(1), PERIOD_ADJUST_RATE));
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
void TOS_EVENT(CLOCK_EVENT)(void)
{
  update_msg_rate();

  if (INT_TO_FP(++VAR(seconds)) < VAR(broadcast_period))
    return;

  adapt_broadcast_period();

  VAR(seconds) = 0;

  if (VAR(have_identity) && !VAR(pending1))
    {
      char *mdata = VAR(msg1).data;

      memcpy(mdata, VAR(identity), IDENTITY_LEN);

      *(fp_type *)(mdata + IDENTITY_LEN) = VAR(scaled_msg_rate);
      *(fp_type *)(mdata + IDENTITY_LEN + sizeof(fp_type)) = VAR(broadcast_period);
      *(fp_type *)(mdata + IDENTITY_LEN + 2 * sizeof(fp_type)) = 0x4224;
      if (TOS_COMMAND(SUB_SEND_MSG)(TOS_BCAST_ADDR, AM_MSG(SEND_ID), &VAR(msg1)))
	{
	  VAR(message_count)++; /* This message counts too! */
	  DBG(y_toggle);
	  VAR(pending1) = TRUE;
	}
    }
}

char TOS_EVENT(SUB_MSG_SEND_DONE)(TOS_MsgPtr sentBuffer)
{
  if (VAR(pending1) && sentBuffer == &VAR(msg1)) 
    {
      VAR(pending1) = FALSE;
      return 1;
    }
  return 0;
}

TOS_MsgPtr TOS_MSG_EVENT(CLEAR_ID)(TOS_MsgPtr msg)
{
  clear_identity();
  save_id();
  return msg;
}

TOS_MsgPtr TOS_MSG_EVENT(SET_ID)(TOS_MsgPtr msg)
{
  if (!(VAR(have_identity)))
    {
      set_identity(msg->data);
      save_id();
    }
  return msg;
}
