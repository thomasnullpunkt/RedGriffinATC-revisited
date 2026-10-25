#
# Red Griffin ATC - Simulated F-15 escort for squawk 7500
#
# Version 2.5.0 - 25 October 2026
#
# The F-15 aircraft model is an optional external FlightGear aircraft install.
# This add-on only creates visual model instances; it does not control an FDM
# aircraft or use weapons.
#

var f15EscortModelPath = "";
var f15EscortState = "idle";
var f15EscortElapsed = 0;
var f15EscortLeftModel = nil;
var f15EscortRightModel = nil;
var f15EscortUpdateSeconds = 0.5;
var f15EscortStartDistance = 6 * NM2M;
var f15EscortEndDistance = 0.8 * NM2M;
var f15EscortLateralSpacing = 420;
var f15EscortAltitudeOffset = 150;
var f15EscortApproachSeconds = 45;
var f15EscortDepartureSeconds = 30;
var f15EscortTimer = nil;

var configureF15Escort = func(addonBasePath)
{
    f15EscortModelPath = addonBasePath ~ "/AI/f15-escort.xml";
}

var f15EscortCoordinates = func(distanceBehind)
{
    var aircraftPosition = geo.aircraft_position();
    var heading = property_Aircraft_HeadingDeg.getValue();

    if(aircraftPosition == nil or heading == nil)
        return nil;

    var behindCourse = math.mod(heading + 180, 360);
    var leftCourse = heading - 90;
    var rightCourse = heading + 90;

    if(leftCourse < 0)
        leftCourse += 360;

    if(rightCourse >= 360)
        rightCourse -= 360;

    var centerPosition = geo.Coord.new().set_latlon(
        aircraftPosition.lat(),
        aircraftPosition.lon()
    );

    centerPosition.apply_course_distance(behindCourse, distanceBehind);

    var leftPosition = geo.Coord.new().set_latlon(
        centerPosition.lat(),
        centerPosition.lon()
    );

    var rightPosition = geo.Coord.new().set_latlon(
        centerPosition.lat(),
        centerPosition.lon()
    );

    leftPosition.apply_course_distance(leftCourse, f15EscortLateralSpacing);
    rightPosition.apply_course_distance(rightCourse, f15EscortLateralSpacing);

    return [leftPosition, rightPosition];
}

var setF15EscortModelPosition = func(model, position, altitudeFeet, heading)
{
    if(model == nil or position == nil)
        return;

    model.getNode("latitude").setValue(position.lat());
    model.getNode("longitude").setValue(position.lon());
    model.getNode("elevation").setValue(altitudeFeet);
    model.getNode("heading-deg").setValue(heading);
    model.getNode("pitch-deg").setValue(0);
    model.getNode("roll-deg").setValue(0);
}

var createF15EscortModel = func(callsign, position, altitudeFeet, heading)
{
    if(f15EscortModelPath == "" or position == nil)
        return nil;

    var modelList = props.globals.getNode("models", 1);
    var index = 0;

    while(modelList.getChild("model", index, 0) != nil)
        index += 1;

    var model = modelList.getChild("model", index, 1);

    if(model == nil)
        return nil;

    model.getNode("elevation", 1).setValue(altitudeFeet);
    model.getNode("latitude", 1).setValue(position.lat());
    model.getNode("longitude", 1).setValue(position.lon());
    model.getNode("elevation-ft-prop", 1).setValue(model.getPath() ~ "/elevation");
    model.getNode("latitude-deg-prop", 1).setValue(model.getPath() ~ "/latitude");
    model.getNode("longitude-deg-prop", 1).setValue(model.getPath() ~ "/longitude");
    model.getNode("heading-deg", 1).setValue(heading);
    model.getNode("pitch-deg", 1).setValue(0);
    model.getNode("roll-deg", 1).setValue(0);
    model.getNode("path", 1).setValue(f15EscortModelPath);
    model.getNode("callsign", 1).setValue(callsign);

    var loadNode = model.getNode("load", 1);
    loadNode.setBoolValue(1);
    loadNode.remove();

    return model;
}

var updateF15EscortModels = func(distanceBehind)
{
    var positions = f15EscortCoordinates(distanceBehind);
    var altitudeFeet = property_Aircraft_AltitudeFeet.getValue();
    var heading = property_Aircraft_HeadingDeg.getValue();

    if(positions == nil or altitudeFeet == nil or heading == nil)
        return 0;

    altitudeFeet += f15EscortAltitudeOffset;

    setF15EscortModelPosition(f15EscortLeftModel, positions[0], altitudeFeet, heading);
    setF15EscortModelPosition(f15EscortRightModel, positions[1], altitudeFeet, heading);

    return 1;
}

var removeF15EscortModels = func()
{
    if(f15EscortLeftModel != nil)
        f15EscortLeftModel.remove();

    if(f15EscortRightModel != nil)
        f15EscortRightModel.remove();

    f15EscortLeftModel = nil;
    f15EscortRightModel = nil;
}

var startF15Escort = func()
{
    if(f15EscortState == "approaching" or
       f15EscortState == "escorting" or
       f15EscortState == "waiting")
        return;

    if(f15EscortState == "unavailable")
        return;

    if(f15EscortState == "departing")
    {
        f15EscortState = "approaching";
        f15EscortElapsed = 0;
        f15EscortTimer.start();
        return;
    }

    f15EscortState = "waiting";
    f15EscortElapsed = 0;
    f15EscortTimer.start();
}

var endF15Escort = func()
{
    if(f15EscortState == "idle")
        return;

    if(f15EscortState == "unavailable")
    {
        f15EscortState = "idle";
        return;
    }

    if(f15EscortState == "waiting")
    {
        f15EscortState = "idle";
        f15EscortTimer.stop();
        return;
    }

    if(f15EscortState != "departing")
    {
        f15EscortState = "departing";
        f15EscortElapsed = 0;
        f15EscortTimer.start();
    }
}

f15EscortTimer = maketimer(f15EscortUpdateSeconds, func()
{
    if(f15EscortState == "idle" or f15EscortState == "unavailable")
        return;

    if(isSimulationPaused() == 1)
        return;

    if(f15EscortState == "waiting")
    {
        if(squawkingMode != "On" or emergencySquawkCode != "7500" or isAtcEnabled() == 0)
        {
            f15EscortState = "idle";
            f15EscortTimer.stop();
            return;
        }

        var aircraftModel = resolvepath("Aircraft/F-15/Models/f15c.ac");
        var escortModel = resolvepath(f15EscortModelPath);

        if(aircraftModel == nil or io.stat(aircraftModel) == nil or
           escortModel == nil or io.stat(escortModel) == nil)
        {
            f15EscortState = "unavailable";
            f15EscortTimer.stop();
            showPopup(RGAtcName ~ ": Install the FlightGear F-15 aircraft to enable the simulated 7500 escort.");
            return;
        }

        var altitudeAgl = property_Aircraft_AltitudeAglFeet.getValue();

        if(altitudeAgl == nil or altitudeAgl < 80)
            return;

        var positions = f15EscortCoordinates(f15EscortStartDistance);
        var altitudeFeet = property_Aircraft_AltitudeFeet.getValue();
        var heading = property_Aircraft_HeadingDeg.getValue();

        if(positions == nil or altitudeFeet == nil or heading == nil)
            return;

        altitudeFeet += f15EscortAltitudeOffset;
        f15EscortLeftModel = createF15EscortModel("RG-ESCORT-1", positions[0], altitudeFeet, heading);
        f15EscortRightModel = createF15EscortModel("RG-ESCORT-2", positions[1], altitudeFeet, heading);

        if(f15EscortLeftModel == nil or f15EscortRightModel == nil)
        {
            removeF15EscortModels();
            f15EscortState = "unavailable";
            f15EscortTimer.stop();
            showPopup(RGAtcName ~ ": FlightGear could not create the simulated F-15 escort models.");
            return;
        }

        f15EscortElapsed = 0;
        f15EscortState = "approaching";
        showPopup(RGAtcName ~ ": Two simulated F-15s are approaching to escort your flight.");
        return;
    }

    if(f15EscortState == "approaching" or f15EscortState == "escorting")
    {
        var altitudeAgl = property_Aircraft_AltitudeAglFeet.getValue();

        if(squawkingMode != "On" or emergencySquawkCode != "7500" or
           isAtcEnabled() == 0 or altitudeAgl == nil or altitudeAgl < 40)
        {
            f15EscortState = "departing";
            f15EscortElapsed = 0;
        }
        else if(f15EscortState == "approaching")
        {
            f15EscortElapsed += f15EscortUpdateSeconds;

            var progress = f15EscortElapsed / f15EscortApproachSeconds;

            if(progress > 1)
                progress = 1;

            var distanceBehind = f15EscortStartDistance -
                ((f15EscortStartDistance - f15EscortEndDistance) * progress);

            updateF15EscortModels(distanceBehind);

            if(progress >= 1)
                f15EscortState = "escorting";

            return;
        }
        else
        {
            updateF15EscortModels(f15EscortEndDistance);
            return;
        }
    }

    if(f15EscortState == "departing")
    {
        f15EscortElapsed += f15EscortUpdateSeconds;

        var progress = f15EscortElapsed / f15EscortDepartureSeconds;

        if(progress > 1)
            progress = 1;

        var distanceBehind = f15EscortEndDistance +
            ((f15EscortStartDistance - f15EscortEndDistance) * progress);

        updateF15EscortModels(distanceBehind);

        if(progress >= 1)
        {
            removeF15EscortModels();
            f15EscortState = "idle";
            f15EscortElapsed = 0;
            f15EscortTimer.stop();
        }
    }
});
