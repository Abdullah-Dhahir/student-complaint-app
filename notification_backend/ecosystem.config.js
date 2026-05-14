/**
 * PM2 Ecosystem Configuration
 *
 * Use PM2 to run the notification service as a daemon process
 * that auto-restarts on crashes and can survive server reboots.
 *
 * Installation:
 *   npm install -g pm2
 *
 * Usage:
 *   pm2 start ecosystem.config.js
 *   pm2 logs notification-service
 *   pm2 restart notification-service
 *   pm2 stop notification-service
 *   pm2 startup (enable auto-start on system boot)
 */

module.exports = {
  apps: [{
    name: 'notification-service',
    script: './index.js',

    // Restart configuration
    watch: false,
    max_memory_restart: '500M',
    restart_delay: 4000,

    // Auto-restart on crash
    autorestart: true,
    max_restarts: 10,
    min_uptime: '10s',

    // Environment variables
    env: {
      NODE_ENV: 'production',
      SERVICE_ACCOUNT_PATH: './serviceAccountKey.json'
    },

    // Logging
    error_file: './logs/error.log',
    out_file: './logs/output.log',
    log_date_format: 'YYYY-MM-DD HH:mm:ss Z',
    merge_logs: true,

    // Advanced options
    instances: 1, // Single instance (Firestore listener doesn't need clustering)
    exec_mode: 'fork',

    // Graceful shutdown
    kill_timeout: 5000,
    wait_ready: false,
  }]
};
