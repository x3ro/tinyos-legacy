package net.tinyos.nucleus;

import java.io.*; 
import java.text.*;
import java.util.*;

import net.tinyos.message.*;
import net.tinyos.util.*;
import net.tinyos.drip.*;
import net.tinyos.drain.*;

import org.jdom.*;
import org.jdom.input.*;

import org.apache.log4j.*;

public class NucleusInterface {

  private Logger log = Logger.getLogger(NucleusInterface.class.getName());

  public static final int QUERY_ATTR = 1;
  public static final int QUERY_RAM = 2;

  public static final int DEST_NETWORK = 65534;
  public static final int DEST_LINK = 65535;

  public static final int RESPONSE_SERIAL = 1;
  public static final int RESPONSE_LOCAL = 2;
  public static final int RESPONSE_TREE = 3;

  private MoteIF moteIF;
  private Drip queryDrip;
  private Drip setDrip;
  private DrainConnector mhConnector;

  private Document schema;

  private int activeQueryID;
  private List resultList;
  private String[] queryNames;

  private static int ATTR_SIZE = 3;
  private static int MAX_ATTR_COUNT = 4;

  public NucleusInterface() {
    log.info("started: opening moteIF, drip(GET), drip(SET), drainConnector, drain.listen(RESPONSE)");
    moteIF = new MoteIF();
    queryDrip = new Drip(MgmtQueryConsts.AM_MGMTQUERYMSG);
    setDrip = new Drip(RemoteSetMsg.AM_TYPE);
    mhConnector = new DrainConnector();
    mhConnector.registerListener(MgmtQueryConsts.AM_MGMTQUERYRESPONSEMSG, 
				 new TreeListener());
  }

  public void loadSchema(String filename) {
    SAXBuilder builder = new SAXBuilder();
    try {
      schema = builder.build(filename);
    } catch (Exception e) {
      System.err.println(e);
    }
  }

  public synchronized List get(int destAddr,
			       int queryDest,
			       int queryDelay,
			       String[] names, 
			       int[] positions) {

    int numAttrs = names.length;
    if (numAttrs > MAX_ATTR_COUNT) {
      log.warn("Can only request " + MAX_ATTR_COUNT + " attributes at a time. Truncating from " + numAttrs + ".");
      numAttrs = 4;
    }

    String info = "get: " + queryDelay + "cs {";
    for(int i = 0; i < names.length; i++) {
      info += names[i] + "." + positions[i] + " ";
    }
    info += "}";
    info += " destAddr: " + destAddr + " respAddr: " + queryDest;

    log.info(info);
  
    resultList = new ArrayList();
    activeQueryID = (int)((double)Math.random() * (double)65535);
    queryNames = names;

    DestMsg destMsg = null;    
    MgmtQueryMsg mqMsg = null;

    switch(destAddr) {

    case DEST_LINK:
      mqMsg = new MgmtQueryMsg(MgmtQueryMsg.DEFAULT_MESSAGE_SIZE +
			       ATTR_SIZE * numAttrs);
      break;

    case DEST_NETWORK:

      destMsg = new DestMsg(DestMsg.DEFAULT_MESSAGE_SIZE +
			    MgmtQueryMsg.DEFAULT_MESSAGE_SIZE +
			    ATTR_SIZE * numAttrs);
	    
      destMsg.set_addr(MoteIF.TOS_BCAST_ADDR);
      destMsg.set_ttl((short)0xff);
      
      mqMsg = 
	new MgmtQueryMsg(destMsg, destMsg.offset_data(0),
			 MgmtQueryMsg.DEFAULT_MESSAGE_SIZE + 
			 ATTR_SIZE * numAttrs);
      break;

    default:
      destMsg = new DestMsg(DestMsg.DEFAULT_MESSAGE_SIZE +
			    MgmtQueryMsg.DEFAULT_MESSAGE_SIZE +
			    ATTR_SIZE * numAttrs);
      
      destMsg.set_addr(destAddr);
      destMsg.set_ttl((short)0xff);
      
      mqMsg = 
	new MgmtQueryMsg(destMsg, destMsg.offset_data(0),
			 MgmtQueryMsg.DEFAULT_MESSAGE_SIZE + 
			 ATTR_SIZE * numAttrs);
    }

    mqMsg.set_destination(queryDest);

    mqMsg.set_active((byte)1);
    mqMsg.set_repeat((byte)0);
    mqMsg.set_queryID((int)activeQueryID);

    if (queryDelay > 1) {
      mqMsg.set_delay((byte)queryDelay / 2);
    } else {
      mqMsg.set_delay((byte)queryDelay);
    }

    mqMsg.set_numAttrs((byte)numAttrs);

    for (int i = 0; i < numAttrs; i++) {
      
      AttrData attr = lookupAttr(names[i]);

      if (attr == null) {
	System.out.println("Unknown attribute name: " + names[i]);
	return null;
      }

      mqMsg.setElement_attrList_id(i, attr.id);

      if (attr.ram) {
	mqMsg.setElement_attrList_pos(i, (byte)attr.length);
	mqMsg.set_ramAttrs((short)(mqMsg.get_ramAttrs() | (1 << i)));
      } else {
	mqMsg.setElement_attrList_pos(i, (byte)positions[i]);
      }
    }

    switch (destAddr) {
    case DEST_LINK:
      send(mqMsg);
      break;
    default:
      queryDrip.send(destMsg, destMsg.dataGet().length);
      break;
    }

    try {
      if (queryDelay < 10) {
	Thread.sleep(10 * 100);
      } else {
	Thread.sleep(queryDelay * 100);
      }
    } catch (InterruptedException e) {}

    return resultList;
  }

  public synchronized boolean set(int destAddr,
				  String name,
				  int position,
				  short[] value) {
    
    DestMsg destMsg = null;    
    RemoteSetMsg rsMsg = null;

    AttrData attr = lookupAttr(name);
    
    if (attr == null) {
      System.err.println("Unknown attribute name: " + name);
      return false;
    }
    
    int size = attr.length;

    switch(destAddr) {
      
    case DEST_LINK:
      rsMsg = new RemoteSetMsg(RemoteSetMsg.DEFAULT_MESSAGE_SIZE + size);
      
      break;

    case DEST_NETWORK:

      destMsg = new DestMsg(DestMsg.DEFAULT_MESSAGE_SIZE +
			    RemoteSetMsg.DEFAULT_MESSAGE_SIZE +
			    size);
	    
      destMsg.set_addr(MoteIF.TOS_BCAST_ADDR);
      destMsg.set_ttl((short)0xff);
      
      rsMsg = 
	new RemoteSetMsg(destMsg, destMsg.offset_data(0),
			 RemoteSetMsg.DEFAULT_MESSAGE_SIZE + 
			 size);
      break;

    default:

      destMsg = new DestMsg(DestMsg.DEFAULT_MESSAGE_SIZE +
			    RemoteSetMsg.DEFAULT_MESSAGE_SIZE +
			    size);
	    
      destMsg.set_addr(destAddr);
      destMsg.set_ttl((short)0xff);
      
      rsMsg = 
	new RemoteSetMsg(destMsg, destMsg.offset_data(0),
			 RemoteSetMsg.DEFAULT_MESSAGE_SIZE + 
			 size);
      break;
    }

    rsMsg.set_id(attr.id);
    
    if (attr.ram) {
      rsMsg.set_isRAM((byte)1);
      rsMsg.set_pos((byte)attr.length);
    } else {
      rsMsg.set_isRAM((byte)0);
      rsMsg.set_pos((byte)position);
    }
    
    short[] cutValue = new short[attr.length];
    System.arraycopy(value, 0, cutValue, 0, attr.length);
    rsMsg.set_value(cutValue);

    switch (destAddr) {
    case DEST_LINK:
      send(rsMsg);
      break;
    default:
      setDrip.send(destMsg, destMsg.dataGet().length);
      break;
    }

    return true;
  }

  private void wakeupGet() {
    notifyAll();
  }

  private AttrData lookupAttr(String attrName) {

    AttrData data = new AttrData();
    data.name = attrName;

    if (schema != null) {
      
      List attributes;
      
      // see if it's a name in the attribute schema
      attributes = schema.getRootElement().getChild("attributes").getChildren();
      for (Iterator it = attributes.iterator(); it.hasNext(); ) {
	Element attribute = (Element)it.next();
	if (attribute.getAttributeValue("name").equals(attrName)) {
	  data.id = Integer.parseInt(attribute.getAttributeValue("id"));
	  data.length = Integer.parseInt(attribute.getAttributeValue("length"));
	  data.type = attribute.getAttributeValue("type");
	  data.ram = false;
	  return data;
	}
      }
      
      // see if it's a name in the RAM symbol schema
      attributes = schema.getRootElement().getChild("symbols").getChildren();
      
      for (Iterator it = attributes.iterator(); it.hasNext(); ) {
	Element attribute = (Element)it.next();
	if (attribute.getAttributeValue("name").equals(attrName)) {
	  data.id = Integer.parseInt(attribute.getAttributeValue("address"));
	  data.length = Integer.parseInt(attribute.getAttributeValue("length"));
	  data.ram = true;
	  return data;
	}
      }
    }
    
    // then try interpreting it as id:length
    String idSize[] = attrName.split(":");
    if (idSize.length == 2) {
      try {
	data.id = Integer.parseInt(idSize[0]);
	data.length = Integer.parseInt(idSize[1]);
	return data;
      } catch (NumberFormatException e) { }
    }
    
    // I give up.
    return null;
  }
  
  private class TreeListener implements MessageListener {
    public void messageReceived(int to, Message m) {
      DrainMsg mhMsg = (DrainMsg) m;
      
      MgmtQueryResponseMsg mqrMsg = 
	new MgmtQueryResponseMsg(mhMsg, mhMsg.offset_data(0), 
				 mhMsg.dataLength()
				 - mhMsg.offset_data(0));
      
      if (mqrMsg.get_queryID() == activeQueryID) {
	processResult(mhMsg.get_source(), mqrMsg);
      }
    }
  }
  
  private void processResult(int from, MgmtQueryResponseMsg msg) {

    log.debug("Response from node " + from);

    NucleusResult nr = new NucleusResult();
    nr.from = from;

    if (resultList.contains(nr)) {
      return;
    }

    if (msg.dataLength() < msg.offset_data(0)) {
      log.error("Result message too short! size=" + msg.dataLength());
      return;
    }

    byte[] data = new byte[msg.dataLength() - msg.offset_data(0)];
    int dataLength = msg.dataLength() - msg.offset_data(0);

    for(int i = 0; i < dataLength; i++) {
      data[i] = (byte)msg.getElement_data(i);
    }

    nr.bytes = data;
    int offset = 0;

    LEDataInputStream resultData = 
      new LEDataInputStream(new ByteArrayInputStream(nr.bytes));
    
    for(int i = 0; i < queryNames.length; i++) {

      AttrData attr = lookupAttr(queryNames[i]);

      NucleusValue nv = new NucleusValue();

      if ((msg.get_attrsPresent() & (1 << i)) != 0) {
	// the attribute is present in the response.
	
	String info = "Parsing attribute (" + queryNames[i] + "): ";

	nv.bytes = new ArrayList();
	for (int j = 0; j < attr.length; j++) {
	  try {
	    info += toHexByte(nr.bytes[offset+j]) + " ";
	    nv.bytes.add(new Byte((byte)nr.bytes[offset+j]));
	  } catch (Exception e) {
	    break; // stop processing data...it's likely to be wrong.
	  }
	}

	nv.value = convertBytes(resultData, attr);

	log.debug(info + "value: " + nv.value);
      }

      nr.attrs.put(new String(attr.name), nv);
      
      offset += attr.length;
    }

    resultList.add(nr);
  }

  private Object convertBytes(LEDataInputStream data, AttrData attr) {

    try {

      if (attr.ram) {
	if (attr.length == 0) {
	  return null;
	}
	if (attr.length == 1) {
	  return new Integer(data.readUnsignedByte());
	}
	if (attr.length == 2) {
	  return new Integer(data.readUnsignedShortLE());
	}
	if (attr.length >= 4) {
	  return new Integer(data.readIntLE());
	}
	
      } else {

	if (attr.type.equals("unsigned char")) {
	  return new Integer(data.readUnsignedByte());
	}
	
	if (attr.type.equals("unsigned int")) {
	  return new Integer(data.readUnsignedShortLE());
	}
	
	if (attr.type.equals("unsigned long")) {
	  return new Integer(data.readIntLE());
	}
	
	if (attr.type.equals("int")) {
	  return new Integer(data.readShortLE());
	}
	
	if (attr.type.startsWith("struct")) {
	  
	  List structs = schema.getRootElement().getChild("structs").getChildren();
	  for (Iterator it = structs.iterator(); it.hasNext(); ) {
	    Element struct = (Element)it.next();
	    if (("struct " + struct.getAttributeValue("name")).equals(attr.type)) {
	      int size = Integer.parseInt(struct.getAttributeValue("size").substring(2));
	      Hashtable obj = new Hashtable();
	      
	      List fields = struct.getChildren();
	      
	      for (Iterator it2 = fields.iterator(); it2.hasNext(); ) {
		Element field = (Element)it2.next();
		String name = field.getAttributeValue("name");
		int fieldSize = Integer.parseInt(field.getAttributeValue("size").substring(2));
		
		if (field.getChild("type-int") != null) {
		  Integer val = suckBytes(data, fieldSize);
		  System.out.println(val);
		  obj.put(name, val);
		}
	      }
	      
	      return obj;
	    }
	  }
	}
      }

      // If the type is unknown, just flush the bytes out of the
      // LEInputDataStream

      for (int i = 0; i < attr.length; i++) {
	data.readUnsignedByte();
      }

    } catch (Exception e) {
      e.printStackTrace();
    }

    return null;
  }

  private Integer suckBytes(LEDataInputStream data, int length) throws IOException {
    
    if (length == 1) {
      return new Integer(data.readUnsignedByte());
    }
    if (length == 2) {
      return new Integer(data.readUnsignedShortLE());
    }
    if (length >= 4) {
      return new Integer(data.readIntLE());
    }

    return null;
  }

  private void send(Message m) {
    try {
      moteIF.send(MoteIF.TOS_BCAST_ADDR, m);
    } catch (IOException e) {
      e.printStackTrace();
      System.out.println("ERROR: Can't send message");
      System.exit(1);
    } catch (Exception e) {
      e.printStackTrace();
    }
  }

  private class AttrData {
    public String name;
    public int id;
    public int length;
    public String type;
    public boolean ram;
  }

  public static void main(String[] args) {

    NucleusInterface ni = new NucleusInterface();

    ni.loadSchema("nucleusSchema.xml");

    String[] names = {"Boring"}; 
    int[] positions = {0};
    short[] value = {0xFE, 0xFD};

    boolean result = ni.set(NucleusInterface.DEST_LINK,
			    names[0], positions[0], value); 

/*
    List result = ni.get(NucleusInterface.QUERY_ATTR, 
			 NucleusInterface.SEND_DIRECT,
			 NucleusInterface.RESPONSE_SERIAL,
			 10, names, positions);

    if (result == null) {
      System.exit(1);
    }

    for(Iterator it = result.iterator(); it.hasNext(); ) {
      NucleusResult nr = (NucleusResult) it.next();
      for(Iterator nameIt = nr.attrs.keySet().iterator(); nameIt.hasNext(); ) {
	String name = (String) nameIt.next();
	Object value = nr.attrs.get(name);
	System.out.print("" + nr.from + ": " + name + " = ");
	
	if (value instanceof Long) {
	  System.out.println((Long)value);
	} else if (value instanceof ArrayList) {
	  System.out.println(toHexByteString((ArrayList)value));
	}
      }
    }
*/
  
    System.exit(0);
  }

  private static String toHexByteString(ArrayList arr) {
    String ret = "";
    for (Iterator byteIt = arr.iterator(); byteIt.hasNext(); ) {
      Byte theByte = (Byte) byteIt.next();
      ret += toHexByte(theByte.intValue()) + " "; 
    }
    return ret;
  }

  private static String toHexByte(int b) {
    String buf = "";
    String bs = Integer.toHexString(b & 0xff).toUpperCase();
    if (b >=0 && b < 16)
      buf += "0";
    buf += bs;
    return buf;
  }
}



