// $Id: Trigger.nc,v 1.2 2004/03/30 09:32:30 celaine Exp $

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
 * Date: 18 February 2004
 *
 */

/**
 * @author Elaine Cheong
 */

module Trigger {
  provides {
    interface StdControl;
  }
  uses {
    interface Timer;
    interface StdControl as TimerControl;
    command result_t trigger();
  }
}
implementation {
  command result_t StdControl.init() {
    call TimerControl.init();
    return SUCCESS;
  }

  command result_t StdControl.start() {
    call TimerControl.start();
    return call Timer.start(TIMER_REPEAT, 250);
  }

  command result_t StdControl.stop() {
    return call Timer.stop();
  }

  event result_t Timer.fired() {
    call trigger();
    return SUCCESS;
  }
}

