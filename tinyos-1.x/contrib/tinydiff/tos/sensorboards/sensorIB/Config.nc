//Mohammad Rahimi
interface Config {
	command result_t  configSet(uint8_t dataType,uint8_t sensorType,uint8_t channel,uint8_t channelType,uint8_t param);
    command result_t convert(uint8_t channel,uint8_t channelType,uint16_t rawData);
	event result_t conversionReady(int16_t realData,uint8_t percision,uint8_t units,uint8_t param); 
    command result_t configQuery(uint8_t channel,uint8_t channelType);
    event result_t configReply(uint8_t dataType,uint8_t sensorType,uint8_t channel,uint8_t channelType);
}
