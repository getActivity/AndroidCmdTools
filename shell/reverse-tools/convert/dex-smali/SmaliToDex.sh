#!/bin/bash
# ----------------------------------------------------------------------
#     author   : Android 轮子哥
#     github   : https://github.com/getActivity/AndroidCmdTools
#      time    : 2026/01/25
#      desc    : Smali 转 Dex 脚本（smali 汇编）
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

    echo "请输入要汇编的 smali 源目录路径："
    read -r inputSmaliDirPath
    inputSmaliDirPath=$(parseComputerFilePath "${inputSmaliDirPath}")

    if [[ ! -d "${inputSmaliDirPath}" ]]; then
        echo "❌ 目录不存在，请检查 ${inputSmaliDirPath} 目录路径是否正确"
        exit 1
    fi

    outputDexFilePath="${inputSmaliDirPath%/}.dex"
    smali2dexNameSuffix="-$(date "+%Y%m%d%H%M%S")"
    if [[ -f "${outputDexFilePath}" ]]; then
        outputDexFilePath="${outputDexFilePath%.*}${smali2dexNameSuffix}.dex"
    elif [[ -d "${outputDexFilePath}" ]]; then
        if [[ "$(find "${outputDexFilePath}" -mindepth 1 | head -1)" ]]; then
            outputDexFilePath="${outputDexFilePath%.*}${smali2dexNameSuffix}.dex"
        else
            rmdir "${outputDexFilePath}"
        fi
    fi

    outputPrint="$(java -jar "${resourcesDirPath}$(getFileSeparator)smali-2.5.2.jar" a "${inputSmaliDirPath}" -o "${outputDexFilePath}" 2>&1)"
    exitCode=$?
    if (( exitCode != 0 )); then
        echo "❌ smali 转 dex 失败，原因如下："
        echo "${outputPrint}"
        exit 1
    fi

    if [[ ! -f "${outputDexFilePath}" ]]; then
        echo "❌ 转换失败，请检查 smali 输出的信息："
        echo "${outputPrint}"
        exit 1
    fi

    echo "✅ 转换成功，输出路径：${outputDexFilePath}"
}

clear
main