#!/usr/bin/env python3

import sys, os
from os.path import join
import subprocess

def echo_run(cmd):
    print(cmd)
    return os.system(cmd)

# def echo_run_get_output(cmd):
#     print(cmd)
#     return subprocess.run(cmd, shell=True, capture_output=True, text=True).stdout

def mknewdir(path):
    if os.path.exists(path):
        echo_run(f"rm -r {path}")
    echo_run(f"mkdir -p {path}")

def send_command(process, cmd):
    print("remote command:", cmd)
    process.stdin.write(cmd + '\n')
    process.stdin.flush()

p4_name = sys.argv[1]
remote = sys.argv[2]
tmpdir = "/tmp/p4_remote_install"
sde_install = os.environ["SDE_INSTALL"]
# remote_sde_install = echo_run_get_output(f"ssh {remote} 'echo $SDE_INSTALL'").strip()

# all useful files
files = [
    f"share/p4/targets/tofino/{p4_name}.conf", 
    f"share/tofinopd/{p4_name}/bf-rt.json",
    f"share/tofinopd/{p4_name}/pipe/context.json",
    f"share/tofinopd/{p4_name}/pipe/tofino.bin",
]

dirs = [
    "share/p4/targets/tofino",
    f"share/tofinopd/{p4_name}/pipe",
]

local_files = [f"{sde_install}/{f}" for f in files]

for f in local_files:
    if not os.path.isfile(f):
        print(f"file {f} does not exist")
        exit(1)

mknewdir(tmpdir)
for f in local_files:
    echo_run(f"cp {f} {tmpdir}")

echo_run(f"scp -r {tmpdir} {remote}:/tmp/")
ssh_cmd = f"ssh {remote}"
print(ssh_cmd)
process = subprocess.Popen(
    ssh_cmd, 
    stdin=subprocess.PIPE,
    # stdout=subprocess.PIPE,
    # stderr=subprocess.PIPE,
    shell=True, 
    text=True,
    bufsize=1,
)

for d in dirs:
    send_command(process, f"mkdir -p $SDE_INSTALL/{d}")

remote_tmpdir = f"/tmp/{os.path.basename(tmpdir)}"
for f in files:
    remote_file = f"{remote_tmpdir}/{os.path.basename(f)}"
    remote_install_path = f"$SDE_INSTALL/{os.path.dirname(f)}"
    send_command(process, f"cp {remote_file} {remote_install_path}")

