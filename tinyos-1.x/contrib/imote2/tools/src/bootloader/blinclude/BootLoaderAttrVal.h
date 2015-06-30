/*									tab:4
 * "Copyright (c) 2000-2003 The Regents of the University  of California.  
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
 * Copyright (c) 2002-2003 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */

/**
 * @file BootLoaderAttrVal.h
 * @author Junaith Ahemed Shahabdeen
 * 
 * File defines the boot loader table shared by the application.
 *
 * NOTE
 *   This is a safety measure to prevent the app from including
 *   or modifying any files in the boot loader.
 * 
 */
#ifndef BOOTLOADER_ATTR_VAL_H
#define BOOTLOADER_ATTR_VAL_H

#include <BootLoaderInc.h>

unsigned short Gen_ATTR_Shared_Table [ATTR_SHARED_TABLE_NUM][2] =
  {
    {ATTR_VERIFY_IMAGE, 4},
    {ATTR_PERFORM_SELF_TEST, 4},
    {ATTR_IMG_LOAD_LOCATION, 4},
    {ATTR_IMG_CRC, 4},
    {ATTR_IMG_SIZE, 4},
    {ATTR_SELF_TEST_IMG_LOC, 4},
    {ATTR_SELF_TEST_IMG_CRC, 4},
    {ATTR_SELF_TEST_IMG_SIZE, 4},
  };

/*Current size of the shared table (only the valid part)*/
/*FIXME Length has to be automated based on number of attributes*/
#define SHARED_TABLE_SIZE ((ATTR_SHARED_TABLE_NUM*sizeof (Attribute)) + 32)

#endif
