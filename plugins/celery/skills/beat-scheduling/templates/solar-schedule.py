"""
Celery Beat Solar Schedule Configuration

Provides solar event-based periodic task scheduling.
Use for location-based timing (sunrise, sunset, dawn, dusk, solar noon).

Security: No hardcoded credentials - all configuration from environment.
"""

from celery import Celery
from celery.schedules import solar
import os

# Initialize Celery app
app = Celery('tasks')

# Load configuration from environment
app.config_from_object('celeryconfig')

# Alternative: Direct configuration
app.conf.update(
    broker_url=os.getenv('CELERY_BROKER_URL', 'redis://localhost:6379/0'),
    result_backend=os.getenv('CELERY_RESULT_BACKEND', 'redis://localhost:6379/0'),
    timezone='UTC',  # Solar schedules always use UTC
    enable_utc=True,
)

# Location coordinates (lat, lon)
# Examples: NYC, London, Tokyo, Sydney
LOCATIONS = {
    'nyc': (40.7128, -74.0060),
    'london': (51.5074, -0.1278),
    'tokyo': (35.6762, 139.6503),
    'sydney': (-33.8688, 151.2093),
}

# Get location from environment or use default
LATITUDE = float(os.getenv('LOCATION_LATITUDE', '40.7128'))
LONGITUDE = float(os.getenv('LOCATION_LONGITUDE', '-74.0060'))

# Solar Schedule Configuration
app.conf.beat_schedule = {
    # Sunrise task
    'morning-routine': {
        'task': 'tasks.sunrise_routine',
        'schedule': solar('sunrise', LATITUDE, LONGITUDE),
        'args': (),
    },

    # Sunset task
    'evening-routine': {
        'task': 'tasks.sunset_routine',
        'schedule': solar('sunset', LATITUDE, LONGITUDE),
        'args': (),
    },

    # Solar noon (sun at highest point)
    'midday-task': {
        'task': 'tasks.solar_noon_task',
        'schedule': solar('solar_noon', LATITUDE, LONGITUDE),
        'args': (),
    },

    # Civil dawn (sun 6° below horizon)
    'dawn-task': {
        'task': 'tasks.dawn_routine',
        'schedule': solar('dawn_civil', LATITUDE, LONGITUDE),
        'args': (),
    },

    # Civil dusk (sun 6° below horizon)
    'dusk-task': {
        'task': 'tasks.dusk_routine',
        'schedule': solar('dusk_civil', LATITUDE, LONGITUDE),
        'args': (),
    },

    # Nautical dawn (sun 12° below horizon)
    'nautical-dawn': {
        'task': 'tasks.nautical_dawn_task',
        'schedule': solar('dawn_nautical', LATITUDE, LONGITUDE),
        'args': (),
    },

    # Nautical dusk (sun 12° below horizon)
    'nautical-dusk': {
        'task': 'tasks.nautical_dusk_task',
        'schedule': solar('dusk_nautical', LATITUDE, LONGITUDE),
        'args': (),
    },

    # Astronomical dawn (sun 18° below horizon)
    'astronomical-dawn': {
        'task': 'tasks.astronomical_dawn_task',
        'schedule': solar('dawn_astronomical', LATITUDE, LONGITUDE),
        'args': (),
    },

    # Astronomical dusk (sun 18° below horizon)
    'astronomical-dusk': {
        'task': 'tasks.astronomical_dusk_task',
        'schedule': solar('dusk_astronomical', LATITUDE, LONGITUDE),
        'args': (),
    },
}

# Multi-Location Solar Schedules
app.conf.beat_schedule.update({
    # NYC sunrise
    'nyc-sunrise': {
        'task': 'tasks.location_sunrise',
        'schedule': solar('sunrise', *LOCATIONS['nyc']),
        'kwargs': {'location': 'nyc'},
    },

    # London sunset
    'london-sunset': {
        'task': 'tasks.location_sunset',
        'schedule': solar('sunset', *LOCATIONS['london']),
        'kwargs': {'location': 'london'},
    },

    # Tokyo solar noon
    'tokyo-solar-noon': {
        'task': 'tasks.location_solar_noon',
        'schedule': solar('solar_noon', *LOCATIONS['tokyo']),
        'kwargs': {'location': 'tokyo'},
    },
})


# Solar Event Reference
"""
Supported Solar Events:
- sunrise: Sun crosses horizon (appears above)
- sunset: Sun crosses horizon (disappears below)
- solar_noon: Sun at highest point in sky
- dawn_civil: Civil dawn (6° below horizon, sufficient light for outdoor activities)
- dusk_civil: Civil dusk (6° below horizon, artificial lighting needed)
- dawn_nautical: Nautical dawn (12° below horizon, horizon visible at sea)
- dusk_nautical: Nautical dusk (12° below horizon, horizon no longer visible)
- dawn_astronomical: Astronomical dawn (18° below horizon, sky starts brightening)
- dusk_astronomical: Astronomical dusk (18° below horizon, sky completely dark)

Note: All solar events are calculated using UTC and are unaffected by timezone settings.
"""


# Solar Schedule Best Practices
"""
1. UTC Only:
   - Solar schedules always use UTC
   - Set app.conf.timezone = 'UTC' and app.conf.enable_utc = True
   - Convert to local time in task if needed

2. Location Accuracy:
   - Use accurate latitude/longitude coordinates
   - Decimal degrees format (not degrees/minutes/seconds)
   - Positive for North/East, negative for South/West

3. Polar Regions:
   - Be aware of polar day/night (no sunrise/sunset for months)
   - Implement fallback schedules for extreme latitudes
   - Test behavior during transition periods

4. Performance:
   - Solar calculations are computed once per day
   - Minimal performance impact
   - Suitable for any number of locations

5. Use Cases:
   - Outdoor equipment control (lights, irrigation, cameras)
   - Photography/astronomy automation
   - Energy optimization (solar panels)
   - Agricultural monitoring
   - Marine/aviation scheduling
"""


# Example Tasks
@app.task
def sunrise_routine():
    """Execute tasks at sunrise"""
    print(f"Sunrise task executing at location: {LATITUDE}, {LONGITUDE}")
    # Turn on outdoor lights, start cameras, etc.
    return "Sunrise routine complete"

@app.task
def sunset_routine():
    """Execute tasks at sunset"""
    print(f"Sunset task executing at location: {LATITUDE}, {LONGITUDE}")
    # Turn on security lights, stop outdoor equipment, etc.
    return "Sunset routine complete"

@app.task
def solar_noon_task():
    """Execute tasks at solar noon"""
    print(f"Solar noon task executing at location: {LATITUDE}, {LONGITUDE}")
    # Peak solar power monitoring, etc.
    return "Solar noon task complete"

@app.task
def dawn_routine():
    """Execute tasks at civil dawn"""
    print(f"Dawn task executing at location: {LATITUDE}, {LONGITUDE}")
    # Pre-sunrise preparations
    return "Dawn routine complete"

@app.task
def dusk_routine():
    """Execute tasks at civil dusk"""
    print(f"Dusk task executing at location: {LATITUDE}, {LONGITUDE}")
    # Post-sunset operations
    return "Dusk routine complete"

@app.task
def location_sunrise(location):
    """Multi-location sunrise task"""
    print(f"Sunrise at {location}")
    return f"Sunrise routine complete for {location}"

@app.task
def location_sunset(location):
    """Multi-location sunset task"""
    print(f"Sunset at {location}")
    return f"Sunset routine complete for {location}"

@app.task
def location_solar_noon(location):
    """Multi-location solar noon task"""
    print(f"Solar noon at {location}")
    return f"Solar noon task complete for {location}"


# Dynamic Solar Schedule Registration
@app.on_after_configure.connect
def setup_solar_tasks(sender, **kwargs):
    """
    Register solar tasks programmatically.
    Useful for multi-location or configurable systems.
    """

    # Register tasks for multiple locations
    for location_name, (lat, lon) in LOCATIONS.items():
        sender.add_periodic_task(
            solar('sunrise', lat, lon),
            location_sunrise.s(location_name),
            name=f'{location_name}-sunrise'
        )


# Coordinate Calculation Helper
"""
To find coordinates for your location:
1. Google Maps: Right-click location → "What's here?" → Copy coordinates
2. GPS apps: Use smartphone GPS
3. Online tools: latlong.net, gps-coordinates.net

Format: (latitude, longitude) in decimal degrees
- Latitude: -90 to +90 (negative = South, positive = North)
- Longitude: -180 to +180 (negative = West, positive = East)

Examples:
- New York City: (40.7128, -74.0060)
- London: (51.5074, -0.1278)
- Tokyo: (35.6762, 139.6503)
- Sydney: (-33.8688, 151.2093)
- São Paulo: (-23.5505, -46.6333)
"""


# Testing Solar Schedules
"""
Development Testing:
1. Solar schedules execute once per day at calculated time
2. For testing, use crontab or interval schedules instead
3. Verify schedule registration:
   celery -A tasks beat inspect scheduled
4. Check calculation accuracy with astronomy tools

Production Deployment:
1. Verify UTC timezone configuration
2. Test across seasonal changes (winter/summer solstice)
3. Monitor execution at expected solar times
4. Set up alerting for missed executions
"""


# Handling Edge Cases
"""
Polar Regions (latitude > 66.5° or < -66.5°):
- During polar day/night, sunrise/sunset may not occur
- Implement fallback schedules:

if abs(LATITUDE) > 66.5:
    # Use fixed time schedule as fallback
    app.conf.beat_schedule['fallback-morning'] = {
        'task': 'tasks.sunrise_routine',
        'schedule': crontab(hour=6, minute=0),
    }

Daylight Saving Time:
- Solar schedules unaffected (UTC-based)
- No DST adjustments needed
"""


if __name__ == '__main__':
    # Start Celery Beat scheduler
    # In production, run as separate process:
    #   celery -A tasks beat --loglevel=info

    from celery.bin import beat
    beat.beat(app=app).run()
