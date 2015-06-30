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
 * @file BinImageUpload.c
 * @author Junaith Ahemed Shahabdeen
 *
 * Provides the function required to upload code to IMote2.
 */

#include <BinImageUpload.h>
#include <CommandLine.h>
#include <USBDefines.h>
#include <Crc.h>
#include <windows.h>
#include <stdlib.h>
#include <sys/time.h>

/**
 * After the whole image is downloaded the crc of the
 * cumulative crc of the file in chunk size should be
 * sent as a part of verify image.
 *
 * If there are many motes then this step has to be performed
 * on the fly and the PC application has to remember which file
 * was uploaded to the requesting mote.
 */
uint16_t Cumulative_Crc = 0;

/**
 * Buffer Sent to the Mote
 */
uint8_t sendBuffer [BIN_DATA_WINDOW_SIZE * IMOTE_HID_SHORT_MAXPACKETDATA];

/**
 * FIXME Used for flow control
 */
struct timeval  now;            /* time when we started waiting        */
struct timespec timeout;        /* timeout value for the wait function */
int             done;           /* are we done waiting?                */
pthread_cond_t got_req = PTHREAD_COND_INITIALIZER;
pthread_mutex_t req_mutx = PTHREAD_MUTEX_INITIALIZER;


/**
 * Binary_Code_Upload
 *
 * The binary chunk request from the Imote device is
 * handled by this function. The reqest from the
 * device provides the start index and the size
 * of the chunk in of a given file that is being
 * trasfered. The function breaks the buffer in to
 * USB trasferable sizes and passes it to the USBComm
 * module to be trasfered to the IMote.
 *
 * @param startpck Starting index denoted in number of USB Packets.
 * @param numpck Number of packets to be transfered from start index.
 *
 * @return SUCCESS | FAIL 
 */
result_t Binary_Code_Upload (uint32_t startpck, uint32_t numpck)
{
  uint16_t numt = numpck;   // Number of packets to be transfered
  uint16_t numcnt = 1;      // Local counter for keeping track of num pck.
  uint32_t length = IMOTE_HID_SHORT_MAXPACKETDATA; // num bytes per packet.
  uint32_t sindex = startpck * length; // Start index in the binary buffer.
  uint32_t totlength = 0;
  uint8_t data [length];
  //uint16_t buffCrc = 0;
  FILE *f;

  /* create the file of 10 records */
  f=fopen("testdump_org.bin","w");
  //printf ("Request from Mote. Start = %ld, NumPck = %ld \n", startpck, numpck);
  //printf ("Request for Binary Chunk. Number of packets requested = %ld\n", numpck);
  got_req = PTHREAD_COND_INITIALIZER;
  req_mutx = PTHREAD_MUTEX_INITIALIZER;
  int rc = pthread_mutex_lock(&req_mutx);
  if (rc) 
  { /* an error has occurred */
    perror("pthread_mutex_lock");
  }  
  
  while (numcnt <= numt)
  {
    memset (data, 0xFF, IMOTE_HID_SHORT_MAXPACKETDATA);
    if ((length = Get_Bin_Buffer_Data (data, IMOTE_HID_SHORT_MAXPACKETDATA, sindex)) != FAIL)
    {
      Send_Binary_Data (data, length, numcnt);
      /**
       * FIXME this is actually a lot of work. We know that we can only
       * send 62 bytes per packet, but for the crc calculation it is
       * absolutly required that we match with the IMOTE side. So let
       * reform the whole chunk and calculate the CRC in the end.
       */
      memcpy (sendBuffer + totlength, data, length);
      if (f)
        fwrite (sendBuffer + totlength, length, 1, f);
      totlength += length;
      sindex += length;
    }
    else
    {
      fprintf (stderr, "DIDNT GET DATA from Get_Bin_Buffer_Data \n");
      /* lets get out of this while loop */
      numt = numcnt - 1;
      //return FAIL;
      break;
    }
    ++ numcnt;
  }
  fclose (f);
  Cumulative_Crc = Crc_Buffer (sendBuffer, totlength, Cumulative_Crc);

//#ifdef DEBUG
  if (!Is_Test_Program_Mode())
  {
//#endif
    Send_CRC_Command (sendBuffer, totlength, startpck, numpck);
//#ifdef DEBUG
  }
  else
  {
    uint16_t tstbuffCrc = 0;
    tstbuffCrc = Crc_Buffer (sendBuffer, totlength, tstbuffCrc);
    fprintf (stdout, "Send CRC Command now with following parameters; \n");
    fprintf (stdout, "\t start = %ld \n\t num packet = %ld \n\t crc = %d\n",
                         startpck, numpck, tstbuffCrc);
  }
//#endif
  pthread_mutex_unlock(&req_mutx);
  pthread_cond_destroy(&got_req);
  return SUCCESS;
}


/**
 * Send_Binary_Packet
 *
 * When the Mote request for one binary packet during the MMU Disabled mode,
 * this function will send the right data from the file. The chunk size
 * passed as parameter will identify the position in the file from which
 * the data has to be copied.
 * 
 * @param nseq Sequence number (Received from Device and has to be echoed)
 * @param numpck Number of packets requested.
 * @param ftpr The position in the file.
 *
 * @return SUCCESS | FAIL
 */
result_t Send_Binary_Packet (uint32_t nseq, uint32_t numpck, uint32_t fptr)
{
  uint32_t length = IMOTE_HID_SHORT_MAXPACKETDATA; // num bytes per packet.
  uint8_t data [length];
  uint32_t sindex = fptr * length; // Start index in the binary buffer.
  //fprintf (stdout, "Received Binary Packet Request %d - %d\n", nseq, fptr);
  //memset (data, 0xFF, length);
  if ((length = Get_Bin_Buffer_Data (data, length, sindex)) != FAIL)
  {
    Send_Binary_Data (data, length, nseq);
    //Send_Binary_Data (data, IMOTE_HID_SHORT_MAXPACKETDATA, nseq);
    memcpy (sendBuffer + ((nseq - 1) * IMOTE_HID_SHORT_MAXPACKETDATA), data, length);
  }
  else
  {
    fprintf (stderr, "DIDNT GET DATA from Get_Bin_Buffer_Data \n");
    return FAIL;
  }
  
  /* Now we have reached the Buffer Limit. We have to send the CRC to the device*/
  if ((!(nseq % BIN_DATA_WINDOW_SIZE)) || (fptr >= (Get_Num_USB_Packets (0) - 1)))
  {
    Sleep (3);  
    //printf ("Finished uploading the chunk.\n");
    Cumulative_Crc = Crc_Buffer (sendBuffer, (nseq*IMOTE_HID_SHORT_MAXPACKETDATA), Cumulative_Crc);
    Send_CRC_Command (sendBuffer, (nseq*IMOTE_HID_SHORT_MAXPACKETDATA), 0,0);
  }
  return SUCCESS;
}



/**
 * Send_Image_Crc_Command
 *
 * After the whole image is downloaded the crc of the
 * cumulative crc of the file in chunk size should be
 * sent as a part of verify image.
 *
 * @return SUCCESS | FAIL
 */
result_t Send_Image_Crc_Command ()
{
  CmdCrcData crcdata;
  uint16_t cumulative_crc = 0;
  uint32_t length = 0;
  uint32_t sindex = 0;
  uint32_t Size=(uint32_t)(Get_BinFile_Size());
  uint32_t CSize=(uint32_t)(BIN_DATA_WINDOW_SIZE * IMOTE_HID_SHORT_MAXPACKETDATA);
  uint32_t RSize = 0;
  uint32_t CurSize = 0;

  while (CurSize < Size)
  {
    RSize = ((Size - CurSize) > CSize)? CSize : (Size - CurSize);
    memset (sendBuffer, 0x0, CSize);
    if ((length = Get_Bin_Buffer_Data (sendBuffer, RSize, sindex)) != FAIL)
    {
      cumulative_crc = Crc_Buffer (sendBuffer, length, cumulative_crc);
      CurSize += RSize;
      sindex += RSize;
    }
    else
    {
      fprintf (stderr, "Error Receiving File Data \n");
      return FAIL;
    }
  }

  crcdata.chunkStart = 0;
  crcdata.NumUSBPck = Get_Num_USB_Packets (0);
  crcdata.ChunkCRC = cumulative_crc;
  Send_USB_Command_Packet (RSP_CRC_CHECK, sizeof (CmdCrcData), &crcdata);
  printf ("CRC of the Image = %d, Total Size = %ld\n", cumulative_crc, Size);
  Cumulative_Crc = 0;
  return SUCCESS;
}


/**
 * Send_CRC_Command
 *
 * The function calculates the CRC of a buffer of given length
 * and sends the result to the mote over USB.
 *
 * @param buff The buffer for which crc must be computed.
 * @param length Length of the buffer.
 * 
 * @return SUCCESS | FAIL
 */
result_t Send_CRC_Command (uint8_t* buff, uint32_t length, 
		uint32_t startpck, uint32_t numt)
{
  uint16_t tstbuffCrc = 0;
  USBCommand* cmd;
  CmdCrcData* crcdata;
  uint32_t len = sizeof (USBCommand) + sizeof (CmdCrcData);
  cmd = (USBCommand*) malloc (len);
  tstbuffCrc = Crc_Buffer (buff, length, tstbuffCrc);
  if (cmd != NULL)
  {
    cmd->type = RSP_CRC_CHECK;
    crcdata = (CmdCrcData*) cmd->data;
    crcdata->chunkStart = startpck;
    crcdata->NumUSBPck = numt;
    crcdata->ChunkCRC = tstbuffCrc;
    Send_USB_Command (cmd, len);
    printf ("Sending CRC Check command %d\n", tstbuffCrc);
    free (cmd);
  }

  return SUCCESS;
}


/**
 * Send_Test_CRC_Command
 *
 * This function is used in the debug mode to send
 * crc command to the mote. (allows to fake crc)
 *
 * @param startpck 
 * @param numt 
 * @param crc 
 * 
 * @return SUCCESS | FAIL
 */
result_t Send_Test_CRC_Command (uint32_t startpck, uint32_t numt, uint16_t crc)
{
  CmdCrcData crcdata;
  crcdata.chunkStart = startpck;
  crcdata.NumUSBPck = numt;
  crcdata.ChunkCRC = crc;
  printf ("Sending CRC Command.\n");
  Send_USB_Command_Packet (RSP_CRC_CHECK, sizeof (CmdCrcData), &crcdata);

  return SUCCESS;
}
