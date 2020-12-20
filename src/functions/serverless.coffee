exports.handler = (event, context) ->
    # your server-side functionality
    console.log "\ncontext: #{JSON.stringify context, null, 2},\nevent: #{JSON.stringify event, null, 2}\n"
    ipAddress = event.headers['client-ip']

    return value =
        statusCode: 200,
        body: "Your IP address: #{ipAddress}"
