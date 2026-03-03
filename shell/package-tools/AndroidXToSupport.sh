#!/bin/bash
# ----------------------------------------------------------------------
#     author   : Android 轮子哥
#     github   : https://github.com/getActivity/AndroidCmdTools
#      time    : 2026/01/25
#      desc    : androidx 转 support
# ----------------------------------------------------------------------
scriptDirPath=$(dirname "${BASH_SOURCE[0]}")
originalDirPath=$PWD
cd "${scriptDirPath}" || exit 1
source "../common/SystemPlatform.sh" && \
source "../common/EnvironmentTools.sh" && \
source "../common/FileTools.sh" && \
source "../business/ResourceManager.sh" || exit 1
cd "${originalDirPath}" || exit 1
unset scriptDirPath
unset originalDirPath

main() {
    printCurrentSystemType
    checkJavaEnvironment

    echo "请输入要转换 aar / jar / zip 包的路径："
    read -r androidXFilePath
    androidXFilePath=$(parseComputerFilePath "${androidXFilePath}")

    if [[ ! -f "${androidXFilePath}" ]]; then
        echo "❌ 文件不存在，请检查 ${androidXFilePath} 文件路径是否正确"
        exit 1
    fi

    if [[ ! "${androidXFilePath}" =~ \.([Aa][Aa][Rr]|[Jj][Aa][Rr]|[Zz][Ii][Pp])$ ]]; then
        echo "❌ 文件错误，只支持文件名后缀为 aar / jar / zip 包的文件"
        exit 1
    fi

    supportFilePath="${androidXFilePath%.*}-support.${androidXFilePath##*.}"
    supportNameSuffix="-$(date "+%Y%m%d%H%M%S")"
    if [[ -f "${supportFilePath}" ]]; then
        supportFilePath="${supportFilePath%.*}${supportNameSuffix}.${androidXFilePath##*.}"
    elif [[ -d "${supportFilePath}" ]]; then
        if [[ "$(find "${supportFilePath}" -mindepth 1 | head -1)" ]]; then
            supportFilePath="${supportFilePath%.*}${supportNameSuffix}.${androidXFilePath##*.}"
        else
            rmdir "${supportFilePath}"
        fi
    fi
    echo "support 包的保存路径：${supportFilePath}"

    outputPrint="$("$(getJetifierStandaloneShellFilePath)" -r -i "${androidXFilePath}" -o "${supportFilePath}" 2>&1)"
    exitCode=$?
    if (( exitCode != 0 )); then
        echo "❌ 转换失败，原因如下："
        echo "${outputPrint}"
        exit 1
    fi

    if [[ ! -f "${supportFilePath}" ]]; then
        echo "❌ 转换失败，请检查 jetifier-standalone 输出的信息："
        echo "${outputPrint}"
        exit 1
    fi

    echo "✅ 转换成功，存放路径为：${supportFilePath}"
}

clear
main