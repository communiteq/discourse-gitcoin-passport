import Component from "@glimmer/component";
import { inject as service } from "@ember/service";
import { action } from "@ember/object";
import { findAll } from "discourse/models/login-method";

export default class GitcoinPassportBanner extends Component {
  @service currentUser;
  @service siteSettings;
  
  get showPassportBanner() {
    if (this.currentUser) {
      return this.currentUser.gitcoin_passport_status < 3;
    }
    else {
      return false;
    }
  }

  get bannerText() {
    if (this.currentUser) {
      const i = this.currentUser.gitcoin_passport_status;
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
        const url = I18n.t("gitcoin_passport_plugin.link_gitcoin_connect");
        window.open(url, '_blank');
      }
    }
  }
}
