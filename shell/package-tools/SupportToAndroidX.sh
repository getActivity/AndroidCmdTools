#!/bin/bash
# ----------------------------------------------------------------------
#     author   : Android 轮子哥
#     github   : https://github.com/getActivity/AndroidCmdTools
#      time    : 2026/01/25
#      desc    : support 转 androidx
# ----------------------------------------------------------------------
scriptDirPath=$(dirname "${BASH_SOURCE[0]}")
originalDirPath=$PWD
cd "${scriptDirPath}" || exit 1
source "../common/SystemPlatform.sh" && \
source "../common/EnvironmentTools.sh" && \
source "../common/FileTools.sh" || exit 1
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

    echo "请输入要转换 aar / jar / zip 包的路径："
    read -r supportFilePath
    supportFilePath=$(parseComputerFilePath "${supportFilePath}")

    if [[ ! -f "${supportFilePath}" ]]; then
        echo "❌ 文件不存在，请检查 ${supportFilePath} 文件路径是否正确"
        exit 1
    fi

    if [[ ! "${supportFilePath}" =~ \.(aar|jar|zip)$ ]]; then
        echo "❌ 文件错误，只支持文件名后缀为 aar / jar / zip 包的文件"
        exit 1
    fi

    androidXFilePath="${supportFilePath%.*}-androidx.${supportFilePath##*.}"
    androidxNameSuffix="-$(date "+%Y%m%d%H%M%S")"
    if [[ -f "${androidXFilePath}" ]]; then
        androidXFilePath="${androidXFilePath%.*}${androidxNameSuffix}.${supportFilePath##*.}"
    elif [[ -d "${androidXFilePath}" ]]; then
        if [[ "$(find "${androidXFilePath}" -mindepth 1 | head -1)" ]]; then
            androidXFilePath="${androidXFilePath%.*}${androidxNameSuffix}.${supportFilePath##*.}"
        else
            rmdir "${androidXFilePath}"
        fi
    fi
    echo "androidx 包的保存路径：${androidXFilePath}"

    outputPrint="$("${resourcesDirPath}$(getFileSeparator)jetifier-standalone-20200827$(getFileSeparator)bin$(getFileSeparator)jetifier-standalone" -i "${supportFilePath}" -o "${androidXFilePath}" 2>&1)"
    exitCode=$?
    if (( exitCode != 0 )); then
        echo "❌ 转换失败，原因如下："
        echo "${outputPrint}"
        exit 1
    fi

    if [[ ! -f "${androidXFilePath}" ]]; then
        echo "❌ 转换失败，请检查 jetifier-standalone 输出的信息："
        echo "${outputPrint}"
        exit 1
    fi

    echo "✅ 转换成功，存放路径为：${androidXFilePath}"
    exit 0
}

clear
main