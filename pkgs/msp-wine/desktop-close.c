#include <windows.h>

static WNDPROC original_proc;
static HANDLE closing_process;
static UINT_PTR close_timer;
static const WCHAR installed_property[] = L"MSP1DesktopCloseInstalled";

static BOOL CALLBACK find_game(HWND hwnd, LPARAM result) {
    WCHAR path[1024];
    DWORD pid, length = 1024;
    if (!IsWindowVisible(hwnd) || GetWindow(hwnd, GW_OWNER)) return TRUE;
    GetWindowThreadProcessId(hwnd, &pid);
    HANDLE process = OpenProcess(PROCESS_QUERY_LIMITED_INFORMATION, FALSE, pid);
    if (!process) return TRUE;
    BOOL ok = QueryFullProcessImageNameW(process, 0, path, &length);
    CloseHandle(process);
    WCHAR *base = NULL;
    if (ok) for (WCHAR *p = path; *p; ++p) if (*p == L'\\') base = p + 1;
    if (!base || lstrcmpiW(base, L"MovieStarPlanet.exe")) return TRUE;
    *(HWND *)result = hwnd;
    return FALSE;
}

static void close_desktop(void) {
    OutputDebugStringA("MSP_CLOSE stopping desktop host");
    HWND control = FindWindowW(L"MSP1BorderlessControl", NULL);
    if (control) PostMessageW(control, WM_CLOSE, 0, 0);
    /* The game is gone; exit this desktop loop without Wine logoff. */
    PostQuitMessage(0);
}

static LRESULT CALLBACK desktop_proc(HWND hwnd, UINT message, WPARAM wp, LPARAM lp) {
    if (message == WM_CLOSE || (message == WM_SYSCOMMAND && (wp & 0xfff0) == SC_CLOSE)) {
        OutputDebugStringA("MSP_CLOSE forwarding close request");
        HWND game = NULL;
        EnumWindows(find_game, (LPARAM)&game);
        if (game) {
            OutputDebugStringA("MSP_CLOSE found game");
            DWORD pid;
            GetWindowThreadProcessId(game, &pid);
            HANDLE process = OpenProcess(SYNCHRONIZE, FALSE, pid);
            if (!process) return 0;
            if (closing_process) CloseHandle(closing_process);
            closing_process = process;
            if (!close_timer && SetTimer(hwnd, 0x4d535043, 100, NULL)) close_timer = 0x4d535043;
            if (close_timer) {
                OutputDebugStringA("MSP_CLOSE posting WM_CLOSE");
                PostMessageW(game, WM_CLOSE, 0, 0);
            }
            else { CloseHandle(closing_process); closing_process = NULL; }
        } else if (!closing_process) close_desktop();
        /* Keep the desktop open while the app confirms, cancels, or finishes. */
        return 0;
    }
    if (message == WM_TIMER && close_timer && wp == close_timer) {
        if (WaitForSingleObject(closing_process, 0) == WAIT_OBJECT_0) {
            OutputDebugStringA("MSP_CLOSE game process exited");
            KillTimer(hwnd, close_timer);
            close_timer = 0;
            CloseHandle(closing_process);
            closing_process = NULL;
            /* A country restart may have replaced the original process. */
            HWND game = NULL;
            EnumWindows(find_game, (LPARAM)&game);
            if (!game) close_desktop();
        }
        return 0;
    }
    return CallWindowProcW(original_proc, hwnd, message, wp, lp);
}

/* Runs briefly in explorer's desktop thread to install the local subclass. */
__declspec(dllexport) LRESULT CALLBACK DesktopCloseHook(int code, WPARAM wp, LPARAM lp) {
    if (code >= 0) {
        CWPSTRUCT *message = (CWPSTRUCT *)lp;
        HWND desktop = GetDesktopWindow();
        if (message->hwnd == desktop && !GetPropW(desktop, installed_property)) {
            HMODULE pinned;
            if (GetModuleHandleExW(GET_MODULE_HANDLE_EX_FLAG_FROM_ADDRESS | GET_MODULE_HANDLE_EX_FLAG_PIN,
                                  (LPCWSTR)DesktopCloseHook, &pinned)) {
                SetLastError(0);
                original_proc = (WNDPROC)SetWindowLongPtrW(desktop, GWLP_WNDPROC, (LONG_PTR)desktop_proc);
                if (original_proc) SetPropW(desktop, installed_property, (HANDLE)1);
            }
        }
    }
    return CallNextHookEx(NULL, code, wp, lp);
}
