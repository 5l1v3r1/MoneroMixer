#!/bin/bash
download_monero_wallet_cli(){
    [ -d monero-software ] || mkdir monero-software
    cd monero-software
    
    declare uaList 
    readarray -n 7478 uaList < ../info/user-agents.txt    

    ua=$(echo "User-Agent: ${uaList[$(( ( RANDOM % 7047 )  + 1 ))]}" | tr -d "\n")
    torsocks wget https://web.getmonero.org/downloads/hashes.txt \
    --show-progress \
    --secure-protocol="TLSv1_2" \
    --user-agent "$ua" \
    --max-redirect=0 | $(zenity --progress \
                                    --title="Downloading SHA256 hashes from getmonero.org" \
                                    --text="Downloading SHA256 hashes from getmonero.org to verify the\nauthenticity of your Monero software.
\nPlease wait. MoneroMixer will start automatically once finished..." \
                                    --pulsate --auto-close --auto-kill 2> /dev/null)
    chmod 400 hashes.txt
    read -r filename authentic_hash <<<$(grep "monero-linux-x64" hashes.txt | tr -d ,)
    
    ua=$(echo "User-Agent: ${uaList[$(( ( RANDOM % 7047 )  + 1 ))]}" | tr -d "\n")
    torsocks wget https://dlsrc.getmonero.org/cli/${filename} \
    --show-progress \
    --secure-protocol="TLSv1_2" \
    --user-agent "$ua" \
    --max-redirect=0 -O $filename | $(zenity --progress \
                                    --title="Downloading Monero software from getmonero.org" \
                                    --text="Downloading Linux 64-bit Monero command line tools from getmonero.org
\nPlease wait. MoneroMixer will start automatically once finished..." \
                                    --pulsate --auto-close --auto-kill 2> /dev/null)
    [ -e $filename ] || failed_monero_wallet_cli

    
    read -ra cli_hash <<< $(openssl sha256 $filename)
    if [ "${cli_hash[1]}" = "$authentic_hash" ]
    then
        zenity --notification --text "Successfully verified Monero binary hash\nYour Monero software is safe to use"   
        unzip_monero_wallet_cli | $(zenity --progress \
                                    --title="Extracting monero-wallet-cli from Monero binary" \
                                    --text="Extracting monero-wallet-cli from $filename

Please wait. MoneroMixer will start automatically once finished..." \
                                    --pulsate --auto-close --auto-kill 2> /dev/null)
    else
        if zenity --question --ellipsize --icon-name='dialog-warning' \
            --title="WARNING: The Monero software you downloaded may be NOT be authentic" \
            --text="WARNING: The Monero software you downloaded may be NOT be authentic.

The SHA256 hash of the Monero software that you downloaded is:       
${cli_hash[1]}

Which is different from the SHA256 hash posted on getmonero.org:
$authentic_hash
   
You may be affected by an MITM (Man-in-the-middle) attack and should install the Monero software manually to ensure your security.

The potentially compromised software will be destroyed unless you select continue anyway." \
            --ok-label="View steps to download manually" \
            --cancel-label="Continue anyway (Potentially dangerous)" 2> /dev/null
        then 
            manual_monero_wallet_cli   
        else
            unzip_monero_wallet_cli   
        fi 
    fi
    cd ../
    [ -x monero-software/monero-wallet-cli ] || failed_monero_wallet_cli
}

unzip_monero_wallet_cli(){
    tar -xf $filename
    mv */monero-wallet-cli monero-wallet-cli
    chmod +x monero-wallet-cli
}

failed_monero_wallet_cli(){
    if zenity --question --ellipsize --icon-name='dialog-warning' \
              --title="Error: Failed to download Monero Software" \
              --text="Failed to download monero-wallet-cli from getmonero.org

Try again or download the Monero Software manually to continue" \
              --ok-label="Try automatic download again" \
              --cancel-label="Download manually" 2> /dev/null
    then 
        download_monero_wallet_cli
    else
        manual_monero_wallet_cli
    fi 
    test -x monero-software/monero-wallet-cli || failed_monero_wallet_cli
}

manual_monero_wallet_cli(){
    zenity --info --ellipsize --title="How to setup Monero software manually" \
           --text="1. Download the Monero Linux64 Command Line tool from this link:
https://downloads.getmonero.org/cli/linux64

2. Unzip the zip archive and find the file called monero-wallet-cli inside the unpacked file.

3. Copy monero-wallet-cli to the monero-software folder inside your MoneroMixer folder (MoneroMixer/monero-software) then press Ok to continue." 2> /dev/null
}


download_python_dependencies(){
    [ $USER = "amnesia" ] || $(pip3 install requests qrcode) \
    | zenity --progress --title="Downloading Python3 Dependencies" \
      --text "Please wait. MoneroMixer will start automatically once finished..." \
      --pulsate --auto-close --auto-kill 2> /dev/null
}

check_if_persistent(){
    if test "$(echo "print('Persistent' in '$PWD')" | python3)" = "False" -a $USER = "amnesia"
    then 
        if zenity --question --ellipsize \
                  --title="WARNING: MoneroMixer is NOT installed in your Persistent volume" \
                  --text="MoneroMixer should be installed to your Tails Persisent volume so that your Monero wallet(s) are saved permanently.

FAILURE TO INSTALL MONEROMIXER IN YOUR PERSISTENT VOLUME WILL CAUSE YOUR WALLETS TO BE DELETED UPON RESTARTING TAILS

Instructions on how to setup a persistent volume can be found here:
https://tails.boum.org/install/clone/index.en.html#create-persistence\n" \
                  --ok-label="Select a new folder to move MoneroMixer" \
                  --cancel-label="Continue without persistence" \
                  --icon-name="dialog-warning" 2> /dev/null 
        then 
            move_setup
            check_persistent
        else
            if zenity --question --ellipsize \
                --title="Are you sure you want to continue without persistence?" \
                --text="MoneroMixer will still work fine without being installed in your persistent volume, but all of your data (wallets, coins, order IDs) will be lost upon restarting Tails.

AGAIN, FAILURE TO INSTALL MONEROMIXER IN YOUR PERSISTENT VOLUME WILL CAUSE YOUR WALLETS TO BE DELETED UPON RESTARTING TAILS

You should only continue without persistence if you are aware of this fact." \
                --ok-label="Select a new folder to move MoneroMixer" \
                --cancel-label="Continue without persistence" \
                --icon-name="dialog-warning" 2> /dev/null 
            then 
                move_setup
                check_persistent            
            fi
        fi
    fi
}

move_setup(){
    new_dir="$(zenity --file-selection --title="Select a folder in your Persistent volume where you would like to move MoneroMixer" --directory 2> /dev/null)"
    cd ../
    mv MoneroMixer $new_dir/MoneroMixer
    cd $new_dir/MoneroMixer
}


file_setup() {
    shell=( "welcome" "mmutils" "error" "settings" "wallet" "wallet_gen" \
            "main_menu" "exchange" "exchange_menus" "update" "help" "donate" )
    python=( "display" "exchange" "excomp" "mmutils" "MoneroMixer" "wallet" )
    
    for shfile in "${shell[@]}"; do
        chmod 400 "scripts/shell/${shfile}.sh"
    done

    for pyfile in "${python[@]}"; do
        chmod 400 "scripts/python3/${pyfile}.py"
    done

    chmod 500 scripts/shell/MoneroMixer.sh
    
    rm -rf .git _config.yml
    mv README.md info/README.md
    mv LICENSE info/LICENSE
}

make_launchers() {
    MMPATH="$PWD"
    term_args="-terminal --title=\"MoneroMixer v1.2\" --hide-menubar"
    mmscript="./scripts/shell/MoneroMixer.sh"
    if echo "$XDG_MENU_PREFIX" | grep -q "gnome"; then
        terminal="gnome"
        term_args="$term_args -- "
    elif echo "$XDG_MENU_PREFIX" | grep -q "xfce"; then
        terminal="xfce4"
        term_args="$term_args --icon=\"${MMPATH}/icons/MMICON.png\" -e "
    else
        unset -v term_args
    fi
    
     echo "
#######################################################################################
#   Did you accidently open this file while trying to start MoneroMixer?              
#   To run MoneroMixer:
#   1. Right click your desktop and select \"Open in Terminal\"
#   2. Copy and paste your startup command into the terminal window then press ENTER
#      (Make sure you copy the whole command from \"cd\" to \"exit\") 
#
#   Your startup command is: cd \"$MMPATH\" && ./start; exit
#
#######################################################################################

${terminal}${term_args}${mmscript}" > start
    chmod 500 start

    echo "[Desktop Entry]
Version=1.2
Encoding=UTF-8
Type=Application
Terminal=false
StartupNotify=false
Name=MoneroMixer
Comment=Anonymously transact XMR, BTC, ETH, and 100+ other coins
Icon=${MMPATH}/icons/MMICON.png
Categories=Application;Network;
Path=${MMPATH}
Exec=${MMPATH}/start" > MoneroMixer.desktop
    chmod 755 MoneroMixer.desktop
    xdg-desktop-icon install MoneroMixer.desktop --novendor
    xdg-desktop-menu install MoneroMixer.desktop --novendor
    mv MoneroMixer.desktop icons/MoneroMixer.desktop
}


if [ -z "$1" ]; then
    . scripts/shell/mmutils.sh
    . scripts/shell/settings.sh
    check_if_persistent
    file_setup
    $(download_new_icons &> /dev/null) &
    download_python_dependencies
    download_monero_wallet_cli
    make_launchers
    ./start
elif [ "$1" = "update" ]; then 
    download_python_dependencies
    download_monero_wallet_cli
    file_setup
    make_launchers
elif [ "$1" = "launchers" ]; then
    make_launchers
else
    read_settings 
    $1
    write_settings
fi
