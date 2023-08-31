BASEDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"


cd $BASEDIR
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo 'System detected: MacOS'
    # Mac
    # Install using brew
    ./brew/install.sh
    # Install using npm
    npm install -g git-split-diffs
else
    echo 'System detected: Arch'
    # Arch
    # Install using yay
    # Install using npm
    echo 'Not implemented yet'
    # Install npm first
    npm install -g git-split-diffs
fi
