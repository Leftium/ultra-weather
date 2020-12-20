<script type='text/coffeescript'>
    import axios from 'axios'
    import dayjs from 'dayjs'

    import { onMount } from 'svelte'

    import jq from 'jquery'
    import Chartist from 'chartist'
    import ctPointLabels from 'chartist-plugin-pointlabels'

    data = {}

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
                makeSeries 'high'
                makeSeries 'low'
                makeSeries 'current.apparent'
                makeSeries 'current'
            ]

    sliceData = (data, length) ->
        data.labels = data.labels.slice 0, length
        data.series.forEach (series, i) ->
            data.series[i].data = data.series[i].data.slice 0, length
        data

    cdata = initData()
    fdata = initData()

    celsius = (f) -> 5/9 * (f - 32)

    temperatureDiv = (f, div) ->
        c = celsius f
        div.html jq('<span>').addClass('fahrenheit').html("#{Math.round f}&deg;F")
        div.append jq('<span>').addClass('celsius').html("#{Math.round c}&deg;C")

    onMount () ->
        url = '/.netlify/functions/serverless'
        response = await axios.get url
        data = response.data
        console.log data

        data.daily.forEach (row, i) ->
            #TODO: better check for today
            if i is 2
                fdata.labels.push ('<b>Today</b>')
                cdata.series[4].data[i] = celsius data.currently.apparentTemperature
                fdata.series[4].data[i] =         data.currently.apparentTemperature

                cdata.series[5].data[i] = celsius data.currently.temperature
                fdata.series[5].data[i] =         data.currently.temperature
            else
                fdata.labels.push (dayjs.unix(row.time).format 'dd-DD')

            cdata.series[0].data.push celsius row.apparentTemperatureMax
            cdata.series[1].data.push celsius row.apparentTemperatureMin
            cdata.series[2].data.push celsius row.temperatureMax
            cdata.series[3].data.push celsius row.temperatureMin

            fdata.series[0].data.push row.apparentTemperatureMax
            fdata.series[1].data.push row.apparentTemperatureMin
            fdata.series[2].data.push row.temperatureMax
            fdata.series[3].data.push row.temperatureMin

        $currently = jq('#currently').attr 'title', data.summary

        temperatureDiv data.currently.temperature, $currently.find('.temperature')
        temperatureDiv data.currently.apparentTemperature, $currently.find('.apparentTemperature')
        $currently.find('.summary').html data.currently.summary
        $currently.find('i.wi').addClass 'wi-forecast-io-' + data.currently.icon

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

            jq(div).insertBefore($template)
            jq(div).find('i').addClass('wi-forecast-io-' + list[i])
            jq("#chart .day-#{i} .label").html fdata.labels[i]

        $template.remove()

        $template = jq('#wide-chart .template')

        for icon,i in list
            [div] = $template.clone()
                             .addClass("day-#{i}")
                             .attr 'title', data.daily[i].summary

            jq(div).insertBefore($template)
            jq(div).find('i').addClass('wi-forecast-io-' + list[i])
            jq("#wide-chart .day-#{i} .label").html fdata.labels[i]

        $template.remove()

        makeChart = (id, data) ->
            new Chartist.Line id, data,
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
                        labelOffset:
                            x: 0,
                            y: -10
                        labelInterpolationFnc: (v) -> Math.round v
                ]


        chart = makeChart '#chart .chartist', sliceData(jq.extend(true, {}, fdata), 5)
        wideChart = makeChart '#wide-chart .chartist', fdata
</script>

<template lang=pug>
main
    // p: a(href=".netlify/functions/serverless") serverless
    // pre {JSON.stringify(fdata, null, 4)}


    .view.portrait
        div#currently.flex-top.flex-vertical
            #links-container.flex-top.flex-container
                #links
                    a(href="http://forecast.io/#/f/#{'aaa'},#{'zlongitude'}") Full forecast.io
                    | &nbsp;|&nbsp;
                    a.json-link(href="/weather?'bbb'=#{'ccc'},longitude=#{'longitude'}")
                        span JSON Data
                    |&nbsp;|&nbsp;
                    a(href="/about")
                        span Help/About
            .forecast.flex-bottom.flex-vertical
                div.flex-item.flex-container.center
                    h1.location {data.location}
                div.icon-and-temperature.flex-item.flex-container.center
                    i.wi
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
                    i.wi.wi-fw
                    div.label
            div.chartist.ct-chart.ct-golden-section

    .view.landscape
        #wide-chart
            h1.location {data.location}
            div#summary
            div#daily.flex-container.space-between
                div.template
                    i.wi
                    div.label
            div.chartist.ct-major-twelfth

</template>

<style>

</style>
