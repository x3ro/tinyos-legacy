/*
 * file:        FlashM.nc
 * description: Component that abstracts the NOR flash
 *
 */

includes common_header;

#define FLASH_DEBUG

module FlashM {
    provides interface GenericFlash[uint8_t id];

    uses {
        interface HALSTM25P;
        interface Console;
    }
}

implementation 
{
    uint8_t Tid;

    task void initDone()
    {
        signal GenericFlash.initDone[Tid](SUCCESS);
    }

    command result_t GenericFlash.init[uint8_t id]()
    {
        Tid = id;
        post initDone();

        return (SUCCESS);
    }

    command pageptr_t GenericFlash.numPages[uint8_t id]()
    {
        return(4096);
    }
    
    command result_t GenericFlash.write[uint8_t id](pageptr_t page, offsetptr_t offset,
                                        void *data, offsetptr_t len)
    {
        Tid = id;
#ifdef FLASH_DEBUG
        call Console.string("FlashM: Writing.. pg:");
        call Console.decimal(page);
        call Console.string(" off:");
        call Console.decimal(offset);
        call Console.string(" len:");
        call Console.decimal(len);
        call Console.string("\n");
        TOSH_uwait(10000);
#endif
        return(call HALSTM25P.pageProgram((page * 256) + offset, data, len));
    }

    event void HALSTM25P.pageProgramDone()
    {
#ifdef FLASH_DEBUG
        call Console.string("FlashM: Write done");
        TOSH_uwait(10000);
#endif
        signal GenericFlash.writeDone[Tid](SUCCESS);
    }

    task void readSignal()
    {
        signal GenericFlash.readDone[Tid](SUCCESS);
    }

    task void falReadSignal()
    {
#ifdef FLASH_DEBUG
        call Console.string("FlashM: Read done");
        TOSH_uwait(10000);
#endif

        signal GenericFlash.falReadDone[Tid](SUCCESS);
    }


    uint8_t headerBuf[MAX_HEADERS_LEN];
    command result_t GenericFlash.falRead[uint8_t id](pageptr_t page, offsetptr_t offset,
                                          void *header, 
                                          void *app_buff, offsetptr_t app_len, 
                                          void *data_buff)
    {
        uint32_t accessLocation = (page * 256) + offset;

        Tid = id;

#ifdef FLASH_DEBUG
        call Console.string("FlashM: Read 1.. pg:");
        call Console.decimal(page);
        call Console.string(" off:");
        call Console.decimal(offset);
        call Console.string(" len:");
        call Console.decimal(sizeof(chunk_header) + app_len);
        call Console.string("\n");
        TOSH_uwait(10000);
#endif

        if (SUCCESS != call HALSTM25P.read(accessLocation, headerBuf, 
                                           sizeof(chunk_header) + app_len))
        {
#ifdef FLASH_DEBUG
            call Console.string("FlashM: Read 1 failed");
            TOSH_uwait(10000);
#endif
            return (FAIL);
        }
        else
        {
            chunk_header *h;

#ifdef FLASH_DEBUG
            {
                int i=0;

                for (i=0; i<(sizeof(chunk_header) + app_len); i++)
                {
                    call Console.string(" ");
                    call Console.decimal(headerBuf[i]);
                }
                call Console.string("\n");
            }
#endif 

            memcpy(header, headerBuf, sizeof(chunk_header));
            h = (chunk_header *) &header;

            if(app_len > 0)
            {
                memcpy(app_buff, &headerBuf[sizeof(chunk_header)], app_len);
            }

#ifdef FLASH_DEBUG
            call Console.string("FlashM: Read 2.. pg:");
            call Console.decimal(page);
            call Console.string(" off:");
            call Console.decimal(offset + sizeof(chunk_header) + app_len);
            call Console.string(" len:");
            call Console.decimal(h->data_len - app_len);
            call Console.string(" h->data_len:");
            call Console.decimal(h->data_len);
            call Console.string(" app_len:");
            call Console.decimal(app_len);
            call Console.string("\n");
            TOSH_uwait(10000);
#endif

            /* Now retrieve the chunk data */
            if ( (h->data_len - app_len) && 
                 (SUCCESS != call HALSTM25P.read(accessLocation + sizeof(chunk_header) + app_len, 
                                                 data_buff, h->data_len - app_len)) )
            {
#ifdef FLASH_DEBUG
                call Console.string("FlashM: Read 2 failed");
                TOSH_uwait(10000);
#endif
                return (FAIL);
            }
            else
            {
                post falReadSignal();
            }
        }

        return (SUCCESS);
    }

    command result_t GenericFlash.read[uint8_t id](pageptr_t page, offsetptr_t offset,
                                                   void *buff, offsetptr_t app_len)
    {
        uint32_t accessLocation = (page * 256) + offset;

        Tid = id;

#ifdef FLASH_DEBUG
        call Console.string("FlashM: Reading");
        TOSH_uwait(10000);
#endif

        if (SUCCESS != call HALSTM25P.read(accessLocation, buff, app_len))
        {
            return (FAIL);
        }
        else
        {
            post readSignal();
        }

        return (SUCCESS);
    }


    command result_t GenericFlash.erase[uint8_t id](pageptr_t page)
    {
        Tid = id;
        return(call HALSTM25P.sectorErase(page));
    }

    event void HALSTM25P.sectorEraseDone()
    {
        signal GenericFlash.eraseDone[Tid](SUCCESS);
    }

    event void HALSTM25P.bulkEraseDone()
    {}

    event void HALSTM25P.writeSRDone()
    {}

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
