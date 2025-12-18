<template>
    <button type="button" v-b-popover.focus="content">
        <BIconInfoCircle />
    </button>
</template>

<script>
import { BIconInfoCircle } from 'bootstrap-vue'

export default {
    components: { BIconInfoCircle },
    props: {
        content: {
            type: String,
            required: true,
        }
    }
}
</script>

<style scoped>
button {
    padding: 0;
    border: 0;
    background: none;
    cursor: help;
    font-size: 1rem;
}
</style>

