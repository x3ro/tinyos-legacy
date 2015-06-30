package net.tinyos.social.names;

import javax.swing.DefaultListModel;
import java.util.Enumeration;

class UserDB extends DefaultListModel
{
    Sql sql;
    DefaultListModel names;

    MoteInfo add(int moteId) {
	MoteInfo m = add(new MoteInfo(moteId));
	sql.addMote(m.moteId, m.name);
	return m;
    }

    MoteInfo add(MoteInfo m) {
	// Add in sorted order
	Enumeration elems = names.elements();
	int index = 0;
	while (elems.hasMoreElements()) {
	    MoteInfo elem = (MoteInfo)elems.nextElement();

	    if (m.moteId == elem.moteId)
		return null; // duplicate
	    if (m.moteId < elem.moteId) {
		break;
	    }
	    index++;
	}
	names.add(index, m);

	return m;
    }

    int lookupIndex(int moteId) {
	Enumeration elems = names.elements();
	int index = 0;

	while (elems.hasMoreElements()) {
	    MoteInfo elem = (MoteInfo)elems.nextElement();

	    if (elem.moteId == moteId)
		return index;
	    index++;
	}
	return -1;
    }

    MoteInfo lookupByIndex(int index) {
	if (index < 0 || index >= names.size())
	    return null;
	return (MoteInfo)names.elementAt(index);
    }

    boolean delIndex(int index) {
	if (index < 0 || index >= names.size())
	    return false;
	sql.delMote(lookupByIndex(index).moteId);
	names.remove(index);
	return true;
    }

    boolean setNameByIndex(int index, String name) {
	if (index < 0 || index >= names.size())
	    return false;

	MoteInfo m = (MoteInfo)names.get(index);
	m.name = name;
	names.set(index, m);
	sql.setMoteName(m.moteId, name);
	return true;
    }

    UserDB() {
	names = this;
	sql = new Sql();
	sql.connect();
	sql.getMotes(this);
    }
}
