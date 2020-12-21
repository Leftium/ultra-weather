require('dotenv').config()

import axios from 'axios'

exports.handler = (event, context) ->
    # console.log """\ncontext: #{JSON.stringify context, null, 2},
    #               event: #{JSON.stringify event, null, 2}\n"""

    ipAddress = event.headers['client-ip']
    host = event.headers['host']


    if ipAddress is '::1'
        ipAddress = '110.47.160.191'
        mockIp = true


    url = "http://ip-api.com/json/#{ipAddress}"

    response = await axios.get url
    data = response.data
    # console.log data

    latitude = data.lat
    longitude = data.lon
    location = data.city or data.regionName or data.country


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


    if USE_MOCK_DATA = mockIp
        response = await axios.get "http://#{host}/json/mock-data.json"
        data = await response.data
    else
        promises = []
        promises.push callDarkSkyApi(url0)
        promises.push callDarkSkyApi(url1)
        promises.push callDarkSkyApi(url2)
        data = await Promise.all promises


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

    results.summary = data[0].daily.summary
    results.currently = extractFields data[0].currently
    results.daily.push extractFields data[2].daily.data[0]
    results.daily.push extractFields data[1].daily.data[0]

    data[0].daily.data.forEach (data) ->
        results.daily.push extractFields(data)

    return await value =  # `await` needed to force async function.
        statusCode: 200,
        body: JSON.stringify results, null, 2

