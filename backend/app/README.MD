ask_docs_sample_docs/
│
├── backend/
│   ├── app/
│   │   ├── main.py
│   │   ├── config.py
│   │   ├── retrieval.py
│   │   ├── ingest.py
│   │   ├── storage.py
│   │   ├── llm.py
│   │   ├── schemas.py
│   │   └── safety.py
│   ├── data/
│   ├── docs/
│   ├── scripts/
│   ├── tests/
│   ├── requirements.txt
│   └── mermaid-diagram.png
│
├── frontend/
│   ├── node_modules/
│   ├── public/
│   ├── src/
│   ├── package.json
│   ├── package-lock.json
│   ├── vite.config.ts
│   └── index.html
│
├── deploy/
│   └── helm/
│       ├── charts/
│       ├── templates/
│       ├── .helmignore
│       ├── Chart.yaml
│       └── values.yaml
│
└── README.md


1)Features

Local LLM inference using Ollama

Document indexing from backend/docs/

Vector retrieval using FAISS

Streaming answers to the UI

Inline citations with expandable source snippets

Retrieval error vs model error separation in UI

Approximate token-budget indicator

Helm chart skeleton in /deploy/helm/



2)Your backend uses this requirements.txt:

Install Ollama from its official site, then start it:https://ollama.com/download

ollama serve

Check which model the backend expects in:
backend/app/config.py



3) Setup

2. Backend Setup
Open a terminal and go to the backend folder:
cd backend


Windows:
python -m venv .venv
.venv\Scripts\activate

macOS / Linux:
python3 -m venv .venv
source .venv/bin/activate

Install dependencies:
pip install -r requirements.txt

Start the backend server:
uvicorn app.main:app --reload

Backend runs on:
http://127.0.0.1:8000

Useful endpoints:

Health check: http://127.0.0.1:8000/health
Swagger UI: http://127.0.0.1:8000/docs




3.Frontend Setup 
Open a new terminal and go to the frontend folder:

cd frontend

Install dependencies:
npm install

Run the frontend:
npm run dev

Frontendrunson:
http://127.0.0.1:5173

http://localhost:5173/

Make sure the frontend points to the backend URL:
<AskDocsWidget apiBaseUrl="http://127.0.0.1:8000" />


Running Tests:
cd backend

pytest
