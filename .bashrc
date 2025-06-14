# Only load Liquid Prompt in interactive shells, not from a script or from scp
test -d ~/liquidprompt || git clone https://github.com/liquidprompt/liquidprompt.git ~/liquidprompt
[[ $- = *i* ]] && source ~/liquidprompt/liquidprompt

if ! pgrep -u "$USER" ssh-agent > /dev/null; then
    ssh-agent -t 1h > "$XDG_RUNTIME_DIR/ssh-agent.env"
fi
if [[ ! "$SSH_AUTH_SOCK" ]]; then
    source "$XDG_RUNTIME_DIR/ssh-agent.env" >/dev/null
fi

alias pbcopy='xclip -sel clip'
alias pbpaste='xclip -o -sel clip'
alias wifiscan="${HOME}/.wifi scan"
alias wificonnect="${HOME}/.wifi connect"
alias gmod="git status | grep modified | awk '{ print \$NF }'"
alias gadd="xargs -n 1 git add"

export EDITOR=vim
export PATH="${HOME}/go/bin:${PATH}"
export PATH="/opt/zig:${PATH}"
export BUILDKIT_PROGRESS="plain"

# ****************************************************************************
# custom package manager
#
# this convoluted series of abstractions are to support two
# primary design goals
# - transparency into dependency version
# - the ability to select an arbitrary version of the dependency at run time
#       $ diff <(JQ_VERSION=1.5 jq --version) <(JQ_VERSION=1.7 jq --version)
#       1c1
#       < jq-1.5
#       ---
#       > jq-1.7
# - this is accomplished by creating shell functions that share the same name
#   as the desired executable.
#       $ type jq
#       jq is a function
#       jq ()
#       {
#         ...
# - the function is "sourced" into the operator's environment
# - the first time the function is called it authors an entrypoint script,
#   validates the version of the executable(as set via env var), downloads
#   the version of the tool specified if not present, then passes all the
#   arguments received by the function TO the executable
# - updates to the version list allow new versions and the ability to run
#   multiple versions of the same tool side by side
# ****************************************************************************
test -d "${HOME}/.local/bin" || mkdir -p "${HOME}/.local/bin"
export PATH="${HOME}/.local/bin:${PATH}"

function make_entrypoint() {
  cat <<EOF
#!/usr/bin/env bash

source "${HOME}/.bashrc"
$@
EOF
}

function validate_version_and_get_tool() {
  # a note on the ${UNPACK} logic
  # tar, by default, will extract files into the current working directory
  # to avoid leaving messes around, or ${UNPACK} logic that moves files around
  # try the -C flag!
  # tar -C "$(dirname ${APP})" -zxf "${APP}"

  test "$#" -eq 2 || {
    echo "function validate_version_and_get_tool() expects 2 arguments" 1>&2
    return 1
  }

  : "${VERSION_LIST?"expected variable \${VERSION_LIST} to be set"}"
  : "${TEST_METHOD?"expected variable \${TEST_METHOD} to be set"}"
  : "${VALID_OUTPUT?"expected variable \${VALID_OUTPUT} to be set"}"
  : "${EXPECTATION?"expected variable \${EXPECTATION} to be set"}"
  : "${UNPACK?"expected variable \${UNPACK} to be set"}"
  : "${!1?"expected variable ${1} to be set, pass the name of the variable that has the path to the versioned tool"}"
  : "${!2?"expected variable ${2} to be set, pass the name of the version variable for the target tool"}"
  : "${URL?"expected variable \${URL} to be set"}"

  # decay the indirection to named variables
  ABSOLUTE_PATH_TO_TOOL="${!1}"
  VERSION="${!2}"

  # fail if the VERSION passed does not meet format EXPECTATION
  test "$(echo "${VERSION}" | ${TEST_METHOD})" = "${VALID_OUTPUT}" || {
    echo "${2} ${EXPECTATION}, received ${VERSION}" 1>&2
    return 1
  }

  # fail if the VERSION passed is not contained within VERSION_LIST
  grep "${VERSION}" <<< "${VERSION_LIST}" -q 2>&1 > /dev/null || {
    echo "${2} '${VERSION}' not found in VERSION_LIST '${VERSION_LIST}'" 1>&2
    echo "${2} '${VERSION}' is invalid" 1>&2
    return 1
  }

  test -e "${ABSOLUTE_PATH_TO_TOOL}" || {
    # create the directory in which the executable will reside
    test -d "$(dirname ${ABSOLUTE_PATH_TO_TOOL})" || mkdir -p "$(dirname ${ABSOLUTE_PATH_TO_TOOL})"

    # download the given URL
    curl -L "$(envsubst <<< "${URL}")" > "${ABSOLUTE_PATH_TO_TOOL}"

    # unpack download
    eval "$(echo "${UNPACK}" | envsubst)"
  }
}

export JQ_VERSION="${JQ_VERSION:-1.7}"
function jq() {
  export JQ="${HOME}/jq/${JQ_VERSION}/jq"
  PATH_JQ="${HOME}/.local/bin/jq"
  test -f "${PATH_JQ}" || make_entrypoint 'jq "$@"' > "${PATH_JQ}"
  test -x "${PATH_JQ}" || chmod +x "${PATH_JQ}"

  VERSION_LIST="1.5 1.6 1.7" \
  EXPECTATION='must be in format of X.Y' \
  TEST_METHOD='tr -d [:alnum:]' \
  VALID_OUTPUT='.' \
  UNPACK='chmod +x "${JQ}"' \
  URL='https://github.com/stedolan/jq/releases/download/jq-${JQ_VERSION}/jq-linux64' \
  validate_version_and_get_tool "JQ" "JQ_VERSION" && "${JQ}" "$@"
}

export YQ_VERSION="${YQ_VERSION:-4.45.1}"
function yq() {
  export YQ="${HOME}/yq/${YQ_VERSION}/yq"
  PATH_YQ="${HOME}/.local/bin/yq"
  test -f "${PATH_YQ}" || make_entrypoint 'yq "$@"' > "${PATH_YQ}"
  test -x "${PATH_YQ}" || chmod +x "${PATH_YQ}"

  VERSION_LIST="4.45.1 4.42.1 4.40.4 4.33.3 4.23.1 4.5.0" \
  EXPECTATION='must be in format of X.Y.Z' \
  TEST_METHOD='tr -d [:alnum:]' \
  VALID_OUTPUT='..' \
  UNPACK='chmod +x "${YQ}"' \
  URL='https://github.com/mikefarah/yq/releases/download/v${YQ_VERSION}/yq_linux_386' \
  validate_version_and_get_tool "YQ" "YQ_VERSION" && "${YQ}" "$@"
}

export KUBECTL_VERSION="${KUBECTL_VERSION:-1.28.0}"
function kubectl() {
  export KUBECTL="${HOME}/kubectl/${KUBECTL_VERSION}/kubectl"
  PATH_KUBECTL="${HOME}/.local/bin/kubectl"
  test -f "${PATH_KUBECTL}" || make_entrypoint 'kubectl "$@"' > "${PATH_KUBECTL}"
  test -x "${PATH_KUBECTL}" || chmod +x "${PATH_KUBECTL}"

  VERSION_LIST="1.22.0 1.23.0 1.24.0 1.25.0 1.26.0 1.27.0 1.28.0" \
  EXPECTATION='must be in format of X.Y.Z' \
  TEST_METHOD='tr -d [:alnum:]' \
  VALID_OUTPUT='..' \
  UNPACK='chmod +x "${KUBECTL}"' \
  URL='https://dl.k8s.io/release/v${KUBECTL_VERSION}/bin/linux/amd64/kubectl' \
  validate_version_and_get_tool "KUBECTL" "KUBECTL_VERSION" && "${KUBECTL}" "$@"
}

export ISTIOCTL_VERSION="${ISTIOCTL_VERSION:-1.21.0}"
function istioctl() {
  export ISTIOCTL="${HOME}/istioctl/${ISTIOCTL_VERSION}/istioctl"
  PATH_ISTIOCTL="${HOME}/.local/bin/istioctl"
  test -f "${PATH_ISTIOCTL}" || make_entrypoint 'istioctl "$@"' > "${PATH_ISTIOCTL}"
  test -x "${PATH_ISTIOCTL}" || chmod +x "${PATH_ISTIOCTL}"

  VERSION_LIST="1.21.0 1.17.2 1.16.4 1.15.7" \
  EXPECTATION='must be in format of X.Y.Z' \
  TEST_METHOD='tr -d [:alnum:]' \
  VALID_OUTPUT='..' \
  UNPACK='tar --directory="$(dirname ${ISTIOCTL})" -xf "${ISTIOCTL}" && mv "$(dirname $(dirname ${ISTIOCTL}))/${ISTIOCTL_VERSION}/istio-${ISTIOCTL_VERSION}/bin/istioctl" "${ISTIOCTL}" && chmod +x "${ISTIOCTL}"' \
  URL='https://github.com/istio/istio/releases/download/${ISTIOCTL_VERSION}/istio-${ISTIOCTL_VERSION}-linux-amd64.tar.gz' \
  validate_version_and_get_tool "ISTIOCTL" "ISTIOCTL_VERSION" && "${ISTIOCTL}" "$@"
}

export TERRAFORM_VERSION="${TERRAFORM_VERSION:-1.8.0}"
function terraform() {
  export TERRAFORM="${HOME}/terraform/${TERRAFORM_VERSION}/terraform"
  PATH_TERRAFORM="${HOME}/.local/bin/terraform"
  test -f "${PATH_TERRAFORM}" || make_entrypoint 'terraform "$@"' > "${PATH_TERRAFORM}"
  test -x "${PATH_TERRAFORM}" || chmod +x "${PATH_TERRAFORM}"

  VERSION_LIST="1.8.0 1.6.6 1.6.2 1.6.1 1.4.6 1.0.11 0.11.8" \
  EXPECTATION='must be in format of X.Y.Z' \
  TEST_METHOD='tr -d [:alnum:]' \
  VALID_OUTPUT='..' \
  UNPACK='unzip -o -d "$(dirname ${TERRAFORM})" "${TERRAFORM}" && chmod +x "${TERRAFORM}"' \
  URL='https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip' \
  validate_version_and_get_tool "TERRAFORM" "TERRAFORM_VERSION" && "${TERRAFORM}" "$@"
}

export MESHCTL_VERSION="${MESHCTL_VERSION:-2.5.4}"
function meshctl() {
  export MESHCTL="${HOME}/meshctl/${MESHCTL_VERSION}/meshctl"
  PATH_MESHCTL="${HOME}/.local/bin/meshctl"
  test -f "${PATH_MESHCTL}" || make_entrypoint 'meshctl "$@"' > "${PATH_MESHCTL}"
  test -x "${PATH_MESHCTL}" || chmod +x "${PATH_MESHCTL}"

  VERSION_LIST="2.5.4 2.5.1 2.3.3 2.3.2 2.3.1 2.3.0 2.2.8 2.2.7 2.2.6 2.2.5 2.2.4 2.2.3 2.2.2 2.2.1 2.2.0" \
  EXPECTATION='must be in format of X.Y.Z' \
  TEST_METHOD='tr -d [:alnum:]' \
  VALID_OUTPUT='..' \
  UNPACK='chmod +x "${MESHCTL}"' \
  URL='https://storage.googleapis.com/meshctl/v${MESHCTL_VERSION}/meshctl-linux-amd64' \
  validate_version_and_get_tool "MESHCTL" "MESHCTL_VERSION" && "${MESHCTL}" "$@"
}

export HELM_VERSION="${HELM_VERSION:-3.12.0}"
function helm() {
  export HELM="${HOME}/helm/${HELM_VERSION}/helm"
  PATH_HELM="${HOME}/.local/bin/helm"
  test -f "${PATH_HELM}" || make_entrypoint 'helm "$@"' > "${PATH_HELM}"
  test -x "${PATH_HELM}" || chmod +x "${PATH_HELM}"

  VERSION_LIST="3.12.0 3.11.3 3.10.3" \
  EXPECTATION='must be in format of X.Y.Z' \
  TEST_METHOD='tr -d [:alnum:]' \
  VALID_OUTPUT='..' \
  UNPACK='tar -zxf "${HELM}" && mv linux-amd64/helm "${HELM}"' \
  URL='https://get.helm.sh/helm-v${HELM_VERSION}-linux-amd64.tar.gz' \
  validate_version_and_get_tool "HELM" "HELM_VERSION" && "${HELM}" "$@"
}

export SPRUCE_VERSION="${SPRUCE_VERSION:-1.30.2}"
function spruce() {
  export SPRUCE="${HOME}/spruce/${SPRUCE_VERSION}/spruce"
  PATH_SPRUCE="${HOME}/.local/bin/spruce"
  test -f "${PATH_SPRUCE}" || make_entrypoint 'spruce "$@"' > "${PATH_SPRUCE}"
  test -x "${PATH_SPRUCE}" || chmod +x "${PATH_SPRUCE}"

  VERSION_LIST="1.31.0 1.30.2 1.29.0 1.25.3" \
  EXPECTATION='must be in format of X.Y.Z' \
  TEST_METHOD='tr -d [:alnum:]' \
  VALID_OUTPUT='..' \
  UNPACK='chmod +x "${SPRUCE}"' \
  URL='https://github.com/geofffranks/spruce/releases/download/v${SPRUCE_VERSION}/spruce-linux-amd64' \
  validate_version_and_get_tool "SPRUCE" "SPRUCE_VERSION" && "${SPRUCE}" "$@"
}

export LOGCLI_VERSION="${LOGCLI_VERSION:-2.8.2}"
function logcli() {
  export LOGCLI="${HOME}/logcli/${LOGCLI_VERSION}/logcli"
  PATH_LOGCLI="${HOME}/.local/bin/logcli"
  test -f "${PATH_LOGCLI}" || make_entrypoint 'logcli "$@"' > "${PATH_LOGCLI}"
  test -x "${PATH_LOGCLI}" || chmod +x "${PATH_LOGCLI}"

  VERSION_LIST="2.8.2 2.7.5" \
  EXPECTATION='must be in format of X.Y.Z' \
  TEST_METHOD='tr -d [:alnum:]' \
  VALID_OUTPUT='..' \
  UNPACK='unzip -o -d "$(dirname ${LOGCLI})" "${LOGCLI}" && mv "$(dirname ${LOGCLI})/logcli-linux-amd64" "${LOGCLI}" && chmod +x "${LOGCLI}"' \
  URL='https://github.com/grafana/loki/releases/download/v${LOGCLI_VERSION}/logcli-linux-amd64.zip' \
  validate_version_and_get_tool "LOGCLI" "LOGCLI_VERSION" && "${LOGCLI}" "$@"
}

export TRIVY_VERSION="${TRIVY_VERSION:-0.60.0}"
function trivy() {
  export TRIVY="${HOME}/trivy/${TRIVY_VERSION}/trivy"
  PATH_TRIVY="${HOME}/.local/bin/trivy"
  test -f "${PATH_TRIVY}" || make_entrypoint 'trivy "$@"' > "${PATH_TRIVY}"
  test -x "${PATH_TRIVY}" || chmod +x "${PATH_TRIVY}"

  VERSION_LIST="0.60.0 0.49.1" \
  EXPECTATION='must be in format of X.Y.Z' \
  TEST_METHOD='tr -d [:alnum:]' \
  VALID_OUTPUT='..' \
  UNPACK='tar -C "$(dirname ${TRIVY})" -zxf "${TRIVY}" && chmod +x "${TRIVY}"' \
  URL='https://github.com/aquasecurity/trivy/releases/download/v${TRIVY_VERSION}/trivy_${TRIVY_VERSION}_Linux-64bit.tar.gz' \
  validate_version_and_get_tool "TRIVY" "TRIVY_VERSION" && "${TRIVY}" "$@"
}

export KUSTOMIZE_VERSION="${KUSTOMIZE_VERSION:-5.4.1}"
function kustomize() {
  export KUSTOMIZE="${HOME}/kustomize/${KUSTOMIZE_VERSION}/kustomize"
  PATH_KUSTOMIZE="${HOME}/.local/bin/kustomize"
  test -f "${PATH_KUSTOMIZE}" || make_entrypoint 'kustomize "$@"' > "${PATH_KUSTOMIZE}"
  test -x "${PATH_KUSTOMIZE}" || chmod +x "${PATH_KUSTOMIZE}"

  VERSION_LIST="5.4.1" \
  EXPECTATION='must be in format of X.Y.Z' \
  TEST_METHOD='tr -d [:alnum:]' \
  VALID_OUTPUT='..' \
  UNPACK='tar -C "$(dirname ${KUSTOMIZE})" -zxf "${KUSTOMIZE}" && chmod +x "${KUSTOMIZE}"' \
  URL='https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize%2Fv${KUSTOMIZE_VERSION}/kustomize_v${KUSTOMIZE_VERSION}_linux_amd64.tar.gz' \
  validate_version_and_get_tool "KUSTOMIZE" "KUSTOMIZE_VERSION" && "${KUSTOMIZE}" "$@"
}

export ARGOCD_VERSION="${ARGOCD_VERSION:-2.11.0}"
function argocd() {
  export ARGOCD="${HOME}/argocd/${ARGOCD_VERSION}/argocd"
  PATH_ARGOCD="${HOME}/.local/bin/argocd"
  test -f "${PATH_ARGOCD}" || make_entrypoint 'argocd "$@"' > "${PATH_ARGOCD}"
  test -x "${PATH_ARGOCD}" || chmod +x "${PATH_ARGOCD}"

  VERSION_LIST="2.11.0" \
  EXPECTATION='must be in format of X.Y.Z' \
  TEST_METHOD='tr -d [:alnum:]' \
  VALID_OUTPUT='..' \
  UNPACK='chmod +x "${ARGOCD}"' \
  URL='https://github.com/argoproj/argo-cd/releases/download/v2.11.0/argocd-linux-amd64' \
  validate_version_and_get_tool "ARGOCD" "ARGOCD_VERSION" && "${ARGOCD}" "$@"
}

export CMCTL_VERSION="${CMCTL_VERSION:-2.1.0}"
function cmctl() {
  export CMCTL="${HOME}/cmctl/${CMCTL_VERSION}/cmctl"
  PATH_CMCTL="${HOME}/.local/bin/cmctl"
  test -f "${PATH_CMCTL}" || make_entrypoint 'cmctl "$@"' > "${PATH_CMCTL}"
  test -x "${PATH_CMCTL}" || chmod +x "${PATH_CMCTL}"

  VERSION_LIST="2.1.0" \
  EXPECTATION='must be in format of X.Y.Z' \
  TEST_METHOD='tr -d [:alnum:]' \
  VALID_OUTPUT='..' \
  UNPACK='chmod +x "${CMCTL}"' \
  URL='https://github.com/cert-manager/cmctl/releases/download/v${CMCTL_VERSION}/cmctl_linux_amd64' \
  validate_version_and_get_tool "CMCTL" "CMCTL_VERSION" && "${CMCTL}" "$@"
}

export GH_VERSION="${GH_VERSION:-2.55.0}"
function gh() {
  export GH="${HOME}/gh/${GH_VERSION}/gh"
  PATH_GH="${HOME}/.local/bin/gh"
  test -f "${PATH_GH}" || make_entrypoint 'gh "$@"' > "${PATH_GH}"
  test -x "${PATH_GH}" || chmod +x "${PATH_GH}"

  VERSION_LIST="2.55.0" \
  EXPECTATION='must be in format of X.Y.Z' \
  TEST_METHOD='tr -d [:alnum:]' \
  VALID_OUTPUT='..' \
  UNPACK='tar -C "$(dirname ${GH})" -zxf "${GH}" && ls -la "${GH}" && cp "$(dirname ${GH})/gh_${GH_VERSION}_linux_amd64/bin/gh" "${GH}" && chmod +x "${GH}"' \
  URL='https://github.com/cli/cli/releases/download/v${GH_VERSION}/gh_${GH_VERSION}_linux_amd64.tar.gz' \
  validate_version_and_get_tool "GH" "GH_VERSION" && "${GH}" "$@"
}

export SNX_RS_VERSION="${SNX_RS_VERSION:-3.1.2}"
function snx-rs() {
  export SNX_RS="${HOME}/snx-rs/${SNX_RS_VERSION}/snx-rs"
  PATH_SNX_RS="${HOME}/.local/bin/snx-rs"
  test -f "${PATH_SNX_RS}" || make_entrypoint 'snx-rs "$@"' > "${PATH_SNX_RS}"
  test -x "${PATH_SNX_RS}" || chmod +x "${PATH_SNX_RS}"

  VERSION_LIST="3.1.2" \
  EXPECTATION='must be in format of X.Y.Z' \
  TEST_METHOD='tr -d [:alnum:]' \
  VALID_OUTPUT='..' \
  UNPACK='tar -C "$(dirname ${SNX_RS})" --xz -xf "${SNX_RS}" && ls -la "${SNX_RS}" && cp "$(dirname ${SNX_RS})/snx-rs-v${SNX_RS_VERSION}-linux-x86_64/snx-rs" "${SNX_RS}" && chmod +x "${SNX_RS}"' \
  URL='https://github.com/ancwrd1/snx-rs/releases/download/v${SNX_RS_VERSION}/snx-rs-v${SNX_RS_VERSION}-linux-x86_64.tar.xz' \
  validate_version_and_get_tool "SNX_RS" "SNX_RS_VERSION" && "${SNX_RS}" "$@"
}

export GRYPE_VERSION="${GRYPE_VERSION:-0.92.0}"
function grype() {
  export GRYPE="${HOME}/grype/${GRYPE_VERSION}/grype"
  PATH_GRYPE="${HOME}/.local/bin/grype"
  test -f "${PATH_GRYPE}" || make_entrypoint 'grype "$@"' > "${PATH_GRYPE}"
  test -x "${PATH_GRYPE}" || chmod +x "${PATH_GRYPE}"

  VERSION_LIST="0.92.0" \
  EXPECTATION='must be in format of X.Y.Z' \
  TEST_METHOD='tr -d [:alnum:]' \
  VALID_OUTPUT='..' \
  UNPACK='tar -C "$(dirname ${GRYPE})" -xzf "${GRYPE}"' \
  URL='https://github.com/anchore/grype/releases/download/v${GRYPE_VERSION}/grype_${GRYPE_VERSION}_linux_amd64.tar.gz' \
  validate_version_and_get_tool "GRYPE" "GRYPE_VERSION" && "${GRYPE}" "$@"
}
