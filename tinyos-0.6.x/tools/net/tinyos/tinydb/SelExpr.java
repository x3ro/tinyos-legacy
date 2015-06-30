package net.tinyos.tinydb;

/** SelExpr represents a selection expression;  selection expressions are of
    the form:

    WHERE field OP value
    
    Where field is a field in the query, value is an integral value,
    and op is a SelOp.
*/
public class SelExpr implements QueryExpr {
    public SelExpr(short field, SelOp op, short value) {
	this.field = field;
	this.op = op;
	this.value = value;
    }

    public boolean isAgg() {
	return false;
    }
    public short getField() {
	return field;
    }

    public short getValue() {
	return value;
    }

    public byte getSelOpCode() {
	return op.toByte();
    }
    
    private short field;
    private SelOp op;
    private short value;

}
