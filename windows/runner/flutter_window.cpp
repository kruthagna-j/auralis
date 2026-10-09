#include "flutter_window.h"

#include <optional>
#include <shellapi.h>

#include "flutter/generated_plugin_registrant.h"

FlutterWindow::FlutterWindow(const flutter::DartProject& project)
    : project_(project) {}

FlutterWindow::~FlutterWindow() {}

void FlutterWindow::SetInitialFiles(const std::vector<std::wstring>& file_paths) {
  initial_files_ = file_paths;
}

// static
std::string FlutterWindow::WStringToUtf8(const std::wstring& wstr) {
  if (wstr.empty()) return {};
  int size = ::WideCharToMultiByte(CP_UTF8, 0, wstr.c_str(), -1,
                                   nullptr, 0, nullptr, nullptr);
  std::string result(size - 1, '\0');
  ::WideCharToMultiByte(CP_UTF8, 0, wstr.c_str(), -1,
                        result.data(), size, nullptr, nullptr);
  return result;
}

void FlutterWindow::SendFilesToFlutter(const std::vector<std::wstring>& file_paths) {
  if (!file_channel_ || file_paths.empty()) return;
  
  flutter::EncodableList pathList;
  for (const auto& path : file_paths) {
    pathList.push_back(flutter::EncodableValue(WStringToUtf8(path)));
  }

  file_channel_->InvokeMethod(
      "openFiles",
      std::make_unique<flutter::EncodableValue>(pathList));
}

bool FlutterWindow::OnCreate() {
  if (!Win32Window::OnCreate()) {
    return false;
  }

  RECT frame = GetClientArea();

  // The size here must match the window dimensions to avoid unnecessary surface
  // creation / destruction in the startup path.
  flutter_controller_ = std::make_unique<flutter::FlutterViewController>(
      frame.right - frame.left, frame.bottom - frame.top, project_);
  // Ensure that basic setup of the controller was successful.
  if (!flutter_controller_->engine() || !flutter_controller_->view()) {
    return false;
  }
  RegisterPlugins(flutter_controller_->engine());
  SetChildContent(flutter_controller_->view()->GetNativeWindow());

  // Set up the MethodChannel for file-open / drag-and-drop events.
  // Dart calls "getInitialFiles" to retrieve startup files (command-line /
  // "Open With"); C++ calls "openFiles" to push drag-dropped files.
  file_channel_ =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          flutter_controller_->engine()->messenger(),
          "com.auralis.app/file_open",
          &flutter::StandardMethodCodec::GetInstance());

  file_channel_->SetMethodCallHandler(
      [this](const flutter::MethodCall<flutter::EncodableValue>& call,
             std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
        if (call.method_name() == "getInitialFiles") {
          if (!initial_files_.empty()) {
            flutter::EncodableList pathList;
            for (const auto& path : initial_files_) {
              pathList.push_back(flutter::EncodableValue(WStringToUtf8(path)));
            }
            result->Success(flutter::EncodableValue(pathList));
            initial_files_.clear();
          } else {
            result->Success(flutter::EncodableValue());  // null → no files
          }
        } else {
          result->NotImplemented();
        }
      });

  // Enable drag-and-drop so that audio files can be dropped onto the window.
  ::DragAcceptFiles(GetHandle(), TRUE);

  flutter_controller_->engine()->SetNextFrameCallback([&]() {
    this->Show();
  });

  // Flutter can complete the first frame before the "show window" callback is
  // registered. The following call ensures a frame is pending to ensure the
  // window is shown. It is a no-op if the first frame hasn't completed yet.
  flutter_controller_->ForceRedraw();

  return true;
}

void FlutterWindow::OnDestroy() {
  if (flutter_controller_) {
    flutter_controller_ = nullptr;
  }

  Win32Window::OnDestroy();
}

LRESULT
FlutterWindow::MessageHandler(HWND hwnd, UINT const message,
                              WPARAM const wparam,
                              LPARAM const lparam) noexcept {
  // Give Flutter, including plugins, an opportunity to handle window messages.
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

    // Handle files dragged and dropped from Windows Explorer.
    case WM_DROPFILES: {
      HDROP hDrop = reinterpret_cast<HDROP>(wparam);
      UINT fileCount = ::DragQueryFileW(hDrop, 0xFFFFFFFF, nullptr, 0);
      static const wchar_t* kAudioExts[] = {
          L".mp3", L".flac", L".wav", L".m4a",
           L".aac", L".opus", L".wma", nullptr};
      
      std::vector<std::wstring> validFiles;
      for (UINT i = 0; i < fileCount; ++i) {
        wchar_t filePath[MAX_PATH];
        if (::DragQueryFileW(hDrop, i, filePath, MAX_PATH)) {
          std::wstring fp(filePath);
          // Only forward recognised audio files.
          for (int e = 0; kAudioExts[e]; ++e) {
            size_t extLen = wcslen(kAudioExts[e]);
            if (fp.size() > extLen &&
                _wcsicmp(fp.c_str() + fp.size() - extLen, kAudioExts[e]) == 0) {
              validFiles.push_back(fp);
              break; 
            }
          }
        }
      }
      
      if (!validFiles.empty()) {
        SendFilesToFlutter(validFiles);
      }

      ::DragFinish(hDrop);
      // Bring window to the foreground after the drop.
      ::SetForegroundWindow(hwnd);
      return 0;
    }
  }

  return Win32Window::MessageHandler(hwnd, message, wparam, lparam);
}

