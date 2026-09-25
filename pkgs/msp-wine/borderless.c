#include <windows.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
static HWND game;
static BOOL CALLBACK find_game(HWND hwnd, LPARAM unused) {
    WCHAR title[256], path[1024];
    DWORD pid, len = 1024;
    (void)unused;
    if (!IsWindowVisible(hwnd) || GetWindow(hwnd, GW_OWNER) ||
        !GetWindowTextW(hwnd, title, 256)) return TRUE;
    GetWindowThreadProcessId(hwnd, &pid);
    HANDLE process = OpenProcess(PROCESS_QUERY_LIMITED_INFORMATION, FALSE, pid);
    if (!process) return TRUE;
    BOOL ok = QueryFullProcessImageNameW(process, 0, path, &len);
    CloseHandle(process);
    WCHAR *base = NULL;
    if (ok) for (WCHAR *p = path; *p; ++p) if (*p == L'\\') base = p;
    if (!base || lstrcmpiW(base + 1, L"MovieStarPlanet.exe")) return TRUE;
    game = hwnd;
    return FALSE;
}
static BOOL install_desktop_close(void) {
    WCHAR path[1024];
    DWORD length = GetModuleFileNameW(NULL, path, 1024);
    if (!length || length >= 1024) return FALSE;
    WCHAR *base = NULL;
    for (WCHAR *p = path; *p; ++p) if (*p == L'\\') base = p + 1;
    if (!base || base - path + 18 >= 1024) return FALSE;
    lstrcpyW(base, L"desktop-close.dll");
    HMODULE module = LoadLibraryW(path);
    if (!module) { fprintf(stderr, "Load desktop-close.dll failed: %lu\n", (unsigned long)GetLastError()); return FALSE; }
    union { FARPROC address; HOOKPROC hook; } callback;
    callback.address = GetProcAddress(module, "DesktopCloseHook");
    HWND desktop = GetDesktopWindow();
    DWORD thread = GetWindowThreadProcessId(desktop, NULL);
    HHOOK hook = callback.hook ? SetWindowsHookExW(WH_CALLWNDPROC, callback.hook, module, thread) : NULL;
    if (!hook) fprintf(stderr, "Desktop thread %lu hook failed: %lu\n", (unsigned long)thread, (unsigned long)GetLastError());
    if (hook) {
        DWORD_PTR result;
        if (!SendMessageTimeoutW(desktop, WM_NULL, 0, 0, SMTO_ABORTIFHUNG, 2000, &result))
            fprintf(stderr, "Desktop initialization message failed: %lu\n", (unsigned long)GetLastError());
        UnhookWindowsHookEx(hook);
    }
    BOOL installed = GetPropW(desktop, L"MSP1DesktopCloseInstalled") != NULL;
    FreeLibrary(module);
    return installed;
}
/* Wine shutdown broadcasts session messages, including to hidden windows. */
static LRESULT CALLBACK watcher_proc(HWND hwnd, UINT message, WPARAM wp, LPARAM lp) {
    if (message == WM_QUERYENDSESSION) return TRUE;
    if (message == WM_CLOSE || (message == WM_ENDSESSION && wp)) {
        PostQuitMessage(0);
        return 0;
    }
    return DefWindowProcW(hwnd, message, wp, lp);
}
static BOOL watcher_wait(void) {
    MSG msg;
    DWORD start = GetTickCount();
    do {
        while (PeekMessageW(&msg, NULL, 0, 0, PM_REMOVE)) {
            if (msg.message == WM_QUIT) return FALSE;
            TranslateMessage(&msg);
            DispatchMessageW(&msg);
        }
        DWORD elapsed = GetTickCount() - start;
        if (elapsed >= 250) return TRUE;
        MsgWaitForMultipleObjects(0, NULL, FALSE, 250 - elapsed, QS_ALLINPUT);
    } while (TRUE);
}
/* Country changes can replace the window or restore its frame. */
static int watch_game(HDESK desktop, long width, long height,
                      long desktop_width, long desktop_height) {
    HANDLE mutex = CreateMutexW(NULL, FALSE, L"MSP1BorderlessWatcher");
    if (!mutex) return 1;
    if (GetLastError() == ERROR_ALREADY_EXISTS) { CloseHandle(mutex); return 0; }
    WNDCLASSW cls = {0};
    cls.lpfnWndProc = watcher_proc;
    cls.hInstance = GetModuleHandleW(NULL);
    cls.lpszClassName = L"MSP1BorderlessControl";
    if (!RegisterClassW(&cls)) { CloseHandle(mutex); return 1; }
    HWND control = CreateWindowExW(WS_EX_TOOLWINDOW, cls.lpszClassName, L"", 0,
                                   0, 0, 0, 0, NULL, NULL, cls.hInstance, NULL);
    if (!control) { CloseHandle(mutex); return 1; }
    if (!install_desktop_close()) {
        fprintf(stderr, "Cannot install Wine desktop close forwarding: %lu\n", (unsigned long)GetLastError());
        DestroyWindow(control);
        CloseHandle(mutex);
        return 10;
    }
    puts("Wine desktop close forwarding installed");
    fflush(stdout);
    unsigned missing = 0;
    BOOL seen_game = FALSE;
    while (missing < (seen_game ? 8u : 120u)) {
        game = NULL;
        EnumDesktopWindows(desktop, find_game, 0);
        if (!game) { ++missing; if (!watcher_wait()) break; continue; }
        seen_game = TRUE;
        missing = 0;
        RECT rect;
        LONG_PTR style = GetWindowLongPtrW(game, GWL_STYLE);
        /* Leave minimized windows alone. */
        if (!(style & WS_MINIMIZE) && GetWindowRect(game, &rect)) {
            LONG_PTR frame = style & (WS_CAPTION | WS_THICKFRAME | WS_MAXIMIZE);
            long x = (desktop_width - width) / 2;
            long y = (desktop_height - height) / 2;
            if (frame || rect.left != x || rect.top != y ||
                rect.right != x + width || rect.bottom != y + height) {
                SetLastError(0);
                if (frame && !SetWindowLongPtrW(game, GWL_STYLE, style & ~frame) && GetLastError()) {
                    if (!watcher_wait()) break;
                    continue;
                }
                if (SetWindowPos(game, NULL, x, y, width, height,
                                 SWP_FRAMECHANGED | SWP_NOZORDER | SWP_NOACTIVATE)) {
                    printf("Reapplied borderless bounds to %p\n", (void *)game);
                    fflush(stdout);
                }
            }
        }
        if (!watcher_wait()) break;
    }
    DestroyWindow(control);
    CloseHandle(mutex);
    return 0;
}
int main(int argc, char **argv) {
    int watch = argc == 6 && !strcmp(argv[5], "--watch");
    if (argc != 5 && !watch) { fprintf(stderr, "Usage: borderless.exe WIDTH HEIGHT DESKTOP_WIDTH DESKTOP_HEIGHT [--watch]\n"); return 6; }
    char *endw, *endh;
    long width = strtol(argv[1], &endw, 10), height = strtol(argv[2], &endh, 10);
    if (*endw || *endh || width < 320 || height < 240 || width > 16384 || height > 16384) return 6;
    char *enddw, *enddh;
    long desktop_width = strtol(argv[3], &enddw, 10), desktop_height = strtol(argv[4], &enddh, 10);
    if (*enddw || *enddh || desktop_width < width || desktop_height < height || desktop_width > 16384 || desktop_height > 16384) return 6;
    HDESK desktop = NULL;
    for (int i = 0; i < 120 && !desktop; ++i) {
        desktop = OpenDesktopW(L"MSP1", 0, FALSE, DESKTOP_READOBJECTS | DESKTOP_WRITEOBJECTS | DESKTOP_ENUMERATE |
                               (watch ? DESKTOP_CREATEWINDOW | DESKTOP_HOOKCONTROL : 0));
        if (!desktop) Sleep(250);
    }
    if (!desktop || !SetThreadDesktop(desktop)) { fprintf(stderr, "Cannot access MSP1 desktop: %lu\n", (unsigned long)GetLastError()); return 1; }
    if (watch) return watch_game(desktop, width, height, desktop_width, desktop_height);
    for (int i = 0; i < 120 && !game; ++i) {
        EnumDesktopWindows(desktop, find_game, 0);
        if (!game) Sleep(250);
    }
    if (!game) { fprintf(stderr, "MovieStarPlanet window not found\n"); return 2; }
    HWND desktop_window = GetDesktopWindow();
    int background_index = COLOR_BACKGROUND;
    COLORREF black = RGB(0, 0, 0);
    if (!SetSysColors(1, &background_index, &black)) return 9;
    /* Wine's desktop class brush stays blue; use a full-size black wallpaper instead. */
    HKEY key;
    if (RegCreateKeyExW(HKEY_CURRENT_USER, L"Control Panel\\Desktop", 0, NULL,
                        0, KEY_SET_VALUE, NULL, &key, NULL)) return 9;
    const WCHAR tile[] = L"0";
    LONG status = RegSetValueExW(key, L"TileWallpaper", 0, REG_SZ,
                                 (const BYTE *)tile, sizeof(tile));
    RegCloseKey(key);
    if (status) return 9;
    if (!SystemParametersInfoW(SPI_SETDESKWALLPAPER, 0,
            L"C:\\msp-wine\\black.bmp",
            SPIF_UPDATEINIFILE | SPIF_SENDCHANGE)) return 9;
    Sleep(2000);
    LONG_PTR style = GetWindowLongPtrW(game, GWL_STYLE);
    SetLastError(0);
    if (!SetWindowLongPtrW(game, GWL_STYLE, style & ~(WS_CAPTION | WS_THICKFRAME | WS_MAXIMIZE)) && GetLastError()) return 3;
    if (!SetWindowPos(game, NULL, 0, 0, width, height, SWP_FRAMECHANGED | SWP_NOZORDER | SWP_NOACTIVATE)) return 4;
    Sleep(1000);
    RECT rect;
    GetWindowRect(game, &rect);
    long game_width = rect.right - rect.left;
    long game_height = rect.bottom - rect.top;
    if (game_width > desktop_width || game_height > desktop_height) return 7;
    long x = (desktop_width - game_width) / 2;
    long y = (desktop_height - game_height) / 2;
    if (!SetWindowPos(game, NULL, x, y, 0, 0, SWP_NOSIZE | SWP_NOZORDER | SWP_NOACTIVATE)) return 4;
    RedrawWindow(desktop_window, NULL, NULL, RDW_INVALIDATE | RDW_ERASE | RDW_UPDATENOW);
    Sleep(1000);
    GetWindowRect(game, &rect);
    printf("Game bounds: (%ld,%ld)-(%ld,%ld); desktop: %ldx%ld; background: #%06lx\n",
        (long)rect.left, (long)rect.top, (long)rect.right, (long)rect.bottom,
        desktop_width, desktop_height, (unsigned long)GetSysColor(COLOR_BACKGROUND));
    if (rect.left != x || rect.top != y || rect.right > desktop_width || rect.bottom > desktop_height) return 7;
    printf("Title bar removed; caption bits remaining: %lx\n", (long)(GetWindowLongPtrW(game,GWL_STYLE) & WS_CAPTION));
    return (GetWindowLongPtrW(game,GWL_STYLE) & WS_CAPTION) ? 5 : 0;
}
