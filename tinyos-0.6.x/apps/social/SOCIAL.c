/*
 * social.c - a people-tracking application
 *   two functions: 
 *     broadcast a regular "I'm here" message with the motes unique id
 *     keep track of how often other motes are heard
 *       (used to build a social network graph)
 *
 * Authors: David Gay
 * History: created 12/20/01
 */

#include "tos.h"
#include "dbg.h"
#include "SOCIAL.h"

#define DBG(act) TOS_CALL_COMMAND(SOCIAL_LEDS)(led_ ## act)

typedef unsigned char bool;
#define FALSE 0
#define TRUE 1

typedef unsigned char u8;
typedef signed char i8;
typedef unsigned short u16;
typedef short i16;
typedef unsigned long u32;
typedef long i32;

static void memcpy(void *to, void *from, unsigned int n)
{
  char *cto = to, *cfrom = from;

  while (n--) *cto++ = *cfrom++;
}

static void memset(void *to, u8 val, unsigned int n)
{
  char *cto = to;

  while (n--) *cto++ = val;
}

/* Power increase for social info messages */
#define SSI_POT_STEP 10

#define IDENT_TIMER_PORT 0
#define SOCIAL_TIMER_PORT 1

#define CHECKPOINT_INTERVAL 300
#define MIN_SEND_INTERVAL 300
#define SEND_TIMEOUT 5 /* Minimum interval before resending social info */

#define SOCIAL_EEPROM_BASE 128

#define MAX_PEOPLE 64

struct social_info {
  u8 counts[MAX_PEOPLE * 3];
};

struct eeprom_state {
  u16 local_id;
  struct social_info current_info, sent_info;
  u32 time_info_starts, time_sent_info_ends;
};

struct identity {
  u16 mote_id;
  u16 local_id;
  u32 time_info_starts;
};

struct ident_msg {
  u16 seqno;
  u16 broadcast_period;
  struct identity id;
};

struct req_data_msg {
  u32 current_time; /* At the base */
  u32 last_data_time;
};

struct multi_packet_header {
  u16 mote_id;
  u8 seqno;
  u8 messageno;
};

struct social_packet_header {
  u8 protocol;
  u8 unused1; /* So that social data uses the whole message (otherwise we
		 would have a 1-byte gap at the end of the first message) */
  u32 time_info_starts __attribute__((packed));
  u32 time_info_ends __attribute__((packed));
};

//Frame Declaration
#define TOS_FRAME_TYPE SOCIAL_frame
TOS_FRAME_BEGIN(SOCIAL_frame) {
  bool ready : 1;
  bool sending : 1;
  bool checkpointing : 1;
  struct eeprom_state info;
  u32 current_time;
  u32 last_checkpoint_time;

  TOS_Msg msg1;
  u8 social_seqno, social_packet_id;
  u32 send_timeout_end;
}
TOS_FRAME_END(SOCIAL_frame);

static void clear_social_info(struct social_info *s);
static void update_social_info(u8 id, u16 period);
static void send_social_info(void);

char TOS_COMMAND(INIT)(void)
{
  VAR(ready) = VAR(sending) = VAR(checkpointing) = FALSE;
  VAR(current_time) = VAR(last_checkpoint_time) = 0;

  TOS_CALL_COMMAND(IDENT_INIT)(IDENT_TIMER_PORT);
  TOS_CALL_COMMAND(DEBUG_INIT)();
  TOS_CALL_COMMAND(REGISTER_INIT)();
  TOS_CALL_COMMAND(CHECKPOINT_INIT)(SOCIAL_EEPROM_BASE,
				    sizeof(VAR(info)), 1);

  return 1;
}

static void update_identity(void)
{
  struct identity id;

  id.mote_id = TOS_LOCAL_ADDRESS;
  id.local_id = VAR(info).local_id;
  id.time_info_starts = VAR(info).time_info_starts;
  TOS_CALL_COMMAND(IDENT_SET_ID)((u8 *)&id, sizeof(id));
}

void start_app(void)
{
  VAR(ready) = TRUE;
  TOS_CALL_COMMAND(TIMER_REGISTER)(SOCIAL_TIMER_PORT, 8);
  if (VAR(info).local_id)
    TOS_CALL_COMMAND(REGISTER_SET_ID)(VAR(info).local_id);
  else
    TOS_CALL_COMMAND(REGISTER_CLEAR_ID)();
  TOS_CALL_COMMAND(IDENT_START)();
  update_identity();
}

static void checkpoint_end(void)
{
  VAR(checkpointing) = FALSE;
  //DBG(r_off);
  if (VAR(sending))
    {
      update_identity();
      send_social_info();
    }
  else if (!VAR(ready))
    start_app();
  else
    update_identity();
}

static void checkpoint(void)
{
  if (!VAR(checkpointing))
    {
      //DBG(r_on);
      VAR(checkpointing) = TRUE;
      if (!TOS_CALL_COMMAND(CHECKPOINT_WRITE)(0, (u8 *)&VAR(info)))
	{
	  //DBG(y_on);
	  checkpoint_end();
	}
    }
}

void TOS_EVENT(CHECKPOINT_WRITE_DONE)(bool success, u8 *data)
{
  if (success)
    0;//DBG(y_on);
  checkpoint_end();
}

static void clear_state(int newid)
{
  struct eeprom_state *s = &VAR(info);

  s->local_id = newid;
  clear_social_info(&s->current_info);
  clear_social_info(&s->sent_info);
  s->time_info_starts = s->time_sent_info_ends = 0;

  /* There's a potential vulnerability here (if we die before saving,
     we won't get the "cleared" indication from the checkpointer
     next time). To fix, need to change CHECKPOINT to keep a per-data-set
     validity bit (or else, perform our own validation of checkpoint entries,
     but that seems silly (CHECKPOINT can easily do it)) */
  checkpoint();
}

static void load_state(void)
{
  TOS_CALL_COMMAND(CHECKPOINT_READ)(0, (u8 *)&VAR(info));
}

void TOS_EVENT(CHECKPOINT_READ_DONE)(bool success, u8 *data)
{
  if (success)
    start_app();
  else
    clear_state(0);
}

void TOS_EVENT(CHECKPOINT_INITIALISED)(unsigned char cleared)
{
  if (cleared)
    {
      DBG(r_on);
      clear_state(0);
    }
  else
    {
      DBG(g_on);
      load_state();
    }
}

char TOS_COMMAND(START)(void)
{
  return 1;
}

char TOS_EVENT(REGISTERED)(u16 newid)
{
  if (VAR(ready) && !VAR(checkpointing))
    {
      /* Host has given us a new identity. Forget old state */
      VAR(ready) = FALSE;
      clear_state(newid);
      return 1;
    }
  else
    /* Kill registration as we cannot accept it */
    return 0;
}

void TOS_EVENT(SOCIAL_TIMER_EVENT)(short port)
{
  VAR(current_time)++;
  if (VAR(current_time) > VAR(last_checkpoint_time) + CHECKPOINT_INTERVAL)
    {
      VAR(last_checkpoint_time) = VAR(current_time);
      if (!VAR(sending))
	checkpoint();
    }

  if (VAR(sending) && VAR(current_time) >= VAR(send_timeout_end))
    VAR(sending) = FALSE;
}

/* Respond to messages */

/* From another social mote */
TOS_MsgPtr TOS_MSG_EVENT(SEND_ID2)(TOS_MsgPtr msg)
{
  struct ident_msg *sender = (struct ident_msg *)msg->data;

  if (VAR(ready) && !VAR(checkpointing) && sender->id.local_id)
    update_social_info(sender->id.local_id, sender->broadcast_period);
  return msg;
}

TOS_MsgPtr TOS_MSG_EVENT(SEND_SOCIAL_INFO)(TOS_MsgPtr msg)
{
  /* Ignore these, they are for the base station */
  return msg;
}

/* 30 bytes avail per packet, 4 byte header on all packets and a
   social_packet_header on the first packet */
#define FIRST_PACKET_PEOPLE ((30 - sizeof(struct multi_packet_header) - sizeof(struct social_packet_header)) / 2)
#define PEOPLE_PER_PACKET ((30 - sizeof(struct multi_packet_header)) / 2)
#define NPACKETS \
    (MAX_PEOPLE <= FIRST_PACKET_PEOPLE ? 1 : \
    1 + (MAX_PEOPLE - FIRST_PACKET_PEOPLE + PEOPLE_PER_PACKET - 1) / PEOPLE_PER_PACKET)

static u32 get_social_count_fp(struct social_info *s, u8 id)
{
  return ((u32)s->counts[id * 3 + 2] << 16) +
    ((u16)s->counts[id * 3 + 1] << 8) + s->counts[id * 3];
}

static void copy_social_count(struct social_info *s, u8 id, u8 *to)
{
  /* Implicit round to zero, little-endian order, skip low order 8 bits */
  to[0] = s->counts[id * 3 + 1];
  to[1] = s->counts[id * 3 + 2];
}

static void set_social_count_fp(struct social_info *s, u8 id, u32 count)
{
  s->counts[id * 3] = count & 0xff;
  count >>= 8;
  s->counts[id * 3 + 1] = count & 0xff;
  count >>= 8;
  s->counts[id * 3 + 2] = count;
}

static void clear_social_info(struct social_info *s)
{
  memset(s, 0, sizeof(*s));
}

static void clear_sent_social_data(void)
{
  struct social_info *c = &VAR(info).current_info;
  struct social_info *l = &VAR(info).sent_info;
  u8 i;

  for (i = 0; i < MAX_PEOPLE; i++)
    set_social_count_fp(c, i, get_social_count_fp(c, i) - get_social_count_fp(l, i));
  clear_social_info(l); /* Don't subtract l twice ! */
}

static void update_social_info(u8 id, u16 period)
{
  struct social_info *s = &VAR(info).current_info;
  set_social_count_fp(s, id, get_social_count_fp(s, id) + period);
}

static void send_social_info(void)
{
  u8 packet_id = VAR(social_packet_id);
  TOS_MsgPtr m = &VAR(msg1);
  u8 mote_id, mote_base_id;
  u8 *base;
  struct social_info *s = &VAR(info).sent_info;
  struct multi_packet_header *mhdr = (struct multi_packet_header *)m->data;
  u8 npeople;

  DBG(g_toggle);
  mhdr->mote_id = TOS_LOCAL_ADDRESS;
  mhdr->seqno = VAR(social_seqno);
  mhdr->messageno = packet_id;
  if (packet_id == 0)
    {
      struct social_packet_header *shdr = (struct social_packet_header *)(m->data + sizeof(struct multi_packet_header));
      u8 i;

      base = (u8 *)shdr + sizeof(struct social_packet_header);
      shdr->protocol = 100;
      shdr->time_info_starts = VAR(info).time_info_starts;
      shdr->time_info_ends = VAR(info).time_sent_info_ends;
      npeople = FIRST_PACKET_PEOPLE;
      mote_base_id = 0;
      for (i = 0; i < SSI_POT_STEP; i++)
	TOS_CALL_COMMAND(SUB_POT_DEC)();
    }
  else
    {
      base = m->data + sizeof(struct multi_packet_header);
      npeople = PEOPLE_PER_PACKET;
      mote_base_id = FIRST_PACKET_PEOPLE + (packet_id - 1) * PEOPLE_PER_PACKET;
    }

  if (mote_base_id + npeople > MAX_PEOPLE)
      npeople = MAX_PEOPLE - mote_base_id;

  for (mote_id = 0; mote_id < npeople; mote_id++)
    copy_social_count(s, mote_base_id + mote_id, base + 2 * mote_id);

  TOS_CALL_COMMAND(SEND_MSG)(TOS_BCAST_ADDR, AM_MSG(SEND_SOCIAL_INFO), &VAR(msg1));
}

TOS_TASK(SEND_NEXT)
{
  send_social_info();
}


char TOS_EVENT(MSG_SEND_DONE)(TOS_MsgPtr sentBuffer)
{
  if (sentBuffer == &VAR(msg1)) 
    {
      VAR(social_packet_id)++;
      if (VAR(social_packet_id) < NPACKETS)
	//send_social_info();
	TOS_POST_TASK(SEND_NEXT);
      else
	{
	  u8 i;

	  /* start timeout */
	  VAR(send_timeout_end) = VAR(current_time) + SEND_TIMEOUT;

	  /* Decrease xmission power */
	  for (i = 0; i < SSI_POT_STEP; i++)
	    TOS_CALL_COMMAND(SUB_POT_INC)();
	}

      return 1;
    }
  return 0;
}

static void start_social_data_send(void)
{
  memcpy(&VAR(info).sent_info,
	 &VAR(info).current_info, sizeof(struct social_info));
  VAR(info).time_sent_info_ends = VAR(current_time);
  VAR(sending) = TRUE;
  VAR(social_seqno)++;
  VAR(social_packet_id) = 0;
  VAR(send_timeout_end) = (u32)-1; /* Disable timeout */
  checkpoint();
}

/* From a base station */
TOS_MsgPtr TOS_MSG_EVENT(REQ_DATA)(TOS_MsgPtr msg)
{
  struct req_data_msg *rd = (struct req_data_msg *)msg->data;

  if (VAR(ready) && !VAR(checkpointing))
    {
      bool info_change = FALSE;

      /* Resync clock (it drifts quite fast, so we can't just sync
	 it once).
         This doesn't create problems as we don't timestamp our data,
         except for "time sent info ends", and that is only set just
         after the clock is synced. */
      u32 old_time = VAR(current_time), toffset;

      VAR(current_time) = rd->current_time;
      if (VAR(info).time_info_starts == 0 &&
	  VAR(info).time_sent_info_ends == 0)
	{
	  toffset = VAR(current_time) - old_time;
	  VAR(info).time_info_starts += toffset;
	  VAR(info).time_sent_info_ends += toffset;
	  info_change = TRUE;
	}

      /* Sanity checks (irrespective of comment above ;-))
	 These guarantee that
	   time_sent_info_ends < current_time 
	 and avoids disturbing time_sent_info_ends (which is used
	 in our protocol as an identifier)
      */
      if (VAR(current_time) <= VAR(info).time_sent_info_ends)
	VAR(current_time) = VAR(info).time_sent_info_ends + 1;

      /* Update other times */
      toffset = VAR(current_time) - old_time;
      VAR(last_checkpoint_time) += toffset;
      if (VAR(send_timeout_end) != (u32)-1)
	VAR(send_timeout_end) += toffset;


      if (rd->last_data_time == VAR(info).time_sent_info_ends)
	{
	  clear_sent_social_data();
	  VAR(info).time_info_starts =
	    VAR(info).time_sent_info_ends;
	  info_change = TRUE;
	}

      if (!VAR(sending))
	{
	  if (VAR(current_time) >= rd->last_data_time + MIN_SEND_INTERVAL)
	    start_social_data_send();
	  else if (info_change)
	    checkpoint();
	}
    }
  return msg;
}
