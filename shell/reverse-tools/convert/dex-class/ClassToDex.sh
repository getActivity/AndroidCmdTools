#!/bin/bash
# ----------------------------------------------------------------------
#     author   : Android 轮子哥
#     github   : https://github.com/getActivity/AndroidCmdTools
#      time    : 2026/01/25
#      desc    : Class 转 Dex 脚本（打包 class 为 dex）
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
    checkJarEnvironment
    jarCmd=$(getJarCmd)

    resourcesDirPath=$(getResourcesDirPath)
    if [[ -z "${resourcesDirPath}" ]]; then
        echo "❌ 未找到 resources 目录，请确保它位于脚本的当前目录或者父目录"
        exit 1
    fi
    echo "资源目录为：${resourcesDirPath}"

    echo "请输入 .class 文件所在目录或单个 .class 文件路径"
    read -r inputPath
    inputPath=$(parseComputerFilePath "${inputPath}")

    if [[ -z "${inputPath}" ]]; then
        echo "❌ 路径为空，请检查输入是否正确"
        exit 1
    fi

    if [[ -d "${inputPath}" ]]; then
        classesDirPath="${inputPath}"
        tempJar="${classesDirPath%/}-class2dex-temp.jar"
        echo "中间 jar 路径：${tempJar}"
        outputPrint=$("${jarCmd}" cf "${tempJar}" -C "${classesDirPath}" . 2>&1)
    elif [[ -f "${inputPath}" ]]; then
        if [[ ! "${inputPath}" =~ \.(class)$ ]]; then
            echo "❌ 文件错误，只支持文件名后缀为 class 的文件"
            exit 1
        fi
        classesDirPath="$(dirname "${inputPath}")"
        singleClassFileName="$(basename "${inputPath}")"
        tempJar="${inputPath%.*}-class2dex-temp.jar"
        echo "中间 jar 路径：${tempJar}"
        outputPrint=$("${jarCmd}" cf "${tempJar}" -C "${classesDirPath}" "${singleClassFileName}" 2>&1)
    else
        echo "❌ 路径不存在，请检查 ${inputPath} 是否正确"
        exit 1
    fi

    exitCode=$?
    if (( exitCode != 0 )) || [[ ! -f "${tempJar}" ]]; then
        echo "❌ 将 class 打包成 jar 失败，原因如下："
        echo "${outputPrint}"
        exit 1
    fi

    if [[ -d "${inputPath}" ]]; then
        outputDex="${classesDirPath%/}.dex"
    else
        outputDex="${inputPath%.*}.dex"
    fi
    class2dexNameSuffix="-$(date "+%Y%m%d%H%M%S")"
    if [[ -f "${outputDex}" ]]; then
        outputDex="${outputDex%.*}${class2dexNameSuffix}.dex"
    elif [[ -d "${outputDex}" ]]; then
        if [[ "$(find "${outputDex}" -mindepth 1 | head -1)" ]]; then
            outputDex="${outputDex%.*}${class2dexNameSuffix}.dex"
        else
            rmdir "${outputDex}"
        fi
    fi
    outputPrint="$("${resourcesDirPath}$(getFileSeparator)dex2jar-2.4$(getFileSeparator)d2j-jar2dex.sh" -f -o "${outputDex}" "${tempJar}" 2>&1)"
    exitCode=$?
    rm -f "${tempJar}"
    if (( exitCode != 0 )) || [[ ! -f "${outputDex}" ]]; then
        echo "❌ class 转 dex 失败，原因如下："
        echo "${outputPrint}"
        exit 1
    fi

    echo "✅ 转换成功，dex 存放路径：${outputDex}"
}

clear
main