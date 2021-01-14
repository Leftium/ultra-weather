# UltraWeather

![UltraWeather](https://trello-attachments.s3.amazonaws.com/57f3b8fdfee753ac33f2bfad/5ffe720969170381d98f11bb/281ecf33932ed6c9efa7b87eb86ba74b/ultraweather.jpg)

User-friendly, actionable weather forecasts: at a glance, you can quickly decide:
- "Is it warm enough for short sleeves?"
- "Do I need sunscreen? An umbrella?"

UltraWeather also gives you a better [intuitive sense of the temperature](http://blog.leftium.com/2013/12/how-to-display-temperature-properly.html).

Live demo: [uw.leftium.com](https://uw.leftium.com)

## How to build:

    git clone https://github.com/Leftium/ultra-weather.git
    cd ultra-weather
    yarn                                 # Install dependencies.
    netlify init                         # Connect to Netlify.
        # Answer like this at prompts:
        # Your build command: "yarn dev"
        # Directory to deploy to: "public"
        # Netlify functions folder: "functions"
    netlify dev                          # Start the local server!

The above will fall back to mock data, since no API keys are configured. To show live weather data, set up your API keys:
    
    cp .env-example .env
    ## Edit .env file with your own API keys
    netlify dev
    
### Get your own API keys:

- [Dark Sky](https://darksky.net/dev) (Unfortunately Dark Sky API does not accept new signups.)
- [OpenWeatherMap](https://openweathermap.org/api)

### You may also need to install/configure Netlify dev

- [Blog post tutorial](https://scotch.io/tutorials/netlify-dev-the-power-of-netlify-on-your-local-computer)
- [Netlify Dev](https://www.netlify.com/products/dev/)



