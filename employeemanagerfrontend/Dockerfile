FROM node:20.18-alpine AS build
WORKDIR /app

COPY package*.json ./
RUN npm ci && npm install -g @angular/cli

COPY . . 
RUN ng build --configuration production

RUN chown -R node:node /app
USER node

FROM nginx:stable-alpine-slim
WORKDIR /app

COPY --from=build /app/dist/employeemanagerfrontend/browser/ /usr/share/nginx/html
COPY --from=build /app/nginx_conf/default.conf /etc/nginx/conf.d/default.conf

