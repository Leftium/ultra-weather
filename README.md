# UltraWeather

**Live demo:** [User-friendly weather forecast](https://uw.leftium.com)

[![UltraWeather](https://cdn.glitch.com/e2e10ff0-74aa-48e9-88ca-0643a72848b9%2Fultraweather.jpg)](https://uw.leftium.com)

At a glance, quickly determine:
- Is it warmer than yesterday? Colder than the day before?
- Is it warm enough for short sleeves?
- Do I need sunscreen? An umbrella?

UltraWeather also gives a better [intuitive sense of the temperature](http://blog.leftium.com/2013/12/how-to-display-temperature-properly.html).

## Advanced Usage

UltraWeather options are set via the URL:

### Specify a location
- https://uw.leftium.com Default is location based on IP address.
- https://uw.leftium.com/london By city name.
- https://uw.leftium.com/london,,GB Force country to Great Britain.
- https://uw.leftium.com/55105 Sometimes ZIP codes work.

Locations are retrieved from the [OpenWeather geocoding API](https://openweathermap.org/api/geocoding-api), and sorted to prefer some countries like the US.

### Choose which weather API to use
- https://uw.leftium.com/?api=openweather
    - Possible API's: `darksky`,`openweather`,`visualcrossing`
    - Get mock data: `mockdarksky`,`mockopenweather`,`mockvisualcrossing`
    - Short versions: `ds`, `mds`
    
### Get debug info
- https://uw.leftium.com/?debug&api=mds,mow,mvc Returns data from three API's, inspectable in the browser dev console. Normally only data from the first successful call is returned.

![Debug Info](https://cdn.glitch.com/e2e10ff0-74aa-48e9-88ca-0643a72848b9%2F6611b888-f83c-4066-b1a8-c7e27ab367a3.image.png?v=1610690770121)
   
    



## How to build:

    git clone https://github.com/Leftium/ultra-weather.git
    cd ultra-weather
    
    yarn            # Install dependencies.
    netlify init    # Connect to Netlify.
        # Answer like this at prompts:
        # Your build command: "yarn dev"
        # Directory to deploy to: "public"
        # Netlify functions folder: "functions"
    netlify dev     # Start the local server!

The above will fall back to mock data, since no API keys are configured. To show live weather data, set up your API keys:
    
    cp .env-example .env
    ## Edit .env file with your own API keys
    netlify dev
    
### Get your own API keys:

All these services offer a generous free tier:

- [OpenWeather](https://openweathermap.org/api) This API is also used to geocode place names to lat/long.
- [Visual Crossing](https://www.visualcrossing.com/weather-api)
- [Dark Sky](https://darksky.net/dev) (Unfortunately Dark Sky API does not accept new signups.)

- [ip-api](https://ip-api.com/) Used to geocode IP address to lat/long. No API key needed, but listed here for reference.


### You may also need to install/configure Netlify Dev

- [Blog post tutorial](https://scotch.io/tutorials/netlify-dev-the-power-of-netlify-on-your-local-computer)
- [Netlify Dev](https://www.netlify.com/products/dev/)
