/*
 * file:        RootDirectoryM.nc
 * description: Root directory implementation
 */

/*
 * Root page implementation
 */

includes app_header;
includes common_header;

module RootDirectoryM {
    provides interface RootDirectory;
    provides interface StdControl;

    uses {
        interface GenericFlash;
        interface Leds;
        interface Console;
        interface Crc8;
    }
}

implementation 
{
    enum {NONE, RECOVERING, FINAL_RECOVERING, SETTING, GETTING};
    bool busy;
    pageptr_t page = DELUGE_AREA;
    offsetptr_t offset = 0;
    uint16_t currentTime, besttime = 0;
    pageptr_t bestpage = 0;
    offsetptr_t bestoffset = 0;

    bool loaded = FALSE;
    uint8_t state;
    root_header root;

    task void eraser();


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
   

    /********* Initialize *********/

    /* 
       This method actually goes ahead and initializes the system 
       - if there are no checkpoints in the root dir area, then its a fresh start
       - if a checkpoint is found, then the system recovers to it
       - this recovery process does not happen while the system is running as
         without checkpointed data, storage of additional data would create 
         inconsistency in the storage objects
       - while running, if init is called it does nothing and signal a SUCCESS
     */
    task void signalInit()
    {
        loaded = TRUE;
        unlock();
        signal RootDirectory.initDone(SUCCESS);
    }

    command result_t StdControl.init() 
    {
        currentTime = 1;
        return (SUCCESS);
    }

    task void recoverRoot()
    {
#ifdef ROOT_DIR_DEBUG
            call Console.string("Looking for root chunk at pg:");
            call Console.decimal(page);
            call Console.string(" off:");
            call Console.decimal(offset);
            call Console.string("\n");
            TOSH_uwait(20000);
#endif

        /* We need to locate the last valid root and load it */
        if(SUCCESS != call GenericFlash.read(page, offset,
                                             &root, sizeof(root_header)))
        {
#ifdef ROOT_DIR_DEBUG
            call Console.string("ERROR ! Root chunk load failed from pg:");
            call Console.decimal(page);
            call Console.string(" off:");
            call Console.decimal(offset);
            call Console.string("\n");
            TOSH_uwait(3000);
#endif
            call Leds.redOn();
        }
    }

    command result_t StdControl.start()
    {
        if (SUCCESS != lock())
        {
#ifdef ROOT_DIR_DEBUG
            call Console.string("ERROR ! Unable to acquire lock");
            call Console.string("\n");
            TOSH_uwait(3000);
#endif

            return (FAIL);
        }

        if (loaded == TRUE)
        {
            /* Do nothing */
            post signalInit();
            return (SUCCESS);
        }

        /* First time... Go to recovery state*/
        page = DELUGE_AREA; offset = 0;
        post recoverRoot();
        state = RECOVERING;

        return (SUCCESS);
    }

    command result_t StdControl.stop()
    {
        return (SUCCESS);
    }

    event result_t GenericFlash.readDone(result_t result)
    {
        switch(state)
        {
            case(RECOVERING):    
                if ((root.timestamp != 0xFFFF) && (root.timestamp > besttime))
                {
                    uint8_t tCrc;
#ifdef ROOT_DIR_DEBUG
                    call Console.string("Latest time... time :");
                    call Console.decimal(root.timestamp);
                    call Console.string(" pg:");
                    call Console.decimal(page);
                    call Console.string(" off:");
                    call Console.decimal(offset);
                    call Console.string("\n");
                    TOSH_uwait(3000);
#endif

                    tCrc = root.crc;
                    root.crc = 0;
                    if (tCrc != call Crc8.crc8((uint8_t *)&root, sizeof(root_header), 0))
                    {
#ifdef ROOT_DIR_DEBUG
                        call Console.string("CRC failed\n");
                        TOSH_uwait(3000);
#endif
                    }
                    else
                    {
#ifdef ROOT_DIR_DEBUG
                        call Console.string("CRC success\n");
                        TOSH_uwait(3000);
#endif
                    }

                    besttime = root.timestamp;
                    bestpage = page;
                    bestoffset = offset;
                }

                /* Look at the next entry in the root directory */                        
                if ((PAGE_SIZE - offset) >= sizeof(root_header))
                {
                    offset += sizeof(root_header);
                }
                else 
                {
                    /* Goto next page */
                    offset = 0; page++;

                    if (page >= (DELUGE_AREA + ROOT_DIRECTORY_AREA) * ERASE_BLOCK_SIZE)
                    {
                        /* We scanned all of the root area -> now lets see the results */
                        if (besttime == 0)
                        {
                            /* We never wrote any root directory information */
                            /* Start at the head & we are done */
                            page = DELUGE_AREA; offset = 0;
                            post signalInit();

                            return (SUCCESS);
                        }
                        else
                        {
                            /* We found the most current data here -> reload that entry */
                            page = bestpage;
                            offset = bestoffset;
                            currentTime = besttime + 1;
							state = FINAL_RECOVERING;
#ifdef ROOT_DIR_DEBUG
                        	call Console.string("Latest data -- pg:");
                        	call Console.decimal(page);
							call Console.string(" offset:");
							call Console.decimal(offset);
							call Console.string("\n");
                        	TOSH_uwait(30000L);
#endif

                        }
                    }
                }

                post recoverRoot();

                break;

            case(FINAL_RECOVERING):
                /* Just finished loading the last accurate root page... */
                /* We dont know the number of writes done in this page -> Goto next page */
                offset = 0; page++;
                if (page == (DELUGE_AREA + ROOT_DIRECTORY_AREA) * ERASE_BLOCK_SIZE)
                {
/*
#ifdef ROOT_DIR_DEBUG
                    call Console.string("page == (D_A + RDA) * EBS\n");
                    TOSH_uwait(30000L);
#endif
*/
                    page = DELUGE_AREA;
                }

                if (!(page % ERASE_BLOCK_SIZE))
				{
					/*
#ifdef ROOT_DIR_DEBUG
                    call Console.string("posting eraser\n");
                    TOSH_uwait(30000L);
#endif
					*/

					post eraser();
				}
                /* Signal a restore to all checkpointed objects */
                post signalInit();
                signal RootDirectory.restore(root.root);

                break;
        }

        return (SUCCESS);
    }

    /********* Set root *********/

    command result_t RootDirectory.setRoot(uint8_t id, flashptr_t *save)
    {
        if (SUCCESS != lock())
            return (FAIL);

        memcpy (&root.root[id], save, sizeof(flashptr_t));

        root.timestamp = currentTime++;
        root.crc = 0;
        root.crc = call Crc8.crc8((uint8_t *) &root, sizeof(root_header), 0);

#ifdef ROOT_DIR_DEBUG
        {
            int i;

            call Console.string("Writing root... time:");
            call Console.decimal(root.timestamp);
            call Console.string(" size:");
            call Console.decimal(sizeof(root));
            call Console.string(" ");
            TOSH_uwait(6000);

            for (i=0; i < NUM_CHECKPOINTS; i++)
            {
                call Console.string("(id:");
                call Console.decimal(i);
                call Console.string(", pg:");
                call Console.decimal(root.root[id].page);
                call Console.string(", off:");
                call Console.decimal(root.root[id].offset);
                call Console.string(")");
                TOSH_uwait(8000);
            }
            call Console.string("\n");
        }
#endif

        /* Write the root page */
        if(SUCCESS != call GenericFlash.write(page, offset, 
                                              &root, sizeof(root_header)))
        {
#ifdef ROOT_DIR_DEBUG
            call Console.string("ERROR ! Root dir commit failed to page number:");
            call Console.decimal(page);
            call Console.string(" off:");
            call Console.decimal(offset);
            call Console.string("\n");
            TOSH_uwait(3000);
#endif
            call Leds.redOn();
        }
        else
            state = SETTING;

        return (SUCCESS);
    }


    event result_t GenericFlash.writeDone(result_t result)
    {
#ifdef ROOT_DIR_DEBUG
        if (result == SUCCESS)
            call Console.string("Root dir committed to pg:");
        else
            call Console.string("Root dir NOT committed to pg:");

        call Console.decimal(page);
        call Console.string(" off:");
        call Console.decimal(offset);
        call Console.string("\n");
        TOSH_uwait(3000);
#endif

        /* Find next location to write the root */
        if ((PAGE_SIZE - offset) >= sizeof(root_header))
        {
            offset += sizeof(root_header);
        }
        else 
        {
            /* Goto next page */
            offset = 0; page++;

            if (page == (DELUGE_AREA + ROOT_DIRECTORY_AREA) * ERASE_BLOCK_SIZE)
            {
                /* Cycle back */
                page = DELUGE_AREA;
            }

            /* Also erase next page */
#ifdef ROOT_DIR_DEBUG
            call Console.string("Rootdir: Need to erase pg#");
            call Console.decimal(page);
            call Console.string("\n");
#endif
            if (!(page % ERASE_BLOCK_SIZE))
                post eraser();
        }

        unlock();

        signal RootDirectory.setRootDone(result);

        return (SUCCESS);
    }

    
    task void eraser()
    {
#ifdef ROOT_DIR_DEBUG
            call Console.string("Erasing: ");
            call Console.decimal(page);
			call Console.string("\n");
			TOSH_uwait(30000L);
#endif
		
        if(SUCCESS != call GenericFlash.erase(page))
        {
            call Leds.redOn();
#ifdef ROOT_DIR_DEBUG
            call Console.string("ERROR ! Erase failed on pg:");
            call Console.decimal(page);
            call Console.string("\n");
            TOSH_uwait(3000);
#endif
        }
    }

    /********* Get root *********/

    task void signalGetRoot()
    {
        unlock();
    
        signal RootDirectory.getRootDone(SUCCESS);
    }

    command result_t RootDirectory.getRoot(uint8_t id, flashptr_t *ptr)
    {
        if (SUCCESS != lock())
            return (FAIL);

/*
#ifdef ROOT_DIR_DEBUG
        {
            int i;

            call Console.string("Current root... time:");
            call Console.decimal(root.timestamp);
            call Console.string(" size:");
            call Console.decimal(sizeof(root));
            call Console.string(" ");
            TOSH_uwait(6000);

            for (i=0; i < NUM_CHECKPOINTS; i++)
            {
                call Console.string("(id:");
                call Console.decimal(i);
                call Console.string(", pg:");
                call Console.decimal(root.root[id].page);
                call Console.string(", off:");
                call Console.decimal(root.root[id].offset);
                call Console.string(")");
                TOSH_uwait(8000);
            }
            call Console.string("\n");
        }
#endif
*/

        /* Read it from the memory */
        memcpy (ptr, &root.root[id], sizeof(flashptr_t));

        post signalGetRoot();

        return (SUCCESS);        
    }

    event result_t GenericFlash.eraseDone(result_t result)
    {
        return (SUCCESS);
    }

    event result_t GenericFlash.falReadDone(result_t result)
    {
        return (SUCCESS);
    }

    event result_t GenericFlash.initDone(result_t result)
    {
        return (SUCCESS);
    }

    event void Console.input(char *s)
    {
    }
}
