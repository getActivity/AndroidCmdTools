#!/bin/bash
# ----------------------------------------------------------------------
#     author   : Android 轮子哥
#     github   : https://github.com/getActivity/AndroidCmdTools
#      time    : 2026/01/25
#      desc    : 刷写恢复分区脚本（fastboot flash recovery）
# ----------------------------------------------------------------------
scriptDirPath=$(dirname "${BASH_SOURCE[0]}")
originalDirPath=$PWD
cd "${scriptDirPath}" || exit 1
source "../../common/SystemPlatform.sh" && \
source "../../common/FileTools.sh" && \
source "../../common/EnvironmentTools.sh" && \
source "../../business/DevicesSelector.sh" || exit 1
cd "${originalDirPath}" || exit 1
unset scriptDirPath
unset originalDirPath

flashRecoveryForDevice() {
    fastbootDeviceList=()
    fastbootDeviceIdsString=$(getFastbootDeviceIdsString)
    while read -r fastbootDeviceId; do
        fastbootDeviceList+=("${fastbootDeviceId}")
    done < <(echo "${fastbootDeviceIdsString}" | tr -d '\r')
    fastbootDeviceCount=${#fastbootDeviceList[@]}

    if (( fastbootDeviceCount > 1 )); then
        echo "❌ 当前操作仅支持单设备操作，请断开多余设备后重试"
        exit 1
    fi

    echo "请输入要刷入 recovery 包的路径："
    read -r recoveryFilePath
    recoveryFilePath=$(parseComputerFilePath "${recoveryFilePath}")

    if [[ ! -f "${recoveryFilePath}" ]]; then
        echo "❌ 文件不存在，请检查 ${recoveryFilePath} 文件路径是否正确"
        return 1
    fi

    if [[ ! "${recoveryFilePath}" =~ \.([Ii][Mm][Gg])$ ]]; then
        echo "❌ 文件错误，只接受文件名后缀为 img 的文件"
        exit 1
    fi

    echo "这是一个危险操作，你确定要给设备刷入新的 recovery ？（y/n）"
    read -r flashConfirm

    if [[ "${flashConfirm}" =~ ^[nN]$ ]]; then
        echo "✅ 用户手动取消操作"
        return 0
    elif [[ ! "${flashConfirm}" =~ ^[yY]$ ]]; then
        echo "❌ 无效选择，已取消操作"
        return 1
    fi

    echo "⏳ 正在刷入 recovery 文件，过程可能会比较慢，请耐心等待 5 ~ 10 分钟"
    outputPrint=$(fastboot flash recovery "${recoveryFilePath}" < /dev/null 2>&1)
    exitCode=$?
    if (( exitCode == 0 )); then
       echo "✅ 刷入 recovery 成功"
       fastboot reboot recovery < /dev/null
    else
       echo "✅ 刷入 recovery 失败，原因如下："
       echo "${outputPrint}"
    fi
}

main() {
    printCurrentSystemType
    checkFastbootEnvironment
    flashRecoveryForDevice
}

clear
main