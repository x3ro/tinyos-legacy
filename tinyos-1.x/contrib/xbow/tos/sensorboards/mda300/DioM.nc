/*
 *
 * Copyright (c) 2003 The Regents of the University of California.  All 
 * rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 *
 * - Neither the name of the University nor the names of its
 *   contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE REGENTS AND CONTRIBUTORS ``AS IS''
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
 * THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
 * PARTICULAR  PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE REGENTS OR
 * CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 *
 * Authors:   Mohammad Rahimi mhr@cens.ucla.edu
 * History:   created 08/14/2003
 * History:   modified 11/14/2003
 *
 * driver for PCF8574APWR on mda300ca
 *
 */

module DioM {
    provides {
        interface StdControl;
        interface Dio[uint8_t channel];
    }
    uses {
        interface StdControl as I2CPacketControl;
        interface Leds;
        interface I2CPacket;
    }
}

implementation {

  //Note we have no async code here so there is no possibility of any race condition

  uint8_t state;      //keep state of our State Machine 
  uint8_t io_value;         //keep track of what is actually on the chip
  uint8_t mode[8];      //keep track of the mode of each channel
  uint16_t count[8];   //we can count the number of pulses 
  uint8_t bitmap_high,bitmap_low,bitmap_toggle;   //the param setting we get this is for channel number
  uint8_t i2c_data;    //the data read from the chip

#define XOR(a,b)  ((a) & ~(b))|(~(a) & (b))

    //set of bitwise functions
#define  testbit(var, bit)   ((var) & (1 <<(bit)))      //if zero then return zero and if one not equal zero
#define  setbit(var, bit)    ((var) |= (1 << (bit)))
#define  clrbit(var, bit)    ((var) &= ~(1 << (bit)))

    //Interrupt definition
#define INT_ENABLE()  sbi(EIMSK , 4)
#define INT_DISABLE() cbi(EIMSK , 4)


    enum {GET_DATA, SET_OUTPUT_HIGH, SET_OUTPUT_LOW, SET_OUTPUT_TOGGLE , GET_THEN_SET_INPUT, IDLE , INIT};


    command result_t StdControl.init() {
          mode[0] = RISING_EDGE;
          mode[1] = RISING_EDGE;
          mode[2] = RISING_EDGE;
          mode[3] = RISING_EDGE;
          mode[4] = RISING_EDGE;
          mode[5] = RISING_EDGE;
          mode[6]=DIG_OUTPUT;
          mode[7]=DIG_OUTPUT;
          io_value=0xff;         //set all inputs to high and relays OFF (we know chip boots to 0xff)
          state=INIT;             
        call I2CPacketControl.init();
        return SUCCESS;
    }
    


    task void init_io()
      {
           if(call I2CPacket.readPacket(1,0x03) == FAIL)
             {
               post init_io();
             }        
      }

    command result_t StdControl.start() {
        cbi(DDRE,4);            //Making INT pin input
        //cbi(EICRB,ISC40);       //Making INT sensitive to falling edge
        //sbi(EICRB,ISC41);
        //INT_ENABLE();           //probably bus is stable and now we are ready 
        post init_io();
        return SUCCESS;
    }
    
    command result_t StdControl.stop() {
     return SUCCESS;
    }
        
    command result_t Dio.setparam[uint8_t channel](uint8_t modeToSet)
        {    
            //we only set INT flag if we set any channel to input otherwise we do not touch it.
            mode[channel]=modeToSet;
            if( ((modeToSet & RISING_EDGE) == 0) & ((modeToSet & FALLING_EDGE) == 0) ) mode[channel] |= RISING_EDGE;
            return FAIL;
        }
    
    task void set_io_high()
      {
        uint8_t status;
        uint8_t i;
        status = FALSE;
        if(state==IDLE) state= SET_OUTPUT_HIGH; 
        else { status=TRUE; post set_io_high(); }
        if(status==TRUE) return; 
        i2c_data=io_value;
        for(i=0;i<=7;i++) {
          if(testbit(bitmap_high,i)) {    
            setbit(i2c_data,i);
          }
          if(!(mode[i] & DIG_OUTPUT)) setbit(i2c_data,i);           //if we set them to High as week input
        }
        //we should leave inputs as high and outputs either high or low
        if( (call I2CPacket.writePacket(1,(char*) &i2c_data, 0x01)) == FAIL)
          {
            state=IDLE;
            post set_io_high();
          }
        else bitmap_high=0x0;
      }
    
    task void set_io_low()
      {
        uint8_t status;
        uint8_t i;
        status = FALSE;
        if(state==IDLE) state= SET_OUTPUT_LOW; 
        else { status=TRUE; post set_io_low(); }
        if(status==TRUE) return; 
        i2c_data=io_value;
        //we should leave inputs as high and outputs either high or low
        for(i=0;i<=7;i++) {
          if(testbit(bitmap_low,i)) {
            clrbit(i2c_data,i);
          }
          if(!(mode[i] & DIG_OUTPUT)) setbit(i2c_data,i);             //if we set them to High as week input
        }
        if( (call I2CPacket.writePacket(1,(char*) &i2c_data, 0x01)) == FAIL)
          {
            state=IDLE;
            post set_io_low();
          }
        else bitmap_low=0x0;
      }
    
    task void set_io_toggle()
      {
        uint8_t i;
        if(state==IDLE) state= SET_OUTPUT_TOGGLE; 
        else { post set_io_toggle(); return; }
        i2c_data=io_value;
        //we should leave inputs as high and outputs either high or low
        for(i=0;i<=7;i++) {
          if(testbit(bitmap_toggle,i)) {
            if (testbit(i2c_data,i)) {
              clrbit(i2c_data,i);
            } else {
              setbit(i2c_data,i);
            }
          }
          if(!(mode[i] & DIG_OUTPUT)) setbit(i2c_data,i);            //if we set them to High as week input
        }                     
        if( (call I2CPacket.writePacket(1,(char*) &i2c_data, 0x01)) == FAIL)
          {
            state=IDLE;
            post set_io_toggle();
          }
        else bitmap_toggle=0x0;
      }
    
    command result_t Dio.Toggle[uint8_t channel]()
      {
        if(DIG_OUTPUT & mode[channel])
          {
            setbit(bitmap_toggle,channel); 
            post set_io_toggle();
            return SUCCESS;
          }
        else return FALSE;
      }
    
    command result_t Dio.high[uint8_t channel]()
      {
        if(DIG_OUTPUT & mode[channel])
          {
            setbit(bitmap_high,channel);            
            post set_io_high();
            return SUCCESS;
          }
        else return FALSE;
      }
    
    command result_t Dio.low[uint8_t channel]()
      {
        if(DIG_OUTPUT & mode[channel])
          {
            setbit(bitmap_low,channel);
            post set_io_low();
            return SUCCESS;
          }
        else return FALSE;
      }
    
    command result_t Dio.getData[uint8_t channel]()
      {    
        uint16_t counter;
        counter = count[channel];
        if(RESET_ZERO_AFTER_READ & mode[channel]) {count[channel]=0;}
        signal Dio.dataReady[channel](counter);
        return SUCCESS;
      } 
    
    default event result_t Dio.dataReady[uint8_t channel](uint16_t data) 
        {
            return SUCCESS;
        } 
    /*        
    command result_t Dio.getValue[uint8_t channel]()
      {    
        bool value;
        value = (testbit(io_value,channel) != 0);
        signal Dio.valueReady[channel](io_value);
        return SUCCESS;
      } 
    */

    task void read_io()
        {
           uint8_t status;
           status = FALSE;
               if(state==IDLE) state=GET_DATA; 
               else { status=TRUE; post read_io(); }
           if(status==TRUE) return; 
           else if(call I2CPacket.readPacket(1,0x03) == FAIL)
               {
                           state=IDLE;
                           post read_io();
               }
        }

    event result_t I2CPacket.writePacketDone(bool result) {
        if(result) {
            if ( state == SET_OUTPUT_HIGH || state == SET_OUTPUT_LOW || state == SET_OUTPUT_TOGGLE) {
              //io_value=i2c_data;
              state = IDLE;
              //INT_DISABLE();
              //if(!post read_io()) INT_ENABLE();

            }
        }
        return SUCCESS;
    }
    
    event result_t I2CPacket.readPacketDone(char length, char* data) {
       uint8_t ChangedState;
       int i;
       i2c_data=*data;
       if (length != 1)
           {
             state = IDLE;
               INT_ENABLE();
               return FALSE;
           } 

       
       if(state==INIT)
         {
             io_value=i2c_data;
             state=IDLE;
             INT_ENABLE();
         }
       
       if(state==GET_DATA) {
         ChangedState = XOR(io_value,i2c_data);     //see those one who has changed               
         for(i=0;i<8;i++){
           if( !( mode[i] & DIG_OUTPUT) ){       //we only care about channels which are not output (input channels)
             if(testbit(ChangedState,i)) {       //find the channels which are realy changed
               if( mode[i] & RISING_EDGE )
                 {
                   if(testbit(io_value,i)==0 && testbit(i2c_data,i)!=0) { 
                     if(EVENT & mode[i]) signal Dio.dataReady[i](count[i]);
                     //                           if (count[i] == 0xffff) signal Dio.dataOverflow[i]();
                     count[i]++; 
                   }
                 }
               if( mode[i] & FALLING_EDGE )
                 {
                   if(testbit(io_value,i)!=0 && testbit(i2c_data,i)==0) {
                     if(EVENT & mode[i]) signal Dio.dataReady[i](count[i]);
                     //                           if (count[i] == 0xffff) signal Dio.dataOverflow[i]();
                     count[i]++;
                   }
                 }
             }               
           }
         }
           io_value=i2c_data;
           INT_ENABLE();
           state = IDLE;
       }
       return SUCCESS;
    }
                
   TOSH_SIGNAL(SIG_INTERRUPT4)
       {
         INT_DISABLE();
         if(!post read_io()) INT_ENABLE();
         return;
       }   

}
