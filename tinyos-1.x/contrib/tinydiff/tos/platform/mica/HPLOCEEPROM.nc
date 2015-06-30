module HPLOCEEPROM 
{
  provides 
  {
    interface StdControl;
    interface SimpleEEPROM;
  }
}
implementation
{

  #include <inttypes.h>
  #include <string.h> // for NULL pointer


  // Bit flags in EEPROM control register
  #define _EERIE 0x08
  #define _EEMWE 0x04
  #define _EEWE  0x02
  #define _EERE  0x01

  //TOS_FRAME_BEGIN(OCEEPROM_obj_frame) {
  int bytes_left;
  char *buf;
  int destAddr;
  //} TOS_FRAME_END(OCEEPROM_obj_frame);

  //char TOS_COMMAND(OCEEPROM_INIT)(void) {
  result_t command StdControl.init() {
    buf=NULL;
    bytes_left=0;
    //return 1; // 1 is good... only for INIT
    return SUCCESS;
  }

  result_t command StdControl.start() {
    return SUCCESS;
  }

  result_t command StdControl.stop() {
    return SUCCESS;
  }

  //1char TOS_COMMAND(OCEEPROM_READ)(int addr, int size, char* passedBuf) {
  command result_t SimpleEEPROM.read(int addr, int size, char* passedBuf) {
    int i, curAddr;
    if( buf==NULL ) {
      buf=passedBuf;
      
      // wait for write to complete [not really necessary]
      while ( inp(EECR) & _EEWE );

      for(i=0; i < size; i++ ) {
	curAddr=addr+i;
	
	// load address
	outp( curAddr & 0xFF, EEARL);
	outp( (curAddr >> 8) & 0xFF , EEARH);

	// read data
	outp( _EERE, EECR);
	passedBuf[i]=inp(EEDR);

      }
      buf=NULL;
      //return 1;
      return SUCCESS;
    }
    //return 0; // error, operation is already in progress
    return FAIL;
  }


  //char TOS_COMMAND(OCEEPROM_WRITE_BYTE)(int addr, char data) {
  command result_t SimpleEEPROM.writeByte(int addr, char data) {
    if( buf==NULL ) {
      buf=(char*)&buf;

      // wait for write to complete 
      while ( inp(EECR) & _EEWE );
      
      // disable interrupts
      cli();
      
      // load address 
      outp( addr & 0xFF, EEARL);
      outp( (addr >> 8) & 0xFF , EEARH);
      
      // load data to be written
      outp( data, EEDR );
      
      // set master write enable
      outp( _EEMWE, EECR );
      // set write enable
      outp( _EEWE, EECR );
      
      // enable interrupts
      sei();
      
      buf=NULL;
      //return 1;
      return SUCCESS;
    }
    //return 0; // error...
    return FAIL;
  }


  //TOS_TASK(OCEEPROM_WRITE_TASK);
  task void writeTask();

  //char TOS_COMMAND(OCEEPROM_ASYNC_WRITE)(int addr, int size, char* passedBuf) {
  command result_t SimpleEEPROM.asyncWrite(int addr, int size, char *passedBuf) {
    if( buf==NULL && 
	size>0 && 
	//1==TOS_POST_TASK(OCEEPROM_WRITE_TASK)) {
	(SUCCESS==post writeTask())) {
      destAddr=addr;
      buf=passedBuf;
      bytes_left=size;
      //return 1;
      return SUCCESS;
    }
    //return 0;
    return FAIL;
  }

  default event void SimpleEEPROM.asyncWriteDone(char success)
  {
    return;
  }

  //TOS_TASK(OCEEPROM_WRITE_TASK) {
  task void writeTask() {

    // this should not happen
    if( buf==NULL) return;

    // check if we can write yet...
    if( inp(EECR) & _EEWE ) {
	  // ... no, write is in progress	
	  // try to post a task again, 	
	  goto try_post;
    }
    
    // disable interrupts
    cli();
    
    // load address 
    outp( destAddr & 0xFF, EEARL);
    outp( (destAddr >> 8) & 0xFF , EEARH);
    
    // load data to be written
    outp( *buf, EEDR );
    
    // set master write enable
    outp( _EEMWE, EECR );
    // set write enable
    outp( _EEWE, EECR );
    
    // enable interrupts
    sei();

    // advance to the next byte
    destAddr++;
    buf++;
    bytes_left--;

    // are we done?
    if( bytes_left > 0 ) { 
	  // no... post next task
	  goto try_post;
    } else {
	  // we are done
	  buf=NULL;
	  // do callback with success
	  //TOS_SIGNAL_EVENT(OCEEPROM_ASYNC_WRITE_DONE)(1);
	  signal SimpleEEPROM.asyncWriteDone(SUCCESS);
	  return;
    }
    
  try_post:
    // try to post next task
    //if( ! TOS_POST_TASK(OCEEPROM_WRITE_TASK) ) {
    if(FAIL == post writeTask() ) {
	  // if failed
	  // - reset state
	  buf=NULL;
	  // - callback with error
	  //TOS_SIGNAL_EVENT(OCEEPROM_ASYNC_WRITE_DONE)(0);
	  signal SimpleEEPROM.asyncWriteDone(FAIL);
    }
  }


}
