package net.tinyos.mgmtquery;

import java.util.*;

public class MgmtQueryResult {

  private ArrayList valueList = new ArrayList();
  private ArrayList byteValueList = new ArrayList();
  private int sourceAddr;
  private int sampleNumber;
  private int ttl;
  private int queryID;

  public MgmtQueryResult(int sourceAddr,
			 MgmtQuery q, MgmtQueryResponseMsg m,
			 int queryID) {

    int offset = 0;
    this.sourceAddr = sourceAddr;
    this.sampleNumber = m.get_seqno();

    for(Iterator keyIt = q.keyList().iterator(); keyIt.hasNext(); ) {
      MgmtAttr attr = (MgmtAttr)keyIt.next();

      ArrayList valueArray = new ArrayList(attr.length);
	
      /* 
	 how to parse more complex types? 
	 for now, we're just going to assume each value is an int...
       */
      try {
	for(int i = 0; i < attr.length; i++) {
	  Integer theByte = new Integer(m.getElement_data(offset + i));
	  valueArray.add(theByte);
	}
	offset += attr.fieldLength;
	byteValueList.add(valueArray);

      } catch (ArrayIndexOutOfBoundsException e) {
	break;
      }
    }
  }

  public int getSourceAddr() {
    return sourceAddr;
  }

  public int getSampleNumber() {
    return sampleNumber;
  }

  public int getQueryID() {
    return queryID;
  }

  public void setTTL(int ttl) {
    this.ttl = ttl;
  }

  public int getTTL() {
    return ttl;
  }

  public int getColumnCount() {
    return byteValueList.size();
  }

  public ArrayList getByteArray(int columnIndex) {
    return (ArrayList) byteValueList.get(columnIndex);
  }

  public int getInt(int columnIndex) {
    return getUIntElement((ArrayList)byteValueList.get(columnIndex));
  }

  public String getString(int columnIndex) {
    ArrayList theValue = (ArrayList)byteValueList.get(columnIndex);
    char[] theString = new char[theValue.size()];
    int j = 0;
    for(int i = 0; i < theValue.size(); i++) {
      char theChar = (char) ubyte(((Integer)theValue.get(i)).intValue());
      if (theChar != 0) {
	theString[j] = theChar;
	j++;
      }
    }
    return new String(theString).substring(0,j);
  }

  public String getOctetString(int columnIndex) {
    String ret = ""; 
    ArrayList theValue = (ArrayList)byteValueList.get(columnIndex);    
    
    for(int i = 0; i < theValue.size(); i++) {
      ret += toByteString(ubyte(((Integer)theValue.get(i)).intValue()));
      if (i < theValue.size()-1)
	ret += ":";
    }    
    return ret;
  }

  public String getBitString(int columnIndex) {
    String ret = ""; 
    ArrayList theValue = (ArrayList)byteValueList.get(columnIndex);
    for(int i = 0; i < theValue.size(); i++) {
      String bits = Integer.toBinaryString(ubyte(((Integer)theValue.get(i)).intValue()));
      for (int j = 8; j > bits.length(); j--) {
	ret += "0";
      }
      ret += bits;
      if (i < theValue.size()-1)
	ret += " ";
    }
    return ret;
  }

  public String toByteString(int b) {
    String bs = "";
    if (b >= 0 && b < 16) {
      bs += "0";
    }
    bs += Integer.toHexString(b & 0xff).toUpperCase();
    return bs;
  }

  public ArrayList getValues() {
    return valueList;
  }

  public ArrayList getByteValues() {
    return byteValueList;
  }

  public String toString() {
    String ret = "";
    
    ret += sourceAddr + "\t";
    ret += sampleNumber + "\t";
    for(Iterator it = valueList.iterator(); it.hasNext(); ) {
      Integer value = (Integer) it.next();
//      ret += "0x" + Integer.toHexString(value.intValue()) + "\t";
      ret += "" + value + "\t";
    }
    return ret;
  }

  private int ubyte(int val) {
    if (val < 0) return val + 256;
    else return val;
  }

  protected int getUIntElement(ArrayList arr) {
    int length = arr.size() * 8;
    int byteOffset = 0;
    int shift = 0;
    int val = 0;
    int theByte;

    while (length >= 8) {
      theByte = (int)ubyte(((Integer)arr.get(byteOffset++)).intValue());
      val |= theByte << shift;
      shift += 8;
      length -= 8;
    }
    return val;
  }
}
