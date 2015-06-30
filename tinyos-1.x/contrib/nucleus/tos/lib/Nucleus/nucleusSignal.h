//$Id: nucleusSignal.h,v 1.2 2005/06/14 18:10:10 gtolle Exp $

#ifndef __NUCLEUSSIGNAL_H__
#define __NUCLEUSSIGNAL_H__

#ifdef NUCLEUS_NO_EVENTS
#define nucleusSignal(...)
#else
#define nucleusSignal(x) signal x
#endif

#endif
