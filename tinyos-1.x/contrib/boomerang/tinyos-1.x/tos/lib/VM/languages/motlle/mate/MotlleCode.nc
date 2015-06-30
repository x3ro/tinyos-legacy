/*
 * Copyright (c) 2004-2005 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
interface MotlleCode 
{
  command uint8_t read_uint8_t(MateContext *context);
  command int16_t read_offset(MateContext *context, bool sixteen);
  command uint16_t read_local_var(MateContext *context);
  command uint16_t read_closure_var(MateContext *context);
  command uint16_t read_global_var(MateContext *context);
  command mvalue read_value(MateContext *context);
}
