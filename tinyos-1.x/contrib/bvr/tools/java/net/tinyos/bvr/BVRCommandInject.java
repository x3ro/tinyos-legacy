/* ex: set tabstop=4 shiftwidth=4 expandtab:*/ 
/* $Id: BVRCommandInject.java,v 1.1.1.1 2005/06/19 04:34:38 rfonseca76 Exp $ */

/**
 * @author Rodrigo Fonseca, based on BCastInject by Robert Szewczyk
 */

package net.tinyos.bvr;

import net.tinyos.util.*;
import java.io.*;
import java.util.Properties;
import net.tinyos.message.*;
import net.tinyos.bvr.messages.*;

public class BVRCommandInject implements MessageListener, BVRConstants {
    static Properties p = new Properties();

    public static final int TIMEOUT = 1000;

    public boolean response_received = false; 
        
    public static void usage() {
    System.err.println("Usage: java net.tinyos.bvr.BVRCommandInject"+
                   " <group_id> <address> <command> [arguments]");
        System.err.println("\twhere <command> and [arguments] can " + 
                   "be one of the following:");
        System.err.println("\t\thello");
        System.err.println("\t\tled_on");
        System.err.println("\t\tled_off");
        System.err.println("\t\tset_root <id>");
        System.err.println("\t\tget_root");
        System.err.println("\t\tset_coords <coords: x1 x2 x3 x...>");
        System.err.println("\t\tget_coords");
        System.err.println("\t\tset_radio <power>");
        System.err.println("\t\tget_radio");
        System.err.println("\t\tget_info");
        System.err.println("\t\tget_neighbor <n - neighbor index>");
        System.err.println("\t\tget_link_info <n - link index> ");
        System.err.println("\t\tget_root_info <n - root id>");
        System.err.println("\t\tget_id");
        System.err.println("\t\tfreeze");
        System.err.println("\t\tresume");
        System.err.println("\t\treset");
        
        System.err.println("\t\troute_to <mode> <dest_id> <coords: x1 x2 x3 x...>");
        System.err.println("\tand <address> can be either");
        System.err.println("\t\tBCAST or an integer (in hex or decimal)");
    }

    public static short restoreSequenceNo() {
    try {
        FileInputStream fis = new FileInputStream("cmd.properties");
        p.load(fis);
        short i = (short)Integer.parseInt(p.getProperty("sequenceNo", "1"));
        fis.close();
        return i;
    } catch (IOException e) {
        p.setProperty("sequenceNo", "1");
        return 1;
    }
    }
    public static void saveSequenceNo(int i) {
    try {
        FileOutputStream fos = new FileOutputStream("cmd.properties");
        p.setProperty("sequenceNo", Integer.toString(i));
        p.store(fos, "#Properties for BVRCommandInject\n");
    } catch (IOException e) {
        System.err.println("Exception while saving sequence number" +
                   e);
        e.printStackTrace();
    }
    }

    public static void main(String[] argv) throws IOException{
        String cmd;
        byte group_id = 0;
        byte am = 0;
        short mote_id = 0;
        short sequenceNo = 0;
    
    
        if (argv.length < 3) {
          usage();
          System.exit(-1);
        }
    
        //group_id
        try {
            if (argv[0].startsWith("0x") || argv[0].startsWith("0X")) {
                group_id = (byte)Integer.parseInt(argv[0].substring(2), 16);
            } else {
                group_id = (byte)Integer.parseInt(argv[0]);
            }
        } catch (NumberFormatException nfe) {
            usage();
            System.exit(-1);
        }
       
        
        //address
        if (argv[1].equals("BCAST")) {
          mote_id = TOS_BCAST_ADDR;
        }else {
          try {
            if (argv[1].startsWith("0x") || argv[1].startsWith("0X")) {
              mote_id = (short)Integer.parseInt(argv[1].substring(2), 16);
            } else {
              mote_id = (short)Integer.parseInt(argv[1]);
            }
          } catch (NumberFormatException nfe) {
            usage();
            System.exit(-1);
          }
        }
        
        //command and possible arguments
        cmd = argv[2];
    
        System.err.println("Args: group "+group_id+", dest "+mote_id+", " + cmd);
        
        BVRCommandMessage command = new BVRCommandMessage();
    
        sequenceNo = restoreSequenceNo();
        command.set_header_last_hop(TOS_UART_ADDR);
        command.set_header_seqno(sequenceNo);
        command.set_type_data_hopcount((short)1);
        command.set_type_data_origin(TOS_UART_ADDR);
        command.set_type_data_data_seqno(sequenceNo);
        command.set_type_data_data_flags((short)0);
    
        if (cmd.equals("hello")) {
            command.set_type_data_type(BVR_CMD_HELLO);
            mote_id =  TOS_BCAST_ADDR;

        } else if (cmd.equals("led_on")) {
            command.set_type_data_type(BVR_CMD_LED_ON);

        } else if (cmd.equals("led_off")) {
            command.set_type_data_type(BVR_CMD_LED_OFF);

        } else if (cmd.equals("set_root")) {
            if (argv.length != 4) {
                usage();
                System.exit(-1);
            }
            command.set_type_data_type(BVR_CMD_SET_ROOT_BEACON);
            short byte_arg = (byte)Integer.parseInt(argv[3]);
            command.set_type_data_data_args_byte_arg(byte_arg);
        } else if (cmd.equals("get_root")) {
            command.set_type_data_type(BVR_CMD_IS_ROOT_BEACON);    
        } else if (cmd.equals("set_coords")) {
            if (argv.length < 4) {
                usage();
                System.exit(-1);
            }
            command.set_type_data_type(BVR_CMD_SET_COORDS);
            //short valid = 0;  
            for (int i = 3; i < argv.length && i < 20; i++) {
                //valid |= 1 << (i-3);
                command.setElement_type_data_data_args_dest_coords_comps(
                    i-3,(short)Integer.parseInt(argv[i])
                );
            }
            //command.set_type_data_data_args_dest_coords_valid(valid);
        } else if (cmd.equals("get_coords")) {
            command.set_type_data_type(BVR_CMD_GET_COORDS);

        } else if (cmd.equals("set_radio")) {
            if (argv.length != 4) {
                usage();
                System.exit(-1);
            }
            command.set_type_data_type(BVR_CMD_SET_RADIO_PWR);
            short byte_arg = (short)Integer.parseInt(argv[3]);
            command.set_type_data_data_args_byte_arg(byte_arg);

        } else if (cmd.equals("get_radio")) {
            command.set_type_data_type(BVR_CMD_GET_RADIO_PWR);

        } else if (cmd.equals("get_info")) {
            command.set_type_data_type(BVR_CMD_GET_INFO);

        } else if (cmd.equals("get_neighbor")) {
            if (argv.length != 4) {
                usage();
                System.exit(-1);
            }
            command.set_type_data_type(BVR_CMD_GET_NEIGHBOR);
            short byte_arg = (short)Integer.parseInt(argv[3]);
            command.set_type_data_data_args_byte_arg(byte_arg);
        } else if (cmd.equals("get_link_info")) {
            if (argv.length != 4) {
                usage();
                System.exit(-1);
            }
            command.set_type_data_type(BVR_CMD_GET_LINK_INFO);
            short byte_arg = (short)Integer.parseInt(argv[3]);
            command.set_type_data_data_args_byte_arg(byte_arg);
            
        } else if (cmd.equals("get_root_info")) {
            if (argv.length != 4) {
                usage();
                System.exit(-1);
            }
            command.set_type_data_type(BVR_CMD_GET_ROOT_INFO);
            short byte_arg = (short)Integer.parseInt(argv[3]);
            command.set_type_data_data_args_byte_arg(byte_arg);
            
        } else if (cmd.equals("get_id")) {
            command.set_type_data_type(BVR_CMD_GET_ID);
        
        } else if (cmd.equals("freeze")) {
            command.set_type_data_type(BVR_CMD_FREEZE);
        } else if (cmd.equals("resume")) {
            command.set_type_data_type(BVR_CMD_RESUME);
        } else if (cmd.equals("reset")) {
            command.set_type_data_type(BVR_CMD_RESET);
        } else if (cmd.equals("route_to")) {
            if (argv.length < 6) {
                usage();
                System.exit(-1);
            }
            command.set_type_data_type(BVR_CMD_APP_ROUTE_TO);
            //short valid = 0;  
            for (int i = 5; i < argv.length && i < 20; i++) {
                //valid |= 1 << (i-5);
                System.out.println("Setting coord "+i+" to "
                                   +(short)Integer.parseInt(argv[i]));
                command.setElement_type_data_data_args_dest_coords_comps(
                    i-5,(short)Integer.parseInt(argv[i])
                );
            }
            //command.set_type_data_data_args_dest_coords_valid(valid);
            command.set_type_data_data_args_dest_addr((short)Integer.parseInt(argv[4]));
            command.set_type_data_data_args_dest_mode((byte)Integer.parseInt(argv[3]));
        } else {
            usage();
            System.exit(-1);
        }
        try {
          System.err.print("Sending payload: ");
                  
          for (int i = 0; i < command.dataLength(); i++) {
            System.err.print(Integer.toHexString(command.dataGet()[i] & 0xff)+ " ");
          }
          //System.err.println(command.toString());
          System.err.println();
    
    
          MoteIF mote = new MoteIF();
          //MoteIF mote = new MoteIF(PrintStreamMessenger.err);

          // Need to wait for a response message to come back
          BVRCommandInject bci = null;
          bci = new BVRCommandInject();
          BVRCommandResponseMessage response = new BVRCommandResponseMessage();
          mote.registerListener(response, bci);
          mote.send(mote_id, command);
    
          synchronized (bci) {
            if (bci.response_received == false) {
              System.err.println("Waiting for response to command...");
              bci.wait(TIMEOUT);
            }
            if (bci.response_received == false) {
              System.err.println("Warning: Timed out waiting for response to command!");
            }
          }
    
          saveSequenceNo(sequenceNo+1);
          System.exit(0);
    
        } catch(Exception e) {
                e.printStackTrace();
        }    
    
        }
    
        public void messageReceived(int dest_addr, Message m) {
          BVRCommandResponseMessage cm = (BVRCommandResponseMessage) m;
          System.out.println("Received message");
          System.out.println("Received message: "+cm);
          //System.err.println(cm); 
    
          synchronized (this) {
            response_received = true;
            this.notifyAll();
          }
    }
  
}

