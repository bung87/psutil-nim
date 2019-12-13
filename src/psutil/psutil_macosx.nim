import posix
import times except Time
import common
import strutils
# https://reviews.freebsd.org/rS317061

const
    CTL_KERN = 1
    KERN_SUCCESS = 0           # mach/kern_return.h.
    CTL_VM = 2
    KERN_BOOTTIME = 21
    # host_statistics()
    HOST_LOAD_INFO = 1.cint         # System loading stats
    HOST_VM_INFO = 2.cint           # Virtual memory stats
    HOST_CPU_LOAD_INFO = 3     # CPU load stats

    # host_statistics64()
    HOST_VM_INFO64 = 4         # 64-bit virtual memory stats
    HOST_EXTMOD_INFO64 = 5     # External modification stats
    HOST_EXPIRED_TASK_INFO = 6 # Statistics for expired tasks


var CPU_STATE_MAX {.importc: "CPU_STATE_MAX", header: "<mach/machine.h>".}: cint
var CPU_STATE_USER {.importc: "CPU_STATE_USER",
        header: "<mach/machine.h>".}: cint
var CPU_STATE_NICE {.importc: "CPU_STATE_NICE",
        header: "<mach/machine.h>".}: cint
var CPU_STATE_SYSTEM {.importc: "CPU_STATE_SYSTEM",
        header: "<mach/machine.h>".}: cint
var CPU_STATE_IDLE {.importc: "CPU_STATE_IDLE",
        header: "<mach/machine.h>".}: cint
var CLK_TCK {.importc: "CLK_TCK", header: "<sys/time.h>".}: cdouble

type host_cpu_load_info_data_t {.importc: "host_cpu_load_info_data_t", header: "<mach/host_info.h>".} = object
    cpu_ticks*: array[0..3, cint] #limit to CPU_STATE_MAX but cant refer it as array length at compile time.

type Timeval = object
    tv_sec*: Time
    tv_usec*: int32
type host_info_t = ptr cint
type mach_port_t {.importc: "mach_port_t",header: "<mach/message.h>",nodecl.} = object
type mach_msg_type_number_t {.importc: "mach_msg_type_number_t",header: "<mach/message.h>",nodecl.} = object

type Vmmeter {.importc: "struct vmmeter",header: "<sys/vmmeter.h>",nodecl.} = object
    v_swtch: cint
    v_intr: cint
    v_soft: cint
    v_syscall: cint

proc sysctl(x: ptr array[0..3, cint], y: cint, z: pointer,
            a: var csize, b: pointer, c: int): cint {.
            importc: "sysctl", nodecl.}

proc mach_host_self(): mach_port_t{.importc: "mach_host_self",
        header: "<mach/mach_init.h>", nodecl.}
proc mach_port_deallocate(): void {.importc: "mach_port_deallocate",
        header: "<mach/mach_port.h>", nodecl, varargs.}
proc mach_task_self(): cint{.importc: "mach_task_self",
        header: "<mach/thread_act.h>", nodecl.}
proc mach_error_string(): string{.importc: "mach_error_string",
        header: "<mach/thread_act.h>", nodecl, varargs.}
proc host_statistics(a: mach_port_t; b: cint; c: host_info_t; d: ptr mach_msg_type_number_t): cint{.
        importc: "host_statistics", header: "<mach/mach_host.h>", nodecl, varargs.}

proc host_statistics64(a: mach_port_t; b: cint; c: host_info_t;  d: ptr mach_msg_type_number_t): cint{.
        importc: "host_statistics64",
    header: "<mach/mach_host.h>", nodecl, varargs.}

proc boot_time*(): int =
    ## Return the system boot time expressed in seconds since the epoch, Integer type.
    var
        mib: array[0..3, cint]
        boot_time: Time
        len: csize
        r: Timeval
    mib[0] = CTL_KERN
    mib[1] = KERN_BOOTTIME
    len = sizeof(r)
    if sysctl(addr(mib), 2, addr(r), len, nil, 0) == -1:
        raise newException(OSError, "")
    boot_time = (Time)r.tv_sec
    return boot_time.int

proc uptime*(): int =
    ## Return the system uptime expressed in seconds, Integer type.
    times.epochTime().int - boot_time()

var HOST_CPU_LOAD_INFO_COUNT {.importc: "HOST_CPU_LOAD_INFO_COUNT",
    header: "<mach/mach_host.h>", nodecl.}: cint


proc cpu_times*(): CPUTimes =

    var count = cast[mach_msg_type_number_t](HOST_CPU_LOAD_INFO_COUNT)
    let host_port = mach_host_self()
    var r_load: host_cpu_load_info_data_t
    let error = host_statistics(host_port, HOST_CPU_LOAD_INFO, cast[
            host_info_t](r_load.unsafeAddr), count.addr)
 
    if error != KERN_SUCCESS:
        raise newException(OSError, "host_statistics(HOST_CPU_LOAD_INFO) syscall failed: $1" %
                mach_error_string(error))
    mach_port_deallocate(mach_task_self(), host_port)

    result.user = r_load.cpu_ticks[CPU_STATE_USER].cdouble / CLK_TCK
    result.nice = r_load.cpu_ticks[CPU_STATE_NICE].cdouble / CLK_TCK
    result.system = r_load.cpu_ticks[CPU_STATE_SYSTEM].cdouble / CLK_TCK
    result.idle = r_load.cpu_ticks[CPU_STATE_IDLE].cdouble / CLK_TCK

proc cpu_stats*(): tuple[ctx_switches, interrupts, soft_interrupts,
        syscalls: int] =
    var vmstat:Vmmeter 

    var count: mach_msg_type_number_t = cast[mach_msg_type_number_t](sizeof(vmstat) div sizeof(cint));
    let mport = mach_host_self()
    let ret = host_statistics(mport, HOST_VM_INFO, cast[host_info_t](
            vmstat.unsafeAddr), count.unsafeAddr)
    echo ret
    if ret != KERN_SUCCESS:
        raise newException(OSError, "host_statistics(HOST_VM_INFO) syscall failed: $1" %
        mach_error_string(ret))

    mach_port_deallocate(mach_task_self(), mport)

    return (vmstat.v_swtch.int, vmstat.v_intr.int, vmstat.v_soft.int, vmstat.v_syscall.int)

when isMainModule:
    echo boot_time()
    echo uptime()
    echo cpu_times()
    echo cpu_stats()
