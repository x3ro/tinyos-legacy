package net.tinyos.tinydb;

public class ArithOps {
    static final short NO_OP = 0;
    static final short MULTIPLY = 1;
    static final short DIVIDE = 2;
    static final short ADD = 3 ;
    static final short SUBTRACT = 4;
    static final short MOD = 5;
    static final short SHIFT_RIGHT = 6;

    static short getOp(String opStr) {
	if (opStr.equals("*"))
	    return MULTIPLY;
	else if (opStr.equals("/"))
	    return DIVIDE;
	else if (opStr.equals("+"))
	    return ADD;
	else if (opStr.equals("-"))
	    return SUBTRACT;
	else if (opStr.equals("%"))
	    return MOD;
	else if (opStr.equals(">>"))
	    return SHIFT_RIGHT;
	else return NO_OP;
    }

    static String getStringValue(short op) {
	switch (op) {
	case NO_OP:
	    break;
	case MULTIPLY:
	    return "*";
	case DIVIDE:
	    return "/";
	case ADD:
	    return "+";
	case SUBTRACT:
	    return "-";
	case MOD:
	    return "%";
	case SHIFT_RIGHT:
	    return ">>";
	}
	return "";
    }
}
    
