/*
  D e t F a s t . n c

  This file (c) Copyright 2004 The MITRE Corporation (MITRE)

  This file is part of the NEST Acoustic Subsystem. It is licensed
  under the conditions described in the file LICENSE in the root
  directory of the NEST Acoustic Subsystem.
*/

// 04/23/04 BPF  Convert to component interface


configuration DetFast
  { /* provides nothing */ }

implementation {
  components
    Main, DetFastM, TimerC, LedsC, Sounder, DetectorC; 

  Main.StdControl -> DetFastM;
  Main.StdControl -> TimerC;
  Main.StdControl -> DetectorC;

  DetFastM.Detector -> DetectorC;
  DetFastM.Timer -> TimerC.Timer[unique("Timer")];
  DetFastM.Leds -> LedsC;
  DetFastM.SoundControl -> Sounder;
} // DetFast
