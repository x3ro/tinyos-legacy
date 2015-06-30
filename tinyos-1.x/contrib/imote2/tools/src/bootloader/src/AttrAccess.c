//$Id: AttrAccess.c,v 1.1 2006/10/10 22:34:06 lnachman Exp $
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
 */
#include <AttrAccess.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <BinImageHandler.h>
#include <Leds.h>

/*** To be included only in the source*/
#include <BLAttributeVal.h>

/**
 * Read_Attribute_Data
 *
 * Read the attribute from the flash. 
 * The function copies only the whole attribute to the buffer.
 *
 * <B>
 * NOTE:
 *    NEVER PASS A BUFFER POINTER WHICH CANNOT ACCOMODATA A
 *    LENGTH OF (sizeof (Attribute) + length of Attribute).
 * </B>
 *
 * @param attr Id of the Attribute which has to be retrived.
 * @parma data Buffer to which the entire attribute struct will be copied to.
 *
 * @return SUCCESS | FAIL
 */
result_t Read_Attribute (uint16_t attr, void* data)
{
  Attribute* attPtr;
  ATTR_Address_Table table = Get_Attribute_TableID (attr);
  uint8_t length = Get_Attribute_Length (attr);
  uint8_t AttributeBuff [sizeof (Attribute) + length];
  uint32_t AttrPos = 1;
  attPtr = (Attribute*) AttributeBuff; 
  uint8_t errbuff [60];
  uint8_t ErrVal = 0;

  if ((table == FAIL) || (length == FAIL))
    return FAIL;
  
  /** 
   * Load the address table to find the current address.
   */
  AttrPos = (uint32_t) Get_Attr_Flash_Address (table, attr);
  if (AttrPos == FAIL)
  {
    return FAIL;
  }
  if(Flash_Read(AttrPos, (sizeof (Attribute) + length), AttributeBuff) == FAIL)
  {
    Send_USB_Error_Packet (ERR_FLASH_READ, 0, NULL);
    return FAIL;
  }
  /**FIXME i think for loop might be better*/
  /*Check if the attribute value is valid in the current location*/
  if (attPtr->AttrValidity == BL_INVALID_ATTR)
  {
    /* If we add exactly the table size then we can get to the right position
     * of the attribute.
     */
    AttrPos += BL_TABLE_SIZE;
    if(Flash_Read(AttrPos, sizeof (Attribute) + length, AttributeBuff) == FAIL)
    {
      Send_USB_Error_Packet (ERR_FLASH_READ, 0, NULL);
      return FAIL;
    }
  }
  /* Check the validity of the data.*/
  attPtr = (Attribute*) AttributeBuff; 
  if (attPtr->AttrType == attr)
  {
   /**
    * We might have attributes that are not integers and could be
    * an array. So its better to check it byte by byte.
    */
    for (ErrVal = 0; ErrVal < attPtr->AttrLength; ErrVal++)  
      if (attPtr->AttrValue [ErrVal] != 0xFF)
         break;
    if (ErrVal <= (attPtr->AttrLength - 1))
    {
      memcpy (data, AttributeBuff, (sizeof (Attribute) + length));
      return SUCCESS;
    }
    else
      sprintf (errbuff, "Attribute contains invalid value.\n");
  }
  else
    sprintf (errbuff, "Error Reading Attribute Location.\n");
  
  Send_USB_Error_Packet (ERR_FATAL_ERROR_ABORT, 60, errbuff);  
  return FAIL;
}


/**
 * Read_Attribute_Value
 *
 * Read the attribute data of a particular attribute from the flash. 
 * The function copies only the value of the attribute to the parameter
 * passed. As a precondition the user has to get the length of the
 * attribute and create a buffer which can hold that value, before
 * passing the buffer as a parameter to this fucntion.
 *
 * NOTE:
 *    NEVER PASS A BUFFER POINTER WHICH CANNOT ACCOMODATA THE
 *    ATTRIBUTE VALUE.
 *
 * @param attr The Attribute Id.
 * @param data Pointer to the buffer to which the value will be copied to.
 *
 * @return SUCCESS | FAIL
 */
result_t Read_Attribute_Value (uint16_t attr, void* data)
{
  Attribute* attPtr;
  ATTR_Address_Table table = Get_Attribute_TableID (attr);
  uint8_t length = Get_Attribute_Length (attr);
  uint8_t AttributeBuff [sizeof (Attribute) + length];
  uint32_t AttrPos = 1;
  attPtr = (Attribute*) AttributeBuff; 
  uint8_t errbuff [60];
  uint8_t ErrVal = 0;

  if ((table == FAIL) || (length == FAIL))
    return FAIL;

  /** 
   * Load the address table to find the current address.
   */
  AttrPos = (uint32_t) Get_Attr_Flash_Address (table, attr);
  if (AttrPos == FAIL)
    return FAIL;

  if(Flash_Read(AttrPos, sizeof (Attribute) + length, AttributeBuff) == FAIL)
  {
    Send_USB_Error_Packet (ERR_FLASH_READ, 0, NULL);
    return FAIL;
  }
  attPtr = (Attribute*) AttributeBuff; 
  /**FIXME i think for loop might be better*/
  /*Check if the attribute value is valid in the current location*/
  if (attPtr->AttrValidity == BL_INVALID_ATTR)
  {
    /**
     * If we add exactly the table size then we can get to the right position
     * of the attribute.
     */
    AttrPos += BL_TABLE_SIZE;
    if(Flash_Read(AttrPos, sizeof (Attribute) + length, AttributeBuff) == FAIL)
    {
      Send_USB_Error_Packet (ERR_FLASH_READ, 0, NULL);
      return FAIL;
    }
    attPtr = (Attribute*) AttributeBuff; 
  }

  if (attPtr->AttrType == attr)
  {
   /**
    * We might have attributes that are not integers and could be
    * an array. So its better to check it byte by byte.
    */
    for (ErrVal = 0; ErrVal < attPtr->AttrLength; ErrVal++)  
      if (attPtr->AttrValue [ErrVal] != 0xFF)
         break;
    if (ErrVal <= (attPtr->AttrLength - 1))
    {
      memcpy (data, attPtr->AttrValue, length);
      return SUCCESS;
    }
    else
      sprintf (errbuff, "Attribute contains invalid value.\n");
  }
  else
    sprintf (errbuff, "Error Reading Attribute Location.\n");

  Send_USB_Error_Packet (ERR_FATAL_ERROR_ABORT, 60, errbuff);
  return FAIL;
}

/**
 * Recover_Default_Table
 *
 * Reset a table to its default state. Usually performed during disaster
 * recovery.
 * @param table The table to be reset.
 * @return SUCCESS | FAIL
 */
result_t Recover_Default_Table (ATTR_Address_Table table)
{
  uint8_t* AttrBuff;
  uint32_t DefBaseAddress = 1;
  uint32_t BaseAddress = 1;
  uint32_t TblSize = 0;
  result_t res = SUCCESS;
  switch (table)
  {
    case BL_ATTR_TYP_ADDRESS_TABLE:
      /*FIXME Send an error stating that its write protected*/
      return FAIL;
    break;
    case BL_ATTR_TYP_DEF_BOOTLOADER:
    case BL_ATTR_TYP_BOOTLOADER:
      DefBaseAddress = BL_ATTR_DEF_BOOTLOADER;
      BaseAddress = BL_ATTR_BOOTLOADER;
      TblSize = BOOTLOADER_TABLE_SIZE;
    break;
    case BL_ATTR_TYP_DEF_SHARED:
    case BL_ATTR_TYP_SHARED:
      DefBaseAddress = BL_ATTR_DEF_SHARED;
      BaseAddress = BL_ATTR_SHARED;
      TblSize = SHARED_TABLE_SIZE;
    break;
    default:
    return FAIL;
  }
  AttrBuff = (uint8_t*) malloc (TblSize * sizeof(uint8_t));
  if (AttrBuff == NULL)
    return FAIL;
  
  if(Flash_Read(DefBaseAddress, TblSize, AttrBuff) == FAIL)
  {
    free (AttrBuff);
    Send_USB_Error_Packet (ERR_FLASH_READ, 0, NULL);
    return FAIL;
  }
  
  if (Flash_Erase (BaseAddress) == FAIL)
    res = FAIL;
  
  if (Flash_Write (BaseAddress, AttrBuff, TblSize) == FAIL)
    res = FAIL;

  free (AttrBuff);
  return res;
}

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
result_t Read_Attribute_Table (uint32_t TblAddr, uint32_t length, void* data)
{
  if(Flash_Read(TblAddr, length, data) == FAIL)
  {
    Send_USB_Error_Packet (ERR_FLASH_READ, 0, NULL);
    return FAIL;
  }  
  return SUCCESS;
}

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
result_t Write_Attribute_Table (uint32_t TblAddr, uint32_t length, void* data)
{
  /* cannot fail. If we do then we should replace the attr */
  if (Flash_Erase (TblAddr) == FAIL)
    return FAIL;
  if (Flash_Write (TblAddr, data, length) == FAIL)
    return FAIL; /*FIXME Bad. Load the default attr back*/
  return SUCCESS;
}

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
result_t Write_Attribute_Value (uint16_t AttrID, uint32_t Val)
{
  Attribute* attPtr;
  ATTR_Address_Table table = Get_Attribute_TableID (AttrID);
  uint8_t length = Get_Attribute_Length (AttrID);
  uint8_t AttributeBuff [sizeof (Attribute) + length];
  uint32_t InValidAttrPos = 1;
  uint32_t ValidAttrReadPos = 1;
  uint32_t ValidAttrWritePos = 1;
  uint32_t BaseAddress = 1;
  uint32_t TblSize = 0;
  uint8_t* AttrBuff;
  uint8_t Invalid = BL_INVALID_ATTR;
  attPtr = (Attribute*) AttributeBuff; 

  /* If its some thing like 0xFFFFFFFF then its not allowed*/
  if (Val == 0xFFFFFFFF)
    return FAIL;

  if ((table == FAIL) || (length == FAIL))
    return FAIL;

  switch (table)
  {
    case BL_ATTR_TYP_ADDRESS_TABLE:
    case BL_ATTR_TYP_DEF_BOOTLOADER:
    case BL_ATTR_TYP_DEF_SHARED:
      /*FIXME Send an error stating that its write protected*/
      return FAIL;
    break;
    case BL_ATTR_TYP_BOOTLOADER:
      BaseAddress = BL_ATTR_BOOTLOADER;
      TblSize = BOOTLOADER_TABLE_SIZE;
    break;
    case BL_ATTR_TYP_SHARED:
      BaseAddress = BL_ATTR_SHARED;
      TblSize = SHARED_TABLE_SIZE;
    break;
    default:
    return FAIL;
  }

  AttrBuff = (uint8_t*) malloc (TblSize * sizeof(uint8_t));
  if (AttrBuff == NULL)
    return FAIL;  /*FIXME fatal error, requires more handling*/

  {
    ValidAttrReadPos = (uint32_t) Get_Attr_Flash_Address (table, AttrID);
    if(Flash_Read(ValidAttrReadPos, sizeof (Attribute) + length, AttributeBuff) == FAIL)
    {
      free (AttrBuff);
      Send_USB_Error_Packet (ERR_FLASH_READ, 0, NULL);
      return FAIL;
    }

    /*Check if the attribute value is valid in the current location*/
    if (attPtr->AttrValidity == BL_VALID_ATTR)
    {
      InValidAttrPos = ValidAttrReadPos + 2; /* Add size of type */
      //ValidAttrReadPos = BaseAddress;
      ValidAttrWritePos = BaseAddress + BL_TABLE_SIZE;
    }
    else
    {
      InValidAttrPos = ValidAttrReadPos + BL_TABLE_SIZE + 2; /* Add size of type */
      //ValidAttrReadPos = BaseAddress + BL_TABLE_SIZE;
      ValidAttrWritePos = BaseAddress;
    }

    if(Flash_Read(ValidAttrWritePos, TblSize, AttrBuff) == FAIL)
    {
      free (AttrBuff);
      Send_USB_Error_Packet (ERR_FLASH_READ, 0, NULL);
      return FAIL;
    }
    else
    {
      uint32_t offset = (ValidAttrReadPos - BaseAddress);
      attPtr = (Attribute*) (AttrBuff + offset);
      attPtr->AttrValidity = BL_VALID_ATTR; /* Make it valid*/
      memcpy (attPtr->AttrValue, &Val, 4);     /* Assign the new value*/
    }

    /* cannot fail. If we do then we should replace the attr */
    if (Flash_Erase (ValidAttrWritePos) == FAIL)
    {
      free (AttrBuff);
      return FAIL;
    }
    if (Flash_Write (ValidAttrWritePos, AttrBuff, TblSize) == FAIL)
    {
      free (AttrBuff);
      return FAIL; /*FIXME Bad. Load the default attr back*/
    }
    if (Flash_Write (InValidAttrPos, &Invalid, 1) == FAIL)
    {
      free (AttrBuff);
      return FAIL;
    }
  }
  free (AttrBuff);
  return SUCCESS;
}

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
result_t Write_Attribute_Set (ATTR_Address_Table table, AttrSet* aset)
{
  Attribute* attPtr;
  Attribute* attPtr2;
  uint32_t BaseAddress = 1;
  uint32_t TblSize = 0;
  uint8_t AttrBuff1 [0x2000];
  uint8_t AttrBuff2 [0x2000];
  uint16_t acnt = 0;
  uint16_t oall = 0;
  uint16_t mlen = 0;
  uint16_t NumAttr = 0;

  if (table == FAIL)
    return FAIL;
  /**
   * We are currently restricting the number of attributes in
   * a set.
   */
  if (aset->NumAttributes > ATTR_SET_LIMIT)
    return FAIL;

  switch (table)
  {
    case BL_ATTR_TYP_ADDRESS_TABLE:
    case BL_ATTR_TYP_DEF_BOOTLOADER:
    case BL_ATTR_TYP_DEF_SHARED:
      /*FIXME Send an error stating that its write protected*/
      return FAIL;
    break;
    case BL_ATTR_TYP_BOOTLOADER:
      BaseAddress = BL_ATTR_BOOTLOADER;
      TblSize = BOOTLOADER_TABLE_SIZE;
      NumAttr = BL_ATTR_BOOTLOADER_TABLE_NUM;
    break;
    case BL_ATTR_TYP_SHARED:
      BaseAddress = BL_ATTR_SHARED;
      TblSize = SHARED_TABLE_SIZE;
      NumAttr = ATTR_SHARED_TABLE_NUM;
    break;
    default:
    return FAIL;
  }

  /* Read first Location */
  if(Flash_Read(BaseAddress, TblSize, AttrBuff1) == FAIL)
  {
    Send_USB_Error_Packet (ERR_FLASH_READ, 0, NULL);
    return FAIL;
  }
  
  /* Read secondary Location (BaseAddress + table size)*/
  if(Flash_Read((BaseAddress + BL_TABLE_SIZE), TblSize, AttrBuff2) == FAIL)
  {
    Send_USB_Error_Packet (ERR_FLASH_READ, 0, NULL);
    return FAIL;
  }

  for (oall = 0; oall < aset->NumAttributes; oall ++)
  {
    mlen = 0;
    for (acnt = 0; acnt < NumAttr; acnt ++)
    {
      attPtr = (Attribute*) (AttrBuff1 + mlen);
      if (attPtr->AttrType == aset->AttrId [oall])
      {
        if (attPtr->AttrValidity == BL_VALID_ATTR)
        {
          /*FIXME check that the length is same as the current */
          memcpy (attPtr->AttrValue, &aset->AttrVal [oall], attPtr->AttrLength);
          //memcpy ((AttrBuff1 + mlen + sizeof (Attribute)), &aset->AttrVal [oall], 4);
        }
        else
        {
          attPtr2 = (Attribute*) (AttrBuff2 + mlen);
          if (attPtr2->AttrValidity == BL_VALID_ATTR)
          {
            memcpy (attPtr2->AttrValue, &aset->AttrVal [oall], attPtr2->AttrLength);
            //memcpy ((AttrBuff2 + mlen + sizeof (Attribute)), &aset->AttrVal [oall], 4);
          }
          else
          {
            /*FIXME this is actually a bug, both locations cannot be invalid.
             * Right now we are just fixing it and adding a new value.
             */
            attPtr2->AttrValidity = BL_VALID_ATTR;
            memcpy (attPtr2->AttrValue, &aset->AttrVal [oall], attPtr2->AttrLength);
            //memcpy ((AttrBuff2 + mlen + sizeof (Attribute)), &aset->AttrVal [oall], 4);
          }
        }
        acnt = NumAttr; /* Get out of the inner FOR LOOP*/
      }
      /*Move to the begining to next attribute*/
      mlen += sizeof (Attribute) + 4; //attPtr->AttrLength;
    }
  }
  
  /**
   * Write the frist table back with all the modification
   */
  if (Flash_Erase (BaseAddress) == FAIL)
  {
    return FAIL;
  }
  if (Flash_Write (BaseAddress, AttrBuff1, TblSize) == FAIL)
  {
    return FAIL; /*FIXME Bad. Load the default attr back*/
  }

  /**
   * Write the second table back with all the modification
   */
  if (Flash_Erase (BaseAddress + BL_TABLE_SIZE) == FAIL)
  {
    return FAIL;
  }
  if (Flash_Write ((BaseAddress + BL_TABLE_SIZE), AttrBuff2, TblSize) == FAIL)
  {
    return FAIL; /*FIXME Bad. Load the default attr back*/
  }
  return SUCCESS;
}


/**
 * Get_Attribute_TableID
 * 
 * Returns a table ID for a particular attribute type. The BLAttrDefines.h
 * file defines the attribute type ranges.
 *
 * @param attr Attribute Type for which the table name is required.
 * @return TABLE ID | 0 on error
 */
ATTR_Address_Table Get_Attribute_TableID (uint16_t attr)
{
  if ((attr < 25) && (attr > 0))
    return BL_ATTR_TYP_ADDRESS_TABLE;
  else if ((attr < 351) && (attr > 49))
    return BL_ATTR_TYP_BOOTLOADER;
  else if ((attr < 800) && (attr > 350))
    return BL_ATTR_TYP_SHARED;
    
  return 0;
}

/**
 * Get_Attribute_Length
 *
 * Get the length of the attribute by passing the attribute type.
 * 
 * @param attr Attribute Type for which to find the Length.
 * @return Length | 0 on error
 */
uint8_t Get_Attribute_Length (uint16_t attr)
{
  ATTR_Address_Table table = Get_Attribute_TableID(attr);
  uint16_t NumItem = 0;
  uint16_t* tblPtr;
  uint16_t i = 0;

  switch (table)
  {
    case BL_ATTR_TYP_ADDRESS_TABLE:
      NumItem = BL_ATTR_ADDRESS_TABLE_NUM*2;
      tblPtr = (uint16_t*) Gen_ATTR_Addr_Table[0];
    break;
    case BL_ATTR_TYP_DEF_BOOTLOADER:
      NumItem = BL_ATTR_BOOTLOADER_TABLE_NUM*2;
      tblPtr = (uint16_t*) Gen_ATTR_Bootloader_Table[0];
    break;
    case BL_ATTR_TYP_BOOTLOADER:
      NumItem = BL_ATTR_BOOTLOADER_TABLE_NUM*2;
      tblPtr = (uint16_t*) Gen_ATTR_Bootloader_Table[0];
    break;
    case BL_ATTR_TYP_DEF_SHARED:
      NumItem = ATTR_SHARED_TABLE_NUM*2;
      tblPtr = (uint16_t*) Gen_ATTR_Shared_Table[0];
    break;
    case BL_ATTR_TYP_SHARED:
      NumItem = ATTR_SHARED_TABLE_NUM*2;
      tblPtr = (uint16_t*) Gen_ATTR_Shared_Table[0];
    break;
    default:
    return FAIL;
  }

  for (i = 0;i < NumItem; i+=2)
  {
    if (tblPtr [i] == attr)
      return tblPtr [i+1];
  }

  return FAIL;
}

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
uint32_t Get_Attr_Flash_Address (ATTR_Address_Table TblID, uint16_t AttrID)
{
  uint32_t Addr = 0;
  uint8_t Length = sizeof (Attribute);
  uint16_t NumItem = 0;
  uint16_t* tblPtr;
  uint16_t i = 0;
  
  switch (TblID)
  {
    case BL_ATTR_TYP_ADDRESS_TABLE:
      Addr = BL_ATTR_ADDRESS_TABLE;
      NumItem = BL_ATTR_ADDRESS_TABLE_NUM * 2;
      tblPtr = (uint16_t*) Gen_ATTR_Addr_Table[0];
    break;
    case BL_ATTR_TYP_DEF_BOOTLOADER:
      Addr = BL_ATTR_DEF_BOOTLOADER;
      NumItem = BL_ATTR_BOOTLOADER_TABLE_NUM * 2;
      tblPtr = (uint16_t*) Gen_ATTR_Bootloader_Table[0];
    break;
    case BL_ATTR_TYP_BOOTLOADER:
      Addr = BL_ATTR_BOOTLOADER;
      NumItem = BL_ATTR_BOOTLOADER_TABLE_NUM * 2;
      tblPtr = (uint16_t*) Gen_ATTR_Bootloader_Table[0];
    break;
    case BL_ATTR_TYP_DEF_SHARED:
      Addr = BL_ATTR_DEF_SHARED;
      NumItem = ATTR_SHARED_TABLE_NUM*2;
      tblPtr = (uint16_t*) Gen_ATTR_Shared_Table[0];
    break;
    case BL_ATTR_TYP_SHARED:
      Addr = BL_ATTR_SHARED;
      NumItem = ATTR_SHARED_TABLE_NUM*2;
      tblPtr = (uint16_t*) Gen_ATTR_Shared_Table[0];
    break;
    default:
    return FAIL;
  }

  for (i = 0;i < NumItem; i+=2)
  {
    if (tblPtr [i] == AttrID)
      return Addr;
    else
      Addr += (Length + tblPtr [i + 1]);
  }
  return FAIL;
}
