package net.tinyos.tinydb;

import java.util.*;

/** Class representing a named field in a query */
public class QueryField implements Cloneable {
    private String name;
    private String table;
    private byte type;
    private short idx = -1;
    private byte op;

  public static final  byte INTONE = 1;
  public static final byte INTTWO = 3;
  public static final byte INTFOUR = 5;
  public static final byte STRING= 8;
  public static final byte TIMESTAMP = 7;
  public static final byte COMPLEX_TYPE = 9;
    public static final byte UINTONE = 2;
    public static final byte UINTTWO = 4;
    public static final byte UINTFOUR = 6;

    
  public QueryField(String field, byte fieldType) throws NoSuchElementException {
      if (field.indexOf(".") != -1) {
	  table = field.substring(0, field.indexOf("."));
	  name = field.substring(field.indexOf(".")+1);
      } else {
	  name = field;
	  table = null;
      }
    if (fieldType < INTONE || fieldType > COMPLEX_TYPE)
      throw new NoSuchElementException();
    type = fieldType;
    op = AggOp.AGG_NOOP;
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
    
    public byte getOp() {
	return op;
    }

    public void setOp(byte op) {
	this.op = op;
    }
  
    public String toString() {
	if (op != AggOp.AGG_NOOP) {
	    try {
		return getName() + " OP = " + new AggOp(op).toString();
	    } catch (NoSuchElementException e) {
		return getName();
	    }
	}
	else return getName();
    }

    public QueryField copy() {
	try {
	    return (QueryField)this.clone();
	} catch (Exception e) {
	    return null;
	}
    }
  

}
