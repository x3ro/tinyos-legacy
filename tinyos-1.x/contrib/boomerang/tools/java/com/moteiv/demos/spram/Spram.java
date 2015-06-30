package com.moteiv.demos.spram;

import net.tinyos.util.*;
import net.tinyos.message.*;
import net.tinyos.packet.*;
import java.io.*;
import java.util.*;
import java.util.regex.*;

public class Spram
  extends RunSkeleton
  implements MessageListener
{
  protected SpramDataMsg datamsg[];
  SpramDataMsg versionmsg;
  SpramDataMsg advmsg;

  boolean m_got_data;
  boolean isDownloading = false;
  boolean dont_print_reqver = false;

  protected int bytes_per_msg = 32;
  int share_goodrun_break = 10;
  int version = -1;
  int imageSize = 0;
  int versionToken = 0;

  SendData sendData;


  public Spram() {
    super();
    sendData = new SendData();
    sendData.start();
  }


  public RunSkeleton create() {
    return new Spram();
  }


  public void init() {
    //set_config_default( "motecom", "sf@localhost:9001" );
    set_config_default( "cmd", "help" ); //help (default), get, put
    set_config_default( "format", "auto" );
    set_config_default( "file", "" );
    set_config_default( "msg_timeout", "500" );
  }


  public void run() {
    String cmd = config.getStr("cmd");

    if( "help".equals(cmd) ) {
      System.out.println(
        "usage: Spram cmd=[cmd] format=[format] file=[file]\n"
      + "\n"
      + "  cmd = help, get, put\n"
      + "  format = auto, text, bin\n"
      + "  file = stdio, [filename]\n"
      + "  motecom = [motecom_env], [motecom_spec]\n"
      + "\n"
      + "  cmd=help\n"
      + "    Print this help text\n"
      + "\n"
      + "  cmd=get [file=...] [format=...]\n"
      + "    Download Spram image from the attached mote.  Save the output to filename\n"
      + "    or to \"stdio\" if given.  The format is deduced by the file\n"
      + "    extension, or may be overridden with format=... .\n"
      + "\n"
      + "  cmd=put [file=...] [format=...]\n"
      + "    Upload Spram image to the attached mote.  Similar to cmd=get, except bytes\n"
      + "    are loaded from the file first, then uplodaded.\n"
      );
      System.exit(0);
    }


    version = -1;
    imageSize = 0;
    datamsg = new SpramDataMsg[1];

    make_connection();

    mote.registerListener( new SpramDataMsg(), this );
    mote.registerListener( new SpramRequestMsg(), this );

    try {
      if( "get".equals(cmd) ) {
        downloadBytes();
        writeBytes();
      }
      else if( "put".equals(cmd) ) {
        readBytes();
        uploadBytes();
      }
      else {
        throw new IllegalArgumentException( "unknown cmd "+cmd );
      }
    }
    catch( java.io.IOException e ) {
      e.printStackTrace();
      System.exit(1);
    }
  }


  boolean receiveData( int pageBegin, int pageEnd ) throws java.io.IOException {
    return receiveData( pageBegin, pageEnd, false );
  }


  boolean receiveData( int pageBegin, int pageEnd, boolean no_version ) throws java.io.IOException {

    int send_timeout = config.getInt("msg_timeout");
    int sleep_time = 100;

    int begin = pageBegin * bytes_per_msg;
    int end = pageEnd * bytes_per_msg;
    if( end > imageSize )
      end = imageSize;

    boolean gotdata = false;

    SpramRequestMsg reqmsg = new SpramRequestMsg();
    reqmsg.set_addrRequester( 126 );
    reqmsg.set_bytesBegin( begin );
    reqmsg.set_bytesEnd( end );
    reqmsg.set_bytesTotal( imageSize );
    reqmsg.set_flags( (short)(version==-1?1:0) ); // no version
    reqmsg.set_versionToken( versionToken );
    reqmsg.set_version( (short)version );

    printMessage( System.err, "sent>   ", reqmsg );

    m_got_data = false;
    mote.send( MoteIF.TOS_BCAST_ADDR, reqmsg );

    for( int s=send_timeout; s>0; s-=sleep_time ) {
      if( m_got_data ) {
        gotdata = true;
        if( datamsg[pageEnd-1] != null ) {
          break;
        }
        s = send_timeout;
        m_got_data = false;
      }
      try { Thread.sleep(sleep_time); }
      catch( InterruptedException ie ) { break; }
    }

    return gotdata;
  }

  int numPages() {
    return (imageSize + bytes_per_msg - 1) / bytes_per_msg;
  }

  class SendData extends Thread {
    SpramDataMsg msg;
    int pageBegin;
    int pageEnd;
    boolean timeout;
    boolean havedata;

    public void run() {
      while(true) {
        boolean l_timeout = false;
        boolean l_havedata = false;

        try {
          synchronized(this) {
            timeout = true;
            wait(100);
            l_timeout = timeout;
            l_havedata = havedata;
          }
        }
        catch( InterruptedException e ) {
        }

//System.err.println( "SendData 1 l_timeout="+l_timeout+", l_havedata="+l_havedata );

        if( l_timeout && l_havedata ) {
//System.err.println("SendData 2");

          if( pageEnd > numPages() )
            pageEnd = numPages();

          for( int i=pageBegin; i<pageEnd; i++ ) {
            msg.set_bytesBegin( i * bytes_per_msg );
            msg.set_bytesTotal( imageSize );
            for( int j=0; j<bytes_per_msg; j++ ) {
              //System.err.println( "i="+i+", j="+j );
              msg.setElement_bytes( j, datamsg[i].getElement_bytes(j) );
            }

            printMessage( System.err, "sent>   ", msg );
            try { mote.send( MoteIF.TOS_BCAST_ADDR, msg ); }
            catch( java.io.IOException e ) { i--; }
          }

          synchronized(this) { havedata = false; }
        }
      }
    }
    
    synchronized public void send( SpramDataMsg msg, int pageBegin, int pageEnd ) throws java.io.IOException {
//System.err.println( "SendData.send 1" );
      this.msg = msg;
      this.pageBegin = pageBegin;
      this.pageEnd = pageEnd;
      havedata = true;
      if( timeout ) {
        timeout = false;
        notify();
      }
    }

    synchronized public boolean isSending() {
//System.err.println( "SendData.isSending="+havedata );
      return havedata;
    }
  }


  protected void downloadBytes() throws java.io.IOException {

    isDownloading = true;

    //System.err.println( "downloadBytes 3." );
    version = getVersion();
    versionToken = versionmsg.get_versionToken();

    while( true ) {

      int begin = 1;
      int end = 0;
      int missing = 0;
      int goodrun = 0;

      for( int i=0; i<datamsg.length; i++ ) {
        if( datamsg[i] == null ) {
          missing++;
          goodrun = 0;
          if( begin > end )
            begin = i;
          end = i+1;
        }
        else {
          if( (missing > 0) && (++goodrun >= share_goodrun_break) )
            break;
        }
      }

      if( begin > end )
        break;

      dont_print_reqver = false;
      System.err.println( "Requesting bytes "+(begin*bytes_per_msg)+" to "+(end*bytes_per_msg)+"." );
      receiveData( begin, end );
    }

    isDownloading = false;

    dont_print_reqver = false;
    System.err.println( "Download complete." );
  }

  protected int getVersion() throws java.io.IOException {
    versionmsg = null;
    int sleep_time = 100;
    while( versionmsg == null ) {
      if( !sendData.isSending() ) {
        if( !dont_print_reqver ) {
          System.err.println( "Requesting version." );
          dont_print_reqver = true;
        }
        if( receiveData(0,1,true) )
          break;
      }
      else {
        try { Thread.sleep(sleep_time); }
        catch( InterruptedException e ) { }
      }
    }
    return versionmsg.get_version();
  }

  protected void uploadBytes() throws java.io.IOException {

    //System.err.println( "uploadBytes 1" );

    int version_inc = config.getInt("version_inc",1);
    version = 255 & (getVersion() + version_inc);

    //System.err.println( "uploadBytes 2" );

    advmsg = new SpramDataMsg( SpramDataMsg.DEFAULT_MESSAGE_SIZE + 32 );
    advmsg.set_addrSender( 126 ); //uart address
    advmsg.set_version( (short)version );
    advmsg.set_versionToken( versionToken );
    advmsg.set_flags( (short)0 );

    int minsleep = 100;
    long lastcheck = 0;

    while(true) {

      //System.err.println( "uploadBytes 3" );
      int n = 0;

      if( !sendData.isSending() ) {
        long now = System.currentTimeMillis();
        if( (now-lastcheck) >= minsleep ) {
          lastcheck = now;
          //System.err.println( "uploadBytes 4."+(++n) );
          if( getVersion() == version ) {
            if( (versionmsg.get_flags() & 2) != 0 )
              break; //done!
          }
          else {
            version = 255 & (versionmsg.get_version() + version_inc);
            versionToken = (int)System.currentTimeMillis();
            advmsg.set_version( (short)version );
            advmsg.set_versionToken( versionToken );
          }

          sendData.send(advmsg,0,1) ;
        }
      }

      try { Thread.sleep(minsleep); }
      catch( InterruptedException e ) { break; }
    }
      
    dont_print_reqver = false;
    System.err.println( "Upload complete." );
  }


  protected String getFormat( String filename ) { 
    String format = config.getStr("format").toLowerCase();
    if( "auto".equals(format) ) {
      Matcher m = Pattern.compile(".*\\.(.*)").matcher( filename );
      format = m.matches() ? m.group(1).toLowerCase() : "text";
      if( "txt".equals(format) )
        format = "text";
    }
    return format;
  }


  protected void writeBytes() throws java.io.IOException {
    String filename = config.getStr("file","");
    String format = getFormat( filename );
    PrintStream output = "stdio".equals(filename) ? System.out
      : new PrintStream( new FileOutputStream(filename) );
    boolean isText = "text".equals(format);

    int nremain = imageSize;

    for( int i=0; i<datamsg.length; i++ ) {
      for( int j=0; j<bytes_per_msg; j++ ) {
        int v = datamsg[i].getElement_bytes(j);
        if( isText ) output.println(v);
        else output.write(v);
        if( --nremain <= 0 )
          return;
      }
    }
  }

  
  protected void readBytes( boolean isText, InputStream input )
  throws java.io.IOException {
    Vector msgs = new Vector();
    imageSize = 0;

    BufferedReader reader = null;
    BufferedInputStream in = null;

    if( isText )
      reader = new BufferedReader( new InputStreamReader( input ) );
    else
      in = new BufferedInputStream( input );

    boolean more = true;

    while( more ) {
      SpramDataMsg msg = new SpramDataMsg(48);
      msgs.add( msg );
      for( int j=0; j<bytes_per_msg; j++ ) {
        
        int v = 0;

        if( isText ) {
          String line = reader.readLine();
          if( line == null ) { more = false; break; }
          v = Integer.parseInt( line.trim() );
        }
        else {
          v = in.read();
          if( v == -1 ) { more = false; break; }
        }

        msg.setElement_bytes( j, (byte)v );
        imageSize++;
      }
    }

    versionToken = (int)System.currentTimeMillis();

    datamsg = new SpramDataMsg[msgs.size()];
    msgs.copyInto( datamsg );

//System.err.println( "imageSize="+imageSize+", datamsg.length="+datamsg.length );
  }


  protected void readBytes() throws java.io.IOException {
    String filename = config.getStr("file","");
    String format = getFormat( filename );
    InputStream input = "stdio".equals(filename) ? System.in
      : new FileInputStream(filename);
    boolean isText = "text".equals(format);
    readBytes( isText, input );
  }

  void printMessage( PrintStream out, String prefix, Message msg ) {
    if( config.getBool("debugmsg") ) {
      if( msg instanceof SpramDataMsg ) {
        SpramDataMsg m = (SpramDataMsg)msg;
        out.println( prefix+"data: sender="+m.get_addrSender()+", begin="+m.get_bytesBegin()+", total="+m.get_bytesTotal()+", token="+m.get_versionToken()+", version="+m.get_version()+", flags="+m.get_flags() );
      }
      else if( msg instanceof SpramRequestMsg ) {
        SpramRequestMsg m = (SpramRequestMsg)msg;
        out.println( prefix+"req: requester="+m.get_addrRequester()+", begin="+m.get_bytesBegin()+", end="+m.get_bytesEnd()+", total="+m.get_bytesTotal()+", token="+m.get_versionToken()+", version="+m.get_version()+", flags="+m.get_flags() );
      }
    }
  }

  public void messageReceived( int dest_addr, Message msg ) {
  
    printMessage( System.err, "received>   ", msg );

    if( msg instanceof SpramDataMsg ) {

      m_got_data = true;

      SpramDataMsg m = (SpramDataMsg)msg;

      if( versionmsg == null )
        versionmsg = m;

      if( isDownloading ) {
        int numpages = (m.get_bytesTotal() + bytes_per_msg - 1) / bytes_per_msg;
//System.err.println( "numPages="+numpages );
        if( numpages <= 0 )
          numpages = 1;
        if( datamsg.length != numpages ) {
          datamsg = new SpramDataMsg[numpages];
          version = m.get_version();
          imageSize = m.get_bytesTotal();
        }
        int page = m.get_bytesBegin() / bytes_per_msg;
        datamsg[page] = m;
      }
    }
    else if( msg instanceof SpramRequestMsg ) {

      SpramRequestMsg m = (SpramRequestMsg)msg;

      if( m.get_version() == version ) {
        if( !sendData.isSending() ) {
          try {
            int begin = m.get_bytesBegin();
            int end = m.get_bytesEnd();
            if( end > imageSize )
              end = imageSize;
            dont_print_reqver = false;
            System.err.println( "Uploading "+(end-begin)+" bytes." );
            sendData.send( advmsg, begin/bytes_per_msg, (end+bytes_per_msg-1)/bytes_per_msg );
          }
          catch( java.io.IOException e ) {
            dont_print_reqver = false;
            System.err.println( "Warning, error writing data to mote" );
          }
        }
      }
      else {
        dont_print_reqver = false;
        System.err.println( "Warning, requested version mismatch" );
      }
    }
  }


  static public void main( String args[] ) {
    (new Spram()).skel_main(args);
    System.exit(0);
  }
}

