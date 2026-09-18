use std::ffi::c_void;
use std::ptr::null_mut;

#[repr(C)]
struct Guid {
    data1: u32,
    data2: u16,
    data3: u16,
    data4: [u8; 8],
}

type Hwnd = *mut c_void;
type Handle = *mut c_void;
type Hkey = *mut c_void;

const ERROR_ALREADY_EXISTS: u32 = 183;
const SW_RESTORE: i32 = 9;
const HKEY_CURRENT_USER: Hkey = 0x80000001_u64 as Hkey;
const KEY_READ: u32 = 0x20019;

#[link(name = "kernel32")]
extern "system" {
    fn CreateMutexW(security_attributes: *mut c_void, initial_owner: i32, name: *const u16) -> Handle;
    fn GetLastError() -> u32;
    fn CloseHandle(handle: Handle) -> i32;
}

#[link(name = "user32")]
extern "system" {
    fn FindWindowW(class_name: *const u16, window_name: *const u16) -> Hwnd;
    fn ShowWindow(hwnd: Hwnd, cmd: i32) -> i32;
    fn SetForegroundWindow(hwnd: Hwnd) -> i32;
    fn BringWindowToTop(hwnd: Hwnd) -> i32;
    fn SwitchToThisWindow(hwnd: Hwnd, alt_tab: i32);
    fn GetForegroundWindow() -> Hwnd;
    fn GetWindowThreadProcessId(hwnd: Hwnd, process_id: *mut u32) -> u32;
    fn AttachThreadInput(id_attach: u32, id_attach_to: u32, attach: i32) -> i32;
}

#[link(name = "advapi32")]
extern "system" {
    fn RegOpenKeyExW(
        hkey: Hkey,
        sub_key: *const u16,
        options: u32,
        sam_desired: u32,
        result: *mut Hkey,
    ) -> i32;
    fn RegQueryValueExW(
        hkey: Hkey,
        value_name: *const u16,
        reserved: *mut u32,
        type_: *mut u32,
        data: *mut u8,
        data_len: *mut u32,
    ) -> i32;
    fn RegCloseKey(hkey: Hkey) -> i32;
}

#[link(name = "ole32")]
extern "system" {
    fn CoInitializeEx(reserved: *mut c_void, co_init: u32) -> i32;
    fn CoCreateInstance(
        rclsid: *const Guid,
        aggregate: *mut c_void,
        context: u32,
        riid: *const Guid,
        out: *mut *mut c_void,
    ) -> i32;
    fn CoUninitialize();
}

pub struct SingleInstanceGuard {
    _mutex: Handle,
}

impl SingleInstanceGuard {
    /// Attempts to acquire single-instance mutex.
    /// If another instance exists, teleports existing window and exits.
    pub fn acquire_or_teleport(window_title: &str) -> Option<Self> {
        let mutex_name = to_wide("Global\\Sakshi_Spark_SingleInstance_Mutex_Karan");
        unsafe {
            let mutex = CreateMutexW(null_mut(), 1, mutex_name.as_ptr());
            if GetLastError() == ERROR_ALREADY_EXISTS {
                // Instance already exists - Teleport and activate existing window
                teleport_and_focus_existing(window_title);
                if !mutex.is_null() {
                    CloseHandle(mutex);
                }
                return None;
            }

            Some(Self { _mutex: mutex })
        }
    }
}

impl Drop for SingleInstanceGuard {
    fn drop(&mut self) {
        unsafe {
            if !self._mutex.is_null() {
                CloseHandle(self._mutex);
            }
        }
    }
}

fn to_wide(s: &str) -> Vec<u16> {
    s.encode_utf16().chain(std::iter::once(0)).collect()
}

fn teleport_and_focus_existing(window_title: &str) {
    let title_wide = to_wide(window_title);
    unsafe {
        let hwnd = FindWindowW(null_mut(), title_wide.as_ptr());
        if hwnd.is_null() {
            return;
        }

        // 1. Attempt Virtual Desktop Teleportation via COM
        let _ = move_window_to_current_desktop(hwnd);

        // 2. Force foreground focus bypassing Windows lock
        let fore_hwnd = GetForegroundWindow();
        let fore_thread = GetWindowThreadProcessId(fore_hwnd, null_mut());
        let target_thread = GetWindowThreadProcessId(hwnd, null_mut());

        if fore_thread != target_thread {
            AttachThreadInput(fore_thread, target_thread, 1);
            ShowWindow(hwnd, SW_RESTORE);
            BringWindowToTop(hwnd);
            SetForegroundWindow(hwnd);
            SwitchToThisWindow(hwnd, 1);
            AttachThreadInput(fore_thread, target_thread, 0);
        } else {
            ShowWindow(hwnd, SW_RESTORE);
            BringWindowToTop(hwnd);
            SetForegroundWindow(hwnd);
        }
    }
}

fn move_window_to_current_desktop(hwnd: Hwnd) -> Result<(), ()> {
    unsafe {
        // Read current virtual desktop GUID from Registry
        let sub_key = to_wide("Software\\Microsoft\\Windows\\CurrentVersion\\Explorer\\VirtualDesktops");
        let val_name = to_wide("CurrentVirtualDesktop");

        let mut hkey: Hkey = null_mut();
        if RegOpenKeyExW(HKEY_CURRENT_USER, sub_key.as_ptr(), 0, KEY_READ, &mut hkey) != 0 {
            return Err(());
        }

        let mut guid_bytes = [0u8; 16];
        let mut len = 16u32;
        let mut type_val = 0u32;
        let query_res = RegQueryValueExW(
            hkey,
            val_name.as_ptr(),
            null_mut(),
            &mut type_val,
            guid_bytes.as_mut_ptr(),
            &mut len,
        );
        RegCloseKey(hkey);

        if query_res != 0 || len != 16 {
            return Err(());
        }

        let desktop_guid = Guid {
            data1: u32::from_le_bytes(guid_bytes[0..4].try_into().unwrap()),
            data2: u16::from_le_bytes(guid_bytes[4..6].try_into().unwrap()),
            data3: u16::from_le_bytes(guid_bytes[6..8].try_into().unwrap()),
            data4: guid_bytes[8..16].try_into().unwrap(),
        };

        CoInitializeEx(null_mut(), 0x2); // COINIT_APARTMENTTHREADED

        // CLSID_VirtualDesktopManager Win 11 24H2 & Legacy
        let clsid_24h2 = Guid {
            data1: 0xAA509086,
            data2: 0x5CA9,
            data3: 0x4C25,
            data4: [0x8F, 0x95, 0x58, 0x9D, 0x3C, 0x07, 0xB4, 0x8A],
        };
        let clsid_legacy = Guid {
            data1: 0xAA509085,
            data2: 0x5CA9,
            data3: 0x4C25,
            data4: [0x8F, 0x95, 0x58, 0x9D, 0x3C, 0x07, 0xB4, 0x8A],
        };
        let iid_vdm = Guid {
            data1: 0xA5CD92FF,
            data2: 0x29BE,
            data3: 0x454C,
            data4: [0x8D, 0x04, 0xD8, 0x28, 0x79, 0xFB, 0x3F, 0x1B],
        };

        let mut vdm_ptr: *mut c_void = null_mut();
        let mut hr = CoCreateInstance(&clsid_24h2, null_mut(), 1, &iid_vdm, &mut vdm_ptr);
        if hr != 0 {
            hr = CoCreateInstance(&clsid_legacy, null_mut(), 1, &iid_vdm, &mut vdm_ptr);
        }

        if hr == 0 && !vdm_ptr.is_null() {
            // VirtualDesktopManager vtable:
            // 0: QueryInterface, 1: AddRef, 2: Release
            // 3: IsWindowOnCurrentVirtualDesktop, 4: GetWindowDesktopId, 5: MoveWindowToDesktop
            type MoveWindowFn = unsafe extern "system" fn(this: *mut c_void, hwnd: Hwnd, desktop: *const Guid) -> i32;
            let vtable = *(vdm_ptr as *const *const *const ());
            let move_fn: MoveWindowFn = std::mem::transmute(*vtable.offset(5));
            let _ = move_fn(vdm_ptr, hwnd, &desktop_guid);

            type ReleaseFn = unsafe extern "system" fn(this: *mut c_void) -> u32;
            let release_fn: ReleaseFn = std::mem::transmute(*vtable.offset(2));
            release_fn(vdm_ptr);
        }

        CoUninitialize();
        Ok(())
    }
}
