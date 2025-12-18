FROM python:3.10-slim-bullseye

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    TZ=Asia/Shanghai

# JDBC needs a JVM; pyodbc may need unixODBC at runtime/build time.
RUN apt-get update \
  && apt-get install -y --no-install-recommends \
    bash \
    ca-certificates \
    openjdk-11-jre-headless \
    unixodbc \
    unixodbc-dev \
    build-essential \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy project (do not copy local secrets/data; see .dockerignore).
COPY pyproject.toml README.md requirements*.txt ./
COPY src ./src
COPY sql ./sql
COPY scripts ./scripts
COPY config ./config
COPY drivers ./drivers
COPY lib ./lib

# Create a non-root user matching common host UID/GID (1000:1000).
RUN groupadd -g 1000 etl \
  && useradd -m -u 1000 -g 1000 -s /bin/bash etl \
  && chown -R etl:etl /app

RUN python -m pip install --no-cache-dir --upgrade pip \
  && pip install --no-cache-dir -e ".[jdbc]"

USER etl

# Keep container running so you can `docker exec -it dm8-etl bash`.
CMD ["bash", "-lc", "tail -f /dev/null"]
