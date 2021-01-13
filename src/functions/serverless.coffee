import axios from 'axios'

exports.handler = (event, context) ->
    # console.log """\ncontext: #{JSON.stringify context, null, 2}, event: #{JSON.stringify event, null, 2}\n"""

    MOCK_IP_ADDRESS = process.env.MOCK_IP_ADDRESS
    MOCK_DATA       = process.env.MOCK_DATA

    console.log o =
        MOCK_DATA: MOCK_DATA
        MOCK_IP_ADDRESS: MOCK_IP_ADDRESS

    host = event.headers['host']

    ipAddress = event.headers['client-ip']

    if (ipAddress is '::1') or !!MOCK_IP_ADDRESS
        ipAddress = MOCK_IP_ADDRESS
        if not !!ipAddress then ipAddress = '110.47.160.191'
        mockIp = true

    location = event.queryStringParameters.l
    console.log ['location:', location]
    if !!location  # Ensure location non-empty string.
        key = process.env.OPENWEATHER_API_KEY
        url = "http://api.openweathermap.org/geo/1.0/direct?q=#{location}&limit=5&appid=#{key}"

        response = await axios.get url
        data = response.data

        console.log data

    if place = data?[0]
        latitude  = place.lat
        longitude = place.lon
        location = "#{place.name} (#{place.country})"
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

    key = process.env.DARK_SKY_API_KEY
    # console.log key

    SECONDS_PER_DAY = 24*60*60

    unixEpoch = Math.floor(Date.now() / 1000)
    tsMinusOneDay = unixEpoch - SECONDS_PER_DAY
    tsMinusTwoDays = unixEpoch - SECONDS_PER_DAY*2

    url0 = "https://api.darksky.net/forecast/#{key}/#{latitude},#{longitude}"
    url1 = "https://api.darksky.net/forecast/#{key}/#{latitude},#{longitude},#{tsMinusOneDay}"
    url2 = "https://api.darksky.net/forecast/#{key}/#{latitude},#{longitude},#{tsMinusTwoDays}"

    # console.log url1

    callDarkSkyApi = (url) ->
        response = await axios.get url, config =
            headers:
                'Accept-Encoding': 'gzip'
            params:
                exclude: 'minutely,hourly,alerts,flags'

        data = await response.data


    if !!MOCK_DATA
        response = await axios.get "http://#{host}/json/#{MOCK_DATA}.json"
        data = await response.data
    else
        promises = []
        promises.push callDarkSkyApi(url0)
        promises.push callDarkSkyApi(url1)
        promises.push callDarkSkyApi(url2)
        data = await Promise.all promises
        # console.log  JSON.stringify(data)


    extractFields = (data) ->
        object =
            time:    data?.time
            summary: data?.summary
            icon:    data?.icon

            precipProbability: data?.precipProbability

            temperature:         data?.temperature
            apparentTemperature: data?.apparentTemperature

            temperatureMin: data?.temperatureMin
            temperatureMax: data?.temperatureMax

            apparentTemperatureMin: data?.apparentTemperatureMin
            apparentTemperatureMax: data?.apparentTemperatureMax

    results =
        ipAddress: ipAddress
        latitude: latitude
        longitude: longitude
        location: location

        currently: null
        daily: []

    if mockIp
        results.mockIp = true

    if !!MOCK_DATA
        results.location += ' (mock data)'

    results.summary = data[0].daily.summary
    results.currently = extractFields data[0].currently
    results.daily.push extractFields data[2].daily.data[0]
    results.daily.push extractFields data[1].daily.data[0]

    data[0].daily.data.forEach (data) ->
        results.daily.push extractFields(data)

    # console.log results

    return await value =  # `await` needed to force async function.
        statusCode: 200,
        body: JSON.stringify results, null, 2

