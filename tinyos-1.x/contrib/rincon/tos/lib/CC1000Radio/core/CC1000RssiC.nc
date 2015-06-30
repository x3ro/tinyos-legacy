
/**
 * CC1000 RSSI readings
 * Use unique("Rssi") when connecting to one of the parameterized interfaces
 *
 * @author David Moss
 */

configuration CC1000RssiC {
  provides {
    interface StdControl;
    interface Rssi[uint8_t id];
  }
}

implementation {
  components CC1000RssiM, ADCC;
  
  StdControl = CC1000RssiM;
  Rssi = CC1000RssiM;
  
  CC1000RssiM.ADC -> ADCC.ADC[TOS_ADC_CC_RSSI_PORT];
  CC1000RssiM.ADCControl -> ADCC;
}

