package net.tinyos.tinydb.topology.util;

import net.tinyos.tinydb.topology.Dialog.*;

public interface EdgeDialogContributor
{
	public ActivePanel GetProprietaryEdgeInfoPanel(Integer pSourceNodeNumber, Integer pDestinationNodeNumber);
}
