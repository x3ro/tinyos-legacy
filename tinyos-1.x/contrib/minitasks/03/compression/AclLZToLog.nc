/*                                                                      tab:4
 * Author: Ning Xu
 * Create: Oct 27,2002
 * 
 */

configuration AclLZToLog {
   provides interface Sensing;
 }
implementation {
  components Main,AclLZToLogM,SimpleCmd,Logger,Accel,ClockC,LedsC;

  Main.StdControl -> AclLZToLogM;
  AclLZToLogM.Leds -> LedsC;
  AclLZToLogM.AccelX -> Accel.AccelX;
  AclLZToLogM.AccelY -> Accel.AccelY;
  AclLZToLogM.SubControl -> Accel;
  AclLZToLogM.SubControl -> Logger;
  AclLZToLogM.LoggerWrite -> Logger.LoggerWrite;
  AclLZToLogM.Clock -> ClockC;
  Sensing = AclLZToLogM.Sensing;
}
