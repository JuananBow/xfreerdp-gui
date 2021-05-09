  #!/bin/bash


  #####################################################################################
  #### FEDERAL UNIVERSITY OF SANTA CATARINA -- UFSC
  #### Prof. Wyllian Bezerra da Silva


  #####################################################################################
  #### Dependencies: freerdp-x11 gawk x11-utils yad zenity

  string=""
  if ! hash xfreerdp 2>/dev/null; then
      string="\nfreerdp-x11"
  fi
  if ! hash awk 2>/dev/null; then
      string="\ngawk"
  fi
  if ! hash xdpyinfo 2>/dev/null; then
      string="${string}\nx11-utils"
  fi
  if ! hash yad 2>/dev/null; then
      string="${string}\nyad"
  fi
  if [ -n "$string" ]; then
    if hash amixer 2>/dev/null; then
      amixer set Master 80% > /dev/null 2>&1;
    else
      pactl set-sink-volume 0 80%
    fi
    if hash speaker-test 2>/dev/null; then
      ((speaker-test -t sine -f 880 > /dev/null 2>&1)& pid=$!; sleep 0.2s; kill -9 $pid) > /dev/null 2>&1
    else
      if hash play 2>/dev/null; then
        play -n synth 0.1 sin 880 > /dev/null 2>&1
      else
        cat /dev/urandom | tr -dc '0-9' | fold -w 32 | sed 60q | aplay -r 9000 > /dev/null 2>&1
      fi
    fi
    (zenity --info --title="Requirements" --width=300 --text="You need to install this(ese) package(s):

    <b>$string</b>

    ") > /dev/null 2>&1
    exit
  fi


  #####################################################################################
  #### Get informations
  dim=$(xdpyinfo | grep dimensions | sed -r 's/^[^0-9]*([0-9]+x[0-9]+).*$/\1/')
  wxh1=$(echo $dim | sed -r 's/x.*//')"x"$(($(echo $dim | sed -r 's/.*x//')-20))
  wxh2=$(($(echo $dim | sed -r 's/x.*//')-70))"x"$(($(echo $dim | sed -r 's/.*x//')-70))

  configfile="$HOME/xfreerdp-gui.conf"
  LOGIN=Administrator
  DOMAIN=WORKGROUP 
  SERVER=somewhere.com
  PORT=3389
  RESOLUTION=1920x1060
  BPP=24
  SHAREDIRNAME=Shared
  SHAREDIR=$HOME
  if [ -f "$configfile" ]; then
    source $configfile
    echo -e "Configuration loaded from $configfile"
  fi 

  [ -n "$USER" ] && until xdotool search "xfreerdp-gui" windowactivate key Right Tab 2>/dev/null ; do sleep 0.03; done &
    FORMULARY=$(yad --center --width=380 \
          --window-icon="gtk-execute" --image="$(dirname "$0")/freerdp-logo.png" --item-separator=","                         \
          --title "xfreeRDP-GUI"                                                                                              \
          --form                                                                                                              \
          --field="Server":CE ^$SERVER                                                                                        \
          --field="Port":CE  ^$PORT                                                                                           \
          --field="Domain":CE ^$DOMAIN                                                                                        \
          --field="Username":CE ^$LOGIN                                                                                       \
          --field="Password ":H $PASSWORD ""                                                                                  \
          --field="Resolution":CBE "^$RESOLUTION,$wxh1,$wxh2,640x480,720x480,800x600,1024x768,1280x1024,1600x1200,1920x1080," \
          --field="BPP":CBE "^$BPP,32,24,16,"                                                                                 \
          --field="Name of Shared Directory":CE ^$SHAREDIRNAME                                                                \
          --field="Shared Directory":DIR $SHAREDIR                                                                            \
          --field="Other Options":CE ^$OPTIONS                                                                                \
          --field="Log":CBE "^OFF,FATAL,ERROR,WARN,INFO,DEBUG,TRACE"                                                          \
          --field="Full Screen":CHK $FULLSCREEN                                                                               \
          --field="Save config":CHK                                                                                           \
          --button="Cancel":1 --button="Connect":0)
    [ $? != 0 ] && exit
    SERVER=$(echo $FORMULARY        | awk -F '|' '{ print $1 }')
    PORT=$(echo $FORMULARY          | awk -F '|' '{ print $2 }')
    DOMAIN=$(echo $FORMULARY        | awk -F '|' '{ print $3 }')
    LOGIN=$(echo $FORMULARY         | awk -F '|' '{ print $4 }')
    PASSWORD=$(echo $FORMULARY      | awk -F '|' '{ print $5 }')
    RESOLUTION=$(echo $FORMULARY    | awk -F '|' '{ print $6 }')
    BPP=$(echo $FORMULARY           | awk -F '|' '{ print $7 }')
    SHAREDIRNAME=$(echo $FORMULARY  | awk -F '|' '{ print $8 }')
    SHAREDIR=$(echo $FORMULARY      | awk -F '|' '{ print $9 }')
    OPTIONS=$(echo $FORMULARY       | awk -F '|' '{ print $10 }')
    LOG=$(echo $FORMULARY           | awk -F '|' '{ print $11 }')
    FULLSCREEN=$(echo $FORMULARY    | awk -F '|' '{ print $12 }')
    varSave=$(echo $FORMULARY       | awk -F '|' '{ print $13 }')
    if [ "$FULLSCREEN" = "TRUE" ]; then
          fullscreenparam="/f"
    else
          fullscreenparam=""
    fi
    if [ "$varSave" = "TRUE" ]; then
        echo -e "# xFreeRDP-GUI Config File"    > $configfile
        echo -e "# `date` "                     >> $configfile
        echo -e ""                              >> $configfile
        echo -e "LOGIN=$LOGIN"                  >> $configfile
        echo -e "DOMAIN=$DOMAIN"                >> $configfile
        echo -e "SERVER=$SERVER"                >> $configfile
        echo -e "PORT=$PORT"                    >> $configfile
        echo -e "RESOLUTION=$RESOLUTION"        >> $configfile
        echo -e "BPP=$BPP"                      >> $configfile
        echo -e "SHAREDIRNAME=$SHAREDIRNAME"    >> $configfile
        echo -e "SHAREDIR=$SHAREDIR"            >> $configfile
        echo -e "OPTIONS=$OPTIONS"              >> $configfile
        echo -e "FULLSCREEN=$FULLSCREEN"        >> $configfile
        echo -e "Configuration saved to $configfile"
    fi

    xfreerdp \
     /v:"$SERVER":$PORT        \
     /cert-tofu /cert-ignore   \
     /t:"$SERVER"              \
     /u:"$LOGIN"               \
     /p:"$PASSWORD"            \
     /d:"$DOMAIN"              \
     /sound                    \
     /bpp:$BPP                 \
     /sec-tls $fullscreenparam \
     /size:$RESOLUTION         \
     /decorations /window-drag \
     /drive:$SHAREDIRNAME,$SHAREDIR \
     /compression-level:2      \
     $OPTIONS                  \
     +clipboard                \
     -menu-anims               \
     /log-level:"$LOG"         \
     2>&1


  #####################################################################################
  #### Reference:
  #### Adapted from: https://github.com/FreeRDP/FreeRDP/issues/1358#issuecomment-175075061
