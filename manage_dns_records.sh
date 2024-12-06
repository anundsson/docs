#!/bin/bash

# Function to display usage
function usage() {
  echo "Usage: $0 -t <type> -z <dns-zone> -n <record-name> -d <destination> -a <action> [-g <resource-group>] [-l <ttl>] [-r]"
  echo "  -t <type>: Record type (A or CNAME)"
  echo "  -z <dns-zone>: DNS zone name"
  echo "  -n <record-name>: Record set name"
  echo "  -d <destination>: Destination value (IPv4 address for A, DNS for CNAME)"
  echo "  -a <action>: Action to perform (add, modify, delete)"
  echo "  -g <resource-group>: Resource group name (optional)"
  echo "  -l <ttl>: Time-to-live value (optional, defaults to 3600)"
  echo "  -r: Delete the entire record set (optional, only for delete action)"
  exit 1
}

# Default TTL
TTL="3600"

# Parse arguments
while getopts "t:z:n:d:a:g:l:r" opt; do
  case "$opt" in
    t) TYPE="$OPTARG" ;;
    z) DNS_ZONE="$OPTARG" ;;
    n) RECORD_NAME="$OPTARG" ;;
    d) DESTINATION="$OPTARG" ;;
    a) ACTION="$OPTARG" ;;
    g) RESOURCE_GROUP="$OPTARG" ;;
    l) TTL="$OPTARG" ;;  # TTL is set to the passed value
    r) DELETE_ALL=true ;; # Flag for deleting the entire record set
    *) usage ;;
  esac
done

# Validate inputs
if [ -z "$TYPE" ] || [ -z "$DNS_ZONE" ] || [ -z "$RECORD_NAME" ] || [ -z "$ACTION" ]; then
  echo "Error: Missing required parameters."
  usage
fi

# Validate record type
if [[ "$TYPE" != "A" && "$TYPE" != "CNAME" ]]; then
  echo "Error: Invalid record type. Only 'A' and 'CNAME' are supported."
  exit 1
fi

# Check if record set exists (for modify and delete actions)
record_exists=$(az network private-dns record-set $TYPE list \
  --resource-group "$RESOURCE_GROUP" \
  --zone-name "$DNS_ZONE" \
  --query "[?name=='$RECORD_NAME']" \
  --output tsv)

# Perform action
case "$ACTION" in
  add)
    # Add the A record(s) (multiple destinations supported)
    if [ "$TYPE" = "A" ]; then
      for ip in $DESTINATION; do
        az network private-dns record-set a add-record \
          --resource-group "$RESOURCE_GROUP" \
          --zone-name "$DNS_ZONE" \
          --record-set-name "$RECORD_NAME" \
          --ipv4-address "$ip"
      done
    fi

    # Add the CNAME record(s) (multiple destinations supported)
    if [ "$TYPE" = "CNAME" ]; then
      for cname in $DESTINATION; do
        az network private-dns record-set cname set-record \
          --resource-group "$RESOURCE_GROUP" \
          --zone-name "$DNS_ZONE" \
          --record-set-name "$RECORD_NAME" \
          --cname "$cname"
      done
    fi
    ;;
  
  modify)
    if [ -z "$record_exists" ]; then
      echo "Error: Record set $RECORD_NAME does not exist."
      exit 1
    fi

    # Ensure modify only runs if TTL is provided
    if [ -z "$TTL" ]; then
      echo "Error: TTL is required for modify action."
      exit 1
    fi

    # Modify TTL
    if [ "$TYPE" = "A" ] || [ "$TYPE" = "CNAME" ]; then
      az network private-dns record-set "$TYPE" update \
        --resource-group "$RESOURCE_GROUP" \
        --zone-name "$DNS_ZONE" \
        --name "$RECORD_NAME" \
        --set ttl="$TTL"
    fi
    ;;
  
  delete)
    if [ -z "$record_exists" ]; then
      echo "Error: Record set $RECORD_NAME does not exist."
      exit 1
    fi

    # If the whole record set needs to be deleted
    if [ "$DELETE_ALL" = true ]; then
      # Delete the entire record set
      az network private-dns record-set "$TYPE" delete \
        --resource-group "$RESOURCE_GROUP" \
        --zone-name "$DNS_ZONE" \
        --name "$RECORD_NAME" \
        --yes
    elif [ -z "$DESTINATION" ]; then
      # If -d is not specified, do not delete anything unless -r flag is set for entire record set
      echo "Error: Destination (-d) must be specified for delete action unless -r is used to delete the entire record set."
      exit 1
    else
      # Delete a specific destination (A or CNAME record)
      if [ "$TYPE" = "A" ]; then
        # Delete a specific A record destination
        az network private-dns record-set a remove-record \
          --resource-group "$RESOURCE_GROUP" \
          --zone-name "$DNS_ZONE" \
          --record-set-name "$RECORD_NAME" \
          --ipv4-address "$DESTINATION"
      fi

      if [ "$TYPE" = "CNAME" ]; then
        # Delete a specific CNAME record destination
        az network private-dns record-set cname remove-record \
          --resource-group "$RESOURCE_GROUP" \
          --zone-name "$DNS_ZONE" \
          --record-set-name "$RECORD_NAME" \
          --cname "$DESTINATION"
      fi
    fi
    ;;
  
  *)
    echo "Unsupported action: $ACTION"
    usage
    ;;
esac

echo "Action $ACTION completed successfully for record $RECORD_NAME.$DNS_ZONE of type $TYPE."