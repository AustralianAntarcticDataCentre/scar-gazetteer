<template>
    <div>
        <h1>Add new place name</h1>
        <place-name-form :form="form_data" v-on:submit="submit" v-on:reset="reset" />
    </div>
</template>

<script>
import { pg } from 'vue-postgrest'
import PlaceNameForm from '@/components/PlaceNameForm.vue'

const initialForm = () => ({
    "place_id": undefined,
    "place_name_mapping": null,
    "place_name_gazetteer": null,
    "geometry": { type: "Point", coordinates: [0, -60] },
    "coordinate_accuracy": null,
    "altitude": null,
    "altitude_accuracy": null,
    "narrative": "",
    "named_for": null,
    "un_sdg": 0,
    "gazetteer": null,
    "feature_type_code": null,
    "relic_flag": false,
    "date_named": null,
    "comments": null,
})

export default {
    name: "NewPlaceName",
    components: { PlaceNameForm },
    mixins: [pg],
    data: function () {
        return {
            form_data: initialForm()
        }
    },
    computed: {
        pgConfig() {
            return {
                route: 'place_names',
                single: true,
                token: this.$store.getters['user/getToken']
            }
        }
    },
    methods: {
        async submit(data) {
            try {
                Object.assign(this.pg, data)

                await this.pg.$post()

                this.$router.push({ path: `/place-name/${this.pg.name_id}` })
            } catch (error) {
                console.log(error)
                alert(`Error: could not submit new place name (${error})`)
            }
        },
        reset() {
            this.form_data = initialForm()
        }
    },
}
</script>
