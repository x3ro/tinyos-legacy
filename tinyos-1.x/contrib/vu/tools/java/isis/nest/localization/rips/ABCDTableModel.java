/*
 * Copyright (c) 2005, Vanderbilt University
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for instruction and non-commercial research only, without
 * fee, and without written agreement is hereby granted, provided that the
 * this copyright notice including the following two paragraphs and the 
 * author's name appear in all copies of this software.
 * 
 * IN NO EVENT SHALL VANDERBILT UNIVERSITY BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF VANDERBILT
 * UNIVERSITY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * VANDERBILT UNIVERSITY SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND VANDERBILT UNIVERSITY HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.
 */
 // @author Brano Kusy: kusy@isis.vanderbilt.edu
 
package isis.nest.localization.rips;

import java.util.Iterator;
import java.util.Vector;

import javax.swing.table.DefaultTableModel;

/**
 * @author brano
 *
 */
public class ABCDTableModel extends DefaultTableModel {

    protected LocalizationData localizationData = null;
    protected boolean filterOutBad = false;
    public void setFilterOutBad(boolean value){
    	filterOutBad = value;
    }
    void setLocalizationData(LocalizationData localizationData){
    	this.localizationData = localizationData;
    }

    public ABCDTableModel(LocalizationData lD){
		localizationData = lD;
	}
	
	void writeRow(ABCDMeasurement abcdMeasurement, int index)
	{
        //System.out.println("writeRow, idx:"+index+", columns:"+getColumnCount()+", row  s:"+getRowCount());
        setValueAt(Integer.toString(abcdMeasurement.sensor_A), index, 0);
        setValueAt(Integer.toString(abcdMeasurement.sensor_B), index, 1);
        setValueAt(Integer.toString(abcdMeasurement.sensor_C), index, 2);
        setValueAt(Integer.toString(abcdMeasurement.sensor_D), index, 3);

        setValueAt(Integer.toString(abcdMeasurement.phaseOffsetMeasurments.size()), index, 4);

        java.text.DecimalFormat df = new java.text.DecimalFormat("##0.0###");
        setValueAt(df.format(abcdMeasurement.calc_dist), index, 5);
        setValueAt(df.format(abcdMeasurement.dist_dev), index, 6);
        setValueAt(df.format(abcdMeasurement.real_dist), index, 7);
        setValueAt(df.format(abcdMeasurement.error), index, 8);
        
	}

	void writeRow(ABCDMeasurement abcdMeasurement)
	{
		int index = findReplaceIndex(abcdMeasurement);
		if( index < 0 )
		{
			index = getRowCount();
			setRowCount(index+1);

    		writeRow(abcdMeasurement, index);
	    	fireTableRowsInserted(index, index);
		}
		writeRow(abcdMeasurement, index);
		fireTableRowsUpdated(index, index);
	}

	int findReplaceIndex(ABCDMeasurement m){
	    for(int i = 0; i < getRowCount(); ++i){
            try{
                if ( m.sensor_A == Integer.parseInt((String)getValueAt(i, 0)) 
                		&& m.sensor_B == Integer.parseInt((String)getValueAt(i, 1))
                		&& m.sensor_C == Integer.parseInt((String)getValueAt(i, 2))
                		&& m.sensor_D == Integer.parseInt((String)getValueAt(i, 3)))
						
    	    		    return i;
    		}
    		catch( Exception e){
    		    System.out.println("parsing error in ABCDTableModel / findReplaceIndex!");
    		}
		}
                
        return -1;
    }

	void addMeasurementEntry(LocalizationData.MeasurementEntry mE){
		int idx1 = localizationData.abcd_measurements.size();
		localizationData.addABCDMeasurements(mE.masterID, mE.seqNumber);
		int idx2 = localizationData.abcd_measurements.size()-1;
		for (int i=idx2; i>=idx1; i--){
			ABCDMeasurement abcd = (ABCDMeasurement)localizationData.abcd_measurements.get(i);
			localizationData.computeRange(abcd);
			if (abcd.valid)
				writeRow((ABCDMeasurement)localizationData.abcd_measurements.get(i));
			else
				localizationData.abcd_measurements.remove(i);
		}
	}
	
	void writeAll(){
        Iterator it = localizationData.abcd_measurements.iterator();
        setRowCount(localizationData.abcd_measurements.size());
        int i = 0;
        while (it.hasNext())
            writeRow((ABCDMeasurement)it.next(),i++);
	}

	void recalculateAll(){
		resetTable();
		localizationData.createABCDMeasurements();
		localizationData.computeRanges();
		if (filterOutBad)
			localizationData.cheatFilter();
		writeAll();
//		fireTableDataChanged();
	}
	
	void resetTable(){
		setRowCount(0);
		resetEntries();
	}
	
	void resetEntries()
	{
	    Vector vector = new Vector();
	    vector.add("A");
	    vector.add("B");
	    vector.add("C");
	    vector.add("D");
	    vector.add("#offsets");
	    vector.add("calcDist");
	    vector.add("internError");
	    vector.add("realDist");
	    vector.add("error");
            		    
	    setColumnIdentifiers(vector);        
		fireTableStructureChanged();
	}
	
	
}
