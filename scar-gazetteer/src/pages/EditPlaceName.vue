<template>
    <b-container>
        <h1>Edit place name</h1>
        <place-name-form v-if="!form_data.$get.isPending" :form="form_data" v-on:reset="reset" v-on:submit="submit"/>
    </b-container>
</template>

<script>
import { pg } from 'vue-postgrest'
import PlaceNameForm from '@/components/PlaceNameForm.vue'

export default {
    name: "EditPlaceName",
    components: {PlaceNameForm},
    mixins: [pg],
    computed: {
        pgConfig () {
            return {
                route: 'place_names',
                query: {
                        'name_id.eq': this.$route.params.id
                    },
                single: true 
            }
        },
        form_data () {
            return this.pg
        }
    },
    methods: {
        submit (form_data) {
            Object.assign(this.form_data, form_data)

            this.form_data.$put({ return: 'minimal' })
            this.$router.push({ path: `/place-name/${this.form_data.name_id}` })
        },
        reset () {
            this.form_data.$get()
        }
    }
}
</script>
