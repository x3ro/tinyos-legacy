/*									
 * Authors:  Lin Gu
 * Date:     2003-6-11
 */

configuration MIR {
  provides interface StdControl;
  provides interface Radar;

}

implementation {
 components Main, MIRM, LedsC, Sounder, AdcMir, LogicalTime, Peeker, SnoozeC;

 StdControl = MIRM.StdControl;
 MIRM.ADCControl -> AdcMir.StdControl;
 MIRM.SubControl -> Peeker.StdControl;
 Radar = MIRM;
 MIRM.UnderlyingADC -> AdcMir.MirADC;
 MIRM.Peek -> Peeker;
 MIRM.TimerControl -> LogicalTime.StdControl;
 MIRM.AdcMirTimer -> LogicalTime.Timer[unique("Timer")];
 MIRM.Snooze -> SnoozeC;
 MIRM.Sounder -> Sounder.StdControl;
}

