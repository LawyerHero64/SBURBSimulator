#!/bin/sh
rsync -rcv --exclude .git --exclude '*~' --chmod=Dugo+x,ugo+r ./ jadedresearcher@50.116.40.89:/var/www/html/ferragofiction.com/public_html/SBURBSim/
