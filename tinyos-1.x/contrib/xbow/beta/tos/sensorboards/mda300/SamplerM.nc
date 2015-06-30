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
 * History:   created  08/14/2003
 * history:   modified 11/14/2003
 *
 *
 */


module SamplerM
{
    provides interface StdControl as SamplerControl;
    provides interface Sample;
    provides command result_t PlugPlay();

  uses {
      interface Leds;
      interface Timer as SamplerTimer;

      //analog channels
      interface StdControl as IBADCcontrol;
      interface ADConvert as ADC0;
      interface ADConvert as ADC1;
      interface ADConvert as ADC2;
      interface ADConvert as ADC3;
      interface ADConvert as ADC4;
      interface ADConvert as ADC5;
      interface ADConvert as ADC6;
      interface ADConvert as ADC7;
      interface ADConvert as ADC8;
      interface ADConvert as ADC9;
      interface ADConvert as ADC10;
      interface ADConvert as ADC11;
      interface ADConvert as ADC12;
      interface ADConvert as ADC13;
      //ADC parameters
      interface SetParam as SetParam0;
      interface SetParam as SetParam1;
      interface SetParam as SetParam2;
      interface SetParam as SetParam3;
      interface SetParam as SetParam4;
      interface SetParam as SetParam5;
      interface SetParam as SetParam6;
      interface SetParam as SetParam7;
      interface SetParam as SetParam8;
      interface SetParam as SetParam9;
      interface SetParam as SetParam10;
      interface SetParam as SetParam11;
      interface SetParam as SetParam12;
      interface SetParam as SetParam13;


      //health channels temp,humidity,voltage
      interface StdControl as BatteryControl;
      interface ADConvert as Battery;
      interface StdControl as TempHumControl;
      interface ADConvert as Temp;
      interface ADConvert as Hum;

      //digital and relay channels
      interface StdControl as DioControl;
      interface Dio as Dio0;
      interface Dio as Dio1;
      interface Dio as Dio2;
      interface Dio as Dio3;
      interface Dio as Dio4;
      interface Dio as Dio5;

      //counter channels
      interface StdControl as CounterControl;
      interface Dio as Counter;
      
      command result_t Plugged();
  }
}
implementation
{

#define SCHEDULER_RESPONSE_TIME 100
#define TIME_SCALE 100                 //this means we have resolution of 0.1 sec
#define FLAG_SET 1
#define FLAG_NOT_SET 0

    //flag for power saving
    uint8_t flag25,flag33,flag50;

    //main data structure 10 byte per recorde
    struct SampleRecords{
      uint8_t channel;              
      uint8_t channelType;         
      //      uint8_t param;
      int16_t ticks_left;         //used for keeping the monostable timer 
      int16_t sampling_interval;  //Sampling interval set by command above, It is in second, SampleRecord in no use if set to zero.
    }SampleRecord[MAX_SAMPLERECORD];
    
    
    //check what is the SampleRecords that are avilable and return one that is available
    static inline int8_t get_avilable_SampleRecord()
        {
            int8_t i;
            for(i=0;i<MAX_SAMPLERECORD;i++) if( SampleRecord[i].sampling_interval == SAMPLE_RECORD_FREE ) return i;
            return -1; //not available SampleRecord
        }
    
    //find the next channel which should be serviced. 
    //    task 
    void next_schedule(){
        int8_t i;
        int16_t min=SCHEDULER_RESPONSE_TIME;   //minimum time to ba called.we set it to 15Sec min so that if a new sampling request comes we reply with 15 sec delay.

        for(i=0;i<MAX_SAMPLERECORD;i++) //find out any one who should be serviced before next 15 second.
            {
             if( SampleRecord[i].sampling_interval != SAMPLE_RECORD_FREE )
                 {
                     if(SampleRecord[i].ticks_left < min) min = SampleRecord[i].ticks_left;
                 }
            }
        for(i=0;i<MAX_SAMPLERECORD;i++) //set the next time accordingly
            {
                if( SampleRecord[i].sampling_interval != SAMPLE_RECORD_FREE )
                    {
                        SampleRecord[i].ticks_left = SampleRecord[i].ticks_left-min;
                    }
            }
        min=min * TIME_SCALE ;   //since timer gets input in milisecond and we get command in 0.1sec.
        call SamplerTimer.start(TIMER_ONE_SHOT , min);
    }

    static inline void setparam_analog(uint8_t i,uint8_t param)
        {
             switch(SampleRecord[i].channel){
            case 0:
                call SetParam0.setParam(param);
                break;
            case 1:
                call SetParam1.setParam(param);
                break;
            case 2:
                call SetParam2.setParam(param);
                break;
            case 3:
                call SetParam3.setParam(param);
                break;
            case 4:
                call SetParam4.setParam(param);
                break;
            case 5:
                call SetParam5.setParam(param);
                break;
            case 6:
                call SetParam6.setParam(param);
                break;
            case 7:
                call SetParam7.setParam(param);
                break;
            case 8:
                call SetParam8.setParam(param);
                break;
            case 9:
                call SetParam9.setParam(param);
                break;
            case 10:
                call SetParam10.setParam(param);
                break;
            case 11:
                call SetParam11.setParam(param);
                break;
            case 12:
                call SetParam12.setParam(param);
                break;
            case 13:
                call SetParam13.setParam(param);
                break;
             default:
            }
            return;
        }

    static inline void setparam_digital(int8_t i,uint8_t param)
        {
            switch(SampleRecord[i].channel){
            case 0:
                call Dio0.setparam(param);
                break;
            case 1:
                call Dio1.setparam(param);
                break;
            case 2:
                call Dio2.setparam(param);
                break;
            case 3:
                call Dio3.setparam(param);
                break;
            case 4:
                call Dio4.setparam(param);
                break;
            case 5:
                call Dio5.setparam(param);
                break;
            default:
            }
            return;
        }
    
    static inline void setparam_counter(int8_t i,uint8_t param)
        {
            call Counter.setparam(param);
            return;
        }
    

void sampleRecord(uint8_t i)
        {
            if(SampleRecord[i].channelType==ANALOG) { 
                switch (SampleRecord[i].channel){
                case 0:       
                    call ADC0.getData();
                    break;
                case 1:
                    call ADC1.getData();                 
                    break;
                case 2:
                    call ADC2.getData();                 
                    break;
                case 3:       
                    call ADC3.getData();                 
                    break;
                case 4:
                    call ADC4.getData();                 
                    break;
                case 5:
                    call ADC5.getData();                 
                    break;
                case 6:       
                    call ADC6.getData();                 
                    break;
                case 7:
                    call ADC7.getData();
                    break;
                case 8:
                    call ADC8.getData();                 
                    break;
                case 9:       
                    call ADC9.getData();                 
                    break;
                case 10:
                    call ADC10.getData();
                    break;
                case 11:
                    call ADC11.getData();
                    break;
                case 12:
                    call ADC12.getData();                 
                    break;
                case 13:
                    call ADC13.getData();                 
                    break;
                default:
                }
                return;
            }
            if(SampleRecord[i].channelType==BATTERY) { 
                call Battery.getData();
                return;
            }
            

            if(SampleRecord[i].channelType==TEMPERATURE || SampleRecord[i].channelType==HUMIDITY ) { 
                if(SampleRecord[i].channelType==TEMPERATURE) call Temp.getData();                
                if(SampleRecord[i].channelType==HUMIDITY) call Hum.getData();                
                return; 
            }
            
            if(SampleRecord[i].channelType==DIGITAL) { 
                switch (SampleRecord[i].channel){
                case 0:       
                    call Dio0.getData();                 
                    break;
                case 1:
                    call Dio1.getData();                 
                    break;
                case 2:
                    call Dio2.getData();                 
                    break;
                case 3:       
                    call Dio3.getData();                 
                    break;
                case 4:
                    call Dio4.getData();                 
                    break;
                case 5:
                    call Dio5.getData();                 
                    break;
                default:
                }
                return;
            }
            if(SampleRecord[i].channelType==COUNTER) { 
                call Counter.getData();
                return;
            }         
            return;
        }
    
 command result_t SamplerControl.init() {
     int i;
        call CounterControl.init();
        call DioControl.init();
        call IBADCcontrol.init();
        call BatteryControl.init();
        call TempHumControl.init();
        for(i=0;i<MAX_SAMPLERECORD;i++){ 
            SampleRecord[i].sampling_interval=SAMPLE_RECORD_FREE;
            SampleRecord[i].ticks_left=0xffff;
        }
        atomic {
        flag25=FLAG_NOT_SET;
        flag33=FLAG_NOT_SET;
        flag50=FLAG_NOT_SET;
        }
        return SUCCESS;
    }
    
    command result_t SamplerControl.start() {
        call CounterControl.start();
        call DioControl.start();
        call IBADCcontrol.start();
        call BatteryControl.start();
        call TempHumControl.start();
        call CounterControl.start();
        //post next_schedule();
        next_schedule();
        return SUCCESS;
    }

    command result_t SamplerControl.stop() {
        call CounterControl.stop();
        call DioControl.stop();
        call IBADCcontrol.stop();
        call BatteryControl.stop();
        call TempHumControl.stop();
        return SUCCESS;
    }

    
    command result_t PlugPlay()
        {
            return call Plugged();
        }
    

    event result_t SamplerTimer.fired() {
        uint8_t i;
        //sample anyone which is supposed to be sampled
        for(i=0;i<MAX_SAMPLERECORD;i++)
            {
                if( SampleRecord[i].sampling_interval != SAMPLE_RECORD_FREE )
                    {
                        if(SampleRecord[i].ticks_left == 0 ) 
                            {
                                SampleRecord[i].ticks_left = SampleRecord[i].sampling_interval; 
                                sampleRecord(i);
                            }
                    }
            }
        //now see when timer should be fired for new samples
        //post next_schedule();
        next_schedule();
        return SUCCESS;
    }
    


    command result_t Sample.set_digital_output(uint8_t channel,uint8_t state)
        {
            
        }
    
    command int8_t Sample.getSample(uint8_t channel,uint8_t channelType,uint16_t interval,uint8_t param)
        {
          int8_t i;
          i=get_avilable_SampleRecord();
          if(i==-1) return i;
          SampleRecord[i].channel=channel;              
          SampleRecord[i].channelType=channelType;         
          SampleRecord[i].ticks_left=0;                //used for keeping the monostable timer 
          SampleRecord[i].sampling_interval=interval;  //Sampling interval set by command above,SampleRecord in no use if set to zero
          //SampleRecord[i].param=param;
          if(SampleRecord[i].channelType == DIGITAL ) setparam_digital(i,param);
          if(SampleRecord[i].channelType == COUNTER ) setparam_counter(i,param);
          if(SampleRecord[i].channelType == ANALOG ) setparam_analog(i,param);
          return i;            
        }

    command result_t Sample.reTask(int8_t record,uint16_t interval)
        {
          if(record<0 || record>MAX_SAMPLERECORD) return FAIL;
          SampleRecord[record].sampling_interval=interval;
          return SUCCESS;
        }

    command result_t Sample.stop(int8_t record)
        {
          if(record<0 || record>MAX_SAMPLERECORD) return FAIL;
          SampleRecord[record].sampling_interval= SAMPLE_RECORD_FREE;
          return SUCCESS;
        }

    default event result_t Sample.dataReady(uint8_t channel,uint8_t channelType,uint16_t data)
        {
          return SUCCESS;
        }
    
    event result_t ADC0.dataReady(uint16_t data) {
      if(data != ADC_ERROR) signal Sample.dataReady(0,ANALOG,data); 
      return SUCCESS;
    }
    
    event result_t ADC1.dataReady(uint16_t data) {
      if(data != ADC_ERROR) signal Sample.dataReady(1,ANALOG,data); 
      return SUCCESS;
    }
    
    event result_t ADC2.dataReady(uint16_t data) {
      if(data != ADC_ERROR) signal Sample.dataReady(2,ANALOG,data); 
      return SUCCESS;
    }
    
    event result_t ADC3.dataReady(uint16_t data) {
      if(data != ADC_ERROR) signal Sample.dataReady(3,ANALOG,data); 
      return SUCCESS;
    }
    
    event result_t ADC4.dataReady(uint16_t data) {
      if(data != ADC_ERROR) signal Sample.dataReady(4,ANALOG,data); 
      return SUCCESS; 
    }
    
    event result_t ADC5.dataReady(uint16_t data) {
      if(data != ADC_ERROR) signal Sample.dataReady(5,ANALOG,data); 
      return SUCCESS;
    }
    
    event result_t ADC6.dataReady(uint16_t data) {
      if(data != ADC_ERROR) signal Sample.dataReady(6,ANALOG,data); 
      return SUCCESS;
    }
    
    event result_t ADC7.dataReady(uint16_t data) {
      if(data != ADC_ERROR) signal Sample.dataReady(7,ANALOG,data); 
      return SUCCESS;
    }
    
    event result_t ADC8.dataReady(uint16_t data) {
      if(data != ADC_ERROR) signal Sample.dataReady(8,ANALOG,data); 
      return SUCCESS;
    }

    event result_t ADC9.dataReady(uint16_t data) {
      if(data != ADC_ERROR) signal Sample.dataReady(9,ANALOG,data); 
      return SUCCESS;
    }
    
    event result_t ADC10.dataReady(uint16_t data) {
      if(data != ADC_ERROR) signal Sample.dataReady(10,ANALOG,data); 
      return SUCCESS;
    }

    event result_t ADC11.dataReady(uint16_t data) {
      if(data != ADC_ERROR) signal Sample.dataReady(11,ANALOG,data); 
      return SUCCESS;
    }
    
    event result_t ADC12.dataReady(uint16_t data) {
      if(data != ADC_ERROR) signal Sample.dataReady(12,ANALOG,data); 
      return SUCCESS;
    }
    
     event result_t ADC13.dataReady(uint16_t data) {
       if(data != ADC_ERROR) signal Sample.dataReady(13,ANALOG,data); 
       return SUCCESS;
    }
    
    
     event result_t Battery.dataReady(uint16_t data) {
       signal Sample.dataReady(0,BATTERY,data); 
       return SUCCESS;
  }
  
  
     event result_t Temp.dataReady(uint16_t data) {
       signal Sample.dataReady(0,TEMPERATURE,data); //data type problem      
       return SUCCESS;
  }
  
     event result_t Hum.dataReady(uint16_t data) {
       signal Sample.dataReady(0,HUMIDITY,data); 
       return SUCCESS;
  }
  
   event result_t Dio0.dataReady(uint16_t data) {
      signal Sample.dataReady(0,DIGITAL,data); 
      return SUCCESS;
  }
  
   event result_t Dio1.dataReady(uint16_t data) {
      signal Sample.dataReady(1,DIGITAL,data); 
      return SUCCESS;
  }

   event result_t Dio2.dataReady(uint16_t data) {
      signal Sample.dataReady(2,DIGITAL,data); 
      return SUCCESS;
  }
  
   event result_t Dio3.dataReady(uint16_t data) {
      signal Sample.dataReady(3,DIGITAL,data); 
      return SUCCESS;
  }

   event result_t Dio4.dataReady(uint16_t data) {
      signal Sample.dataReady(4,DIGITAL,data); 
      return SUCCESS;
  }

   event result_t Dio5.dataReady(uint16_t data) {
      signal Sample.dataReady(5,DIGITAL,data); 
      return SUCCESS;
  }

  event result_t Dio0.dataOverflow() {
      return SUCCESS;
  }

  event result_t Dio1.dataOverflow() {
      return SUCCESS;
  }

  event result_t Dio2.dataOverflow() {
      return SUCCESS;
  }

  event result_t Dio3.dataOverflow() {
      return SUCCESS;
  }

  event result_t Dio4.dataOverflow() {
      return SUCCESS;
  }

  event result_t Dio5.dataOverflow() {
      return SUCCESS;
  }

  event result_t Counter.dataReady(uint16_t data) {
      signal Sample.dataReady(0,COUNTER,data);         
      return SUCCESS;
  }

  event result_t Counter.dataOverflow() {
      return SUCCESS;
  }

}
