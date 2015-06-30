package	edu.mit.mers.localization;

import java.util.*;
import java.lang.*;

public class MoteRecord extends GenericRecord {
    public final String recordType() {return "mote";}

    public MoteRecord(String line, StringTokenizer lineSplitter) {
	super(line, lineSplitter);
    }

    public MoteRecord(Node n) {
	super();
	setID(n.getID());
	setX(n.getX());
	setY(n.getY());
	setPot(n.getPotValue());
	setMoteType(n.getMoteType());
    }

    public double getX() {return getDouble("X");}
    public void setX(double val) {setDouble("X", val);}

    public double getY() {return getDouble("Y");}
    public void setY(double val) {setDouble("Y", val);}

    public int getID() {return getInt("ID");}
    public void setID(int val) {setInt("ID", val);}

    public int getMoteType() {return getInt("MoteType");}
    public void setMoteType(int val) {setInt("MoteType", val);}

    public int getPot() {return getInt("pot");}
    public void setPot(int pot) {setInt("pot", pot);}

    public String getName() {return getString("Name");}
    public void setName(String val) {setString("Name", val);}
}


