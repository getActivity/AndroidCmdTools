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
source "../../common/FileTools.sh" || exit 1
cd "${originalDirPath}" || exit 1
unset scriptDirPath
unset originalDirPath

main() {
    printCurrentSystemType
    checkJavaElevenEnvironment

    resourcesDirPath=$(getResourcesDirPath)
    if [[ -z "${resourcesDirPath}" ]]; then
        echo "❌ 未找到 resources 目录，请确保它位于脚本的当前目录或者父目录"
        exit 1
    fi
    echo "资源目录为：${resourcesDirPath}"

    echo "请输入要用 jadx 查看包体的文件路径（支持 apk/dex/jar/class/smali/zip/aar/arsc/xapk/apkm/jadx/aab）："
    read -r inputFilePath
    inputFilePath=$(parseComputerFilePath "${inputFilePath}")

    if [[ ! -f "${inputFilePath}" ]]; then
        echo "❌ 文件不存在，请检查 ${inputFilePath} 文件路径是否正确"
        exit 1
    fi

    if [[ ! "${inputFilePath}" =~ \.(apk|dex|jar|class|smali|zip|aar|arsc|xapk|apkm|jadx|aab)$ ]]; then
        echo "❌ 文件错误，仅支持后缀为 apk, dex, jar, class, smali, zip, aar, arsc, xapk, apkm, jadx, aab 的文件"
        exit 1
    fi

    fileSeparator=$(getFileSeparator)
    jadxVersion="1.5.3"
    jadxDirPath="${resourcesDirPath}${fileSeparator}jadx-${jadxVersion}"
    if [[ ! -d "${jadxDirPath}" ]]; then
        zipFileName="jadx-${jadxVersion}.zip"
        decompressedDirPath="${resourcesDirPath}${fileSeparator}jadx-${jadxVersion}"
        zipUrl="https://github.com/skylot/jadx/releases/download/v${jadxVersion}/${zipFileName}"
        zipFilePath="${resourcesDirPath}${fileSeparator}${zipFileName}"
        expectedSha256="8280f3799c0273fe797a2bcd90258c943e451fd195f13d05400de5e6451d15ec"
        if [[ -f "${zipFilePath}" ]]; then
            actualSha256=$(getFileSha256 "${zipFilePath}")
            if [[ "${actualSha256}" != "${expectedSha256}" ]]; then
                rm -f "${zipFilePath}"
            fi
        fi
        if [[ -f "${zipFilePath}" ]]; then
            outputPrint="$(unzip -q -o "${zipFilePath}" -d "${decompressedDirPath}" 2>&1)"
            exitCode=$?
            if (( exitCode != 0 )); then
                echo "❌ ${zipFileName} 解压失败，原因如下："
                echo "${outputPrint}"
                exit 1
            fi
        else
            echo "⏳ 检测到本地还未下载 jadx，开始下载 ${zipFileName} 文件，体积较大请耐心等待..."
            curl -L --progress-bar -o "${zipFilePath}" "${zipUrl}"
            exitCode=$?
            if (( exitCode != 0 )); then
                echo "❌ ${zipFileName} 下载失败，请检查网络或稍后重试"
                exit 1
            fi
            actualSha256=$(getFileSha256 "${zipFilePath}")
            if [[ "${actualSha256}" != "${expectedSha256}" ]]; then
                rm -f "${zipFilePath}"
                echo "❌ ${zipFileName} 文件校验失败，期望值：${expectedSha256}，实际值：${actualSha256}"
                exit 1
            fi
            outputPrint="$(unzip -q -o "${zipFilePath}" -d "${decompressedDirPath}" 2>&1)"
            exitCode=$?
            if (( exitCode != 0 )); then
                echo "❌ ${zipFileName} 解压失败，原因如下："
                echo "${outputPrint}"
                exit 1
            fi
        fi
        rm -f "${zipFilePath}"
    fi

    jadxGuiShellFilePath="${jadxDirPath}${fileSeparator}bin${fileSeparator}jadx-gui"
    if ! isWindows; then
        if [[ ! -x "${jadxGuiShellFilePath}" ]]; then
            chmod +x "${jadxGuiShellFilePath}"
        fi
        jadxShellFilePath="${jadxDirPath}${fileSeparator}bin${fileSeparator}jadx"
        if [[ ! -x "${jadxShellFilePath}" ]]; then
            chmod +x "${jadxShellFilePath}"
        fi
    fi

    "${jadxGuiShellFilePath}" "${inputFilePath}"
}

clear
main