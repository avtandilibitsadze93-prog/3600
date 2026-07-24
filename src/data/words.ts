import { Word } from '../types';

// Placeholder მონაცემები საწყისი ტესტირებისთვის.
// შემდეგ ეტაპზე აქ ჩაიწერება რეალური 3600 სიტყვა Word ფაილიდან.
export const WORDS: Word[] = [
  { id: 'b1u1w1', book: 1, unit: 1, en: 'apple', ka: 'ვაშლი' },
  { id: 'b1u1w2', book: 1, unit: 1, en: 'book', ka: 'წიგნი' },
  { id: 'b1u1w3', book: 1, unit: 1, en: 'water', ka: 'წყალი' },
  { id: 'b1u1w4', book: 1, unit: 1, en: 'house', ka: 'სახლი' },
  { id: 'b1u1w5', book: 1, unit: 1, en: 'dog', ka: 'ძაღლი' },
  { id: 'b1u1w6', book: 1, unit: 1, en: 'cat', ka: 'კატა' },
  { id: 'b1u1w7', book: 1, unit: 1, en: 'sun', ka: 'მზე' },
  { id: 'b1u1w8', book: 1, unit: 1, en: 'moon', ka: 'მთვარე' },
  { id: 'b1u1w9', book: 1, unit: 1, en: 'friend', ka: 'მეგობარი' },
  { id: 'b1u1w10', book: 1, unit: 1, en: 'school', ka: 'სკოლა' },
  { id: 'b1u1w11', book: 1, unit: 1, en: 'table', ka: 'მაგიდა' },
  { id: 'b1u1w12', book: 1, unit: 1, en: 'chair', ka: 'სკამი' },
  { id: 'b1u1w13', book: 1, unit: 1, en: 'road', ka: 'გზა' },
  { id: 'b1u1w14', book: 1, unit: 1, en: 'city', ka: 'ქალაქი' },
  { id: 'b1u1w15', book: 1, unit: 1, en: 'tree', ka: 'ხე' },

  { id: 'b1u2w1', book: 1, unit: 2, en: 'morning', ka: 'დილა' },
  { id: 'b1u2w2', book: 1, unit: 2, en: 'evening', ka: 'საღამო' },
  { id: 'b1u2w3', book: 1, unit: 2, en: 'night', ka: 'ღამე' },
  { id: 'b1u2w4', book: 1, unit: 2, en: 'work', ka: 'სამუშაო' },
  { id: 'b1u2w5', book: 1, unit: 2, en: 'family', ka: 'ოჯახი' },
  { id: 'b1u2w6', book: 1, unit: 2, en: 'child', ka: 'ბავშვი' },
  { id: 'b1u2w7', book: 1, unit: 2, en: 'mother', ka: 'დედა' },
  { id: 'b1u2w8', book: 1, unit: 2, en: 'father', ka: 'მამა' },
  { id: 'b1u2w9', book: 1, unit: 2, en: 'brother', ka: 'ძმა' },
  { id: 'b1u2w10', book: 1, unit: 2, en: 'sister', ka: 'და' },
  { id: 'b1u2w11', book: 1, unit: 2, en: 'food', ka: 'საკვები' },
  { id: 'b1u2w12', book: 1, unit: 2, en: 'bread', ka: 'პური' },
  { id: 'b1u2w13', book: 1, unit: 2, en: 'milk', ka: 'რძე' },
  { id: 'b1u2w14', book: 1, unit: 2, en: 'money', ka: 'ფული' },
  { id: 'b1u2w15', book: 1, unit: 2, en: 'time', ka: 'დრო' },
];

export const BOOK_TITLES: Record<number, string> = {
  1: 'წიგნი 1',
  2: 'წიგნი 2',
  3: 'წიგნი 3',
  4: 'წიგნი 4',
  5: 'წიგნი 5',
  6: 'წიგნი 6',
};

export function getBookNumbers(): number[] {
  return [1, 2, 3, 4, 5, 6];
}

export function getUnitsForBook(book: number): number[] {
  const units = new Set(WORDS.filter((w) => w.book === book).map((w) => w.unit));
  return Array.from(units).sort((a, b) => a - b);
}

export function getWordsForUnit(book: number, unit: number): Word[] {
  return WORDS.filter((w) => w.book === book && w.unit === unit);
}

export function getAllWords(): Word[] {
  return WORDS;
}
