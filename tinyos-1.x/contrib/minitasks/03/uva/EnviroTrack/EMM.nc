/* "Copyright (c) 2000-2002 University of Virginia.  
 * All rights reserved.
 * 
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF VIRGINIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * VIRGINIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF VIRGINIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF VIRGINIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 * 
 * Authors: Brain Blum,Tian He 
 */

interface EMM {
   
   command result_t setParameters(uint16_t baseRate, uint16_t sensorDistance);
   command result_t init();
   command result_t start();

   command result_t join(uint16_t ev, uint16_t port, uint16_t rGroup);
   command result_t resign();
   
   command result_t accept(uint16_t group);
   command result_t reportEventStatus(uint16_t ev, char seen);
	command result_t setState(uint16_t state);
	command uint16_t getState();

	event result_t recruitPacket(uint16_t ev, uint16_t lGroup, uint16_t rGroup);
	event result_t leaveGroup(uint16_t group);
	event result_t joinDone(uint16_t group, uint16_t leader);
	
   //tian
   command result_t stop();  
   command result_t FireHeartBeat(); //for performance concern. used same timer in Tracking
       
}
