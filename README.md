# Red Griffin ATC

### A speaking Air Traffic Controller addon for FlightGear

#### Version 2.6.1 - Unofficial remaster, 26 October 2026

## Project status

This repository and its releases are an **unofficial remaster** of the original
Red Griffin ATC add-on for FlightGear. The original add-on was created by
Antonello Biancalana (Red Griffin, IK0TOJ). This is a separate remastered
release, not an official release of the original project. See the
[original project page](https://sourceforge.net/projects/red-griffin-atc/).

### Main features:

* Support for ground, take off, visual approach, ILS and landing operations
* ATC assisted approach, guiding the pilot to the proper route, altitude and
  speed up to the final approach point to runway and according to aircraft type
* Festival Speech Synthesis System support
* Squawking
* Recognition and simulated ATC acknowledgements for emergency squawks 7500, 7600 and 7700
* Optional visual F-15 escorts for airborne squawk 7500 (requires a separate F-15 aircraft installation)
* Context-aware ground and takeoff checks, with varied radio phraseology that works offline
* Approach and slope monitor
* Speech synthesis of messages through native FlightGear speech synthesizer
* ATC can be operated both with mouse and keyboard
* Independent dialog window or pop-up window operation modes
* Determination of proper take-off and landing runways according to wind direction
  and airport settings
* Status monitor for both ground and flying modes (ground speed, current position,
  runway alignment, runway approaching)
* Determination of approaching routes and patterns according to position and route
  manager
* Automatic control and warning in case of incorrect procedure
* Radio station type check according to ATC request
* Automated ATC callback messages according to procedure
* Dedicated window with available radios
* Automatic selection of ATC requests according to aircraft status and position
* Information about the current airport
* Information about the tuned communication radio
* Support for CTR (Controlled Traffic Region)
* When flying in an approved CTR, ATC will check your correct altitude and warns in
  case the aircraft is flying too low or towards terrain, such as hills or mountains.
  ATC may also require the pilot to change altitude according to heading and area.
* When flying in an approved CTR, the pilot can request to the ATC to change its current
  flight level with dedicated buttons
* When flying in an approved CTR, in case the aircraft is about to leave the CTR range,
  ATC will inform the pilot about the neighboring CTR and gives information about the
  corresponding radio in order to request transition approval to the new zone.
* Displayed information according to flight/approach/lading modes
* Buttons for aborting approach, ILS and landing procedures
* And a lot more

Download the ready-to-install package from the [Red Griffin ATC download page](https://thomasnullpunkt.github.io/RedGriffinATC-revisited/).


## How to install Red Griffin ATC

* Download the <code>.zip</code> or <code>.tar.gz</code> package from the
  [Red Griffin ATC download page](https://thomasnullpunkt.github.io/RedGriffinATC-revisited/).
* Unpack the archive with a proper command (<code>zip</code> or <code>tar</code>) or utility in a convenient place
  of your disk
* It will be created a directory named <code>RedGriffinATC</code> containing the addon


### Running Red Griffin ATC addon from command line

* Start <code>fgfs</code> including <code>--addon=&lt;your_local_path&gt;/RedGriffinATC</code> option in the command line


### Running Red Griffin ATC addon from the Launcher

* Start FlightGear launcher
* Click "Add-ons" button
* Scroll down to "Add-on Module folders" section
* Click "Add +" button
* Select "RedGriffinATC" directory from the path where you unpacked the distribution file
* The add-on will be added to the list of installed addons. Make sure it is enabled
  and the corresponding "check-box" is checked.
* Start FlightGear by clicking the "Fly!" button


### How to use Red Griffin ATC

Red Griffin ATC can be operated both with the mouse and the keyboard. You will
find a new item "Red Griffin ATC" in FlightGear's menu from which you can open
and close the main dialog window as well as get help about keyboard commands and
information about the addon. You can open or close the main dialog window by
pressing the <&#92;> key (backslash). You can also show the "pop-up dialog" by
pressing <ctrl+\\\> key sequence (control + backslash).


### The Main Dialog

Red Griffin ATC can be operated with the mouse through its main dialog window in
which are shown information about the current flight, radios, approaching and
landing instructions.

The dialog is divided in three main areas:

* **Top area**: information about the current airport, altitude, speed,
  approaching and landing instruction, current CTR, radio station in use

* **Middle area**: Requests to the ATC, Radio list

* **Bottom area**: CTR requests, Flight level requests, Abort requests, Radio
  list, Dialog close


#### Top Area

The top area of the dialog is divided in three sub areas: white (top), blue
(middle), yellow (bottom).

The **white area** changes according the flight status. During ground operations
and when the aircraft is flying over an airport area, in this part are shown
airport information, aircraft speed and altitude according to the status of the
flight.

During the flight and in case the aircraft is not flying over an airport, in
this part are shown flight information such as altitude, AGL, heading and speed.
When the aircraft is approaching an airport for landing (both visual and ILS) in
this area are shown the course and distance to both the pattern point and final
point (see picture above) as well as the landing runway.

When the aircraft is on the final course to landing, here are shown the
approaching runway, distance to the runway, AGL and a "correction bar". This bar
shows the correction in relation to the center of the runway: the shorter the
more the aircraft is near the runway horizontal path. For example, a bar like
this one [===>] means the aircraft should heavily correct the course to the
right, while a bar like [=>] means the aircraft need to slightly turn to right
in order to be in the correct path, [ok] means the aircraft is aligned to the
center of the runway. In case the correction needs a left turn, the bar is shown
as [<===] or [<=].

The **blue area** is reserved to CTR information (Controlled Traffic Region)
such as name of the airport controlling the CTR, controlled area range in
nautical miles, distance and course to the center of CTR, frequency of the
corresponding radio. In this area is also reported the aircraft status in
relation to the CTR: "inside", "approved" or "flying to". "Inside" means the
aircraft is flying inside the CTR but has not been approved by the ATC;
"approved" means the aircraft is flying inside the CTR and has been granted
transition permission by the ATC; "flying to" means the aircraft is outside the
CTR but it is flying towards the controlled area.

The **yellow area** is reserved to the radio information and status, such as COM
radio in use, radio station name and type, frequency, distance and course to the
station, readability quality from 1 to 5.


#### Middle Area

The middle area is divided in two parts. In the left side are found the
operational buttons with the requests to be transmitted to the ATC, in the right
side is found the list of the available radios provided and operated by the
currently tuned airport.

The left side provides a maximum of four buttons, each corresponding to a
specific request and depending on the aircraft position and status. In the top
part can also be found a "R" button (Repeat) to be used for requesting the ATC
to repeat the last message.

The right side is used to tune and select a specific radio from the ones
currently available and operated by the tuned airport. Each entry is actually a
button to be used for tuning the COM in use to the corresponding radio station.


#### Bottom Area

The bottom area of the dialog is reserved to CTR, flight level requests, abort
operation, radio list and dialog closing. The Leftmost button is used to request
the CTR transition to the ATC, while the three buttons in the center are used
for requesting a new flight level to the ATC. During the approach, ILS and
landing operations, these three buttons are replaced by the "abort" button used
to cancel the current operation. The "radio" button shows a list of the radio
stations available in the current airport, while the "close" button dismiss the
dialog. The dialog can be reopened by pressing the backslash key or by using the
menu.


### Red Griffin ATC Keys and Commands

* **<&#92;>** (backslash) - Open or close dialog
* **<ctrl+\\\>** (control + backslash) - Show popup dialog
* **<Ctrl+4>** - Send message 1 to ATC
* **<Ctrl+5>** - Send message 2 to ATC
* **<Ctrl+6>** -Send message 3 to ATC
* **<Ctrl+7>** - Send message 4 to ATC
* **<Ctrl+9>** - Repeat last ATC message
* **<Ctrl+0>** - Request CTR transition
* **<Ctrl+Shift+4>** - Request Flight Level 1
* **<Ctrl+Shift+5>** - Request Flight Level 2
* **<Ctrl+Shift+6>** - Request Flight Level 3
* **<Ctrl+Shift+0>** - Abort Approach/ILS/Landing


### Settings

Red Griffin ATC can be configured by using the settings dialog in which it is
possible to set how the ATC will provide information to the pilot as well as how
the pilot will interact with the ATC.

To open the settings dialog select the corresponding function in "Red Griffin ATC"
menu.

The changes done in the settings dialog are immediate and are effective as soon
as the dialog is closed. The settings dialog allows to change the following
options and therefore affecting the operational mode of the Red Griffin ATC
addon:

* **Dialog Position** *(possible values: Top Left, Top Right, Bottom Left,
  Bottom Right)* - Sets the initial position of the main dialog relative to the
  screen or window.

* **ATC text position** *(possible values: Top Left, Top Center, Top Right,
  Middle Left, Middle Center, Middle Right, Bottom Left, Bottom Center, Bottom Right)*
  - Sets the position of the ATC messages relative to the screen.

* **ATC text transparency** *(possible values: Off, Very low, Low, Medium, High,
  Very high)* - Sets the transparency of ATC messages in the screen.

* **Call sign** - Pilot call sign or aircraft registration code. It defaults to
  <code>/sim/multiplay/callsign</code> property. This value is copied both to
  <code>/sim/multiplay/callsign</code> and <code>/sim/user/callsign</code>
  properties.

* **Call sign usage** *(possible values: Complete, Last three letters, First and
  last two letters)* - Defines how the ATC will use the pilot's call sign in all
  communications. Please note whenever a radio is tuned for the first time, the
  pilot will always provide the call sign in complete form in the very first
  contact to the radio station.

* **Include manufacturer** *(possible values: Yes, No)* - Defines whether the
  name of the aircraft manufacturer is to be used during the communication with
  the ATC.

* **QNH reported in** *(possible values: hPa, inHg, hPa and inHg)* - Sets the
  unit of measure used by the ATC to report the QNH value (atmospheric pressure)
  to the pilot for the proper altimeter setting: hectopascal (hPa), inches of
  mercury (inHg) or both.

* **Aircraft type** *(possible values: Auto, Small single engine, Small multi
  engine, Executive turboprop/jet, Business jet, Airline jet, Large/military jet,
  Special military)* - Defines the rules and settings used by the ATC and
  according to the aircraft type. In particular, it changes the parameters used in
  the assisted approach procedure - such as altitude, distance and speed - initial
  altitude after take off and cruising altitude. When set to "Auto" Red Griffin
  ATC will try to automatically detect the aircraft type according to the values
  set in <code>/sim/tags</code>. In case it was not possible to detect the
  aircraft types, including the case the aircraft in use has no tags defined, Red
  Griffin ATC will warn the user to properly choose the aircraft type. In case the
  user does not set an aircraft type, Red Griffin ATC will consider the aircraft
  as a "Small single engine" and set operational parameters accordingly. The
  currently selected aircraft type is always shown in the main dialog's title bar.

* **Squawking** *(possible values: On, Off)* - Enable or disable ATC squawking.
  When on, the ATC will require the pilot to properly set the aircraft's
  transponder as well as operating it according to the ATC requests.

  When the active transponder is set to **7500** (unlawful interference), **7600**
  (radio communications failure) or **7700** (general emergency), Red Griffin ATC
  recognizes the code, gives a matching simulated ATC acknowledgement, and stops
  asking you to restore the routine assigned code until the emergency squawk is
  cleared. These messages are for FlightGear simulation only and are not real
  aviation guidance.

  When airborne, an active **7500** squawk also brings two visual-only F-15 models
  in from behind to hold an escort position. This requires the FlightGear F-15
  aircraft to be installed separately so
  <code>Aircraft/F-15/Models/f15c.ac</code> is available in the aircraft search
  path. The aircraft model is not included in this add-on download. These escort
  models do not have independent flight dynamics or weapon functionality.

* **Open dialog at startup** *(possible values: On, Off)* - Enable or disable the
  opening of Red Griffin ATC dialog at FlightGear startup.

* **Pilot request** *(possible values: Disabled, Voice only, Text only, Voice
  and text)* - Defines how the pilot requests to the ATC are to be shown, spoken
  or disabled. Text modes will show a pop-up message with the pilot request to be
  transmitted to the ATC, Voice modes will activate the speech synthesis for the
  requests by using <code>/sim/sound/voices/pilot</code> property and will
  therefore use the voice assigned by FlightGear for that specific purpose.

* **Pilot response** *(possible values: Disabled, Voice only, Text only, Voice
  and text)* - Same as "Pilot request" but referring to the confirmation responses
  and message used by the pilot to acknowledge the ATC operations and
  instructions.

* **ATC message** *(possible values: Voice only, Text only, Voice and text)* -
  Defines how the ATC messages to the pilot are to be shown or spoken. Text modes
  will show a pop-up message with the ATC message, Voice modes will activate the
  speech synthesis for the messages by using <code>/sim/sound/voices/atc</code>,
  <code>/sim/sound/voices/approach</code> and
  <code>/sim/sound/voices/ground</code> properties according to the radio station
  type and will therefore use the voice assigned by FlightGear for that specific
  purpose.

* **ATC radio** *(possible values: Auto, COM1, COM2, COM3)* - Select the COM
  radio to be used for ATC communications. In case it is set to "Auto", the first
  radio tuned to a valid ATC frequency will be used.

* **Too low warning** *(possible values: On, Off)* - Enable or disable ATC
  warning in case the aircraft is flying too low.

* **Terrain warning** *(possible values: On, Off)* - Enable or disable ATC
  warning in case the aircraft is flying towards terrain, such as a mountain or
  hill.

* **Multiplayer chat** *(possible values: Off, Important messages only, All
  messages)* - Define how ATC messages should be broadcast to the multiplayer chat
  in order to let other know about the traffic in your current airport. When set
  to "Important messages only", only relevant traffic information will be sent to
  the multiplayer chat, such as taxing, take off and landing.

* **Approach slope angle** *(possible values: from 2 to 8)* - Approach slope
  angle in degrees for the final leg to the destination runway. Default: 3
  degrees.

* **Reset button** - Resets all the setting options to their default value.

* **Close button** - Close the settings dialog and permanently save the options
  to the file <code>$FG_HOME/Export/RedGriffinATC-config.xml</code>

  
### ATC Log

Red Griffin ATC logs every message sent and received to or from any radio tuned
during the flight session. The ATC Log can be opened by selecting "ATC Log" from
the menu. The messages can be scrolled with the mouse wheel or by grabbing the
"scroll bar" to the right of the window.

The log widows has two buttons and corresponding to the following actions:

* **Clear** - Clears all the messages contained in the log

* **Close** - Close the log window


### Supported Aircraft Types and Operational Values

Red Griffin ATC provides support for the below aircraft types. Each of them uses
specific operational values and used by Red Griffin ATC in determining the
procedures of approach and landing, such as minimum cruise altitude, speed,
approach and pattern distance. For each aircraft type are used the below values:

#### Small single engine

* Minimum cruise altitude: 3500 feet
* Pattern speed: 100 knots
* Approach speed: 90 knots
* Final speed: 70 knots
* Approach point distance: 10 nautical miles
* Pattern point distance: 3 nautical miles

#### Small multi engine

* Minimum cruise altitude: 3500 feet
* Pattern speed: 120 knots
* Approach speed: 100 knots
* Final speed: 85 knots
* Approach point distance: 10 nautical miles
* Pattern point distance: 3 nautical miles

#### Executive turboprop/jet

* Minimum cruise altitude: 5500 feet
* Pattern speed: 160 knots
* Approach speed: 140 knots
* Final speed: 120 knots
* Approach point distance: 12 nautical miles
* Pattern point distance: 5 nautical miles

#### Business jet

* Minimum cruise altitude: 5500 feet
* Pattern speed: 170 knots
* Approach speed: 150 knots
* Final speed: 130 knots
* Approach point distance: 15 nautical miles
* Pattern point distance: 5 nautical miles

#### Airline jet

* Minimum cruise altitude: 7500 feet
* Pattern speed: 180 knots
* Approach speed: 160 knots
* Final speed: 140 knots
* Approach point distance: 15 nautical miles
* Pattern point distance: 6 nautical miles

#### Large/military jet

* Minimum cruise altitude: 8500 feet
* Pattern speed: 210 knots
* Approach speed: 190 knots
* Final speed: 150 knots
* Approach point distance: 15 nautical miles
* Pattern point distance: 7 nautical miles

#### Special military

* Minimum cruise altitude: 8500 feet
* Pattern speed: 210 knots
* Approach speed: 190 knots
* Final speed: 150 knots
* Approach point distance: 15 nautical miles
* Pattern point distance: 8 nautical miles

### Aircraft compatibility

Red Griffin ATC radio support and use rely on FlightGear properties and, for this
reason, it is essential for the aircraft to provide a functional implementation of
both the radio stack and transponder. Red Griffin ATC has been extensively tested
with tens of aircraft and, according to these tests, not all aircraft seem to
provide a complete implementation of COM radios and transponder. In this particular
case, those aircraft will not work because of lack of fundamental properties needed
by Red Griffin ATC. Red Griffin ATC uses and relies on the
following radio properties for each COM radio:

* <code>/instrumentation/comm[x]/serviceable</code>
* <code>/instrumentation/comm[x]/signal-quality-norm</code>
* <code>/instrumentation/comm[x]/volume</code>
* <code>/instrumentation/comm[x]/volume-selected</code>
* <code>/instrumentation/comm[x]/power-btn</code>
* <code>/instrumentation/comm[x]/airport-id</code>
* <code>/instrumentation/comm[x]/station-name</code>
* <code>/instrumentation/comm[x]/frequencies/selected-mhz</code>
* <code>/instrumentation/comm[x]/track-distance-m</code>
* <code>/instrumentation/comm[x]/true-bearing-to-deg</code>

Moreover, in order to be fully compatible with Red Griffin ATC, the aircraft must also
provide operative support for its transponders, in particular, the below properties need
to be properly defined and usable:

* <code>/instrumentation/transponder[x]/serviceable</code>
* <code>/instrumentation/transponder[x]/operable</code>
* <code>/instrumentation/transponder[x]/inputs/knob-mode</code>
* <code>/instrumentation/transponder[x]/id-code</code>
* <code>/instrumentation/transponder[x]/ident</code>

In case the aircraft does not provide some of the above properties, Red Griffin
ATC will show a warning message in the main dialog and any radio operation will
not be possible. In this specific case, you can contact the aircraft developer
and ask for a revision of the radio implementation in order to comply to the
above properties.

Please note Red Griffin ATC reads and uses the above properties "as they are"
and relies on their data. If you notice some incongruence in data shown both in
the radio stack or Red Griffin ATC dialog window or popup, it is probably
because of improper data written by the aircraft in FlightGear properties.

A list of the aircraft tested with Red Griffin ATC can be found
[here](https://wiki.flightgear.org/Red_Griffin_ATC_compatible_aircraft). The
list is continuously updated and tries to provide both a reliable and up-to-date
source of compatible and incompatible aircraft. You are invited to browse this
list and check aircraft compatibility in case you see or experience a wrong or
unexpected behavior in Red Griffin ATC.


### Controlled Traffic Region

Red Griffin ATC provides a simple Controlled Traffic Region (CTR) management
however effective and enough for normal flight simulation. CTR range is
determined according to the the supposed size of the airport controlling it.
Airport size is arbitrarily determined by the number of radio stations operating
in the airport. The greater the number of radio stations, the bigger the
supposed airport size and according to this schema:

* 1 radio station: small
* 2-4 radio stations: medium
* 5 or more radio stations: big

CTR range is therefore determined according to this schema:

* Small airport: 20 nm
* Medium airport: 30 nm
* Big airport: 50 nm


### Assisted Approach and Landing

Red Griffin ATC can guide the pilot to the proper route up to the final leg to
the runway. In order to work properly, the assisted approach and landing
procedure requires the pilot to provide the right operational settings, in
particular aircraft type and approach slope angle. It is also very important to
set the altimeter according to the QNH provided by the ATC in order to follow a
reliable and consistent altitude.

As for approach slope angle, Red Griffin ATC uses 3 degree as a default value,
however this can be changed in the settings dialog. The pilot is therefore
required to properly set the approach slope angle before initiating the assisted
approaching procedure and according to the destination airport and runway. The
correct approach slope angle is usually reported in airport charts and each
airport usually has its own angle setting.

Before initiating the assisted approach procedure (or before taking off) it is
advised to follow this very minimal checklist:

* Set aircraft type (settings dialog)
* Set approach slope angle according to the runway of destination airport (settings dialog)
* Set the altimeter according to the QNH provided by the ATC (aircraft cockpit panel)


### Approach and slope monitor

When the aircraft is about to land, while it is flying the final leg to runway
and within 5 nautical miles from the runway landing area, Red Griffin ATC gives
the pilot both the distance to the touch down point as well as an "approach and
slope monitor" in order to assist the pilot in following the right course and
glide path to landing.

Course correction is represented by a "bar" showing the direction in which the
aircraft should turn in order to align to the center of runway. Specifically,
when the monitor shows "<===" means the pilot should turn to the left, whereas
in case it shows "===>" it is needed a turn to the right. The longer the bar,
the farther the distance from the center of glide path.

The monitor also provides information about the correction in altitude in order
to follow the proper glide path to the landing area of runway. In case the
monitor shows a "v" it means the aircraft is flying too high and the pilot must
descend, whereas in case it shows a "^", the aircraft is flying too low and the
pilot must climb.

In case the aircraft is perfectly aligned and following the proper glide path,
the monitor will show "ok".

## Festival Speech Synthesis System Support

Red Griffin ATC can take advantage of the superior voice quality offered by the
[Festival Speech Synthesis System](https://www.cstr.ed.ac.uk/projects/festival)
through FlightGear direct support for Festival running in server mode. In order
to use the Festival Speech Synthesis System, you need to have a properly
installed and working Festival system in your machine as well as having at least
FlightGear version 2020.3.6. Prior to this version, FlightGear cannot properly
support and initialize the Festival Speech Synthesis System and will therefore
fall back to the internal default speech synthesizer.

The Festival Speech Synthesis System running in server mode allows up to ten
simultaneous connections, therefore it can provide up to ten different voices.
Red Griffin ATC takes advantage of this feature and can provide a fuller and
deeper experience by using those ten different voices and by assigning them to
each specific radio. The available voices are assigned at random from the whole
pool of voices available and properly configured through FlightGear COMM
properties. This will give the sensation of speaking to different operators
during the whole flight session. Red Griffin ATC associates a specific voice to
any specific radio frequency and the association is kept for the whole duration
of the flight. This means you are going to hear the very same voice in case you
are tuning back to a radio frequency already used in the current flight session.
Please note pilot voice is associated to a specific voice and exclusively used
for that purpose. This means the pilot voice will never be used for radio
operators.

### Configuring Red Griffin ATC with Festival Support

Festival Speech Synthesis System support in Red Griffin ATC is implemented
through FlightGear internal properties, in particular those related to sound and
voice support, found in the <code>/sim/sound/voices</code> tree.

Voices can be defined and set up by using a configuration <code>XML</code> file
describing each FlightGear voice according to the internal structure of the
property tree. Here it is how a voice should be configured in order to support
the Festival Speech Synthesis System:

<code>
&lt;voice&gt;<br>
    &lt;desc&gt;Pilot&lt;/desc&gt;<br>
    &lt;text type="string"/&gt;<br>
    &lt;volume type="double"&gt;1.0&lt;/volume&gt;<br>
    &lt;pitch type="double"&gt;100.0&lt;/pitch&gt;<br>
    &lt;speed type="double"&gt;0.8&lt;/speed&gt;<br>
    &lt;preamble type="string"&gt;(voice_cmu_us_rms_cg) (audio_mode 'async)&lt;/preamble&gt;<br>
    &lt;festival type="bool"&gt;true&lt;/festival&gt;<br>
    &lt;htsvoice type="string"&gt;cstr_uk_female-1.0.htsvoice&lt;/htsvoice&gt;<br>
&lt;/voice&gt;<br>
</code>

In order to be used in Festival, a voice needs the <code>&lt;festival&gt;</code>
and <code>&lt;preamble&gt;</code> properties to be properly initialized.
Specifically, <code>&lt;festival&gt;</code> property must be <code>true</code>
(that is, enabled) while <code>&lt;preamble&gt;</code> property must contain
valid Festival <code>scheme</code> commands to be sent to the server at
initialization time. The <code>&lt;preamble&gt;</code> property must at least
contain the <code>scheme</code> command selector for the specific Festival voice
to be associated to a FlightGear voice.

In this regard, it is strongly advised to set Festival in asynchronous audio
mode by adding the <code>scheme</code> command <code>(audio_mode 'async)</code>
to the <code>&lt;preamble&gt;</code> property. In this case, Red Griffin ATC
will interact with Festival in a way that will provide a quicker response and by
actually creating utterances while speaking, therefore getting a better
synchronization with ATC texts shown in the screen.

In case <code>(audio_mode 'async)</code> is not used, Red Griffin ATC
interaction with Festival server will result with an "out of sync"  speaking in
relation to the text shown in the screen.

Voices can also be "fine tuned" by properly setting <code>&lt;volume&gt;</code>,
<code>&lt;pitch&gt;</code> and <&lt;speed&gt;</code> properties.

The property <code>&lt;desc&gt;</code> can optionally describe the defined voice
and, in particular, the voice to be used for the pilot. In this specific case,
<code>&lt;desc&gt;</code> property must be assigned to "Pilot", like the sample
shown above. In case no voice is assigned to the pilot, Red Griffin ATC will use
the value found in <code>/sim/sound/voices/pilot</code>.

Red Griffin ATC is distributed with a sample configuration file defining ten
different Festival voices and can be used "out of the box" or used as a template
in case it is wished a different voice scheme or configuration. The sample
configuration file is found at
<code>&lt;your_local_path&gt;/RedGriffinATC/festival.xml</code>. The
<code>festival.xml</code> is configured in order to use some Festival default
voices as well as some of those available at
[http://festvox.org/packed/festival/2.4/voices Festvox website]. In order to use
the configuration file provided with Red Griffin ATC, you need to properly
install the Festival voices defined in <code>festival.xml</code> and available
at the Festvox website.

### Running Festival in Server Mode

In order to run Festival, you need it to be properly installed and working in
your system. Festival can be compiled and installed from the source distribution
or by using the binary package available for your system.

To start Festival in server mode, you need to open a shell or console window and
type:

<code>festival --server</code>

The Festival Speech Synthesis System will then listen to port 1314 waiting for
incoming requests and will accept up to ten simultaneous clients.

### Running FlightGear with Festival Support

In order to have FlightGear using the configuration file as described above, you
need to use the <code>--config</code> option.

In case you are going to start FlightGear from the command line, you need to
append the <code>--config</code> option and the path of festival configuration
file:

<code>fgfs [your_options] --config=&lt;your_local_path&gt;/RedGriffinATC/festival.xml</code>

In case you are using FlightGear launcher, you need to add
<code>--config=&lt;your_local_path&gt;/RedGriffinATC/festival.xml</code> in the
"Additional Settings" box found in the "Settings" tab.


### Videos and tutorials

For a quick preview and sample sessions of Red Griffin ATC, you can watch these videos:


### Demonstration Flight and Tutorial

[[embed url=https://www.youtube.com/watch?v=DEuz9hTpvuI]]

[[embed url=https://www.youtube.com/watch?v=ZOxDTGj9UnQ]]

**Initial operations and setup**

[[embed url=https://youtu.be/ZOxDTGj9UnQ?t=110]]

**Take-off**

[[embed url=https://youtu.be/ZOxDTGj9UnQ?t=313]]

**Terrain alert**

[[embed url=https://youtu.be/ZOxDTGj9UnQ?t=513]]

**Flight information**

[[embed url=https://youtu.be/ZOxDTGj9UnQ?t=660]]

**Altitude check**

[[embed url=https://youtu.be/ZOxDTGj9UnQ?t=708]]

[[embed url=https://youtu.be/ZOxDTGj9UnQ?t=1470]]

**Leaving and entering CTR**

[[embed url=https://youtu.be/ZOxDTGj9UnQ?t=848]]

[[embed url=https://youtu.be/ZOxDTGj9UnQ?t=1905]]

[[embed url=https://youtu.be/ZOxDTGj9UnQ?t=2105]]

**CTR assigning a new altitude**

[[embed url=https://youtu.be/ZOxDTGj9UnQ?t=957]]

[[embed url=https://youtu.be/ZOxDTGj9UnQ?t=1945]]

**Flight level change**

[[embed url=https://youtu.be/ZOxDTGj9UnQ?t=1023]]

[[embed url=https://youtu.be/ZOxDTGj9UnQ?t=1190]]

[[embed url=https://youtu.be/ZOxDTGj9UnQ?t=1505]]

**Flying over an airport area**

[[embed url=https://youtu.be/ZOxDTGj9UnQ?t=1278]]

**Request ILS procedure**

[[embed url=https://youtu.be/ZOxDTGj9UnQ?t=2380]]

[[embed url=https://youtu.be/ZOxDTGj9UnQ?t=2460]]

**Abort ILS procedure**

[[embed url=https://youtu.be/ZOxDTGj9UnQ?t=2450]]

**ILS established**

[[embed url=https://youtu.be/ZOxDTGj9UnQ?t=2865]]

**Request visual approach**

[[embed url=https://youtu.be/ZOxDTGj9UnQ?t=2950]]

**Reaching pattern point**

[[embed url=https://youtu.be/ZOxDTGj9UnQ?t=3210]]

**Reaching final approach point**

[[embed url=https://youtu.be/ZOxDTGj9UnQ?t=3305]]

**Landing**

[[embed url=https://youtu.be/ZOxDTGj9UnQ?t=3413]]

**Abort landing**

[[embed url=https://youtu.be/ZOxDTGj9UnQ?t=2910]]


### Red Griffin ATC videos

Assisted Visual Approach and Landing

[[embed url=https://www.youtube.com/watch?v=U7XqA1iUBF4]]

ILS Landing

[[embed url=https://www.youtube.com/watch?v=7FEtAvhdx4U]]

Operating the ATC with Keyboard Only

[[embed url=https://www.youtube.com/watch?v=s9G_zkjUMnY]]

Procedure Control, Warning and Approach Routes

[[embed url=https://www.youtube.com/watch?v=BHfvSL_4XuA]]

Altitude, Terrain Control, Flight Level Change

[[embed url=https://www.youtube.com/watch?v=65KjUT3Avl4]]

Red Griffin ATC Using Festival Speech Synthesis System

[[embed url=https://www.youtube.com/watch?v=5IhPebn2TgI]]

### Resources and links

* [Red Griffin ATC Wiki Page](http://wiki.flightgear.org/Red_Griffin_ATC)
* [Red Griffin YouTube Channel](https://www.youtube.com/c/RedGriffin)
* [Red Griffin ATC Thread in FlightGear Forum](https://forum.flightgear.org/viewtopic.php?f=6&t=36755)
* [FlightGear Newsletter April 2020](https://wiki.flightgear.org/FlightGear_Newsletter_April_2020#Red_Griffin_ATC_release)
* [FlightGear Newsletter October 2020](https://wiki.flightgear.org/FlightGear_Newsletter_October_2020#Red_Griffin_ATC_2.0_released)
* [FlightGear Newsletter November 2020](https://wiki.flightgear.org/FlightGear_Newsletter_November_2020#Red_Griffin_ATC_2.0_released)
* [Festival Speech Synthesis System](https://www.cstr.ed.ac.uk/projects/festival)
* [Festvox Project](http://festvox.org/festival/index.html)
* [Voices and lexicons for Festival 2.4](http://festvox.org/packed/festival/2.4/voices)


### Special thanks

Special thanks to the FlightGear community for the valuable help and for providing
very useful information about ATC phraseology, procedures and communication, in
particular to those participating to [Red Griffin ATC](https://forum.flightgear.org/viewtopic.php?f=6&t=36755)
thread in [FlightGear forum](https://forum.flightgear.org)


#### Original author's note

The original Red Griffin ATC was developed and written by Antonello Biancalana
(Red Griffin, IK0TOJ) in Nasal language and it was tested in FlightGear
2019.1.1, 2019.1.2, 2020.3.x and 2020.4.0 git, specifically in my Fedora Linux
FC33. I understand there can be bugs or the ATC procedures may be formally
incorrect. On this regard, any feedback, suggestion, criticism and hint on how
to improve this addon are warmly welcome. You are kindly invited to contribute
with your ideas and feedback by posting in the forum thread.

I am not a pilot and I do not have a plane pilot license, I have never been in a
real aircraft's cabin and all the times I have been in a real airplane I did it
as a passenger. All of my "plane pilot" experience is only as a "virtual and
simulated pilot", a hobby I started in 1982 and the very first flight simulator
I used was subLOGIC's FS1 Flight Simulator by Bruce Artwick running on an Apple
II.

It was not my computer though as at that time I owned a Commodore VIC20 and,
alas, the only "flight simulators" available for it were Ron Wanttaja's IFR
Flight Simulator and Anirog's Flight Path 737. The big step forward was Flight
Simulator II for Commodore 64 in 1984 and featuring a Piper PA-28-181 Archer II.
The giant step forward was in 1987 when it was released the Commodore Amiga
version (one of the most amazing and very best, revolutionary, exceptional
computer of all times) which featured three aircraft: Cessna 182RG, Gates
Learjet 25G and Sopwith Camel.

I therefore have no real ATC procedures experience and what I know about this
subject is from what I read in specialized books about ATC procedures and
phraseology found in various website of flight schools, airports and aero clubs.
Most of the phraseology used in Red Griffin ATC is created according to the
procedures found in these books and manuals, as well as from the many valuable
contributions from Red Griffin ATC users, both in FlightGear forum and direct
exchange of messages from amateur and professional licensed pilots. I understand
the procedures used in this addon may however result incorrect to real pilots,
either because of my lack of experience in this subject or because of improper
implementation. I am more than glad to get any feedback about ATC procedures
from experienced pilots and anyone knowing this subject in order to improve this
addon.



## Lineage and status

The original Red Griffin ATC is hosted at
[SourceForge](https://sourceforge.net/projects/red-griffin-atc/).
Original work: Red Griffin ATC (C) 2019-2021 Antonello Biancalana,
Red Griffin, IK0TOJ.

This repository is an **unofficial remaster** of that original
add-on. It is not an official release of the original project.
