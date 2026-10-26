#
# Red Griffin ATC - Speaking Air Traffic Controller for FlightGear
#
# Written and developer by Antonello Biancalana (Red Griffin, IK0TOJ)
#
# Copyright (C) 2019-2021 Antonello Biancalana
#
# addon-main.nas
#
# Launcher script
#
# Version 2.6.0 - 26 October 2026
#
# Red Griffin ATC is an Open Source project and it is licensed
# under the Gnu Public License v3 (GPLv3)
#

var main = func(addon)
{
    print("Installing Red Griffin ATC addon from ", addon.basePath);

    foreach(var script; ['globals.nas', 'settings.nas', 'rgatc.nas', 'f15-escort.nas'])
    {
        var fname = addon.basePath ~ "/" ~ script;

        print("Loading ", fname, " module");

        io.load_nasal(fname, "RgATC");
    }

    RgATC.configureF15Escort(addon.basePath);
    
    RgATC.loadSettings();
    
    var openRgATCDialog = getprop("/rgatc/open-dialog-startup");

    if(openRgATCDialog != nil)
    {
        if(openRgATCDialog == "On")
            RgATC.openATCDialog();
    }
}
