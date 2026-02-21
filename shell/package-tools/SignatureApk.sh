#!/bin/bash
# ----------------------------------------------------------------------
#     author   : Android 轮子哥
#     github   : https://github.com/getActivity/AndroidCmdTools
#      time    : 2026/01/25
#      desc    : Apk 签名脚本（使用 keystore 为 apk 签名）
# ----------------------------------------------------------------------
scriptDirPath=$(dirname "${BASH_SOURCE[0]}")
originalDirPath=$PWD
cd "${scriptDirPath}" || exit 1
source "../common/SystemPlatform.sh" && \
source "../common/EnvironmentTools.sh" && \
source "../common/FileTools.sh" || exit 1
cd "${originalDirPath}" || exit 1
unset scriptDirPath
unset originalDirPath

waitUserInputParameter() {
    local sourcePath=$1
    if [[ -f "${sourcePath}" ]]; then
        sourcePath=$(parseComputerFilePath "${sourcePath}")
    else
        echo "请输入要进行签名的 apk 文件或所在目录路径："
        read -r sourcePath
        sourcePath=$(parseComputerFilePath "${sourcePath}")
    fi
    if [[ -z "${sourcePath}" ]]; then
        echo "❌ 路径为空，请检查输入是否正确"
        exit 1
    fi
    apkFiles=()
    if [[ -d "${sourcePath}" ]]; then
        while IFS= read -r -d '' file; do
            apkFiles+=("${file}")
        done < <(find "${sourcePath}" -maxdepth 1 -type f -name "*.apk" -print0)
        if (( ${#apkFiles[@]} == 0 )); then
            echo "❌ 该目录下没有以 .apk 结尾的文件，签名中止"
            exit 1
        fi
    elif [[ -f "${sourcePath}" ]]; then
        if [[ ! "${sourcePath}" =~ \.(apk)$ ]]; then
            echo "❌ 文件错误，只接受文件名后缀为 apk 的文件"
            exit 1
        fi
        apkFiles+=("${sourcePath}")
    else
        echo "❌ 路径不存在，请检查 ${sourcePath} 是否正确"
        exit 1
    fi

    resourcesDirPath=$(getResourcesDirPath)
    if [[ -z "${resourcesDirPath}" ]]; then
        echo "❌ 未找到 resources 目录，请确保它位于脚本的当前目录或者父目录"
        exit 1
    fi
    echo "资源目录为：${resourcesDirPath}"
    echo "是否使用默认的签名配置进行签名？(y/n)，留空则默认使用"
    read -r oneKeySignature
    if [[ -z "${oneKeySignature}" ]]; then
        oneKeySignature="y"
    fi
    if [[ "${oneKeySignature}" =~ ^[yY]$ ]]; then
        storeFilePath="${resourcesDirPath}$(getFileSeparator)signatureFile$(getFileSeparator)AppSignature.jks"
        apkSignerJarFilePath=""
    else
        echo "请输入 apksigner jar 包的路径（可为空）"
        read -r apkSignerJarFilePath
        apkSignerJarFilePath=$(parseComputerFilePath "${apkSignerJarFilePath}")
        echo "请输入密钥库文件所在路径（建议拖拽文件到此处）"
        read -r storeFilePath
        storeFilePath=$(parseComputerFilePath "${storeFilePath}")
    fi
    configFilePath="${storeFilePath%.*}.txt"
    if [[ -f "${configFilePath}" ]]; then
        sp=$(sed -n 's/^[[:space:]]*storePassword[[:space:]]*=[[:space:]]*//p' "${configFilePath}" | head -n1)
        ka=$(sed -n 's/^[[:space:]]*keyAlias[[:space:]]*=[[:space:]]*//p' "${configFilePath}" | head -n1)
        kp=$(sed -n 's/^[[:space:]]*keyPassword[[:space:]]*=[[:space:]]*//p' "${configFilePath}" | head -n1)
        if [[ -n "${sp}" ]]; then storePassword="${sp}"; fi
        if [[ -n "${ka}" ]]; then keyAlias="${ka}"; fi
        if [[ -n "${kp}" ]]; then keyPassword="${kp}"; fi
    fi
    if [[ -z "${storePassword}" ]]; then
        echo "请输入 storePassword 密码（不能为空）"
        read -r storePassword
    fi
    if [[ -z "${keyAlias}" ]]; then
        echo "请输入 keyAlias 别名（不能为空）"
        read -r keyAlias
    fi
    if [[ -z "${keyPassword}" ]]; then
        echo "请输入 keyPassword 密码（不能为空）"
        read -r keyPassword
    fi
    if [[ -z "${apkSignerJarFilePath}" ]]; then
        apkSignerJarFilePath="${resourcesDirPath}$(getFileSeparator)apksigner-36.0.0.jar"
    fi
    if [[ ! -f "${storeFilePath}" ]]; then
        echo "❌ 密钥库文件不存在，请检查 ${storeFilePath} 文件路径是否正确"
        exit 1
    fi
    if [[ ! -f "${apkSignerJarFilePath}" ]]; then
        echo "❌ 文件不存在，请检查 ${apkSignerJarFilePath} 文件路径是否正确"
        exit 1
    fi
    if [[ ! "${apkSignerJarFilePath}" =~ \.(jar)$ ]]; then
        echo "❌ 文件错误，apksigner 文件名后缀只能是 jar 结尾"
        exit 1
    fi

    echo "签名后是否直接覆盖原文件？（y/n），留空则默认不覆盖"
    while true; do
        read -r overwriteSourceFileConfirm
        if [[ -z "${overwriteSourceFileConfirm}" ]]; then
            overwriteSourceFile="false"
            break
        elif [[ "${overwriteSourceFileConfirm}" =~ ^[yY]$ ]]; then
            overwriteSourceFile="true"
            break
        elif [[ "${overwriteSourceFileConfirm}" =~ ^[nN]$ ]]; then
            overwriteSourceFile="false"
            break
        else
            echo "👻 输入不正确，请输入正确的选项（y/n）"
            continue
        fi
    done

    echo "是否要指定签名方案？（y/n），留空则默认不指定"
    while true; do
        read -r customSigningSchemeConfirm
        if [[ -z "${customSigningSchemeConfirm}" ]]; then
            customSigningScheme="false"
            break
        elif [[ "${customSigningSchemeConfirm}" =~ ^[yY]$ ]]; then
            customSigningScheme="true"
            break
        elif [[ "${customSigningSchemeConfirm}" =~ ^[nN]$ ]]; then
            customSigningScheme="false"
            break
        else
            echo "👻 输入不正确，请输入正确的选项（y/n）"
            continue
        fi
    done

    if [[ "${customSigningScheme}" == "false" ]]; then
        return
    fi

    echo "是否使用 v1 进行签名？（y/n）"
    while true; do
        read -r v1SigningSchemeConfirm
        if [[ "${v1SigningSchemeConfirm}" =~ ^[yY]$ ]]; then
            v1SigningScheme="true"
            break
        elif [[ "${v1SigningSchemeConfirm}" =~ ^[nN]$ ]]; then
            v1SigningScheme="false"
            break
        else
            echo "👻 输入不正确，请输入正确的选项（y/n）"
            continue
        fi
    done

    echo "是否使用 v2 进行签名？（y/n）"
    while true; do
        read -r v2SigningSchemeConfirm
        if [[ "${v2SigningSchemeConfirm}" =~ ^[yY]$ ]]; then
            v2SigningScheme="true"
            break
        elif [[ "${v2SigningSchemeConfirm}" =~ ^[nN]$ ]]; then
            v2SigningScheme="false"
            break
        else
            echo "👻 输入不正确，请输入正确的选项（y/n）"
            continue
        fi
    done

    echo "是否使用 v3 进行签名？（y/n）"
    while true; do
        read -r v3SigningSchemeConfirm
        if [[ "${v3SigningSchemeConfirm}" =~ ^[yY]$ ]]; then
            v3SigningScheme="true"
            break
        elif [[ "${v3SigningSchemeConfirm}" =~ ^[nN]$ ]]; then
            v3SigningScheme="false"
            break
        else
            echo "👻 输入不正确，请输入正确的选项（y/n）"
            continue
        fi
    done

    echo "是否使用 v4 进行签名？（y/n）"
    while true; do
        read -r v4SigningSchemeConfirm
        if [[ "${v4SigningSchemeConfirm}" =~ ^[yY]$ ]]; then
            v4SigningScheme="true"
            break
        elif [[ "${v4SigningSchemeConfirm}" =~ ^[nN]$ ]]; then
            v4SigningScheme="false"
            break
        else
            echo "👻 输入不正确，请输入正确的选项（y/n）"
            continue
        fi
    done
}

signatureSingleApk() {
    local sourceApkFilePath=$1
    local baseName;
    baseName=$(basename "${sourceApkFilePath}")
    local targetApkFilePath
    if [[ "${overwriteSourceFile}" == "true" ]]; then
        targetApkFilePath="${sourceApkFilePath}"
    else
        targetApkFilePath="${sourceApkFilePath%.*}-signed-$(date "+%Y%m%d%H%M%S").${sourceApkFilePath##*.}"
    fi
    echo "⏳ 正在签名 [${baseName}]"
    local outputPrint
    if [[ "${customSigningScheme}" == "true" ]]; then
        outputPrint=$(java -jar "${apkSignerJarFilePath}" sign --v1-signing-enabled "${v1SigningScheme}" --v2-signing-enabled "${v2SigningScheme}" --v3-signing-enabled "${v3SigningScheme}" --v4-signing-enabled "${v4SigningScheme}" --ks "${storeFilePath}" --ks-pass pass:"${storePassword}" --ks-key-alias "${keyAlias}" --key-pass pass:"${keyPassword}" --out "${targetApkFilePath}" "${sourceApkFilePath}" 2>&1)
    else
        outputPrint=$(java -jar "${apkSignerJarFilePath}" sign --ks "${storeFilePath}" --ks-pass pass:"${storePassword}" --ks-key-alias "${keyAlias}" --key-pass pass:"${keyPassword}" --out "${targetApkFilePath}" "${sourceApkFilePath}" 2>&1)
    fi
    local exitCode=$?
    if (( exitCode != 0 )); then
        echo "❌ 签名失败 [${baseName}]，原因如下："
        echo "${outputPrint}"
        return 1
    fi
    if [[ ! -f "${targetApkFilePath}" ]]; then
        echo "❌ 签名 apk 失败 [${baseName}]，文件不存在"
        return 1
    fi
    echo "✅ 签名成功 [${baseName}]，存放路径：${targetApkFilePath}"
    if [[ -f "${targetApkFilePath}.idsig" ]]; then
        rm -f "${targetApkFilePath}.idsig"
    fi
    return 0
}

signatureApkInParallel() {
    if (( ${#apkFiles[@]} > 1 )); then
        echo "⏳ 开始并行签名 ${#apkFiles[@]} 个 apk..."
    fi
    local successCount=0
    local failCount=0
    local pids=()
    for apkFile in "${apkFiles[@]}"; do
        signatureSingleApk "${apkFile}" &
        pids+=($!)
    done
    for i in "${!pids[@]}"; do
        if wait "${pids[${i}]}"; then
            ((successCount++))
        else
            ((failCount++))
        fi
    done
    if (( ${#apkFiles[@]} > 1 )); then
        echo "📋 批量签名任务完成，成功 ${successCount} 个，失败 ${failCount} 个"
    fi
    exit 0
}

main() {
    printCurrentSystemType
    checkJavaEnvironment
    waitUserInputParameter "$1"
    signatureApkInParallel
}

clear
main "$@"