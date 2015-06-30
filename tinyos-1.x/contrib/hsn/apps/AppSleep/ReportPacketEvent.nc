/*									
 * Copyright (c) 2002-2003 Intel Corporation
 * All rights reserved.
 */

/*
 * Authors:		Jasmeet Chhabra
 *
 *
 */

/**
 * Generic Interface to report a countable event to the counter component
 */
interface ReportPacketEvent
{ 
  async command result_t PacketEvent(uint16_t type, uint32_t seqNum);
}
