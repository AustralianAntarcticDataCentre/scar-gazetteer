<template>
  <b-container class="search">
    <h1>Search for place names</h1>
    <b-form @submit="search">
      <b-form-group label="Place name:" label-for="search_text">
        <b-form-input id="search_text" class="my-0" v-model="form.search_text" type="text" />
      </b-form-group>
      <b-form-group label="Feature type:" label-for="feature_type">
        <b-form-select id="feature_type" class="form-select" v-model="form.feature_type" :options="feature_types" />
      </b-form-group>
      <b-form-group label="Gazetteer:" label-for="gazetteer">
        <b-form-select id="gazetteer" class="form-select" v-model="form.gazetteer" :options="gazetteers" />
      </b-form-group>
      <b-form-group label="Relics:" label-for="relics">
        <b-form-select id="relics" class="form-select" v-model="form.relics" :options="relics" />
      </b-form-group>
      <b-form-group label="Named after:" label-for="date_after" id="date_after_label">
        <b-form-input id="date_after" v-model="form.date_after" type="date" />
      </b-form-group>
      <b-form-group label="Named before:" label-for="date_before">
        <b-form-input id="date_before" v-model="form.date_before" type="date" />
      </b-form-group>
      <b-button class="submit-button" type="submit" variant="primary">Search</b-button>
    </b-form>
  </b-container>
</template>

<script>
import qs from "qs";
import axios from "axios";
import { getNameForNumericIsoCountryCode } from "@/utils"

export default {
  name: "Search",
  data: function () {
    return {
      feature_types: [
        {
          value: null,
          text: "All feature types",
        },
      ],
      relics: [
        { value: null, text: "Include relics" },
        { value: 1, text: "Exclude relics" },
        { value: 2, text: "Only relics" },
      ],
      gazetteers: [{ value: null, text: "All gazetteers" }],
      form: {
        search_text: "",
        feature_type: null,
        gazetteer: null,
        relics: null,
        date_after: null,
        date_before: null,
      },
    };
  },
  methods: {
    search(event) {
      event.preventDefault();
      this.$router.push(`/search/results?${qs.stringify(this.form)}`);
    },
    async getGazetteers() {
      let { data } = await axios.get("/api/gazetteers?order=gazetteer_name.asc");

      let formatted = data.map((g) => {
        return { value: g.gazetteer_code, text: g.gazetteer_name || getNameForNumericIsoCountryCode(g.country_id) || 'Unknown' };
      });

      this.gazetteers = this.gazetteers.concat(formatted);
    },
    async getFeatureTypes() {
      let { data } = await axios.get("/api/feature_types?feature_type_code=neq.0&order=feature_type_name.asc");

      let formatted = data.map((f) => {
        return { value: f.feature_type_code, text: f.feature_type_name };
      });

      this.feature_types = this.feature_types.concat(formatted);
    }
  },
  mounted() {
    this.getGazetteers()
    this.getFeatureTypes()
  },
};
</script>

<style scoped>
.search {
  max-width: 50em;
}

.submit-button {
  margin-top: 1em;
}

.form-group {
  margin-top: 0.3em;
}

.form-select, #date_before, #date_after {
  width: 35%;
  margin-top: 0;
  margin-bottom: 0;
}

</style>
