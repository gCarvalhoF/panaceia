# Phase 9 — Rename to Panaceia

This document describes Phase 9. The project used to be called `dados_acesso_saude_salvador` (Rails module `DadosAcessoSaudeSalvador`). It is now **Panaceia**, the same name as the production instance at https://panaceia.gabrielcf.com.

## What changed

| Area | Before | After |
|---|---|---|
| Rails module | `DadosAcessoSaudeSalvador` | `Panaceia` |
| Databases | `dados_acesso_saude_salvador_{development,test,production*}` | `panaceia_{development,test,production*}` |
| Production DB user | `dados_acesso_saude_salvador` | `panaceia` |
| Production password variable | `DADOS_ACESSO_SAUDE_SALVADOR_DATABASE_PASSWORD` | `PANACEIA_DATABASE_PASSWORD` |
| Compose project | derived from the folder name | `name: panaceia` (containers `panaceia-web-1`, `panaceia-db-1`, …) |
| npm package | `dashboard-saude-salvador` | `panaceia` |
| Browser tab / header | "Dashboard Saúde Salvador" / "Saúde em Salvador" | "Panaceia — Saúde em Salvador" / "Panaceia" + "Acesso à saúde em Salvador" |
| GitHub repository | `gCarvalhoF/panaceia-saude-salvador` | `gCarvalhoF/panaceia` (GitHub redirects the old URLs) |
| Local folder | `dados_acesso_saude_salvador/` | `panaceia/` |

The compose project name is now set in `docker-compose.yml`, so the `Makefile` container names don't depend on the checkout's folder name.

Earlier phase docs are historical and still use the old names.

## Tests

`spec/config/app_naming_spec.rb` checks the module name, the dev/test/production database names, the production user and password variable, and that no tracked source, config or current doc mentions the old name. `DashboardPage.test.tsx` checks the new header.

## Production cutover

The production names must match the `panaceia` role in `gCarvalhoF/homelab-iac` (`POSTGRES_USER`, the healthcheck user, `PANACEIA_DATABASE_PASSWORD` in `.env`, `panaceia_repo_url`). Both PRs are merged together.

The PostGIS superuser is created only when the volume is first initialised. Renaming it in place isn't worth the effort because the data is fully reproducible. So the cutover drops the volume and lets the first boot reimport:

```bash
# on panaceia.homelab (LXC 108)
cd /srv/panaceia && docker compose down -v

# on iac-control
ansible-playbook playbooks/site.yml --limit panaceia
```

`db:prepare` then creates the `panaceia_production*` databases and runs the full CNES/IBGE import from `/srv/panaceia/aux-data` (about 2 minutes of downtime).

## Local migration

The local `tmp/db` cluster still holds the old databases. After pulling, either recreate them:

```bash
docker compose up -d db
make create_db && make migrate
docker compose exec web bundle exec rails data:import:all
```

or rename them in place:

```bash
docker compose exec db psql -U postgres -c 'ALTER DATABASE dados_acesso_saude_salvador_development RENAME TO panaceia_development'
docker compose exec db psql -U postgres -c 'ALTER DATABASE dados_acesso_saude_salvador_test RENAME TO panaceia_test'
```

Containers from before the rename used a different compose project. Stop them with `docker compose -p dados_acesso_saude_salvador down` before running `docker compose up`.
