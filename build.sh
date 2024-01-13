set -e

platforms=(
  "platform=macOS" 
  "generic/platform=iOS"
  #"generic/platform=iOS Simulator" 
  #"generic/platform=tvOS" 
  #"generic/platform=tvOS Simulator" 
  #"generic/platform=visionOS" 
  #"generic/platform=visionOS Simulator" 
  #"generic/platform=watchOS" 
  #"generic/platform=watchOS Simulator"
)

rm -rf build

for i in "${platforms[@]}"; do
  echo "\033[1mBuilding: ${i}\033[0m"
  xcodebuild -quiet -scheme 'DLog-Package' -destination "$i" -derivedDataPath build -configuration Release
done