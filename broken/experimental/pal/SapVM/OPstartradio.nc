/**
 * @author Mark Kranz
 */

includes Mate;

configuration OPstartradio {
  provides interface MateBytecode;
}

implementation {
  components LedsC
    , CC2420RadioC as Comm
    , OPstartradioM
    , MVirusProxy;
  MateBytecode = OPstartradioM;

  OPstartradioM.Leds -> LedsC;
  OPstartradioM.RadioControl -> Comm;
  OPstartradioM.RadioControl -> MVirusProxy;
}
