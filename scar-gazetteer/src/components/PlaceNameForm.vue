<template>
    <b-form novalidate @submit.prevent="submit">
        <b-form-group label-for="place_name_mapping" class="my-1">
            <template #label>
                <span style="color: red;">*</span> Mapping place name:
            </template>
            <small>Must be at least 2 characters.</small>
            <b-form-input id="place_name_mapping" v-model="$v.form_data.place_name_mapping.$model" type="text"
                required :state="validateState('place_name_mapping')" />
        </b-form-group>
        <b-form-group label-for="place_name_gazetteer" class="my-1">
            <template #label>
                <span style="color: red;">*</span> Gazetteer place name:
            </template>
            <small>Must be at least 2 characters.</small>
            <b-form-input id="place_name_mapping" v-model="$v.form_data.place_name_gazetteer.$model"
                required :state="validateState('place_name_gazetteer')" type="text" />
        </b-form-group>

        <b-form-group v-if="!form.name_id" label="Is this place known by an existing name in the SCAR CGA?" v-slot="{ ariaDescribedby }">
            <b-form-radio v-model="isExistingPlace" :aria-describedby="ariaDescribedby" :value="true">Yes</b-form-radio>
            <b-form-radio v-model="isExistingPlace" :aria-describedby="ariaDescribedby" :value="false">No</b-form-radio>
        </b-form-group>

        <b-form-group v-if="isExistingPlace" label-for="place_id" class="my-1">
            <template #label>
                <span style="color: red;">*</span> Place ID:
            </template>
            <b-form-input id="place_id" v-model="$v.form_data.place_id.$model" required type="text"
                :state="validateState('place_id')" />
        </b-form-group>

        <b-form-group label-for="latitude" class="my-1">
            <template #label>
                <span style="color: red;">*</span> Latitude:
            </template>
            <small>Must be between -90 and -60 degrees.</small>
            <b-form-input id="latitude" v-model="$v.coordinates.latitude.$model" required type="number"
                :state="validateState($v.coordinates.latitude)" />
        </b-form-group>
        <b-form-group label-for="longitude" class="my-1">
            <template #label>
                <span style="color: red;">*</span> Longitude:
            </template>
            <small>Must be between -180 and 180 degrees.</small>
            <b-form-input id="longitude" v-model="$v.coordinates.longitude.$model" required type="number"
                :state="validateState($v.coordinates.longitude)" />
        </b-form-group>

        <b-form-group label="Coordinate accuracy:" label-for="coordinate_accuracy" class="my-1">
            <b-form-input id="coordinate_accuracy" v-model="$v.form_data.coordinate_accuracy.$model" type="text"
                :state="validateState('coordinate_accuracy')" />
        </b-form-group>
        <b-form-group label="Altitude:" label-for="altitude" class="my-1">
            <b-form-input id="altitude" v-model="$v.form_data.altitude.$model" type="text"
                :state="validateState('altitude')" />
        </b-form-group>
        <b-form-group label="Altitude accuracy:" label-for="altitude_accuracy" class="my-1">
            <b-form-input id="altitude" v-model="$v.form_data.altitude_accuracy.$model" type="text"
                :state="validateState('altitude_accuracy')" />
        </b-form-group>

        <b-form-group label="Narrative:" label-for="narrative" class="my-1">
            <small>Use <i>[L]&lt;placename&gt;[/L]</i> to link to other place names.</small>
            <b-form-textarea id="narrative" v-model="$v.form_data.narrative.$model" rows="3" max-rows="6" />
        </b-form-group>
        <b-form-group label="Narrative translation:" label-for="narrative_translation" class="my-1">
            <small>Use <i>[L]&lt;placename&gt;[/L]</i> to link to other place names.</small>
            <b-form-textarea id="narrative_translation" v-model="$v.form_data.narrative_translation.$model" rows="3"
                max-rows="6" />
        </b-form-group>

        <b-form-group label="Is machine translation:" label-for="machine_translation" class="my-1">
            <b-form-select id="machine_translation" class="form-select my-1" v-model="$v.form_data.machine_translation.$model"
                :options="lists.machine_translation" :state="validateState($v.form_data.machine_translation)" />
        </b-form-group>

        <b-form-group label="Named for:" label-for="named-for" class="my-1">
            <b-form-textarea id="named-for" v-model="$v.form_data.named_for.$model" rows="3" max-rows="6" />
        </b-form-group>

        <b-form-group label="UN SDG:" label-for="un_sdg" class="my-1">
            <small>A place name can be linked to a related <a href="https://sdgs.un.org/goals">UN Sustainable Development Goal</a>.</small>
            <b-form-select id="un_sdg" class="form-select my-1" v-model.number="$v.form_data.un_sdg.$model" :options="lists.un_sdg" :state="validateState($v.form_data.un_sdg)" />
        </b-form-group>

        <b-form-group label-for="gazetteer" class="my-1">
            <template #label>
                <span style="color: red;">*</span> Source gazetteer:
            </template>
            <b-form-select id="gazetteer" class="form-select" required v-model="$v.form_data.gazetteer.$model" :options="lists.gazetteers"
                :state="validateState('gazetteer')" />
        </b-form-group>
        <b-form-group label-for="feature_type" class="my-1">
            <template #label>
                <span style="color: red;">*</span> Feature type:
            </template>
            <b-form-select id="feature_type" class="form-select" required v-model="$v.form_data.feature_type_code.$model"
                :options="lists.feature_types" :state="validateState('feature_type_code')" />
        </b-form-group>
        <b-form-group label-for="is_relic" class="my-1">
            <template #label>
                <span style="color: red;">*</span> Is relic:
            </template>
            <b-form-select id="is_relic" class="form-select" v-model="$v.form_data.relic_flag.$model" :options="lists.relic" :state="validateState($v.form_data.relic_flag)" />
        </b-form-group>
        <b-form-group label="Date named:" label-for="date_named" class="my-1">
            <b-form-input id="date_named" v-model="$v.form_data.date_named.$model" type="date" />
        </b-form-group>
        <b-form-group label="Comments:" label-for="comments" class="my-1">
            <b-form-textarea id="comments" v-model="$v.form_data.comments.$model" rows="3" max-rows="6" />
        </b-form-group>
        <b-form-group label="Source name:" label-for="source_name" class="my-1">
            <b-form-input id="source_name" v-model="$v.form_data.source_name.$model" type="text" />
        </b-form-group>
        <b-form-group label="Source publisher:" label-for="source_publisher" class="my-1">
            <b-form-input id="source_publisher" v-model="$v.form_data.source_publisher.$model" type="text" />
        </b-form-group>
        <b-form-group label="Source identifier:" label-for="source_identifier" class="my-1">
            <b-form-input id="source_identifier" v-model="$v.form_data.source_identifier.$model" type="text" />
        </b-form-group>
        <b-form-group label="Source scale:" label-for="source_scale" class="my-1">
            <b-form-input id="source_scale" v-model="$v.form_data.source_scale.$model" type="text" />
        </b-form-group>
        <b-alert variant="danger" :show="$v.$dirty && $v.$error">There are errors that require your attention.</b-alert>
        <b-button type="submit" variant="primary">Submit</b-button>
        <b-button variant="secondary" @click="reset">Reset</b-button>
        <b-button v-if="form_data.name_id" variant="danger" @click="deletePlacename">Delete</b-button>
    </b-form>
</template>

<script>
import axios from 'axios'
import { validationMixin } from "vuelidate"
import { required, minLength, between, decimal, integer, requiredIf } from 'vuelidate/lib/validators'
import { getNameForNumericIsoCountryCode } from '@/utils'
import { join } from '../utils'

const boolean = (value) => typeof value === 'boolean'

export default {
    name: 'PlaceNameForm',
    props: {
        form: Object
    },
    mixins: [validationMixin],
    data: function () {
        return {
            isExistingPlace: true,
            coordinates: {
                latitude: this.form.geometry.coordinates[1],
                longitude: this.form.geometry.coordinates[0]
            },
            form_data: this.form,
            lists: {
                gazetteers: [{ value: null, text: 'Select gazetteer' }],
                feature_types: [{ value: null, text: 'Select feature type' }],
                un_sdg: [
                    { value: 0, text: "None"},
                    { value: 1, text: "No Poverty"},
                    { value: 2, text: "Zero Hunger"},
                    { value: 3, text: "Good Health and Well-being"},
                    { value: 4, text: "Quality Education"},
                    { value: 5, text: "Gender Equality"},
                    { value: 6, text: "Clean Water and Sanitation"},
                    { value: 7, text: "Affordable and Clean Energy"},
                    { value: 8, text: "Decent Work and Economic Growth"},
                    { value: 9, text: "Industry, Innovation, and Infrastructure"},
                    { value: 10, text: "Reduced Inequality"},
                    { value: 11, text: "Sustainable Cities and Communities"},
                    { value: 12, text: "Responsible Consumption and Production"},
                    { value: 13, text: "Climate Action"},
                    { value: 14, text: "Life Below Water"},
                    { value: 15, text: "Life on Land"},
                    { value: 16, text: "Peace, Justice, and Strong Institutions"},
                    { value: 17, text: "Partnerships for the Goals"}
                ],
                relic: [{ value: false, text: 'No' }, { value: true, text: 'Yes' }],
                machine_translation: [{ value: false, text: 'No' }, { value: true, text: 'Yes' }],
            }
        }
    },
    validations: {
        coordinates: {
            latitude: {
                required,
                decimal,
                between: between(-90, -60),
            },
            longitude: {
                required,
                decimal,
                between: between(-180, 180),
            },
        },
        form_data: {
            place_id: {
                required: requiredIf(function () {
                    return this.isExistingPlace
                }),
                integer,
                between: between(0, Number.MAX_SAFE_INTEGER),
            },
            place_name_mapping: {
                required,
                minLength: minLength(2),
            },
            place_name_gazetteer: {
                required,
                minLength: minLength(2),
            },
            coordinate_accuracy: {
                decimal,
            },
            altitude: {
                decimal,
            },
            altitude_accuracy: {
                decimal,
            },
            narrative: {

            },
            narrative_translation: {

            },
            machine_translation: {
                required,
                boolean,
            },
            named_for: {

            },
            un_sdg: {
                integer,
            },
            gazetteer: {
                required,
            },
            feature_type_code: {
                required,
                integer,
            },
            scar_feature_class: {

            },
            relic_flag: {
                required,
                boolean,
            },
            date_named: {

            },
            comments: {

            },
            source_name: {

            },
            source_publisher: {

            },
            source_identifier: {

            },
            source_scale: {

            }
        }
    },
    watch: {
        isExistingPlace(val) {
            if (!val) this.form_data.place_id = undefined
        },
        form() {
            this.isExistingPlace = true
            Object.assign(this.form_data, this.form)
            Object.assign(this.coordinates, {
                latitude: this.form.geometry.coordinates[1],
                longitude: this.form.geometry.coordinates[0]
            })
        }
    },
    mounted: async function () {
        this.loadGazetteers()
        this.loadFeatures()
    },
    methods: {
        validateState(name) {
            if (typeof name === 'string') {
                const { $dirty, $error } = this.$v.form_data[name];
                return $dirty ? $error ? false : undefined : undefined
            }

            const { $dirty, $error } = name
            return $dirty ? $error ? false : undefined : undefined
        },
        async loadGazetteers() {
            const { data } = await axios.get(join(process.env.BASE_URL, `/api/gazetteers?order=gazetteer_name.asc`))

            const formatted = data.map(g => {
                return { value: g.gazetteer_code, text: g.gazetteer_name || getNameForNumericIsoCountryCode(g.country_id) }
            })

            this.lists.gazetteers = this.lists.gazetteers.concat(formatted)
        },
        async loadFeatures() {
            let { data } = await axios.get(join(process.env.BASE_URL, `/api/feature_types?feature_type_code=neq.0&order=feature_type_name.asc`))

            let formatted = data.map(f => {
                return { value: f.feature_type_code, text: f.feature_type_name }
            })

            this.lists.feature_types = this.lists.feature_types.concat(formatted)
        },
        submit() {
            this.$v.$touch()

            if (this.$v.$anyError) return

            this.form_data.geometry = {
                type: "Point",
                crs: { type: "name", properties: { name: "urn:ogc:def:crs:EPSG::4326" }},
                coordinates: [this.coordinates.longitude, this.coordinates.latitude],
            }

            this.$emit('submit', this.form_data)
        },
        reset() {
            if (!window.confirm("Confirm form reset? Changes will be lost.")) return

            this.$emit('reset')
        },
        deletePlacename() {
            if (!window.confirm("Confirm record deletion? This cannot be undone.")) return

            this.$emit('deletePlacename', this.form_data)
        }
    }
}
</script>
