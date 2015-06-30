package net.tinyos.nucleus;

import java.io.DataInputStream.*;
import java.io.*;

/** 
LEDataInputStream.java 
<p>

This class is an extension of the DataInputStream class that supports reading
values in "Little Endian" byte order, as well as Java's native
<a href=http://www.webopedia.com/TERM/B/big_endian.html>"Big Endian"</a>. 

<p>
Everything in Java binary format files is stored
 big-endian,
MSB(Most Significant Byte) first. This is sometimes called network order.
This is good news. This means if you use only Java, all files are done 
the same way on all platforms Mac, PC, Solaris, etc. You can freely exchange
binary data electronically over the Internet or on floppy without any concerns
about endianness. The problem problem comes when you must exchange data files
with some program not written in Java that uses little-endian order, most 
commonly C on the PC. Some platforms use big-endian order internally
(Mac, IBM 390); some use little-endian order (Intel). Java hides that internal
endianness from you. 
<p>
To support these input operations, for multi-byte values
we must read each byte individually and reorder them using 
Java's bit shift left operator <<. Don't worry if you do not understand 
how these functions work, you will not need to edit this file.
<p>
This code and description is adapted from  <a href=http://mindprod.com>Roedy 
Green's LEDataInputStream.java</a>, which
implements LEDataInputStream with wrapper methods, we extend
DataInputStream directly, and suffix all "Little Endian" methods
with the letters LE.
<p>

@author Roedy Green
@author Stephanie Weirich
@version 2.0
@see java.io.DataInputStream

*/

public class LEDataInputStream extends DataInputStream {

   /** Creates a LEDataInputStream and saves its argument, the input stream in, for later use.
    */
   public LEDataInputStream(InputStream in) {
      super(in);
      w = new byte[8];
   }
   /** work array for buffering input */
   private byte w[];

   // L I T T L E   E N D I A N   R E A D E R S
   // Little endian methods for multi-byte numeric types.
   // Big-endian do fine for single-byte types and strings.

   /**
    * like {@link DataInputStream#readShort } except little endian.
    */
   public final short readShortLE() throws IOException
   {
      readFully(w, 0, 2);
      return (short)(
      	       (w[1]&0xff) << 8 |
      	       (w[0]&0xff));
   }

   /**
    * like {@link DataInputStream#readUnsignedShort } except little endian.
    * Note, returns int even though it reads a short.
    */
   public final int readUnsignedShortLE() throws IOException
   {
      readFully(w, 0, 2);
      return (
      	(w[1]&0xff) << 8 |
      	(w[0]&0xff));
   }

   /**
   * like {@link DataInputStream#readChar} except little endian.
    */
   public final char readCharLE() throws IOException
   {
      readFully(w, 0, 2);
      return (char) (
   	      (w[1]&0xff) << 8 |
   	      (w[0]&0xff));
   }
   /**
    * like {@link DataInputStream#readInt} except little endian.
    */
   public final int readIntLE() throws IOException
   {
       readFully(w, 0, 4);
       return
       (w[3])      << 24 |
       (w[2]&0xff) << 16 |
       (w[1]&0xff) <<  8 |
       (w[0]&0xff);
   }

   /**
    * like {@link DataInputStream#readInt} except little endian.
    */
   public final long readUnsignedIntLE() throws IOException
   {
       readFully(w, 0, 4);
       return
       (long)(w[3]&0xff) << 24 |
       (long)(w[2]&0xff) << 16 |
       (long)(w[1]&0xff) <<  8 |
       (long)(w[0]&0xff);
   }


   /**
    * like {@link DataInputStream#readInt} except little endian.
    */
   public final long readUnsignedInt() throws IOException
   {
       readFully(w, 0, 4);
       return
       (long)(w[3]&0xff) << 0  |
       (long)(w[2]&0xff) << 8  |
       (long)(w[1]&0xff) << 16 |
       (long)(w[0]&0xff) << 24;
   }

   /**
   * like {@link DataInputStream#readLong } except little endian.
   */
   public final long readLongLE() throws IOException
   {
      readFully(w, 0, 8);
      return
          (long)(w[7])      << 56 |  /* long cast needed or shift done modulo 32 */
          (long)(w[6]&0xff) << 48 |
          (long)(w[5]&0xff) << 40 |
          (long)(w[4]&0xff) << 32 |
          (long)(w[3]&0xff) << 24 |
          (long)(w[2]&0xff) << 16 |
          (long)(w[1]&0xff) <<  8 |
          (long)(w[0]&0xff);
   }

   /**
    * like {@link DataInputStream#readFloat } except little endian.
    */
   public final float readFloatLE() throws IOException
   {
     return Float.intBitsToFloat(readIntLE());
   }
   /**
    * like {@link DataInputStream#readDouble } except little endian.
    */
   public final double readDoubleLE() throws IOException
   {
     return Double.longBitsToDouble(readLongLE());
   }

}















