import Component from "@glimmer/component";
import { action } from "@ember/object";
import { tracked } from "@glimmer/tracking";
import { ajax } from "discourse/lib/ajax";

export default class GitcoinPassportPreferencesScore extends Component {
  @tracked refreshingPassport = false;
  @tracked score = this.args.outletArgs.model.unique_humanity_score;

  get passportStatus() {
    const i = this.args.outletArgs.model.gitcoin_passport_status;
    return I18n.t(`gitcoin_passport_plugin.status_${i}`) || "unknown";
  }

  get showUHScore() {
    return this.args.outletArgs.model.gitcoin_passport_status > 2;
  }

  get uniqueHumanityScore() {
    return this.score;
  }

  @action
  refreshPassport() {
    this.refreshingPassport = true;
    ajax({
      url: "/gitcoin_passport/refresh_score",
      type: "POST",
    })
    .then((result) => {
      this.score = result.unique_humanity_score;
    })
    .catch((e) => {
      popupAjaxError(e);
    })
    .finally(() => {
      this.refreshingPassport = false;
    });
  }
}
