# ================================
# Stage 1: Build
# ================================
FROM public.ecr.aws/docker/library/maven:3.9-eclipse-temurin-21 AS build

WORKDIR /app

COPY pom.xml .

RUN mvn dependency:go-offline -B

COPY src ./src

RUN mvn clean package -DskipTests -B


# ================================
# Stage 2: Runtime
# ================================
FROM public.ecr.aws/docker/library/eclipse-temurin:21-jre

WORKDIR /app

# Create a non-root user
RUN groupadd --system appgroup \
    && useradd --system --gid appgroup appuser

# Copy application
COPY --from=build /app/target/*.jar app.jar

# Give application user ownership
RUN chown -R appuser:appgroup /app

USER appuser

# Application port
EXPOSE 8080

# Container health check
HEALTHCHECK --interval=30s \
            --timeout=5s \
            --start-period=60s \
            --retries=3 \
            CMD wget --spider -q http://localhost:8080/actuator/health || exit 1

# Start application
ENTRYPOINT ["java", "-jar", "app.jar"]