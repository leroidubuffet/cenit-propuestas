FROM python:3.11-slim

WORKDIR /app

RUN pip install --no-cache-dir fastapi uvicorn anthropic openai

COPY app_*.py ./

EXPOSE 8000
