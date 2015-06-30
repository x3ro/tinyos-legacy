/*
 * file:        ChunkStorageM.nc
 * description: Implementation of the FAL
 */

/*
 * This module provides a Chunk-based interface to read and write data
 * to the Flash
 */
includes chunk_header;
includes common_header;


module ChunkStorageM {
    provides interface ChunkStorage[uint8_t id];
    provides interface StdControl;
    provides interface Serialize;

    uses {
        interface GenericFlash;
        interface Leds;
        interface Console;
        interface Compaction;
        interface Crc8;
    }
}

implementation {

    /* States for the driver */
    enum {FLUSHING, WRITING, READING1, READING2};
    
    /* Write cache maintenance and access */
    pageptr_t page_ptr;     /* Maintains a pointer to the next page to be 
                               written to in the flash */
    offsetptr_t offset_ptr; /* Maintains a pointer to the next offset to be 
                               written to in the current page */
    uint16_t cache_ptr;     /* This is the pointer into the current write buffer 
                                  where the next chunk will be written */
    uint8_t write_buffer[BUFFER_SIZE]; /* This is the page buffer used to 
                                               cache data that is to be 
                                               written to the flash */
    bool chunkbusy = FALSE;    /* Used to lock the component */
    uint8_t state;             /* Tracks the state of the component */
    pageptr_t total_pages;
    bool flashFull = FALSE, writeBufferValid = FALSE;

    result_t res;
    uint8_t if_id;

	int who_owns_it;
	
    /* Local functions */
    bool verifyEcc();
    result_t readBuffer(offsetptr_t ptr);
    void write_to_cache();

    /* Temp storage for write & read data */
    void *data1, *data2; 
    datalen_t len1, len_data, *rlen2;
    bool computeEcc, *ecc;
    flashptr_t seekptr, *save_ptr;
    uint8_t header_buffer[sizeof(chunk_header)];


    /*********************************************
     ************** Lock / Unlock ****************
     *********************************************/
    result_t lock()
    {
        bool localBusy;

        atomic 
        {
            localBusy = chunkbusy;
            chunkbusy = TRUE;
        }

        if (TRUE != localBusy)
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
        chunkbusy = FALSE;
    }
    

    command result_t StdControl.init() 
    {
        /* Initialize chunk storage */
        page_ptr = ROOT_DIRECTORY_AREA + DELUGE_AREA;
        offset_ptr = 0;
        cache_ptr = 0;

		who_owns_it = -1;
		
        /* Fill write buffer with 1s */
        memset (write_buffer, 0xFF, BUFFER_SIZE);

        call Leds.init();

        if (SUCCESS != call GenericFlash.init())
        {
#ifdef CHUNK_DEBUG
            call Console.string("GenericFlash.init call failed\n");
            TOSH_uwait(30000L);
#endif
            call Leds.redOn();
            return (FAIL);
        }

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

    event result_t GenericFlash.initDone(result_t r)
    {
        if (SUCCESS != r)
        {
#ifdef CHUNK_DEBUG
            call Console.string("GenericFlash.init call returned failure\n");
            TOSH_uwait(30000L);
#endif
            call Leds.redOn();
            return (FAIL);
        }
    
        total_pages = call GenericFlash.numPages();
    
        return (SUCCESS);
    }

    task void flushDoneRespond()
    {
#ifdef CHUNK_DEBUG
        //call Console.string("Releasing flush lock\n");
//        call Console.string("Signalling writeDone id:");
//        call Console.decimal(if_id);
//        call Console.string("\n");
        TOSH_uwait(20000);
#endif

        unlock();
        signal ChunkStorage.flushDone[if_id](res);
    }


    /*********************************************
     ************  Writing to Flash **************
     *********************************************/

    /* 
     * Flushes the write buffer to flash 
     * Note : this assumes that locking has already been handled
     */
    result_t flush_write_buffer()
    {
        if (cache_ptr == 0)
        {
            /* Nothing to write */
            if (state == WRITING)
                write_to_cache();
            else
            {
                res = SUCCESS;
                post flushDoneRespond();
            }

            return (SUCCESS);
        }

#ifdef A
        {
            int i;
            call Console.string("Cache being written to page:");
            call Console.decimal(page_ptr);
            call Console.string(" offset:");
            call Console.decimal(offset_ptr);
            call Console.string(" len:");
            call Console.decimal(cache_ptr);
            call Console.string("\n");
            
            for (i = 0; i < cache_ptr; i++)
            {
                call Console.hex(write_buffer[i]);
                call Console.string(" ");
                if (!(i % 10))
                    call Console.string("\n");
                TOSH_uwait(10000);
            }
            call Console.string("\n");
        }
#endif

        /* Flush data to the flash */
        if (SUCCESS != call GenericFlash.write(page_ptr, offset_ptr, 
                                               write_buffer, 
                                               cache_ptr))
        {
#ifdef CHUNK_DEBUG
            call Console.string("Write cache dump failed: pg");
            call Console.decimal(page_ptr);
            call Console.string(" off:");
            call Console.decimal(offset_ptr);
            call Console.string(" len:");
            call Console.decimal(cache_ptr);
            call Console.string("\n");
            TOSH_uwait(20000);
#endif
            call Leds.redOn();
            return (FAIL);
        }
		
        return (SUCCESS);
    }

    command uint8_t ChunkStorage.percentagefull[uint8_t id]()
    {
        return (page_ptr / total_pages);
    }

    /*
     * Erase management - when the flash becomes full, this starts erasing 
     * one block ahead of the flash
     */
	task void eraser()
	{
		pageptr_t page = page_ptr + 1;

		if (page == total_pages)
		{
			page = ROOT_DIRECTORY_AREA + DELUGE_AREA;
		}
		
		if (SUCCESS != call GenericFlash.erase(page))
		{
            call Leds.redOn();
#ifdef CHUNK_DEBUG
			call Console.string("Erase failed: pg");
			call Console.decimal(page);
			call Console.string("\n");
			TOSH_uwait(20000);
#endif
		}
	}
    
    /*
     * This method is called after flushing the write buffer
     * It does all the pointer management for flash and buffer pointers
     */
    void post_flushing_buffer()
    {
        /* Fill write buffer with 1s */
        memset (write_buffer, 0xFF, cache_ptr);

        offset_ptr += cache_ptr;
        cache_ptr = 0;

#ifdef CHUNK_DEBUG
        call Console.string("\nPAGE_SIZE:");
        call Console.decimal(PAGE_SIZE);
        call Console.string(" offset_ptr:");
        call Console.decimal(offset_ptr);
        call Console.string(" BUFFER_SIZE:");
        call Console.decimal(BUFFER_SIZE);
        call Console.string("\n");
        TOSH_uwait(20000);
#endif

        if ((PAGE_SIZE - offset_ptr) <= BUFFER_SIZE)
        {
            /* Go to a new page... */
#ifdef CHUNK_DEBUG
            call Console.string("Moving to new page\n");
            TOSH_uwait(20000);
#endif

            offset_ptr = 0;
            page_ptr++; // Might hit total flash size + 1 -> its ok we handle it a lil later

            /* Do compaction if we are half-way through flash... */
            if ( (page_ptr == (total_pages/2)) || (page_ptr == total_pages) )
            {
  	          uint8_t agingHint=0;
              call Compaction.compact(agingHint);
            }

            if (page_ptr == total_pages)
            {
                flashFull = TRUE;
                page_ptr = ROOT_DIRECTORY_AREA + DELUGE_AREA;
            }

            if ( (flashFull == TRUE) || (page_ptr == total_pages - 1) )
            {
                /* Erase the next page that will be written to... */
                post eraser();               
            }
        }            
    }
    
    event void Compaction.compactionDone(result_t r)
    {
    }
    
    /* 
     * Flush current write buffer to flash
     */
    command result_t ChunkStorage.flush[uint8_t id]()
    {
        result_t result;

        if (lock() != SUCCESS)
        {
#ifdef CHUNK_DEBUG
            call Console.string("ERROR ! Unable to acquire flush lock\n");
            TOSH_uwait(20000);
#endif
            return (FAIL);
        }
#ifdef CHUNK_DEBUG
        call Console.string("Acquired flush lock\n");
#endif

        state = FLUSHING;
        if_id = id;

        if((result = flush_write_buffer()) != SUCCESS)
        {
#ifdef CHUNK_DEBUG
            call Console.string("ERROR ! Unable to flush the write buffer\n");
            TOSH_uwait(20000);
#endif
            unlock();
        }

        return (result);
    }

    
    /* Writes a chunk/record into Flash
     * NOTE : Internally, chunks are buffered and the buffer is flushed to the
     *        flash when it becomes full or user force-flushes it.
     */
    command result_t ChunkStorage.write[uint8_t id](void *data1_, datalen_t len1_,
                                                    void *data2_, datalen_t len2_, 
                                                    bool computeEcc_, 
                                                    flashptr_t *save_ptr_)
	{
		datalen_t chunk_len;
		
		if (lock() != SUCCESS)
		{			
#ifdef CHUNK_DEBUG
			call Console.string("ERROR ! Unable to acquire write lock\n");
			TOSH_uwait(40000L);
#endif
			return (FAIL);
		}
		who_owns_it = id;
#ifdef CHUNK_DEBUG
		call Console.string("Acquired write lock\n");
		TOSH_uwait(20000);
#endif

		state = WRITING;
		if_id = id;

		chunk_len = len1_ + len2_ + sizeof(chunk_header);
		
		/*
		* Check if the chunk size is supported
		*/
		if (chunk_len > BUFFER_SIZE)
		{
			
#ifdef CHUNK_DEBUG
			call Console.string("Chunk len ");
			call Console.decimal(chunk_len);
			call Console.string("\nwrite buffer ");
			call Console.decimal(BUFFER_SIZE);
			call Console.string("\nERROR ! Chunk len > write buffer\n");
			TOSH_uwait(20000);
#endif
			unlock();
			return (FAIL);
		}

		
		/* Write data to temp location */
		data1 = data1_;
		len1 = len1_;
		data2 = data2_; 
		len_data = len2_;
		computeEcc = computeEcc_;
		save_ptr = save_ptr_;

		
		/*
		* Flush the current page write cache if there isnt enough place
		* to hold the new chunk
		*/
		if (chunk_len > (BUFFER_SIZE - cache_ptr))
		{
			/* Flush the cache -> hold off writing the data until 
			data is flushed */
#ifdef CHUNK_DEBUG
			call Console.string("Flushing write cache\n");
			call Console.string("chunk_len:");
			call Console.decimal(chunk_len); 
			call Console.string(" cache_ptr:");
			call Console.decimal(cache_ptr); 
			call Console.string("\n");
			TOSH_uwait(20000);
#endif
			
			if(flush_write_buffer() != SUCCESS)
			{
#ifdef CHUNK_DEBUG
				call Console.string("ERROR ! Flush to flash failed\n");
				TOSH_uwait(20000);
#endif
				unlock();
				return (FAIL);
			}
			
		}
		else
		{
			
			/* Write the data to the cache */
			write_to_cache();
		}

		return (SUCCESS);
	}


    /* 
     * Event responders 
     */
    task void writeDoneRespond()
    {
#ifdef CHUNK_DEBUG
        //call Console.string("Releasing write lock\n");
//        call Console.string("Signalling writeDone id:");
//        call Console.decimal(if_id);
//        call Console.string("\n");
        TOSH_uwait(20000);
#endif
        unlock();
        
        signal ChunkStorage.writeDone[if_id](res);
    }

    

    /*
     * Writes the application passed chunk into the page buffer.
     * NOTE: Its actually not written to the flash here...
     */
    void write_to_cache()
    {
        uint8_t Ecc = 0;
        chunk_header* header;
		
		/* Return handle to where data will be written in flash */
        save_ptr->page = page_ptr;
        save_ptr->offset = (offset_ptr + cache_ptr);
#ifdef CHUNK_DEBUG
        call Console.string("Writing data to:pg");
        call Console.decimal(save_ptr->page);
        call Console.string(" off");
        call Console.decimal(save_ptr->offset);
        call Console.string("\n");
        TOSH_uwait(20000);
#endif

        header = (chunk_header*) &write_buffer[cache_ptr];

        /* Copy data to the page cache */
        header->data_len = len1 + len_data;

        cache_ptr += sizeof(chunk_header);

        /* Copy in app-level header */
        if (len1 > 0)
        {
            memcpy(&write_buffer[cache_ptr], data1, len1);
            cache_ptr += len1;

            if (computeEcc)
            {
                Ecc = call Crc8.crc8(data1, len1, 0);
            }
        }
        /* Copy in data */
        if (len_data > 0)
        {
            memcpy(&write_buffer[cache_ptr], data2, len_data);
            cache_ptr += len_data;

            if (computeEcc)
            {
                Ecc = call Crc8.crc8(data2, len_data, Ecc);
            }
        }

#ifdef CHUNK_DEBUG
        {
            int i;

            call Console.string("Write cache:");
            for (i=0; i < 20; i++)
            {
                call Console.string(" ");
                call Console.decimal(write_buffer[i]);
            }
            call Console.string("\n");
            TOSH_uwait(20000);
        }
#endif

        header->ecc = Ecc;
        res = SUCCESS;
        writeBufferValid = TRUE;

		
        post writeDoneRespond();
    }
   
    /*
     * This is called when the page is written to the flash - it could be called
     * both when the application is trying to write into the buffer but there isnt
     * enough space, and when the user force-flushes the page buffer.
     */
    event result_t GenericFlash.writeDone(result_t result)
    {
        res = result;
        
        if (state == WRITING)
        {
			
            /* Data being flushed to flash -> data has to be written to cache */
            if (result == SUCCESS)
            {
                post_flushing_buffer();
                write_to_cache();
            }
            else
            {
#ifdef CHUNK_DEBUG
                call Console.string("ERROR ! writeDone - page writing failed\n");
                TOSH_uwait(20000);
#endif        
                post writeDoneRespond();
            }
        }
        else if (state == FLUSHING)
        {
            /* Cache clearing */
            if (result == SUCCESS)
                post_flushing_buffer();
            else
            {
#ifdef CHUNK_DEBUG
                call Console.string("ERROR ! flushDone - page flushing failed\n");
                TOSH_uwait(20000);
#endif  
            }

            post flushDoneRespond();
        }

        return (SUCCESS);
    }


    /*********************************************
     ************  Reading from Flash ************
     *********************************************/

    /*
     * Event responder
     */
    task void readDoneRespond()
    {
#ifdef CHUNK_DEBUG
        //call Console.string("Releasing read lock\n");
        TOSH_uwait(40000L);
#endif 

        unlock();
        signal ChunkStorage.readDone[if_id](res);
    }

    /* 
     * Reads a chunk of data from flash
     * TODO We should probably read a fixed amount of data from the flash
     * and read more if needed (32b seems to be knee of the amortized cost
     curve for the 512b flash)
     */
     command result_t ChunkStorage.read[uint8_t id](flashptr_t *ptr_, 
                                        void *data1_, datalen_t len1_, 
                                        void *data2_, datalen_t *len2_, 
                                        bool checkEcc_, bool *ecc_) 
     {
        //uint8_t *blah;

        if (lock() != SUCCESS)
        {
#ifdef CHUNK_DEBUG
            call Console.string("ERROR ! Unable to acquire read lock\n");
            TOSH_uwait(20000);
#endif
            return (FAIL);
        }
		who_owns_it = id;
#ifdef CHUNK_DEBUG
        call Console.string("Acquired read lock\n");
        TOSH_uwait(40000L);
		TOSH_uwait(40000L);
#endif

        state = READING1;
        if_id = id;

        /* Write data to temp buffer */
        seekptr.page = ptr_->page;
        seekptr.offset = ptr_->offset;
        data1 = data1_;
        len1 = len1_;
        data2 = data2_; 
        rlen2 = len2_;
        computeEcc = checkEcc_;
        ecc = ecc_;

#ifdef CHUNK_DEBUG
        call Console.string("Reading from flash seekptr- pg:");
        call Console.decimal(seekptr.page);
        call Console.string(" off:");
        call Console.decimal(seekptr.offset);
        call Console.string(" len:");
        call Console.decimal(sizeof(chunk_header) + len1);
        call Console.string(" if:");
        call Console.decimal(id);
        call Console.string("\n");
        TOSH_uwait(40000L);
		TOSH_uwait(40000L);
#endif

        if ( (seekptr.page == page_ptr) && (seekptr.offset >= offset_ptr) &&
             (seekptr.offset < (offset_ptr + BUFFER_SIZE)) && (writeBufferValid == TRUE) )
        {
            /* Data is in the write cache */
            readBuffer(seekptr.offset - offset_ptr);
        
            res = SUCCESS;
            post readDoneRespond();
            
            return (SUCCESS);
        }

#ifdef CHUNK_DEBUG
        call Console.string("Reading from flash...\n");
        TOSH_uwait(40000L);
		TOSH_uwait(40000L);
#endif

        /* Get the data from flash */
        if (SUCCESS != call GenericFlash.falRead(seekptr.page, seekptr.offset,
                                                 header_buffer, 
                                                 data1_, len1,
                                                 data2_))
        {
#ifdef CHUNK_DEBUG
            call Console.string("ERROR ! Chunk header reading failed\n");
            TOSH_uwait(30000);
			TOSH_uwait(30000);
#endif
            call Leds.redOn();
            unlock();
            return (FAIL);
        }

        return (SUCCESS);
    }

    /* 
     * Reads a chunk still present in the write cache
     */
    result_t readBuffer(offsetptr_t cacheptr)
    {   
        chunk_header *header;
        datalen_t data2_len;
        
#ifdef CHUNK_DEBUG
        call Console.string("Reading header chunk from page cache. offset:");
        call Console.decimal(cacheptr);
        call Console.string("\n");
        TOSH_uwait(50000L);
#endif

        /* First get the header of the chunk */
        header = (chunk_header *) &write_buffer[cacheptr];

#ifdef CHUNK_DEBUG
        {
            int i;

            call Console.string("Write cache (20):");
            for (i=0; i < 20; i++)
            {
                call Console.string(" ");
                call Console.decimal(write_buffer[i]);
            }
            call Console.string("\n");
            TOSH_uwait(20000);
        }

        {
            int i;

            call Console.string("Write cache:");
            for (i=cacheptr; i < (cacheptr + sizeof(chunk_header)); i++)
            {
                call Console.string(" ");
                call Console.decimal(write_buffer[i]);
            }
            call Console.string("\n");
            TOSH_uwait(20000);
        }
#endif

        /* Now retrieve the chunk data */
        data2_len = header->data_len - len1;

#ifdef CHUNK_DEBUG
        call Console.string("Header data len:");
        call Console.decimal(header->data_len);
        call Console.string(" len1:");
        call Console.decimal(len1);
        call Console.string(" chunk data len:");
        call Console.decimal(data2_len);
        call Console.string("\n");
        TOSH_uwait(50000L);
#endif
       
        if ((data2_len > 0) && (data2 != NULL))
        {
            memcpy (data2, &write_buffer[cacheptr + sizeof(chunk_header) + len1], data2_len);
        }

        if (rlen2 != NULL)
            *rlen2 = data2_len;

        /* Copy the header data */
        if (len1 > 0)
        {
            memcpy (data1, &write_buffer[cacheptr + sizeof(chunk_header)], len1);
        }

        return (SUCCESS);
    }
    
    /*
     * This event is triggered when a read if performed on the flash. It is triggered
     * both when reading the header and the data part of the chunk.
     */
    event result_t GenericFlash.falReadDone(result_t result)
    {
        res = result;

        if ((result == SUCCESS) && (rlen2 != NULL))
        {
            chunk_header *header = (chunk_header *) header_buffer;
            *rlen2 = header->data_len - len1;

            if (computeEcc)
            {
                uint8_t Ecc = call Crc8.crc8(data1, len1, 0);
                Ecc = call Crc8.crc8(data2, *rlen2, Ecc);

                if ( (ecc != NULL) && (Ecc == header->ecc) )
                {
                    *ecc = TRUE;
#ifdef CHUNK_DEBUG
                    call Console.string("CRC passed\n");
                    TOSH_uwait(40000L);
#endif
                }
                else
                {
                    *ecc = FALSE;
#ifdef CHUNK_DEBUG
                    call Console.string("CRC failure\n");
                    TOSH_uwait(40000L);
#endif
                }
            }
        }

        post readDoneRespond();

        return (SUCCESS);
    }

    /*
     * This event is triggered when an erase is performed on an erase block
     */
    event result_t GenericFlash.eraseDone(result_t result)
    {
         /* TODO Check for 0xFF at byte 517 on the first 2 pages of the
            erase block */
         return (SUCCESS);
    }

    event result_t GenericFlash.readDone(result_t result)
    {
         return (SUCCESS);
    }

    command result_t Serialize.checkpoint(uint8_t *buffer, datalen_t *len)
    {
#ifdef CHECKPOINT_DEBUG
        call Console.string("Checkpointing ChunkStorage, pg=");
        call Console.decimal(page_ptr);
        call Console.string("\n");
        TOSH_uwait(50000L);
#endif

        memcpy (&buffer[*len], &page_ptr, sizeof(pageptr_t));
        *len += sizeof(pageptr_t);

        return (SUCCESS);
    }

    command result_t Serialize.restore(uint8_t *buffer, datalen_t *len)
    {
        memcpy (&page_ptr, &buffer[*len], sizeof(pageptr_t));
        *len += sizeof(pageptr_t);

#ifdef CHECKPOINT_DEBUG
        call Console.string("Restored ChunkStorage, pg=");
        call Console.decimal(page_ptr);
        call Console.string("\n");
        TOSH_uwait(50000L);
#endif
        page_ptr++;

        return (SUCCESS);
    }

    /* Keep compiler happy... */
    default event void ChunkStorage.readDone[uint8_t id](result_t r)
    {}

    default event void ChunkStorage.writeDone[uint8_t id](result_t r)
    {}

    default event void ChunkStorage.flushDone[uint8_t id](result_t r)
    {}

    event void Console.input(char *s)
    {
    }

}
