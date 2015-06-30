includes DetectionLog;
configuration DetectionLogC
{
  provides {
    interface StdControl;
  }
}
implementation
{
  components RegistryC;
  components new LogStorageC() as DataLog;
  components new BlockStorageC() as DataBlock;
  components StrawC, DetectionLogM;

  StdControl = StrawC;
  StdControl = DetectionLogM;

  DetectionLogM.PIRDetectValue -> RegistryC.PIRDetectValue;
  DetectionLogM.LogMount -> DataLog;
  DetectionLogM.BlockMount -> DataBlock;
  DetectionLogM.LogWrite -> DataLog;
  DetectionLogM.BlockRead -> DataBlock;

  DetectionLogM.Straw -> StrawC;
}

