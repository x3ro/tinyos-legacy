/* 
 * Author:		Josh Herbach
 * Revision:	1.0
 * Date:		09/02/2005
 */
configuration TestUSBC {}
implementation {
  components 
    Main,
    BluSHC;
 
  Main.StdControl -> BluSHC;
}
