//$Header: /cvsroot/tinyos/tinyos-1.x/contrib/uva/Spotlight/Celestron/SpotLightConnector.java,v 1.1.1.1 2005/05/10 23:37:06 rsto99 Exp $

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

// Author: Ting Yan, Tian He, Radu Stoleru
// Date: 3/26/2005


import java.io.*;
import net.tinyos.message.*;

public class SpotLightConnector  {
	
	private net.tinyos.packet.PacketSource serialStub = null;
	private PacketReader packetReader                 = null;
	private java.util.HashMap messageIdRegisterMap = new java.util.HashMap();
	private packet.SerialByteSource ByteSerial        = null;	
	BufferedWriter bwout                              = null;
	
	public SpotLightConnector(){		
		connectSerial();
	}
		
	// print a byte value in Hex
	private void PrintHexByte(byte b) {
		int i = (int) b;
		i = (i >= 0) ? i : (i + 256);
		System.out.print(Integer.toHexString(i / 16));
		System.out.print(Integer.toHexString(i % 16));
	}
	
	/* send out a string of bytes of certain length */ 
	public void sendMessage(Message m, byte MessageID ){
		
		byte[] content = m.dataGet();
		
		byte[] full_packet = new byte[m.dataLength() + Constants.macHeaderSize];

		full_packet[0] = Constants.DEST_ADDR % 0xff;
		full_packet[1] = (Constants.DEST_ADDR >> 8) % 0xff;     
		full_packet[2] = MessageID;  
		full_packet[3] = Constants.GROUP_ID;            
		full_packet[Constants.LENGTH_OFFSET] = (byte)m.dataLength();
		
		for (int i = 0; i < m.dataLength(); i++) {
			full_packet[Constants.macHeaderSize+i] = content[i];
		}
			
		try {
			if (serialStub != null) {
				serialStub.writePacket(full_packet);
			}
		}
		catch (Exception e) {
			e.printStackTrace();
		}
	
	}

	void connectSerial() {
		try {
			packet.BuildSource Builder = new packet.BuildSource();
			
			serialStub = Builder.makePacketSource(Constants.BASE_COM_PORT);
			serialStub.open(net.tinyos.util.PrintStreamMessenger.err);
			
			ByteSerial = Builder.getSerialByteSource();		
			
			packetReader = new SpotLightConnector.PacketReader();
			packetReader.start();
			
		}
		catch (Exception e) {
			e.printStackTrace();
			System.exit(1);
		}
		
	}
	
	public packet.SerialByteSource getSerialByteSource(){	
		return ByteSerial;	
	}
	
	public packet.Packetizer getPacketizer(){
		if( serialStub instanceof packet.Packetizer)
			return (packet.Packetizer)serialStub;
		else
			return null;
	}
	
	void disconnectSerial() {
		try {
			packetReader.stopRun();
			serialStub.close();
		}
		catch (Exception e) {
			e.printStackTrace();
		}
	}
	

	protected class PacketReader
	extends Thread {
		boolean run = true;
		byte[] packet = null;
		
		public void stopRun() {
			run = false;
		}
		
		public void run() {
			try {
				while (run) {
					packet = serialStub.readPacket();
					System.out.print("[In ]");
					for (int k = 0; k < packet.length; k++) {
						PrintHexByte(packet[k]);
						System.out.print(" ");
					}
					System.out.println();
					
					java.util.HashSet toNotify = new java.util.HashSet();
					
					if(messageIdRegisterMap.containsKey(new Integer(packet[Constants.PACKET_TYPE_FIELD]))) {
						toNotify.addAll((java.util.HashSet)messageIdRegisterMap.get(new Integer(packet[Constants.PACKET_TYPE_FIELD])));
					}
					
					java.util.Iterator notifyListIterator = toNotify.iterator();
					
					while(notifyListIterator.hasNext()){
						((PacketListenerIF)notifyListIterator.next()).
						packetReceived(packet, Constants.BASE);
					}
					
				}                    
			}
			catch (Exception e) {
				e.printStackTrace();
				System.out.println("Thread crashed " + e.toString());
			}
		}
	}
	
	public void registerPacketListener(PacketListenerIF packetListener, 
			int messageID) {
		
		java.util.HashSet listenerList;
		
		if(messageIdRegisterMap.containsKey(new Integer(messageID))) {
			listenerList = (java.util.HashSet) this.messageIdRegisterMap.get(new Integer(messageID));
		} else {
			listenerList = new java.util.HashSet();
			this.messageIdRegisterMap.put(new Integer(messageID), listenerList);
		}
		
		listenerList.add(packetListener);
		
	}
	
}
