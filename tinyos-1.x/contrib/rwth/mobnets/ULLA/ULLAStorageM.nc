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
 * LLA implementation
<p>
 * @author Krisakorn Rerkrai <kre@mobnets.rwth-aachen.de>
 **/

includes MemAlloc;
includes UllaStorage;
includes msg_type;
includes UQLCmdMsg;

module ULLAStorageM {

  provides 	{
    interface StdControl;
    interface StorageIf;
  }
  uses {
    interface Timer as ValidityTimer;
    interface Leds;
    interface MemAlloc;
  }

}

/*
 *  Module Implementation
 */

#define  STORAGE_TIMEOUT   500
#define  BUFFER_SIZE  25
#define  STORAGE_BUFFER 5

implementation
{
  uint16_t counter;
  uint16_t buffer[BUFFER_SIZE];
  //bool result_is_old;
  //norace StorageMsg sbuffer[10];
  StorageMsg sbuffer[10];
  uint8_t index[BUFFER_SIZE];

  uint8_t cur_linkid;
  uint8_t adding_link;
	
	bool storageIsBusy;
	bool updateAppend;
	
	uint8_t sensorValidity;
	
	AttrDescr_t srQueueBuffer[STORAGE_BUFFER];
  uint8_t     bufIn, bufOut, bufCount;
  
  Handle gCurHandle;

	/*
	 * ullaLink class Linklist
	 */
  typedef struct 
	{
    void **next;
		struct ullaLink_t ulla;
    
  } ullaLinkList, *ullaLinkListPtr, **ullaLinkListHandle;

  ullaLinkListHandle ullaLinkListHead;
  ullaLinkListHandle ullaLinkListTail;
  
	ullaLinkListPtr pCurClass;
  ullaLinkListHandle hCurClass;
	
	struct ullaLinkProvider_t lp;
	struct sensorMeter_t sm;
		
	uint8_t validityAttr;	
	uint16_t validityCnt;
	
	/*
	 * Buffer for incoming AttrDescr
	 */
	AttrDescr_t bCurAttrDescr[2];
  uint8_t curAttrDescr;
	
	bool isNewLink(uint8_t linkid);
	ullaLinkListHandle getAddressList(uint8_t linkid);
	void putAttribute(ullaLinkListHandle clh, AttrDescr_t *attrDescr);
	
	task void initLinkProvider();
  
  command result_t StdControl.init() {
    
		//dbg(DBG_USR1,"%p %p\n",*hCurClass,pCurClass);
		atomic {
			sensorValidity = 0; // not valid
		
		}
		post initLinkProvider();
    return SUCCESS;
  }

  command result_t StdControl.start() {
	  atomic {
      counter = 0;
      ullaLinkListHead = NULL;
      ullaLinkListTail = NULL;
      adding_link = 0;
			curAttrDescr = 0;
			validityCnt = 0;
      //gCurUllaLink = &pCurUllaLink;
			//pCurClass = *hCurClass;
			///hCurClass = &(pCurClass);
			storageIsBusy = FALSE;
			updateAppend = FALSE;
      //result_is_old = FALSE;
    }
		return SUCCESS;
  }
  
  command result_t StdControl.stop() {

   return SUCCESS;
  }

	task void initLinkProvider() {
		lp.lp_id = TOS_LOCAL_ADDRESS;
	
	}
	
  task void StopValidityTimer() {
    call ValidityTimer.stop();
  }
  
  task void StartValidityTimer() {
    call ValidityTimer.start( TIMER_ONE_SHOT, STORAGE_TIMEOUT );
  }

  event result_t ValidityTimer.fired() {
    uint8_t linkid;
		uint8_t num_attr;
    // increase counter here (attributes)
    //call Leds.yellowToggle();
    atomic {
			for (linkid=0; linkid<10; linkid++) {
				for (num_attr=0; num_attr<MAX_ATTRIBUTE; num_attr++) {
					atomic {
						sbuffer[linkid].result_is_old[num_attr] = TRUE;
					}
				}
			}
    }
    return SUCCESS;
  }

/*----------------------------- Table -----------------------------------------*/

	void saveCurAttrDescr(AttrDescr_t *attrDescr) 
	{
		dbg(DBG_USR1, "ULLAStorage: saveCurAttrDescr %d\n", curAttrDescr);
		memcpy(&bCurAttrDescr[curAttrDescr], attrDescr, sizeof(AttrDescr_t));
		dbg(DBG_USR1, "id id %d %d\n",bCurAttrDescr[curAttrDescr].id, attrDescr->id);
		return;
	}
	
  uint8_t insertEntry(uint8_t linkid) 
	{
		//FIXME specify new size of memory (struct something)
		// FIXME 08.08.06: specify all supported classes (ullaLink, ullaLinkProvider, sensorMeter)
		dbg(DBG_USR1, "insertEntry size %d %d %d\n",sizeof(ullaLink_t), sizeof(ullaLinkProvider_t), sizeof(sensorMeter_t));
		
		return call MemAlloc.allocate(&gCurHandle, sizeof(ullaLink_t) + sizeof(ullaLinkProvider_t) + sizeof(sensorMeter_t));
  }

	task void insertEntryTask() 
	{
		// added 02.01.07
		if (bufCount == 0)
		{
			dbg(DBG_USR1, "bufCount = 0\n");
			storageIsBusy = FALSE;
		}
		else {
			if (storageIsBusy) 
			{
				post insertEntryTask();
			}	
			else 
			{
				if (isNewLink(cur_linkid) == TRUE) 
				{
				  dbg(DBG_USR1, "insertEntryTask is a new link\n");
					if (insertEntry(cur_linkid)) 
					{
						storageIsBusy = FALSE;
					}
					else 
					{	
						post insertEntryTask();
					}
				}
				else 
				{
				  AttrDescr_t *attrDescr;
					dbg(DBG_USR1, "insertEntryTask NOT a new link\n");
					// update attribute have to be called here!!! 02.01.07
					/*
					clh = (ullaLinkListHandle) *memory;
					
					//hCurClass = clh;
					pCurClass = *clh;
					hCurClass = &pCurClass;
					*/
					hCurClass = getAddressList(cur_linkid);
							
					//dbg(DBG_USR1, "pointer %p %p %p\n",*clh,pCurClass,*hCurClass);
					
					attrDescr = &srQueueBuffer[bufOut];
					putAttribute(hCurClass, attrDescr);
					
		
				}
				
			}
		}
	}
	/*
	task void RadioSendTask() {

    if (radioCount == 0) {
      radioBusy = FALSE;
    } 
		else {
      radioQueueBufs[radioOut].group = TOS_AM_GROUP;
      if (call RadioSend.send(&radioQueueBufs[radioOut]) == SUCCESS) 
			{
				//call Leds.redToggle();
      } 
			else {
				failBlink();
				post RadioSendTask();
      }
    }
  }*/
	
	ullaLinkListHandle getAddressList(uint8_t linkid) 
	{
		ullaLinkListHandle temp;
		struct ullaLink_t *temp_ulla;
		
		if (ullaLinkListHead != NULL) 
		{
			// check if it already exists
			temp = ullaLinkListHead;
      temp_ulla = &((**temp).ulla);
      
			while (temp != NULL) 
			{
        dbg(DBG_USR1, "Next: %d linkid %d %d\n", linkid, (**temp).ulla.link_id,(*temp_ulla).link_id);
				if (linkid == (**temp).ulla.link_id) 
				{
				  dbg(DBG_USR1, "ULLAStorage: received linkid already exists in the storage\n");
					return temp;
				}
        
        temp = (ullaLinkListHandle)(**temp).next;
        dbg(DBG_USR1,"move next %p %d\n",temp);
      }
      dbg(DBG_USR1,"List is empty, no linkid exists in the list\n");
		}
		else 
		{
		  dbg(DBG_USR1, "ullaLinkListHead is NULL\n");
		}
		
		return NULL;
	}
	
	// FIXME 02.08.06: hasn't been tested yet.
	bool isNewLink(uint8_t linkid) 
	{
		///ullaLinkListHandle temp;
		ullaLinkListHandle temp;
    struct ullaLink_t *temp_ulla;
    bool linkIsNew = TRUE;
    
    dbg(DBG_USR1,"ULLAStorage: checking whether a new link is received. ullaLinkListHead %p\n",ullaLinkListHead);
		
		if (ullaLinkListHead != NULL) 
		{
			// check if it already exists
			temp = ullaLinkListHead;
      temp_ulla = &((**temp).ulla);
      
			while (temp != NULL) 
			{
        dbg(DBG_USR1, "Next: %d linkid %d %d\n", linkid, (**temp).ulla.link_id,(*temp_ulla).link_id);
				if (linkid == (**temp).ulla.link_id) 
				{
				  dbg(DBG_USR1, "ULLAStorage: received linkid already exists in the storage\n");
					linkIsNew = FALSE;
					break;
				}
        
        ///temp = (ullaLinkListHandle)(**temp).next;
				temp = (ullaLinkListHandle)(**temp).next;
        dbg(DBG_USR1,"move next %p %d\n",temp);
      }
      dbg(DBG_USR1,"List is empty\n");
		}
		else 
		{
			linkIsNew = TRUE;
		}
		
		return linkIsNew;
	}
	
	// NEW 08.08.06
	void putAttribute(ullaLinkListHandle clh, AttrDescr_t *attrDescr) 
	{
		dbg(DBG_USR1, "putAttribute %p Attribute %d\n", *clh, attrDescr->attribute);
		
		atomic validityAttr = attrDescr->attribute;
		
		switch (attrDescr->attribute) 
		{
			case LINK_ID:
				
				memcpy(&((**clh).ulla.link_id), (uint8_t *)attrDescr->data, sizeof(uint16_t));
				dbg(DBG_USR1, "ULLAStorage: update LINK_ID data %d %d\n", *((uint8_t *)(attrDescr->data)),((**clh).ulla.link_id));
				//call ValidityTimer.start(TIMER_ONE_SHOT, LINK_ID_VALIDITY);
			break;
				
			case TYPE:
				dbg(DBG_USR1, "ULLAStorage: update TYPE data %d\n", *((uint8_t *)(attrDescr->data)));
				//(**temp).ulla.type = (uint8_t)attrDescr->data;
				memcpy(&((**clh).ulla.type), (uint8_t *)attrDescr->data, sizeof(uint8_t));
			break;
			/*	
			case LP_ID:
				dbg(DBG_USR1, "ULLAStorage: update LP_ID data %d\n", *((uint16_t *)(attrDescr->data)));
				//(**temp).ulla.lp_id = (uint8_t)attrDescr->data;
				memcpy(&((**clh).ulla.lp_id), (uint8_t *)attrDescr->data, sizeof(uint16_t));
			break;
			*/	
			case STATE:
				dbg(DBG_USR1, "ULLAStorage: update STATE data %d\n", *((uint8_t *)(attrDescr->data)));
				//**temp).ulla.state = (uint8_t)attrDescr->data;
				memcpy(&((**clh).ulla.state), (uint8_t *)attrDescr->data, sizeof(uint8_t));
			break;
				
			case MODE:
				dbg(DBG_USR1, "ULLAStorage: update MODE data %d\n", *((uint8_t *)(attrDescr->data)));
				//(**temp).ulla.mode = (uint8_t)attrDescr->data;
				memcpy(&((**clh).ulla.mode), (uint8_t *)attrDescr->data, sizeof(uint8_t));
			break;
			
			case NETWORK_NAME:
				dbg(DBG_USR1, "ULLAStorage: update NETWORK_NAME data %d\n", *((uint8_t *)(attrDescr->data)));
				//(**temp).ulla.network_name = (uint8_t)attrDescr->data;
				memcpy(&((**clh).ulla.network_name), (uint8_t *)attrDescr->data, sizeof(uint8_t));
			break;
	
			case LQI:
				dbg(DBG_USR1, "ULLAStorage: update LQI data %d\n", *((uint8_t *)(attrDescr->data)));
				//(**temp).ulla.network_name = (uint8_t)attrDescr->data;
				memcpy(&((**clh).ulla.lqi), (uint8_t *)attrDescr->data, sizeof(uint8_t));
				//call ValidityTimer.start(TIMER_ONE_SHOT, LQI_VALIDITY);
			break;
			
			case RSSI:
				dbg(DBG_USR1, "ULLAStorage: update RSSI data %d\n", *((uint8_t *)(attrDescr->data)));
				//(**temp).ulla.network_name = (uint8_t)attrDescr->data;
				memcpy(&((**clh).ulla.rssi), (uint8_t *)attrDescr->data, sizeof(uint8_t));
				//call ValidityTimer.start(TIMER_ONE_SHOT, RSSI_VALIDITY);
			break;
			
			case TEMPERATURE:
				dbg(DBG_USR1, "ULLAStorage: update RSSI data %d\n", *((uint8_t *)(attrDescr->data)));
				//(**temp).ulla.network_name = (uint8_t)attrDescr->data;
				memcpy(&(sm.temperature), (uint8_t *)attrDescr->data, sizeof(uint8_t));
				//call ValidityTimer.start(TIMER_ONE_SHOT, TEMPERATURE_VALIDITY);
			break;
			
			case TSRSENSOR:
				dbg(DBG_USR1, "ULLAStorage: update RSSI data %d\n", *((uint8_t *)(attrDescr->data)));
				//(**temp).ulla.network_name = (uint8_t)attrDescr->data;
				memcpy(&(sm.tsr), (uint8_t *)attrDescr->data, sizeof(uint8_t));
				//call ValidityTimer.start(TIMER_ONE_SHOT, TSR_VALIDITY);
			break;
			
			case PARSENSOR:
				dbg(DBG_USR1, "ULLAStorage: update RSSI data %d\n", *((uint8_t *)(attrDescr->data)));
				//(**temp).ulla.network_name = (uint8_t)attrDescr->data;
				memcpy(&(sm.par), (uint8_t *)attrDescr->data, sizeof(uint8_t));
				//call ValidityTimer.start(TIMER_ONE_SHOT, PAR_VALIDITY);
			break;
			
			case INT_TEMP:
				dbg(DBG_USR1, "ULLAStorage: update RSSI data %d\n", *((uint8_t *)(attrDescr->data)));
				//(**temp).ulla.network_name = (uint8_t)attrDescr->data;
				memcpy(&(sm.int_temperature), (uint8_t *)attrDescr->data, sizeof(uint8_t));
				//call ValidityTimer.start(TIMER_ONE_SHOT, INT_TEMP_VALIDITY);
			break;
			
			case INT_VOLT:
				dbg(DBG_USR1, "ULLAStorage: update RSSI data %d\n", *((uint8_t *)(attrDescr->data)));
				//(**temp).ulla.network_name = (uint8_t)attrDescr->data;
				memcpy(&(sm.int_voltage), (uint8_t *)attrDescr->data, sizeof(uint8_t));
				//call ValidityTimer.start(TIMER_ONE_SHOT, INT_VOLT_VALIDITY);
			break;
			
			case RF_POWER:
				dbg(DBG_USR1, "ULLAStorage: update RSSI data %d\n", *((uint8_t *)(attrDescr->data)));
				//(**temp).ulla.network_name = (uint8_t)attrDescr->data;
				memcpy(&(sm.rf_power), (uint8_t *)attrDescr->data, sizeof(uint8_t));
				//call ValidityTimer.start(TIMER_ONE_SHOT, RF_POWER_VALIDITY);
			break;
			
			default:
				dbg(DBG_USR1, "ULLAStorage: update UNDEFINED TYPE\n");
			break;
		}
		
		// added 02.01.07
		bufCount--;
		dbg(DBG_USR1, "bufCount = %d\n",bufCount);
		if( ++bufOut >= BUFFER_RX_LEN ) bufOut = 0;
        
    post insertEntryTask();
    
		return;	
	}
	
	// NEW 07.08.06
	bool updateAttribute(AttrDescr_t *attrDescr) 
	{
		//ullaLinkListHandle temp;
		ullaLinkListHandle temp;
		
		dbg(DBG_USR1, "ULLAStorage: updateAttribute: linkid %d attribute %d\n",attrDescr->id, attrDescr->attribute);
		atomic 
		{	
			temp = ullaLinkListHead;
		}
		
		storageIsBusy = TRUE;
		
		if (temp == NULL)
		  dbg(DBG_USR1, "ULLAStorageM: updateAttribute Linklist is NULL\n");
		while (temp != NULL) 
		{
			if (attrDescr->id == (**temp).ulla.link_id)
			{
				// FIXME 07.08.06: data type needs to be checked.
				putAttribute(temp, attrDescr);
				
			}
			else {
			  dbg(DBG_USR1, "id %d is not in the list\n", attrDescr->id);
			}
			//temp = (ullaLinkListHandle)(**temp).next;
			temp = (ullaLinkListHandle)(**temp).next;
		}
    
		storageIsBusy = FALSE;
		
		return TRUE;
	}
	
	/*
	 * If id == TOS_BCAST_ADDR, it should return all the links in the ULLAStorage.
	 */
	ullaLinkListHandle getClassList(uint16_t id) 
	{
		ullaLinkListHandle temp;
		
		atomic 
		{	
			temp = ullaLinkListHead;
		}
		dbg(DBG_USR1, "getClassList %d \n", id);
		while (temp != NULL) 
		{
			dbg(DBG_USR1, "22 %d\n", (**temp).ulla.link_id);
			if ((**temp).ulla.link_id == id)
			{
				dbg(DBG_USR1, "33 \n");
				return temp;
			}
			temp = (ullaLinkListHandle)(**temp).next;
		}
		dbg(DBG_USR1, "44\n");
		return NULL;
	}	

  void readUllaLinkAttribute(AttrDescr_t *attrDescr, SingleTuple *single_tuple, uint8_t *length) 
	{
	  ullaLinkListHandle clh;
				
		dbg(DBG_USR1, "ULLAStorage: StorageIf.readUllaLinkAttribute linkid %d requested attr %d\n", attrDescr->id, attrDescr->attribute); 
		clh = getClassList(attrDescr->id);
		dbg(DBG_USR1, "ULLAStorage: getClassList %p\n", clh);
		single_tuple->linkid = attrDescr->id;
		switch (attrDescr->attribute) 
		{
			case LINK_ID:
				//memcpy((uint8_t *)attrDescr->data, &((**clh).ulla.link_id), sizeof(uint16_t));
				//memcpy(attrDescr->data, &((**clh).ulla.link_id), sizeof(uint16_t));
				attrDescr->data = &((uint16_t)(**clh).ulla.link_id);
				single_tuple->u.value16 = (**clh).ulla.link_id;
				dbg(DBG_USR1, "ULLAStorage: readUllaLinkAttribute ullaLink class LINK_ID data %d %d\n", *((uint16_t *)(attrDescr->data)),((**clh).ulla.link_id));
			break;
		
			case TYPE:
				dbg(DBG_USR1, "ULLAStorage: readUllaLinkAttribute ullaLink class TYPE data %d\n", *((uint8_t *)(attrDescr->data)));
				//(**temp).ulla.type = (uint8_t)attrDescr->data;
				//memcpy((uint8_t *)attrDescr->data, &((**clh).ulla.type), sizeof(uint8_t));
				attrDescr->data = (uint16_t *)&((**clh).ulla.type);
				single_tuple->u.value16 = (uint16_t)((**clh).ulla.type);
			break;
				
			case LP_ID:
				dbg(DBG_USR1, "ULLAStorage: readUllaLinkAttribute ullaLink class LP_ID data %d\n", *((uint16_t *)(attrDescr->data)));
				//(**temp).ulla.lp_id = (uint8_t)attrDescr->data;
				//memcpy((uint8_t *)attrDescr->data, &((**clh).ulla.lp_id), sizeof(uint16_t));
				*attrDescr->data = TOS_LOCAL_ADDRESS; // can be read from the list as well.
				single_tuple->u.value16 = TOS_LOCAL_ADDRESS;
			break;
				
			case STATE:
				dbg(DBG_USR1, "ULLAStorage: readUllaLinkAttribute ullaLink class STATE data %d\n", *((uint8_t *)(attrDescr->data)));
				//**temp).ulla.state = (uint8_t)attrDescr->data;
				//memcpy((uint8_t *)attrDescr->data, &((**clh).ulla.state), sizeof(uint8_t));
				attrDescr->data = (uint16_t *)&((**clh).ulla.state);
				single_tuple->u.value16 = (uint16_t)((**clh).ulla.state);
			break;
				
			case MODE:
				dbg(DBG_USR1, "ULLAStorage: readUllaLinkAttribute ullaLink class MODE data %d\n", *((uint8_t *)(attrDescr->data)));
				//(**temp).ulla.mode = (uint8_t)attrDescr->data;
				//memcpy((uint8_t *)attrDescr->data, &((**clh).ulla.mode), sizeof(uint8_t));
				attrDescr->data = (uint16_t *)&((**clh).ulla.mode);
				single_tuple->u.value16 = (uint16_t)((**clh).ulla.mode);
			break;
			
			case NETWORK_NAME:
				dbg(DBG_USR1, "ULLAStorage: readUllaLinkAttribute ullaLink class NETWORK_NAME data %d\n", *((uint8_t *)(attrDescr->data)));
				//(**temp).ulla.network_name = (uint8_t)attrDescr->data;
				//memcpy((uint8_t *)attrDescr->data, &((**clh).ulla.network_name), sizeof(uint8_t));
				attrDescr->data = (uint16_t *)&((**clh).ulla.network_name);
				single_tuple->u.value16 = (uint16_t)((**clh).ulla.network_name);
			break;
			
			case RSSI:
				dbg(DBG_USR1, "ULLAStorage: readUllaLinkAttribute ullaLink class RSSI data %d\n", *((uint8_t *)(attrDescr->data)));
				//(**temp).ulla.network_name = (uint8_t)attrDescr->data;
				//memcpy((uint8_t *)attrDescr->data, &((**clh).ulla.rssi), sizeof(uint8_t));
				//memcpy(attrDescr->data, &((**clh).ulla.rssi), sizeof(uint16_t));
				attrDescr->data = (uint16_t *)&((**clh).ulla.rssi);
				single_tuple->u.value16 = (uint16_t)((**clh).ulla.rssi);
			break;
			
			case LQI:
				dbg(DBG_USR1, "ULLAStorage: readUllaLinkAttribute ullaLink class LQI data %d\n", *((uint8_t *)(attrDescr->data)));
				//(**temp).ulla.network_name = (uint8_t)attrDescr->data;
				//memcpy((uint8_t *)attrDescr->data, &((**clh).ulla.lqi), sizeof(uint8_t));
				attrDescr->data = (uint16_t *)&((**clh).ulla.lqi);
				single_tuple->u.value16 = (uint16_t)((**clh).ulla.lqi);
			break;

			default:
				dbg(DBG_USR1, "ULLAStorage: readUllaLinkAttribute ullaLink class UNDEFINED\n");
			break;
	
			
		}
		
		return;
	}
	
	bool readElseAttribute(AttrDescr_t *attrDescr, elseHorizontalTuple *else_tuple, uint8_t *length) 
	{
		bool ret;
		else_tuple->attr = attrDescr->attribute;
		//call Leds.yellowOn();
	  switch (attrDescr->className) 
		{
			case ullaLinkProvider:
				dbg(DBG_USR1, "className ullaLinkProvider\n");
				switch (attrDescr->attribute) 
				{
					case LP_ID:
					  //call Leds.yellowToggle();
						*attrDescr->data = TOS_LOCAL_ADDRESS;
						else_tuple->u.value16 = TOS_LOCAL_ADDRESS;
						ret = TRUE;
						dbg(DBG_USR1, "ULLAStorage: readElseAttribute linkProvider class LP_ID data %d\n", *((uint16_t *)(attrDescr->data)));
					break;
				
					default:
						dbg(DBG_USR1, "ULLAStorage: readElseAttribute linkProvider class UNDEFINED\n");
					break;
				}
			//	return SUCCESS;
			break;
			
			case sensorMeter:
				dbg(DBG_USR1, "className sensorMeter\n");
				switch (attrDescr->attribute) 
				{
					case LP_ID:
					  //call Leds.yellowToggle();
						*attrDescr->data = TOS_LOCAL_ADDRESS;
						else_tuple->u.value16 = TOS_LOCAL_ADDRESS;
						dbg(DBG_USR1, "ULLAStorage: readElseAttribute linkProvider class LP_ID data %d\n", *((uint16_t *)(attrDescr->data)));
						ret = FALSE;
					break;
					
					case HUMIDITY:
						attrDescr->data = (uint16_t *)&(sm.humidity);
						else_tuple->u.value16 = sm.humidity;
						ret = FALSE;
					break;
					
					case TEMPERATURE:
						attrDescr->data = (uint16_t *)&(sm.temperature);
						else_tuple->u.value16 = sm.temperature;
						ret = FALSE;
					break;
					
					case TSRSENSOR:
						attrDescr->data = (uint16_t *)&(sm.tsr);
						else_tuple->u.value16 = sm.tsr;
						ret = FALSE;
					break;
					
					case PARSENSOR:
						attrDescr->data = (uint16_t *)&(sm.par);
						else_tuple->u.value16 = sm.par;
						ret = FALSE;
					break;
					
					case INT_TEMP:
						attrDescr->data = (uint16_t *)&(sm.int_temperature);
						else_tuple->u.value16 = sm.int_temperature;
						ret = FALSE;
					break;
					
					case INT_VOLT:
						attrDescr->data = (uint16_t *)&(sm.int_voltage);
						else_tuple->u.value16 = sm.int_voltage;
						ret = FALSE;
					break;
					
					case RF_POWER:
						attrDescr->data = (uint16_t *)&(sm.rf_power);
						else_tuple->u.value16 = sm.rf_power;
						ret = FALSE;
					break;
					
					default:
					
					break;
				
				}
				//return SUCCESS;
			break;
			
			default:
				dbg(DBG_USR1, "class not supported\n");
				//return FAIL;
				//single_tuple->u.value16 = 0x9988;
				ret = FALSE;
			break;
		}
		
		return ret;
	}
	
	void getIdList(uint8_t *idList, uint8_t *num_id) 
	{
		ullaLinkListHandle temp;
		uint8_t i=0;
		
		dbg(DBG_USR1, "ULLAStorage: getIdList");
		atomic 
		{	
			temp = ullaLinkListHead;
		}
		while (temp != NULL) 
		{
			dbg(DBG_USR1, " %d ", (**temp).ulla.link_id);
			idList[i] = (**temp).ulla.link_id;
			temp = (ullaLinkListHandle)(**temp).next;
			i++;
		}
		*num_id = i;
		dbg(DBG_USR1, "\n");
		
		return;
	}
	
	uint8_t getNextId(uint8_t *idList, uint8_t i) 
	{
	  return idList[i];
	}
	
	void attachDataToUllaLinkHorizontalTuple(ullaLinkHorizontalTuple *horizontal_tuple, SingleTuple *data_tuple, uint8_t *tuple_length, uint8_t tuple_index)
	{
	  (*tuple_length)++;
		memcpy(&(horizontal_tuple->single_tuple[tuple_index]), data_tuple, sizeof(SingleTuple));
		dbg(DBG_USR1, "attachDataToUllaLinkHorizontalTuple %p %p index %d length %d size %d\n", horizontal_tuple, &(horizontal_tuple->single_tuple[tuple_index]), tuple_index, *tuple_length, sizeof(SingleTuple));
		
	  return;
	}
	
	command result_t StorageIf.readAttributeFromUllaLink(AttrDescr_t *attrDescr, ullaLinkHorizontalTuple *horizontal_tuple, uint8_t *attr_length, uint8_t *tuple_length) 
	{
		AttrDescr_t singleDescr;
		SingleTuple temp_tuple;
		SingleTuple *single_tuple = &temp_tuple;
		//uint8_t tuple_length;
		uint8_t idList[MAX_LINKS];
		uint8_t num_id, i;
		/*
		 * 1. Check classType. 
		 * 2. Check if links exist in the storage. If not, return FAIL. If so, return a list of attribute and its size.
		 */
		 
		
		//dbg(DBG_USR1, "ULLAStorage: StorageIf.readAttributeNew linkid %d\n", attrDescr->id); 
		//clh = getClassList(attrDescr->id);
		//dbg(DBG_USR1, "ULLAStorage: getClassList %p\n", clh);
		
		/*
		 * 03.01.07
		 * Check id here
		 * 1. If id is a single one, fetch an attribute directly from the storage.
		 * 2. If id is 0xFFFF, get the whole list of ids, then fetch an attribute
		 *    from one by one link.
		 */
		 
		if (attrDescr->id != 0xffff) 
		{
			dbg(DBG_USR1, "ULLAStorage: single link\n");
			readUllaLinkAttribute(attrDescr, single_tuple, attr_length);
			attachDataToUllaLinkHorizontalTuple(horizontal_tuple, single_tuple, tuple_length, 0);
		}
		else // all
		{
		  //call Leds.yellowToggle(); 
		  dbg(DBG_USR1, "ULLAStorage: all links\n");
			getIdList(idList, &num_id);  // read a whold list of linkids from the Storage
			
			for (i = 0; i < num_id; i++)
			{
			  memcpy(&singleDescr, attrDescr, sizeof(AttrDescr_t));
				//dbg(DBG_USR1, "attribute %d\n", attrDescr->attribute);
				singleDescr.id = getNextId(idList, i);  // read one linkid from the list
				dbg(DBG_USR1, "attribute %d next linkid %d\n", singleDescr.attribute, singleDescr.id);
			  readUllaLinkAttribute(&singleDescr, single_tuple, attr_length);
				attachDataToUllaLinkHorizontalTuple(horizontal_tuple, single_tuple, tuple_length, i);            // add a single reading to the data tube.
			}
			horizontal_tuple->attr = attrDescr->attribute;
			horizontal_tuple->num_links = num_id;
		}
		
		return SUCCESS;
	}
	
	command result_t StorageIf.readAttributeFromElse(AttrDescr_t *attrDescr, elseHorizontalTuple *horizontal_tuple, uint8_t *attr_length, uint8_t *tuple_length) {
		//call Leds.redToggle();
		
		// check validity
		//if ()
		if (readElseAttribute(attrDescr, horizontal_tuple, attr_length) == TRUE)
		//attachDataToElseHorizontalTuple(horizontal_tuple, single_tuple, tuple_length, 0);
		return SUCCESS;
		
		return FAIL;
	
	}
	

	/* FIXME 02.08.06: linkid should be removed. linkid should be considered as another attribute. We can either do
	 * "SELECT lpId FROM ullaLinkProvider" or "SELECT rxQuality FROM ullaLink WHERE lpId = xx"
	 * 
	 * FIXME: data needs not to be uint16_t. It should be returned as a pointer of data tuple.
	 */
	command result_t StorageIf.readAttribute(uint16_t linkid, uint8_t attribute, void* data, uint8_t *length) 
	{
    uint16_t * value = (uint16_t *) data;
    // first check if the attribute is already cached or too old (maybe with a simple counter).
    // if there is no result present -> create one in the storage.
	//atomic {
	
    dbg(DBG_USR1, "ULLAStorage: StorageIf.read %d %d  ",sbuffer[linkid].buffer[attribute],sbuffer[linkid].result_is_old[attribute]);
    
		if (sbuffer[linkid].buffer[attribute] && !sbuffer[linkid].result_is_old[attribute]) 
		{
      dbg(DBG_USR1, " SUCCESS\n");
      //*data = buffer[attribute];
      value = (uint16_t *)&(sbuffer[linkid].buffer[attribute]);
      //call Leds.greenToggle();
      return SUCCESS;
			
    }
    else {
      dbg(DBG_USR1, " FAIL %d %d att%d\n",sbuffer[linkid].buffer[attribute],sbuffer[linkid].result_is_old[attribute],attribute);
      index[attribute] = linkid;
      return FAIL;  // result doesn't exist nor too old
    }

  }
  
  //command result_t StorageIf.updateAttribute(uint16_t linkid, uint8_t attribute, void* data, uint8_t *length) 
	command result_t StorageIf.updateAttribute(AttrDescr_t *attrDescr) 
	{
    //uint16_t *value = (uint16_t *)data;
		///uint16_t *value = (uint16_t *)attrDescr->data;
		
		/*
		 * FIXME 02.08.06: If no links exist in the ULLAStorage, creat an entry.
		 */
		/*
		 * FIXME 02.08.06: If there is more than one link coming at the same time, need to check the flag whether
		 * or not the storage is busy. Because it has to keep the linkid and attributes for the current link which is
		 * waiting for memory allocation.
		 */
		//call Leds.greenToggle(); 
		/*
		if (bufCount < BUFFER_RX_LEN) 
						{
							memcpy(&rxQueueBuffer[bufIn], rmsg, sizeof(TOS_Msg));

							bufCount++;
      
							if( ++bufIn >= BUFFER_RX_LEN ) bufIn = 0;
      
							if (!ullaBusy) 
							{
								if (post SignalReceiveTask()) 
								{
									ullaBusy = TRUE;
								}
							}
						} 
			*/			
		if (isNewLink(attrDescr->id))
		{
			atomic cur_linkid = attrDescr->id;
			dbg(DBG_USR1, "ULLAStorage: isNewLink\n");
			
			if (bufCount < STORAGE_BUFFER) 
			{
				memcpy(&srQueueBuffer[bufIn], attrDescr, sizeof(AttrDescr_t));
				bufCount++;
  			if( ++bufIn >= STORAGE_BUFFER ) bufIn = 0;
				if (!storageIsBusy) 
				{
				  dbg(DBG_USR1, "StorageNotBusy post insertEntryTask\n");
					post insertEntryTask();
				}
			}
			else {
				dbg(DBG_USR1, "Drop query\n");
			}
			/*
			if (!storageIsBusy) 
			{
				dbg(DBG_USR1, "StorageNotBusy insertEntry\n");
				storageIsBusy = TRUE;
				updateAppend = TRUE;
				saveCurAttrDescr(attrDescr);
				insertEntry(attrDescr->id);
			}
			else 
			{
				dbg(DBG_USR1, "ULLAStorage.updateAttribute: StorageBusy post insertEntry\n");
				post insertEntryTask();
			}*/
		}
		else 
		{
			// FIXME 04.08.06: This has to use linklist. No more fixed buffer.
			dbg(DBG_USR1, "ULLAStorage: notNewLink\n");
			/*
			atomic 
			{
				//dbg(DBG_USR1, "ULLAStorage: StorageIf.Update %d att%d\n",value[0],attribute);
				
				sbuffer[attrDescr->id].buffer[attrDescr->attribute] = value[0];
				sbuffer[attrDescr->id].result_is_old[attrDescr->attribute] = FALSE; // FALSE for validity > 0
				sbuffer[attrDescr->id].counter = 0;
				//buffer[attribute] = (uint16_t) *data;
				//buffer[attribute] = value[0];
				dbg(DBG_USR1, "ULLAStorage: Updated linkid%d %d %d\n",attrDescr->id,sbuffer[attrDescr->id].buffer[attrDescr->attribute],attrDescr->attribute);
			}*/
			storageIsBusy = TRUE;
			updateAttribute(attrDescr);
		}
		
		storageIsBusy = FALSE;
		
		// FIXME 02.08.06: Validity check needs to be changed.
    post StopValidityTimer();
    post StartValidityTimer();
    return SUCCESS;
  }
	
	command result_t StorageIf.updateMessage(TOS_Msg *update) {
	  AttrDescr_t attrDescr;
		FixedAttrMsg *fixed = (FixedAttrMsg *)update->data;
		
	  dbg(DBG_USR1, "ULLAStorageM: updateMessage\n");
		// need to update all the attributes (RSSI, LQI)
		
		attrDescr.id = fixed->node_id;
		attrDescr.className = ullaLink;
		//attrDescr.id = ullaLink;
		attrDescr.attribute = RSSI;
		attrDescr.data = (void *)(&update->strength);
		
		// FIXME: same as updateAttribute function, should be
    // rewritten. 
		
		if (isNewLink(attrDescr.id))
		{

			atomic cur_linkid = attrDescr.id;
			dbg(DBG_USR1, "ULLAStorage: isNewLink\n");
			
			if (bufCount < STORAGE_BUFFER) 
			{
				memcpy(&srQueueBuffer[bufIn], &attrDescr, sizeof(AttrDescr_t));
				bufCount++;
  			if( ++bufIn >= STORAGE_BUFFER ) bufIn = 0;
				if (!storageIsBusy) 
				{
				  dbg(DBG_USR1, "StorageNotBusy post insertEntryTask\n");
					//saveCurAttrDescr(&attrDescr);
					post insertEntryTask();
				}
			}
			else {
				dbg(DBG_USR1, "Drop query\n");
			}
			
			attrDescr.id = fixed->node_id;
			attrDescr.className = ullaLink;
			attrDescr.attribute = LQI;
			attrDescr.data = (void *)(&update->lqi);
			
			if (bufCount < STORAGE_BUFFER) 
			{
				memcpy(&srQueueBuffer[bufIn], &attrDescr, sizeof(AttrDescr_t));
				bufCount++;
				if( ++bufIn >= STORAGE_BUFFER ) bufIn = 0;
				if (!storageIsBusy) 
				{
				  dbg(DBG_USR1, "StorageNotBusy post insertEntryTask\n");
					//saveCurAttrDescr(&attrDescr);
					///post insertEntryTask();
				}
			}
			else {
				dbg(DBG_USR1, "Drop query\n");
			}
			/*
			if (!storageIsBusy) 
			{
				dbg(DBG_USR1, "StorageNotBusy insertEntry\n");
				storageIsBusy = TRUE;
				updateAppend = TRUE;
				saveCurAttrDescr(&attrDescr);
				insertEntry(attrDescr.id);
			}
			else 
			{
				dbg(DBG_USR1, "ULLAStorage.updateMessage: StorageBusy post insertEntry\n");
				post insertEntryTask();
			}*/
		}
		else 
		{
			dbg(DBG_USR1, "ULLAStorage: notNewLink\n");
			storageIsBusy = TRUE;
			updateAttribute(&attrDescr);
			
			// not a new link, then update all the rest attributes here
			
			attrDescr.id = fixed->node_id;
			attrDescr.className = ullaLink;
			attrDescr.attribute = LQI;
			attrDescr.data = (void *)(&update->lqi);
		
			dbg(DBG_USR1, "ULLAStorage: notNewLink update LQI\n");
			storageIsBusy = TRUE;
			updateAttribute(&attrDescr);
		}
		//updateAttribute(&attrDescr);
	/*	
		// if a link is new, MemAlloc needs to be first processed.
		attrDescr.id = update->data[0];
		attrDescr.className = ullaLink;
		attrDescr.attribute = LQI;
		attrDescr.data = (void *)(&update->lqi);
		
		dbg(DBG_USR1, "ULLAStorage: notNewLink\n");
		storageIsBusy = TRUE;
		updateAttribute(&attrDescr);
	*/	
		#if 0
		if (isNewLink(attrDescr.id))
		{
			atomic cur_linkid = attrDescr.id;
			dbg(DBG_USR1, "ULLAStorage: isNewLink\n");
			
			if (bufCount < STORAGE_BUFFER) 
			{
				memcpy(&srQueueBuffer[bufIn], &attrDescr, sizeof(AttrDescr_t));
				bufCount++;
  			if( ++bufIn >= STORAGE_BUFFER ) bufIn = 0;
				if (!storageIsBusy) 
				{
				  dbg(DBG_USR1, "StorageNotBusy post insertEntryTask\n");
					//saveCurAttrDescr(&attrDescr);
					post insertEntryTask();
				}
			}
			else {
				dbg(DBG_USR1, "Drop query\n");
			}
			
			/*
			if (!storageIsBusy) 
			{
				dbg(DBG_USR1, "StorageNotBusy insertEntry\n");
				storageIsBusy = TRUE;
				updateAppend = TRUE;
				saveCurAttrDescr(&attrDescr);
				insertEntry(attrDescr.id);
			}
			else 
			{
				dbg(DBG_USR1, "ULLAStorage.updateMessage2: StorageBusy post insertEntry\n");
				post insertEntryTask();
			}*/
		}
		else 
		{
			dbg(DBG_USR1, "ULLAStorage: notNewLink\n");
			storageIsBusy = TRUE;
			updateAttribute(&attrDescr);
		}
		#endif
		//updateAttribute(&attrDescr);
	
		return SUCCESS;
	}

	/*
	 * Check whether there is still an available link in the storage.
	 * FIXME: should check whether there is a next link (instead of returning 0)
	 */
	command result_t StorageIf.hasNextLink() {
	
		return 0; // FIXME 
	}
	
	/*
	 * Fetch the next link in the storage if present.
	 */
	command uint8_t StorageIf.getLink() {
	
		return 0; // FIXME 
	}
	
	// FIXME 02.08.06: links variable is useless, should be fixed.
	
  command result_t StorageIf.readAvailableLinks(uint8_t *numLinks, uint8_t *links) {
    //ullaLinkListHandle temp;
		ullaLinkListHandle temp;
    struct ullaLink_t *temp_ulla;
    uint8_t num_links=0;
    uint16_t linklist[MAX_LINKS];
    /*
    //gCurUllaLink = (struct ullaLink_t **)*memory;
    ulh = (ullaLinkListHandle) *memory;
    //gCurUllaLink = (struct ullaLink_t **)&&(&((**ulh).ulla));
    pCurUllaLink = &((**ulh).ulla);
    dbg(DBG_USR1,"Yo**** %p\n",(**ullaLinkListHead).next);
    //(**gCurUllaLink).link_id  = 1;
    pCurUllaLink->link_id  = cur_linkid;
      */
    ////ullaLinkListHead = NULL;
    //gCurUllaLink = (struct ullaLink_t **)*memory;

    dbg(DBG_USR1,"ULLAStorage: readAvailableLinks\n");
		//call Leds.greenToggle();
		/*
		 * No links exist in the ULLAStorage.
		 */
    if (ullaLinkListHead == NULL) 
		//if (num_links == 0)
		{
      dbg(DBG_USR1, "ULLAStorage: ullaLinkListHead is empty\n");
			//call Leds.greenToggle();
			*numLinks = 0;
			links = NULL;
			return FAIL;
    }
		/*
		 * Otherwise return number of links and its list head.
		 */
		#if 1 
    else 
		{
			//call Leds.greenToggle();
			#if 1
      temp = ullaLinkListHead;
      temp_ulla = &((**temp).ulla);
      //ulla = (struct ullaLink_t **)temp;
      //ulla = &((**temp).ulla);
      //dbg(DBG_USR1, "ULLAStorage: ullaLinkListHead is NOT empty %d\n",(**ullaLinkListHead).ulla.link_id);
      //dbg(DBG_USR1, "ULLAStorage: ullaLinkListHead %p is NOT empty %d\n",gCurUllaLink,(*ullaLinkListHead)->ulla.link_id);
      //dbg(DBG_USR1, "ULLAStorage: ullaLinkListHead %p %p %p is NOT empty %d %d\n",ulla,gCurUllaLink,ullaLinkListTail,(*ulla).link_id,(**gCurUllaLink).link_id);
      
			#if 1
			while (temp != NULL) 
			{
        dbg(DBG_USR1, "Next: linkid %d %d\n", (**temp).ulla.link_id,(*temp_ulla).link_id);

        //linklist[num_links] = (*temp_ulla).link_id;
        linklist[num_links] = (**temp).ulla.link_id;

        if ((**temp).next != NULL) dbg(DBG_USR1,"not NULL %p %p\n",temp,(**temp).next);
        //temp = (ullaLinkListHandle)(**temp).next;
				temp = (ullaLinkListHandle)(**temp).next;
        dbg(DBG_USR1,"move next %p %d\n",temp,linklist[num_links]);
        num_links++;
      }
			
			dbg(DBG_USR1,"List is empty\n");
			#endif
      
      if (temp != NULL) memcpy(links, linklist, MAX_LINKS); 
      
			*numLinks = num_links;  
			
			#endif
    }
		#endif
    return SUCCESS;
  }
  
  command result_t StorageIf.addLink(uint8_t linkid) {
    dbg(DBG_USR1, "ULLAStorage: addLink %d\n", linkid);
    // FIXME
		//call Leds.greenToggle();
    if (!adding_link) {
    
      atomic {
        adding_link = 1;
        cur_linkid = linkid;
      }
      insertEntry(linkid);
    } else {
      dbg(DBG_USR1, "still adding another link\n");
      return FAIL;
    }

    return SUCCESS;
  }

  command result_t StorageIf.removeLink(uint8_t linkid) 
	{
    // delete list here
    return SUCCESS;
  }
  
  void addUllaLink(HandlePtr memory) 
	{
    //ullaLinkListHandle ulh;
		ullaLinkListHandle clh;
		AttrDescr_t *attrDescr;

/*
		ullaLinkListHandle temp;
    struct ullaLink_t *ulla;
    bool linkIsNew = TRUE;
    
    dbg(DBG_USR1,"ULLAStorage: checking whether a new link is received. ullaLinkListHead %p\n",ullaLinkListHead);
		
		if (ullaLinkListHead != NULL) 
		{
			// check if it already exists
			temp = ullaLinkListHead;
      temp_ulla = &((**temp).ulla);
			
		(**temp).ulla.link_id
	*/
		
    //gCurUllaLink = (struct ullaLink_t **)*memory;
    ////ulh = (ullaLinkListHandle) *memory;
		clh = (ullaLinkListHandle) *memory;
		//hCurClass = clh;
		pCurClass = *clh;
		hCurClass = &pCurClass;
		//gCurUllaLink = (struct ullaLink_t **)&&(&((**ulh).ulla));
    
		// NEW 08.08.06
		/////pCurUllaLink = &((**ulh).ulla);
		///////pCurClass = &((**clh));
		//(**gCurUllaLink).link_id  = 1;
    
		dbg(DBG_USR1, "pointer %p %p %p\n",*clh,pCurClass,*hCurClass);
		
		// FIXME 02.01.07: Replace by srQueueBuffer[bufIn]
		/*attrDescr = &bCurAttrDescr[curAttrDescr];
		dbg(DBG_USR1, "addUllaLink %p %d %d %d\n",&bCurAttrDescr[curAttrDescr],curAttrDescr,bCurAttrDescr[curAttrDescr].id,attrDescr->id);
		*/
		
		attrDescr = &srQueueBuffer[bufOut];
		
		/*
		 * FIXME 02.08.06: put more info here (not only linkid).
		 * cur_linkid hasn't been initialized correctly.
		 */
		
		(**hCurClass).ulla.link_id  = cur_linkid;
		///(**hCurClass).ulla.link_id  = attrDescr->id;
		(**hCurClass).ulla.lp_id  = TOS_LOCAL_ADDRESS;
		
		putAttribute(hCurClass, attrDescr);
		
    atomic {
      adding_link = 0;
    }
  }
  
/*----------------------------- TinyAlloc --------------------------------------*/

/*--------------------------- MemAlloc Events -------------------------------*/

  event result_t MemAlloc.allocComplete(Handle *handle, result_t complete) {
    ///ullaLinkListHandle ulh = (ullaLinkListHandle)*handle;
		ullaLinkListHandle clh = (ullaLinkListHandle)*handle;

    //call Leds.greenToggle();
    dbg(DBG_USR1,"MemAlloc.alloc complete\n");
		
    ///(**ulh).next = NULL;
		(**clh).next = NULL;
    atomic {
      if (ullaLinkListTail == NULL) {

	      ///ullaLinkListTail = ulh;
	      ///ullaLinkListHead = ulh;
				ullaLinkListTail = clh;
	      ullaLinkListHead = clh;
				
				/*
				 * Initialize the current class handle.
				 */
				pCurClass = *clh;
				hCurClass = &pCurClass;
				
	      dbg(DBG_USR1,"--** start ullaLinkListTail **--  %d  %p  %p %p\n",(*ullaLinkListHead)->ulla.link_id, ullaLinkListHead, ullaLinkListTail,(**ullaLinkListHead).next);
				
	    } else {
        dbg(DBG_USR1,"--** next ullaLinkListTail **--\n");
	      ///(**ullaLinkListTail).next = (void **)ulh;
	      ///ullaLinkListTail = ulh;
				(**ullaLinkListTail).next = (void **)clh;
	      ullaLinkListTail = clh;
	    }
   }
	  
    addUllaLink((HandlePtr)&ullaLinkListTail);

    return SUCCESS;
  }

  event result_t MemAlloc.reallocComplete(Handle handle, result_t complete) {
    dbg(DBG_USR1,"MemAlloc.realloc complete\n");
    return SUCCESS;
  }

  event result_t MemAlloc.compactComplete() {
    dbg(DBG_USR1,"MemAlloc.compact complete\n");
    return SUCCESS;
  }

} // end implementation










