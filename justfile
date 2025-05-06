

default:
    @just -l

LOCALDIR := `sh -c 'pwd'`

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
    kubectl delete -f azurite-k8s.yaml || true


install_events FS_URL="default" CLOUD_PROVIDER="AZURE":
    #!/bin/bash
    FS_URL="{{ FS_URL }}"

    LISTENER_MODE="default"
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

    echo "todo install events"

uninstall_events:
    #!/bin/bash
    echo "todo uninstall events"

install_genai FS_URL="default" CLOUD_PROVIDER="AZURE":
    #!/bin/bash
    # SMB csi driver
    if ! helm list -n kube-system | grep -q 'csi-driver-smb'; then
        helm repo add csi-driver-smb https://raw.githubusercontent.com/kubernetes-csi/csi-driver-smb/master/charts
        helm install csi-driver-smb csi-driver-smb/csi-driver-smb --namespace kube-system --version v1.16.0
    fi
    FS_URL="{{ FS_URL }}"
    CLOUD_PROVIDER="{{ CLOUD_PROVIDER }}"
    CLOUD_PROVIDER_LOWER="$(echo "$CLOUD_PROVIDER" | tr '[:upper:]' '[:lower:]')"

    # TODO change default to smb
    FS_PROTOCOL="nfs"
    # TODO remove dummy temporary value
    MOUNT_VOLUMES="1.2.3.4:/export1"
    if [[ $FS_URL == smb:* ]]; then
        FS_PROTOCOL="smb"
        #TODO parse MOUNT_VOLUMES
        #TODO translate smb://smbuser:smbpass@1.2.3.4:30445/smb-volume to //1.2.3.4:30445/smb-volume
        #TODO handle smbcreds
    elif [[ $FS_URL == nfs:* ]]; then
        FS_PROTOCOL="nfs"
        #TODO parse MOUNT_VOLUMES from FS_URL
        #TODO translate nfs://1.2.3.4/export1 to 1.2.3.4:/export1
    fi
    echo "FS Protocol is ${FS_PROTOCOL}"

    # TODO check if cloudProvider should still be anf for azure
    if [[ "${CLOUD_PROVIDER_LOWER}" == "azure" ]]; then
        CLOUD_PROVIDER_LOWER="anf"
    fi
    HELM_SET_FLAGS="cloudProvider=\"$CLOUD_PROVIDER_LOWER\""
    if [ -n "${MOUNT_VOLUMES}" ]; then
        HELM_SET_FLAGS="${HELM_SET_FLAGS},${FS_PROTOCOL}.volumes=\"${MOUNT_VOLUMES}\""
    fi

    helm upgrade --install genai-toolkit genai-toolkit-helmcharts --set-json ${HELM_SET_FLAGS}


uninstall_genai:
    helm uninstall genai-toolkit || true

install FS_URL="default" CLOUD_PROVIDER="AZURE":
    #!/bin/bash
    FS_URL="{{ FS_URL }}"
    CLOUD_PROVIDER="{{ CLOUD_PROVIDER }}"

    if [[ "${FS_URL}" == "default" ]]; then
        echo "FS_URL is default -- assuming local emulated setup"
        if [[ "${CLOUD_PROVIDER}" == "AZURE" ]]; then
            just install_azurite
        fi
        just install_local_smb_server
    fi

    just install_genai "${FS_URL}" "${CLOUD_PROVIDER}"
    just install_events "${FS_URL}" "${CLOUD_PROVIDER}"

uninstall:
    #!/bin/bash
    just uninstall_genai
    just uninstall_azurite
    just uninstall_local_smb_server
    just uninstall_events

