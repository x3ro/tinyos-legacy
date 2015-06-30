/*
 * ndebug.c - component with same interface as DEBUG, but where the
 *            debug actions are noops
 *
 * Authors: David Gay
 * History: created 12/21/01
 */

#include "tos.h"
#include "NDEBUG.h"


//Frame Declaration
#define TOS_FRAME_TYPE NDEBUG_frame
TOS_FRAME_BEGIN(NDEBUG_frame) {
}
TOS_FRAME_END(NDEBUG_frame);

void TOS_COMMAND(NLEDS)(unsigned char act)
{
}
