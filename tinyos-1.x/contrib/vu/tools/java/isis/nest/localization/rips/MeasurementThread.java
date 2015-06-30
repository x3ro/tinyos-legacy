/*
 * Copyright (c) 2005, Vanderbilt University
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for instruction and non-commercial research only, without
 * fee, and without written agreement is hereby granted, provided that the
 * this copyright notice including the following two paragraphs and the 
 * author's name appear in all copies of this software.
 * 
 * IN NO EVENT SHALL VANDERBILT UNIVERSITY BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF VANDERBILT
 * UNIVERSITY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * VANDERBILT UNIVERSITY SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND VANDERBILT UNIVERSITY HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.
 */
 // @author Brano Kusy: kusy@isis.vanderbilt.edu
 
package isis.nest.localization.rips;

import java.util.ArrayList;

import net.tinyos.mcenter.RemoteControl;

/**
 * @author brano
 *
 */
public class MeasurementThread extends Thread{

    public static int MT_STATE_IDLE = 0;
    public static int MT_STATE_RUNING = 1;
	private static int START_MEASUREMENT_CMD = 0x12;

	private MeasurementEndedCallback callback = null;
	private static int measurementSleepTime = 10000;

	public int getMeasurementSleepTime(){
		return measurementSleepTime;
	}
	public void setMeasurementSleepTime(int time){
		measurementSleepTime = time;
	}
	
	private int state = MT_STATE_IDLE;
	public int getThreadState(){
		return state;
	}
	private int a1 = 0;
	private int a2 = 0;
	private ArrayList senders = new ArrayList();
	private int lastSeqNum;
    private int masterID;
	public int getMasterID(){
		return masterID;
	}
	public void setMasterID(int i){
		masterID = i;
	}
    private int assistantID;
	public int getAssistantID(){
		return assistantID;
	}
	public void setAssistantID(int i){
		assistantID = i;
	}
    private static int sequenceNumber = 0;
	public int getSequenceNumber(){
		return sequenceNumber;
	}
	public void setSequenceNumber(int seqNum){
		sequenceNumber = seqNum;
	}
    
    private int moteSequenceNumber = 0;
	public int getMoteSequenceNumber(){
		return moteSequenceNumber;
	}
	public void setMoteSequenceNumber(int seqNum){
		moteSequenceNumber = seqNum;
	}
    
	public boolean init(Object[] senders, MeasurementEndedCallback callback){
		if( state != MT_STATE_IDLE){
		    System.err.println("Measurement is currently runing!");
			return false;
		}
		
		if(senders.length < 2){
			System.err.println("At least 2 senders are needed!!");
			return false;
		}
		state = MT_STATE_RUNING;
		
		a1 = 0;
		a2 = 1;
		this.senders.clear();
		for (int i=0; i<senders.length; i++){
			LocalizationData.Sensor tmpSensor = (LocalizationData.Sensor)senders[i];
			if (tmpSensor.isSender())
				this.senders.add(tmpSensor);
		}
			
		this.callback = callback;
		
		return true;
	}
	
	public void run(){
        while (state == MT_STATE_RUNING && a1 < senders.size()-1){
            try{
            	masterID = ((LocalizationData.Sensor)senders.get(a1)).getId();
            	assistantID = ((LocalizationData.Sensor)senders.get(a2)).getId();
            	byte[] bytes = new byte[3];
            	bytes[0] = (byte)(moteSequenceNumber & 0xFF);
            	bytes[1] = (byte)(assistantID & 0xFF);
            	bytes[2] = (byte)((assistantID>>8) & 0xFF);
    		    lastSeqNum = RemoteControl.sendData(masterID,(byte)START_MEASUREMENT_CMD, bytes) & 0xFF;
    		}
    		catch (Exception e){
    		    System.err.println("Sth's wrong with RemoteControl!!!");
    		    state = MT_STATE_IDLE;
    		    break;
    		}
    		System.out.println("startMeasurement: master "+masterID+", slave "+assistantID+", seqNum "+sequenceNumber);
    		if(++a2 >= senders.size()){
    			++a1;
    			a2 = a1+1;
	    	}
	    	try{
	    	    sleep(measurementSleepTime);
	    	}
	    	catch (Exception e){
	    	};
        	moteSequenceNumber++;
	    	callback.measurementEnded(masterID, sequenceNumber);
        	sequenceNumber++;
	    }
        System.out.println("Measurement finished!");
        state = MT_STATE_IDLE;
        return; 
    }    	    
	
	public void finish(){
		state = MT_STATE_IDLE;
	}
}
