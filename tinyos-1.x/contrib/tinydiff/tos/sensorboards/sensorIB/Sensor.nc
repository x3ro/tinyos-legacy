//Mohammad Rahimi
interface Sensor {
  command result_t getData();
  event result_t dataReady(int16_t data);
}

