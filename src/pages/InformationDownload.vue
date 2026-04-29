<template>
    <div>
        <h1>Download</h1>

        <h2>Citation information</h2>
        <p>When citing this dataset, use the following example as a guide.</p>
        <blockquote>
            Secretariat SCAR (1992, updated 2025). Composite Gazetteer of
            Antarctica, Scientific Committee on Antarctic Research.
            (http://placenames.aq/)
        </blockquote>

        <div class="alert alert-info">
            <strong>Note:</strong> These files may contain Unicode characters, which may not display as expected in all software.
        </div>

        <b-form @submit="submit">
            <b-form-group label="Gazetteer:" label-for="gazetteer">
                <b-form-select
                    id="gazetteer"
                    v-model="form.gazetteer"
                    :options="gazetteers"
                />
            </b-form-group>
            <b-form-group label="Format:" label-for="format">
                <b-form-select
                    id="format"
                    v-model="form.format"
                    :options="formats"
                />
            </b-form-group>
            <br />
            <b-button type="submit" variant="primary"
                ><BIconDownload /> Download</b-button
            >
        </b-form>
    </div>
</template>

<script>
import axios from "axios";
import { getNameForNumericIsoCountryCode, join } from "../utils";
import download from "downloadjs";
import { BIconDownload } from "bootstrap-vue";

export default {
    name: "Search",
    components: { BIconDownload },
    data: function () {
        return {
            form: {
                gazetteer: null,
                format: "text/csv",
            },
            gazetteers: [{ value: null, text: "All gazetteers" }],
            formats: [
                { value: "text/csv", text: "CSV" },
                { value: "application/geo+json", text: "GeoJSON" },
                { value: "application/vnd.google-earth.kml+xml", text: "KML" },
            ],
        };
    },
    methods: {
        submit: function (event) {
            event.preventDefault();

            let filter = "";

            if (this.form.gazetteer) {
                filter = `?gazetteer_code=eq.${this.form.gazetteer}`;
            }

            let url = join(import.meta.env.BASE_URL, `/api/place_names${filter}`);

            if (this.form.format == "text/csv") {
                url = join(
                    import.meta.env.BASE_URL,
                    `/api/place_names_consolidated${filter}`
                );
            }

            const options = {
                headers: {
                    Accept: this.form.format,
                },
            };
            fetch(url, options)
                .then((res) => res.blob())
                .then((blob) => {
                    let gazetteer = this.form.gazetteer || "All";
                    let fileSuffix = ".csv";

                    if (this.form.format == "application/geo+json") {
                        fileSuffix = ".json";
                    } else if (
                        this.form.format ==
                        "application/vnd.google-earth.kml+xml"
                    ) {
                        fileSuffix = ".kml";
                    }

                    download(
                        blob,
                        `SCAR-CGA-${gazetteer}${fileSuffix}`,
                        this.form.format
                    );
                });
        },
    },
    mounted: async function () {
        let response = await axios.get(
            join(import.meta.env.BASE_URL, `/api/gazetteers`)
        );
        let gaz = response.data;

        let formatted = gaz.map((g) => {
            return {
                value: g.gazetteer_code,
                text: getNameForNumericIsoCountryCode(g.country_id),
            };
        });

        this.gazetteers = this.gazetteers.concat(formatted);
    },
    metaInfo: {
        title: 'Download',
    },
};
</script>
