import axios from 'axios'
import dayjs from 'dayjs'

exports.handler = (event, context) ->
    console.log """\ncontext: #{JSON.stringify context, null, 2}, event: #{JSON.stringify event, null, 2}\n"""

    MOCK_IP_ADDRESS          = process.env.MOCK_IP_ADDRESS
    MOCK_DATA_DARKSKY        = process.env.MOCK_DATA_DARKSKY
    MOCK_DATA_OPENWEATHER    = process.env.MOCK_DATA_OPENWEATHER
    MOCK_DATA_VISUALCROSSING = process.env.MOCK_DATA_VISUALCROSSING
    DARKSKY_API_KEY          = process.env.DARK_SKY_API_KEY
    OPENWEATHER_API_KEY      = process.env.OPENWEATHER_API_KEY
    VISUALCROSSING_API_KEY   = process.env.VISUALCROSSING_API_KEY

    console.log o =
        MOCK_IP_ADDRESS: MOCK_IP_ADDRESS
        MOCK_DATA_DARKSKY: MOCK_DATA_DARKSKY
        MOCK_DATA_OPENWEATHER: MOCK_DATA_OPENWEATHER
        MOCK_DATA_VISUALCROSSING: MOCK_DATA_VISUALCROSSING

    host = event.headers['host']

    ipAddress = event.headers['client-ip']

    if (ipAddress is '::1') or !!MOCK_IP_ADDRESS
        ipAddress = MOCK_IP_ADDRESS
        if not !!ipAddress then ipAddress = '110.47.160.191'
        mockIp = true

    location = event.queryStringParameters.l
    console.log ['location:', location]
    if !!location  # Ensure location non-empty string.
        url = "http://api.openweathermap.org/geo/1.0/direct?q=#{location}&limit=5&appid=#{OPENWEATHER_API_KEY}"

        try
            response = await axios.get url
            data = response.data
            # Sort results to prefer some countries
            data?.sort (a, b) ->
                countryTiers = US: 1, CA: 2, GB: 3

                aTier = countryTiers[a.country] or 99
                bTier = countryTiers[b.country] or 99

                return aTier - bTier

            # console.log data
        catch error
            console.log error



    if place = data?[0]
        latitude  = place.lat
        longitude = place.lon
        location = "#{place.name}"
        if place.state
            location += ", #{place.state}"

        if place.country
            location += " [#{place.country}]"
        # location = "#{place.name}"
    else
        url = "http://ip-api.com/json/#{ipAddress}"

        response = await axios.get url
        data = response.data
        # console.log data

        latitude = data.lat
        longitude = data.lon
        location = data.city or data.regionName or data.country

    console.log vars =
        latitude: latitude
        longitude: longitude
        location:  location


    SECONDS_PER_DAY = 24*60*60

    unixEpoch = Math.floor(Date.now() / 1000)
    ts1 = unixEpoch - SECONDS_PER_DAY
    ts2 = unixEpoch - SECONDS_PER_DAY*2

    date1 = dayjs.unix(unixEpoch - 2*SECONDS_PER_DAY).format 'YYYY-M-D'
    date2 = dayjs.unix(unixEpoch + 7*SECONDS_PER_DAY).format 'YYYY-M-D'

    darkskyUrls = if !!MOCK_DATA_DARKSKY
        ["http://#{host}/json/#{MOCK_DATA_DARKSKY}.json"]
    else [
        "https://api.darksky.net/forecast/#{DARKSKY_API_KEY}/#{latitude},#{longitude}"
        "https://api.darksky.net/forecast/#{DARKSKY_API_KEY}/#{latitude},#{longitude},#{ts1}"
        "https://api.darksky.net/forecast/#{DARKSKY_API_KEY}/#{latitude},#{longitude},#{ts2}"
    ]

    openweatherUrls = if !!MOCK_DATA_OPENWEATHER
         ["http://#{host}/json/#{MOCK_DATA_OPENWEATHER}.json"]
    else [
        "https://api.openweathermap.org/data/2.5/onecall?lat=#{latitude}&lon=#{longitude}"
        "https://api.openweathermap.org/data/2.5/onecall/timemachine?lat=#{latitude}&lon=#{longitude}&dt=#{ts1}"
        "https://api.openweathermap.org/data/2.5/onecall/timemachine?lat=#{latitude}&lon=#{longitude}&dt=#{ts2}"
    ]

    url =  "https://weather.visualcrossing.com/VisualCrossingWebServices/rest"
    url += "/services/timeline/#{latitude},#{longitude}/#{date1}/#{date2}?"
    url += "key=#{VISUALCROSSING_API_KEY}&unitGroup=us&include=obs,fcst,current"
    visualcrossingUrls = if !!MOCK_DATA_VISUALCROSSING
         ["http://#{host}/json/#{MOCK_DATA_VISUALCROSSING}.json"]
    else [
        url
    ]

    # console.log url1

    callDarkSkyApi = (url) ->
        response = await axios.get url, config =
            headers:
                'Accept-Encoding': 'gzip'
            params:
                exclude: 'minutely,alerts,flags'

        data = response.data

    callOpenWeatherApi = (url) ->
        if url.match /openweathermap.org/
            url += "&units=imperial&exclude=minutely,hourly,alerts&"
            url += "appid=#{OPENWEATHER_API_KEY}"

        response = await axios.get url, config =
            headers:
                'Accept-Encoding': 'gzip'

        data = response.data

    callVisualCrossingApi = (url) ->
        console.log url
        try
            response = await axios.get url, config =
                headers:
                    'Accept-Encoding': 'gzip'
            data = response.data
        catch error
            console.log error
    promises = []
    for url in darkskyUrls
        promises.push callDarkSkyApi(url)

    dsData = await Promise.all promises
    if !!MOCK_DATA_DARKSKY
        dsData = dsData[0]
        dsData.mockData = true
    # console.log 'START DARKSKY DATA'
    # console.log  JSON.stringify(dsData)
    # console.log 'END DARKSKY DATA'


    promises = []
    for url in openweatherUrls
        promises.push callOpenWeatherApi(url)

    owData = await Promise.all promises
    if !!MOCK_DATA_OPENWEATHER
        owData = owData[0]
        owData.mockData = true
    # console.log 'START OPENWEATHER DATA'
    # console.log owData
    # console.log 'END OPENWEATHER DATA'


    promises = []
    for url in visualcrossingUrls
        promises.push callVisualCrossingApi(url)

    vcData = await Promise.all promises
    if !!MOCK_DATA_VISUALCROSSING
        vcData = vcData[0]
        vcData.mockData = true
    # console.log 'START VISUALCROSSING DATA'
    # console.log  JSON.stringify(dsData)
    # console.log 'END VISUALCROSSING DATA'

    extractFields = (data, isHistorical=false) ->
        if isHistorical
            intensity = data?.precipIntensity
            # 25.4 mm/inch, 24 hours
            mmIntensity = intensity *  25.4 * 24
            mmAccumulation = (data?.precipAccumulation or 0) * 25.4

            #console.log o =
            #    mmIntensity:mmIntensity
            #    mmAccumulation:mmAccumulation

            precipProbability = (mmIntensity + mmAccumulation)/100

        else
            precipProbability = data?.precipProbability
        object =
            time:    data?.time
            summary: data?.summary
            icon:    data?.icon

            precipProbability: precipProbability

            temperature:         data?.temperature
            apparentTemperature: data?.apparentTemperature

            temperatureMin: data?.temperatureMin
            temperatureMax: data?.temperatureMax

            apparentTemperatureMin: data?.apparentTemperatureMin
            apparentTemperatureMax: data?.apparentTemperatureMax


    darkskyIcon = (icon) ->
        switch icon
            when '01d' then 'clear-day'
            when '01n' then 'clear-night'
            when '02d','03d' then 'partly-cloudy-day'
            when '02n','03n' then 'partly-cloudy-night'
            when '04d','04n' then 'cloudy'
            when '09d','10d','11d','09n','10n','11n' then 'rain'
            when '13d','13n' then 'snow'
            when '50d','50n' then 'fog'

    extractFieldsOwHistorical = (data) ->
        # console.log data
        if summary = data?.current?.weather?[0]?.description
            summary = summary[0].toUpperCase() + summary[1..]

        current = data?.current
        #console.log icon: current?.weather?[0]?.icon
        #console.log rain: current?.rain
        #console.log snow: current?.snow

        minTemp = Number.MAX_VALUE
        maxTemp = -Number.MAX_VALUE
        minFeel = Number.MAX_VALUE
        maxFeel = -Number.MAX_VALUE

        totalRain = 0
        totalSnow = 0

        descriptions = {}
        icons        = {}

        for hour in data.hourly
            minTemp = Math.min minTemp, hour.temp
            maxTemp = Math.max maxTemp, hour.temp
            minFeel = Math.min minFeel, hour.feels_like
            maxFeel = Math.max maxFeel, hour.feels_like

            rain = (hour?.rain?['1h'] or 0)
            snow = (hour?.snow?['1h'] or 0)
            totalRain += rain
            totalSnow += snow

        for hour in data.hourly
            rain = (hour?.rain?['1h'] or 0)
            snow = (hour?.snow?['1h'] or 0)

            if (totalRain + totalSnow) > 2 and (rain or snow)
                value = 100
            else
                value = 1

            description = hour.weather?[0]?.description
            if descriptions[description]
                descriptions[description] += value
            else
                descriptions[description] = value

            icon = hour.weather?[0]?.icon
            icon = icon.replace /n/, 'd'
            icon = darkskyIcon icon
            if icons[icon]
                icons[icon] += value
            else
                icons[icon] = value

            # console.log o =
            #    rain: rain
            #    snow: snow
            #    description: hour.weather?[0]?.description

        # console.log totalRain:totalRain
        # console.log totalSnow:totalSnow

        descriptions = Object.entries descriptions
        descriptions.sort (a, b) ->b[1] - a[1]

        icons = Object.entries icons
        icons.sort (a, b) ->b[1] - a[1]


        # console.log descriptions
        # console.log icons


        object =
            time:    data?.current?.dt
            summary: descriptions[0][0]
            icon:    icons[0][0]

            precipProbability: (totalRain+totalSnow)/100

            temperature:         data?.temp if typeof data?.temp isnt 'object'
            apparentTemperature: data?.feels_like if typeof data?.feels_like isnt 'object'

            temperatureMin: minTemp
            temperatureMax: maxTemp

            apparentTemperatureMin: minFeel
            apparentTemperatureMax: maxFeel


    extractFieldsOw = (data) ->
        # console.log data

        apparentTemperatureMin = undefined
        apparentTemperatureMax = undefined
        if typeof data?.feels_like is 'object'
            {day, night, eve, morn} = data.feels_like
            # console.log [day, night, eve, morn]
            apparentTemperatureMin = Math.min(day, night, eve, morn)
            apparentTemperatureMax = Math.max(day, night, eve, morn)

        if summary = data?.weather?[0]?.description
            summary = summary[0].toUpperCase() + summary[1..]

        object =
            time:    data?.dt
            summary: summary
            icon:    darkskyIcon data?.weather?[0]?.icon

            precipProbability: data?.pop

            temperature:         data?.temp if typeof data?.temp isnt 'object'
            apparentTemperature: data?.feels_like if typeof data?.feels_like isnt 'object'

            temperatureMin: data?.temp?.min
            temperatureMax: data?.temp?.max

            apparentTemperatureMin: apparentTemperatureMin
            apparentTemperatureMax: apparentTemperatureMax


    dsResults =
        daily: []


    dsResults.summary = dsData[0].daily.summary
    dsResults.timezone = dsData[0].timezone
    dsResults.currently = extractFields dsData[0].currently
    dsResults.daily.push extractFields(dsData[2].daily.data[0], true)
    dsResults.daily.push extractFields(dsData[1].daily.data[0], true)

    # console.log dsData[2].daily.data[0]

    dsData[0].daily.data.forEach (dsData) ->
        dsResults.daily.push extractFields(dsData)

    owResults =
        daily: []

    owResults.summary = ''
    owResults.timezone = owData[0].timezone
    owResults.currently = extractFieldsOw owData[0].current

    # console.log 'JKM'
    # console.log owData[2]
    # console.log '[2]current:'
    # console.log owData[2].current
    # console.log '[1]current:'
    # console.log owData[1].current


    # console.log 'fields[2]'
    fields = extractFieldsOwHistorical owData[2]
    # console.log fields
    owResults.daily.push fields

    fields = extractFieldsOwHistorical owData[1]
    # console.log 'fields[1]'
    # console.log fields
    owResults.daily.push fields

    for day,i in owData[0].daily
        # console.log day
        owResults.daily.push extractFieldsOw day

    # console.log owResults.currently
    # console.log owResults.daily[0]

    # console.log results

    extractFieldsVc = (data) ->
        if data?.source isnt 'fcst'
            precipProbability = data?.precip * 25.4
            console.log "precip mm: #{precipProbability}"
        else
            precipProbability = data?.precipprob

        apparentTemperatureMin = data?.feelslikemin
        apparentTemperatureMax = data?.feelslikemax
        if apparentTemperatureMin is 0 and apparentTemperatureMax is 0
            apparentTemperatureMin = undefined
            apparentTemperatureMax = undefined

        object =
            time:    data?.datetimeEpoch
            datetime: data?.datetime
            summary: data?.conditions
            icon:    data?.icon

            precipProbability: precipProbability/100

            temperature:         data?.temp
            apparentTemperature: data?.feelslike

            temperatureMin: data?.tempmin
            temperatureMax: data?.tempmax

            apparentTemperatureMin: apparentTemperatureMin
            apparentTemperatureMax: apparentTemperatureMax


    vcResults =
        daily: []

    vcResults.summary = ''
    vcResults.timezone = vcData[0].timezone
    vcResults.currently = extractFieldsVc vcData[0].currentConditions

    for day in vcData[0].days
        fields = extractFieldsVc day
        vcResults.daily.push fields


    # console.log vcResults

    api = event.queryStringParameters.api or ''

    results = null
    if not results and api in ['ds', 'darksky', '']
        results = dsResults
    if not results and api in ['ow', 'openweather']
        results = owResults
    if not results and api in ['vc', 'visualcrossing']
        results = vcResults

    results.dsData = dsData
    results.owData = owData
    results.vcData = vcData

    results.ipAddress = ipAddress
    results.latitude  = latitude
    results.longitude = longitude
    results.location  = location

    if mockIp
        results.mockIp = true

    return await value =  # `await` needed to force async function.
        statusCode: 200,
        body: JSON.stringify results, null, 2

