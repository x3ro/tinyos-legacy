/*
 * Author: Mike Chen <mikechen@cs.berkeley.edu>
 * Inception Date: October 22th, 2000
 *
 * This software is copyrighted by Mike Chen and the Regents of
 * the University of California.  The following terms apply to all
 * files associated with the software unless explicitly disclaimed in
 * individual files.
 *
 * The authors hereby grant permission to use this software without
 * fee or royalty for any non-commercial purpose.  The authors also
 * grant permission to redistribute this software, provided this
 * copyright and a copy of this license (for reference) are retained
 * in all distributed copies.
 *
 * For commercial use of this software, contact the authors.
 *
 * IN NO EVENT SHALL THE AUTHORS OR DISTRIBUTORS BE LIABLE TO ANY PARTY
 * FOR DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES
 * ARISING OUT OF THE USE OF THIS SOFTWARE, ITS DOCUMENTATION, OR ANY
 * DERIVATIVES THEREOF, EVEN IF THE AUTHORS HAVE BEEN ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 *
 * THE AUTHORS AND DISTRIBUTORS SPECIFICALLY DISCLAIM ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE, AND NON-INFRINGEMENT.  THIS SOFTWARE
 * IS PROVIDED ON AN "AS IS" BASIS, AND THE AUTHORS AND DISTRIBUTORS HAVE
 * NO OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR
 * MODIFICATIONS.
 */

//==============================================================================
//===   listen.java   ==============================================

package net.tinyos.gdi;

import net.tinyos.message.MoteIF;
import net.tinyos.message.MessageListener;
import net.tinyos.message.Message;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;

/**
 *
 * Init the serial port and reads data from it.
 *
 * @author  <A HREF="http://www.cs.berkeley.edu/~mikechen/">Mike Chen</A>
 *		(<A HREF="mailto:mikechen@cs.berkeley.edu">mikechen@cs.berkeley.edu</A>)
 * @since   1.1.6
 *
 * modified by bwhull to work with the serialforwarder
 */


public class DBLoggerWB implements MessageListener, Runnable {

    //=========================================================================
    //===   CONSTANTS   =======================================================

    private static int MSG_SIZE = 36;  // 4 header bytes, 30 msg bytes, 2 crc
				       // bytes;  2 strength bytes are not
				       // transmitted
    //=========================================================================
    //===   PRIVATE VARIABLES  ================================================

    String strAddr;
    int nPort;
    MoteIF sfstub;

    Connection conn = null;
    private static  String urlPSQL= "jdbc:postgresql:";
    private String m_usr = "birdwatcher";
    private String m_pwd = "mote";

    private final static String insertStmtWS = "INSERT INTO gsk_query1 values (now(), ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";
    private final static String insertStmtB  = "INSERT INTO gsk_query2 values (now(), ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";
    private final static String insertStmtAck  = "INSERT INTO gsk_command_acks values (?, now(), ?, ?, ?, ?)";
    private final static String updateStmtCalib = "UPDATE gsk_mote_info SET calib = ? WHERE mote_id = ?";

    public DBLoggerWB(String host, String port, String pgHost, String dbName) {
  	    this.nPort = Integer.parseInt( port );
	    this.strAddr = host;
        this.sfstub = null;
        try {
            this.sfstub = new MoteIF(strAddr,nPort,-1);
            sfstub.registerListener(new GDI2SoftWSMsg(),this);
            sfstub.registerListener(new GDI2SoftCalibMsg(), this);
            sfstub.registerListener(new GDI2SoftAckMsg(), this);
            sfstub.start();
        } catch (Exception e) {
            e.printStackTrace();  //To change body of catch statement use Options | File Templates.
            System.exit(1);
        }
        try {
            urlPSQL += "//" + pgHost + "/" + dbName;
            Class.forName ( "org.postgresql.Driver" );
            conn = DriverManager.getConnection(urlPSQL, m_usr, m_pwd);
            System.out.println("connected to " + urlPSQL);
        } catch (Exception ex) {
            System.out.println("failed to connect to Postgres!\n");
            ex.printStackTrace();
            System.exit(1);
        }
        System.out.println("Connected to Postgres!\n");

    }

    public void packetReceived(byte[] packet) {
    }



    //=========================================================================
    //===   MAIN    ===========================================================

    public static void main(String args[]) {
	    if (args.length < 4) {
    	    System.err.println("usage: java DBLoggerWB [forwarder address] [port] [db address] [db name]");
    	    System.exit(-1);
    	}

    	DBLoggerWB reader = new DBLoggerWB(args[0],args[1],args[2],args[3]);
        Thread th = new Thread(reader);
        th.start();

    }

    public void run() {
        while (true) {
            try {
                Thread.sleep(500);
            } catch (InterruptedException e) {
                e.printStackTrace();
            }
        }
    }

    public void messageReceived(int to, Message m) {
        if (m.amType() == GDI2SoftWSMsg.AM_TYPE) {
            GDI2SoftWSMsg msg = new GDI2SoftWSMsg(m,0);
            byte[] packet = msg.dataGet();

            /*
            for (int i = 0; i < packet.length; i++) {
                String datumb = (Integer.toHexString(packet[i]).toUpperCase());
                if (datumb.length() == 1) {datumb = "0" + datumb;}
                System.out.print(datumb + " ");
            }
            System.out.println();
            */
            PreparedStatement  pstmt = null;
            //PreparedStatement uPstmt = null;
            try {
                pstmt = conn.prepareStatement(insertStmtWS);
                pstmt.setInt(1, (int)msg.get_seqno());
                pstmt.setInt(2, msg.get_source());
                int samplerate = msg.get_sample_rate_sec() + (60*msg.get_sample_rate_min());
                pstmt.setInt(3, samplerate);
                pstmt.setInt(4, msg.get_hamamatsu_top());
                pstmt.setInt(5, msg.get_hamamatsu_bottom());
                pstmt.setInt(6, msg.get_humidity());
                pstmt.setInt(7, msg.get_humidity_temp());
                pstmt.setInt(8, msg.get_pressure());
                pstmt.setInt(9, msg.get_pressure_temp());
                pstmt.setInt(10, msg.get_taos_ch0_top());
                pstmt.setInt(11, msg.get_taos_ch1_top());
                pstmt.setInt(12, msg.get_taos_ch0_bottom());
                pstmt.setInt(13, msg.get_taos_ch1_bottom());
                pstmt.setInt(14, msg.get_voltage());
                pstmt.setBytes(15,packet);

                pstmt.executeUpdate();
                pstmt.close(); /*
                uPstmt = conn.prepareStatement(updateStmt);
                uPstmt.executeUpdate();
                uPstmt.close();*/
            }
            catch (Exception ex) {
                System.out.println("insert failed.\n");
                ex.printStackTrace();
            }


            System.out.println("------------DATA--------------------");
            System.out.println("Source:            " + msg.get_source());
            System.out.println("Sequence Number:   " + msg.get_seqno());
            System.out.println("Sample Rate (min): " + msg.get_sample_rate_min());
            System.out.println("Sample Rate (sec): " + msg.get_sample_rate_sec());
            System.out.println("Hamamatsu (top):   " + msg.get_hamamatsu_top());
            System.out.println("Hamamatsu (bot):   " + msg.get_hamamatsu_bottom()); /*
            System.out.println("Humidity (%):      " + msg.get_humidity());
            System.out.println("Humidity Temp:     " + msg.get_humidity_temp()); */
            System.out.println("Humidity (%):      " + GDI2SoftConverter.humid_adj(msg.get_humidity(),msg.get_humidity_temp()));
            System.out.println("Humidity Temp:     " + GDI2SoftConverter.humid_temp(msg.get_humidity_temp()));
            System.out.println("Pressure:          " + msg.get_pressure());
            System.out.println("Pressure Temp:     " + msg.get_pressure_temp()); /*
            System.out.println("Taos Ch0 (top):    " + msg.get_taos_ch0_top());
            System.out.println("Taos Ch1 (top):    " + msg.get_taos_ch1_top());
            System.out.println("Taos Ch0 (bot):    " + msg.get_taos_ch0_bottom());
            System.out.println("Taos Ch1 (bot):    " + msg.get_taos_ch1_bottom()); */
            System.out.println("Taos (top):        " + GDI2SoftConverter.photo(msg.get_taos_ch0_top(), msg.get_taos_ch1_top()));
            System.out.println("Taos (bot):        " + GDI2SoftConverter.photo(msg.get_taos_ch0_bottom(), msg.get_taos_ch1_bottom()));
            // System.out.println("Voltage:           " + msg.get_voltage());
            System.out.println("Voltage:           " + GDI2SoftConverter.voltage(msg.get_voltage()));
            System.out.println();
        }
        else if (m.amType() == GDI2SoftCalibMsg.AM_TYPE) {
            GDI2SoftCalibMsg msg = new GDI2SoftCalibMsg(m,0);

            PreparedStatement pstmt = null;
            try {
                pstmt = conn.prepareStatement(updateStmtCalib);

                int[] input = new int[4];
                input[0] = msg.get_word1();
                input[1] = msg.get_word2();
                input[2] = msg.get_word3();
                input[3] = msg.get_word4();

                byte[] calib = GDI2SoftConverter.toCalibByteArray(input);

                pstmt.setBytes(1, calib);
                pstmt.setInt(2, msg.get_source());

                pstmt.executeUpdate();
                pstmt.close();
            }
            catch (Exception ex) {
                System.out.println("insert failed.\n");
                ex.printStackTrace();
            }

            System.out.println("---------CALIBRATION----------------");
            System.out.println("Source:            " + msg.get_source());
            System.out.println("Sequence Number:   " + msg.get_seqno());
            System.out.println("Word 1:            " + msg.get_word1());
            System.out.println("Word 2:            " + msg.get_word2());
            System.out.println("Word 3:            " + msg.get_word3());
            System.out.println("Word 4:            " + msg.get_word4());
            System.out.println("Command ID:        " + msg.get_command_id());
            System.out.println();
        }
        else if (m.amType() == GDI2SoftAckMsg.AM_TYPE) {
            GDI2SoftAckMsg msg = new GDI2SoftAckMsg(m,0);
            //command_id int references gsk_command_log, node_id int, sample_rate int);

            PreparedStatement  pstmt = null;
            try {
                pstmt = conn.prepareStatement(insertStmtAck);
                pstmt.setInt(1, msg.get_command_id());
                pstmt.setInt(2, msg.get_source());
                pstmt.setInt(3, msg.get_mote_type());
                pstmt.setInt(4, (int)msg.get_seqno());
                int samplerate = msg.get_sample_rate_sec() + (60*msg.get_sample_rate_min());
                pstmt.setInt(5, samplerate);

                pstmt.executeUpdate();
                pstmt.close();
            }
            catch (Exception ex) {
                System.out.println("insert failed.\n");
                ex.printStackTrace();
            }

            System.out.println("------------ACK---------------------");
            System.out.println("Source:            " + msg.get_source());
            System.out.println("Sequence Number:   " + msg.get_seqno());
            System.out.println("Sample Rate (min): " + msg.get_sample_rate_min());
            System.out.println("Sample Rate (sec): " + msg.get_sample_rate_sec());
            System.out.println("Command ID:        " + msg.get_command_id());
            System.out.println();
        }
    }

    public void close() {
        try
        {
            if (conn != null)
                conn.close();
            conn = null;
            System.out.println("disconnected from Postgres.\n");
        }
        catch (Exception e)
        {
            e.printStackTrace();
        }
    }

}


