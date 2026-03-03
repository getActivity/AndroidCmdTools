#!/bin/bash
# ----------------------------------------------------------------------
#     author   : Android 轮子哥
#     github   : https://github.com/getActivity/AndroidCmdTools
#      time    : 2026/01/25
#      desc    : adb 安装脚本（支持批量安装和多设备并行安装）
# ----------------------------------------------------------------------
scriptDirPath=$(dirname "${BASH_SOURCE[0]}")
originalDirPath=$PWD
cd "${scriptDirPath}" || exit 1
source "../common/SystemPlatform.sh" && \
source "../common/FileTools.sh" && \
source "../common/EnvironmentTools.sh" && \
source "../business/DevicesSelector.sh" && \
source "../business/ResourceManager.sh" || exit 1
cd "${originalDirPath}" || exit 1
unset scriptDirPath
unset originalDirPath

unzipDirPathSuffix="-$(date "+%Y%m%d%H%M%S")"

waitUserInputParameter() {
    local inputPath
    if [[ -n "$1" ]]; then
        inputPath="$1"
    else
        echo "请输入要安装的 apk/apks/xapk/apkm 文件或所在目录路径："
        read -r inputPath
    fi
    sourcePath=$(parseComputerFilePath "${inputPath}")

    if [[ -z "${sourcePath}" ]]; then
        echo "❌ 路径为空，请检查输入是否正确"
        exit 1
    fi

    packageFiles=()
    if [[ -d "${sourcePath}" ]]; then
        while IFS= read -r -d '' file; do
            packageFiles+=("${file}")
        done < <(find "${sourcePath}" -maxdepth 1 -type f \( -iname "*.apk" -o -iname "*.apks" -o -iname "*.xapk" -o -iname "*.apkm" \) -print0)
        if (( ${#packageFiles[@]} == 0 )); then
            echo "❌ 该目录下没有以 .apk/.apks/.xapk/.apkm 结尾的文件，安装中止"
            exit 1
        fi
    elif [[ -f "${sourcePath}" ]]; then
        if [[ ! "${sourcePath}" =~ \.([Aa][Pp][Kk]|[Aa][Pp][Kk][Ss]|[Xx][Aa][Pp][Kk]|[Aa][Pp][Kk][Mm])$ ]]; then
            echo "❌ 文件错误，只接受后缀为 apk/apks/xapk/apkm 的文件"
            exit 1
        fi
        packageFiles+=("${sourcePath}")
    else
        echo "❌ 路径不存在，请检查 ${sourcePath} 是否正确"
        exit 1
    fi
}

installSingleApk() {
    local deviceId=$1
    local apkFilePath=$2
    local baseName
    baseName=$(basename "${apkFilePath}")
    echo "⏳ [${deviceId}] 设备正在安装 [${baseName}]"
    local outputPrint
    outputPrint=$(adb -s "${deviceId}" install -r "${apkFilePath}" < /dev/null 2>&1)
    local exitCode=$?
    if (( exitCode == 0 )); then
        echo "✅ [${deviceId}] 设备安装 [${baseName}] 成功"
        return 0
    else
        echo "❌ [${deviceId}] 设备安装 [${baseName}] 失败，原因如下："
        echo "${outputPrint}"
        return 1
    fi
}

installApksWithBundletool() {
    local deviceId=$1
    local apksFilePath=$2
    local baseName
    baseName=$(basename "${apksFilePath}")
    echo "⏳ [${deviceId}] 设备正在安装 [${baseName}]"
    local outputPrint
    local javaMajorVersionCode
    javaMajorVersionCode=$(getJavaMajorVersionCode)
    if (( javaMajorVersionCode <= 11 )); then
        local tempDirPath
        tempDirPath=$(unzipFileToTempDir "${apksFilePath}")
        local -a apkList=()
        while IFS= read -r -d '' apk; do apkList+=("${apk}"); done < <(findApkPathForDir "${tempDirPath}")
        outputPrint=$(adb -s "${deviceId}" install-multiple -r "${apkList[@]}" < /dev/null 2>&1)
    else
        local bundletoolJar
        bundletoolJar="$(getBundletoolJarFilePath)"
        outputPrint=$(java -jar "${bundletoolJar}" install-apks --apks="${apksFilePath}" --device-id="${deviceId}" < /dev/null 2>&1)
    fi
    local exitCode=$?
    if (( exitCode == 0 )); then
        echo "✅ [${deviceId}] 设备安装 [${baseName}] 成功"
        return 0
    else
        echo "❌ [${deviceId}] 设备安装 [${baseName}] 失败，原因如下："
        echo "${outputPrint}"
        return 1
    fi
}

installMultipleApkFromDir() {
    local deviceId=$1
    local unzipApkDirPath=$2
    local targetApkFilePath=$3
    local -a apkList=()
    while IFS= read -r -d '' apk; do apkList+=("${apk}"); done < <(findApkPathForDir "${unzipApkDirPath}")
    local baseName
    baseName=$(basename "${targetApkFilePath}")
    echo "⏳ [${deviceId}] 设备正在安装 [${baseName}]"
    local outputPrint
    outputPrint=$(adb -s "${deviceId}" install-multiple -r "${apkList[@]}" < /dev/null 2>&1)
    local exitCode=$?
    if (( exitCode == 0 )); then
        echo "✅ [${deviceId}] 设备安装 [${baseName}] 成功"
        return 0
    else
        echo "❌ [${deviceId}] 设备安装 [${baseName}] 失败，原因如下："
        echo "${outputPrint}"
        return 1
    fi
}

unzipFileToTempDir() {
    local archivePath=$1
    local tempDirPath
    tempDirPath="${archivePath%.*}${unzipDirPathSuffix}"
    if [[ ! -d "${tempDirPath}" ]]; then
        unzip -q -o "${archivePath}" -d "${tempDirPath}" < /dev/null
    fi
    echo "${tempDirPath}"
}

maybePushObb() {
    local deviceId=$1
    local unzipApkDirPath=$2
    local obbPath="${unzipApkDirPath}/Android/obb"
    if [[ -d "${obbPath}" ]]; then
        echo "⏳ [${deviceId}] 检测到 OBB，正在推送至 /sdcard/Android/obb"
        adb -s "${deviceId}" shell "mkdir -p /sdcard/Android/obb" < /dev/null > /dev/null 2>&1
        adb -s "${deviceId}" push "${obbPath}" "/sdcard/Android/obb" < /dev/null
    fi
}

getBashApkPath() {
    local dir="$1"
    local manifest="${dir}/manifest.json"
    local basePath=""
    if [[ -f "${manifest}" ]]; then
        local oneLine
        oneLine=$(tr -d '\n' < "${manifest}")
        local baseRel
        baseRel=$(printf "%s" "$oneLine" | sed -n 's/.*"id"[[:space:]]*:[[:space:]]*"base"[[:space:]]*,[^{]*"file"[[:space:]]*:[[:space:]]*"\([^"]*\.apk\)".*/\1/p' | head -n1)
        if [[ -z "${baseRel}" ]]; then
            baseRel=$(printf "%s" "$oneLine" | sed -n 's/.*"file"[[:space:]]*:[[:space:]]*"\([^"]*\.apk\)".*"id"[[:space:]]*:[[:space:]]*"base".*/\1/p' | head -n1)
        fi
        if [[ -n "${baseRel}" && -f "${dir}/${baseRel}" ]]; then
            basePath="${dir}/${baseRel}"
        fi
    fi
    if [[ -z "${basePath}" ]]; then
        local p
        while IFS= read -r -d '' p; do
            if [[ "$(basename "$p")" == "base.apk" ]]; then basePath="$p"; break; fi
        done < <(find "${dir}" -type f -name "base.apk" -print0)
    fi
    if [[ -z "${basePath}" ]]; then
        local p
        while IFS= read -r -d '' p; do
            if [[ "$(basename "$p")" == "base-master.apk" ]]; then basePath="$p"; break; fi
        done < <(find "${dir}" -type f -name "base-master.apk" -print0)
    fi
    echo "${basePath}"
}

findApkPathForDir() {
    local dir="$1"
    local basePath
    basePath="$(getBashApkPath "${dir}")"
    if [[ -n "${basePath}" ]]; then
        printf '%s\0' "${basePath}"
    fi
    while IFS= read -r -d '' p; do
        if [[ -n "${basePath}" && "$p" == "${basePath}" ]]; then
            continue
        fi
        printf '%s\0' "$p"
    done < <(find "${dir}" -type f -iname "*.apk" -print0)
}

installMultipleApk() {
    local deviceId=$1
    local successCount=0
    local failCount=0
    for filePath in "${packageFiles[@]}"; do
        if [[ "${filePath}" =~ \.([Aa][Pp][Kk])$ ]]; then
            installSingleApk "${deviceId}" "${filePath}"
        elif [[ "${filePath}" =~ \.([Aa][Pp][Kk][Ss])$ ]]; then
            installApksWithBundletool "${deviceId}" "${filePath}"
        elif [[ "${filePath}" =~ \.([Xx][Aa][Pp][Kk]|[Aa][Pp][Kk][Mm])$ ]]; then
            local tempDirPath
            tempDirPath=$(unzipFileToTempDir "${filePath}")
            if [[ "${filePath}" =~ \.([Xx][Aa][Pp][Kk])$ ]]; then
                maybePushObb "${deviceId}" "${tempDirPath}"
            fi
            installMultipleApkFromDir "${deviceId}" "${tempDirPath}" "${filePath}"
        else
            echo "👻 跳过不支持的文件类型：${filePath}"
            continue
        fi
        local exitCode=$?
        if (( exitCode == 0 )); then
            ((successCount++))
        else
            ((failCount++))
        fi
    done
    if (( ${#packageFiles[@]} > 1 )); then
        echo "📋 [${deviceId}] 设备安装任务完成，成功 ${successCount} 个，失败 ${failCount} 个"
    fi
    return 0
}

installApkForDevice() {
    local deviceId
    deviceId="$(inputMultipleAdbDevice)"
    local pids=()
    if [[ -n "${deviceId}" ]]; then
        installMultipleApk "${deviceId}" &
        pids+=($!)
    else
        echo "⏳ 正在并行向多台设备安装..."
        adbDeviceIdsString=$(getAdbDeviceIdsString)
        while read -r adbDeviceId; do
            installMultipleApk "${adbDeviceId}" &
            pids+=($!)
        done < <(echo "${adbDeviceIdsString}" | tr -d '\r' | grep -v '^$')
    fi
    for pid in "${pids[@]}"; do
        wait "${pid}"
    done
}

clearTempDir() {
    local packageFilePath
    for packageFilePath in "${packageFiles[@]}"; do
        if [[ -z "${packageFilePath}" ]]; then
            continue
        fi
        local tempDir="${packageFilePath%.*}${unzipDirPathSuffix}"
        if [[ -d "${tempDir}" ]]; then
            rm -rf "${tempDir}"
        fi
    done
}

main() {
    printCurrentSystemType
    checkAdbEnvironment
    waitUserInputParameter "$1"
    installApkForDevice
    clearTempDir
}

clear
main "$@"