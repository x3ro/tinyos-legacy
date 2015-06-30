/*
 * file:        IndexM.nc
 * description: Index object implementation
 */

/*
 * Index implementation
 */

includes app_header;
includes common_header;

module IndexM {
    provides interface Index[uint8_t id];
    provides interface Serialize[uint8_t id];
    provides interface Compaction[uint8_t id];
    provides interface RootPtrAccess[uint8_t id];
    provides interface StdControl;

    uses {
        interface ChunkStorage;
        interface Array[uint8_t id];
        interface Leds;
        interface Console;
    }
}

implementation 
{
    enum{SETTING, GETTING, SAVING, LOADING, DELETING};
    flashptr_t *Tsave_ptr;
    unsigned int Tarrindex, Tindex;
    void *Tdata;
    datalen_t Tlen, *Tlen_;
    uint8_t indexif_id;
    uint8_t state, state2;
    bool compacting;
    struct _data
    {
        flashptr_t head; // back this up
        bool doEcc;
        index_header buffer;
        pageptr_t old_indexptr;
        
        /* Compaction data */
        datalen_t clen;
        uint16_t compactptr;
        uint8_t buff[LEN];
        bool buffModify;
    }local[NUM_INDEXES];
    bool indexbusy;


    task void loadData();
    task void saveData();
    task void compact_get();
    task void compact_set();
    task void loadArrPage();
    task void deleteData();

    /*********************************************
     ************** Lock / Unlock ****************
     *********************************************/
    result_t lock()
    {
        bool localBusy;

        atomic 
        {
            localBusy = indexbusy;
            indexbusy = TRUE;
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
        indexbusy = FALSE;
    }

    task void SuccessRespond()
    {
        unlock();
        //call Leds.redOn();

        if(state == SAVING)
            signal Index.saveDone[indexif_id](SUCCESS);
        else if(state == LOADING)
            signal Index.loadDone[indexif_id](SUCCESS);
    }

    task void FailRespond()
    {
        unlock();
        //call Leds.redOn();

        if(state2 == SETTING)
            signal Index.setDone[indexif_id](FAIL);
        else if(state2 == GETTING)
            signal Index.getDone[indexif_id](FAIL);
        else
            signal Index.saveDone[indexif_id](FAIL);
    }

    task void FailRespond2()
    {
        unlock();

        if(state == SAVING)
            signal Index.saveDone[indexif_id](FAIL);
        else if(state == LOADING)
            signal Index.loadDone[indexif_id](FAIL);
    }

    command result_t StdControl.init()
    {
        uint8_t i=0; 

        do
        {
#ifdef INDEX_DEBUG
            call Console.string("Index: init-ing if:");
            call Console.decimal(i);
            call Console.string("\n");
#endif

            memset(&local[i].head, 0xFF, sizeof(flashptr_t));
            memset(&local[i].buffer, 0xFF, sizeof(index_header));
            local[i].old_indexptr = 0xFFFF;

            local[i].clen = 0;
            local[i].compactptr = 0;
            local[i].buffModify = FALSE;
        }
        while (++i < NUM_INDEXES);

        return(SUCCESS);
    }

    command result_t StdControl.start()
    {
        return(SUCCESS);
    }

    command result_t StdControl.stop()
    {
        return(SUCCESS);
    }

    task void loadTask()
    {
        flashptr_t temp;
        uint8_t ecc;

        memset(&temp, 0xFF, sizeof(flashptr_t));

        if (memcmp(&local[indexif_id].head, &temp, sizeof(flashptr_t)) != 0)
        {
            if (SUCCESS != call ChunkStorage.read(&local[indexif_id].head, 
                                                  NULL, 0,
                                                  &local[indexif_id].buffer, NULL,
                                                  FALSE, &ecc))
            {
#ifdef INDEX_DEBUG
                call Console.string("ERROR ! Unable to read in the index\n");
                TOSH_uwait(30000L);
#endif
                post FailRespond2();
            }
        }
        else
        {
            post SuccessRespond();
        }

    }

    /***********
     * This loads the index from flash to memory
     ***********/
    command result_t Index.load[uint8_t id](bool ecc)
    {
        if (lock() != SUCCESS)
        {
#ifdef LOCK_DEBUG
            call Console.string("ERROR ! Unable to acquire index load lock\n");
            TOSH_uwait(30000L);
#endif
            return (FAIL);
        }
#ifdef LOCK_DEBUG
        call Console.string("Acquired index load lock\n");
        TOSH_uwait(30000L);
#endif

        local[id].doEcc = ecc;        
        state = LOADING;
        indexif_id = id;

#ifdef INDEX_DEBUG
        call Console.string("Loading index ");
        call Console.string(" from page: ");
        call Console.decimal(local[indexif_id].head.page);
        call Console.string(" off: ");
        call Console.decimal(local[indexif_id].head.offset);
        call Console.string("\n");
        TOSH_uwait(30000L);
#endif

        post loadTask();

        return (SUCCESS);
    }

    task void saveTask()
    {
#ifdef INDEX_DEBUG
        call Console.string("In Index.saveTask\n");
        TOSH_uwait(30000L);
#endif

        if (SUCCESS != call ChunkStorage.write(NULL, 0,
                                               &local[indexif_id].buffer, sizeof(index_header), 
                                               FALSE, &local[indexif_id].head))
        {
#ifdef INDEX_DEBUG
            call Console.string("Failed to save index to flash\n");
            TOSH_uwait(30000L);
#endif
            post FailRespond2();
        }        
    }

    /***********
     * This saves the index from memory to flash
     ***********/
    task void save_l1_index()
    {
#ifdef INDEX_DEBUG
        call Console.string("In Index.save_l1_index\n");
        TOSH_uwait(30000L);
#endif

        /* Save the current page */
        if (local[indexif_id].buffModify == TRUE)
        {
            if (SUCCESS != call Array.save[indexif_id](&local[
                            indexif_id].buffer.ptr[local[indexif_id].old_indexptr]))
            {
#ifdef INDEX_DEBUG
                call Console.string("Saving current level 1 index failed\n");
                TOSH_uwait(30000L);
#endif
                post FailRespond();
            }
	    else
	    {
#ifdef INDEX_DEBUG
                call Console.string("Array.save SUCCESS\n");
                TOSH_uwait(30000L);
#endif
	    }
        }
        else if (state == SAVING)
	{
#ifdef INDEX_DEBUG
            call Console.string("Posting saveTask\n");
            TOSH_uwait(30000L);
#endif

            post saveTask();
	}
	else if (state == SETTING)
	{
#ifdef INDEX_DEBUG
            call Console.string("Posting loadArrPage\n");
            TOSH_uwait(30000L);
#endif

	    post loadArrPage();
	}
    }


    command result_t Index.save[uint8_t id](flashptr_t *save_ptr)
    {
        if (lock() != SUCCESS)
        {
#ifdef LOCK_DEBUG
            call Console.string("ERROR ! Unable to acquire index save lock\n");
            TOSH_uwait(30000L);
#endif
            return (FAIL);
        }
#ifdef LOCK_DEBUG
        call Console.string("Acquired index save lock\n");
        TOSH_uwait(30000L);
#endif

        Tsave_ptr = save_ptr;
        indexif_id = id;

        state2 = state = SAVING;

        post save_l1_index();

        return (SUCCESS);
    }
    
    /***********
     * This sets a (key, value) pair into the Index
     ***********/
    command result_t Index.set[uint8_t id](unsigned int arr_index, void *data, 
                                           datalen_t len, flashptr_t *save_ptr)
    {
		//call Leds.redOn();
		
        if (lock() != SUCCESS)
        {
#ifdef LOCK_DEBUG
            call Console.string("ERROR ! Unable to acquire index set lock\n");
            TOSH_uwait(30000L);
#endif
            return (FAIL);
        }
		
#ifdef LOCK_DEBUG
        call Console.string("Acquired index set lock\n");
        TOSH_uwait(30000L);
#endif
#ifdef INDEX_DEBUG
        call Console.string("Set index: ");
        call Console.decimal(arr_index);
        call Console.string(" if: ");
        call Console.decimal(id);
        call Console.string(" data: ");
        call Console.decimal(data);
        call Console.string(" len: ");
        call Console.decimal(len);
        call Console.string("\n");
        TOSH_uwait(30000L);
#endif

        /* Calculate data storage location */
        Tindex = arr_index / ARRAY_ELEMENTS_PER_CHUNK;
        Tarrindex = arr_index % ARRAY_ELEMENTS_PER_CHUNK;

        Tdata = data;
        Tlen = len;
        Tsave_ptr = save_ptr;
        indexif_id = id;

        /*
        {
            int i;
            char *temp = data;
            call Console.string( "\nPB2:" );
            for (i=0; i < len; i++)
            {
                call Console.string( " " );
                call Console.decimal(temp[i]);
                TOSH_uwait(2000);
            }
            call Console.printf2("\nPB Tindex: %d Tarrindex:%d", Tindex, Tarrindex);
            call Console.string( "\n\n" );
        }
        */

        /* If new page being accessed is different -> 
              save currently loaded page and load relevant page */

        if (local[id].old_indexptr == 0xFFFF)
        {
#ifdef INDEX_DEBUG
            call Console.string("New component - will have to load page...\n");
            TOSH_uwait(30000L);
#endif
            state2 = state = SETTING;
            post loadArrPage();
        }
	else if(local[id].old_indexptr != Tindex)
        {
#ifdef INDEX_DEBUG
            call Console.string("Will have to load page...\n");
            TOSH_uwait(30000L);
#endif
            state2 = state = SETTING;
            post save_l1_index();
        }
        else
        {
			
#ifdef INDEX_DEBUG
            call Console.string("Page already loaded. saving data...\n");
            TOSH_uwait(30000L);
#endif
       
            /* Relevant page is already loaded */
            post saveData();
        }
		
        return (SUCCESS);
    }


    task void loadArrPage()
    {
        flashptr_t temp;

        memset(&temp, 0xFF, sizeof(flashptr_t));

        /* Check if the lower level array page exists */
        if (0 == memcmp(&local[indexif_id].buffer.ptr[Tindex],
                        &temp, sizeof(flashptr_t)))
        {
#ifdef INDEX_DEBUG
            call Console.string("Level 1 page doesnt exist\n");
            TOSH_uwait(30000L);
#endif

            /* Lower level array page does not exist -> load a new one */
            if (SUCCESS != call Array.load[indexif_id](NULL, TRUE, local[indexif_id].doEcc))
            {
#ifdef LOCK_DEBUG
                call Console.string("Level 1 index load failed\n");
                TOSH_uwait(30000L);
#endif
                post FailRespond();
            }
        }
        else
        {
#ifdef INDEX_DEBUG
            call Console.string("Loading level 1 index page : ");
            call Console.decimal(Tindex);
            call Console.string(" if: ");
            call Console.decimal(indexif_id);
            call Console.string(" from page: ");
            call Console.decimal(local[indexif_id].buffer.ptr[Tindex].page);
            call Console.string(" off: ");
            call Console.decimal(local[indexif_id].buffer.ptr[Tindex].offset);
            call Console.string("\n");
            TOSH_uwait(30000L);
#endif

            /* Load level 1 index */
            if (SUCCESS != call Array.load[indexif_id](&local[indexif_id].buffer.ptr[Tindex],
                                            FALSE, FALSE))
            {
#ifdef INDEX_DEBUG
                call Console.string("Loading the level 1 index failed\n");
                TOSH_uwait(30000L);
#endif
                post FailRespond();
            }
        }
    }

    event void Array.saveDone[uint8_t id](result_t res)
    {
        if (res == SUCCESS)
        {
            local[indexif_id].buffModify = FALSE;

            if (state == SAVING)
                post saveTask();
            else
                post loadArrPage();

#ifdef INDEX_DEBUG
            call Console.string("Saved level 1 index page : ");
            call Console.decimal(Tindex);
            call Console.string(" to page: ");
            call Console.decimal(local[indexif_id].buffer.ptr[local[indexif_id].old_indexptr].page);
            call Console.string(" off: ");
            call Console.decimal(local[indexif_id].buffer.ptr[local[indexif_id].old_indexptr].offset);
            call Console.string("\n");
            TOSH_uwait(6000);

            {
                int i;

                for (i=0; i < INDEX_ELEMENTS_PER_CHUNK; i++)
                {
                    call Console.string("Element:");
                    call Console.decimal(i);
                    call Console.string(" page: ");
                    call Console.decimal(local[indexif_id].buffer.ptr[i].page);
                    call Console.string(" off: ");
                    call Console.decimal(local[indexif_id].buffer.ptr[i].offset);
                    call Console.string("\n");
                    TOSH_uwait(30000L);
                }
            }
#endif
        }
        else
        {
#ifdef INDEX_DEBUG
            call Console.string("Saving level 1 index failure\n");
            TOSH_uwait(30000L);
#endif
            post FailRespond();
        }
    }

    task void saveData()
    {
#ifdef INDEX_DEBUG
        call Console.string("In Index.savedata : Tarrindex ");
        call Console.decimal(Tarrindex);
        call Console.string(" Tlen ");
        call Console.decimal(Tlen);
        call Console.string(" indexif_id ");
        call Console.decimal(indexif_id);
        call Console.string(" Tindex ");
        call Console.decimal(Tindex);
        call Console.string("\n");
        TOSH_uwait(30000L);
#endif

        local[indexif_id].buffModify = TRUE;

        /* Write the data */
        if(SUCCESS != call Array.set[indexif_id](Tarrindex, Tdata, Tlen, 
                                     &local[indexif_id].buffer.ptr[Tindex]))
        {
#ifdef INDEX_DEBUG
            call Console.string("Setting index data failed\n");
            TOSH_uwait(30000L);
#endif
            post FailRespond();
        }
    }

    event void Array.setDone[uint8_t id](result_t res)
    {
#ifdef INDEX_DEBUG
        if (res == SUCCESS)
            call Console.string("Setting array success\n");
        else
            call Console.string("Setting array failed\n");
        TOSH_uwait(30000L);
#endif

        if ((res == SUCCESS) && (Tsave_ptr != NULL))
            memcpy (Tsave_ptr, &local[indexif_id].buffer.ptr[Tindex], sizeof(flashptr_t));
        
        unlock();
#ifdef LOCK_DEBUG
        call Console.string("Released index set lock\n");
        TOSH_uwait(30000L);
#endif
        if (!compacting)
            signal Index.setDone[indexif_id](res);
        else
        {
            local[indexif_id].compactptr++;

            if (local[indexif_id].compactptr < COUNT)
                post compact_get();
            else
            {
                compacting = FALSE;
                signal Compaction.compactionDone[indexif_id](SUCCESS);
            }
        }
    }

    /***********
     * This gets the value associated with a key
     ***********/
    command result_t Index.get[uint8_t id](unsigned int arr_index, void *data, 
                                           datalen_t *len)
    {
        if (lock() != SUCCESS)
        {
#ifdef LOCK_DEBUG
            call Console.string("ERROR ! Unable to acquire index get lock\n");
            TOSH_uwait(30000L);
#endif
            return (FAIL);
        }
#ifdef LOCK_DEBUG
        call Console.string("Acquired index get lock\n");
#endif
#ifdef INDEX_DEBUG
        call Console.string("Get index: ");
        call Console.decimal(arr_index);
        call Console.string(" if: ");
        call Console.decimal(id);
        call Console.string(" data: ");
        call Console.decimal(data);
        call Console.string(" len: ");
        call Console.decimal(len);
        call Console.string("\n");
        TOSH_uwait(30000L);
#endif

        /* Calculate data storage location */
        Tindex = arr_index / ARRAY_ELEMENTS_PER_CHUNK;
        Tarrindex = arr_index % ARRAY_ELEMENTS_PER_CHUNK;
        Tdata = data;
        Tlen_ = len;
        indexif_id = id;
       
        state2 = state = GETTING;
#ifdef INDEX_DEBUG
            call Console.string("Tindex=");
            call Console.decimal(Tindex);
            call Console.string(" local[indexif_id].old_indexptr=");
            call Console.decimal(local[indexif_id].old_indexptr);
            call Console.string("\n");
            TOSH_uwait(30000L);
#endif


        if (Tindex == local[indexif_id].old_indexptr)
        {
#ifdef INDEX_DEBUG
            call Console.string("Index already loaded -- getting data.");
            TOSH_uwait(30000L);
#endif
            /* Level 1 index is already loaded */
            post loadData();
        }
        else if (local[indexif_id].old_indexptr == 0xFFFF)
        {
#ifdef INDEX_DEBUG
            call Console.string("New components -- loading l1 index.");
            TOSH_uwait(30000L);
#endif
            post loadArrPage();
        }
        else
        {
#ifdef INDEX_DEBUG
            call Console.string("Saving l1 index.");
            TOSH_uwait(30000L);
#endif

            /* Save the current page */
            if (SUCCESS != call Array.save[indexif_id](&local[id].buffer.ptr[local[id].old_indexptr]))
            {
#ifdef INDEX_DEBUG
                call Console.string("Saving current level 1 index failed\n");
                TOSH_uwait(30000L);
#endif
                unlock();
                return (FAIL);
            }
        }
        
        return (SUCCESS);
    }

    event void Array.loadDone[uint8_t id](result_t res)
    {
        if (res == SUCCESS)
        {
#ifdef INDEX_DEBUG
            call Console.string("In Array.loadDone()\n");
            TOSH_uwait(30000L);
#endif

            local[indexif_id].old_indexptr = Tindex;
            local[indexif_id].buffModify = FALSE;

            if (state == SETTING)
            {
                post saveData();
            }
            else if (state == GETTING)
            {
                post loadData();
            }
	        else if (state == DELETING)
	        {
        		post deleteData();
	        }

        }
        else
        {
#ifdef INDEX_DEBUG
            call Console.string("Loading level 1 index failure\n");
            TOSH_uwait(30000L);
#endif
            post FailRespond();
        }
    }


    task void deleteData()
    {
#ifdef INDEX_DEBUG
        call Console.string("Index.deletedata : Tarrindex ");
        call Console.decimal(Tarrindex);
    	call Console.string(" indexif_id ");
	    call Console.decimal(indexif_id);
    	call Console.string(" Tindex ");
	    call Console.decimal(Tindex);
     	call Console.string("\n");
	    TOSH_uwait(5000);
#endif

        local[indexif_id].buffModify = TRUE;

        /* Write the data */
        if(SUCCESS != call Array.delete[indexif_id](Tarrindex))
	   {
#ifdef INDEX_DEBUG
            call Console.string("Dltng ndx dt fld\n");
            TOSH_uwait(30000L);
#endif
            post FailRespond();
    	}

	    unlock();
    	signal Index.deleteDone[indexif_id](SUCCESS);
    }

    task void loadData()
    {
        /* Now get the data */
        if (SUCCESS != call Array.get[indexif_id](Tarrindex, Tdata, Tlen_))
        {
#ifdef INDEX_DEBUG
            call Console.string("Level 1 index loading failure\n");
            TOSH_uwait(30000L);
#endif
            post FailRespond();
        }

    }

    event void Array.getDone[uint8_t id](result_t res)
    {
#ifdef INDEX_DEBUG
        call Console.string("In Array.getDone : Tarrindex ");
        call Console.decimal(Tarrindex);
        if (Tlen_ != NULL)
        {
            call Console.string(" Tlen_ ");
            call Console.decimal(*Tlen_);
        }
        call Console.string("\n");
        TOSH_uwait(30000L);
#endif

        unlock();
#ifdef LOCK_DEBUG
        call Console.string("Released index get lock\n");
        TOSH_uwait(30000L);
#endif

        if (!compacting)
            signal Index.getDone[indexif_id](res);
        else
            post compact_set();
    }

    event void ChunkStorage.writeDone(result_t result)
    {
        /* Just saved the index page */
        if (result == SUCCESS)
        {
            if(Tsave_ptr != NULL)
                memcpy(Tsave_ptr, &local[indexif_id].head, sizeof(flashptr_t));
      
#ifdef INDEX_DEBUG
            call Console.string("Saved level 2 index page.");
#endif
        }
        else
        {
#ifdef INDEX_DEBUG
            call Console.string("ERROR ! While saving level 2 index page : ");
#endif
        }

        unlock();

        signal Index.saveDone[indexif_id](result);
    }

    event void ChunkStorage.readDone(result_t result)
    {
        /* Just read in the index page */
        if (result == SUCCESS)
        {
#ifdef INDEX_DEBUG
            call Console.string("Loaded level 2 index page.\n");

            {
                int i;

                for (i=0; i < INDEX_ELEMENTS_PER_CHUNK; i++)
                {
                    call Console.string("Element:");
                    call Console.decimal(i);
                    call Console.string(" page: ");
                    call Console.decimal(local[indexif_id].buffer.ptr[i].page);
                    call Console.string(" off: ");
                    call Console.decimal(local[indexif_id].buffer.ptr[i].offset);
                    call Console.string("\n");
                    TOSH_uwait(30000L);
                }
            }
#endif
        }
        else
        {
#ifdef INDEX_DEBUG
            call Console.string("ERROR ! While loading level 2 index page : ");
#endif
        }

        unlock();

        signal Index.loadDone[indexif_id](result);
    }

    event void ChunkStorage.flushDone(result_t result)
    {
    }
	
	

	
	command result_t Index.delete[uint8_t id](unsigned int arr_index)
    {
        if (lock() != SUCCESS)
        {
#ifdef LOCK_DEBUG
            call Console.string("ERROR ! Unable to acquire index delete lock\n");
            TOSH_uwait(30000L);
#endif
            return (FAIL);
        }
#ifdef LOCK_DEBUG
        call Console.string("Acquired index delete lock\n");
        TOSH_uwait(30000L);
#endif
#ifdef INDEX_DEBUG
        call Console.string("Delete index: ");
        call Console.decimal(arr_index);
        call Console.string("\n");
        TOSH_uwait(30000L);
#endif

        /* Calculate data storage location */
        Tindex = arr_index / ARRAY_ELEMENTS_PER_CHUNK;
        Tarrindex = arr_index % ARRAY_ELEMENTS_PER_CHUNK;

        indexif_id = id;
        
        /* If new page being accessed is different -> 
              save currently loaded page and load relevant page */
        if(local[id].old_indexptr != Tindex)
        {
#ifdef INDEX_DEBUG
            call Console.string("Will have to load page...\n");
            TOSH_uwait(30000L);
#endif
            state2 = state = DELETING;
            post save_l1_index();
        }
        else
        {
#ifdef INDEX_DEBUG
            call Console.string("Page already loaded. saving data...\n");
            TOSH_uwait(30000L);
#endif
       
            /* Relevant page is already loaded */
            post deleteData();
        }

        return (SUCCESS);
    }

    /*
     * Checkpoint / restore
     */
    command result_t Serialize.checkpoint[uint8_t id](uint8_t *buffer, datalen_t *len)
    {
#ifdef CHECKPOINT_DEBUG
        call Console.string("Checkpointing Index, id=");
        call Console.decimal(id);
        call Console.string("\n");
        TOSH_uwait(30000L);
#endif

        memcpy (&buffer[*len], &local[id].head, sizeof(flashptr_t));
        *len += sizeof(flashptr_t);

        return (SUCCESS);
    }

    command result_t Serialize.restore[uint8_t id](uint8_t *buffer, datalen_t *len)
    {
#ifdef CHECKPOINT_DEBUG
        call Console.string("Restoring Index, id=");
        call Console.decimal(id);
        call Console.string("\n");
        TOSH_uwait(30000L);
#endif
        memcpy (&local[id].head, &buffer[*len], sizeof(flashptr_t));
        *len += sizeof(flashptr_t);

        return (SUCCESS);
    }

    task void compact_get()
    {
        if (SUCCESS != call Index.get[indexif_id](local[indexif_id].compactptr, local[indexif_id].buff, &local[indexif_id].clen))
        {
#ifdef COMPACT_DEBUG
            call Console.string("ERROR ! Unable to get index data\n");
            TOSH_uwait(30000L);
#endif
        }
    }

    task void compact_set()
    {
        if (SUCCESS != call Index.set[indexif_id](local[indexif_id].compactptr, local[indexif_id].buff, local[indexif_id].clen, NULL))
        {
#ifdef COMPACT_DEBUG
            call Console.string("ERROR ! Unable to get index data\n");
            TOSH_uwait(30000L);
#endif
        }
    }

    command result_t Compaction.compact[uint8_t id](uint8_t againgHint)
    {
        indexif_id = id;
        compacting = TRUE;
        post compact_get();

        return (SUCCESS);
    }

    command void RootPtrAccess.setPtr[uint8_t id](flashptr_t *setPtr)
    {
#ifdef FILE_DEBUG
		call Console.string("id = ");
        call Console.decimal(id);
		call Console.string(", setting index root ptr, pg=");
        call Console.decimal(setPtr->page);
        call Console.string(" off=");
        call Console.decimal(setPtr->offset);
        call Console.string("\n");
        TOSH_uwait(50000L);
#endif

        memcpy(&local[id].head, setPtr, sizeof(flashptr_t));
    }

    command void RootPtrAccess.getPtr[uint8_t id](flashptr_t *getPtr)
    {
        memcpy(getPtr, &local[id].head, sizeof(flashptr_t));

#ifdef CHECKPOINT_DEBUG
		call Console.string("Got index root ptr, id=");
		call Console.decimal(id);
        call Console.string(", pg=");
        call Console.decimal(local[id].head.page);
        call Console.string(" off=");
        call Console.decimal(local[id].head.offset);
        call Console.string("\n");
        TOSH_uwait(50000L);
#endif
    }

    event void Console.input(char *s)
    {
    }

    default event void Index.setDone[uint8_t id](result_t res)
    {
    }

    default event void Index.getDone[uint8_t id](result_t res)
    {}
    
    default event void Index.loadDone[uint8_t id](result_t res)
    {}

    default event void Index.saveDone[uint8_t id](result_t res)
    {}

    default event void Index.deleteDone[uint8_t id](result_t res)
    {}

    default event void Compaction.compactionDone[uint8_t id](result_t res)
    {}
}
