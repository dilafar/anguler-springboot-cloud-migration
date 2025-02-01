FROM maven:3.9.9-amazoncorretto-17-alpine AS builder
WORKDIR /app
COPY pom.xml .
COPY src ./src
RUN mvn clean package -DskipTests

FROM amazoncorretto:17-alpine3.20-jdk
RUN addgroup -S pipeline && adduser -S k8-user -G pipeline
COPY --from=builder /app/target/*.jar /home/k8-user/app.jar
USER k8-user
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "/home/k8-user/app.jar"]