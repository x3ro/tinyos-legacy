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

import net.tinyos.mcenter.RemoteControl;
import net.tinyos.mcenter.SerialConnector;
import net.tinyos.packet.PacketListenerIF;

/**
 * @author brano
 *
 */
public class MoteQueryLogic implements PacketListenerIF{

	private static int SEND_CHANNELS_CMD = 0x10;
	private static int SEND_MOTE_PARAMS_CMD = 0x11;
    static final int PACKET_TYPE = 2;    
    static final int PACKET_LENGTH_BYTE = 4;
	static final int PACKET_DATA = 5;
	static final int PACKET_ROUTING_TYPE = 5;
	
	private int queryId = 0;
	private MotesTableModel motesTableModel = null;

	public MoteQueryLogic(MotesTableModel motesTableModel){
		this.motesTableModel = motesTableModel;
		SerialConnector.instance().registerPacketListener(this,0x82 );
	}
	
	public void doQuery(){
		queryId = RemoteControl.sendInteger(0xFFFF,(byte)0x21, 0x10) & 0xFF;
	}
	
	public void sendChannels(int channels[]){
    	byte[] bytes = new byte[RipsDataTableModel.NUM_CHANNELS];
    	System.out.print("Data stream:");
    	for (int i=0; i<RipsDataTableModel.NUM_CHANNELS; i++){
    		bytes[i] = (byte)(channels[i] & 0xFF);
    		System.out.print(" "+bytes[i]);
    	}
	    queryId = RemoteControl.sendData(0xFFFF,(byte)SEND_CHANNELS_CMD, bytes) & 0xFF;

	    System.out.println(" sent!");
	}
	
	public void sendMoteParams(MoteParams moteParams){
    	byte[] bytes = new byte[16];
    	bytes[0] = (byte)(moteParams.masterPower & 0xFF);
    	bytes[1] = (byte)(moteParams.assistPower & 0xFF);
    	bytes[2] = (byte)(moteParams.algorithmType & 0xFF);
        bytes[3] = (byte)(moteParams.interferenceFreq & 0xFF);
        bytes[4] = (byte)((moteParams.interferenceFreq>>8) & 0xFF);
        bytes[5] = (byte)(moteParams.tsNumHops & 0xFF);
        bytes[6] = (byte)(moteParams.channelA & 0xFF);
        bytes[7] = (byte)(moteParams.channelB & 0xFF);
        bytes[8] = (byte)(moteParams.initialTuning & 0xFF); 
        bytes[9] = (byte)((moteParams.initialTuning>>8) & 0xFF); 
        bytes[10]= (byte)(moteParams.tuningOffset & 0xFF); 
        bytes[11]= (byte)(moteParams.numTuneHops & 0xFF);
        bytes[12]= (byte)(moteParams.numVees & 0xFF);
        bytes[13]= (byte)(moteParams.numChanHops & 0xFF);
        bytes[14]= (byte)(moteParams.initialChannel & 0xFF);//initial channel: moteParams.initialChannel 
        bytes[15]= (byte)(moteParams.channelOffset & 0xFF);//channel offset: moteParams.channelOffset 
	    queryId = RemoteControl.sendData(0xFFFF,(byte)SEND_MOTE_PARAMS_CMD, bytes) & 0xFF;
	    System.out.print("Data stream:");
	    for (int i=0; i<bytes.length; i++)
	    	System.out.print(" "+(bytes[i]&0xff));
	    System.out.println(" sent with remCtlID "+queryId+"!");
	}
	
	public void packetReceived(byte[] packet) {
		if( (packet[PACKET_TYPE] & 0xFF) == 130 )
			sliceFloodRoutingMsg(packet);
	}
	
	private void sliceFloodRoutingMsg(byte[] packet)
	{
		int headerLength = 3;
		int totalLength = 8;
		int dataLength = totalLength - headerLength;
		int packetLength = packet[PACKET_LENGTH_BYTE] & 0xFF;

		byte[] slice = new byte[PACKET_DATA + headerLength + dataLength];
				
		if ((packetLength-headerLength) % dataLength != 0)
			return;

		for(int i = headerLength; i < packetLength; i += dataLength)
		{
			slice[PACKET_LENGTH_BYTE] = (byte)(headerLength + dataLength);
			System.arraycopy(packet, PACKET_DATA, slice, PACKET_DATA, headerLength);
			System.arraycopy(packet, PACKET_DATA + i, slice, PACKET_DATA + headerLength, dataLength);
			if( (packet[PACKET_DATA+0]&0xFF) == 0x5e){
    			int nodeId = (packet[PACKET_DATA+3]&0xFF) + (packet[PACKET_DATA+4]&0xFF) * 256;
    			int seqNum = packet[PACKET_DATA+5]&0xFF;
    			
    			if(seqNum == (queryId&0xFF)){
    				LocalizationData.Sensor newMote = new LocalizationData.Sensor(nodeId, queryId, 0,0,0,false,false);
    				motesTableModel.addNewMote(newMote);
    			}	
			}
		}
	}
	
}
