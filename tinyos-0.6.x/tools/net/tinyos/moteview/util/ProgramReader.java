package net.tinyos.moteview.util;

import java.util.*;
import java.io.*;
import net.tinyos.moteview.PacketAnalyzers.*;

public class ProgramReader
{
    private String          m_strPath       = ".";
    private Hashtable       m_htPrograms    = new Hashtable ( );
    private MoteViewInjector    codeInjector    = null;

    public ProgramReader( String strPath, MoteViewInjector ci )
    {
        m_strPath = strPath;
        codeInjector = ci;
        FillHashtable ( );
    }

    private void FillHashtable ( )
    {
        File    currentDir = new File ( m_strPath );
        if ( currentDir == null ) return;

        File[]  dirListing = currentDir.listFiles( );
        if ( dirListing == null ) return;

        File currentFile;
        int progID;
        for ( int i = 0; i < dirListing.length; i++ )
        {
            currentFile = dirListing[i];
            AddProgram ( currentFile );
        }
    }

    public void AddProgram ( File file )
    {
        int progID = codeInjector.GetProgID ( file );
        if ( m_htPrograms.containsKey( new Integer ( progID ) ) ) { return; }
        m_htPrograms.put( new Integer ( progID ), file );
    }

    public String GetProgName ( int id )
    {
        File name = (File) m_htPrograms.get( new Integer ( id ) );
        if ( name == null ) return null;
        return name.getName ();
    }

    public File GetProgFile ( int id )
    {
        return (File) m_htPrograms.get( new Integer ( id ) );
    }
}