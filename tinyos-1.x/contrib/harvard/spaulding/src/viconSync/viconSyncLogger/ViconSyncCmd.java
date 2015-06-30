import net.tinyos.util.*;
import net.tinyos.message.*;
import java.util.*;
import java.text.*;
import java.io.*;

/**
 * This is the Vicon Java Logger
 *
 * @author Konrad Lorincz
 * @version 1.0, August 24, 2006
 */
public class ViconSyncCmd //implements MessageListener
{
    private MoteIF moteIF;


    public static void main(String args[])
    {
        int cmdID = 0;
        if (args.length < 2)
            usage();

        if (args[1].equals("stop")) {
            System.out.println("Sending cmd= stop");
            cmdID = 0;
        }
        else if (args[1].equals("start")) {
            System.out.println("Sending cmd= start");
            cmdID = 1;
        }
        else
            usage();

        int nodeID = Integer.parseInt(args[0]);
        ViconSyncCmd myApp = new ViconSyncCmd();
        myApp.sendMsg(nodeID, cmdID);
    }

    private static void usage() 
    {
        System.err.println("Usage:");
        System.err.println("  java ViconSyncCmd  <moteID> [stop | start]");
        System.exit(1);
    }


    ViconSyncCmd()
    {
        resetMoteIF();
    }

    private void resetMoteIF() 
    {
        try {
            moteIF = new MoteIF(PrintStreamMessenger.err); // uses MOTECOM!
//             moteIF.registerListener(new ViconSyncMsg(), this);
        } catch (Exception e) {
            System.err.println("Error: Could not connect MoteIF: " + e);
            e.printStackTrace();
            System.exit(1);
        }
    }

    private void sendMsg(int moteID, int cmdID)
    {
        ViconSyncCmdMsg vscMsg = new ViconSyncCmdMsg();
        vscMsg.set_cmdID(cmdID);
        
        synchronized (this) {
            try {
                System.err.println("Sending cmdID= " + cmdID + "...");
                moteIF.send(moteID, vscMsg);
            } catch (Exception e) {
                System.err.println("ERROR: Can't send message: " + e);
                e.printStackTrace();
            }
        }
    }


//     public void messageReceived(int dstaddr, Message msg)
//     {
//         if (msg instanceof ViconSyncMsg) {

//             ViconSyncMsg vsMsg = (ViconSyncMsg) msg;

//             //long pcTime = System.currentTimeMillis();
//             String pcTime = DateToString.dateToString(new Date(), USE_GMT_DATE);
//             long localTime = vsMsg.get_localTime();
//             long globalTime = vsMsg.get_globalTime();
//             int isSynched = vsMsg.get_isSynched();
//             int edgeCnt = vsMsg.get_edgeCnt();

//             String logStr = 
//                 "pcTime= " + pcTime +
//                 " localTime= " + localTime +
//                 " globalTime= " + globalTime +
//                 " isSynched= " + isSynched +
//                 " edgeCnt= " + edgeCnt;
            
//             System.out.println(logStr);
//             logger.writeln(logStr);
//         }
//     }
}
