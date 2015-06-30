//Mohammad Rahimi
interface Sample {
    //channel number.only relevent for ADC and Dio
    //channel type can be ANALOG,BATTERY,TEMPERATURE,HUMIDITY,DIGITAL,COUNTER
    //time interval in 0.1 sec
    command result_t sample(uint8_t channel,uint8_t channelType,uint8_t interval); 
    event result_t dataReady(uint8_t channel,uint8_t channelType,uint16_t data); 
}
