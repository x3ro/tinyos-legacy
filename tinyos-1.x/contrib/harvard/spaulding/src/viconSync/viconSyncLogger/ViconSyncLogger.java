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
public class ViconSyncLogger implements MessageListener
{
    private static final DecimalFormat dbFormat = new DecimalFormat("#.###");
    private static final boolean USE_GMT_DATE = false;
    Logger logger = new Logger();
    MoteIF moteIF;


    public static void main(String args[])
    {
        ViconSyncLogger myapp = new ViconSyncLogger();
    }


    private void resetMoteIF() 
    {
        try {
            moteIF = new MoteIF(PrintStreamMessenger.err); // uses MOTECOM!
            moteIF.registerListener(new ViconSyncMsg(), this);
        } catch (Exception e) {
            System.err.println("Error: Could not connect MoteIF: " + e);
            e.printStackTrace();
            System.exit(1);
        }
    }

    ViconSyncLogger()
    {
        logger.open( DateToString.dateToString(new Date(), USE_GMT_DATE) );
        resetMoteIF();
    }

    public void messageReceived(int dstaddr, Message msg)
    {
        if (msg instanceof ViconSyncMsg) {

            ViconSyncMsg vsMsg = (ViconSyncMsg) msg;

            //long pcTime = System.currentTimeMillis();
            String pcTime = DateToString.dateToString(new Date(), USE_GMT_DATE);
            long localTime = vsMsg.get_localTime();
            long globalTime = vsMsg.get_globalTime();
            int isSynched = vsMsg.get_isSynched();
            int edgeCnt = vsMsg.get_edgeCnt();

            String logStr = 
                "pcTime= " + pcTime +
                " localTime= " + localTime +
                " globalTime= " + globalTime +
                " isSynched= " + isSynched +
                " edgeCnt= " + edgeCnt;
            
            System.out.println(logStr);
            logger.writeln(logStr);
        }
    }
}
