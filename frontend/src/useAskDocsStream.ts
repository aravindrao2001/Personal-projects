import { useState } from "react";
import type { Citation, TokenBudget, WidgetError } from "./Types";

type UseAskDocsStreamProps = {
  apiBaseUrl: string;
  onStart: (question: string) => void;
  onToken: (token: string) => void;
  onCitation: (citation: Citation) => void;
  onDone: () => void;
};

export function useAskDocsStream({
  apiBaseUrl,
  onStart,
  onToken,
  onCitation,
  onDone,
}: UseAskDocsStreamProps) {
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<WidgetError | null>(null);
  const [tokenBudget, setTokenBudget] = useState<TokenBudget>({
    used: 0,
    max: 4096,
  });

  const askQuestion = async (question: string, topK = 4) => {
    setIsLoading(true);
    setError(null);
    onStart(question);

    try {
      const response = await fetch(`${apiBaseUrl}/query`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Accept: "text/event-stream",
        },
        body: JSON.stringify({ question, top_k: topK }),
      });

      if (!response.ok) {
        throw new Error(`Request failed with status ${response.status}`);
      }

      if (!response.body) {
        throw new Error("Streaming response body not available");
      }

      const reader = response.body.getReader();
      const decoder = new TextDecoder("utf-8");
      let buffer = "";

      while (true) {
        const { done, value } = await reader.read();
        if (done) break;

        buffer += decoder.decode(value, { stream: true });

        const events = buffer.split("\n\n");
        buffer = events.pop() || "";

        for (const rawEvent of events) {
          const lines = rawEvent.split("\n");
          let eventName = "message";
          let data = "";

          for (const line of lines) {
            if (line.startsWith("event:")) {
              eventName = line.slice(6).trim();
            } else if (line.startsWith("data:")) {
              data += line.slice(5).trim();
            }
          }

          if (!data) continue;

          const parsed = JSON.parse(data);

          switch (eventName) {
            case "meta":
              if (parsed.token_budget) {
                setTokenBudget(parsed.token_budget);
              }
              break;
            case "token":
              console.log("TOKEN:", parsed.text);
              onToken(parsed.text ?? "");
              break;
            case "citation":
              console.log("CITATION:", parsed);
              onCitation(parsed);
              break;
            case "retrieval_error":
              setError({
                type: "retrieval",
                message: parsed.message ?? "Retrieval failed",
              });
              break;
            case "model_error":
              setError({
                type: "model",
                message: parsed.message ?? "Model generation failed",
              });
              break;
            case "done":
              onDone();
              break;
            default:
              break;
          }
        }
      }
    } catch (err) {
      setError({
        type: "network",
        message: err instanceof Error ? err.message : "Network error",
      });
    } finally {
      setIsLoading(false);
    }
  };

  return {
    isLoading,
    error,
    tokenBudget,
    askQuestion,
  };
}