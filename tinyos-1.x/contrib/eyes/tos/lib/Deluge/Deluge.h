// $Id: Deluge.h,v 1.5 2005/01/25 18:08:51 klueska Exp $

/*									tab:4
 *
 *
 * "Copyright (c) 2000-2004 The Regents of the University  of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 *
 */

/**
 * Manages advertisements of image data and updates to metadata. Also
 * notifies <code>DelugePageTransfer</code> of nodes to request data
 * from.
 *
 * @author Jonathan Hui <jwhui@cs.berkeley.edu>
 */

#ifndef __DELUGE_H__
#define __DELUGE_H__

#if defined(PLATFORM_EYESIFX)
enum {
  DELUGE_MAX_IMAGE_SIZE = 30, // in kilobytes
  DELUGE_NUM_IMGS       = 1,
};
#else
enum {
  DELUGE_MAX_IMAGE_SIZE = 96, // in kilobytes
  DELUGE_NUM_IMGS       = 2,
};
#endif

enum {
  DELUGE_MIN_ADV_PERIOD_LOG2        = 11,
  DELUGE_MAX_ADV_PERIOD_LOG2        = 21,
  DELUGE_MAX_OVERHEARD_ADVS         = 1,
  DELUGE_NUM_NEWDATA_ADVS_REQUIRED  = 2,
  DELUGE_NUM_MIN_ADV_PERIODS        = 2,
  DELUGE_MAX_NUM_REQ_TRIES          = 1,
  DELUGE_FAILED_SEND_DELAY          = 16,
  DELUGE_MIN_DELAY                  = 16,
  DELUGE_INVALID_VNUM               = -1,
  DELUGE_INVALID_IMGNUM             = 0xff,
  DELUGE_MAX_REQ_DELAY              = (0x1 << (DELUGE_MIN_ADV_PERIOD_LOG2-1)),
  DELUGE_NACK_TIMEOUT               = (DELUGE_MAX_REQ_DELAY >> 0x1),
};

#define NODE_0_STARTUP_DELAY      2 // for debugging only

#if defined(PLATFORM_MICA2) || defined(PLATFORM_MICA2DOT) || defined(PLATFORM_MICAZ)
#define IFLASH_GVNUM_ADDR      0xFD6
#elif defined(PLATFORM_TELOS) || defined(PLATFORM_EYESIFX) || defined(PLATFORM_EYESIFXV2)
#define IFLASH_GVNUM_ADDR      0x56
#endif

#endif
