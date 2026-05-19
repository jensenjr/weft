# syntax=docker/dockerfile:1
# Build context: repo root (docker build -f dashboard/Dockerfile .)

# ---------------------------------------------------------------------------
# Stage 1: Build
# ---------------------------------------------------------------------------
FROM node:22-slim AS builder
WORKDIR /repo

RUN npm install -g pnpm@9

# Install dashboard dependencies (cached until lockfile changes)
COPY dashboard/package.json dashboard/pnpm-lock.yaml dashboard/pnpm-workspace.yaml ./dashboard/
RUN cd dashboard && pnpm install --frozen-lockfile

# Bring in catalog and scripts — needed to generate dashboard/src/lib/nodes/
COPY catalog/ catalog/
COPY scripts/ scripts/

# Copy remaining dashboard source
COPY dashboard/ dashboard/

# Populate dashboard/src/lib/nodes/ from the catalog
RUN bash scripts/catalog-link.sh --copy

# Build the SvelteKit app (outputs to dashboard/build/)
RUN cd dashboard && pnpm build

# ---------------------------------------------------------------------------
# Stage 2: Minimal runtime
# ---------------------------------------------------------------------------
FROM node:22-alpine AS runtime
WORKDIR /app

COPY --from=builder /repo/dashboard/build .

ENV NODE_ENV=production
EXPOSE 3000
CMD ["node", "index.js"]
