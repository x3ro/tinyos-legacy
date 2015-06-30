// $Id: SenseToInt.nc,v 1.1 2004/03/29 21:33:47 celaine Exp $

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
 * Author: Elaine Cheong
 * Date: 18 February 2004
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
  }
  uses {
    interface Timer;
    interface StdControl as TimerControl;
    interface ADC;
    interface StdControl as ADCControl;
    interface IntOutput;
  }
}
implementation {
  command result_t StdControl.init() {
    return rcombine (call ADCControl.init(), call TimerControl.init());
    return SUCCESS;
  }

  command result_t StdControl.start() {
    call ADCControl.start();
    call TimerControl.start();
    return call Timer.start(TIMER_REPEAT, 250);
  }

  command result_t StdControl.stop() {
    call ADCControl.stop();
    return call Timer.stop();
  }

  event result_t Timer.fired() {
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

