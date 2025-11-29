ARG BASE_IMAGE=node:20-alpine
FROM ${BASE_IMAGE}
WORKDIR /app
COPY package*.json ./
# Improve reliability and support missing lockfile
RUN npm config set fetch-retry-maxtimeout 120000 \
 && if [ -f package-lock.json ]; then npm ci --omit=dev; else npm install --omit=dev; fi
COPY . .
EXPOSE 8080
CMD ["node", "index.js"]
