<template>
    <b-container>
        <h1>Add new place name</h1>
        <place-name-form :form="form_data" v-on:submit="submit" />
    </b-container>
</template>

<script>
import { pg } from 'vue-postgrest'

import PlaceNameForm from '@/components/PlaceNameForm.vue'

export default {
    name: "NewPlaceName",
    components: { PlaceNameForm },
    mixins: [pg],
    data: function () {
        return {
            form_data: {
                "place_id": null,
                "place_name_mapping": null,
                "place_name_gazetteer": null,
                "latitude": -60,
                "longitude": 0,
                "coordinate_accuracy": null,
                "altitude": null,
                "altitude_accuracy": null,
                "narrative": "",
                "narrative_translation": "",
                "machine_translation": false,
                "named_for": null,
                "un_sdg": 0,
                "gazetteer": null,
                "feature_type_code": null,
                "relic_flag": false,
                "date_named": null,
                "comments": null,
                "source_name": null,
                "source_publisher": null,
                "source_identifier": null,
                "source_scale": null,
            }
        }
    },
    computed: {
        pgConfig() {
            return {
                route: 'place_names',
                single: true,
            }
        }
    },
    methods: {
        async submit(form_data) {
            try {
                Object.assign(this.pg, form_data)

                await this.pg.$post()

                this.$router.push({ path: `/place-name/${this.pg.name_id}` })
            } catch (error) {
                console.log(error)
                alert(`Error: could not submit new place name (${error})`)
            }
        }
    },
}
</script>
