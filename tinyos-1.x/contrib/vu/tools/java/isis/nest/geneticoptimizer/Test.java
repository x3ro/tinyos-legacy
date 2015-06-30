package isis.nest.geneticoptimizer;

import isis.nest.geneticoptimizer.samples.packing.PackingProblem;
import isis.nest.math.RandomSingleton;

/**
 * This is a test class for the genetic optimizer
 * A packing problem is generated with 200 object and solved with the 
 * optimzer
 */
public class Test 
{
    public static void main(String[] args) throws Exception
    {
        RandomSingleton.instance().setSeed( 0 );
               
        PackingProblem p = new PackingProblem( 200 );
        
        RandomSingleton.instance().setSeed( System.currentTimeMillis() );
        
        Optimizer opt = new Optimizer( p, 5000, 500 );        
        opt.run( 500000, 5000 );               
        
        System.out.println("done");        
    }
}
