// $Id: HPLUART0C.nc,v 1.1.1.1 2005/12/15 22:40:29 cepett01 Exp $

/*									tab:4
 *
 * - Description ----------------------------------------------------------
 * Implementation of UART0 lowlevel functionality - stateless.
 * Modified from the original HPLUARTM.nc in the MSP430 platform
 * folder of the TinyOS environment
 * - Revision -------------------------------------------------------------
 * $Revision: 1.1.1.1 $
 * $Date: 2005/12/15 22:40:29 $
 * @author Chris Pettus 
 * ========================================================================
 */
 
configuration HPLUART0C {
  provides interface HPLUART as UART;
}
implementation
{
  components HPLUART0M as UARTCFGM, HPLUSART0M as HPLUSART;

  UART=UARTCFGM;

  UARTCFGM.USARTControl -> HPLUSART;
  UARTCFGM.USARTData -> HPLUSART;
}
