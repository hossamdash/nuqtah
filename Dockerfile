FROM node:22-alpine

# Create unprivileged user
RUN adduser -u 1001 -S appuser

WORKDIR /app

COPY package.json package-lock.json* ./

# doesn't install anything for now
RUN npm ci --only=production

COPY --chown=appuser . .

USER appuser

EXPOSE 3000

CMD ["node", "index.js"]