# syntax=docker/dockerfile:1

# Pinned by digest (multi-arch index) so a rebuild can't silently pick up a
# different base image than the one that was scanned. Bump deliberately.
ARG NODE_IMAGE=node:24-alpine@sha256:06d7adf3e0ef61a13f1d28682726366f97a15aa1888c934d3ecec86c33918b53

# --- deps: the only stage that runs npm ---
FROM ${NODE_IMAGE} AS deps

WORKDIR /app

COPY package.json package-lock.json ./
# Exactly what the lockfile says, no dev dependencies, and no install scripts
# from third-party packages. npm doesn't create node_modules when there are no
# dependencies, so make sure it exists for the COPY below either way.
RUN npm ci --omit=dev --ignore-scripts && mkdir -p node_modules

# --- runtime ---
FROM ${NODE_IMAGE}

LABEL app=lab-dom12-server-details

# Patch OS packages, then remove the package managers: the app never installs
# anything at runtime, and npm's own bundled dependencies are where nearly all
# of the base image's CVEs live.
RUN apk upgrade --no-cache \
    && rm -rf /usr/local/lib/node_modules \
              /usr/local/bin/npm /usr/local/bin/npx /usr/local/bin/corepack \
              /usr/local/bin/yarn /usr/local/bin/yarnpkg /opt/yarn-*

ENV NODE_ENV=production

WORKDIR /app

# Owned by root and only readable by the node user, so the running app can't
# modify its own code. Pairs with readonlyRootFilesystem in the task definition.
COPY --from=deps /app/node_modules ./node_modules
COPY package.json server.js ./
COPY lib/ ./lib/
COPY public/ ./public/

USER node

EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://127.0.0.1:3000/api/server-info || exit 1

CMD ["node", "server.js"]
