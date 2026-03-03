#!/bin/bash
# ----------------------------------------------------------------------
#     author   : Android 轮子哥
#     github   : https://github.com/getActivity/AndroidCmdTools
#      time    : 2026/01/25
#      desc    : Jadx 图形界面打开脚本（启动 GUI）
# ----------------------------------------------------------------------
scriptDirPath=$(dirname "${BASH_SOURCE[0]}")
originalDirPath=$PWD
cd "${scriptDirPath}" || exit 1
source "../../common/SystemPlatform.sh" && \
source "../../common/EnvironmentTools.sh" && \
source "../../common/FileTools.sh" && \
source "../../business/ResourceManager.sh" || exit 1
cd "${originalDirPath}" || exit 1
unset scriptDirPath
unset originalDirPath

main() {
    printCurrentSystemType
    checkJavaElevenEnvironment

    echo "请输入要用 jadx 查看包体的文件路径（支持 apk/dex/jar/class/smali/zip/aar/arsc/xapk/apkm/jadx/aab）："
    read -r inputFilePath
    inputFilePath=$(parseComputerFilePath "${inputFilePath}")

    if [[ ! -f "${inputFilePath}" ]]; then
        echo "❌ 文件不存在，请检查 ${inputFilePath} 文件路径是否正确"
        exit 1
    fi

    if [[ ! "${inputFilePath}" =~ \.([Aa][Pp][Kk]|[Dd][Ee][Xx]|[Jj][Aa][Rr]|[Cc][Ll][Aa][Ss][Ss]|[Ss][Mm][Aa][Ll][Ii]|[Zz][Ii][Pp]|[Aa][Aa][Rr]|[Aa][Rr][Ss][Cc]|[Xx][Aa][Pp][Kk]|[Aa][Pp][Kk][Mm]|[Jj][Aa][Dd][Xx]|[Aa][Aa][Bb])$ ]]; then
        echo "❌ 文件错误，仅支持后缀为 apk, dex, jar, class, smali, zip, aar, arsc, xapk, apkm, jadx, aab 的文件"
        exit 1
    fi

    "$(getJadxShellFilePath)" "${inputFilePath}"
}

clear
main