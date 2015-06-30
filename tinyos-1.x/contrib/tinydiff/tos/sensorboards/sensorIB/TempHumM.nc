//mohammad Rahmim @ 01/14/2003
//driver for sensirion temperature and humidity sensor

module TempHumM {
  provides {
    interface StdControl;
    interface ADC as TempSensor;
    interface ADC as HumSensor;
  }
  uses {
    interface Leds;
  }
}
implementation {


//include "tos.h"

//states
#define READY 0
#define TEMP_MEASUREMENT 1
#define HUM_MEASUREMENT 2

//Interrupt definition.It is INT3 in sch which is INT7 of MCU! 
#define INT_ENABLE()  sbi(EIMSK , 7)
#define INT_DISABLE() cbi(EIMSK , 7)

//#define delay() asm volatile  ("nop" ::)
/*
#define SET_CLOCK() sbi(PORTC, 3)
#define CLEAR_CLOCK() cbi(PORTC, 3)
#define SET_DATA() sbi(PORTD, 3)
#define CLEAR_DATA() cbi(PORTD, 3)
#define MAKE_DATA_OUTPUT() sbi(DDRD, 3)
#define MAKE_DATA_INPUT() cbi(DDRD, 3)
#define GET_DATA() (inp(PIND) >> 3) & 0x1
*/

//usese PW0 (PORTC,0) for Clock and INT3 (PORTE,7) for data.
#define SET_CLOCK() sbi(PORTC, 0)
#define CLEAR_CLOCK() cbi(PORTC, 0)
#define MAKE_CLOCK_OUTPUT() sbi(DDRC, 0)    
#define SET_DATA() sbi(PORTE, 7)
#define CLEAR_DATA() cbi(PORTE, 7)
#define MAKE_DATA_OUTPUT() sbi(DDRE, 7)
#define MAKE_DATA_INPUT() cbi(DDRE, 7)
#define GET_DATA() (inp(PINE) >> 7) & 0x1


void delay() {
    asm volatile  ("nop" ::);
    asm volatile  ("nop" ::);
    asm volatile  ("nop" ::);
}


//#define TEMP_COMMAND 0x1e
#define TEMP_COMMAND 0x03
#define HUM_COMMAND  0x05
#define SOFT_RESET   0x1e 

//#define TOS_FRAME_TYPE Sensor_frame
 char state;
 int16_t data;
 uint16_t temp,hum;
 float t=25,h;   //temprature and humidity values.we set temprature to 25.
                 //if sombody not reads temprature and reads humidity then by t=25 it means 
                 //no temperature compensation  

static inline void clk(){
    delay();
    CLEAR_CLOCK();
    delay();
    SET_CLOCK();
}

static inline void  ack()
{
  MAKE_DATA_OUTPUT();
  CLEAR_DATA();
  delay();
  SET_CLOCK();
  delay();
  CLEAR_CLOCK();
  MAKE_DATA_INPUT();
}

static inline void initseq()
{ 
  MAKE_DATA_OUTPUT();
  SET_DATA();
  CLEAR_CLOCK();   
  delay();         
  SET_CLOCK();
  delay();
  CLEAR_DATA();
  delay();
  CLEAR_CLOCK();
  delay();
  SET_CLOCK();
  delay(); 
  SET_DATA();
  delay(); 
  CLEAR_CLOCK();
}

static inline void reset()
{
  int i;
  MAKE_DATA_OUTPUT();
  SET_DATA();
  CLEAR_CLOCK();
  for (i=0;i<9;i++) {
    SET_CLOCK();
    delay();
    CLEAR_CLOCK();
  }
}


static inline char processCommand(int cmd)
{
  int i;
  int CMD=cmd;
  cmd &= 0x1f;
  INT_DISABLE();
  reset();           
  initseq();        //sending the init sequence
  for(i=0;i<8;i++){
    if(cmd & 0x80) SET_DATA();
    else CLEAR_DATA();
    cmd = cmd << 1 ;
    SET_CLOCK();
    delay();              
    delay();              
    CLEAR_CLOCK();        
    
  }
  MAKE_DATA_INPUT();
  delay();
  SET_CLOCK();
  delay();
  if(GET_DATA()) 
    { 
      reset(); 
      return 0; 
    }
  delay();
  CLEAR_CLOCK();
  if( CMD==TEMP_COMMAND || CMD==HUM_COMMAND){
      INT_ENABLE();
  }
 return 1;
}

//char TOS_COMMAND(SENSOR_INIT)(){
command result_t StdControl.init() { 
  state=READY;
  INT_DISABLE();
  MAKE_CLOCK_OUTPUT();
  reset();
  processCommand(SOFT_RESET);
  return SUCCESS;
}
command result_t StdControl.start() {
  return SUCCESS;
}

command result_t StdControl.stop() {
  return SUCCESS;
}


default event result_t TempSensor.dataReady(uint16_t tempData) 
{
    return SUCCESS;
}

default event result_t HumSensor.dataReady(uint16_t humData) 
{
    return SUCCESS;
}


task void readSensor()
{
  char i;
  char CRC=0;  
  data=0; 
  for(i=0;i<8;i++){
    SET_CLOCK();   
    delay();
    data |= GET_DATA();
    data = data << 1;
    //    if(i!=7) data = data << 1;
    CLEAR_CLOCK();
 }
  ack();
  for(i=0;i<8;i++){
    SET_CLOCK();   
    delay();
    data |= GET_DATA();
    //    data = data << 1;
    if(i!=7) data = data << 1;  //the last byte of data should not be shifted
    CLEAR_CLOCK();
    
 }
  ack();
  for(i=0;i<8;i++){           //I am not cheching the checksum
    SET_CLOCK();   
    delay();
    CRC |= GET_DATA();
    if(i!=7)CRC = CRC << 1;
    CLEAR_CLOCK();
 }
  //ack with high as it should be for the CRC ack
  MAKE_DATA_OUTPUT();
  SET_DATA();          
  delay();
  SET_CLOCK();
  delay();
  CLEAR_CLOCK(); 
  if(state==TEMP_MEASUREMENT){
      temp=data;
      t= (((float)(temp) )*0.98-3840)/100;
      //we convert to Fahrenheit to avoid negative values in transmition
      //temp= (int16_t) t;             //for centigrade    
      //if(temp > 100 ) temp=100;      //for centigrade    
      //if(temp < -15 ) temp=-10;      //for centigrade    
      temp= (uint16_t) (t * 180 +3200 ); 
      signal TempSensor.dataReady(temp);
      //signal TempSensor.dataReady(data);
  }
  else if(state==HUM_MEASUREMENT) {
      hum=data;
      h= 0.0405 * (float) (hum) - 4 - (float)(hum) * (float)(hum)*0.0000028;
      h= (t-25) * (0.01 + 0.00128 * hum) + h;
      hum= (uint16_t) h;
      if(hum > 100 ) hum=100;
      if(hum < 0 ) hum=0;
      signal HumSensor.dataReady(hum);
      //signal HumSensor.dataReady(data);
  }
  state=READY;
}



TOSH_SIGNAL(SIG_INTERRUPT7)
{
    INT_DISABLE();
    post readSensor();
    return;
 }


command result_t TempSensor.getData()
{
  if(state!= READY ){
    reset();
      }
  state=TEMP_MEASUREMENT;
  processCommand(TEMP_COMMAND);
  return SUCCESS;
}


command result_t HumSensor.getData()
{
    if(state!= READY ){
        reset();
    }
    state=HUM_MEASUREMENT;
    processCommand(HUM_COMMAND);
    return SUCCESS;
}

command result_t TempSensor.getContinuousData(){
    return FALSE;
}

command result_t HumSensor.getContinuousData(){
    return FALSE;
}

}
