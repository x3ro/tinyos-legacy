package com.shockfish.tinyos.util;


public class Unsigned {



  public static int convertunsignedBytetoInt(byte data) {
    return (data & 0xff);
  }
  public static int convertunsignedBytestoInt(byte dataLow, byte dataHigh) {
    return ((dataLow&0xff) | ((dataHigh&0xff) <<8));
  }

  public static int convertunsignedShorttoInt (short data) {
  return (data & 0xffff);
}


  public static long convertunsignedBytestoInt(byte dataFirst, byte dataSecond, byte dataThird, byte dataFourth) {
   return ((dataFirst &0xff )| ((dataSecond&0xff) <<8) | ((dataThird&0xff) <<16) | ((dataFourth&0xff) <<24));
 }

 public static long convertUnsignedInttoLong (int data) {
   return (data & 0xffffffffl);
 }

 public static byte [] convertInttoUnsignedBytes (int data) {
   byte [] res = new byte[4];
   int temp=data;
   int i;
   for (i=0; i<res.length;i++) {
     res[i] = convertInttoUnsignedByte(temp);
     temp=temp>>8;
   }
   return res;
 }
 
 public static byte [] convertLongtoUnsignedBytes (long data) {
	   byte [] res = new byte[8];
	   long temp=data;
	   int i;
	   for (i=0; i<res.length;i++) {
		 
	     res[i] = convertLongtoUnsignedByte(temp);
	     temp=temp>>8;
	   }
	   return res;
	 }

 public static long convertunsignedBytestoLong(byte [] data) {
	 long result=0;
	 for (int i=0; i<data.length;i++) {
	     result=result |((long)(data[i]&0xff)<<i*8);
	   }
	   return result;
	 }

 public static void main(String args[]) throws Exception {
	 long essai=286423;
	 System.out.println("Nombre a convertir: "+essai);
	 byte [] data=Unsigned.convertLongtoUnsignedBytes(essai);
	 long resu=Unsigned.convertunsignedBytestoLong(data);
	 System.out.println("Nombre a converti: "+resu);
	 
 }
  public static byte convertInttoUnsignedByte(int data) {
    //byte temp= data && 0xff;
    return (byte) (data & 0xff);
  }
  
  public static byte convertLongtoUnsignedByte(long data) {
	    //byte temp= data && 0xff;
	    return (byte) (data & 0xff);
	  }

  public static short convertInttoUnsignedShort(int data) {
    //byte temp= data && 0xff;
    return (short) (data & 0xffff);
  }

  public static int convertLongtoUnsignedInt (long data) {
    return (int) (data & 0xffffffff);
  }


}
