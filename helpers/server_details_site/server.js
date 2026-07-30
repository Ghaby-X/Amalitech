const http = require('http');
const os = require('os');
const fs = require('fs');
const path = require('path');
const { DatabaseSync } = require('node:sqlite');

// Configurable Environment Variables with sensible fallbacks
const PORT = process.env.PORT || 3000;
const HOSTNAME = process.env.HOST_NAME || os.hostname();
const DATA_DIR = process.env.DATA_DIR || path.join(__dirname, 'data');
const DB_NAME = process.env.DB_NAME || 'database.sqlite';
const REFRESH_INTERVAL_MS = parseInt(process.env.REFRESH_INTERVAL_MS, 10) || 3000;

// Full path to SQLite database file
const DB_FILE = path.join(DATA_DIR, DB_NAME);

// Ensure data directory exists
if (!fs.existsSync(DATA_DIR)) {
    fs.mkdirSync(DATA_DIR, { recursive: true });
}

// Initialize SQLite Database
const db = new DatabaseSync(DB_FILE);

// Create page_views table if it doesn't exist
db.exec(`
    CREATE TABLE IF NOT EXISTS page_views (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        ip_address TEXT NOT NULL,
        visited_at TEXT NOT NULL
    );
`);

// Prepared SQL statements for high efficiency
const insertVisitStmt = db.prepare('INSERT INTO page_views (ip_address, visited_at) VALUES (?, ?)');
const totalVisitsStmt = db.prepare('SELECT COUNT(*) AS totalVisits FROM page_views');
const uniqueVisitsStmt = db.prepare('SELECT COUNT(DISTINCT ip_address) AS uniqueVisitors FROM page_views');
const lastVisitStmt = db.prepare('SELECT visited_at FROM page_views ORDER BY id DESC LIMIT 1');

function formatMemory(bytes) {
    return (bytes / (1024 * 1024 * 1024)).toFixed(2) + ' GB';
}

function formatUptime(seconds) {
    const d = Math.floor(seconds / (3600 * 24));
    const h = Math.floor((seconds % (3600 * 24)) / 3600);
    const m = Math.floor((seconds % 3600) / 60);
    const s = Math.floor(seconds % 60);

    const parts = [];
    if (d > 0) parts.push(`${d}d`);
    if (h > 0) parts.push(`${h}h`);
    if (m > 0) parts.push(`${m}m`);
    parts.push(`${s}s`);

    return parts.join(' ');
}

const MIME_TYPES = {
    '.html': 'text/html; charset=utf-8',
    '.css': 'text/css; charset=utf-8',
    '.js': 'application/javascript; charset=utf-8',
    '.json': 'application/json; charset=utf-8',
    '.png': 'image/png',
    '.ico': 'image/x-icon',
    '.svg': 'image/svg+xml'
};

const server = http.createServer((req, res) => {
    const parsedUrl = new URL(req.url, `http://${req.headers.host || 'localhost'}`);
    const pathname = parsedUrl.pathname;

    // API: Frontend Runtime Configuration
    if (pathname === '/api/config') {
        res.writeHead(200, { 'Content-Type': 'application/json; charset=utf-8' });
        return res.end(JSON.stringify({
            refreshIntervalMs: REFRESH_INTERVAL_MS
        }));
    }

    // API: Live Real-Time Server System Metrics
    if (pathname === '/api/server-info') {
        const totalMem = os.totalmem();
        const freeMem = os.freemem();
        const usedMem = totalMem - freeMem;
        const memUsagePercent = ((usedMem / totalMem) * 100).toFixed(1);
        
        const cpus = os.cpus();
        const loadAvg = os.loadavg();
        
        const clientIp = req.headers['x-forwarded-for'] 
            ? req.headers['x-forwarded-for'].split(',')[0].trim()
            : req.socket.remoteAddress || '127.0.0.1';

        res.writeHead(200, { 'Content-Type': 'application/json; charset=utf-8' });
        return res.end(JSON.stringify({
            hostname: HOSTNAME,
            platform: `${os.type()} ${os.release()} (${os.arch()})`,
            uptime: formatUptime(os.uptime()),
            uptimeSeconds: Math.floor(os.uptime()),
            cpuModel: cpus.length > 0 ? cpus[0].model.trim() : 'Generic CPU',
            cpuCores: cpus.length,
            cpuLoadAvg: `${loadAvg[0].toFixed(2)}, ${loadAvg[1].toFixed(2)}, ${loadAvg[2].toFixed(2)}`,
            totalMemory: formatMemory(totalMem),
            freeMemory: formatMemory(freeMem),
            usedMemory: formatMemory(usedMem),
            memoryUsagePercent: `${memUsagePercent}%`,
            nodeVersion: process.version,
            listeningPort: PORT,
            dataDir: DATA_DIR,
            dbName: DB_NAME,
            clientIp: clientIp,
            serverTime: new Date().toISOString()
        }));
    }

    // API: Server-Side Visitor Counter using SQLite Database
    if (pathname === '/api/visitor-count') {
        const clientIp = req.headers['x-forwarded-for'] 
            ? req.headers['x-forwarded-for'].split(',')[0].trim()
            : req.socket.remoteAddress || '127.0.0.1';

        const nowIso = new Date().toISOString();

        // Insert new visit record into SQLite database
        insertVisitStmt.run(clientIp, nowIso);

        // Query SQLite for total visits & unique visitor IPs
        const totalVisits = totalVisitsStmt.get().totalVisits;
        const uniqueVisitors = uniqueVisitsStmt.get().uniqueVisitors;
        const lastVisitRow = lastVisitStmt.get();

        res.writeHead(200, { 'Content-Type': 'application/json; charset=utf-8' });
        return res.end(JSON.stringify({
            database: 'SQLite',
            dbPath: DB_FILE,
            totalVisits: totalVisits,
            uniqueVisitors: uniqueVisitors,
            lastVisit: lastVisitRow ? lastVisitRow.visited_at : nowIso,
            yourIp: clientIp
        }));
    }

    // Serve Static Frontend Assets
    let safePath = path.normalize(pathname).replace(/^(\.\.[\/\\])+/, '');
    if (safePath === '/' || safePath === '\\') safePath = '/index.html';

    const filePath = path.join(__dirname, 'public', safePath);
    const ext = path.extname(filePath).toLowerCase();
    const contentType = MIME_TYPES[ext] || 'application/octet-stream';

    fs.readFile(filePath, (err, content) => {
        if (err) {
            res.writeHead(404, { 'Content-Type': 'text/plain; charset=utf-8' });
            res.end('404 Not Found');
        } else {
            res.writeHead(200, { 'Content-Type': contentType });
            res.end(content);
        }
    });
});

server.listen(PORT, '0.0.0.0', () => {
    console.log(`Server details app listening on http://0.0.0.0:${PORT} [DB: ${DB_FILE}]`);
});
