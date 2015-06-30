/*
 * Copyright (c) 2004,2005 Hewlett-Packard Company
 * All rights reserved
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:

 *     * Redistributions of source code must retain the above copyright
 *       notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above
 *       copyright notice, this list of conditions and the following
 *       disclaimer in the documentation and/or other materials provided
 *       with the distribution.
 *     * Neither the name of the Hewlett-Packard Company nor the names of its
 *       contributors may be used to endorse or promote products derived
 *       from this software without specific prior written permission.

 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * Authors:  Andrew Christian
 *           16 December 2004
 */

includes Message;
includes IEEEUtility;

module IEEEUtilityM {
  provides {
    interface IEEEUtility;
  }
}

implementation {

  /*
   * Extract the source PAN_ID.  If INTRA_PAN is set and a destination address
   * was set, then the source PAN_ID is omitted.
   */

  bool extract_pan( struct Message *msg, struct DecodedHeader *header )
  {
    if ( (header->fcf1 & INTRA_PAN) && (header->fcf2 & DEST_MODE_MASK) != 0) {
      header->src.pan_id = header->dest.pan_id;
    }
    else {
      if ( msg_get_length(msg) < 2 ) return FALSE;
      header->src.pan_id = msg_get_saddr( msg, 0 );
      msg_drop_from_front( msg, 2 );
    }
    return TRUE;
  }

  command bool IEEEUtility.decodeHeader( struct Message *msg, struct DecodedHeader *header )
  {
    if ( msg_get_length(msg) < 5 )
      return FALSE;

    // Grab the end bits
    header->rssi = msg_get_int8( msg, msg_get_length(msg) - 2 );
    header->lqi  = msg_get_uint8( msg, msg_get_length(msg) - 1 ) & 0x7f;
    msg_drop_from_end( msg, 2 );

    header->fcf1 = msg_get_uint8(msg,0);
    header->fcf2 = msg_get_uint8(msg,1);

    // Drop the FCF and DSN
    msg_drop_from_front( msg, 3 );

    // Extract the destination address
    switch (header->fcf2 & DEST_MODE_MASK) {
    case 0:
      break;   // No DEST mode

    case DEST_MODE_SHORT:
      if ( msg_get_length(msg) < 4 ) return FALSE;
      header->dest.pan_id  = msg_get_saddr( msg, 0 );
      header->dest.a.saddr = msg_get_saddr( msg, 2 );
      msg_drop_from_front( msg, 4 );
      break;

    case DEST_MODE_LONG:
      if ( msg_get_length(msg) < 10 ) return FALSE;
      header->dest.pan_id = msg_get_saddr( msg, 0 );
      msg_get_buf( msg, 2, header->dest.a.laddr, 8 );
      msg_drop_from_front( msg, 10 );
      break;

    default:
      return FALSE;   // Illegal
    }

    // Extract the source address
    switch (header->fcf2 & SRC_MODE_MASK) {
    case 0:
      break;   // No SRC mode

    case SRC_MODE_SHORT:
      if ( !extract_pan( msg, header ) || msg_get_length(msg) < 2 )
	return FALSE;

      header->src.a.saddr = msg_get_saddr( msg, 0 );
      msg_drop_from_front( msg, 2 );
      break;
      
    case SRC_MODE_LONG:
      if ( !extract_pan( msg, header ) || msg_get_length(msg) < 8 )
	return FALSE;

      msg_get_buf( msg, 0, header->src.a.laddr, 8 );
      msg_drop_from_front( msg, 8 );
      break;

    default:
      return FALSE;   // Illegal
    }

    return TRUE;
  }
}
