import { NativeStackScreenProps } from '@react-navigation/native-stack';
import React from 'react';
import { ScrollView, StyleSheet, Text, View } from 'react-native';
import { AdPlaceholder } from '../components/AdPlaceholder';
import { PrimaryButton } from '../components/PrimaryButton';
import { getUnitsForBook } from '../data/words';
import { colors } from '../theme';
import { RootStackParamList } from '../navigation/types';

type Props = NativeStackScreenProps<RootStackParamList, 'Home'>;

export function HomeScreen({ navigation }: Props) {
  const hasDestinationB2 = getUnitsForBook('destination-b2', 1).length > 0;
  const hasDestinationB1 = getUnitsForBook('destination-b1', 1).length > 0;

  return (
    <ScrollView style={styles.container} contentContainerStyle={styles.content}>
      <Text style={styles.title}>ინგლისური ლექსიკა</Text>
      <Text style={styles.subtitle}>აირჩიეთ სასწავლო მასალა</Text>

      <View style={styles.card}>
        <Text style={styles.cardTitle}>Essential Words</Text>
        <Text style={styles.cardText}>3600 საბაზისო სიტყვა — 6 წიგნი, 30 Unit-ი თითოში</Text>
        <PrimaryButton title="დაწყება" onPress={() => navigation.navigate('BookList')} />
      </View>

      <View style={styles.card}>
        <Text style={styles.cardTitle}>Destination B1</Text>
        <Text style={styles.cardText}>
          {hasDestinationB1 ? 'თემატური ლექსიკა, ფრაზული ზმნები, სიტყვათწარმოება' : 'მასალა მალე დაემატება'}
        </Text>
        <PrimaryButton
          title="დაწყება"
          variant="secondary"
          disabled={!hasDestinationB1}
          onPress={() => navigation.navigate('UnitList', { series: 'destination-b1', book: 1 })}
        />
      </View>

      <View style={styles.card}>
        <Text style={styles.cardTitle}>Destination B2</Text>
        <Text style={styles.cardText}>
          {hasDestinationB2 ? 'თემატური ლექსიკა, ფრაზული ზმნები, სიტყვათწარმოება' : 'მასალა მალე დაემატება'}
        </Text>
        <PrimaryButton
          title="დაწყება"
          variant="secondary"
          disabled={!hasDestinationB2}
          onPress={() => navigation.navigate('UnitList', { series: 'destination-b2', book: 1 })}
        />
      </View>

      <View style={styles.card}>
        <Text style={styles.cardTitle}>ყოველდღიური პრაქტიკა</Text>
        <Text style={styles.cardText}>50 შემთხვევითი სიტყვის სწრაფი ტესტი (Essential Words-დან)</Text>
        <PrimaryButton
          title="დაწყება"
          variant="secondary"
          onPress={() => navigation.navigate('Test', { mode: 'daily' })}
        />
      </View>

      <PrimaryButton title="ჩემი პროგრესი" variant="secondary" onPress={() => navigation.navigate('Progress')} />

      <AdPlaceholder />
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
  title: {
    fontSize: 28,
    fontWeight: '700',
    color: colors.text,
    textAlign: 'center',
  },
  subtitle: {
    fontSize: 15,
    color: colors.muted,
    textAlign: 'center',
    marginBottom: 6,
  },
  card: {
    backgroundColor: colors.card,
    borderRadius: 16,
    padding: 20,
    gap: 10,
    borderWidth: 1,
    borderColor: colors.border,
  },
  cardTitle: {
    fontSize: 19,
    fontWeight: '700',
    color: colors.text,
  },
  cardText: {
    fontSize: 14,
    color: colors.muted,
    marginBottom: 6,
  },
});
