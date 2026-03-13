import React, { useState } from "react";
import { useAskDocsStream } from "./useAskDocsStream";
import type { Citation, Message } from "./Types";

type AskDocsWidgetProps = {
  apiBaseUrl?: string;
  title?: string;
  maxContextTokens?: number;
};

function TokenBudgetBar({ used, max }: { used: number; max: number }) {
  const percent = Math.min(100, Math.round((used / max) * 100));

  return (
    <div className="ad-token-budget">
      <div className="ad-token-budget-label">
        Context budget: {used} / {max} tokens
      </div>
      <div className="ad-progress">
        <div
          className={`ad-progress-fill ${percent > 85 ? "danger" : ""}`}
          style={{ width: `${percent}%` }}
        />
      </div>
    </div>
  );
}

function ErrorBanner({
  type,
  message,
}: {
  type: "retrieval" | "model" | "network";
  message: string;
}) {
  const label =
    type === "retrieval"
      ? "Retrieval error"
      : type === "model"
      ? "Model error"
      : "Network error";

  return (
    <div className={`ad-error-banner ad-error-${type}`} role="alert">
      <strong>{label}:</strong> {message}
    </div>
  );
}

function CitationBadges({
  citations,
  onToggle,
  expanded,
}: {
  citations: Citation[];
  onToggle: () => void;
  expanded: boolean;
}) {
  return (
    <div className="ad-citation-section">
      <div className="ad-inline-citations">
        {citations.map((c) => (
          <span key={`${c.id}-${c.chunkId ?? ""}`} className="ad-citation-badge">
            [{c.id}]
          </span>
        ))}
      </div>
      <button className="ad-link-btn" onClick={onToggle} type="button">
        {expanded ? "Hide sources" : "Show sources"}
      </button>
    </div>
  );
}

function CitationPanel({ citations }: { citations: Citation[] }) {
  return (
    <div className="ad-citation-panel">
      {citations.map((citation) => (
        <div
          key={`${citation.id}-${citation.chunkId ?? ""}`}
          className="ad-citation-card"
        >
          <div className="ad-citation-title">
            [{citation.id}] {citation.file}
          </div>
          <div className="ad-citation-snippet">{citation.snippet}</div>
        </div>
      ))}
    </div>
  );
}

export function AskDocsWidget({
  apiBaseUrl = "http://localhost:8000",
  title = "Ask Docs",
  maxContextTokens = 4096,
}: AskDocsWidgetProps) {
  const [question, setQuestion] = useState("");
  const [messages, setMessages] = useState<Message[]>([]);
  const [expandedMessageId, setExpandedMessageId] = useState<string | null>(null);

  const { isLoading, error, tokenBudget, askQuestion } = useAskDocsStream({
    apiBaseUrl,
    onStart: (userQuestion) => {
      setMessages((prev) => [
        ...prev,
        {
          id: crypto.randomUUID(),
          role: "user",
          text: userQuestion,
        },
        {
          id: "streaming-assistant",
          role: "assistant",
          text: "",
          citations: [],
        },
      ]);
    },
    onToken: (token) => {
      setMessages((prev) =>
        prev.map((msg) =>
          msg.id === "streaming-assistant"
            ? { ...msg, text: msg.text + token }
            : msg
        )
      );
    },
    onCitation: (citation) => {
      setMessages((prev) =>
        prev.map((msg) =>
          msg.id === "streaming-assistant"
            ? {
                ...msg,
                citations: [...(msg.citations ?? []), citation],
              }
            : msg
        )
      );
    },
    onDone: () => {
      setMessages((prev) =>
        prev.map((msg) =>
          msg.id === "streaming-assistant"
            ? { ...msg, id: `assistant-${crypto.randomUUID()}` }
            : msg
        )
      );
    },
  });

  const handleSend = async () => {
    const trimmed = question.trim();
    if (!trimmed || isLoading) return;
    setQuestion("");
    await askQuestion(trimmed, 4);
  };

  const handleSuggestionClick = (value: string) => {
    setQuestion(value);
  };

  return (
    <div className="ad-widget">
      <div className="ad-header">{title}</div>

      <div className="ad-budget-row">
        <TokenBudgetBar
          used={tokenBudget.used}
          max={tokenBudget.max || maxContextTokens}
        />
      </div>

      {error && <ErrorBanner type={error.type} message={error.message} />}

      <div className="ad-messages">
        {messages.length === 0 ? (
          <div className="ad-empty-state">
            <div className="ad-empty-title">Ask your docs anything</div>

            <div className="ad-empty-subtitle">
              Get grounded answers with citations from your indexed files.
            </div>

            <div className="ad-suggestion-list">
              <button
                type="button"
                className="ad-suggestion-chip"
                onClick={() =>
                  handleSuggestionClick("How many annual leave days do employees get?")
                }
              >
                How many annual leave days do employees get?
              </button>

              <button
                type="button"
                className="ad-suggestion-chip"
                onClick={() =>
                  handleSuggestionClick("What are the sick leave limits?")
                }
              >
                What are the sick leave limits?
              </button>

              <button
                type="button"
                className="ad-suggestion-chip"
                onClick={() =>
                  handleSuggestionClick("Do employees get insurance benefits?")
                }
              >
                Do employees get insurance benefits?
              </button>

              <button
                type="button"
                className="ad-suggestion-chip"
                onClick={() =>
                  handleSuggestionClick("What learning support is available?")
                }
              >
                What learning support is available?
              </button>
            </div>
          </div>
        ) : (
          messages.map((msg) => {
            const isExpanded = expandedMessageId === msg.id;

            return (
              <div
                key={msg.id}
                className={`ad-message ${
                  msg.role === "user" ? "ad-message-user" : "ad-message-assistant"
                }`}
              >
                <div className="ad-message-role">
                  {msg.role === "user" ? "You" : "Assistant"}
                </div>

                <div className="ad-message-text">
                  {msg.text ||
                    (isLoading && msg.id === "streaming-assistant" ? "..." : "")}
                </div>

                {msg.role === "assistant" && (msg.citations?.length ?? 0) > 0 && (
                  <>
                    <CitationBadges
                      citations={msg.citations ?? []}
                      expanded={isExpanded}
                      onToggle={() =>
                        setExpandedMessageId(isExpanded ? null : msg.id)
                      }
                    />
                    {isExpanded && <CitationPanel citations={msg.citations ?? []} />}
                  </>
                )}
              </div>
            );
          })
        )}
      </div>

      <div className="ad-footer">
        <input
          className="ad-input"
          value={question}
          onChange={(e) => setQuestion(e.target.value)}
          placeholder="Ask a question about the docs..."
          onKeyDown={(e) => {
            if (e.key === "Enter") handleSend();
          }}
        />
        <button
          className="ad-send-btn"
          onClick={handleSend}
          disabled={isLoading}
          type="button"
        >
          {isLoading ? "Asking..." : "Send"}
        </button>
      </div>
    </div>
  );
}