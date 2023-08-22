import Component from "@glimmer/component";
import { inject as service } from "@ember/service";

export default class GitcoinPassportUsercardScore extends Component {
  @service siteSettings;
    
  get showUHScore() {
    return this.siteSettings.gitcoin_passport_show_on_usercard && (this.args.outletArgs.user.gitcoin_passport_status > 2);
  }
    
  get uniqueHumanityScore() {
    return this.args.outletArgs.user.unique_humanity_score;
  }
}