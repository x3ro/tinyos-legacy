/*
 * Copyright (c) 2006 Moteiv Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached MOTEIV-LICENSE     
 * file. If you do not find these files, copies can be found at
 * http://www.moteiv.com/MOTEIV-LICENSE.txt and by emailing info@moteiv.com.
 */

/**
 * Implementation of the utility functions (link estimation and time
 * stamping) for SP.
 *
 * @author Joe Polastre, Moteiv Corporation <info@moteiv.com>
 */
module SPUtilM {
  provides interface SPUtil;
  uses interface TimeStamping<T32khz, uint32_t>;
  uses interface SPLinkStats;
}
implementation {

  command uint16_t SPUtil.getQuality(sp_neighbor_t* n, TOS_Msg* msg) {
    return call SPLinkStats.getQuality(n, msg);
  }

  command uint32_t SPUtil.getSenderTimestamp(TOS_MsgPtr msg, int8_t offset) {
    return call TimeStamping.getStampMsg(msg, offset);
  }

  command uint32_t SPUtil.getReceiveTimestamp(TOS_MsgPtr msg) {
    return call TimeStamping.getReceiveStamp(msg);
  }

}
