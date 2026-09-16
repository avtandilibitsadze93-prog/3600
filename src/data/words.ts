import { Series, Word, WordCategory } from '../types';
import essentialData from './words.json';
import destinationB2Data from './destinationB2.json';

export const WORDS: Word[] = [...(essentialData as Word[]), ...(destinationB2Data as Word[])];

export const BOOK_TITLES: Record<number, string> = {
  1: 'წიგნი 1',
  2: 'წიგნი 2',
  3: 'წიგნი 3',
  4: 'წიგნი 4',
  5: 'წიგნი 5',
  6: 'წიგნი 6',
};

export const CATEGORY_TITLES: Record<WordCategory, string> = {
  topic: 'თემატური ლექსიკა კონტრასტში',
  phrasal: 'ფრაზული ზმნები',
  formation: 'სიტყვათწარმოება',
};

export const DESTINATION_UNIT_TITLES: Record<Series, Record<number, string>> = {
  essential: {},
  'destination-b1': {},
  'destination-b2': {
    2: 'Travel and transport',
    4: 'Hobbies, sport and games',
    6: 'Science and technology',
    8: 'The media',
    10: 'People and society',
    12: 'The law and crime',
    14: 'Health and fitness',
    16: 'Food and drink',
    18: 'Education and learning',
    20: 'Weather and the environment',
    22: 'Money and shopping',
    24: 'Entertainment',
    26: 'Fashion and design',
    28: 'Work and business',
  },
};

export function getBookNumbers(series: Series): number[] {
  const books = new Set(WORDS.filter((w) => w.series === series).map((w) => w.book));
  return Array.from(books).sort((a, b) => a - b);
}

export function getUnitsForBook(series: Series, book: number): number[] {
  const units = new Set(WORDS.filter((w) => w.series === series && w.book === book).map((w) => w.unit));
  return Array.from(units).sort((a, b) => a - b);
}

export function getCategoriesForUnit(series: Series, book: number, unit: number): WordCategory[] {
  const order: WordCategory[] = ['topic', 'phrasal', 'formation'];
  const present = new Set(
    WORDS.filter((w) => w.series === series && w.book === book && w.unit === unit && w.category).map(
      (w) => w.category as WordCategory
    )
  );
  return order.filter((c) => present.has(c));
}

export function getWordsForUnit(series: Series, book: number, unit: number, category?: WordCategory): Word[] {
  return WORDS.filter(
    (w) =>
      w.series === series &&
      w.book === book &&
      w.unit === unit &&
      (category === undefined || w.category === category)
  );
}

export function getEssentialWords(): Word[] {
  return WORDS.filter((w) => w.series === 'essential');
}
