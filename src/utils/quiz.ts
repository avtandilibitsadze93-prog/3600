import { Word } from '../types';

export function shuffle<T>(items: T[]): T[] {
  const arr = [...items];
  for (let i = arr.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [arr[i], arr[j]] = [arr[j], arr[i]];
  }
  return arr;
}

function normalize(value: string): string {
  return value.trim().toLowerCase();
}

// ერთ ინგლისურ სიტყვას შეიძლება ერთ ველში ჰქონდეს რამდენიმე ქართული
// ვარიანტი გამოყოფილი "/", "," ან ";" სიმბოლოებით — ნებისმიერი მათგანი მიღებულია.
// ფრჩხილებში მოცემული განმარტება (მაგ. "ქალაქი (პატარა)") დამატებითი კონტექსტია,
// ამიტომ პასუხი მიღებულია ფრჩხილების ჩათვლითაც და მის გარეშეც.
export function isAnswerCorrect(userInput: string, ka: string): boolean {
  const variants = ka.split(/[/,;]/).flatMap((variant) => [variant, variant.replace(/\([^)]*\)/g, '')]);
  const accepted = variants.map(normalize).filter(Boolean);
  return accepted.includes(normalize(userInput));
}

export function pickRandomWords(pool: Word[], count: number): Word[] {
  return shuffle(pool).slice(0, Math.min(count, pool.length));
}
