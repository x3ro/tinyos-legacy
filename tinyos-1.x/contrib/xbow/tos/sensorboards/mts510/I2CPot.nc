interface I2CPot
{
  command result_t writePot(char addr, char pot, char data);
  command result_t readPot(char addr, char pot);  
  event result_t readPotDone(char data, bool result);
  event result_t writePotDone(bool result);
}
