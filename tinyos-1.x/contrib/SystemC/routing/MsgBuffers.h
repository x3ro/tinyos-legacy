
#ifndef _H_MsgBuffers_h
#define _H_MsgBuffers_h

enum
{
  MSGBUFFERS_NUM_BUFFERS = 4,
};

#define MsgBuffers_alloc() MsgBuffers.debug_alloc( unique("MsgBuffersDebug") )
#define MsgBuffers_alloc_for_swap(a) MsgBuffers.debug_alloc_for_swap( unique("MsgBuffersDebug"), a )

#endif//_H_MsgBuffers_h

