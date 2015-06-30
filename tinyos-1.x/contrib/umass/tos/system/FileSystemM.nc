/*
 * file:        FileSystemM.nc
 * description: FileSystem operation implementation
 */

/*
 * Checkpoint implementation
 */

includes app_header;
includes common_header;

module FileSystemM {
	provides interface FileSystem;
    provides interface Serialize;
    provides interface StdControl;
	
	uses {
		interface Leds;
#ifdef FS_DEBUG
		interface Console;
#endif
        interface ChunkStorage;
        interface Checkpoint;
	}
}

implementation 
{
    /* States for the FS */
    enum {CREATE, DELETE, FLUSH, UPDATE_FILE_ROOT};

    uint8_t state;             /* Tracks the state of the component */
    flashptr_t fat;
    filesystem fsdata;
    bool busy = FALSE;
    result_t Res;

	task void FSinit();

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

    /************************************************
     ************  Read/Write to Flash **************
     ************************************************/

    task void signaler()
    {
        unlock();

        if (state == CREATE)
            signal FileSystem.createDone(Res);
        else if (state == DELETE)
            signal FileSystem.deleteDone(Res);
        else if (state == FLUSH)
            signal FileSystem.flushDone(Res);
        else if (state == UPDATE_FILE_ROOT)
            signal FileSystem.updateFileDataDone(Res);
    }


    task void write()
    {
        /*
#ifdef FS_DEBUG
        {
            int i;
            uint8_t *ptr = (uint8_t *) &fsdata;

            for (i=0; i<sizeof(filesystem); i++)
            {
                call Console.decimal(i);
                call Console.string(":");
                call Console.decimal(*ptr); ptr++;
                call Console.string("\n");
                TOSH_uwait(40000L);
            }
        }
#endif
        */

        if (SUCCESS != call ChunkStorage.write(NULL, 0,
                                               &fsdata, sizeof(filesystem),
                                               TRUE, &fat))
        {
            call Leds.redOn();
#ifdef FS_DEBUG
            call Console.string("FS data write failure\n");
            TOSH_uwait(20000);
#endif
            Res = FAIL;
            post signaler();
        }
    }
    

    event void ChunkStorage.writeDone(result_t res)
    {
        if (res != SUCCESS)
        {
            call Leds.redOn();
#ifdef FS_DEBUG
            call Console.string("FS data write returned failure\n");
            TOSH_uwait(20000);
#endif
            Res = res;
            post signaler();
            return;
        }

#ifdef FS_DEBUG
        call Console.string("FS data written to page: ");
        call Console.decimal(fat.page);
        call Console.string(" offset: ");
        call Console.decimal(fat.offset);
        call Console.string("\n");
        TOSH_uwait(20000);
#endif

        if (SUCCESS != call Checkpoint.checkpoint())
        {
            call Leds.redOn();
#ifdef FS_DEBUG
            call Console.string("FS checkpointing failure\n");
            TOSH_uwait(20000);
#endif
            Res = res;
            post signaler();
        }
    }

    event void Checkpoint.checkpointDone(result_t res)
    {
        Res = res;
        post signaler();
    }

    event void Checkpoint.rollbackDone(result_t res)
    {
    }

    bool ecc;
    task void read()
    {
        datalen_t len;

#ifdef FS_DEBUG
        call Console.string("Going to read FS data from page: ");
        call Console.decimal(fat.page);
        call Console.string(" offset: ");
        call Console.decimal(fat.offset);
        call Console.string("\n");
        TOSH_uwait(30000L);
#endif

        if (SUCCESS != call ChunkStorage.read(&fat, NULL, 0,
                                              &fsdata, &len,
                                              TRUE, &ecc))
        {
            call Leds.redOn();
#ifdef FS_DEBUG
            call Console.string("FS data read failure -- fat page: ");
            call Console.decimal(fat.page);
            call Console.string(" offset: ");
            call Console.decimal(fat.offset);
            call Console.string("\n");
            TOSH_uwait(30000L);
#endif
            unlock();
            signal FileSystem.initDone(FAIL);
        }
    }

    event void ChunkStorage.readDone(result_t res)
    {
        if (res != SUCCESS)
        {
            call Leds.redOn();
#ifdef FS_DEBUG
            call Console.string("FS data read returned failure\n");
            TOSH_uwait(20000);
#endif
        }

        unlock();
        signal FileSystem.initDone(res);
    }

    /*****************************************
     ************  FS functions **************
     *****************************************/

	command result_t StdControl.init()
    {
        fileptr_t i;

        memset(&fsdata, 0, sizeof(fsdata));

        /* Default stateof the FS should be clean */
        for (i=0; i<MAX_FILES; i++)
            fsdata.data[i].invalid = TRUE;

        memset(&fat, 0xFF, sizeof(fat));

        return (SUCCESS);
    }

	command result_t StdControl.stop()
    {
        return (SUCCESS);
    }

	command result_t StdControl.start()
    {
        return (SUCCESS);
    }

	task void FSinit()
    {
        flashptr_t tempcmp;

        if (lock() != SUCCESS)
        {
#ifdef FS_DEBUG
            call Console.string("ERROR ! Unable to acquire FS-init lock\n");
            TOSH_uwait(20000);
#endif
            signal FileSystem.initDone(FAIL);
        }
#ifdef FS_DEBUG
        call Console.string("Acquired FS-init lock\n");
#endif

        memset(&tempcmp, 0xFF, sizeof(tempcmp));
        if ( memcmp(&tempcmp, &fat, sizeof(fat)) == 0 )
        {
#ifdef FS_DEBUG
            call Console.string("FS is fresh\n");
            TOSH_uwait(20000);
#endif

            unlock();
            signal FileSystem.initDone(SUCCESS);
        }
        else
        {
#ifdef FS_DEBUG
            call Console.string("Reading FS-init data\n");
            TOSH_uwait(20000);
#endif
            post read();
        }
    }

    command result_t FileSystem.flush()
    {
        if (lock() != SUCCESS)
        {
#ifdef FS_DEBUG
            call Console.string("ERROR ! Unable to acquire FS-flush lock\n");
            TOSH_uwait(20000);
#endif
            return (FAIL);
        }
#ifdef FS_DEBUG
        call Console.string("Acquired FS-flush lock\n");
#endif

        state = FLUSH;
        post write();
    }

    command result_t FileSystem.lookup(char *fileName, fileptr_t *id)
    {
        fileptr_t i;

        for (i=0; i<MAX_FILES; i++)
            if (strcmp(fsdata.data[i].name, fileName) == 0)
            {
#ifdef FS_DEBUG
                call Console.string("Lookup ok filename ");
                call Console.string(fileName);
                call Console.string("with id ");
                call Console.decimal(i);
                call Console.string("\n");
                TOSH_uwait(20000);
#endif

                if (id != NULL)
                    *id = i;
                return (SUCCESS);
            }

#ifdef FS_DEBUG
        call Console.string("Lookup failed for ");
        call Console.string(fileName);
        call Console.string("\n");
        TOSH_uwait(20000);
#endif
        return (FAIL);
    }

    command result_t FileSystem.create(char *fileName)
    {
        int i;

        if (lock() != SUCCESS)
        {
#ifdef FS_DEBUG
            call Console.string("ERROR ! Unable to acquire FS-create lock\n");
            TOSH_uwait(20000);
#endif
            return (FAIL);
        }
#ifdef FS_DEBUG
        call Console.string("Acquired FS-create lock\n");
#endif

        for (i=0; i<MAX_FILES; i++)
            if (fsdata.data[i].invalid == TRUE)
            {
                /* Found empty space for file */
                strcpy (fsdata.data[i].name, fileName);
                fsdata.data[i].invalid = FALSE;
                fsdata.data[i].length = 0;
                memset (&fsdata.data[i].start_ptr, 0xFF, sizeof(flashptr_t));

#ifdef FS_DEBUG
                call Console.string("Alloted filename ");
                call Console.string(fileName);
                call Console.string("with id ");
                call Console.decimal(i);
                call Console.string("\n");
                TOSH_uwait(20000);
#endif

                /* Flush to flash */
                state = CREATE;
                post write();

                return (SUCCESS);
            }

#ifdef FS_DEBUG
        call Console.string("Filesystem Full !\n");
        TOSH_uwait(20000);
#endif
        return (FAIL);
    }

    command result_t FileSystem.delete(uint8_t id)
    {
        if (fsdata.data[id].invalid == TRUE)
        {
#ifdef FS_DEBUG
            call Console.string("File with id ");
            call Console.decimal(id);
            call Console.string(" does not exist (FS.delete)\n");
            TOSH_uwait(20000);
#endif
            return (FAIL);
        }

        if (lock() != SUCCESS)
        {
#ifdef FS_DEBUG
            call Console.string("ERROR ! Unable to acquire FS-delete lock\n");
            TOSH_uwait(20000);
#endif
            return (FAIL);
        }
#ifdef FS_DEBUG
        call Console.string("Acquired FS-delete lock\n");
#endif

         fsdata.data[id].invalid = TRUE;

#ifdef FS_DEBUG
         call Console.string("Deleting file with id ");
         call Console.decimal(id);
         call Console.string("\n");
         TOSH_uwait(20000);
#endif

         /* Flush to flash */
         state = DELETE;
         post write();

         return (SUCCESS);
    }

    command result_t FileSystem.move(uint8_t id, char *fileName2)
    {
        if (fsdata.data[id].invalid == TRUE)
        {
#ifdef FS_DEBUG
            call Console.string("File with id ");
            call Console.decimal(id);
            call Console.string(" does not exist (FS.move)\n");
            TOSH_uwait(20000);
#endif
            return (FAIL);
        }

        strcpy (fsdata.data[id].name, fileName2);

#ifdef FS_DEBUG
        call Console.string("Renaming file with id ");
        call Console.decimal(id);
        call Console.string(" to ");
        call Console.string(fileName2);
        call Console.string("\n");
        TOSH_uwait(20000);
#endif

        return (SUCCESS);
    }

    command uint16_t FileSystem.getLength(uint8_t id)
    {
        if (fsdata.data[id].invalid == TRUE)
        {
#ifdef FS_DEBUG
            call Console.string("File with id ");
            call Console.decimal(id);
            call Console.string(" does not exist (FS.getLength)\n");
            TOSH_uwait(20000);
#endif
            return (FAIL);
        }

        return (fsdata.data[id].length);
    }

    command result_t FileSystem.updateLength(uint8_t id, uint16_t length)
    {
        if (fsdata.data[id].invalid == TRUE)
        {
#ifdef FS_DEBUG
            call Console.string("File with id ");
            call Console.decimal(id);
            call Console.string(" does not exist (FS.updateLength)\n");
            TOSH_uwait(20000);
#endif
            return (FAIL);
        }

        fsdata.data[id].length = length;

        return (SUCCESS);
    }

    command result_t FileSystem.getFileData(uint8_t id, file_header *ptr)
    {
        if (fsdata.data[id].invalid == TRUE)
        {
#ifdef FS_DEBUG
            call Console.string("File with id ");
            call Console.decimal(id);
            call Console.string(" does not exist (FS.getFileRoot)\n");
            TOSH_uwait(20000);
#endif
            return (FAIL);
        }

        memcpy (ptr, &fsdata.data[id], sizeof(file_header));

        return (SUCCESS);
    }

    command result_t FileSystem.updateFileData(uint8_t id, file_header *ptr)
    {
        if (fsdata.data[id].invalid == TRUE)
        {
#ifdef FS_DEBUG
            call Console.string("File with id ");
            call Console.decimal(id);
            call Console.string(" does not exist (FS.updateFileData)\n");
            TOSH_uwait(20000);
#endif
            return (FAIL);
        }

        memcpy (&fsdata.data[id], ptr, sizeof(file_header));

        /* Flush to flash */
        state = UPDATE_FILE_ROOT;
        post write();

        return (SUCCESS);
    }

    /**********************************************
     ************ Save/restore state **************
     **********************************************/

    command result_t Serialize.checkpoint(uint8_t *buffer, datalen_t *len)
    {
#ifdef CHECKPOINT_DEBUG
        call Console.string("Checkpointing FileSystem, pg=");
        call Console.decimal(fat.page);
        call Console.string(" off=");
        call Console.decimal(fat.offset);
        call Console.string("\n");
        TOSH_uwait(50000L);
#endif

        memcpy (&buffer[*len], &fat, sizeof(flashptr_t));
        *len += sizeof(flashptr_t);

        return (SUCCESS);
    }

    command result_t Serialize.restore(uint8_t *buffer, datalen_t *len)
    {
        memcpy (&fat, &buffer[*len], sizeof(flashptr_t));
        *len += sizeof(flashptr_t);

#ifdef CHECKPOINT_DEBUG
        call Console.string("Restored FileSystem, pg=");
        call Console.decimal(fat.page);
        call Console.string(" off=");
        call Console.decimal(fat.offset);
        call Console.string("\n");
        TOSH_uwait(50000L);
#endif

        post FSinit();

        return (SUCCESS);
    }

    event void ChunkStorage.flushDone(result_t res)
    {}

#ifdef FS_DEBUG
    event void Console.input(char *s)
    {}
#endif
}
