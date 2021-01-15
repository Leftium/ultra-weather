# UltraWeather

**Live demo:** [User-friendly, actionable weather forecasts](https://uw.leftium.com)

![UltraWeather](https://cdn.glitch.com/e2e10ff0-74aa-48e9-88ca-0643a72848b9%2Fultraweather.jpg)

At a glance, you can quickly decide:
- Is it warm enough for short sleeves?
- Do I need sunscreen? An umbrella?

UltraWeather also gives you a better [intuitive sense of the temperature](http://blog.leftium.com/2013/12/how-to-display-temperature-properly.html).

## Advanced Usage

UltraWeather automatically grabs your location based on your IP address, but you can specify some other options:

### Specify a location
- https://uw.leftium.com Default is location based on IP address.
- https://uw.leftium.com/london (By city name)
- https://uw.leftium.com/london,,GB (Force country to Great Britain)
- https://uw.leftium.com/55105 (Sometimes ZIP codes work)

Locations are retrieved from the [OpenWeather geocoding API](https://openweathermap.org/api/geocoding-api), and sorted to prefer some countries like the US.

### Choose which weather API to use
- https://uw.leftium.com/?api=openweather
    - Possible API's: `darksky`,`openweather`,`visualcrossing`
    - The API's are also mocked: `mockdarksky`
    - There are also short version: `ds`, `mds`
    
### Get debug info
- https://uw.leftium.com/?debug&api=mds,mow,mvc Returns data from all three mock API's, which can be inspected from the browser dev console. Normally only data from the first successful call is returned.


   
    

### Select which weather API to use

## How to build:

    git clone https://github.com/Leftium/ultra-weather.git
    cd ultra-weather
    
    yarn                # Install dependencies.
    netlify init        # Connect to Netlify.
        # Answer like this at prompts:
        # Your build command: "yarn dev"
        # Directory to deploy to: "public"
        # Netlify functions folder: "functions"
    netlify dev         # Start the local server!

The above will fall back to mock data, since no API keys are configured. To show live weather data, set up your API keys:
    
    cp .env-example .env
    ## Edit .env file with your own API keys
    netlify dev
    
### Get your own API keys:
- [OpenWeather](https://openweathermap.org/api) This API is also used to geocode place names to lat/long.
- [Visual Crossing](https://www.visualcrossing.com/weather-api)
- [Dark Sky](https://darksky.net/dev) (Unfortunately Dark Sky API does not accept new signups.)

- [ip-api](https://ip-api.com/) Used to geocode IP address to lat/long. No API key needed, but listed here for reference.


### You may also need to install/configure Netlify dev

- [Blog post tutorial](https://scotch.io/tutorials/netlify-dev-the-power-of-netlify-on-your-local-computer)
- [Netlify Dev](https://www.netlify.com/products/dev/)



