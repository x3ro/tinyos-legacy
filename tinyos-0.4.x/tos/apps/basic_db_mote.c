
char TOS_EVENT(LIGHT_DATA_READY)(int data){ 
  TOS_SIGNAL_EVENT(SENSOR_DATA)(&data, sizeof(int));
}

char TOS_EVENT(TEMPERATURE_DATA_READY)(int data){ 
  TOS_SIGNAL_EVENT(SENSOR_DATA)(&data, sizeof(int));
}
