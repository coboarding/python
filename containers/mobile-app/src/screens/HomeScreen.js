import React, { useState, useEffect, useContext } from 'react';
import {
  View,
  Text,
  StyleSheet,
  TouchableOpacity,
  ScrollView,
  RefreshControl,
  ActivityIndicator,
  Image,
  Alert
} from 'react-native';
import Icon from 'react-native-vector-icons/MaterialIcons';
import { ServerContext } from '../context/ServerContext';
import { ProfileContext } from '../context/ProfileContext';
import { fetchServerStatus, fetchRecentForms } from '../services/api';

const HomeScreen = ({ navigation }) => {
  const { serverConfig } = useContext(ServerContext);
  const { activeProfile } = useContext(ProfileContext);
  const [status, setStatus] = useState(null);
  const [recentForms, setRecentForms] = useState([]);
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);

  const loadData = async () => {
    setLoading(true);
    try {
      // Pobierz status serwera
      if (serverConfig && serverConfig.serverUrl) {
        const statusData = await fetchServerStatus(serverConfig.serverUrl);
        setStatus(statusData);

        // Pobierz ostatnie formularze
        const formsData = await fetchRecentForms(serverConfig.serverUrl);
        setRecentForms(formsData);
      } else {
        // Jeśli nie ma konfiguracji serwera, pokaż alert
        Alert.alert(
          'Serwer nie skonfigurowany',
          'Musisz skonfigurować połączenie z serwerem AutoFormFiller.',
          [
            {
              text: 'Konfiguruj',
              onPress: () => navigation.navigate('ServerConfig')
            },
            {
              text: 'Anuluj',
              style: 'cancel'
            }
          ]
        );
      }
    } catch (error) {
      console.error('Błąd podczas ładowania danych:', error);
      Alert.alert(
        'Błąd połączenia',
        'Nie można połączyć się z serwerem AutoFormFiller.'
      );
    } finally {
      setLoading(false);
      setRefreshing(false);
    }
  };

  // Załaduj dane przy pierwszym renderowaniu
  useEffect(() => {
    loadData();
  }, [serverConfig]);

  // Obsługa odświeżania przez pociągnięcie
  const onRefresh = () => {
    setRefreshing(true);
    loadData();
  };

  // Renderowanie statusu serwera
  const renderServerStatus = () => {
    if (!status) return null;

    const statusColor = status.running ? '#2ecc71' : '#e74c3c';

    return (
      <View style={styles.statusCard}>
        <View style={styles.statusHeader}>
          <Text style={styles.cardTitle}>Status serwera</Text>
          <View style={[styles.statusDot, { backgroundColor: statusColor }]} />
        </View>

        <View style={styles.statusDetails}>
          <View style={styles.statusItem}>
            <Text style={styles.statusLabel}>URL:</Text>
            <Text style={styles.statusValue}>{serverConfig?.serverUrl || 'Nie skonfigurowano'}</Text>
          </View>

          <View style={styles.statusItem}>
            <Text style={styles.statusLabel}>Stan:</Text>
            <Text style={styles.statusValue}>{status.running ? 'Działa' : 'Zatrzymany'}</Text>
          </View>

          <View style={styles.statusItem}>
            <Text style={styles.statusLabel}>Model LLM:</Text>
            <Text style={styles.statusValue}>{status.activeModel || 'Brak'}</Text>
          </View>

          <View style={styles.statusItem}>
            <Text style={styles.statusLabel}>Kontenery:</Text>
            <Text style={styles.statusValue}>{status.runningContainers || 0}/{status.totalContainers || 0}</Text>
          </View>
        </View>
      </View>
    );
  };


  // Renderowanie akt
  // Renderowanie akt
  const renderRecentForms = () => {
    if (recentForms.length === 0) {
      return (
          <View style={styles.emptyState}>
            <Icon name="description" size={48} color="#ccc" />
            <Text style={styles.emptyStateText}>Brak ostatnich formularzy</Text>
          </View>
      );
    }

    return (
        <View style={styles.formsCard}>
          <Text style={styles.cardTitle}>Ostatnie formularze</Text>
          {recentForms.map((form, index) => (
              <TouchableOpacity
                  key={form.id}
                  style={styles.formItem}
                  onPress={() => navigation.navigate('FormDetails', { formId: form.id })}
              >
                <View style={styles.formItemContent}>
                  <Icon name="description" size={24} color="#666" />
                  <View style={styles.formItemText}>
                    <Text style={styles.formTitle}>{form.name}</Text>
                    <Text style={styles.formDate}>
                      {new Date(form.lastModified).toLocaleDateString()}
                    </Text>
                  </View>
                </View>
                <Icon name="chevron-right" size={24} color="#666" />
              </TouchableOpacity>
          ))}
        </View>
    );
  };

  if (loading) {
    return (
        <View style={styles.loadingContainer}>
          <ActivityIndicator size="large" color="#0000ff" />
        </View>
    );
  }

  return (
      <ScrollView
          style={styles.container}
          refreshControl={
            <RefreshControl refreshing={refreshing} onRefresh={onRefresh} />
          }
      >
        {renderServerStatus()}
        {renderRecentForms()}

        <TouchableOpacity
            style={styles.newFormButton}
            onPress={() => navigation.navigate('NewForm')}
        >
          <Icon name="add" size={24} color="#fff" />
          <Text style={styles.newFormButtonText}>Nowy formularz</Text>
        </TouchableOpacity>
      </ScrollView>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#f5f5f5',
    padding: 16,
  },
  loadingContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
  },
  statusCard: {
    backgroundColor: '#fff',
    borderRadius: 8,
    padding: 16,
    marginBottom: 16,
    elevation: 2,
  },
  statusHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 16,
  },
  cardTitle: {
    fontSize: 18,
    fontWeight: 'bold',
    color: '#333',
  },
  statusDot: {
    width: 12,
    height: 12,
    borderRadius: 6,
  },
  statusDetails: {
    gap: 8,
  },
  statusItem: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  statusLabel: {
    color: '#666',
    fontSize: 14,
  },
  statusValue: {
    color: '#333',
    fontSize: 14,
    fontWeight: '500',
  },
  formsCard: {
    backgroundColor: '#fff',
    borderRadius: 8,
    padding: 16,
    marginBottom: 16,
    elevation: 2,
  },
  formItem: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingVertical: 12,
    borderBottomWidth: 1,
    borderBottomColor: '#eee',
  },
  formItemContent: {
    flexDirection: 'row',
    alignItems: 'center',
    flex: 1,
  },
  formItemText: {
    marginLeft: 12,
    flex: 1,
  },
  formTitle: {
    fontSize: 16,
    color: '#333',
    fontWeight: '500',
  },
  formDate: {
    fontSize: 12,
    color: '#666',
    marginTop: 4,
  },
  emptyState: {
    alignItems: 'center',
    padding: 32,
  },
  emptyStateText: {
    color: '#666',
    marginTop: 8,
    fontSize: 16,
  },
  newFormButton: {
    backgroundColor: '#007AFF',
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    padding: 16,
    borderRadius: 8,
    marginBottom: 16,
  },
  newFormButtonText: {
    color: '#fff',
    fontSize: 16,
    fontWeight: '600',
    marginLeft: 8,
  },
});

export default HomeScreen;