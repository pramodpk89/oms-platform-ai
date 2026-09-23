import com.sun.net.httpserver.*;
import java.net.*;
import java.nio.charset.StandardCharsets;
import java.nio.file.*;
import java.io.*;
import java.util.concurrent.atomic.AtomicInteger;

/** Loopback-only fixture; never connects to OMS. */
public final class MockServer {
    public static void main(String[] args) throws Exception {
        HttpServer server = HttpServer.create(new InetSocketAddress("127.0.0.1", 0), 0);
        AtomicInteger writes = new AtomicInteger();
        server.createContext("/", e -> {
            String path = e.getRequestURI().getPath(); int status = 200; String body;
            if (path.equals("/api/echo")) { body = "{\"authorization\":\"" + e.getRequestHeaders().getFirst("Authorization") + "\",\"secret\":\"fixture-password\",\"result\":\"ok\"}"; }
            else if (path.equals("/api/write")) { writes.incrementAndGet(); body = "{\"result\":\"changed\"}"; }
            else if (path.equals("/api/count")) { body = String.valueOf(writes.get()); }
            else if (path.equals("/api/redirect")) { status = 302; e.getResponseHeaders().add("Location", "/api/write"); body = "redirect"; }
            else if (path.equals("/api/error")) { status = 400; body = "{\"error\":\"invalid input\"}"; }
            else if (path.equals("/api/large")) { StringBuilder b = new StringBuilder(); for (int i=0;i<6000;i++) b.append('x'); body = b.toString(); }
            else if (path.equals("/api/empty")) { body = ""; }
            else if (path.equals("/api/payload")) {
                ByteArrayOutputStream data = new ByteArrayOutputStream(); byte[] b = new byte[512]; int n;
                while ((n = e.getRequestBody().read(b)) > 0) data.write(b, 0, n);
                body = new String(data.toByteArray(), StandardCharsets.UTF_8);
            }
            else if (path.equals("/api/slow")) {
                e.sendResponseHeaders(200, 1000); e.getResponseBody().write('x'); e.getResponseBody().flush();
                try { Thread.sleep(2000); } catch (InterruptedException ignored) {}
                e.close(); return;
            }
            else if (path.equals("/tester")) {
                e.getResponseHeaders().add("Content-Type", "text/html; charset=utf-8");
                body = "<!doctype html><title>Mock API Tester</title><h1>Mock API Tester — no OMS connection</h1><label>Operation<select id='operation'><option>Inspect</option><option>Cancel</option></select></label><label>Input XML<textarea id='input'></textarea></label><button onclick=\"document.getElementById('result').textContent=document.getElementById('operation').value === 'Cancel' ? 'MOCK: cancelled TEST-1' : 'MOCK: TEST-1 status Created'\">Invoke</button><p id='result' role='status'></p>";
            } else { status = 404; body = "not found"; }
            byte[] bytes = body.getBytes(StandardCharsets.UTF_8);
            e.sendResponseHeaders(status, bytes.length == 0 ? -1 : bytes.length);
            try (OutputStream out = e.getResponseBody()) { out.write(bytes); }
        });
        server.start();
        Files.write(Paths.get(args[0]), String.valueOf(server.getAddress().getPort()).getBytes(StandardCharsets.UTF_8));
    }
}
