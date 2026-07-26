export type TestParams =
  | { mode: 'unit'; book: number; unit: number }
  | { mode: 'daily' };

export type RootStackParamList = {
  Home: undefined;
  BookList: undefined;
  UnitList: { book: number };
  Learn: { book: number; unit: number };
  Test: TestParams;
  Progress: undefined;
  Result: {
    correct: number;
    total: number;
    mode: 'unit' | 'daily';
    book?: number;
    unit?: number;
  };
};
