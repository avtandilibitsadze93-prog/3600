import { NativeStackScreenProps } from '@react-navigation/native-stack';
import React, { useEffect, useRef, useState } from 'react';
import { KeyboardAvoidingView, Platform, StyleSheet, Text, TextInput, View } from 'react-native';
import { PrimaryButton } from '../components/PrimaryButton';
import { getAllWords, getWordsForUnit } from '../data/words';
import { todayStr, useProgress } from '../context/ProgressContext';
import { isAnswerCorrect, pickRandomWords, shuffle } from '../utils/quiz';
import { colors } from '../theme';
import { RootStackParamList } from '../navigation/types';
import { Word } from '../types';

type Props = NativeStackScreenProps<RootStackParamList, 'Test'>;

const DAILY_WORD_COUNT = 50;

export function TestScreen({ navigation, route }: Props) {
  const { progress, loading, setDailyWords, saveUnitResult, saveDailySession } = useProgress();
  const [queue, setQueue] = useState<Word[] | null>(null);
  const [totalUnique, setTotalUnique] = useState(0);
  const [input, setInput] = useState('');
  const [feedback, setFeedback] = useState<'none' | 'correct' | 'incorrect'>('none');
  const [seen, setSeen] = useState<Set<string>>(new Set());
  const [correctFirstTry, setCorrectFirstTry] = useState<Set<string>>(new Set());
  const timerRef = useRef<ReturnType<typeof setTimeout> | null>(null);

  useEffect(() => {
    navigation.setOptions({
      title: route.params.mode === 'unit' ? `Unit ${route.params.unit} — ტესტი` : 'ყოველდღიური პრაქტიკა',
    });
  }, [navigation, route.params]);

  useEffect(() => {
    if (loading || queue !== null) return;

    if (route.params.mode === 'unit') {
      const words = getWordsForUnit(route.params.book, route.params.unit);
      setQueue(shuffle(words));
      setTotalUnique(words.length);
      return;
    }

    const all = getAllWords();
    const today = todayStr();
    if (progress.dailyWords && progress.dailyWords.date === today) {
      const ids = new Set(progress.dailyWords.wordIds);
      const words = all.filter((w) => ids.has(w.id));
      setQueue(shuffle(words));
      setTotalUnique(words.length);
    } else {
      const words = pickRandomWords(all, DAILY_WORD_COUNT);
      setDailyWords(words.map((w) => w.id));
      setQueue(shuffle(words));
      setTotalUnique(words.length);
    }
  }, [loading, queue, progress.dailyWords, route.params, setDailyWords]);

  useEffect(() => {
    return () => {
      if (timerRef.current) clearTimeout(timerRef.current);
    };
  }, []);

  if (queue === null) {
    return (
      <View style={styles.container}>
        <Text style={styles.progress}>იტვირთება...</Text>
      </View>
    );
  }

  const current = queue[0];

  const handleSubmit = () => {
    if (!current || feedback !== 'none' || input.trim().length === 0) return;

    const correct = isAnswerCorrect(input, current.ka);
    const firstAttempt = !seen.has(current.id);
    let newCorrectFirstTry = correctFirstTry;

    if (firstAttempt) {
      const newSeen = new Set(seen).add(current.id);
      setSeen(newSeen);
      if (correct) {
        newCorrectFirstTry = new Set(correctFirstTry).add(current.id);
        setCorrectFirstTry(newCorrectFirstTry);
      }
    }

    setFeedback(correct ? 'correct' : 'incorrect');

    const rest = queue.slice(1);
    const nextQueue = correct ? rest : [...rest, current];
    const isFinished = nextQueue.length === 0;
    const finalCorrectCount = newCorrectFirstTry.size;

    timerRef.current = setTimeout(() => {
      setInput('');
      setFeedback('none');
      setQueue(nextQueue);

      if (isFinished) {
        if (route.params.mode === 'unit') {
          saveUnitResult(route.params.book, route.params.unit, finalCorrectCount, totalUnique);
          navigation.replace('Result', {
            correct: finalCorrectCount,
            total: totalUnique,
            mode: 'unit',
            book: route.params.book,
            unit: route.params.unit,
          });
        } else {
          saveDailySession(finalCorrectCount, totalUnique);
          navigation.replace('Result', { correct: finalCorrectCount, total: totalUnique, mode: 'daily' });
        }
      }
    }, correct ? 500 : 1500);
  };

  if (!current) {
    return (
      <View style={styles.container}>
        <Text style={styles.progress}>სიტყვები არ მოიძებნა.</Text>
      </View>
    );
  }

  return (
    <KeyboardAvoidingView
      style={styles.container}
      behavior={Platform.OS === 'ios' ? 'padding' : undefined}
    >
      <Text style={styles.progress}>დარჩენილია {queue.length} სიტყვა (სულ {totalUnique})</Text>

      <View
        style={[
          styles.card,
          feedback === 'correct' && styles.cardCorrect,
          feedback === 'incorrect' && styles.cardIncorrect,
        ]}
      >
        <Text style={styles.english}>{current.en}</Text>
        <TextInput
          style={styles.input}
          placeholder="ჩაწერეთ ქართული მნიშვნელობა"
          placeholderTextColor={colors.muted}
          value={input}
          onChangeText={setInput}
          editable={feedback === 'none'}
          autoCapitalize="none"
          autoCorrect={false}
          onSubmitEditing={handleSubmit}
          returnKeyType="done"
        />
        {feedback === 'incorrect' && <Text style={styles.correctAnswer}>სწორია: {current.ka}</Text>}
      </View>

      <PrimaryButton
        title="შემოწმება"
        onPress={handleSubmit}
        disabled={feedback !== 'none' || input.trim().length === 0}
      />
    </KeyboardAvoidingView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: colors.background,
    padding: 20,
    justifyContent: 'center',
    gap: 20,
  },
  progress: {
    textAlign: 'center',
    color: colors.muted,
    fontSize: 14,
  },
  card: {
    backgroundColor: colors.card,
    borderRadius: 20,
    padding: 28,
    alignItems: 'center',
    gap: 16,
    borderWidth: 2,
    borderColor: colors.border,
  },
  cardCorrect: {
    borderColor: colors.success,
    backgroundColor: colors.successBg,
  },
  cardIncorrect: {
    borderColor: colors.error,
    backgroundColor: colors.errorBg,
  },
  english: {
    fontSize: 32,
    fontWeight: '800',
    color: colors.text,
  },
  input: {
    width: '100%',
    borderWidth: 1,
    borderColor: colors.border,
    borderRadius: 12,
    paddingHorizontal: 16,
    paddingVertical: 12,
    fontSize: 18,
    backgroundColor: '#ffffff',
    color: colors.text,
    textAlign: 'center',
  },
  correctAnswer: {
    fontSize: 16,
    fontWeight: '600',
    color: colors.error,
  },
});
