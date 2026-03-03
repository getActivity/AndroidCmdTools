#!/bin/bash
# ----------------------------------------------------------------------
#     author   : Android 轮子哥
#     github   : https://github.com/getActivity/AndroidCmdTools
#      time    : 2026/01/25
#      desc    : 压缩包对比脚本（比较两个归档差异）
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

    echo "请输入旧 apk/aar/jar/aab 包的路径："
    read -r oldLibraryFilePath
    oldLibraryFilePath=$(parseComputerFilePath "${oldLibraryFilePath}")
    if [[ ! -f "${oldLibraryFilePath}" ]]; then
        echo "文件不存在，请检查 ${oldLibraryFilePath} 文件路径是否正确"
        exit 1
    fi
    if [[ ! "${oldLibraryFilePath}" =~ \.([Aa][Pp][Kk]|[Aa][Aa][Rr]|[Jj][Aa][Rr]|[Aa][Aa][Bb])$ ]]; then
        echo "文件错误，只支持文件名后缀为 apk, aar, jar, aab 包的文件"
        exit 1
    fi

    echo "请输入新 apk/aar/jar/aab 包的路径："
    read -r newLibraryFilePath
    newLibraryFilePath=$(parseComputerFilePath "${newLibraryFilePath}")
    if [[ ! -f "${newLibraryFilePath}" ]]; then
        echo "文件不存在，请检查 ${newLibraryFilePath} 文件路径是否正确"
        exit 1
    fi
    if [[ ! "${newLibraryFilePath}" =~ \.([Aa][Pp][Kk]|[Aa][Aa][Rr]|[Jj][Aa][Rr]|[Aa][Aa][Bb])$ ]]; then
        echo "文件错误，只支持文件名后缀为 apk, aar, jar, aab 包的文件"
        exit 1
    fi

    java -jar "$(getDiffuserJarFilePath)" diff "${oldLibraryFilePath}" "${newLibraryFilePath}"
}

clear
main