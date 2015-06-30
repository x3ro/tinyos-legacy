/**
*
*@author Robbie Adler
*
**/

configuration SensorboardC{
    provides {
      interface StdControl;
      interface GenericSampling;
    }
    uses{
      interface BufferManagement;
      interface WriteData;
    }
}

implementation {

  components SensorboardFrameworkC,
    QuickFilterQF4A512C as SensorDataC,
    PMICC,
    I2CBusSequenceC,
    Main,
    TimerC,
    BluSHC,
    GenericSensorboardManagerM as BoardManagerM;

  StdControl = SensorboardFrameworkC;
  GenericSampling = SensorboardFrameworkC;
  BufferManagement = SensorboardFrameworkC; 
  WriteData = SensorboardFrameworkC;
  
  SensorboardFrameworkC.BoardManager -> BoardManagerM;
  
  BoardManagerM.AccelDataControl -> SensorDataC; 
  BoardManagerM.I2CBusSequence -> I2CBusSequenceC;
  BoardManagerM.PMIC -> PMICC;

    
  BoardManagerM.QuickFilterQF4A512 -> SensorDataC.QuickFilterQF4A512;

  BoardManagerM.Timer -> TimerC.Timer[unique("Timer")];
  BluSHC.BluSH_AppI[unique("BluSH")] -> BoardManagerM.CalOffset;
  BluSHC.BluSH_AppI[unique("BluSH")] -> BoardManagerM.CalGain;
  
  
  //data channel components get wired into the parameterized
  //SensorData interface instance that corresponds to their
  //data channel #.  Typically, SensorData[0] will be wired into
  //a dummyData Component, but this is usage defined.
  SensorboardFrameworkC.SensorData[1] -> SensorDataC.SensorData[0];
  SensorboardFrameworkC.SensorData[2] -> SensorDataC.SensorData[1];
  SensorboardFrameworkC.SensorData[3] -> SensorDataC.SensorData[2];
  SensorboardFrameworkC.SensorData[4] -> SensorDataC.SensorData[3];
  

}
