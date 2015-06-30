// $Id: TASKQuery.java,v 1.2 2003/10/07 21:46:06 idgay Exp $

/*									tab:4
 * "Copyright (c) 2000-2003 The Regents of the University  of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 *
 * Copyright (c) 2002-2003 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
package net.tinyos.task.taskapi;

import java.util.*;

import java.io.*;
import net.tinyos.tinydb.*;

/**
 * Class that encapsulates a TASK query.  TASKServer assigns a new 
 * unique query id to TASKQuery whose queryId field is INVALID_QUERYID.
 * TASKQuery with a previous queryId can be resubmitted as long as no
 * other clients submit new queries since the TASKQuery was fetched from
 * the server.  Any methods that modifies TASKQuery will set the queryId
 * to INVALID_QUERYID.
 */
public class TASKQuery implements Serializable
{
	public static final int INVALID_QUERYID = -1;

	/**
	 * Constructor for TASKQuery.
	 *
	 * @param	selectEntries	expressions in select clause, 
	 * 							i.e., data to be collected.
	 * @param	predicates		predicates to be satisfied.
	 * @param	samplePeriod	sample period in milliseconds.
	 * @param	tableName		table name in TASK database for logging results
	 * 							null if you want the TASK server to pick a name
	 */
	public TASKQuery(Vector selectEntries, Vector predicates, int samplePeriod, String tableName) 
	{
		this.selectEntries = selectEntries;
		this.predicates = predicates;
		this.samplePeriod = samplePeriod;
		this.tableName = tableName;
		this.queryId = INVALID_QUERYID;
	};
	/**
	 * Constructor to convert from TinyDBQuery to TASKQuery.
	 * XXX should try to unify the two query classes
	 *
	 * @param	tinyDBQuery	TinyDBQuery representation of a TASK query.
	 * @param	queryId		the global query id.
	 * @param	tableName	table name in TASK database for logging results
	 */
	public TASKQuery(TinyDBQuery tinyDBQuery, int queryId, String tableName)
	{
		this.samplePeriod = tinyDBQuery.getEpoch();
		this.queryId = queryId;
		this.tinyDBQid = tinyDBQuery.qid;
		this.tableName = tableName;
		this.selectEntries = new Vector();
		this.predicates = new Vector();
		int i;
		for (i = 0; i < tinyDBQuery.numFields(); i++)
		{
			QueryField qf = tinyDBQuery.getField(i);
			int attrType = TASKTypes.tinyDBTypeToTASKType(qf.getType());
			addSelectEntry(new TASKAttrExpr(attrType, qf.getName()));
		}
		for (i = 0; i < tinyDBQuery.numExprs(); i++)
		{
			QueryExpr e = tinyDBQuery.getExpr(i);
			if (e.isAgg())
			{
				AggExpr ae = (AggExpr)e;
				AggOp aggOp = ae.getAgg();
				addSelectEntry(new TASKAggExpr(TASKAggInfo.aggNameFromOpCode(aggOp.toByte()), tinyDBQuery.getField(ae.getField()).getName(), new Integer(aggOp.getConst1()), new Integer(aggOp.getConst2())));
			}
		}
		for (i = 0; i < tinyDBQuery.numExprs(); i++)
		{
			QueryExpr e = tinyDBQuery.getExpr(i);
			if (e instanceof SelExpr)
			{
				SelExpr se = (SelExpr)e;
				QueryField qf = tinyDBQuery.getField(se.getField());
				int type = TASKTypes.tinyDBTypeToTASKType(qf.getType());
				addPredicate(new TASKOperExpr(TASKOperators.opTypeFromSelOp(se.getSelOpCode()), new TASKAttrExpr(type, qf.getName()), new TASKConstExpr(type, new Short(se.getValue()))));
			}
		}
	};
	/**
	 * Add a select entry to the query.
	 *
	 * @param	expr	an expression to be added as a new select entry.
	 */
	public void addSelectEntry(TASKExpr expr) 
	{ 
		selectEntries.add(expr); 
		this.queryId = INVALID_QUERYID;
	};
	/**
	 * Delete a select entry.
	 *
	 * @param	i	index of the select entry to be deleted.  It's 0-based.
	 */
	public void deleteSelectEntry(int i) 
	{ 
		selectEntries.remove(i); 
		this.queryId = INVALID_QUERYID;
	};
	/**
	 * Add a predicate to the query.
	 *
	 * @param	expr	an expression of type BOOL representing a predicate.
	 */
	public void addPredicate(TASKExpr expr) 
	{ 
		predicates.add(expr); 
		this.queryId = INVALID_QUERYID;
	};
	/**
	 * Delete a predicate.
	 *
	 * @param	i	index of the predicate to be deleted.  It's 0-based.
	 */
	public void deletePredicate(int i) 
	{ 
		predicates.remove(i); 
		this.queryId = INVALID_QUERYID;
	};
	/**
	 * Returns all the select entries.
	 *
	 * @return	a Vector of TASKExpr's.
	 */
	public Vector getSelectEntries() { return selectEntries; };
	/**
	 * Returns all predicates.
	 *
	 * @return	a Vector of TASKExpr's representing conjunction of a list of
	 *			boolean expressions.
	 */
	public Vector getPredicates() { return predicates; };
	/**
	 * Returns the sample period of the query in milliseconds.
	 */
	public int getSamplePeriod() { return samplePeriod; };
	/**
	 * Set sample period.
	 *
	 * @param	samplePeriod	sample period in milliseconds.
	 */
	public void setSamplePeriod(int samplePeriod) 
	{ 
		this.samplePeriod = samplePeriod; 
		this.queryId = INVALID_QUERYID;
	};
	/**
	 * Returns the table name where the query results will be logged.
	 */
	public String getTableName() { return tableName; };
	/**
	 * Set the table name where the query results will be logged.
	 */
	public void setTableName(String name) { tableName = name; };
	/**
	 * Returns the query id of the query if the query has already been
	 * assigned a query id by the TASKServer, otherwise INVALID_QUERYID.
	 */
	public int getQueryId() { return queryId; };

	public String toSQL()
	{
		String queryStr = "SELECT ";
		boolean notFirst = false;
		Iterator it;
		TASKExpr expr;
		for (it = selectEntries.iterator(); it.hasNext();)
		{
			expr = (TASKExpr)it.next();
			if (notFirst)
				queryStr += ",";
			queryStr += expr.toString();
			notFirst = true;
		}
		notFirst = false;
		if (predicates != null && predicates.size() > 0)
		{
			queryStr += " WHERE ";
			for (it = predicates.iterator(); it.hasNext(); )
			{
				expr = (TASKExpr)it.next();
				if (notFirst)
					queryStr += " AND ";
				queryStr += expr.toString();
				notFirst = true;
			}
		}
		queryStr += " SAMPLE PERIOD ";
		queryStr += samplePeriod;
		return queryStr;
	}

	// XXX this really should not be public, but TASKServer needs to use it
	public void setQueryId(int queryId)
	{
		this.queryId = queryId;
	}
	public void setTinyDBQid(byte tinyDBQid)
	{
		this.tinyDBQid = tinyDBQid;
	}

	private Vector	selectEntries;	// Vector of TASKExpr for select entries
	private Vector	predicates;		// Vector of TASKExpr for predicates
	private int		samplePeriod;	// sample period
	private int		queryId;		// query id
	private byte	tinyDBQid;		// TinyDB query id, 1-byte
	private	String	tableName;		// table name in TASK database
};
