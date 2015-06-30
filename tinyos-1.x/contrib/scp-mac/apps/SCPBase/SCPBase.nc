includes AM;
includes Timer;
includes config;   
includes protocols;
includes AM_emstar;
includes ScpMsg;
includes SCPBaseMsg;

configuration SCPBase { 
}

implementation
{
#include "PlatformConstants.h"

   components Main, SCPBaseM,
       Scp as Mac, UART,
       FramerM, LedsC, NoLeds, TOSMsgTranslateM;
   
   Main.StdControl -> SCPBaseM;

   SCPBaseM.UARTControl -> FramerM;

   SCPBaseM.Framer -> FramerM.Framer[unique("Framer")];
   SCPBaseM.FramerSendDone -> FramerM.Framer[unique("Framer")];
   SCPBaseM.FramerStatus -> FramerM.Framer[unique("Framer")];

   SCPBaseM.Leds -> LedsC;

   SCPBaseM.TOSMsgTranslate -> TOSMsgTranslateM;      

   SCPBaseM.MacMsg -> Mac;
   SCPBaseM.MacStdControl -> Mac;
#ifdef RADIO_TX_POWER
   SCPBaseM.RadioTxPower -> Mac;
#endif

   FramerM.ByteControl -> UART;
   FramerM.ByteComm -> UART;
   FramerM.Leds -> NoLeds;
}
