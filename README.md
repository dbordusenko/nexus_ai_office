# FlyPDF

AI-powered PDF toolkit for iOS. Interactive prototype + FastAPI backend with Claude integration.

## Project Structure

- `FlyPDF/preview/` — Interactive HTML/CSS/JS prototype (11 screens)
- `FlyPDF/Sources/` — SwiftUI iOS app source
- `backend/` — FastAPI + Claude AI backend

## Quick Start

### Backend

```bash
cd backend
pip install -r requirements.txt
cp .env.example .env
# Edit .env and add your ANTHROPIC_API_KEY
uvicorn main:app --host 0.0.0.0 --port 8001 --reload
```

Backend runs on `http://localhost:8001`.

### Prototype

Open `FlyPDF/preview/index.html` in a browser. The AI chat auto-detects the backend — falls back to mock responses if unavailable.

## API Endpoints

| Method | Path | Description |
|--------|------|-------------|
| GET | `/health` | Status check |
| POST | `/documents/upload` | Upload a document for analysis |
| POST | `/chat` | Send a message, get a response |
| POST | `/chat/stream` | Streaming chat (SSE) |
| POST | `/analyze` | Run a specific analysis task |

## Features

- PDF analysis with Claude Sonnet 4
- Streaming AI responses
- Document upload and context-aware chat
- 11-screen interactive prototype with SVG icons
