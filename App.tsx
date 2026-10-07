import { NavigationContainer } from '@react-navigation/native';
import * as Updates from 'expo-updates';
import { StatusBar } from 'expo-status-bar';
import React, { useEffect } from 'react';
import { SafeAreaProvider } from 'react-native-safe-area-context';
import { ProgressProvider } from './src/context/ProgressContext';
import { RootNavigator } from './src/navigation/RootNavigator';

export default function App() {
  useEffect(() => {
    async function applyPendingUpdate() {
      if (__DEV__) return;
      try {
        const result = await Updates.checkForUpdateAsync();
        if (result.isAvailable) {
          await Updates.fetchUpdateAsync();
          await Updates.reloadAsync();
        }
      } catch {
        // offline or no update server reachable — ignore and keep running current version
      }
    }
    applyPendingUpdate();
  }, []);

  return (
    <SafeAreaProvider>
      <ProgressProvider>
        <NavigationContainer>
          <RootNavigator />
          <StatusBar style="auto" />
        </NavigationContainer>
      </ProgressProvider>
    </SafeAreaProvider>
  );
}
