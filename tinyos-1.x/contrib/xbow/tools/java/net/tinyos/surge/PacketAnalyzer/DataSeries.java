
/**
 * @author Jason Hil
 */

package net.tinyos.surge.PacketAnalyzer;

import net.tinyos.surge.*;
import net.tinyos.surge.event.*;
import net.tinyos.message.*;
import net.tinyos.surge.util.*;
import java.util.*;
import java.lang.*;
import java.text.*;
import javax.swing.*;
import net.tinyos.surge.Dialog.*;
import java.awt.*;



    public class DataSeries 
    {

	int max_sequence_number = 0;
	class Reading{
		int sequenceNumber;
		Object value;
	}

	int i;
	Vector data = new Vector(50);

	public int getStartSequenceNumber(){
		if(max_sequence_number == 0) return 0;
		return ((Reading)data.get(0)).sequenceNumber;}
	public int getEndSequenceNumber(){return ((Reading)data.lastElement()).sequenceNumber;}
	public int getLength(){
		if(max_sequence_number == 0) return 0;
		return getEndSequenceNumber() - getStartSequenceNumber() + 1;}

	public boolean insertNewReading(int sequenceNumber, Object value){	
		sequenceNumber = ++ i;
		//if(sequenceNumber <= max_sequence_number) return false;
		max_sequence_number = sequenceNumber;
		Reading r = new Reading();
		r.value = value;	
		r.sequenceNumber = sequenceNumber;	
		data.add(r);
		int length = getLength();
		if(length > 1000) {
			data.remove(0);
		}
		return true;



	}

	public Object getValue(int number){
		if(number >= data.size()) return null;
		return ((Reading)data.elementAt(number)).value;

	}
	public int getSequenceNumber(int number){
		if(number >= data.size()) return -1;
		return ((Reading)data.elementAt(number)).sequenceNumber;

	}


    }                                         
