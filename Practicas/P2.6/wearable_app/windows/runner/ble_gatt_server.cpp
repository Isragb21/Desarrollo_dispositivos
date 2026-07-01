#include "ble_gatt_server.h"

#include <winrt/Windows.Foundation.h>

#include <cstdint>
#include <sstream>

static GUID StringToGuid(const std::string& uuid_str) {
  std::string s = uuid_str;
  for (auto& c : s) {
    if (c == '-') c = ' ';
  }
  std::stringstream ss(s);
  uint32_t d1;
  uint16_t d2, d3;
  uint64_t d4 = 0;
  ss >> std::hex >> d1 >> d2 >> d3 >> d4;
  GUID guid;
  guid.Data1 = d1;
  guid.Data2 = d2;
  guid.Data3 = d3;
  for (int i = 0; i < 8; ++i) {
    guid.Data4[i] = static_cast<uint8_t>((d4 >> ((7 - i) * 8)) & 0xFF);
  }
  return guid;
}

BleGattServer::BleGattServer() {}

BleGattServer::~BleGattServer() {
  Stop();
}

bool BleGattServer::Initialize() {
  if (initialized_) return true;
  initialized_ = true;
  return true;
}

bool BleGattServer::Start() {
  std::lock_guard<std::mutex> lock(mutex_);
  if (running_) return true;
  if (!Initialize()) return false;

  try {
    GUID service_uuid = StringToGuid("19b10000-e8f2-537e-4f6c-d104768a1214");

    auto create_result = GattServiceProvider::CreateAsync(service_uuid).get();
    service_provider_ = create_result.ServiceProvider();
    if (!service_provider_) return false;

    auto service = service_provider_.Service();

    auto create_char = [&](const std::string& uuid_str,
                           const std::vector<uint8_t>& initial_value,
                           GattLocalCharacteristic& out_char) -> bool {
      try {
        GUID char_uuid = StringToGuid(uuid_str);
        GattLocalCharacteristicParameters params;
        params.CharacteristicProperties(
            GattCharacteristicProperties::Read |
            GattCharacteristicProperties::Notify);
        params.ReadProtectionLevel(GattProtectionLevel::Plain);
        params.WriteProtectionLevel(GattProtectionLevel::Plain);

        DataWriter writer;
        writer.WriteBytes(winrt::array_view<const uint8_t>(initial_value));
        params.StaticValue(writer.DetachBuffer());

        auto char_result =
            service.CreateCharacteristicAsync(char_uuid, params).get();
        out_char = char_result.Characteristic();
        return out_char != nullptr;
      } catch (...) {
        return false;
      }
    };

    if (!create_char("19b10001-e8f2-537e-4f6c-d104768a1214",
                     {0, 0, 0, 0}, steps_char_))
      return false;
    if (!create_char("19b10002-e8f2-537e-4f6c-d104768a1214",
                     {70}, hr_char_))
      return false;
    if (!create_char("19b10003-e8f2-537e-4f6c-d104768a1214",
                     {0, 0}, cal_char_))
      return false;

    {
      std::string initial_status = "reposo";
      std::vector<uint8_t> status_bytes(initial_status.begin(),
                                        initial_status.end());
      if (!create_char("19b10004-e8f2-537e-4f6c-d104768a1214",
                       status_bytes, status_char_))
        return false;
    }

    GattServiceProviderAdvertisingParameters adv_params;
    adv_params.IsDiscoverable(true);
    adv_params.IsConnectable(true);
    service_provider_.StartAdvertising(adv_params);

    running_ = true;
    return true;
  } catch (...) {
    return false;
  }
}

void BleGattServer::Stop() {
  std::lock_guard<std::mutex> lock(mutex_);
  if (!running_) return;
  try {
    service_provider_.StopAdvertising();
    service_provider_ = nullptr;
    steps_char_ = nullptr;
    hr_char_ = nullptr;
    cal_char_ = nullptr;
    status_char_ = nullptr;
  } catch (...) {
  }
  running_ = false;
}

bool BleGattServer::UpdateSteps(int value) {
  std::lock_guard<std::mutex> lock(mutex_);
  if (!running_ || !steps_char_) return false;
  try {
    auto bytes = IntToBytes(static_cast<uint32_t>(value), 4);
    DataWriter writer;
    writer.WriteBytes(winrt::array_view<const uint8_t>(bytes));
    steps_char_.NotifyValueAsync(writer.DetachBuffer()).get();
    return true;
  } catch (...) {
    return false;
  }
}

bool BleGattServer::UpdateHeartRate(int value) {
  std::lock_guard<std::mutex> lock(mutex_);
  if (!running_ || !hr_char_) return false;
  try {
    std::vector<uint8_t> bytes = {
        static_cast<uint8_t>(value & 0xFF)};
    DataWriter writer;
    writer.WriteBytes(winrt::array_view<const uint8_t>(bytes));
    hr_char_.NotifyValueAsync(writer.DetachBuffer()).get();
    return true;
  } catch (...) {
    return false;
  }
}

bool BleGattServer::UpdateCalories(int value) {
  std::lock_guard<std::mutex> lock(mutex_);
  if (!running_ || !cal_char_) return false;
  try {
    auto bytes = IntToBytes(static_cast<uint32_t>(value), 2);
    DataWriter writer;
    writer.WriteBytes(winrt::array_view<const uint8_t>(bytes));
    cal_char_.NotifyValueAsync(writer.DetachBuffer()).get();
    return true;
  } catch (...) {
    return false;
  }
}

bool BleGattServer::UpdateStatus(const std::string& value) {
  std::lock_guard<std::mutex> lock(mutex_);
  if (!running_ || !status_char_) return false;
  try {
    std::vector<uint8_t> bytes(value.begin(), value.end());
    DataWriter writer;
    writer.WriteBytes(winrt::array_view<const uint8_t>(bytes));
    status_char_.NotifyValueAsync(writer.DetachBuffer()).get();
    return true;
  } catch (...) {
    return false;
  }
}

std::vector<uint8_t> BleGattServer::IntToBytes(uint32_t value,
                                                int byte_count) {
  std::vector<uint8_t> bytes(byte_count);
  for (int i = 0; i < byte_count; ++i) {
    bytes[i] = static_cast<uint8_t>((value >> (i * 8)) & 0xFF);
  }
  return bytes;
}
