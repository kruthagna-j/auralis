#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>
#include <shobjidl.h>
#include <shlobj.h>
#include <shellapi.h>
#include <propvarutil.h>
#include <propkey.h>
#include <string>

#include "flutter_window.h"
#include "utils.h"

// The AppUserModelID used for SMTC identification.
static const wchar_t kAppUserModelId[] = L"com.auralis.app";
static const wchar_t kAppDisplayName[] = L"Auralis";

// Creates a Start Menu shortcut with the AppUserModelID so that Windows SMTC
// can resolve the app name (instead of showing "Unknown app").
static void EnsureStartMenuShortcut() {
  wchar_t appPath[MAX_PATH];
  if (!::GetModuleFileNameW(nullptr, appPath, MAX_PATH)) return;

  // Build shortcut path: %APPDATA%\Microsoft\Windows\Start Menu\Programs\Auralis.lnk
  wchar_t shortcutDir[MAX_PATH];
  if (FAILED(::SHGetFolderPathW(nullptr, CSIDL_PROGRAMS, nullptr, 0, shortcutDir)))
    return;

  std::wstring shortcutPath = std::wstring(shortcutDir) + L"\\Auralis.lnk";

  IShellLinkW* shellLink = nullptr;
  HRESULT hr = ::CoCreateInstance(CLSID_ShellLink, nullptr, CLSCTX_INPROC_SERVER,
                                  IID_PPV_ARGS(&shellLink));
  if (FAILED(hr)) return;

  IPersistFile* persistFile = nullptr;
  hr = shellLink->QueryInterface(IID_PPV_ARGS(&persistFile));
  if (FAILED(hr)) { shellLink->Release(); return; }

  bool needsUpdate = true;
  if (SUCCEEDED(persistFile->Load(shortcutPath.c_str(), STGM_READ))) {
    wchar_t existingPath[MAX_PATH];
    if (SUCCEEDED(shellLink->GetPath(existingPath, MAX_PATH, nullptr, 0))) {
      if (_wcsicmp(existingPath, appPath) == 0) {
        needsUpdate = false;
      }
    }
  }

  if (needsUpdate) {
    shellLink->SetPath(appPath);
    shellLink->SetDescription(kAppDisplayName);

    IPropertyStore* propStore = nullptr;
    hr = shellLink->QueryInterface(IID_PPV_ARGS(&propStore));
    if (SUCCEEDED(hr)) {
      PROPVARIANT pv;
      hr = ::InitPropVariantFromString(kAppUserModelId, &pv);
      if (SUCCEEDED(hr)) {
        propStore->SetValue(PKEY_AppUserModel_ID, pv);
        ::PropVariantClear(&pv);
      }
      propStore->Commit();
      propStore->Release();
    }

    persistFile->Save(shortcutPath.c_str(), TRUE);
  }

  persistFile->Release();
  shellLink->Release();
}


static void RegisterFileAssociations() {
  wchar_t appPath[MAX_PATH];
  if (!::GetModuleFileNameW(nullptr, appPath, MAX_PATH)) return;

  std::wstring exePath(appPath);
  std::wstring cmdTemplate = L"\"" + exePath + L"\" \"%1\"";

  const wchar_t* kProgId = L"AuralisFile";
  std::wstring progIdBase = std::wstring(L"SOFTWARE\\Classes\\") + kProgId;

  HKEY hKey = nullptr;

  if (::RegCreateKeyExW(HKEY_CURRENT_USER, progIdBase.c_str(), 0, nullptr, 0,
                        KEY_SET_VALUE, nullptr, &hKey, nullptr) == ERROR_SUCCESS) {
    const wchar_t* displayName = L"Auralis File";
    ::RegSetValueExW(hKey, nullptr, 0, REG_SZ,
                     reinterpret_cast<const BYTE*>(displayName),
                     (static_cast<DWORD>(wcslen(displayName)) + 1) * sizeof(wchar_t));
    ::RegCloseKey(hKey);
  }

  std::wstring iconKey = progIdBase + L"\\DefaultIcon";
  if (::RegCreateKeyExW(HKEY_CURRENT_USER, iconKey.c_str(), 0, nullptr, 0,
                        KEY_SET_VALUE, nullptr, &hKey, nullptr) == ERROR_SUCCESS) {
    std::wstring iconVal = L"\"" + exePath + L"\",0";
    ::RegSetValueExW(hKey, nullptr, 0, REG_SZ,
                     reinterpret_cast<const BYTE*>(iconVal.c_str()),
                     (static_cast<DWORD>(iconVal.size()) + 1) * sizeof(wchar_t));
    ::RegCloseKey(hKey);
  }

  std::wstring openCmdKey = progIdBase + L"\\shell\\open\\command";
  if (::RegCreateKeyExW(HKEY_CURRENT_USER, openCmdKey.c_str(), 0, nullptr, 0,
                        KEY_SET_VALUE, nullptr, &hKey, nullptr) == ERROR_SUCCESS) {
    ::RegSetValueExW(hKey, nullptr, 0, REG_SZ,
                     reinterpret_cast<const BYTE*>(cmdTemplate.c_str()),
                     (static_cast<DWORD>(cmdTemplate.size()) + 1) * sizeof(wchar_t));
    ::RegCloseKey(hKey);
  }

  static const wchar_t* kExts[] = {
      L".mp3", L".flac", L".wav", L".m4a",
      L".aac", L".opus", L".wma", nullptr};
  for (int i = 0; kExts[i]; ++i) {
    std::wstring extKey =
        std::wstring(L"SOFTWARE\\Classes\\") + kExts[i] + L"\\OpenWithProgids";
    if (::RegCreateKeyExW(HKEY_CURRENT_USER, extKey.c_str(), 0, nullptr, 0,
                          KEY_SET_VALUE, nullptr, &hKey, nullptr) == ERROR_SUCCESS) {
      ::RegSetValueExW(hKey, kProgId, 0, REG_NONE, nullptr, 0);
      ::RegCloseKey(hKey);
    }
  }

  ::SHChangeNotify(SHCNE_ASSOCCHANGED, SHCNF_IDLIST, nullptr, nullptr);
}

static std::vector<std::wstring> GetAudioFilesFromCommandLine() {
  int argc = 0;
  wchar_t** argv = ::CommandLineToArgvW(::GetCommandLineW(), &argc);
  if (!argv) return {};

  std::vector<std::wstring> results;
  static const wchar_t* kAudioExts[] = {
      L".mp3", L".flac", L".wav", L".m4a",
      L".aac", L".opus", L".wma", nullptr};

  for (int i = 1; i < argc; ++i) {
    std::wstring arg(argv[i]);
    for (int e = 0; kAudioExts[e]; ++e) {
      size_t extLen = wcslen(kAudioExts[e]);
      if (arg.size() > extLen &&
          _wcsicmp(arg.c_str() + arg.size() - extLen, kAudioExts[e]) == 0) {
        results.push_back(arg);
        break;
      }
    }
  }

  ::LocalFree(argv);
  return results;
}

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t *command_line, _In_ int show_command) {

  if (!::AttachConsole(ATTACH_PARENT_PROCESS) && ::IsDebuggerPresent()) {
    CreateAndAttachConsole();
  }


  ::CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);

  ::SetCurrentProcessExplicitAppUserModelID(kAppUserModelId);


  EnsureStartMenuShortcut();

  RegisterFileAssociations();


  std::vector<std::wstring> initialAudioFiles = GetAudioFilesFromCommandLine();

  flutter::DartProject project(L"data");

  std::vector<std::string> command_line_arguments =
      GetCommandLineArguments();

  project.set_dart_entrypoint_arguments(std::move(command_line_arguments));

  FlutterWindow window(project);
  if (!initialAudioFiles.empty()) {
    window.SetInitialFiles(initialAudioFiles);
  }
  Win32Window::Point origin(10, 10);
  Win32Window::Size size(450, 780);
  if (!window.Create(L"Auralis", origin, size)) {
    return EXIT_FAILURE;
  }

  window.SetQuitOnClose(true);

  window.SetMinimumSize(size);

  ::MSG msg;
  while (::GetMessage(&msg, nullptr, 0, 0)) {
    ::TranslateMessage(&msg);
    ::DispatchMessage(&msg);
  }

  ::CoUninitialize();
  return EXIT_SUCCESS;
}
