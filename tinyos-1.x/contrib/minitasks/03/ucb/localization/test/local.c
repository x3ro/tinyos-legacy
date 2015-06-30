#include "Localization.h"
#include <stdio.h>
#include "nrutil.h"
#include <inttypes.h>
#include <string.h>
#include <stdlib.h>
#include <math.h>
#include <stddef.h>
#include <ctype.h>

#define NRANSI
#define SWAP(a,b) {temp=(a);(a)=(b);(b)=temp;}
#define TOL 1.0e-5
#define SUCCESS 1
#define FAIL 0
#define MAX_MEMBERS_AnchorHood 5



distance_t distances[3];
location_t locations[3]; 

float inline square(float f){ return f*f;}

void svbksb(float **u, float w[], float **v, int m, int n, float b[], float x[])
{
	int jj,j,i;
	float s;
	float tmp[MAX_MEMBERS_AnchorHood+1];	

	for (j=1;j<=n;j++) {
		s=0.0;
		if (w[j]) {
			for (i=1;i<=m;i++) s += u[i][j]*b[i];
			s /= w[j];
		}
		tmp[j]=s;
	}
	for (j=1;j<=n;j++) {
		s=0.0;
		for (jj=1;jj<=n;jj++) s += v[j][jj]*tmp[jj];
		x[j]=s;
	}
}

float pythag(float a, float b)
{
	float absa,absb;
	absa=fabs(a);
	absb=fabs(b);
	if (absa > absb) return absa*sqrt(1.0+SQR(absb/absa));
	else return (absb == 0.0 ? 0.0 : absb*sqrt(1.0+SQR(absa/absb)));
}

result_t svdcmp(float **a, int m, int n, float w[], float **v)
{
	int flag,i,its,j,jj,k,l,nm;
	float anorm,c,f,g,h,s,scale,x,y,z;
	float rv1[MAX_MEMBERS_AnchorHood+1];

	g=scale=anorm=0.0;
	for (i=1;i<=n;i++) {
		l=i+1;
		rv1[i]=scale*g;
		g=s=scale=0.0;
		if (i <= m) {
			for (k=i;k<=m;k++) scale += fabs(a[k][i]);
			if (scale) {
				for (k=i;k<=m;k++) {
					a[k][i] /= scale;
					s += a[k][i]*a[k][i];
				}
				f=a[i][i];
				g = -SIGN(sqrt(s),f);
				h=f*g-s;
				a[i][i]=f-g;
				for (j=l;j<=n;j++) {
					for (s=0.0,k=i;k<=m;k++) s += a[k][i]*a[k][j];
					f=s/h;
					for (k=i;k<=m;k++) a[k][j] += f*a[k][i];
				}
				for (k=i;k<=m;k++) a[k][i] *= scale;
			}
		}
		w[i]=scale *g;
		g=s=scale=0.0;
		if (i <= m && i != n) {
			for (k=l;k<=n;k++) scale += fabs(a[i][k]);
			if (scale) {
				for (k=l;k<=n;k++) {
					a[i][k] /= scale;
					s += a[i][k]*a[i][k];
				}
				f=a[i][l];
				g = -SIGN(sqrt(s),f);
				h=f*g-s;
				a[i][l]=f-g;
				for (k=l;k<=n;k++) rv1[k]=a[i][k]/h;
				for (j=l;j<=m;j++) {
					for (s=0.0,k=l;k<=n;k++) s += a[j][k]*a[i][k];
					for (k=l;k<=n;k++) a[j][k] += s*rv1[k];
				}
				for (k=l;k<=n;k++) a[i][k] *= scale;
			}
		}
		anorm=FMAX(anorm,(fabs(w[i])+fabs(rv1[i])));
	}
	for (i=n;i>=1;i--) {
		if (i < n) {
			if (g) {
				for (j=l;j<=n;j++)
					v[j][i]=(a[i][j]/a[i][l])/g;
				for (j=l;j<=n;j++) {
					for (s=0.0,k=l;k<=n;k++) s += a[i][k]*v[k][j];
					for (k=l;k<=n;k++) v[k][j] += s*v[k][i];
				}
			}
			for (j=l;j<=n;j++) v[i][j]=v[j][i]=0.0;
		}
		v[i][i]=1.0;
		g=rv1[i];
		l=i;
	}
	for (i=IMIN(m,n);i>=1;i--) {
		l=i+1;
		g=w[i];
		for (j=l;j<=n;j++) a[i][j]=0.0;
		if (g) {
			g=1.0/g;
			for (j=l;j<=n;j++) {
				for (s=0.0,k=l;k<=m;k++) s += a[k][i]*a[k][j];
				f=(s/a[i][i])*g;
				for (k=i;k<=m;k++) a[k][j] += f*a[k][i];
			}
			for (j=i;j<=m;j++) a[j][i] *= g;
		} else for (j=i;j<=m;j++) a[j][i]=0.0;
		++a[i][i];
	}
	for (k=n;k>=1;k--) {
		for (its=1;its<=30;its++) {
			flag=1;
			for (l=k;l>=1;l--) {
				nm=l-1;
				if ((float)(fabs(rv1[l])+anorm) == anorm) {
					flag=0;
					break;
				}
				if ((float)(fabs(w[nm])+anorm) == anorm) break;
			}
			if (flag) {
				c=0.0;
				s=1.0;
				for (i=l;i<=k;i++) {
					f=s*rv1[i];
					rv1[i]=c*rv1[i];
					if ((float)(fabs(f)+anorm) == anorm) break;
					g=w[i];
					h=pythag(f,g);
					w[i]=h;
					h=1.0/h;
					c=g*h;
					s = -f*h;
					for (j=1;j<=m;j++) {
						y=a[j][nm];
						z=a[j][i];
						a[j][nm]=y*c+z*s;
						a[j][i]=z*c-y*s;
					}
				}
			}
			z=w[k];
			if (l == k) {
				if (z < 0.0) {
					w[k] = -z;
					for (j=1;j<=n;j++) v[j][k] = -v[j][k];
				}
				break;
			}
			if (its == 30) return FAIL;//nrerror("no convergence in 30 svdcmp iterations");
			x=w[l];
			nm=k-1;
			y=w[nm];
			g=rv1[nm];
			h=rv1[k];
			f=((y-z)*(y+z)+(g-h)*(g+h))/(2.0*h*y);
			g=pythag(f,1.0);
			f=((x-z)*(x+z)+h*((y/(f+SIGN(g,f)))-h))/x;
			c=s=1.0;
			for (j=l;j<=nm;j++) {
				i=j+1;
				g=rv1[i];
				y=w[i];
				h=s*g;
				g=c*g;
				z=pythag(f,h);
				rv1[j]=z;
				c=f/z;
				s=h/z;
				f=x*c+g*s;
				g = g*c-x*s;
				h=y*s;
				y *= c;
				for (jj=1;jj<=n;jj++) {
					x=v[jj][j];
					z=v[jj][i];
					v[jj][j]=x*c+z*s;
					v[jj][i]=z*c-x*s;
				}
				z=pythag(f,h);
				w[j]=z;
				if (z) {
					z=1.0/z;
					c=f*z;
					s=h*z;
				}
				f=c*g+s*y;
				x=c*y-s*g;
				for (jj=1;jj<=m;jj++) {
					y=a[jj][j];
					z=a[jj][i];
					a[jj][j]=y*c+z*s;
					a[jj][i]=z*c-y*s;
				}
			}
			rv1[l]=0.0;
			rv1[k]=f;
			w[k]=x;
		}
	}
	return SUCCESS;
}

void LeastSquaresEvaluateBasisFunctions(float x, float p[], int pSize){
  location_t firstAnchorLocation=locations[0];//call LocationRefl.get(call AnchorHood.getNeighbor(0));
  location_t anchorLocation=locations[(int)x];//call LocationRefl.get(call AnchorHood.getNeighbor(x));
  p[1]=(float)(-2*(anchorLocation.pos.x-firstAnchorLocation.pos.x));
  p[2]=(float)(-2*(anchorLocation.pos.y-firstAnchorLocation.pos.y));
}


/*    This is the SVD algorithm from numerical recipes in c second edition*/
result_t LeastSquaresSolve(float x[], float y[], float sig[], int ndata, float a[], int ma, float **u, float **v, float w[], float *chisq)
{
	int j,i;
	float wmax,tmp,thresh,sum;
	float b[MAX_MEMBERS_AnchorHood+1], afunc[MAX_MEMBERS_AnchorHood+1];

	if(ndata > MAX_MEMBERS_AnchorHood+1)
		;
//		dbg(DBG_ERR, "too large matrix needed\n"); //not really gives any error info when make mica(2). some err handling necessary here

	
	for (i=1;i<=ndata;i++) {
		LeastSquaresEvaluateBasisFunctions(x[i],afunc,ma);
		tmp=1.0/sig[i];
		for (j=1;j<=ma;j++) u[i][j]=afunc[j]*tmp;
		b[i]=y[i]*tmp;
	}
        {
	  uint8_t i;
	  printf("z ");
	  for(i=1;i<=ndata;i++) {
	    uint8_t j;
	    for(j=1;j<=ma;j++) {
	      printf("%f ",u[i][j]);
	    }
	  }
	  printf("\n");
	}
	if(svdcmp(u,ndata,ma,w,v)==FAIL) return FAIL;
	wmax=0.0;
	for (j=1;j<=ma;j++)
		if (w[j] > wmax) wmax=w[j];
	thresh=TOL*wmax;
	for (j=1;j<=ma;j++)
		if (w[j] < thresh) w[j]=0.0;
	svbksb(u,w,v,ndata,ma,b,a); //@@
	*chisq=0.0;
	for (i=1;i<=ndata;i++) {
		LeastSquaresEvaluateBasisFunctions(x[i],afunc,ma);
		for (sum=0.0,j=1;j<=ma;j++) sum += a[j]*afunc[j];
		*chisq += (tmp=(y[i]-sum)/sig[i],tmp*tmp);
	}
	
	return SUCCESS;
}

main() {

  location_t positionEstimate;
  location_t anchorLocation,firstAnchorLocation;//=call LocationRefl.get(call AnchorHood.getNeighbor(0));
  distance_t anchorDistance,firstAnchorDistance;//=call DistanceRefl.get(call AnchorHood.getNeighbor(0));
    //all of the following matrix contruction is because I can't f**king malloc
    //and I need to use least squares, which should be able to take a variable
    //sized array (i.e. a float**) but c is dumb about multidimensional pointers

	//also, all arrays are 1-indexed in this section because nr is dumb
    float x[MAX_MEMBERS_AnchorHood], y[MAX_MEMBERS_AnchorHood], sig[MAX_MEMBERS_AnchorHood], a[3], w[3], chisq;
    float uData[MAX_MEMBERS_AnchorHood][3], vData[3][3], covMatData[3][3];
    float *uPointerArray[MAX_MEMBERS_AnchorHood],*vPointerArray[3], *covMatPointerArray[3];
    float **u,**v, **covMat;

    int count;
    int numAnchors = 3;
    
    for(count=0;count<3;count++) {
      distances[count].distance = 42;
      distances[count].stdv = 5;
      switch(count) {
      case 1:
	locations[count].pos.x = 0;
	locations[count].pos.y = 0;
	break;

      case 0:
	locations[count].pos.x = 0;
	locations[count].pos.y = 60;
	break;

      case 2:
	locations[count].pos.x = 60;
	locations[count].pos.y = 60;
	break;

      default:
	break;
      }
    }

    firstAnchorLocation = locations[0];
    firstAnchorDistance = distances[0];
    
  u=uPointerArray;
  v=vPointerArray;
  covMat=covMatPointerArray;
  for(count=0;count<numAnchors;count++){
	u[count]=&uData[count][0];
  }
  for(count=0;count<3;count++){
	v[count]=&vData[count][0];
	covMat[count]=&covMatData[count][0];
  }

  x[0] = y[0] = 0;
  
  //dbg(DBG_USR2,"LOCALIZATION : making the x and y (and sig) matrices\n");
  for(count=1;count<=numAnchors-1;count++){
    anchorLocation=locations[count];//call LocationRefl.get(call AnchorHood.getNeighbor(count));
    anchorDistance=distances[count];//call DistanceRefl.get(call AnchorHood.getNeighbor(count));
   x[count]=count;//this is the multidimensional trick mentioned in nr
   y[count]=(float)(square( anchorDistance.distance)
    -square( firstAnchorDistance.distance)
    -square( anchorLocation.pos.x)
    +square( firstAnchorLocation.pos.x)
    -square( anchorLocation.pos.y)
    +square( firstAnchorLocation.pos.y));
   sig[count]=anchorLocation.stdv.x+1;;
  }

  printf("x ");
  for(count=0;count<3;count++) {
    printf("%f ",x[count]);
  }
  printf("\n");


  printf("y ");
  for(count=0;count<3;count++) {
    printf("%f ",y[count]);
  }
  printf("\n");
  
  //dbg(DBG_USR2,"LOCALIZATION : solving linear system\n");
  if(LeastSquaresSolve(x,y,sig,numAnchors-1,a,2,u,v,w,&chisq)==SUCCESS){
    //dbg(DBG_USR2,"LOCALIZATION : finished solving linear system\n");
    positionEstimate.pos.x=(uint16_t)a[1];
    positionEstimate.pos.y=(uint16_t)a[2];

//	call LeastSquares.getCovarianceMatrix(v,2,w,covMat);
//    positionEstimate.stdv.x=sqrt(covMat[1][1]);
//    positionEstimate.stdv.y=sqrt(covMat[2][2]);
    //for now, we will estimate the location error to be the max of the errors used in locating it
    positionEstimate.stdv.x=0;
    positionEstimate.stdv.y=0;
	for(count=0;count<numAnchors;count++){
	  anchorLocation=locations[count];//call LocationRefl.get(call AnchorHood.getNeighbor(count));
	  anchorDistance=distances[count];//call DistanceRefl.get(call AnchorHood.getNeighbor(count));
      positionEstimate.stdv.x= positionEstimate.stdv.x > anchorDistance.stdv? (
		  positionEstimate.stdv.x > anchorLocation.stdv.x? (
			  positionEstimate.stdv.x > anchorLocation.stdv.y?
			  positionEstimate.stdv.x
			  : anchorLocation.stdv.y)
		      : anchorLocation.stdv.x)
    		  : anchorDistance.stdv;
	  positionEstimate.stdv.y=positionEstimate.stdv.x;
    }
  }
  else{
    printf("error\n");
/*      location_t currentPosition = call LocationAttr.get(); */
/*  	positionEstimate.pos.x=currentPosition.pos.x; */
/*  	positionEstimate.pos.y=currentPosition.pos.y; */
/*  	positionEstimate.stdv.x=65534; */
/*  	positionEstimate.stdv.y=65534; */
  }

  printf("distance: x %d y %d\n",positionEstimate.pos.x,positionEstimate.pos.y);
}
//  call LocationAttr.set(positionEstimate);

//d->myID=TOS_LOCAL_ADDRESS;
//d->location=positionEstimate;

