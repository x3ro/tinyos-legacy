// $Id: TestFlashFSM.nc,v 1.1 2006/10/10 02:41:16 lnachman Exp $

/*									tab:2
 * "Copyright (c) 2000-2005 The Regents of the University  of California.  
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
 */

/*
 * @author: Jonathan Hui <jwhui@cs.berkeley.edu>
 */

includes trace;
includes PXAFlash;

module TestFlashFSM 
{
  provides 
  {
    interface StdControl;
    interface BluSH_AppI as FSCreate;
    interface BluSH_AppI as FSClean;
    interface BluSH_AppI as NumFiles;
    interface BluSH_AppI as MntFiles;
    interface BluSH_AppI as FSInit;
    interface BluSH_AppI as FWrite;
    interface BluSH_AppI as FErase;
    interface BluSH_AppI as FRead;
    interface BluSH_AppI as FRseek;
    interface BluSH_AppI as FList;
    interface BluSH_AppI as FDel;
    interface BluSH_AppI as FClose;
  }
  uses 
  {
    interface FileStorage as FormatStorage;
    interface Leds;
    interface FileMount as Mount;
    interface FileWrite as BlockWrite;
    interface FileRead as BlockRead;
  }
}

implementation 
{
  uint16_t NextVolumeId = 0x1;
  #define FILE_CONTENT_SIZE 0x1000
  uint8_t FileContent [FILE_CONTENT_SIZE];
  uint8_t CurrFileName [80];
  uint32_t content = 0xDEADBEEF;
  uint8_t fcontent[256] = "Faster, quieter computers. Easy phone calls over the Internet. Mobile processors that use less energy. These are some of the major announcements Intel is making this week at Computex one of the biggest computer trade shows in the world. Here's the lat";

  uint32_t WPtr = 0x0;
  uint32_t RPtr = 0x0;

  command result_t StdControl.init() 
  {
    call Leds.init();
    memset (FileContent, 0, FILE_CONTENT_SIZE);
    return SUCCESS;
  }

  command result_t StdControl.start() 
  {
    return SUCCESS;
  }

  command result_t StdControl.stop() 
  {
    return SUCCESS;
  }

  event void Mount.mountDone(storage_result_t result, volume_id_t id) 
  {
    if ((result == STORAGE_OK))
      trace(DBG_USR1,"Mounted File Successfully\r\n");
    else
      trace(DBG_USR1,"Failed to Mount VolumeId %d\r\n", id);

    return;
  }

  event void BlockWrite.writeDone(storage_result_t result, 
                                  block_addr_t addr, 
                                  void* buf, block_addr_t len)
  {
    if (result == STORAGE_OK)
    {
      trace(DBG_USR1,"Write Successfully, num bytes = %ld, Addres = %ld\r\n", len, addr);
      WPtr += FILE_CONTENT_SIZE;
    }
    else
      trace(DBG_USR1,"WriteDone returned failed \r\n");
    return;
  }

  event void BlockWrite.eraseDone(storage_result_t result)
  {
    if (result == STORAGE_OK)
      trace(DBG_USR1,"EraseDone Completed \r\n");
    return;
  }

  event void BlockWrite.commitDone(storage_result_t result)
  {
    trace(DBG_USR1,"Commit Done.\r\n");
    return;
  }

  event void BlockRead.readDone(storage_result_t result, block_addr_t addr, 
                                void* buf, block_addr_t len)
  {
    uint8_t testCon;
    uint16_t i = 0;
    if (result == STORAGE_OK)
    {
      for (i = 0; i<256; i++)
      {
        testCon = (uint8_t) FileContent[i]; 
        trace(DBG_USR1,"%d ", testCon);
      }
      trace (DBG_USR1, "\r\n");
    }
    return;
  }

  event void BlockRead.verifyDone(storage_result_t result)
  {
    return;
  }

  event void BlockRead.computeCrcDone(storage_result_t result, uint16_t crc, 
                                      block_addr_t addr, block_addr_t len)
  {
    return;
  }

  command BluSH_result_t FRseek.getName(char *buff, uint8_t len)
  {
    const char name[] = "frseek";
    strcpy(buff,name);
    return BLUSH_SUCCESS_DONE;
  }

  command BluSH_result_t FRseek.callApp(char *cmdBuff, uint8_t cmdLen,
                                       char *resBuff, uint8_t resLen)
  {
    uint8_t cargs [2][20];
    uint8_t* arg;
    uint32_t address = 0xFFFFFFFF;

    arg = strtok (cmdBuff, " ");
    strcpy (cargs [0], arg);

    if ((arg = strtok (NULL, " ")) != NULL)
    {
      strcpy (cargs [1], arg);
      address = atoi(cargs[1]);
    }

    if (address != 0xFFFFFFFF)
    {
      if (call BlockRead.rseek(address) == FAIL)
        trace(DBG_USR1,"Seek Failed\r\n");
      else
        trace(DBG_USR1,"Seek Succeeded. Read Ptr = %ld\r\n", call FormatStorage.getReadPtr (CurrFileName));
    }
    else
      trace(DBG_USR1,"Usage: frseek 150 or address to seek\r\n");

    return BLUSH_SUCCESS_DONE;
  }

  command BluSH_result_t FRead.getName(char *buff, uint8_t len)
  {
    const char name[] = "fread";
    strcpy(buff,name);
    return BLUSH_SUCCESS_DONE;
  }

  command BluSH_result_t FRead.callApp(char *cmdBuff, uint8_t cmdLen,
                                       char *resBuff, uint8_t resLen)
  {
    memset (FileContent, 0x0, 0x1000);
    if (call BlockRead.fread (FileContent, 256) == FAIL)
      trace(DBG_USR1,"Read Request Failed\r\n");
    else
    {
      trace(DBG_USR1,"Read Succeeded. Read Ptr = %ld\r\n", call FormatStorage.getReadPtr (CurrFileName));
    }

    return BLUSH_SUCCESS_DONE;
  }

  command BluSH_result_t FList.getName(char *buff, uint8_t len)
  {
    const char name[] = "flist";
    strcpy(buff,name);
    return BLUSH_SUCCESS_DONE;
  }

  command BluSH_result_t FList.callApp(char *cmdBuff, uint8_t cmdLen,
                                        char *resBuff, uint8_t resLen)
  {
    uint16_t numfiles = 0x0;
    char* fmdata;
    uint16_t i = 0x0;
    numfiles = call FormatStorage.getFileCount();
    for (i=0; i<numfiles; i++)
    {
      fmdata = call FormatStorage.getFileName (i);
      trace(DBG_USR1,"FileName %s\r\n",fmdata);
      if (call FormatStorage.isFileMounted(fmdata) == TRUE)
        trace(DBG_USR1,"%s is mounted.\r\n",fmdata);
      else
        trace(DBG_USR1,"%s is not mounted.\r\n",fmdata);
    }
    return BLUSH_SUCCESS_DONE;
  }

  command BluSH_result_t FErase.getName(char *buff, uint8_t len)
  {
    const char name[] = "ferase";
    strcpy(buff,name);
    return BLUSH_SUCCESS_DONE;
  }

  command BluSH_result_t FErase.callApp(char *cmdBuff, uint8_t cmdLen,
                                        char *resBuff, uint8_t resLen)
  {
    if (call BlockWrite.erase () == FAIL)
      trace(DBG_USR1,"Erase Request Failed\r\n");
    else
      trace(DBG_USR1,"Erase Request Succeded\r\n");
    return BLUSH_SUCCESS_DONE;
  }

  command BluSH_result_t FWrite.getName(char *buff, uint8_t len)
  {
    const char name[] = "fwrite";
    strcpy(buff,name);
    return BLUSH_SUCCESS_DONE;
  }

  command BluSH_result_t FWrite.callApp(char *cmdBuff, uint8_t cmdLen,
                                        char *resBuff, uint8_t resLen)
  {
    uint16_t i = 0;
    for (i = 0; i < (0x1000); i+=256)
      memcpy ((FileContent + i), fcontent, 256);

    //for (i = 0; i < (0x1000); i+=4)
    //  memcpy ((FileContent + i), &content, 4);

#if 1
    if (call BlockWrite.append (FileContent, 0x1000) == FAIL)
      trace(DBG_USR1,"Append Request Failed\r\n");
    else
      trace(DBG_USR1,"Append Request Succeded\r\n");
#endif

#if 0
    WPtr = call FormatStorage.getWritePtr (CurrFileName);
    if (WPtr == INVALID_PTR)
    {
      trace(DBG_USR1,"Invalid Write Pointer %ld %s\r\n",WPtr, CurrFileName);
      return BLUSH_SUCCESS_DONE;
    }
    if (call BlockWrite.write (WPtr, FileContent, 0x1000) == FAIL)
      trace(DBG_USR1,"Write Request Failed %ld\r\n",WPtr);
    else
      trace(DBG_USR1,"Write Request Succeded %ld\r\n", WPtr);
#endif

    return BLUSH_SUCCESS_DONE;
  }

  command BluSH_result_t FDel.getName(char *buff, uint8_t len)
  {
    const char name[] = "fdel";
    strcpy(buff,name);
    return BLUSH_SUCCESS_DONE;
  }

  command BluSH_result_t FDel.callApp(char *cmdBuff, uint8_t cmdLen,
                                        char *resBuff, uint8_t resLen)
  {
    uint8_t cargs [2][20];
    uint8_t* arg;

    arg = strtok (cmdBuff, " ");
    strcpy (cargs [0], arg);

    if ((arg = strtok (NULL, " ")) != NULL)
      strcpy (cargs [1], arg);
    else
      strcpy (cargs [1], "test1");

    if (call FormatStorage.fdelete(cargs[1]) == SUCCESS)
    {
      trace(DBG_USR1,"Successfully Deleted %s\r\n", cargs[1]);
    }
    else
      trace(DBG_USR1,"Delete Failed %s\r\n", cargs[1]);
    
    return BLUSH_SUCCESS_DONE;
  }  
  
  command BluSH_result_t NumFiles.getName(char *buff, uint8_t len)
  {
    const char name[] = "fnum";
    strcpy(buff,name);
    return BLUSH_SUCCESS_DONE;
  }

  command BluSH_result_t NumFiles.callApp(char *cmdBuff, uint8_t cmdLen,
                                        char *resBuff, uint8_t resLen)
  {
    uint16_t TotalFiles = 0;
    TotalFiles = call FormatStorage.getFileCount();
    trace(DBG_USR1,"Number of File in the System %d\r\n", TotalFiles);
    return BLUSH_SUCCESS_DONE;
  }

  command BluSH_result_t MntFiles.getName(char *buff, uint8_t len)
  {
    const char name[] = "mount";
    strcpy(buff,name);
    return BLUSH_SUCCESS_DONE;
  }

  command BluSH_result_t MntFiles.callApp(char *cmdBuff, uint8_t cmdLen,
                                        char *resBuff, uint8_t resLen)
  {
    uint8_t cargs [2][20];
    uint8_t* arg;

    arg = strtok (cmdBuff, " ");
    strcpy (cargs [0], arg);

    if ((arg = strtok (NULL, " ")) != NULL)
    {
      strcpy (cargs [1], arg);
      strcpy (CurrFileName, cargs [1]);
    }
    else
    {
      strcpy (cargs [1], "test1");
      strcpy (CurrFileName, cargs [1]);
    }

    WPtr = 0x0;

    if ((call Mount.fopen(cargs[1])) == FAIL)
      trace(DBG_USR1,"Mounted Failed %s\r\n", cargs[1]);

    return BLUSH_SUCCESS_DONE;
  }

  command BluSH_result_t FSInit.getName(char *buff, uint8_t len)
  {
    const char name[] = "finit";
    strcpy(buff,name);
    return BLUSH_SUCCESS_DONE;
  }

  command BluSH_result_t FSInit.callApp(char *cmdBuff, uint8_t cmdLen,
                                        char *resBuff, uint8_t resLen)
  {
    if (call FormatStorage.init() == SUCCESS)
      trace(DBG_USR1,"Inited File System\r\n");
    else
      trace(DBG_USR1,"InitFile system failed.\r\n");

    return BLUSH_SUCCESS_DONE;
  }

  command BluSH_result_t FClose.getName(char *buff, uint8_t len)
  {
    const char name[] = "fclose";
    strcpy(buff,name);
    return BLUSH_SUCCESS_DONE;
  }

  command BluSH_result_t FClose.callApp(char *cmdBuff, uint8_t cmdLen,
                                        char *resBuff, uint8_t resLen)
  {
    uint8_t cargs [2][20];
    uint8_t* arg;

    arg = strtok (cmdBuff, " ");
    strcpy (cargs [0], arg);

    if ((arg = strtok (NULL, " ")) != NULL)
      strcpy (cargs [1], arg);
    else
      strcpy (cargs [1], "test1");

    if (call Mount.fclose(cargs[1]) == SUCCESS)
      trace(DBG_USR1,"File Closed, Name = %s\r\n", cargs[1]);
    else
      trace(DBG_USR1,"File Close failed.\r\n");

    return BLUSH_SUCCESS_DONE;
  }

  command BluSH_result_t FSCreate.getName(char *buff, uint8_t len)
  {
    const char name[] = "fcreate";
    strcpy(buff,name);
    return BLUSH_SUCCESS_DONE;
  }

  command BluSH_result_t FSCreate.callApp(char *cmdBuff, uint8_t cmdLen,
                                        char *resBuff, uint8_t resLen)
  {
    result_t res = FAIL;
    uint8_t fname [10];
    uint8_t cargs [2][20];
    uint8_t* arg;
    uint32_t filesize = 1;
    arg = strtok (cmdBuff, " ");
    strcpy (cargs [0], arg);

    if ((arg = strtok (NULL, " ")) != NULL)
    {
      strcpy (cargs [1], arg);
      filesize = atoi (cargs[1]);
    }

    NextVolumeId = call FormatStorage.getNextId();
    sprintf (fname,"test%d",NextVolumeId);
    trace(DBG_USR1,"Creating file name %s\r\n", fname);

    if (NextVolumeId > 0x1)
      res = call FormatStorage.fcreate(fname, STORAGE_BLOCK_SIZE*filesize);
    else
    {
      trace(DBG_USR1,"Bad Value for NextId. FS not inited.\r\n");
      return BLUSH_SUCCESS_DONE;
    }

    if (res == FAIL)
      trace(DBG_USR1,"Create failed for file name %s\r\n", fname);

    return BLUSH_SUCCESS_DONE;
  }

  command BluSH_result_t FSClean.getName(char *buff, uint8_t len)
  {
    const char name[] = "fclean";
    strcpy(buff,name);
    return BLUSH_SUCCESS_DONE;
  }

  command BluSH_result_t FSClean.callApp(char *cmdBuff, uint8_t cmdLen,
                                        char *resBuff, uint8_t resLen)
  {
    result_t res = FAIL;
    res = call FormatStorage.cleanAllFiles();
    if (res == SUCCESS)
      trace(DBG_USR1,"All Files Deleted. %s\r\n",cmdBuff);
    else
      trace(DBG_USR1,"Error Deleting Files.\r\n");
    return BLUSH_SUCCESS_DONE;
  }

  event void FormatStorage.commitDone(storage_result_t result) 
  {
    if (result == STORAGE_OK)
      trace(DBG_USR1,"File Created, Volume = %d\r\n", NextVolumeId);
    else  
      trace(DBG_USR1,"Commit Failed.\r\n");
  }
}
