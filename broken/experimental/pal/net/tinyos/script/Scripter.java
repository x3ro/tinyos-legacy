/*									tab:4
 * "Copyright (c) 2000-2003 The Regents of the University  of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and
 * its documentation for any purpose, without fee, and without written
 * agreement is hereby granted, provided that the above copyright
 * notice, the following two paragraphs and the author appear in all
 * copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY
 * PARTY FOR DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL
 * DAMAGES ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS
 * DOCUMENTATION, EVEN IF THE UNIVERSITY OF CALIFORNIA HAS BEEN
 * ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 *
 * Copyright (c) 2002-2003 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
/* Authors:	Phil Levis <pal@cs.berkeley.edu>
 * Date:        Sep 30 2003
 * Desc:        Main window for script injector.
 *               
 */

/**
 * @author Phil Levis <pal@cs.berkeley.edu>
 */


package net.tinyos.script;

import java.awt.*;
import java.awt.event.*;
import java.awt.font.*;
import java.io.*;
import java.net.*;
import java.util.*;
import java.util.regex.*;
import javax.swing.*;
import javax.swing.border.*;

import net.tinyos.message.*;
import net.tinyos.packet.*;
import net.tinyos.util.*;
import net.tinyos.script.tree.*;
import vm_specific.*;

public class Scripter extends JFrame implements net.tinyos.message.MessageListener {

  private JMenuBar    menuBar;
    
  private JPanel      leftPanel;

  private JLabel      titleLabel;
    
  private JPanel      moteIDPanel;
  private JLabel      moteIDLabel;
  private JTextField   moteIDText;
    
  private JPanel      versionPanel;
  private JLabel      versionLabel;
  private JTextField  versionText;

  private JLabel      spacerLabel;
    
  private JPanel      selectionPanel;
  private JLabel      selectorLabel;
  private JLabel      optionLabel;
  private CapsuleSelector selector;
  private OptionSelector options;
  private VariablePanel variablePanel;
  
  private JPanel      buttonPanel;
  private JButton     injectButton;
  private JButton compileButton;
  private JButton     quitButton;
  
  
  private JPanel      rightPanel;
  private JLabel      programLabel;
  private JPanel      programLabelPanel;
  private JTextArea   programArea;

  private JPanel      primitivePanel;
  
  private MoteIF moteIF;

  private ErrorDialog dialog = null;
  private String context = "";
  private String cause = "";
  private String capsule = "";
  private String instruction = "";
    
  private ScriptAssembler assembler;

  private Vector primitives;
  private String configFileName;
  private String constantClassName;
  private ConstantMapper capsuleMap;
  private ConstantMapper optionMap;
  private ConstantMapper errorMap;
  private ConstantMapper opcodeMap;
  private ConstantMapper virusMap;
  
  private Configuration config;

  private Hashtable programTable;
  private Hashtable compiledProgramTable;
  private Hashtable versionTable;
  
  public Scripter(String source,
		  String configFileName,
		  String programFileName) throws Exception {
    super("TinyOS VM Scripter");
    this.configFileName = configFileName;
    config = loadConfiguration();
    System.out.println("Loaded configuration.");
    assembler = new ScriptAssembler(opcodeMap);

    TinyLook.setLookAndFeel(this);
    menuBar = new JMenuBar();
    menuBar.setFont(TinyLook.defaultFont());
    JMenu fileMenu = new JMenu();
    fileMenu.setText("File");
    JMenuItem quitItem = new JMenuItem();
    quitItem.setText("Quit");
    quitItem.addActionListener(new QuitActionListener(this));
    quitItem.setFont(TinyLook.defaultFont());
    fileMenu.add(quitItem);
    menuBar.add(fileMenu);
    this.setJMenuBar(menuBar);
	
    Font font = TinyLook.defaultFont();
	
    programArea = new JTextArea(24, 16);
    programArea.setFont(TinyLook.constFont());
    programArea.setBorder(new EtchedBorder());
    programTable = new Hashtable();
    compiledProgramTable = new Hashtable();
    versionTable = new Hashtable();
    
    variablePanel = new VariablePanel();
    
    programLabel = new JLabel("Program Text");
    programLabel.setFont(TinyLook.boldFont());
    programLabel.setAlignmentX(LEFT_ALIGNMENT);
    programLabelPanel = new JPanel();
    programLabelPanel.add(programLabel);
    programLabelPanel.setBorder(new EtchedBorder());
	
    leftPanel = new JPanel();
    leftPanel.setBorder(new EmptyBorder(10, 10, 10, 10));
    leftPanel.setAlignmentX(CENTER_ALIGNMENT);
    leftPanel.setFont(font);

    titleLabel = new JLabel("Tiny Script for " + config.vmName());
    titleLabel.setBorder(new EmptyBorder(10, 0, 10, 0));
    titleLabel.setFont(TinyLook.boldFont().deriveFont((float)14.0));
    titleLabel.setAlignmentX(CENTER_ALIGNMENT);
	
    createMotePanel();
    createVersionPanel();
    createSelectionPanel();
    createButtonPanel(TinyLook.boldFont());

    leftPanel.add(titleLabel);
    leftPanel.add(moteIDPanel);
    leftPanel.add(selectionPanel);
    leftPanel.add(variablePanel);
    leftPanel.add(buttonPanel);

    GridBagLayout layout = new GridBagLayout();
    GridBagConstraints gridConsts = new GridBagConstraints();
    gridConsts.fill = GridBagConstraints.BOTH;
    gridConsts.gridwidth = GridBagConstraints.REMAINDER;
    gridConsts.anchor = GridBagConstraints.CENTER;
	
    layout.setConstraints(titleLabel, gridConsts);
    layout.setConstraints(moteIDPanel, gridConsts);
    layout.setConstraints(selectionPanel, gridConsts);
    layout.setConstraints(buttonPanel, gridConsts);
    leftPanel.setLayout(layout);

	
    rightPanel = new JPanel();
	
    rightPanel.setLayout(new BoxLayout(rightPanel, BoxLayout.Y_AXIS));
    rightPanel.add(programLabelPanel);
    rightPanel.add(programArea);
    rightPanel.setFont(font);
    rightPanel.setBorder(new EtchedBorder());

    primitivePanel = new PrimitivePanel();
    primitivePanel.setBorder(new EtchedBorder());
	
    getContentPane().setLayout(new GridLayout(0, 3));
	
    getContentPane().add(leftPanel);
    getContentPane().add(rightPanel);
    getContentPane().add(primitivePanel);

    System.out.println("Loading saved scripter state.");
    loadPrograms(programFileName);
    
    setVisible(true);
    startListener(source);
    pack();
    changeToCapsule(selector.getSelected());	
    variablePanel.setVariables(SymbolTable.getSharedVariables());
  }

  private Configuration loadConfiguration() throws Exception {
    Configuration configuration = null;
    primitives = new Vector();
    try {
      configuration = new Configuration(configFileName);
      Enumeration prims = configuration.primitives();
      while (prims.hasMoreElements()) {
	String pName = (String)prims.nextElement();
	primitives.add(PrimitiveSet.getPrimitive(pName));
      }
      constantClassName = configuration.constantClassName();
    }
    catch (Exception exception) {
      System.err.println("Could not load configuration in " + configFileName);
      throw exception;
    }
	
    capsuleMap = new ConstantMapper(constantClassName, "MATE_CAPSULE_");
    optionMap = new ConstantMapper(constantClassName, "MATE_OPTION_");
    errorMap = new ConstantMapper(constantClassName, "MATE_ERROR_");
    opcodeMap = new ConstantMapper(constantClassName, "OP");
    virusMap = new ConstantMapper(constantClassName, "MVIRUS_");
    return configuration;
  }

  private void loadPrograms(String filename) {
    try {
      FileReader reader = new FileReader(filename);
      DFTokenizer tok = new DFTokenizer(reader);
      while (tok.hasMoreStatements()) {
	DFStatement statement = tok.nextStatement();
	if (statement == null) {continue;}
	if (statement.getType().toUpperCase().equals("HANDLER")) {
	  String name = statement.get("name");
	  String version = statement.get("version");
	  String code = statement.get("code");
	  programTable.put(name, code);
	  versionTable.put(name, version);
	  try {
	    System.err.println("  Recompiling stored " + name + " handler.");
	    StringReader stringReader = new StringReader(code);
	    Parser p = new Parser(new Yylex(stringReader));
	    p.parse();
	    Program prog = Parser.getProgram();
	    compiledProgramTable.put(name, prog);
	  }
	  catch (Exception e) {
	    System.err.println(e);
	    return;
	  }
	}
	else if (statement.getType().toUpperCase().equals("VARIABLE")) {
	  String name = statement.get("name");
	  String val = statement.get("val");
	  Integer iVal = new Integer(val);
	  SymbolTable.putSharedVariable(name, iVal.intValue());
	}
      }
    }
    catch (FileNotFoundException exception) {
      System.out.println("No program state found, instantiating.");
    }
    catch (IOException exception) {
      System.err.println("Error reading program file.");
      exception.printStackTrace();
    }
  }
  
  private String getType(int type) {
    return capsuleMap.codeToName((byte)type);
  }
    
  private String getCause(int cause) {
    return errorMap.codeToName((byte)cause);
  }
    
  public void messageReceived(int to, Message m) {
    try {
      BombillaErrorMsg msg = (BombillaErrorMsg)m;
      String context = getType(msg.get_context());
      String cause = getCause((int)msg.get_reason());
      String capsule = getType(msg.get_capsule());
      String instruction = "" + msg.get_instruction();
      if ((!this.context.equals(context)) ||
	  (!this.cause.equals(cause)) ||
	  (!this.capsule.equals(capsule)) ||
	  (!this.instruction.equals(instruction))) {
	this.context = context;
	this.cause = cause;
	this.capsule = capsule;
	this.instruction = instruction;
	System.out.println("Error received:");
	System.out.println("  Context:     " + context);
	System.out.println("  Cause:       " + cause);
	System.out.println("  Capsule:     " + capsule);
	System.out.println("  Instruction: " + instruction);
	System.out.println();
	updateDialog(context, cause, capsule, instruction);
      }
    }
    catch (ClassCastException e) {
      System.err.println("Erroneously received a non-error message.");
      System.err.println(m);
    }
    catch (Exception e) {
      System.err.println("Exception thrown when receiving packets.");
      e.printStackTrace();
    }
  }

  private void updateDialog(String context, String cause, String capsule, String instruction) {
    Point p = null;
    if (dialog != null) {
      p = dialog.getLocation();
      dialog.dispose();
    }

    dialog = new ErrorDialog(context, cause, capsule, instruction);
    if (p != null) {
      dialog.setLocation(p);
    }
	
    dialog.show();
  }
    
  protected void inject() throws IOException, InvalidInstructionException  {
    String program = programArea.getText();
    StringReader reader = new StringReader(program);
    Parser p = new Parser(new Yylex(reader));
    Program prog;
    try {
      System.out.println("Compiling " + selector.getSelected() + " handler script version " + versionText.getText() + ".");
      p.parse();
      //      System.out.println("Getting program.");
      prog = Parser.getProgram();
      StringWriter writer = new StringWriter();
      System.out.println("  Generating assembly.");
      prog.generateCode(new CodeWriter(writer));
      //System.out.println("Getting assembly text.");
      program = writer.getBuffer().toString();
    }
    catch (Exception e) {
      System.err.println(e);
      return;
    }
	
    reader = new StringReader(program);
    
    //System.out.println("Tokenizing code:\n" + program);
    AssemblyTokenizer tok = new AssemblyTokenizer(reader);
    System.out.println("  Assembling to instruction set.");
    byte[] code = assembler.toByteCodes(tok);

    reader = new StringReader(program);
    tok = new AssemblyTokenizer(reader);
    String codeStr = assembler.toHexString(tok);

    //System.out.println("Sending program: " + codeStr);
    incrementVersion();
    versionTable.put(selector.getSelected().toLowerCase(),
		     versionText.getText());

    CapsuleMsg msg = new CapsuleMsg();
    byte num;
    byte type;
    int version;
    num = (byte)selector.getType();
    type = (byte)(num | (byte)options.getOptions());
    msg.set_capsule_type(type);
    version = Integer.parseInt(versionText.getText(), 16);
    msg.set_capsule_version((char)(version & 0xffffffff));
    byte[] sCode = new byte[code.length];
    for (int i = 0; i < code.length; i++) {
      sCode[i] = code[i];
    }
    msg.set_capsule_code(sCode);
    msg.set_capsule_codeLen(code.length);

    // Chunk it up and send those out
    int chunkSize = virusMap.nameToCode("CHUNK_SIZE");
    byte[] capsule = msg.dataGet();
    int numChunks = (sCode.length + chunkSize - 1) / chunkSize;
    System.err.print("Sending " + numChunks + " chunks (" + sCode.length + "," + chunkSize + "): ");
    for (byte i = 0; i < numChunks; i++) {
      CapsuleChunkMsg chunk = new CapsuleChunkMsg();
      chunk.set_version(version);
      chunk.set_capsuleNum(num);
      chunk.set_piece(i);
      short[] chunkData = new short[chunkSize];
      for (int j = 0; j < chunkSize; j++) {
	chunkData[j] = capsule[i * chunkSize + j];
      }
      chunk.set_chunk(chunkData);
      
      int moteID = Integer.parseInt(moteIDText.getText(), 16);
      moteIF.send(moteID, chunk);
      System.out.print("+");
    }
    System.out.println();

    programTable.put(selector.getSelected().toLowerCase(), programArea.getText());
    compiledProgramTable.put(selector.getSelected().toLowerCase(), prog);
    gcSharedVariables();
    variablePanel.setVariables(SymbolTable.getSharedVariables());
  }

  /* See if any shared variables are no longer in use. If this
     is the case, clear them. */
  private void gcSharedVariables() {
    System.out.println("Garbage collecting variables");
    Enumeration vars = SymbolTable.getSharedVariables().elements();
    while (vars.hasMoreElements()) { // For each variable
      boolean used = false;
      String var = (String)vars.nextElement();
      Enumeration progs = compiledProgramTable.keys();
      //System.out.println("Checking variable " + var);
      while (progs.hasMoreElements()) {        // In each program
	String progName = (String)progs.nextElement();
	//System.out.println("  Checking program " + progName);
	Program prog = (Program)compiledProgramTable.get(progName);
	Enumeration referenced = prog.getSharedVariables().elements();
	while (referenced.hasMoreElements()) {
	  SharedDeclaration decl = (SharedDeclaration)referenced.nextElement();
	  //System.out.print("    Checking reference " + decl.getName() + ":");
	  if (decl.getName().toLowerCase().equals(var.toLowerCase())) {
	    used = true;
	    //System.out.println(" used");
	    break;
	  }
	  //System.out.println();
	}
	if (used) {
	  break;
	}
      }
      if (!used) {
	//System.err.println("Revoking shared variable " + var);
	SymbolTable.revokeSharedVariable(var);
      }
    }
  }
  
  
  private void incrementVersion() {
    Integer iVal = new Integer(versionText.getText());
    int i = iVal.intValue();
    i++;
    versionText.setText("" + i);
  }
  
  protected String getProgramText() {
    return programArea.getText();
  }

  protected void changeToCapsule(String capsule) {
    String version = (String)versionTable.get(capsule.toLowerCase());
    if (version == null || version.equals("")) {
      version = "0";
    }
    versionText.setText(version);
    programArea.setText((String)programTable.get(capsule.toLowerCase()));
  }
  
  private void createMotePanel() {
    moteIDPanel = new JPanel();
    moteIDPanel.setBorder(new EtchedBorder());
    moteIDPanel.setLayout(new BoxLayout(moteIDPanel, BoxLayout.X_AXIS));
    moteIDPanel.setAlignmentX(CENTER_ALIGNMENT);

    moteIDLabel = new JLabel("Mote ID");
    moteIDLabel.setBorder(new EmptyBorder(0, 10, 0, 10));
    moteIDLabel.setFont(TinyLook.boldFont());
    moteIDText = new JTextField("0", 4);
    moteIDText.setFont(new Font("Courier", Font.PLAIN, 12));
    moteIDPanel.add(moteIDLabel);
    moteIDPanel.add(moteIDText);
    moteIDText.setMaximumSize(new Dimension(34, 25));
    moteIDText.setMinimumSize(new Dimension(34, 25));
	
    versionLabel = new JLabel("Handler Version");
    versionLabel.setBorder(new EmptyBorder(0, 10, 0, 10));
    versionLabel.setFont(TinyLook.boldFont());
    versionText = new JTextField("0", 4);
    moteIDPanel.add(versionLabel);
    moteIDPanel.add(versionText);
    versionText.setMaximumSize(new Dimension(50, 25));
    versionText.setMinimumSize(new Dimension(50, 25));
  }
    
  private void createVersionPanel() {
    versionPanel = new JPanel();
    //versionPanel.setLayout(new BoxLayout(versionPanel, BoxLayout.X_AXIS));
    //versionPanel.setBorder(new EmptyBorder(5, 0, 10, 0));
    //versionPanel.setAlignmentX(LEFT_ALIGNMENT);
	
  }

  private void createSelectionPanel() {
    selectionPanel = new JPanel();
    JPanel subLeftPanel = new JPanel();
    JPanel subRightPanel = new JPanel();

    subLeftPanel.setBorder(new EmptyBorder(10, 10, 10, 10));
    subLeftPanel.setLayout(new BoxLayout(subLeftPanel, BoxLayout.Y_AXIS));
    subRightPanel.setBorder(new EmptyBorder(10, 10, 10, 10));
    subRightPanel.setLayout(new BoxLayout(subRightPanel, BoxLayout.Y_AXIS));
    selectionPanel.setLayout(new BoxLayout(selectionPanel, BoxLayout.X_AXIS));
    selectionPanel.setBorder(new EtchedBorder());
	
    selectorLabel = new JLabel("Event Handler");
    selectorLabel.setFont(TinyLook.boldFont());
    selectorLabel.setBorder(new EmptyBorder(0, 0, 10, 0));
    selector = new CapsuleSelector(capsuleMap, this);
    selectorLabel.setAlignmentY(TOP_ALIGNMENT);
    selector.setAlignmentY(TOP_ALIGNMENT);
	
    optionLabel = new JLabel("Handler Options");
    optionLabel.setFont(TinyLook.boldFont());
    optionLabel.setBorder(new EmptyBorder(0, 0, 10, 0));
    options = new OptionSelector(optionMap);
    optionLabel.setAlignmentY(TOP_ALIGNMENT);
    options.setAlignmentY(TOP_ALIGNMENT);

    subLeftPanel.add(selectorLabel);
    subLeftPanel.add(selector);

    //subRightPanel.add(optionLabel);
    //subRightPanel.add(options);

    subLeftPanel.setAlignmentY(TOP_ALIGNMENT);
    subRightPanel.setAlignmentY(TOP_ALIGNMENT);
    subRightPanel.setAlignmentX(RIGHT_ALIGNMENT);
	
    selectionPanel.add(subLeftPanel);
    selectionPanel.add(subRightPanel);
    selectionPanel.setAlignmentX(CENTER_ALIGNMENT);
  }

  private void createButtonPanel(Font font) {
    injectButton = new InjectButton(this);
    injectButton.setFont(font);
    injectButton.setAlignmentX(CENTER_ALIGNMENT);

    compileButton = new CompileButton(this);
    compileButton.setFont(font);
    compileButton.setAlignmentX(RIGHT_ALIGNMENT);
    compileButton.setEnabled(false);
    
    buttonPanel = new JPanel();
    buttonPanel.setLayout(new GridLayout(2,1));
    buttonPanel.add(injectButton);
    buttonPanel.add(compileButton);
    buttonPanel.setAlignmentX(CENTER_ALIGNMENT);
    buttonPanel.setBorder(new EtchedBorder());
  }

  private void startListener(String source) {
    moteIF = new MoteIF(BuildSource.makePhoenix(source, PrintStreamMessenger.err));
    moteIF.registerListener(new BombillaErrorMsg(), this);
    moteIF.start();
  }

  private class QuitButton extends JButton {
    private Scripter scripter;
    
    public QuitButton(Scripter s) {
      super("Quit");
      scripter = s;
      addActionListener(new QuitActionListener(s));
      setAlignmentX(CENTER_ALIGNMENT);
    }
  }

  private class QuitActionListener implements ActionListener {
    private Scripter scripter;

    public QuitActionListener(Scripter s) {
      scripter = s;
    }
    public void actionPerformed(ActionEvent e) {
	scripter.writeState();
	System.exit(0);
      }
    }
  private class InjectButton extends JButton {
    public InjectButton(Scripter inject) {
      super("Inject");
      addActionListener(new InjectListener(inject));
      setAlignmentX(CENTER_ALIGNMENT);
    }

    private class InjectListener implements ActionListener {
      private Scripter injector;
	    
      public InjectListener(Scripter injector) {
	this.injector = injector;
      }

      public void actionPerformed(ActionEvent e) {
	try {
	  injector.inject();
	}
	catch (IOException exception) {
	  System.err.println("ERROR: Couldn't inject packet: " + exception);
	}
	catch (InvalidInstructionException exception) {
	  System.err.println("ERROR: Invalid instruction: " + exception);
	}
      }
    }
	
  }

  private class CompileButton extends JButton {
    public CompileButton(Scripter scripter) {
      super("Compile to Primitive");
      addActionListener(new CompileListener(scripter));
      setAlignmentX(RIGHT_ALIGNMENT);
    }

    private class CompileListener implements ActionListener {
      private Scripter scripter;

      public CompileListener(Scripter scripter) {
	this.scripter = scripter;
      }

      public void actionPerformed(ActionEvent e) {
	try {
	  String text = scripter.getProgramText();
	  VMDescriptionDialog desc = new VMDescriptionDialog(scripter);
	  OpcodeSaveDialog osDialog = new OpcodeSaveDialog();
	  int rval = osDialog.showSaveDialog(scripter);
	  if (rval != JFileChooser.APPROVE_OPTION) {return;}

	  CompositeOpcode composite = new CompositeOpcode(desc.getName(), text);

	  String name = desc.getName();

	  osDialog.writeModule(name, composite.getModule());
	  osDialog.writeConfiguration(name, composite.getConfiguration());
	  osDialog.writeDescription(name, desc.getDesc());
	}
	
	catch (IOException exception) {
	  System.err.println("ERROR: Couldn't build instruction: " + exception);
	}
	catch (InvalidInstructionException exception) {
	  System.err.println("Invalid instruction: " + exception.getMessage());
	}
	catch (Exception exception) {
	  System.err.println("Exception thrown when trying to create composite opcode.");
	  exception.printStackTrace();
	}
      }
    }
  }

  private class OpcodeSaveDialog extends JFileChooser {

    public OpcodeSaveDialog() {
      super("Save Composite Opcode");
      setFileSelectionMode(JFileChooser.DIRECTORIES_ONLY);
    }

    protected void writeModule(String name, String text) throws IOException {
      File dir = getSelectedFile();
      File module = new File(dir.getAbsolutePath() + "/OP" + name + "M.nc");
      FileWriter writer = new FileWriter(module);

      System.err.println("Writing " + module);
      writer.write(text);
      writer.close();
    }

    protected void writeConfiguration(String name, String text) throws IOException {
      File dir = getSelectedFile();
      File conf = new File(dir.getAbsolutePath() + "/OP" + name + ".nc");
      FileWriter writer = new FileWriter(conf);

      System.err.println("Writing " + conf);
      writer.write(text);
      writer.close();
    }

    protected void writeDescription(String name, String desc) throws IOException {
      File dir = getSelectedFile();
      File odf = new File(dir.getAbsolutePath() + "/OP" + name + ".odf");
      FileWriter writer = new FileWriter(odf);
      String msg = "<PRIMITIVE ";
      msg += "NAME=" + name.toUpperCase() + " ";
      msg += "OPCODE=" + name + " ";
      msg += "DESC=\"" + desc + "\">";

      System.err.println("Writing " + odf);
      writer.write(msg);
      writer.close();
    }
    
  }
  
  public static void main(String[] args) {
    try {
      int index = 0;
      String source = "sf@localhost:9001";
      String filename = "vm.vmdf";
      String progName = "programs.vmdf";
      while (index < args.length) {
	String arg = args[index];
	if (arg.equals("-h") || arg.equals("--help")) {
	  usage();
	  System.exit(0);
	}
	else if (arg.equals("-comm")) {
	  index++;
	  source = args[index];
	}
	else {
	  usage();
	  System.exit(1);
	}
	index++;
      }
      System.out.println("Starting Scripter with source " + source);
      Scripter window = new Scripter(source, filename, progName);
    } 
	
    catch (Exception e) {
      System.err.println(e);
      System.err.println();
      System.err.println("ERROR: Could not create a Scripter. Are you in an application directory?");

    }
  }
    
  private static void usage() {
    System.err.println("usage: Scripter [-h|--help|-comm <source>] (default is SerialForwarder 1.1)");
  }

  protected void writeState() {
    System.out.println("Writing state.");
    try {
      Writer writer = new FileWriter("programs.vmdf");
      Enumeration handlers = versionTable.keys();
      Date d = new Date();
      writer.write("// Generated for " + config.vmName() + " at " + d + "\n");
      while (handlers.hasMoreElements()) {
	String name = (String)handlers.nextElement();
	writer.write("<HANDLER ");
	writer.write("name=\"" + name + "\" ");
	writer.write("version=\"" + versionTable.get(name.toLowerCase()) + "\" ");
	writer.write("code=\"" + programTable.get(name.toLowerCase()) + "\" ");
	writer.write(">\n");
      }
      
      Enumeration vars = SymbolTable.getSharedVariables().elements();
      
      while (vars.hasMoreElements()) {
	String var = (String)vars.nextElement();
	writer.write("<VARIABLE ");
	writer.write("name=\"" + var + "\" ");
	writer.write("val=\"" + SymbolTable.getShared(var) + "\" ");
	writer.write(">\n");
      }
      writer.write("\n");
      writer.close();
    }
    catch (IOException exception) {
      System.err.println("Error writing out state.");
      exception.printStackTrace();
    }
  }
    
}
