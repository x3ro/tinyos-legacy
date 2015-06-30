includes Tuning;

interface Tuning {

  command result_t set(tuning_key_t key, tuning_value_t value);
  command result_t get(tuning_key_t key, tuning_value_t *value);
  command result_t getDefault(tuning_key_t key, tuning_value_t *value, 
      tuning_value_t defaultValue);

}

