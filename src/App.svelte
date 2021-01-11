<script type='text/coffeescript'>
    import axios from 'axios'
    import dayjs from 'dayjs'

    import { onMount } from 'svelte'

    import Chart from 'chart.js'
    import ChartDataLabels from 'chartjs-plugin-datalabels'

    ICON_URL_BASE = 'https://darksky.net/images/weather-icons/'

    COLORS =
        red: '#dc322f'
        lightred: '#dc322f44'
        blue: '#268bd2'
        lightblue: '#268bd244'
        purple: '#6c71c4'
        lightpurple: '#6c71c444'
        gray: '#586e75'
        lightcyan: '#00afaf44'
        water: '#1ca3ec44'

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
        url = '/.netlify/functions/serverless'
        response = await axios.get url
        data = await response.data

        data.labels = []

        for day in data.daily
            jsDate = dayjs.unix day.time
            if jsDate.isSame now, 'day'
                data.labels.push "Today"
            else
                data.labels.push jsDate.format 'dd-DD'

        return data
    data = getData()

    makeColorScript = (color1, color2) ->
        (context) ->
            index = context.dataIndex
            if index < 2
                color1
            else
                color2

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
                backgroundColor: COLORS.lightpurple
                borderColor: COLORS.lightpurple
                pointRadius: 0
                data: [NaN, NaN, temperatureApparent]
                yAxisID: 'temperature-axis'
                datalabels:
                    display: false
                    color: COLORS.lightpurple
            dsHighs =
                label: 'High'
                backgroundColor: COLORS.red
                borderColor: COLORS.red
                pointBorderColor: makeColorScript COLORS.lightred, COLORS.red
                borderWidth: 4
                data: dataDaily.temperatureMax
                yAxisID: 'temperature-axis'
                datalabels:
                    color: makeColorScript COLORS.lightred, COLORS.red
            dsLows =
                label: 'Low'
                backgroundColor: COLORS.blue
                borderColor: COLORS.blue
                pointBorderColor: makeColorScript COLORS.lightblue, COLORS.blue
                borderWidth: 4
                data: dataDaily.temperatureMin
                yAxisID: 'temperature-axis'
                datalabels:
                    color: makeColorScript COLORS.lightblue, COLORS.blue
                    align: 'start'
                    display: 'true'
            dsHighsApparent =
                label: 'High (Apparent)'
                showLine: false
                backgroundColor: COLORS.lightred
                borderColor: COLORS.lightred
                borderWidth: 4
                pointRadius: 0
                data: dataDaily.apparentMax
                yAxisID: 'temperature-axis'
                datalabels:
                    display: false
            dsLowsApparent =
                label: 'Low  (Apparent)'
                showLine: false
                backgroundColor: COLORS.lightblue
                borderColor: COLORS.lightblue
                borderWidth: 4
                pointRadius: 0
                data: dataDaily.apparentMin
                yAxisID: 'temperature-axis'
                datalabels:
                    display: false
            dsPrec =
                type: 'bar'
                label: 'Prec. %'
                backgroundColor: COLORS.water
                borderColor: COLORS.water
                data: dataDaily.precipProbability
                yAxisID: 'percent-axis'
                datalabels:
                    display: false
                    color: COLORS.gray
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
                value = "#{Math.round value}".padStart 6, ' '
                return "#{value}% Chance of precipitation"
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
                            img(src='{ICON_URL_BASE}{data.currently.icon}.png')
                        div.temperature(on:click='{toggleUnits}') {@html displayTemperature}
                    div.flex-item.flex-container.center.margin-bottom(on:click='{toggleUnits}')
                        span {data.currently.summary}.&nbsp;
                        span Feels like&nbsp;{@html displayTemperatureApparent}

            #chart.flex-bottom
                div#daily.flex-container.space-between(on:click='{toggleSimple}')
                    +each('data.daily.slice(0,5) as day,i')
                        div(class='day-{i}' title='{data.daily[i].summary}')
                            div.icon: img(src='https://darksky.net/images/weather-icons/{day.icon}.png')
                            div.label {data.labels[i]}
                div.flex-item.flex-container.center: hr
                div.chart: canvas(bind:this='{canvas1}')
                #links-container.flex-top.flex-container
                    #links
                        a(href="https://darksky.net/forecast/{data.latitude},{data.longitude}/") Full DarkSky Forecast

        .view.landscape
            #wide-chart
                h1.center: span.location(on:click='{toggleUnits}') {data.location}
                div.center.margin-bottom: span(on:click='{toggleUnits}') {data.summary}
                div#daily.flex-container.space-between(on:click='{toggleSimple}')
                    +each('data.daily as day,i')
                        div(class='day-{i}' title='{data.daily[i].summary}')
                            div.icon: img(src='https://darksky.net/images/weather-icons/{day.icon}.png')
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
