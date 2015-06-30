/*
 * Copyright (c) 2007, RWTH Aachen University
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL RWTH AACHEN UNIVERSITY BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF RWTH AACHEN
 * UNIVERSITY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * RWTH AACHEN UNIVERSITY SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND RWTH AACHEN UNIVERSITY HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.
 *
 */
 
 
/**
 *
 * Implementation of SersorMeterC.nc
<p>
 * @author Krisakorn Rerkrai <kre@mobnets.rwth-aachen.de>
 **/

includes UQLCmdMsg;
includes UllaQuery;

#ifndef TELOS_PLATFORM
#define TELOS_PLATFORM
#endif

module SensorMeterM {

  provides 	{
    interface StdControl;
    //interface RequestUpdate;
    interface LinkProviderIf[uint8_t id];
    interface GetInfoIf as GetSensorInfo;
  }
  uses {
    interface Timer;
    interface Leds;

  	interface ProcessCmd as AttributeEvent;
    interface ProcessCmd as LinkEvent;
    interface ProcessCmd as CompleteCmdEvent;

    ////interface Send[uint8_t id];
    //interface Condition;

#ifdef HISTORICAL_STORAGE
    interface WriteToStorage;
#endif
#ifdef TELOS_PLATFORM
    /* Sensors */
    interface SplitControl as HumidityControl;

    interface ADC as Humidity;
    interface ADC as Temperature;
    interface ADC as TSR;
    interface ADC as PAR;
    interface ADC as InternalTemperature;
    interface ADC as InternalVoltage;

    interface ADCError as HumidityError;
    interface ADCError as TemperatureError;
#endif
#ifdef OSCOPE
    interface Oscope as OHumidity;
    interface Oscope as OTemperature;
    interface Oscope as OTSR;
    interface Oscope as OPAR;
    interface Oscope as OInternalTemperature;
    interface Oscope as OInternalVoltage;
#endif
  }

}

/*
 *  Module Implementation
 */

implementation
{
  enum {
    OSCOPE_DELAY = 10,
  };

  norace uint16_t humidity, temperature, tsr, par, itemp, ivolt;
  norace uint8_t state;
  norace uint16_t numSamples;
  norace uint16_t timeInterval;
  norace uint8_t actionIndex;
  norace uint16_t sdata;

  // module scoped variables
  TOS_MsgPtr msg;
  TOS_Msg buf;
  int8_t pending;
  QueryPtr query;
  ResultTuple rt;
  ResultTuplePtr rtp;
  
  uint8_t query_type;
  uint8_t currentLU;

  /* task declaration */
  task void getHumidity();
  task void getTemperature();
  task void getTSR();
  task void getPAR();
  task void getInternalTemperature();
  task void getInternalVoltage();

  /* function declaration */
  //result_t addToResultTuple(ResultTuplePtr result);
  task void SimDataReady();
  task void CheckQueryType();

  ////void CheckCounter();

  command result_t StdControl.init() {

  atomic {
    //state = HUMIDITY;
    rtp = &rt;
    msg = &buf;
    actionIndex = 0;
  }
    //call Leds.init();
    //call Leds.set(0);
#ifdef TELOS_PLATFORM
    call HumidityControl.init();
#endif

    return (SUCCESS);
  }
#ifdef TELOS_PLATFORM
  event result_t HumidityControl.initDone() {
    return SUCCESS;
  }
#endif
/* start the sensorcontrol component */
  command result_t StdControl.start() {
#ifdef TELOS_PLATFORM
    call HumidityControl.start();
#endif
    return SUCCESS;
  }
#ifdef TELOS_PLATFORM
  event result_t HumidityControl.startDone() {
    call HumidityError.enable();
    call TemperatureError.enable();
    //call Timer.start( TIMER_ONE_SHOT, 250 );
    return SUCCESS;
  }
#endif
/* stop the sensorcontrol component */
  command result_t StdControl.stop() {
#ifdef TELOS_PLATFORM
    call HumidityControl.stop();
#endif
    call Timer.stop();
    return SUCCESS;
  }
#ifdef TELOS_PLATFORM
  event result_t HumidityControl.stopDone() {
    call HumidityError.disable();
    call TemperatureError.disable();
    return SUCCESS;
  }
#endif

#if 0
  // fill in the result tuple when dataReady, and signal receiveTuple
  command result_t RequestUpdate.execute(QueryPtr pq) {

    dbg(DBG_USR1, "Request update starts\n");
    atomic {
      query = pq;
      actionIndex = 0;
      state = pq->fields[actionIndex];
      numSamples = pq->nsamples;
      timeInterval = pq->interval;
      //rtp->qid = pq->qid;
      rtp->numFields = pq->numFields;
      rtp->numConds = pq->numConds;

    }

    call Timer.start( TIMER_ONE_SHOT, OSCOPE_DELAY );

    return SUCCESS;
  }
#endif

  event result_t Timer.fired() {
    //call Leds.yellowToggle();

    dbg(DBG_USR1, "Timer fired\n");
    // set a timeout in case a task post fails (rare)
    //call Timer.start(TIMER_ONE_SHOT, 100);
    switch(state) {
    case HUMIDITY:
      post getHumidity();
      break;

    case TEMPERATURE:
      post getTemperature();
      break;

    case TSRSENSOR:
      post getTSR();
      break;

    case PARSENSOR:
      post getPAR();
      break;

    case INT_TEMP:
      post getInternalTemperature();
      break;

    case INT_VOLT:
      post getInternalVoltage();
      break;

    //default:
    //  call Timer.start(TIMER_ONE_SHOT, 10);
    } // switch case

    return SUCCESS;
  }
/*
  default event ResultTuplePtr RequestUpdate.receiveTuple(ResultTuplePtr rtr) {
    return rtr;
  }
*/
  event result_t AttributeEvent.done(TOS_MsgPtr pmsg, result_t status) {
    return SUCCESS;
  }

  event result_t LinkEvent.done(TOS_MsgPtr pmsg, result_t status) {
  	return SUCCESS;
  }

  event result_t CompleteCmdEvent.done(TOS_MsgPtr pmsg, result_t status) {
  	return SUCCESS;
  }

  void ProcessAttribute(uint8_t attr) {
    switch(attr) {
		case LP_ID:
				state = LP_ID;
				post CheckQueryType();
			break;
      case HUMIDITY:
        post getHumidity();
				call Leds.greenToggle();
      break;

      case TEMPERATURE:
			  //call Leds.yellowToggle();  
		
        post getTemperature();
      break;

      case TSRSENSOR:
        post getTSR();
      break;

      case PARSENSOR:
        post getPAR();
      break;

      case INT_TEMP:
        post getInternalTemperature();
      break;

      case INT_VOLT:
        post getInternalVoltage();
      break;
    }
  }
  
/*------------------------------ Link Provider --------------------------------*/

  command uint8_t LinkProviderIf.execCmd[uint8_t id](CmdDescr_t* cmdDescr) {

  }

  command uint8_t LinkProviderIf.requestUpdate[uint8_t id](RuId_t ruId, RuDescr_t* ruDescr, AttrDescr_t* attrDescr) {
	
		 switch (id) {
      // probe or read from the firmware
      case REMOTE_QUERY:
			// no use here
			dbg(DBG_USR1, "SensorMeter: LP.requestUpdate REMOTE_QUERY\n");
      break;
      // local reading
      // This case we should signal LinkProviderIf.getAttributeDone back to UQP
      case LOCAL_QUERY:
			
			dbg(DBG_USR1, "SensorMeter: LP.requestUpdate LOCAL_QUERY\n");
			break;
			
			default:
			
			dbg(DBG_USR1, "SensorMeter: LP.requestUpdate UNDEFINED TYPE\n");
			break;
		}
    return 1;
  }

  command uint8_t LinkProviderIf.cancelUpdate[uint8_t id](RuId_t ruId) {

  }

  command uint8_t LinkProviderIf.getAttribute[uint8_t id](AttrDescr_t* attDescr) {
    TOS_MsgPtr p;
    struct GetInfoMsg *getInfo = (struct GetInfoMsg *)buf.data;
    dbg(DBG_USR1, "SensorMeterM: getAttribute\n");
/*
    atomic {
      query_type = id;
      currentLU = LOCAL_LU;
    }
  */
    call Leds.greenToggle();  
		dbg(DBG_USR1, "SensorMeter.getAttribute\n");
    ProcessAttribute(attDescr->attribute);
   return 1;
  }

  command uint8_t LinkProviderIf.setAttribute[uint8_t id](AttrDescr_t* attDescr) {
    return 1;
  }

  command void LinkProviderIf.freeAttribute[uint8_t id](AttrDescr_t* attDescr) {

  }
  
/*-------------------------------- Transceiver --------------------------------*/

  command uint8_t GetSensorInfo.getAttribute(TOS_Msg *tmsg) {
    struct GetInfoMsg *getinfo = (struct GetInfoMsg *)tmsg->data;
    atomic {
      currentLU = REMOTE_LU;
      query_type = REMOTE_QUERY;
    }
    ProcessAttribute(getinfo->attribute);
    return 1;
  }
  /*
  event result_t Send.sendDone[uint8_t id](TOS_MsgPtr pmsg, result_t success) {
    AttrDescr_t* attDescr;
    dbg(DBG_USR1, "SensorMeterM: SendGetInfoMsg.sendDone\n");
    //signal LinkProviderIf.getAttributeDone[REMOTE_QUERY](attDescr);
    return success;
  }*/

/*------------------------------- Put data ------------------------------------*/

  task void putHumidity() {
#ifdef OSCOPE
    call OHumidity.put(humidity);
#endif
    // fill in tuple here
    rtp->fields[actionIndex] = HUMIDITY;
    rtp->data[actionIndex] = humidity;
    //call Leds.yellowToggle();
    ////CheckCounter();
  }

  task void putTemperature() {
#ifdef OSCOPE
    call OTemperature.put(temperature);
#endif
    rtp->fields[actionIndex] = TEMPERATURE;
    rtp->data[actionIndex] = temperature;
    //call Leds.greenToggle();
    ////CheckCounter();
  }

  task void putTSR() {
#ifdef OSCOPE
    call OTSR.put(tsr);
    //call Leds.greenToggle();
#endif
    rtp->fields[actionIndex] = TSRSENSOR;
    rtp->data[actionIndex] = tsr;
    ////CheckCounter();
  }

  task void putPAR() {
#ifdef OSCOPE
    call OPAR.put(par);
#endif
    rtp->fields[actionIndex] = PARSENSOR;
    ///rtp->dummy = 0xFF;
    rtp->data[actionIndex] = par;
    ///CheckCounter();
  }

  task void putIntTemp() {
#ifdef OSCOPE
    call OInternalTemperature.put(itemp);
#endif
    rtp->fields[actionIndex] = INT_TEMP;
    rtp->data[actionIndex] = itemp;
    ///CheckCounter();
  }

  task void putIntVoltage() {
#ifdef OSCOPE
    call OInternalVoltage.put(ivolt);
#endif
    rtp->fields[actionIndex] = INT_VOLT;
    rtp->data[actionIndex] = ivolt;
    ///CheckCounter();
  }

  task void getHumidity() {
    state = HUMIDITY;
#ifdef TELOS_PLATFORM
    call Humidity.getData();
#else
    post SimDataReady();
#endif
  }

  task void getTemperature() {
    state = TEMPERATURE;
		//call Leds.yellowToggle();
#ifdef TELOS_PLATFORM
    call Temperature.getData();
#else
    post SimDataReady();
#endif
  }

  task void getTSR() {
  state = TSRSENSOR;
#ifdef TELOS_PLATFORM
    call TSR.getData();
#else
    post SimDataReady();
#endif
  }

  task void getPAR() {
    state = PARSENSOR;
#ifdef TELOS_PLATFORM
    call PAR.getData();
#else
    post SimDataReady();
#endif
  }

  task void getInternalTemperature() {
    state = INT_TEMP;
#ifdef TELOS_PLATFORM
    call InternalTemperature.getData();
#else
    post SimDataReady();
#endif
  }

  task void getInternalVoltage() {
    state = INT_VOLT;
#ifdef TELOS_PLATFORM
    call InternalVoltage.getData();
#else
    post SimDataReady();
#endif
  }

//#ifdef TELOS_PLATFORM

  task void CheckQueryType() {

    struct GetInfoMsg *getinfo = (struct GetInfoMsg *) msg->data;
    struct AttrDescr_t attDescr;
		elseHorizontalTuple tuple;
    
    uint16_t data;
		//call Leds.redToggle();
    switch(state) {
		case LP_ID:
				sdata = TOS_LOCAL_ADDRESS;
			break;
      case HUMIDITY:
        sdata = humidity;
      break;

      case TEMPERATURE:
        sdata = temperature;
      break;

      case TSRSENSOR:
        //call Leds.redToggle();
        sdata = tsr;
      break;

      case PARSENSOR:
        ///call Leds.yellowToggle();
        sdata = par;
      break;

      case INT_TEMP:
        call Leds.greenToggle();
        sdata = itemp;
      break;

      case INT_VOLT:
        sdata = ivolt;
      break;
    }
    dbg(DBG_USR1, "SenserMeterM: CheckQueryType sdata=%d\n",sdata);
    data = sdata;
		attDescr.attribute = state;
		attDescr.className = sensorMeter;
		
		tuple.attr = state;
		tuple.u.value16 = sdata;
		signal LinkProviderIf.getAttributeDone[LOCAL_QUERY](&attDescr, (uint8_t *) &tuple);
    #if 0
		switch (currentLU) {
      case LOCAL_LU:
      //call Leds.yellowToggle();
        switch (query_type) {
          case LOCAL_QUERY:
            //call Leds.yellowToggle();
            signal LinkProviderIf.getAttributeDone[LOCAL_QUERY](&attDescr, &data);
          break;
          case REMOTE_QUERY:
						//////call Send.send[AM_GETINFO_MESSAGE](msg, sizeof(struct GetInfoMsg));
						signal LinkProviderIf.getAttributeDone[REMOTE_QUERY](&attDescr, &data);
          break;
        }
      break;
      case REMOTE_LU:
      //call Leds.greenToggle();
        switch (query_type) {
          case LOCAL_QUERY:
            signal LinkProviderIf.getAttributeDone[LOCAL_QUERY](&attDescr, &data);
          break;
          case REMOTE_QUERY:
            // FIXME 04.08.06: check if this is correct (changed GetSensorInfo to LinkProvider[LOCAL_QUERY].
            ///signal GetSensorInfo.getAttributeDone(msg);
						signal LinkProviderIf.getAttributeDone[REMOTE_QUERY](&attDescr, &data);
          break;
        }
      break;
      default:
        //call Leds.greenToggle();
      break;
    }
		#endif
  }
#ifdef TELOS_PLATFORM
  async event result_t Humidity.dataReady(uint16_t data) {
    //struct QueryMsg *query = (struct QueryMsg *) msg->data;
    humidity = data;
    //post putHumidity();
    state = HUMIDITY;
    post CheckQueryType();
    return SUCCESS;
  }

  event result_t HumidityError.error(uint8_t token) {
    //struct QueryMsg *query = (struct QueryMsg *) msg->data;
    humidity = 0;
    //post putHumidity();
    state = HUMIDITY;
    post CheckQueryType();
    return SUCCESS;
  }

  async event result_t Temperature.dataReady(uint16_t data) {
    //struct QueryMsg *query = (struct QueryMsg *) msg->data;
    temperature = data;
    //post putTemperature();
    state = TEMPERATURE;
    post CheckQueryType();
    //state = TSRSENSOR;
    return SUCCESS;
  }

  event result_t TemperatureError.error(uint8_t token) {
    //struct QueryMsg *query = (struct QueryMsg *) msg->data;
    temperature = 0;
    //post putTemperature();
    state = TEMPERATURE;
    post CheckQueryType();
    return SUCCESS;
  }

  async event result_t TSR.dataReady(uint16_t data) {
    //struct QueryMsg *query = (struct QueryMsg *) msg->data;
    struct GetInfoMsg *getinfo = (struct GetInfoMsg *) msg->data;
    tsr = data;
    state = TSRSENSOR;
    post CheckQueryType();
    //post putTSR();
    getinfo->data = tsr;
    return SUCCESS;
  }

  async event result_t PAR.dataReady(uint16_t data) {
    //struct QueryMsg *query = (struct QueryMsg *) msg->data;
    struct GetInfoMsg *getinfo = (struct GetInfoMsg *) msg->data;
    par = data;
    //post putPAR();
  /*
    uint8_t type; // send or receive
  uint8_t attribute;
  uint8_t numFields;
  uint8_t fieldIdx;
  uint8_t linkid;
  uint16_t seq;
  uint16_t src_address;
  uint16_t dst_address;*/
    state = PARSENSOR;
    post CheckQueryType();
    //getinfo->data = par;
    //call Send.send[AM_GETINFO_MESSAGE](msg, sizeof(struct GetInfoMsg));
    return SUCCESS;
  }

  async event result_t InternalTemperature.dataReady(uint16_t data) {
    //struct QueryMsg *query = (struct QueryMsg *) msg->data;
    itemp = data;
    //post putIntTemp();
    state = INT_TEMP;
    post CheckQueryType();
    return SUCCESS;
  }

  async event result_t InternalVoltage.dataReady(uint16_t data) {
    //struct QueryMsg *query = (struct QueryMsg *) msg->data;
    ivolt = data;
    state = INT_VOLT;
    post CheckQueryType();
    //post putIntVoltage();
    return SUCCESS;
  }
#endif

/*------------------------------- Simulation Results ---------------------------*/
#ifndef TELOS_PLATFORM

  task void SimDataReady() {

  dbg(DBG_USR1, "Simulate Data state=%d\n",state);
  switch(state) {
    case HUMIDITY:
      dbg(DBG_USR1, "Simulate HUMIDITY %d\n", actionIndex);
      humidity = 10000;
      //post putHumidity();
      break;

    case TEMPERATURE:
      dbg(DBG_USR1, "Simulate TEMPERATURE %d\n", actionIndex);
      temperature = 2000;
      //post putTemperature();
      break;

    case TSRSENSOR:
      dbg(DBG_USR1, "Simulate TSRSENSOR %d\n", actionIndex);
      tsr = 3000;
      //post putTSR();
      break;

    case PARSENSOR:
      dbg(DBG_USR1, "Simulate PARSENSOR %d\n", actionIndex);
      par = 4000;
      //post putPAR();
      break;

    case INT_TEMP:
      dbg(DBG_USR1, "Simulate INT_TEMP %d\n", actionIndex);
      itemp = 5000;
      //post putIntTemp();
      break;

    case INT_VOLT:
      dbg(DBG_USR1, "Simulate INT_VOLT %d\n", actionIndex);
      ivolt = 5500;
      //post putIntVoltage();
      break;

  }
  post CheckQueryType();
}

#endif
#if 0
void CheckCounter() {
  dbg(DBG_USR1, "CheckCounter  actionIndex=%d numF=%d\n", actionIndex,rtp->numFields);
  actionIndex++;
  if (actionIndex >= rtp->numFields) {
    rtp->qid = (uint8_t)numSamples;
    dbg(DBG_USR1, "QID = %d\n", numSamples);
    // send results back to UQP
    signal RequestUpdate.receiveTuple(rtp);
    actionIndex = 0;
    numSamples--;
  }
  state = query->fields[actionIndex];

  if (numSamples > 0) {
    if (actionIndex == 0) {
      dbg(DBG_USR1, "***start next interval\n");
      call Timer.start(TIMER_ONE_SHOT, timeInterval);
    }
    else {
      dbg(DBG_USR1, "---go to next attribute\n");
      call Timer.start(TIMER_ONE_SHOT, OSCOPE_DELAY);
    }
  }
}
#endif

/*------------------------------- Result Tuple ---------------------------------*/

/*------------------------------- ULLA Storage ---------------------------------*/
#ifdef HISTORICAL_STORAGE
  event result_t WriteToStorage.writeDone(uint8_t *data, uint32_t bytes, result_t ok) {
    dbg(DBG_USR1,"WriteToStorage write done\n");
    return SUCCESS;
  }
#endif
} // end of implementation
