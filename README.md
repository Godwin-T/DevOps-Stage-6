# HNG13 DevOps Stage6 Task

This Repo Contains the code for a microservice application comprising of several components communicating to each other. In other words, this is an example of microservice. These microservices are written in different languages.

The app itself is a simple TODO app that additionally authenticates users.

## Components

1. [Frontend](/frontend) part is a Javascript application, provides UI. Created with [VueJS](http://vuejs.org)
2. [Auth API](/auth-api) is written in Go and provides authorization functionality. Generates JWT tokens to be used with other APIs.
3. [TODOs API](/todos-api) is written with NodeJS, provides CRUD functionality ove user's todo records. Also, it logs "create" and "delete" operations to Redis queue, so they can be later processed by [Log Message Processor](/log-message-processor).
4. [Users API](/users-api) is a Spring Boot project written in Java. Provides user profiles. Does not provide full CRUD for simplicity, just getting a single user and all users.
5. [Log Message Processor](/log-message-processor) is a very short queue processor written in Python. It's sole purpose is to read messages from Redis queue and print them to stdout


The diagram describes the various components and their interactions.
![microservice-app-example](https://user-images.githubusercontent.com/1905821/34918427-a931d84e-f952-11e7-85a0-ace34a2e8edb.png)

Note: 3 different login details are provided in the .env file 

## Containerized deployment

Each service now owns its environment configuration:

- Root `.env` defines routing for Traefik – set `BASE_DOMAIN` (e.g. `your-domain.com`), `API_BASE_PATH`, and the per-service prefixes such as `/api/auth`. It also holds `TRAEFIK_ACME_EMAIL`, which Let's Encrypt uses when issuing certificates.
- `frontend/.env` describes the browser-facing endpoints (by default `https://your-domain.com/api/*`), plus the local dev port.
- `auth-api/.env`, `todos-api/.env`, `users-api/.env`, `log-message-processor/.env` – runtime ports, shared JWT secret, Redis connection parameters and Zipkin endpoint.

Traefik (see `/traefik`) terminates HTTPS for every entry point and now requests certificates automatically from Let's Encrypt using the TLS-ALPN challenge. Issued certs are stored in `traefik/acme.json` (created automatically; keep it writable so renewals succeed).

### Prerequisites

- Docker 24+ and Docker Compose Plugin v2.
- Optional: add the generated certificate to your OS keychain to avoid HTTPS warnings.

### Bring the stack up

```bash
# from the repo root
docker compose build
docker compose up -d
```

Available endpoints (all served over HTTPS on `https://$BASE_DOMAIN`):

- UI: `https://your-domain.com`
- Auth API: `https://your-domain.com/api/auth` (Traefik strips the prefix and forwards `/login`, etc.)
- Todos API: `https://your-domain.com/api/todos`
- Users API: `https://your-domain.com/api/users`
- Zipkin collector: `https://your-domain.com/api/zipkin`
- Zipkin UI/API explorer: `https://zipkin.your-domain.com`

Logs can be tailed with `docker compose logs -f <service>` and the stack can be removed with `docker compose down -v`.

### Customizing TLS

- Set `TRAEFIK_ACME_EMAIL` in `.env` before the first `docker compose up -d`.
- Ensure ports 80/443 on your host are reachable from the public Internet so Let's Encrypt can validate requests.
- `traefik/acme.json` stores issued certs; keep it persisted and locked down (`chmod 600 traefik/acme.json`).
- If you prefer custom certificates, mount them via `traefik/certs/` and change the Traefik command-line flags accordingly.

### Environment tweaks

- Ports, secrets, Redis channel names, etc. can be edited inside the respective `.env` files per service.
- Each directory now ships with an `.env.example`; copy it to `.env` (e.g. `cp auth-api/.env.example auth-api/.env`) and tweak values for your environment.
- The login credentials remain the same (`admin/Admin123`, `hng/HngTech`, `user/Password`).
- Update `frontend/.env` if you change the public hostnames so the browser calls the right URLs.
- After editing `.env` (root or per-service), rebuild the affected images: e.g. `docker compose up -d --build frontend`.

Once DNS for `your-domain.com` points to your Docker host, Traefik will request and renew certificates automatically.

## Infrastructure & automation

Infrastructure lives in `infra/` and provisions a single AWS EC2 host plus all dependencies:

- `infra/terraform` provisions networking, security groups, SSH keys, a t3.medium instance, and an Elastic IP. Remote state is configured for S3 + DynamoDB (`backend.tf`); create those resources and update the placeholder bucket/table names before running `terraform init`.
- After provisioning, Terraform writes `infra/ansible/inventory/hosts.ini` and immediately runs `ansible-playbook` to finish configuration.
- Required environment variables/inputs:
  ```bash
  export TF_VAR_ssh_public_key="$(cat ~/.ssh/id_rsa.pub)"
  export TF_VAR_ssh_private_key_path="$HOME/.ssh/id_rsa"
  export TF_VAR_base_domain="your-domain.com"
  export TF_VAR_traefik_acme_email="admin@your-domain.com"
  export TF_VAR_auth_jwt_secret="replace-me"
  export TF_VAR_todos_jwt_secret="replace-me"
  export TF_VAR_users_jwt_secret="replace-me"
  ```
- Typical workflow:
  ```bash
  cd infra/terraform
  terraform init
  terraform plan
  terraform apply
  ```
  The outputs (`app_public_ip`, `app_public_dns`) are what you should point your DNS records to. Terraform expects `ansible-playbook` to be installed on the same machine because a `local-exec` provisioner kicks off configuration automatically after provisioning.

### Ansible layout

- `infra/ansible/site.yml` applies two roles:
  - `dependencies`: installs Docker Engine, docker compose plugin, git, Python tooling, and Traefik helpers; enables the Docker service.
  - `deploy`: clones this repository into `/opt/devops-stage6`, templates `.env` plus `frontend/.env` with the domain you supplied to Terraform, ensures `traefik/acme.json` exists with `0600` perms, and runs `docker compose up -d --remove-orphans`. Handlers only fire when git/templates change, keeping the deployment idempotent.

### CI/CD drift guard

`.github/workflows/infra.yaml` enforces drift detection and safe applies:

1. Every push (and a daily 06:00 UTC schedule) runs `terraform plan -detailed-exitcode`.
2. If drift is detected (exit code `2`), an email is sent via `dawidd6/action-send-mail` with the plan output, and the `production` environment requires manual approval before apply.
3. After approval, the saved `tfplan` artifact is applied. When no drift exists, the workflow exits after the plan stage.

Add these GitHub secrets so the workflow can authenticate:

- `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_DEFAULT_REGION`
- `SMTP_SERVER`, `SMTP_PORT`, `SMTP_USERNAME`, `SMTP_PASSWORD`, `DRIFT_EMAIL_TO`

## License

MIT
