package net.tinyos.social;

import java.io.*;

// Why on earth isn't there something like this already ?
// (there probably is, but where ?)

class ParseStream implements DataInput {

    InputStream in;
    boolean pushbackValid = false;
    int pushback;

    public ParseStream(InputStream s)
    {
	in = s;
    }

    public void readFully(byte[] b) throws IOException
    {
	readFully(b, 0, b.length);
    }

    public void readFully(byte[] b, int off, int len) throws IOException
    {
	if (in.read(b, off, len) != len)
	    throw new EOFException();
    }

    public int skipBytes(int n) throws IOException
    {
	return (int)in.skip(n);
    }

    public boolean readBoolean() throws IOException
    {
	String word = readWord();

	if (word.equalsIgnoreCase("true"))
	    return true;
	else if (word.equalsIgnoreCase("false"))
	    return false;

	badToken();
	return false;
    }

    public byte readByte() throws IOException
    {
	return (byte)readNumber(-128, 127);
    }

    public int readUnsignedByte() throws IOException
    {
	return (int)readNumber(0, 255);
    }

    public short readShort() throws IOException
    {
	return (short)readNumber(-32768, 32767);
    }

    public int readUnsignedShort() throws IOException
    {
	return (int)readNumber(0, 65535);
    }

    public char readChar() throws IOException
    {
	throw new IOException("unclear what this should do");
    }

    public int readInt() throws IOException
    {
	return (int)readNumber(java.lang.Integer.MIN_VALUE,
			       java.lang.Integer.MAX_VALUE);
    }

    public long readLong() throws IOException
    {
	return readNumber(java.lang.Long.MIN_VALUE,
			  java.lang.Long.MAX_VALUE);
    }

    public float readFloat() throws IOException
    {
	return (float)readDouble();
    }

    public double readDouble() throws IOException
    {
	try {
	    return new Double(readWord()).doubleValue();
	}
	catch (NumberFormatException e) {
	    badToken();
	}
	return 0;
    }

    public long readNumber(long min, long max) throws IOException
    {
	try {
	    long val = new Long(readWord()).longValue();

	    if (val >= min && val <= max)
		return val;
	    throw new IOException("value out of range");
	}
	catch (NumberFormatException e) {
	    badToken();
	}
	return 0;
    }

    public String readLine() throws IOException
    {
	StringBuffer s = new StringBuffer();
	int c;

	skipWhiteSpace(); // should we do this ?
	while ((c = readCharacter()) >= 0 && c != '\n') {
	    s.append((char)c);
	}

	return s.toString();
    }

    public String readUTF() throws IOException
    {
	throw new IOException("unimplemented");
    }

    public String readWord() throws IOException
    {
	StringBuffer s = new StringBuffer();
	int c;

	skipWhiteSpace();
	while (!isWhiteSpace(c = readCharacter())) {
	    s.append((char)c);
	}
	pushback(c);

	return s.toString();
    }

    public boolean skipWhiteSpace() throws IOException
    {
	int c;

	while (isWhiteSpace(c = readCharacter()) && c >= 0) ;
	pushback(c);

	return c < 0;
    }

    protected boolean isWhiteSpace(int c) {
	return c < 0 || c == ' ' || c == '\n' || c == '\r' || c == '\t';
    }

    protected int readCharacter() throws IOException
    {
	if (pushbackValid) {
	    pushbackValid = false;
	    return pushback;
	}
	return in.read();
    }

    protected void pushback(int c)
    {
	if (pushbackValid)
	    throw new RuntimeException("double pushback");
	if (c >= 0) { // ignore EOF 
	    pushbackValid = true;
	    pushback = c;
	}
    }

    protected void badToken() throws IOException
    {
	throw new IOException("bad token");
    }
}
