/*
 * Created on Apr 27, 2005
 *
 * TODO To change the template for this generated file go to
 * Window - Preferences - Java - Code Style - Code Templates
 */
package net.tinyos.mcenter;

/**
 * @author nadand
 *
 * TODO To change the template for this generated type comment go to
 * Window - Preferences - Java - Code Style - Code Templates
 */
public interface MessageInterpreter {
	
	
	public byte[] getHeader(byte[] message);
	
	public byte[] getData(byte[] message);
	
	public int getDataStart(byte[] message);
	
	public int getDataLength(byte[] message);
	
	public int getDataLengthPosition(byte[] message);
		
	public int getAddress(byte[] message);
	
	public int getAddressStart(byte[] message);
		
	public int getType(byte[] message);
	
	public int getTypePosition(byte[] message);
	
	public int getGroup(byte[] message);
	
	public int getGroupPosition(byte[] message);
	
	public boolean isValidMessage(byte[] message);
}
