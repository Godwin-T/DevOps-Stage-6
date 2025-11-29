FROM maven:3.9.9-eclipse-temurin-8 AS builder
ENV MAVEN_OPTS="-Djdk.tls.client.protocols=TLSv1.2"
WORKDIR /build

COPY pom.xml .
COPY src ./src
RUN mvn -q -B -Dmaven.wagon.http.ssl.insecure=true -Dmaven.wagon.http.ssl.allowall=true package -DskipTests

FROM eclipse-temurin:8-jre
WORKDIR /app
COPY --from=builder /build/target/users-api-0.0.1-SNAPSHOT.jar /app/users-api.jar

EXPOSE 8083
ENV SERVER_PORT=8083
ENTRYPOINT ["java","-jar","/app/users-api.jar"]
