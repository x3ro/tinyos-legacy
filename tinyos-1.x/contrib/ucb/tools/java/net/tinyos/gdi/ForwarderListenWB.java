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


public class ForwarderListenWB implements MessageListener, Runnable {

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
    public ForwarderListenWB(String host, String port) {
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
    }

    public void packetReceived(byte[] packet) {
    }

    //=========================================================================
    //===   MAIN    ===========================================================

    public static void main(String args[]) {
	    if (args.length < 2) {
    	    System.err.println("usage: java listen [forwarder address] [port] [msg size (optional - default=" + MSG_SIZE +"]");
    	    System.exit(-1);
    	}
    	if ( args.length == 3 ) {
    	    MSG_SIZE = Integer.parseInt( args[2] );
    	}

    	ForwarderListenWB reader = new ForwarderListenWB(args[0],args[1]);
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
            System.out.println("---------CALIBRATION----------------");
            System.out.println("Source:            " + msg.get_source());
            System.out.println("Sequence Number:   " + msg.get_seqno());
            System.out.println("Word 1:            " + msg.get_word1());
            System.out.println("Word 2:            " + msg.get_word2());
            System.out.println("Word 3:            " + msg.get_word3());
            System.out.println("Word 4:            " + msg.get_word4());
            System.out.println();
        }
        else if (m.amType() == GDI2SoftAckMsg.AM_TYPE) {
            GDI2SoftAckMsg msg = new GDI2SoftAckMsg(m,0);
            System.out.println("------------ACK---------------------");
            System.out.println("Source:            " + msg.get_source());
            System.out.println("Sequence Number:   " + msg.get_seqno());
            System.out.println("Sample Rate (min): " + msg.get_sample_rate_min());
            System.out.println("Sample Rate (sec): " + msg.get_sample_rate_sec());
        }
    }

}

