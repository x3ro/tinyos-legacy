package net.tinyos.tinydb;

import net.tinyos.message.*;

/** Class with static functions to generate message arrays that
    can be used to invoke commands on Db motes.
*/
public class CommandMsgs {
    /** AM Message ID used for command messages */
    public static final byte CMD_MSG_TYPE = 103;

    /** The reset command resets motes (like toggling the power switch 
     @param targetId The id of the mote that should receive this message 
    */
    public static Message resetCmd(short targetId) {
	CommandMsg cmdMessage = new CommandMsg(9);

	cmdMessage.set_nodeid(targetId);
	cmdMessage.set_fromBase((short)1);
	cmdMessage.setElement_data(0,(byte)'R');
	cmdMessage.setElement_data(1,(byte)'e');
	cmdMessage.setElement_data(2,(byte)'s');
	cmdMessage.setElement_data(3,(byte)'e');
	cmdMessage.setElement_data(4,(byte)'t');
	cmdMessage.setElement_data(5,(byte)0);
		      
	return cmdMessage;

	
    }

    /** Sets the length of the log (number of messages returned by dump log
	@deprecated
     */
    public static Message setLogLen(short targetId, short offset) {
	CommandMsg cmdMessage = new CommandMsg(14);

	cmdMessage.set_nodeid(targetId);
	cmdMessage.set_fromBase((short)1);
	cmdMessage.setElement_data(0,(byte)'R');
	cmdMessage.setElement_data(1,(byte)'e');
	cmdMessage.setElement_data(2,(byte)'s');
	cmdMessage.setElement_data(3,(byte)'e');
	cmdMessage.setElement_data(4,(byte)'t');
	cmdMessage.setElement_data(5,(byte)'L');
	cmdMessage.setElement_data(6,(byte)'o');
	cmdMessage.setElement_data(7,(byte)'g');
	cmdMessage.setElement_data(8, (byte)0);
	cmdMessage.setElement_data(9, (byte)(offset & 0xFF));
	cmdMessage.setElement_data(10,(byte)((targetId & 0xFF00) >> 8));

	return cmdMessage;



    }

    /** Causes the mote to spill the current contents of the EEPROM log 
     @deprecated
     */
    public static Message dumpLog(short targetId) {
	CommandMsg cmdMessage = new CommandMsg(13);

	cmdMessage.set_nodeid(targetId);
	cmdMessage.set_fromBase((short)1);
	cmdMessage.setElement_data(0,(byte)'D');
	cmdMessage.setElement_data(1,(byte)'u');
	cmdMessage.setElement_data(2,(byte)'m');
	cmdMessage.setElement_data(3,(byte)'p');
	cmdMessage.setElement_data(4,(byte)'L');
	cmdMessage.setElement_data(5,(byte)'o');
	cmdMessage.setElement_data(6,(byte)'g');
	cmdMessage.setElement_data(7,(byte)0);
	cmdMessage.setElement_data(8,(byte)0);
	cmdMessage.setElement_data(9,(byte)0);
	
	return cmdMessage;



    }

    /** Constrains the network topology to have the specified fanout 
	@param targetId The ID of the mote that should receive this message
	@param fanout The topology fanout.  Motes are constrained to choose
	one of fanout parents (e.g. if fanout = 2, mote id 3 can pick motes
	1 or 2 as a parent.)
     */
    public static Message setFanout(short targetId, char fanout) {
	CommandMsg cmdMessage = new CommandMsg(12);
	cmdMessage.set_nodeid(targetId);
	cmdMessage.set_fromBase((short)1);
	cmdMessage.setElement_data(0,(byte)'S');
	cmdMessage.setElement_data(1,(byte)'e');
	cmdMessage.setElement_data(2,(byte)'t');
	cmdMessage.setElement_data(3,(byte)'T');
	cmdMessage.setElement_data(4,(byte)'o');
	cmdMessage.setElement_data(5,(byte)'p');
	cmdMessage.setElement_data(6,(byte)'o');
	cmdMessage.setElement_data(7,(byte)0);
	cmdMessage.setElement_data(8,(byte)fanout);

	return cmdMessage;
    }

    /** Sets the value of the radio strength potentiometer (0 - 100), 0 is largest
     @param targetId The recipient of this message
    @param pot The value of the potentiometer*/
    public static Message setPot(short targetId, char pot) {
	CommandMsg cmdMessage = new CommandMsg(11);

	cmdMessage.set_nodeid(targetId);
	cmdMessage.set_fromBase((short)1);

	cmdMessage.setElement_data(0,(byte)'S');
	cmdMessage.setElement_data(1,(byte)'e');
	cmdMessage.setElement_data(2,(byte)'t');
	cmdMessage.setElement_data(3,(byte)'P');
	cmdMessage.setElement_data(4,(byte)'o');
	cmdMessage.setElement_data(5,(byte)'t');
	cmdMessage.setElement_data(6,(byte)0);
	cmdMessage.setElement_data(7,(byte)pot);

	return cmdMessage;


    }

    /** Enabled "centralized" routing, where no aggregation is performed in network
	and data is simply forwarded to the root.
    */
    public static Message setCentralized(short targetId, boolean centralized) {
	CommandMsg cmdMessage = new CommandMsg(12);

	cmdMessage.set_nodeid(targetId);
	cmdMessage.set_fromBase((short)1);

	cmdMessage.setElement_data(0,(byte)'S');
	cmdMessage.setElement_data(1,(byte)'e');
	cmdMessage.setElement_data(2,(byte)'t');
	cmdMessage.setElement_data(3,(byte)'C');
	cmdMessage.setElement_data(4,(byte)'e');
	cmdMessage.setElement_data(5,(byte)'n');
	cmdMessage.setElement_data(6,(byte)'t');
	cmdMessage.setElement_data(7,(byte)0);
	cmdMessage.setElement_data(8,centralized?(byte)1:(byte)0);

	return cmdMessage;
    }

    
    /** Fixed comm means that motes transmit in in the time slot corresponding to their
	local id * 2;  unfixed comm means mote xmit in a random slot selected uniformly
	in the range (0 .. local cell size estimate)
    */
    public static Message setFixedComm(short targetId, boolean fixed) {
	CommandMsg cmdMessage = new CommandMsg(12);

	cmdMessage.set_nodeid(targetId);
	cmdMessage.set_fromBase((short)1);

	cmdMessage.setElement_data(0,(byte)'F');
	cmdMessage.setElement_data(1,(byte)'i');
	cmdMessage.setElement_data(2,(byte)'x');
	cmdMessage.setElement_data(3,(byte)'C');
	cmdMessage.setElement_data(4,(byte)'o');
	cmdMessage.setElement_data(5,(byte)'m');
	cmdMessage.setElement_data(6,(byte)'m');
	cmdMessage.setElement_data(7,(byte)0);
	cmdMessage.setElement_data(8,fixed?(byte)1:(byte)0);

	return cmdMessage;
    }
    
    /** Stop the magnetometer from oversampling (for power conservation)*/
    public static Message stopMagCmd(short targetId) {
	CommandMsg cmdMessage = new CommandMsg(11);

	cmdMessage.set_nodeid(targetId);
	cmdMessage.set_fromBase((short)1);
	cmdMessage.setElement_data(0,(byte)'S');
	cmdMessage.setElement_data(1,(byte)'t');
	cmdMessage.setElement_data(2,(byte)'o');
	cmdMessage.setElement_data(3,(byte)'p');
	cmdMessage.setElement_data(4,(byte)'M');
	cmdMessage.setElement_data(5,(byte)'a');
	cmdMessage.setElement_data(6,(byte)'g');
	cmdMessage.setElement_data(7,(byte)0);
		      
	return cmdMessage;
	
    }

    public static Message setSounderCmd(short targetId) {
	CommandMsg cmdMessage = new CommandMsg(12);

	cmdMessage.set_nodeid(targetId);

	cmdMessage.set_fromBase((short)1);
	cmdMessage.setElement_data(0,(byte)'S');
	cmdMessage.setElement_data(1,(byte)'e');
	cmdMessage.setElement_data(2,(byte)'t');
	cmdMessage.setElement_data(3,(byte)'S');
	cmdMessage.setElement_data(4,(byte)'n');
	cmdMessage.setElement_data(5,(byte)'d');
	cmdMessage.setElement_data(6,(byte)0);
	cmdMessage.setElement_data(7,(byte)0);
	cmdMessage.setElement_data(8,(byte)2);
		      
	return cmdMessage;
	
    }

    public static Message addAttrCmd(short targetId, char[] name, byte t, long val) {
      int namelen = name.length;
      int offset = 0;
      String cmd = "addattr";
      int cmdlen = cmd.length();

      if (namelen > 8) namelen = 8;

      CommandMsg cmdMessage = new CommandMsg(cmdlen + 1 /*null term*/
					     + namelen + 1 /*null term*/ 
					     + 5 /* t and val */ + 2 /*targetId*/ + 1 /* is from base */);
      cmdMessage.set_nodeid(targetId);
      
      cmdMessage.set_fromBase((short)1);
      for (int i = 0; i < cmdlen; i++) {
	cmdMessage.setElement_data(offset++, (byte)cmd.charAt(i));
      }
      cmdMessage.setElement_data(offset++, (byte)0); //null term
      for (int i =0; i < namelen; i++) {
	cmdMessage.setElement_data(offset++, (byte)name[i]);
      }
      cmdMessage.setElement_data(offset++, (byte)0); //null term
      cmdMessage.setElement_data(offset++,t); //type
      cmdMessage.setElement_data(offset++,(byte)(val & 0xFF));
      cmdMessage.setElement_data(offset++,(byte)((val & 0xFF00) >> 8));
      cmdMessage.setElement_data(offset++,(byte)((val & 0xFF0000) >> 16));
      cmdMessage.setElement_data(offset++,(byte)((val & 0xFF000000) >> 24));

      return cmdMessage;
    }
}
