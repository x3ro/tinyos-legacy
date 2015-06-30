#ifndef ULLA_H
#define ULLA_H

/**
 * @file   ulla.h
 * @author Nicola Baldo
 * 
 * @brief  General definitions for the ULLA API
 * 
 * This header files contains definitions which are common
 * to both the Link User interface and the Link Provider interface.
 * This header file is automatically included when ullalu.h or 
 * ullalp.h are included.
 * 
 */
 
/**
 * @modified Krisakorn Rerkrai
 * @brief Modified version to work with TinyOS
 */


//#define IN
//#define OUT
//#define INOUT

 
  /**
   * @defgroup ucp ULLA Command Processing 
   */

 
  /**
   * @defgroup uqp ULLA Query Processing 
   */

  /**
   * @defgroup lu Link User 
   */


  /**
   * @defgroup lpfunc Link Provider
   */

  /** 
   * @defgroup uepfunc ULLA Event Processing
   */

  /**
   * @defgroup type Type Definitions
   */

  /**
   * @defgroup error Error Handling
   */ 

  /**
   * @ingroup type
   * @name Media Types
   *
   * @{
   */
#define ULLA_MEDIATYPE_UNKNOWN 1
#define ULLA_MEDIATYPE_80211   2
#define ULLA_MEDIATYPE_80211b  3
#define ULLA_MEDIATYPE_80211a  4
#define ULLA_MEDIATYPE_80211g  5
#define ULLA_MEDIATYPE_GPRS    6
#define ULLA_MEDIATYPE_UMTS    7
#define ULLA_MEDIATYPE_BLUETOOTH  8
#define ULLA_MEDIATYPE_ZIGBEE  9
#define ULLA_MEDIATYPE_IRDA    10
  /** @}  */



  /**
   * @ingroup type
   * @name Profiles
   *
   * @{
   */
#define ULLA_PROFILE_UNSPECIFIED 0
#define ULLA_PROFILE_BASE        1
#define ULLA_PROFILE_EXTENDED    2
#define ULLA_PROFILE_HIGH_END    3
  /** @}  */


  /**
   * @ingroup type
   * @brief Unique identifier used for links and link providers
   *
   * This identifier is determined by the ullaCore and is unique for both links and link providers. 
   * 
   */
  typedef uint16_t Id_t;
	typedef uint8_t ullaResult_t;
	
	
	typedef enum BaseType_t {
		ULLA_TYPE_UINT8 = 1,		/**< Unsigned char */
		ULLA_TYPE_INT8,  				/**< Char */
    ULLA_TYPE_UINT16,				/**< Unsigned short */
		ULLA_TYPE_INT16,				/**< Short */
    ULLA_TYPE_UINT32,				/**< Unsigned integer */
		ULLA_TYPE_INT32,				/**< Integer */
    ULLA_TYPE_RAWDATA,				/**< Raw data bytes */
	} BaseType_t;
	
  /**
   * @ingroup type  
   * @name Link Provider Attribute Qualifiers
   */
  typedef enum AttrQual_t{
    ULLA_QUAL_HARDCODED,    /**< Hard-coded value */
    ULLA_QUAL_THEORETICAL,  /**< Theoretical value */
    ULLA_QUAL_ESTIMATED,    /**< Estimated value */
    ULLA_QUAL_MEASURED,     /**< Measured value */
    ULLA_QUAL_EXACT         /**< Exact value */
  } AttrQual_t;



  /**
   * @ingroup type
   * @brief data structure for attribute value request/retrieval between the UEP and the LP
   * 
   * This data structure is used in two cases: 
   * - for the request and the retrieval of Link and Link Provider attributes 
   *   between the UEP and the LP, through getAttribute(), freeAttribute(), requestUpdate() and handleEvent()
   * - for the setting of link or link provider parameters through setParameter()
   *
   * Depending on which method the structure is passed to, the structure members act as an IN or as an OUT parameter. 
   */
  typedef struct AttrDescr_t{
    Id_t id;             /**< id of the Link or Link Provider for which the attribute is requested or reported. */
    uint8_t className;             /**< the name of the class the requested/reported attribute belongs to
			      * (e.g. ullaLink, linkProvider, dot11Link, etc.) 
			      */        //kre_modified
    uint8_t attribute;         /**< the name of the attribute  */  //kre_modified
    ////AttrQual_t qualifier; /**< the requested/reported qualifier of the attribute  */
    uint8_t type;                /**< the reported type of the attribute (ULLATYPE_INT, ULLATYPE_STRING...)  */
    uint8_t length;              /**< the length of the attribute in bytes. Used for types whose length is not known (e.g. ULLATYPE_STRING)
			      *
			      * @note the length field is mainly useful for strings which cannot be null-terminated, 
			      * for instance security keys, MAC addressed, LinkSignatures, etc. 
			      * Since the length field itself is unique, if multiple values are reported they must be 
			      * of the same length. This is OK when the attribute has a well-defined length 
			      * (e.g. a MAC address, or a MD5 hash), but problems may arise if a multiple-valued attribute needs
			      * a different length for each value.
			      */
    uint8_t numValues;           /**< how many values the attribute is composed of (this is to support multivalued attributes) */
    uint16_t *data;
		//void* data;
           /**< the pointer to the attribute value(s). 
			      * This pointer is supposed to be an array of the type indicated in the apposite field 
			      * (in other words, a pointer to data of the indicated type).
			      * The receiver of this data structure (the UC for getAttribute and handleNotification, 
			      * the LP for setAttribute() ) must explicitly cast the pointer to the appropriate type, 
			      * e.g.
			      * @code			      
                               switch(attr->type) {
				 case ULLATYPE_INT: 
				   { int* value = (int*) attr->data;
				     for (i=0; i<attr->numValues; i++)
				       printf("Value = %d",value[i]);
				   } break;
				 case ULLATYPE_STRING:
				   { char** value = (char**) attr->data;
				     sprintf(format,"Value = \%.%ds",attr->length);
				     for (i=0; i<attr->numValues; i++)
				       printf(format,value[i]);
				   } break;
			       case ULLATYPE_WHATEVER:
				 ...
			       }
			      * @endcode			      
			      */ 		      
  } AttrDescr_t;


 /*
   * @ingroup error
   * @name ULLA Core Error Codes
   *
   * All functions in the ULLA return an ullaResultCode indicating
   * the result of the function call. If the function succeeded, ULLA_OK is returned
   * otherwise the appropriate error code, defined hereafter.
   */  
  typedef enum ullaResultCode
    {
      /** Operation succesful   */
      ULLA_OK = 0,     
			
      /** Operation failed, general failure, no specific reason */
      ULLA_ERROR_FAILED,
			
      ULLA_ERROR_UNDEFINED,
			
      ULLA_ERROR_OUT_OF_MEMORY,
			
      /**  generic error in ULLA library, e.g. due to a bug */
      ULLA_ERROR_LIB,    
			
      /** generic error in ULLA Core, e.g. due to a bug */         
      ULLA_ERROR_CORE,
			
      /** generic error in ulla Storage system, e.g. in the internal database or in the external 
       * database implementation 
       */   
      ULLA_ERROR_STORAGE,
			
      /** ULLA API version mismatch  */
      ULLA_ERROR_API_VERSION_MISMATCH,
			
      /** Syntax error e.g. in the query string or in the commmand string */ 
      ULLA_ERROR_SYNTAX_ERROR,
			
      /** Invlaid class in the query string or in the commmand string */ 
      ULLA_ERROR_INVALID_CLASS,
			
      /** Invalid attribute in the query string or in the commmand string */ 
      ULLA_ERROR_INVALID_ATTRIBUTE,
			
      /** e.g. command not supported  */
      ULLA_ERROR_UNSUPPORTED_FEATURE,
			
      /** one or more of the function arameters is invalid  */
      ULLA_ERROR_INVALID_PARAMETER,
			
      /** the ullaResult_t identifier does not exist or has been already deallocated  */
      ULLA_ERROR_INVALID_ULLARESULT,
			
      /** non-existing field number or field name  */
      ULLA_ERROR_INVALID_FIELD,
			
      /** The link user has not registered yet */
      ULLA_ERROR_NOTREGISTERED,

      /** an error has occurred in the link provider while executing the function call  */
      ULLA_ERROR_LP_ERROR,
			
      /** e.g. the buffer space allocated by the linkUser was not sufficient  */
      ULLA_ERROR_BUFFER_TOO_SMALL,
			
      /** all tuples in a result set have already been processed */
      ULLA_ERROR_NO_MORE_TUPLES,
			
      /** this is returned when the linkUser is trying to access data within a result set without 
       * having called ullaNextTuple() at least once, or if the last call to ullaNextTuple() returned
       * ULLA_NO_MORE_TUPLES but the linkUser is trying to access data anyway.
       */
      ULLA_ERROR_NO_CURRENT_TUPLE,
			
      /**
       * the requested field cannot be converted to the requested value. 
       * E.g. ullaResultIntValue() is called on a string field.
       */
      ULLA_ERROR_TYPE_MISMATCH,
			
      /**
       * No more values are available for the current field.   
       * For an attribute field which contains N values, this error code is returned when 
       * a data access function (ullaResultIntValue(), ullaResultStringValue(), etc..)
       * is called more than N times.
       */
      ULLA_ERROR_NO_MORE_VALUES,
			
      /** The link provider ID does not exist or has already been unregistered */
      ULLA_ERROR_UNKNOWN_ID,
			
      /** The link user ID does not exist or has already been unregistered */
      ULLA_ERROR_INVALID_LUID,
			
      /** Returned upon a call to registerLu(), if the Link User requested support for a profile the 
       * ULLA Core does not support.
       */
      ULLA_ERROR_UNSUPPORTED_PROFILE,
			
      /** Returned upon a call to registerLu(), if the Link User requested a role the 
       * ULLA Core does not support.
       */
      ULLA_ERROR_UNSUPPORTED_ROLE,
      /** Returned upon a call to registerLu(), if the ULLA Core denies the requested role 
       */
      ULLA_ERROR_ROLE_DENIED,
			
      /** Returned upon ullaRegisterLm from an ULLA core that does not support external LM */
      ULLA_ERROR_LM_NOT_SUPPORTED,
			
      /** LM specific error codes: LM authorizes the operation */
      ULLA_AUTHORIZATION_OK,
			
      /** LM specific error codes: LM does not authorize the operation */
      ULLA_AUTHORIZATION_FAILED,
			
      /** LM specific error codes: LM authorizes has perfomed the requested operation */
      ULLA_OPERATION_PERFORMED,
			
      /** command can not be executed by link or linkprovider */
      ULLA_ERROR_INVALID_COMMAND,
			
      /** user is not allowed to execute the command */
      ULLA_ERROR_CMD_NOT_ALLOWED,

      /** user is not allowed to set the attribute */
      ULLA_ERROR_SETATTR_NOT_ALLOWED,
			
      /** user is not allowed to set the attribute */
      ULLA_ERROR_QUERY_NOT_ALLOWED,
			
      /** there is already a lock on the link or LP */
      ULLA_ERROR_ALREADY_LOCKED,
			
      /** ULLA Core or Link provider can not handle the requested period */
      ULLA_ERROR_PERIOD_TOO_SHORT,
			
      /** Invalid pointer to handler used */
      ULLA_ERROR_INVALID_HANDLER,
			
      /** Invalid notification ID */
      ULLA_ERROR_INVALID_NOTIFICATION,
			
      /** There is no known error to return the error string */
      ULLA_ERROR_NO_KNOWN_ERROR,
			
      /** Indicates that the LU is already registered when a subsequent request is made*/
      ULLA_ERROR_ALREADY_REGISTERED,
			
      /** Used in unmapChannel to indicate that there is no mapping set up for this relationship */
      ULLA_ERROR_NO_MAPPING,
			
      /** Used to indicate that a command (or other operation) has been timed out */
      ULLA_ERROR_TIMEOUT,
			
      /** The provided address can not be reached */
      ULLA_ERROR_DESTINATION_NOT_REACHABLE,
      
      /** Invalid qualifier being used */
      ULLA_ERROR_INVALID_QUALIFIER,
      
      /** Trying to set an invalid value */
      ULLA_ERROR_INVALID_VALUE,
      
      /** Trying to set multiple values for a single value attribute */
      ULLA_ERROR_SETATTR_NOTMULTIPLE,

	  /** Trying to set a read only value */
	  ULLA_ERROR_SETATTR_READONLY,
			
      ULLA_ERROR_MAX = 0x7fffffff
			
    } ullaResultCode;

 

  /**
   * @ingroup error
   * @name Link Provider Error Codes
   *
   * @{
   */


  /** A generic error descriptor. May signal
   * an error in the link provider implementation 
   */
#define LP_GENERIC_ERROR -101

  /** An error occured in the netowrk adpater's driver */
#define LP_DRIVER_ERROR -102               

/** Out of memory */
#define LP_OUT_OF_MEMORY_ERROR -103              

/** The specified attribute has not been recognised by the link provider */
#define LP_BAD_ATTRIBUTE_ERROR -104              

/** The specified ID does not exist */
#define LP_UNKNOWN_ID_ERROR -106            

 /** The supplied Request Update ID already exists */
#define LP_BAD_REQUEST_ID_ERROR -107            

 /** The ULLA version is not compatible to the one requested by the link provider */
#define LP_VERSION_MISMATCH_ERROR -108      

  /** The requested command has not been recognized by the link provider */
#define LP_BAD_COMMAND_ERROR -109    

  /** E.g. attribute or command known but unsupported */
#define LP_UNSUPPORTED_FEATURE_ERROR -110


  /** The LP is busy and cannot perform the requested operation*/
#define LP_BUSY_ERROR -112

  /** No error */
#define LP_OK 0                        


  /** @}  */


  /** 
   * @ingroup type
   * @name Attribute types
   * 
   * @{
   */

  /**
   * This type code refers to data of type "int"
   */ 
#define ULLA_TYPE_INT 1

  /** 
   * This type code refers to data of type "double"
   */ 
#define ULLA_TYPE_DOUBLE 2

  /** 
   * This type code refers to data of type "char*"
   */ 
#define ULLA_TYPE_STRING 3

  /** @}  */

#endif /* ULLA_H */

