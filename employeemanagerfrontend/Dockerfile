FROM node:23.4.0-alpine AS build
WORKDIR /app

COPY package*.json ./
RUN npm install && npm install -g @angular/cli

COPY . . 
RUN ng build --configuration production

FROM nginxinc/nginx-unprivileged:alpine3.20-perl

COPY --from=build /app/dist/employeemanagerfrontend/browser/ /usr/share/nginx/html
COPY --from=build /app/generated_openssl_cert/default.conf /etc/nginx/conf.d/default.conf

USER root
RUN chown -R nginx:nginx /usr/share/nginx/html /etc/nginx/conf.d/default.conf

USER nginx