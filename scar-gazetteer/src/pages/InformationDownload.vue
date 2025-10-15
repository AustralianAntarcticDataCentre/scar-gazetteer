<template>
    <b-container>
        <h2>Download</h2>

        <h3>Citation information</h3>
        <p>When citing this dataset, use the following example as a guide.</p>
        <p>Secretariat SCAR (1992, updated 2022).
            Composite Gazetteer of Antarctica, <em>Scientific Committee on Antarctic Research</em>.
            GCMD Metadata (<a
                href="http://gcmd.nasa.gov/records/SCAR_Gazetteer.html">http://gcmd.nasa.gov/records/SCAR_Gazetteer.html</a>)
        </p>

        <div class="alert alert-info"><strong>Note:</strong> These files maintain <span class="label label-info"
                id="diacritic_info" data-toggle="tooltip"
                title="A sign, such as an accent or cedilla, which when written above or below a letter indicates a difference in pronunciation from the same letter when unmarked or differently marked.">diacritics</span>.
            Please be mindful not to use software that does not keep diacritics.</div>

        <b-form @submit="submit">
            <b-form-group label="Gazetteer:" label-for="gazetteer">
                <b-form-select id="gazetteer" v-model="form.gazetteer" :options="gazetteers" />
            </b-form-group>
            <b-form-group label="Format:" label-for="format">
                <b-form-select id="format" v-model="form.format" :options="formats" />
            </b-form-group>
            <br>
            <b-button type="submit" variant="primary"><b-icon-download /> Download </b-button>
        </b-form>
    </b-container>
</template>

<script>
import axios from 'axios'
import { getNameForNumericIsoCountryCode } from '../utils'
import download from 'downloadjs'

export default {
    name: "Search",
    data: function () {
        return {
            form: {
                gazetteer: null,
                format: 'text/csv'
            },
            gazetteers: [{ value: null, text: "All Gazetteers" }],
            formats: [
                { value: 'text/csv', text: "CSV" },
                { value: 'application/geo+json', text: 'GeoJSON' },
                { value: 'application/vnd.google-earth.kml+xml', text: 'KML' }],
        }
    },
    methods: {
        submit: function (event) {
            event.preventDefault()

            let filter = ""

            if (this.form.gazetteer) {
                filter = `?gazetteer=eq.${this.form.gazetteer}`
            }

            let url = `${process.env.BASE_URL}/api/place_names${filter}`

            if(this.form.format == 'text/csv') {
                url = `${process.env.BASE_URL}/api/place_names_consolidated${filter}`
            }

            const options = {
            headers: {
                Accept: this.form.format
            }
            };
            fetch(url, options)
            .then( res => res.blob() )
            .then( blob => {

                let gazetteer = this.form.gazetteer || 'All'
                let fileSuffix = '.csv'

                if (this.form.format == 'application/geo+json') {
                    fileSuffix = '.json'
                } else if (this.form.format == 'application/vnd.google-earth.kml+xml') {
                    fileSuffix = '.kml'
                }

                download(blob, `SCAR-CGA-${gazetteer}${fileSuffix}`, this.form.format)
            });
        }
    },
    mounted: async function () {
        let response = await axios.get(`${process.env.BASE_URL}/api/gazetteers`)
        let gaz = response.data

        let formatted = gaz.map(g => {
            return { value: g.gazetteer_code, text: getNameForNumericIsoCountryCode(g.country_id) }
        })

        this.gazetteers = this.gazetteers.concat(formatted)
    }
}
</script>
