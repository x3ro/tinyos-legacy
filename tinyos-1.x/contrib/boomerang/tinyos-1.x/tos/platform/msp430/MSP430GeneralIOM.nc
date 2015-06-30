// $Id: MSP430GeneralIOM.nc,v 1.1.1.1 2007/11/05 19:10:15 jpolastre Exp $

/* "Copyright (c) 2000-2003 The Regents of the University of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement
 * is hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY
 * OF CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 */

// @author Cory Sharp <cssharp@eecs.berkeley.edu>

includes MSP430GeneralIO;

module MSP430GeneralIOM
{
  provides interface MSP430GeneralIO as Port10;
  provides interface MSP430GeneralIO as Port11;
  provides interface MSP430GeneralIO as Port12;
  provides interface MSP430GeneralIO as Port13;
  provides interface MSP430GeneralIO as Port14;
  provides interface MSP430GeneralIO as Port15;
  provides interface MSP430GeneralIO as Port16;
  provides interface MSP430GeneralIO as Port17;

  provides interface MSP430GeneralIO as Port20;
  provides interface MSP430GeneralIO as Port21;
  provides interface MSP430GeneralIO as Port22;
  provides interface MSP430GeneralIO as Port23;
  provides interface MSP430GeneralIO as Port24;
  provides interface MSP430GeneralIO as Port25;
  provides interface MSP430GeneralIO as Port26;
  provides interface MSP430GeneralIO as Port27;

  provides interface MSP430GeneralIO as Port30;
  provides interface MSP430GeneralIO as Port31;
  provides interface MSP430GeneralIO as Port32;
  provides interface MSP430GeneralIO as Port33;
  provides interface MSP430GeneralIO as Port34;
  provides interface MSP430GeneralIO as Port35;
  provides interface MSP430GeneralIO as Port36;
  provides interface MSP430GeneralIO as Port37;

  provides interface MSP430GeneralIO as Port40;
  provides interface MSP430GeneralIO as Port41;
  provides interface MSP430GeneralIO as Port42;
  provides interface MSP430GeneralIO as Port43;
  provides interface MSP430GeneralIO as Port44;
  provides interface MSP430GeneralIO as Port45;
  provides interface MSP430GeneralIO as Port46;
  provides interface MSP430GeneralIO as Port47;

  provides interface MSP430GeneralIO as Port50;
  provides interface MSP430GeneralIO as Port51;
  provides interface MSP430GeneralIO as Port52;
  provides interface MSP430GeneralIO as Port53;
  provides interface MSP430GeneralIO as Port54;
  provides interface MSP430GeneralIO as Port55;
  provides interface MSP430GeneralIO as Port56;
  provides interface MSP430GeneralIO as Port57;

  provides interface MSP430GeneralIO as Port60;
  provides interface MSP430GeneralIO as Port61;
  provides interface MSP430GeneralIO as Port62;
  provides interface MSP430GeneralIO as Port63;
  provides interface MSP430GeneralIO as Port64;
  provides interface MSP430GeneralIO as Port65;
  provides interface MSP430GeneralIO as Port66;
  provides interface MSP430GeneralIO as Port67;
}
implementation
{
  async command void Port10.setHigh() { TOSH_SET_PORT10_PIN(); }
  async command void Port10.setLow() { TOSH_CLR_PORT10_PIN(); }
  async command void Port10.toggle() { TOSH_TOGGLE_PORT10_PIN(); }
  async command uint8_t Port10.getRaw() { return TOSH_READ_PORT10_PIN(); }
  async command bool Port10.get() { return TOSH_READ_PORT10_PIN() != 0; }
  async command void Port10.makeInput() { TOSH_MAKE_PORT10_INPUT(); }
  async command void Port10.makeOutput() { TOSH_MAKE_PORT10_OUTPUT(); }
  async command void Port10.selectModuleFunc() { TOSH_SEL_PORT10_MODFUNC(); }
  async command void Port10.selectIOFunc() { TOSH_SEL_PORT10_IOFUNC(); }

  async command void Port11.setHigh() { TOSH_SET_PORT11_PIN(); }
  async command void Port11.setLow() { TOSH_CLR_PORT11_PIN(); }
  async command void Port11.toggle() { TOSH_TOGGLE_PORT11_PIN(); }
  async command uint8_t Port11.getRaw() { return TOSH_READ_PORT11_PIN(); }
  async command bool Port11.get() { return TOSH_READ_PORT11_PIN() != 0; }
  async command void Port11.makeInput() { TOSH_MAKE_PORT11_INPUT(); }
  async command void Port11.makeOutput() { TOSH_MAKE_PORT11_OUTPUT(); }
  async command void Port11.selectModuleFunc() { TOSH_SEL_PORT11_MODFUNC(); }
  async command void Port11.selectIOFunc() { TOSH_SEL_PORT11_IOFUNC(); }

  async command void Port12.setHigh() { TOSH_SET_PORT12_PIN(); }
  async command void Port12.setLow() { TOSH_CLR_PORT12_PIN(); }
  async command void Port12.toggle() { TOSH_TOGGLE_PORT12_PIN(); }
  async command uint8_t Port12.getRaw() { return TOSH_READ_PORT12_PIN(); }
  async command bool Port12.get() { return TOSH_READ_PORT12_PIN() != 0; }
  async command void Port12.makeInput() { TOSH_MAKE_PORT12_INPUT(); }
  async command void Port12.makeOutput() { TOSH_MAKE_PORT12_OUTPUT(); }
  async command void Port12.selectModuleFunc() { TOSH_SEL_PORT12_MODFUNC(); }
  async command void Port12.selectIOFunc() { TOSH_SEL_PORT12_IOFUNC(); }

  async command void Port13.setHigh() { TOSH_SET_PORT13_PIN(); }
  async command void Port13.setLow() { TOSH_CLR_PORT13_PIN(); }
  async command void Port13.toggle() { TOSH_TOGGLE_PORT13_PIN(); }
  async command uint8_t Port13.getRaw() { return TOSH_READ_PORT13_PIN(); }
  async command bool Port13.get() { return TOSH_READ_PORT13_PIN() != 0; }
  async command void Port13.makeInput() { TOSH_MAKE_PORT13_INPUT(); }
  async command void Port13.makeOutput() { TOSH_MAKE_PORT13_OUTPUT(); }
  async command void Port13.selectModuleFunc() { TOSH_SEL_PORT13_MODFUNC(); }
  async command void Port13.selectIOFunc() { TOSH_SEL_PORT13_IOFUNC(); }

  async command void Port14.setHigh() { TOSH_SET_PORT14_PIN(); }
  async command void Port14.setLow() { TOSH_CLR_PORT14_PIN(); }
  async command void Port14.toggle() { TOSH_TOGGLE_PORT14_PIN(); }
  async command uint8_t Port14.getRaw() { return TOSH_READ_PORT14_PIN(); }
  async command bool Port14.get() { return TOSH_READ_PORT14_PIN() != 0; }
  async command void Port14.makeInput() { TOSH_MAKE_PORT14_INPUT(); }
  async command void Port14.makeOutput() { TOSH_MAKE_PORT14_OUTPUT(); }
  async command void Port14.selectModuleFunc() { TOSH_SEL_PORT14_MODFUNC(); }
  async command void Port14.selectIOFunc() { TOSH_SEL_PORT14_IOFUNC(); }

  async command void Port15.setHigh() { TOSH_SET_PORT15_PIN(); }
  async command void Port15.setLow() { TOSH_CLR_PORT15_PIN(); }
  async command void Port15.toggle() { TOSH_TOGGLE_PORT15_PIN(); }
  async command uint8_t Port15.getRaw() { return TOSH_READ_PORT15_PIN(); }
  async command bool Port15.get() { return TOSH_READ_PORT15_PIN() != 0; }
  async command void Port15.makeInput() { TOSH_MAKE_PORT15_INPUT(); }
  async command void Port15.makeOutput() { TOSH_MAKE_PORT15_OUTPUT(); }
  async command void Port15.selectModuleFunc() { TOSH_SEL_PORT15_MODFUNC(); }
  async command void Port15.selectIOFunc() { TOSH_SEL_PORT15_IOFUNC(); }

  async command void Port16.setHigh() { TOSH_SET_PORT16_PIN(); }
  async command void Port16.setLow() { TOSH_CLR_PORT16_PIN(); }
  async command void Port16.toggle() { TOSH_TOGGLE_PORT16_PIN(); }
  async command uint8_t Port16.getRaw() { return TOSH_READ_PORT16_PIN(); }
  async command bool Port16.get() { return TOSH_READ_PORT16_PIN() != 0; }
  async command void Port16.makeInput() { TOSH_MAKE_PORT16_INPUT(); }
  async command void Port16.makeOutput() { TOSH_MAKE_PORT16_OUTPUT(); }
  async command void Port16.selectModuleFunc() { TOSH_SEL_PORT16_MODFUNC(); }
  async command void Port16.selectIOFunc() { TOSH_SEL_PORT16_IOFUNC(); }

  async command void Port17.setHigh() { TOSH_SET_PORT17_PIN(); }
  async command void Port17.setLow() { TOSH_CLR_PORT17_PIN(); }
  async command void Port17.toggle() { TOSH_TOGGLE_PORT17_PIN(); }
  async command uint8_t Port17.getRaw() { return TOSH_READ_PORT17_PIN(); }
  async command bool Port17.get() { return TOSH_READ_PORT17_PIN() != 0; }
  async command void Port17.makeInput() { TOSH_MAKE_PORT17_INPUT(); }
  async command void Port17.makeOutput() { TOSH_MAKE_PORT17_OUTPUT(); }
  async command void Port17.selectModuleFunc() { TOSH_SEL_PORT17_MODFUNC(); }
  async command void Port17.selectIOFunc() { TOSH_SEL_PORT17_IOFUNC(); }

  async command void Port20.setHigh() { TOSH_SET_PORT20_PIN(); }
  async command void Port20.setLow() { TOSH_CLR_PORT20_PIN(); }
  async command void Port20.toggle() { TOSH_TOGGLE_PORT20_PIN(); }
  async command uint8_t Port20.getRaw() { return TOSH_READ_PORT20_PIN(); }
  async command bool Port20.get() { return TOSH_READ_PORT20_PIN() != 0; }
  async command void Port20.makeInput() { TOSH_MAKE_PORT20_INPUT(); }
  async command void Port20.makeOutput() { TOSH_MAKE_PORT20_OUTPUT(); }
  async command void Port20.selectModuleFunc() { TOSH_SEL_PORT20_MODFUNC(); }
  async command void Port20.selectIOFunc() { TOSH_SEL_PORT20_IOFUNC(); }

  async command void Port21.setHigh() { TOSH_SET_PORT21_PIN(); }
  async command void Port21.setLow() { TOSH_CLR_PORT21_PIN(); }
  async command void Port21.toggle() { TOSH_TOGGLE_PORT21_PIN(); }
  async command uint8_t Port21.getRaw() { return TOSH_READ_PORT21_PIN(); }
  async command bool Port21.get() { return TOSH_READ_PORT21_PIN() != 0; }
  async command void Port21.makeInput() { TOSH_MAKE_PORT21_INPUT(); }
  async command void Port21.makeOutput() { TOSH_MAKE_PORT21_OUTPUT(); }
  async command void Port21.selectModuleFunc() { TOSH_SEL_PORT21_MODFUNC(); }
  async command void Port21.selectIOFunc() { TOSH_SEL_PORT21_IOFUNC(); }

  async command void Port22.setHigh() { TOSH_SET_PORT22_PIN(); }
  async command void Port22.setLow() { TOSH_CLR_PORT22_PIN(); }
  async command void Port22.toggle() { TOSH_TOGGLE_PORT22_PIN(); }
  async command uint8_t Port22.getRaw() { return TOSH_READ_PORT22_PIN(); }
  async command bool Port22.get() { return TOSH_READ_PORT22_PIN() != 0; }
  async command void Port22.makeInput() { TOSH_MAKE_PORT22_INPUT(); }
  async command void Port22.makeOutput() { TOSH_MAKE_PORT22_OUTPUT(); }
  async command void Port22.selectModuleFunc() { TOSH_SEL_PORT22_MODFUNC(); }
  async command void Port22.selectIOFunc() { TOSH_SEL_PORT22_IOFUNC(); }

  async command void Port23.setHigh() { TOSH_SET_PORT23_PIN(); }
  async command void Port23.setLow() { TOSH_CLR_PORT23_PIN(); }
  async command void Port23.toggle() { TOSH_TOGGLE_PORT23_PIN(); }
  async command uint8_t Port23.getRaw() { return TOSH_READ_PORT23_PIN(); }
  async command bool Port23.get() { return TOSH_READ_PORT23_PIN() != 0; }
  async command void Port23.makeInput() { TOSH_MAKE_PORT23_INPUT(); }
  async command void Port23.makeOutput() { TOSH_MAKE_PORT23_OUTPUT(); }
  async command void Port23.selectModuleFunc() { TOSH_SEL_PORT23_MODFUNC(); }
  async command void Port23.selectIOFunc() { TOSH_SEL_PORT23_IOFUNC(); }

  async command void Port24.setHigh() { TOSH_SET_PORT24_PIN(); }
  async command void Port24.setLow() { TOSH_CLR_PORT24_PIN(); }
  async command void Port24.toggle() { TOSH_TOGGLE_PORT24_PIN(); }
  async command uint8_t Port24.getRaw() { return TOSH_READ_PORT24_PIN(); }
  async command bool Port24.get() { return TOSH_READ_PORT24_PIN() != 0; }
  async command void Port24.makeInput() { TOSH_MAKE_PORT24_INPUT(); }
  async command void Port24.makeOutput() { TOSH_MAKE_PORT24_OUTPUT(); }
  async command void Port24.selectModuleFunc() { TOSH_SEL_PORT24_MODFUNC(); }
  async command void Port24.selectIOFunc() { TOSH_SEL_PORT24_IOFUNC(); }

  async command void Port25.setHigh() { TOSH_SET_PORT25_PIN(); }
  async command void Port25.setLow() { TOSH_CLR_PORT25_PIN(); }
  async command void Port25.toggle() { TOSH_TOGGLE_PORT25_PIN(); }
  async command uint8_t Port25.getRaw() { return TOSH_READ_PORT25_PIN(); }
  async command bool Port25.get() { return TOSH_READ_PORT25_PIN() != 0; }
  async command void Port25.makeInput() { TOSH_MAKE_PORT25_INPUT(); }
  async command void Port25.makeOutput() { TOSH_MAKE_PORT25_OUTPUT(); }
  async command void Port25.selectModuleFunc() { TOSH_SEL_PORT25_MODFUNC(); }
  async command void Port25.selectIOFunc() { TOSH_SEL_PORT25_IOFUNC(); }

  async command void Port26.setHigh() { TOSH_SET_PORT26_PIN(); }
  async command void Port26.setLow() { TOSH_CLR_PORT26_PIN(); }
  async command void Port26.toggle() { TOSH_TOGGLE_PORT26_PIN(); }
  async command uint8_t Port26.getRaw() { return TOSH_READ_PORT26_PIN(); }
  async command bool Port26.get() { return TOSH_READ_PORT26_PIN() != 0; }
  async command void Port26.makeInput() { TOSH_MAKE_PORT26_INPUT(); }
  async command void Port26.makeOutput() { TOSH_MAKE_PORT26_OUTPUT(); }
  async command void Port26.selectModuleFunc() { TOSH_SEL_PORT26_MODFUNC(); }
  async command void Port26.selectIOFunc() { TOSH_SEL_PORT26_IOFUNC(); }

  async command void Port27.setHigh() { TOSH_SET_PORT27_PIN(); }
  async command void Port27.setLow() { TOSH_CLR_PORT27_PIN(); }
  async command void Port27.toggle() { TOSH_TOGGLE_PORT27_PIN(); }
  async command uint8_t Port27.getRaw() { return TOSH_READ_PORT27_PIN(); }
  async command bool Port27.get() { return TOSH_READ_PORT27_PIN() != 0; }
  async command void Port27.makeInput() { TOSH_MAKE_PORT27_INPUT(); }
  async command void Port27.makeOutput() { TOSH_MAKE_PORT27_OUTPUT(); }
  async command void Port27.selectModuleFunc() { TOSH_SEL_PORT27_MODFUNC(); }
  async command void Port27.selectIOFunc() { TOSH_SEL_PORT27_IOFUNC(); }

  async command void Port30.setHigh() { TOSH_SET_PORT30_PIN(); }
  async command void Port30.setLow() { TOSH_CLR_PORT30_PIN(); }
  async command void Port30.toggle() { TOSH_TOGGLE_PORT30_PIN(); }
  async command uint8_t Port30.getRaw() { return TOSH_READ_PORT30_PIN(); }
  async command bool Port30.get() { return TOSH_READ_PORT30_PIN() != 0; }
  async command void Port30.makeInput() { TOSH_MAKE_PORT30_INPUT(); }
  async command void Port30.makeOutput() { TOSH_MAKE_PORT30_OUTPUT(); }
  async command void Port30.selectModuleFunc() { TOSH_SEL_PORT30_MODFUNC(); }
  async command void Port30.selectIOFunc() { TOSH_SEL_PORT30_IOFUNC(); }

  async command void Port31.setHigh() { TOSH_SET_PORT31_PIN(); }
  async command void Port31.setLow() { TOSH_CLR_PORT31_PIN(); }
  async command void Port31.toggle() { TOSH_TOGGLE_PORT31_PIN(); }
  async command uint8_t Port31.getRaw() { return TOSH_READ_PORT31_PIN(); }
  async command bool Port31.get() { return TOSH_READ_PORT31_PIN() != 0; }
  async command void Port31.makeInput() { TOSH_MAKE_PORT31_INPUT(); }
  async command void Port31.makeOutput() { TOSH_MAKE_PORT31_OUTPUT(); }
  async command void Port31.selectModuleFunc() { TOSH_SEL_PORT31_MODFUNC(); }
  async command void Port31.selectIOFunc() { TOSH_SEL_PORT31_IOFUNC(); }

  async command void Port32.setHigh() { TOSH_SET_PORT32_PIN(); }
  async command void Port32.setLow() { TOSH_CLR_PORT32_PIN(); }
  async command void Port32.toggle() { TOSH_TOGGLE_PORT32_PIN(); }
  async command uint8_t Port32.getRaw() { return TOSH_READ_PORT32_PIN(); }
  async command bool Port32.get() { return TOSH_READ_PORT32_PIN() != 0; }
  async command void Port32.makeInput() { TOSH_MAKE_PORT32_INPUT(); }
  async command void Port32.makeOutput() { TOSH_MAKE_PORT32_OUTPUT(); }
  async command void Port32.selectModuleFunc() { TOSH_SEL_PORT32_MODFUNC(); }
  async command void Port32.selectIOFunc() { TOSH_SEL_PORT32_IOFUNC(); }

  async command void Port33.setHigh() { TOSH_SET_PORT33_PIN(); }
  async command void Port33.setLow() { TOSH_CLR_PORT33_PIN(); }
  async command void Port33.toggle() { TOSH_TOGGLE_PORT33_PIN(); }
  async command uint8_t Port33.getRaw() { return TOSH_READ_PORT33_PIN(); }
  async command bool Port33.get() { return TOSH_READ_PORT33_PIN() != 0; }
  async command void Port33.makeInput() { TOSH_MAKE_PORT33_INPUT(); }
  async command void Port33.makeOutput() { TOSH_MAKE_PORT33_OUTPUT(); }
  async command void Port33.selectModuleFunc() { TOSH_SEL_PORT33_MODFUNC(); }
  async command void Port33.selectIOFunc() { TOSH_SEL_PORT33_IOFUNC(); }

  async command void Port34.setHigh() { TOSH_SET_PORT34_PIN(); }
  async command void Port34.setLow() { TOSH_CLR_PORT34_PIN(); }
  async command void Port34.toggle() { TOSH_TOGGLE_PORT34_PIN(); }
  async command uint8_t Port34.getRaw() { return TOSH_READ_PORT34_PIN(); }
  async command bool Port34.get() { return TOSH_READ_PORT34_PIN() != 0; }
  async command void Port34.makeInput() { TOSH_MAKE_PORT34_INPUT(); }
  async command void Port34.makeOutput() { TOSH_MAKE_PORT34_OUTPUT(); }
  async command void Port34.selectModuleFunc() { TOSH_SEL_PORT34_MODFUNC(); }
  async command void Port34.selectIOFunc() { TOSH_SEL_PORT34_IOFUNC(); }

  async command void Port35.setHigh() { TOSH_SET_PORT35_PIN(); }
  async command void Port35.setLow() { TOSH_CLR_PORT35_PIN(); }
  async command void Port35.toggle() { TOSH_TOGGLE_PORT35_PIN(); }
  async command uint8_t Port35.getRaw() { return TOSH_READ_PORT35_PIN(); }
  async command bool Port35.get() { return TOSH_READ_PORT35_PIN() != 0; }
  async command void Port35.makeInput() { TOSH_MAKE_PORT35_INPUT(); }
  async command void Port35.makeOutput() { TOSH_MAKE_PORT35_OUTPUT(); }
  async command void Port35.selectModuleFunc() { TOSH_SEL_PORT35_MODFUNC(); }
  async command void Port35.selectIOFunc() { TOSH_SEL_PORT35_IOFUNC(); }

  async command void Port36.setHigh() { TOSH_SET_PORT36_PIN(); }
  async command void Port36.setLow() { TOSH_CLR_PORT36_PIN(); }
  async command void Port36.toggle() { TOSH_TOGGLE_PORT36_PIN(); }
  async command uint8_t Port36.getRaw() { return TOSH_READ_PORT36_PIN(); }
  async command bool Port36.get() { return TOSH_READ_PORT36_PIN() != 0; }
  async command void Port36.makeInput() { TOSH_MAKE_PORT36_INPUT(); }
  async command void Port36.makeOutput() { TOSH_MAKE_PORT36_OUTPUT(); }
  async command void Port36.selectModuleFunc() { TOSH_SEL_PORT36_MODFUNC(); }
  async command void Port36.selectIOFunc() { TOSH_SEL_PORT36_IOFUNC(); }

  async command void Port37.setHigh() { TOSH_SET_PORT37_PIN(); }
  async command void Port37.setLow() { TOSH_CLR_PORT37_PIN(); }
  async command void Port37.toggle() { TOSH_TOGGLE_PORT37_PIN(); }
  async command uint8_t Port37.getRaw() { return TOSH_READ_PORT37_PIN(); }
  async command bool Port37.get() { return TOSH_READ_PORT37_PIN() != 0; }
  async command void Port37.makeInput() { TOSH_MAKE_PORT37_INPUT(); }
  async command void Port37.makeOutput() { TOSH_MAKE_PORT37_OUTPUT(); }
  async command void Port37.selectModuleFunc() { TOSH_SEL_PORT37_MODFUNC(); }
  async command void Port37.selectIOFunc() { TOSH_SEL_PORT37_IOFUNC(); }

  async command void Port40.setHigh() { TOSH_SET_PORT40_PIN(); }
  async command void Port40.setLow() { TOSH_CLR_PORT40_PIN(); }
  async command void Port40.toggle() { TOSH_TOGGLE_PORT40_PIN(); }
  async command uint8_t Port40.getRaw() { return TOSH_READ_PORT40_PIN(); }
  async command bool Port40.get() { return TOSH_READ_PORT40_PIN() != 0; }
  async command void Port40.makeInput() { TOSH_MAKE_PORT40_INPUT(); }
  async command void Port40.makeOutput() { TOSH_MAKE_PORT40_OUTPUT(); }
  async command void Port40.selectModuleFunc() { TOSH_SEL_PORT40_MODFUNC(); }
  async command void Port40.selectIOFunc() { TOSH_SEL_PORT40_IOFUNC(); }

  async command void Port41.setHigh() { TOSH_SET_PORT41_PIN(); }
  async command void Port41.setLow() { TOSH_CLR_PORT41_PIN(); }
  async command void Port41.toggle() { TOSH_TOGGLE_PORT41_PIN(); }
  async command uint8_t Port41.getRaw() { return TOSH_READ_PORT41_PIN(); }
  async command bool Port41.get() { return TOSH_READ_PORT41_PIN() != 0; }
  async command void Port41.makeInput() { TOSH_MAKE_PORT41_INPUT(); }
  async command void Port41.makeOutput() { TOSH_MAKE_PORT41_OUTPUT(); }
  async command void Port41.selectModuleFunc() { TOSH_SEL_PORT41_MODFUNC(); }
  async command void Port41.selectIOFunc() { TOSH_SEL_PORT41_IOFUNC(); }

  async command void Port42.setHigh() { TOSH_SET_PORT42_PIN(); }
  async command void Port42.setLow() { TOSH_CLR_PORT42_PIN(); }
  async command void Port42.toggle() { TOSH_TOGGLE_PORT42_PIN(); }
  async command uint8_t Port42.getRaw() { return TOSH_READ_PORT42_PIN(); }
  async command bool Port42.get() { return TOSH_READ_PORT42_PIN() != 0; }
  async command void Port42.makeInput() { TOSH_MAKE_PORT42_INPUT(); }
  async command void Port42.makeOutput() { TOSH_MAKE_PORT42_OUTPUT(); }
  async command void Port42.selectModuleFunc() { TOSH_SEL_PORT42_MODFUNC(); }
  async command void Port42.selectIOFunc() { TOSH_SEL_PORT42_IOFUNC(); }

  async command void Port43.setHigh() { TOSH_SET_PORT43_PIN(); }
  async command void Port43.setLow() { TOSH_CLR_PORT43_PIN(); }
  async command void Port43.toggle() { TOSH_TOGGLE_PORT43_PIN(); }
  async command uint8_t Port43.getRaw() { return TOSH_READ_PORT43_PIN(); }
  async command bool Port43.get() { return TOSH_READ_PORT43_PIN() != 0; }
  async command void Port43.makeInput() { TOSH_MAKE_PORT43_INPUT(); }
  async command void Port43.makeOutput() { TOSH_MAKE_PORT43_OUTPUT(); }
  async command void Port43.selectModuleFunc() { TOSH_SEL_PORT43_MODFUNC(); }
  async command void Port43.selectIOFunc() { TOSH_SEL_PORT43_IOFUNC(); }

  async command void Port44.setHigh() { TOSH_SET_PORT44_PIN(); }
  async command void Port44.setLow() { TOSH_CLR_PORT44_PIN(); }
  async command void Port44.toggle() { TOSH_TOGGLE_PORT44_PIN(); }
  async command uint8_t Port44.getRaw() { return TOSH_READ_PORT44_PIN(); }
  async command bool Port44.get() { return TOSH_READ_PORT44_PIN() != 0; }
  async command void Port44.makeInput() { TOSH_MAKE_PORT44_INPUT(); }
  async command void Port44.makeOutput() { TOSH_MAKE_PORT44_OUTPUT(); }
  async command void Port44.selectModuleFunc() { TOSH_SEL_PORT44_MODFUNC(); }
  async command void Port44.selectIOFunc() { TOSH_SEL_PORT44_IOFUNC(); }

  async command void Port45.setHigh() { TOSH_SET_PORT45_PIN(); }
  async command void Port45.setLow() { TOSH_CLR_PORT45_PIN(); }
  async command void Port45.toggle() { TOSH_TOGGLE_PORT45_PIN(); }
  async command uint8_t Port45.getRaw() { return TOSH_READ_PORT45_PIN(); }
  async command bool Port45.get() { return TOSH_READ_PORT45_PIN() != 0; }
  async command void Port45.makeInput() { TOSH_MAKE_PORT45_INPUT(); }
  async command void Port45.makeOutput() { TOSH_MAKE_PORT45_OUTPUT(); }
  async command void Port45.selectModuleFunc() { TOSH_SEL_PORT45_MODFUNC(); }
  async command void Port45.selectIOFunc() { TOSH_SEL_PORT45_IOFUNC(); }

  async command void Port46.setHigh() { TOSH_SET_PORT46_PIN(); }
  async command void Port46.setLow() { TOSH_CLR_PORT46_PIN(); }
  async command void Port46.toggle() { TOSH_TOGGLE_PORT46_PIN(); }
  async command uint8_t Port46.getRaw() { return TOSH_READ_PORT46_PIN(); }
  async command bool Port46.get() { return TOSH_READ_PORT46_PIN() != 0; }
  async command void Port46.makeInput() { TOSH_MAKE_PORT46_INPUT(); }
  async command void Port46.makeOutput() { TOSH_MAKE_PORT46_OUTPUT(); }
  async command void Port46.selectModuleFunc() { TOSH_SEL_PORT46_MODFUNC(); }
  async command void Port46.selectIOFunc() { TOSH_SEL_PORT46_IOFUNC(); }

  async command void Port47.setHigh() { TOSH_SET_PORT47_PIN(); }
  async command void Port47.setLow() { TOSH_CLR_PORT47_PIN(); }
  async command void Port47.toggle() { TOSH_TOGGLE_PORT47_PIN(); }
  async command uint8_t Port47.getRaw() { return TOSH_READ_PORT47_PIN(); }
  async command bool Port47.get() { return TOSH_READ_PORT47_PIN() != 0; }
  async command void Port47.makeInput() { TOSH_MAKE_PORT47_INPUT(); }
  async command void Port47.makeOutput() { TOSH_MAKE_PORT47_OUTPUT(); }
  async command void Port47.selectModuleFunc() { TOSH_SEL_PORT47_MODFUNC(); }
  async command void Port47.selectIOFunc() { TOSH_SEL_PORT47_IOFUNC(); }

  async command void Port50.setHigh() { TOSH_SET_PORT50_PIN(); }
  async command void Port50.setLow() { TOSH_CLR_PORT50_PIN(); }
  async command void Port50.toggle() { TOSH_TOGGLE_PORT50_PIN(); }
  async command uint8_t Port50.getRaw() { return TOSH_READ_PORT50_PIN(); }
  async command bool Port50.get() { return TOSH_READ_PORT50_PIN() != 0; }
  async command void Port50.makeInput() { TOSH_MAKE_PORT50_INPUT(); }
  async command void Port50.makeOutput() { TOSH_MAKE_PORT50_OUTPUT(); }
  async command void Port50.selectModuleFunc() { TOSH_SEL_PORT50_MODFUNC(); }
  async command void Port50.selectIOFunc() { TOSH_SEL_PORT50_IOFUNC(); }

  async command void Port51.setHigh() { TOSH_SET_PORT51_PIN(); }
  async command void Port51.setLow() { TOSH_CLR_PORT51_PIN(); }
  async command void Port51.toggle() { TOSH_TOGGLE_PORT51_PIN(); }
  async command uint8_t Port51.getRaw() { return TOSH_READ_PORT51_PIN(); }
  async command bool Port51.get() { return TOSH_READ_PORT51_PIN() != 0; }
  async command void Port51.makeInput() { TOSH_MAKE_PORT51_INPUT(); }
  async command void Port51.makeOutput() { TOSH_MAKE_PORT51_OUTPUT(); }
  async command void Port51.selectModuleFunc() { TOSH_SEL_PORT51_MODFUNC(); }
  async command void Port51.selectIOFunc() { TOSH_SEL_PORT51_IOFUNC(); }

  async command void Port52.setHigh() { TOSH_SET_PORT52_PIN(); }
  async command void Port52.setLow() { TOSH_CLR_PORT52_PIN(); }
  async command void Port52.toggle() { TOSH_TOGGLE_PORT52_PIN(); }
  async command uint8_t Port52.getRaw() { return TOSH_READ_PORT52_PIN(); }
  async command bool Port52.get() { return TOSH_READ_PORT52_PIN() != 0; }
  async command void Port52.makeInput() { TOSH_MAKE_PORT52_INPUT(); }
  async command void Port52.makeOutput() { TOSH_MAKE_PORT52_OUTPUT(); }
  async command void Port52.selectModuleFunc() { TOSH_SEL_PORT52_MODFUNC(); }
  async command void Port52.selectIOFunc() { TOSH_SEL_PORT52_IOFUNC(); }

  async command void Port53.setHigh() { TOSH_SET_PORT53_PIN(); }
  async command void Port53.setLow() { TOSH_CLR_PORT53_PIN(); }
  async command void Port53.toggle() { TOSH_TOGGLE_PORT53_PIN(); }
  async command uint8_t Port53.getRaw() { return TOSH_READ_PORT53_PIN(); }
  async command bool Port53.get() { return TOSH_READ_PORT53_PIN() != 0; }
  async command void Port53.makeInput() { TOSH_MAKE_PORT53_INPUT(); }
  async command void Port53.makeOutput() { TOSH_MAKE_PORT53_OUTPUT(); }
  async command void Port53.selectModuleFunc() { TOSH_SEL_PORT53_MODFUNC(); }
  async command void Port53.selectIOFunc() { TOSH_SEL_PORT53_IOFUNC(); }

  async command void Port54.setHigh() { TOSH_SET_PORT54_PIN(); }
  async command void Port54.setLow() { TOSH_CLR_PORT54_PIN(); }
  async command void Port54.toggle() { TOSH_TOGGLE_PORT54_PIN(); }
  async command uint8_t Port54.getRaw() { return TOSH_READ_PORT54_PIN(); }
  async command bool Port54.get() { return TOSH_READ_PORT54_PIN() != 0; }
  async command void Port54.makeInput() { TOSH_MAKE_PORT54_INPUT(); }
  async command void Port54.makeOutput() { TOSH_MAKE_PORT54_OUTPUT(); }
  async command void Port54.selectModuleFunc() { TOSH_SEL_PORT54_MODFUNC(); }
  async command void Port54.selectIOFunc() { TOSH_SEL_PORT54_IOFUNC(); }

  async command void Port55.setHigh() { TOSH_SET_PORT55_PIN(); }
  async command void Port55.setLow() { TOSH_CLR_PORT55_PIN(); }
  async command void Port55.toggle() { TOSH_TOGGLE_PORT55_PIN(); }
  async command uint8_t Port55.getRaw() { return TOSH_READ_PORT55_PIN(); }
  async command bool Port55.get() { return TOSH_READ_PORT55_PIN() != 0; }
  async command void Port55.makeInput() { TOSH_MAKE_PORT55_INPUT(); }
  async command void Port55.makeOutput() { TOSH_MAKE_PORT55_OUTPUT(); }
  async command void Port55.selectModuleFunc() { TOSH_SEL_PORT55_MODFUNC(); }
  async command void Port55.selectIOFunc() { TOSH_SEL_PORT55_IOFUNC(); }

  async command void Port56.setHigh() { TOSH_SET_PORT56_PIN(); }
  async command void Port56.setLow() { TOSH_CLR_PORT56_PIN(); }
  async command void Port56.toggle() { TOSH_TOGGLE_PORT56_PIN(); }
  async command uint8_t Port56.getRaw() { return TOSH_READ_PORT56_PIN(); }
  async command bool Port56.get() { return TOSH_READ_PORT56_PIN() != 0; }
  async command void Port56.makeInput() { TOSH_MAKE_PORT56_INPUT(); }
  async command void Port56.makeOutput() { TOSH_MAKE_PORT56_OUTPUT(); }
  async command void Port56.selectModuleFunc() { TOSH_SEL_PORT56_MODFUNC(); }
  async command void Port56.selectIOFunc() { TOSH_SEL_PORT56_IOFUNC(); }

  async command void Port57.setHigh() { TOSH_SET_PORT57_PIN(); }
  async command void Port57.setLow() { TOSH_CLR_PORT57_PIN(); }
  async command void Port57.toggle() { TOSH_TOGGLE_PORT57_PIN(); }
  async command uint8_t Port57.getRaw() { return TOSH_READ_PORT57_PIN(); }
  async command bool Port57.get() { return TOSH_READ_PORT57_PIN() != 0; }
  async command void Port57.makeInput() { TOSH_MAKE_PORT57_INPUT(); }
  async command void Port57.makeOutput() { TOSH_MAKE_PORT57_OUTPUT(); }
  async command void Port57.selectModuleFunc() { TOSH_SEL_PORT57_MODFUNC(); }
  async command void Port57.selectIOFunc() { TOSH_SEL_PORT57_IOFUNC(); }

  async command void Port60.setHigh() { TOSH_SET_PORT60_PIN(); }
  async command void Port60.setLow() { TOSH_CLR_PORT60_PIN(); }
  async command void Port60.toggle() { TOSH_TOGGLE_PORT60_PIN(); }
  async command uint8_t Port60.getRaw() { return TOSH_READ_PORT60_PIN(); }
  async command bool Port60.get() { return TOSH_READ_PORT60_PIN() != 0; }
  async command void Port60.makeInput() { TOSH_MAKE_PORT60_INPUT(); }
  async command void Port60.makeOutput() { TOSH_MAKE_PORT60_OUTPUT(); }
  async command void Port60.selectModuleFunc() { TOSH_SEL_PORT60_MODFUNC(); }
  async command void Port60.selectIOFunc() { TOSH_SEL_PORT60_IOFUNC(); }

  async command void Port61.setHigh() { TOSH_SET_PORT61_PIN(); }
  async command void Port61.setLow() { TOSH_CLR_PORT61_PIN(); }
  async command void Port61.toggle() { TOSH_TOGGLE_PORT61_PIN(); }
  async command uint8_t Port61.getRaw() { return TOSH_READ_PORT61_PIN(); }
  async command bool Port61.get() { return TOSH_READ_PORT61_PIN() != 0; }
  async command void Port61.makeInput() { TOSH_MAKE_PORT61_INPUT(); }
  async command void Port61.makeOutput() { TOSH_MAKE_PORT61_OUTPUT(); }
  async command void Port61.selectModuleFunc() { TOSH_SEL_PORT61_MODFUNC(); }
  async command void Port61.selectIOFunc() { TOSH_SEL_PORT61_IOFUNC(); }

  async command void Port62.setHigh() { TOSH_SET_PORT62_PIN(); }
  async command void Port62.setLow() { TOSH_CLR_PORT62_PIN(); }
  async command void Port62.toggle() { TOSH_TOGGLE_PORT62_PIN(); }
  async command uint8_t Port62.getRaw() { return TOSH_READ_PORT62_PIN(); }
  async command bool Port62.get() { return TOSH_READ_PORT62_PIN() != 0; }
  async command void Port62.makeInput() { TOSH_MAKE_PORT62_INPUT(); }
  async command void Port62.makeOutput() { TOSH_MAKE_PORT62_OUTPUT(); }
  async command void Port62.selectModuleFunc() { TOSH_SEL_PORT62_MODFUNC(); }
  async command void Port62.selectIOFunc() { TOSH_SEL_PORT62_IOFUNC(); }

  async command void Port63.setHigh() { TOSH_SET_PORT63_PIN(); }
  async command void Port63.setLow() { TOSH_CLR_PORT63_PIN(); }
  async command void Port63.toggle() { TOSH_TOGGLE_PORT63_PIN(); }
  async command uint8_t Port63.getRaw() { return TOSH_READ_PORT63_PIN(); }
  async command bool Port63.get() { return TOSH_READ_PORT63_PIN() != 0; }
  async command void Port63.makeInput() { TOSH_MAKE_PORT63_INPUT(); }
  async command void Port63.makeOutput() { TOSH_MAKE_PORT63_OUTPUT(); }
  async command void Port63.selectModuleFunc() { TOSH_SEL_PORT63_MODFUNC(); }
  async command void Port63.selectIOFunc() { TOSH_SEL_PORT63_IOFUNC(); }

  async command void Port64.setHigh() { TOSH_SET_PORT64_PIN(); }
  async command void Port64.setLow() { TOSH_CLR_PORT64_PIN(); }
  async command void Port64.toggle() { TOSH_TOGGLE_PORT64_PIN(); }
  async command uint8_t Port64.getRaw() { return TOSH_READ_PORT64_PIN(); }
  async command bool Port64.get() { return TOSH_READ_PORT64_PIN() != 0; }
  async command void Port64.makeInput() { TOSH_MAKE_PORT64_INPUT(); }
  async command void Port64.makeOutput() { TOSH_MAKE_PORT64_OUTPUT(); }
  async command void Port64.selectModuleFunc() { TOSH_SEL_PORT64_MODFUNC(); }
  async command void Port64.selectIOFunc() { TOSH_SEL_PORT64_IOFUNC(); }

  async command void Port65.setHigh() { TOSH_SET_PORT65_PIN(); }
  async command void Port65.setLow() { TOSH_CLR_PORT65_PIN(); }
  async command void Port65.toggle() { TOSH_TOGGLE_PORT65_PIN(); }
  async command uint8_t Port65.getRaw() { return TOSH_READ_PORT65_PIN(); }
  async command bool Port65.get() { return TOSH_READ_PORT65_PIN() != 0; }
  async command void Port65.makeInput() { TOSH_MAKE_PORT65_INPUT(); }
  async command void Port65.makeOutput() { TOSH_MAKE_PORT65_OUTPUT(); }
  async command void Port65.selectModuleFunc() { TOSH_SEL_PORT65_MODFUNC(); }
  async command void Port65.selectIOFunc() { TOSH_SEL_PORT65_IOFUNC(); }

  async command void Port66.setHigh() { TOSH_SET_PORT66_PIN(); }
  async command void Port66.setLow() { TOSH_CLR_PORT66_PIN(); }
  async command void Port66.toggle() { TOSH_TOGGLE_PORT66_PIN(); }
  async command uint8_t Port66.getRaw() { return TOSH_READ_PORT66_PIN(); }
  async command bool Port66.get() { return TOSH_READ_PORT66_PIN() != 0; }
  async command void Port66.makeInput() { TOSH_MAKE_PORT66_INPUT(); }
  async command void Port66.makeOutput() { TOSH_MAKE_PORT66_OUTPUT(); }
  async command void Port66.selectModuleFunc() { TOSH_SEL_PORT66_MODFUNC(); }
  async command void Port66.selectIOFunc() { TOSH_SEL_PORT66_IOFUNC(); }

  async command void Port67.setHigh() { TOSH_SET_PORT67_PIN(); }
  async command void Port67.setLow() { TOSH_CLR_PORT67_PIN(); }
  async command void Port67.toggle() { TOSH_TOGGLE_PORT67_PIN(); }
  async command uint8_t Port67.getRaw() { return TOSH_READ_PORT67_PIN(); }
  async command bool Port67.get() { return TOSH_READ_PORT67_PIN() != 0; }
  async command void Port67.makeInput() { TOSH_MAKE_PORT67_INPUT(); }
  async command void Port67.makeOutput() { TOSH_MAKE_PORT67_OUTPUT(); }
  async command void Port67.selectModuleFunc() { TOSH_SEL_PORT67_MODFUNC(); }
  async command void Port67.selectIOFunc() { TOSH_SEL_PORT67_IOFUNC(); }
}

