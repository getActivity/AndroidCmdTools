#!/bin/bash
# ----------------------------------------------------------------------
#     author   : Android 轮子哥
#     github   : https://github.com/getActivity/AndroidCmdTools
#      time    : 2026/01/25
#      desc    : 用 apktool 回编译 apk
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

waitUserInputParameter() {
    echo "请输入要回编译的 apk 源目录路径（即反编译后的目录）"
    read -r sourceDirPath
    sourceDirPath=$(parseComputerFilePath "${sourceDirPath}")

    if [[ ! -d "${sourceDirPath}" ]]; then
        echo "❌ 目录不存在，请检查 ${sourceDirPath} 目录路径是否正确"
        exit 1
    fi

    echo "请输入回编译输出的 apk 文件路径（可为空，默认输出到同名 .apk 文件）"
    read -r outputApkFilePath
    outputApkFilePath=$(parseComputerFilePath "${outputApkFilePath}")

    if [[ -z "${outputApkFilePath}" ]]; then
        outputApkFilePath="${sourceDirPath%/}.apk"
    fi

    recompileApkNameSuffix="-recompile-$(date "+%Y%m%d%H%M%S")"
    if [[ -f "${outputApkFilePath}" ]]; then
        echo "该文件已经存在，是否覆盖原有内容？（y/n）"
        while true; do
            read -r rewriteConfirm
            if [[ "${rewriteConfirm}" =~ ^[yY]$ ]]; then
                break
            elif [[ "${rewriteConfirm}" =~ ^[nN]$ ]]; then
                outputApkFilePath="${outputApkFilePath%.*}${recompileApkNameSuffix}.apk"
                break
            else
                echo "👻 输入不正确，请输入正确的选项（y/n）"
                continue
            fi
        done
    elif [[ -d "${outputApkFilePath}" ]]; then
        if [[ "$(find "${outputApkFilePath}" -mindepth 1 | head -1)" ]]; then
            outputApkFilePath="${outputApkFilePath%.*}${recompileApkNameSuffix}.apk"
        else
            rmdir "${outputApkFilePath}"
        fi
    fi

    echo "请输入 apktool jar 包的路径（可为空）"
    read -r apktoolJarFilePath
    apktoolJarFilePath=$(parseComputerFilePath "${apktoolJarFilePath}")

    if [[ -z "${apktoolJarFilePath}" ]]; then
        apktoolJarFilePath=$(getApktoolJarFilePath)
    fi

    if [[ ! -f "${apktoolJarFilePath}" ]]; then
        echo "❌ 文件不存在，请检查 ${apktoolJarFilePath} 文件路径是否正确"
        exit 1
    fi

    if [[ ! "${apktoolJarFilePath}" =~ \.([Jj][Aa][Rr])$ ]]; then
        echo "❌ 文件错误，apktool 文件名后缀只能是 jar 结尾"
        exit 1
    fi
}

recompileApk() {
    echo "⏳ 正在回编译，过程可能会比较慢，请耐心等待"
    outputPrint="$(java -jar "${apktoolJarFilePath}" b -f "${sourceDirPath}" -o "${outputApkFilePath}" 2>&1)"
    exitCode=$?
    if (( exitCode != 0 )); then
        echo "❌ 回编译过程中出现错误，原因如下："
        echo "${outputPrint}"
        exit 1
    fi

    if [[ ! -f "${outputApkFilePath}" ]]; then
        echo "❌ 回编译失败，请检查 apktool 输出的信息："
        echo "${outputPrint}"
        exit 1
    fi

    echo "✅ 回编译 apk 完成，输出文件：${outputApkFilePath}"
}

signatureApk() {
    echo "是否要对回编译输出的 apk 进行签名？（y/n）"
    while true; do
        read -r signConfirm
        if [[ "${signConfirm}" =~ ^[yY]$ ]]; then
            selfDir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
            bash "${selfDir}/../../package-tools/SignatureApk.sh" "${outputApkFilePath}"
            break
        elif [[ "${signConfirm}" =~ ^[nN]$ ]]; then
            break
        else
            echo "👻 输入不正确，请输入正确的选项（y/n）"
            continue
        fi
    done
}

main() {
    printCurrentSystemType
    checkJavaEnvironment
    waitUserInputParameter
    recompileApk
    signatureApk
}

clear
main