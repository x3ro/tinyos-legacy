
includes common_header;

//#define FLASH_DEBUG

module FlashM {
    provides interface GenericFlash[uint8_t id];

    uses {
        interface PageEEPROM;
        interface Leds;
#ifdef FLASH_DEBUG
        interface Console;
#endif
    }
}

implementation 
{
    pageptr_t Tpage;
    result_t r;
    uint8_t Tid;
    bool busy;

    /*********************************************
	************** Lock / Unlock ****************
	*********************************************/
	result_t lock()
	{
		bool localBusy;

		atomic 
		{
			localBusy = busy;
			busy = TRUE;
		}
        
		if (!localBusy)
		{
			return (SUCCESS);
		}
		else
		{
			return (FAIL);
		}
	}

	void unlock()
	{
		busy = FALSE;
	}


    task void initDone()
    {
        signal GenericFlash.initDone[Tid](SUCCESS);
    }

    command result_t GenericFlash.init[uint8_t id]()
    {
        post initDone();
        Tid = id;

        return(SUCCESS);
    }

    command pageptr_t GenericFlash.numPages[uint8_t id]()
    {
        return(2048);
    }
    
    command result_t GenericFlash.write[uint8_t id](pageptr_t page, offsetptr_t offset,
                                        void *data, datalen_t len)
    {
        if (lock() != SUCCESS)
        {
#ifdef FLASH_DEBUG
            call Console.string("ERROR ! Unable to acquire Flash-write lock if:");
            call Console.decimal(id);
            call Console.string("\n");
            TOSH_uwait(40000L);
#endif
            return (FAIL);
        }
#ifdef FLASH_DEBUG
        call Console.string("Acquired Flash-write lock if:");
        call Console.decimal(id);
        call Console.string("\n");
        TOSH_uwait(40000L);
#endif

        Tpage = page;
        Tid = id;
        if (SUCCESS != call PageEEPROM.write(page, offset, data, len))
        {
            unlock();
#ifdef FLASH_DEBUG
            call Console.string("PageEEPROM write call failed\n");
            TOSH_uwait(40000L);
#endif
            call Leds.redOn();
            return (FAIL);
        }
        else
            return (SUCCESS);
    }

    event result_t PageEEPROM.writeDone(result_t res)
    {
        if (res == SUCCESS)
        {
            if (SUCCESS != call PageEEPROM.flush(Tpage))
            {
                unlock();
#ifdef FLASH_DEBUG
                call Console.string("PageEEPROM flush call failed\n");
                TOSH_uwait(40000L);
#endif

                call Leds.redOn();
                signal GenericFlash.writeDone[Tid](FAIL);
            }
        }
        else
        {
            unlock();

#ifdef FLASH_DEBUG
            call Console.string("PageEEPROM write call returned failure\n");
            TOSH_uwait(40000L);
#endif

            call Leds.redOn();
            signal GenericFlash.writeDone[Tid](FAIL);
        }

        return (SUCCESS);
    }

    event result_t PageEEPROM.flushDone(result_t res)
    {
        unlock();
        signal GenericFlash.writeDone[Tid](res);

        return (SUCCESS);
    }

    enum{FAL_ONE, FAL_TWO, READ};
    uint8_t headerBuf[MAX_HEADERS_LEN];
    bool state;
    datalen_t Tdata_len, Tapp_len;
    offsetptr_t Toffset;
    void *Theader, *Tapp_buff, *Tdata_buff;
    command result_t GenericFlash.falRead[uint8_t id](pageptr_t page, offsetptr_t offset,
                                                      void *header, 
                                                      void *app_buff, datalen_t app_len, 
                                                      void *data_buff)
    {
        if (lock() != SUCCESS)
        {
#ifdef FLASH_DEBUG
            call Console.string("ERROR ! Unable to acquire Flash-falread lock if:");
            call Console.decimal(id);
            call Console.string("\n");
            TOSH_uwait(40000L);
#endif
            return (FAIL);
        }
#ifdef FLASH_DEBUG
        call Console.string("Acquired Flash-falread lock if:");
        call Console.decimal(id);
        call Console.string("\n");
        TOSH_uwait(40000L);
#endif

        if (sizeof(headerBuf) < (sizeof(chunk_header) + app_len))
        {
#ifdef FLASH_DEBUG
            call Console.string("ERROR - Size of header larger than MAX_HEADERS_LEN -- redefine it\n");
            TOSH_uwait(40000L);
#endif
            return (FAIL);
        }

        state = FAL_ONE;
        Theader = header; Tapp_buff = app_buff; Tdata_buff = data_buff;
        Tapp_len = app_len; Tpage = page; Toffset = offset;
        Tid = id;

#ifdef FLASH_DEBUG
        call Console.string("Read pg:");
        call Console.decimal(page);
        call Console.string(" off:");
        call Console.decimal(offset);
        TOSH_uwait(40000L);
        call Console.string(" len:");
        call Console.decimal(sizeof(chunk_header) + app_len);
        call Console.string("\n");
        TOSH_uwait(40000L);
#endif

        if (SUCCESS != call PageEEPROM.read(page, offset, headerBuf, 
                                            sizeof(chunk_header) + app_len))
        {
            unlock();
#ifdef FLASH_DEBUG
            call Console.string("PageEEPROM read call failed\n");
            TOSH_uwait(40000L);
#endif
            call Leds.redOn();
            return (FAIL);
        }
        else
            return (SUCCESS);
    }

    task void readData()
    {
#ifdef FLASH_DEBUG
        call Console.string("Read pg:");
        call Console.decimal(Tpage);
        call Console.string(" off:");
        call Console.decimal(Toffset + sizeof(chunk_header) + Tapp_len);
        TOSH_uwait(40000L);
        call Console.string(" len:");
        call Console.decimal(Tdata_len);
        call Console.string("\n");
        TOSH_uwait(40000L);
#endif

        /* Check if data is larger than page size */
        if (PAGE_SIZE < Tdata_len)
        {
            unlock();

#ifdef FLASH_DEBUG
            call Console.string("ERROR - Data larger than page size - ");
            call Console.decimal(Tdata_len);
            call Console.string(" > ");
            call Console.decimal(PAGE_SIZE);
            call Console.string("\n");
            TOSH_uwait(40000L);
#endif

            call Leds.redOn();
            signal GenericFlash.falReadDone[Tid](FAIL);
            return;
        }


        if (SUCCESS != call PageEEPROM.read(Tpage, Toffset + sizeof(chunk_header) + Tapp_len, 
                                            Tdata_buff, Tdata_len))
        {
            unlock();
#ifdef FLASH_DEBUG
            call Console.string("PageEEPROM read call 2 failed\n");
            TOSH_uwait(40000L);
#endif

            call Leds.redOn();
            signal GenericFlash.falReadDone[Tid](FAIL);
        }
        else
            state = FAL_TWO;
    }

    event result_t PageEEPROM.readDone(result_t res)
    {
        if (state == FAL_ONE)
        {
            if (res == SUCCESS)
            {
                chunk_header *h = (chunk_header *) Theader;
                memcpy(Theader, headerBuf, sizeof(chunk_header));

                if(Tapp_len > 0)
                {
#ifdef FLASH_DEBUG
                    call Console.string("Obj hdr len:");
                    call Console.decimal(Tapp_len);
                    call Console.string("\n");
                    TOSH_uwait(40000L);
#endif

                    memcpy(Tapp_buff, &headerBuf[sizeof(chunk_header)], Tapp_len);
                }

#ifdef FLASH_DEBUG
                call Console.string("Chunk len:");
                call Console.decimal(h->data_len);
                call Console.string(" if:");
                call Console.decimal(Tid);
                call Console.string("\n");
                TOSH_uwait(40000L);
#endif

                /* Now retrieve the chunk data */
                Tdata_len = h->data_len - Tapp_len;

#ifdef FLASH_DEBUG
                call Console.string("Data len to read:");
                call Console.decimal(Tdata_len);
                call Console.string("\n");
                TOSH_uwait(40000L);
#endif

                if (Tdata_len > 0)
                    post readData();
                else if (Tdata_len == 0)
                    signal GenericFlash.falReadDone[Tid](SUCCESS);
                else if (Tdata_len < 0)
                    signal GenericFlash.falReadDone[Tid](FAIL);
            }
            else
            {
                unlock();
#ifdef FLASH_DEBUG
                call Console.string("PageEEPROM read call returned failure\n");
                TOSH_uwait(40000L);
#endif

                signal GenericFlash.falReadDone[Tid](FAIL);
            }
        }
        else if (state == FAL_TWO)
        {
            /* Just finished reading the data also */
            unlock();
            signal GenericFlash.falReadDone[Tid](res);
        }
        else if (state == READ)
        {
            /* Just finished reading the data also */
            unlock();
            signal GenericFlash.readDone[Tid](res);
        }

        return (SUCCESS);
    }

    command result_t GenericFlash.read[uint8_t id](pageptr_t page, offsetptr_t offset,
                                       void *app_buff, datalen_t app_len)
    {
        if (lock() != SUCCESS)
        {
#ifdef FLASH_DEBUG
            call Console.string("ERROR ! Unable to acquire Flash-read lock\n");
            TOSH_uwait(40000L);
#endif
            return (FAIL);
        }
#ifdef FLASH_DEBUG
        call Console.string("Acquired Flash-read lock\n");
        TOSH_uwait(40000L);
#endif

        state = READ;
        Tid = id;

#ifdef FLASH_DEBUG
        call Console.string("Read pg:");
        call Console.decimal(page);
        call Console.string(" off:");
        call Console.decimal(offset);
        TOSH_uwait(40000L);
        call Console.string(" hdr len:");
        call Console.decimal(app_len);
        call Console.string("\n");
        TOSH_uwait(40000L);
#endif

        return(call PageEEPROM.read(page, offset, app_buff, app_len));
    }

    command result_t GenericFlash.erase[uint8_t id](pageptr_t page)
    {
        if (lock() != SUCCESS)
        {
#ifdef FLASH_DEBUG
            call Console.string("ERROR ! Unable to acquire Flash-erase lock\n");
            TOSH_uwait(20000);
#endif
            return (FAIL);
        }
#ifdef FLASH_DEBUG
        //call Console.string("Acquired Flash-erase lock\n");
        //TOSH_uwait(20000L);
#endif

#ifdef FLASH_DEBUG
        call Console.string("Erase pg:");
        call Console.decimal(page);
        call Console.string("\n");
        TOSH_uwait(20000L);
#endif
        Tid = id;

        return(call PageEEPROM.erase(page, TOS_EEPROM_ERASE));
    }

    event result_t PageEEPROM.eraseDone(result_t res)
    {
        unlock();
        signal GenericFlash.eraseDone[Tid](res);

        return (SUCCESS);
    }

    event result_t PageEEPROM.syncDone(result_t result)
    {
        return (SUCCESS);
    }

    event result_t PageEEPROM.computeCrcDone(result_t result, uint16_t crc)
    {
        return (SUCCESS);
    }

    default event result_t GenericFlash.initDone[uint8_t id](result_t result)
    {
        return (SUCCESS);
    }

    default event result_t GenericFlash.writeDone[uint8_t id](result_t result)
    {
        return (SUCCESS);
    }

    default event result_t GenericFlash.readDone[uint8_t id](result_t result)
    {
        return (SUCCESS);
    }

    default event result_t GenericFlash.eraseDone[uint8_t id](result_t result)
    {
        return (SUCCESS);
    }

    default event result_t GenericFlash.falReadDone[uint8_t id](result_t result)
    {
        return (SUCCESS);
    }

#ifdef FLASH_DEBUG
    event void Console.input(char *s)
    {}
#endif
}
