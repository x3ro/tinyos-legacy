//Mohammad Rahimi
includes IB;
module SamplerM
{
    provides interface StdControl as SamplerControl;
    provides interface Sample;

  uses {
      interface Leds;
      interface Timer as SamplerTimer;

      //analog channels
      interface StdControl as IBADCcontrol;
      interface Excite;
      interface ADC as ADC0;
      interface ADC as ADC1;
      interface ADC as ADC2;
      interface ADC as ADC3;
      interface ADC as ADC4;
      interface ADC as ADC5;
      interface ADC as ADC6;
      interface ADC as ADC7;
      interface ADC as ADC8;
      interface ADC as ADC9;
      interface ADC as ADC10;
      interface ADC as ADC11;
      interface ADC as ADC12;
      interface ADC as ADC13;


      //health channels temp,humidity,voltage
      interface StdControl as BatteryControl;
      interface ADC as Battery;
      interface StdControl as TempHumControl;
      interface ADC as Temp;
      interface ADC as Hum;

      //digital and relay channels
      interface StdControl as DioControl;
      interface Dio as Dio0;
      interface Dio as Dio1;
      interface Dio as Dio2;
      interface Dio as Dio3;
      interface Dio as Dio4;
      interface Dio as Dio5;
      interface Dio as Dio6;
      interface Dio as Dio7;

      //counter channels
      interface StdControl as CounterControl;
      interface Dio as Counter;
  }
}
implementation
{

#define SAMPLE_RECORD_FREE 0
#define SCHEDULER_RESPONSE_TIME 10

    //lock for the shared resources
    uint8_t ADC_lock,SH11_lock;

    //main data structure 10 byte per recorde
    struct SampleRecords{
        uint8_t channel;              
        uint8_t channelType;         
        uint8_t param;
        uint16_t ticks_left;         //used for keeping the monostable timer 
        uint16_t sampling_interval;  //Sampling interval set by command above, It is in second, SampleRecord in no use if set to zero.
        char pending;
    }SampleRecord[MAX_SAMPLERECORD];
    
    
    //check what is the SampleRecords that are avilable and return one that is available
    static inline int8_t get_avilable_SampleRecord()
        {
            int8_t i;
            for(i=0;i<MAX_SAMPLERECORD;i++) if( SampleRecord[i].sampling_interval == SAMPLE_RECORD_FREE ) return i;
            return -1; //not available SampleRecord
        }
    
    //find the next channel which should be serviced. 
    task void next_schedule(){
        uint8_t i;
        uint16_t min=SCHEDULER_RESPONSE_TIME;   //minimum time to ba called.we set it to 15Sec min so that if a new sampling request comes we reply with 15 sec delay.

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
        min=min * 1000;   //since timer gets input in milisecond and we get command in 0.1sec.
        call SamplerTimer.start(TIMER_ONE_SHOT , min);
    }
    
    static inline void setparam_analog(uint8_t i)
        {
            call Excite.setEx(ALL_EXCITATION);
            return;
        }

    static inline void setparam_digital(uint8_t i)
        {
            call Dio0.setCount(0xffff);
            call Dio1.setCount(0xffff);
            call Dio2.setCount(0xffff);
            call Dio3.setCount(0xffff);
            call Dio4.setCount(0xffff);
            call Dio5.setCount(0xffff);
            call Dio6.setCount(0xffff);
            call Dio7.setCount(0xffff);
            return;
        }

 static inline void setparam_counter()
     {
         call Counter.setparam(0,Edge);
         return;
     }

 //static inline 
void sampleRecord(uint8_t i)
     {
         if(SampleRecord[i].channelType==ANALOG) { 
             //we only sample if the lock is free
             cli();
             if (ADC_lock==LOCK) { 
                 SampleRecord[i].pending=PENDING;
                 return;
             }
             else {
                 ADC_lock=LOCK;
             }
             sei();

             switch (SampleRecord[i].channel){
             case 0:       
                 setparam_analog(0);
                 call ADC0.getData();                 
                 break;
             case 1:
                 setparam_analog(1);
                 call ADC1.getData();                 
                 break;
             case 2:
                 setparam_analog(2);
                 call ADC2.getData();                 
                 break;
             case 3:       
                 setparam_analog(3);
                 call ADC3.getData();                 
                 break;
             case 4:
                 setparam_analog(4);
                 call ADC4.getData();                 
                 break;
             case 5:
                 setparam_analog(5);
                 call ADC5.getData();                 
                 break;
             case 6:       
                 setparam_analog(6);
                 call ADC6.getData();                 
                 break;
             case 7:
                 setparam_analog(7);
                 call ADC7.getData();
                 break;
             case 8:
                 setparam_analog(8);
                 call ADC8.getData();                 
                 break;
             case 9:       
                 setparam_analog(9);
                 call ADC9.getData();                 
                 break;
             case 10:
                 setparam_analog(10);
                 call ADC10.getData();
                 break;
             case 11:
                 setparam_analog(11);
                 call ADC11.getData();
                 break;
             case 12:       
                 setparam_analog(12);
                 call ADC12.getData();                 
                 break;
             case 13:
                 setparam_analog(13);
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

         if(SampleRecord[i].channelType==TEMPERATURE) { 
            //we only sample if the lock is free
             cli();
             if (SH11_lock==LOCK) { 
                 SampleRecord[i].pending=PENDING;
                 return;
             }
             else {
                 SH11_lock=LOCK;
             }
             sei();
             call Temp.getData();
             return; 
         }

         if(SampleRecord[i].channelType==HUMIDITY) { 
            //we only sample if the lock is free
             cli();
             if (SH11_lock==LOCK) { 
                 SampleRecord[i].pending=PENDING;
                 return;
             }
             else {
                 SH11_lock=LOCK;
             }
             sei();
             call Hum.getData();
             return;
         }

         if(SampleRecord[i].channelType==DIGITAL) { 
             switch (SampleRecord[i].channel){
             case 0:       
                 setparam_digital(0);
                 call Dio0.getData();                 
                 break;
             case 1:
                 setparam_digital(1);
                 call Dio1.getData();                 
                 break;
             case 2:
                 setparam_digital(2);
                 call Dio2.getData();                 
                 break;
             case 3:       
                 setparam_digital(3);
                 call Dio3.getData();                 
                 break;
             case 4:
                 setparam_digital(4);
                 call Dio4.getData();                 
                 break;
             case 5:
                 setparam_digital(5);
                 call Dio5.getData();                 
                 break;
             case 6:       
                 setparam_digital(6);
                 call Dio6.getData();                 
                 break;
             case 7:
                 setparam_digital(7);
                 call Dio7.getData();                 
                 break;
             default:
             }
             return;
         }
         if(SampleRecord[i].channelType==COUNTER) { 
             setparam_counter();
             call Counter.getData();
             return;
         }         
         return;
     }

//static inline 
void run_pending_adc_samples()
     {
         int i;
         for(i=0;i<MAX_SAMPLERECORD;i++) //find out any one who should be serviced before next 15 second.
             {
                 if((SampleRecord[i].sampling_interval != SAMPLE_RECORD_FREE ) && SampleRecord[i].pending == PENDING && SampleRecord[i].channelType==ANALOG )
                     {                      
                             SampleRecord[i].pending = NOT_PENDING;
                             sampleRecord(i);
                             return;
                     }                 
             } 
     }

void run_pending_sh11_samples()
     {
         int i;
         for(i=0;i<MAX_SAMPLERECORD;i++) //find out any one who should be serviced before next 15 second.
             {
                 if((SampleRecord[i].sampling_interval != SAMPLE_RECORD_FREE ) && (SampleRecord[i].pending == PENDING) && (SampleRecord[i].channelType==TEMPERATURE || SampleRecord[i].channelType==HUMIDITY ))
                     {                      
                         SampleRecord[i].pending = NOT_PENDING;
                         sampleRecord(i);
                         return;
                     }                 
             } 
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
            SampleRecord[i].pending=NOT_PENDING;
        }
        ADC_lock=UNLOCK;
        SH11_lock=UNLOCK;
        return SUCCESS;
    }
    
    command result_t SamplerControl.start() {
        call CounterControl.start();
        call DioControl.start();
        call IBADCcontrol.start();
        call BatteryControl.start();
        call TempHumControl.start();
        //setting the default parameters for all channels.
        //this should be changed.
        call Excite.setPowerMode(NO_POWER_SAVING_MODE);
        call Excite.setCoversionSpeed(SLOW_COVERSION_MODE);
        call Excite.setAvergeMode(NO_AVERAGE);
        call Excite.setEx(ALL_EXCITATION);
        call Counter.setparam(InputChannel,RisingEdge);
        call CounterControl.start();
        post next_schedule();
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
        post next_schedule();
        return SUCCESS;
    }
    
    command result_t Sample.sample(uint8_t channel,uint8_t channelType,uint8_t interval)
        {
            int8_t i;
            i=get_avilable_SampleRecord();
            if(i==-1) return FAIL;
            SampleRecord[i].channel=channel;              
            SampleRecord[i].channelType=channelType;         
            SampleRecord[i].ticks_left=0;                //used for keeping the monostable timer 
            SampleRecord[i].sampling_interval=interval;  //Sampling interval set by command above,SampleRecord in no use if set to zero
            SampleRecord[i].pending=NOT_PENDING;                //non of them are pending
            return SUCCESS;
        }
    
    default event result_t Sample.dataReady(uint8_t channel,uint8_t channelType,uint16_t data)
        {
            return SUCCESS;
        }
    
    event result_t ADC0.dataReady(uint16_t data) {
          ADC_lock=UNLOCK;
          run_pending_adc_samples();
          signal Sample.dataReady(0,ANALOG,data); 
        return SUCCESS;
    }
    
    event result_t ADC1.dataReady(uint16_t data) {
        ADC_lock=UNLOCK;
        run_pending_adc_samples();
        signal Sample.dataReady(1,ANALOG,data); 
        return SUCCESS;
    }
    
    event result_t ADC2.dataReady(uint16_t data) {
        ADC_lock=UNLOCK;
        run_pending_adc_samples();
        signal Sample.dataReady(2,ANALOG,data); 
        return SUCCESS;
    }
    
    event result_t ADC3.dataReady(uint16_t data) {
        ADC_lock=UNLOCK;
        run_pending_adc_samples();
        signal Sample.dataReady(3,ANALOG,data); 
        return SUCCESS;
    }
    
    event result_t ADC4.dataReady(uint16_t data) {
        ADC_lock=UNLOCK;
        run_pending_adc_samples();
        signal Sample.dataReady(4,ANALOG,data); 
        return SUCCESS;
  }

  event result_t ADC5.dataReady(uint16_t data) {
      ADC_lock=UNLOCK;
      run_pending_adc_samples();
      signal Sample.dataReady(5,ANALOG,data); 
      return SUCCESS;
  }

  event result_t ADC6.dataReady(uint16_t data) {
      ADC_lock=UNLOCK;
      run_pending_adc_samples();
      signal Sample.dataReady(6,ANALOG,data); 
      return SUCCESS;
  }

  event result_t ADC7.dataReady(uint16_t data) {
      ADC_lock=UNLOCK;
      run_pending_adc_samples();
      signal Sample.dataReady(7,ANALOG,data); 
      return SUCCESS;
  }

  event result_t ADC8.dataReady(uint16_t data) {
      ADC_lock=UNLOCK;
      run_pending_adc_samples();
      signal Sample.dataReady(8,ANALOG,data); 
      return SUCCESS;
  }

  event result_t ADC9.dataReady(uint16_t data) {
      ADC_lock=UNLOCK;
      run_pending_adc_samples();
      signal Sample.dataReady(9,ANALOG,data); 
      return SUCCESS;
  }

  event result_t ADC10.dataReady(uint16_t data) {
      ADC_lock=UNLOCK;
      run_pending_adc_samples();
      signal Sample.dataReady(10,ANALOG,data); 
      return SUCCESS;
  }

  event result_t ADC11.dataReady(uint16_t data) {
      ADC_lock=UNLOCK;
      run_pending_adc_samples();
      signal Sample.dataReady(11,ANALOG,data); 
      return SUCCESS;
  }

  event result_t ADC12.dataReady(uint16_t data) {
      ADC_lock=UNLOCK;
      run_pending_adc_samples();
      signal Sample.dataReady(12,ANALOG,data); 
      return SUCCESS;
  }
  event result_t ADC13.dataReady(uint16_t data) {
      ADC_lock=UNLOCK;
      run_pending_adc_samples();
      signal Sample.dataReady(13,ANALOG,data); 
      return SUCCESS;
  }
  
  
  event result_t Battery.dataReady(uint16_t data) {
      signal Sample.dataReady(0,BATTERY,data); 
      return SUCCESS;
  }
  

  event result_t Temp.dataReady(uint16_t data) {
      SH11_lock=UNLOCK;
      //run_pending_sh11_samples();
      signal Sample.dataReady(0,TEMPERATURE,data); //data type problem
      return SUCCESS;
  }

  event result_t Hum.dataReady(uint16_t data) {
      SH11_lock=UNLOCK;
      //run_pending_sh11_samples();
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

  event result_t Dio6.dataReady(uint16_t data) {
      signal Sample.dataReady(6,DIGITAL,data); 
      return SUCCESS;
  }

  event result_t Dio7.dataReady(uint16_t data) {
      signal Sample.dataReady(7,DIGITAL,data); 
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

  event result_t Dio6.dataOverflow() {
      return SUCCESS;
  }

  event result_t Dio7.dataOverflow() {
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
