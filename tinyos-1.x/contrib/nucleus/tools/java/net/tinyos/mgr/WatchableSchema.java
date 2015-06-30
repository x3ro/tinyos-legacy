import java.util.*;
import java.io.*;

public class WatchableSchema {
  private List watchables = new LinkedList();
  public boolean isRAMQuery = false;

  public WatchableSchema() {

  }

  public void setRAMQuery() {
    isRAMQuery = true;
  }

  public boolean isRAMQuery() {
    return isRAMQuery;
  }

  public List getWatchables() {
    return watchables;
  }

  public Watchable getWatchable(String name) {
    for(Iterator it = watchables.iterator(); it.hasNext(); ) {
      Watchable w = (Watchable)it.next();
      if (w.getName().equals(name)) {
	return w;
      }
    }
    return null;
  }

  public void loadSchema(String schemaFilename) throws IOException {

    BufferedReader in = new BufferedReader(new FileReader(schemaFilename));
    String str;
    while ((str = in.readLine()) != null) {
      processSchemaEntry(str);
    }
    in.close();
    Collections.sort(watchables);
  }

  private void processSchemaEntry(String line) {
    String[] tokens = line.split("\\s+");

    /* XXX: insert different subclasses of Watchable for different types */

    Watchable w = new Watchable(tokens[0],
				Integer.parseInt(tokens[1]),
				Integer.parseInt(tokens[2]),
				tokens[3]);

    watchables.add(w);
  }
}





