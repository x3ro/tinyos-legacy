package	edu.mit.mers.localization;

import java.util.*;
import java.lang.*;

public class TagRecord extends GenericRecord {
    public final String recordType() {return "tag";}

    public TagRecord(String line, StringTokenizer lineSplitter) {
	super(line, lineSplitter);
    }

    public TagRecord(Tag t) {
	super();
	setID(t.getID());
	setTagType(t.getTagType());
    }

    public int getID() {return getInt("ID");}
    public void setID(int val) {setInt("ID", val);}

    public int getTagType() {return getInt("TagType");}
    public void setTagType(int val) {setInt("TagType", val);}
}


