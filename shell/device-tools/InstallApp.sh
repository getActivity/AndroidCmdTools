#!/bin/bash
# ----------------------------------------------------------------------
#     author   : Android 轮子哥
#     github   : https://github.com/getActivity/AndroidCmdTools
#      time    : 2026/01/25
#      desc    : adb 安装脚本（支持批量安装和多设备并行安装）
# ----------------------------------------------------------------------
scriptDirPath=$(dirname "${BASH_SOURCE[0]}")
originalDirPath=$PWD
cd "${scriptDirPath}" || exit 1
source "../common/SystemPlatform.sh" && \
source "../common/FileTools.sh" && \
source "../common/EnvironmentTools.sh" && \
source "../business/DevicesSelector.sh" || exit 1
cd "${originalDirPath}" || exit 1
unset scriptDirPath
unset originalDirPath

waitUserInputParameter() {
    echo "请输入要安装的 apk 文件或所在目录路径："
    read -r sourcePath
    sourcePath=$(parseComputerFilePath "${sourcePath}")

    if [[ -z "${sourcePath}" ]]; then
        echo "❌ 路径为空，请检查输入是否正确"
        exit 1
    fi

    apkFiles=()
    if [[ -d "${sourcePath}" ]]; then
        while IFS= read -r -d '' file; do
            apkFiles+=("${file}")
        done < <(find "${sourcePath}" -maxdepth 1 -type f -name "*.apk" -print0)
        if (( ${#apkFiles[@]} == 0 )); then
            echo "❌ 该目录下没有以 .apk 结尾的文件，安装中止"
            exit 1
        fi
    elif [[ -f "${sourcePath}" ]]; then
        if [[ ! "${sourcePath}" =~ \.(apk)$ ]]; then
            echo "❌ 文件错误，只接受文件名后缀为 apk 的文件"
            exit 1
        fi
        apkFiles+=("${sourcePath}")
    else
        echo "❌ 路径不存在，请检查 ${sourcePath} 是否正确"
        exit 1
    fi
}

installSingleApk() {
    local deviceId=$1
    local apkFilePath=$2
    local baseName
    baseName=$(basename "${apkFilePath}")
    echo "⏳ [${deviceId}] 设备正在安装 [${baseName}]"
    local outputPrint
    outputPrint=$(adb -s "${deviceId}" install -r "${apkFilePath}" < /dev/null 2>&1)
    local exitCode=$?
    if (( exitCode == 0 )); then
        echo "✅ [${deviceId}] 设备安装 [${baseName}] 成功"
        return 0
    else
        echo "❌ [${deviceId}] 设备安装 [${baseName}] 失败，原因如下："
        echo "${outputPrint}"
        return 1
    fi
}

installMultipleApk() {
    local deviceId=$1
    local successCount=0
    local failCount=0
    for apkFilePath in "${apkFiles[@]}"; do
        installSingleApk "${deviceId}" "${apkFilePath}"
        local exitCode=$?
        if (( exitCode == 0 )); then
            ((successCount++))
        else
            ((failCount++))
        fi
    done
    if (( ${#apkFiles[@]} > 1 )); then
        echo "📋 [${deviceId}] 设备安装任务完成，成功 ${successCount} 个，失败 ${failCount} 个"
    fi
    return 0
}

installApkForDevice() {
    local deviceId
    deviceId="$(inputMultipleAdbDevice)"
    local pids=()
    if [[ -n "${deviceId}" ]]; then
        echo "⏳ 正在安装中..."
        installMultipleApk "${deviceId}" &
        pids+=($!)
    else
        echo "⏳ 正在并行向多台设备安装..."
        adbDeviceIdsString=$(getAdbDeviceIdsString)
        while read -r adbDeviceId; do
            installMultipleApk "${adbDeviceId}" &
            pids+=($!)
        done < <(echo "${adbDeviceIdsString}" | tr -d '\r' | grep -v '^$')
    fi
    for pid in "${pids[@]}"; do
        wait "${pid}"
    done
}

main() {
    printCurrentSystemType
    checkAdbEnvironment
    waitUserInputParameter
    installApkForDevice
}

clear
main