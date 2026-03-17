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

# Start DenchClaw by explicitly calling the bootstrap command
# We use a shell command to ensure we can tail the log file and keep the container alive
CMD node denchclaw.mjs bootstrap --non-interactive --yes && tail -f /root/.openclaw-dench/logs/web-app.log
