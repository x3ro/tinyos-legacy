/*
 * file:        FalC.nc
 * description: This abstracts away the flash device
 */

includes common_header;

module NANDFlashM {
  provides interface GenericFlash[uint8_t id];
  
  uses {
    interface PageNAND;
  }
}

implementation 
{
  pageptr_t Tpage;
  uint8_t Tid;
  uint8_t init = 0;

  task void initPageNAND()
    {
      call PageNAND.init();
    } 

  task void initDone()
    {
      signal GenericFlash.initDone[Tid](SUCCESS);
    }
  
  command result_t GenericFlash.init[uint8_t id]()
    {
      Tid = id;
      atomic{
	if( init == 0 )
	  {
	    init++;
	    post initPageNAND();
	  }
	else
	  post initDone();
      }
      return SUCCESS;
    }
  
  event result_t PageNAND.initDone(result_t r)
    {
      signal GenericFlash.initDone[Tid](r);
      return(SUCCESS);
    }
  
  command pageptr_t GenericFlash.numPages[uint8_t id]()
    {
      return(call PageNAND.numPages());
    }
  
  command result_t GenericFlash.write[uint8_t id](pageptr_t page,
						  offsetptr_t offset,
						  void *data,
						  datalen_t len)
    {
      Tpage = page;
      Tid = id;
      return(call PageNAND.write(page, offset, data, len));
    }
  
  event result_t PageNAND.writeDone(result_t r)
    {
      signal GenericFlash.writeDone[Tid](r);
      return(SUCCESS);
    }
  
  command result_t GenericFlash.falRead[uint8_t id](pageptr_t page,
						    offsetptr_t offset,
						    void *header, 
						    void *app_buff,
						    datalen_t app_len, 
						    void *data_buff)
    {
      Tid = id;
      Tpage = page;
      return(call PageNAND.falRead(page,
				   offset,
				   header,
				   app_buff,
				   app_len,
				   data_buff));
    }
  
  event result_t PageNAND.falReadDone(result_t r)
    {
      signal GenericFlash.falReadDone[Tid](r);
      return(SUCCESS);
    }
  
  command result_t GenericFlash.read[uint8_t id](pageptr_t page,
						 offsetptr_t offset,
						 void *app_buff,
						 datalen_t app_len)
    {
      Tid = id;
      Tpage = page;
      return(call PageNAND.read(page, offset, app_buff, app_len));
    }
  
  event result_t PageNAND.readDone(result_t r)
    {
      signal GenericFlash.readDone[Tid](r);
      return(SUCCESS);
    }
  
  command result_t GenericFlash.erase[uint8_t id](pageptr_t page)
    {
      Tid = id;
      Tpage = page;
      return(call PageNAND.erase(page));
    }
  
  event result_t PageNAND.eraseDone(result_t result)
    {
      signal GenericFlash.eraseDone[Tid](result);
      return(SUCCESS);
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
}
