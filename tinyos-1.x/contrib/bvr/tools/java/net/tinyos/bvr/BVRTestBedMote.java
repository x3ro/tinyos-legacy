package net.tinyos.bvr;

import net.tinyos.util.*;
import java.io.*;
import java.util.*;

import net.tinyos.message.*;
import net.tinyos.packet.*;
import net.tinyos.util.*;
import net.tinyos.bvr.messages.*;

public class BVRTestBedMote implements MessageListener, BVRConstants  {
  private Receiver receiver;
  private Date date;
  private long time;
  private int id;
  private int port;

  private String host;

  private MoteIF mote;

  private BVRCommandMessage command;
  private short sequenceNo = 0;
  private int updateCount = 0;
  private short coords[]; 

  private boolean updating = true;

  /* This creates a new mote listener. It assumes that a mote with
   * programmed id <i> is connected to a serial forwarder at port
   * basePort + i, at host host. 
   */
  public BVRTestBedMote(int id, String host, int basePort) {
    this.id = id;
    this.port = basePort+id;
    this.host = host;
    System.err.println("Starting connection to mote "+id+" at "+host+":"+port);
    PhoenixSource source = BuildSource.makePhoenix("sf@"+host+":"+port, PrintStreamMessenger.err);
    mote = new MoteIF(source);
    BVRLogMessage logmessage = new BVRLogMessage();
    mote.registerListener(logmessage, this);
    
    command = new BVRCommandMessage();
    command.set_header_last_hop(TOS_UART_ADDR);
    command.set_type_data_hopcount((short)1);
    command.set_type_data_origin(TOS_UART_ADDR);
    command.set_type_data_data_flags((short)0);
  }

  public void messageReceived(int dest_addr, Message m) {
     synchronized(this) {
         if (updating && m instanceof BVRLogMessage) {
             BVRLogMessage lm = (BVRLogMessage)m;    
             updateCount++;
             short type = lm.get_log_msg_type();
             if (type == LOG_CHANGE_COORDS) {
                 updateCoordinates(lm);
             }
         }
     }
  }

  public void stopUpdating() {
     updating = false;
  }

  public void startUpdating() {
     updating = true;
  }

  public boolean isUpdating() {
     return updating;
  }

  public int getId() {
     return id;
  }

  public int getUpdateCount() {
     return updateCount;
  }

  public short[] getCoords() {
     return coords;
  }
 
  public short countValid() {
     short count = 0;
     if (coords != null) {
       for (int i = 0; i < coords.length; i++) {
           if (coords[i] != 255) {
             count++;
           }
       }
     }
     return count;
  }

 
  public void sendRouteCommand(BVRTestBedMote dest) {
     System.out.print("Sending route command from " + id + " to " + dest.getId() + " [");
     short[] destCoords = dest.getCoords();
     System.out.print(destCoords[0]);
     for (int i = 1; i < destCoords.length; i++) {
         System.out.print("," + destCoords[i]);
     }
     System.out.println("]");

    sequenceNo++;
    command.set_header_seqno(sequenceNo);
    command.set_type_data_data_seqno(sequenceNo);

    command.set_type_data_type(BVR_CMD_APP_ROUTE_TO);
    command.set_type_data_data_args_coords_comps(dest.getCoords());
    command.set_type_data_data_args_dest_addr(dest.getId());
    command.set_type_data_data_args_dest_mode((byte)2);

    sendCommand();
  }

  private void sendCommand() {
     System.out.print("Sending payload: ");
             
     for (int i = 0; i < command.dataLength(); i++) {
       System.out.print(Integer.toHexString(command.dataGet()[i] & 0xff)+ " ");
     }
     System.out.println();

     try {
         mote.send(id, command);
     } catch (IOException e) {e.printStackTrace(System.err);}
  }

  private void updateCoordinates(BVRLogMessage m) {
    this.coords = m.get_log_msg_update_coordinates_Coords_comps();
    //System.out.print("Update coordinates: ");
    //this.printCoordinates();
  }
  
  public void printCoordinates() {
      System.out.print("m "+id+": [");
      if (coords != null) {
          System.out.print(coords[0]);
          for (int i = 1; i < coords.length; i++) {
             System.out.print("," + coords[i]); 
          }
      } 
      System.out.print("]");
  }
}
