/*
 * file:        FileM.nc
 * description: File operation implementation
 */

/*
 * File implementation
 */

includes app_header;
includes common_header;

module FileM {
	provides interface File;
	
	uses {
		interface Index;
		interface Leds;
#ifdef FILE_DEBUG
		interface Console;
#endif
        interface FileSystem;
        interface RootPtrAccess as IndexRootPtrAccess;
	}
}

implementation 
{
    /* States for the File state */
    enum {CREATE, DELETE, CLOSE, FLUSH, APPEND, READ};
    uint8_t state;             /* Tracks the state of the component */
    char writeBuf[FILE_WRITE_BUFF], readBuf[FILE_READ_BUFF];
    uint16_t cache_ptr = 0;    /* This is the pointer into the current write  
                                  buffer where the next chunk will be written */

    file_header filedata;
    fileptr_t ofid;
    bool ofid_valid = FALSE;
    bool busy = FALSE;

    task void copyIntoBuf();

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
    
    /*********** Create a new file ***********/
	command result_t File.create(char *fileName)
    {
        if (lock() != SUCCESS)
        {
#ifdef FILE_DEBUG
            call Console.string("ERROR ! Unable to acquire File-create lock\n");
            TOSH_uwait(20000);
#endif
            return (FAIL);
        }

        /* First lookup to see if this file exists */
        if (FAIL != call FileSystem.lookup(fileName, NULL))
        {
            /* Filename already exists */
#ifdef FILE_DEBUG
            call Console.string("ERR 1 : ");
            call Console.string(fileName);
            call Console.newline();
            TOSH_uwait(20000);
#endif
            unlock();
            return (FAIL);
        }

        /* File does not exist -> now create it */
        if (FAIL == call FileSystem.create(fileName))
        {
#ifdef FILE_DEBUG
            call Console.string("ERR 2 : ");
            call Console.string(fileName);
            call Console.string("\n");
            TOSH_uwait(20000);
#endif
            unlock();
            return (FAIL);
        }

        return (SUCCESS);
    }

    event void FileSystem.createDone(result_t res)
    {
#ifdef FILE_DEBUG
        call Console.string("Created file\n");
        TOSH_uwait(20000);
#endif

        unlock();
        signal File.createDone(res);
    }

    /*********** Delete file ***********/
    command result_t File.delete(char *fileName)
    {
        fileptr_t fid;

        if (lock() != SUCCESS)
        {
#ifdef FILE_DEBUG
            call Console.string("ERROR ! Unable to acquire File-del lock\n");
            TOSH_uwait(20000);
#endif
            return (FAIL);
        }

        /* First lookup to see if this file exists */
        if (FAIL == call FileSystem.lookup(fileName, &fid))
        {
            /* Filename does not exist */
#ifdef FILE_DEBUG
            call Console.string("ERR 3 : ");
            call Console.string(fileName);
            call Console.newline();
            TOSH_uwait(20000);
#endif
            unlock();
            return (FAIL);
        }

        /* Delete File */
        if (FAIL == call FileSystem.delete(fid))
        {
#ifdef FILE_DEBUG
            call Console.string("ERR 3 fn: ");
            call Console.string(fileName);
            call Console.string(" id: ");
            call Console.decimal(fid);
            call Console.string("\n");
            TOSH_uwait(20000);
#endif
            unlock();
            return (FAIL);
        }
    }

    event void FileSystem.deleteDone(result_t res)
    {
#ifdef FILE_DEBUG
        call Console.string("Deleted file\n");
        TOSH_uwait(20000);
#endif

        unlock();
        signal File.deleteDone(res);
    }

    /*********** Move file ***********/
    command result_t File.move(char *fileName1, char *fileName2)
    {
        fileptr_t fid;

        /* First lookup to see if this file exists */
        if (FAIL == call FileSystem.lookup(fileName1, &fid))
        {
            /* Filename does not exist */
#ifdef FILE_DEBUG
            call Console.string("Filename: ");
            call Console.string(fileName1);
            call Console.string(" does not exist\n");
            TOSH_uwait(20000);
#endif
            return (FAIL);
        }

        /* File exists -> move file */
        if (FAIL == call FileSystem.move(fid, fileName2))
        {
#ifdef FILE_DEBUG
            call Console.string("Error moving file: ");
            call Console.string(fileName1);
            call Console.string(" fid: ");
            call Console.decimal(fid);
            call Console.string("\n");
            TOSH_uwait(20000);
#endif
            return (FAIL);
        }

        return (SUCCESS);
    }

    /*********** Open file ***********/
    command result_t File.open(char *fileName)
    {
        if (lock() != SUCCESS)
        {
#ifdef FILE_DEBUG
            call Console.string("ERROR ! Unable to acquire File-open lock\n");
            TOSH_uwait(20000);
#endif
            return (FAIL);
        }

        /* First lookup to see if this file exists */
        if (FAIL == call FileSystem.lookup(fileName, &ofid))
        {
            /* Filename does not exist */
#ifdef FILE_DEBUG
            call Console.string("ERR 4:");
            call Console.string(fileName);
            call Console.string("\n");
            TOSH_uwait(20000);
#endif
            unlock();
            return (FAIL);
        }

        if (FAIL == call FileSystem.getFileData(ofid, &filedata))
        {
#ifdef FILE_DEBUG
            call Console.string("ERR 5:");
            call Console.decimal(ofid);
            call Console.string("\n");
            TOSH_uwait(20000);
#endif
            unlock();
            return (FAIL);
        }
        ofid_valid = TRUE;

        /* Load index into memory */
        call IndexRootPtrAccess.setPtr(&filedata.start_ptr);

        if (FAIL == call Index.load(TRUE))
        {
#ifdef FILE_DEBUG
            call Console.string("ERR 6:");
            call Console.decimal(ofid);
            call Console.string("\n");
            TOSH_uwait(20000);
#endif
            unlock();
            return (FAIL);
        }

        return (SUCCESS);
    }

    event void Index.loadDone(result_t res)
    {
        unlock();
        signal File.openDone(res);
    }


    /*********** Close file ***********/
    result_t Res;
    task void signaler()
    {
        unlock();
        if (state == CLOSE)
            signal File.closeDone(Res);
        else if (state == APPEND)
            signal File.appendDone(Res);
        else if (state == FLUSH)
            signal File.flushDone(Res);
        else if (state == READ)
            signal File.readDone(Res);
    }

    task void saveIndex()
    {
#ifdef FILE_DEBUG
        call Console.string("In saveIndex...\n");
#endif

        if (SUCCESS != call Index.save(&filedata.start_ptr))
        {
#ifdef FILE_DEBUG
            call Console.string("ERR 7\n");
            TOSH_uwait(20000);
#endif
            call Leds.redOn();
            Res = FAIL;
            post signaler();
        }
    }

    event void Index.saveDone(result_t res)
    {
        if (SUCCESS != res)
        {
            call Leds.redOn();

#ifdef FILE_DEBUG
            call Console.string("ERR 8\n");
            TOSH_uwait(20000);
#endif

            Res = FAIL;
            post signaler();

            return;
        }

#ifdef FILE_DEBUG
        call Console.string("Saving File Data, root pg:");
        call Console.decimal(filedata.start_ptr.page);
        call Console.string(" off:");
        call Console.decimal(filedata.start_ptr.offset);
        call Console.string(" len:");
        call Console.decimal(filedata.length);
        call Console.string(" lastindex:");
        call Console.decimal(filedata.last_index);
        call Console.string("\n");
        TOSH_uwait(20000);
#endif


        if (SUCCESS != call FileSystem.updateFileData(ofid, &filedata))
        {
#ifdef FILE_DEBUG
            call Console.string("ERR 9\n");
            TOSH_uwait(20000);
#endif
            call Leds.redOn();
            Res = FAIL;
            post signaler();
        }
    }

    /* Flush write buffer */
    result_t flush_write_buffer()
    {
#ifdef FILE_DEBUG
        call Console.string("In flush write buffer...\n");
        TOSH_uwait(20000L);
#endif

        if (cache_ptr == 0)
        {
            /* Nothing to write */
            if ( (state == CLOSE) || (state == FLUSH) )
            {
#ifdef FILE_DEBUG
                call Console.string("Posting saveIndex\n");
                TOSH_uwait(20000L);
#endif
                post saveIndex();
            }
            else if (state == APPEND)
            {
#ifdef FILE_DEBUG
                call Console.string("Posting copyIntoBuf\n");
                TOSH_uwait(20000L);
#endif
                post copyIntoBuf();
            }
        }
        else
        {
            if (SUCCESS != call Index.set(filedata.last_index++, writeBuf, 
                                          cache_ptr, NULL))
            {
#ifdef FILE_DEBUG
                call Console.string("ERR 10 index loc:");
                call Console.decimal(filedata.last_index);
                call Console.string("\n");
                TOSH_uwait(20000);
#endif
                return (FAIL);
            }
            else
            {
#ifdef FILE_DEBUG
                call Console.string("Setting data index loc:");
                call Console.decimal(filedata.last_index);
                call Console.string(" len:");
                call Console.decimal(cache_ptr);
                call Console.string("\n");
                TOSH_uwait(30000);
#endif
            }
        }

        return (SUCCESS);
    }
    
    event void Index.setDone(result_t res)
    {
#ifdef FILE_DEBUG
        call Console.string("In Index.setDone\n");
#endif

        if (SUCCESS != res)
        {
            call Leds.redOn();

#ifdef FILE_DEBUG
            call Console.string("ERR 11\n");
            TOSH_uwait(20000);
#endif

            Res = FAIL;
            post signaler();

            return;
        }

        /* succeeded */
        cache_ptr = 0;

        if ( (state == CLOSE) || (state == FLUSH) )
        {
#ifdef FILE_DEBUG
            call Console.string("Posting saveIndex\n");
            TOSH_uwait(20000L);
#endif

            post saveIndex();
        }
        else if (state == APPEND)
        {
#ifdef FILE_DEBUG
            call Console.string("Posting copyIntoBuf\n");
            TOSH_uwait(20000L);
#endif

            post copyIntoBuf();
        }
    }


    command result_t File.close()
    {
        if (lock() != SUCCESS)
        {
#ifdef FILE_DEBUG
            call Console.string("ERROR ! Unable to acquire File-close lock\n");
            TOSH_uwait(20000);
#endif
            return (FAIL);
        }

        state = CLOSE;
 
        /* Flush current write buffer to flash */
        flush_write_buffer();

        return (SUCCESS);
    }

    event void FileSystem.updateFileDataDone(result_t res)
    {
#ifdef FILE_DEBUG
        call Console.string("ERR 12\n");
#endif

        if (state == CLOSE)
            ofid_valid = FALSE;

        Res = res;
        post signaler();
    }

    /*********** Append to file ***********/
    char *Tdata; uint16_t Tlen;

    task void copyIntoBuf()
    {
#ifdef FILE_DEBUG
        call Console.string("Copied data\n");
        TOSH_uwait(40000L);
#endif

        memcpy(&writeBuf[cache_ptr], Tdata, Tlen);
        cache_ptr += Tlen;

        /* Update the length */
        filedata.length += Tlen;

        Res = SUCCESS;
        post signaler();
    }

    command result_t File.append(void *data, uint16_t length)
    {
        if (lock() != SUCCESS)
        {
#ifdef FILE_DEBUG
            call Console.string("ERROR ! Unable to acquire File-append lock\n");
            TOSH_uwait(20000);
#endif
            return (FAIL);
        }

        if (ofid_valid != TRUE)
        {
#ifdef FILE_DEBUG
            call Console.string("ERR 13\n");
            TOSH_uwait(20000);
#endif
            unlock();
            return (FAIL);
        }

        if ( (length > FILE_WRITE_BUFF) || (length <= 0) )
		{
#ifdef FILE_DEBUG
            call Console.string("ERROR ! 0 < Length <= ");
            call Console.decimal(FILE_WRITE_BUFF);
            call Console.string(" only supported. Provided:");
            call Console.decimal(length);
            call Console.string("\n");
            TOSH_uwait(40000L);
#endif
            unlock();
            return (FAIL);
        }

        state = APPEND;
        Tdata = (char *) data; Tlen = length;

        /* Write the data to the buffer */
   		if (length > (FILE_WRITE_BUFF - cache_ptr))
		{
#ifdef FILE_DEBUG
            call Console.string("Flushing write buff\n");
            TOSH_uwait(40000L);
#endif

            flush_write_buffer();
        }
        else
        {
            post copyIntoBuf();
        }

        return (SUCCESS);
    }


    /*********** Read from file ***********/
    uint16_t read_ptr=0, index_loc = 0;
    uint16_t *Trlen;

    command result_t File.readStart()
    {
        read_ptr = 0;
        index_loc = 0;

        return (SUCCESS);
    }

    result_t load_buffer()
    {
        if (index_loc >= filedata.last_index)
        {
            /* Nothing more to read */
#ifdef FILE_DEBUG
            call Console.string("ERROR ! Nothing more in file, index_loc:");
            call Console.decimal(index_loc);
            call Console.string(" filedata.last_index:");
            call Console.decimal(filedata.last_index);
            call Console.string("\n");
            TOSH_uwait(20000);
#endif
            return (FAIL);
        }

        if (SUCCESS != call Index.get(index_loc, readBuf, NULL))
        {
#ifdef FILE_DEBUG
            call Console.string("ERR 14 index loc:");
            call Console.decimal(index_loc);
            call Console.string("\n");
            TOSH_uwait(20000);
#endif
            return (FAIL);
        }

        return (SUCCESS);
    }


    task void copyFromBuf()
    {
        uint16_t toRead;

        /* Check how much data is in the buffer */
        if ( Tlen < (toRead = (FILE_READ_BUFF - read_ptr)) )
            toRead = Tlen;

        memcpy(&Tdata[*Trlen], &readBuf[read_ptr], toRead);

        Tlen -= toRead;
        *Trlen += toRead;
        read_ptr += toRead;

        if (Tlen > 0)
        {
            if (SUCCESS != load_buffer())
            {
                Res = FAIL;
                post signaler();
            }
        }
        else
        {
            Res = SUCCESS;
            post signaler();
        }
    }


    event void Index.getDone(result_t res)
    {
        if (res != SUCCESS)
        {
#ifdef FILE_DEBUG
            call Console.string("ERR 15\n");
            TOSH_uwait(20000);
#endif
            Res = res;
            call Leds.redOn();
            post signaler();
            return;
        }
        
        index_loc++;
        read_ptr = 0;
    
        post copyFromBuf();
    }

    command result_t File.readNext(void *data, uint16_t length, 
                                   uint16_t *read_length)
    {
        if (lock() != SUCCESS)
        {
#ifdef FILE_DEBUG
            call Console.string("ERROR ! Unable to acquire File-read lock\n");
            TOSH_uwait(20000);
#endif
            return (FAIL);
        }

        if (ofid_valid != TRUE)
        {
#ifdef FILE_DEBUG
            call Console.string("ERR 16\n");
            TOSH_uwait(20000);
#endif
            unlock();
            return (FAIL);
        }

        if (length <= 0)
		{
#ifdef FILE_DEBUG
            call Console.string("ERR 17\n");
            TOSH_uwait(40000L);
#endif
            unlock();
            return (FAIL);
        }

        state = READ;
        Tdata = data; Tlen = length;
        Trlen = read_length;
        *read_length = 0;

        /* Load buffer or read, as need be */
   		if ((read_ptr == 0) || (read_ptr == FILE_READ_BUFF))
		{
            /* There is no data in the buffer -> get some fresh data */
            if (FAIL == load_buffer())
            {
#ifdef FILE_DEBUG
                call Console.string("ERR 18\n");
                TOSH_uwait(40000L);
#endif
                unlock();
                return (FAIL);
            }
        }
        else
        {
            /* There is some data in the buffer */
            post copyFromBuf();
        }

        return (SUCCESS);
    }


    event void Index.deleteDone(result_t res)
    {
    }


    /*********** Get length of the file ***********/
    command uint16_t File.length()
    {
        if (ofid_valid != TRUE)
        {
#ifdef FILE_DEBUG
            call Console.string("ERR 19\n");
            TOSH_uwait(20000);
#endif
            return (~0);
        }
        else
        {
            return (filedata.length);
        }
    }

    /*********** Flush file ***********/
    command result_t File.flush()
    {
        if (lock() != SUCCESS)
        {
#ifdef FILE_DEBUG
            call Console.string("ERROR ! Unable to acquire File-flush lock\n");
            TOSH_uwait(20000);
#endif
            return (FAIL);
        }

        state = FLUSH;

        flush_write_buffer();

        return (SUCCESS);
    }

    event void FileSystem.flushDone(result_t res)
    {}

    event void FileSystem.initDone(result_t res)
    {}

#ifdef FILE_DEBUG
    event void Console.input(char *s)
    {}
#endif

}
