includes WSN;
configuration RadioCommP2PTest {
}

implementation {
   components Main, 
              RadioCommP2PTestM, 
              RadioCRCPacket as Comm, 
              TimerC, 
              CC2420ControlM,
              SettingsC,
              LedsC;

   Main.StdControl -> RadioCommP2PTestM.Init;

   RadioCommP2PTestM.TimerControl -> TimerC;
   RadioCommP2PTestM.Timer->TimerC.Timer[unique("Timer")];

   RadioCommP2PTestM.RadioControl -> Comm;
   RadioCommP2PTestM.RadioSend -> Comm;
   RadioCommP2PTestM.RadioReceive -> Comm;

   RadioCommP2PTestM.CC2420Control -> CC2420ControlM;

   RadioCommP2PTestM.Leds -> LedsC;
   RadioCommP2PTestM.ReadResetCause -> SettingsC;
}
