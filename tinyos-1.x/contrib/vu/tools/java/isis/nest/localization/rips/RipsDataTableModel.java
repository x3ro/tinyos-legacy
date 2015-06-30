/*
 * Copyright (c) 2005, Vanderbilt University
 * All rights reserved.
 *
 * Permission to use, copy,	modify,	and	distribute this	software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided	that the above copyright notice, the following
 * two paragraphs and the author appear	in all copies of this software.
 * 
 * IN NO EVENT SHALL THE VANDERBILT	UNIVERSITY BE LIABLE TO	ANY	PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE VANDERBILT
 * UNIVERSITY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE VANDERBILT UNIVERSITY SPECIFICALLY DISCLAIMS	ANY	WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF	MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR	PURPOSE.  THE SOFTWARE PROVIDED	HEREUNDER IS
 * ON AN "AS IS" BASIS,	AND	THE	VANDERBILT UNIVERSITY HAS NO OBLIGATION	TO
 * PROVIDE MAINTENANCE,	SUPPORT, UPDATES, ENHANCEMENTS,	OR MODIFICATIONS.
 *
 * @author Brano Kusy, kusy@isis.vanderbilt.edu
 * @modified 04/11/05
 */

package isis.nest.localization.rips;

import javax.swing.table.*;
import java.util.*;

class RipsDataTableModel extends DefaultTableModel
{
    static final int NUM_CHANNELS = 55;
    static final int PACKET_LENGTH = 24;
	static final int PACKET_DATA = 5;

    protected boolean collapseMotes = false;
    protected boolean showPhase = true;
    protected LocalizationData localizationData = null;
    
    void setLocalizationData(LocalizationData localizationData){
    	this.localizationData = localizationData;
    }

    public RipsDataTableModel(LocalizationData lD){
		localizationData = lD;
	}

	class PacketMeasurement{
        int channel;
        double frequency;
        double phase;
        int minRSSI;
    }
    class Packet
    {
        final int NUM_MEASUREMENTS = 7;
        int moteSequenceNumber;
        int slaveID;
        PacketMeasurement packetMeasurement[];
        Packet(){
            packetMeasurement = new PacketMeasurement[NUM_MEASUREMENTS];
            for (int i=0; i<NUM_MEASUREMENTS; i++)
                packetMeasurement[i] = new PacketMeasurement();
        }
    }

    protected static java.text.SimpleDateFormat timestamp = new java.text.SimpleDateFormat("HH:mm:ss.SS");
	
    // The main storage that stores all measurements

	Packet getPacket(byte[] bytePacket)
	{
	    int packetIndex = PACKET_DATA;
	    Packet packet = new Packet();

	    packet.moteSequenceNumber = (bytePacket[packetIndex++] & 0xFF);
	    packet.slaveID =  (bytePacket[packetIndex++] & 0xFF) + ((bytePacket[packetIndex++] & 0xFF) << 8);
	    
	    for (int i=0; i<packet.NUM_MEASUREMENTS; i++){
	   	    byte byte6 = (byte)(bytePacket[packetIndex++] & 0xFF);
	        byte byte7 = (byte)(bytePacket[packetIndex++] & 0xFF);

    	    packet.packetMeasurement[i].channel = (byte7&0xff) >> 2;
	        packet.packetMeasurement[i].frequency = (((byte7 & 0xff)<<8) | byte6&0xff)/65536.0*4096.0*16.0;
	        packet.packetMeasurement[i].phase = (double)(bytePacket[packetIndex++] & 0xFF)/256.0*2.0*Math.PI;
	    }

	    return packet;
	}

	void writeRow(LocalizationData.MeasurementEntry measurementEntry, LocalizationData.SlaveEntry slaveEntry, int index)
	{
        //System.out.println("writeRow, idx:"+index+", columns:"+getColumnCount()+", row  s:"+getRowCount());
	    if (collapseMotes){
	        setValueAt(measurementEntry.time, index, 0);
		    setValueAt(Integer.toString(measurementEntry.seqNumber), index, 1);
		    setValueAt(Integer.toString(measurementEntry.masterID), index, 2);
		    setValueAt(Integer.toString(measurementEntry.assistantID), index, 3);
		    setValueAt(Integer.toString(measurementEntry.slaves.size()), index, 4);
		}
		else{
	        setValueAt(measurementEntry.time, index, 0);
		    setValueAt(Integer.toString(measurementEntry.seqNumber), index, 1);
		    setValueAt(Integer.toString(measurementEntry.masterID), index, 2);
		    setValueAt(Integer.toString(measurementEntry.assistantID), index, 3);
		    if (slaveEntry != null)
    		    setValueAt(Integer.toString(slaveEntry.slaveID), index, 4);
            else
    		    setValueAt("null", index, 4);
		    for (int i = 5; i<5+NUM_CHANNELS; i++){
		        if (slaveEntry == null || slaveEntry.channels[i-5] == null)
		            setValueAt("null", index, i);
		        else{
		            String string;
		            if (showPhase)
		               string = Double.toString( ((LocalizationData.ChannelEntry)slaveEntry.channels[i-5]).phase );
		            else
		               string = Double.toString( ((LocalizationData.ChannelEntry)slaveEntry.channels[i-5]).frequency );
		            if (string.length()>=5)
		                string = string.substring(0,5);
		            setValueAt( string, index, i);    
		        }
            }
	    }
	}
	
	int writeRow(LocalizationData.MeasurementEntry measurementEntry, int index)
	{
	    int index_ = index;
        Set keys = measurementEntry.slaves.keySet();
	    if (collapseMotes || keys.isEmpty()){
            writeRow(measurementEntry, null, index_);
            ++index_;
        }
		else{
            Iterator iter = keys.iterator();
            while (iter.hasNext()){
                Object key = iter.next();
                LocalizationData.SlaveEntry sE = (LocalizationData.SlaveEntry)(measurementEntry.slaves.get(key));
		        writeRow(measurementEntry, sE, index_);
		        ++index_;
		    }
	    }
	    return index_;
	}
	
    void writeRows(){
        int index = 0;
		setRowCount(0);
        Set keys = localizationData.measurements.keySet();
        Iterator iter = keys.iterator();
        while (iter.hasNext()){
            Object key = iter.next();
            LocalizationData.MeasurementEntry mE = (LocalizationData.MeasurementEntry)(localizationData.measurements.get(key));
            if (collapseMotes || mE.slaves.isEmpty())
			    setRowCount(index+1);
            else
			    setRowCount(index+mE.slaves.size());
            index = writeRow(mE, index);
        }        
    }

    static String getTimestamp(){
		return timestamp.format(new java.util.Date());
	}

    LocalizationData.SlaveEntry getSlaveEntryByRow(int row){
	    int	seqNum = Integer.parseInt((getValueAt(row,1).toString()));
	    int	master = Integer.parseInt((getValueAt(row,2).toString()));
	    int	assist = Integer.parseInt((getValueAt(row,3).toString()));
	    int	slave  = Integer.parseInt((getValueAt(row,4).toString()));
    	LocalizationData.MeasurementEntry mE = 
    		(LocalizationData.MeasurementEntry)localizationData.measurements.get(LocalizationData.getMeasurementKey(master,seqNum)); 
		
    	if (mE==null)
    		return null;

    	if (collapseMotes){
            Iterator it = mE.slaves.values().iterator();
            while (it.hasNext())
            {
                LocalizationData.SlaveEntry sE = (LocalizationData.SlaveEntry)it.next();
                if (sE.valid)
                    return sE;
            }
            return null;
    	}
    	
    	LocalizationData.SlaveEntry sE = (LocalizationData.SlaveEntry)mE.slaves.get(new Integer(slave));
    	
    	return sE;
    }
    
    void addPacket(int sequenceNumber, int masterID, int assistantID, int moteSequenceNumber, byte[] bytePacket)
	{
        Packet packet = getPacket(bytePacket);
        
        if (packet == null || packet.moteSequenceNumber != moteSequenceNumber)
        	//old value
        	return;

        LocalizationData.MeasurementEntry measurementEntry = 
        	(LocalizationData.MeasurementEntry)localizationData.measurements.get(LocalizationData.getMeasurementKey(masterID, sequenceNumber));
        if (measurementEntry == null){
            measurementEntry = new LocalizationData.MeasurementEntry();
            measurementEntry.time = getTimestamp();
            measurementEntry.masterID = masterID;
            measurementEntry.assistantID = assistantID;
            measurementEntry.seqNumber = sequenceNumber;
            measurementEntry.slaves = new TreeMap();
            localizationData.measurements.put(LocalizationData.getMeasurementKey(masterID,sequenceNumber), measurementEntry);
        }
    
        LocalizationData.SlaveEntry slaveEntry = (LocalizationData.SlaveEntry)measurementEntry.slaves.get(new Integer(packet.slaveID));
        if (slaveEntry == null){

            slaveEntry = new LocalizationData.SlaveEntry();
            slaveEntry.slaveID = packet.slaveID;
            slaveEntry.channels = new LocalizationData.ChannelEntry[NUM_CHANNELS];
            for (int i=0; i<NUM_CHANNELS; i++)
                slaveEntry.channels[i]=null;

            measurementEntry.slaves.put(new Integer(packet.slaveID), slaveEntry);
        }

        for (int i=0; i<packet.NUM_MEASUREMENTS; i++){
            LocalizationData.ChannelEntry channelEntry = new LocalizationData.ChannelEntry();
            channelEntry.frequency = packet.packetMeasurement[i].frequency;
            channelEntry.phase = packet.packetMeasurement[i].phase;
            channelEntry.minRSSI = packet.packetMeasurement[i].minRSSI;
            channelEntry.valid = true;
        
            //System.out.println("channel:"+packet.channel+", entry:"+channelEntry.phase);
            if (channelEntry.frequency != 0)
                slaveEntry.channels[packet.packetMeasurement[i].channel] = channelEntry;
        }
        
		int index = findReplaceIndex(measurementEntry, slaveEntry);
		if( index < 0 ){
			index = getRowCount();
			setRowCount(index+1);
		}

		writeRow(measurementEntry, slaveEntry , index);
		fireTableRowsUpdated(index, index);
	}

    int findReplaceIndex(LocalizationData.MeasurementEntry mE, LocalizationData.SlaveEntry sE){
    	//this is price i have to pay for having different data struct (localizationData) and tableModel (new data always apear at the end)
	    for(int i = 0; i < getRowCount(); ++i){
            try{
                if ( mE.seqNumber == Integer.parseInt((String)getValueAt(i, 1)) && mE.masterID == Integer.parseInt((String)getValueAt(i, 2))){
        		    if (collapseMotes || sE == null || ((String)getValueAt(i,4)).equals("null") || sE.slaveID == Integer.parseInt((String)getValueAt(i, 4))){
        		    	return i;
    		    	}
    		    }
    		}
    		catch( Exception e){
    		    System.out.println("ERROR!!!!!! couldn't parse integer in findReplaceIndex fcion!");
    		}
		}
                
        return -1;
    }

    void resetTable(){
		setRowCount(0);
		resetEntries();
	}
	
	void resetEntries()
	{
	    Vector vector = new Vector();
	    vector.add("Time");
	    vector.add("SeqN");
	    vector.add("master");
	    vector.add("assist");
	    if (collapseMotes)
		    vector.add("#slvs");
        else
		    vector.add("slave");
            		    
		if (!collapseMotes){
	        for (int i=0; i<NUM_CHANNELS; i++)
	            vector.add("CH"+(i+1));
	    }
	            
	    setColumnIdentifiers(vector);        
		fireTableStructureChanged();
	}
	
	void readFromFile(String fileBaseName, boolean readRanges) throws Exception {
		resetTable();
		resetEntries();
		try{
			if (!readRanges)
				localizationData.read(fileBaseName);
			else
				localizationData.readRangeFile(fileBaseName);
		}
		catch(Exception e){
			throw e;
		}
		writeRows();
	}

	void saveToFile(String fileBaseName) throws Exception {
		try{
			localizationData.write(fileBaseName);
		}
		catch(Exception e){
			throw e;
		}
	}
	
/*	void removeRows(int[] rows)
	{
		int i = rows.length;
		while( --i >= 0 )
			removeRow(rows[i]);
		
		fireTableDataChanged();
	}*/
}
