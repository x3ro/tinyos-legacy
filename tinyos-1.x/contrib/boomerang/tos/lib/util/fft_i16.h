#ifndef H_fft_i16_h
#define H_fft_i16_h

/*
Heavily modified from int_fft.c found at http://www.jjj.de/fft/fftpage.html
by Cory Sharp <cory@moteiv.com>
*/

/*
FILE: int_fft-doc.txt

Here it is... an integer FFT routine that's pretty fast.  I've only tested
it on a 68k powerbook, and it's much faster than either software floating
point or the built in FPU.  The orignal source was DOS only and came off
the net.  
I simply removed the ugly DOS stuff and did some simple testing.  I do not
guarantee that it works... but try compiling with -DMAIN to test it yourself.

Those of you with impoverished floating point hardware (notably, some new
Powerbooks, and maybe even Intel machines) might find these routines
useful.

Input and output is an array of shorts.  I haven't tested all the routines,
but the FFT looks good enough to use.  It keeps a table of trig functions, so
it will only run up to 1024 points.

-- Malcolm

Written by:  Tom Roberts  11/8/89
Made portable:  Malcolm Slaney 12/15/94 malcolm (AT) interval.com
*/

typedef int16_t fft_data_t;
typedef int32_t fft_multiply_t;

enum {
  SIZE_SINETABLE_LOG2 = 8,
  SIZE_SINETABLE = (1 << SIZE_SINETABLE_LOG2), // size of sineTable
};

#if defined(__MSP430__) && defined(MPY_)

#undef atomic
#define atomic_fft_i16_mul atomic

fft_data_t fft_i16_mul( int16_t a, int16_t b ) {
  MPYS = a;
  OP2 = b;
  return (RESLO & 0x8000) ? ((RESHI << 1) | 1) : (RESHI << 1);
}

#else

#define atomic_fft_i16_mul

fft_data_t fft_i16_mul( fft_multiply_t a, fft_multiply_t b ) {
  return ((a*b + 16383) << 1) >> 16;
}

#endif

fft_data_t sineTable[SIZE_SINETABLE] = { 0, 804, 1608, 2410, 3212, 4011, 4808,
  5602, 6393, 7179, 7962, 8739, 9512, 10278, 11039, 11793, 12539, 13279, 14010,
  14732, 15446, 16151, 16846, 17530, 18204, 18868, 19519, 20159, 20787, 21403,
  22005, 22594, 23170, 23731, 24279, 24811, 25329, 25832, 26319, 26790, 27245,
  27683, 28105, 28510, 28898, 29268, 29621, 29956, 30273, 30571, 30852, 31113,
  31356, 31580, 31785, 31971, 32137, 32285, 32412, 32521, 32609, 32678, 32728,
  32757, 32767, 32757, 32728, 32678, 32609, 32521, 32412, 32285, 32137, 31971,
  31785, 31580, 31356, 31113, 30852, 30571, 30273, 29956, 29621, 29268, 28898,
  28510, 28105, 27683, 27245, 26790, 26319, 25832, 25329, 24811, 24279, 23731,
  23170, 22594, 22005, 21403, 20787, 20159, 19519, 18868, 18204, 17530, 16846,
  16151, 15446, 14732, 14010, 13279, 12539, 11793, 11039, 10278, 9512, 8739,
  7962, 7179, 6393, 5602, 4808, 4011, 3212, 2410, 1608, 804, 0, -804, -1608,
  -2410, -3212, -4011, -4808, -5602, -6393, -7179, -7962, -8739, -9512, -10278,
  -11039, -11793, -12539, -13279, -14010, -14732, -15446, -16151, -16846, -17530,
  -18204, -18868, -19519, -20159, -20787, -21403, -22005, -22594, -23170, -23731,
  -24279, -24811, -25329, -25832, -26319, -26790, -27245, -27683, -28105, -28510,
  -28898, -29268, -29621, -29956, -30273, -30571, -30852, -31113, -31356, -31580,
  -31785, -31971, -32137, -32285, -32412, -32521, -32609, -32678, -32728, -32757,
  -32767, -32757, -32728, -32678, -32609, -32521, -32412, -32285, -32137, -31971,
  -31785, -31580, -31356, -31113, -30852, -30571, -30273, -29956, -29621, -29268,
  -28898, -28510, -28105, -27683, -27245, -26790, -26319, -25832, -25329, -24811,
  -24279, -23731, -23170, -22594, -22005, -21403, -20787, -20159, -19519, -18868,
  -18204, -17530, -16846, -16151, -15446, -14732, -14010, -13279, -12539, -11793,
  -11039, -10278, -9512, -8739, -7962, -7179, -6393, -5602, -4808, -4011, -3212,
  -2410, -1608, -804
};


/*
  fix_fft() - perform fast Fourier transform.

  if n>0 FFT is done, if n<0 inverse FFT is done
  fr[n],fi[n] are real,imaginary arrays, INPUT AND RESULT.
  size of data = 2**m
  set inverse to 0=dft, 1=idft
*/
int fft_i16(fft_data_t fr[], fft_data_t fi[], int m, int inverse)
{
  int mr, nn, i, j, l, k, istep, n, scale, shift;
  fft_data_t qr, qi, tr, ti, wr, wi;

  n = 1<<m;

  if(n > SIZE_SINETABLE)
    return -1;

  mr = 0;
  nn = n - 1;
  scale = 0;

  /* decimation in time - re-order data */
  for(m=1; m<=nn; ++m) {
    l = n;
    do {
      l >>= 1;
    } while(mr+l > nn);
    mr = (mr & (l-1)) + l;

    if(mr <= m) continue;
    tr = fr[m];
    fr[m] = fr[mr];
    fr[mr] = tr;
    ti = fi[m];
    fi[m] = fi[mr];
    fi[mr] = ti;
  }

  l = 1;
  k = SIZE_SINETABLE_LOG2-1;
  while(l < n) {
    if(inverse) {
      /* variable scaling, depending upon data */
      shift = 0;
      for(i=0; i<n; ++i) {
        j = fr[i];
        if(j < 0)
          j = -j;
        m = fi[i];
        if(m < 0)
          m = -m;
        if(j > 16383 || m > 16383) {
          shift = 1;
          break;
        }
      }
      if(shift)
        ++scale;
    } else {
      /* fft_data_t scaling, for proper normalization -
         there will be log2(n) passes, so this
         results in an overall factor of 1/n,
         distributed to maximize arithmetic accuracy. */
      shift = 1;
    }
    /* it may not be obvious, but the shift will be performed
       on each data point exactly once, during this pass. */
    istep = l << 1;
    for(m=0; m<l; ++m) {
      j = m << k;
      /* 0 <= j < SIZE_SINETABLE/2 */
      wr =  sineTable[j+SIZE_SINETABLE/4];
      wi = -sineTable[j];
      if(inverse)
        wi = -wi;
      if(shift) { wr >>= 1; wi >>= 1; }
      for(i=m; i<n; i+=istep) {
        j = i + l;
        atomic_fft_i16_mul {
          tr = fft_i16_mul(wr,fr[j]) - fft_i16_mul(wi,fi[j]);
          ti = fft_i16_mul(wr,fi[j]) + fft_i16_mul(wi,fr[j]);
        }
        qr = fr[i];
        qi = fi[i];
        if(shift) { qr >>= 1; qi >>= 1; }
        fr[j] = qr - tr;
        fi[j] = qi - ti;
        fr[i] = qr + tr;
        fi[i] = qi + ti;
      }
    }
    --k;
    l = istep;
  }

  return scale;
}



#ifdef  MAIN

#include  <stdio.h>
#include  <math.h>

#define M       7
#define N       (1<<M)

main(){
  fft_data_t real[N], imag[N];
  int     i;

  for (i=0; i<N; i++){
    real[i] = 31.*cos(i*2*M_PI/N) + 31.*cos(i*5*2*M_PI/N);
    imag[i] = 0;
    printf("%5d  %% %5d / %5d\n", real[i], i, imag[i]);
  }
  printf("%%\n");

  fft_i8(real, imag, M, 0);

  for (i=0; i<N; i++)
    printf("%5d  %% %5d / %5d\n", real[i], i, imag[i]);
  printf("%%\n");

  fft_i8(real, imag, M, 1);

  for (i=0; i<N; i++)
    printf("%5d  %% %5d / %5d\n", real[i], i, imag[i]);
  printf("%%\n");
}

#endif  /* MAIN */

#endif//H_fft_i16_h
