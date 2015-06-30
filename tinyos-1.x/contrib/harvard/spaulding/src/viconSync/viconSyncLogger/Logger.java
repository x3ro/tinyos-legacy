import java.util.*;
import java.text.*;
import java.io.*;

public class Logger
{
    // ======================= Data members =============================
    private FileWriter fileWriter;

    // ======================= Methods =================================
    public void open(String fileName)
    {
        try {
            // (1) - Create the log directory
            String strLogFileDir = "." + File.separator + "logs";
            File logDir = new File(strLogFileDir);
            logDir.mkdirs();

            // (2) - Create the log file
            // if a file already exists with this name, then add an index to the name
            String fileWriterStr = logDir + File.separator + fileName;
            File rbFile = new File(fileWriterStr);
            for (int i = 1; ; ++i) {
                if (rbFile.exists())
                    rbFile = new File(fileWriterStr + "_" + i);
                else
                    break;
            }

            // (3) - Open a FileWriter for this file
            fileWriter = new FileWriter(rbFile);                  
            fileWriter.write("# File created on " + DateToString.dateToString(new Date(), false) + "\n");
        } catch (IOException e) {
            System.err.println("Can't open file " + fileWriter + "! " + e);
            //System.exit(1);
        }
    }

    public void writeln(String str)
    {
        this.write(str + "\n");
    }

    public void write(String str)
    {
        try {
            fileWriter.write(str);
            fileWriter.flush();
        } catch (IOException e) {
            System.err.println("Can't write to file " + fileWriter + "! " + e);
        }
    }

    public void close()
    {
        try {
            fileWriter.close();
        } catch (IOException e) {
            System.err.println("Can't close file " + fileWriter + "! " + e);
        }
    }
}
