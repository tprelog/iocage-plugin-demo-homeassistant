#!/bin/bash 

v2srv_user=hass
v2srv_uid=8123

pip_pip () {
 python3.6 -m ensurepip
 pip3 install --upgrade pip
 pip3 install --upgrade virtualenv
}

add_hass () {
  install -d -g 8123 -o 8123 -m 775 -- /home/${v2srv_user}
  pw addgroup -g 8123 -n ${v2srv_user}
  pw adduser -u 8123 -n ${v2srv_user} -d /home/${v2srv_user} -s /usr/local/bin/bash -G dialer -c "Daemon user for Home Assistant"
}

install_configurator () {
  v2srv=configurator
    install -d -g "${v2srv_user}" -o "${v2srv_user}" -m 775 -- /srv/${v2srv} || exit
  wget https://raw.githubusercontent.com/danielperna84/hass-configurator/master/configurator.py -O /srv/${v2srv}/configurator.py
  chmod +x /srv/${v2srv}/configurator.py
    start_v2srv
}


install_homeassistant () {
  v2srv=homeassistant
    install -d -g "${v2srv_user}" -o "${v2srv_user}" -m 775 -- /srv/${v2srv} || exit
  screen -dmS scrn_env su - hass -c bash "/root/post_install.sh homeassistant_virt"
  screen -r scrn_env || exit
    start_v2srv
}


install_appdaemon () {
  v2srv=appdaemon
    install -d -g "${v2srv_user}" -o "${v2srv_user}" -m 775 -- /srv/{v2srv} || exit
  screen -dmS scrn_env su - hass -c bash "/root/post_install.sh appdaemon_virt"
  screen -r scrn_env || exit
    start_v2srv
}


homeassistant_virt () {
  v2srv=homeassistant
    echo "Installing ${v2srv} virtualenv for: `whoami`"; echo
    sleep 2 # sleep 2 so we check we're the right person above
  virtualenv -p /usr/local/bin/python3.6 /srv/homeassistant
  source /srv/homeassistant/bin/activate
  pip3 install --upgrade homeassistant
    exit
}


appdaemon_virt () {
  v2srv=appdaemon
    echo "Installing ${v2srv} virtualenv for: `whoami`"; echo
    sleep 2 # sleep 2 so we check we're the right person above
  virtualenv -p /usr/local/bin/python3.6 /srv/appdaemon
  source /srv/appdaemon/bin/activate
  pip3 install --pre appdaemon
    exit
}


start_v2srv () {
  chmod +x /usr/local/etc/rc.d/${v2srv}
  sysrc -f /etc/rc.conf ${v2srv}_enable=yes
  service ${v2srv} start; sleep 1
  echo "Checking on ${v2srv}..."; sleep 1
  service ${v2srv} status
}

do_it () {          # - Install this shit already! ---

  add_hass || exit    # Problems already :( -- I quit!
   pip_pip
    install_homeassistant
    install_configurator
    install_appdaemon
  
  echo; echo " Finished. OK!"; exit
}

do_it

