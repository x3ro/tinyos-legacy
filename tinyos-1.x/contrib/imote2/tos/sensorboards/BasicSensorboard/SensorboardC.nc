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
    BasicSensorboardAccelDataC as DataChan1,
    //BasicSensorboardADCDataC as DataChan2,
    PMICC,
    BasicSensorboardManagerM as BoardManagerM;

  StdControl = SensorboardFrameworkC;
  GenericSampling = SensorboardFrameworkC;
  BufferManagement = SensorboardFrameworkC; 
  WriteData = SensorboardFrameworkC;
  
  SensorboardFrameworkC.BoardManager -> BoardManagerM;
  
  BoardManagerM.AccelDataControl -> DataChan1; 
  BoardManagerM.PMIC -> PMICC;
  
  //data channel components get wired into the parameterized
  //SensorData interface instance that corresponds to their
  //data channel #.  Typically, SensorData[0] will be wired into
  //a dummyData Component, but this is usage defined.
  SensorboardFrameworkC.SensorData[1] -> DataChan1;  
  

}
