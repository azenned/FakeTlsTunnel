
import std/[random,os,osproc,asyncdispatch,exitprocs]
from globals import nil
import connection,tunnel,server,print
from std/times import getTime, toUnix, nanosecond

let now = getTime()
randomize(now.toUnix * 1_000_000_000 + now.nanosecond)

globals.init()

#full reset iptables at exit (if the user allowed )
if globals.multi_port and globals.reset_iptable and globals.mode == globals.RunMode.tunnel:
    addExitProc do():
        globals.resetIptables() 
    setControlCHook do:
        quit()


#increase systam maximum fds to be able to handle more than 1024 cons (650000 for now)
when defined(linux) and not defined(android):
    import std/posix
    if not isAdmin():
        echo "Please run as root."
        quit(-1)
    if not globals.is_docker and globals.disable_ufw:
        discard 0 == execShellCmd("sudo ufw disable")
    if not globals.is_docker:
        discard 0 == execShellCmd("sysctl -w fs.file-max=100000")
    else:
        echo("Launch mode is set to Docker. Will use `docker-sysctl.conf` instead of shell-exec.")
    var limit = RLimit(rlim_cur:65000,rlim_max:66000)
    assert 0 == setrlimit(RLIMIT_NOFILE,limit)



#idle connection removal controller
asyncCheck startController()


if globals.mode == globals.RunMode.tunnel:
    asyncCheck tunnel.start()
else:
    asyncCheck server.start()

runForever()