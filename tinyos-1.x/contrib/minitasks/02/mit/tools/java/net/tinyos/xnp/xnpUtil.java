/*
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice and the following
 * two paragraphs appear in all copies of this software.
 *
 * IN NO EVENT SHALL CROSSBOW TECHNOLOGY BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF CROSSBOW
 * TECHNOLOGY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * CROSSBOW TECHNOLOGY SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND CROSSBOW TECHNOLOGY HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 *
*/
/*-----------------------------------------------------------------------------
* xnpUtil:
* Utility functions for xnp:
* - 1. Read srec file
* - 2. Xmit/rcv mote messages
* SerialPortStub modified to set higher baud rates, variable packet sizes
*---------------------------------------------------------------------------- */
package net.tinyos.xnp;

import java.io.*;
import java.util.*;

import net.tinyos.util.*;
import javax.swing.*;

public class xnpUtil implements PacketListenerIF, Runnable{
/*-----------------------------------------------------------------------------
* General Description:
*------------------------------------------------------------------------------- */
    public static final byte AM_REPROG = 47;      //AM handler for this reprogamming code
    public static final byte MSG_LENGTH = 36;     //TOS message length
    static final byte MSG_DATALENGTH = 29;        //number of data bytes in mote msg
    public static final byte MSG_DATA = 5;         //1st location in mote pck for  data

    public static final byte MSG_READ  = 50;
    public static final byte MSG_RUN = 8;
    public static final int GENERIC_BASE_ADDR = 0x7e;
    public static final int TOS_BROADCAST_ADDR = 0xffff;
// Parameters if using XGenericBase
// XGenericBase requires two header bytes to the uart message.
// Header bytes are stripped off by XGenericBase before xmitting pckt.
// XGenericBase also adds the same header bytes to radio msg rcvd before sending
// out the uart
    public static boolean m_bUseXGB = false;       //true if using XGenericBase
    private static final byte XGB_MSG_LENGTH = 38; //XGenericBase message length
    private static final int XGB_HDR1 = 0xAA;     //1st header byte
    private static final int XGB_HDR2 = 0x55;     //2nd header byte

    public static int nrepeats = 4;
    public int nretries = 1000;
    public static final int MAX_CODE_SIZE  = 128*1024;          //128K bytes max code to load
    public static final int MAX_CAPSULES = MAX_CODE_SIZE / 16;  //16 bytes per cap => 8K capsuless
    public static final int MAX_SREC_BYTE_SIZE = 24;            //max bytes of srec data in srec line
    public static final int MAX_SREC_CHAR_SIZE = 2* MAX_SREC_BYTE_SIZE;
 //   public static int longDelay = 200;
 //   public static int shortDelay =  60;          //problem with generic base overrun?

    private static final boolean debug = true;         //true to display debug info

    byte flash[];                    //array of code bytes, read from srec file - OLD REMOVE!!!!
    byte CRCsrec[];                   //array to hold CRC calculation
    int length;                      //# of code bytes to xfr to node
    public static short prog_id = 1;              // program id: CRC of all data in srec file
    SerialStub serialStub;
    SerialPortStub SPStub;

    byte m_srec[][];                     //array to hold srec file lines
    public byte m_group_id;                       //group_id
    public static int m_NmbCodeCapsules;        //# of code capsules to xmit
    public static int m_NmbCodeCapsulesXmitted; //# code capsules xmitd to mote
    public static int m_NmbCodeCapsulesRcvd;    //# code capsules rcvd by mote
    public static boolean m_bCodeDwnloadDone;    //true when code download complete
    public static boolean m_bMoteMsgRcvd;            // true if message rcv from mote
    public static boolean m_bCmdAccepted;           //true if cmd accepted by mote
    public static boolean m_bBatteryVoltsOK;        //true if battery volts OK for reprogramming
    public static int m_BatteryVolts;           // battery volage in millivolts
    public static int m_prog_id_rcvd;               //prog_id read back from mote
    public static int m_mote_id_rcvd;            //mote id returned after query

// Commands sent to the Mote
    static final int
     CMD_START_DWNLOAD = 1,          //start download of new code
     CMD_DWNLOADING = 2,             //code capsule to load into serial flash
     CMD_DWNLOAD_COMPLETE = 3,       //no more code capsules to download
     CMD_DWNLOAD_STATUS = 4,         //respond with download status
     CMD_START_ICP = 5,              //start ICP - in cirucit programming
     CMD_QRY_CAPSULES = 6,           //qry for missing capsules
     CMD_PROG_ID = 7,                //qry for prog_id
     CMD_TERMINATE_LOAD = 8,         //cmd to terminate download
// return codes from MOTE
     CMD_NO_ERR = 0

    ;
//------------------------------------- Constructor----------------------------------------
    public xnpUtil() {
	   flash = new byte[MAX_CODE_SIZE];               //stores code bytes for download
	   m_srec = new byte[MAX_CAPSULES][MAX_SREC_BYTE_SIZE];
           CRCsrec = new byte[MAX_CAPSULES*MAX_SREC_BYTE_SIZE];
	   for (int i=0; i < MAX_CODE_SIZE; i++) {
	     flash[i] = (byte) 0xff;                      //init to 0xff
	   }
    }

  public xnpUtil(String commPort, int BaudRate, boolean bSetXGB) {
      this();
      SPStub = new SerialPortStub(commPort,(long)BaudRate);
      serialStub= SPStub;
      SetXSG(bSetXGB);
  }

// method to return a serialstub
    public SerialStub getStub() {
        return serialStub;
    }
//------------------------------------------------------------------------------
// Enable/disable XGenericBase
//------------------------------------------------------------------------------
    public void SetXSG(boolean bSetXGB){
     if (bSetXGB){
       SPStub.msgSize = XGB_MSG_LENGTH;
       SPStub.hdr1= (byte)0xaa;
       m_bUseXGB = true;       //true if using XGenericBase
     }
     else{
       SPStub.msgSize = MSG_LENGTH;
       SPStub.hdr1= 0x7e;
       m_bUseXGB = false;       //true if using XGenericBase
     }
    }
//------------------------------------------------------------------------------
// run: serial port read thread
//------------------------------------------------------------------------------
    public void run() {
	try {
          while (true) {
	    serialStub.Read();                        //read the serial port
          }
	}
	catch (Exception e) {
	    System.err.println("Reading ERROR");         //port err
	    System.err.println(e);
	    e.printStackTrace();
	}
	System.err.print("error");
    }
//--------------------------------------------------------------------------------------------
// packetReceived:
//   -packet received from mote
//   -decode packet
//   -if m_bUseXGB = true then there 2 extra header bytes at the start of the packet
//   -MSG_DATA location in packet is always echo of cmd that requested message
//--------------------------------------------------------------------------------------------
    public synchronized void packetReceived(byte [] readings) {
       int i;

       if (debug) {
            System.out.print("Rcv Pkt: ");
            for(int j = 0; j < readings.length; j++)
                System.out.print(Integer.toHexString(readings[j] & 0xff) + " ");
            System.out.println("\n");
        }
       if (m_bUseXGB){                                 //byte shift XGB data
          for (i =0; i < readings.length-2;i++){
             readings[i] = readings[i+2];
          }
       }
       if (readings[2] != AM_REPROG) return;
   //         if (readings[MSG_DATA] == CMD_START_DWNLOAD){

  //            if (readings[MSG_DATA+1] == 1) m_bBatteryVoltsOK = true;
  //            else                            m_bBatteryVoltsOK = false;
   //           m_BatteryVolts = ((readings[MSG_DATA+3] & 0xff) << 8) +
   //                            (readings[MSG_DATA+2] & 0xff);
   //        }
   //        else if (readings[MSG_DATA + 3] == CMD_DWNLOAD_STATUS){
       m_bMoteMsgRcvd = true;
        if (readings[MSG_DATA] == CMD_DWNLOAD_STATUS){
                if (readings[MSG_DATA + 7] == CMD_NO_ERR) m_bCmdAccepted = true;
                else m_bCmdAccepted = false;
                m_NmbCodeCapsulesRcvd = ((readings[MSG_DATA+5] & 0xff) << 8) +
                                          (readings[MSG_DATA+4] & 0xff);
        }
        else if (readings[MSG_DATA] == CMD_PROG_ID){
                int itmp = 1;
         //       itmp = (readings[MSG_DATA+3] & 0xff) << 8 +
         //                           (readings[MSG_DATA+2] & 0xff);
                itmp = (readings[MSG_DATA+3] & 0xff) << 8;
                itmp += (readings[MSG_DATA+2] & 0xff);
                m_prog_id_rcvd = itmp;
        }
        else if (readings[MSG_DATA] == CMD_QRY_CAPSULES){
                m_mote_id_rcvd = readings[MSG_DATA+1];
                m_NmbCodeCapsulesRcvd = ((readings[MSG_DATA+5] & 0xff) << 8) +
                                          (readings[MSG_DATA+4] & 0xff);
                if (m_NmbCodeCapsulesRcvd >  m_NmbCodeCapsules) m_NmbCodeCapsulesRcvd = 1;

        }
        else if (readings[MSG_DATA] == CMD_TERMINATE_LOAD){
        }
	notify();
    }

// set/get group id
    public void setGroupID(short group) {
	m_group_id = (byte)group;
    }

    public byte getGroupID() {
	return (byte)m_group_id;
    }
  // stop the code download
    public void stopDownload(){
      m_bCodeDwnloadDone = true;
    }
//--------------------------htoi-----------------------------------------------
// convert 2 chars to a 16 bit integer
// line: an array of chars
// index: index into 1st of 2 chars to convert
//-----------------------------------------------------------------------------
    public int htoi(char []line, int index) {
	String val = "" + line[index] + line[index + 1];  //val = 2 byte char
	return Integer.parseInt(val, 16);                 //return 16 bit integer
    }
//--------------------------ctoi-----------------------------------------------
// convert 1 char to a 16 bit integer
// line: an array of chars
// index: index into 1st of 2 chars to convert
//-----------------------------------------------------------------------------
    public int ctoi(char sChar) {
	String val = "" + sChar;
	return Integer.parseInt(val, 16);                 //return 16 bit integer
    }
//----------------------calculateCRC-------------------------------------------
//compute CRC of array
//------------------------------------------------------------------------------
    private short calculateCRC(byte packet[]) {
	short crc;
	int i;
	int index = 0;
	int count = packet.length - 2;
	crc = 0;
	while (--count >= 0) {
	    crc = (short) (crc ^ ((short) (packet[index++]) << 8));
	    i = 8;
	    do {
		if ((crc & 0x8000) != 0)
		    crc = (short)(crc << 1 ^ ((short)0x1021));
		else
		    crc = (short)(crc << 1);
	    } while(--i>0);
	}
	return (crc);
    }

/*-----------------------------------------------------------------------------
* readSrecCode
* -read a .srec code file; file format: S<type><length><address><data><checksum>
* -create prog_id which is crc of data from srec file
* -search for 1st "1" in file, then read all data records until end of "1" as 1st char
* -return true if srec file read
* srec file format:
*  <type> : 0 -9
*    0: start record;
*    1: data record, 16 bit address;
*    9 end record giving exe address
*  <length> : two char, length of record
*  <address> : 4 char for 16bit address
*  <data>: 2 char per byte of memory
*  <checksum>: 1's complement of the 8 bit checksum
*-----------------------------------------------------------------------------*/
public boolean readSrecCode(String name) {
int j = 0;
int jCRC = 0;
   m_NmbCodeCapsules = 0;                                       //# code capsules to xmit
   try {
      DataInputStream dis = new DataInputStream (new FileInputStream(name));
      String line;
      while (true) {
	line = dis.readLine();                                  //read a line from file
	char [] bline = line.toUpperCase().toCharArray();       //get array of bytes
	int line_size = bline.length;
	if (bline[1] > '0') {                                  //bline[0] = 'S'
          m_NmbCodeCapsules++;                                  //inc # of code capsules
	  //int n = htoi(bline, 2)-3;                             //# of data bytes in rec
	  if (line_size > MAX_SREC_CHAR_SIZE){
	    System.out.println("Too many data bytes in srec file line: " + m_NmbCodeCapsules);
	    return false;
	  }
          //int start = (htoi(bline, 4) << 8) + htoi(bline, 6); //start address of rc
          m_srec[m_NmbCodeCapsules-1][0] = (byte)ctoi(bline[1]);              //srec 'type'
	  CRCsrec[jCRC++] = m_srec[m_NmbCodeCapsules-1][0];
	  m_srec[m_NmbCodeCapsules-1][1] = (byte) htoi(bline,2);              //srec 'length'
	  CRCsrec[jCRC++] = m_srec[m_NmbCodeCapsules-1][1];
	  int s;
          for (j = 2, s = 4;  j < m_srec[m_NmbCodeCapsules-1][1]+2; j++,s+=2) {
	    m_srec[m_NmbCodeCapsules-1][j] = (byte) htoi(bline, s); //srec len,addr,data,chk
	    CRCsrec[jCRC++] = m_srec[m_NmbCodeCapsules-1][j];
	  } //end for
	} // end if
       } // end while
   }//end try
   catch(FileNotFoundException e){
        System.out.println("readCode: " + e);
         return false;
   }
   catch (Exception e) {
//       System.out.println("# of Code Capsules: :" +  m_NmbCodeCapsules + e);
         System.out.println("# of Code Capsules: :" +  m_NmbCodeCapsules);
	 length = j;
   }
   //prog_id = calculateCRC(flash);
   prog_id = calculateCRC(CRCsrec);          //compute CRC of array
   System.out.println("Program ID:" + Integer.toHexString(prog_id).toUpperCase());
   return true;
}
/*-----------------------------------------------------------------------------
* CmdStartDwnload
* -xmit msg to Mote to start rcving code bytes
* -xmit prog id
* -xmit number of code capsules to be loaded
* - if node = broadcast address xmit message 'repeat' time, no response
* -rqst response msg from mote if node <> broadcast
*-----------------------------------------------------------------------------*/
public boolean CmdStartDwnload(short node,boolean bGetReply, int iTries, int iSleep){
  byte [] packet = new byte[MSG_LENGTH];
   packet[0] = (byte) (node & 0xff);
   packet[1] = (byte) ((node >> 8) & 0xff);
   packet[2] = AM_REPROG;
   packet[3] = m_group_id;
   packet[4] = MSG_DATALENGTH;
   packet[MSG_DATA+ 0] = CMD_START_DWNLOAD;              // cmd to initiate download
   packet[MSG_DATA+ 1] = 0;
   packet[MSG_DATA+ 2] = (byte) (prog_id & 0xff);
   packet[MSG_DATA+ 3] = (byte) ((prog_id >> 8) & 0xff);
   packet[MSG_DATA+ 4] = (byte) (m_NmbCodeCapsules & 0xff);
   packet[MSG_DATA+ 5] = (byte) ((m_NmbCodeCapsules >>8) & 0xff);
   return (WritePkt(packet,bGetReply,iTries,iSleep));
}
/*---------------------------------------------------------------------------
* CmdSendCapsule:
* -xmit a code capsule in the flash array to the mote
* -node : Mote Id (can be broadcast)
* -sindx : index in srec[] array for srec code record
* -These msgs xmitted after mote notified to start loading new program
* -msg consist of the data:
*   -localnode - if bcast msg to all, then mote with localnode address
*                should respond that it received the capsule.
*                if bcast msg to all, and localnode = 0 then no response
*                expected.
*   -program id (2 bytes):
*   -capsule# (2 bytes)  : increments from 1..m_NmbCodeCapsulesXmitted
*   -srec type(1 byte)   : type of srec record
*   -srec length(1 byte) : # of bytes to follow in srec record
*   -data[]: srec data bytes, including code address, code data bytes, chksum
*---------------------------------------------------------------------------*/
    public boolean CmdsendCapsule(short node, short localnode, int sindx,
                                  boolean bGetReply, int iTries, int iSleep){
        byte [] packet = new byte[MSG_LENGTH];                //create packet
        int isrec, ipkt;
        int  capsule= sindx+1;
        m_bMoteMsgRcvd = false;
        packet[0] = (byte) (node & 0xff);                     //Mote_Id, LSB
        packet[1] = (byte) ((node >> 8) & 0xff);              //Mote_Id, MSB
        packet[2] = AM_REPROG;                             //AM_MSG
        packet[3] = m_group_id;                                 // Group Id
        packet[4] = MSG_DATALENGTH;
        packet[MSG_DATA+ 0] = CMD_DWNLOADING;
        packet[MSG_DATA+ 1] = (byte)localnode;
        packet[MSG_DATA+ 2] = (byte) (prog_id & 0xff);
        packet[MSG_DATA+ 3] = (byte) ((prog_id >> 8) & 0xff);
        packet[MSG_DATA+ 4] = (byte) (capsule & 0xff);          // capsule, LSBy
        packet[MSG_DATA+ 5] = (byte) ((capsule >> 8) & 0xff);   // capsule,MSBy
        packet[MSG_DATA+ 6] = m_srec[sindx][0];                 // srec type
        byte iLen = m_srec[sindx][1];                           // srec length
        packet[MSG_DATA+ 7] = iLen;
        for (isrec = 0, ipkt = 8 ; isrec < iLen; isrec ++, ipkt++){
           packet[MSG_DATA+ipkt] = m_srec[sindx][2+isrec];
        }
        return (WritePkt(packet,bGetReply,iTries,iSleep));
    }
/*-----------------------------------------------------------------------------
* CmdGetLoadStatus
* -xmit msg to request status of download
*-----------------------------------------------------------------------------*/
    public boolean CmdGetLoadStatus(short node,boolean bGetReply, int iTries, int iSleep){
        byte [] packet = new byte[MSG_LENGTH];
        m_bMoteMsgRcvd = false;           //rst mote message received
        packet[0] = (byte) (node & 0xff);
        packet[1] = (byte) ((node >> 8) & 0xff);
        packet[2] = AM_REPROG;
        packet[3] = m_group_id;
        packet[4] = MSG_DATALENGTH;
        packet[MSG_DATA+ 0] = CMD_DWNLOAD_STATUS;
        packet[MSG_DATA+ 1] = (byte)node;
        packet[MSG_DATA+ 2] = (byte) (prog_id & 0xff);
        packet[MSG_DATA+ 3] = (byte) ((prog_id >> 8) & 0xff);
        return (WritePkt(packet,bGetReply,iTries,iSleep));
    }
/*-----------------------------------------------------------------------------
* CmdTerminateLoad
* -xmit msg to terminate downloading
*-----------------------------------------------------------------------------*/
    public boolean CmdTerminateLoad(short node,boolean bGetReply, int iTries, int iSleep){
        byte [] packet = new byte[MSG_LENGTH];
        m_bMoteMsgRcvd = false;           //rst mote message received
        packet[0] = (byte) (node & 0xff);
        packet[1] = (byte) ((node >> 8) & 0xff);
        packet[2] = AM_REPROG;
        packet[3] = m_group_id;
        packet[4] = MSG_DATALENGTH;
        packet[MSG_DATA+ 0] = CMD_TERMINATE_LOAD;
        packet[MSG_DATA+ 1] = (byte)node;
        packet[MSG_DATA+ 2] = (byte) (prog_id & 0xff);
        packet[MSG_DATA+ 3] = (byte) ((prog_id >> 8) & 0xff);
        packet[MSG_DATA+ 4] = (byte) (m_NmbCodeCapsules & 0xff);
        packet[MSG_DATA+ 5] = (byte) ((m_NmbCodeCapsules >>8) & 0xff);
        return (WritePkt(packet,bGetReply,iTries,iSleep));
    }


/*-----------------------------------------------------------------------------
* CmdStartISP
* -xmit msg to start reflashing/rebooting of motes
*-----------------------------------------------------------------------------*/
 //   public void CmdStartISP(short node)  throws IOException{
 //      byte [] packet = new byte[MSG_LENGTH];
 //       m_bMoteMsgRcvd = false;           //rst mote message received
  //      packet[0] = (byte) (node & 0xff);
    //    packet[1] = (byte) ((node >> 8) & 0xff);
 //       packet[2] = AM_REPROG;
 //       packet[3] = m_group_id;
 //       packet[4] = MSG_DATALENGTH;
 //       packet[MSG_DATA+ 0] = CMD_START_ICP;
 //       packet[MSG_DATA+ 1] = (byte)node;
 //       packet[MSG_DATA+ 2] = (byte) (prog_id & 0xff);
 //       packet[MSG_DATA+ 3] = (byte) ((prog_id >> 8) & 0xff);
 //       packet[MSG_DATA+ 4] = (byte) (m_NmbCodeCapsules & 0xff);
 //       packet[MSG_DATA+ 5] = (byte) ((m_NmbCodeCapsules >>8) & 0xff);
 //       preparePacket(packet);
 //       serialStub.Write(packet);
 //   }
/*-----------------------------------------------------------------------------
* CmdStartISP
* -xmit msg to start reflashing/rebooting of motes
*-----------------------------------------------------------------------------*/
    public boolean CmdStartISP(short node, boolean bGetReply, int iTries, int iSleep){
        byte [] packet = new byte[MSG_LENGTH];
        packet[0] = (byte) (node & 0xff);
        packet[1] = (byte) ((node >> 8) & 0xff);
        packet[2] = AM_REPROG;
        packet[3] = m_group_id;
        packet[4] = MSG_DATALENGTH;
        packet[MSG_DATA+ 0] = CMD_START_ICP;
        packet[MSG_DATA+ 1] = (byte)node;
        packet[MSG_DATA+ 2] = (byte) (prog_id & 0xff);
        packet[MSG_DATA+ 3] = (byte) ((prog_id >> 8) & 0xff);
        packet[MSG_DATA+ 4] = (byte) (m_NmbCodeCapsules & 0xff);
        packet[MSG_DATA+ 5] = (byte) ((m_NmbCodeCapsules >>8) & 0xff);
        return (WritePkt(packet,bGetReply,iTries,iSleep));
    }
/*-----------------------------------------------------------------------------
* CmdQryProgId
* -xmit cmd to request prog_id or mismatch
* -if Match = true then requesting mote to return the prog_id its now running.
*     Match = false then mote returns prog_id only if its prog_id doesn't match.
*             [This is used for bcast downloads, at end
*             of download, request all motes with incorrect prog_ids to respond]
*-----------------------------------------------------------------------------*/
      public boolean CmdQryProgId(short node, boolean Match,boolean bGetReply, int iTries, int iSleep){
          byte [] packet = new byte[MSG_LENGTH];
          packet[0] = (byte) (node & 0xff);
          packet[1] = (byte) ((node >> 8) & 0xff);
          packet[2] = AM_REPROG;
          packet[3] = m_group_id;
          packet[4] = MSG_DATALENGTH;
          packet[MSG_DATA+ 0] = CMD_PROG_ID;
          packet[MSG_DATA+ 1] = 0;
          packet[MSG_DATA+ 2] = (byte) (prog_id & 0xff);
          packet[MSG_DATA+ 3] = (byte) ((prog_id >> 8) & 0xff);
          packet[MSG_DATA+ 4] = 0;
          packet[MSG_DATA+ 5] = 0;
          byte mMatch = 0;
          if (Match) mMatch = 1;
          packet[MSG_DATA+ 6] = mMatch;
          return (WritePkt(packet,bGetReply,iTries,iSleep));
 }
/*-----------------------------------------------------------------------------
* CmdQryCapsules
* -xmit cmd to motes to ask for missing capsules
* -if node_qry_id = 0 then all motes respond to query
* -if node_qry_id = n then only mote_id=n responds
*-----------------------------------------------------------------------------*/
      public boolean CmdQryCapsules(short node,short node_qry_id,boolean bGetReply, int iTries, int iSleep){
        byte [] packet = new byte[MSG_LENGTH];
          packet[0] = (byte) (node & 0xff);
          packet[1] = (byte) ((node >> 8) & 0xff);
          packet[2] = AM_REPROG;
          packet[3] = m_group_id;
          packet[4] = MSG_DATALENGTH;
          packet[MSG_DATA+ 0] = CMD_QRY_CAPSULES;
          packet[MSG_DATA+ 1] = (byte)node_qry_id;
          packet[MSG_DATA+ 2] = (byte) (prog_id & 0xff);
          packet[MSG_DATA+ 3] = (byte) ((prog_id >> 8) & 0xff);
          return (WritePkt(packet,bGetReply,iTries,iSleep));
     }
/*-----------------------------------------------------------------------------
* download code capsules to Mote
* -node: MoteId
* -executed as thread
*-----------------------------------------------------------------------------*/
//  public void download(short node) throws IOException  {
//
//	m_NmbCodeCapsulesXmitted = 0;       //zero the # of code capsules xmitted
//	m_bCodeDwnloadDone = false;         //code download not complete
//	System.out.println("Xmitting code capsules:\n");
//
//
  //      for (int i = 0; i < m_NmbCodeCapsules; i ++) {
//	    CmdsendCapsule(node, 0,i);
//	    m_NmbCodeCapsulesXmitted++;	     //inc # of code capsules xmitted;
//	    try {
//		Thread.currentThread().yield();
//		Thread.currentThread().sleep(shortDelay);
//	    }
//	    catch (Exception e) {}
//	} //end for; download of code capsules
//	m_bCodeDwnloadDone = true;
//	while(true){
//	    try{
//	      Thread.currentThread().sleep(longDelay);
//	    }
//	    catch(Exception e){};
//	 }
 //  }
/*-----------------------------------------------------------------------------
* preparePacket
* prepare mote data packet for xmit
* -add CRC to packet
* -print packet if debug mode
*----------------------------------------------------------------------------*/
    synchronized void preparePacket(byte [] packet) {
	short crc;
        int j;
	crc = calculateCRC(packet);
	packet[packet.length-1] = (byte) ((crc>>8) & 0xff);
	packet[packet.length-2] = (byte) (crc & 0xff);
//        if (debug) {
//            System.out.print("Xmt Pkt: ");
//	    for(j = 0; j < packet.length; j++)
//              System.out.print(Integer.toHexString(packet[j] & 0xff) + " ");
//	    System.out.println("\n");
//    	}
    }
    private void printPacket(byte[] packet) {
	System.out.print("Packet:");
	for (int i = 0; i < packet.length; i++) {
	    if (i % 16 == 0) {System.out.println();}
	    String val = Integer.toHexString((int)(packet[i] & 0xff));
	    for (int j = 0; j < (3 - val.length()); j++) {
		System.out.print(" ");
	    }

	    System.out.print(val);
	}
	System.out.println();
    }
//-------------------------------readCapsule-----------------------------------
//xmit msg to mote to read back a code capsule
//-------------------------------readCapsule-----------------------------------
//    public void readCapsule(short node, int capsule) throws IOException {
//	readCapsule(node, capsule, 0);
//    }

//    public void readCapsule(short node, int capsule, int check) throws IOException {

//	byte [] packet = new byte[MSG_LENGTH];
//	packet[0] = (byte) (node & 0xff);
//	packet[1] = (byte) ((node >> 8) & 0xff);
//	packet[2] = MSG_READ;
//	packet[3] = m_group_id;
//	packet[5] = (byte) ((prog_id >> 8) & 0xff);
//	packet[4] = (byte) (prog_id & 0xff);
//	packet[7] = (byte) ((capsule >> 8) & 0xff);
//	packet[6] = (byte) (capsule & 0xff);
//	packet[9] = (byte) ((GENERIC_BASE_ADDR >> 8) & 0xff);
//	packet[8] = (byte) (GENERIC_BASE_ADDR & 0xff);
//	packet[10] = (byte) check;
//	preparePacket(packet);
//
//	serialStub.Write(packet);
//    }

//-----------------------------------------------------------------------------
//write mote packet to uart
// iTries : Nmb of times to xmit the packet (min value = 1)
// bGetReply: if true then expect reply from mote, if get response then exit
// iSleep: time to sleep between retries, 10msec increments
// if bGetReplay = true then return true immediatley,if get response from mote
// if no response from mote then return false
// if using XGenericBase then add header bytes to packet
//------------------------------------------------------------------------------
  public boolean WritePkt(byte [] packet,boolean bGetReply, int iTries, int iSleep){
    int iRetryNmb = 0;
    int i,j;
    byte[] tmp_packet;
    byte[] XGB_packet = new byte [XGB_MSG_LENGTH];

    preparePacket(packet);
    if (m_bUseXGB){                                //use XGenericBase?
        XGB_packet[0] = (byte)XGB_HDR1;
        XGB_packet[1] = (byte)XGB_HDR2;
        for (i = 0; i < packet.length; i ++){
          XGB_packet[i+ 2] = packet[i];
        }
        tmp_packet = XGB_packet;
    }
    else tmp_packet = packet;
    m_bMoteMsgRcvd = false;
    if (iTries <= 0) iTries = 1;
    try {
       while (iRetryNmb < iTries){
          int count = iSleep;
          serialStub.Write(tmp_packet);
          if (debug) {
            System.out.print("Xmt Pkt: ");
            for(j = 0; j < tmp_packet.length; j++)
              System.out.print(Integer.toHexString(tmp_packet[j] & 0xff) + " ");
              System.out.println("\n");
            }

          while (--count >= 0) {
            Thread.currentThread().sleep(10);       //wait for mote to reply
            if (bGetReply && m_bMoteMsgRcvd) return true;
          }
          iRetryNmb++;
       }
    }
    catch (Exception f) {
    }
    return false;



  }

}
