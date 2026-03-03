#!/bin/bash
# ----------------------------------------------------------------------
#     author   : Android 轮子哥
#     github   : https://github.com/getActivity/AndroidCmdTools
#      time    : 2026/01/25
#      desc    : 获取 apk 签名信息
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

    echo "请输入要要进行要验证的 apk 包的路径（不能为空）"
    read -r sourceApkFilePath
    sourceApkFilePath=$(parseComputerFilePath "${sourceApkFilePath}")

    if [[ ! -f "${sourceApkFilePath}" ]]; then
        echo "❌ 文件不存在，请检查 ${sourceApkFilePath} 文件路径是否正确"
        exit 1
    fi

    if [[ ! "${sourceApkFilePath}" =~ \.([Aa][Pp][Kk])$ ]]; then
        echo "❌ 文件错误，只能验证文件名后缀为 apk 的文件"
        exit 1
    fi

    echo "请输入 apksigner jar 包的路径（可为空）"
    read -r apkSignerJarFilePath
    apkSignerJarFilePath=$(parseComputerFilePath "${apkSignerJarFilePath}")

    if [[ -z "${apkSignerJarFilePath}" ]]; then
        apkSignerJarFilePath="$(getApksignerJarFilePath)"
    fi

    if [[ ! -f "${apkSignerJarFilePath}" ]]; then
        echo "❌ 文件不存在，请检查 ${apkSignerJarFilePath} 文件路径是否正确"
        exit 1
    fi

    if [[ ! "${apkSignerJarFilePath}" =~ \.([Jj][Aa][Rr])$ ]]; then
        echo "❌ 文件错误，apksigner 文件名后缀只能是 jar 结尾"
        exit 1
    fi

    echo "要验证签名的 apk 包的路径：${sourceApkFilePath}"
    echo "apksigner jar 包的路径：${apkSignerJarFilePath}"

    outputPrint="$(java -jar "${apkSignerJarFilePath}" verify -verbose -print-certs-pem  "${sourceApkFilePath}" 2>&1)"
    exitCode=$?
    if (( exitCode != 0 )); then
        echo "❌ apk 签名验证失败，原因如下："
        echo "${outputPrint}"
        exit 1
    fi

    echo "✅ apk 签名验证成功，签名信息如下："
    echo "${outputPrint}"
}

clear
main