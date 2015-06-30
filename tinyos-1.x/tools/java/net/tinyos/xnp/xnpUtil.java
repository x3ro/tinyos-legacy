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
import net.tinyos.message.*;
import javax.swing.*;

public class xnpUtil implements MessageListener, Runnable{
/*-----------------------------------------------------------------------------
* General Description:
*--------------------------------------------------------------------------- */
    public static final byte AM_REPROG = 47;      //AM handler for this reprogamming code
    public static final byte MSG_LENGTH = 36;     //TOS message length
    static final byte MSG_DATALENGTH = 29;        //number of data bytes in mote msg
    public static final byte MSG_DATA = 5;         //1st location in mote pck for  data

    public static final byte MSG_READ  = 50;
    public static final byte MSG_RUN = 8;
    public static final int GENERIC_BASE_ADDR = 0x7e;
    public static final int TOS_BROADCAST_ADDR = 0xffff;

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
    MoteMsgIF mote;

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

    private static boolean m_bXGenericBase = false;

    public static int m_MoteIdQry;	// to screen the mote id for query

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

  public xnpUtil( MoteMsgIF motestub ) {
      this();
      mote = motestub;
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
//   -if using XGenericBase then there 2 extra header bytes at the start of the packet
//   -MSG_DATA location in packet is always echo of cmd that requested message
//--------------------------------------------------------------------------------------------

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


    public void messageReceived(int dest_addr, Message msg) {
        if (msg instanceof XnpMsg) {
            xnpReceived((XnpMsg) msg);
        } else {
            throw new RuntimeException("messageReceived: Got bad message type: "
               + msg);
        }
    }

    void xnpReceived(XnpMsg xnpmsg) {

       m_bMoteMsgRcvd = true;

       if (xnpmsg.get_cmd() == CMD_DWNLOAD_STATUS) {
           if (xnpmsg.getElement_data(1) == CMD_NO_ERR) m_bCmdAccepted = true;
           else m_bCmdAccepted = false;
           m_NmbCodeCapsulesRcvd = xnpmsg.get_cid();
       }
       else if (xnpmsg.get_cmd() == CMD_PROG_ID) {
           int itmp = 1;
           itmp = xnpmsg.get_pid();
           m_prog_id_rcvd = itmp;
       }
       else if (xnpmsg.get_cmd() == CMD_QRY_CAPSULES) {
           if (m_MoteIdQry == 0 || m_MoteIdQry == xnpmsg.get_subcmd()) {
               m_MoteIdQry = xnpmsg.get_subcmd();
               m_mote_id_rcvd = xnpmsg.get_subcmd();
               m_NmbCodeCapsulesRcvd = xnpmsg.get_cid();
               if (m_NmbCodeCapsulesRcvd > m_NmbCodeCapsules)
                   m_NmbCodeCapsulesRcvd = 1;
           }
       }
       else if (xnpmsg.get_cmd() == CMD_DWNLOAD_COMPLETE) {
           m_mote_id_rcvd = xnpmsg.get_subcmd();
           // set the received capsule number larger than the total
           // number of capsules
           m_NmbCodeCapsulesRcvd = m_NmbCodeCapsules + 2;
       }
       else if (xnpmsg.get_cmd() == CMD_TERMINATE_LOAD) {
       }
       //notify();
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
   FileInputStream fis = null;
   m_NmbCodeCapsules = 0;                                       //# code capsules to xmit
   try {
      DataInputStream dis = new DataInputStream (fis = new FileInputStream(name));
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
   try { if( fis != null ) fis.close(); } catch(Exception e) { }
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
   XnpMsg xnpmsg = new XnpMsg();

   xnpmsg.set_cmd((byte) CMD_START_DWNLOAD);  // cmd to initiate download
   xnpmsg.set_subcmd((byte) 0);
   xnpmsg.set_pid(prog_id);
   xnpmsg.set_cid(m_NmbCodeCapsules);

   return (WriteMsg(xnpmsg, bGetReply, iTries, iSleep));
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
        XnpMsg xnpmsg = new XnpMsg();
        int isrec, ipkt;
        int capsule= sindx+1;
        m_bMoteMsgRcvd = false;

        xnpmsg.set_cmd((byte) CMD_DWNLOADING);
        xnpmsg.set_subcmd((byte) localnode);
        xnpmsg.set_pid(prog_id);
        xnpmsg.set_cid(capsule);
        xnpmsg.setElement_data(0, m_srec[sindx][0]);		// srec type
        byte iLen = m_srec[sindx][1];                           // srec length
        xnpmsg.setElement_data(1, iLen);
        for (isrec = 0, ipkt = 2 ; isrec < iLen; isrec ++, ipkt++){
           xnpmsg.setElement_data(ipkt, m_srec[sindx][2+isrec]);
        }

        return (WriteMsg(xnpmsg, bGetReply, iTries, iSleep));
    }
/*-----------------------------------------------------------------------------
* CmdGetLoadStatus
* -xmit msg to request status of download
*-----------------------------------------------------------------------------*/
    public boolean CmdGetLoadStatus(short node,boolean bGetReply, int iTries, int iSleep){
        XnpMsg xnpmsg = new XnpMsg();
        m_bMoteMsgRcvd = false;		// rst mote message received

        xnpmsg.set_cmd((byte) CMD_DWNLOAD_STATUS);
        xnpmsg.set_subcmd((byte) node);
        xnpmsg.set_pid(prog_id);

        return (WriteMsg(xnpmsg, bGetReply, iTries, iSleep));
    }
/*-----------------------------------------------------------------------------
* CmdTerminateLoad
* -xmit msg to terminate downloading
*-----------------------------------------------------------------------------*/
    public boolean CmdTerminateLoad(short node,boolean bGetReply, int iTries, int iSleep){
        XnpMsg xnpmsg = new XnpMsg();
        m_bMoteMsgRcvd = false;           //rst mote message received

        xnpmsg.set_cmd((byte) CMD_TERMINATE_LOAD); 
        xnpmsg.set_subcmd((byte) node);
        xnpmsg.set_pid(prog_id);
        xnpmsg.set_cid(m_NmbCodeCapsules);

        return (WriteMsg(xnpmsg, bGetReply, iTries, iSleep));
    }


/*-----------------------------------------------------------------------------
* CmdStartISP
* -xmit msg to start reflashing/rebooting of motes
*-----------------------------------------------------------------------------*/
    public boolean CmdStartISP(short node, boolean bGetReply, int iTries, int iSleep){
        XnpMsg xnpmsg = new XnpMsg();

        xnpmsg.set_cmd((byte) CMD_START_ICP);
        xnpmsg.set_subcmd((byte) node);
        xnpmsg.set_pid(prog_id);
        xnpmsg.set_cid(m_NmbCodeCapsules);

        return (WriteMsg(xnpmsg, bGetReply, iTries, iSleep));
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
        XnpMsg xnpmsg = new XnpMsg();

        xnpmsg.set_cmd((byte) CMD_PROG_ID);
        xnpmsg.set_subcmd((byte) 0);
        xnpmsg.set_pid(prog_id);
        xnpmsg.set_cid(0);

        byte mMatch = 0;
        if (Match) mMatch = 1;

        xnpmsg.setElement_data(0, mMatch);

        return (WriteMsg(xnpmsg, bGetReply, iTries, iSleep));
    }
/*-----------------------------------------------------------------------------
* CmdQryCapsules
* -xmit cmd to motes to ask for missing capsules
* -if node_qry_id = 0 then all motes respond to query
* -if node_qry_id = n then only mote_id=n responds
*-----------------------------------------------------------------------------*/
    public boolean CmdQryCapsules(short node,short node_qry_id,boolean bGetReply, int iTries, int iSleep){
        XnpMsg xnpmsg = new XnpMsg();

        xnpmsg.set_cmd((byte) CMD_QRY_CAPSULES);
        xnpmsg.set_subcmd((byte) node_qry_id);
        xnpmsg.set_pid(prog_id);

        return (WriteMsg(xnpmsg, bGetReply, iTries, iSleep));
    }

//-----------------------------------------------------------------------------
//write mote packet to uart
// iTries : Nmb of times to xmit the packet (min value = 1)
// bGetReply: if true then expect reply from mote, if get response then exit
// iSleep: time to sleep between retries, 10msec increments
// if bGetReplay = true then return true immediatley,if get response from mote
// if no response from mote then return false
//------------------------------------------------------------------------------

  public boolean WriteMsg(XnpMsg xnpmsg,boolean bGetReply, int iTries, int iSleep){
    int iRetryNmb = 0;
    int i,j;

    m_bMoteMsgRcvd = false;
    if (iTries <= 0) iTries = 1;
    try {
       while (iRetryNmb < iTries){
          int count = iSleep;
          mote.send(MoteIF.TOS_BCAST_ADDR, xnpmsg);

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
