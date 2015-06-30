/*
 * Copyright (c) 2006 Moteiv Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached MOTEIV-LICENSE     
 * file. If you do not find these files, copies can be found at
 * http://www.moteiv.com/MOTEIV-LICENSE.txt and by emailing info@moteiv.com.
 */
package com.moteiv.demos.ditto;

import net.tinyos.util.*;
import net.tinyos.message.*;
import net.tinyos.packet.*;
import java.io.*;
import java.util.*;
import java.util.regex.*;
import javax.sound.sampled.*;
import com.moteiv.demos.spram.*;

public class Ditto extends Spram
{
  public RunSkeleton create() {
    return new Ditto();
  }


  public void init() {
    //set_config_default( "motecom", "sf@localhost:9001" );
    set_config_default( "cmd", "help" ); //help (default), get, put, play, playfile
    set_config_default( "format", "auto" );
    set_config_default( "file", "" );
    set_config_default( "msg_timeout", "500" );
  }


  public void run() {
    String cmd = config.getStr("cmd");

    if( "help".equals(cmd) ) {
      System.out.println(
        "usage: Ditto cmd=[cmd] format=[format] file=[file]\n"
      + "\n"
      + "  cmd = help, get, put, play, playfile\n"
      + "  format = auto, text, aifc, aiff, au, snd, wav\n"
      + "  file = stdio, [filename]\n"
      + "  motecom = [motecom_env], [motecom_spec]\n"
      + "\n"
      + "  cmd=help\n"
      + "    Print this help text\n"
      + "\n"
      + "  cmd=get [file=...] [format=...]\n"
      + "    Download samples from the attached mote.  Save the output to filename\n"
      + "    or to \"stdio\" if given.  The format is deduced by the file\n"
      + "    extension, or may be overridden with format=... .\n"
      + "\n"
      + "  cmd=put [file=...] [format=...]\n"
      + "    Upload samples to the attached mote.  Similar to cmd=get, except samples\n"
      + "    are loaded from the file first, then uplodaded.\n"
      + "\n"
      + "  cmd=play\n"
      + "    Download samples from the attached mote and immediately play to the PC.\n"
      + "\n"
      + "  cmd=playfile [file=...] [format=...]\n"
      + "    Load a file then immediately play to the PC.  A mote is not required.\n"
      );
      System.exit(0);
    }

    try {
      if( "playfile".equals(cmd) ) {
        readBytes();
        playSamples();
        return;
      }
      else if( "dumpaudio".equals(cmd) ) {
        readBytes();
        config.put("file","stdio");
        writeBytes();
        return;
      }
    }
    catch( java.io.IOException e ) {
      e.printStackTrace();
      System.exit(1);
    }


    try {
      super.run();
      return;
    }
    catch( IllegalArgumentException e ) {
    }

    try {
      if( "play".equals(cmd) ) {
        downloadBytes();
        playSamples();
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


  AudioFileFormat.Type getFormatType( String format )
  throws IllegalArgumentException {
    AudioFileFormat.Type type = null;
    if( "aifc".equals(format) ) type = AudioFileFormat.Type.AIFC;
    else if( "aiff".equals(format) ) type = AudioFileFormat.Type.AIFF;
    else if( "au".equals(format) ) type = AudioFileFormat.Type.AU;
    else if( "snd".equals(format) ) type = AudioFileFormat.Type.SND;
    else if( "wav".equals(format) ) type = AudioFileFormat.Type.WAVE;
    else throw new IllegalArgumentException("unknown output file format "+format);
    return type;
  }


  byte[] getSampleBytes() {
    byte bytes[] = new byte[ bytes_per_msg * datamsg.length ];
    int n = 0;
    for( int i=0; i<datamsg.length; i++ ) {
      for( int j=0; j<bytes_per_msg; j++ ) {
        // data conversion
        bytes[n++] = (byte)datamsg[i].getElement_bytes(j);
      }
    }
    return bytes;
  }


  AudioFormat getMoteAudioFormat() {
    //  AudioFormat: 8192 Hz, 8 bits, 1 channel, not signed, not bigEndian
    return new AudioFormat( 8192, 8, 1, false, false );
  }

  AudioInputStream getAudioStream() {
    return new AudioInputStream( 
      new ByteArrayInputStream( getSampleBytes() ),
      getMoteAudioFormat(),
      bytes_per_msg * datamsg.length
    );
  }


  protected void readBytes() throws java.io.IOException {
    try {
      String filename = config.getStr("file","");
      AudioFileFormat.Type formatType = getFormatType( getFormat( filename ) );
      // try to convert the source audio format to the mote audio format, if possible
      AudioInputStream input = AudioSystem.getAudioInputStream(
        getMoteAudioFormat(),
        AudioSystem.getAudioInputStream( new File( filename ) )
      );
//System.err.println( "AudioInputStream format = "+input.getFormat() );
      super.readBytes( false, input );
    }
    catch( javax.sound.sampled.UnsupportedAudioFileException e ) {
      System.err.println( "unsupported audio file" );
      throw new java.io.IOException( "unsupported audio file\n"+e );
    }
    catch( IllegalArgumentException e ) {
      if( e.getMessage().startsWith("Unsupported conversion:") )
        throw new RuntimeException( e.getMessage() );
      super.readBytes();
    }
  }


  protected void writeBytes() throws java.io.IOException {
    try {
      String filename = config.getStr("file","");
      String format = getFormat( filename );
      AudioFileFormat.Type atype = getFormatType( format );
      PrintStream output = "stdio".equals(filename) ? System.out
        : new PrintStream( new FileOutputStream(filename) );
      AudioSystem.write( getAudioStream(), atype, output );
    }
    catch( IllegalArgumentException e ) {
      super.writeBytes();
    }
  }


  void playSamples() throws IOException {
    try {
      Clip clip = AudioSystem.getClip();
      clip.open( getAudioStream() );
      clip.loop(0);
      try { Thread.sleep( (clip.getMicrosecondLength()+999) / 1000 ); }
      catch( InterruptedException e ) { }
    }
    catch( LineUnavailableException e ) {
      System.err.println( "Error: audio device error, line unavailable, not playing audio." );
    }
  }


  static public void main( String args[] ) {
    (new Ditto()).skel_main(args);
    System.exit(0);
  }
}

