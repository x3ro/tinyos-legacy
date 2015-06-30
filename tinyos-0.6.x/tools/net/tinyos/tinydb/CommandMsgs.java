package net.tinyos.tinydb;

/** Class with static functions to generate message arrays that
    can be used to invoke commands on Db motes.
*/
public class CommandMsgs {
    /** AM Message ID used for command messages */
    public static final byte CMD_MSG_TYPE = 103;

    /** The reset command resets motes (like toggling the power switch 
     @param targetId The id of the mote that should receive this message 
    */
    public static byte[] resetCmd(short targetId) {
	byte cmdMessage[] = new byte[30];
	
	cmdMessage[0] = (byte)(targetId & 0xFF);
	cmdMessage[1] = (byte)((targetId & 0xFF00) >> 8);

	cmdMessage[2] = 'R';
	cmdMessage[3] = 'e';
	cmdMessage[4] = 's';
	cmdMessage[5] = 'e';
	cmdMessage[6] = 't';
	cmdMessage[7] = 0;
		      
	return cmdMessage;

	
    }

    /** Sets the length of the log (number of messages returned by dump log
	@deprecated
     */
    public static byte[] setLogLen(short targetId, short offset) {
	byte cmdMessage[] = new byte[30];

	cmdMessage[0] = (byte)(targetId & 0xFF);
	cmdMessage[1] = (byte)((targetId & 0xFF00) >> 8);

	cmdMessage[2] = 'R';
	cmdMessage[3] = 'e';
	cmdMessage[4] = 's';
	cmdMessage[5] = 'e';
	cmdMessage[6] = 't';
	cmdMessage[7] = 'L';
	cmdMessage[8] = 'o';
	cmdMessage[9] = 'g';
	cmdMessage[10] = 0x0;	

	cmdMessage[11] = (byte)(offset & 0xFF);
	cmdMessage[12] = (byte)((targetId & 0xFF00) >> 8);

	return cmdMessage;



    }

    /** Causes the mote to spill the current contents of the EEPROM log 
     @deprecated
     */
    public static byte[] dumpLog(short targetId) {
	byte cmdMessage[] = new byte[30];

	cmdMessage[0] = (byte)(targetId & 0xFF);
	cmdMessage[1] = (byte)((targetId & 0xFF00) >> 8);
	
	cmdMessage[2] = 'D';
	cmdMessage[3] = 'u';
	cmdMessage[4] = 'm';
	cmdMessage[5] = 'p';
	cmdMessage[6] = 'L';
	cmdMessage[7] = 'o';
	cmdMessage[8] = 'g';
	cmdMessage[9] = 0x0;
	cmdMessage[10] = 0x0;
	cmdMessage[11] = 0x0;
	
	return cmdMessage;



    }

    /** Constrains the network topology to have the specified fanout 
	@param targetId The ID of the mote that should receive this message
	@param fanout The topology fanout.  Motes are constrained to choose
	one of fanout parents (e.g. if fanout = 2, mote id 3 can pick motes
	1 or 2 as a parent.)
     */
    public static byte[] setFanout(short targetId, char fanout) {
	byte cmdMessage[] = new byte[30];

	cmdMessage[0] = (byte)(targetId & 0xFF);
	cmdMessage[1] = (byte)((targetId & 0xFF00) >> 8);
	cmdMessage[2] = 'S';
	cmdMessage[3] = 'e';
	cmdMessage[4] = 't';
	cmdMessage[5] = 'T';
	cmdMessage[6] = 'o';
	cmdMessage[7] = 'p';
	cmdMessage[8] = 'o';
	cmdMessage[9] = 0x0;
	cmdMessage[10] = (byte)fanout;

	return cmdMessage;
    }

    /** Sets the value of the radio strength potentiometer (0 - 100), 0 is largest
     @param targetId The recipient of this message
    @param pot The value of the potentiometer*/
    public static byte[] setPot(short targetId, char pot) {
	byte cmdMessage[] = new byte[30];

	cmdMessage[0] = (byte)(targetId & 0xFF);
	cmdMessage[1] = (byte)((targetId & 0xFF00) >> 8);
	cmdMessage[2] = 'S';
	cmdMessage[3] = 'e';
	cmdMessage[4] = 't';
	cmdMessage[5] = 'P';
	cmdMessage[6] = 'o';
	cmdMessage[7] = 't';

	cmdMessage[8] = 0;
	cmdMessage[9] = (byte)pot;

	return cmdMessage;


    }

    /** Enabled "centralized" routing, where no aggregation is performed in network
	and data is simply forwarded to the root.
    */
    public static byte[] setCentralized(short targetId, boolean centralized) {
	byte cmdMessage[] = new byte[30];

	cmdMessage[0] = (byte)(targetId & 0xFF);
	cmdMessage[1] = (byte)((targetId & 0xFF00) >> 8);

	cmdMessage[2] = 'S';
	cmdMessage[3] = 'e';
	cmdMessage[4] = 't';
	cmdMessage[5] = 'C';
	cmdMessage[6] = 'e';
	cmdMessage[7] = 'n';
	cmdMessage[8] = 't';
	cmdMessage[9] = 0x0;
	cmdMessage[10] = centralized?(byte)1:(byte)0;

	return cmdMessage;
    }

    
    /** Fixed comm means that motes transmit in in the time slot corresponding to their
	local id * 2;  unfixed comm means mote xmit in a random slot selected uniformly
	in the range (0 .. local cell size estimate)
    */
    public static byte[] setFixedComm(short targetId, boolean fixed) {
	byte cmdMessage[] = new byte[30];

	cmdMessage[0] = (byte)(targetId & 0xFF);
	cmdMessage[1] = (byte)((targetId & 0xFF00) >> 8);

	cmdMessage[2] = 'F';
	cmdMessage[3] = 'i';
	cmdMessage[4] = 'x';
	cmdMessage[5] = 'C';
	cmdMessage[6] = 'o';
	cmdMessage[7] = 'm';
	cmdMessage[8] = 'm';
	cmdMessage[9] = 0x0;
	cmdMessage[10] = fixed?(byte)1:(byte)0;

	return cmdMessage;
    }
    
    /** Stop the magnetometer from oversampling (for power conservation)*/
    public static byte[] stopMagCmd(short targetId) {
	byte cmdMessage[] = new byte[30];
	
	cmdMessage[0] = (byte)(targetId & 0xFF);
	cmdMessage[1] = (byte)((targetId & 0xFF00) >> 8);

	cmdMessage[2] = 'S';
	cmdMessage[3] = 't';
	cmdMessage[4] = 'o';
	cmdMessage[5] = 'p';
	cmdMessage[6] = 'M';
	cmdMessage[7] = 'a';
	cmdMessage[8] = 'g';
	cmdMessage[9] = 0;
		      
	return cmdMessage;
	
    }
}
