import java.io.*;
import java.nio.charset.StandardCharsets;
import java.sql.*;
import java.util.*;
import java.util.regex.Pattern;

/** No runtime dependency except IBM's JDBC driver. Java 8+. */
public final class OmsDb2 {
    static final Pattern FORBIDDEN = Pattern.compile("\\b(INSERT|UPDATE|DELETE|MERGE|UPSERT|DROP|ALTER|CREATE|TRUNCATE|CALL|EXECUTE|EXEC|GRANT|REVOKE|COMMIT|ROLLBACK|CONNECT|DISCONNECT|SET|INTO|NEXT|PREVIOUS|FINAL|OLD|NEW|EXPORT|IMPORT|LOAD|UNLOAD|ATTACH|DETACH)\\b");
    static String guard(String sql) {
        StringBuilder clean = new StringBuilder();
        for (int i = 0; i < sql.length();) {
            char c = sql.charAt(i);
            if (c == '\'' || c == '"') {
                char quote = c; boolean ended = false; i++;
                while (i < sql.length()) {
                    if (sql.charAt(i++) == quote) {
                        if (i < sql.length() && sql.charAt(i) == quote) { i++; continue; }
                        ended = true; break;
                    }
                }
                if (!ended) throw new IllegalArgumentException("Unclosed SQL quote.");
                clean.append(" Q ");
            } else if (c == '-' && i + 1 < sql.length() && sql.charAt(i + 1) == '-') {
                i += 2; while (i < sql.length() && sql.charAt(i) != '\n' && sql.charAt(i) != '\r') i++;
                clean.append(' ');
            } else if (c == '/' && i + 1 < sql.length() && sql.charAt(i + 1) == '*') {
                i += 2; int depth = 1;
                while (i < sql.length() && depth > 0) {
                    if (i + 1 < sql.length() && sql.startsWith("/*", i)) { depth++; i += 2; }
                    else if (i + 1 < sql.length() && sql.startsWith("*/", i)) { depth--; i += 2; }
                    else i++;
                }
                if (depth != 0) throw new IllegalArgumentException("Unclosed SQL comment.");
                clean.append(' ');
            } else { clean.append(c); i++; }
        }
        String normalized = clean.toString().trim().toUpperCase(Locale.ROOT);
        if (normalized.endsWith(";")) throw new IllegalArgumentException("Omit the SQL statement terminator.");
        if (normalized.indexOf(';') >= 0 || !normalized.matches("(?s)^(SELECT|WITH)\\b.*") || FORBIDDEN.matcher(normalized).find())
            throw new IllegalArgumentException("Only a single read-only SELECT or SELECT CTE is accepted.");
        return sql;
    }
    static String quote(String value) {
        if (value == null) return "null";
        StringBuilder s = new StringBuilder("\"");
        for (char c : value.toCharArray()) {
            if (c == '"' || c == '\\') s.append('\\').append(c);
            else if (c < 32) s.append(String.format("\\u%04x", (int)c));
            else s.append(c);
        }
        return s.append('"').toString();
    }
    static String required(Properties p, String key) {
        String v = p.getProperty(key);
        if (v == null || v.isEmpty()) throw new IllegalArgumentException("Missing " + key + ".");
        return v;
    }
    static int bounded(Properties p, String key, int fallback, int max) {
        int value = Integer.parseInt(p.getProperty(key, String.valueOf(fallback)));
        if (value < 1 || value > max) throw new IllegalArgumentException("Invalid " + key + ".");
        return value;
    }
    static void bind(PreparedStatement s, Properties p) throws SQLException {
        int count = Integer.parseInt(p.getProperty("parameterCount", "0"));
        for (int i = 0; i < count; i++) {
            String prefix = "parameter." + i + ".";
            String value = p.getProperty(prefix + "value", "");
            switch (required(p, prefix + "type")) {
                case "string": s.setString(i + 1, value); break;
                case "int": s.setInt(i + 1, Integer.parseInt(value)); break;
                case "long": s.setLong(i + 1, Long.parseLong(value)); break;
                case "decimal": s.setBigDecimal(i + 1, new java.math.BigDecimal(value)); break;
                case "date": s.setDate(i + 1, java.sql.Date.valueOf(value)); break;
                case "timestamp": s.setTimestamp(i + 1, Timestamp.valueOf(value)); break;
                case "boolean":
                    if (!value.equalsIgnoreCase("true") && !value.equalsIgnoreCase("false")) throw new IllegalArgumentException("Invalid boolean parameter.");
                    s.setBoolean(i + 1, Boolean.parseBoolean(value)); break;
                case "null": s.setNull(i + 1, Types.NULL); break;
                default: throw new IllegalArgumentException("Unsupported parameter type.");
            }
        }
    }
    static String run(Properties p) throws Exception {
        boolean probe = "probe".equals(p.getProperty("operation"));
        String sql = probe ? "" : guard(required(p, "sql"));
        if (!probe && !"true".equals(p.getProperty("readOnlyAccountVerified")))
            throw new IllegalArgumentException("DB2 queries require a verified SELECT-only account. Configure one before querying.");
        String host = required(p, "host");
        String database = required(p, "database");
        String schema = required(p, "schema");
        if (!host.matches("[A-Za-z0-9._-]+") || !database.matches("[A-Za-z0-9_]+") || !schema.matches("[A-Za-z_][A-Za-z0-9_]*"))
            throw new IllegalArgumentException("Invalid DB2 host, database, or schema.");
        int port = bounded(p, "port", 50000, 65535);
        int timeout = bounded(p, "timeout", 30, 300);
        int limit = bounded(p, "limit", 50, 1000);
        Class.forName(p.getProperty("driverClass", "com.ibm.db2.jcc.DB2Driver"));
        Properties auth = new Properties();
        auth.setProperty("user", required(p, "username"));
        auth.setProperty("password", required(p, "password"));
        auth.setProperty("currentSchema", schema);
        auth.setProperty("loginTimeout", "10");
        auth.setProperty("blockingReadConnectionTimeout", String.valueOf(timeout));
        DriverManager.setLoginTimeout(10);
        try (Connection c = DriverManager.getConnection("jdbc:db2://" + host + ":" + port + "/" + database, auth)) {
            if (probe) return "{\"status\":\"connected\",\"database\":" + quote(c.getMetaData().getDatabaseProductName()) + ",\"version\":" + quote(c.getMetaData().getDatabaseProductVersion()) + ",\"queryExecuted\":false}";
            c.setReadOnly(true); c.setAutoCommit(false);
            try {
                try (PreparedStatement s = c.prepareStatement(sql, ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY)) {
                    s.setQueryTimeout(timeout); s.setMaxRows(limit + 1); s.setFetchSize(Math.min(limit + 1, 100));
                    bind(s, p);
                    try (ResultSet r = s.executeQuery()) {
                        ResultSetMetaData m = r.getMetaData();
                        StringBuilder columns = new StringBuilder("[");
                        for (int j = 1; j <= m.getColumnCount(); j++) { if (j > 1) columns.append(','); columns.append(quote(m.getColumnLabel(j))); }
                        columns.append(']');
                        StringBuilder rows = new StringBuilder("[");
                        int count = 0; boolean truncated = false;
                        while (r.next()) {
                            if (count >= limit || rows.length() > 16000) { truncated = true; break; }
                            StringBuilder row = new StringBuilder("[");
                            for (int j = 1; j <= m.getColumnCount(); j++) {
                                if (j > 1) row.append(',');
                                String value;
                                int type = m.getColumnType(j);
                                if (type == Types.BLOB || type == Types.BINARY || type == Types.VARBINARY || type == Types.LONGVARBINARY) value = "[binary omitted]";
                                else if (type == Types.CLOB || type == Types.NCLOB || type == Types.LONGVARCHAR || type == Types.LONGNVARCHAR || type == Types.VARCHAR || type == Types.NVARCHAR || type == Types.CHAR || type == Types.NCHAR) {
                                    try (Reader reader = r.getCharacterStream(j)) {
                                        if (reader == null) value = null;
                                        else { char[] buffer = new char[513]; int n = 0, got; while (n < buffer.length && (got = reader.read(buffer, n, buffer.length - n)) > 0) n += got;
                                            value = new String(buffer, 0, Math.min(n, 512)); if (n > 512) { value += " [truncated]"; truncated = true; } }
                                    }
                                } else { value = r.getString(j); if (value != null && value.length() > 512) { value = value.substring(0, 512) + " [truncated]"; truncated = true; } }
                                row.append(quote(value));
                            }
                            row.append(']');
                            if (rows.length() + row.length() > 16000) { truncated = true; break; }
                            if (count++ > 0) rows.append(','); rows.append(row);
                        }
                        return "{\"status\":\"ok\",\"columns\":" + columns + ",\"rows\":" + rows.append(']') + ",\"rowCount\":" + count + ",\"truncated\":" + truncated + "}";
                    }
                }
            } finally { c.rollback(); }
        }
    }
    static Properties readInput(InputStream stream) throws IOException {
        BufferedReader reader = new BufferedReader(new InputStreamReader(stream, StandardCharsets.UTF_8));
        // .NET Framework can emit a preamble when Process.StandardInput is initialized.
        reader.mark(1); if (reader.read() != '\ufeff') reader.reset();
        Properties encoded = new Properties(); encoded.load(reader);
        Properties p = new Properties();
        for (String key : encoded.stringPropertyNames()) p.setProperty(key, new String(Base64.getDecoder().decode(encoded.getProperty(key)), StandardCharsets.UTF_8));
        return p;
    }
    public static void main(String[] args) {
        try {
            Properties p = readInput(System.in);
            String result = run(p);
            // Do not echo credentials returned by a query or a driver.
            for (String key : Arrays.asList("password")) if (p.getProperty(key) != null && !p.getProperty(key).isEmpty()) result = result.replace(quote(p.getProperty(key)).substring(1, quote(p.getProperty(key)).length() - 1), "[REDACTED]");
            System.out.println(result);
        } catch (SQLException e) {
            System.out.println("{\"status\":\"error\",\"error\":\"DB2 operation failed\",\"sqlState\":" + quote(e.getSQLState()) + ",\"code\":" + e.getErrorCode() + "}"); System.exit(1);
        } catch (IllegalArgumentException e) {
            System.out.println("{\"status\":\"error\",\"error\":" + quote(e.getMessage()) + "}"); System.exit(1);
        } catch (Exception e) {
            System.out.println("{\"status\":\"error\",\"error\":\"Check Java, driver, and connection configuration\"}"); System.exit(1);
        }
    }
}
