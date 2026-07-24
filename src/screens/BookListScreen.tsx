import { NativeStackScreenProps } from '@react-navigation/native-stack';
import React from 'react';
import { FlatList, Pressable, StyleSheet, Text, View } from 'react-native';
import { BOOK_TITLES, getBookNumbers, getUnitsForBook } from '../data/words';
import { colors } from '../theme';
import { RootStackParamList } from '../navigation/types';

type Props = NativeStackScreenProps<RootStackParamList, 'BookList'>;

export function BookListScreen({ navigation }: Props) {
  const books = getBookNumbers();

  return (
    <View style={styles.container}>
      <FlatList
        data={books}
        keyExtractor={(item) => String(item)}
        contentContainerStyle={styles.list}
        renderItem={({ item }) => {
          const unitCount = getUnitsForBook(item).length;
          const hasData = unitCount > 0;
          return (
            <Pressable
              style={({ pressed }) => [styles.row, pressed && hasData && styles.rowPressed, !hasData && styles.rowDisabled]}
              disabled={!hasData}
              onPress={() => navigation.navigate('UnitList', { book: item })}
            >
              <Text style={styles.rowTitle}>{BOOK_TITLES[item]}</Text>
              <Text style={styles.rowSubtitle}>
                {hasData ? `${unitCount} Unit` : 'მასალა მალე დაემატება'}
              </Text>
            </Pressable>
          );
        }}
      />
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: colors.background,
  },
  list: {
    padding: 16,
    gap: 12,
  },
  row: {
    backgroundColor: colors.card,
    borderRadius: 14,
    padding: 18,
    borderWidth: 1,
    borderColor: colors.border,
    marginBottom: 12,
  },
  rowPressed: {
    opacity: 0.8,
  },
  rowDisabled: {
    opacity: 0.5,
  },
  rowTitle: {
    fontSize: 18,
    fontWeight: '700',
    color: colors.text,
  },
  rowSubtitle: {
    fontSize: 13,
    color: colors.muted,
    marginTop: 4,
  },
});
