# ──────────────────────────────────────────────────────────────
# PetScan AI Backend — Cloud Run container
# ──────────────────────────────────────────────────────────────
# Build:   docker build -t petscan-ai ./backend
# Run:     docker run -p 8080:8080 petscan-ai
# Deploy:  gcloud run deploy petscan-ai --source ./backend ...
# ──────────────────────────────────────────────────────────────

FROM python:3.11-slim

# Prevent Python from buffering stdout/stderr (so Cloud Run logs appear in real-time)
ENV PYTHONUNBUFFERED=1

WORKDIR /app

# 1. Install dependencies first (Docker layer caching speeds up rebuilds)
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# 2. Copy the AI model files into the container
#    These are copied from lib/AI/models/ → /app/models/
COPY models/ ./models/

# 3. Copy the backend source code
COPY main.py .
COPY serviceAccount.json .

# 4. Cloud Run sets the PORT env variable (default 8080)
ENV PORT=8080

# 5. Start the FastAPI server
CMD exec uvicorn main:app --host 0.0.0.0 --port $PORT --workers 1
