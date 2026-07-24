import { NativeStackScreenProps } from '@react-navigation/native-stack';
import * as Speech from 'expo-speech';
import React, { useState } from 'react';
import { StyleSheet, Text, View } from 'react-native';
import { PrimaryButton } from '../components/PrimaryButton';
import { getWordsForUnit } from '../data/words';
import { useProgress } from '../context/ProgressContext';
import { colors } from '../theme';
import { RootStackParamList } from '../navigation/types';

type Props = NativeStackScreenProps<RootStackParamList, 'Learn'>;

export function LearnScreen({ navigation, route }: Props) {
  const { book, unit } = route.params;
  const words = getWordsForUnit(book, unit);
  const { markUnitLearned } = useProgress();
  const [index, setIndex] = useState(0);

  const word = words[index];
  const isLast = index === words.length - 1;

  const speak = () => {
    Speech.stop();
    Speech.speak(word.en, { language: 'en-US' });
  };

  const goNext = () => {
    if (isLast) {
      markUnitLearned(book, unit);
      navigation.replace('Test', { mode: 'unit', book, unit });
    } else {
      setIndex((i) => i + 1);
    }
  };

  const goPrev = () => {
    if (index > 0) setIndex((i) => i - 1);
  };

  if (!word) {
    return (
      <View style={styles.container}>
        <Text style={styles.progress}>ამ Unit-ში სიტყვები ჯერ არ არის დამატებული.</Text>
      </View>
    );
  }

  return (
    <View style={styles.container}>
      <Text style={styles.progress}>
        სიტყვა {index + 1} / {words.length}
      </Text>

      <View style={styles.card}>
        <Text style={styles.english}>{word.en}</Text>
        <PrimaryButton title="🔊 გახმოვანება" onPress={speak} variant="secondary" />
        <View style={styles.divider} />
        <Text style={styles.georgian}>{word.ka}</Text>
      </View>

      <View style={styles.nav}>
        <PrimaryButton title="წინა" onPress={goPrev} variant="secondary" disabled={index === 0} style={styles.navButton} />
        <PrimaryButton
          title={isLast ? 'ტესტის დაწყება' : 'შემდეგი'}
          onPress={goNext}
          style={styles.navButton}
        />
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: colors.background,
    padding: 20,
    justifyContent: 'center',
    gap: 24,
  },
  progress: {
    textAlign: 'center',
    color: colors.muted,
    fontSize: 14,
  },
  card: {
    backgroundColor: colors.card,
    borderRadius: 20,
    padding: 32,
    alignItems: 'center',
    gap: 16,
    borderWidth: 1,
    borderColor: colors.border,
  },
  english: {
    fontSize: 36,
    fontWeight: '800',
    color: colors.text,
  },
  divider: {
    height: 1,
    width: '60%',
    backgroundColor: colors.border,
  },
  georgian: {
    fontSize: 24,
    fontWeight: '600',
    color: colors.primary,
  },
  nav: {
    flexDirection: 'row',
    gap: 12,
  },
  navButton: {
    flex: 1,
  },
});
