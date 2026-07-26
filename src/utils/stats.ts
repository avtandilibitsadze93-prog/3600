import { ProgressData } from '../context/ProgressContext';
import { getBookNumbers, getUnitsForBook } from '../data/words';

export interface BookProgress {
  book: number;
  totalUnits: number;
  learnedUnits: number;
}

export interface ProgressSummary {
  perBook: BookProgress[];
  totalUnitsAll: number;
  learnedUnitsAll: number;
  unitTestsTaken: number;
  unitAvgPercent: number | null;
  dailyHistory: ProgressData['dailyHistory'];
}

export function summarizeProgress(progress: ProgressData): ProgressSummary {
  const perBook: BookProgress[] = getBookNumbers().map((book) => {
    const totalUnits = getUnitsForBook(book).length;
    const learnedUnits = progress.learnedUnits.filter((key) => key.startsWith(`${book}-`)).length;
    return { book, totalUnits, learnedUnits };
  });

  const totalUnitsAll = perBook.reduce((sum, b) => sum + b.totalUnits, 0);
  const learnedUnitsAll = perBook.reduce((sum, b) => sum + b.learnedUnits, 0);

  const unitResultsList = Object.values(progress.unitResults);
  const unitTestsTaken = unitResultsList.length;
  const unitAvgPercent =
    unitTestsTaken > 0
      ? Math.round(
          (unitResultsList.reduce((sum, r) => sum + (r.total > 0 ? r.correct / r.total : 0), 0) /
            unitTestsTaken) *
            100
        )
      : null;

  const dailyHistory = [...progress.dailyHistory].reverse();

  return { perBook, totalUnitsAll, learnedUnitsAll, unitTestsTaken, unitAvgPercent, dailyHistory };
}
