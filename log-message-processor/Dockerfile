FROM python:3.8-slim AS builder

# Install build dependencies and required libraries for compiling C extensions
WORKDIR /opt/app

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    build-essential \
    python3-dev \
    libssl-dev \
    libffi-dev \
    && rm -rf /var/lib/apt/lists/*

# Copy the requirements file and install the dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir --prefix=/install -r requirements.txt

FROM python:3.8-slim

# Set environment variables for Python optimization
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

WORKDIR /app

# Copy installed packages from the builder stage
COPY --from=builder /install /usr/local
COPY main.py .

# Command to run the app
CMD ["python", "/app/main.py"]
