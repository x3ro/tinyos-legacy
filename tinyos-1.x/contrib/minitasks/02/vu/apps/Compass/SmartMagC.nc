/**
 * Compass - Copyright (c) 2003 ISIS
 *
 * Author: Peter Volgyesi, based on UCB work (Cory Sharp)
 **/

configuration SmartMagC {
  provides {
    interface SmartMag;
    interface StdControl;
  }
}

implementation {
  components SmartMagM, Mag;
  
  SmartMag              = SmartMagM;
  StdControl            = SmartMagM;
  
  SmartMagM.MagControl -> Mag;
  SmartMagM.MagSetting -> Mag;
  SmartMagM.MagX       -> Mag.MagX;
  SmartMagM.MagY       -> Mag.MagY;
}

