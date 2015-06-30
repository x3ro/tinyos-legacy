
#include "tos.h"
#include "RF_WAKE_UP.h"
#include "eeprom.h"

#define DOT

#ifdef DOT
#define BBOUT_PIN_PORT 0x7
#else
#define BBOUT_PIN_PORT 0x0
#endif

void null(){;}

void wake_up_delay(int val){
	int i;
	for(i = 0; i < val; i ++){null();}
}

void wake_up_long_delay(unsigned char val){
	cbi(TIMSK, TOIE2);
	cbi(TIMSK, OCIE2);  
	sbi(ASSR, AS2);    
	outp(0, TCNT2);
	outp(0x7, TCCR2);
	outp(0, TCNT2);
	while(inp(TCNT2) != 0){;}
	while(inp(TCNT2) < val){;}
	outp(0, TCNT2);
	outp(0, TCCR2);
	cbi(ASSR, AS2);    
}

int read_ADC(char port){
	int val;
	outp(port, ADMUX);
	outp(0, ADCSR);
	sbi(ADCSR, ADIF);
	sbi(ADCSR, ADEN);
	sbi(ADCSR, ADSC);
	while((inp(ADCSR) & 0x10) == 0){}
	val = __inw(ADCL);
	outp(0, ADCSR);
	return val;
}

#define MAGIC 165
char TOS_COMMAND(RF_WAKE_UP_INIT)(){
    char wakeup = 0; 
    char sample = 0;
    char long_sample = 0;
    int i, cutoff;
    int SAMPLE_COUNT=10;
    int ADC_SAMPLE_MAX_FAIL = 2;
    int ADC_SAMPLE_COUNT = 75+SAMPLE_COUNT;
    int ADC_SECONDARY_SAMPLE_MAX_FAIL = 15;
    int CUTOFF_TICKS = 4;
    char use_defaults;
    SET_RFM_CTL0_PIN();
    SET_RFM_CTL1_PIN();
    sample = 0;
    long_sample = 0;
    wake_up_delay(450); //delay 
    
    use_defaults = eeprom_rb(0);
    if (use_defaults == MAGIC) {
	CUTOFF_TICKS = (int) (eeprom_rb(1) & 0x1f);
	SAMPLE_COUNT = eeprom_rw(2);
	ADC_SAMPLE_MAX_FAIL = eeprom_rw(4);
	ADC_SAMPLE_COUNT = eeprom_rw(6);
	ADC_SECONDARY_SAMPLE_MAX_FAIL = eeprom_rw(8);
    }
#ifdef DOT
	i = read_ADC(30);//0x1e);
	i = read_ADC(30);//0x1e);
	
	//i = i + (i >> 3) + (i >> 4);
	i += ((CUTOFF_TICKS * (i & 0x1ff)) >> 5);
	cutoff = 0x3ff - i;
#else
	cutoff = 500;
#endif
	i = 0;
	while(i < SAMPLE_COUNT && sample < ADC_SAMPLE_MAX_FAIL){
		if(read_ADC(BBOUT_PIN_PORT) < cutoff) sample ++;
		i ++;
	}
	while(i < ADC_SAMPLE_COUNT && sample < ADC_SAMPLE_MAX_FAIL 
		&& long_sample < ADC_SECONDARY_SAMPLE_MAX_FAIL){
    		wake_up_delay(0x85); //delay 
		if(read_ADC(BBOUT_PIN_PORT) < cutoff) long_sample ++;
		i ++;
	}
	if((sample <  ADC_SAMPLE_MAX_FAIL) && (long_sample < ADC_SECONDARY_SAMPLE_MAX_FAIL)){
		wakeup = 1;
	}
    if(wakeup == 1){
	CLR_RFM_CTL1_PIN();
	SET_RFM_CTL0_PIN();
	SET_RFM_TXD_PIN();
	CLR_YELLOW_LED_PIN();
	for(sample = 0; sample < 10; sample++){
		decrease_r();
	}
	wake_up_long_delay(0xfe);
	CLR_RFM_TXD_PIN();
	CLR_RFM_CTL0_PIN();	
	SET_YELLOW_LED_PIN();
	for(sample = 0; sample < 10; sample++){
		increase_r();
	}
	set_bit_timer();
	set_bit_timer();
    	TOS_CALL_COMMAND(RF_WAKE_UP_SUB_INIT)();
    }else{
    	CLR_RFM_CTL0_PIN();
    	CLR_RFM_CTL1_PIN();
	TOS_CALL_COMMAND(RF_WAKE_UP_SLEEP)(period1024);
    }
    return 1;
}

