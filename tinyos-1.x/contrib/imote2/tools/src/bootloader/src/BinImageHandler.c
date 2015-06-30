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
 * @file BinImageHandler.c
 * @author Junaith Ahemed Shahabdeen
 *
 * This file serves as a layer above the <I>USB driver</I>. It 
 * receives a the USB Packet and parses the data part to
 * identify a command or binary data. The <B>boot loader state
 * machine</B> is directly controlled by this file based on the
 * current download context or error conditions.
 */
#include <string.h>
#include <stdio.h>
#include <hardware.h>
#include <BinImageHandler.h>
#include <FlashAccess.h>
#include <Leds.h>
#include <BootLoader.h>
#include <stdlib.h>
#include <Crc.h>
#include <AttrAccess.h>
#include <PXA27XClock.h>
#include <TOSSched.h>

/**
 * We are handling the code download in this file for now,
 * may be this has to move to a different location. - js
 */
static uint8_t rcvBuffer [BIN_DATA_WINDOW_SIZE * IMOTE_HID_SHORT_MAXPACKETDATA];
uint16_t NumPckReceived = 0;   /* number of packets received per window*/
uint32_t TotalPckReceived = 0; /* Total number of packets received during download*/ 
uint32_t NumPckExpected = 0;   /* Total Number of packet expected */
uint32_t ImageSize = 0;        /* Total Size of the image being downloaded*/
uint32_t ValidBuffSize = 0;    /* Total Size received for the current buffer*/
uint8_t WindowCount = 0;       /* Number of chunks received currently*/
bool SelfTestImage = FALSE;    /* Identifies if we are loading a self test image*/

uint32_t NumCrcRetries = 0;     /* Number of CRC Retries from attributes*/
uint8_t CrcRetries = 0;         /* Number of CRC Retries*/
uint32_t CmdRetries = 0;        /* Number of CRC Retries*/
uint32_t CmdTimeOut = 0;        /* Timeout Value for commands*/
uint32_t BinTimeOut = 0;        /* Timeout value for binary data*/

/* Variables used for flash dump */
uint8_t DmpWindowCount = 0; /* Number of chunks sent to the PC application*/
uint32_t TotalPckSent = 0;  /* Total number of packets uploaded during dump*/ 

uint32_t CurrLoadAddr = 0;
bool FlashDumpMode = FALSE;

uint16_t dbg_curr_crc = 0;
uint16_t dbg_rcv_crc = 0;

TimeoutDetail toutdetail;

/**
 * Binary_Image_Packet_Received
 *
 * The function is a signal from the USB Driver when a binary 
 * data packet is received. The function stores the binary data in 
 * the RAM Buffer till the BIN_DATA_WINDOW_SIZE is reached. If the 
 * sequence number matches with the windown size then the function 
 * changes the <B>boot loader internal state</B> to <B>VERIFY_CURRENT_BUFFER</B>.
 * The state change indicates that the current buffer is completely
 * downloaded and the next command from the PC app (CRC Check) can 
 * be executed on the RAM Buffer.
 * 
 * @param data Buffer with binary data.
 * @param length Length of the valid part of buffer.
 * @param seq Sequence number of the packet.
 */
void Binary_Image_Packet_Received (uint8_t* data, uint8_t length, uint32_t seq)
{
  memcpy (rcvBuffer + (NumPckReceived * IMOTE_HID_SHORT_MAXPACKETDATA), data, length);
  ++ NumPckReceived;
  ValidBuffSize += length;

#ifdef MMU_ENABLE  
  ++ TotalPckReceived;
  if (TotalPckReceived >= NumPckExpected)
  {
    Check_Timeout_Disable (1, 0);
    Change_Internal_CodeLoad_State (VERIFY_CURRENT_BUFFER);
  }
  else
  {
    if (NumPckReceived >= (BIN_DATA_WINDOW_SIZE))
    {
      Check_Timeout_Disable (1, 0);
      Change_Internal_CodeLoad_State (VERIFY_CURRENT_BUFFER);
    }
  }
  //Check_Timeout_Disable (1, 0);
#else
  ++ TotalPckReceived;
  if (TotalPckReceived >= NumPckExpected)
    Change_Internal_CodeLoad_State (VERIFY_CURRENT_BUFFER);
  else
  {
    if (NumPckReceived < (BIN_DATA_WINDOW_SIZE))
      BootLoader_State_Machine ();
    else
      Change_Internal_CodeLoad_State (VERIFY_CURRENT_BUFFER);
  }
#endif
}

/**
 * Check_Buffer_Crc 
 *
 * Check the CRC of the current RAM buffer and return the
 * result.
 * 
 * @param start  Current Start packet.
 * @param numpck number of packets downloaded in to the current buffer.
 * @param crc    CRC of the current buffer.
 *
 * @return SUCCESS| FAIL
 */
result_t Check_Buffer_Crc (uint32_t start, uint32_t numpck, uint16_t crc)
{
  uint16_t CurrentCRC = 0;
  CurrentCRC = Crc_Buffer (rcvBuffer, 
                    ValidBuffSize,
                    CurrentCRC);
  dbg_curr_crc = CurrentCRC;
  if (CurrentCRC == crc)
    return SUCCESS;
  else
    return FAIL;
  return FAIL;
}


/**
 * Request_Next_Binary_Chunk
 *
 * The function requests the next binary chunk of size 
 * <I>BIN_DATA_WINDOW_SIZE</I> from the PC app. This function is 
 * invoked from the boot loader state machine when the current state 
 * is <I>REQUEST_USB_PACKETS</I>.
 * It also sets the time out value for the buffer download.
 *
 * @return SUCCESS | FAIL
 */
result_t Request_Next_Binary_Chunk ()
{
  uint8_t buff [62];
  USBCommand* cmd;
  CmdReqBinData req;

  int len = sizeof (USBCommand) + sizeof (CmdReqBinData);
  cmd = (USBCommand*) buff;
  cmd->type = CMD_REQUEST_BIN_DATA;
  req.PckStart = (WindowCount * BIN_DATA_WINDOW_SIZE);
  /* The case where we wont need the full window (we dont have enough packets)*/
  if ((NumPckExpected - TotalPckReceived) < BIN_DATA_WINDOW_SIZE)
    req.NumUSBPck = (NumPckExpected - TotalPckReceived);
  else
    req.NumUSBPck = (BIN_DATA_WINDOW_SIZE);
  req.ChunkSize = TotalPckReceived;
  Prepare_Buffer_Download (TotalPckReceived, NumPckExpected);
  memcpy (cmd->data, &req, sizeof (CmdReqBinData));
  Send_Command_Packet (cmd, len);

  toutdetail.TimeoutMS = BinTimeOut;
  toutdetail.MsgId = 1; /*Indicates Binary Packet*/
  toutdetail.Type = CMD_REQUEST_BIN_DATA;
  toutdetail.ExpectedType = 0; /*No specific type*/
  toutdetail.NumRetries = CmdRetries;
  toutdetail.NotifyFunc = &Command_Timeout;
  Enable_Timeout (&toutdetail);
  return SUCCESS;
}


/**
 * Request_Next_Binary_Packet
 *
 * While in the MMU Disabled mode it is impossible to receive chunks
 * of data from the PC app, because the processing is not fast enough to
 * keep up with the data rate. It is easier to switch to request
 * each packet.
 *
 * @return SUCCESS | FAIL
 * 
 */
result_t Request_Next_Binary_Packet ()
{
  CmdReqBinData req;
  int len = sizeof (CmdReqBinData);

  /* We want the seq number to start from 1*/
  req.PckStart = (NumPckReceived + 1);/* Seq number will be the same as this*/
  req.NumUSBPck = 1;                  /* We are requesting one at a time */
  req.ChunkSize = TotalPckReceived;   /* For diag purposes */

  Send_USB_Command_Packet (CMD_REQUEST_BIN_PCK, len, &req);
  return SUCCESS;
}

/**
 * Command_Timeout
 * 
 * The function is a signal from the timer module to indicate
 * that timeout value has reached for a particular operation.
 * The action required for the signal is determined by the
 * message type and the number of retires.
 * 
 * NOTE:
 *   If the number of retries expired then it usually indicates
 * a fatal comminucation error in the current code, the board 
 * will send a fata error message and will reboot.
 *
 * @param MsgId Message Type (command, or binary etc)
 * @parma Typ Type of command or any other message.
 * @param retries Number of retries left. (usually reducing).
 *
 */
void Command_Timeout (uint8_t MsgId, uint8_t Typ, uint8_t retries)
{
  bool SendErr = FALSE;
  uint8_t buff [61];

  switch (Typ)
  {
    case CMD_GET_IMAGE_DETAILS:
      if (retries)
      {
        Change_BootLoader_State (CODE_LOAD);
        TOS_post (&BootLoader_State_Machine);
      }
      else
      {
        sprintf (buff, "No Image Details. Aborting.");
        SendErr = TRUE;
      }
    break;
    case CMD_REQUEST_BIN_DATA:
      if (retries)
      {
        if (Get_BootLoader_State () == CODE_LOAD)
          Change_Internal_CodeLoad_State (REQUEST_USB_PACKETS);
        TOS_post (&BootLoader_State_Machine);
      }
      else
      {
        sprintf (buff, "Did not receive binary data. Aborting");
        SendErr = TRUE;
      }
    break;
    default:
      TOGGLE_LED (RED);
    break;
  }

  /**
   * Right now we are only sending a fatal errors but not all
   * failures are fatal, FIXME needs to handle the errors
   */
  if (SendErr)
  {
    Send_USB_Error_Packet (ERR_FATAL_ERROR_ABORT, sizeof buff, buff);
    Reboot_Device ();
  }

  return;
}

/**
 * Command_Packet_Received
 * 
 * Signal from the USB Driver when a command packet is received.
 * The payload is parsed to identify the command type and based
 * on the command type the rest of the data is handled.
 * The commands and the data structure for each command is
 * defined in <B>MessageDefines.h</B>.
 *
 * @param data Data Payload of the USB Packet.
 * @param length Length of the payload.
 *
 * @return SUCCESS | FAIL
 */
result_t Command_Packet_Received (uint8_t* data, uint8_t length)
{
  USBCommand* cmd = (USBCommand*) data;
  Check_Timeout_Disable (0, cmd->type);
  switch (cmd->type)
  {
    case RSP_REBOOT:
      OSMR3 = OSCR0 + 9000;
      OWER = 1;
      while(1);
    break;
    case RSP_USB_CODE_LOAD:
    {
      result_t ret = FAIL;
      if (cmd->data [0] == SELFTEST)
      {
        ret = Read_Attribute_Value (BL_ATTR_TYP_DEF_SELF_TEST_IMG_LOC,
                                    (void*)&CurrLoadAddr);
	SelfTestImage = TRUE;
      }
      else if (cmd->data [0] == APPLICATION)
      {
        ret = Read_Attribute_Value (BL_ATTR_TYP_SECONDARY_IMG_LOCATION,
                                    (void*)&CurrLoadAddr);
      }

      if (ret == SUCCESS)
      {
        if (Read_Attribute_Value (BL_ATTR_TYP_CMD_FAIL_RETRY,
                                     &CmdRetries) == FAIL)
          CmdRetries = 3; /* Dont make a big deal, just do it thrice*/
        if (Read_Attribute_Value (BL_ATTR_TYP_CRC_FAIL_RETRY,
                                     (void*)&NumCrcRetries) == FAIL)
          NumCrcRetries = 3; /* Dont make a big deal, just do it thrice*/
        if (Read_Attribute_Value (BL_ATTR_TYP_CMD_TIMEOUT,
                                     &CmdTimeOut) == FAIL)
          CmdTimeOut = CMD_TIMEOUT_VAL;
        if (Read_Attribute_Value (BL_ATTR_TYP_BIN_TIMEOUT,
                                     &BinTimeOut) == FAIL)
         BinTimeOut = BIN_TIMEOUT_VAL;
	
        toutdetail.TimeoutMS = CmdTimeOut;
        toutdetail.MsgId = 0;
        toutdetail.Type = CMD_GET_IMAGE_DETAILS;
        toutdetail.ExpectedType = RSP_GET_IMAGE_DETAILS;
        toutdetail.NumRetries = CmdRetries;
        toutdetail.NotifyFunc = &Command_Timeout;
        Enable_Timeout (&toutdetail);

        Change_BootLoader_State (CODE_LOAD);
        BootLoader_State_Machine ();
      }
      else
      {
        /*If we cannot read the image location then its impossible to continue*/
        uint8_t errbuff [60];
        Change_BootLoader_State (NORMAL);
        sprintf (errbuff, "Could not read Loading Location Attribute\n");
        Send_USB_Error_Packet (ERR_FATAL_ERROR_ABORT, 60, errbuff);
      }
    }
    break;
    case RSP_GET_IMAGE_DETAILS:
    if ((Get_BootLoader_State () == CODE_LOAD))
    {
      result_t ret = FAIL;
      RspImageDetail imgdetail;
      memcpy (&imgdetail, cmd->data, sizeof (RspImageDetail));
      ImageSize = imgdetail.ImageSize;
      NumPckExpected = imgdetail.NumUSBPck;
      if (SelfTestImage)
        if (ImageSize < 0x40000)
          ret = Write_Attribute_Value (BL_ATTR_TYP_DEF_SELF_TEST_IMG_SIZE,
                                                              ImageSize);
        else
        {
          uint8_t errbuff [60];
          sprintf (errbuff,"Image Size too big for Self Test. Should be less than 256K.");
          Send_USB_Error_Packet (ERR_FATAL_ERROR_ABORT, 60, errbuff);
          Reboot_Device ();
        }	
      else
        ret = Write_Attribute_Value (BL_ATTR_TYP_SECONDARY_IMG_SIZE,
                                                             ImageSize);
      if (ret == SUCCESS)
      {
        if (Get_BootLoader_State () == CODE_LOAD)
          Change_Internal_CodeLoad_State (REQUEST_USB_PACKETS);
        //else
          //FIXME this cannot happen, Send an error.
        BootLoader_State_Machine ();
      }
      else
      {
        uint8_t errbuff [60];
        Change_BootLoader_State (NORMAL);
        sprintf (errbuff, "Could not write ImageSize to Attribute\n");
        Send_USB_Error_Packet (ERR_FATAL_ERROR_ABORT, 60, errbuff);
      }
    }
    else
    {
      uint8_t errbuff [60];
      Change_BootLoader_State (NORMAL);
      sprintf (errbuff, "Wrong State. Cannot continue upload.\n");
      Send_USB_Error_Packet (ERR_FATAL_ERROR_ABORT, 60, errbuff);
    }
    break;
    case RSP_CRC_CHECK:
      if (Get_Internal_CodeLoad_State() == VERIFY_CURRENT_BUFFER)
      {
        CmdCrcData chkcrc;
        bool Abort = FALSE;
        memcpy (&chkcrc, cmd->data, sizeof(CmdCrcData));
        if (Handle_Cmd_Verify_Buffer_Crc (&chkcrc) == FAIL)
        {
          /* For what ever reason, if we fail we have to get the chunk back*/
          TotalPckReceived = TotalPckReceived - NumPckReceived;
          ++ CrcRetries;
          if (CrcRetries > NumCrcRetries)
            Abort = TRUE;
        }
        NumPckReceived = 0; /* Reset and prepare for next download*/
        ValidBuffSize = 0;
        /**
         * Determine if the download is complete and send appropriate
         * command to the PC.
         */
        if (!Abort)
        {
          if (TotalPckReceived < NumPckExpected)
            Change_Internal_CodeLoad_State (REQUEST_USB_PACKETS);
          else
            Change_Internal_CodeLoad_State (VERIFY_CURRENT_IMAGE);
          BootLoader_State_Machine ();
        }
        else
        {
          uint8_t errbuff [60];
          Change_BootLoader_State (NORMAL);
          sprintf (errbuff, "Too Many Crc Errors. Aborting \n");
          Send_USB_Error_Packet (ERR_FATAL_ERROR_ABORT, 60, errbuff);
        }
      }
      else if (Get_Internal_CodeLoad_State() == VERIFY_CURRENT_IMAGE)
      {
        CmdCrcData chkcrc;
        memcpy (&chkcrc, cmd->data, sizeof(CmdCrcData));
        /* FIXME Change the start address to point to the right attribute*/
        if (Handle_Cmd_Verify_Image_Crc (CurrLoadAddr, 
                 (uint32_t)(ImageSize),
                 chkcrc.ChunkCRC) == SUCCESS)
        {
      	  if (!(SelfTestImage))
          {
            if (Write_Attribute_Value (BL_ATTR_TYP_SECONDARY_IMG_CRC, 
                                           chkcrc.ChunkCRC) == FAIL)
              ; /*FIXME Actually This is serious, Incase if we crash we cant recover*/
            Set_Image_Details (ImageSize, CurrLoadAddr, chkcrc.ChunkCRC);
            Change_BootLoader_State_Attribute (CPY_TO_BOOT);
            Send_USB_Command_Packet (CMD_IMG_VERIFY_COMPLETE, 0, NULL);
            TOSH_SET_GREEN_LED_PIN();
            TOSH_SET_YELLOW_LED_PIN();
            TOS_post (&BootLoader_State_Machine);
          }
          else
          {
            if (Write_Attribute_Value (BL_ATTR_TYP_DEF_SELF_TEST_IMG_CRC, 
                                           chkcrc.ChunkCRC) == FAIL)
              ; /*FIXME Actually This is serious, Handle*/
            Reboot_Device ();
	  }
        }
        else
        {
          unsigned char buff [10];
          memset (buff, 0, 10);
          memcpy (buff, &ImageSize, 4);
          memcpy (buff + 4, &chkcrc.ChunkCRC, 2);
          memcpy (buff + 8, &dbg_curr_crc, 2);
          Send_USB_Error_Packet (TEST_CRC_FAILURE, 10, buff);
        }
      }
      else
      {
        uint8_t errbuff [60];
        sprintf (errbuff, "Invalid Buffer.\n");
        Send_USB_Error_Packet (ERR_FATAL_ERROR_ABORT, 60, errbuff);
      }
    break;
    case RSP_GET_ATTRIBUTE:
    {
      uint8_t buffer [62];
      uint16_t tsttyp;
      tsttyp = ((cmd->data [1] & 0xFF) << 8);
      tsttyp |= (cmd->data [0] & 0xFF);
      memset (buffer, 0, 62);
      if (Read_Attribute (tsttyp,
                     buffer) == SUCCESS)
      {
        Send_USB_Command_Packet (CMD_RSP_GET_ATTRIBUTE, 
                               61, buffer);
      }
      else
      {
        Send_USB_Error_Packet (ERR_COMMAND_FAILED, 0, NULL);
      }
    }
    break;
    case RSP_SET_ATTRIBUTE:
    {
      uint16_t tsttyp;
      uint32_t value = 0;
      Attribute attrTyp;
      tsttyp = ((cmd->data [1] & 0xFF) << 8);
      tsttyp |= (cmd->data [0] & 0xFF);
      memcpy (&attrTyp, cmd->data, sizeof (Attribute));
      memcpy (&attrTyp.AttrValue, cmd->data + sizeof (Attribute), attrTyp.AttrLength);
      memcpy (&value, &attrTyp.AttrValue, attrTyp.AttrLength);
      if (Write_Attribute_Value (tsttyp, value) == SUCCESS)
        Send_USB_Command_Packet (CMD_RSP_SET_ATTRIBUTE, 0, NULL); 
      else
        Send_USB_Error_Packet (ERR_COMMAND_FAILED, 0, NULL);
    }
    break;
    case RSP_TEST_GET_BUFFER_DATA:
    {
      uint16_t tstseq = 0;
      tstseq = ((cmd->data [1] & 0xFF) << 8);
      tstseq |= (cmd->data [0] & 0xFF);
      if (FlashDumpMode)
        Handle_Cmd_Get_Buffer_Data (tstseq);
      //else
        /*FIXME send an error*/
    }
    break;
    case RSP_DUMP_FLASH_DATA:
      DmpWindowCount = 0;
      TotalPckSent = 0;
      if (!FlashDumpMode)
        FlashDumpMode = TRUE;
      Handle_Cmd_Flash_Dump ();
    break;
    case RSP_FLASH_MEM_TEST:
      Send_USB_Error_Packet (ERR_COMMAND_FAILED, 0, NULL);    
    break;
    case RSP_SET_BOOTLOADER_STATE:
    {
      uint8_t st = cmd->data [0];
      Change_BootLoader_State (st);
    }
    break;
    default:
      Send_USB_Error_Packet (ERR_COMMAND_FAILED, 0, NULL);    
    break;
  }
  return SUCCESS;
}

/**
 * Handle_Cmd_Verify_Buffer_Crc
 * 
 * The function caluculates the crc of a given buffer
 * and compares it with the crc passed. If the data in
 * the buffer is determined valid through the crc check the
 * buffer data is transfered to the current load location.
 * 
 * @parma chkcrc Data structure contaning number of packets 
 *               and the crc of the current buffer.
 *
 * @return SUCCESS | FAIL
 */
result_t Handle_Cmd_Verify_Buffer_Crc (CmdCrcData* chkcrc)
{
  result_t res = SUCCESS;
  uint32_t BuffSize = (BIN_DATA_WINDOW_SIZE * IMOTE_HID_SHORT_MAXPACKETDATA);
  uint32_t flashaddr = 0;
  uint32_t endaddr = 0;
  flashaddr = CurrLoadAddr + (WindowCount * BuffSize);
  endaddr = flashaddr + BuffSize;
  
  if (Check_Buffer_Crc (0, chkcrc->NumUSBPck, chkcrc->ChunkCRC) == SUCCESS)
  {
    bool EraseFail = FALSE;
    /**
     * Now Write this chunk to the flash and start downloading
     * the next chunk.
     *
     * NOTE: We will have to find out if we have to erase the block.
     * If we are in multipes of 128k then we are good to go. Since we
     * are allowing variable block sizes, we have to check if the
     * data we are writing to can get past the current block.
     */
    if ((flashaddr % FLASH_BLOCK_SIZE) == 0)
    {
      if (Flash_Erase (flashaddr) == FAIL)
      {
        Send_USB_Error_Packet (ERR_FLASH_ERASE, 4, &flashaddr);
        EraseFail = TRUE;
        res = FAIL;
      }
    }
    else if ((endaddr % FLASH_BLOCK_SIZE) < BuffSize)
    {
      if (Flash_Erase (endaddr) == FAIL)
      {
        Send_USB_Error_Packet (ERR_FLASH_ERASE, 4, &flashaddr);
        EraseFail = TRUE;
        res = FAIL;
      }
    }
    

    if (!EraseFail)
    {
      if (Flash_Write (flashaddr, rcvBuffer, 
                       ValidBuffSize)
                       == SUCCESS)
      {
        ++ WindowCount;
      }
      else
      {
        Send_USB_Error_Packet (ERR_FLASH_WRITE, 0, NULL);
        res = FAIL;
      }
    }
    else
    {
      //Send_USB_Error_Packet (ERR_FATAL_ERROR_ABORT, 0, NULL);
      res = FAIL;
    }
  }
  else
  {
    unsigned char buff [10];
    memset (buff, 0, 10);
    memcpy (buff, &chkcrc->chunkStart, 4);
    //memcpy (buff + 4, &tstCrc, 2);	
    memcpy (buff + 4, &chkcrc->ChunkCRC, 2);	
    memcpy (buff + 8, &dbg_curr_crc, 2);
    res = FAIL;
    Send_USB_Error_Packet (TEST_CRC_FAILURE, 10, buff);
  }
  return res;
}

/**
 * Handle_Cmd_Verify_Image_Crc
 *
 * After the download is completed the bootloader verifies
 * the CRC of the image by reading the Image from the
 * flash. The current load location has to be specified
 * to the boot loader through CURRENT_LOAD_LOCATION attribute.
 * This function starts reading chunks of size DATA_WINDOW_SIZE
 * from the address passed as the first parameter from the flash and
 * calculates a cumulative crc of the chunks up to the
 * specified size (numpck number of ).
 *
 * @param StartAddr Starting address of the image.
 * @param Size The total size of the image.
 * @param rcvCRC The crc received or to be verified.
 *
 * @return SUCCESS | FAIL
 */
result_t Handle_Cmd_Verify_Image_Crc (uint32_t StartAddr, uint32_t Size, 
                                                        uint16_t rcvCrc)
{
  uint32_t ImgFlashAddr = StartAddr;
  uint32_t CSize=(uint32_t)(BIN_DATA_WINDOW_SIZE * IMOTE_HID_SHORT_MAXPACKETDATA);
  uint32_t RSize = 0;
  uint32_t CurSize = 0;
  uint16_t cumulative_crc = 0;
  while (CurSize < Size)
  {
    RSize = ((Size - CurSize) > CSize)? CSize : (Size - CurSize);
    memset (rcvBuffer, 0x0, CSize);
    if (Flash_Read (ImgFlashAddr, RSize, rcvBuffer) == FAIL)
    {
      Send_USB_Error_Packet (ERR_FLASH_READ, 0, NULL);
    }
    cumulative_crc = Crc_Buffer (rcvBuffer, RSize, cumulative_crc);
    CurSize += RSize;
    ImgFlashAddr += RSize;
  }
  dbg_curr_crc = cumulative_crc;
  if (cumulative_crc == rcvCrc)
    return SUCCESS;
  return FAIL;
}


/**
 * Handle_Cmd_Get_Buffer_Data
 *
 * This command enables the PC application to request the data from
 * the current internal buffer (rcvBuffer). This command is usally preceded by a
 * DUMP_FLASH_DATA command.
 *
 * @param sequence Sequence number of the packet requested.
 */
void Handle_Cmd_Get_Buffer_Data (uint16_t sequence)
{
  if (Send_USB_Binary_Packet (rcvBuffer + (sequence * IMOTE_HID_SHORT_MAXPACKETDATA), 
             IMOTE_HID_SHORT_MAXPACKETDATA) == SUCCESS)
  {
    ++ TotalPckSent;
    if (TotalPckSent >= NumPckExpected)
    {
      Send_USB_Command_Packet (CMD_TEST_IMG_DUMP, 0, NULL);
      FlashDumpMode = FALSE;
      DmpWindowCount = 0;
      TotalPckSent = 0;
    }
    else
    {
      if (sequence >= (BIN_DATA_WINDOW_SIZE - 1))
      {
        /**
         * If we are in flash dump mode then lets just start the next cycle
         */
        if ((FlashDumpMode) && (TotalPckSent < NumPckExpected))
        {
          ++ DmpWindowCount;
          Handle_Cmd_Flash_Dump ();
        }
      }
    }
  }
}

/**
 * Handle_Cmd_Flash_Dump
 *
 * The verification mechanism of flash programming requires a flash dump of the
 * currently programmed location. The PC application can request a flash
 * dump of either the primary or the secondary flash image. 
 * The function expects the CurrentAddress to be set to the address where
 * the chunk has to be read. The chunk size is same as the download 
 * (BIN_DATA_WINDOW_SIZE).
 * 
 */ 
void Handle_Cmd_Flash_Dump ()
{
  uint32_t CurrentAddress = CurrLoadAddr + 
          (DmpWindowCount * (BIN_DATA_WINDOW_SIZE * IMOTE_HID_SHORT_MAXPACKETDATA));
  memset (rcvBuffer, 0, (BIN_DATA_WINDOW_SIZE * IMOTE_HID_SHORT_MAXPACKETDATA));
  if (Flash_Read (CurrentAddress,
            ((BIN_DATA_WINDOW_SIZE) * IMOTE_HID_SHORT_MAXPACKETDATA),
            rcvBuffer) == FAIL)
  {
    Send_USB_Error_Packet (ERR_FLASH_READ, 0, NULL);
  }
  else
  {
    ++ TotalPckSent;
    Send_USB_Binary_Packet (rcvBuffer, IMOTE_HID_SHORT_MAXPACKETDATA);
  }
}

/**
 * Send_Command_Packet
 *
 * The abstraction function which takes a command and converts it in to
 * byte array and calls the lower level send function in USBClient.
 *
 * @param cmd Command to be send.
 * @param length Size of the struct pointed by cmd.
 *
 * @return SUCCESS | FAIL
 */
result_t Send_Command_Packet (USBCommand* cmd, int length)
{
  uint8_t data [62];
  memcpy (&data, cmd, length);
  USBMsg_Send (data, length, IMOTE_HID_TYPE_MSC_COMMAND);
  return SUCCESS;
}


/**
 * Send_USB_Command_Packet
 *
 * Send a command message to the PC.
 *
 * @param cmd Command type defined in the enum (see MessageDefines.h).
 * @param clen Length of the command data.
 * @param cdata Command data in array format.
 */
result_t Send_USB_Command_Packet (Commands cmd, uint8_t clen, void* cdata)
{
  USBCommand* ucmd;
  result_t ret = FAIL;
  int len = sizeof (USBCommand) + clen;
  uint8_t data [len];
  memset (data, 0, len);
  ucmd = (USBCommand*)data;
  ucmd->type = cmd;
  if (clen > 0)
  {
    memcpy (ucmd->data, cdata, clen);
  }
  ret = USBMsg_Send (data, len, IMOTE_HID_TYPE_MSC_COMMAND);
  
  return ret;
}


/**
 * Send_USB_Error_Packet
 *
 * Send an error message and a description about the error to the
 * PC application.
 *
 * @param err Error codes defined in the enum (see MessageDefines.h).
 * @param dlen Length of the descriptor string.
 * @param desc A description about the error.
 */
result_t Send_USB_Error_Packet (Errors err, uint8_t dlen, void* desc)
{
  result_t ret = SUCCESS;
  USBError* uerr;
  int len = sizeof (USBError) + dlen;
  uint8_t data [len];
  memset (data, 0, len);
  uerr = (USBError*)data;
  uerr->type = err;
  uerr->desclen = dlen;
  if (dlen > 0)
  {
    memcpy (uerr->description, desc, dlen);
  }
  ret = USBMsg_Send (data, len, IMOTE_HID_TYPE_MSC_ERROR);
  return ret;
}


/**
 * Send_USB_Binary_Packet
 *
 * Send Binary data to the pc application. This function is used mainly
 * to dump data from flash or the internal buffer to the pc applicaiton for
 * image verification purposes.
 *
 * The function currently follows the JTPacket format which means that
 * every packet can transmit a length of IMOTE_HID_SHORT_MAXPACKETDATA and
 * packet will contain the sequence number.
 *
 * @param data Data to be transmitted.
 * @return SUCCESS | FAIL
 */
result_t Send_USB_Binary_Packet (uint8_t* data, uint32_t length)
{
  result_t ret = SUCCESS;
  ret = USBMsg_Send (data, length, IMOTE_HID_TYPE_MSC_BINARY);
  return ret;
}
