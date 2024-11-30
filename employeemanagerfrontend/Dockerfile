FROM node:23.3.0-slim AS build
WORKDIR /app

COPY package*.json ./
COPY generated_openssl_cert/ ./generated_openssl_cert
RUN npm install --no-cache && npm install -g @angular/cli

COPY . .
RUN ng build --configuration production

FROM nginx:stable
WORKDIR /usr/share/nginx/html
COPY --from=build /app/dist/employeemanagerfrontend/browser/ .
COPY --from=build /app/generated_openssl_cert/default.conf /etc/nginx/conf.d/default.conf