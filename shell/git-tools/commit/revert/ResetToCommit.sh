#!/bin/bash
# ----------------------------------------------------------------------
#     author   : Android 轮子哥
#     github   : https://github.com/getActivity/AndroidCmdTools
#      time    : 2026/01/25
#      desc    : Git 重置提交脚本
# ----------------------------------------------------------------------
scriptDirPath=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
[ -z "" ] || source "../../../common/SystemPlatform.sh"
source "${scriptDirPath}/../../../common/SystemPlatform.sh"
[ -z "" ] || source "../../../common/EnvironmentTools.sh"
source "${scriptDirPath}/../../../common/EnvironmentTools.sh"
[ -z "" ] || source "../../../common/FileTools.sh"
source "${scriptDirPath}/../../../common/FileTools.sh"
[ -z "" ] || source "../../../business/GitSelector.sh"
source "${scriptDirPath}/../../../business/GitSelector.sh"

main() {
    printCurrentSystemType
    checkGitEnvironment
    set -e

    repositoryDirPath=$(selectLocalRepositoryPath)

    hasChanges=$(cd "${repositoryDirPath}" && [[ -n "$(git status --porcelain)" ]] && echo "1" || echo "0")
    if [[ "${hasChanges}" == "1" ]]; then
        echo "❌ 检测到存在未提交的更改，操作中止"
        exit 1
    fi

    currentBranch=$(cd "${repositoryDirPath}" && git rev-parse --abbrev-ref HEAD < /dev/null 2>/dev/null || echo "")
    origHead=$(cd "${repositoryDirPath}" && git rev-parse HEAD)
    timestamp=$(date "+%Y%m%d%H%M%S")
    backupBranch="${currentBranch}_backup_${timestamp}"
    if [[ -z "${currentBranch}" || "${currentBranch}" == "HEAD" ]]; then
        backupBranch="backup_${timestamp}"
    fi
    echo "请输入要回退到的提交哈希（例如：bd73f02567ecb85ea9e13206e6dcfee5b94b1f91）"
    read -r commitHash
    if [[ -z "${commitHash}" ]]; then
        echo "提交哈希不能为空"
        exit 1
    fi

    targetFullHash=$(cd "${repositoryDirPath}" && git rev-parse --verify "${commitHash}^{commit}" < /dev/null 2>/dev/null || echo "")
    if [[ -z "${targetFullHash}" ]]; then
        echo "❌ 无法解析该提交哈希，请确认输入正确"
        exit 1
    fi

    echo "⏳ 正在创建备份分支：${backupBranch}"
    (cd "${repositoryDirPath}" && git branch -f "${backupBranch}" "${origHead}") 2>&1
    createdHash=$(cd "${repositoryDirPath}" && git rev-parse --verify "${backupBranch}" < /dev/null 2>/dev/null || echo "")
    if [[ -z "${createdHash}" || "${createdHash}" != "${origHead}" ]]; then
        echo "❌ 备份分支创建失败：${backupBranch}"
        exit 1
    fi
    echo "✅ 已创建备份分支 ${backupBranch}，指向提交 ${origHead}"
    (cd "${repositoryDirPath}" && git reset --hard "${targetFullHash}")
    currentHash=$(cd "${repositoryDirPath}" && git rev-parse HEAD)
    if [[ "${currentHash}" != "${targetFullHash}" ]]; then
        echo "❌ 回退失败，当前提交为 ${currentHash}，与目标 ${targetFullHash} 不一致"
        exit 1
    fi

    echo "🤔 回退完成，请确认本次修改是否符合你的预期？"
    echo "1. 是的，符合预期"
    echo "2. 不是，给我改回去"
    while true; do
        read -r resultChoice
        if [[ "${resultChoice}" == "1" ]]; then
            echo "✅ 成功回退到指定的提交上，后续你仍可以用备份分支 ${backupBranch} 找回之前的内容"
            upstreamRef=$(cd "${repositoryDirPath}" && git rev-parse --abbrev-ref --symbolic-full-name @{u} < /dev/null 2>/dev/null || echo "")
            if [[ -n "${upstreamRef}" && -n "${currentBranch}" ]]; then
                aheadBehind=$(cd "${repositoryDirPath}" && git rev-list --left-right --count HEAD..."${upstreamRef}" < /dev/null 2>/dev/null || echo "")
                if [[ -n "${aheadBehind}" ]]; then
                    upstreamOnly=$(echo "${aheadBehind}" | awk '{print $2}')
                    if (( upstreamOnly > 0 )); then
                        echo "💡 远端分支 ${upstreamRef} 比本地分支 ${currentBranch} 新 ${upstreamOnly} 个提交，普通推送将无法成功，请使用强制推送"
                    fi
                fi
            fi
            exit 0
        elif [[ "${resultChoice}" == "2" ]]; then
            (cd "${repositoryDirPath}" && git reset --hard "${origHead}") < /dev/null > /dev/null
            finalHash=$(cd "${repositoryDirPath}" && git rev-parse HEAD)
            if [[ "${finalHash}" == "${origHead}" ]]; then
                (cd "${repositoryDirPath}" && git branch -D "${backupBranch}") < /dev/null > /dev/null || true
                echo "✅ 已经还原到最初的状态，并已删除备份分支 ${backupBranch}"
                exit 0
            else
                echo "❌ 改回失败，但是你仍可以使用备份分支 ${backupBranch} 手动进行恢复"
                exit 1
            fi
        else
            echo "👻 请选择正确的选项编号"
        fi
    done
}

clear
main
