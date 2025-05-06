

default:
    @just -l

LOCALDIR := `sh -c 'pwd'`
RUNTIME := `sh -c "if [ \"\$(kubectl get nodes --no-headers | awk '{print \$1}')\" = 'orbstack' ]; then echo orbstack; else echo docker-desktop; fi"`

# Optional parameters: smb_user, smb_pass, smb_port
install_local_smb_server local_volume_path="./smb-volume" smb_user="smbuser" smb_pass="mypass" smb_port="30445":
    #!/bin/bash

    local_volume_path="{{ local_volume_path }}"
    mkdir -p ${local_volume_path}
    volume_paths=($local_volume_path)
    # Check if the SMB server is already running
    if kubectl get pods --no-headers | grep smb-server | awk '{print $3}' | grep -q "Running"; then
        echo "SMB server is already running. Exiting..."
        exit 0
    fi

    # Split the paths into an array
    #IFS=';' read -r -A volume_path_array <<< "${volume_paths}"
    volume_path_array=${volume_paths}
    SMB_SHARES=""
    VOLUME_MOUNTS=""
    VOLUMES=""

    for volume_path in "${volume_path_array[@]}"; do
        # Determine if path is absolute or relative
        if [[ "$volume_path" = /* ]]; then
            SMB_PATH="$volume_path"
        else
            SMB_PATH="{{ LOCALDIR }}/$volume_path"
        fi

        SMB_SHARE_NAME=$(basename "$SMB_PATH")

        SMB_SHARES="${SMB_SHARES}
              - \"-s\"
              - ${SMB_SHARE_NAME};/${SMB_SHARE_NAME};yes;no;no;all;none"

        VOLUME_MOUNTS="${VOLUME_MOUNTS}
              - mountPath: /${SMB_SHARE_NAME}
                name: ${SMB_SHARE_NAME}"

        VOLUMES="${VOLUMES}
            - name: ${SMB_SHARE_NAME}
              hostPath:
                path: ${SMB_PATH}
                type: DirectoryOrCreate"
    done

    # Trim leading newlines (but keep indentation intact)
    SMB_SHARES=$(echo "$SMB_SHARES" | sed '1d')
    VOLUME_MOUNTS=$(echo "$VOLUME_MOUNTS" | sed '1d')
    VOLUMES=$(echo "$VOLUMES" | sed '1d')

    echo "Deploying Samba to Kubernetes with paths: ${volume_paths}"
    echo "SMB credentials: user={{ smb_user }}, pass={{ smb_pass }}"
    echo "NodePort: {{ smb_port }}"

    # Create or update the secret named 'smbcreds'
    kubectl delete secret smbcreds --ignore-not-found=true
    kubectl create secret generic smbcreds \
    --from-literal username="{{ smb_user }}" \
    --from-literal password="{{ smb_pass }}"

    # Export environment variables for envsubst
    export SMB_SHARES
    export VOLUME_MOUNTS
    export VOLUMES
    export SMB_445_NODE_PORT="{{ smb_port }}"

    # Apply the YAML that uses $SMB_SHARES, $VOLUME_MOUNTS, and $VOLUMES
    envsubst '$SMB_SHARES $VOLUME_MOUNTS $VOLUMES $SMB_445_NODE_PORT' < smb-server/smb-server-deployment.yaml | kubectl apply -f -

    # Check if the SMB server is running
    for i in {1..3}; do
        if kubectl get deployment smb-server &> /dev/null; then
            echo "SMB server is running."
            break
        else
            echo "Waiting for SMB server to start... ($i/3)"
            sleep 3
        fi
    done

    if ! kubectl get deployment smb-server &> /dev/null; then
        echo "SMB server failed to start after 3 attempts. Exiting..."
        exit 1
    fi

    echo "SMB server is up and running."


uninstall_local_smb_server:
    #!/bin/zsh
    echo "Deleting Samba Deployment/Service/Secret..."
    kubectl delete deployment smb-server --ignore-not-found=true
    kubectl delete service smb-server --ignore-not-found=true
    kubectl delete secret smbcreds --ignore-not-found=true


install_azurite:
    #!/bin/bash
    cd azurite
    kubectl apply -f azurite-k8s.yaml || true

uninstall_azurite:
    #!/bin/bash
    cd azurite
    kubectl delete -f azurite-k8s.yaml --ignore-not-found || true


install_events FS_URL="default" CLOUD_PROVIDER="AZURE" LISTENER_MODE="default":
    #!/bin/bash
    FS_URL="{{ FS_URL }}"

    LISTENER_MODE="{{ LISTENER_MODE }}"
    if [[ "${LISTENER_MODE}" == "SMB" ]]; then
        SMB_URL="{{FS_URL}}"
        echo "Received SMB_URL: $SMB_URL"
        LISTENER_COMPONENT="function-smblistener-js"
    elif [[ "${LISTENER_MODE}" == "FPOLICY" ]]; then
        FSEVENTS_SERVER_MODE="fpolicy"
        LISTENER_COMPONENT="fs-events-server"
    elif [[ "${LISTENER_MODE}" == "LOCAL" ]]; then
        FSEVENTS_SERVER_MODE="local"
        FSEVENTS_LOCAL_DIR="{{FS_URL}}"
        LISTENER_COMPONENT="fs-events-server"
    fi

    components+=("${LISTENER_COMPONENT}" "function-event-distributor" "function-imageresize" "function-preprocess")

    # TODO: Install events

uninstall_events:
    #!/bin/bash
    echo "todo uninstall events"

install_genai FS_URL="default" CLOUD_PROVIDER="AZURE" FS_PROTOCOL="smb" MOUNT_VOLUMES="./smb-volume":
    #!/bin/bash

    # Add helm repositories if missing.
    if ! helm repo list | grep -q 'keycloak'; then
        helm repo add keycloak https://codecentric.github.io/helm-charts
    fi

    if ! helm repo list | grep -q 'searxng'; then
        helm repo add searxng https://charts.searxng.org
    fi

    # Install SMB CSI driver if missing.
    if ! helm list -n kube-system | grep -q 'csi-driver-smb'; then
        helm repo add csi-driver-smb https://raw.githubusercontent.com/kubernetes-csi/csi-driver-smb/master/charts
        helm install csi-driver-smb csi-driver-smb/csi-driver-smb --namespace kube-system --version v1.16.0
    fi

    missing_deps=$(helm dependency list genai-toolkit-helmcharts | grep missing)
    if [ -n "${missing_deps}" ]; then
        helm dependency build genai-toolkit-helmcharts
    fi

    # Retrieve parameter values (these may be provided by Just’s templating).
    FS_URL="{{ FS_URL }}"
    CLOUD_PROVIDER="{{ CLOUD_PROVIDER }}"
    apiv2_secret_store="kubernetes"
    volumes="{{ MOUNT_VOLUMES }}"

    IFS=';' read -r -a share_names <<< "$volumes"

    # Determine RUNTIME-dependent variables.
    RUNTIME="{{ RUNTIME }}"
    if [ "${RUNTIME}" = "orbstack" ]; then
        node_ip="$(kubectl get nodes -o wide --no-headers | head -n1 | awk '{print $6}')"
    else
        node_ip="localhost"
    fi
    if [ "${RUNTIME}" = "orbstack" ]; then
        smb_port="$(kubectl get svc smb-server -o jsonpath='{.spec.ports[?(@.name=="smb-server")].nodePort}')"
    else
        smb_port="445"
    fi

    FS_PROTOCOL="{{ FS_PROTOCOL }}"
    MOUNT_VOLUMES="{{ MOUNT_VOLUMES }}"

    # Process FS_URL to prepare volume mount strings.
    if [[ $FS_URL == smb:* ]]; then
        FS_PROTOCOL="smb"
        connection_strings="{{ FS_URL }}"
    elif [[ $FS_URL == default ]]; then
        FS_PROTOCOL="smb"
        connection_strings=""
        smb_user="smbuser"
        smb_pass="mypass"

        for share_name in "${share_names[@]}"; do
            # Build connection string using shell variables.
            connection_string="smb://${smb_user}:${smb_pass}@${node_ip}:${smb_port}/$(basename "$share_name")?sec=ntlmssp"
            if [ -z "$connection_strings" ]; then
                connection_strings="$connection_string"
            else
                connection_strings="$connection_strings;$connection_string"
            fi
        done
    elif [[ $FS_URL == nfs:* ]]; then
        FS_PROTOCOL="nfs"
        # translate nfs://1.2.3.4/export1 to 1.2.3.4:/export1
        converted_mount_volumes=$(echo "$MOUNT_VOLUMES" | sed -e 's|nfs://||' -e 's|/|:|')
        MOUNT_VOLUMES="$converted_mount_volumes"
    fi

    echo "FS Protocol is ${FS_PROTOCOL}"

    HELM_SET_FLAGS="apiv2.secretStore=\"${apiv2_secret_store}\""
    HELM_SET_FLAGS="${HELM_SET_FLAGS},apiv2.cloudEnv=\"$CLOUD_PROVIDER\""
    if [ -n "${MOUNT_VOLUMES}" ]; then
        if [ "$FS_PROTOCOL" = "nfs" ]; then
            HELM_SET_FLAGS="${HELM_SET_FLAGS},nfs.volumes=\"$MOUNT_VOLUMES\""
        else
            HELM_SET_FLAGS="${HELM_SET_FLAGS},smbVolumes=\"$connection_strings\""
        fi
    fi

    echo "HELM_SET_FLAGS: ${HELM_SET_FLAGS}"

    # Perform the helm upgrade/install (ensure the chart reference is correct).
    helm upgrade --install genai-toolkit genai-toolkit-helmcharts --set-json "${HELM_SET_FLAGS}"

uninstall_genai:
    helm uninstall genai-toolkit || true

install FS_URL="default" CLOUD_PROVIDER="AZURE" MOUNT_VOLUMES="" LISTENER_MODE="default":
    #!/bin/bash
    FS_URL="{{ FS_URL }}"
    CLOUD_PROVIDER="{{ CLOUD_PROVIDER }}"
    MOUNT_VOLUMES="{{ MOUNT_VOLUMES }}"
    LISTENER_MODE="{{ LISTENER_MODE }}"

    if [[ "${FS_URL}" == "default" ]]; then
        echo "FS_URL is default -- assuming local emulated setup"
        if [[ "${CLOUD_PROVIDER}" == "AZURE" ]]; then
            just install_azurite
        fi
        just install_local_smb_server
    fi

    just install_genai "${FS_URL}" "${CLOUD_PROVIDER}" "${MOUNT_VOLUMES}"
    just install_events "${FS_URL}" "${CLOUD_PROVIDER}" "${LISTENER_MODE}"

install_nfs_local MOUNT_VOLUMES="":
    #!/bin/bash
    MOUNT_VOLUMES="{{ MOUNT_VOLUMES }}"

    HELM_SET_FLAGS="cloudProvider=local"
    HELM_SET_FLAGS="${HELM_SET_FLAGS},localVolumePaths=\"${MOUNT_VOLUMES}\""

    echo "Using HELM_SET_FLAGS: ${HELM_SET_FLAGS}"

    helm upgrade --install genai-toolkit genai-toolkit-helmcharts --set "${HELM_SET_FLAGS}"

uninstall:
    #!/bin/bash
    just uninstall_genai
    just uninstall_azurite
    just uninstall_local_smb_server
    just uninstall_events

uninstall_nfs_local:
    #!/bin/bash
    helm uninstall genai-toolkit || true

