exports.handler = (event, context) ->
    console.log "\ncontext: #{JSON.stringify context, null, 2},\nevent: #{JSON.stringify event, null, 2}\n"

    ipAddress = event.headers['client-ip']

    if ipAddress is '::1'
        ipAddress = '110.47.160.191'

    return await value =
        statusCode: 200,
        body: "Your IP address: #{ipAddress}"

