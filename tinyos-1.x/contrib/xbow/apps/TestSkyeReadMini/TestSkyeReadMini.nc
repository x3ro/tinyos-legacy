/*
 *
 * Systemic Realtime Design, LLC.
 * http://www.sysrtime.com
 *
 * Authors:  Qingwei Ma
 *           Michael Li
 *
 * Date last modified:  9/30/04
 *
 */

includes SkyeReadMini;
includes MiniPacketizer;


configuration TestSkyeReadMini {
}
implementation {

  components Main, TestSkyeReadMiniM, SkyeReadMiniC, MiniPacketizerC, LedsC; 

  Main.StdControl -> TestSkyeReadMiniM;
  Main.StdControl -> SkyeReadMiniC;
  Main.StdControl -> MiniPacketizerC;

  TestSkyeReadMiniM.Mini -> SkyeReadMiniC;
  TestSkyeReadMiniM.MiniControl -> SkyeReadMiniC;
  TestSkyeReadMiniM.Packetizer -> MiniPacketizerC;

  TestSkyeReadMiniM.Leds -> LedsC;
}
