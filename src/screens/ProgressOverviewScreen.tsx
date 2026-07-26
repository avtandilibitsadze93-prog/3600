import { NativeStackScreenProps } from '@react-navigation/native-stack';
import React from 'react';
import { ScrollView, StyleSheet, Text, View } from 'react-native';
import { BOOK_TITLES } from '../data/words';
import { useProgress } from '../context/ProgressContext';
import { summarizeProgress } from '../utils/stats';
import { colors } from '../theme';
import { RootStackParamList } from '../navigation/types';

type Props = NativeStackScreenProps<RootStackParamList, 'Progress'>;

function formatDate(iso: string): string {
  const d = new Date(iso);
  return d.toLocaleDateString('ka-GE', { year: 'numeric', month: 'short', day: 'numeric' });
}

export function ProgressOverviewScreen(_props: Props) {
  const { progress } = useProgress();
  const summary = summarizeProgress(progress);

  return (
    <ScrollView style={styles.container} contentContainerStyle={styles.content}>
      <View style={styles.card}>
        <Text style={styles.cardTitle}>საერთო პროგრესი</Text>
        <Text style={styles.bigNumber}>
          {summary.learnedUnitsAll} / {summary.totalUnitsAll}
        </Text>
        <Text style={styles.cardText}>ნასწავლი Unit-ი</Text>
      </View>

      <View style={styles.card}>
        <Text style={styles.cardTitle}>Unit-ის ტესტები</Text>
        {summary.unitTestsTaken > 0 ? (
          <>
            <Text style={styles.bigNumber}>{summary.unitAvgPercent}%</Text>
            <Text style={styles.cardText}>
              საშუალო სისწორე პირველივე მცდელობაზე ({summary.unitTestsTaken} ტესტი)
            </Text>
          </>
        ) : (
          <Text style={styles.cardText}>ჯერ არცერთი Unit-ის ტესტი არ გაქვთ ჩაბარებული</Text>
        )}
      </View>

      <View style={styles.card}>
        <Text style={styles.cardTitle}>წიგნების მიხედვით</Text>
        {summary.perBook.map((b) => (
          <View key={b.book} style={styles.bookRow}>
            <Text style={styles.bookLabel}>{BOOK_TITLES[b.book]}</Text>
            <Text style={styles.bookValue}>
              {b.learnedUnits} / {b.totalUnits}
            </Text>
          </View>
        ))}
      </View>

      <View style={styles.card}>
        <Text style={styles.cardTitle}>ყოველდღიური პრაქტიკის ისტორია</Text>
        {summary.dailyHistory.length === 0 ? (
          <Text style={styles.cardText}>ჯერ არ გაქვთ გავლილი ყოველდღიური პრაქტიკა</Text>
        ) : (
          summary.dailyHistory.slice(0, 10).map((session, idx) => (
            <View key={idx} style={styles.bookRow}>
              <Text style={styles.bookLabel}>{formatDate(session.date)}</Text>
              <Text style={styles.bookValue}>
                {session.correct} / {session.total}
              </Text>
            </View>
          ))
        )}
      </View>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: colors.background,
  },
  content: {
    padding: 20,
    gap: 16,
  },
  card: {
    backgroundColor: colors.card,
    borderRadius: 16,
    padding: 20,
    borderWidth: 1,
    borderColor: colors.border,
    gap: 6,
  },
  cardTitle: {
    fontSize: 16,
    fontWeight: '700',
    color: colors.text,
    marginBottom: 4,
  },
  bigNumber: {
    fontSize: 32,
    fontWeight: '800',
    color: colors.primary,
  },
  cardText: {
    fontSize: 13,
    color: colors.muted,
  },
  bookRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    paddingVertical: 6,
    borderBottomWidth: 1,
    borderBottomColor: colors.background,
  },
  bookLabel: {
    fontSize: 14,
    color: colors.text,
  },
  bookValue: {
    fontSize: 14,
    fontWeight: '700',
    color: colors.text,
  },
});
