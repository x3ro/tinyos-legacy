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
 * @file AttrAccess.c
 * @author Junaith Ahemed Shahabdeen
 *
 * Attributes are parameters that is used by the system to make it
 * flexible and configurable with out recompiling the source, few
 * examples will be <I>Number of Retries on a command failure</I> and
 * <I>timeout values for a response</I> etc.
 *
 * This file provides functions for getting and setting atrributes together
 * with helper functions for locating the position of an attribute or a
 * table that contains a particular attribute. The attributes, length, and
 * its table size is defined in <I>BLAttrDefines</I>.
 *
 * The currently active attribute tables are maintained in two different 
 * flash blocks other than the default table. Attribute update occurs on
 * one the block which hold the current invalid value and is marked as valid,
 * and the old valid value is marked invalid. This mechanism is to share the
 * load between flash block holding the tables.
 */
#ifndef ATTR_ACCESS_H
#define ATTR_ACCESS_H

#include <BLAttrDefines.h>
#include <types.h>
#include <FlashAccess.h>

#define ATTR_SET_LIMIT 20
/**
 * struct AttrSet
 *
 * Set of attributes that has to be set or read from the
 * attribute table.
 */
typedef struct AttrSet
{
  uint8_t NumAttributes;
  uint16_t AttrId [ATTR_SET_LIMIT];
  uint32_t AttrVal [ATTR_SET_LIMIT];
}AttrSet;

/**
 * Read_Attribute_Data
 *
 * Read the attribute from the flash. 
 * The function copies the whole attribute to the buffer.
 * 
 * @param attr Id of the Attribute which has to be retrived.
 * @parma data Buffer to which the entire attribute struct will be copied to.
 *
 * @return SUCCESS | FAIL
 */
result_t Read_Attribute (uint16_t attr, void* data);

/**
 * Read_Attribute_Value
 *
 * Read the value of a particular attribute from the flash. 
 * The function copies only the value of the attribute to the parameter
 * passed. As a <I>precondition</I> the user has to get the length of the
 * attribute and create a buffer which can hold that length before
 * passing the buffer as a parameter to this fucntion.
 *
 * @param attr The Attribute Id.
 * @param data Pointer to the buffer to which the value will be copied to.
 *
 * @return SUCCESS | FAIL
 */
result_t Read_Attribute_Value (uint16_t attr, void* data);

/**
 * Write_Attribute_Value
 *
 * This function will update an attribute with a new value. The
 * attribute id and the value of the attribute is passed as
 * parameter.
 *
 * @param AttrID ID of the Attribute that is updated.
 * @param Val    new Value to be updated.
 *
 * @return SUCCESS | ERROR
 */
result_t Write_Attribute_Value (uint16_t AttrID, uint32_t Val);

/**
 * Write_Attribute_Set
 *
 * The function provides an efficiently updating a list of 
 * attributes that belong to the same table in a single pass. The
 * AttrSet values must be set before it is passed to the function and
 * the number of attributes in the set cannot exceed ATTR_SET_LIMIT (20).
 * <B>It is absolutely required that the attributes must belong to 
 * the same table. </B>
 *
 * As a <I>precondition</I> the AttrSet has to be populated with
 * the required information and the table id of the attributes has
 * to be obtained.
 * 
 * @param table Table Id for the set.
 * @param aset	Attribute set with the list of attr and its values.
 *
 * @return SUCCESS | ERROR
 */
result_t Write_Attribute_Set (ATTR_Address_Table table, AttrSet* aset);


/**
 * Recover_Default_Table
 *
 * Reset a particular table to its default state. Usually performed 
 * during disaster recovery.
 * 
 * @param table The table to be reset.
 * @return SUCCESS | FAIL
 */
result_t Recover_Default_Table (ATTR_Address_Table table);

/**
 * Read_Attribute_Table
 *
 * The function copies the entire attribute table in to the
 * second parameter. The higher level is responsible for
 * allocating the data and passing the required length.
 *
 * @param TblAddr Starting Address of the table has to be read.
 * @param length  Length of the table.
 * @param data	  RAM location to copy the table to.
 *
 * @return SUCCESS | FAIL
 */
result_t Read_Attribute_Table (uint32_t TblAddr, uint32_t length, void* data);

/**
 * Write_Attribute_Table
 * 
 * Write the entire table back to the flash memory. The entire flash
 * block will be erase and the table will be rewritten.
 *
 * @param TblAddr Starting Address of the table.
 * @param length  Length of the table.
 * @param data    Pointer to the table in memory.
 *
 * @return SUCCESS | ERROR
 */  
result_t Write_Attribute_Table (uint32_t TblAddr, uint32_t length, void* data);

/**
 * Get_Table_ID
 * 
 * Returns a table ID for a particular attribute type. The BLAttrDefines.h
 * file defines the attribute type ranges.
 *
 * @param attr Attribute Type for which the table name is required.
 * @return TABLE ID | 0 on error
 */
ATTR_Address_Table Get_Attribute_TableID (uint16_t attr);


/**
 * Get_Attribute_Length
 *
 * Get the length of the attribute by passing the attribute type.
 * 
 * @param attr Attribute Type for which to find the Length.
 * @return Length | 0 on error
 */
uint8_t Get_Attribute_Length (uint16_t attr);

/**
 * Get_Attr_Flash_Address
 *
 * Given the table name and the attribute id the function will
 * calculate the current flash address location of the attribute.
 * 
 * @param TblID The table Id in which the attribute belongs.
 * @param AttrID  The ID of the attribute.
 *
 * @return Addr Address of the attribute.
 */
uint32_t Get_Attr_Flash_Address (ATTR_Address_Table TblID, uint16_t AttrID);

#endif
