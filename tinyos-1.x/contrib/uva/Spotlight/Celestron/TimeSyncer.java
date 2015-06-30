//$Header: /cvsroot/tinyos/tinyos-1.x/contrib/uva/Spotlight/Celestron/TimeSyncer.java,v 1.1.1.1 2005/05/10 23:37:06 rsto99 Exp $

/* "Copyright (c) 2000-2004 University of Virginia.  
 * All rights reserved.
 * 
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF VIRGINIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * VIRGINIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF VIRGINIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF VIRGINIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 */

// Author: Tian He
// Date: 3/26/2005

/*
 http://www.faqs.org/rfcs/rfc2030.html
 
 TimeSyncer Implementation is based on simplifed RFC 2030
 
 BaseMote is used as server. Pc is used as Client.
 
 Timestamp Name          ID   When Generated
 ------------------------------------------------------------
 pcSendTime     T1   time request sent by client
 moteRecvTime   T2   time request received by server
 moteSendTime   T3   time reply sent by server
 pcRecvTime     T4   time reply received by client
 
 The roundtrip delay d and local clock offset t are defined as
 
 d = (pcRecvTime - pcSendTime) - (moteSendTime - moteRecvTime)     t = ((T2 - T1) + (T3 - T4)) / 2.    
 
 */

/* to do list
 make sure one trip delay from mote to pc is equal to one trip delay from pc to motes.
 This is required to obtain high accuracy in time sychoronization
 */

import java.util.Date;
import java.io.*;
import javax.comm.*;
import javax.swing.Timer;
import java.awt.event.ActionEvent;
import java.awt.event.ActionListener;

public class TimeSyncer implements PacketListenerIF, TimeSyncIF,
SerialPortEventListener,ActionListener {	
	
	private final long RETRY_NUMBER = 100000;
	private long numRetry = RETRY_NUMBER;
	private short seqNo = 0;
	private SpotLightConnector Connector = null;
	private long startTimeInNaoSecond = 0;
	private long _moteRecvTime = 0;
	private long _moteSendTime = 0;		  
	private long _pcSendTime = 0;
	private long _pcRecvTime = 0;
	private long _pcRecvAtPortTime = 0;			  
	private long roundTripDelay = 0;		  
	private long TimeDiff,TimeDiffAtLowerLayer;
	private boolean synPending = false;
	private SerialPort serialPort;
	private packet.SerialByteSource ByteSerial = null; 
	private packet.Packetizer FramePacketizer = null; 		  
	private PrintStream Statistic = null;
	private long TransmissionTime = 0;
	private final long MODE = 1000000000;
	private double alpha = 0.1; //weight of moving average 
	
	Timer          SyncTimmer;
	long DateOffSet;
	long startTime;
	
	/* actual_pcSendTime = offset + _pcSendTime;  
	 *  This variable is used to fit 8 byte pc time into 4 bytes structure
	 */
	private long offset; 
	
	private boolean timeSynchronized = false;
	
	private short sync_count = 0;
	
	CommPortIdentifier portId;
	
	public TimeSyncer(SpotLightConnector c) {			  	  
		Connector = c;	  	
		Connector.registerPacketListener(this,SyncMsg.AM_TYPE);
		timeSynchronized = false;
		
		ByteSerial = c.getSerialByteSource();
		serialPort = ByteSerial.getSerialPort();
		FramePacketizer = c.getPacketizer();
		
		TransmissionTime = (SyncMsg.DEFAULT_MESSAGE_SIZE*10)*Constants.NANO/serialPort.getBaudRate();
		
		System.out.println("Serial port baudrate is "+ serialPort.getBaudRate());		
		
		try{		  	  
			ByteSerial.registerSerialEventListener(this);
		}
		catch (Exception e) {
			serialPort.close();
			System.out.println("Couldn't set listener");
		}	
		try{
			Statistic = new PrintStream(new FileOutputStream("stat.xls"));
			Statistic.println("pcTxTime\tmoteRxTime\tmoteTxTime\tpcRxPortTime\t_pcRxTime\tRT\tRT1\tTD\tTD1");          	  
		} catch (Exception e) {		
			System.out.println("Couldn't open statistic file");        	    	
		}         
		DateOffSet = (new Date()).getTime();
		startTime =	System.nanoTime();
		SyncTimmer = new javax.swing.Timer(2000,this);       						
		SyncTimmer.start();            	  
	}
	
	public void actionPerformed(ActionEvent e) {
		
		/* slow down after inital time sync */
		if(RETRY_NUMBER - numRetry > 5) SyncTimmer.setDelay(30000);
		
		synchronize(); 
		if(--numRetry == 0) SyncTimmer.stop();           
	} 	   
	
	/* send out sync message */          
	public void synchronize(){
		
		FramePacketizer.WriteSyncByte();
		
	}
	
	public void packetReceived(byte[] packet, int origin){
		
		switch(packet[Constants.PACKET_TYPE_FIELD]){
		case (byte)SyncMsg.AM_TYPE:
			
			/* get time diff betwen pc and mote */           	      	       
			_moteRecvTime = PacketParser.FourBytes(packet,SyncMsg.offset_moteRecvTime()+ Constants.macHeaderSize); 
		_moteSendTime = PacketParser.FourBytes(packet,SyncMsg.offset_moteSendTime()+ Constants.macHeaderSize); 
		_pcSendTime = FramePacketizer.getSendTime()/1000000;   
		_pcRecvTime = FramePacketizer.getRecvTime()/1000000;
		
		long CurrentRoundTripDelay = (_pcRecvTime - _pcSendTime) - (_moteSendTime - _moteRecvTime);								 
		long CurrentRoundTripDelayAtLowerLayer = (_pcRecvAtPortTime - _pcSendTime) - (_moteSendTime - _moteRecvTime);								 
		long CurrentTimeDiff =  ((_moteRecvTime - _pcSendTime) + (_moteSendTime - _pcRecvTime)) / 2;			 					 
		long CurrentTimeDiffAtLowerLayer =  ((_moteRecvTime - _pcSendTime) + (_moteSendTime - _pcRecvAtPortTime)) / 2;
		
		if(TimeDiff != 0){
			TimeDiff = (long)(((double)CurrentTimeDiff) * alpha  + ((double)TimeDiff) * (1 - alpha));  
			TimeDiffAtLowerLayer = (long)(((double)CurrentTimeDiffAtLowerLayer) * alpha  + ((double)TimeDiffAtLowerLayer) * (1 - alpha)); 
			roundTripDelay =  (long)(((double)CurrentRoundTripDelay) * alpha  + ((double)roundTripDelay) * (1 - alpha));   
		}else{
			TimeDiff = CurrentTimeDiff;
			TimeDiffAtLowerLayer = CurrentTimeDiffAtLowerLayer;
			roundTripDelay = CurrentRoundTripDelay;
		} 				
		
		sync_count++;                  	                       
		
		Statistic.println("["+sync_count+"]"+_pcSendTime+"\t"+_moteRecvTime+"\t"+
				_moteSendTime+"\t"+_pcRecvAtPortTime+"\t"+
				_pcRecvTime+"\t"+roundTripDelay+"\t"+roundTripDelay+"\t"+
				TimeDiff+"\t"+TimeDiffAtLowerLayer);
		
		System.out.println("RoundTrip:"+roundTripDelay + " TimeDiff is "
				+ TimeDiff +" MoteTime "+_moteSendTime+" PC Time "+ _pcRecvTime );        	       
		
		
		timeSynchronized = true;        	       
		}
	}
	
	public long Mote2PCTime(long moteTime){        	        
		return 	moteTime - TimeDiff + offset ;        
	}
	
	public long PC2MoteTime(long pcTime){        
		return 	pcTime + TimeDiff - offset;        
	}     
	
	public void serialEvent(SerialPortEvent ev) {
		
		int EventType = 	ev.getEventType();
		
		switch(EventType){
		case SerialPortEvent.BI: System.out.println("Break interrupt");break;
		case SerialPortEvent.CD: System.out.println("Carrier detect");break;    	
		case SerialPortEvent.CTS: System.out.println("Clear to send");break;
		case SerialPortEvent.DSR: System.out.println("Data set ready");break;    	    
		case SerialPortEvent.DATA_AVAILABLE: {
			if(synPending == true){
				synPending = false;
				_pcRecvAtPortTime = _pcSendTime + (System.nanoTime() - startTimeInNaoSecond)/1000000;			    		
			}
		}
		default: break;    		    	    	    	    	    	    	
		}
		
	}                            
}
