/*
 * Measuring the performance of the data structures
 */
includes chunk_header;
includes sizes;

module StressTestM {
    provides interface StdControl;
    
    uses {
        interface Leds;
        interface Console;
        interface GenericFlash;
        interface File;
        interface Timer;
    }
}

implementation {
    uint8_t i_[LEN], i[LEN];
    uint16_t j, j_;
    char names[5][6]= {"foo1", "foo2", "foo3", "foo4", "foo5"};
    uint8_t ncnt=0;
    int cnt=0;

    bool ecc, busy;
    int count = 0;
    uint16_t pages, current;
    flashptr_t someptr;
    datalen_t len;

    task void format();
    task void FileOpenTask();
    task void FileCloseTask();
    task void FileAppendTask(); 

    task void FileCreateTask()
    {
        call Leds.yellowToggle();
        call Leds.yellowToggle();

        if (SUCCESS != call File.create(names[ncnt]))
        {
#ifdef DEBUG
            call Console.string("Unable to create file 2:");
            call Console.string(names[ncnt]);
            call Console.string("\n");
            TOSH_uwait(50000L);
#endif
            call Leds.redOn();
        }
        else
        {
#ifdef DEBUG
            call Console.string("Creating file2...\n");
            TOSH_uwait(50000L);
#endif
        }
    }

    event void File.createDone(result_t res)
    {
        call Leds.yellowToggle();
        call Leds.yellowToggle();

        if (SUCCESS != res)
        {
#ifdef DEBUG
            call Console.string("File creation failed 2\n");
            TOSH_uwait(50000L);
#endif
            call Leds.redOn();
        }
        else
        {
            call Console.string("File creation ok 2\n");
            TOSH_uwait(50000L);
        }
    }


    event void File.deleteDone(result_t res)
    {
    }


    task void FileOpenTask()
    {
        call Leds.yellowToggle();
        call Leds.yellowToggle();

        if (SUCCESS != call File.open(names[ncnt]))
        {
#ifdef DEBUG
            call Console.string("Unable to open file 2\n");
            TOSH_uwait(50000L);
#endif
            call Leds.redOn();
        }
        else
        {
#ifdef DEBUG
            call Console.string("Opening file2...\n");
            TOSH_uwait(50000L);
#endif
        }
    }

    event void File.openDone(result_t res)
    {
        call Leds.yellowToggle();
        call Leds.yellowToggle();

        if (SUCCESS != res)
        {
#ifdef DEBUG
            call Console.string("File opening failed 2\n");
            TOSH_uwait(50000L);
#endif
            call Leds.redOn();
        }
        else
        {
            call Console.string("File open ok 2\n");
            TOSH_uwait(50000L);
        }
    }

    task void FileCloseTask()
    {
        call Leds.greenToggle();
        call Leds.greenToggle();

        if (SUCCESS != call File.close())
        {
#ifdef DEBUG
            call Console.string("Unable to close file 2\n");
            TOSH_uwait(50000L);
#endif
            call Leds.redOn();
        }
        else
        {
#ifdef DEBUG
            call Console.string("Closing file2...\n");
            TOSH_uwait(50000L);
#endif
        }
    }

    event void File.closeDone(result_t res)
    {
        call Leds.greenToggle();
        call Leds.greenToggle();

        if (SUCCESS != res)
        {
#ifdef DEBUG
            call Console.string("File closing failed 2\n");
            TOSH_uwait(50000L);
#endif
            call Leds.redOn();
        }
        else
        {
            call Console.string("File close ok 2\n");
            TOSH_uwait(50000L);
        }
    }

    char buff[LEN];
    task void FileAppendTask()
    {
        if (cnt == 0)
        {
            call Leds.greenToggle();
            call Leds.greenToggle();
        }

        if (SUCCESS != call File.append(buff, LEN))
        {
#ifdef DEBUG
            call Console.string("Unable to append file 2\n");
            TOSH_uwait(50000L);
#endif
            call Leds.redOn();
        }
    }

    event void File.appendDone(result_t res)
    {
        if (SUCCESS != res)
        {
#ifdef DEBUG
            call Console.string("File appending failed 2\n");
            TOSH_uwait(50000L);
#endif
            call Leds.redOn();
        }
        else
        {
            if (cnt++ < COUNT)
            {
                post FileAppendTask();
            }
            else
            {
                cnt=0;
                call Leds.greenToggle();
                call Leds.greenToggle();

                post FileCloseTask();
            }
        }
    }

    uint16_t read;
    task void FileReadTask()
    {
        if (cnt == 0)
        {
            call Leds.greenToggle();
            call Leds.greenToggle();
        }

        if (SUCCESS != call File.readNext(buff, LEN, &read))
        {
#ifdef DEBUG
            call Console.string("Unable to read file 2\n");
            TOSH_uwait(50000L);
#endif
            call Leds.redOn();
        }
    }

    event void File.readDone(result_t res)
    {
        if (SUCCESS != res)
        {
#ifdef DEBUG
            call Console.string("File reading failed 2\n");
            TOSH_uwait(50000L);
#endif
            call Leds.redOn();
        }
        else
        {
            if (cnt++ < COUNT)
                post FileReadTask();
            else
            {
                cnt=0;
                call Leds.greenToggle();
                call Leds.greenToggle();

                call Console.string("File reading done 2\n");
                TOSH_uwait(50000L);
            }
        }
    }

    event void File.flushDone(result_t res)
    {}

    command result_t StdControl.init() 
    {
        busy = 0;
        current = pages = 0;
	    memset(i, 0xAB, LEN);
    	memset(i_, 0x0, LEN);
        count = 0;   

        call Console.init();

        call Leds.init();
        
        return SUCCESS;
    }

    command result_t StdControl.start() 
    {    
        pages = 2048;

        call Timer.start(TIMER_REPEAT, 15000);

        return SUCCESS;
    }
    
    command result_t StdControl.stop() 
    {
        return SUCCESS;
    }

    event void Console.input(char *s)
    {
        if ((s[0] == 'f') && (s[1] == 'f'))
        {
            call Console.string("formatting flash...\n");
            post format();
        }

        if ((s[0] == 'f') && (s[1] == 'c'))
        {
            post FileCreateTask();
        }

        if ((s[0] == 'f') && (s[1] == 'o'))
        {
            post FileOpenTask();
        }

        if ((s[0] == 'f') && (s[1] == 'l'))
        {
            post FileCloseTask();
        }

        if ((s[0] == 'f') && (s[1] == 'a'))
        {
            post FileAppendTask();
        }

        if ((s[0] == 'f') && (s[1] == 'R'))
        {
            call File.readStart();
        }

        if ((s[0] == 'f') && (s[1] == 'r'))
        {
            post FileReadTask();
        }

        call Console.string("ok...\n");
    }

    uint8_t count_=0;
    event result_t Timer.fired()
    {
        // perform operation here
        if (count_ == 0)
            post format();
        else if (count_ == 2)        
            post FileCreateTask();
        else if (count_ == 3)
            post FileOpenTask();
        else if (count_ == 4)
            post FileAppendTask();
        else if (count_ == 5)
            post FileOpenTask();
        else if (count_ == 6)
            post FileReadTask();

        count_++;

        return(SUCCESS);
    }

    task void format()
    {
        if (SUCCESS != call GenericFlash.erase(current))
        {
            call Console.string("ERROR ! erase call failed\n");
            call Leds.redOn();
        }

        current += 1;
    }

    event result_t GenericFlash.eraseDone(result_t r)
    {
        if (SUCCESS != r)
        {
            call Leds.redOn();
            call Console.string("ERROR ! erase call failure - pg: ");
            call Console.decimal(current);
            call Console.string("\n");
            return (FAIL);
        }
        else
        {
            if (current < pages)
            {
                post format();
                //call Console.string("Formatting\n");
            }
            else
            {
                call Console.string("Flash formatted... Ready\n");

                current = 0;
           }
        }

        return (SUCCESS);
    }
    
    event result_t GenericFlash.initDone(result_t r)
    {
        call Console.string("Init done\n");
        return (SUCCESS);
    }

    event result_t GenericFlash.writeDone(result_t r)
    {
        return (SUCCESS);
    }

    event result_t GenericFlash.readDone(result_t r)
    {
        return (SUCCESS);
    }

    event result_t GenericFlash.falReadDone(result_t r)
    {
        return (SUCCESS);
    }
}
