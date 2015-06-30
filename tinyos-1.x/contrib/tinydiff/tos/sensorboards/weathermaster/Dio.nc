//Mohammad Rahimi
interface Dio {
  command result_t getData();
  command result_t high();
  command result_t low();
  command result_t reset();
  //the number of egdes to count before geting u back that data
  //if zero it always count and only give u back the resltu when`
  command result_t setCount(uint16_t count);
  command result_t setparam(uint8_t io,uint8_t mode);
  event result_t dataReady(uint16_t data);
}
