# Start from a base Python image. Choose a version compatible with your project.
# It's good practice to use a specific tag (e.g., python:3.10-slim-bookworm)
# rather than just python:3.10 to ensure consistent builds.
# Use a slim or alpine version for smaller image size.
FROM python:3.10-slim-bookworm 

# Install system dependencies (PortAudio development files)
# Update apt lists, install the package, and clean up apt cache to keep image small
RUN apt-get update && apt-get install -y \
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
# Render automatically handles port mapping, but it's good practice to expose
EXPOSE 10000 

# Define the command to run your application using Gunicorn (as per your Procfile)
# This uses the same command you had in your Procfile, but now it's inside the Dockerfile
CMD ["gunicorn", "main:app", "--bind", "0.0.0.0:$PORT"]
