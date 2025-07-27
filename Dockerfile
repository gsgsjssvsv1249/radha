# 🚧 Stage 1: Builder - Install dependencies and build packages
FROM python:3.10-slim-bookworm AS builder

ENV DEBIAN_FRONTEND=noninteractive

# 📦 Install build tools and audio libraries
RUN apt-get update && apt-get install -y \
    build-essential \
    libasound-dev \
    libjack-dev \
    portaudio19-dev \
    libportaudio2 \
    libportaudiocpp0 \
    libsndfile1-dev \
    ffmpeg && \
    rm -rf /var/lib/apt/lists/*

# 🔨 Prepare working directory
WORKDIR /app

# 📦 Install Python dependencies
COPY requirements.txt ./
RUN pip install --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt --default-timeout=100

# 🧊 Stage 2: Runtime - Lean image for deployment
FROM python:3.10-slim-bookworm

ENV DEBIAN_FRONTEND=noninteractive

# 🛠️ Reinstall required runtime libraries
RUN apt-get update && apt-get install -y \
    libasound2 \
    libjack-jackd2-0 \
    libportaudio2 \
    libportaudiocpp0 \
    libsndfile1 && \
    rm -rf /var/lib/apt/lists/*

# 📁 Set runtime working directory
WORKDIR /app

# ⛓️ Copy installed Python packages from builder
COPY --from=builder /usr/local/lib/python3.10/site-packages /usr/local/lib/python3.10/site-packages

# 📂 Copy app code
COPY . .

# 🌐 Expose port expected by Render
ENV PORT=10000
EXPOSE 10000

# 🚀 Start app with Gunicorn
CMD ["gunicorn", "main:app", "--bind", "0.0.0.0:$PORT"]
