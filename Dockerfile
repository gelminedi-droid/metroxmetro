# Use Node.js 22 as the base image
FROM node:22-slim AS builder

# Install system dependencies required for Wasp and Prisma
RUN apt-get update && apt-get install -y curl openssl ca-certificates && rm -rf /var/lib/apt/lists/*

# Install Wasp
RUN curl -sSL https://get.wasp.sh/installer.sh | sh

# Set working directory
WORKDIR /app

# Copy source code
COPY . .

# Install dependencies and build
ENV WASP_TELEMETRY_DISABLE=1
RUN /root/.local/bin/wasp build

# Build the server bundle (required for production)
WORKDIR /app/.wasp/build/server
RUN npm install zod
RUN npm install @prisma/client@5.19.1
RUN npm install lucia@3.2.0
RUN npm install @lucia-auth/adapter-prisma@4.0.1
RUN npm install nodemailer@6.9.9
RUN npm install
RUN npm run bundle

# ---------------------------------------------------------
# Production Image
# ---------------------------------------------------------
FROM node:22-slim

WORKDIR /app

# Copy built server
COPY --from=builder /app/.wasp/build/server /app/server
# Copy built client (for serving static files if needed, though Render Static Site is better)
COPY --from=builder /app/.wasp/build/web-app /app/web-app

# Install production dependencies for server
WORKDIR /app/server
RUN npm install --omit=dev
RUN npx prisma generate

# Expose port
EXPOSE 3001

# Start server
CMD ["npm", "start"]
