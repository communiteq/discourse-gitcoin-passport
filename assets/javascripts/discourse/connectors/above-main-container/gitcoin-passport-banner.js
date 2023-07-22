import Component from "@glimmer/component";
import { inject as service } from "@ember/service";
import { action } from "@ember/object";

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
  
  get ctaText() {
    if (this.currentUser) {
      const i = this.currentUser.gitcoin_passport_status;
      return `gitcoin_passport_plugin.linktext_${i}` || "unknown";
    }
  }

  @action
  clickCTA() {
    if (this.currentUser) {
      const i = this.currentUser.gitcoin_passport_status;
      
      const url = I18n.t(`gitcoin_passport_plugin.link_${i}`) || "/";
      if (i == 1) {
        window.location.href = url;
      } else { // new window
        window.open(url, '_blank');
      }
    }
  }
}
