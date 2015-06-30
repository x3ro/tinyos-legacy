/*
 *I2C Bus Sequence interface
 *
 *
 *@authors Robbie Adler, Lama Nachman
 *
 */

includes I2CBusSequence;

interface I2CBusSequence{

  /*
   * execute a sequence of I2C commands
   *
   * @return FAIL if bus module is unable to accept an additional sequence of commands to be processed (it is implementation defined how many command sequences the underlying module may accept
   * returns SUCCESS otherwise.  
   *
   *
   */
  command result_t runI2CBusSequence(i2c_op_t *pOps, uint8_t numOps);
  
  /*
   * event that indicates that a previos sequence has been executed.  The succes parameter indicates whether the sequ
   * was succesfully exectued
   *
   *
   * @return void
   *
   */
  
  event void runI2CBusSequenceDone(i2c_op_t *pOpsExecuted, uint8_t numOpsExecuted, result_t success);
}
 


