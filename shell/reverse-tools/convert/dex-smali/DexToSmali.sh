#!/bin/bash
# ----------------------------------------------------------------------
#     author   : Android 轮子哥
#     github   : https://github.com/getActivity/AndroidCmdTools
#      time    : 2026/01/25
#      desc    : Dex 转 Smali 脚本（baksmali 反汇编）
# ----------------------------------------------------------------------
scriptDirPath=$(dirname "${BASH_SOURCE[0]}")
originalDirPath=$PWD
cd "${scriptDirPath}" || exit 1
source "../../../common/SystemPlatform.sh" && \
source "../../../common/EnvironmentTools.sh" && \
source "../../../common/FileTools.sh" || exit 1
cd "${originalDirPath}" || exit 1
unset scriptDirPath
unset originalDirPath

main() {
    printCurrentSystemType
    checkJavaEnvironment

    resourcesDirPath=$(getResourcesDirPath)
    if [[ -z "${resourcesDirPath}" ]]; then
        echo "❌ 未找到 resources 目录，请确保它位于脚本的当前目录或者父目录"
        exit 1
    fi
    echo "资源目录为：${resourcesDirPath}"

    echo "请输入要反汇编的 dex/apk 文件路径"
    read -r inputDexFilePath
    inputDexFilePath=$(parseComputerFilePath "${inputDexFilePath}")

    if [[ ! -f "${inputDexFilePath}" ]]; then
        echo "❌ 文件不存在，请检查 ${inputDexFilePath} 文件路径是否正确"
        exit 1
    fi

    if [[ ! "${inputDexFilePath}" =~ \.(dex|apk)$ ]]; then
        echo "❌ 文件错误，只支持文件名后缀为 dex 或 apk 的文件"
        exit 1
    fi

    outputSmaliDirPath="${inputDexFilePath%.*}"
    dex2smaliDirSuffix="-$(date "+%Y%m%d%H%M%S")"
    if [[ -f "${outputSmaliDirPath}" ]]; then
        outputSmaliDirPath="${outputSmaliDirPath}${dex2smaliDirSuffix}"
    elif [[ -d "${outputSmaliDirPath}" ]]; then
        if [[ "$(find "${outputSmaliDirPath}" -mindepth 1 | head -1)" ]]; then
            outputSmaliDirPath="${outputSmaliDirPath}${dex2smaliDirSuffix}"
        else
            rmdir "${outputSmaliDirPath}"
        fi
    fi

    outputPrint="$(java -jar "${resourcesDirPath}$(getFileSeparator)baksmali-2.5.2.jar" d "${inputDexFilePath}" -o "${outputSmaliDirPath}" 2>&1)"
    exitCode=$?
    if (( exitCode != 0 )); then
        echo "❌ dex 转 smali 失败，原因如下："
        echo "${outputPrint}"
        exit 1
    fi

    if [[ ! -d "${outputSmaliDirPath}" ]]; then
        echo "❌ 转换失败，请检查 baksmali 输出的信息："
        echo "${outputPrint}"
        exit 1
    fi

    echo "✅ 转换成功，输出目录：${outputSmaliDirPath}"
}

clear
main