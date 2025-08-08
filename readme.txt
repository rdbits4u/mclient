zig build -Doptimize=ReleaseFast -Dstrip=true --summary all
cp -i zig-out/bin/mclient mclient.app/Contents/MacOS/
./mclient.app/Contents/MacOS/mclient
