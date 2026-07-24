# Use Node.js 22 Alpine base image (includes built-in native SQLite engine)
FROM node:22-alpine

# Set working directory
WORKDIR /app

# Copy application files
COPY package.json server.js ./
COPY public/ ./public/

# Expose port
EXPOSE 3000

# Run server.js directly
CMD ["node", "server.js"]
