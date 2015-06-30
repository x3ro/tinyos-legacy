package com.shockfish.tinyos.gateway;

/**
 * @author Karl Baumgartner, HEIG-VD
 */

import java.util.Vector;
import com.shockfish.tinyos.tools.CldcLogger;



public class TOSBuffer {
	
	private class ByteArray {
		private byte [] data;
		public ByteArray (byte [] data) {
			this.data=data;
		}
		public byte [] getBytes () {
			return data;
		}
	}

  public final static int BUFCAP = 20;
  private Vector vector;
  
	public TOSBuffer () {
		vector=new Vector(BUFCAP);
	}
	
	public void close() {
		vector=null;
	}
	
	public void addElement (byte [] data) { 

		if (vector.size()>=BUFCAP) {
			CldcLogger.severe("Record dropped, TOSBuffer capacity reached, TOSBuf.size="+vector.size());
			return;
		}
		
    vector.addElement(new ByteArray(data));
	}
	
	public byte [] getElement (int index_Element) {
		ByteArray byteArray=(ByteArray) vector.elementAt(index_Element);
		return byteArray.getBytes();
	}
	
	public void deleteRecord (int index) {
	  vector.removeElementAt(index);
	}
	
	public void empty () {
		vector.removeAllElements();		
	}
	
	public int size () {
		return vector.size();
	}
	
}
