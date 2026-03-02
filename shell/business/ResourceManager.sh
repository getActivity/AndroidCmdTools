#!/bin/bash
# ----------------------------------------------------------------------
#     author   : Android 轮子哥
#     github   : https://github.com/getActivity/AndroidCmdTools
#      time    : 2026/02/28
#      desc    : 资源管理器脚本
# ----------------------------------------------------------------------
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../common/SystemPlatform.sh" || source "../common/SystemPlatform.sh"
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../common/FileTools.sh" || source "../common/FileTools.sh"

getDexToJarShellDirPath() {
    local resourcesDirPath
    resourcesDirPath=$(getResourcesDirPath)
    echo "${resourcesDirPath}$(getFileSeparator)dex2jar-2.4$(getFileSeparator)d2j-dex2jar.sh"
}

getDexToJarShellFilePath() {
    local resourcesDirPath
    resourcesDirPath=$(getResourcesDirPath)
    echo "${resourcesDirPath}$(getFileSeparator)dex2jar-2.4$(getFileSeparator)d2j-dex2jar.sh"
}

getJarToDexShellDirPath() {
    local resourcesDirPath
    resourcesDirPath=$(getResourcesDirPath)
    echo "${resourcesDirPath}$(getFileSeparator)dex2jar-2.4$(getFileSeparator)d2j-jar2dex.sh"
}

getJarToDexShellFilePath() {
    local resourcesDirPath
    resourcesDirPath=$(getResourcesDirPath)
    echo "${resourcesDirPath}$(getFileSeparator)dex2jar-2.4$(getFileSeparator)d2j-jar2dex.sh"
}

getJadxShellFilePath() {
    local resourcesDirPath
    resourcesDirPath=$(getResourcesDirPath)
    local fileSeparator
    fileSeparator=$(getFileSeparator)
    local jadxVersion="1.5.3"
    local jadxDirPath="${resourcesDirPath}${fileSeparator}jadx-${jadxVersion}"

    local outputPrint
    local exitCode
    local actualSha256
    if [[ ! -d "${jadxDirPath}" ]]; then
        local zipFileName="jadx-${jadxVersion}.zip"
        local decompressedDirPath="${resourcesDirPath}${fileSeparator}jadx-${jadxVersion}"
        local zipUrl="https://github.com/skylot/jadx/releases/download/v${jadxVersion}/${zipFileName}"
        local zipFilePath="${resourcesDirPath}${fileSeparator}${zipFileName}"
        local expectedSha256="8280f3799c0273fe797a2bcd90258c943e451fd195f13d05400de5e6451d15ec"
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
                echo "❌ ${zipFileName} 解压失败，原因如下：" >&2
                echo "${outputPrint}" >&2
                kill -SIGTERM $$
                exit 1
            fi
        else
            echo "⏳ 检测到本地还未下载 jadx，开始下载 ${zipFileName} 文件，体积较大请耐心等待..." >&2
            curl -L --progress-bar -o "${zipFilePath}" "${zipUrl}"
            exitCode=$?
            if (( exitCode != 0 )); then
                echo "❌ ${zipFileName} 下载失败，请检查网络或稍后重试" >&2
                kill -SIGTERM $$
                exit 1
            fi
            actualSha256=$(getFileSha256 "${zipFilePath}")
            if [[ "${actualSha256}" != "${expectedSha256}" ]]; then
                rm -f "${zipFilePath}"
                echo "❌ ${zipFileName} 文件校验失败，期望值：${expectedSha256}，实际值：${actualSha256}" >&2
                kill -SIGTERM $$
                exit 1
            fi
            outputPrint="$(unzip -q -o "${zipFilePath}" -d "${decompressedDirPath}" 2>&1)"
            exitCode=$?
            if (( exitCode != 0 )); then
                echo "❌ ${zipFileName} 解压失败，原因如下：" >&2
                echo "${outputPrint}" >&2
                kill -SIGTERM $$
                exit 1
            fi
        fi
        rm -f "${zipFilePath}"
    fi

    local jadxGuiShellFilePath="${jadxDirPath}${fileSeparator}bin${fileSeparator}jadx-gui"
    if ! isWindows; then
        if [[ ! -x "${jadxGuiShellFilePath}" ]]; then
            chmod +x "${jadxGuiShellFilePath}"
        fi
        local jadxShellFilePath="${jadxDirPath}${fileSeparator}bin${fileSeparator}jadx"
        if [[ ! -x "${jadxShellFilePath}" ]]; then
            chmod +x "${jadxShellFilePath}"
        fi
    fi
    echo "${jadxGuiShellFilePath}"
}

getJetifierStandaloneShellFilePath() {
    local resourcesDirPath
    resourcesDirPath=$(getResourcesDirPath)
    local fileSeparator
    fileSeparator=$(getFileSeparator)
    local jetifierDirPath="${resourcesDirPath}${fileSeparator}jetifier-standalone-20200827"
    local shellPath="${jetifierDirPath}${fileSeparator}bin${fileSeparator}jetifier-standalone"
    if isWindows; then
        echo "${shellPath}.bat"
        return
    fi
    if [[ ! -x "${shellPath}" ]]; then
        chmod +x "${shellPath}"
    fi
    echo "${shellPath}"
}

getADBKeyBoardApkFilePath() {
    local resourcesDirPath
    resourcesDirPath=$(getResourcesDirPath)
    echo "${resourcesDirPath}$(getFileSeparator)ADBKeyBoard-5.0.apk"
}

getApksignerJarFilePath() {
    local resourcesDirPath
    resourcesDirPath=$(getResourcesDirPath)
    echo "${resourcesDirPath}$(getFileSeparator)apksigner-36.0.0.jar"
}

getDefaultStoreFilePath() {
    local resourcesDirPath
    resourcesDirPath=$(getResourcesDirPath)
    echo "${resourcesDirPath}$(getFileSeparator)signatureFile$(getFileSeparator)AppSignature.jks"
}

getApktoolJarFilePath() {
    local resourcesDirPath
    resourcesDirPath=$(getResourcesDirPath)
    local apktoolVersion="3.0.1"
    local jarFilePath
    jarFilePath="${resourcesDirPath}$(getFileSeparator)apktool-${apktoolVersion}.jar"
    local expectedSha256="b947b945b4bc455609ba768d071b64d9e63834079898dbaae15b67bf03bcd362"
    local actualSha256
    if [[ -f "${jarFilePath}" ]]; then
        actualSha256=$(getFileSha256 "${jarFilePath}")
        if [[ "${actualSha256}" == "${expectedSha256}" ]]; then
            echo "${jarFilePath}"
            return
        fi
        rm -f "${jarFilePath}"
    fi
    local url="https://github.com/iBotPeaches/Apktool/releases/download/v${apktoolVersion}/apktool_${apktoolVersion}.jar"
    echo "⏳ 检测到本地还未下载 apktool，开始下载 apktool-${apktoolVersion}.jar，体积较大请耐心等待..." >&2
    curl -L --progress-bar -o "${jarFilePath}" "${url}"
    local exitCode=$?
    if (( exitCode != 0 )); then
        echo "❌ apktool-${apktoolVersion}.jar 下载失败，请检查网络或稍后重试" >&2
        kill -SIGTERM $$
        exit 1
    fi
    actualSha256=$(getFileSha256 "${jarFilePath}")
    if [[ "${actualSha256}" != "${expectedSha256}" ]]; then
        rm -f "${jarFilePath}"
        echo "❌ apktool-${apktoolVersion}.jar 文件校验失败，期望值：${expectedSha256}，实际值：${actualSha256}" >&2
        kill -SIGTERM $$
        exit 1
    fi
    echo "${jarFilePath}"
}

getBaksmaliJarFilePath() {
    local resourcesDirPath
    resourcesDirPath=$(getResourcesDirPath)
    echo "${resourcesDirPath}$(getFileSeparator)baksmali-2.5.2.jar"
}

getSmaliJarFilePath() {
    local resourcesDirPath
    resourcesDirPath=$(getResourcesDirPath)
    echo "${resourcesDirPath}$(getFileSeparator)smali-2.5.2.jar"
}

getDiffuserJarFilePath() {
    local resourcesDirPath
    resourcesDirPath=$(getResourcesDirPath)
    echo "${resourcesDirPath}$(getFileSeparator)diffuse-0.1.0.jar"
}

getJdGuiJarFilePath() {
    local resourcesDirPath
    resourcesDirPath=$(getResourcesDirPath)
    echo "${resourcesDirPath}$(getFileSeparator)jd-gui-1.6.6.jar"
}

getBundletoolJarFilePath() {
    local resourcesDirPath
    resourcesDirPath=$(getResourcesDirPath)
    local bundletoolVersion="1.18.3"
    local jarFilePath
    jarFilePath="${resourcesDirPath}$(getFileSeparator)bundletool-${bundletoolVersion}.jar"
    local expectedSha256="a099cfa1543f55593bc2ed16a70a7c67fe54b1747bb7301f37fdfd6d91028e29"
    local actualSha256
    if [[ -f "${jarFilePath}" ]]; then
        actualSha256=$(getFileSha256 "${jarFilePath}")
        if [[ "${actualSha256}" == "${expectedSha256}" ]]; then
            echo "${jarFilePath}"
            return
        fi
        rm -f "${jarFilePath}"
    fi
    local url="https://github.com/google/bundletool/releases/download/${bundletoolVersion}/bundletool-all-${bundletoolVersion}.jar"
    echo "⏳ 检测到本地还未下载 bundletool，开始下载 bundletool-all-${bundletoolVersion}.jar，体积较大请耐心等待..." >&2
    curl -L --progress-bar -o "${jarFilePath}" "${url}"
    local exitCode=$?
    if (( exitCode != 0 )); then
        echo "❌ bundletool-all-${bundletoolVersion}.jar 下载失败，请检查网络或稍后重试" >&2
        kill -SIGTERM $$
        exit 1
    fi
    actualSha256=$(getFileSha256 "${jarFilePath}")
    if [[ "${actualSha256}" != "${expectedSha256}" ]]; then
        rm -f "${jarFilePath}"
        echo "❌ bundletool-all-${bundletoolVersion}.jar 文件校验失败，期望值：${expectedSha256}，实际值：${actualSha256}" >&2
        kill -SIGTERM $$
        exit 1
    fi
    echo "${jarFilePath}"
}