package tools;

import net.tinyos.message.*;

class Op extends FSOpMsg {
    static int maxData = MoteIF.maxMessageSize - DEFAULT_MESSAGE_SIZE;
    int offset;

    Op(int op) {
	super(maxData + DEFAULT_MESSAGE_SIZE);
	set_op((short)op);
	offset = 0;
    }

    Op argU8(int x) {
	if (offset >= maxData) {
	    System.err.println("message overflow");
	    System.exit(2);
	}
	setElement_data(offset++, (short)x);
	return this;
    }

    Op argU16(int x) {
	return argU8(x & 0xff).argU8((x >> 8) & 0xff);
    }

    Op argU32(long x) {
	return argU16((int)x & 0xffff).argU16((int)(x >> 16) & 0xffff);
    }

    Op argBoolean(boolean b) {
	return argU8(b ? 1 : 0);
    }

    Op argString(String s) { 
         int len = s.length();
         for (int i = 0; i < len; i++)
	     argU8(s.charAt(i));
	 argU8(0);
	 return this;
    }

    Op argBytes(byte[] buffer, int count) { 
	for (int i = 0; i < count; i++)
	     argU8(buffer[i]);
	 return this;
    }
}
