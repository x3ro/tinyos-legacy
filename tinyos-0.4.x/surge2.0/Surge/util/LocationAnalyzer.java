package Surge.util;

import java.util.*;

public interface LocationAnalyzer//this class serves as an "adapter" (i.e. an interface with methods)
{
	public double GetX(Integer nodeNumber);
	public double GetY(Integer nodeNumber);
	public void SetX(Integer nodeNumber, double pX);
	public void SetY(Integer nodeNumber, double pY);
	
	public double GetDistance(Integer sourceNodeNumber, Integer destinationNodeNumber);
	public void SetDistance(Integer sourceNodeNumber, Integer destinationNodeNumber, double pDistance);
	
	public Integer FindNearestNode(double x, double y);
	public Vector FindNearestEdge(double x, double y);
}