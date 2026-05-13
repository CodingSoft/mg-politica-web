# AGENTS.md — MG-Firma Legal

## Architecture

This is a **two-stack monolith**: a SvelteKit 5 frontend and a FastAPI backend, shipped together as one deployable unit. This is a customized fork of Open WebUI for MG-Firma Legal by CodingSoft.

- **Frontend** (`src/`): SvelteKit 5 (Svelte 5 runes) + Tailwind v4 + TypeScript. Uses `adapter-static` to produce a SPA in `build/` with `index.html` fallback. No server-side rendering.
- **Backend** (`backend/open_webui/`): FastAPI app (`open_webui.main:app`) served by uvicorn on port 8080. The built frontend is served as static files by the backend at runtime.
- **Python package**: `backend/` is the source root for the `open_webui` Python package. `pyproject.toml` uses hatchling; version is read from `package.json`. `hatch_build.py` runs `npm install && npm run build` at wheel-build time, so Node.js is required for Python packaging too.

## Dev Commands

```bash
# Frontend dev (runs pyodide:fetch first, then vite dev on default port)
npm run dev

# Backend dev (from backend/ — enables CORS for both vite and backend ports)
cd backend && bash dev.sh

# Full-stack local: run both simultaneously. Frontend at :5173 proxies API to :8080.
```

### Build

```bash
npm run build          # Runs pyodide:fetch then vite build → outputs to build/
```

### Lint & Format (run in this order)

```bash
npm run lint           # Runs lint:frontend → lint:types → lint:backend sequentially
npm run lint:frontend  # eslint with --fix
npm run lint:types     # svelte-check (Svelte + TS type checking)
npm run lint:backend   # pylint backend/

npm run format              # prettier (JS/TS/Svelte/CSS/MD/JSON)
npm run format:backend      # ruff format (excludes .venv, venv)
```

Pre-commit hooks run `ruff --fix backend/` and `ruff-format backend/` only.

### Test

```bash
npm run test:frontend   # vitest —passWithNoTests
npm run cy:open         # Cypress e2e (expects app at localhost:8080)
```

Backend tests are in `backend/open_webui/test/` — no top-level pytest script; use `pytest` directly from the backend directory.

### i18n

```bash
npm run i18n:parse      # Extracts translation keys → src/lib/i18n/locales/$LOCALE/$NAMESPACE.json
```

## Key Conventions

### Frontend

- **Tabs, not spaces** — `.prettierrc` enforces `useTabs: true`.
- **Single quotes**, no trailing commas, 100 char print width.
- Dark mode via Tailwind `class` strategy (`darkMode: 'class'`).
- Svelte 5 runes syntax (`$state`, `$derived`, `$effect`) — this is not Svelte 4.
- Static adapter means **no SSR**; all pages are client-rendered SPA.

### Backend

- **Single quotes** per ruff (`inline-quotes = 'single'`).
- Line length 120 (both ruff and black).
- Python **3.11–3.12 only** (3.13+ not supported).
- Ruff lint rules: E, F, W, I, UP, C90, Q, ICN. Max complexity 10.
- `datetime` must be imported as `dt` (import convention rule).

## Database

- Default: **SQLite** via `aiosqlite` (data in `backend/data/`).
- Optional: **PostgreSQL** via `psycopg` (async) + `psycopg2` (sync, for Alembic).
- Connection string: `DATABASE_URL` env var. Async engine uses `postgresql+asyncpg://` or `sqlite+aiosqlite://`.
- **Two migration systems**:
  - **Alembic** (`backend/open_webui/migrations/`) — primary, used for SQLAlchemy models.
  - **Peewee migrations** (`peewee-migrate`) — legacy, still referenced in `internal/db.py` at startup.
- Migrations auto-run on startup unless `ENABLE_DB_MIGRATIONS=false`.

## Environment & Config

- Backend loads `.env` from the repo root (via `dotenv`, see `env.py`).
- Config is centralized: `backend/open_webui/config.py` reads env vars into an `AppConfig` instance stored on `app.state.config`.
- Frontend env vars are injected at build time via `vite.config.ts` (`APP_VERSION`, `APP_BUILD_HASH`).
- Docker: `WEBUI_SECRET_KEY` is auto-generated if not set; stored in `backend/.webui_secret_key`.

## Docker

- `Dockerfile` is multi-stage: Node 22 Alpine builds frontend → Python 3.11 slim runs backend.
- `docker-compose.yaml` provides Ollama + MG-Firma Legal. Use `docker-compose.gpu.yaml` for CUDA, `docker-compose.api.yaml` for API-only, etc.
- Production serves on port **8080** (not 3000 — that's just the default host mapping in compose).
- Health check: `curl http://localhost:8080/health | jq -ne 'input.status == true'`.

## PR & Branch Conventions

- **Target `dev` branch** for all PRs. PRs targeting `main` are auto-closed.
- PR title must use a conventional prefix: `feat:`, `fix:`, `refactor:`, `chore:`, `i18n:`, etc.
- CLA checkbox at PR bottom is mandatory — deleting it invalidates the PR.
- Changelog entry required (Keep a Changelog format).
- AI-agent-authored PRs may be immediately closed; human review and manual testing required.

## Pyodide (In-Browser Python)

- `npm run pyodide:fetch` downloads Pyodide runtime + packages into `static/pyodide/`.
- This runs automatically before `dev` and `build`.
- `static/pyodide/` is gitignored except `pyodide-lock.json`.
- Supports HTTP/HTTPS proxy via `https_proxy` / `HTTP_PROXY` env vars.

## Common Pitfalls

- `npm install` requires `--force` (engine-strict is on via `.npmrc`; Node must be 18.13–22.x).
- Changing the embedding model (`RAG_EMBEDDING_MODEL`) breaks RAG on existing documents — they must be re-embedded.
- `aiohttp` is pinned; **do not update to 3.13.3** (broken, per comment in `pyproject.toml`).
- `pyarrow` is pinned to 20 for RPi compatibility.
- Backend middleware is pure-ASGI (not `BaseHTTPMiddleware`) — old-style `@app.middleware('http')` caused `CancelledError` storms with aiosqlite.
- The `open_webui.__init__.py` exports `app` — that's the entrypoint for `open-webui serve`.
- Swagger UI (`/docs`) is only available when `ENV=dev`.
