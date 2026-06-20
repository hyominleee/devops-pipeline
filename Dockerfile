FROM openjdk:17-jdk-slim

WORKDIR /app

EXPOSE 8080
EXPOSE 8081

ADD ./target/spring-boot-app-0.0.1-SNAPSHOT.jar  app.jar

ENTRYPOINT ["java","-jar","app.jar"]
