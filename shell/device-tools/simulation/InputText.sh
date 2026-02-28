#!/bin/bash
# ----------------------------------------------------------------------
#     author   : Android 轮子哥
#     github   : https://github.com/getActivity/AndroidCmdTools
#      time    : 2026/01/25
#      desc    : 输入文本脚本（模拟在设备上输入文本）
# ----------------------------------------------------------------------
scriptDirPath=$(dirname "${BASH_SOURCE[0]}")
originalDirPath=$PWD
cd "${scriptDirPath}" || exit 1
source "../../common/SystemPlatform.sh" && \
source "../../common/EnvironmentTools.sh" && \
source "../../common/FileTools.sh" && \
source "../../common/PasteTools.sh" && \
source "../../business/DevicesSelector.sh" && \
source "../../business/ResourceManager.sh" || exit 1
cd "${originalDirPath}" || exit 1
unset scriptDirPath
unset originalDirPath

ADB_KEY_BOARD_PACKAGE="com.android.adbkeyboard"
ADB_KEY_BOARD_COMPONENT="${ADB_KEY_BOARD_PACKAGE}/.AdbIME"

waitUserInputParameter() {
    echo "请输入要传输的文本（可空，为空则默认读取电脑剪贴板的内容）"
    inputText=""
    if IFS= read -r firstLine; then
        inputText="${firstLine}"
        while IFS= read -r -t 2 nextLine; do
            inputText+=$'\n'
            inputText+="${nextLine}"
        done
    fi
    if [[ -z "${inputText}" ]]; then
        inputText=$(readTextForPaste)
        if [[ -n "${inputText}" ]]; then
            echo "📝 已自动从剪贴板读取文本"
            echo ""
            echo "${inputText}"
        else
            echo "👻 未检测到剪贴板有输入"
        fi
    fi
    if [[ -z "${inputText}" ]]; then
        echo "❌ 输入的内容为空，无法继续操作"
        exit 1
    fi
    printf '\n'
    echo "按回车键继续开始传输..."
    read -r
}

setIme() {
    local deviceId=$1
    local ime=$2
    local outputPrint
    if [[ -z "${ime}" ]]; then
        return 1
    fi
    outputPrint=$(adb -s "${deviceId}" shell ime set "${ime}" < /dev/null 2>&1)
    local exitCode=$?
    if (( exitCode != 0 )); then
        echo "❌ [${deviceId}] 切换输入法失败，原因如下："
        echo "${outputPrint}"
        return ${exitCode}
    fi
    sleep 0.5
    return 0
}

getIme() {
    local deviceId=$1
    local ime
    ime=$(adb -s "${deviceId}" shell settings get secure default_input_method < /dev/null | tr -d '\r')
    echo "${ime}"
}

enableIme() {
    local deviceId=$1
    local ime=$2
    local outputPrint
    outputPrint=$(adb -s "${deviceId}" shell ime enable "${ime}" < /dev/null 2>&1)
    local exitCode=$?
    if (( exitCode != 0 )); then
        echo "❌ [${deviceId}] 启用输入法失败，原因如下："
        echo "${outputPrint}"
        return ${exitCode}
    fi
    sleep 0.5
    return 0
}

isInstallAdbKeyBoard() {
    local deviceId=$1
    if adb -s "${deviceId}" shell pm path "${ADB_KEY_BOARD_PACKAGE}" < /dev/null > /dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

installAdbKeyBoard() {
    local deviceId=$1
    local apkFilePath
    apkFilePath="$(getADBKeyBoardApkFilePath)"
    if [[ ! -f "${apkFilePath}" ]]; then
        echo "❌ 找不到 ADBKeyBoard 安装包：${apkFilePath}"
        return 1
    fi
    echo "ADBKeyBoard 安装包路径为：${apkFilePath}"
    local baseName
    baseName=$(basename "${apkFilePath}")
    local outputPrint
    outputPrint=$(adb -s "${deviceId}" install -r "${apkFilePath}" < /dev/null 2>&1)
    local exitCode=$?
    if (( exitCode == 0 )); then
        echo "✅ [${deviceId}] 设备安装 [${baseName}] 成功"
        return 0
    else
        echo "❌ [${deviceId}] 设备安装 [${baseName}] 失败，原因如下："
        echo "${outputPrint}"
        return ${exitCode}
    fi
}

base64Encode() {
    local text="$1"
    printf '%s' "${text}" | base64
}

base64Decode() {
    local base64String="$1"
    printf '%s' "${base64String}" | base64 --decode
}

shouldUseAdbKeyBoard() {
    local text="$1"
    while IFS=$'\n' read -r line; do
        line=${line//$'\r'/}
        if [[ -z "${line}" ]]; then
            continue
        fi
        local leftover
        leftover=$(printf '%s' "${line}" | LC_ALL=C tr -d '[:alnum:]._@ -')
        if [[ -n "${leftover}" ]]; then
            echo "true"
            return
        fi
    done <<< "${text}"
    echo "false"
}

sendLineBreak() {
    local deviceId=$1
    local useAdbKeyboard=$2
    if [[ "${useAdbKeyboard}" == "true" ]]; then
        # KEYCODE_ENTER = 66
        adb -s "${deviceId}" shell am broadcast -a ADB_INPUT_CODE --ei code 66 < /dev/null > /dev/null 2>&1
    else
        adb -s "${deviceId}" shell input keyevent KEYCODE_ENTER < /dev/null > /dev/null 2>&1
    fi
}

sendBase64ByAdbKeyBoard() {
    local deviceId=$1
    local base64String=$2
    adb -s "${deviceId}" shell am broadcast -a ADB_INPUT_B64 --es msg "${base64String}" < /dev/null > /dev/null 2>&1
}

# 按字节截取 UTF-8 字符串，确保不截断多字节字符
truncateUtf8() {
    local string="$1"
    local maxBytes="$2"
    
    # 获取当前字符串字节数
    local length
    length=$(printf '%s' "${string}" | LC_ALL=C wc -c)
    
    if (( length <= maxBytes )); then
        printf '%s' "${string}"
        return
    fi

    # 初步截取 maxBytes
    # 使用 head -c 按字节截取 (兼容 macOS/Linux/Git Bash)
    local chunk
    chunk=$(printf '%s' "${string}" | LC_ALL=C head -c "${maxBytes}")
    
    # 获取 chunk 的实际字节长度
    local chunkLen
    chunkLen=$(printf '%s' "${chunk}" | LC_ALL=C wc -c | tr -d ' ')
    
    # 如果截取后的长度小于 maxBytes，说明原字符串本身就短，不需要截断检查
    if (( chunkLen < maxBytes )); then
        printf '%s' "${chunk}"
        return
    fi
    
    # 检查末尾字节，防止切在字符中间
    # 0xxxxxxx (0-127): ASCII，安全
    # 11xxxxxx (192-255): 多字节头，不安全（除非刚好是下一个字符的开始，但这里是末尾，说明缺了后续），需要回退
    # 10xxxxxx (128-191): 多字节后续，不安全，需要回退找到头
    
    # 获取最后 4 个字节的十进制值 (UTF-8 最大 4 字节)
    local tailBytes
    # 使用 od -An -t u1 输出十进制字节值，tr -s ' ' 将多个空格压缩为一个，方便转数组
    tailBytes=$(printf '%s' "${chunk}" | tail -c 4 | od -An -t u1 | tr -s ' ')
    
    # 转为数组
    local bytesArray
    IFS=' ' read -r -a bytesArray <<< "${tailBytes}"
    
    # 移除数组中可能存在的空元素 (由于 od 输出前后可能有空格)
    local cleanBytesArray=()
    for byte in "${bytesArray[@]}"; do
        [[ -n "${byte}" ]] && cleanBytesArray+=("${byte}")
    done
    bytesArray=("${cleanBytesArray[@]}")
    
    local count=${#bytesArray[@]}
    
    local dropCount=0
    # 倒序检查
    for (( i=count-1; i>=0; i-- )); do
        local byteVal=${bytesArray[i]}
        
        if (( byteVal < 128 )); then
            # ASCII，完整字符，之前的截断有效
            break
        elif (( byteVal >= 192 )); then
            # 多字节头
            local char_len=2
            if (( byteVal >= 240 )); then char_len=4;
            elif (( byteVal >= 224 )); then char_len=3; fi
            
            # 如果从这个头开始剩下的长度不足 char_len，说明被截断了
            local currentLength=$(( count - i ))
            if (( currentLength < char_len )); then
                dropCount=$(( currentLength ))
            fi
            # 找到了头，判断完毕
            break
        else
            # 10xxxxxx，继续往前找头
            continue
        fi
    done
    
    local finalLength=$(( maxBytes - dropCount ))

    while true; do
        local nextByte
        nextByte=$(printf '%s' "${string}" | LC_ALL=C head -c "$((finalLength + 1))" | LC_ALL=C tail -c 1 | od -An -t u1 | tr -d ' ' | tr -d '\n')
        if [[ -z "${nextByte}" ]]; then
            break
        fi
        if (( nextByte >= 128 && nextByte <= 191 )); then
            finalLength=$(( finalLength - 1 ))
            continue
        fi
        break
    done

    printf '%s' "${chunk}" | LC_ALL=C head -c "${finalLength}"
}

sendSegmentsText() {
    local deviceId=$1
    local inputText=$2
    local useAdbKeyboard=$3

    # 计算分段阈值（原始字节数）
    local maxRawBytes
    if isWindows; then
        # Windows: Base64 限制 76 -> 原始字节 57
        # 为什么是 57？Base64 编码是 3 字节变 4 字节。76 * 3 / 4 = 57。
        maxRawBytes=57
    else
        # Others: Base64 限制 2048 -> 原始字节 1536
        # Base64 长度 = (原始字节 + 2) / 3 * 4
        # 2048 * 3 / 4 = 1536
        # 保守一点，减去一点余量，防止某些系统 base64 实现的差异
        maxRawBytes=1500
    fi

    if [[ "${useAdbKeyboard}" == "true" ]]; then
        # 使用 AdbKeyboard (高效模式)
        # 策略：不按行切割，直接将包含换行符的全文视为一个整体。
        # 按 maxRawBytes 循环切分，Base64 编码后发送广播。
        # AdbKeyboard 会自动处理 Base64 解码后的换行符。
        local remainingText="${inputText}"
        while [[ -n "${remainingText}" ]]; do
            # 1. 获取安全的切片 (包含换行符)
            local chunk
            chunk=$(truncateUtf8 "${remainingText}" "${maxRawBytes}")
            
            # 2. Base64 编码并发送
            if [[ -n "${chunk}" ]]; then
                local chunkBase64
                chunkBase64=$(base64Encode "${chunk}" | tr -d '\n')
                sendBase64ByAdbKeyBoard "${deviceId}" "${chunkBase64}"
                # echo "正在分段发送 Base64：${chunkBase64}"
                # echo "解码后的原文本：$(base64Decode "${chunkBase64}")"
                sleep 0.01
            fi
            
            # 3. 移除已发送部分
            local chunkLength
            chunkLength=$(printf '%s' "${chunk}" | LC_ALL=C wc -c | tr -d ' ')
            
            if (( chunkLength == 0 )); then break; fi
            
            remainingText=$(printf '%s' "${remainingText}" | LC_ALL=C dd bs=1 skip="${chunkLength}" 2> /dev/null)
        done

        return 0
    fi

    # 使用原生 ADB (兼容模式)
    # 策略：必须按行切割，因为 `input text` 不支持换行符。
    # 每行发送完毕后，需手动发送回车键事件。

    local lines=()
    while IFS= read -r line || [[ -n "${line}" ]]; do
        lines+=("${line}")
    done <<< "${inputText}"

    totalLines=${#lines[@]}
    for ((idx=1; idx<=totalLines; idx++)); do
        local line="${lines[$((idx-1))]}"

        # 逐行处理：如果单行过长，也需要切分发送 (URL 编码模式)
        while [[ -n "${line}" ]]; do
            # 1. 获取安全的切片
            local chunk
            chunk=$(truncateUtf8 "${line}" "${maxRawBytes}")

            # 2. URL 编码并发送
            if [[ -n "${chunk}" ]]; then
                local encoded="${chunk// /%s}"
                adb -s "${deviceId}" shell input text "${encoded}" < /dev/null > /dev/null 2>&1
                # echo "正在分段发送文本：${encoded}"
                sleep 0.01
            fi

            # 3. 移除已发送部分
            local chunkLength
            chunkLength=$(printf '%s' "${chunk}" | LC_ALL=C wc -c | tr -d ' ')

            if (( chunkLength == 0 )); then break; fi

            line=$(printf '%s' "${line}" | LC_ALL=C dd bs=1 skip="${chunkLength}" 2> /dev/null)
        done

        # 行尾发送回车键
        if (( idx < totalLines )); then
            sendLineBreak "${deviceId}" "${useAdbKeyboard}"
            # echo "正在发送换行符"
            sleep 0.01
        fi
    done
}

inputTextSingleDevice() {
    local deviceId=$1
    local text=$2
    local needAdbKeyboard=$3
    local currentIme
    currentIme=$(getIme "${deviceId}")
    local useAdbKeyboard="false"
    if [[ ${needAdbKeyboard} == "true" && "${currentIme}" == "${ADB_KEY_BOARD_COMPONENT}" ]]; then
        useAdbKeyboard="true"
    fi

    echo "⏳ [${deviceId}] 设备正在发送文本"
    sendSegmentsText "${deviceId}" "${text}" "${useAdbKeyboard}"

    if [[ "${useAdbKeyboard}" == "true" ]]; then
        echo "✅ [${deviceId}] 设备已通过 ADBKeyBoard 完成文本输入"
    else
        echo "✅ [${deviceId}] 设备已通过 ADB 模拟文本输入"
    fi
}

enableAdbKeyBoard() {
    echo "⏳ 正在将输入法设置成 ADBKeyBoard"
    local adbDeviceList=("$@")
    restoreImePairs=()
    for adbDeviceId in "${adbDeviceList[@]}"; do
        if ! isInstallAdbKeyBoard "${adbDeviceId}"; then
            continue
        fi
        if [[ ${needAdbKeyboard} == "true" ]]; then
            # 记录原先的输入法
            originalIme=$(getIme "${adbDeviceId}")
            restoreImePairs+=("${adbDeviceId}|${originalIme}")

            # 启用 ADBKeyBoard 输入法
            enableIme "${adbDeviceId}" "${ADB_KEY_BOARD_COMPONENT}"
            local exitCode=$?
            if (( exitCode != 0 )); then
                exit ${exitCode}
            fi

            # 设置 ADBKeyBoard 输入法
            setIme "${adbDeviceId}" "${ADB_KEY_BOARD_COMPONENT}"
            exitCode=$?
            if (( exitCode != 0 )); then
                exit ${exitCode}
            fi
            sleep 0.3
        fi
    done
}

disabledAdbKeyBoard() {
    echo "⏳ 正在将输入法还原回去"
    for pair in "${restoreImePairs[@]}"; do
        local deviceId="${pair%%|*}"
        local originalIme="${pair#*|}"
        if [[ -z "${deviceId}" || -z "${originalIme}" ]]; then
            continue
        fi

        local currentIme
        currentIme=$(getIme "${deviceId}")
        if [[ "${currentIme}" != "${originalIme}" ]]; then
            enableIme "${deviceId}" "${originalIme}"
            setIme "${deviceId}" "${originalIme}"
        fi
    done
}

checkInstallAdbKeyBoard() {
    local adbDeviceList=("$@")
    for adbDeviceId in "${adbDeviceList[@]}"; do
        if isInstallAdbKeyBoard "${adbDeviceId}"; then
            continue
        fi

        echo "🤔 检测到 [${adbDeviceId}] 设备 ADBKeyBoard 还未安装，请问是否安装？（y/n）"
        while true; do
            read -r installConfirm
            if [[ "${installConfirm}" =~ ^[yY]$ ]]; then
                installAdbKeyBoard "${adbDeviceId}"
                local exitCode=$?
                if (( exitCode != 0 )); then
                    exit ${exitCode}
                fi
                break
            elif [[ "${installConfirm}" =~ ^[nN]$ ]]; then
                echo "✅ 用户手动取消安装"
                exit 0
            else
                echo "👻 输入不正确，请输入正确的选项（y/n）"
                continue
            fi
        done
    done
}

inputTextForDevice() {
    needAdbKeyboard=$(shouldUseAdbKeyBoard "${inputText}")

    local restoreImePairs=()

    local deviceId
    deviceId="$(inputMultipleAdbDevice)"

    local adbDeviceList=()
    if [[ -n "${deviceId}" ]]; then
        while IFS= read -r line; do
            [[ -n "${line}" ]] && adbDeviceList+=("${line}")
        done <<< "${deviceId}"
    else
        adbDeviceIdsString=$(getAdbDeviceIdsString)
        while read -r adbDeviceId; do
            adbDeviceList+=("${adbDeviceId}")
        done < <(echo "${adbDeviceIdsString}" | tr -d '\r' | grep -v '^$')
    fi

    if [[ ${needAdbKeyboard} == "true" ]]; then
        echo "💡 检测到文本包含特殊字符，将使用 ADBKeyBoard 来输入文本"
        checkInstallAdbKeyBoard "${adbDeviceList[@]}"
        enableAdbKeyBoard "${adbDeviceList[@]}"
    fi

    local adbDeviceCount=${#adbDeviceList[@]}
    if (( adbDeviceCount >= 1 )); then
        echo "🤔 请问所有设备的输入框焦点是否都已经获取？（y/n）"
    else
        echo "🤔 请问当前设备的输入框焦点是否已经获取？（y/n）"
    fi

    while true; do
        read -r focusConfirm
        if [[ "${focusConfirm}" =~ ^[yY]$ ]]; then
            local pids=()
            for adbDeviceId in "${adbDeviceList[@]}"; do
                inputTextSingleDevice "${adbDeviceId}" "${inputText}" "${needAdbKeyboard}" &
                pids+=($!)
            done
            for pid in "${pids[@]}"; do
                wait "${pid}"
            done
            disabledAdbKeyBoard
            if (( adbDeviceCount >= 1 )); then
                echo "✅ 所有设备的文本输入任务已完成"
            else
                echo "✅ 当前设备的文本输入任务已完成"
            fi
            break
        elif [[ "${focusConfirm}" =~ ^[nN]$ ]]; then
            disabledAdbKeyBoard
            echo "✅ 用户选择不获取焦点，无法进行下一步，取消操作"
            break
        else
            echo "👻 输入不正确，请输入正确的选项（y/n）"
            continue
        fi
    done
}

main() {
    printCurrentSystemType
    checkAdbEnvironment
    waitUserInputParameter
    inputTextForDevice
}

clear
main