/*
 * file:        ArrayM.nc
 * description: Array implementation
 */

/*
 * Array implementation
 */

includes app_header;
includes common_header;

module ArrayM {
    provides interface Array[uint8_t id];
    
    uses {
        interface ChunkStorage;
        interface Leds;
        interface Console;
    }
}

implementation 
{
    enum {SETTING, SAVING, GETTING, LOADING};
    uint8_t state;
    flashptr_t *Tsave_ptr;
    uint8_t arrayif_id;
    struct 
    {
        flashptr_t head;
        bool doEcc;
        array_header buffer;
        unsigned int Tarr_index;
    }local[NUM_INDEXES];
    bool arrbusy = FALSE;

    /*********************************************
     ************** Lock / Unlock ****************
     *********************************************/
    result_t lock()
    {
        bool localBusy;

        atomic 
        {
            localBusy = arrbusy;
            arrbusy = TRUE;
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
        arrbusy = FALSE;
    }


    task void loadDoneRespond()
    {
        unlock();
        signal Array.loadDone[arrayif_id](SUCCESS);
    }

    command result_t Array.load[uint8_t id](flashptr_t *head_, 
                                            bool first_write, bool ecc)
    {
        if (lock() != SUCCESS)
        {
#ifdef LOCK_DEBUG
            call Console.string("ERROR ! Unable to acquire array load lock\n");
            TOSH_uwait(3000);
#endif
            return (FAIL);
        }
#ifdef LOCK__DEBUG
        call Console.string("Acquired array load lock\n");
#endif
#ifdef ARRAY_DEBUG
        call Console.string("Array: Loading level 1 index page - page:");
        call Console.decimal(head_->page);
        call Console.string(" off: ");
        call Console.decimal(head_->offset);
        call Console.string("\n");
        TOSH_uwait(5000);
#endif

        local[id].doEcc = ecc;

        if (first_write == TRUE)
        {
            // Index page does not exist on the flash
            post loadDoneRespond();
            return(SUCCESS);
        }
        else
        {
            memcpy (&local[id].head, head_, sizeof(flashptr_t));

            // Load the array page from flash
            if (SUCCESS != call ChunkStorage.read(&local[id].head, 
                                                  NULL, 0,
                                                  &local[id].buffer, NULL,
                                                  FALSE, &ecc))
            {
#ifdef ARRAY_DEBUG
                call Console.string("ERROR ! Unable to read array header from flash\n");
                TOSH_uwait(3000);
#endif       
                unlock();
                return (FAIL);
            }
            else
            {
                state = LOADING;
                arrayif_id = id;
                
                return(SUCCESS);
            }
        }
        
    }

    event void ChunkStorage.readDone(result_t res)
    {   
        unlock();

        if (state == GETTING)
        {            
            signal Array.getDone[arrayif_id](res);
        }
        else if (state == LOADING)
        {
            signal Array.loadDone[arrayif_id](res);
        }
    }

    command result_t Array.save[uint8_t id](flashptr_t *save_ptr)
    {
        if (lock() != SUCCESS)
        {
#ifdef LOCK_DEBUG
            call Console.string("ERROR ! Unable to acquire array save lock\n");
            TOSH_uwait(3000);
#endif
            return (FAIL);
        }
#ifdef LOCK_DEBUG
        call Console.string("Acquired array save lock\n");
        TOSH_uwait(3000);
#endif

        if (SUCCESS != call ChunkStorage.write(&local[id].buffer, sizeof(array_header),
                                               NULL, 0, FALSE, &local[id].head))
        {
#ifdef ARRAY_DEBUG
            call Console.string("ERROR ! Unable to write array header to flash\n");
            TOSH_uwait(3000);
#endif
            unlock();
            return (FAIL);
        }
        else
        {
            Tsave_ptr = save_ptr;
            state = SAVING;
            arrayif_id = id;
            
            return (SUCCESS);
        }
    }

    event void ChunkStorage.writeDone(result_t res)
    {   
        unlock();
		
        if (state == SETTING)
        {
			
            /* Modify it to reflect new data */
            memcpy(Tsave_ptr, 
                   &local[arrayif_id].buffer.ptr[local[arrayif_id].Tarr_index],
                   sizeof(flashptr_t));
            signal Array.setDone[arrayif_id](res);
        }
        else if (state == SAVING)
        {
            if ((res == SUCCESS) && (Tsave_ptr != NULL))
                memcpy(Tsave_ptr, &local[arrayif_id].head, sizeof(flashptr_t));
        
#ifdef ARRAY_DEBUG
        {
            int i;

            call Console.string("Array: Saved level 1 index page - page:");
            call Console.decimal(local[arrayif_id].head.page);
            call Console.string(" off: ");
            call Console.decimal(local[arrayif_id].head.offset);
            call Console.string("\n");
            TOSH_uwait(4000);

            for (i=0; i < ARRAY_ELEMENTS_PER_CHUNK; i++)
            {
                call Console.string("Element:");
                call Console.decimal(i);
                call Console.string(" page: ");
                call Console.decimal(local[arrayif_id].buffer.ptr[i].page);
                call Console.string(" off: ");
                call Console.decimal(local[arrayif_id].buffer.ptr[i].offset);
                call Console.string("\n");
                TOSH_uwait(4000);
            }
        }
#endif

            signal Array.saveDone[arrayif_id](res);
        }
    }


    command result_t Array.set[uint8_t id](unsigned int arr_index, void *data, 
                                           datalen_t len, flashptr_t *save_ptr)
    {	
        if (lock() != SUCCESS)
        {
#ifdef LOCK_DEBUG
            call Console.string("ERROR ! Unable to acquire array set lock\n");
            TOSH_uwait(3000);
#endif
            return (FAIL);
        }
#ifdef LOCK_DEBUG
        call Console.string("Acquired array set lock\n");
        TOSH_uwait(3000);
#endif
        /* Write the data */
        if(SUCCESS != call ChunkStorage.write(NULL, 0,
                                              data, len, 
                                              local[id].doEcc, 
                                              &local[id].buffer.ptr[arr_index]))
        {
#ifdef ARRAY_DEBUG
            call Console.string("ERROR ! Unable to write chunk in array.set\n");
            TOSH_uwait(3000);
#endif           

			unlock();
            return (FAIL);
        }
        else
        {
            Tsave_ptr = save_ptr;
            state = SETTING;
            arrayif_id = id;
            local[id].Tarr_index = arr_index;
            return (SUCCESS);
        }
    }

    event void ChunkStorage.flushDone(result_t res)
    {
    }

    command result_t Array.get[uint8_t id](unsigned int arr_index, 
                                           void *data, datalen_t *len)
    {
        uint8_t ecc;

        if (lock() != SUCCESS)
        {
#ifdef LOCK_DEBUG
            call Console.string("ERROR ! Unable to acquire array get lock\n");
            TOSH_uwait(3000);
#endif
            return (FAIL);
        }
#ifdef ARRAY_DEBUG
        call Console.string("Acquired array get lock\n");
#endif
#ifdef LOCK_DEBUG
        call Console.string("Array: Getting element:");
        call Console.decimal(arr_index);
        call Console.string(" from page:");
        call Console.decimal(local[id].buffer.ptr[arr_index].page);
        call Console.string(" off: ");
        call Console.decimal(local[id].buffer.ptr[arr_index].offset);
        call Console.string("\n");
        TOSH_uwait(3000);
#endif

    	//check for null pointer
		if (local[id].buffer.ptr[arr_index].page == 0xFFFF && 
			local[id].buffer.ptr[arr_index].offset == 0xFF)
		{
			*len = 0;
			unlock();
			signal Array.getDone[id](SUCCESS);
			return SUCCESS;
		}
		
        /* Now get the data */
        if (SUCCESS != call ChunkStorage.read(&local[id].buffer.ptr[arr_index],
                                              NULL, 0,
                                              data, len, FALSE, &ecc))
        {
#ifdef ARRAY_DEBUG
            call Console.string("ERROR ! Unable to read chunk date in array.get\n");
            TOSH_uwait(3000);
#endif             
            unlock();
            return (FAIL);
        }
        else
        {
            state = GETTING;
            arrayif_id = id;
            
            return (SUCCESS);
        }
    }
	
	
	command result_t Array.delete[uint8_t id](unsigned int arr_index)
    {
        /* Delete the data */
        memset (&local[arrayif_id].buffer.ptr[arr_index], 0xFF, sizeof(flashptr_t));

        return (SUCCESS);
    }
	

    default event void Array.setDone[uint8_t id](result_t r)
    {}

    default event void Array.getDone[uint8_t id](result_t r)
    {}

    default event void Array.saveDone[uint8_t id](result_t r)
    {}
    
    default event void Array.loadDone[uint8_t id](result_t r)
    {}

    event void Console.input(char *s)
    {
    }
}
