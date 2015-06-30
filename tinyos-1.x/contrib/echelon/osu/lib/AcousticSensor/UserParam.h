/*
  U s e r P a r a m . h

  This file (c) Copyright 2004 The MITRE Corporation (MITRE)

  This file is part of the NEST Acoustic Subsystem. It is licensed
  under the conditions described in the file LICENSE in the root
  directory of the NEST Acoustic Subsystem.
*/

/*
  These are the control knobs from the user's prespective.  Other
  paramiters may be derived from these paramiters.
*/

#ifndef _USER_PARAM_H_
#define _USER_PARAM_H_

/*
  Maximum target duration (in seconds) that will not be considered a
  change in background.  Rais this number for slow moving targets. If
  this number is too large then natural fluxuations in background
  noise, such as wind noise or distant trafic will cause false
  alarms.  Was 2.5.
*/
#define MAX_TARG_DUR 8

/*
  Number of snippets per second.  In general more snippets per second
  inprove the range and reduce the latency.  However, at some point you
  get a catastrophic breakdown caused by timing errors.  4 or 5 should
  be OK too.
*/
#define SNIPPET_PER_SEC 3

/*
  Snippet length in miliseconds.  Short lengths decrease senstitivty
  to low frequencies.  Long lengths can increase range in noisy
  environments, but just waste processor time in quiet environments.
  Was 100.
*/
#define SNIPPET_LEN 50

/*
  This is the number of estimated standard deviations above background
  that is required to consider it a target.  If you have false alarm
  problems in noisy environments (or with very long filter lengths) you
  can raise this number.  The result will be a slight reduction in
  range.
*/
#define NUM_STD 3

/*
  This is the minimum threshold (in ADC units) that is allowed,
  even if the estimated standard deviation of the background goes
  to zero.  If you have a false alarm problem in very quiet
  environments (like tall grass) raise this number.
*/
#define MIN_THRESH 4.5

#endif
