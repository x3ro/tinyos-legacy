/*
 * Copyright (c) 2006 Moteiv Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached MOTEIV-LICENSE     
 * file. If you do not find these files, copies can be found at
 * http://www.moteiv.com/MOTEIV-LICENSE.txt and by emailing info@moteiv.com.
 */

/*
 * SP type definitions
 *
 * @author Joe Polastre, Moteiv Corporation <info@moteiv.com>
 */
#ifndef __SP_H__
#define __SP_H__

#ifndef SP_SIZE_MESSAGE_POOL
#define SP_SIZE_MESSAGE_POOL 10
#endif

#ifndef SP_SIZE_ADAPTOR_POOL
#define SP_SIZE_ADAPTOR_POOL 1
#endif

#ifndef SP_SIZE_NEIGHBOR_TABLE
#define SP_SIZE_NEIGHBOR_TABLE 10
#endif

#ifndef SP_CONTROL_COUNT_RETRIES
#define SP_CONTROL_COUNT_RETRIES 3
#endif

typedef enum {
  SP_I_NOT_SPECIFIED      = 0,
  SP_I_RADIO = unique("SPInterface"),
  SP_I_UART = unique("SPInterface"),
} sp_interface_t;

typedef uint16_t sp_address_t;
typedef uint8_t sp_device_t;

typedef struct SPMessage {
  TOS_Msg* msg;
  uint32_t time;
  sp_address_t addr;
  sp_device_t dev;
  uint8_t id;           // service that initiated message
  uint8_t quantity;     // how many message futures?
  uint8_t flags;        // control and feedback flags
  uint8_t retries;      // number of times current message is retried
  uint8_t length;       // length of the enclosed message
} sp_message_t;

typedef struct SPNeighborTableEntry {
  uint16_t addr;
  uint32_t timeon;
  uint32_t timeoff;
  uint8_t id;           // sp neighbor table entries/buffers used by 'id' 
  uint8_t flags;        // is the entry in the table or not in it?
} sp_neighbor_t;

typedef enum {
  SP_RADIO_OFF = 0,
  SP_RADIO_ON,
  SP_RADIO_WAKEUP,
  SP_RADIO_SHUTDOWN,
} sp_linkstate_t;

typedef enum {
  // Control
  SP_FLAG_C_TIMESTAMP     = 0x001,  // add a timestamp to the message
  SP_FLAG_C_RELIABLE      = 0x002,  // try to send with reliability
  SP_FLAG_C_URGENT        = 0x004,  // send an urgent request
  SP_FLAG_C_NONE          = 0x000,
  SP_FLAG_C_ALL           = 0x007,
  // Feedback
  SP_FLAG_F_CONGESTION    = 0x010,  // congestion feedback is provided
  SP_FLAG_F_PHASE         = 0x020,  // phase feedback is provided
  SP_FLAG_F_RELIABLE      = 0x040,  // feedback of reliability if achieved
  SP_FLAG_F_NONE          = 0x000,
  SP_FLAG_F_ALL           = 0x070,

  // Internal
  SP_FLAG_C_BUSY          = 0x080,
  SP_FLAG_C_FUTURES       = 0x008,

  // of these flags, the following are currently implemented:
  // Control-  TIMESTAMP, RELIABLE
  // Feedback- RELIABLE
} sp_message_flags_t;

typedef enum {
  SP_FLAG_TABLE           = 0x01,
  SP_FLAG_BUSY            = 0x02,
  SP_FLAG_LISTEN          = 0x04,
  SP_FLAG_LINK_STARTED    = 0x08,
  SP_FLAG_LINK_ACTIVE     = 0x10,
} sp_neighbor_flags_t;

typedef enum {
  SP_SUCCESS              = 0,
  SP_E_UNKNOWN            = 0x01, // an unknown error occured
  SP_E_RELIABLE           = 0x02, // reliability was not achieved
  SP_E_BUF_UNDERRUN       = 0x03, // the send buffer is empty
  SP_E_SHUTDOWN           = 0x04, // the link shut down before completion
} sp_error_t;

#endif
