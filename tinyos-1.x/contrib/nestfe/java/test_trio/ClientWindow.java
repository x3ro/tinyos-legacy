// Author: Jaein Jeong
// ClientWindow.java
// This files is the main engine of bandwidth measurement program.
// 

package test_trio;

import net.tinyos.util.*;
import net.tinyos.message.*;
import java.io.*;
import java.awt.*;
import java.text.*;
import javax.swing.*;
import javax.swing.border.*;
import javax.swing.plaf.basic.*;
import javax.swing.filechooser.FileFilter;
import java.awt.event.*;
import javax.swing.event.*;
import java.sql.Time;
import java.sql.Date;
import java.sql.Timestamp;
import java.util.Timer;
import java.util.TimerTask;

public class ClientWindow extends JPanel implements WindowListener, MessageListener, ActionListener, ItemListener
{
  final static short CMD_REDLED    = 0;
  final static short CMD_GREENLED  = 1;
  final static short CMD_YELLOWLED = 2;

  final static short CMD_SOUNDER   = 10;
  final static short CMD_SOUNDER_READ  = 11;
  final static short REPLY_SOUNDER_READ  = 12;

  final static short CMD_X1226      = 20;
  final static short CMD_X1226_SET  = 21;
  final static short CMD_X1226_READ = 22;
  final static short REPLY_X1226_READ = 23;

  final static short SUBCMD_X1226_STATUS  = 0;
  final static short SUBCMD_X1226_INT     = 1;
  final static short SUBCMD_X1226_RTC     = 2;
  final static short SUBCMD_X1226_ALM0    = 3;
  final static short SUBCMD_X1226_ALM1    = 4;

  final static short CMD_IOSWITCH1_INIT = 30;
  final static short CMD_IOSWITCH1_SET  = 31;
  final static short CMD_IOSWITCH1_CLR  = 32;
  final static short CMD_IOSWITCH1_READ = 33;
  final static short REPLY_IOSWITCH1_READ = 34;
  final static short REPLY_IOSWITCH1_INTERRUPT = 35;

  final static short CMD_IOSWITCH2_INIT = 40;
  final static short CMD_IOSWITCH2_SET  = 41;
  final static short CMD_IOSWITCH2_CLR  = 42;
  final static short CMD_IOSWITCH2_READ = 43;
  final static short REPLY_IOSWITCH2_READ = 44;
  final static short REPLY_IOSWITCH2_INTERRUPT = 45;

  final static short CMD_PWSWITCH_INIT  = 50;
  final static short CMD_PWSWITCH_SET   = 51;
  final static short CMD_PWSWITCH_READ  = 52;
  final static short REPLY_PWSWITCH_READ = 53;
  final static short CMD_PWSWITCH_GETADC = 54;
  final static short REPLY_PWSWITCH_ADCREADY = 55;

  final static short CMD_PIR                = 60;
  final static short CMD_PIR_POT_ADJUST     = 61;
  final static short CMD_PIR_POT_READ       = 62;
  final static short REPLY_PIR_POT_READ     = 63;
  final static short CMD_PIR_GETADC         = 64;
  final static short REPLY_PIR_ADCREADY     = 65;

  final static short SUBCMD_PIR_DETECT      = 0;
  final static short SUBCMD_PIR_QUAD        = 1;

  final static short CMD_MAG                = 70;
  final static short CMD_MAG_POT_ADJUST     = 71;
  final static short CMD_MAG_POT_READ       = 72;
  final static short REPLY_MAG_POT_READ     = 73;
  final static short CMD_MAG_GETADC         = 74;
  final static short REPLY_MAG_ADCREADY     = 75;
  final static short CMD_MAG_SETRESET       = 76;

  final static short SUBCMD_MAG_GAINX       = 0;
  final static short SUBCMD_MAG_GAINY       = 1;
  final static short SUBCMD_MAG_ADC0        = 2;
  final static short SUBCMD_MAG_ADC1        = 3;

  final static short CMD_MIC                = 80;
  final static short CMD_MIC_POT_ADJUST     = 81;
  final static short CMD_MIC_POT_READ       = 82;
  final static short REPLY_MIC_POT_READ     = 83;
  final static short CMD_MIC_GETADC         = 84;
  final static short REPLY_MIC_ADCREADY     = 85;

  final static short SUBCMD_MIC_GAIN        = 0;
  final static short SUBCMD_MIC_DETECT      = 1;
  final static short SUBCMD_MIC_LPF0        = 2;
  final static short SUBCMD_MIC_LPF1        = 3;
  final static short SUBCMD_MIC_HPF0        = 4;
  final static short SUBCMD_MIC_HPF1        = 5;

  final static short CMD_GRENADE            = 90;

  final static short CMD_PROMETHEUS_GETVOLTAGE     = 100;
  final static short REPLY_PROMETHEUS_GETVOLTAGE   = 101;
  final static short CMD_PROMETHEUS_SET_STATUS     = 102;
  final static short CMD_PROMETHEUS_GET_STATUS     = 103;
  final static short REPLY_PROMETHEUS_GET_STATUS   = 104;

  final static short SUBCMD_PROMETHEUS_REFVOL = 0;
  final static short SUBCMD_PROMETHEUS_CAPVOL = 1;
  final static short SUBCMD_PROMETHEUS_BATTVOL = 2;

  final static short SUBCMD_PROMETHEUS_AUTOMATIC    = 0;
  final static short SUBCMD_PROMETHEUS_POWERSOURCE  = 1;
  final static short SUBCMD_PROMETHEUS_CHARGING     = 2;
  final static short SUBCMD_PROMETHEUS_ADCSOURCE    = 3;

  final static short CMD_DEBUG_MSG          = 250;
  final static short REPLY_DEBUG_MSG        = 251;

  final static short SUBCMD_OFF = 0;
  final static short SUBCMD_ON  = 1;

  final static short MASK_X1226_ENABLE_ALARM = 0x80;
  final static short MASK_X1226_DISABLE_ALARM = 0x00;
  final static short MASK_X1226_ENABLE_INT = 0xa0;
  final static short MASK_X1226_DISABLE_INT = 0x00;

  final static short MASK_PWR_SW      = 0x01;
  final static short MASK_CHARGE_SW   = 0x02;
  final static short MASK_PW_ACOUSTIC = 0x04;
  final static short MASK_PW_MAG      = 0x08;
  final static short MASK_PW_PIR      = 0x10;
  final static short MASK_PW_SOUNDER  = 0x20;
  final static short MASK_MAG_SR      = 0x80;

  final static short MASK_INT_ACOUSTIC = 0x01;
  final static short MASK_INT_PIR      = 0x02;

  final static short MASK_I2C_SW      = 0x01;
  final static short MASK_MCU_RESET   = 0x02;
  final static short MASK_GRENADE_CK  = 0x04;

  final static short MASK_BAT_ADC     = 0x44;
  final static short MASK_EXT_ADC     = 0x88;

  final static String LEDS_PANEL = "Leds";
  final static String IOSWITCH1_PANEL = "IO Switch 1";
  final static String IOSWITCH2_PANEL = "IO Switch 2";
  final static String X1226_PANEL     = "X1226";
  final static String PWSWITCH_PANEL  = "PW Switch";
  final static String PIR_PANEL       = "PIR";
  final static String MAG_PANEL       = "Magnetometer";
  final static String MIC_PANEL       = "Microphone";
  final static String SOUNDER_PANEL   = "Sounder";
  final static String PROMETHEUS_PANEL = "Prometheus";
  final static String GRENADE_PANEL   = "Grenade Timer";
  final static String STATUS_PANEL = "Status";

  JPanel        comboBoxPane    = new JPanel();
  String        comboBoxItems[] = { LEDS_PANEL, 
                                    IOSWITCH1_PANEL, 
                                    IOSWITCH2_PANEL, 
                                    X1226_PANEL, 
                                    PWSWITCH_PANEL, 
                                    PIR_PANEL, 
                                    MAG_PANEL, 
                                    MIC_PANEL, 
                                    SOUNDER_PANEL, 
                                    PROMETHEUS_PANEL, 
                                    GRENADE_PANEL, 
                                  };
  JLabel        labelCB         = new JLabel("Select Operations:");
  JComboBox     cb              = null;
  JPanel        cards           = null;

  TitledBorder  borderLeds    = new TitledBorder("Leds");
  JPanel        panelLeds     = new JPanel();
  JButton       btnLedsRedOn  = new JButton("red On");
  JButton       btnLedsRedOff = new JButton("red Off");
  JButton       btnLedsGreenOn   = new JButton("green On");
  JButton       btnLedsGreenOff  = new JButton("green Off");
  JButton       btnLedsYellowOn  = new JButton("yellow On");
  JButton       btnLedsYellowOff = new JButton("yellow Off");

  TitledBorder  borderSounder = new TitledBorder("Sounder");
  JPanel        panelSounder  = new JPanel();
  JButton       btnSounderOn  = new JButton("On");
  JButton       btnSounderOff = new JButton("Off");
  JButton       btnSounderRead = new JButton("Read");

  TitledBorder  borderX1226 = new TitledBorder("X1226");
  JPanel        panelX1226  = new JPanel();
  JLabel        labelX1226Min   = new JLabel("Alarm0 (min)");
  JTextField    fieldX1226Min   = new JTextField();
  JLabel        labelX1226Sec   = new JLabel("Alarm0 (sec)");
  JTextField    fieldX1226Sec   = new JTextField();

  JRadioButton  btnX1226DisableAlarm = new JRadioButton("Disable Alarm");
  JRadioButton  btnX1226EnableAlarm = new JRadioButton("Enable Alarm");
  ButtonGroup   group4          = new ButtonGroup();

  JButton       btnX1226SetAlarm   = new JButton("Set Alarm");
  JButton       btnX1226ReadAlarm  = new JButton("Read Alarm");

  JButton       btnX1226ResetClock = new JButton("Reset Clk");
  JButton       btnX1226ReadClock = new JButton("Read Clk");
  JButton       btnX1226ReadStatus = new JButton("Status");
  JButton       btnX1226EnableInt = new JButton("Enable Int");
  JButton       btnX1226DisableInt = new JButton("Disable Int");
  JButton       btnX1226ReadInt = new JButton("Read Int");

  TitledBorder  borderIOSwitch1 = new TitledBorder("IO Switch 1");
  JPanel        panelIOSwitch1  = new JPanel();
  JRadioButton  btnPwrSw        = new JRadioButton("Pwr_Sw");
  JRadioButton  btnChargeSw     = new JRadioButton("Charge_Sw");
  JRadioButton  btnPwAcoustic   = new JRadioButton("Pw_Acoustic");
  JRadioButton  btnPwMag        = new JRadioButton("Pw_Mag");
  JRadioButton  btnPwPIR        = new JRadioButton("Pw_PIR");
  JRadioButton  btnPwSounder    = new JRadioButton("Pw_Sounder");
  JRadioButton  btnMagSR        = new JRadioButton("Mag_SR");
  ButtonGroup   group1          = new ButtonGroup();
  JButton       btnSetIOSwitch1 = new JButton("Set Pin");
  JButton       btnClearIOSwitch1 = new JButton("Clear Pin");
  JButton       btnReadSW1Port = new JButton("Read Port");

  TitledBorder  borderIOSwitch2 = new TitledBorder("IO Switch 2");
  JPanel        panelIOSwitch2  = new JPanel();
  JRadioButton  btnI2cSw        = new JRadioButton("I2C_Sw");
  JRadioButton  btnMcuReset     = new JRadioButton("Mcu_Reset");
  JRadioButton  btnGrenadeCk    = new JRadioButton("Grenade_Ck");
  ButtonGroup   group2          = new ButtonGroup();
  JButton       btnSetIOSwitch2 = new JButton("Set Pin");
  JButton       btnClearIOSwitch2 = new JButton("Clear Pin");
  JButton       btnReadSW2Port = new JButton("Read Port");
  
  TitledBorder  borderPWSwitch = new TitledBorder("ADC Switch");
  JPanel        panelPWSwitch  = new JPanel();
  JRadioButton  btnBatADC      = new JRadioButton("Battery ADC");
  JRadioButton  btnExtADC      = new JRadioButton("External ADC");
  ButtonGroup   group3         = new ButtonGroup();
  JButton       btnSetPWSwitch = new JButton("Set PWSW Pin");
  JButton       btnReadPWSwitch = new JButton("Read PWSW Port");
  JButton       btnGetADCMux0  = new JButton("Get ADC Mux 0");
  JButton       btnGetADCMux1  = new JButton("Get ADC Mux 1");

  TitledBorder  borderPIR     = new TitledBorder("PIR Sensor");
  JPanel        panelPIR      = new JPanel();
  JButton       btnPIROn      = new JButton("PIR On");
  JButton       btnPIROff     = new JButton("PIR Off");
  JButton       btnPIRGetADC  = new JButton("PIR ADC");
  JLabel        labelPIRDetect   = new JLabel("Pot (Detect)");
  JTextField    fieldPIRDetect   = new JTextField();
  JButton       btnPIRDetectAdjust = new JButton("Adjust");
  JButton       btnPIRDetectRead   = new JButton("Read");
  JLabel        labelPIRQuad     = new JLabel("Pot (Quad)");
  JTextField    fieldPIRQuad     = new JTextField();
  JButton       btnPIRQuadAdjust   = new JButton("Adjust");
  JButton       btnPIRQuadRead     = new JButton("Read");

  TitledBorder  borderMag     = new TitledBorder("Mag Sensor");
  JPanel        panelMag      = new JPanel();
  JButton       btnMagOn      = new JButton("Mag Sensor On");
  JButton       btnMagOff     = new JButton("Mag Sensor Off");
  JButton       btnMagGetADC0 = new JButton("Mag ADC 0");
  JButton       btnMagGetADC1 = new JButton("Mag ADC 1");
  JLabel        labelMagGainX    = new JLabel("Pot (gain X)");
  JTextField    fieldMagGainX    = new JTextField();
  JButton       btnMagGainXAdjust = new JButton("Adjust");
  JButton       btnMagGainXRead   = new JButton("Read");
  JLabel        labelMagGainY    = new JLabel("Pot (gain Y)");
  JTextField    fieldMagGainY    = new JTextField();
  JButton       btnMagGainYAdjust = new JButton("Adjust");
  JButton       btnMagGainYRead   = new JButton("Read");
  JButton       btnMagSet        = new JButton("Mag Set");
  JButton       btnMagReset      = new JButton("Mag Reset");

  TitledBorder  borderMic     = new TitledBorder("Mic Sensor");
  JPanel        panelMic      = new JPanel();
  JButton       btnMicOn      = new JButton("Mic On");
  JButton       btnMicOff     = new JButton("Mic Off");
  JButton       btnMicGetADC  = new JButton("Mic ADC");
  JLabel        labelMicLPF0    = new JLabel("Pot (LPF0)");
  JTextField    fieldMicLPF0    = new JTextField();
  JButton       btnMicLPF0Adjust = new JButton("Adjust");
  JButton       btnMicLPF0Read   = new JButton("Read");
  JLabel        labelMicLPF1    = new JLabel("Pot (LPF1)");
  JTextField    fieldMicLPF1    = new JTextField();
  JButton       btnMicLPF1Adjust = new JButton("Adjust");
  JButton       btnMicLPF1Read   = new JButton("Read");
  JLabel        labelMicHPF0    = new JLabel("Pot (HPF0)");
  JTextField    fieldMicHPF0    = new JTextField();
  JButton       btnMicHPF0Adjust = new JButton("Adjust");
  JButton       btnMicHPF0Read   = new JButton("Read");
  JLabel        labelMicHPF1    = new JLabel("Pot (HPF1)");
  JTextField    fieldMicHPF1    = new JTextField();
  JButton       btnMicHPF1Adjust = new JButton("Adjust");
  JButton       btnMicHPF1Read   = new JButton("Read");
  JLabel        labelMicGain    = new JLabel("Pot (Gain)");
  JTextField    fieldMicGain    = new JTextField();
  JButton       btnMicGainAdjust  = new JButton("Adjust");
  JButton       btnMicGainRead    = new JButton("Read");
  JLabel        labelMicDetect    = new JLabel("Pot (Detect)");
  JTextField    fieldMicDetect    = new JTextField();
  JButton       btnMicDetectAdjust  = new JButton("Adjust");
  JButton       btnMicDetectRead    = new JButton("Read");

  TitledBorder  borderPrometheus = new TitledBorder("Prometheus");
  JPanel        panelPrometheus  = new JPanel();
  JRadioButton  btnRefVol       = new JRadioButton("Ref");
  JRadioButton  btnCapVol       = new JRadioButton("Cap");
  JRadioButton  btnBattVol      = new JRadioButton("Batt");
  ButtonGroup   group5          = new ButtonGroup();
  JButton       btnReadVoltage  = new JButton("Read Voltage");
  JLabel        labelAuto       = new JLabel("Automatic Charging:");
  JButton       btnChargeAuto   = new JButton("Automatic");
  JButton       btnChargeManual = new JButton("Manual");
  JButton       btnGetChargeAuto = new JButton("Status");
  JLabel        labelPowerSource = new JLabel("Power Source:");
  JButton       btnPowerCap     = new JButton("Capacitor");
  JButton       btnPowerBatt    = new JButton("Battery");
  JButton       btnGetPowerStatus = new JButton("Status");
  JLabel        labelCharging   = new JLabel("Charging to Battery:");
  JButton       btnNoCharging   = new JButton("No Charging");
  JButton       btnCharging     = new JButton("Charging");
  JButton       btnChargingStatus = new JButton("Status");
  JLabel        labelADCSource  = new JLabel("ADC Source");
  JButton       btnADCPrometheus = new JButton("Prometheus");
  JButton       btnADCExternal   = new JButton("External");
  JButton       btnADCStatus     = new JButton("Status");

  TitledBorder  borderGrenade   = new TitledBorder("Grenade Timer");
  JPanel        panelGrenade    = new JPanel();
  JButton       btnGrenadeArm   = new JButton("Arm");
  JButton       btnGrenadeInit  = new JButton("Init");
  JButton       btnGrenadeDebug = new JButton("Read State");

  TitledBorder  borderStatus  = new TitledBorder("Status");
  JPanel        panelStatus   = new JPanel();
  JScrollPane   panelWnd      = null;
  JTextArea     msgWnd        = null;
  JButton       btnStatusClear = new JButton("Clear");

  boolean bMeasuring = false;
  int nPktRcvd = 0;

  int DEFAULT_BEACON_RATE = 2000;

  short maskIOSwitch1 = MASK_PWR_SW;
  short maskIOSwitch2 = MASK_I2C_SW;
  short maskPWSwitch = MASK_BAT_ADC;
  short maskDisableAlarm = MASK_X1226_DISABLE_ALARM;
  short maskPrometheus = SUBCMD_PROMETHEUS_REFVOL;

  boolean bMicADC_started = false;
  boolean bMagXADC_started = false;
  boolean bMagYADC_started = false;
  boolean bPIRADC_started = false;

  //Timer timer;
  MoteIF mote;

  public ClientWindow(JFrame frame) {
    enableEvents(AWTEvent.WINDOW_EVENT_MASK);
    try {
      jbInit();
    }
    catch(Exception e) {
      e.printStackTrace();
    }
  }

  void init_Layout()
  {
    cb = new JComboBox(comboBoxItems);
    cb.setEditable(false);
    cb.addItemListener(this);
    comboBoxPane.setBounds(new Rectangle(0, 0, 340, 30));
    comboBoxPane.add(labelCB);
    comboBoxPane.add(cb);

    cards = new JPanel(new CardLayout());
    cards.setBounds(new Rectangle(345, 0, 340, 400));
    cards.add(panelLeds, LEDS_PANEL);
    cards.add(panelIOSwitch1, IOSWITCH1_PANEL);
    cards.add(panelIOSwitch2, IOSWITCH2_PANEL);
    cards.add(panelX1226, X1226_PANEL);
    cards.add(panelPWSwitch, PWSWITCH_PANEL);
    cards.add(panelPIR, PIR_PANEL);
    cards.add(panelMag, MAG_PANEL);
    cards.add(panelMic, MIC_PANEL);
    cards.add(panelSounder, SOUNDER_PANEL);
    cards.add(panelPrometheus, PROMETHEUS_PANEL);
    cards.add(panelGrenade, GRENADE_PANEL);

    this.add(comboBoxPane);
    this.add(cards);
    this.add(panelStatus);
  }

  void init_panelLeds()
  {
    // panelMote
    panelLeds.setLayout(null);
    panelLeds.setBorder(borderLeds);
    panelLeds.setBounds(new Rectangle(0, 0, 340, 90));

    btnLedsRedOn.setBounds(new Rectangle(25, 20, 90, 25));
    btnLedsGreenOn.setBounds(new Rectangle(125, 20, 90, 25));
    btnLedsYellowOn.setBounds(new Rectangle(225, 20, 90, 25));
    btnLedsRedOff.setBounds(new Rectangle(25, 55, 90, 25));
    btnLedsGreenOff.setBounds(new Rectangle(125, 55, 90, 25));
    btnLedsYellowOff.setBounds(new Rectangle(225, 55, 90, 25));

    btnLedsRedOn.addActionListener(this);
    btnLedsRedOff.addActionListener(this);
    btnLedsGreenOn.addActionListener(this);
    btnLedsGreenOff.addActionListener(this);
    btnLedsYellowOn.addActionListener(this);
    btnLedsYellowOff.addActionListener(this);

    panelLeds.add(btnLedsRedOn);
    panelLeds.add(btnLedsRedOff);
    panelLeds.add(btnLedsGreenOn);
    panelLeds.add(btnLedsGreenOff);
    panelLeds.add(btnLedsYellowOn);
    panelLeds.add(btnLedsYellowOff);

    //this.add(panelLeds);
  }

  void init_panelIOSwitch1() 
  {
    panelIOSwitch1.setLayout(null);
    panelIOSwitch1.setBorder(borderIOSwitch1);
    panelIOSwitch1.setBounds(new Rectangle(0, 0, 340, 160));
    //panelIOSwitch1.setBounds(new Rectangle(0, 100, 340, 160));

    btnPwrSw.setBounds      (new Rectangle(15, 20, 90, 25));
    btnChargeSw.setBounds   (new Rectangle(115, 20, 100, 25));
    btnPwAcoustic.setBounds (new Rectangle(215, 20, 110, 25));
    btnPwMag.setBounds      (new Rectangle(15, 55, 90, 25));
    btnPwPIR.setBounds      (new Rectangle(115, 55, 90, 25));
    btnPwSounder.setBounds  (new Rectangle(215, 55, 100, 25));
    btnMagSR.setBounds      (new Rectangle(15, 90, 90, 25));

    btnSetIOSwitch1.setBounds(new Rectangle(25, 125, 90, 25));
    btnClearIOSwitch1.setBounds(new Rectangle(125, 125, 90, 25));
    btnReadSW1Port.setBounds(new Rectangle(225, 125, 90, 25));

    group1.add(btnPwrSw);
    group1.add(btnChargeSw);
    group1.add(btnPwAcoustic);
    group1.add(btnPwMag);
    group1.add(btnPwPIR);
    group1.add(btnPwSounder);
    group1.add(btnMagSR);
    btnPwrSw.setSelected(true);

    btnPwrSw.addActionListener(this);
    btnChargeSw.addActionListener(this);
    btnPwAcoustic.addActionListener(this);
    btnPwMag.addActionListener(this);
    btnPwPIR.addActionListener(this);
    btnPwSounder.addActionListener(this);
    btnMagSR.addActionListener(this);
    btnSetIOSwitch1.addActionListener(this);
    btnClearIOSwitch1.addActionListener(this);
    btnReadSW1Port.addActionListener(this);

    panelIOSwitch1.add(btnPwrSw);
    panelIOSwitch1.add(btnChargeSw);
    panelIOSwitch1.add(btnPwAcoustic);
    panelIOSwitch1.add(btnPwMag);
    panelIOSwitch1.add(btnPwPIR);
    panelIOSwitch1.add(btnPwSounder);
    panelIOSwitch1.add(btnMagSR);
    panelIOSwitch1.add(btnSetIOSwitch1);
    panelIOSwitch1.add(btnClearIOSwitch1);
    panelIOSwitch1.add(btnReadSW1Port);

    //this.add(panelIOSwitch1);
  }

  void init_panelIOSwitch2()
  {
    panelIOSwitch2.setLayout(null);
    panelIOSwitch2.setBorder(borderIOSwitch2);
    panelIOSwitch2.setBounds(new Rectangle(0, 0, 340, 90));
    //panelIOSwitch2.setBounds(new Rectangle(0, 270, 340, 90));
  
    btnI2cSw.setBounds      (new Rectangle(15, 20, 90, 25));
    btnMcuReset.setBounds   (new Rectangle(105, 20, 90, 25));
    btnGrenadeCk.setBounds  (new Rectangle(205, 20, 100, 25));
  
    btnSetIOSwitch2.setBounds(new Rectangle(25, 55, 90, 25));
    btnClearIOSwitch2.setBounds(new Rectangle(125, 55, 90, 25));
    btnReadSW2Port.setBounds(new Rectangle(225, 55, 90, 25));
  
    group2.add(btnI2cSw);
    group2.add(btnMcuReset);
    group2.add(btnGrenadeCk);
    btnI2cSw.setSelected(true);
  
    btnI2cSw.addActionListener(this);
    btnMcuReset.addActionListener(this);
    btnGrenadeCk.addActionListener(this);
    btnSetIOSwitch2.addActionListener(this);
    btnClearIOSwitch2.addActionListener(this);
    btnReadSW2Port.addActionListener(this);
  
    panelIOSwitch2.add(btnI2cSw);
    panelIOSwitch2.add(btnMcuReset);
    panelIOSwitch2.add(btnGrenadeCk);
    panelIOSwitch2.add(btnSetIOSwitch2);
    panelIOSwitch2.add(btnClearIOSwitch2);
    panelIOSwitch2.add(btnReadSW2Port);
  
    //this.add(panelIOSwitch2);
  }

  void init_panelX1226()
  {
    panelX1226.setLayout(null);
    panelX1226.setBorder(borderX1226);
    panelX1226.setBounds(new Rectangle(0, 0, 340, 195));
    //panelX1226.setBounds(new Rectangle(0, 370, 340, 195));

    labelX1226Min.setBounds(new Rectangle(25, 20, 75, 25));
    fieldX1226Min.setBounds(new Rectangle(110, 20, 50, 25));

    labelX1226Sec.setBounds(new Rectangle(180, 20, 75, 25));
    fieldX1226Sec.setBounds(new Rectangle(265, 20, 50, 25));

    btnX1226DisableAlarm.setBounds(new Rectangle(25, 55, 135, 25));
    btnX1226EnableAlarm.setBounds(new Rectangle(180, 55, 135, 25));
    group4.add(btnX1226DisableAlarm);
    group4.add(btnX1226EnableAlarm);
    btnX1226DisableAlarm.setSelected(true);

    btnX1226SetAlarm.setBounds(new Rectangle(120, 90, 100, 25));
    btnX1226ReadAlarm.setBounds(new Rectangle(230, 90, 100, 25));

    btnX1226ResetClock.setBounds(new Rectangle(10, 125, 100, 25));
    btnX1226ReadClock.setBounds(new Rectangle(120, 125, 100, 25));
    btnX1226ReadStatus.setBounds(new Rectangle(230, 125, 100, 25));
    btnX1226EnableInt.setBounds(new Rectangle(10, 160, 100, 25));
    btnX1226DisableInt.setBounds(new Rectangle(120, 160, 100, 25));
    btnX1226ReadInt.setBounds(new Rectangle(230, 160, 100, 25));
    btnX1226DisableAlarm.addActionListener(this);
    btnX1226EnableAlarm.addActionListener(this);
    btnX1226SetAlarm.addActionListener(this);
    btnX1226ReadAlarm.addActionListener(this);
    btnX1226ResetClock.addActionListener(this);
    btnX1226ReadClock.addActionListener(this);
    btnX1226ReadStatus.addActionListener(this);
    btnX1226EnableInt.addActionListener(this);
    btnX1226DisableInt.addActionListener(this);
    btnX1226ReadInt.addActionListener(this);
    panelX1226.add(labelX1226Min);
    panelX1226.add(fieldX1226Min);
    panelX1226.add(labelX1226Sec);
    panelX1226.add(fieldX1226Sec);
    panelX1226.add(btnX1226DisableAlarm);
    panelX1226.add(btnX1226EnableAlarm);
    panelX1226.add(btnX1226SetAlarm);
    panelX1226.add(btnX1226ReadAlarm);
    panelX1226.add(btnX1226ResetClock);
    panelX1226.add(btnX1226ReadClock);
    panelX1226.add(btnX1226ReadStatus);
    panelX1226.add(btnX1226EnableInt);
    panelX1226.add(btnX1226DisableInt);
    panelX1226.add(btnX1226ReadInt);

    //this.add(panelX1226);
  }

  void init_panelStatus()
  {
    // panelMote
    panelStatus.setLayout(null);
    panelStatus.setBorder(borderStatus);
    panelStatus.setBounds(new Rectangle(0, 40, 340, 360));
    //panelStatus.setBounds(new Rectangle(0, 575, 340, 235));

    msgWnd = new JTextArea();
    panelWnd = new JScrollPane(msgWnd);
    panelWnd.setBounds(new Rectangle(10, 20, 320, 295));

    btnStatusClear.setBounds(new Rectangle(110, 325, 135, 25));
    btnStatusClear.addActionListener(this);

    panelStatus.add(panelWnd);
    panelStatus.add(btnStatusClear);

    this.add(panelStatus);
  }

  void init_panelPWSwitch()
  {
    panelPWSwitch.setLayout(null);
    panelPWSwitch.setBorder(borderPWSwitch);
    panelPWSwitch.setBounds(new Rectangle(0, 0, 340, 125));
    //panelPWSwitch.setBounds(new Rectangle(345, 0, 340, 125));

    btnBatADC.setBounds      (new Rectangle(25, 20, 135, 25));
    btnExtADC.setBounds   (new Rectangle(180, 20, 135, 25));

    btnSetPWSwitch.setBounds(new Rectangle(25, 55, 135, 25));
    btnReadPWSwitch.setBounds(new Rectangle(180, 55, 135, 25));
    btnGetADCMux0.setBounds(new Rectangle(25, 90, 135, 25));
    btnGetADCMux1.setBounds(new Rectangle(180, 90, 135, 25)); 
    group3.add(btnBatADC);
    group3.add(btnExtADC);
    btnBatADC.setSelected(true);

    btnBatADC.addActionListener(this);
    btnExtADC.addActionListener(this);
    btnSetPWSwitch.addActionListener(this);
    btnReadPWSwitch.addActionListener(this);
    btnGetADCMux0.addActionListener(this);
    btnGetADCMux1.addActionListener(this);


    panelPWSwitch.add(btnBatADC);
    panelPWSwitch.add(btnExtADC);
    panelPWSwitch.add(btnSetPWSwitch);
    panelPWSwitch.add(btnReadPWSwitch);
    panelPWSwitch.add(btnGetADCMux0);
    panelPWSwitch.add(btnGetADCMux1);

    //this.add(panelPWSwitch);
  }

  void init_panelPIR()
  {
    // panelMote
    panelPIR.setLayout(null);
    panelPIR.setBorder(borderPIR);
    panelPIR.setBounds(new Rectangle(0, 0, 340, 125));
    //panelPIR.setBounds(new Rectangle(345, 135, 340, 125));

    btnPIROn.setBounds(new Rectangle(25, 20, 90, 25));
    btnPIROff.setBounds(new Rectangle(125, 20, 90, 25));
    btnPIRGetADC.setBounds(new Rectangle(225, 20, 90, 25));
    labelPIRDetect.setBounds(new Rectangle(25, 55, 75, 25));
    fieldPIRDetect.setBounds(new Rectangle(110, 55, 50, 25));
    btnPIRDetectAdjust.setBounds(new Rectangle(170, 55, 70, 25));
    btnPIRDetectRead.setBounds(new Rectangle(250, 55, 70, 25));
    labelPIRQuad.setBounds(new Rectangle(25, 90, 75, 25));
    fieldPIRQuad.setBounds(new Rectangle(110, 90, 50, 25));
    btnPIRQuadAdjust.setBounds(new Rectangle(170, 90, 70, 25));
    btnPIRQuadRead.setBounds(new Rectangle(250, 90, 70, 25));

    btnPIROn.addActionListener(this);
    btnPIROff.addActionListener(this);
    btnPIRGetADC.addActionListener(this);
    btnPIRDetectAdjust.addActionListener(this);
    btnPIRDetectRead.addActionListener(this);
    btnPIRQuadAdjust.addActionListener(this);
    btnPIRQuadRead.addActionListener(this);

    panelPIR.add(btnPIROn);
    panelPIR.add(btnPIROff);
    panelPIR.add(btnPIRGetADC);
    panelPIR.add(labelPIRDetect);
    panelPIR.add(fieldPIRDetect);
    panelPIR.add(btnPIRDetectAdjust);
    panelPIR.add(btnPIRDetectRead);
    panelPIR.add(labelPIRQuad);
    panelPIR.add(fieldPIRQuad);
    panelPIR.add(btnPIRQuadAdjust);
    panelPIR.add(btnPIRQuadRead);

    //this.add(panelPIR);
  }

  void init_panelMag()
  {
    // panelMote
    panelMag.setLayout(null);
    panelMag.setBorder(borderMag);
    panelMag.setBounds(new Rectangle(0, 0, 340, 195));
    //panelMag.setBounds(new Rectangle(345, 270, 340, 195));

    btnMagOn.setBounds(new Rectangle(25, 20, 135, 25));
    btnMagOff.setBounds(new Rectangle(180, 20, 135, 25));
    btnMagGetADC0.setBounds(new Rectangle(25, 55, 135, 25));
    btnMagGetADC1.setBounds(new Rectangle(180, 55, 135, 25));
    labelMagGainX.setBounds(new Rectangle(25, 90, 75, 25));
    fieldMagGainX.setBounds(new Rectangle(110, 90, 50, 25));
    btnMagGainXAdjust.setBounds(new Rectangle(170, 90, 70, 25));
    btnMagGainXRead.setBounds(new Rectangle(250, 90, 70, 25));
    labelMagGainY.setBounds(new Rectangle(25, 125, 75, 25));
    fieldMagGainY.setBounds(new Rectangle(110, 125, 50, 25));
    btnMagGainYAdjust.setBounds(new Rectangle(170, 125, 70, 25));
    btnMagGainYRead.setBounds(new Rectangle(250, 125, 70, 25));
    btnMagSet.setBounds(new Rectangle(25, 160, 135, 25));
    btnMagReset.setBounds(new Rectangle(180, 160, 135, 25));

    btnMagOn.addActionListener(this);
    btnMagOff.addActionListener(this);
    btnMagGetADC0.addActionListener(this);
    btnMagGetADC1.addActionListener(this);
    btnMagGainXAdjust.addActionListener(this);
    btnMagGainXRead.addActionListener(this);
    btnMagGainYAdjust.addActionListener(this);
    btnMagGainYRead.addActionListener(this);
    btnMagSet.addActionListener(this);
    btnMagReset.addActionListener(this);

    panelMag.add(btnMagOn);
    panelMag.add(btnMagOff);
    panelMag.add(btnMagGetADC0);
    panelMag.add(btnMagGetADC1);
    panelMag.add(labelMagGainX);
    panelMag.add(fieldMagGainX);
    panelMag.add(btnMagGainXAdjust);
    panelMag.add(btnMagGainXRead);
    panelMag.add(labelMagGainY);
    panelMag.add(fieldMagGainY);
    panelMag.add(btnMagGainYAdjust);
    panelMag.add(btnMagGainYRead);
    panelMag.add(btnMagSet);
    panelMag.add(btnMagReset);

    //this.add(panelMag);
  }

  void init_panelMic()
  {
    // panelMote
    panelMic.setLayout(null);
    panelMic.setBorder(borderMic);
    panelMic.setBounds(new Rectangle(0, 0, 340, 265));
    //panelMic.setBounds(new Rectangle(345, 475, 340, 265));

    btnMicOn.setBounds(new Rectangle(25, 20, 90, 25));
    btnMicOff.setBounds(new Rectangle(125, 20, 90, 25));
    btnMicGetADC.setBounds(new Rectangle(225, 20, 90, 25));
    labelMicLPF0.setBounds(new Rectangle(25, 55, 75, 25));
    fieldMicLPF0.setBounds(new Rectangle(110, 55, 50, 25));
    btnMicLPF0Adjust.setBounds(new Rectangle(170, 55, 70, 25));
    btnMicLPF0Read.setBounds(new Rectangle(250, 55, 70, 25));
    labelMicLPF1.setBounds(new Rectangle(25, 90, 75, 25));
    fieldMicLPF1.setBounds(new Rectangle(110, 90, 50, 25));
    btnMicLPF1Adjust.setBounds(new Rectangle(170, 90, 70, 25));
    btnMicLPF1Read.setBounds(new Rectangle(250, 90, 70, 25));
    labelMicHPF0.setBounds(new Rectangle(25, 125, 75, 25));
    fieldMicHPF0.setBounds(new Rectangle(110, 125, 50, 25));
    btnMicHPF0Adjust.setBounds(new Rectangle(170, 125, 70, 25));
    btnMicHPF0Read.setBounds(new Rectangle(250, 125, 70, 25));
    labelMicHPF1.setBounds(new Rectangle(25, 160, 75, 25));
    fieldMicHPF1.setBounds(new Rectangle(110, 160, 50, 25));
    btnMicHPF1Adjust.setBounds(new Rectangle(170, 160, 70, 25));
    btnMicHPF1Read.setBounds(new Rectangle(250, 160, 70, 25));
    labelMicGain.setBounds(new Rectangle(25, 195, 75, 25));
    fieldMicGain.setBounds(new Rectangle(110, 195, 50, 25));
    btnMicGainAdjust.setBounds(new Rectangle(170, 195, 70, 25));
    btnMicGainRead.setBounds(new Rectangle(250, 195, 70, 25));
    labelMicDetect.setBounds(new Rectangle(25, 230, 75, 25));
    fieldMicDetect.setBounds(new Rectangle(110, 230, 50, 25));
    btnMicDetectAdjust.setBounds(new Rectangle(170, 230, 70, 25));
    btnMicDetectRead.setBounds(new Rectangle(250, 230, 70, 25));

    btnMicOn.addActionListener(this);
    btnMicOff.addActionListener(this);
    btnMicGetADC.addActionListener(this);
    btnMicLPF0Adjust.addActionListener(this);
    btnMicLPF0Read.addActionListener(this);
    btnMicLPF1Adjust.addActionListener(this);
    btnMicLPF1Read.addActionListener(this);
    btnMicHPF0Adjust.addActionListener(this);
    btnMicHPF0Read.addActionListener(this);
    btnMicHPF1Adjust.addActionListener(this);
    btnMicHPF1Read.addActionListener(this);
    btnMicGainAdjust.addActionListener(this);
    btnMicGainRead.addActionListener(this);
    btnMicDetectAdjust.addActionListener(this);
    btnMicDetectRead.addActionListener(this);

    panelMic.add(btnMicOn);
    panelMic.add(btnMicOff);
    panelMic.add(btnMicGetADC);
    panelMic.add(labelMicLPF0);
    panelMic.add(fieldMicLPF0);
    panelMic.add(btnMicLPF0Adjust);
    panelMic.add(btnMicLPF0Read);
    panelMic.add(labelMicLPF1);
    panelMic.add(fieldMicLPF1);
    panelMic.add(btnMicLPF1Adjust);
    panelMic.add(btnMicLPF1Read);
    panelMic.add(labelMicHPF0);
    panelMic.add(fieldMicHPF0);
    panelMic.add(btnMicHPF0Adjust);
    panelMic.add(btnMicHPF0Read);
    panelMic.add(labelMicHPF1);
    panelMic.add(fieldMicHPF1);
    panelMic.add(btnMicHPF1Adjust);
    panelMic.add(btnMicHPF1Read);
    panelMic.add(labelMicGain);
    panelMic.add(fieldMicGain);
    panelMic.add(btnMicGainAdjust);
    panelMic.add(btnMicGainRead);
    panelMic.add(labelMicDetect);
    panelMic.add(fieldMicDetect);
    panelMic.add(btnMicDetectAdjust);
    panelMic.add(btnMicDetectRead);

    //this.add(panelMic);
  }

  void init_panelSounder()
  {
    panelSounder.setLayout(null);
    panelSounder.setBorder(borderSounder);
    panelSounder.setBounds(new Rectangle(0, 0, 340, 55));
    //panelSounder.setBounds(new Rectangle(345, 750, 340, 55));

    btnSounderOn.setBounds(new Rectangle(25, 20, 90, 25));
    btnSounderOff.setBounds(new Rectangle(125, 20, 90, 25));
    btnSounderRead.setBounds(new Rectangle(225, 20, 90, 25));

    btnSounderOn.addActionListener(this);
    btnSounderOff.addActionListener(this);
    btnSounderRead.addActionListener(this);

    panelSounder.add(btnSounderOn);
    panelSounder.add(btnSounderOff);
    panelSounder.add(btnSounderRead);

    //this.add(panelSounder);
  }

  void init_panelPrometheus()
  {
    panelPrometheus.setLayout(null);
    panelPrometheus.setBorder(borderPrometheus);
    panelPrometheus.setBounds(new Rectangle(0, 0, 340, 335));
    //panelPrometheus.setBounds(new Rectangle(690, 0, 340, 90));

    btnRefVol.setBounds   (new Rectangle(15, 20, 50, 25));
    btnCapVol.setBounds   (new Rectangle(75, 20, 50, 25));
    btnBattVol.setBounds  (new Rectangle(135, 20, 50, 25));
    btnReadVoltage.setBounds(new Rectangle(195, 20, 120, 25));
    labelAuto.setBounds(new Rectangle(15, 55, 120, 25));
    btnChargeAuto.setBounds(new Rectangle(15, 90, 100, 25));
    btnChargeManual.setBounds(new Rectangle(125, 90, 90, 25));
    btnGetChargeAuto.setBounds(new Rectangle(225, 90, 90, 25));

    labelPowerSource.setBounds(new Rectangle(15, 125, 120, 25));
    btnPowerCap.setBounds(new Rectangle(15, 160, 100, 25));
    btnPowerBatt.setBounds(new Rectangle(125, 160, 90, 25));
    btnGetPowerStatus.setBounds(new Rectangle(225, 160, 90, 25));

    labelCharging.setBounds(new Rectangle(15, 195, 120, 25));
    btnNoCharging.setBounds(new Rectangle(15, 230, 100, 25));
    btnCharging.setBounds(new Rectangle(125, 230, 90, 25));
    btnChargingStatus.setBounds(new Rectangle(225, 230, 90, 25));

    labelADCSource.setBounds(new Rectangle(15, 265, 120, 25));
    btnADCPrometheus.setBounds(new Rectangle(15, 300, 100, 25));
    btnADCExternal.setBounds(new Rectangle(125, 300, 90, 25));
    btnADCStatus.setBounds(new Rectangle(225, 300, 90, 25));

    group5.add(btnRefVol);
    group5.add(btnCapVol);
    group5.add(btnBattVol);
    btnRefVol.setSelected(true);

    btnRefVol.addActionListener(this);
    btnCapVol.addActionListener(this);
    btnBattVol.addActionListener(this);
    btnReadVoltage.addActionListener(this);
    btnChargeAuto.addActionListener(this);
    btnChargeManual.addActionListener(this);
    btnGetChargeAuto.addActionListener(this);
    btnPowerCap.addActionListener(this);
    btnPowerBatt.addActionListener(this);
    btnGetPowerStatus.addActionListener(this);
    btnNoCharging.addActionListener(this);
    btnCharging.addActionListener(this);
    btnChargingStatus.addActionListener(this);
    btnADCPrometheus.addActionListener(this);
    btnADCExternal.addActionListener(this);
    btnADCStatus.addActionListener(this);

    panelPrometheus.add(btnRefVol);
    panelPrometheus.add(btnCapVol);
    panelPrometheus.add(btnBattVol);
    panelPrometheus.add(btnReadVoltage);
    panelPrometheus.add(labelAuto);
    panelPrometheus.add(btnChargeAuto);
    panelPrometheus.add(btnChargeManual);
    panelPrometheus.add(btnGetChargeAuto);
    panelPrometheus.add(labelPowerSource);
    panelPrometheus.add(btnPowerCap);
    panelPrometheus.add(btnPowerBatt);
    panelPrometheus.add(btnGetPowerStatus);
    panelPrometheus.add(labelCharging);
    panelPrometheus.add(btnNoCharging);
    panelPrometheus.add(btnCharging);
    panelPrometheus.add(btnChargingStatus);
    panelPrometheus.add(labelADCSource);
    panelPrometheus.add(btnADCPrometheus);
    panelPrometheus.add(btnADCExternal);
    panelPrometheus.add(btnADCStatus);

    //this.add(panelPrometheus);
  }

  void init_panelGrenade()
  {
    panelGrenade.setLayout(null);
    panelGrenade.setBorder(borderGrenade);
    panelGrenade.setBounds(new Rectangle(0, 0, 340, 55));
    //panelGrenade.setBounds(new Rectangle(690, 100, 340, 55));

    btnGrenadeArm.setBounds(new Rectangle(25, 20, 90, 25));
    btnGrenadeInit.setBounds(new Rectangle(125, 20, 90, 25));
    btnGrenadeDebug.setBounds(new Rectangle(225, 20, 90, 25));

    btnGrenadeArm.addActionListener(this);
    btnGrenadeInit.addActionListener(this);
    btnGrenadeDebug.addActionListener(this);

    panelGrenade.add(btnGrenadeArm);
    panelGrenade.add(btnGrenadeInit);
    panelGrenade.add(btnGrenadeDebug);

    //this.add(panelGrenade);
  }

  private void jbInit() throws Exception {
    this.setLayout(null);
    this.setMinimumSize(new Dimension(545, 440));
    this.setPreferredSize(new Dimension(700, 440));

    init_Layout();

    init_panelLeds();
    init_panelSounder();
    init_panelX1226();
    init_panelIOSwitch1();
    init_panelStatus();
    init_panelIOSwitch2();
    init_panelPWSwitch();
    init_panelPIR();
    init_panelMag();
    init_panelMic();
    init_panelPrometheus();
    init_panelGrenade();

    try {
       mote = new MoteIF(PrintStreamMessenger.err, Injecter.group_id);
       mote.registerListener(new TestTrioMsg(), this);
       
    } catch(Exception e){
       e.printStackTrace();
       System.exit(-1);
    }
  }

  public void itemStateChanged(ItemEvent evt) {
    CardLayout cl = (CardLayout)(cards.getLayout());
    cl.show(cards, (String)evt.getItem());
  }

  public void actionPerformed(ActionEvent e)
  {
    if (e.getSource() == btnLedsRedOn) 
      btnLedsRedOn_actionPerformed(e);
    else if (e.getSource() == btnLedsRedOff) 
      btnLedsRedOff_actionPerformed(e);
    else if (e.getSource() == btnLedsGreenOn) 
      btnLedsGreenOn_actionPerformed(e);
    else if (e.getSource() == btnLedsGreenOff) 
      btnLedsGreenOff_actionPerformed(e);
    else if (e.getSource() == btnLedsYellowOn) 
      btnLedsYellowOn_actionPerformed(e);
    else if (e.getSource() == btnLedsYellowOff) 
      btnLedsYellowOff_actionPerformed(e);
    else if (e.getSource() == btnSounderOn) 
      btnSounderOn_actionPerformed(e);
    else if (e.getSource() == btnSounderOff) 
      btnSounderOff_actionPerformed(e);
    else if (e.getSource() == btnSounderRead) 
      btnSounderRead_actionPerformed(e);
    else if (e.getSource() == btnX1226DisableAlarm) 
      btnX1226DisableAlarm_actionPerformed(e);
    else if (e.getSource() == btnX1226EnableAlarm) 
      btnX1226EnableAlarm_actionPerformed(e);
    else if (e.getSource() == btnX1226SetAlarm) 
      btnX1226SetAlarm_actionPerformed(e);
    else if (e.getSource() == btnX1226ReadAlarm) 
      btnX1226ReadAlarm_actionPerformed(e);
    else if (e.getSource() == btnX1226ResetClock) 
      btnX1226ResetClock_actionPerformed(e);
    else if (e.getSource() == btnX1226ReadClock) 
      btnX1226ReadClock_actionPerformed(e);
    else if (e.getSource() == btnX1226ReadStatus) 
      btnX1226ReadStatus_actionPerformed(e);
    else if (e.getSource() == btnX1226EnableInt) 
      btnX1226EnableInt_actionPerformed(e);
    else if (e.getSource() == btnX1226DisableInt) 
      btnX1226DisableInt_actionPerformed(e);
    else if (e.getSource() == btnX1226ReadInt) 
      btnX1226ReadInt_actionPerformed(e);
    else if (e.getSource() == btnPwrSw) 
      btnPwrSw_actionPerformed(e);
    else if (e.getSource() == btnChargeSw) 
      btnChargeSw_actionPerformed(e);
    else if (e.getSource() == btnPwAcoustic) 
      btnPwAcoustic_actionPerformed(e);
    else if (e.getSource() == btnPwMag) 
      btnPwMag_actionPerformed(e);
    else if (e.getSource() == btnPwPIR) 
      btnPwPIR_actionPerformed(e);
    else if (e.getSource() == btnPwSounder) 
      btnPwSounder_actionPerformed(e);
    else if (e.getSource() == btnMagSR) 
      btnMagSR_actionPerformed(e);
    else if (e.getSource() == btnSetIOSwitch1) 
      btnSetIOSwitch1_actionPerformed(e);
    else if (e.getSource() == btnClearIOSwitch1) 
      btnClearIOSwitch1_actionPerformed(e);
    else if (e.getSource() == btnReadSW1Port) 
      btnReadSW1Port_actionPerformed(e);
    else if (e.getSource() == btnStatusClear) 
      btnStatusClear_actionPerformed(e);
    else if (e.getSource() == btnI2cSw)
      btnI2cSw_actionPerformed(e);
    else if (e.getSource() == btnMcuReset)
      btnMcuReset_actionPerformed(e);
    else if (e.getSource() == btnGrenadeCk)
      btnGrenadeCk_actionPerformed(e);
    else if (e.getSource() == btnSetIOSwitch2)
      btnSetIOSwitch2_actionPerformed(e);
    else if (e.getSource() == btnClearIOSwitch2)
      btnClearIOSwitch2_actionPerformed(e);
    else if (e.getSource() == btnReadSW2Port) 
      btnReadSW2Port_actionPerformed(e);
    else if (e.getSource() == btnBatADC)
      btnBatADC_actionPerformed(e);
    else if (e.getSource() == btnExtADC)
      btnExtADC_actionPerformed(e);
    else if (e.getSource() == btnSetPWSwitch)
      btnSetPWSwitch_actionPerformed(e);
    else if (e.getSource() == btnReadPWSwitch)
      btnReadPWSwitch_actionPerformed(e);
    else if (e.getSource() == btnGetADCMux0)
      btnGetADCMux0_actionPerformed(e);
    else if (e.getSource() == btnGetADCMux1)
      btnGetADCMux1_actionPerformed(e);
    else if (e.getSource() == btnPIROn)
      btnPIROn_actionPerformed(e);
    else if (e.getSource() == btnPIROff)
      btnPIROff_actionPerformed(e);
    else if (e.getSource() == btnPIRGetADC)
      btnPIRGetADC_actionPerformed(e);
    else if (e.getSource() == btnPIRDetectAdjust)
      btnPIRDetectAdjust_actionPerformed(e);
    else if (e.getSource() == btnPIRDetectRead)
      btnPIRDetectRead_actionPerformed(e);
    else if (e.getSource() == btnPIRQuadAdjust)
      btnPIRQuadAdjust_actionPerformed(e);
    else if (e.getSource() == btnPIRQuadRead)
      btnPIRQuadRead_actionPerformed(e);
    else if (e.getSource() == btnMagOn)
      btnMagOn_actionPerformed(e);
    else if (e.getSource() == btnMagOff)
      btnMagOff_actionPerformed(e);
    else if (e.getSource() == btnMagGetADC0)
      btnMagGetADC0_actionPerformed(e);
    else if (e.getSource() == btnMagGetADC1)
      btnMagGetADC1_actionPerformed(e);
    else if (e.getSource() == btnMagGainXAdjust)
      btnMagGainXAdjust_actionPerformed(e);
    else if (e.getSource() == btnMagGainXRead)
      btnMagGainXRead_actionPerformed(e);
    else if (e.getSource() == btnMagGainYAdjust)
      btnMagGainYAdjust_actionPerformed(e);
    else if (e.getSource() == btnMagGainYRead)
      btnMagGainYRead_actionPerformed(e);
    else if (e.getSource() == btnMagSet)
      btnMagSet_actionPerformed(e);
    else if (e.getSource() == btnMagReset)
      btnMagReset_actionPerformed(e);
    else if (e.getSource() == btnMicOn)
      btnMicOn_actionPerformed(e);
    else if (e.getSource() == btnMicOff)
      btnMicOff_actionPerformed(e);
    else if (e.getSource() == btnMicGetADC)
      btnMicGetADC_actionPerformed(e);
    else if (e.getSource() == btnMicLPF0Adjust)
      btnMicLPF0Adjust_actionPerformed(e);
    else if (e.getSource() == btnMicLPF0Read)
      btnMicLPF0Read_actionPerformed(e);
    else if (e.getSource() == btnMicLPF1Adjust)
      btnMicLPF1Adjust_actionPerformed(e);
    else if (e.getSource() == btnMicLPF1Read)
      btnMicLPF1Read_actionPerformed(e);
    else if (e.getSource() == btnMicHPF0Adjust)
      btnMicHPF0Adjust_actionPerformed(e);
    else if (e.getSource() == btnMicHPF0Read)
      btnMicHPF0Read_actionPerformed(e);
    else if (e.getSource() == btnMicHPF1Adjust)
      btnMicHPF1Adjust_actionPerformed(e);
    else if (e.getSource() == btnMicHPF1Read)
      btnMicHPF1Read_actionPerformed(e);
    else if (e.getSource() == btnMicGainAdjust)
      btnMicGainAdjust_actionPerformed(e);
    else if (e.getSource() == btnMicGainRead)
      btnMicGainRead_actionPerformed(e);
    else if (e.getSource() == btnMicDetectAdjust)
      btnMicDetectAdjust_actionPerformed(e);
    else if (e.getSource() == btnMicDetectRead)
      btnMicDetectRead_actionPerformed(e);
    else if (e.getSource() == btnRefVol)
      btnRefVol_actionPerformed(e);
    else if (e.getSource() == btnCapVol)
      btnCapVol_actionPerformed(e);
    else if (e.getSource() == btnBattVol)
      btnBattVol_actionPerformed(e);
    else if (e.getSource() == btnReadVoltage)
      btnReadVoltage_actionPerformed(e);
    else if (e.getSource() == btnChargeAuto)
      btnChargeAuto_actionPerformed(e);
    else if (e.getSource() == btnChargeManual)
      btnChargeManual_actionPerformed(e);
    else if (e.getSource() == btnGetChargeAuto)
      btnGetChargeAuto_actionPerformed(e);
    else if (e.getSource() == btnPowerCap)
      btnPowerCap_actionPerformed(e);
    else if (e.getSource() == btnPowerBatt)
      btnPowerBatt_actionPerformed(e);
    else if (e.getSource() == btnGetPowerStatus)
      btnGetPowerStatus_actionPerformed(e);
    else if (e.getSource() == btnNoCharging)
      btnNoCharging_actionPerformed(e);
    else if (e.getSource() == btnCharging)
      btnCharging_actionPerformed(e);
    else if (e.getSource() == btnChargingStatus)
      btnChargingStatus_actionPerformed(e);
    else if (e.getSource() == btnADCPrometheus)
      btnADCPrometheus_actionPerformed(e);
    else if (e.getSource() == btnADCExternal)
      btnADCExternal_actionPerformed(e);
    else if (e.getSource() == btnADCStatus)
      btnADCStatus_actionPerformed(e);
    else if (e.getSource() == btnGrenadeArm)
      btnGrenadeArm_actionPerformed(e);
    else if (e.getSource() == btnGrenadeInit)
      btnGrenadeInit_actionPerformed(e);
    else if (e.getSource() == btnGrenadeDebug)
      btnGrenadeDebug_actionPerformed(e);
  }

  void sendMsg(TestTrioMsg msg) {
    try {
      mote.send(MoteIF.TOS_BCAST_ADDR, msg);
    }
    catch (Exception ex) {
    }
  }

  public void btnLedsRedOn_actionPerformed(ActionEvent e) {
    TestTrioMsg msg = new TestTrioMsg();
    msg.set_cmd(CMD_REDLED);
    msg.set_subcmd(SUBCMD_ON);
    sendMsg(msg);
  }

  public void btnLedsRedOff_actionPerformed(ActionEvent e) {
    TestTrioMsg msg = new TestTrioMsg();
    msg.set_cmd(CMD_REDLED);
    msg.set_subcmd(SUBCMD_OFF);
    sendMsg(msg);
  }

  public void btnLedsGreenOn_actionPerformed(ActionEvent e) {
    TestTrioMsg msg = new TestTrioMsg();
    msg.set_cmd(CMD_GREENLED);
    msg.set_subcmd(SUBCMD_ON);
    sendMsg(msg);
  }

  public void btnLedsGreenOff_actionPerformed(ActionEvent e) {
    TestTrioMsg msg = new TestTrioMsg();
    msg.set_cmd(CMD_GREENLED);
    msg.set_subcmd(SUBCMD_OFF);
    sendMsg(msg);
  }

  public void btnLedsYellowOn_actionPerformed(ActionEvent e) {
    TestTrioMsg msg = new TestTrioMsg();
    msg.set_cmd(CMD_YELLOWLED);
    msg.set_subcmd(SUBCMD_ON);
    sendMsg(msg);
  }

  public void btnLedsYellowOff_actionPerformed(ActionEvent e) {
    TestTrioMsg msg = new TestTrioMsg();
    msg.set_cmd(CMD_YELLOWLED);
    msg.set_subcmd(SUBCMD_OFF);
    sendMsg(msg);
  }

  public void btnSounderOn_actionPerformed(ActionEvent e) {
    TestTrioMsg msg = new TestTrioMsg();
    msg.set_cmd(CMD_SOUNDER);
    msg.set_subcmd(SUBCMD_ON);
    sendMsg(msg);
  }

  public void btnSounderOff_actionPerformed(ActionEvent e) {
    TestTrioMsg msg = new TestTrioMsg();
    msg.set_cmd(CMD_SOUNDER);
    msg.set_subcmd(SUBCMD_OFF);
    sendMsg(msg);
  }

  public void btnSounderRead_actionPerformed(ActionEvent e) {
    TestTrioMsg msg = new TestTrioMsg();
    msg.set_cmd(CMD_SOUNDER_READ);
    sendMsg(msg);
  }

  public void btnX1226DisableAlarm_actionPerformed(ActionEvent e) {
    maskDisableAlarm = MASK_X1226_DISABLE_ALARM;
  }

  public void btnX1226EnableAlarm_actionPerformed(ActionEvent e) {
    maskDisableAlarm = MASK_X1226_ENABLE_ALARM;
  }

  public void btnX1226SetAlarm_actionPerformed(ActionEvent e) {
    TestTrioMsg msg = new TestTrioMsg();
    msg.set_cmd(CMD_X1226_SET);
    msg.set_subcmd(SUBCMD_X1226_ALM0);

    System.out.println("maskDisableAlarm: " +
                       Integer.toString(maskDisableAlarm, 16));

    try {
      short second = Short.parseShort(fieldX1226Sec.getText());
      if (second < 0 || second > 59) {
        System.err.println(
          "The SEC value for X1226 Alarm0 should be 0 through 59.");
        return;
      }
      // BCD representation of second
      int second_10 = (second / 10) & 0x07;
      int second_1 = (second - second_10 * 10) & 0x0f;    
      int second_bit = (second_10 << 4) | second_1 | maskDisableAlarm;
      msg.setElement_arg(0, (short)second_bit);
    }
    catch (Exception ex) {
      System.err.println(
        "The SEC value for X1226 Alarm0 should be 0 through 59.");
      return;
    }

    try {
      short minute = Short.parseShort(fieldX1226Min.getText());
      if (minute < 0 || minute > 59) {
        System.err.println(
          "The MIN value for X1226 Alarm0 should be 0 through 59.");
        return;
      }
      // BCD representation of minute
      int minute_10 = (minute / 10) & 0x07;
      int minute_1 = (minute - minute_10 * 10) & 0x0f;
      int minute_bit = (minute_10 << 4) | minute_1 | maskDisableAlarm;
      msg.setElement_arg(1, (short)minute_bit);
    }
    catch (Exception ex) {
      System.err.println(
        "The MIN value for X1226 Alarm0 should be 0 through 59.");
      return;
    }

    // fill the rest of time unit as zero.
    for (int i = 2; i < 8; i++) {
      msg.setElement_arg(i, (short)0);
    }

    sendMsg(msg);
  }

  public void btnX1226ReadAlarm_actionPerformed(ActionEvent e) {
    TestTrioMsg msg = new TestTrioMsg();
    msg.set_cmd(CMD_X1226_READ);
    msg.set_subcmd(SUBCMD_X1226_ALM0);
    sendMsg(msg);
  }

  public void btnX1226ResetClock_actionPerformed(ActionEvent e) {
    TestTrioMsg msg = new TestTrioMsg();
    msg.set_cmd(CMD_X1226_SET);
    msg.set_subcmd(SUBCMD_X1226_RTC);
    for (int i = 0; i < 8; i++) {
      msg.setElement_arg(i, (short)0);
    }
    sendMsg(msg);
  }

  public void btnX1226ReadClock_actionPerformed(ActionEvent e) {
    TestTrioMsg msg = new TestTrioMsg();
    msg.set_cmd(CMD_X1226_READ);
    msg.set_subcmd(SUBCMD_X1226_RTC);
    sendMsg(msg);
  }

  public void btnX1226ReadStatus_actionPerformed(ActionEvent e) {
    TestTrioMsg msg = new TestTrioMsg();
    msg.set_cmd(CMD_X1226_READ);
    msg.set_subcmd(SUBCMD_X1226_STATUS);
    sendMsg(msg);
  }

  public void btnX1226EnableInt_actionPerformed(ActionEvent e) {
    TestTrioMsg msg = new TestTrioMsg();
    msg.set_cmd(CMD_X1226_SET);
    msg.set_subcmd(SUBCMD_X1226_INT);
    msg.setElement_arg(0, MASK_X1226_ENABLE_INT);
    sendMsg(msg);
  }

  public void btnX1226DisableInt_actionPerformed(ActionEvent e) {
    TestTrioMsg msg = new TestTrioMsg();
    msg.set_cmd(CMD_X1226_SET);
    msg.set_subcmd(SUBCMD_X1226_INT);
    msg.setElement_arg(0, MASK_X1226_DISABLE_INT);
    sendMsg(msg);
  }

  public void btnX1226ReadInt_actionPerformed(ActionEvent e) {
    TestTrioMsg msg = new TestTrioMsg();
    msg.set_cmd(CMD_X1226_READ);
    msg.set_subcmd(SUBCMD_X1226_INT);
    sendMsg(msg);
  }

  public void btnPwrSw_actionPerformed(ActionEvent e) {
    maskIOSwitch1 = MASK_PWR_SW;
  }

  public void btnChargeSw_actionPerformed(ActionEvent e) {
    maskIOSwitch1 = MASK_CHARGE_SW;
  }

  public void btnPwAcoustic_actionPerformed(ActionEvent e) {
    maskIOSwitch1 = MASK_PW_ACOUSTIC;
  }

  public void btnPwMag_actionPerformed(ActionEvent e) {
    maskIOSwitch1 = MASK_PW_MAG;
  }

  public void btnPwPIR_actionPerformed(ActionEvent e) {
    maskIOSwitch1 = MASK_PW_PIR;
  }

  public void btnPwSounder_actionPerformed(ActionEvent e) {
    maskIOSwitch1 = MASK_PW_SOUNDER;
  }

  public void btnMagSR_actionPerformed(ActionEvent e) {
    maskIOSwitch1 = MASK_MAG_SR;
  }

  public void btnSetIOSwitch1_actionPerformed(ActionEvent e) {
    TestTrioMsg msg = new TestTrioMsg();
    msg.set_cmd(CMD_IOSWITCH1_SET);
    msg.set_subcmd(maskIOSwitch1);
    sendMsg(msg);
  }

  public void btnClearIOSwitch1_actionPerformed(ActionEvent e) {
    TestTrioMsg msg = new TestTrioMsg();
    msg.set_cmd(CMD_IOSWITCH1_CLR);
    msg.set_subcmd(maskIOSwitch1);
    sendMsg(msg);
  }

  public void btnReadSW1Port_actionPerformed(ActionEvent e) {
    TestTrioMsg msg = new TestTrioMsg();
    msg.set_cmd(CMD_IOSWITCH1_READ);
    sendMsg(msg);
  }

  public void btnStatusClear_actionPerformed(ActionEvent e) {
    msgWnd.setText("");
  }

  public void btnI2cSw_actionPerformed(ActionEvent e) {
    maskIOSwitch2 = MASK_I2C_SW;
  }

  public void btnMcuReset_actionPerformed(ActionEvent e) {
    maskIOSwitch2 = MASK_MCU_RESET;
  }

  public void btnGrenadeCk_actionPerformed(ActionEvent e) {
    maskIOSwitch2 = MASK_GRENADE_CK;
  }

  public void btnSetIOSwitch2_actionPerformed(ActionEvent e) {
    TestTrioMsg msg = new TestTrioMsg();
    msg.set_cmd(CMD_IOSWITCH2_SET);
    msg.set_subcmd(maskIOSwitch2);
    sendMsg(msg);
  }

  public void btnClearIOSwitch2_actionPerformed(ActionEvent e) {
    TestTrioMsg msg = new TestTrioMsg();
    msg.set_cmd(CMD_IOSWITCH2_CLR);
    msg.set_subcmd(maskIOSwitch2);
    sendMsg(msg);
  }

  public void btnReadSW2Port_actionPerformed(ActionEvent e) {
    TestTrioMsg msg = new TestTrioMsg();
    msg.set_cmd(CMD_IOSWITCH2_READ);
    sendMsg(msg);
  }

  public void btnBatADC_actionPerformed(ActionEvent e) {
    maskPWSwitch = MASK_BAT_ADC;
  }

  public void btnExtADC_actionPerformed(ActionEvent e) {
    maskPWSwitch = MASK_EXT_ADC;
  }

  public void btnSetPWSwitch_actionPerformed(ActionEvent e) {
    TestTrioMsg msg = new TestTrioMsg();
    msg.set_cmd(CMD_PWSWITCH_SET);
    msg.set_subcmd(maskPWSwitch);
    sendMsg(msg);
  }

  public void btnReadPWSwitch_actionPerformed(ActionEvent e) {
    TestTrioMsg msg = new TestTrioMsg();
    msg.set_cmd(CMD_PWSWITCH_READ);
    sendMsg(msg);
  }

  public void btnGetADCMux0_actionPerformed(ActionEvent e) {
    TestTrioMsg msg = new TestTrioMsg();
    msg.set_cmd(CMD_PWSWITCH_GETADC);
    msg.set_subcmd((short)0);
    sendMsg(msg);
  }

  public void btnGetADCMux1_actionPerformed(ActionEvent e) {
    TestTrioMsg msg = new TestTrioMsg();
    msg.set_cmd(CMD_PWSWITCH_GETADC);
    msg.set_subcmd((short)1);
    sendMsg(msg);
  }

  public void btnPIROn_actionPerformed(ActionEvent e) {
    TestTrioMsg msg = new TestTrioMsg();
    msg.set_cmd(CMD_PIR);
    msg.set_subcmd(SUBCMD_ON);
    sendMsg(msg);
  }

  public void btnPIROff_actionPerformed(ActionEvent e) {
    TestTrioMsg msg = new TestTrioMsg();
    msg.set_cmd(CMD_PIR);
    msg.set_subcmd(SUBCMD_OFF);
    sendMsg(msg);
  }

  public void btnPIRGetADC_actionPerformed(ActionEvent e) {
    TestTrioMsg msg = new TestTrioMsg();
    msg.set_cmd(CMD_PIR_GETADC);
    bPIRADC_started = !bPIRADC_started;

    if (bPIRADC_started) {
      msg.set_subcmd(SUBCMD_ON);
      btnPIRGetADC.setText("Stop ADC");
    }
    else {
      msg.set_subcmd(SUBCMD_OFF);
      btnPIRGetADC.setText("PIR ADC");
    }

    sendMsg(msg);
  }

  public void btnPIRDetectAdjust_actionPerformed(ActionEvent e) {
    try {
      short detect_value;
      TestTrioMsg msg = new TestTrioMsg();
      msg.set_cmd(CMD_PIR_POT_ADJUST);
      msg.set_subcmd(SUBCMD_PIR_DETECT);

      detect_value = Short.parseShort(fieldPIRDetect.getText());
      if (detect_value < 0 || detect_value > 255) {
        System.err.println(
          "The value for PIR DETECT should be 0 through 255.");
        return;
      }

      msg.setElement_arg(0, detect_value);
      sendMsg(msg);
    }
    catch (Exception ex) {
      System.err.println(
        "The value for PIR DETECT should be 0 through 255.");
    }
  }

  public void btnPIRDetectRead_actionPerformed(ActionEvent e) {
    TestTrioMsg msg = new TestTrioMsg();
    msg.set_cmd(CMD_PIR_POT_READ);
    msg.set_subcmd(SUBCMD_PIR_DETECT);
    sendMsg(msg);
  }

  public void btnPIRQuadAdjust_actionPerformed(ActionEvent e) {
    try {
      short quad_value;
      TestTrioMsg msg = new TestTrioMsg();
      msg.set_cmd(CMD_PIR_POT_ADJUST);
      msg.set_subcmd(SUBCMD_PIR_QUAD);

      quad_value = Short.parseShort(fieldPIRQuad.getText());
      if (quad_value < 0 || quad_value > 255) {
        System.err.println(
          "The value for PIR QUAD should be 0 through 255.");
        return;
      }

      msg.setElement_arg(0, quad_value);
      sendMsg(msg);
    }
    catch (Exception ex) {
      System.err.println(
        "The value for PIR QUAD should be 0 through 255.");
    }
  }

  public void btnPIRQuadRead_actionPerformed(ActionEvent e) {
    TestTrioMsg msg = new TestTrioMsg();
    msg.set_cmd(CMD_PIR_POT_READ);
    msg.set_subcmd(SUBCMD_PIR_QUAD);
    sendMsg(msg);
  }

  public void btnMagOn_actionPerformed(ActionEvent e) {
    TestTrioMsg msg = new TestTrioMsg();
    msg.set_cmd(CMD_MAG);
    msg.set_subcmd(SUBCMD_ON);
    sendMsg(msg);
  }

  public void btnMagOff_actionPerformed(ActionEvent e) {
    TestTrioMsg msg = new TestTrioMsg();
    msg.set_cmd(CMD_MAG);
    msg.set_subcmd(SUBCMD_OFF);
    sendMsg(msg);
  }

  public void btnMagGetADC0_actionPerformed(ActionEvent e) {
    TestTrioMsg msg = new TestTrioMsg();
    msg.set_cmd(CMD_MAG_GETADC);
    msg.set_subcmd(SUBCMD_MAG_ADC0);
    bMagXADC_started = !bMagXADC_started;

    if (bMagXADC_started) {
      msg.setElement_arg(0, SUBCMD_ON);
      btnMagGetADC0.setText("Stop ADC 0");
    }
    else {
      msg.setElement_arg(0, SUBCMD_OFF);
      btnMagGetADC0.setText("Mag ADC 0");
    }

    sendMsg(msg);
  }

  public void btnMagGetADC1_actionPerformed(ActionEvent e) {
    TestTrioMsg msg = new TestTrioMsg();
    msg.set_cmd(CMD_MAG_GETADC);
    msg.set_subcmd(SUBCMD_MAG_ADC1);
    bMagYADC_started = !bMagYADC_started;

    if (bMagYADC_started) {
      msg.setElement_arg(0, SUBCMD_ON);
      btnMagGetADC1.setText("Stop ADC 1");
    }
    else {
      msg.setElement_arg(0, SUBCMD_OFF);
      btnMagGetADC1.setText("Mag ADC 1");
    }

    sendMsg(msg);
  }

  public void btnMagGainXAdjust_actionPerformed(ActionEvent e) {
    try {
      short gainx_value;
      TestTrioMsg msg = new TestTrioMsg();
      msg.set_cmd(CMD_MAG_POT_ADJUST);
      msg.set_subcmd(SUBCMD_MAG_GAINX);

      gainx_value = Short.parseShort(fieldMagGainX.getText());
      if (gainx_value < 0 || gainx_value > 255) {
        System.err.println(
          "The value for MAG GAIN X should be 0 through 255.");
        return;
      }

      msg.setElement_arg(0, gainx_value);
      sendMsg(msg);
    }
    catch (Exception ex) {
      System.err.println(
        "The value for MAG GAIN X should be 0 through 255.");
    }
  }

  public void btnMagGainXRead_actionPerformed(ActionEvent e) {
    TestTrioMsg msg = new TestTrioMsg();
    msg.set_cmd(CMD_MAG_POT_READ);
    msg.set_subcmd(SUBCMD_MAG_GAINX);
    sendMsg(msg);
  }

  public void btnMagGainYAdjust_actionPerformed(ActionEvent e) {
    try {
      short gainy_value;
      TestTrioMsg msg = new TestTrioMsg();
      msg.set_cmd(CMD_MAG_POT_ADJUST);
      msg.set_subcmd(SUBCMD_MAG_GAINY);

      gainy_value = Short.parseShort(fieldMagGainY.getText());
      if (gainy_value < 0 || gainy_value > 255) {
        System.err.println(
          "The value for MAG GAIN Y should be 0 through 255.");
        return;
      }

      msg.setElement_arg(0, gainy_value);
      sendMsg(msg);
    }
    catch (Exception ex) {
      System.err.println(
        "The value for MAG GAIN Y should be 0 through 255.");
    }
  }

  public void btnMagGainYRead_actionPerformed(ActionEvent e) {
    TestTrioMsg msg = new TestTrioMsg();
    msg.set_cmd(CMD_MAG_POT_READ);
    msg.set_subcmd(SUBCMD_MAG_GAINY);
    sendMsg(msg);
  }

  public void btnMagSet_actionPerformed(ActionEvent e) {
    TestTrioMsg msg = new TestTrioMsg();
    msg.set_cmd(CMD_MAG_SETRESET);
    msg.set_subcmd(SUBCMD_ON);
    sendMsg(msg);
  }

  public void btnMagReset_actionPerformed(ActionEvent e) {
    TestTrioMsg msg = new TestTrioMsg();
    msg.set_cmd(CMD_MAG_SETRESET);
    msg.set_subcmd(SUBCMD_OFF);
    sendMsg(msg);
  }

  public void btnMicOn_actionPerformed(ActionEvent e) {
    TestTrioMsg msg = new TestTrioMsg();
    msg.set_cmd(CMD_MIC);
    msg.set_subcmd(SUBCMD_ON);
    sendMsg(msg);
  }

  public void btnMicOff_actionPerformed(ActionEvent e) {
    TestTrioMsg msg = new TestTrioMsg();
    msg.set_cmd(CMD_MIC);
    msg.set_subcmd(SUBCMD_OFF);
    sendMsg(msg);
  }

  public void btnMicGetADC_actionPerformed(ActionEvent e) {
    TestTrioMsg msg = new TestTrioMsg();
    msg.set_cmd(CMD_MIC_GETADC);
    bMicADC_started = !bMicADC_started;

    if (bMicADC_started) {
      msg.set_subcmd(SUBCMD_ON);
      btnMicGetADC.setText("Stop ADC"); 
    }
    else {
      msg.set_subcmd(SUBCMD_OFF);
      btnMicGetADC.setText("Mic ADC"); 
    }

    sendMsg(msg);
  }

  public void btnMicLPF0Adjust_actionPerformed(ActionEvent e) {
    try {
      short lpf_value;
      TestTrioMsg msg = new TestTrioMsg();
      msg.set_cmd(CMD_MIC_POT_ADJUST);
      msg.set_subcmd(SUBCMD_MIC_LPF0);

      lpf_value = Short.parseShort(fieldMicLPF0.getText());
      if (lpf_value < 0 || lpf_value > 255) {
        System.err.println(
          "The value for MIC LPF should be 0 through 255.");
        return;
      }

      msg.setElement_arg(0,lpf_value);
      sendMsg(msg);
    }
    catch (Exception ex) {
      System.err.println(
        "The value for MIC LPF should be 0 through 255.");
    }
  }

  public void btnMicLPF0Read_actionPerformed(ActionEvent e) {
    TestTrioMsg msg = new TestTrioMsg();
    msg.set_cmd(CMD_MIC_POT_READ);
    msg.set_subcmd(SUBCMD_MIC_LPF0);
    sendMsg(msg);
  }

  public void btnMicLPF1Adjust_actionPerformed(ActionEvent e) {
    try {
      short lpf_value;
      TestTrioMsg msg = new TestTrioMsg();
      msg.set_cmd(CMD_MIC_POT_ADJUST);
      msg.set_subcmd(SUBCMD_MIC_LPF1);

      lpf_value = Short.parseShort(fieldMicLPF1.getText());
      if (lpf_value < 0 || lpf_value > 255) {
        System.err.println(
          "The value for MIC LPF should be 0 through 255.");
        return;
      }

      msg.setElement_arg(0, lpf_value);
      sendMsg(msg);
    }
    catch (Exception ex) {
      System.err.println(
        "The value for MIC LPF should be 0 through 255.");
    }
  }

  public void btnMicLPF1Read_actionPerformed(ActionEvent e) {
    TestTrioMsg msg = new TestTrioMsg();
    msg.set_cmd(CMD_MIC_POT_READ);
    msg.set_subcmd(SUBCMD_MIC_LPF1);
    sendMsg(msg);
  }

  public void btnMicHPF0Adjust_actionPerformed(ActionEvent e) {
    try {
      short hpf_value;
      TestTrioMsg msg = new TestTrioMsg();
      msg.set_cmd(CMD_MIC_POT_ADJUST);
      msg.set_subcmd(SUBCMD_MIC_HPF0);

      hpf_value = Short.parseShort(fieldMicHPF0.getText());
      if (hpf_value < 0 || hpf_value > 255) {
        System.err.println(
          "The value for MIC HPF should be 0 through 255.");
        return;
      }

      msg.setElement_arg(0, hpf_value);
      sendMsg(msg);
    }
    catch (Exception ex) {
      System.err.println(
        "The value for MIC HPF should be 0 through 255.");
    }
  }

  public void btnMicHPF0Read_actionPerformed(ActionEvent e) {
    TestTrioMsg msg = new TestTrioMsg();
    msg.set_cmd(CMD_MIC_POT_READ);
    msg.set_subcmd(SUBCMD_MIC_HPF0);
    sendMsg(msg);
  }

  public void btnMicHPF1Adjust_actionPerformed(ActionEvent e) {
    try {
      short hpf_value;
      TestTrioMsg msg = new TestTrioMsg();
      msg.set_cmd(CMD_MIC_POT_ADJUST);
      msg.set_subcmd(SUBCMD_MIC_HPF1);

      hpf_value = Short.parseShort(fieldMicHPF1.getText());
      if (hpf_value < 0 || hpf_value > 255) {
        System.err.println(
          "The value for MIC HPF should be 0 through 255.");
        return;
      }

      msg.setElement_arg(0, hpf_value);
      sendMsg(msg);
    }
    catch (Exception ex) {
      System.err.println(
        "The value for MIC HPF should be 0 through 255.");
    }
  }

  public void btnMicHPF1Read_actionPerformed(ActionEvent e) {
    TestTrioMsg msg = new TestTrioMsg();
    msg.set_cmd(CMD_MIC_POT_READ);
    msg.set_subcmd(SUBCMD_MIC_HPF1);
    sendMsg(msg);
  }

  public void btnMicGainAdjust_actionPerformed(ActionEvent e) {
    try {
      short gain_value;
      TestTrioMsg msg = new TestTrioMsg();
      msg.set_cmd(CMD_MIC_POT_ADJUST);
      msg.set_subcmd(SUBCMD_MIC_GAIN);

      gain_value = Short.parseShort(fieldMicGain.getText());
      if (gain_value < 0 || gain_value > 255) {
        System.err.println(
          "The value for MIC GAIN should be 0 through 255.");
        return;
      }

      msg.setElement_arg(0, gain_value);
      sendMsg(msg);
    }
    catch (Exception ex) {
      System.err.println(
        "The value for MIC GAIN should be 0 through 255.");
    }
  }

  public void btnMicGainRead_actionPerformed(ActionEvent e) {
    TestTrioMsg msg = new TestTrioMsg();
    msg.set_cmd(CMD_MIC_POT_READ);
    msg.set_subcmd(SUBCMD_MIC_GAIN);
    sendMsg(msg);
  }

  public void btnMicDetectAdjust_actionPerformed(ActionEvent e) {
    try {
      short detect_value;
      TestTrioMsg msg = new TestTrioMsg();
      msg.set_cmd(CMD_MIC_POT_ADJUST);
      msg.set_subcmd(SUBCMD_MIC_DETECT);

      detect_value = Short.parseShort(fieldMicDetect.getText());
      if (detect_value < 0 || detect_value > 255) {
        System.err.println(
          "The value for MIC DETECT should be 0 through 255.");
        return;
      }

      msg.setElement_arg(0, detect_value);
      sendMsg(msg);
    }
    catch (Exception ex) {
      System.err.println(
        "The value for MIC DETECT should be 0 through 255.");
    }
  }

  public void btnMicDetectRead_actionPerformed(ActionEvent e) {
    TestTrioMsg msg = new TestTrioMsg();
    msg.set_cmd(CMD_MIC_POT_READ);
    msg.set_subcmd(SUBCMD_MIC_DETECT);
    sendMsg(msg);
  }

  public void btnRefVol_actionPerformed(ActionEvent e) {
    maskPrometheus = SUBCMD_PROMETHEUS_REFVOL;
  }

  public void btnCapVol_actionPerformed(ActionEvent e) {
    maskPrometheus = SUBCMD_PROMETHEUS_CAPVOL;
  }

  public void btnBattVol_actionPerformed(ActionEvent e) {
    maskPrometheus = SUBCMD_PROMETHEUS_BATTVOL;
  }

  public void btnReadVoltage_actionPerformed(ActionEvent e) {
    TestTrioMsg msg = new TestTrioMsg();
    msg.set_cmd(CMD_PROMETHEUS_GETVOLTAGE);
    msg.set_subcmd(maskPrometheus);
    sendMsg(msg);
  }

  public void btnChargeAuto_actionPerformed(ActionEvent e) {
    TestTrioMsg msg = new TestTrioMsg();
    msg.set_cmd(CMD_PROMETHEUS_SET_STATUS);
    msg.set_subcmd(SUBCMD_PROMETHEUS_AUTOMATIC);
    msg.setElement_arg(0, SUBCMD_ON);
    sendMsg(msg);
  }

  public void btnChargeManual_actionPerformed(ActionEvent e) {
    TestTrioMsg msg = new TestTrioMsg();
    msg.set_cmd(CMD_PROMETHEUS_SET_STATUS);
    msg.set_subcmd(SUBCMD_PROMETHEUS_AUTOMATIC);
    msg.setElement_arg(0, SUBCMD_OFF);
    sendMsg(msg);
  }

  public void btnGetChargeAuto_actionPerformed(ActionEvent e) {
    TestTrioMsg msg = new TestTrioMsg();
    msg.set_cmd(CMD_PROMETHEUS_GET_STATUS);
    msg.set_subcmd(SUBCMD_PROMETHEUS_AUTOMATIC);
    sendMsg(msg);
  }

  public void btnPowerCap_actionPerformed(ActionEvent e) {
    TestTrioMsg msg = new TestTrioMsg();
    msg.set_cmd(CMD_PROMETHEUS_SET_STATUS);
    msg.set_subcmd(SUBCMD_PROMETHEUS_POWERSOURCE);
    msg.setElement_arg(0, SUBCMD_OFF);
    sendMsg(msg);
  }

  public void btnPowerBatt_actionPerformed(ActionEvent e) {
    TestTrioMsg msg = new TestTrioMsg();
    msg.set_cmd(CMD_PROMETHEUS_SET_STATUS);
    msg.set_subcmd(SUBCMD_PROMETHEUS_POWERSOURCE);
    msg.setElement_arg(0, SUBCMD_ON);
    sendMsg(msg);
  }

  public void btnGetPowerStatus_actionPerformed(ActionEvent e) {
    TestTrioMsg msg = new TestTrioMsg();
    msg.set_cmd(CMD_PROMETHEUS_GET_STATUS);
    msg.set_subcmd(SUBCMD_PROMETHEUS_POWERSOURCE);
    sendMsg(msg);
  }

  public void btnNoCharging_actionPerformed(ActionEvent e) {
    TestTrioMsg msg = new TestTrioMsg();
    msg.set_cmd(CMD_PROMETHEUS_SET_STATUS);
    msg.set_subcmd(SUBCMD_PROMETHEUS_CHARGING);
    msg.setElement_arg(0, SUBCMD_ON);
    sendMsg(msg);
  }

  public void btnCharging_actionPerformed(ActionEvent e) {
    TestTrioMsg msg = new TestTrioMsg();
    msg.set_cmd(CMD_PROMETHEUS_SET_STATUS);
    msg.set_subcmd(SUBCMD_PROMETHEUS_CHARGING);
    msg.setElement_arg(0, SUBCMD_OFF);
    sendMsg(msg);
  }

  public void btnChargingStatus_actionPerformed(ActionEvent e) {
    TestTrioMsg msg = new TestTrioMsg();
    msg.set_cmd(CMD_PROMETHEUS_GET_STATUS);
    msg.set_subcmd(SUBCMD_PROMETHEUS_CHARGING);
    sendMsg(msg);
  }

  public void btnADCPrometheus_actionPerformed(ActionEvent e) {
    TestTrioMsg msg = new TestTrioMsg();
    msg.set_cmd(CMD_PROMETHEUS_SET_STATUS);
    msg.set_subcmd(SUBCMD_PROMETHEUS_ADCSOURCE);
    msg.setElement_arg(0, SUBCMD_ON);
    sendMsg(msg);
  }

  public void btnADCExternal_actionPerformed(ActionEvent e) {
    TestTrioMsg msg = new TestTrioMsg();
    msg.set_cmd(CMD_PROMETHEUS_SET_STATUS);
    msg.set_subcmd(SUBCMD_PROMETHEUS_ADCSOURCE);
    msg.setElement_arg(0, SUBCMD_OFF);
    sendMsg(msg);
  }

  public void btnADCStatus_actionPerformed(ActionEvent e) {
    TestTrioMsg msg = new TestTrioMsg();
    msg.set_cmd(CMD_PROMETHEUS_GET_STATUS);
    msg.set_subcmd(SUBCMD_PROMETHEUS_ADCSOURCE);
    sendMsg(msg);
  }

  public void btnGrenadeArm_actionPerformed(ActionEvent e) {
    TestTrioMsg msg = new TestTrioMsg();
    msg.set_cmd(CMD_GRENADE);
    msg.set_subcmd(SUBCMD_ON);
    sendMsg(msg);
  }

  public void btnGrenadeInit_actionPerformed(ActionEvent e) {
    TestTrioMsg msg = new TestTrioMsg();
    msg.set_cmd(CMD_GRENADE);
    msg.set_subcmd(SUBCMD_OFF);
    sendMsg(msg);
  }

  public void btnGrenadeDebug_actionPerformed(ActionEvent e) {
    TestTrioMsg msg = new TestTrioMsg();
    msg.set_cmd(CMD_DEBUG_MSG);
    sendMsg(msg);
  }

  void TestTrioMsgReceived(TestTrioMsg msg) {
    short multiplier = 256;
    if (msg.get_cmd() == REPLY_IOSWITCH1_READ) {     
      String strPort0 = Integer.toString(msg.getElement_arg(0), 16);
      String strPort1 = Integer.toString(msg.getElement_arg(1), 16);
      if (msg.get_subcmd() == 1) {
        setStatus("IO Switch 1, Port 0: " + strPort0);
      }
      else if (msg.get_subcmd() == 2) {
        setStatus("IO Switch 1, Port 0: " + strPort0);
        setStatus("IO Switch 1, Port 1: " + strPort1);
      }
    }
    else if (msg.get_cmd() == REPLY_IOSWITCH2_READ) {     
      String strPort0 = Integer.toString(msg.getElement_arg(0), 16);
      String strPort1 = Integer.toString(msg.getElement_arg(1), 16);
      if (msg.get_subcmd() == 1) {
        setStatus("IO Switch 2, Port 0: " + strPort0);
      }
      else if (msg.get_subcmd() == 2) {
        setStatus("IO Switch 2, Port 0: " + strPort0);
        setStatus("IO Switch 2, Port 1: " + strPort1);
      }
    }
    else if (msg.get_cmd() == REPLY_PWSWITCH_READ) {
      String strPort = Integer.toString(msg.getElement_arg(0), 16);
      setStatus("PW Switch, Port: " + strPort);
    }
    else if (msg.get_cmd() == REPLY_IOSWITCH1_INTERRUPT) {
      if ((msg.get_subcmd() & MASK_INT_ACOUSTIC) != 0) {
        setStatus("Microphone interrupt triggered.");
      }
      else if ((msg.get_subcmd() & MASK_INT_PIR) != 0) {
        setStatus("PIR interrupt triggered.");
      }
      else {
        setStatus("IO Switch 1 interrupt triggered: " +
                 Integer.toString(msg.get_subcmd(), 16));
      }
    }
    else if (msg.get_cmd() == REPLY_IOSWITCH2_INTERRUPT) {
      setStatus("IO Switch 2 interrupt triggered: " +
                Integer.toString(msg.get_subcmd(), 16));
    }
    else if (msg.get_cmd() == REPLY_PWSWITCH_ADCREADY) {
      int adc_data = msg.getElement_arg(0) |
                       (msg.getElement_arg(1) & 0xff) << 8;
      setStatus("PW Switch ADC Mux " + msg.get_subcmd() + ": " +
                Integer.toString(adc_data));
    }
    else if (msg.get_cmd() == REPLY_MAG_POT_READ) {
      if (msg.get_subcmd() == SUBCMD_MAG_GAINX) {
        setStatus("Mag GainX Pot: " + msg.getElement_arg(0));
      }
      else if (msg.get_subcmd() == SUBCMD_MAG_GAINY) {
        setStatus("Mag GainY Pot: " + msg.getElement_arg(0));
      }
    }
    else if (msg.get_cmd() == REPLY_MAG_ADCREADY) {
      int adc_data = msg.getElement_arg(0) |
                       (msg.getElement_arg(1) & 0xff) << 8;
      setStatus("MAG ADC " + msg.get_subcmd() + ": " +
                Integer.toString(adc_data));
    }
    else if (msg.get_cmd() == REPLY_PIR_POT_READ) {
      if (msg.get_subcmd() == SUBCMD_PIR_DETECT) {
        setStatus("PIR Detect Pot: " + msg.getElement_arg(0));
      }
      else if (msg.get_subcmd() == SUBCMD_PIR_QUAD) {
        setStatus("PIR Quad Pot: " + msg.getElement_arg(0));
      }
    }
    else if (msg.get_cmd() == REPLY_PIR_ADCREADY) {
      int adc_data = msg.getElement_arg(0) |
                       (msg.getElement_arg(1) & 0xff) << 8;
      setStatus("PIR ADC " + msg.get_subcmd() + ": " +
                Integer.toString(adc_data));
    }
    else if (msg.get_cmd() == REPLY_MIC_POT_READ) {
      if (msg.get_subcmd() == SUBCMD_MIC_LPF0) {
        setStatus("Mic LPF0 Pot: " + msg.getElement_arg(0));
      }
      else if (msg.get_subcmd() == SUBCMD_MIC_LPF1) {
        setStatus("Mic LPF1 Pot: " + msg.getElement_arg(0));
      }
      else if (msg.get_subcmd() == SUBCMD_MIC_HPF0) {
        setStatus("Mic HPF0 Pot: " + msg.getElement_arg(0));
      }
      else if (msg.get_subcmd() == SUBCMD_MIC_HPF1) {
        setStatus("Mic HPF1 Pot: " + msg.getElement_arg(0));
      }
      else if (msg.get_subcmd() == SUBCMD_MIC_GAIN) {
        setStatus("Mic GAIN Pot: " + msg.getElement_arg(0));
      }
      else if (msg.get_subcmd() == SUBCMD_MIC_DETECT) {
        setStatus("Mic DETECT Pot: " + msg.getElement_arg(0));
      }
    }
    else if (msg.get_cmd() == REPLY_MIC_ADCREADY) {
      int adc_data = msg.getElement_arg(0) |
                       (msg.getElement_arg(1) & 0xff) << 8;
      setStatus("Mic ADC " + msg.get_subcmd() + ": " +
                Integer.toString(adc_data));
    }
    else if (msg.get_cmd() == REPLY_X1226_READ) {
      if (msg.get_subcmd() == SUBCMD_X1226_STATUS) {
        setStatus("X1226 status: 0x" + 
                 Integer.toString(msg.getElement_arg(0), 16));
      }
      else if (msg.get_subcmd() == SUBCMD_X1226_INT) {
        setStatus("X1226 interrupt: 0x" + 
                 Integer.toString(msg.getElement_arg(0), 16));
      }
      else if (msg.get_subcmd() == SUBCMD_X1226_RTC) {
        setStatus("X1226 RTC (min): " +
                 Integer.toString(msg.getElement_arg(1), 16) +
                  " (sec): " +
                 Integer.toString(msg.getElement_arg(0), 16));
      }
      else if (msg.get_subcmd() == SUBCMD_X1226_ALM0) {
        setStatus("X1226 Alarm 0 (min): " +
                 Integer.toString(msg.getElement_arg(1) & 0x7f, 16) +
                  " (sec): " +
                 Integer.toString(msg.getElement_arg(0) & 0x7f, 16));
        if ((msg.getElement_arg(1) & MASK_X1226_ENABLE_ALARM) != 0) {
          setStatus("X1226 Alarm 0 on for minute.");
        }
        if ((msg.getElement_arg(0) & MASK_X1226_ENABLE_ALARM) != 0) {
          setStatus("X1226 Alarm 0 on for second.");
        }
      }
    }
    else if (msg.get_cmd() == REPLY_PROMETHEUS_GETVOLTAGE) {
      if (msg.get_subcmd() == SUBCMD_PROMETHEUS_REFVOL) {
        int refvol = (msg.getElement_arg(0) & 0xff) +
                  ((msg.getElement_arg(1) & 0xff) << 8);
        setStatus("Ref vol: " + Integer.toString(refvol));
      }
      else if (msg.get_subcmd() == SUBCMD_PROMETHEUS_CAPVOL) {
        int refvol = (msg.getElement_arg(0) & 0xff) +
                     ((msg.getElement_arg(1) & 0xff) << 8);
        setStatus("Ref vol: " + Integer.toString(refvol));
        int volCap = (msg.getElement_arg(2) & 0xff) +
                      ((msg.getElement_arg(3) & 0xff) << 8);
        setStatus("Cap vol (Mote): " + Integer.toString(volCap));
      }
      else if (msg.get_subcmd() == SUBCMD_PROMETHEUS_BATTVOL) {
        int refvol = (msg.getElement_arg(0) & 0xff) +
                     ((msg.getElement_arg(1) & 0xff) << 8);
        setStatus("Ref vol: " + Integer.toString(refvol));
        int volBatt = (msg.getElement_arg(2) & 0xff) +
                      ((msg.getElement_arg(3) & 0xff) << 8);
        setStatus("Batt vol (Mote): " + Integer.toString(volBatt));
      }
      //if (msg.get_subcmd() == SUBCMD_PROMETHEUS_REFVOL) {
      //  setStatus("Ref vol: " + msg.get_voltage());
      //}
      //else if (msg.get_subcmd() == SUBCMD_PROMETHEUS_CAPVOL) {
      //  setStatus("Cap vol: " + msg.get_voltage());
      //}
      //else if (msg.get_subcmd() == SUBCMD_PROMETHEUS_BATTVOL) {
      //  setStatus("Batt vol: " + msg.get_voltage());
      //}
    }
    else if (msg.get_cmd() == REPLY_PROMETHEUS_GET_STATUS) {
      if (msg.get_subcmd() == SUBCMD_PROMETHEUS_AUTOMATIC) {
        if (msg.getElement_arg(0) == SUBCMD_ON) {
          setStatus("Automatic charging: YES");
        }
        else {
          setStatus("Automatic charging: NO");
        }
      }
      else if (msg.get_subcmd() == SUBCMD_PROMETHEUS_POWERSOURCE) {
        if (msg.getElement_arg(0) == SUBCMD_ON) {
          setStatus("Power source: Battery");
        }
        else {
          setStatus("Power source: Capacitor");
        }
      }
      else if (msg.get_subcmd() == SUBCMD_PROMETHEUS_CHARGING) {
        if (msg.getElement_arg(0) == SUBCMD_ON) {
          setStatus("Charging status: NO");
        }
        else {
          setStatus("Charging status: YES");
        }
      }
      else if (msg.get_subcmd() == SUBCMD_PROMETHEUS_ADCSOURCE) {
        if (msg.getElement_arg(0) == SUBCMD_ON) {
          setStatus("ADC source: Battery / Capacitor");
        }
        else {
          setStatus("ADC source: External ADC");
        }
      }
    }
    else if (msg.get_cmd() == REPLY_SOUNDER_READ) {
      if (msg.get_subcmd() == SUBCMD_OFF) {
        setStatus("Sounder is off.");
      }
      else if (msg.get_subcmd() == SUBCMD_ON) {
        setStatus("Sounder is on.");
      }
    }
    else if (msg.get_cmd() == REPLY_DEBUG_MSG) {
      setStatus("State: " + msg.get_subcmd());
    }
  }

  void setStatus(String str) {
    Time lasttime = new Time(System.currentTimeMillis());
    msgWnd.append("[" + lasttime.toString() + "] " + str+"\n");
    msgWnd.setCaretPosition(msgWnd.getDocument().getLength());
  }

  public void messageReceived(int dest_addr, Message msg) {
    if (msg instanceof TestTrioMsg) {
      TestTrioMsgReceived((TestTrioMsg) msg);
    }
  }

  public synchronized void windowClosing ( WindowEvent e )
  {
    System.exit(1);
  }

  public void windowClosed      ( WindowEvent e ) { }
  public void windowActivated   ( WindowEvent e ) { }
  public void windowIconified   ( WindowEvent e ) { }
  public void windowDeactivated ( WindowEvent e ) { }
  public void windowDeiconified ( WindowEvent e ) { }
  public void windowOpened      ( WindowEvent e ) { }


}
