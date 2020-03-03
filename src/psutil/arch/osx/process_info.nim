import ./types
import ./socket

const MAXPATHLEN      = 1024

const PROC_PIDLISTFDS* = 1.cint
const PROC_PIDLISTFD_SIZE* = 8.cint
# defns of process file desc type  https://opensource.apple.com/source/xnu/xnu-1456.1.26/bsd/sys/proc_info.h.auto.html
const PROX_FDTYPE_ATALK* = 0.cint
const PROX_FDTYPE_VNODE* = 1.cint
const PROX_FDTYPE_SOCKET* = 2.cint
const PROX_FDTYPE_PSHM* = 3.cint
const PROX_FDTYPE_PSEM* = 4.cint
const PROX_FDTYPE_KQUEUE* = 5.cint
const PROX_FDTYPE_PIPE* = 6.cint
const PROX_FDTYPE_FSEVENTS* = 7.cint
const PROC_PIDFDVNODEPATHINFO* = 2.cint

type proc_fdinfo* {.importc:"struct proc_fdinfo",header:"<sys/proc_info.h>".} = object
    proc_fdtype*:cint
    proc_fd*:cint

type vnode_fdinfowithpath* {.importc:"struct vnode_fdinfowithpath",header:"<sys/proc_info.h>".} = object


type proc_fileinfo* = object
    fi_openflags*:uint32
    fi_status*:uint32
    fi_offset*:off_t
    vip_path*:array[MAXPATHLEN,char]

type socket_fdinfo* {.importc:"struct socket_fdinfo",header:"<sys/proc_info.h>".} = object
    pfi*:proc_fileinfo
    psi*:socket_info

# https://opensource.apple.com/source/xnu/xnu-2422.1.72/libsyscall/wrappers/libproc/libproc.h.auto.html
proc proc_pidinfo*(pid:cint,flavor:cint,arg:uint64,buffer:pointer,buffer_size:cint):cint{.importc:"proc_pidinfo",header:"<libproc.h>".}

proc proc_pidfdinfo*(pid:cint,flavor:cint,fd:cint,buffer:pointer,buffer_size:cint):cint{.importc:"proc_pidfdinfo",header:"<libproc.h>".}

when isMainModule:
    var x {.importc: "PROC_PIDLISTFDS", header: "<sys/proc_info.h>".}: cint
    assert x == PROC_PIDLISTFDS
    var y {.importc: "PROX_FDTYPE_ATALK", header: "<sys/proc_info.h>".}: cint
    assert y == PROX_FDTYPE_ATALK
    var z {.importc: "PROX_FDTYPE_VNODE", header: "<sys/proc_info.h>".}: cint
    assert z == PROX_FDTYPE_VNODE
    var z1 {.importc: "PROX_FDTYPE_SOCKET", header: "<sys/proc_info.h>".}: cint
    assert z1 == PROX_FDTYPE_SOCKET

    var z2 {.importc: "PROX_FDTYPE_PSHM", header: "<sys/proc_info.h>".}: cint
    assert z2 == PROX_FDTYPE_PSHM

    var z3 {.importc: "PROX_FDTYPE_PSEM", header: "<sys/proc_info.h>".}: cint
    assert z3 == PROX_FDTYPE_PSEM

    var z4 {.importc: "PROX_FDTYPE_KQUEUE", header: "<sys/proc_info.h>".}: cint
    assert z4 == PROX_FDTYPE_KQUEUE

    var z5 {.importc: "PROX_FDTYPE_PIPE", header: "<sys/proc_info.h>".}: cint
    assert z5 == PROX_FDTYPE_PIPE

    var z6 {.importc: "PROX_FDTYPE_FSEVENTS", header: "<sys/proc_info.h>".}: cint
    assert z6 == PROX_FDTYPE_FSEVENTS

    var z7 {.importc: "PROC_PIDFDVNODEPATHINFO", header: "<sys/proc_info.h>".}: cint
    assert z7 == PROC_PIDFDVNODEPATHINFO
