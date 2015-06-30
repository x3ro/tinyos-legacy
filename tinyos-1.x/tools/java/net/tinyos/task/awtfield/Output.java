package net.tinyos.task.awtfield;

import java.awt.*;
import java.awt.event.*;
import java.util.*;
import java.text.*;
import net.tinyos.message.*;

class Output {
    Tool parent;
    String title, now;
    Hashtable entries = new Hashtable();
    boolean first, displayed;

    Output(Tool parent, String title) {
	this.parent = parent;
	this.title = title;
	this.now = new SimpleDateFormat("H:mm:ss").format(new Date());
	this.first = this.displayed = false;
    }

    synchronized void activate(boolean first) {
	this.displayed = true;
	this.first = first;
	redisplay();
    }

    synchronized void deactivate() {
	this.displayed = false;
    }

    synchronized void add(int moteId, String msg) {
	//System.out.println("" + moteId + " " + msg);
	entries.put(new Integer(moteId), msg);
	if (displayed)
	    redisplay();
    }

    void redisplay() {
	String actualTitle;

	if (first) {
	    parent.cmdNameElement.setColor(Color.red);
	    actualTitle = title;
	}
	else {
	    parent.cmdNameElement.setColor(Color.black);
	    actualTitle = title + " @ " + now;
	}
	parent.cmdNameElement.setText(actualTitle);

	int[] keys = new int[entries.size()];
	Enumeration e;
	int i;
	for (i = 0, e = entries.keys(); e.hasMoreElements(); i++)
	    keys[i] = ((Integer)(e.nextElement())).intValue();
	IntSort.qsort(keys);

	StringBuffer contents = new StringBuffer();
	for (i = 0; i < keys.length; i++)
	    contents.append("" + keys[i]).append(": ").
		append(entries.get(new Integer(keys[i]))).append("\n");

	//System.out.println("contents: " + contents);
	parent.outputElement.setText(contents.toString());
    }

    /* Quicksort debugging */
    public static void main(String[] args) {
	/*
	int[] ia = new int[args.length];

	for (int i = 0; i < args.length; i++)
	    try {
		ia[i] = Integer.decode(args[i]).intValue();
	    } catch (NumberFormatException e) { }
	IntSort.qsort(ia);
	for (int i = 0; i < args.length; i++)
	    System.out.println("" + ia[i]);
	*/
	int n = 0, m = 0;
	try {
	    n = Integer.decode(args[0]).intValue();
	    m = Integer.decode(args[0]).intValue();
	} catch (NumberFormatException e) { }
	int[] ia = new int[n];
	Random r = new Random(n * m);
	for (int i = 0; i < m; i++) {
	    for (int j = 0; j < n; j++)
		ia[j] = r.nextInt();
	    IntSort.qsort(ia);
	    for (int j = 0; j < n - 1; j++) {
		//System.out.print("" + ia[j]);
		if (ia[j] > ia[j + 1]) {
		    System.out.println("oops");
		    System.exit(2);
		}
	    }
	    //System.out.println();
	}
    }
}

// No sorting in Java 1.1. So here we go for the twenty millionth time...
// (and the thirty millionth bug)
class IntSort {
    static void selectPivot(int[] v, int s, int e) {
	// move pivot to v[s]. here we just use v[s] as the pivot
    }

    static void qsort(int[] v, int s, int e) {
	if (s + 1 >= e) // 1 element
	    return;

	selectPivot(v, s, e);
	int pivot = v[s];
	int s2 = s + 1, e2 = e;

	// if s2 < e2, then all values from s + 1 to s2 are <= pivot and
	// all values from e2 to e - 1 are > pivot
	while (s2 < e2) {
	    if (v[s2] > pivot) { // move to 2nd half
		int tmp = v[s2];
		v[s2] = v[--e2];
		v[e2] = tmp;
	    }
	    else
		s2++;
	}
	// is s2 (== e2) < or >= than the pivot ?
	//System.out.println("" + s + " " + e + " " + s2 + " " + e2);
	if (s2 == e || v[s2] > pivot)
	    s2--;
	// stick pivot at s2
	int tmp = v[s2];
	v[s2] = pivot;
	v[s] = tmp;

	qsort(v, s, s2);
	qsort(v, s2 + 1, e);
    }

    static void qsort(int[] v) {
	qsort(v, 0, v.length);
    }
}
