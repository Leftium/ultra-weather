<script type='text/coffeescript'>
    import axios from 'axios'
    import dayjs from 'dayjs'

    import { onMount, tick } from 'svelte'

    import jq from 'jquery'
    import Chartist from 'chartist'
    import ctPointLabels from 'chartist-plugin-pointlabels'

    initData = () ->
        makeSeries = (name) ->
            value =
                name: name
                data: []

        value =
            labels: []
            series: [
                makeSeries 'apparent-high'
                makeSeries 'apparent-low'
                makeSeries 'current-apparent'
                makeSeries 'current'
                makeSeries 'high'
                makeSeries 'low'
            ]

    getData = () ->
        url = '/.netlify/functions/serverless'
        response = await axios.get url
        data = response.data

    cdata = initData()
    fdata = initData()

    data = getData()

    sliceData = (data, length) ->
        data.labels = data.labels.slice 0, length
        data.series.forEach (series, i) ->
            data.series[i].data = data.series[i].data.slice 0, length
        data

    celsius = (f) -> 5/9 * (f - 32)

    temperatureDiv = (f, div) ->
        c = celsius f
        div.html jq('<span>').addClass('fahrenheit').html("#{Math.round f}&deg;F")
        div.append jq('<span>').addClass('celsius').html("#{Math.round c}&deg;C")

    onMount () ->
        data = await data
        console.log data
        window.data = data

        await tick()

        data.daily.forEach (row, i) ->
            #TODO: better check for today
            if i is 2
                fdata.labels.push ('<b>Today</b>')
                cdata.series[2].data[i] = celsius data.currently.apparentTemperature
                fdata.series[2].data[i] =         data.currently.apparentTemperature

                cdata.series[3].data[i] = celsius data.currently.temperature
                fdata.series[3].data[i] =         data.currently.temperature
            else
                fdata.labels.push (dayjs.unix(row.time).format 'dd-DD')

            cdata.series[0].data.push celsius row.apparentTemperatureMax
            cdata.series[1].data.push celsius row.apparentTemperatureMin
            cdata.series[4].data.push celsius row.temperatureMax
            cdata.series[5].data.push celsius row.temperatureMin

            fdata.series[0].data.push row.apparentTemperatureMax
            fdata.series[1].data.push row.apparentTemperatureMin
            fdata.series[4].data.push row.temperatureMax
            fdata.series[5].data.push row.temperatureMin

        $currently = jq('#currently').attr 'title', data.summary

        temperatureDiv data.currently.temperature, $currently.find('.temperature')
        temperatureDiv data.currently.apparentTemperature, $currently.find('.apparentTemperature')
        $currently.find('.summary').html data.currently.summary

        img = "https://darksky.net/images/weather-icons/#{data.currently.icon}.png"
        $currently.find('div.icon').append("<img src=#{img}>")

        jq('#summary').html data.summary

        jq('.celsius').addClass 'hidden'

        jq('.celsius').click (e) ->
            e.preventDefault()
            jq('.fahrenheit').removeClass 'hidden'
            jq('.celsius').addClass 'hidden'
            chart.update sliceData(jq.extend(true, {}, fdata), 5)
            wideChart.update fdata

        jq('.fahrenheit').click (e) ->
            e.preventDefault()
            jq('.celsius').removeClass 'hidden'
            jq('.fahrenheit').addClass 'hidden'
            chart.update sliceData(jq.extend(true, {}, cdata), 5)
            wideChart.update cdata


        list = (day.icon for day in data.daily)
        console.log list

        $template = jq('#chart .template')

        for icon,i in list.slice(0,5)
            [div] = $template.clone()
                             .addClass("day-#{i}")
                             .attr 'title', data.daily[i].summary

            img = "https://darksky.net/images/weather-icons/#{list[i]}.png"

            jq(div).insertBefore($template)
            jq(div).find('div.icon').append("<img src=#{img}>")
            jq("#chart .day-#{i} .label").html fdata.labels[i]

        $template.remove()

        $template = jq('#wide-chart .template')

        for icon,i in list
            [div] = $template.clone()
                             .addClass("day-#{i}")
                             .attr 'title', data.daily[i].summary

            img = "https://darksky.net/images/weather-icons/#{list[i]}.png"

            jq(div).insertBefore($template)
            jq(div).find('div.icon').append("<img src=#{img}>")
            jq("#wide-chart .day-#{i} .label").html fdata.labels[i]

        $template.remove()

        makeChart = (id, data) ->
            new Chartist.Line id, data,
                lineSmooth: Chartist.Interpolation.none()
                # low: 50
                axisY:
                    showLabel: false
                axisX:
                    showLabel: false

                fullWidth: true
                chartPadding:
                    top:    15,
                    right:  20,
                    bottom: 15,
                    left:  -15
                plugins: [
                    ctPointLabels options =
                        textAnchor: 'middle'
                        labelOffset: { x: 0, y: -10 }
                        labelInterpolationFnc: (v) -> Math.round v
                ]


        chart = makeChart '#chart .chartist', sliceData(jq.extend(true, {}, fdata), 5)
        wideChart = makeChart '#wide-chart .chartist', fdata
</script>

<template lang=pug>
main
    // p: a(href=".netlify/functions/serverless") serverless
    // pre {JSON.stringify(fdata, null, 4)}

    +await('data then data')
        .view.portrait
            div#currently.flex-top.flex-vertical
                #links-container.flex-top.flex-container
                    #links
                        a(href="https://darksky.net/forecast/{data.latitude},{data.longitude}/") Full DarkSky Forecast
                .forecast.flex-bottom.flex-vertical
                    div.flex-item.flex-container.center
                        h1.location {data.location || 'loading...'}
                    div.icon-and-temperature.flex-item.flex-container.center
                        div.icon
                        div.temperature
                    div.flex-item.flex-container.center
                        span.summary
                        span . Feels like&nbsp;
                        span.apparentTemperature
                    div.flex-item.flex-container.center
                        hr

            #chart.flex-bottom
                div#daily.flex-container.space-between
                    div.template
                        div.icon
                        div.label
                div.chartist.ct-chart.ct-golden-section

        .view.landscape
            #wide-chart
                h1.location {data.location || 'loading...'}
                div#summary
                div#daily.flex-container.space-between
                    div.template
                        div.icon
                        div.label
                div.chartist.ct-major-twelfth

</template>

<style>

</style>
