/*
  D e c t e c t o r C . m

  This file (c) Copyright 2004 The MITRE Corporation (MITRE)

  This file is part of the NEST Acoustic Subsystem. It is licensed
  under the conditions described in the file LICENSE in the root
  directory of the NEST Acoustic Subsystem.
*/

/*
  This component provides the Detector and StdControl interfaces, and
  wires dependent components required by DetectorM.

  Author: Dr. Brian Flanagan <bflan@mitre.org>, Signal Processing
  Center, The MITRE Corporation.
*/
includes AcousticTuning;

configuration DetectorC
{
  provides {
    interface Detector;
    interface StdControl;
  }
}

implementation
{
  components DetectorM, SoundBlockFastM, IndexM, MedianIndexM,
    QuickMedianM, MinMaxM, MicC, TimerC, LedsC, ADCC, GenericComm as TuningComm;

  Detector = DetectorM;
  StdControl = DetectorM;

  DetectorM.SubControl -> MicC;
  DetectorM.SubControl -> TimerC;

  DetectorM.SoundBlock -> SoundBlockFastM;
  DetectorM.WarmUp -> SoundBlockFastM.WarmUp;
  DetectorM.SoundBlockConfig -> SoundBlockFastM.Config;
  DetectorM.RunMedOfMed -> MedianIndexM.MedianIndex[unique("MedianIndex")];
  DetectorM.RunMedOfDev -> MedianIndexM.MedianIndex[unique("MedianIndex")];
  DetectorM.Median -> QuickMedianM;
  DetectorM.MinMax -> MinMaxM;
  DetectorM.Timer -> TimerC.Timer[unique("Timer")];
  DetectorM.Leds -> LedsC;

  DetectorM.ReceiveTuningMsg -> TuningComm.ReceiveMsg[AM_ACOUSTIC_TUNING_MSG];

  QuickMedianM.MinMax -> MinMaxM;

  SoundBlockFastM.ADC -> MicC;
  SoundBlockFastM.ADCControl -> ADCC;
  SoundBlockFastM.Mic -> MicC;
  SoundBlockFastM.Timer -> TimerC.Timer[unique("Timer")];

  MedianIndexM.Index -> IndexM.Index;
  
}
