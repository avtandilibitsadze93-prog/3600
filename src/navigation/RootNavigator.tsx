import { createNativeStackNavigator } from '@react-navigation/native-stack';
import React from 'react';
import { BookListScreen } from '../screens/BookListScreen';
import { HomeScreen } from '../screens/HomeScreen';
import { LearnScreen } from '../screens/LearnScreen';
import { ProgressOverviewScreen } from '../screens/ProgressOverviewScreen';
import { ResultScreen } from '../screens/ResultScreen';
import { TestScreen } from '../screens/TestScreen';
import { UnitListScreen } from '../screens/UnitListScreen';
import { colors } from '../theme';
import { RootStackParamList } from './types';

const Stack = createNativeStackNavigator<RootStackParamList>();

export function RootNavigator() {
  return (
    <Stack.Navigator
      screenOptions={{
        headerStyle: { backgroundColor: colors.primary },
        headerTintColor: '#ffffff',
        headerTitleStyle: { fontWeight: '700' },
      }}
    >
      <Stack.Screen name="Home" component={HomeScreen} options={{ title: 'ინგლისური ლექსიკა' }} />
      <Stack.Screen name="BookList" component={BookListScreen} options={{ title: 'აირჩიეთ წიგნი' }} />
      <Stack.Screen name="UnitList" component={UnitListScreen} options={{ title: 'Unit-ები' }} />
      <Stack.Screen name="Learn" component={LearnScreen} options={{ title: 'სწავლა' }} />
      <Stack.Screen name="Progress" component={ProgressOverviewScreen} options={{ title: 'ჩემი პროგრესი' }} />
      <Stack.Screen
        name="Test"
        component={TestScreen}
        options={{ title: 'ტესტი', headerBackVisible: false, gestureEnabled: false }}
      />
      <Stack.Screen
        name="Result"
        component={ResultScreen}
        options={{ title: 'შედეგი', headerBackVisible: false, gestureEnabled: false }}
      />
    </Stack.Navigator>
  );
}
