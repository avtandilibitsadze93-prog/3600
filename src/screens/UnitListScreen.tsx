import { NativeStackScreenProps } from '@react-navigation/native-stack';
import React from 'react';
import { FlatList, Pressable, StyleSheet, Text, View } from 'react-native';
import { DESTINATION_UNIT_TITLES, getCategoriesForUnit, getUnitsForBook } from '../data/words';
import { unitKey, useProgress } from '../context/ProgressContext';
import { colors } from '../theme';
import { RootStackParamList } from '../navigation/types';

type Props = NativeStackScreenProps<RootStackParamList, 'UnitList'>;

export function UnitListScreen({ navigation, route }: Props) {
  const { series, book } = route.params;
  const units = getUnitsForBook(series, book);
  const { progress } = useProgress();
  const isEssential = series === 'essential';

  return (
    <View style={styles.container}>
      <FlatList
        data={units}
        keyExtractor={(item) => String(item)}
        contentContainerStyle={styles.list}
        renderItem={({ item }) => {
          if (isEssential) {
            const key = unitKey(series, book, item);
            const learned = progress.learnedUnits.includes(key);
            const result = progress.unitResults[key];
            return (
              <Pressable
                style={({ pressed }) => [styles.row, pressed && styles.rowPressed]}
                onPress={() => navigation.navigate('Learn', { series, book, unit: item })}
              >
                <View style={styles.rowHeader}>
                  <Text style={styles.rowTitle}>Unit {item}</Text>
                  {learned && <Text style={styles.badge}>ნასწავლი</Text>}
                </View>
                {result && (
                  <Text style={styles.rowSubtitle}>
                    ბოლო ტესტის შედეგი: {result.correct}/{result.total}
                  </Text>
                )}
              </Pressable>
            );
          }

          const categories = getCategoriesForUnit(series, book, item);
          const learnedCount = categories.filter((c) =>
            progress.learnedUnits.includes(unitKey(series, book, item, c))
          ).length;
          const title = DESTINATION_UNIT_TITLES[series][item];
          return (
            <Pressable
              style={({ pressed }) => [styles.row, pressed && styles.rowPressed]}
              onPress={() => navigation.navigate('CategoryList', { series, book, unit: item })}
            >
              <View style={styles.rowHeader}>
                <Text style={styles.rowTitle}>Unit {item}</Text>
                {learnedCount === categories.length && categories.length > 0 && (
                  <Text style={styles.badge}>ნასწავლი</Text>
                )}
              </View>
              {title && <Text style={styles.rowSubtitle}>{title}</Text>}
              <Text style={styles.rowSubtitle}>
                {learnedCount} / {categories.length} კატეგორია ნასწავლი
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
    fontSize: 18,
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
