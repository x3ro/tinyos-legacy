

/*
 *  msg_types.h
 *
 *  a place where we can define message types!!!
 *
 */

#ifndef __MSG_TYPES_H__
#define __MSG_TYPES_H__

// base types (to be used in TOS type field)
#define MSG_SYNC_OBS         	0x3
#define MSG_SET_FUNCTION     	0x4
#define MSG_CHIRP_REQUEST    	0x5
#define MSG_CHIRP_REPLY      	0x6
#define MSG_SHADOW           	0x7
#define MSG_SET_FUNC	     	0x8
#define MSG_SET_FUNC_REPLY   	0x9
#define MSG_REPLY	   	0xa
#define MSG_CONFIG_AUDIO     	0xb
#define MSG_CONFIG_AUDIO_REPLY 	0xc
#define MSG_STORE_LOC        	0xd
#define MSG_EVENT_OBSERV    	0xe
#define MSG_RAW_DATA		0xf
#define MSG_FRAG_LAYER    	0x19


// sub types for use with MSG_SET_FUNC
#define FUNC_RESET		'r'
#define FUNC_WAIT		'0'
#define FUNC_SAMP_THRESH  	'1'
#define FUNC_SAMP_DIFF		'2'
#define FUNC_SAMP_PEAK		'3'
#define FUNC_SAMP_COLAB		'4'
#define FUNC_SAMP_TRACK		'5'
#define FUNC_SAMP_RAW		'6'
#define FUNC_TEST		't'

// sub types for use with MSG_CONFIG_AUDIO
#define SEL_SPKRS_MICS_OFF	'0'
#define SEL_SPKRS_ON		'1'
#define SEL_SPKR_0_ON		'2'
#define SEL_SPKR_1_ON		'3'
#define SEL_MIC_0_ON		'4'
#define SEL_MIC_1_ON		'5'



// msg types 51-150 are used as different data types for James Reserve apps
enum {
  JR_DATA_1		= 61,
  JR_DATA_2		= 62,
  MSG_NEIGHBOR_BEACON	= 63,
  MSG_NEIGHBOR_TEST	= 64,
  ESS_OPP_INTEREST	= 65,
  ESS_OPP_DATA		= 66,
  ESS_OPP_IBCAST	= 67
};

// msg types 151-160 are used as control types for James Reserve apps

#endif
