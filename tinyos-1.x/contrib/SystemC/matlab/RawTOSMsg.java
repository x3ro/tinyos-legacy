// $Id: RawTOSMsg.java,v 1.2 2003/10/23 23:24:15 cssharp Exp $


/**
 */

//package net.tinyos.message;
import net.tinyos.message.*;

public class RawTOSMsg extends net.tinyos.message.TOSMsg
{
  /** Create a new TOSMsg of size 41. */
  public RawTOSMsg()
  {
    super(DEFAULT_MESSAGE_SIZE);
    amTypeSet(AM_TYPE);
  }

  /** Create a new RawTOSMsg of the given data_length. */
  public RawTOSMsg(int data_length)
  {
    super(data_length);
    amTypeSet(AM_TYPE);
  }

  /**
   * Create a new RawTOSMsg with the given data_length
   * and base offset.
   */
  public RawTOSMsg(int data_length, int base_offset)
  {
    super(data_length, base_offset);
    amTypeSet(AM_TYPE);
  }

  /**
   * Create a new RawTOSMsg using the given byte array
   * as backing store.
   */
  public RawTOSMsg(byte[] data)
  {
    super(data);
    amTypeSet(AM_TYPE);
  }

  /**
   * Create a new RawTOSMsg using the given byte array
   * as backing store, with the given base offset.
   */
  public RawTOSMsg(byte[] data, int base_offset)
  {
    super(data, base_offset);
    amTypeSet(AM_TYPE);
  }

  /**
   * Create a new RawTOSMsg using the given byte array
   * as backing store, with the given base offset and data length.
   */
  public RawTOSMsg(byte[] data, int base_offset, int data_length)
  {
    super(data, base_offset, data_length);
    amTypeSet(AM_TYPE);
  }

  /**
   * Create a new RawTOSMsg embedded in the given message
   * at the given base offset.
   */
  public RawTOSMsg(net.tinyos.message.Message msg, int base_offset)
  {
    super(msg, base_offset, DEFAULT_MESSAGE_SIZE);
    amTypeSet(AM_TYPE);
  }

  /**
   * Create a new RawTOSMsg embedded in the given message
   * at the given base offset and length.
   */
  public RawTOSMsg(net.tinyos.message.Message msg, int base_offset, int data_length)
  {
    super(msg, base_offset, data_length);
    amTypeSet(AM_TYPE);
  }



  // 
  // Cory wants to push values in a message.
  // He like it.
  // Maybe he'll add popping later, too.
  //

  protected void pushUIntElement( int length, long val )
  {
    int datalen = get_length();
    setUIntElement( offsetBits_data(datalen), length, val );
    set_length( (short)(datalen + (length/8)) );
  }

  protected void pushSIntElement( int length, long val )
  {
    int datalen = get_length();
    setSIntElement( offsetBits_data(datalen), length, val );
    set_length( (short)(datalen + (length/8)) );
  }

  protected void pushFloatElement( int length, float val )
  {
    int datalen = get_length();
    setFloatElement( offsetBits_data(datalen), length, val );
    set_length( (short)(datalen + (length/8)) );
  }

  public void push_uint8( long val ) { pushUIntElement( 8, val ); }
  public void push_uint16( long val ) { pushUIntElement( 16, val ); }
  public void push_uint32( long val ) { pushUIntElement( 32, val ); }
  public void push_int8( long val ) { pushSIntElement( 8, val ); }
  public void push_int16( long val ) { pushSIntElement( 16, val ); }
  public void push_int32( long val ) { pushSIntElement( 32, val ); }
  public void push_float( float val ) { pushFloatElement( 32, val ); }


  // 
  // As predicted (see above), Cory adds popping.
  //

  protected long popUIntElement( int length )
  {
    int datalen = get_length() - (length/8);
    long val = getUIntElement( offsetBits_data(datalen), length );
    set_length( (short)datalen );
    return val;
  }

  protected long popSIntElement( int length )
  {
    int datalen = get_length() - (length/8);
    long val = getSIntElement( offsetBits_data(datalen), length );
    set_length( (short)datalen );
    return val;
  }

  protected float popFloatElement( int length )
  {
    int datalen = get_length() - (length/8);
    float val = getFloatElement( offsetBits_data(datalen), length );
    set_length( (short)datalen );
    return val;
  }

  public short pop_uint8() { return (short)popUIntElement( 8 ); }
  public int pop_uint16() { return (int)popUIntElement( 16 ); }
  public long pop_uint32() { return (long)popUIntElement( 32 ); }
  public byte pop_int8() { return (byte)popSIntElement( 8 ); }
  public short pop_int16() { return (short)popSIntElement( 16 ); }
  public int pop_int32() { return (int)popSIntElement( 32 ); }
  public float pop_float() { return (float)popFloatElement( 32 ); }

  
  // 
  // Read values directly from the data region
  //

  public short read_uint8( int offset ) 
    { return (short)getUIntElement( offsetBits_data(offset), 8 ); }

  public int read_uint16( int offset ) 
    { return (int)getUIntElement( offsetBits_data(offset), 16 ); }

  public long read_uint32( int offset ) 
    { return (long)getUIntElement( offsetBits_data(offset), 32 ); }

  public byte read_int8( int offset ) 
    { return (byte)getSIntElement( offsetBits_data(offset), 8 ); }

  public short read_int16( int offset ) 
    { return (short)getSIntElement( offsetBits_data(offset), 16 ); }

  public int read_int32( int offset ) 
    { return (int)getSIntElement( offsetBits_data(offset), 32 ); }

  public float read_float( int offset ) 
    { return (float)getFloatElement( offsetBits_data(offset), 32 ); }

  public String read_string( int offset, int length ) 
    { return new String( get_data(), offset, length ); }
}

