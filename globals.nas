#
# Red Griffin ATC - Speaking Air Traffic Controller for FlightGear
#
# Written and developer by Antonello Biancalana (Red Griffin, IK0TOJ)
#
# Copyright (C) 2019-2021 Antonello Biancalana
#
# global.nas
#
# Global variables for Red Griffin ATC (rgatc.nas)
#
# Version 2.5.0 - 25 October 2026
#
# Red Griffin ATC is an Open Source project and it is licensed
# under the Gnu Public License v3 (GPLv3)
#

var RGAtcAddonID = "org.flightgear.addons.RGATC";
var RGAtcAddonProp = "/addons/by-id/" ~ RGAtcAddonID ~ "/";
var RGAtcVersion = "";
var RGAtcTitle = "Red Griffin ATC";
var RGAtcName = RGAtcTitle;
var RGAtcEnabled = 1;

var min_distance = 0.25;
var min_near_distance = 0.1;
var max_runway_alignment_degrees = 5;
var min_ground_altitude = 30;
var min_cruise_altitude = 3500;
var min_safe_altitude = 1500;
var flight_level_step = 2000;
var pattern_speed = 110;
var approach_speed = 100;
var final_speed = 80;
var flight_level_rate = 1000;
var min_airport_range = 3;
var atc_callback_seconds_counter = -1;
var atc_callback_wait_seconds = -1;
var timer_interval = 2;
var pilot_message_wait_seconds = -1;
var pilot_message_counter = 0;
var pilot_message_pause_atc_seconds = 2;
var pilot_response_wait_seconds = -1;
var pilot_response_counter = 0;
var pilot_response_pause_atc_seconds = 2;
var ctr_check_interval = 15;
var ctr_check_counter = 0;
var ctr_update_interval = 4;
var ctr_update_counter = 0;
var altitude_change_wait_seconds = 0;
var altitude_change_counter = 0;
var altitude_check_interval = 45;
var altitude_check_counter = 0;
var squawk_check_interval = 60;
var squawk_check_counter = 0;
var ctr_update_counter = 0;
var approach_check_interval = 60;
var approach_check_interval_initial = 45;
var approach_check_interval_near_point = 20;
var approach_check_interval_final = 10;
var approach_check_counter = 0;
var approach_slope_angle = 3;
var flight_plan_min_distance = 5;
var assigned_altitude_delta = 400;
var approach_speed_delta = 20;
var departure_extra_time = 0;
var flight_time_seconds = 0;
var take_off_max_seconds = 120;
var max_radios = 30;
var radioButton = [];
var radioButtonFrequency = [];
var KT2KMH = 1.852;
var NM2FT = 6076.12;

var altitudeFromTerrain = -1;
var min_altitude_from_terrain = 350;
var min_altitude_too_low_warning = 50;
var min_safety_distance_from_terrain_miles = 4;
var terrainWarning = 0;
var terrain_warning_interval = 10;
var terrain_warning_counter = 0;

var auto_reply_off = -1;
var min_altitude_change_secs = 30;
var max_altitude_change_secs = 60 - min_altitude_change_secs;
var min_cleared_takeoff_secs = 20;
var max_cleared_takeoff_secs = 45 - min_cleared_takeoff_secs;
var wait_after_take_off = 15;
var max_departure_secs = 120;
var extra_departure_secs = 120;
var max_take_off_secs = 60;
var land_check_secs = 15;
var welcome_airport_secs = 15;

var aircraft_type_unknown = "Unknown";
var aircraft_type_small_single_engine = "Small single engine";
var aircraft_type_small_multi_engine = "Small multi engine";
var aircraft_type_executive_turboprop_jet = "Executive turboprop/jet";
var aircraft_type_business_jet = "Business jet";
var aircraft_type_airline_jet = "Airline jet";
var aircraft_type_large_military_jet = "Large/military jet";
var aircraft_type_special_military = "Special military";

var com1quality = 0;
var com1volume = 0;
var com1serviceable = 0;
var com1PowerStatus = 0;
var com1Operable = 0;
var com2quality = 0;
var com2volume = 0;
var com2serviceable = 0;
var com2PowerStatus = 0;
var com2Operable = 0;
var com3quality = 0;
var com3volume = 0;
var com3serviceable = 0;
var com3PowerStatus = 0;
var com3Operable = 0;
var contactRadio = nil;
var squawkingMode = "On";
var squawkCode = "";
var squawkChange = 0;
var squawkIdent = 0;
var squawkIdentButtonPushed = 0;
var emergencySquawkCode = "";
var emergencySquawkAnnouncedCode = "";
var squawk_ident_off = 0;
var squawk_ident_only = 1;
var squawk_ident_code = 2;

var reservedSquawkCodes = [ 21, 22, 25, 33, 100, 500, 600, 700, 1000, 1100, 1200, 1201, 1202,
                            1203, 1255, 1273, 1274, 1275, 1276, 1277, 1300, 1400, 1500, 1600,
                            1700, 2000, 2100, 220, 2300, 2400, 2500, 2600, 2700, 3000, 3100,
                            3200, 3300, 3400, 3500, 3600, 3700, 4000, 4100, 4200, 4300, 4400,
                            4454, 4466, 4500, 4600, 4700, 5000, 5061, 5062, 5100, 5200, 5300,
                            5400, 5500, 5600, 5700, 6000, 6100, 6200, 6300, 6400, 6500, 6600,
                            6700, 7000, 7001, 7100, 7200, 7300, 7400, 7500, 7600, 7610, 7615,
                            7700, 7701, 7702, 7703, 7704, 7705, 7706, 7707, 7710, 7777 ];

var departureInformation = "";
var departureInformationAirport = "";

var initialized = 0;
var dialogInitialized = 0;
var callsign = "";
var atcCallsignText = "";
var atcCallsignVoice = "";
var callsignMode = "";
var includeManufacturer = "";
var aircraftManufacturer = "";
var atcMessageMode = "";
var synthVoice = [];
var usedSynthVoice = [];
var stationVoice = {};
var stationVoicePool = [];
var pilotRequestMode = "";
var pilotResponseMode = "";
var pilotVoice = {};
var availableRadio = {};
var currentRadioStationId = "";
var radioListHasChanged = 1;
var qnhUnitMeasure = "";
var qualityThreshold = 0.01;
var atcRadioMode = "Auto";
var aircraftType = aircraft_type_small_single_engine;
var tooLowWarningMode = "On";
var terrainWarningMode = "On";
var multiplayerChatEcho = "Off";
var slopeAngle = 3.0;

var airportRunwayInUse = "";
var airportRunwayInUseILS = nil;
var airportLandingRunway = "";
var landingRunway = "";

var approach_point_distance = -10;
var pattern_point_distance = -3;
var min_distance_for_altitude_change = 8;
var max_runway_align_angle = 30;
var miles_altitude_step = 10;
var feet_altitude_step = 1000;

var last_key = 0;
var reset_key_interval = 10;
var key_press_counter = 0;
var binding_key_dialog = 92;
var binding_key_name = "\\";
var binding_key_description = "backslash";
var binding_key_msg1 = 28;
var binding_key_msg2 = 29;
var binding_key_msg3 = 30;
var binding_key_msg4 = 31;
var binding_key_request_ctr = 48;
var binding_key_flight_level_1 = 36;
var binding_key_flight_level_2 = 37;
var binding_key_flight_level_3 = 38;
var binding_key_repeat_last_atc_message = 57;
var binding_key_abort_approach = 61;

var update_dialog = 0;
var update_popup = 1;
var update_data_only = 2;

var position_unknown = -1;
var position_ground = 1;
var position_runway = 2;
var position_flying = 3;

var status_going_around = 1;
var status_ready_for_departure = 2;
var status_cleared_for_takeoff = 3;
var status_took_off = 4;
var status_flying = 5;
var status_requested_approach = 6;
var status_requested_ils = 7;
var status_cleared_for_land_approach = 8;
var status_cleared_for_land_ils = 9;
var status_landed = 10;

var aircraft_status = status_going_around;

var radio_station_type_unknown = -1;
var radio_station_type_ground = 1;
var radio_station_type_tower = 2;
var radio_station_type_atis = 3;
var radio_station_type_departure = 4;
var radio_station_type_approach = 5;
var radio_station_type_clearance = 6;

var selectedComRadio = "";
var selectedComServiceable = 0;
var selectedComServiceableProperty = nil;
var selectedComPowerStatus = 0;
var selectedComOperable = 0;
var selectedComVolume = 0;
var selectedComStationType = radio_station_type_unknown;
var selectedComAirportId = "";
var selectedComStationName = "";
var selectedComFrequency = 0;
var selectedComStationDistance = 0;
var selectedComStationBearing = 0;
var selectedComSignalQuality = 0;
var selectedTransponder = 0;

var radio_type_exact_match = 1;
var radio_type_any = 2;

var currentCtr = nil;
var approvedCtr = nil;

var aircraftIsDeparting = 0;

var ctr_request_approved = 1;
var ctr_already_approved = 2;
var ctr_request_denied = 3;

var ctr_status_inside = 1;
var ctr_status_in_range = 2;
var ctr_status_outside = 3;

var ctr_range_short = 20;
var ctr_range_medium = 30;
var ctr_range_wide = 50;

var ctr_search_range = ctr_range_wide + 20;
var ctr_leaving_range = 1;
var ctr_leaving_warning = 0;

var ctr_maximum_range_distance = 10;
var ctr_maximum_range_angle = 90;

var meteo_type_full = 1;
var meteo_type_wind = 2;
var meteo_type_qnh = 3;

var runway_take_off = 1;
var runway_landing = 2;

var approach_status_none = 1;
var approach_status_to_pattern = 2;
var approach_status_to_approach = 3;
var approach_status_to_final = 4;
var approach_status_landing = 5;

var approachStatus = approach_status_none;
var approach_turn_distance = 0.5;
var approachRouteTextInstructions = "";
var approachRouteVoiceInstructions = "";
var approachAltitude = 0;

var spell_text = 1;
var spell_number = 2;
var spell_number_to_literal = 3;
var spell_runway = 4;

var altitude_zone_odd = 1;
var altitude_zone_even = 2;

var ctr_request_button = -1;

var message_none = -1;
var message_radio_check = 1;
var message_engine_start = 2;
var message_departure_information = 3;
var message_request_taxi = 4;
var message_ready_for_departure = 5;
var message_abort_departure = 6;
var message_request_approach = 7;
var message_request_ils = 8;
var message_request_ctr = 9;
var message_request_fl = 10;
var message_airfield_in_sight = 11;
var message_ils_established = 12;
var message_flying_too_low = 13;
var message_terrain_ahead = 14;
var message_leaving_ctr = 15;
var message_change_altitude = 16;
var message_check_altitude = 17;
var message_abort_approach = 18;
var message_roger = 19;
var message_wilco = 20;
var message_ctr_approved = 21;
var message_not_in_this_ctr = 22;
var message_cleared_take_off = 23;
var message_approved_approach = 24;
var message_approved_ils = 25;
var message_approach_route_instructions = 26;
var message_cleared_landing = 27;
var message_fl_approved = 28;
var message_wait_for_departure = 29;
var message_leaving_airport = 30;
var message_going_around = 31;
var message_contact_radio = 32;
var message_check_transponder = 33;
var message_say_again = 34;
var message_emergency_squawk = 35;

var message_type_local = 1;
var message_type_important = 2;

var multiplayMessageType = message_type_local;

var openDialogStartup = "Off";
var dialogPosition = "";
var atcTextPosition = "";
var atcTextTransparency = "Medium";
var menu_bar_height = 30;

var dialogWidth = 480;
var dialogHeight = 160;
var maxDialogWidth = 462;
var maxDialogHeight = 314;
var dialogPosX = 0;
var dialogPosY = 0;
var popup_window_bg_color = [0.0, 0.0, 0.0, 0.40];
var popup_window_fg_atc_color = [1.0, 1.0, 0.5, 1];
var popup_window_fg_pilot_color = [0.7, 1.0, 0.5, 1];
var atc_popup_y_position = nil;
var atc_popup_x_position = nil;
var atc_popup_align = "center";
var dlgWindow = nil;
var dlgCanvas = nil;
var dlgRoot = nil;
var dlgLayout = nil;
var atcLogWindow = nil;
var atcLogScroll = nil;
var txtAtcLog = nil;
var radioBox = nil;
var radioList = nil;
var radioScroll = nil;
var radioScrollContent = nil;
var txtAirport = nil;
var txtAircraftPosition = nil;
var txtCurrentCtr = nil;
var txtCurrentCtrSpecs = nil;
var txtCurrentRadio = nil;
var txtCurrentRadioSpecs = nil;
var btnMessage = [nil, nil, nil, nil];
var btnRepeatATCMessage = nil;
var btnRequestCtr = nil;
var btnRequestFlightLevel1 = nil;
var btnRequestFlightLevel2 = nil;
var btnRequestFlightLevel3 = nil;
var btnAvailableRadio = nil;
var btnAbortApproach = nil;
var repeatBtnWidth = 22;
var dialogOpened = 0;
var atcLogOpened = 0;
var currentAirport = nil;
var currentRunway = "";
var alignedOnRunway = 0;
var nearRunway = 0;
var assignedAltitude = -1;
var requestedAltitude = -1;
var currentAltitudeZone = -1;
var flightLevel1 = 0;
var flightLevel2 = 0;
var flightLevel3 = 0;
var patternPoint = nil;
var approachPoint = nil;
var pilotMessageType = message_none;
var pilotResponseType = message_none;
var atcMessageType = [message_none, message_none, message_none, message_none];

var lastAtcText = "";
var lastAtcVoice = "";
var atcLogText = "";

var pilotMessageRequest = {
                           radio_check:"%s, %s, radio check %s",
                           engine_start:"%s, %s, Request start up",
                           departure_information:"%s, %s, Request departure information",
                           request_taxi:"%s, %s, Request taxi instructions%s",
                           ready_departure:"%s, %s, Ready for departure, runway %s",
                           abort_departure:"%s, %s, Abort departure, runway %s",
                           request_approach:"%s, %s, Request approach information",
                           abort_approach:"%s, %s, Abort approach request runway %s",
                           request_ils:"%s, %s, Request %s information",
                           abort_ils:"%s, %s, Abort %s request runway %s",
                           airfield_in_sight:"%s, %s, Airfield in sight",
                           ils_established:"%s, %s, %s established runway %s",
                           abort_landing:"%s, %s, Abort landing runway %s",
                           request_ctr:"%s, %s, Request clearance to transition through the %s airspace",
                           request_fl:"%s, %s, Request %s%s",
                           say_again:"%s, %s, Say again"
                         };

var pilotMessageResponse = {
                            roger:"%s, %s, Roger",
                            wilco:"%s, %s, Wilco",
                            engine_start:"%s, %s, Start up approved, departure runway %s.",
                            approved_ctr:"%s, %s, %s transition approved%s",
                            taxi:"%s, %s.\nTaxi to hold short of runway %s%s",
                            wait_departure:"%s, %s, %sReady for departure, runway %s",
                            cleared_take_off:"%s, %s, Cleared for take off, runway %s.",
                            leaving_airport:"%s, %s, Fly at runway heading, climb to %s feet.\n%s",
                            approved_approach:"%s, %s. Cleared to approach runway %s",
                            approved_ils:"%s, %s. Cleared %s approach to runway %s",
                            approach_route_instructions:"%s, %s, %s",
                            cleared_landing:"%s, %s. Cleared to land runway %s",
                            approved_fl:"%s, %s, Approved %s%s",
                            change_altitude:"%s, %s, %s and maintain %s feet",
                            going_around:"%s, %s, Going around",
                            contact_radio:"%s, %s. Contact %s at %s.",
                            check_transponder:"%s, %s. Squawk %sIDENT",
                            departure_information:"%s, %s. I have information %s."
                           };

var atcMessageRequest = {
                         radio_check:"Radio Check",
                         engine_start:"Request Engine Start",
                         departure_information:"Departure Information",
                         request_taxi:"Request Taxi",
                         ready_departure:"Ready for Departure",
                         abort_departure:"Abort Departure",
                         request_approach:"Request Approach",
                         request_ils:"Request ILS",
                         airfield_in_sight:"Airfield in Sight",
                         ils_established:"ILS Established"
                        };

var atcMessageReply = {
                       radio_check:"%s, %s, Reading you %s.%s",
                       engine_start:"%s, %s, Start up approved.\nDeparture runway %s, %s %s.\nReport when ready to taxi.",
                       departure_information:"%s, %s.\nDeparture runway %s, %s.\nCorrect time %s. End of information %s.",
                       request_taxi:"%s, %s.\nTaxi to hold short of runway %s.\n%s%s",
                       ready_departure:"%s, %s.\n%sGet ready for departure, runway %s.",
                       report_ready_departure:"Report when ready for departure",
                       cleared_for_takeoff:"%s, %s, Runway %s, %s, cleared for take off.",
                       leaving_airport:"%s, %s, %s. Fly at runway heading,\nclimb to %s feet and follow your flight plan.\n%s",
                       abort_departure:"%s, %s.\nAborted departure, runway %s.\nVacate runway and go around.",
                       request_pattern_approach:"%s, %s. Cleared to approach.\n%sHeading %s for %s miles to join %s pattern,\nthen turn %s and then turn %s to final %srunway %s with %s feet.\n%s.",
                       request_approach:"%s, %s. Cleared to approach.\n%sHeading %s for %s miles then turn to %s final %srunway %s with %s feet.\n%s.",
                       request_pattern_ils:"%s, %s.\n%sHeading %s for %s miles to join %s pattern,\nthen turn %s to intercept the %slocalizer.\nCleared %s runway %s, maintain %s feet until established.\n%s.",
                       request_ils:"%s, %s.\n%sHeading %s for %s miles to intercept the %slocalizer.\nCleared %s runway %s, maintain %s feet until established.\n%s.",
                       approach_route_instructions:"%s, %s, %s",
                       abort_approach:"%s, %s, Approach to runway %s aborted. Go around",
                       airfield_in_sight:"%s, %s. %s. Cleared to land runway %s.",
                       report_airfield_in_sight:"%seport on airfield in sight.",
                       report_established_ils:"%seport on established %s runway %s",
                       wrong_approach_runway:"%s, %s, You are approaching the wrong runway.\nLanding runway is %s. Leave this route immediately,\nrequest approach and follow instructions.",
                       welcome_to_airport:"%s, %s, welcome to %s.\nExit runway at first taxiway and taxi to platform.",
                       abort_landing:"%s, %s, Landing runway %s aborted.\nLeave route and go around",
                       ctr_approved:"%s, %s, Transition through %s airspace approved%s",
                       ctr_already_approved:"%s, %s, You are already approved in this %s airspace%s",
                       ctr_not_approved:"%s, %s, You are not approved in this %s.\nContact me when you are near this %s or request transition permission.",
                       not_in_this_ctr:"%s, %s, You are not approved in this %s.\nLeave this %s immediately.",
                       leaving_ctr:"%s, %s, You are about to leave this %s.%s",
                       change_altitude:"%s, %s, %s and maintain %s feet",
                       check_altitude:"%s, %s, %s to your assigned altitude %s feet",
                       fl_approved:"%s, %s, Approved %s%s.",
                       flying_too_low:"%s,\nYou are flying too low. Pull up! Pull up!",
                       terrain_ahead:"%s,\nYou are flying towards terrain.\nPull up and climb immediately\nor turn to a safe heading immediately",
                       wrong_runway:"%s, %s,\nYou are on the wrong runway.\nTaxi to hold short of runway %s via taxiway and report when ready for departure.",
                       not_in_this_airfield:"%s, This is %s.%s\nYou are not in this airfield.",
                       not_allowed_to_land:"%s, %s. You are not allowed to land. Request approach or landing.",
                       vacate_runway:"%s, %s, Take off immediately or vacate the runway.",
                       turn_to_heading:"Turn %s heading to %s",
                       turn_to_final:"Turn %s heading %s to final runway %s",
                       radio_available_at:"%s available at %s.",
                       contact_radio:"Contact %s at %s",
                       wrong_radio:"%s, This is %s.\nContact %s at %s.",
                        check_transponder:"%s, %s. Squawk %sIDENT",
                        emergency_7500:"%s, %s. Squawk %s observed. If able, acknowledge with IDENT and request assistance in the ATC dialog.",
                        emergency_7600:"%s, %s. Squawk %s observed; radio failure noted. Continue using the simulator's lost-communications procedure.",
                         emergency_7700:"%s, %s. Squawk %s observed. State the nature of your emergency and intentions if able.",
                         engine_start_while_airborne:"%s, %s. Start-up approval is only available on the ground at the departure airport.",
                         taxi_while_airborne:"%s, %s. You are airborne; taxi clearance is not available. Land and contact ground when on the airport surface.",
                         hold_short_for_departure:"%s, %s. Hold short of runway %s and report ready to line up.",
                         align_for_departure:"%s, %s. Align with runway %s before requesting takeoff clearance."
                      };

var atcMessageReplyVariants = {
                            radio_check:[
                                "%s, %s, readable at signal %s.%s",
                                "%s, %s. Your signal is %s.%s",
                                "%s, %s, your transmission is coming through at %s.%s"
                            ],
                            engine_start:[
                                "%s, %s. Start-up approved for runway %s. %s %s. Call ground when ready to taxi.",
                                "%s, %s, you may start. Runway %s is in use; set %s to %s and request taxi when ready."
                            ],
                            departure_information:[
                                "%s, %s. Departure runway %s; %s. Time %s, information %s.",
                                "%s, %s. Runway %s is in use. %s. The time is %s; information %s."
                            ],
                            request_taxi:[
                                "%s, %s. Taxi to hold short of runway %s. %s%s",
                                "%s, %s, runway %s is in use. Taxi and hold short; %s%s",
                                "%s, %s. Taxi to the holding point for runway %s. %s%s"
                            ],
                            ready_departure:[
                                "%s, %s.\n%sRunway %s, stand by for departure.",
                                "%s, %s. %sExpect departure clearance for runway %s.",
                                "%s, %s. %sRunway %s, prepare for departure."
                            ],
                            cleared_for_takeoff:[
                                "%s, %s. Runway %s, %s, cleared for takeoff.",
                                "%s, %s, takeoff clearance: runway %s, %s."
                            ],
                            leaving_airport:[
                                "%s, %s. Current conditions: %s. Climb to %s feet and continue on your flight plan.\n%s",
                                "%s, %s. For departure, %s. Climb and maintain %s feet; then follow your flight plan.\n%s"
                            ],
                            approach_route_instructions:[
                                "%s, %s. Approach instructions: %s",
                                "%s, %s, follow this approach route: %s"
                            ],
                            wrong_runway:[
                                "%s, %s. Runway %s is active. Taxi to it and hold short; report when ready.",
                                "%s, %s. That is not the active departure runway. Use runway %s and report ready."
                            ],
                            wrong_approach_runway:[
                                "%s, %s, you are lined up with the wrong runway. Landing runway is %s. Go around and request new instructions.",
                                "%s, %s. Landing runway is %s; discontinue this approach and request a new clearance."
                            ],
                            welcome_to_airport:[
                                "%s, %s, welcome to %s. Vacate at the first taxiway and taxi to parking.",
                                "%s, %s, welcome to %s. Exit the runway when able, then taxi to the apron."
                            ],
                            emergency_7500:[
                                "%s, %s. Squawk %s received. If able, IDENT and use the ATC dialog to request assistance.",
                                "%s, %s. Squawk %s observed. If safe, confirm your intentions and request help in the ATC dialog."
                            ],
                            emergency_7600:[
                                "%s, %s. Squawk %s received; radio failure acknowledged. Continue with FlightGear's lost-communications procedure.",
                                "%s, %s. We have your %s squawk and have noted the radio failure. Follow the simulator's lost-communications procedure."
                            ],
                            emergency_7700:[
                                "%s, %s. Squawk %s received. If able, state the nature of the emergency and your intentions.",
                                "%s, %s. General emergency squawk %s observed. Tell us what assistance you need when able."
                            ]
                          };

var atcMessageAction = {
                        atc_message:"%s, This is %s.%s",
                        startup:"startup",
                        taxi_request:"taxi request",
                        departure_request:"departure request",
                        lineup_and_wait:"Line up and wait. ",
                        contact_when_ready:"Contact %s at %s when ready.",
                        unable_approve:"Unable to approve",
                        negative:"Negative",
                        tower_not_reachable:"tower radio is not reachable",
                        no_radio_available:"no radio available in this area",
                        left_tag:"left",
                        right_tag:"right",
                        climb:"Climb",
                        descend:"Descend",
                        reduce:"Reduce",
                        increase:"Increase",
                        altitude_change:"%s to %s feet with ",
                        turn_radio_on:"Turn radio on",
                        radio_volume_up:"Turn radio volume up",
                        no_radio_tuned:"Tuned radio is not readable or is out of range",
                        bad_radio_data:"** WARNING: This aircraft's radio is unusable **",
                        bad_airport_radio:"** WARNING: This airport radio is unusable **",
                        unknown_radio_type:"** WARNING: Cannot detect radio type **",
                        inconsistent_radio_data:"ERROR: Aircraft radio use inconsistent frequency settings",
                        contact_ctr:"\nFly current heading and request transition\nto %s %s at %s",
                        check_transponder:"Squawk %s and IDENT"
                       };

var meteoMessage = {
                        wind_report:"Wind %s degrees, %s knots",
                        wind_calm:"Wind calm",
                        full:"%s %s,\nTemperature %s, Dew point %s, Visibility %s kilometers",
                        cloud_report:"Clouds %s at %s feet",
                        rain_report:"%s rain",
                        snow_report:"%s snow",
                        sky_clear:"Sky clear",
                        light:"Light",
                        moderate:"Moderate",
                        heavy:"Heavy",
                        cover:"cover",
                        qnh_report:"%s %s"
                   };

var phoneticLetter = {
                      A:"Alpha",
                      B:"Bravo",
                      C:"Charlie",
                      D:"Delta",
                      E:"Echo",
                      F:"Fox trot",
                      G:"Golf",
                      H:"Hotel",
                      I:"India",
                      J:"Juliet",
                      K:"Kilo",
                      L:"Leema",
                      M:"Mike",
                      N:"November",
                      O:"Oscar",
                      P:"Papa",
                      Q:"Quebec",
                      R:"Romeo",
                      S:"Sierra",
                      T:"Tango",
                      U:"Uniform",
                      V:"Victor",
                      W:"Whiskey",
                      X:"X ray",
                      Y:"Yankee",
                      Z:"Zulu"
                     };

var phoneticDigit = {
                     0:"Zero",
                     1:"One",
                     2:"Two",
                     3:"Three",
                     4:"Fower",
                     5:"Five",
                     6:"Six",
                     7:"Seven",
                     8:"Eight",
                     9:"Niner"
                    };

var phoneticNumber = {
                        0:"Zero",
                        1:"One",
                        2:"Two",
                        3:"Three",
                        4:"Fower",
                        5:"Five",
                        6:"Six",
                        7:"Seven",
                        8:"Eight",
                        9:"Niner",
                       10:"Ten",
                       11:"Eleven",
                       12:"Twelve",
                       13:"Thirteen",
                       14:"Fourteen",
                       15:"Fifteen",
                       16:"Sixteen",
                       17:"Seventeen",
                       18:"Eighteen",
                       19:"Nineteen"
                     };

var phoneticTen = {
                    0:"",
                    1:"Ten",
                    2:"Twenty",
                    3:"Thirty",
                    4:"Forty",
                    5:"Fifty",
                    6:"Sixty",
                    7:"Seventy",
                    8:"Eighty",
                    9:"Ninety"
                  };

# FlightGear Properties

var property_MultiplayCallsign = props.globals.getNode("/sim/multiplay/callsign");
var property_UserCallsign = props.globals.getNode("/sim/user/callsign");

var property_Setting_OpenDialogStartup = props.globals.getNode("/rgatc/open-dialog-startup", 1);
var property_Setting_DialogPosition = props.globals.getNode("/rgatc/dialog-position", 1);
var property_Setting_AtcTextPosition = props.globals.getNode("/rgatc/atc-text-position", 1);
var property_Setting_AtcTextTransparency = props.globals.getNode("/rgatc/atc-text-transparency", 1);
var property_Setting_Callsign = props.globals.getNode("/rgatc/callsign", 1);
var property_Setting_CallsignMode = props.globals.getNode("/rgatc/callsign-mode", 1);
var property_Setting_IncludeManufacturer = props.globals.getNode("/rgatc/include-manufacturer", 1);
var property_Setting_PilotRequestMode = props.globals.getNode("/rgatc/pilot-request-mode", 1);
var property_Setting_PilotResponseMode = props.globals.getNode("/rgatc/pilot-response-mode", 1);
var property_Setting_AtcMessageMode = props.globals.getNode("/rgatc/atc-message-mode", 1);
var property_Setting_QnhUnitMeasure = props.globals.getNode("/rgatc/qnh", 1);
var property_Setting_AtcRadioMode = props.globals.getNode("/rgatc/atc-radio", 1);
var property_Setting_AircraftType = props.globals.getNode("/rgatc/aircraft-type", 1);
var property_Setting_SquawkingMode = props.globals.getNode("/rgatc/squawking", 1);
var property_Setting_SlopeAngle = props.globals.getNode("/rgatc/slope-angle", 1);
var property_Setting_TooLowWarningMode = props.globals.getNode("/rgatc/too-low-warning", 1);
var property_Setting_TerrainWarningMode = props.globals.getNode("/rgatc/terrain-warning", 1);
var property_Setting_MultiplayerChatEcho = props.globals.getNode("/rgatc/multiplayer-chat-echo", 1);

var property_Aircraft_AltitudeFeet = props.globals.getNode("/position/altitude-ft");
var property_Aircraft_AltitudeAglFeet = props.globals.getNode("/position/altitude-agl-ft");
var property_Aircraft_HeadingDeg = props.globals.getNode("/orientation/heading-deg");
var property_Aircraft_HeadingMagneticDeg = props.globals.getNode("/orientation/heading-magnetic-deg");
var property_Aircraft_AirSpeedKnots = props.globals.getNode("/velocities/airspeed-kt");
var property_Aircraft_GroundSpeedKnots = props.globals.getNode("/velocities/groundspeed-kt");
var property_Aircraft_MachSpeed = props.globals.getNode("/velocities/mach");

var property_COM1_Serviceable = props.globals.getNode("/instrumentation/comm/serviceable");
var property_COM1_Quality = props.globals.getNode("/instrumentation/comm/signal-quality-norm");
var property_COM1_Volume = props.globals.getNode("/instrumentation/comm/volume");
var property_COM1_VolumeSelected = props.globals.getNode("/instrumentation/comm/volume-selected");
var property_COM1_PowerButton = props.globals.getNode("/instrumentation/comm/power-btn");
var property_COM1_Operable = props.globals.getNode("/instrumentation/comm/operable");
var property_COM1_AirportID = props.globals.getNode("/instrumentation/comm/airport-id");
var property_COM1_StationName = props.globals.getNode("/instrumentation/comm/station-name");
var property_COM1_Frequency = props.globals.getNode("/instrumentation/comm/frequencies/selected-mhz");
var property_COM1_RealFrequency = props.globals.getNode("/instrumentation/comm/frequencies/selected-real-frequency-mhz");
var property_COM1_Distance = props.globals.getNode("/instrumentation/comm/track-distance-m");
var property_COM1_Bearing = props.globals.getNode("/instrumentation/comm/true-bearing-to-deg");

var property_COM2_Serviceable = props.globals.getNode("/instrumentation/comm[1]/serviceable");
var property_COM2_Quality = props.globals.getNode("/instrumentation/comm[1]/signal-quality-norm");
var property_COM2_Volume = props.globals.getNode("/instrumentation/comm[1]/volume");
var property_COM2_VolumeSelected = props.globals.getNode("/instrumentation/comm[1]/volume-selected");
var property_COM2_PowerButton = props.globals.getNode("/instrumentation/comm[1]/power-btn");
var property_COM2_Operable = props.globals.getNode("/instrumentation/comm[1]/operable");
var property_COM2_AirportID = props.globals.getNode("/instrumentation/comm[1]/airport-id");
var property_COM2_StationName = props.globals.getNode("/instrumentation/comm[1]/station-name");
var property_COM2_Frequency = props.globals.getNode("/instrumentation/comm[1]/frequencies/selected-mhz");
var property_COM2_RealFrequency = props.globals.getNode("/instrumentation/comm[1]/frequencies/selected-real-frequency-mhz");
var property_COM2_Distance = props.globals.getNode("/instrumentation/comm[1]/track-distance-m");
var property_COM2_Bearing = props.globals.getNode("/instrumentation/comm[1]/true-bearing-to-deg");

var property_COM3_Serviceable = props.globals.getNode("/instrumentation/comm[2]/serviceable");
var property_COM3_Quality = props.globals.getNode("/instrumentation/comm[2]/signal-quality-norm");
var property_COM3_Volume = props.globals.getNode("/instrumentation/comm[2]/volume");
var property_COM3_VolumeSelected = props.globals.getNode("/instrumentation/comm[2]/volume-selected");
var property_COM3_PowerButton = props.globals.getNode("/instrumentation/comm[2]/power-btn");
var property_COM3_Operable = props.globals.getNode("/instrumentation/comm[2]/operable");
var property_COM3_AirportID = props.globals.getNode("/instrumentation/comm[2]/airport-id");
var property_COM3_StationName = props.globals.getNode("/instrumentation/comm[2]/station-name");
var property_COM3_Frequency = props.globals.getNode("/instrumentation/comm[2]/frequencies/selected-mhz");
var property_COM3_RealFrequency = props.globals.getNode("/instrumentation/comm[2]/frequencies/selected-real-frequency-mhz");
var property_COM3_Distance = props.globals.getNode("/instrumentation/comm[2]/track-distance-m");
var property_COM3_Bearing = props.globals.getNode("/instrumentation/comm[2]/true-bearing-to-deg");

var property_Transponder1_Serviceable = props.globals.getNode("/instrumentation/transponder/serviceable");
var property_Transponder1_Operable = props.globals.getNode("/instrumentation/transponder/operable");
var property_Transponder1_KnobMode = props.globals.getNode("/instrumentation/transponder/inputs/knob-mode");
var property_Transponder1_IdCode = props.globals.getNode("/instrumentation/transponder/id-code");
var property_Transponder1_Ident = props.globals.getNode("/instrumentation/transponder/ident");

var property_Transponder2_Serviceable = props.globals.getNode("/instrumentation/transponder[1]/serviceable");
var property_Transponder2_Operable = props.globals.getNode("/instrumentation/transponder[1]/operable");
var property_Transponder2_KnobMode = props.globals.getNode("/instrumentation/transponder[1]/inputs/knob-mode");
var property_Transponder2_IdCode = props.globals.getNode("/instrumentation/transponder[1]/id-code");
var property_Transponder2_Ident = props.globals.getNode("/instrumentation/transponder[1]/ident");

var property_Transponder3_Serviceable = props.globals.getNode("/instrumentation/transponder[2]/serviceable");
var property_Transponder3_Operable = props.globals.getNode("/instrumentation/transponder[2]/operable");
var property_Transponder3_KnobMode = props.globals.getNode("/instrumentation/transponder[2]/inputs/knob-mode");
var property_Transponder3_IdCode = props.globals.getNode("/instrumentation/transponder[2]/id-code");
var property_Transponder3_Ident = props.globals.getNode("/instrumentation/transponder[2]/ident");

var property_RealWeather = props.globals.getNode("/environment/realwx/enabled");

var property_Weather_WindDirectionDeg = props.globals.getNode("/environment/wind-from-heading-deg");
var property_Weather_WindSpeedKnots = props.globals.getNode("/environment/wind-speed-kt");
var property_Weather_Temperature = props.globals.getNode("/environment/temperature-degc");
var property_Weather_Dewpoint = props.globals.getNode("/environment/dewpoint-degc");
var property_Weather_Visibility = props.globals.getNode("/environment/visibility-m");
var property_Weather_Rain = props.globals.getNode("/environment/rain-norm");
var property_Weather_Snow = props.globals.getNode("/environment/snow-norm");
var property_Weather_CloudsCoverage = props.globals.getNode("/environment/clouds/layer/coverage");
var property_Weather_CloudsElevationFeet = props.globals.getNode("/environment/clouds/layer/elevation-ft");
var property_Weather_QnhInHg = props.globals.getNode("/environment/pressure-sea-level-inhg");

var property_Weather_Metar_WindDirectionDeg = props.globals.getNode("/environment/metar/base-wind-dir-deg");
var property_Weather_Metar_WindSpeedKnots = props.globals.getNode("/environment/metar/base-wind-speed-kt");
var property_Weather_Metar_Temperature = props.globals.getNode("/environment/metar/temperature-degc");
var property_Weather_Metar_Dewpoint = props.globals.getNode("/environment/metar/dewpoint-degc");
var property_Weather_Metar_Visibility = props.globals.getNode("/environment/metar/max-visibility-m");
var property_Weather_Metar_Rain = props.globals.getNode("/environment/metar/rain-norm");
var property_Weather_Metar_Snow = props.globals.getNode("/environment/metar/snow-norm");
var property_Weather_Metar_SnowCover = props.globals.getNode("/environment/metar/snow-cover");
var property_Weather_Metar_CloudsCoverage = props.globals.getNode("/environment/metar/clouds/layer/coverage");
var property_Weather_Metar_CloudsElevationFeet = props.globals.getNode("/environment/metar/clouds/layer/elevation-ft");
var property_Weather_Metar_QnhInHg = props.globals.getNode("/environment/metar/pressure-sea-level-inhg");

var property_AtcRunway = props.globals.getNode("/sim/atc/runway");

var property_Autopilot_RouteManagerActive = props.globals.getNode("/autopilot/route-manager/active");
var property_Autopilot_RouteManagerDepartureRunway = props.globals.getNode("/autopilot/route-manager/departure/runway");
var property_Autopilot_RouteManagerRouteNum = props.globals.getNode("/autopilot/route-manager/route/num");
var property_Autopilot_RouteManagerCurrentWayPoint = props.globals.getNode("/autopilot/route-manager/current-wp");
var property_Autopilot_RouteManagerCruiseAltitudeFeet = props.globals.getNode("/autopilot/route-manager/cruise/altitude-ft");

var property_ClosestAirportId = props.globals.getNode("/sim/airport/closest-airport-id");
var property_TimeGmtString = props.globals.getNode("/sim/time/gmt-string");

var property_Multiplay_Chat = props.globals.getNode("/sim/multiplay/chat");

var property_Canvas_Width = props.globals.getNode("/sim/gui/canvas/size");
var property_Canvas_Height = props.globals.getNode("/sim/gui/canvas/size[1]");

var property_Simulator_Freeze = props.globals.getNode("/sim/freeze/master");
var property_Simulator_Replay = props.globals.getNode("/sim/replay/replay-state");
