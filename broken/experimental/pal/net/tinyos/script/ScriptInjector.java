/*									tab:4
 * "Copyright (c) 2000-2003 The Regents of the University  of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
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
import javax.swing.*;
import javax.swing.border.*;

import net.tinyos.message.*;
import net.tinyos.packet.*;
import net.tinyos.util.*;
//import net.tinyos.vm_asm.*;
import net.tinyos.script.tree.*;
import vm_specific.*;

public class ScriptInjector extends JFrame implements net.tinyos.message.MessageListener {

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

  private JPanel      buttonPanel;
  private JButton     injectButton;
  private JButton     quitButton;
    
  private JPanel      rightPanel;
  private JLabel      programLabel;
  private JPanel      programLabelPanel;
  private JTextArea   programArea;

  private MoteIF moteIF;
    
  private ErrorDialog dialog = null;
  private String context = "";
  private String cause = "";
  private String capsule = "";
  private String instruction = "";
    
  private ScriptAssembler assembler;

  private ConstantMapper errorMapper;
  private ConstantMapper capsuleMapper;
  private ConstantMapper optionMapper;
  private ConstantMapper virusMapper;
  
  public ScriptInjector(String source, String constants) throws Exception {
    super("TinyOS VM Code Injector");

    TinyLook.setLookAndFeel(this);
    assembler = new ScriptAssembler(new ConstantMapper(constants, "OP"));

    errorMapper = new ConstantMapper(constants, "MATE_ERROR");
    capsuleMapper = new ConstantMapper(constants, "MATE_CAPSULE");
    optionMapper = new ConstantMapper(constants, "MATE_OPTION");
    virusMapper = new ConstantMapper(constants, "MVIRUS");
    
    menuBar = new JMenuBar();
    menuBar.setFont(TinyLook.defaultFont());
    JMenu fileMenu = new JMenu();
    fileMenu.setText("File");
    JMenuItem quitItem = new JMenuItem();
    quitItem.setText("Quit");
    quitItem.addActionListener(new java.awt.event.ActionListener() {
	public void actionPerformed(java.awt.event.ActionEvent evt) {
	  System.exit(0);
	}
      });
    quitItem.setFont(TinyLook.defaultFont());
    fileMenu.add(quitItem);
    menuBar.add(fileMenu);
    this.setJMenuBar(menuBar);
	
    Font font = TinyLook.defaultFont();
	
    programArea = new JTextArea(24, 16);
    programArea.setFont(TinyLook.constFont());
    programArea.setBorder(new EtchedBorder());
	
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

    titleLabel = new JLabel("Mate Assembler");
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
	
    getContentPane().setLayout(new GridLayout(0, 2));
	
    getContentPane().add(leftPanel);
    getContentPane().add(rightPanel);

    setVisible(true);

    startListener(source);
    pack();
  }

  private String getType(int type) {
    return capsuleMapper.codeToName((byte)type);
  }
    
  private String getCause(int cause) {
    return errorMapper.codeToName((byte)cause);
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


  private String compileProgram(StringReader reader) throws IOException, InvalidInstructionException, Exception, SemanticException {
    Parser p = new Parser(new Yylex(reader));
    System.out.println("Parsing program.");
    p.parse();
    System.out.println("Getting program.");
    Program prog = Parser.getProgram();
    StringWriter writer = new StringWriter();
    System.out.println("Generating code.");
    prog.generateCode(new CodeWriter(writer));
    System.out.println("Getting assembly text.");
    return writer.getBuffer().toString();
  }

  private byte[] assembleInstructions(StringReader reader) throws IOException, InvalidInstructionException {
    System.out.println("Tokenizing code.");
    AssemblyTokenizer tok = new AssemblyTokenizer(reader);
    System.out.println("Assembling.");
    return assembler.toByteCodes(tok);
  }
  
  protected void inject() throws IOException, InvalidInstructionException  {
    // First, parse the program to VM instructions
    String program = programArea.getText();
    StringReader reader = new StringReader(program);
    String instructions;

    // Compile the program to instructions
    try {
      instructions = compileProgram(reader);
    }
    catch (Exception e) {
      System.err.println(e);
      e.printStackTrace();
      return;
    }

    // Then assemble those instructions to opcodes
    reader = new StringReader(instructions);
    System.err.println("Instructions:" + instructions);
    byte[] code = assembleInstructions(reader);

    // Print out the opcodes (sanity check for GUI)
    System.out.println("Printing program.");
    reader = new StringReader(instructions);
    AssemblyTokenizer tok = new AssemblyTokenizer(reader);
    String codeStr = assembler.toHexString(tok);
    //    System.out.println("Sending program: " + codeStr);

    // Build the program structure
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
    int chunkSize = virusMapper.nameToCode("CHUNK_SIZE");
    byte[] capsule = msg.dataGet();
    int numChunks = (capsule.length + chunkSize - 1) / chunkSize;
    System.err.print("Sending chunks: ");
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
	
    versionLabel = new JLabel("Capsule Version");
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
	
    selectorLabel = new JLabel("Capsule Type");
    selectorLabel.setFont(TinyLook.boldFont());
    selectorLabel.setBorder(new EmptyBorder(0, 0, 10, 0));
    selector = new CapsuleSelector(capsuleMapper);
    selectorLabel.setAlignmentY(TOP_ALIGNMENT);
    selector.setAlignmentY(TOP_ALIGNMENT);
	
    optionLabel = new JLabel("Capsule Options");
    optionLabel.setFont(TinyLook.boldFont());
    optionLabel.setBorder(new EmptyBorder(0, 0, 10, 0));
    options = new OptionSelector(optionMapper);
    optionLabel.setAlignmentY(TOP_ALIGNMENT);
    options.setAlignmentY(TOP_ALIGNMENT);

    subLeftPanel.add(selectorLabel);
    subLeftPanel.add(selector);

    subRightPanel.add(optionLabel);
    subRightPanel.add(options);

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
	
    buttonPanel = new JPanel();
    buttonPanel.setLayout(new GridLayout(1,1));
    buttonPanel.add(injectButton);
    buttonPanel.setAlignmentX(CENTER_ALIGNMENT);
    buttonPanel.setBorder(new EtchedBorder());
  }

  private void startListener(String source) {
    moteIF = new MoteIF(BuildSource.makePhoenix(source, PrintStreamMessenger.err));
    moteIF.registerListener(new BombillaErrorMsg(), this);
    moteIF.start();
  }

  private class QuitButton extends JButton {
    public QuitButton() {
      super("Quit");
      addActionListener(new QuitListener());
      setAlignmentX(CENTER_ALIGNMENT);
    }
    private class QuitListener implements ActionListener {
      public void actionPerformed(ActionEvent e) {
	System.exit(0);
      }
    }
  }

  private class InjectButton extends JButton {
    public InjectButton(ScriptInjector inject) {
      super("Inject");
      addActionListener(new InjectListener(inject));
      setAlignmentX(CENTER_ALIGNMENT);
    }

    private class InjectListener implements ActionListener {
      private ScriptInjector injector;
	    
      public InjectListener(ScriptInjector injector) {
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
	  System.err.println("Invalid instruction: " + exception.getMessage());
	}
      }
    }
	
  }

  public static void main(String[] args) {
    try {
      int index = 0;
      String source = "sf@localhost:9001";
      String constantsFile = null;
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
	else if (constantsFile == null) {
	  constantsFile = arg;
	}
	else {
	  usage();
	  System.exit(1);
	}
	index++;
      }
      System.out.println("Starting ScriptInjector with source " + source);
      ScriptInjector window = new ScriptInjector(source, constantsFile);
    } 
	
    catch (Exception e) {
      e.printStackTrace();
    }
  }
    
  private static void usage() {
    System.err.println("usage: ScriptInjector [-h|--help|-comm <source>] (default is SerialForwarder 1.1) <constants class>");
  }
	   
    
    
}
