

default:
    @just -l

LOCALDIR := `sh -c 'pwd'`
RUNTIME := `sh -c "if [ \"\$(kubectl get nodes --no-headers | awk '{print \$1}')\" = 'orbstack' ]; then echo orbstack; else echo docker-desktop; fi"`

check_requirements:
    #!/bin/bash
    if ! command -v kubectl 2>&1 > /dev/null; then
        echo "please install kubectl"
        echo "  e.g. brew install kubernetes-cli"
        exit 1
    fi
    if ! command -v helm 2>&1 > /dev/null; then
        echo "please install helm"
        echo "  e.g. brew install helm"
        exit 1
    fi
    if ! command -v jq 2>&1 > /dev/null; then
        echo "please install jq"
        echo "  e.g. brew install jq"
        exit 1
    fi
        if ! command -v yq 2>&1 > /dev/null; then
        echo "please install yq"
        echo "  e.g. brew install yq"
        exit 1
    fi
    if ! command -v envsubst 2>&1 > /dev/null; then
        echo "please install gettext/envsubst"
        echo "  e.g. brew install gettext"
        exit 1
    fi


# Optional parameters: smb_user, smb_pass, smb_port
install_local_smb_server local_volume_paths="default" smb_user="smbuser" smb_pass="mypass" smb_port="30445": check_requirements
    #!/bin/bash
    set -e
    smb_user="{{ smb_user }}"
    smb_pass="{{ smb_pass }}"
    smb_port="{{ smb_port }}"
    config_json=$(kubectl get configmap genai-config -o yaml | yq -r '.data."config.yaml"' | yq -o json)
    local_volume_paths=$(echo ${config_json} | jq -c -r '[.volumes[] | select(.access[].protocol=="smb") | .access[].localPath] | join(",")')

    if [ "${local_volume_paths}" != "" ]; then

        # Split the paths into an array
        IFS=',' read -r -a volume_path_array <<< "${local_volume_paths}"

        # Check if the SMB server is already running
        if kubectl get pods --no-headers | grep smb-server | awk '{print $3}' | grep -q "Running"; then
            echo "SMB server is already running. Exiting..."
            exit 0
        fi

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

            SMB_SHARE_NAME_UPPER=$(basename "$SMB_PATH")
            SMB_SHARE_NAME=$(echo ${SMB_SHARE_NAME_UPPER} | tr '[:upper:]' '[:lower:]')

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
        echo "SMB credentials: user=${smb_user}, pass=${smb_pass}"
        echo "NodePort: ${smb_port}"

        # # Create or update the secret named 'smbcreds'
        # kubectl delete secret smbcreds --ignore-not-found=true
        # kubectl create secret generic smbcreds \
        #     --from-literal username="{{ smb_user }}" \
        #     --from-literal password="{{ smb_pass }}"

        # Export environment variables for envsubst
        export SMB_SHARES
        export VOLUME_MOUNTS
        export VOLUMES
        export SMB_445_NODE_PORT="${smb_port}"

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
    else
        echo "No local volumes found - skipping local smb server"
    fi


uninstall_local_smb_server:
    #!/bin/zsh
    echo "Deleting Samba Deployment/Service/Secret..."
    kubectl delete deployment smb-server --ignore-not-found=true
    kubectl delete service smb-server --ignore-not-found=true
    kubectl delete secret smbcreds --ignore-not-found=true


install_azurite: check_requirements
    #!/bin/bash
    cd azurite
    kubectl apply -f azurite-k8s.yaml || true

uninstall_azurite:
    #!/bin/bash
    cd azurite
    kubectl delete -f azurite-k8s.yaml --ignore-not-found || true

install_events FS_URLS="default" CLOUD_PROVIDER="AZURE": check_requirements
    #!/bin/bash

    CLOUD_PROVIDER="{{ CLOUD_PROVIDER }}"
    FS_URLS="{{ FS_URLS }}"

    just install_smb_listener "${FS_URLS}" "${CLOUD_PROVIDER}"
    just install_event_distributor "${FS_URLS}" "${CLOUD_PROVIDER}"


install_event_distributor FS_URLS="default" CLOUD_PROVIDER="AZURE": check_requirements
    #!/bin/bash
    set -e

    CLOUD_PROVIDER="{{ CLOUD_PROVIDER }}"
    FS_URLS="{{ FS_URLS }}"

    #HELM_SET_FLAGS="cloudProvider=\"$CLOUD_PROVIDER\""

    echo ""
    echo "===== Installing helm chart for event-distributor ====="
    #helm upgrade --install event-distributor event-distributor --set-json ${HELM_SET_FLAGS}
    helm upgrade --install event-distributor event-distributor
    echo "=================================================="
    echo ""



install_smb_listener FS_URLS="default" CLOUD_PROVIDER="AZURE": check_requirements
    #!/bin/bash
    set -e

    CLOUD_PROVIDER="{{ CLOUD_PROVIDER }}"
    FS_URLS="{{ FS_URLS }}"

    SMB_URLS="[]"

    config_json=$(kubectl get configmap genai-config -o yaml | yq -r '.data."config.yaml"' | yq -o json)
    SMB_URLS=$(echo ${config_json} | jq -c '.volumes[] | select(.access[].protocol=="smb") | .access[].url' | jq -s | tr -d "\n\r" | tr -d '[:blank:]' )
    if [ "${SMB_URLS}" != "[]" ]; then
        HELM_SET_FLAGS="cloudProvider=\"$CLOUD_PROVIDER\""
        if [ -n "${SMB_URLS}" ]; then
            HELM_SET_FLAGS="${HELM_SET_FLAGS},smb.urls=${SMB_URLS}"
        fi
        if [ -n "${SMB_LISTENER_RETRIES}" ]; then
        HELM_SET_FLAGS="${HELM_SET_FLAGS},smb.listenerRetries=\"${SMB_LISTENER_RETRIES}\""
        fi
        if [ -n "${AzureWebJobsStorage}" ]; then
        HELM_SET_FLAGS="${HELM_SET_FLAGS},azure.aqsConnectionString=\"${AzureWebJobsStorage}\""
        fi
        if [ -n "${AWS_REGION}" ]; then
        HELM_SET_FLAGS="${HELM_SET_FLAGS},aws.region=\"${AWS_REGION}\""
        fi
        if [ -n "${SQS_QUEUE_URL}" ]; then
        HELM_SET_FLAGS="${HELM_SET_FLAGS},aws.sqsQueueUrl=\"${SQS_QUEUE_URL}\""
        fi
        if [ -n "${SQS_MESSAGE_GROUP_ID}" ]; then
        HELM_SET_FLAGS="${HELM_SET_FLAGS},aws.sqsMessageGroupId=\"${SQS_MESSAGE_GROUP_ID}\""
        fi
        if [ -n "${NATS_URL}" ]; then
        HELM_SET_FLAGS="${HELM_SET_FLAGS},nats.url=\"${NATS_URL}\""
        fi
        if [ -n "${NATS_SUBJECT}" ]; then
        HELM_SET_FLAGS="${HELM_SET_FLAGS},nats.subject=\"${NATS_SUBJECT}\""
        fi

        echo ""
        echo "===== Installing helm chart for smb-listener ====="
        helm upgrade --install smb-listener smb-listener --set-json ${HELM_SET_FLAGS}
        echo "=================================================="
        echo ""

    else
        echo "no SMB volumes founds, skipping smb-listener"
    fi
    
uninstall_events:
    #!/bin/bash
    helm uninstall smb-listener || true
    helm uninstall event-distributor || true
    echo "done uninstalling events"

install_genai FS_URLS="default" CLOUD_PROVIDER="AZURE": check_requirements
    #!/bin/bash
    set -e

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
        helm repo update
        helm install csi-driver-smb csi-driver-smb/csi-driver-smb --namespace kube-system --version v1.16.0
    else
      echo "csi-driver-smb already installed - if you have problems with containers using the driver, try uninstalling the csi smb driver and allowing this chart to install"
    fi

    missing_deps=$(helm dependency list genai-toolkit-helmcharts | grep missing || true)
    if [ -n "${missing_deps}" ]; then
        helm dependency build genai-toolkit-helmcharts
    fi

    # Retrieve parameter values (these may be provided by Just’s templating).
    CLOUD_PROVIDER="{{ CLOUD_PROVIDER }}"
    apiv2_secret_store="kubernetes"
    volumes=""

    IFS=';' read -r -a share_names <<< "$volumes"

    # Determine RUNTIME-dependent variables.
    # RUNTIME="{{ RUNTIME }}"
    # if [ "${RUNTIME}" = "orbstack" ]; then
    #     node_ip="$(kubectl get nodes -o wide --no-headers | head -n1 | awk '{print $6}')"
    # else
    #     node_ip="localhost"
    # fi

    FS_URLS="{{ FS_URLS }}"
    FS_PROTOCOL="smb"

    FS_PROTOCOL="smb"
    config_json=$(kubectl get configmap genai-config -o yaml | yq -r '.data."config.yaml"' | yq -o json)
    nfs_connection_strings=$(echo ${config_json} | jq -c -r '[.volumes[] | select(.access[].protocol=="nfs") | .access[].connectionString] | join(";")')
    smb_connection_strings=$(echo ${config_json} | jq -c -r '[.volumes[] | select(.access[].protocol=="smb") | .access[].connectionString] | join(";")')

    volume_urls=$(echo ${config_json} | jq -c -r '[.volumes[] | .access[].url] | join(";")')
    volume_names=$(echo ${config_json} | jq -c -r '[.volumes[] | .name] | join(";")')
    IFS=';' read -r -a volume_urls_array <<< "$volume_urls"
    IFS=';' read -r -a volume_names_array <<< "$volume_names"

    # Calculate the volume mappings
    i=0
    volumeMapping=""
    for fs_url in "${volume_urls[@]}"; do
        vol_name=${volume_names[$i]}
        vol_path="/ontap/${vol_name}"
        volumeMapping="${volumeMapping}${fs_url};${vol_path}__"
        i=$((i+1))
    done


    HELM_SET_FLAGS="apiv2.secretStore=\"${apiv2_secret_store}\""
    #HELM_SET_FLAGS="${HELM_SET_FLAGS},apiv2.cloudEnv=\"$CLOUD_PROVIDER\""
    if [ -n "${nfs_connection_strings}" ]; then
        HELM_SET_FLAGS="${HELM_SET_FLAGS},nfs.volumes=\"$nfs_connection_strings\""
    fi
    if [ -n "${smb_connection_strings}" ]; then
        HELM_SET_FLAGS="${HELM_SET_FLAGS},smb.volumes=\"$smb_connection_strings\""
    fi
    if [ -n "${volumeMapping}" ]; then
        HELM_SET_FLAGS="${HELM_SET_FLAGS},apiv2.volumeMapping=\"$volumeMapping\""
    fi

    # Perform the helm upgrade/install (ensure the chart reference is correct).
    echo ""
    echo "===== Installing helm chart for genai-toolkit ====="
    helm upgrade --install genai-toolkit genai-toolkit-helmcharts --set-json "${HELM_SET_FLAGS}"
    echo "==================================================="
    echo ""

uninstall_genai:
    helm uninstall genai-toolkit || true

install FS_URLS="default" CLOUD_PROVIDER="AZURE": check_requirements
    #!/bin/bash
    FS_URLS="{{ FS_URLS }}"
    CLOUD_PROVIDER="{{ CLOUD_PROVIDER }}"
    just configure "${FS_URLS}" "${CLOUD_PROVIDER}"

    config_json=$(kubectl get configmap genai-config -o yaml | yq -r '.data."config.yaml"' | yq -o json)
    IS_LOCAL=$(echo ${config_json} | jq -r .isLocal)

    if [ "${IS_LOCAL}" == "true" ]; then
        just install_local_smb_server
    fi
    # For now always installing azurite
    if [[ "${CLOUD_PROVIDER}" == "AZURE" ]]; then
        just install_azurite
    fi

    just install_genai "${FS_URLS}" "${CLOUD_PROVIDER}"
    just install_events "${FS_URLS}" "${CLOUD_PROVIDER}"


configure FS_URLS="default" CLOUD_PROVIDER="AZURE": check_requirements
    #!/bin/bash
    set -e
    # Setting up configmap with config
    # auto populating if not present
    FS_URLS="{{ FS_URLS }}"
    LOCALDIR="{{ LOCALDIR }}"
    # Process FS_URLS to prepare volume config.
    CONFIG_FILE="$(pwd)/config.yaml"
    CONFIG_MAP_EXISTS=0
    CONFIG_FILE_EXISTS=0

    if kubectl get configmap genai-config 2>&1 > /dev/null; then
        CONFIG_MAP_EXISTS=1
    fi
    if [ -e "${CONFIG_FILE}" ]; then
        CONFIG_FILE_EXISTS=1
    fi

    if [ ${CONFIG_FILE_EXISTS} -eq 0 ] && [ ${CONFIG_MAP_EXISTS} -eq 0 ]; then
        CONFIG_FILE_ORIG="${CONFIG_FILE}"
        CONFIG_FILE="${CONFIG_FILE_ORIG}.json"
        echo "config file does not exist - creating it"
        IS_LOCAL="true"

        if [[ "${FS_URLS}" == "default" ]]; then
            FS_URLS="smb-volume"
            echo "FS_URL is default -- assuming local emulated setup"
            echo ""
            echo " Adding one smb volume with name ${FS_URLS}"
            echo ""
            IS_LOCAL="true"
        else
            if [[ "${FS_URLS}" == smb:* ]]; then
                # assuming non local for smb urls
                IS_LOCAL="false"
            elif [[ "${FS_URLS}" == nfs:* ]]; then
                # assuming non local for nfs urls
                IS_LOCAL="false"
            fi
            IFS=',' read -r -a fs_urls_array <<< "$FS_URLS"
            for fs_url in "${fs_urls_array[@]}"; do
                echo "Adding FS URL : $fs_url"
            done
        fi
        echo -e "{\"isLocal\": ${IS_LOCAL},\n\"volumes\": [" >> ${CONFIG_FILE}
        IFS=',' read -r -a fs_urls_array <<< "$FS_URLS"
        IS_FIRST=1
        for FS_URL in "${fs_urls_array[@]}"; do
            absolute_local_path=""
            if [[ $FS_URL == nfs:* ]]; then
                echo "found nfs url, skipping prep"
            elif [[ $FS_URL == smb:* ]]; then
                echo "found smb url, skipping prep"
            else
                if [[ $FS_URL == local:* ]]; then
                    local_path=$(echo "${FS_URL}" | sed -e 's|local://||' -e 's|/|:|')
                else
                    local_path="${FS_URL}"
                fi
                # Determine if path is absolute or relative
                if [[ "$local_path" = /* ]]; then
                    absolute_local_path="$local_path"
                else
                    absolute_local_path="${LOCALDIR}/$local_path"
                fi
                if [ ! -e "${absolute_local_path}" ]; then
                    echo "Path: ${absolute_local_path} not found, creating"
                    mkdir -p ${absolute_local_path}
                fi

                share_name_upper=$(basename "$absolute_local_path")
                share_name=$(echo ${share_name_upper} | tr '[:upper:]' '[:lower:]')
                #TODO move these settings to global config
                smb_user="smbuser"
                smb_pass="mypass"
                default_smb_port="445"
                smb_server="smb-server.default.svc.cluster.local"
                smb_port="${default_smb_port}"
                smb_port_if_any_with_colon=""
                #if [ "${RUNTIME}" = "orbstack" ]; then
                #    smb_port="$(kubectl get svc smb-server -o jsonpath='{.spec.ports[?(@.name=="smb-server")].nodePort}')"
                #else
                #    smb_port="445"
                #fi
                if [ -n "${smb_port}" ]; then
                    if [ "${smb_port}" != "${default_smb_port}" ]; then
                        # skipping adding port if it is default
                        smb_port_if_any_with_colon=":${smb_port}"
                    fi
                fi
                FS_URL="smb://${smb_user}:${smb_pass}@${smb_server}${smb_port_if_any_with_colon}/${share_name}?sec=ntlmssp"
            fi


            proto="$(echo $FS_URL | grep :// | sed -e's,^\(.*://\).*,\1,g')"
            url=$(echo $FS_URL | sed -e s,$proto,,g)
            userpass="$(echo $url | grep @ | cut -d@ -f1)"
            username="$(echo $userpass | awk -F ':' '{print $1}')"
            password="$(echo $userpass | awk -F ':' '{print $2}')"
            hostport=$(echo $url | sed -e s,$userpass@,,g | cut -d/ -f1)
            host="$(echo $hostport | sed -e 's,:.*,,g')"
            port="$(echo $hostport | sed -e 's,^.*:,:,g' -e 's,.*:\([0-9]*\).*,\1,g' -e 's,[^0-9],,g')"
            share_name="$(echo $url | grep / | cut -d/ -f2- | awk -F '?' '{print $1}')"
            FS_PROTOCOL="$(echo $proto | awk -F ':' '{print $1}')"

            if [[ $FS_URL == smb:* ]]; then
                connection_string="//${host}/${share_name}"

                if [ -n "${username}" ] && [ -n "${password}" ]; then
                    # echo "creating smbcreds with username: ${username} and password ${password}"
                    # Create or update the secret named 'smbcreds' for smb volumes
                    kubectl delete secret smbcreds --ignore-not-found=true
                    kubectl create secret generic smbcreds \
                        --from-literal username="${username}" \
                        --from-literal password="${password}"
                fi

            elif [[ $FS_URL == nfs:* ]]; then
                # translate nfs://1.2.3.4/export1 to 1.2.3.4:/export1
                connection_string=$(echo "$FS_URL" | sed -e 's|nfs://||' -e 's|/|:/|')
            fi
            if [ $IS_FIRST -eq 0 ]; then
                echo -e ",\n" >> ${CONFIG_FILE}
            fi
            echo -e "{\n" >> ${CONFIG_FILE}
            echo -e "\"name\": \"${share_name}\",\n" >> ${CONFIG_FILE}
            echo -e "\"access\": [{\n" >> ${CONFIG_FILE}
            echo -e "\"protocol\": \"${FS_PROTOCOL}\",\n" >> ${CONFIG_FILE}
            echo -e "\"url\": \"${FS_URL}\",\n" >> ${CONFIG_FILE}
            echo -e "\"connectionString\": \"${connection_string}\"\n" >> ${CONFIG_FILE}
            if [ "${absolute_local_path}" != "" ]; then
                echo -e ",\"localPath\": \"${absolute_local_path}\"\n" >> ${CONFIG_FILE}
            fi
            echo -e "}]\n" >> ${CONFIG_FILE}
            echo -e "}\n" >> ${CONFIG_FILE}
            IS_FIRST=0
        done
        echo -e "]\n}" >> ${CONFIG_FILE}
        cat ${CONFIG_FILE} | yq -p=json > ${CONFIG_FILE_ORIG}
        rm ${CONFIG_FILE} || true
        CONFIG_FILE=${CONFIG_FILE_ORIG}
    else
        echo "config file already does exist - skipping creating"
    fi
    if [ ${CONFIG_MAP_EXISTS} -eq 0 ]; then
        kubectl create configmap genai-config --from-file=${CONFIG_FILE}
        if [ ${CONFIG_MAP_EXISTS} -eq 0 ]; then
            # only deleting if we created it
            rm ${CONFIG_FILE}
        fi
    else
        echo "config map already exist - skipping creating"
    fi

uninstall:
    #!/bin/bash
    just uninstall_genai
    just uninstall_azurite
    just uninstall_local_smb_server
    just uninstall_events
    kubectl delete secret genai-toolkit-api-key || true
    kubectl delete secret genai-toolkit-realm-secret || true
    kubectl delete configmap genai-config