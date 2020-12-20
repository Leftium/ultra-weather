<script type='text/coffeescript'>
</script>

<template lang=pug>
main
    p: a(href=".netlify/functions/serverless") serverless

</template>

<style>
    main {
        text-align: center;
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
