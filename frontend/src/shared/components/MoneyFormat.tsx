// src/shared/components/MoneyFormat.tsx

interface MoneyFormatProps {
  cents: number;
  currency?: string;
}

export default function MoneyFormat({ cents, currency = 'RUB' }: MoneyFormatProps) {
  const amount = (cents / 100).toFixed(2);
  const symbol = currency === 'RUB' ? '\u20BD' : currency;
  return (
    <span>
      {amount} {symbol}
    </span>
  );
}
