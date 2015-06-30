/*
 * Copyright (c) 2007, RWTH Aachen University
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL RWTH AACHEN UNIVERSITY BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF RWTH AACHEN
 * UNIVERSITY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * RWTH AACHEN UNIVERSITY SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND RWTH AACHEN UNIVERSITY HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.
 *
 */
 
 /**
 * @author Krisakorn Rerkrai <kre@mobnets.rwth-aachen.de>
 **/
#ifndef LU_H
#define LU_H

/**
 *
<p>
 * @author Krisakorn Rerkrai <kre@mobnets.rwth-aachen.de>
 **/


  /**
   * @ingroup type
   * @brief  Link User identifier returned from the ULLA core to the Link User upon call to registerLu()
   *
   */
  typedef uint8_t LuId_t;
  
  /**
   * @ingroup type
   * @brief  Notification Request identifier returned from the ULLA core to the Link User upon call to requestNotification()
   *
   */
  typedef uint8_t RnId_t;
  
  /**
   * @ingroup type
   * @brief  Command request identifier returned from the ULLA core to the Link User upon call to requestCmd()
   *
   */
  typedef uint8_t CmdId_t;
  
   /**
   * @ingroup type
   * @brief Link User information.
   *
   * This is the data structure passed from the linkUser to the ullaCore upon registration with registerLu
   */
  typedef struct LuDescr_t{
    char* name; 	/**< Name of the Link User */
    char* description;  /**< Link User description (e.g. supplier, type of application, whatever) */
    char* version;	/**< Version of the ULLA we are willing to use */
    uint8_t profile;        /**< The requested profile type */
  }LuDescr_t;
  
    
#endif
