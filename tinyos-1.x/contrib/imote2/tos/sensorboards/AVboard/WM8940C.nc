configuration WM8940C{
  provides{
    interface StdControl;
    interface Audio;
  }
}

implementation{
  components WM8940M, 
    PXA27XI2SC as I2SC,
    I2CBusSequenceC;
  
  StdControl = WM8940M.StdControl;
  Audio = WM8940M.Audio;
  WM8940M.I2S -> I2SC.I2S;
  WM8940M.BulkTxRx -> I2SC.BulkTxRx;
  WM8940M.I2CBusSequence -> I2CBusSequenceC;
  WM8940M.I2CSequenceControl -> I2CBusSequenceC;
}
