import Vue from 'vue'
import { BootstrapVue, BootstrapVueIcons } from 'bootstrap-vue'
import VueMeta from 'vue-meta'
import Vuelidate from 'vuelidate'
import '@/assets/bootstrap.css'
import 'bootstrap-vue/dist/bootstrap-vue.css'

import store from './store';
import App from './App.vue'
import router from './routes/main'

Vue.config.productionTip = false

Vue.use(VueMeta)
Vue.use(BootstrapVue)
Vue.use(BootstrapVueIcons)
Vue.use(Vuelidate)

new Vue({
  router,
  store,
  render: h => h(App),
}).$mount('#app')
