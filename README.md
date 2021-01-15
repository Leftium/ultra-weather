# UltraWeather

![UltraWeather](https://cdn.glitch.com/e2e10ff0-74aa-48e9-88ca-0643a72848b9%2Fultraweather.jpg)

User-friendly, actionable weather forecasts: at a glance, you can quickly decide:
- "Is it warm enough for short sleeves?"
- "Do I need sunscreen? An umbrella?"

UltraWeather also gives you a better [intuitive sense of the temperature](http://blog.leftium.com/2013/12/how-to-display-temperature-properly.html).

Live demo: [uw.leftium.com](https://uw.leftium.com)

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



