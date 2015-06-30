// $Id: PageEEPROMM.nc,v 1.1.1.1 2007/11/05 19:10:34 jpolastre Exp $

/*                                    tab:4
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

/*
 *
 * Author:     Rabin Patra
 * Adapted from pc:EEPROM.nc and mica:PageEEPROMM.nc
 * Date last modified:  11/17/03
 *
 */

/**
 * @author Rabin Patra(rkpatra@cs.berkeley.edu)
 */


includes crc;
includes PageEEPROM;
module PageEEPROMM {
    provides {
        interface StdControl;
        interface PageEEPROM;
    }
}
implementation
{
    enum {
        S_IDLE = 0,
        S_READ = 2,
        S_WRITE = 4,
        S_SYNC =5,
        S_FLUSH = 6,
        S_SYNCALL = 7,
        S_FLUSHALL = 8,
        S_ERASE = 9,
        S_CRC = 10,
        SYNC_DELAY = 40000,
        READ_DELAY = 20000,   // 10 milliseconds (40,000 cycles)
        WRITE_DELAY = 40000,   // 10 milliseconds (40,000 cycles)
        ERASE_DELAY = 60000,
        APPEND_ADDR_START = 16
    };

    char state;
    char *data_buf;
    int data_len;
    int read_page,read_off;
    int write_page,write_off;
    int erase_page;
    int crc_page,crc_off;
     
    uint16_t computeCrc;

    event_t eeprom_event;

    void event_logger_create(event_t* fevent, int mote, long long ftime);
    
    command result_t StdControl.init() {
        state = S_IDLE;
        write_page = 1;//APPEND_ADDR_START;
        write_off = 0;
        event_logger_create(&eeprom_event, tos_state.current_node, 0);
        dbg(DBG_BOOT, "Logger initialized.\n");
        return SUCCESS;
    }
    
    command result_t StdControl.start() {
        state = S_IDLE;
        return SUCCESS;
    }

    command result_t StdControl.stop() {
        return SUCCESS;
    }
    
   
    command result_t PageEEPROM.read(eeprompage_t page, eeprompageoffset_t offset,
                     void *reqdata, eeprompageoffset_t n) {
        if (page >= TOS_EEPROM_MAX_PAGES || offset >= TOS_EEPROM_PAGE_SIZE ||
            n > TOS_EEPROM_PAGE_SIZE || offset + n > TOS_EEPROM_PAGE_SIZE)
            return FAIL;
        if (state != S_IDLE) 
            return  FAIL;
        
        data_buf = reqdata;
        state    = S_READ;
        data_len = n;
        read_page= page;
        read_off = offset;
        dbg(DBG_LOG,"LOGGER:EEPROM read called:page:%d,offser:%d,count:%d\n",
                     page,offset,n);  
        eeprom_event.time = tos_state.tos_time + READ_DELAY;
        queue_insert_event(&(tos_state.queue), &eeprom_event);
        return SUCCESS;
    }

    command result_t PageEEPROM.computeCrc(eeprompage_t page,
                       eeprompageoffset_t offset,
                       eeprompageoffset_t n) {
        if (page >= TOS_EEPROM_MAX_PAGES || offset >= TOS_EEPROM_PAGE_SIZE ||
            n > TOS_EEPROM_PAGE_SIZE || offset + n > TOS_EEPROM_PAGE_SIZE)
            return FAIL;
        if (state != S_IDLE)
            return FAIL;
      
        data_len = n;
        crc_page = page;
        crc_off  = offset;
        state    = S_CRC;
        dbg(DBG_LOG,"LOGGER: EEPROM readcrc called:page:%d,offset:%d,count:%d\n",
                    page,offset,n);  
        eeprom_event.time = tos_state.tos_time + READ_DELAY;
        queue_insert_event(&(tos_state.queue), &eeprom_event);
        return SUCCESS;
    }

    command result_t PageEEPROM.write(eeprompage_t page, eeprompageoffset_t offset,
                      void *reqdata, eeprompageoffset_t n) {
        if (page >= TOS_EEPROM_MAX_PAGES || offset >= TOS_EEPROM_PAGE_SIZE ||
            n > TOS_EEPROM_PAGE_SIZE || (offset + n )> TOS_EEPROM_PAGE_SIZE)
            return FAIL;
        if (state != S_IDLE)
            return FAIL;
        
        data_buf   = reqdata;
        data_len   = n;
        write_page = page;
        write_off  = offset;
        state      = S_WRITE;
        dbg(DBG_LOG,"LOGGER: EEPROM write called:page:%d,offset:%d,count:%d\n",
                     state,page,offset,n);  
        eeprom_event.time = tos_state.tos_time + WRITE_DELAY;
        queue_insert_event(&(tos_state.queue), &eeprom_event);
        return SUCCESS;
    }


    command result_t PageEEPROM.erase(eeprompage_t page, uint8_t eraseKind) {
        if (state != S_IDLE)
            return FAIL;
       
        state = S_ERASE;
        erase_page = page;
        dbg(DBG_LOG,"EEPROM erase called:page:%d\n",page);  
        eeprom_event.time = tos_state.tos_time + ERASE_DELAY;
        queue_insert_event(&(tos_state.queue), &eeprom_event);
        return SUCCESS;
    }

    command result_t PageEEPROM.sync(eeprompage_t page) {
        if (state != S_IDLE)
           return FAIL;
        
        state = S_SYNC;
        eeprom_event.time = tos_state.tos_time + SYNC_DELAY;
        queue_insert_event(&(tos_state.queue), &eeprom_event);
        return SUCCESS;
    }

    command result_t PageEEPROM.flush(eeprompage_t page) {
        if (state != S_IDLE)
           return FAIL;
        state = S_FLUSH;
        eeprom_event.time = tos_state.tos_time + SYNC_DELAY;
        queue_insert_event(&(tos_state.queue), &eeprom_event);
        return SUCCESS;
    }

     command result_t PageEEPROM.syncAll() {
        if (state != S_IDLE)
           return FAIL;
        state = S_SYNCALL;
        eeprom_event.time = tos_state.tos_time + SYNC_DELAY;
        queue_insert_event(&(tos_state.queue), &eeprom_event);
        return SUCCESS;
    }

    command result_t PageEEPROM.flushAll() {
        if (state != S_IDLE)
           return FAIL;
        state = S_FLUSHALL;
        eeprom_event.time = tos_state.tos_time + SYNC_DELAY;
        queue_insert_event(&(tos_state.queue), &eeprom_event);
        return SUCCESS;
    }



    result_t logger_spi_byte_done(unsigned char in) {
        if (state == S_READ) {
            int rval;
            state = S_IDLE;
            rval = readEEPROM(data_buf, tos_state.current_node,
                              read_page * TOS_EEPROM_PAGE_SIZE + read_off, data_len);
            if (rval == 0) {
                int i;
                dbg(DBG_LOG, "LOGGER: Log read of page:%d off:%d bytes:%d completed.\n", 
                read_page,read_off,data_len);
                dbg_clear(DBG_LOG, "\t[");
                for (i = 0; i < data_len; i++) {
                    dbg_clear(DBG_LOG, "%X ",(uint8_t) data_buf[i]);
                }
                dbg_clear(DBG_LOG, "]\n");
            }
            signal PageEEPROM.readDone(SUCCESS);
        }
      
        else if (state == S_WRITE) {
            int rval;
            state = S_IDLE;
            dbg(DBG_LOG, "LOGGER: Log writing of page:%d off:%d bytes:%d completed.\n", 
                write_page,write_off,data_len);
            rval = writeEEPROM(data_buf, tos_state.current_node,
                               write_page * TOS_EEPROM_PAGE_SIZE  + write_off , data_len);
            if (rval == 0) {
                int i;
                dbg_clear(DBG_LOG, "\t[");
                for (i = 0; i < data_len; i++) {
                    dbg_clear(DBG_LOG, "%X ",(uint8_t) data_buf[i]);
                }
                dbg_clear(DBG_LOG, "]\n");
            }
            signal PageEEPROM.writeDone(SUCCESS);
        }
        
        else if(state == S_SYNC || state == S_SYNCALL)
        {
            state = S_IDLE;
            dbg(DBG_LOG,  "LOGGER: SYNC type:%d done\n", state);
            signal PageEEPROM.syncDone(SUCCESS);
        }
        else if(state == S_FLUSH || state == S_FLUSHALL)
        {
            state = S_IDLE;
            dbg(DBG_LOG,  "LOGGER: FLUSH  type:%d done\n", state);
            signal PageEEPROM.flushDone(SUCCESS);
        }
          
        else if(state == S_ERASE)
        {
            state = S_IDLE;
            dbg(DBG_LOG,  "LOGGER: ERASE  erase_page:%d \n", erase_page);
            signal PageEEPROM.eraseDone(SUCCESS);
        }
          
        else if(state == S_CRC)
        {
            int rval;
            char  crc_buf[TOS_EEPROM_PAGE_SIZE];
            int i;
            state = S_IDLE;
            computeCrc = 0;
            if(data_len != 0)
            {
                rval = readEEPROM(crc_buf, tos_state.current_node, 
                                  crc_page * TOS_EEPROM_PAGE_SIZE + crc_off, data_len);
            }
            dbg(DBG_LOG,"LOGGER: CRC  crc_page:%d, off:%d n:%d\n",
                        crc_page,crc_off,data_len);
            dbg_clear(DBG_LOG, "\t[");
            for (i = 0; i < data_len; i++) {
                computeCrc = crcByte(computeCrc,(uint8_t)crc_buf[i]);
                dbg_clear(DBG_LOG, "%X ", (uint8_t) crc_buf[i]);
            }
            dbg_clear(DBG_LOG, "\t]\n");
            dbg(DBG_LOG,"LOGGER: Computed CRC=%X\n",computeCrc);
            signal PageEEPROM.computeCrcDone(SUCCESS,computeCrc);
        }
        else {
            dbg(DBG_LOG | DBG_ERROR, 
                "LOGGER: Operation completed when unknown operation specified!\n");
        }
        return SUCCESS;
    }
    
    void event_logger_handle(event_t* fevent, struct TOS_state* fstate) {
        logger_spi_byte_done(0);
    }
    
    void event_logger_cleanup(event_t* fevent) {
        // Since logger events are statically allocated,
        // we shouldn't deallocate anything; since this function
        // should never be called, we set the fields so they
        // will cause a SEGV if used as is.
        fevent->time = -1;
        fevent->handle = 0;
        fevent->cleanup = 0;
        fevent->mote = 0xffffffff;
        return;
    }
    
    void event_logger_create(event_t* fevent, int mote, long long ftime) {
        fevent->mote = mote;
        fevent->time = ftime;
        fevent->data = NULL;
        fevent->handle = event_logger_handle;
        fevent->cleanup = event_logger_cleanup;
        fevent->pause = 0;
    }
}
  
