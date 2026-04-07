// src/shared/components/ErrorDisplay.tsx

interface ErrorDisplayProps {
  message: string;
}

export default function ErrorDisplay({ message }: ErrorDisplayProps) {
  return (
    <div className="rounded-lg border border-red-800 bg-red-900/30 p-4 text-red-300">
      <p className="font-medium">Error</p>
      <p className="text-sm">{message}</p>
    </div>
  );
}
