/************************************************************************************
* This is a global header file for the application/ASP interface.
*
* Author(s): JEHOL1
*
* (c) Copyright 2004, Freescale, Inc.  All rights reserved.
*
* Freescale Confidential Proprietary
* Digianswer Confidential
*
* No part of this document must be reproduced in any form - including copied,
* transcribed, printed or by any electronic means - without specific written
* permission from Freescale.
*
* Last Inspected:
* Last Tested:
*
* Source Safe revision history (Do not edit manually) 
*   $Date: 2005/10/12 15:01:42 $
*   $Author: janflora $
*   $Revision: 1.1 $
*   $Workfile: AppAspInterface.h $
************************************************************************************/

#ifndef _APP_ASP_INTERFACE_H_
#define _APP_ASP_INTERFACE_H_

/************************************************************************************
*************************************************************************************
* Includes
*************************************************************************************
************************************************************************************/

#include "DigiType.h"
#include "MacPhy.h"

/************************************************************************************
*************************************************************************************
* Public types
*************************************************************************************
************************************************************************************/

  // Valid values for aspSetNotifyReq_t->notifications.
enum {
  gAspNotifyNone_c,         // No notifications about beacon state
  gAspNotifyIdle_c,         // Notify about remaining time in Idle portion of CAP
  gAspNotifyInactive_c,     // Notify about remaining time in inactive portion of superframe
  gAspNotifyIdleInactive_c, // Notify about remaining time in Idle portion of CAP, and inactive portion of superframe
  gAspNotifyLastEntry_c     // Don't use! 
};

//-----------------------------------------------------------------------------------
//     Messages from application to ASP
//-----------------------------------------------------------------------------------

enum {
    // This sequence must match the secuence of gAspApp*** confirm primitives
  gAppAspGetTimeReq_c,
  gAppAspGetInactiveTimeReq_c,
  gAppAspDozeReq_c,
  gAppAspAutoDozeReq_c,
  gAppAspHibernateReq_c,
  gAppAspWakeReq_c,
  gAppAspEventReq_c,
  gAppAspTrimReq_c,
  gAppAspDdrReq_c,
  gAppAspPortReq_c,
  gAppAspClkoReq_c,
  gAppAspTempReq_c,
  gAppAspNvRamReq_c,
  gAppAspBatteryReq_c,
  gAppAspSetNotifyReq_c,
  gAppAspSetMinDozeTimeReq_c,
  gAppMaxPrimitives_c
};

  // Type: gAppAspGetTimeReq_c
typedef struct aspGetTimeReq_tag {
  uint8_t dummy;
} aspGetTimeReq_t;

  // Type: gAppAspGetInactiveTimeReq_c
typedef struct aspGetInactiveTimeReq_tag {
  uint8_t dummy;
} aspGetInactiveTimeReq_t;

  // Type: gAppAspDoze_c
typedef struct aspDozeReq_tag {
  uint8_t dozeDuration[3];
} aspDozeReq_t;

  // Type: gAppAspAutoDoze_c
typedef struct aspAutoDozeReq_tag {
  bool_t  autoEnable;
  bool_t  enableWakeIndication;
  uint8_t autoDozeInterval[3];
} aspAutoDozeReq_t;

  // Type: gAppAspHibernate_c
typedef struct aspHibernateReq_tag {
  uint8_t dummy;
} aspHibernateReq_t;

  // Type: gAppAspWake_c
typedef struct aspWakeReq_tag {
  uint8_t dummy;
} aspWakeReq_t;

  // Type: gAppAspEventReq_c
typedef struct aspEventReq_tag {
  uint8_t eventTime[3];
} aspEventReq_t;

  // Type: gAppAspTrimReq_c
typedef struct aspTrimReq_tag {
  uint8_t trimValue;
} aspTrimReq_t;

  // Type: gAppAspDdrReq_c
typedef struct aspDdrReq_tag {
  uint8_t directionMask; // Abel Addr 0x0B gpio's 3-7
} aspDdrReq_t;

  // Type: gAppAspPortReq_c
typedef struct aspPortReq_tag {
  uint8_t portWrite;  // Abel Addr 0x0C gpio's 3-7
  uint8_t portValue;
} aspPortReq_t;

  // Type: gAppAspClkoReq_c
typedef struct aspClkoReq_tag {
  bool_t  clkoEnable; // Abel Addr 0x09 bit 5
  uint8_t clkoRate;   // Abel Addr 0x0A bits 0-2
} aspClkoReq_t;

  // Type: gAppAspTempReq_c
typedef struct aspTempReq_tag {
  uint8_t dummy;
} aspTempReq_t;

  // Type: gAspNvRamReq_c
typedef struct appNvRamReq_tag {
  uint8_t flashId;
  uint8_t length;
  uint8_t *newData;
} aspNvRamReq_t;

  // Type: gAppAspBatteryReq_c
typedef struct aspBatteryReq_tag {
  uint8_t dummy;
} aspBatteryReq_t;

  // Type: gAppAspSetNotifyReq_c
typedef struct aspSetNotifyReq_tag {
  uint8_t notifications;
} aspSetNotifyReq_t;

  // Type: gAppAspSetMinDozeTimeReq_c
typedef struct aspSetMinDozeTimeReq_tag {
  uint8_t minDozeTime[3]; // Should be at least 2ms ((2*1000)/16 = 125) Default is 4ms.
} aspSetMinDozeTimeReq_t;

  // Application to ASP message
typedef struct appToAspMsg_tag {
  uint8_t msgType;
  union {
    aspGetTimeReq_t         aspGetTimeReq;
    aspGetInactiveTimeReq_t aspGetInactiveTimeReq;
    aspDozeReq_t            aspDozeReq;
    aspAutoDozeReq_t        aspAutoDozeReq;
    aspHibernateReq_t       aspHibernateReq;
    aspWakeReq_t            aspWakeReq;
    aspEventReq_t           aspEventReq;
    aspTrimReq_t            aspTrimReq;
    aspDdrReq_t             aspDdrReq;
    aspPortReq_t            aspPortReq;
    aspClkoReq_t            aspClkoReq;
    aspTempReq_t            aspTempReq;
    aspNvRamReq_t           aspNvRamReq;
    aspBatteryReq_t         aspBatteryReq;
    aspSetNotifyReq_t       aspSetNotifyReq;
    aspSetMinDozeTimeReq_t  aspSetMinDozeTimeReq;
  } msgData;
} appToAspMsg_t;

//-----------------------------------------------------------------------------------
//     Messages from ASP to application
//-----------------------------------------------------------------------------------
enum {
    // This sequence must match the secuence of gAppAsp*** request primitives
  gAspAppGetTimeCfm_c         = gAppAspGetTimeReq_c,
  gAspAppGetInactiveTimeCfm_c = gAppAspGetInactiveTimeReq_c,
  gAspAppDozeCfm_c            = gAppAspDozeReq_c,
  gAspAppAutoDozeCfm_c        = gAppAspAutoDozeReq_c,
  gAspAppHibernateCfm_c       = gAppAspHibernateReq_c,
  gAspAppWakeCfm_c            = gAppAspWakeReq_c,
  gAspAppEventCfm_c           = gAppAspEventReq_c,
  gAspAppTrimCfm_c            = gAppAspTrimReq_c,
  gAspAppDdrCfm_c             = gAppAspDdrReq_c,
  gAspAppPortCfm_c            = gAppAspPortReq_c,
  gAspAppClkoCfm_c            = gAppAspClkoReq_c,
  gAspAppTempCfm_c            = gAppAspTempReq_c,
  gAspAppNvRamCfm_c           = gAppAspNvRamReq_c,
  gAspAppBatteryCfm_c         = gAppAspBatteryReq_c,
  gAspAppSetNotifyCfm_c       = gAppAspSetNotifyReq_c,
  gAspAppSetMinDozeTimeCfm_c  = gAppAspSetMinDozeTimeReq_c,
  gAspErrorCfm_c,       
  gAspAppWakeInd_c,
  gAspAppIdleInd_c,
  gAspAppInactiveInd_c,
  gAspAppEventInd_c,
  gAspMaxPrimitives_c
};


  // Type: gAspAppGetTime_c
typedef struct appGetTimeCfm_tag {
  uint8_t status;
  uint8_t time[3];
} appGetTimeCfm_t;

  // Type: gAspAppGetInactiveTime_c
typedef struct appGetInactiveTimeCfm_tag {
  uint8_t status;
  uint8_t time[3];
} appGetInactiveTimeCfm_t;

  // Type: gAspAppWake_c
typedef struct appWakeCfm_tag {
  uint8_t status;
} appWakeCfm_t;

  // Type: gAspAppDoze_c
typedef struct appDozeCfm_tag {  // Not used
  uint8_t status;
  uint8_t actualDozeDuration[3];
} appDozeCfm_t;

  // Type: gAspAppAutoDoze_c
typedef struct appAutoDozeCfm_tag {  // Not used
  uint8_t status;
} appAutoDozeCfm_t;

  // Type: gAspHibernate_c
typedef struct appHibernateCfm_tag { // Not used
  uint8_t status;
} appHibernateCfm_t;

  // Type: gAspAppEventCfm_c
typedef struct appEventCfm_tag {
  uint8_t  status;
} appEventCfm_t;

  // Type: gAspAppTrimCfm_c
typedef struct appTrimCfm_tag {
  uint8_t  status;
} appTrimCfm_t;

  // Type: gAspAppDdrCfm_c
typedef struct appDdrCfm_tag {
  uint8_t  status;
} appDdrCfm_t;

  // Type: gAspAppPortCfm_c
typedef struct appPortCfm_tag {
  uint8_t  status;
  uint8_t  portResult;
} appPortCfm_t;

  // Type: gAspAppClkoCfm_c
typedef struct appClkoCfm_tag {
  uint8_t  status;
} appClkoCfm_t;

  // Type: gAspAppTempCfm_c
typedef struct appTempCfm_tag {
  uint8_t  status;
  uint16_t  temperature; // Only 12 least significant bits are valid
} appTempCfm_t;

  // Type: gAspAppWakeInd_c
typedef struct appWakeInd_tag {
  uint8_t status;
} appWakeInd_t;

  // Type: gAspAppIdleInd_c
typedef struct appIdleInd_tag {
  uint8_t timeRemaining[3];
} appIdleInd_t;

  // Type: gAspAppInactiveInd_c
typedef struct appInactiveInd_tag {
  uint8_t timeRemaining[3];
} appInactiveInd_t;

  // Type: gAspAppEventInd_c
typedef struct appEventInd_tag {
  uint8_t dummy; // This primitive has no parameters.
} appEventInd_t;

  // Type: gAspAppNvRamCfm_c
typedef struct appNvRamCfm_tag {
  uint8_t  status;
} appNvRamCfm_t;

  // Type: gAspAppBatteryCfm_c
typedef struct appBatteryCfm_tag {
  uint8_t  status;
  uint8_t  level;
} appBatteryCfm_t;

  // Type: gAspAppSetNotifyCfm_c
typedef struct appSetNotifyCfm_tag {
  uint8_t  status;
} appSetNotifyCfm_t;

  // Type: gAspAppSetMinDozeTimeCfm_c
typedef struct appSetMinDozeTimeCfm_tag {
  uint8_t  status;
} appSetMinDozeTimeCfm_t;

  // Type: gAspErrorCnf_c
typedef struct appErrorCfm_tag {
  uint8_t  status;
} appErrorCfm_t;


  // ASP to application message
typedef struct aspToAppMsg_tag {
  uint8_t msgType;
  union {
    appGetTimeCfm_t         appGetTimeCfm;
    appGetInactiveTimeCfm_t appGetInactiveTimeCfm;
    appDozeCfm_t            appDozeCfm;       
    appAutoDozeCfm_t        appAutoDozeCfm;   
    appHibernateCfm_t       appHibernateCfm;  
    appWakeCfm_t            appWakeCfm;       
    appEventCfm_t           appEventCfm;      
    appTrimCfm_t            appTrimCfm;       
    appDdrCfm_t             appDdrCfm;        
    appPortCfm_t            appPortCfm;       
    appClkoCfm_t            appClkoCfm;       
    appTempCfm_t            appTempCfm;       
    appNvRamCfm_t           appNvRamCfm;      
    appBatteryCfm_t         appBatteryCfm;    
    appSetNotifyCfm_t       appSetNotifyCfm;
    appSetMinDozeTimeCfm_t  appSetMinDozeTimeCfm;
    appErrorCfm_t           appErrorCfm;      
    appWakeInd_t            appWakeInd;
    appIdleInd_t            appIdleInd;
    appInactiveInd_t        appInactiveInd;
    appEventInd_t           appEventInd;
  } msgData;
} aspToAppMsg_t;

typedef aspToAppMsg_t memToAspMsg_t;

typedef union aspMsg_tag {
  uint8_t msgType;
  appToAspMsg_t appToAspMsg;
  aspToAppMsg_t aspToAppMsg;
} aspMsg_t;

/************************************************************************************
*************************************************************************************
* Public prototypes
*************************************************************************************
************************************************************************************/

/************************************************************************************
* ASP layer service access point for application requests.
*   
* Interface assumptions:
*   None
*   
* Return value:
*   Standard error code
* 
* Revision history:
*   date      Author    Comments
*   ------    ------    --------
*   170204    JEHOL1    Created
* 
************************************************************************************/
uint8_t APP_ASP_SapHandler
  (
  aspMsg_t *pMsg
  );

/************************************************************************************
* Application layer service access point for ASP indications.
*   
* Interface assumptions:
*   None
*   
* Return value:
*   Standard error code
* 
* Revision history:
*   date      Author    Comments
*   ------    ------    --------
*   170204    JEHOL1    Created
* 
************************************************************************************/
uint8_t ASP_APP_SapHandler
  (
  aspToAppMsg_t *pMsg
  );

#endif /* _APP_ASP_INTERFACE_H_ */
