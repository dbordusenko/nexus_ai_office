import os
from contextlib import asynccontextmanager

from groq import Groq
from dotenv import load_dotenv
from fastapi import FastAPI, UploadFile, File, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import StreamingResponse
from pydantic import BaseModel

load_dotenv()

client: Groq | None = None

SYSTEM_PROMPT = (
    "You are FlyPDF AI Assistant — a helpful PDF analysis tool. "
    "Be concise and use markdown formatting. "
    "When analyzing documents, highlight key numbers with **bold**."
)


@asynccontextmanager
async def lifespan(app: FastAPI):
    global client
    api_key = os.getenv("GROQ_API_KEY")
    if not api_key:
        print("WARNING: GROQ_API_KEY not set — AI endpoints will fail")
    else:
        client = Groq(api_key=api_key)
    yield


app = FastAPI(title="FlyPDF API", version="0.1.0", lifespan=lifespan)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

MODEL = os.getenv("GROQ_MODEL", "llama-3.3-70b-versatile")

documents: dict[str, dict] = {}


class ChatRequest(BaseModel):
    message: str
    document_id: str | None = None


class AnalyzeRequest(BaseModel):
    document_id: str
    task: str = "summarize"


def build_messages(user_text: str, document_id: str | None = None) -> list[dict]:
    content = user_text
    if document_id and document_id in documents:
        doc = documents[document_id]
        content = f"<document>\n{doc['filename']}\n\n{doc['text'][:20000]}\n</document>\n\n{user_text}"
    return [
        {"role": "system", "content": SYSTEM_PROMPT},
        {"role": "user", "content": content},
    ]


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
    return {"document_id": doc_id, "filename": file.filename, "size": len(content)}


@app.post("/chat")
async def chat(req: ChatRequest):
    if not client:
        raise HTTPException(503, "API key not configured")

    messages = build_messages(req.message, req.document_id)
    response = client.chat.completions.create(
        model=MODEL,
        messages=messages,
        max_tokens=1024,
    )
    return {"response": response.choices[0].message.content}


@app.post("/chat/stream")
async def chat_stream(req: ChatRequest):
    if not client:
        raise HTTPException(503, "API key not configured")

    messages = build_messages(req.message, req.document_id)

    def generate():
        stream = client.chat.completions.create(
            model=MODEL,
            messages=messages,
            max_tokens=1024,
            stream=True,
        )
        for chunk in stream:
            delta = chunk.choices[0].delta.content
            if delta:
                yield f"data: {delta}\n\n"
        yield "data: [DONE]\n\n"

    return StreamingResponse(generate(), media_type="text/event-stream")


@app.post("/analyze")
async def analyze(req: AnalyzeRequest):
    if not client:
        raise HTTPException(503, "API key not configured")

    if req.document_id not in documents:
        raise HTTPException(404, "Document not found")

    prompts = {
        "summarize": "Summarize this document concisely. Highlight key figures with **bold**.",
        "key_numbers": "Extract all key numbers, metrics, and financial figures. Format as a bullet list.",
        "red_flags": "Identify any potential concerns, risks, or red flags in this document.",
        "extract_tables": "Identify and describe any tables found in this document.",
    }

    prompt = prompts.get(req.task, req.task)
    messages = build_messages(prompt, req.document_id)
    response = client.chat.completions.create(
        model=MODEL,
        messages=messages,
        max_tokens=1024,
    )
    return {"response": response.choices[0].message.content, "task": req.task}
