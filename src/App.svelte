<script type='text/coffeescript'>
    import axios from 'axios'
    import dayjs from 'dayjs'

    import { onMount } from 'svelte'

    data = null

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
        data.labels = data.lables.slice 0, length
        data.series.forEach (series, i) ->
            data.series[i].data = data.series[i].data.slice 0, length
        data

    cdata = initData()
    fdata = initData()

    celsius = (f) -> 5/9 * (f - 32)

    onMount () ->
        url = '/.netlify/functions/serverless'
        response = await axios.get url
        data = response.data

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

</script>

<template lang=pug>
main
    p: a(href=".netlify/functions/serverless") serverless
    pre {JSON.stringify(fdata, null, 4)}

</template>

<style>
    main {
        padding: 1em;
        max-width: 240px;
        margin: 0 auto;
    }

    @media (min-width: 640px) {
        main {
            max-width: none;
        }
    }
</style>
