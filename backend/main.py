import os
from contextlib import asynccontextmanager

import anthropic
from dotenv import load_dotenv
from fastapi import FastAPI, UploadFile, File, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import StreamingResponse
from pydantic import BaseModel

load_dotenv()

client: anthropic.Anthropic | None = None


@asynccontextmanager
async def lifespan(app: FastAPI):
    global client
    api_key = os.getenv("ANTHROPIC_API_KEY")
    if not api_key:
        print("WARNING: ANTHROPIC_API_KEY not set — AI endpoints will fail")
    else:
        client = anthropic.Anthropic(api_key=api_key)
    yield


app = FastAPI(title="FlyPDF API", version="0.1.0", lifespan=lifespan)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

MODEL = os.getenv("CLAUDE_MODEL", "claude-sonnet-4-20250514")

documents: dict[str, dict] = {}


class ChatRequest(BaseModel):
    message: str
    document_id: str | None = None


class AnalyzeRequest(BaseModel):
    document_id: str
    task: str = "summarize"


@app.get("/health")
def health():
    return {"status": "ok", "model": MODEL, "has_key": client is not None}


@app.post("/documents/upload")
async def upload_document(file: UploadFile = File(...)):
    content = await file.read()
    doc_id = f"doc_{len(documents) + 1}"

    text = content.decode("utf-8", errors="ignore")[:50000]

    documents[doc_id] = {
        "id": doc_id,
        "filename": file.filename,
        "size": len(content),
        "text": text,
    }
    return {
        "document_id": doc_id,
        "filename": file.filename,
        "size": len(content),
    }


@app.post("/chat")
async def chat(req: ChatRequest):
    if not client:
        raise HTTPException(503, "API key not configured")

    system = "You are FlyPDF AI Assistant — a helpful PDF analysis tool. Be concise and use markdown formatting. When analyzing documents, highlight key numbers with **bold**."

    messages = [{"role": "user", "content": req.message}]

    if req.document_id and req.document_id in documents:
        doc = documents[req.document_id]
        doc_context = f"Document: {doc['filename']}\n\n{doc['text'][:20000]}"
        messages = [
            {"role": "user", "content": f"<document>\n{doc_context}\n</document>\n\n{req.message}"},
        ]

    response = client.messages.create(
        model=MODEL,
        max_tokens=1024,
        system=system,
        messages=messages,
    )
    return {"response": response.content[0].text}


@app.post("/chat/stream")
async def chat_stream(req: ChatRequest):
    if not client:
        raise HTTPException(503, "API key not configured")

    system = "You are FlyPDF AI Assistant — a helpful PDF analysis tool. Be concise and use markdown formatting. When analyzing documents, highlight key numbers with **bold**."

    messages = [{"role": "user", "content": req.message}]

    if req.document_id and req.document_id in documents:
        doc = documents[req.document_id]
        doc_context = f"Document: {doc['filename']}\n\n{doc['text'][:20000]}"
        messages = [
            {"role": "user", "content": f"<document>\n{doc_context}\n</document>\n\n{req.message}"},
        ]

    def generate():
        with client.messages.stream(
            model=MODEL,
            max_tokens=1024,
            system=system,
            messages=messages,
        ) as stream:
            for text in stream.text_stream:
                yield f"data: {text}\n\n"
        yield "data: [DONE]\n\n"

    return StreamingResponse(generate(), media_type="text/event-stream")


@app.post("/analyze")
async def analyze(req: AnalyzeRequest):
    if not client:
        raise HTTPException(503, "API key not configured")

    if req.document_id not in documents:
        raise HTTPException(404, "Document not found")

    doc = documents[req.document_id]

    prompts = {
        "summarize": "Summarize this document concisely. Highlight key figures with **bold**.",
        "key_numbers": "Extract all key numbers, metrics, and financial figures from this document. Format as a bullet list.",
        "red_flags": "Identify any potential concerns, risks, or red flags in this document.",
        "extract_tables": "Identify and describe any tables found in this document.",
    }

    prompt = prompts.get(req.task, req.task)

    response = client.messages.create(
        model=MODEL,
        max_tokens=1024,
        system="You are FlyPDF AI Assistant. Analyze the provided document and respond concisely with markdown.",
        messages=[
            {"role": "user", "content": f"<document>\n{doc['filename']}\n\n{doc['text'][:20000]}\n</document>\n\n{prompt}"},
        ],
    )
    return {"response": response.content[0].text, "task": req.task}
