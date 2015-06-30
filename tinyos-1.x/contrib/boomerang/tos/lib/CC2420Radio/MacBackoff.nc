/*
 * Copyright (c) 2006 Moteiv Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached MOTEIV-LICENSE     
 * file. If you do not find these files, copies can be found at
 * http://www.moteiv.com/MOTEIV-LICENSE.txt and by emailing info@moteiv.com.
 */

/**
 * Mac Backoff Interface.  Allows services to control the number of
 * symbol units for a backoff event.  Use with care; modifying the
 * backoffs may result in very poor overall system operation!
 *
 * @author Joe Polastre, Moteiv Corporation <info@moteiv.com>
 */
interface MacBackoff
{
  async event int16_t initialBackoff(TOS_MsgPtr m);
  async event int16_t congestionBackoff(TOS_MsgPtr m);
}
