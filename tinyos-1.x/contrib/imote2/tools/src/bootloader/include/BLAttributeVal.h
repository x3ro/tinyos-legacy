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
 * @file BLAttributeVal.h
 * @author Junaith Ahemed Shahabdeen
 * 
 * This file defines the attribute value table and the length
 * of each attribute in an array. 
 *
 * This file is mainly used for generating attribute binary and
 * also provides an easy way to add new attributes.
 * 
 */
#ifndef BL_ATTRIBUTE_VAL_H
#define BL_ATTRIBUTE_VAL_H

#include <BLAttrDefines.h>
#include <BootLoaderAttrVal.h>

/**
 * This size of the array is limited to BL_ATTR_ADDRESS_TABLE_NUM, if
 * you are adding a new value then confirm that you can incremented
 * the BL_ATTR_ADDRESS_TABLE_NUM.
 */ 
unsigned short Gen_ATTR_Addr_Table [BL_ATTR_ADDRESS_TABLE_NUM] [2] = 
             {
               {BL_ATTR_TYP_ADDRESS_TABLE, 4},
               {BL_ATTR_TYP_DEF_BOOTLOADER, 4},
               {BL_ATTR_TYP_BOOTLOADER, 4},
               {BL_ATTR_TYP_DEF_SHARED, 4},
               {BL_ATTR_TYP_SHARED, 4},
               {BL_ATTR_TYP_BOOT_LOCATION, 4},
             };

/*Current size of the address table (only the valid part)*/
#define ADDRESS_TABLE_SIZE ((BL_ATTR_ADDRESS_TABLE_NUM*sizeof (Attribute)) + 24)

/**
 * This size of the array is limited to BL_ATTR_BOOTLOADER_TABLE_NUM, <B>if
 * you are adding a new value then confirm that you can incremented
 * the BL_ATTR_ADDRESS_TABLE_NUM.</B>
 */ 
unsigned short Gen_ATTR_Bootloader_Table [BL_ATTR_BOOTLOADER_TABLE_NUM][2] = 
             {
               {BL_ATTR_TYP_SYNC_TIMEOUT, 4},
               {BL_ATTR_TYP_BOOTLOADER_STATE, 4},
               {BL_ATTR_TYP_CMD_FAIL_RETRY, 4},
               {BL_ATTR_TYP_CRC_FAIL_RETRY, 4},
               {BL_ATTR_TYP_DATA_WINDOW, 4},
               {BL_ATTR_TYP_SELF_TEST_TIMEOUT, 4},
               {BL_ATTR_TYP_CMD_TIMEOUT, 4},
               {BL_ATTR_TYP_BIN_TIMEOUT, 4},
               {BL_ATTR_TYP_PRIMARY_IMG_LOCATION, 4},
               {BL_ATTR_TYP_PRIMARY_IMG_CRC, 4},
               {BL_ATTR_TYP_PRIMARY_IMG_SIZE, 4},
               {BL_ATTR_TYP_PRIMARY_IMG_VALIDITY, 4},
               {BL_ATTR_TYP_SECONDARY_IMG_LOCATION, 4},
               {BL_ATTR_TYP_SECONDARY_IMG_CRC, 4},
               {BL_ATTR_TYP_SECONDARY_IMG_SIZE, 4},
               {BL_ATTR_TYP_SECONDARY_IMG_VALIDITY, 4},
               {BL_ATTR_TYP_BOOT_IMG_CRC, 4},
               {BL_ATTR_TYP_BOOT_IMG_SIZE, 4},
               {BL_ATTR_TYP_BOOT_IMG_VALIDITY, 4},
               {BL_ATTR_TYP_DEF_SELF_TEST_IMG_LOC, 4},
               {BL_ATTR_TYP_DEF_SELF_TEST_IMG_CRC, 4},
               {BL_ATTR_TYP_DEF_SELF_TEST_IMG_SIZE, 4},
             };

/*Current size of the bootloader table (only the valid part)*/
/*FIXME Automate the length calculation*/
#define BOOTLOADER_TABLE_SIZE ((BL_ATTR_BOOTLOADER_TABLE_NUM*sizeof (Attribute)) + 88)

/***************************************************************************
 *
 * THESE VALUES ARE USED FOR ATTRIBUTE GENERATION PURPOSES ONLY
 *
 * DONT NOT USE THIS IN THE SOURCE FILE, IT WILL DEFEAT THE PURPOSE
 *
 ***************************************************************************/

unsigned int Gen_ATTR_Addr_Table_Data [BL_ATTR_ADDRESS_TABLE_NUM] = 
             {BL_ATTR_ADDRESS_TABLE,
              BL_ATTR_DEF_BOOTLOADER,
              BL_ATTR_BOOTLOADER,
              BL_ATTR_DEF_SHARED,
              BL_ATTR_SHARED,
	      BL_ATTR_BOOT_LOC
              }; 

unsigned int Gen_ATTR_Bootloader_Table_Data [BL_ATTR_BOOTLOADER_TABLE_NUM] = 
             { 500, /*Timeout in MS */
               1,   /*Boot_State = NORMAL*/
	       3,   /*Retry thrice on command failure*/
	       3,   /*Retry thrice on CRC failure*/
	       546, /*Data Window Size in (546*61) */
	       BL_ATTR_TYP_SELF_TEST_TIMEOUT, /*WD Timeout value for Self Test*/
	       CMD_TIMEOUT_VAL,
	       BIN_TIMEOUT_VAL,
               BL_PRIMARY_IMAGE_LOCATION, /* Primary Image Location*/
	       0, /*CRC is 0*/
	       0, /*Size is 0*/ 
	       0, /*Image not valid*/
	       BL_SECONDARY_IMAGE_LOCATION, /* Secondary Image Location*/
	       0, /*CRC is 0*/
	       0, /*Size is 0*/ 
	       0, /*Image not valid*/
               0, /*Boot Img CRC is 0*/
	       0, /*Boot Img Size is 0*/ 
	       0, /*Boot Image not valid*/
               BL_DEF_SELF_TEST_IMG_LOC, /*Self Test Image Locaiton*/
	       0, /*Self Test Image CRC*/
	       0, /*Self Test Image Size*/
             }; 

unsigned int ATTR_Shared_Table_Data [ATTR_SHARED_TABLE_NUM] =
             { 0,  /*Default Value is False*/
               0,  /*Default Value is False*/
	       BL_SECONDARY_IMAGE_LOCATION,
	       0, /*CRC is zero*/
	       0, /*Size is zero*/
	       SELF_TEST_IMG_LOC, /*Self test image location*/
	       0, /*Self Test image CRC*/
	       0, /*Self Test image Size*/
	     };

#endif
