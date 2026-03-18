# Use Node 22 slim as base
FROM node:22-slim

# Install system dependencies
# - lsof: required by denchclaw for port checking
# - procps: provides 'ps' for process management
# - build-essential, python3: often needed for native node modules (node-pty, sharp, etc.)
# - git: needed for git clone in some scripts or dependencies
RUN apt-get update && apt-get install -y \
    lsof \
    procps \
    build-essential \
    python3 \
    git \
    socat \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Install pnpm
RUN npm install -g pnpm@10.23.0

# Copy workspace configuration
COPY pnpm-workspace.yaml pnpm-lock.yaml package.json ./
COPY apps/web/package.json ./apps/web/

# Install dependencies
RUN pnpm install --frozen-lockfile

# Copy the rest of the source code
COPY . .

# Build the project
RUN pnpm build
RUN pnpm web:build
RUN pnpm web:prepack

# Set environment variables
ENV DENCHCLAW_DAEMONLESS=1
ENV PORT=3100
ENV OPENCLAW_PROFILE=dench
ENV NODE_ENV=production

# Expose the Web UI port and the default Gateway port
EXPOSE 3100
EXPOSE 19001

# Start DenchClaw by:
# 1. Bootstrapping profile and dependencies
# 2. Starting OpenClaw Gateway in background (now binds to 0.0.0.0 via patched bootstrap)
# 3. Tailing the web log to keep container alive
# Start DenchClaw by:
# 1. Bootstrapping profile and dependencies (which natively configures the Gateway for loopback:19001)
# 2. Starting the OpenClaw Gateway manually (since DENCHCLAW_DAEMONLESS prevents auto-start)
# 3. Using socat to bridge loopback:19001 to all-interfaces:19002 for host browser access
# 4. Tailing the web log to keep container alive
CMD node denchclaw.mjs bootstrap --non-interactive --yes --gateway-port 19001 && \
    (openclaw --profile dench gateway &) && \
    (socat TCP-LISTEN:19002,fork,reuseaddr,bind=0.0.0.0 TCP:127.0.0.1:19001 &) && \
    tail -f /root/.openclaw-dench/logs/web-app.log
