import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { inject as service } from "@ember/service";
import { action } from "@ember/object";
import { findAll } from "discourse/models/login-method";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";

export default class GitcoinPassportBanner extends Component {
  @service currentUser;
  @service siteSettings;
  
  @tracked connectingPassport = false;
  @tracked status = this.currentUser.gitcoin_passport_status;

  get showPassportBanner() {
    if (this.currentUser) {
      return this.status < 3;
    }
    else {
      return false;
    }
  }

  get bannerText() {
    if (this.currentUser) {
      const i = this.status;
      return I18n.t(`gitcoin_passport_plugin.banner_${i}`) || "unknown";
    }
  }
  
  @action
  clickCTA() {
    if (this.currentUser) {
      const i = this.currentUser.gitcoin_passport_status;
      if (i == 1) { // connect to Eth
        const allMethods = findAll();
        const siweMethod = allMethods.find(obj => obj.name === 'siwe');
        if (siweMethod) {
          siweMethod.doLogin({reconnect:true});
        }
      }
      if (i == 2) { // connect to Gitcoin Passport
        if (this.connectingPassport) {
          return;
        }

        this.connectingPassport = true;
        ajax({
          url: "/gitcoin_passport/refresh_score",
          type: "POST",
        })
        .then((result) => {
          alert("Your passport score is " + result.unique_humanity_score);
          this.status = 4;
        })
        .catch((e) => {
          popupAjaxError(e);
        })
        .finally(() => {
          this.connectingPassport = false;
        });
      }
    }
  }
}
