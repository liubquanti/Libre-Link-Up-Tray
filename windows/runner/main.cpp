#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>

#include "flutter_window.h"
#include "utils.h"

int APIENTRY wWinMain(_In_ HINSTANCE instance,
                      _In_opt_ HINSTANCE prev,
                      _In_ wchar_t *command_line,
                      _In_ int show_command) {
  // Single-instance guard
  HANDLE app_mutex = CreateMutexW(nullptr, TRUE, L"LibreLinkUpTray_Singleton_Mutex");
  if (app_mutex && GetLastError() == ERROR_ALREADY_EXISTS) {
    // Notify existing instance to show itself and exit
    UINT showMsg = RegisterWindowMessageW(L"LibreLinkUpTray_Show");
    if (showMsg != 0) {
      SendMessageTimeoutW(HWND_BROADCAST, showMsg, 0, 0, SMTO_ABORTIFHUNG, 200, nullptr);
    }
    return 0;
  }

  // Attach to console when present (e.g., 'flutter run') or create a
  // new console when running with a debugger.
  if (!::AttachConsole(ATTACH_PARENT_PROCESS) && ::IsDebuggerPresent()) {
    CreateAndAttachConsole();
  }

  // Initialize COM, so that it is available for use in the library and/or
  // plugins.
  ::CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);

  flutter::DartProject project(L"data");

  std::vector<std::string> command_line_arguments =
      GetCommandLineArguments();

  project.set_dart_entrypoint_arguments(std::move(command_line_arguments));

  FlutterWindow window(project);
  Win32Window::Point origin(10, 10);
  Win32Window::Size size(1280, 720);
  if (!window.Create(L"LibreLinkUpTray", origin, size)) {
    return EXIT_FAILURE;
  }
  window.SetQuitOnClose(true);

  // Standard Windows message loop замість неіснуючого Win32Window::RunFlutter
  MSG msg;
  int result = EXIT_SUCCESS;
  while (GetMessage(&msg, nullptr, 0, 0)) {
    TranslateMessage(&msg);
    DispatchMessage(&msg);
  }

  ::CoUninitialize();
  if (app_mutex) {
    ReleaseMutex(app_mutex);
    CloseHandle(app_mutex);
  }
  return result;
}
