# Spin Template - Laravel Starter Kit (Inertia & React) 🚀

A highly opinionated Spin template for the [Laravel Starter Kit (Inertia & React)](https://github.com/nunomaduro/laravel-starter-kit-inertia-react). This template combines the strict, type-safe architecture of the starter kit with the Docker-powered ease of use from [Spin](https://serversideup.net/open-source/spin).

> [!NOTE]
> This template installs the `nunomaduro/laravel-starter-kit-inertia-react` project, which mandates PHP 8.4+.

## Features

| Feature | Included |
|---------|----------|
| **Laravel Starter Kit (Inertia & React)** | ✅ |
| **Vite HMR (Hot Module Replacement)** | ✅ |
| MySQL 8.0 Database | ✅ |
| Laravel Queues (database driver) | ✅ |
| Queue Worker Container | ✅ |
| Task Scheduling Container | ✅ |
| Traefik Reverse Proxy | ✅ |
| Zero-Downtime Deployments | ✅ |
| Automated SSL (Let's Encrypt) | ✅ |
| Mailpit (SMTP Trapping) | ✅ |

### What's Special About This Template?
- **Automated Vite Config**: We automatically inject Docker-compatible settings into `vite.config.js` / `vite.config.ts`, ensuring the dev server binds correctly (`0.0.0.0`) and HMR works out of the box.
- **Strict Typing**: Inherits the starter kit's strict PHPStan and TypeScript configuration.

## Quick Start

### Install Spin
Make sure you have Spin installed: https://serversideup.net/open-source/spin/docs

### Create a new project
```bash
spin new webjackl/spin-template-laravel-inertia-react my-project
```

### Run the project
```bash
cd my-project
spin up
```
Once started, your application will be available at `https://laravel.test` (or the domain you configured).

### Run migrations
```bash
spin exec php artisan migrate
```

## Services

When you run `spin up`, the following containers will start:

| Service | Host Port | Internal Port | Description |
|---------|-----------|---------------|-------------|
| php | - | 9000 | Laravel application (via Traefik) |
| mysql | 3306 | 3306 | MySQL 8.0 database |
| queue | - | - | Queue worker (`php artisan queue:work`) |
| scheduler | - | - | Task scheduler (`php artisan schedule:work`) |
| traefik | 80, 443 | 80, 443 | Reverse proxy |
| node | 5173 | 5173 | Node.js for Vite dev server |
| mailpit | 8025 | 8025 | Email testing UI |

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

Queues use the `database` driver by default.

```env
QUEUE_CONNECTION=database
```

## Production Deployment

This template supports Spin's standard deployment workflow.

```bash
# Provision your server (first time)
spin provision production

# Deploy your application
spin deploy production
```

## Credits
- [Laravel Starter Kit (Inertia & React)](https://github.com/nunomaduro/laravel-starter-kit-inertia-react) by Nuno Maduro
- [Spin](https://serversideup.net/open-source/spin) by Server Side Up

## License

GPL-3.0-or-later - Same as Spin
