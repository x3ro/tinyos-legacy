#ifndef __ACCEL_REC___
#define __ACCEL_REC___
#include "super.h"
//ACCEPTS
char TOS_COMMAND(ACCEL_REC_INIT)(void);
char TOS_COMMAND(ACCEL_REC_START)(void);
//HANDLES
void TOS_EVENT(ACCEL_REC_CLOCK_EVENT)(void);
char TOS_EVENT(ACCEL_REC_DATA_EVENT_2)(int data);
char TOS_EVENT(ACCEL_REC_DATA_EVENT_3)(int data);
char TOS_EVENT(ACCEL_REC_MSG_SEND_DONE)(TOS_MsgPtr msg);
char TOS_EVENT(ACCEL_REC_READ_LOG_DONE)(char* data, char success);
char TOS_EVENT(ACCEL_REC_WRITE_LOG_DONE)(char success);
TOS_MsgPtr TOS_EVENT(ACCEL_REC_msg)(TOS_MsgPtr data);
//SIGNALS
//USES
char TOS_COMMAND(ACCEL_REC_ADC_INIT)(void);
char TOS_COMMAND(ACCEL_REC_CLOCK_INIT)(char interval, char scale);
char TOS_COMMAND(ACCEL_REC_GET_DATA)(char port);
char TOS_COMMAND(ACCEL_REC_READ_LOG)(int line, char* data);
char TOS_COMMAND(ACCEL_REC_SEND_MSG)(short addr,char type, TOS_MsgPtr data);
char TOS_COMMAND(ACCEL_REC_SUB_INIT)();
char TOS_COMMAND(ACCEL_REC_SUB_PWR)(char pwr);
char TOS_COMMAND(ACCEL_REC_WRITE_LOG)(char* data);
char TOS_COMMAND(GREEN_LED_TOGGLE)(void);
char TOS_COMMAND(LOGGER_APPEND_INIT)();
char TOS_COMMAND(RED_LED_TOGGLE)(void);
char TOS_COMMAND(YELLOW_LED_TOGGLE)(void);
//INTERNAL
#endif //__ACCEL_REC___//
