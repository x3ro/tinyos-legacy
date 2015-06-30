import net.tinyos.util.*;
import net.tinyos.packet.*;
import net.tinyos.message.*;
import java.io.*;

public class Read {
    public static final byte SEND_MSG_TYPE = 100;
    public static final byte RECV_MSG_TYPE = 101;
    public static boolean displayInHex = false;

    public static void main(String[] args) throws IOException
    {
        if (args.length != 2 && args.length != 3) {
          System.out.println("Usage: java Read <from_eeprom_line> <to_eeprom_line>");
          System.out.println("    or java Read <from_eeprom_line> <to_eeprom_line> hex");
        }
        int fromLineNum = Integer.parseInt(args[0]);
        int toLineNum = Integer.parseInt(args[1]);
        if (args.length == 3)
          if (args[2].toUpperCase().equals("HEX"))
            displayInHex = true;

	PacketSource sfw = BuildSource.makePacketSource();
	sfw.open(PrintStreamMessenger.err);

	byte[] packet = new byte[38];
        packet[0] = 28; // length
        packet[1] = 0;
        packet[2] = 0;
        packet[3] = 0;
        packet[4] = 0;
        packet[5] = 0;
        packet[6] = (byte)0xff;  // addr low
        packet[7] = (byte)0xff;  // addr hi
        packet[8] = (byte)SEND_MSG_TYPE;
        packet[9] = (byte)0x7d;  // group
 
        packet[10] = (byte)0;  // 0: read a line; 2: write a line.

        for (int i = fromLineNum; i <= toLineNum; i++) {

          /* Specify the line number. */
          packet[11] = (byte)((i >> 8) & 0xff);
          packet[12] = (byte)(i & 0xff);

          try {
	    sfw.writePacket(packet);
//          System.out.print("Sent: ");
//          Dump.printPacket(System.out, packet);
//          System.out.println();

            byte [] packetRecv = sfw.readPacket();
//            System.out.print("Recv: ");
//            Dump.printPacket(System.out, packetRecv);
//            System.out.println();
            processPacket(packetRecv);

	  } catch (IOException e) {
	    System.exit(2);
	  }
        }
   
	// A close would be nice, but javax.comm's close is deathly slow
	//sfw.close();

        System.exit(0);
    }

    private static void processPacket(byte [] packet) {
        if (RECV_MSG_TYPE == packet[8]) {
          String str = Integer.toHexString(packet[10] & 0xff).toUpperCase();
          int lineNum = ((packet[11] & 0xff) << 8) + (packet[12] & 0xff);
          System.out.print("Received Code: " + str + " Line " + lineNum + ": ");
          for (int i = 13; i < 29; i++) {
            if (displayInHex) str = Integer.toHexString(packet[i] & 0xff).toUpperCase();
            else str = "" + (packet[i] & 0xff); 
            // Make str 3-char long.
            if (str.length() == 1) str = "  " + str;
            else if (str.length() == 2) str = " " + str;
            System.out.print(str + " ");
          }
          System.out.println(); 
        }
    }
}
