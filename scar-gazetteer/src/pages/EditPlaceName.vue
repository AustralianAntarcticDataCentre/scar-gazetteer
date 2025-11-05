<template>
    <div class="max-w-md">
        <h1>Edit place name</h1>
        <div class="d-flex justify-content-center" v-if="pg.$get.isPending">
            <b-spinner class="spinner"></b-spinner>
        </div>
        <place-name-form v-else :form="form_data" v-on:reset="reset" v-on:submit="submit" v-on:deletePlacename="deletePlacename" />
    </div>
</template>

<script>
import { pg } from 'vue-postgrest'
import PlaceNameForm from '@/components/PlaceNameForm.vue'

export default {
    name: "EditPlaceName",
    components: { PlaceNameForm },
    mixins: [pg],
    computed: {
        pgConfig() {
            return {
                route: 'place_names',
                query: {
                    'name_id.eq': this.$route.params.id
                },
                single: true,
                token: this.$store.getters['user/getToken']
            }
        },
        form_data() {
            return this.pg
        }
    },
    methods: {
        submit(form_data) {
            Object.assign(this.pg, form_data)

            this.pg.$patch({ headers: { Prefer: 'return=minimal' } })
                .then(() => {
                    this.$router.push({ path: `/place-names/${this.pg.name_id}` })
                })
                .catch(err => {
                    console.error("PUT failed", err)
                    alert(`Error: could not save place name (${err})`)
                })
        },
        reset() {
            this.pg.$get()
        },
        deletePlacename() {
            this.pg.$delete({ headers: { Prefer: 'return=minimal' } })
                .then(() => {
                    this.$router.push({ path: '/' })
                })
                .catch(err => {
                    console.error("Delete place name failed", err)
                    alert(`Error: could not delete place name (${err})`)
                })
        }
    }
}
</script>
