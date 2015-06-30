/*
 *
 * Systemic Realtime Design, LLC.
 * http://www.sysrtime.com
 *
 * Authors:  Qingwei Ma
 *           Michael Li
 *
 * Date last modified:  9/30/04
 *
 */



#ifndef SKYEREAD_MINI_H
#define SKYEREAD_MINI_H


#define CONVERT_TO_RAW_DATA(data) data-2
#define CONVERT_TO_RAW_SIZE(size) size+2

typedef struct TagCommand
{
  uint8_t flag[2];
  uint8_t request[2];
  uint8_t type[2];
  uint8_t TID[16];
  uint8_t start[2];
  uint8_t length[2];
  uint8_t data[8];
} TagCommand;


enum {
  MAX_CMD_SIZE = sizeof(TagCommand),   // maximum command length (writing 1 block at a time)
  MAX_RSP_SIZE = 20,                   /* maximum response length
                                          2 bytes for response code + 18 bytes for TID */
  MINI_SLEEP_TIMEOUT = 5000,  /* if no activity is detected on Mini within 5 seconds of last
                                 received reply, then it goes to sleep */
  MINI_SEARCH_TAG_TIMEOUT = 3,  // default is 3 seconds to find a tag when searchTag command is called
  MINI_RESPONSE_TIMEOUT = 3,    // 3 seconds to execute a command before timing out and failing command
  MINI_RESET_READY = 150,  // approximately 150 ms for Mini to be ready after a reset
  MINI_WAKEUP_READY = 100, // according to Skyetek Mini manual, it takes < 100 ms for Mini to wake up from sleep
};


typedef enum result {
  MINI_FAIL    = 0,
  MINI_SUCCESS = 1,
  MINI_TIMEOUT = 2 
} miniResult_t;


#endif
