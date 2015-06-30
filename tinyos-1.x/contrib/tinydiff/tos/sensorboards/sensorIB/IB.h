
enum {
    InputChannel=0,
    OutputChannel=1
};

enum {
    RisingEdge=0,
    FallingEdge=1,
    Edge=2
};


enum {
    NO_EXCITATION=0,
    ADCREF=1,
    THREE_VOLT=2,
    FIVE_VOLT=3,
    ALL_EXCITATION=4	
};

enum {
    POWER_SAVING_MODE=0,
    NO_POWER_SAVING_MODE=1
};

enum {
    FAST_COVERSION_MODE=0,
    SLOW_COVERSION_MODE=1
};

enum {
    NO_AVERAGE = 1,
    FOUR_AVERAGE = 4,
    EIGHT_AVERAGE = 8,
    SIXTEEN_AVERAGE = 16,
};

enum { 
    ATTENTION_PACKET = 9 
};

enum {
    ANALOG=0,
    BATTERY=1,
    TEMPERATURE=2,
    HUMIDITY=3,
    DIGITAL=4,
    COUNTER=5
};

enum {
    PENDING,
    NOT_PENDING
};

enum {
    MUX_CHANNEL_SEVEN = 0xC0,
    MUX_CHANNEL_EIGHT = 0x30,
    MUX_CHANNEL_NINE = 0x0C, 
    MUX_CHANNEL_TEN = 0x03
};

enum{
    LOCK,
    UNLOCK
};
//Please not that the number of clients that can be handles by Smapler is MAX_CHANNEL which is defined here
//u can set it up to maximum of 127 values.I currently set it to 10.Please notice that addition of each 1 
//possible client cost 64 byte.This will be reduce soon by optimizing the data structure but not that magically.
#define MAX_SAMPLERECORD 25
#define BATTERY_PORT 7
