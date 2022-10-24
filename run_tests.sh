echo "💧  Running unit tests on macOS"
swift test
MACOS_EXIT=$?

echo "💧  Starting docker-machine"
docker-machine start default

echo "💧  Exporting docker-machine env"
eval "$(docker-machine env default)"

echo "💧  Running unit tests on Linux"
docker run --rm --platform linux/amd64 -it -v $PWD:/root/code -w /root/code swift:5.5-focal /usr/bin/swift test -v -c release
LINUX_EXIT=$?

if [[ $MACOS_EXIT == 0 ]];
then
echo "✅  macOS Passed"
else
echo "🚫  macOS Failed"
fi

if [[ $LINUX_EXIT == 0 ]];
then
echo "✅  Linux Passed"
else
echo "🚫  Linux Failed"
fi
