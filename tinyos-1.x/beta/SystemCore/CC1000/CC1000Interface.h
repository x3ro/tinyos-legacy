enum {
 AM_CC1000INTERFACEDRIPMSG = 8,
};

typedef struct CC1000InterfaceDripMsg {

  uint8_t rfPowerChanged:1;
  uint8_t lplPowerChanged:1;
  uint8_t pad:6;

// Valid values: 1-15.
  uint8_t rfPower;  

// Valid values: 0(full duty cycle) to 3(lowest duty cycle).
  uint8_t lplPower;
  
} CC1000InterfaceDripMsg;
