FROM node:23.4.0-alpine AS build
WORKDIR /app

COPY package*.json ./
RUN npm install
RUN npm install -g @angular/cli

COPY . . 
RUN ng build --configuration production

RUN chown -R node:node /app
USER node

FROM nginx:stable-alpine-slim

COPY --from=build /app/dist/employeemanagerfrontend/browser/ /usr/share/nginx/html
COPY --from=build /app/generated_openssl_cert/default.conf /etc/nginx/conf.d/default.conf


