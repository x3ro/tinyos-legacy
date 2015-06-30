package isis.nest.geneticoptimizer;

import isis.nest.math.RandomSingleton;

import java.util.Arrays;
import java.util.Random;


/**
 * Optimizer is a genetic algorithm based general optimizer.
 * To solve an optimization problem with it the followings have to be done:
 * - Implement the Problem interface to describe the problem
 * - Derive a class from Genotype to implement a possible solution of 
 *   the problem
 * - call this optimzer 
 */
public class Optimizer 
{
    protected Problem        problem;
    protected int            populationSize;
    protected int            subPopulationSize;
    protected Genotype[]     population;
    protected Genotype       bestSolution;
    protected Genotype[]     subPopulation;
    protected int            bestIndNum;
    protected int            firstBadInd;
    protected double         maxFitness;
    protected Random         rand;
    protected int            evaluations;
    protected int            logFreq;
    protected int            lastLog;       
    
    /**
     * The constructor.
     * 
     * @param problem The problem to solve. 
     * @param populationSize Population size. For more complex problems 
     *        larger numbers recommended. 
     * @param subPopulationSize Recomended value for subPopulationSize is
     *        populationSize/10. If it is larger optimization moves faster 
     *        but can stuck on lockal maxima easier. 
     */
    public Optimizer( Problem problem, int populationSize, int subPopulationSize )
        throws Exception
    {
        if( populationSize < 10 || subPopulationSize < 10 )
            throw new Exception("too small population!");
        
        rand = RandomSingleton.instance();
                       
        this.problem           = problem;
        this.populationSize    = populationSize;
        this.subPopulationSize = subPopulationSize;
        
        evaluations = 0;
        lastLog     = 0;
        logFreq     = 0;
        
        population = new Genotype[populationSize];
        maxFitness = -Double.MAX_VALUE;
        for( int i=0; i<populationSize; ++i )
        {
            population[i] = problem.createRandomSolution();
            population[i].fitness = problem.evaluteSolution( population[i] );
            stepEvaluations();
            if( population[i].fitness > maxFitness )
            {
                maxFitness   = population[i].fitness;
                bestSolution = population[i]; 
            }
        }
        
        subPopulation = new Genotype[subPopulationSize];
        
        bestIndNum  = (int)(0.2 * subPopulationSize + 0.5);
        firstBadInd = subPopulationSize - bestIndNum;
    }  
    
    protected void step()
    {
        int i,j;
        
        // select random subpopulation
        for( i=0; i<subPopulationSize; ++i )
            subPopulation[i] = population[rand.nextInt(populationSize)];

        // sort subpopulation            
        Arrays.sort(subPopulation);
        
        // generate new individuals
        for( i=firstBadInd; i<subPopulationSize; ++i )
        {
            Genotype parent1 = subPopulation[rand.nextInt(bestIndNum)];
            Genotype parent2 = subPopulation[rand.nextInt(bestIndNum)];
            Genotype child   = subPopulation[i];
            
            if( child != bestSolution && child != parent1 && child != parent2 && parent1 != parent2 )
            {           
                child.derive( parent1, parent2 );
                subPopulation[i].fitness = problem.evaluteSolution( subPopulation[i] );
                stepEvaluations();
                            
                if( subPopulation[i].fitness > maxFitness )
                {
                    maxFitness   = subPopulation[i].fitness;
                    bestSolution = subPopulation[i]; 
                } 
            }
        }
    }
    
    /**
     * Returns back the best solution found so far.
     * @return The best solution.
     */
    public Genotype getBestSolution()
    {
        return bestSolution;
    }
    
    /**
     * Returns back the best fitness value found so far.
     * @return The best fitness value.
     */
    public double getBestFitness()
    {
        return maxFitness;
    }
    
    /**
     * Runs the optimization. 
     * @param evalNum Number of solution evaluations.
     * @param logFreq Frequency of logging, number of evaluations and the 
     *        best fitness is logged. Specify 0 to disable logging.
     */
    public void run( int evalNum, int logFreq )
    {
        run( evalNum, logFreq, Double.MAX_VALUE );
    }        
    
    /**
     * Runs the optimization. 
     * @param evalNum Number of solution evaluations.
     * @param logFreq Frequency of logging, number of evaluations and the 
     *        best fitness is logged. Specify 0 to disable logging.
     * @param fitnessThreshold Running is stop if best fitness reach this 
     *        value. 
     */    
    public void run( int evalNum, int logFreq, double fitnessThreshold )
    {
        evaluations = 0;
        this.logFreq = logFreq;
        while( evaluations <= evalNum && maxFitness<fitnessThreshold )
            step();
    }
    
    protected void stepEvaluations()
    {    
        evaluations++;    
        lastLog++;
        if( logFreq != 0 )
        {
            if( lastLog >= logFreq )
            {
                lastLog = 0;
                System.out.println( evaluations + "\t" + maxFitness );
            }        
        }        
    }
}
