# syntax=docker/dockerfile:1.7
#
# Production server image: the API, serving the built dashboard. Expects
# DATABASE_URL to point at Postgres. On start it applies pending migrations,
# then serves; set SHOAL_SKIP_MIGRATIONS=true when a deploy step migrates or
# several instances share a database.

FROM oven/bun:1 AS build
WORKDIR /app
COPY bun.lock package.json ./
COPY apps/api/package.json apps/api/
COPY apps/cli/package.json apps/cli/
COPY apps/dashboard/package.json apps/dashboard/
COPY apps/web/package.json apps/web/
COPY packages/contracts/package.json packages/contracts/
COPY packages/db/package.json packages/db/
COPY packages/protocol/package.json packages/protocol/
RUN bun install --frozen-lockfile --filter '@shoal/api' --filter '@shoal/dashboard'
COPY . .
RUN cd apps/dashboard && bun run build
# The API and the migrator, bundled with their dependencies so the runtime
# needs no node_modules. The migrator finds its migrations beside its bundle.
RUN bun build apps/api/src/main.ts packages/db/cli.ts \
      --target=bun --minify-syntax --minify-whitespace --outdir /out \
 && cp -r packages/db/migrations /out/packages/db/migrations \
 && cp -r apps/dashboard/dist /out/dashboard \
 && cp apps/api/docker-entrypoint.sh /out/

FROM oven/bun:1-slim AS runtime
WORKDIR /app
COPY --from=build /out ./
ENV NODE_ENV=production \
    PORT=3000 \
    SHOAL_DASHBOARD_DIR=/app/dashboard
EXPOSE 3000
ENTRYPOINT ["./docker-entrypoint.sh"]
CMD ["bun", "apps/api/src/main.js"]
