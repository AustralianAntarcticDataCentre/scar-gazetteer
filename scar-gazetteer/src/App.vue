<template>
  <b-container fluid="sm">
    <b-container id="header">
      <b-row>
        <b-col><a href="https://scar.org"><img src="~@/assets/scar_logo_sm.gif" alt="S C A R" /></a></b-col>
        <b-col>
          <h1>SCAR COMPOSITE GAZETTEER OF ANTARCTICA</h1>
        </b-col>
        <b-col></b-col>
      </b-row>
    </b-container>

    <div v-if="isLoggedIn" id="login-status"><small>You are logged in as {{ username }}</small></div>

    <div id="main-menu-placeholder">
      <div id="main-menu" data-spy="affix" data-offset-top="286">
        <b-container>
          <b-navbar type="dark" variant="primary">
            <b-navbar-brand to="/">SCAR Gazetteer</b-navbar-brand>
            <b-navbar-nav>
              <b-nav-item to="/search"><b-icon-search /> Search</b-nav-item>
              <b-nav-item to="/information"><b-icon-info-circle-fill /> Information</b-nav-item>
              <b-nav-item v-if="$store.state.user.isAdmin" to="/new-name"><b-icon-plus-circle-fill /> Add new
                name</b-nav-item>
            </b-navbar-nav>

            <b-navbar-nav class="nav-right">
              <b-button v-if="!isLoggedIn" id="login-button" size="sm" @click="$bvModal.show('login-modal')">
                <b-icon-person-fill /> Login
              </b-button>
              <div v-else class="form-inline">
                <b-button id="logout-button" size="sm" @click="logout"><b-icon-person /> Logout</b-button>
              </div>
            </b-navbar-nav>
          </b-navbar>
        </b-container>
      </div>
    </div>

    <b-modal id="login-modal" title="Login" hide-header-close @ok="handleLogin" @cancel="resetForm" @hidden="resetForm">
      <b-form @submit.prevent="handleLogin">
        <b-form-group label="Username" label-for="username">
          <b-form-input
            id="username"
            v-model="form.username"
            type="text"
            required
            autofocus
          />
        </b-form-group>

        <b-form-group label="Password" label-for="password">
          <b-form-input
            id="password"
            v-model="form.password"
            type="password"
            required
          />
        </b-form-group>

        <input type="submit" hidden />

        <b-alert v-if="loginError && form.submitted && loginError.response.status === 401" variant="danger" show>
          Invalid username or password
        </b-alert>
        <b-alert v-if="loginError && form.submitted && loginError.response.status === 429" variant="warning" show>
          Error: Too many requests
        </b-alert>
        <b-alert v-if="loginError && form.submitted && loginError.response.status !== 401 && loginError.response.status !== 429" variant="warning" show>
          Error: Could not log in
        </b-alert>
      </b-form>
    </b-modal>

    <router-view />
    <div class="footer">
      <p><i>The SCAR CGA is edited by Italian representatives from Comitato per i nomi geografici antartici.</i></p>
      <p><i>The SCAR CGA is hosted by the <a href="https://data.aad.gov.au">Australian Antarctic Data Centre</a>.</i></p>
    </div>
  </b-container>
</template>

<script>
import { mapActions, mapState } from 'vuex'
import { setDefaultToken } from 'vue-postgrest'

export default {
  name: 'App',
  components: {
  },
  metaInfo: function () {
    return {
      title: 'SCAR Composite Gazetteer of Antarctica',
      meta: [
        { name: 'description', content: 'SCAR Composite Gazetteer of Antarctica' },
        { property: 'og:title', content: 'SCAR Composite Gazetteer of Antarctica' },
        { property: 'og:site_name', content: 'SCAR Composite Gazetteer of Antarctica' },
        { property: 'og:type', content: 'website' },
        { name: 'robots', content: 'index,follow' },
      ]
    }
  },
  data: function () {
    return {
      form: {
        username: '',
        password: '',
        submitted: false
      }
    }
  },
  methods: {
    ...mapActions('user', [
      'authenticate',
      'logout'
    ]),
    handleLogin: function (bvModalEvt) {
      if (bvModalEvt) {
        bvModalEvt.preventDefault()
      }
      this.form.submitted = true
      this.authenticate({ username: this.form.username, password: this.form.password })
        .then(() => {
          if (!this.loginError) {
            this.$bvModal.hide('login-modal')
            this.resetForm()
          }
        })
    },
    resetForm: function () {
      this.form.username = ''
      this.form.password = ''
      this.form.submitted = false
    }
  },
  computed: {
    ...mapState('user', [
      'isLoggedIn',
      'loginError',
      'username'
    ]),
  },
  mounted: function () {
    setDefaultToken(this.$store.getters['user/getToken'])
  }
}
</script>

<style>
@import '~@/assets/scar_gaz.css';
@import '~@/assets/main.css';

.navbar {
  border-radius: 5px;
}

.navbar-brand {
  padding-left: 1.5em
}

.nav-right {
  justify-content: flex-end;
  flex-grow: 3;
  padding-right: 1.5em;
}

.form-inline {
  display: flex;
  flex-direction: row;
  align-items: center;
}

.form-control {
  margin-top: 0.5em;
  margin-bottom: 0.5em;
}

.footer {
  padding-top: 2em;
  margin: 1.5em;
  font-size: 9pt;
}

#login-button, #logout-button {
  margin-right: 0;
}

#login-status {
  text-align: right;
  margin-right: 1em;
  margin-bottom: 0.2em;
}

</style>
