package net.tinyos.tinydb;

import java.util.*;

public class SelOp {
    public static final byte OP_EQ = 0;
    public static final byte OP_NEQ = 1;
    public static final byte OP_GT = 2;
    public static final byte OP_GE = 3;
    public static final byte OP_LT = 4;
    public static final byte OP_LE = 5;
    
    public SelOp(byte type) throws NoSuchElementException  {
	if (type < OP_EQ || type > OP_LE)
	    throw new NoSuchElementException();
	this.type = type;
    }

    public byte toByte() {
	return type;
    }

    public String toString() {
	switch (type) {
	case OP_EQ:
	    return "=";
	case OP_NEQ:
	    return "!=";
	case OP_GT:
	    return ">";
	case OP_GE:
	    return ">=";
	case OP_LT:
	    return "<";
	case OP_LE:
	    return "<=";
	}
	return "";
    }

    private byte type;
}
