/*								tab:4
 * 
 * =============================================================================
 * 
 * Authors:  Su Ping
 *           Intel Research Berkeley Lab
 * Date:     7/11/2002
 *
 */
/** 
 * Module Name: TestBedSensor
 * 
 * Module description:
 *
 *  
 * Functionally, this is the same as nest/apps/generic_sensor
 * 
**/

configuration TestBedSensor { }

implementation {
  components Main, ExternalFunction, ExternalFunctionM,  OscopeC;

  Main.StdControl -> ExternalFunctionM;  
  Main.StdControl -> OscopeC;

}
