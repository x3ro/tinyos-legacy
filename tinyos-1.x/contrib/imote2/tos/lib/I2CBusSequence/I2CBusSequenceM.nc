/*
 *I2C Bus Sequence Module StateMachine
 *
 *
 *@authors Lama Nachman, Robbie Adler
 *
 */

includes trace;

includes I2CBusSequence;

module I2CBusSequenceM {
  provides {
    interface I2CBusSequence;
    interface StdControl;
  }
  uses {
    interface StdControl as I2CControl;
    interface I2C;
  }
}
implementation {

  
  i2c_op_t *pCurrentOps = NULL;
  uint8_t num_ops;
  uint8_t current_op;
  bool gbInit = FALSE;
  bool gbStart = FALSE;
  
  /**
   * Initialize the component.
   * 
   * @return Always returns <code>SUCCESS</code>
   **/
  command result_t StdControl.init() {
    call I2CControl.init();
    num_ops = 0;
    current_op = 0;
    gbInit = TRUE;
    return SUCCESS;
  }

  command result_t StdControl.start() {
    gbStart = TRUE;
    return call I2CControl.start();
  }

  command result_t StdControl.stop() {
    return call I2CControl.stop();
  }
  

  task void processNextCmd() {
     if (num_ops == 0) {
        // empty queue
        return;
     }
     if (current_op > (num_ops - 1)) { // changed gte to strictly greater so that the last op is performed
        // finished last op
       signal I2CBusSequence.runI2CBusSequenceDone(pCurrentOps, current_op, SUCCESS);
       pCurrentOps = NULL;
       num_ops = 0;
       current_op = 0;
       return;
     }
     // process next command
     switch (pCurrentOps[current_op].op) {
        case I2C_START:
           call I2C.sendStart();
           break;
        case I2C_END:
           call I2C.sendEnd();
           break;
        case I2C_READ:
           call I2C.read(pCurrentOps[current_op].param);
           break;
        case I2C_WRITE:
           call I2C.write(pCurrentOps[current_op].param);
           break;
     }
  }

  command result_t I2CBusSequence.runI2CBusSequence(i2c_op_t *pOps, uint8_t numOps){
    
    if(gbInit == FALSE){
      call StdControl.init();
    }
    if(gbStart == FALSE){
      call StdControl.start();
    }
    
    if(pCurrentOps == NULL){
      pCurrentOps = pOps;
      current_op = 0;
      num_ops = numOps;
      post processNextCmd();
      return SUCCESS;
    }
    else{
      return FAIL;
    }
  }
  

  /*
   * I2C interface events
   */

  event result_t I2C.sendStartDone() {
     current_op++;
     post processNextCmd();
     return SUCCESS;
  }

  event result_t I2C.sendEndDone() {
     current_op++;
     post processNextCmd();
     return SUCCESS;
  }

  event result_t I2C.readDone(char data) {
     // Done reading, update the table
     pCurrentOps[current_op].res = data;
     current_op++;
     post processNextCmd();
     return SUCCESS;
  }

  event result_t I2C.writeDone(bool success) {
     // Done writing, update the table with result
     pCurrentOps[current_op].res = success;
     current_op++;
     post processNextCmd();
     return SUCCESS;
  }
}

