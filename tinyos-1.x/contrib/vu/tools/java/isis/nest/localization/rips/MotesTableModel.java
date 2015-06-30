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

public class MotesTableModel extends javax.swing.table.DefaultTableModel {

	static String[] columnNames = {"Mote ID", "Sender", "Reply msgID", "X", "Y", "Z", "Anchor"};

	protected LocalizationData localizationData = null;
    
    void setLocalizationData(LocalizationData localizationData){
    	this.localizationData = localizationData;
    }
	
	public MotesTableModel(LocalizationData lD){
		localizationData = lD;
	}
    
    public void addNewMote( LocalizationData.Sensor newMote){
		LocalizationData.Sensor tmpMote = (LocalizationData.Sensor)localizationData.sensors.get(new Integer(newMote.getId()));
		if(tmpMote == null){
			localizationData.sensors.put(new Integer(newMote.getId()), newMote);
			fireTableDataChanged();
		}
		else{
			tmpMote.setMsgId(newMote.getMsgId());
			fireTableDataChanged();
		}
	}
	
	public int getNumberOfMotes(){
	    return localizationData.sensors.size();
	}
	
	public Class getColumnClass(int columnIndex) {
		if (columnIndex == 1 || columnIndex == 6)
			return Boolean.class;
		
		if(columnIndex == 0 || columnIndex == 2)
			return Integer.class;
		
		return String.class;
	}

	public void removeRow(int row) {
		if (row < localizationData.sensors.size()) {
			localizationData.sensors.remove(new Integer(getMoteInRow(row).getId()));
		}
	}
	
	public int getColumnCount() {
		return columnNames.length;
	};

	public String getColumnName(int column) {
		return columnNames[column];
	}

	public int getRowCount() {
		if (localizationData!=null && localizationData.sensors != null) {
			return localizationData.sensors.size()+1;
		}
		return 1;
	}
	
	public LocalizationData.Sensor getMoteInRow(int row){
		if (row<localizationData.sensors.size()){
			Integer key = new Integer( Integer.parseInt(getValueAt(row, 0).toString()) );
			if (key != null)
				return (LocalizationData.Sensor) localizationData.sensors.get(key);
		}
		return null;
	}

	public Object getValueAt(int row, int column) {
		LocalizationData.Sensor mote;
		if (row < localizationData.sensors.size()) {
			Object[] motes = localizationData.sensors.values().toArray();
			mote = (LocalizationData.Sensor)motes[row];
		}
		else 
			mote = null;
		
		if (mote == null){
			if(column == 1 || column == 6)
				return new Boolean(false);
			else
				return "";
		}	
		Object value = null;
		try{
		switch(column){
		
			case 0:	value = Integer.toString(mote.getId()); break;
			case 1: value = new Boolean(mote.isSender()); break;
			case 2: value = Integer.toString(mote.getMsgId());break;
			case 3: value = Double.toString(mote.getPos().x); break;
			case 4: value = Double.toString(mote.getPos().y); break;
			case 5: value = Double.toString(mote.getPos().z); break;
			case 6: value = new Boolean(mote.isAnchor()); break;
			default: value = null;break;
		};
		}
		catch (Exception e){
			System.out.println("Mote panel parsing error at "+row+","+column);
		}

		return value;
	}
	
	public void setValueAt(Object aValue, int row, int column) {
		LocalizationData.Sensor mote = null;
		
		try{
			if (row < localizationData.sensors.size()) {
				mote = getMoteInRow(row);
				switch(column){
					case 0: mote.setId(Integer.parseInt(aValue.toString())); break;
					case 1: mote.setSender(((Boolean)aValue).booleanValue()); break;
					case 3: mote.setX(Double.parseDouble(aValue.toString())); break;
					case 4: mote.setY(Double.parseDouble(aValue.toString())); break;
					case 5: mote.setZ(Double.parseDouble(aValue.toString())); break;
					case 6: mote.setAnchor(((Boolean)aValue).booleanValue()); break;
					default: break;
				};
			} 
			else {
				if (column == 0){
					mote = new LocalizationData.Sensor( ((Integer)aValue).intValue());
					addNewMote(mote);
				}
			}
		}
		catch (Exception e){
			System.out.println("Mote panel parsing error at "+row+","+column);
		}
	}

	public boolean isCellEditable(int row, int column) {
		if (row == localizationData.sensors.size()){
			if(column == 0) 
				return true;
			else
				return false;
		} 
		else if (column == 2) {
			return false; 
		}
		return true;
	}
}
