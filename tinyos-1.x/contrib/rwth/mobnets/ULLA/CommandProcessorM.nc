/*
 * Copyright (c) 2007, RWTH Aachen University
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL RWTH AACHEN UNIVERSITY BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF RWTH AACHEN
 * UNIVERSITY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * RWTH AACHEN UNIVERSITY SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND RWTH AACHEN UNIVERSITY HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.
 *
 */
 
/**
 *
 * UCP implementation
<p>
 * @author Krisakorn Rerkrai <kre@mobnets.rwth-aachen.de>
 **/


includes UQLCmdMsg;
includes AMTypes;

module CommandProcessorM {

    provides 	{
      interface StdControl;
      interface ProcessCmd as ProcessCommand; // assemble commands from a remote user
      interface CommandInf;                   // commands from a local user
      interface UcpIf;
      interface ProcessData as ProcessScanLinks;
    }
    uses {
      interface Leds;
      interface StdControl as TransControl;
      interface ProcessCmd as Control;

      interface LinkProviderIf[uint8_t id];
      
      interface StorageIf;
    }
}

/* 
 *  Module Implementation
 */

implementation 
{
  typedef struct {
    void **next;
    struct CommandMsg uq;
  } CommandList, *CommandListPtr, **CommandListHandle;
  
  typedef struct {
    uint8_t cid;
    uint16_t interval;
    uint16_t ntimes;
  } SleepRadioUnit, *SleepRadioUnitPtr;
  
  TOS_MsgPtr msg;	       

  CommandMsgPtr cmsg;
  
  uint8_t mStatus;
  bool is_processing_command;
  SleepRadioUnit sleepUnit, *sleepUnitPtr;
  bool sleepNow;
  
  SleepRadioUnit blinkUnit, *blinkUnitPtr;
  
  CommandListHandle cListHead;
  CommandListHandle cListTail;
  struct CommandMsg **gCurCommand;
  
  Handle gCurHandle;

  bool allocateCommand();
  void addCommand(HandlePtr memory);
  void SleepRadio();
  void WakeUpRadio();


    /* task declaration */
 // task void deleteCommand();
  task void modifyCommand();
  task void continueProcessCommand();
  task void RadioTask();

  command result_t StdControl.init() {
    atomic {
      sleepUnitPtr = &sleepUnit;
      blinkUnitPtr = &blinkUnit;
      cListHead = NULL;
      cListTail = NULL;
      sleepNow = FALSE;
			is_processing_command = 0;
    }
    call Leds.init();
    return (SUCCESS);
  }
  
  /* start generic communication interface */
  command result_t StdControl.start(){
    return (SUCCESS);
  }

  /* stop generic communication interface */
  command result_t StdControl.stop(){
    return (SUCCESS);
  } 

  /*new from ULLA */
  command uint8_t UcpIf.doCmd(LuId_t luId, CmdDescrPtr cmddescr) {
    uint8_t numLinks;
    uint8_t links[10];

    dbg(DBG_USR1,"UCP: doCmd\n");

    switch (cmddescr->cmd) {

      case READ_AVAILABLE_LINKS:
        dbg(DBG_USR1, "LLAM: ReadAvailableLinks\n");
        call StorageIf.readAvailableLinks(&numLinks, &links[0]);
      break;
      
      default:
        call LinkProviderIf.execCmd[/*cmd type?*/1](cmddescr);
        //return COMMAND_NOT_SUPPORTED
      break;
    } //*/
    return 1;
  }
  
  command uint8_t UcpIf.requestCmd(LuId_t luId, CmdDescr_t* cmddescr, RcDescr_t *rcdescr, CmdId_t *cmdId) {

    return 1;
  }
  
  command uint8_t UcpIf.cancelCmd(LuId_t luId, CmdId_t cmdId) {

    return 1;
  }
  
  command uint8_t UcpIf.setParam(LuId_t luId, AttrDescr_t paramDescr) {

    return 1;
  }
  
  command result_t ProcessCommand.execute(TOS_MsgPtr pmsg) {
    atomic {
      cmsg = (struct CommandMsg *) pmsg->data;
      msg = pmsg;
    }
    dbg(DBG_USR1,"ProcessCommand execute\n");

    //check message data type: add, modify, delete
    if (cmsg->msgType == DEL_MSG) { // delete a command
      dbg(DBG_USR1,"ProcessCommand DEL_MSG\n");
      if (is_processing_command) return FAIL;
     

    // modify a previous command (given a command ID)
    } else if (cmsg->msgType == MOD_MSG) {

      dbg(DBG_USR1,"ProcessCommand MOD_MSG\n");
      if (is_processing_command) return FAIL;
      is_processing_command = 1;	
      post modifyCommand();
      is_processing_command = 0;
    // add a command
    } else if (cmsg->msgType == ADD_MSG) {
      dbg(DBG_USR1,"ProcessCommand ADD_MSG\n");
      if (is_processing_command) return FAIL;
  
    }
    return SUCCESS;
  }
  /*
  task void deleteCommand() {
    dbg(DBG_USR1, "deleteCommand\n");
  }         */

  task void modifyCommand() {
    dbg(DBG_USR1, "modifyCommand\n");
  }
  
  inline void setSleepUnit() {
    sleepUnitPtr->cid = (**gCurCommand).cid;
    sleepUnitPtr->interval = (**gCurCommand).interval;
    sleepUnitPtr->ntimes = (**gCurCommand).ntimes;
  }
  
  inline void setBlinkUnit() {
    blinkUnitPtr->cid = (**gCurCommand).cid;
    blinkUnitPtr->interval = (**gCurCommand).interval;
    blinkUnitPtr->ntimes = (**gCurCommand).ntimes;
  }
  
  task void scanAvailableLinks() {
    //struct ScanLinks scan;
    
    //scan.
    /////call SendInf.send[AM_SCAN_LINKS](msg, sizeof(struct ScanLinkMsg));
  }
  
  task void continueProcessCommand() {
    dbg(DBG_USR1, "continueProcessCommand %p %d\n",*gCurCommand, (**gCurCommand).cid);
    switch ((**gCurCommand).action){
      case LED_TOGGLE :
        dbg(DBG_USR1, "Yellow Toggle\n");
        //call Leds.yellowToggle();
      break;
      
      case LED_BLINK :
        // blink commands can stay here
        setBlinkUnit();
        //call BlinkTimer.start( TIMER_REPEAT, blinkUnitPtr->interval);
      break;
      
      case SLEEP_MODE :
        // needs to be changed. Use LLA to do so.
        setSleepUnit();
        //call RadioTimer.start( TIMER_ONE_SHOT, 10);
      break;
      
      case SET_RFPOWER :
      /*power = 31 => full power    (0dbm)
       *         3 => lowest power  (-25dbm)  */
        /* platform dependence should be removed.
         * UCP will be connected to LLA with ProcessCmd interface.
         * setAttribute commands will be translated here to put in
         * CommandMsg and send to LLA via ProcessCmd.
        */
        atomic {
          *gCurCommand = (struct CommandMsg *) msg->data;
        }
        call Control.execute(msg);
        ///call CommandInf.setAttribute8(RF_POWER, (**gCurCommand).param);
        //call CC2420Control.SetRFPower((**gCurCommand).param);
      break;
      
      case SCAN_AVAILABLE_LINKS :
        // send polling message to the neighbours
        post scanAvailableLinks();

      default:
      
      break;
    }
  }

  command bool CommandInf.control(CommandMsgPtr cmp, Cond *c, char idx) {
    dbg(DBG_USR1,"ULLA Core: CommandInf.control \n");
    return TRUE;
  }

  command result_t CommandInf.setAttribute8(CommandMsgPtr cmp, uint8_t mode, uint8_t param) {

    return SUCCESS;
  }

  command result_t CommandInf.setAttribute16(CommandMsgPtr cmp, uint8_t mode, uint16_t param) {

    return SUCCESS;
  }

  command result_t CommandInf.setAttribute32(CommandMsgPtr cmp, uint8_t mode, uint32_t param) {

    return SUCCESS;
  }
  
  command result_t ProcessScanLinks.perform(void *pdata, uint8_t length) {
   struct ScanLinkMsg *scanlink = (struct ScanLinkMsg *) pdata;
   dbg(DBG_USR1, "UCP: ProcessScanLinks.perform\n");
   
   // FIXME update the storage
   call StorageIf.addLink(scanlink->linkid);
   return SUCCESS;
  }
  
  /*---------------------------------- Transceiver ----------------------------*/
  /*
  event result_t SendInf.sendDone[uint8_t id](TOS_MsgPtr pmsg, result_t success) {
   return SUCCESS;
  }*/

  /*--------------------------------- LinkProvider ---------------------------*/
  
  event result_t LinkProviderIf.getAttributeDone[uint8_t id](AttrDescr_t* attDescr, uint8_t *result) {
    return SUCCESS;
  }
  
  event result_t Control.done(TOS_MsgPtr pmsg, result_t status) {
  	return SUCCESS;
  }
  
 /*--------------------------------- Radio ------------------------------------*/
  inline void SleepRadio() {
    call TransControl.stop();
  }

  inline void WakeUpRadio() {
    call TransControl.start();
  }

  task void RadioTask() {

  }
  
  /*---------------------------- Command Allocation ---------------------------*/
#ifdef MULTIPLE_COMMANDS
  inline bool allocateCommand() {

    dbg(DBG_USR1, "allocateCommand \n");
    atomic mStatus = ALLOC_QUERY_STATUS;
    if (call MemAlloc.allocate(&gCurHandle, sizeof(struct CommandMsg)) == SUCCESS)
      return TRUE;
    return FALSE;
  }

  inline void addCommand(HandlePtr memory) {

    gCurCommand = (struct CommandMsg **)*memory;
    dbg(DBG_USR1, "addCommand %p %p\n",*memory, *gCurCommand);

    memcpy(&(**gCurCommand), cmsg, sizeof(struct CommandMsg));
    post continueProcessCommand();
  }

  /*--------------------------- MemAlloc Events -------------------------------*/

  event result_t MemAlloc.allocComplete(Handle *handle, result_t complete) {
    CommandListHandle clh = (CommandListHandle)*handle;
    if (mStatus == NOT_ALLOCING_STATUS) return SUCCESS; //not our allocation

    if (complete) {
      dbg(DBG_USR1,"Allocated command\n");

      switch (mStatus) {

        case ALLOC_QUERY_STATUS:
          // put a new command to the list
	        (**clh).next = NULL;
        	atomic {
        	  if (cListTail == NULL) {
              dbg(DBG_USR1,"--** start cListTail **--\n");
	            cListTail = clh;
	            cListHead = clh;
	          } else {
              dbg(DBG_USR1,"--** next cListTail **--\n");
	            (**cListTail).next = (void **)clh;
	            cListTail = clh;
	          }
        	}
        	// then add the information
          //call Query.addQuery(qmsg, *gCurCommand);
          addCommand((HandlePtr)&cListTail);
        break;      //
      }

    } else {
      dbg(DBG_USR1,"Error: Out of Memory!\n");
    }
    mStatus = NOT_ALLOCING_STATUS; //not allocating any more

    return SUCCESS;
  }

  event result_t MemAlloc.reallocComplete(Handle handle, result_t complete) {
    dbg(DBG_USR1,"MemAlloc.realloc complete\n");
    return SUCCESS;
  }

  event result_t MemAlloc.compactComplete() {
    dbg(DBG_USR1,"MemAlloc.compact complete\n");
    return SUCCESS;
  }
#endif
} // end of implementation
