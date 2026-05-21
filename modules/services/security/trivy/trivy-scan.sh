set -euo pipefail

readonly SERVER=@SERVER_ADDR@
readonly SCANNERS=@SCANNERS@
readonly NTFY_SERVER=@NTFY_SERVER@
readonly NTFY_ENABLED=@NTFY_ENABLED@
readonly NTFY_TOPIC=@NTFY_TOPIC@
readonly HOST_NAME=@HOST_NAME@

LOGDIR="/var/log/trivy"
CACHEDIR="/var/cache/trivy"
export TMPDIR="$CACHEDIR/tmp"
mkdir -p "$LOGDIR" "$CACHEDIR" "$TMPDIR"

podman images --digests --format '{{.Repository}}:{{.Tag}}@{{.Digest}}' \
  | grep -v '<none>' | sort -u \
  | while read -r img; do
      slug=$(echo "$img" | tr '/:@' '_')
      echo "Scanning: $img"
      trivy image \
        --server "http://$SERVER" \
        --scanners "$SCANNERS" \
        --severity "CRITICAL,HIGH" \
        --cache-dir "$CACHEDIR" \
        --format json \
        --output "$LOGDIR/$slug.json" \
        "$img" || true
    done

CRITICAL=$(
  jq -r '[.Results[]?.Vulnerabilities[]? | select(.Severity == "CRITICAL")] | length' \
    "$LOGDIR"/*.json 2>/dev/null | awk '{s+=$1} END {print s}'
)
HIGH=$(
  jq -r '[.Results[]?.Vulnerabilities[]? | select(.Severity == "HIGH")] | length' \
    "$LOGDIR"/*.json 2>/dev/null | awk '{s+=$1} END {print s}'
)
: "${CRITICAL:=0}"
: "${HIGH:=0}"

echo "Scan complete: $CRITICAL CRITICAL, $HIGH HIGH findings across all images"

if [ "$CRITICAL" -gt 0 ] || [ "$HIGH" -gt 0 ]; then
  if [ "$NTFY_ENABLED" = "true" ]; then
    SUMMARY="Trivy scan on ${HOST_NAME}: $CRITICAL CRITICAL, $HIGH HIGH vulnerabilities"
    curl --fail --silent --show-error \
      -H "Title: Trivy Alert - ${HOST_NAME}" \
      -H "Priority: high" \
      -H "Tags: warning,skull" \
      -d "$SUMMARY" \
      "https://$NTFY_SERVER/$NTFY_TOPIC" > /dev/null || echo "Failed to send ntfy notification" >&2
  fi
fi
