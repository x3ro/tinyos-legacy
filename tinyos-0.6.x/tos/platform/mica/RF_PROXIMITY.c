
#include "tos.h"
#include "RF_PROXIMITY.h"


static inline void reset_pot() {
    unsigned char i;
    for (i=0; i < 200; i++) {
        decrease_r();
    }
    for (i=0; i < 33; i++) {
        increase_r();
    }
    SET_UD_PIN();
    SET_INC_PIN();
}

#define TOS_FRAME_TYPE RF_PROXIMITY_frame
TOS_FRAME_BEGIN(CHIRP_frame) {
int COUNT_STATE;
int MAX_VAL;
int MAX_MASK;
int BATT_STATE;
int cutoff_check[8];
int HIGH_VAL;
}
TOS_FRAME_END(RF_PROXIMITY_frame);


void TOS_COMMAND(RF_PROXIMITY_START)(){
 int i;
 cli();
 outp(0, TIMSK);
 sbi(ASSR, AS2); 
 outp(0x1, TCCR2);
 outp(0, TCNT2);
 sbi(TIMSK, TOIE2);
 sei();
 SET_PIN_DIRECTIONS();
 reset_pot();
 for(i = 0; i < 8; i ++) VAR(cutoff_check)[i] = 0xfff;
 VAR(COUNT_STATE) = 0;
 while(1){
	sbi(MCUCR, SM1);
	sbi(MCUCR, SM0);
	sbi(MCUCR, SE);
	asm volatile ("sleep" ::);
	asm volatile ("nop" ::);
	asm volatile ("nop" ::);
  }
}
	
static int read_ADC(char port){
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


TOS_INTERRUPT_HANDLER(SIG_OVERFLOW2, (void)) {
  VAR(COUNT_STATE) ++;
  if((VAR(COUNT_STATE) & VAR(MAX_MASK)) == 0){
	CLR_RED_LED_PIN();
  }
  if((VAR(COUNT_STATE) & 0x7f) == 0){
	int i;
	SET_RFM_CTL0_PIN();
	CLR_RFM_CTL1_PIN();
	SET_RFM_TXD_PIN();
	read_ADC(30);
	VAR(BATT_STATE) = read_ADC(30);
	
	VAR(BATT_STATE) = read_ADC(30);
	VAR(cutoff_check)[0] = 0x3ff - VAR(BATT_STATE);
	VAR(BATT_STATE) >>= 4;
	for(i = 1; i < 8; i ++){
		VAR(cutoff_check)[i] = VAR(cutoff_check)[i-1] - VAR(BATT_STATE);
	}
	if(VAR(MAX_VAL) > VAR(cutoff_check)[1]){
		VAR(MAX_MASK) = 0x30;
	}else if(VAR(MAX_VAL) > VAR(cutoff_check)[2]){
		VAR(MAX_MASK) = 0x70;
	}else if(VAR(MAX_VAL) > VAR(cutoff_check)[3]){
		VAR(MAX_MASK) = 0xf0;
	}else{ 
		VAR(MAX_MASK) = 0x1f0;
	}
	if(VAR(HIGH_VAL) > 0x70){
		TOS_CALL_COMMAND(RF_PROXIMITY_SLEEP)(0x1);
	}
  	VAR(MAX_VAL) = 0;	
	VAR(HIGH_VAL) = 0;
  }else{
	int val;
  	CLR_RFM_TXD_PIN();
	SET_RFM_CTL1_PIN();
	SET_RFM_CTL0_PIN();
	read_ADC(0x7);
	val = read_ADC(0x7);
	if(val > VAR(MAX_VAL)){
		VAR(MAX_VAL) = val;
 	}
	if(val > VAR(cutoff_check)[4]){
	   VAR(HIGH_VAL) ++;
	}
	CLR_RFM_CTL1_PIN();
	CLR_RFM_CTL0_PIN();
  }
  if(VAR(COUNT_STATE) & 0x1){
	  SET_RED_LED_PIN();
  }
}


