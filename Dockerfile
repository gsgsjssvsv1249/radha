# Stage 1: Build Stage - Install dependencies and build wheels
# Using a specific, stable Python version from Debian's Bookworm distribution
FROM python:3.10-slim-bookworm as builder

# Set environment variable for non-interactive apt-get commands
ENV DEBIAN_FRONTEND=noninteractive

# Install system dependencies required for building Python packages like PyAudio
RUN apt-get clean && \
    apt-get update && \
    apt-get install -y \
    build-essential \
    libasound-dev \
    libjack-dev \
    portaudio19-dev \
    libportaudio2 \
    libportaudiocpp0 \
    libsndfile1-dev \
    ffmpeg && \
    rm -rf /var/lib/apt/lists/*

# Set the working directory for the build stage
WORKDIR /app

# Copy only the requirements.txt file first
COPY requirements.txt .

# Upgrade pip to the latest version, then install Python dependencies.
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt --default-timeout=100

# Stage 2: Final Image - A lighter image for running the application
FROM python:3.10-slim-bookworm

# Set environment variable for non-interactive apt-get commands in final image if needed
ENV DEBIAN_FRONTEND=noninteractive

# Install runtime system dependencies. We should explicitly install these again
# in the final stage's OS, rather than trying to copy specific .so files which
# might break if the paths or dependencies aren't perfect.
RUN apt-get clean && apt-get update && apt-get install -y \
    libasound2 \
    libjack-jackd2-0 \
    libportaudio2 \
    libportaudiocpp0 \
    libsndfile1 \
    && rm -rf /var/lib/apt/lists/*

# Set the working directory in the container
WORKDIR /app

# Copy Python packages from the build stage
# THIS IS THE KEY CHANGE: Copy from the standard global site-packages path
# of the Python image, not Render's internal path.
COPY --from=builder /usr/local/lib/python3.10/site-packages /usr/local/lib/python3.10/site-packages

# Copy your application code
COPY . .

# Expose the port your Flask app will listen on
EXPOSE 10000

# Define the command to run your application using Gunicorn
CMD ["gunicorn", "main:app", "--bind", "0.0.0.0:$PORT"]
