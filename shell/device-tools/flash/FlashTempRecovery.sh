#!/bin/bash
# ----------------------------------------------------------------------
#     author   : Android 轮子哥
#     github   : https://github.com/getActivity/AndroidCmdTools
#      time    : 2026/01/25
#      desc    : 临时引导恢复脚本（fastboot boot recovery）
# ----------------------------------------------------------------------
scriptDirPath=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
[ -z "" ] || source "../../common/SystemPlatform.sh"
source "${scriptDirPath}/../../common/SystemPlatform.sh"
[ -z "" ] || source "../../common/FileTools.sh"
source "${scriptDirPath}/../../common/FileTools.sh"
[ -z "" ] || source "../../common/EnvironmentTools.sh"
source "${scriptDirPath}/../../common/EnvironmentTools.sh"
[ -z "" ] || source "../../business/DevicesSelector.sh"
source "${scriptDirPath}/../../business/DevicesSelector.sh"

isAbPartitionDevice() {
    # 获取current-slot值（仅保留a/b，屏蔽错误输出）
    local currentSlot=$(getCurrentSlot)
    # 非空则是A/B分区，返回0；空则非A/B，返回1
    if [[ -n "${currentSlot}" ]]; then
        return 0
    else
        return 1
    fi
}

getCurrentSlot() {
    fastboot getvar current-slot 2>&1 | grep -oE 'current-slot: [ab]' | awk '{print $2}'
}

switchToAnotherSlot() {
    local currentSlot=$(getCurrentSlot)
    local targetSlot=""
    if [[ "${currentSlot}" == "a" ]]; then
        targetSlot="b"
    else
        targetSlot="a"
    fi
    echo "🔄 当前激活槽位为：${currentSlot}，准备切换到槽位：${targetSlot}"
    fastboot set_active "${targetSlot}" 2>/dev/null
    local newSlot=$(getCurrentSlot)
    if [[ "${newSlot}" == "${targetSlot}" ]]; then
        echo "✅ 槽位切换成功，当前激活槽位：${newSlot}"
        return 0
    else
        echo "❌ 槽位切换失败，将继续使用原槽位重试"
        return 1
    fi
}

clearMiscPartition() {
    echo "🧹 正在清空 misc 分区，清除启动错误标记"
    fastboot erase misc 2>/dev/null
}

flashTempRecoveryForDevice() {
    fastbootDeviceList=()
    fastbootDeviceIdsString=$(getFastbootDeviceIdsString)
    while read -r fastbootDeviceId; do
        fastbootDeviceList+=("${fastbootDeviceId}")
    done < <(echo "${fastbootDeviceIdsString}" | tr -d '\r')
    fastbootDeviceCount=${#fastbootDeviceList[@]}

    if (( fastbootDeviceCount > 1 )); then
        echo "❌ 当前操作仅支持单设备操作，请断开多余设备后重试"
        return 1
    fi

    # 判断是否为A/B分区设备
    if isAbPartitionDevice; then
        echo "💡 检测到设备为 A/B 分区设备，启用槽位容错逻辑"
        currentSlot=$(getCurrentSlot)
        echo "📝 当前设备激活槽位：${currentSlot}"
    else
        echo "📝 检测到设备为非 A/B 分区设备，直接加载 recovery"
    fi

    echo "请输入要加载 recovery 包的路径"
    read -r recoveryFilePath
    recoveryFilePath=$(parseComputerFilePath "${recoveryFilePath}")

    if [[ ! -f "${recoveryFilePath}" ]]; then
        echo "❌ 文件不存在，请检查 ${recoveryFilePath} 文件路径是否正确"
        return 1
    fi

    if [[ ! "${recoveryFilePath}" =~ \.(img)$ ]]; then
        echo "❌ 文件错误，只接受文件名后缀为 img 的文件"
        exit 1
    fi

    echo "这是一个危险操作，你确定要给设备加载临时的 recovery ？（y/n）"
    read -r loadConfirm
    if [[ "${loadConfirm}" == "n" || "${loadConfirm}" == "N" ]]; then
        echo "✅ 用户手动取消操作"
        return 0
    elif [[ "${loadConfirm}" != "y" && "${loadConfirm}" != "Y" ]]; then
        echo "❌ 无效选择，已取消操作"
        return 1
    fi

    echo "⏳ 正在加载临时 recovery 文件，过程可能会比较慢，请耐心等待 5 ~ 10 分钟"
    clearMiscPartition
    local outputPrint
    outputPrint=$(fastboot boot "${recoveryFilePath}" < /dev/null 2>&1)
    local exitCode=$?
    if (( exitCode == 0 )); then
        echo "✅ 加载临时的 recovery 成功"
        fastboot reboot recovery < /dev/null
        return
    fi

    if ! isAbPartitionDevice; then
        echo "❌ 加载临时的 recovery 失败，原因如下："
        echo "${outputPrint}"
        return
    fi

    echo "💡 当前是A/B分区设备，开始匹配错误关键字"
    echo "${outputPrint}"
    if echo "${outputPrint}" | grep -qi 'bad buffer size'; then
        echo "⏳ 匹配到 Bad Buffer Size 错误，准备切槽位再重试"
        clearMiscPartition
        switchToAnotherSlot
        outputPrint=$(fastboot boot "${recoveryFilePath}" < /dev/null 2>&1)
        exitCode=$?
        if (( exitCode == 0 )); then
            echo "✅ 切换槽位后，加载临时的 recovery 成功"
            fastboot reboot recovery < /dev/null
        else
            echo "❌ 切换槽位后仍加载失败，最终失败原因："
            echo "${outputPrint}"
            clearMiscPartition
            switchToAnotherSlot
        fi
    else
        echo "📝 未匹配到 Bad Buffer Size 错误，错误内容不触发切槽位逻辑"
    fi
}

main() {
    printCurrentSystemType
    checkFastbootEnvironment
    flashTempRecoveryForDevice
}

clear
main