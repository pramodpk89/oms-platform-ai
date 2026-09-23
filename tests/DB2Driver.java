package com.ibm.db2.jcc;

/** Loads the test driver under the production class name; test JAR only. */
public final class DB2Driver {
    static { try { Class.forName("OmsDb2Test"); } catch (ClassNotFoundException e) { throw new RuntimeException(e); } }
}
