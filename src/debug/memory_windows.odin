#+build windows
package debug

import "core:sys/windows"

@(private)
ProcessMemoryCountersEx2 :: struct {
    cb:                         windows.DWORD,
    PageFaultCount:             windows.DWORD,
    PeakWorkingSetSize:         windows.SIZE_T,
    WorkingSetSize:             windows.SIZE_T,
    QuotaPeakPagedPoolUsage:    windows.SIZE_T,
    QuotaPagedPoolUsage:        windows.SIZE_T,
    QuotaPeakNonPagedPoolUsage: windows.SIZE_T,
    QuotaNonPagedPoolUsage:     windows.SIZE_T,
    PagefileUsage:              windows.SIZE_T,
    PeakPagefileUsage:          windows.SIZE_T,
    PrivateUsage:               windows.SIZE_T,
    PrivateWorkingSetSize:      windows.SIZE_T,
    SharedCommitUsage:          windows.ULONG64,
}

foreign import psapi "system:Psapi.lib"
@(default_calling_convention = "system")
foreign psapi {
    @(private = "file")
    GetProcessMemoryInfo :: proc(
        process: windows.HANDLE,
        counters: ^ProcessMemoryCountersEx2,
        cb: windows.DWORD,
    ) -> windows.BOOL ---
}

foreign import kernel32 "system:Kernel32.lib"
@(default_calling_convention = "system")
foreign kernel32 {
    @(private = "file")
    GetCurrentProcess :: proc() -> windows.HANDLE ---
}

ram_usage_mb :: proc() -> u64 {
    pmc: ProcessMemoryCountersEx2
    pmc.cb = size_of(ProcessMemoryCountersEx2)

    if !GetProcessMemoryInfo(GetCurrentProcess(), &pmc, pmc.cb) {
        return 0
    }
    return u64(pmc.PrivateWorkingSetSize) / (1024 * 1024)
}
