//$Header: /cvsroot/tinyos/tinyos-1.x/contrib/uva/Spotlight/Celestron/Localizer.java,v 1.1.1.1 2005/05/10 23:37:06 rsto99 Exp $

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

// Author: Radu Stoleru
// Date: 3/26/2005


import java.util.ArrayList;
import java.util.Date;
import java.util.List;
import java.util.Observable;

public class Localizer extends Observable implements PacketListenerIF {
	
	private List   nodesList = new ArrayList();
	private List   scanList  = new ArrayList();
	private EventGenerator handler = null; 
	private SpotLightConnector baseConnector;
	private CelestronConnector celestronConnector;
	private TimeSyncIF sync;
	//private int localizationState;
	private boolean getInitialPosition, getFinalPosition;
	
	private int horizontalScanDuration = 1000*Constants.FIELD_LENGTH/
	Constants.SCAN_SPEED; 
	private int verticalScanDuration = 1000*2*Constants.EVENT_RADIUS/
	Constants.SCAN_SPEED;
	private int numHorizontalPasses = (int) Math.ceil(Constants.FIELD_HEIGHT/
			(2.0*Constants.EVENT_RADIUS));
	private int numVerticalPasses = numHorizontalPasses - 1;
	
	// Celestron Messages
	private byte[] okMsg = {'T', 0x00};
	private byte[] trackOffMsg = {0x54, 0x00};
	
	private byte[] startAltPosTrackMsg = {0x50, 0x03, 0x11, 0x07, 
			(byte) 0x27, (byte) 0xA0, 0x00, 0x00};
	private byte[] startAltNegTrackMsg = {0x50, 0x03, 0x11, 0x06, 
			(byte) 0x27, (byte) 0xA0, 0x00, 0x00};
	private byte[] startAzPosTrackMsg = {0x50, 0x03, 0x10, 0x06, 
			(byte) 0x27, (byte) 0xA0, 0x00, 0x00};
	private byte[] startAzNegTrackMsg = {0x50, 0x03, 0x10, 0x07, 
			(byte) 0x27, (byte) 0xA0, 0x00, 0x00};		
	
	private byte[] stopAltTrackMsg = {0x50, 0x02, 0x11, 0x25, 
			0x00, 0x00, 0x00, 0x00};
	private byte[] stopAzTrackMsg = {0x50, 0x02, 0x10, 0x25, 
			0x00, 0x00, 0x00, 0x00};
	private byte[] getAltAzMsg = {'Z'};
	
	/********************************************************************/
	public void GoTo(int nodeID) {
		
		for(int i = 0; i < nodesList.size(); i++) {
			Node n = (Node) nodesList.get(i);
			
			if(nodeID == n.id) {
				
				char alt1 = Character.toUpperCase(Integer.
						toHexString(n.altRawValue & 0x000f).charAt(0));
				char alt2 = Character.toUpperCase(Integer.
						toHexString((n.altRawValue >> 4) & 0x000f).charAt(0));
				char alt3 = Character.toUpperCase(Integer.
						toHexString((n.altRawValue >> 8) & 0x000f).charAt(0));
				char alt4 = Character.toUpperCase(Integer.
						toHexString((n.altRawValue >> 12) & 0x000f).charAt(0));
				char az1 = Character.toUpperCase(Integer.
						toHexString(n.azRawValue & 0x000f).charAt(0));
				char az2 = Character.toUpperCase(Integer.
						toHexString((n.azRawValue >> 4) & 0x000f).charAt(0));
				char az3 = Character.toUpperCase(Integer.
						toHexString((n.azRawValue >> 8) & 0x000f).charAt(0));
				char az4 = Character.toUpperCase(Integer.
						toHexString((n.azRawValue >> 12) & 0x000f).charAt(0));
				
				
				byte[] targetPointCmd = {'B', (byte) az4, (byte)az3, (byte)az2 , 
						(byte)az1, ',', (byte)alt4, (byte)alt3, (byte)alt2, 
						(byte)alt1};
				
				System.out.println("SENDING GOTO COMMAND:");
				for(int j = 0; j < targetPointCmd.length; j++)
					System.out.print(" " + Integer.toHexString(targetPointCmd[j]));
				System.out.println("");
				celestronConnector.sendMessage(targetPointCmd);
			}
		}
		
	}
	
	/********************************************************************/
	public void connect() {
		baseConnector = new SpotLightConnector();
		baseConnector.registerPacketListener(this, ReportMsg.AM_TYPE);
		sync = new TimeSyncer(baseConnector);
		
		celestronConnector = new CelestronConnector();
		celestronConnector.registerPacketListener(this);
	}
	
	/********************************************************************/	
	public void disconnect() {
		baseConnector.disconnectSerial();
		celestronConnector.disconnectSerial();
	}
	
	/********************************************************************/
	public void stop() {
		celestronConnector.sendMessage(stopAzTrackMsg);
		if(handler != null && handler.isAlive())
			handler.stopRunning = true;
	}
	
	/********************************************************************/	
	public int getLocalizationDuration() {
		long beginTime = 0,  endTime = 0;
		
		if(scanList.size() > 0) {
			if(((Scan) scanList.get(0)).timeStampInitial > 0)
				beginTime = ((Scan) scanList.get(0)).timeStampInitial;
			
			Scan last = (Scan) scanList.get(scanList.size()-1);
			if(last.timeStampFinal > 0)
				endTime = last.timeStampFinal;
			else if(last.timeStampInitial > 0)
				endTime = last.timeStampInitial;
			else if(scanList.size() > 1){
				Scan beforeLast = (Scan) scanList.get(scanList.size()-2);
				endTime = beforeLast.timeStampFinal;
			}
		}
		
		return (int) ((endTime-beginTime)/Constants.MILI);
	}
	
	/********************************************************************/	
	public void configNodes(short delta, Byte detectionThreshold) {
		ConfigMsg msg = new ConfigMsg();
		msg.set_type(Constants.CONFIG_RECONFIG);
		//msg.set_samplingInterval(samplingInterval.byteValue());
		msg.set_samplingInterval(delta);
		msg.set_DetectionThreshold(detectionThreshold.byteValue());
		baseConnector.sendMessage(msg, (byte) ConfigMsg.AM_TYPE);
	}
	
	/********************************************************************/	
	public void queryNodes() {
		ConfigMsg msg = new ConfigMsg();
		msg.set_type(Constants.CONFIG_REQUEST);
		baseConnector.sendMessage(msg, (byte) ConfigMsg.AM_TYPE);		
	}
	
	/********************************************************************/
	private void storeNodes(short id) {
		ConfigMsg msg = new ConfigMsg();
		msg.set_type(Constants.CONFIG_STORE);
		msg.set_ScanID(id);		
		baseConnector.sendMessage(msg, (byte) ConfigMsg.AM_TYPE);
	}
	
	/********************************************************************/
	public void startLocalization(byte[] speedBytes) {
		
		if(handler == null || !handler.isAlive()) {
			
			startAltPosTrackMsg[4] = startAltNegTrackMsg[4] =
				startAzPosTrackMsg[4] = startAzNegTrackMsg[4] = speedBytes[0];
			
			startAltPosTrackMsg[5] = startAltNegTrackMsg[5] =
				startAzPosTrackMsg[5] = startAzNegTrackMsg[5] = speedBytes[1];
			
			// clear the current state
			nodesList.clear();
			scanList.clear();
			setChanged();
			
			// start the localization
			handler = new EventGenerator();
			handler.start();
		}
	}
	
	/********************************************************************/
	public void restartSystem() {
		ConfigMsg msg = new ConfigMsg();
		msg.set_type(Constants.CONFIG_RESTART);
		baseConnector.sendMessage(msg, (byte) ConfigMsg.AM_TYPE);
	}
	
	/********************************************************************/
	private void resetNodes() {
		ConfigMsg msg = new ConfigMsg();
		msg.set_type(Constants.CONFIG_INIT);
		baseConnector.sendMessage(msg, (byte) ConfigMsg.AM_TYPE);
	}
	
	/********************************************************************/
	private void ackReport(short id) {
		System.out.println("Acking report for: " + id);
		ReportAckMsg msg = new ReportAckMsg();
		msg.set_dest(id);
		baseConnector.sendMessage(msg, (byte) ReportAckMsg.AM_TYPE);
	}
	
	/********************************************************************/	
	public void packetReceived(byte[] packet, int origin) {
		long delay;
		
		if(origin == Constants.BASE) {
			processBasePacket(packet);
		} else if(origin == Constants.CELESTRON){
			processCelestronPacket(packet);
		}
		
		setChanged();
		notifyObservers(nodesList);

	}
	
	/********************************************************************/
	private void processBasePacket(byte[] packet) {
		
		switch(packet[Constants.PACKET_TYPE_FIELD]){
		case (byte) ReportMsg.AM_TYPE: {
			byte [] payload = new byte [ReportMsg.DEFAULT_MESSAGE_SIZE];
			
			System.arraycopy(packet, Constants.macHeaderSize, payload,
					0, ReportMsg.DEFAULT_MESSAGE_SIZE);
			
			ReportMsg  Msg    = new ReportMsg(payload);
			int moteID        = Msg.get_moteID();
			long[] timeStamp  = Msg.get_timeStamp();							
			short[] scanID    = Msg.get_ScanID();
			
			// debugging information
			for(int i = 0; i < timeStamp.length; i++) {			
				if(timeStamp[i] != 0)
					timeStamp[i] = sync.Mote2PCTime(timeStamp[i]); 
				System.out.println("Time Stamps with scan ID " + scanID[i] +
						" is " + timeStamp[i] + " from node=" + moteID);				
			}
			
			if(scanID[0] != 0) {	
				// look at all the scans
				for(int i = 0; i < scanList.size(); i++) {
					Scan scan = (Scan) scanList.get(i);
					
					// we found the inteval
					if((timeStamp[0] + Constants.BIAS) > scan.timeStampInitial &&
							(timeStamp[0] + Constants.BIAS) < scan.timeStampFinal) {
						
						Node n        = new Node();
						n.id          = moteID;
						n.altRawValue = scan.altInitial;
						n.azRawValue  = (int) (scan.azInitial + 1.0*
								(timeStamp[0] + Constants.BIAS - scan.timeStampInitial)/
								(scan.timeStampFinal-scan.timeStampInitial)*
								(scan.azFinal-scan.azInitial));;
								
								nodesList.add(n);
								
								break; // for() loop
					}
				}
			}
			
			ackReport((short) moteID);
			break;
		}
		
		default:
			System.out.println("Invalid Packet Type");
		}			
	}
	
	/********************************************************************/
	private void processCelestronPacket(byte[] packet) {
		
		if(getInitialPosition == true) {
			if(packet.length == 10) {
				Scan scan = (Scan) scanList.get(scanList.size() - 1); // get last element
				scan.azInitial = Integer.decode("0x" + 
						(new String(packet, 0, 4))).intValue();
				scan.altInitial = Integer.decode("0x" + 
						(new String(packet, 5, 4))).intValue();
			}
			getInitialPosition = false;
		} else if(getFinalPosition == true) {
			if(packet.length == 10) {
				Scan scan = (Scan) scanList.get(scanList.size()-1); // get last element
			
				scan.azFinal = Integer.decode("0x" + 
						(new String(packet, 0, 4))).intValue();
				scan.altFinal = Integer.decode("0x" + 
						(new String(packet, 5, 4))).intValue();
			}
			getFinalPosition = false;
		}				
	} 	
	
	class Scan {
		int azInitial;
		int azFinal;
		int altInitial;
		int altFinal;
		long timeStampInitial;
		long timeStampFinal;
		
		public Scan() {
			azInitial = azFinal = altInitial = altFinal = 0;
			timeStampInitial = timeStampFinal = 0;
		}
		
	}
	
	/********************************************************************/
	class EventGenerator extends Thread {
		
		boolean stopRunning;
		
		public void run() {
			
			long dateOffset     = (new Date()).getTime();
			long startTime      = System.nanoTime();
			
			for(int k = 0 ; k < Constants.DEFAULT_RETRANSMIT_NUMBER; k++) {
				resetNodes();					
				delay(Constants.DEFAULT_RETRANSMIT_DURATION);
			}
			
			for(int i = 0; i < numHorizontalPasses + numVerticalPasses &&
			stopRunning == false; i++) {
				
				Scan scan = new Scan();
				scanList.add(scan);
				
				System.out.println("          GET INITIAL POZITION         ");
				getInitialPosition = true;
				celestronConnector.sendMessage(getAltAzMsg);
				delay(100); // wait for the response from mount
				
				scan.timeStampInitial = dateOffset + (System.nanoTime() - 
						startTime)/1000000;
				
				System.out.println("          SCANNING         ");
				if(i%2 == 0) {
					if(i%4 == 0)
						celestronConnector.sendMessage(startAzPosTrackMsg);
					else
						celestronConnector.sendMessage(startAzNegTrackMsg);	
					delay(horizontalScanDuration);
				}
				else {
					celestronConnector.sendMessage(startAltNegTrackMsg);
					delay(verticalScanDuration);
				}
				
				if(stopRunning)
					return;
				
				System.out.println("          STOPPING         ");
				scan.timeStampFinal = dateOffset + (System.nanoTime() - 
						startTime)/1000000;
				
				if(i%2 == 0)
					celestronConnector.sendMessage(stopAzTrackMsg);
				else
					celestronConnector.sendMessage(stopAltTrackMsg);
				delay(1000); // it may take a while for the mount to stop
				
				
				System.out.println("          GET FINAL POZITION         ");			
				getFinalPosition = true;
				celestronConnector.sendMessage(getAltAzMsg);
				delay(100);
				
			}
			
			if(stopRunning)
				return;
			
			System.out.println("STORE at end of the scan " + 1);				
			for(int k = 0 ; k < Constants.DEFAULT_RETRANSMIT_NUMBER; k++) {     				
				storeNodes((short) 1);			
				delay(Constants.DEFAULT_RETRANSMIT_DURATION);
			}
			
			System.out.println("QUERY nodes");
			for(int k = 0 ; k < Constants.DEFAULT_RETRANSMIT_NUMBER; k++){  
				queryNodes();					
				delay(Constants.DEFAULT_RETRANSMIT_DURATION);
			}
			
		}
		
		private void delay(long duration) {
			try {
				Thread.sleep(duration);
			} catch (InterruptedException e) {
				e.printStackTrace();
			}			
		}		
	}
	
}
