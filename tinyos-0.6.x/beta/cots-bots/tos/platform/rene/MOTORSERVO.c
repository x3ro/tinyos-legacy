/*
 * Sarah Bergbreiter
 * 9/26/2001
 * COTS-BOTS project
 *
 * This MOTORSERVO component uses Timer2 to create two pwm signals with 
 * different duty cycles.  This allows for the control of two different motors.
 * MOTORSERVO differs from MOTOR in that it also contains code for the servo 
 * control (using the ADC).
 *
 * The component was also written taking some liberties in order to minimize
 * the amount of code and time taken in the interrupts.  Note to self: might
 * be able to take advantage of 2-cycle multiply on ATMEGA163L in PID loop.
 *
 * 9/26/2001
 * Created based on MOTOR2a and SERVO to solve RFM/Timer1 problem.
 * 9/27/2001
 * Make sure to test all relevant cases:
 * Set both speeds to zero: forward and reverse
 * Set speeds different (x1<x2 and x2<x1): all combos of forward and reverse
 * Set speeds one tick apart: all combos of forward and reverse
 * Set speeds the same: all combos of forward and reverse
 * Set one speed to zero and one to something else (both and all directions)
 * 
 * Once this works, can be reasonably confident about adding servo component
 *
 * 11/18/2001
 * Modifying servo component to actually work.  I don't know what happened
 * between it working previously and now.
 *
 * 1/24/2002
 * Changed signal handlers to correctly defined functions (v. aliased ones)
 */

#include "tos.h"
#include "dbg.h"
#include "MOTORSERVO.h"

/* Servo Constants */
#define SERVO_PORT 1
#define STRAIGHT 80
#define RIGHT 100
#define LEFT 60
/* Feedback Constants */
#define Kp 4
#define Ki 2
#define Kd 0

#define CUTOFF 7

/* Create frame here */
#define TOS_FRAME_TYPE MOTORSERVO_frame
TOS_FRAME_BEGIN(MOTORSERVO_frame){
  // General motor variables
  char state;
  unsigned char speed1;
  unsigned char speed2;
  unsigned char compare1;
  unsigned char compare2;
  char direction1;
  char direction2; 
  unsigned char compare;
  unsigned char data;
  // Servo control variables
  char servo_reference;
  unsigned char total_error;
  //unsigned char prev_error;
}
TOS_FRAME_END(MOTORSERVO_frame);

char TOS_COMMAND(MOTORSERVO_INIT)(void){
  // Make sure all pin directions are set correctly, counter is 
  // initialized and all registries are set.
  
  VAR(servo_reference) = STRAIGHT;
  //VAR(prev_error) = 0;
  VAR(total_error) = 0;
  VAR(speed1) = CUTOFF-1;
  VAR(speed2) = CUTOFF-1;
  VAR(compare1) = CUTOFF-1;
  VAR(compare2) = CUTOFF-1;
  VAR(direction1) = 1;
  VAR(direction2) = 1;
  VAR(state) = 3;
  VAR(data) = 0;

  dbg(DBG_BOOT,("Motors initialized\n"));
  outp(0x05, TCCR2);   // Set prescaler to 128
  CLR_MOTOR1PWM_PIN(); // Motor1 PWM
  CLR_MOTOR1DIR_PIN(); // Motor1 Initialized to forward direction
  CLR_MOTOR2PWM_PIN(); // Motor2 PWM
  CLR_MOTOR2DIR_PIN(); // Motor2 Initialized to forward direction
  
  outp(CUTOFF-1, OCR2);       // Initialize compare register to cutoff-1

  sbi(TIMSK, OCIE2);
  sbi(TIMSK, TOIE2);   // Enable interrupts for overflow and compare match
  sei();               // Set the global interrupt pin (not sure if I need)

  return TOS_CALL_COMMAND(MOTORSERVO_SUB_INIT)();
}

char TOS_COMMAND(MOTOR1_SETSPEED)(unsigned char speed){
  // Set the duty cycle for the PWM output to modulate the speed of motor1.
  if (speed > 250)
    VAR(speed1) = 250;
  else if (speed < (CUTOFF-1))
    VAR(speed1) = CUTOFF - 1;
  else
    VAR(speed1) = speed;

  VAR(compare1) = VAR(speed1);

  if (VAR(direction1) == 0){
    VAR(compare1) = 255-VAR(speed1)+1;
  }

  return 1;
}

char TOS_COMMAND(MOTOR1_SETDIR)(char direction){
  // Set motor 1 direction (keep speed the same though)

  dbg(DBG_TASK,("Setting Motor1 = %d",(int)(direction)));
  VAR(direction1) = direction;
  if (direction == 0) {
    SET_MOTOR1DIR_PIN();    // going in reverse
    VAR(compare1) = 255-VAR(speed1)+1;
  }
  else {
    CLR_MOTOR1DIR_PIN();    // going forward
    VAR(compare1) = VAR(speed1);
  }

  return 1;
}

char TOS_COMMAND(SERVO_SET_DIRECTION)(char direction){
  // defining acceptable directions as 0 - 40 with 20 as center
  if (direction > 40) direction = 40;
  if (direction < 0) direction = 0;

  // compute appropriate adc value from this and store in frame variable
  VAR(servo_reference) = direction + 60;
  VAR(total_error) = 0;

  return 1;
}

char TOS_EVENT(MOTORSERVO_DATA_READY)(int data){
  // use this to change speed2 to appropriate value to drive motor

  unsigned char i_err = 0; 
  unsigned char d_err = 0;
  unsigned char error; 

  VAR(data) = data >> 2;

  if (VAR(data) > VAR(servo_reference)){
    error = VAR(data) - VAR(servo_reference);
    VAR(direction2) = 0;
  }
  else {
    error = VAR(servo_reference) - VAR(data);
    VAR(direction2) = 1;
  }

  if ((250 - error) > VAR(total_error))
    VAR(total_error) += error;
  else
    VAR(total_error) = 250;

  VAR(speed2) = 0;
  if (error > 0){ 
    //d_err = (error - VAR(prev_error))*Kd;
    //VAR(prev_error) = error;
    if (error < 15) 
      error = error << Kp;
    else
      error = 15 << Kp;
    i_err = VAR(total_error) >> Ki ;
    if (i_err < (250-error-d_err))
      VAR(speed2) = error + i_err + d_err;
    else
      VAR(speed2) = 250;
  }
  if (VAR(speed2) < CUTOFF-1) {
    VAR(speed2) = CUTOFF-1;
    VAR(total_error) = 0;
  }

  if (VAR(direction2) == 0) { 
    VAR(compare2) = 255-VAR(speed2)+1; 
    SET_MOTOR2DIR_PIN();
  }
  else {
    VAR(compare2) = VAR(speed2);
    CLR_MOTOR2DIR_PIN();
  }

  // Signal event for calibration
  TOS_SIGNAL_EVENT(MOTORSERVO_FIRE_EVENT)(VAR(data),VAR(speed2));

  return 1;
}


TOS_INTERRUPT_HANDLER(SIG_OVERFLOW2, (void)) {
  // Note: The zero case is taken care of by setting a zero speed to 1 (which
  // will essentially be zero anyway and greatly simplifies the logic)
  // I need to make sure this happens on the interrupt so all of this code
  // needs to go inside the interrupt
  // compare is set in other commands/events

  VAR(state) = 0;
  VAR(compare) = 0;

  dbg(DBG_TASK,("Motor1 = %d",(int)(VAR(direction1))));

  if (VAR(compare1) < VAR(compare2)) {
    outp(VAR(compare1),OCR2);
    VAR(compare) = VAR(compare2);
    VAR(state) = 1;
  }
  else if (VAR(compare2) < VAR(compare1)) {
    outp(VAR(compare2),OCR2);
    VAR(compare) = VAR(compare1);
    VAR(state) = 2;
  }
  else {
    outp(VAR(compare1),OCR2);
    VAR(compare) = VAR(compare1);
    VAR(state) = 3;
  }

  // Start motor pulse -- if small don't turn on
  if (VAR(compare1) < CUTOFF)
    CLR_MOTOR1PWM_PIN();
  else
    SET_MOTOR1PWM_PIN();
  if (VAR(compare2) < CUTOFF)
    CLR_MOTOR2PWM_PIN();
  else
    SET_MOTOR2PWM_PIN();

  TOS_CALL_COMMAND(MOTORSERVO_GET_DATA)(SERVO_PORT);
}
  
TOS_INTERRUPT_HANDLER(SIG_OUTPUT_COMPARE2, (void)) {
  // Using speed and direction vars might give me errors if this has just
  // changed...

  if (VAR(state) & 1)
    CLR_MOTOR1PWM_PIN();
  if (VAR(state) & 2)
    CLR_MOTOR2PWM_PIN();
  outp(VAR(compare),OCR2);
  VAR(state) += 1;

}






