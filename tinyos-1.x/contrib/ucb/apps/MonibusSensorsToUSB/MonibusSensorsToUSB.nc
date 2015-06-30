// $Id: MonibusSensorsToUSB.nc,v 1.2 2005/07/04 09:30:40 neturner Exp $

/**
 * At some interval, send a MonibusSensorMsg (via UART1/USB) containing
 * the sensor readings.
 * <p>
 * @author Neil E. Turner
 */

includes MonibusSensorMsg;

configuration MonibusSensorsToUSB {
}

implementation {
  components Main
    , GenericComm as USB_UART
    , Voltage12C
    , HamamatsuC
    , LedsC as LEDs
    , MonibusHPLUARTC
    , MonibusSensorsToUSBM
    , TimerC
    ;

  Main.StdControl -> MonibusSensorsToUSBM.StdControl;

  MonibusSensorsToUSBM.Leds -> LEDs;
  MonibusSensorsToUSBM.MessageControl -> USB_UART.Control;
  MonibusSensorsToUSBM.PAR -> HamamatsuC.PAR;
  MonibusSensorsToUSBM.HamamatsuControl -> HamamatsuC;
  MonibusSensorsToUSBM.SendMsg -> USB_UART.SendMsg[AM_MONIBUSSENSORMSG];
  MonibusSensorsToUSBM.TSR -> HamamatsuC.TSR;
  MonibusSensorsToUSBM.Timer  -> TimerC.Timer[unique("Timer")];
  MonibusSensorsToUSBM.TimerControl -> TimerC.StdControl;
  MonibusSensorsToUSBM.Voltage12 -> Voltage12C.ADC;
  MonibusSensorsToUSBM.Voltage12Control -> Voltage12C;
}
