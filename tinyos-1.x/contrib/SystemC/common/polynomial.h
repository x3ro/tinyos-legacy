typedef struct {
  uint8_t degree;
  float coefficients[0];
} polynomial_t;

typedef struct {
  uint8_t degree;
  float coefficients[1];
} polynomialD1_t;

typedef struct {
  uint8_t degree;
  float coefficients[2];
} polynomialD2_t;


float polynomialEval(float x, polynomial_t *polynomial)
{
  uint16_t i, j;
  float y=0, term;
  for(i=0;i<polynomial->degree;i++)
    {
      term=polynomial->coefficients[i];
      for(j=0; j<i; j++)
	{
	  term*=x;
	}
      y+=term;
    }
  return y;
}





