<script type='text/coffeescript'>
    import axios from 'axios'

    import dayjs from 'dayjs'
    import utc from 'dayjs/plugin/utc'
    import timezone  from 'dayjs/plugin/timezone'

    dayjs.extend utc
    dayjs.extend timezone

    import { onMount } from 'svelte'

    import Chart from 'chart.js'
    import ChartDataLabels from 'chartjs-plugin-datalabels'

    showErrorWarning    = false
    showMockdataWarning = false

    COLORS =
        red:   '#dc322f'
        red80: '#e35b59'
        red60: '#ea8482'
        red40: '#f1adac'

        blue:   '#268bd2'
        blue80: '#51a2db'
        blue60: '#7db9e4'
        blue40: '#a8d1ed'

        purple:   '#6c71c4'
        purple40: '#c4c6e7'

        cyan:   '#00afaf'
        cyan80: '#33bfbf'
        cyan40: '#99dfdf'
        cyan20: '#ccefef'

        water:   '#c3e3f8'
        water60: '#E1F4FF'


    canvas1 = null
    canvas2 = null

    chart1 = null
    chart2 = null

    mode = 'f'  # F/C temperature mode.

    showApparentTemps = false

    ## Make these references to datasets global so we can easily modify them.
    dsHighsApparent = null
    dsLowsApparent = null
    dsCurrentlyApparent = null

    temperature = 0
    temperatureApparent = 0
    displayTemperature = ''
    displayTemperatureApparent = ''
    ```$: {```  ## Start Svelte reactive block.

    if mode is 'c'
        convertedTemperature = celsius temperature
        convertedTempApparent = celsius temperatureApparent
    else
        convertedTemperature = temperature
        convertedTempApparent = temperatureApparent

    unit = "&deg;#{mode.toUpperCase()}"

    displayTemperature         = "#{Math.round(convertedTemperature) }#{unit}"
    displayTemperatureApparent = "#{Math.round(convertedTempApparent)}#{unit}"
    ```}```  ## End reactive block.

    now = dayjs()

    celsius = (f) -> 5/9 * (f - 32)

    temperatureFormatter = (t) ->
        if mode is 'c' then t = celsius t
        Math.round t

    ensureToolTipClosed = (e) ->
        if not e.target.$chartjs
            canvas1.dispatchEvent(new MouseEvent 'mouseout')
            canvas2.dispatchEvent(new MouseEvent 'mouseout')

    toggleUnits = (e) ->
        e.preventDefault()

        mode = if mode is 'f' then 'c' else 'f'

        chart1.update()
        chart2.update()

    toggleSimple = (e) ->
        e.preventDefault()
        showApparentTemps = !showApparentTemps

        dsHighsApparent.showLine = showApparentTemps
        dsLowsApparent.showLine  = showApparentTemps

        dsCurrentlyApparent.pointRadius = if showApparentTemps then 6 else 0

        chart1.update()
        chart2.update()

    getData = () ->
        console.log location

        loc = location.pathname[1..]  # Trim first slash

        queryString = location.search
        queryParams = new URLSearchParams queryString
        queryParams.set 'l', loc

        url = "/.netlify/functions/serverless/?#{queryParams.toString()}"

        response = await axios.get url
        data = await response.data

        window.data = data
        console.log data

        for k,v of data.apiData
            if v.error
                showErrorWarning = true
                console.error "ERROR getting data for #{k}:", v

        # Construct object with weather data to render:
        use = data.use[0]

        if /mock/.test use
            showMockdataWarning = true
            #preferredApis = queryString.get 'api'
            #if not /mock/.test(preferredApis) and /(^|,)m/.test(preferredApis)


        payload = Object.assign {}, data.common, data.normalized[use]
        payload.labels = []
        if payload.daily
            for day in payload.daily
                jsDate = dayjs.unix(day.time).tz(payload.timezone)
                if jsDate.isSame now, 'day'
                    payload.labels.push "Today"
                else
                    payload.labels.push jsDate.format 'dd-DD'

        window.payload = payload
        console.log payload
        return payload



    data = getData()

    makeColorScript = (color1, color2) ->
        (context) ->
            index = context.dataIndex
            if index < 2
                color1
            else
                color2

    # Based on:
    # https://github.com/chartjs/Chart.js/issues/4302#issuecomment-304847311
    makeGradient = (color1, color2) ->
        (context) ->
            chart = context.chart
            chartArea = chart.chartArea
            xaxis = chart.scales['x-axis-0']
            ctx = chart.ctx

            numSegments = chart.data.labels.length - 1

            if (!chartArea)
                # This case happens on initial chart load
                return null

            left = chart.chartArea.left
            right = chart.chartArea.right

            gradient = ctx.createLinearGradient left, 0, right, 0

            colorStop = 2/numSegments

            if colorStop > 0 and colorStop < 1
                gradient.addColorStop colorStop, color1
                gradient.addColorStop colorStop, color2

            gradient

    onMount () ->
        data = await data

        loader = document.getElementById 'loader'
        loader.remove()

        precipProbability = []
        temperature = []
        temperatureMin = []
        temperatureMax = []
        apparentMin = []
        apparentMax = []


        for day in data.daily
            temperature.push day.temperature
            precipProbability.push day.precipProbability * 100

            temperatureMin.push day.temperatureMin
            temperatureMax.push day.temperatureMax

            apparentMin.push    day.apparentTemperatureMin
            apparentMax.push    day.apparentTemperatureMax

        dataDaily =
            labels: data.labels
            precipProbability: precipProbability
            temperatureMin:    temperatureMin
            temperatureMax:    temperatureMax
            apparentMin:       apparentMin
            apparentMax:       apparentMax


        temperature =         data.currently.temperature
        temperatureApparent = data.currently.apparentTemperature

        Chart.defaults.global.elements.line.tension = 0
        Chart.defaults.global.elements.line.fill = false

        datasetsF = [
            dsCurrently =
                label: 'Temperature'
                backgroundColor: COLORS.purple
                borderColor: COLORS.purple
                pointRadius: 6
                data:[NaN, NaN, temperature]
                yAxisID: 'temperature-axis'
                datalabels:
                    display: false
                    color: COLORS.purple
            dsCurrentlyApparent =
                label: 'Temperature (Apparent)'
                showLine: false
                backgroundColor: COLORS.purple40
                borderColor: COLORS.purple40
                pointRadius: 0
                data: [NaN, NaN, temperatureApparent]
                yAxisID: 'temperature-axis'
                datalabels:
                    display: false
                    color: COLORS.purple40
            dsHighs =
                label: 'High'
                backgroundColor: makeGradient COLORS.red80, COLORS.red
                borderColor: makeGradient COLORS.red80, COLORS.red
                borderWidth: 4
                pointBackgroundColor: makeColorScript COLORS.red80, COLORS.red
                pointBorderColor: makeColorScript COLORS.red80, COLORS.red
                pointBorderWidth: 0
                data: dataDaily.temperatureMax
                yAxisID: 'temperature-axis'
                datalabels:
                    color: makeColorScript COLORS.red80, COLORS.red
            dsLows =
                label: 'Low'
                backgroundColor:makeGradient COLORS.blue80, COLORS.blue
                borderColor: makeGradient COLORS.blue80, COLORS.blue
                borderWidth: 4
                pointBackgroundColor: makeColorScript COLORS.blue80, COLORS.blue
                pointBorderColor: makeColorScript COLORS.blue80, COLORS.blue
                pointBorderWidth: 0
                data: dataDaily.temperatureMin
                yAxisID: 'temperature-axis'
                datalabels:
                    color: makeColorScript COLORS.blue80, COLORS.blue
                    align: 'start'
                    display: 'true'
            dsHighsApparent =
                label: 'High (Apparent)'
                showLine: false
                backgroundColor: makeGradient COLORS.red40, COLORS.red60
                borderColor: makeGradient COLORS.red40, COLORS.red60
                borderWidth: 4
                pointRadius: 0
                data: dataDaily.apparentMax
                yAxisID: 'temperature-axis'
                datalabels:
                    display: false
            dsLowsApparent =
                label: 'Low  (Apparent)'
                showLine: false
                backgroundColor: makeGradient COLORS.blue40, COLORS.blue60
                borderColor: makeGradient COLORS.blue40, COLORS.blue60
                borderWidth: 4
                pointRadius: 0
                data: dataDaily.apparentMin
                yAxisID: 'temperature-axis'
                datalabels:
                    display: false
            dsPrec =
                type: 'bar'
                label: 'Prec. %'
                backgroundColor: makeColorScript COLORS.water60, COLORS.water
                borderColor: makeColorScript COLORS.water60, COLORS.water
                data: dataDaily.precipProbability
                yAxisID: 'percent-axis'
                datalabels:
                    display: false
                    anchor: 'start'
                    formatter: (n) ->
                        Math.round(n) + '%'
        ]

        toolTipsLabelCallback = (tooltipItem, data) ->
            yAxisID = data.datasets[tooltipItem.datasetIndex].yAxisID
            label = data.datasets[tooltipItem.datasetIndex].label or ''
            value = Number.parseFloat tooltipItem.value, 10

            if yAxisID is 'temperature-axis' and mode is 'c'
                value = celsius(value)

            if yAxisID is 'percent-axis'
                return if tooltipItem.index < 2
                    value = "#{value.toFixed 1}".padStart 6, ' '
                    "#{value}: mm of precipitation"
                else
                    value = "#{Math.round value}".padStart 6, ' '
                    "#{value}% Chance of precipitation"
            else
                value = "#{value.toFixed(1)}".padStart 6, ' '
                return "#{value}: #{label}"

        toolTipsTitleCallback = (tooltipItem, d) ->
            data.daily[tooltipItem[0].index].summary

        Chart.Tooltip.positioners.top = (elements, eventPosition) ->
            point = Chart.Tooltip.positioners.nearest elements, eventPosition

            result =
                x: point.x
                y: 0


        makeChartJs =  (canvas, labels, datasets, aspectRatio=2, maintainAspectRatio=true)  ->
            ctx = canvas.getContext('2d')

            chart = new Chart ctx, options =
                # The type of chart we want to create
                type: 'line'
                # The data for our dataset
                data:
                    labels: labels
                    datasets: datasets
                # Configuration options go here
                options:
                    tooltips:
                        mode: 'index'
                        position: 'top'
                        intersect: false
                        bodyFontFamily: 'Lucida Console, Courier, monospace'
                        callbacks:
                            label: toolTipsLabelCallback
                            title: toolTipsTitleCallback
                    animation: false
                    responsive: true
                    aspectRatio: aspectRatio
                    maintainAspectRatio: maintainAspectRatio
                    layout:
                        padding: 15
                    legend:
                        position: 'bottom'
                        display: false
                    plugins:
                        datalabels:
                            display: 'auto'
                            align: 'end'
                            formatter: temperatureFormatter
                            padding: 1
                            font:
                                weight: '900'
                    scales:
                        xAxes: [
                            axis =
                                display: false
                                position: 'top'
                        ]
                        yAxes: [
                            axis =
                                id: 'temperature-axis'
                                display: false
                                type: 'linear'
                                position: 'left'
                            axis =
                                id: 'percent-axis'
                                display: false
                                type: 'linear'
                                position: 'right'
                                ticks:
                                    min: 0
                                    max: 100
                                gridLines:
                                    drawOnChartArea: false
                        ]
        chart1 = makeChartJs canvas1, data.labels[...5], datasetsF
        chart2 = makeChartJs canvas2, data.labels,       datasetsF, 3, true

        return () ->
            chart1.destroy()
            chart2.destroy()
</script>

<template lang=pug>
main(on:click='{ensureToolTipClosed}' on:touchstart='{ensureToolTipClosed}')
    +await('data then data')
        .view.portrait
            div#currently.flex-top.flex-vertical(title='{data.summary}')
                .forecast.flex-bottom.flex-vertical
                    div.flex-item.flex-container.center
                        h1.center: span.location {data.location}
                    div.icon-and-temperature.flex-item.flex-container.center
                        div.icon(on:click='{toggleUnits}')
                            img(alt='{data.currently.icon}' src='img/{data.currently.icon}.png')
                        div.temperature(on:click='{toggleUnits}') {@html displayTemperature}
                    div.flex-item.flex-container.center.margin-bottom(on:click='{toggleUnits}')
                        span {data.currently.summary}.&nbsp;
                        span Feels like&nbsp;{@html displayTemperatureApparent}

            #chart.flex-bottom
                div#daily.flex-container.space-between(on:click='{toggleSimple}')
                    +each('data.daily.slice(0,5) as day,i')
                        div(class='day-{i}' title='{data.daily[i].summary}')
                            div.icon
                                img(alt='{day.icon}' src='img/{day.icon}.png')
                            div.label {data.labels[i]}
                div.flex-item.flex-container.center: hr
                div.chart: canvas(bind:this='{canvas1}')
                #links-container.flex-top.flex-container
                    #links
                        a(href="https://darksky.net/forecast/{data.latitude},{data.longitude}/") Full DarkSky Forecast
                div
                    div.center &#x1f6c8; Showing mocked data. To see live data, check API keys and quotas.
                    div.center &#x26A0;&#xFE0F; Errors getting data. More details in developer console.


        .view.landscape
            #wide-chart
                h1.center: span.location(on:click='{toggleUnits}') {data.location}
                div.center.margin-bottom: span(on:click='{toggleUnits}') {data.summary}
                div#daily.flex-container.space-between(on:click='{toggleSimple}')
                    +each('data.daily as day,i')
                        div(class='day-{i}' title='{data.daily[i].summary}')
                            div.icon
                                img(alt='{day.icon}' src='img/{day.icon}.png')
                            div.label {data.labels[i]}
                div.flex-item.flex-container.center: hr
                div.chart: canvas(bind:this='{canvas2}')

</template>

<style>
    main {
        height: 100%;
    }

    *:not(input):not(textarea) {
        user-select: none;
    }

    @media (max-aspect-ratio: 12/10 ) {
        .portrait { display: block; }
        .landscape { display: none; }
    }
    @media (min-aspect-ratio: 12/10) {
        .portrait { display: none; }
        .landscape { display: block; }
    }

    h1 {
        margin: 0;
    }

    .flex-container {
        padding: 0;
        margin: 0 8px;
        list-style: none;

        -ms-box-orient: horizontal;
        display: flex;
    }

    .flex-vertical {
        display: flex;
        flex-direction: column;
    }

    .flex-item {
        flex-basis: auto;
    }

    .flex-top {
        flex-basis: auto;

    }
    .flex-bottom {
        flex-grow: 1;
    }

    .center {
        -webkit-justify-content: center;
        justify-content: center;
    }

    .space-between {
        -webkit-justify-content: space-between;
        justify-content: space-between;
    }

    hr {
        border-top: 1px solid #eee8d5;
        width: 100%;
    }

    .margin-bottom {
        margin-bottom: 20px;
    }

    .chart {
        padding: 15px;
    }
    .center {
        text-align: center;
    }

    #currently .temperature {
      display: inline-block;
      font-size: 60px;
    }

    /* Historical weather */
    :global(.day-0 .icon),
    :global(.day-1 .icon) {
        opacity: .22;
    }

    /* Today */
    :global(.day-2) {
        font-weight: bold;
    }

    #links {
        margin: auto;
    }

    .location {
        margin: 15px;
    }

    .view {
        position: fixed;
        top: 0; bottom: 0;
        left: 0; right: 0;
        padding: 8px;
    }

    :global(#currently div.icon) {
        width: 64px;
        height: 64px;
        display: inline-block;
    }

    :global(div.icon) {
        margin-bottom: 0px;
        min-width: 40px;
    }

    :global(.icon) {
        width: 40px;
        height: 40px;
    }

    :global(div.icon img),
    :global(.icon img) {
        width: 100%;
        object-fit: contain;
    }
</style>
