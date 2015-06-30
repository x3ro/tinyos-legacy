	/*
 * Created on Apr 27, 2005
 *
 * TODO To change the template for this generated file go to
 * Window - Preferences - Java - Code Style - Code Templates
 */
package net.tinyos.mcenter;

import net.tinyos.message.TOSMsg;

/**
 * @author nadand
 *
 * TODO To change the template for this generated type comment go to
 * Window - Preferences - Java - Code Style - Code Templates
 */
public class UniversalInterpreter implements MessageInterpreter{
	
	
	
	private int dataOffset;
	private int maxDataLength;
	private int headerLength;
	
	private int addressPosition;
	private int lengthPosition;
	private int typePosition;
	private int groupPosition;
	
	public static final int MICA2 = 0;
	public static final int ZIGBEE = 1;
	
	public static final int DEFAULT_SIZE = 29;
	
	public UniversalInterpreter(UniversalInterpreter refernceUI){
		addressPosition = refernceUI.addressPosition;
		typePosition = refernceUI.typePosition;
		groupPosition = refernceUI.groupPosition;
		
		
		lengthPosition = refernceUI.lengthPosition;
		dataOffset = refernceUI.dataOffset;
		headerLength = refernceUI.headerLength;
		maxDataLength = refernceUI.maxDataLength; 
	}
	
	public UniversalInterpreter( TOSMsg refernceMessage){
	
		//addressPosition = refernceMessage.offset_addr();
		//typePosition = refernceMessage.offset_type();
		//groupPosition = refernceMessage.offset_group();
		//Hack: The referenceMsg has to be a array of the byte numbers 
		addressPosition = refernceMessage.get_addr() & 0xFF;
		typePosition = refernceMessage.get_type();
		groupPosition = refernceMessage.get_group();
		
		
		lengthPosition = refernceMessage.offset_length();
		dataOffset = refernceMessage.offset_data(0);
		headerLength = refernceMessage.offset_data(0);
		maxDataLength = refernceMessage.totalSize_data();
	}
	
	public UniversalInterpreter( int default_type){
		this(default_type, DEFAULT_SIZE);
	}
	
	public UniversalInterpreter( int default_type, int max_length){
		
			//addressPosition = refernceMessage.offset_addr();
			//typePosition = refernceMessage.offset_type();
			//groupPosition = refernceMessage.offset_group();
			//Hack: The referenceMsg has to be a array of the byte numbers
		switch(default_type){
			
			case ZIGBEE :{
				addressPosition = 0;
				typePosition = 2;
				groupPosition = 3;
				
				
				lengthPosition = 4;
				dataOffset = 5;
				headerLength = 5;
				maxDataLength = max_length;
				break;
			}
			case MICA2 :{
				
			}
			default:{
				addressPosition = 6;
				typePosition = 8;
				groupPosition = 9;
				
				
				lengthPosition = 0;
				dataOffset = 10;
				headerLength = 10;
				maxDataLength = max_length;
			}
		}		
	}
	
	
	/* (non-Javadoc)
	 * @see net.tinyos.mcenter.MessageInterpreter#getData(byte[])
	 */
	public byte[] getData(byte[] message) {
		byte[] data = new byte[getDataLength(message)];
		System.arraycopy(message,dataOffset,data,0,getDataLength(message));

		return data;
	}
	/* (non-Javadoc)
	 * @see net.tinyos.mcenter.MessageInterpreter#getDataStart(byte[])
	 */
	public int getDataStart(byte[] message) {
		return dataOffset;
	}
	/* (non-Javadoc)
	 * @see net.tinyos.mcenter.MessageInterpreter#getDataLength(byte[])
	 */
	public int getDataLength(byte[] message) {
		return message[lengthPosition] & 0xFF;
	}
	/* (non-Javadoc)
	 * @see net.tinyos.mcenter.MessageInterpreter#getDataLengthPosition(byte[])
	 */
	public int getDataLengthPosition(byte[] message) {
		return lengthPosition;
	}
	/* (non-Javadoc)
	 * @see net.tinyos.mcenter.MessageInterpreter#getHeader(byte[])
	 */
	public byte[] getHeader(byte[] message) {
		byte[] header = new byte[headerLength];
		System.arraycopy(message,0,header,0,headerLength);
		return header;
	}
	/* (non-Javadoc)
	 * @see net.tinyos.mcenter.MessageInterpreter#getAddress(byte[])
	 */
	public int getAddress(byte[] message) {
		return message[addressPosition] & 0xFF | ((message[addressPosition+1] & 0xFF) << 8);
		
	}
	/* (non-Javadoc)
	 * @see net.tinyos.mcenter.MessageInterpreter#getAddressStart(byte[])
	 */
	public int getAddressStart(byte[] message) {
		return addressPosition;
	}
	
	/* (non-Javadoc)
	 * @see net.tinyos.mcenter.MessageInterpreter#getGroup(byte[])
	 */
	public int getGroup(byte[] message) {
		return message[groupPosition] & 0xFF;
	}
	/* (non-Javadoc)
	 * @see net.tinyos.mcenter.MessageInterpreter#getGroupPosition(byte[])
	 */
	public int getGroupPosition(byte[] message) {
		return groupPosition;
	}
	/* (non-Javadoc)
	 * @see net.tinyos.mcenter.MessageInterpreter#getType(byte[])
	 */
	public int getType(byte[] message) {
		return message[typePosition] & 0xFF;
	}
	/* (non-Javadoc)
	 * @see net.tinyos.mcenter.MessageInterpreter#getTypePosition(byte[])
	 */
	public int getTypePosition(byte[] message) {
		return typePosition;
	}
	/* (non-Javadoc)
	 * @see net.tinyos.mcenter.MessageInterpreter#isValidMessage(byte[])
	 */
	public boolean isValidMessage(byte[] message) {
		if(message.length >= headerLength){
			return (message.length > (headerLength + message[lengthPosition] & 0xFF));
			
		}else{
			return false;
		}
	}
	
	public String toString(){
		
		return"dataOffset \tmaxDataLength \theaderLength \taddressPosition \tlengthPosition \ttypePosition \tgroupPosition\n"
			  + dataOffset+" \t"+maxDataLength+" \t"+headerLength+" \t"+addressPosition+" \t"+lengthPosition+" \t"+typePosition+" \t"+groupPosition+"\n";

		
	}
	
	
	
	
}
