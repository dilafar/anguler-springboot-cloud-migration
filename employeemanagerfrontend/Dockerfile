FROM node:20.18-alpine AS build
WORKDIR /app

COPY package*.json ./
RUN npm install
RUN npm install -g @angular/cli

COPY . . 
RUN ng build --configuration production

RUN chown -R node:node /app
USER node

FROM nginx:stable-alpine-slim

RUN chown -R nginx:nginx /usr/share/nginx/html && chmod -R 755 /usr/share/nginx/html && \
        chown -R nginx:nginx /var/cache/nginx && \
        chown -R nginx:nginx /var/log/nginx && \
        chown -R nginx:nginx /etc/nginx/conf.d 

RUN touch /var/run/nginx.pid && \
        chown -R nginx:nginx /var/run/nginx.pid

COPY --from=build /app/dist/employeemanagerfrontend/browser/ /usr/share/nginx/html
COPY --from=build /app/generated_openssl_cert/default.conf /etc/nginx/conf.d/default.conf

USER nginx

