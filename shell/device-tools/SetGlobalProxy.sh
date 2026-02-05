#!/bin/bash
# ----------------------------------------------------------------------
#     author   : Android 轮子哥
#     github   : https://github.com/getActivity/AndroidCmdTools
#      time    : 2026/01/25
#      desc    : adb 设置全局代理脚本
# ----------------------------------------------------------------------
scriptDirPath=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
[ -z "" ] || source "../common/SystemPlatform.sh"
source "${scriptDirPath}/../common/SystemPlatform.sh"
[ -z "" ] || source "../common/EnvironmentTools.sh"
source "${scriptDirPath}/../common/EnvironmentTools.sh"
[ -z "" ] || source "/../common/IpAddressTools.sh"
source "${scriptDirPath}/../common/IpAddressTools.sh"
[ -z "" ] || source "/../business/DevicesSelector.sh"
source "${scriptDirPath}/../business/DevicesSelector.sh"

waitUserInputParameter() {
    local computerIpV4
    computerIpV4=$(getComputerIpV4)
    if [[ -n "${computerIpV4}" ]]; then
        echo "请输入代理主机名（可空，默认用电脑局域网地址 ${computerIpV4}）："
    else
        echo "请输入代理主机名："
    fi
    while true; do
        read -r host
        if [[ -n "${host}" ]]; then
            if isIpV4Format "${host}"; then
                if isLocalhostIp "${host}"; then
                    echo "👻 不能使用本地回环地址（${host}）作为代理 IP，请重新输入："
                    continue
                fi
                break
            else
                echo "👻 IP 地址格式不合法，请重新输入："
                continue
            fi
        else
            if [[ -z "${computerIpV4}" ]]; then
                echo "👻 无法获取电脑局域网 IP，请手动输入："
                continue
            else
                host="${computerIpV4}"
                break
            fi
        fi
    done

    echo "请输入代理端口（可空，默认使用 8888 端口）："
    read -r port
    if [[ -z "${port}" ]]; then
        port=8888
    fi
    if [[ ! "${port}" =~ ^[0-9]+$ ]] || (( port < 1 || port > 65535 )); then
        echo "❌ 端口号不合法，请输入 1-65535 的整数"
        exit 1
    fi
}

setProxySingleDevice() {
    local deviceId=$1
    local outputPrint
    outputPrint=$(adb -s "${deviceId}" shell settings put global http_proxy "${host}:${port}" < /dev/null 2>&1)
    local exitCode=$?
    if (( exitCode == 0 )); then
        echo "✅ [${deviceId}] 设备已设置全局代理为 ${host}:${port}"
    else
        echo "❌ [${deviceId}] 设备设置全局代理失败，原因如下："
        echo "${outputPrint}"
        return 1
    fi
    return 0
}

setGlobalProxyForDevice() {
    local deviceId
    deviceId="$(inputMultipleAdbDevice)"
    if [[ -n "${deviceId}" ]]; then
        setProxySingleDevice "${deviceId}"
    else
        adbDeviceIdsString=$(getAdbDeviceIdsString)
        while read -r adbDeviceId; do
            setProxySingleDevice "${adbDeviceId}"
        done < <(echo "${adbDeviceIdsString}" | tr -d '\r' | grep -v '^$')
    fi
    echo "✅ 所有代理设置已完成"
    exit 0
}

main() {
    printCurrentSystemType
    checkAdbEnvironment
    waitUserInputParameter
    setGlobalProxyForDevice
}

clear
main
