#!/bin/bash
# ----------------------------------------------------------------------
#     author   : Android 轮子哥
#     github   : https://github.com/getActivity/AndroidCmdTools
#      time    : 2026/02/26
#      desc    : 使用 bundletool 将 .aab 转为 .apks（优先按连接设备构建）
# ----------------------------------------------------------------------
scriptDirPath=$(dirname "${BASH_SOURCE[0]}")
originalDirPath=$PWD
cd "${scriptDirPath}" || exit 1
source "../common/SystemPlatform.sh" && \
source "../common/FileTools.sh" && \
source "../common/EnvironmentTools.sh" && \
source "../business/DevicesSelector.sh" && \
source "../business/ResourceManager.sh" || exit 1
cd "${originalDirPath}" || exit 1
unset scriptDirPath
unset originalDirPath

waitUserInputParameter() {
    if [[ -n "$1" ]]; then
        aabFilePath="$1"
    else
        echo "请输入要转换的 aab 文件路径："
        read -r aabFilePath
    fi

    aabFilePath=$(parseComputerFilePath "${aabFilePath}")
    if [[ -z "${aabFilePath}" ]]; then
        echo "❌ 输入的路径为空，请检查输入是否正确"
        exit 1
    fi

    if [[ ! -f "${aabFilePath}" ]]; then
        echo "❌ 输入的文件不存在，请检查 ${aabFilePath} 是否正确"
        exit 1
    fi

    if [[ ! "${aabFilePath}" =~ \.([Aa][Aa][Bb])$ ]]; then
        echo "❌ 输入无效，只接受以 .aab 结尾的文件"
        exit 1
    fi

    buildModeArgs=()
    echo "🤔 请选择构建模式："
    echo "1. 按设备构建（推荐，生成的 apks 体积更小）"
    echo "2. 通用模式构建（生成的 apks 体积更大，但适用于所有设备）"
    while true; do
        read -r resultChoice
        if [[ "${resultChoice}" == "1" ]]; then
            local adbDeviceIdsString
            adbDeviceIdsString=$(getAdbDeviceIdsString | tr -d '\r' | grep -v '^$' || true)
            if [[ -z "${adbDeviceIdsString}" ]]; then
                echo "❌ 没有检测到连接的设备，请先连接设备后再选择按设备构建"
                continue
            fi
            local deviceId
            deviceId="$(inputSingleAdbDevice)"
            buildModeArgs+=(--connected-device --device-id="${deviceId}")
            break
        elif [[ "${resultChoice}" == "2" ]]; then
            buildModeArgs+=(--mode=universal)
            break
        else
            echo "👻 请选择正确的选项编号"
            continue
        fi
    done
}

main() {
    checkJavaElevenEnvironment
    waitUserInputParameter "$1"
    local apksFilePath
    apksFilePath="$(dirname "${aabFilePath}")/$(basename "${aabFilePath%.*}").apks"
    apksFileSuffix="-$(date "+%Y%m%d%H%M%S")"
    if [[ -f "${apksFilePath}" ]]; then
        apksFilePath="${apksFilePath%.*}${apksFileSuffix}.${apksFilePath##*.}"
    elif [[ -d "${apksFilePath}" ]]; then
        if [[ "$(find "${apksFilePath}" -mindepth 1 | head -1)" ]]; then
            apksFilePath="${apksFilePath%.*}${apksFileSuffix}.${apksFilePath##*.}"
        else
            rmdir "${apksFilePath}"
        fi
    fi

    local bundletoolJar
    bundletoolJar="$(getBundletoolJarFilePath)"

    local modeArgs=()
    modeArgs=("${buildModeArgs[@]}")

    local outputPrint
    outputPrint=$(java -jar "${bundletoolJar}" build-apks --bundle="${aabFilePath}" --output="${apksFilePath}" "${modeArgs[@]}" < /dev/null 2>&1)
    local exitCode=$?
    if (( exitCode == 0 )); then
        echo "✅ 生成成功：${apksFilePath}"
        return 0
    else
        echo "❌ 生成失败，原因如下："
        echo "${outputPrint}"
        return 1
    fi
}

clear
main "$@"