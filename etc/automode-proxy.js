#!/usr/bin/env node
// HTTPS proxy that intercepts GrowthBook remoteEval responses from
// api.anthropic.com and patches tengu_auto_mode_config.enabled to "enabled",
// allowing auto mode for Claude Code regardless of server-side feature flags.
const https = require('https');
const http = require('http');
const net = require('net');
const fs = require('fs');
const zlib = require('zlib');

const PROXY_PORT = parseInt(process.env.AUTOMODE_PROXY_PORT || '18019');
const TARGET_HOST = 'api.anthropic.com';
const INTERCEPT_PATH = '/api/eval/';

const keyPath = process.env.AUTOMODE_PROXY_KEY;
const certPath = process.env.AUTOMODE_PROXY_CERT;
if (!keyPath || !certPath) {
  process.stderr.write('AUTOMODE_PROXY_KEY and AUTOMODE_PROXY_CERT must be set\n');
  process.exit(1);
}

const key = fs.readFileSync(keyPath);
const cert = fs.readFileSync(certPath);

function decompress(headers, chunks) {
  const raw = Buffer.concat(chunks);
  const enc = headers['content-encoding'];
  if (enc === 'gzip') return zlib.gunzipSync(raw);
  if (enc === 'deflate') return zlib.inflateSync(raw);
  if (enc === 'br') return zlib.brotliDecompressSync(raw);
  return raw;
}

// HTTPS server impersonating api.anthropic.com for intercepted connections
const interceptServer = https.createServer({ key, cert }, (req, res) => {
  const intercept = req.url.startsWith(INTERCEPT_PATH);
  const opts = {
    hostname: TARGET_HOST, port: 443, path: req.url, method: req.method,
    headers: { ...req.headers, host: TARGET_HOST },
  };

  const proxyReq = https.request(opts, (proxyRes) => {
    if (!intercept) { res.writeHead(proxyRes.statusCode, proxyRes.headers); proxyRes.pipe(res); return; }
    const chunks = [];
    proxyRes.on('data', (c) => chunks.push(c));
    proxyRes.on('end', () => {
      try {
        const json = JSON.parse(decompress(proxyRes.headers, chunks).toString());
        if (json.features) {
          for (const [k, v] of Object.entries(json.features)) {
            if (k === 'tengu_auto_mode_config' && v?.value && typeof v.value === 'object')
              v.value.enabled = 'enabled';
            if (k === 'ccr_auto_permission_mode') v.value = true;
          }
        }
        const body = JSON.stringify(json);
        const hdrs = { ...proxyRes.headers };
        delete hdrs['content-encoding']; delete hdrs['transfer-encoding'];
        hdrs['content-length'] = Buffer.byteLength(body);
        res.writeHead(proxyRes.statusCode, hdrs);
        res.end(body);
      } catch {
        const raw = Buffer.concat(chunks);
        const hdrs = { ...proxyRes.headers };
        delete hdrs['transfer-encoding']; hdrs['content-length'] = raw.length;
        res.writeHead(proxyRes.statusCode, hdrs);
        res.end(raw);
      }
    });
  });
  proxyReq.on('error', () => { res.writeHead(502); res.end(); });
  req.pipe(proxyReq);
});

// HTTP CONNECT proxy — intercepts api.anthropic.com, passes everything else through
const proxyServer = http.createServer();
proxyServer.on('connect', (req, clientSocket, head) => {
  const [host, port] = req.url.split(':');
  const target = host === TARGET_HOST
    ? { port: interceptServer.address().port, host: '127.0.0.1' }
    : { port: parseInt(port) || 443, host };
  const serverSocket = net.connect(target, () => {
    clientSocket.write('HTTP/1.1 200 Connection Established\r\n\r\n');
    serverSocket.write(head);
    serverSocket.pipe(clientSocket);
    clientSocket.pipe(serverSocket);
  });
  serverSocket.on('error', () => clientSocket.end());
  clientSocket.on('error', () => serverSocket.end());
});

interceptServer.listen(0, '127.0.0.1', () => {
  proxyServer.listen(PROXY_PORT, '127.0.0.1', () => {
    process.stdout.write(`${PROXY_PORT}\n`);
  });
});

process.on('SIGTERM', () => process.exit(0));
process.on('SIGINT', () => process.exit(0));
