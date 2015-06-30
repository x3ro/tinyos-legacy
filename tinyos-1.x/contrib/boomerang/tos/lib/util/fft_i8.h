#ifndef H_fft_i8_h
#define H_fft_i8_h

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

typedef int8_t fft_data_t;
typedef int16_t fft_multiply_t;

enum {
  SIZE_SINETABLE_LOG2 = 8,
  SIZE_SINETABLE = (1 << SIZE_SINETABLE_LOG2), // size of sineTable
};

#if defined(__MSP430__) && defined(MPY_)

#undef atomic
#define atomic_fft_i8_mul atomic

fft_data_t fft_i8_mul( fft_multiply_t a, fft_multiply_t b ) {
  MPYS = a;
  OP2 = b;
  return ((RESLO + 63) << 1) >> 8;
}

#else

#define atomic_fft_i8_mul

fft_data_t fft_i8_mul( fft_multiply_t a, fft_multiply_t b ) {
  return ((a*b + 63) << 1) >> 8;
}

#endif

fft_data_t sineTable[SIZE_SINETABLE] = {
  0, 3, 6, 9, 12, 16, 19, 22, 25, 28, 31, 34, 37, 40, 43, 46, 49, 51, 54, 57, 60,
  63, 65, 68, 71, 73, 76, 78, 81, 83, 85, 88, 90, 92, 94, 96, 98, 100, 102, 104,
  106, 107, 109, 111, 112, 113, 115, 116, 117, 118, 120, 121, 122, 122, 123, 124,
  125, 125, 126, 126, 126, 127, 127, 127, 127, 127, 127, 127, 126, 126, 126, 125,
  125, 124, 123, 122, 122, 121, 120, 118, 117, 116, 115, 113, 112, 111, 109, 107,
  106, 104, 102, 100, 98, 96, 94, 92, 90, 88, 85, 83, 81, 78, 76, 73, 71, 68, 65,
  63, 60, 57, 54, 51, 49, 46, 43, 40, 37, 34, 31, 28, 25, 22, 19, 16, 12, 9, 6,
  3, 0, -3, -6, -9, -12, -16, -19, -22, -25, -28, -31, -34, -37, -40, -43, -46,
  -49, -51, -54, -57, -60, -63, -65, -68, -71, -73, -76, -78, -81, -83, -85, -88,
  -90, -92, -94, -96, -98, -100, -102, -104, -106, -107, -109, -111, -112, -113,
  -115, -116, -117, -118, -120, -121, -122, -122, -123, -124, -125, -125, -126,
  -126, -126, -127, -127, -127, -127, -127, -127, -127, -126, -126, -126, -125,
  -125, -124, -123, -122, -122, -121, -120, -118, -117, -116, -115, -113, -112,
  -111, -109, -107, -106, -104, -102, -100, -98, -96, -94, -92, -90, -88, -85,
  -83, -81, -78, -76, -73, -71, -68, -65, -63, -60, -57, -54, -51, -49, -46, -43,
  -40, -37, -34, -31, -28, -25, -22, -19, -16, -12, -9, -6, -3,
};


/*
  fix_fft() - perform fast Fourier transform.

  if n>0 FFT is done, if n<0 inverse FFT is done
  fr[n],fi[n] are real,imaginary arrays, INPUT AND RESULT.
  size of data = 2**m
  set inverse to 0=dft, 1=idft
*/
int fft_i8(fft_data_t fr[], fft_data_t fi[], int m, int inverse)
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
        atomic_fft_i8_mul {
          tr = fft_i8_mul(wr,fr[j]) - fft_i8_mul(wi,fi[j]);
          ti = fft_i8_mul(wr,fi[j]) + fft_i8_mul(wi,fr[j]);
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

#endif//H_fft_i8_h
