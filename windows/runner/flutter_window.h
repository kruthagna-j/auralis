#ifndef RUNNER_FLUTTER_WINDOW_H_
#define RUNNER_FLUTTER_WINDOW_H_

#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <flutter/method_channel.h>
#include <flutter/standard_method_codec.h>
#include <flutter/encodable_value.h>

#include <memory>
#include <string>

#include "win32_window.h"

// A window that does nothing but host a Flutter view.
class FlutterWindow : public Win32Window {
 public:
  // Creates a new FlutterWindow hosting a Flutter view running |project|.
  explicit FlutterWindow(const flutter::DartProject& project);
  virtual ~FlutterWindow();

  // Stores a list of file paths to be delivered to Flutter after the engine starts.
  // Call this before Create().
  void SetInitialFiles(const std::vector<std::wstring>& file_paths);

 protected:
  // Win32Window:
  bool OnCreate() override;
  void OnDestroy() override;
  LRESULT MessageHandler(HWND window, UINT const message, WPARAM const wparam,
                         LPARAM const lparam) noexcept override;

 private:
  // Converts a wide string to a UTF-8 std::string.
  static std::string WStringToUtf8(const std::wstring& wstr);

  // Sends |file_paths| (wide) to the Flutter/Dart layer via the file channel.
  void SendFilesToFlutter(const std::vector<std::wstring>& file_paths);

  // The project to run.
  flutter::DartProject project_;

  // The Flutter instance hosted by this window.
  std::unique_ptr<flutter::FlutterViewController> flutter_controller_;

  // MethodChannel used for file-open and drag-and-drop communication.
  std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> file_channel_;

  // File paths supplied via command-line / "Open With" before the engine starts.
  std::vector<std::wstring> initial_files_;
};

#endif  // RUNNER_FLUTTER_WINDOW_H_
