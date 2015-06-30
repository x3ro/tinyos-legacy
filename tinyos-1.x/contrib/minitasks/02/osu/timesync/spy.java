/*
 * Copyright Ted Herman, 2003, All Rights Reserved.
 * To the user: Ted Herman does not and cannot warrant the
 * product, information, documentation, or software (including
 * any fixes and updates) included in this package or the
 * performance or results obtained by using this product,
 * information, documentation, or software. This product,
 * information, documentation, and software is provided
 * "as is". Ted Herman makes no warranties of any kind,
 * either express or implied, including but not limited to,
 * non infringement of third party rights, merchantability,
 * or fitness for a particular purpose with respect to the
 * product and the accompanying written materials. To the
 * extent you use or implement this product, information,
 * documentation, or software in your own setting, you do so
 * at your own risk. In no event will Ted Herman be liable
 * to you for any damages arising from your use or, your
 * inability to use this product, information, documentation,
 * or software, including any lost profits, lost savings,
 * or other incidental or consequential damages, even if
 * Ted Herman has been advised of the possibility of such
 * damages, or for any claim by another party. All product
 * names are trademarks or registered trademarks of their
 * respective holders. Any resemblance to real persons, living
 * or dead is purely coincidental. Contains no peanuts. Void
 * where prohibited. Batteries not included. Contents may
 * settle during shipment. Use only as directed. No other
 * warranty expressed or implied. Do not use while operating a
 * motor vehicle or heavy equipment. This is not an offer to
 * sell securities. Apply only to affected area. May be too
 * intense for some viewers. Do not stamp. Use other side
 * for additional listings. For recreational use only. Do
 * not disturb. All models over 18 years of age. If condition
 * persists, consult your physician. No user-serviceable parts
 * inside. Freshest if eaten before date on carton. Subject
 * to change without notice. Times approximate. Simulated
 * picture. Children under 12 must wear a helmet. May cause
 * oily discharge. Contents under pressure. Pay before pumping
 * after dark. Paba free. Please remain seated until the ride
 * has come to a complete stop. Breaking seal constitutes
 * acceptance of agreement. For off-road use only. As seen on
 * TV. One size fits all. Many suitcases look alike. Contains
 * a substantial amount of non-tobacco ingredients. Colors
 * may, in time, fade. Slippery when wet. Not affiliated with
 * the American Red Cross. Drop in any mailbox. Edited for
 * television. Keep cool; process promptly. Post office will
 * not deliver without postage. List was current at time of
 * printing. Not responsible for direct, indirect, incidental
 * or consequential damages resulting from any defect,
 * error or failure to perform. At participating locations
 * only. Not the Beatles. See label for sequence. Substantial
 * penalty for early withdrawal. Do not write below this
 * line. Falling rock. Lost ticket pays maximum rate. Your
 * canceled check is your receipt. Add toner. Avoid
 * contact with skin. Sanitized for your protection. Be
 * sure each item is properly endorsed. Sign here without
 * admitting guilt. Employees and their families are not
 * eligible. Beware of dog. Contestants have been briefed
 * on some questions before the show. You must be present
 * to win. No passes accepted for this engagement. Shading
 * within a garment may occur. Use only in a well-ventilated
 * area. Keep away from fire or flames. Replace with same
 * type. Approved for veterans. Booths for two or more. Check
 * if tax deductible. Some equipment shown is optional. No
 * Canadian coins. Not recommended for children. Prerecorded
 * for this time zone. Reproduction strictly prohibited. No
 * solicitors. No alcohol, dogs or horses. No anchovies
 * unless otherwise specified. Restaurant package, not for
 * resale. List at least two alternate dates. First pull up,
 * then pull down. Call before digging. Driver does not carry
 * cash. Some of the trademarks mentioned in this product
 * appear for identification purposes only. Objects in
 * mirror may be closer than they appear. Record additional
 * transactions on back of previous stub. Do not fold,
 * spindle or mutilate. No transfers issued until the bus
 * comes to a complete stop. Package sold by weight, not
 * volume. Your mileage may vary. Parental discretion is
 * advised. Warranty void if this seal is broken. Employees
 * do not know combination to safe. Do not expose to rain
 * or moisture. To prevent fire hazard, do not exceed listed
 * wattage. Do not use with any other power source. May cause
 * radio and television interference. Consult your doctor
 * before starting this, or any other program. Drain fully
 * before recharging.
 */

import java.util.*;
import java.io.*;
import java.net.*;

public class spy {

   public static final String[] hex = 
           {"0", "1", "2", "3", "4", "5", "6", "7", "8", 
	    "9", "A", "B", "C", "D", "E", "F"};

   private static int MSG_SIZE = 25;  
   // 2 address bytes, 1 byte for AM type, 1 byte for group, 
   // 1 byte for length, 20 or so msg bytes
    
   String strAddr;
   int nPort;
   Socket socket;
   InputStream in;
   OutputStream out;

   public spy() {
     this.nPort = 9000;
     this.strAddr = "127.0.0.1";
     }

   public int unsig(byte b) {
     int r;
     r = (0x7f & b);
     if ((0x80 & b) != 0) r += 128;
     return r;
     }

   public void display(byte packet[]) {
     int gpstime; 
     int motetime; 
     int sendId;
     int rootId;
     // compute GPS time
     gpstime = unsig(packet[13]);
     gpstime += 256 * unsig(packet[14]);
     gpstime += (256*256) * unsig(packet[15]);
     gpstime += (256*256*256) * unsig(packet[16]);
     motetime = unsig(packet[9]);
     motetime += 256 * unsig(packet[10]);
     motetime += (256*256) * unsig(packet[11]);
     motetime += (256*256*256) * unsig(packet[12]);
     rootId = unsig(packet[5]) + 256*unsig(packet[6]);
     sendId = unsig(packet[7]) + 256*unsig(packet[8]);
     System.out.print("Beacon from Mote " + sendId + " has root id " + rootId);
     System.out.print(" Nbrhood = " + unsig(packet[17]));
     System.out.print(" hopDist = " + unsig(packet[18]));
     System.out.print(" clock = " + (motetime / 32768) + ":" 
     				+ (motetime % 32768));
     if (gpstime != 0) System.out.print(" GPS time = " +
		(gpstime / 32768) + ":" + (gpstime % 32768));
     System.out.print("\n");
     }

  public static String toHex(int i) {
    int q = i/16;
    int r = i % 16;
    return (hex[q] + hex[r]);
    }

  public static String toHex(byte[] bytes) {
    return toHex(bytes, bytes.length);
    }

  public static String toHex(byte[] bytes, int length) {
    String result ="";
    for (int i = 0; i < length; i++) {
      byte b = bytes[i];
      int h = ((b & 0xf0) >> 4);
      int l = (b & 0x0f);
      result += hex[h] + hex[l] + " ";
      }
    return result;
    }

   public boolean open() {
    try {
        System.out.println 
	   ("Connecting to host " + strAddr + ":" + nPort + "\n");
        socket = new Socket (strAddr, nPort);
        in = socket.getInputStream();
        out = socket.getOutputStream();
        } catch ( IOException e ) {
        System.out.println ("Unable to connect to host\n");
        return false;
        }

    return true;
    }

   public void read() throws IOException {
      int i;
      int count = 0;
      byte[] packet = new byte[MSG_SIZE];

      while ((i = in.read()) != -1) {
         if (i == 0x7e || count != 0) {
    	     packet[count] = (byte) i;
    	     count++;
	     if (count == MSG_SIZE) { display(packet); count = 0; }
	     }
	 // else System.out.println("extra byte " + toHex(i));
         }
      }

   public static void main(String args[]) {

      boolean bSuccess = false;
      System.out.println("*** spy started ***");
      spy reader = new spy();

      bSuccess = reader.open();

      try { if ( bSuccess ) reader.read(); }
      catch (Exception e) { e.printStackTrace(); }

      }

   }
