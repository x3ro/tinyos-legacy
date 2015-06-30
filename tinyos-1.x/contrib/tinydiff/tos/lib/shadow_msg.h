
/*
 *  shadow_msg.h
 *
 */


#ifndef __SHADOW_MSG_H__
#define __SHADOW_MSG_H__

#define SHADOW_INIT                '0'
#define SHADOW_SET_CLOCK           '1'
#define SHADOW_SET_LOC             '2'
#define SHADOW_SET_DIFF_THRESH     '5'
#define SHADOW_SET_EV_THRESH       '6'

#define SHADOW_OBS_RAW             '7'
#define SHADOW_OBS_EV              '8'
#define SHADOW_OBS_TRACK           '9'

// "tasks" or "modes"
#define MODE_OFFSET '0'
#define WAIT        0
#define SAMP_DIFF   1
#define SAMP_PKDET  2
#define SAMP_TRACK  3
#define TESTING     9


#endif
