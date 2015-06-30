
/**
 * <h1>LeadTek 9546 Sirf-based GPS sensor</h1>
 *
 * <ul>
 * <li>Compact module size (measured only 25.4*24.1*6.8mm, 
 *     including RF shield and connector) suitable for
 *     space-sensitive applications.</li>
 * <li>Onboard MMCX RF connector support active and passive antenna.</li>
 * <li>20 pin Molex® board connector (Part#52991) for easy 
 *     module interface and integration.</li>
 * <li>SiRF 2e/LP low power chipset with Trickle Power 
 *     mode support for additional power saving.</li>
 * <li>12 Channels “All-In-View” Tracking with 
 *     onboard TCXO for superior sensitivity and performance.</li>
 * <li>Cold/Warm/Hot Start Time: 45/38/8 Seconds.</li>
 * <li>Reacquisition Time: 0.1 seconds.</li>
 * <li>Support NMEA-0183 and SiRF Binary protocol 
 *     (default NMEA 4800 with GGA, RMC, VTG at 1Hz
 *     and GSV, GSA at 0.2Hz).</li>
 * <li>Multi-path Mitigation Hardware.</li>
 * <li>On-board RTCM SC-104 DGPS and WASS Demodulator enabled.</li>
 * <li>Integrated ARM7TDMI CPU for customized software integration.</li>
 *</ul>
 *
 *
 * Parts of this code were written or modified for FireBug project
 * funded by the NSF Information Technology Research
 * initiative.  Copyright Regents of the University of 
 * of California, 2003.
 *
 * @url http://firebug.sourceforge.net
 * 
 * @author David. M. Doolin
 */

includes sensorboard;
includes leadtek_9546;

configuration gps_driver {

  provides {

    interface StdControl;
    interface HLSensor;
  }  
}

implementation {

   components  gps_driverM,
               MicaWbSwitch,
               GpsPacket,
               LedsC;


  gps_driverM.StdControl = StdControl;
  HLSensor                 = gps_driverM; 
  StdControl             = MicaWbSwitch;

   gps_driverM.Leds        -> LedsC;

   //gps_driverM.SwitchControl  -> MicaWbSwitch.StdControl;
   gps_driverM.PowerSwitch -> MicaWbSwitch.Switch[0];
   gps_driverM.IOSwitch    -> MicaWbSwitch.Switch[1];

   gps_driverM.GpsControl  -> GpsPacket;
   gps_driverM.GpsSend     -> GpsPacket;
   gps_driverM.GpsReceive  -> GpsPacket;

   // FIXME: Remove the GpsCmd abstraction.  In fact, 
   // remove the I2CSwitchCmds interface completely.
   //gps_driverM.GpsCmd      -> GpsPacket.GpsCmd;
   gps_driverM.I2CSwitchCmds -> GpsPacket.I2CSwitchCmds;
}
