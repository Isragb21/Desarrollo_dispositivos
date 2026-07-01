#pragma once

#include <flutter/method_channel.h>
#include <flutter/standard_method_codec.h>

#include <winrt/Windows.Devices.Bluetooth.GenericAttributeProfile.h>
#include <winrt/Windows.Foundation.h>
#include <winrt/Windows.Foundation.Collections.h>
#include <winrt/Windows.Storage.Streams.h>

#include <string>
#include <vector>
#include <mutex>

using namespace winrt;
using namespace winrt::Windows::Devices::Bluetooth::GenericAttributeProfile;
using namespace winrt::Windows::Storage::Streams;

class BleGattServer {
 public:
  BleGattServer();
  ~BleGattServer();

  bool Start();
  void Stop();
  bool UpdateSteps(int value);
  bool UpdateHeartRate(int value);
  bool UpdateCalories(int value);
  bool UpdateStatus(const std::string& value);

 private:
  bool Initialize();

  std::vector<uint8_t> IntToBytes(uint32_t value, int byte_count);

  bool initialized_ = false;
  bool running_ = false;
  std::mutex mutex_;

  GattServiceProvider service_provider_{nullptr};
  GattLocalCharacteristic steps_char_{nullptr};
  GattLocalCharacteristic hr_char_{nullptr};
  GattLocalCharacteristic cal_char_{nullptr};
  GattLocalCharacteristic status_char_{nullptr};
};
