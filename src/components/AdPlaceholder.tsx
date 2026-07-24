import React from 'react';
import { StyleSheet, Text, View } from 'react-native';
import { colors } from '../theme';

// სარეზერვო ადგილი მომავალი AdMob ბანერისთვის.
// მზადყოფნისას აქ ჩაანაცვლეთ react-native-google-mobile-ads-ის <BannerAd /> კომპონენტით.
export function AdPlaceholder() {
  return (
    <View style={styles.container}>
      <Text style={styles.text}>სარეკლამო ბანერისთვის ადგილი</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    height: 56,
    borderRadius: 8,
    backgroundColor: colors.border,
    alignItems: 'center',
    justifyContent: 'center',
  },
  text: {
    color: colors.muted,
    fontSize: 12,
  },
});
