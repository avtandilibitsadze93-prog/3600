import { Series, WordCategory } from '../types';

export type TestParams =
  | { mode: 'unit'; series: Series; book: number; unit: number; category?: WordCategory }
  | { mode: 'daily' };

export type RootStackParamList = {
  Home: undefined;
  BookList: undefined;
  UnitList: { series: Series; book: number };
  CategoryList: { series: Series; book: number; unit: number };
  Learn: { series: Series; book: number; unit: number; category?: WordCategory };
  Test: TestParams;
  Progress: undefined;
  Result: {
    correct: number;
    total: number;
    mode: 'unit' | 'daily';
    series?: Series;
    book?: number;
    unit?: number;
    category?: WordCategory;
  };
};
