/* Compile with 'gcc FloydWarshall.c' */

/* Run Floyd-Warshall's algorithm on a weighted directed graph. (HHu) */

#include <stdio.h>
#include <stdlib.h>
//#include <sys/time.h>
//#include <sys/resource.h>

int     n, m;  /* # of vertices, edges */

typedef float **Matrix;

#define infinity       1e6
#define MALLOC(t,n)    (t *) malloc( n*sizeof(t) ) 
#define CHECKPTR(p)    if (!p) Error("Out of memory")

void Error(char *text)
{ 
  printf("\nERROR: %s\n", text); exit(1);
}

/* /\* Returns amount of CPU time used by the process in milliseconds *\/ */
/* long get_cpu_time() */
/* { */
/*   struct rusage rusage; */
 
/*   getrusage ( RUSAGE_SELF, &rusage); */
/*   return (rusage.ru_utime.tv_sec * 1000 + (rusage.ru_utime.tv_usec/1000) */
/*           + rusage.ru_stime.tv_sec * 1000 + (rusage.ru_stime.tv_usec/1000) ); */
/* } */

Matrix mat_new( int dim )
{
  int i, j;
  Matrix A = MALLOC( float *, dim ); CHECKPTR( A );
  for ( i = 0; i < dim; i++ ) {
    A[i] = MALLOC( float, n );  CHECKPTR( A[i] );
  }
  return A;
}

void mat_free( Matrix A, int dim )
{
  int i;
  for ( i = 0; i < dim; i++ )
    free( A[i] );
  free( A );
}

Matrix mat_copy( Matrix A, int dim )
{
  int i, j;
  Matrix B = mat_new( dim );

  for ( i = 0; i < n; i++ )
    for ( j = 0; j < n; j++ )
      B[i][j] = A[i][j];

  return B;
}

Matrix Initialize()
{ 
  int i, j;
  Matrix W = mat_new( n );
  for ( i = 0; i < n; i++ )
    for ( j = 0; j < n; j++ )
      W[i][j] = ( i == j ? 0 : infinity );

  return W;
}

Matrix LoadGraph(char* filename)
{ 
  int i, j;
  float w;
  Matrix W;
  FILE *infile = fopen(filename,"r");
  if (!infile) Error("Could not open file");
  fscanf(infile,"%d %d", &n, &m);
  printf("Reading %s with %d vertices and %d edges \n", filename, n, m);
  W = Initialize(); 
  while (fscanf(infile,"%d %d %f",&i,&j,&w) != EOF)
    if ( i != j ) 
      W[i][j] = w;
  return W;
}      

Matrix FloydWarshall( Matrix W )
{
  /* Notice: we use the optimization from 26.2-2 and simply 
   * computes the shortest path matrix directly in place in D. 
   */

  Matrix D = mat_copy( W, n );
  int i, j, k;

  for ( k = 0; k < n; k++ )
    for ( i = 0; i < n; i++ )
      for ( j = 0; j < n; j++ )
	if (  D[i][j] > D[i][k] + D[k][j])
	  D[i][j] = D[i][k] + D[k][j];
  return D;
}

void DumpMatrix( Matrix A, FILE *fp )
{
  int i, j;
  for ( i = 0; i < n; i++ ) {
    for ( j = 0; j < n; j++ )
      fprintf( fp, "%6.1f  ", A[i][j] );
    fprintf( fp, "\n" );
  }
}

int main(int argc, char **argv)
{
  //  clock_t cl1, cl2;

  Matrix W = LoadGraph(argv[1]), D;

  //  cl1 = get_cpu_time ();
  D = FloydWarshall( W );
  //  cl2 = get_cpu_time ();
  if ( n < 100 )
    DumpMatrix( D, stdout );

  //  printf("\nTime: %.2f secs\n", (float)(cl2-cl1)/(float)1000);

  mat_free( W, n );
  mat_free( D, n );
  return 1;
}
