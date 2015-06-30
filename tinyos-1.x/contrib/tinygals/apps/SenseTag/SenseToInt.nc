// $Id: SenseToInt.nc,v 1.1 2004/04/14 06:43:20 celaine Exp $

/* Copyright (C) 2003-2004 Palo Alto Research Center
 *
 * The attached "TinyGALS" software is provided to you under the terms and
 * conditions of the GNU General Public License Version 2 as published by the
 * Free Software Foundation.
 *
 * TinyGALS is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with TinyGALS; see the file COPYING.  If not, write to
 * the Free Software Foundation, 59 Temple Place - Suite 330,
 * Boston, MA 02111-1307, USA.
 */

/*									tab:4
 * Author: Elaine Cheong <celaine @ users.sourceforge.net>
 * Date: 5 April 2004
 *
 * Based on $TOSROOT/tos/lib/Counters/SenseToInt.nc
 *
 */

/**
 * @author Elaine Cheong
 */

module SenseToInt {
  provides {
    interface StdControl;
    command result_t trigger();
  }
  uses {
    interface ADC;
    interface StdControl as ADCControl;
    interface IntOutput;
  }
}
implementation {
  command result_t StdControl.init() {
    call ADCControl.init();
    return SUCCESS;
  }

  command result_t StdControl.start() {
    return call ADCControl.start();
  }

  command result_t StdControl.stop() {
    return call ADCControl.stop();
  }

  command result_t trigger() {
    call ADC.getData();
    return SUCCESS;
  }
    
  async event result_t ADC.dataReady(uint16_t data) {
      uint16_t rCopy;
      atomic {
          rCopy = data;
      }
      return call IntOutput.output(rCopy >> 7);
  }

  event result_t IntOutput.outputComplete(result_t success) {
    return SUCCESS;
  }
}

