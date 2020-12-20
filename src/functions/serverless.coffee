import axios from 'axios'

exports.handler = (event, context) ->
    console.log """\ncontext: #{JSON.stringify context, null, 2},
                   event: #{JSON.stringify event, null, 2}\n"""

    ipAddress = event.headers['client-ip']


    if ipAddress is '::1'
        ipAddress = '110.47.160.191'
        mockIp = true


    url = "http://ip-api.com/json/#{ipAddress}"

    response = await axios.get url
    data = response.data
    console.log data

    payload =
        ipAddres: ipAddress
        latitude: data.lat
        longitude: data.lon
        location: data.city or data.regionName or data.country

    if mockIp
        payload.mockIp = true

    return await value =  # `await` needed to force async function.
        statusCode: 200,
        body: JSON.stringify payload, null, 2

