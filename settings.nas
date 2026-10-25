#
# Red Griffin ATC - Speaking Air Traffic Controller for FlightGear
#
# Written and developer by Antonello Biancalana (Red Griffin, IK0TOJ)
#
# Copyright (C) 2019-2021 Antonello Biancalana
#
# settings.nas
#
# Global variables for Red Griffin ATC (rgatc.nas)
#
# Version 2.5.0 - 25 October 2026
#
# Red Griffin ATC is an Open Source project and it is licensed
# under the Gnu Public License v3 (GPLv3)
#

var rgatcPropNode = "/rgatc";

var default_setting_open_dialog_startup = "Off";
var default_setting_dialog_position = "Bottom Left";
var default_setting_atc_text_position = "Top Center";
var default_setting_atc_text_transparency = "Medium";
var default_setting_callsign = property_MultiplayCallsign.getValue();
var default_setting_callsign_mode = "Complete";
var default_setting_include_manufacturer = "Yes";
var default_setting_pilot_request_mode = "Voice and text";
var default_setting_pilot_response_mode = "Voice and text";
var default_setting_atc_message_mode = "Voice and text";
var default_setting_qnh = "hPa and inHg";
var default_setting_atc_radio = "Auto";
var default_setting_aircraft_type = "Auto";
var default_setting_squawking = "On";
var default_setting_slope_angle = 3.0;
var default_setting_too_low_warning = "On";
var default_setting_terrain_warning = "On";
var default_setting_multiplayer_chat_echo = "Off";

var settingsFileName = getprop("/sim/fg-home") ~ "/Export/RedGriffinATC-config.xml";

var settings = nil;

var initSettings = func()
{
    if(default_setting_callsign == "" or default_setting_callsign == nil)
        default_setting_callsign = "RG-ATC";

    loadSettings();

    if(settings == nil or property_Setting_DialogPosition.getValue() == "" or property_Setting_DialogPosition.getValue() == nil)
        resetSettings();
}

var resetSettings = func()
{
    property_Setting_OpenDialogStartup.setValue(default_setting_open_dialog_startup);
    property_Setting_DialogPosition.setValue(default_setting_dialog_position);
    property_Setting_AtcTextPosition.setValue(default_setting_atc_text_position);
    property_Setting_AtcTextTransparency.setValue(default_setting_atc_text_transparency);
    property_Setting_Callsign.setValue(default_setting_callsign);
    property_Setting_CallsignMode.setValue(default_setting_callsign_mode);
    property_Setting_IncludeManufacturer.setValue(default_setting_include_manufacturer);
    property_Setting_PilotRequestMode.setValue(default_setting_pilot_request_mode);
    property_Setting_PilotResponseMode.setValue(default_setting_pilot_response_mode);
    property_Setting_AtcMessageMode.setValue(default_setting_atc_message_mode);
    property_Setting_QnhUnitMeasure.setValue(default_setting_qnh);
    property_Setting_AtcRadioMode.setValue(default_setting_atc_radio);
    property_Setting_AircraftType.setValue(default_setting_aircraft_type);
    property_Setting_SquawkingMode.setValue(default_setting_squawking);
    property_Setting_SlopeAngle.setValue(default_setting_slope_angle);
    property_Setting_TooLowWarningMode.setValue(default_setting_too_low_warning);
    property_Setting_TerrainWarningMode.setValue(default_setting_terrain_warning);
    property_Setting_MultiplayerChatEcho.setValue(default_setting_multiplayer_chat_echo);

    applySettings();
}

var applySettings = func()
{
    openDialogStartup = property_Setting_OpenDialogStartup.getValue();
    dialogPosition = property_Setting_DialogPosition.getValue();
    atcTextPosition = property_Setting_AtcTextPosition.getValue();
    atcTextTransparency = property_Setting_AtcTextTransparency.getValue();
    callsign = property_Setting_Callsign.getValue();
    callsignMode = property_Setting_CallsignMode.getValue();
    includeManufacturer = property_Setting_IncludeManufacturer.getValue();
    pilotRequestMode = property_Setting_PilotRequestMode.getValue();
    pilotResponseMode = property_Setting_PilotResponseMode.getValue();
    atcMessageMode = property_Setting_AtcMessageMode.getValue();
    qnhUnitMeasure = property_Setting_QnhUnitMeasure.getValue();
    atcRadioMode = property_Setting_AtcRadioMode.getValue();
    aircraftType = getAircraftType();
    squawkingMode = property_Setting_SquawkingMode.getValue();
    slopeAngle = property_Setting_SlopeAngle.getValue();
    tooLowWarningMode = property_Setting_TooLowWarningMode.getValue();
    terrainWarningMode = property_Setting_TerrainWarningMode.getValue();
    multiplayerChatEcho = property_Setting_MultiplayerChatEcho.getValue();

    if(openDialogStartup == nil or openDialogStartup == "")
    {
        openDialogStartup = default_setting_open_dialog_startup;

        property_Setting_OpenDialogStartup.setValue(default_setting_open_dialog_startup);
    }

    if(dialogPosition == nil or dialogPosition == "")
    {
        dialogPosition = default_setting_dialog_position;

        property_Setting_DialogPosition.setValue(default_setting_dialog_position);
    }

    if(atcTextPosition == nil or atcTextPosition == "")
    {
        atcTextPosition = default_setting_atc_text_position;

        property_Setting_AtcTextPosition.setValue(default_setting_atc_text_position);
    }

    if(atcTextTransparency == nil or atcTextTransparency == "")
    {
        atcTextTransparency = default_setting_atc_text_transparency;

        property_Setting_AtcTextTransparency.setValue(default_setting_atc_text_transparency);
    }

    if(callsign == nil or callsign == "")
    {
        callsign = default_setting_callsign;

        property_Setting_Callsign.setValue(default_setting_callsign);
    }

    if(callsignMode == nil or callsignMode == "")
    {
        callsignMode = default_setting_callsign_mode;

        property_Setting_CallsignMode.setValue(default_setting_callsign_mode);
    }

    if(includeManufacturer == nil or includeManufacturer == "")
    {
        includeManufacturer = default_setting_include_manufacturer;

        property_Setting_IncludeManufacturer.setValue(default_setting_include_manufacturer);
    }

    if(pilotRequestMode == nil or pilotRequestMode == "")
    {
        pilotRequestMode = default_setting_pilot_request_mode;

        property_Setting_PilotRequestMode.setValue(default_setting_pilot_request_mode);
    }

    if(pilotResponseMode == nil or pilotResponseMode == "")
    {
        pilotResponseMode = default_setting_pilot_response_mode;

        property_Setting_PilotResponseMode.setValue(default_setting_pilot_response_mode);
    }

    if(atcMessageMode == nil or atcMessageMode == "")
    {
        atcMessageMode = default_setting_atc_message_mode;

        property_Setting_AtcMessageMode.setValue(default_setting_atc_message_mode);
    }

    if(qnhUnitMeasure == nil or qnhUnitMeasure == "")
    {
        qnhUnitMeasure = default_setting_qnh;

        property_Setting_QnhUnitMeasure.setValue(default_setting_qnh);
    }

    if(atcRadioMode == nil or atcRadioMode == "")
    {
        atcRadioMode = default_setting_atc_radio;

        property_Setting_AtcRadioMode.setValue(default_setting_atc_radio);
    }

    if(aircraftType == nil or aircraftType == "")
    {
        property_Setting_AircraftType.setValue(default_setting_aircraft_type);

        aircraftType = getAircraftType();
    }

    if(squawkingMode == nil or squawkingMode == "")
    {
        squawkingMode = default_setting_squawking;

        property_Setting_SquawkingMode.setValue(default_setting_squawking);
    }

    if(slopeAngle == nil or slopeAngle == "")
    {
        slopeAngle = default_setting_slope_angle;

        property_Setting_SlopeAngle.setValue(default_setting_slope_angle);
    }

    if(num(slopeAngle) < 2 or num(slopeAngle) > 8)
    {
        slopeAngle = default_setting_slope_angle;

        property_Setting_SlopeAngle.setValue(default_setting_slope_angle);
    }

    if(slopeAngle == nil or slopeAngle == "" or num(slopeAngle) == nil)
    {
        slopeAngle = default_setting_slope_angle;

        property_Setting_SlopeAngle.setValue(default_setting_slope_angle);
    }

    if(tooLowWarningMode == nil or tooLowWarningMode == "")
    {
        tooLowWarningMode = default_setting_too_low_warning;

        property_Setting_TooLowWarningMode.setValue(default_setting_too_low_warning);
    }

    if(terrainWarningMode == nil or terrainWarningMode == "")
    {
        terrainWarningMode = default_setting_terrain_warning;

        property_Setting_TerrainWarningMode.setValue(default_setting_terrain_warning);
    }

    if(multiplayerChatEcho == nil or multiplayerChatEcho == "")
    {
        multiplayerChatEcho = default_setting_multiplayer_chat_echo;

        property_Setting_MultiplayerChatEcho.setValue(default_setting_multiplayer_chat_echo);
    }

    property_Setting_Callsign.setValue(string.uc(callsign));

    property_MultiplayCallsign.setValue(string.uc(callsign));
    property_UserCallsign.setValue(string.uc(callsign));

    (atcCallsignText, atcCallsignVoice) = getCallSignForAtc(1);

    approach_slope_angle = num(slopeAngle);

    setAtcTextPosition();

    setDialogPosition();

    setAircraftType();

    saveSettings();

    if(aircraftType == aircraft_type_unknown)
        gui.showDialog("set-aircraft-type-dialog");
}

var saveSettings = func()
{
    settings = props.globals.getNode(rgatcPropNode);

    io.write_properties(settingsFileName, settings);
}

var loadSettings = func()
{
    settings = io.read_properties(settingsFileName, rgatcPropNode);

    if(settings != nil)
        applySettings();

    return settings;
}

var setAircraftType = func()
{
    var atype = getAircraftType();

    if(atype == aircraft_type_small_single_engine)
    {
        min_cruise_altitude = 3500;

        pattern_speed = 100;
        approach_speed = 90;
        final_speed = 70;
        flight_level_rate = 1000;

        approach_point_distance = -10;
        pattern_point_distance = -3;
        approach_turn_distance = 0.8;

        altitude_check_interval = 90;
    }
    else if(atype == aircraft_type_small_multi_engine)
    {
        min_cruise_altitude = 3500;

        pattern_speed = 120;
        approach_speed = 100;
        final_speed = 85;
        flight_level_rate = 1000;

        approach_point_distance = -10;
        pattern_point_distance = -3;
        approach_turn_distance = 1.0;

        altitude_check_interval = 90;
    }
    else if(atype == aircraft_type_executive_turboprop_jet)
    {
        min_cruise_altitude = 5500;

        pattern_speed = 160;
        approach_speed = 140;
        final_speed = 120;
        flight_level_rate = 1200;

        approach_point_distance = -12;
        pattern_point_distance = -5;
        approach_turn_distance = 1.8;

        altitude_check_interval = 75;
    }
    else if(atype == aircraft_type_business_jet)
    {
        min_cruise_altitude = 5500;

        pattern_speed = 170;
        approach_speed = 150;
        final_speed = 130;
        flight_level_rate = 1500;

        approach_point_distance = -15;
        pattern_point_distance = -5;
        approach_turn_distance = 1.8;

        altitude_check_interval = 45;
    }
    else if(atype == aircraft_type_airline_jet)
    {
        min_cruise_altitude = 7500;

        pattern_speed = 180;
        approach_speed = 160;
        final_speed = 140;
        flight_level_rate = 1500;

        approach_point_distance = -15;
        pattern_point_distance = -6;
        approach_turn_distance = 2.3;

        altitude_check_interval = 45;
    }
    else if(atype == aircraft_type_large_military_jet)
    {
        min_cruise_altitude = 8500;

        pattern_speed = 210;
        approach_speed = 190;
        final_speed = 150;
        flight_level_rate = 1500;

        approach_point_distance = -15;
        pattern_point_distance = -7;
        approach_turn_distance = 2.3;

        altitude_check_interval = 45;
    }
    else if(atype == aircraft_type_special_military)
    {
        min_cruise_altitude = 8500;

        pattern_speed = 210;
        approach_speed = 190;
        final_speed = 150;
        flight_level_rate = 2000;

        approach_point_distance = -15;
        pattern_point_distance = -8;
        approach_turn_distance = 2.3;

        altitude_check_interval = 45;
    }
    else
    {
        min_cruise_altitude = 3500;

        pattern_speed = 100;
        approach_speed = 90;
        final_speed = 70;
        flight_level_rate = 1000;

        approach_point_distance = -10;
        pattern_point_distance = -3;
        approach_turn_distance = 0.8;

        altitude_check_interval = 90;
    }

    setRGTitle();
}

var getAircraftType = func()
{
    var aType = property_Setting_AircraftType.getValue();

    if(aType == "Auto")
    {
        if(isTagDefined("fighter") == 1 or isTagDefined("interceptor") == 1 or isTagDefined("combat") == 1)
        {
            if(isTagDefined("bomber") == 1 or isTagDefined("tanker") == 1)
                aType = aircraft_type_large_military_jet;
            else
                aType = aircraft_type_special_military;
        }
        else if(isTagDefined("piston") == 1 or isTagDefined("propeller") == 1)
        {
            if(isTagDefined("single-engine") == 1 or isTagDefined("1-engine") == 1)
                aType = aircraft_type_small_single_engine;
            else if(isTagDefined("twin-engine") == 1 or isTagDefined("2-engine") == 1 or
                    isTagDefined("4-engine") == 1 or isTagDefined("four-engine") == 1 )
                aType = aircraft_type_small_multi_engine;
            else if(isTagDefined("turboprop") == 1)
                aType = aircraft_type_executive_turboprop_jet;
            else
                aType = aircraft_type_small_single_engine;
        }
        else if(isTagDefined("jet") == 1)
        {
            if(isTagDefined("turboprop") == 1)
                aType = aircraft_type_executive_turboprop_jet;
            else if(isTagDefined("bizjet") == 1 or isTagDefined("business") == 1)
                aType = aircraft_type_business_jet;
            else if(isTagDefined("cargo") == 1 or isTagDefined("tanker") == 1)
                aType = aircraft_type_large_military_jet;
            else if(isTagDefined("transport") == 1 or isTagDefined("passenger") == 1)
                aType = aircraft_type_airline_jet;
            else
                aType = aircraft_type_business_jet;
        }
        else if(isTagDefined("supersonic") == 1 or isTagDefined("turbojet") == 1)
            aType = aircraft_type_large_military_jet;
        else if(isTagDefined("turboprop") == 1)
            aType = aircraft_type_executive_turboprop_jet;
        else if(isTagDefined("bizjet") == 1 or isTagDefined("business") == 1)
            aType = aircraft_type_business_jet;
        else
            aType = aircraft_type_unknown;
    }

    return aType;
}

var isTagDefined = func(tag)
{
    var tagdef = 0;
    var done = 0;
    var i = 0;
    var ndx = "";
    var property = "";

    while(tagdef == 0 and done == 0)
    {
        if(i > 0)
            ndx = sprintf("[%d]", i);
        else
            ndx = "";

        property = getprop(sprintf("/sim/tags/tag%s", ndx));

        if(property != nil)
        {
            if(property == tag)
                tagdef = 1;
        }
        else
            done = 1;

        i += 1;
    }

    return tagdef;
}
