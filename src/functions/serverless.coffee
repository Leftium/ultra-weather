exports.handler = (event, context, callback) ->
    console.log "\ncontext: #{JSON.stringify context, null, 2},\nevent: #{JSON.stringify event, null, 2}\n"
    ipAddress = event.headers['client-ip']

    callback null, value =
        statusCode: 200,
        body: "Your IP address: #{ipAddress}"

