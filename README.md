Build scripts for building multiple applications from parent location<br />

Before you run/use the script<br />
    - download sdk and update sdkmanager with latest API plaforms<br />
    - download latest ndk<br />
<br />

Run 'source envsetup.sh' to set<br />
    - android source directory<br />
    - android sdk<br />
    - android ndk<br />
    - out directory<br />

e.g.<br />
(Note: one can also run the script directory, script will ask for inputs)<br />

source envsetup.sh --sdk "sdk path" --ndk "ndk path" --and "android source" \
                    --approot "where applications are clonned" --out "out directory for final apks"

Once, environment is set run <br />
    $ ndk-build 
    <br />

What is next?<br />
    - Script is verified with k9mail app<br />
    - need to add support for upcoming apps<br />
    - need to add support to checkout app with respected branch to build<br />
