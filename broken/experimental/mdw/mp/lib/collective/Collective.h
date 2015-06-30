/* Copyright (c) 2002 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704. Attention: Intel License Inquiry.  
 * 
 * Author: Matt Welsh <mdw@eecs.harvard.edu>
 */

/* The set of supported operators for a reduce operation. */
typedef enum {
  OP_NOP,
  OP_ADD,
  OP_PROD,
  OP_MIN,
  OP_MAX,
} operator_t;

/* The type of buffers operated on by reductions. Yay for monomorphism. */
typedef enum {
  TYPE_UINT16,
  TYPE_FLOAT,
} type_t;

enum {
  AM_REDUCEMSG = 83,
  AM_COMMANDMSG = 84,
  /* Time to wait for a spanning tree to get created. */
  SPANTREE_TIMEOUT = 10000,
  REDUCE_MAX_BUFLEN = 8,
  /* Assumed maximum depth of spanning tree for reductions */
  REDUCE_MAX_LEVELS = 10,
  /* Per-level delay before reducing/transmitting */
  REDUCE_XMIT_DELAY = 100,
  COMMAND_MAX_BUFLEN = 8,
}; 

typedef struct ReduceMsg {
  uint16_t sourceaddr;
  uint8_t data[REDUCE_MAX_BUFLEN];
} __attribute__ ((packed)) ReduceMsg;

typedef struct CommandMsg {
  uint16_t destaddr;
  uint16_t commandID;
  uint16_t data_len;
  uint8_t seqno;
  uint8_t data[COMMAND_MAX_BUFLEN];
} __attribute__ ((packed)) CommandMsg;
