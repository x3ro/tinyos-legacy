/*
 * Copyright (c) 2004,2005 Hewlett-Packard Company
 * All rights reserved
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:

 *     * Redistributions of source code must retain the above copyright
 *       notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above
 *       copyright notice, this list of conditions and the following
 *       disclaimer in the documentation and/or other materials provided
 *       with the distribution.
 *     * Neither the name of the Hewlett-Packard Company nor the names of its
 *       contributors may be used to endorse or promote products derived
 *       from this software without specific prior written permission.

 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

/**
 * A program that just broadcasts periodic messagse over the RF
 *
 * @author Andrew Christian
 * 24 November 2004
 */



includes PulseOx;

// include problems made me put these here. work out after techcon
#define LCD_WIDTH 160
#define LCD_HEIGHT 120
#define NUM_BATTERIES_ICONS 6
#define NUM_HEART_ICONS 1
#define NUM_RADIO_ICONS 6
#define NUM_ENVELOPE_ICONS 1



module MenuPulseOxRcvM {
  provides {
    interface StdControl;
  }
  uses {
    interface Timer as TimerSlow;
    interface Timer as TimerFast;
    interface LCD;    
    interface Leds;
    interface Menu;
#if defined(BATTERY_VOLTAGE)
    interface BatVolt;
#endif
    
    interface StdControl as IPStdControl;
#if defined(SERVER)
    interface StdControl as SIPLiteStdControl;
#endif
#if defined(HAVE_TELNET)
    interface StdControl as TelnetStdControl;
#endif
    interface StdControl as PVStdControl;
    interface StdControl as MenuStdControl;

    interface StdControl as IMAPStdControl;
    interface IMAPLite;

    
    interface UIP;
    interface Client;
#if defined(SERVER)
    interface SIPLiteClient;
#endif
#if defined(HAVE_TELNET)
    interface Telnet;
#endif
    interface PatientView;

    
    interface NTPClient;
    interface Time;
    interface ParamList;
    
    
  }
}
implementation {
  extern int snprintf(char *str, size_t size, const char *format, ...) __attribute__ ((C));
  extern int sprintf(char *str, const char *format, ...) __attribute__ ((C));
  task void handleState();
#if defined(SERVER)
  task void  closeSIPLiteConnection();
#endif
  task void forceTimeUpdate();
  
#define TIMER_INTERVAL 120000
#define TIMER_FAST_INTERVAL 1000


  enum STATES 
    {
      IDLE_STATE,
      POX_CONNECTING_STATE,
      POX_CONNECTED_STATE,
      MESSAGE_MAIN_STATE,
      MESSAGE_DETAIL_STATE,
      INFO_MAIN_STATE,
      INFO_SUB_STATE      
    };

     


  
       
struct lcd_strings
{
  Point p;
  int fontNum;
  int alignment;  
  char *str;  
};

char PatientName[64] = "Unknown";
char PatientID[64] = "Soldier";

 struct appState
 {
   int state;
   int oldState;

   uint32_t counter;
   uint32_t heartCounter;   
   char hourS[3];
   char minS[3];   
   int rssi;
   int pulse;
   int spo2;   
   char pulseS[6];
   char spo2S[6];
   int batVolt;
   int msgCount;
   bool msgChanged;   
   struct ParamList *pL;
   const struct Param *pLA;
   uint16_t msgID;   
   bool isAssociated; // to an access point
   
 };
 
 struct appState AppState;
 struct appState *gAppState = &AppState;
 int gInfoMenu  = -1;
 int gIdleMenu  = -1;
 int gPoxMenu  = -1;
 int gMessageMainMenu  = -1;
 int gMessageDetailMenu  = -1;

 // offset tot he rssi value to get a range
#define RSSI_OFFSET 50

  
 /**************************************************
  * icons
  **************************************************/ 
#define STD_ICON_WIDTH 24
#define STD_ICON_HEIGHT 17


#define RSSI_ICON_X 80
#define RSSI_ICON_Y 17
 static Rect rssiIconRect = {RSSI_ICON_X,RSSI_ICON_Y - STD_ICON_HEIGHT,STD_ICON_WIDTH,STD_ICON_HEIGHT};
#define BATTERY_ICON_X 2
#define BATTERY_ICON_Y 17
 static Rect batteryIconRect = {BATTERY_ICON_X,BATTERY_ICON_Y - STD_ICON_HEIGHT,STD_ICON_WIDTH,STD_ICON_HEIGHT};
#define POX_ICON_X 4
#define POX_ICON_Y 60
 static Rect poxIconRect = {POX_ICON_X,POX_ICON_Y - STD_ICON_HEIGHT,STD_ICON_WIDTH,STD_ICON_HEIGHT};

#define MESSAGE_ICON_X 45
#define MESSAGE_ICON_Y 17
 static Rect messageIconRect = {MESSAGE_ICON_X,MESSAGE_ICON_Y - STD_ICON_HEIGHT,STD_ICON_WIDTH,STD_ICON_HEIGHT};


 
 char gEmptyString[1] = "";
#define IDLE_PAGE_HOUR_SLOT 0
#define IDLE_PAGE_COLON_SLOT 1
#define IDLE_PAGE_MIN_SLOT 2 
#define IDLE_PAGE_PATIENT_SLOT 3
#define IDLE_PAGE_ID_SLOT 4

#define TIME_X 126
#define TIME_Y 14


 
 static Rect timeDataRect = {TIME_X-5,TIME_Y-14,LCD_WIDTH-(TIME_X-5),15};

 static Rect patientNameDataRect = {1,12,LCD_WIDTH-2,21};
 static Rect patientIDDataRect = {1,34,LCD_WIDTH-2,21};
 static  struct  lcd_strings IdlePage[] = 
   {
     {{TIME_X,TIME_Y},FONT_HELVETICA_R_12,LCD_ALIGN_LEFT,gEmptyString}, // hour
     {{TIME_X+14,TIME_Y},FONT_HELVETICA_R_12,LCD_ALIGN_LEFT,gEmptyString}, // colon
     {{TIME_X+18,TIME_Y},FONT_HELVETICA_R_12,LCD_ALIGN_LEFT,gEmptyString}, // min     
     {{LCD_WIDTH/2,32},FONT_HELVETICA_R_18,LCD_ALIGN_CENTER,gEmptyString}, // name
     {{LCD_WIDTH/2,54},FONT_HELVETICA_R_18,LCD_ALIGN_CENTER,gEmptyString}, // id
     {{0,0},0,LCD_ALIGN_LEFT,NULL}
   };

#define POX_PAGE_PULSE_SLOT 0
#define POX_PAGE_SPO2_SLOT 1
#define POX_PAGE_SENSOR_SLOT 2  
#define PULSE_X 26
#define PULSE_Y 38 
#define SPO2_X 100
#define SPO2_Y (PULSE_Y)
#define PULSE_DATA_X (PULSE_X+4)
#define PULSE_DATA_Y (PULSE_Y+22) 
#define SPO2_DATA_X (SPO2_X)
#define SPO2_DATA_Y (SPO2_Y+22)
#define INFO_DEVICE_X (LCD_WIDTH/2)
#define INFO_DEVICE_Y (45)
 
 static Rect poxDataRect = {PULSE_DATA_X,(PULSE_DATA_Y-20),125,22};
 static  struct  lcd_strings POXPage[] = 
   {
     {{PULSE_DATA_X,PULSE_DATA_Y},FONT_HELVETICA_R_18,LCD_ALIGN_LEFT,gEmptyString}, // pulse
     {{SPO2_DATA_X,SPO2_DATA_Y},FONT_HELVETICA_R_18,LCD_ALIGN_LEFT,gEmptyString}, // spo2
     {{LCD_WIDTH/2,80},FONT_HELVETICA_R_12,LCD_ALIGN_CENTER,gEmptyString}, // sensor
     {{PULSE_X,PULSE_Y},FONT_HELVETICA_R_18,LCD_ALIGN_LEFT,"PULSE"},
     {{SPO2_X,SPO2_Y},FONT_HELVETICA_R_18,LCD_ALIGN_LEFT,"SPO2"},     
     {{0,0},0,LCD_ALIGN_LEFT,NULL}
   };

#define INFO_PAGE_IP_SLOT 0

 static  struct  lcd_strings InfoPage[] = 
   {
     {{INFO_DEVICE_X,INFO_DEVICE_Y},FONT_HELVETICA_R_12,LCD_ALIGN_CENTER,gEmptyString}, // ip
     {{LCD_WIDTH/2,32},FONT_HELVETICA_R_18,LCD_ALIGN_CENTER,"Device Info"},
     {{0,0},0,LCD_ALIGN_LEFT,NULL}
   };

 static  struct  lcd_strings MessageMainPage[] = 
   {
     {{LCD_WIDTH/2,32},FONT_HELVETICA_R_18,LCD_ALIGN_CENTER,"Messages"},
     {{0,0},0,LCD_ALIGN_LEFT,NULL}
   };

 static Rect messageDetailDataRect = {2,40,LCD_WIDTH - 2 - 1,92-40 -1};  
 static  struct  lcd_strings MessageDetailPage[] = 
   {

     {{LCD_WIDTH/2,32},FONT_HELVETICA_R_18,LCD_ALIGN_CENTER,"Message Detail"},
     {{0,0},0,LCD_ALIGN_LEFT,NULL}
   };
 

 static Rect idleMenuRect = {6,60,LCD_WIDTH-2,LCD_HEIGHT-60-2};
 static Rect infoMenuRect = {6,52,LCD_WIDTH-2,LCD_HEIGHT-52-2};
 static Rect poxMenuRect = {6,95,LCD_WIDTH-2,LCD_HEIGHT-95-2};
 static Rect messageMainMenuRect = {6,40,LCD_WIDTH-2,LCD_HEIGHT-40-2};
 static Rect messageDetailMenuRect = {6,92,LCD_WIDTH-2,LCD_HEIGHT-92-2}; 
 
 void draw_lcd_string(const struct lcd_strings *page);
 void draw_page(const struct lcd_strings *page);
  

 enum { MENU_IDLE_ITEM_PULSEOX=0,
	MENU_IDLE_ITEM_MESSAGES, 
	MENU_IDLE_ITEM_INFO};

 enum { MENU_INFO_ITEM_EXIT=0,
	};
 enum { MENU_POX_ITEM_EXIT=0,
	};
 enum { MENU_MESSAGE_DETAIL_ITEM_DELETE=0,
	};

 
  static const struct MenuItem idleMenuItems[] = 
    {
      {(void *) "PulseOx",MENU_STATE_UNSELECTABLE,MENU_TYPE_STRING},
      {(void *)"Messages",MENU_STATE_UNSELECTABLE,MENU_TYPE_STRING},
      {(void *)"Device Info",MENU_STATE_NONE,MENU_TYPE_STRING},
      {NULL,MENU_STATE_NONE,MENU_TYPE_STRING}
    };

  static const struct MenuItem infoMenuItems[] = 
    {
      {(void *)"Exit",MENU_STATE_NONE,MENU_TYPE_STRING},
      {NULL,MENU_STATE_NONE,MENU_TYPE_STRING}
    };

  static const struct MenuItem messageDetailMenuItems[] = 
    {
      {(void *) "Delete",MENU_STATE_NONE,MENU_TYPE_STRING},
      {NULL,MENU_STATE_NONE,MENU_TYPE_STRING}
    };

  static const struct MenuItem poxMenuItems[] = 
    {
      {(void *)"Exit",MENU_STATE_NONE,MENU_TYPE_STRING},
      {NULL,MENU_STATE_NONE,MENU_TYPE_STRING}
    };

#undef DEBUG_APP  
#ifdef DEBUG_APP
#define APP_ERROR(s,i ) {Error(s,i);}
#else
#define APP_ERROR(s,i) {}  
#endif //DEBUG_APP  

#ifdef DEBUG_APP
  
  void Error(char *s,int e)
    {
      char buf[128];
      Point p = {2,100};
      volatile int hold;

      call LCD.clear();
      snprintf(buf,128,"%s:%d",s,e);	
      for (hold = 1; hold < 100; hold++)
	call LCD.gf_draw_string(buf,FONT_HELVETICA_R_12,&p,GF_OR);
    }
  
#endif //DEBUG_APP  



  
  
  
  command result_t StdControl.init() {

    call Leds.init();
    call PVStdControl.init();
    call IPStdControl.init();
    call IMAPStdControl.init();    
#if defined(HAVE_TELNET)
    call TelnetStdControl.init();
#endif
#if defined(SERVER)
    call SIPLiteStdControl.init();
#endif
    call LCD.init();

    // initialize our data structure
    gAppState->state = IDLE_STATE;
    gAppState->oldState = IDLE_STATE;
    sprintf(gAppState->hourS,"%.2d",0);
    sprintf(gAppState->minS,"%.2d",0);    
    gAppState->counter = 0;
    gAppState->heartCounter = 0;    
    gAppState->rssi = 0;
    gAppState->pulse = 0;
    sprintf(gAppState->pulseS,"%d",gAppState->pulse);
    gAppState->spo2 = 0;
    sprintf(gAppState->spo2S,"%d",gAppState->spo2);
    gAppState->batVolt = 3650; // force full bat state w/ no ADC
    gAppState->msgCount = 0;
    gAppState->msgChanged = FALSE;
    gAppState->isAssociated = FALSE;
    return SUCCESS;
  }

  command result_t StdControl.start() {
    struct ParamList *pL;
    
    
    call IPStdControl.start();
#if defined(SERVER)
    call SIPLiteStdControl.start();
#endif
    call IMAPStdControl.start(); 
#if defined(HAVE_TELNET)
    call TelnetStdControl.start();
#endif

    call LCD.clear();
    // Make the Menus 
    gIdleMenu = call Menu.makeRomMenu((void *) idleMenuItems);
    gInfoMenu = call Menu.makeRomMenu((void *) infoMenuItems);
    gPoxMenu = call Menu.makeRomMenu((void *) poxMenuItems);
    gMessageDetailMenu = call Menu.makeRomMenu((void *) messageDetailMenuItems);
    call TimerFast.start(TIMER_REPEAT, TIMER_FAST_INTERVAL);

    
    pL = call ParamList.getParamList();
    atomic 
      {
	gAppState->pL = pL;
	gAppState->pLA = NULL;
      }
    
	
    post handleState();    
    return SUCCESS;
    
  }
  
  command result_t StdControl.stop() {
    call TimerSlow.stop();
    call TimerFast.stop();
#if defined(HAVE_TELNET)
    call TelnetStdControl.stop();
#endif
    call IMAPStdControl.stop();    
#if defined(SERVER)
    call SIPLiteStdControl.stop();
#endif
    return call IPStdControl.stop();
  }
  void drawRadioIcon(int rssi,bool assoc)
    {
      Point p;
      int radioIcon;
      if (!assoc)
	radioIcon = 0;
      else {
	radioIcon = (rssi + RSSI_OFFSET)/NUM_RADIO_ICONS;	    
	if (radioIcon < 1)
	  radioIcon = 1;
	else if (radioIcon >= NUM_RADIO_ICONS)
	  radioIcon = NUM_RADIO_ICONS-1;
      }
      call LCD.gf_clear_rect(&rssiIconRect);
      p.x = rssiIconRect.x;
      p.y = rssiIconRect.y + rssiIconRect.h-1;
      call LCD.gf_draw_icon(ICON_RADIO,radioIcon,&p,GF_OR);
    }
  


  void drawMessageIcon(int msgCount)
    {
      Point p;

#if 1
      call LCD.gf_clear_rect(&messageIconRect);
      if (msgCount){
	p.x = messageIconRect.x;
	p.y = messageIconRect.y + rssiIconRect.h-1;
	call LCD.gf_draw_icon(ICON_ENVELOPE,0,&p,GF_OR);
      }
#else
      {
	char buf[24];
	call LCD.gf_clear_rect(&messageIconRect);
	p.x = messageIconRect.x;
	p.y = messageIconRect.y + messageIconRect.h-1;
	sprintf(buf,"%d",msgCount);
	call LCD.gf_draw_string(buf,FONT_HELVETICA_R_12,&p,GF_OR);
	call LCD.gf_get_string_rect(buf,FONT_HELVETICA_R_12,&p,&messageIconRect);
      }
#endif 

    }
  
  void drawBatteryIcon(int batVolt)
    {
      Point p;
      int batteryIcon;
      
      enum 
	{
	  BATV0=3000,
	  BATV1=3200,
	  BATV2=3400,
	  BATV3=3600,
	  BATV4=3900
	};
      
      
      // icons are prettier but the text makes debug easier
#if 1
      // math takes too 
      if (batVolt < BATV0)
	batteryIcon = 0;      
      else if (batVolt < BATV1)
	batteryIcon = 1;      
      else if (batVolt < BATV2)
	batteryIcon = 2;      
      else if (batVolt < BATV3)
	batteryIcon = 3;      
      else if (batVolt < BATV4)
	batteryIcon = 4;      
      else
	batteryIcon = 5;      

      call LCD.gf_clear_rect(&batteryIconRect);
      p.x = batteryIconRect.x;
      p.y = batteryIconRect.y + batteryIconRect.h-1;
      call LCD.gf_draw_icon(ICON_BATTERY,batteryIcon,&p,GF_OR);
#else
      {
	char buf[24];
	call LCD.gf_clear_rect(&batteryIconRect);
	p.x = batteryIconRect.x;
	p.y = batteryIconRect.y + batteryIconRect.h-1;
	sprintf(buf,"%d",batVolt);
	call LCD.gf_draw_string(buf,FONT_HELVETICA_R_12,&p,GF_OR);
	call LCD.gf_get_string_rect(buf,FONT_HELVETICA_R_12,&p,&batteryIconRect);
      }
#endif 
    }
	
  void drawPoxIcon()
    {
      Point p;

      if (gAppState->heartCounter%2)      
	call LCD.gf_clear_rect(&poxIconRect);
      else {
	p.x = poxIconRect.x;
	p.y = poxIconRect.y + batteryIconRect.h-1;
	call LCD.gf_draw_icon(ICON_HEART,0,&p,GF_OR);
      }
      atomic
	gAppState->heartCounter++;
      
    }
	

  
  // we just do time and icons, no stte changes happen here
  // but what icons we can draw depends on the state
  task void handleFastUpdates()
    {
      int state;

      atomic 
	state = gAppState->state;

      
      
      switch (state){
      case IDLE_STATE:
      case INFO_MAIN_STATE:
      case INFO_SUB_STATE:      
      case MESSAGE_MAIN_STATE:
      case MESSAGE_DETAIL_STATE:
	{
	  char hourS[3];
	  char minS[3];
	  char colonS[2] = " ";	  
	  int rssi;
	  uint16_t batVolt;
	  bool isAssociated;
	  int msgCount;
	  
	  
  
	  atomic 
	    {
	      if (gAppState->counter%2)
		strcpy(colonS,":");
	      batVolt = gAppState->batVolt;
	      strcpy(hourS,gAppState->hourS);
	      strcpy(minS,gAppState->minS);
	      isAssociated = gAppState->isAssociated;
	      msgCount = gAppState->msgCount;
	    }
	  if (isAssociated)
	    rssi = call Client.get_average_rssi();
	  else
	    rssi = -RSSI_OFFSET;


	  // draw the relevant icons
	  drawRadioIcon(rssi,isAssociated);
	  drawBatteryIcon(batVolt);
	  drawMessageIcon(msgCount);

	  
	  // fill in the time etc
	  IdlePage[IDLE_PAGE_HOUR_SLOT].str = hourS;
	  IdlePage[IDLE_PAGE_COLON_SLOT].str = colonS;
	  IdlePage[IDLE_PAGE_MIN_SLOT].str = minS;
	  // clear the dynamic parts
	  call LCD.gf_clear_rect(&timeDataRect);

	  
	  // draw the main idle screen fast elements	
	  draw_lcd_string(&IdlePage[IDLE_PAGE_HOUR_SLOT]);	  
	  draw_lcd_string(&IdlePage[IDLE_PAGE_COLON_SLOT]);
	  draw_lcd_string(&IdlePage[IDLE_PAGE_MIN_SLOT]);

	  // clear the string pointers
	  IdlePage[IDLE_PAGE_HOUR_SLOT].str = gEmptyString;
	  IdlePage[IDLE_PAGE_COLON_SLOT].str = gEmptyString;
	  IdlePage[IDLE_PAGE_MIN_SLOT].str = gEmptyString;
	}
	break;
      case POX_CONNECTED_STATE:
	break;
	  
      default:
	break;
      }
    }
  

  void drawIdleState(int oldState,int state)
    {
      bool isAssociated;
      int msgCount;

      atomic 
	{
	  isAssociated=gAppState->isAssociated;
	  msgCount = gAppState->msgCount;
	}
      
      if ((state != IDLE_STATE))
	return;
      call Menu.undisplayMenu();
      
      IdlePage[IDLE_PAGE_PATIENT_SLOT].str = PatientName;
      IdlePage[IDLE_PAGE_ID_SLOT].str = PatientID;
      call LCD.gf_clear_rect(&patientNameDataRect);
      call LCD.gf_clear_rect(&patientIDDataRect);
            
      // draw the main idle screen	
      draw_page(IdlePage);

      IdlePage[IDLE_PAGE_PATIENT_SLOT].str = gEmptyString;
      IdlePage[IDLE_PAGE_ID_SLOT].str = gEmptyString;

      if (isAssociated){
#if defined(SERVER)
	call Menu.setMenuState(gIdleMenu,MENU_IDLE_ITEM_PULSEOX,MENU_STATE_NONE);
#endif
      }
      else {
	call Menu.setMenuState(gIdleMenu,MENU_IDLE_ITEM_PULSEOX,MENU_STATE_UNSELECTABLE);
      }

      if (msgCount){
	call Menu.setMenuState(gIdleMenu,MENU_IDLE_ITEM_MESSAGES,MENU_STATE_NONE);
      }
      else {
	call Menu.setMenuState(gIdleMenu,MENU_IDLE_ITEM_MESSAGES,MENU_STATE_UNSELECTABLE);
      }
      call Menu.setMenuSelection(-1);      
      call Menu.setMenuRect(&idleMenuRect);	  
      call Menu.displayMenu(gIdleMenu);

    }

  task void drawPOXData()
    {
      char pulseS[6];
      char spo2S[6];
      int pulse;
      int spo2;
      int state;
      
      atomic 
	{
	  state = gAppState->state;
	  pulse = gAppState->pulse;
	  spo2 = gAppState->spo2;
	};
      
      
      if (state != POX_CONNECTED_STATE)
	return;

      drawPoxIcon();      
      
      if ((pulse > 500)|| (pulse == 0)){
	sprintf(pulseS,"%s","N/A");
	sprintf(spo2S,"%s","N/A");
      }
      else{
	sprintf(pulseS,"%d",pulse);
	sprintf(spo2S,"%d",spo2);
      }
	
      POXPage[POX_PAGE_PULSE_SLOT].str = pulseS;
      POXPage[POX_PAGE_SPO2_SLOT].str = spo2S;

      // clear the dynamic parts
      call LCD.gf_clear_rect(&poxDataRect);
      
      // draw the main idle screen fast elements	
      draw_lcd_string(&POXPage[POX_PAGE_PULSE_SLOT]);	  
      draw_lcd_string(&POXPage[POX_PAGE_SPO2_SLOT]);

      // clear the string pointers
      POXPage[POX_PAGE_PULSE_SLOT].str = gEmptyString;
      POXPage[POX_PAGE_SPO2_SLOT].str = gEmptyString;

      
    }
  
#if defined(SERVER)  
  void drawPOXState(int oldState,int state)
    {
      char connectionS[24] = "Connecting...";
      char sensorS[24];
      
      if ((state != POX_CONNECTING_STATE) &&
	  (state != POX_CONNECTED_STATE)) 
	return;

      sprintf(sensorS,"%d.%d.%d.%d",SERVER);
      if (state == POX_CONNECTING_STATE){
	POXPage[POX_PAGE_PULSE_SLOT].str = connectionS;
      }
      POXPage[POX_PAGE_SENSOR_SLOT].str = sensorS;      
      draw_page(POXPage);

      // clear the string pointers
      POXPage[POX_PAGE_PULSE_SLOT].str = gEmptyString;
      POXPage[POX_PAGE_SENSOR_SLOT].str = gEmptyString;      

      call Menu.setMenuRect(&poxMenuRect);	  
      call Menu.displayMenu(gPoxMenu);
    }
#endif
      
  void drawInfoState(int oldState,int state)
    {
      char ipS[24];
      struct ParamList *pL;
      const struct Param *pLA;

      atomic 
	{
	  pL = gAppState->pL;
	  pLA = gAppState->pLA;	  
	}

      if (gInfoMenu>=0){	
	call Menu.deleteMenu(gInfoMenu);
	gInfoMenu = -1;
      }
      
      gInfoMenu = call Menu.makeMenu();
      call Menu.setDynamic(gInfoMenu);
      
      if (state == INFO_MAIN_STATE){
	while(pL){
	  if ((call Menu.addItem(gInfoMenu,(void *) pL,MENU_STATE_NONE,MENU_TYPE_PARAMLIST)) < 0)
	    APP_ERROR("cant add pL",(int)pL);	
	  pL = pL->next;	  
	}	
      }
      else {
	while (pLA->name){
#if 0
	{
	  char l_buf[128];
	  Point p2;
	  volatile int hold;
	  
	  Rect r2;
	  p2.x = 1;
	  p2.y = 80;

	  call LCD.clear();

	  sprintf(l_buf,"p[0]:0x%x n:%s",pLA,pLA->name);
	  for (hold = 1; hold < 100; hold++)
	    call LCD.gf_draw_string(l_buf,FONT_HELVETICA_R_12,&p2,GF_OR);
      }
#endif


	  if ((call Menu.addItem(gInfoMenu,(void *) pLA,MENU_STATE_NONE,MENU_TYPE_PARAM)) < 0)
	    APP_ERROR("cant add pla",(int)pLA);	
	  pLA++;
	}

	

	
      }

      sprintf(ipS,"%d.%d.%d.%d",IP);
      InfoPage[INFO_PAGE_IP_SLOT].str = ipS;      
      draw_page(InfoPage);

      // clear the string pointers
      InfoPage[INFO_PAGE_IP_SLOT].str = gEmptyString;      

      call Menu.setMenuRect(&infoMenuRect);	  
      call Menu.displayMenu(gInfoMenu);
    }
      
  void drawMainMessageState(int oldState,int state)
    {
      int msgCount;
      const struct TextMessage *tm;
      int i;
      int selItem;

      // if there was a selected item for the menu use the cursor to get the best selection
      //available in case someone deleted it.
      if ((selItem = call Menu.getMenuSelection(gMessageMainMenu)) >= 0){	
	selItem = call IMAPLite.get_cursor();
	APP_ERROR("get_cursor to:",selItem);
      }
	
      if (gMessageMainMenu>=0){	
	call Menu.undisplayMenu();
	call Menu.deleteMenu(gMessageMainMenu);
	gMessageMainMenu = -1;
      }
      
      gMessageMainMenu = call Menu.makeMenu();

      msgCount = call IMAPLite.count_msgs();
      
      for (i=0; i < msgCount; i++){
	tm = call IMAPLite.get_msg_by_index(i);
	if (tm)
	  if ((call Menu.addItem(gMessageMainMenu,(void *) tm->id,MENU_STATE_NONE,MENU_TYPE_MESSAGE)) < 0)
	    APP_ERROR("bad add message id",tm->id);	  	  	  
      }

      call Menu.setMenuRect(&messageMainMenuRect);	        
      call Menu.displayMenu(gMessageMainMenu);
      call Menu.setMenuSelection(selItem);      
      draw_page(MessageMainPage);

    }

  void drawDetailedMessageState(int oldState,int state)
    {
      const struct TextMessage *tm;
      uint16_t msgID;
      char msg_buf[128];
      Point p;
      
	
      atomic
	msgID = gAppState->msgID;
      // if we are watching a detailed messsage keep watching it even if things change,
      if (oldState == state)
	return;
      

      p.x = messageDetailDataRect.x;
      // XXX hack for leading
      p.y = messageDetailDataRect.y+13;
      
      tm = call IMAPLite.get_msg_by_id(msgID);
      if (tm){
	strcpy(msg_buf,tm->text);
      }
      else
	msg_buf[0] = '\0';
      

      draw_page(MessageDetailPage);
      // do the multiline copy
      call LCD.gf_clear_rect(&messageDetailDataRect);      
      call LCD.gf_draw_multiline_string_aligned(msg_buf,FONT_HELVETICA_R_12,&p,GF_OR, LCD_ALIGN_LEFT);
      
      
      call Menu.setMenuRect(&messageDetailMenuRect);	  
      call Menu.displayMenu(gMessageDetailMenu);

    }
  
  
  task void handleState()
    {
      int state,oldState;
      bool isAssociated;
      
      atomic 
	{
	  state = gAppState->state;
	  oldState = gAppState->oldState;
	  isAssociated = gAppState->isAssociated;	  
	  gAppState->oldState = gAppState->state;
	}
      call Leds.yellowToggle();
      // major changes require major erase
      if (state != oldState){
	call LCD.clear();      
      }

      switch (state){
      case IDLE_STATE:
	drawIdleState(oldState,state);
#if defined(SERVER)
	if (!isAssociated)
	  post closeSIPLiteConnection();
#endif
	break;
      case POX_CONNECTING_STATE:
#if defined(SERVER)
	drawPOXState(oldState,state);	
#endif
	break;
      case POX_CONNECTED_STATE:
#if defined(SERVER)
	drawPOXState(oldState,state);
	post drawPOXData();	
#endif
	break;
      case INFO_MAIN_STATE:
      case INFO_SUB_STATE:
	call TimerSlow.stop();
	call TimerSlow.start(TIMER_ONE_SHOT, TIMER_INTERVAL);      
	drawInfoState(oldState,state);
	break;	
      case MESSAGE_MAIN_STATE:
	call TimerSlow.stop();
	call TimerSlow.start(TIMER_ONE_SHOT, TIMER_INTERVAL);
	drawMainMessageState(oldState,state);
	break;	
      case MESSAGE_DETAIL_STATE:
	call TimerSlow.stop();
	call TimerSlow.start(TIMER_ONE_SHOT, TIMER_INTERVAL);
	drawDetailedMessageState(oldState,state);
	break;	
      default:
	//Error !! no get here i hope
	while (1){
	  call Leds.yellowToggle();
	  call Leds.greenToggle();
	}
	
	break;
      }

    }
  
      

#if defined(SERVER)
  task void  connectToServer()
    {
      if ( call SIPLiteClient.connect( SERVER, 5062,MEDIA_TYPE_PULSE_ONLY ) != SUCCESS )
	{
	  //call Leds.set(7);
	}
      
    }

  task void  closeSIPLiteConnection()
    {
      call SIPLiteClient.close( );      
    }
#endif

  inline void draw_lcd_string(const struct lcd_strings *ls)
    {
      call LCD.gf_draw_string_aligned(ls->str,ls->fontNum,(Point *) &(ls->p),GF_OR, ls->alignment);
    }
  
  void draw_page(const struct lcd_strings *page)
    {
      const struct lcd_strings *ls = page;

      while(ls->str){
	draw_lcd_string(ls);
	ls++;
      }
    }

  void erase_page(const struct lcd_strings *page)
    {
      const struct lcd_strings *ls = page;

      while(ls->str){
	call LCD.gf_erase_string(ls->str,ls->fontNum,(Point *) &(ls->p),ls->alignment);
	ls++;
      }
    }

  task void updateIMAP()
    {
      bool conn;      
      atomic
	conn = gAppState->isAssociated;
      call IMAPLite.update( IMAP_SERVER, 3143 );      
    }
  
  task void handleSlowTimer()
    {
      atomic {
	gAppState->oldState = gAppState->state;	  
	gAppState->state = IDLE_STATE;
      };
      post handleState();      
    }
  
  
  //this is for *VERY* slow timeouts like page returns
  event result_t TimerSlow.fired() {
    post handleSlowTimer();    
    return SUCCESS;
  }


  event result_t TimerFast.fired() {
    gAppState->counter++;         
    post handleFastUpdates();
    // every 4 seconds go ahead and talk to the imap server
    if (!(gAppState->counter%4))
      post updateIMAP();    
    return SUCCESS;
  }


  event result_t Menu.menuSelectionChanged(int whichMenu,int whichItem)
    {
      int state;
      
      atomic
	state = gAppState->state;

      // in the messagemain state we should play with cursors here
      if (state == MESSAGE_MAIN_STATE){
	int id;
	id = (int) call Menu.getMenuUID(whichMenu,whichItem);
	call IMAPLite.set_cursor(whichItem);
	APP_ERROR("set_cursor to:",whichItem);
      }
      call TimerSlow.stop();
      call TimerSlow.start(TIMER_ONE_SHOT, TIMER_INTERVAL);
      return SUCCESS;      
    }
  
  event result_t Menu.menuSelect(int whichMenu,int whichItem)
    {
      int state;

      atomic
	state = gAppState->state;

      call TimerSlow.stop();
      call TimerSlow.start(TIMER_ONE_SHOT, TIMER_INTERVAL);
      if (whichMenu ==  gIdleMenu){
	call Menu.undisplayMenu();
	switch (whichItem){
	case MENU_IDLE_ITEM_PULSEOX:
	  atomic {
	    gAppState->oldState = gAppState->state;	  
	    gAppState->state = POX_CONNECTING_STATE;
	  };
	  call Menu.undisplayMenu();	  
	  post handleState(); // display connecting page
#if defined(SERVER)
	  post connectToServer(); // start up the connection
#endif
	  break;
	case MENU_IDLE_ITEM_MESSAGES:
	  atomic {
	    gAppState->oldState = gAppState->state;	  
	    gAppState->state = MESSAGE_MAIN_STATE;
	  };
	  call Menu.undisplayMenu();	  
	  post handleState(); // display connecting page	  
	  break;
	case MENU_IDLE_ITEM_INFO:
	  atomic {
	    gAppState->oldState = gAppState->state;	  
	    gAppState->state = INFO_MAIN_STATE;
	  };
	  call Menu.undisplayMenu();	  
	  post handleState(); // display connecting page
	  break;
	default:
	  break;
	}
      }
      
      else if (whichMenu == gPoxMenu){
	switch (whichItem){
	case MENU_POX_ITEM_EXIT:
	  atomic {
	    gAppState->oldState = gAppState->state;	  
	    gAppState->state = IDLE_STATE;
	  };
	  call Menu.undisplayMenu();
#if defined(SERVER)
	  post closeSIPLiteConnection();
#endif
	  post handleState(); // display connecting page
	  break;
	default:
	  break;
	}
      }
      else if (whichMenu == gInfoMenu){
	void *uid;
	
	switch (state){
	case INFO_MAIN_STATE:
	  {
	    const struct ParamList *pL;
	    const struct Param *pLA;
	    
	    uid = call Menu.getMenuUID(whichMenu,whichItem);
	    pL = (const struct ParamList *) uid;
	    pLA = pL->list;	    
	  atomic {
	    gAppState->oldState = gAppState->state;	  
	    gAppState->state = INFO_SUB_STATE;
	    gAppState->pLA = pLA;	    
	  };
	  }	  
	  break;	  
	case INFO_SUB_STATE:
	  break;
	}
	call Menu.undisplayMenu();	  
	post handleState(); // display connecting page
      }
      else if (whichMenu == gMessageMainMenu){
	uint16_t msgID;
	
	msgID = (uint16_t) call Menu.getMenuUID(whichMenu,whichItem);
	
	atomic {
	  gAppState->oldState = gAppState->state;	  
	  gAppState->state = MESSAGE_DETAIL_STATE;
	  gAppState->msgID = msgID;	    
	};
	call Menu.undisplayMenu();	  
	post handleState(); // display connecting page

      }
      else if (whichMenu == gMessageDetailMenu){
	uint16_t msgID;
	atomic
	  msgID = gAppState->msgID;

	if (whichItem == MENU_MESSAGE_DETAIL_ITEM_DELETE){
	  call IMAPLite.remove_msg(msgID);
	}
	atomic {
	  gAppState->oldState = gAppState->state;	  
	  gAppState->state = MESSAGE_MAIN_STATE;
	};
	call Menu.undisplayMenu();	  
	post handleState(); // display connecting page
      }	  

      return SUCCESS;
      
    }
  
  
  event result_t Menu.menuEscape(int whichMenu)
    {
      int state;

      atomic
	state = gAppState->state;


      call TimerSlow.stop();
      call TimerSlow.start(TIMER_ONE_SHOT, TIMER_INTERVAL);
      if (whichMenu == gIdleMenu){
	call Menu.setMenuSelection(-1);
      }
      else if (whichMenu == gPoxMenu){
	atomic {
	  gAppState->oldState = gAppState->state;	  
	  gAppState->state = IDLE_STATE;
	};
	call Menu.undisplayMenu();
#if defined(SERVER)
	post closeSIPLiteConnection();
#endif
	post handleState(); // display connecting page
      }
      else if (whichMenu == gInfoMenu){      
	switch (state){
	case INFO_MAIN_STATE:
	  atomic {
	    gAppState->oldState = gAppState->state;	  
	    gAppState->state = IDLE_STATE;
	  };
	  break;
	case INFO_SUB_STATE:
	  atomic {
	    gAppState->oldState = gAppState->state;	  
	    gAppState->state = INFO_MAIN_STATE;
	  };
	  break;
	}
	call Menu.undisplayMenu();	  
	post handleState(); // display connecting page
	
      }
      else if (whichMenu == gMessageMainMenu){
	atomic {
	  gAppState->oldState = gAppState->state;	  
	  gAppState->state = IDLE_STATE;
	};
	call Menu.undisplayMenu();
	post handleState(); // display connecting page
      }
      else if (whichMenu == gMessageDetailMenu){
	atomic {
	  gAppState->oldState = gAppState->state;	  
	  gAppState->state = MESSAGE_MAIN_STATE;
	};
	call Menu.undisplayMenu();
	post handleState(); // display connecting page
      }


      return SUCCESS;
    }

  
  /*****************************************
   *  SIPLiteClient interface
   *****************************************/

#if defined(SERVER)
  event void SIPLiteClient.connectDone( bool isUp )
  {
    int state;
    
    atomic
      state = gAppState->state;
    if (isUp){
      // only handle it in connecting state
      if (state == POX_CONNECTING_STATE){
	atomic {
	  gAppState->oldState = gAppState->state;	  
	  gAppState->state = POX_CONNECTED_STATE;
	};
	post handleState();
      }      
    }
    else {
      // if we were connected or trying to connect and we failed
      // try again

      // else we ignore the message
      if ((state == POX_CONNECTING_STATE) ||
	  (state == POX_CONNECTED_STATE)){
	  atomic {
	    gAppState->oldState = gAppState->state;	  
	    gAppState->state = POX_CONNECTING_STATE;
	  };
	  post handleState();	  
	  post connectToServer(); // start up the connection
      }
    }
    
      
  }

  event void SIPLiteClient.connectionFailed( uint8_t reason )
  {
    int state;
    
    atomic
      state = gAppState->state;
    
    if ((state == POX_CONNECTING_STATE) ||
	(state == POX_CONNECTED_STATE)){
      atomic {
	gAppState->oldState = gAppState->state;	  
	gAppState->state = POX_CONNECTING_STATE;
      };
      post handleState();	  
      post connectToServer(); // start up the connection
    }
  }

  event void SIPLiteClient.dataAvailable( uint8_t *buf, uint16_t len )
  {
    int state;
    
    atomic
      state = gAppState->state;

    if (state != POX_CONNECTED_STATE)
      return;
    
    if (len == sizeof(struct XpodDataShort)){
      struct XpodDataShort *xps = (struct XpodDataShort *) buf;
      atomic {
	gAppState->pulse = xps->heart_rate_display;
	gAppState->spo2 = xps->spo2_display;
      }
    }
    post drawPOXData();    
  }
#endif

  /*****************************************
   *  Client interface
   *****************************************/
  event void Client.connected( bool isConnected )
  {
    if (isConnected){
      call Leds.greenOn();
      gAppState->isAssociated = TRUE;      
    }
    else {
      call Leds.greenOff();

      // noswitch out of the info states unless by hand
      if ((gAppState->state != INFO_MAIN_STATE) &&
	  (gAppState->state != INFO_SUB_STATE)){
	gAppState->oldState  = gAppState->state ;
	gAppState->state = IDLE_STATE;
      }
      gAppState->isAssociated = FALSE;      
    }      

    post handleState();    
  }

#if defined(HAVE_TELNET)
  /*****************************************
   *  Telnet interface
   *****************************************/

  event const char * Telnet.token() { return "sip"; }
  event const char * Telnet.help() { return "Sip client control\r\n"; }

  event char * Telnet.process( char *in, char *out, char *outmax )
  {
    out += snprintf(out, outmax - out, "This doesn't do anything\r\n");
    return out;
  }
#endif



  /*****************************************
   *  Battery Voltage interface
   *****************************************/
#if defined(BATTERY_VOLTAGE)
  event result_t BatVolt.dataReady(uint16_t data)
    {
      atomic
	gAppState->batVolt = data;
      
      return SUCCESS;
    }
#endif

  /*****************************************
   *  NTPClient interface
   *****************************************/

  event void NTPClient.timestampReceived( uint32_t *seconds, uint32_t *fraction )
  {

  }


  /*****************************************
   *  Time interface
   *****************************************/

  event void Time.tick(  )
  {
    time_t l_timer;
    struct tm l_tm;
    // do the time
    call Time.time(&l_timer);
    call Time.localtime(&l_timer, &l_tm);	
    atomic 
      {
	sprintf(gAppState->hourS,"%.2d",l_tm.tm_hour);
	sprintf(gAppState->minS,"%.2d",l_tm.tm_min);
      };
    //call Leds.yellowToggle();    
  }

  task void forceTimeUpdate()
    {
      time_t l_timer;
      struct tm l_tm;
      // do the time
      call Time.time(&l_timer);
      call Time.localtime(&l_timer, &l_tm);	
      atomic 
	{
	  sprintf(gAppState->hourS,"%.2d",l_tm.tm_hour);
	  sprintf(gAppState->minS,"%.2d",l_tm.tm_min);
	};        
    }


  /*****************************************
   *  PatientView interface
   *****************************************/

  event void PatientView.changed() {
    int state;    
    const struct Patient *patientInfo = call PatientView.getPatientInfo();
    state = gAppState->state;

    // copy bits where we need them
    strcpy(PatientName,patientInfo->name);
    strcpy(PatientID,patientInfo->id);
    if (state == IDLE_STATE)
      post handleState();
    
  }

  /*****************************************
   *  IMAP Interface
   *****************************************/

  event void IMAPLite.updateDone()
  {
  }

  event void IMAPLite.changed( int reason )
  {
    int msgCount;

    msgCount = call IMAPLite.count_msgs();
    
    atomic
      {	
	gAppState->msgCount = msgCount;
	gAppState->msgChanged = TRUE;
      }
    
    post handleState();
    
  }

  

  

}




