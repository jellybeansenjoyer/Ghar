# ---- Build Stage ----
FROM node:20-alpine AS builder

# Install OpenSSL so Prisma can detect the correct engine binary
RUN apk add --no-cache openssl

WORKDIR /app

# Copy dependency manifests
COPY package*.json ./
COPY prisma ./prisma/

# Install ALL dependencies (including devDependencies for TypeScript build)
RUN npm ci

# Generate Prisma client
RUN npx prisma generate

# Copy source code
COPY . .

# Compile TypeScript
RUN npm run build

# ---- Production Stage ----
FROM node:20-alpine

# Install OpenSSL (required by Prisma query engine at runtime)
RUN apk add --no-cache openssl

WORKDIR /app

# Copy dependency manifests
COPY package*.json ./
COPY prisma ./prisma/

# Install production dependencies only
RUN npm ci --omit=dev

# Generate Prisma client (needed at runtime)
RUN npx prisma generate

# Copy compiled output from builder
COPY --from=builder /app/dist ./dist

# Copy public assets (visitor web form)
COPY --from=builder /app/public ./public

# Expose port (Render uses $PORT env var)
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD wget -qO- http://localhost:${PORT:-3000}/api/health || exit 1

# Start the server
CMD ["node", "dist/index.js"]
