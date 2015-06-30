/*
 * register.c - respond to registration messages
 *
 * Authors: David Gay
 * History: created 12/19/01
 */

#include "tos.h"
#include "IDENT.h"

typedef unsigned short id_type;
#define NOID 0

#define TOS_FRAME_TYPE REGISTER_frame
TOS_FRAME_BEGIN(REGISTER_frame) {
  id_type id;
}
TOS_FRAME_END(REGISTER_frame);

char TOS_COMMAND(REGISTER_INIT)(void)
{
  VAR(id) = NOID;
  return 1;
}

char TOS_COMMAND(REGISTER_SET_ID)(id_type newid)
{
  if (newid == NOID)
    return 0;

  VAR(id) = newid;
  return 1;
}

char TOS_COMMAND(REGISTER_CLEAR_ID)(void)
{
  VAR(id) = NOID;
  return 1;
}

unsigned short TOS_COMMAND(REGISTER_GET_ID)(void)
{
  return VAR(id);
}

char TOS_EVENT(REGISTERED)(unsigned short id);

TOS_MsgPtr TOS_MSG_EVENT(REGISTER_MSG)(TOS_MsgPtr msg)
{
  id_type newid = *(id_type *)msg->data;

  if (VAR(id) != newid)
    {
      /* event handler can refuse registration */
      if (TOS_SIGNAL_EVENT(REGISTERED)(newid))
	  VAR(id) = newid;
      else
	; /* some error handling */
    }
  return msg;
}
