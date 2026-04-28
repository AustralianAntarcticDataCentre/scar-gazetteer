import Vue from 'vue'
import { BootstrapVue } from 'bootstrap-vue'
import VueMeta from 'vue-meta'
import Vuelidate from 'vuelidate'
import Router from 'vue-router'
import Postgrest from 'vue-postgrest'

import 'bootstrap/dist/css/bootstrap.css'
import 'bootstrap-vue/dist/bootstrap-vue.css'
import '@/assets/main.css'

import store from './store';
import App from './App.vue'
import routes from './routes'
import { join } from './utils'

Vue.use(VueMeta)
Vue.use(BootstrapVue)
Vue.use(Vuelidate)
Vue.use(Router)
Vue.use(Postgrest, {
    apiRoot: join(import.meta.env.BASE_PATH, `/api`),
})

const router = new Router({
    base: import.meta.env.BASE_PATH,
    mode: 'history',
    routes: routes
})

router.beforeEach(async (to, from, next) => {
    await store.dispatch('user/checkLoggedIn');

    if(to.matched.some(record => record.meta.requiresAdmin)) {
        if (store.state.user.isAdmin) {
            next()
            return
        }

        next('/')
        return
    }

    next()
})

new Vue({
  router,
  store,
  render: h => h(App),
}).$mount('#app')
