/*
 * powermod.h
 * Author: Victor Shnayder
 *
 * Global variable declarations for the power modeling TOSSIM extension
 */

#ifndef POWERMOD_H_INCLUDED
#define POWERMOD_H_INCLUDED

double* cycles;  // array of bb->cycle count mappings
int power_init;
int prof_on;
int cpu_prof_on;

#endif
