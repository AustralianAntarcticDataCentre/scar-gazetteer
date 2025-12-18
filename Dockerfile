# Step 1
FROM node:14-alpine AS builder

WORKDIR /tmp/app
COPY ./ .
RUN npm cache clean --force
RUN npm install && npm run build

# Step 2
FROM nginx:latest

COPY ./nginx.conf /etc/nginx/templates/default.conf.template
COPY --from=builder /tmp/app/dist/ /usr/share/nginx/html/

HEALTHCHECK --interval=60s --timeout=3s CMD curl -fsSI http://localhost/ || exit 1