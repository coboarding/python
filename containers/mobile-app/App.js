import React, { useState, useEffect } from 'react';
import { NavigationContainer } from '@react-navigation/native';
import { createBottomTabNavigator } from '@react-navigation/bottom-tabs';
import { createStackNavigator } from '@react-navigation/stack';
import AsyncStorage from '@react-native-async-storage/async-storage';
import SplashScreen from 'react-native-splash-screen';
import Icon from 'react-native-vector-icons/MaterialIcons';

// Importy ekranów
import HomeScreen from './src/screens/HomeScreen';
import FormListScreen from './src/screens/FormListScreen';
import FormViewScreen from './src/screens/FormViewScreen';
import SettingsScreen from './src/screens/SettingsScreen';
import ProfileScreen from './src/screens/ProfileScreen';
import ServerConfigScreen from './src/screens/ServerConfigScreen';
import OnboardingScreen from './src/screens/OnboardingScreen';

// Importy kontekstu
import { ServerProvider } from './src/context/ServerContext';
import { ProfileProvider } from './src/context/ProfileContext';

const Tab = createBottomTabNavigator();
const Stack = createStackNavigator();

// Funkcja dla głównego stosu nawigacyjnego
const MainStack = () => (
  <Stack.Navigator
    screenOptions={{
      headerStyle: {
        backgroundColor: '#2c3e50',
      },
      headerTintColor: '#fff',
    }}
  >
    <Stack.Screen
      name="MainTabs"
      component={MainTabs}
      options={{ headerShown: false }}
    />
    <Stack.Screen
      name="FormView"
      component={FormViewScreen}
      options={({ route }) => ({ title: route.params?.formName || 'Formularz' })}
    />
    <Stack.Screen
      name="ServerConfig"
      component={ServerConfigScreen}
      options={{ title: 'Konfiguracja serwera' }}
    />
  </Stack.Navigator>
);

// Funkcja dla zakładek dolnych
const MainTabs = () => (
  <Tab.Navigator
    screenOptions={({ route }) => ({
      headerStyle: {
        backgroundColor: '#2c3e50',
      },
      headerTintColor: '#fff',
      tabBarActiveTintColor: '#3498db',
      tabBarInactiveTintColor: 'gray',
      tabBarStyle: {
        backgroundColor: '#fff',
        borderTopWidth: 1,
        borderTopColor: '#e0e0e0',
      },
      tabBarIcon: ({ focused, color, size }) => {
        let iconName;

        if (route.name === 'Home') {
          iconName = 'home';
        } else if (route.name === 'Forms') {
          iconName = 'list';
        } else if (route.name === 'Profile') {
          iconName = 'person';
        } else if (route.name === 'Settings') {
          iconName = 'settings';
        }

        return <Icon name={iconName} size={size} color={color} />;
      },
    })}
  >
    <Tab.Screen
      name="Home"
      component={HomeScreen}
      options={{ title: 'Pulpit' }}
    />
    <Tab.Screen
      name="Forms"
      component={FormListScreen}
      options={{ title: 'Formularze' }}
    />
    <Tab.Screen
      name="Profile"
      component={ProfileScreen}
      options={{ title: 'Profil' }}
    />
    <Tab.Screen
      name="Settings"
      component={SettingsScreen}
      options={{ title: 'Ustawienia' }}
    />
  </Tab.Navigator>
);

const App = () => {
  const [isFirstLaunch, setIsFirstLaunch] = useState(null);

  useEffect(() => {
    // Sprawdź, czy to pierwsze uruchomienie
    AsyncStorage.getItem('hasLaunchedBefore')
      .then(value => {
        if (value === null) {
          AsyncStorage.setItem('hasLaunchedBefore', 'true');
          setIsFirstLaunch(true);
        } else {
          setIsFirstLaunch(false);
        }

        // Ukryj ekran powitalny
        SplashScreen.hide();
      });
  }, []);

  // Pokaż ładowanie, dopóki nie sprawdzimy, czy to pierwsze uruchomienie
  if (isFirstLaunch === null) {
    return null;
  }

  return (
    <ServerProvider>
      <ProfileProvider>
        <NavigationContainer>
          {isFirstLaunch ? (
            <OnboardingScreen onDone={() => setIsFirstLaunch(false)} />
          ) : (
            <MainStack />
          )}
        </NavigationContainer>
      </ProfileProvider>
    </ServerProvider>
  );
};

export default App;