package isis.nest.geneticoptimizer;

/**
 * Problem is an interface for optimization problems.
 */
public interface Problem 
{
    /**
     * Creates a uniformly distributed random solution over the search space.
     * @return the created random solution.
     */

    public Genotype createRandomSolution    ();
    
    /**
     * Evalutes the given solution and returns back its fitness. The higher 
     * the fitness the better the solution is. 
     * Optimizer maximizes the fitnes. 
     * @param sol The solution to evaluate.
     * @return The fitness of the solution.
     */
    
    public double   evaluteSolution         ( Genotype sol );
}
