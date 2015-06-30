package net.tinyos.mgmtquery;

import java.io.*;
import java.util.*;

public class MgmtQueryCommander implements ResultListener {

  private static int ACCEPTABLE_MISSES = 1;
  private static int MAX_MISSED_REPORTS = 4;

  private MgmtQueryHost queryHost;
  private HashMap schema = new HashMap();
  private HashMap nodes = new HashMap();
  private ArrayList queryNames = new ArrayList();

  private String command;
  private String schemaFile;
  private boolean ramSchema = false;
  private int period = 32;
  private boolean summaryMode = false;
  private int qid = 1;

  void usage() {
    System.out.println("Usage: java net.tinyos.mgmtquery.MgmtQueryCommander [OPTION]... [COMMAND] [KEY]..."); 
    System.out.println("COMMAND = query, query_oneshot, cancel, printschema");
    System.out.println("KEY = <ComponentName>.<AttributeName>");
    System.out.println("  -s, --schema <filename/platform> : ");
    System.out.println("      The schema file is needed when keys are specified on the command line.");
    System.out.println("      First it will be interpreted as a filename, and if that does not exist,");
    System.out.println("      'build/<platform>/snms_schema.txt' will be tried.");
    System.out.println("  --ramschema <filename/platform> : As above, but indicating a schema file containing RAM symbols.");
    System.out.println("  --qid <slot> : Inject the query into <slot> (default 1, max 4)");
    System.out.println("  --period <seconds> : Response period for the query (default 32)");
    System.out.println("      With query, nodes will respond every <seconds>. ");
    System.out.println("      With query_oneshot, nodes will wait between 0 and <seconds> to respond, ");
    System.out.println("      and the query will be reinjected every <seconds>. (default off)");
    System.out.println("  --summary : Summary display mode (default is real time display)");
    System.exit(1);
  }

  private void parseArgs(String args[]) {

    ArrayList cleanedArgs = new ArrayList();

    for(int i = 0; i < args.length; i++) {
      if (args[i].startsWith("--")) {
	// Parse Long Options
	String longopt = args[i].substring(2);

	if (longopt.equals("help")) {
	  usage(); 
	} else if (longopt.equals("schema")) {
	  if (schemaFile == null) {
	    schemaFile = args[i+1];
	    i++;
	  }
	} else if (longopt.equals("ramschema")) {
	  if (schemaFile == null) {
	    schemaFile = args[i+1];
	    i++;
	  }
	  ramSchema = true;
	} else if (longopt.equals("period")) {
	  period = Integer.parseInt(args[i+1]);
	  i++;
	} else if (longopt.equals("summary")) {
	  summaryMode = true;
	} else if (longopt.equals("qid")) {
	  qid = Integer.parseInt(args[i+1]);
	  i++;
	}

      } else if (args[i].startsWith("-")) {
	// Parse Short Options
	String opt = args[i].substring(1);

	if (opt.equals("h")) {
	  usage();
	} else if (opt.equals("s")) {
	  schemaFile = args[i+1];
	  i++;
	}

      } else {
	// Place into args string
	cleanedArgs.add(args[i]);
      }
    }

    if (cleanedArgs.size() < 1) {
      usage();
    }
    command = (String) cleanedArgs.get(0);
    for (int i = 1; i < cleanedArgs.size(); i++) {
      queryNames.add(cleanedArgs.get(i));
    }
  }

  public MgmtQueryCommander(String args[]) {

    parseArgs(args);
     
    if (schemaFile != null) {

      // css: use build/schemaFile/snms_schema.txt if it exists and schemaFile doesn't
      try {
	String defschema;

	if (ramSchema) {
	  defschema = "build/" + schemaFile + "/snms_ram_schema.txt";
	} else {	
	  defschema = "build/" + schemaFile + "/snms_schema.txt";
	}

	if( !(new File(schemaFile)).isFile() && (new File(defschema)).isFile() ) {
	  schemaFile = defschema;
	}
      } catch( SecurityException se ) {
      }
      
      if (!readSchema(schemaFile)) {
	System.err.println("\nERROR: Invalid schema file: " + schemaFile + "\n");
	usage();
      }
    }

    if (schemaFile == null && 
	(command.equals("printschema") || queryNames.size() > 0)) {
      usage();
    }
    
    if (command.equals("printschema") || queryNames.size() == 0) {
      printSchema();
      if (command.equals("printschema")) {
	System.exit(0);
      }
    }

    queryHost = new MgmtQueryHost();    

    if (command.equals("cancel")) {
      cancelQuery(qid);
      System.exit(0);
    }

    if (!(command.equals("query") || command.equals("query_oneshot"))) {
      usage();
    }

    MgmtQuery query = new MgmtQuery(period);

    if (ramSchema) {
      query.setRAMQuery(true);
    }

    for(Iterator it = queryNames.iterator(); it.hasNext(); ) {
      String name = (String) it.next();
      SchemaEntry se = (SchemaEntry) schema.get(name);
      if (se == null) {
	System.err.println("Unknown attribute: " + name);
	continue;
      }
      if (ramSchema) {
	query.appendKey(makeRAMKey(se.key, se.length), se.length,
			makeRAMLength(se.length)); 
      } else {
	query.appendKey(se.key, se.length);	
      }
    }
  
    cancelQuery(qid);

    System.out.println("Activating query " + qid + " with " + period + " second period...");
    System.out.println();

    System.out.println(query);

    if (command.equals("query_oneshot")) {

      try {

	while (true) {
	  System.out.println("Injecting one-shot query...");
	  printHeader();
	  queryHost.sendOneShotQuery(query, qid, this);
	  Thread.sleep(period * 1024);
	}

      } catch (InterruptedException e) {
	e.printStackTrace();
      }

    } else if (command.equals("query")) {

      printHeader();
      queryHost.injectQuery(query, qid, this);

    } else {

      usage();
    }
  }

  void processSchemaEntry(String line) {
    String[] tokens = line.split("\\s+");

    SchemaEntry se = new SchemaEntry(tokens[0],
				     Integer.parseInt(tokens[1]),
				     Integer.parseInt(tokens[2]),
				     tokens[3]);
    schema.put(tokens[0], se);
  }

  boolean readSchema(String filename) {
    try {
      BufferedReader in = new BufferedReader(new FileReader(filename));
      String str;
      while ((str = in.readLine()) != null) {
	processSchemaEntry(str);
      }
      in.close();
    } catch (IOException e) {
      return false;
    }
    return true;
  }

  void printSchema() {
    List l = new ArrayList();
    System.out.println("\n* Queryable Attributes");
    for(Iterator it = schema.values().iterator(); it.hasNext(); ) {
      SchemaEntry se = (SchemaEntry) it.next();
      l.add(se.name);
    }
    Collections.sort(l);
    for(Iterator it = l.iterator(); it.hasNext(); ) {
      System.out.println("- " + (String)it.next());
    }
  }

  void cancelQuery(int qid) {
    System.out.println("Clearing query " + qid + "...");
    queryHost.cancelQuery(qid);
    try {
      Thread.sleep(2000);
    } catch (Exception e) {}
  }

  int seqno = 0;

  public String toByteString(int b) {
    String bs = "";
    if (b >=0 && b < 16) {
      bs += "0";
    }
    bs += Integer.toHexString(b & 0xff).toUpperCase();
    return bs;
  }

  void printHeader() {
    System.out.print("Time\t\tAddr\tSeqno\tTTL\t");
    for(int i = 0; i < queryNames.size(); i++) {
      String queryName = (String)queryNames.get(i);
      SchemaEntry se = (SchemaEntry) schema.get(queryName);
      if (se == null) {
	continue;
      }
      if (queryName.length() <= 15) {
	System.out.print(queryName + "\t");
      } else {
	System.out.print(queryName.substring(queryName.length()-15) + "\t");
      }
    }
    System.out.println();
  }

  private void printQueryResult(MgmtQueryResult qr) {

    System.out.print(System.currentTimeMillis() + "\t" + qr.getSourceAddr() + "\t" + qr.getSampleNumber() + "\t" + qr.getTTL() + "\t");
    
    int numCols = qr.getColumnCount();

    for (int i = 0; i < numCols; i++ ) {
      
      SchemaEntry se = (SchemaEntry) schema.get((String)queryNames.get(i));
      
      if (se == null) {
	continue;
      }

      if (se.type.equals("MA_TYPE_UINT")) {
	System.out.print(qr.getInt(i) + "\t\t"); 
      } else if(se.type.equals("MA_TYPE_TEXTSTRING")) {
	System.out.print(qr.getString(i) + "\t\t"); 
      } else if(se.type.equals("MA_TYPE_OCTETSTRING")) {
	System.out.print(qr.getOctetString(i) + "\t\t");
      } else if (se.type.equals("MA_TYPE_BITSTRING")) {
	System.out.print(qr.getBitString(i) + "\t\t");
      } else if(se.type.equals("MA_TYPE_UNIXTIME")) {
	long time = (long)qr.getInt(i);
	Date date = new Date(time * 1000);
	System.out.print(date + "\t\t");
      }
    }
    System.out.println();
  }

  private void printInstantaneous(MgmtQueryResult qr) {
    String missed = "";

    if (qr.getSampleNumber() > seqno) {
      seqno = qr.getSampleNumber();
      
      System.out.println(System.currentTimeMillis() + " " + "Total nodes: " + nodes.size());
      int active = 0;
      int missCount = 0;
      for(Iterator it = nodes.values().iterator(); it.hasNext(); ) {
	Node curNode = (Node) it.next();
	if (System.currentTimeMillis() - curNode.lastTime <= period * 1024 * 
	    (ACCEPTABLE_MISSES + 1)) {
	  active++;
	} else if (System.currentTimeMillis() - curNode.lastTime > period * 1024 * 
		   (MAX_MISSED_REPORTS + 1)) {
	  it.remove();
	} else {
	  missCount++;
	  missed += curNode.addr + " ";
	}
      }
      System.out.println(System.currentTimeMillis() + " " + active + " nodes heard, " + missCount + " nodes inactive: {" + missed + "}"); 
      printHeader();
    }
    
    printQueryResult(qr);
  }

  private void printSummary(MgmtQueryResult qr) {
    System.out.print(".");
    if (qr.getSampleNumber() > seqno) {
      System.out.println();
      seqno = qr.getSampleNumber();

      Vector tmpVector = new Vector(nodes.values());

      int active = 0;

      for(Iterator it = tmpVector.iterator(); it.hasNext(); ) {
	Node curNode = (Node) it.next();
	if (System.currentTimeMillis() - curNode.lastTime <= period * 1024)
	  active++;
      }

      System.out.println("Total nodes: " + nodes.size() + "   Active nodes: " + active);
      printHeader();

      Collections.sort(tmpVector, new Comparator()
	{
	  public int compare( Object a, Object b ) {
	    return ( (((Node)a).addr < ((Node)b).addr) ? 0 : 1 );
	  } 
	});

      for(Iterator it = tmpVector.iterator(); it.hasNext(); ) {
	Node curNode = (Node) it.next();
	if (!(System.currentTimeMillis() - curNode.lastTime <= period * 1024)) 
	  System.out.print("x ");
	if (curNode.qr != null)
	  printQueryResult(curNode.qr);
      }
    }
  }

  public void addResult(MgmtQueryResult qr) {

    Node node = (Node) nodes.get(new Integer(qr.getSourceAddr()));
    
    if (node == null) {
      node = new Node(qr.getSourceAddr());
      nodes.put(new Integer(qr.getSourceAddr()), node);
    }

    if (!summaryMode)
      printInstantaneous(qr);
    else
      printSummary(qr);

    node.seqno = qr.getSampleNumber();
    node.lastTime = System.currentTimeMillis();
    node.qr = qr;

  }
  
    public static void main(String args[]) {
    new MgmtQueryCommander(args);
  }

  private int makeRAMKey(int key, int length) {
    int fieldLengthLog2;
    if (length == 1) {
      fieldLengthLog2 = 0; 
    } else if (length == 2) {
      fieldLengthLog2 = 1;
    } else if (length > 2 && length <= 4) {
      fieldLengthLog2 = 2;
    } else if (length > 4 && length <= 8) {
      fieldLengthLog2 = 3;
    } else {
      fieldLengthLog2 = 3;
    }
  
    return (key | (fieldLengthLog2 << 14));
  }

  private int makeRAMLength(int length) {
    if (length == 1) {
      return 1;
    } else if (length == 2) {
      return 2;
    } else if (length > 2 && length <= 4) {
      return 4;
    } else if (length > 4 && length <= 8) {
      return 8;
    } 
    return 0;
  }

  private class SchemaEntry {
    String name;
    int key;
    int length;
    String type;
    
    SchemaEntry(String n, int k, int l, String t) {
      name = n; key = k; length = l; type = t;
    }
  }

  private class Node {
    int addr;
    int seqno;
    long lastTime;
    MgmtQueryResult qr;

    Node(int addr) {
      this.addr = addr;
    }
  }
}
