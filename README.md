# SignSuite

A white-label document signing platform.

A self-hosted electronic signature solution designed to be branded for any organization.

## Features

* PDF document form creation and management
* Multi-step signature workflows
* API for programmatic document signing
* Email and SMS notifications
* Embedding support (React, Vue, Angular)
* Webhooks for integration
* Role-based access control
* Custom branding and templates

## White-Label Usage

1. **Fork** this repository to your organization
2. **Customize** branding in `lib/sign_suite.rb` (product name, URLs, support email)
3. **Update** the theme in `tailwind.config.js` for your brand colors
4. **Deploy** to Railway, Docker, or any cloud provider

### Key Customization Points

| File | What to Change |
|------|---------------|
| `lib/sign_suite.rb` | Product name, URLs, support email |
| `tailwind.config.js` | Brand colors and theme |
| `app/views/shared/_logo.html.erb` | Company logo |
| `app/views/layouts/application.html.erb` | Page title, meta tags |

## Self-Hosted Deployment

### Docker (Recommended)

```
docker run -d --name signsuite \
  -p 3000:3000 \
  -v signsuite_data:/data \
  signsuite:latest
```

### Docker Compose

```
docker compose up -d
```

### Railway

1. Connect this repo to a new Railway project
2. Add a PostgreSQL database
3. Set environment variables: `DATABASE_URL`, `SECRET_KEY_BASE`, `RAILS_ENV=production`, `FORCE_SSL=true`, `HOST=your-domain.up.railway.app`
4. Deploy

## Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `DATABASE_URL` | PostgreSQL connection string | SQLite (local) |
| `SECRET_KEY_BASE` | Rails secret key | Required in production |
| `HOST` | Application hostname | `localhost` |
| `FORCE_SSL` | Enable HTTPS | `false` |
| `PRODUCT_NAME` | Override display name | `SignSuite` |
| `SUPPORT_EMAIL` | Support contact email | `support@signsuite.live` |

## License

Proprietary. See [LICENSE](LICENSE) file.
