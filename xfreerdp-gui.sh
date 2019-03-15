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

  LOGIN=
  PASSWORD=
  DOMAIN=
  SERVER=
  PORT=
  RESOLUTION=
  GEOMETRY=
  CERTIGNORE=
  BPP=
  NAMEDIR=
  DIR=
  OPTIONS=
    varFull=
  varLog=
  [ -n "$USER" ] && until xdotool search "xfreerdp-gui" windowactivate key Right Tab 2>/dev/null ; do sleep 0.03; done &
    FORMULARY=$(yad --center --width=380 \
          --window-icon="gtk-execute" --image="debian-logo" --item-separator=","                                              \
          --title "xfreerdp-gui"                                                                                              \
          --form                                                                                                              \
          --field="Server" $SERVER "somewhere.com"                                                               \
          --field="Port"  $PORT "3389"                                                                                        \
          --field="Domain" $DOMAIN ""                                                                                         \
          --field="Username" $LOGIN "Administrator"                                                                            \
          --field="Password ":H $PASSWORD "password"                                                                                  \
          --field="Resolution":CBE $RESOLUTION "$wxh1,$wxh2,640x480,720x480,800x600,1024x768,1280x1024,1600x1200,1920x1080,"  \
          --field="BPP":CBE $BPP "24,16,32,"                                                                                  \
          --field="Name of Shared Directory" $NAMEDIR "Shared"                                                                \
          --field="Shared Directory" $DIR $HOME/Downloads                                                                     \
          --field="Other Options" $OPTIONS ""                                                                                 \
          --field="Full Screen":CHK $varFull                                                                                  \
          --field="Show Log":CHK $varLog                                                                                      \
          --button="Cancel":1 --button="Connect":0)
    [ $? != 0 ] && exit
    SERVER=$(echo $FORMULARY     | awk -F '|' '{ print $1 }')
    PORT=$(echo $FORMULARY       | awk -F '|' '{ print $2 }')
    DOMAIN=$(echo $FORMULARY     | awk -F '|' '{ print $3 }')
    LOGIN=$(echo $FORMULARY      | awk -F '|' '{ print $4 }')
    PASSWORD=$(echo $FORMULARY   | awk -F '|' '{ print $5 }')
    RESOLUTION=$(echo $FORMULARY | awk -F '|' '{ print $6 }')
    BPP=$(echo $FORMULARY        | awk -F '|' '{ print $7 }')
    NAMEDIR=$(echo $FORMULARY    | awk -F '|' '{ print $8 }')
    DIR=$(echo $FORMULARY        | awk -F '|' '{ print $9 }')
    OPTIONS=$(echo $FORMULARY    | awk -F '|' '{ print $10 }')
    varFull=$(echo $FORMULARY    | awk -F '|' '{ print $11 }')
    if [ "$varFull" = "TRUE" ]; then
          GEOMETRY="/f"
    else
          GEOMETRY=""
    fi
    varLog=$(echo $FORMULARY | awk -F '|' '{ print $12 }')

    xfreerdp                            \
                      /v:"$SERVER":$PORT        \
                      /cert-tofu /cert-ignore   \
                      /t:"$SERVER"              \
                      /u:"$LOGIN"               \
                      /p:"$PASSWORD"            \
                      /d:"$DOMAIN"              \
                      /sound                    \
                      /bpp:$BPP                 \
                      /sec-tls $GEOMETRY        \
                      /size:$RESOLUTION         \
                      /decorations /window-drag \
                      /drive:$NAMEDIR,$DIR      \
                      /compression /drive:$DIR  \
                      $OPTIONS                  \
                      +compression +clipboard   \
                      -menu-anims +fonts 2>&1 &


  #####################################################################################
  #### Reference:
  #### Adapted from: https://github.com/FreeRDP/FreeRDP/issues/1358#issuecomment-175075061
