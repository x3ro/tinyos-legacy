/*
 * powermod.h
 * Author: Victor Shnayder
 *
 * Global variable declarations for the power modeling TOSSIM extension
 */

#ifndef POWERMOD_H_INCLUDED
#define POWERMOD_H_INCLUDED

norace double* cycles;  // array of bb->cycle count mappings
norace int power_init;
norace int prof_on;
norace int cpu_prof_on;

#endif
