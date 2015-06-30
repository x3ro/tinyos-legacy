
interface GpsCmd
{
       command result_t PowerSwitch(uint8_t PowerState);  
       /* 0 => gps power off; 1 => gps power on */

       event result_t PowerSet(uint8_t PowerState);                //notify power is on/off 

       command result_t TxRxSwitch(uint8_t State);  
       /* 0 => gps rx/tx disabled; 1 => gps rx/tx enabled */

       event result_t TxRxSet(uint8_t rtstate);                //notify tx/rx is on/off 


}

