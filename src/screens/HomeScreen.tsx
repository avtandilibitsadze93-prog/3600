import { NativeStackScreenProps } from '@react-navigation/native-stack';
import React from 'react';
import { SafeAreaView, StyleSheet, Text, View } from 'react-native';
import { AdPlaceholder } from '../components/AdPlaceholder';
import { PrimaryButton } from '../components/PrimaryButton';
import { colors } from '../theme';
import { RootStackParamList } from '../navigation/types';

type Props = NativeStackScreenProps<RootStackParamList, 'Home'>;

export function HomeScreen({ navigation }: Props) {
  return (
    <SafeAreaView style={styles.container}>
      <View style={styles.content}>
        <Text style={styles.title}>ინგლისური ლექსიკა</Text>
        <Text style={styles.subtitle}>აირჩიეთ სასწავლო რეჟიმი</Text>

        <View style={styles.card}>
          <Text style={styles.cardTitle}>სწავლება</Text>
          <Text style={styles.cardText}>ისწავლეთ სიტყვები წიგნებისა და Unit-ების მიხედვით</Text>
          <PrimaryButton title="დაწყება" onPress={() => navigation.navigate('BookList')} />
        </View>

        <View style={styles.card}>
          <Text style={styles.cardTitle}>ყოველდღიური პრაქტიკა</Text>
          <Text style={styles.cardText}>50 შემთხვევითი სიტყვის სწრაფი ტესტი</Text>
          <PrimaryButton
            title="დაწყება"
            variant="secondary"
            onPress={() => navigation.navigate('Test', { mode: 'daily' })}
          />
        </View>

        <PrimaryButton
          title="ჩემი პროგრესი"
          variant="secondary"
          onPress={() => navigation.navigate('Progress')}
        />
      </View>
      <AdPlaceholder />
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: colors.background,
    padding: 20,
    justifyContent: 'space-between',
  },
  content: {
    flex: 1,
    justifyContent: 'center',
    gap: 20,
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
    marginBottom: 10,
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
