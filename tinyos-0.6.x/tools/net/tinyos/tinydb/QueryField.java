package net.tinyos.tinydb;

import java.util.*;

/** Class representing a named field in a query */
public class QueryField {
  private String name;
  private byte type;
    private short idx = -1;
  
  public static final  byte INTONE = 0;
  public static final byte INTTWO = 1;
  public static final byte INTFOUR = 2;
  public static final byte STRING= 3;
  public static final byte TIMESTAMP = 4;
  public static final byte COMPLEX_TYPE = 5;
  
  public QueryField(String field, byte fieldType) throws NoSuchElementException {
    this.name = field;
    if (fieldType < INTONE || fieldType > COMPLEX_TYPE)
      throw new NoSuchElementException();
    type = fieldType;
  }

    public short getIdx() {
	return idx;
    }

    public void setIdx(short idx) {
	this.idx = idx;
    }
  
  public String getName() {
    return name;
  }
  
  public byte getType() {
    return type;
  }
  
    public String toString() {
	return getName();
    }
  

}
