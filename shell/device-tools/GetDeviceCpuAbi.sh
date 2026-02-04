#!/bin/bash
# ----------------------------------------------------------------------
#     author   : Android 轮子哥
#     github   : https://github.com/getActivity/AndroidCmdTools
#      time    : 2026/01/25
#      desc    : 设备 CPU ABI 获取脚本（查询 abi）
# ----------------------------------------------------------------------
scriptDirPath=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
[ -z "" ] || source "../common/SystemPlatform.sh"
source "${scriptDirPath}/../common/SystemPlatform.sh"
[ -z "" ] || source "../common/EnvironmentTools.sh"
source "${scriptDirPath}/../common/EnvironmentTools.sh"
[ -z "" ] || source "/../business/DevicesSelector.sh"
source "${scriptDirPath}/../business/DevicesSelector.sh"

printDeviceCpuAbi() {
    local deviceId=$1
    local abi
    abi=$(adb -s "${deviceId}" shell getprop ro.product.cpu.abi < /dev/null | tr -d '\r')
    local exitCode=$?
    if (( exitCode != 0 )); then
        abi="获取失败"
    elif [[ -z "${abi}" ]]; then
        abi="获取为空"
    fi

    local abiList32
    abiList32=$(adb -s "${deviceId}" shell getprop ro.product.cpu.abilist32 < /dev/null | tr -d '\r')
    exitCode=$?
    if (( exitCode != 0 )); then
        abiList32="获取失败"
    elif [[ -z "${abiList32}" ]]; then
        abiList32="获取为空"
    fi

    local abiList64
    abiList64=$(adb -s "${deviceId}" shell getprop ro.product.cpu.abilist64 < /dev/null | tr -d '\r')
    exitCode=$?
    if (( exitCode != 0 )); then
        abiList64="获取失败"
    elif [[ -z "${abiList64}" ]]; then
        abiList64="获取为空"
    fi

    local abiList
    abiList=$(adb -s "${deviceId}" shell getprop ro.product.cpu.abilist < /dev/null | tr -d '\r')
    exitCode=$?
    if (( exitCode != 0 )); then
        abiList="获取失败"
    elif [[ -z "${abiList}" ]]; then
        abiList="获取为空"
    fi

    echo "✅ [${deviceId}] 设备的 CPU 架构参数为："
    echo "主 ABI：${abi}"
    echo "32 位 ABI 列表：${abiList32}"
    echo "64 位 ABI 列表：${abiList64}"
    echo "所有的 ABI 列表：${abiList}"
    return 0
}

printCpuAbiForDevice() {
    local deviceId
    deviceId="$(inputMultipleAdbDevice)"
    if [[ -n "${deviceId}" ]]; then
        printDeviceCpuAbi "${deviceId}"
    else
        adbDeviceIdsString=$(getAdbDeviceIdsString)
        while read -r adbDeviceId; do
            printDeviceCpuAbi "${adbDeviceId}"
        done < <(echo "${adbDeviceIdsString}" | tr -d '\r' | grep -v '^$')
    fi
    exit 0
}

main() {
    printCurrentSystemType
    checkAdbEnvironment
    printCpuAbiForDevice
}

clear
main