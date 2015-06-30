//Mohammad Rahimi
interface Excite {
  command result_t setEx(uint8_t excitation);
  command result_t setPowerMode(uint8_t mode);       //to turn device off after conversion or not
  command result_t setCoversionSpeed(uint8_t mode);  //to wait 50ms after turning devices on before sampling
  command result_t setAvergeMode(uint8_t mode);  //to Average before passing data back
}
