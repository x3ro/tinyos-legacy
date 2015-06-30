#ifndef H_Reset_h
#define H_Reset_h

// $Id: Reset.h,v 1.1.1.1 2007/11/05 19:11:35 jpolastre Exp $

void resetMote()
{
        WDTCTL = 0;
}

#endif//H_Reset_h
