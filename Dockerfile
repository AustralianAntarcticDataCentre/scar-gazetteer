# Step 1
FROM node:22-alpine AS builder

WORKDIR /tmp/app
COPY ./ .
RUN npm ci && npm run build

# Step 2
FROM nginx:latest

COPY ./nginx.conf /etc/nginx/templates/default.conf.template
COPY --from=builder /tmp/app/dist/ /usr/share/nginx/html/

HEALTHCHECK --interval=60s --timeout=3s CMD curl -fsSI http://localhost/ || exit 1