#!/usr/bin/env bash
################################################################################
# File Name  : build.sh
# File Type  : linux shell script
# File Desc  : build padavan firmware for k2p (hanwckf version)
################################################################################
set -o pipefail  # trace ERR through pipes
set -o errtrace  # trace ERR through 'trap command' and other functions
set -o nounset   ## set -u : exit the script if use an uninitialised variable
set -o errexit   ## set -e : exit the script if when any error occurs
umask 0022
trap 'echo -e "\nERROR - command: [$BASH_COMMAND] return_code: [$?] line_no: [$LINENO] script: [$(readlink -f $0)]"' ERR

#*******************************************************************************
# export global environment variables
export LANG=en_US.UTF-8
export LC_CTYPE=en_US.UTF-8
# set global environment variables
g_host_name=$(hostname)
g_working_dir="$PWD"
g_script_name=$(basename "${0}")
g_error_log="${g_working_dir}/${g_script_name%.*}.err"
g_base_dir="/opt/rt-n56u"
g_git_url="https://github.com/okaweb/rt-n56u.git"
g_git_branch="develop"
g_router_model="K2P"
#*******************************************************************************
# function to print message
function print(){
    local l_messages=("$@")  # ("$@") puts all the arguments in the l_messages array
    local l_file_log=${g_log_file:-/dev/null}
    local l_datetime=$(get_current_datetime)
    local l_padding_string=" "
    local l_separator="  "

    printf "%s%s%s%s\n" "${l_separator}" "${l_datetime}" "${l_separator}" "${l_messages[0]:-}" | tee -a $l_file_log
    for l_message in "${l_messages[@]:1}";do
        # <char>%.0s means that it will always print a single <char> no matter what argument it is given.
        printf "%s"                      "${l_separator}"                    | tee -a $l_file_log
        printf "${l_padding_string}%.0s" $(eval "echo {1..${#l_datetime}}")  | tee -a $l_file_log
        printf "%s%s\n"                  "${l_separator}" "${l_message}"     | tee -a $l_file_log
    done
}

# function to get current datetime
function get_current_datetime(){
    echo $(date +'%Y-%m-%d %H:%M:%S')
}

rm -rf "${g_error_log}"
#*******************************************************************************
print "install dependent packages on Debian/Ubuntu started"

sudo apt-get update >>"${g_error_log}" 2>&1
sudo apt-get --assume-yes install \
    unzip libtool-bin curl cmake gperf gawk flex bison nano xxd \
    fakeroot kmod cpio git python3-docutils gettext automake autopoint \
    texinfo build-essential help2man pkg-config zlib1g-dev libgmp3-dev \
    libmpc-dev libmpfr-dev libncurses5-dev libltdl-dev wget libc-dev-bin >>"${g_error_log}" 2>&1

sudo apt-get --assume-yes install libdbus-1-dev >>"${g_error_log}" 2>&1

print "install dependent packages on Debian/Ubuntu completed"
#*******************************************************************************
print "clone source code started"

if [[ ! -d "${g_base_dir}" ]]; then
    # sudo rm -rf ${g_base_dir}
    sudo mkdir -p ${g_base_dir}
    sudo chmod -R 777 ${g_base_dir}
    if [[ ! -z "${g_git_branch}" ]]; then
        git clone --depth=1 -b ${g_git_branch} ${g_git_url} ${g_base_dir} >>"${g_error_log}" 2>&1
    else
        git clone --depth=1 ${g_git_url} ${g_base_dir} >>"${g_error_log}" 2>&1
    fi
fi

print "clone source code completed"
#*******************************************************************************
print "download toolchain started"

cd ${g_base_dir}/toolchain-mipsel
sh dl_toolchain.sh >>"${g_error_log}" 2>&1

print "download toolchain completed"
#*******************************************************************************
print "build firmware started"
cd ${g_base_dir}/trunk
# (./clear_tree || true) >>"${g_error_log}" 2>&1
rm -f ${g_base_dir}/trunk/nohup.out
nohup bash fakeroot ./build_firmware_modify K2P &
print "build firmware completed"
