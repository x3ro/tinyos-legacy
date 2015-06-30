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
 * @file BootLoaderInc.h
 *
 * @author Junaith Ahemed Shahabdeen
 *
 * Shared header file between the Application and the
 * Boot Loader which contains the extended state definitions.
 */
#ifndef BOOTLOADER_INC_H
#define BOOTLOADER_INC_H

/***********************************************************************************
 *                              SHARED TABLE                                       *
 ***********************************************************************************/
#define ATTR_SHARED_TABLE_START 351
#define ATTR_SHARED_TABLE_END 800
#define ATTR_SHARED_TABLE_NUM 8

#define SELF_TEST_IMG_LOC 0x1F20000

typedef enum ATTR_Shared_Table
{
  ATTR_VERIFY_IMAGE = 351,       /*Set to true will place the bl in Verify Image*/
  ATTR_PERFORM_SELF_TEST = 352,  /*Set to true will place the bl in self test*/
  ATTR_IMG_LOAD_LOCATION = 400,
  ATTR_IMG_CRC = 401,
  ATTR_IMG_SIZE = 402,
  ATTR_SELF_TEST_IMG_LOC = 403,  /*Self Test Image Location*/
  ATTR_SELF_TEST_IMG_CRC = 404,  /*Self Test Image Crc*/
  ATTR_SELF_TEST_IMG_SIZE = 405, /*Self Test Image Size*/  
} ATTR_Shared_Table;


typedef struct Attribute
{
  unsigned short AttrType;    /* Identifies and attribute uniquely */
  unsigned char AttrValidity; /* Says if the AttrValue is valid or invalid*/
  unsigned char AttrLength;   /* The length could be from 4 to 255 */
  unsigned int AttrValidAddr; /* The next location to find the attribute */
  unsigned char AttrValue[];  /* Value of the Attribute */
} Attribute;


#endif
