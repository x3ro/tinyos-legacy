package net.tinyos.tinydb;

/** SelExpr represents a selection expression;  selection expressions are of
    the form:

    WHERE (field fieldOp fieldConst) OP value
    
    Where field is a field in the query, value is an integral value,
    and op is a SelOp.
*/
public class SelExpr implements QueryExpr {
    public SelExpr(short field, SelOp op, short value) {
	this.field = field;
	this.op = op;
	this.value = value;

	this.fieldOp = ArithOps.NO_OP;
	this.fieldConst = 0;
    }

    public SelExpr(short field, String fieldOp, short fieldConst, SelOp op, short value) {
	this.field = field;
	this.fieldOp = ArithOps.getOp(fieldOp);
	this.fieldConst = fieldConst;
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

    public short getFieldConst() {
	return fieldConst;
    }

    public short getFieldOp() {
	return fieldOp;
    }
    
    public byte getSelOpCode() {
	return op.toByte();
    }

    public String toString() {
	return ("SelOp( (" + field + " " + ArithOps.getStringValue(fieldOp) + " " + fieldConst + ") " + op + " " + value + ")\n");
    }
    
    private short fieldConst;
    private short fieldOp;

    private short field;
    private SelOp op;
    private short value;

}
