import 'dart:convert';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BLEService {
  Future<void> startScan() async {
    try {
      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 15),
        androidUsesFineLocation:
            false, // CORREGIDO: Esto evita el bloqueo de Android
        continuousUpdates: true,
      );
    } catch (_) {
      rethrow;
    }
  }

  Future<bool> ensureBluetoothEnabled() async {
    try {
      final state = await FlutterBluePlus.adapterState.first;
      if (state == BluetoothAdapterState.on) {
        return true;
      }

      await FlutterBluePlus.turnOn();
      final newState = await FlutterBluePlus.adapterState.first;
      return newState == BluetoothAdapterState.on;
    } catch (_) {
      return false;
    }
  }

  // Paso 6: Escanear dispositivos
  Stream<List<ScanResult>> scanForDevices() {
    return FlutterBluePlus.scanResults;
  }

  // Detener el escaneo manualmente si es necesario
  void stopScan() {
    FlutterBluePlus.stopScan();
  }

  // Paso 7: Conectar al dispositivo
  Future<void> connect(BluetoothDevice device) async {
    await device.connect();
  }

  // Desconectar
  Future<void> disconnect(BluetoothDevice device) async {
    await device.disconnect();
  }

  // Escuchar el estado de la conexión (para el Paso 13 de reconexiones)
  Stream<BluetoothConnectionState> getConnectionState(BluetoothDevice device) {
    return device.connectionState;
  }

  // Pasos 8, 9 y Criterio de seguridad: Leer y validar características
  Future<Map<String, dynamic>?> readWeatherCharacteristic(
    BluetoothDevice device,
    String targetUuid,
  ) async {
    try {
      // Descubrir los servicios del dispositivo
      List<BluetoothService> services = await device.discoverServices();

      for (BluetoothService service in services) {
        for (BluetoothCharacteristic characteristic
            in service.characteristics) {
          // Busca el UUID específico
          if (characteristic.uuid.toString().toLowerCase() ==
              targetUuid.toLowerCase()) {
            // Lee el valor en bytes y lo decodifica a String
            List<int> value = await characteristic.read();
            String dataString = utf8.decode(value);

            // Convierte el String a un Mapa (JSON)
            Map<String, dynamic> data = jsonDecode(dataString);

            // CRITERIO DE SEGURIDAD OBLIGATORIO: Validar datos antes de procesarlos
            if (data.containsKey('temperature')) {
              int temp = data['temperature'] is int
                  ? data['temperature']
                  : int.tryParse(data['temperature'].toString()) ?? 0;
              // Rango de -50 a 60
              if (temp < -50 || temp > 60) {
                return null; // Dato inválido o malicioso
              }
            }

            if (data.containsKey('city')) {
              String city = data['city'].toString();
              // Longitud menor a 50 caracteres
              if (city.length >= 50) {
                return null; // Dato inválido o malicioso
              }
            }

            return data;
          }
        }
      }
    } catch (e) {
      return null;
    }
    return null; // Si no encontró la característica
  }
}
