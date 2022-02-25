Param(
  [string]$LOG_PATH = "${PWD}\logs",
  [string]$LOG_PEFIX = "docker",
  [string]$LOG_SUFFIX = ".log",
  [string]$TAG = "jdk11-ubuntu",
  [string]$FILE = "Dockerfile",
  [string]$FUNCTIONS_URI = "https://github.com/aem-design/aemdesign-docker/releases/latest/download/functions.ps1",
  [string]$COMMAND = "docker buildx build . -f .\${FILE} -t ${TAG}",
  [string]$TEST = "docker run --rm -it -e CI=true -v /var/run/docker.sock:/var/run/docker.sock wagoodman/dive:latest ${TAG}"
)

$SKIP_CONFIG = $true
$PARENT_PROJECT_PATH = "."

. ([Scriptblock]::Create((([System.Text.Encoding]::ASCII).getString((Invoke-WebRequest -Uri "${FUNCTIONS_URI}").Content))))

printSectionBanner "Building Image"
printSectionLine "$COMMAND" "warn"

Invoke-Expression -Command "$COMMAND" | Tee-Object -Append -FilePath "${LOG_FILE}"
Invoke-Expression -Command "$TEST" | Tee-Object -Append -FilePath "${LOG_FILE}"


