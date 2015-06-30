/*********************************************************************
   FILE: fuse_detection_mex.cpp

   AUTHOR: Songhwai Oh (sho@eecs.berkeley.edu)   

**********************************************************************
                Copyright (c) 2005 Songhwai Oh 
*********************************************************************/

#include <math.h>
#include <float.h>
#include "mex.h"
#include <stdlib.h>
#include <time.h>
#include <stdarg.h>
#include <string.h>
//#include <iostream>
//using namespace std;

#ifndef INF
#define INF DBL_MAX
#endif
#ifndef ISINF
#define ISINF(A) (((A)==INF || (A)==-INF) ? 1 : 0)
#endif
#if !defined(MAX)
#define	MAX(A, B)	((A) > (B) ? (A) : (B))
#endif

struct grid_struct {
  int N;			// number of grid points
  int xN;			// number of grid points in x-axis
  int yN;			// number of grid points in y-axis
  double unitlen; 		// grid unit length
  int num_min_detections;	//
  double localmaxima_scale;	//
  double min_fuse_cnt;		//
  //  const mxArray *cluster; 	// clusters of grid points
  //  int cluster_siz;			// size of clusters
  const mxArray *sensV;		// sensor covers
  int sensV_siz;			// size of sensor covers
};
typedef struct grid_struct gridS;
gridS *grid;

struct sw_struct {
  int N;		// number of sensor nodes
  double Rs;		// sensing radius
  const mxArray *Pd;	// detection probabilities
  int Pd_siz;			// size of detection probabilities
  const mxArray *SR;	// surveillance region dimension (2x2)
};
typedef struct sw_struct swS;
swS *sw;

inline double square(double x) 
{
  return x*x;
}

mxArray* fuse_detection(const mxArray *mxA_rawY)
{
  int n, m, i, j, t, fuseV_siz;
  int x1,x2,y1,y2;
  int sensV_siz, mxA_rawY_siz, detected, num_detections, fuse_cnt;
  int *sensV, *sensDetect, *valid;
  double *plik, *plik0, *dp, d, *dp2, d2, *probp, prob;
  double min_plik, dist, max_dist;
  double *fuseV_x, *fuseV_y, fuse_x, fuse_y, fuse_v;
  mxArray *mxA_sensV, *mxA_fuseY, *mxA_plikH, *mxA_plikVM;
  mxArray *res;

  plik = new double[grid->N];
  plik0 = new double[grid->N];
  sensV = new int[grid->N];
  sensDetect = new int[grid->N];
  valid = new int[grid->N];
  fuseV_x = new double[grid->N];
  fuseV_y = new double[grid->N];
  fuseV_siz = 0;

  mxA_rawY_siz = mxGetM(mxA_rawY);
  probp = mxGetPr(sw->Pd);
  max_dist = square(grid->localmaxima_scale/grid->unitlen);

  // compute the likelihood
  for (n=0; n<grid->N; n++) {
    plik[n] = 0; plik0[n] = 0;

    mxA_sensV = mxGetCell(grid->sensV,n);
    sensV_siz = mxGetM(mxA_sensV);
    dp = mxGetPr(mxA_sensV);
    
    if (sensV_siz>0) {
      num_detections = 0;
      //mexPrintf("sensV[%d:%d] ", n+1,sensV_siz);
      for (i=0; i<sensV_siz; i++) {
	d = *(dp+i);
	sensV[i] = (int) d;
	//mexPrintf("%d ",sensV[i]);
	dp2 = mxGetPr(mxA_rawY);
	detected = 0;
	for (j=0; j<mxA_rawY_siz; j++) {
	  d2 = *(dp2+j);
	  if (sensV[i]==(int)d2) {
	    detected = 1;
	    break;
	  }
	}
	sensDetect[i] = (detected ? 1 : 0);
	num_detections += detected;
      }
      //mexPrintf("\n");
      //mexPrintf("\t Detected: ");
      //for (i=0; i<sensV_siz; i++) {
      //if (sensDetect[i]) 
      //  mexPrintf("%d ",sensV[i]);
      //}
      //mexPrintf(" (%d)\n\t", (num_detections >= MAX(grid->num_min_detections,floor(.5*sensV_siz))));
      if (num_detections >= MAX(grid->num_min_detections,floor(.5*sensV_siz))) {
	for (i=0; i<sensV_siz; i++) {
	  prob = *(probp+sensV[i]-1);
	  plik[n] += (sensDetect[i] ? log(prob) : log(1-prob));
	  //mexPrintf("%f ", plik[n]);
	}
	//mexPrintf("\n");
      }
      else 
	plik[n] = -INF;

      for (i=0; i<sensV_siz; i++) {
	prob = *(probp+sensV[i]-1);
	plik0[n] += (sensDetect[i] ? log(prob) : log(1-prob));
	//mexPrintf("%f ", plik0[n]);
      }
      //mexPrintf("\n");
    }
    else 
      plik[n] = -INF;
    //mexPrintf("  plik[%d] = %e  plik0[%d] = %e\n",n+1, plik[n],n+1, plik0[n]);
  }

  // find the minimum value
  min_plik = 0;
  for (n=0; n<grid->N; n++) {
    if (!ISINF(plik[n]) & plik[n]<min_plik)
      min_plik = plik[n];
  }
  //mexPrintf("min_plik = %e\n",min_plik);

  if (min_plik<0.0) {
    for (n=0; n<grid->N; n++) {
      valid[n] = (plik[n] > min_plik ? 1 : 0);
      //mexPrintf("plik[%d]=%e min_plik=%e valid=%d\n",n,plik[n],min_plik,valid[n]);
    }
    
    // find local maxima
    for (n=0; n<grid->N; n++) {
      if (valid[n]) {
	fuse_cnt = 1;
	fuse_v = (plik[n]-min_plik);
	x1 = n % grid->xN + 1; 
	y1 = n / grid->xN + 1; 
	//mexPrintf("n=%d x=%d y=%d v=%e\n",n+1,x1,y1,(plik[n]-min_plik));
	fuse_x = (plik[n]-min_plik)*x1;
	fuse_y = (plik[n]-min_plik)*y1;
	//mexPrintf("\t fuse_v=%e fuse_x=%f fuse_y=%f\n",fuse_v,fuse_x,fuse_y);
	for (m=n+1; m<grid->N; m++) {
	  if (valid[m]) {
	    x2 = m % grid->xN + 1;
	    y2 = m / grid->xN + 1;
	    dist = square(x1-x2) + square(y1-y2);
	    if (dist < max_dist) {
	      //mexPrintf("m=%d x=%d y=%d v=%e \n",m+1,x2,y2,(plik[n]-min_plik));
	      valid[m] = 0;
	      fuse_cnt++;
	      fuse_v += (plik[m]-min_plik);
	      fuse_x += (plik[m]-min_plik)*x2;
	      fuse_y += (plik[m]-min_plik)*y2;
	      //mexPrintf("\t fuse_v=%e fuse_x=%f fuse_y=%f\n",fuse_v,fuse_x,fuse_y);
	    }
	  }
	}
	if (fuse_cnt > (int) grid->min_fuse_cnt) {
	  fuseV_x[fuseV_siz] = fuse_x / fuse_v;
	  fuseV_y[fuseV_siz] = fuse_y / fuse_v;
	  fuseV_siz++;
	}
	//else
	  //mexPrintf("unused fuse_cnt=%d (<%d)\n", fuse_cnt, (int)grid->min_fuse_cnt);
      }
    }
  }
  //mexPrintf("fuseV_siz=%d\n",fuseV_siz);
  //for (i=0; i<fuseV_siz; i++)
  //mexPrintf("fuse[%d] x=%f y=%f\n",i,fuseV_x[i],fuseV_y[i]);

  // write outputs
  static const char *mx_field_names[] = {"fuseY","plikH","plikVM"};
  res = mxCreateStructMatrix(1,1,3,&mx_field_names[0]);
  mxA_plikH = mxCreateDoubleMatrix(1,grid->N,mxREAL);
  mxA_plikVM = mxCreateDoubleMatrix(1,grid->N,mxREAL);
  dp = mxGetPr(mxA_plikH);
  dp2 = mxGetPr(mxA_plikVM);
  for (n=0; n<grid->N; n++) {
    *(dp+n) = plik[n];
    *(dp2+n) = plik0[n];
  }
  mxA_fuseY = mxCreateDoubleMatrix(2,fuseV_siz,mxREAL);
  dp = mxGetPr(mxA_fuseY);
  n = 0;
  for (i=0; i<fuseV_siz; i++) {
    *(dp+n) = fuseV_x[i];
    n++;
    *(dp+n) = fuseV_y[i];
    n++;
  }
  mxSetFieldByNumber(res,0,0,mxA_fuseY);
  mxSetFieldByNumber(res,0,1,mxA_plikH);
  mxSetFieldByNumber(res,0,2,mxA_plikVM);

  delete[] plik;
  delete[] plik0;
  delete[] sensV;
  delete[] sensDetect;
  delete[] valid;
  delete[] fuseV_x;
  delete[] fuseV_y;
  return res;
}

//
// MATLAB Interface
//
// [fuseY,plikH,plikVM] = fuse_detection(grid,sw,rawY)
//
void mexFunction( int nlhs, mxArray *plhs[], 
		  int nrhs, const mxArray *prhs[] )     
{
  const mxArray *mxA_rawY;

  // check proper input and output
  if (nrhs < 3 || nrhs > 3)
    mexErrMsgTxt("Wrong number of inputs.");
  else if (nlhs > 3)
    mexErrMsgTxt("Too many output arguments.");
  else if (!mxIsStruct(prhs[0]))
    mexErrMsgTxt("Input(1) must be a structure.");
  else if (!mxIsStruct(prhs[1]))
    mexErrMsgTxt("Input(2) must be a structure.");
  else if (!mxIsDouble(prhs[2]))
    mexErrMsgTxt("Input(3) must be a double-precision, floating-point vector.");

  // get input: rawY
  mxA_rawY = prhs[2];

  // get grid information
  grid = (gridS*) mxCalloc(1,sizeof(gridS));
  grid->N = mxGetScalar(mxGetField(prhs[0],0,"N"));
  grid->xN = mxGetScalar(mxGetField(prhs[0],0,"xN"));
  grid->yN = mxGetScalar(mxGetField(prhs[0],0,"yN"));
  grid->unitlen = mxGetScalar(mxGetField(prhs[0],0,"unitlen"));
  grid->num_min_detections = mxGetScalar(mxGetField(prhs[0],0,"num_min_detections"));
  grid->localmaxima_scale = mxGetScalar(mxGetField(prhs[0],0,"localmaxima_scale"));
  grid->min_fuse_cnt = mxGetScalar(mxGetField(prhs[0],0,"min_fuse_cnt"));
  //grid->cluster = mxGetField(prhs[0],0,"cluster");
  //grid->cluster_siz = mxGetNumberOfElements(grid->cluster);
  grid->sensV = mxGetField(prhs[0],0,"sensV");
  grid->sensV_siz = mxGetNumberOfElements(grid->sensV);

  // get sensor network information
  sw = (swS*) mxCalloc(1,sizeof(swS));
  sw->N = mxGetScalar(mxGetField(prhs[1],0,"N"));
  sw->Rs = mxGetScalar(mxGetField(prhs[1],0,"Rs"));
  sw->Pd = mxGetField(prhs[1],0,"Pd");
  sw->Pd_siz = mxGetNumberOfElements(sw->Pd);
  sw->SR = mxGetField(prhs[1],0,"SR");

  /*
  mexPrintf("grid: N=%d xN=%d yN=%d unitlen=%f num_min_detections=%d localmaxima_scale=%f\n", 
	    grid->N, grid->xN, grid->yN, grid->unitlen, grid->num_min_detections, 
	    grid->localmaxima_scale);
  mexPrintf("      cluster=%d(0x%08x) sensV=%d(0x%08x)\n", 
	    grid->cluster_siz, grid->cluster, grid->sensV_siz, grid->sensV);
  mexPrintf("  sw: N=%d Pd=%d(0x%08x) SR=(0x%08x)\n", sw->N, sw->Pd_siz, sw->Pd, sw->SR);
  */

  // main function
  plhs[0] = fuse_detection(mxA_rawY);

  // memory management
  mxFree(grid);
  mxFree(sw);

  return;    
}
