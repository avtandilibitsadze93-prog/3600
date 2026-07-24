import { Word } from '../types';
import wordsData from './words.json';

export const WORDS: Word[] = wordsData as Word[];

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
