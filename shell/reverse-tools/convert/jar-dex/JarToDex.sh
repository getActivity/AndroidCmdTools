#!/bin/bash
# ----------------------------------------------------------------------
#     author   : Android 轮子哥
#     github   : https://github.com/getActivity/AndroidCmdTools
#      time    : 2026/01/25
#      desc    : Jar 转 Dex 脚本（d2j 或 dx 转换）
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

    echo "请输入要转换的 jar 文件路径："
    read -r inputFilePath
    inputFilePath=$(parseComputerFilePath "${inputFilePath}")

    if [[ ! -f "${inputFilePath}" ]]; then
        echo "❌ 文件不存在，请检查 ${inputFilePath} 文件路径是否正确"
        exit 1
    fi

    if [[ ! "${inputFilePath}" =~ \.(jar)$ ]]; then
        echo "❌ 文件错误，只支持文件名后缀为 jar 的文件"
        exit 1
    fi

    outputFilePath="${inputFilePath%.*}.dex"
    jar2dexNameSuffix="-$(date "+%Y%m%d%H%M%S")"
    if [[ -f "${outputFilePath}" ]]; then
        outputFilePath="${outputFilePath%.*}${jar2dexNameSuffix}.dex"
    elif [[ -d "${outputFilePath}" ]]; then
        if [[ "$(find "${outputFilePath}" -mindepth 1 | head -1)" ]]; then
            outputFilePath="${outputFilePath%.*}${jar2dexNameSuffix}.dex"
        else
            rmdir "${outputFilePath}"
        fi
    fi
    echo "输出的 dex 文件路径：${outputFilePath}"

    outputPrint="$("${resourcesDirPath}$(getFileSeparator)dex2jar-2.4$(getFileSeparator)d2j-jar2dex.sh" -f -o "${outputFilePath}" "${inputFilePath}" 2>&1)"
    exitCode=$?
    if (( exitCode != 0 )); then
        echo "❌ jar 转 dex 失败，原因如下："
        echo "${outputPrint}"
        exit 1
    fi

    if [[ ! -f "${outputFilePath}" ]]; then
        echo "❌ 转换失败，请检查 d2j-jar2dex.sh 输出的信息："
        echo "${outputPrint}"
        exit 1
    fi

    echo "✅ 转换成功，输出路径：${outputFilePath}"
}

clear
main