//@author Ralph Kling

module IGlowM {

    provides {
        interface StdControl;
    }
    uses {
        interface Timer;
        interface UTimer;
        interface Leds;
    }
}

implementation {

#include <stdlib.h>

#define STEPS        50
#define HRSPEED     200 // us
#define SPEED        50 // ms

    uint32_t l, r, g, b, h, s, v;

    command result_t StdControl.init() {
        call Leds.init();
        l = 0;
        h = 0;
        s = 45; // saturation 0 ... STEPS
        v = 45; // brightness 0 ... STEPS
        return SUCCESS;
    }

    command result_t StdControl.start() {
        call Leds.redOff();
        call Leds.greenOff(); 
        call Leds.yellowOff(); // blue on IM2
        call Timer.start(TIMER_REPEAT, SPEED);
        call UTimer.start(TIMER_REPEAT, HRSPEED);
        return SUCCESS;
    }

    command result_t StdControl.stop() {
        call Timer.stop();
        call UTimer.stop();
        return SUCCESS;
    }

    // Use HSV to maintain brightness/saturation
    // From http://www.cs.rit.edu/~ncs/color/t_convert.html
    // Converted from FP to integer by RMK
    task void HSVtoRGB() {
        uint32_t i, f, p, q, t, x;

        if (s == 0) { // achromatic (grey)
            r = g = b = v;
            return;
        }
        x = (h * STEPS) / 60;
        i = h / 60;
        f = x - (i * STEPS);		// factorial part of h
        p = (v * (STEPS - s)) / STEPS;
        q = (v * (STEPS * STEPS - s * f)) / STEPS / STEPS;
        t = (v * (STEPS * STEPS - s * (STEPS - f))) / STEPS / STEPS;
        switch (i) {
		case 0:
			r = v;
			g = t;
			b = p;
			break;
		case 1:
			r = q;
			g = v;
			b = p;
			break;
        case 2:
            r = p;
			g = v;
			b = t;
			break;
		case 3:
			r = p;
			g = q;
			b = v;
			break;
		case 4:
			r = t;
			g = p;
			b = v;
			break;
		default:		// case 5:
			r = v;
			g = p;
			b = q;
			break;
        }
        h = h + 1;
        if (h >= 360) {
            h = 0;
        }
    }

    event result_t UTimer.fired() {
        if (l > r) {
            call Leds.redOn();
        } else {
            call Leds.redOff();
        }
        if (l > g) {
            call Leds.greenOn();
        } else {
            call Leds.greenOff();
        }
        if (l > b) {
            call Leds.yellowOn(); // blue on IM2
        } else {
            call Leds.yellowOff();
        }
        l++;
        if (l >= STEPS) {
            l = 0;
        }
        return SUCCESS;
    }

    event result_t Timer.fired() {
        post HSVtoRGB();
        return SUCCESS;
    }
}

