// src/api/client.ts

const BASE_URL = '';

interface ApiError {
  error: {
    code: string;
    message: string;
  };
}

class ApiClientError extends Error {
  constructor(
    public code: string,
    message: string,
    public status: number,
  ) {
    super(message);
    this.name = 'ApiClientError';
  }
}

async function request<T>(path: string, options: RequestInit = {}): Promise<T> {
  const url = `${BASE_URL}${path}`;
  const headers: HeadersInit = {
    'Content-Type': 'application/json',
    Accept: 'application/json',
    ...options.headers,
  };

  const response = await fetch(url, { ...options, headers });

  if (!response.ok) {
    let errorData: ApiError | undefined;
    try {
      errorData = (await response.json()) as ApiError;
    } catch {
      // response body is not JSON
    }
    throw new ApiClientError(
      errorData?.error?.code ?? 'unknown',
      errorData?.error?.message ?? `HTTP ${response.status}`,
      response.status,
    );
  }

  return (await response.json()) as T;
}

export const api = {
  get: <T>(path: string) => request<T>(path),
  post: <T>(path: string, body?: unknown) =>
    request<T>(path, {
      method: 'POST',
      body: body ? JSON.stringify(body) : undefined,
    }),
};

export { ApiClientError };
