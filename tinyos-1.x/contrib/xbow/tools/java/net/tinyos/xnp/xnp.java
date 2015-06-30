/*
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice and the following
 * two paragraphs appear in all copies of this software.
 *
 * IN NO EVENT SHALL CROSSBOW TECHNOLOGY BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF CROSSBOW
 * TECHNOLOGY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * CROSSBOW TECHNOLOGY SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND CROSSBOW TECHNOLOGY HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 *
*/
/*-----------------------------------------------------------------------------
* General Description:
* - read a TOS .srec file and store in array,  for downloading
* - xmit code capsules (.srec file lines) to mote. Mote stores code capsules in
*   serial eprom memory. Code capsules look almost identical to each file line of
*   the srec file.
* - if all code capsules received by mote, then cmd mote to reprogram itself.
*------------------------------------------------------------------------------- */
package net.tinyos.xnp;

import net.tinyos.util.*;
import java.awt.*;
import java.awt.event.*;
import javax.swing.*;
import java.io.File;
import javax.swing.filechooser.FileFilter;
import javax.swing.border.*;

public class xnp extends javax.swing.JFrame {
//----------------default mote values-----------------------------------------
  private static short wMoteId = 3;              //mote id
  private static final int TOS_BROADCAST_ADDR = 0xffff;  //broadcast address
  private static short group_id = 125;           //mote group id
  private static String sCommPort = "COM1";      //comm port
  private static int BaudRate = 57600;           //baud rate
  public static boolean bCommOpen = false;       //true if comm port open
  public static boolean bXGenericBase = false;     //true if using XGenericBase
  public static boolean bDownLoadBcast = false;    //true if bcast download
  public static boolean bDownLoading = false;    //not loading code
  private static boolean bThreadRunning = false; //true if download thrd running
  private static boolean bThread2Running = false; //true if chking for msd pckts
//---------------------------------------------------------------------------
  private JPanel contentPane;
  private Label label5 = new Label();
  private SrecFileFilter SrecFilter;
  private  static xnpUtil CodeInj;
  private static  SerialStub rSerialStub;
  private static xnpXmitCode XDwn;
  private static xnpQry XDwn2;
  private Thread rt2;
  private Thread rt3;
  private static String sSrecFileName;                  //name of selected srec file.
  private TextField TxtStatus = new TextField();
  private Label label8 = new Label();
  private JPanel jPanel1 = new JPanel();
  private TextField TxtProgramID = new TextField();
  private Label label7 = new Label();
  private Label label6 = new Label();
  private TextField TxtLength = new TextField();
  private JButton jBtnDwnLoad = new JButton();
  private Border border1;
  private TitledBorder titledBorder1;
  private TextField TxtSrecFileName = new TextField();
  private Label label2 = new Label();
  private JPanel jPanel2 = new JPanel();
  private Label label4 = new Label();
  private Label label3 = new Label();
  private TextField TxtMoteId = new TextField();
  private TextField TxtGroupId = new TextField();
  private JPanel jPanel3 = new JPanel();
  private TextField TxtCommPort = new TextField();
  private Label label1 = new Label();
  private JPanel jPanel4 = new JPanel();
  private JFileChooser jFileChooser1 = new JFileChooser();
  private TitledBorder titledBorder2;
  private TitledBorder titledBorder3;
  private TitledBorder titledBorder4;
  private TextField TxtBatteryVolts = new TextField();
  private Label label9 = new Label();
  private JButton jBtnProgram1 = new JButton();
  private JButton jBtnReProg = new JButton();
  private Label label10 = new Label();
  private TextField TxtCommBaud = new TextField();
  public TextField TxtCommStatus = new TextField();
  private Label label11 = new Label();
  private JCheckBox jCheckBox1 = new JCheckBox();
  private Label label12 = new Label();
  private JButton jBtnQry = new JButton();
  private JCheckBox jCheckBoxXGB1 = new JCheckBox();
  private Label label14 = new Label();

  //Construct the frame
  public xnp() {
    enableEvents(AWTEvent.WINDOW_EVENT_MASK);
    try {
      jbInit();
    }
    catch(Exception e) {
      e.printStackTrace();
    }
    jFileChooser1.addChoosableFileFilter( new SrecFileFilter());

  }
  //Component initialization
  private void jbInit() throws Exception  {
    contentPane = (JPanel) this.getContentPane();
    border1 = BorderFactory.createMatteBorder(6,6,6,6,Color.white);
    titledBorder1 = new TitledBorder(BorderFactory.createEtchedBorder(Color.blue,new Color(148, 145, 140)),"Srec file");
    titledBorder2 = new TitledBorder(BorderFactory.createEtchedBorder(Color.blue,new Color(148, 145, 140)),"CommPort Info");
    titledBorder3 = new TitledBorder(BorderFactory.createEtchedBorder(Color.blue,new Color(148, 145, 140)),"Mote Info");
    titledBorder4 = new TitledBorder(BorderFactory.createEtchedBorder(Color.blue,new Color(148, 145, 140)),"Code Info");
    contentPane.setLayout(null);
    this.setSize(new Dimension(518, 612));
    this.setTitle("Xnp");
    contentPane.setEnabled(true);
    contentPane.setBorder(BorderFactory.createRaisedBevelBorder());
    contentPane.setPreferredSize(new Dimension(600, 400));
    contentPane.setToolTipText("");
    label5.setBounds(new Rectangle(187, 50, 75, 37));
    label5.setText("# CodeCap");
    TxtStatus.setBounds(new Rectangle(77, 87, 365, 18));
    label8.setText("Status");
    label8.setBounds(new Rectangle(15, 85, 45, 26));
    jPanel1.setBorder(titledBorder4);
    jPanel1.setBounds(new Rectangle(17, 429, 460, 137));
    jPanel1.setLayout(null);
    TxtProgramID.setEnabled(false);
    TxtProgramID.setBounds(new Rectangle(77, 65, 70, 18));
    label7.setText("Prog Id");
    label7.setBounds(new Rectangle(14, 62, 50, 28));
    label6.setBounds(new Rectangle(236, 63, 113, 24));
    label6.setText("# of Code Capsules");
    TxtLength.setEnabled(false);
    TxtLength.setBounds(new Rectangle(351, 66, 91, 18));
    jBtnDwnLoad.addActionListener(new java.awt.event.ActionListener() {
      public void actionPerformed(ActionEvent e) {
        jBtnDwnLoad_actionPerformed(e);
      }
    });
    jBtnDwnLoad.setText("Download");
    jBtnDwnLoad.setEnabled(false);
    jBtnDwnLoad.setActionCommand("DownLoad");
    jBtnDwnLoad.setBounds(new Rectangle(14, 20, 91, 18));
    jBtnReProg.setBounds(new Rectangle(228, 20, 100, 18));
    jBtnReProg.setEnabled(false);
    jBtnReProg.setActionCommand("DownLoad");
    jBtnReProg.setToolTipText("");
    jBtnReProg.setText("ReProgram");
    jBtnReProg.addActionListener(new java.awt.event.ActionListener() {
      public void actionPerformed(ActionEvent e) {
        jBtnReProg_actionPerformed(e);
      }
    });

    TxtSrecFileName.setEnabled(false);
    TxtSrecFileName.setFont(new java.awt.Font("Dialog", 1, 12));
    TxtSrecFileName.setBounds(new Rectangle(77, 44, 364, 18));
    label2.setBounds(new Rectangle(16, 38, 60, 26));
    label2.setText("File name");
    jPanel2.setBorder(titledBorder3);
    jPanel2.setBounds(new Rectangle(15, 69, 457, 53));
    jPanel2.setLayout(null);
    label4.setText("Mote Id");
    label4.setBounds(new Rectangle(161, 24, 45, 17));
    label3.setText("Group Id");
    label3.setBounds(new Rectangle(245, 25, 54, 17));
    TxtMoteId.setBounds(new Rectangle(207, 21, 36, 21));
    TxtGroupId.setBounds(new Rectangle(299, 22, 36, 21));
    jPanel3.setLayout(null);
    jPanel3.setBounds(new Rectangle(14, 11, 457, 53));
    jPanel3.setBorder(titledBorder2);
    TxtCommPort.setEnabled(false);
    TxtCommPort.setBounds(new Rectangle(121, 20, 54, 18));
    label1.setText("Comm");
    label1.setBounds(new Rectangle(74, 15, 39, 27));
    jPanel4.setBorder(titledBorder1);
    jPanel4.setBounds(new Rectangle(16, 126, 457, 298));
    jPanel4.setLayout(null);
    jFileChooser1.setBounds(new Rectangle(38, 37, 388, 227));
    jFileChooser1.setEnabled(false);
    jFileChooser1.setBorder(BorderFactory.createRaisedBevelBorder());
    String sPath = getLocalDirName();
    sPath += "\\srec";
    jFileChooser1.setCurrentDirectory(new java.io.File(sPath));
    //jFileChooser1.setCurrentDirectory(new java.io.File("D:\\tinyos-1.x\\tools\\java\\net\\tinyos\\xnp\\srec"));
    jFileChooser1.addActionListener(new java.awt.event.ActionListener() {
      public void actionPerformed(ActionEvent e) {
        jFileChooser1_actionPerformed(e);
      }
    });
    TxtBatteryVolts.setBounds(new Rectangle(399, 21, 49, 21));
    TxtBatteryVolts.setEnabled(false);
    TxtBatteryVolts.setText("N/U");
    label9.setBounds(new Rectangle(338, 23, 57, 17));
    label9.setText("Battery(V)");
    label10.setBounds(new Rectangle(184, 15, 39, 27));
    label10.setText("Baud");
    TxtCommBaud.setBounds(new Rectangle(225, 21, 57, 18));
    TxtCommBaud.setEnabled(false);
    TxtCommStatus.setForeground(Color.black);
    TxtCommStatus.setBounds(new Rectangle(333, 20, 110, 18));
    label11.setText("Status");
    label11.setBounds(new Rectangle(286, 17, 39, 27));
    jCheckBox1.setText("jCheckBox1");
    jCheckBox1.setBounds(new Rectangle(46, 26, 13, 13));
    jCheckBox1.addActionListener(new java.awt.event.ActionListener() {
      public void actionPerformed(ActionEvent e) {
        jCheckBox1_actionPerformed(e);
      }
    });
    label12.setBounds(new Rectangle(7, 24, 35, 17));
    label12.setText("Bcast");
    jBtnQry.setBounds(new Rectangle(117, 20, 91, 18));
    jBtnQry.setActionCommand("Query");
    jBtnQry.setEnabled(false);
    jBtnQry.setToolTipText("");
    jBtnQry.setText("Query");
    jBtnQry.addActionListener(new java.awt.event.ActionListener() {
      public void actionPerformed(ActionEvent e) {
        jBtnQry_actionPerformed(e);
      }
    });
    jCheckBoxXGB1.setText("jCheckBox1");
    jCheckBoxXGB1.setBounds(new Rectangle(53, 25, 13, 13));
    jCheckBoxXGB1.addActionListener(new java.awt.event.ActionListener() {
      public void actionPerformed(ActionEvent e) {
        jCheckBoxXGB1_actionPerformed(e);
      }
    });
    label14.setBounds(new Rectangle(9, 21, 44, 17));
    label14.setText("XGenB");
    jPanel1.add(jBtnDwnLoad, null);
    jPanel1.add(label2, null);
    jPanel1.add(TxtSrecFileName, null);
    jPanel1.add(label7, null);
    jPanel1.add(TxtProgramID, null);
    jPanel1.add(jBtnProgram1, null);
    jPanel1.add(jBtnReProg, null);
    jPanel1.add(TxtStatus, null);
    jPanel1.add(label8, null);
    jPanel1.add(TxtLength, null);
    jPanel1.add(label6, null);
    jPanel1.add(jBtnQry, null);
    contentPane.add(jPanel3, null);
    jPanel3.add(TxtCommStatus, null);
    jPanel3.add(label11, null);
    jPanel3.add(TxtCommBaud, null);
    jPanel3.add(label10, null);
    jPanel3.add(TxtCommPort, null);
    jPanel3.add(label1, null);
    jPanel3.add(label14, null);
    jPanel3.add(jCheckBoxXGB1, null);
    contentPane.add(jPanel2, null);
    jPanel2.add(label12, null);
    jPanel2.add(jCheckBox1, null);
    jPanel2.add(label9, null);
    jPanel2.add(TxtBatteryVolts, null);
    jPanel2.add(label4, null);
    jPanel2.add(TxtGroupId, null);
    jPanel2.add(label3, null);
    jPanel2.add(TxtMoteId, null);
    contentPane.add(jPanel4, null);
    jPanel4.add(jFileChooser1, null);
    contentPane.add(jPanel1, null);
    TxtMoteId.setText(Integer.toString((int)wMoteId));
    TxtGroupId.setText(Integer.toString((int)group_id));
//    CodeInj.SetXSG(bXGenericBase);
  }
  //Overridden so we can exit when window is closed
  protected void processWindowEvent(WindowEvent e) {
    super.processWindowEvent(e);
    if (e.getID() == WindowEvent.WINDOW_CLOSING) {
      System.exit(0);
    }
  }
/*-----------------------------------------------------------------------------
 * Enable/disable bcast download to all motes
 *-----------------------------------------------------------------------------*/
  void jCheckBox1_actionPerformed(ActionEvent e) {

    if (bDownLoadBcast){
     bDownLoadBcast = false;
     TxtMoteId.enable();
   }
     else{
       bDownLoadBcast = true;
       TxtMoteId.disable();
     }
  return;
  }
/*-----------------------------------------------------------------------------
 * Enable/disable XGenericBase
 *-----------------------------------------------------------------------------*/
  void jCheckBoxXGB1_actionPerformed(ActionEvent e) {

    if (bXGenericBase){
      bXGenericBase = false;
    }
    else{
      bXGenericBase = true;
    }
    CodeInj.SetXSG(bXGenericBase);
  }
/*-----------------------------------------------------------------------------
 * Do Query. Used mainly in bcast mode. Expect any mote that has missing
 * code capsules to respond
 *-----------------------------------------------------------------------------*/
  void jBtnQry_actionPerformed(ActionEvent e) {
    xnpQry Xdq;
    if (!MoteParamsOK()) return;
    Xdq = new xnpQry(this,CodeInj,wMoteId); //start thread
    Xdq.run();
  }

/*-----------------------------------------------------------------------------
 * Cmd motes to reprogram
  *Wait for reprogramming, then ask for prog_id
 *-----------------------------------------------------------------------------*/
void jBtnReProg_actionPerformed(ActionEvent e) {
  int CMD1_RETRY = 3;
  int CMD1_SLEEP = 100;  // * 10 msec
  int CMD2_RETRY = 10;
  int CMD2_SLEEP = 100;  // * 10 msec


  if (!MoteParamsOK()) return;
  TxtStatus.setText("Waiting for mote(s) to reprogram");
  CodeInj.CmdStartISP(wMoteId, false, CMD1_RETRY, CMD1_SLEEP);
  boolean bRet = CodeInj.CmdQryProgId(wMoteId,true, true, CMD2_RETRY, CMD2_SLEEP);   //request prog_id
  if (bRet){
       if((short)CodeInj.m_prog_id_rcvd  == (short)CodeInj.prog_id)
          TxtStatus.setText("Rcvd correct program id after rebooting");
       else
          TxtStatus.setText("Rcvd INCORRECT program id after rebooting " +
                            Integer.toString(((short)(CodeInj.m_prog_id_rcvd) & 0xffff), 16) );
        return;
   }
   TxtStatus.setText("No response on query for program id after rebooting");
  }
/*-----------------------------------------------------------------------------
 * Cmd to start/abort the download
 *-----------------------------------------------------------------------------*/
  void jBtnDwnLoad_actionPerformed(ActionEvent e) {

    if (bDownLoading){
         jBtnDwnLoad.setText("Download");
         TxtStatus.setText("Download aborted");
         bDownLoading = false;
         if ( bThreadRunning) rt2.stop();
         if ( bThread2Running) rt3.stop();
         bThreadRunning = false;
         bThread2Running = false;
         return;
     }
    else {
      if (!MoteParamsOK()) return;    //check for valid mote_id and group_id
      jBtnDwnLoad.setText("Abort");
      bDownLoading = true;
      if (bDownLoadBcast)DownloadBcast();      //load code to all motes
      else               DownloadMote();       //load code to single mote
      if (!bDownLoading){
        jBtnDwnLoad.setText("Download");
      }
    }
  }
/*-----------------------------------------------------------------------------
 * Download code to single mote
 *----------------------------------------------------------------------------*/
  void DownloadMote(){
    int iSleep = 50;

      if (!bDownLoading) return;
      TxtStatus.setText("Sending request to start program download");
      boolean bRet = CodeInj.CmdStartDwnload(wMoteId, true, 1,iSleep);
      if (!bRet){
            TxtStatus.setText("No response from Mote after initiating download ");
            bDownLoading = false;
            return;
      }
      if (!CodeInj.m_bCmdAccepted){
            TxtStatus.setText("Command refused by Mote after initiating download ");
            bDownLoading = false;
            return;
      }
      // if (!CodeInj.m_bBatteryVoltsOK){
      //      TxtStatus.setText("Mote battery voltage too low to program");
      //      return;
       //}
          double fBV = ((float)CodeInj.m_BatteryVolts)/1000.0;
          TxtBatteryVolts.setText(Double.toString(fBV));   //dply mote battery volts
//xmit code capsules to mote
        TxtStatus.setText("Downloading code");
        XDwn = new xnpXmitCode(this,CodeInj,wMoteId); //start thread
        rt2 = new Thread(XDwn);         //create thread for MicaCodeInj
        rt2.setDaemon(true);                      //thread dies when Main dies
        rt2.start();
        bThreadRunning = true;
    }
/*-----------------------------------------------------------------------------
 * Bcast download code to all motes
 *----------------------------------------------------------------------------*/
  void DownloadBcast(){
  int itries = 3;
  int iSleep = 25;

   TxtStatus.setText("Sending request to start program download");
   CodeInj.CmdStartDwnload(wMoteId, false, itries,iSleep);

//xmit code capsules to mote
    TxtStatus.setText("Downloading code");
    XDwn = new xnpXmitCode(this,CodeInj,wMoteId); //start thread
    rt2 = new Thread(XDwn);         //create thread for MicaCodeInj
    rt2.setDaemon(true);                      //thread dies when Main dies
    rt2.start();
    bThreadRunning = true;
  }

/*-----------------------------------------------------------------------------
* EndDownLoad
* -End download of code capsules.
* -If single mote xfer then this is the end of the download before ISP.
* -If bcast mote xfer then this is end of bcast of code capsules to all motes
*  before entering the query state to ask for missing capsules.
*-----------------------------------------------------------------------------*/
  public void EndDownLoad(){
    bDownLoading = false;
    int MAX_RETRY = 5;

    if (bDownLoadBcast){                            //broadcast download?
      TxtStatus.setText("Terminating download");
      CodeInj.CmdTerminateLoad((short)TOS_BROADCAST_ADDR, false, MAX_RETRY, 20);  //request termination
      XDwn2 = new xnpQry(this,CodeInj,wMoteId);     //start qry thread for missing packets
      rt3 = new Thread(XDwn2);                      //create qry thread
      rt3.setDaemon(true);
      rt3.start();
      bThread2Running = true;
    }
    if (!bDownLoadBcast){
       jBtnDwnLoad.setText("Download");                 //download complete
       TxtStatus.setText("Waiting for mote to terminate download");
       boolean bRet = CodeInj.CmdTerminateLoad(wMoteId,true, MAX_RETRY, 10);  //request termination
       if (bRet) TxtStatus.setText("Download terminated after capsule# " + Integer.toString((short)(CodeInj.m_NmbCodeCapsulesXmitted) ) );
       else      TxtStatus.setText("No response on termination request");
       bRet = CodeInj.CmdQryCapsules(wMoteId,wMoteId,false, 2, 100);
       if ( bThreadRunning) rt2.stop();
       bThreadRunning = false;
    }
  }
/*-----------------------------------------------------------------------------
* EndBcastDownLoad
* -Terminate bcast download of code capsules
*-----------------------------------------------------------------------------*/
  public void EndBcastDownLoad(){
    if (bThread2Running){
        bThread2Running = false;
        bDownLoading = false;
        jBtnDwnLoad.setText("Download");
        rt3.stop();
      }
  }
/*-----------------------------------------------------------------------------
* MoteParamsOK
* -if not promiscous download then chk for goot mote_id
*  else set wMoteId to broadcast address;
* -Chk for good group_id
* -Set group_id
*-----------------------------------------------------------------------------*/
  boolean MoteParamsOK() {

//check for valid mote_id
    wMoteId = (short)TOS_BROADCAST_ADDR;
    if (!bDownLoadBcast){
      wMoteId = Short.parseShort(TxtMoteId.getText());    //mode id to download
      if ((wMoteId < 0) || (wMoteId > 255)){
        TxtStatus.setText("Aborting: Bad Mote ID");
        return false;
      }
    }
//check for valid group_id
    group_id = Short.parseShort(TxtGroupId.getText());    //group id to download
    if ((group_id < 0) || (group_id > 255)){
     TxtStatus.setText("Aborting: Bad Group ID");
     return false;
    }
    CodeInj.setGroupID(group_id);
    return true;
  }
/*-----------------------------------------------------------------------------
* Display a status message in the text box
*-----------------------------------------------------------------------------*/
public void SetStatusTxt(String sStatus){
       TxtStatus.setText(sStatus);
}
/*-----------------------------------------------------------------------------
* Display the comm port/baud rate and status text box
*-----------------------------------------------------------------------------*/
public void SetCommTxt(String sStatus){
       TxtCommPort.setText(sCommPort);
       TxtCommBaud.setText(Integer.toString(BaudRate));
       TxtCommStatus.setText(sStatus);
}
/*-----------------------------------------------------------------------------
* Select an .srec file to download
*-----------------------------------------------------------------------------*/
  void jFileChooser1_actionPerformed(ActionEvent e) {
    String ActionCommand = e.getActionCommand();
    if (ActionCommand == "ApproveSelection"){
      File fileSrec = jFileChooser1.getSelectedFile();
      sSrecFileName = fileSrec.getPath();
      TxtSrecFileName.setText(sSrecFileName);
      if (CodeInj.readSrecCode(sSrecFileName)){
       if (bCommOpen){
        TxtProgramID.setText(Integer.toString(((short)(xnpUtil.prog_id) & 0xffff), 16));
        TxtLength.setText(Integer.toString(xnpUtil.m_NmbCodeCapsules));
        jBtnDwnLoad.setEnabled(true);
        jBtnReProg.setEnabled(true);
        jBtnQry.setEnabled(true);
       }
       else TxtStatus.setText("Download disabled: Comm port not open");

      }
      else{
        TxtSrecFileName.setText("Invalid file");
      }
    }
  }
  public String getClassName(){
    String thisClassName;
    thisClassName = this.getClass().getName();
    thisClassName = thisClassName.substring(thisClassName.lastIndexOf(".")+1,thisClassName.length());
    thisClassName += ".class";
    return thisClassName;
 }
 public String getLocalDirName(){
   String localDirName;
   java.net.URL myURL = this.getClass().getResource(getClassName());
   localDirName = myURL.getPath();
   localDirName = localDirName.substring(0,localDirName.lastIndexOf("/"));
   return localDirName;
 }
/*-----------------------------------------------------------------------------
*    SrecFileFilter Class: Add a file filter to a file chooser object
*-----------------------------------------------------------------------------*/
public class SrecFileFilter extends FileFilter {

  public SrecFileFilter() {  }
// Accept all directories and .srec files.
    public boolean accept(File f) {
        if (f.isDirectory()) return true;
        String extension = getExtension(f);
        if (extension != null) {
            if (extension.equals("srec")) return true;
            else                          return false;
               }
        return false;
    }
// The description of this filter
    public String getDescription() {
        return ".srec files";
    }
// Find extension of file
    private String getExtension(File f) {
        String ext = null;
        String s = f.getName();
        int i = s.lastIndexOf('.');

        if (i > 0 &&  i < s.length() - 1) {
            ext = s.substring(i+1).toLowerCase();
        }
        return ext;
    }
    public final static String srec = "srec";
}

 public static void main(String[] args) {

   try {
     UIManager.setLookAndFeel(UIManager.getSystemLookAndFeelClassName());
   }
   catch(Exception e) {
     e.printStackTrace();
   }

   xnp XFrame = new xnp();
   XFrame.show();
  // XFrame.SetCommTxt();
   try{
       CodeInj = new xnpUtil(sCommPort,BaudRate,bXGenericBase); //create comport interface for COM1?
       rSerialStub = CodeInj.getStub();                           // r = serial port, COM1
       rSerialStub.Open();
       rSerialStub.registerPacketListener(CodeInj);
       Thread rt = new Thread(CodeInj);                      //create thread for MicaCodeInj
       rt.setDaemon(true);                              //thread dies when Main dies
       rt.start();
       XFrame.SetCommTxt("Port open");
       XFrame.bCommOpen = true;
   }
    catch(Exception e) {
      XFrame.TxtCommStatus.setForeground(Color.red);
      XFrame.SetCommTxt("Cannot open port");
      XFrame.bCommOpen = false;
   }

 }

}
