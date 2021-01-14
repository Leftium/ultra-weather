import axios from 'axios'
import dayjs from 'dayjs'

exports.handler = (event, context) ->
    # console.log """\ncontext: #{JSON.stringify context, null, 2}, event: #{JSON.stringify event, null, 2}\n"""

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

    # Get an IP address that the geocoding API can use.
    # netlify dev localhost IP address is weird.
    ipAddress = event.headers['client-ip']
    if (ipAddress is '::1') or !!MOCK_IP_ADDRESS
        ipAddress = MOCK_IP_ADDRESS
        if not !!ipAddress then ipAddress = '1.1.1.1'
        mockIp = true

    # Get the list of preferred API's.
    location = event.queryStringParameters.l
    preferredApis = (event.queryStringParameters.api or '').split ','

    # Fallback on mock API.
    preferredApis = [...preferredApis, 'mockdarksky']

    # Normalize API names/shortcuts to full name.
    preferredApis = preferredApis.map (name) ->
        switch name.toLowerCase()
            when 'ow', 'openweather'    then 'openweather'
            when 'vc', 'visualcrossing' then 'visualcrossing'
            when 'ds', 'darksky'        then 'darksky'

            when 'mow', 'mockopenweather'    then 'mockopenweather'
            when 'mvc', 'mockvisualcrossing' then 'mockvisualcrossing'
            when 'mds', 'mockdarksky'        then 'mockdarksky'

            # Default to darksky
            else 'mockdarksky'

    console.log preferredApis: preferredApis

    SECONDS_PER_DAY = 24*60*60

    unixEpoch = Math.floor(Date.now() / 1000)
    ts1 = unixEpoch - SECONDS_PER_DAY    # Yesterday.
    ts2 = unixEpoch - SECONDS_PER_DAY*2  # Day befor yesterday.

    date1 = dayjs.unix(unixEpoch - 2*SECONDS_PER_DAY).format 'YYYY-M-D' # Day before yesterday.
    date2 = dayjs.unix(unixEpoch + 7*SECONDS_PER_DAY).format 'YYYY-M-D' # One week into future.

        # If a location passed geocode it to a lat/lon.
    console.log ['location:', location]
    if !!location  # Ensure location non-empty string.
        url = "http://api.openweathermap.org/geo/1.0/direct?q=#{location}&limit=5&appid=#{OPENWEATHER_API_KEY}"

        try
            response = await axios.get url
            places = response.data
            # Sort results to prefer some countries
            places?.sort (a, b) ->
                countryTiers = US: 1, CA: 2, GB: 3

                aTier = countryTiers[a.country] or 99
                bTier = countryTiers[b.country] or 99

                return aTier - bTier
        catch error
            console.log error

    if place = places?[0]
        # Geocode API was successful. Use the first place from the results.
        latitude  = place.lat
        longitude = place.lon

        # Construct location name from place.
        location = "#{place.name}"
        if place.state
            location += ", #{place.state}"
        if place.country
            location += " [#{place.country}]"
    else
        # Geocode lat/long from IP address.
        url = "http://ip-api.com/json/#{ipAddress}"

        response = await axios.get url
        data = response.data
        # console.log data

        latitude = data.lat
        longitude = data.lon
        location = data.city or data.regionName or data.country

    makeDarkSkyUrl = (latitude, longitude, timestamp) ->
        key = DARKSKY_API_KEY
        url = "https://api.darksky.net/forecast/#{key}/#{latitude},#{longitude}"
        if timestamp
            url += ",#{timestamp}"
        return url

    makeOpenWeatherUrl = (latitude, longitude, timestamp) ->
        key = OPENWEATHER_API_KEY
        url = "https://api.openweathermap.org/data/2.5/onecall"

        if timestamp then url += '/timemachine'
        url += "?lat=#{latitude}&lon=#{longitude}"
        if timestamp then url += "&dt=#{timestamp}"

        return url

    makeVisualCrossingUrl = (latitude, longitude, date1, date2) ->
        url = 'https://weather.visualcrossing.com/'
        url += 'VisualCrossingWebServices/rest/services/timeline/'
        url += "#{latitude},#{longitude}/#{date1}/#{date2}/"

        return url




    # Settings for each API above
    SETTINGS_MOCKDARKSKY =
        hasKey: true
        urls: "http://#{host}/json/#{MOCK_DATA_DARKSKY}.json"
    SETTINGS_DARKSKY =
        hasKey: !!DARKSKY_API_KEY
        urls: [
            makeDarkSkyUrl latitude, longitude
            makeDarkSkyUrl latitude, longitude, ts1
            makeDarkSkyUrl latitude, longitude, ts2
        ]
        axiosConfig:
            headers:
                'Accept-Encoding': 'gzip'
            params:
                exclude: 'minutely,hourly,alerts,flags'

    SETTINGS_MOCKOPENWEATHER =
        hasKey: true
        urls: "http://#{host}/json/#{MOCK_DATA_OPENWEATHER}.json"
    SETTINGS_OPENWEATHER =
        hasKey: !!OPENWEATHER_API_KEY
        urls: [
            makeOpenWeatherUrl latitude, longitude
            makeOpenWeatherUrl latitude, longitude, ts1
            makeOpenWeatherUrl latitude, longitude, ts2
        ]
        axiosConfig:
            headers:
                'Accept-Encoding': 'gzip'
            params:
                exclude: 'minutely,hourly,alerts'
                units: 'imperial'
                appid: OPENWEATHER_API_KEY

    SETTINGS_MOCKVISUALCROSSING =
        hasKey: true
        urls: "http://#{host}/json/#{MOCK_DATA_VISUALCROSSING}.json"
    SETTINGS_VISUALCROSSING =
        hasKey: !!VISUALCROSSING_API_KEY
        urls: [
            makeVisualCrossingUrl latitude, longitude, date1, date2
        ]
        axiosConfig:
            headers:
                'Accept-Encoding': 'gzip'
            params:
                include: 'obs,fcst,current'
                unitGroup: 'us'
                key: VISUALCROSSING_API_KEY

    API_SETTINGS =
        mockdarksky:        SETTINGS_MOCKDARKSKY
        darksky:            SETTINGS_DARKSKY
        mockopenweather:    SETTINGS_MOCKOPENWEATHER
        openweather:        SETTINGS_OPENWEATHER
        mockvisualcrossing: SETTINGS_MOCKVISUALCROSSING
        visualcrossing:     SETTINGS_VISUALCROSSING

    console.log vars =
        latitude: latitude
        longitude: longitude
        location:  location

    getDataFromApi = (api) ->
        if not api.hasKey then return error =
            error:
                message: 'API key not configured for API.'
                api: api

        data = null
        if typeof (url = api.urls) is 'string'
            response = await axios.get url, api.axiosConfig
            data = await response.data
        else
            promises = []
            for url in api.urls
                console.log url
                try
                    response = await axios.get url, api.axiosConfig
                    promises.push response.data
                    data = await Promise.all promises
                catch error
                    console.log "ERROR: #{error.message}"
                    return error =
                        error:
                            message: error?.message
                            url: error?.config?.url
        return data



    mdsData = await getDataFromApi API_SETTINGS.mockdarksky
    mowData = await getDataFromApi API_SETTINGS.mockopenweather
    mvcData = await getDataFromApi API_SETTINGS.mockvisualcrossing

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

        descriptions = Object.entries descriptions
        descriptions.sort (a, b) ->b[1] - a[1]

        icons = Object.entries icons
        icons.sort (a, b) ->b[1] - a[1]

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

    normalizeDarkskyData = (mdsData, source) ->
        mdsResults =
            source: source
            daily: []

        mdsResults.summary = mdsData?[0]?.daily.summary
        mdsResults.timezone = mdsData?[0]?.timezone
        mdsResults.currently = extractFields mdsData?[0]?.currently
        mdsResults.daily.push extractFields(mdsData?[2]?.daily?.data[0], true)
        mdsResults.daily.push extractFields(mdsData?[1]?.daily?.data[0], true)

        mdsData?[0]?.daily?.data?.forEach (mdsData) ->
            mdsResults.daily.push extractFields(mdsData)

        return mdsResults

    mdsNormalized = normalizeDarkskyData mdsData, 'mockdarksky'


    normalizeOpenweatherData = (mowData, source) ->
        mowResults =
            source: 'mockopenweather'
            data: mowData
            daily: []

        mowResults.summary = ''
        mowResults.timezone = mowData?[0]?.timezone
        mowResults.currently = extractFieldsOw mowData?[0]?.current

        fields = extractFieldsOwHistorical mowData?[2]
        mowResults.daily.push fields

        fields = extractFieldsOwHistorical mowData?[1]
        mowResults.daily.push fields

        for day,i in mowData?[0].daily
            mowResults.daily.push extractFieldsOw day

        return mowResults

    mowNormalized = normalizeOpenweatherData mowData, 'mockopenweather'


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

    normalizeVisualcrossingData = (mvcData, source) ->
        if mvcData.error
            return null

        mvcResults =
            source: 'mockvisualcrossing'
            daily: []

        mvcResults.summary = ''
        mvcResults.timezone = mvcData?[0]?.timezone
        mvcResults.currently = extractFieldsVc mvcData?[0]?.currentConditions

        if mvcData?[0]?.days
            for day in mvcData?[0]?.days
                fields = extractFieldsVc day
                mvcResults.daily.push fields

        return mvcResults

    mvcNormalized = normalizeVisualcrossingData mvcData, 'mockvirtualcrossing'

    payload =
        common:
            mockip:    mockIp
            ipAddress: ipAddress
            latitude:  latitude
            longitude: longitude
            location:  location
        apiData:
            mockdarksky:        mdsData
            mockopenweather:    mowData
            mockvisualcrossing: mvcData
        normalized:
            mockdarksky:        mdsNormalized
            mockopenweather:    mowNormalized
            mockvisualcrossing: mvcNormalized

    if 'darksky' in preferredApis
        data = await getDataFromApi API_SETTINGS.darksky
        payload.apiData.darksky = data
        payload.normalized.darksky = normalizeDarkskyData data, 'darksky'

    if 'openweather' in preferredApis
        data = await getDataFromApi API_SETTINGS.openweather
        payload.apiData.openweather = data
        payload.normalized.openweather = normalizeOpenweatherData data, 'openweather'

    if 'visualcrossing' in preferredApis
        data = await getDataFromApi API_SETTINGS.visualcrossing
        payload.apiData.visualcrossing = data
        payload.normalized.visualcrossing = normalizeVisualcrossingData data, 'visualcrossing'

    sortedResults = []
    for api in preferredApis
        result = payload.normalized[api]
        if result and not result.error
            sortedResults.push api

    console.log sortedResults
    payload.use = sortedResults

    return await value =  # `await` needed to force async function.
        statusCode: 200,
        body: JSON.stringify payload, null, 2

