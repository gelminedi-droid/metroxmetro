# Use Node.js 18 as the base image
FROM node:18-slim AS builder

# Install Wasp
RUN curl -sSL https://get.wasp.sh/installer.sh | sh

# Set working directory
WORKDIR /app

# Copy source code
COPY . .

# Install dependencies and build
ENV WASP_TELEMETRY_DISABLE=1
RUN /root/.local/bin/wasp build

# ---------------------------------------------------------
# Production Image
# ---------------------------------------------------------
FROM node:18-slim

WORKDIR /app

# Copy built server
COPY --from=builder /app/.wasp/build/server /app/server
# Copy built client (for serving static files if needed, though Render Static Site is better)
COPY --from=builder /app/.wasp/build/web-app /app/web-app

# Install production dependencies for server
WORKDIR /app/server
RUN npm install --omit=dev

# Expose port
EXPOSE 3001

# Start server
CMD ["npm", "start"]
