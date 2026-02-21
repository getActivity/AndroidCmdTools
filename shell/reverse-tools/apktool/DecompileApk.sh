#!/bin/bash
# ----------------------------------------------------------------------
#     author   : Android 轮子哥
#     github   : https://github.com/getActivity/AndroidCmdTools
#      time    : 2026/01/25
#      desc    : Apk 反编译脚本（使用 apktool 解包）
# ----------------------------------------------------------------------
scriptDirPath=$(dirname "${BASH_SOURCE[0]}")
originalDirPath=$PWD
cd "${scriptDirPath}" || exit 1
source "../../common/SystemPlatform.sh" && \
source "../../common/EnvironmentTools.sh" && \
source "../../common/FileTools.sh" || exit 1
cd "${originalDirPath}" || exit 1
unset scriptDirPath
unset originalDirPath

waitUserInputParameter() {
    resourcesDirPath=$(getResourcesDirPath)
    echo "资源目录为：${resourcesDirPath}"

    echo "请输入要反编译 apk 包的路径"
    read -r sourceApkFilePath
    sourceApkFilePath=$(parseComputerFilePath "${sourceApkFilePath}")

    if [[ ! -f "${sourceApkFilePath}" ]]; then
        echo "❌ 文件不存在，请检查 ${sourceApkFilePath} 文件路径是否正确"
        exit 1
    fi

    if [[ ! "${sourceApkFilePath}" =~ \.(apk)$ ]]; then
        echo "❌ 文件错误，只能反编译文件名后缀为 apk 的文件"
        exit 1
    fi

    echo "请设置反编译 apk 输出目录路径（可为空，默认输出到和反编译 apk 文件同级且同名的目录下）"
    read -r apkDecompileDirPath
    apkDecompileDirPath=$(parseComputerFilePath "${apkDecompileDirPath}")

    if [[ -z "${apkDecompileDirPath}" ]]; then
        apkDecompileDirPath="${sourceApkFilePath%.*}"
    else
        apkDecompileDirPath="${apkDecompileDirPath}$(getFileSeparator)$(basename "${sourceApkFilePath%.*}")"
    fi

    decompileDirNameSuffix="-decompile-$(date "+%Y%m%d%H%M%S")"
    if [[ -f "${apkDecompileDirPath}" ]]; then
        apkDecompileDirPath="${apkDecompileDirPath}${decompileDirNameSuffix}"
    elif [[ -d "${apkDecompileDirPath}" && "$(find "${apkDecompileDirPath}" -mindepth 1 | head -1)" ]]; then
        echo "该目录已经存在且不为空，是否覆盖原有内容？（y/n）"
        while true; do
            read -r rewriteConfirm
            if [[ "${rewriteConfirm}" =~ ^[yY]$ ]]; then
                rm -rf "${apkDecompileDirPath:?}"
                mkdir -p "${apkDecompileDirPath}"
                break
            elif [[ "${rewriteConfirm}" =~ ^[nN]$ ]]; then
                apkDecompileDirPath="${apkDecompileDirPath}${decompileDirNameSuffix}"
                break
            else
                echo "👻 输入不正确，请输入正确的选项（y/n）"
                continue
            fi
        done
    fi

    local apktoolJarFileName="apktool-2.12.1.jar"
    echo "请输入 apktool jar 包的路径（可为空，默认使用 ${apktoolJarFileName}）"
    read -r apktoolJarFilePath
    apktoolJarFilePath=$(parseComputerFilePath "${apktoolJarFilePath}")

    if [[ -z "${apktoolJarFilePath}" ]]; then
        apktoolJarFilePath="${resourcesDirPath}$(getFileSeparator)${apktoolJarFileName}"
    fi

    if [[ ! -f "${apktoolJarFilePath}" ]]; then
        echo "❌ 文件不存在，请检查 ${apktoolJarFilePath} 文件路径是否正确"
        exit 1
    fi

    echo "请输入 framework-res.apk 包所在的目录（可为空）"
    read -r frameworkResourcesDirPath
    frameworkResourcesDirPath=$(parseComputerFilePath "${frameworkResourcesDirPath}")

    frameworkResourcesFilePath="${frameworkResourcesDirPath}$(getFileSeparator)1.apk"
    if [[ -n "${frameworkResourcesDirPath}" ]]; then
        if [[ ! -d "${frameworkResourcesDirPath}" ]]; then
            echo "❌ 目录不存在，请检查 ${frameworkResourcesDirPath} 目录路径是否正确"
            exit 1
        fi
        if [[ ! -f "${frameworkResourcesFilePath}" ]]; then
            echo "❌ 文件不存在，请检查 ${frameworkResourcesFilePath} 文件路径是否正确"
            exit 1
        fi
    fi

    echo "反编译 apk 的路径：${sourceApkFilePath}"

    echo "反编译 apk 包输出目录路径：${apkDecompileDirPath}"

    if [[ -n "${apktoolJarFilePath}" ]]; then
        echo "apktool 包路径：${apktoolJarFilePath}"
    fi

    if [[ -n "${frameworkResourcesDirPath}" ]]; then
        echo "framework-res.apk 目录路径：${frameworkResourcesDirPath}"
        echo "framework-res.apk 文件路径：${frameworkResourcesFilePath}"
    fi
}

decompileApk() {
    echo "⏳ 正在反编译，过程可能会比较慢，请耐心等待"
    if [[ -d "${frameworkResourcesDirPath}" ]]; then
        outputPrint=$(java -jar "${apktoolJarFilePath}" d -f "${sourceApkFilePath}" -o "${apkDecompileDirPath}" -p "${frameworkResourcesDirPath}" 2>&1)
    else
        outputPrint=$(java -jar "${apktoolJarFilePath}" d -f "${sourceApkFilePath}" -o "${apkDecompileDirPath}" 2>&1)
    fi
    exitCode=$?
    if (( exitCode != 0 )); then
        echo "❌ 反编译过程中出现错误，原因如下："
        echo "${outputPrint}"
        exit 1
    fi

    if [[ ! -d "${apkDecompileDirPath}" || -z "$(ls -A "${apkDecompileDirPath}")" ]]; then
        echo "❌ 反编译失败，请检查 apktool 输出的信息："
        echo "${outputPrint}"
        exit 1
    fi

    echo "✅ 反编译 apk 完成，存放目录：${apkDecompileDirPath}"
}

main() {
    printCurrentSystemType
    checkJavaEnvironment
    waitUserInputParameter
    decompileApk
}

clear
main