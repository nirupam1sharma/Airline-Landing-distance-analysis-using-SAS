**Background:** Flight landing.

**Motivation:** To reduce the risk of landing overrun.

**Goal:** To study what factors and how they would impact the landing distance of a commercial flight.

## Data: 
Landing data (landing distance and other parameters) from 950 commercial flights (not real data set 
but simulated from statistical models). See two Excel files ‘FAA-1.xls’ (800 flights) and ‘FAA-2.xls’ (150 flights).

## Variable dictionary:

* Aircraft: The make of an aircraft (Boeing or Airbus).

* Duration (in minutes): Flight duration between taking off and landing. The duration of a normal flight should always be greater than 40min.

* No_pasg: The number of passengers in a flight.

* Speed_ground (in miles per hour): The ground speed of an aircraft when passing over the threshold of the runway. If its value is less than 30MPH or greater than 140MPH, then the landing would be considered as abnormal.

* Speed_air (in miles per hour): The air speed of an aircraft when passing over the threshold of the runway. If its value is less than 30MPH or greater than 140MPH, then the landing would be considered as abnormal.

* Height (in meters): The height of an aircraft when it is passing over the threshold of the runway. The landing aircraft is required to be at least 6 meters high at the threshold of the runway.

* Pitch (in degrees): Pitch angle of an aircraft when it is passing over the threshold of the runway.
