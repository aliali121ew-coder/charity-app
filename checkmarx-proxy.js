/**
 * Checkmarx MCP Proxy
 * 1. Exchanges offline token for access token via Keycloak
 * 2. Uses access token to connect to Checkmarx SSE MCP
 * 3. Converts HTTP 202 → 200 so Claude Code accepts it
 */

const http = require('http');
const https = require('https');
const fs = require('fs');
const path = require('path');

const PORT = 3742;
const MCP_URL = 'https://ast.checkmarx.net/api/security-mcp/mcp';
const IAM_URL = 'https://iam.checkmarx.net/auth/realms/checkmarxdevassistus/protocol/openid-connect/token';
const CLIENT_ID = 'ast-app';
const TOKEN_FILE = path.join(__dirname, 'checkmarx-token.txt');

let accessToken = null;
let tokenExpiry = 0;

function getOfflineToken() {
  return fs.readFileSync(TOKEN_FILE, 'utf8').trim();
}

function postHttps(url, body) {
  return new Promise((resolve, reject) => {
    const urlObj = new URL(url);
    const data = Buffer.from(body);
    const options = {
      hostname: urlObj.hostname,
      path: urlObj.pathname,
      method: 'POST',
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
        'Content-Length': data.length,
      }
    };
    const req = https.request(options, (res) => {
      let chunks = [];
      res.on('data', chunk => chunks.push(chunk));
      res.on('end', () => {
        try {
          resolve(JSON.parse(Buffer.concat(chunks).toString()));
        } catch (e) {
          reject(new Error('Invalid JSON response: ' + Buffer.concat(chunks)));
        }
      });
    });
    req.on('error', reject);
    req.write(data);
    req.end();
  });
}

async function getAccessToken() {
  if (accessToken && Date.now() < tokenExpiry - 30000) {
    return accessToken;
  }
  console.log('[Proxy] Exchanging offline token for access token...');
  const offlineToken = getOfflineToken();
  const body = new URLSearchParams({
    grant_type: 'refresh_token',
    client_id: CLIENT_ID,
    refresh_token: offlineToken,
  }).toString();

  const result = await postHttps(IAM_URL, body);
  if (result.access_token) {
    accessToken = result.access_token;
    tokenExpiry = Date.now() + (result.expires_in || 300) * 1000;
    console.log('[Proxy] Access token obtained, expires in', result.expires_in, 'seconds');
    return accessToken;
  }
  throw new Error('Token exchange failed: ' + JSON.stringify(result));
}

const server = http.createServer(async (req, res) => {
  try {
    const token = await getAccessToken();
    const urlObj = new URL(MCP_URL);

    const options = {
      hostname: urlObj.hostname,
      path: urlObj.pathname,
      method: req.method,
      headers: {
        'Authorization': 'Bearer ' + token,
        'cx-origin': 'VsCode',
        'Accept': req.headers['accept'] || 'text/event-stream',
        'Content-Type': req.headers['content-type'] || 'application/json',
        'mcp-session-id': req.headers['mcp-session-id'] || '',
      }
    };

    // Remove empty headers
    Object.keys(options.headers).forEach(k => {
      if (!options.headers[k]) delete options.headers[k];
    });

    const proxyReq = https.request(options, (proxyRes) => {
      const statusCode = proxyRes.statusCode === 202 ? 200 : proxyRes.statusCode;
      console.log(`[Proxy] ${req.method} → ${proxyRes.statusCode} (sending ${statusCode})`);
      res.writeHead(statusCode, proxyRes.headers);
      proxyRes.pipe(res, { end: true });
      proxyRes.on('data', chunk => {
        process.stdout.write('[SSE] ' + chunk.toString().substring(0, 80));
      });
    });

    proxyReq.on('error', (err) => {
      console.error('[Proxy] Request error:', err.message);
      if (!res.headersSent) {
        res.writeHead(502);
        res.end(err.message);
      }
    });

    if (req.method === 'POST') {
      req.pipe(proxyReq);
    } else {
      proxyReq.end();
    }
  } catch (err) {
    console.error('[Proxy] Error:', err.message);
    if (!res.headersSent) {
      res.writeHead(500, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({ error: err.message }));
    }
  }
});

server.listen(PORT, '127.0.0.1', () => {
  console.log(`[Proxy] Checkmarx MCP Proxy running at http://127.0.0.1:${PORT}`);
  console.log(`[Proxy] Forwarding to: ${MCP_URL}`);
});
