
/**
 * Byte and Command interface for using the I2C hardware bus
 */
interface I2C
{
  command result_t sendStart();
  command result_t sendEnd();
  command result_t read(bool ack);
  command result_t write(char data);
 
  event result_t sendStartDone();
  event result_t sendEndDone();
  event result_t readDone(char data);
  event result_t writeDone(bool success);
}
