/**
 * Module for GlowLight
 *
 * Copyright (C) 2005 Shockfish SA
 *
 * Authors:             Maxime Muller
 **/

/** 
 * Dim the led according to light sensor and msg from
 * other TinyNodes.
 * Every msg sent or receive is fwd to the UART 
 * throught OscopeUART lib
 **/

module GlowLightM
{
    provides interface StdControl;
    uses {
	interface Timer;
	interface Timer as Blink;
	interface ADC as LightADC;
	interface LedsIntensity as LedsI;
	interface Oscope as OLight;
	interface Random;
	interface SendMsg;
	interface ReceiveMsg;
	interface Oscope as Node0;
	interface Oscope as Node1;
	interface Oscope as Node2;
    }
}
implementation
{
    enum {
	LED_HIGH = 254,      // maximum led value
	TIMER_FREQ = 300,    // sampling Freq
#ifdef RND_TIMER
	RND_INT = 20,
#endif
	DELTA = 150,         // difference between MAX/MIN_LIGHT at init
	MIN_TRESH = 10,      // avoid 0 value as it tends to spike
	BLINK_TIME = 5      // set the red LED on for 5ms
    };
    
    typedef struct {
	uint16_t nodeId;
	uint16_t ledIntensity;
	uint8_t cnter;
    } GlowMsg_t;

    norace TOS_Msg m_msg;

    norace bool isSending = FALSE;
    norace bool init = TRUE;      // to set first value of MAX/MIN_LIGHT

    uint16_t counter = 0;
    norace static int MAX_LIGHT, MIN_LIGHT, CNTER_MOD = 10;
    norace uint16_t lightValue;
    void blink();

    command result_t StdControl.init() {
	MAX_LIGHT = 0;
	MIN_LIGHT = 0;

	return SUCCESS;
    }
    
    command result_t StdControl.start() {

	return call Timer.start(TIMER_ONE_SHOT, TIMER_FREQ);
    }
    
    command result_t StdControl.stop() {

	return rcombine(call Timer.stop(), call Blink.stop());
    }

    task void NoticeError() {
	TOSH_SET_RED_LED_PIN();
	call Blink.start(TIMER_ONE_SHOT, 2000);
    }

    /* 
    ** bcast our value to other TinyNodes 
    */
    task void bcast() {
	uint16_t oldVal = lightValue;
	float  tmpVal = lightValue;
	tmpVal =  (tmpVal-MIN_LIGHT)/(MAX_LIGHT-MIN_LIGHT);
	lightValue =tmpVal* LED_HIGH;
	lightValue = lightValue%LED_HIGH+1;
 	if (lightValue < MIN_TRESH)  
 	    lightValue = oldVal; 
	if (!isSending) {
	    GlowMsg_t* body = (GlowMsg_t*)m_msg.data;
	    isSending = TRUE;
	    counter++;
	    counter %=CNTER_MOD;
	    body->nodeId = TOS_LOCAL_ADDRESS;
	    body->ledIntensity = lightValue;
	    body->cnter = counter;
	    call LedsI.set(TOS_LOCAL_ADDRESS,lightValue);
	    if ( call SendMsg.send(TOS_BCAST_ADDR,
				   sizeof(GlowMsg_t), 
				   &m_msg) == FAIL)
	      
		isSending = FALSE;
	    if (counter==0 && isSending)
		blink();
	}
    }
    
    async event result_t LightADC.dataReady(uint16_t data) {

	lightValue=data;
	if (init) {
	    MAX_LIGHT = data+DELTA;
	    MIN_LIGHT = data-DELTA;
	    if (MIN_LIGHT < MIN_TRESH ) MIN_LIGHT = MIN_TRESH;
	    init = FALSE;
	}
	else {
	    if (data > MAX_LIGHT)
		MAX_LIGHT = data;
	    if (MIN_TRESH < data && data < MIN_LIGHT) 
		MIN_LIGHT = data;
	    if (lightValue != MAX_LIGHT && lightValue != MIN_LIGHT) {
		if(!post bcast())
		    post NoticeError();
	    }
	}
	return SUCCESS;
    }

    
    event result_t SendMsg.sendDone( TOS_MsgPtr msg, result_t success )
    {
	if (isSending)
	    isSending = FALSE;
	if(!success) {
	    TOSH_SET_RED_LED_PIN();
	    call Blink.start(TIMER_ONE_SHOT, 2000);
	}
	switch (TOS_LOCAL_ADDRESS) {
	case 0:
	    call Node0.put(lightValue); break;
	case 1:
	    call Node1.put(lightValue); break;
	case 2:
	    call Node2.put(lightValue); break;
	default: break;
	}
	return success;
    }

    /*
    ** set our own led to the received value 
    ** and fwd it to proper oscope channel
    */
    event TOS_MsgPtr ReceiveMsg.receive( TOS_MsgPtr msg )
    {   
	GlowMsg_t* body = (GlowMsg_t*)msg->data;
	if (body->nodeId != TOS_LOCAL_ADDRESS ) {
	    call LedsI.set(body->nodeId, body->ledIntensity);
	    if (body->cnter%CNTER_MOD==0)
		blink();	     		
	    switch (body->nodeId) {
	    case 0:
		call Node0.put(body->ledIntensity); break;
	    case 1:
		call Node1.put(body->ledIntensity); break;
	    case 2:
		call Node2.put(body->ledIntensity); break;
	    default: break;
	    }
	}
	return msg;
    }

    event result_t Timer.fired()
    {
#ifdef RND_TIMER
	uint16_t rndTimer;
	rndTimer = ((call Random.rand() & 0xfff) + 1)%RND_INT;
	call LightADC.getData();
	call Timer.start(TIMER_ONE_SHOT, TIMER_FREQ-RND_INT/2+rndTimer);
#else
	call LightADC.getData();
	call Timer.start(TIMER_ONE_SHOT, TIMER_FREQ);
#endif
	return SUCCESS;
    }

    event result_t Blink.fired() {
	TOSH_CLR_RED_LED_PIN();
	return SUCCESS;
    }
    void blink() {
	TOSH_SET_RED_LED_PIN();
	TOSH_uwait(2000);
	TOSH_CLR_RED_LED_PIN();
    }
	
}
