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

enum {
  SHAREDVAR_MAX_KEY = 32,
  SHAREDVAR_BUFLEN = 16,
  AM_SHAREDVARMSG = 88,
  SHAREDVAR_CMD_GET = 1,
  SHAREDVAR_REPLY_GET = 2,
};

typedef struct SharedVarMsg {
  uint8_t cmd;
  uint16_t sourceaddr;
  uint8_t key;
  uint8_t data[SHAREDVAR_BUFLEN];
  uint8_t data_len;
  uint8_t success; // For replies
} __attribute__ ((packed)) SharedVarMsg;

