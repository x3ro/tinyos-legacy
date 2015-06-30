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
 
#ifndef MSG_TYPE_H
#define MSG_TYPE_H


  /**
   * @ingroup type
   * @brief notification parameters to be passed to ULLA through requestNotification()
   *
   */
  typedef struct RnDescr_t {
    uint16_t count;         /**< max number of notification to be reported by calling the handler. If zero,
				   the notification remains in force until explicitly canceled by cancelNotification().
				   Otherwise the notification is automatically canceled after "count" reports */
    uint16_t period;        /**< If this parameter is nonzero, the notification is periodic, and the value
				   of the parameter represents the time interval in milliseconds between two periodic
				   notifications. If the parameter is zero, the notification is event-driven. */
    ///handleNotification_t handler; /**< callback function provided by the application to be called by ULLA when
		///		   reporting events */
    void* privdata;             /**< private data that the application wants to be returned within the callback function */
		struct Query query;
		
  } RnDescr_t, *RnDescrPtr;
  
  
    /**
   * @ingroup type
   * @brief Parameters for asynchronous command call
   *
   * This structure contains parameter which are specific to the asynchronous command call through
   * requestCmd()
   *
   */
  typedef struct RcDescr_t
  {
    ///handleAsyncCmd_t handler;      /**< callback function privided by the Link User to be called upon
		//			   command completion */
    uint16_t count;         /**< The number of times the command must be issued. If zero,
				   the command call is repeated until explicitly canceled by cancelCmd().
				   Otherwise the command is automatically canceled after "count" reports */
    uint16_t period;        /**< The time interval in milliseconds between two commands. The first comand is
				   executed after the first period has elapsed. */
  } RcDescr_t, *RcDescrPtr;
  
  
   /**
   * @ingroup ucp
   * @brief Command Description
   *
   * This structure contains the name and parameters of the command to be issued by the link user
   * through requestCmd() or doCmd()
   */
  typedef struct CmdDescr_t
  {
    Id_t id;        /**< identifier of the link or link provider on which the command is to be executed */
    uint8_t class;        /**< the class (e.g. ullaLink, linkProvider, dot11Link) the command belongs to */
    uint8_t cmd;		/**< null-terminated string containing the command to be executed */
    uint8_t cmdArgLen;	/**< length of the cmdArg field in bytes */
    uint8_t* cmdArg;	/**< structure containing command arguments. How this is interpreted is command specific. */
  } CmdDescr_t, *CmdDescrPtr;
  
  typedef struct LpIf_t LpIf_t;



  /**
   * @ingroup type
   * @brief Identified an update request made through requestUpdate()
   *
   */
  typedef uint8_t RuId_t;


  /**
   * @ingroup type
   * @brief Link Provider information and methods
   *
   * This structure provides general information on the link provider, and also contains the
   * interface that the link provider must export to the ullaCore.
   *
   * @todo The method to load dynamically LP/Link attribute and command definitions
   * is still to be defined. It is still under discussion whether it can be enough to pass them
   * as a sequence of names and types in a string within the structure LpDescr_t (probably sufficient for attributes),
   * or whether a more complex representation should be used (which might be better to define command names and parameters).
   *
   */
  typedef struct LpDescr_t{
    char* version;       /**< Version of the ULLA this Link provider is compatible with */
    LpIf_t* lpIf;        /**< Pointer to link Provider interface struct */
  } LpDescr_t;




  /**
   * @ingroup type
   * @brief Request Update descriptor.
   *
   * Conveys information for issuing an update request through requestUpdate()
   *
   * @todo There is currently no way to specify the notification condition,
   * e.g. if the notification must be reported only on attribute change or also on exceeding some threshold.
   */
  typedef struct RuDescr_t{
    uint16_t count;  /**< The maxumum numner of times the request update notification fires. If set to zero
			      the request will stay in force until it is canceled by a cancelUpdate() call */
    uint32_t period;   /**< if a periodic notification was requested, this parameter indicates the reporting interval in ms. */
  } RuDescr_t;
   // for testing
	 
  typedef struct ullaLink_t {
    uint16_t link_id;
    uint16_t lp_id;
		uint8_t type;
    uint8_t state;
    uint8_t mode;
    uint8_t network_name;
		uint8_t rssi;
		uint8_t lqi;
  } ullaLink_t;
  
	typedef struct ullaLinkProvider_t {
    uint16_t lp_id;
    uint8_t foobar1;
    uint8_t foobar2;
    uint8_t foobar3;
  } ullaLinkProvider_t;
	
	typedef struct sensorMeter_t {
    uint16_t humidity;
    uint16_t temperature;
    uint16_t tsr;
    uint16_t par;
    uint16_t int_temperature;
    uint16_t int_voltage;
		uint16_t rf_power;
  } sensorMeter_t;
	
	typedef struct classList_t {
    ullaLink_t ulla;
    ullaLinkProvider_t lp;
    sensorMeter_t sm;
  } classList_t;
	
	typedef struct ResultTuple_t {
		uint8_t status;
		uint8_t attribute;
		uint8_t size;
		void *data;
	} ResultTuple_t;
	
	/*
	 * @rt: pointer to the headlist of ResultTuple_t of one link.
	 */
	typedef struct UllaResultTuple_t {
		ResultTuple_t *rt;
		struct UllaResultTuple_t *next;
	} UllaResultTuple_t;
	
#endif
