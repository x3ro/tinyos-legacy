/* "Copyright (c) 2000-2002 The Regents of the University of California.  
 * All rights reserved.
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
 */

// Authors: Kamin Whitehouse


includes Localization;
includes Ranging;
includes NestArch;


//!! Config 200 { uint16_t localizationPeriod = 1800; }

//!! Config 201 { uint16_t rangingPeriod = 994; }



module LocalizeM
{
  provides
  {
    interface StdControl;
  }
  uses
  {

    interface Timer as LocalizationTimer;
    interface Timer as RangingTimer;
    interface Localization;
    interface RangingActuator;
    interface Config_localizationPeriod;
    interface Config_rangingPeriod;
    interface Leds;
    interface StdControl as Sounder;
  }
}
implementation
{
	
  command result_t StdControl.init()
  {
    return SUCCESS;
  }

  command result_t StdControl.start()
  {
    call LocalizationTimer.start( TIMER_REPEAT, G_Config.localizationPeriod );
    call RangingTimer.start( TIMER_REPEAT, G_Config.rangingPeriod );
    return SUCCESS;
  }

  command result_t StdControl.stop()
  {
    call LocalizationTimer.stop();
    call RangingTimer.stop();
    return SUCCESS;
  }


  event result_t LocalizationTimer.fired()
  {
	call Localization.estimateLocation();
	call Leds.greenToggle();
  }

  event result_t RangingTimer.fired()
  {
	call RangingActuator.range();
	call Leds.redToggle();
  }

  event void Config_localizationPeriod.updated()
  {
    call LocalizationTimer.stop();
    if(G_Config.localizationPeriod>0){
	call LocalizationTimer.start( TIMER_REPEAT, G_Config.localizationPeriod );
    }
  }

  event void Config_rangingPeriod.updated()
  {
    call RangingTimer.stop();
    if(G_Config.rangingPeriod>0){
	call RangingTimer.start( TIMER_REPEAT, G_Config.rangingPeriod );
    }
  }
}





