// controls for the voltage reference monitor
#define MAKE_BAT_MONITOR_OUTPUT() sbi(DDRA, 5)
#define MAKE_ADC_INPUT() cbi(DDRF, 5)
#define SET_BAT_MONITOR() sbi(PORTA, 5)
#define CLEAR_BAT_MONITOR() cbi(PORTA, 5)

//controls for the thermistor sensor
#define SET_THERM_POWER() sbi(PORTA,7)
#define CLEAR_THERM_POWER() cbi(PORTA,7)



enum {
    BATTERY_PORT = 7,             //adc port for battery voltage
    TEMP_PORT = 1
};

