package	edu.mit.mers.localization;

import java.util.*;
import java.lang.*;

public class MoteFieldRecord extends GenericRecord {
    public final String recordType() {return "motefield";}

    public MoteFieldRecord(String line, StringTokenizer lineSplitter) {
	super(line, lineSplitter);
    }
    

    public int getID() {return getInt("ID");}
    public void setID(int val) {setInt("ID", val);}

    public String getBackgroundFile() {return getString("BackgroundFile");}
    public void setBackgroundFile(String fname) {setString("BackgroundFile", fname);}
 
    public int getScreen1X() {return getInt("Screen1X");}
    public void setScreen1X(int val) {setInt("Screen1X", val);}
 
    public int getScreen1Y() {return getInt("Screen1Y");}
    public void setScreen1Y(int val) {setInt("Screen1Y", val);}
 
    public int getScreen2X() {return getInt("Screen2X");}
    public void setScreen2X(int val) {setInt("Screen2X", val);}
 
    public int getScreen2Y() {return getInt("Screen2Y");}
    public void setScreen2Y(int val) {setInt("Screen2Y", val);}

    public double getWorld1X() {return getDouble("World1X");}
    public void setWorld1X(double val) {setDouble("World1X", val);}

    public double getWorld1Y() {return getDouble("World1Y");}
    public void setWorld1Y(double val) {setDouble("World1Y", val);}

    public double getWorld2X() {return getDouble("World2X");}
    public void setWorld2X(double val) {setDouble("World2X", val);}

    public double getWorld2Y() {return getDouble("World2Y");}
    public void setWorld2Y(double val) {setDouble("World2Y", val);}

    public double getScale() {return getDouble("Scale");}
    public void setScale(double val) {setDouble("Scale", val);}

    public double getMoteSize() {return getDouble("MoteSize");}
    public void setMoteSize(double val) {setDouble("MoteSize", val);}

    public double getIconSize() {return getDouble("IconSize");}
    public void setIconSize(double val) {setDouble("IconSize", val);}
    
    public double getTrackThrow() {return getDouble("TrackThrow");}
    public void setTrackThrow(double val) {setDouble("TrackThrow", val);}

    public double getTrackDelta() {return getDouble("TrackDelta");}
    public void setTrackDelta(double val) {setDouble("TrackDelta", val);}
	
	public double getUnitDistanceScaleX() {return getDouble("UnitDistanceScaleX");}
	public double getUnitDistanceScaleY() {return getDouble("UnitDistanceScaleY");}
}


