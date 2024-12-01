FROM node:23.3.0-slim AS build
WORKDIR /app

COPY package*.json ./
COPY generated_openssl_cert/ ./generated_openssl_cert
RUN npm install --no-cache && npm install -g @angular/cli

COPY . .
RUN ng build --configuration production

FROM nginx:stable
WORKDIR /usr/share/nginx/html
RUN addgroup --system pipeline && adduser --system --ingroup pipeline k8s-pipeline
COPY --from=build /app/dist/employeemanagerfrontend/browser/ .
COPY --from=build /app/generated_openssl_cert/default.conf /etc/nginx/conf.d/default.conf

RUN chown -R k8s-pipeline:pipeline /usr/share/nginx/html /etc/nginx/conf.d

USER k8s-pipeline