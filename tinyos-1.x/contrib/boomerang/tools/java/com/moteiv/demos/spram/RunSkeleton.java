package com.moteiv.demos.spram;

import net.tinyos.util.*;
import net.tinyos.message.*;
import net.tinyos.packet.*;
import java.io.*;
import java.util.*;
import java.util.regex.*;

public class RunSkeleton
  extends Thread
{
  protected HashMap config;
  protected PhoenixSource source;
  protected MoteIF mote;

  public RunSkeleton create() {
    return new RunSkeleton();
  }

  public void skel_init( String args[] ) {
    config = new HashMap();

    Pattern p = Pattern.compile( "(\\S+?)=(.*)" );
    for( int i=0; i<args.length; i++ ) {
      Matcher m = p.matcher(args[i]);
      if( m.matches() )
	config.put( m.group(1), m.group(2) );
    }

    skel_init( config );
  }

  public void skel_init( HashMap _config ) {
    config = _config;
    init();
    set_config_default( "groupid", "125" );
    set_config_default( "motecom", "sf@localhost:9001" );
  }

  public void init() {
  }

  public void run() {
  }

  public void set_config_default( Object key, Object value ) {
    if( !config.containsKey(key) )
      config.put(key,value);
  }

  public void make_connection() {
    source = BuildSource.makePhoenix( config.getStr("motecom"), PrintStreamMessenger.err );
    mote = new MoteIF( source, config.getInt("groupid") );
  }

  public void close_connection() {
    if( source != null ) {
      source.shutdown();
    }
  }

  public void skel_main( String[] args ) {
    skel_init( args );

    Vector v = new Vector();
    Pattern p = Pattern.compile( "motecom.+" );
    Iterator i = config.keySet().iterator();
    while( i.hasNext() ) {
      String arg = (String)i.next();
      Matcher m = p.matcher(arg);
      if( m.matches() ) {
	RunSkeleton skel = create();
	HashMap altconfig = (HashMap)config.clone();
	altconfig.put( "motecom", config.get(arg) );
	skel.skel_init( altconfig );
	skel.start();
	v.add( skel );
      }
    }

    try {
      if( v.size() > 0 ) {
	Iterator j = v.iterator();
	while( j.hasNext() ) {
	  RunSkeleton s = (RunSkeleton)j.next();
	  s.join();
	  s.source.shutdown();
	}
      }
      else {
	start();
	join();
      }
    }
    catch( InterruptedException ie ) {
      ie.printStackTrace();
      System.exit(1);
    }
    catch( Exception e ) {
      e.printStackTrace();
      System.exit(1);
    }
    
    System.exit(0);
  }
}

