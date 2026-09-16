import { NativeStackScreenProps } from '@react-navigation/native-stack';
import React from 'react';
import { FlatList, Pressable, StyleSheet, Text, View } from 'react-native';
import { CATEGORY_TITLES, DESTINATION_UNIT_TITLES, getCategoriesForUnit, getWordsForUnit } from '../data/words';
import { unitKey, useProgress } from '../context/ProgressContext';
import { colors } from '../theme';
import { RootStackParamList } from '../navigation/types';

type Props = NativeStackScreenProps<RootStackParamList, 'CategoryList'>;

export function CategoryListScreen({ navigation, route }: Props) {
  const { series, book, unit } = route.params;
  const categories = getCategoriesForUnit(series, book, unit);
  const { progress } = useProgress();
  const title = DESTINATION_UNIT_TITLES[series][unit];

  return (
    <View style={styles.container}>
      {title && <Text style={styles.header}>{title}</Text>}
      <FlatList
        data={categories}
        keyExtractor={(item) => item}
        contentContainerStyle={styles.list}
        renderItem={({ item }) => {
          const wordCount = getWordsForUnit(series, book, unit, item).length;
          const key = unitKey(series, book, unit, item);
          const learned = progress.learnedUnits.includes(key);
          const result = progress.unitResults[key];
          return (
            <Pressable
              style={({ pressed }) => [styles.row, pressed && styles.rowPressed]}
              onPress={() => navigation.navigate('Learn', { series, book, unit, category: item })}
            >
              <View style={styles.rowHeader}>
                <Text style={styles.rowTitle}>{CATEGORY_TITLES[item]}</Text>
                {learned && <Text style={styles.badge}>ნასწავლი</Text>}
              </View>
              <Text style={styles.rowSubtitle}>{wordCount} სიტყვა/ფრაზა</Text>
              {result && (
                <Text style={styles.rowSubtitle}>
                  ბოლო ტესტის შედეგი: {result.correct}/{result.total}
                </Text>
              )}
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
  header: {
    fontSize: 16,
    fontWeight: '700',
    color: colors.text,
    paddingHorizontal: 16,
    paddingTop: 16,
  },
  list: {
    padding: 16,
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
  rowHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  rowTitle: {
    fontSize: 17,
    fontWeight: '700',
    color: colors.text,
  },
  rowSubtitle: {
    fontSize: 13,
    color: colors.muted,
    marginTop: 4,
  },
  badge: {
    fontSize: 12,
    color: colors.success,
    fontWeight: '600',
    backgroundColor: colors.successBg,
    paddingHorizontal: 8,
    paddingVertical: 3,
    borderRadius: 8,
  },
});
