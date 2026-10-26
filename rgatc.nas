#
# Red Griffin ATC - Speaking Air Traffic Controller for FlightGear
#
# Written and developer by Antonello Biancalana (Red Griffin, IK0TOJ)
#
# Copyright (C) 2019-2021 Antonello Biancalana
#
# rgatc.nas
#
# Main program
#
# Version 2.5.0 - 25 October 2026
#
# Red Griffin ATC is an Open Source project and it is licensed
# under the Gnu Public License v3 (GPLv3)
#

var rgatcKeyboardListener = setlistener("/devices/status/keyboard/event", func(event)
{
    if(!event.getNode("pressed").getValue())
        return;

    var key = event.getNode("key").getValue();
    var shift = event.getNode("modifier/shift").getValue();
    var ctrl = event.getNode("modifier/ctrl").getValue();
    var minCruiseAltidude = getMinCruiseAltitude();

    if(key == last_key)
        return;

    if(isAtcEnabled() == 0)
    {
        showPopup(RGAtcName ~ " is not enabled.\nTurn it on from the menu");

        return;
    }

    last_key = key;

    if(key == binding_key_dialog)
    {
        if(initialized == 0)
            initRgATC();

        if(!rgatcTimer.isRunning)
            rgatcTimer.start();

        if(ctrl == 0)
        {
            last_key = 0;

            if(dialogOpened == 0)
                openATCDialog();
            else
                closeATCDialog();
        }
        else
            updateATC(update_popup);

        return;
    }
    else if(ctrl == 1 and shift == 0)
    {
        if(key == binding_key_msg1)
            pilotRequest(atcMessageType[0]);
        else if(key == binding_key_msg2)
            pilotRequest(atcMessageType[1]);
        else if(key == binding_key_msg3)
            pilotRequest(atcMessageType[2]);
        else if(key == binding_key_msg4)
            pilotRequest(atcMessageType[3]);
        else if(key == binding_key_request_ctr)
            pilotRequest(message_request_ctr);
        else if(key == binding_key_repeat_last_atc_message)
            pilotRequest(message_say_again);
    }
    else if(ctrl == 1 and shift == 1)
    {
        if(key == binding_key_flight_level_1 and aircraft_status == status_flying and flightLevel1 >= minCruiseAltidude)
        {
            requestedAltitude = flightLevel1;

            pilotRequest(message_request_fl);
        }
        else if(key == binding_key_flight_level_2 and aircraft_status == status_flying and flightLevel2 >= minCruiseAltidude)
        {
            requestedAltitude = flightLevel2;

            pilotRequest(message_request_fl);
        }
        else if(key == binding_key_flight_level_3 and aircraft_status == status_flying and flightLevel3 >= minCruiseAltidude and property_Aircraft_AltitudeFeet.getValue() > flightLevel3)
        {
            requestedAltitude = flightLevel3;

            pilotRequest(message_request_fl);
        }
        else if(key == binding_key_abort_approach)
            pilotRequest(message_abort_approach);
    }
}, 1);

var rgatcTimer = maketimer(timer_interval, func()
{
    var isTerrainSafe = 1;
    var radioIsTunedToApprovedCtrRadio = 0;
    var minCruiseAltidude = getMinCruiseAltitude();

    if(isSimulationPaused() == 1 or isAtcEnabled() == 0)
        return;

    if(initialized == 0)
        initRgATC();

    updateATC((dialogOpened == 1) ? update_dialog : update_data_only);

    if(atc_callback_wait_seconds != auto_reply_off)
    {
        atc_callback_seconds_counter += timer_interval;

        if(atc_callback_seconds_counter >= atc_callback_wait_seconds)
        {
            atc_callback_seconds_counter = 0;

            atc_callback_wait_seconds = auto_reply_off;

            atcAutoMessage();
        }
    }

    if(pilot_message_wait_seconds > 0)
    {
        pilot_message_counter += timer_interval;

        if(pilot_message_counter >= pilot_message_wait_seconds)
        {
            pilot_message_wait_seconds = -1;

            atcReplyToRequest(pilotMessageType);

            pilotMessageType = message_none;
        }
    }

    if(pilot_response_wait_seconds > 0)
    {
        pilot_response_counter += timer_interval;

        if(pilot_response_counter >= pilot_response_wait_seconds)
        {
            pilot_response_wait_seconds = -1;

            pilotResponse(pilotResponseType);

            pilotResponseType = message_none;
        }
    }

    key_press_counter += timer_interval;
    ctr_update_counter += timer_interval;
    ctr_check_counter += timer_interval;

    if(aircraft_status == status_flying or aircraft_status == status_took_off)
        flight_time_seconds += timer_interval;

    if(key_press_counter > reset_key_interval)
    {
        key_press_counter = 0;

        last_key = 0;
    }

    radioIsTunedToApprovedCtrRadio = isRadioTunedToApprovedCtrRadio();

    if(ctr_check_counter > ctr_check_interval)
    {
        if(currentCtr != nil and approvedCtr == nil and aircraft_status == status_flying and radioIsTunedToApprovedCtrRadio == 1)
        {
            atcReplyToRequest(message_not_in_this_ctr);
        }

        ctr_check_counter = 0;
    }

    if(ctr_update_counter > ctr_update_interval)
    {
        if(approvedCtr != nil)
        {
            currentCtr = getCtrData(airportinfo(approvedCtr.ident));

            if(currentCtr.distance > (currentCtr.range - ctr_leaving_range))
            {
                if(radioIsTunedToApprovedCtrRadio == 1)
                    atcReplyToRequest(message_leaving_ctr);

                ctr_leaving_warning = 1;

                approvedCtr = nil;

                altitude_check_counter = 0;

                resetAircraftStatus();

                setCtrButtons();
            }
        }
        else
            currentCtr = getNearbyCtr(ctr_search_range);

        ctr_update_counter = 0;

        var aircraftPosition = geo.aircraft_position();
        var terrainInfo = geodinfo(aircraftPosition.lat(), aircraftPosition.lon());
        isTerrainSafe = isTerrainSafeAhead();

        if(terrainInfo != nil)
            altitudeFromTerrain = property_Aircraft_AltitudeFeet.getValue() - (terrainInfo[0] * M2FT);
        else
            altitudeFromTerrain = -1;

        if((altitudeFromTerrain < min_altitude_from_terrain or isTerrainSafe == 0) and terrainWarning == 0 and (aircraft_status == status_flying or aircraft_status == status_requested_approach or aircraft_status == status_requested_ils) and flight_time_seconds > take_off_max_seconds)
        {
            if(approvedCtr.ident == currentCtr.ident and radioIsTunedToApprovedCtrRadio == 1)
            {
                if(altitudeFromTerrain > min_altitude_too_low_warning)
                {
                    if(altitudeFromTerrain < min_altitude_from_terrain and tooLowWarningMode == "On")
                        atcReplyToRequest(message_flying_too_low);
                    else if(isTerrainSafe == 0 and terrainWarningMode == "On")
                        atcReplyToRequest(message_terrain_ahead);
                }

                terrainWarning = 1;
                terrain_warning_counter = 0;
            }
        }

        if(aircraft_status == status_flying)
        {
            var heading = property_Aircraft_HeadingDeg.getValue();

            flightLevel2 = normalizeAltitudeHeading(property_Aircraft_AltitudeFeet.getValue(), heading, minCruiseAltidude);

            flightLevel1 = flightLevel2 + flight_level_step;

            flightLevel3 = flightLevel2 - flight_level_step;

            if(flightLevel2 < minCruiseAltidude)
                flightLevel2 = normalizeAltitudeHeading(minCruiseAltidude, heading, minCruiseAltidude);

            if(flightLevel3 < minCruiseAltidude)
                flightLevel3 = normalizeAltitudeHeading(minCruiseAltidude, heading, minCruiseAltidude);
        }
    }

    if(terrainWarning == 1)
    {
        terrain_warning_counter += timer_interval;

        if(terrain_warning_counter >= terrain_warning_interval)
        {
            if(pilot_message_wait_seconds > 0)
                pilot_message_wait_seconds += 10;

            if(altitude_change_wait_seconds > 0)
                altitude_change_wait_seconds += 15;

            altitude_check_counter = 0;

            if(altitudeFromTerrain > min_altitude_too_low_warning)
            {
                if(altitudeFromTerrain < min_altitude_from_terrain)
                    atcReplyToRequest(message_flying_too_low);
                else if(isTerrainSafe == 0)
                    atcReplyToRequest(message_terrain_ahead);
                else
                    terrainWarning = 0;
            }
            else
                terrainWarning = 0;

            terrain_warning_counter = 0;
        }
    }

    if(assignedAltitude != -1 and aircraft_status == status_flying)
    {
        altitude_check_counter += timer_interval;

        if(approvedCtr != nil)
        {
            if(altitude_check_counter >= altitude_check_interval and radioIsTunedToApprovedCtrRadio == 1)
            {
                var fpalt = getFlightPlanAltitude();

                if(fpalt != -1 and assignedAltitude != fpalt)
                {
                    atcReplyToRequest(message_change_altitude);
                }
                else
                {
                    if(property_Aircraft_HeadingDeg.getValue() > 180)
                        altitudeZone = altitude_zone_even;
                    else
                        altitudeZone = altitude_zone_odd;

                    if(currentAltitudeZone != altitudeZone)
                    {
                        currentAltitudeZone = altitudeZone;

                        atcReplyToRequest(message_change_altitude);
                    }
                    else if(abs(property_Aircraft_AltitudeFeet.getValue() - assignedAltitude) > assigned_altitude_delta)
                        atcReplyToRequest(message_check_altitude);
                }

                altitude_check_counter = 0;

                altitude_check_interval = flightLevelChangeSeconds(assignedAltitude);
            }
        }
    }

    if(altitude_change_wait_seconds > 0)
    {
        altitude_change_counter += timer_interval;

        if(approvedCtr != nil)
        {
            if(altitude_change_counter >= altitude_change_wait_seconds and aircraft_status == status_flying and radioIsTunedToApprovedCtrRadio == 1)
            {
                altitude_change_wait_seconds = -1;

                atcReplyToRequest(message_change_altitude);
            }
        }
    }

    if(aircraft_status == status_requested_approach or aircraft_status == status_requested_ils)
    {
        approach_check_counter += timer_interval;

        if(approach_check_counter > approach_check_interval and  radioIsTunedToApprovedCtrRadio == 1)
        {
            assistedAtcApproach();

            approach_check_counter = 0;
        }
    }

    if(squawkingMode == "On")
    {
        var detectedEmergencySquawk = getEmergencySquawkCode(selectedTransponder);

        if(detectedEmergencySquawk != emergencySquawkCode)
        {
            emergencySquawkCode = detectedEmergencySquawk;
            emergencySquawkAnnouncedCode = "";
            squawk_check_counter = 0;
            setSquawkIdentMode(squawk_ident_off);

            if(emergencySquawkCode == "7500")
                startF15Escort();
            else
                endF15Escort();
        }

        if(emergencySquawkCode != "")
        {
            if(emergencySquawkAnnouncedCode != emergencySquawkCode and
               isRadioServiceable() == 1 and selectedComAirportId != "")
            {
                atcReplyToRequest(message_emergency_squawk);
                emergencySquawkAnnouncedCode = emergencySquawkCode;
            }
        }
        else if(aircraft_status == status_flying or aircraft_status == status_requested_approach or aircraft_status == status_requested_ils)
        {
            squawk_check_counter += timer_interval;

            if(checkTransponderIdent(selectedTransponder) == 1)
                squawkIdentButtonPushed = 1;

            if(squawk_check_counter > squawk_check_interval)
            {
                if(squawkIdent != squawk_ident_off)
                {
                    if(checkTransponder(selectedTransponder) == 1 and squawkIdentButtonPushed == 1)
                        setSquawkIdentMode(squawk_ident_off);
                    else
                        atcReplyToRequest(message_check_transponder);
                }
                else if(checkTransponder(selectedTransponder) == 0)
                    atcReplyToRequest(message_check_transponder);

                squawk_check_counter = 0;
            }
        }
    }
    else if(f15EscortState != "idle")
        endF15Escort();

    if(squawkingMode == "On" and emergencySquawkCode == "7500" and f15EscortState == "idle")
        startF15Escort();
});

var initRgATC = func()
{
    initSettings();

    var aircraftDescription = split(" ", getprop("/sim/description"));

    RGAtcName = getprop(RGAtcAddonProp ~ "name");
    RGAtcVersion = getprop(RGAtcAddonProp ~ "version");

    setRGTitle();

    if(size(aircraftDescription) > 0)
        aircraftManufacturer = aircraftDescription[0];
    else
        aircraftManufacturer = "";

    rgatcTimer.start();

    initialized = 1;

    setsize(radioButton, max_radios);
    setsize(radioButtonFrequency, max_radios);

    for(var i = 0; i < max_radios; i += 1)
    {
        radioButton[i] = nil;
        radioButtonFrequency[i] = 0;
    }

    var pos = geo.aircraft_position();

    var range = min_airport_range;

    if(currentCtr != nil)
        range += int((currentCtr.range / 1.5) / 10);

    var airport = findAirportsWithinRange(pos, range);

    if(size(airport) > 0)
    {
        currentAirport = airport[0];

        getAvailableRadios();

        currentRadioStationId = currentAirport.id;
    }

    aircraftIsDeparting = 1;
    approachStatus = approach_status_none;
    approach_check_interval = approach_check_interval_initial;

    currentCtr = getNearbyCtr(ctr_search_range);

    (atcCallsignText, atcCallsignVoice) = getCallSignForAtc(1);

    pilotVoice = getPilotVoice();

    initAtcVoice();

    print(RGAtcName ~ " successfully initialized and ready");

    RGAtcEnabled = 1;
    
    clearAtcLog();
}

var enableAtc = func()
{
    if(!rgatcTimer.isRunning)
        rgatcTimer.start();

    RGAtcEnabled = 1;

    openATCDialog();

    showPopup(RGAtcName ~ " is on");
}

var disableAtc = func()
{
    if(rgatcTimer.isRunning)
        rgatcTimer.stop();

    endF15Escort();

    RGAtcEnabled = 0;

    closeATCDialog();

    showPopup(RGAtcName ~ " is off");
}

var isAtcEnabled = func()
{
    return RGAtcEnabled;
}

var toggleAtc = func()
{
    if(isAtcEnabled() == 1)
        disableAtc();
    else
        enableAtc();
}

var setRGTitle = func()
{
    RGAtcTitle = "Red Griffin ATC";

    if(RGAtcName != nil and RGAtcName != "")
    {
        RGAtcTitle = RGAtcName;

        if(RGAtcVersion != nil and RGAtcVersion != "")
            RGAtcTitle ~= " " ~ RGAtcVersion;
    }
    else
        RGAtcName = RGAtcTitle;

    RGAtcTitle ~= " - Aircraft: " ~ aircraftType;

    if(dlgWindow != nil)
        dlgWindow.setTitle(RGAtcTitle);
}

var initRgATCDialog = func()
{
    dlgWindow = canvas.Window.new([dialogWidth, dialogHeight], "dialog")
                    .setTitle(RGAtcTitle);

    dlgWindow.del = func()
    {
        dialogInitialized = 0;
        dialogOpened = 0;

        call(canvas.Window.del, [], me);
    };

    dlgCanvas = dlgWindow.createCanvas().set("background", canvas.style.getColor("bg_color"));
    dlgCanvas.setColorBackground(0.5, 0.5, 0.5, 0.9);

    dlgRoot = dlgCanvas.createGroup();

    dlgLayout = canvas.VBoxLayout.new();

    dlgCanvas.setLayout(dlgLayout);

    txtAirport = dlgRoot.createChild("text")
      .setText("")
      .setFont("LiberationFonts/LiberationSans-Bold.ttf")
      .setFontSize(14, 0.9)
      .setColor(1,1,1,1)
      .setAlignment("left-center")
      .setTranslation(10, 20);

    txtAircraftPosition = dlgRoot.createChild("text")
      .setText("")
      .setFont("LiberationFonts/LiberationSans-Bold.ttf")
      .setFontSize(14, 0.9)
      .setColor(1,1,1,1)
      .setAlignment("left-center")
      .setTranslation(10, 36);

    txtCurrentCtr = dlgRoot.createChild("text")
      .setText("")
      .setFont("LiberationFonts/LiberationSans-Bold.ttf")
      .setFontSize(14, 0.9)
      .setColor(0.6,1,1,1)
      .setAlignment("left-center")
      .setTranslation(10, 60);

    txtCurrentCtrSpecs = dlgRoot.createChild("text")
      .setText("")
      .setFont("LiberationFonts/LiberationSans-Bold.ttf")
      .setFontSize(14, 0.9)
      .setColor(0.6,1,1,1)
      .setAlignment("left-center")
      .setTranslation(10, 76);

    txtCurrentRadio = dlgRoot.createChild("text")
      .setText("")
      .setFont("LiberationFonts/LiberationSans-Bold.ttf")
      .setFontSize(14, 0.9)
      .setColor(1,1,0,1)
      .setAlignment("left-center")
      .setTranslation(10, 100);

    txtCurrentRadioSpecs = dlgRoot.createChild("text")
      .setText("")
      .setFont("LiberationFonts/LiberationSans-Bold.ttf")
      .setFontSize(14, 0.9)
      .setColor(1,1,0,1)
      .setAlignment("left-center")
      .setTranslation(10, 116);

    var buttonBox = canvas.HBoxLayout.new();

    var middleBox = canvas.HBoxLayout.new();

    var messageBox = canvas.VBoxLayout.new();

    var topButtonBox = canvas.HBoxLayout.new();

    btnRepeatATCMessage = canvas.gui.widgets.Button.new(dlgRoot, canvas.style, {})
	            .setText("R")
	            .setFixedSize(repeatBtnWidth, 26);

    btnRepeatATCMessage.hide();

    btnRepeatATCMessage.listen("clicked", func
    {
        pilotRequest(message_say_again);

        dlgWindow.clearFocus();
    });

    btnRepeatATCMessage.hide();

    btnMessage[0] = canvas.gui.widgets.Button.new(dlgRoot, canvas.style, {})
	                .setText("")
	                .setFixedSize((dialogWidth / 2) - 20, 26);

    btnMessage[0].listen("clicked", func
    {
        pilotRequest(atcMessageType[0]);

        dlgWindow.clearFocus();
    });

    btnMessage[1] = canvas.gui.widgets.Button.new(dlgRoot, canvas.style, {})
	                .setText("")
	                .setFixedSize((dialogWidth / 2) - 20, 26);

    btnMessage[1].listen("clicked", func
    {
        pilotRequest(atcMessageType[1]);

        dlgWindow.clearFocus();
    });

    btnMessage[2] = canvas.gui.widgets.Button.new(dlgRoot, canvas.style, {})
	                .setText("")
	                .setFixedSize((dialogWidth / 2) - 20, 26);

    btnMessage[2].listen("clicked", func
    {
        pilotRequest(atcMessageType[2]);

        dlgWindow.clearFocus();
    });

    btnMessage[3] = canvas.gui.widgets.Button.new(dlgRoot, canvas.style, {})
	                .setText("")
	                .setFixedSize((dialogWidth / 2) - 20, 26);

    btnMessage[3].listen("clicked", func
    {
        pilotRequest(atcMessageType[3]);

        dlgWindow.clearFocus();
    });

    for(var i = 0; i < 4; i += 1)
        btnMessage[i].hide();

    topButtonBox.addItem(btnRepeatATCMessage);
    topButtonBox.addItem(btnMessage[0]);

    messageBox.addItem(topButtonBox);
    messageBox.addItem(btnMessage[1]);
    messageBox.addItem(btnMessage[2]);
    messageBox.addItem(btnMessage[3]);

    radioBox = canvas.VBoxLayout.new();

    radioBox.hide();

    radioScroll = canvas.gui.widgets.ScrollArea.new(dlgRoot, canvas.style, {size: [(dialogWidth / 2) - 20, 80]});
    radioScroll.setColorBackground(1.0, 1.0, 0.9, 0.9);

    radioBox.addItem(radioScroll, 1);

    radioScrollContent = radioScroll.getContent()
                .set("font", "LiberationFonts/LiberationSans-Bold.ttf")
                .set("character-size", 16)
                .set("alignment", "left-center");

    middleBox.addItem(messageBox);
    middleBox.addItem(radioBox);

    btnRequestCtr = canvas.gui.widgets.Button.new(dlgRoot, canvas.style, {})
	            .setText("Request CTR")
	            .setFixedSize(114, 26);

    btnRequestCtr.setEnabled(0);

    btnRequestCtr.listen("clicked", func
    {
        pilotRequest(message_request_ctr);

        dlgWindow.clearFocus();
    });

    var minCruiseAltidude = getMinCruiseAltitude();

    btnRequestFlightLevel1 = canvas.gui.widgets.Button.new(dlgRoot, canvas.style, {})
	            .setText("--")
	            .setFixedSize(58, 26);

    btnRequestFlightLevel1.setEnabled(0);

    btnRequestFlightLevel1.listen("clicked", func
    {
        if(flightLevel1 >= minCruiseAltidude)
        {
            requestedAltitude = flightLevel1;

            pilotRequest(message_request_fl);
        }

        dlgWindow.clearFocus();
    });

    btnRequestFlightLevel2 = canvas.gui.widgets.Button.new(dlgRoot, canvas.style, {})
	            .setText("--")
	            .setFixedSize(58, 26);

    btnRequestFlightLevel2.setEnabled(0);

    btnRequestFlightLevel2.listen("clicked", func
    {
        if(flightLevel2 >= minCruiseAltidude)
        {
            requestedAltitude = flightLevel2;

            pilotRequest(message_request_fl);
        }

        dlgWindow.clearFocus();
    });

    btnRequestFlightLevel3 = canvas.gui.widgets.Button.new(dlgRoot, canvas.style, {})
	            .setText("--")
	            .setFixedSize(58, 26);

    btnRequestFlightLevel3.setEnabled(0);

    btnRequestFlightLevel3.listen("clicked", func
    {
        if(flightLevel3 >= minCruiseAltidude)
        {
            requestedAltitude = flightLevel3;

            pilotRequest(message_request_fl);
        }

        dlgWindow.clearFocus();
    });

    btnAbortApproach = canvas.gui.widgets.Button.new(dlgRoot, canvas.style, {})
	            .setText("--")
	            .setFixedSize(140, 26);

    btnAbortApproach.setEnabled(0);

    btnAbortApproach.listen("clicked", func
    {
        pilotRequest(message_abort_approach);

        dlgWindow.clearFocus();
    });

    btnAvailableRadio = canvas.gui.widgets.Button.new(dlgRoot, canvas.style, {})
	            .setText("Radios")
	            .setFixedSize(74, 26);

    btnAvailableRadio.setEnabled(0);

    btnAvailableRadio.listen("clicked", func
    {
        availableRadioDialog();

        dlgWindow.clearFocus();
    });

    var btnClose = canvas.gui.widgets.Button.new(dlgRoot, canvas.style, {})
	            .setText("Close")
	            .setFixedSize(70, 26);

    btnClose.listen("clicked", func
    {
        closeATCDialog();
    });

    setApproachButtons();

    buttonBox.addStretch(1);
    buttonBox.addItem(btnRequestCtr);
    buttonBox.addStretch(1);
    buttonBox.addItem(btnAbortApproach);
    buttonBox.addItem(btnRequestFlightLevel1);
    buttonBox.addStretch(1);
    buttonBox.addItem(btnRequestFlightLevel2);
    buttonBox.addStretch(1);
    buttonBox.addItem(btnRequestFlightLevel3);
    buttonBox.addStretch(1);
    buttonBox.addItem(btnAvailableRadio);
    buttonBox.addStretch(1);
    buttonBox.addItem(btnClose);
    buttonBox.addStretch(1);

    dlgLayout.addStretch(1);
    dlgLayout.addItem(middleBox);
    dlgLayout.addItem(buttonBox);

    dialogInitialized = 1;

    setDialogPosition();

    showRepeatATCMessageButton(0);

    updateATC(update_dialog);
}

var setAtcTextPosition = func()
{
    if(atcTextPosition == "Top Left")
    {
        atc_popup_x_position = 20;
        atc_popup_y_position = -(10 + menu_bar_height);
        atc_popup_align = "left";
    }
    else if(atcTextPosition == "Top Center")
    {
        atc_popup_x_position = nil;
        atc_popup_y_position = -(10 + menu_bar_height);
        atc_popup_align = "center";
    }
    else if(atcTextPosition == "Top Right")
    {
        atc_popup_x_position = -20;
        atc_popup_y_position = -(10 + menu_bar_height);
        atc_popup_align = "left";
    }
    else if(atcTextPosition == "Middle Left")
    {
        atc_popup_x_position = 20;
        atc_popup_y_position = nil;
        atc_popup_align = "left";
    }
    else if(atcTextPosition == "Middle Center")
    {
        atc_popup_x_position = nil;
        atc_popup_y_position = nil;
        atc_popup_align = "center";
    }
    else if(atcTextPosition == "Middle Right")
    {
        atc_popup_x_position = -20;
        atc_popup_y_position = nil;
        atc_popup_align = "left";
    }
    else if(atcTextPosition == "Bottom Left")
    {
        atc_popup_x_position = 20;
        atc_popup_y_position = 10 + menu_bar_height;
        atc_popup_align = "left";
    }
    else if(atcTextPosition == "Bottom Center")
    {
        atc_popup_x_position = nil;
        atc_popup_y_position = 10 + menu_bar_height;
        atc_popup_align = "center";
    }
    else if(atcTextPosition == "Bottom Right")
    {
        atc_popup_x_position = -20;
        atc_popup_y_position = 10 + menu_bar_height;
        atc_popup_align = "left";
    }
    else
    {
        atc_popup_x_position = nil;
        atc_popup_y_position = -(10 + menu_bar_height);
        atc_popup_align = "center";
    }
    
    if(atcTextTransparency == "Off")
        popup_window_bg_color[3] = 1;
    else if(atcTextTransparency == "Very low")
        popup_window_bg_color[3] = 0.8;
    else if(atcTextTransparency == "Low")
        popup_window_bg_color[3] = 0.6;
    else if(atcTextTransparency == "Medium")
        popup_window_bg_color[3] = 0.4;
    else if(atcTextTransparency == "High")
        popup_window_bg_color[3] = 0.2;
    else if(atcTextTransparency == "Very high")
        popup_window_bg_color[3] = 0;
    else
        popup_window_bg_color[3] = 0.4;
}

var setDialogPosition = func()
{
    var canvasWidth = property_Canvas_Width.getValue();
    var canvasHeight = property_Canvas_Height.getValue();

    if(canvasWidth != nil and canvasHeight != nil)
    {
        if(dialogPosition == "Top Left")
        {
            dialogPosX = 0;
            dialogPosY = menu_bar_height;
        }
        else if(dialogPosition == "Top Right")
        {
            dialogPosX = canvasWidth - maxDialogWidth;
            dialogPosY = menu_bar_height;
        }
        else if(dialogPosition == "Bottom Left")
        {
            dialogPosX = 0;
            dialogPosY = canvasHeight - maxDialogHeight;
        }
        else if(dialogPosition == "Bottom Right")
        {
            dialogPosX = canvasWidth - maxDialogWidth;
            dialogPosY = canvasHeight - maxDialogHeight;
        }
        else
        {
            dialogPosX = 0;
            dialogPosY = menu_bar_height;
        }
    }
    else
    {
        dialogPosX = 0;
        dialogPosY = menu_bar_height;
    }

    if(dlgWindow != nil and dialogInitialized == 1)
        dlgWindow.setPosition(dialogPosX, dialogPosY);
}

var setApproachButtons = func()
{
    if(dialogOpened == 0)
        return;

    if(aircraft_status == status_requested_approach or aircraft_status == status_requested_ils or aircraft_status == status_cleared_for_land_approach or aircraft_status == status_cleared_for_land_ils)
    {
        btnRequestFlightLevel1.setEnabled(0);
        btnRequestFlightLevel2.setEnabled(0);
        btnRequestFlightLevel3.setEnabled(0);

        btnRequestFlightLevel1.hide();
        btnRequestFlightLevel2.hide();
        btnRequestFlightLevel3.hide();

        btnAbortApproach.setEnabled(1);

        btnAbortApproach.show();

        if(aircraft_status == status_requested_approach)
            btnAbortApproach.setText("Abort Approach");
        else if(aircraft_status == status_requested_ils)
            btnAbortApproach.setText("Abort ILS");
        else if(aircraft_status == status_cleared_for_land_approach or aircraft_status == status_cleared_for_land_ils)
            btnAbortApproach.setText("Abort Landing");
        else
        {
            btnAbortApproach.setEnabled(0);
            btnAbortApproach.hide();
        }
    }
    else
    {
        btnAbortApproach.setEnabled(0);

        btnAbortApproach.hide();

        btnRequestFlightLevel1.setEnabled(1);
        btnRequestFlightLevel2.setEnabled(1);
        btnRequestFlightLevel3.setEnabled(1);

        btnRequestFlightLevel1.show();
        btnRequestFlightLevel2.show();
        btnRequestFlightLevel3.show();
    }
}

var setCtrButtons = func()
{
    if(dialogOpened == 0)
        return;

    if(selectedComFrequency > 0)
        btnRequestCtr.setEnabled(1);
    else
        btnRequestCtr.setEnabled(0);

    if(aircraft_status == status_flying)
    {
        if(approvedCtr != nil)
        {
            btnRequestFlightLevel1.show();
            btnRequestFlightLevel2.show();
            btnRequestFlightLevel3.show();
        }
        else
        {
            btnRequestFlightLevel1.hide();
            btnRequestFlightLevel2.hide();
            btnRequestFlightLevel3.hide();
        }
    }
}

var openATCDialog = func()
{
    if(isAtcEnabled() == 0)
    {
        showPopup(RGAtcName ~ " is not enabled.\nTurn it on from the menu");

        return;
    }

    if(initialized == 0)
        initRgATC();

    if(dlgWindow == nil or dialogInitialized == 0)
        initRgATCDialog();

    if(dlgWindow != nil and dialogInitialized == 1)
    {
        if(dialogOpened == 0)
        {
            dlgWindow.show();

            dlgWindow.clearFocus();

            setRGTitle();

            dialogOpened = 1;

            updateATC(update_dialog);

            updateRadioList();

            setApproachButtons();

            setCtrButtons();
        }
        else
            closeATCDialog();
    }
}

var closeATCDialog = func()
{
    if(initialized == 0)
        initRgATC();

    if(dlgWindow == nil or dialogInitialized == 0)
        initRgATCDialog();

    if(dialogInitialized == 1 and dialogOpened == 1 and dlgWindow != nil)
    {
        dlgWindow.hide();

        dialogOpened = 0;

        dlgWindow.clearFocus();
    }
}

var openAtcLogDialog = func()
{
    if(atcLogWindow == nil)
    {
        atcLogWindow = canvas.Window.new([320, 180], "dialog")
            .setTitle(RGAtcName ~ ": Log");

        var atcLogCanvas = atcLogWindow.createCanvas().set("background", canvas.style.getColor("bg_color"));
        atcLogCanvas.setColorBackground(0.4, 0.4, 0.4, 0.9);

        var atcLogRoot = atcLogCanvas.createGroup();

        var atcLogLayout = canvas.VBoxLayout.new();

        atcLogCanvas.setLayout(atcLogLayout);

        atcLogScroll = canvas.gui.widgets.ScrollArea.new(atcLogRoot, canvas.style, {});
        atcLogScroll.setColorBackground(1.0, 1.0, 0.9, 0.9);
        atcLogScroll.setFixedSize(320, 148);

        atcLogLayout.addItem(atcLogScroll, 1);

        atcLogScrollContent = atcLogScroll.getContent()
                    .set("font", "LiberationFonts/LiberationSans-Bold.ttf")
                    .set("character-size", 16)
                    .set("alignment", "left-center");

        txtAtcLog = canvas.gui.widgets.Label.new(atcLogScrollContent, canvas.style, {});

        var btnClear = canvas.gui.widgets.Button.new(atcLogRoot, canvas.style, {})
                .setText("Clear")
                .setFixedSize(75, 26);

        btnClear.listen("clicked", func
        {
            clearAtcLog();
        });

        var btnClose = canvas.gui.widgets.Button.new(atcLogRoot, canvas.style, {})
                .setText("Close")
                .setFixedSize(75, 26);

        btnClose.listen("clicked", func
        {
            atcLogWindow.hide();
            
            atcLogOpened = 0;
        });
    
        var buttonBox = canvas.HBoxLayout.new();

        buttonBox.addStretch(1);
        buttonBox.addItem(btnClear);
        buttonBox.addStretch(1);
        buttonBox.addItem(btnClose);
        buttonBox.addStretch(1);

        atcLogLayout.addStretch(1);
        atcLogLayout.addItem(buttonBox);
    }
    else
        atcLogWindow.show();

    atcLogOpened = 1;

    txtAtcLog.setText(atcLogText);

    atcLogWindow.raise(1);

    atcLogScroll.scrollTo(0, 32768);

    atcLogWindow.clearFocus();
}

var addAtcLog = func(text)
{
    rowlen = 45;

    text = string.replace(text, "\n", " ");
    var word = split(" ", text);
    var wlen = size(word);
    var row = property_TimeGmtString.getValue() ~ "Z: ";

    for(var i = 0; i < wlen; i += 1)
    {
        if(size(row) + size(word[i]) <= rowlen)
            row ~= word[i] ~ " ";
        else
        {
            atcLogText ~= row ~ "\n";
            
            row = word[i] ~ " ";
        }
    }

    atcLogText ~= row ~ "\n\n";

    if(txtAtcLog != nil)
        txtAtcLog.setText(atcLogText);
    
    if(atcLogOpened == 1 and atcLogWindow != nil and atcLogScroll != nil)
        atcLogScroll.scrollTo(0, 32768);
}

var clearAtcLog = func()
{
    atcLogText = "\n";

    if(txtAtcLog != nil)
        txtAtcLog.setText(atcLogText);
    
    if(atcLogOpened == 1 and atcLogWindow != nil and atcLogScroll != nil)
        atcLogScroll.scrollTo(0, 32768);
}

var updateATC = func(update_mode)
{
    var type = nil;
    var aircraftPosition = "";
    var txt = "";
    var degTag = "°";
    var popupText = RGAtcTitle ~ "\n\n";

    if(update_mode == update_dialog)
        degTag = "°";
    else
        degTag = "�";

    if(property_COM1_Serviceable != nil)
    {
        if(property_COM1_Quality != nil)
            com1quality = property_COM1_Quality.getValue();
        else
            com1quality = 5;

        com1volume = getRadioVolume(property_COM1_Volume, property_COM1_VolumeSelected);

        com1serviceable = property_COM1_Serviceable.getValue();

        if(property_COM1_PowerButton != nil)
            com1PowerStatus = property_COM1_PowerButton.getValue();
        else
            com1PowerStatus = 1;

        if(property_COM1_Operable != nil)
            com1Operable = property_COM1_Operable.getValue();
        else
            com1Operable = 1;
    }
    else
    {
        com1quality = 0;
        com1volume = 0;
        com1serviceable = 0;
        com1PowerStatus = 0;
        com1Operable = 0;
    }

    if(property_COM2_Serviceable != nil)
    {
        if(property_COM2_Quality != nil)
            com2quality = property_COM2_Quality.getValue();
        else
            com2quality = 5;

        com2volume = getRadioVolume(property_COM2_Volume, property_COM2_VolumeSelected);

        com2serviceable = property_COM2_Serviceable.getValue();

        if(property_COM2_PowerButton != nil)
            com2PowerStatus = property_COM2_PowerButton.getValue();
        else
            com2PowerStatus = 1;

        if(property_COM2_Operable != nil)
            com2Operable = property_COM2_Operable.getValue();
        else
            com2Operable = 1;
    }
    else
    {
        com2quality = 0;
        com2volume = 0;
        com2serviceable = 0;
        com2PowerStatus = 0;
        com2Operable = 0;
    }

    if(property_COM3_Serviceable != nil)
    {
        if(property_COM3_Quality != nil)
            com3quality = property_COM3_Quality.getValue();
        else
            com3quality = 5;

        com3volume = getRadioVolume(property_COM3_Volume, property_COM3_VolumeSelected);

        com3serviceable = property_COM3_Serviceable.getValue();

        if(property_COM3_PowerButton != nil)
            com3PowerStatus = property_COM3_PowerButton.getValue();
        else
            com3PowerStatus = 1;

        if(property_COM3_Operable != nil)
            com3Operable = property_COM3_Operable.getValue();
        else
            com3Operable = 1;
    }
    else
    {
        com3quality = 0;
        com3volume = 0;
        com3serviceable = 0;
        com3PowerStatus = 0;
        com3Operable = 0;
    }

    if(com1serviceable == 1 and com1PowerStatus == 1 and com1Operable == 1 and (atcRadioMode == "Auto" or atcRadioMode == "COM1"))
    {
        if(property_COM1_StationName != nil)
            selectedComStationType = getRadioType(property_COM1_StationName.getValue());
        else
        {
            selectedComStationType = radio_station_type_unknown;
            com1serviceable = 0;
        }

        if(property_COM1_AirportID != nil)
            selectedComAirportId = property_COM1_AirportID.getValue();
        else
        {
            selectedComAirportId = "";
            com1serviceable = 0;
        }

        if(property_COM1_StationName != nil)
        {
            if(selectedComAirportId != "")
                selectedComStationName = getRadioFullName(selectedComAirportId, property_COM1_StationName.getValue());
            else
                selectedComStationName = property_COM1_StationName.getValue();
        }
        else
        {
            selectedComStationName = "";
            com1serviceable = 0;
        }

        selectedComFrequency = getRadioFrequency(property_COM1_Frequency, property_COM1_RealFrequency);

        if(selectedComFrequency <= 0)
            com1serviceable = 0;

        if(property_COM1_Distance != nil)
            selectedComStationDistance = property_COM1_Distance.getValue();
        else
        {
            selectedComStationDistance = "";
            com1serviceable = 0;
        }

        if(property_COM1_Bearing != nil)
            selectedComStationBearing = property_COM1_Bearing.getValue();
        else
        {
            selectedComStationBearing = "";
            com1serviceable = 0;
        }

        if(com1serviceable == 1)
        {
            selectedComRadio = "COM1";

            selectedComSignalQuality = com1quality;
            selectedComVolume = com1volume;
            selectedComServiceable = com1serviceable;
            selectedComServiceableProperty = property_COM1_Serviceable;
            selectedComPowerStatus = com1PowerStatus;
            selectedComOperable = com1Operable;
        }
        else
        {
            selectedComRadio = "";

            selectedComServiceableProperty = nil;

            selectedComSignalQuality = 0;
        }
    }
    else if(com2serviceable == 1 and com2PowerStatus == 1 and com2Operable == 1 and (atcRadioMode == "Auto" or atcRadioMode == "COM2"))
    {
        if(property_COM2_StationName != nil)
            selectedComStationType = getRadioType(property_COM2_StationName.getValue());
        else
        {
            selectedComStationType = radio_station_type_unknown;
            com2serviceable = 0;
        }

        if(property_COM2_AirportID != nil)
            selectedComAirportId = property_COM2_AirportID.getValue();
        else
        {
            selectedComAirportId = "";
            com2serviceable = 0;
        }

        if(property_COM2_StationName != nil)
        {
            if(selectedComAirportId != "")
                selectedComStationName = getRadioFullName(selectedComAirportId, property_COM2_StationName.getValue());
            else
                selectedComStationName = property_COM2_StationName.getValue();
        }
        else
        {
            selectedComStationName = "";
            com2serviceable = 0;
        }

        selectedComFrequency = getRadioFrequency(property_COM2_Frequency, property_COM2_RealFrequency);

        if(selectedComFrequency <= 0)
            com2serviceable = 0;

        if(property_COM2_Distance != nil)
            selectedComStationDistance = property_COM2_Distance.getValue();
        else
        {
            selectedComStationDistance = "";
            com2serviceable = 0;
        }

        if(property_COM2_Bearing != nil)
            selectedComStationBearing = property_COM2_Bearing.getValue();
        else
        {
            selectedComStationBearing = "";
            com2serviceable = 0;
        }

        if(com2serviceable == 1)
        {
            selectedComRadio = "COM2";

            selectedComSignalQuality = com2quality;
            selectedComVolume = com2volume;
            selectedComServiceable = com2serviceable;
            selectedComServiceableProperty = property_COM2_Serviceable;
            selectedComPowerStatus = com2PowerStatus;
            selectedComOperable = com2Operable;
        }
        else
        {
            selectedComRadio = "";

            selectedComServiceableProperty = nil;

            selectedComSignalQuality = 0;
        }
    }
    else if(com3serviceable == 1 and com3PowerStatus == 1 and com3Operable == 1 and (atcRadioMode == "Auto" or atcRadioMode == "COM3"))
    {
        if(property_COM3_StationName != nil)
            selectedComStationType = getRadioType(property_COM3_StationName.getValue());
        else
        {
            selectedComStationType = radio_station_type_unknown;
            com3serviceable = 0;
        }

        if(property_COM3_AirportID != nil)
            selectedComAirportId = property_COM3_AirportID.getValue();
        else
        {
            selectedComAirportId = "";
            com3serviceable = 0;
        }

        if(property_COM3_StationName != nil)
        {
            if(selectedComAirportId != "")
                selectedComStationName = getRadioFullName(selectedComAirportId, property_COM3_StationName.getValue());
            else
                selectedComStationName = property_COM3_StationName.getValue();
        }
        else
        {
            selectedComStationName = "";
            com3serviceable = 0;
        }

        selectedComFrequency = getRadioFrequency(property_COM3_Frequency, property_COM3_RealFrequency);

        if(selectedComFrequency <= 0)
            com3serviceable = 0;

        if(property_COM3_Distance != nil)
            selectedComStationDistance = property_COM3_Distance.getValue();
        else
        {
            selectedComStationDistance = "";
            com3serviceable = 0;
        }

        if(property_COM3_Bearing != nil)
            selectedComStationBearing = property_COM3_Bearing.getValue();
        else
        {
            selectedComStationBearing = "";
            com3serviceable = 0;
        }

        if(com3serviceable == 1)
        {
            selectedComRadio = "COM3";

            selectedComSignalQuality = com3quality;
            selectedComVolume = com3volume;
            selectedComServiceable = com3serviceable;
            selectedComServiceableProperty = property_COM3_Serviceable;
            selectedComPowerStatus = com3PowerStatus;
            selectedComOperable = com3Operable;
        }
        else
        {
            selectedComRadio = "";

            selectedComServiceableProperty = nil;

            selectedComSignalQuality = 0;
        }
    }
    else
    {
        selectedComSignalQuality = 0;
        selectedComAirportId = "";
        selectedComStationName = "";
        selectedComFrequency = 0;
        selectedComStationDistance = "";
        selectedComStationBearing = "";

        if(property_COM1_Serviceable != nil)
        {
            selectedComRadio = "COM1";
            selectedComVolume = com1volume;
            selectedComServiceable = com1serviceable;
            selectedComServiceableProperty = property_COM1_Serviceable;
            selectedComPowerStatus = com1PowerStatus;
            selectedComOperable = com1Operable;
        }
        else
        {
            selectedComRadio = "";
            selectedComVolume = "";
            selectedComServiceable = 0;
            selectedComServiceableProperty = nil;
            selectedComPowerStatus = 0;
            selectedComOperable = 0;
        }
    }

    if(selectedComStationType != radio_station_type_unknown)
        selectedComStationName = normalizeRadioStationName(selectedComStationName);
    else
        selectedComStationName = atcMessageAction.unknown_radio_type;

    if(selectedComAirportId == "")
        selectedComAirportId = atcMessageAction.bad_airport_radio;

    if(selectedComFrequency <= 0)
        selectedComFrequency = 999.99;

    if(selectedComStationDistance == "")
        selectedComStationDistance = 9999;

    if(selectedComStationBearing == "")
        selectedComStationBearing = 999;

    selectedTransponder = getOperatingTransponder();

    var pos = geo.aircraft_position();

    var range = min_airport_range;

    if(currentCtr != nil)
        range += int((currentCtr.range / 1.5) / 10);

    if(update_mode == update_dialog)
        setCtrButtons();

    var airport = findAirportsWithinRange(pos, range);
    var altitude = property_Aircraft_AltitudeAglFeet.getValue();

    if(size(airport) > 0 and aircraft_status != status_requested_approach and aircraft_status != status_requested_ils)
    {
        if(update_mode == update_dialog)
            txtAirport.setText(airport[0].id ~ " " ~ airport[0].name);
        else if(update_mode == update_popup)
            popupText ~= airport[0].id ~ " " ~ airport[0].name ~ "\n";

        var aPos = getPositionInAirport(airport[0], pos);

        if(aPos == position_ground)
        {
            aircraftPosition = "Ground";

            if(aircraft_status == status_cleared_for_land_approach or aircraft_status == status_cleared_for_land_ils)
            {
                aircraft_status = status_landed;

                cancelAtcPendingMessage();

                setAtcAutoCallbackAfterSeconds(welcome_airport_secs);
            }
            else if(aircraft_status != status_landed and aircraft_status != status_cleared_for_takeoff)
                aircraft_status = status_going_around;

            assignedAltitude = -1;
        }
        else if(aPos == position_flying)
        {
            aircraftPosition = "Flying over";
            airportRunwayInUse = "";
            airportRunwayInUseILS = "";

            if(aircraft_status == status_cleared_for_takeoff)
            {
                aircraft_status = status_took_off;
                flight_time_seconds = 0;

                cancelAtcPendingMessage();

                setAtcAutoCallbackAfterSeconds(wait_after_take_off);
            }
            else if(aircraft_status == status_going_around)
                aircraft_status = status_flying;
        }
        else if(aPos == position_runway)
            aircraftPosition = "Runway " ~ currentRunway;
        else
            aircraftPosition = "???";

        if(aPos == position_runway)
        {
            atcMessageType[0] = message_none;
            atcMessageType[1] = message_none;
            atcMessageType[2] = message_none;
            atcMessageType[3] = message_none;

            if(nearRunway == 1)
            {
                aircraftPosition = "Near " ~ aircraftPosition;

                atcMessageType[0] = message_radio_check;
                atcMessageType[1] = message_departure_information;

                if(aircraft_status == status_cleared_for_takeoff)
                    atcMessageType[2] = message_abort_departure;
                else
                    atcMessageType[2] = message_ready_for_departure;

                atcMessageType[3] = message_none;
            }
            else if(alignedOnRunway == 1)
            {
                aircraftPosition ~= " - Aligned";

                atcMessageType[0] = message_radio_check;
                atcMessageType[1] = message_departure_information;

                if(aircraft_status == status_cleared_for_takeoff)
                    atcMessageType[2] = message_abort_departure;
                else
                    atcMessageType[2] = message_ready_for_departure;

                atcMessageType[3] = message_none;
            }
            else
            {
                aircraftPosition = aircraftPosition;

                atcMessageType[0] = message_radio_check;
                atcMessageType[1] = message_departure_information;
                atcMessageType[2] = message_request_taxi;

                if(aircraft_status == status_cleared_for_takeoff)
                    atcMessageType[3] = message_abort_departure;
                else
                    atcMessageType[3] = message_ready_for_departure;
            }

            if(aircraft_status == status_cleared_for_land_approach or aircraft_status == status_cleared_for_land_ils)
            {
                aircraft_status = status_landed;

                cancelAtcPendingMessage();

                setAtcAutoCallbackAfterSeconds(welcome_airport_secs);
            }

            assignedAltitude = -1;
        }
        else if(aPos == position_flying)
        {
            var approachingRunway = "";
            var distance = -1;
            var degreeDiff = 0;
            var turnToDiff = "";
            var posTag = "";
            var slopeCourseMarker = "";

            (approachingRunway, distance) = getApproachingRunway(currentAirport);

            if(approachingRunway != "")
            {
                var course = 0;
                var dist = 0;

                var alignPoint = geo.Coord.new().set_latlon(currentAirport.runways[approachingRunway].lat, currentAirport.runways[approachingRunway].lon);

                (course, dist) = courseAndDistance(alignPoint);

                alignPoint.apply_course_distance(currentAirport.runways[approachingRunway].heading, -(dist * NM2M));

                (course, dist) = courseAndDistance(alignPoint);

                (degreeDiff, turnToDiff) = degreesDifference(currentAirport.runways[approachingRunway].heading, course);

                dist = int(dist * NM2M);

                slopeCourseMarker = " [";
                altMarker = "";

                altSlope = altitudeApproachSlope(currentAirport.elevation, distance);
                altitudeFt = property_Aircraft_AltitudeFeet.getValue();

                altOk = 0;
                crsOk = 0;

                if(altitudeFt > altSlope)
                {
                    altMarker = "v";
                    altOk = 0;
                }
                else if(altitudeFt < altSlope)
                {
                    altMarker = "^";
                    altOk = 0;
                }
                else
                {
                    altMarker = "o";
                    altOk = 1;
                }

                if(dist > 3)
                {
                    if(dist > 60)
                        dist = 60;

                    if(turnToDiff == "left")
                        slopeCourseMarker ~= "<";
                    else
                        slopeCourseMarker ~= altMarker;

                    if(dist > 10)
                    {
                        for(var n = 0; n < dist; n += 30)
                            slopeCourseMarker ~= "=";
                    }

                    if(turnToDiff == "right")
                        slopeCourseMarker ~= ">";
                    else
                        slopeCourseMarker ~= altMarker;

                    crsOk = 0;
                }
                else
                {
                    slopeCourseMarker ~= altMarker;
                    crsOk = 1;
                }

                if(altOk == 1 and crsOk == 1)
                    slopeCourseMarker ~= "ok";

                slopeCourseMarker ~= "]";

                aircraftPosition = sprintf("APPR Runway %s%s DST %.1f nm AGL %.1f ft (%.1f m)", approachingRunway, slopeCourseMarker, distance, altitude, altitude * FT2M);
            }
            else
                aircraftPosition = sprintf("Flying over @ AGL %.1f ft (%.1f m)", altitude, altitude * FT2M);

            (airportRunwayInUse, airportRunwayInUseILS) = runwayInUse(airportinfo(selectedComAirportId), runway_landing);

            atcMessageType[0] = message_radio_check;
            atcMessageType[1] = message_request_approach;

            if(airportRunwayInUseILS != "")
            {
                atcMessageType[2] = message_request_ils;
                atcMessageType[3] = message_airfield_in_sight;
            }
            else
            {
                atcMessageType[2] = message_airfield_in_sight;
                atcMessageType[3] = message_none;
            }

            if(aircraft_status == status_cleared_for_takeoff)
            {
                aircraft_status = status_took_off;
                flight_time_seconds = 0;

                cancelAtcPendingMessage();

                setAtcAutoCallbackAfterSeconds(wait_after_take_off);
            }
        }
        else if(aPos == position_ground)
        {
            var speed = property_Aircraft_GroundSpeedKnots.getValue();

            aircraftPosition ~= sprintf(" @ %.1f kt (%.1f km/h)", speed, speed * KT2KMH);

            atcMessageType[0] = message_radio_check;
            atcMessageType[1] = message_departure_information;
            atcMessageType[2] = message_engine_start;
            atcMessageType[3] = message_request_taxi;
        }

        if(airportRunwayInUse != "" and aPos != position_flying)
            aircraftPosition ~= " - Departure runway " ~ airportRunwayInUse;

        if(update_mode == update_dialog)
            txtAircraftPosition.setText(aircraftPosition);
        else if(update_mode == update_popup)
            popupText ~= aircraftPosition ~ "\n\n";

        currentAirport = airport[0];

        if(update_mode == update_dialog)
        {
            btnAvailableRadio.setEnabled(1);

            if(selectedComAirportId != "" or currentCtr != nil)
                btnRequestCtr.setEnabled(1);
            else
                btnRequestCtr.setEnabled(0);
        }
    }
    else
    {
        var upperText = "";
        var bottomText = "";
        var altitude = property_Aircraft_AltitudeFeet.getValue();
        var airSpeed = property_Aircraft_AirSpeedKnots.getValue();

        if(patternPoint != nil and approachPoint != nil and (aircraft_status == status_requested_approach or aircraft_status == status_requested_ils))
        {
            var courseToPoint = nil;
            var distanceToPoint = 0;

            (courseToPoint, distanceToPoint) = courseAndDistance(patternPoint);

            upperText = sprintf("PTTN: HDG %d%s - DST %.2f nm - ALT %d ft", courseToPoint, degTag, distanceToPoint, altitude);

            (courseToPoint, distanceToPoint) = courseAndDistance(approachPoint);

            bottomText = sprintf("APPR: HDG %d%s - DST %.2f nm - IAS %d kt - Runway %s", courseToPoint, degTag, distanceToPoint, airSpeed, airportLandingRunway);
        }
        else
        {
            var agl = property_Aircraft_AltitudeAglFeet.getValue();
            var heading = property_Aircraft_HeadingDeg.getValue();
            var groundSpeed = property_Aircraft_GroundSpeedKnots.getValue();
            var mach = property_Aircraft_MachSpeed.getValue();

            upperText = sprintf("ALT %d ft (%d m) - AGL %d ft (%d m) - HDG %d%s", altitude, altitude * FT2M, agl, agl * FT2M, heading, degTag);
            bottomText = sprintf("IAS %d kt (%d km/h) - SPD %d kt (%d km/h) - Mach %.2f", airSpeed, airSpeed * KT2KMH, groundSpeed, groundSpeed * 1.852, mach);
        }

        if(update_mode == update_dialog)
        {
            if(txtAirport != nil)
                txtAirport.setText(upperText);

            if(txtAircraftPosition != nil)
                txtAircraftPosition.setText(bottomText);
        }
        else if(update_mode == update_popup)
            popupText ~= upperText ~ "\n" ~ bottomText ~ "\n\n";

        currentAirport = nil;
    }

    if(currentCtr != nil)
    {
        if(currentCtr.status != ctr_status_outside)
        {
            var frequency = 0;
            var ctrDistance = 0;
            var ctrStatus = "";

            txt = sprintf("CTR: %s %s", currentCtr.ident, currentCtr.airport);

            if(update_mode == update_dialog)
                txtCurrentCtr.setText(txt);
            else if(update_mode == update_popup)
                popupText ~= txt ~ "\n";

            var radio = getCtrRadio(currentCtr);

            if(radio != nil)
                frequency = radio.frequency;
            else
                frequency = 0;

            if(currentCtr.status == ctr_status_inside)
            {
                ctrDistance = currentCtr.distance;

                if(approvedCtr != nil and approvedCtr.ident == currentCtr.ident)
                    ctrStatus = "Approved";
                else
                    ctrStatus = "Inside";
            }
            else if(currentCtr.status == ctr_status_in_range)
            {
                ctrDistance = currentCtr.distance_from_range;
                ctrStatus = "Flying to";
            }

            txt = sprintf("RNG %d nm DST %.2f nm CRS %d%s - %.3f MHz - %s", currentCtr.range, ctrDistance, currentCtr.course, degTag, frequency, ctrStatus);

            if(update_mode == update_dialog)
                txtCurrentCtrSpecs.setText(txt);
            else if(update_mode == update_popup)
                popupText ~= txt ~ "\n\n";
        }
        else
        {
            if(update_mode == update_dialog)
            {
                txtCurrentCtr.setText("CTR: --");
                txtCurrentCtrSpecs.setText("--");
            }
            else if(update_mode == update_popup)
                popupText ~= "\nCTR: --\n\n";
        }
    }
    else
    {
        if(update_mode == update_dialog)
        {
            txtCurrentCtr.setText("CTR: --");
            txtCurrentCtrSpecs.setText("--");
        }
        else if(update_mode == update_popup)
            popupText ~= "\nCTR: --\n\n";
    }

    var aircraftPosition = "";

    if(radioSignalQuality() > 0 and selectedComVolume >= 0.1)
    {
        if(btnAvailableRadio != nil)
            btnAvailableRadio.setEnabled(1);

        if(selectedComAirportId != currentRadioStationId)
        {
            getAvailableRadios();

            radioListHasChanged = 1;

            currentRadioStationId = selectedComAirportId;

            (atcCallsignText, atcCallsignVoice) = getCallSignForAtc(1);

            showRepeatATCMessageButton(0);
        }

        if(altitude > min_ground_altitude)
        {
            (airportRunwayInUse, airportRunwayInUseILS) = runwayInUse(airportinfo(selectedComAirportId), runway_landing);

            atcMessageType[0] = message_radio_check;
            atcMessageType[1] = message_request_approach;

            if(aircraft_status == status_requested_ils or aircraft_status == status_cleared_for_land_ils)
            {
                atcMessageType[2] = message_request_ils;
                atcMessageType[3] = message_ils_established;
            }
            else
            {
                if(airportRunwayInUseILS != "")
                {
                    atcMessageType[2] = message_request_ils;
                    atcMessageType[3] = message_airfield_in_sight;
                }
                else
                {
                    atcMessageType[2] = message_airfield_in_sight;
                    atcMessageType[3] = message_none;
                }
            }
        }

        txt = sprintf("%s: %s %s", selectedComRadio, selectedComAirportId, selectedComStationName);

        if(update_mode == update_dialog)
            txtCurrentRadio.setText(txt);
        else if(update_mode == update_popup)
            popupText ~= txt ~ "\n";

        txt = sprintf("%.3f MHz - Distance: %.2f nm @ %d%s - Quality: %d", selectedComFrequency, selectedComStationDistance * M2NM , int(selectedComStationBearing), degTag, radioSignalQuality());

        if(update_mode == update_dialog)
            txtCurrentRadioSpecs.setText(txt);
        else if(update_mode == update_popup)
            popupText ~= txt ~ "\n";

        if(update_mode == update_dialog)
        {
            var wh = dialogHeight;
            var minCruiseAltidude = getMinCruiseAltitude();

            for(var i = 0; i < size(atcMessageType); i += 1)
            {
                if(atcMessageType[i] != message_none)
                {
                    wh += 32;

                    var btnTag = getMessageText(atcMessageType[i]);

                    if(btnTag != "")
                    {
                        btnMessage[i].setText(btnTag);

                        btnMessage[i].show();
                    }
                }
                else
                    btnMessage[i].hide();
            }

            if(radioListHasChanged == 1)
            {
                radioBox.show();

                updateRadioList();

                radioListHasChanged = 0;

                showRepeatATCMessageButton(0);
            }

            radioBox.show();

            if(aircraft_status == status_flying)
            {
                if(flightLevel1 >= minCruiseAltidude)
                {
                    btnRequestFlightLevel1.setText("FL" ~ getFlightLevelCode(flightLevel1));
                    btnRequestFlightLevel1.setEnabled(1);
                }
                else
                {
                    btnRequestFlightLevel1.setText("--");
                    btnRequestFlightLevel1.setEnabled(0);
                }

                if(flightLevel2 >= minCruiseAltidude)
                {
                    btnRequestFlightLevel2.setText("FL" ~ getFlightLevelCode(flightLevel2));
                    btnRequestFlightLevel2.setEnabled(1);
                }
                else
                {
                    btnRequestFlightLevel2.setText("--");
                    btnRequestFlightLevel2.setEnabled(0);
                }

                if(flightLevel3 >= minCruiseAltidude and flightLevel3 != flightLevel2)
                {
                    btnRequestFlightLevel3.setText("FL" ~ getFlightLevelCode(flightLevel3));
                    btnRequestFlightLevel3.setEnabled(1);
                }
                else
                {
                    btnRequestFlightLevel3.setText("--");
                    btnRequestFlightLevel3.setEnabled(0);
                }
            }
            else
            {
                btnRequestFlightLevel1.setText("--");
                btnRequestFlightLevel1.setEnabled(0);

                btnRequestFlightLevel2.setText("--");
                btnRequestFlightLevel2.setEnabled(0);

                btnRequestFlightLevel3.setText("--");
                btnRequestFlightLevel3.setEnabled(0);
            }

            if(dialogInitialized == 1 and dialogOpened == 1 and dlgWindow != nil)
                dlgWindow.setSize(dialogWidth, wh);
        }
        else if(update_mode == update_popup)
        {
            var minCruiseAltidude = getMinCruiseAltitude();

            for(var i = 0; i < size(atcMessageType); i += 1)
            {
                if(atcMessageType[i] != message_none)
                    popupText ~= sprintf("\n<ctrl+%d> %s", i+4, getMessageText(atcMessageType[i]));
            }

            if(lastAtcText != "" or lastAtcVoice != "")
                popupText ~= "\n<ctrl+9> Repeat last ATC message";

            popupText ~= "\n<ctrl+0> Request CTR";

            if(aircraft_status == status_flying)
            {
                popupText ~= "\n";

                if(flightLevel1 >= minCruiseAltidude)
                    popupText ~= "<ctrl+shift+4> Request FL" ~ getFlightLevelCode(flightLevel1) ~ "\n";

                if(flightLevel2 >= minCruiseAltidude)
                    popupText ~= "<ctrl+shift+5> Request FL" ~ getFlightLevelCode(flightLevel2) ~ "\n";

                if(flightLevel3 >= minCruiseAltidude and flightLevel3 != flightLevel2)
                    popupText ~= "<ctrl+shift+6> Request FL" ~ getFlightLevelCode(flightLevel3) ~ "\n";
            }
            else if(aircraft_status == status_requested_approach)
                popupText ~= "\n<ctrl+shift+0> Abort Approach";
            else if(aircraft_status == status_requested_ils)
                popupText ~= "\n<ctrl+shift+0> Abort ILS";
            else if(aircraft_status == status_cleared_for_land_approach or aircraft_status == status_cleared_for_land_ils)
                popupText ~= "\n<ctrl+shift+0> Abort Landing";

            showPopup(popupText);
        }
    }
    else
    {
        if(selectedComServiceableProperty == nil)
            txt = atcMessageAction.bad_radio_data;
        else if(selectedComServiceable == 0 or selectedComPowerStatus == 0 or selectedComOperable == 0)
            txt = atcMessageAction.turn_radio_on;
        else if(selectedComVolume < 0.1)
        {
            if(selectedComRadio != "")
                txt = selectedComRadio ~ ": ";
            else
                txt = "";

            txt ~= atcMessageAction.radio_volume_up;
        }
        else if(radioSignalQuality() == 0)
        {
            if(selectedComRadio != "")
                txt = selectedComRadio ~ ": ";
            else
                txt = "";

            txt ~= atcMessageAction.no_radio_tuned;
        }
        else
            txt = atcMessageAction.bad_radio_data;

        if(update_mode == update_dialog)
            txtCurrentRadio.setText(txt);
        else if(update_mode == update_popup)
            popupText ~= txt ~ "\n";

        if(update_mode == update_dialog)
        {
            txtCurrentRadioSpecs.setText("--");

            btnRequestFlightLevel1.setText("--");
            btnRequestFlightLevel1.setEnabled(0);

            btnRequestFlightLevel2.setText("--");
            btnRequestFlightLevel2.setEnabled(0);

            btnRequestFlightLevel3.setText("--");
            btnRequestFlightLevel3.setEnabled(0);
        }

        selectedComStationType = radio_station_type_unknown;

        if(update_mode == update_dialog)
            clearATCButtons();
        else if(update_mode == update_popup)
            showPopup(popupText);

        if(radioBox != nil)
            radioBox.hide();

        getAvailableRadios();

        radioListHasChanged = 1;

        (atcCallsignText, atcCallsignVoice) = getCallSignForAtc(1);

        showRepeatATCMessageButton(0);
    }

    if(dialogInitialized == 1 and dialogOpened == 1 and dlgWindow != nil)
        dlgWindow.clearFocus();
    
    if(atcLogOpened == 1 and atcLogWindow != nil)
        atcLogWindow.clearFocus();
}

var getPositionInAirport = func(airport, pos)
{
    var distance = 9999;
    var course = 0;
    var dist = 0;
    var runwayPos = 0;
    var position = position_ground;
    var degreeDiff = 360;
    var turnToDiff = "";

    currentRunway = "";
    alignedOnRunway = 0;
    nearRunway = 0;

    if(airport == nil)
        return position_unknown;

    if(property_Aircraft_AltitudeAglFeet.getValue() > min_ground_altitude)
        return position_flying;

    if(size(airport.runways) > 0)
    {
        var aircraftHeading = property_Aircraft_HeadingDeg.getValue();

        foreach(var runway; keys(airport.runways))
        {
            min_distance = airport.runways[runway].width * 1.5;
            min_near_distance = min_distance + airport.runways[runway].width * 2;
            var angleDeviation = abs(airport.runways[runway].heading - aircraftHeading);

            runwayPos = geo.Coord.new().set_latlon(airport.runways[runway].lat, airport.runways[runway].lon);
            runwayLength = airport.runways[runway].length;

            if(airport.runways[runway].stopway > 0)
            {
                runwayPos.apply_course_distance(airport.runways[runway].heading, -airport.runways[runway].stopway);
                runwayLength += airport.runways[runway].stopway;
            }

            if(airport.runways[runway].threshold > 0)
            {
                runwayPos.apply_course_distance(airport.runways[runway].heading, -airport.runways[runway].threshold);
                runwayLength += airport.runways[runway].threshold;
            }

            if(airport.runways[runway].reciprocal.stopway > 0)
            {
                runwayPos.apply_course_distance(airport.runways[runway].heading, -airport.runways[runway].reciprocal.stopway);
                runwayLength += airport.runways[runway].reciprocal.stopway;
            }

            if(airport.runways[runway].reciprocal.threshold > 0)
            {
                runwayPos.apply_course_distance(airport.runways[runway].heading, -airport.runways[runway].reciprocal.threshold);
                runwayLength += airport.runways[runway].reciprocal.threshold;
            }

            dist = minPathDistance(pos, runwayPos, airport.runways[runway].heading, runwayLength / 2, min_distance);

            if(dist < min_near_distance)
            {
                position = position_runway;
                currentRunway = runway;
                nearRunway = 1;
            }

            if(dist < min_distance and dist < distance)
            {
                distance = dist;
                position = position_runway;
                currentRunway = runway;
                nearRunway = 0;
            }
        }

        if(position == position_runway)
        {
            (degreeDiff, turnToDiff) = degreesDifference(aircraftHeading, airport.runways[currentRunway].heading);

            if(degreeDiff < max_runway_alignment_degrees)
                alignedOnRunway = 1;
            else
                alignedOnRunway = 0;
        }
    }

    return position;
}

var runwayInUse = func(airport, runway_type)
{
    var degreesBest = 360;
    var lengthBest = 0;
    var degreeDiff = 360;
    var turnToDiff = "";

    var windDirection = 0;

    if(isRealMeteoEnabled() == 1)
    {
        if(property_Weather_Metar_WindDirectionDeg != nil)
            windDirection = property_Weather_Metar_WindDirectionDeg.getValue();
        else
            windDirection = 0;
    }
    else
    {
        if(property_Weather_WindDirectionDeg != nil)
            windDirection = property_Weather_WindDirectionDeg.getValue();
        else
            windDirection = 0;
    }

    var atcRunway = property_AtcRunway.getValue();

    if(airport == nil)
        return ["", nil];

    airportRunway = "";
    airportRunwayILS = "";

    if(property_Autopilot_RouteManagerActive.getValue() and property_Autopilot_RouteManagerDepartureRunway.getValue() != "" and runway_type == runway_take_off)
    {
        airportRunway = property_Autopilot_RouteManagerDepartureRunway.getValue();
    }
    else if(atcRunway != "" and airport.runways[atcRunway] != nil)
    {
        airportRunway = atcRunway;

        if(airport.runways[airportRunway].ils_frequency_mhz != nil)
            airportRunwayILS = airport.runways[airportRunway].id;
    }
    else
    {
        foreach(var runway; keys(airport.runways))
        {
            var runwayDeg = airport.runways[runway].heading;
            (degreeDiff, turnToDiff) = degreesDifference(runwayDeg, windDirection);

            if(degreeDiff < degreesBest or (degreeDiff == degreesBest and airport.runways[runway].length > lengthBest))
            {
                airportRunway = airport.runways[runway].id;

                degreesBest = degreeDiff;

                lengthBest = airport.runways[runway].length;
            }
        }
    }

    if(airportRunwayILS == "")
    {
        degreesBest = 360;
        lengthBest = 0;
        degreeDiff = 360;

        foreach(var runway; keys(airport.runways))
        {
            var runwayDeg = airport.runways[runway].heading;
            (degreeDiff, turnToDiff) = degreesDifference(runwayDeg, windDirection);

            if(airport.runways[runway].ils_frequency_mhz != nil and (degreeDiff < degreesBest or (degreeDiff == degreesBest and airport.runways[runway].length > lengthBest)))
            {
                airportRunwayILS = airport.runways[runway].id;

                degreesBest = degreeDiff;

                lengthBest = airport.runways[runway].length;
            }
        }
    }

    return [airportRunway, airportRunwayILS];
}

var getApproachingRunway = func(airport)
{
    var degreesBest = 360;
    var lengthBest = 0;
    var heading = property_Aircraft_HeadingDeg.getValue();
    var approachingRunway = "";
    var distance = 9999;
    var degreeDiff = 0;
    var turnToDiff = "";
    var runwayPos = nil;
    var runwayVector = nil;

    if(airport == nil)
        return ["", 0];

    foreach(var runway; keys(airport.runways))
    {
        if(courseWithinDegrees(heading, airport.runways[runway].heading, max_runway_align_angle) == 1)
        {
            runwayPos = geo.Coord.new().set_latlon(airport.runways[runway].lat, airport.runways[runway].lon);

            if(airport.runways[runway].stopway > 0)
                runwayPos.apply_course_distance(airport.runways[runway].heading, -airport.runways[runway].stopway);

            if(airport.runways[runway].threshold > 0)
                runwayPos.apply_course_distance(airport.runways[runway].heading, -airport.runways[runway].threshold);

            if(airport.runways[runway].reciprocal.stopway > 0)
                runwayPos.apply_course_distance(airport.runways[runway].heading, -airport.runways[runway].reciprocal.stopway);

            if(airport.runways[runway].reciprocal.threshold > 0)
                runwayPos.apply_course_distance(airport.runways[runway].heading, -airport.runways[runway].reciprocal.threshold);

            (course, dist) = courseAndDistance(runwayPos);

            if(courseWithinDegrees(heading, course, max_runway_align_angle) == 1)
            {
                runwayVector = runwayPos;

                runwayVector.apply_course_distance(airport.runways[runway].heading, -(dist * NM2M));

                (courseVector, distVector) = courseAndDistance(runwayVector);

                if(distVector < distance)
                {
                    distance = distVector;

                    approachingRunway = runway;
                }
            }
        }
    }

    return [approachingRunway, distance];
}

var clearATCButtons = func()
{
    if(btnMessage[0] == nil)
        return;

    btnMessage[0].hide();
    btnMessage[1].hide();
    btnMessage[2].hide();
    btnMessage[3].hide();

    if(dialogInitialized == 1 and dialogOpened == 1 and dlgWindow != nil)
        dlgWindow.setSize(dialogWidth, dialogHeight);
}

var showRepeatATCMessageButton = func(enable)
{
    var w = (dialogWidth / 2) - 20;

    if(btnRepeatATCMessage != nil)
    {
        if(enable == 1)
        {
            btnRepeatATCMessage.show();

            w = (dialogWidth / 2) - 28 - repeatBtnWidth;
        }
        else
        {
            lastAtcText = "";
            lastAtcVoice = "";

            btnRepeatATCMessage.hide();
        }
    }

    if(btnMessage[0] != nil)
        btnMessage[0].setFixedSize(w, 26);
}

var availableRadioDialog = func()
{
    if(size(availableRadio) == 0)
    {
        showPopup(RGAtcName ~ ": " ~ atcMessageAction.no_radio_available ~ ".");

        return;
    }

    if(selectedComStationType != radio_station_type_unknown and selectedComAirportId != "")
        airport = airportinfo(selectedComAirportId);
    else if(currentAirport != nil)
        airport = currentAirport;
    else
    {
        showPopup(RGAtcName ~ ": " ~ atcMessageAction.no_radio_available ~ ".");

        return;
    }

    var h = (size(availableRadio) * 14) + 120;

    var (width, height) = (320, h);

    var radioWindow = canvas.Window.new([width,height], "dialog")
        .setTitle(RGAtcName ~ ": Available Radios");

    var radioCanvas = radioWindow.createCanvas().set("background", canvas.style.getColor("bg_color"));
    radioCanvas.setColorBackground(0.4, 0.4, 0.4, 0.9);

    var radioRoot = radioCanvas.createGroup();

    var radioLayout = canvas.VBoxLayout.new();

    radioCanvas.setLayout(radioLayout);

    var btnRadioClose = canvas.gui.widgets.Button.new(radioRoot, canvas.style, {})
	    .setText("Close")
	    .setFixedSize(75, 26);

    btnRadioClose.listen("clicked", func
    {
        radioWindow.hide();
    });

    radioLayout.addStretch(1);
    radioLayout.addItem(btnRadioClose);

    var txtAirport = radioRoot.createChild("text")
      .setText(airport.name)
      .setFont("LiberationFonts/LiberationSans-Bold.ttf")
      .setFontSize(14, 0.9)
      .setColor(1, 1, 1, 1)
      .setAlignment("left-center")
      .setTranslation(10, 20);

    var txtComTitle = radioRoot.createChild("text")
      .setText("Communication Radios")
      .setFont("LiberationFonts/LiberationSans-Bold.ttf")
      .setFontSize(14, 0.9)
      .setColor(1, 1, 0, 1)
      .setAlignment("left-center")
      .setTranslation(10, 48);

    var txtRadios = radioRoot.createChild("text")
      .setText("")
      .setFont("LiberationFonts/LiberationSans-Bold.ttf")
      .setFontSize(14, 0.9)
      .setColor(1, 1, 1, 1)
      .setAlignment("left")
      .setTranslation(10, 88);

    var radioDesc = "";
    var i = 0;

    for(i = 0; i < size(availableRadio); i += 1)
    {
        var radio = availableRadio[i];

	    radioDesc ~= sprintf("%s: %.3f MHz\n", radio.ident, radio.frequency);
    }

    txtRadios.setText(radioDesc);

    radioWindow.raise(1);

    radioWindow.clearFocus();
}

var updateRadioList = func()
{
    var vndx = 0;
    var voiceIsValid = 0;

    getAvailableRadios();

    numRadios = size(availableRadio);

    if(numRadios == 0)
        return;

    stationVoice = {};

    radioList = canvas.VBoxLayout.new();

    for(var i = 0; i < numRadios; i += 1)
    {
        var radio = availableRadio[i];

        radioButton[i] = canvas.gui.widgets.Button.new(radioScrollContent, canvas.style, {})
            .setText(sprintf("%s: %.3f MHz", radio.ident, radio.frequency))
            .setFixedSize((dialogWidth / 2) - 4, 24);

        radioButton[i].show();

        radioButtonFrequency[i] = radio.frequency;

        radioList.addItem(radioButton[i]);

        stationVoice[radio.frequency] = getSynthVoice(radio.frequency);
    }

    radioList.addStretch(1);

    radioScroll.setLayout(radioList);

    for(; i < max_radios; i += 1)
    {
        if(radioButton[i] != nil)
        {
            radioButton[i].hide();
            radioButton[i] = nil;
        }
    }

    if(numRadios > 0)
    {
        radioButton[0].listen("clicked", func()
        {
            setCurrentComRadioFrequency(radioButtonFrequency[0]);
        });
    }

    if(numRadios > 1)
    {
        radioButton[1].listen("clicked", func()
        {
            setCurrentComRadioFrequency(radioButtonFrequency[1]);
        });
    }

    if(numRadios > 2)
    {
        radioButton[2].listen("clicked", func()
        {
            setCurrentComRadioFrequency(radioButtonFrequency[2]);
        });
    }

    if(numRadios > 3)
    {
        radioButton[3].listen("clicked", func()
        {
            setCurrentComRadioFrequency(radioButtonFrequency[3]);
        });
    }

    if(numRadios > 4)
    {
        radioButton[4].listen("clicked", func()
        {
            setCurrentComRadioFrequency(radioButtonFrequency[4]);
        });
    }

    if(numRadios > 5)
    {
        radioButton[5].listen("clicked", func()
        {
            setCurrentComRadioFrequency(radioButtonFrequency[5]);
        });
    }

    if(numRadios > 6)
    {
        radioButton[6].listen("clicked", func()
        {
            setCurrentComRadioFrequency(radioButtonFrequency[6]);
        });
    }

    if(numRadios > 7)
    {
        radioButton[7].listen("clicked", func()
        {
            setCurrentComRadioFrequency(radioButtonFrequency[7]);
        });
    }

    if(numRadios > 8)
    {
        radioButton[8].listen("clicked", func()
        {
            setCurrentComRadioFrequency(radioButtonFrequency[8]);
        });
    }

    if(numRadios > 9)
    {
        radioButton[9].listen("clicked", func()
        {
            setCurrentComRadioFrequency(radioButtonFrequency[9]);
        });
    }

    if(numRadios > 10)
    {
        radioButton[10].listen("clicked", func()
        {
            setCurrentComRadioFrequency(radioButtonFrequency[10]);
        });
    }

    if(numRadios > 11)
    {
        radioButton[11].listen("clicked", func()
        {
            setCurrentComRadioFrequency(radioButtonFrequency[11]);
        });
    }

    if(numRadios > 12)
    {
        radioButton[12].listen("clicked", func()
        {
            setCurrentComRadioFrequency(radioButtonFrequency[12]);
        });
    }

    if(numRadios > 13)
    {
        radioButton[13].listen("clicked", func()
        {
            setCurrentComRadioFrequency(radioButtonFrequency[13]);
        });
    }

    if(numRadios > 14)
    {
        radioButton[14].listen("clicked", func()
        {
            setCurrentComRadioFrequency(radioButtonFrequency[14]);
        });
    }

    if(numRadios > 15)
    {
        radioButton[15].listen("clicked", func()
        {
            setCurrentComRadioFrequency(radioButtonFrequency[15]);
        });
    }

    if(numRadios > 16)
    {
        radioButton[16].listen("clicked", func()
        {
            setCurrentComRadioFrequency(radioButtonFrequency[16]);
        });
    }

    if(numRadios > 17)
    {
        radioButton[17].listen("clicked", func()
        {
            setCurrentComRadioFrequency(radioButtonFrequency[17]);
        });
    }

    if(numRadios > 18)
    {
        radioButton[18].listen("clicked", func()
        {
            setCurrentComRadioFrequency(radioButtonFrequency[18]);
        });
    }

    if(numRadios > 19)
    {
        radioButton[19].listen("clicked", func()
        {
            setCurrentComRadioFrequency(radioButtonFrequency[19]);
        });
    }

    if(numRadios > 20)
    {
        radioButton[20].listen("clicked", func()
        {
            setCurrentComRadioFrequency(radioButtonFrequency[20]);
        });
    }

    if(numRadios > 21)
    {
        radioButton[21].listen("clicked", func()
        {
            setCurrentComRadioFrequency(radioButtonFrequency[21]);
        });
    }

    if(numRadios > 22)
    {
        radioButton[22].listen("clicked", func()
        {
            setCurrentComRadioFrequency(radioButtonFrequency[22]);
        });
    }

    if(numRadios > 23)
    {
        radioButton[23].listen("clicked", func()
        {
            setCurrentComRadioFrequency(radioButtonFrequency[23]);
        });
    }

    if(numRadios > 24)
    {
        radioButton[24].listen("clicked", func()
        {
            setCurrentComRadioFrequency(radioButtonFrequency[24]);
        });
    }

    if(numRadios > 25)
    {
        radioButton[25].listen("clicked", func()
        {
            setCurrentComRadioFrequency(radioButtonFrequency[25]);
        });
    }

    if(numRadios > 26)
    {
        radioButton[26].listen("clicked", func()
        {
            setCurrentComRadioFrequency(radioButtonFrequency[26]);
        });
    }

    if(numRadios > 27)
    {
        radioButton[27].listen("clicked", func()
        {
            setCurrentComRadioFrequency(radioButtonFrequency[27]);
        });
    }

    if(numRadios > 28)
    {
        radioButton[28].listen("clicked", func()
        {
            setCurrentComRadioFrequency(radioButtonFrequency[28]);
        });
    }

    if(numRadios > 29)
    {
        radioButton[29].listen("clicked", func()
        {
            setCurrentComRadioFrequency(radioButtonFrequency[29]);
        });
    }
}

var setCurrentComRadioFrequency = func(frequency)
{
    if(selectedComRadio == "COM1")
    {
        if(property_COM1_RealFrequency != nil)
            property_COM1_RealFrequency.setValue(frequency);

        if(property_COM1_Frequency != nil)
            property_COM1_Frequency.setValue(frequency);
    }
    else if(selectedComRadio == "COM2")
    {
        if(property_COM2_RealFrequency != nil)
            property_COM2_RealFrequency.setValue(frequency);

        if(property_COM2_Frequency != nil)
            property_COM2_Frequency.setValue(frequency);
    }
    else if(selectedComRadio == "COM3")
    {
        if(property_COM3_RealFrequency != nil)
            property_COM3_RealFrequency.setValue(frequency);

        if(property_COM3_Frequency != nil)
            property_COM3_Frequency.setValue(frequency);
    }

    if(dialogInitialized == 1 and dialogOpened == 1 and dlgWindow != nil)
    {
        dlgWindow.clearFocus();

        showRepeatATCMessageButton(0);
    }
}

var showPopup = func(text)
{
    var window = screen.window.new(atc_popup_x_position, atc_popup_y_position, 20, 8);

    window.bg = popup_window_bg_color;
    window.fg = popup_window_fg_atc_color;
    window.align = atc_popup_align;

    window.write(text);
}

var lastAtcMessageReplyVariant = {};

var getAtcMessageReplyFormat = func(replyName)
{
    var variants = atcMessageReplyVariants[replyName];

    if(variants == nil or size(variants) == 0)
        return atcMessageReply[replyName];

    var variantCount = size(variants);
    var variantIndex = int(rand() * variantCount);
    var previousVariantIndex = lastAtcMessageReplyVariant[replyName];

    if(variantCount > 1 and previousVariantIndex != nil and variantIndex == previousVariantIndex)
        variantIndex = (variantIndex + 1) % variantCount;

    lastAtcMessageReplyVariant[replyName] = variantIndex;

    return variants[variantIndex];
}

var atcReplyToRequest = func(messageType)
{
    var text = "";
    var voice = "";
    var replyFormat = "";
    var signal = -1;
    var extraText = "";
    var extraVoice = "";
    var towerContactText = "";
    var towerContactVoice = "";
    var minCruiseAltidude = getMinCruiseAltitude();

    if(initialized == 0)
        initRgATC();

    if(isRadioServiceable() == 0)
        return;

    if(messageType == message_none or selectedComAirportId == "")
        return;

    multiplayMessageType = message_type_local;

    (atcCallsignText, atcCallsignVoice) = getCallSignForAtc(0);

    if(messageType == message_say_again)
    {
        if(lastAtcText == "" and lastAtcVoice == "")
            return;

        multiplayMessageType = message_type_local;

        text = lastAtcText;

        voice = lastAtcVoice;

        pilotResponseType = message_roger;
    }
    else if(messageType == message_radio_check)
    {
        multiplayMessageType = message_type_local;

        signal = radioSignalQuality();

        var atisRadio = getRadio(radio_station_type_atis, radio_type_exact_match);

        if(atisRadio != nil)
        {
            extraText = sprintf(atcMessageReply.radio_available_at,
                                "\nATIS",
                                sprintf("%.3f", atisRadio.frequency)
                            );

            extraVoice = sprintf(atcMessageReply.radio_available_at,
                                "\nA T I S",
                                spellToPhonetic(sprintf("%.3f", atisRadio.frequency), spell_number)
                            );
        }

        replyFormat = getAtcMessageReplyFormat("radio_check");

        text = sprintf(replyFormat,
                    atcCallsignText,
                    selectedComStationName,
                    sprintf("%d", signal),
                    extraText
               );

        voice = sprintf(replyFormat,
                    atcCallsignVoice,
                    selectedComStationName,
                    spellToPhonetic(sprintf("%d", signal), spell_number),
                    extraVoice
                );

        pilotResponseType = message_none;
    }
    else if(messageType == message_request_ctr)
    {
        var ctrData = getCtrData(airportinfo(selectedComAirportId));
        var radio = nil;

        multiplayMessageType = message_type_local;

        if(ctrData != nil)
        {
            radio = getCtrRadio(ctrData);

            if(radio != nil)
            {
                if(approvedCtr != nil and approvedCtr.ident == ctrData.ident)
                {
                    (text, voice) = getCtrAtcMessage(ctr_already_approved);

                    pilotResponseType = message_roger;
                }
                else if(ctrData.status == ctr_status_in_range or ctrData.status == ctr_status_inside)
                {
                    if(selectedComAirportId == ctrData.ident and selectedComFrequency == radio.frequency)
                    {
                        (text, voice) = getCtrAtcMessage(ctr_request_approved);

                        currentCtr = ctrData;
                        approvedCtr = ctrData;
                        ctr_leaving_warning = 0;
                        altitude_check_counter = 0;

                        altitude_change_wait_seconds = int(rand() * max_altitude_change_secs) + min_altitude_change_secs;
                        assignedAltitude = -1;
                        aircraftIsDeparting = 0;

                        resetAircraftStatus();

                        pilotResponseType = message_ctr_approved;
                    }
                    else
                    {
                        text = sprintf("%s, %s, ",
                                    atcCallsignText,
                                    selectedComStationName
                            );

                        voice = sprintf("%s, %s, ",
                                    atcCallsignVoice,
                                    selectedComStationName
                                );

                        text ~= sprintf(atcMessageReply.contact_radio,
                                    normalizeRadioStationName(radio.name),
                                    sprintf("%.3f", radio.frequency)
                                );

                        voice ~= sprintf(atcMessageReply.contact_radio,
                                    normalizeRadioStationName(radio.name),
                                    spellToPhonetic(sprintf("%.3f", radio.frequency), spell_number)
                                );


                        pilotResponseType = message_roger;
                    }
                }
                else
                {
                    (text, voice) = getCtrAtcMessage(ctr_request_denied);

                    assignedAltitude = -1;

                    pilotResponseType = message_roger;
                }
            }
            else
            {
                (text, voice) = getCtrAtcMessage(ctr_request_denied);

                assignedAltitude = -1;

                pilotResponseType = message_roger;
            }
        }
        else
        {
            (text, voice) = getCtrAtcMessage(ctr_request_denied);

            assignedAltitude = -1;

            pilotResponseType = message_roger;
        }

        setApproachButtons();

        setCtrButtons();
    }
    else if(messageType == message_engine_start)
    {
        if(checkRadioIsType(radio_station_type_ground) == 0)
            return;

        var airport = "";

        multiplayMessageType = message_type_local;

        if(property_Aircraft_AltitudeAglFeet.getValue() > min_ground_altitude)
        {
            text = sprintf(atcMessageReply.engine_start_while_airborne,
                        atcCallsignText,
                        selectedComStationName
                   );

            voice = sprintf(atcMessageReply.engine_start_while_airborne,
                        atcCallsignVoice,
                        selectedComStationName
                    );

            pilotResponseType = message_roger;
        }
        else if(selectedComAirportId == property_ClosestAirportId.getValue())
        {
            airport = airportinfo(selectedComAirportId);
            (airportRunwayInUse, airportRunwayInUseILS) = runwayInUse(airport, runway_take_off);

            (qnhValue, qnhLiteralValue) = getQNH();

            replyFormat = getAtcMessageReplyFormat("engine_start");

            text = sprintf(replyFormat,
                        atcCallsignText,
                        selectedComStationName,
                        airportRunwayInUse,
                        "QNH",
                        qnhValue
                   );

            voice = sprintf(replyFormat,
                        atcCallsignVoice,
                        selectedComStationName,
                        spellToPhonetic(airportRunwayInUse, spell_runway),
                        "Q N H",
                        qnhLiteralValue
                    );

            aircraftIsDeparting = 1;

            pilotResponseType = message_engine_start;
        }
        else
        {
            reason = " ";

            if(rand() < 0.5)
                reason ~= atcMessageAction.unable_approve;
            else
                reason ~= atcMessageAction.negative;

            reason ~= " " ~ atcMessageAction.startup ~ ".";

            text = sprintf(atcMessageReply.not_in_this_airfield,
                        atcCallsignText,
                        selectedComStationName,
                        reason
                   );

            voice = sprintf(atcMessageReply.not_in_this_airfield,
                        atcCallsignVoice,
                        selectedComStationName,
                        reason
                    );

            pilotResponseType = message_roger;
        }

        setApproachButtons();
    }
    else if(messageType == message_departure_information)
    {
        if(checkRadioIsType(radio_station_type_ground) == 0)
            return;

        var airport = "";

        multiplayMessageType = message_type_local;

        if(selectedComAirportId == property_ClosestAirportId.getValue())
        {
            airport = airportinfo(selectedComAirportId);
            (airportRunwayInUse, airportRunwayInUseILS) = runwayInUse(airport, runway_take_off);
            var currentTime = substr(property_TimeGmtString.getValue(), 0, 5) ~ "Z";

            if(selectedComAirportId != departureInformationAirport)
            {
                departureInformationAirport = selectedComAirportId;

                letter = chr(int(rand() * (size(phoneticLetter) - 1)) + 65);

                departureInformation = phoneticLetter[letter];
            }

            replyFormat = getAtcMessageReplyFormat("departure_information");

            text = sprintf(replyFormat,
                        atcCallsignText,
                        selectedComStationName,
                        airportRunwayInUse,
                        getMeteoText(meteo_type_full, 0),
                        currentTime,
                        departureInformation
                    );

            voice = sprintf(replyFormat,
                        atcCallsignVoice,
                        selectedComStationName,
                        spellToPhonetic(airportRunwayInUse, spell_runway),
                        getMeteoText(meteo_type_full, 1),
                        spellToPhonetic(currentTime, spell_number),
                        departureInformation
                    );

            pilotResponseType = message_departure_information;

            aircraftIsDeparting = 1;
        }
        else
        {
            text = sprintf(atcMessageReply.not_in_this_airfield,
                        atcCallsignText,
                        selectedComStationName,
                        ""
                   );

            voice = sprintf(atcMessageReply.not_in_this_airfield,
                        atcCallsignVoice,
                        selectedComStationName,
                        ""
                    );

            pilotResponseType = message_roger;
        }

        setApproachButtons();
    }
    else if(messageType == message_request_taxi)
    {
        if(checkRadioIsType(radio_station_type_ground) == 0)
            return;

        var airport = "";

        multiplayMessageType = message_type_important;

        if(property_Aircraft_AltitudeAglFeet.getValue() > min_ground_altitude)
        {
            text = sprintf(atcMessageReply.taxi_while_airborne,
                        atcCallsignText,
                        selectedComStationName
                   );

            voice = sprintf(atcMessageReply.taxi_while_airborne,
                        atcCallsignVoice,
                        selectedComStationName
                    );

            pilotResponseType = message_roger;
        }
        else if(selectedComAirportId == property_ClosestAirportId.getValue())
        {
            var towerRadio = getRadio(radio_station_type_tower, radio_type_any);
            var reportTag = "";
            var reportVoice = "";

            if(towerRadio == nil)
            {
                showPopup(RGAtcName ~ ": " ~ atcMessageAction.tower_not_reachable ~ ".");

                return;
            }

            if(selectedComFrequency == towerRadio.frequency)
            {
                reportTag = atcMessageReply.report_ready_departure;

                reportVoice = reportTag;
            }
            else
            {
                reportTag = sprintf(atcMessageAction.contact_when_ready,
                                        normalizeRadioStationName(towerRadio.name),
                                        sprintf("%.3f", towerRadio.frequency)
                            );

                reportVoice = sprintf(atcMessageAction.contact_when_ready,
                                        normalizeRadioStationName(towerRadio.name),
                                        spellToPhonetic(sprintf("%.3f", towerRadio.frequency), spell_number)
                              );
            }

            airport = airportinfo(selectedComAirportId);
            (airportRunwayInUse, airportRunwayInUseILS) = runwayInUse(airport, runway_take_off);

            extraText = "";
            extraVoice = "";

            if(squawkingMode == "On")
            {
                squawkCode = getSquawkCode();
                squawkChange = 1;

                extraText ~= sprintf(" Squawk %s.", squawkCode);
                extraVoice ~= sprintf(" Squawk %s.", spellToPhonetic(squawkCode, spell_number));

                setSquawkIdentMode(squawk_ident_off);
            }
            else
            {
                extraText = ".";
                extraVoice = ".";
            }

            if(departureInformation != "")
            {
                if(squawkingMode == "Off")
                {
                    extraText ~= ".";
                    extraVoice ~= ".";
                }

                extraText ~= sprintf("\nYou have information %s.",
                                departureInformation
                            );

                extraVoice ~= sprintf("\nYou have information %s.",
                                departureInformation
                            );
            }

            replyFormat = getAtcMessageReplyFormat("request_taxi");

            text = sprintf(replyFormat,
                        atcCallsignText,
                        selectedComStationName,
                        airportRunwayInUse,
                        reportTag,
                        extraText
                   );

            voice = sprintf(replyFormat,
                        atcCallsignVoice,
                        selectedComStationName,
                        spellToPhonetic(airportRunwayInUse, spell_runway),
                        reportVoice,
                        extraVoice
                    );

            aircraftIsDeparting = 1;

            pilotResponseType = message_request_taxi;
        }
        else
        {
            reason = " ";

            if(rand() < 0.5)
                reason ~= atcMessageAction.unable_approve;
            else
                reason ~= atcMessageAction.negative;

            reason ~= " " ~ atcMessageAction.taxi_request ~ ".";

            text = sprintf(atcMessageReply.not_in_this_airfield,
                        atcCallsignText,
                        selectedComStationName,
                        reason
                   );

            voice = sprintf(atcMessageReply.not_in_this_airfield,
                        atcCallsignVoice,
                        selectedComStationName,
                        reason
                    );

            pilotResponseType = message_roger;
        }

        setApproachButtons();
    }
    else if(messageType == message_ready_for_departure)
    {
        if(checkRadioIsType(radio_station_type_tower) == 0)
            return;

        var airport = nil;

        multiplayMessageType = message_type_important;

        if(selectedComAirportId == airportinfo().id)
        {
            airport = airportinfo(selectedComAirportId);
            (airportRunwayInUse, airportRunwayInUseILS) = runwayInUse(airport, runway_take_off);

            if(nearRunway == 1)
            {
                extraText = atcMessageAction.lineup_and_wait;
                extraVoice = atcMessageAction.lineup_and_wait;
            }
            else
            {
                extraText = "";
                extraVoice = "";
            }

            if(currentRunway == airportRunwayInUse and nearRunway == 0 and alignedOnRunway == 1)
            {
                replyFormat = getAtcMessageReplyFormat("ready_departure");

                text = sprintf(replyFormat,
                            atcCallsignText,
                            selectedComStationName,
                            extraText,
                            airportRunwayInUse
                       );

                voice = sprintf(replyFormat,
                            atcCallsignVoice,
                            selectedComStationName,
                            extraVoice,
                            spellToPhonetic(airportRunwayInUse, spell_runway)
                        );

                if(squawkingMode == "On" and squawkChange == 1)
                {
                    squawkCode = getSquawkCode();

                    text ~= sprintf(" Squawk %s.", squawkCode);

                    voice ~= sprintf(" Squawk %s.", spellToPhonetic(squawkCode, spell_number));

                    setSquawkIdentMode(squawk_ident_off);
                }

                aircraft_status = status_ready_for_departure;

                cancelAtcPendingMessage();

                setAtcAutoCallbackAfterSeconds(int(rand() * max_cleared_takeoff_secs) + min_cleared_takeoff_secs);

                pilotResponseType = message_wait_for_departure;
            }
            else if(currentRunway == airportRunwayInUse and nearRunway == 0 and alignedOnRunway == 0)
            {
                text = sprintf(atcMessageReply.align_for_departure,
                            atcCallsignText,
                            selectedComStationName,
                            airportRunwayInUse
                       );

                voice = sprintf(atcMessageReply.align_for_departure,
                            atcCallsignVoice,
                            selectedComStationName,
                            spellToPhonetic(airportRunwayInUse, spell_runway)
                        );

                pilotResponseType = message_roger;
            }
            else if(currentRunway != "" and currentRunway != airportRunwayInUse)
            {
                replyFormat = getAtcMessageReplyFormat("wrong_runway");

                text = sprintf(replyFormat,
                            atcCallsignText,
                            selectedComStationName,
                            airportRunwayInUse
                       );

                voice = sprintf(replyFormat,
                            atcCallsignVoice,
                            selectedComStationName,
                            spellToPhonetic(airportRunwayInUse, spell_runway)
                        );

                pilotResponseType = message_roger;
            }
            else
            {
                text = sprintf(atcMessageReply.hold_short_for_departure,
                            atcCallsignText,
                            selectedComStationName,
                            airportRunwayInUse
                       );

                voice = sprintf(atcMessageReply.hold_short_for_departure,
                            atcCallsignVoice,
                            selectedComStationName,
                            spellToPhonetic(airportRunwayInUse, spell_runway)
                        );

                pilotResponseType = message_roger;
            }

            aircraftIsDeparting = 1;
        }
        else
        {
            reason = " ";

            if(rand() < 0.5)
                reason ~= atcMessageAction.unable_approve;
            else
                reason ~= atcMessageAction.negative;

            reason ~= " " ~ atcMessageAction.departure_request ~ ".";

            text = sprintf(atcMessageReply.not_in_this_airfield,
                        atcCallsignText,
                        selectedComStationName,
                        reason
                   );

            voice = sprintf(atcMessageReply.not_in_this_airfield,
                        atcCallsignVoice,
                        selectedComStationName,
                        reason
                    );

            pilotResponseType = message_roger;
        }

        setApproachButtons();
    }
    else if(messageType == message_abort_departure)
    {
        if(checkRadioIsType(radio_station_type_tower) == 0)
            return;

        multiplayMessageType = message_type_important;

        airport = airportinfo(selectedComAirportId);
        (airportRunwayInUse, airportRunwayInUseILS) = runwayInUse(airport, runway_take_off);

        text = sprintf(atcMessageReply.abort_departure,
                    atcCallsignText,
                    selectedComStationName,
                    airportRunwayInUse
                );

        voice = sprintf(atcMessageReply.abort_departure,
                    atcCallsignVoice,
                    selectedComStationName,
                    spellToPhonetic(airportRunwayInUse, spell_runway)
                );

        aircraft_status = status_going_around;

        aircraftIsDeparting = 0;

        pilotResponseType = message_going_around;

        setApproachButtons();
    }
    else if(messageType == message_request_approach or messageType == message_request_ils)
    {
        var towerRadio = nil;
        var initialReportLetter = "R";
        var finalTurn = "";
        var ilsText = "";
        var ilsVoice = "";

        if(isRadioTunedToApprovedCtrRadio() == 0)
        {
            atcReplyToRequest(message_not_in_this_ctr);

            return;
        }

        if(checkRadioIsType(radio_station_type_approach) == 0)
            return;

        multiplayMessageType = message_type_important;

        if(approvedCtr != nil)
            airport = airportinfo(approvedCtr.ident);
        else
            airport = airportinfo(selectedComAirportId);

        (airportLandingRunway, airportRunwayInUseILS) = runwayInUse(airport, runway_landing);

        if(messageType == message_request_ils)
        {
            patternFormat = atcMessageReply.request_pattern_ils;
            approachFormat = atcMessageReply.request_ils;

            ilsText = "ILS";
            ilsVoice = "I L S";

            airportLandingRunway = airportRunwayInUseILS;
        }
        else
        {
            patternFormat = atcMessageReply.request_pattern_approach;
            approachFormat = atcMessageReply.request_approach;

            ilsText = "";
            ilsVoice = "";
        }

        var (courseToRunway, distanceToRunway) = courseAndDistance(airport.runways[airportLandingRunway]);

        approachPoint = geo.Coord.new().set_latlon(airport.runways[airportLandingRunway].lat,
                                                   airport.runways[airportLandingRunway].lon);

        approachPoint.apply_course_distance(airport.runways[airportLandingRunway].heading, approach_point_distance * NM2M);

        var heading = property_Aircraft_HeadingMagneticDeg.getValue();

        patternPoint = geo.Coord.new().set_latlon(approachPoint.lat(),
                                                  approachPoint.lon());

        if(geo.normdeg(courseToRunway - heading) < 180)
        {
            patternCircuit = atcMessageAction.right_tag;

            courseToApproachPoint = geo.normdeg(airport.runways[airportLandingRunway].heading - 90);
        }
        else
        {
            patternCircuit = atcMessageAction.left_tag;

            courseToApproachPoint = geo.normdeg(airport.runways[airportLandingRunway].heading + 90);
        }

        if(messageType == message_request_approach)
            finalTurn = patternCircuit;
        else
            finalTurn = "";

        patternPoint.apply_course_distance(courseToApproachPoint, pattern_point_distance * NM2M);

        var (courseToPattern, distanceToPattern) = courseAndDistance(patternPoint);
        var (courseToApproach, distanceToApproach) = courseAndDistance(approachPoint);

        airportElevation = airport.elevation * M2FT;

        approachAltitude = altitudeApproachSlope(airport.elevation, abs(approach_point_distance), 1);

        var cruiseAltitude = approachAltitude;

        var altitudeInstructionText = "";
        var altitudeInstructionVoice = "";

        if(distanceToPattern > min_distance_for_altitude_change)
        {
            var altSteps = int(distanceToPattern / miles_altitude_step);

            cruiseAltitude += (feet_altitude_step * altSteps);

            cruiseAltitude = normalizeAltitudeHeading(cruiseAltitude, courseToPattern, approachAltitude);

            if(property_Aircraft_AltitudeFeet.getValue() > cruiseAltitude)
                actionTag = atcMessageAction.descend;
            else
                actionTag = atcMessageAction.climb;

            altitudeInstructionText = sprintf(atcMessageAction.altitude_change,
                                                actionTag,
                                                sprintf("%d", cruiseAltitude)
                                      );

            altitudeInstructionVoice = sprintf(atcMessageAction.altitude_change,
                                                actionTag,
                                                spellToPhonetic(sprintf("%d", cruiseAltitude), spell_number_to_literal)
                                       );

            assignedAltitude = cruiseAltitude;

            altitude_check_interval = flightLevelChangeSeconds(assignedAltitude);
        }

        if(distanceToPattern < distanceToRunway or distanceToApproach < distanceToRunway)
        {
            # Route plane to runway approach point

            (courseToApproach, distanceToApproach) = courseAndDistance(approachPoint);

            text = sprintf(approachFormat,
                        atcCallsignText,
                        selectedComStationName,
                        altitudeInstructionText,
                        sprintf("%d", courseToApproach),
                        sprintf("%d", distanceToApproach),
                        finalTurn,
                        ilsText,
                        airportLandingRunway,
                        sprintf("%d", approachAltitude),
                        getMeteoText(meteo_type_qnh, 0)
                );

            voice = sprintf(approachFormat,
                        atcCallsignVoice,
                        selectedComStationName,
                        altitudeInstructionVoice,
                        spellToPhonetic(sprintf("%d", courseToApproach), spell_number),
                        spellToPhonetic(sprintf("%d", distanceToApproach), spell_number_to_literal),
                        finalTurn,
                        ilsVoice,
                        spellToPhonetic(airportLandingRunway, spell_runway),
                        spellToPhonetic(sprintf("%d", approachAltitude), spell_number_to_literal),
                        getMeteoText(meteo_type_qnh, 1)
                    );

            assignedAltitude = approachAltitude;

            altitude_check_interval = flightLevelChangeSeconds(assignedAltitude);

            approachStatus = approach_status_to_approach;
            approach_check_counter = 0;
        }
        else if(distanceToApproach > 3)
        {
            # Route plane to pattern point

            text = sprintf(patternFormat,
                        atcCallsignText,
                        selectedComStationName,
                        altitudeInstructionText,
                        sprintf("%d", courseToPattern),
                        sprintf("%d", distanceToPattern),
                        patternCircuit,
                        sprintf("%d", courseToApproachPoint),
                        finalTurn,
                        ilsText,
                        airportLandingRunway,
                        sprintf("%d", approachAltitude),
                        getMeteoText(meteo_type_qnh, 0)
                );

            voice = sprintf(patternFormat,
                        atcCallsignVoice,
                        selectedComStationName,
                        altitudeInstructionVoice,
                        spellToPhonetic(sprintf("%d", courseToPattern), spell_number),
                        spellToPhonetic(sprintf("%d", distanceToPattern), spell_number_to_literal),
                        patternCircuit,
                        spellToPhonetic(sprintf("%d", courseToApproachPoint), spell_number),
                        finalTurn,
                        ilsVoice,
                        spellToPhonetic(airportLandingRunway, spell_runway),
                        spellToPhonetic(sprintf("%d", approachAltitude), spell_number_to_literal),
                        getMeteoText(meteo_type_qnh, 1)
                    );

            approachStatus = approach_status_to_pattern;
            approach_check_counter = 0;
        }
        else
        {
            # Route plane to approach point

            text = sprintf(approachFormat,
                        atcCallsignText,
                        selectedComStationName,
                        altitudeInstructionText,
                        sprintf("%d", courseToApproachPoint),
                        sprintf("%d", distanceToApproach),
                        finalTurn,
                        ilsText,
                        airportLandingRunway,
                        sprintf("%d", approachAltitude),
                        getMeteoText(meteo_type_qnh, 0)
                );

            voice = sprintf(approachFormat,
                        atcCallsignVoice,
                        selectedComStationName,
                        altitudeInstructionVoice,
                        spellToPhonetic(sprintf("%d", courseToApproachPoint), spell_number),
                        spellToPhonetic(sprintf("%d", distanceToApproach), spell_number_to_literal),
                        finalTurn,
                        ilsVoice,
                        spellToPhonetic(airportLandingRunway, spell_runway),
                        spellToPhonetic(sprintf("%d", approachAltitude), spell_number_to_literal),
                        getMeteoText(meteo_type_qnh, 1)
                    );

            approachStatus = approach_status_to_approach;
            approach_check_counter = 0;
        }

        if(messageType == message_request_approach)
            pilotResponseType = message_approved_approach;
        else
            pilotResponseType = message_approved_ils;

        if(approvedCtr == nil or approvedCtr.ident != currentCtr.ident)
        {
            (text, voice) = getCtrAtcMessage(ctr_request_denied);

            assignedAltitude = -1;

            pilotResponseType = message_roger;
        }
        else
        {
            if(messageType == message_request_approach)
                aircraft_status = status_requested_approach;
            else
                aircraft_status = status_requested_ils;

            aircraftIsDeparting = 0;
        }

        setApproachButtons();

        setCtrButtons();

        cancelAtcPendingMessage();

        approach_check_interval = approach_check_interval_initial;
    }
    else if(messageType == message_approach_route_instructions)
    {
        replyFormat = getAtcMessageReplyFormat("approach_route_instructions");

        text = sprintf(replyFormat,
                    atcCallsignText,
                    selectedComStationName,
                    approachRouteTextInstructions
                );

        voice = sprintf(replyFormat,
                    atcCallsignVoice,
                    selectedComStationName,
                    approachRouteVoiceInstructions
                );

        multiplayMessageType = message_type_local;

        pilotResponseType = message_approach_route_instructions;
    }
    else if(messageType == message_airfield_in_sight or messageType == message_ils_established)
    {
        if(checkRadioIsType(radio_station_type_tower) == 0)
            return;

        multiplayMessageType = message_type_important;

        if(aircraft_status == status_requested_approach or aircraft_status == status_requested_ils or aircraft_status == status_cleared_for_land_approach or aircraft_status == status_cleared_for_land_ils)
        {
            airport = airportinfo(selectedComAirportId);

            (airportLandingRunway, airportRunwayInUseILS) = runwayInUse(airport, runway_landing);

            if(aircraft_status == status_requested_ils or aircraft_status == status_cleared_for_land_ils)
                landingRunway = airportRunwayInUseILS;
            else
                landingRunway = airportLandingRunway;

            text = sprintf(atcMessageReply.airfield_in_sight,
                        atcCallsignText,
                        selectedComStationName,
                        getMeteoText(meteo_type_wind, 0),
                        landingRunway
                );

            voice = sprintf(atcMessageReply.airfield_in_sight,
                        atcCallsignVoice,
                        selectedComStationName,
                        getMeteoText(meteo_type_wind, 1),
                        spellToPhonetic(landingRunway, spell_runway)
                    );

            if(aircraft_status == status_requested_ils)
                aircraft_status = status_cleared_for_land_ils;
            else
                aircraft_status = status_cleared_for_land_approach;

            setApproachButtons();

            cancelAtcPendingMessage();

            setAtcAutoCallbackAfterSeconds(land_check_secs);

            aircraftIsDeparting = 0;

            pilotResponseType = message_cleared_landing;
        }
        else
        {
            text = sprintf(atcMessageReply.not_allowed_to_land,
                        atcCallsignText,
                        selectedComStationName
                   );

            voice = sprintf(atcMessageReply.not_allowed_to_land,
                        atcCallsignVoice,
                        selectedComStationName
                    );

            setApproachButtons();

            pilotResponseType = message_roger;
        }

        if(approvedCtr == nil or approvedCtr.ident != currentCtr.ident)
        {
            (text, voice) = getCtrAtcMessage(ctr_request_denied);

            assignedAltitude = -1;

            pilotResponseType = message_roger;

            setApproachButtons();

            setCtrButtons();
        }
    }
    else if(messageType == message_flying_too_low)
    {
        multiplayMessageType = message_type_local;

        text = sprintf(atcMessageReply.flying_too_low,
                    atcCallsignText
                );

        voice = sprintf(atcMessageReply.flying_too_low,
                    atcCallsignVoice
                );

        pilotResponseType = message_none;
    }
    else if(messageType == message_terrain_ahead)
    {
        multiplayMessageType = message_type_local;

        text = sprintf(atcMessageReply.terrain_ahead,
                    atcCallsignText
                );

        voice = sprintf(atcMessageReply.terrain_ahead,
                    atcCallsignVoice
                );

        pilotResponseType = message_none;
    }
    else if(messageType == message_leaving_ctr)
    {
        multiplayMessageType = message_type_local;

        var nearestCtr = getNearbyCtr(ctr_search_range);

        if(nearestCtr != nil)
        {
            var radio = getCtrRadio(nearestCtr);

            extraText = sprintf(atcMessageAction.contact_ctr,
                            nearestCtr.airport,
                            "CTR",
                            sprintf("%.3f", radio.frequency)
                        );

            extraVoice = sprintf(atcMessageAction.contact_ctr,
                            nearestCtr.airport,
                            "C T R",
                            spellToPhonetic(sprintf("%.3f", radio.frequency), spell_number)
                        );
        }

        text = sprintf(atcMessageReply.leaving_ctr,
                    atcCallsignText,
                    selectedComStationName,
                    "CTR",
                    extraText
                );

        voice = sprintf(atcMessageReply.leaving_ctr,
                    atcCallsignVoice,
                    selectedComStationName,
                    "C T R",
                    extraVoice
                );

        aircraftIsDeparting = 0;

        pilotResponseType = message_roger;

        resetAircraftStatus();

        setApproachButtons();
    }
    else if(messageType == message_not_in_this_ctr)
    {
        multiplayMessageType = message_type_local;

        text = sprintf(atcMessageReply.not_in_this_ctr,
                    atcCallsignText,
                    selectedComStationName,
                    "CTR",
                    "CTR"
                );

        voice = sprintf(atcMessageReply.not_in_this_ctr,
                    atcCallsignVoice,
                    selectedComStationName,
                    "C T R",
                    "C T R"
                );

        aircraftIsDeparting = 0;

        pilotResponseType = message_roger;

        resetAircraftStatus();

        setApproachButtons();
    }
    if(messageType == message_request_fl)
    {
        multiplayMessageType = message_type_important;

        text = sprintf(atcMessageReply.fl_approved,
                    atcCallsignText,
                    selectedComStationName,
                    "FL",
                    getFlightLevelCode(requestedAltitude)
                );

        voice = sprintf(atcMessageReply.fl_approved,
                    atcCallsignVoice,
                    selectedComStationName,
                    "Flight Level",
                    spellToPhonetic(getFlightLevelCode(requestedAltitude), spell_number)
                );

        resetAircraftStatus();

        setApproachButtons();

        setCtrButtons();

        assignedAltitude = requestedAltitude;

        altitude_check_interval = flightLevelChangeSeconds(assignedAltitude);

        pilotResponseType = message_fl_approved;

        if(approvedCtr == nil or approvedCtr.ident != currentCtr.ident)
        {
            (text, voice) = getCtrAtcMessage(ctr_request_denied);

            assignedAltitude = -1;

            pilotResponseType = message_roger;
        }
    }
    else if(messageType == message_change_altitude)
    {
        multiplayMessageType = message_type_important;

        assignedAltitude = getFlightPlanAltitude();

        if(assignedAltitude == -1)
        {
            assignedAltitude = normalizeAltitudeHeading(property_Aircraft_AltitudeFeet.getValue(), property_Aircraft_HeadingDeg.getValue(), minCruiseAltidude);

            if(rand() < 0.5 and (assignedAltitude - flight_level_step) >= minCruiseAltidude)
                assignedAltitude -= flight_level_step;
        }

        if(property_Aircraft_AltitudeFeet.getValue() > assignedAltitude)
            actionTag = atcMessageAction.descend;
        else
            actionTag = atcMessageAction.climb;

        text = sprintf(atcMessageReply.change_altitude,
                    atcCallsignText,
                    selectedComStationName,
                    actionTag,
                    sprintf("%d", assignedAltitude)
                );

        voice = sprintf(atcMessageReply.change_altitude,
                    atcCallsignVoice,
                    selectedComStationName,
                    actionTag,
                    spellToPhonetic(sprintf("%d", assignedAltitude), spell_number_to_literal)
               );

        altitude_check_interval = flightLevelChangeSeconds(assignedAltitude);

        pilotResponseType = message_change_altitude;
    }
    else if(messageType == message_check_altitude)
    {
        multiplayMessageType = message_type_local;

        if(property_Aircraft_AltitudeFeet.getValue() > assignedAltitude)
            actionTag = atcMessageAction.descend;
        else
            actionTag = atcMessageAction.climb;

        text = sprintf(atcMessageReply.check_altitude,
                    atcCallsignText,
                    selectedComStationName,
                    actionTag,
                    sprintf("%d", assignedAltitude)
                );

        voice = sprintf(atcMessageReply.check_altitude,
                    atcCallsignVoice,
                    selectedComStationName,
                    actionTag,
                    spellToPhonetic(sprintf("%d", assignedAltitude), spell_number_to_literal)
                );

        altitude_check_interval = flightLevelChangeSeconds(assignedAltitude);

        pilotResponseType = message_change_altitude;
    }
    else if(messageType == message_check_transponder)
    {
        multiplayMessageType = message_type_local;

        if(squawkIdent != squawk_ident_code)
        {
            if(squawkCode == "")
                squawkCode = getSquawkCode();

            extraText = sprintf("%s and ", squawkCode);

            extraVoice = sprintf("%s and ", spellToPhonetic(squawkCode, spell_number));

            setSquawkIdentMode(squawk_ident_code);
        }
        else
        {
            extraText = "";
            extraVoice = "";

            setSquawkIdentMode(squawk_ident_only);
        }

        text = sprintf(atcMessageReply.check_transponder,
                    atcCallsignText,
                    selectedComStationName,
                    extraText
                );

        voice = sprintf(atcMessageReply.check_transponder,
                    atcCallsignVoice,
                    selectedComStationName,
                    extraVoice
                );

        pilotResponseType = message_check_transponder;
    }
    else if(messageType == message_emergency_squawk)
    {
        var code = emergencySquawkCode;
        var message = "";

        if(code == "")
            return;

        multiplayMessageType = message_type_important;

        if(code == "7500")
            message = getAtcMessageReplyFormat("emergency_7500");
        else if(code == "7600")
            message = getAtcMessageReplyFormat("emergency_7600");
        else if(code == "7700")
            message = getAtcMessageReplyFormat("emergency_7700");
        else
            return;

        text = sprintf(message, atcCallsignText, selectedComStationName, code);
        voice = sprintf(message, atcCallsignVoice, selectedComStationName,
                        spellToPhonetic(code, spell_number));
        pilotResponseType = message_none;
    }
    else if(messageType == message_abort_approach)
    {
        var msg = "";
        var rwy = "";

        multiplayMessageType = message_type_important;

        if(aircraft_status == status_requested_approach or aircraft_status == status_requested_ils)
        {
            msg = atcMessageReply.abort_approach;
            rwy = airportLandingRunway;
        }
        else if(aircraft_status == status_cleared_for_land_approach or aircraft_status == status_cleared_for_land_ils)
        {
            msg = atcMessageReply.abort_landing;
            rwy = landingRunway;
        }
        else
            return;

        text = sprintf(msg,
                    atcCallsignText,
                    selectedComStationName,
                    rwy
                );

        voice = sprintf(msg,
                    atcCallsignVoice,
                    selectedComStationName,
                    spellToPhonetic(rwy, spell_runway)
                );

        aircraftIsDeparting = 0;
        approachStatus = approach_status_none;
        approach_check_interval = approach_check_interval_initial;

        resetAircraftStatus();

        setApproachButtons();

        pilotResponseType = message_going_around;
    }

    if(text != "" or voice != "")
        atcMessage(text, voice);
}

var atcAutoMessage = func()
{
    var text = "";
    var voice = "";
    var replyFormat = "";
    var minCruiseAltidude = getMinCruiseAltitude();

    if(isRadioServiceable() == 0)
        return;

    multiplayMessageType = message_type_local;

    (atcCallsignText, atcCallsignVoice) = getCallSignForAtc(0);

    if(aircraft_status == status_ready_for_departure)
    {
        multiplayMessageType = message_type_important;

        if(currentRunway != airportRunwayInUse or nearRunway == 1 or alignedOnRunway == 0)
        {
            if(currentRunway != "" and currentRunway != airportRunwayInUse)
            {
                replyFormat = getAtcMessageReplyFormat("wrong_runway");

                text = sprintf(replyFormat,
                            atcCallsignText,
                            selectedComStationName,
                            airportRunwayInUse
                       );

                voice = sprintf(replyFormat,
                            atcCallsignVoice,
                            selectedComStationName,
                            spellToPhonetic(airportRunwayInUse, spell_runway)
                        );
            }
            else if(currentRunway == airportRunwayInUse and nearRunway == 0 and alignedOnRunway == 0)
            {
                text = sprintf(atcMessageReply.align_for_departure,
                            atcCallsignText,
                            selectedComStationName,
                            airportRunwayInUse
                       );

                voice = sprintf(atcMessageReply.align_for_departure,
                            atcCallsignVoice,
                            selectedComStationName,
                            spellToPhonetic(airportRunwayInUse, spell_runway)
                        );
            }
            else
            {
                text = sprintf(atcMessageReply.hold_short_for_departure,
                            atcCallsignText,
                            selectedComStationName,
                            airportRunwayInUse
                       );

                voice = sprintf(atcMessageReply.hold_short_for_departure,
                            atcCallsignVoice,
                            selectedComStationName,
                            spellToPhonetic(airportRunwayInUse, spell_runway)
                        );
            }

            aircraft_status = status_going_around;
            atc_callback_wait_seconds = auto_reply_off;
            atc_callback_seconds_counter = 0;
            pilotResponseType = message_roger;

            setApproachButtons();
            setCtrButtons();
        }
        else
        {
            replyFormat = getAtcMessageReplyFormat("cleared_for_takeoff");

            text = sprintf(replyFormat,
                        atcCallsignText,
                        selectedComStationName,
                        airportRunwayInUse,
                        getMeteoText(meteo_type_qnh, 0)
                    );

            voice = sprintf(replyFormat,
                        atcCallsignVoice,
                        selectedComStationName,
                        spellToPhonetic(airportRunwayInUse, spell_runway),
                        getMeteoText(meteo_type_qnh, 1)
                    );

            aircraft_status = status_cleared_for_takeoff;

            cancelAtcPendingMessage();

            setAtcAutoCallbackAfterSeconds(max_departure_secs);

            departure_extra_time = 0;

            approvedCtr = currentCtr;
            altitude_check_counter = 0;

            aircraftIsDeparting = 1;

            setApproachButtons();

            setCtrButtons();

            pilotResponseType = message_cleared_take_off;
        }
    }
    else if(aircraft_status == status_cleared_for_takeoff)
    {
        multiplayMessageType = message_type_important;

        if(departure_extra_time == 0 and alignedOnRunway == 1)
        {
            addSecondsToAtcAutoCallback(extra_departure_secs);

            departure_extra_time = 1;
        }
        else
        {
            text = sprintf(atcMessageReply.vacate_runway,
                        atcCallsignText,
                        selectedComStationName
                    );

            voice = sprintf(atcMessageReply.vacate_runway,
                        atcCallsignVoice,
                        selectedComStationName
                    );

            cancelAtcPendingMessage();

            setAtcAutoCallbackAfterSeconds(max_take_off_secs);
        }

        approvedCtr = currentCtr;
        altitude_check_counter = 0;
        aircraftIsDeparting = 1;

        setApproachButtons();

        setCtrButtons();

        pilotResponseType = message_roger;
    }
    else if(aircraft_status == status_took_off)
    {
        var airport = airportinfo();
        var extraText = "";
        var extraVoice = "";

        multiplayMessageType = message_type_local;

        aircraftIsDeparting = 1;

        var cruiseAltitude = getFlightPlanAltitude();

        if(cruiseAltitude == -1)
            cruiseAltitude = normalizeAltitudeHeading(airport.elevation * M2FT, airport.runways[airportRunwayInUse].heading, minCruiseAltidude);

        var radio = getCtrRadio(currentCtr);

        if(radio != nil and radio.frequency != selectedComFrequency)
        {
            extraText = sprintf(atcMessageReply.contact_radio,
                            normalizeRadioStationName(radio.name),
                            sprintf("%.3f", radio.frequency)
                        );

            extraVoice = sprintf(atcMessageReply.contact_radio,
                            normalizeRadioStationName(radio.name),
                            spellToPhonetic(sprintf("%.3f", radio.frequency), spell_number)
                        );
        }

        if(squawkingMode == "On")
        {
            if(checkTransponder(selectedTransponder) == 0)
            {
                if(squawkCode == "")
                    squawkCode = getSquawkCode();

                if(extraText != "")
                {
                    extraText ~= ".";
                    extraVoice ~= ".";
                }

                extraText ~= " " ~ sprintf(atcMessageAction.check_transponder, squawkCode);

                extraVoice ~= " " ~ sprintf(atcMessageAction.check_transponder, spellToPhonetic(squawkCode, spell_number));

                setSquawkIdentMode(squawk_ident_code);
            }
        }

        replyFormat = getAtcMessageReplyFormat("leaving_airport");

        text = sprintf(replyFormat,
                    atcCallsignText,
                    selectedComStationName,
                    getMeteoText(meteo_type_wind, 0),
                    sprintf("%d", cruiseAltitude),
                    extraText
                );

        voice = sprintf(replyFormat,
                    atcCallsignVoice,
                    selectedComStationName,
                    getMeteoText(meteo_type_wind, 1),
                    spellToPhonetic(sprintf("%d", cruiseAltitude), spell_number_to_literal),
                    extraVoice
                );

        cancelAtcPendingMessage();

        aircraft_status = status_flying;
        approachStatus = approach_status_none;
        approach_check_interval = approach_check_interval_initial;

        approvedCtr = currentCtr;
        assignedAltitude = cruiseAltitude;
        altitude_check_counter = 0;
        altitude_check_interval = flightLevelChangeSeconds(assignedAltitude);

        setApproachButtons();

        setCtrButtons();

        pilotResponseType = message_leaving_airport;
    }
    else if(aircraft_status == status_cleared_for_land_approach or aircraft_status == status_cleared_for_land_ils)
    {
        var approachingRunway = "";
        var distance = 9999;

        multiplayMessageType = message_type_important;

        (approachingRunway, distance) = getApproachingRunway(currentAirport);

        airport = airportinfo(selectedComAirportId);

        (airportLandingRunway, airportRunwayInUseILS) = runwayInUse(airport, runway_landing);

        if(aircraft_status == status_cleared_for_land_ils)
            landingRunway = airportRunwayInUseILS;
        else
            landingRunway = airportLandingRunway;

        if(approachingRunway != "" and approachingRunway != landingRunway)
        {
            replyFormat = getAtcMessageReplyFormat("wrong_approach_runway");

            text = sprintf(replyFormat,
                        atcCallsignText,
                        selectedComStationName,
                        landingRunway
                    );

            voice = sprintf(replyFormat,
                        atcCallsignVoice,
                        selectedComStationName,
                        spellToPhonetic(landingRunway, spell_runway)
                    );

            pilotResponseType = message_wilco;
        }
        else
            pilotResponseType = message_none;

        aircraftIsDeparting = 0;

        cancelAtcPendingMessage();

        setAtcAutoCallbackAfterSeconds(land_check_secs);

        setApproachButtons();
    }
    else if(aircraft_status == status_landed)
    {
        airport = airportinfo();

        multiplayMessageType = message_type_important;

        replyFormat = getAtcMessageReplyFormat("welcome_to_airport");

        text = sprintf(replyFormat,
                    atcCallsignText,
                    selectedComStationName,
                    airport.name
                );

        voice = sprintf(replyFormat,
                    atcCallsignVoice,
                    selectedComStationName,
                    airport.name
                );

        cancelAtcPendingMessage();

        aircraft_status = status_going_around;

        assignedAltitude = -1;
        aircraftIsDeparting = 0;
        approachStatus = approach_status_none;
        approach_check_interval = approach_check_interval_initial;
        squawkCode = "";
        squawkChange = 0;

        setSquawkIdentMode(squawk_ident_off);

        setApproachButtons();

        pilotResponseType = message_roger;
    }

    if(text != "" or voice != "")
        atcMessage(text, voice);
}

var pilotRequest = func(messageType)
{
    if(isRadioServiceable() == 0)
        return;

    if(isSimulationPaused() == 1)
        return;

    var text = "";
    var voice = "";

    multiplayMessageType = message_type_local;

    if(messageType == message_say_again)
    {
        multiplayMessageType = message_type_local;

        text = sprintf(pilotMessageRequest.say_again,
                    selectedComStationName,
                    atcCallsignText
                );

        voice = sprintf(pilotMessageRequest.say_again,
                    selectedComStationName,
                    atcCallsignVoice
                );
    }
    else if(messageType == message_radio_check)
    {
        multiplayMessageType = message_type_local;

        text = sprintf(pilotMessageRequest.radio_check,
                    selectedComStationName,
                    atcCallsignText,
                    sprintf("%.3f", selectedComFrequency)
                );

        voice = sprintf(pilotMessageRequest.radio_check,
                    selectedComStationName,
                    atcCallsignVoice,
                    spellToPhonetic(sprintf("%.3f", selectedComFrequency), spell_number)
                );
    }
    else if(messageType == message_engine_start)
    {
        multiplayMessageType = message_type_local;

        text = sprintf(pilotMessageRequest.engine_start,
                    selectedComStationName,
                    atcCallsignText
                );

        voice = sprintf(pilotMessageRequest.engine_start,
                    selectedComStationName,
                    atcCallsignVoice
                );
    }
    else if(messageType == message_departure_information)
    {
        multiplayMessageType = message_type_local;

        text = sprintf(pilotMessageRequest.departure_information,
                    selectedComStationName,
                    atcCallsignText
                );

        voice = sprintf(pilotMessageRequest.departure_information,
                    selectedComStationName,
                    atcCallsignVoice
                );
    }
    else if(messageType == message_request_taxi)
    {
        multiplayMessageType = message_type_important;

        if(departureInformation != "")
        {
            extraText = sprintf(" with information %s",
                            departureInformation
                        );

            extraVoice = extraText;
        }
        else
        {
            extraText = "";
            extraVoice = "";
        }

        text = sprintf(pilotMessageRequest.request_taxi,
                    selectedComStationName,
                    atcCallsignText,
                    extraText
                );

        voice = sprintf(pilotMessageRequest.request_taxi,
                    selectedComStationName,
                    atcCallsignVoice,
                    extraVoice
                );
    }
    else if(messageType == message_ready_for_departure)
    {
        multiplayMessageType = message_type_important;

        text = sprintf(pilotMessageRequest.ready_departure,
                    selectedComStationName,
                    atcCallsignText,
                    currentRunway
                );

        voice = sprintf(pilotMessageRequest.ready_departure,
                    selectedComStationName,
                    atcCallsignVoice,
                    spellToPhonetic(currentRunway, spell_runway)
                );

        if(squawkingMode == "On" and squawkCode == "")
            squawkChange = 1;
    }
    else if(messageType == message_abort_departure)
    {
        multiplayMessageType = message_type_important;

        text = sprintf(pilotMessageRequest.abort_departure,
                    selectedComStationName,
                    atcCallsignText,
                    currentRunway
                );

        voice = sprintf(pilotMessageRequest.abort_departure,
                    selectedComStationName,
                    atcCallsignVoice,
                    spellToPhonetic(currentRunway, spell_runway)
                );
    }
    else if(messageType == message_request_approach)
    {
        multiplayMessageType = message_type_important;

        text = sprintf(pilotMessageRequest.request_approach,
                    selectedComStationName,
                    atcCallsignText
                );

        voice = sprintf(pilotMessageRequest.request_approach,
                    selectedComStationName,
                    atcCallsignVoice
                );
    }
    else if(messageType == message_request_ils)
    {
        multiplayMessageType = message_type_important;

        text = sprintf(pilotMessageRequest.request_ils,
                    selectedComStationName,
                    atcCallsignText,
                    "ILS"
                );

        voice = sprintf(pilotMessageRequest.request_ils,
                    selectedComStationName,
                    atcCallsignVoice,
                    "I L S"
                );
    }
    else if(messageType == message_airfield_in_sight)
    {
        multiplayMessageType = message_type_important;

        text = sprintf(pilotMessageRequest.airfield_in_sight,
                    selectedComStationName,
                    atcCallsignText
                );

        voice = sprintf(pilotMessageRequest.airfield_in_sight,
                    selectedComStationName,
                    atcCallsignVoice
                );
    }
    else if(messageType == message_ils_established)
    {
        multiplayMessageType = message_type_important;

        text = sprintf(pilotMessageRequest.ils_established,
                    selectedComStationName,
                    atcCallsignText,
                    "ILS",
                    airportRunwayInUseILS
                );

        voice = sprintf(pilotMessageRequest.ils_established,
                    selectedComStationName,
                    atcCallsignVoice,
                    "I L S",
                    spellToPhonetic(airportRunwayInUseILS, spell_runway)
                );
    }
    else if(messageType == message_request_ctr)
    {
        multiplayMessageType = message_type_local;

        text = sprintf(pilotMessageRequest.request_ctr,
                    selectedComStationName,
                    atcCallsignText,
                    "CTR"
                );

        voice = sprintf(pilotMessageRequest.request_ctr,
                    selectedComStationName,
                    atcCallsignVoice,
                    "C T R"
                );
    }
    else if(messageType == message_request_fl)
    {
        multiplayMessageType = message_type_important;

        text = sprintf(pilotMessageRequest.request_fl,
                    selectedComStationName,
                    atcCallsignText,
                    "FL",
                    getFlightLevelCode(requestedAltitude)
                );

        voice = sprintf(pilotMessageRequest.request_fl,
                    selectedComStationName,
                    atcCallsignVoice,
                    "Flight Level",
                    spellToPhonetic(getFlightLevelCode(requestedAltitude), spell_number)
                );
    }
    else if(messageType == message_abort_approach)
    {
        multiplayMessageType = message_type_important;

        if(aircraft_status == status_requested_approach)
        {
            text = sprintf(pilotMessageRequest.abort_approach,
                        selectedComStationName,
                        atcCallsignText,
                        airportLandingRunway
                    );

            voice = sprintf(pilotMessageRequest.abort_approach,
                        selectedComStationName,
                        atcCallsignVoice,
                        spellToPhonetic(airportLandingRunway, spell_runway)
                    );
        }
        else if(aircraft_status == status_requested_ils)
        {
            text = sprintf(pilotMessageRequest.abort_ils,
                        selectedComStationName,
                        atcCallsignText,
                        "ILS",
                        airportLandingRunway
                    );

            voice = sprintf(pilotMessageRequest.abort_ils,
                        selectedComStationName,
                        atcCallsignVoice,
                        "I L S",
                        spellToPhonetic(airportLandingRunway, spell_runway)
                    );
        }
        else if(aircraft_status == status_cleared_for_land_approach or aircraft_status == status_cleared_for_land_ils)
        {
            text = sprintf(pilotMessageRequest.abort_landing,
                        selectedComStationName,
                        atcCallsignText,
                        landingRunway
                    );

            voice = sprintf(pilotMessageRequest.abort_landing,
                        selectedComStationName,
                        atcCallsignVoice,
                        spellToPhonetic(landingRunway, spell_runway)
                    );
        }
    }
    else
        return;

    if(text != "" or voice != "")
    {
        cancelAtcPendingMessage();

        var secs = 0;

        pilotMessageType = messageType;

        if(pilotRequestMode != "Disabled")
            secs = int(size(text) / 12) + 1;

        if((pilotRequestMode == "Voice only" or pilotRequestMode == "Voice and text") and voice != "")
        {
            speak(voice, pilotVoice['text'], pilotVoice['type']);

            secs += 2;
        }

        echoMultiplayerChat(text, multiplayMessageType);

        if((pilotRequestMode == "Text only" or pilotRequestMode == "Voice and text") and text != "")
        {
            var window = screen.window.new(atc_popup_x_position, atc_popup_y_position, 10, secs);

            window.bg = popup_window_bg_color;
            window.fg = popup_window_fg_pilot_color;
            window.align = atc_popup_align;

            window.write(text);

            addAtcLog(text);
        }

        setPilotMessageSeconds(secs + pilot_message_pause_atc_seconds);

        autoATCMessageDelay(secs + pilot_message_pause_atc_seconds);
    }
}

var pilotResponse = func(messageType)
{
    var text = "";
    var voice = "";
    var extraText = "";
    var extraVoice = "";
    var initialReportLetter = "R";
    var radio = nil;

    if(initialized == 0)
        initRgATC();

    if(isRadioServiceable() == 0)
        return;

    if(messageType == message_none or selectedComAirportId == "")
        return;

    multiplayMessageType = message_type_local;

    (atcCallsignText, atcCallsignVoice) = getCallSignForAtc(0);

    if(messageType == message_roger)
    {
        multiplayMessageType = message_type_local;

        text = sprintf(pilotMessageResponse.roger,
                    selectedComStationName,
                    atcCallsignText
                );

        voice = sprintf(pilotMessageResponse.roger,
                    selectedComStationName,
                    atcCallsignVoice
                );
    }
    else if(messageType == message_wilco)
    {
        multiplayMessageType = message_type_local;

        text = sprintf(pilotMessageResponse.wilco,
                    selectedComStationName,
                    atcCallsignText
                );

        voice = sprintf(pilotMessageResponse.wilco,
                    selectedComStationName,
                    atcCallsignVoice
                );
    }
    else if(messageType == message_departure_information)
    {
        if(departureInformation == "")
            return;

        multiplayMessageType = message_type_local;

        text = sprintf(pilotMessageResponse.departure_information,
                    selectedComStationName,
                    atcCallsignText,
                    departureInformation
                );

        voice = sprintf(pilotMessageResponse.departure_information,
                    selectedComStationName,
                    atcCallsignVoice,
                    departureInformation
                );
    }
    else if(messageType == message_engine_start)
    {
        multiplayMessageType = message_type_local;

        text = sprintf(pilotMessageResponse.engine_start,
                    selectedComStationName,
                    atcCallsignText,
                    airportRunwayInUse
                );

        voice = sprintf(pilotMessageResponse.engine_start,
                    selectedComStationName,
                    atcCallsignVoice,
                    spellToPhonetic(airportRunwayInUse, spell_runway)
                );
    }
    else if(messageType == message_ctr_approved)
    {
        multiplayMessageType = message_type_local;

        if(squawkingMode == "On")
        {
            if(squawkChange == 1)
            {
                extraText = sprintf(", Squawk %s and IDENT", squawkCode);
                extraVoice = sprintf(", Squawk %s and ident", spellToPhonetic(squawkCode, spell_number));

                setSquawkIdentMode(squawk_ident_code);
            }
            else
            {
                extraText = ", Squawk IDENT";
                extraVoice = ", Squawk ident";

                setSquawkIdentMode(squawk_ident_only);
            }

            squawkChange = 0;
        }
        else
        {
            extraText = "";
            extraVoice = "";
        }

        text = sprintf(pilotMessageResponse.approved_ctr,
                    selectedComStationName,
                    atcCallsignText,
                    "CTR",
                    extraText
                );

        voice = sprintf(pilotMessageResponse.approved_ctr,
                    selectedComStationName,
                    atcCallsignVoice,
                    "C T R",
                    extraVoice
                );
    }
    else if(messageType == message_request_taxi)
    {
        multiplayMessageType = message_type_important;

        if(squawkingMode == "On")
        {
            extraText = sprintf(", Squawk %s", squawkCode);
            extraVoice = sprintf(", Squawk %s", spellToPhonetic(squawkCode, spell_number));

            squawkChange = 0;
        }
        else
        {
            extraText = "";
            extraVoice = "";
        }

        text = sprintf(pilotMessageResponse.taxi,
                    selectedComStationName,
                    atcCallsignText,
                    airportRunwayInUse,
                    extraText
                );

        voice = sprintf(pilotMessageResponse.taxi,
                    selectedComStationName,
                    atcCallsignVoice,
                    spellToPhonetic(airportRunwayInUse, spell_runway),
                    extraVoice
                );
    }
    else if(messageType == message_wait_for_departure)
    {
        multiplayMessageType = message_type_important;

        if(nearRunway == 1)
        {
            extraText = atcMessageAction.lineup_and_wait;
            extraVoice = atcMessageAction.lineup_and_wait;
        }
        else
        {
            extraText = "";
            extraVoice = "";
        }

        text = sprintf(pilotMessageResponse.wait_departure,
                    selectedComStationName,
                    atcCallsignText,
                    extraText,
                    airportRunwayInUse
                );

        voice = sprintf(pilotMessageResponse.wait_departure,
                    selectedComStationName,
                    atcCallsignVoice,
                    extraVoice,
                    spellToPhonetic(airportRunwayInUse, spell_runway)
                );

        if(squawkingMode == "On" and squawkChange == 1)
        {
            text ~= sprintf(". Squawk %s.", squawkCode);

            voice ~= sprintf(". Squawk %s.", spellToPhonetic(squawkCode, spell_number));

            squawkChange = 0;
        }
    }
    else if(messageType == message_cleared_take_off)
    {
        multiplayMessageType = message_type_important;

        text = sprintf(pilotMessageResponse.cleared_take_off,
                    selectedComStationName,
                    atcCallsignText,
                    airportRunwayInUse
                );

        voice = sprintf(pilotMessageResponse.cleared_take_off,
                    selectedComStationName,
                    atcCallsignVoice,
                    spellToPhonetic(airportRunwayInUse, spell_runway)
                );
    }
    else if(messageType == message_leaving_airport)
    {
        radio = getCtrRadio(currentCtr);

        multiplayMessageType = message_type_local;

        if(radio != nil and radio.frequency != selectedComFrequency)
        {
            extraText = sprintf(atcMessageReply.contact_radio,
                            normalizeRadioStationName(radio.name),
                            sprintf("%.3f", radio.frequency)
                        );

            extraVoice = sprintf(atcMessageReply.contact_radio,
                            normalizeRadioStationName(radio.name),
                            spellToPhonetic(sprintf("%.3f", radio.frequency), spell_number)
                        );
        }

        if(squawkingMode == "On")
        {
            if(checkTransponder(selectedTransponder) == 0)
            {
                if(squawkCode == "")
                    squawkCode = getSquawkCode();

                if(extraText != "")
                {
                    extraText ~= ".";
                    extraVoice ~= ".";
                }

                extraText ~= " " ~ sprintf(atcMessageAction.check_transponder, squawkCode);

                extraVoice ~= " " ~ sprintf(atcMessageAction.check_transponder, spellToPhonetic(squawkCode, spell_number));

                setSquawkIdentMode(squawk_ident_code);
            }
            else
                setSquawkIdentMode(squawk_ident_off);
        }

        text = sprintf(pilotMessageResponse.leaving_airport,
                    selectedComStationName,
                    atcCallsignText,
                    sprintf("%d", assignedAltitude),
                    extraText
                );

        voice = sprintf(pilotMessageResponse.leaving_airport,
                    selectedComStationName,
                    atcCallsignVoice,
                    spellToPhonetic(sprintf("%d", assignedAltitude), spell_number_to_literal),
                    extraVoice
                );

        altitude_check_interval = flightLevelChangeSeconds(assignedAltitude);
    }
    else if(messageType == message_approved_approach)
    {
        multiplayMessageType = message_type_important;

        text = sprintf(pilotMessageResponse.approved_approach,
                    selectedComStationName,
                    atcCallsignText,
                    airportLandingRunway
                );

        voice = sprintf(pilotMessageResponse.approved_approach,
                    selectedComStationName,
                    atcCallsignVoice,
                    spellToPhonetic(airportLandingRunway, spell_runway)
                );
    }
    else if(messageType == message_approved_ils)
    {
        multiplayMessageType = message_type_important;

        text = sprintf(pilotMessageResponse.approved_ils,
                    selectedComStationName,
                    atcCallsignText,
                    "ILS",
                    airportLandingRunway
                );

        voice = sprintf(pilotMessageResponse.approved_ils,
                    selectedComStationName,
                    atcCallsignVoice,
                    "I L S",
                    spellToPhonetic(airportLandingRunway, spell_runway)
                );
    }
    else if(messageType == message_approach_route_instructions)
    {
        multiplayMessageType = message_type_local;

        text = sprintf(pilotMessageResponse.approach_route_instructions,
                    selectedComStationName,
                    atcCallsignText,
                    approachRouteTextInstructions
                );

        voice = sprintf(pilotMessageResponse.approach_route_instructions,
                    selectedComStationName,
                    atcCallsignVoice,
                    approachRouteVoiceInstructions
                );
    }
    else if(messageType == message_cleared_landing)
    {
        multiplayMessageType = message_type_important;

        text = sprintf(pilotMessageResponse.cleared_landing,
                    selectedComStationName,
                    atcCallsignText,
                    landingRunway
                );

        voice = sprintf(pilotMessageResponse.cleared_landing,
                    selectedComStationName,
                    atcCallsignVoice,
                    spellToPhonetic(landingRunway, spell_runway)
                );
    }
    else if(messageType == message_fl_approved)
    {
        multiplayMessageType = message_type_important;

        text = sprintf(pilotMessageResponse.approved_fl,
                    selectedComStationName,
                    atcCallsignText,
                    "FL",
                    getFlightLevelCode(requestedAltitude)
                );

        voice = sprintf(pilotMessageResponse.approved_fl,
                    selectedComStationName,
                    atcCallsignVoice,
                    "Flight Level",
                    spellToPhonetic(getFlightLevelCode(requestedAltitude), spell_number)
                );
    }
    else if(messageType == message_change_altitude)
    {
        var actionTag = "";

        multiplayMessageType = message_type_important;

        if(property_Aircraft_AltitudeFeet.getValue() > assignedAltitude)
            actionTag = atcMessageAction.descend;
        else
            actionTag = atcMessageAction.climb;

        text = sprintf(pilotMessageResponse.change_altitude,
                    selectedComStationName,
                    atcCallsignText,
                    actionTag,
                    sprintf("%d", assignedAltitude)
                );

        voice = sprintf(pilotMessageResponse.change_altitude,
                    selectedComStationName,
                    atcCallsignVoice,
                    actionTag,
                    spellToPhonetic(sprintf("%d", assignedAltitude), spell_number_to_literal)
                );

        altitude_check_interval = flightLevelChangeSeconds(assignedAltitude);
    }
    else if(messageType == message_check_transponder)
    {
        if(squawkIdent == squawk_ident_code)
        {
            extraText = sprintf("%s and ", squawkCode);

            extraVoice = sprintf("%s and ", spellToPhonetic(squawkCode, spell_number));
        }
        else
        {
            extraText = "";
            extraVoice = "";
        }

        text = sprintf(pilotMessageResponse.check_transponder,
                    selectedComStationName,
                    atcCallsignText,
                    extraText
                );

        voice = sprintf(pilotMessageResponse.check_transponder,
                    selectedComStationName,
                    atcCallsignVoice,
                    extraVoice
                );
    }
    else if(messageType == message_going_around)
    {
        multiplayMessageType = message_type_important;

        text = sprintf(pilotMessageResponse.going_around,
                    selectedComStationName,
                    atcCallsignText
                );

        voice = sprintf(pilotMessageResponse.going_around,
                    selectedComStationName,
                    atcCallsignVoice
                );
    }
    else if(messageType == message_contact_radio)
    {
        multiplayMessageType = message_type_local;

        if(contactRadio != nil)
        {
            text = sprintf(pilotMessageResponse.contact_radio,
                        atcCallsignText,
                        selectedComStationName,
                        normalizeRadioStationName(contactRadio.name),
                        sprintf("%.3f", contactRadio.frequency)
                   );

            voice = sprintf(pilotMessageResponse.contact_radio,
                        atcCallsignVoice,
                        selectedComStationName,
                        normalizeRadioStationName(contactRadio.name),
                        spellToPhonetic(sprintf("%.3f", contactRadio.frequency), spell_number)
                    );
        }
    }

    pilotResponseType = message_none;

    pilot_response_wait_seconds = -1;

    if(text != "" or voice != "")
    {
        var secs = 0;

        if(pilotResponseMode != "Disabled")
            secs = int(size(text) / 12) + 1;

        if((pilotResponseMode == "Voice only" or pilotResponseMode == "Voice and text") and voice != "")
        {
            speak(voice, pilotVoice['text'], pilotVoice['type']);

            secs += 2;
        }

        if((pilotResponseMode == "Text only" or pilotResponseMode == "Voice and text") and text != "")
        {
            var window = screen.window.new(atc_popup_x_position, atc_popup_y_position, 10, secs);

            window.bg = popup_window_bg_color;
            window.fg = popup_window_fg_pilot_color;
            window.align = atc_popup_align;

            window.write(text);

            addAtcLog(text);
        }

        autoATCMessageDelay(secs);

        echoMultiplayerChat(text, multiplayMessageType);
    }
}

var atcMessage = func(text, voice)
{
    var secs = int(size(voice) / 12) + 1;

    if((atcMessageMode == "Voice only" or atcMessageMode == "Voice and text") and voice != "")
    {
        if(stationVoice[selectedComFrequency] != nil)
            speak(voice, stationVoice[selectedComFrequency]['text'], stationVoice[selectedComFrequency]['type']);
        else
            showPopup(atcMessageAction.inconsistent_radio_data);
    }

    if((atcMessageMode == "Text only" or atcMessageMode == "Voice and text") and text != "")
    {
        var window = screen.window.new(atc_popup_x_position, atc_popup_y_position, 10, secs);

        window.bg = popup_window_bg_color;
        window.fg = popup_window_fg_atc_color;
        window.align = atc_popup_align;

        window.write(text);

        addAtcLog(text);
    }

    autoATCMessageDelay(secs);

    echoMultiplayerChat(text, multiplayMessageType);

    lastAtcText = text;
    lastAtcVoice = voice;

    showRepeatATCMessageButton(1);

    pilot_response_counter = 0;

    if(pilotResponseType != message_none)
        pilot_response_wait_seconds = secs + pilot_response_pause_atc_seconds;
    else
        pilot_response_wait_seconds = -1;
}

var echoMultiplayerChat = func(text, type)
{
    if(multiplayerChatEcho == "Off")
        return;

    var airport = airportinfo(selectedComAirportId);

    var message = "[" ~ RGAtcName;

    if(airport != nil)
        message ~= "@" ~ airport.id;

    message ~= "] ";

    message ~= text;

    if((multiplayerChatEcho == "Important messages only" and type == message_type_important) or (multiplayerChatEcho == "All messages"))
        property_Multiplay_Chat.setValue(message);
}

var assistedAtcApproach = func()
{
    var courseToPoint = nil;
    var distanceToPoint = nil;
    var degreeDiff = 0;
    var turnToDiff = "";
    var requiredSpeed = 0;
    var actionTag = "";
    var aircraftHeading = property_Aircraft_HeadingDeg.getValue();
    var point = nil;

    if(approachStatus == approach_status_none or approachStatus == approach_status_landing)
        return;

    if(approachStatus == approach_status_to_pattern)
    {
        (courseToPoint, distanceToPoint) = courseAndDistance(patternPoint);

        requiredSpeed = pattern_speed;
    }
    else
    {
        (courseToPoint, distanceToPoint) = courseAndDistance(approachPoint);

        requiredSpeed = approach_speed;
    }

    if(distanceToPoint < abs(approach_point_distance / 2))
        approach_check_interval = approach_check_interval_near_point;

    if(distanceToPoint < approach_turn_distance)
    {
        if(approachStatus == approach_status_to_pattern)
            approachStatus = approach_status_to_approach;
        else
            approachStatus = approach_status_to_final;

        approach_check_interval = approach_check_interval_final;
    }

    if(approachStatus == approach_status_to_pattern or approachStatus == approach_status_to_approach)
    {
        approachRouteTextInstructions = "";
        approachRouteVoiceInstructions = "";

        if(courseWithinDegrees(aircraftHeading, courseToPoint, 10) == 0)
        {
            (degreeDiff, turnToDiff) = degreesDifference(aircraftHeading, courseToPoint);

            approachRouteTextInstructions = sprintf(atcMessageReply.turn_to_heading,
                                                    turnToDiff,
                                                    sprintf("%d", courseToPoint)
                                            );

            approachRouteVoiceInstructions = sprintf(atcMessageReply.turn_to_heading,
                                                        turnToDiff,
                                                        spellToPhonetic(sprintf("%d", courseToPoint), spell_number)
                                                );
        }

        if(distanceToPoint < abs(approach_point_distance / 2) and abs(property_Aircraft_AltitudeFeet.getValue() - approachAltitude) > (assigned_altitude_delta / 2))
        {
            if(approachRouteTextInstructions != "")
            {
                approachRouteTextInstructions ~= ". ";
                approachRouteVoiceInstructions ~= ". ";
            }

            if(property_Aircraft_AltitudeFeet.getValue() > approachAltitude)
                actionTag = atcMessageAction.descend;
            else
                actionTag = atcMessageAction.climb;

            approachRouteTextInstructions ~= sprintf("%s and maintain %s",
                                                        actionTag,
                                                        sprintf("%d", approachAltitude)
                                                );

            approachRouteVoiceInstructions ~= sprintf("%s and maintain %s",
                                                        actionTag,
                                                        spellToPhonetic(sprintf("%d", approachAltitude),
                                                        spell_number_to_literal)
                                                );
        }

        if(distanceToPoint < abs(approach_point_distance / 2) and abs(property_Aircraft_AirSpeedKnots.getValue() - requiredSpeed) > approach_speed_delta)
        {
            if(approachRouteTextInstructions != "")
            {
                approachRouteTextInstructions ~= ". ";
                approachRouteVoiceInstructions ~= ". ";
            }

            if(property_Aircraft_AirSpeedKnots.getValue() > requiredSpeed)
                actionTag = atcMessageAction.reduce;
            else
                actionTag = atcMessageAction.increase;

            approachRouteTextInstructions ~= sprintf("%s speed %s knots",
                                                        actionTag,
                                                        sprintf("%d", requiredSpeed)
                                                );

            approachRouteVoiceInstructions ~= sprintf("%s speed %s knots",
                                                        actionTag,
                                                        spellToPhonetic(sprintf("%d", requiredSpeed),
                                                        spell_number_to_literal)
                                                );
        }

        if(approachRouteTextInstructions != "")
            atcReplyToRequest(message_approach_route_instructions);
    }
    else if(approachStatus == approach_status_to_final)
    {
        var initialReportLetter = "R";
        var contactMsgText = "";
        var contactMsgVoice = "";
        var towerContactText = "";
        var towerContactVoice = "";

        airport = airportinfo(selectedComAirportId);

        runwayHeading = airport.runways[airportLandingRunway].heading;

        (degreeDiff, turnToDiff) = degreesDifference(aircraftHeading, runwayHeading);

        approachRouteTextInstructions = sprintf(atcMessageReply.turn_to_final,
                                                turnToDiff,
                                                sprintf("%d", runwayHeading),
                                                airportLandingRunway
                                        );

        approachRouteVoiceInstructions = sprintf(atcMessageReply.turn_to_final,
                                                 turnToDiff,
                                                 spellToPhonetic(sprintf("%d", runwayHeading), spell_number),
                                                 spellToPhonetic(airportLandingRunway, spell_runway)
                                         );

        if(abs(property_Aircraft_AirSpeedKnots.getValue() - final_speed) > approach_speed_delta)
        {
            if(approachRouteTextInstructions != "")
            {
                approachRouteTextInstructions ~= ". ";
                approachRouteVoiceInstructions ~= ". ";
            }

            if(property_Aircraft_AirSpeedKnots.getValue() > final_speed)
                actionTag = atcMessageAction.reduce;
            else
                actionTag = atcMessageAction.increase;

            approachRouteTextInstructions ~= sprintf("%s speed %s knots",
                                                     actionTag,
                                                     sprintf("%d", final_speed)
                                             );

            approachRouteVoiceInstructions ~= sprintf("%s speed %s knots",
                                                      actionTag,
                                                      spellToPhonetic(sprintf("%d", final_speed), spell_number_to_literal)
                                              );
        }

        if(isRadioFrequencyOfType(selectedComFrequency, radio_station_type_tower) == 0)
        {
            towerRadio = getRadio(radio_station_type_tower, radio_type_any);

            if(towerRadio == nil)
            {
                showPopup(RGAtcName ~ ": " ~ atcMessageAction.tower_not_reachable ~ ".");

                return;
            }

            if(selectedComFrequency != towerRadio.frequency)
            {
                towerContactText = sprintf(atcMessageReply.contact_radio,
                                            normalizeRadioStationName(towerRadio.name),
                                            sprintf("%.3f", towerRadio.frequency)
                                );

                towerContactText ~= " and ";

                towerContactVoice = sprintf(atcMessageReply.contact_radio,
                                            normalizeRadioStationName(towerRadio.name),
                                            spellToPhonetic(sprintf("%.3f", towerRadio.frequency), spell_number)
                                );

                towerContactVoice ~= " and ";

                initialReportLetter = "r";
            }
        }

        if(aircraft_status == status_requested_approach)
        {
            contactMsgText = sprintf(atcMessageReply.report_airfield_in_sight,
                                        initialReportLetter
                            );

            contactMsgText = towerContactText ~ contactMsgText;

            contactMsgVoice = sprintf(atcMessageReply.report_airfield_in_sight,
                                        initialReportLetter
                            );

            contactMsgVoice = towerContactVoice ~ contactMsgVoice;
        }
        else
        {
            contactMsgText = sprintf(atcMessageReply.report_established_ils,
                                        initialReportLetter,
                                        "ILS",
                                        airportLandingRunway
                            );

            contactMsgText = towerContactText ~ contactMsgText;

            contactMsgVoice = sprintf(atcMessageReply.report_established_ils,
                                        initialReportLetter,
                                        "I L S",
                                        spellToPhonetic(airportLandingRunway, spell_runway)
                            );

            contactMsgVoice = towerContactVoice ~ contactMsgVoice;
        }

        approachRouteTextInstructions ~= "\n" ~ contactMsgText;
        approachRouteVoiceInstructions ~= "\n" ~ contactMsgVoice;

        atcReplyToRequest(message_approach_route_instructions);

        approachStatus = approach_status_landing;
    }
}

var getCallSign = func(mode)
{
    var cs = property_Setting_Callsign.getValue();

    if(mode != "Complete" and size(cs) > 3)
    {
        if(mode == "Last three letters")
            cs = substr(cs, size(cs) - 3);
        else
            cs = left(cs, 1) ~ substr(cs, size(cs) - 2);
    }

    return cs;
}

var getCallSignForAtc = func(initial)
{
    var cs = property_Setting_Callsign.getValue();
    var atcText = "";
    var atcVoice = "";

    if(includeManufacturer == "Yes" and aircraftManufacturer != "")
    {
        atcText ~= aircraftManufacturer ~ " ";
        atcVoice ~= aircraftManufacturer ~ " ";
    }

    if(initial == 0)
        cs = getCallSign(callsignMode);

    atcText ~= cs;
    atcVoice ~= spellToPhonetic(cs, spell_text);

    return [atcText, atcVoice];
}

var checkRadioIsType = func(radioType)
{
    if(selectedComStationType == radioType)
        return 1;

    var requestedRadio = nil;
    var towerRadio = nil;
    var i = 0;
    var check = 0;
    var radio = nil;

    for(i = 0; i < size(availableRadio); i += 1)
    {
        radio = availableRadio[i];

        if(radio.type == radioType and requestedRadio == nil)
            requestedRadio = radio;

        if(radio.type == radio_station_type_tower and towerRadio == nil)
            towerRadio = radio;
    }

    if(requestedRadio != nil)
        radio = requestedRadio;
    else if(towerRadio != nil)
        radio = towerRadio;
    else
        radio = nil;

    if(radio != nil)
    {
        if(selectedComFrequency == radio.frequency)
            return 1;

        if(radio == towerRadio and selectedComStationType == radio_station_type_tower)
            return 1;

        var text = sprintf(atcMessageReply.wrong_radio,
                        atcCallsignText,
                        selectedComStationName,
                        normalizeRadioStationName(radio.name),
                        sprintf("%.3f", radio.frequency)
                   );

        var voice = sprintf(atcMessageReply.wrong_radio,
                        atcCallsignVoice,
                        selectedComStationName,
                        normalizeRadioStationName(radio.name),
                        spellToPhonetic(sprintf("%.3f", radio.frequency), spell_number)
                    );

        pilotResponseType = message_contact_radio;
        contactRadio = radio;

        atcMessage(text, voice);

        check = 0;
    }
    else
        check = 1;

    return check;
}

var getAvailableRadios = func()
{
    availableRadio = {};

    if(selectedComStationType != nil and selectedComStationType != radio_station_type_unknown and selectedComAirportId != "")
        airport = airportinfo(selectedComAirportId);
    else if(currentAirport != nil)
        airport = currentAirport;
    else
        return;

    if(size(airport.comms()) == 0)
        return;

    var i = 0;
    var radioType = radio_station_type_unknown;

    foreach(var radio; airport.comms())
    {
        radioType = getRadioType(radio.ident);

        radioData = {name:getRadioFullName(airport.id, radio.ident),
                     airport:airport.name,
                     location:split(" ", airport.name)[0],
                     ident:radio.ident,
                     frequency:radio.frequency,
                     type:radioType
                    };

        availableRadio[i] = radioData;

        i += 1;
    }
}

var getRadio = func(radioType, type)
{
    var requestedRadio = nil;
    var i = 0;
    var radio = nil;
    var nradio = size(availableRadio);

    if(nradio > 0)
    {
        for(i = 0; i < nradio; i += 1)
        {
            radio = availableRadio[i];

            if(radio.type == radioType and requestedRadio == nil)
                requestedRadio = radio;
        }

        if(requestedRadio == nil and type == radio_type_any)
            requestedRadio = availableRadio[0];
    }

    return requestedRadio;
}

var getRadioType = func(radioIdent)
{
    if(radioIdent == nil)
        return radio_station_type_unknown;

    var radioType = radio_station_type_unknown;
    var name = string.lc(radioIdent);

    if(find("TWR", radioIdent) != -1 or find("tower", name) != -1)
        radioType = radio_station_type_tower;
    else if(find("APP", radioIdent) != -1 or find("approach", name) != -1)
        radioType = radio_station_type_approach;
    else if(find("GND", radioIdent) != -1 or find("ground", name) != -1 or find("grd", name) != -1)
        radioType = radio_station_type_ground;
    else if(find("ARR", radioIdent) != -1 or find("arrival", name) != -1 or find("director", name) != -1)
        radioType = radio_station_type_approach;
    else if(find("DEP", radioIdent) != -1 or find("departure", name) != -1)
        radioType = radio_station_type_departure;
    else if(find("DEL", radioIdent) != -1 or find("delivery", name) != -1 or find("clnc", name) != -1)
        radioType = radio_station_type_clearance;
    else if(find("apron", name) != -1 or find("APR", radioIdent) != -1)
        radioType = radio_station_type_approach;
    else if(find("traffic", name) != -1)
        radioType = radio_station_type_approach;
    else if(find("ATIS", radioIdent) != -1)
        radioType = radio_station_type_atis;
    else if(find("AFIS", radioIdent) != -1 or find("SERVICE", radioIdent) != -1)
        radioType = radio_station_type_atis;
    else if(find("CTAF", radioIdent) != -1)
        radioType = radio_station_type_ground;
    else if(find("CON", radioIdent) != -1)
        radioType = radio_station_type_approach;
    else if(find("radio", name) != -1 or find("rdo", name) != -1)
        radioType = radio_station_type_tower;
    else if(find("info", name) != -1 or find("ATC", radioIdent) != -1)
        radioType = radio_station_type_tower;
    else if(find("unicom", name) != -1)
        radioType = radio_station_type_tower;
    else if(find("centre", name) != -1 or find("cntr", name) != -1 or find("ctr", name) != -1)
        radioType = radio_station_type_tower;
    else if(find("MF", radioIdent) != -1 or find("MULT", radioIdent) != -1)
        radioType = radio_station_type_tower;
    else if(find("FSS", radioIdent) != -1 or find("FIS", radioIdent) != -1 or find("FS", radioIdent) != -1)
        radioType = radio_station_type_tower;
    else if(find("start", name) != -1 or find("taxi", name) != -1)
        radioType = radio_station_type_ground;
    else
        radioType = radio_station_type_tower;

    return radioType;
}

var getRadioFullName = func(airportID, radioName)
{
    if(airportID == nil or radioName == nil)
        return "";

    if(airportID == "" or radioName == "")
        return "";

    var airport = airportinfo(airportID);
    var radioFullName = "";

    if(airport != nil)
    {
        var airportCity = split(" ", airport.name)[0];

        if(string.lc(airportCity) != string.lc(split(" ", radioName)[0]))
            radioFullName = airportCity ~ " ";
        
        radioFullName ~= radioName;
    }
    else
        radioFullName = "";

    return radioFullName;
}

var getAirportRadio = func(airport, radioType)
{
    var requestedRadio = nil;
    var i = 0;
    var radio = nil;

    if(airport == nil)
        return nil;

    var nradio = size(airport.comms());

    if(nradio > 0)
    {
        foreach(radio; airport.comms())
        {
            if(getRadioType(radio.ident) == radioType and requestedRadio == nil)
                requestedRadio = radio;
        }

        if(requestedRadio == nil)
        {
            foreach(radio; airport.comms())
            {
                if(getRadioType(radio.ident) == radio_station_type_tower and requestedRadio == nil)
                    requestedRadio = radio;
            }
        }

        if(requestedRadio == nil)
            requestedRadio = airport.comms()[0];
    }
    
    if(requestedRadio != nil)
    {
        requestedRadio.name = getRadioFullName(airport.id, requestedRadio.ident);
        requestedRadio.airport = airport.name;
        requestedRadio.location = split(" ", airport.name)[0];
    }

    return requestedRadio;
}

var isRadioFrequencyOfType = func(frequency, radioType)
{
    var result = 0;
    var i = 0;
    var radio = nil;
    var nradio = size(availableRadio);

    if(nradio > 0)
    {
        for(i = 0; i < nradio and result == 0; i += 1)
        {
            radio = availableRadio[i];

            if(radio.type == radioType and radio.frequency == frequency)
                result = 1;
        }
    }

    return result;
}

var getRadioVolume = func(volumeProperty, volumeSelectedProperty)
{
    var commVolume = 0;

    if(volumeProperty != nil)
        commVolume = volumeProperty.getValue();

    if(commVolume == 0 and volumeSelectedProperty != nil)
        commVolume = volumeSelectedProperty.getValue();

    return commVolume;
}

var getRadioFrequency = func(frequency, realFrequency)
{
    var commFrequency = 0;

    if(realFrequency != nil)
        commFrequency = realFrequency.getValue();

    if(commFrequency == 0 and frequency != nil)
        commFrequency = frequency.getValue();

    return commFrequency;
}

var isRadioServiceable = func()
{
    var msg = "";

    if(selectedComServiceableProperty == nil)
        msg = atcMessageAction.bad_radio_data;
    else if(selectedComServiceable == 0 or selectedComPowerStatus == 0 or selectedComOperable == 0)
        msg = atcMessageAction.turn_radio_on;
    else if(selectedComVolume < 0.1)
    {
        if(selectedComRadio != "")
            msg = selectedComRadio ~ ": ";
        else
            msg = "";

        msg ~= atcMessageAction.radio_volume_up;
    }
    else if(radioSignalQuality() == 0)
    {
        if(selectedComRadio != "")
            msg = selectedComRadio ~ ": ";
        else
            msg = "";

        msg ~= atcMessageAction.no_radio_tuned;
    }

    if(msg != "")
    {
        showPopup(RGAtcName ~ ": " ~ msg);

        return 0;
    }

    return 1;
}

var isRadioTunedToApprovedCtrRadio = func()
{
    var radio = nil;
    var isTuned = 0;

    if(approvedCtr == nil)
        return 0;

    radio = getCtrRadio(approvedCtr);

    if(radio.frequency == selectedComFrequency)
        isTuned = 1;

    return isTuned;
}

var isRealMeteoEnabled = func()
{
    return property_RealWeather.getValue();
}

var getMeteoText = func(meteoType, voice)
{
    var meteo = "";
    var windFromDegrees = 0;
    var windSpeed = 0;
    var temperature = 0;
    var dewpoint = 0;
    var visibility = 0;
    var rain = 0;
    var snow = 0;
    var clouds = "";
    var cloudsElevation = 0;

    if(isRealMeteoEnabled() == 1)
    {
        windFromDegrees = int(property_Weather_Metar_WindDirectionDeg.getValue());
        windSpeed = int(property_Weather_Metar_WindSpeedKnots.getValue());
        temperature = int(property_Weather_Metar_Temperature.getValue());
        dewpoint = int(property_Weather_Metar_Dewpoint.getValue());
        visibility = int(property_Weather_Metar_Visibility.getValue() / 1000);
        
        if(property_Weather_Metar_Rain != nil)
            rain = property_Weather_Metar_Rain.getValue();
        else
            rain = 0;

        if(property_Weather_Metar_Snow != nil)
            snow = property_Weather_Metar_Snow.getValue();
        else
            snow = 0;

        if(property_Weather_Metar_CloudsCoverage != nil)
            clouds = property_Weather_Metar_CloudsCoverage.getValue();
        else
            clouds = "clear";

        if(property_Weather_Metar_CloudsElevationFeet != nil)
            cloudsElevation = property_Weather_Metar_CloudsElevationFeet.getValue();
        else
            cloudsElevation = 0;
    }
    else
    {
        windFromDegrees = int(property_Weather_WindDirectionDeg.getValue());
        windSpeed = int(property_Weather_WindSpeedKnots.getValue());
        temperature = int(property_Weather_Temperature.getValue());
        dewpoint = int(property_Weather_Dewpoint.getValue());
        visibility = int(property_Weather_Visibility.getValue() / 1000);

        if(property_Weather_Rain != nil)
            rain = property_Weather_Rain.getValue();
        else
            rain = 0;

        if(property_Weather_Snow != nil)
            snow = property_Weather_Snow.getValue();
        else
            snow = 0;

        if(property_Weather_CloudsCoverage != nil)
            clouds = property_Weather_CloudsCoverage.getValue();
        else
            clouds = "clear";

        if(property_Weather_CloudsElevationFeet != nil)
            cloudsElevation = property_Weather_CloudsElevationFeet.getValue();
        else
            cloudsElevation = 0;
    }

    (qnhValue, qnhLiteralValue) = getQNH();

    if(windSpeed > 0)
    {
        if(voice == 0)
        {
            meteo = sprintf(meteoMessage.wind_report,
                        sprintf("%d", windFromDegrees),
                        sprintf("%d", windSpeed)
                    );
        }
        else
        {
            meteo = sprintf(meteoMessage.wind_report,
                        spellToPhonetic(sprintf("%d", windFromDegrees), spell_number),
                        spellToPhonetic(sprintf("%d", windSpeed), spell_number)
                    );
        }
    }
    else
        meteo = meteoMessage.wind_calm;

    if(meteoType == meteo_type_full)
    {
        meteo ~= ", ";

        if(voice == 0)
        {
            meteo ~= sprintf(meteoMessage.full,
                        "QNH",
                        qnhValue,
                        sprintf("%d", temperature),
                        sprintf("%d", dewpoint),
                        sprintf("%d", visibility)
                    );
        }
        else
        {
            meteo ~= sprintf(meteoMessage.full,
                        "Q N H",
                        qnhLiteralValue,
                        spellToPhonetic(sprintf("%d", temperature), spell_number),
                        spellToPhonetic(sprintf("%d", dewpoint), spell_number),
                        spellToPhonetic(sprintf("%d", visibility), spell_number)
                    );
        }

        if(clouds != "clear")
        {
            meteo ~= ", ";

            if(voice == 0)
            {
                meteo ~= sprintf(meteoMessage.cloud_report,
                            clouds,
                            sprintf("%d", cloudsElevation)
                         );
            }
            else
            {
                meteo ~= sprintf(meteoMessage.cloud_report,
                            clouds,
                            spellToPhonetic(sprintf("%d", cloudsElevation), spell_number_to_literal)
                         );
            }
        }
        else
            meteo ~= ", " ~ meteoMessage.sky_clear;

        if(rain > 0)
        {
            var rainTag = "";

            if(rain < 0.3)
                rainTag = meteoMessage.light;
            else if(rain < 0.6)
                rainTag = meteoMessage.moderate;
            else
                rainTag = meteoMessage.heavy;

            meteo ~= ", ";

            meteo ~= sprintf(meteoMessage.rain_report,
                        rainTag
                     );
        }

        if(snow > 0)
        {
            var snowTag = "";

            if(snow < 0.3)
                snowTag = meteoMessage.light;
            else if(snow < 0.6)
                snowTag = meteoMessage.moderate;
            else
                snowTag = meteoMessage.heavy;

            meteo ~= ", ";

            meteo ~= sprintf(meteoMessage.snow_report,
                        snowTag
                     );

            if(isRealMeteoEnabled() == 1 and property_Weather_Metar_SnowCover != nil)
            {
                if(property_Weather_Metar_SnowCover.getValue() > 0)
                    meteo ~= " " ~ meteoMessage.cover;
            }
        }
    }
    else if(meteoType == meteo_type_qnh)
    {
        meteo ~= ", ";

        if(voice == 0)
        {
            meteo ~= sprintf(meteoMessage.qnh_report,
                        "QNH",
                        qnhValue
                    );
        }
        else
        {
            meteo ~= sprintf(meteoMessage.qnh_report,
                        "Q N H",
                        qnhLiteralValue
                    );
        }
    }

    return meteo;
}

var radioSignalQuality = func()
{
    var signal = 0;

    if(selectedComSignalQuality == nil)
        return 0;

    if(selectedComSignalQuality > 0)
    {
        if(selectedComSignalQuality < 0.05)
            signal = 0;
        else if(selectedComSignalQuality < 0.2)
            signal = 1;
        else if(selectedComSignalQuality < 0.3)
            signal = 2;
        else if(selectedComSignalQuality < 0.4)
            signal = 3;
        else if(selectedComSignalQuality < 0.5)
            signal = 4;
        else
            signal = 5;
    }
    else
        signal = 0;

    return signal;
}

var minPathDistance = func(pos, pathPos, pathHeading, pathLength, minDistance)
{
    var minDist = 9999;
    var course = 0;
    var dist = 0;
    var step = minDistance / 4;
    var cDist = 0;
    var cPos = pathPos;

    for(cDist = 0; cDist < pathLength; cDist += step)
    {
        cPos.apply_course_distance(pathHeading, step);

        (course, dist) = courseAndDistance(pos, cPos);

        if(dist < minDist)
            minDist = dist;
    }

    return minDist * NM2M;
}

var normalizeAltitudeHeading = func(altitude, heading, minAltitude)
{
    var normalizedAltitude = altitude;

    if(normalizedAltitude < minAltitude)
        normalizedAltitude = minAltitude;

    var normalizedAltitude = int(normalizedAltitude / 1000) * 1000;

    if(heading < 180)
    {
        if(math.mod(int(normalizedAltitude / 1000), 2) == 0)
            normalizedAltitude += 1000;
    }
    else
    {
        if(math.mod(int(normalizedAltitude / 1000), 2) == 1)
            normalizedAltitude += 1000;
    }

    normalizedAltitude += 500;

    return normalizedAltitude;
}

var getFlightPlanAltitude = func()
{
    var altitude = -1;
    var distance = 9999;
    var minCruiseAltidude = getMinCruiseAltitude();

    if(!property_Autopilot_RouteManagerActive.getValue())
        return -1;

    var wpnum = property_Autopilot_RouteManagerRouteNum.getValue() - 1;

    for(var i = property_Autopilot_RouteManagerCurrentWayPoint.getValue(); i < wpnum; i += 1)
    {
        var prop = sprintf("/autopilot/route-manager/route/wp[%d]/", i);

        var wpalt = getprop(prop ~ "altitude-ft");

        if(wpalt > 0)
        {
            var (wpcourse, wpdist) = courseAndDistance(geo.Coord.new().set_latlon(getprop(prop ~ "latitude-deg"), getprop(prop ~ "longitude-deg")));

            if(wpdist < distance and wpdist < flight_plan_min_distance)
            {
                distance = wpdist;

                altitude = wpalt;
            }
        }
    }

    if(altitude == -1)
    {
        altitude = property_Autopilot_RouteManagerCruiseAltitudeFeet.getValue();

        if(altitude < minCruiseAltidude)
            altitude = normalizeAltitudeHeading(property_Aircraft_AltitudeFeet.getValue(), heading, minCruiseAltidude);
    }

    return math.round(altitude, 100);
}

var getFlightLevelCode = func(level)
{
    var len = 0;

    if(level >= 10000)
        len = 3;
    else if(level >= 1000)
        len = 2;
    else
        len = 1;

    return substr(sprintf("%d", level), 0, len);
}

var flightLevelChangeSeconds = func(finalAltitude)
{
    var altitudeChange = abs(property_Aircraft_AltitudeFeet.getValue() - finalAltitude);

    return int((altitudeChange / flight_level_rate) * 60);
}

var getMinCruiseAltitude = func()
{
    var minCruiseAltidude = min_cruise_altitude;
    var safeAltitude = property_Aircraft_AltitudeFeet.getValue() - property_Aircraft_AltitudeAglFeet.getValue() + min_safe_altitude;

    if(minCruiseAltidude < safeAltitude)
        minCruiseAltidude = safeAltitude;

    return minCruiseAltidude;
}

var courseWithinDegrees = func(course, degrees, range)
{
    var inRange = 0;
    var degreeDiff = 360;
    var turnToDiff = "";

    (degreeDiff, turnToDiff) = degreesDifference(course, degrees);

    if(degreeDiff <= (range / 2))
        inRange = 1;

    return inRange;
}

var degreesDifference = func(fromDegrees, toDegrees)
{
    var degreeDiff = 0;
    var turnToDiff = "";

    degreeDiff = int(math.mod(((toDegrees - fromDegrees) + 180), 360) - 180);

    if(degreeDiff == 0)
        turnToDiff = "";
    else if(degreeDiff < 0)
        turnToDiff = "left";
    else
        turnToDiff = "right";

    return [abs(degreeDiff), turnToDiff];
}

var resetAircraftStatus = func()
{
    if(property_Aircraft_AltitudeAglFeet.getValue() > min_ground_altitude)
        aircraft_status = status_flying;
    else
        aircraft_status = status_going_around;
}

var spellToPhonetic = func(text, spellMode)
{
    var phoneticText = "";
    var length = size(text);

    if(spellMode == spell_number_to_literal)
        phoneticText = numberToLiteral(int(text));
    else
    {
        for(var i = 0; i < length; i += 1)
        {
            var character = chr(text[i]);

            if(string.isalpha(text[i]))
            {
                character = chr(string.toupper(text[i]));

                if(spellMode == spell_text or spellMode == spell_number)
                    phoneticText ~= phoneticLetter[character] ~ " ";
                else if(spellMode == spell_runway)
                {
                    var rwTag = "";

                    if(character == "L")
                        rwTag = "left";
                    else if(character == "R")
                        rwTag = "right";
                    else if(character == "C")
                        rwTag = "center";
                    else
                        rwTag = character;

                    phoneticText ~= rwTag ~ " ";
                }
            }
            else if(string.isdigit(text[i]))
                phoneticText ~= phoneticDigit[text[i] - 48] ~ " ";
            else if(character == ".")
                phoneticText ~= "decimal";
            else if(character == "-")
            {
                if(spellMode == spell_number)
                    phoneticText ~= "minus";
            }
            else if(character == "/")
            {
                # ignore slash
            }
            else if(character == "\n")
            {
                phoneticText ~= " ";
            }
            else
                phoneticText ~= character;

            if(i < length - 1)
                phoneticText ~= " ";
        }
    }

    return phoneticText;
}

var numberToLiteral = func(number)
{
    var text = "";
    var digit = 0;
    var tens = 0;
    var units = 0;

    digit = int(number / 1000);

    if(digit > 0)
    {
        if(digit < 20)
            text ~= phoneticNumber[digit];
        else
        {
            tens = int(digit / 10);

            if(tens > 0)
                text ~= phoneticTen[tens] ~ " ";

            units = digit - (tens * 10);

            if(units < 10 and units > 0)
                text ~= phoneticNumber[units];
        }

        text ~= " Thousand ";
    }

    number -= digit * 1000;

    digit = int(number / 100);

    if(digit > 0)
        text ~= phoneticNumber[digit] ~ " Hundred ";

    number -= digit * 100;

    if(number > 0)
    {
        if(size(text) > 0)
            text ~= "and ";

        if(number < 20)
            text ~=  phoneticNumber[number];
        else
        {
            digit = int(number / 10);

            if(digit > 0)
                text ~= phoneticTen[digit] ~ " ";

            number -= digit * 10;

            if(number < 10 and number > 0)
                text ~= phoneticNumber[number];
        }
    }

    return text;
}

var getMessageText = func(messageType)
{
    var message = "";

    if(messageType == message_radio_check)
        message = atcMessageRequest.radio_check;
    else if(messageType == message_engine_start)
        message = atcMessageRequest.engine_start;
    else if(messageType == message_departure_information)
        message = atcMessageRequest.departure_information;
    else if(messageType == message_request_taxi)
        message = atcMessageRequest.request_taxi;
    else if(messageType == message_ready_for_departure)
        message = atcMessageRequest.ready_departure;
    else if(messageType == message_abort_departure)
        message = atcMessageRequest.abort_departure;
    else if(messageType == message_request_approach)
        message = atcMessageRequest.request_approach;
    else if(messageType == message_request_ils)
        message = atcMessageRequest.request_ils;
    else if(messageType == message_airfield_in_sight)
        message = atcMessageRequest.airfield_in_sight;
    else if(messageType == message_ils_established)
        message = atcMessageRequest.ils_established;

    return message;
}

var normalizeRadioStationName = func(text)
{
    if(text == nil or text == "")
        return "";

    var word = split(" ", text);
    var wlen = size(word);
    var wspace = wlen - 1;
    var stationName = "";

    for(var i = 0; i < wlen; i += 1)
    {
        var w = string.lc(word[i]);

        if(w == "twr")
            w = "tower";
        else if(w == "app")
            w = "approach";
        else if(w == "apron")
            w = "approach On";
        else if(w == "gnd")
            w = "ground";
        else if(w == "gnd/apron")
            w = "ground";
        else if(w == "arr")
            w = "arrival";
        else if(w == "dep")
            w = "departure";
        else if(w == "del")
            w = "delivery";
        else if(w == "clnc")
            w = "clearance";
        else if(w == "ctaf")
            w = "CTAF";
        else if(w == "awos")
            w = "AWOS";
        else if(w == "afis")
            w = "AFIS";
        else if(w == "atis")
            w = "ATIS";
        else if(w == "unicom")
            w = "Universal communications";

        stationName ~= string.uc(left(w, 1)) ~ substr(w, 1) ;

        if(i < wspace)
            stationName ~= " ";
    }

    return stationName;
}

var setPilotMessageSeconds = func(delay)
{
    pilot_message_wait_seconds = delay;

    pilot_message_counter = 0;
}

var cancelPilotPendingMessage = func()
{
    pilot_message_wait_seconds = -1;
    pilot_message_counter = 0;

    pilot_response_wait_seconds = -1;
    pilot_response_counter = 0;
}

var setAtcAutoCallbackAfterSeconds = func(delay)
{
    atc_callback_wait_seconds = delay;

    atc_callback_seconds_counter = 0;
}

var addSecondsToAtcAutoCallback = func(delay)
{
    atc_callback_wait_seconds += delay;
}

var cancelAtcPendingMessage = func()
{
    atc_callback_seconds_counter = 0;

    altitude_check_counter = 0;

    altitude_change_counter = 0;
}

var getNearbyCtr = func(range)
{
    var airport = nil;
    var nearByAirports = nil;
    var minDistance = range;
    var nearestCtr = nil;
    var ctrData = nil;
    var radio = nil;

    airport = airportinfo();

    if(airport != nil)
    {
        ctrData = getCtrData(airport);

        if(ctrData != nil and ctrData.status == ctr_status_inside)
        {
            if(approvedCtr != nil)
            {
                if(ctrData.ident != approvedCtr.ident or isRadioTunedToApprovedCtrRadio == 0)
                    return ctrData;
            }
            else
                return ctrData;
        }
    }

    nearByAirports = findAirportsWithinRange(range);

    foreach(airport; nearByAirports)
    {
        ctrData = getCtrData(airport);

        if(ctrData != nil)
        {
            if(approvedCtr != nil and ctrData.ident == approvedCtr.ident)
            {
                # ignore currently approved CTR
            }
            else if(ctrData.status == ctr_status_inside)
            {
                nearestCtr = ctrData;

                minDistance = 0;
            }
            else if(ctrData.status == ctr_status_in_range and ctrData.distance_from_range < minDistance)
            {
                minDistance = ctrData.distance_from_range;

                nearestCtr = ctrData;
            }
        }
    }

    return nearestCtr;
}

var getCtrData = func(airport)
{
    var course = 0;
    var distance = 0;
    var range = 0;
    var rangeDistance = 0;
    var status = ctr_status_outside;
    var aircraftHeading = property_Aircraft_HeadingDeg.getValue();

    if(airport == nil)
        return nil;

    var nradios = size(airport.comms());

    if(nradios == 0)
        return nil;

    var pos = geo.Coord.new().set_latlon(airport.lat, airport.lon);

    (course, distance) = courseAndDistance(pos);

    if(nradios > 5)
        range = ctr_range_wide;
    else if(nradios > 1)
        range = ctr_range_medium;
    else
        range = ctr_range_short;

    if(distance < range)
    {
        status = ctr_status_inside;

        rangeDistance = 0;
    }
    else if(courseWithinDegrees(aircraftHeading, course, ctr_maximum_range_angle) == 1)
    {
        if((distance - range) < ctr_maximum_range_distance)
        {
            status = ctr_status_in_range;

            rangeDistance = distance - range;
        }
        else
        {
            status = ctr_status_outside;

            rangeDistance = 0;
        }
    }
    else
    {
        status = ctr_status_outside;

        rangeDistance = 0;
    }

    var ctrData = {
                    ident:airport.id,
                    airport:airport.name,
                    lat:airport.lat,
                    lon:airport.lon,
                    range:range,
                    course:course,
                    distance:distance,
                    distance_from_range:rangeDistance,
                    status:status
                  };

    return ctrData;
}

var getCtrRadio = func(ctr)
{
    var radioType = radio_station_type_approach;
    var radio = nil;

    if(ctr == nil)
        return nil;

    if(aircraftIsDeparting == 1)
        radioType = radio_station_type_departure;

    radio = getAirportRadio(airportinfo(ctr.ident), radioType);

    if(radio == nil)
        return nil;

    if(getRadioType(radio.ident) != radioType)
        radio = getAirportRadio(airportinfo(ctr.ident), radio_station_type_approach);

    return radio;
}

var getQNH = func()
{
    var qnhinhg = 0;
    var qnhhpa = 0;
    var qnhValue = "";
    var qnhLiteralValue = "";

    if(isRealMeteoEnabled() == 1)
    {
        if(property_Weather_QnhInHg != nil)
            qnhinhg = property_Weather_Metar_QnhInHg.getValue();
        else
            qnhinhg = 0;
    }
    else
    {
        if(property_Weather_QnhInHg != nil)
            qnhinhg = property_Weather_QnhInHg.getValue();
        else
            qnhinhg = 0;
    }

    qnhhpa = int(qnhinhg / 0.02953);

    if(qnhUnitMeasure == "hPa")
    {
        qnhValue = sprintf("%d hPa", qnhhpa);
        qnhLiteralValue = spellToPhonetic(sprintf("%d", qnhhpa), spell_number) ~ " hecto pascal";
    }
    else if(qnhUnitMeasure == "inHg")
    {
        qnhValue = sprintf("%.2f inHg", qnhinhg);
        qnhLiteralValue = spellToPhonetic(sprintf("%.2f" ,qnhinhg), spell_number) ~ " inches of mercury";
    }
    else
    {
        qnhValue = sprintf("%d hPa or %.2f inHg", qnhhpa, qnhinhg);
        qnhLiteralValue = spellToPhonetic(sprintf("%d", qnhhpa), spell_number) ~ " hecto pascal or ";
        qnhLiteralValue ~= spellToPhonetic(sprintf("%.2f", qnhinhg), spell_number) ~ " inches of mercury";
    }

    return [qnhValue, qnhLiteralValue];
}

var isInsideCtr = func(airport)
{
    if(airport == nil)
        return 0;

    var ctrData = getCtrData(airport);
    var isInside = 0;

    if(ctrData != nil and ctrData.status == ctr_status_inside)
        isInside = 1;
    else
        isInside = 0;

    return isInside;
}

var getCtrAtcMessage = func(request)
{
    var text = "";
    var voice = "";
    var extraText = "";
    var extraVoice = "";

    (atcCallsignText, atcCallsignVoice) = getCallSignForAtc(0);

    if(request == ctr_request_approved)
    {
        if(squawkingMode == "On")
        {
            var code = getSquawkCode();

            if(code != squawkCode)
            {
                squawkCode = code;

                extraText = sprintf(", Squawk %s and IDENT", squawkCode);
                extraVoice = sprintf(", Squawk %s and ident", spellToPhonetic(squawkCode, spell_number));

                squawkChange = 1;

                setSquawkIdentMode(squawk_ident_code);
            }
            else
            {
                extraText = ", Squawk IDENT";
                extraVoice = ", Squawk ident";

                squawkChange = 0;

                setSquawkIdentMode(squawk_ident_only);
            }
        }
        else
        {
            extraText = "";
            extraVoice = "";
        }

        text = sprintf(atcMessageReply.ctr_approved,
                        atcCallsignText,
                        selectedComStationName,
                        "CTR",
                        extraText
                    );

        voice = sprintf(atcMessageReply.ctr_approved,
                        atcCallsignVoice,
                        selectedComStationName,
                        "C T R",
                        extraVoice
                    );
    }
    else if(request == ctr_already_approved)
    {
        if(squawkingMode == "On")
        {
            if(squawkCode == "")
                squawkCode = getSquawkCode();

            extraText = sprintf(", Squawk %s", squawkCode);
            extraVoice = sprintf(", Squawk %s", spellToPhonetic(squawkCode, spell_number));

            setSquawkIdentMode(squawk_ident_code);
        }
        else
        {
            extraText = "";
            extraVoice = "";

            setSquawkIdentMode(squawk_ident_off);
        }

        text = sprintf(atcMessageReply.ctr_already_approved,
                        atcCallsignText,
                        selectedComStationName,
                        "CTR",
                        extraText
                    );

        voice = sprintf(atcMessageReply.ctr_already_approved,
                        atcCallsignVoice,
                        selectedComStationName,
                        "C T R",
                        extraVoice
                    );
    }
    else
    {
        text = sprintf(atcMessageReply.ctr_not_approved,
                        atcCallsignText,
                        selectedComStationName,
                        "CTR",
                        "CTR"
                    );

        voice = sprintf(atcMessageReply.ctr_not_approved,
                        atcCallsignVoice,
                        selectedComStationName,
                        "C T R",
                        "C T R"
                    );
    }

    return [text, voice];
}

var isTerrainSafeAhead = func()
{
    var safe = 0;
    var aircraftPosition = geo.aircraft_position();
    var pathPosition = geo.aircraft_position().apply_course_distance(property_Aircraft_HeadingDeg.getValue(), min_safety_distance_from_terrain_miles * NM2M);

    var intersection = get_cart_ground_intersection({
                                                        "x":aircraftPosition.x(),
                                                        "y":aircraftPosition.y(),
                                                        "z":aircraftPosition.z()
                                                    },
                                                    {
                                                        "x":pathPosition.x()-aircraftPosition.x(),
                                                        "y":pathPosition.y()-aircraftPosition.y(),
                                                        "z":pathPosition.z()-aircraftPosition.z()
                                                    }
                                                   );

    if(intersection == nil)
        safe = 1;
    else
    {
        var terrainPos = geo.Coord.new();

        terrainPos.set_latlon(intersection.lat, intersection.lon, intersection.elevation);

        var maxDist = aircraftPosition.direct_distance_to(pathPosition);
        var terrainDist = aircraftPosition.direct_distance_to(terrainPos);

        if(terrainDist < maxDist)
            safe = 0;
        else
            safe = 1;
    }

    return safe;
}

var isSimulationPaused = func()
{
    var paused = 0;

    if(property_Simulator_Freeze.getValue() == 1 or property_Simulator_Replay.getValue() == 1)
        paused = 1;

    return paused;
}

var altitudeApproachSlope = func(altitude, distance, roundHundred = 0)
{
    if(altitude < 0 or distance < 0)
        return -1;

    slopeRadians = approach_slope_angle * D2R;
    ralt = math.sin(slopeRadians);
    rdist = math.cos(slopeRadians);

    slopeAltitude = ((distance / rdist) * ralt) * NM2FT;

    slopeAltitude += altitude * M2FT;

    if(roundHundred == 1)
        slopeAltitude = (100 * int(slopeAltitude / 100));

    return slopeAltitude;
}

var getSquawkCode = func()
{
    code = squawkCode;

    if(code == "" or rand() < 0.3)
    {
        codeOk = 0;

        while(codeOk == 0)
        {
            tempCode = int(rand() * 7776) + 1;

            codeOk = 1;

            foreach(var c; reservedSquawkCodes)
            {
                if(tempCode == c)
                    codeOk = 0;
            }

            newCode = sprintf("0000%d", tempCode);

            newCode = substr(newCode, size(newCode) - 4);
            clen = size(newCode);

            for(var i = 0; i < clen; i += 1)
            {
                if(int(chr(newCode[i])) > 7)
                    codeOk = 0;
            }
        }

        code = newCode;
    }

    return code;
}

var getOperatingTransponder = func()
{
    if(property_Transponder1_Serviceable != nil and
       property_Transponder1_Operable != nil and
       property_Transponder1_KnobMode != nil)
    {
        if(property_Transponder1_Serviceable.getValue() == 1 and property_Transponder1_Operable.getValue() == 1 and property_Transponder1_KnobMode.getValue() > 3)
            return 1;
    }

    if(property_Transponder2_Serviceable != nil and
       property_Transponder2_Operable != nil and
       property_Transponder2_KnobMode != nil)
    {
        if(property_Transponder2_Serviceable.getValue() == 1 and property_Transponder2_Operable.getValue() == 1 and property_Transponder2_KnobMode.getValue() > 3)
            return 2;
    }

    if(property_Transponder3_Serviceable != nil and
       property_Transponder3_Operable != nil and
       property_Transponder3_KnobMode != nil)
    {
        if(property_Transponder3_Serviceable.getValue() == 1 and property_Transponder3_Operable.getValue() == 1 and property_Transponder3_KnobMode.getValue() > 3)
            return 3;
    }

    return 0;
}

var getTransponderSquawkCode = func(transponder)
{
    var idCodeProperty = nil;

    if(transponder == 1)
        idCodeProperty = property_Transponder1_IdCode;
    else if(transponder == 2)
        idCodeProperty = property_Transponder2_IdCode;
    else if(transponder == 3)
        idCodeProperty = property_Transponder3_IdCode;

    if(idCodeProperty == nil)
        return "";

    var idCode = idCodeProperty.getValue();

    if(idCode == nil or idCode == "")
        return "";

    return sprintf("%04d", int(idCode));
}

var getEmergencySquawkCode = func(transponder)
{
    var code = getTransponderSquawkCode(transponder);

    if(code == "7500" or code == "7600" or code == "7700")
        return code;

    return "";
}

var checkTransponder = func(transponder)
{
    var serviceable = nil;
    var operable = nil;

    if(transponder == 1 and property_Transponder1_Serviceable != nil and
       property_Transponder1_Operable != nil and property_Transponder1_IdCode != nil)
    {
        serviceable = property_Transponder1_Serviceable.getValue();
        operable = property_Transponder1_Operable.getValue();
    }
    else if(transponder == 2 and property_Transponder2_Serviceable != nil and
            property_Transponder2_Operable != nil and property_Transponder2_IdCode != nil)
    {
        serviceable = property_Transponder2_Serviceable.getValue();
        operable = property_Transponder2_Operable.getValue();
    }
    else if(transponder == 3 and property_Transponder3_Serviceable != nil and
            property_Transponder3_Operable != nil and property_Transponder3_IdCode != nil)
    {
        serviceable = property_Transponder3_Serviceable.getValue();
        operable = property_Transponder3_Operable.getValue();
    }
    else
        return 0;

    if(serviceable == 0)
        return 0;

    if(operable == 0)
        return 0;

    if(getTransponderSquawkCode(transponder) != squawkCode)
        return 0;

    return 1;
}

var checkTransponderIdent = func(transponder)
{
    var ident = 0;

    if(transponder == 1 and property_Transponder1_Ident != nil)
        ident = property_Transponder1_Ident.getValue();
    else if(transponder == 2 and property_Transponder2_Ident != nil)
        ident = property_Transponder2_Ident.getValue();
    else if(transponder == 3 and property_Transponder3_Ident != nil)
        ident = property_Transponder3_Ident.getValue();
    else
        return 0;

    return ident;
}

var setSquawkIdentMode = func(mode)
{
    squawkIdent = mode;

    if(mode == squawk_ident_off)
        squawkIdentButtonPushed = 0;

    squawk_check_counter = 0;
}

var getPilotVoice = func()
{
    var done = 0;
    var i = 0;
    var pvoice = "";
    var ptype = "";
    var vdesc = "";

    while(done == 0)
    {
        if(i == 0)
            vprop = "/sim/sound/voices/voice";
        else
            vprop = sprintf("/sim/sound/voices/voice[%d]", i);

        vdesc = vprop ~ "/desc";

        if(getprop(vdesc) == nil)
        {
            done = 1;

            pvoice = "/sim/sound/voices/pilot";
        }
        else
        {
            if(string.lc(getprop(vdesc)) == "pilot")
            {
                pvoice = props.globals.getNode(vprop ~ "/text");

                if(getprop(sprintf("%s/festival", vprop)) == 1)
                {
                    if(string.match(getprop(sprintf("%s/preamble", vprop)), "*(audio_mode 'async)*") == 1)
                        ptype = "festival-async";
                    else
                        ptype = "festival";
                }
                else
                    ptype = "flite";

                done = 1;
            }
        }

        i += 1;
    }

    return { text:pvoice, type:ptype };
}

var initAtcVoice = func()
{
    synthVoice = [];
    var done = 0;
    var i = 0;
    var vdesc = "";

    synthVoice = [];
    usedSynthVoice = [];
    stationVoice = {};
    stationVoicePool = [];

    while(done == 0)
    {
        if(i == 0)
            vprop = "/sim/sound/voices/voice";
        else
            vprop = sprintf("/sim/sound/voices/voice[%d]", i);

        vdesc = vprop ~ "/desc";

        if(getprop(vdesc) == nil)
            done = 1;
        else
        {
            if(string.lc(getprop(vdesc)) != "pilot")
            {
                var pvoice = {};

                pvoice['text'] = props.globals.getNode(vprop ~ "/text");

                if(getprop(sprintf("/sim/sound/voices/voice[%d]/festival", i)) == 1)
                {
                    if(string.match(getprop(sprintf("/sim/sound/voices/voice[%d]/preamble", i)), "*(audio_mode 'async)*") == 1)
                        pvoice['type'] = "festival-async";
                    else
                        pvoice['type'] = "festival";
                }
                else
                    pvoice['type'] = "flite";

                append(synthVoice, pvoice);
            }
        }

        i += 1;
    }
}

var getSynthVoice = func(frequency)
{
    var voiceIsValid = 0;
    var svoice = {};
    var i = 0;
    var vndx = 0;
    var svsize = size(synthVoice);
    var usvsize = size(usedSynthVoice);
    var svpsize = size(stationVoicePool);

    if(frequency == "")
    {
        if(svsize > 0)
            return synthVoice[0];
        else
            return { text:"/sim/sound/voices/voice/atc", type:"flite" };
    }

    if(svpsize > 0)
    {
        for(i = 0; i < svpsize; i += 1)
        {
            svoice = stationVoicePool[i];

            if(svoice['frequency'] == frequency)
                return svoice;
        }
    }

    voiceIsValid = 0;

    while(voiceIsValid == 0)
    {
        vndx = int(rand() * svsize);

        voiceIsValid = 1;

        foreach(var usv; usedSynthVoice)
        {
            if(usv['index'] == vndx)
                voiceIsValid = 0;
        }
    }

    svoice = {};

    svoice['index'] = vndx;
    svoice['text'] = synthVoice[vndx]['text'];
    svoice['type'] = synthVoice[vndx]['type'];
    svoice['frequency'] = frequency;

    append(usedSynthVoice, svoice);

    append(stationVoicePool, svoice);

    if(size(usedSynthVoice) == svsize)
        usedSynthVoice = [];

    return svoice;
}

var speak = func(text, voice, type)
{
    if(type == "festival-async")
    {
        var tpart = split(",", text);

        foreach(var t; tpart)
        {
            var tpart1 = split("\n", t);

            foreach(var t1; tpart1)
                voice.setValue(t1 ~ ".");
        }
    }
    else
        voice.setValue(text);
}

var autoATCMessageDelay = func(seconds)
{
    ctr_update_counter -= seconds;
    ctr_check_counter -= seconds;

    terrain_warning_counter -= seconds;

    if(terrain_warning_counter < 0)
        terrain_warning_counter = 0;

    altitude_check_counter -= seconds;

    if(altitude_check_counter < 0)
        altitude_check_counter = 0;

    squawk_check_counter -= seconds;

    if(squawk_check_counter < 0)
        squawk_check_counter = 0;

    approach_check_counter -= seconds;

    if(approach_check_counter < 0)
        approach_check_counter = 0;
}
