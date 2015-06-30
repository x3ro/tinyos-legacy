/* $Id: HplAt32uc3bGeneralIOC.nc,v 1.5 2008/03/09 16:36:17 yuecelm Exp $ */

/**
 * HPL for the Atmel AT32UC3B microcontroller. This provides an
 * abstraction for general-purpose I/O.
 *
 * @author Mustafa Yuecel <mustafa.yuecel@alumni.ethz.ch>
 */

#include "at32uc3b_gpio.h"

configuration HplAt32uc3bGeneralIOC
{
  provides {
    interface HplAt32uc3bGeneralIO as Gpio0;
    interface HplAt32uc3bGeneralIO as Gpio1;
    interface HplAt32uc3bGeneralIO as Gpio2;
    interface HplAt32uc3bGeneralIO as Gpio3;
    interface HplAt32uc3bGeneralIO as Gpio4;
    interface HplAt32uc3bGeneralIO as Gpio5;
    interface HplAt32uc3bGeneralIO as Gpio6;
    interface HplAt32uc3bGeneralIO as Gpio7;
    interface HplAt32uc3bGeneralIO as Gpio8;
    interface HplAt32uc3bGeneralIO as Gpio9;
    interface HplAt32uc3bGeneralIO as Gpio10;
    interface HplAt32uc3bGeneralIO as Gpio11;
    interface HplAt32uc3bGeneralIO as Gpio12;
    interface HplAt32uc3bGeneralIO as Gpio13;
    interface HplAt32uc3bGeneralIO as Gpio14;
    interface HplAt32uc3bGeneralIO as Gpio15;
    interface HplAt32uc3bGeneralIO as Gpio16;
    interface HplAt32uc3bGeneralIO as Gpio17;
    interface HplAt32uc3bGeneralIO as Gpio18;
    interface HplAt32uc3bGeneralIO as Gpio19;
    interface HplAt32uc3bGeneralIO as Gpio20;
    interface HplAt32uc3bGeneralIO as Gpio21;
    interface HplAt32uc3bGeneralIO as Gpio22;
    interface HplAt32uc3bGeneralIO as Gpio23;
    interface HplAt32uc3bGeneralIO as Gpio24;
    interface HplAt32uc3bGeneralIO as Gpio25;
    interface HplAt32uc3bGeneralIO as Gpio26;
    interface HplAt32uc3bGeneralIO as Gpio27;
    interface HplAt32uc3bGeneralIO as Gpio28;
    interface HplAt32uc3bGeneralIO as Gpio29;
    interface HplAt32uc3bGeneralIO as Gpio30;
    interface HplAt32uc3bGeneralIO as Gpio31;
    interface HplAt32uc3bGeneralIO as Gpio32;
    interface HplAt32uc3bGeneralIO as Gpio33;
    interface HplAt32uc3bGeneralIO as Gpio34;
    interface HplAt32uc3bGeneralIO as Gpio35;
    interface HplAt32uc3bGeneralIO as Gpio36;
    interface HplAt32uc3bGeneralIO as Gpio37;
    interface HplAt32uc3bGeneralIO as Gpio38;
    interface HplAt32uc3bGeneralIO as Gpio39;
    interface HplAt32uc3bGeneralIO as Gpio40;
    interface HplAt32uc3bGeneralIO as Gpio41;
    interface HplAt32uc3bGeneralIO as Gpio42;
    interface HplAt32uc3bGeneralIO as Gpio43;
  }
}
implementation
{
  components
    new HplAt32uc3bGeneralIOP(0) as PA00,
    new HplAt32uc3bGeneralIOP(1) as PA01,
    new HplAt32uc3bGeneralIOP(2) as PA02,
    new HplAt32uc3bGeneralIOP(3) as PA03,
    new HplAt32uc3bGeneralIOP(4) as PA04,
    new HplAt32uc3bGeneralIOP(5) as PA05,
    new HplAt32uc3bGeneralIOP(6) as PA06,
    new HplAt32uc3bGeneralIOP(7) as PA07,
    new HplAt32uc3bGeneralIOP(8) as PA08,
    new HplAt32uc3bGeneralIOP(9) as PA09,
    new HplAt32uc3bGeneralIOP(10) as PA10,
    new HplAt32uc3bGeneralIOP(11) as PA11,
    new HplAt32uc3bGeneralIOP(12) as PA12,
    new HplAt32uc3bGeneralIOP(13) as PA13,
    new HplAt32uc3bGeneralIOP(14) as PA14,
    new HplAt32uc3bGeneralIOP(15) as PA15,
    new HplAt32uc3bGeneralIOP(16) as PA16,
    new HplAt32uc3bGeneralIOP(17) as PA17,
    new HplAt32uc3bGeneralIOP(18) as PA18,
    new HplAt32uc3bGeneralIOP(19) as PA19,
    new HplAt32uc3bGeneralIOP(20) as PA20,
    new HplAt32uc3bGeneralIOP(21) as PA21,
    new HplAt32uc3bGeneralIOP(22) as PA22,
    new HplAt32uc3bGeneralIOP(23) as PA23,
    new HplAt32uc3bGeneralIOP(24) as PA24,
    new HplAt32uc3bGeneralIOP(25) as PA25,
    new HplAt32uc3bGeneralIOP(26) as PA26,
    new HplAt32uc3bGeneralIOP(27) as PA27,
    new HplAt32uc3bGeneralIOP(28) as PA28,
    new HplAt32uc3bGeneralIOP(29) as PA29,
    new HplAt32uc3bGeneralIOP(30) as PA30,
    new HplAt32uc3bGeneralIOP(31) as PA31,
    new HplAt32uc3bGeneralIOP(32) as PB00,
    new HplAt32uc3bGeneralIOP(33) as PB01,
    new HplAt32uc3bGeneralIOP(34) as PB02,
    new HplAt32uc3bGeneralIOP(35) as PB03,
    new HplAt32uc3bGeneralIOP(36) as PB04,
    new HplAt32uc3bGeneralIOP(37) as PB05,
    new HplAt32uc3bGeneralIOP(38) as PB06,
    new HplAt32uc3bGeneralIOP(39) as PB07,
    new HplAt32uc3bGeneralIOP(40) as PB08,
    new HplAt32uc3bGeneralIOP(41) as PB09,
    new HplAt32uc3bGeneralIOP(42) as PB10,
    new HplAt32uc3bGeneralIOP(43) as PB11;

  Gpio0 = PA00;
  Gpio1 = PA01;
  Gpio2 = PA02;
  Gpio3 = PA03;
  Gpio4 = PA04;
  Gpio5 = PA05;
  Gpio6 = PA06;
  Gpio7 = PA07;
  Gpio8 = PA08;
  Gpio9 = PA09;
  Gpio10 = PA10;
  Gpio11 = PA11;
  Gpio12 = PA12;
  Gpio13 = PA13;
  Gpio14 = PA14;
  Gpio15 = PA15;
  Gpio16 = PA16;
  Gpio17 = PA17;
  Gpio18 = PA18;
  Gpio19 = PA19;
  Gpio20 = PA20;
  Gpio21 = PA21;
  Gpio22 = PA22;
  Gpio23 = PA23;
  Gpio24 = PA24;
  Gpio25 = PA25;
  Gpio26 = PA26;
  Gpio27 = PA27;
  Gpio28 = PA28;
  Gpio29 = PA29;
  Gpio30 = PA30;
  Gpio31 = PA31;
  Gpio32 = PB00;  
  Gpio33 = PB01;
  Gpio34 = PB02;
  Gpio35 = PB03;
  Gpio36 = PB04;
  Gpio37 = PB05;
  Gpio38 = PB06;
  Gpio39 = PB07;
  Gpio40 = PB08;
  Gpio41 = PB09;
  Gpio42 = PB10;
  Gpio43 = PB11;
}
