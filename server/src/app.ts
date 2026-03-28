import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import path from 'path';
import { generalLimiter } from './middleware/rate-limiter';
import { errorHandler } from './middleware/error-handler';
import authRoutes from './routes/auth.routes';
import userRoutes from './routes/user.routes';
import familyRoutes from './routes/family.routes';
import visitorRoutes from './routes/visitor.routes';

const app = express();

// --- Diagnostic log capture (in-memory ring buffers) ---
const MAX_LOG_ENTRIES = 50;
const recentErrors: { ts: string; msg: string }[] = [];
const recentRequests: { ts: string; method: string; url: string; status: number }[] = [];

const origConsoleError = console.error;
console.error = (...args: unknown[]) => {
  recentErrors.push({ ts: new Date().toISOString(), msg: args.map(String).join(' ') });
  if (recentErrors.length > MAX_LOG_ENTRIES) recentErrors.shift();
  origConsoleError.apply(console, args);
};

// Security middleware
app.use(helmet({ contentSecurityPolicy: false }));
app.use(cors({ origin: '*', credentials: true }));
app.use(generalLimiter);

// Body parsing
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Serve visitor web form static files
app.use('/visit', express.static(path.join(__dirname, '../public/visit')));

// Visitor web form route - serve index.html for /visit/:familyId
app.get('/visit/:familyId', (_req, res) => {
  res.sendFile(path.join(__dirname, '../public/visit/index.html'));
});

// Request logger for diagnostics
app.use((req, res, next) => {
  res.on('finish', () => {
    recentRequests.push({
      ts: new Date().toISOString(),
      method: req.method,
      url: req.originalUrl,
      status: res.statusCode,
    });
    if (recentRequests.length > MAX_LOG_ENTRIES) recentRequests.shift();
  });
  next();
});

// API Routes
app.use('/api/auth', authRoutes);
app.use('/api/users', userRoutes);
app.use('/api/families', familyRoutes);
app.use('/api/visitors', visitorRoutes);

// Health check
app.get('/api/health', (_req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

// Diagnostic endpoint — shows recent errors and requests for remote debugging
app.get('/api/debug/logs', (_req, res) => {
  res.json({
    errors: { count: recentErrors.length, logs: recentErrors },
    requests: { count: recentRequests.length, logs: recentRequests },
  });
});

// Public Invite landing: attempts to open the app via deep link and shows basic info
app.get('/invite/:token', (req, res) => {
  const { token } = req.params;
  // Minimal HTML that deep-links into the app and provides fallbacks
  res.type('html').send(`
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <title>Ghar - Family Invite</title>
    <style>
      body { font-family: system-ui, -apple-system, Segoe UI, Roboto, Helvetica, Arial, sans-serif; padding: 24px; line-height: 1.5; }
      .card { max-width: 560px; margin: 0 auto; border: 1px solid #e5e7eb; border-radius: 12px; padding: 24px; box-shadow: 0 2px 8px rgba(0,0,0,0.05); }
      .btn { display: inline-block; padding: 12px 16px; background: #2563eb; color: #fff; border-radius: 8px; text-decoration: none; }
      .muted { color: #6b7280; font-size: 14px; }
      code { background: #f3f4f6; padding: 2px 6px; border-radius: 4px; }
    </style>
    <script>
      // Try opening the app via custom scheme
      function openApp() {
        const scheme = 'ghar://invite/${token}';
        window.location.href = scheme;
        // Fallback after 1.5s to show instructions
        setTimeout(() => {
          document.getElementById('fallback').style.display = 'block';
        }, 1500);
      }
      window.onload = openApp;
    </script>
  </head>
  <body>
    <div class="card">
      <h2>Open Ghar to Join Family</h2>
      <p>Tap the button below to open the Ghar app and accept your family invite.</p>
      <p><a class="btn" href="ghar://invite/${token}">Open in Ghar</a></p>
      <div id="fallback" class="muted" style="display:none;margin-top:16px;">
        <p>If nothing happened:</p>
        <ol>
          <li>Ensure the Ghar app is installed.</li>
          <li>Open the app and sign in.</li>
          <li>Return to this page and tap <strong>Open in Ghar</strong> again.</li>
        </ol>
        <p>You can also share this code with the app: <code>${token}</code></p>
      </div>
      <p class="muted" style="margin-top:12px;">This link is secure and expires after a short time.</p>
    </div>
  </body>
</html>
  `);
});

// Error handler
app.use(errorHandler);

export default app;
