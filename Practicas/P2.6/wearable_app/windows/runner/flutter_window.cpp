#include "flutter_window.h"

#include <optional>

#include "flutter/generated_plugin_registrant.h"

FlutterWindow::FlutterWindow(const flutter::DartProject& project)
    : project_(project) {}

FlutterWindow::~FlutterWindow() {}

bool FlutterWindow::OnCreate() {
  if (!Win32Window::OnCreate()) {
    return false;
  }

  RECT frame = GetClientArea();

  flutter_controller_ = std::make_unique<flutter::FlutterViewController>(
      frame.right - frame.left, frame.bottom - frame.top, project_);
  if (!flutter_controller_->engine() || !flutter_controller_->view()) {
    return false;
  }
  RegisterPlugins(flutter_controller_->engine());
  SetChildContent(flutter_controller_->view()->GetNativeWindow());

  SetupBleChannel();

  flutter_controller_->engine()->SetNextFrameCallback([&]() { this->Show(); });
  flutter_controller_->ForceRedraw();

  return true;
}

void FlutterWindow::OnDestroy() {
  if (ble_server_) {
    ble_server_->Stop();
    ble_server_.reset();
  }
  if (flutter_controller_) {
    flutter_controller_ = nullptr;
  }
  Win32Window::OnDestroy();
}

void FlutterWindow::SetupBleChannel() {
  auto messenger = flutter_controller_->engine()->messenger();
  ble_server_ = std::make_unique<BleGattServer>();

  ble_channel_ = std::make_unique<
      flutter::MethodChannel<flutter::EncodableValue>>(
      messenger, "com.uteq.wearable_app/ble",
      &flutter::StandardMethodCodec::GetInstance());

  ble_channel_->SetMethodCallHandler(
      [this](const flutter::MethodCall<flutter::EncodableValue>& call,
             std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>>
                 result) {
        const auto& method = call.method_name();

        if (method == "startServer") {
          bool ok = ble_server_->Start();
          result->Success(flutter::EncodableValue(ok));
        } else if (method == "stopServer") {
          ble_server_->Stop();
          result->Success();
        } else if (method == "updateSteps") {
          int value = 0;
          if (call.arguments()) {
            auto args = std::get_if<flutter::EncodableMap>(call.arguments());
            if (args) {
              auto it = args->find(flutter::EncodableValue("value"));
              if (it != args->end())
                value = std::get<int32_t>(it->second);
            }
          }
          ble_server_->UpdateSteps(value);
          result->Success();
        } else if (method == "updateHeartRate") {
          int value = 0;
          if (call.arguments()) {
            auto args = std::get_if<flutter::EncodableMap>(call.arguments());
            if (args) {
              auto it = args->find(flutter::EncodableValue("value"));
              if (it != args->end())
                value = std::get<int32_t>(it->second);
            }
          }
          ble_server_->UpdateHeartRate(value);
          result->Success();
        } else if (method == "updateCalories") {
          int value = 0;
          if (call.arguments()) {
            auto args = std::get_if<flutter::EncodableMap>(call.arguments());
            if (args) {
              auto it = args->find(flutter::EncodableValue("value"));
              if (it != args->end())
                value = std::get<int32_t>(it->second);
            }
          }
          ble_server_->UpdateCalories(value);
          result->Success();
        } else if (method == "updateStatus") {
          std::string value;
          if (call.arguments()) {
            auto args = std::get_if<flutter::EncodableMap>(call.arguments());
            if (args) {
              auto it = args->find(flutter::EncodableValue("value"));
              if (it != args->end())
                value = std::get<std::string>(it->second);
            }
          }
          ble_server_->UpdateStatus(value);
          result->Success();
        } else {
          result->NotImplemented();
        }
      });
}

LRESULT
FlutterWindow::MessageHandler(HWND hwnd, UINT const message,
                              WPARAM const wparam,
                              LPARAM const lparam) noexcept {
  if (flutter_controller_) {
    std::optional<LRESULT> result =
        flutter_controller_->HandleTopLevelWindowProc(hwnd, message, wparam,
                                                      lparam);
    if (result) {
      return *result;
    }
  }

  switch (message) {
    case WM_FONTCHANGE:
      flutter_controller_->engine()->ReloadSystemFonts();
      break;
  }

  return Win32Window::MessageHandler(hwnd, message, wparam, lparam);
}
