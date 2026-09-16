import AsyncStorage from '@react-native-async-storage/async-storage';
import React, { createContext, useCallback, useContext, useEffect, useState } from 'react';
import { Series, WordCategory } from '../types';

const STORAGE_KEY = '@evocab_progress_v2';

export interface UnitTestResult {
  correct: number;
  total: number;
  date: string;
}

export interface DailySession {
  date: string;
  correct: number;
  total: number;
}

export interface DailyWordsRecord {
  date: string;
  wordIds: string[];
}

export interface ProgressData {
  learnedUnits: string[]; // "book-unit"
  unitResults: Record<string, UnitTestResult>;
  dailyHistory: DailySession[];
  dailyWords: DailyWordsRecord | null;
}

const DEFAULT_PROGRESS: ProgressData = {
  learnedUnits: [],
  unitResults: {},
  dailyHistory: [],
  dailyWords: null,
};

export function todayStr(): string {
  return new Date().toISOString().slice(0, 10);
}

export function unitKey(series: Series, book: number, unit: number, category?: WordCategory): string {
  return category ? `${series}-${book}-${unit}-${category}` : `${series}-${book}-${unit}`;
}

interface ProgressContextValue {
  progress: ProgressData;
  loading: boolean;
  markUnitLearned: (series: Series, book: number, unit: number, category?: WordCategory) => void;
  saveUnitResult: (
    series: Series,
    book: number,
    unit: number,
    correct: number,
    total: number,
    category?: WordCategory
  ) => void;
  saveDailySession: (correct: number, total: number) => void;
  setDailyWords: (wordIds: string[]) => void;
}

const ProgressContext = createContext<ProgressContextValue | undefined>(undefined);

export function ProgressProvider({ children }: { children: React.ReactNode }) {
  const [progress, setProgress] = useState<ProgressData>(DEFAULT_PROGRESS);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    (async () => {
      try {
        const raw = await AsyncStorage.getItem(STORAGE_KEY);
        if (raw) setProgress(JSON.parse(raw));
      } finally {
        setLoading(false);
      }
    })();
  }, []);

  const update = useCallback((updater: (prev: ProgressData) => ProgressData) => {
    setProgress((prev) => {
      const next = updater(prev);
      AsyncStorage.setItem(STORAGE_KEY, JSON.stringify(next)).catch(() => {});
      return next;
    });
  }, []);

  const markUnitLearned = useCallback(
    (series: Series, book: number, unit: number, category?: WordCategory) => {
      const key = unitKey(series, book, unit, category);
      update((prev) =>
        prev.learnedUnits.includes(key) ? prev : { ...prev, learnedUnits: [...prev.learnedUnits, key] }
      );
    },
    [update]
  );

  const saveUnitResult = useCallback(
    (series: Series, book: number, unit: number, correct: number, total: number, category?: WordCategory) => {
      const key = unitKey(series, book, unit, category);
      update((prev) => ({
        ...prev,
        unitResults: { ...prev.unitResults, [key]: { correct, total, date: new Date().toISOString() } },
      }));
    },
    [update]
  );

  const saveDailySession = useCallback(
    (correct: number, total: number) => {
      update((prev) => ({
        ...prev,
        dailyHistory: [...prev.dailyHistory, { date: new Date().toISOString(), correct, total }].slice(-30),
      }));
    },
    [update]
  );

  const setDailyWords = useCallback(
    (wordIds: string[]) => {
      update((prev) => ({ ...prev, dailyWords: { date: todayStr(), wordIds } }));
    },
    [update]
  );

  return (
    <ProgressContext.Provider
      value={{ progress, loading, markUnitLearned, saveUnitResult, saveDailySession, setDailyWords }}
    >
      {children}
    </ProgressContext.Provider>
  );
}

export function useProgress(): ProgressContextValue {
  const ctx = useContext(ProgressContext);
  if (!ctx) throw new Error('useProgress must be used within ProgressProvider');
  return ctx;
}
