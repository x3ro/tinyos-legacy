
/*
 * Sync Event Observation Packet Formats
 *
 * author: girod
 *
 * $Id: sync_obs_msg.h,v 1.1.1.2 2004/03/06 03:01:07 mturon Exp $
 */

#ifndef __SYNC_OBS_MSG_H__
#define __SYNC_OBS_MSG_H__

/* packet type */
#define SYNC_OBS_MESSAGE_TYPE   3

/* flags */
#define OBS_INUSE          1
#define OBS_USEFORSYNC  0x10

/* observation struct */
struct obs {
  uint32_t stamp;
  uint16_t seqno;
  uint8_t source;
  uint8_t flags;
};


struct obs_msg {
  uint8_t our_addr;
  uint8_t count;
  uint16_t seqno;
  struct obs obs[0];
};


#endif
