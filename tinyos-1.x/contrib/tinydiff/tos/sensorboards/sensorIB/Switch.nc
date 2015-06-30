//Mohammad Rahimi
interface Switch {
  command result_t get();
  command result_t set(char position, char value);
  command result_t setAll(char value);

  event result_t getDone(char value);
  event result_t setDone(bool result);
  event result_t setAllDone(bool result);
}

