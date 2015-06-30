
import net.tinyos.packet.*;
import net.tinyos.util.*;
import net.tinyos.message.*;
import net.tinyos.deluge.*;


class PrettyPrint {
  static int typeByte = 2;
  static int groupByte = 3;
  static int AM_DELUGEADVMSG            = 151;
  static int AM_DELUGEREQUPDMETADATAMSG = 152;
  static int AM_DELUGEUPDMETADATAMSG    = 153;
  static int AM_DELUGEREQMSG            = 154;
  static int AM_DELUGEDATAMSG           = 155;
  static int AM_DELUGEDURATIONMSG       = 156;

  static int convertByte(byte temp) {
    return (temp < 0) ? temp + 256 : temp;
  }

  public static void print(byte[] packet) {
    Message msg = null;
    int type = convertByte(packet[typeByte]);
    int group = convertByte(packet[groupByte]);
    type -= 10;
    if (group == 1) {
      System.out.println("Sending ...");
    } else if (group == 2) {
      System.out.println("Receiving ...");
    }
    if (type == AM_DELUGEADVMSG) {
      msg = new DelugeAdvMsg(packet, 5);
    } else if (type == AM_DELUGEREQUPDMETADATAMSG) {
      msg = new DelugeReqUpdMetadataMsg(packet, 5);
    } else if (type == AM_DELUGEUPDMETADATAMSG) {
      msg = new DelugeUpdMetadataMsg(packet, 5);
    } else if (type == AM_DELUGEREQMSG) {
      msg = new DelugeReqMsg(packet, 5);
    } else if (type == AM_DELUGEDATAMSG) {
      msg = new DelugeDataMsg(packet, 5);
    } else if (type == AM_DELUGEDURATIONMSG) {
      msg = new DelugeDurationMsg(packet, 5);
    } else {
      Dump.printPacket(System.out, packet);
      return;
    }
      


    System.out.println(msg.toString());
  }

  
  
  
}


