/**
 * @author Mark Kranz
 */

includes Mate;

configuration OPstopradio {
  provides interface MateBytecode;
}

implementation {
  components LedsC
    , CC2420RadioC as Comm
    , OPstopradioM
    , MVirusProxy;
  MateBytecode = OPstopradioM;

  OPstopradioM.Leds -> LedsC;
  OPstopradioM.RadioControl -> Comm;
  OPstopradioM.RadioControl -> MVirusProxy;
}
