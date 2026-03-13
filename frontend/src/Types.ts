export type Citation = {
  id: number;
  file: string;
  snippet: string;
  chunkId?: string;
};

export type WidgetError = {
  type: "retrieval" | "model" | "network";
  message: string;
};

export type TokenBudget = {
  used: number;
  max: number;
};

export type Message = {
  id: string;
  role: "user" | "assistant";
  text: string;
  citations?: Citation[];
};