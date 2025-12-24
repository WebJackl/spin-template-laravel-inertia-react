# Spin Template - Laravel Lite 🚀

A Laravel template with **MySQL database** and **Laravel Queues** support. This template sits between the basic free template and the Pro template, offering essential production features without the full Pro feature set.

## Features

| Feature | Included |
|---------|----------|
| MySQL 8.0 Database | ✅ |
| Laravel Queues (database driver) | ✅ |
| Queue Worker Container | ✅ |
| Traefik Reverse Proxy | ✅ |
| Zero-Downtime Deployments | ✅ |
| Automated SSL (Let's Encrypt) | ✅ |
| Mailpit (SMTP Trapping) | ✅ |
| Local Development with Hot Reload | ✅ |

## What's Not Included (Pro Features)

- Redis
- Laravel Horizon
- Laravel Reverb
- Task Scheduling container
- GitHub Actions CI/CD (pre-configured)
- Local HTTPS/SSL (trusted certs)
- PostgreSQL/MariaDB options

## Quick Start

### Install Spin
Make sure you have Spin installed: https://serversideup.net/open-source/spin/docs

### Create a new project
```bash
spin new jigar-dhulla/spin-laravel-lite-template my-project
```

### Run the project
```bash
cd my-project
spin up
```

### Run migrations
```bash
spin exec php artisan migrate
```

## Services

When you run `spin up`, the following containers will start:

| Service | Port | Description |
|---------|------|-------------|
| php | - | Laravel application (via Traefik) |
| mysql | 3306 | MySQL 8.0 database |
| queue | - | Queue worker (php artisan queue:work) |
| traefik | 80, 443 | Reverse proxy |
| node | - | Node.js for asset compilation |
| mailpit | 8025 | Email testing UI |

## Database Configuration

The template configures MySQL with these defaults:

```env
DB_CONNECTION=mysql
DB_HOST=mysql
DB_PORT=3306
DB_DATABASE=laravel
DB_USERNAME=laravel
DB_PASSWORD=secret
```

## Queue Configuration

Queues use the database driver by default:

```env
QUEUE_CONNECTION=database
```

To create the jobs table:
```bash
spin exec php artisan queue:table
spin exec php artisan migrate
```

## Production Deployment

```bash
# Provision your server (first time)
spin provision production

# Deploy your application
spin deploy production
```

## License

GPL-3.0-or-later - Same as Spin