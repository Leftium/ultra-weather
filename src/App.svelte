<script type='text/coffeescript'>
    export name = null
    console.log 'Hello Svelte-CoffeeScript!'
</script>

<template lang=pug>
main
    h1 Hello {name}!
    p.
        Visit the #[a(href="https://svelte.dev/tutorial") Svelte tutorial]
        to learn how to build Svelte apps.
</template>

<style>
    main {
        text-align: center;
        padding: 1em;
        max-width: 240px;
        margin: 0 auto;
    }

    h1 {
        color: #ff3e00;
        text-transform: uppercase;
        font-size: 4em;
        font-weight: 100;
    }

    @media (min-width: 640px) {
        main {
            max-width: none;
        }
    }
</style>
