import { NativeStackScreenProps } from '@react-navigation/native-stack';
import React from 'react';
import { StyleSheet, Text, View } from 'react-native';
import { PrimaryButton } from '../components/PrimaryButton';
import { colors } from '../theme';
import { RootStackParamList } from '../navigation/types';

type Props = NativeStackScreenProps<RootStackParamList, 'Result'>;

export function ResultScreen({ navigation, route }: Props) {
  const { correct, total, mode, book, unit } = route.params;
  const percent = total > 0 ? Math.round((correct / total) * 100) : 0;

  return (
    <View style={styles.container}>
      <Text style={styles.emoji}>{percent >= 80 ? '🎉' : percent >= 50 ? '💪' : '📚'}</Text>
      <Text style={styles.title}>ტესტი დასრულებულია</Text>
      <Text style={styles.score}>
        {correct} / {total}
      </Text>
      <Text style={styles.percent}>({percent}% სწორი პირველივე მცდელობაზე)</Text>

      <View style={styles.actions}>
        {mode === 'unit' && book !== undefined && unit !== undefined && (
          <PrimaryButton
            title="Unit-ის თავიდან გავლა"
            variant="secondary"
            onPress={() => navigation.replace('Test', { mode: 'unit', book, unit })}
          />
        )}
        <PrimaryButton title="მთავარ გვერდზე დაბრუნება" onPress={() => navigation.popToTop()} />
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: colors.background,
    padding: 24,
    alignItems: 'center',
    justifyContent: 'center',
    gap: 12,
  },
  emoji: {
    fontSize: 56,
  },
  title: {
    fontSize: 22,
    fontWeight: '700',
    color: colors.text,
  },
  score: {
    fontSize: 40,
    fontWeight: '800',
    color: colors.primary,
    marginTop: 8,
  },
  percent: {
    fontSize: 15,
    color: colors.muted,
    marginBottom: 24,
  },
  actions: {
    width: '100%',
    gap: 12,
  },
});
