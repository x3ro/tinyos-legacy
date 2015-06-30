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
 * @file USBMessageHandler.c
 * @author Junaith Ahemed Shahabdeen
 *
 * This file provides a higher level USB Message
 * parser and assembler. The message from the
 * USB driver is identified by its message type
 * and the required modules are invoked based on
 * the type.
 */

#include <USBComm.h>
#include <USBMessageHandler.h>
#include <BinImageFile.h>
#include <BinImageUpload.h>
#include <BLAttrDefines.h>
#include <CommandLine.h>
#include <sys/time.h>

FILE *f = NULL;
uint16_t buffind = 0;
uint32_t fsize = 0;
double percent = 0;

struct timeval upstart, upend;
unsigned long uptelapsed = 0, upsec = 0, upusec = 0;

//#ifdef DEBUG
CmdReqBinData DbgRequest;
//#endif

/**
 * Display_USB_Buffer
 *
 * This function dumps the data to the stdout.
 *
 * @param data Data to be dumped to stdout.
 * @param len Size of data.
 */
void Display_USB_Buffer (uint8_t* data, uint8_t len)
{
  int i = 0;
  for (i = 0; i < len; i++)
  {
    printf ("%d ", data [i]);
  }
  printf ("\n");
}

/**
 * Binary_Packet_Received
 *
 * Binary data received from the mote. Currently the mote sends
 * a binary packet only when the pc requests a flash dump or a
 * buffer dump.
 *
 * @param data Binary data from the mote.
 * @param length Length of the data.
 * @param seq Sequence number from the packet.
 */
result_t Binary_Packet_Received (char* data, uint8_t length, uint32_t seq)
{
  //Display_USB_Buffer (data, 10);
  if (f)
  {
    fwrite(data, length,1,f);
  }
  Get_Buffer_Dump ();
  return SUCCESS;
}

/**
 * Command_Packet_Received
 *
 * The function is signalled when a command packet is received
 * from the device. The function parses the USB payload
 * to determine the command type and calls the required module
 * based on the type.
 * 
 * @param data USB Payload.
 *
 * @return SUCCESS | FAIL
 */
result_t Command_Packet_Received (char* data)
{
  USBCommand* cmd = (USBCommand*) data;
  switch (cmd->type)
  {
    case CMD_BOOT_ANNOUNCE:
      printf ("Recieved boot announce message \n");
    break;
    case CMD_GET_IMAGE_DETAILS:
    {
      gettimeofday (&upstart, NULL);
      fprintf (stdout, "GET_IMAGE_DETAILS Received.\n");
//#if DEBUG
      if (!Is_Test_Program_Mode ())
      {
//#endif     
        USBCommand* cmdsend;
        RspImageDetail* imgdetail;
        uint32_t Length = sizeof(USBCommand) + sizeof(RspImageDetail);
        fsize = Get_BinFile_Size();

        cmdsend = (USBCommand*) malloc(Length);
        if (cmdsend == NULL)
          fprintf (stderr, "Error allocating memeory for command.\n");
        cmdsend->type = RSP_GET_IMAGE_DETAILS;
        imgdetail = (RspImageDetail*) cmdsend->data;
        imgdetail->ImageSize = (uint32_t) Get_BinFile_Size ();

	if (fsize % IMOTE_HID_SHORT_MAXPACKETDATA)
          imgdetail->NumUSBPck = ((uint32_t) (fsize / IMOTE_HID_SHORT_MAXPACKETDATA)) + 1;
	else
          imgdetail->NumUSBPck = (uint32_t) (fsize / IMOTE_HID_SHORT_MAXPACKETDATA);

        Send_USB_Command (cmdsend, Length);
        free (cmdsend);
	fprintf (stdout, "ImgSize=%ld, Num Packets= %ld\n", imgdetail->ImageSize, imgdetail->NumUSBPck);
//#if DEBUG
      }
      else
        fprintf (stdout, "Waiting for user to send 'imagedetail' command\n");
//#endif     
    }
    break;
    case CMD_REQUEST_BIN_DATA:
    {
//#if DEBUG
      if (!Is_Test_Program_Mode ())
      {
//#endif
      uint32_t usize = 0;
      float div = 0;
      unsigned char percentsign [1] = "%";
      CmdReqBinData* req = (CmdReqBinData*) cmd->data;
      usize = (uint32_t) ((req->ChunkSize * IMOTE_HID_SHORT_MAXPACKETDATA) * 100);
      div = (float) (usize / fsize);
      printf ("Total Packets Uploaded = %ld, %.2lf%s completed \n", req->ChunkSize, div, percentsign);
      Binary_Code_Upload (req->PckStart, req->NumUSBPck);
//#if DEBUG
      }
      else
      {
        memcpy (&DbgRequest, cmd->data, sizeof (CmdReqBinData));
        fprintf (stdout, "Waiting for user to send 'sendbindata' command\n");
      }
//#endif
    }
    break;
    case CMD_REQUEST_BIN_PCK:
    {
      CmdReqBinData* req;
      req = (CmdReqBinData*) cmd->data;
      Send_Binary_Packet (req->PckStart, req->NumUSBPck, req->ChunkSize);
    }
    break;
    case CMD_IMG_UPLOAD_COMPLETE:
      fprintf (stdout, "Image Download Completed\n");
      Send_Image_Crc_Command ();
      gettimeofday (&upend, NULL);
      upsec = (upend.tv_sec - upstart.tv_sec);
      upusec = (upend.tv_usec - upstart.tv_usec);
      uptelapsed = (upsec * 1000000) + upusec;
      printf ("Time taken for Upload %ld Milli Seconds\n", (uptelapsed/1000));
    break;
    case CMD_IMG_VERIFY_COMPLETE:
      if (Is_STImage ())
      {
        fprintf (stdout, "Image Verification Completed.\n");
        fprintf (stdout, "Successfully Loaded Self Test Image.\n");
        Exit_Application ();
      }
      else
      {
        fprintf (stdout, "Image Verification Completed.\n");
        fprintf (stdout, "Loading Image to boot location and marking it as golden.\n");
        Binary_Upload_Completed ();
        gettimeofday (&upend, NULL);
        upsec = (upend.tv_sec - upstart.tv_sec);
        upusec = (upend.tv_usec - upstart.tv_usec);
        uptelapsed = (upsec * 1000000) + upusec;
        printf ("Time Elapsed till IMG_VERIFY %ld Milli Seconds\n", (uptelapsed/1000));
      }
    break;
    case CMD_CREATED_GOLDEN_IMG:
    {
      uint8_t buff [61];
      sprintf (buff, cmd->data, 61);
      printf ("%s\n", buff);
      gettimeofday (&upend, NULL);
      upsec = (upend.tv_sec - upstart.tv_sec);
      upusec = (upend.tv_usec - upstart.tv_usec);
      uptelapsed = (upsec * 1000000) + upusec;
      printf ("Overall Time Elapsed %ld Milli Seconds\n", (uptelapsed/1000));
      Exit_Application ();
    }
    break;
    case CMD_BOOTLOADER_MSG:
    {
      uint8_t buff [61];
        gettimeofday (&upend, NULL);
        upsec = (upend.tv_sec - upstart.tv_sec);
        upusec = (upend.tv_usec - upstart.tv_usec);
        uptelapsed = (upsec * 1000000) + upusec;
        printf ("Time Elapsed %ld Milli Seconds\n", (uptelapsed/1000));
      sprintf (buff, cmd->data, 61);
      printf ("%s\n", buff);
    }
    break;
    case CMD_RSP_GET_ATTRIBUTE:
    {
      uint32_t value;
      Attribute* attr;
      attr = (Attribute*)cmd->data;
      memcpy (&value, attr->AttrValue, 4);
      printf ("\nResponse for get attribute: \n");
      //printf ("Attribute Type = %d \n", attr->AttrType);
      //printf ("Attribute Validity = %d \n", attr->AttrValidity);
      printf ("\tAttribute Length = %d \n", attr->AttrLength);
      printf ("\tAttribute Value = %ld \n", value);
      //Display_USB_Buffer (cmd->data, 62);
    }
    break;
    case CMD_RSP_SET_ATTRIBUTE:
      fprintf (stdout, "Set Attribute Successful\n");
    break;
    case CMD_TEST_IMG_DUMP:
      fclose (f);
      fprintf (stderr, "Image download Completed.\n");
    break;
    default:
      printf ("**UNKNOWN** Command Received. Type = %d\n", cmd->type);
      break;
  }
  return 0;
}

/**
 * Error_Packet_Received
 *
 * This function is signalled when an error is received 
 * from the Device. The function parses the USB payload
 * and takes appropriate measures based on the error.
 *
 * @param data  Valid usb data.
 * @return SUCCESS | FAIL
 */
result_t Error_Packet_Received (uint8_t* data)
{
  USBError* err = (USBError*) data;
  switch (err->type)
  {	
    case ERR_FLASH_WRITE:
      printf ("****** ERROR WRITING TO FLASH ****************\n");
      break;
    case ERR_FLASH_READ:
      printf ("****** ERROR READING FROM FLASH ****************\n");
      break;
    case ERR_FLASH_ERASE:
    {
      uint32_t BlockAddress = 0;
      mempcpy (&BlockAddress, err->description, 4);
      printf ("****** ERROR ERASING FLASH BLOCK ****************\n");
      printf ("Address = %ld\n", BlockAddress);
    }
    break;
    case ERR_FATAL_ERROR_ABORT:
    {
      uint8_t buff [61];
      printf ("**** FATAL ERROR ****. \nError from Device: ");
      sprintf (buff, err->description, 61);
      printf (" %s \n", buff);
      //if (Is_STImage ())
        Exit_Application ();
    }
    break;
    case ERR_COMMAND_FAILED:
      printf ("****** COMMAND FAILED ****************\n");
    break;
    case TEST_CRC_FAILURE:
    {
      CmdCrcData* chkcrc;
      chkcrc = (CmdCrcData*) (err->description);
      printf ("***** CRC ERROR Received ****** %ld,%ld,%d\n", 
                chkcrc->chunkStart, chkcrc->NumUSBPck,chkcrc->ChunkCRC);
    }
    break;
    default:
      printf ("**UNKNOWN** Command Received. Type = %d\n", err->type);
      break;
  } 
  return SUCCESS;  
}


//#ifdef DEBUG
/**
 * Dbg_Binary_Code_Upload
 *
 * Function used in the -tp option to send the
 * image detail command to the device.
 *
 * @return SUCCESS | FAIL
 */
result_t Dbg_Binary_Code_Upload ()
{
  Binary_Code_Upload (DbgRequest.PckStart, DbgRequest.NumUSBPck);
  return SUCCESS;
}
//#endif

/**
 * Get_Buffer_Dump
 *
 * The function requests the next packet from the IMote during
 * flash dump mode. The process continues till the window size
 * and is trigerred by the <I>Dump_From_Flash</I> function
 * for the next buffer.
 *
 * @return SUCESS | FAIL
 */
result_t Get_Buffer_Dump ()
{
  if (buffind < BIN_DATA_WINDOW_SIZE)
  {
    uint8_t buff [61];
    USBCommand* cmd = (USBCommand*)buff;
    USBImagePck* imgpck = (USBImagePck*) cmd->data; 
    cmd->type = RSP_TEST_GET_BUFFER_DATA;
    imgpck->seq = buffind;
    ++ buffind;
    Send_USB_Command (cmd, sizeof(USBCommand) + sizeof(USBImagePck));
  }
  else
  {
    printf ("Number of pck received = %d\n", buffind);
    buffind = 0;
  }
  return SUCCESS;
}

/**
 * Dump_From_Flash
 *
 * Request a data chunk from the flash, the length of the
 * chunk and the flash address is passed as parameter to
 * the function. This function basically triggers a request
 * response cycle between the MOTE and the PC Application till
 * the entire chunk is downloaded.
 *
 * @param addr Start address of the chunk in flash.
 * @param length The size of the chunk.
 *
 * @return SUCCESS | FAIL
 */
result_t Dump_From_Flash (uint32_t addr, uint32_t length)
{
  uint8_t buff [61];
  USBCommand* cmd = (USBCommand*)buff;
  cmd->type = RSP_DUMP_FLASH_DATA;
  if (!f)
    f=fopen("testdump.bin","a");
  if (Send_USB_Command (cmd, (sizeof(USBCommand) + 1)) == SUCCESS)
  {
    ++ buffind;
    return SUCCESS;
  }
  return FAIL;
}


/**
 * Send_USB_Command_Packet
 *
 * Send a command message to the Mote.
 *
 * @param cmd Command type defined in the enum (see MessageDefines.h).
 * @param clen Length of the command data.
 * @param cdata Command data in array format.
 *
 * @return SUCCESS | FAIL
 */
result_t Send_USB_Command_Packet (Commands cmd, uint8_t clen, void* cdata)
{
  unsigned char OutputReport [Get_OutputReportByteLength()];
  USBCommand* ucmd;
  uint32_t length = sizeof (USBCommand) + clen;
  OutputReport[0]=0;

  /**
   * Reboot need not be a seperate type, but inorder for the
   * applicaiton to parse it easily, we are adding it as a
   * seperate command.
   */
  if (cmd == RSP_REBOOT)
  {
    OutputReport[IMOTE_HID_TYPE] = 
          ((IMOTE_HID_TYPE_MSC_COMMAND << IMOTE_HID_TYPE_MSC) & 0xE3) | 
          _BIT(IMOTE_HID_TYPE_H) | (IMOTE_HID_TYPE_L_BYTE << IMOTE_HID_TYPE_L);
  }
  else
  {
    OutputReport[IMOTE_HID_TYPE] = 
          ((IMOTE_HID_TYPE_MSC_COMMAND << IMOTE_HID_TYPE_MSC) & 0xE3) | 
          _BIT(IMOTE_HID_TYPE_H) | (IMOTE_HID_TYPE_L_BYTE << IMOTE_HID_TYPE_L);
  }
  OutputReport[IMOTE_HID_NI] = 0x01;

  ucmd = (USBCommand*)(OutputReport + 3);
  ucmd->type = cmd;
  if (clen > 0)
    memcpy (ucmd->data, cdata, clen);
  Write_Output_Report (OutputReport, length + 3);
  return SUCCESS;
}

/**
 * Send_USB_Command
 *
 * Send a command message to the Mote.
 *
 * @param cmd Command struct with appropriate data defined in MessageDefines.h.
 * @param length Length of the command data.
 *
 * @return SUCCESS | FAIL
 */
result_t Send_USB_Command (USBCommand* cmd, uint32_t length)
{
  unsigned char OutputReport [Get_OutputReportByteLength()];
  OutputReport[0]=0;
  if (cmd->type == RSP_REBOOT)
  {
    OutputReport[IMOTE_HID_TYPE] = 
          ((IMOTE_HID_TYPE_MSC_REBOOT << IMOTE_HID_TYPE_MSC) & 0xE3) | 
          _BIT(IMOTE_HID_TYPE_H) | (IMOTE_HID_TYPE_L_BYTE << IMOTE_HID_TYPE_L);
  }
  else
  {  
    OutputReport[IMOTE_HID_TYPE] = 
          ((IMOTE_HID_TYPE_MSC_COMMAND << IMOTE_HID_TYPE_MSC) & 0xE3) | 
          _BIT(IMOTE_HID_TYPE_H) | (IMOTE_HID_TYPE_L_BYTE << IMOTE_HID_TYPE_L);
  }
  OutputReport[IMOTE_HID_NI] = 0x01;
  memcpy ((OutputReport + 3), cmd, length);
  Write_Output_Report (OutputReport, length + 3);
  return SUCCESS;
}

/**
 * Send_Binary_Data
 *
 * Send a binary buffer to the device. Usually binary data is prepended
 * with the sequence number of the packet the final packet will
 * have a sequence number of 0. JT Protocol requires a header with the
 * valid bytes in the packet if the seqence number is 0, this allows
 * the pc host to send less than IMOTE_HID_TYPE_L_SHORT in the last
 * packet if required.
 *
 * @param buff Pointer to the binary buffer.
 * @param length Length of the buffer.
 * @param seq Current Sequence number of the buffer.
 *
 * @return SUCCESS | FAIL
 */
result_t Send_Binary_Data (uint8_t* buff, uint32_t length, uint16_t seq)
{
  unsigned char OutputReport [65];
  OutputReport[0]=0;
  OutputReport[IMOTE_HID_TYPE] = 
       ((IMOTE_HID_TYPE_MSC_BINARY << IMOTE_HID_TYPE_MSC) & 0xE3) | 
       _BIT(IMOTE_HID_TYPE_H) | (IMOTE_HID_TYPE_L_SHORT << IMOTE_HID_TYPE_L);
  /**
   * NOTE:
   *    Following Josh's protocol in which the last packet can
   *    specify the valid bytes
   */
  if (length < IMOTE_HID_SHORT_MAXPACKETDATA)
  {
    OutputReport[IMOTE_HID_NI] = 0;
    OutputReport[IMOTE_HID_NI + 1] = 0;
    OutputReport[IMOTE_HID_NI + 2] = length; /* Specifies how many bytes are valid*/
    memcpy (OutputReport + 5, buff, length);
    Write_Output_Report (OutputReport, length + 5);
  }
  else
  {
    OutputReport[IMOTE_HID_NI] = ((seq >> 8) & 0xFF);
    OutputReport[IMOTE_HID_NI + 1] = seq & 0xFF;
    memcpy (OutputReport + 4, buff, length);
    Write_Output_Report (OutputReport, length + 4);
  }
  return SUCCESS;
}

/**
 * Send_USB_Binary_Data
 *
 * The function allows the user to send binary data packed in
 * a structure.
 *
 * @param img The struct which contains binary data.
 * @param length length of the struct with data.
 * 
 * @return SUCCESS | FAIL
 */
result_t Send_USB_Binary_Data (USBImagePck* img, uint32_t length)
{
  unsigned char OutputReport [Get_OutputReportByteLength()];
  OutputReport[0]=0;
  OutputReport[IMOTE_HID_TYPE] = 
       ((IMOTE_HID_TYPE_MSC_BINARY << IMOTE_HID_TYPE_MSC) & 0xE3) | 
       _BIT(IMOTE_HID_TYPE_H) | (IMOTE_HID_TYPE_L_SHORT << IMOTE_HID_TYPE_L);
  OutputReport[IMOTE_HID_NI] = 0x01;
  memcpy ((OutputReport + 3), img, length);
  Write_Output_Report (OutputReport, length + 3);
  return SUCCESS;
}
