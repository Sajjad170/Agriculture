import 'dart:io';

const _backendPort = 3001;

void main() async {
  final server = await HttpServer.bind('0.0.0.0', 5000);
  print('Server started on port 5000');
  print('API proxy: /api/* → http://localhost:$_backendPort');

  await for (final request in server) {
    _handleRequest(request);
  }
}

Future<void> _handleRequest(HttpRequest request) async {
  final path = request.uri.path;

  // Proxy /api/* and /uploads/* to Node.js backend on port 3001
  if (path.startsWith('/api/') || path.startsWith('/uploads/')) {
    await _proxyRequest(request);
    return;
  }

  // APK build status endpoint
  if (path == '/apk-status') {
    final log = File('/home/runner/apk_build.log');
    final content = await log.exists() ? await log.readAsString() : 'APK build not started yet.';
    request.response.headers.set('content-type', 'text/plain; charset=utf-8');
    request.response.headers.set('Access-Control-Allow-Origin', '*');
    request.response.write(content);
    await request.response.close();
    return;
  }

  // Serve Flutter web files
  var filePath = path == '/' ? '/index.html' : path;
  final file = File('.$filePath');

  // CORS headers for all responses
  request.response.headers.set('Access-Control-Allow-Origin', '*');
  request.response.headers.set('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
  request.response.headers.set('Access-Control-Allow-Headers', 'Content-Type, Authorization');

  if (request.method == 'OPTIONS') {
    request.response.statusCode = 200;
    await request.response.close();
    return;
  }

  if (await file.exists()) {
    request.response.headers.set('content-type', _contentType(filePath));
    await file.openRead().pipe(request.response);
  } else {
    final index = File('./index.html');
    request.response.headers.set('content-type', 'text/html; charset=utf-8');
    await index.openRead().pipe(request.response);
  }
}

Future<void> _proxyRequest(HttpRequest request) async {
  final client = HttpClient();
  try {
    final backendUri = Uri(
      scheme: 'http',
      host: 'localhost',
      port: _backendPort,
      path: request.uri.path,
      query: request.uri.query.isEmpty ? null : request.uri.query,
    );

    final proxyReq = await client.openUrl(request.method, backendUri);

    // Copy request headers (skip host)
    request.headers.forEach((name, values) {
      if (name.toLowerCase() != 'host') {
        for (final v in values) proxyReq.headers.add(name, v);
      }
    });

    // Stream request body
    await for (final chunk in request) {
      proxyReq.add(chunk);
    }
    final proxyRes = await proxyReq.close();

    request.response.statusCode = proxyRes.statusCode;

    // Copy response headers
    proxyRes.headers.forEach((name, values) {
      if (name.toLowerCase() != 'transfer-encoding') {
        for (final v in values) request.response.headers.add(name, v);
      }
    });

    // CORS headers
    request.response.headers.set('Access-Control-Allow-Origin', '*');

    await proxyRes.pipe(request.response);
  } catch (e) {
    print('Proxy error: $e');
    request.response.statusCode = 502;
    request.response.write('{"error":"Backend unavailable"}');
    await request.response.close();
  } finally {
    client.close();
  }
}

String _contentType(String path) {
  if (path.endsWith('.html')) return 'text/html; charset=utf-8';
  if (path.endsWith('.js')) return 'application/javascript';
  if (path.endsWith('.css')) return 'text/css';
  if (path.endsWith('.png')) return 'image/png';
  if (path.endsWith('.ico')) return 'image/x-icon';
  if (path.endsWith('.json')) return 'application/json';
  if (path.endsWith('.bin')) return 'application/octet-stream';
  if (path.endsWith('.wasm')) return 'application/wasm';
  if (path.endsWith('.svg')) return 'image/svg+xml';
  if (path.endsWith('.ttf') || path.endsWith('.otf') || path.endsWith('.woff2')) return 'font/otf';
  if (path.endsWith('.apk')) return 'application/vnd.android.package-archive';
  return 'application/octet-stream';
}
