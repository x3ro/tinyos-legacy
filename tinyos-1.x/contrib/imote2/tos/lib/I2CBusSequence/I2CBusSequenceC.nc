/*
 *I2C Bus Sequence Module StateMachine
 *
 *
 *@authors Lama Nachman, Robbie Adler
 *
 */

configuration I2CBusSequenceC {
  provides {
    interface I2CBusSequence;
    interface StdControl;
  }
}
implementation {
  
  components PXA27XI2CM as I2CM,
    I2CBusSequenceM as I2CBus;
  
  I2CBusSequence = I2CBus;
  StdControl = I2CBus;
  
  I2CBus.I2CControl -> I2CM;
  I2CBus.I2C -> I2CM;
  
}

