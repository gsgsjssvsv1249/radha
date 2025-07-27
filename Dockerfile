# Start from a base Python image. Let's stick with 3.10-slim-bookworm
# as it's generally stable and well-supported.
FROM python:3.10-slim-bookworm 

# Set noninteractive for apt-get to prevent prompts
ENV DEBIAN_FRONTEND=noninteractive

# Install common build tools and ALL necessary PortAudio/ALSA libraries
# PyAudio might need more than just portaudio19-dev
RUN apt-get clean && apt-get update && apt-get install -y \
    build-essential \
    libasound-dev \
    libjack-dev \
    portaudio19-dev \
    libportaudio2 \
    libportaudiocpp0 \
    libsndfile1-dev \
    ffmpeg \ # ffmpeg is often useful for audio processing, sometimes a hidden dependency
    && rm -rf /var/lib/apt/lists/*

# Set the working directory in the container
WORKDIR /app

# Copy your requirements.txt file first to leverage Docker's build cache
COPY requirements.txt .

# Install Python dependencies
# Increase pip's default timeout in case of slow downloads
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt --default-timeout=100

# Copy the rest of your application code
COPY . .

# Expose the port your Flask app will listen on
EXPOSE 10000 

# Define the command to run your application using Gunicorn (as per your Procfile)
CMD ["gunicorn", "app:app", "--bind", "0.0.0.0:$PORT"]
