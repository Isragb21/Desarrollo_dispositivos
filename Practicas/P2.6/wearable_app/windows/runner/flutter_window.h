#ifndef RUNNER_FLUTTER_WINDOW_H_
#define RUNNER_FLUTTER_WINDOW_H_

#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <flutter/method_channel.h>
#include <flutter/standard_method_codec.h>

#include <memory>

#include "ble_gatt_server.h"
#include "win32_window.h"

class FlutterWindow : public Win32Window {
 public:
  explicit FlutterWindow(const flutter::DartProject& project);
  virtual ~FlutterWindow();

 protected:
  bool OnCreate() override;
  void OnDestroy() override;
  LRESULT MessageHandler(HWND window, UINT const message, WPARAM const wparam,
                         LPARAM const lparam) noexcept override;

 private:
  void SetupBleChannel();

  flutter::DartProject project_;
  std::unique_ptr<flutter::FlutterViewController> flutter_controller_;
  std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> ble_channel_;
  std::unique_ptr<BleGattServer> ble_server_;
};

#endif  // RUNNER_FLUTTER_WINDOW_H_
