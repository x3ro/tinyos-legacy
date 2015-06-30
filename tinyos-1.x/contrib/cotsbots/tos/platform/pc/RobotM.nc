/*                                                                      tab:4
 *
 *
 * "Copyright (c) 2002 and The Regents of the University
 * of California.  All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 *
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 *
 * Authors:             Sarah Bergbreiter
 * Date last modified:  4/14/04
 *
 * The Robot component is the top-level control for a robot on the mica mote.
 * This is the simulation implementation which simply sends debug messages
 * to TOSSIM to be interpreted.
 *
 */

module RobotM {
  provides interface Robot;
}
implementation {

  /* Initialize the communication */
  command result_t Robot.init() {
    dbg(DBG_BOOT, "ROBOT: initialized.\n");
    return SUCCESS;
  }

  /* Set the robot speed */
  command result_t Robot.setSpeed(uint8_t speed) {
    dbg(DBG_USR3, "ROBOT: Speed = %d\n", speed);
    return SUCCESS;
  }

  /* Set the robot direction */
  command result_t Robot.setDir(uint8_t dir) {
    dbg(DBG_USR3, "ROBOT: Direction = %d\n", dir);
    return SUCCESS;
  }

  /* Set the robot turn */
  command result_t Robot.setTurn(uint8_t turn) {
    dbg(DBG_USR3, "ROBOT: Turn = %d\n", turn);
    return SUCCESS;
  }

  /* Set the robot speed turn and direction all at once */
  command result_t Robot.setSpeedTurnDirection(uint8_t speed, uint8_t turn, uint8_t dir) {
    dbg(DBG_USR3, "ROBOT: SDT = %d %d %d\n", speed, dir, turn);
    return SUCCESS;
  }

}
