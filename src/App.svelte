<script type='text/coffeescript'>
    import axios from 'axios'
    import dayjs from 'dayjs'

    import { onMount, tick } from 'svelte'

    import jq from 'jquery'

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

    canvas1 = null
    canvas2 = null

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


    getData = () ->
        url = '/.netlify/functions/serverless'
        response = await axios.get url
        data = response.data

    data = getData()

    celsius = (f) -> 5/9 * (f - 32)

    temperatureFormatter = (t) ->
        if mode is 'c' then t = celsius t
        Math.round t

    onMount () ->
        data = await data
        now = dayjs()

        labels = []
        precipProbability = []
        temperature = []
        temperatureMin = []
        temperatureMax = []
        apparentMin = []
        apparentMax = []


        for dailyData,i in data.daily
            jsDate = dayjs.unix dailyData.time
            if jsDate.isSame now, 'day'
                labels.push "Today"
            else
                labels.push jsDate.format 'dd-DD'

            temperature.push dailyData.temperature
            precipProbability.push dailyData.precipProbability * 100

            temperatureMin.push dailyData.temperatureMin
            temperatureMax.push dailyData.temperatureMax

            apparentMin.push    dailyData.apparentTemperatureMin
            apparentMax.push    dailyData.apparentTemperatureMax

        dataDaily =
            labels: labels
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
                borderWidth: 4
                data: dataDaily.temperatureMax
                yAxisID: 'temperature-axis'
                datalabels:
                    color: COLORS.red
            dsLows =
                label: 'Low'
                backgroundColor: COLORS.blue
                borderColor: COLORS.blue
                borderWidth: 4
                data: dataDaily.temperatureMin
                yAxisID: 'temperature-axis'
                datalabels:
                    color: COLORS.blue
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
                backgroundColor: COLORS.lightblue
                borderColor: COLORS.lightblue
                data: dataDaily.precipProbability
                yAxisID: 'percent-axis'
                datalabels:
                    display: false
                    color: COLORS.gray
                    anchor: 'start'
                    formatter: (n) ->
                        Math.round(n) + '%'
        ]

        jq('.toggle-fc').click (e) ->
            e.preventDefault()

            mode = if mode is 'f' then 'c' else 'f'

            chart1.update()
            chart2.update()

        jq('.toggle-simple').click (e) ->
            e.preventDefault()
            showApparentTemps = !showApparentTemps

            dsHighsApparent.showLine = showApparentTemps
            dsLowsApparent.showLine  = showApparentTemps

            dsCurrentlyApparent.pointRadius = if showApparentTemps then 6 else 0

            chart1.update()
            chart2.update()



        list = (day.icon for day in data.daily)

        $template = jq('#chart .template')

        for icon,i in list.slice(0,5)
            [div] = $template.clone()
                             .addClass("day-#{i}")
                             .attr 'title', data.daily[i].summary

            img = "https://darksky.net/images/weather-icons/#{list[i]}.png"

            jq(div).insertBefore($template)
            jq(div).find('div.icon').append("<img src=#{img}>")
            jq("#chart .day-#{i} .label").html labels[i]

        $template.remove()

        $template = jq('#wide-chart .template')

        for icon,i in list
            [div] = $template.clone()
                             .addClass("day-#{i}")
                             .attr 'title', data.daily[i].summary

            img = "https://darksky.net/images/weather-icons/#{list[i]}.png"

            jq(div).insertBefore($template)
            jq(div).find('div.icon').append("<img src=#{img}>")
            jq("#wide-chart .day-#{i} .label").html labels[i]

        $template.remove()

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
        chart1 = makeChartJs canvas1, dataDaily.labels[...5], datasetsF
        chart2 = makeChartJs canvas2, dataDaily.labels,       datasetsF, 3, true
</script>

<template lang=pug>
main
    +await('data then data')
        .view.portrait
            div#currently.flex-top.flex-vertical(title='{data.summary}')
                #links-container.flex-top.flex-container
                    #links
                        a(href="https://darksky.net/forecast/{data.latitude},{data.longitude}/") Full DarkSky Forecast
                .forecast.flex-bottom.flex-vertical
                    div.flex-item.flex-container.center
                        h1: span.location {data.location}
                    div.icon-and-temperature.flex-item.flex-container.center
                        div.icon.toggle-fc
                            img(src='{ICON_URL_BASE}{data.currently.icon}.png')
                        div.temperature.toggle-fc {@html displayTemperature}
                    div.flex-item.flex-container.center.toggle-fc
                        span {data.currently.summary}.
                        span Feels like&nbsp;{@html displayTemperatureApparent}
                    div.flex-item.flex-container.center
                        hr

            #chart.flex-bottom
                div#daily.flex-container.space-between.toggle-simple
                    div.template
                        div.icon
                        div.label
                div.chart: canvas(bind:this='{canvas1}')

        .view.landscape
            #wide-chart
                h1.center: span.toggle-fc.location {data.location}
                div.center: span.toggle-fc {data.summary}
                div#daily.flex-container.space-between.toggle-simple
                    div.template
                        div.icon
                        div.label
                div.chart: canvas(bind:this='{canvas2}')

</template>

<style>
    *:not(input):not(textarea) {
        user-select: none;
    }
    .chart {
        padding: 15px;
    }
    .center {
        text-align: center;
    }
</style>
