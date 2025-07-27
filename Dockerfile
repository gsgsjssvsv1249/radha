# Start from a base Python image. Let's try a slightly older, very stable one.
# Python 3.9 or 3.10 are often more compatible with older libraries.
FROM python:3.10-slim-bookworm 

# Set noninteractive for apt-get to prevent prompts
ENV DEBIAN_FRONTEND=noninteractive

# Install system dependencies (PortAudio development files)
# Use a single RUN command to minimize layers and potential issues
RUN apt-get clean && apt-get update && apt-get install -y \
    portaudio19-dev \
    && rm -rf /var/lib/apt/lists/*

# Set the working directory in the container
WORKDIR /app

# Copy your requirements.txt file first to leverage Docker's build cache
COPY requirements.txt .

# Install Python dependencies
# Use --no-cache-dir to prevent pip from storing downloaded wheels, further reducing image size
RUN pip install --no-cache-dir -r requirements.txt

# Copy the rest of your application code
COPY . .

# Expose the port your Flask app will listen on
EXPOSE 10000 

# Define the command to run your application using Gunicorn (as per your Procfile)
# This uses the same command you had in your Procfile, but now it's inside the Dockerfile
CMD ["gunicorn", "main:app", "--bind", "0.0.0.0:$PORT"]
