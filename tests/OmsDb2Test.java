import java.lang.reflect.*;
import java.sql.*;
import java.util.*;
import java.io.StringReader;

public final class OmsDb2Test implements Driver {
    static int passed, rollbacks, executions;
    static boolean readOnly, autoCommit, failQuery;
    static int maxRows, timeout;
    static Object bound;
    static { try { DriverManager.registerDriver(new OmsDb2Test()); } catch (SQLException e) { throw new RuntimeException(e); } }
    static void check(boolean ok, String message) { if (!ok) throw new AssertionError(message); passed++; }
    static void blocked(String sql) { try { OmsDb2.guard(sql); throw new AssertionError("Accepted unsafe SQL: " + sql); } catch (IllegalArgumentException expected) { passed++; } }
    static Object proxy(Class<?> type, InvocationHandler h) { return Proxy.newProxyInstance(OmsDb2Test.class.getClassLoader(), new Class<?>[]{type}, h); }
    static Object fallback(Method m) { if (m.getReturnType() == boolean.class) return false; if (m.getReturnType() == int.class) return 0; return null; }
    public Connection connect(String url, Properties p) {
        if (!acceptsURL(url)) return null;
        return (Connection)proxy(Connection.class, (o,m,a) -> {
            switch (m.getName()) {
                case "setReadOnly": readOnly = (boolean)a[0]; return null;
                case "setAutoCommit": autoCommit = (boolean)a[0]; return null;
                case "rollback": rollbacks++; return null;
                case "prepareStatement": return statement();
                case "getMetaData": return proxy(DatabaseMetaData.class, (x,n,b) -> n.getName().equals("getDatabaseProductName") ? "Mock DB2" : "test");
                default: return fallback(m);
            }
        });
    }
    static PreparedStatement statement() {
        return (PreparedStatement)proxy(PreparedStatement.class, (o,m,a) -> {
            switch (m.getName()) {
                case "setMaxRows": maxRows = (int)a[0]; return null;
                case "setQueryTimeout": timeout = (int)a[0]; return null;
                case "setString": bound = a[1]; return null;
                case "executeQuery":
                    executions++;
                    if (failQuery) throw new SQLException("mock-secret", "42000", -1);
                    final int[] row = {0};
                    return proxy(ResultSet.class, (x,n,b) -> {
                        switch (n.getName()) {
                            case "next": return ++row[0] <= 3;
                            case "getMetaData": return proxy(ResultSetMetaData.class, (y,k,c) -> {
                                if (k.getName().equals("getColumnCount")) return 2;
                                if (k.getName().equals("getColumnLabel")) return (int)c[0] == 1 ? "VALUE" : "NUMBER";
                                if (k.getName().equals("getColumnType")) return (int)c[0] == 1 ? Types.VARCHAR : Types.INTEGER;
                                return fallback(k);
                            });
                            case "getCharacterStream": return new StringReader("row-" + row[0]);
                            case "getString": return "42";
                            default: return fallback(n);
                        }
                    });
                default: return fallback(m);
            }
        });
    }
    public boolean acceptsURL(String url) { return url.startsWith("jdbc:db2://"); }
    public DriverPropertyInfo[] getPropertyInfo(String u, Properties p) { return new DriverPropertyInfo[0]; }
    public int getMajorVersion() { return 1; }
    public int getMinorVersion() { return 0; }
    public boolean jdbcCompliant() { return false; }
    public java.util.logging.Logger getParentLogger() { return java.util.logging.Logger.getGlobal(); }
    public static void main(String[] args) throws Exception {
        for (String preamble : Arrays.asList("", "\ufeff")) {
            Properties input = OmsDb2.readInput(new java.io.ByteArrayInputStream((preamble + "host=bG9jYWxob3N0\n").getBytes(java.nio.charset.StandardCharsets.UTF_8)));
            check("localhost".equals(input.getProperty("host")), "UTF-8 input with optional Windows BOM");
        }
        for (String sql : Arrays.asList("SELECT * FROM T", "with x as (select * from t) select * from x", "-- comment\nSELECT 'DELETE; it''s fine', \"UPDATE\" FROM T", "/* a /* b */ c */ SELECT * FROM T")) check(OmsDb2.guard(sql).equals(sql), "Read query changed");
        for (String sql : Arrays.asList("DELETE FROM T", "SELECT * FROM T; DELETE FROM T", "SELECT * FROM FINAL TABLE (DELETE FROM T)", "WITH x AS (DELETE FROM T) SELECT * FROM x", "SELECT NEXT VALUE FOR S FROM T", "CALL X()", "SELECT * FROM T FOR UPDATE", "SELECT * INTO X FROM T", "SELECT 'unterminated", "SELECT * /* unclosed", "VALUES 1", "SELECT * FROM T;", "GRANT SELECT ON T TO X")) blocked(sql);
        check(OmsDb2.quote("a\"\n\\").equals("\"a\\\"\\u000a\\\\\""), "JSON escaping");
        Properties p = new Properties();
        p.setProperty("driverClass", "OmsDb2Test"); p.setProperty("host", "localhost"); p.setProperty("database", "TEST"); p.setProperty("schema", "TEST"); p.setProperty("username", "test"); p.setProperty("password", "test"); p.setProperty("sql", "SELECT * FROM T WHERE ID = ?"); p.setProperty("limit", "2"); p.setProperty("parameterCount", "1"); p.setProperty("parameter.0.type", "string"); p.setProperty("parameter.0.value", "x' OR 1=1");
        try { OmsDb2.run(p); throw new AssertionError("Unverified account accepted"); } catch (IllegalArgumentException expected) { passed++; }
        check(executions == 0, "Rejected request executed SQL");
        p.setProperty("readOnlyAccountVerified", "true");
        String result = OmsDb2.run(p);
        check(readOnly && !autoCommit, "Read-only transaction"); check(maxRows == 3 && timeout == 30, "Query bounds"); check(bound.equals("x' OR 1=1"), "Value was not bound"); check(result.contains("\"rowCount\":2") && result.contains("\"truncated\":true"), "Result bounds"); check(rollbacks == 1, "Rollback on success");
        check(result.contains("\"row-1\",\"42\""), "Text and numeric result conversion");
        failQuery = true;
        try { OmsDb2.run(p); throw new AssertionError("Query failure missing"); } catch (SQLException expected) { passed++; }
        check(rollbacks == 2, "Rollback on failure");
        p.setProperty("operation", "probe"); p.setProperty("readOnlyAccountVerified", "false"); int before = executions;
        check(OmsDb2.run(p).contains("\"queryExecuted\":false") && executions == before, "Probe executed query");
        System.out.println("Java checks passed: " + passed);
    }
}
