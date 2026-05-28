# Nexus AI Office Standalone

This is a standalone version of the AI Office (Agents) module, extracted from the Nexus MRP project.

## Project Structure

- `frontend/`: React + Vite application
- `backend/`: FastAPI application

## Getting Started

### Backend

1. Navigate to the `backend` folder.
2. Install dependencies:
   ```bash
   pip install fastapi uvicorn anthropic openai python-dotenv
   ```
3. Run the backend:
   ```bash
   python main.py
   ```
   The backend will run on `http://localhost:8001`.

### Frontend

1. Navigate to the `frontend` folder.
2. Install dependencies:
   ```bash
   npm install
   ```
3. Run the frontend:
   ```bash
   npm run dev
   ```
   The frontend will run on `http://localhost:5173` (or the next available port).

## Features

- **Autonomous Agents**: Powered by Claude 3.5 Sonnet (via Anthropic or OpenRouter).
- **Interactive Floor Plan**: Visualize and interact with the AI agents in their virtual office.
- **Tool Calling**: Agents can read/write files and execute shell commands within the project root.
