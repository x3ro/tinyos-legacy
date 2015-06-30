#ifndef __LOGGER___
#define __LOGGER___
#include "super.h"
//ACCEPTS
char TOS_COMMAND(APPEND_INIT)(void);
char TOS_COMMAND(APPEND_LOG)(char* data);
char TOS_COMMAND(LOGGER_INIT)(void);
char TOS_COMMAND(READ_LOG)(int line, char* dest);
char TOS_COMMAND(WRITE_LOG)(int line, char* data);
//HANDLES
char TOS_EVENT(LOGGER_I2C_READ_BYTE_DONE)(char data, char success);
char TOS_EVENT(LOGGER_I2C_SEND_END_DONE)(void);
char TOS_EVENT(LOGGER_I2C_SEND_START_DONE)(void);
char TOS_EVENT(LOGGER_I2C_WRITE_BYTE_DONE)(char success);
//SIGNALS
char TOS_EVENT(APPEND_LOG_DONE)(char success);
char TOS_EVENT(READ_LOG_DONE)(char* packet, char success);
//USES
char TOS_COMMAND(LOGGER_I2C_READ_BYTE)(char ack);
char TOS_COMMAND(LOGGER_I2C_SEND_END)(void);
char TOS_COMMAND(LOGGER_I2C_SEND_START)(void);
char TOS_COMMAND(LOGGER_I2C_WRITE_BYTE)(char data);
char TOS_COMMAND(LOGGER_SUB_INIT)(void);
//INTERNAL
#endif //__LOGGER___//
