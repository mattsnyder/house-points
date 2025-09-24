# House Points - Deployment Guide

## Overview

This document outlines how to deploy the House Points application to Gigalixir, a platform-as-a-service (PaaS) specifically designed for Elixir applications.

## Prerequisites

1. **Git repository** - Ensure your code is committed to git
2. **Python 3** - Required for Gigalixir CLI installation
3. **Gigalixir account** - Sign up at https://www.gigalixir.com/

## Configuration Files

The following files have been configured for Gigalixir deployment:

### 1. `elixir_buildpack.config`
Specifies Elixir and Erlang versions for the build environment.

### 2. `phoenix_static_buildpack.config`
Specifies Node.js and NPM versions for building frontend assets.

### 3. `config/releases.exs`
Production runtime configuration including database and endpoint settings.

### 4. `.buildpacks`
Defines the buildpacks used for deployment (Phoenix static + Elixir).

### 5. `.gigalixir.toml`
Gigalixir-specific configuration including asset compilation and migration settings.

### 6. `Procfile`
Defines how to start the application (optional for Gigalixir).

## Installation & Setup

### 1. Install Gigalixir CLI
```bash
pip3 install gigalixir
```

### 2. Sign up and login
```bash
gigalixir signup
gigalixir login
```

### 3. Create your app
```bash
gigalixir create
```
This will create a new Gigalixir app and add a git remote called `gigalixir`.

## Database Setup

### Create a PostgreSQL database
```bash
gigalixir pg:create --size=0.6
```

The `DATABASE_URL` environment variable will be automatically set.

## Environment Variables

Set the required secret key:
```bash
gigalixir config:set SECRET_KEY_BASE="$(mix phx.gen.secret)"
```

## Deployment

### 1. Commit your changes
```bash
git add .
git commit -m "Ready for production deployment"
```

### 2. Deploy to Gigalixir
```bash
git push gigalixir main
```

### 3. Run database migrations
```bash
gigalixir ps:migrate
```

### 4. Seed the database (if needed)
```bash
gigalixir ps:remote_console
```
Then run:
```elixir
HousePoints.Release.seed()
```

## Verification

1. **Check app status**: `gigalixir ps`
2. **View logs**: `gigalixir logs`
3. **Open in browser**: `gigalixir open`

## Useful Commands

- **Restart app**: `gigalixir ps:restart`
- **Scale app**: `gigalixir ps:scale --replicas=2`
- **View configuration**: `gigalixir config`
- **Connect to remote console**: `gigalixir ps:remote_console`

## Production Release Testing

Before deploying, you can test the production build locally:

1. **Build assets**: `MIX_ENV=prod mix assets.deploy`
2. **Create release**: `MIX_ENV=prod mix release`
3. **Test release**: `_build/prod/rel/house_points/bin/house_points start`

## Troubleshooting

### Common Issues

1. **Asset compilation failures**: Check Node.js/NPM versions in buildpack config
2. **Database connection issues**: Verify `DATABASE_URL` is set correctly
3. **Missing secret key**: Ensure `SECRET_KEY_BASE` is configured
4. **Migration failures**: Run `gigalixir ps:migrate` after deployment

### Logs and Debugging

- **Real-time logs**: `gigalixir logs -t`
- **Application metrics**: `gigalixir ps`
- **Remote console**: `gigalixir ps:remote_console`

## Production Configuration

The application is configured for production with:

- **SSL/HTTPS** enabled
- **Database connection pooling** (2 connections by default)
- **Static asset compression** and caching
- **Runtime configuration** via environment variables
- **Database migrations** on deployment
- **Logging** set to info level

## Security Notes

- Never commit secrets to git
- Use environment variables for sensitive configuration
- SSL is enforced in production
- Database connections use SSL by default

## Monitoring

Consider setting up external monitoring for:
- Application uptime
- Database performance
- Error tracking
- Performance metrics

Your House Points application is now ready for production deployment on Gigalixir! 🏆✨