# Stage 1: Build Stage - Install dependencies and build wheels
# Using a specific, stable Python version from Debian's Bookworm distribution
FROM python:3.10-slim-bookworm as builder

# Set environment variable for non-interactive apt-get commands
ENV DEBIAN_FRONTEND=noninteractive

# Install system dependencies required for building Python packages like PyAudio
# This includes build tools, and all necessary PortAudio/ALSA libraries.
# Combined into a single RUN command with line continuations for readability.
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
# This allows Docker to cache this step if requirements don't change
COPY requirements.txt .

# Upgrade pip to the latest version, then install Python dependencies.
# --no-cache-dir reduces the image size by not storing pip's cache.
# --default-timeout increases the download timeout for packages.
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt --default-timeout=100

# Stage 2: Final Image - A lighter image for running the application
# We'll use the same base image to ensure compatibility
FROM python:3.10-slim-bookworm

# Set environment variable for non-interactive apt-get commands in final image if needed
ENV DEBIAN_FRONTEND=noninteractive

# Copy only the necessary runtime system libraries from the build stage
# This helps keep the final image smaller by only bringing over what's truly needed
# for PyAudio's runtime, not its build tools.
# This might need adjustment if your PyAudio specifically links against dynamic libs
# that aren't in /usr/lib. For now, this is a common approach.
COPY --from=builder /usr/lib/x86_64-linux-gnu/libportaudio.so.2 /usr/lib/x86_64-linux-gnu/
COPY --from=builder /usr/lib/x86_64-linux-gnu/libportaudiocpp.so.0 /usr/lib/x86_64-linux-gnu/
COPY --from=builder /usr/lib/x86_64-linux-gnu/libasound.so.2 /usr/lib/x86_64-linux-gnu/
# Add more if runtime errors occur for other libs (e.g., libsndfile)

# Re-install runtime system dependencies if needed in the final image, 
# or just ensure they are available in the slim base image.
# For simplicity, let's include the runtime libraries directly again if the COPY fails,
# or for libs not specific to build. This helps if the slim base doesn't have them.
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
COPY --from=builder /opt/render/project/src/.venv/lib/python3.10/site-packages /usr/local/lib/python3.10/site-packages
# Adjust /opt/render/project/src/.venv/lib/python3.10/site-packages
# if Render's build directory structure changes, or use the global site-packages path
# directly if pip installs globally in the builder:
# COPY --from=builder /usr/local/lib/python3.10/site-packages /usr/local/lib/python3.10/site-packages

# Copy your application code
COPY . .

# Expose the port your Flask app will listen on
EXPOSE 10000

# Define the command to run your application using Gunicorn
# This assumes your Flask application instance is named 'app' in 'main.py'
CMD ["gunicorn", "main:app", "--bind", "0.0.0.0:$PORT"]
