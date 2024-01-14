set -e

SCHEME=$1
BUILD_DIR=.build
PLATFORMS=(
  "generic/platform=iOS"
  "generic/platform=iOS Simulator" 
  #"platform=macOS" 
  #"generic/platform=tvOS" 
  #"generic/platform=tvOS Simulator" 
  #"generic/platform=visionOS" 
  #"generic/platform=visionOS Simulator" 
  #"generic/platform=watchOS" 
  #"generic/platform=watchOS Simulator"
)

rm -rf $BUILD_DIR

for platform in "${PLATFORMS[@]}"; do
  for config in Debug Release; do
    echo "\033[1m$SCHEME ${config} ${platform}\033[0m"
    xcodebuild -quiet -scheme $SCHEME -destination "$platform" -derivedDataPath $BUILD_DIR -configuration "$config"
  done
done